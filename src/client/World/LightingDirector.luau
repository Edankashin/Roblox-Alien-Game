--!strict
-- StarterPlayerScripts.Client.World.LightingDirector: gives each world and weather its look
-- (docs/vault/06-art-pipelines/Look-Plan.md, pass L1). The target is a pure function of the place's world
-- and the active conditions: data/Lighting.luau Base, then Worlds[Place.WorldId()], then each active
-- condition's look in ConditionOrder (a field set later wins; nested tables merge field by field, Rgb
-- triples replace whole). The result drives Lighting, one Atmosphere, one BloomEffect, one
-- ColorCorrectionEffect, one SunRaysEffect and (only when a look names real ids) one Sky, all created under
-- Lighting by this module and reused on rejoin. The first application is instant; later changes tween over
-- Config.LightingTweenSeconds (Quad, Out) or snap under Reduced Motion. Active conditions: "Night" while the
-- clock mirror says night, the clock's weather when Conditions has a look for it (Fog, Snow, Rain,
-- Blizzard...), "Shower" while a Meteor Shower runs. ClockTime stays the server's (WorldClock) and
-- Lighting.Technology is not scriptable, so neither is touched. Pure presentation: the clock and the
-- shower are the server's; this only picks how they look.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local LightingData = require(Shared:WaitForChild("data"):WaitForChild("Lighting"))
local Place = require(Shared:WaitForChild("Place"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))

local LightingDirector = {}

type Table = { [string]: any }

local LIGHTING_PROPS: { string } = { "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation", "ShadowSoftness" }
local ATMOSPHERE_PROPS: { string } = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" }
local BLOOM_PROPS: { string } = { "Intensity", "Size", "Threshold" }
local COLOR_CORRECTION_PROPS: { string } = { "Brightness", "Contrast", "Saturation", "TintColor" }
local SUN_RAYS_PROPS: { string } = { "Intensity", "Spread" }
-- Sky look field -> Sky property. Ids of 0 mean "keep the place's own sky".
local SKY_FACES: { [string]: string } = { Bk = "SkyboxBk", Dn = "SkyboxDn", Ft = "SkyboxFt", Lf = "SkyboxLf", Rt = "SkyboxRt", Up = "SkyboxUp" }
local SKY_SCALARS: { string } = { "SunAngularSize", "StarCount" }

local started = false
local applied = false -- the first application is instant; every later one tweens
local lastSignature = ""
local tweens: { Tween } = {} -- the tweens in flight, cancelled before the next application starts new ones
local atmosphere: Instance? = nil
local bloom: Instance? = nil
local colorCorrection: Instance? = nil
local sunRays: Instance? = nil
local sky: Instance? = nil

-- Helpers ----------------------------------------------------------------

-- The Lighting child of this class and name, created when missing (so a rejoin reuses it).
local function findOrCreate(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = Lighting
	return created
end

-- Deep-merges `from` into `into`: a nested table merges field by field, an Rgb triple (an array) replaces
-- whole, anything else overwrites. Always copies, so the data tables are never mutated or aliased.
local function mergeInto(into: Table, from: Table)
	for key, value in pairs(from) do
		if type(value) == "table" then
			if (value :: { any })[1] ~= nil then
				into[key] = table.clone(value :: { any })
			else
				local existing = into[key]
				local destination: Table
				if type(existing) == "table" then
					destination = existing :: Table
				else
					destination = {}
					into[key] = destination
				end
				mergeInto(destination, value :: Table)
			end
		else
			into[key] = value
		end
	end
end

local function toColor(rgb: LightingData.Rgb): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- The property -> value goals for the listed props that `source` sets; Rgb triples become Color3.
local function goalsOf(source: Table?, props: { string }): Table
	local goals: Table = {}
	if source then
		for _, prop in ipairs(props) do
			local value = source[prop]
			if value ~= nil then
				goals[prop] = if type(value) == "table" then toColor(value :: LightingData.Rgb) else value
			end
		end
	end
	return goals
end

local function cancelTweens()
	for _, tween in ipairs(tweens) do
		tween:Cancel()
	end
	tweens = {}
end

-- Sets the goals on `instance` at once, or eases them in when `instant` is false.
local function drive(instance: Instance, goals: Table, instant: boolean)
	if next(goals) == nil then
		return
	end
	if instant then
		for prop, value in pairs(goals) do
			(instance :: any)[prop] = value
		end
		return
	end
	local info = TweenInfo.new(Config.LightingTweenSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, goals)
	table.insert(tweens, tween)
	tween:Play()
end

-- Every look condition that holds right now, in merge order (ConditionOrder: the last listed wins).
local function activeConditions(): { string }
	local set: { [string]: boolean } = {}
	local clock = State.GetClock()
	if clock.isNight then
		set["Night"] = true
	end
	if LightingData.Conditions[clock.weather] ~= nil then
		set[clock.weather] = true
	end
	local shower = State.GetShower()
	if shower.active then
		set["Shower"] = true
	end
	local out: { string } = {}
	for _, name in ipairs(LightingData.ConditionOrder) do
		if set[name] then
			table.insert(out, name)
		end
	end
	return out
end

-- Base <- the place's world <- each active condition: one full look.
local function buildTarget(names: { string }): LightingData.Look
	local target: Table = {}
	mergeInto(target, LightingData.Base :: any)
	local world = LightingData.Worlds[Place.WorldId()]
	if world then
		mergeInto(target, world :: any)
	end
	for _, name in ipairs(names) do
		local look = LightingData.Conditions[name]
		if look then
			mergeInto(target, look :: any)
		end
	end
	return target :: any
end

-- The Sky, only once a look names a real id; a look with every id 0 leaves the place's own sky alone.
local function applySky(look: Table?)
	if not look then
		return
	end
	local named = false
	for field in pairs(SKY_FACES) do
		local id = look[field]
		if type(id) == "number" and id ~= 0 then
			named = true
		end
	end
	if not named then
		return
	end
	local instance = sky
	if not instance then
		instance = findOrCreate("Sky", "LookSky")
		sky = instance
	end
	local target = instance :: any
	for field, prop in pairs(SKY_FACES) do
		local id = look[field]
		if type(id) == "number" and id ~= 0 then
			target[prop] = string.format("rbxassetid://%d", id)
		end
	end
	for _, prop in ipairs(SKY_SCALARS) do
		local value = look[prop]
		if value ~= nil then
			target[prop] = value
		end
	end
end

-- Re-merges and applies the look. Unchanged inputs (world and active conditions) are skipped unless
-- `force`, so the repeated "profile" fires every State topic also answers never restart a tween.
local function apply(force: boolean)
	local names = activeConditions()
	local signature = tostring(Place.WorldId()) .. "|" .. table.concat(names, ",")
	if not force and signature == lastSignature then
		return
	end
	lastSignature = signature

	local look = (buildTarget(names) :: any) :: Table
	local instant = not applied or Prefs.ReducedMotion() or Config.LightingTweenSeconds <= 0
	applied = true
	cancelTweens()

	local lightingGoals = goalsOf(look, LIGHTING_PROPS)
	drive(Lighting, lightingGoals, instant)
	local shadows = look["GlobalShadows"]
	if type(shadows) == "boolean" then
		Lighting.GlobalShadows = shadows
	end

	local atmosphereInstance = atmosphere
	if atmosphereInstance then
		drive(atmosphereInstance, goalsOf(look["Atmosphere"] :: Table?, ATMOSPHERE_PROPS), instant)
	end
	local bloomInstance = bloom
	if bloomInstance then
		drive(bloomInstance, goalsOf(look["Bloom"] :: Table?, BLOOM_PROPS), instant)
	end
	local colorInstance = colorCorrection
	if colorInstance then
		drive(colorInstance, goalsOf(look["ColorCorrection"] :: Table?, COLOR_CORRECTION_PROPS), instant)
	end
	local raysInstance = sunRays
	if raysInstance then
		drive(raysInstance, goalsOf(look["SunRays"] :: Table?, SUN_RAYS_PROPS), instant)
	end
	applySky(look["Sky"] :: Table?)
end

-- Public ------------------------------------------------------------------

-- Finds or creates the effect instances, applies the look at once, then follows the clock, the shower and
-- the world.
-- A place file can carry its own Atmosphere and post-effects from before the looks existed; two Atmospheres
-- fight (the older one won in Studio) and foreign effects stack on ours. The looks own Lighting on the
-- client: a stray Atmosphere goes, other effects are switched off and left in place. The Sky stays.
local function retireForeignEffects()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name:sub(1, 4) == "Look" then
			continue
		end
		if child:IsA("Atmosphere") then
			child:Destroy()
		elseif child:IsA("PostEffect") then
			child.Enabled = false
		end
	end
end

function LightingDirector.Start()
	if started then
		return
	end
	started = true

	retireForeignEffects()
	atmosphere = findOrCreate("Atmosphere", "LookAtmosphere")
	bloom = findOrCreate("BloomEffect", "LookBloom")
	colorCorrection = findOrCreate("ColorCorrectionEffect", "LookColorCorrection")
	sunRays = findOrCreate("SunRaysEffect", "LookSunRays")

	State.OnChanged("clock", function()
		apply(false)
	end)
	State.OnChanged("shower", function()
		apply(false)
	end)
	State.OnChanged("world", function()
		apply(false)
	end)
	-- Reduced Motion only changes how the next change lands; one switched on mid-tween snaps it home.
	Prefs.OnChanged(function()
		if applied and Prefs.ReducedMotion() then
			apply(true)
		end
	end)
	apply(true)
end

-- Re-merges and applies now, even when nothing changed (tests that edit the data tables).
function LightingDirector.Reapply()
	apply(true)
end

-- The look conditions active right now, in merge order (for a debug print).
function LightingDirector.ActiveConditions(): { string }
	return activeConditions()
end

return LightingDirector
