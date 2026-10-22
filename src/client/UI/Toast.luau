--!strict
-- StarterPlayerScripts.Client.UI.Toast: short messages under the HUD's top rows, held to the notification budget (data/Notify,
-- Shared/NotifyMath, UI Playbook "Clean pass: notifications"). Ethan, 2026-10-22: "the viewer shouldn't be overstimulated". At most
-- three things announce at once: ONE banner and TWO toasts. Four classes:
--   * Banner (Toast.Banner): its own slot, top centre at Notify.BannerTop (the bottom edge while a panel is open), with its own child
--     frame of the ScreenGui, never in the toast stack. One on screen at a time; the others wait in a queue of Notify.BannerQueueMax in
--     priority order (a Rush or Shower, then the Warden, the Peddler, a Server Luck, someone else's big catch), one per kind (the latest
--     wins), Notify.BannerGapSeconds between two, and one queued longer than Notify.BannerStaleSeconds is dropped (the event chip carries
--     its state by then). Its sound plays once, never again on a replay after a Hush.
--   * Toast (Toast.Show, Toast.ShowAction): the stack, top centre from Notify.StackTop (lower while a banner stands in the top slot), a
--     ding. At most Notify.ToastMax at a time; a third waits for a place. A toast whose merge key matches a live (or waiting) one within
--     Notify.MergeSeconds updates it in place, restarts its time and makes no sound: three pickups read "+3 Wreck Plate".
--   * Quiet line (Toast.Quiet): the stack under the toasts, no sound, Notify.QuietSeconds. Dropped first when the stack is full, and
--     never held through a quiet moment (dropped instead).
-- At most one UI cue (a banner sound or a ding) plays in Notify.CueGapSeconds.
-- Each toast is a dark block with a coloured square icon on the left and outlined white text (the square gives way to a pack icon when the
-- caller names one that is uploaded). It slides down from above with a Back ease, waits its time, fades out, and the stack re-flows. A toast
-- whose words do not fit one line at the minimum text size grows taller (up to MAX_LINES lines) instead of being cut. Pure presentation:
-- callers decide what to say (usually a server refusal reason mapped to a TOAST_* string).
-- The look is block cells (UI Playbook "Screens after the HUD", Decisions B44): a toast is an edged dark block (a toast is built
-- per message, so it takes the eight-frame edged form, not full cells), its square a flat block in the accent, a named icon the
-- pixel icon first (Builder.blockIcon); a banner is an edged block in the accent.
-- Quiet moments: while Toast.IsQuiet() is true (the Reveal is open or a catch is running, which the bootstrap tells
-- through SetQuietProbe) nothing new is drawn, since the Reveal and the capture bar are the two moments nothing may
-- cover. Toasts queue instead, in order (Config.ToastHoldMax toasts, the oldest dropped past it) and drain one per
-- Config.ToastHoldGapSeconds once it is quiet again; a banner waits in its own queue. Whatever is already on screen does not stay: Hush,
-- which the bootstrap calls as a catch begins and Reveal.Show calls as the card opens, takes every live toast and banner down at once and
-- puts them back at the front of their queues in their on-screen order, each with its full time again and without its sound, so they replay
-- after the moment (a banner drawn a second before the tap is as unwelcome over the capture bar as one drawn during it); live quiet lines
-- are dropped. QuietFor adds a timed quiet moment (the module-complete assembly burst, the quick catch card, and the tap on an egg claim or
-- purchase, which starts the calm before the server's answer and its Reveal arrive).
-- ShowAction is a toast with one chip on its right end, a chunky block button (the only toast a player can tap): the Earn faster
-- chip after "Need N more Scrap" (UI/ScrapGap, Decision B51). A tap runs the caller's action and takes the toast down; it queues,
-- hushes and replays like any toast.

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Notify = require(Shared:WaitForChild("data"):WaitForChild("Notify"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local NotifyMath = require(Shared:WaitForChild("NotifyMath"))
local Builder = require(script.Parent.Builder)

local Toast = {}

local TOP_DEFAULT = Notify.StackTop -- first slot of the stack, under the goal plate and the banner's slot
local top = TOP_DEFAULT -- the bootstrap lowers it while a panel is open so toasts clear the header tab
local GAP = 0.012 -- between stacked toasts, in screen height
local WIDTH = 0.42 -- of the screen; the aspect constraint derives the height from this
local MAX_HEIGHT = 0.2 -- generous cap so the width stays the binding side of the aspect fit
local ASPECT = 7
local BANNER_BOTTOM_MARGIN = 0.06 -- while a panel is open a banner lands this far above the bottom edge instead of over the panel's header
-- A pack icon in place of the coloured square: ICON_H of the toast's height, square, at ICON_X from the left; the
-- text then starts one ICON_GAP past it (all of the toast's width) and keeps its right edge at TEXT_X + TEXT_W.
local ICON_H = 0.7
local ICON_X = 0.03
local ICON_GAP = 0.02
local TEXT_X = 0.16 -- the text's left edge beside the coloured square
local TEXT_W = 0.81
local TEXT_H = 0.7 -- the text box's height, of the toast
local MAX_LINES = 3 -- a toast never grows past this many lines of text
-- An action toast's chip: its width and height as shares of the toast, its right edge, and the gap between the text and it.
local ACTION_W = 0.3
local ACTION_H = 0.72
local ACTION_RIGHT = 0.975
local ACTION_GAP = 0.02

-- The chip an action toast carries: its words, its colour, and what a tap does.
export type Action = { text: string, color: Color3, onTap: () -> () }

-- Everything one message needs to be drawn, and to be drawn again after a Hush. `class` is "Toast", "Quiet" or "Banner"; `kind` keys a
-- banner (NotifyMath's queue); `mergeKey` names a toast that later ones with the same key update in place; `cued` is true once its
-- sound has been asked for, so a replay is silent.
type Item = {
	class: string,
	kind: string,
	text: string,
	color: Color3,
	seconds: number,
	iconKey: string?,
	action: Action?,
	mergeKey: string?,
	cued: boolean,
}
-- A message on screen, with the item it was drawn from so Hush can put it back in its queue. `token` changes whenever its time is
-- restarted (a merge); `top` is true for a banner standing in the top slot.
type Entry = { group: CanvasGroup, label: TextLabel?, leaving: boolean, height: number, item: Item, token: number, updatedAt: number, top: boolean }

local gui: ScreenGui? = nil
local stackFrame: Frame? = nil
local bannerFrame: Frame? = nil
local entries: { Entry } = {} -- live toasts and quiet lines on the stack, oldest first
local live: { Entry } = {} -- every message on screen and not leaving, in the order drawn (a banner is here and not in `entries`)
local bannerEntry: Entry? = nil -- the banner on screen
local bannerFreeAt = 0 -- os.clock() from which the next banner may show (the last one's leaving plus its gap)
local bannerQueue: { NotifyMath.Banner } = {} -- banners waiting, in priority order; the payload is the Item
local held: { Item } = {} -- toasts waiting for a quiet moment to pass or for a place on the stack, oldest first
local lastCueAt = -math.huge -- os.clock() of the last banner sound or ding
local panelOpen: (() -> boolean)? = nil -- the bootstrap's Screens.IsAnyOpen; a banner pushed while it answers true takes the bottom slot
local quietProbe: (() -> boolean)? = nil -- the bootstrap's "Reveal open or catch running"; with quietUntil, the answer behind Toast.IsQuiet
local quietUntil = 0 -- os.clock() until which a timed quiet moment (QuietFor) lasts
local pumping = false -- the pump thread is running

-- Lines `text` needs at the minimum size in a box `boxPx` wide, and one line's height in px (1 line of 17 px when it fits
-- or the text cannot be measured). A 425 px window shows a 144 px text box: "You waved at Player1's Mossbop" is two lines there.
local function measureLines(text: string, boxPx: number): (number, number)
	local ok, lines, lineHeight = pcall(function(): (number, number)
		local one = TextService:GetTextSize("A", Theme.TextSize.Min, Theme.Font, Vector2.new(10000, 10000))
		local wrapped = TextService:GetTextSize(text, Theme.TextSize.Min, Theme.Font, Vector2.new(boxPx, 10000))
		return math.clamp(math.round(wrapped.Y / math.max(1, one.Y)), 1, MAX_LINES), one.Y
	end)
	if ok then
		return lines, lineHeight
	end
	return 1, Theme.TextSize.Min
end

-- Height of one toast in screen Scale, from the width-bound aspect fit (so slots stack tightly). `minPx` is the
-- least height that holds the text; a toast that fits one line is just the aspect fit.
local function heightScale(root: ScreenGui, width: number, aspect: number, minPx: number?): number
	local abs = root.AbsoluteSize
	if abs.X <= 0 or abs.Y <= 0 then
		return MAX_HEIGHT
	end
	local px = math.min(math.max(width * abs.X / aspect, minPx or 0), MAX_HEIGHT * abs.Y)
	return px / abs.Y
end

-- Where the stack starts: `top`, or under the banner while one stands in the top slot (the banner is wider than a toast and sits
-- in the toasts' column, so the stack gives way to it).
local function stackBase(): number
	local banner = bannerEntry
	if banner and banner.top and not banner.leaving then
		return math.max(top, Notify.BannerTop + banner.height + GAP)
	end
	return top
end

-- The slot a given entry occupies: the heights of everything above it, plus gaps.
local function slotPosition(index: number): UDim2
	local y = stackBase()
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
	local liveIndex = table.find(live, entry)
	if liveIndex then
		table.remove(live, liveIndex)
	end
	if bannerEntry == entry then
		bannerEntry = nil
		bannerFreeAt = os.clock() + NotifyMath.BannerGap(entry.item.kind)
	end
	local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(entry.group, info, { GroupTransparency = 1 })
	tween.Completed:Once(function()
		entry.group:Destroy()
	end)
	tween:Play()
	reflow()
end

-- Takes the entry down after `seconds`, unless a merge restarted its time meanwhile (the token moved on).
local function scheduleDismiss(entry: Entry, seconds: number)
	entry.token += 1
	local token = entry.token
	task.delay(seconds, function()
		if entry.token == token then
			dismiss(entry)
		end
	end)
end

-- Public API -------------------------------------------------------------

-- Creates the ScreenGui once, with its two child frames: the toast stack and the banner's own slot. Show calls this, so wiring code
-- may skip it.
function Toast.Build()
	if gui then
		return
	end
	local root = Builder.screen("Toasts", 40)
	gui = root
	stackFrame = Builder.frame({ parent = root, name = "Stack", zIndex = 1 })
	bannerFrame = Builder.frame({ parent = root, name = "BannerSlot", zIndex = 2 })
end

-- Builds one message's block inside `parent` and slides it in. A banner is an edged block in its colour with one line; a toast or quiet
-- line is an edged dark block with the coloured square (or the named icon), the words and, for an action toast, the chip.
local function push(item: Item)
	Toast.Build()
	local root, stack, slot = gui, stackFrame, bannerFrame
	if not root or not stack or not slot then
		return
	end
	local text, accent, seconds, iconKey, action = item.text, item.color, item.seconds, item.iconKey, item.action
	local banner = item.class == "Banner"
	-- The text's right edge, of the toast: short of the chip on an action toast.
	local textRight = if action then ACTION_RIGHT - ACTION_W - ACTION_GAP else TEXT_X + TEXT_W
	local width = if banner then Notify.BannerWidth else WIDTH
	local aspect = if banner then Notify.BannerAspect else ASPECT
	local abs = root.AbsoluteSize
	local minPx: number? = nil
	if not banner and abs.X > 0 then
		-- Wrapping: a toast that needs more than one line at the minimum size is taller (its text box is TEXT_H of it).
		local lines, lineHeight = measureLines(text, (textRight - TEXT_X) * width * abs.X)
		if lines > 1 then
			minPx = lines * lineHeight / TEXT_H
		end
	end
	local height = heightScale(root, width, aspect, minPx)
	if abs.X > 0 and abs.Y > 0 then
		aspect = width * abs.X / (height * abs.Y) -- the aspect that gives exactly this height
	end
	local atTop = not (banner and panelOpen ~= nil and panelOpen())

	-- A CanvasGroup so the whole pill (strokes included) fades with one GroupTransparency tween.
	local group = Instance.new("CanvasGroup")
	group.Name = if banner then "Banner" else if item.class == "Quiet" then "QuietLine" else "Toast"
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.AnchorPoint = Vector2.new(0.5, 0)
	group.Size = UDim2.fromScale(width, MAX_HEIGHT)
	group.Position = UDim2.fromScale(0.5, -height)
	group.ZIndex = 1
	Builder.aspect(group, aspect)
	group.Parent = if banner then slot else stack

	-- A toast is an edged dark block with a coloured square; a banner is an edged block in the colour itself. The plate keeps the
	-- group's aspect, its rows from the toast's height, so its cells are the HUD's.
	local fill = if banner then accent else Theme.Block.Trough
	local pill = Builder.blockPlate({
		parent = group,
		name = "Pill",
		color = fill,
		aspect = aspect,
		rows = Builder.blockRows(height),
		cells = false,
		edges = true,
		zIndex = 1,
	})
	local topZ = Builder.blockTop(pill)
	local label: TextLabel
	if banner then
		label = Builder.label({
			parent = pill,
			name = "Text",
			text = text,
			textSize = Theme.TextSize.Label,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.94, 0.72),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = topZ,
		})
	else
		local image: GuiObject? = nil
		if iconKey then
			image = Builder.blockIcon({
				parent = pill,
				name = "Icon",
				key = iconKey,
				position = UDim2.fromScale(ICON_X, 0.5),
				size = UDim2.fromScale(ICON_H / aspect, ICON_H),
				anchor = Vector2.new(0, 0.5),
				zIndex = topZ,
			})
		end
		local textX = TEXT_X
		if image then
			textX = ICON_X + ICON_H / aspect + ICON_GAP
		else
			Builder.blockPlate({
				parent = pill,
				name = "Icon",
				color = accent,
				aspect = 1,
				rows = Theme.Block.MinRows,
				cells = false,
				position = UDim2.fromScale(0.03, 0.5),
				size = UDim2.fromScale(0.12, 0.62),
				anchor = Vector2.new(0, 0.5),
				zIndex = topZ,
			})
		end
		label = Builder.label({
			parent = pill,
			name = "Text",
			text = text,
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(textX, 0.5),
			size = UDim2.fromScale(textRight - textX, TEXT_H),
			anchor = Vector2.new(0, 0.5),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = topZ,
		})
	end

	local entry: Entry = { group = group, label = label, leaving = false, height = height, item = item, token = 0, updatedAt = os.clock(), top = banner and atTop }
	if action and not banner then
		Builder.blockButton({
			parent = pill,
			name = "Action",
			text = action.text,
			color = action.color,
			position = UDim2.fromScale(ACTION_RIGHT, 0.5),
			size = UDim2.fromScale(ACTION_W, ACTION_H),
			anchor = Vector2.new(1, 0.5),
			textSize = Theme.TextSize.Min,
			rows = Builder.blockButtonRows(ACTION_H * height),
			cells = false,
			hit = true,
			zIndex = topZ + 1,
		}, function()
			if entry.leaving then
				return
			end
			dismiss(entry)
			action.onTap()
		end)
	end
	table.insert(live, entry)
	local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	if banner then
		bannerEntry = entry
		if atTop then
			TweenService:Create(group, info, { Position = UDim2.fromScale(0.5, Notify.BannerTop) }):Play()
			reflow() -- the stack gives way to a banner in the top slot
		else
			-- A wide banner over an open panel hides its header: slide it up from the bottom edge instead.
			group.Position = UDim2.fromScale(0.5, 1 + height)
			TweenService:Create(group, info, { Position = UDim2.fromScale(0.5, 1 - BANNER_BOTTOM_MARGIN - height) }):Play()
		end
	else
		table.insert(entries, entry)
		TweenService:Create(group, info, { Position = slotPosition(#entries) }):Play()
	end
	scheduleDismiss(entry, seconds)
end

-- True while the Reveal or a capture encounter (the Legendary opening included) owns the screen, or a timed quiet moment
-- (QuietFor) runs. The bootstrap supplies the Reveal and capture answer (it holds both states); without a probe only the
-- timed moment counts.
function Toast.IsQuiet(): boolean
	return os.clock() < quietUntil or (quietProbe ~= nil and quietProbe())
end

function Toast.SetQuietProbe(probe: (() -> boolean)?)
	quietProbe = probe
end

-- A presentation asks for `seconds` of calm from now (the longest ask stands): the assembly burst over a finished module,
-- the tap on an egg claim or purchase (Gifts, Peddler), the quick catch card and the launch sequence (World.LaunchSequence: the lift,
-- the fades and the hold) are the callers. Held items drain once it ends.
function Toast.QuietFor(seconds: number)
	quietUntil = math.max(quietUntil, os.clock() + seconds)
end

-- Plays the item's cue once: a banner's sound for a banner, the ding for a toast, nothing for a quiet line or a replay, and never
-- twice inside Notify.CueGapSeconds.
local function cue(item: Item)
	if item.cued then
		return
	end
	item.cued = true
	local sound: string? = nil
	if item.class == "Banner" then
		sound = Sounds.Banner
	elseif item.class == "Toast" then
		sound = Sounds.ToastDing
	end
	local now = os.clock()
	if sound ~= nil and NotifyMath.CueAllowed(now, lastCueAt) then
		lastCueAt = now
		Builder.playSound(sound)
	end
end

local function draw(item: Item)
	cue(item)
	push(item)
end

-- The classes of what is on the stack, oldest first.
local function stackClasses(): { string }
	local classes: { string } = {}
	for _, entry in ipairs(entries) do
		table.insert(classes, entry.item.class)
	end
	return classes
end

-- Shows the head of the waiting toasts when the stack has a place for it. True when one was drawn.
local function drawHeldToast(): boolean
	local item = held[1]
	if item == nil then
		return false
	end
	local answer, evict = NotifyMath.StackAnswer(stackClasses(), item.class)
	if answer == "wait" then
		return false
	end
	table.remove(held, 1)
	if answer == "drop" then
		return false
	end
	if evict ~= nil then
		dismiss(entries[evict]) -- a quiet line gives its place to a toast
	end
	draw(item)
	return true
end

-- Shows the next banner when the slot is free and it is quiet.
local function drawNextBanner()
	if bannerEntry ~= nil then
		return
	end
	local next = NotifyMath.NextBanner(bannerQueue, os.clock(), bannerFreeAt)
	if next ~= nil then
		draw(next.payload :: Item)
	end
end

-- Draws what is waiting, as the quiet moments and the places allow: banners one at a time, held toasts one per
-- Config.ToastHoldGapSeconds. One thread at a time; it ends when both queues are empty.
local function pump()
	if pumping then
		return
	end
	pumping = true
	task.spawn(function()
		while #held > 0 or #bannerQueue > 0 do
			if Toast.IsQuiet() then
				task.wait()
			else
				drawNextBanner()
				if drawHeldToast() then
					task.wait(Config.ToastHoldGapSeconds)
				else
					task.wait()
				end
			end
		end
		pumping = false
	end)
end

-- Keeps at most Config.ToastHoldMax waiting toasts: the oldest go first.
local function trimHeld()
	while #held > Config.ToastHoldMax do
		table.remove(held, 1)
	end
end

-- Whether a message with `item`'s merge key joins one already waiting or on screen (updating it in place). Answers true when it did.
local function tryMerge(item: Item): boolean
	local key = item.mergeKey
	if key == nil then
		return false
	end
	for _, other in ipairs(held) do
		if other.mergeKey == key then
			other.text = item.text
			other.color = item.color
			return true
		end
	end
	local now = os.clock()
	for _, entry in ipairs(entries) do
		if not entry.leaving and entry.item.mergeKey == key and NotifyMath.CanMerge(entry.updatedAt, now) then
			entry.item.text = item.text
			if entry.label then
				entry.label.Text = item.text
			end
			entry.updatedAt = now
			scheduleDismiss(entry, item.seconds)
			return true
		end
	end
	return false
end

-- Whether a message with this merge key would merge now (a matching toast or quiet line waits, or is on screen inside the merge window).
-- A caller that counts a running total ("+3 Wreck Plate") asks this before adding to it, so the count restarts when the line has gone.
function Toast.IsMerging(mergeKey: string): boolean
	for _, other in ipairs(held) do
		if other.mergeKey == mergeKey then
			return true
		end
	end
	local now = os.clock()
	for _, entry in ipairs(entries) do
		if not entry.leaving and entry.item.mergeKey == mergeKey and NotifyMath.CanMerge(entry.updatedAt, now) then
			return true
		end
	end
	return false
end

-- A toast or quiet line: merges into a matching one, draws now, or waits (a toast) or is dropped (a quiet line).
local function submit(item: Item)
	if tryMerge(item) then
		return
	end
	if item.class == "Quiet" then
		-- Never held through a quiet moment, and never waiting for a place.
		if Toast.IsQuiet() then
			return
		end
		local answer, evict = NotifyMath.StackAnswer(stackClasses(), "Quiet")
		if answer == "show" then
			if evict ~= nil then
				dismiss(entries[evict])
			end
			draw(item)
		end
		return
	end
	if not Toast.IsQuiet() and #held == 0 then
		local answer, evict = NotifyMath.StackAnswer(stackClasses(), "Toast")
		if answer == "show" then
			if evict ~= nil then
				dismiss(entries[evict])
			end
			draw(item)
			return
		end
	end
	-- Anything arriving behind a waiting toast waits too, so the order never changes.
	table.insert(held, item)
	trimHeld()
	pump()
end

-- A quiet moment is starting: every message on screen comes down at once (dismiss, so its fade is the usual short one) and goes back to
-- the front of its queue in its on-screen order with its full time and without its sound, to replay after the moment. A queued banner of
-- the same kind is newer, so it wins; a live quiet line is dropped. The bootstrap calls this as a catch begins and Reveal.Show as the
-- card opens; twice in a row, or with nothing live, it does nothing.
function Toast.Hush()
	if #live == 0 then
		return
	end
	local shown = table.clone(live) -- dismiss edits `live`
	for _, entry in ipairs(shown) do
		dismiss(entry)
	end
	local now = os.clock()
	for index = #shown, 1, -1 do
		local item = shown[index].item
		if item.class == "Banner" then
			local newer = false
			for _, other in ipairs(bannerQueue) do
				if other.kind == item.kind then
					newer = true
				end
			end
			if not newer then
				NotifyMath.InsertBanner(bannerQueue, { kind = item.kind, queuedAt = now, payload = item }, true)
			end
		elseif item.class == "Toast" then
			table.insert(held, 1, item) -- walking back to front, so the front ends up in on-screen order
		end
	end
	bannerFreeAt = now -- the replay needs no gap
	trimHeld()
	pump()
end

-- iconKey (an Icons key, e.g. a material or power-up id) swaps the coloured square for that icon when its
-- image is uploaded; without it, or while the id is 0, the toast is the plain one. `seconds` overrides the time (nil: Theme.Tween.Toast).
-- `mergeKey` names a message that later ones with the same key update in place within Notify.MergeSeconds (the caller builds the new
-- text, e.g. the running total).
function Toast.Show(text: string, color: Color3?, iconKey: string?, seconds: number?, mergeKey: string?)
	submit({
		class = "Toast",
		kind = "",
		text = text,
		color = color or Theme.Colors.Featured,
		seconds = seconds or Theme.Tween.Toast,
		iconKey = iconKey,
		mergeKey = mergeKey,
		cued = false,
	})
end

-- A quiet line: a toast with no sound for what the player loses nothing by missing (a shower that is over, a friend who left). It
-- stays Notify.QuietSeconds, goes first when the stack is full, and is dropped, not held, in a quiet moment.
function Toast.Quiet(text: string, color: Color3?, iconKey: string?, mergeKey: string?)
	submit({
		class = "Quiet",
		kind = "",
		text = text,
		color = color or Theme.Colors.Select,
		seconds = Notify.QuietSeconds,
		iconKey = iconKey,
		mergeKey = mergeKey,
		cued = false,
	})
end

-- A toast with one tappable chip on its right end (see the header): `seconds` how long it stays (nil: a plain toast's time).
function Toast.ShowAction(text: string, color: Color3?, action: Action, seconds: number?)
	submit({
		class = "Toast",
		kind = "",
		text = text,
		color = color or Theme.Colors.Featured,
		seconds = seconds or Theme.Tween.Toast,
		iconKey = nil,
		action = action,
		cued = false,
	})
end

-- Where the stack starts, in screen Scale; nil restores the default. Live toasts re-flow.
function Toast.SetTop(y: number?)
	local next = y or TOP_DEFAULT
	if next ~= top then
		top = next
		reflow()
	end
end

-- A banner already standing in the top slot when a panel opens would cover the panel's header and close button: it slides down to the
-- bottom slot at once (the bootstrap calls this every poll). A banner that draws while a panel is open already takes the bottom slot.
function Toast.SyncPanel()
	local entry = bannerEntry
	if entry == nil or entry.leaving or panelOpen == nil then
		return
	end
	if NotifyMath.BannerMustMoveDown(entry.top, panelOpen()) then
		entry.top = false
		local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(entry.group, info, { Position = UDim2.fromScale(0.5, 1 - BANNER_BOTTOM_MARGIN - entry.height) }):Play()
		reflow() -- the stack no longer gives way to a banner in the top slot
	end
end

-- The bootstrap hands in Screens.IsAnyOpen so banners know when a panel owns the top of the screen.
function Toast.SetPanelProbe(probe: (() -> boolean)?)
	panelOpen = probe
end

-- A banner (see the header): `color` is usually the tier colour. While a panel is open it takes the bottom slot so the panel's header
-- stays readable. `kind` names what the banner is (a key of data/Notify BannerKinds: "rush", "shower", "warden", "sighting", "peddler",
-- "serverluck", "announce", "crash", "fly"): it sets the priority, and a newer banner of the same kind replaces the one waiting; without
-- a kind the text is the kind (the lowest priority, and only a repeat of the same line replaces).
function Toast.Banner(text: string, color: Color3, seconds: number?, kind: string?)
	local item: Item = {
		class = "Banner",
		kind = kind or text,
		text = text,
		color = color,
		seconds = seconds or Config.AnnounceSeconds,
		iconKey = nil,
		action = nil,
		mergeKey = nil,
		cued = false,
	}
	NotifyMath.InsertBanner(bannerQueue, { kind = item.kind, queuedAt = os.clock(), payload = item }, false)
	if not Toast.IsQuiet() and bannerEntry == nil and os.clock() >= bannerFreeAt then
		drawNextBanner() -- the slot is free: no wait for the pump
	end
	pump()
end

return Toast
