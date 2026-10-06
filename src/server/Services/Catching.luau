--!strict
-- ServerScriptService.Server.Services.Catching: the server-authoritative capture minigame.
-- The server generates every parameter (ticker speed, zones, zone centre, start clock), hands them
-- to the client, and judges each tap from the client's tap TIME only, using the shared Capture math.
-- The client never reports an outcome. A won encounter hands the alien to Economy.GrantAlien, the one
-- door an alien enters a profile through; this service decides only whether the catch was won.
-- Warden rules: a spawn reserved for one player (Spawner.SpawnAt from the Field Notes horn) refuses
-- everyone else; a multi-round tier (Legendary and above) shrinks both zones by
-- Config.WardenZoneShrinkPerRound each round after the first; catching the world's warden also drops
-- one Warden's Core (KeyMaterials) into the key materials; and a reserved encounter that is lost or
-- cancelled is reported to Quests so the horn's cooldown starts.
-- Catch variants (Shared/data/CatchVariants): the spawn's variant row sets the ticker speed scale, lets the
-- zone centre drift over each sweep (Capture.driftCenter from a per-sweep phase the server rolls and sends),
-- and can put the whole encounter on a clock: a tap stamped after the deadline loses the alien. The control
-- (tap or release) is the client's business; the server judges whichever timestamp arrives the same way.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Tiers = require(Shared.data.Tiers)
local Lures = require(Shared.data.Lures)
local KeyMaterials = require(Shared.data.KeyMaterials)
local Worlds = require(Shared.data.Worlds)
local AnalyticsData = require(Shared.data.Analytics)
local CatchVariants = require(Shared.data.CatchVariants)
local Place = require(Shared.Place)
local Capture = require(Shared.Capture)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Leaderboard = require(script.Parent.Leaderboard)
local DailyQuests = require(script.Parent.DailyQuests)
local WorldClock = require(script.Parent.WorldClock)
local Spawner = require(script.Parent.Spawner)
local Economy = require(script.Parent.Economy)
local Buffs = require(script.Parent.Buffs)
local Quests = require(script.Parent.Quests)

local Catching = {}

type Encounter = {
	player: Player, -- for the buff reads each sweep (Steady Hands)
	userId: number,
	spawnId: string,
	species: string,
	tier: Types.Tier,
	reserved: boolean, -- a spawn reserved for this player (the Warden): its loss is a retreat
	token: string,
	roundsTotal: number,
	round: number,
	sweepsLeft: number,
	misses: number, -- across the whole encounter, for hidden kindness
	perfectRounds: number,
	kindnessApplied: boolean,
	lure: string?, -- the Lures.Lures id spent on this encounter, if any
	lureBonus: number, -- its zoneBonus (0 with no lure), added to both zones
	variant: CatchVariants.Row, -- the catch variant this encounter runs
	tickerSpeed: number,
	goodZone: number,
	perfectZone: number,
	zoneCenter: number, -- the rolled base; the zone sits at Capture.driftCenter of it at the tap
	driftPhase: number, -- radians, rolled every sweep
	startClock: number,
	deadline: number?, -- server clock the whole encounter must end by (a time-limited variant); nil without one
	lastActivity: number, -- os.clock()
}

-- The world this place runs: catching its warden drops the Warden's Core, the key material no node holds.
local WARDEN_SPECIES: string = Worlds[Place.WorldId()].warden
local WARDEN_CORE = "WardenCore" -- KeyMaterials row (condition "Quest", nodes 0)

local rng = Random.new()
local encounters: { [number]: Encounter } = {} -- by UserId
local claimedSpawns: { [string]: number } = {} -- spawnId -> UserId mid-encounter
local forcedVariants: { [number]: string } = {} -- UserId -> CatchVariants row id; Studio Dev's /variant sets it

local function now(): number
	return workspace:GetServerTimeNow()
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function endEncounter(userId: number)
	local encounter = encounters[userId]
	if encounter then
		if claimedSpawns[encounter.spawnId] == userId then
			claimedSpawns[encounter.spawnId] = nil
		end
		encounters[userId] = nil
	end
end

local function isStale(encounter: Encounter): boolean
	return os.clock() - encounter.lastActivity > Config.CaptureEncounterTimeoutSeconds
end

local function rollZoneCenter(): number
	return rng:NextNumber(Config.CaptureZoneCenterMin, Config.CaptureZoneCenterMax)
end

-- Zone widths for this encounter: tier base, plus the bonus of the lure spent on it, shrunk by
-- WardenZoneShrinkPerRound for every round won so far (round 1 = x1, compounding), grown by an active
-- Steady Hands, plus hidden kindness once the player has missed enough times. Read every sweep, so a
-- power-up that ends mid-encounter stops helping on the next sweep.
local function applyZones(encounter: Encounter)
	local tier = Tiers.Tiers[encounter.tier]
	local good = tier.goodZone + encounter.lureBonus
	local perfect = tier.perfectZone + encounter.lureBonus
	local shrink = Config.WardenZoneShrinkPerRound ^ (encounter.round - 1)
	good *= shrink
	perfect *= shrink
	local steady = Buffs.ZoneBonus(encounter.player)
	if steady > 0 then
		good *= 1 + steady
		perfect *= 1 + steady
	end
	if encounter.kindnessApplied then
		good *= 1 + Config.HiddenKindnessZoneBonus
		perfect *= 1 + Config.HiddenKindnessZoneBonus
	end
	encounter.goodZone = math.min(good, 1)
	encounter.perfectZone = math.min(perfect, encounter.goodZone)
end

local function startSweep(encounter: Encounter, newRound: boolean)
	if newRound then
		encounter.zoneCenter = rollZoneCenter()
		encounter.sweepsLeft = Config.CaptureSweepsPerEncounter
	end
	-- a fresh drift phase every sweep, so the swing cannot be memorised
	encounter.driftPhase = rng:NextNumber(0, 2 * math.pi)
	applyZones(encounter)
	encounter.startClock = now() + Config.CaptureSweepLeadSeconds
	encounter.lastActivity = os.clock()
end

local function continued(encounter: Encounter, outcome: Types.CaptureOutcome, hit: Types.HitOutcome, pos: number, zoneAt: number): Types.CaptureHitResult
	return {
		outcome = outcome,
		hit = hit,
		pos = pos,
		sweepsLeft = encounter.sweepsLeft,
		round = encounter.round,
		roundsTotal = encounter.roundsTotal,
		nextStartClock = encounter.startClock,
		zoneCenter = encounter.zoneCenter,
		goodZone = encounter.goodZone,
		perfectZone = encounter.perfectZone,
		driftPhase = encounter.driftPhase,
		zoneAt = zoneAt,
	}
end

-- Spends the best lure the player holds (Lures.Order runs weakest to strongest, so walk it from the
-- end) and tells the client. Returns the id spent, or nil when the player holds none. The lure is not
-- refunded if the alien flees or the player cancels: it bought the wider zones for this attempt, win
-- or lose, which keeps the rule simple and gives cancelling no edge.
local function consumeBestLure(player: Player): string?
	local used: string? = nil
	PlayerData.Update(player, function(profile)
		for index = #Lures.Order, 1, -1 do
			local id = Lures.Order[index]
			local held = profile.inventory.lures[id] or 0
			if held > 0 then
				profile.inventory.lures[id] = held - 1
				used = id
				break
			end
		end
	end)
	if used then
		local profile = PlayerData.Get(player)
		if profile then
			Net.event("InventoryChanged"):FireClient(player, profile.inventory)
		end
	end
	return used
end

-- The world's warden carries its Core: one Warden's Core (the row's dropCount) into the key materials,
-- right after GrantAlien has written the alien. Its own profile write and push, so GrantAlien stays the
-- one plain door for every alien (a Peddler egg never drops one).
local function grantWardenCore(player: Player)
	local def = KeyMaterials[WARDEN_CORE]
	local ok = PlayerData.Update(player, function(profile)
		profile.inventory.keyMaterials[WARDEN_CORE] = (profile.inventory.keyMaterials[WARDEN_CORE] or 0) + def.dropCount
	end)
	local profile = PlayerData.Get(player)
	if ok and profile then
		Net.event("InventoryChanged"):FireClient(player, profile.inventory)
	end
end

-- A reserved encounter that ends without a catch (fled, despawned under the player, or cancelled) is
-- the Warden retreating: Quests starts the horn's cooldown and tells the client.
-- Reserved spawns are the Warden and the tutorial's trainee aliens; only the Warden's loss is a retreat.
local function reportLoss(player: Player, encounter: Encounter)
	if encounter.reserved and encounter.species == WARDEN_SPECIES then
		Quests.OnWardenRetreat(player)
	end
end

-- Remotes ----------------------------------------------------------------

-- CaptureStart(spawnId) -> (result, reason). Reasons: RateLimited, BadArgs, NoProfile, Busy, NoSpawn,
-- Reserved (another player's Warden), Taken, NoCharacter, TooFar.
local function onCaptureStart(player: Player, spawnId: any): (Types.CaptureStartResult?, string?)
	if not Net.allow(player, "CaptureStart", 2) then
		return nil, "RateLimited"
	end
	if type(spawnId) ~= "string" then
		return nil, "BadArgs"
	end
	if not PlayerData.Get(player) then
		return nil, "NoProfile"
	end
	local existing = encounters[player.UserId]
	if existing then
		if isStale(existing) then
			endEncounter(player.UserId)
		else
			return nil, "Busy"
		end
	end
	local spawn = Spawner.GetSpawn(spawnId)
	if not spawn then
		return nil, "NoSpawn"
	end
	local reservedFor = spawn.reservedFor
	if reservedFor and reservedFor ~= player.UserId then
		return nil, "Reserved"
	end
	local claimer = claimedSpawns[spawnId]
	if claimer and claimer ~= player.UserId then
		local other = encounters[claimer]
		if other and not isStale(other) then
			return nil, "Taken"
		end
		endEncounter(claimer)
	end
	local at = rootPosition(player)
	if not at then
		return nil, "NoCharacter"
	end
	if (at - spawn.part.Position).Magnitude > Config.CaptureInteractDistance + Config.CaptureDistanceSlack then
		return nil, "TooFar"
	end

	-- Every check has passed: the attempt is on, so the lure is spent now (see consumeBestLure).
	local lure: string? = nil
	local lureBonus = 0
	if Config.LureAutoUse then
		lure = consumeBestLure(player)
		if lure then
			lureBonus = Lures.Lures[lure].zoneBonus
		end
	end

	local tier = Tiers.Tiers[spawn.tier]
	-- a forced variant (Studio Dev) beats the spawn's; an unknown id falls back to the default row
	local variantId = forcedVariants[player.UserId] or spawn.variant
	local row = CatchVariants.Rows[variantId] or CatchVariants.Rows[CatchVariants.Default]
	local encounter: Encounter = {
		player = player,
		userId = player.UserId,
		spawnId = spawnId,
		species = spawn.species,
		tier = spawn.tier,
		reserved = reservedFor ~= nil,
		token = HttpService:GenerateGUID(false),
		roundsTotal = math.max(1, tier.rounds),
		round = 1,
		sweepsLeft = Config.CaptureSweepsPerEncounter,
		misses = 0,
		perfectRounds = 0,
		kindnessApplied = false,
		lure = lure,
		lureBonus = lureBonus,
		variant = row,
		tickerSpeed = tier.tickerSpeed * row.tickerSpeedScale,
		goodZone = tier.goodZone,
		perfectZone = tier.perfectZone,
		zoneCenter = 0.5,
		driftPhase = 0,
		startClock = 0,
		deadline = nil,
		lastActivity = os.clock(),
	}
	startSweep(encounter, true)
	-- the clock covers every round, counted from the first sweep's start
	encounter.deadline = if row.timeLimitSeconds > 0 then encounter.startClock + row.timeLimitSeconds else nil
	encounters[player.UserId] = encounter
	claimedSpawns[spawnId] = player.UserId

	return {
		token = encounter.token,
		species = encounter.species,
		tier = encounter.tier,
		tickerSpeed = encounter.tickerSpeed,
		goodZone = encounter.goodZone,
		perfectZone = encounter.perfectZone,
		zoneCenter = encounter.zoneCenter,
		roundsTotal = encounter.roundsTotal,
		round = encounter.round,
		sweepsLeft = encounter.sweepsLeft,
		startClock = encounter.startClock,
		lure = encounter.lure,
		variant = row.id,
		driftPhase = encounter.driftPhase,
		deadline = encounter.deadline,
	}, nil
end

local function onCaptureHit(player: Player, token: any, clientTapTime: any): Types.CaptureHitResult?
	if not Net.allow(player, "CaptureHit", 6) then
		return nil
	end
	local encounter = encounters[player.UserId]
	if not encounter or type(token) ~= "string" or token ~= encounter.token then
		return nil
	end
	encounter.lastActivity = os.clock()

	local spawn = Spawner.GetSpawn(encounter.spawnId)
	if not spawn then
		-- despawned mid-encounter (its condition ended, or a Warden's lifetime ran out)
		endEncounter(player.UserId)
		reportLoss(player, encounter)
		return { outcome = "Fled" }
	end

	-- Judge the tap from its timestamp alone. A stamp outside the window the network can explain
	-- is scored as a miss: too early (before the sweep started), too far ahead of the server clock,
	-- or too far behind it (a backdated stamp could otherwise be chosen to land on Perfect).
	local serverNow = now()
	local tapTime = if type(clientTapTime) == "number" and clientTapTime == clientTapTime then clientTapTime else -1
	local valid = tapTime >= encounter.startClock
		and tapTime <= serverNow + Config.LatencyAllowanceSeconds
		and serverNow - tapTime <= Config.CaptureMaxTapLagSeconds
	local pos = if valid then Capture.position(tapTime - encounter.startClock, encounter.tickerSpeed) else -1

	-- The clock (a time-limited variant): a tap stamped after the deadline, or any tap that reaches the server
	-- after the deadline plus the lag allowance, means the alien bolts. The raw stamp is used whenever it is a
	-- number (valid or not); a missing or non-numeric stamp is read as arriving now.
	local deadline = encounter.deadline
	if deadline then
		local stamp = if type(clientTapTime) == "number" and clientTapTime == clientTapTime then clientTapTime else serverNow
		if stamp > deadline or serverNow > deadline + Config.CaptureMaxTapLagSeconds then
			Spawner.RemoveSpawn(encounter.spawnId, "fled")
			endEncounter(player.UserId)
			reportLoss(player, encounter)
			Analytics.Event(player, AnalyticsData.Events.Flee, 1, { tier = encounter.tier :: string })
			return { outcome = "Fled", hit = "Miss", pos = pos }
		end
	end

	-- Where the zone sits at the tap: the rolled centre drifted by the variant over the sweep so far.
	local row = encounter.variant
	local zoneAt = if valid
		then Capture.driftCenter(tapTime - encounter.startClock, encounter.zoneCenter, row.driftAmplitude, row.driftPeriodSeconds, encounter.driftPhase, row.driftClampMin, row.driftClampMax)
		else encounter.zoneCenter
	local hit: Types.HitOutcome = if valid
		then Capture.outcome(pos, zoneAt, encounter.goodZone, encounter.perfectZone)
		else "Miss"

	local roundWon = false
	if hit == "Perfect" then
		roundWon = true
		encounter.perfectRounds += 1
	elseif hit == "Good" then
		roundWon = rng:NextNumber() < Tiers.Tiers[encounter.tier].catchChance
	end

	if roundWon then
		if encounter.round >= encounter.roundsTotal then
			local perfect = encounter.perfectRounds >= encounter.roundsTotal
			local overlay: Types.Overlay = spawn.overlay
			local species: string = spawn.species
			local tier: Types.Tier = spawn.tier
			local size: string = spawn.size
			Spawner.RemoveSpawn(encounter.spawnId, "caught")
			endEncounter(player.UserId)
			-- GrantAlien writes the record, codex, Scrap and stats, seats the alien, pushes ScrapChanged
			-- and the camp, moves pity, counts the Field Notes and announces a rare enough tier. Nil only
			-- if the profile is gone.
			local grant = Economy.GrantAlien(player, species, overlay, perfect, size)
			if not grant then
				return nil
			end
			-- Only a wild catch counts on the weekly board and the daily quests: eggs and shop aliens go
			-- through GrantAlien too (the Field Notes keep counting those, as before).
			Leaderboard.OnCatch(player)
			DailyQuests.OnCatch(player, tier, WorldClock.GetConditions(), perfect)
			if species == WARDEN_SPECIES then
				grantWardenCore(player)
			end
			return {
				outcome = "Caught",
				hit = hit,
				pos = pos,
				perfect = perfect,
				species = grant.species,
				tier = tier,
				overlay = grant.overlay,
				isNew = grant.isNew,
				scrapGained = grant.scrapGained,
				scrap = grant.scrap,
				zoneAt = zoneAt,
			}
		end
		-- next round: a fresh zone centre and sweep count; applyZones shrinks the zones for the round
		encounter.round += 1
		startSweep(encounter, true)
		return continued(encounter, "Round", hit, pos, zoneAt)
	end

	-- Good that failed the roll wiggles free; a miss costs a sweep too. Both count toward kindness.
	encounter.sweepsLeft -= 1
	if hit == "Miss" then
		encounter.misses += 1
		if not encounter.kindnessApplied and encounter.misses >= Config.HiddenKindnessAfterMisses then
			encounter.kindnessApplied = true
		end
		Analytics.Event(player, AnalyticsData.Events.CatchMiss, 1, { tier = encounter.tier :: string })
	end
	if encounter.sweepsLeft <= 0 then
		Spawner.RemoveSpawn(encounter.spawnId, "fled")
		endEncounter(player.UserId)
		reportLoss(player, encounter)
		Analytics.Event(player, AnalyticsData.Events.Flee, 1, { tier = encounter.tier :: string })
		return { outcome = "Fled", hit = hit, pos = pos, zoneAt = zoneAt }
	end
	startSweep(encounter, false)
	return continued(encounter, if hit == "Miss" then "Miss" else "Wiggle", hit, pos, zoneAt)
end

-- Walking away from a Warden is giving up on it: the spawn is removed through Quests and the cooldown runs.
local function onCaptureCancel(player: Player)
	local encounter = encounters[player.UserId]
	endEncounter(player.UserId)
	if encounter then
		reportLoss(player, encounter)
	end
end

-- Public API -------------------------------------------------------------

-- Studio Dev's /variant: every encounter this player starts runs the CatchVariants row `id` instead of the
-- spawn's own, until cleared with nil (or the player leaves). An unknown id falls back to the default row.
function Catching.SetForcedVariant(player: Player, id: string?)
	if id then
		forcedVariants[player.UserId] = id
	else
		forcedVariants[player.UserId] = nil
	end
end

function Catching.Init()
	Net.event("InventoryChanged") -- consumeBestLure, grantWardenCore
	Net.func("CaptureStart").OnServerInvoke = onCaptureStart
	Net.func("CaptureHit").OnServerInvoke = onCaptureHit
	Net.event("CaptureCancel").OnServerEvent:Connect(onCaptureCancel)
end

function Catching.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		endEncounter(player.UserId)
		forcedVariants[player.UserId] = nil
	end)
end

return Catching
