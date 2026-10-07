--!strict
-- StarterPlayerScripts.Client.UI.PlaytimeScreen: the playtime gifts (milestone 49), registered with Screens as "Playtime" and
-- opened by the HUD's Playtime button. A centre panel with the usual header tab and close button: one card per
-- data/Playtime gift, side by side in a row (the panel is wide, so six cards fit at iPhone SE size and on an iPad), each
-- showing the minutes it needs, the reward (its icon once the pack is uploaded, its name and amount in the same words the
-- Gifts screen uses) and its state: a green Claim button once unlocked, a Claimed chip once taken, and until then the time
-- left as m:ss, counted down locally once a second from the last state while the screen is open. A line under the cards
-- says the gifts reset each day.
--
-- Every value shown is read from the server's last PlaytimeState (PlaytimeChanged pushes it when a gift unlocks or is
-- claimed, GetPlaytime pulls it at start and each time the screen opens) and the data table: a card is unlocked or not by
-- Shared/PlaytimeMath on the server's seconds, never on the local clock, which only draws the countdown (it shows at least
-- 0:01 until the server's next push says the gift is open). Every Claim asks the server (ClaimPlaytimeGift); a refusal is
-- a toast and an egg comes back as a GrantResult the bootstrap turns into a Reveal. Nothing here decides an outcome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local PlaytimeData = require(Shared:WaitForChild("data"):WaitForChild("Playtime"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local PlaytimeMath = require(Shared:WaitForChild("PlaytimeMath"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local GiftsScreen = require(script.Parent.GiftsScreen)

local PlaytimeScreen = {}

local gifts: { PlaytimeData.Gift } = PlaytimeData.Gifts

-- One gift card. Built once and refreshed in place.
type Card = {
	card: Frame,
	chip: Frame,
	claim: Frame,
	claimed: Frame,
	locked: Frame,
	left: TextLabel,
}

-- Panel layout, as fractions of the panel. The panel is wide (PANEL_ASPECT) so the row of cards reads on a phone: about
-- 88 x 175 px a card at iPhone SE size. The header tab straddles the top edge and the close button reaches down to
-- 0.155, so the cards start under it.
local PANEL_W = 0.92
local PANEL_H = 0.78
local PANEL_ASPECT = 2
local CARDS_Y = 0.19
local CARDS_H = 0.6
local CARD_GAP = 0.012 -- between two cards, of the panel width
local HINT_Y = 0.83
local HINT_H = 0.11
-- Inside a card, as fractions of the card.
local CHIP_Y, CHIP_W, CHIP_H = 0.05, 0.84, 0.13
local ICON_Y, ICON_W, ICON_H = 0.21, 0.7, 0.27
local NAME_Y, NAME_H = 0.2, 0.52 -- the reward name without an icon above it
local NAME_ICON_Y, NAME_ICON_H = 0.5, 0.24 -- and with one
local NAME_W = 0.92
local STATE_W, STATE_H = 0.86, 0.2 -- the Claim button, the Claimed chip and the time-left pill share this slot
local STATE_BOTTOM = 0.95
local CLOCK_STEP = 1 -- seconds between two redraws of the countdowns while the screen is open

local gui: ScreenGui? = nil
local panel: Frame? = nil
local cards: { Card } = {}
local open = false
local pending = false -- one claim in flight at a time
local clockToken = 0 -- bumped on every open, so a countdown thread from an earlier open stops
local state: Types.PlaytimeState = { enabled = false, seconds = 0, claimed = {} } -- the server's last word
local stateAt = os.clock() -- when it arrived, so the countdown runs from there
local stateSeq = 0 -- bumped by every state, so a pull that started before a push is dropped
local claimedLocal: { [string]: boolean } = {} -- gifts the server confirmed, until the next state
local onGrant: ((Types.GrantResult) -> ())? = nil
local onState: ((Types.PlaytimeState) -> ())? = nil

-- Helpers ----------------------------------------------------------------

-- Recolours a pill chip in place (fill and gradient).
local function recolorChip(chip: Frame, color: Color3)
	chip.BackgroundColor3 = color
	local gradient = chip:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Builder.lighter(color), color)
	end
end

-- The reward in words: an egg by its tier, everything else through the Gifts screen's reward lines ("150 Scrap",
-- "1 x Twig Lure", "1 free spin").
local function rewardText(reward: PlaytimeData.Reward): string
	if reward.kind == "egg" then
		return Strings.PLAYTIME_EGG:format(Builder.text("TIER_" .. (reward.tier or "Common")))
	end
	return GiftsScreen.RewardText({ reward } :: any)
end

-- The icon key for a reward: Scrap, a lure or power-up by its id, an egg by its tier's rarity badge; a spin has none.
local function rewardIconKey(reward: PlaytimeData.Reward): string?
	if reward.kind == "scrap" then
		return "Scrap"
	elseif reward.kind == "lure" or reward.kind == "powerUp" then
		return reward.id
	elseif reward.kind == "egg" then
		return reward.tier
	end
	return nil
end

-- The card's accent: an egg takes its tier colour (the hour's Rare egg reads Rare), the rest gold.
local function accentOf(reward: PlaytimeData.Reward): Color3
	if reward.kind == "egg" then
		return Builder.tierColor(reward.tier or "Common")
	end
	return Theme.Colors.Featured
end

-- Seconds played today as far as this client can tell: the server's count plus the time since it arrived.
local function secondsNow(): number
	return state.seconds + (os.clock() - stateAt)
end

-- m:ss of the time a locked gift still needs, never below 0:01 (the server opens it on its next push).
local function timeLeftText(index: number): string
	local needed = PlaytimeMath.SecondsNeeded(index) or 0
	local left = math.max(1, math.ceil(needed - secondsNow()))
	return Strings.PLAYTIME_TIME_LEFT:format(math.floor(left / 60), left % 60)
end

-- Refresh ----------------------------------------------------------------------

local function refreshCard(entry: Card, index: number)
	local gift = gifts[index]
	if not gift then
		return
	end
	local key = PlaytimeMath.Key(index)
	local isClaimed = state.claimed[key] == true or claimedLocal[key] == true
	local unlocked = PlaytimeMath.IsUnlocked(state.seconds, index)
	local accent = accentOf(gift.reward)
	entry.claim.Visible = unlocked and not isClaimed
	entry.claimed.Visible = isClaimed
	entry.locked.Visible = not unlocked and not isClaimed
	entry.left.Text = timeLeftText(index)
	local dimmed = Builder.lighter(Theme.Rarity.Common, 0.6)
	local stroke = entry.card:FindFirstChildOfClass("UIStroke")
	if unlocked and not isClaimed then
		entry.card.BackgroundColor3 = Theme.Colors.White
		recolorChip(entry.chip, accent)
		if stroke then
			stroke.Color = accent
		end
	else
		-- Claimed or locked: grey, except a locked egg keeps its tier colour so the hour's prize stays in view.
		entry.card.BackgroundColor3 = dimmed
		local edge = if not unlocked and gift.reward.kind == "egg" then accent else Theme.Rarity.Common
		recolorChip(entry.chip, edge)
		if stroke then
			stroke.Color = edge
		end
	end
end

local function refresh()
	if not open then
		return
	end
	for index, entry in ipairs(cards) do
		refreshCard(entry, index)
	end
end

-- Only the countdown lines: runs every CLOCK_STEP while the screen is open.
local function refreshTimes()
	for index, entry in ipairs(cards) do
		if entry.locked.Visible then
			entry.left.Text = timeLeftText(index)
		end
	end
end

-- Server calls -------------------------------------------------------------

local function refusalToast(reason: any)
	if reason == "Locked" then
		Toast.Show(Strings.PLAYTIME_TOAST_LOCKED, Theme.Rarity.Common)
	elseif reason == "AlreadyClaimed" then
		Toast.Show(Strings.PLAYTIME_TOAST_ALREADY, Theme.Rarity.Common)
	elseif reason == "Disabled" then
		Toast.Show(Strings.PLAYTIME_TOAST_OFF, Theme.Rarity.Common)
	else
		Toast.Show(Strings.PLAYTIME_TOAST_ERROR, Theme.Colors.Close)
		print(("[%s] ClaimPlaytimeGift refused: %s"):format(Config.WorkingTitle, tostring(reason)))
	end
end

-- Asks the server for gift `index`. Runs in its own thread: callers are taps. The server pushes PlaytimeChanged (and Scrap
-- or inventory) itself; this toasts the answer and hands an egg's GrantResult on.
local function claim(index: number)
	local gift = gifts[index]
	if pending or not gift then
		return
	end
	pending = true
	task.spawn(function()
		local called, ok, reason, raw = pcall(function(): (any, any, any)
			return Net.func("ClaimPlaytimeGift"):InvokeServer(index)
		end)
		pending = false
		if called and ok == true then
			claimedLocal[PlaytimeMath.Key(index)] = true
			Builder.playSound(Sounds.GiftClaim)
			local grant = raw :: Types.GrantResult?
			if not grant then
				Toast.Show(Strings.PLAYTIME_TOAST_CLAIMED:format(rewardText(gift.reward)), accentOf(gift.reward)) -- an egg's Reveal says it instead
			end
			refresh()
			local callback = onGrant
			if grant and callback then
				callback(grant)
			end
		else
			refusalToast(if called then reason else "Error")
			refresh()
		end
	end)
end

-- Cards ---------------------------------------------------------------------

-- A white card in its slot of the row: the minutes chip on top, the reward (icon, then name), and along the bottom the
-- Claim button, the Claimed chip or the time-left pill (one visible at a time).
local function buildCard(parent: Frame, index: number, gift: PlaytimeData.Gift, x: number, width: number): Card
	local accent = accentOf(gift.reward)
	local card = Builder.frame({
		parent = parent,
		name = "Gift" .. index,
		position = UDim2.fromScale(x, CARDS_Y),
		size = UDim2.fromScale(width, CARDS_H),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = accent,
		zIndex = 3,
	})

	local chip = Builder.pill({
		parent = card,
		name = "MinutesChip",
		position = UDim2.fromScale(0.5, CHIP_Y),
		size = UDim2.fromScale(CHIP_W, CHIP_H),
		anchor = Vector2.new(0.5, 0),
		color = accent,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	Builder.gradient(chip, accent)
	Builder.label({
		parent = chip,
		name = "Text",
		text = Strings.PLAYTIME_MINUTES:format(gift.minutes),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})

	-- The reward's icon (absent while its image is not uploaded: the name then takes its room).
	local iconKey = rewardIconKey(gift.reward)
	local icon: ImageLabel? = nil
	if iconKey then
		icon = Builder.icon({
			parent = card,
			name = "RewardIcon",
			key = iconKey,
			position = UDim2.fromScale(0.5, ICON_Y),
			size = UDim2.fromScale(ICON_W, ICON_H),
			anchor = Vector2.new(0.5, 0),
			zIndex = 4,
		})
	end
	local name = Builder.label({
		parent = card,
		name = "Reward",
		text = rewardText(gift.reward),
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, if icon then NAME_ICON_Y else NAME_Y),
		size = UDim2.fromScale(NAME_W, if icon then NAME_ICON_H else NAME_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})
	name.TextWrapped = true

	local claimButton = Builder.button({
		parent = card,
		name = "Claim",
		text = Strings.GIFTS_CLAIM,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(0.5, STATE_BOTTOM),
		size = UDim2.fromScale(STATE_W, STATE_H),
		anchor = Vector2.new(0.5, 1),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		claim(index)
	end)

	local claimed = Builder.pill({
		parent = card,
		name = "Claimed",
		position = UDim2.fromScale(0.5, STATE_BOTTOM),
		size = UDim2.fromScale(STATE_W, STATE_H * 0.9),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.Confirm,
		stroke = Theme.Stroke.Button,
		strokeColor = Builder.darker(Theme.Colors.Confirm),
		zIndex = 4,
	})
	Builder.gradient(claimed, Theme.Colors.Confirm)
	Builder.label({
		parent = claimed,
		name = "Text",
		text = Strings.GIFTS_CLAIMED,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	claimed.Visible = false

	-- The time left, in white on a navy pill so it reads on the grey card.
	local locked = Builder.pill({
		parent = card,
		name = "Locked",
		position = UDim2.fromScale(0.5, STATE_BOTTOM),
		size = UDim2.fromScale(STATE_W, STATE_H * 0.9),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.Trough,
		zIndex = 4,
	})
	local left = Builder.label({
		parent = locked,
		name = "Left",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.9, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 5,
	})
	locked.Visible = false

	return { card = card, chip = chip, claim = claimButton, claimed = claimed, locked = locked, left = left }
end

-- Build ----------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("PlaytimeScreen", 20)
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
		PlaytimeScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(PANEL_W, PANEL_H),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = PANEL_ASPECT,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, gold, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.3, 0.12),
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
		text = Strings.PLAYTIME_TITLE,
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
		position = UDim2.fromScale(0.99, 0.02),
		size = UDim2.fromScale(0.07, 0.14),
		anchor = Vector2.new(1, 0),
		textSize = Theme.TextSize.Label,
		aspect = 1,
		zIndex = 4,
	}, function()
		PlaytimeScreen.Close()
	end)

	-- The row of cards, side by side inside the 2% margin.
	local count = #gifts
	local width = (1 - 2 * Theme.Margin - (count - 1) * CARD_GAP) / count
	cards = {}
	for index, gift in ipairs(gifts) do
		local x = Theme.Margin + (index - 1) * (width + CARD_GAP)
		table.insert(cards, buildCard(body, index, gift, x, width))
	end

	Builder.label({
		parent = body,
		name = "Hint",
		text = Strings.PLAYTIME_HINT,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, HINT_Y),
		size = UDim2.fromScale(1 - 2 * Theme.Margin, HINT_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})
end

-- State ----------------------------------------------------------------------

local function apply(newState: Types.PlaytimeState)
	stateSeq += 1
	state = newState
	stateAt = os.clock()
	claimedLocal = {} -- the state is the truth again
	refresh()
	local callback = onState
	if callback then
		callback(newState)
	end
end

-- The bootstrap's hook for PlaytimeChanged: the server's new state, drawn at once if the screen is up.
function PlaytimeScreen.SetState(newState: Types.PlaytimeState)
	apply(newState)
end

-- Asks the server for today's state (the answer is dropped when a push landed meanwhile: it is newer). Yields: callers run
-- it in a task. Called at start by the bootstrap and each time the screen opens.
function PlaytimeScreen.Pull()
	local seq = stateSeq
	local ok, answer = pcall(function(): any
		return Net.func("GetPlaytime"):InvokeServer()
	end)
	if not ok or type(answer) ~= "table" or seq ~= stateSeq then
		return
	end
	local reply = answer :: Types.PlaytimeState
	if type(reply.enabled) ~= "boolean" or type(reply.seconds) ~= "number" or type(reply.claimed) ~= "table" then
		return
	end
	apply(reply)
end

-- The gifts unlocked and not yet claimed, by the server's last state (the HUD badge).
function PlaytimeScreen.ReadyCount(): number
	return PlaytimeMath.ReadyCount(state.seconds, state.claimed)
end

-- Whether the server says the gifts are on (false until its first answer).
function PlaytimeScreen.IsEnabled(): boolean
	return state.enabled
end

-- The bootstrap's hook for every new state (a push or a pull): it keeps the HUD button and its badge in step.
function PlaytimeScreen.OnState(callback: (Types.PlaytimeState) -> ())
	onState = callback
end

-- The bootstrap's hook for an egg: the server's GrantResult for a hatched alien, to show as a Reveal.
function PlaytimeScreen.OnGrant(callback: (Types.GrantResult) -> ())
	onGrant = callback
end

-- Public API -------------------------------------------------------------

function PlaytimeScreen.IsOpen(): boolean
	return open
end

function PlaytimeScreen.Open()
	if not state.enabled then
		return
	end
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	refresh()
	root.Enabled = true
	Builder.open(body)
	-- The countdowns tick once a second until this open ends.
	clockToken += 1
	local token = clockToken
	task.spawn(function()
		while open and token == clockToken do
			task.wait(CLOCK_STEP)
			if open and token == clockToken then
				refreshTimes()
			end
		end
	end)
	task.spawn(PlaytimeScreen.Pull)
end

function PlaytimeScreen.Close()
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

function PlaytimeScreen.Toggle()
	if open then
		PlaytimeScreen.Close()
	else
		PlaytimeScreen.Open()
	end
end

return PlaytimeScreen
