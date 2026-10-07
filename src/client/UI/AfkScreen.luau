--!strict
-- StarterPlayerScripts.Client.UI.AfkScreen: the Resting screen (milestone 46, data/Afk). An overlay, not a Screens panel:
-- a full-screen dim over the world (Afk.OverlayDimTransparency) and a centred cream card with the title "Resting" in
-- the section-heading style, one wrapped line of helper text, the time rested counting up locally from the server's
-- `since` (m:ss, h:mm:ss past an hour), the Scrap earned from the latest push, and a green "Back to play" button.
-- While the player's rejoin is under way (the server accepted AfkRejoin) the button gives way to a navy pill saying
-- "Keeping your spot...". Pure presentation: the server decides who rests and what they earned (AfkChanged), and
-- init.client decides when to show and hide this, what the button does (OnBack) and what the HUD's rate reads.
-- Layer: 35, above the HUD (10), the panels (20) and the reveal (30), below the toasts (40), so the welcome-back toast
-- and any refusal show over it. Hiding is instant (a shrink tween would race a quick re-show). Scale only.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local AfkData = require(Shared:WaitForChild("data"):WaitForChild("Afk"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Prefs = require(script.Parent.Parent.Prefs)

local AfkScreen = {}

local DISPLAY_ORDER = 35
local CARD_W = 0.5 -- the box the card fits inside, as fractions of the screen; the aspect fits it (iPhone SE: about 333 x 238 px)
local CARD_H = 0.7
local CARD_ASPECT = 1.4
local TITLE_Y = 0.05
local TITLE_H = 0.16
local LINE_Y = 0.23
local LINE_H = 0.25
local TIME_Y = 0.5
local TIME_H = 0.1
local EARNED_Y = 0.61
local EARNED_H = 0.09
local TEXT_W = 0.88 -- the card's lines, centred; the 2% margin and more on each side
local BUTTON_BOTTOM = 0.94 -- the button's and the rejoining pill's bottom edge
local BUTTON_W = 0.5
local BUTTON_H = 0.2
local PILL_W = 0.8 -- "Keeping your spot..." is longer than "Back to play"
local TICK_SECONDS = 1 -- the time line is recomputed this often while the screen shows
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600

local gui: ScreenGui? = nil
local card: Frame? = nil
local timeLabel: TextLabel? = nil
local earnedLabel: TextLabel? = nil
local backButton: Frame? = nil
local rejoinPill: Frame? = nil
local onBack: (() -> ())? = nil
local shown = false
local rejoining = false
local since = 0 -- server time (os.time on the server) the rest began
local earned = 0
local tickToken = 0 -- a newer Show makes an older ticker stop

-- m:ss, h:mm:ss past an hour.
local function formatClock(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = total // SECONDS_PER_HOUR
	local minutes = (total % SECONDS_PER_HOUR) // SECONDS_PER_MINUTE
	local secs = total % SECONDS_PER_MINUTE
	if hours > 0 then
		return ("%d:%02d:%02d"):format(hours, minutes, secs)
	end
	return ("%d:%02d"):format(minutes, secs)
end

local function refreshTime()
	local label = timeLabel
	if label then
		label.Text = Strings.AFK_TIME:format(formatClock(Workspace:GetServerTimeNow() - since))
	end
end

local function refreshEarned()
	local label = earnedLabel
	if label then
		label.Text = Strings.AFK_EARNED:format(Builder.formatNumber(earned))
	end
end

local function applyRejoining()
	local button, pill = backButton, rejoinPill
	if button then
		button.Visible = not rejoining
	end
	if pill then
		pill.Visible = rejoining
	end
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("AfkScreen", DISPLAY_ORDER)
	root.Enabled = false
	gui = root

	-- The dim swallows the first tap so it only wakes the screen; any input hides it (init.client listens).
	local dim = Builder.frame({
		parent = root,
		name = "Dim",
		color = Theme.Colors.Black,
		transparency = AfkData.OverlayDimTransparency,
		zIndex = 1,
	})
	dim.Active = true

	local body = Builder.frame({
		parent = root,
		name = "Card",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(CARD_W, CARD_H),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = CARD_ASPECT,
		zIndex = 2,
	})
	card = body

	Builder.label({
		parent = body,
		name = "Title",
		text = Strings.AFK_TITLE,
		textSize = Theme.TextSize.Title,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(0.5, TITLE_Y),
		size = UDim2.fromScale(TEXT_W, TITLE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})

	local line = Builder.label({
		parent = body,
		name = "Line",
		text = Strings.AFK_LINE,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, LINE_Y),
		size = UDim2.fromScale(TEXT_W, LINE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})
	line.TextWrapped = true

	timeLabel = Builder.label({
		parent = body,
		name = "Time",
		text = Strings.AFK_TIME:format(formatClock(0)),
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, TIME_Y),
		size = UDim2.fromScale(TEXT_W, TIME_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})

	earnedLabel = Builder.label({
		parent = body,
		name = "Earned",
		text = Strings.AFK_EARNED:format(Builder.formatNumber(0)),
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, EARNED_Y),
		size = UDim2.fromScale(TEXT_W, EARNED_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})

	backButton = Builder.button({
		parent = body,
		name = "Back",
		text = Strings.AFK_BACK,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.5, BUTTON_BOTTOM),
		size = UDim2.fromScale(BUTTON_W, BUTTON_H),
		anchor = Vector2.new(0.5, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 3,
	}, function()
		local callback = onBack
		if callback then
			callback()
		end
	end)

	local pill = Builder.pill({
		parent = body,
		name = "Rejoining",
		color = Theme.Colors.Trough,
		position = UDim2.fromScale(0.5, BUTTON_BOTTOM),
		size = UDim2.fromScale(PILL_W, BUTTON_H),
		anchor = Vector2.new(0.5, 1),
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 3,
	})
	Builder.label({
		parent = pill,
		name = "Text",
		text = Strings.AFK_REJOINING,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.7),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
	rejoinPill = pill
	applyRejoining()
end

-- Public API -------------------------------------------------------------

function AfkScreen.IsShown(): boolean
	return shown
end

-- What the "Back to play" button does (the bootstrap hides the screen and tells the server).
function AfkScreen.OnBack(callback: (() -> ())?)
	onBack = callback
end

-- Puts the screen up for a rest that began at state.since (server time) with state.earned Scrap so far; a screen that
-- is already up only takes the new numbers.
function AfkScreen.Show(state: Types.AfkState)
	build()
	since = state.since
	earned = state.earned
	refreshTime()
	refreshEarned()
	local root, body = gui, card
	if shown or not root or not body then
		return
	end
	shown = true
	root.Enabled = true
	if not Prefs.ReducedMotion() then
		Builder.open(body)
	end
	tickToken += 1
	local token = tickToken
	task.spawn(function()
		while shown and token == tickToken do
			task.wait(TICK_SECONDS)
			if shown and token == tickToken then
				refreshTime()
			end
		end
	end)
end

-- The newest push's numbers, whether or not the screen is up (a hidden screen is ready for a re-show). Never shows it.
function AfkScreen.Update(state: Types.AfkState)
	since = state.since
	earned = state.earned
	refreshTime()
	refreshEarned()
end

function AfkScreen.Hide()
	if not shown then
		return
	end
	shown = false
	rejoining = false
	tickToken += 1
	applyRejoining()
	local root = gui
	if root then
		root.Enabled = false
	end
end

-- The server accepted the rejoin: the button gives way to "Keeping your spot...".
function AfkScreen.SetRejoining(on: boolean)
	rejoining = on
	build()
	applyRejoining()
end

return AfkScreen
