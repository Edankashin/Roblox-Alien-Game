--!strict
-- ServerScriptService.Server.Services.Weekly: the weekly drop (data/Weekly) on the server's wall clock.
-- The week and its drop are a pure function of os.time() and the data tables (Shared/WeeklyMath), so every
-- server in the game agrees and nothing needs saving. This service reads that function at Start and then every
-- Weekly.PushSeconds, and when the drop changes (a new week, or Dev's /week offset) it acts once: it asks
-- WorldClock to hold the drop's weather all week (nil clears it), tells every client through WeeklyChanged
-- (the offset; each client recomputes the drop from WeeklyMath with the server time), reports WeeklyFlip to
-- Analytics for every player online and prints one line. A late joiner asks GetWeekly once for the offset.
-- Spawner reads ActiveSpecies and OverlayActive for the Alien of the Week and the week's overlay.
-- It never decides what spawns or what an overlay is worth (Spawner and Overlays), never grants or counts a
-- catch, and never touches the client: the client only renders.
--
-- Requires run one way: this module requires WorldClock, Analytics, Net, Place and shared data and maths
-- only; Spawner requires this module, so nothing here requires Spawner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local WeeklyData = require(Shared.data.Weekly)
local AnalyticsData = require(Shared.data.Analytics)
local WeeklyMath = require(Shared.WeeklyMath)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local WorldClock = require(script.Parent.WorldClock)
local Analytics = require(script.Parent.Analytics)

local Weekly = {}

local SNAPSHOT_RATE_PER_SECOND = 2 -- GetWeekly calls per player per second

local offset = 0 -- whole weeks the rotation is shifted by; Dev's /week sets it, 0 in play
local current: WeeklyMath.Current? = nil -- the week as of the last read
local hasRead = false -- whether a read has been acted on yet (the first one always counts as a change)
local readOffset = 0 -- the offset the last acted-on read used

-- The week as one line: "week 2026-10-02, drop 1 Panpipe, Aurora" (or the usual weather).
local function describe(state: WeeklyMath.Current?): string
	if not state then
		return "no drop"
	end
	return ("week %s, drop %d %s, %s"):format(state.weekId, state.index, state.drop.species, state.drop.weather or "usual weather")
end

local function sameWeek(a: WeeklyMath.Current?, b: WeeklyMath.Current?): boolean
	if a == nil or b == nil then
		return a == b
	end
	return a.weekId == b.weekId and a.index == b.index
end

-- Reads the week from the clock. Anything new (a different week, index or offset, or the first read) is acted
-- on once: the weather override, the WeeklyChanged broadcast, one WeeklyFlip per player online, one print.
local function read()
	local fresh = WeeklyMath.Current(os.time(), offset)
	local changed = not hasRead or readOffset ~= offset or not sameWeek(current, fresh)
	current = fresh
	if not changed then
		return
	end
	hasRead = true
	readOffset = offset

	local drop = if fresh then fresh.drop else nil
	WorldClock.SetWeatherOverride(if drop then drop.weather else nil)
	Net.event("WeeklyChanged"):FireAllClients(offset)
	if fresh and drop then
		for _, player in ipairs(Players:GetPlayers()) do
			Analytics.Event(player, AnalyticsData.Events.WeeklyFlip, fresh.index, {
				species = drop.species,
				weather = drop.weather or "none",
			})
		end
	end
	print(("[%s] Weekly: %s"):format(Config.WorkingTitle, describe(fresh)))
end

-- GetWeekly() -> offset. The only thing a late joiner needs besides the server time; nil only when rate limited.
local function onGetWeekly(player: Player): number?
	if not Net.allow(player, "GetWeekly", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	return offset
end

-- Public API -------------------------------------------------------------

-- The week as of the last read (at most Weekly.PushSeconds old), nil before Start or with an empty rotation.
function Weekly.Current(): WeeklyMath.Current?
	return current
end

-- The Alien of the Week when it spawns in this place's world, else nil.
function Weekly.ActiveSpecies(): string?
	local state = current
	if state and state.drop.worldId == Place.WorldId() then
		return state.drop.species
	end
	return nil
end

-- The week's overlay while the week's weather is the one showing (the weather the clock holds all week, or
-- the world's special weather that interrupts it, does not count), else nil.
function Weekly.OverlayActive(): string?
	local state = current
	if not state then
		return nil
	end
	local drop = state.drop
	if drop.weather ~= nil and WorldClock.GetWeather() == drop.weather then
		return drop.overlay
	end
	return nil
end

-- The week line Weekly prints at a flip, for Dev.
function Weekly.Describe(): string
	return describe(current)
end

function Weekly.GetOffset(): number
	return offset
end

-- Developer override (Dev's /week): shifts the rotation by `n` whole weeks and re-reads at once, so the
-- weather, the clients and the Spawner follow within the same frame.
function Weekly.SetOffset(n: number)
	offset = math.floor(n)
	read()
end

function Weekly.Init()
	Net.event("WeeklyChanged")
	Net.func("GetWeekly").OnServerInvoke = onGetWeekly
end

function Weekly.Start()
	read()
	task.spawn(function()
		while true do
			task.wait(WeeklyData.PushSeconds)
			read()
		end
	end)
end

return Weekly
