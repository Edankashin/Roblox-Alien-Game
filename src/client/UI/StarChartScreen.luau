--!strict
-- StarterPlayerScripts.Client.UI.StarChartScreen: the Star Chart, opened from the Ship panel. One card
-- per world in id order (data/Worlds), in a scrolling list so a phone shows two at a time:
--   current world   "You are here"; the card's stroke pulses (Config.StarChartPulseSeconds; held still
--                   under Reduced Motion); no buttons.
--   unlocked, with an outpost   its level, its output per hour, what it has ready (OutpostMath.Pending
--                   against os.time(), refreshed every Config.StarChartTickSeconds while open), and the
--                   Collect, Upgrade and Fly buttons.
--   unlocked, no outpost   Fly only.
--   locked          a dimmed card reading Locked; the first locked world after the highest unlocked one
--                   reads "Next stop" instead.
-- Every tap asks the server (CollectOutpost, UpgradeOutpost, FlyTo; one request in flight) and toasts
-- the answer; the buttons only dim to hint what a tap would do, they never block it, so the server's
-- reason always reaches the player. The mirror (State: "world", "scrap", "profile") is all the cards
-- read; OutpostsChanged, ScrapChanged and WorldChanged keep it current. Nothing here decides anything.
-- Both loops stop when the screen closes: the pulse tween is cancelled and the tick thread is
-- task.cancel'ed in Close.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local OutpostMath = require(Shared:WaitForChild("OutpostMath"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Prefs = require(script.Parent.Parent.Prefs)

local StarChartScreen = {}

-- One world's card and the pieces refresh rewrites.
type Card = {
	worldId: number,
	frame: Frame,
	stroke: UIStroke,
	name: TextLabel,
	level: TextLabel, -- "Outpost Lv 2", top right
	line: TextLabel, -- the status line, or the outpost's output per hour
	pending: TextLabel,
	collect: Frame,
	upgrade: Frame,
	fly: Frame,
}

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close button
-- reaches down to 0.155, so the list starts under it.
local LIST_Y = 0.17
local LIST_H = 0.8
-- Card geometry in units of the visible list height: every size is a Scale of the canvas, which is
-- PAGES list-heights tall, so each is divided by PAGES when it is applied.
local CARD_H = 0.56
local CARD_GAP = 0.04
local SCROLLBAR_PX = 6

-- Inside a card, as fractions of the card.
local NAME_X = 0.03
local NAME_W = 0.55
local NAME_Y = 0.05
local NAME_H = 0.22
local LEVEL_X = 0.6
local LEVEL_W = 0.37
local LINE_Y = 0.29
local LINE_H = 0.15
local PENDING_Y = 0.45
local PENDING_H = 0.15
local BUTTON_Y = 0.63
local BUTTON_H = 0.33
local COLLECT_X = 0.03
local COLLECT_W = 0.3
local UPGRADE_X = 0.35
local UPGRADE_W = 0.36
local FLY_X = 0.73
local FLY_W = 0.24
local FLY_ALONE_W = 0.34

local COLLECT_COLOR = Theme.Colors.Featured
local UPGRADE_COLOR = Theme.Colors.Confirm
local FLY_COLOR = Theme.Colors.Select
local DIM_COLOR = Theme.Rarity.Common
local LOCKED_TRANSPARENCY = 0.45
local PULSE_PEAK = Theme.Stroke.Panel * 1.5 -- the pulsing stroke swells to this thickness (px)

local gui: ScreenGui? = nil
local panel: Frame? = nil
local cards: { Card } = {}
local open = false
local busy = false -- one request in flight at a time
local pulseTween: Tween? = nil
local pulseCard: Card? = nil
local tickThread: thread? = nil

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

local function setButton(container: Frame, text: string, color: Color3)
	recolorButton(container, color)
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.Text = text
	end
end

-- The world's name from the strings table (WORLD_<id>), or the Worlds row, or the key itself.
local function worldName(worldId: number): string
	local key = "WORLD_" .. tostring(worldId)
	local text = Builder.text(key)
	if text ~= key then
		return text
	end
	local def = Worlds[worldId]
	return if def then def.name else key
end

-- The canvas height in list-heights: the cards and the gaps between them.
local function pages(): number
	local count = #Worlds
	return math.max(1, count * CARD_H + (count - 1) * CARD_GAP)
end

local function outpostOf(profile: Types.Profile, worldId: number): Types.OutpostState?
	local outposts: { [string]: Types.OutpostState }? = profile.world.outposts -- a mirror older than the field reads as none
	return if outposts then outposts[tostring(worldId)] else nil
end

-- The pulse -----------------------------------------------------------------

-- The current card's resting stroke: gold, the panel's thickness.
local function restStroke(card: Card)
	card.stroke.Color = Theme.Colors.Featured
	card.stroke.Thickness = Theme.Stroke.Panel
end

-- Cancels the pulse and puts the card's stroke back to rest.
local function stopPulse()
	local tween, card = pulseTween, pulseCard
	pulseTween = nil
	pulseCard = nil
	if tween then
		tween:Cancel()
		tween:Destroy()
	end
	if card then
		restStroke(card)
	end
end

-- Starts the pulse on `card` (the current world); a card already pulsing is left alone. Under Reduced
-- Motion the stroke holds still at rest.
local function startPulse(card: Card)
	if pulseCard == card and (pulseTween ~= nil or Prefs.ReducedMotion()) then
		return
	end
	stopPulse()
	pulseCard = card
	restStroke(card)
	if Prefs.ReducedMotion() then
		return
	end
	local half = math.max(Config.StarChartPulseSeconds / 2, 0.05)
	local tween = TweenService:Create(
		card.stroke,
		TweenInfo.new(half, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Thickness = PULSE_PEAK, Color = Builder.lighter(Theme.Colors.Featured) }
	)
	pulseTween = tween
	tween:Play()
end

-- Refresh ----------------------------------------------------------------

local function showOnly(card: Card, collect: boolean, upgrade: boolean, fly: boolean)
	card.collect.Visible = collect
	card.upgrade.Visible = upgrade
	card.fly.Visible = fly
end

local function refreshCard(card: Card, profile: Types.Profile, unlocked: { [number]: boolean }, highest: number, now: number)
	local id = card.worldId
	card.name.Text = worldName(id)
	card.level.Visible = false
	card.pending.Visible = false
	card.frame.BackgroundTransparency = 0
	card.frame.BackgroundColor3 = Theme.Colors.White

	if id == profile.world.current then
		-- (a) here: gold, pulsing, no buttons
		card.line.Text = Strings.STARCHART_HERE
		card.line.TextColor3 = Theme.Colors.Heading
		showOnly(card, false, false, false)
		startPulse(card)
		return
	end
	if pulseCard == card then
		stopPulse()
	end
	card.line.TextColor3 = Theme.Colors.White

	if not unlocked[id] then
		-- (d) locked: dimmed; the next one on the chart says what opens it
		card.line.Text = if id == highest + 1 then Strings.STARCHART_NEXT else Strings.STARCHART_LOCKED
		card.frame.BackgroundColor3 = DIM_COLOR
		card.frame.BackgroundTransparency = LOCKED_TRANSPARENCY
		card.stroke.Color = DIM_COLOR
		card.stroke.Thickness = Theme.Stroke.Text
		showOnly(card, false, false, false)
		return
	end

	card.stroke.Color = Theme.Colors.Select
	card.stroke.Thickness = Theme.Stroke.Button
	local state = outpostOf(profile, id)
	if not state then
		-- (c) unlocked, no outpost: Fly alone, bottom right
		card.line.Text = ""
		card.fly.Position = UDim2.fromScale(1 - NAME_X, BUTTON_Y)
		card.fly.AnchorPoint = Vector2.new(1, 0)
		card.fly.Size = UDim2.fromScale(FLY_ALONE_W, BUTTON_H)
		setButton(card.fly, Strings.STARCHART_FLY, FLY_COLOR)
		showOnly(card, false, false, true)
		return
	end

	-- (b) unlocked, with an outpost
	local rates = OutpostMath.Level(state.level)
	local ready = OutpostMath.Pending(state, id, now)
	card.level.Text = Strings.STARCHART_OUTPOST:format(state.level)
	card.level.Visible = true
	card.line.Text = Strings.STARCHART_OUTPUT:format(rates.scrapPerHour, rates.materialsPerHour)
	card.pending.Text = Strings.STARCHART_PENDING:format(ready.scrap, ready.materialCount)
	card.pending.Visible = true

	local nothing = ready.scrap <= 0 and ready.materialCount <= 0
	setButton(card.collect, Strings.STARCHART_COLLECT, if nothing then DIM_COLOR else COLLECT_COLOR)
	local cost = OutpostMath.UpgradeCost(state.level)
	if cost == nil then
		setButton(card.upgrade, Strings.STARCHART_MAXED, DIM_COLOR)
	else
		setButton(card.upgrade, Strings.STARCHART_UPGRADE:format(cost), if profile.scrap < cost then DIM_COLOR else UPGRADE_COLOR)
	end
	card.fly.Position = UDim2.fromScale(FLY_X, BUTTON_Y)
	card.fly.AnchorPoint = Vector2.zero
	card.fly.Size = UDim2.fromScale(FLY_W, BUTTON_H)
	setButton(card.fly, Strings.STARCHART_FLY, FLY_COLOR)
	showOnly(card, true, true, true)
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local unlocked: { [number]: boolean } = {}
	local highest = 0
	for _, id in ipairs(profile.world.unlocked) do
		unlocked[id] = true
		highest = math.max(highest, id)
	end
	unlocked[profile.world.current] = true
	highest = math.max(highest, profile.world.current)
	local now = os.time()
	for _, card in ipairs(cards) do
		refreshCard(card, profile, unlocked, highest, now)
	end
end

-- The tick -------------------------------------------------------------------

local function stopTick()
	local thread = tickThread
	tickThread = nil
	if thread and coroutine.status(thread) ~= "dead" then
		task.cancel(thread)
	end
end

-- Redraws every Config.StarChartTickSeconds so the ready amounts count up while the chart is open.
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

-- Build ----------------------------------------------------------------------

-- One world's card: every piece is built once; refresh decides which show and what they say.
local function buildCard(parent: ScrollingFrame, worldId: number, canvasPages: number): Card
	local frame = Builder.frame({
		parent = parent,
		name = "World_" .. worldId,
		size = UDim2.fromScale(1, CARD_H / canvasPages),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = DIM_COLOR,
		zIndex = 3,
	})
	frame.LayoutOrder = worldId
	local stroke = frame:FindFirstChildOfClass("UIStroke") :: UIStroke
	local name = Builder.label({
		parent = frame,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(NAME_X, NAME_Y),
		size = UDim2.fromScale(NAME_W, NAME_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local level = Builder.label({
		parent = frame,
		name = "Level",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(LEVEL_X, NAME_Y),
		size = UDim2.fromScale(LEVEL_W, NAME_H),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})
	local line = Builder.label({
		parent = frame,
		name = "Line",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(NAME_X, LINE_Y),
		size = UDim2.fromScale(1 - 2 * NAME_X, LINE_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local pending = Builder.label({
		parent = frame,
		name = "Pending",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(NAME_X, PENDING_Y),
		size = UDim2.fromScale(1 - 2 * NAME_X, PENDING_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local collect = Builder.button({
		parent = frame,
		name = "Collect",
		text = Strings.STARCHART_COLLECT,
		color = COLLECT_COLOR,
		position = UDim2.fromScale(COLLECT_X, BUTTON_Y),
		size = UDim2.fromScale(COLLECT_W, BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		onCollect(worldId)
	end)
	local upgrade = Builder.button({
		parent = frame,
		name = "Upgrade",
		text = Strings.STARCHART_UPGRADE,
		color = UPGRADE_COLOR,
		position = UDim2.fromScale(UPGRADE_X, BUTTON_Y),
		size = UDim2.fromScale(UPGRADE_W, BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		onUpgrade(worldId)
	end)
	local fly = Builder.button({
		parent = frame,
		name = "Fly",
		text = Strings.STARCHART_FLY,
		color = FLY_COLOR,
		position = UDim2.fromScale(FLY_X, BUTTON_Y),
		size = UDim2.fromScale(FLY_W, BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		onFly(worldId)
	end)
	return {
		worldId = worldId,
		frame = frame,
		stroke = stroke,
		name = name,
		level = level,
		line = line,
		pending = pending,
		collect = collect,
		upgrade = upgrade,
		fly = fly,
	}
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

	-- Header tab straddling the top edge, sky blue, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.42, 0.11),
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
		text = Strings.STARCHART_TITLE,
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
		StarChartScreen.Close()
	end)

	-- The list: a ScrollingFrame with a thin dark bar. Its canvas is `canvasPages` list-heights tall and
	-- children scale against the canvas, so each card height and the gap are divided by it.
	local canvasPages = pages()
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Worlds"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(Theme.Margin, LIST_Y)
	scroller.Size = UDim2.fromScale(1 - Theme.Margin * 2, LIST_H)
	scroller.ZIndex = 3
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroller.CanvasSize = UDim2.fromScale(0, canvasPages)
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = Theme.Colors.Trough
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.Parent = body
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(CARD_GAP / canvasPages, 0)
	layout.Parent = scroller

	cards = {}
	for id = 1, #Worlds do
		table.insert(cards, buildCard(scroller, id, canvasPages))
	end

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "world", "scrap" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
	-- Reduced Motion turned on or off while open: restart the pulse the new way.
	Prefs.OnChanged(function()
		if open then
			stopPulse()
			refresh()
		end
	end)
end

-- Public API -------------------------------------------------------------

function StarChartScreen.IsOpen(): boolean
	return open
end

function StarChartScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	startTick()
	root.Enabled = true
	Builder.open(body)
end

-- Stops the pulse tween and the tick thread before the close tween runs, so nothing keeps redrawing
-- (or tweening a stroke) behind a hidden screen.
function StarChartScreen.Close()
	if not open then
		return
	end
	open = false
	stopTick()
	stopPulse()
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
