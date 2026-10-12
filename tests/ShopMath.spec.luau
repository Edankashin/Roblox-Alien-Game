--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.ShopMath)
local Shop = require(Shared.data.Shop)
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
end)
return true
