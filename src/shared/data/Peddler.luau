--!strict
-- Lands every Config.PeddlerIntervalSeconds with three offers drawn from this pool (weights).
-- Priced in Scrap only, so these never fall under paid random item rules.
export type PeddlerOffer = { id: string, kind: string, weight: number, scrap: number, amount: number?, tier: string? }

local Pool: { PeddlerOffer } = {
	{ id = "Lure1", kind = "lure", weight = 30, scrap = 120 },
	{ id = "Lure2", kind = "lure", weight = 12, scrap = 750 },
	{ id = "SpeedBurst", kind = "powerUp", weight = 20, scrap = 200 },
	{ id = "SteadyHands", kind = "powerUp", weight = 15, scrap = 350 },
	{ id = "ScrapMagnet", kind = "powerUp", weight = 10, scrap = 400 },
	{ id = "ScrapBundleSmall", kind = "scrap", weight = 10, scrap = 0, amount = 500 },
	{ id = "RareEgg", kind = "egg", weight = 3, scrap = 2500, tier = "Rare" },
	{ id = "EpicEgg", kind = "egg", weight = 1, scrap = 9000, tier = "Epic" },
}

return { OffersPerVisit = 3, Pool = Pool }
