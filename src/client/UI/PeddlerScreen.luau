--!strict
-- StarterPlayerScripts.Client.UI.PeddlerScreen: the Peddler's trade panel. A gold header, a "Leaves in"
-- countdown, and the visit's three offers as a row of cards: a kind chip, the name, what it does, the
-- price and a Buy button that turns into a Sold chip once the server confirms. Every value shown is
-- read from the visit mirrored in State and the shared data tables; every Buy asks the server
-- (PeddlerBuy) and a refusal becomes a toast. Nothing here decides an outcome: the server pushes the
-- new Scrap and inventory, and an egg comes back as a GrantResult the bootstrap turns into a Reveal.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Lures = require(Shared:WaitForChild("data"):WaitForChild("Lures"))
local PowerUps = require(Shared:WaitForChild("data"):WaitForChild("PowerUps"))
local Peddler = require(Shared:WaitForChild("data"):WaitForChild("Peddler"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local PeddlerScreen = {}

type LureDef = { name: string, tier: number, scrap: number, zoneBonus: number }
type PowerUpDef = { name: string, seconds: number, effect: string, value: number, sellable: boolean }

local lureDefs: { [string]: LureDef } = Lures.Lures
local powerUpDefs: { [string]: PowerUpDef } = PowerUps

-- One offer card. Children are built once and refreshed in place.
type Card = {
	frame: Frame,
	chip: Frame,
	chipLabel: TextLabel,
	name: TextLabel,
	description: TextLabel,
	price: TextLabel,
	buy: Frame,
	sold: Frame,
}

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close
-- button reaches down to 0.155, so the body starts under it.
local BODY_Y = 0.17
local COUNTDOWN_H = 0.07
local ROW_Y = 0.26
local ROW_H = 1 - Theme.Margin - ROW_Y
local CARD_ASPECT = 0.52 -- width / height; three fit across the 1.35 panel with the gaps
local CARD_GAP = 0.03 -- of the row width
local REFRESH_SECONDS = 1 -- the countdown line (and the visit-over check) refresh this often

local gui: ScreenGui? = nil
local panel: Frame? = nil
local countdown: TextLabel? = nil
local cards: { Card } = {}
local open = false
local heartbeat: RBXScriptConnection? = nil
local accumulator = 0
local pending = false -- one server request in flight at a time
local bought: { [number]: boolean } = {} -- offer indices the server confirmed this visit
local visitEndsAt: number? = nil -- identifies the visit the bought set belongs to
local onGrant: ((Types.GrantResult) -> ())? = nil

-- Helpers ----------------------------------------------------------------

local function formatTime(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.ceil(seconds))
	if total >= 3600 then
		return Strings.TIME_HM:format(total // 3600, (total % 3600) // 60)
	elseif total >= 60 then
		return Strings.TIME_MS:format(total // 60, total % 60)
	end
	return Strings.TIME_S:format(total)
end

-- Recolours a Builder.button in place (lip, face, thick stroke, gradient).
local function recolorButton(container: Frame, color: Color3)
	local dark = Builder.darker(color)
	local lip = container:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = dark
	end
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.BackgroundColor3 = color
		for _, child in ipairs(face:GetChildren()) do
			if child:IsA("UIStroke") and child.Thickness == Theme.Stroke.Button then
				child.Color = dark
			elseif child:IsA("UIGradient") then
				child.Color = ColorSequence.new(Builder.lighter(color), color)
			end
		end
	end
end

-- Recolours a card's accent: its stroke and the kind chip (fill and gradient).
local function recolorCard(card: Card, accent: Color3)
	local stroke = card.frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = accent
	end
	card.chip.BackgroundColor3 = accent
	local gradient = card.chip:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Builder.lighter(accent), accent)
	end
end

local function offerName(offer: Types.PeddlerOffer): string
	if offer.kind == "lure" then
		return Builder.text("LURE_" .. offer.id)
	elseif offer.kind == "powerUp" then
		return Builder.text("POWERUP_" .. offer.id)
	end
	return Builder.text("OFFER_" .. offer.id)
end

local function offerDescription(offer: Types.PeddlerOffer): string
	if offer.kind == "lure" then
		local def = lureDefs[offer.id]
		return if def then Strings.SHOP_LURE_EFFECT:format(math.floor(def.zoneBonus * 100)) else ""
	elseif offer.kind == "powerUp" then
		local def = powerUpDefs[offer.id]
		local duration = formatTime(if def then def.seconds else 0)
		return Builder.text("POWERUP_DESC_" .. offer.id):format(duration)
	elseif offer.kind == "scrap" then
		return Strings.PEDDLER_SCRAP_DESC:format(Builder.formatNumber(offer.amount or 0))
	elseif offer.kind == "egg" then
		return Strings.PEDDLER_EGG_DESC:format(Builder.text("TIER_" .. (offer.tier or "Common")))
	end
	return ""
end

local function offerPrice(offer: Types.PeddlerOffer): string
	if offer.scrap == 0 then
		return Strings.PEDDLER_FREE
	end
	return Strings.SHOP_SCRAP_PRICE:format(Builder.formatNumber(offer.scrap))
end

-- The card's accent: eggs take their tier colour, the rest the colour of what they are.
local function offerAccent(offer: Types.PeddlerOffer): Color3
	if offer.kind == "egg" then
		return Builder.tierColor(offer.tier or "Common")
	elseif offer.kind == "powerUp" then
		return Theme.Colors.Select
	elseif offer.kind == "scrap" then
		return Theme.Colors.Featured
	end
	return Theme.Colors.Confirm
end

-- Server calls -------------------------------------------------------------

local function handleRefusal(index: number, reason: any)
	if reason == "AlreadyBought" then
		bought[index] = true
		Toast.Show(Strings.TOAST_PEDDLER_SOLD, Theme.Rarity.Common)
	elseif reason == "NotEnoughScrap" then
		Toast.Show(Strings.TOAST_NOT_ENOUGH_SCRAP, Theme.Colors.Close)
	else
		print(("[%s] PeddlerBuy refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

local refresh: () -> ()

-- Asks the server for offer `index`. Runs in its own thread: callers are taps. The server pushes
-- ScrapChanged and InventoryChanged itself; this toasts the answer and hands an egg's GrantResult on.
local function buy(index: number)
	if pending then
		return
	end
	local visit = State.GetPeddler()
	local offer = if visit then visit.offers[index] else nil
	if not offer then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason, raw = Net.func("PeddlerBuy"):InvokeServer(index)
		pending = false
		if ok == true then
			bought[index] = true
			Toast.Show(Strings.TOAST_PEDDLER_BOUGHT:format(offerName(offer)), Theme.Colors.Confirm)
			refresh()
			local grant = raw :: Types.GrantResult?
			local callback = onGrant
			if grant and callback then
				callback(grant)
			end
		else
			handleRefusal(index, reason)
			refresh()
		end
	end)
end

-- Cards ---------------------------------------------------------------------

-- A white card: kind chip on top, name, description, price, and the Buy button (or the Sold chip
-- that stands in for it) along the bottom.
local function buildCard(parent: Frame, index: number): Card
	local frame = Builder.frame({
		parent = parent,
		name = "Offer" .. index,
		size = UDim2.fromScale(1, 1),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Rarity.Common,
		aspect = CARD_ASPECT,
		zIndex = 3,
	})
	frame.LayoutOrder = index

	local chip = Builder.pill({
		parent = frame,
		name = "Kind",
		position = UDim2.fromScale(0.5, 0.04),
		size = UDim2.fromScale(0.84, 0.11),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Rarity.Common,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(chip, Theme.Rarity.Common)
	local chipLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	local name = Builder.label({
		parent = frame,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.05, 0.17),
		size = UDim2.fromScale(0.9, 0.14),
		zIndex = 4,
	})
	local description = Builder.label({
		parent = frame,
		name = "Description",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.05, 0.32),
		size = UDim2.fromScale(0.9, 0.26),
		zIndex = 4,
	})
	local price = Builder.label({
		parent = frame,
		name = "Price",
		text = "",
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.05, 0.6),
		size = UDim2.fromScale(0.9, 0.12),
		zIndex = 4,
	})

	local buy = Builder.button({
		parent = frame,
		name = "Buy",
		text = Strings.PEDDLER_BUY,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.5, 0.95),
		size = UDim2.fromScale(0.84, 0.21),
		anchor = Vector2.new(0.5, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		buy(index)
	end)

	local sold = Builder.pill({
		parent = frame,
		name = "Sold",
		position = UDim2.fromScale(0.5, 0.95),
		size = UDim2.fromScale(0.84, 0.19),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Rarity.Common,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(Theme.Rarity.Common),
		zIndex = 4,
	})
	Builder.gradient(sold, Theme.Rarity.Common)
	Builder.label({
		parent = sold,
		name = "Text",
		text = Strings.PEDDLER_SOLD,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	sold.Visible = false

	return {
		frame = frame,
		chip = chip,
		chipLabel = chipLabel,
		name = name,
		description = description,
		price = price,
		buy = buy,
		sold = sold,
	}
end

-- Refresh ----------------------------------------------------------------------

-- The countdown line; when the visit is over the screen closes and says so.
local function refreshCountdown()
	local label = countdown
	if not open or not label then
		return
	end
	local visit = State.GetPeddler()
	local left = if visit then visit.endsAt - State.Now() else 0
	if not visit or left <= 0 then
		PeddlerScreen.Close()
		Toast.Show(Strings.PEDDLER_GONE, Theme.Rarity.Common)
		return
	end
	label.Text = Strings.PEDDLER_LEAVES:format(formatTime(left))
end

refresh = function()
	if not open or not State.Has() then
		return
	end
	local visit = State.GetPeddler()
	if visit and visit.endsAt ~= visitEndsAt then
		-- A new visit: nothing is sold yet.
		visitEndsAt = visit.endsAt
		bought = {}
	end
	local profile = State.Get()
	for index, card in ipairs(cards) do
		local offer: Types.PeddlerOffer? = if visit then visit.offers[index] else nil
		if not offer then
			card.frame.Visible = false
			continue
		end
		card.frame.Visible = true
		recolorCard(card, offerAccent(offer))
		card.chipLabel.Text = Builder.text("PEDDLER_KIND_" .. offer.kind)
		card.name.Text = offerName(offer)
		card.description.Text = offerDescription(offer)
		card.price.Text = offerPrice(offer)
		local isSold = bought[index] == true
		card.buy.Visible = not isSold
		card.sold.Visible = isSold
		local affordable = profile.scrap >= offer.scrap
		recolorButton(card.buy, if affordable then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
	refreshCountdown()
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("PeddlerScreen", 20)
	root.Enabled = false
	gui = root

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = 1
	backdrop.Parent = root
	backdrop.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		PeddlerScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.8, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = 1.35,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, gold for the Peddler, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.42, 0.11),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Featured)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.PEDDLER_TITLE,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	Builder.button({
		parent = body,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(0.985, 0.015),
		size = UDim2.fromScale(0.11, 0.14),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 4,
	}, function()
		PeddlerScreen.Close()
	end)

	countdown = Builder.label({
		parent = body,
		name = "Countdown",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, BODY_Y),
		size = UDim2.fromScale(0.6, COUNTDOWN_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})

	-- The offer row: three aspect-fit cards centred, built once and refreshed in place.
	local row = Builder.frame({
		parent = body,
		name = "Offers",
		position = UDim2.fromScale(Theme.Margin, ROW_Y),
		size = UDim2.fromScale(1 - Theme.Margin * 2, ROW_H),
		zIndex = 3,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(CARD_GAP, 0)
	layout.Parent = row
	cards = {}
	for index = 1, Peddler.OffersPerVisit do
		table.insert(cards, buildCard(row, index))
	end

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "peddler", "scrap", "inventory" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
end

-- Public API -------------------------------------------------------------

function PeddlerScreen.IsOpen(): boolean
	return open
end

function PeddlerScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	if not open then
		return -- the visit was already over: refresh closed the screen
	end
	root.Enabled = true
	Builder.open(body)
	accumulator = 0
	if heartbeat then
		heartbeat:Disconnect()
	end
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < REFRESH_SECONDS then
			return
		end
		accumulator = 0
		refreshCountdown()
	end)
end

function PeddlerScreen.Close()
	if not open then
		return
	end
	open = false
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	local root, body = gui, panel
	if root and body then
		Builder.close(body, function()
			if not open then
				root.Enabled = false
			end
		end)
	elseif root then
		root.Enabled = false
	end
end

function PeddlerScreen.Toggle()
	if open then
		PeddlerScreen.Close()
	else
		PeddlerScreen.Open()
	end
end

-- The bootstrap's hook for an egg: the server's GrantResult for a bought alien, to show as a Reveal.
function PeddlerScreen.OnGrant(callback: (Types.GrantResult) -> ())
	onGrant = callback
end

return PeddlerScreen
