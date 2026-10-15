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
					expect(ShelfMath.IsLive(item)).toEqual(liveId ~= 0)
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
return true
