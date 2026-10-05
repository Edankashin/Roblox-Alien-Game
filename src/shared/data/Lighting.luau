--!strict
-- The look of the light per world and per condition (docs/vault/06-art-pipelines/Look-Plan.md, pass L1).
-- The client's LightingDirector merges Base <- Worlds[worldId] <- one condition look per active condition
-- (later entries in ConditionOrder win) and tweens Lighting, its Atmosphere, Bloom, ColorCorrection and
-- SunRays to the result over Config.LightingTweenSeconds. ClockTime itself stays the server's (WorldClock).
-- Colours are RGB 0..255 triples. Sky ids of 0 keep the place's own sky. Lighting.Technology cannot be
-- set from a script: set it to Future in the place by hand (TESTING milestone 22).

export type Rgb = { number }
export type Atmosphere = { Density: number?, Offset: number?, Color: Rgb?, Decay: Rgb?, Glare: number?, Haze: number? }
export type Bloom = { Intensity: number?, Size: number?, Threshold: number? }
export type ColorCorrection = { Brightness: number?, Contrast: number?, Saturation: number?, TintColor: Rgb? }
export type SunRays = { Intensity: number?, Spread: number? }
export type Sky = { Bk: number, Dn: number, Ft: number, Lf: number, Rt: number, Up: number, SunAngularSize: number?, StarCount: number? }
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
}

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
	Snow = { Atmosphere = { Density = 0.4, Color = { 230, 235, 240 }, Haze = 3 } },
	Rain = {
		Brightness = 1.4,
		Atmosphere = { Density = 0.45, Color = { 150, 160, 170 }, Decay = { 120, 130, 140 }, Glare = 0, Haze = 3 },
		ColorCorrection = { Contrast = 0.05, Saturation = -0.25, TintColor = { 215, 225, 235 } },
		SunRays = { Intensity = 0 },
	},
	Blizzard = {
		Brightness = 1.2,
		Atmosphere = { Density = 0.6, Color = { 235, 240, 245 }, Decay = { 220, 225, 235 }, Glare = 0, Haze = 6 },
		ColorCorrection = { Brightness = 0.1, Saturation = -0.4, TintColor = { 245, 250, 255 } },
		SunRays = { Intensity = 0 },
	},
	Shower = {
		Atmosphere = { Color = { 255, 200, 150 }, Glare = 0.4 },
		Bloom = { Intensity = 1.2, Size = 40 },
		ColorCorrection = { Saturation = 0.3, TintColor = { 255, 230, 210 } },
	},
}

return {
	Base = Base,
	Worlds = Worlds,
	Conditions = Conditions,
	-- Merge order: the first listed is applied first, so the last active one listed here wins.
	ConditionOrder = { "Fog", "Snow", "Night", "Rain", "Blizzard", "Shower" },
}
