--!strict
-- Robux catalog. productId values are placeholders until products exist in the Creator Dashboard.
-- paidRandom = true means: show odds, no dud, hidden where PolicyService.ArePaidRandomItemsRestricted is true.
export type ShopItem = {
	id: string,
	tab: string,
	kind: "product" | "pass",
	robux: number,
	productId: number?,
	passId: number?,
	once: boolean?,
	paidRandom: boolean,
}

local Items: { ShopItem } = {
	{ id = "StarterPack", tab = "Featured", kind = "product", robux = 199, productId = 0, once = true, paidRandom = false },
	{ id = "DirectRare", tab = "Aliens", kind = "product", robux = 99, productId = 0, paidRandom = false },
	{ id = "DirectEpic", tab = "Aliens", kind = "product", robux = 199, productId = 0, paidRandom = false },
	{ id = "CompanionSlot4", tab = "Aliens", kind = "pass", robux = 249, passId = 0, paidRandom = false },
	{ id = "SlotEveryStation1", tab = "Camp", kind = "pass", robux = 399, passId = 0, paidRandom = false },
	{ id = "SlotEveryStation2", tab = "Camp", kind = "pass", robux = 799, passId = 0, paidRandom = false },
	{ id = "AutoCollect", tab = "Camp", kind = "pass", robux = 199, passId = 0, paidRandom = false },
	{ id = "AutoOptimize", tab = "Camp", kind = "pass", robux = 299, passId = 0, paidRandom = false },
	{ id = "LongerOffline", tab = "Camp", kind = "pass", robux = 299, passId = 0, paidRandom = false },
	{ id = "ModuleRush", tab = "Camp", kind = "product", robux = 59, productId = 0, paidRandom = false },
	{ id = "ExplorerPack", tab = "Gear", kind = "pass", robux = 399, passId = 0, paidRandom = false },
	{ id = "RadarMk1Unlock", tab = "Gear", kind = "product", robux = 149, productId = 0, paidRandom = false },
	{ id = "SpeedBurstx5", tab = "Boosts", kind = "product", robux = 49, productId = 0, paidRandom = false },
	{ id = "SteadyHandsx3", tab = "Boosts", kind = "product", robux = 79, productId = 0, paidRandom = false },
	{ id = "ScrapMagnetx3", tab = "Boosts", kind = "product", robux = 99, productId = 0, paidRandom = false },
	{ id = "ServerLuck2x", tab = "Boosts", kind = "product", robux = 249, productId = 0, paidRandom = true },
	{ id = "ServerLuck4x", tab = "Boosts", kind = "product", robux = 999, productId = 0, paidRandom = true },
	{ id = "Spins1", tab = "Spins", kind = "product", robux = 49, productId = 0, paidRandom = true },
	{ id = "Spins5", tab = "Spins", kind = "product", robux = 199, productId = 0, paidRandom = true },
	{ id = "Spins12", tab = "Spins", kind = "product", robux = 399, productId = 0, paidRandom = true },
}

return {
	Tabs = { "Featured", "Aliens", "Camp", "Gear", "Boosts", "Home", "Spins" },
	Items = Items,
	NeverSold = { "Scrap", "DoubleShift", "LuckyCharm", "Mounts", "LegendaryAliens", "EventAliens" },
}
