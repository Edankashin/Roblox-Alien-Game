--!strict
-- Per-species effects and idle motion, drawn by the client's World.SpeciesFx (the server never reads this table).
-- Species: one row per species id (all 35): an element label, the effect layers strongest first, and an idle motion.
-- Tiers: what each rarity may draw of them (Common one subtle layer ... Cosmic and Secret everything plus extras).
-- Caps: the per-client budgets. Attach: the body regions layers hang on, as fractions of the alien's bounds.
-- Every length in a layer is a fraction of the alien's own height ("heights"), so the data names no stud; the idle
-- amplitudes are the only studs and degrees. Colours are hex. Sprites are keys of Icons.Particles (nil keeps the soft
-- default sprite, and so does a key whose id is still 0). Lint (tools/lint_data.py) checks every id, region, sprite,
-- rate cap and the tier ladder; tests/Effects.spec.luau checks the gating in EffectsMath.
-- To add a species: one row in Species below (and its row in data/Species). Keep the rows strongest layer first.
local Types = require(script.Parent.Parent.types.Types)

-- Where layers hang. x and z run from the bounds' centre (-0.5 to 0.5 is the whole side; the face is toward -z), y from the
-- feet (0) to the top of the head (1).
local attach: { [string]: Types.AttachPoint } = {
	Top = { x = 0, y = 1, z = 0 },
	Halo = { x = 0, y = 1.2, z = 0 },
	Eyes = { x = 0, y = 0.7, z = -0.42 },
	Mouth = { x = 0, y = 0.4, z = -0.5 },
	Body = { x = 0, y = 0.5, z = 0 },
	Back = { x = 0, y = 0.75, z = 0.15 },
	BackL = { x = -0.3, y = 0.7, z = 0.15 },
	BackR = { x = 0.3, y = 0.7, z = 0.15 },
	FrontL = { x = -0.45, y = 0.3, z = -0.35 },
	FrontR = { x = 0.45, y = 0.3, z = -0.35 },
	Tail = { x = 0, y = 0.4, z = 0.5 },
	Feet = { x = 0, y = 0.02, z = 0 },
}

-- Budgets. The rate caps are particles per second for one emitter after the tier's rateScale; a phone is a device with a
-- touch screen. MaxBeams and MaxLights are per alien. MaxActive is how many aliens in a client keep their species effects
-- (the nearest first, re-ranked every Config.VfxFxRecheckSeconds); the rest keep only the tier aura. ActiveDistance (studs)
-- is how far from the camera an alien may be to keep them. MaxSoundsPerSecond is how many species sounds start across all
-- aliens in one second (a crowd of lightning boars is not a drum roll).
local caps = {
	MobileRateCap = 100,
	DesktopRateCap = 400,
	MaxBeams = 4,
	MaxLights = 1,
	MaxActive = 12,
	ActiveDistance = 90,
	MaxSoundsPerSecond = 2,
}

-- What a rarity may draw. layersAllowed is how many of a species' layers (strongest first) it draws; 6 is "all". The trail
-- and orbit flags add the Extras below when the species has no layer of that kind; groundRing adds the Extras ring; dark
-- sinks every colour toward Dark.Color. Each step up the ladder is at least as grand as the one below (lint checks it).
local tiers: { [string]: Types.TierFxRule } = {
	Common = { layersAllowed = 1, rateScale = 0.4, sizeScale = 0.7, lightScale = 0.4, trail = false, orbit = false, groundRing = false, dark = false },
	Uncommon = { layersAllowed = 1, rateScale = 0.6, sizeScale = 0.8, lightScale = 0.55, trail = false, orbit = false, groundRing = false, dark = false },
	Rare = { layersAllowed = 2, rateScale = 0.8, sizeScale = 0.9, lightScale = 0.7, trail = false, orbit = false, groundRing = false, dark = false },
	Epic = { layersAllowed = 3, rateScale = 1, sizeScale = 1, lightScale = 0.85, trail = false, orbit = false, groundRing = false, dark = false },
	Legendary = { layersAllowed = 6, rateScale = 1.3, sizeScale = 1.2, lightScale = 1, trail = false, orbit = false, groundRing = true, dark = false },
	Cosmic = { layersAllowed = 6, rateScale = 1.6, sizeScale = 1.4, lightScale = 1.25, trail = true, orbit = true, groundRing = true, dark = false },
	Secret = { layersAllowed = 6, rateScale = 1.8, sizeScale = 1.5, lightScale = 1.35, trail = true, orbit = true, groundRing = true, dark = true },
}

-- The layers a tier adds on top of a species' own. Their colour is the tier's (data/Tiers color); the colour here is only a
-- placeholder for the type.
local extras: { Trail: Types.EffectLayer, Orbit: Types.EffectLayer, GroundRing: Types.EffectLayer } = {
	Trail = { kind = "Trail", color = "FFFFFF", at = "Back", to = "Feet", lifetime = 1.1, width = 0.8 },
	Orbit = { kind = "Orbit", color = "FFFFFF", at = "Body", count = 3, radius = 0.75, period = 4.5, rate = 10, size = 0.11, lifetime = 0.5, glow = 1, sprite = "Glow" },
	GroundRing = { kind = "Emitter", color = "FFFFFF", at = "Feet", rate = 0.7, size = 1.7, lifetime = 1.7, speed = 0.02, spread = 0, glow = 0.8, sprite = "Ring", flat = true },
}

-- The Secret variant: each colour moves Mix of the way to Color, and an emitter's glow is multiplied by GlowScale so smoke
-- reads as smoke instead of vanishing into the additive blend.
local dark = { Color = "0B0618", Mix = 0.55, GlowScale = 0.35 }

-- How the pieces are drawn. DefaultGlow: LightEmission when a layer names none. AnchorStuds: the invisible part a model's
-- attachments sit on. Emitter transparency fades in over FadeIn of the life, holds at PeakTransparency until FadeOut, then
-- fades out. Beam: a strike lasts BeamFlashSeconds and redraws its bend BeamSteps times; the bend is BeamCurve of the bolt's
-- length; BeamTransparency is the bolt's. TrailTransparency is the ribbon's start (it fades to 1 along its life). PulseDepth:
-- a pulsing light dips to this fraction below its brightness. RingFrom: the ground ring starts at this fraction of its size.
-- EndSize: a particle shrinks to this fraction of its size by the end of its life. SpeedSpread: the slowest particle moves at
-- this fraction of a layer's speed. Sound (a species row's optional `sound`, a key of data/Sounds): an alien plays it on its
-- signature beat (a beam's strike, else the start of an idle cycle) at most once per SoundEverySeconds; it is a 3D sound at the
-- alien, full volume within SoundRollOffMin studs and fading out by SoundRollOffMax, and SoundMaxSeconds is the longest a
-- one-shot may live (a sound that never loads is removed then).
local look = {
	DefaultGlow = 0.5,
	AnchorStuds = 0.2,
	FadeIn = 0.12,
	FadeOut = 0.6,
	PeakTransparency = 0.2,
	EndSize = 0.35,
	SpeedSpread = 0.6,
	BeamFlashSeconds = 0.18,
	BeamSteps = 3,
	BeamCurve = 0.35,
	BeamTransparency = 0.05,
	TrailTransparency = 0.25,
	PulseDepth = 0.5,
	RingFrom = 0.25,
	SoundEverySeconds = 8,
	SoundRollOffMin = 6,
	SoundRollOffMax = 70,
	SoundMaxSeconds = 10,
}

-- Idle motion shapes. HoverSway: a Hover rises and falls by this fraction of its height. BreatheLiftPerDegree: studs a
-- Breathe lifts per degree of rock. FlapFallbackStuds: the bob a Flap species falls back to when its model has no named wing.
local motion = {
	HoverSway = 0.35,
	BreatheLiftPerDegree = 0.02,
	FlapFallbackStuds = 0.12,
}

-- Under Reduced Motion every emitter, beam, trail and orbit drops out and the alien keeps one still glow: its own light
-- layer held steady, or, when it has none, a light of this brightness and range (heights) in its first layer's colour.
local reduced = { GlowBrightness = 0.8, GlowRange = 2.5 }

local wings = { "WingL", "WingR" }

local species: { [string]: Types.SpeciesFx } = {
	-- Common: one subtle layer
	Mossbop = {
		element = "Moss",
		layers = {
			{ kind = "Emitter", color = "7BD14A", at = "Top", rate = 1.2, size = 0.11, lifetime = 2.4, speed = 0.1, spread = 40, rise = 0.04, glow = 0.2 },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3.2 },
	},
	Pebblet = {
		element = "Stone",
		layers = {
			{ kind = "Emitter", color = "B8AFA0", at = "Feet", rate = 1.8, size = 0.14, lifetime = 0.9, speed = 0.22, spread = 55, glow = 0, sprite = "Wisp" },
		},
		idle = { kind = "Bob", amplitude = 0.12, period = 0.8 },
	},
	Glimmo = {
		element = "Glow",
		layers = {
			{ kind = "Emitter", color = "FFE066", at = "Back", rate = 2, size = 0.14, lifetime = 1.7, speed = 0.08, spread = 180, glow = 1, sprite = "Glow" },
		},
		idle = { kind = "Hover", amplitude = 0.25, period = 2.4 },
	},
	Twiglet = {
		element = "Leaf",
		layers = {
			{ kind = "Emitter", color = "9CB84A", at = "Top", rate = 1, size = 0.11, lifetime = 2.6, speed = 0.04, spread = 90, rise = -0.1, glow = 0 },
		},
		idle = { kind = "Bob", amplitude = 0.08, period = 1.2 },
	},
	Puffpuff = {
		element = "Seeds",
		layers = {
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 1.6, size = 0.1, lifetime = 3.2, speed = 0.1, spread = 140, rise = 0.03, glow = 0.3, sprite = "Wisp" },
		},
		idle = { kind = "Spin", amplitude = 360, period = 16 },
	},
	Flufflet = {
		element = "Snowfall",
		layers = {
			{ kind = "Emitter", color = "F2F6FA", at = "Top", rate = 1.4, size = 0.11, lifetime = 2.2, speed = 0.05, spread = 120, rise = -0.12, glow = 0.3, sprite = "Flake" },
		},
		idle = { kind = "Breathe", amplitude = 2.5, period = 2.8 },
	},
	Snowbun = {
		element = "Snowdust",
		layers = {
			{ kind = "Emitter", color = "DDEBF7", at = "Tail", rate = 1.6, size = 0.13, lifetime = 1.4, speed = 0.12, spread = 80, rise = -0.05, glow = 0.2, sprite = "Flake" },
		},
		idle = { kind = "Bob", amplitude = 0.14, period = 1 },
	},
	Drippo = {
		element = "Meltwater",
		layers = {
			{ kind = "Emitter", color = "A9D6F5", at = "Mouth", rate = 1.3, size = 0.1, lifetime = 0.9, speed = 0.02, spread = 15, rise = -0.9, glow = 0.3, dir = "Down" },
		},
		idle = { kind = "Bob", amplitude = 0.06, period = 1.6 },
	},
	Chipmole = {
		element = "Ice chips",
		layers = {
			{ kind = "Emitter", color = "C9E6F5", at = "FrontL", rate = 2, size = 0.11, lifetime = 0.7, speed = 0.25, spread = 60, rise = -0.8, glow = 0.2 },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 0.9 },
	},
	Kettlepuff = {
		element = "Steam",
		layers = {
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 2, size = 0.2, lifetime = 1.4, speed = 0.25, spread = 18, rise = 0.15, glow = 0, sprite = "Wisp" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2 },
	},
	-- Uncommon: one layer, a little fuller
	Snailbyte = {
		element = "Metal",
		layers = {
			{ kind = "Emitter", color = "D6E6F2", at = "Back", rate = 2.4, size = 0.11, lifetime = 0.6, speed = 0.02, spread = 360, glow = 1, sprite = "Sparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.05, period = 2.8 },
	},
	Buzzlebee = {
		element = "Pollen",
		layers = {
			{ kind = "Emitter", color = "FFD84D", at = "Back", rate = 5, size = 0.1, lifetime = 1.3, speed = 0.12, spread = 120, rise = -0.05, glow = 0.4 },
		},
		idle = { kind = "Flap", amplitude = 25, period = 0.14, parts = wings },
	},
	Lanternewt = {
		element = "Lantern",
		layers = {
			{ kind = "Light", color = "FFA94D", at = "Tail", brightness = 1.6, range = 2.6, pulse = 3.2 },
		},
		idle = { kind = "Breathe", amplitude = 2, period = 2.6 },
	},
	Pengoo = {
		element = "Snow spray",
		layers = {
			{ kind = "Emitter", color = "EAF6FF", at = "Feet", rate = 3.5, size = 0.19, lifetime = 0.8, speed = 0.25, spread = 70, glow = 0.2, sprite = "Flake" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.1 },
	},
	Flapsicle = {
		element = "Ice",
		layers = {
			{ kind = "Emitter", color = "BFE9FF", at = "BackL", rate = 3, size = 0.11, lifetime = 1.1, speed = 0.05, spread = 80, rise = -0.4, glow = 0.5, sprite = "Flake" },
		},
		idle = { kind = "Flap", amplitude = 20, period = 0.5, parts = wings },
	},
	Toastoad = {
		element = "Hot spring",
		layers = {
			{ kind = "Emitter", color = "FFFFFF", at = "Back", rate = 3, size = 0.16, lifetime = 1.5, speed = 0.2, spread = 25, rise = 0.2, glow = 0, sprite = "Wisp" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2.2 },
	},
	Emberchin = {
		element = "Ember",
		layers = {
			{ kind = "Emitter", color = "FF7A2E", at = "Back", rate = 6, size = 0.11, lifetime = 0.9, speed = 0.3, spread = 70, rise = 0.3, glow = 1, sprite = "Ember" },
		},
		idle = { kind = "Bob", amplitude = 0.15, period = 1 },
	},
	-- Rare: two layers
	Rocklobber = {
		element = "Boulder",
		layers = {
			{ kind = "Emitter", color = "A89F91", at = "FrontL", rate = 3, size = 0.13, lifetime = 0.8, speed = 0.1, spread = 60, rise = -0.5, glow = 0 },
			{ kind = "Emitter", color = "8C8378", at = "Feet", rate = 4, size = 0.22, lifetime = 1, speed = 0.2, spread = 80, glow = 0, sprite = "Wisp" },
		},
		idle = { kind = "Bob", amplitude = 0.15, period = 1.4 },
	},
	Zapfinch = {
		element = "Static",
		layers = {
			{ kind = "Beam", color = "8FD3FF", at = "Top", to = "Back", width = 0.07, flicker = 3.2, segments = 6 },
			{ kind = "Emitter", color = "CFEFFF", at = "Top", rate = 4, size = 0.08, lifetime = 0.35, speed = 0.4, spread = 180, glow = 1, sprite = "Sparkle" },
		},
		idle = { kind = "Flap", amplitude = 15, period = 0.35, parts = wings },
	},
	Sparkfox = {
		element = "Ember",
		layers = {
			{ kind = "Emitter", color = "FF8A3D", at = "Tail", rate = 8, size = 0.14, lifetime = 0.9, speed = 0.35, spread = 35, rise = 0.35, glow = 1, sprite = "Ember" },
			{ kind = "Light", color = "FFB45A", at = "Tail", brightness = 1.1, range = 2.4, pulse = 2 },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.3 },
	},
	Wisplet = {
		element = "Spirit",
		layers = {
			{ kind = "Light", color = "9BE7FF", at = "Body", brightness = 1.4, range = 3, pulse = 1.4 },
			{ kind = "Emitter", color = "9BE7FF", at = "Body", rate = 5, size = 0.18, lifetime = 1.4, speed = 0.1, spread = 180, rise = 0.2, glow = 1, sprite = "Wisp" },
		},
		idle = { kind = "Hover", amplitude = 0.5, period = 2.8 },
	},
	Reindazzle = {
		element = "Frost",
		layers = {
			{ kind = "Emitter", color = "DFF4FF", at = "Top", rate = 4, size = 0.13, lifetime = 0.5, speed = 0.02, spread = 360, glow = 1, sprite = "Sparkle" },
			{ kind = "Light", color = "FF4D4D", at = "Mouth", brightness = 1.2, range = 1.6, pulse = 1.6 },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.5 },
	},
	Shellberg = {
		element = "Iceberg",
		layers = {
			{ kind = "Emitter", color = "CFF6F2", at = "Back", rate = 4, size = 0.26, lifetime = 2, speed = 0.08, spread = 80, rise = -0.1, glow = 0, sprite = "Wisp" },
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 1.5, size = 0.11, lifetime = 0.5, speed = 0.02, spread = 360, glow = 1, sprite = "Sparkle" },
		},
		idle = { kind = "Breathe", amplitude = 2, period = 4.5 },
	},
	Capybubble = {
		element = "Bubble",
		layers = {
			{ kind = "Emitter", color = "BFEFFF", at = "Mouth", rate = 1.5, size = 0.22, lifetime = 2.4, speed = 0.12, spread = 25, rise = 0.12, glow = 0.3, sprite = "Ring" },
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 1.5, size = 0.18, lifetime = 1.6, speed = 0.05, spread = 30, rise = 0.2, glow = 0, sprite = "Wisp" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3.4 },
	},
	-- Epic: three layers
	Thunderhog = {
		element = "Lightning",
		layers = {
			{ kind = "Beam", color = "FFF27A", at = "BackL", to = "BackR", width = 0.1, flicker = 2, segments = 8 },
			{ kind = "Emitter", color = "FFF27A", at = "Back", rate = 6, size = 0.1, lifetime = 0.3, speed = 0.5, spread = 180, glow = 1, sprite = "Sparkle" },
			{ kind = "Light", color = "C084FC", at = "Back", brightness = 1.1, range = 3 },
		},
		idle = { kind = "Bob", amplitude = 0.12, period = 1.1 },
	},
	Gloomoth = {
		element = "Crystal",
		layers = {
			{ kind = "Emitter", color = "E1B8FF", at = "BackL", rate = 4, size = 0.11, lifetime = 0.5, speed = 0.03, spread = 360, glow = 1, sprite = "Sparkle" },
			{ kind = "Emitter", color = "C8A2E8", at = "Back", rate = 5, size = 0.13, lifetime = 1.6, speed = 0.1, spread = 100, rise = -0.15, glow = 0.2, sprite = "Wisp" },
			{ kind = "Light", color = "B07CFF", at = "Back", brightness = 0.9, range = 3, pulse = 2.6 },
		},
		idle = { kind = "Flap", amplitude = 22, period = 0.9, parts = wings },
	},
	Spookum = {
		element = "Ghost",
		layers = {
			{ kind = "Emitter", color = "F2F2FF", at = "Feet", rate = 4, size = 0.22, lifetime = 1.6, speed = 0.05, spread = 60, rise = 0.1, glow = 0.6, sprite = "Wisp" },
			{ kind = "Light", color = "FF9F1C", at = "Mouth", brightness = 1.3, range = 2.6, pulse = 2.4 },
			{ kind = "Emitter", color = "FFB347", at = "Mouth", rate = 4, size = 0.1, lifetime = 0.6, speed = 0.08, spread = 30, rise = 0.3, glow = 1, sprite = "Ember" },
		},
		idle = { kind = "Hover", amplitude = 0.35, period = 3 },
	},
	Shimmerlynx = {
		element = "Aurora",
		layers = {
			{ kind = "Trail", color = "7CFFC4", at = "Top", to = "Tail", lifetime = 1.4, width = 0.9 },
			{ kind = "Emitter", color = "B38CFF", at = "Top", rate = 5, size = 0.16, lifetime = 1.8, speed = 0.1, spread = 40, rise = 0.15, glow = 1, sprite = "Glow" },
			{ kind = "Light", color = "7CFFC4", at = "Top", brightness = 1, range = 3.2, pulse = 3 },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.4 },
	},
	Frostfang = {
		element = "Frost",
		layers = {
			{ kind = "Emitter", color = "E6F6FF", at = "Mouth", rate = 4, size = 0.2, lifetime = 1.2, speed = 0.35, spread = 25, rise = 0.05, glow = 0.2, dir = "Front", sprite = "Wisp" },
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 4, size = 0.13, lifetime = 1.6, speed = 0.15, spread = 180, rise = -0.1, glow = 0.3, sprite = "Flake" },
			{ kind = "Light", color = "8AD0FF", at = "Body", brightness = 0.9, range = 3 },
		},
		idle = { kind = "Breathe", amplitude = 4, period = 1.8 },
	},
	-- Legendary: four or five layers, plus the ground ring
	Gaiabloom = {
		element = "Bloom",
		layers = {
			{ kind = "Emitter", color = "FFB7D5", at = "Top", rate = 6, size = 0.14, lifetime = 2.2, speed = 0.12, spread = 120, rise = -0.06, glow = 0.3 },
			{ kind = "Emitter", color = "FFE066", at = "Feet", rate = 5, size = 0.16, lifetime = 1.2, speed = 0.15, spread = 40, glow = 0.6, sprite = "Glow" },
			{ kind = "Light", color = "FFD966", at = "Top", brightness = 1.5, range = 4, pulse = 3.6 },
			{ kind = "Emitter", color = "7BD14A", at = "Back", rate = 4, size = 0.13, lifetime = 2.4, speed = 0.05, spread = 150, rise = 0.04, glow = 0.2 },
		},
		idle = { kind = "Breathe", amplitude = 2.5, period = 3.6 },
	},
	Nebulyn = {
		element = "Nebula",
		layers = {
			{ kind = "Emitter", color = "9D7BFF", at = "Body", rate = 10, size = 0.22, lifetime = 2, speed = 0.08, spread = 180, glow = 0.8, sprite = "Wisp" },
			{ kind = "Emitter", color = "FFFFFF", at = "Tail", rate = 9, size = 0.11, lifetime = 1.6, speed = 0.2, spread = 25, glow = 1, dir = "Back", sprite = "Star" },
			{ kind = "Light", color = "8F6BFF", at = "Body", brightness = 1.6, range = 4.5, pulse = 3.4 },
			{ kind = "Emitter", color = "C8F0FF", at = "Eyes", rate = 3, size = 0.1, lifetime = 0.5, speed = 0.02, spread = 360, glow = 1, sprite = "Sparkle" },
			{ kind = "Trail", color = "B79CFF", at = "Tail", to = "Body", lifetime = 1.6, width = 0.8 },
		},
		idle = { kind = "Hover", amplitude = 0.45, period = 3.2 },
	},
	Skaddle = {
		element = "Blizzard",
		layers = {
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 8, size = 0.13, lifetime = 1.8, speed = 0.05, spread = 180, rise = -0.2, glow = 0.3, sprite = "Flake" },
			{ kind = "Emitter", color = "CFEFFF", at = "Back", rate = 4, size = 0.11, lifetime = 0.6, speed = 0.03, spread = 360, glow = 1, sprite = "Sparkle" },
			{ kind = "Light", color = "BFE6FF", at = "Top", brightness = 1.4, range = 4, pulse = 3 },
			{ kind = "Emitter", color = "FFFFFF", at = "Feet", rate = 6, size = 0.19, lifetime = 0.7, speed = 0.3, spread = 40, glow = 0.2, dir = "Back", sprite = "Flake" },
		},
		idle = { kind = "Hover", amplitude = 0.3, period = 2.8 },
	},
	-- Cosmic: five layers, plus the ground ring, an orbit and a trail
	Radish = {
		element = "Sun",
		layers = {
			{ kind = "Light", color = "FFD27A", at = "Top", brightness = 2.2, range = 6, pulse = 3 },
			{ kind = "Orbit", color = "FFB347", at = "Top", count = 4, radius = 0.7, period = 4, rate = 14, size = 0.13, lifetime = 0.5, glow = 1, sprite = "Glow" },
			{ kind = "Emitter", color = "FFE9A8", at = "Top", rate = 10, size = 0.19, lifetime = 1, speed = 0.3, spread = 360, glow = 1, sprite = "Star" },
			{ kind = "Emitter", color = "FFC266", at = "Body", rate = 4, size = 0.3, lifetime = 1.6, speed = 0.05, spread = 60, rise = 0.2, glow = 0.5, sprite = "Wisp" },
			{ kind = "Emitter", color = "FFD27A", at = "Feet", rate = 6, size = 0.13, lifetime = 1.4, speed = 0.1, spread = 30, rise = 0.25, glow = 1, sprite = "Glow" },
		},
		idle = { kind = "Hover", amplitude = 0.5, period = 3 },
	},
	Fenripup = {
		element = "Moon",
		layers = {
			{ kind = "Light", color = "C9D6FF", at = "Top", brightness = 1.8, range = 5, pulse = 3.2 },
			{ kind = "Emitter", color = "3A2C7A", at = "Feet", rate = 7, size = 0.3, lifetime = 1.8, speed = 0.15, spread = 90, rise = 0.1, glow = 0, sprite = "Wisp" },
			{ kind = "Emitter", color = "E6ECFF", at = "Top", rate = 5, size = 0.11, lifetime = 1.4, speed = 0.05, spread = 60, rise = 0.2, glow = 1, sprite = "Star" },
			{ kind = "Orbit", color = "DDE6FF", at = "Top", count = 2, radius = 0.6, period = 5, rate = 10, size = 0.11, lifetime = 0.6, glow = 1, sprite = "Glow" },
			{ kind = "Trail", color = "6C5CE7", at = "Tail", to = "Body", lifetime = 1.6, width = 0.8 },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2.4 },
	},
	-- Secret: six layers, everything the Cosmic gets, in the dark variant
	Panpipe = {
		element = "Shadow",
		layers = {
			{ kind = "Emitter", color = "B28CFF", at = "Top", rate = 6, size = 0.16, lifetime = 2, speed = 0.1, spread = 50, rise = 0.2, glow = 0.8, sprite = "Star" },
			{ kind = "Light", color = "7A3CFF", at = "Body", brightness = 1.6, range = 4.5, pulse = 2.8 },
			{ kind = "Emitter", color = "1A1A1A", at = "Feet", rate = 8, size = 0.3, lifetime = 2, speed = 0.15, spread = 80, rise = 0.1, glow = 0, sprite = "Wisp" },
			{ kind = "Beam", color = "A07BFF", at = "BackL", to = "BackR", width = 0.1, flicker = 3, segments = 8 },
			{ kind = "Orbit", color = "8E6BFF", at = "Top", count = 3, radius = 0.8, period = 5, rate = 10, size = 0.13, lifetime = 0.6, glow = 1, sprite = "Glow" },
			{ kind = "Trail", color = "5B3FA8", at = "Tail", to = "Body", lifetime = 1.8, width = 0.8 },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3 },
	},
}

return {
	Species = species,
	Tiers = tiers,
	Caps = caps,
	Attach = attach,
	Extras = extras,
	Dark = dark,
	Look = look,
	Motion = motion,
	Reduced = reduced,
}
