--!strict
-- Catch variants: the rules a world or a species lays over the one timing bar (docs/GAME_DESIGN.md,
-- "World signatures"). Same control surface, same server judging from a timestamp: a variant only
-- moves the Good and Perfect zones over the sweep (the drift), decides which input scores (the tap, or
-- letting go of a hold: the reel), scales the tier's ticker speed, and can put the whole encounter on a
-- clock (the chase). Which variant an encounter runs: the species row's `variant`, else the world's
-- `catchVariant` (Worlds.luau), else Standard. Dev `/variant <id>` forces one per player in Studio so a
-- variant can be played on World 1 before its world exists. Every number here, never in code.

export type Control = "tap" | "release"

export type Look = {
	zone: string, -- Theme.Colors key the client draws the Good zone with
	ticker: string, -- Theme.Colors key for the ticker
}

export type Row = {
	id: string,
	control: Control, -- what scores: the tap, or the release of a hold (hold to reel, let go to score)
	driftAmplitude: number, -- how far the zone centre swings from its rolled base, as a fraction of the bar (0 = still)
	driftPeriodSeconds: number, -- one full swing out and back
	driftClampMin: number, -- the drifting centre never leaves [driftClampMin, driftClampMax]
	driftClampMax: number,
	tickerSpeedScale: number, -- multiplies the tier's ticker speed
	timeLimitSeconds: number, -- the whole encounter (all rounds) must end inside this; 0 for no clock
	look: Look,
	nameKey: string?, -- strings key for the word that opens the bar ("Cast!"); nil shows nothing
	hintKey: string, -- strings key for the hint under the bar
	holdHintKey: string?, -- release control only: the hint while the hold is down
}

local Rows: { [string]: Row } = {
	Standard = {
		id = "Standard",
		control = "tap",
		driftAmplitude = 0,
		driftPeriodSeconds = 1,
		driftClampMin = 0,
		driftClampMax = 1,
		tickerSpeedScale = 1,
		timeLimitSeconds = 0,
		look = { zone = "Confirm", ticker = "White" },
		nameKey = nil,
		hintKey = "CATCH_TAP_HINT",
		holdHintKey = nil,
	},
	-- Tidepool's fishing bar: the zone bobs like a float, the fish (ticker) is slower, and the player holds to
	-- reel and lets go to score.
	Reel = {
		id = "Reel",
		control = "release",
		driftAmplitude = 0.18,
		driftPeriodSeconds = 2.6,
		driftClampMin = 0.08,
		driftClampMax = 0.92,
		tickerSpeedScale = 0.85,
		timeLimitSeconds = 0,
		look = { zone = "Select", ticker = "Featured" },
		nameKey = "CATCH_VARIANT_REEL",
		hintKey = "CATCH_HINT_REEL",
		holdHintKey = "CATCH_HINT_REEL_HOLD",
	},
	-- Neon Grid's rooftop chase: the zone darts side to side, the ticker is quicker, and the whole encounter
	-- runs on a clock; when it runs out the alien bolts.
	Chase = {
		id = "Chase",
		control = "tap",
		driftAmplitude = 0.3,
		driftPeriodSeconds = 1.4,
		driftClampMin = 0.08,
		driftClampMax = 0.92,
		tickerSpeedScale = 1.1,
		timeLimitSeconds = 12,
		look = { zone = "Confirm", ticker = "Featured" },
		nameKey = "CATCH_VARIANT_CHASE",
		hintKey = "CATCH_HINT_CHASE",
		holdHintKey = nil,
	},
}

local Order: { string } = { "Standard", "Reel", "Chase" }

return {
	Rows = Rows,
	Order = Order,
	Default = "Standard",
	-- The client sends one last tap this long after the deadline passes (plus the lag allowance) so the
	-- server, not the client, declares the chase lost.
	DeadlineTapDelaySeconds = 0.1,
	-- The chase clock turns red and pops once a second for its last seconds.
	CountdownUrgentSeconds = 3,
}
