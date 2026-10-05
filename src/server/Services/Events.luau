--!strict
-- ServerScriptService.Server.Services.Events: the Meteor Shower on a fixed server clock.
-- A shower starts at every multiple of Config.ShowerIntervalSeconds of os.time() (the wall clock,
-- shared by every server) and runs for Config.ShowerDurationSeconds, so every server in the game
-- showers at the same moment and the state needs no save: it is a pure function of the time. While a
-- shower runs this service switches the "Shower" condition on in WorldClock (the Spawns tables list
-- the Cosmic Ra-dish under it), the Spawner gives the Cosmic tier its share (Events.IsShowerActive),
-- and everyone's luck carries Config.ShowerLuckBonus (Events.ServerLuckBonus, read by Buffs.Luck).
-- Clients hear ShowerChanged (FireAllClients) at every start and end, every Config.ShowerPushSeconds
-- while a shower runs or is within Config.ShowerWarnSeconds of starting (so the countdown chip stays
-- honest), and a late joiner asks GetShower once. The client only renders.
-- Events.Force (Studio commands, guarded by Dev) overrides the clock for one run: a forced shower runs
-- ShowerDurationSeconds from now; a forced end mutes the clock's own shower until it would have ended.
--
-- Requires run one way: this module requires WorldClock, Net and Config only. Buffs requires this
-- module for ServerLuckBonus and registers its LuckChanged broadcast through Events.OnShowerChanged
-- at Init, so this module never requires Buffs back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Net = require(Shared.Net)
local WorldClock = require(script.Parent.WorldClock)

local Events = {}

local CONDITION = "Shower" -- the WorldClock extra condition this service switches (Spawns.luau keys on it)
local SNAPSHOT_RATE_PER_SECOND = 2 -- GetShower calls per player per second
local TICK_SECONDS = 1 -- how often the loop looks at the clock; a start or end is seen within this

local listeners: { (boolean) -> () } = {} -- Buffs.PushLuckAll, see the header
local wasActive = false -- the last state the loop acted on
local lastPush = 0 -- os.clock() of the last ShowerChanged broadcast
local forcedEndsAt: number? = nil -- os.time() a forced shower (Events.Force) ends; beats the clock while in the future
local mutedUntil: number? = nil -- os.time() until which the clock's own shower is ignored (a forced end)

-- Clock maths -------------------------------------------------------------
-- phase = seconds since the most recent start (os.time() modulo the interval). The shower is active
-- for the first ShowerDurationSeconds of every interval; the next start is interval - phase away.
-- Expired overrides are simply ignored here, so nothing needs clearing.

local function phase(): number
	return os.time() % Config.ShowerIntervalSeconds
end

local function secondsToNextStart(): number
	return Config.ShowerIntervalSeconds - phase()
end

local function snapshot(): Types.ShowerState
	local now = os.time()
	local forcedEnd = forcedEndsAt
	if forcedEnd and now < forcedEnd then
		return { active = true, secondsLeft = forcedEnd - now, nextInSeconds = 0 }
	end
	local p = now % Config.ShowerIntervalSeconds
	local active = p < Config.ShowerDurationSeconds
	local muted = mutedUntil
	if muted and now < muted then
		active = false
	end
	return {
		active = active,
		secondsLeft = if active then Config.ShowerDurationSeconds - p else 0,
		nextInSeconds = if active then 0 else Config.ShowerIntervalSeconds - p,
	}
end

local function broadcast(state: Types.ShowerState)
	Net.event("ShowerChanged"):FireAllClients(state)
	lastPush = os.clock()
end

-- A start or an end: the condition flips, every client hears it, and the listeners (Buffs) run, each
-- in its own thread so one failing service cannot stall the clock.
local function flip(state: Types.ShowerState)
	wasActive = state.active
	WorldClock.SetCondition(CONDITION, state.active)
	broadcast(state)
	for _, callback in ipairs(listeners) do
		task.spawn(callback, state.active)
	end
end

local function tick()
	local state = snapshot()
	if state.active ~= wasActive then
		flip(state)
		return
	end
	local watching = state.active or state.nextInSeconds <= Config.ShowerWarnSeconds
	if watching and os.clock() - lastPush >= Config.ShowerPushSeconds then
		broadcast(state)
	end
end

-- Remotes ----------------------------------------------------------------

-- GetShower() -> ShowerState. The clock for a late joiner; nil only when rate limited.
local function onGetShower(player: Player): Types.ShowerState?
	if not Net.allow(player, "GetShower", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	return snapshot()
end

-- Public API -------------------------------------------------------------

-- The shower clock right now, computed from os.time(): active, secondsLeft (0 when not active) and
-- nextInSeconds to the next start (0 while active).
function Events.GetShower(): Types.ShowerState
	return snapshot()
end

function Events.IsShowerActive(): boolean
	return snapshot().active
end

-- The luck every player on the server carries while a shower runs (Buffs.Luck adds it before the cap).
function Events.ServerLuckBonus(): number
	return if Events.IsShowerActive() then Config.ShowerLuckBonus else 0
end

-- Server-side hook: `callback` runs with the new active flag at every start and end. Plain callbacks,
-- not a BindableEvent, so the argument keeps its type (Buffs re-sends LuckChanged to everyone).
function Events.OnShowerChanged(callback: (boolean) -> ())
	table.insert(listeners, callback)
end

-- Developer override (Studio commands): true starts a shower now that ends ShowerDurationSeconds later
-- (a running one is extended to that); false ends the current shower now, whether forced or from the
-- clock, and mutes the clock's own shower until the moment it would have ended on its own. Either way
-- the start or end handling runs at once (condition, ShowerChanged, luck pushes).
function Events.Force(active: boolean)
	local now = os.time()
	if active then
		forcedEndsAt = now + Config.ShowerDurationSeconds
		mutedUntil = nil
	else
		forcedEndsAt = nil
		local p = now % Config.ShowerIntervalSeconds
		if p < Config.ShowerDurationSeconds then
			mutedUntil = now + (Config.ShowerDurationSeconds - p)
		end
	end
	tick()
end

function Events.Init()
	Net.event("ShowerChanged")
	Net.func("GetShower").OnServerInvoke = onGetShower
end

function Events.Start()
	-- A server that boots mid-shower joins it at once; otherwise the loop sees the next start.
	local state = snapshot()
	wasActive = state.active
	if state.active then
		WorldClock.SetCondition(CONDITION, true)
	end
	lastPush = os.clock()

	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			tick()
		end
	end)

	local nextStart = secondsToNextStart()
	if state.active then
		print(("[%s] Events: Meteor Shower active now, %ds left; every %ss for %ss, next start in %ds"):format(
			Config.WorkingTitle,
			state.secondsLeft,
			tostring(Config.ShowerIntervalSeconds),
			tostring(Config.ShowerDurationSeconds),
			nextStart
		))
	else
		print(("[%s] Events: Meteor Shower every %ss for %ss, next start in %ds"):format(
			Config.WorkingTitle,
			tostring(Config.ShowerIntervalSeconds),
			tostring(Config.ShowerDurationSeconds),
			nextStart
		))
	end
end

return Events
