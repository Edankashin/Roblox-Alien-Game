--!strict
-- The spectacle ladder (Ethan, 2026-10-21: "make the rare aliens 1000x cooler"; B46: effects and motion carry rarity, never size,
-- never fiercer): how a wild alien of each tier arrives, carries itself while it stays, reacts to a player and leaves in a catch.
-- Drawn by the client's World.Spectacle with Shared/SpectacleMath; the server never reads this table, and nothing here decides an
-- outcome (a catch, a flight, a spawn): the client only dresses what the server already said. The species' own layers stay in
-- data/Effects (World.SpeciesFx) and its clips in data/Rigs (World.RigAnimator); this table is the tier's stage around them.
-- Arrivals: Rare a pixel-portal pop, Epic a burst of cells and a light pulse, Legendary a falling star that lands and blooms a ground
-- ring, Cosmic the sky dims a touch, a beam comes down and the alien descends in it to a shockwave of cells (SpeciesFx's spawn moment,
-- the pillar and star burst, rides on top), Secret a glitch-in (the screen edge flickers, the alien assembles from cells). From Epic a
-- beacon stands over it, for `beacon` seconds or (-1) while it stays, so it can be followed from far; the compass and radar are unchanged.
-- Presence: Rare and up a light pool on the ground in its colour; Epic and up glyph cells orbiting its head; Legendary and up footprints
-- that bloom (World 1 flowers, World 2 frost) and a soft aura (Cosmic and Secret wear data/Effects' aura shell instead); Cosmic and
-- Secret a trail of cells when they move and a shimmer (a star field, a dark heat haze); an ambient note per tier (Sounds.TierAmbient).
-- Personality: every alien wanders a short leash and plays (look round, stretch, sit, sleep at night with Zz cells), notices a player
-- (turns to them, perks its ears through RigAnimator.Perk, hops, a "!" bubble, a heart for a species the player has caught), and from
-- Rare does its flourish the first time a player comes close. The tier sets how theatrical it is.
-- Catch: the bar's hit and Perfect moments flash in the alien's colour; a catch throws a cell burst and the alien spirals into the
-- player's device (Legendary and up add a camera nudge and a shockwave, Cosmic and Secret a brief slow-mo); a flight is a puff and a
-- hop away (a Secret blinks out).
-- Budgets (Caps): counted by SpectacleMath.ArrivalCost and SceneCost and held in tests/Spectacle.spec.luau so a Cosmic arrival with
-- eight aliens around never passes the phone's particle and part caps (the research numbers of Blocky-Style section 7: 100 particles a
-- second an emitter, a burst under about 300 near the camera). Reduced Motion (Prefs) is the still version of everything: no flight,
-- descent, flicker, hop, spiral, nudge or slow-mo; the beacon and the pool hold steady, a bubble shows without a pop.
-- Lengths are heights of the alien where the field says so, else studs; times are seconds; colours come from the species' accent
-- (EffectsMath.Accent), so no hex lives here but the glyph inks and the footprint motifs.

export type ArrivalKind = "None" | "Pop" | "Burst" | "Star" | "Beam" | "Glitch"
export type Arrival = {
	kind: ArrivalKind,
	seconds: number, -- from the first frame to the alien fully there
	cells: number, -- block cells (parts) the arrival flies: the portal, the burst, the bloom ring, the shockwave, the assembly
	cellStuds: number, -- the side of one cell
	particles: number, -- one firing of cell particles at the moment it lands
	reach: number, -- heights: how far the cells fly, the ring's radius, how far the assembly's cells start
	lightPulse: number, -- the brightness of the flash at the landing (0: none)
	fall: number, -- studs: the star's fall, or the Cosmic's descent in its beam (0: none)
	skyDim: number, -- how far the screen's brightness dips while it lands (a ColorCorrection, 0: none)
	vignette: boolean, -- the Secret's screen-edge flicker
	beacon: number, -- seconds the beacon stands after the arrival; -1 while the alien stays; 0 none
	beaconReach: number, -- studs the beacon stands up
	beaconWidth: number, -- studs across
}

export type ShimmerKind = "None" | "StarField" | "Haze"
export type Presence = {
	pool: number, -- the light pool's radius in heights (0: none)
	ornaments: number, -- glyph cells orbiting the head
	ornamentRadius: number, -- heights
	ornamentPeriod: number, -- seconds a turn
	footprints: boolean, -- a bloom where it steps
	aura: number, -- soft aura sprites a second (0: none; Cosmic and Secret wear data/Effects' aura)
	trail: number, -- cells a second dropped while it moves (0: none)
	shimmer: ShimmerKind,
	shimmerRate: number, -- particles a second
	ambient: boolean, -- plays Sounds.TierAmbient[tier] near it (a hook: silent while the id is 0)
}

export type IdleKind = "Look" | "Stretch" | "Sit" | "Sleep" | "Play"
export type Personality = {
	notice: number, -- studs: a player this near is noticed
	turn: number, -- 0 to 1: how far it turns to face them
	hop: number, -- studs: the notice hop
	hops: number, -- how many hops
	perk: number, -- degrees its ears, antennae, crest and tail flare when it notices (RigAnimator.Perk)
	bubble: boolean, -- the "!" or heart bubble
	approachFlourish: boolean, -- its flourish the first time a player comes within `approach`
	approach: number, -- studs
	wander: number, -- studs of leash round where the server placed it
	cycle: number, -- seconds of one wander-and-idle cycle
	theatre: number, -- a multiplier on every idle amplitude (Look, Stretch, Sit, Play)
	idles: { [IdleKind]: number }, -- weights of the idle each cycle plays (Sleep only at night)
}

export type EscapeKind = "PuffHop" | "BlinkOut"
export type CatchLook = {
	flashes: number, -- times the bar's zone flashes in the alien's colour on a Good; a Perfect adds one
	cells: number, -- particles in the cell burst where it is caught
	spiral: number, -- seconds it spirals into the player's device
	turns: number, -- turns of the spiral
	nudge: number, -- studs of camera nudge (0: none)
	nudgeSeconds: number,
	shockwave: number, -- cells in the ground shockwave (0: none)
	slowmo: number, -- seconds of the slow-mo moment (0: none)
	escape: EscapeKind,
	escapeHops: number, -- hops away from the player
}

local arrivals: { [string]: Arrival } = {
	Common = { kind = "None", seconds = 0, cells = 0, cellStuds = 0, particles = 0, reach = 0, lightPulse = 0, fall = 0, skyDim = 0, vignette = false, beacon = 0, beaconReach = 0, beaconWidth = 0 },
	Uncommon = { kind = "None", seconds = 0, cells = 0, cellStuds = 0, particles = 0, reach = 0, lightPulse = 0, fall = 0, skyDim = 0, vignette = false, beacon = 0, beaconReach = 0, beaconWidth = 0 },
	-- a square portal of cells opens at its body, it pops through, the portal snaps shut
	Rare = { kind = "Pop", seconds = 0.7, cells = 12, cellStuds = 0.25, particles = 10, reach = 0.7, lightPulse = 0, fall = 0, skyDim = 0, vignette = false, beacon = 0, beaconReach = 0, beaconWidth = 0 },
	-- cells burst out of it and a light pulses once; a beacon for the first 20 s
	Epic = { kind = "Burst", seconds = 0.8, cells = 16, cellStuds = 0.25, particles = 20, reach = 1.6, lightPulse = 3, fall = 0, skyDim = 0, vignette = false, beacon = 20, beaconReach = 40, beaconWidth = 0.4 },
	-- a star falls from the sky trailing light, lands, and a ring of cells blooms out across the ground; a beacon while it stays
	Legendary = { kind = "Star", seconds = 1.6, cells = 20, cellStuds = 0.3, particles = 24, reach = 2.6, lightPulse = 4, fall = 60, skyDim = 0, vignette = false, beacon = -1, beaconReach = 70, beaconWidth = 0.6 },
	-- the sky dims a touch, a beam comes down, the alien descends in it, a shockwave of cells rolls out (plus SpeciesFx's spawn moment)
	Cosmic = { kind = "Beam", seconds = 2.6, cells = 24, cellStuds = 0.3, particles = 30, reach = 3.6, lightPulse = 5, fall = 12, skyDim = 0.12, vignette = false, beacon = -1, beaconReach = 110, beaconWidth = 0.9 },
	-- the screen's edge flickers, the alien assembles from cells drawn in from around it (plus SpeciesFx's spawn moment, in shadow)
	Secret = { kind = "Glitch", seconds = 1.8, cells = 24, cellStuds = 0.25, particles = 16, reach = 1.4, lightPulse = 2, fall = 0, skyDim = 0.06, vignette = true, beacon = -1, beaconReach = 90, beaconWidth = 0.6 },
}

local presence: { [string]: Presence } = {
	Common = { pool = 0, ornaments = 0, ornamentRadius = 0, ornamentPeriod = 0, footprints = false, aura = 0, trail = 0, shimmer = "None", shimmerRate = 0, ambient = false },
	Uncommon = { pool = 0, ornaments = 0, ornamentRadius = 0, ornamentPeriod = 0, footprints = false, aura = 0, trail = 0, shimmer = "None", shimmerRate = 0, ambient = false },
	Rare = { pool = 0.6, ornaments = 0, ornamentRadius = 0, ornamentPeriod = 0, footprints = false, aura = 0, trail = 0, shimmer = "None", shimmerRate = 0, ambient = true },
	Epic = { pool = 0.75, ornaments = 1, ornamentRadius = 0.45, ornamentPeriod = 4, footprints = false, aura = 0, trail = 0, shimmer = "None", shimmerRate = 0, ambient = true },
	Legendary = { pool = 0.9, ornaments = 2, ornamentRadius = 0.5, ornamentPeriod = 5, footprints = true, aura = 1.2, trail = 0, shimmer = "None", shimmerRate = 0, ambient = true },
	Cosmic = { pool = 1.1, ornaments = 3, ornamentRadius = 0.55, ornamentPeriod = 6, footprints = true, aura = 0, trail = 8, shimmer = "StarField", shimmerRate = 6, ambient = true },
	Secret = { pool = 1, ornaments = 3, ornamentRadius = 0.55, ornamentPeriod = 7, footprints = true, aura = 0, trail = 8, shimmer = "Haze", shimmerRate = 5, ambient = true },
}

-- Idle weights: a Common mostly looks round and sits; the rarer it is, the more it plays (a spin and a skip).
local personality: { [string]: Personality } = {
	Common = { notice = 14, turn = 0.6, hop = 0.25, hops = 1, perk = 15, bubble = true, approachFlourish = false, approach = 0, wander = 1.5, cycle = 7, theatre = 0.7, idles = { Look = 4, Stretch = 2, Sit = 3, Sleep = 3, Play = 0 } },
	Uncommon = { notice = 15, turn = 0.7, hop = 0.3, hops = 1, perk = 18, bubble = true, approachFlourish = false, approach = 0, wander = 1.75, cycle = 7, theatre = 0.8, idles = { Look = 4, Stretch = 2, Sit = 3, Sleep = 3, Play = 1 } },
	Rare = { notice = 16, turn = 0.8, hop = 0.35, hops = 1, perk = 22, bubble = true, approachFlourish = true, approach = 12, wander = 2, cycle = 8, theatre = 1, idles = { Look = 3, Stretch = 2, Sit = 2, Sleep = 3, Play = 2 } },
	Epic = { notice = 18, turn = 0.9, hop = 0.4, hops = 2, perk = 25, bubble = true, approachFlourish = true, approach = 14, wander = 2, cycle = 8, theatre = 1.15, idles = { Look = 3, Stretch = 2, Sit = 2, Sleep = 3, Play = 3 } },
	Legendary = { notice = 20, turn = 1, hop = 0.45, hops = 2, perk = 28, bubble = true, approachFlourish = true, approach = 16, wander = 2.25, cycle = 9, theatre = 1.3, idles = { Look = 2, Stretch = 2, Sit = 2, Sleep = 3, Play = 4 } },
	Cosmic = { notice = 22, turn = 1, hop = 0.5, hops = 3, perk = 30, bubble = true, approachFlourish = true, approach = 18, wander = 2.5, cycle = 9, theatre = 1.45, idles = { Look = 2, Stretch = 2, Sit = 1, Sleep = 3, Play = 5 } },
	Secret = { notice = 22, turn = 1, hop = 0.5, hops = 3, perk = 30, bubble = true, approachFlourish = true, approach = 18, wander = 2.5, cycle = 10, theatre = 1.45, idles = { Look = 2, Stretch = 2, Sit = 1, Sleep = 3, Play = 5 } },
}

local catches: { [string]: CatchLook } = {
	Common = { flashes = 1, cells = 8, spiral = 0.5, turns = 1, nudge = 0, nudgeSeconds = 0, shockwave = 0, slowmo = 0, escape = "PuffHop", escapeHops = 2 },
	Uncommon = { flashes = 1, cells = 10, spiral = 0.55, turns = 1, nudge = 0, nudgeSeconds = 0, shockwave = 0, slowmo = 0, escape = "PuffHop", escapeHops = 2 },
	Rare = { flashes = 2, cells = 14, spiral = 0.6, turns = 1.5, nudge = 0, nudgeSeconds = 0, shockwave = 0, slowmo = 0, escape = "PuffHop", escapeHops = 3 },
	Epic = { flashes = 2, cells = 18, spiral = 0.65, turns = 2, nudge = 0, nudgeSeconds = 0, shockwave = 0, slowmo = 0, escape = "PuffHop", escapeHops = 3 },
	Legendary = { flashes = 3, cells = 22, spiral = 0.75, turns = 2, nudge = 0.15, nudgeSeconds = 0.25, shockwave = 16, slowmo = 0, escape = "PuffHop", escapeHops = 3 },
	Cosmic = { flashes = 3, cells = 24, spiral = 0.85, turns = 2.5, nudge = 0.2, nudgeSeconds = 0.3, shockwave = 20, slowmo = 0.6, escape = "PuffHop", escapeHops = 3 },
	Secret = { flashes = 3, cells = 24, spiral = 0.85, turns = 2.5, nudge = 0.2, nudgeSeconds = 0.3, shockwave = 20, slowmo = 0.6, escape = "BlinkOut", escapeHops = 0 },
}

-- Budgets. ArrivalParticles and ArrivalParts are what one arrival may throw and build (its cells, its firing, its beacon, the
-- star, the beam, SpeciesFx's spawn moment) on a phone (Mobile) and a desktop. SceneParticles and SceneParts are the whole scene's
-- live budget the 30 fps target is held to on a phone: MaxActive aliens wearing their species effects at the per-alien budget
-- (data/Effects Caps), each with its presence, plus the arrivals that may play at once. MaxArrivals: arrivals playing at once.
-- MaxPresence (MaxPresenceMobile): the nearest aliens that wear their presence (the rest keep only the pool). MaxBeacons: beacons
-- standing at once (the nearest). MaxFootprints: footprint cells alive at once across every alien. ArrivalDistance: studs from the
-- camera an arrival plays within (beyond it the alien simply appears); a beacon is seen from the whole map. SlowMoMinScale: the
-- slowest a slow-mo runs the catch's own clocks (its particles' TimeScale, the spiral).
local caps = {
	MobileArrivalParticles = 160,
	DesktopArrivalParticles = 400,
	MobileArrivalParts = 40,
	DesktopArrivalParts = 80,
	MobileSceneParticles = 1300,
	MobileSceneParts = 140,
	MaxArrivals = 2,
	MaxArrivalsMobile = 1,
	MaxPresence = 12,
	MaxPresenceMobile = 8,
	MaxBeacons = 4,
	MaxBeaconsMobile = 2,
	MaxFootprints = 24,
	MaxFootprintsMobile = 12,
	ArrivalDistance = 220,
	SlowMoMinScale = 0.3,
}

-- How the pieces look and time. Bubble: seconds a bubble stays, studs across it, studs over the alien's head; HeartColor and
-- AlertColor ink it, the plate is white with the outline colour. Zz: one Z every ZzEvery seconds while it sleeps, rising ZzRise
-- studs over ZzSeconds. Pool: the light pool lies PoolLift studs over the ground at PoolTransparency, and breathes PoolBreathe of the
-- way to clear over PoolPeriod (held still under Reduced Motion). Ornament: OrnamentStuds a cell, bobbing OrnamentBob heights.
-- Footprint: one every FootprintStep studs of wandering, grows over FootprintGrow, holds, fades out by FootprintLife; FootprintStuds
-- a cell. Beacon: BeaconTransparency at its brightest, swelling by BeaconBreathe over BeaconPeriod; BeaconFade seconds in and out.
-- Notice: TurnRate (a share a second the turn closes), HopSeconds a hop, PerkSeconds the ears' perk, FlashPeriod seconds one flash of the bar takes (at
-- least a third of a second, so nothing flashes more than three times a second), ForgetSeconds out of range before it may notice the same
-- player again (and pop a bubble again). Wander: MoveShare of a cycle is walking, the rest is the idle; MaxStep studs of ground
-- height difference it will not wander across. Idle amplitudes (before theatre): LookYaw degrees, StretchPitch degrees and
-- StretchLift studs, SitPitch degrees, SleepRoll degrees, PlaySpin degrees and PlayHop studs. Catch: SpiralRadius heights at the
-- start, SpiralRise studs up to the device, SpiralEnd the share of its size it shrinks to; Shockwave grows to ShockwaveReach
-- heights over ShockwaveSeconds. Escape: EscapeHop studs high and EscapeStride studs away each hop, EscapeHopSeconds a hop,
-- BlinkFlickers times over BlinkSeconds, HoldSeconds the most a removed alien waits for its outcome before it simply fades.
-- Vignette: VignetteFlickers over the arrival, at VignetteTransparency at its darkest, VignetteDepth of the screen deep.
-- SkyRamp: seconds the sky's dip takes in and out. FovPunch: degrees the field of view narrows at a slow-mo.
local look = {
	BubbleSeconds = 1.6,
	BubbleStuds = 1.4,
	BubbleGap = 0.2, -- studs between the top of the alien's nameplate and the bubble's bottom: the bubble stands above the plate, never over its name
	HeartColor = "FF5C8A",
	AlertColor = "FFD43B",
	ZzColor = "DDE6FF",
	ZzEvery = 1.6,
	ZzRise = 2.2,
	ZzSeconds = 2.4,
	ZzStuds = 0.7,
	PoolLift = 0.06,
	PoolTransparency = 0.72,
	PoolBreathe = 0.12,
	PoolPeriod = 3.2,
	OrnamentStuds = 0.22,
	OrnamentBob = 0.08,
	FootprintStep = 0.9,
	FootprintGrow = 0.35,
	FootprintLife = 4,
	FootprintStuds = 0.18,
	BeaconTransparency = 0.35,
	BeaconBreathe = 0.25,
	BeaconPeriod = 2.4,
	BeaconFade = 0.8,
	TurnRate = 4,
	HopSeconds = 0.32,
	PerkSeconds = 0.6,
	FlashPeriod = 0.34,
	ForgetSeconds = 20,
	MoveShare = 0.35,
	MaxStep = 0.6,
	LookYaw = 35,
	StretchPitch = 10,
	StretchLift = 0.12,
	SitPitch = -8,
	SleepRoll = 9,
	PlaySpin = 360,
	PlayHop = 0.3,
	SpiralRadius = 0.6,
	SpiralRise = 2.5,
	SpiralEnd = 0.05,
	ShockwaveReach = 4,
	ShockwaveSeconds = 0.7,
	EscapeHop = 1.2,
	EscapeStride = 3,
	EscapeHopSeconds = 0.35,
	BlinkFlickers = 4,
	BlinkSeconds = 0.5,
	HoldSeconds = 2.5,
	VignetteFlickers = 3,
	VignetteTransparency = 0.35,
	VignetteDepth = 0.12,
	VignetteColor = "1A0B33",
	SkyRamp = 0.5,
	FovPunch = 6,
}

-- The footprint motif per world id (World 1 Verdant flowers, World 2 Frostbyte frost); a world not listed uses Default. Each is
-- the cells' colours, the first the centre.
local footprints: { [number]: { string } } = {
	[1] = { "FFE066", "FF8FC0", "FFB7D5" },
	[2] = { "E6F6FF", "BFE9FF", "9FD8FF" },
}
local footprintDefault: { string } = { "FFFFFF", "DDE6FF", "BFD4FF" }

-- The pixel glyphs a bubble or a Zz draws, row by row ("X" a cell, "." clear): block cells, like every icon (B44).
local glyphs: { [string]: { string } } = {
	Heart = { ".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..." },
	Alert = { "..XX..", "..XX..", "..XX..", "..XX..", "......", "..XX.." },
	Z = { "XXXXX", "...X.", "..X..", ".X...", "XXXXX" },
}

-- The moving parts (data/Rigs names) that perk up when an alien notices a player (RigAnimator.Perk): a part whose name starts
-- with one of these flares by the tier's `perk` degrees over Look.PerkSeconds, on the axis of its own first clip.
local perkParts: { string } = { "ear", "antenna", "crest", "tail", "whisker", "tuft", "fin", "leaf", "sprout", "frond" }

-- Particles one alien's presence keeps alive (for the budget): the aura's sprites, the trail's cells and the shimmer.
-- PresenceLifetime: seconds each of them lives.
local presenceLifetime = { aura = 1.6, trail = 0.9, shimmer = 1.8 }

return {
	Arrivals = arrivals,
	Presence = presence,
	Personality = personality,
	Catch = catches,
	Caps = caps,
	Look = look,
	Footprints = footprints,
	FootprintDefault = footprintDefault,
	Glyphs = glyphs,
	PerkParts = perkParts,
	PresenceLifetime = presenceLifetime,
}
