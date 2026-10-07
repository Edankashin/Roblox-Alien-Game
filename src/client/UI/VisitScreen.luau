--!strict
-- StarterPlayerScripts.Client.UI.VisitScreen: "Visit a friend" (milestone 42e), registered with Screens as "Visit" and
-- opened by the Visit button on the Star Chart's Home card. A centre panel like the Mailbox: the blue header tab, the
-- red close button, a dim backdrop that closes it. One scrolling list with two sections, each under a yellow-on-black
-- heading like the Visitor Book's:
--   In this server   one row per other player here (Players:GetPlayers() minus you; the list redraws on PlayerAdded
--                    and PlayerRemoving while the screen is open), or the line "Nobody else is here right now".
--   Friends          your Roblox friends, read once per session with Players:GetFriendsAsync in a task.spawn (up to
--                    data/Visiting FriendListMax, in page order, the online ones first, each with a green "Online"
--                    chip). "Finding your friends..." while it loads; the "No friends yet" line when there are none
--                    or the call fails (a failed call is tried again the next time the screen opens).
-- A row is a white card with the name in navy (no outline, helper text on a card), the chip when the friend is online
-- and a green Visit button at the right (0.25 of the card wide, like the Mailbox's Claim).
--
-- Tapping Visit asks the server (VisitHome, one request in flight); the server judges everything: whether the owner's
-- lock lets this player in, whether the home is reachable, whether it is this server's own view or a teleport. On ok
-- the screens close; when the owner was in this server a HomeView push follows at once and the bootstrap's welcome
-- toast answers it; when it was a flight the "Flying to ..." toast says so, but only if no push arrived within half
-- a second (the client cannot tell the two apart). A refusal is a toast; RateLimited is silent.
--
-- The rows are built once per list change (the sections' content changed, not each frame) into one Content frame
-- inside the ScrollingFrame, and as in the Mailbox there are no layout objects: every child's position and size is a
-- fraction of the canvas, worked out here from the content's height in visible-list heights, so nothing feeds back.
-- Heights are in visible-list heights (the viewport of the list is 1): a heading 0.13, a text line 0.22, a row 0.27
-- and a 0.03 gap after each, so two rows and a heading fit at a glance on an iPhone SE (a row about 66 px) and the
-- rest scrolls; on an iPad the same fractions give 116 px rows.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local VisitingData = require(Shared:WaitForChild("data"):WaitForChild("Visiting"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local Screens = require(script.Parent.Screens)
local State = require(script.Parent.Parent.State)

local VisitScreen = {}

-- Someone the list can send you to. `order` is the position in the page order, which keeps the online-first sort stable.
type Person = { userId: number, name: string, online: boolean, order: number }
-- One element of the list: its kind, its text (a row's name), its height in visible-list heights, and for a row the
-- person and whether it wears the Online chip.
type Entry = { kind: "heading" | "line" | "row", text: string, h: number, person: Person?, chip: boolean }
type FriendsState = "idle" | "loading" | "ready" | "failed"

-- Panel layout, as fractions of the panel (the Mailbox's size and place). The header tab straddles the top edge and
-- the close button reaches down to 0.155, so the list starts under it and takes the rest down to the margin.
local PANEL_W = 0.8
local PANEL_H = 0.78
local PANEL_ASPECT = 1.6
local HEADER_W = 0.4 -- "Visit a friend" is longer than "Mailbox"
local LIST_Y = 0.13
local LIST_BOTTOM = 0.97
local SCROLLBAR_PX = 6 -- the thin dark bar's thickness; not a Size
-- Heights in visible-list heights, and the gap after every element.
local HEADING_H = 0.13
local LINE_H = 0.22
local ROW_H = 0.27
local GAP = 0.03
-- Inside a row, as fractions of the card.
local ROW_PAD_X = 0.03
local NAME_W_CHIP = 0.45 -- the name's width beside the Online chip
local NAME_W_PLAIN = 0.67 -- and without one: up to the button
local CHIP_X, CHIP_W = 0.5, 0.2
local CHIP_Y, CHIP_H = 0.27, 0.46
local GO_X, GO_W = 0.73, 0.25
local GO_Y, GO_H = 0.18, 0.64
local DELETED_ACCOUNT_NAME = "Account Deleted" -- the name Roblox gives a deleted account in the friend pages
local FLYING_TOAST_DELAY = 0.5 -- seconds a HomeView push has to arrive before the trip toast says the player is flying

local localPlayer = Players.LocalPlayer

local gui: ScreenGui? = nil
local panel: Frame? = nil
local scroller: ScrollingFrame? = nil
local content: Frame? = nil
local open = false
local pending = false -- one VisitHome in flight at a time
local friends: { Person } = {}
local friendsState: FriendsState = "idle"
local visitSeq = 0 -- counts the "visit" topic's firings: a HomeView push landing between two readings shows as a change
local joinConnections: { RBXScriptConnection } = {}

-- Helpers ----------------------------------------------------------------

-- The other players in this server, by name, leaving out `leaving` (PlayerRemoving fires while the player is still
-- in GetPlayers).
local function playersHere(leaving: Player?): { Person }
	local out: { Person } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player ~= leaving then
			local name = if player.DisplayName ~= "" then player.DisplayName else player.Name
			table.insert(out, { userId = player.UserId, name = name, online = true, order = #out + 1 })
		end
	end
	table.sort(out, function(a: Person, b: Person)
		local left, right = string.lower(a.name), string.lower(b.name)
		if left ~= right then
			return left < right
		end
		return a.userId < b.userId
	end)
	return out
end

-- Reads the friend pages into `friends`: up to FriendListMax in page order, online ones first (the page order kept
-- within each group). A failed call leaves the list empty and the state "failed". Runs in its own thread.
local function loadFriends()
	if friendsState == "loading" or friendsState == "ready" then
		return
	end
	friendsState = "loading"
	task.spawn(function()
		local list: { Person } = {}
		local ok = pcall(function()
			local pages = Players:GetFriendsAsync(localPlayer.UserId)
			while #list < VisitingData.FriendListMax do
				for _, item in ipairs(pages:GetCurrentPage()) do
					local entry = item :: any
					-- A deleted account stays in the friend pages under the name "Account Deleted": nobody to visit, skipped.
					local deleted = entry.Username == DELETED_ACCOUNT_NAME or entry.DisplayName == DELETED_ACCOUNT_NAME
					if type(entry.Id) == "number" and not deleted and #list < VisitingData.FriendListMax then
						local display, user = entry.DisplayName, entry.Username
						local name = if type(display) == "string" and display ~= ""
							then display
							elseif type(user) == "string" and user ~= "" then user
							else Strings.VISIT_UNKNOWN_NAME
						table.insert(list, { userId = entry.Id, name = name, online = entry.IsOnline == true, order = #list + 1 })
					end
				end
				if pages.IsFinished then
					break
				end
				pages:AdvanceToNextPageAsync()
			end
		end)
		if ok then
			table.sort(list, function(a: Person, b: Person)
				if a.online ~= b.online then
					return a.online
				end
				return a.order < b.order
			end)
			friends = list
			friendsState = "ready"
		else
			friends = {}
			friendsState = "failed"
		end
		if open then
			VisitScreen.Redraw(nil)
		end
	end)
end

-- What the list says now, top to bottom, and its total height in visible-list heights.
local function plan(leaving: Player?): ({ Entry }, number)
	local entries: { Entry } = {}
	local function add(kind: "heading" | "line" | "row", text: string, h: number, person: Person?, chip: boolean)
		table.insert(entries, { kind = kind, text = text, h = h, person = person, chip = chip })
	end
	add("heading", Strings.VISIT_SECTION_HERE, HEADING_H, nil, false)
	local here = playersHere(leaving)
	if #here == 0 then
		add("line", Strings.VISIT_NOBODY_HERE, LINE_H, nil, false)
	else
		for _, person in ipairs(here) do
			add("row", person.name, ROW_H, person, false)
		end
	end
	add("heading", Strings.VISIT_SECTION_FRIENDS, HEADING_H, nil, false)
	if friendsState == "ready" and #friends > 0 then
		for _, person in ipairs(friends) do
			add("row", person.name, ROW_H, person, person.online)
		end
	elseif friendsState == "ready" or friendsState == "failed" then
		add("line", Strings.VISIT_EMPTY, LINE_H, nil, false)
	else
		add("line", Strings.VISIT_LOADING, LINE_H, nil, false)
	end
	local total = 0
	for _, entry in ipairs(entries) do
		total += entry.h + GAP
	end
	return entries, total - GAP
end

-- Server calls -------------------------------------------------------------

-- The toast a refusal earns; nil for a silent one (RateLimited) or a reason this screen does not name.
local function refusalToast(reason: string, name: string): (string?, Color3?)
	if reason == "Self" then
		return Strings.TOAST_VISIT_SELF, Theme.Colors.Select
	elseif reason == "NoHome" then
		return Strings.TOAST_VISIT_NOHOME:format(name), Theme.Colors.Select
	elseif reason == "OwnerOnly" then
		return Strings.TOAST_VISIT_OWNERONLY:format(name), Theme.Colors.Close
	elseif reason == "FriendsOnly" then
		return Strings.TOAST_VISIT_FRIENDSONLY:format(name), Theme.Colors.Close
	elseif reason == "Away" then
		return Strings.TOAST_VISIT_AWAY:format(name), Theme.Colors.Select
	elseif reason == "NoPlace" then
		return Strings.TOAST_VISIT_NOPLACE, Theme.Colors.Featured
	elseif reason == "Busy" then
		return Strings.TOAST_FLY_BUSY, Theme.Colors.Select
	elseif reason == "Crowded" then
		return Strings.TOAST_VISIT_CROWDED, Theme.Colors.Select
	end
	return nil, nil
end

-- Asks the server to take the player to `userId`'s home. Runs in its own thread: callers are taps. The server judges
-- it; ok means the view switched here (a HomeView push, welcomed by the bootstrap) or a flight began (the Flew event
-- plays the fade), and the screens close either way.
local function visit(userId: number, name: string)
	if pending then
		return
	end
	pending = true
	local seq = visitSeq
	task.spawn(function()
		local called, ok, reason = pcall(function(): (any, any)
			return Net.func("VisitHome"):InvokeServer(userId)
		end)
		pending = false
		if not called then
			print(("[%s] VisitHome failed: %s"):format(Config.WorkingTitle, tostring(ok)))
			return
		end
		if ok == true then
			Screens.CloseAll()
			if visitSeq == seq then
				-- No view has been pushed yet: either it is on its way (the welcome toast comes with it) or this is
				-- a trip. Give the push half a second before saying the player is flying.
				task.delay(FLYING_TOAST_DELAY, function()
					if visitSeq == seq then
						Toast.Show(Strings.TOAST_VISIT_FLYING:format(name), Theme.Colors.Select)
					end
				end)
			end
			return
		end
		local text, color = refusalToast(tostring(reason), name)
		if text then
			Toast.Show(text, color)
		elseif reason ~= "RateLimited" then
			print(("[%s] VisitHome refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- Rows -------------------------------------------------------------------

-- A section heading, centred, yellow on black like the Visitor Book's.
local function buildHeading(parent: Frame, text: string, y: number, h: number)
	Builder.label({
		parent = parent,
		name = "Heading",
		text = text,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		position = UDim2.fromScale(0, y),
		size = UDim2.fromScale(1, h),
		zIndex = 4,
	})
end

-- A one-line message (nobody here, loading, no friends), navy with no stroke, wrapped to two lines at most.
local function buildLine(parent: Frame, text: string, y: number, h: number)
	local line = Builder.label({
		parent = parent,
		name = "Line",
		text = text,
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Outline,
		stroke = 0,
		position = UDim2.fromScale(0.5 * ROW_PAD_X, y),
		size = UDim2.fromScale(1 - ROW_PAD_X, h),
		zIndex = 4,
	})
	line.TextWrapped = true
end

-- One person: a white card with the name at the left, the Online chip when it applies and the green Visit button at
-- the right.
local function buildRow(parent: Frame, person: Person, chip: boolean, y: number, h: number)
	local card = Builder.frame({
		parent = parent,
		name = "Row",
		position = UDim2.fromScale(0, y),
		size = UDim2.fromScale(1, h),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Rarity.Common,
		zIndex = 3,
	})
	local name = Builder.label({
		parent = card,
		name = "Name",
		text = person.name,
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Outline,
		stroke = 0,
		xAlign = Enum.TextXAlignment.Left,
		position = UDim2.fromScale(ROW_PAD_X, 0.1),
		size = UDim2.fromScale(if chip then NAME_W_CHIP else NAME_W_PLAIN, 0.8),
		zIndex = 4,
	})
	name.TextTruncate = Enum.TextTruncate.AtEnd
	if chip then
		local pill = Builder.pill({
			parent = card,
			name = "Online",
			position = UDim2.fromScale(CHIP_X, CHIP_Y),
			size = UDim2.fromScale(CHIP_W, CHIP_H),
			color = Theme.Colors.Confirm,
			stroke = Theme.Stroke.Text,
			strokeColor = Theme.Colors.Outline,
			zIndex = 4,
		})
		Builder.label({
			parent = pill,
			name = "Text",
			text = Strings.VISIT_ONLINE,
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.86, 0.8),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 5,
		})
	end
	Builder.button({
		parent = card,
		name = "Visit",
		text = Strings.VISIT_GO,
		color = Theme.Colors.Confirm,
		position = UDim2.fromScale(GO_X, GO_Y),
		size = UDim2.fromScale(GO_W, GO_H),
		textSize = Theme.TextSize.Label,
		zIndex = 4,
	}, function()
		visit(person.userId, person.name)
	end)
end

-- Redraws the whole list from the players here and the friends read so far: the old content goes, the new one is
-- laid out as fractions of the canvas. `leaving` is a player on the way out (PlayerRemoving) that no longer counts.
-- Cheap while closed: it returns at once, and Open draws.
function VisitScreen.Redraw(leaving: Player?)
	local frame = scroller
	if not open or not frame then
		return
	end
	local old = content
	if old then
		old:Destroy()
	end
	local entries, total = plan(leaving)
	local pages = math.max(1, total)
	-- CanvasSize scales against the panel (the list's parent), not the list, so the pages are multiplied by the
	-- list's share of it (UI-Rules.md); the children below are fractions of the canvas, which is `pages` lists tall.
	frame.CanvasSize = UDim2.fromScale(0, pages * (LIST_BOTTOM - LIST_Y))
	local holder = Builder.frame({
		parent = frame,
		name = "Content",
		size = UDim2.fromScale(1, 1), -- the canvas
		zIndex = 3,
	})
	content = holder
	local y = 0
	for _, entry in ipairs(entries) do
		local at, h = y / pages, entry.h / pages
		local person = entry.person
		if entry.kind == "heading" then
			buildHeading(holder, entry.text, at, h)
		elseif entry.kind == "line" then
			buildLine(holder, entry.text, at, h)
		elseif person then
			buildRow(holder, person, entry.chip, at, h)
		end
		y += entry.h + GAP
	end
end

-- Build --------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("VisitScreen", 20)
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
		VisitScreen.Close()
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
		size = UDim2.fromScale(HEADER_W, 0.11),
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
		text = Strings.VISIT_TITLE,
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
		VisitScreen.Close()
	end)

	-- The list: a ScrollingFrame with a thin dark bar, the same as the Mailbox's. Its content is laid out in code.
	local frame = Instance.new("ScrollingFrame")
	frame.Name = "List"
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

	-- A HomeView push (or the boot pull) is what a visit looks like from here: count them, so a tap's follow-up can
	-- tell whether the view arrived while the call was in flight.
	State.OnChanged("visit", function()
		visitSeq += 1
	end)
end

-- Public API -------------------------------------------------------------

function VisitScreen.IsOpen(): boolean
	return open
end

function VisitScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	local list = scroller
	if list then
		list.CanvasPosition = Vector2.zero
	end
	VisitScreen.Redraw(nil)
	loadFriends() -- the first open of the session reads the friends; later opens use the cached list
	table.insert(
		joinConnections,
		Players.PlayerAdded:Connect(function()
			VisitScreen.Redraw(nil)
		end)
	)
	table.insert(
		joinConnections,
		Players.PlayerRemoving:Connect(function(leaving: Player)
			VisitScreen.Redraw(leaving)
		end)
	)
	root.Enabled = true
	Builder.open(body)
end

function VisitScreen.Close()
	if not open then
		return
	end
	open = false
	for _, connection in ipairs(joinConnections) do
		connection:Disconnect()
	end
	table.clear(joinConnections)
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

function VisitScreen.Toggle()
	if open then
		VisitScreen.Close()
	else
		VisitScreen.Open()
	end
end

return VisitScreen
