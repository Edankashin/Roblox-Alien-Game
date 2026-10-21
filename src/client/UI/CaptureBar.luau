--!strict
-- StarterPlayerScripts.Client.UI.CaptureBar: the timing-bar minigame screen. Draws the zones the
-- server sent, animates the ticker with the shared Capture.position() from the server's startClock
-- (workspace:GetServerTimeNow() keeps both clocks aligned), and reports only the tap TIME. Every
-- outcome shown here came back from the server. A catch variant (data/CatchVariants) changes only what
-- is drawn and which input reports the time: the zones drift with the shared Capture.driftCenter() from
-- the server's driftPhase, the reel scores on the release of a hold, and the chase shows a countdown
-- and sends one last tap when it runs out so the server declares the loss.
-- The look is block cells (UI Playbook "Block cells", "The capture bar in block cells", Decisions B44): the trough a fitted dark
-- plate in cells; a trail of light that fills it cell by cell behind the sweep; the Good and Perfect zones lit bands under the
-- grout, so they read as cells, with their edges exactly where the server scores (never snapped to a cell); the marker a stepped
-- pixel arrow; the lure and countdown chips edged blocks; the sweep dots flat blocks. Timing, bindings and sounds as before.
-- The spectacle ladder (data/Spectacle Catch): a Good or Perfect the server scored flashes the zone bands in the alien's own colour
-- (BeginInfo.alienColor), more times up the tiers and once more on a Perfect (SpectacleMath.Flashes), each flash
-- Spectacle.Look.FlashPeriod long, so nothing flashes more than three times a second.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Capture = require(Shared:WaitForChild("Capture"))
local BlockMath = require(Shared:WaitForChild("BlockMath"))
local CatchVariants = require(Shared:WaitForChild("data"):WaitForChild("CatchVariants"))
local SpectacleData = require(Shared:WaitForChild("data"):WaitForChild("Spectacle"))
local SpectacleMath = require(Shared:WaitForChild("SpectacleMath"))
local Builder = require(script.Parent.Builder)

local CaptureBar = {}

export type BeginInfo = {
	speciesName: string,
	tierName: string,
	tierColor: Color3,
	tier: string?, -- the alien's tier (how many times a hit flashes); nil is Common
	alienColor: Color3?, -- the alien's own colour, which a hit flashes the zone in; nil: no flash
	params: Types.CaptureStartResult,
	onTap: (tapTime: number) -> (),
}

local ACTION_NAME = "CaptureTap"
local ROUND_INTRO_DELAY = 0.3 -- seconds the hit's own feedback (Perfect! / Good!) shows before the round intro replaces it
local ROUND_INTRO_SHAKE = 0.006 -- half the miss shake, in Scale: a nudge, not a rebuke
local TRAIL_ALPHA = 0.78 -- the trail of light behind the sweep: white at this transparency over the cells it has passed
-- The marker: a stepped pixel arrow pointing down at the bar, on a 7 by 11 grid of square pixels, a pixel being a sixth of the
-- bar's height. The head sits over the bar (rows 0 to 3), the stem runs through it (rows 4 to 9) and one ink pixel below.
-- Bars { x, y, w, h }: the ink (the colour dilated by one pixel all round, so the ink keeps one thickness round every step),
-- then the colour.
local ARROW_W, ARROW_H = 7, 11
local ARROW_UNIT = 1 / 6 -- a pixel, in bar heights
local ARROW_TOP = 4 -- rows of the arrow above the bar's top edge
local ARROW_INK = { { 0, 0, 7, 3 }, { 1, 3, 5, 1 }, { 2, 4, 3, 7 } }
local ARROW_FILL = { { 1, 1, 5, 1 }, { 2, 2, 3, 1 }, { 3, 3, 1, 7 } }

local gui: ScreenGui? = nil
local nameLabel: TextLabel? = nil
local tierLabel: TextLabel? = nil
local roundLabel: TextLabel? = nil
local feedback: TextLabel? = nil
local hint: TextLabel? = nil
local bar: Frame? = nil -- the trough, a fitted block plate
local goodZone: { Frame } = {} -- the Good band: four frames, the face's two bars cut either side of the Perfect band
local perfectZone: { Frame } = {}
local trail: { Frame } = {} -- the light behind the sweep, a whole cell at a time
local ticker: Frame? = nil -- the marker's holder
local tickerFill: { Frame } = {} -- the marker's colour bars (the variant's ticker colour)
local tickerPos = 0 -- where the marker stands, 0 to 1 along the bar
local trailShown = -1 -- the cell step the trail last drew
local lureChip: Frame? = nil
local lureLabel: TextLabel? = nil
local countdownChip: Frame? = nil
local countdownLabel: TextLabel? = nil
local dots: { Frame } = {}

local active = false
local awaiting = false -- a tap is in flight; ignore more until the server answers
local tickerSpeed = 1
local startClock = 0
local zoneCenter = 0.5 -- the centre the zones are drawn at right now
local baseCenter = 0.5 -- the sweep's rolled centre, before any drift
local goodWidth = 0.4
local perfectWidth = 0.12
local row: CatchVariants.Row = CatchVariants.Rows[CatchVariants.Default]
local driftPhase = 0
local deadline: number? = nil -- server clock the chase runs out at; nil without a time limit
local holding = false -- the reel's hold is down
local shownSeconds = -1 -- whole seconds the countdown chip last drew
local heldPos: number? = nil -- server-reported position shown while feedback plays
local heldCenter: number? = nil -- where the zone centre was at that tap; the zones sit here while feedback plays
local onTap: ((number) -> ())? = nil
local renderConn: RBXScriptConnection? = nil
local feedbackToken = 0
local alienColor: Color3? = nil
local alienTier = "Common"

local press: () -> () -- defined below; build() wires the backdrop to them
local release: () -> ()
local placeZones: (number) -> ()

local function build()
	if gui then
		return
	end
	local root = Builder.screen("CaptureBar", 20)
	root.Enabled = false
	gui = root

	-- Full-screen dim that also catches taps anywhere.
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Dim"
	backdrop.AutoButtonColor = false
	backdrop.Text = ""
	backdrop.BorderSizePixel = 0
	backdrop.Position = UDim2.fromScale(0, 0)
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 1 - Theme.Backdrop
	backdrop.ZIndex = 1
	backdrop.Parent = root
	backdrop.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			press()
		end
	end)
	backdrop.InputEnded:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			release()
		end
	end)

	nameLabel = Builder.label({
		parent = root,
		name = "Species",
		text = "",
		textSize = Theme.TextSize.Title,
		position = UDim2.fromScale(0.5, 0.64),
		size = UDim2.fromScale(0.6, 0.08),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	tierLabel = Builder.label({
		parent = root,
		name = "Tier",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(0.5, 0.705),
		size = UDim2.fromScale(0.4, 0.05),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	local feedbackLabel = Builder.label({
		parent = root,
		name = "Feedback",
		text = "",
		textSize = Theme.TextSize.Reveal,
		position = UDim2.fromScale(0.5, 0.52),
		size = UDim2.fromScale(0.6, 0.1),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 3,
	})
	feedbackLabel.Visible = false
	feedback = feedbackLabel

	-- The bar: a fitted dark plate in cells (the trough), the Good and Perfect bands under its grout, the trail of light over its
	-- cells, the marker over all. Every piece is placed from the plate's grid (Builder.blockGrid), again when the plate redraws.
	local trough = Builder.blockPlate({
		parent = root,
		name = "Bar",
		color = Theme.Block.Trough,
		position = UDim2.fromScale(0.5, 0.8),
		size = UDim2.fromScale(0.6, 0.06),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	bar = trough
	local layers = Theme.Block.Layer
	local function band(name: string, color: Color3, z: number, transparency: number): { Frame }
		local frames: { Frame } = {}
		for index = 1, 2 do
			local frame = Builder.frame({
				parent = trough,
				name = name,
				color = color,
				transparency = transparency,
				size = UDim2.fromScale(0, 0),
				zIndex = z,
			})
			frames[index] = frame
		end
		return frames
	end
	-- Under the grout (the Bar layer), so a band reads as lit cells. The Good band is two pieces, either side of the Perfect band,
	-- so no two bands overlap on the one layer (siblings at one ZIndex have no order to rely on).
	goodZone = band("Good", Theme.Colors.Confirm, trough.ZIndex + layers.Bar, 0)
	for _, frame in ipairs(band("Good", Theme.Colors.Confirm, trough.ZIndex + layers.Bar, 0)) do
		table.insert(goodZone, frame)
	end
	perfectZone = band("Perfect", Theme.Colors.Featured, trough.ZIndex + layers.Bar, 0)
	trail = band("Trail", Theme.Colors.White, Builder.blockTop(trough), TRAIL_ALPHA)
	local top = Builder.blockTop(trough) + 1
	local marker = Builder.frame({
		parent = trough,
		name = "Ticker",
		position = UDim2.fromScale(0, -ARROW_TOP * ARROW_UNIT),
		size = UDim2.fromScale(1, ARROW_H * ARROW_UNIT),
		anchor = Vector2.new(0.5, 0),
		aspect = ARROW_W / ARROW_H,
		zIndex = top,
	})
	tickerFill = {}
	for layer, bars in ipairs({ ARROW_INK, ARROW_FILL }) do
		for _, rect in ipairs(bars) do
			local piece = Builder.frame({
				parent = marker,
				name = if layer == 1 then "Ink" else "Fill",
				position = UDim2.fromScale(rect[1] / ARROW_W, rect[2] / ARROW_H),
				size = UDim2.fromScale(rect[3] / ARROW_W, rect[4] / ARROW_H),
				color = if layer == 1 then Theme.Colors.Outline else Theme.Colors.White,
				zIndex = top + layer,
			})
			if layer == 2 then
				table.insert(tickerFill, piece)
			end
		end
	end
	ticker = marker
	Builder.onBlockRedraw(trough, function()
		trailShown = -1
		placeZones(zoneCenter)
	end)

	-- Lure chip above the bar's left end, in the clear column beside the centred tier label. Shown only
	-- for an encounter the server says consumed a lure. An edged block (a transient: eight frames).
	local chip = Builder.blockPlate({
		parent = root,
		name = "Lure",
		color = Theme.Colors.Select,
		cells = false,
		edges = true,
		position = UDim2.fromScale(0.2, 0.74),
		size = UDim2.fromScale(0.2, 0.05),
		anchor = Vector2.new(0, 0.5),
		zIndex = 2,
	})
	chip.Visible = false
	lureChip = chip
	lureLabel = Builder.label({
		parent = chip,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(chip),
	})

	-- Chase clock above the bar's right end, mirroring the lure chip. Shown only for an encounter with a deadline.
	local timer = Builder.blockPlate({
		parent = root,
		name = "Countdown",
		color = Theme.Block.Trough,
		cells = false,
		edges = true,
		position = UDim2.fromScale(0.8, 0.74),
		size = UDim2.fromScale(0.2, 0.05),
		anchor = Vector2.new(1, 0.5),
		zIndex = 2,
	})
	timer.Visible = false
	countdownChip = timer
	countdownLabel = Builder.label({
		parent = timer,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.75),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(timer),
	})

	-- Sweeps left as three square flat blocks under the bar.
	local dotRow = Builder.frame({
		parent = root,
		name = "Sweeps",
		position = UDim2.fromScale(0.5, 0.87),
		size = UDim2.fromScale(0.12, 0.03),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.08, 0)
	layout.Parent = dotRow
	dots = {}
	for i = 1, Config.CaptureSweepsPerEncounter do
		local dot = Builder.blockPlate({
			parent = dotRow,
			name = "Dot" .. i,
			color = Theme.Colors.White,
			size = UDim2.fromScale(0.2, 1),
			aspect = 1,
			rows = Theme.Block.MinRows,
			cells = false,
			zIndex = 2,
		})
		dot.LayoutOrder = i
		table.insert(dots, dot)
	end

	roundLabel = Builder.label({
		parent = root,
		name = "Round",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.915),
		size = UDim2.fromScale(0.3, 0.04),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Heading,
		strokeColor = Theme.Colors.Black,
		zIndex = 2,
	})
	hint = Builder.label({
		parent = root,
		name = "Hint",
		text = Strings.CATCH_TAP_HINT,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.96),
		size = UDim2.fromScale(0.3, 0.04),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 2,
	})
end

-- Puts `frames` (a band's two bars) over `left` to `left + width` of the bar, cut to the trough's face.
local function placeBand(frames: { Frame }, grid: BlockMath.Grid, left: number, width: number, first: number?)
	local from = (first or 1) - 1
	for index, rect in ipairs(BlockMath.Span(grid, left, width)) do
		local frame = frames[from + index]
		if frame then
			frame.Position = UDim2.fromScale(rect.x, rect.y)
			frame.Size = UDim2.fromScale(rect.w, rect.h)
			frame.Visible = rect.w > 0
		end
	end
end

-- Moves the marker to `pos` along the bar and lets the trail catch up a whole cell at a time (redrawn only when it steps).
local function placeTicker(pos: number)
	tickerPos = pos
	local plate, marker = bar, ticker
	local grid = if plate then Builder.blockGrid(plate) else nil
	if not grid or not marker then
		return
	end
	marker.Position = UDim2.fromScale(BlockMath.Along(grid, pos), -ARROW_TOP * ARROW_UNIT)
	local step = BlockMath.CellStep(grid.cols, pos)
	if step ~= trailShown then
		trailShown = step
		placeBand(trail, grid, 0, step)
	end
end

-- Draw both zones centred on `center` at their current widths (the widths never drift, only the centre), exactly where the
-- server scores them, on the trough's face.
placeZones = function(center: number)
	zoneCenter = center
	local plate = bar
	local grid = if plate then Builder.blockGrid(plate) else nil
	if not grid then
		return
	end
	local goodLeft, goodSpan = Capture.zoneSpan(center, goodWidth)
	local perfectLeft, perfectSpan = Capture.zoneSpan(center, perfectWidth)
	placeBand(perfectZone, grid, perfectLeft, perfectSpan)
	-- The Good band either side of the Perfect one: together they cover exactly the Good span.
	placeBand(goodZone, grid, goodLeft, math.max(0, perfectLeft - goodLeft), 1)
	local perfectRight = perfectLeft + perfectSpan
	placeBand(goodZone, grid, perfectRight, math.max(0, goodLeft + goodSpan - perfectRight), 3)
	placeTicker(tickerPos)
end

local function setZones(center: number, good: number, perfect: number)
	baseCenter = center
	goodWidth = good
	perfectWidth = perfect
	placeZones(center)
end

-- Where the variant's drift has the zone centre at server time `now` (the rolled centre when it is still).
local function centerAt(now: number): number
	if row.driftAmplitude <= 0 then
		return baseCenter
	end
	return Capture.driftCenter(now - startClock, baseCenter, row.driftAmplitude, row.driftPeriodSeconds, driftPhase, row.driftClampMin, row.driftClampMax)
end

-- The hint under the bar: the row's own, or the hold hint while the reel's hold is down.
local function setHolding(on: boolean)
	holding = on
	local label = hint
	if label then
		local holdKey = row.holdHintKey
		label.Text = Builder.text(if on and holdKey ~= nil then holdKey else row.hintKey)
	end
end

local function setSweeps(left: number)
	for i, dot in ipairs(dots) do
		Builder.setBlockColor(dot, if i <= left then Theme.Colors.White else Theme.Block.Trough)
	end
end

local function setRound(round: number, total: number)
	if roundLabel then
		roundLabel.Text = if total > 1 then Strings.CATCH_ROUND:format(round, total) else ""
	end
end

local function showFeedback(text: string, color: Color3)
	local label = feedback
	if not label then
		return
	end
	feedbackToken += 1
	local token = feedbackToken
	label.Text = text
	label.TextColor3 = color
	label.Visible = true
	Builder.pop(label, 1.4)
	task.delay(0.7, function()
		if feedbackToken == token and label then
			label.Visible = false
		end
	end)
end

local function flashZone()
	local info = TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 2, true)
	for _, frame in ipairs(goodZone) do
		TweenService:Create(frame, info, { BackgroundColor3 = Theme.Colors.White }):Play()
	end
end

-- A scored hit flashes the zone bands in the alien's colour (a Perfect the Perfect band too): SpectacleMath.Flashes times, each one
-- out and back over Spectacle.Look.FlashPeriod; the bands end on their own colour.
local function flashAlien(hit: Types.HitOutcome?)
	local color = alienColor
	local count = SpectacleMath.Flashes(alienTier, hit)
	if not color or count <= 0 then
		return
	end
	local info = TweenInfo.new(SpectacleData.Look.FlashPeriod / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, count - 1, true)
	for _, frame in ipairs(goodZone) do
		TweenService:Create(frame, info, { BackgroundColor3 = color }):Play()
	end
	if hit == "Perfect" then
		local bright = color:Lerp(Theme.Colors.White, 0.4)
		for _, frame in ipairs(perfectZone) do
			TweenService:Create(frame, info, { BackgroundColor3 = bright }):Play()
		end
	end
end

local function tap()
	if not active or awaiting or not onTap then
		return
	end
	local tapTime = workspace:GetServerTimeNow()
	if tapTime < startClock then
		return -- the next sweep has not started yet; not a miss, just ignored
	end
	awaiting = true
	heldPos = Capture.position(tapTime - startClock, tickerSpeed)
	heldCenter = centerAt(tapTime)
	onTap(tapTime)
end

-- A press scores at once on tap control; on the reel it starts the hold and the release scores.
function press()
	if not active then
		return
	end
	if row.control ~= "release" then
		tap()
		return
	end
	if awaiting or holding then
		return
	end
	setHolding(true)
	if ticker then
		Builder.pop(ticker)
	end
end

-- The release is the reel's tap: tap() stamps the release time, so the server judges when the player let go.
function release()
	if not holding then
		return
	end
	setHolding(false)
	tap()
end

-- Redraw the countdown chip from the server clock; red and a pop each second for the last few.
local function updateCountdown(now: number)
	local limit = deadline
	local label = countdownLabel
	if limit == nil or not label then
		return
	end
	local left = math.max(0, math.ceil(limit - now))
	if left == shownSeconds then
		return
	end
	shownSeconds = left
	label.Text = Strings.CATCH_TIME_LEFT:format(left)
	if left <= CatchVariants.CountdownUrgentSeconds then
		label.TextColor3 = Theme.Colors.Close
		Builder.pop(label)
	else
		label.TextColor3 = Theme.Colors.White
	end
end

local function onRender()
	local t = ticker
	if not t then
		return
	end
	local now = workspace:GetServerTimeNow()
	local held = heldPos
	local pos: number = if held ~= nil then held else Capture.position(now - startClock, tickerSpeed)
	placeTicker(pos)
	local center = centerAt(now)
	if row.driftAmplitude > 0 then
		-- While a tap's feedback shows, the zones stay where that tap was scored.
		placeZones(if held ~= nil then heldCenter or zoneCenter else center)
	end
	updateCountdown(now)

	-- The chase ran out: freeze the bar where it is and send one last tap a beat later; the server declares the loss.
	local limit = deadline
	if limit ~= nil and now >= limit and active and not awaiting then
		awaiting = true
		heldPos = pos
		heldCenter = center
		local send = onTap
		task.delay(CatchVariants.DeadlineTapDelaySeconds, function()
			if active and send ~= nil and onTap == send then
				send(workspace:GetServerTimeNow())
			end
		end)
	end
end

local function bindInput()
	ContextActionService:BindAction(ACTION_NAME, function(_name: string, state: Enum.UserInputState, _input: InputObject)
		if state == Enum.UserInputState.Begin then
			press()
		elseif state == Enum.UserInputState.End then
			release()
		elseif state == Enum.UserInputState.Cancel then
			setHolding(false) -- the hold was interrupted (focus lost): drop it without scoring
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

local function unbindInput()
	ContextActionService:UnbindAction(ACTION_NAME)
end

-- Public API -------------------------------------------------------------


function CaptureBar.Begin(info: BeginInfo)
	build()
	local root = gui
	if not root then
		return
	end
	local params = info.params
	active = true
	awaiting = false
	heldPos = nil
	heldCenter = nil
	onTap = info.onTap
	tickerSpeed = params.tickerSpeed
	startClock = params.startClock
	row = CatchVariants.Rows[params.variant] or CatchVariants.Rows[CatchVariants.Default]
	driftPhase = params.driftPhase
	deadline = params.deadline
	alienColor = info.alienColor
	alienTier = info.tier or "Common"
	setZones(params.zoneCenter, params.goodZone, params.perfectZone)
	for _, frame in ipairs(goodZone) do
		frame.BackgroundColor3 = Theme.Colors[row.look.zone] or Theme.Colors.Confirm
	end
	for _, frame in ipairs(tickerFill) do
		frame.BackgroundColor3 = Theme.Colors[row.look.ticker] or Theme.Colors.White
	end
	placeTicker(0)
	setSweeps(params.sweepsLeft)
	setRound(params.round, params.roundsTotal)
	if nameLabel then
		nameLabel.Text = info.speciesName
	end
	if tierLabel then
		tierLabel.Text = info.tierName
		tierLabel.TextColor3 = info.tierColor
	end
	if feedback then
		feedback.Visible = false
		feedback.Text = "" -- a stale "Good!" from the last catch must not read as this one's
	end
	if hint then
		hint.Visible = true
	end
	setHolding(false)
	shownSeconds = -1
	local timer, timerLabel = countdownChip, countdownLabel
	if timer and timerLabel then
		timer.Visible = params.deadline ~= nil
		timerLabel.TextColor3 = Theme.Colors.White
		if params.deadline ~= nil then
			updateCountdown(workspace:GetServerTimeNow())
			Builder.pop(timer)
		end
	end
	local chip, chipLabel = lureChip, lureLabel
	if chip and chipLabel then
		local lure = params.lure
		chip.Visible = lure ~= nil
		if lure then
			chipLabel.Text = Strings.CATCH_LURE_USED:format(Builder.text("LURE_" .. lure))
			Builder.pop(chip)
		end
	end
	root.Enabled = true
	if bar then
		Builder.open(bar)
	end
	Builder.playSound(Sounds.BarOpen) -- once per catch: the bar's later rounds re-arm through ApplyResult, not Begin
	-- The variant's name lands as the bar opens ("Cast!", "Chase!").
	local nameKey = row.nameKey
	if nameKey ~= nil then
		task.delay(Theme.Tween.Open, function()
			if active then
				showFeedback(Builder.text(nameKey), Theme.Colors.Featured)
			end
		end)
	end
	bindInput()
	if renderConn then
		renderConn:Disconnect()
	end
	renderConn = RunService.RenderStepped:Connect(onRender)
end

-- Show the server's verdict and, for continued sweeps, re-arm the bar for the next one.
function CaptureBar.ApplyResult(result: Types.CaptureHitResult)
	if not active then
		return
	end
	setHolding(false)
	if result.pos ~= nil and result.pos >= 0 then
		heldPos = result.pos
	end
	if result.zoneAt ~= nil then
		heldCenter = result.zoneAt
	end
	local hit = result.hit
	if result.outcome == "Fled" then
		-- A chase whose clock ran out bolted; any other flight is the usual escape.
		local limit = deadline
		local bolted = limit ~= nil and workspace:GetServerTimeNow() >= limit
		showFeedback(if bolted then Strings.CATCH_BOLTED else Strings.CATCH_ESCAPED, Theme.Colors.Close)
		Builder.playSound(Sounds.Fled)
		return
	end
	if hit == "Perfect" or hit == "Good" then
		flashAlien(hit)
	end
	if hit == "Perfect" then
		showFeedback(Strings.CATCH_PERFECT, Theme.Colors.Featured)
		Builder.playSound(Sounds.Perfect)
	elseif hit == "Good" then
		if result.outcome == "Wiggle" then
			showFeedback(Strings.CATCH_WIGGLE, Theme.Colors.Select)
			Builder.playSound(Sounds.Wiggle)
		else
			showFeedback(Strings.CATCH_GOOD, Theme.Colors.Confirm)
			Builder.playSound(Sounds.CatchHit)
		end
	else
		local pos = result.pos
		local near = false
		if pos ~= nil and pos >= 0 then
			near = Capture.isNearMiss(pos, heldCenter or zoneCenter, goodWidth, Config.CaptureNearMissWidth)
		end
		showFeedback(if near then Strings.CATCH_NEAR_MISS else Strings.CATCH_MISS, Theme.Colors.Close)
		Builder.playSound(Sounds.Miss)
		if near then
			flashZone()
		end
		if bar then
			Builder.shake(bar)
		end
	end
	if result.outcome == "Caught" then
		return
	end

	-- A won round of a multi-round catch: after the hit lands, name the next round and nudge the bar
	-- before its sweep starts (the server waits CaptureSweepLeadSeconds, so the intro fits in between).
	if result.outcome == "Round" and result.round then
		local nextRound = result.round
		task.delay(ROUND_INTRO_DELAY, function()
			if not active then
				return
			end
			showFeedback(Strings.CATCH_ROUND_INTRO:format(nextRound), Theme.Colors.Featured)
			if bar then
				Builder.shake(bar, ROUND_INTRO_SHAKE)
			end
		end)
	end

	-- continued sweeps: new zone (new round) or same zone, ticker restarts at nextStartClock
	if result.zoneCenter and result.goodZone and result.perfectZone then
		setZones(result.zoneCenter, result.goodZone, result.perfectZone)
	end
	if result.driftPhase ~= nil then
		driftPhase = result.driftPhase
	end
	if result.sweepsLeft then
		setSweeps(result.sweepsLeft)
	end
	if result.round and result.roundsTotal then
		setRound(result.round, result.roundsTotal)
	end
	if result.nextStartClock then
		startClock = result.nextStartClock
	end
	local wait = math.max(0, startClock - workspace:GetServerTimeNow())
	task.delay(wait, function()
		if active then
			heldPos = nil
			heldCenter = nil
			awaiting = false
		end
	end)
end

function CaptureBar.End()
	if not active then
		return
	end
	active = false
	awaiting = false
	deadline = nil
	setHolding(false)
	onTap = nil
	unbindInput()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	if lureChip then
		lureChip.Visible = false
	end
	if countdownChip then
		countdownChip.Visible = false
	end
	local root = gui
	if bar and root then
		Builder.close(bar, function()
			if not active then
				root.Enabled = false
			end
		end)
	elseif root then
		root.Enabled = false
	end
end

return CaptureBar
