--!strict
-- One overlay per alien, multiplicative with tier. Chance is percent of catches; 0 means event only.
local Overlays: { [string]: { multiplier: number, chance: number } } = {
	None = { multiplier = 1, chance = 0 },
	Shiny = { multiplier = 1.25, chance = 5 },
	Gold = { multiplier = 1.5, chance = 1.5 },
	Crystal = { multiplier = 2, chance = 0.3 },
	Rainbow = { multiplier = 5, chance = 0 },
	Spectral = { multiplier = 2, chance = 0 }, -- week-only: rolls only during a weekly drop's weather (data/Weekly OverlayChance)
}

return {
	Order = { "Shiny", "Gold", "Crystal", "Rainbow", "Spectral" },
	Overlays = Overlays,
}
