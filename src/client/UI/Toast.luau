--!strict
-- StarterPlayerScripts.Client.UI.Toast: short messages that stack top centre under the HUD's top
-- row. Each toast is a dark pill with a coloured square icon on the left and outlined white text (the
-- square gives way to a pack icon when the caller names one that is uploaded). It
-- slides down from above with a Back ease, waits Theme.Tween.Toast seconds, fades out, and the stack
-- re-flows. At most three show at once; the oldest leaves first. A toast whose words do not fit one line at the minimum
-- text size grows taller (up to MAX_LINES lines) instead of being cut. Pure presentation: callers decide
-- what to say (usually a server refusal reason mapped to a TOAST_* string). Banner is the wide,
-- coloured variant for server-wide announcements; it shares the stack.
-- Quiet moments: while Toast.Quiet() is true (the Reveal is open or a catch is running, which the bootstrap tells
-- through SetQuietProbe) nothing new is drawn, since the Reveal and the capture bar are the two moments nothing may
-- cover. Toasts and banners queue instead, in order (Config.ToastHoldMax toasts, the oldest dropped past it; one pending
-- banner per kind, the latest wins) and drain one per Config.ToastHoldGapSeconds once it is quiet again. Whatever is
-- already on screen does not stay: Hush, which the bootstrap calls as a catch begins and Reveal.Show calls as the card opens,
-- takes every live toast and banner down at once and puts them back at the front of the queue in their on-screen order, each
-- with its full time again, so they replay after the moment (a banner drawn a second before the tap is as unwelcome over the
-- capture bar as one drawn during it). QuietFor adds a timed quiet moment (the module-complete assembly burst, and the tap
-- on an egg claim or purchase, which starts the calm before the server's answer and its Reveal arrive).

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Builder = require(script.Parent.Builder)

local Toast = {}

local MAX_VISIBLE = 3
local TOP_DEFAULT = 0.29 -- first slot, below the HUD's whole centre column (the Friend Boost chip ends at 0.281 under the compass strip)
local top = TOP_DEFAULT -- the bootstrap lowers it while a panel is open so toasts clear the header tab
local GAP = 0.012 -- between stacked toasts, in screen height
local WIDTH = 0.42 -- of the screen; the aspect constraint derives the height from this
local MAX_HEIGHT = 0.2 -- generous cap so the width stays the binding side of the aspect fit
local ASPECT = 7
local BANNER_WIDTH = 0.7 -- the server-wide banner is wider and in the accent colour
local BANNER_ASPECT = 9
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

-- A toast or banner that arrived in a quiet moment (or behind one that did). `kind` keys a banner: a newer banner of the
-- same kind replaces the pending one.
type Held = { banner: boolean, kind: string, text: string, color: Color3, seconds: number, iconKey: string? }
-- A toast or banner on screen, with the item it was drawn from so Hush can put it back in the queue.
type Entry = { group: CanvasGroup, leaving: boolean, height: number, item: Held }

local gui: ScreenGui? = nil
local entries: { Entry } = {} -- live toasts, oldest first
local live: { Entry } = {} -- every toast and banner on screen and not leaving, in the order drawn (a banner over an open panel is here and not in `entries`)
local panelOpen: (() -> boolean)? = nil -- the bootstrap's Screens.IsAnyOpen; a banner pushed while it answers true takes the bottom slot
local quietProbe: (() -> boolean)? = nil -- the bootstrap's "Reveal open or catch running"; with quietUntil, the answer behind Toast.Quiet
local quietUntil = 0 -- os.clock() until which a timed quiet moment (QuietFor) lasts
local held: { Held } = {} -- toasts and banners waiting for a quiet moment to pass, oldest first
local draining = false -- the drain thread is running

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

-- The slot a given entry occupies: the heights of everything above it, plus gaps.
local function slotPosition(index: number): UDim2
	local y = top
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
	local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(entry.group, info, { GroupTransparency = 1 })
	tween.Completed:Once(function()
		entry.group:Destroy()
	end)
	tween:Play()
	reflow()
end

-- Public API -------------------------------------------------------------

-- Creates the ScreenGui once. Show calls this, so wiring code may skip it.
function Toast.Build()
	if gui then
		return
	end
	gui = Builder.screen("Toasts", 40)
end

local function push(item: Held)
	Toast.Build()
	local root = gui
	if not root then
		return
	end
	local text, accent, banner, seconds, iconKey = item.text, item.color, item.banner, item.seconds, item.iconKey
	while #entries >= MAX_VISIBLE do
		dismiss(entries[1])
	end
	local width = if banner then BANNER_WIDTH else WIDTH
	local aspect = if banner then BANNER_ASPECT else ASPECT
	local abs = root.AbsoluteSize
	local minPx: number? = nil
	if not banner and abs.X > 0 then
		-- Wrapping: a toast that needs more than one line at the minimum size is taller (its text box is TEXT_H of it).
		local lines, lineHeight = measureLines(text, TEXT_W * width * abs.X)
		if lines > 1 then
			minPx = lines * lineHeight / TEXT_H
		end
	end
	local height = heightScale(root, width, aspect, minPx)
	if abs.X > 0 and abs.Y > 0 then
		aspect = width * abs.X / (height * abs.Y) -- the aspect that gives exactly this height
	end

	-- A CanvasGroup so the whole pill (strokes included) fades with one GroupTransparency tween.
	local group = Instance.new("CanvasGroup")
	group.Name = if banner then "Banner" else "Toast"
	group.BackgroundTransparency = 1
	group.BorderSizePixel = 0
	group.AnchorPoint = Vector2.new(0.5, 0)
	group.Size = UDim2.fromScale(width, MAX_HEIGHT)
	group.Position = UDim2.fromScale(0.5, -height)
	group.ZIndex = 1
	Builder.aspect(group, aspect)
	group.Parent = root

	-- A toast is a dark pill with a coloured icon; a banner is the colour itself, edge to edge.
	local fill = if banner then accent else Theme.Colors.Trough
	local pill = Builder.pill({
		parent = group,
		name = "Pill",
		color = fill,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		zIndex = 1,
	})
	Builder.gradient(pill, fill)
	if banner then
		Builder.label({
			parent = pill,
			name = "Text",
			text = text,
			textSize = Theme.TextSize.Label,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(0.94, 0.72),
			anchor = Vector2.new(0.5, 0.5),
			zIndex = 2,
		})
	else
		local image: ImageLabel? = nil
		if iconKey then
			image = Builder.icon({
				parent = pill,
				name = "Icon",
				key = iconKey,
				position = UDim2.fromScale(ICON_X, 0.5),
				size = UDim2.fromScale(ICON_H / aspect, ICON_H),
				anchor = Vector2.new(0, 0.5),
				zIndex = 2,
			})
		end
		local textX = TEXT_X
		if image then
			textX = ICON_X + ICON_H / aspect + ICON_GAP
		else
			local icon = Builder.frame({
				parent = pill,
				name = "Icon",
				position = UDim2.fromScale(0.03, 0.5),
				size = UDim2.fromScale(0.12, 0.62),
				anchor = Vector2.new(0, 0.5),
				color = accent,
				corner = Theme.Corner.Card,
				stroke = Theme.Stroke.Text,
				aspect = 1,
				zIndex = 2,
			})
			Builder.gradient(icon, accent)
		end
		Builder.label({
			parent = pill,
			name = "Text",
			text = text,
			textSize = Theme.TextSize.Body,
			position = UDim2.fromScale(textX, 0.5),
			size = UDim2.fromScale(TEXT_X + TEXT_W - textX, TEXT_H),
			anchor = Vector2.new(0, 0.5),
			xAlign = Enum.TextXAlignment.Left,
			zIndex = 2,
		})
	end

	local entry: Entry = { group = group, leaving = false, height = height, item = item }
	table.insert(live, entry)
	local info = TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	if banner and panelOpen ~= nil and panelOpen() then
		-- A wide banner over an open panel hides its header: slide it up from the bottom edge instead,
		-- outside the stack (dismiss tolerates an entry the stack never held).
		group.Position = UDim2.fromScale(0.5, 1 + height)
		TweenService:Create(group, info, { Position = UDim2.fromScale(0.5, 1 - BANNER_BOTTOM_MARGIN - height) }):Play()
	else
		table.insert(entries, entry)
		TweenService:Create(group, info, { Position = slotPosition(#entries) }):Play()
	end
	task.delay(seconds, function()
		dismiss(entry)
	end)
end

-- True while the Reveal or a capture encounter (the Legendary opening included) owns the screen, or a timed quiet moment
-- (QuietFor) runs. The bootstrap supplies the Reveal and capture answer (it holds both states); without a probe only the
-- timed moment counts.
function Toast.Quiet(): boolean
	return os.clock() < quietUntil or (quietProbe ~= nil and quietProbe())
end

function Toast.SetQuietProbe(probe: (() -> boolean)?)
	quietProbe = probe
end

-- A presentation asks for `seconds` of calm from now (the longest ask stands): the assembly burst over a finished module
-- and the tap on an egg claim or purchase (Gifts, Peddler) are the callers. Held items drain once it ends.
function Toast.QuietFor(seconds: number)
	quietUntil = math.max(quietUntil, os.clock() + seconds)
end

local function draw(item: Held)
	if item.banner then
		Builder.playSound(Sounds.Banner)
	else
		Builder.playSound(Sounds.ToastDing)
	end
	push(item)
end

-- Shows the held items one per Config.ToastHoldGapSeconds once it is quiet; a quiet moment that starts again mid-drain
-- pauses it. One thread at a time; it ends when the queue is empty.
local function drain()
	if draining then
		return
	end
	draining = true
	task.spawn(function()
		while #held > 0 do
			if Toast.Quiet() then
				task.wait()
			else
				draw(table.remove(held, 1) :: Held)
				if #held > 0 then
					task.wait(Config.ToastHoldGapSeconds)
				end
			end
		end
		draining = false
	end)
end

-- Keeps at most Config.ToastHoldMax held toasts: the oldest go first. A banner is one per kind, so it never counts.
local function trimHeld()
	local toasts = 0
	for _, other in ipairs(held) do
		if not other.banner then
			toasts += 1
		end
	end
	local index = 1
	while toasts > Config.ToastHoldMax and index <= #held do
		if held[index].banner then
			index += 1
		else
			table.remove(held, index) -- the oldest held toast goes
			toasts -= 1
		end
	end
end

-- Draws now, or holds. Anything arriving behind a held item holds too, so the order never changes.
local function show(item: Held)
	if not Toast.Quiet() and #held == 0 then
		draw(item)
		return
	end
	if item.banner then
		-- One pending banner per kind: the latest replaces the older one.
		for index, other in ipairs(held) do
			if other.banner and other.kind == item.kind then
				table.remove(held, index)
				break
			end
		end
	end
	table.insert(held, item)
	trimHeld()
	drain()
end

-- A quiet moment is starting: every toast and banner on screen comes down at once (dismiss, so its fade is the usual short
-- one) and goes back to the front of the queue in its on-screen order with its full time, to replay through the drain after
-- the moment. One banner per kind still holds: a held banner is newer than any that was on screen, so it wins, and of two
-- on-screen banners of a kind the later one does. The bootstrap calls this as a catch begins and Reveal.Show as the card opens;
-- twice in a row, or with nothing live, it does nothing.
function Toast.Hush()
	if #live == 0 then
		return
	end
	local shown = table.clone(live) -- dismiss edits `live`
	for _, entry in ipairs(shown) do
		dismiss(entry)
	end
	local newer: { [string]: boolean } = {}
	for _, other in ipairs(held) do
		if other.banner then
			newer[other.kind] = true
		end
	end
	for index = #shown, 1, -1 do
		local item = shown[index].item
		if not (item.banner and newer[item.kind]) then
			if item.banner then
				newer[item.kind] = true
			end
			table.insert(held, 1, item) -- walking back to front, so the front ends up in on-screen order
		end
	end
	trimHeld()
	drain()
end

-- iconKey (an Icons key, e.g. a material or power-up id) swaps the coloured square for that icon when its
-- image is uploaded; without it, or while the id is 0, the toast is the plain one.
function Toast.Show(text: string, color: Color3?, iconKey: string?)
	show({ banner = false, kind = "", text = text, color = color or Theme.Colors.Featured, seconds = Theme.Tween.Toast, iconKey = iconKey })
end

-- Where the stack starts, in screen Scale; nil restores the default. Live toasts re-flow.
function Toast.SetTop(y: number?)
	local next = y or TOP_DEFAULT
	if next ~= top then
		top = next
		reflow()
	end
end

-- The bootstrap hands in Screens.IsAnyOpen so banners know when a panel owns the top of the screen.
function Toast.SetPanelProbe(probe: (() -> boolean)?)
	panelOpen = probe
end

-- Server-wide announcement: a wide banner in the given colour (usually the tier colour). While a panel
-- is open it takes the bottom slot so the panel's header stays readable. `kind` names what the banner is
-- ("announce", "peddler", "shower", "rush"): in a quiet moment a newer banner of the same kind replaces the one
-- waiting; without a kind the text is the kind, so only a repeat of the same line replaces.
function Toast.Banner(text: string, color: Color3, seconds: number?, kind: string?)
	show({ banner = true, kind = kind or text, text = text, color = color, seconds = seconds or Theme.Tween.Toast, iconKey = nil })
end

return Toast
