--!strict
-- StarterPlayerScripts.Client.UI.Hud: the always-on HUD. The Scrap pill top-left (icon + rolling
-- number) with the Scrap-per-minute line under it, the ship bar top centre (tap opens the ship
-- panel), the Day/Night + weather chip top-right, and the contextual action button bottom-right that
-- shows "Catch!" near a wild alien. A dumb view: every value shown is pushed in by the bootstrap
-- from server state; nothing here computes anything that matters.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Modules = require(Shared:WaitForChild("data"):WaitForChild("Modules"))
local Builder = require(script.Parent.Builder)

local Hud = {}

local SHIP_FILL_SECONDS = 0.4 -- the ship bar's fill eases to a new value over this
local TICK_WIDTH = 0.004 -- milestone tick marks, as a fraction of the bar width
local DEFAULT_TICK_WORLD = 1 -- every player starts here; SetShipTicks replaces these once the profile is in

local gui: ScreenGui? = nil
local setScrapValue: ((number) -> ())? = nil
local clockLabel: TextLabel? = nil
local clockChip: Frame? = nil
local actionButton: Frame? = nil
local actionFace: TextButton? = nil
local breathe: Tween? = nil
local onAction: (() -> ())? = nil
local lastScrap = 0
local shipFill: Frame? = nil
local shipLabel: TextLabel? = nil
local shipTicks: Frame? = nil
local shipTween: Tween? = nil
local onShipTapped: (() -> ())? = nil
local rateLabel: TextLabel? = nil

local function buildScrapPill(root: ScreenGui)
	local pill = Builder.pill({
		parent = root,
		name = "ScrapPill",
		position = UDim2.fromScale(0.015, 0.025),
		size = UDim2.fromScale(0.3, 0.085),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		aspect = 3.6,
	})
	Builder.gradient(pill, Theme.Colors.Trough)
	-- icon placeholder: a gold rounded square until the Scrap icon exists
	local icon = Builder.frame({
		parent = pill,
		name = "Icon",
		position = UDim2.fromScale(0.04, 0.5),
		size = UDim2.fromScale(0.2, 0.72),
		anchor = Vector2.new(0, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		aspect = 1,
	})
	Builder.gradient(icon, Theme.Colors.Featured)
	local number = Builder.label({
		parent = pill,
		name = "Amount",
		text = "0",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.3, 0.5),
		size = UDim2.fromScale(0.66, 0.7),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
	})
	setScrapValue = Builder.rolling(number)
end

local function buildClockChip(root: ScreenGui)
	local chip = Builder.pill({
		parent = root,
		name = "ClockChip",
		position = UDim2.fromScale(0.985, 0.025),
		size = UDim2.fromScale(0.3, 0.075),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Featured,
		stroke = Theme.Stroke.Button,
		aspect = 4.2,
	})
	Builder.gradient(chip, Theme.Colors.Featured)
	clockChip = chip
	clockLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.HUD_DAY,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.7),
		anchor = Vector2.new(0.5, 0.5),
	})
end

-- Cumulative module weights for the default world, until the bootstrap calls SetShipTicks.
local function defaultTicks(): { number }
	local out: { number } = {}
	local acc = 0
	for _, def in ipairs(Modules.Worlds[DEFAULT_TICK_WORLD] or {}) do
		acc += def.weight
		table.insert(out, acc)
	end
	return out
end

-- Ship bar top centre: pill trough, gradient fill clipped to the percent, milestone ticks, centred
-- "Ship N%" text, and an invisible button over it all so a tap opens the ship panel.
local function buildShipBar(root: ScreenGui)
	local trough = Builder.pill({
		parent = root,
		name = "ShipBar",
		position = UDim2.fromScale(0.5, 0.025),
		size = UDim2.fromScale(0.3, 0.075),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		aspect = 4.2,
	})
	trough.ClipsDescendants = true
	local fill = Builder.pill({
		parent = trough,
		name = "Fill",
		size = UDim2.fromScale(0, 1),
		color = Theme.Colors.Featured,
		zIndex = 2,
	})
	Builder.gradient(fill, Theme.Colors.Featured)
	shipFill = fill
	shipTicks = Builder.frame({
		parent = trough,
		name = "Ticks",
		zIndex = 3,
	})
	shipLabel = Builder.label({
		parent = trough,
		name = "Text",
		text = Strings.HUD_SHIP:format(0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.AutoButtonColor = false
	tap.Text = ""
	tap.BorderSizePixel = 0
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 5
	tap.Parent = trough
	tap.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		if onShipTapped then
			onShipTapped()
		end
	end)
	Hud.SetShipTicks(defaultTicks())
end

-- "+N/min" under the Scrap pill; hidden while the camp earns nothing.
local function buildRateLine(root: ScreenGui)
	local label = Builder.label({
		parent = root,
		name = "Rate",
		text = Strings.HUD_SCRAP_PER_MIN:format(Builder.formatNumber(0)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.03, 0.115),
		size = UDim2.fromScale(0.3, 0.045),
		color = Theme.Colors.Confirm,
		xAlign = Enum.TextXAlignment.Left,
	})
	label.Visible = false
	rateLabel = label
end

local function buildActionButton(root: ScreenGui)
	local button = Builder.button({
		parent = root,
		name = "Action",
		text = Strings.ACTION_CATCH,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.975, 0.96),
		size = UDim2.fromScale(0.3, 0.13),
		anchor = Vector2.new(1, 1),
		textSize = Theme.TextSize.Title,
		aspect = 2.3,
	}, function()
		if onAction then
			onAction()
		end
	end)
	button.Visible = false
	actionButton = button
	actionFace = button:FindFirstChild("Face") :: TextButton
end

-- Public API -------------------------------------------------------------

function Hud.Build()
	if gui then
		return
	end
	local root = Builder.screen("HUD", 10)
	gui = root
	buildScrapPill(root)
	buildClockChip(root)
	buildShipBar(root)
	buildRateLine(root)
	buildActionButton(root)
end

-- Ship completion 0..1: eases the fill and shows the whole percent.
function Hud.SetShip(percent01: number)
	local fill, label = shipFill, shipLabel
	if not fill or not label then
		return
	end
	local p = math.clamp(percent01, 0, 1)
	if shipTween then
		shipTween:Cancel()
	end
	local info = TweenInfo.new(SHIP_FILL_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(fill, info, { Size = UDim2.fromScale(p, 1) })
	shipTween = tween
	tween:Play()
	label.Text = Strings.HUD_SHIP:format(math.floor(p * 100))
end

-- Milestone tick marks (cumulative module weights, 0..1). The final mark sits at the bar's end and
-- is skipped, so the caller may pass Economy.milestones(world) as is.
function Hud.SetShipTicks(marks: { number })
	local holder = shipTicks
	if not holder then
		return
	end
	for _, child in ipairs(holder:GetChildren()) do
		child:Destroy()
	end
	for _, mark in ipairs(marks) do
		if mark > 0 and mark < 1 then
			Builder.frame({
				parent = holder,
				name = "Tick",
				position = UDim2.fromScale(mark, 0.5),
				size = UDim2.fromScale(TICK_WIDTH, 1),
				anchor = Vector2.new(0.5, 0.5),
				color = Theme.Colors.White,
				transparency = 0.45,
				zIndex = 3,
			})
		end
	end
end

function Hud.OnShipTapped(callback: () -> ())
	onShipTapped = callback
end

-- Scrap income per second; the line reads "+N/min" and hides when the camp earns nothing.
function Hud.SetRate(perSecond: number)
	local label = rateLabel
	if not label then
		return
	end
	if perSecond <= 0 then
		label.Visible = false
		return
	end
	label.Text = Strings.HUD_SCRAP_PER_MIN:format(Builder.formatNumber(perSecond * 60))
	label.Visible = true
end

function Hud.SetScrap(amount: number)
	if setScrapValue then
		setScrapValue(amount)
	end
	if amount > lastScrap then
		Builder.playSound(Sounds.ScrapTick)
	end
	lastScrap = amount
end

function Hud.SetClock(state: Types.ClockState)
	if not clockLabel or not clockChip then
		return
	end
	local phase = if state.isNight then Strings.HUD_NIGHT else Strings.HUD_DAY
	local weather = Builder.text("WEATHER_" .. state.weather)
	clockLabel.Text = Strings.HUD_CLOCK:format(phase, weather)
	local color = if state.isNight then Theme.Colors.Select else Theme.Colors.Featured
	TweenService:Create(clockChip, TweenInfo.new(Theme.Tween.Open), { BackgroundColor3 = color }):Play()
	local gradient = clockChip:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Builder.lighter(color), color)
	end
end

-- Show the contextual button with this text, or hide it with nil. It breathes while shown.
function Hud.SetAction(text: string?)
	local button, face = actionButton, actionFace
	if not button or not face then
		return
	end
	if text then
		face.Text = text
		if not button.Visible then
			button.Visible = true
			Builder.pop(button, 1.1)
			local scale = button:FindFirstChildOfClass("UIScale")
			if scale then
				task.delay(Theme.Tween.Open, function()
					if not button.Visible then
						return
					end
					local info = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
					local tween = TweenService:Create(scale, info, { Scale = Theme.Scale.Breathe })
					breathe = tween
					tween:Play()
				end)
			end
		end
	elseif button.Visible then
		button.Visible = false
		if breathe then
			breathe:Cancel()
			breathe = nil
		end
		local scale = button:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1
		end
	end
end

function Hud.OnAction(callback: () -> ())
	onAction = callback
end

function Hud.SetVisible(visible: boolean)
	if gui then
		gui.Enabled = visible
	end
end

return Hud
