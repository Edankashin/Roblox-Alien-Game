--!strict
-- Size rolls (docs/GAME_DESIGN.md: size rolls and growth, the "HUGE!" moment): every wild spawn rolls a
-- size band when it appears, the band travels into the caught record, scales the model wherever it is
-- drawn, multiplies the catch Scrap and stamps the reveal. Odds sum to 100. Luck does not touch size.

export type Band = {
	id: string,
	odds: number, -- percent, the bands sum to 100
	scale: number, -- model scale multiplier on top of the species' own
	scrapMultiplier: number, -- on the catch Scrap
	revealPop: number, -- the reveal card's pop scale (1 is the usual)
	label: boolean, -- whether the reveal and the Aliens screen name the band (SIZE_<id>)
}

local Bands: { Band } = {
	{ id = "Tiny", odds = 3, scale = 0.75, scrapMultiplier = 1.5, revealPop = 0.9, label = true },
	{ id = "Small", odds = 17, scale = 0.9, scrapMultiplier = 1, revealPop = 1, label = false },
	{ id = "Normal", odds = 60, scale = 1, scrapMultiplier = 1, revealPop = 1, label = false },
	{ id = "Big", odds = 17, scale = 1.15, scrapMultiplier = 1.25, revealPop = 1.15, label = true },
	{ id = "Huge", odds = 3, scale = 1.35, scrapMultiplier = 2, revealPop = 1.3, label = true },
}

local ById: { [string]: Band } = {}
for _, band in ipairs(Bands) do
	ById[band.id] = band
end

return {
	Bands = Bands, -- in roll order
	ById = ById,
	Default = "Normal", -- records and spawns from before sizes existed
}
