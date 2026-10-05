--!strict
-- Outposts (docs/GAME_DESIGN.md section 8): when the player launches, the camp they leave becomes an
-- Outpost that keeps producing that world's key materials and a trickle of Scrap, offline too, and can be
-- upgraded with Scrap. Production is lazy: nothing ticks; the pending amount is the time since the
-- outpost's lastCollect (capped) times the level's rates (Shared/OutpostMath), granted on Collect, when
-- the player flies back to that world, and never while the player's ship is on that world (its camp's
-- stations pay instead). Every number lives here.

export type Level = {
	scrapPerHour: number,
	materialsPerHour: number, -- whole key materials per hour, spread round-robin over the world's node materials
	upgradeScrap: number?, -- Scrap to reach the next level; nil at the top level
}

local Levels: { Level } = {
	{ scrapPerHour = 90, materialsPerHour = 2, upgradeScrap = 600 },
	{ scrapPerHour = 180, materialsPerHour = 4, upgradeScrap = 1500 },
	{ scrapPerHour = 360, materialsPerHour = 6 },
}

return {
	Levels = Levels,
	CollectCapSeconds = 24 * 3600, -- production stops piling up after this long uncollected (the offline cap)
	CollectMinSeconds = 300, -- Collect answers TooSoon before this much time has passed since the last collect
	-- Key materials whose condition is in this list never come from an outpost (the Warden's Core is quest-only).
	ExcludedConditions = { "Quest" },
}
