--!strict
-- ReplicatedStorage.Shared.ShopMath: the real-currency estimate under every Robux price (GAME_DESIGN 14, "every price shows
-- its real-currency equivalent"), shared so the Shop screen and the headless tests format it the same way. Pure functions of
-- the values passed in: the rate, the symbol and the line's wording are not here, they live in data/Shop (RealCurrency) and
-- strings/en (SHOP_ABOUT_PRICE), and the screen hands them in. The amount is an estimate: Roblox sets the real regional
-- price when the purchase prompt opens, so the line only says roughly what the Robux are worth.

local ShopMath = {}

-- The currency row of data/Shop (RealCurrency): the ISO code, the symbol shown before the amount, and the money one Robux
-- is worth.
export type Currency = { code: string, symbol: string, perRobux: number }

-- Units per whole currency unit (a cent per dollar). Money is shown to this precision, so it is the definition of the
-- display, not a game value.
local SUBUNITS = 100
-- Added before rounding so a value that is exactly half a cent in decimal (1.005) rounds up even where the product's binary
-- form lands a hair below it: without it 1,147 of the first 20,001 half-cent values rounded down. It is far smaller than any
-- cent, so it moves no other value.
local TIE_NUDGE = 1e-9

-- `robux` at `perRobux` money each, rounded half-up to the cent and written with exactly two decimals ("2.49", "0.61",
-- "12.48"): no thousands separator, never negative (a negative amount, or NaN, clamps to "0.00").
function ShopMath.RealPrice(robux: number, perRobux: number): string
	local subunits = math.max(0, math.floor(robux * perRobux * SUBUNITS + 0.5 + TIE_NUDGE))
	local whole = math.floor(subunits / SUBUNITS)
	return string.format("%.0f.%02d", whole, subunits - whole * SUBUNITS)
end

-- The whole line for a price: `template` (strings/en SHOP_ABOUT_PRICE, symbol then amount) filled with the currency's symbol
-- and RealPrice(robux, currency.perRobux), so the screen makes one call per tile.
function ShopMath.AboutLine(robux: number, currency: Currency, template: string): string
	return string.format(template, currency.symbol, ShopMath.RealPrice(robux, currency.perRobux))
end

return ShopMath
