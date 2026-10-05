--!strict
-- StarterPlayerScripts.Client.UI.LeaderboardScreen: the Ranks panel, the weekly "Catches this week"
-- board. A gold header, a countdown to the weekly reset, a small note when the server is in Studio
-- memory mode (this server only), a scrolling list of up to Leaderboard.TopCount rows (rank and name on
-- the left, the count right-aligned, the local player's row in the Featured colour) and a pinned row
-- at the bottom with the player's own count and rank. Everything shown is what the server said last:
-- GetLeaderboard on open (once) and LeaderboardChanged pushes while open. Nothing here decides a rank.
-- The rows are built once and reused; the list's canvas is sized in Scale from the number of rows.
-- While open two things run: a countdown thread that redraws the reset line once a minute, and the
-- row stagger (tweens with a delay). Close cancels the thread and the tweens and puts the rows back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local LeaderboardMath = require(Shared:WaitForChild("LeaderboardMath"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Leaderboard = require(Shared:WaitForChild("data"):WaitForChild("Leaderboard"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Prefs = require(script.Parent.Parent.Prefs)

local LeaderboardScreen = {}

-- The server's answer to GetLeaderboard and the body of the LeaderboardChanged push. `local` true means
-- Studio memory mode: this server only. `own` holds the present players' counts keyed by user id string.
export type Entry = { userId: number, name: string, count: number }
export type Payload = {
	periodId: string,
	resetsAt: number,
	["local"]: boolean,
	rows: { Entry },
	own: { [string]: number },
}

-- One list row: a transparent slot the layout places, the card inside it (the stagger slides the card, so
-- the layout never fights the tween), the card's outline and its two labels.
type Row = { slot: Frame, card: Frame, stroke: UIStroke, name: TextLabel, count: TextLabel }

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close button
-- reaches down to 0.155, so the info lines sit between the two and the list starts under the lower one.
local HEADER_W = 0.62 -- wide enough for the title at the minimum text size on a phone
local HEADER_H = 0.12
local COUNTDOWN_Y = 0.075
local COUNTDOWN_H = 0.065
local COUNTDOWN_W = 0.68 -- stays clear of the close button on the right
local NOTE_Y = 0.14
local NOTE_H = 0.055
local LIST_Y = 0.15 -- the list's top without the Studio note
local LIST_Y_NOTE = 0.2 -- and with it
local LIST_BOTTOM = 0.875
local YOU_Y = 0.89
local YOU_H = 0.085
local SCROLLBAR_PX = 6

-- Rows are sized in visible-list heights: one row plus its gap is PITCH, so ROWS_VISIBLE of them fill the
-- list with half a row peeking to say it scrolls. On an iPhone SE that is more than ten full rows.
local ROWS_VISIBLE = 10.5
local PITCH = 1 / ROWS_VISIBLE
local ROW_SHARE = 0.9 -- of the pitch; the rest is the gap
local ROW_H = PITCH * ROW_SHARE
local ROW_GAP = PITCH - ROW_H
local ROW_PAD_X = 0.03 -- of a row, on both sides
local NAME_W = 0.66
local COUNT_W = 0.25

-- Time units, in seconds. The countdown shows days and hours, hours and minutes, or minutes, so it
-- changes at most once a minute and the open screen redraws it that often.
local MINUTE = 60
local HOUR = 60 * MINUTE
local DAY = 24 * HOUR

-- The day and minute-only countdown shapes have no key in strings/en yet (TIME_HM is the hours shape).

-- The row stagger on open: the first rows slide in from the right, one after another.
local STAGGER_FROM_X = 1

local gui: ScreenGui? = nil
local panel: Frame? = nil
local scroller: ScrollingFrame? = nil
local scrollLayout: UIListLayout? = nil
local countdownLabel: TextLabel? = nil
local noteLabel: TextLabel? = nil
local emptyLabel: TextLabel? = nil
local youCard: Frame? = nil
local youLabel: TextLabel? = nil
local rows: { Row } = {}
local open = false
local payload: Payload? = nil -- the server's last word; kept while closed so the next open has something to draw
local fetching = false -- one GetLeaderboard in flight at a time
local canvasPages = 0 -- the list canvas height in visible-list heights, as last applied
local tickThread: thread? = nil
local staggerTweens: { Tween } = {}
local staggered = 0 -- rows the current stagger moved
local staggerPending = false -- set on open; the first draw that has rows consumes it

-- Helpers ----------------------------------------------------------------

-- "Nd Nh" from a day up, "Nh Nm" from an hour up, "Nm" under it (minutes round up so the last minute reads 1m).
local function timeLeftText(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.floor(seconds))
	if total >= DAY then
		return Strings.TIME_DH:format(total // DAY, (total % DAY) // HOUR)
	elseif total >= HOUR then
		return Strings.TIME_HM:format(total // HOUR, (total % HOUR) // MINUTE)
	end
	return Strings.TIME_M:format(math.ceil(total / MINUTE))
end

-- Keeps what the screen draws from; drops anything that is not the shape the server documents.
local function sanitize(raw: any): Payload?
	if type(raw) ~= "table" then
		return nil
	end
	local rawRows: any = raw.rows
	if type(rawRows) ~= "table" then
		return nil
	end
	local cleanRows: { Entry } = {}
	for _, item: any in ipairs(rawRows) do
		if #cleanRows >= Leaderboard.TopCount then
			break
		end
		if type(item) == "table" and type(item.userId) == "number" and type(item.count) == "number" then
			table.insert(cleanRows, {
				userId = item.userId,
				name = if type(item.name) == "string" then item.name else "",
				count = math.max(0, math.floor(item.count)),
			})
		end
	end
	local cleanOwn: { [string]: number } = {}
	local rawOwn: any = raw.own
	if type(rawOwn) == "table" then
		for key: any, value: any in pairs(rawOwn) do
			if type(key) == "string" and type(value) == "number" then
				cleanOwn[key] = math.max(0, math.floor(value))
			end
		end
	end
	local resetsAt: any = raw.resetsAt
	local periodId: any = raw.periodId
	return {
		periodId = if type(periodId) == "string" then periodId else "",
		resetsAt = if type(resetsAt) == "number" then resetsAt else 0,
		["local"] = raw["local"] == true,
		rows = cleanRows,
		own = cleanOwn,
	}
end

-- Draw -------------------------------------------------------------------

-- The reset line: the payload's reset instant while it is still ahead, else the next one the shared
-- math names (a payload from before a reset, or none yet).
local function refreshCountdown()
	local label = countdownLabel
	if not label then
		return
	end
	local now = os.time()
	local target = LeaderboardMath.NextReset(now)
	local current = payload
	if current and current.resetsAt > now then
		target = current.resetsAt
	end
	label.Text = Strings.LB_RESETS:format(timeLeftText(target - now))
end

-- Sizes the list canvas to the rows shown and every slot and gap against it (children of a ScrollingFrame
-- scale against the canvas, so each height is divided by the page count). Only when the count changes.
local function applyCanvas(shown: number)
	local frame, layout = scroller, scrollLayout
	if not frame or not layout then
		return
	end
	local pages = math.max(1, shown * PITCH)
	if pages == canvasPages then
		return
	end
	canvasPages = pages
	frame.CanvasSize = UDim2.fromScale(0, pages)
	layout.Padding = UDim.new(ROW_GAP / pages, 0)
	for _, row in ipairs(rows) do
		row.slot.Size = UDim2.fromScale(1, ROW_H / pages)
	end
end

local function stopStagger()
	for _, tween in ipairs(staggerTweens) do
		tween:Cancel()
	end
	table.clear(staggerTweens)
	for index = 1, staggered do
		local row = rows[index]
		if row then
			row.card.Position = UDim2.fromScale(0, 0)
		end
	end
	staggered = 0
end

-- The first rows start off to the right and slide in, each a little after the one above. Delayed tweens, so
-- there is no thread to stop; Reduced Motion skips it and the rows are simply there.
local function startStagger(shown: number)
	stopStagger()
	if Prefs.ReducedMotion() then
		return
	end
	local count = math.min(shown, Theme.Tween.StaggerRows, #rows)
	for index = 1, count do
		local card = rows[index].card
		card.Position = UDim2.fromScale(STAGGER_FROM_X, 0)
		local info = TweenInfo.new(
			Theme.Tween.Open,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			0,
			false,
			(index - 1) * Theme.Tween.StaggerStep
		)
		local tween = TweenService:Create(card, info, { Position = UDim2.fromScale(0, 0) })
		table.insert(staggerTweens, tween)
		tween:Play()
	end
	staggered = count
end

-- Redraws everything from the payload (or from nothing, before the first answer arrives). Cheap: at most
-- Leaderboard.TopCount rows, text and colours set in place.
local function draw()
	if not open then
		return
	end
	local current = payload
	local list: { Entry } = if current then current.rows else {}
	local shown = math.min(#list, #rows)
	local userId = Players.LocalPlayer.UserId
	local ownRank: number? = nil
	for index = 1, shown do
		local row, entry = rows[index], list[index]
		local mine = entry.userId == userId
		if mine then
			ownRank = index
		end
		row.slot.Visible = true
		local name = if entry.name ~= "" then entry.name else tostring(entry.userId)
		row.name.Text = Strings.LB_ROW:format(index, name)
		row.count.Text = Strings.LB_COUNT:format(entry.count)
		row.card.BackgroundColor3 = if mine then Theme.Colors.Featured else Theme.Colors.White
		row.stroke.Color = if mine then Theme.Colors.Outline else Theme.Rarity.Common
	end
	for index = shown + 1, #rows do
		rows[index].slot.Visible = false
	end
	applyCanvas(shown)

	local isLocal = current ~= nil and current["local"]
	local frame = scroller
	if frame then
		local top = if isLocal then LIST_Y_NOTE else LIST_Y
		frame.Position = UDim2.fromScale(Theme.Margin, top)
		frame.Size = UDim2.fromScale(1 - 2 * Theme.Margin, LIST_BOTTOM - top)
	end
	if noteLabel then
		noteLabel.Visible = isLocal
	end
	if emptyLabel then
		emptyLabel.Visible = current ~= nil and #list == 0
	end

	-- The pinned row: the server's count for the player (own), else the row's, else 0; the rank is the row
	-- index when the player is in the top list.
	local card, label = youCard, youLabel
	if card and label then
		card.Visible = current ~= nil
		if current then
			local count = current.own[tostring(userId)]
			if count == nil then
				count = if ownRank then list[ownRank].count else 0
			end
			local rank = if ownRank then tostring(ownRank) else Strings.LB_RANK_OUT
			label.Text = Strings.LB_YOU:format(count, rank)
		end
	end
	refreshCountdown()

	if staggerPending and shown > 0 then
		staggerPending = false
		startStagger(shown)
	end
end

-- The tick -----------------------------------------------------------------

local function stopTick()
	local thread = tickThread
	tickThread = nil
	if thread and coroutine.status(thread) ~= "dead" then
		task.cancel(thread)
	end
end

-- Server calls -------------------------------------------------------------

local function apply(clean: Payload)
	payload = clean
	draw()
end

-- Asks the server for the board and redraws. One in flight; a failure leaves what is shown as it was.
local function fetch()
	if fetching then
		return
	end
	fetching = true
	task.spawn(function()
		local ok, raw: any = pcall(function()
			return Net.func("GetLeaderboard"):InvokeServer()
		end)
		fetching = false
		if not ok then
			print(("[%s] GetLeaderboard failed: %s"):format(Config.WorkingTitle, tostring(raw)))
			return
		end
		local clean = sanitize(raw)
		if clean then
			apply(clean)
		end
	end)
end

-- Redraws the reset line once a minute while open; once the reset instant has passed it asks for the
-- new week's board (still one request at a time). task.cancel'ed in Close.
local function startTick()
	stopTick()
	tickThread = task.spawn(function()
		while open do
			task.wait(MINUTE)
			if not open then
				break
			end
			refreshCountdown()
			local current = payload
			if current and current.resetsAt <= os.time() then
				fetch()
			end
		end
	end)
end

-- Build --------------------------------------------------------------------

local function buildRow(parent: ScrollingFrame, index: number): Row
	local slot = Builder.frame({
		parent = parent,
		name = "Row" .. index,
		size = UDim2.fromScale(1, ROW_H),
		zIndex = 3,
	})
	slot.LayoutOrder = index
	slot.Visible = false
	local card = Builder.frame({
		parent = slot,
		name = "Card",
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	local stroke = card:FindFirstChildOfClass("UIStroke") or Builder.stroke(card, Theme.Stroke.Text, Theme.Rarity.Common)
	-- Navy text, no stroke: the rows are small and sit on a card, not over the world.
	local name = Builder.label({
		parent = card,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(ROW_PAD_X, 0.5),
		size = UDim2.fromScale(NAME_W, 1),
		anchor = Vector2.new(0, 0.5),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	name.TextTruncate = Enum.TextTruncate.AtEnd
	local count = Builder.label({
		parent = card,
		name = "Count",
		text = "",
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(1 - ROW_PAD_X, 0.5),
		size = UDim2.fromScale(COUNT_W, 1),
		anchor = Vector2.new(1, 0.5),
		xAlign = Enum.TextXAlignment.Right,
		zIndex = 4,
	})
	return { slot = slot, card = card, stroke = stroke, name = name, count = count }
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("LeaderboardScreen", 20)
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
		LeaderboardScreen.Close()
	end)

	local body = Builder.frame({
		parent = root,
		name = "Panel",
		position = UDim2.fromScale(0.5, 0.55), -- below the HUD's top row; the header tab straddles the top edge
		size = UDim2.fromScale(0.62, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Panel,
		corner = Theme.Corner.Panel,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		aspect = 1.15,
		zIndex = 2,
	})
	panel = body

	-- Header tab straddling the top edge, gold like the Ranks button, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
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
		text = Strings.LB_TITLE,
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.94, 0.8),
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
		LeaderboardScreen.Close()
	end)

	-- Info lines: the reset countdown, and the Studio note (shown only in memory mode).
	countdownLabel = Builder.label({
		parent = body,
		name = "Countdown",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, COUNTDOWN_Y),
		size = UDim2.fromScale(COUNTDOWN_W, COUNTDOWN_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})
	local note = Builder.label({
		parent = body,
		name = "LocalNote",
		text = Strings.LB_LOCAL_ONLY,
		textSize = Theme.TextSize.Min,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, NOTE_Y),
		size = UDim2.fromScale(COUNTDOWN_W, NOTE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 3,
	})
	note.Visible = false
	noteLabel = note

	-- The list: a ScrollingFrame with a thin dark bar; its rows are built once, up to TopCount.
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "Rows"
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(Theme.Margin, LIST_Y)
	frame.Size = UDim2.fromScale(1 - 2 * Theme.Margin, LIST_BOTTOM - LIST_Y)
	frame.ZIndex = 3
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	frame.CanvasSize = UDim2.fromScale(0, 1)
	frame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	frame.ScrollBarThickness = SCROLLBAR_PX
	frame.ScrollBarImageColor3 = Theme.Colors.Trough
	frame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	frame.Parent = body
	scroller = frame
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(ROW_GAP, 0)
	layout.Parent = frame
	scrollLayout = layout
	rows = {}
	for index = 1, Leaderboard.TopCount do
		table.insert(rows, buildRow(frame, index))
	end

	-- The empty line, over the list's middle (shown only when the server sent no rows).
	local empty = Builder.label({
		parent = body,
		name = "Empty",
		text = Strings.LB_EMPTY,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, 0.45),
		size = UDim2.fromScale(0.8, 0.2),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	empty.Visible = false
	emptyLabel = empty

	-- The pinned row: the player's own count and rank, gold like their row in the list.
	local you = Builder.frame({
		parent = body,
		name = "You",
		position = UDim2.fromScale(Theme.Margin, YOU_Y),
		size = UDim2.fromScale(1 - 2 * Theme.Margin, YOU_H),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 3,
	})
	Builder.gradient(you, Theme.Colors.Featured)
	you.Visible = false
	youCard = you
	youLabel = Builder.label({
		parent = you,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.96, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 4,
	})
end

-- Public API -------------------------------------------------------------

function LeaderboardScreen.IsOpen(): boolean
	return open
end

-- Takes the server's board (GetLeaderboard's answer or a LeaderboardChanged push). Kept while closed;
-- drawn when open.
function LeaderboardScreen.SetPayload(raw: Payload)
	local clean = sanitize(raw)
	if clean then
		apply(clean)
	end
end

function LeaderboardScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	staggerPending = true
	local frame = scroller
	if frame then
		frame.CanvasPosition = Vector2.zero
	end
	draw()
	startTick()
	root.Enabled = true
	Builder.open(body)
	fetch()
end

-- Stops the countdown thread and the stagger tweens before the close tween runs, so nothing keeps
-- redrawing or moving behind a hidden screen.
function LeaderboardScreen.Close()
	if not open then
		return
	end
	open = false
	staggerPending = false
	stopTick()
	stopStagger()
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

function LeaderboardScreen.Toggle()
	if open then
		LeaderboardScreen.Close()
	else
		LeaderboardScreen.Open()
	end
end

return LeaderboardScreen
