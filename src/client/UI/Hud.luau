--!strict
-- StarterPlayerScripts.Client.UI.Hud: the always-on HUD. The Scrap pill top-left (icon + rolling
-- number) with the Scrap-per-minute line under it, the ship bar top centre (tap opens the ship
-- panel) with the luck line or the event banner under it, the Day/Night + weather chip top-right with
-- the biome chip and the Meteor Shower countdown chip stacked beneath, and the contextual action
-- button bottom-right that shows "Catch!" near a wild alien. A dumb view: every value shown is pushed
-- in by the bootstrap from server state; nothing here computes anything that matters.

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
local menuGui: ScreenGui? = nil -- the icon stack sits above modal dims (MENU_DISPLAY_ORDER) so panels can be switched
local setScrapValue: ((number) -> ())? = nil
local clockLabel: TextLabel? = nil
local clockChip: Frame? = nil
local biomeLabel: TextLabel? = nil
local menuButtons: { [string]: Frame } = {}
local menuCount = 0

local MENU_DISPLAY_ORDER = 25 -- above the modal screens (20) and their backdrops, below reveals (30) and toasts (40)
local MENU_TOP = 0.19 -- the icon stack starts here, under the Scrap pill and its rate line
local MENU_SLOT = 0.13 -- vertical space per entry: the square button plus its label; six entries end at 0.97
local MENU_BUTTON = 0.095 -- square button height (width follows through the aspect constraint)
local MENU_LEFT = 0.015
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
local luckLabel: TextLabel? = nil
local luckShown = false -- the luck line's own rule (luck is not exactly 1); the event banner overrides it
local showerChip: Frame? = nil
local showerLabel: TextLabel? = nil
local banner: Frame? = nil
local bannerText: TextLabel? = nil
local bannerChip: Frame? = nil
local bannerChipLabel: TextLabel? = nil

local BANNER_TEXT_LEFT = 0.14 -- the banner text starts after the icon square
local BANNER_TEXT_WIDTH = 0.56 -- with the luck chip showing on the right
local BANNER_TEXT_WIDTH_FULL = 0.82 -- without a chip

-- m:ss for the shower countdown chip (TIME_MS past a minute, TIME_S under it).
local function formatCountdown(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.ceil(seconds))
	if total >= 60 then
		return Strings.TIME_MS:format(total // 60, total % 60)
	end
	return Strings.TIME_S:format(total)
end

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

-- Biome chip under the clock chip: which part of the world the player is standing in.
local function buildBiomeChip(root: ScreenGui)
	local chip = Builder.pill({
		parent = root,
		name = "BiomeChip",
		position = UDim2.fromScale(0.985, 0.108),
		size = UDim2.fromScale(0.2, 0.05),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Select,
		stroke = Theme.Stroke.Button,
		aspect = 4.2,
	})
	Builder.gradient(chip, Theme.Colors.Select)
	biomeLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.HUD_BIOME:format(Strings.BIOME_Meadow),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.7),
		anchor = Vector2.new(0.5, 0.5),
	})
end

-- Meteor Shower countdown chip under the biome chip: "Shower in m:ss", purple, hidden until the
-- bootstrap feeds a countdown in (Config.ShowerWarnSeconds before a shower).
local function buildShowerChip(root: ScreenGui)
	local chip = Builder.pill({
		parent = root,
		name = "ShowerChip",
		position = UDim2.fromScale(0.985, 0.165),
		size = UDim2.fromScale(0.2, 0.05),
		anchor = Vector2.new(1, 0),
		color = Theme.Colors.Codex,
		stroke = Theme.Stroke.Button,
		aspect = 4.2,
	})
	Builder.gradient(chip, Theme.Colors.Codex)
	chip.Visible = false
	showerChip = chip
	showerLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.SHOWER_CHIP:format(formatCountdown(0)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.7),
		anchor = Vector2.new(0.5, 0.5),
	})
end

-- Left-edge icon stack: square buttons with a label beneath, as the hit sims lay them out. Until the
-- icon pack is chosen the face shows a placeholder glyph from the strings table.
local function buildMenuButton(root: ScreenGui, id: string, color: Color3, onClick: () -> ()): Frame
	local label = Builder.text("MENU_" .. id)
	local glyph = Builder.text("MENU_GLYPH_" .. id)
	local top = MENU_TOP + menuCount * MENU_SLOT
	menuCount += 1
	local slot = Builder.frame({
		parent = root,
		name = "Menu_" .. id,
		position = UDim2.fromScale(MENU_LEFT, top),
		size = UDim2.fromScale(0.12, MENU_SLOT),
		aspect = 0.8,
	})
	local button = Builder.button({
		parent = slot,
		name = "Button",
		text = if glyph == "MENU_GLYPH_" .. id then string.upper(string.sub(label, 1, 1)) else glyph,
		color = color,
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(1, MENU_BUTTON / MENU_SLOT),
		anchor = Vector2.new(0.5, 0),
		textSize = Theme.TextSize.Title,
		aspect = 1,
	}, onClick)
	Builder.label({
		parent = slot,
		name = "Label",
		text = label,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 1),
		size = UDim2.fromScale(1.3, 1 - MENU_BUTTON / MENU_SLOT),
		anchor = Vector2.new(0.5, 1),
	})
	-- Red notification dot, hidden until SetBadge
	local badge = Builder.frame({
		parent = button,
		name = "Badge",
		position = UDim2.fromScale(0.98, 0.02),
		size = UDim2.fromScale(0.34, 0.34),
		anchor = Vector2.new(0.8, 0.2),
		color = Theme.Colors.Close,
		corner = Theme.Corner.Pill,
		stroke = Theme.Stroke.Text,
		aspect = 1,
		zIndex = 5,
	})
	Builder.label({
		parent = badge,
		name = "Count",
		text = "",
		textSize = Theme.TextSize.Min,
		size = UDim2.fromScale(0.9, 0.9),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 6,
	})
	badge.Visible = false
	menuButtons[id] = button
	return button
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

-- "Luck xN.N" under the ship bar; hidden while luck is exactly 1.
local function buildLuckLine(root: ScreenGui)
	local label = Builder.label({
		parent = root,
		name = "Luck",
		text = Strings.HUD_LUCK:format(("%.1f"):format(1)),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.105),
		size = UDim2.fromScale(0.3, 0.045),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Featured,
	})
	label.Visible = false
	luckLabel = label
end

-- Event banner in the luck line's slot under the ship bar (UI Playbook, "Event banner and compass"):
-- a dark navy pill with the event's icon square on the left, the event text left-aligned, and a green
-- chip on the right for the luck multiplier. Hidden until SetEventBanner; while it shows, the luck
-- line stays hidden (the chip carries the number).
local function buildEventBanner(root: ScreenGui)
	local pill = Builder.pill({
		parent = root,
		name = "EventBanner",
		position = UDim2.fromScale(0.5, 0.105),
		size = UDim2.fromScale(0.36, 0.055),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		aspect = 7,
	})
	Builder.gradient(pill, Theme.Colors.Trough)
	pill.Visible = false
	banner = pill
	-- icon placeholder: a purple rounded square until the event icons exist
	local icon = Builder.frame({
		parent = pill,
		name = "Icon",
		position = UDim2.fromScale(0.025, 0.5),
		size = UDim2.fromScale(0.1, 0.66),
		anchor = Vector2.new(0, 0.5),
		color = Theme.Colors.Codex,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		aspect = 1,
		zIndex = 2,
	})
	Builder.gradient(icon, Theme.Colors.Codex)
	bannerText = Builder.label({
		parent = pill,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(BANNER_TEXT_LEFT, 0.5),
		size = UDim2.fromScale(BANNER_TEXT_WIDTH, 0.7),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 2,
	})
	local chip = Builder.pill({
		parent = pill,
		name = "Chip",
		position = UDim2.fromScale(0.975, 0.5),
		size = UDim2.fromScale(0.25, 0.68),
		anchor = Vector2.new(1, 0.5),
		color = Theme.Colors.Confirm,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 2,
	})
	Builder.gradient(chip, Theme.Colors.Confirm)
	bannerChip = chip
	bannerChipLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
end

-- The luck line shows by its own rule (luck is not exactly 1) unless the event banner has its slot.
local function applyLuckLine()
	local label = luckLabel
	if not label then
		return
	end
	local pill = banner
	label.Visible = luckShown and not (pill ~= nil and pill.Visible)
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
	menuGui = Builder.screen("Menu", MENU_DISPLAY_ORDER)
	buildScrapPill(root)
	buildClockChip(root)
	buildBiomeChip(root)
	buildShowerChip(root)
	buildShipBar(root)
	buildRateLine(root)
	buildLuckLine(root)
	buildEventBanner(root)
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

-- The server's luck multiplier (LuckChanged), one decimal; the line hides while luck is exactly 1,
-- and stays hidden while the event banner holds its slot (the banner's chip carries the number).
function Hud.SetLuck(luck: number)
	local label = luckLabel
	if not label then
		return
	end
	luckShown = luck ~= 1
	if luckShown then
		-- Round half up to one decimal before formatting (1.25 must read x1.3, and %.1f would print 1.2).
		luck = math.floor(luck * 10 + 0.5) / 10
		label.Text = Strings.HUD_LUCK:format(("%.1f"):format(luck))
	end
	applyLuckLine()
end

-- Event banner in the luck line's slot: `text` is the event line (already formatted by the caller,
-- e.g. SHOWER_BANNER with the time left) and `chip` the green chip's text (SHOWER_LUCK formatted),
-- or nil for no chip. nil text hides the banner and gives the luck line its own rule back.
function Hud.SetEventBanner(text: string?, chip: string?)
	local pill, label = banner, bannerText
	if not pill or not label then
		return
	end
	if text then
		label.Text = text
		label.Size = UDim2.fromScale(if chip then BANNER_TEXT_WIDTH else BANNER_TEXT_WIDTH_FULL, 0.7)
		if bannerChip then
			bannerChip.Visible = chip ~= nil
		end
		if bannerChipLabel then
			bannerChipLabel.Text = chip or ""
		end
		if not pill.Visible then
			pill.Visible = true
			Builder.pop(pill, 1.1)
		end
	else
		pill.Visible = false
	end
	applyLuckLine()
end

-- Meteor Shower countdown chip under the biome chip: seconds until the shower, or nil to hide it.
function Hud.SetShowerCountdown(seconds: number?)
	local chip, label = showerChip, showerLabel
	if not chip or not label then
		return
	end
	if seconds then
		label.Text = Strings.SHOWER_CHIP:format(formatCountdown(seconds))
		if not chip.Visible then
			chip.Visible = true
			Builder.pop(chip, 1.1)
		end
	else
		chip.Visible = false
	end
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

-- Adds an entry to the left icon stack. Call after Hud.Build, once per screen, in display order.
function Hud.AddMenuButton(id: string, color: Color3, onClick: () -> ())
	local root = menuGui
	if not root or menuButtons[id] then
		return
	end
	buildMenuButton(root, id, color, onClick)
end

-- The icon stack hides during a capture or a reveal (it sits above those dims) and shows otherwise.
function Hud.SetMenuVisible(visible: boolean)
	if menuGui and menuGui.Enabled ~= visible then
		menuGui.Enabled = visible
	end
end

-- Shows a red dot with a count on a menu button; 0 hides it.
function Hud.SetBadge(id: string, count: number)
	local button = menuButtons[id]
	if not button then
		return
	end
	local badge = button:FindFirstChild("Badge")
	if not badge or not badge:IsA("Frame") then
		return
	end
	badge.Visible = count > 0
	local label = badge:FindFirstChild("Count")
	if label and label:IsA("TextLabel") then
		label.Text = if count > 0 then tostring(count) else ""
	end
	if count > 0 then
		Builder.pop(button, 1.15)
	end
end

function Hud.SetBiome(biome: string)
	if biomeLabel then
		biomeLabel.Text = Strings.HUD_BIOME:format(Builder.text("BIOME_" .. biome))
	end
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
	if menuGui then
		menuGui.Enabled = visible
	end
end

return Hud
