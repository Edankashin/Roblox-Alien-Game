--!strict
-- StarterPlayerScripts.Client.UI.Hud: the always-on HUD. Milestone 2 pieces only: the Scrap pill
-- top-left (icon + rolling number), the Day/Night + weather chip top-right, and the contextual action
-- button bottom-right that shows "Catch!" near a wild alien. Reads state pushed from the server;
-- never computes anything that matters.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Builder = require(script.Parent.Builder)

local Hud = {}

local gui: ScreenGui? = nil
local setScrapValue: ((number) -> ())? = nil
local clockLabel: TextLabel? = nil
local clockChip: Frame? = nil
local actionButton: Frame? = nil
local actionFace: TextButton? = nil
local breathe: Tween? = nil
local onAction: (() -> ())? = nil
local lastScrap = 0

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
	buildActionButton(root)
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
	clockLabel.Text = ("%s · %s"):format(phase, weather)
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
