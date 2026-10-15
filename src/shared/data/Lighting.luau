--!strict
-- The look of the light per world and per condition (docs/vault/06-art-pipelines/Look-Plan.md, pass L1).
-- The client's LightingDirector merges Base <- Worlds[worldId] <- one condition look per active condition
-- (later entries in ConditionOrder win) and tweens Lighting, its Atmosphere, Bloom, ColorCorrection and
-- SunRays to the result over Config.LightingTweenSeconds. A condition can be refined for one world
-- (WorldConditions) and, inside that world, for the biome the player stands in (BiomeConditions): each
-- refinement merges straight after the condition it refines. ClockTime itself stays the server's (WorldClock).
-- Colours are RGB 0..255 triples. Sky ids of 0 keep the place's own sky. The place-level engine settings sit at the
-- bottom of the table (Style, PrioritizeLightingQuality, Technology): Lighting.LightingStyle supersedes
-- Lighting.Technology, which stays only as the fallback for older clients (docs/vault/04-roblox-engine/Lighting-Style.md).

export type Rgb = { number }
export type Atmosphere = { Density: number?, Offset: number?, Color: Rgb?, Decay: Rgb?, Glare: number?, Haze: number? }
export type Bloom = { Intensity: number?, Size: number?, Threshold: number? }
export type ColorCorrection = { Brightness: number?, Contrast: number?, Saturation: number?, TintColor: Rgb? }
export type SunRays = { Intensity: number?, Spread: number? }
export type Sky = { Bk: number, Dn: number, Ft: number, Lf: number, Rt: number, Up: number, SunAngularSize: number?, StarCount: number? }
-- The ground's colour while the look applies: each ground part's day colour lerped toward `color` by `strength` (0 to 1).
-- The ground is every part tagged GroundTag (the server tags the floor and the biome patches, Services/Meadow); a look with
-- no groundTint leaves the ground at its day colour, so the tint lifts by itself when the row stops applying.
export type GroundTint = { color: Rgb, strength: number }
export type Look = {
	Brightness: number?,
	Ambient: Rgb?,
	OutdoorAmbient: Rgb?,
	ColorShift_Top: Rgb?,
	EnvironmentDiffuseScale: number?,
	EnvironmentSpecularScale: number?,
	ExposureCompensation: number?,
	GlobalShadows: boolean?,
	ShadowSoftness: number?,
	Atmosphere: Atmosphere?,
	Bloom: Bloom?,
	ColorCorrection: ColorCorrection?,
	SunRays: SunRays?,
	Sky: Sky?,
	groundTint: GroundTint?,
}

-- A look per condition name (Conditions keys).
export type ConditionLooks = { [string]: Look }

-- Everything a look can set, with its default: the merge starts here so a tween always has a full target.
local Base: Look = {
	Brightness = 2,
	Ambient = { 70, 70, 70 },
	OutdoorAmbient = { 128, 128, 128 },
	ColorShift_Top = { 0, 0, 0 },
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	ExposureCompensation = 0,
	GlobalShadows = true,
	ShadowSoftness = 0.2,
	Atmosphere = { Density = 0.3, Offset = 0.25, Color = { 199, 170, 107 }, Decay = { 106, 112, 125 }, Glare = 0.2, Haze = 1 },
	Bloom = { Intensity = 0.6, Size = 24, Threshold = 1.5 },
	ColorCorrection = { Brightness = 0, Contrast = 0.1, Saturation = 0.1, TintColor = { 255, 255, 255 } },
	SunRays = { Intensity = 0.1, Spread = 0.6 },
	Sky = { Bk = 0, Dn = 0, Ft = 0, Lf = 0, Rt = 0, Up = 0, SunAngularSize = 14, StarCount = 2000 },
}

-- Per world (Worlds.luau ids). A world without an entry uses Base.
local Worlds: { [number]: Look } = {
	-- Verdant Crash Site: warm green-gold meadow light, a touch more saturation.
	[1] = {
		Atmosphere = { Density = 0.32, Color = { 210, 190, 120 }, Glare = 0.3, Haze = 1.2 },
		Bloom = { Intensity = 0.7 },
		ColorCorrection = { Saturation = 0.2, TintColor = { 255, 250, 235 } },
	},
	-- Frostbyte: cold blue-white, hazier, desaturated, soft sun.
	[2] = {
		OutdoorAmbient = { 150, 165, 185 },
		Atmosphere = { Density = 0.38, Color = { 200, 220, 240 }, Decay = { 160, 190, 220 }, Glare = 0.1, Haze = 2 },
		ColorCorrection = { Contrast = 0.15, Saturation = 0, TintColor = { 235, 245, 255 } },
		SunRays = { Intensity = 0.05 },
	},
}

-- Per active condition (WorldClock conditions and normal weathers), merged over the world look in the order
-- below: a later entry wins where two set the same field, so the Meteor Shower's warm night beats plain Night.
local Conditions: { [string]: Look } = {
	-- The weekly drop's Aurora (data/Weekly): green and violet light over the whole sky, a touch dimmer, strongest at night
	-- (it sits after Night in ConditionOrder, so its tint wins over the night look).
	Aurora = {
		Brightness = 1.6,
		Ambient = { 52, 84, 78 },
		OutdoorAmbient = { 88, 140, 128 },
		ColorShift_Top = { 70, 210, 160 },
		Atmosphere = { Color = { 130, 210, 185 }, Decay = { 90, 70, 150 }, Glare = 0.3, Haze = 1.4 },
		Bloom = { Intensity = 0.7, Size = 30, Threshold = 0.9 },
		ColorCorrection = { Saturation = 0.12, TintColor = { 228, 255, 243 } },
	},
	Night = {
		Brightness = 1,
		Ambient = { 40, 45, 60 },
		OutdoorAmbient = { 60, 70, 95 },
		Atmosphere = { Density = 0.35, Glare = 0, Haze = 1.5 },
		Bloom = { Intensity = 0.8 },
		ColorCorrection = { Saturation = -0.1, TintColor = { 210, 220, 255 } },
		SunRays = { Intensity = 0 },
	},
	Fog = { Atmosphere = { Density = 0.5, Color = { 190, 195, 200 }, Decay = { 180, 180, 180 }, Haze = 4, Glare = 0 }, ColorCorrection = { Saturation = -0.1 } },
	Snow = { Atmosphere = { Density = 0.5, Offset = 0.35, Color = { 230, 235, 240 }, Decay = { 200, 210, 220 }, Haze = 5 } },
	Rain = {
		Brightness = 1.4,
		Atmosphere = { Density = 0.45, Color = { 150, 160, 170 }, Decay = { 120, 130, 140 }, Glare = 0, Haze = 3 },
		ColorCorrection = { Contrast = 0.05, Saturation = -0.25, TintColor = { 215, 225, 235 } },
		SunRays = { Intensity = 0 },
	},
	Blizzard = {
		Brightness = 1.2,
		-- a white-out: density near the top of the range and full haze so the sky itself goes white
		Atmosphere = { Density = 0.9, Offset = 0.6, Color = { 245, 248, 250 }, Decay = { 235, 240, 245 }, Glare = 0, Haze = 10 },
		ColorCorrection = { Brightness = 0.15, Saturation = -0.5, TintColor = { 248, 250, 255 } },
		SunRays = { Intensity = 0 },
	},
	Shower = {
		Atmosphere = { Color = { 255, 200, 150 }, Glare = 0.4 },
		Bloom = { Intensity = 1.2, Size = 40 },
		ColorCorrection = { Saturation = 0.3, TintColor = { 255, 230, 210 } },
	},
}

-- A condition seen in one world (Worlds.luau ids), merged right after the plain Conditions look of the same name.
-- World 1's Night is the Moonlit Forest palette (media/tiktok/NOTES.md ZPLYSA3uR: indigo, violet and teal with
-- warm-white light from the props, not a dark scene). This is the mild version, the one the Meadow and the Cave
-- wear, so the catch bar and the wild aliens stay easy to read. Against the plain Night row nothing is lower:
-- Brightness stays 1, ExposureCompensation stays at the Base 0 (unset), and every channel of Ambient and
-- OutdoorAmbient is at least the plain row's ({ 40, 45, 60 } and { 60, 70, 95 }); tests/Lighting.spec.luau holds
-- that line. Saturation goes from -0.1 to +0.1 so the indigo reads as colour, not grey, and the tint is a touch
-- warmer than the plain row's ({ 210, 220, 255 }) so warm-white lights glow against it.
local WorldConditions: { [number]: ConditionLooks } = {
	[1] = {
		Night = {
			Ambient = { 46, 46, 84 },
			OutdoorAmbient = { 74, 76, 128 },
			ColorShift_Top = { 24, 22, 56 },
			-- Violet-blue fog; the Offset is raised from 0.25 so far trees keep their outline against the sky.
			Atmosphere = { Density = 0.35, Offset = 0.32, Color = { 78, 72, 138 }, Decay = { 50, 56, 120 }, Glare = 0, Haze = 1.5 },
			Bloom = { Intensity = 0.9, Size = 28, Threshold = 1.2 },
			ColorCorrection = { Saturation = 0.1, TintColor = { 222, 224, 255 } },
			-- The ground wore its day green into the night (Studio retest 2026-10-14: "green field at night"): it is lerped
			-- toward the fog's indigo. The Meadow floor (6FBF4A) reads 5A836C, still a ground but no longer a green field.
			groundTint = { color = { 64, 58, 150 }, strength = 0.45 },
		},
	},
}

-- A condition seen from one biome (the biome the local player stands in, Types.Biome; each biome name belongs to
-- one world, so no world key). Merged after the world's refinement of the same condition, so it is the stronger
-- version: the Forest at night is the Moonlit Forest proper. Same floor as the world row, so a Forest is never
-- darker than the plain Night: only the colour, the fog, the bloom and the tint go further. The Forest's own row
-- is the one the fireflies and light drips (data/Weather Layers) sit in; the Meadow keeps the milder world row.
local BiomeConditions: { [string]: ConditionLooks } = {
	Forest = {
		Night = {
			Ambient = { 50, 46, 96 },
			OutdoorAmbient = { 78, 74, 140 },
			ColorShift_Top = { 44, 30, 96 },
			-- Denser, more violet fog with a higher Offset: the far trees stand as dark silhouettes in it.
			Atmosphere = { Density = 0.42, Offset = 0.5, Color = { 70, 60, 142 }, Decay = { 36, 70, 118 }, Glare = 0, Haze = 2 },
			Bloom = { Intensity = 1.1, Size = 36, Threshold = 0.9 },
			ColorCorrection = { Saturation = 0.2, TintColor = { 232, 226, 255 } },
			-- Deeper into the violet than the Meadow's, and stronger: every ground part is tinted by it while the player
			-- stands in the Forest (the Forest's own patch, 2E6B2B, reads 36486B; the Meadow floor reads 506978).
			groundTint = { color = { 60, 48, 150 }, strength = 0.6 },
		},
	},
}

return {
	-- Place-level engine settings, applied once by the director (not tweened, not per look).
	Style = "Realistic", -- Enum.LightingStyle item name: "Realistic" or "Soft". Players on graphics quality below 4 are forced to Soft by the engine.
	PrioritizeLightingQuality = true, -- true keeps shadows and shaders good near the camera as quality drops; false keeps view distance
	Technology = "Future", -- Enum.Technology item name. LightingStyle supersedes it; kept as the fallback for older clients.
	GroundTag = "GroundTint", -- the CollectionService tag the server puts on every ground part (a hand-built ground part needs it by hand)
	Base = Base,
	Worlds = Worlds,
	Conditions = Conditions,
	WorldConditions = WorldConditions,
	BiomeConditions = BiomeConditions,
	-- Merge order: the first listed is applied first, so the last active one listed here wins.
	ConditionOrder = { "Fog", "Snow", "Night", "Aurora", "Rain", "Blizzard", "Shower" },
}
