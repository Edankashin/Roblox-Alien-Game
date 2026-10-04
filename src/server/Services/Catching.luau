--!strict
-- ServerScriptService.Server.Services.Catching: the server-authoritative capture minigame.
-- The server generates every parameter (ticker speed, zones, zone centre, start clock), hands them
-- to the client, and judges each tap from the client's tap TIME only, using the shared Capture math.
-- The client never reports an outcome. Catches write to the profile here and nowhere else.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Tiers = require(Shared.data.Tiers)
local Overlays = require(Shared.data.Overlays)
local Capture = require(Shared.Capture)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Spawner = require(script.Parent.Spawner)

local Catching = {}

type Encounter = {
	userId: number,
	spawnId: string,
	species: string,
	tier: Types.Tier,
	token: string,
	roundsTotal: number,
	round: number,
	sweepsLeft: number,
	misses: number, -- across the whole encounter, for hidden kindness
	perfectRounds: number,
	kindnessApplied: boolean,
	tickerSpeed: number,
	goodZone: number,
	perfectZone: number,
	zoneCenter: number,
	startClock: number,
	lastActivity: number, -- os.clock()
}

local rng = Random.new()
local encounters: { [number]: Encounter } = {} -- by UserId
local claimedSpawns: { [string]: number } = {} -- spawnId -> UserId mid-encounter

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

-- Zone widths for this encounter: tier base, plus the lure bonus (hook, lures arrive later),
-- plus hidden kindness once the player has missed enough times.
local function applyZones(encounter: Encounter)
	local tier = Tiers.Tiers[encounter.tier]
	local lureBonus = 0 -- TODO lures: Lures.Lures[id].zoneBonus from the player's active lure
	local good = tier.goodZone + lureBonus
	local perfect = tier.perfectZone + lureBonus
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
	applyZones(encounter)
	encounter.startClock = now() + Config.CaptureSweepLeadSeconds
	encounter.lastActivity = os.clock()
end

local function continued(encounter: Encounter, outcome: Types.CaptureOutcome, hit: Types.HitOutcome, pos: number): Types.CaptureHitResult
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
	}
end

local function overlayRank(overlay: Types.Overlay): number
	return table.find(Overlays.Order, overlay) or 0
end

-- Write the catch into the profile. Returns isNew and the Scrap paid.
local function recordCatch(player: Player, encounter: Encounter, overlay: Types.Overlay, perfect: boolean): (boolean, number, number)
	local isNew = false
	local scrapGained = 0
	local scrapNow = 0
	local caughtAt = os.time()
	PlayerData.Update(player, function(profile)
		local uid = HttpService:GenerateGUID(false)
		local record: Types.AlienRecord = {
			uid = uid,
			species = encounter.species,
			level = 1,
			overlay = overlay,
			caughtAt = caughtAt,
		}
		profile.aliens[uid] = record

		local entry = profile.codex[encounter.species]
		if not entry then
			entry = { count = 0, bestOverlay = "None", firstCaughtAt = 0 }
			profile.codex[encounter.species] = entry
		end
		isNew = entry.count == 0
		entry.count += 1
		if overlayRank(overlay) > overlayRank(entry.bestOverlay) then
			entry.bestOverlay = overlay
		end
		if isNew then
			entry.firstCaughtAt = caughtAt
			scrapGained = Tiers.Tiers[encounter.tier].codexScrap
			profile.scrap += scrapGained
		end

		profile.stats.catches += 1
		if perfect then
			profile.stats.perfects += 1
		end
		scrapNow = profile.scrap
	end)
	return isNew, scrapGained, scrapNow
end

-- Remotes ----------------------------------------------------------------

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

	local tier = Tiers.Tiers[spawn.tier]
	local encounter: Encounter = {
		userId = player.UserId,
		spawnId = spawnId,
		species = spawn.species,
		tier = spawn.tier,
		token = HttpService:GenerateGUID(false),
		roundsTotal = math.max(1, tier.rounds),
		round = 1,
		sweepsLeft = Config.CaptureSweepsPerEncounter,
		misses = 0,
		perfectRounds = 0,
		kindnessApplied = false,
		tickerSpeed = tier.tickerSpeed,
		goodZone = tier.goodZone,
		perfectZone = tier.perfectZone,
		zoneCenter = 0.5,
		startClock = 0,
		lastActivity = os.clock(),
	}
	startSweep(encounter, true)
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
		-- despawned mid-encounter (its condition ended)
		endEncounter(player.UserId)
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
	local hit: Types.HitOutcome = if valid
		then Capture.outcome(pos, encounter.zoneCenter, encounter.goodZone, encounter.perfectZone)
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
			Spawner.RemoveSpawn(encounter.spawnId, "caught")
			endEncounter(player.UserId)
			local isNew, scrapGained, scrapNow = recordCatch(player, encounter, overlay, perfect)
			if scrapGained > 0 then
				Net.event("ScrapChanged"):FireClient(player, scrapNow)
			end
			return {
				outcome = "Caught",
				hit = hit,
				pos = pos,
				perfect = perfect,
				species = species,
				tier = tier,
				overlay = overlay,
				isNew = isNew,
				scrapGained = scrapGained,
				scrap = scrapNow,
			}
		end
		encounter.round += 1
		startSweep(encounter, true)
		return continued(encounter, "Round", hit, pos)
	end

	-- Good that failed the roll wiggles free; a miss costs a sweep too. Both count toward kindness.
	encounter.sweepsLeft -= 1
	if hit == "Miss" then
		encounter.misses += 1
		if not encounter.kindnessApplied and encounter.misses >= Config.HiddenKindnessAfterMisses then
			encounter.kindnessApplied = true
		end
	end
	if encounter.sweepsLeft <= 0 then
		Spawner.RemoveSpawn(encounter.spawnId, "fled")
		endEncounter(player.UserId)
		return { outcome = "Fled", hit = hit, pos = pos }
	end
	startSweep(encounter, false)
	return continued(encounter, if hit == "Miss" then "Miss" else "Wiggle", hit, pos)
end

local function onCaptureCancel(player: Player)
	endEncounter(player.UserId)
end

-- Public API -------------------------------------------------------------

function Catching.Init()
	Net.event("ScrapChanged")
	Net.func("CaptureStart").OnServerInvoke = onCaptureStart
	Net.func("CaptureHit").OnServerInvoke = onCaptureHit
	Net.event("CaptureCancel").OnServerEvent:Connect(onCaptureCancel)
end

function Catching.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		endEncounter(player.UserId)
	end)
end

return Catching
