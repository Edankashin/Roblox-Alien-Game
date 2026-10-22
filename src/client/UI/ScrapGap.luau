--!strict
-- StarterPlayerScripts.Client.UI.ScrapGap: what a tap on a Scrap price the player cannot pay shows, in one place for every screen
-- that sells for Scrap (the Shop's Scrap shelf, the Ship's Pay, a Build card, a Peddler offer, the Storage Bay button). The toast
-- says how much more Scrap is needed (Shared/ShopMath.ShortLine, TikTok batch 9 lesson 3), and once a session it carries the
-- Earn faster chip (Decision B51, Decide-Now 48c): one tap opens the Shop on the Boosts shelf at Scrap Magnet (data/Shop
-- EarnFaster), a catch bonus, never Scrap. The chip opens the Shop and nothing else: no purchase prompt starts from the gap, and
-- the Shop's own Buy still asks the server. When to offer it is Shared/ShopMath.OfferBoost (specced in tests/ShopMath.spec.luau):
-- a real gap, the boost on sale, no Scrap Magnet running or waiting in the bar, under the session cap. The bootstrap hands in the
-- opener (SetOpener), since the Shop itself shows this line and this module cannot require it back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Shop = require(Shared:WaitForChild("data"):WaitForChild("Shop"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local ShopMath = require(Shared:WaitForChild("ShopMath"))
local ShelfMath = require(Shared:WaitForChild("ShelfMath"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local ScrapGap = {}

local EARN = Shop.EarnFaster
local earnItem: Shop.ShopItem? = nil
for _, item in ipairs(Shop.Items) do
	if item.id == EARN.item then
		earnItem = item
	end
end
local earnGrants: { Shop.ShopGrant }? = Shop.Grants[EARN.item]
-- The power-up the boost hands over (its first powerUp grant row), whose running buff or unused stock means no chip.
local earnPowerUp: string? = nil
for _, grant in ipairs(earnGrants or {}) do
	if grant.kind == "powerUp" and earnPowerUp == nil then
		earnPowerUp = grant.id
	end
end
-- The chip wears the colour of the shelf it opens (data/Shop Categories), so it reads as a way to that shelf.
local chipColor = Theme.Colors.Select
for _, category in ipairs(Shop.Categories) do
	if earnItem and category.id == earnItem.tab then
		chipColor = Theme.Hex(category.color)
	end
end

local opener: ((string) -> ())? = nil
local shown = 0 -- chips offered this session

-- The bootstrap's way to the Shop: opens it on the named item's card (Screens.Open("Shop"), then ShopScreen.Focus).
function ScrapGap.SetOpener(fn: ((string) -> ())?)
	opener = fn
end

-- Whether this gap gets the chip now (Shared/ShopMath.OfferBoost with what the client mirror knows).
local function offers(short: number): boolean
	local item, powerUp = earnItem, earnPowerUp
	if opener == nil or item == nil or powerUp == nil or not State.Has() then
		return false
	end
	local endsAt = State.GetBuffs()[powerUp]
	return ShopMath.OfferBoost({
		short = short,
		sellable = ShelfMath.IsSellable(item, earnGrants),
		active = endsAt ~= nil and endsAt > State.Now(),
		held = State.Get().inventory.powerUps[powerUp] or 0,
		shown = shown,
		perSession = EARN.perSession,
	})
end

-- The refusal for a Scrap price: "Need N more Scrap" (or the plain line when the price is unknown or nothing is short, so the
-- server's refusal stands without a wrong number), in `color`, with the Earn faster chip when OfferBoost says so.
function ScrapGap.Show(price: number?, held: number, color: Color3)
	local line = ShopMath.ShortLine(price, held, Strings.TOAST_SCRAP_SHORT, Strings.TOAST_NOT_ENOUGH_SCRAP, Builder.formatNumber)
	local short = if price ~= nil then ShopMath.ScrapShort(price, held) else 0
	if not offers(short) then
		Toast.Show(line, color)
		return
	end
	shown += 1
	Toast.ShowAction(line, color, {
		text = Strings.TOAST_EARN_FASTER,
		color = chipColor,
		onTap = function()
			local open = opener
			if open then
				open(EARN.item)
			end
		end,
	}, EARN.seconds)
end

return ScrapGap
