--!strict
-- StarterPlayerScripts.Client.UI.MailScreen: the home planet's mailbox (milestone 42d), registered with Screens as
-- "Mail" and opened by the "Mail" action beside the mailbox. A centre panel with the usual header tab and close
-- button. Under the header a scrolling list of letters, newest first (data/Mail keeps at most MaxLetters, so that
-- many rows are built once and shown or hidden): each row is a white card with "From <name>" in the Common grey
-- (outlined), the letter's line in navy, the rewards in gold (GiftsScreen.RewardText, the same words as the gift
-- and referral lines), and a green Claim button. Under the list the Visitor Book: a heading and the names of
-- whoever came by, newest first, or a line saying nobody has.
--
-- Every value shown is read from the home mirror in State (home.mail and home.visitors; MailChanged pushes the
-- whole letter list, GetMail seeds both at start) and every Claim asks the server (ClaimMail). The server judges
-- it, pays the rewards and pushes the new list, which this redraws from; the toast names what the letter paid.
-- Nothing here decides an outcome. Unknown means the letter is already gone (a double tap, or another server
-- claimed it), so the list just redraws; any other refusal is only logged.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Mail = require(Shared:WaitForChild("data"):WaitForChild("Mail"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local GiftsScreen = require(script.Parent.GiftsScreen)
local State = require(script.Parent.Parent.State)

local MailScreen = {}

-- One letter's row. Built once and refreshed in place; `uid` is the letter it shows now (nil while hidden).
type Row = { slot: Frame, from: TextLabel, text: TextLabel, rewards: TextLabel, uid: string? }

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close button reaches
-- down to 0.155, so the list starts under it; the Visitor Book takes the bottom. At iPhone SE height the list
-- holds two rows of about 70 px, enough for the "From" line, two lines of the letter's text and the rewards at
-- the minimum text size.
local PANEL_W = 0.8
local PANEL_H = 0.78
local PANEL_ASPECT = 1.6
local LIST_Y = 0.13
local LIST_BOTTOM = 0.68
local BOOK_Y = 0.7
local BOOK_H = 0.26
local BOOK_TITLE_Y = 0.04
local BOOK_TITLE_H = 0.34
local BOOK_NAMES_Y = 0.4
local BOOK_NAMES_H = 0.56
local SCROLLBAR_PX = 6 -- the thin dark bar's thickness; not a Size
-- Rows are sized in visible-list heights: one row plus its gap is PITCH.
local ROWS_VISIBLE = 2
local PITCH = 1 / ROWS_VISIBLE
local ROW_SHARE = 0.9 -- of the pitch; the rest is the gap
local ROW_H = PITCH * ROW_SHARE
local ROW_GAP = PITCH - ROW_H
-- Inside a row, as fractions of the card.
local ROW_PAD_X = 0.025
local TEXT_W = 0.69
local FROM_Y, FROM_H = 0.04, 0.26
local LINE_Y, LINE_H = 0.3, 0.42
local REWARD_Y, REWARD_H = 0.72, 0.25
local CLAIM_X, CLAIM_W = 0.73, 0.25
local CLAIM_Y, CLAIM_H = 0.18, 0.64

local gui: ScreenGui? = nil
local panel: Frame? = nil
local scroller: ScrollingFrame? = nil
local scrollLayout: UIListLayout? = nil
local emptyLabel: TextLabel? = nil
local namesLabel: TextLabel? = nil
local rows: { Row } = {}
local open = false
local pending = false -- one ClaimMail in flight at a time
local canvasPages = 0 -- the list canvas height in visible-list heights, as last applied

-- Helpers ----------------------------------------------------------------

-- The mirror's letter with this uid, or nil when it is gone.
local function findLetter(uid: string): Types.MailItem?
	if not State.Has() then
		return nil
	end
	for _, letter in ipairs(State.Get().home.mail) do
		if letter.uid == uid then
			return letter
		end
	end
	return nil
end

-- Sizes the list canvas to the rows shown and every slot and gap against it (children of a ScrollingFrame scale
-- against the canvas, so each height is divided by the page count; CanvasSize itself scales against the panel,
-- the scroller's parent, so the page count is multiplied by the list's share of it). Only when the count changes.
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
	frame.CanvasSize = UDim2.fromScale(0, pages * (LIST_BOTTOM - LIST_Y))
	layout.Padding = UDim.new(ROW_GAP / pages, 0)
	for _, row in ipairs(rows) do
		row.slot.Size = UDim2.fromScale(1, ROW_H / pages)
	end
end

local function fillRow(row: Row, letter: Types.MailItem)
	row.uid = letter.uid
	row.from.Text = Strings.MAIL_FROM:format(letter.from)
	row.text.Text = letter.text
	row.rewards.Text = Strings.MAIL_REWARD:format(GiftsScreen.RewardText(letter.rewards))
	row.slot.Visible = true
end

-- Refresh ----------------------------------------------------------------

-- Redraws from the mirror: the letters newest first (the mirror keeps them newest last), the empty line, the
-- Visitor Book. Cheap while closed: it returns at once, and Open draws.
local function refresh()
	if not open or not State.Has() then
		return
	end
	local home = State.Get().home
	local mail = home.mail
	local shown = math.min(#mail, #rows)
	for slot, row in ipairs(rows) do
		local letter = if slot <= shown then mail[#mail - slot + 1] else nil
		if letter then
			fillRow(row, letter)
		else
			row.uid = nil
			row.slot.Visible = false
		end
	end
	applyCanvas(shown)
	local empty = emptyLabel
	if empty then
		empty.Visible = shown == 0
	end
	local names = namesLabel
	if names then
		-- One entry per visitor, in the order of their latest visit (newest first), "Player2 x2" for a repeat visit:
		-- the book keeps one record per visit, and a name repeated for each of them read as a mistake.
		local visitors = home.visitors
		local list: { string } = {}
		local counts: { [string]: number } = {}
		local order: { string } = {}
		for index = #visitors, 1, -1 do
			local name = visitors[index].name
			if counts[name] == nil then
				table.insert(order, name)
			end
			counts[name] = (counts[name] or 0) + 1
		end
		for _, name in ipairs(order) do
			local count = counts[name] or 1
			table.insert(list, if count > 1 then Strings.VISITOR_REPEAT:format(name, count) else name)
		end
		names.Text = if #list > 0 then table.concat(list, Strings.UI_LIST_SEPARATOR) else Strings.VISITORS_NONE
	end
end

-- Server calls -------------------------------------------------------------

-- Asks the server to pay the letter `uid`. Runs in its own thread: callers are taps. The rewards are read before
-- the call, because the server's push can remove the letter from the mirror before the answer lands.
local function claim(uid: string)
	if pending then
		return
	end
	local letter = findLetter(uid)
	if not letter then
		refresh()
		return
	end
	local rewardText = GiftsScreen.RewardText(letter.rewards)
	pending = true
	task.spawn(function()
		local ok, reason = Net.func("ClaimMail"):InvokeServer(uid)
		pending = false
		if ok == true then
			Builder.playSound(Sounds.GiftClaim)
			Toast.Show(Strings.TOAST_MAIL_CLAIMED:format(rewardText), Theme.Colors.Confirm)
		elseif reason ~= "Unknown" then
			print(("[%s] ClaimMail refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
		refresh() -- Unknown: the letter is gone already, the redraw drops it
	end)
end

-- Build --------------------------------------------------------------------

-- One row: a white card in a slot (the slot is what the list lays out), its three lines at the left and the
-- Claim button at the right. Navy text with no stroke for the letter's line (helper text on a card); the "From"
-- line and the rewards keep the outline, as grey and gold text needs it on white.
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
	local from = Builder.label({
		parent = card,
		name = "From",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Rarity.Common,
		xAlign = Enum.TextXAlignment.Left,
		position = UDim2.fromScale(ROW_PAD_X, FROM_Y),
		size = UDim2.fromScale(TEXT_W, FROM_H),
		zIndex = 4,
	})
	from.TextTruncate = Enum.TextTruncate.AtEnd
	local line = Builder.label({
		parent = card,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		xAlign = Enum.TextXAlignment.Left,
		position = UDim2.fromScale(ROW_PAD_X, LINE_Y),
		size = UDim2.fromScale(TEXT_W, LINE_H),
		zIndex = 4,
	})
	line.TextWrapped = true
	line.TextTruncate = Enum.TextTruncate.AtEnd
	local rewards = Builder.label({
		parent = card,
		name = "Rewards",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Featured,
		xAlign = Enum.TextXAlignment.Left,
		position = UDim2.fromScale(ROW_PAD_X, REWARD_Y),
		size = UDim2.fromScale(TEXT_W, REWARD_H),
		zIndex = 4,
	})
	rewards.TextTruncate = Enum.TextTruncate.AtEnd
	local row: Row = { slot = slot, from = from, text = line, rewards = rewards, uid = nil }
	Builder.button({
		parent = card,
		name = "Claim",
		text = Strings.MAIL_CLAIM,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(CLAIM_X, CLAIM_Y),
		size = UDim2.fromScale(CLAIM_W, CLAIM_H),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		local uid = row.uid
		if uid ~= nil then
			claim(uid)
		end
	end)
	return row
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("MailScreen", 20)
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
		MailScreen.Close()
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

	-- Header tab straddling the top edge, sky blue, title in white outlined text.
	local header = Builder.frame({
		parent = body,
		name = "Header",
		position = UDim2.fromScale(0.5, 0),
		size = UDim2.fromScale(0.34, 0.11),
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
		text = Strings.MAIL_TITLE,
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
		MailScreen.Close()
	end)

	-- The list: a ScrollingFrame with a thin dark bar; its rows are built once, up to Mail.MaxLetters.
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "Letters"
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
	for index = 1, Mail.MaxLetters do
		table.insert(rows, buildRow(frame, index))
	end

	-- The empty line, over the list's middle (shown only while there are no letters).
	local empty = Builder.label({
		parent = body,
		name = "Empty",
		text = Strings.MAIL_EMPTY,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, (LIST_Y + LIST_BOTTOM) / 2),
		size = UDim2.fromScale(0.8, 0.14),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	empty.Visible = false
	emptyLabel = empty

	-- The Visitor Book: a card under the list with its heading (yellow on black, like the other section
	-- headings) and the names, one wrapped line of navy text.
	local book = Builder.frame({
		parent = body,
		name = "VisitorBook",
		position = UDim2.fromScale(Theme.Margin, BOOK_Y),
		size = UDim2.fromScale(1 - 2 * Theme.Margin, BOOK_H),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	Builder.label({
		parent = book,
		name = "Heading",
		text = Strings.VISITORS_TITLE,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(0.5, BOOK_TITLE_Y),
		size = UDim2.fromScale(1 - 2 * ROW_PAD_X, BOOK_TITLE_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})
	local names = Builder.label({
		parent = book,
		name = "Names",
		text = Strings.VISITORS_NONE,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5, BOOK_NAMES_Y),
		size = UDim2.fromScale(1 - 2 * ROW_PAD_X, BOOK_NAMES_H),
		anchor = Vector2.new(0.5, 0),
		zIndex = 4,
	})
	names.TextWrapped = true
	names.TextTruncate = Enum.TextTruncate.AtEnd
	namesLabel = names

	-- Server pushes: redraw whenever the mail changes (cheap while closed: refresh returns early).
	State.OnChanged("mail", refresh)
end

-- Public API -------------------------------------------------------------

function MailScreen.IsOpen(): boolean
	return open
end

function MailScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	local list = scroller
	if list then
		list.CanvasPosition = Vector2.zero -- opens at the newest letter
	end
	refresh()
	root.Enabled = true
	Builder.open(body)
end

function MailScreen.Close()
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

function MailScreen.Toggle()
	if open then
		MailScreen.Close()
	else
		MailScreen.Open()
	end
end

return MailScreen
