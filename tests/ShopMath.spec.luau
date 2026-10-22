--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.ShopMath)
local Shop = require(Shared.data.Shop)
local Gear = require(Shared.data.Gear)
local Strings = require(Shared.strings.en)
local F = require(script.Parent.Fixtures)
-- Units in one cent of the display, the definition of the format and not a game value. The half-up rule below is the
-- test's own: it never calls ShopMath, so a change to the module's rounding cannot move the expectation with it.
local CENTS = 100
local function halfUpCents(value: number): number
	return math.floor(value * CENTS + F.half)
end
local function written(cents: number): string
	return string.format("%.2f", cents / CENTS)
end
-- The sentence the template speaks before its first %s, taken from the template itself so a reworded line moves the test
-- with it ("about ").
local function prefixOf(template: string): string
	return string.sub(template, F.one, (string.find(template, "%s", F.one, true) :: number) - F.one)
end
local currency = Shop.RealCurrency
local template = Strings.SHOP_ABOUT_PRICE
describe("ShopMath", function()
	it("RealPrice writes every catalog price rounded half-up to two decimals", function()
		expect(#Shop.Items > F.zero).toEqual(true)
		for _, item in ipairs(Shop.Items) do
			local text = Math.RealPrice(item.robux, currency.perRobux)
			expect(text).toEqual(written(halfUpCents(item.robux * currency.perRobux)))
			expect(string.match(text, "^%d+%.%d%d$")).toEqual(text)
		end
	end)
	it("RealPrice rounds a value of exactly half a cent up, however its binary form falls", function()
		-- 0.005 itself, then every half cent of the first hundred dollars: (n + 0.5) cents is the tie and must read n + 1.
		expect(Math.RealPrice(F.one, F.half / CENTS)).toEqual(written(F.one))
		for whole = F.zero, CENTS * CENTS do
			local tie = (whole + F.half) / CENTS
			expect(Math.RealPrice(F.one, tie)).toEqual(written(whole + F.one))
			expect(Math.RealPrice(F.one, (whole + F.quarter) / CENTS)).toEqual(written(whole))
			expect(Math.RealPrice(F.one, (whole + F.half + F.quarter) / CENTS)).toEqual(written(whole + F.one))
		end
	end)
	it("RealPrice scales with the number of Robux: one cent each reads that many cents", function()
		for count = F.zero, CENTS * F.two do
			expect(Math.RealPrice(count, F.one / CENTS)).toEqual(written(count))
		end
	end)
	it("RealPrice clamps zero and negative amounts at 0.00", function()
		local zero = written(F.zero)
		expect(Math.RealPrice(F.zero, currency.perRobux)).toEqual(zero)
		expect(Math.RealPrice(F.one, F.zero)).toEqual(zero)
		expect(Math.RealPrice(-F.one, currency.perRobux)).toEqual(zero)
		expect(Math.RealPrice(-CENTS, currency.perRobux)).toEqual(zero)
		expect(Math.RealPrice(F.one, -currency.perRobux)).toEqual(zero)
	end)
	it("RealPrice never writes a thousands separator", function()
		local robux = CENTS * CENTS * F.two
		local text = Math.RealPrice(robux, F.one)
		expect(text).toEqual(written(robux * CENTS))
		expect(string.find(text, ",", F.one, true)).toEqual(nil)
		expect(string.match(text, "^%d+%.%d%d$")).toEqual(text)
	end)
	it("AboutLine speaks the template with the currency's symbol and the RealPrice amount", function()
		for _, item in ipairs(Shop.Items) do
			local line = Math.AboutLine(item.robux, currency, template)
			local amount = Math.RealPrice(item.robux, currency.perRobux)
			expect(line).toEqual(prefixOf(template) .. currency.symbol .. amount)
			expect(string.sub(line, F.one, #prefixOf(template) + #currency.symbol)).toEqual(prefixOf(template) .. currency.symbol)
			expect(string.sub(line, -#amount)).toEqual(amount)
		end
	end)
	it("AboutLine reads 'about ' then the symbol in the English strings", function()
		-- The one wording check: GAME_DESIGN 14 names the line ("about $2.49"), so a rewording of SHOP_ABOUT_PRICE is a
		-- design change and this should fail until the design says so.
		for _, item in ipairs(Shop.Items) do
			local line = Math.AboutLine(item.robux, currency, template)
			expect(string.sub(line, F.one, #"about " + #currency.symbol)).toEqual("about " .. currency.symbol)
		end
	end)
	it("AboutLine uses the currency and template it is given, not the shop's", function()
		local other = { code = "TST", symbol = "T", perRobux = F.half }
		local robux = F.two * F.two + F.one
		expect(Math.AboutLine(robux, other, "%s|%s")).toEqual("T|" .. written(halfUpCents(robux * other.perRobux)))
		expect(Math.AboutLine(F.zero, other, "%s|%s")).toEqual("T|" .. written(F.zero))
	end)
	it("ScrapShort is the whole Scrap still needed, and 0 once the player can pay", function()
		-- Every Scrap price the shop shows for gear, from the data, so a repriced row moves the test with it.
		for _, price in ipairs({ Gear.Boots.scrap, Gear.Hoverboard.scrap, Gear.Glider.scrap }) do
			expect(Math.ScrapShort(price, F.zero)).toEqual(price)
			expect(Math.ScrapShort(price, price - F.one)).toEqual(F.one)
			expect(Math.ScrapShort(price, price)).toEqual(F.zero)
			expect(Math.ScrapShort(price, price + F.one)).toEqual(F.zero)
			-- a part of a Scrap short still needs a whole one
			expect(Math.ScrapShort(price, price - F.half)).toEqual(F.one)
		end
	end)
	it("ShortLine names the gap, and falls back to the plain line when the price is unknown or nothing is short", function()
		local price = Gear.Boots.scrap
		local held = price - F.two
		local short = "%s|short"
		local plain = "plain"
		expect(Math.ShortLine(price, held, short, plain, tostring)).toEqual(tostring(F.two) .. "|short")
		expect(Math.ShortLine(nil, held, short, plain, tostring)).toEqual(plain)
		expect(Math.ShortLine(price, price, short, plain, tostring)).toEqual(plain)
		expect(Math.ShortLine(price, price + F.one, short, plain, tostring)).toEqual(plain)
		-- the English strings: the template takes the formatted gap
		expect(Math.ShortLine(price, F.zero, Strings.TOAST_SCRAP_SHORT, Strings.TOAST_NOT_ENOUGH_SCRAP, tostring))
			.toEqual(string.format(Strings.TOAST_SCRAP_SHORT, tostring(price)))
		expect(Math.ShortLine(nil, F.zero, Strings.TOAST_SCRAP_SHORT, Strings.TOAST_NOT_ENOUGH_SCRAP, tostring))
			.toEqual(Strings.TOAST_NOT_ENOUGH_SCRAP)
	end)
	describe("the Earn faster chip (B51, Decide-Now 48c)", function()
		local cap = Shop.EarnFaster.perSession
		local function base(): Math.BoostOffer
			return { short = Gear.Boots.scrap, sellable = true, active = false, held = F.zero, shown = F.zero, perSession = cap }
		end
		it("offers the chip after a real gap while the boost is on sale and none is running or held", function()
			expect(Math.OfferBoost(base())).toEqual(true)
			local small = base()
			small.short = F.one
			expect(Math.OfferBoost(small)).toEqual(true)
		end)
		it("never offers it without a gap: an unknown price or a price the player can pay", function()
			local none = base()
			none.short = Math.ScrapShort(Gear.Boots.scrap, Gear.Boots.scrap)
			expect(Math.OfferBoost(none)).toEqual(false)
		end)
		it("never offers it while a Scrap Magnet runs, or while one waits unused in the bar", function()
			local running = base()
			running.active = true
			expect(Math.OfferBoost(running)).toEqual(false)
			local held = base()
			held.held = F.one
			expect(Math.OfferBoost(held)).toEqual(false)
		end)
		it("never offers it when the boost cannot be sold here (no product id, off sale, no grant row)", function()
			local unsold = base()
			unsold.sellable = false
			expect(Math.OfferBoost(unsold)).toEqual(false)
		end)
		it("offers it at most perSession times a session", function()
			expect(cap >= F.one).toEqual(true)
			local spent = base()
			spent.shown = cap - F.one
			expect(Math.OfferBoost(spent)).toEqual(true)
			spent.shown = cap
			expect(Math.OfferBoost(spent)).toEqual(false)
		end)
		it("points at a Boosts product that hands over a catch-Scrap power-up: never Scrap, never random, never a pass", function()
			local PowerUps = require(Shared.data.PowerUps)
			local id = Shop.EarnFaster.item
			local found: Shop.ShopItem? = nil
			for _, item in ipairs(Shop.Items) do
				if item.id == id then
					found = item
				end
			end
			assert(found ~= nil, "EarnFaster names " .. id .. ", which is not in Shop.Items")
			expect(found.kind).toEqual("product")
			expect(found.paidRandom).toEqual(false)
			expect(found.once == true).toEqual(false)
			local onBoosts = false
			for _, section in ipairs(Shop.Launch) do
				if section.section == "Boosts" and table.find(section.items, id) then
					onBoosts = true
				end
			end
			expect(onBoosts).toEqual(true)
			local grants = Shop.Grants[id]
			expect(#grants > F.zero).toEqual(true)
			for _, grant in ipairs(grants) do
				expect(grant.kind).toEqual("powerUp")
				local row = (PowerUps :: any)[grant.id :: string]
				expect(row.effect).toEqual("catchScrap")
			end
			expect(Shop.EarnFaster.seconds > F.zero).toEqual(true)
			expect(type(Strings.TOAST_EARN_FASTER)).toEqual("string")
		end)
	end)
end)
return true
