--!strict
-- StarterPlayerScripts.Client.UI.CaptureBar: the timing-bar minigame screen. Draws the zones the
-- server sent, animates the ticker with the shared Capture.position() from the server's startClock
-- (workspace:GetServerTimeNow() keeps both clocks aligned), and reports only the tap TIME. Every
-- outcome shown here came back from the server. A catch variant (data/CatchVariants) changes only what
-- is drawn and which input reports the time: the zones drift with the shared Capture.driftCenter() from
-- the server's driftPhase, the reel scores on the release of a hold, and the chase shows a countdown
-- and sends one last tap when it runs out so the server declares the loss.

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
local CatchVariants = require(Shared:WaitForChild("data"):WaitForChild("CatchVariants"))
local Builder = require(script.Parent.Builder)

local CaptureBar = {}

export type BeginInfo = {
	speciesName: string,
	tierName: string,
	tierColor: Color3,
	params: Types.CaptureStartResult,
	onTap: (tapTime: number) -> (),
}

local ACTION_NAME = "CaptureTap"
local ROUND_INTRO_DELAY = 0.3 -- seconds the hit's own feedback (Perfect! / Good!) shows before the round intro replaces it
local ROUND_INTRO_SHAKE = 0.006 -- half the miss shake, in Scale: a nudge, not a rebuke

local gui: ScreenGui? = nil
local nameLabel: TextLabel? = nil
local tierLabel: TextLabel? = nil
local roundLabel: TextLabel? = nil
local feedback: TextLabel? = nil
local hint: TextLabel? = nil
local bar: Frame? = nil
local goodZone: Frame? = nil
local perfectZone: Frame? = nil
local ticker: Frame? = nil
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

local press: () -> () -- defined below; build() wires the backdrop to them
local release: () -> ()

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

	-- The bar: dark trough pill, Good and Perfect zones, the ticker on top.
	local trough = Builder.pill({
		parent = root,
		name = "Bar",
		position = UDim2.fromScale(0.5, 0.8),
		size = UDim2.fromScale(0.6, 0.06),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Panel,
		strokeColor = Theme.Colors.Outline,
		zIndex = 2,
	})
	bar = trough
	goodZone = Builder.frame({
		parent = trough,
		name = "Good",
		position = UDim2.fromScale(0.3, 0),
		size = UDim2.fromScale(0.4, 1),
		color = Theme.Colors.Confirm,
		corner = Theme.Corner.Card,
		zIndex = 3,
	})
	perfectZone = Builder.frame({
		parent = trough,
		name = "Perfect",
		position = UDim2.fromScale(0.44, 0),
		size = UDim2.fromScale(0.12, 1),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Card,
		zIndex = 4,
	})
	ticker = Builder.frame({
		parent = trough,
		name = "Ticker",
		position = UDim2.fromScale(0, 0.5),
		size = UDim2.fromScale(0.012, 1.5),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 5,
	})

	-- Lure chip above the bar's left end, in the clear column beside the centred tier label. Shown only
	-- for an encounter the server says consumed a lure.
	local chip = Builder.pill({
		parent = root,
		name = "Lure",
		position = UDim2.fromScale(0.2, 0.74),
		size = UDim2.fromScale(0.2, 0.05),
		anchor = Vector2.new(0, 0.5),
		color = Theme.Colors.Select,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		zIndex = 2,
	})
	Builder.gradient(chip, Theme.Colors.Select)
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
		zIndex = 3,
	})

	-- Chase clock above the bar's right end, mirroring the lure chip. Shown only for an encounter with a deadline.
	local timer = Builder.pill({
		parent = root,
		name = "Countdown",
		position = UDim2.fromScale(0.8, 0.74),
		size = UDim2.fromScale(0.2, 0.05),
		anchor = Vector2.new(1, 0.5),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
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
		zIndex = 3,
	})

	-- Sweeps left as three dots under the bar.
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
	layout.Padding = UDim.new(0.08, 0)
	layout.Parent = dotRow
	dots = {}
	for i = 1, Config.CaptureSweepsPerEncounter do
		local dot = Builder.pill({
			parent = dotRow,
			name = "Dot" .. i,
			size = UDim2.fromScale(0.2, 1),
			color = Theme.Colors.White,
			stroke = Theme.Stroke.Text,
			aspect = 1,
			zIndex = 2,
		})
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

-- Draw both zones centred on `center` at their current widths (the widths never drift, only the centre).
local function placeZones(center: number)
	zoneCenter = center
	if goodZone then
		local left, width = Capture.zoneSpan(center, goodWidth)
		goodZone.Position = UDim2.fromScale(left, 0)
		goodZone.Size = UDim2.fromScale(width, 1)
	end
	if perfectZone then
		local left, width = Capture.zoneSpan(center, perfectWidth)
		perfectZone.Position = UDim2.fromScale(left, 0)
		perfectZone.Size = UDim2.fromScale(width, 1)
	end
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
		dot.BackgroundColor3 = if i <= left then Theme.Colors.White else Theme.Colors.Trough
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
	local zone = goodZone
	if not zone then
		return
	end
	local info = TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 2, true)
	TweenService:Create(zone, info, { BackgroundColor3 = Theme.Colors.White }):Play()
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
	t.Position = UDim2.fromScale(pos, 0.5)
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
	setZones(params.zoneCenter, params.goodZone, params.perfectZone)
	if goodZone then
		goodZone.BackgroundColor3 = Theme.Colors[row.look.zone] or Theme.Colors.Confirm
	end
	if ticker then
		ticker.BackgroundColor3 = Theme.Colors[row.look.ticker] or Theme.Colors.White
	end
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
