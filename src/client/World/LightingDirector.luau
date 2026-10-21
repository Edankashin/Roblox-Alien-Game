--!strict
-- StarterPlayerScripts.Client.World.LightingDirector: gives each world and weather its look
-- (docs/vault/06-art-pipelines/Look-Plan.md, pass L1). The target is a pure function of the place's world
-- and the active conditions (plus, for a condition with a biome row, the biome the player stands in):
-- data/Lighting.luau Base, then Worlds[Place.WorldId()], then each active condition's look in ConditionOrder,
-- each followed by that world's WorldConditions refinement and then the player's biome's BiomeConditions
-- one (a field set later wins; nested tables merge field by field, Rgb triples replace whole). The result drives Lighting, one Atmosphere, one BloomEffect, one
-- ColorCorrectionEffect, one SunRaysEffect and (only when a look names real ids) one Sky, all created under
-- Lighting by this module and reused on rejoin. The first application is instant; later changes tween over
-- Config.LightingTweenSeconds (Quad, Out) or snap under Reduced Motion. A look may also carry a `groundTint`
-- (a colour and a 0 to 1 strength, World 1's Night rows do): every part tagged LightingData.GroundTag then wears its day
-- colour lerped toward the tint's colour by the strength, the same tween as the light, and goes back to the day colour when
-- the look stops naming one. The day colour is kept on the part as the GroundDayColor attribute (the first time the part is
-- seen) and every target is computed from it, so repeated applies never drift; a part that streams in mid-night is tinted
-- on arrival. One tween per ground part per change, nothing per frame. Active conditions: "Night" while the
-- clock mirror says night, the clock's weather when Conditions has a look for it (Fog, Snow, Rain,
-- Blizzard...), "Shower" while a Meteor Shower runs. ClockTime stays the server's (WorldClock), except that a biome night at any hour (BiomeAlways, the Starhollow) holds this client's sky at night.
-- Once at Start the place-level engine settings go on (applyEngineSettings): LightingStyle, then
-- PrioritizeLightingQuality, then the deprecated Technology as the fallback, each in its own pcall. Pure presentation:
-- the clock and the shower are the server's; this only picks how they look.

local CollectionService = game:GetService("CollectionService")
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
local GROUND_DAY_COLOR = "GroundDayColor" -- the attribute a ground part keeps its day colour in (client-side only)

type GroundGoal = { color: Color3, strength: number }

local started = false
local applied = false -- the first application is instant; every later one tweens
local lastSignature = ""
local tweens: { Tween } = {} -- the tweens in flight, cancelled before the next application starts new ones
local atmosphere: Instance? = nil
local bloom: Instance? = nil
local colorCorrection: Instance? = nil
local sunRays: Instance? = nil
local sky: Instance? = nil
local groundParts: { [BasePart]: boolean } = {} -- every part tagged LightingData.GroundTag that exists now
local groundGoal: GroundGoal? = nil -- the tint the current look names, nil while it names none
local clockHeld = false -- true while a BiomeAlways biome holds the sky's ClockTime at night on this client
local clockWasHeld = false -- true from the moment we moved ClockTime until we hand it back
local clockEaseUntil = 0 -- os.clock() until which our own ClockTime ease runs (the hold below leaves it alone)

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
	-- a biome that is night at any hour (data/Lighting BiomeAlways: the Starhollow Forest) counts its condition as active
	local always = LightingData.BiomeAlways[State.GetBiome()]
	if always then
		set[always] = true
	end
	local out: { string } = {}
	for _, name in ipairs(LightingData.ConditionOrder) do
		if set[name] then
			table.insert(out, name)
		end
	end
	return out
end

-- The biome whose refinements count right now: the player's biome when some active condition has a row for it,
-- else "". Biomes without a row for the active conditions all look the same, so crossing between them is not a
-- change and never restarts a tween (the Meadow into the Cave by day, say).
local function activeBiome(names: { string }): string
	local biome: string = State.GetBiome()
	local rows = LightingData.BiomeConditions[biome]
	if rows then
		for _, name in ipairs(names) do
			if rows[name] ~= nil then
				return biome
			end
		end
	end
	return ""
end

-- Base <- the place's world <- each active condition (then this world's refinement of it, then the biome's): one
-- full look.
local function buildTarget(names: { string }, biome: string): LightingData.Look
	local target: Table = {}
	mergeInto(target, LightingData.Base :: any)
	local worldId = Place.WorldId()
	local world = LightingData.Worlds[worldId]
	if world then
		mergeInto(target, world :: any)
	end
	local worldRows = LightingData.WorldConditions[worldId]
	local biomeRows = LightingData.BiomeConditions[biome]
	for _, name in ipairs(names) do
		local look = LightingData.Conditions[name]
		if look then
			mergeInto(target, look :: any)
		end
		local worldLook = if worldRows then worldRows[name] else nil
		if worldLook then
			mergeInto(target, worldLook :: any)
		end
		local biomeLook = if biomeRows then biomeRows[name] else nil
		if biomeLook then
			mergeInto(target, biomeLook :: any)
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

-- The colour a ground part should wear now: its day colour, lerped toward the current tint when the look names one.
-- Always computed from the stored day colour, never from the part's present colour, so nothing drifts.
local function groundTarget(part: BasePart): Color3
	local stored = part:GetAttribute(GROUND_DAY_COLOR)
	local day: Color3 = if typeof(stored) == "Color3" then stored else part.Color
	local goal = groundGoal
	return if goal then day:Lerp(goal.color, goal.strength) else day
end

-- A ground part appears (at start, or streamed in later): its colour now is its day colour, kept as an attribute the first
-- time it is seen, and a tint already in force reaches it at once.
local function trackGround(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	if instance:GetAttribute(GROUND_DAY_COLOR) == nil then
		instance:SetAttribute(GROUND_DAY_COLOR, instance.Color)
	end
	groundParts[instance] = true
	if groundGoal then
		instance.Color = groundTarget(instance)
	end
end

local function untrackGround(instance: Instance)
	if instance:IsA("BasePart") then
		groundParts[instance] = nil
	end
end

-- Points every ground part at the look's tint (or its day colour when the look names none): one tween, or one assignment
-- when instant, per part that is not there yet. A tint missing its colour or its strength counts as none.
local function applyGround(spec: Table?, instant: boolean)
	local goal: GroundGoal? = nil
	if spec then
		local color, strength = spec["color"], spec["strength"]
		if type(color) == "table" and type(strength) == "number" then
			goal = { color = toColor(color :: LightingData.Rgb), strength = math.clamp(strength, 0, 1) }
		end
	end
	groundGoal = goal
	for part in pairs(groundParts) do
		local target = groundTarget(part)
		if part.Color ~= target then
			drive(part, { Color = target }, instant)
		end
	end
end

-- The place-level engine settings from data/Lighting.luau, set once. Each is its own pcall so an engine without the
-- property (or one that refuses a script the write) never errors, and the next one still runs. LightingStyle
-- supersedes Technology; Technology is the fallback for older clients. It is not scriptable at runtime in
-- current Studio (the Rojo project files set it on the place), so its pcall is expected to fail quietly.
local function applyEngineSettings()
	local styleOk, style = pcall(function()
		return Enum.LightingStyle:FromName(LightingData.Style)
	end)
	if styleOk and style ~= nil then
		pcall(function()
			Lighting.LightingStyle = style
		end)
	end
	pcall(function()
		Lighting.PrioritizeLightingQuality = LightingData.PrioritizeLightingQuality
	end)
	local technologyOk, technology = pcall(function()
		return Enum.Technology:FromName(LightingData.Technology)
	end)
	if technologyOk and technology ~= nil then
		pcall(function()
			Lighting.Technology = technology
		end)
	end
end

-- The sky's time of day on this client: in a biome that is night at any hour (BiomeAlways "Night", the Starhollow Forest) it eases
-- to Config.NightClockTime and stays there while the server's own clock replicates over it; outside, it goes back to the server's
-- (night or day by the clock mirror), so leaving the forest at noon brings the sun back. Pure presentation: the server's ClockTime
-- and conditions are unchanged.
local function clockGoal(): number?
	if LightingData.BiomeAlways[State.GetBiome()] == "Night" then
		return Config.NightClockTime
	end
	return nil
end

local function applyClock(instant: boolean)
	local goal = clockGoal()
	clockHeld = goal ~= nil
	if goal then
		clockWasHeld = true
	elseif clockWasHeld then
		clockWasHeld = false -- hand the sky back once
	else
		return -- not ours to move: the server's clock and its own tween
	end
	local target = goal or (if State.GetClock().isNight then Config.NightClockTime else Config.DayClockTime)
	if math.abs(Lighting.ClockTime - target) < 0.01 then
		return
	end
	clockEaseUntil = os.clock() + (if instant then 0 else Config.LightingTweenSeconds)
	drive(Lighting, { ClockTime = target }, instant)
end

-- Re-merges and applies the look. Unchanged inputs (world, active conditions and the biome when it matters) are skipped unless
-- `force`, so the repeated "profile" fires every State topic also answers never restart a tween.
local function apply(force: boolean)
	local names = activeConditions()
	local biome = activeBiome(names)
	local signature = tostring(Place.WorldId()) .. "|" .. table.concat(names, ",") .. "|" .. biome
	if not force and signature == lastSignature then
		return
	end
	lastSignature = signature

	local look = (buildTarget(names, biome) :: any) :: Table
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
	applyGround(look["groundTint"] :: Table?, instant)
	applyClock(instant)
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

	applyEngineSettings()
	retireForeignEffects()
	atmosphere = findOrCreate("Atmosphere", "LookAtmosphere")
	bloom = findOrCreate("BloomEffect", "LookBloom")
	colorCorrection = findOrCreate("ColorCorrectionEffect", "LookColorCorrection")
	sunRays = findOrCreate("SunRaysEffect", "LookSunRays")

	-- The ground the night tints: the parts the server tagged, those already here and any that stream in later.
	CollectionService:GetInstanceAddedSignal(LightingData.GroundTag):Connect(trackGround)
	CollectionService:GetInstanceRemovedSignal(LightingData.GroundTag):Connect(untrackGround)
	for _, part in ipairs(CollectionService:GetTagged(LightingData.GroundTag)) do
		trackGround(part)
	end

	State.OnChanged("clock", function()
		apply(false)
	end)
	State.OnChanged("shower", function()
		apply(false)
	end)
	State.OnChanged("world", function()
		apply(false)
	end)
	-- The Forest wears the stronger night; walking in or out tweens over Config.LightingTweenSeconds.
	State.OnChanged("biome", function()
		apply(false)
	end)
	-- The server's clock replicates over a held night sky (its tween on a day/night change): hold it.
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		if clockHeld and os.clock() > clockEaseUntil and math.abs(Lighting.ClockTime - Config.NightClockTime) > 0.01 then
			Lighting.ClockTime = Config.NightClockTime
		end
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

-- The look conditions active right now, in merge order (for a debug print).

return LightingDirector
