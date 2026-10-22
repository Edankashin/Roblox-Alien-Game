--!strict
-- One active per id. Timers run only while online. `value` is a bonus fraction for speed, zone, luck and
-- catchScrap (+0.5 = +50%) and a straight multiplier for stationScrap (2.0 = double).
-- ScannerPulse (effect "reveal", Decision B52): while it runs the radar column (data/Radar) lists every alien in the player's
-- current biome whatever the range, up to Radar.Pulse.slots of them, even with no Radar Mk1 owned; still shadows and order only.
-- The world's reveal of that biome's uncaught silhouettes (WildRenderer) is unchanged.
-- `sellable`: the power-up may be granted by a Robux product (data/Shop Grants; tools/lint_data.py refuses a powerUp grant of a
-- row that says false). Scanner Pulse became sellable one at a time with Decision B51 (Scanner Pulse x1 at 9 Robux); Lucky Charm
-- and Double Shift stay earned only (GAME_DESIGN 6 and 14, data/Shop NeverSold).
type Row = { name: string, seconds: number, effect: string, value: number, sellable: boolean }
local rows: { [string]: Row } = {
	SpeedBurst = { name = "Speed Burst", seconds = 60, effect = "speed", value = 0.5, sellable = true }, -- +50% speed (bonus, like the other rows)
	SteadyHands = { name = "Steady Hands", seconds = 600, effect = "zone", value = 0.30, sellable = true },
	ScannerPulse = { name = "Scanner Pulse", seconds = 60, effect = "reveal", value = 1, sellable = true },
	LuckyCharm = { name = "Lucky Charm", seconds = 600, effect = "luck", value = 0.5, sellable = false },
	ScrapMagnet = { name = "Scrap Magnet", seconds = 600, effect = "catchScrap", value = 0.5, sellable = true },
	DoubleShift = { name = "Double Shift", seconds = 600, effect = "stationScrap", value = 2.0, sellable = false },
}
return rows
