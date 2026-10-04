--!strict
-- Segments must sum to 100. Every segment has value; no dud.
return {
	FreePerDay = 1,
	Segments = {
		{ id = "Scrap200", label = "200 Scrap", odds = 30, reward = { kind = "scrap", amount = 200 } },
		{ id = "Scrap600", label = "600 Scrap", odds = 20, reward = { kind = "scrap", amount = 600 } },
		{ id = "Lure1", label = "Twig Lure", odds = 18, reward = { kind = "lure", id = "Lure1", amount = 1 } },
		{ id = "SpeedBurst", label = "Speed Burst", odds = 12, reward = { kind = "powerUp", id = "SpeedBurst", amount = 1 } },
		{ id = "LuckyCharm", label = "Lucky Charm", odds = 10, reward = { kind = "powerUp", id = "LuckyCharm", amount = 1 } },
		{ id = "Scrap2000", label = "2,000 Scrap", odds = 6, reward = { kind = "scrap", amount = 2000 } },
		{ id = "DoubleShift", label = "Double Shift", odds = 3, reward = { kind = "powerUp", id = "DoubleShift", amount = 1 } },
		{ id = "CompanionToken", label = "Companion Token", odds = 1, reward = { kind = "token", id = "CompanionSlot", amount = 1 } },
	},
}
