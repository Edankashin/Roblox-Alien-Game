--!strict
-- One active per id. Timers run only while online.
return {
	SpeedBurst = { name = "Speed Burst", seconds = 60, effect = "speed", value = 1.5, sellable = true },
	SteadyHands = { name = "Steady Hands", seconds = 600, effect = "zone", value = 0.30, sellable = true },
	ScannerPulse = { name = "Scanner Pulse", seconds = 60, effect = "reveal", value = 1, sellable = false },
	LuckyCharm = { name = "Lucky Charm", seconds = 600, effect = "luck", value = 0.5, sellable = false },
	ScrapMagnet = { name = "Scrap Magnet", seconds = 600, effect = "catchScrap", value = 0.5, sellable = true },
	DoubleShift = { name = "Double Shift", seconds = 600, effect = "stationScrap", value = 2.0, sellable = false },
}
