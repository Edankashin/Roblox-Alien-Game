--!strict
-- StarterPlayerScripts.Client.World.LampDirector: the warm lamps of the generated worlds (lanterns, the campfire, the glowcaps, the
-- crystals) at night. The server gives every recipe PointLight the data/Lighting Lamps.Tag tag (Services/Meadow, from the recipes
-- of data/WorldKit); this keeps only the nearest few lit (Lamps.MaxLit, Lamps.MaxLitTouch on a phone, none past Lamps.Radius studs),
-- fades the rest out and in over Lamps.FadeSeconds, and at night lifts the lit ones (brightness x Lamps.NightBrightnessScale, range x
-- Lamps.NightRangeScale), so a lantern throws a warm pool on the path and a phone never lights 55 lamps at once. The day value is the
-- recipe's own, so the day look is the one the server built, only with the far lamps off. Pure presentation: every change is to the
-- client's copy of the light, nothing here reaches the server. Night is the clock's, or a biome that is always night (the Starhollow
-- Forest, data/Lighting BiomeAlways), the same test WeatherFx and LightingDirector use.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local LightingData = require(Shared:WaitForChild("data"):WaitForChild("Lighting"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local LampDirector = {}

local Lamps = LightingData.Lamps
local OFF_BELOW = 0.02 -- a faded level under this turns the light off outright

type Lamp = {
	light: PointLight,
	brightness: number, -- the recipe's, as the server built it
	range: number,
	level: number, -- 0 (off) to 1 (lit), eased toward `target`
	target: number,
}

local started = false
local lamps: { [PointLight]: Lamp } = {}
local nightMix = 0 -- 0 by day, 1 at night, eased over Config.LightingTweenSeconds
local nightTarget = 0
local moving = false -- some lamp or the night mix is still easing

-- The lamps lit at once on this device.
local function limit(): number
	if UserInputService.TouchEnabled then
		return Lamps.MaxLitTouch
	end
	return Lamps.MaxLit
end

local function isNight(): boolean
	return State.GetClock().isNight or LightingData.BiomeAlways[State.GetBiome()] == "Night"
end

-- Where a light stands in the world (its Attachment's point, or its part's).
local function positionOf(light: PointLight): Vector3?
	local parent = light.Parent
	if parent and parent:IsA("Attachment") then
		return parent.WorldPosition
	end
	if parent and parent:IsA("BasePart") then
		return parent.Position
	end
	return nil
end

-- Writes one lamp's light from its level and the night mix.
local function render(lamp: Lamp)
	local light = lamp.light
	if lamp.level <= OFF_BELOW then
		light.Enabled = false
		return
	end
	light.Enabled = true
	light.Brightness = lamp.brightness * (1 + (Lamps.NightBrightnessScale - 1) * nightMix) * lamp.level
	light.Range = lamp.range * (1 + (Lamps.NightRangeScale - 1) * nightMix)
end

local function track(light: PointLight)
	if lamps[light] then
		return
	end
	local lamp: Lamp = { light = light, brightness = light.Brightness, range = light.Range, level = 0, target = 0 }
	lamps[light] = lamp
	render(lamp) -- off until the first pick, so a streamed-in lamp never pops on past the cap
	moving = true
end

local function untrack(light: PointLight)
	lamps[light] = nil
end

-- Re-picks the nearest lamps to the camera: those become the targets at 1, every other 0.
local function pick()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local origin = camera.CFrame.Position
	local near: { { lamp: Lamp, distance: number } } = {}
	local radiusSquared = Lamps.Radius * Lamps.Radius
	for _, lamp in pairs(lamps) do
		local position = positionOf(lamp.light)
		local distance = if position then (position - origin).Magnitude else math.huge
		if distance * distance <= radiusSquared then
			table.insert(near, { lamp = lamp, distance = distance })
		else
			lamp.target = 0
		end
	end
	table.sort(near, function(a, b)
		return a.distance < b.distance
	end)
	local allowed = limit()
	for index, entry in ipairs(near) do
		entry.lamp.target = if index <= allowed then 1 else 0
	end
	moving = true
end

-- One frame: ease every lamp's level and the night mix, and write only the lights that changed.
local function step(dt: number)
	if not moving then
		return
	end
	local fade = dt / math.max(Lamps.FadeSeconds, 0.05)
	local mixStep = dt / math.max(Config.LightingTweenSeconds, 0.05)
	local mixMoved = nightMix ~= nightTarget
	if mixMoved then
		nightMix = if nightMix < nightTarget then math.min(nightTarget, nightMix + mixStep) else math.max(nightTarget, nightMix - mixStep)
	end
	local any = mixMoved
	for _, lamp in pairs(lamps) do
		local changed = mixMoved and lamp.level > OFF_BELOW
		if lamp.level ~= lamp.target then
			lamp.level = if lamp.level < lamp.target then math.min(lamp.target, lamp.level + fade) else math.max(lamp.target, lamp.level - fade)
			changed = true
			any = true
		end
		if changed then
			render(lamp)
		end
	end
	moving = any
end

-- Public ------------------------------------------------------------------

-- How many lamps are lit now (level above zero) and tracked in all (for tests and the perf line of the Mac job).
function LampDirector.Counts(): (number, number)
	local lit, all = 0, 0
	for _, lamp in pairs(lamps) do
		all += 1
		if lamp.light.Enabled then
			lit += 1
		end
	end
	return lit, all
end

function LampDirector.Start()
	if started then
		return
	end
	started = true
	local tag = Lamps.Tag
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		if instance:IsA("PointLight") then
			track(instance)
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
		if instance:IsA("PointLight") then
			track(instance)
		end
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
		if instance:IsA("PointLight") then
			untrack(instance)
		end
	end)
	local function readNight()
		nightTarget = if isNight() then 1 else 0
		moving = true
	end
	State.OnChanged("clock", readNight)
	State.OnChanged("biome", readNight)
	readNight()
	nightMix = nightTarget -- the first read does not ease: a player who joins at night sees the night lamps at once
	pick()
	RunService.Heartbeat:Connect(step)
	task.spawn(function()
		while true do
			task.wait(Lamps.CheckSeconds)
			pick()
		end
	end)
end

return LampDirector
