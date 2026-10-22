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
	-- Verdant Crash Site, block cells (2026-10-21 worlds pass): the dioramas' warm toy light. A clear blue sky over a pale warm horizon
	-- (Blocky-Style E3: day blue 62B3EC over D8EEF5), warm sun on the tops (ColorShift_Top), soft but present shadows so every block
	-- edge reads, saturation lifted so the greens and the petals pop, a little bloom on the lanterns and the water, gentle sun rays.
	[1] = {
		Brightness = 2.3,
		OutdoorAmbient = { 140, 136, 122 },
		ColorShift_Top = { 36, 26, 8 },
		EnvironmentSpecularScale = 0.6,
		ShadowSoftness = 0.35,
		Atmosphere = { Density = 0.27, Offset = 0.2, Color = { 216, 236, 244 }, Decay = { 98, 170, 230 }, Glare = 0.3, Haze = 1 },
		Bloom = { Intensity = 0.65, Size = 26, Threshold = 1.4 },
		ColorCorrection = { Contrast = 0.12, Saturation = 0.26, TintColor = { 255, 248, 232 } },
		SunRays = { Intensity = 0.12, Spread = 0.5 },
		Sky = { Bk = 0, Dn = 0, Ft = 0, Lf = 0, Rt = 0, Up = 0, SunAngularSize = 16, StarCount = 3000 },
	},
	-- Frostbyte, block cells: crisp, cold and still colourful (not grey). A cold blue sky over a pale haze (78A8D6 over DDE8F2), cool
	-- light on the tops, the exposure eased a touch so the snow never clips white, bloom a little stronger so snow and ice glow
	-- softly, saturation kept above zero so the pines, the heater's orange and the aliens hold their colour.
	[2] = {
		Brightness = 2.4,
		OutdoorAmbient = { 158, 172, 198 },
		ColorShift_Top = { 10, 20, 34 },
		ExposureCompensation = -0.1,
		EnvironmentSpecularScale = 0.9,
		ShadowSoftness = 0.3,
		Atmosphere = { Density = 0.32, Offset = 0.25, Color = { 221, 232, 242 }, Decay = { 120, 168, 214 }, Glare = 0.15, Haze = 1.4 },
		Bloom = { Intensity = 0.75, Size = 28, Threshold = 1.3 },
		ColorCorrection = { Contrast = 0.13, Saturation = 0.12, TintColor = { 238, 246, 255 } },
		SunRays = { Intensity = 0.08, Spread = 0.4 },
		Sky = { Bk = 0, Dn = 0, Ft = 0, Lf = 0, Rt = 0, Up = 0, SunAngularSize = 11, StarCount = 4500 },
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
		Ambient = { 52, 58, 82 },
		OutdoorAmbient = { 84, 96, 128 },
		Atmosphere = { Density = 0.35, Glare = 0, Haze = 1.5 },
		Bloom = { Intensity = 0.8 },
		ColorCorrection = { Saturation = 0, TintColor = { 212, 222, 255 } },
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
-- World 1's Night is the Moonlit Forest palette (media/tiktok/NOTES.md ZPLYSA3uR: teal and violet with warm lantern
-- light from the props, not a dark scene). This is the mild version, the one the Meadow and the Cave wear: a soft
-- blue-green, so the catch bar and the wild aliens stay easy to read. The night pass of 2026-10-22 (Mac job 53 step 5: the
-- game's Starhollow was one flat navy against the store thumbnail) lifted every ambient channel by about 40 and moved the
-- ground tint from indigo to teal: a surface shows its colour times the ambient, so a dark ambient on a dark tint gave navy
-- twice. Against the plain Night row nothing is lower: Brightness stays 1, ExposureCompensation is never below the Base 0,
-- and every channel of Ambient and OutdoorAmbient is at least the plain row's ({ 52, 58, 82 } and { 84, 96, 128 });
-- tests/Lighting.spec.luau holds that line. Saturation is above the plain row's and the tint a touch warmer
-- ({ 212, 222, 255 }) so the warm lantern light glows against the cool air.
local WorldConditions: { [number]: ConditionLooks } = {
	-- Frostbyte's night is the aurora night (data/WorldFx Aurora ribbons hang in its sky): teal-green light from above over a cool
	-- cyan air, never darker than the plain Night row (every ambient channel at or above it, brightness and exposure unchanged), the
	-- snow and ice catching the colour (lifted 2026-10-22 so the frozen lake reads cyan, not slate). No groundTint: World 2 keeps
	-- its ground (tests/Lighting.spec.luau).
	[2] = {
		Night = {
			Ambient = { 62, 90, 116 },
			OutdoorAmbient = { 96, 134, 166 },
			ColorShift_Top = { 30, 92, 78 },
			Atmosphere = { Density = 0.3, Offset = 0.3, Color = { 84, 138, 158 }, Decay = { 44, 84, 134 }, Glare = 0, Haze = 1.2 },
			Bloom = { Intensity = 1, Size = 32, Threshold = 1.1 },
			ColorCorrection = { Saturation = 0.2, TintColor = { 224, 242, 255 } },
		},
	},
	[1] = {
		Night = {
			Ambient = { 74, 92, 128 },
			OutdoorAmbient = { 108, 134, 172 },
			ColorShift_Top = { 20, 40, 64 },
			-- A soft blue-green fog; the Offset is raised from 0.25 so far trees keep their outline against the sky.
			Atmosphere = { Density = 0.33, Offset = 0.3, Color = { 84, 110, 160 }, Decay = { 52, 96, 140 }, Glare = 0, Haze = 1.4 },
			Bloom = { Intensity = 0.7, Size = 26, Threshold = 1.3 },
			ColorCorrection = { Saturation = 0.2, TintColor = { 226, 238, 255 } },
			-- The ground wore its day green into the night (Studio retest 2026-10-14: "green field at night") and then, in the
			-- indigo version, went navy (job 53 step 5): it is lerped toward a teal, so the Meadow floor (6FBF4A) reads 5CA164,
			-- a cool green that is still a ground but no longer a daytime field.
			groundTint = { color = { 64, 116, 138 }, strength = 0.4 },
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
			-- Violet in the shade, teal-blue from the sky, a lift of exposure on top: the trees keep their blue-violet and teal and the
			-- ground its moss, lit from the lanterns' warm pools (Lamps below), never one dark navy (job 53 step 5).
			Ambient = { 120, 114, 156 },
			OutdoorAmbient = { 124, 146, 182 },
			ColorShift_Top = { 50, 64, 120 },
			ExposureCompensation = 0.4,
			-- Denser, more violet fog with a higher Offset, its decay teal so the horizon glows teal under the violet: the far trees
			-- stand as silhouettes in it.
			Atmosphere = { Density = 0.38, Offset = 0.42, Color = { 92, 100, 172 }, Decay = { 52, 104, 150 }, Glare = 0, Haze = 1.8 },
			-- The threshold sits above a lit surface so only the Neon lamps, glowcaps and motes bloom: at 0.9 every lit tree glowed white.
			Bloom = { Intensity = 0.85, Size = 32, Threshold = 1.15 },
			ColorCorrection = { Saturation = 0.3, TintColor = { 238, 236, 255 } },
			-- Teal-violet and stronger than the Meadow's: every ground part is tinted by it while the player stands in the Forest
			-- (the Forest's own patch, 2E6B2B, reads 315D5B, a mossy teal; the Meadow floor reads 5CA164).
			groundTint = { color = { 52, 80, 140 }, strength = 0.5 },
		},
	},
}

-- The warm lamps of the generated worlds (lanterns, the campfire, the glowcaps, the crystals): every recipe PointLight of
-- data/WorldKit carries the tag; the client's LampDirector keeps only the nearest few lit (a phone cannot light 55 lamps),
-- fades the rest, and at night lifts the ones that stay: brightness x NightBrightnessScale, range x NightRangeScale, so a
-- lantern throws a warm pool on the path while its day value (the recipe's own) is a barely visible fill. The recipe's colour,
-- range and brightness stay in tools/blocky/worlds/kit.json; these are the caps and the night lift.
local Lamps = {
	Tag = "RecipeLamp", -- the CollectionService tag the server puts on every recipe PointLight (Services/Meadow)
	MaxLit = 12, -- lamps lit at once: the nearest to the camera
	MaxLitTouch = 7, -- the same on a touch device (a phone)
	Radius = 90, -- studs from the camera past which a lamp is never lit, however few are near
	CheckSeconds = 0.5, -- how often the nearest are re-picked
	FadeSeconds = 0.6, -- a lamp fades in or out over this when the pick changes
	NightBrightnessScale = 1.9, -- brightness multiplier at night (eased in with the lighting tween)
	NightRangeScale = 1.25, -- range multiplier at night
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
	Lamps = Lamps,
	-- A biome that wears a condition's look at any hour while the local player stands in it (B48: the Starhollow Forest, World 1's
	-- Forest region, is moonlit night even at noon). LightingDirector counts the condition as active there, so the Night row, World 1's
	-- refinement and the Forest's own row all merge, eases the sky's ClockTime to Config.NightClockTime on the client (the server's
	-- clock is untouched and comes back on the way out), and WeatherFx and WorldFx run their night layers there.
	BiomeAlways = { Forest = "Night" } :: { [string]: string },
	-- Merge order: the first listed is applied first, so the last active one listed here wins.
	ConditionOrder = { "Fog", "Snow", "Night", "Aurora", "Rain", "Blizzard", "Shower" },
}
