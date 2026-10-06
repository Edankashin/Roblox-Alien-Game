--!strict
-- StarterPlayerScripts.Client.UI.BuildScreen: the house grid's Build tray (milestone 42b), registered with Screens
-- as "Build". A tray along the bottom edge, not a centre panel, so the plot stays in view: a header tab, three rows
-- of item cards (Rooms, Things, Habitats; each card the item's name, its price in Scrap, tinted with its placeholder
-- colour and grey while Scrap is short), a cap line for each kind at the row's left ("Rooms: 1/4"), a hint line,
-- and three buttons: Turn, Take away (remove mode on and off) and Done. There is no backdrop. The tray keeps its
-- height, which holds two rows, so the rows are a vertical scrolling list that shows two at a time (Habitats is the
-- one scrolled to). Every value shown is read from the home mirror in State and the data tables (data/HomeBuild,
-- strings HOME_ITEM_<id>, BUILD_KIND_<kind>).
--
-- Placing: tap a card to pick the item, then tap the plot. The first tap on a cell only moves the ghost there (the
-- HomeRenderer's half see-through preview, so the player sees it before paying); a tap on the ghost, or on its
-- cell, asks the server (PlaceHomeItem). Taking away: with Take away on, a tap on a placed item asks the server
-- (RemoveHomeItem). The server judges every one: it answers (ok, reason) and pushes HomeChanged, which the mirror
-- and this tray redraw from; a refusal becomes a toast. Nothing here decides an outcome.
--
-- A tap reaches OnWorldTap (the bootstrap routes it while the tray is open). It is cast from the camera against the
-- plot and the ghost (placing) or the plot and the placed items (taking away), so a tap on the body of a tall item
-- finds that item, not the ground behind it.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local HomeBuild = require(Shared:WaitForChild("data"):WaitForChild("HomeBuild"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local HomeRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("HomeRenderer"))

local BuildScreen = {}

type Kind = HomeBuild.Kind

-- One item card. Built once and refreshed in place.
type Card = { id: string, tint: Color3, frame: Frame, stroke: UIStroke, gradient: UIGradient }

local KINDS: { Kind } = { "room", "furniture", "habitat" } -- the rows, top to bottom

-- Tray layout, as fractions of the screen (the tray) or of the tray (everything inside it). The tray is 0.32 of
-- the screen tall: at iPhone SE height (375) that is 120 px, a card row 32 px, the button row 31 px. Three rows
-- do not fit under the title tab above the footer, so the rows sit in a ScrollingFrame (the "list") whose window
-- shows two of them.
local TRAY_W = 0.88 -- of the screen; 0.9 tucked 5 px under the menu column at 1081 px wide
local TRAY_H = 0.32
local HEADER_W = 0.2 -- the title tab straddling the tray's top edge
local HEADER_H = 0.2
local ROW_TOP = 0.11 -- under the header tab
local ROW_H = 0.27
local ROW_GAP = 0.02
local LIST_PAD = 0.01 -- above and below the rows inside the list, so a card's outline is not clipped by its edge
local LIST_ROWS_SHOWN = 2 -- rows the list's window holds at once
local LIST_BAR_PX = 6 -- the scroll bar's thickness, not a Size: a thin dark bar at the list's right
local CAP_W = 0.18 -- the cap line's column at each row's left
local CARDS_X = 0.22 -- the cards start here and run to the right margin
local CARD_GAP = 0.012 -- between cards, of the cards' span
local FOOT_Y = 0.7 -- the hint and the buttons
local FOOT_H = 0.26
local HINT_W = 0.45
local TURN_X, TURN_W = 0.5, 0.14
local REMOVE_X, REMOVE_W = 0.65, 0.19
local DONE_X, DONE_W = 0.85, 0.13

local gui: ScreenGui? = nil
local panel: Frame? = nil
local hint: TextLabel? = nil
local list: ScrollingFrame? = nil
local capLabels: { [string]: TextLabel } = {}
local cards: { Card } = {}
local turnButton: Frame? = nil
local removeButton: Frame? = nil
local open = false
local removing = false -- Take away is on
local picked: string? = nil -- the card tapped; nil until one is
local rotation = 0 -- quarter turns the next placement (and the ghost) is turned
local ghostX: number? = nil -- the cell the ghost stands on; nil while there is none
local ghostZ: number? = nil
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

local function itemName(itemId: string): string
	return Builder.text("HOME_ITEM_" .. itemId)
end

local refresh: () -> ()

-- Shows the ghost of the picked item at its cell, or clears it when there is no pick, no cell or Take away is on.
local function showGhost()
	HomeRenderer.SetGhost(if removing then nil else picked, ghostX, ghostZ, rotation)
end

local function clearGhost()
	ghostX, ghostZ = nil, nil
	HomeRenderer.SetGhost(nil, nil, nil, rotation)
end

-- Server calls -------------------------------------------------------------

-- A refused placement becomes a toast; anything else the player cannot fix is only logged.
local function refusePlace(reason: any, kind: Kind)
	if reason == "Taken" then
		Toast.Show(Strings.TOAST_BUILD_TAKEN, Theme.Colors.Select)
	elseif reason == "OffPlot" then
		Toast.Show(Strings.TOAST_BUILD_OFF_PLOT, Theme.Colors.Select)
	elseif reason == "Full" then
		Toast.Show(Strings.TOAST_BUILD_FULL:format(Builder.text("BUILD_KIND_" .. kind)), Theme.Colors.Select)
	elseif reason == "NotEnoughScrap" then
		Toast.Show(Strings.TOAST_NOT_ENOUGH_SCRAP, Theme.Colors.Close)
	else
		print(("[%s] PlaceHomeItem refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

-- Asks the server to place `itemId` at a cell, turned as the tray has it. Runs in its own thread: callers are
-- taps. The ghost goes once the item stands (the pick stays, for the next one); on a refusal it stays where it is.
local function placeItem(itemId: string, cellX: number, cellZ: number)
	local def = HomeBuild.ById[itemId]
	if pending or not def then
		return
	end
	pending = true
	local turned = rotation
	task.spawn(function()
		local ok, reason = Net.func("PlaceHomeItem"):InvokeServer(itemId, cellX, cellZ, turned)
		pending = false
		if ok == true then
			Builder.playSound(Sounds.Click)
			Toast.Show(Strings.TOAST_BUILD_PLACED:format(itemName(itemId)), Theme.Colors.Confirm)
			if open and ghostX == cellX and ghostZ == cellZ then
				clearGhost()
			end
		else
			refusePlace(reason, def.kind)
		end
		refresh()
	end)
end

-- Asks the server to take the placed item `uid` away.
local function removeItem(uid: string)
	local item = if State.Has() then State.Get().home.items[uid] else nil
	if pending or not item then
		return
	end
	pending = true
	local name = itemName(item.itemId)
	task.spawn(function()
		local ok, reason = Net.func("RemoveHomeItem"):InvokeServer(uid)
		pending = false
		if ok == true then
			Builder.playSound(Sounds.Click)
			Toast.Show(Strings.TOAST_BUILD_REMOVED:format(name), Theme.Colors.Select)
		else
			print(("[%s] RemoveHomeItem refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
		refresh()
	end)
end

-- Taps -----------------------------------------------------------------------

local function pickItem(itemId: string)
	removing = false
	if picked ~= itemId then
		rotation = 0 -- a fresh pick starts unturned; a turn never carries over to the next item
	end
	picked = itemId
	showGhost() -- a ghost already up becomes the new item at its cell
	refresh()
end

local function turn()
	rotation = (rotation + 1) % HomeBuild.RotationSteps
	showGhost()
	refresh()
end

local function toggleRemove()
	removing = not removing
	if removing then
		clearGhost()
	end
	refresh()
end

-- What the ray from a screen point meets: the cell under the hit (nil off the plot), the uid of a placed item it
-- hit, and whether it hit the ghost. The ray runs from the camera through the point (input positions include the
-- GUI inset, which ScreenPointToRay expects), long enough to cross the plot from wherever the camera is, against
-- an Include list of just the plot and the ghost, or with Take away on the plot and the placed items.
local function rayAt(x: number, y: number): (number?, number?, string?, boolean)
	local camera = Workspace.CurrentCamera
	local plot = HomeRenderer.Plot()
	if not camera or not plot then
		return nil, nil, nil, false
	end
	local ray = camera:ScreenPointToRay(x, y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = HomeRenderer.RayTargets(removing)
	local reach = (ray.Origin - plot.Position).Magnitude + plot.Size.Magnitude
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * reach, params)
	if not hit then
		return nil, nil, nil, false
	end
	local cellX, cellZ = HomeRenderer.CellAt(hit.Position)
	local uid, onGhost = HomeRenderer.Identify(hit.Instance)
	return cellX, cellZ, uid, onGhost
end

-- A tap in the world while the tray is open (the bootstrap hands it over instead of starting a catch).
function BuildScreen.OnWorldTap(x: number, y: number)
	if not open or pending or not State.Has() then
		return
	end
	local cellX, cellZ, uid, onGhost = rayAt(x, y)
	if removing then
		local target = uid
		if target == nil and cellX ~= nil and cellZ ~= nil then
			local item = HomeRenderer.ItemAt(cellX, cellZ)
			target = if item then item.uid else nil
		end
		if target then
			removeItem(target)
		end
		return
	end
	local itemId = picked
	if itemId == nil then
		return -- the hint asks for a pick first
	end
	if onGhost and ghostX ~= nil and ghostZ ~= nil then
		cellX, cellZ = ghostX, ghostZ -- a tap on any part of the ghost is a tap on its cell
	end
	if cellX == nil or cellZ == nil then
		return -- sky or beyond the plot
	end
	if cellX == ghostX and cellZ == ghostZ then
		placeItem(itemId, cellX, cellZ)
	else
		Builder.playSound(Sounds.Click)
		ghostX, ghostZ = cellX, cellZ
		showGhost()
	end
end

-- Cards ---------------------------------------------------------------------

-- A card: the item's name over its price, tinted with its placeholder colour (grey while unaffordable, a thick
-- gold border while picked, both set by refresh), and an invisible button over all of it.
local function buildCard(parent: ScrollingFrame, def: HomeBuild.Item, position: UDim2, size: UDim2): Card
	local tint = Color3.fromHex(def.placeholder.color)
	local frame = Builder.frame({
		parent = parent,
		name = def.id,
		position = position,
		size = size,
		color = tint,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 3,
	})
	local gradient = Builder.gradient(frame, tint)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	assert(stroke, "Builder.frame stroke")
	Builder.label({
		parent = frame,
		name = "Name",
		text = itemName(def.id),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.04),
		size = UDim2.fromScale(0.92, 0.46),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})
	Builder.label({
		parent = frame,
		name = "Price",
		text = Strings.BUILD_PRICE:format(Builder.formatNumber(def.scrap)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.92, 0.46),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.AutoButtonColor = false
	tap.Text = ""
	tap.BorderSizePixel = 0
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 6
	tap.Parent = frame
	tap.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		pickItem(def.id)
	end)
	return { id = def.id, tint = tint, frame = frame, stroke = stroke, gradient = gradient }
end

-- Refresh ----------------------------------------------------------------------

refresh = function()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local counts: { [string]: number } = {}
	for _, item in pairs(profile.home.items) do
		local def = HomeBuild.ById[item.itemId]
		if def then
			counts[def.kind] = (counts[def.kind] or 0) + 1
		end
	end
	local caps: { [string]: number } = HomeBuild.Caps
	for kind, label in pairs(capLabels) do
		local count, cap = counts[kind] or 0, caps[kind] or 0
		label.Text = Strings.BUILD_CAP:format(Builder.text("BUILD_KIND_" .. kind), count, cap)
		label.TextColor3 = if count >= cap then Theme.Colors.Close else Theme.Colors.Outline
	end
	for _, card in ipairs(cards) do
		local def = HomeBuild.ById[card.id]
		local full = (counts[def.kind] or 0) >= (caps[def.kind] or 0) -- the kind's cap is reached: grey like unaffordable
		local fill = if profile.scrap >= def.scrap and not full then card.tint else Theme.Rarity.Common
		card.frame.BackgroundColor3 = fill
		card.gradient.Color = ColorSequence.new(Builder.lighter(fill), fill)
		local selected = not removing and picked == card.id
		card.stroke.Color = if selected then Theme.Colors.Featured else Theme.Colors.Outline
		card.stroke.Thickness = if selected then Theme.Stroke.Panel else Theme.Stroke.Text
	end
	local line = hint
	if line then
		line.Text = if removing then Strings.BUILD_HINT_REMOVE elseif picked ~= nil then Strings.BUILD_HINT_PLACE else Strings.BUILD_HINT_PICK
	end
	local turnFace, removeFace = turnButton, removeButton
	if turnFace then
		recolorButton(turnFace, if picked ~= nil and not removing then Theme.Colors.Select else Theme.Rarity.Common)
	end
	if removeFace then
		recolorButton(removeFace, if removing then Theme.Colors.Close else Theme.Colors.Featured)
	end
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("BuildScreen", 20)
	root.Enabled = false
	gui = root

	local body = Builder.frame({
		parent = root,
		name = "Tray",
		position = UDim2.fromScale(1 - Theme.Margin, 1 - Theme.Margin), -- bottom right: the left edge clears the menu column
		size = UDim2.fromScale(TRAY_W, TRAY_H),
		anchor = Vector2.new(1, 1),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		zIndex = 2,
	})
	body.Active = true -- sinks input, so a tap on the tray never reaches the world
	panel = body

	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(HEADER_W, HEADER_H),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Select,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Select)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.BUILD_TITLE,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	-- The rows: the items of each kind in data order, all rows on the same slot grid (as many slots as the
	-- fullest row), so a card sits in the same column from row to row. A row with fewer cards than slots gives
	-- each card as many slots as fit evenly (Habitats: two cards of two slots), so a longer name fits a card.
	local perKind: { [string]: { HomeBuild.Item } } = {}
	local slots = 1
	for _, def in ipairs(HomeBuild.Items) do
		local row = perKind[def.kind] or {}
		table.insert(row, def)
		perKind[def.kind] = row
		slots = math.max(slots, #row)
	end

	-- The list: a window over the rows with a thin dark bar. Children of a ScrollingFrame scale against its canvas, so
	-- every row position, height and x below is the tray fraction divided by the canvas's extent (the window's width
	-- for x, canvasH for y). CanvasSize's Scale is relative to the scroller's PARENT (the tray), like any Size, not to
	-- the window, so the canvas is canvasH of the tray and the window shows LIST_ROWS_SHOWN rows of it. There are no
	-- layout objects, so nothing feeds back (UI Playbook, "Grids inside scrolling frames").
	local listW = 1 - Theme.Margin * 2
	local listH = LIST_ROWS_SHOWN * ROW_H + (LIST_ROWS_SHOWN - 1) * ROW_GAP + LIST_PAD * 2
	local canvasH = #KINDS * ROW_H + (#KINDS - 1) * ROW_GAP + LIST_PAD * 2
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Rows"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Theme.Margin, ROW_TOP - LIST_PAD)
	scroller.Size = UDim2.fromScale(listW, listH)
	scroller.ZIndex = 3
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroller.CanvasSize = UDim2.fromScale(0, canvasH)
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.ScrollBarThickness = LIST_BAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Trough
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.Parent = body
	list = scroller

	local cardsW = 1 - CARDS_X - Theme.Margin
	local slotW = (1 - (slots - 1) * CARD_GAP) / slots -- a slot's width as a fraction of the cards' span
	cards = {}
	capLabels = {}
	for rowIndex, kind in ipairs(KINDS) do
		local rowY = (LIST_PAD + (rowIndex - 1) * (ROW_H + ROW_GAP)) / canvasH
		local rowH = ROW_H / canvasH
		-- Helper text on the cream plate: navy, no outline (UI Playbook, "Input fields and hints").
		capLabels[kind] = Builder.label({
			parent = scroller,
			name = "Cap_" .. kind,
			text = "",
			textSize = Theme.TextSize.Body,
			color = Theme.Colors.Outline,
			stroke = 0,
			xAlign = Enum.TextXAlignment.Left,
			position = UDim2.fromScale(0, rowY),
			size = UDim2.fromScale(CAP_W / listW, rowH),
			zIndex = 3,
		})
		local row = perKind[kind] or {}
		local span = math.max(1, math.floor(slots / math.max(1, #row))) -- slots each card takes
		for index, def in ipairs(row) do
			local x = CARDS_X + cardsW * (index - 1) * span * (slotW + CARD_GAP)
			local w = cardsW * (span * slotW + (span - 1) * CARD_GAP)
			table.insert(
				cards,
				buildCard(scroller, def, UDim2.fromScale((x - Theme.Margin) / listW, rowY), UDim2.fromScale(w / listW, rowH))
			)
		end
	end

	hint = Builder.label({
		parent = body,
		name = "Hint",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		xAlign = Enum.TextXAlignment.Left,
		position = UDim2.fromScale(Theme.Margin, FOOT_Y),
		size = UDim2.fromScale(HINT_W, FOOT_H),
		zIndex = 3,
	})
	turnButton = Builder.button({
		parent = body,
		name = "Turn",
		text = Strings.BUILD_ROTATE,
		color = Theme.Rarity.Common,
		position = UDim2.fromScale(TURN_X, FOOT_Y),
		size = UDim2.fromScale(TURN_W, FOOT_H),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, turn)
	removeButton = Builder.button({
		parent = body,
		name = "TakeAway",
		text = Strings.BUILD_REMOVE,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(REMOVE_X, FOOT_Y),
		size = UDim2.fromScale(REMOVE_W, FOOT_H),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, toggleRemove)
	Builder.button({
		parent = body,
		name = "Done",
		text = Strings.BUILD_DONE,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(DONE_X, FOOT_Y),
		size = UDim2.fromScale(DONE_W, FOOT_H),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		BuildScreen.Close()
	end)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	State.OnChanged("home", refresh)
	State.OnChanged("scrap", refresh)
end

-- Public API -------------------------------------------------------------

function BuildScreen.IsOpen(): boolean
	return open
end

function BuildScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	removing = false
	picked = nil
	rotation = 0
	local rows = list
	if rows then
		rows.CanvasPosition = Vector2.zero -- the list opens at its top, on Rooms
	end
	clearGhost()
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function BuildScreen.Close()
	if not open then
		return
	end
	open = false
	clearGhost()
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

return BuildScreen
