--!strict
-- One overlay per alien, multiplicative with tier. Chance is percent of catches; 0 means event only.
-- Order is the prestige rank (a later row is the better copy when two copies of one species are compared).
-- The three event rows (Rainbow, Spectral, LaunchGold) never come out of the usual roll: Rainbow has no source yet,
-- Spectral rolls through data/Seasons and data/Weekly, LaunchGold through LaunchWindow below. Event overlays roll
-- on free wild spawns only, never on a bought or hatched alien (docs/GAME_DESIGN.md section 12).
export type Row = {
	multiplier: number,
	chance: number,
	tint: string?, -- a Theme.Colors key the overlay's badge wears in place of the Codex purple; nil keeps the purple
	desc: string?, -- a strings key: one line on what the overlay is, shown in the Codex under "Best"
}

local Overlays: { [string]: Row } = {
	None = { multiplier = 1, chance = 0 },
	Shiny = { multiplier = 1.25, chance = 5 },
	Gold = { multiplier = 1.5, chance = 1.5 },
	Crystal = { multiplier = 2, chance = 0.3 },
	Rainbow = { multiplier = 5, chance = 0 },
	Spectral = { multiplier = 2, chance = 0 }, -- week-only: rolls only during a weekly drop's weather (data/Weekly OverlayChance)
	LaunchGold = { multiplier = 1.5, chance = 0, tint = "Featured", desc = "OVERLAY_DESC_LaunchGold" }, -- launch window only (LaunchWindow); Gold's 1.5x, prestige and not power
}

return {
	Order = { "Shiny", "Gold", "Crystal", "Rainbow", "Spectral", "LaunchGold" },
	Overlays = Overlays,
	-- The launch-week hook: players who were there keep proof. Inside [startsAt, endsAt) every wild spawn carries
	-- `overlay` with `chance` percent, rolled by the server before the season's and the week's overlays; never
	-- before startsAt, never at or after endsAt (the overlay then stops existing for good, it is not sold or granted).
	LaunchWindow = {
		startsAt = 1792108800, -- Friday 2026-10-16 00:00 UTC, the day before the public launch
		endsAt = 1792972800, -- Monday 2026-10-26 00:00 UTC, ten days on (the launch week and the days around it)
		overlay = "LaunchGold",
		chance = 4, -- percent of wild spawns, 1 in 25, so about 1 in 25 catches: seen within a short session, not common
	},
}
