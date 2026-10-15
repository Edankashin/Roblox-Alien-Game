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
	OddsWidth = 1.5, -- the odds pill hangs on the card's bottom edge: width, of the card
	OddsHeight = 0.1, -- height, of the card
	OddsY = 1,

	CrackLines = CrackLines,
	Speckles = Speckles,
	Tiers = Tiers,
}
