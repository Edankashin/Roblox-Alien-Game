--!strict
-- One active per id. Timers run only while online. `value` is a bonus fraction for speed, zone, luck and
-- catchScrap (+0.5 = +50%) and a straight multiplier for stationScrap (2.0 = double).
-- ScannerPulse alone carries `pulseSeconds`, the period of the radar rim's breathing while the pulse runs
-- (client presentation only). The table is typed as the common row shape so the readers that view it as
-- `{ [string]: PowerUpDef }` stay exact; the client Radar reads `pulseSeconds` through an any cast.
type Row = { name: string, seconds: number, effect: string, value: number, sellable: boolean }
local rows: { [string]: Row } = {
	SpeedBurst = { name = "Speed Burst", seconds = 60, effect = "speed", value = 0.5, sellable = true }, -- +50% speed (bonus, like the other rows)
	SteadyHands = { name = "Steady Hands", seconds = 600, effect = "zone", value = 0.30, sellable = true },
	ScannerPulse = { name = "Scanner Pulse", seconds = 60, effect = "reveal", value = 1, sellable = false, pulseSeconds = 1.6 },
	LuckyCharm = { name = "Lucky Charm", seconds = 600, effect = "luck", value = 0.5, sellable = false },
	ScrapMagnet = { name = "Scrap Magnet", seconds = 600, effect = "catchScrap", value = 0.5, sellable = true },
	DoubleShift = { name = "Double Shift", seconds = 600, effect = "stationScrap", value = 2.0, sellable = false },
}
return rows
