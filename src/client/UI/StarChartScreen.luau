--!strict
-- StarterPlayerScripts.Client.UI.StarChartScreen: the Star Chart, opened from the Ship panel. UI richness pass, package B
-- (docs/vault/05-ui-design/UI-Richness-Pass.md section 3): the orbit map is gone; the body is a scrolling grid of world cards, two
-- columns, the Home planet first and worlds 1 to 7 in order (UI/WorldCard), and it opens scrolled to the current world. Under the
-- header band (Builder.panelHeader: "Worlds 2 / 3" and, while an outpost has something ready, "Ready 90 Scrap"):
--   a card     one world's picture, number badge, name, species chips with the found count and one button: HERE (the world you
--              are on: grey, a toast says "You are here"), TRAVEL (an unlocked world: the same FlyTo request as the old Fly
--              button, the same refusals and toasts), "Return" (a guest, State.IsGuest: visiting someone's home, or a ship that is
--              not on the world this place runs, sees it on the world the ship waits on: flying there is the way home), nothing on a
--              locked card (a padlock and the line that says what opens it; the next stop wears a gold ink and NEXT) or an unbuilt
--              one ("Opens soon"). A tap on a card (not its button) selects it: its ink turns gold.
--   the tray   along the bottom while the selected world is unlocked and has an outpost: "Outpost Lv 2, 120 Scrap/h", what is
--              ready, and Collect (the main green when something is ready, else grey) and Upgrade (blue, grey when unaffordable
--              or maxed), exactly the old requests, refreshed every Config.StarChartTickSeconds while open. Selecting the unlocked
--              Home planet shows its Visit button here instead (milestone 42e: it opens the Visit screen; a guest at the home has
--              none). A card with an outpost also wears "Lv 2" and a green ready dot.
-- Every tap asks the server (CollectOutpost, UpgradeOutpost, FlyTo; one request in flight) and toasts the answer; the buttons only
-- dim to hint what a tap would do, they never block it, so the server's reason always reaches the player. The mirror (State: "world",
-- "scrap", "profile", "codex") is all the screen reads; OutpostsChanged, ScrapChanged, WorldChanged, CodexChanged and HomeView
-- ("visit": a guest's card changes) keep it current. Nothing here decides anything. The tick thread is task.cancel'ed in Close.
-- The Ship's next-stop strip (ShipScreen) calls Preselect(worldId) and then Screens.Open("StarChart"): no new server path.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local OutpostMath = require(Shared:WaitForChild("OutpostMath"))
local PanelHeaderMath = require(Shared:WaitForChild("PanelHeaderMath"))
local WorldCardMath = require(Shared:WaitForChild("WorldCardMath"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Panels = require(Shared:WaitForChild("data"):WaitForChild("Panels"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local WorldCards = require(Shared:WaitForChild("data"):WaitForChild("WorldCards"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local Screens = require(script.Parent.Screens)
local WorldCard = require(script.Parent.WorldCard)
local State = require(script.Parent.Parent.State)

local StarChartScreen = {}

-- The outpost tray and the pieces refresh rewrites.
type Tray = {
	frame: Frame, -- an edged block plate
	title: TextLabel, -- "Outpost Lv 2, 120 Scrap/h", or the Home planet's line
	line: TextLabel, -- "Ready: 90 Scrap, 1 materials"
	collect: Frame,
	upgrade: Frame,
	visit: Frame,
}

-- Panel layout, as fractions of the panel. The header band fills the top (Panels.Shell.BodyTop is where a body starts); the grid
-- runs from there to the tray, or to the bottom while no tray shows. The panel keeps the width it had (1.75 at the old 0.78 height).
local PANEL_W = 0.84
local PANEL_H = Panels.Shell.Height
local PANEL_ASPECT = PanelHeaderMath.ShellAspect(1.75, 0.78, PANEL_H)
local GRID_Y = Panels.Shell.BodyTop + 0.005
local GRID_BOTTOM = 1 - Theme.Margin
local HOME_ID = 0 -- data/Worlds row 0: the home planet
local SCROLLBAR_PX = 6
local CELL_EPSILON = 0.001 -- a grid cell a hair under 1 / columns, so two always fit a row

-- Inside the tray, as fractions of it.
local TRAY_TEXT_X = 0.03
local TRAY_TEXT_W = 0.42
local TRAY_ROW_H = 0.44
local TRAY_UPGRADE_X = 0.47
local TRAY_UPGRADE_W = 0.26
local TRAY_COLLECT_X = 0.74
local TRAY_COLLECT_W = 0.23
local TRAY_BUTTON_Y = 0.14
local TRAY_BUTTON_H = 0.72

local gui: ScreenGui? = nil
local panel: Frame? = nil
local header: Builder.PanelHeader? = nil
local scroller: ScrollingFrame? = nil
local cards: { [number]: WorldCard.Card } = {}
local slots: { [number]: Frame } = {}
local cardOptions: WorldCard.Options = {}
local tray: Tray? = nil
local selected = 1 -- the world id the tray belongs to; Open resets it to the current world
local preselect: number? = nil -- a world the Ship's strip asked to open on
local open = false
local busy = false -- one request in flight at a time
local tickThread: thread? = nil

-- Helpers ----------------------------------------------------------------

local function outpostOf(profile: Types.Profile, worldId: number): Types.OutpostState?
	local outposts: { [string]: Types.OutpostState }? = profile.world.outposts -- a mirror older than the field reads as none
	return if outposts then outposts[tostring(worldId)] else nil
end

local function worldName(worldId: number): string
	return WorldCard.WorldName(worldId)
end

-- Recolours a block button in place (its face and lip), keeping its text.
local function setButton(container: Frame, text: string, color: Color3)
	Builder.recolorBlockButton(container, color)
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.Text = text
	end
end

-- Refresh ----------------------------------------------------------------

-- The tray for the selected world: an outpost's level, rate, what is ready and the two buttons; the Home planet's line and Visit.
local function refreshTray(profile: Types.Profile, unlocked: { [number]: boolean }, now: number): boolean
	local bar = tray
	if not bar then
		return false
	end
	local id = selected
	local isHome = id == HOME_ID
	local state = if isHome then nil else outpostOf(profile, id)
	local guestHome = State.IsGuest() and profile.world.current == id -- the ship waits here: "Return", no Visit
	local showVisit = isHome and unlocked[HOME_ID] == true and not guestHome
	local showOutpost = state ~= nil and unlocked[id] == true
	bar.visit.Visible = showVisit
	bar.collect.Visible = showOutpost
	bar.upgrade.Visible = showOutpost
	bar.title.Visible = showOutpost or showVisit
	bar.line.Visible = showOutpost
	if showOutpost and state then
		local rates = OutpostMath.Level(state.level)
		local ready = OutpostMath.Pending(state, id, now)
		bar.title.Text = Strings.WORLDCARD_TRAY:format(state.level, rates.scrapPerHour)
		bar.line.Text = Strings.STARCHART_PENDING:format(ready.scrap, ready.materialCount)
		local nothing = ready.scrap <= 0 and ready.materialCount <= 0
		setButton(bar.collect, Strings.STARCHART_COLLECT, if nothing then Builder.roleColor("current") else Builder.roleColor("main"))
		local cost = OutpostMath.UpgradeCost(state.level)
		if cost == nil then
			setButton(bar.upgrade, Strings.STARCHART_MAXED, Builder.roleColor("current"))
		else
			setButton(bar.upgrade, Strings.STARCHART_UPGRADE:format(cost), if profile.scrap < cost then Builder.roleColor("current") else Builder.roleColor("select"))
		end
	elseif showVisit then
		bar.title.Text = Strings.STARCHART_HOME_LINE
		bar.line.Text = ""
		setButton(bar.visit, Strings.STARCHART_VISIT, Builder.roleColor("main"))
	end
	return showOutpost or showVisit
end

-- Resizes the grid to leave room for the tray.
local function placeGrid(trayShown: boolean)
	local grid, bar = scroller, tray
	if not grid or not bar then
		return
	end
	bar.frame.Visible = trayShown
	local bottom = if trayShown then 1 - Theme.Margin - WorldCards.OutpostTray.Height - WorldCards.OutpostTray.Gap else GRID_BOTTOM
	grid.Size = UDim2.fromScale(1 - 2 * Theme.Margin, bottom - GRID_Y)
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local unlocked, highest = WorldCard.OpenWorlds(profile)
	local ids = WorldCardMath.Order(#Worlds)
	local nextLocked = WorldCardMath.NextLocked(ids, unlocked, highest)
	local now = os.time()
	local readyScrap = 0
	local unlockedBuilt, builtTotal = 0, 0
	local body = panel
	cardOptions.panelPx = if body and body.AbsoluteSize.X > 0 then body.AbsoluteSize.X else 0
	for _, id in ipairs(ids) do
		local card = cards[id]
		local def = Worlds[id]
		if id > 0 and def and def.built then
			builtTotal += 1
			if unlocked[id] then
				unlockedBuilt += 1
			end
		end
		if not card or not def then
			continue
		end
		card.Set(WorldCard.ViewFor(profile, id, unlocked, nextLocked, selected, now))
		local state = if id == HOME_ID or not unlocked[id] then nil else outpostOf(profile, id)
		if state then
			readyScrap += OutpostMath.Pending(state, id, now).scrap
		end
	end
	local bar = header
	if bar then
		local pills: { { any } } = { { unlockedBuilt, builtTotal } }
		if readyScrap > 0 then
			table.insert(pills, { Builder.formatNumber(readyScrap) })
		end
		bar.setPills(pills)
	end
	placeGrid(refreshTray(profile, unlocked, now))
end

-- Selects `worldId`: its ink turns gold and the tray follows it.
local function selectWorld(worldId: number)
	if worldId == selected then
		return
	end
	selected = worldId
	refresh()
end

-- The pictures: a card loads its render once it is within a screen of the viewport (a picture at id 0 draws nothing at all).
local function updateNear()
	local grid = scroller
	if not grid then
		return
	end
	local origin = grid.AbsolutePosition.Y
	local scrollY = grid.CanvasPosition.Y
	local window = grid.AbsoluteWindowSize.Y
	for id, slot in pairs(slots) do
		local top = slot.AbsolutePosition.Y - origin + scrollY
		local card = cards[id]
		if card then
			card.SetNear(WorldCardMath.Near(top, top + slot.AbsoluteSize.Y, scrollY, window, WorldCards.NearScreens))
		end
	end
end

-- Scrolls the grid to the row of `worldId` (after the layout has run, a frame later).
local function scrollTo(worldId: number)
	task.defer(function()
		local grid, slot = scroller, slots[worldId]
		if not grid or not slot or not open then
			return
		end
		RunService.Heartbeat:Wait() -- the grid layout resolves its cells a frame after the screen turns on
		if not open then
			return
		end
		local y = slot.AbsolutePosition.Y - grid.AbsolutePosition.Y + grid.CanvasPosition.Y
		grid.CanvasPosition = Vector2.new(0, math.max(0, y))
		updateNear()
	end)
end

-- The tick -------------------------------------------------------------------

local function stopTick()
	local thread = tickThread
	tickThread = nil
	if thread and coroutine.status(thread) ~= "dead" then
		task.cancel(thread)
	end
end

-- Redraws every Config.StarChartTickSeconds so the ready amounts count up (and the dots appear) while the chart is open.
local function startTick()
	stopTick()
	tickThread = task.spawn(function()
		while open do
			task.wait(Config.StarChartTickSeconds)
			if not open then
				break
			end
			refresh()
		end
	end)
end

-- Server calls -------------------------------------------------------------

-- Runs `work` as the one request in flight (taps meanwhile are ignored), then redraws.
local function request(work: () -> ())
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		work()
		busy = false
		refresh()
	end)
end

local function invoke(name: string, worldId: number): (boolean, string?, any, any)
	local success, ok, reason, a, b = pcall(function()
		return Net.func(name):InvokeServer(worldId)
	end)
	if not success then
		print(("[%s] %s failed: %s"):format(Config.WorkingTitle, name, tostring(ok)))
		return false, "Error", nil, nil
	end
	return ok == true, if type(reason) == "string" then reason else nil, a, b
end

local function onCollect(worldId: number)
	request(function()
		local ok, reason, scrap, count = invoke("CollectOutpost", worldId)
		if ok then
			local gotScrap = if type(scrap) == "number" then scrap else 0
			local gotCount = if type(count) == "number" then count else 0
			Toast.Show(Strings.TOAST_OUTPOST_COLLECTED:format(gotScrap, gotCount), Theme.Colors.Confirm)
		elseif reason == "Nothing" then
			Toast.Show(Strings.TOAST_OUTPOST_NOTHING, Theme.Colors.Select)
		elseif reason == "TooSoon" then
			Toast.Show(Strings.TOAST_OUTPOST_TOO_SOON, Theme.Colors.Select)
		elseif reason ~= "RateLimited" then
			print(("[%s] CollectOutpost refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

local function onUpgrade(worldId: number)
	request(function()
		-- What the tap was asking for, read before the answer: the OutpostsChanged push may land first.
		local profile = if State.Has() then State.Get() else nil
		local state = if profile then outpostOf(profile, worldId) else nil
		local level = if state then state.level else 1
		local ok, reason = invoke("UpgradeOutpost", worldId)
		if ok then
			Toast.Show(Strings.TOAST_OUTPOST_UPGRADED:format(math.min(level + 1, OutpostMath.MaxLevel())), Theme.Colors.Confirm)
		elseif reason == "NotEnoughScrap" then
			Toast.Show(Strings.TOAST_OUTPOST_NOT_ENOUGH:format(OutpostMath.UpgradeCost(level) or 0), Theme.Colors.Close)
		elseif reason == "Maxed" then
			Toast.Show(Strings.TOAST_OUTPOST_MAXED, Theme.Colors.Featured)
		elseif reason ~= "RateLimited" then
			print(("[%s] UpgradeOutpost refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- On ok nothing happens here: the Flew event closes the screens and plays the fade.
local function onFly(worldId: number)
	request(function()
		local ok, reason = invoke("FlyTo", worldId)
		if ok then
			return
		elseif reason == "Locked" then
			Toast.Show(Strings.TOAST_FLY_LOCKED:format(worldName(worldId)), Theme.Colors.Close)
		elseif reason == "Busy" then
			Toast.Show(Strings.TOAST_FLY_BUSY, Theme.Colors.Select)
		elseif reason ~= "RateLimited" then
			print(("[%s] FlyTo refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- A card's button: HERE says where you are, TRAVEL and "Return" ask the server to fly.
local function onAction(worldId: number, kind: string)
	if kind == "Here" then
		Toast.Show(Strings.WORLDCARD_TOAST_HERE, Theme.Colors.Select)
	else
		onFly(worldId)
	end
end

-- Build ----------------------------------------------------------------------

-- The tray along the bottom: built once; refresh decides which pieces show and what they say.
local function buildTray(body: Frame)
	local frame = Builder.blockPlate({
		parent = body,
		name = "Tray",
		color = Theme.Colors.White,
		ink = Theme.Rarity.Common,
		cells = false,
		edges = true,
		position = UDim2.fromScale(Theme.Margin, 1 - Theme.Margin),
		size = UDim2.fromScale(1 - 2 * Theme.Margin, WorldCards.OutpostTray.Height),
		anchor = Vector2.new(0, 1),
		zIndex = Builder.blockTop(body),
	})
	frame.Visible = false
	local top = Builder.blockTop(frame)
	local rows = Builder.blockButtonRows(TRAY_BUTTON_H * WorldCards.OutpostTray.Height * PANEL_H)
	local title = Builder.label({
		parent = frame,
		name = "Title",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(TRAY_TEXT_X, 0.06),
		size = UDim2.fromScale(TRAY_TEXT_W, TRAY_ROW_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	title.TextWrapped = true
	local line = Builder.label({
		parent = frame,
		name = "Ready",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(TRAY_TEXT_X, 0.5),
		size = UDim2.fromScale(TRAY_TEXT_W, TRAY_ROW_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = top,
	})
	local function button(name: string, text: string, color: Color3, x: number, w: number, onTap: () -> ()): Frame
		return Builder.blockButton({
			parent = frame,
			name = name,
			text = text,
			color = color,
			position = UDim2.fromScale(x, TRAY_BUTTON_Y),
			size = UDim2.fromScale(w, TRAY_BUTTON_H),
			textSize = Theme.TextSize.Body,
			rows = rows,
			cells = false,
			hit = true,
			zIndex = top,
		}, onTap)
	end
	local collect = button("Collect", Strings.STARCHART_COLLECT, Builder.roleColor("main"), TRAY_COLLECT_X, TRAY_COLLECT_W, function()
		onCollect(selected)
	end)
	local upgrade = button("Upgrade", Strings.STARCHART_UPGRADE, Builder.roleColor("select"), TRAY_UPGRADE_X, TRAY_UPGRADE_W, function()
		onUpgrade(selected)
	end)
	local visit = button("Visit", Strings.STARCHART_VISIT, Builder.roleColor("main"), TRAY_COLLECT_X, TRAY_COLLECT_W, function()
		Screens.Open("Visit") -- closes the chart; the Visit screen asks the server, the chart decides nothing
	end)
	collect.Visible = false
	upgrade.Visible = false
	visit.Visible = false
	tray = { frame = frame, title = title, line = line, collect = collect, upgrade = upgrade, visit = visit }
end

-- The grid: a ScrollingFrame of two columns of slots (a UIGridLayout cell at the card's aspect), one world card in each slot.
local function buildGrid(body: Frame)
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "Worlds"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(Theme.Margin, GRID_Y)
	frame.Size = UDim2.fromScale(1 - 2 * Theme.Margin, GRID_BOTTOM - GRID_Y)
	frame.CanvasSize = UDim2.fromScale(0, 0)
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	frame.VerticalScrollBarInset = Enum.ScrollBarInset.Always -- a constant window width, so the cards never change size as the bar appears
	frame.ScrollBarThickness = SCROLLBAR_PX
	frame.ScrollBarImageColor3 = Theme.Colors.Outline
	frame.ZIndex = Builder.blockTop(body)
	frame.Parent = body
	scroller = frame

	local layout = Instance.new("UIGridLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.CellPadding = UDim2.fromScale(0, 0) -- the gap is the inset of each card inside its slot
	layout.CellSize = UDim2.fromScale(1 / WorldCards.Columns - CELL_EPSILON, 1 / WorldCards.Columns)
	layout.Parent = frame
	local shape = Instance.new("UIAspectRatioConstraint")
	shape.AspectRatio = WorldCards.Aspect
	shape.AspectType = Enum.AspectType.ScaleWithParentSize
	shape.DominantAxis = Enum.DominantAxis.Width
	shape.Parent = layout

	cardOptions = {
		aspect = WorldCards.Aspect,
		heightShare = WorldCards.HeightShare,
		panelPx = 0,
		onSelect = selectWorld,
		onAction = onAction,
	}
	cards = {}
	slots = {}
	for index, id in ipairs(WorldCardMath.Order(#Worlds)) do
		local slot = Builder.frame({ parent = frame, name = "Slot" .. tostring(id), zIndex = Builder.blockTop(body) + 1 })
		slot.LayoutOrder = index
		slots[id] = slot
		cards[id] = WorldCard.Build(slot, id, false, cardOptions)
	end
	frame:GetPropertyChangedSignal("CanvasPosition"):Connect(updateNear)
	frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateNear)
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("StarChartScreen", 20)
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
		StarChartScreen.Close()
	end)

	local body = Builder.blockPlate({
		parent = root,
		name = "Panel",
		color = Theme.Colors.Panel,
		aspect = PANEL_ASPECT,
		rows = Builder.blockPanelRows(PANEL_H), -- a cream block plate at the panel cell (UI Playbook "Screens after the HUD")
		quiet = true, -- one cream surface behind the text (Clean UI pass)
		position = UDim2.fromScale(0.5, Panels.Shell.Top), -- below the Scrap pill, which ends at Top; the band is inside the panel
		size = UDim2.fromScale(PANEL_W, PANEL_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 2,
	})
	panel = body

	-- The header band: blue, the Star Chart icon, "Worlds n / m" and "Ready n Scrap" pills (refresh), the red X.
	header = Builder.panelHeader(body, { panelId = "StarChart", panelAspect = PANEL_ASPECT, panelHeight = PANEL_H }, function()
		StarChartScreen.Close()
	end)

	buildGrid(body)
	buildTray(body)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "world", "scrap", "outposts", "visit", "codex", "home" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
end

-- Public API -------------------------------------------------------------

function StarChartScreen.IsOpen(): boolean
	return open
end

-- The next Open starts with `worldId` selected and scrolled to (the Ship's next-stop strip asks for this before opening the chart).
function StarChartScreen.Preselect(worldId: number)
	preselect = worldId
end

-- Opens with the current world selected, or the world Preselect named.
function StarChartScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	local focus = preselect
	preselect = nil
	if focus and cards[focus] then
		selected = focus
	elseif State.Has() then
		selected = State.Get().world.current
	end
	refresh()
	startTick()
	root.Enabled = true
	Builder.open(body)
	scrollTo(selected)
end

-- Stops the tick thread before the close tween runs, so nothing keeps redrawing behind a hidden screen.
function StarChartScreen.Close()
	if not open then
		return
	end
	open = false
	stopTick()
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

function StarChartScreen.Toggle()
	if open then
		StarChartScreen.Close()
	else
		StarChartScreen.Open()
	end
end

return StarChartScreen
