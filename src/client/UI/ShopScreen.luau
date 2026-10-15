--!strict
-- StarterPlayerScripts.Client.UI.ShopScreen: the Shop, a full-screen shelf (UI Playbook "Shop shelf"; the reference is the TikTok
-- clip ZPLSQA4aX, media/tiktok/NOTES.md batch 7). While it is open a violet-to-navy ground with slow rays covers the HUD (display
-- order 26, over the HUD's own menu column at 25): what stays is the Scrap pill top right and the red X. A rail of five tabs runs
-- down the left (Featured, Passes, Scrap, Boosts, Spins: data/Shop Categories, each a category colour, never a rarity colour);
-- one row of tall cards scrolls across the rest, in the same order, and a tab is a scroll target, not a filter: the active tab
-- follows the row's position. A card is a category-coloured gradient with a ribbon plate on its top edge, the name, a one-line
-- note, a big picture (the icon pack, or a letter until the id is uploaded), an optional starburst seal and the price pill; its
-- body is one tap target that opens a detail card with the long description, so nothing the old rows said is lost. Robux cards
-- (data/Shop Launch sections) ask the server to open Roblox's purchase prompt; the Scrap tab holds the lures and the gear
-- (data/Shop Categories `scrap`), bought with ShopBuy exactly as before. Under every Robux price sits the grey "about $N.NN"
-- (ShopMath.AboutLine); the Starter Pack is the one wide card, with the Rare picker, and the one that shines. Paid random items
-- (Server Luck, the Spins) show only where GetPolicy allows, a Spins card's note is the link to the wheel and its odds table, and
-- an item with no dashboard id yet shows a grey SOON pill that says "Coming soon" on tap.
-- Every value shown is read from the profile, the purchases mirror in State and the data tables; every tap asks the server
-- (ShopBuy, SetStarterChoice, PromptPurchase) and a refusal becomes a toast. Nothing here decides an outcome and nothing here
-- knows a product id: the server opens the prompt, grants on the receipt and pushes PurchasesChanged, which redraws the shelf.
-- Motion (each has a Reduced Motion form, which is none): the tabs drop in and the cards slide in tilted, a card lifts under a
-- mouse, one shine crosses the featured card, the rays turn, a tab or chevron tap scrolls with a springy ease. Layout reads the
-- shelf window's pixels once per change (layoutShelf); every Position and Size is a Scale.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
local ShopMath = require(Shared:WaitForChild("ShopMath"))
local ShelfMath = require(Shared:WaitForChild("ShelfMath"))
local Builder = require(script.Parent.Builder)
local Screens = require(script.Parent.Screens)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Prefs = require(script.Parent.Parent.Prefs)

local ShopScreen = {}

type LureDef = { name: string, tier: number, scrap: number, zoneBonus: number }
type GearDef = { name: string, speedMultiplier: number, scrap: number, unlock: string }
type RadarTier = { name: string, range: number, scrap: number, unlock: string? }
type GearField = "boots" | "hoverboard" | "glider" | "radar"
-- A gear card. Movement gear carries its Gear def (the speed bonus); a radar carries the tier it grants, and its range is read
-- from the Radar table. `scrap` is the price either way.
type GearItem = { id: string, field: GearField, scrap: number, def: GearDef?, radarTier: number? }
type Kind = "robux" | "lure" | "gear"
type ShopItem = Shop.ShopItem
type CardDef = Shop.CardDef
type Band = Shop.Band

-- One card on the shelf. Three frames stack: `slot` is placed by layoutShelf, `mover` carries the entrance (slide and tilt),
-- `card` is the visible face and lifts under a mouse. Everything is built once and refreshed in place.
type CardView = {
	id: string,
	kind: Kind,
	category: string,
	def: CardDef,
	units: number,
	item: ShopItem?,
	gearItem: GearItem?,
	slot: Frame,
	mover: Frame,
	card: Frame,
	note: TextLabel,
	below: TextLabel,
	button: Frame,
	face: TextButton,
	chip: Frame,
	chipText: TextLabel,
	visible: boolean,
	done: boolean, -- owned or claimed: the chip stands where the price pill was
}
type TabView = { id: string, color: Color3, holder: Frame, button: Frame, bang: Frame, fresh: Frame, visible: boolean, row: number, index: number }
type Picker = { species: string, button: Frame, row: Frame }

local lureDefs: { [string]: LureDef } = Lures.Lures
-- Literal number keys, some rows without `unlock`: cast through any the way the server's Shop does.
local radarTiers: { [number]: RadarTier } = (Radar :: any) :: { [number]: RadarTier }
local RADAR_MK1 = 1
local RADAR_MK2 = 2

-- The gear the shop sells, each with the profile.gear field that marks it owned. Literal keys: the Gear table also carries
-- BaseWalkSpeed, so it cannot be cast to a dictionary. The shelf's order is data/Shop Categories `scrap`.
local GEAR_BY_ID: { [string]: GearItem } = {
	Boots = { id = "Boots", field = "boots", scrap = Gear.Boots.scrap, def = Gear.Boots },
	Hoverboard = { id = "Hoverboard", field = "hoverboard", scrap = Gear.Hoverboard.scrap, def = Gear.Hoverboard },
	Radar1 = { id = "Radar1", field = "radar", scrap = radarTiers[RADAR_MK1].scrap, radarTier = RADAR_MK1 },
	Radar2 = { id = "Radar2", field = "radar", scrap = radarTiers[RADAR_MK2].scrap, radarTier = RADAR_MK2 },
	Glider = { id = "Glider", field = "glider", scrap = Gear.Glider.scrap, def = Gear.Glider },
}
-- Gear the server answers Locked for until its unlock lands. FirstLaunch gear (the Glider) is drawn grey while only the starting
-- world is unlocked and buyable once a second world is; Radar Mk2 waits on the same second world and on Mk1 being held. The tap
-- still goes to the server, which decides, and a refusal becomes the TOAST_LOCKED_GEAR toast. The ship has launched when any
-- world past the first is unlocked (the home planet, world 0, never counts), the same rule the server's Shop reads.
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

local shopItems: { [string]: ShopItem } = {}
for _, item in ipairs(Shop.Items) do
	shopItems[item.id] = item
end
local launchSections: { { section: string, items: { string } } } = Shop.Launch
local starterChoices: { string } = Shop.StarterChoices
local shopGrants: { [string]: { Shop.ShopGrant } } = Shop.Grants
local speciesById: { [string]: Types.SpeciesDef } = Species.ById

local SHELF = Shop.Shelf
local MOTION = SHELF.Motion
local DISPLAY_ORDER = 26 -- over the HUD (10), the tutorial hint (15), the modal screens (20) and the HUD's menu column (25); under reveals (30) and toasts (40)
local DETAIL_Z = 30 -- the detail card's layer inside the stage, over the rail, the header and the shelf

local gui: ScreenGui? = nil
local stage: Frame? = nil
local shelf: ScrollingFrame? = nil
local sunburst: Frame? = nil
local thumb: Frame? = nil
local leftChevron: Frame? = nil
local rightChevron: Frame? = nil
local edgeFade: Frame? = nil
local scrapLabel: TextLabel? = nil
local detailLayer: Frame? = nil
local detailHeader: Frame? = nil
local detailName: TextLabel? = nil
local detailText: TextLabel? = nil
local tabs: { TabView } = {}
local views: { CardView } = {}
local viewById: { [string]: CardView } = {}
local pickers: { Picker } = {}
local open = false
local pending = false -- one server request in flight at a time
local policyAsked = false
local policyKnown = false
local paidRandomRestricted = true -- paid random items stay hidden until GetPolicy says otherwise
-- The purchases state as of the last redraw, so a push can be compared to find what was just granted.
local lastPurchases: Types.PurchasesState = { purchases = {}, passes = {}, starterSpecies = nil }
local lastPurchasesPushed = false

-- Layout state, set by layoutShelf: the window and the row in px, the offset each visible tab scrolls to, and how far the row goes.
local windowPx = Vector2.zero
local canvasPx = 0
local cardPx = 0
local starts: { number } = {}
local startTabs: { TabView } = {}
local maxOffset = 0
local layoutDirty = true
local activeTab: TabView? = nil
local scrollTween: Tween? = nil
local autoScrolling = false
local dragging = false
local entranceTweens: { Tween } = {}
local sunburstTween: Tween? = nil
local stopShine: (() -> ())? = nil

-- Helpers ----------------------------------------------------------------

local function pos(b: Band): UDim2
	return UDim2.fromScale(b.X, b.Y)
end

local function siz(b: Band): UDim2
	return UDim2.fromScale(b.W, b.H)
end

-- A card's width over its height in px: `units` card widths and the gaps between them.
local function cardAspect(units: number): number
	return SHELF.CardAspect * (units + SHELF.CardGap * (units - 1))
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

local function scrapName(kind: "lure" | "gear", id: string): string
	return Builder.text((if kind == "lure" then "LURE_" else "GEAR_") .. id)
end

local function robuxItemName(id: string): string
	return Builder.text("SHOP_ITEM_" .. id)
end

local function cardName(kind: Kind, id: string): string
	if kind == "robux" then
		return robuxItemName(id)
	end
	return scrapName(kind, id)
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

-- The long effect line (the detail card): the minimap range for a radar (Mk2 says what it adds, or the unlock note while it is
-- locked), the walk-speed bonus for movement gear, or, for gear that does nothing yet (the Glider), the unlock note while it is
-- locked and what it will do once it is not.
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

-- The same facts as one short line for a 120 px card (each at most 98 px at 14 px).
local function gearNote(profile: Types.Profile, item: GearItem): string
	local radarTier = item.radarTier
	if radarTier then
		local row = radarTiers[radarTier]
		local range = if row then row.range else 0
		if radarTier == RADAR_MK2 then
			return if gearLocked(profile, item) then Strings.SHOP_RADAR_LOCKED_NOTE else Strings.SHOP_GEAR_RADAR2_NOTE:format(range)
		end
		return Strings.SHOP_GEAR_RADAR_NOTE:format(range)
	end
	local def = item.def
	local bonus = if def then math.floor((def.speedMultiplier - 1) * 100) else 0
	if bonus > 0 then
		return Strings.SHOP_GEAR_SPEED_NOTE:format(bonus)
	end
	return if gearLocked(profile, item) then Strings.SHOP_GEAR_LOCKED_NOTE else Strings.SHOP_GEAR_SOON_NOTE
end

-- A Robux card's note from its data row: the string, with the minutes of a shared boost or the count of a power-up bundle read
-- from the grant row so the line never disagrees with what the server grants.
local function robuxNote(item: ShopItem, noteId: string?): string
	if not noteId then
		return ""
	end
	local text = Builder.text("SHOP_NOTE_" .. noteId)
	local grants = shopGrants[item.id]
	if grants then
		for _, grant in ipairs(grants) do
			if noteId == "Everyone" and grant.kind == "serverLuck" and grant.seconds then
				return text:format(math.floor(grant.seconds / 60))
			elseif noteId == "Uses" and grant.kind == "powerUp" and grant.amount then
				return text:format(grant.amount)
			end
		end
	end
	return text
end

-- The long description the detail card shows.
local function descriptionOf(view: CardView): string
	if view.kind == "robux" then
		return Builder.text("SHOP_DESC_" .. view.id)
	end
	if view.kind == "lure" then
		local def = lureDefs[view.id]
		return if def then Strings.SHOP_LURE_EFFECT:format(math.floor(def.zoneBonus * 100)) else ""
	end
	local item = view.gearItem
	if item and State.Has() then
		return effectText(State.Get(), item)
	end
	return ""
end

-- Server calls -------------------------------------------------------------

local function handleRefusal(kind: "lure" | "gear", id: string, reason: any)
	if reason == "NotEnoughScrap" then
		Toast.Show(Strings.TOAST_NOT_ENOUGH_SCRAP, Theme.Colors.Close)
	elseif reason == "Locked" then
		Toast.Show(Strings.TOAST_LOCKED_GEAR:format(scrapName(kind, id)), Theme.Rarity.Common)
	else
		print(("[%s] ShopBuy refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

-- Asks the server to craft a lure or buy gear. Runs in its own thread: callers are taps. The server
-- pushes ScrapChanged, InventoryChanged and GearChanged itself; this only toasts the answer.
local function buy(kind: "lure" | "gear", id: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("ShopBuy"):InvokeServer(kind, id)
		pending = false
		if ok == true then
			if kind == "lure" then
				Toast.Show(Strings.TOAST_CRAFTED:format(scrapName(kind, id)), Theme.Colors.Confirm)
			else
				Toast.Show(Strings.TOAST_BOUGHT:format(scrapName(kind, id)), Theme.Colors.Featured)
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
		fetchPurchases(false) -- the mirror is behind the server; its answer redraws the card as held
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
-- Roblox dialog takes over, the server grants on the receipt and PurchasesChanged redraws the shelf.
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

-- A tap on a price pill: a SOON pill says so (no server call: nothing is live to buy), a Robux card opens the purchase prompt,
-- a Scrap card crafts or buys. The server still decides every one of them.
local function onPillTap(id: string)
	local view = viewById[id]
	if not view then
		return
	end
	local item = view.item
	if item then
		if not ShelfMath.IsLive(item) then
			Toast.Show(Strings.COMING_SOON, Theme.Colors.Featured)
			return
		end
		promptPurchase(id)
	elseif view.kind == "lure" or view.kind == "gear" then
		buy(view.kind, id)
	end
end

-- Detail card ---------------------------------------------------------------

local function hideDetail()
	local layer = detailLayer
	if layer then
		layer.Visible = false
	end
end

-- A card in front of the shelf: the item's name over its category colour and the long description. It is built on first use.
local function buildDetail(parent: Frame)
	local layer = Builder.frame({ parent = parent, name = "Detail", zIndex = DETAIL_Z })
	layer.Visible = false
	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.BorderSizePixel = 0
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Theme.Colors.Black
	dim.BackgroundTransparency = 1 - Theme.Backdrop
	dim.ZIndex = DETAIL_Z
	dim.Parent = layer
	dim.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		hideDetail()
	end)
	local panel = Builder.frame({
		parent = layer,
		name = "Panel",
		position = UDim2.fromScale(SHELF.Detail.Panel.X, SHELF.Detail.Panel.Y),
		size = siz(SHELF.Detail.Panel),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		zIndex = DETAIL_Z + 1,
	})
	panel.Active = true -- a tap on the card's body is not a tap on the dim behind it
	local header = Builder.frame({
		parent = panel,
		name = "Header",
		size = UDim2.fromScale(1, SHELF.Detail.HeaderH),
		color = Theme.Colors.White,
		corner = Theme.Corner.Panel,
		zIndex = DETAIL_Z + 2,
	})
	detailHeader = header
	detailName = Builder.label({
		parent = header,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Title,
		position = pos(SHELF.Detail.Name),
		size = siz(SHELF.Detail.Name),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = DETAIL_Z + 3,
	})
	-- Navy on the cream panel, no stroke: reading text, not a title (UI Playbook "Input fields and hints").
	detailText = Builder.label({
		parent = panel,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = pos(SHELF.Detail.Text),
		size = siz(SHELF.Detail.Text),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = DETAIL_Z + 2,
	})
	Builder.button({
		parent = panel,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = pos(SHELF.Detail.Close),
		size = siz(SHELF.Detail.Close),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = DETAIL_Z + 4,
	}, hideDetail)
	detailLayer = layer
end

local function showDetail(id: string)
	local view = viewById[id]
	local parent = stage
	if not view or not parent then
		return
	end
	if not detailLayer then
		buildDetail(parent)
	end
	local layer, header, name, text = detailLayer, detailHeader, detailName, detailText
	if not layer or not header or not name or not text then
		return
	end
	local category = Theme.Colors.White
	for _, tab in ipairs(tabs) do
		if tab.id == view.category then
			category = tab.color
		end
	end
	header.BackgroundColor3 = category
	name.Text = cardName(view.kind, id)
	text.Text = descriptionOf(view)
	layer.Visible = true
end

-- Cards ---------------------------------------------------------------------

-- A card's face: light tint at the top, the category colour through the middle, a deep shade at the bottom. The frame is
-- white because a gradient multiplies its frame's colour, so the stops are the colours.
local function cardGradient(target: Frame, color: Color3)
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Builder.lighter(color, 0.3)),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, Builder.darker(color, 0.45)),
	})
	fade.Parent = target
end

local function lift(card: Frame, up: boolean)
	if Prefs.ReducedMotion() then
		return
	end
	local info = TweenInfo.new(MOTION.HoverSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(card, info, { Position = UDim2.fromScale(0, if up then -MOTION.HoverLift else 0) }):Play()
end

-- A transparent button over `parent`, a click on every tap: the card's body, a link.
local function tapArea(parent: GuiObject, name: string, z: number, onTap: () -> ()): TextButton
	local area = Instance.new("TextButton")
	area.Name = name
	area.Text = ""
	area.AutoButtonColor = false
	area.BackgroundTransparency = 1
	area.BorderSizePixel = 0
	area.Size = UDim2.fromScale(1, 1)
	area.ZIndex = z
	area.Parent = parent
	area.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		onTap()
	end)
	return area
end

local function buildPicker(card: Frame)
	local row = Builder.frame({
		parent = card,
		name = "Picker",
		position = pos(SHELF.Featured.Picker),
		size = siz(SHELF.Featured.Picker),
		zIndex = 8,
	})
	local count = math.max(1, #starterChoices)
	local gap = SHELF.Featured.PickerGap
	local height = (1 - gap * (count - 1)) / count
	for index, species in ipairs(starterChoices) do
		local button = Builder.button({
			parent = row,
			name = species,
			text = speciesName(species),
			color = Theme.Rarity.Common,
			position = UDim2.fromScale(0, (index - 1) * (height + gap)),
			size = UDim2.fromScale(1, height),
			textSize = Theme.TextSize.Body,
			hit = true,
			zIndex = 8,
		}, function()
			chooseStarter(species)
		end)
		table.insert(pickers, { species = species, button = button, row = row })
	end
end

local function buildCard(parent: ScrollingFrame, id: string, kind: Kind, category: string, color: Color3): CardView
	local def: CardDef = Shop.Cards[id] or {}
	local units = def.width or 1
	local featured = units > 1
	local L = if featured then SHELF.Featured else SHELF.Card
	local aspect = cardAspect(units)

	local slot = Builder.frame({ parent = parent, name = id, zIndex = 3 })
	slot.Visible = false -- layoutShelf places it
	local mover = Builder.frame({ parent = slot, name = "Mover", zIndex = 3 })
	local card = Builder.frame({
		parent = mover,
		name = "Card",
		color = Theme.Colors.White,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		gloss = true,
		zIndex = 4,
	})
	cardGradient(card, color)
	-- The whole card is one tap target (the detail card) and the hover lift's trigger, under every label and button. The labels
	-- on a card are inert so a tap on them lands here; a drag scrolls the shelf instead.
	local body = tapArea(card, "Body", 5, function()
		showDetail(id)
	end)
	body.MouseEnter:Connect(function()
		lift(card, true)
	end)
	body.MouseLeave:Connect(function()
		lift(card, false)
	end)

	-- The picture: a lighter disc, then the icon, or the letter until its id is uploaded.
	local iconBand = L.Icon
	Builder.frame({
		parent = card,
		name = "Glow",
		position = UDim2.fromScale(iconBand.X + iconBand.W / 2, iconBand.Y + iconBand.H / 2),
		size = siz(iconBand),
		anchor = Vector2.new(0.5, 0.5),
		color = Builder.lighter(color, SHELF.Glow.Lighten),
		transparency = SHELF.Glow.Alpha,
		corner = Theme.Corner.Pill,
		aspect = 1,
		zIndex = 6,
	})
	local picture = Builder.icon({
		parent = card,
		name = "Icon",
		key = def.icon or id,
		position = pos(iconBand),
		size = siz(iconBand),
		zIndex = 7,
	})
	if not picture then
		Builder.label({
			parent = card,
			name = "Glyph",
			text = Builder.text("SHOP_GLYPH_" .. id),
			textSize = Theme.TextSize.Reveal,
			position = pos(iconBand),
			size = siz(iconBand),
			zIndex = 7,
		})
	end

	Builder.label({
		parent = card,
		name = "Name",
		text = cardName(kind, id),
		textSize = if featured then Theme.TextSize.Label else Theme.TextSize.Body,
		position = pos(L.Name),
		size = siz(L.Name),
		zIndex = 7,
	})
	local note = Builder.label({
		parent = card,
		name = "Note",
		text = "",
		textSize = Theme.TextSize.Body,
		position = pos(L.Note),
		size = siz(L.Note),
		zIndex = 7,
	})
	-- "about $N.NN" under a Robux price and "Held: N" under a lure: one 14 px line (the label's size is pinned to the floor, so
	-- the preferred text size never grows it), trimmed with an ellipsis rather than wrapped onto the card's edge.
	local below = Builder.label({
		parent = card,
		name = "Below",
		text = "",
		textSize = Theme.TextSize.Min,
		color = Theme.Rarity.Common,
		position = pos(L.Below),
		size = siz(L.Below),
		zIndex = 7,
	})
	below.TextTruncate = Enum.TextTruncate.AtEnd

	local button = Builder.button({
		parent = card,
		name = "Buy",
		text = "",
		color = Theme.Colors.Confirm,
		position = pos(L.Pill),
		size = siz(L.Pill),
		textSize = Theme.TextSize.Body,
		hit = true,
		zIndex = 8,
	}, function()
		onPillTap(id)
	end)
	local face = button:FindFirstChild("Face") :: TextButton
	-- The grey Owned / Claimed chip that stands where the pill was once the item is held. A plain frame that sinks taps.
	local chip = Builder.pill({
		parent = card,
		name = "Held",
		position = pos(L.Pill),
		size = siz(L.Pill),
		color = Theme.Rarity.Common,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(Theme.Rarity.Common),
		zIndex = 8,
	})
	Builder.gradient(chip, Theme.Rarity.Common)
	chip.Active = true
	local chipText = Builder.label({
		parent = chip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 9,
	})
	chip.Visible = false

	local ribbonDef = if def.ribbon then Shop.Ribbons[def.ribbon] else nil
	if def.ribbon and ribbonDef then
		Builder.ribbon({
			parent = card,
			name = "Ribbon",
			text = Builder.text("SHOP_RIBBON_" .. def.ribbon),
			color = Theme.Hex(ribbonDef.color),
			aspect = L.Ribbon.W * aspect / L.Ribbon.H,
			position = pos(L.Ribbon),
			size = siz(L.Ribbon),
			zIndex = 10,
		})
	end
	local sealDef = if def.seal then Shop.Seals[def.seal] else nil
	if def.seal and sealDef then
		Builder.seal({
			parent = card,
			name = "Seal",
			text = Builder.text("SHOP_SEAL_" .. def.seal),
			color = Theme.Hex(sealDef.color),
			position = UDim2.fromScale(L.Seal.X, L.Seal.Y),
			size = UDim2.fromScale(L.Seal.W, L.Seal.W * aspect),
			anchor = Vector2.new(0.5, 0.5),
			rotation = SHELF.SealTilt,
			zIndex = 11,
		})
	end

	local item: ShopItem? = if kind == "robux" then shopItems[id] else nil
	if item then
		note.Text = robuxNote(item, def.note)
		if def.note == "Everyone" then
			note.TextColor3 = Theme.Colors.Featured
		elseif def.note == "SeeOdds" then
			-- The link to the wheel and its odds table (data/Spins, summing to 100, no dud): gold and underlined, with a hit area of
			-- at least the tap floor around the line, over the labels it overlaps.
			note.TextColor3 = Theme.Colors.Featured
			note.RichText = true
			note.Text = "<u>" .. note.Text .. "</u>"
			local link = tapArea(card, "OddsLink", 12, function()
				Screens.Open("Gifts")
			end)
			link.AnchorPoint = Vector2.new(0.5, 0.5)
			link.Position = UDim2.fromScale(L.Note.X + L.Note.W / 2, L.Note.Y + L.Note.H / 2)
			link.Size = siz(L.Note)
			local floor = Instance.new("UISizeConstraint")
			floor.MinSize = Vector2.new(Theme.TapMin, Theme.TapMin)
			floor.Parent = link
		end
	end
	if featured and needsChoice(id) then
		buildPicker(card)
	end

	local view: CardView = {
		id = id,
		kind = kind,
		category = category,
		def = def,
		units = units,
		item = item,
		gearItem = if kind == "gear" then GEAR_BY_ID[id] else nil,
		slot = slot,
		mover = mover,
		card = card,
		note = note,
		below = below,
		button = button,
		face = face,
		chip = chip,
		chipText = chipText,
		visible = false,
		done = false,
	}
	return view
end

-- Refresh ----------------------------------------------------------------------

local function setPill(view: CardView, text: string, color: Color3)
	view.face.Text = text
	recolorButton(view.button, color)
end

-- A held item: the chip takes the pill's place and the line under it is cleared.
local function showChip(view: CardView, text: string)
	view.button.Visible = false
	view.chip.Visible = true
	view.chipText.Text = text
	view.below.Text = ""
	view.done = true
end

local function showPill(view: CardView)
	view.button.Visible = true
	view.chip.Visible = false
	view.done = false
end

-- Redraws a Robux card from the purchases mirror: an owned pass or a claimed once-only product shows its chip instead of the
-- price (and loses its about-line); the Starter Pack's pill stays grey until a Rare is stored, its price and about-line still
-- showing; an item with no dashboard id yet is a grey SOON pill with no price under it; paid random items show only once
-- GetPolicy has said they are allowed here.
local function refreshRobuxCard(view: CardView, state: Types.PurchasesState, showPaidRandom: boolean)
	local item = view.item
	if not item then
		return
	end
	local visible = showPaidRandom or not item.paidRandom
	if view.visible ~= visible then
		view.visible = visible
		layoutDirty = true
	end
	local owned = item.kind == "pass" and state.passes[item.id] == true
	local claimed = item.once == true and (state.purchases[item.id] or 0) > 0
	if owned then
		showChip(view, Strings.SHOP_OWNED_PASS)
		return
	elseif claimed then
		showChip(view, Strings.SHOP_ONCE_DONE)
		return
	end
	showPill(view)
	local about = ShopMath.AboutLine(item.robux, Shop.RealCurrency, Strings.SHOP_ABOUT_PRICE)
	if not ShelfMath.IsLive(item) then
		setPill(view, Strings.SHOP_SOON, Theme.Rarity.Common)
		view.below.Text = ""
	elseif needsChoice(item.id) and state.starterSpecies == nil then
		setPill(view, Strings.SHOP_STARTER_PICK, Theme.Rarity.Common)
		view.below.Text = about
	else
		setPill(view, Strings.SHOP_ROBUX_PRICE:format(item.robux), Theme.Colors.Confirm)
		view.below.Text = about
	end
end

local function refreshScrapCard(view: CardView, profile: Types.Profile)
	local shown = view.kind ~= "lure" or lureDefs[view.id] ~= nil
	if view.visible ~= shown then
		view.visible = shown
		layoutDirty = true
	end
	if view.kind == "lure" then
		local def = lureDefs[view.id]
		if not def then
			return
		end
		view.note.Text = Strings.SHOP_LURE_NOTE:format(math.floor(def.zoneBonus * 100))
		view.below.Text = Strings.SHOP_HELD:format(profile.inventory.lures[view.id] or 0)
		view.below.TextColor3 = Theme.Colors.White
		showPill(view)
		setPill(view, priceText(def.scrap), if profile.scrap >= def.scrap then Theme.Colors.Confirm else Theme.Rarity.Common)
		return
	end
	local item = view.gearItem
	if not item then
		return
	end
	view.note.Text = gearNote(profile, item)
	if ownsGear(profile, item) then
		showChip(view, Strings.SHOP_OWNED)
		return
	end
	showPill(view)
	view.below.Text = ""
	local affordable = profile.scrap >= item.scrap and not gearLocked(profile, item)
	setPill(view, priceText(item.scrap), if affordable then Theme.Colors.Confirm else Theme.Rarity.Common)
end

-- Where a tab sits: down the rail in the order of the tabs that show, the active one nudged right (the raised look).
local function tabPosition(tab: TabView, active: boolean): UDim2
	local rail = SHELF.Rail
	return UDim2.fromScale(rail.X + (if active then rail.Nudge else 0), rail.Y + (tab.row - 1) * (rail.TabH + rail.Gap))
end

local function setActive(tab: TabView?)
	if tab == activeTab then
		return
	end
	activeTab = tab
	for _, entry in ipairs(tabs) do
		local active = entry == tab
		entry.button.Position = tabPosition(entry, active)
		recolorButton(entry.button, if active then entry.color else Builder.darker(entry.color, 0.3))
	end
end

-- Which tabs show (a category with a card on the shelf), their order down the rail, and their chips: a red "!" while a deal card
-- is unclaimed and NEW while a new card is on the shelf (both are flags on the card's data row).
local function refreshTabs()
	local row = 0
	for _, tab in ipairs(tabs) do
		local any, deal, fresh = false, false, false
		for _, view in ipairs(views) do
			if view.category == tab.id and view.visible then
				any = true
				deal = deal or (view.def.deal == true and not view.done)
				fresh = fresh or view.def.new == true
			end
		end
		tab.visible = any
		tab.holder.Visible = any
		tab.bang.Visible = deal
		tab.fresh.Visible = fresh
		if any then
			row += 1
		end
		tab.row = row
		tab.button.Position = tabPosition(tab, tab == activeTab)
	end
end

-- Layout ------------------------------------------------------------------------

-- Places every visible card along the row and sizes the canvas. The window's pixels are read here (the one place), because a
-- card's width follows its height (so it is the same shape in any window) and a child of a scrolling frame is a Scale of the
-- canvas, which is as wide as the row needs. Also finds the offset each tab scrolls to.
local function layoutShelf()
	local frame = shelf
	if not frame then
		return
	end
	local window = frame.AbsoluteWindowSize
	if window.X <= 0 or window.Y <= 0 then
		return
	end
	layoutDirty = false
	windowPx = window
	local cardH = window.Y * SHELF.CardH / SHELF.Window.H
	local cardW = cardH * SHELF.CardAspect
	cardPx = cardW
	local gap = cardW * SHELF.CardGap
	local pad = cardW * SHELF.EndPad
	local top = (SHELF.CardTop - SHELF.Window.Y) / SHELF.Window.H
	local shown: { CardView } = {}
	local widths: { number } = {}
	for _, view in ipairs(views) do
		view.slot.Visible = view.visible
		if view.visible then
			table.insert(shown, view)
			table.insert(widths, view.units * cardW + (view.units - 1) * gap)
		end
	end
	local lefts, total = ShelfMath.Place(widths, gap, pad)
	local canvas = math.max(total, window.X)
	canvasPx = canvas
	maxOffset = ShelfMath.MaxOffset(canvas, window.X)
	frame.CanvasSize = UDim2.fromScale(canvas / window.X, 1)
	for index, view in ipairs(shown) do
		view.slot.Position = UDim2.fromScale(lefts[index] / canvas, top)
		view.slot.Size = UDim2.fromScale(widths[index] / canvas, cardH / window.Y)
	end
	starts = {}
	startTabs = {}
	for _, tab in ipairs(tabs) do
		if tab.visible then
			for index, view in ipairs(shown) do
				if view.category == tab.id then
					table.insert(starts, lefts[index] - pad)
					table.insert(startTabs, tab)
					break
				end
			end
		end
	end
end

-- The scrollbar, the arrows and the left fade follow the row's offset; the active tab follows it too, except while a tab or
-- chevron tap is carrying the row (the tapped tab is already active, and the tabs it passes must not flash).
local function updateFollow()
	local frame = shelf
	if not frame or windowPx.X <= 0 then
		return
	end
	local offset = frame.CanvasPosition.X
	if not autoScrolling and #starts > 0 then
		local index = ShelfMath.ActiveSection(offset, starts, maxOffset, MOTION.TabSlack * cardPx, MOTION.EdgePx)
		setActive(startTabs[index])
	end
	local handle = thumb
	if handle then
		local size, left = ShelfMath.Thumb(offset, windowPx.X, canvasPx, SHELF.Scrollbar.MinThumb)
		handle.Size = UDim2.fromScale(size, 1)
		handle.Position = UDim2.fromScale(left, 0)
	end
	local canLeft, canRight = ShelfMath.Arrows(offset, maxOffset, MOTION.EdgePx)
	local leftArrow, rightArrow, fade = leftChevron, rightChevron, edgeFade
	if leftArrow then
		leftArrow.Visible = canLeft
	end
	if rightArrow then
		rightArrow.Visible = canRight
	end
	if fade then
		fade.Visible = canLeft
	end
end

local function stopScroll()
	if scrollTween then
		scrollTween:Cancel()
		scrollTween = nil
	end
	autoScrolling = false
end

-- Scrolls the row to an offset: a springy ease, or straight there under Reduced Motion.
local function scrollTo(target: number)
	local frame = shelf
	if not frame then
		return
	end
	stopScroll()
	local x = ShelfMath.ScrollTarget(target, maxOffset)
	if Prefs.ReducedMotion() then
		frame.CanvasPosition = Vector2.new(x, 0)
		return
	end
	autoScrolling = true
	local tween = TweenService:Create(
		frame,
		TweenInfo.new(MOTION.ScrollSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ CanvasPosition = Vector2.new(x, 0) }
	)
	scrollTween = tween
	tween.Completed:Once(function()
		if scrollTween == tween then
			scrollTween = nil
			autoScrolling = false
			updateFollow()
		end
	end)
	tween:Play()
end

local function scrollBy(delta: number)
	local frame = shelf
	if frame then
		scrollTo(frame.CanvasPosition.X + delta)
	end
end

local function onTabTap(tab: TabView)
	for index, entry in ipairs(startTabs) do
		if entry == tab then
			setActive(tab)
			scrollTo(starts[index])
			return
		end
	end
end

local function refresh()
	if not open then
		return
	end
	local state = State.GetPurchases()
	local showPaidRandom = policyKnown and not paidRandomRestricted
	local hasProfile = State.Has()
	local profile = if hasProfile then State.Get() else nil
	local packDone = false
	for _, view in ipairs(views) do
		if view.kind == "robux" then
			refreshRobuxCard(view, state, showPaidRandom)
			if view.done and needsChoice(view.id) then
				packDone = true
			end
		elseif profile then
			refreshScrapCard(view, profile)
		end
	end
	for _, picker in ipairs(pickers) do
		picker.row.Visible = not packDone -- the choice is spent once the pack is claimed
		recolorButton(picker.button, if picker.species == state.starterSpecies then Theme.Colors.Confirm else Theme.Rarity.Common)
	end
	local pill = scrapLabel
	if pill and profile then
		pill.Text = Builder.formatNumber(profile.scrap)
	end
	refreshTabs()
	if layoutDirty then
		layoutShelf()
		updateFollow()
	end
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
-- Until the answer lands the Server Luck and Spins cards stay hidden; a failed call is asked again next open.
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

-- Motion ---------------------------------------------------------------------------

local function stopMotion()
	for _, tween in ipairs(entranceTweens) do
		tween:Cancel()
	end
	table.clear(entranceTweens)
	if sunburstTween then
		sunburstTween:Cancel()
		sunburstTween = nil
	end
	if stopShine then
		stopShine()
		stopShine = nil
	end
	stopScroll()
end

-- The tabs drop in one by one and the cards slide in from the right, tilted, and straighten, each a step after the one before
-- (Theme.Tween.StaggerStep, over the first StaggerRows). Reduced Motion: they are simply there.
local function playEntrance()
	local reduced = Prefs.ReducedMotion()
	local shown = 0
	for _, view in ipairs(views) do
		view.mover.Position = UDim2.fromScale(0, 0)
		view.mover.Rotation = 0
		if view.visible and not reduced then
			local delay = math.min(shown, Theme.Tween.StaggerRows) * Theme.Tween.StaggerStep
			shown += 1
			view.mover.Position = UDim2.fromScale(MOTION.SlideFrom, 0)
			view.mover.Rotation = SHELF.Tilt
			local info = TweenInfo.new(MOTION.SlideSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, delay)
			local tween = TweenService:Create(view.mover, info, { Position = UDim2.fromScale(0, 0), Rotation = 0 })
			table.insert(entranceTweens, tween)
			tween:Play()
		end
	end
	local dropped = 0
	for _, tab in ipairs(tabs) do
		tab.holder.Position = UDim2.fromScale(0, 0)
		if tab.visible and not reduced then
			local delay = dropped * Theme.Tween.StaggerStep
			dropped += 1
			tab.holder.Position = UDim2.fromScale(0, MOTION.DropFrom * SHELF.Rail.TabH)
			local info = TweenInfo.new(MOTION.DropSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay)
			local tween = TweenService:Create(tab.holder, info, { Position = UDim2.fromScale(0, 0) })
			table.insert(entranceTweens, tween)
			tween:Play()
		end
	end
	local rays = sunburst
	if rays then
		rays.Rotation = 0
		if not reduced then
			local info = TweenInfo.new(MOTION.SunburstSeconds, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
			local tween = TweenService:Create(rays, info, { Rotation = 360 })
			sunburstTween = tween
			tween:Play()
		end
	end
	-- One shine sweep, on the featured card only (Builder.shine does nothing under Reduced Motion), and only while it is unclaimed.
	for _, view in ipairs(views) do
		if view.units > 1 and view.visible and not view.done then
			stopShine = Builder.shine(view.card)
			break
		end
	end
end

-- Build ----------------------------------------------------------------------

local function buildTab(parent: Frame, index: number, category: Shop.Category): TabView
	local rail = SHELF.Rail
	local color = Theme.Hex(category.color)
	local holder = Builder.frame({ parent = parent, name = "Tab" .. category.id, zIndex = 10 })
	local button = Builder.button({
		parent = holder,
		name = "Button",
		text = Builder.text("SHOP_TAB_" .. category.id),
		color = color,
		position = UDim2.fromScale(rail.X, rail.Y),
		size = UDim2.fromScale(rail.W, rail.TabH),
		textSize = Theme.TextSize.Body,
		zIndex = 10,
	}, function()
		-- set below: the tab record does not exist until this returns
		local entry = tabs[index]
		if entry then
			onTabTap(entry)
		end
	end)
	local chip = SHELF.Chip
	-- The red "!" at the tab's right edge: a circle (the aspect keeps it round on any window) with a white rim.
	local bang = Builder.frame({
		parent = button,
		name = "Bang",
		position = UDim2.fromScale(1, 0.5),
		size = UDim2.fromScale(chip.BangW, chip.Bang),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Close,
		corner = Theme.Corner.Pill,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.White,
		aspect = 1,
		zIndex = 14,
	})
	Builder.label({
		parent = bang,
		name = "Text",
		text = Strings.SHOP_CHIP_DEAL,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 15,
	})
	bang.Visible = false
	local fresh = Builder.pill({
		parent = button,
		name = "New",
		position = UDim2.fromScale(chip.X, chip.Y),
		size = UDim2.fromScale(chip.W, chip.H),
		color = Theme.Colors.Close,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.White,
		zIndex = 14,
	})
	Builder.label({
		parent = fresh,
		name = "Text",
		text = Strings.SHOP_CHIP_NEW,
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 15,
	})
	fresh.Visible = false
	return { id = category.id, color = color, holder = holder, button = button, bang = bang, fresh = fresh, visible = false, row = 0, index = index }
end

-- The pill bar under the shelf: a dark trough with a gold thumb carrying grip ticks. A tap or drag on it (a hit area of at least
-- the tap floor around the trough) puts the thumb's middle under the pointer and scrolls the row to match.
local function buildScrollbar(parent: Frame)
	local spec = SHELF.Scrollbar
	local track = Builder.pill({
		parent = parent,
		name = "Track",
		position = UDim2.fromScale(spec.X, spec.Y),
		size = UDim2.fromScale(spec.W, spec.H),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 12,
	})
	local handle = Builder.pill({
		parent = track,
		name = "Thumb",
		size = UDim2.fromScale(1, 1),
		color = Theme.Colors.Featured,
		zIndex = 13,
	})
	Builder.gradient(handle, Theme.Colors.Featured)
	for index = 1, spec.Grips do
		Builder.frame({
			parent = handle,
			name = "Grip",
			position = UDim2.fromScale(0.5 + (index - (spec.Grips + 1) / 2) * spec.GripGap, 0.5),
			size = UDim2.fromScale(spec.GripW, 0.5),
			anchor = Vector2.new(0.5, 0.5),
			color = Builder.darker(Theme.Colors.Featured, 0.45),
			zIndex = 14,
		})
	end
	thumb = handle
	local function pointerTo(x: number)
		local width = math.max(1, track.AbsoluteSize.X)
		local fraction = (x - track.AbsolutePosition.X) / width
		stopScroll()
		local frame = shelf
		if frame then
			local offset = ShelfMath.OffsetFromPointer(fraction, windowPx.X, canvasPx, spec.MinThumb)
			frame.CanvasPosition = Vector2.new(ShelfMath.ScrollTarget(offset, maxOffset), 0)
		end
	end
	local area = Instance.new("TextButton")
	area.Name = "Hit"
	area.Text = ""
	area.AutoButtonColor = false
	area.BackgroundTransparency = 1
	area.BorderSizePixel = 0
	area.AnchorPoint = Vector2.new(0.5, 0.5)
	area.Position = UDim2.fromScale(0.5, 0.5)
	area.Size = UDim2.fromScale(1, 1)
	area.ZIndex = 15
	local floor = Instance.new("UISizeConstraint")
	floor.MinSize = Vector2.new(0, Theme.TapMin)
	floor.Parent = area
	area.Parent = track
	area.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			pointerTo(input.Position.X)
		end
	end)
	area.Activated:Connect(function()
		Builder.playSound(Sounds.Click) -- the drag itself is the input events above; a click sounds when it is let go
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			pointerTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function buildChevron(parent: Frame, forward: boolean): Frame
	local spec = SHELF.Chevron
	local button = Builder.button({
		parent = parent,
		name = if forward then "Next" else "Previous",
		text = if forward then Strings.SHOP_CHEVRON_NEXT else Strings.SHOP_CHEVRON_PREV,
		color = Theme.Colors.Outline,
		position = UDim2.fromScale(if forward then spec.Right else spec.Left, spec.Y),
		size = UDim2.fromScale(spec.W, spec.H),
		anchor = Vector2.new(0.5, 0.5),
		textSize = Theme.TextSize.Title,
		aspect = 1,
		zIndex = 16,
	}, function()
		scrollBy((if forward then 1 else -1) * MOTION.ChevronStep * windowPx.X)
	end)
	button.Visible = false
	return button
end

-- The currency row: a dark pill with the Scrap icon and the count (Roblox does not tell a script the player's Robux, so only
-- Scrap shows).
local function buildCurrency(parent: Frame)
	local spec = SHELF.Currency
	local pill = Builder.pill({
		parent = parent,
		name = "ScrapPill",
		position = UDim2.fromScale(spec.Right, spec.Y),
		size = UDim2.fromScale(spec.W, spec.H),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		aspect = spec.Aspect,
		zIndex = 12,
	})
	Builder.gradient(pill, Theme.Colors.Trough)
	local square = Builder.frame({
		parent = pill,
		name = "Icon",
		position = pos(spec.Icon),
		size = siz(spec.Icon),
		anchor = Vector2.new(0, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		aspect = 1,
		zIndex = 13,
	})
	Builder.gradient(square, Theme.Colors.Featured)
	local picture = Builder.icon({ parent = square, name = "Picture", key = "Scrap", zIndex = 14 })
	if picture then
		square.BackgroundTransparency = 1 -- the icon carries its own outline
		for _, child in ipairs(square:GetChildren()) do
			if child:IsA("UIStroke") then
				child.Enabled = false
			end
		end
	end
	scrapLabel = Builder.label({
		parent = pill,
		name = "Amount",
		text = "0",
		textSize = Theme.TextSize.Label,
		position = pos(spec.Amount),
		size = siz(spec.Amount),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 13,
	})
end

-- The faint rays behind the shelf: thin bars turned evenly through half a turn, each fading out at both ends, in a square holder
-- that the open animation turns slowly. The bars carry their own transparency in a gradient.
local function buildSunburst(parent: Frame): Frame
	local spec = SHELF.Sunburst
	local holder = Builder.frame({
		parent = parent,
		name = "Sunburst",
		position = UDim2.fromScale(spec.X, 0.5),
		size = UDim2.fromScale(3, spec.Size),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = 2,
	})
	for ray = 0, spec.Rays - 1 do
		local bar = Builder.frame({
			parent = holder,
			name = "Ray",
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(spec.Width, 1),
			anchor = Vector2.new(0.5, 0.5),
			color = Theme.Colors.White,
			zIndex = 2,
		})
		bar.Rotation = ray * 180 / spec.Rays
		local fade = Instance.new("UIGradient")
		fade.Rotation = 90
		fade.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, spec.Alpha),
			NumberSequenceKeypoint.new(1, 1),
		})
		fade.Parent = bar
	end
	return holder
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("ShopScreen", DISPLAY_ORDER)
	root.Enabled = false
	gui = root

	-- The ground: violet at the top, navy at the bottom, and it sinks every tap, so nothing reaches the world behind a takeover.
	local ground = Builder.frame({ parent = root, name = "Ground", color = Theme.Colors.White, zIndex = 1 })
	ground.Active = true
	local sky = Instance.new("UIGradient")
	sky.Rotation = 90
	sky.Color = ColorSequence.new(Theme.Colors.ShopBackdrop, Theme.Colors.Outline)
	sky.Parent = ground
	local layer = Builder.frame({ parent = root, name = "Stage", zIndex = 2 })
	stage = layer
	sunburst = buildSunburst(layer)

	-- The shelf: one row of cards, scrolling sideways. The native bar is off (ours sits under it); the canvas is sized by layoutShelf.
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "Shelf"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = pos(SHELF.Window)
	frame.Size = siz(SHELF.Window)
	frame.ZIndex = 3
	frame.ScrollingDirection = Enum.ScrollingDirection.X
	frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	frame.CanvasSize = UDim2.fromScale(1, 1)
	frame.ScrollBarThickness = 0
	frame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	frame.Parent = layer
	shelf = frame
	frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
		layoutShelf()
		updateFollow()
	end)
	frame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateFollow)
	-- Input is read from UserInputService, not from the row: a card's button sinks the events its parent would have heard. A press
	-- takes the row back from a running tab scroll (a tap on a tab starts its scroll on release, after this); the wheel scrolls it.
	UserInputService.InputBegan:Connect(function(input: InputObject)
		if open and scrollTween and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			stopScroll()
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		local card = detailLayer
		if open and input.UserInputType == Enum.UserInputType.MouseWheel and not (card and card.Visible) then
			stopScroll()
			local x = ShelfMath.ScrollTarget(frame.CanvasPosition.X - input.Position.Z * MOTION.WheelStep * windowPx.X, maxOffset)
			frame.CanvasPosition = Vector2.new(x, 0)
		end
	end)

	-- A dark strip at the left edge of the row once it has moved, so cards slide away under it.
	local fade = Builder.frame({
		parent = layer,
		name = "EdgeFade",
		position = UDim2.fromScale(SHELF.Window.X, SHELF.Window.Y),
		size = UDim2.fromScale(SHELF.Fade, SHELF.Window.H),
		color = Theme.Colors.Outline,
		zIndex = 6,
	})
	local dim = Instance.new("UIGradient")
	dim.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, MOTION.FadeAlpha), NumberSequenceKeypoint.new(1, 1) })
	dim.Parent = fade
	fade.Visible = false
	edgeFade = fade

	-- The cards, in tab order: each category's items from its Launch section (Robux) or its `scrap` list (lures and gear).
	local sectionItems: { [string]: { string } } = {}
	for _, entry in ipairs(launchSections) do
		sectionItems[entry.section] = entry.items
	end
	for _, category in ipairs(Shop.Categories) do
		local color = Theme.Hex(category.color)
		local scrapIds = category.scrap
		if scrapIds then
			for _, id in ipairs(scrapIds) do
				local kind: Kind = if lureDefs[id] then "lure" else "gear"
				local view = buildCard(frame, id, kind, category.id, color)
				table.insert(views, view)
				viewById[id] = view
			end
		else
			for _, id in ipairs(sectionItems[category.id] or {}) do
				if shopItems[id] then
					local view = buildCard(frame, id, "robux", category.id, color)
					table.insert(views, view)
					viewById[id] = view
				end
			end
		end
	end

	-- The header: the title (clear of Roblox's own buttons at the top left), the currency pill and the red X top right.
	local title = SHELF.Title
	Builder.label({
		parent = layer,
		name = "Title",
		text = Strings.SHOP_TITLE,
		textSize = Theme.TextSize.Title,
		position = pos(title),
		size = siz(title),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 12,
	})
	buildCurrency(layer)
	local close = SHELF.Close
	Builder.button({
		parent = layer,
		name = "Close",
		text = Strings.UI_CLOSE,
		color = Theme.Colors.Close,
		position = UDim2.fromScale(close.Right, close.Y),
		size = UDim2.fromScale(close.W, close.H),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 16,
	}, function()
		ShopScreen.Close()
	end)

	-- The tab rail, then the scrollbar and the arrows.
	tabs = {}
	for index, category in ipairs(Shop.Categories) do
		table.insert(tabs, buildTab(layer, index, category))
	end
	buildScrollbar(layer)
	leftChevron = buildChevron(layer, false)
	rightChevron = buildChevron(layer, true)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	-- "world" too: a launch (or /world) unlocks a second world, which unlocks the Glider card while the Shop is open.
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
	local root, frame = gui, shelf
	if open or not root or not frame then
		return
	end
	open = true
	fetchPolicy()
	local _, purchasesPushed = State.GetPurchases()
	if not purchasesPushed then
		fetchPurchases(true) -- the join push has not landed: ask once so Owned chips are right
	end
	hideDetail()
	activeTab = nil
	layoutDirty = true
	refresh()
	root.Enabled = true
	frame.CanvasPosition = Vector2.zero
	layoutShelf()
	updateFollow()
	setActive(startTabs[1])
	stopMotion()
	playEntrance()
end

function ShopScreen.Close()
	if not open then
		return
	end
	open = false
	stopMotion()
	hideDetail()
	local root = gui
	if root then
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
