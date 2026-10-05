--!strict
-- StarterPlayerScripts.Client.UI.ShopScreen: the Shop panel. Three tabs down the left (Lures, Gear,
-- Robux); the active one is brighter and nudged right so it reads as raised. Lures: one row card per
-- lure with its zone bonus, how many are held, the price and a Craft button. Gear: one row card per
-- item with its speed bonus, the price and a Buy button that becomes an Owned chip. Robux: a single
-- "coming with the launch shop" line. Every value shown is read from the profile mirror in State and
-- the shared data tables; every Craft or Buy tap asks the server (ShopBuy) and a refusal becomes a
-- toast. Nothing here decides an outcome: the server pushes the new Scrap, inventory and gear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Lures = require(Shared:WaitForChild("data"):WaitForChild("Lures"))
local Gear = require(Shared:WaitForChild("data"):WaitForChild("Gear"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local ShopScreen = {}

type LureDef = { name: string, tier: number, scrap: number, zoneBonus: number }
type GearDef = { name: string, speedMultiplier: number, scrap: number, unlock: string }
type GearField = "boots" | "hoverboard" | "glider"
type GearItem = { id: string, field: GearField, def: GearDef }
type Tab = "Lures" | "Gear" | "Robux"
type Kind = "lure" | "gear"

local lureDefs: { [string]: LureDef } = Lures.Lures
local lureOrder: { string } = Lures.Order

-- The gear the shop sells, in display order, each with the profile.gear field that marks it owned.
-- Literal keys: the Gear table also carries BaseWalkSpeed, so it cannot be cast to a dictionary.
local GEAR_ITEMS: { GearItem } = {
	{ id = "Boots", field = "boots", def = Gear.Boots },
	{ id = "Hoverboard", field = "hoverboard", def = Gear.Hoverboard },
	{ id = "Glider", field = "glider", def = Gear.Glider },
}
-- Gear the server answers Locked for until its unlock lands (Glider: first launch). Drawn grey; the
-- tap still goes to the server, which refuses, and the refusal becomes the TOAST_LOCKED_GEAR toast.
local LOCKED_GEAR: { [string]: boolean } = { Glider = true }

local TABS: { Tab } = { "Lures", "Gear", "Robux" }

-- One row card. Children are built once and refreshed in place.
type Row = {
	id: string,
	card: Frame,
	name: TextLabel,
	effect: TextLabel,
	price: TextLabel,
	heldLabel: TextLabel?, -- lures only
	button: Frame,
	face: TextButton,
	owned: Frame?, -- gear only
}

type TabButton = { tab: Tab, button: Frame, page: Frame }

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close
-- button reaches down to 0.155, so the body starts under it.
local BODY_Y = 0.17
local BODY_H = 1 - Theme.Margin - BODY_Y
local TAB_W = 0.2
local TAB_H = 0.15 -- 44 px at iPhone SE height
local TAB_GAP = 0.02
local TAB_NUDGE = 0.015 -- the active tab sits this much further right: the raised look
local CONTENT_X = 0.25
local CONTENT_W = 1 - Theme.Margin - CONTENT_X
local ROW_H = 0.3 -- of the content height
local ROW_GAP = 0.03

local gui: ScreenGui? = nil
local panel: Frame? = nil
local tabButtons: { TabButton } = {}
local lureRows: { Row } = {}
local gearRows: { Row } = {}
local activeTab: Tab = "Lures"
local open = false
local pending = false -- one server request in flight at a time

-- Helpers ----------------------------------------------------------------

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

local function itemName(kind: Kind, id: string): string
	return Builder.text((if kind == "lure" then "LURE_" else "GEAR_") .. id)
end

local function priceText(scrap: number): string
	return Strings.SHOP_SCRAP_PRICE:format(Builder.formatNumber(scrap))
end

local function ownsGear(profile: Types.Profile, field: GearField): boolean
	local gear = profile.gear
	if field == "boots" then
		return gear.boots == true
	elseif field == "hoverboard" then
		return gear.hoverboard == true
	end
	return gear.glider == true
end

-- Server calls -------------------------------------------------------------

local function handleRefusal(kind: Kind, id: string, reason: any)
	if reason == "NotEnoughScrap" then
		Toast.Show(Strings.TOAST_NOT_ENOUGH_SCRAP, Theme.Colors.Close)
	elseif reason == "Locked" then
		Toast.Show(Strings.TOAST_LOCKED_GEAR:format(itemName(kind, id)), Theme.Rarity.Common)
	else
		print(("[%s] ShopBuy refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

-- Asks the server to craft a lure or buy gear. Runs in its own thread: callers are taps. The server
-- pushes ScrapChanged, InventoryChanged and GearChanged itself; this only toasts the answer.
local function buy(kind: Kind, id: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("ShopBuy"):InvokeServer(kind, id)
		pending = false
		if ok == true then
			if kind == "lure" then
				Toast.Show(Strings.TOAST_CRAFTED:format(itemName(kind, id)), Theme.Colors.Confirm)
			else
				Toast.Show(Strings.TOAST_BOUGHT:format(itemName(kind, id)), Theme.Colors.Featured)
			end
		else
			handleRefusal(kind, id, reason)
		end
	end)
end

-- Rows ---------------------------------------------------------------------

-- A white card with the name top left, the effect line and price beneath it, and the action button
-- down the right. Lures also get a Held chip beside the name; gear also gets an Owned chip that
-- stands in for the button once the server says it is owned.
local function buildRow(parent: Frame, index: number, kind: Kind, id: string, buttonText: string): Row
	local card = Builder.frame({
		parent = parent,
		name = id,
		size = UDim2.fromScale(1, ROW_H),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	card.LayoutOrder = index

	local withHeld = kind == "lure"
	local name = Builder.label({
		parent = card,
		name = "Name",
		text = itemName(kind, id),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.03, 0.06),
		size = UDim2.fromScale(if withHeld then 0.41 else 0.65, 0.36),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})

	local heldLabel: TextLabel? = nil
	if withHeld then
		local held = Builder.pill({
			parent = card,
			name = "Held",
			position = UDim2.fromScale(0.46, 0.09),
			size = UDim2.fromScale(0.22, 0.3),
			color = Theme.Colors.Trough,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 4,
		})
		Builder.gradient(held, Theme.Colors.Trough)
		heldLabel = Builder.label({
			parent = held,
			name = "Text",
			text = Strings.SHOP_HELD:format(0),
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 5,
		})
	end

	local effect = Builder.label({
		parent = card,
		name = "Effect",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.03, 0.45),
		size = UDim2.fromScale(0.65, 0.25),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	effect.TextTruncate = Enum.TextTruncate.AtEnd -- the long lure line trims on a phone instead of spilling
	local price = Builder.label({
		parent = card,
		name = "Price",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.03, 0.71),
		size = UDim2.fromScale(0.65, 0.25),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})

	local button = Builder.button({
		parent = card,
		name = "Action",
		text = buttonText,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(1 - 0.03, 0.5),
		size = UDim2.fromScale(0.28, 0.66),
		anchor = Vector2.new(1, 0.5),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		buy(kind, id)
	end)
	local face = button:FindFirstChild("Face") :: TextButton

	local owned: Frame? = nil
	if kind == "gear" then
		local chip = Builder.pill({
			parent = card,
			name = "Owned",
			position = UDim2.fromScale(1 - 0.03, 0.5),
			size = UDim2.fromScale(0.28, 0.6),
			anchor = Vector2.new(1, 0.5),
			color = Theme.Colors.Confirm,
			stroke = Theme.Stroke.Button,
			strokeColor = Builder.darker(Theme.Colors.Confirm),
			zIndex = 4,
		})
		Builder.gradient(chip, Theme.Colors.Confirm)
		Builder.label({
			parent = chip,
			name = "Text",
			text = Strings.SHOP_OWNED,
			textSize = Theme.TextSize.Label,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.75),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 5,
		})
		chip.Visible = false
		owned = chip
	end

	return {
		id = id,
		card = card,
		name = name,
		effect = effect,
		price = price,
		heldLabel = heldLabel,
		button = button,
		face = face,
		owned = owned,
	}
end

local function listLayout(parent: Frame)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = parent
end

local function buildLuresPage(parent: Frame)
	listLayout(parent)
	for index, id in ipairs(lureOrder) do
		local def = lureDefs[id]
		if def then
			table.insert(lureRows, buildRow(parent, index, "lure", id, Strings.SHOP_CRAFT:format(itemName("lure", id))))
		end
	end
end

local function buildGearPage(parent: Frame)
	listLayout(parent)
	for index, item in ipairs(GEAR_ITEMS) do
		table.insert(gearRows, buildRow(parent, index, "gear", item.id, Strings.SHOP_BUY:format(itemName("gear", item.id))))
	end
end

local function buildRobuxPage(parent: Frame)
	Builder.label({
		parent = parent,
		name = "Soon",
		text = Strings.SHOP_ROBUX_SOON,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.8, 0.2),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
end

-- Refresh ----------------------------------------------------------------------

local function refreshLures(profile: Types.Profile)
	for _, row in ipairs(lureRows) do
		local def = lureDefs[row.id]
		if not def then
			row.card.Visible = false
			continue
		end
		row.card.Visible = true
		row.effect.Text = Strings.SHOP_LURE_EFFECT:format(math.floor(def.zoneBonus * 100))
		row.price.Text = priceText(def.scrap)
		if row.heldLabel then
			row.heldLabel.Text = Strings.SHOP_HELD:format(profile.inventory.lures[row.id] or 0)
		end
		local affordable = profile.scrap >= def.scrap
		recolorButton(row.button, if affordable then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
end

local function refreshGear(profile: Types.Profile)
	for index, row in ipairs(gearRows) do
		local item = GEAR_ITEMS[index]
		if not item then
			row.card.Visible = false
			continue
		end
		row.card.Visible = true
		local def = item.def
		local bonus = math.floor((def.speedMultiplier - 1) * 100)
		row.effect.Visible = true
		row.effect.Text = if bonus > 0 then Strings.SHOP_GEAR_SPEED:format(bonus) else Strings.SHOP_GEAR_LOCKED
		row.price.Text = priceText(def.scrap)
		local isOwned = ownsGear(profile, item.field)
		row.button.Visible = not isOwned
		if row.owned then
			row.owned.Visible = isOwned
		end
		local affordable = profile.scrap >= def.scrap and not LOCKED_GEAR[item.id]
		recolorButton(row.button, if affordable then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	refreshLures(profile)
	refreshGear(profile)
end

-- Tabs ---------------------------------------------------------------------------

local function setTab(tab: Tab)
	activeTab = tab
	for _, entry in ipairs(tabButtons) do
		local active = entry.tab == tab
		entry.page.Visible = active
		entry.button.Position = UDim2.fromScale(Theme.Margin + (if active then TAB_NUDGE else 0), entry.button.Position.Y.Scale)
		recolorButton(entry.button, if active then Theme.Colors.Select else Builder.darker(Theme.Colors.Select, 0.3))
	end
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("ShopScreen", 20)
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
		ShopScreen.Close()
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

	-- Header tab straddling the top edge, green for the shop, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.42, 0.11),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Confirm,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Confirm)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.SHOP_TITLE,
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
		ShopScreen.Close()
	end)

	-- Content area to the right of the tab column: one page per tab, only the active one visible.
	local content = Builder.frame({
		parent = body,
		name = "Content",
		position = UDim2.fromScale(CONTENT_X, BODY_Y),
		size = UDim2.fromScale(CONTENT_W, BODY_H),
		zIndex = 3,
	})

	-- Tab column down the left. Each tab is a chunky button; setTab raises and brightens the active one.
	tabButtons = {}
	for index = 1, #TABS do
		local tab: Tab = TABS[index]
		local page = Builder.frame({
			parent = content,
			name = tab,
			zIndex = 3,
		})
		page.Visible = false
		if tab == "Lures" then
			buildLuresPage(page)
		elseif tab == "Gear" then
			buildGearPage(page)
		else
			buildRobuxPage(page)
		end
		local button = Builder.button({
			parent = body,
			name = "Tab" .. tab,
			text = Builder.text("SHOP_TAB_" .. tab),
			color = Theme.Colors.Select,
			position = UDim2.fromScale(Theme.Margin, BODY_Y + (index - 1) * (TAB_H + TAB_GAP)),
			size = UDim2.fromScale(TAB_W, TAB_H),
			textSize = Theme.TextSize.Label,
			zIndex = 4,
		}, function()
			if activeTab ~= tab then
				setTab(tab)
			end
		end)
		table.insert(tabButtons, { tab = tab, button = button, page = page })
	end
	setTab(activeTab)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "inventory", "gear", "scrap" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
end

-- Public API -------------------------------------------------------------

function ShopScreen.IsOpen(): boolean
	return open
end

function ShopScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function ShopScreen.Close()
	if not open then
		return
	end
	open = false
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

function ShopScreen.Toggle()
	if open then
		ShopScreen.Close()
	else
		ShopScreen.Open()
	end
end

return ShopScreen
