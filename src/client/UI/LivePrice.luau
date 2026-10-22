--!strict
-- The Robux price Roblox will actually charge for a Shop item, read once a session with MarketplaceService:GetProductInfo.
-- The data row's `robux` is only the fallback (Studio, a failed read): a product whose price Roblox manages (price
-- optimisation, regional pricing) can differ from the row, and a card must never say one price while the purchase dialog
-- charges another (Server Luck x4: card 599, Roblox 999, Mac job 56, 2026-10-22).

local MarketplaceService = game:GetService("MarketplaceService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shop = require(Shared:WaitForChild("data"):WaitForChild("Shop"))

type ShopItem = Shop.ShopItem

local LivePrice = {}

local prices: { [string]: number } = {}
local started = false

-- The cached live price, else the data row's.
function LivePrice.Get(item: ShopItem): number
	return prices[item.id] or item.robux
end

-- Reads every live item's price in the background, once; `onChange` runs after each read that differs from the row.
function LivePrice.Prefetch(items: { ShopItem }, onChange: () -> ())
	if started then
		return
	end
	started = true
	for _, item in ipairs(items) do
		local id = if item.kind == "pass" then item.passId else item.productId
		if id and id > 0 then
			task.spawn(function()
				local infoType = if item.kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfo(id, infoType)
				end)
				local price = if ok and type(info) == "table" then info.PriceInRobux else nil
				if type(price) == "number" and price > 0 then
					prices[item.id] = price
					if price ~= item.robux then
						onChange()
					end
				end
			end)
		end
	end
end

return LivePrice
