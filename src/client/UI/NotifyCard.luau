--!strict
-- StarterPlayerScripts.Client.UI.NotifyCard: the one-time ask for Experience Notifications (the opt-in that
-- lets Roblox tell the player when a ship part is ready or a rare alien lands). A small centred card with
-- a title, one line of why, and two buttons. The server decides WHEN to ask (the NotifyAsk event: never in
-- the first session, once per cooldown) and stamps the answer (NotifyAskSeen); the platform decides IF it
-- can be asked (ExperienceNotificationService:CanPromptOptInAsync, client-only), and when it cannot nothing
-- is shown and nothing is stamped. The card never opens over a catch, a reveal, a launch or a panel: the
-- caller's canShow is polled every Config.NotifyRetrySeconds, Config.NotifyRetryCount times, then dropped
-- (the server asks again on a later session). Yes stamps "yes" and raises the native prompt; Not now
-- stamps "no". The pop-in is skipped under Reduced Motion.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Prefs = require(script.Parent.Parent.Prefs)

local NotifyCard = {}

local DISPLAY_ORDER = 25 -- over every panel (20), under the reveal (30) and the toasts (40)
local CARD_W = 0.5 -- the box the card fits inside, as fractions of the screen
local CARD_H = 0.6
local CARD_ASPECT = 1.5
local HEADER_Y = 0
local HEADER_W = 0.8
local HEADER_H = 0.2
local BODY_Y = 0.3
local BODY_H = 0.34
local BUTTON_W = 0.42
local BUTTON_H = 0.22
local BUTTON_Y = 0.92 -- bottom edge of both buttons
local BUTTON_YES_X = 0.27
local BUTTON_NO_X = 0.73

local showing = false -- a card is waiting for a clear screen or is up; one at a time
local gui: ScreenGui? = nil
local card: Frame? = nil
local answered = false -- the player has pressed a button; a second press does nothing

-- Takes the card down: at once under Reduced Motion, otherwise the usual shrink.
local function dismiss()
	local root, body = gui, card
	gui = nil
	card = nil
	if not root then
		return
	end
	if body and not Prefs.ReducedMotion() then
		Builder.close(body, function()
			root:Destroy()
		end)
	else
		root:Destroy()
	end
end

-- Stamps the answer with the server, then (Yes) raises the platform's own opt-in prompt. Both calls can
-- fail or yield, so they run in a task behind a pcall; the card is already on its way out.
local function answer(choice: "yes" | "no")
	if answered then
		return
	end
	answered = true
	dismiss()
	task.spawn(function()
		pcall(function()
			return Net.func("NotifyAskSeen"):InvokeServer(choice)
		end)
		if choice == "yes" then
			pcall(function()
				ExperienceNotificationService:PromptOptIn()
			end)
		end
		showing = false
	end)
end

local function build()
	local root = Builder.screen("NotifyCard", DISPLAY_ORDER)
	gui = root

	-- The dim swallows taps behind the card; only the two buttons answer.
	local dim = Builder.frame({
		parent = root,
		name = "Dim",
		color = Theme.Colors.Black,
		transparency = 1 - Theme.Backdrop,
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

	-- Header tab straddling the top edge, gold, title in white outlined text (the same tab as every panel).
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, HEADER_Y),
		size = UDim2.fromScale(HEADER_W, HEADER_H),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(header, Theme.Colors.Featured)
	Builder.label({
		parent = header,
		name = "Title",
		text = Strings.NOTIFY_TITLE,
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	Builder.label({
		parent = body,
		name = "Body",
		text = Strings.NOTIFY_BODY,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, BODY_Y),
		size = UDim2.fromScale(0.88, BODY_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})

	Builder.button({
		parent = body,
		name = "Yes",
		text = Strings.NOTIFY_YES,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(BUTTON_YES_X, BUTTON_Y),
		size = UDim2.fromScale(BUTTON_W, BUTTON_H),
		anchor = Vector2.new(0.5, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 3,
	}, function()
		answer("yes")
	end)
	Builder.button({
		parent = body,
		name = "No",
		text = Strings.NOTIFY_NO,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(BUTTON_NO_X, BUTTON_Y),
		size = UDim2.fromScale(BUTTON_W, BUTTON_H),
		anchor = Vector2.new(0.5, 1),
		textSize = Theme.TextSize.Label,
		zIndex = 3,
	}, function()
		answer("no")
	end)

	if not Prefs.ReducedMotion() then
		Builder.open(body)
	end
end

-- Asks the platform whether the opt-in prompt can be raised at all, waits for a clear screen, then shows
-- the card. `canShow` is the bootstrap's judgement of the screen (no catch, reveal, launch, fly or panel).
-- A platform that cannot prompt, or a call that errors, means no card and no stamp.
function NotifyCard.Show(canShow: () -> boolean)
	if showing then
		return
	end
	showing = true
	task.spawn(function()
		local asked, canPrompt = pcall(function()
			return ExperienceNotificationService:CanPromptOptInAsync()
		end)
		if not asked or canPrompt ~= true then
			showing = false
			return
		end
		for attempt = 0, Config.NotifyRetryCount do
			if canShow() then
				answered = false
				build()
				return -- showing stays true until the player answers
			end
			if attempt < Config.NotifyRetryCount then
				task.wait(Config.NotifyRetrySeconds)
			end
		end
		showing = false
	end)
end

return NotifyCard
