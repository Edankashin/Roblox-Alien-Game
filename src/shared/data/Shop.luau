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

-- What a product or pass hands over, in order. alien: one alien of `tier` (choose = the player picked the
-- species beforehand, Starter Pack); gear: a Gear or radar id through Shop.GrantGear; spins: banked spins;
-- powerUp: inventory power-ups; slots: +n on every station; serverLuck: `bonus` added to everyone's luck
-- for `seconds`; cosmetic: an owned cosmetic id (rendered by a later milestone); passFlag: the pass's own
-- effect, read live by the service named (LongerOffline: Economy's cap; AutoOptimize: Economy).
export type ShopGrant = { kind: "alien" | "gear" | "spins" | "powerUp" | "slots" | "serverLuck" | "cosmetic" | "passFlag", id: string?, tier: string?, choose: boolean?, amount: number?, bonus: number?, seconds: number? }

local Grants: { [string]: { ShopGrant } } = {
	StarterPack = { { kind = "alien", tier = "Rare", choose = true }, { kind = "gear", id = "Boots" }, { kind = "spins", amount = 5 }, { kind = "cosmetic", id = "HoverSkinStarter" } },
	SlotEveryStation1 = { { kind = "slots", amount = 1 } },
	SlotEveryStation2 = { { kind = "slots", amount = 2 } }, -- stacks with SlotEveryStation1: both owned is +3 (decision 17)
	CompanionSlot4 = { { kind = "passFlag", id = "CompanionSlot4" } }, -- Companions reads the pass live for its extra slot
	AutoOptimize = { { kind = "passFlag", id = "AutoOptimize" } },
	LongerOffline = { { kind = "passFlag", id = "LongerOffline" } },
	ExplorerPack = { { kind = "gear", id = "Boots" }, { kind = "gear", id = "Hoverboard" }, { kind = "gear", id = "Radar1" } },
	SpeedBurstx5 = { { kind = "powerUp", id = "SpeedBurst", amount = 5 } },
	SteadyHandsx3 = { { kind = "powerUp", id = "SteadyHands", amount = 3 } },
	ScrapMagnetx3 = { { kind = "powerUp", id = "ScrapMagnet", amount = 3 } },
	ServerLuck2x = { { kind = "serverLuck", bonus = 1.0, seconds = 900 } },
	ServerLuck4x = { { kind = "serverLuck", bonus = 3.0, seconds = 900 } },
}

return {
	Tabs = { "Featured", "Aliens", "Camp", "Gear", "Boosts", "Home", "Spins" },
	Items = Items,
	Grants = Grants,
	-- The launch shop (P0): the Robux page shows these, in these sections, in this order. Everything else in
	-- Items waits for its feature (hoverboard skins, home, direct-buy aliens, paid spins).
	Launch = {
		{ section = "Featured", items = { "StarterPack" } },
		{ section = "Passes", items = { "SlotEveryStation1", "SlotEveryStation2", "CompanionSlot4", "AutoOptimize", "LongerOffline", "ExplorerPack" } },
		{ section = "Boosts", items = { "SpeedBurstx5", "SteadyHandsx3", "ScrapMagnetx3", "ServerLuck2x", "ServerLuck4x" } },
	},
	StarterChoices = { "Rocklobber", "Zapfinch", "Sparkfox" }, -- the Rares a Starter Pack may pick (World 1)
	NeverSold = { "Scrap", "DoubleShift", "LuckyCharm", "Mounts", "LegendaryAliens", "EventAliens" },
}
