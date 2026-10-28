--!strict
-- Cinematic camera moments (milestone 47; PRE_PRODUCTION 5c item 1; the reference is media/tiktok/NOTES.md batch 5,
-- ZPLYS56X5: one unbroken move built from classic shots, never a series of cuts). CameraDirector.PlayShots(momentId)
-- plays a moment: the camera is Scriptable, letterbox bars slide in, and each shot after the first is a segment that
-- tweens the camera's CFrame and FieldOfView from where the previous shot left it to this shot's view over `seconds`
-- with `easing`, while a depth-of-field blur follows `blur` (0 none .. 1 full). The FIRST shot is the opening frame:
-- the camera is placed there at once (a shot with the rule "current" starts from where the camera stands) and its
-- `seconds` is how long the camera rests there (0 for none); every later shot needs seconds > 0.
-- A shot names its view two ways. `anchor` is the name of a Part in the place's camera rig, a folder called RigFolder
-- inside one of the RigParents under Workspace (Workspace.World.CameraRig, or Workspace.Dressing.CameraRig, which is
-- where a hand-made rig lives because Workspace.World is built by the server at runtime); the Part's CFrame IS the
-- camera, and docs/vault/06-art-pipelines/Map-Dressing.md says how to place one. `fallback` is the rule used when the
-- anchor Part is missing (or the shot has no anchor), computed from the world's layout data, so every place works
-- today with no anchors placed at all (Shared/CinematicMath.Fallback):
--   orbitCamp        radius, height, angle (degrees, 0 on +X, 90 on +Z), lookHeight: a ring around the camp, looking at
--                    the camp (lookHeight studs above its ground)
--   overBiome        biome, height, lookHeight: straight above that biome's centre in the layout, looking at the camp
--   behindCharacter  back, height: the third-person seat, `back` studs behind the character and `height` above it
--   towardTarget     distance, height, lookHeight: `distance` studs from the moment's target on the side the camera
--                    already stands, `height` above it, looking at the target (the Legendary push-in)
--   current          the camera exactly where it stands now
-- `fov` is the vertical field of view in degrees (omitted: the camera's own at the start, so the hand-back is seamless).
-- Easing is a Quad or Sine curve in the In, Out or InOut direction. Moments: Arrival_<worldId> is the first arrival in
-- that world's place (12 to 16 seconds on a wild world, shorter at home), played once per profile per world (the
-- SeenKeys below are the only keys the MarkSeen remote accepts); Legendary is the push-in before a Legendary or higher
-- catch bar. A moment's flags: letterbox (the bars), skippable (a Skip button appears after SkipAfterSeconds and cuts to
-- the end), skipOnReducedMotion (nothing plays at all under reduced motion; otherwise ReducedMotionCut decides: cut
-- straight to the last shot's view for ReducedMotionHoldSeconds, then hand back), stinger (a Sounds path the music
-- director plays at the start, silent until its id lands). Every number here.

export type Rule = {
	kind: "orbitCamp" | "overBiome" | "behindCharacter" | "towardTarget" | "current",
	radius: number?,
	height: number?,
	angle: number?,
	lookHeight: number?,
	biome: string?,
	back: number?,
	distance: number?,
}
export type Easing = "QuadInOut" | "QuadIn" | "QuadOut" | "SineInOut" | "SineIn" | "SineOut"
export type Shot = {
	anchor: string?,
	fallback: Rule,
	seconds: number,
	easing: Easing,
	fov: number?,
	blur: number,
}
export type Moment = {
	letterbox: boolean,
	skippable: boolean,
	skipOnReducedMotion: boolean,
	stinger: string?,
	shots: { Shot },
}

-- World 1 (Verdant Reach), 15.2 seconds: the far side of the world over the Forest, a low fast fly-in with blur, a rise as
-- the blur clears, a crane over the camp, the establishing pull-out that shows the whole floor as one island, then down
-- to the seat behind the character.
local Arrival1: { Shot } = {
	{ anchor = "Arrival_1_Open", fallback = { kind = "overBiome", biome = "Forest", height = 30, lookHeight = 6 }, seconds = 0.8, easing = "SineInOut", fov = 70, blur = 0 },
	{ anchor = "Arrival_1_Fly", fallback = { kind = "orbitCamp", radius = 60, height = 4, angle = 40, lookHeight = 6 }, seconds = 3, easing = "QuadIn", fov = 82, blur = 0.85 },
	{ anchor = "Arrival_1_Rise", fallback = { kind = "orbitCamp", radius = 36, height = 14, angle = 320, lookHeight = 4 }, seconds = 2.2, easing = "QuadOut", fov = 72, blur = 0.1 },
	{ anchor = "Arrival_1_Crane", fallback = { kind = "orbitCamp", radius = 34, height = 58, angle = 250, lookHeight = 0 }, seconds = 2.6, easing = "SineInOut", fov = 62, blur = 0 },
	{ anchor = "Arrival_1_Pull", fallback = { kind = "orbitCamp", radius = 225, height = 205, angle = 200, lookHeight = 0 }, seconds = 3.8, easing = "SineInOut", fov = 55, blur = 0 },
	{ fallback = { kind = "behindCharacter", back = 12, height = 6 }, seconds = 2.8, easing = "SineInOut", blur = 0 },
}

-- World 2 (Frostbyte), 15.2 seconds: the same five moves, opening over the Geyser Field and sweeping the other way round.
local Arrival2: { Shot } = {
	{ anchor = "Arrival_2_Open", fallback = { kind = "overBiome", biome = "GeyserField", height = 30, lookHeight = 6 }, seconds = 0.8, easing = "SineInOut", fov = 70, blur = 0 },
	{ anchor = "Arrival_2_Fly", fallback = { kind = "orbitCamp", radius = 60, height = 4, angle = 40, lookHeight = 6 }, seconds = 3, easing = "QuadIn", fov = 82, blur = 0.85 },
	{ anchor = "Arrival_2_Rise", fallback = { kind = "orbitCamp", radius = 36, height = 14, angle = 80, lookHeight = 4 }, seconds = 2.2, easing = "QuadOut", fov = 72, blur = 0.1 },
	{ anchor = "Arrival_2_Crane", fallback = { kind = "orbitCamp", radius = 34, height = 58, angle = 150, lookHeight = 0 }, seconds = 2.6, easing = "SineInOut", fov = 62, blur = 0 },
	{ anchor = "Arrival_2_Pull", fallback = { kind = "orbitCamp", radius = 225, height = 205, angle = 200, lookHeight = 0 }, seconds = 3.8, easing = "SineInOut", fov = 55, blur = 0 },
	{ fallback = { kind = "behindCharacter", back = 12, height = 6 }, seconds = 2.8, easing = "SineInOut", blur = 0 },
}

-- The home planet, 8 seconds: a small plot, so one sweep past the hangar and a short pull-out, then the seat.
local Arrival0: { Shot } = {
	{ anchor = "Arrival_0_Open", fallback = { kind = "orbitCamp", radius = 110, height = 40, angle = 90, lookHeight = 4 }, seconds = 0.6, easing = "SineInOut", fov = 62, blur = 0 },
	{ anchor = "Arrival_0_Sweep", fallback = { kind = "orbitCamp", radius = 45, height = 14, angle = 140, lookHeight = 4 }, seconds = 3, easing = "SineInOut", fov = 72, blur = 0.35 },
	{ anchor = "Arrival_0_Pull", fallback = { kind = "orbitCamp", radius = 120, height = 90, angle = 200, lookHeight = 0 }, seconds = 2.6, easing = "SineInOut", fov = 55, blur = 0 },
	{ fallback = { kind = "behindCharacter", back = 12, height = 6 }, seconds = 1.8, easing = "SineInOut", blur = 0 },
}

-- A slow push-in toward the alien before the catch bar: from where the camera stands to 9 studs from the alien, no
-- blur and the field of view untouched. The rumble (Config.LegendaryRumbleSeconds) runs on the pushed-in view after it.
local Legendary: { Shot } = {
	{ fallback = { kind = "current" }, seconds = 0, easing = "SineInOut", blur = 0 },
	{ fallback = { kind = "towardTarget", distance = 9, height = 3.5, lookHeight = 1 }, seconds = 1.2, easing = "SineInOut", blur = 0 },
}

local Moments: { [string]: Moment } = {
	Arrival_0 = { letterbox = true, skippable = true, skipOnReducedMotion = false, stinger = "Arrival", shots = Arrival0 },
	Arrival_1 = { letterbox = true, skippable = true, skipOnReducedMotion = false, stinger = "Arrival", shots = Arrival1 },
	Arrival_2 = { letterbox = true, skippable = true, skipOnReducedMotion = false, stinger = "Arrival", shots = Arrival2 },
	Legendary = { letterbox = false, skippable = false, skipOnReducedMotion = true, shots = Legendary },
}

return {
	Moments = Moments,
	Letterbox = { barHeight = 0.1, fadeSeconds = 0.4 }, -- each bar's height as a fraction of the screen, and the seconds they take to slide in and out
	SkipAfterSeconds = 1, -- the Skip button appears this long after a skippable moment starts
	ReducedMotionCut = true, -- reduced motion: cut to the last shot's view for ReducedMotionHoldSeconds instead of flying
	ReducedMotionHoldSeconds = 0.6,
	-- The depth-of-field effect a moment owns while it runs: blur 1 is NearFactor and FarFactor times full intensity,
	-- focused FocusDistance studs out with InFocusRadius studs sharp around that (near objects blur most on a fast shot).
	DepthOfField = { FocusDistance = 55, InFocusRadius = 20, NearFactor = 1, FarFactor = 0.4 },
	-- Where hand-placed camera anchors live: Workspace.<one of RigParents>.<RigFolder>.<anchor name>, first found wins.
	RigFolder = "CameraRig",
	RigParents = { "World", "Dressing" },
	ArrivalPrefix = "Arrival_", -- a world's arrival moment (and its seen key) is this followed by the world id
	ArrivalSeconds = { min = 12, max = 16 }, -- a wild world's arrival runs between these; the home's is shorter than min
	LegendaryBudgetSeconds = 2.5, -- the push-in plus the rumble delay a Legendary catch bar by less than this
	-- The only keys the MarkSeen remote accepts and profile.seen holds: the arrival of every built world.
	SeenKeys = { Arrival_0 = true, Arrival_1 = true, Arrival_2 = true },
	-- The arrival title card (UI richness pass, package B; docs/vault/05-ui-design/UI-Richness-Pass.md section 6; UI/ArrivalTitle):
	-- the destination's name screen-wide with a bar in its colour and "NOW ARRIVING" under it, over speed lines that streak inward
	-- from both edges. Seconds unless a name says otherwise; shares are of the screen's width unless it says height. A "cell" is
	-- CellShare of the screen's height, so a line is a flat block of whole cells (the block look: axis-aligned, no rotation).
	-- Shared/ArrivalTitleMath does the arithmetic and tests/ArrivalTitleMath.spec.luau checks it.
	Title = {
		DisplayOrder = 55, -- over the launch fade (50), under nothing that matters during a flight
		NameSize = 48, -- Theme.TextSize.Reveal; shrinks to fit NameWidthShare, never wraps
		NameWidthShare = 0.8,
		NowSize = 24, -- Theme.TextSize.Label
		BarWidthShare = 0.3,
		BarCells = 3, -- the bar's thickness
		CellShare = 0.012, -- one cell, of the screen's height
		NameY = 0.44, -- the name's centre, of the screen's height
		BarY = 0.54,
		NowY = 0.62,
		ScaleFrom = 1.15, -- the name grows from this to 1.0 as it fades in
		InSeconds = 0.25,
		HoldSeconds = 1.8,
		OutSeconds = 0.35,
		TotalSeconds = 2.4, -- in + hold + out; the toasts stay quiet this long (Toast.QuietFor) and the speed lines run inside it
		AtSeconds = 0.8, -- a first visit starts the card this far into the Arrival moment (the end of its open shot); it is gone at 3.2 s, before the rise
		ReducedFadeSeconds = 0.2, -- Reduced Motion: no speed lines, no scale: a fade in over this, a hold, a fade out over this
		ReducedHoldSeconds = 1.2,
		Lines = {
			Count = 12,
			HeightCells = 1,
			MinCells = 8, -- a line's length in cells, from MinCells to MaxCells
			MaxCells = 18,
			InnerCount = 4, -- these reach the middle third (and keep clear of the title's rows); the rest stay in the outer thirds
			OuterTravel = 0.3, -- how far an outer line streaks in from its edge, of the width
			InnerTravel = 0.42,
			MinSeconds = 0.5, -- each line's flight takes MinSeconds to MaxSeconds
			MaxSeconds = 0.8,
			StaggerSeconds = 1.2, -- the starts are spread over the first this-many seconds
			StartTransparency = 0.2, -- fading to 1 as a line ends
			RowMin = 0.06, -- the rows' vertical span, of the height
			RowMax = 0.94,
			Seed = 31,
		},
	},
}
