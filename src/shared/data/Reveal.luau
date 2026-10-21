--!strict
-- ReplicatedStorage.Shared.data.Reveal: every duration, count and size of the Reveal's three beats (UI/Reveal.luau), read by
-- the client and by Shared/RevealMath. The server has decided the outcome before the first tap, so nothing here is a
-- game result; it is only how long the show takes and how big it is. Spec: UI Playbook "The reveal in three beats".
--   Beat 1, Crack: an egg sits in the middle with a tap ring. CrackTaps taps crack it; each tap wobbles it, draws one
--     crack line (CrackLines), plays Sounds.CrackTick and lets the tier colour leak a little more from behind it
--     (GlowTransparency, from Start to End over the taps). AutoCrackSeconds without a tap cracks it on its own, and
--     Reduced Motion cracks it at once, so nobody is stuck. A wild catch has no egg in the flow today, so beat 1 is
--     skipped for it unless CatchCrack is true (then the caught alien's capsule is the same egg, cracked the same way).
--   Beat 2, Shards: the shell bursts into ShardCount pieces that fly out and fade (ShardSeconds), the rays spin up in the
--     tier colour (RaySpinSeconds; a static ring under Reduced Motion), the tier word drops in big in the tier colour,
--     the tier's stinger plays and the stage pushes in (PushInScale). A tier's flags (Tiers below, one row per tier of
--     data/Tiers Order) say what it adds: Rays, SecondRayColor (Cosmic), Grand (Legendary and up: the whole beat is
--     LegendaryShardScale times as long and the shards and confetti that much bigger, and GroundRing puts the gold ring
--     under the model), Iris and DimExtra (Secret: the screen dims further and a dark iris opens instead of rays). Skip: a
--     tap during the shards jumps to the card.
--   Beat 3, the card: the card drops in (CardDropSeconds), then the odds line, the size and multiplier chips and the two
--     buttons arrive in turn inside HoldSeconds (the delays and the slide below must fit in it). "Tap anywhere to
--     continue" closes once they are up; an earlier tap finishes the entrance instead.
-- The Rare total (RevealMath.Total: crack + shards + rays + card drop + hold) must land between TotalMinSeconds and
-- TotalMaxSeconds (tools/lint_data.py). QuietSeconds is the calm kept after the last beat, on top of the total, so a toast
-- does not land on the card as it settles; Toast.QuietFor takes the sum. Sizes are fractions of the screen unless a name
-- says Px (px at ReferenceHeight, the 667x375 iPhone SE the fit pass measures against, turned into a Scale of the height by
-- RevealMath.PxToScale). Colours are never typed here: a tier flag names a Theme.Colors key, GroundRingRarity a Theme.Rarity one.

export type TierFlags = {
	Rays: boolean, -- the ring of rays (and the Shine sprite once uploaded) turns up in the tier colour
	SecondRayColor: string?, -- a Theme.Colors key: every other ray wears it (Cosmic)
	Grand: boolean, -- Legendary and above: the shard beat is LegendaryShardScale times as long and as big
	GroundRing: boolean, -- the gold ring under the model on the card (needs Grand)
	Iris: boolean, -- a dark iris opens behind the card instead of rays (needs Rays false)
	DimExtra: number, -- how much further the screen dims for the beat, 0 to under 1
	Word: boolean, -- the tier word drops in big in the shards beat
	WordAccent: string?, -- a Theme.Colors key the word wears where the tier colour would vanish on the dim (Secret is near black)
	Confetti: boolean, -- confetti with the burst (Epic and above)
}

-- The ladder (Roster-Redesign section 1, "Catch and reveal"): Common and Uncommon have no rays, Rare turns them slowly,
-- Epic adds the confetti, Legendary the gold ring and the long beat, Cosmic a second ray colour, Secret the dark iris.
local Tiers: { [string]: TierFlags } = {
	Common = { Rays = false, Grand = false, GroundRing = false, Iris = false, DimExtra = 0, Word = true, Confetti = false },
	Uncommon = { Rays = false, Grand = false, GroundRing = false, Iris = false, DimExtra = 0, Word = true, Confetti = false },
	Rare = { Rays = true, Grand = false, GroundRing = false, Iris = false, DimExtra = 0, Word = true, Confetti = false },
	Epic = { Rays = true, Grand = false, GroundRing = false, Iris = false, DimExtra = 0, Word = true, Confetti = true },
	Legendary = { Rays = true, Grand = true, GroundRing = true, Iris = false, DimExtra = 0, Word = true, Confetti = true },
	Cosmic = { Rays = true, SecondRayColor = "Select", Grand = true, GroundRing = true, Iris = false, DimExtra = 0, Word = true, Confetti = true },
	Secret = { Rays = false, Grand = true, GroundRing = true, Iris = true, DimExtra = 0.25, Word = true, WordAccent = "Codex", Confetti = true },
}

-- The intensity ladder (Decisions B46: "rarer aliens should look a lot more exclusive and cooler/cuter", and the climb is steep):
-- what each tier adds at the hero beat, the moment the card lands and the alien is first seen. Everything is block cells
-- (UI Playbook "The reveal in block cells"): square cells and stepped pixel shapes, no gradient, no round glow.
--   Common: a pop and one burst of sparkle cells. Rare: a pixel starburst behind the card, the ray ring a short fan of cells.
--   Epic: a fuller cell-ray fan and a colour wash. Legendary: a gold cell frame chasing round the card, a slower grander turn of
--   the model, more confetti cells, a longer hold. Cosmic and Secret: a full-screen pixel sky moment (stepped bands and star
--   cells) from the shard beat on, the longest hold, and the species name spelled in, a cell then a letter at a time.
-- tools/lint_data.py keeps every column climbing (never less from one tier to the next) and RevealMath.EffectFrames counts
-- what a tier draws (tests/RevealMath.spec.luau holds the Cosmic reveal under its frame budget).
export type LadderRow = {
	Pop: number, -- the card's landing pop, to this scale and back (a size band's own revealPop wins when it is bigger)
	Sparkles: number, -- sparkle cells thrown from behind the card at the hero beat, per burst
	SparkleBursts: number, -- how many bursts, SparkleGapSeconds apart
	Starburst: number, -- arms of the pixel starburst behind the card at the hero beat (0: none)
	RayCells: number, -- cells in each ray of the ray ring (0 for a tier without Rays in Tiers above)
	Wash: number, -- the colour wash's peak see-through at the hero beat (1: no wash)
	GoldFrame: boolean, -- a ring of gold cells round the card, a lit cell chasing round it
	TurnScale: number, -- the model's turn in the card, times its usual speed (under 1: slower, grander)
	Sky: boolean, -- the full-screen pixel sky moment
	HoldExtra: number, -- seconds added to the card's hold before the buttons slide up
	SpellName: boolean, -- the species name spelled in, a cell running ahead of the letters
}

local Ladder: { [string]: LadderRow } = {
	Common = { Pop = 1.06, Sparkles = 6, SparkleBursts = 1, Starburst = 0, RayCells = 0, Wash = 1, GoldFrame = false, TurnScale = 1, Sky = false, HoldExtra = 0, SpellName = false },
	Uncommon = { Pop = 1.08, Sparkles = 8, SparkleBursts = 1, Starburst = 0, RayCells = 0, Wash = 1, GoldFrame = false, TurnScale = 1, Sky = false, HoldExtra = 0, SpellName = false },
	Rare = { Pop = 1.1, Sparkles = 10, SparkleBursts = 1, Starburst = 8, RayCells = 3, Wash = 1, GoldFrame = false, TurnScale = 1, Sky = false, HoldExtra = 0, SpellName = false },
	Epic = { Pop = 1.12, Sparkles = 12, SparkleBursts = 2, Starburst = 8, RayCells = 4, Wash = 0.7, GoldFrame = false, TurnScale = 1, Sky = false, HoldExtra = 0, SpellName = false },
	Legendary = { Pop = 1.15, Sparkles = 14, SparkleBursts = 2, Starburst = 12, RayCells = 5, Wash = 0.65, GoldFrame = true, TurnScale = 0.5, Sky = false, HoldExtra = 0.3, SpellName = false },
	Cosmic = { Pop = 1.18, Sparkles = 16, SparkleBursts = 3, Starburst = 16, RayCells = 6, Wash = 0.6, GoldFrame = true, TurnScale = 0.4, Sky = true, HoldExtra = 0.8, SpellName = true },
	-- Secret has no rays (its dark iris opens instead), so no ray cells; everything else is the top rung.
	Secret = { Pop = 1.18, Sparkles = 16, SparkleBursts = 3, Starburst = 16, RayCells = 0, Wash = 0.6, GoldFrame = true, TurnScale = 0.4, Sky = true, HoldExtra = 1, SpellName = true },
}

-- One crack line per tap, a zig-zag of thin rotated bars drawn on the egg. Each bar is { x, y, length, degrees }: its
-- centre as a fraction of the egg's width and height, its length in egg heights, its tilt. A fourth tap would reuse the first.
local CrackLines: { { { number } } } = {
	{ { 0.42, 0.18, 0.12, 115 }, { 0.48, 0.28, 0.12, 65 }, { 0.44, 0.38, 0.12, 115 } },
	{ { 0.58, 0.46, 0.14, 20 }, { 0.68, 0.52, 0.12, -30 }, { 0.78, 0.50, 0.10, 20 } },
	{ { 0.30, 0.58, 0.12, -25 }, { 0.40, 0.66, 0.12, 35 }, { 0.52, 0.72, 0.14, -20 } },
}

-- The egg's speckles: { x, y, diameter } as fractions of the egg's width, width and height.
local Speckles: { { number } } = {
	{ 0.30, 0.30, 0.10 },
	{ 0.66, 0.24, 0.07 },
	{ 0.74, 0.62, 0.11 },
	{ 0.36, 0.78, 0.08 },
	{ 0.56, 0.52, 0.06 },
}

-- The pixel egg (UI Playbook "The reveal in block cells"): its colour, row by row, on a grid of EggCols by EggRows square pixels
-- (EggAspect wide per tall, so the pixels are square), as { row, left, width } (0-based). The ink is the colour grown by one
-- pixel all round (RevealMath.EggBars), so it keeps one thickness round every step; narrow at the top, widest below the middle.
local EggSpans: { { number } } = {
	{ 1, 6, 4 },
	{ 2, 5, 6 },
	{ 3, 4, 8 },
	{ 4, 3, 10 },
	{ 5, 3, 10 },
	{ 6, 2, 12 },
	{ 7, 2, 12 },
	{ 8, 2, 12 },
	{ 9, 1, 14 },
	{ 10, 1, 14 },
	{ 11, 1, 14 },
	{ 12, 1, 14 },
	{ 13, 1, 14 },
	{ 14, 1, 14 },
	{ 15, 2, 12 },
	{ 16, 2, 12 },
	{ 17, 3, 10 },
	{ 18, 5, 6 },
}

return {
	-- Timing (seconds)
	CrackTaps = 3, -- taps that crack the egg
	CrackSecondsPerTap = 0.25, -- one tap's wobble; also the pace of the taps that play themselves
	AutoCrackSeconds = 4, -- without a tap this long, the rest of the taps play themselves
	ShardSeconds = 0.4, -- the shell bursts and the shards fly out and fade
	RaySpinSeconds = 0.6, -- the rays spin up and the word drops in; only a tier with Rays or an Iris spends it
	CardDropSeconds = 0.35, -- the card drops in from CardDropDistance above its place
	HoldSeconds = 0.8, -- the card's entrance: the odds line, the chips and the buttons arrive inside it
	QuietSeconds = 2, -- calm kept after the last beat, so toasts do not land on the card as it settles
	LegendaryShardScale = 1.8, -- a Grand tier's shard beat: times as long, shards and confetti times as big
	Skip = true, -- a tap during the shards jumps to the card
	SkipGuardSeconds = 0.2, -- ignore a tap this soon after a beat starts (the tap that cracked the egg must not also skip)
	ReducedMotionSeconds = 0.6, -- Reduced Motion: one still frame (static ring and word) this long, then the whole card at once
	CatchCrack = false, -- true: a wild catch cracks a capsule (beat 1) like an egg; false: it starts at the shards
	TotalMinSeconds = 2.5, -- the Rare total's band, checked by tools/lint_data.py
	TotalMaxSeconds = 4,

	-- Beat 3's stagger, from the moment the card lands (all inside HoldSeconds)
	OddsDelaySeconds = 0.1,
	ChipDelaySeconds = 0.25,
	ButtonDelaySeconds = 0.45,
	ButtonSlideSeconds = 0.3,
	WordDropSeconds = 0.3, -- the tier word drops in (inside the ray spin)
	WordFadeSeconds = 0.15, -- and fades as the card drops

	-- Beat 1's feel
	WobbleStartDegrees = 4, -- the first tap's wobble
	WobbleEndDegrees = 10, -- the last tap's wobble
	TapPulseScale = 1.06, -- each tap squeezes the egg to this scale and back
	GlowTransparencyStart = 0.92, -- the tier colour behind the egg before any tap
	GlowTransparencyEnd = 0.55, -- and after the last tap
	GlowBurstTransparency = 0.35, -- the flash behind the burst
	GlowHeight = 0.62, -- the glow's diameter, of the screen height
	GlowCoreScale = 0.7, -- its bright centre, of that diameter (the outer disc is the soft edge)
	GlowSoftness = 0.55, -- how far from the centre's transparency toward clear the outer disc sits
	DotEmptyTransparency = 0.35, -- a tap dot before its tap (filled, it is solid gold)
	PopScale = 1.2, -- the pop of a dot, the prompt and the chance pill as they appear
	TapRingHeight = 0.6, -- the tap ring's diameter, of the screen height
	TapRingPulse = 1.07, -- the tap ring breathes to this scale and back
	TapRingPulseSeconds = 0.7,

	-- Beat 2's feel
	ShardCount = 6,
	ShardDistance = 0.3, -- how far a shard flies, of the screen height
	ShardHeight = 0.09, -- a shard's height, of the screen height
	ShardAspect = 0.5, -- a shard's width over its height
	ShardSpinDegrees = 240,
	RayCount = 8, -- thin bars through the middle: twice as many rays
	RayTransparency = 0.55, -- the rays at rest (the old burst was 0.85)
	RaySpinUpDegrees = 120, -- the turn the rays make while they spin up, before the slow turn takes over
	ConfettiCount = 20,
	PushInScale = 1.06, -- the stage pushes in to this scale over the beat (not under Reduced Motion)
	IrisHeight = 1.05, -- the Secret iris's diameter, of the screen height
	IrisTransparency = 0.1,
	RingWidth = 0.62, -- the gold ground ring under the model: width, of the card
	RingHeight = 0.07, -- and height, of the card
	RingY = 0.6, -- and its centre, of the card's height
	GroundRingRarity = "Legendary", -- the Theme.Rarity key the ring wears (the tier gold)

	-- Layout. Px values are at ReferenceHeight and become a Scale of the height
	ReferenceHeight = 375,
	CardDropDistance = 0.6, -- of the screen height
	StageY = 0.47, -- the egg's, the word's and the card's centre, of the screen height
	EggHeight = 0.5,
	EggAspect = 0.8, -- width over height
	EggCols = 16, -- the pixel egg's grid (EggCols / EggRows is EggAspect, so its pixels are square)
	EggRows = 20,
	EggLitRows = 2, -- its top rows of colour wear the lit overlay, its bottom rows the shade (Blocky-Style C3)
	EggShadeRows = 4,
	CrackThickness = 0.022, -- a crack bar's thickness, in egg heights
	PromptPx = 30, -- "Tap to crack it!": its line is this tall at the reference height, and grows with a bigger screen up to PromptMaxPx
	PromptMaxPx = 48,
	PromptY = 0.84,
	PromptWidth = 0.7,
	DotHeight = 0.045, -- the three progress dots (17 px at the reference height)
	DotY = 0.925,
	DotGap = 0.8, -- between two dots, in dot widths
	WordPx = 64, -- the tier word's line, as above, up to WordMaxPx
	WordMaxPx = 96,
	WordWidth = 0.9,
	ButtonHeightPx = 52,
	ButtonWidth = 0.24, -- of the screen width (160 px at 667x375; the footer takes the 0.46 between the buttons)
	ButtonMargin = 0.03, -- from the screen edge
	ButtonBottom = 0.985,
	FooterY = 0.95, -- "Tap anywhere to continue": between the buttons, two lines tall for a portrait phone
	FooterWidth = 0.46,
	FooterHeight = 0.08,
	ButtonSlideDistance = 0.3, -- the buttons start this far below their place, of the screen height
	ButtonRows = 5, -- the buttons' face rows (block buttons in cells: 7.5 px cells at the reference height)
	CardCell = 0.04, -- the card's cell, of the screen height (the panel cell: 13 rows on the 0.56 card)
	OddsRows = 3, -- the chance plate's rows (a flat block hanging on the card's bottom edge)

	-- The hero beat (the Ladder above). Sizes are of the screen height unless they say otherwise.
	SparkleSize = 0.022, -- a sparkle cell
	SparkleDistance = 0.3, -- how far a sparkle flies from the card's centre
	SparkleSeconds = 0.7, -- a sparkle's flight and fade
	SparkleGapSeconds = 0.25, -- between two bursts
	StarburstLength = 0.46, -- an arm's reach from the card's centre
	StarburstCells = 4, -- cells along an arm, growing outward
	StarburstSeconds = 0.6, -- the starburst grows out and fades
	RayCellGap = 0.35, -- the gap after a ray cell, in cells
	RayCellStart = 0.18, -- where a ray's first cell sits, as a share of the ring's radius
	WashPeakSeconds = 0.08, -- the colour wash flashes up
	WashSeconds = 0.5, -- and fades
	GoldFrameCells = 32, -- gold cells round the card
	GoldFrameCellSize = 0.028, -- a gold cell
	GoldFrameGap = 0.02, -- how far the frame sits outside the card, of the card's height
	GoldFrameStepSeconds = 0.06, -- the lit cell chases one cell on each step
	GoldFrameLitAlpha = 0, -- the lit cell's see-through
	GoldFrameDimAlpha = 0.45, -- every other cell's
	SkyBands = 8, -- stepped bands from the tier colour (top) to the night (bottom)
	SkyStars = 20, -- star cells scattered over the sky
	SkyStarSize = 0.018,
	SkyInSeconds = 0.45, -- the bands step in from the top over this
	SkyAlpha = 0.25, -- a band's see-through at rest (the sky never hides the card or the buttons)
	SkyTwinkleSeconds = 0.9, -- a star's twinkle, out and back
	SpellSecondsPerLetter = 0.05, -- the name spelled in, a letter a step
	SpellCursor = 0.7, -- the cell running ahead of the letters, of the name line's height
	OddsWidth = 1.5, -- the odds pill hangs on the card's bottom edge: width, of the card
	OddsHeight = 0.1, -- height, of the card
	OddsY = 1,

	CrackLines = CrackLines,
	Ladder = Ladder,
	EggSpans = EggSpans,
	Speckles = Speckles,
	Tiers = Tiers,
}
