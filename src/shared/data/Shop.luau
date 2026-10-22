--!strict
-- Robux catalog. A productId or passId of 0 means the item does not exist on the dashboard yet (Buy refuses safely);
-- the others were created by the owner on 2026-10-07 (owner guide Part C).
-- offSale = true holds a created item off sale (hidden, never prompted); the paid spins are held at launch because the wheel
-- can pay Scrap and Scrap is never sold for Robux (CLAUDE.md; Decide-Now 46).
-- paidRandom = true means: show odds, no dud, hidden where PolicyService.ArePaidRandomItemsRestricted is true.
-- oddsOnWheel = true: the item buys spins of the prize wheel; its shop tile links to the wheel, which shows every
-- prize with its odds (data/Spins, summing to 100), so the odds are one tap away before the purchase.
export type ShopItem = {
	id: string,
	tab: string,
	kind: "product" | "pass",
	robux: number,
	productId: number?,
	passId: number?,
	once: boolean?,
	paidRandom: boolean,
	oddsOnWheel: boolean?,
	offSale: boolean?,
}

-- The shelf (the Shop screen, UI Playbook "Shop shelf"): one row of tall cards, a tab rail that scrolls to a category.
-- A category is a tab and a colour; its items are a Launch section of the same id (Robux) or, for the one with `scrap`, the
-- lures and gear sold for Scrap. The colours are category colours, never the rarity table's (lint_data checks).
export type Category = { id: string, color: string, scrap: { string }? }
-- Per card: a ribbon and a seal (keys of Ribbons and Seals), the one-line note under the name (a SHOP_NOTE_ key), the Icons key
-- of its picture when it is not the item's id, `deal` (a tab shows "!" while a deal card is unclaimed), `new` (a tab shows NEW
-- while a new card is on the shelf), `width` in card widths (the Starter Pack takes two).
export type CardDef = { ribbon: string?, seal: string?, note: string?, icon: string?, deal: boolean?, new: boolean?, width: number? }
-- A rectangle in fractions of what it sits in (a card, or the screen).
export type Band = { X: number, Y: number, W: number, H: number }

local Items: { ShopItem } = {
	{ id = "StarterPack", tab = "Featured", kind = "product", robux = 199, productId = 3717062435, once = true, paidRandom = false },
	{ id = "DirectRare", tab = "Aliens", kind = "product", robux = 99, productId = 0, paidRandom = false },
	{ id = "DirectEpic", tab = "Aliens", kind = "product", robux = 199, productId = 0, paidRandom = false },
	{ id = "CompanionSlot4", tab = "Aliens", kind = "pass", robux = 249, passId = 2037728282, paidRandom = false },
	{ id = "StorageBoost", tab = "Aliens", kind = "pass", robux = 149, passId = 2037404298, paidRandom = false },
	{ id = "SlotEveryStation1", tab = "Camp", kind = "pass", robux = 399, passId = 2013608394, paidRandom = false },
	{ id = "SlotEveryStation2", tab = "Camp", kind = "pass", robux = 799, passId = 2036258305, paidRandom = false },
	{ id = "AutoCollect", tab = "Camp", kind = "pass", robux = 199, passId = 0, paidRandom = false },
	{ id = "AutoOptimize", tab = "Camp", kind = "pass", robux = 299, passId = 2014838379, paidRandom = false },
	{ id = "ModuleRush", tab = "Camp", kind = "product", robux = 59, productId = 0, paidRandom = false },
	{ id = "ExplorerPack", tab = "Gear", kind = "pass", robux = 399, passId = 2014814394, paidRandom = false },
	{ id = "RadarMk1Unlock", tab = "Gear", kind = "product", robux = 149, productId = 0, paidRandom = false },
	{ id = "SpeedBurstx5", tab = "Boosts", kind = "product", robux = 49, productId = 3717062564, paidRandom = false },
	{ id = "SteadyHandsx3", tab = "Boosts", kind = "product", robux = 79, productId = 3717062704, paidRandom = false },
	{ id = "ScrapMagnetx3", tab = "Boosts", kind = "product", robux = 99, productId = 3717062935, paidRandom = false },
	{ id = "ServerLuck2x", tab = "Boosts", kind = "product", robux = 249, productId = 3717063366, paidRandom = true },
	{ id = "ServerLuck4x", tab = "Boosts", kind = "product", robux = 999, productId = 3717063502, paidRandom = true },
	{ id = "Spins1", tab = "Spins", kind = "product", offSale = true, robux = 49, productId = 3718499778, paidRandom = true, oddsOnWheel = true },
	{ id = "Spins5", tab = "Spins", kind = "product", offSale = true, robux = 199, productId = 3718499788, paidRandom = true, oddsOnWheel = true },
	{ id = "Spins12", tab = "Spins", kind = "product", offSale = true, robux = 399, productId = 3718499794, paidRandom = true, oddsOnWheel = true },
}

-- What a product or pass hands over, in order. alien: one alien of `tier` (choose = the player picked the
-- species beforehand, Starter Pack); gear: a Gear or radar id through Shop.GrantGear; spins: banked spins;
-- powerUp: inventory power-ups; slots: +n on every station; serverLuck: `bonus` added to everyone's luck
-- for `seconds`; cosmetic: an owned cosmetic id (rendered by a later milestone); passFlag: the pass's own
-- effect, read live by the service named (AutoOptimize and StorageBoost: Economy).
export type ShopGrant = { kind: "alien" | "gear" | "spins" | "powerUp" | "slots" | "serverLuck" | "cosmetic" | "passFlag", id: string?, tier: string?, choose: boolean?, amount: number?, bonus: number?, seconds: number? }

local Grants: { [string]: { ShopGrant } } = {
	StarterPack = { { kind = "alien", tier = "Rare", choose = true }, { kind = "gear", id = "Boots" }, { kind = "spins", amount = 5 }, { kind = "cosmetic", id = "HoverSkinStarter" } },
	SlotEveryStation1 = { { kind = "slots", amount = 1 } },
	SlotEveryStation2 = { { kind = "slots", amount = 2 } }, -- stacks with SlotEveryStation1: both owned is +3 (decision 17)
	CompanionSlot4 = { { kind = "passFlag", id = "CompanionSlot4" } }, -- Companions reads the pass live for its extra slot
	StorageBoost = { { kind = "passFlag", id = "StorageBoost" } }, -- Economy reads the pass live: Storage.PassBonus more alien storage (Robux buys space, never Scrap)
	AutoOptimize = { { kind = "passFlag", id = "AutoOptimize" } },
	ExplorerPack = { { kind = "gear", id = "Boots" }, { kind = "gear", id = "Hoverboard" }, { kind = "gear", id = "Radar1" } },
	SpeedBurstx5 = { { kind = "powerUp", id = "SpeedBurst", amount = 5 } },
	SteadyHandsx3 = { { kind = "powerUp", id = "SteadyHands", amount = 3 } },
	ScrapMagnetx3 = { { kind = "powerUp", id = "ScrapMagnet", amount = 3 } },
	ServerLuck2x = { { kind = "serverLuck", bonus = 1.0, seconds = 900 } },
	ServerLuck4x = { { kind = "serverLuck", bonus = 3.0, seconds = 900 } },
	Spins1 = { { kind = "spins", amount = 1 } }, -- banked spins of the prize wheel (paid random: odds on the wheel)
	Spins5 = { { kind = "spins", amount = 5 } },
	Spins12 = { { kind = "spins", amount = 12 } },
}

-- Tab order, shelf order and colours (hex, read through Theme.Hex). Gold, orange, green, blue and purple: none is a rarity
-- colour (Theme.Rarity), and the green is not the buy pill's. Scrap holds what Scrap buys, in display order.
local Categories: { Category } = {
	{ id = "Featured", color = "FFC83D" },
	{ id = "Passes", color = "FF7A2F" },
	{ id = "Scrap", color = "2FBF71", scrap = { "Lure1", "Lure2", "Lure3", "Boots", "Hoverboard", "Radar1", "Radar2", "Glider" } },
	{ id = "Boosts", color = "68C9FE" },
	{ id = "Spins", color = "A855F7" },
}

-- Ribbon plates (white outlined caps on this colour) and starburst seals (SHOP_RIBBON_<id> and SHOP_SEAL_<id> name them).
local Ribbons: { [string]: { color: string } } = {
	BestDeal = { color = "A61E2B" },
	Pass = { color = "8A5A2B" },
	Popular = { color = "7C3AED" },
	New = { color = "E5383B" },
	Limited = { color = "2E9E4F" },
	TopDeal = { color = "D9480F" },
}
local Seals: { [string]: { color: string } } = {
	BestValue = { color = "FF4D4D" },
}

-- Cards that carry more than a name and a price, by item id (a lure or a gear item needs no row). The Starter Pack is the
-- featured card: two widths, the Rare picker, the one shine sweep.
local Cards: { [string]: CardDef } = {
	StarterPack = { ribbon = "BestDeal", seal = "BestValue", note = "OneTime", deal = true, width = 2 },
	SlotEveryStation1 = { ribbon = "Pass", note = "Forever" },
	SlotEveryStation2 = { ribbon = "Pass", note = "Forever" },
	CompanionSlot4 = { ribbon = "Pass", note = "Forever", icon = "Aliens" },
	StorageBoost = { ribbon = "Pass", note = "Forever", icon = "Aliens" },
	AutoOptimize = { ribbon = "Pass", note = "Forever" },
	ExplorerPack = { ribbon = "TopDeal", note = "Forever", icon = "Hoverboard" },
	SpeedBurstx5 = { ribbon = "Popular", note = "Uses", icon = "SpeedBurst" },
	SteadyHandsx3 = { note = "Uses", icon = "SteadyHands" },
	ScrapMagnetx3 = { note = "Uses", icon = "ScrapMagnet" },
	ServerLuck2x = { note = "Everyone", icon = "LuckyCharm" },
	ServerLuck4x = { note = "Everyone", icon = "LuckyCharm" },
	Spins1 = { ribbon = "New", note = "SeeOdds", icon = "Gifts", new = true },
	Spins5 = { ribbon = "New", note = "SeeOdds", icon = "Gifts", new = true },
	Spins12 = { ribbon = "New", seal = "BestValue", note = "SeeOdds", icon = "Gifts", new = true },
}

-- The shelf's geometry and motion. Fractions are of the screen unless a band says it is of a card. At 667x375 (iPhone SE) a card
-- is 0.735 of the height tall and 0.41 of that wide (113 x 276 px, 0.17 of the width); the featured card is two widths and a gap.
-- Every band is measured against the 14 px text floor (docs/vault/05-ui-design/UI-Playbook.md "Shop shelf"). The header (the
-- title, the Scrap pill and the X) sits wholly above the ribbons, even a card's lifted on hover, so a card scrolled under the X
-- never meets it (Studio 2026-10-22: the X covered the third card's ribbon; tests/ShelfMath.spec.luau "Shop header clears the cards").
local Shelf = {
	Window = { X = 0.14, Y = 0.075, W = 0.86, H = 0.875 }, -- the scrolling frame; it clips, so it leaves room above the cards for the ribbons (they straddle the top edge) and the hover lift
	CardTop = 0.195, -- the cards' top edge, of the screen height: the lifted ribbons' top (0.136) under the header's bottom (0.132)
	CardH = 0.735, -- the cards' height, of the screen height (the bottom stays at 0.93)
	CardAspect = 0.41, -- card width over card height: the width follows the height, so a card is the same shape in any window
	CardGap = 0.1, -- between cards, of a card's width
	EndPad = 0.1, -- at both ends of the row, of a card's width
	Rail = { X = 0.012, Y = 0.17, W = 0.118, TabH = 0.125, Gap = 0.02, Nudge = 0.012 }, -- the tab rail (Nudge: the active tab sits this far right); 0.125 of 375 is 47 px, over the 44 px tap floor
	Chip = { W = 0.55, H = 0.4, X = 0.62, Y = -0.1, Bang = 0.42, BangW = 0.3 }, -- the NEW chip (of a tab; Y negative is above its top edge) and the square "!" block (Bang: its height, BangW: the widest it may be, of a tab; an aspect constraint keeps it square)
	Title = { X = 0.16, Y = 0.012, W = 0.3, H = 0.1 }, -- "Shop", clear of Roblox's own buttons at the top left
	Close = { W = 0.1, H = 0.12, Right = 0.985, Y = 0.012 }, -- the red X (an aspect constraint makes it square within W by H): 45 px at 375, a 37 px face and the 44 px hit area
	Currency = { Right = 0.835, Y = 0.027, W = 0.2, H = 0.095, Aspect = 3.6, Icon = { X = 0.04, Y = 0.5, W = 0.2, H = 0.72 }, Amount = { X = 0.3, Y = 0.5, W = 0.66, H = 0.7 } }, -- the Scrap pill, left of the X (Aspect: width over height; Icon and Amount: the square and the count, of the pill)
	Scrollbar = { X = 0.3, Y = 0.958, W = 0.5, H = 0.026, MinThumb = 0.12, Grips = 3, GripGap = 0.15, GripW = 0.03 }, -- the bar under the shelf (MinThumb: the thumb's least width, of the bar; the grip ticks' spacing and width, of the thumb)
	Chevron = { W = 0.1, H = 0.125, Y = 0.5625, Right = 0.955, Left = 0.165 }, -- the edge arrows (Y: the middle of the card row; Right and Left: their centres)
	Detail = { -- the detail card (a tap on a card's body): the panel in the middle of the screen, then its bands as shares of the panel
		Panel = { X = 0.5, Y = 0.5, W = 0.56, H = 0.6 },
		HeaderH = 0.3,
		Name = { X = 0.04, Y = 0.1, W = 0.74, H = 0.8 }, -- of the header
		Text = { X = 0.06, Y = 0.36, W = 0.88, H = 0.56 },
		Close = { X = 0.985, Y = 0.03, W = 0.12, H = 0.26 },
	},
	Fade = 0.03, -- the dark strip at the shelf's left edge once it has moved, of the screen width
	Card = {
		Ribbon = { X = 0.06, Y = -0.05, W = 0.88, H = 0.095 },
		Name = { X = 0.05, Y = 0.055, W = 0.9, H = 0.12 },
		Note = { X = 0.04, Y = 0.18, W = 0.92, H = 0.062 },
		Icon = { X = 0.1, Y = 0.255, W = 0.8, H = 0.36 },
		Seal = { X = 0.2, Y = 0.64, W = 0.64 }, -- the centre (X, Y) and the side of its square, as a share of the card's width
		Pill = { X = 0.07, Y = 0.775, W = 0.86, H = 0.123 },
		Below = { X = 0.04, Y = 0.9, W = 0.92, H = 0.058 }, -- "about $N.NN" or "Held: N": one 14 px line under the pill
	},
	Featured = {
		Ribbon = { X = 0.03, Y = -0.05, W = 0.44, H = 0.095 },
		Name = { X = 0.04, Y = 0.055, W = 0.92, H = 0.1 },
		Note = { X = 0.04, Y = 0.16, W = 0.92, H = 0.062 },
		Icon = { X = 0.04, Y = 0.25, W = 0.44, H = 0.36 },
		Seal = { X = 0.12, Y = 0.62, W = 0.3 }, -- 72 px: "VALUE" is 47 px at 14 px
		Picker = { X = 0.52, Y = 0.235, W = 0.44, H = 0.48 }, -- three 44 px buttons, stacked (Rocklobber is 76 px at 14 px)
		PickerGap = 0.02, -- between the picker buttons, of the picker
		Pill = { X = 0.035, Y = 0.775, W = 0.93, H = 0.123 },
		Below = { X = 0.04, Y = 0.9, W = 0.92, H = 0.058 },
	},
	SealTilt = -15, -- degrees a seal is turned (the shape of ribbons and seals is Theme.Ribbon and Theme.Seal)
	Glow = { Lighten = 0.55, Alpha = 0.55 }, -- the lighter square glow behind a card's picture: how far toward white, and how clear
	Sunburst = { X = 0.57, Rays = 8, Width = 0.05, Alpha = 0.93, Size = 1.7 }, -- the faint rays behind the shelf (X: their centre, Size: of the screen height)
	Tilt = 10, -- degrees a card starts turned when it slides in
	Motion = {
		SlideFrom = 0.9, -- a card starts this far right of its place, in card widths
		SlideSeconds = 0.3,
		DropSeconds = 0.25, -- a tab dropping in
		DropFrom = -0.25, -- a tab starts this high, of its height
		HoverLift = 0.03, -- of the card's height
		HoverSeconds = 0.12,
		ScrollSeconds = 0.45, -- a tab or chevron tap scrolls with a Back ease this long
		SunburstSeconds = 120, -- one turn of the rays
		WheelStep = 0.5, -- one mouse-wheel notch scrolls this much of a window's width
		ChevronStep = 0.75, -- a chevron scrolls this much of the window's width
		FadeAlpha = 0.35, -- the left edge strip's transparency at its darkest
		EdgePx = 2, -- within this many px of an end the shelf counts as at that end
		TabSlack = 0.5, -- a section is the tab's once its first card is within this many card widths of the left edge
	},
}

return {
	Tabs = { "Featured", "Aliens", "Camp", "Gear", "Boosts", "Home", "Spins" },
	Items = Items,
	Grants = Grants,
	Categories = Categories,
	Ribbons = Ribbons,
	Seals = Seals,
	Cards = Cards,
	Shelf = Shelf,
	-- The launch shop (P0): the Robux page shows these, in these sections, in this order. Everything else in
	-- Items waits for its feature (hoverboard skins, home, direct-buy aliens, paid spins).
	Launch = {
		{ section = "Featured", items = { "StarterPack" } },
		{ section = "Passes", items = { "SlotEveryStation1", "SlotEveryStation2", "CompanionSlot4", "StorageBoost", "AutoOptimize", "ExplorerPack" } },
		{ section = "Boosts", items = { "SpeedBurstx5", "SteadyHandsx3", "ScrapMagnetx3", "ServerLuck2x", "ServerLuck4x" } },
		{ section = "Spins", items = { "Spins1", "Spins5", "Spins12" } },
	},
	-- The one offer that stands on the screen, not only behind the Shop button (TikTok batch 9 lesson 4): a HUD top button with
	-- its pixel icon, shown while it can be sold and the player has not bought it (Shared/ShelfMath.OfferShows); a tap opens the
	-- Shop on the Featured shelf. A one-time, not paid-random item from the Featured launch section (tests/ShelfMath.spec).
	HudOffer = "StarterPack",
	StarterChoices = { "Rocklobber", "Zapfinch", "Sparkfox" }, -- the Rares a Starter Pack may pick (World 1)
	NeverSold = { "Scrap", "DoubleShift", "LuckyCharm", "Mounts", "LegendaryAliens", "EventAliens" },
	-- The real-currency equivalent shown under every Robux price (GAME_DESIGN 14, "every price shows its real-currency
	-- equivalent"): an estimate from Roblox's 800 Robux for US$9.99 pack, formatted by Shared/ShopMath.RealPrice. Roblox
	-- sets the real price per region at purchase time; this line only says roughly what the Robux are worth.
	RealCurrency = { code = "USD", symbol = "$", perRobux = 0.0124875 },
}
