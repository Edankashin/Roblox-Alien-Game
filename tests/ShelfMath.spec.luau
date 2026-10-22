--!strict
-- The Shop shelf's arithmetic (Shared/ShelfMath) and the data it reads (data/Shop Categories, Cards, Ribbons, Seals, Shelf): where
-- the cards sit, which tab the scroll belongs to (including the last, short section), the scrollbar thumb and its inverse, the
-- edge arrows, the live check, and that every card, ribbon and seal the shelf names exists. The colours cannot be compared with
-- Theme.Rarity here (no Color3 in this sandbox); tools/lint_data.py does that.
local Shared = game:GetService("ReplicatedStorage").Shared
local ShelfMath = require(Shared.ShelfMath)
local Shop = require(Shared.data.Shop)
local Lures = require(Shared.data.Lures)
local Strings = require(Shared.strings.en)

local EDGE = Shop.Shelf.Motion.EdgePx

describe("ShelfMath", function()
	describe("Place", function()
		it("puts the first card at the pad and every next one a gap past the last", function()
			local lefts, total = ShelfMath.Place({ 100, 210, 100 }, 10, 12)
			expect(lefts[1]).toEqual(12)
			expect(lefts[2]).toEqual(122)
			expect(lefts[3]).toEqual(342)
			expect(total).toEqual(454)
		end)
		it("is a row of length 0 with no cards", function()
			local lefts, total = ShelfMath.Place({}, 10, 12)
			expect(#lefts).toEqual(0)
			expect(total).toEqual(0)
		end)
	end)

	describe("scrolling", function()
		it("clamps a section's start into what the row can reach", function()
			expect(ShelfMath.MaxOffset(1000, 400)).toEqual(600)
			expect(ShelfMath.MaxOffset(300, 400)).toEqual(0)
			expect(ShelfMath.ScrollTarget(-20, 600)).toEqual(0)
			expect(ShelfMath.ScrollTarget(250, 600)).toEqual(250)
			expect(ShelfMath.ScrollTarget(900, 600)).toEqual(600)
			expect(ShelfMath.ScrollTarget(900, 0)).toEqual(0)
		end)
	end)

	describe("ActiveSection", function()
		local starts = { 0, 300, 700, 1100 }
		local slack = 60
		it("follows the scroll position, a section turning current as its first card nears the left edge", function()
			expect(ShelfMath.ActiveSection(0, starts, 2000, slack, EDGE)).toEqual(1)
			expect(ShelfMath.ActiveSection(239, starts, 2000, slack, EDGE)).toEqual(1)
			expect(ShelfMath.ActiveSection(240, starts, 2000, slack, EDGE)).toEqual(2)
			expect(ShelfMath.ActiveSection(700, starts, 2000, slack, EDGE)).toEqual(3)
			expect(ShelfMath.ActiveSection(1060, starts, 2000, slack, EDGE)).toEqual(4)
		end)
		it("lands exactly on a tab's section after that tab's scroll", function()
			for index, start in ipairs(starts) do
				expect(ShelfMath.ActiveSection(ShelfMath.ScrollTarget(start, 2000), starts, 2000, slack, EDGE)).toEqual(index)
			end
		end)
		it("calls the last section current at the far end, though a short one never reaches the left edge", function()
			expect(ShelfMath.ActiveSection(900, starts, 900, slack, EDGE)).toEqual(4)
			expect(ShelfMath.ActiveSection(900 - EDGE, starts, 900, slack, EDGE)).toEqual(4)
			expect(ShelfMath.ActiveSection(900 - EDGE - 1, starts, 900, slack, EDGE)).toEqual(3)
		end)
		it("answers 0 with no sections and the first with a row that does not scroll", function()
			expect(ShelfMath.ActiveSection(0, {}, 0, slack, EDGE)).toEqual(0)
			expect(ShelfMath.ActiveSection(0, starts, 0, slack, EDGE)).toEqual(1)
		end)
	end)

	describe("scrollbar", function()
		it("sizes the thumb by the window over the row and slides it along the free track", function()
			local size, left = ShelfMath.Thumb(0, 400, 1600, 0.12)
			expect(size).toEqual(0.25)
			expect(left).toEqual(0)
			size, left = ShelfMath.Thumb(1200, 400, 1600, 0.12)
			expect(left).toEqual(0.75)
			size, left = ShelfMath.Thumb(600, 400, 1600, 0.12)
			expect(left).toEqual(0.375)
		end)
		it("never makes the thumb smaller than its minimum, and fills the track when nothing scrolls", function()
			local size = ShelfMath.Thumb(0, 400, 40000, 0.12)
			expect(size).toEqual(0.12)
			local fit, fitLeft = ShelfMath.Thumb(0, 400, 400, 0.12)
			expect(fit).toEqual(1)
			expect(fitLeft).toEqual(0)
		end)
		it("puts the thumb's middle under the pointer, clamped to the ends", function()
			expect(ShelfMath.OffsetFromPointer(0, 400, 1600, 0.12)).toEqual(0)
			expect(ShelfMath.OffsetFromPointer(1, 400, 1600, 0.12)).toEqual(1200)
			expect(ShelfMath.OffsetFromPointer(0.5, 400, 1600, 0.12)).toEqual(600)
			expect(ShelfMath.OffsetFromPointer(0.5, 400, 400, 0.12)).toEqual(0)
		end)
		it("round-trips an offset through the thumb and back", function()
			local window, canvas, minimum = 400, 2200, 0.12
			for _, offset in ipairs({ 0, 90, 450, 1000, 1800 }) do
				local size, left = ShelfMath.Thumb(offset, window, canvas, minimum)
				local back = ShelfMath.OffsetFromPointer(left + size / 2, window, canvas, minimum)
				expect(back).toBeClose(offset, 1e-6)
			end
		end)
	end)

	describe("Arrows", function()
		it("shows the left arrow once the row has moved and the right until the end", function()
			local left, right = ShelfMath.Arrows(0, 600, EDGE)
			expect(left).toEqual(false)
			expect(right).toEqual(true)
			left, right = ShelfMath.Arrows(300, 600, EDGE)
			expect(left).toEqual(true)
			expect(right).toEqual(true)
			left, right = ShelfMath.Arrows(600, 600, EDGE)
			expect(left).toEqual(true)
			expect(right).toEqual(false)
			left, right = ShelfMath.Arrows(0, 0, EDGE)
			expect(left).toEqual(false)
			expect(right).toEqual(false)
		end)
	end)

	describe("IsLive", function()
		it("reads passId for a pass and productId for a product, and treats a missing id or 0 as not live", function()
			expect(ShelfMath.IsLive({ kind = "pass", passId = 5 })).toEqual(true)
			expect(ShelfMath.IsLive({ kind = "pass", passId = 0, productId = 9 })).toEqual(false)
			expect(ShelfMath.IsLive({ kind = "pass" })).toEqual(false)
			expect(ShelfMath.IsLive({ kind = "product", productId = 7 })).toEqual(true)
			expect(ShelfMath.IsLive({ kind = "product", productId = 0, passId = 9 })).toEqual(false)
			expect(ShelfMath.IsLive({ kind = "product" })).toEqual(false)
		end)
		it("IsSellable needs a live id and at least one grant row", function()
			local row = { { kind = "spins", amount = 1 } }
			expect(ShelfMath.IsSellable({ kind = "product", productId = 7 }, row)).toEqual(true)
			expect(ShelfMath.IsSellable({ kind = "product", productId = 7 }, {})).toEqual(false)
			expect(ShelfMath.IsSellable({ kind = "product", productId = 7 }, nil)).toEqual(false)
			expect(ShelfMath.IsSellable({ kind = "pass", passId = 0 }, row)).toEqual(false)
		end)
		it("OfferShows only once the purchases are known, while unbought, for a sellable item", function()
			local row = { { kind = "spins", amount = 1 } }
			local live: ShelfMath.Sellable = { kind = "product", productId = 7 }
			expect(ShelfMath.OfferShows(live, row, 0, true)).toEqual(true)
			expect(ShelfMath.OfferShows(live, row, 0, false)).toEqual(false)
			expect(ShelfMath.OfferShows(live, row, 1, true)).toEqual(false)
			expect(ShelfMath.OfferShows(live, nil, 0, true)).toEqual(false)
			expect(ShelfMath.OfferShows({ kind = "product", productId = 7, offSale = true }, row, 0, true)).toEqual(false)
			expect(ShelfMath.OfferShows({ kind = "product", productId = 0 }, row, 0, true)).toEqual(false)
		end)
		it("names a HUD offer that is a one-time launch item on the Featured shelf, with a pixel icon and a menu name", function()
			local PixelIcons = require(Shared.data.PixelIcons)
			local id = Shop.HudOffer
			local found: Shop.ShopItem? = nil
			for _, item in ipairs(Shop.Items) do
				if item.id == id then
					found = item
				end
			end
			assert(found ~= nil, "HudOffer " .. id .. " is not in Shop.Items")
			expect(found.once).toEqual(true)
			expect(found.paidRandom).toEqual(false)
			local onShelf = false
			for _, section in ipairs(Shop.Launch) do
				if section.section == "Featured" and table.find(section.items, id) then
					onShelf = true
				end
			end
			expect(onShelf).toEqual(true)
			expect(Shop.Grants[id] ~= nil).toEqual(true)
			expect(PixelIcons.Icons[id] ~= nil).toEqual(true)
			expect(type((Strings :: any)["MENU_" .. id])).toEqual("string")
		end)
		it("sells one Scanner Pulse as the cheapest launch item, repeatable, first on the Boosts shelf (B51)", function()
			local PowerUps = require(Shared.data.PowerUps)
			local PixelIcons = require(Shared.data.PixelIcons)
			local id = "ScannerPulse1"
			local found: Shop.ShopItem? = nil
			local launch: { [string]: boolean } = {}
			for _, section in ipairs(Shop.Launch) do
				for _, sid in ipairs(section.items) do
					launch[sid] = true
				end
				if section.section == "Boosts" then
					expect(section.items[1]).toEqual(id)
				end
			end
			for _, item in ipairs(Shop.Items) do
				if item.id == id then
					found = item
				end
			end
			assert(found ~= nil, id .. " is not in Shop.Items")
			expect(found.kind).toEqual("product")
			expect(found.tab).toEqual("Boosts")
			expect(found.once == true).toEqual(false)
			expect(found.paidRandom).toEqual(false)
			for _, item in ipairs(Shop.Items) do
				if launch[item.id] and item.id ~= id then
					expect(found.robux < item.robux).toEqual(true)
				end
			end
			local grants = Shop.Grants[id]
			expect(#grants).toEqual(1)
			expect(grants[1].kind).toEqual("powerUp")
			expect(grants[1].id).toEqual("ScannerPulse")
			expect(grants[1].amount).toEqual(1)
			expect(PowerUps.ScannerPulse.sellable).toEqual(true)
			expect(Shop.Cards[id].icon).toEqual("ScannerPulse")
			expect(PixelIcons.Icons.ScannerPulse ~= nil).toEqual(true)
			expect(type((Strings :: any)["SHOP_ITEM_" .. id])).toEqual("string")
			expect(type((Strings :: any)["SHOP_DESC_" .. id])).toEqual("string")
			expect(string.format(Strings.SHOP_NOTE_Use, 1)).toEqual("1 USE")
		end)
		it("finds a grant row for every launch item, so nothing on the shelf can sell nothing", function()
			local byId: { [string]: Shop.ShopItem } = {}
			for _, item in ipairs(Shop.Items) do
				byId[item.id] = item
			end
			for _, section in ipairs(Shop.Launch) do
				for _, id in ipairs(section.items) do
					local grants = Shop.Grants[id]
					expect(grants ~= nil and #grants > 0).toEqual(true)
					expect(ShelfMath.IsSellable(byId[id], grants)).toEqual(ShelfMath.IsLive(byId[id]))
				end
			end
		end)
		it("agrees with the server's rule on every launch item: live exactly when its dashboard id is set", function()
			local byId: { [string]: Shop.ShopItem } = {}
			for _, item in ipairs(Shop.Items) do
				byId[item.id] = item
			end
			for _, section in ipairs(Shop.Launch) do
				for _, id in ipairs(section.items) do
					local item = byId[id]
					expect(item ~= nil).toEqual(true)
					local liveId = if item.kind == "pass" then item.passId or 0 else item.productId or 0
					expect(ShelfMath.IsLive(item)).toEqual(liveId ~= 0 and item.offSale ~= true)
				end
			end
		end)
	end)
end)

describe("Shop shelf data", function()
	local categories: { [string]: Shop.Category } = {}
	for _, category in ipairs(Shop.Categories) do
		categories[category.id] = category
	end

	it("has five categories with unique ids and six-digit hex colours, each named by a tab string", function()
		expect(#Shop.Categories).toEqual(5)
		local seen: { [string]: boolean } = {}
		for _, category in ipairs(Shop.Categories) do
			expect(seen[category.id]).toEqual(nil)
			seen[category.id] = true
			expect(string.match(category.color, "^%x%x%x%x%x%x$")).toEqual(category.color)
			expect((Strings :: any)["SHOP_TAB_" .. category.id] ~= nil).toEqual(true)
		end
	end)

	it("gives every Launch section a category, and every launch item exactly one card on the shelf", function()
		local onShelf: { [string]: number } = {}
		for _, section in ipairs(Shop.Launch) do
			expect(categories[section.section] ~= nil).toEqual(true)
			for _, id in ipairs(section.items) do
				onShelf[id] = (onShelf[id] or 0) + 1
			end
		end
		for _, category in ipairs(Shop.Categories) do
			for _, id in ipairs(category.scrap or {}) do
				onShelf[id] = (onShelf[id] or 0) + 1
			end
		end
		for id, count in pairs(onShelf) do
			expect(count).toEqual(1)
			expect((Strings :: any)["SHOP_GLYPH_" .. id] ~= nil).toEqual(true)
		end
	end)

	it("sells every lure for Scrap on the shelf", function()
		local scrap: { [string]: boolean } = {}
		for _, category in ipairs(Shop.Categories) do
			for _, id in ipairs(category.scrap or {}) do
				scrap[id] = true
			end
		end
		for _, id in ipairs(Lures.Order) do
			expect(scrap[id]).toEqual(true)
		end
	end)

	it("names only ribbons, seals and notes that exist, and every note has its string", function()
		for id, card in pairs(Shop.Cards) do
			local known = false
			for _, section in ipairs(Shop.Launch) do
				for _, item in ipairs(section.items) do
					known = known or item == id
				end
			end
			expect(known).toEqual(true)
			if card.ribbon then
				expect(Shop.Ribbons[card.ribbon] ~= nil).toEqual(true)
				expect((Strings :: any)["SHOP_RIBBON_" .. card.ribbon] ~= nil).toEqual(true)
			end
			if card.seal then
				expect(Shop.Seals[card.seal] ~= nil).toEqual(true)
				expect((Strings :: any)["SHOP_SEAL_" .. card.seal] ~= nil).toEqual(true)
			end
			if card.note then
				expect((Strings :: any)["SHOP_NOTE_" .. card.note] ~= nil).toEqual(true)
			end
		end
		for id, ribbon in pairs(Shop.Ribbons) do
			expect(string.match(ribbon.color, "^%x%x%x%x%x%x$")).toEqual(ribbon.color)
			expect((Strings :: any)["SHOP_RIBBON_" .. id] ~= nil).toEqual(true)
		end
	end)

	it("makes a paid random item carry the odds link, so the odds are one tap from the card", function()
		for _, item in ipairs(Shop.Items) do
			if item.oddsOnWheel then
				local card = Shop.Cards[item.id]
				expect(card ~= nil and card.note == "SeeOdds").toEqual(true)
			end
		end
	end)

	it("keeps the featured card the only wide one and the card layout inside the card", function()
		for id, card in pairs(Shop.Cards) do
			expect(card.width == nil or (card.width == 2 and id == "StarterPack")).toEqual(true)
		end
		for _, layout in ipairs({ Shop.Shelf.Card, Shop.Shelf.Featured }) do
			for name, band in pairs(layout) do
				if name == "Seal" or type(band) ~= "table" then
					continue -- the seal is a centre and a side, and PickerGap is a number
				end
				expect(band.X >= 0 and band.X + band.W <= 1).toEqual(true)
				expect(band.Y + band.H <= 1).toEqual(true)
			end
		end
		-- the pill and the line under it clear each other
		expect(Shop.Shelf.Card.Pill.Y + Shop.Shelf.Card.Pill.H <= Shop.Shelf.Card.Below.Y).toEqual(true)
		expect(Shop.Shelf.Featured.Pill.Y + Shop.Shelf.Featured.Pill.H <= Shop.Shelf.Featured.Below.Y).toEqual(true)
	end)
end)

describe("ShelfMath.IsLive with offSale", function()
	it("an item held off sale is not live even with an id", function()
		expect(ShelfMath.IsLive({ kind = "product", productId = 123, offSale = true })).toEqual(false)
		expect(ShelfMath.IsSellable({ kind = "product", productId = 123, offSale = true }, { {} })).toEqual(false)
	end)
	it("the paid spins are held off sale at launch (Decide-Now 46)", function()
		for _, item in ipairs(Shop.Items) do
			if item.tab == "Spins" then
				expect(ShelfMath.IsLive(item)).toEqual(false)
			end
		end
	end)
end)

describe("Shop arrows clear the cards", function()
	-- Studio 2026-10-22 (second run): the ">" sat on the third card's "+2" icon at the default window. The shelf scrolls, so a card
	-- passes everywhere inside the window: each arrow stands in a gutter beside it. Builder.blockButton aspect 1: a square within
	-- Chevron.W by Chevron.H of the screen, centred on Chevron.Left or Right; the tab rail's right edge is Rail.X + Rail.W, the
	-- active tab nudged Rail.Nudge to the right of it.
	local shelf = Shop.Shelf
	local screens = {
		{ name = "iPhone SE", w = 667, h = 375 },
		{ name = "iPad", w = 1080, h = 810 },
		{ name = "default window", w = 1154, h = 663 },
		{ name = "default 16:9", w = 1280, h = 720 },
		{ name = "wide phone", w = 844, h = 390 },
		{ name = "1080p", w = 1920, h = 1080 },
	}
	for _, screen in ipairs(screens) do
		it(screen.name .. ": neither arrow touches the window, the tab rail or the screen's edge", function()
			local side = math.min(shelf.Chevron.W * screen.w, shelf.Chevron.H * screen.h) / screen.w -- of the width
			local leftLo, leftHi = shelf.Chevron.Left - side / 2, shelf.Chevron.Left + side / 2
			local rightLo, rightHi = shelf.Chevron.Right - side / 2, shelf.Chevron.Right + side / 2
			local railEdge = shelf.Rail.X + shelf.Rail.W + shelf.Rail.Nudge
			assert(leftLo >= railEdge, "the left arrow meets the rail: " .. leftLo .. " against " .. railEdge)
			assert(leftHi <= shelf.Window.X, "the left arrow is over the window: " .. leftHi .. " against " .. shelf.Window.X)
			assert(rightLo >= shelf.Window.X + shelf.Window.W, "the right arrow is over the window")
			assert(rightHi <= 1, "the right arrow leaves the screen")
		end)
	end
	it("the window still holds the featured card and a plain one at iPhone SE (the shelf is not squeezed away)", function()
		local cardW = shelf.CardH * shelf.CardAspect * 375 / 667
		-- the featured card (two widths and a gap), a plain card and the gaps and end pads round them
		assert(shelf.Window.W >= cardW * (3 + 2 * shelf.CardGap + 2 * shelf.EndPad), "window is " .. shelf.Window.W)
	end)
end)

describe("Shop header clears the cards", function()
	-- Studio 2026-10-22: at the default window the red X covered the third card's ribbon. The shelf scrolls, so any card can pass
	-- under the header; the fix is vertical: the header (the title, the Scrap pill and the X, all from data/Shop Shelf) ends above
	-- the top of every ribbon, even a card's lifted on hover. Sizes: iPhone SE and iPad (the device pass), the Mac's 16:9 default
	-- window, a wide phone and a 1080p window. Builder.blockClose: a square within W by H of the screen; the Scrap pill keeps its
	-- aspect within W by H; a ribbon starts Card.Ribbon.Y (negative) of the card above the card's top.
	local shelf = Shop.Shelf
	local screens = {
		{ name = "iPhone SE", w = 667, h = 375 },
		{ name = "iPad", w = 1080, h = 810 },
		{ name = "default 16:9", w = 1280, h = 720 },
		{ name = "wide phone", w = 844, h = 390 },
		{ name = "1080p", w = 1920, h = 1080 },
	}
	local function headerBottom(w: number, h: number): number
		local close = shelf.Close
		local side = math.min(close.W * w, close.H * h)
		local pill = shelf.Currency
		local pillH = math.min(pill.H * h, pill.W * w / pill.Aspect)
		local title = shelf.Title
		return math.max(close.Y * h + side, pill.Y * h + pillH, title.Y * h + title.H * h)
	end
	local function ribbonTop(h: number, lifted: boolean): number
		local cardH = shelf.CardH * h
		local top = shelf.CardTop * h + math.min(shelf.Card.Ribbon.Y, shelf.Featured.Ribbon.Y) * cardH
		return if lifted then top - shelf.Motion.HoverLift * cardH else top
	end
	for _, screen in ipairs(screens) do
		it(screen.name .. ": the X, the Scrap pill and the title end above every ribbon, lifted or not", function()
			local bottom = headerBottom(screen.w, screen.h)
			local lifted = ribbonTop(screen.h, true)
			assert(lifted >= bottom + 1, "a lifted ribbon starts at " .. lifted .. " px, the header ends at " .. bottom)
			assert(ribbonTop(screen.h, false) > lifted, "the lift goes up")
		end)
	end
	it("the cards still fit the window (the ribbons and the lift inside its clip) and keep the text floor at iPhone SE", function()
		local window = shelf.Window
		local liftedTop = shelf.CardTop + (shelf.Card.Ribbon.Y - shelf.Motion.HoverLift) * shelf.CardH
		assert(liftedTop >= window.Y, "a lifted ribbon leaves the window's clip")
		assert(shelf.CardTop + shelf.CardH <= window.Y + window.H, "the cards run past the window")
		assert(shelf.CardTop + shelf.CardH <= shelf.Scrollbar.Y, "the cards run over the scrollbar")
		local cardPx = shelf.CardH * 375
		for _, band in ipairs({ shelf.Card.Note, shelf.Card.Below, shelf.Featured.Note, shelf.Featured.Below }) do
			assert(band.H * cardPx >= 14, "a one-line band is " .. band.H * cardPx .. " px")
		end
		assert(shelf.Card.Name.H * cardPx >= 2 * 14, "the name's two lines do not fit")
		assert(shelf.Card.Ribbon.H * cardPx >= 14 + 4, "the ribbon's line does not fit")
		local middle = shelf.CardTop + shelf.CardH / 2
		assert(math.abs(shelf.Chevron.Y - middle) <= 0.005, "the arrows are off the row's middle")
	end)
	it("the X keeps a face of at least 0.6 of the tap floor at iPhone SE (its hit area makes 44 px)", function()
		local side = math.min(shelf.Close.W * 667, shelf.Close.H * 375)
		local rows = math.max(3, math.floor((shelf.Close.H - 0.02) / 0.02 - 0.8 + 0.5)) -- Builder.blockButtonRows
		local face = side * (1 - 1 / (rows + 0.8 + 1))
		assert(face >= 0.6 * 44, "the X's face is " .. face .. " px")
	end)
end)
return true
