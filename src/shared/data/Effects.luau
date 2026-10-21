--!strict
-- Per-species effects and idle motion, drawn by the client's World.SpeciesFx (the server never reads this table).
-- B46 (2026-10-20): effects carry rarity, and they climb steeply. Every alien stands 2 to 3.5 studs (B45), so a rarer one
-- reads as more exclusive by its effects, never by its size, and never fiercer.
-- Species: one row per species id (all 35): an element label, the effect layers strongest first, and an idle motion.
-- Tiers: what each rarity may draw of them: how many layers, which kinds (the body up to Epic, the ground from Legendary, the
-- sky from Cosmic), the scales, and the extras it adds (trail, orbit, ground ring, aura, sky pillar, flourish, spawn moment).
-- Caps: the per-client budgets. Attach: the body regions layers hang on, as fractions of the alien's bounds.
-- Every length in a layer is a fraction of the alien's own height ("heights"), so the data names no stud; the idle
-- amplitudes are the only studs and degrees. Colours are hex. Sprites are keys of Icons.Particles: a key whose id is still 0
-- wears its SpriteFallback key's sprite when that one is uploaded, else the soft default sprite. Lint (tools/lint_data.py)
-- checks every id, region, kind, sprite, rate cap and the tier ladder; tests/Effects.spec.luau checks the gating in
-- EffectsMath. To add a species: one row in Species below (and its row in data/Species). Keep the rows strongest layer first.
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
-- touch screen. AlienParticles is the live particles one alien may keep (rate times lifetime over its emitters, plus its largest
-- burst); an alien over it has every rate and burst scaled down to fit. BurstMax is the most one firing may throw on the device
-- (on top of the tier's burstMax). MaxBeams, MaxLights and MaxPillars are per alien. MaxActive (MaxActiveMobile on a phone) is
-- how many aliens in a client keep their species effects (the nearest first, re-ranked every Config.VfxFxRecheckSeconds); the
-- rest keep only the tier aura. ActiveDistance (studs) is how far from the camera an alien may be to keep them; past
-- NearDistance its rates and bursts drop to FarRateScale and its sparkles stop (too small to see). MomentDistance is how far
-- a spawn moment is seen from, and MaxMoments how many play at once. MaxSoundsPerSecond is how many species sounds start
-- across all aliens in one second (a crowd of lightning boars is not a drum roll).
local caps = {
	MobileRateCap = 100,
	DesktopRateCap = 400,
	MobileAlienParticles = 120,
	DesktopAlienParticles = 360,
	MobileBurstMax = 24,
	DesktopBurstMax = 48,
	MaxBeams = 4,
	MaxLights = 1,
	MaxPillars = 1,
	MaxActive = 12,
	MaxActiveMobile = 8,
	ActiveDistance = 90,
	NearDistance = 45,
	FarRateScale = 0.5,
	MomentDistance = 350,
	MaxMoments = 2,
	MaxSoundsPerSecond = 2,
}

-- What a rarity may draw (B46, the steep ladder):
--   Common: one subtle touch on the body (a puff, a leaf, a blink).
--   Uncommon: that touch and a small second-colour one.
--   Rare: three layers, a soft light and a sparkle among them.
--   Epic: five layers kept on the body, one of them a signature Burst.
--   Legendary: six layers; the ground (orbiting motes, a ring pulsing out) and a periodic signature flourish.
--   Cosmic: eight layers; the sky too: a trail, an aura shell, a pillar of light on the flourish and a spawn moment.
--   Secret: the Cosmic set in its shadow palette.
-- layersAllowed: how many of a species' layers it draws, strongest first; a layer whose kind is not in `kinds` is skipped.
-- burstMax: the most particles one Burst, Sparkle or RingPulse firing throws. The flags add the Extras below when the species
-- has no layer of that kind (groundRing: no RingPulse on a timer), in the species' accent colour; flourish runs the alien's own
-- flourish timer; spawnMoment plays SpawnMoment once when a wild one arrives; dark sinks every colour toward Dark.Color. Each
-- step up the ladder is at least as grand as the one below (lint checks it).
local tiers: { [string]: Types.TierFxRule } = {
	Common = {
		layersAllowed = 1,
		kinds = { Emitter = true, Burst = true, Sparkle = true },
		rateScale = 0.5,
		sizeScale = 0.8,
		lightScale = 0.4,
		burstMax = 6,
		trail = false,
		orbit = false,
		groundRing = false,
		aura = false,
		pillar = false,
		flourish = false,
		spawnMoment = false,
		dark = false,
	},
	Uncommon = {
		layersAllowed = 2,
		kinds = { Emitter = true, Burst = true, Sparkle = true },
		rateScale = 0.6,
		sizeScale = 0.85,
		lightScale = 0.5,
		burstMax = 8,
		trail = false,
		orbit = false,
		groundRing = false,
		aura = false,
		pillar = false,
		flourish = false,
		spawnMoment = false,
		dark = false,
	},
	Rare = {
		layersAllowed = 3,
		kinds = { Emitter = true, Burst = true, Sparkle = true, Light = true, Beam = true, Trail = true },
		rateScale = 0.8,
		sizeScale = 0.9,
		lightScale = 0.7,
		burstMax = 12,
		trail = false,
		orbit = false,
		groundRing = false,
		aura = false,
		pillar = false,
		flourish = false,
		spawnMoment = false,
		dark = false,
	},
	Epic = {
		layersAllowed = 5,
		kinds = { Emitter = true, Burst = true, Sparkle = true, Light = true, Beam = true, Trail = true },
		rateScale = 1,
		sizeScale = 1,
		lightScale = 0.85,
		burstMax = 20,
		trail = false,
		orbit = false,
		groundRing = false,
		aura = false,
		pillar = false,
		flourish = false,
		spawnMoment = false,
		dark = false,
	},
	Legendary = {
		layersAllowed = 6,
		kinds = { Emitter = true, Burst = true, Sparkle = true, Light = true, Beam = true, Trail = true, Orbit = true, RingPulse = true },
		rateScale = 1.15,
		sizeScale = 1.1,
		lightScale = 1,
		burstMax = 28,
		trail = false,
		orbit = true,
		groundRing = true,
		aura = false,
		pillar = false,
		flourish = true,
		spawnMoment = false,
		dark = false,
	},
	Cosmic = {
		layersAllowed = 8,
		kinds = {
			Emitter = true,
			Burst = true,
			Sparkle = true,
			Light = true,
			Beam = true,
			Trail = true,
			Orbit = true,
			RingPulse = true,
			Pillar = true,
			Aura = true,
		},
		rateScale = 1.25,
		sizeScale = 1.2,
		lightScale = 1.2,
		burstMax = 36,
		trail = true,
		orbit = true,
		groundRing = true,
		aura = true,
		pillar = true,
		flourish = true,
		spawnMoment = true,
		dark = false,
	},
	Secret = {
		layersAllowed = 8,
		kinds = {
			Emitter = true,
			Burst = true,
			Sparkle = true,
			Light = true,
			Beam = true,
			Trail = true,
			Orbit = true,
			RingPulse = true,
			Pillar = true,
			Aura = true,
		},
		rateScale = 1.25,
		sizeScale = 1.2,
		lightScale = 1.25,
		burstMax = 36,
		trail = true,
		orbit = true,
		groundRing = true,
		aura = true,
		pillar = true,
		flourish = true,
		spawnMoment = true,
		dark = true,
	},
}

-- The layers a tier adds on top of a species' own. They wear the species' accent (its row's `accent`, else its first layer's
-- colour); the colour here is only a placeholder for the type.
local extras: { Trail: Types.EffectLayer, Orbit: Types.EffectLayer, GroundRing: Types.EffectLayer, Aura: Types.EffectLayer, Pillar: Types.EffectLayer } = {
	Trail = { kind = "Trail", color = "FFFFFF", at = "Back", to = "Feet", lifetime = 1.1, width = 0.8 },
	Orbit = { kind = "Orbit", color = "FFFFFF", at = "Body", count = 3, radius = 0.6, period = 4.5, rate = 8, size = 0.07, lifetime = 0.5, glow = 1, sprite = "PixelMote" },
	GroundRing = { kind = "RingPulse", color = "FFFFFF", at = "Feet", every = 2.6, count = 1, size = 1.8, lifetime = 1.8, glow = 0.8, sprite = "PixelRing" },
	Aura = { kind = "Aura", color = "FFFFFF", at = "Body", rate = 1.5, size = 1.25, lifetime = 1.6, glow = 0.6, sprite = "PixelHalo" },
	Pillar = { kind = "Pillar", color = "FFFFFF", at = "Top", reach = 30, width = 0.35, lifetime = 2.2, flourish = true },
}

-- The spawn moment (tiers with spawnMoment, a wild arrival only): once, in the species' accent, seen from Caps.MomentDistance
-- even when the alien is not among the nearest. A pillar into the sky, two rings rolling out across the ground, a star burst.
local spawnMoment: { Types.EffectLayer } = {
	{ kind = "Pillar", color = "FFFFFF", at = "Feet", reach = 60, width = 0.6, lifetime = 3 },
	{ kind = "RingPulse", color = "FFFFFF", at = "Feet", count = 2, size = 8, lifetime = 2, glow = 1, sprite = "PixelRing" },
	{ kind = "Burst", color = "FFFFFF", at = "Body", count = 30, size = 0.1, lifetime = 1.6, speed = 1.4, spread = 180, rise = -0.3, glow = 1, sprite = "PixelStar" },
}

-- The Secret variant: each colour moves Mix of the way to Color (a pillar or ring only MomentMix, so the sky column of a Secret
-- still reads against the night), and an emitter's glow is multiplied by GlowScale so smoke reads as smoke instead of vanishing
-- into the additive blend.
local dark = { Color = "0B0618", Mix = 0.55, MomentMix = 0.25, GlowScale = 0.35 }

-- The block-cell sprites (B44: every surface is little blocks; tools/pixel_sprites.py draws them, assets/sprites/blocky). Until
-- a pixel sprite is uploaded (its Icons.Particles id is 0) the emitter wears the key named here, when that one is uploaded.
local spriteFallback: { [string]: string } = {
	PixelBubble = "Ring",
	PixelDrop = "Raindrop",
	PixelEmber = "Ember",
	PixelEmberFlicker = "Ember",
	PixelFlake = "Flake",
	PixelGrit = "Wisp",
	PixelHalo = "Glow",
	PixelLeaf = "Confetti",
	PixelMote = "Glow",
	PixelNote = "Star",
	PixelPetal = "Confetti",
	PixelPuff = "Wisp",
	PixelRing = "Ring",
	PixelRune = "Ring",
	PixelSeed = "Wisp",
	PixelSpark = "Sparkle",
	PixelSparkle = "Sparkle",
	PixelStar = "Star",
	PixelTwinkle = "Sparkle",
}

-- Flipbook sheets among the pixel sprites: a 2 x 2 grid of frames (applied only once the sheet's own id is real).
local sheets: { [string]: Types.SpriteSheet } = {
	PixelTwinkle = { layout = "Grid2x2", mode = "OneShot", fps = 8 },
	PixelEmberFlicker = { layout = "Grid2x2", mode = "Loop", fps = 10 },
}

-- How the pieces are drawn. DefaultGlow: LightEmission when a layer names none. AnchorStuds: the invisible part a model's
-- attachments sit on. Emitter transparency fades in over FadeIn of the life, holds at PeakTransparency until FadeOut, then
-- fades out. Beam: a strike lasts BeamFlashSeconds and redraws its bend BeamSteps times; the bend is BeamCurve of the bolt's
-- length; BeamTransparency is the bolt's. TrailTransparency is the ribbon's start (it fades to 1 along its life). PulseDepth:
-- a pulsing light dips to this fraction below its brightness. RingFrom: a ground ring starts at this fraction of its size;
-- RingDrift (heights a second) gives it the small upward velocity a flat sprite needs to lie flat; RingStagger: seconds
-- between the rings of one RingPulse firing. EndSize: a particle shrinks to this fraction of its size by the end of its life.
-- SpeedSpread: the slowest particle moves at this fraction of a layer's speed.
-- Sparkle: grows to full size at SparklePeak of its life and back to nothing, turning SparkleSpin degrees a second unless the
-- layer names a spin; at the Eyes only a Sparkle may hang, no larger than EyeSparkleMax heights (a catchlight, never a cloud
-- over the face; lint checks it). Aura: held at AuraTransparency, swelling from AuraFrom of its size. Pillar: fades in over PillarIn of its
-- life and out over the last PillarOut, PillarTransparency at full; a core beam CoreWidth as wide, CoreMix of the way to white.
-- Flourish: every FlourishEvery seconds unless the row names flourishEvery, the first one between FlourishFirst and 1 of a
-- period after the alien comes up; a flourish from outside (SpeciesFx.Flourish) stands the alien's own timer down for
-- ExternalHold periods. FlareBoost: a light's brightness multiplier at the peak of a flourish, over FlareSeconds.
-- MomentWindow: seconds after an arrival its spawn moment may still start (a model still loading); MomentSlack: seconds past
-- the longest piece before a moment's parts are removed.
-- Sound (a species row's optional `sound`, a key of data/Sounds): an alien plays it on its signature beat (a beam's strike,
-- else the start of an idle cycle) at most once per SoundEverySeconds; a 3D sound at the alien, full volume within
-- SoundRollOffMin studs and fading out by SoundRollOffMax; SoundMaxSeconds is the longest a one-shot may live.
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
	RingDrift = 0.01,
	RingStagger = 0.25,
	SparklePeak = 0.35,
	SparkleSpin = 90,
	EyeSparkleMax = 0.06,
	AuraTransparency = 0.78,
	AuraFrom = 0.85,
	PillarIn = 0.12,
	PillarOut = 0.5,
	PillarTransparency = 0.15,
	CoreWidth = 0.35,
	CoreMix = 0.65,
	FlourishEvery = 14,
	FlourishFirst = 0.3,
	ExternalHold = 2,
	FlareBoost = 2.5,
	FlareSeconds = 0.6,
	MomentWindow = 6,
	MomentSlack = 0.5,
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

-- Under Reduced Motion every emitter, burst, sparkle, ring, beam, trail, orbit, aura, pillar, flourish and spawn moment drops
-- out and the alien keeps one still glow: its own light layer held steady, or, when it has none, a light of this brightness
-- and range (heights) in its first layer's colour.
local reduced = { GlowBrightness = 0.8, GlowRange = 2.5 }

local wings = { "WingL", "WingR" }

local species: { [string]: Types.SpeciesFx } = {
	-- Common: one subtle touch on the body, on a timer -----------------------------------------------------------------
	Mossbop = {
		element = "Moss",
		layers = {
			-- two spores lift off the sprout as it unfurls
			{ kind = "Burst", color = "9BE15D", at = "Top", every = 6, count = 2, size = 0.05, lifetime = 1.8, speed = 0.08, spread = 50, rise = 0.03, glow = 0.1, sprite = "PixelMote" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3.2 },
	},
	Pebblet = {
		element = "Stone",
		layers = {
			-- a puff of grit at its feet as it hops
			{ kind = "Burst", color = "B8AFA0", at = "Feet", every = 4, count = 4, size = 0.06, lifetime = 0.7, speed = 0.25, spread = 70, rise = -0.4, glow = 0, sprite = "PixelGrit" },
		},
		idle = { kind = "Bob", amplitude = 0.12, period = 0.8 },
	},
	Glimmo = {
		element = "Glow",
		layers = {
			-- the firefly bulb blinks brighter every 3 s
			{ kind = "Sparkle", color = "FFE066", at = "Back", every = 3, count = 1, size = 0.14, lifetime = 0.5, glow = 1, sprite = "PixelMote" },
		},
		idle = { kind = "Hover", amplitude = 0.25, period = 2.4 },
	},
	Twiglet = {
		element = "Leaf",
		layers = {
			-- one leaf lets go of the hat and drifts down
			{ kind = "Burst", color = "9CB84A", at = "Top", every = 8, count = 1, size = 0.06, lifetime = 3, speed = 0.05, spread = 90, rise = -0.08, glow = 0, spin = 60, sprite = "PixelLeaf" },
		},
		idle = { kind = "Bob", amplitude = 0.08, period = 1.2 },
	},
	Puffpuff = {
		element = "Seeds",
		layers = {
			-- one seed lifts off the puff and floats away
			{ kind = "Burst", color = "FFFFFF", at = "Top", every = 5, count = 1, size = 0.06, lifetime = 3.5, speed = 0.12, spread = 140, rise = 0.04, glow = 0.2, sprite = "PixelSeed" },
		},
		idle = { kind = "Spin", amplitude = 360, period = 16 },
	},
	Flufflet = {
		element = "Snowfall",
		layers = {
			-- a snowflake drifts down onto its head and melts
			{ kind = "Burst", color = "F2F6FA", at = "Halo", every = 6, count = 1, size = 0.07, lifetime = 1.6, speed = 0.08, spread = 10, rise = -0.04, glow = 0.2, dir = "Down", spin = 45, sprite = "PixelFlake" },
		},
		idle = { kind = "Breathe", amplitude = 2.5, period = 2.8 },
	},
	Snowbun = {
		element = "Snowdust",
		layers = {
			-- the grown snowball tail pops back with a puff of snow dust
			{ kind = "Burst", color = "DDEBF7", at = "Tail", every = 9, count = 6, size = 0.06, lifetime = 0.8, speed = 0.3, spread = 80, rise = -0.3, glow = 0.2, sprite = "PixelFlake" },
		},
		idle = { kind = "Bob", amplitude = 0.14, period = 1 },
	},
	Drippo = {
		element = "Meltwater",
		layers = {
			-- one drop falls from the drip under its chin
			{ kind = "Burst", color = "A9D6F5", at = "Mouth", every = 3, count = 1, size = 0.06, lifetime = 0.9, speed = 0.02, spread = 10, rise = -0.9, glow = 0.3, dir = "Down", sprite = "PixelDrop" },
		},
		idle = { kind = "Bob", amplitude = 0.06, period = 1.6 },
	},
	Chipmole = {
		element = "Ice chips",
		layers = {
			-- three ice chips kick up from the picks
			{ kind = "Burst", color = "C9E6F5", at = "FrontL", every = 5, count = 3, size = 0.06, lifetime = 0.7, speed = 0.3, spread = 60, rise = -0.8, glow = 0.2, spin = 180, sprite = "PixelGrit" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 0.9 },
	},
	Kettlepuff = {
		element = "Steam",
		layers = {
			-- a steam puff from the spout
			{ kind = "Burst", color = "FFFFFF", at = "Top", every = 4, count = 3, size = 0.12, lifetime = 1.4, speed = 0.25, spread = 18, rise = 0.12, glow = 0, sprite = "PixelPuff" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2 },
	},
	-- Uncommon: the touch, and a small one in a second colour ---------------------------------------------------------------
	Snailbyte = {
		element = "Metal",
		layers = {
			{ kind = "Sparkle", color = "D6E6F2", at = "Back", every = 4, count = 1, size = 0.14, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
			{ kind = "Emitter", color = "E8A15A", at = "Back", rate = 0.8, size = 0.04, lifetime = 0.8, speed = 0.06, spread = 120, rise = 0.05, glow = 0.6, sprite = "PixelMote" },
		},
		idle = { kind = "Bob", amplitude = 0.05, period = 2.8 },
	},
	Buzzlebee = {
		element = "Pollen",
		layers = {
			{ kind = "Emitter", color = "FFD84D", at = "Back", rate = 3, size = 0.05, lifetime = 1.3, speed = 0.12, spread = 120, rise = -0.05, glow = 0.3, sprite = "PixelMote" },
			{ kind = "Sparkle", color = "FFFFFF", at = "BackL", every = 2.5, count = 1, size = 0.08, lifetime = 0.35, glow = 0.8, sprite = "PixelSparkle" },
		},
		idle = { kind = "Flap", amplitude = 25, period = 0.14, parts = wings },
	},
	Lanternewt = {
		element = "Lantern",
		layers = {
			-- the tail lamp's glow breathes (a held glow sprite; the light itself starts at Rare)
			{ kind = "Emitter", color = "FFA94D", at = "Tail", rate = 1, size = 0.22, lifetime = 1.6, speed = 0, spread = 0, glow = 0.8, sprite = "PixelHalo" },
			{ kind = "Burst", color = "FFE2A8", at = "Tail", every = 2, count = 1, size = 0.05, lifetime = 1.8, speed = 0.08, spread = 40, rise = 0.12, glow = 1, sprite = "PixelMote" },
		},
		idle = { kind = "Breathe", amplitude = 2, period = 2.6 },
	},
	Pengoo = {
		element = "Snow spray",
		layers = {
			{ kind = "Emitter", color = "EAF6FF", at = "Feet", rate = 3, size = 0.08, lifetime = 0.8, speed = 0.25, spread = 70, glow = 0.2, dir = "Back", sprite = "PixelFlake" },
			-- the goggles glint
			{ kind = "Sparkle", color = "9FE3FF", at = "Eyes", every = 5, count = 1, size = 0.05, lifetime = 0.35, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.1 },
	},
	Flapsicle = {
		element = "Ice",
		layers = {
			{ kind = "Emitter", color = "BFE9FF", at = "BackL", rate = 2, size = 0.06, lifetime = 1.1, speed = 0.05, spread = 80, rise = -0.4, glow = 0.4, sprite = "PixelFlake" },
			{ kind = "Sparkle", color = "C9B8FF", at = "BackR", every = 3.5, count = 1, size = 0.09, lifetime = 0.4, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Flap", amplitude = 20, period = 0.5, parts = wings },
	},
	Toastoad = {
		element = "Hot spring",
		layers = {
			{ kind = "Emitter", color = "FFFFFF", at = "Back", rate = 2, size = 0.12, lifetime = 1.5, speed = 0.2, spread = 25, rise = 0.2, glow = 0, sprite = "PixelPuff" },
			-- a bubble pops on its nose when it blinks
			{ kind = "Burst", color = "A8E6FF", at = "Mouth", every = 5, count = 1, size = 0.08, lifetime = 0.8, speed = 0.15, spread = 15, rise = 0.05, glow = 0.3, dir = "Front", sprite = "PixelBubble" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2.2 },
	},
	Emberchin = {
		element = "Ember",
		layers = {
			{ kind = "Burst", color = "FF7A2E", at = "Back", every = 2, count = 1, size = 0.06, lifetime = 0.9, speed = 0.35, spread = 70, rise = 0.3, glow = 1, sprite = "PixelEmberFlicker" },
			{ kind = "Sparkle", color = "FFD25A", at = "Top", every = 3, count = 1, size = 0.08, lifetime = 0.35, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.15, period = 1 },
	},
	-- Rare: three layers, a soft light and a sparkle among them -------------------------------------------------------------
	Rocklobber = {
		element = "Boulder",
		layers = {
			-- the claws clack: a dust puff and pebble chips
			{ kind = "Burst", color = "A89F91", at = "FrontL", every = 5, count = 6, size = 0.07, lifetime = 0.8, speed = 0.3, spread = 70, rise = -0.6, glow = 0, sprite = "PixelGrit" },
			{ kind = "Light", color = "F5B342", at = "FrontL", brightness = 0.8, range = 1.8, pulse = 3 },
			{ kind = "Sparkle", color = "FFC766", at = "FrontR", every = 3, count = 1, size = 0.09, lifetime = 0.45, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.15, period = 1.4 },
	},
	Zapfinch = {
		element = "Static",
		layers = {
			{ kind = "Beam", color = "8FD3FF", at = "Top", to = "Back", width = 0.05, flicker = 3, segments = 6 },
			{ kind = "Light", color = "8FD3FF", at = "Top", brightness = 0.8, range = 2, pulse = 1.5 },
			{ kind = "Sparkle", color = "CFEFFF", at = "Top", every = 1.2, count = 2, size = 0.08, lifetime = 0.35, glow = 1, sprite = "PixelSpark" },
		},
		idle = { kind = "Flap", amplitude = 15, period = 0.35, parts = wings },
	},
	Sparkfox = {
		element = "Ember",
		layers = {
			{ kind = "Emitter", color = "FF8A3D", at = "Tail", rate = 6, size = 0.06, lifetime = 0.8, speed = 0.3, spread = 35, rise = 0.35, glow = 1, sprite = "PixelEmberFlicker" },
			{ kind = "Light", color = "FFB45A", at = "Tail", brightness = 1, range = 2.2, pulse = 2 },
			-- the paint drop falls from the brush and reforms
			{ kind = "Sparkle", color = "FFD27A", at = "Tail", every = 4, count = 1, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.3 },
	},
	Wisplet = {
		element = "Spirit",
		layers = {
			{ kind = "Light", color = "9BE7FF", at = "Body", brightness = 1.2, range = 2.6, pulse = 1.4 },
			{ kind = "Emitter", color = "9BE7FF", at = "Body", rate = 0.7, size = 0.09, lifetime = 1.8, speed = 0.08, spread = 60, rise = 0.15, glow = 1, sprite = "PixelMote" },
			{ kind = "Sparkle", color = "C9A8FF", at = "Top", every = 2.5, count = 1, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Hover", amplitude = 0.5, period = 2.8 },
	},
	Reindazzle = {
		element = "Frost",
		layers = {
			-- the red nose blinks
			{ kind = "Light", color = "FF4D4D", at = "Mouth", brightness = 1.1, range = 1.4, pulse = 2 },
			{ kind = "Sparkle", color = "DFF4FF", at = "Top", every = 4, count = 2, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
			{ kind = "Emitter", color = "DFF4FF", at = "Top", rate = 2.5, size = 0.05, lifetime = 0.6, speed = 0.04, spread = 360, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.5 },
	},
	Shellberg = {
		element = "Iceberg",
		layers = {
			-- cold mist rolls off the berg and pools at its feet
			{ kind = "Emitter", color = "CFF6F2", at = "Back", rate = 3, size = 0.12, lifetime = 2, speed = 0.06, spread = 80, rise = -0.1, glow = 0, sprite = "PixelPuff" },
			{ kind = "Light", color = "9FD8FF", at = "Top", brightness = 0.8, range = 2.2, pulse = 4.5 },
			{ kind = "Sparkle", color = "FFFFFF", at = "Top", every = 4, count = 1, size = 0.11, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Breathe", amplitude = 2, period = 4.5 },
	},
	Capybubble = {
		element = "Bubble",
		layers = {
			-- three snore bubbles drift out from its nose
			{ kind = "Burst", color = "BFEFFF", at = "Mouth", every = 4, count = 3, size = 0.09, lifetime = 2.4, speed = 0.15, spread = 25, rise = 0.08, glow = 0.3, dir = "Front", sprite = "PixelBubble" },
			{ kind = "Light", color = "7FE0D0", at = "Body", brightness = 0.7, range = 2.2, pulse = 3.4 },
			{ kind = "Sparkle", color = "FFFFFF", at = "Halo", every = 4, count = 1, size = 0.08, lifetime = 0.35, glow = 0.8, sprite = "PixelSparkle" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3.4 },
	},
	-- Epic: five layers kept on the body, a signature Burst among them -----------------------------------------------------
	Thunderhog = {
		element = "Lightning",
		layers = {
			{ kind = "Beam", color = "FFF27A", at = "BackL", to = "BackR", width = 0.07, flicker = 2, segments = 8 },
			{ kind = "Emitter", color = "FFF27A", at = "Back", rate = 5, size = 0.05, lifetime = 0.3, speed = 0.5, spread = 180, glow = 1, sprite = "PixelSpark" },
			{ kind = "Light", color = "C084FC", at = "Back", brightness = 1.1, range = 2.6 },
			-- the quills discharge: a crackle of sparks every 6 s
			{ kind = "Burst", color = "FFF8B0", at = "Back", every = 6, count = 12, size = 0.06, lifetime = 0.4, speed = 0.9, spread = 180, glow = 1, flourish = true, sprite = "PixelSpark" },
			{ kind = "Sparkle", color = "FFF8B0", at = "Eyes", every = 4.5, count = 1, size = 0.05, lifetime = 0.3, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.12, period = 1.1 },
	},
	Gloomoth = {
		element = "Crystal",
		layers = {
			-- a glint sweeps the crystal wings
			{ kind = "Sparkle", color = "E1B8FF", at = "BackL", every = 3, count = 2, size = 0.12, lifetime = 0.6, glow = 1, sprite = "PixelTwinkle" },
			{ kind = "Emitter", color = "C8A2E8", at = "Back", rate = 4, size = 0.06, lifetime = 1.6, speed = 0.08, spread = 100, rise = -0.15, glow = 0.4, sprite = "PixelMote" },
			{ kind = "Light", color = "B07CFF", at = "Back", brightness = 0.9, range = 2.6, pulse = 2.6 },
			-- a prism dust shaken from the wings
			{ kind = "Burst", color = "FFC8F0", at = "Back", every = 7, count = 14, size = 0.07, lifetime = 1, speed = 0.5, spread = 120, rise = -0.2, glow = 1, flourish = true, sprite = "PixelSparkle" },
			{ kind = "Sparkle", color = "9FE8FF", at = "BackR", every = 3, count = 2, size = 0.12, lifetime = 0.6, glow = 1, sprite = "PixelTwinkle" },
		},
		idle = { kind = "Flap", amplitude = 22, period = 0.9, parts = wings },
	},
	Spookum = {
		element = "Ghost",
		layers = {
			-- the pumpkin grin lit from inside
			{ kind = "Light", color = "FF9F1C", at = "Mouth", brightness = 1.2, range = 2.4, pulse = 2.4 },
			{ kind = "Emitter", color = "E9E2FF", at = "Feet", rate = 3, size = 0.16, lifetime = 1.8, speed = 0.04, spread = 60, rise = 0.05, glow = 0.5, sprite = "PixelPuff" },
			{ kind = "Emitter", color = "FFB347", at = "Top", rate = 2.5, size = 0.05, lifetime = 0.9, speed = 0.1, spread = 40, rise = 0.3, glow = 1, sprite = "PixelEmberFlicker" },
			-- "boo": a ring of violet wisps as it fades and returns
			{ kind = "Burst", color = "C77DFF", at = "Body", every = 5, count = 12, size = 0.1, lifetime = 1.2, speed = 0.4, spread = 180, glow = 0.6, flourish = true, sprite = "PixelPuff" },
			{ kind = "Sparkle", color = "C77DFF", at = "Tail", every = 3, count = 2, size = 0.08, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Hover", amplitude = 0.35, period = 3 },
	},
	Shimmerlynx = {
		element = "Aurora",
		layers = {
			{ kind = "Trail", color = "7CFFC4", at = "Top", to = "Tail", lifetime = 1.4, width = 0.9 },
			{ kind = "Emitter", color = "B38CFF", at = "Top", rate = 4, size = 0.07, lifetime = 1.8, speed = 0.1, spread = 40, rise = 0.15, glow = 1, sprite = "PixelMote" },
			{ kind = "Light", color = "7CFFC4", at = "Top", brightness = 1, range = 2.8, pulse = 3 },
			-- it purrs in colours: an aurora shimmer off the crest
			{ kind = "Burst", color = "FF9BE0", at = "Top", every = 6, count = 12, size = 0.08, lifetime = 1.4, speed = 0.4, spread = 70, rise = 0.2, glow = 1, flourish = true, sprite = "PixelTwinkle" },
			{ kind = "Sparkle", color = "DFFFF3", at = "Eyes", every = 5, count = 1, size = 0.05, lifetime = 0.35, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.4 },
	},
	Frostfang = {
		element = "Frost",
		layers = {
			-- the sneeze: twenty snowflakes thrown forward every 12 s
			{ kind = "Burst", color = "FFFFFF", at = "Mouth", every = 12, count = 20, size = 0.07, lifetime = 1.2, speed = 0.8, spread = 40, rise = -0.3, glow = 0.4, dir = "Front", spin = 120, flourish = true, sprite = "PixelFlake" },
			{ kind = "Emitter", color = "E6F6FF", at = "Mouth", rate = 2, size = 0.12, lifetime = 1.1, speed = 0.3, spread = 25, rise = 0.05, glow = 0.2, dir = "Front", sprite = "PixelPuff" },
			{ kind = "Light", color = "8AD0FF", at = "Body", brightness = 0.9, range = 2.6 },
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 2, size = 0.06, lifetime = 1.6, speed = 0.12, spread = 180, rise = -0.1, glow = 0.3, sprite = "PixelFlake" },
			-- an icicle fang glints
			{ kind = "Sparkle", color = "BFEFFF", at = "Mouth", every = 3, count = 1, size = 0.06, lifetime = 0.35, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Breathe", amplitude = 4, period = 1.8 },
	},
	-- Legendary: six layers, the ground ring, orbiting motes and a flourish ------------------------------------------------
	Gaiabloom = {
		element = "Bloom",
		accent = "F59E0B",
		flourishEvery = 10,
		layers = {
			{ kind = "Orbit", color = "FFB7D5", at = "Top", count = 4, radius = 0.45, period = 5, rate = 6, size = 0.06, lifetime = 0.6, glow = 0.5, spin = 90, sprite = "PixelPetal" },
			-- a flower pops in each footprint
			{ kind = "Burst", color = "FFE066", at = "Feet", every = 2.4, count = 4, size = 0.07, lifetime = 1, speed = 0.2, spread = 60, rise = 0.1, glow = 0.6, sprite = "PixelPetal" },
			{ kind = "Light", color = "FFD966", at = "Top", brightness = 1.4, range = 3.2, pulse = 3.6 },
			-- the flourish: the antlers shake and shed a ring of petals
			{ kind = "Burst", color = "FFB7D5", at = "Top", flourish = true, count = 18, size = 0.07, lifetime = 2, speed = 0.5, spread = 120, rise = -0.12, glow = 0.3, spin = 120, sprite = "PixelPetal" },
			{ kind = "RingPulse", color = "FF8FC0", at = "Feet", flourish = true, count = 1, size = 3, lifetime = 1.6, glow = 0.9, sprite = "PixelRing" },
			{ kind = "Emitter", color = "7BD14A", at = "Back", rate = 1.5, size = 0.06, lifetime = 2.4, speed = 0.05, spread = 150, rise = 0.04, glow = 0.2, spin = 40, sprite = "PixelLeaf" },
		},
		idle = { kind = "Breathe", amplitude = 2.5, period = 3.6 },
	},
	Nebulyn = {
		element = "Nebula",
		accent = "FFE9A8",
		flourishEvery = 12,
		layers = {
			{ kind = "Orbit", color = "FFFFFF", at = "Body", count = 4, radius = 0.6, period = 6, rate = 6, size = 0.06, lifetime = 0.6, glow = 1, sprite = "PixelStar" },
			{ kind = "Trail", color = "B79CFF", at = "Tail", to = "Body", lifetime = 1.6, width = 0.8 },
			{ kind = "Emitter", color = "FFF6D8", at = "Tail", rate = 6, size = 0.06, lifetime = 1.4, speed = 0.2, spread = 25, glow = 1, dir = "Back", sprite = "PixelTwinkle" },
			{ kind = "Light", color = "8F6BFF", at = "Body", brightness = 1.4, range = 3.4, pulse = 3.4 },
			{ kind = "Emitter", color = "9D7BFF", at = "Body", rate = 4, size = 0.14, lifetime = 2, speed = 0.06, spread = 180, glow = 0.7, sprite = "PixelPuff" },
			-- the flourish: a twinkle burst
			{ kind = "Burst", color = "FFFFFF", at = "Body", flourish = true, count = 24, size = 0.07, lifetime = 1.2, speed = 0.9, spread = 180, glow = 1, sprite = "PixelTwinkle" },
		},
		idle = { kind = "Hover", amplitude = 0.45, period = 3.2 },
	},
	Skaddle = {
		element = "Blizzard",
		accent = "BFE6FF",
		flourishEvery = 10,
		layers = {
			-- a snow flurry swirls round it
			{ kind = "Orbit", color = "FFFFFF", at = "Body", count = 6, radius = 0.6, period = 3, rate = 5, size = 0.06, lifetime = 0.7, glow = 0.4, spin = 90, sprite = "PixelFlake" },
			-- frost ski-tracks behind the skis
			{ kind = "Trail", color = "CFEFFF", at = "FrontL", to = "FrontR", lifetime = 0.9, width = 0.4 },
			{ kind = "Emitter", color = "FFFFFF", at = "Top", rate = 3, size = 0.06, lifetime = 1.8, speed = 0.05, spread = 180, rise = -0.2, glow = 0.3, sprite = "PixelFlake" },
			{ kind = "Light", color = "BFE6FF", at = "Top", brightness = 1.3, range = 3.2, pulse = 3 },
			-- the flourish: a gust lifts it and spreads the flurry
			{ kind = "Burst", color = "FFFFFF", at = "Feet", flourish = true, count = 22, size = 0.07, lifetime = 1.2, speed = 0.9, spread = 90, rise = -0.2, glow = 0.3, spin = 120, sprite = "PixelFlake" },
			{ kind = "RingPulse", color = "CFEFFF", at = "Feet", flourish = true, count = 1, size = 3.2, lifetime = 1.4, glow = 0.8, sprite = "PixelRing" },
		},
		idle = { kind = "Hover", amplitude = 0.3, period = 2.8 },
	},
	-- Cosmic: eight layers, reaching the sky: a pillar on the flourish, an aura, a spawn moment -----------------------------
	Radish = {
		element = "Sun",
		accent = "FFD27A",
		flourishEvery = 18,
		layers = {
			{ kind = "Light", color = "FFD27A", at = "Top", brightness = 2, range = 4.5, pulse = 3 },
			{ kind = "Orbit", color = "FFB347", at = "Top", count = 5, radius = 0.55, period = 4, rate = 7, size = 0.07, lifetime = 0.5, glow = 1, sprite = "PixelMote" },
			{ kind = "Aura", color = "FFE9A8", at = "Body", rate = 1.5, size = 1.3, lifetime = 1.6, glow = 0.6, sprite = "PixelHalo" },
			{ kind = "Emitter", color = "FFE9A8", at = "Top", rate = 6, size = 0.08, lifetime = 1, speed = 0.3, spread = 360, glow = 1, sprite = "PixelStar" },
			-- the flourish: a flare and a column of light from the orb
			{ kind = "Pillar", color = "FFF2C0", at = "Top", flourish = true, reach = 40, width = 0.4, lifetime = 2.2 },
			{ kind = "Burst", color = "FFFFFF", at = "Top", flourish = true, count = 30, size = 0.08, lifetime = 1, speed = 1.2, spread = 180, glow = 1, sprite = "PixelStar" },
			{ kind = "RingPulse", color = "FFC266", at = "Feet", every = 2.5, count = 1, size = 2.2, lifetime = 1.8, glow = 0.9, spin = 30, sprite = "PixelRing" },
			{ kind = "Trail", color = "FFD27A", at = "Tail", to = "Body", lifetime = 1.4, width = 0.8 },
		},
		idle = { kind = "Hover", amplitude = 0.5, period = 3 },
	},
	Fenripup = {
		element = "Moon",
		accent = "C9D6FF",
		flourishEvery = 20,
		layers = {
			{ kind = "Light", color = "C9D6FF", at = "Top", brightness = 1.6, range = 4, pulse = 6 },
			{ kind = "Orbit", color = "DDE6FF", at = "Body", count = 4, radius = 0.55, period = 5, rate = 6, size = 0.06, lifetime = 0.6, glow = 1, sprite = "PixelMote" },
			-- a ground ring of runes, turning once in 12 s
			{ kind = "RingPulse", color = "8F7BFF", at = "Feet", every = 3, count = 1, size = 2.4, lifetime = 2, glow = 0.9, spin = 30, sprite = "PixelRune" },
			{ kind = "Aura", color = "B8C8FF", at = "Body", rate = 1.2, size = 1.3, lifetime = 2, glow = 0.5, sprite = "PixelHalo" },
			{ kind = "Emitter", color = "3A2C7A", at = "Feet", rate = 4, size = 0.16, lifetime = 1.8, speed = 0.12, spread = 90, rise = 0.08, glow = 0, sprite = "PixelPuff" },
			{ kind = "Trail", color = "6C5CE7", at = "Tail", to = "Body", lifetime = 1.6, width = 0.8 },
			-- the howl: a beam of moonlight from the forehead and a flare of stars
			{ kind = "Pillar", color = "E6ECFF", at = "Top", flourish = true, reach = 45, width = 0.35, lifetime = 2.6 },
			{ kind = "Burst", color = "E6ECFF", at = "Top", flourish = true, count = 24, size = 0.07, lifetime = 1.4, speed = 0.8, spread = 120, rise = 0.1, glow = 1, sprite = "PixelTwinkle" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2.4 },
	},
	-- Secret: the Cosmic set in its shadow palette (the tier's dark variant on top) ---------------------------------------
	Panpipe = {
		element = "Shadow",
		accent = "B28CFF",
		flourishEvery = 20,
		layers = {
			-- notes drift from the pipes on a trill every 4 s, and fall instead of rise
			{ kind = "Burst", color = "B28CFF", at = "Top", every = 4, count = 5, size = 0.08, lifetime = 2.2, speed = 0.12, spread = 50, rise = -0.08, glow = 0.8, sprite = "PixelNote" },
			{ kind = "Light", color = "7A3CFF", at = "Body", brightness = 1.4, range = 3.6, pulse = 2 },
			{ kind = "Orbit", color = "8E6BFF", at = "Top", count = 3, radius = 0.6, period = 5, rate = 6, size = 0.07, lifetime = 0.6, glow = 1, sprite = "PixelNote" },
			{ kind = "RingPulse", color = "A07BFF", at = "Feet", every = 3.5, count = 1, size = 2.4, lifetime = 2.2, glow = 0.9, spin = -20, sprite = "PixelRing" },
			{ kind = "Emitter", color = "1A1A1A", at = "Feet", rate = 4, size = 0.16, lifetime = 2, speed = 0.12, spread = 80, rise = -0.04, glow = 0, sprite = "PixelPuff" },
			{ kind = "Aura", color = "5B3FA8", at = "Body", rate = 1.2, size = 1.3, lifetime = 2, glow = 0.5, sprite = "PixelHalo" },
			-- the flourish: a hop, a vanish in smoke and a return under a violet column
			{ kind = "Pillar", color = "A07BFF", at = "Top", flourish = true, reach = 40, width = 0.35, lifetime = 2 },
			{ kind = "Burst", color = "2A1F3D", at = "Body", flourish = true, count = 28, size = 0.12, lifetime = 1.2, speed = 0.8, spread = 180, glow = 0, sprite = "PixelPuff" },
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
	SpawnMoment = spawnMoment,
	Dark = dark,
	SpriteFallback = spriteFallback,
	Sheets = sheets,
	Look = look,
	Motion = motion,
	Reduced = reduced,
}
