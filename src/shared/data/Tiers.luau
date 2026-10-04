--!strict
local Types = require(script.Parent.Parent.types.Types)

-- Rarity ladder. Shares are percent of wild spawns; the rest is Common.
local Tiers: { [string]: Types.TierDef } = {
	Common = { share = 50, workSpeed = 1, passive = 0, catchChance = 1.00, tickerSpeed = 0.8, goodZone = 0.40, perfectZone = 0.12, rounds = 1, codexScrap = 50, color = "B0B0B0" },
	Uncommon = { share = 27, workSpeed = 1.6, passive = 0, catchChance = 0.90, tickerSpeed = 0.8, goodZone = 0.34, perfectZone = 0.10, rounds = 1, codexScrap = 120, color = "57F96C" },
	Rare = { share = 15, workSpeed = 3, passive = 0, catchChance = 0.75, tickerSpeed = 1.0, goodZone = 0.26, perfectZone = 0.08, rounds = 1, codexScrap = 400, color = "3B82F6" },
	Epic = { share = 6, workSpeed = 6, passive = 0, catchChance = 0.60, tickerSpeed = 1.2, goodZone = 0.20, perfectZone = 0.06, rounds = 1, codexScrap = 1500, color = "C026D3" },
	Legendary = { share = 1.5, workSpeed = 12, passive = 0.10, catchChance = 0.50, tickerSpeed = 1.5, goodZone = 0.16, perfectZone = 0.05, rounds = 3, codexScrap = 6000, color = "F59E0B" },
	Cosmic = { share = 0, workSpeed = 25, passive = 0.25, catchChance = 0.50, tickerSpeed = 1.7, goodZone = 0.14, perfectZone = 0.04, rounds = 3, codexScrap = 20000, color = "EC4899" },
	Secret = { share = 0, workSpeed = 25, passive = 0.25, catchChance = 1.00, tickerSpeed = 1.5, goodZone = 0.16, perfectZone = 0.05, rounds = 3, codexScrap = 20000, color = "111111" },
}

local Order: { string } = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic", "Secret" }

return { Tiers = Tiers, Order = Order }
