--!strict
-- Habitats on the home planet (docs/GAME_DESIGN.md section 10): themed enclosures per world, placed on the house
-- grid like rooms (HomeBuild rows of kind "habitat", each with a worldId and a capacity), where resting aliens of
-- that world are put on display. A displayed alien roams inside its habitat for everyone to see and pays a little
-- Scrap passively, lazily like an outpost: nothing ticks, the owed amount is the time since the last settle times
-- the displayed aliens' rates (capped), paid when the player arrives home. A displayed alien is never seated and
-- never follows; the habitat count is the capacity (the cap in HomeBuild). Every number here, never in code.

local ScrapPerHourByTier: { [string]: number } = {
	Common = 6,
	Uncommon = 10,
	Rare = 18,
	Epic = 30,
	Legendary = 50,
	Cosmic = 80,
	Secret = 80,
}

return {
	ScrapPerHourByTier = ScrapPerHourByTier,
	CollectCapSeconds = 24 * 3600, -- owed Scrap stops piling up after this long away (the offline cap)
	SettleMinSeconds = 60, -- an arrival less than this after the last settle pays nothing (no toast)
	-- how the client draws a displayed alien inside its habitat
	DisplayScale = 0.7, -- model scale over the species' own (times the size band and growth), like a camp worker
	WanderSpeedStudsPerSecond = 2,
	WanderPauseMin = 2, -- seconds standing still between walks
	WanderPauseMax = 5,
	WanderInsetStuds = 1, -- walks keep this far inside the habitat's footprint edge
	FenceHeightStuds = 1.2, -- the placeholder habitat: a pad with a low fence ring
	FencePostStuds = 0.6,
	PostsPerSide = 4,
}
