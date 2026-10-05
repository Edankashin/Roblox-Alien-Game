--!strict
-- StarterPlayerScripts.Client.UI.PowerUpBar: the power-up row bottom-left. A small "Power-ups" caption
-- over one square slot per power-up the player holds or has running, in data order: a chunky button
-- with the power-up's initial, an "xN" count badge bottom-right while some are held, and while one is
-- running a Select-coloured ring around the face plus a Select under-bar with the time left, counted
-- down each second from the end time State keeps between the server's BuffsChanged pushes. A tap asks
-- the server (UsePowerUp) and a refusal becomes a toast. The whole bar hides when there is nothing to
-- show. Nothing here decides anything: what is held and what is running are the server's.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local PowerUps = require(Shared:WaitForChild("data"):WaitForChild("PowerUps"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)

local PowerUpBar = {}

type PowerUpDef = { name: string, seconds: number, effect: string, value: number, sellable: boolean }
local defs: { [string]: PowerUpDef } = PowerUps

-- Display order (the data table is a dictionary; this is the order the design lists them in).
local ORDER = { "SpeedBurst", "SteadyHands", "ScannerPulse", "LuckyCharm", "ScrapMagnet", "DoubleShift" }

-- One slot. Children are built once and refreshed in place.
type Slot = {
	id: string,
	frame: Frame,
	button: Frame,
	ring: UIStroke?, -- the face's border stroke, recoloured while the power-up runs
	badge: Frame,
	badgeLabel: TextLabel,
	bar: Frame,
	barLabel: TextLabel,
}

-- Screen layout. The bar sits in the bottom-left corner, under the left menu stack (which ends near
-- y 0.8) and clear of the action button bottom-right.
local LEFT = 0.015
local BOTTOM = 0.975
local WIDTH = 0.6
local HEIGHT = 0.17 -- caption plus slot row
local CAPTION_H = 0.165 -- of the bar
local ROW_Y = 0.2
local ROW_H = 0.8
local SLOT_GAP = 0.012 -- of the row width
local SLOT_ASPECT = 0.7 -- a square button with the under-bar beneath it
local BUTTON_H = 0.68 -- of the slot; the under-bar takes the rest
local BAR_H = 0.28
local TICK_SECONDS = 1 -- the running timers count down this often

local gui: ScreenGui? = nil
local slots: { Slot } = {}
local wanted = true -- the bootstrap's SetVisible; the bar also hides itself when empty
local hasAny = false
local pending = false -- one server request in flight at a time

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

local function powerUpName(id: string): string
	return Builder.text("POWERUP_" .. id)
end

local function applyVisible()
	local root = gui
	if root then
		root.Enabled = wanted and hasAny
	end
end

-- The ring: the face's own border stroke, Select and thicker while running, the button's dark edge otherwise.
local function setRing(slot: Slot, active: boolean)
	local ring = slot.ring
	if not ring then
		return
	end
	if active then
		ring.Color = Theme.Colors.Select
		ring.Thickness = Theme.Stroke.Panel
	else
		ring.Color = Builder.darker(Theme.Colors.Featured)
		ring.Thickness = Theme.Stroke.Button
	end
end

-- Server calls -------------------------------------------------------------

-- Asks the server to start a held power-up. Runs in its own thread: callers are taps. The server
-- pushes InventoryChanged and BuffsChanged itself; this only toasts the answer.
local function use(id: string)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("UsePowerUp"):InvokeServer(id)
		pending = false
		if ok == true then
			Toast.Show(Strings.TOAST_POWERUP_USED:format(powerUpName(id)), Theme.Colors.Select)
		elseif reason == "AlreadyActive" then
			Toast.Show(Strings.TOAST_POWERUP_ACTIVE:format(powerUpName(id)), Theme.Rarity.Common)
		else
			print(("[%s] UsePowerUp refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- Slots ---------------------------------------------------------------------

local function buildSlot(parent: Frame, order: number, id: string): Slot
	local frame = Builder.frame({
		parent = parent,
		name = id,
		size = UDim2.fromScale(1, 1),
		aspect = SLOT_ASPECT,
	})
	frame.LayoutOrder = order
	frame.Visible = false

	local button = Builder.button({
		parent = frame,
		name = "Button",
		text = string.upper(string.sub(powerUpName(id), 1, 1)),
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, BUTTON_H),
		anchor = Vector2.new(0.5, 0),
		textSize = Theme.TextSize.Title,
		aspect = 1,
	}, function()
		use(id)
	end)
	local ring: UIStroke? = nil
	local face = button:FindFirstChild("Face")
	if face then
		for _, child in ipairs(face:GetChildren()) do
			if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
				ring = child
			end
		end
	end

	-- "xN" count badge bottom-right of the button while some are held.
	local badge = Builder.pill({
		parent = button,
		name = "Count",
		position = UDim2.fromScale(1.08, 1.08),
		size = UDim2.fromScale(0.62, 0.38),
		anchor = Vector2.new(1, 1),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 5,
	})
	local badgeLabel = Builder.label({
		parent = badge,
		name = "Text",
		text = Strings.CODEX_COUNT_BADGE:format(0),
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.85),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 6,
	})
	badge.Visible = false

	-- Under-bar with the time left while the power-up runs.
	local bar = Builder.pill({
		parent = frame,
		name = "Timer",
		position = UDim2.fromScale(0.5, 1),
		size = UDim2.fromScale(1, BAR_H),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.Select,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 2,
	})
	Builder.gradient(bar, Theme.Colors.Select)
	local barLabel = Builder.label({
		parent = bar,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Min,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.85),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	bar.Visible = false

	return {
		id = id,
		frame = frame,
		button = button,
		ring = ring,
		badge = badge,
		badgeLabel = badgeLabel,
		bar = bar,
		barLabel = barLabel,
	}
end

-- Refresh ----------------------------------------------------------------------

local function refresh()
	if not gui then
		return
	end
	local held: { [string]: number } = if State.Has() then State.Get().inventory.powerUps else {}
	local buffs = State.GetBuffs()
	local now = State.Now()
	local any = false
	for _, slot in ipairs(slots) do
		local count = held[slot.id] or 0
		local endsAt = buffs[slot.id]
		local active = endsAt ~= nil and endsAt > now
		local show = count > 0 or active
		slot.frame.Visible = show
		if not show then
			continue
		end
		any = true
		slot.badge.Visible = count > 0
		slot.badgeLabel.Text = Strings.CODEX_COUNT_BADGE:format(count)
		setRing(slot, active)
		slot.bar.Visible = active
		if active and endsAt then
			slot.barLabel.Text = formatTime(endsAt - now)
		end
	end
	hasAny = any
	applyVisible()
end

-- Public API -------------------------------------------------------------

-- Creates the ScreenGui once and connects the pushes. Refreshes itself each second while any
-- power-up is running so the timers count down between the server's pushes.
function PowerUpBar.Build()
	if gui then
		return
	end
	local root = Builder.screen("PowerUps", 10)
	root.Enabled = false
	gui = root

	local bar = Builder.frame({
		parent = root,
		name = "Bar",
		position = UDim2.fromScale(LEFT, BOTTOM),
		size = UDim2.fromScale(WIDTH, HEIGHT),
		anchor = Vector2.new(0, 1),
	})
	Builder.label({
		parent = bar,
		name = "Caption",
		text = Strings.HUD_POWERUPS,
		textSize = Theme.TextSize.Min,
		size = UDim2.fromScale(1, CAPTION_H),
		xAlign = Enum.TextXAlignment.Left,
	})
	local row = Builder.frame({
		parent = bar,
		name = "Slots",
		position = UDim2.fromScale(0, ROW_Y),
		size = UDim2.fromScale(1, ROW_H),
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(SLOT_GAP, 0)
	layout.Parent = row

	slots = {}
	for order, id in ipairs(ORDER) do
		if defs[id] then
			table.insert(slots, buildSlot(row, order, id))
		end
	end

	State.OnChanged("inventory", refresh)
	State.OnChanged("buffs", refresh)
	refresh()

	task.spawn(function()
		while gui do
			task.wait(TICK_SECONDS)
			if next(State.GetBuffs()) ~= nil then
				refresh()
			end
		end
	end)
end

-- The bootstrap hides the bar behind a catch or a modal; the bar also stays hidden while empty.
function PowerUpBar.SetVisible(visible: boolean)
	wanted = visible
	applyVisible()
end

return PowerUpBar
