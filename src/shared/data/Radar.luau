--!strict
-- The radar (docs/GAME_DESIGN.md section 6, Decision B52): no map, no rarity, no distances, no waypoint. Ethan, 2026-10-22:
-- "having a map of where the aliens are and what rarities defeats the whole struggle aspect of the game. We want them to search
-- for the aliens like a pokemon game." A Scrap-bought tier gives a COLUMN on the right edge of the screen: up to `slots` small
-- squares, the nearest wild alien at the top and the furthest at the bottom, each the black shadow of its species until the
-- player has caught one, the real model after. Only aliens within `range` studs (flat) are listed; a Secret-tier alien never is.
-- Tier 0 (no radar owned) shows nothing at all. Every number here; the client's RadarColumn reads it, Shop and ShopScreen read
-- name, range, slots, scrap and unlock (Mk1 1,500 Scrap after Field Notes 2; Mk2 8,000 Scrap once a second world is unlocked; Mk3
-- waits on World 3, so its range here is "the whole world" and it has no buy rule yet).
-- Scanner Pulse (data/PowerUps ScannerPulse) lifts the radar for its seconds, even without a radar: the column lists every alien
-- in the player's current biome whatever the range, up to `Pulse.slots` of them, still shadows and order only.
return {
	[0] = { name = "No Radar", range = 0, slots = 0, scrap = 0 },
	[1] = { name = "Radar Mk1", range = 120, slots = 5, scrap = 1500, unlock = "FieldNotes2" },
	[2] = { name = "Radar Mk2", range = 250, slots = 7, scrap = 8000, unlock = "World2" },
	[3] = { name = "Radar Mk3", range = 10000, slots = 9, scrap = 25000, unlock = "World3" },
	Pulse = { slots = 9 }, -- the most aliens the column lists while a Scanner Pulse runs (the nearest ones of the biome)
}
