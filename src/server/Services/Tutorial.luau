--!strict
-- ServerScriptService.Server.Services.Tutorial: the first eight minutes (Shared/data/Tutorial.Steps),
-- one step at a time. Other services report what the player did (OnCollect from Materials; OnCatch,
-- OnModuleStarted and OnModuleComplete from Economy) and this service counts it into
-- profile.tutorialCounter for the current step's trigger, advances profile.tutorialStep when the count
-- is reached, and pushes TutorialChanged(step, counter). A poll every Config.TutorialPollSeconds
-- handles the one trigger nobody reports, standing in a biome. A step with `spawn` keeps one wild
-- alien of that species by the camp (Camp.TutorialSpawnOffset, through Spawner.SpawnAt), reserved
-- for the player and with no lifetime, so the trainee catches never depend on luck: it comes back
-- Config.TutorialSpawnRespawnSeconds after it fled, and a rejoin places it again. The client shows the
-- hint and the waypoint; every count and every step change is decided here.
-- Requires run one way: Economy and Materials require this module to report; this module never
-- requires them back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local AnalyticsData = require(Shared.data.Analytics)
local Camp = require(Shared.data.Camp)
local TutorialData = require(Shared.data.Tutorial)
local Biomes = require(Shared.Biomes)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Spawner = require(script.Parent.Spawner)
local Analytics = require(script.Parent.Analytics)

local Tutorial = {}

-- This player's guaranteed alien, out by the camp, and the step it was placed for (a respawn after it
-- fled only happens while the player is still on that step).
type Trainee = { spawnId: string, stepIndex: number }

local STEPS: { TutorialData.Step } = TutorialData.Steps
local FIRST_STEP = 1
local DONE_STEP = #STEPS + 1 -- tutorialStep past the last step: the tutorial is over
local SINGLE = 1 -- a trigger without a count fires on its first match
local TRAINEE_OVERLAY: Types.Overlay = "None"

local trainees: { [number]: Trainee } = {} -- by UserId; at most one per player

-- Steps and progress -----------------------------------------------------

-- The step the player is on and its index, or nil once the tutorial is done (index past the last step).
local function currentStep(profile: Types.Profile): (TutorialData.Step?, number)
	local index = profile.tutorialStep
	return STEPS[index], index
end

local function pushTutorial(player: Player, profile: Types.Profile)
	Net.event("TutorialChanged"):FireClient(player, profile.tutorialStep, profile.tutorialCounter)
end

-- Analytics only: every onboarding funnel step up to the current one, named by its step id ("Done" past
-- the last). Analytics sends each step once per session, so a skip over several steps still reports
-- each in order and a returning player lands on every step already passed.
local function reportFunnel(player: Player, profile: Types.Profile)
	for step = FIRST_STEP, profile.tutorialStep do
		local def = STEPS[step]
		Analytics.Funnel(player, step, if def then def.id else "Done")
	end
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

-- Trainee spawns ---------------------------------------------------------

-- Where the trainee stands: Camp.TutorialSpawnOffset from the camp pad centre (the origin), as a flat
-- point; Spawner.SpawnAt seats it on the surface there (Meadow.GetSurfaceTop).
local function traineePosition(): Vector3
	local offset = Camp.TutorialSpawnOffset
	return Vector3.new(offset.X, 0, offset.Z)
end

-- Makes the player's one trainee match the step: the species the step's `spawn` asks for, or none when
-- the step has no spawn. A trainee of the right species that is still out stays; a stale one (another
-- species, or the step moved on) leaves as a retreat, which schedules no respawn because the tracking
-- is cleared first.
local function ensureTrainee(player: Player, step: TutorialData.Step?, index: number)
	local userId = player.UserId
	local spawnDef = if step then step.spawn else nil
	local wanted = if spawnDef then spawnDef.species else nil
	local trainee = trainees[userId]
	if trainee then
		local spawn = Spawner.GetSpawn(trainee.spawnId)
		if spawn and wanted and spawn.species == wanted then
			trainee.stepIndex = index
			return
		end
		trainees[userId] = nil -- cleared first: the removal below calls back into onSpawnRemoved
		if spawn then
			Spawner.RemoveSpawn(trainee.spawnId, "retreat")
		end
	end
	if not wanted then
		return
	end
	local spawn = Spawner.SpawnAt(traineePosition(), wanted, TRAINEE_OVERLAY, userId, nil)
	if not spawn then
		warn(("[%s] Tutorial: step %d asks for unknown species %s"):format(Config.WorkingTitle, index, wanted))
		return
	end
	trainees[userId] = { spawnId = spawn.spawnId, stepIndex = index }
end

-- A trainee that left without being caught comes back after TutorialSpawnRespawnSeconds, as long as
-- the player is still here, still on that step, and nothing else placed one in the meantime (a
-- rejoin or a later step).
local function scheduleRespawn(userId: number, stepIndex: number)
	task.delay(Config.TutorialSpawnRespawnSeconds, function()
		if trainees[userId] then
			return
		end
		local player = Players:GetPlayerByUserId(userId)
		local profile = if player then PlayerData.Get(player) else nil
		if not player or not profile or profile.tutorialStep ~= stepIndex then
			return
		end
		ensureTrainee(player, STEPS[stepIndex], stepIndex)
	end)
end

-- Every spawn removal passes through here; only this player's trainee matters. Caught: OnCatch
-- advances the step, nothing more to do. Anything else (fled, despawn, retreat) brings it back.
local function onSpawnRemoved(spawn: Spawner.WildSpawn, reason: Spawner.RemoveReason)
	local userId = spawn.reservedFor
	if not userId then
		return
	end
	local trainee = trainees[userId]
	if not trainee or trainee.spawnId ~= spawn.spawnId then
		return
	end
	trainees[userId] = nil
	if reason == "caught" then
		return
	end
	scheduleRespawn(userId, trainee.stepIndex)
end

-- The player is leaving: the trainee goes with them, with no respawn (the tracking is cleared first).
local function forgetTrainee(userId: number)
	local trainee = trainees[userId]
	if not trainee then
		return
	end
	trainees[userId] = nil
	if Spawner.GetSpawn(trainee.spawnId) then
		Spawner.RemoveSpawn(trainee.spawnId, "despawn")
	end
end

-- Advancing ----------------------------------------------------------------

-- A module trigger can be met before its step begins: the Hull Frame finishes while the player is still
-- catching, or completes offline. These two kinds read the profile, so a step that begins already
-- satisfied is skipped at once instead of waiting for a report that will never come again. The other
-- kinds are events (a collect, a catch) or polled (the biome), so they need no catch-up.
local function alreadySatisfied(profile: Types.Profile, trigger: TutorialData.Trigger): boolean
	local kind = trigger.kind
	if kind ~= "moduleStarted" and kind ~= "moduleComplete" then
		return false
	end
	local world = profile.modules[tostring(profile.world.current)]
	local state = if world and trigger.moduleId then world[trigger.moduleId] else nil
	if not state then
		return false
	end
	if kind == "moduleStarted" then
		return state.started or state.completedAt ~= nil
	end
	return state.completedAt ~= nil
end

-- Moves past every step, from the current one, whose trigger the profile already meets, and past all of
-- them when the profile has left the tutorial's world (TutorialData.World: the steps name that world's
-- nodes, trainees and biomes). Runs inside a PlayerData.Update; returns whether anything moved.
local function skipSatisfied(profile: Types.Profile): boolean
	local skipped = false
	if profile.world.current ~= TutorialData.World and profile.tutorialStep < DONE_STEP then
		profile.tutorialStep = DONE_STEP
		profile.tutorialCounter = 0
		return true
	end
	while true do
		local step = STEPS[profile.tutorialStep]
		if not step or not alreadySatisfied(profile, step.trigger) then
			return skipped
		end
		profile.tutorialStep += 1
		profile.tutorialCounter = 0
		skipped = true
	end
end

-- Counts one toward the current step when its trigger `matches`, moves to the next step once the
-- count (SINGLE when the trigger has none) is reached (and on past any step already met, see
-- skipSatisfied), and pushes TutorialChanged when anything moved. A new step with `spawn` places its
-- trainee; one without clears any stale trainee. A no-op once the tutorial is done or when the
-- trigger does not match.
local function report(player: Player, matches: (TutorialData.Trigger) -> boolean)
	local changed = false
	local advanced = false
	local ok = PlayerData.Update(player, function(profile)
		local step = currentStep(profile)
		if not step or not matches(step.trigger) then
			return
		end
		changed = true
		profile.tutorialCounter += 1
		if profile.tutorialCounter >= (step.trigger.count or SINGLE) then
			profile.tutorialStep += 1
			profile.tutorialCounter = 0
			advanced = true
			skipSatisfied(profile)
		end
	end)
	if not ok or not changed then
		return
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	pushTutorial(player, profile)
	if advanced then
		local step, index = currentStep(profile)
		ensureTrainee(player, step, index)
		reportFunnel(player, profile)
	end
end

-- The one trigger nobody reports: standing in the biome a step asks for.
local function pollBiomes()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(player)
		local step = if profile then currentStep(profile) else nil
		if step and step.trigger.kind == "biome" then
			local at = rootPosition(player)
			if at then
				local biome: Types.Biome = Biomes.At(at)
				report(player, function(trigger: TutorialData.Trigger): boolean
					return trigger.kind == "biome" and trigger.biome == biome
				end)
			end
		end
	end
end

-- Hooks ------------------------------------------------------------------
-- All of these are no-ops once the tutorial is done or when the current step's trigger is another kind.

-- Materials reports a collected node. Counts a collect step for that material.
function Tutorial.OnCollect(player: Player, materialId: string)
	report(player, function(trigger: TutorialData.Trigger): boolean
		return trigger.kind == "collect" and trigger.material == materialId
	end)
end

-- Economy.GrantAlien reports every alien that enters a profile. A catchSpecies step needs that species;
-- a catchCount step counts any catch.
function Tutorial.OnCatch(player: Player, species: string)
	report(player, function(trigger: TutorialData.Trigger): boolean
		if trigger.kind == "catchSpecies" then
			return trigger.species == species
		end
		return trigger.kind == "catchCount"
	end)
end

-- Economy reports a module whose clock just started (Scrap paid and every key part in). Completes a
-- moduleStarted step for that module; the Scrap payment alone does not, so the hint names both gates.
function Tutorial.OnModuleStarted(player: Player, moduleId: string)
	report(player, function(trigger: TutorialData.Trigger): boolean
		return trigger.kind == "moduleStarted" and trigger.moduleId == moduleId
	end)
end

-- Economy reports a finished module (income tick, seating, optimize, offline settlement). Completes a
-- moduleComplete step for that module.
function Tutorial.OnModuleComplete(player: Player, moduleId: string)
	report(player, function(trigger: TutorialData.Trigger): boolean
		return trigger.kind == "moduleComplete" and trigger.moduleId == moduleId
	end)
end

-- Public API -------------------------------------------------------------

function Tutorial.Init()
	Net.event("TutorialChanged")

	-- A saved step is kept inside [first, done]; the join payload carries both fields, the push covers
	-- a client that pulled its profile early. A step with a spawn gets its trainee back on rejoin.
	PlayerData.OnLoaded(function(player: Player, _profile: Types.Profile)
		PlayerData.Update(player, function(p)
			p.tutorialStep = math.clamp(p.tutorialStep, FIRST_STEP, DONE_STEP)
			p.tutorialCounter = math.max(p.tutorialCounter, 0)
			skipSatisfied(p) -- a module that finished offline (Economy settles before this runs)
		end)
		local live = PlayerData.Get(player)
		if live then
			pushTutorial(player, live)
			local step, index = currentStep(live)
			ensureTrainee(player, step, index)
			if live.world.current == TutorialData.World then
				reportFunnel(player, live) -- off the tutorial's world the steps were finished or skipped earlier
			end
		end
	end)

	Spawner.OnRemoved(onSpawnRemoved)
end

-- The profile moved to another world (Launch, or the /world command): a profile off the tutorial's world
-- is done with it (skipSatisfied), so the hint clears and any trainee goes. A no-op on the tutorial's
-- own world or once the tutorial is over.
function Tutorial.OnWorldChanged(player: Player)
	local moved = false
	local before = DONE_STEP
	local ok = PlayerData.Update(player, function(p)
		before = p.tutorialStep
		moved = skipSatisfied(p)
	end)
	local profile = PlayerData.Get(player)
	if not ok or not moved or not profile then
		return
	end
	pushTutorial(player, profile)
	local step, stepIndex = currentStep(profile)
	ensureTrainee(player, step, stepIndex)
	-- Not a funnel advance: the steps were left behind, not reached, so the funnel is not walked (it would
	-- count every skipped step as reached). One event records the step the player was on.
	Analytics.Event(player, AnalyticsData.Events.TutorialSkipped, before, { world = tostring(profile.world.current) })
end

-- Developer override (Studio commands): jump to step `index` (clamped to [first, done]) with an empty
-- count, place that step's trainee, and push. Skips on past steps already met, like a real advance.
function Tutorial.DevSetStep(player: Player, index: number)
	local ok = PlayerData.Update(player, function(p)
		p.tutorialStep = math.clamp(math.floor(index), FIRST_STEP, DONE_STEP)
		p.tutorialCounter = 0
		skipSatisfied(p)
	end)
	local profile = PlayerData.Get(player)
	if not ok or not profile then
		return
	end
	pushTutorial(player, profile)
	local step, stepIndex = currentStep(profile)
	ensureTrainee(player, step, stepIndex)
	reportFunnel(player, profile)
end

function Tutorial.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		forgetTrainee(player.UserId)
	end)
	task.spawn(function()
		while true do
			task.wait(Config.TutorialPollSeconds)
			pollBiomes()
		end
	end)
	print(("[%s] Tutorial: %d steps; trainee aliens return after %ss"):format(Config.WorkingTitle, #STEPS, tostring(Config.TutorialSpawnRespawnSeconds)))
end

return Tutorial
