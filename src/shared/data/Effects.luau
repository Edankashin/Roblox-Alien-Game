--!strict
-- Per-species effects and idle motion, drawn by the client's World.SpeciesFx (the server never reads this table).
-- B46 (2026-10-20): effects carry rarity, and they climb steeply. Every alien stands 2 to 3.5 studs (B45), so a rarer one
-- reads as more exclusive by its effects, never by its size, and never fiercer.
-- Species: one row per species id (all 35): an element label, the effect layers strongest first, and an idle motion.
-- Tiers: what each rarity may draw of them: how many layers, which kinds (the body up to Epic, the ground from Legendary, the
-- sky from Cosmic), the scales, and the extras it adds (trail, orbit, ground ring, aura, sky pillar, flourish, spawn moment).
-- Caps: the per-client budgets. Attach: the body regions layers hang on, as fractions of the alien's bounds. Pieces: the
-- signature pieces (Rare and up) on named moving parts, which a layer follows as the rig moves them; a row's `signature` names
-- its piece, and its first layer hangs there.
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
	-- Signature pieces that do not move (part of the static Body mesh), so they are plain points of the bounds (the creature
	-- notes' VFX hooks, Rare pass 2026-10-21): Blinkar's crystal antlers, Gaira's gilded medallion.
	Antlers = { x = 0.32, y = 0.84, z = -0.18 },
	AntlersL = { x = -0.32, y = 0.84, z = -0.18 },
	Medallion = { x = -0.02, y = 0.24, z = -0.36 },
}

-- Signature pieces on moving parts (the Rare pass, 2026-10-21: every Rare to Secret alien got a named piece that moves on its own;
-- the hook tables in the creature notes, docs/vault/07-alien-game/Creatures). A layer whose `at` (or `to`) names one of these hangs
-- on the model's part named `part` (the Blender object's rig name, as data/Rigs names it and the GLB exports it), at `spot` in the
-- part's own box (fractions of each side from its centre; up to 1 reaches a little past a face), so it follows the part as
-- World.RigAnimator spins, sways and pops it: an orbiting comet carries its own sparkle trail, a pane its light. On a model without
-- that part (today's old blockouts, until the block-cell upload) the layer falls back to `region`, the nearest body region. Spots
-- are measured from each note's parts (the hook part's centre in its moving object's box); lint and tests/Effects.spec.luau check
-- every piece a species names against that species' Rigs row. Paired names (Glass and GlassB) are two spots on one part.
local pieces: { [string]: Types.FxPiece } = {
	-- World 1
	Geode = { part = "geodeL", spot = { 0, 0.45, 0 }, region = "Top" }, -- Boulden: the tip of the tall lit crystal
	Palette = { part = "paletteL", spot = { -0.14, -0.21, -0.32 }, region = "FrontL" }, -- Vixa: the lit dab
	Arc = { part = "arc", spot = { -0.38, -0.25, 0 }, region = "Halo" }, -- Zirrit: the spark gap's two ends
	ArcEnd = { part = "arc", spot = { 0.38, 0.25, 0 }, region = "Top" },
	Glass = { part = "glass", spot = { 0, 0.3, -0.48 }, region = "Body" }, -- Wispkin: the front pane and the back one
	GlassB = { part = "glass", spot = { 0, -0.1, 0.48 }, region = "Back" },
	Panes = { part = "wingR", spot = { -0.23, -0.25, -0.33 }, region = "BackR" }, -- Iridia: the stained glass of each wing
	PanesL = { part = "wingL", spot = { 0.23, -0.25, -0.33 }, region = "BackL" },
	Cloud = { part = "cloudR", spot = { -0.06, -0.43, 0 }, region = "Back" }, -- Voltus: under the thundercloud
	Charge = { part = "charge", spot = { 0.49, 0, -0.41 }, region = "BackR" }, -- Voltus: the front cell of the gauge
	Candles = { part = "candles", spot = { 0.43, 0.4, -0.42 }, region = "Halo" }, -- Grin: the three flames
	CandlesB = { part = "candles", spot = { -0.43, 0.4, -0.42 }, region = "Top" },
	CandlesC = { part = "candles", spot = { 0, 0.4, 0.42 }, region = "Back" },
	Mantle = { part = "cape", spot = { 0, 0.5, 0.25 }, region = "Back" }, -- Gaira: the glass-petal mantle
	Comet = { part = "comet", spot = { -0.32, 0, 0 }, region = "Halo" }, -- Cosmoo: the comet's head, and over it (the tail's span)
	CometTail = { part = "comet", spot = { -0.32, 0.5, 0 }, region = "Top" },
	Sunstones = { part = "sunstone", spot = { 0, 0, -0.46 }, region = "Feet" }, -- Raddis: the front sun, the back one, over the front one
	SunstonesB = { part = "sunstone", spot = { 0, 0, 0.46 }, region = "Tail" },
	SunstonesTop = { part = "sunstone", spot = { 0, 0.15, -0.46 }, region = "Body" },
	Eclipse = { part = "eclipse", spot = { 0, 0, 0.8 }, region = "Halo" }, -- Syrinx: just behind the disc's middle (a corona shows round it)
	EclipseRim = { part = "eclipse", spot = { 0.29, 0.29, -0.5 }, region = "Top" }, -- Syrinx: the diamond bead on the rim
	Echo = { part = "echoR", spot = { 0, 0, 0 }, region = "BackR" }, -- Syrinx: the echo ring over the pipes
	Shards = { part = "shards", spot = { 0, 0, -0.46 }, region = "Body" }, -- Syrinx: the front of the satellite ring (eclipse shards, wool tufts, notes)
	-- World 2
	Ring = { part = "ring", spot = { 0.41, 0, 0.03 }, region = "Top" }, -- Snorzo: the big bubbles of the planet ring
	RingB = { part = "ring", spot = { -0.41, 0, -0.31 }, region = "Halo" },
	Summit = { part = "shardsR", spot = { 0.43, 0, 0 }, region = "Top" }, -- Floe: the two shard moons
	SummitB = { part = "shardsR", spot = { -0.43, 0, 0 }, region = "Halo" },
	Crown = { part = "crown", spot = { 0, 0, 0 }, region = "Top" }, -- Sabrek: the snowflake's middle and a tip
	CrownTip = { part = "crown", spot = { 0.25, 0.25, 0 }, region = "Halo" },
	Plume = { part = "tailR", spot = { 0, 0.5, 0 }, region = "Tail" }, -- Aurelyx: the plume's tip and its root (the ribbon's span)
	PlumeBase = { part = "tailR", spot = { 0, 0.2, 0 }, region = "Back" },
	Runes = { part = "halo", spot = { 0.43, 0.07, -0.42 }, region = "Halo" }, -- Skadra: two of the three runes
	RunesB = { part = "halo", spot = { 0, 0.07, 0.42 }, region = "Top" },
	Moon = { part = "halo", spot = { 0, 0.15, -0.46 }, region = "Top" }, -- Fenrir: the silver crescent behind it, its front face (the brow moon was cut, v2b)
	Mane = { part = "mane", spot = { 0.3, 0.2, -0.21 }, region = "Back" }, -- Fenrir: the nebula mane
	Phases = { part = "phases", spot = { 0, 0, -0.46 }, region = "Body" }, -- Fenrir: the front of the satellite ring (moon phases and frost shards)
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
-- length; BeamTransparency is the bolt's. TrailTransparency is the ribbon's start (it fades to 1 along its life, and narrows to
-- TrailTaper of its width, so a comet's tail tapers). PulseDepth:
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
	TrailTaper = 0.25,
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
	-- Rare: three layers, a soft light and a sparkle among them, all on the signature piece -----------------------------------
	Rocklobber = {
		element = "Boulder",
		signature = "Geode",
		layers = {
			-- the open amber geode: motes rise off the lit crystals, which throb with light
			{ kind = "Emitter", color = "FF8C1A", at = "Geode", rate = 6, size = 0.06, lifetime = 1.3, speed = 0.12, spread = 30, rise = 0.12, glow = 1, sprite = "PixelMote" },
			{ kind = "Light", color = "F5B342", at = "Geode", brightness = 1, range = 2.2, pulse = 2.2 },
			-- the crystals glint, and flash on the flourish
			{ kind = "Sparkle", color = "FFD27A", at = "Geode", every = 3, flourish = true, count = 2, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelTwinkle" },
			-- the claws clack: a dust puff and pebble chips
			{ kind = "Burst", color = "A89F91", at = "FrontL", every = 5, count = 6, size = 0.07, lifetime = 0.8, speed = 0.3, spread = 70, rise = -0.6, glow = 0, sprite = "PixelGrit" },
		},
		idle = { kind = "Bob", amplitude = 0.15, period = 1.4 },
	},
	Zapfinch = {
		element = "Static",
		signature = "Arc",
		layers = {
			-- the spark gap: an arc crackles between the two ends of the zigzag
			{ kind = "Beam", color = "8FD3FF", at = "Arc", to = "ArcEnd", width = 0.04, flicker = 1.2, segments = 5 },
			{ kind = "Light", color = "8FD3FF", at = "Arc", brightness = 0.9, range = 2.2, pulse = 1 },
			-- sparks jump off the far end, and on the flourish
			{ kind = "Sparkle", color = "CFEFFF", at = "ArcEnd", every = 1.6, flourish = true, count = 2, size = 0.09, lifetime = 0.35, glow = 1, sprite = "PixelSpark" },
			{ kind = "Burst", color = "CFEFFF", at = "Arc", flourish = true, count = 10, size = 0.05, lifetime = 0.4, speed = 0.8, spread = 180, glow = 1, sprite = "PixelSpark" },
		},
		idle = { kind = "Flap", amplitude = 15, period = 0.35, parts = wings },
	},
	Sparkfox = {
		element = "Ember",
		signature = "Palette",
		layers = {
			-- the floating palette: paint drips off the lit dab and falls (more of it on the flourish)
			{ kind = "Burst", color = "FF8A3D", at = "Palette", every = 2.5, flourish = true, count = 3, size = 0.05, lifetime = 0.9, speed = 0.05, spread = 20, rise = -0.9, glow = 0.8, dir = "Down", sprite = "PixelDrop" },
			{ kind = "Light", color = "FFB45A", at = "Palette", brightness = 1, range = 2.2, pulse = 2 },
			{ kind = "Sparkle", color = "FFD27A", at = "Palette", every = 2, count = 1, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelSparkle" },
			{ kind = "Emitter", color = "FF8A3D", at = "Tail", rate = 6, size = 0.06, lifetime = 0.8, speed = 0.3, spread = 35, rise = 0.35, glow = 1, sprite = "PixelEmberFlicker" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.3 },
	},
	Wisplet = {
		element = "Spirit",
		signature = "Glass",
		layers = {
			-- the orbiting lantern glass: the leading pane leaves a lilac glow behind it and carries the lantern's light round
			{ kind = "Emitter", color = "9466FF", at = "Glass", rate = 8, size = 0.06, lifetime = 0.9, speed = 0.02, spread = 180, glow = 1, sprite = "PixelMote" },
			{ kind = "Light", color = "9BE7FF", at = "Glass", brightness = 1.2, range = 2.6, pulse = 1.4 },
			-- the far pane twinkles, and on the flourish
			{ kind = "Sparkle", color = "C9A8FF", at = "GlassB", every = 2.5, flourish = true, count = 2, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelTwinkle" },
			{ kind = "Emitter", color = "9BE7FF", at = "Body", rate = 0.7, size = 0.09, lifetime = 1.8, speed = 0.08, spread = 60, rise = 0.15, glow = 1, sprite = "PixelMote" },
		},
		idle = { kind = "Hover", amplitude = 0.5, period = 2.8 },
	},
	Reindazzle = {
		element = "Frost",
		signature = "Antlers",
		layers = {
			-- the branching crystal antlers: frost glints rise off the tines
			{ kind = "Emitter", color = "DFF4FF", at = "Antlers", rate = 4, size = 0.06, lifetime = 0.7, speed = 0.04, spread = 180, glow = 1, sprite = "PixelSparkle" },
			-- the lantern nose blinks red
			{ kind = "Light", color = "FF4D4D", at = "Mouth", brightness = 1.1, range = 1.4, pulse = 2 },
			{ kind = "Sparkle", color = "9FE3FF", at = "AntlersL", every = 3, flourish = true, count = 2, size = 0.1, lifetime = 0.5, glow = 1, sprite = "PixelTwinkle" },
			{ kind = "Emitter", color = "DFF4FF", at = "AntlersL", rate = 2.5, size = 0.05, lifetime = 0.7, speed = 0.04, spread = 180, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.5 },
	},
	Shellberg = {
		element = "Iceberg",
		signature = "Summit",
		layers = {
			-- the summit shard moons: the leading shard trails ice glints round the peak and carries a cold light
			{ kind = "Emitter", color = "CFF6F2", at = "Summit", rate = 7, size = 0.05, lifetime = 0.7, speed = 0.02, spread = 180, glow = 1, sprite = "PixelSparkle" },
			{ kind = "Light", color = "9FD8FF", at = "Summit", brightness = 0.9, range = 2.4, pulse = 3 },
			{ kind = "Sparkle", color = "FFFFFF", at = "SummitB", every = 2.5, flourish = true, count = 2, size = 0.11, lifetime = 0.5, glow = 1, sprite = "PixelTwinkle" },
			-- cold mist rolls off the berg and pools at its feet
			{ kind = "Emitter", color = "CFF6F2", at = "Back", rate = 3, size = 0.12, lifetime = 2, speed = 0.06, spread = 80, rise = -0.1, glow = 0, sprite = "PixelPuff" },
		},
		idle = { kind = "Breathe", amplitude = 2, period = 4.5 },
	},
	Capybubble = {
		element = "Bubble",
		signature = "Ring",
		layers = {
			-- the bubble planet ring: the big bubble leaves tiny bubbles behind as it circles, and glows sea green
			{ kind = "Emitter", color = "BFEFFF", at = "Ring", rate = 4, size = 0.05, lifetime = 1.4, speed = 0.03, spread = 180, rise = 0.04, glow = 0.4, sprite = "PixelBubble" },
			{ kind = "Light", color = "7FE0D0", at = "Ring", brightness = 0.8, range = 2.4, pulse = 3.4 },
			{ kind = "Sparkle", color = "FFFFFF", at = "RingB", every = 3, flourish = true, count = 1, size = 0.1, lifetime = 0.45, glow = 1, sprite = "PixelSparkle" },
			-- three snore bubbles drift out from its nose
			{ kind = "Burst", color = "BFEFFF", at = "Mouth", every = 4, count = 3, size = 0.09, lifetime = 2.4, speed = 0.15, spread = 25, rise = 0.08, glow = 0.3, dir = "Front", sprite = "PixelBubble" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3.4 },
	},
	-- Epic: five layers kept on the body, a signature Burst among them, the piece the star ------------------------------------
	Thunderhog = {
		element = "Lightning",
		signature = "Cloud",
		layers = {
			-- the pocket thundercloud strikes down to the charge gauge every 2 s
			{ kind = "Beam", color = "FFF27A", at = "Cloud", to = "Charge", width = 0.06, flicker = 2, segments = 7 },
			-- and drips rain
			{ kind = "Emitter", color = "BFD9FF", at = "Cloud", rate = 7, size = 0.04, lifetime = 0.45, speed = 0.15, spread = 12, rise = -1.4, glow = 0.4, dir = "Down", sprite = "PixelDrop" },
			{ kind = "Light", color = "C084FC", at = "Cloud", brightness = 1.1, range = 2.6, pulse = 2 },
			-- the flourish: the cloud discharges in a crackle of sparks
			{ kind = "Burst", color = "FFF8B0", at = "Cloud", every = 6, flourish = true, count = 14, size = 0.06, lifetime = 0.4, speed = 0.9, spread = 180, glow = 1, sprite = "PixelSpark" },
			-- a flicker runs along the gauge
			{ kind = "Sparkle", color = "FFF27A", at = "Charge", every = 1.5, count = 1, size = 0.08, lifetime = 0.3, glow = 1, sprite = "PixelSpark" },
			{ kind = "Beam", color = "FFF27A", at = "BackL", to = "BackR", width = 0.05, flicker = 3, segments = 8 },
		},
		idle = { kind = "Bob", amplitude = 0.12, period = 1.1 },
	},
	Gloomoth = {
		element = "Crystal",
		signature = "Panes",
		layers = {
			-- the stained-glass wings throw orchid light as they beat
			{ kind = "Light", color = "B832E8", at = "Panes", brightness = 1.1, range = 3, pulse = 2.6 },
			-- a glint sweeps the panes of each wing
			{ kind = "Sparkle", color = "E1B8FF", at = "Panes", every = 2.4, count = 2, size = 0.12, lifetime = 0.6, glow = 1, sprite = "PixelTwinkle" },
			-- the flourish: prism dust shaken off the panes
			{ kind = "Burst", color = "FFC8F0", at = "Panes", every = 7, flourish = true, count = 14, size = 0.07, lifetime = 1.1, speed = 0.5, spread = 120, rise = -0.2, glow = 1, sprite = "PixelSparkle" },
			{ kind = "Sparkle", color = "9FE8FF", at = "PanesL", every = 2.4, count = 2, size = 0.12, lifetime = 0.6, glow = 1, sprite = "PixelTwinkle" },
			{ kind = "Emitter", color = "C8A2E8", at = "PanesL", rate = 3, size = 0.05, lifetime = 1.4, speed = 0.06, spread = 100, rise = -0.15, glow = 0.5, sprite = "PixelMote" },
		},
		idle = { kind = "Flap", amplitude = 22, period = 0.9, parts = wings },
	},
	Spookum = {
		element = "Ghost",
		signature = "Candles",
		layers = {
			-- three floating candles: real flame sprites on the wicks...
			{ kind = "Emitter", color = "C77DFF", at = "Candles", rate = 9, size = 0.07, lifetime = 0.35, speed = 0.12, spread = 8, rise = 0.25, glow = 1, sprite = "PixelEmberFlicker" },
			-- ...and a soft warm candlelight that flickers
			{ kind = "Light", color = "FFB45A", at = "Candles", brightness = 1, range = 2.6, pulse = 0.9 },
			-- "boo": a puff of violet wisps off the candles, and on the flourish
			{ kind = "Burst", color = "C77DFF", at = "Candles", every = 9, flourish = true, count = 12, size = 0.09, lifetime = 1.1, speed = 0.4, spread = 180, glow = 0.6, sprite = "PixelPuff" },
			{ kind = "Emitter", color = "C77DFF", at = "CandlesB", rate = 9, size = 0.07, lifetime = 0.35, speed = 0.12, spread = 8, rise = 0.25, glow = 1, sprite = "PixelEmberFlicker" },
			{ kind = "Sparkle", color = "FFD27A", at = "CandlesC", every = 1.1, count = 1, size = 0.07, lifetime = 0.35, glow = 1, sprite = "PixelSparkle" },
			{ kind = "Emitter", color = "E9E2FF", at = "Feet", rate = 3, size = 0.16, lifetime = 1.8, speed = 0.04, spread = 60, rise = 0.05, glow = 0.5, sprite = "PixelPuff" },
		},
		idle = { kind = "Hover", amplitude = 0.35, period = 3 },
	},
	Shimmerlynx = {
		element = "Aurora",
		signature = "Plume",
		layers = {
			-- the aurora comet tail: a ribbon of aurora streams off the plume as it sways
			{ kind = "Trail", color = "7CFFC4", at = "Plume", to = "PlumeBase", lifetime = 1.2, width = 1, glow = 1 },
			{ kind = "Emitter", color = "B38CFF", at = "Plume", rate = 4, size = 0.07, lifetime = 1.8, speed = 0.1, spread = 40, rise = 0.15, glow = 1, sprite = "PixelMote" },
			{ kind = "Light", color = "7CFFC4", at = "Plume", brightness = 1, range = 2.8, pulse = 3 },
			-- it purrs in colours: an aurora shimmer off the plume, and on the flourish
			{ kind = "Burst", color = "FF9BE0", at = "Plume", every = 6, flourish = true, count = 12, size = 0.08, lifetime = 1.4, speed = 0.4, spread = 70, rise = 0.2, glow = 1, sprite = "PixelTwinkle" },
			{ kind = "Sparkle", color = "DFFFF3", at = "Eyes", every = 5, count = 1, size = 0.05, lifetime = 0.35, glow = 1, sprite = "PixelSparkle" },
		},
		idle = { kind = "Bob", amplitude = 0.1, period = 1.4 },
	},
	Frostfang = {
		element = "Frost",
		signature = "Crown",
		layers = {
			-- the snowflake crown: the flourish scatters crystal glints off it
			{ kind = "Burst", color = "FFFFFF", at = "Crown", every = 12, flourish = true, count = 18, size = 0.07, lifetime = 1.1, speed = 0.7, spread = 180, glow = 1, spin = 120, sprite = "PixelSparkle" },
			{ kind = "Light", color = "8AD0FF", at = "Crown", brightness = 1, range = 2.8, pulse = 3 },
			-- a tip of the turning flake sparkles
			{ kind = "Sparkle", color = "DFF6FF", at = "CrownTip", every = 1.5, count = 1, size = 0.1, lifetime = 0.45, glow = 1, sprite = "PixelTwinkle" },
			-- the sneeze: twenty snowflakes thrown forward every 12 s
			{ kind = "Burst", color = "FFFFFF", at = "Mouth", every = 12, count = 20, size = 0.07, lifetime = 1.2, speed = 0.8, spread = 40, rise = -0.3, glow = 0.4, dir = "Front", spin = 120, sprite = "PixelFlake" },
			-- flakes drift back off the crown, never over the face
			{ kind = "Emitter", color = "FFFFFF", at = "Crown", rate = 2.5, size = 0.05, lifetime = 1.6, speed = 0.12, spread = 60, rise = -0.1, glow = 0.4, dir = "Back", sprite = "PixelFlake" },
		},
		idle = { kind = "Breathe", amplitude = 4, period = 1.8 },
	},
	-- Legendary: six layers, the ground ring, orbiting motes and a flourish, the piece the star -------------------------------
	Gaiabloom = {
		element = "Bloom",
		accent = "F59E0B",
		flourishEvery = 10,
		signature = "Mantle",
		layers = {
			-- the glass-petal mantle sheds petals as it moves
			{ kind = "Emitter", color = "F0287E", at = "Mantle", rate = 3, size = 0.06, lifetime = 2.4, speed = 0.08, spread = 140, rise = -0.1, glow = 0.4, spin = 90, sprite = "PixelPetal" },
			-- the flourish: the mantle lifts and throws a shower of petals
			{ kind = "Burst", color = "FFB7D5", at = "Mantle", flourish = true, count = 22, size = 0.07, lifetime = 2, speed = 0.55, spread = 140, rise = -0.12, glow = 0.3, spin = 120, sprite = "PixelPetal" },
			{ kind = "Light", color = "F0287E", at = "Mantle", brightness = 1.3, range = 3.2, pulse = 3.6 },
			{ kind = "Orbit", color = "FFB7D5", at = "Top", count = 4, radius = 0.45, period = 5, rate = 6, size = 0.06, lifetime = 0.6, glow = 0.5, spin = 90, sprite = "PixelPetal" },
			{ kind = "RingPulse", color = "FF8FC0", at = "Feet", flourish = true, count = 1, size = 3, lifetime = 1.6, glow = 0.9, sprite = "PixelRing" },
			-- the gilded medallion glints pink
			{ kind = "Sparkle", color = "FF8FC0", at = "Medallion", every = 3, count = 1, size = 0.09, lifetime = 0.45, glow = 1, sprite = "PixelSparkle" },
			-- a flower pops in each footprint
			{ kind = "Burst", color = "FFE066", at = "Feet", every = 2.4, count = 4, size = 0.07, lifetime = 1, speed = 0.2, spread = 60, rise = 0.1, glow = 0.6, sprite = "PixelPetal" },
		},
		idle = { kind = "Breathe", amplitude = 2.5, period = 3.6 },
	},
	Nebulyn = {
		element = "Nebula",
		accent = "FFE9A8",
		flourishEvery = 12,
		signature = "Comet",
		layers = {
			-- the pet comet: a stream of gold stars left along its circle...
			{ kind = "Emitter", color = "FFE9A8", at = "Comet", rate = 12, size = 0.05, lifetime = 1.1, speed = 0.02, spread = 180, glow = 1, sprite = "PixelTwinkle" },
			-- ...and a proper tail, a gold ribbon off its head
			{ kind = "Trail", color = "FFC21A", at = "Comet", to = "CometTail", lifetime = 0.9, width = 1, glow = 1 },
			{ kind = "Light", color = "FFD27A", at = "Comet", brightness = 1.3, range = 3, pulse = 3 },
			-- the flourish: the comet bursts into twinkles
			{ kind = "Burst", color = "FFFFFF", at = "Comet", flourish = true, count = 24, size = 0.07, lifetime = 1.2, speed = 0.9, spread = 180, glow = 1, sprite = "PixelTwinkle" },
			{ kind = "Orbit", color = "FFFFFF", at = "Body", count = 4, radius = 0.6, period = 6, rate = 6, size = 0.06, lifetime = 0.6, glow = 1, sprite = "PixelStar" },
			{ kind = "Emitter", color = "9D7BFF", at = "Body", rate = 3, size = 0.14, lifetime = 2, speed = 0.06, spread = 180, glow = 0.7, sprite = "PixelPuff" },
		},
		idle = { kind = "Hover", amplitude = 0.45, period = 3.2 },
	},
	Skaddle = {
		element = "Blizzard",
		accent = "BFE6FF",
		flourishEvery = 10,
		signature = "Runes",
		layers = {
			-- the halo of frost runes: the leading rune trails frost round the crown and carries a cold light
			{ kind = "Emitter", color = "BFE6FF", at = "Runes", rate = 8, size = 0.05, lifetime = 0.8, speed = 0.02, spread = 180, glow = 1, sprite = "PixelFlake" },
			{ kind = "Light", color = "BFE6FF", at = "Runes", brightness = 1.3, range = 3.2, pulse = 3 },
			-- the flourish: the halo whirls and throws rune glints and flakes
			{ kind = "Burst", color = "FFFFFF", at = "Runes", flourish = true, count = 22, size = 0.07, lifetime = 1.2, speed = 0.9, spread = 180, rise = -0.2, glow = 0.6, spin = 120, sprite = "PixelFlake" },
			{ kind = "Orbit", color = "FFFFFF", at = "Body", count = 6, radius = 0.6, period = 3, rate = 5, size = 0.06, lifetime = 0.7, glow = 0.4, spin = 90, sprite = "PixelFlake" },
			{ kind = "RingPulse", color = "CFEFFF", at = "Feet", flourish = true, count = 1, size = 3.2, lifetime = 1.4, glow = 0.8, sprite = "PixelRing" },
			-- gold glints off the rune behind (Legendary's gilded trim)
			{ kind = "Emitter", color = "E8B23A", at = "RunesB", rate = 4, size = 0.04, lifetime = 0.8, speed = 0.02, spread = 180, glow = 1, sprite = "PixelSparkle" },
			-- frost ski-tracks behind the skis
			{ kind = "Trail", color = "CFEFFF", at = "FrontL", to = "FrontR", lifetime = 0.9, width = 0.4 },
		},
		idle = { kind = "Hover", amplitude = 0.3, period = 2.8 },
	},
	-- Cosmic: eight layers, reaching the sky; the piece carries the light, the trail and the burst ------------------------------
	Radish = {
		element = "Sun",
		accent = "FFD27A",
		flourishEvery = 18,
		signature = "Sunstones",
		layers = {
			-- the ring of orbiting sunstones: each sun leaves a short trail of gold sparks...
			{ kind = "Emitter", color = "FFC21A", at = "Sunstones", rate = 14, size = 0.05, lifetime = 0.6, speed = 0.03, spread = 180, glow = 1, sprite = "PixelSpark" },
			{ kind = "Emitter", color = "FFC21A", at = "SunstonesB", rate = 14, size = 0.05, lifetime = 0.6, speed = 0.03, spread = 180, glow = 1, sprite = "PixelSpark" },
			-- ...and the sun's light rides the ring, pulsing
			{ kind = "Light", color = "FFC21A", at = "Sunstones", brightness = 2, range = 4.5, pulse = 3 },
			{ kind = "Trail", color = "FFD27A", at = "Sunstones", to = "SunstonesTop", lifetime = 0.5, width = 1, glow = 1 },
			-- the flourish: the ring rises and whirls, a column of light from the orb and a star burst off the suns
			{ kind = "Pillar", color = "FFF2C0", at = "Top", flourish = true, reach = 40, width = 0.4, lifetime = 2.2 },
			{ kind = "Burst", color = "FFE9A8", at = "Sunstones", flourish = true, count = 30, size = 0.08, lifetime = 1, speed = 1.2, spread = 180, glow = 1, sprite = "PixelStar" },
			{ kind = "Orbit", color = "FFB347", at = "Top", count = 5, radius = 0.55, period = 4, rate = 7, size = 0.07, lifetime = 0.5, glow = 1, sprite = "PixelMote" },
			{ kind = "RingPulse", color = "FFC266", at = "Feet", every = 2.5, count = 1, size = 2.2, lifetime = 1.8, glow = 0.9, spin = 30, sprite = "PixelRing" },
		},
		idle = { kind = "Hover", amplitude = 0.5, period = 3 },
	},
	Fenripup = {
		element = "Moon",
		accent = "C9D6FF",
		flourishEvery = 20,
		signature = "Moon",
		layers = {
			-- the crescent moon glows...
			{ kind = "Light", color = "C9D6FF", at = "Moon", brightness = 1.6, range = 4, pulse = 6 },
			-- ...and sheds frost motes that drift back over the pup
			{ kind = "Emitter", color = "DDE6FF", at = "Moon", rate = 6, size = 0.05, lifetime = 1.6, speed = 0.15, spread = 50, rise = -0.05, glow = 0.8, dir = "Back", sprite = "PixelFlake" },
			{ kind = "Aura", color = "B8C8FF", at = "Moon", rate = 1.2, size = 0.45, lifetime = 2, glow = 0.5, sprite = "PixelHalo" },
			-- stars twinkle in the nebula mane
			{ kind = "Sparkle", color = "FFFFFF", at = "Mane", every = 2, count = 1, size = 0.08, lifetime = 0.5, glow = 1, sprite = "PixelTwinkle" },
			-- the howl: a beam of moonlight from the moon and a flare of stars
			{ kind = "Pillar", color = "E6ECFF", at = "Moon", flourish = true, reach = 45, width = 0.35, lifetime = 2.6 },
			{ kind = "Burst", color = "E6ECFF", at = "Moon", flourish = true, count = 24, size = 0.07, lifetime = 1.4, speed = 0.8, spread = 120, rise = 0.1, glow = 1, dir = "Back", sprite = "PixelTwinkle" },
			-- a ground ring of runes, turning once in 12 s
			{ kind = "RingPulse", color = "8F7BFF", at = "Feet", every = 3, count = 1, size = 2.4, lifetime = 2, glow = 0.9, spin = 30, sprite = "PixelRune" },
			-- the moon phases and frost shards are modelled now (the `phases` ring): frost motes shed off it as it turns
			{ kind = "Emitter", color = "DDE6FF", at = "Phases", rate = 6, size = 0.06, lifetime = 0.8, speed = 0.03, spread = 180, glow = 1, sprite = "PixelMote" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 2.4 },
	},
	-- Secret: the Cosmic set in its shadow palette (the tier's dark variant on top) ---------------------------------------
	Panpipe = {
		element = "Shadow",
		accent = "B28CFF",
		flourishEvery = 20,
		signature = "Eclipse",
		layers = {
			-- the eclipse throws a dark corona (halo cells behind the disc, so only its rim shows)...
			{ kind = "Emitter", color = "1A1030", at = "Eclipse", rate = 1.5, size = 0.62, lifetime = 1.6, speed = 0, spread = 0, glow = 0, sprite = "PixelHalo" },
			-- ...lit at its rim by the accent, where the diamond bead turns
			{ kind = "Light", color = "9B5CFF", at = "EclipseRim", brightness = 1.4, range = 3.6, pulse = 2 },
			-- the flourish: the violet column rises from the eclipse and it throws a ring of dark motes
			{ kind = "Pillar", color = "A07BFF", at = "Eclipse", flourish = true, reach = 40, width = 0.35, lifetime = 2 },
			{ kind = "Burst", color = "2A1F3D", at = "Eclipse", flourish = true, count = 28, size = 0.1, lifetime = 1.4, speed = 0.7, spread = 180, glow = 0, sprite = "PixelPuff" },
			-- a slow rain of dark motes off the disc, drifting back
			{ kind = "Emitter", color = "3A2C5A", at = "Eclipse", rate = 3, size = 0.05, lifetime = 2.2, speed = 0.04, spread = 90, rise = -0.08, glow = 0, dir = "Back", sprite = "PixelMote" },
			-- notes drift from the echo ring over the pipes on a trill every 4 s, and fall instead of rise
			{ kind = "Burst", color = "B28CFF", at = "Echo", every = 4, count = 5, size = 0.08, lifetime = 2.2, speed = 0.12, spread = 50, rise = -0.08, glow = 0.8, sprite = "PixelNote" },
			-- the satellites are modelled now (eclipse shards, wool tufts, notes on the `shards` ring): notes drift off the ring and fall
			{ kind = "Emitter", color = "8E6BFF", at = "Shards", rate = 6, size = 0.07, lifetime = 0.9, speed = 0.03, spread = 180, rise = -0.06, glow = 1, sprite = "PixelNote" },
			{ kind = "RingPulse", color = "A07BFF", at = "Feet", every = 3.5, count = 1, size = 2.4, lifetime = 2.2, glow = 0.9, spin = -20, sprite = "PixelRing" },
		},
		idle = { kind = "Breathe", amplitude = 3, period = 3 },
	},
}

return {
	Species = species,
	Tiers = tiers,
	Caps = caps,
	Attach = attach,
	Pieces = pieces,
	Extras = extras,
	SpawnMoment = spawnMoment,
	Dark = dark,
	SpriteFallback = spriteFallback,
	Sheets = sheets,
	Look = look,
	Motion = motion,
	Reduced = reduced,
}
