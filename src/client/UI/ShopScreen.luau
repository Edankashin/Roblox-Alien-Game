--!strict
-- StarterPlayerScripts.Client.UI.ShopScreen: the Shop panel. Three tabs down the left (Lures, Gear,
-- Robux); the active one is brighter and nudged right so it reads as raised. Lures: one row card per
-- lure with its zone bonus, how many are held, the price and a Craft button. Gear: one row card per
-- item with its speed bonus (or, for a radar, its minimap range), the price and a Buy button that
-- becomes an Owned chip. Robux: the launch shop, a scrolling column with one section per Shop.Launch
-- entry: the Starter Pack as one large gold tile with the Rare picker, then Passes and Boosts as small
-- tiles two to a row, each with a price button that becomes an Owned or Claimed chip. Every value shown
-- is read from the profile and purchases mirrors in State and the shared data tables; every Craft, Buy
-- or pick tap asks the server (ShopBuy, SetStarterChoice, PromptPurchase) and a refusal becomes a toast.
-- Nothing here decides an outcome and nothing here knows a product id: the server opens Roblox's own
-- purchase prompt, grants on the receipt and pushes PurchasesChanged, which redraws the page.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Lures = require(Shared:WaitForChild("data"):WaitForChild("Lures"))
local Gear = require(Shared:WaitForChild("data"):WaitForChild("Gear"))
local Radar = require(Shared:WaitForChild("data"):WaitForChild("Radar"))
local Shop = require(Shared:WaitForChild("data"):WaitForChild("Shop"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Screens = require(script.Parent.Screens)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local ShopScreen = {}

type LureDef = { name: string, tier: number, scrap: number, zoneBonus: number }
type GearDef = { name: string, speedMultiplier: number, scrap: number, unlock: string }
type RadarTier = { name: string, range: number, scrap: number, unlock: string? }
type GearField = "boots" | "hoverboard" | "glider" | "radar"
-- A Gear tab row. Movement gear carries its Gear def (the speed bonus); a radar carries the tier it
-- grants, and its range is read from the Radar table. `scrap` is the price either way.
type GearItem = { id: string, field: GearField, scrap: number, def: GearDef?, radarTier: number? }
type Tab = "Lures" | "Gear" | "Robux"
type Kind = "lure" | "gear"
type ShopItem = Shop.ShopItem
type LaunchSection = { section: string, items: { string } }

local lureDefs: { [string]: LureDef } = Lures.Lures
local lureOrder: { string } = Lures.Order
-- Literal number keys, some rows without `unlock`: cast through any the way the server's Shop does.
local radarTiers: { [number]: RadarTier } = (Radar :: any) :: { [number]: RadarTier }
local RADAR_MK1 = 1
local RADAR_MK2 = 2

-- The gear the shop sells, in display order, each with the profile.gear field that marks it owned.
-- Literal keys: the Gear table also carries BaseWalkSpeed, so it cannot be cast to a dictionary.
local GEAR_ITEMS: { GearItem } = {
	{ id = "Boots", field = "boots", scrap = Gear.Boots.scrap, def = Gear.Boots },
	{ id = "Hoverboard", field = "hoverboard", scrap = Gear.Hoverboard.scrap, def = Gear.Hoverboard },
	{ id = "Radar1", field = "radar", scrap = radarTiers[RADAR_MK1].scrap, radarTier = RADAR_MK1 },
	{ id = "Radar2", field = "radar", scrap = radarTiers[RADAR_MK2].scrap, radarTier = RADAR_MK2 },
	{ id = "Glider", field = "glider", scrap = Gear.Glider.scrap, def = Gear.Glider },
}
-- Gear the server answers Locked for until its unlock lands. FirstLaunch gear (the Glider) is drawn
-- grey while only the starting world is unlocked and buyable once a second world is; Radar Mk2 waits on
-- the same second world and on Mk1 being held. The tap still goes to the server, which decides, and a
-- refusal becomes the TOAST_LOCKED_GEAR toast.
-- The ship has launched when any world past the first is unlocked (the home planet, world 0, never counts),
-- the same rule the server's Shop reads.
local FIRST_WORLD = 1
local function hasLaunched(profile: Types.Profile): boolean
	for _, worldId in ipairs(profile.world.unlocked) do
		if worldId > FIRST_WORLD then
			return true
		end
	end
	return false
end

local function gearLocked(profile: Types.Profile, item: GearItem): boolean
	local def = item.def
	if def and def.unlock == "FirstLaunch" then
		return not hasLaunched(profile)
	end
	if item.radarTier == RADAR_MK2 then
		return not hasLaunched(profile) or profile.gear.radar < RADAR_MK1
	end
	return false
end

local TABS: { Tab } = { "Lures", "Gear", "Robux" }

-- The Robux catalog by id, the launch sections and the Starter Pack's choices, all from data/Shop.
local shopItems: { [string]: ShopItem } = {}
for _, item in ipairs(Shop.Items) do
	shopItems[item.id] = item
end
local launchSections: { LaunchSection } = Shop.Launch
local starterChoices: { string } = Shop.StarterChoices
local shopGrants: { [string]: { Shop.ShopGrant } } = Shop.Grants
local speciesById: { [string]: Types.SpeciesDef } = Species.ById
-- Small-tile colour per launch section; the Featured section's large tile is Featured gold.
local SECTION_COLORS: { [string]: Color3 } = { Passes = Theme.Colors.Select, Boosts = Theme.Colors.Codex, Spins = Theme.Colors.Close }
local FEATURED_SECTION = "Featured"

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

-- A Robux tile, large or small. Built once and refreshed in place: the price button hides behind the
-- Owned / Claimed chip once the server says the item is held.
type RobuxTile = {
	item: ShopItem,
	card: Frame,
	button: Frame,
	face: TextButton,
	chip: Frame,
	chipText: TextLabel,
}
-- One Shop.Launch section on the Robux page: its heading and the block holding its tiles, laid out by
-- a two-column grid (small tiles) or a vertical stack (large tiles).
type RobuxSection = { heading: TextLabel, block: Frame, grid: UIGridLayout?, stack: UIListLayout?, tiles: { RobuxTile } }
type Picker = { species: string, button: Frame }

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
-- A row's icon (a lure or gear picture, once uploaded): a square at the card's left edge, vertically
-- centred, ROW_ICON_H of the row's height. The panel keeps PANEL_ASPECT (width over height), so a row's
-- own aspect follows from the layout fractions above, and the square's width as a fraction of the row is
-- its height over that. The three text lines shift right by the square's width plus a gap to clear it.
local PANEL_ASPECT = 1.35
local ROW_ASPECT = CONTENT_W * PANEL_ASPECT / (BODY_H * ROW_H)
local ROW_INSET = 0.03 -- the row's left padding, of its width
local ROW_ICON_H = 0.7
local ROW_ICON_W = ROW_ICON_H / ROW_ASPECT
local ROW_ICON_GAP = 0.015 -- of the row's width, between the square and the text

-- Robux page layout. Heights are fractions of the page's visible height (the scroller window); the
-- canvas is as many pages tall as the sections need, so layoutRobux divides each child's Scale by
-- the page count. The content area is 0.81 of the panel high, so 0.11 of it is the 0.09-panel tap floor.
local RX_HEADING_H = 0.09 -- about 7% of the panel
local RX_GAP = 0.03 -- between headings and blocks
local RX_FEATURED_H = 0.85 -- the large tile
local RX_COLS = 2
local RX_COL_GAP = 0.03 -- of the page width
local RX_TILE_W = (1 - RX_COL_GAP * (RX_COLS - 1)) / RX_COLS
local RX_TILE_ASPECT = 1.6 -- small tiles, width over height
local SCROLLBAR_PX = 6 -- thickness, not a Size: a thin dark bar on the right
-- Inside a small tile (fractions of the tile). The button is 0.34 of a 0.30-panel tile: 0.10 of the panel.
local TILE_INSET = 0.05
local TILE_NAME_Y, TILE_NAME_H = 0.04, 0.24
local TILE_DESC_Y, TILE_DESC_H = 0.29, 0.2
local TILE_NOTE_Y, TILE_NOTE_H = 0.49, 0.12
local TILE_BUTTON_Y, TILE_BUTTON_H = 0.62, 0.34
-- Inside the large tile (0.69 of the panel high): picker buttons 0.13 and the price button 0.16 of the panel.
local BIG_INSET = 0.04
local BIG_NAME_Y, BIG_NAME_H = 0.03, 0.16
local BIG_DESC_Y, BIG_DESC_H = 0.2, 0.2
local BIG_PICK_Y, BIG_PICK_H = 0.43, 0.19
local BIG_PICKED_Y, BIG_PICKED_H = 0.64, 0.08
local BIG_BUTTON_Y, BIG_BUTTON_H = 0.74, 0.23
local PICK_GAP = 0.03 -- between the picker buttons, of the row width
local CHIP_INSET = 0.02 -- the chip sits this much inside the button it replaces

local gui: ScreenGui? = nil
local panel: Frame? = nil
local tabButtons: { TabButton } = {}
local lureRows: { Row } = {}
local gearRows: { Row } = {}
local activeTab: Tab = "Lures"
local open = false
local pending = false -- one server request in flight at a time

local robuxScroller: ScrollingFrame? = nil
local robuxList: UIListLayout? = nil
local robuxSections: { RobuxSection } = {}
local pickers: { Picker } = {}
local pickerRow: Frame? = nil
local pickedLabel: TextLabel? = nil
local policyAsked = false
local policyKnown = false
local paidRandomRestricted = true -- paid random items stay hidden until GetPolicy says otherwise
-- The purchases state as of the last redraw, so a push can be compared to find what was just granted.
local lastPurchases: Types.PurchasesState = { purchases = {}, passes = {}, starterSpecies = nil }
local lastPurchasesPushed = false

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

local function robuxItemName(id: string): string
	return Builder.text("SHOP_ITEM_" .. id)
end

local function speciesName(id: string): string
	local def = speciesById[id]
	return if def then def.name else id
end

-- True for a product whose grant lets the player pick the species beforehand (the Starter Pack).
local function needsChoice(id: string): boolean
	local grants = shopGrants[id]
	if grants then
		for _, grant in ipairs(grants) do
			if grant.choose == true then
				return true
			end
		end
	end
	return false
end

local function priceText(scrap: number): string
	return Strings.SHOP_SCRAP_PRICE:format(Builder.formatNumber(scrap))
end

-- Owned as the server's profile says: a flag for movement gear, the held tier for a radar.
local function ownsGear(profile: Types.Profile, item: GearItem): boolean
	local gear = profile.gear
	if item.field == "boots" then
		return gear.boots == true
	elseif item.field == "hoverboard" then
		return gear.hoverboard == true
	elseif item.field == "radar" then
		return gear.radar >= (item.radarTier or RADAR_MK1)
	end
	return gear.glider == true
end

-- The effect line: the minimap range for a radar (Mk2 says what it adds, or the unlock note while it is
-- locked), the walk-speed bonus for movement gear, or, for gear that does nothing yet (the Glider), the
-- unlock note while it is locked and what it will do once it is not.
local function effectText(profile: Types.Profile, item: GearItem): string
	local radarTier = item.radarTier
	if radarTier then
		local row = radarTiers[radarTier]
		local range = if row then row.range else 0
		if radarTier == RADAR_MK2 then
			return if gearLocked(profile, item) then Strings.SHOP_RADAR_LOCKED else Strings.SHOP_GEAR_RADAR2:format(range)
		end
		return Strings.SHOP_GEAR_RADAR:format(range)
	end
	local def = item.def
	local bonus = if def then math.floor((def.speedMultiplier - 1) * 100) else 0
	if bonus > 0 then
		return Strings.SHOP_GEAR_SPEED:format(bonus)
	end
	return if gearLocked(profile, item) then Strings.SHOP_GEAR_LOCKED else Strings.SHOP_GEAR_SOON
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

-- Pulls the purchases state from the server: on the first open when the join push has not landed yet
-- (seed only: a push that already arrived wins), or whenever the server says the mirror is stale.
local function fetchPurchases(seedOnly: boolean)
	task.spawn(function()
		local ok, result = pcall(function()
			return Net.func("GetPurchases"):InvokeServer()
		end)
		if ok and type(result) == "table" then
			if seedOnly then
				State.SeedPurchases(result)
			else
				State.SetPurchases(result)
			end
		elseif not ok then
			print(("[%s] GetPurchases failed: %s"):format(Config.WorkingTitle, tostring(result)))
		end
	end)
end

local function handlePromptRefusal(id: string, reason: any)
	if reason == "Restricted" then
		Toast.Show(Strings.SHOP_RESTRICTED, Theme.Rarity.Common)
	elseif reason == "AlreadyOwned" then
		fetchPurchases(false) -- the mirror is behind the server; its answer redraws the tile as held
	elseif reason == "NoChoice" then
		Toast.Show(Strings.SHOP_STARTER_PICK, Theme.Colors.Select)
	elseif reason == "NotLive" then
		Toast.Show(Strings.TOAST_PURCHASE_FAILED, Theme.Colors.Close)
		print(("[%s] PromptPurchase %s refused: NotLive (no product id in the Creator Dashboard yet)"):format(Config.WorkingTitle, id))
	else
		print(("[%s] PromptPurchase %s refused: %s"):format(Config.WorkingTitle, id, tostring(reason)))
	end
end

-- Asks the server to open Roblox's purchase prompt for an item. On ok nothing more happens here: the
-- Roblox dialog takes over, the server grants on the receipt and PurchasesChanged redraws the page.
local function promptPurchase(id: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("PromptPurchase"):InvokeServer(id)
		pending = false
		if ok ~= true then
			handlePromptRefusal(id, reason)
		end
	end)
end

-- Stores the Starter Pack's Rare on the server. The server pushes PurchasesChanged with the choice;
-- if that push has not landed a moment later, the state is pulled once so the picker catches up.
local function chooseStarter(species: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("SetStarterChoice"):InvokeServer(species)
		pending = false
		if ok == true then
			task.delay(1, function()
				local state = State.GetPurchases()
				if state.starterSpecies ~= species then
					fetchPurchases(false)
				end
			end)
		elseif reason == "AlreadyOwned" then
			fetchPurchases(false)
		else
			print(("[%s] SetStarterChoice %s refused: %s"):format(Config.WorkingTitle, species, tostring(reason)))
		end
	end)
end

-- Rows ---------------------------------------------------------------------

-- A white card with the name top left, the effect line and price beneath it, and the action button
-- down the right. Lures also get a Held chip beside the name; gear also gets an Owned chip that
-- stands in for the button once the server says it is owned.
local function buildRow(parent: Instance, index: number, kind: Kind, id: string, buttonText: string): Row
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

	-- The icon, when the pack has one for this id (gear ids resolve through the alias; the Glider has none):
	-- the name, effect and price lines start further right and keep their right edges.
	local icon = Builder.icon({
		parent = card,
		name = "Icon",
		key = id,
		position = UDim2.fromScale(ROW_INSET, 0.5),
		size = UDim2.fromScale(ROW_ICON_W, ROW_ICON_H),
		anchor = Vector2.new(0, 0.5),
		zIndex = 4,
	})
	local shift = if icon then ROW_ICON_W + ROW_ICON_GAP else 0

	local withHeld = kind == "lure"
	local name = Builder.label({
		parent = card,
		name = "Name",
		text = itemName(kind, id),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(ROW_INSET + shift, 0.06),
		size = UDim2.fromScale((if withHeld then 0.41 else 0.65) - shift, 0.36),
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
		position = UDim2.fromScale(ROW_INSET + shift, 0.45),
		size = UDim2.fromScale(0.65 - shift, 0.25),
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
		position = UDim2.fromScale(ROW_INSET + shift, 0.71),
		size = UDim2.fromScale(0.65 - shift, 0.25),
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

local function listLayout(parent: Instance): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = parent
	return layout
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

-- More than three gear rows of ROW_H do not fit the content height (five take 1.62 of it), so the Gear tab
-- is a scrolling column with the thin dark bar, like the Robux page. Children of a ScrollingFrame scale
-- against the canvas, which is `pages` visible heights tall, so each row's height and the gap are divided
-- by `pages` and a row keeps exactly the size it had in the plain list. Rows are Scale-sized and the
-- canvas needs no pixels: it only depends on how many items GEAR_ITEMS holds.
local function buildGearPage(parent: Frame)
	local count = #GEAR_ITEMS
	local pages = math.max(1, count * ROW_H + (count - 1) * ROW_GAP)
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Column"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.ZIndex = 3
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroller.CanvasSize = UDim2.fromScale(0, pages)
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Trough
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.Parent = parent
	listLayout(scroller).Padding = UDim.new(ROW_GAP / pages, 0)
	for index, item in ipairs(GEAR_ITEMS) do
		local row = buildRow(scroller, index, "gear", item.id, Strings.SHOP_BUY:format(itemName("gear", item.id)))
		row.card.Size = UDim2.fromScale(1, ROW_H / pages)
		table.insert(gearRows, row)
	end
end

-- Robux tiles ------------------------------------------------------------------

-- The grey Owned / Claimed chip that stands in for a price button once the server says the item is
-- held. Hidden until refreshRobux shows it.
local function buildChip(parent: Frame, position: UDim2, size: UDim2): (Frame, TextLabel)
	local chip = Builder.pill({
		parent = parent,
		name = "Held",
		position = position,
		size = size,
		anchor = Vector2.new(0.5, 0),
		color = Theme.Rarity.Common,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(Theme.Rarity.Common),
		zIndex = 4,
	})
	Builder.gradient(chip, Theme.Rarity.Common)
	local text = Builder.label({
		parent = chip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	chip.Visible = false
	return chip, text
end

-- A small tile: section-coloured gradient card, the name, a one-line description, the Everyone note
-- on a shared boost, and the price button along the bottom. The grid sets its size and position.
local function buildSmallTile(parent: Frame, index: number, item: ShopItem, color: Color3): RobuxTile
	local card = Builder.frame({
		parent = parent,
		name = item.id,
		size = UDim2.fromScale(RX_TILE_W, RX_TILE_W / RX_TILE_ASPECT),
		color = color,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(color),
		zIndex = 3,
	})
	card.LayoutOrder = index
	Builder.gradient(card, color)
	Builder.label({
		parent = card,
		name = "Name",
		text = robuxItemName(item.id),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(TILE_INSET, TILE_NAME_Y),
		size = UDim2.fromScale(1 - TILE_INSET * 2, TILE_NAME_H),
		zIndex = 4,
	})
	local desc = Builder.label({
		parent = card,
		name = "Desc",
		text = Builder.text("SHOP_DESC_" .. item.id),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(TILE_INSET, TILE_DESC_Y),
		size = UDim2.fromScale(1 - TILE_INSET * 2, TILE_DESC_H),
		zIndex = 4,
	})
	desc.TextTruncate = Enum.TextTruncate.AtEnd -- one line: shrinks to the minimum size, then trims
	if item.oddsOnWheel then
		-- Paid spins: the odds must be visible before buying. The note line says so, and the whole band from the
		-- description to the note is one tap target (a thumb-sized area, not a 14 px line) that opens the wheel,
		-- which lists every prize with its odds (data/Spins). The Buy button below stays its own target.
		Builder.label({
			parent = card,
			name = "Odds",
			text = Strings.SHOP_SEE_ODDS,
			textSize = Theme.TextSize.Min,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(TILE_INSET, TILE_NOTE_Y),
			size = UDim2.fromScale(1 - TILE_INSET * 2, TILE_NOTE_H),
			zIndex = 4,
		})
		local oddsTap = Instance.new("TextButton")
		oddsTap.Name = "OddsTap"
		oddsTap.Text = ""
		oddsTap.AutoButtonColor = false
		oddsTap.BackgroundTransparency = 1
		oddsTap.BorderSizePixel = 0
		oddsTap.Position = UDim2.fromScale(0, TILE_DESC_Y)
		oddsTap.Size = UDim2.fromScale(1, TILE_NOTE_Y + TILE_NOTE_H - TILE_DESC_Y)
		oddsTap.ZIndex = 5
		oddsTap.Parent = card
		oddsTap.Activated:Connect(function()
			Builder.playSound(Sounds.Click)
			Screens.Open("Gifts")
		end)
	elseif item.paidRandom then
		Builder.label({
			parent = card,
			name = "Everyone",
			text = Strings.SHOP_EVERYONE,
			textSize = Theme.TextSize.Min,
			color = Theme.Colors.Featured,
			position = UDim2.fromScale(TILE_INSET, TILE_NOTE_Y),
			size = UDim2.fromScale(1 - TILE_INSET * 2, TILE_NOTE_H),
			zIndex = 4,
		})
	end
	local button = Builder.button({
		parent = card,
		name = "Buy",
		text = Strings.SHOP_ROBUX_PRICE:format(item.robux),
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.5, TILE_BUTTON_Y),
		size = UDim2.fromScale(1 - TILE_INSET * 2, TILE_BUTTON_H),
		anchor = Vector2.new(0.5, 0),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		promptPurchase(item.id)
	end)
	local face = button:FindFirstChild("Face") :: TextButton
	local chip, chipText = buildChip(
		card,
		UDim2.fromScale(0.5, TILE_BUTTON_Y + CHIP_INSET),
		UDim2.fromScale(1 - TILE_INSET * 2, TILE_BUTTON_H - CHIP_INSET * 2)
	)
	return { item = item, card = card, button = button, face = face, chip = chip, chipText = chipText }
end

-- The large tile: gold gradient card, the name, a two-line description, the Rare picker (one small
-- button per Shop.StarterChoices species) with the chosen name under it, and the price button at the
-- bottom. The stack sets its size.
local function buildFeaturedTile(parent: Frame, index: number, item: ShopItem): RobuxTile
	local color = Theme.Colors.Featured
	local card = Builder.frame({
		parent = parent,
		name = item.id,
		size = UDim2.fromScale(1, 1),
		color = color,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(color),
		zIndex = 3,
	})
	card.LayoutOrder = index
	Builder.gradient(card, color)
	Builder.label({
		parent = card,
		name = "Name",
		text = robuxItemName(item.id),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(BIG_INSET, BIG_NAME_Y),
		size = UDim2.fromScale(1 - BIG_INSET * 2, BIG_NAME_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	Builder.label({
		parent = card,
		name = "Desc",
		text = Builder.text("SHOP_DESC_" .. item.id),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(BIG_INSET, BIG_DESC_Y),
		size = UDim2.fromScale(1 - BIG_INSET * 2, BIG_DESC_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	}) -- TextScaled wraps: two lines at the Body size
	if needsChoice(item.id) then
		local row = Builder.frame({
			parent = card,
			name = "Picker",
			position = UDim2.fromScale(BIG_INSET, BIG_PICK_Y),
			size = UDim2.fromScale(1 - BIG_INSET * 2, BIG_PICK_H),
			zIndex = 4,
		})
		local count = math.max(1, #starterChoices)
		local width = (1 - PICK_GAP * (count - 1)) / count
		for choice, species in ipairs(starterChoices) do
			local button = Builder.button({
				parent = row,
				name = species,
				text = speciesName(species),
				color = Theme.Rarity.Common,
				position = UDim2.fromScale((choice - 1) * (width + PICK_GAP), 0),
				size = UDim2.fromScale(width, 1),
				textSize = Theme.TextSize.Body,
				zIndex = 4,
			}, function()
				chooseStarter(species)
			end)
			table.insert(pickers, { species = species, button = button })
		end
		pickerRow = row
		pickedLabel = Builder.label({
			parent = card,
			name = "Picked",
			text = "",
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(BIG_INSET, BIG_PICKED_Y),
			size = UDim2.fromScale(1 - BIG_INSET * 2, BIG_PICKED_H),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = 4,
		})
	end
	local button = Builder.button({
		parent = card,
		name = "Buy",
		text = Strings.SHOP_STARTER_PICK,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(0.5, BIG_BUTTON_Y),
		size = UDim2.fromScale(1 - BIG_INSET * 2, BIG_BUTTON_H),
		anchor = Vector2.new(0.5, 0),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		promptPurchase(item.id)
	end)
	local face = button:FindFirstChild("Face") :: TextButton
	local chip, chipText = buildChip(
		card,
		UDim2.fromScale(0.5, BIG_BUTTON_Y + CHIP_INSET),
		UDim2.fromScale(1 - BIG_INSET * 2, BIG_BUTTON_H - CHIP_INSET * 2)
	)
	return { item = item, card = card, button = button, face = face, chip = chip, chipText = chipText }
end

-- Sizes the Robux column so every child is a Scale fraction of a canvas exactly as tall as the
-- sections need. Children of a ScrollingFrame scale against the canvas, so every height (in visible
-- pages) is divided by the page count; an automatic canvas would chase Scale-sized children instead.
-- Pixels are only read for the page's width-over-height ratio, which turns a small tile's width and
-- aspect into a height. Sections with nothing visible (Boosts where every item is restricted) fold away.
local function layoutRobux()
	local scroller, list = robuxScroller, robuxList
	if not scroller or not list then
		return
	end
	local window = scroller.AbsoluteWindowSize
	if window.X <= 0 or window.Y <= 0 then
		return
	end
	local aspect = window.X / window.Y
	local gapV = RX_COL_GAP * aspect -- the column gap as a fraction of the visible height
	local tileH = RX_TILE_W / RX_TILE_ASPECT * aspect
	local heights: { number } = {}
	local children = 0
	local total = 0
	for index, section in ipairs(robuxSections) do
		local visible = 0
		for _, tile in ipairs(section.tiles) do
			if tile.card.Visible then
				visible += 1
			end
		end
		local height = 0
		if visible > 0 then
			if section.grid then
				local rows = math.ceil(visible / RX_COLS)
				height = rows * tileH + (rows - 1) * gapV
			else
				height = visible * RX_FEATURED_H + (visible - 1) * gapV
			end
			children += 2 -- heading and block
			total += RX_HEADING_H + height
		end
		heights[index] = height
	end
	total += children * RX_GAP -- the gaps between children, plus breathing room under the last
	local pages = math.max(1, total)
	scroller.CanvasSize = UDim2.fromScale(0, pages)
	list.Padding = UDim.new(RX_GAP / pages, 0)
	for index, section in ipairs(robuxSections) do
		local height = heights[index]
		local shown = height > 0
		section.heading.Visible = shown
		section.block.Visible = shown
		if not shown then
			continue
		end
		section.heading.Size = UDim2.fromScale(1, RX_HEADING_H / pages)
		section.block.Size = UDim2.fromScale(1, height / pages)
		local grid, stack = section.grid, section.stack
		if grid then
			grid.CellSize = UDim2.fromScale(RX_TILE_W, tileH / height)
			grid.CellPadding = UDim2.fromScale(RX_COL_GAP, gapV / height)
		end
		if stack then
			stack.Padding = UDim.new(gapV / height, 0)
			for _, tile in ipairs(section.tiles) do
				tile.card.Size = UDim2.fromScale(1, RX_FEATURED_H / height)
			end
		end
	end
end

-- The launch shop: a scrolling column with a thin dark bar, one heading and one block of tiles per
-- Shop.Launch section. The Featured block stacks large tiles; every other block is a two-column grid.
local function buildRobuxPage(parent: Frame)
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Column"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.ZIndex = 3
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None -- layoutRobux sizes the canvas in Scale
	scroller.CanvasSize = UDim2.fromScale(0, 1)
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Trough
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Top
	list.Padding = UDim.new(RX_GAP, 0)
	list.Parent = scroller

	robuxSections = {}
	pickers = {}
	local order = 0
	for _, entry in ipairs(launchSections) do
		order += 1
		local heading = Builder.label({
			parent = scroller,
			name = entry.section .. "Heading",
			text = Builder.text("SHOP_SECTION_" .. entry.section),
			textSize = Theme.TextSize.Label,
			color = Theme.Colors.Heading,
			strokeColor = Theme.Colors.Black,
			size = UDim2.fromScale(1, RX_HEADING_H),
			zIndex = 3,
		})
		heading.LayoutOrder = order
		order += 1
		local block = Builder.frame({
			parent = scroller,
			name = entry.section,
			size = UDim2.fromScale(1, RX_FEATURED_H),
			zIndex = 3,
		})
		block.LayoutOrder = order
		local tiles: { RobuxTile } = {}
		local grid: UIGridLayout? = nil
		local stack: UIListLayout? = nil
		if entry.section == FEATURED_SECTION then
			local stackLayout = Instance.new("UIListLayout")
			stackLayout.FillDirection = Enum.FillDirection.Vertical
			stackLayout.SortOrder = Enum.SortOrder.LayoutOrder
			stackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			stackLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			stackLayout.Padding = UDim.new(RX_GAP, 0)
			stackLayout.Parent = block
			stack = stackLayout
			for index, id in ipairs(entry.items) do
				local item = shopItems[id]
				if item then
					table.insert(tiles, buildFeaturedTile(block, index, item))
				end
			end
		else
			local cells = Instance.new("UIGridLayout")
			cells.FillDirection = Enum.FillDirection.Horizontal
			cells.FillDirectionMaxCells = RX_COLS
			cells.SortOrder = Enum.SortOrder.LayoutOrder
			cells.HorizontalAlignment = Enum.HorizontalAlignment.Left
			cells.VerticalAlignment = Enum.VerticalAlignment.Top
			cells.StartCorner = Enum.StartCorner.TopLeft
			cells.CellSize = UDim2.fromScale(RX_TILE_W, RX_TILE_W / RX_TILE_ASPECT)
			cells.CellPadding = UDim2.fromScale(RX_COL_GAP, RX_COL_GAP)
			cells.Parent = block
			grid = cells
			local color = SECTION_COLORS[entry.section] or Theme.Rarity.Common
			for index, id in ipairs(entry.items) do
				local item = shopItems[id]
				if item then
					table.insert(tiles, buildSmallTile(block, index, item, color))
				end
			end
		end
		table.insert(robuxSections, { heading = heading, block = block, grid = grid, stack = stack, tiles = tiles })
	end
	robuxScroller = scroller
	robuxList = list
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutRobux)
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
		row.effect.Visible = true
		row.effect.Text = effectText(profile, item)
		row.price.Text = priceText(item.scrap)
		local isOwned = ownsGear(profile, item)
		row.button.Visible = not isOwned
		if row.owned then
			row.owned.Visible = isOwned
		end
		local affordable = profile.scrap >= item.scrap and not gearLocked(profile, item)
		recolorButton(row.button, if affordable then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
end

-- Redraws every Robux tile from the purchases mirror: an owned pass or a claimed once-only product
-- shows its chip instead of the price; the Starter Pack's button stays grey until a Rare is stored;
-- paid random items (Server Luck) show only once GetPolicy has said they are allowed here.
local function refreshRobux()
	local state = State.GetPurchases()
	local showPaidRandom = policyKnown and not paidRandomRestricted
	local packDone = false
	for _, section in ipairs(robuxSections) do
		for _, tile in ipairs(section.tiles) do
			local item = tile.item
			tile.card.Visible = showPaidRandom or not item.paidRandom
			local owned = item.kind == "pass" and state.passes[item.id] == true
			local done = item.once == true and (state.purchases[item.id] or 0) > 0
			local chooses = needsChoice(item.id)
			if chooses and done then
				packDone = true
			end
			tile.button.Visible = not (owned or done)
			tile.chip.Visible = owned or done
			if owned then
				tile.chipText.Text = Strings.SHOP_OWNED_PASS
			elseif done then
				tile.chipText.Text = Strings.SHOP_ONCE_DONE
			elseif chooses and state.starterSpecies == nil then
				tile.face.Text = Strings.SHOP_STARTER_PICK
				recolorButton(tile.button, Theme.Rarity.Common)
			else
				tile.face.Text = Strings.SHOP_ROBUX_PRICE:format(item.robux)
				recolorButton(tile.button, Theme.Colors.Confirm)
			end
		end
	end
	local row = pickerRow
	if row then
		row.Visible = not packDone -- the choice is spent once the pack is claimed
	end
	for _, picker in ipairs(pickers) do
		recolorButton(picker.button, if picker.species == state.starterSpecies then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
	local picked = pickedLabel
	if picked then
		local species = state.starterSpecies
		picked.Text = if species then Strings.SHOP_STARTER_PICKED:format(speciesName(species)) else ""
	end
	layoutRobux()
end

local function refresh()
	if not open then
		return
	end
	if State.Has() then
		local profile = State.Get()
		refreshLures(profile)
		refreshGear(profile)
	end
	refreshRobux()
end

-- A purchases push: anything the server added since the last state (a product count that went up, a
-- pass that appeared) gets its thank-you toast. Passes are only compared against a state that also
-- came from the server, so the join push never thanks the player for passes they already held.
local function onPurchasesChanged()
	local state, pushed = State.GetPurchases()
	if pushed then
		local added: { string } = {}
		for id, count in pairs(state.purchases) do
			if count > (lastPurchases.purchases[id] or 0) then
				table.insert(added, id)
			end
		end
		if lastPurchasesPushed then
			for id, held in pairs(state.passes) do
				if held and not lastPurchases.passes[id] then
					table.insert(added, id)
				end
			end
		end
		table.sort(added)
		for _, id in ipairs(added) do
			Toast.Show(Strings.TOAST_PURCHASE_THANKS:format(robuxItemName(id)), Theme.Colors.Featured)
		end
	end
	lastPurchases = state
	lastPurchasesPushed = pushed
	refresh()
end

-- Asks once whether paid random items are restricted for this player (PolicyService on the server).
-- Until the answer lands the Server Luck tiles stay hidden; a failed call is asked again next open.
local function fetchPolicy()
	if policyAsked then
		return
	end
	policyAsked = true
	task.spawn(function()
		local ok, result = pcall(function()
			return Net.func("GetPolicy"):InvokeServer()
		end)
		if ok and type(result) == "table" then
			paidRandomRestricted = result.paidRandomRestricted == true
			policyKnown = true
			refresh()
		else
			policyAsked = false
			print(("[%s] GetPolicy failed: %s"):format(Config.WorkingTitle, tostring(result)))
		end
	end)
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
	if tab == "Robux" and open then
		refreshRobux()
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
		aspect = PANEL_ASPECT,
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
	-- "world" too: a launch (or /world) unlocks a second world, which unlocks the Glider row while the Shop is open.
	for _, topic in ipairs({ "inventory", "gear", "scrap", "world" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
	-- Purchases: remember what the server has said so far, then thank the player for whatever a push adds.
	lastPurchases, lastPurchasesPushed = State.GetPurchases()
	State.OnChanged("purchases", onPurchasesChanged)
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
	fetchPolicy()
	local _, purchasesPushed = State.GetPurchases()
	if not purchasesPushed then
		fetchPurchases(true) -- the join push has not landed: ask once so Owned chips are right
	end
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
