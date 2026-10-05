--!strict
-- StarterPlayerScripts.Client.UI.Toast: short messages that stack top centre under the HUD's top
-- row. Each toast is a dark pill with a coloured square icon on the left and outlined white text. It
-- slides down from above with a Back ease, waits Theme.Tween.Toast seconds, fades out, and the stack
-- re-flows. At most three show at once; the oldest leaves first. Pure presentation: callers decide
-- what to say (usually a server refusal reason mapped to a TOAST_* string). Banner is the wide,
-- coloured variant for server-wide announcements; it shares the stack.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Builder = require(script.Parent.Builder)

local Toast = {}

local MAX_VISIBLE = 3
local TOP = 0.12 -- first slot, below the HUD's top row
local GAP = 0.012 -- between stacked toasts, in screen height
local WIDTH = 0.42 -- of the screen; the aspect constraint derives the height from this
local MAX_HEIGHT = 0.2 -- generous cap so the width stays the binding side of the aspect fit
local ASPECT = 7
local BANNER_WIDTH = 0.7 -- the server-wide banner is wider and in the accent colour
local BANNER_ASPECT = 9

type Entry = { group: CanvasGroup, leaving: boolean, height: number }

local gui: ScreenGui? = nil
local entries: { Entry } = {} -- live toasts, oldest first

-- Height of one toast in screen Scale, from the width-bound aspect fit (so slots stack tightly).
local function heightScale(root: ScreenGui, width: number, aspect: number): number
	local abs = root.AbsoluteSize
	if abs.X <= 0 or abs.Y <= 0 then
		return MAX_HEIGHT
	end
	local px = math.min(width * abs.X / aspect, MAX_HEIGHT * abs.Y)
	return px / abs.Y
end

-- The slot a given entry occupies: the heights of everything above it, plus gaps.
local function slotPosition(index: number): UDim2
	local y = TOP
	for i = 1, index - 1 do
		y += entries[i].height + GAP
	end
	return UDim2.fromScale(0.5, y)
end

local function reflow()
	if not gui then
		return
	end
	local info = TweenInfo.new(Theme.Tween.Close, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for index, entry in ipairs(entries) do
		TweenService:Create(entry.group, info, { Position = slotPosition(index) }):Play()
	end
end

local function dismiss(entry: Entry)
	if entry.leaving then
		return
	end
	entry.leaving = true
	local index = table.find(entries, entry)
	if index then
		table.remove(entries, index)
	end
	local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(entry.group, info, { GroupTransparency = 1 })
	tween.Completed:Once(function()
		entry.group:Destroy()
	end)
	tween:Play()
	reflow()
end

-- Public API -------------------------------------------------------------

-- Creates the ScreenGui once. Show calls this, so wiring code may skip it.
function Toast.Build()
	if gui then
		return
	end
	gui = Builder.screen("Toasts", 40)
end

local function push(text: string, accent: Color3, banner: boolean, seconds: number)
	Toast.Build()
	local root = gui
	if not root then
		return
	end
	while #entries >= MAX_VISIBLE do
		dismiss(entries[1])
	end
	local width = if banner then BANNER_WIDTH else WIDTH
	local aspect = if banner then BANNER_ASPECT else ASPECT
	local height = heightScale(root, width, aspect)

	-- A CanvasGroup so the whole pill (strokes included) fades with one GroupTransparency tween.
	local group = Instance.new("CanvasGroup")
	group.Name = if banner then "Banner" else "Toast"
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.AnchorPoint = Vector2.new(0.5, 0)
	group.Size = UDim2.fromScale(width, MAX_HEIGHT)
	group.Position = UDim2.fromScale(0.5, -height)
	group.ZIndex = 1
	Builder.aspect(group, aspect)
	group.Parent = root

	-- A toast is a dark pill with a coloured icon; a banner is the colour itself, edge to edge.
	local fill = if banner then accent else Theme.Colors.Trough
	local pill = Builder.pill({
		parent = group,
		name = "Pill",
		color = fill,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 1,
	})
	Builder.gradient(pill, fill)
	if banner then
		Builder.label({
			parent = pill,
			name = "Text",
			text = text,
			textSize = Theme.TextSize.Label,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.94, 0.72),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 2,
		})
	else
		local icon = Builder.frame({
			parent = pill,
			name = "Icon",
			position = UDim2.fromScale(0.03, 0.5),
			size = UDim2.fromScale(0.12, 0.62),
			anchor = Vector2.new(0, 0.5),
			color = accent,
			corner = Theme.Corner.Card,
			stroke = Theme.Stroke.Text,
			aspect = 1,
			zIndex = 2,
		})
		Builder.gradient(icon, accent)
		Builder.label({
			parent = pill,
			name = "Text",
			text = text,
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.16, 0.5),
			size = UDim2.fromScale(0.81, 0.7),
			anchor = Vector2.new(0, 0.5),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = 2,
		})
	end

	local entry: Entry = { group = group, leaving = false, height = height }
	table.insert(entries, entry)
	local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(group, info, { Position = slotPosition(#entries) }):Play()
	task.delay(seconds, function()
		dismiss(entry)
	end)
end

function Toast.Show(text: string, color: Color3?)
	push(text, color or Theme.Colors.Featured, false, Theme.Tween.Toast)
end

-- Server-wide announcement: a wide banner in the given colour (usually the tier colour).
function Toast.Banner(text: string, color: Color3, seconds: number?)
	push(text, color, true, seconds or Theme.Tween.Toast)
end

return Toast
