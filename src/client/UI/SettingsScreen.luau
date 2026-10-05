--!strict
-- StarterPlayerScripts.Client.UI.SettingsScreen: the Settings panel. One row per data/Settings entry,
-- in its order: the label on the left, the control on the right. A "level" key shows one chunky
-- button per level (Off / Low / Mid / High) with the active one green and the rest grey; a "toggle"
-- key shows one button that reads On (green) or Off (grey) and flips. Every tap asks the server
-- (SetSetting, one request in flight); the server stores the value and pushes SettingsChanged, State
-- mirrors it and the rows redraw from the mirror. Nothing here decides anything: the buttons show
-- what the server said last, and a refusal is printed. The hint at the bottom is the one place the
-- body font is allowed (a long sentence, UI Playbook).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Settings = require(Shared:WaitForChild("data"):WaitForChild("Settings"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)

local SettingsScreen = {}

-- One row: its definition, the level buttons by level (level rows) or the single toggle button.
type Row = { def: Settings.SettingDef, levelButtons: { Frame }, toggle: Frame? }

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close button
-- reaches down to 0.155, so the rows start under it; the hint takes the bottom.
local ROWS_Y = 0.17
local ROWS_H = 0.66
local HINT_Y = 0.85
local HINT_H = 0.11
local ROW_GAP = 0.045 -- of the rows frame, between rows
local LABEL_X = 0.03 -- of a row
local LABEL_W = 0.35
local CONTROLS_X = 0.39
local CONTROLS_W = 0.59
local CONTROL_H = 0.78 -- of a row: with four rows that is over 0.11 of the panel, thumb-sized
local LEVEL_GAP = 0.03 -- of the controls frame, between level buttons
local TOGGLE_W = 0.4 -- of the controls frame

local ACTIVE = Theme.Colors.Confirm
local INACTIVE = Theme.Rarity.Common

local gui: ScreenGui? = nil
local panel: Frame? = nil
local rows: { Row } = {}
local open = false
local pending = false -- one SetSetting in flight at a time

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

local function faceOf(container: Frame): TextButton?
	local face = container:FindFirstChild("Face")
	return if face and face:IsA("TextButton") then face else nil
end

-- The value the server holds for `def` (the mirror), or the data default while nothing has arrived.
local function currentValue(def: Settings.SettingDef): number
	local value = State.GetSettings()[def.key]
	return if type(value) == "number" then value else def.default
end

-- Refresh ----------------------------------------------------------------

local function refreshRow(row: Row)
	local value = currentValue(row.def)
	for index, button in ipairs(row.levelButtons) do
		recolorButton(button, if index - 1 == value then ACTIVE else INACTIVE)
	end
	local toggle = row.toggle
	if toggle then
		local on = value == 1
		recolorButton(toggle, if on then ACTIVE else INACTIVE)
		local face = faceOf(toggle)
		if face then
			face.Text = if on then Strings.SETTINGS_ON else Strings.SETTINGS_OFF
		end
	end
end

local function refresh()
	if not open then
		return
	end
	for _, row in ipairs(rows) do
		refreshRow(row)
	end
end

-- Server calls -------------------------------------------------------------

-- Asks the server to store `value` for `key`. Runs in its own thread: callers are taps. On ok nothing
-- else happens here: the SettingsChanged push updates State and the rows redraw from it.
local function send(key: string, value: number)
	if pending then
		return
	end
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("SetSetting"):InvokeServer(key, value)
		pending = false
		if ok ~= true then
			print(("[%s] SetSetting refused: %s"):format(Config.WorkingTitle, tostring(reason)))
			refresh()
		end
	end)
end

-- Rows -------------------------------------------------------------------

-- One chunky button per level, laid out right to left inside the controls frame.
local function buildLevelControls(controls: Frame, row: Row)
	local def = row.def
	local levels = def.levels
	local count = if levels then #levels else 0
	if count == 0 then
		return
	end
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(LEVEL_GAP, 0)
	layout.Parent = controls
	local width = (1 - LEVEL_GAP * (count - 1)) / count
	for index = 1, count do
		local level = index - 1
		local button = Builder.button({
			parent = controls,
			name = "Level" .. level,
			text = Builder.text("SETTINGS_LEVEL_" .. level),
			color = INACTIVE,
			size = UDim2.fromScale(width, 1),
			textSize = Theme.TextSize.Body,
			zIndex = 4,
		}, function()
			if currentValue(def) ~= level then
				send(def.key, level)
			end
		end)
		button.LayoutOrder = index
		table.insert(row.levelButtons, button)
	end
end

-- One chunky button on the right that reads On or Off and asks for the other value.
local function buildToggleControl(controls: Frame, row: Row)
	local def = row.def
	row.toggle = Builder.button({
		parent = controls,
		name = "Toggle",
		text = Strings.SETTINGS_OFF,
		color = INACTIVE,
		position = UDim2.fromScale(1, 0.5),
		size = UDim2.fromScale(TOGGLE_W, 1),
		anchor = Vector2.new(1, 0.5),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		send(def.key, if currentValue(def) == 1 then 0 else 1)
	end)
end

-- A white card: the setting's name on the left, its control on the right.
local function buildRow(parent: Frame, index: number, def: Settings.SettingDef, share: number): Row
	local card = Builder.frame({
		parent = parent,
		name = "Row_" .. def.key,
		size = UDim2.fromScale(1, share),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	card.LayoutOrder = index
	Builder.label({
		parent = card,
		name = "Label",
		text = Builder.text("SETTINGS_" .. def.key),
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(LABEL_X, 0.5),
		size = UDim2.fromScale(LABEL_W, 0.84),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local controls = Builder.frame({
		parent = card,
		name = "Controls",
		position = UDim2.fromScale(CONTROLS_X, 0.5),
		size = UDim2.fromScale(CONTROLS_W, CONTROL_H),
		anchor = Vector2.new(0, 0.5),
		zIndex = 4,
	})
	local row: Row = { def = def, levelButtons = {}, toggle = nil }
	if def.kind == "level" then
		buildLevelControls(controls, row)
	else
		buildToggleControl(controls, row)
	end
	return row
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("SettingsScreen", 20)
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
		SettingsScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.6, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = 1.3,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, sky blue, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.44, 0.11),
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
		text = Strings.SETTINGS_TITLE,
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
		SettingsScreen.Close()
	end)

	-- The rows: a vertical list that shares ROWS_H between the data's entries with a gap.
	local holder = Builder.frame({
		parent = body,
		name = "Rows",
		position = UDim2.fromScale(Theme.Margin, ROWS_Y),
		size = UDim2.fromScale(1 - 2 * Theme.Margin, ROWS_H),
		zIndex = 3,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = holder
	local count = #Settings.Order
	local share = if count > 0 then (1 - ROW_GAP * (count - 1)) / count else 1
	rows = {}
	for index, def in ipairs(Settings.Order) do
		table.insert(rows, buildRow(holder, index, def, share))
	end

	-- The hint: the one long line, in the body font, navy, no stroke.
	Builder.label({
		parent = body,
		name = "Hint",
		text = Strings.SETTINGS_HINT,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		font = Theme.BodyFont,
		position = UDim2.fromScale(Theme.Margin, HINT_Y),
		size = UDim2.fromScale(1 - 2 * Theme.Margin, HINT_H),
		zIndex = 3,
	})

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	State.OnChanged("settings", refresh)
end

-- Public API -------------------------------------------------------------

function SettingsScreen.IsOpen(): boolean
	return open
end

function SettingsScreen.Open()
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

function SettingsScreen.Close()
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

function SettingsScreen.Toggle()
	if open then
		SettingsScreen.Close()
	else
		SettingsScreen.Open()
	end
end

return SettingsScreen
