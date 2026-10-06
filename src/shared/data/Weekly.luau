--!strict
-- The weekly drop (docs/GAME_DESIGN.md section 12, "Weekly"): every week, on the leaderboard's Friday clock
-- (data/Leaderboard ResetWeekday and ResetHourUtc, through Shared/WeeklyMath), one species is the Alien of the
-- Week, one themed weather state holds all week where the drop names one, and a week-only overlay rolls on
-- wild spawns while that weather runs. A `limited` species spawns only in its week and shows "Vaulted" in the
-- Codex the rest of the time; a featured one (limited = false) is an existing species boosted for the week.
-- The rotation repeats, so a Vaulted alien always comes back (the design's reruns). Every number here, never in
-- code; Overrides let a dated week carry a different drop without touching the rotation.

export type Drop = {
	species: string, -- Species row id; a limited one should be listed in no Spawns table
	limited: boolean, -- true: spawns only in its week, Vaulted otherwise; false: an existing species, boosted
	weather: string?, -- a weather state id the clock holds all week on every world (Lighting.Conditions and Weather.Sheets rows), nil for the usual weather
	overlay: string?, -- Overlays row that rolls on wild spawns while `weather` runs (OverlayChance), nil for none
	worldId: number, -- the world the species spawns in that week
}

local Rotation: { Drop } = {
	{ species = "Panpipe", limited = true, weather = "Aurora", overlay = "Spectral", worldId = 1 },
	{ species = "Gloomoth", limited = false, weather = nil, overlay = nil, worldId = 1 },
	{ species = "Shimmerlynx", limited = false, weather = "Aurora", overlay = "Spectral", worldId = 2 },
}

return {
	Rotation = Rotation,
	-- A dated week (WeeklyMath.PeriodId, "2026-10-09") that carries a different drop than the rotation would.
	Overrides = {} :: { [string]: Drop },
	Epoch = 1790956800, -- Friday 2026-10-02 16:00 UTC, the first week of the rotation; a Friday at ResetHourUtc
	SpawnChance = 0.05, -- fraction of wild spawns in the drop's world that are the Alien of the Week, any biome
	OverlayChance = 3, -- percent of wild spawns that carry the week's overlay while its weather runs
	PushSeconds = 30, -- how often the server re-reads the week (a flip is announced within this)
	BannerDays = 7, -- the HUD banner shows the week while this many days or fewer remain (the whole week)
}
