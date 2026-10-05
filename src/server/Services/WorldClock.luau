--!strict
-- ServerScriptService.Server.Services.WorldClock: the server-owned day/night cycle and weather.
-- Lives on the server because spawn conditions (Day/Night/Rain species) must be judged by one clock
-- that no client can nudge. Clients only receive ClockChanged and the GetClock snapshot for the HUD.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local Net = require(Shared.Net)

local world: Worlds.WorldDef = Worlds[Config.CurrentWorld]

local WorldClock = {}

local rng = Random.new()
local isNight = false
local weather: string = world.weather.normal[1]
local phaseEndsAt = 0 -- os.clock() when day flips to night or back
local weatherEndsAt = 0
local listeners: { (Types.Condition) -> () } = {} -- server services told on every change (Materials gates nodes by condition)
local extras: { [string]: boolean } = {} -- conditions other services switch on (Events: "Shower")

local function snapshot(): Types.ClockState
	return {
		isNight = isNight,
		weather = weather,
		secondsLeft = math.max(0, math.floor(phaseEndsAt - os.clock())),
		weatherSecondsLeft = math.max(0, math.floor(weatherEndsAt - os.clock())),
	}
end

local function applyLighting(instant: boolean)
	local target = if isNight then Config.NightClockTime else Config.DayClockTime
	if instant then
		Lighting.ClockTime = target
		return
	end
	-- Tween through the intervening hours so dusk and dawn read as a sweep, not a snap.
	local info = TweenInfo.new(Config.ClockTweenSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, { ClockTime = target }):Play()
end

local function broadcast()
	Net.event("ClockChanged"):FireAllClients(snapshot())
end

-- The world's special weather rolls with its own chance (never twice in a row); otherwise any normal
-- state other than the current one, so a roll always reads as a change.
local function rollWeather(): string
	local special = world.weather.special
	if weather ~= special.id and rng:NextNumber() < special.chance then
		return special.id
	end
	local states = world.weather.normal
	if #states <= 1 then
		return states[1]
	end
	local choice = weather
	while choice == weather do
		choice = states[rng:NextInteger(1, #states)]
	end
	return choice
end

local function isKnownWeather(state: string): boolean
	return state == world.weather.special.id or table.find(world.weather.normal, state) ~= nil
end

-- Public API -------------------------------------------------------------

-- The single condition the spawn tables are judged against: the world's special weather beats Night
-- beats Day (World 1: Rain).
function WorldClock.GetCondition(): Types.Condition
	if weather == world.weather.special.id then
		return (weather :: any) :: Types.Condition
	end
	return if isNight then "Night" else "Day"
end

-- Every condition active right now: the special weather while it runs, plus Night or Day. Spawns and
-- nodes gate on this set, so a rainy night still counts as night.
function WorldClock.GetConditions(): { Types.Condition }
	local out: { Types.Condition } = {}
	if weather == world.weather.special.id then
		table.insert(out, (weather :: any) :: Types.Condition)
	end
	table.insert(out, if isNight then "Night" else "Day")
	for name, on in pairs(extras) do
		if on then
			table.insert(out, (name :: any) :: Types.Condition)
		end
	end
	return out
end

-- Switches an extra condition on or off (the Meteor Shower) and tells every listener, so spawn tables
-- and nodes gated on it react at once.
function WorldClock.SetCondition(name: string, on: boolean)
	if (extras[name] == true) == on then
		return
	end
	extras[name] = on
	local condition: Types.Condition = WorldClock.GetCondition()
	for _, callback in ipairs(listeners) do
		task.spawn(callback, condition)
	end
end

function WorldClock.HasCondition(condition: string): boolean
	if condition == "Any" then
		return true
	end
	for _, active in ipairs(WorldClock.GetConditions()) do
		if active == condition then
			return true
		end
	end
	return false
end

-- The special weather of the world this place runs (for banners and the Dev commands).
function WorldClock.GetSpecialWeather(): Worlds.SpecialWeather
	return world.weather.special
end

function WorldClock.IsNight(): boolean
	return isNight
end

function WorldClock.GetWeather(): string
	return weather
end

function WorldClock.GetState(): Types.ClockState
	return snapshot()
end

-- Server-side hook: `callback` runs with the new GetCondition() value each time the clock broadcasts a
-- day/night or weather change. Plain callbacks, not a BindableEvent, so the argument keeps its type.
function WorldClock.OnChanged(callback: (Types.Condition) -> ())
	table.insert(listeners, callback)
end

-- Developer override (Studio commands): force night or day and/or a weather state now. The forced
-- phase keeps its normal length from this moment, so the cycle resumes on its own.
function WorldClock.Force(night: boolean?, state: string?)
	local now = os.clock()
	if night ~= nil then
		isNight = night
		phaseEndsAt = now + (if isNight then Config.NightSeconds else Config.DaySeconds)
		applyLighting(false)
	end
	if state and isKnownWeather(state) then
		weather = state
		weatherEndsAt = now + rng:NextNumber(Config.WeatherMinSeconds, Config.WeatherMaxSeconds)
	end
	broadcast()
	local condition: Types.Condition = WorldClock.GetCondition()
	for _, callback in ipairs(listeners) do
		task.spawn(callback, condition)
	end
end

function WorldClock.Init()
	Net.event("ClockChanged")
	local now = os.clock()
	isNight = false
	phaseEndsAt = now + Config.DaySeconds
	weatherEndsAt = now + rng:NextNumber(Config.WeatherMinSeconds, Config.WeatherMaxSeconds)
	applyLighting(true)

	-- Late joiners ask for the current state once their HUD exists.
	Net.func("GetClock").OnServerInvoke = function(player: Player)
		if not Net.allow(player, "GetClock", 2) then
			return nil
		end
		return snapshot()
	end
end

function WorldClock.Start()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			local changed = false
			if now >= phaseEndsAt then
				isNight = not isNight
				phaseEndsAt = now + (if isNight then Config.NightSeconds else Config.DaySeconds)
				applyLighting(false)
				changed = true
			end
			if now >= weatherEndsAt then
				weather = rollWeather()
				weatherEndsAt = now + rng:NextNumber(Config.WeatherMinSeconds, Config.WeatherMaxSeconds)
				changed = true
			end
			if changed then
				broadcast()
				-- each listener runs in its own thread so one slow or failing service cannot stall the clock
				local condition: Types.Condition = WorldClock.GetCondition()
				for _, callback in ipairs(listeners) do
					task.spawn(callback, condition)
				end
			end
		end
	end)
end

return WorldClock
