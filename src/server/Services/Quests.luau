--!strict
-- ServerScriptService.Server.Services.Quests: the Field Notes engine (Shared/data/Quests). One chain
-- per world, one step at a time: other services report what the player did (OnCatch, OnCollect,
-- OnCraft) and this service counts it into profile.quests.progress for the objectives of the current
-- step, pushes QuestsChanged, pays the step's rewards when the client claims it, and advances
-- profile.quests.fieldNotes[world]. It also owns the finale: SoundHorn summons the world's warden
-- (Worlds[Place.WorldId()].warden) as a spawn reserved for that player next to the shrine
-- (Place.Layout().Shrine, Spawner.SpawnAt), and a lost, cancelled or expired encounter is a retreat
-- that starts the horn's cooldown. The client renders the screen and the toasts; every count and
-- every grant is decided here. The home planet (Place.IsHome, world 0) has no chain and no shrine: the
-- hooks count nothing, QuestClaim and SoundHorn answer NoChain, and the profile gets no fieldNotes entry
-- for it; the daily and weekly quests (DailyQuests) are world-free and keep working there.
-- Requires run one way: Economy, Materials, Shop and Catching require this module to report; this
-- module never requires them back. Shop hands over its gear grant through SetGearGranter at Init.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local QuestData = require(Shared.data.Quests)
local Worlds = require(Shared.data.Worlds)
local Place = require(Shared.Place)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local WorldClock = require(script.Parent.WorldClock)
local Spawner = require(script.Parent.Spawner)
local DailyQuests = require(script.Parent.DailyQuests)

local Quests = {}

type Summon = { spawnId: string } -- this player's Warden, out at the shrine

local REMOTE_RATE_PER_SECOND = 4 -- QuestClaim and SoundHorn calls per player per second
local FIRST_STEP = 1 -- fieldNotes[world] for a profile that has not started the chain
local WORLD_ID = Place.WorldId() -- the chain this place runs
local WORLD_KEY = tostring(WORLD_ID)
local AT_HOME = Place.IsHome() -- no Field Notes chain, no shrine
local WARDEN_SPECIES: string = Worlds[WORLD_ID].warden
local CHAIN: { QuestData.Step } = QuestData.FieldNotes[WORLD_ID] or {}

local summons: { [number]: Summon } = {} -- by UserId
local retreatAt: { [number]: number } = {} -- os.clock() of the last retreat, by UserId; the horn's cooldown
-- Shop.GrantGear: sets the profile flag, pushes GearChanged and re-applies WalkSpeed (see the header).
local gearGranter: ((Player, string) -> (boolean, string?))? = nil

-- Steps and progress -----------------------------------------------------

-- The step the player is on and its index, or nil once the chain is done (index past the last step).
local function currentStep(profile: Types.Profile): (QuestData.Step?, number)
	local index = profile.quests.fieldNotes[WORLD_KEY] or FIRST_STEP
	return CHAIN[index], index
end

local function objectiveDone(profile: Types.Profile, objective: QuestData.Objective): boolean
	return (profile.quests.progress[objective.id] or 0) >= objective.count
end

local function stepComplete(profile: Types.Profile, step: QuestData.Step): boolean
	for _, objective in ipairs(step.objectives) do
		if not objectiveDone(profile, objective) then
			return false
		end
	end
	return true
end

local function hornObjective(step: QuestData.Step): QuestData.Objective?
	for _, objective in ipairs(step.objectives) do
		if objective.kind == "soundHorn" then
			return objective
		end
	end
	return nil
end

local function pushQuests(player: Player, profile: Types.Profile)
	local state: Types.QuestState = { fieldNotes = profile.quests.fieldNotes, progress = profile.quests.progress }
	Net.event("QuestsChanged"):FireClient(player, state)
end

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

-- Counts one toward every objective of the current step that `matches`, never past its count, and
-- pushes QuestsChanged when anything moved (the client reads a completed step from the counts). A
-- no-op once the chain is done or when nothing in the step matches.
local function advance(player: Player, matches: (QuestData.Objective) -> boolean)
	if AT_HOME then
		return
	end
	local changed = false
	local ok = PlayerData.Update(player, function(profile)
		local step = currentStep(profile)
		if not step then
			return
		end
		for _, objective in ipairs(step.objectives) do
			if matches(objective) then
				local have = profile.quests.progress[objective.id] or 0
				if have < objective.count then
					profile.quests.progress[objective.id] = have + 1
					changed = true
				end
			end
		end
	end)
	if not ok or not changed then
		return
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushQuests(player, profile)
	end
end

-- The Warden --------------------------------------------------------------

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

local function flatDistance(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- Where the summoned Warden stands: WardenSummonOffset studs from the shrine centre toward the camp
-- (the origin), so it steps out of the ring in front of a player who walked in from the camp.
-- The shrine's centre on the floor plane, from this world's layout (the pedestal's height is irrelevant
-- here: the horn and the summon are judged flat).
local function shrineFlat(): Vector3
	local shrine = Place.Layout().Shrine
	return Vector3.new(shrine.x, 0, shrine.z)
end

local function summonPosition(): Vector3
	local flat = shrineFlat()
	local toCamp = if flat.Magnitude > 0 then -flat.Unit else Vector3.new(0, 0, -1)
	return flat + toCamp * Config.WardenSummonOffset
end

-- This player's Warden leaves (or has already left): the cooldown starts, the horn objective reopens so
-- the finale reads incomplete until the horn is sounded again, and the client hears WardenRetreated.
-- Idempotent, so Catching's report and the Spawner's removal callback may both arrive for one loss.
local function retreat(userId: number, notify: boolean)
	local summon = summons[userId]
	if not summon then
		return
	end
	summons[userId] = nil -- cleared first: the removal below calls back into onSpawnRemoved
	retreatAt[userId] = os.clock()
	if Spawner.GetSpawn(summon.spawnId) then
		Spawner.RemoveSpawn(summon.spawnId, "retreat")
	end
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return
	end
	local ok = PlayerData.Update(player, function(profile)
		local step = currentStep(profile)
		local objective = if step then hornObjective(step) else nil
		if objective then
			profile.quests.progress[objective.id] = nil
		end
	end)
	local profile = PlayerData.Get(player)
	if ok and profile then
		pushQuests(player, profile)
	end
	if notify then
		print(("[%s] Quests: the Warden retreats from %s"):format(Config.WorkingTitle, player.Name))
		Net.event("WardenRetreated"):FireClient(player)
	end
end

-- Every spawn removal passes through here; only this player's Warden matters. Caught: the finale is
-- won, nothing more to do (Catching granted the alien and the Core). Anything else is a retreat: the
-- lifetime ran out (despawn), it fled, or it was asked to leave.
local function onSpawnRemoved(spawn: Spawner.WildSpawn, reason: Spawner.RemoveReason)
	local userId = spawn.reservedFor
	if not userId then
		return
	end
	local summon = summons[userId]
	if not summon or summon.spawnId ~= spawn.spawnId then
		return
	end
	if reason == "caught" then
		summons[userId] = nil
		return
	end
	retreat(userId, true)
end

-- Remotes ----------------------------------------------------------------

-- QuestClaim() -> (ok, reason). Pays every reward of the current step and moves to the next.
-- Reasons: RateLimited, NoProfile, NoChain (the home planet has none), Done (the chain is finished),
-- NotComplete (an objective is short, or the step's encounter reward has not been caught yet).
local function onQuestClaim(player: Player): (boolean, string?)
	if not Net.allow(player, "QuestClaim", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if AT_HOME then
		return false, "NoChain"
	end
	local step, index = currentStep(profile)
	if not step then
		return false, "Done"
	end
	if not stepComplete(profile, step) then
		return false, "NotComplete"
	end
	-- An encounter reward is the alien the horn summons: the step is claimed once that alien is in the
	-- codex, so a Warden that fled cannot be claimed away.
	for _, reward in ipairs(step.rewards) do
		if reward.kind == "encounter" then
			local entry = if reward.id then profile.codex[reward.id] else nil
			if not entry or entry.count < 1 then
				return false, "NotComplete"
			end
		end
	end

	local gearIds: { string } = {}
	local scrapChanged = false
	local inventoryChanged = false
	PlayerData.Update(player, function(p)
		for _, reward in ipairs(step.rewards) do
			local id = reward.id
			local amount = reward.amount or 1
			if reward.kind == "gear" and id then
				table.insert(gearIds, id) -- granted below through Shop, outside this write
			elseif reward.kind == "lure" and id then
				p.inventory.lures[id] = (p.inventory.lures[id] or 0) + amount
				inventoryChanged = true
			elseif reward.kind == "scrap" then
				p.scrap += amount
				scrapChanged = true
			elseif reward.kind == "spin" then
				p.spins.banked += amount
			elseif reward.kind == "item" and id then
				p.inventory.items[id] = (p.inventory.items[id] or 0) + amount
				inventoryChanged = true
			elseif reward.kind == "powerUp" and id then
				p.inventory.powerUps[id] = (p.inventory.powerUps[id] or 0) + amount
				inventoryChanged = true
			end
			-- "encounter": nothing to hand over; the Warden the horn summoned was the reward
		end
		p.quests.fieldNotes[WORLD_KEY] = index + 1
		for _, objective in ipairs(step.objectives) do
			p.quests.progress[objective.id] = nil
		end
	end)

	for _, id in ipairs(gearIds) do
		local granter = gearGranter
		if granter then
			local ok, reason = granter(player, id)
			if not ok and reason ~= "AlreadyOwned" then
				warn(("[%s] Quests: gear reward %s for %s refused: %s"):format(Config.WorkingTitle, id, player.Name, tostring(reason)))
			end
		else
			warn(("[%s] Quests: no gear granter registered; %s for %s not granted"):format(Config.WorkingTitle, id, player.Name))
		end
	end
	if scrapChanged then
		pushScrap(player, profile)
	end
	if inventoryChanged then
		pushInventory(player, profile)
	end
	pushQuests(player, profile)
	return true, nil
end

-- SoundHorn() -> (ok, reason). Summons this player's Warden next to the shrine and counts the horn
-- objective. Reasons: RateLimited, NoProfile, NoChain (the home planet has no shrine), NoHorn (no Quests.HornItem held), WrongStep (the current
-- step has no soundHorn objective), NotNight (the objective's condition is not active), NoCharacter,
-- TooFar (farther than ShrineInteractDistance from the shrine), Cooldown (a retreat less than
-- WardenRetreatSeconds ago), Active (this player's Warden is already out), Unknown (the warden species
-- is missing from the data).
local function onSoundHorn(player: Player): (boolean, string?)
	if not Net.allow(player, "SoundHorn", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if AT_HOME then
		return false, "NoChain"
	end
	if (profile.inventory.items[QuestData.HornItem] or 0) < 1 then
		return false, "NoHorn"
	end
	local step = currentStep(profile)
	local objective = if step then hornObjective(step) else nil
	if not objective then
		return false, "WrongStep"
	end
	local needs = objective.condition
	if needs and not WorldClock.HasCondition(needs) then
		return false, "NotNight"
	end
	local at = rootPosition(player)
	if not at then
		return false, "NoCharacter"
	end
	if flatDistance(at, shrineFlat()) > Config.ShrineInteractDistance then
		return false, "TooFar"
	end
	local since = retreatAt[player.UserId]
	if since and os.clock() - since < Config.WardenRetreatSeconds then
		return false, "Cooldown"
	end
	local summon = summons[player.UserId]
	if summon then
		if Spawner.GetSpawn(summon.spawnId) then
			return false, "Active"
		end
		summons[player.UserId] = nil -- gone without a removal callback; let the horn work again
	end

	local spawn = Spawner.SpawnAt(summonPosition(), WARDEN_SPECIES, "None", player.UserId, Config.WardenEncounterSeconds)
	if not spawn then
		return false, "Unknown"
	end
	summons[player.UserId] = { spawnId = spawn.spawnId }
	-- The horn objective counts when the Warden is caught (see OnCatch), so the step only reads complete
	-- once the catch has happened; a fled Warden leaves nothing to undo.
	Net.event("WardenSummoned"):FireClient(player)
	return true, nil
end

-- Hooks ------------------------------------------------------------------
-- All of these are no-ops once the chain is done or when the current step has no matching objective.

-- Economy.GrantAlien reports every alien that enters a profile with the conditions active at the time
-- (WorldClock.GetConditions: a rainy night is both Rain and Night). Counts catchCount, catchCondition,
-- catchTier and catchTierCondition. The species is not an objective kind yet.
function Quests.OnCatch(player: Player, species: string, tier: Types.Tier, conditions: { Types.Condition })
	advance(player, function(objective: QuestData.Objective): boolean
		local kind = objective.kind
		local tierMatches = objective.tier == tier
		local conditionMatches = objective.condition ~= nil and table.find(conditions, objective.condition) ~= nil
		if kind == "soundHorn" then
			return species == WARDEN_SPECIES -- the finale completes on the catch the horn made possible
		elseif kind == "catchCount" then
			return true
		elseif kind == "catchCondition" then
			return conditionMatches
		elseif kind == "catchTier" then
			return tierMatches
		elseif kind == "catchTierCondition" then
			return tierMatches and conditionMatches
		end
		return false
	end)
end

-- Materials reports a collected node. Counts collect objectives for that material.
function Quests.OnCollect(player: Player, materialId: string)
	DailyQuests.OnCollect(player)
	advance(player, function(objective: QuestData.Objective): boolean
		return objective.kind == "collect" and objective.material == materialId
	end)
end

-- Shop reports a crafted (bought) lure. Counts craft objectives for that lure.
function Quests.OnCraft(player: Player, lureId: string)
	DailyQuests.OnCraft(player, lureId)
	advance(player, function(objective: QuestData.Objective): boolean
		return objective.kind == "craft" and objective.lure == lureId
	end)
end

-- Catching reports a reserved encounter that ended without a catch (fled, despawned, cancelled).
function Quests.OnWardenRetreat(player: Player)
	retreat(player.UserId, true)
end

-- Shop registers Shop.GrantGear here at Init (the require runs Shop -> Quests, never back).
function Quests.SetGearGranter(callback: (Player, string) -> (boolean, string?))
	gearGranter = callback
end

-- Public API -------------------------------------------------------------

function Quests.Init()
	for _, name in ipairs({ "QuestsChanged", "WardenSummoned", "WardenRetreated", "ScrapChanged", "InventoryChanged" }) do
		Net.event(name)
	end
	Net.func("QuestClaim").OnServerInvoke = onQuestClaim
	Net.func("SoundHorn").OnServerInvoke = onSoundHorn

	-- A profile starts the chain on its first step. The join payload carries the quests; the push
	-- covers a client that pulled its profile early.
	PlayerData.OnLoaded(function(player: Player, _profile: Types.Profile)
		PlayerData.Update(player, function(p)
			if not AT_HOME and p.quests.fieldNotes[WORLD_KEY] == nil then
				p.quests.fieldNotes[WORLD_KEY] = FIRST_STEP
			end
		end)
		local live = PlayerData.Get(player)
		if live then
			pushQuests(player, live)
		end
	end)

	Spawner.OnRemoved(onSpawnRemoved)
end

function Quests.Start()
	-- A player who leaves with their Warden out gives it up: the spawn goes, the cooldown runs, no push.
	Players.PlayerRemoving:Connect(function(player: Player)
		retreat(player.UserId, false)
	end)
	if AT_HOME then
		print(("[%s] Quests: this is the home planet; no Field Notes chain, no shrine"):format(Config.WorkingTitle))
		return
	end
	print(("[%s] Quests: Field Notes for world %d, %d steps; warden %s"):format(Config.WorkingTitle, WORLD_ID, #CHAIN, WARDEN_SPECIES))
end

return Quests
