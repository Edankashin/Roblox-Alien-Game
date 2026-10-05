--!strict
-- StarterPlayerScripts.Client.UI.StarChartScreen: the Star Chart, opened from the Ship panel. A drawn
-- orbit map on the left (about 60% of the panel) and the selected world's card on the right:
--   map      a gold star with a soft glow, one thin ring per world (data/Worlds order), and one planet on
--            each ring at a fixed angle (PLANET_ANGLES). A planet's look says its state:
--              current world   Confirm green, a gold ring that pulses (Config.StarChartPulseSeconds; held
--                              still under Reduced Motion)
--              unlocked        Select blue, navy ring, lit; an outpost adds a "Lv 2" chip under the planet
--                              and, while it has production ready (OutpostMath.Pending against os.time()),
--                              a Confirm dot on the planet's corner
--              next stop       the first locked world after the highest unlocked one: dim fill, gold ring
--              locked          faint Trough grey
--            Tapping a planet (its invisible, larger TextButton) selects it: its ring turns thick. Opening
--            selects the current world.
--   card     the selected world's name and what the old list card said, line for line:
--              current world   "You are here"; no buttons.
--              unlocked, with an outpost   its level, its output per hour, what it has ready (refreshed
--                              every Config.StarChartTickSeconds while open), and Collect, Upgrade and Fly.
--              unlocked, no outpost   Fly only.
--              locked          a dimmed card reading Locked, or "Next stop" for the next world.
-- Every tap asks the server (CollectOutpost, UpgradeOutpost, FlyTo; one request in flight) and toasts
-- the answer; the buttons only dim to hint what a tap would do, they never block it, so the server's
-- reason always reaches the player. The mirror (State: "world", "scrap", "profile") is all the screen
-- reads; OutpostsChanged, ScrapChanged and WorldChanged keep it current. Nothing here decides anything.
-- Both loops stop when the screen closes: the pulse tween is cancelled and the tick thread is
-- task.cancel'ed in Close. Selecting a world restarts the pulse so its swing is measured from the
-- planet's new resting thickness (a selected current planet rests thicker than an unselected one).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Net = require(Shared:WaitForChild("Net"))
local OutpostMath = require(Shared:WaitForChild("OutpostMath"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Builder)
local Toast = require(script.Parent.Toast)
local State = require(script.Parent.Parent.State)
local Prefs = require(script.Parent.Parent.Prefs)

local StarChartScreen = {}

-- One world's planet and the pieces refresh rewrites.
type Planet = {
	worldId: number,
	disc: Frame,
	stroke: UIStroke,
	chip: Frame, -- "Lv 2", under the planet; only for an outpost
	chipText: TextLabel,
	dot: Frame, -- production is ready; on the planet's top right corner
}

-- The selected world's card and the pieces refresh rewrites.
type Detail = {
	frame: Frame,
	stroke: UIStroke,
	name: TextLabel,
	level: TextLabel, -- "Outpost Lv 2"
	line: TextLabel, -- the status line, or the outpost's output per hour
	pending: TextLabel,
	collect: Frame,
	upgrade: Frame,
	fly: Frame,
}

-- Panel layout, as fractions of the panel. The header tab straddles the top edge and the close button
-- reaches down to 0.155, so the map and the card start under it. The panel is wider than the other
-- screens' (1.75 against 1.35) so the card has room for two buttons side by side.
local PANEL_W = 0.84
local PANEL_H = 0.78
local PANEL_ASPECT = 1.75
local BODY_Y = 0.17
local BODY_H = 0.8
local MAP_CX = 0.31 -- centre of the left ~60%
local MAP_W = 0.58
local CARD_X = 0.62
local CARD_W = 0.36

-- The map, as fractions of the map square. The square is as tall as BODY_H and as wide, whichever of
-- MAP_W and BODY_H is smaller (an aspect constraint), so a planet is PLANET of that: about 28 px at
-- iPhone SE (234 px square) and 47 px on a 4:3 tablet, both above 5% of the screen height.
local STAR = 0.12
local GLOW = 0.22
local PLANET = 0.12
local HIT = 0.2 -- the invisible tap area around a planet; the planets sit at least 0.23 apart
local RING_FIRST = 0.33 -- ring diameters run evenly from the first world's to the last's
local RING_LAST = 0.84
local CHIP_W = 0.19
local CHIP_H = 0.08
local CHIP_GAP = 0.01
local DOT = 0.42 -- of the planet disc

-- Where each world's planet sits on its ring: degrees clockwise from east. Chosen so that no two planets
-- or "Lv" chips touch even when every outpost shows one (a layout constant, not a game number).
local PLANET_ANGLES: { [number]: number } = { 165, 350, 70, 230, 115, 155, 315 }
local FALLBACK_ANGLE_STEP = 137.5 -- a world past the table spirals on the golden angle

-- Strokes (px) and colours.
local RING_STROKE = 2
local RING_TRANSPARENCY = 0.75
local STROKE_LIT = Theme.Stroke.Button
local STROKE_LOCKED = Theme.Stroke.Text
local STROKE_CURRENT = Theme.Stroke.Panel
local STROKE_SELECTED = Theme.Stroke.Panel * 1.5 -- a selected planet's ring, whatever its state
local PULSE_SWELL = Theme.Stroke.Panel * 0.5 -- the pulsing ring swells this far past its rest thickness
local NEXT_FILL_TRANSPARENCY = 0.75
local LOCKED_FILL_TRANSPARENCY = 0.7
local LOCKED_STROKE_TRANSPARENCY = 0.55
local LOCKED_TRANSPARENCY = 0.45 -- the locked card's fill

-- Inside the card, as fractions of the card.
local TEXT_X = 0.05
local TEXT_W = 0.9
local NAME_Y = 0.03
local NAME_H = 0.165
local LEVEL_Y = 0.2
local LEVEL_H = 0.075
local LINE_Y = 0.285
local LINE_H = 0.145
local PENDING_Y = 0.44
local PENDING_H = 0.145
local ROW_ONE_Y = 0.6
local ROW_TWO_Y = 0.79
local BUTTON_H = 0.17
local COLLECT_W = 0.43
local UPGRADE_X = 0.52

local COLLECT_COLOR = Theme.Colors.Featured
local UPGRADE_COLOR = Theme.Colors.Confirm
local FLY_COLOR = Theme.Colors.Select
local DIM_COLOR = Theme.Rarity.Common

local gui: ScreenGui? = nil
local panel: Frame? = nil
local planets: { Planet } = {}
local detail: Detail? = nil
local selected = 1 -- the world id the card shows; Open resets it to the current world
local open = false
local busy = false -- one request in flight at a time
local pulseTween: Tween? = nil
local pulsePlanet: Planet? = nil
local tickThread: thread? = nil

-- Helpers ----------------------------------------------------------------

-- Recolours a Builder.button in place (lip, face, thick stroke, gradient).
local function recolorButton(container: Frame, color: Color3)
	local dark = Builder.darker(color)
	local lip = container:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = dark
	end
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.BackgroundColor3 = color
		for _, child in ipairs(face:GetChildren()) do
			if child:IsA("UIStroke") and child.Thickness == Theme.Stroke.Button then
				child.Color = dark
			elseif child:IsA("UIGradient") then
				child.Color = ColorSequence.new(Builder.lighter(color), color)
			end
		end
	end
end

local function setButton(container: Frame, text: string, color: Color3)
	recolorButton(container, color)
	local face = container:FindFirstChild("Face")
	if face and face:IsA("TextButton") then
		face.Text = text
	end
end

-- The world's name from the strings table (WORLD_<id>), or the Worlds row, or the key itself.
local function worldName(worldId: number): string
	local key = "WORLD_" .. tostring(worldId)
	local text = Builder.text(key)
	if text ~= key then
		return text
	end
	local def = Worlds[worldId]
	return if def then def.name else key
end

local function outpostOf(profile: Types.Profile, worldId: number): Types.OutpostState?
	local outposts: { [string]: Types.OutpostState }? = profile.world.outposts -- a mirror older than the field reads as none
	return if outposts then outposts[tostring(worldId)] else nil
end

-- "Lv 2": the last two words of the existing "Outpost Lv 2" line, so the chip needs no string of its own.
-- (A language that writes the level without a space keeps the whole line.)
local function levelChip(level: number): string
	return Strings.STARCHART_LEVEL_CHIP:format(level)
end

-- The ring diameter for a world, as a fraction of the map square.
local function ringDiameter(worldId: number): number
	local last = math.max(#Worlds, 2) - 1
	return RING_FIRST + (RING_LAST - RING_FIRST) * (worldId - 1) / last
end

-- A planet's centre on the map square (0..1 on each axis).
local function planetCenter(worldId: number): (number, number)
	local radius = ringDiameter(worldId) / 2
	local angle = math.rad(PLANET_ANGLES[worldId] or worldId * FALLBACK_ANGLE_STEP)
	return 0.5 + radius * math.cos(angle), 0.5 + radius * math.sin(angle)
end

-- The pulse -----------------------------------------------------------------

-- The current planet's resting ring: gold, thicker while it is the selected one.
local function restThickness(planet: Planet): number
	return if planet.worldId == selected then STROKE_SELECTED else STROKE_CURRENT
end

local function restStroke(planet: Planet)
	planet.stroke.Color = Theme.Colors.Featured
	planet.stroke.Transparency = 0
	planet.stroke.Thickness = restThickness(planet)
end

-- Cancels the pulse and puts the planet's ring back to rest.
local function stopPulse()
	local tween, planet = pulseTween, pulsePlanet
	pulseTween = nil
	pulsePlanet = nil
	if tween then
		tween:Cancel()
		tween:Destroy()
	end
	if planet then
		restStroke(planet)
	end
end

-- Starts the pulse on `planet` (the current world); a planet already pulsing is left alone. Under
-- Reduced Motion the ring holds still at rest.
local function startPulse(planet: Planet)
	if pulsePlanet == planet and (pulseTween ~= nil or Prefs.ReducedMotion()) then
		return
	end
	stopPulse()
	pulsePlanet = planet
	restStroke(planet)
	if Prefs.ReducedMotion() then
		return
	end
	local half = math.max(Config.StarChartPulseSeconds / 2, 0.05)
	local tween = TweenService:Create(
		planet.stroke,
		TweenInfo.new(half, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Thickness = restThickness(planet) + PULSE_SWELL }
	)
	pulseTween = tween
	tween:Play()
end

-- Refresh ----------------------------------------------------------------

local function showOnly(card: Detail, collect: boolean, upgrade: boolean, fly: boolean)
	card.collect.Visible = collect
	card.upgrade.Visible = upgrade
	card.fly.Visible = fly
end

-- Paints a planet that is not the current one. `thickness` is the state's resting ring; the selected
-- planet's ring is STROKE_SELECTED instead.
local function paintPlanet(
	planet: Planet,
	fill: Color3,
	fillTransparency: number,
	ring: Color3,
	ringTransparency: number,
	thickness: number
)
	planet.disc.BackgroundColor3 = fill
	planet.disc.BackgroundTransparency = fillTransparency
	planet.stroke.Color = ring
	planet.stroke.Transparency = ringTransparency
	planet.stroke.Thickness = if planet.worldId == selected then STROKE_SELECTED else thickness
end

local function refreshPlanet(planet: Planet, profile: Types.Profile, unlocked: { [number]: boolean }, highest: number, now: number)
	local id = planet.worldId
	planet.chip.Visible = false
	planet.dot.Visible = false

	if id == profile.world.current then
		-- here: green, a gold ring that pulses; the ring is the tween's, so it is not touched here
		planet.disc.BackgroundColor3 = Theme.Colors.Confirm
		planet.disc.BackgroundTransparency = 0
		startPulse(planet)
		return
	end
	if pulsePlanet == planet then
		stopPulse()
	end

	if not unlocked[id] then
		if id == highest + 1 then
			-- the next stop: dim fill, gold ring
			paintPlanet(planet, Theme.Colors.Featured, NEXT_FILL_TRANSPARENCY, Theme.Colors.Featured, 0, STROKE_LIT)
		else
			-- locked: faint
			paintPlanet(planet, Theme.Colors.Trough, LOCKED_FILL_TRANSPARENCY, Theme.Colors.Trough, LOCKED_STROKE_TRANSPARENCY, STROKE_LOCKED)
		end
		return
	end

	-- unlocked: lit; an outpost adds its chip, and a dot while it has something ready
	paintPlanet(planet, Theme.Colors.Select, 0, Theme.Colors.Outline, 0, STROKE_LIT)
	local state = outpostOf(profile, id)
	if state then
		planet.chipText.Text = levelChip(state.level)
		planet.chip.Visible = true
		local ready = OutpostMath.Pending(state, id, now)
		planet.dot.Visible = ready.scrap > 0 or ready.materialCount > 0
	end
end

-- The card for the selected world: the old list card's states, line for line.
local function refreshDetail(profile: Types.Profile, unlocked: { [number]: boolean }, highest: number, now: number)
	local card = detail
	if not card then
		return
	end
	local id = selected
	card.name.Text = worldName(id)
	card.level.Visible = false
	card.pending.Visible = false
	card.frame.BackgroundTransparency = 0
	card.frame.BackgroundColor3 = Theme.Colors.White

	if id == profile.world.current then
		-- (a) here: gold, no buttons
		card.stroke.Color = Theme.Colors.Featured
		card.stroke.Thickness = Theme.Stroke.Panel
		card.line.Text = Strings.STARCHART_HERE
		card.line.TextColor3 = Theme.Colors.Heading
		showOnly(card, false, false, false)
		return
	end
	card.line.TextColor3 = Theme.Colors.White

	if not unlocked[id] then
		-- (d) locked: dimmed; the next one on the chart says what opens it
		card.line.Text = if id == highest + 1 then Strings.STARCHART_NEXT else Strings.STARCHART_LOCKED
		card.frame.BackgroundColor3 = DIM_COLOR
		card.frame.BackgroundTransparency = LOCKED_TRANSPARENCY
		card.stroke.Color = DIM_COLOR
		card.stroke.Thickness = Theme.Stroke.Text
		showOnly(card, false, false, false)
		return
	end

	card.stroke.Color = Theme.Colors.Select
	card.stroke.Thickness = Theme.Stroke.Button
	local state = outpostOf(profile, id)
	if not state then
		-- (c) unlocked, no outpost: Fly alone
		card.line.Text = ""
		setButton(card.fly, Strings.STARCHART_FLY, FLY_COLOR)
		showOnly(card, false, false, true)
		return
	end

	-- (b) unlocked, with an outpost
	local rates = OutpostMath.Level(state.level)
	local ready = OutpostMath.Pending(state, id, now)
	card.level.Text = Strings.STARCHART_OUTPOST:format(state.level)
	card.level.Visible = true
	card.line.Text = Strings.STARCHART_OUTPUT:format(rates.scrapPerHour, rates.materialsPerHour)
	card.pending.Text = Strings.STARCHART_PENDING:format(ready.scrap, ready.materialCount)
	card.pending.Visible = true

	local nothing = ready.scrap <= 0 and ready.materialCount <= 0
	setButton(card.collect, Strings.STARCHART_COLLECT, if nothing then DIM_COLOR else COLLECT_COLOR)
	local cost = OutpostMath.UpgradeCost(state.level)
	if cost == nil then
		setButton(card.upgrade, Strings.STARCHART_MAXED, DIM_COLOR)
	else
		setButton(card.upgrade, Strings.STARCHART_UPGRADE:format(cost), if profile.scrap < cost then DIM_COLOR else UPGRADE_COLOR)
	end
	setButton(card.fly, Strings.STARCHART_FLY, FLY_COLOR)
	showOnly(card, true, true, true)
end

local function refresh()
	if not open or not State.Has() then
		return
	end
	local profile = State.Get()
	local unlocked: { [number]: boolean } = {}
	local highest = 0
	for _, id in ipairs(profile.world.unlocked) do
		unlocked[id] = true
		highest = math.max(highest, id)
	end
	unlocked[profile.world.current] = true
	highest = math.max(highest, profile.world.current)
	local now = os.time()
	for _, planet in ipairs(planets) do
		refreshPlanet(planet, profile, unlocked, highest, now)
	end
	refreshDetail(profile, unlocked, highest, now)
end

-- Shows `worldId` on the card and thickens its planet's ring. The pulse restarts so its swing is measured
-- from the new resting thickness (stopPulse reads `selected`, so it is set first).
local function selectWorld(worldId: number)
	if worldId == selected then
		return
	end
	selected = worldId
	stopPulse()
	refresh()
end

-- The tick -------------------------------------------------------------------

local function stopTick()
	local thread = tickThread
	tickThread = nil
	if thread and coroutine.status(thread) ~= "dead" then
		task.cancel(thread)
	end
end

-- Redraws every Config.StarChartTickSeconds so the ready amounts count up (and the dots appear) while the
-- chart is open.
local function startTick()
	stopTick()
	tickThread = task.spawn(function()
		while open do
			task.wait(Config.StarChartTickSeconds)
			if not open then
				break
			end
			refresh()
		end
	end)
end

-- Server calls -------------------------------------------------------------

-- Runs `work` as the one request in flight (taps meanwhile are ignored), then redraws.
local function request(work: () -> ())
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		work()
		busy = false
		refresh()
	end)
end

local function invoke(name: string, worldId: number): (boolean, string?, any, any)
	local success, ok, reason, a, b = pcall(function()
		return Net.func(name):InvokeServer(worldId)
	end)
	if not success then
		print(("[%s] %s failed: %s"):format(Config.WorkingTitle, name, tostring(ok)))
		return false, "Error", nil, nil
	end
	return ok == true, if type(reason) == "string" then reason else nil, a, b
end

local function onCollect(worldId: number)
	request(function()
		local ok, reason, scrap, count = invoke("CollectOutpost", worldId)
		if ok then
			local gotScrap = if type(scrap) == "number" then scrap else 0
			local gotCount = if type(count) == "number" then count else 0
			Toast.Show(Strings.TOAST_OUTPOST_COLLECTED:format(gotScrap, gotCount), Theme.Colors.Confirm)
		elseif reason == "Nothing" then
			Toast.Show(Strings.TOAST_OUTPOST_NOTHING, Theme.Colors.Select)
		elseif reason == "TooSoon" then
			Toast.Show(Strings.TOAST_OUTPOST_TOO_SOON, Theme.Colors.Select)
		elseif reason ~= "RateLimited" then
			print(("[%s] CollectOutpost refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

local function onUpgrade(worldId: number)
	request(function()
		-- What the tap was asking for, read before the answer: the OutpostsChanged push may land first.
		local profile = if State.Has() then State.Get() else nil
		local state = if profile then outpostOf(profile, worldId) else nil
		local level = if state then state.level else 1
		local ok, reason = invoke("UpgradeOutpost", worldId)
		if ok then
			Toast.Show(Strings.TOAST_OUTPOST_UPGRADED:format(math.min(level + 1, OutpostMath.MaxLevel())), Theme.Colors.Confirm)
		elseif reason == "NotEnoughScrap" then
			Toast.Show(Strings.TOAST_OUTPOST_NOT_ENOUGH:format(OutpostMath.UpgradeCost(level) or 0), Theme.Colors.Close)
		elseif reason == "Maxed" then
			Toast.Show(Strings.TOAST_OUTPOST_MAXED, Theme.Colors.Featured)
		elseif reason ~= "RateLimited" then
			print(("[%s] UpgradeOutpost refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- On ok nothing happens here: the Flew event closes the screens and plays the fade.
local function onFly(worldId: number)
	request(function()
		local ok, reason = invoke("FlyTo", worldId)
		if ok then
			return
		elseif reason == "Locked" then
			Toast.Show(Strings.TOAST_FLY_LOCKED:format(worldName(worldId)), Theme.Colors.Close)
		elseif reason == "Busy" then
			Toast.Show(Strings.TOAST_FLY_BUSY, Theme.Colors.Select)
		elseif reason ~= "RateLimited" then
			print(("[%s] FlyTo refused: %s"):format(Config.WorkingTitle, tostring(reason)))
		end
	end)
end

-- Build ----------------------------------------------------------------------

-- One world's planet: a disc with its number, a chip and a dot that refresh shows or hides, and the
-- invisible tap area over the top.
local function buildPlanet(map: Frame, worldId: number): Planet
	local cx, cy = planetCenter(worldId)
	local disc = Builder.frame({
		parent = map,
		name = "Planet_" .. worldId,
		position = UDim2.fromScale(cx, cy),
		size = UDim2.fromScale(PLANET, PLANET),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Select,
		corner = Theme.Corner.Pill,
		stroke = STROKE_LIT,
		strokeColor = Theme.Colors.Outline,
		zIndex = 5,
	})
	local stroke = disc:FindFirstChildOfClass("UIStroke") :: UIStroke
	Builder.label({
		parent = disc,
		name = "Id", -- the world's number
		text = tostring(worldId),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.8, 0.8),
		anchor = Vector2.new(0.5, 0.5),
		stroke = 2,
		zIndex = 6,
	})
	local dot = Builder.frame({
		parent = disc,
		name = "Ready",
		position = UDim2.fromScale(0.9, 0.12),
		size = UDim2.fromScale(DOT, DOT),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Confirm,
		corner = Theme.Corner.Pill,
		stroke = 2,
		strokeColor = Theme.Colors.Outline,
		zIndex = 7,
	})
	dot.Visible = false
	local chip = Builder.pill({
		parent = map,
		name = "Chip_" .. worldId,
		position = UDim2.fromScale(cx, cy + PLANET / 2 + CHIP_GAP),
		size = UDim2.fromScale(CHIP_W, CHIP_H),
		anchor = Vector2.new(0.5, 0),
		color = Theme.Colors.Trough,
		zIndex = 5,
	})
	chip.Visible = false
	local chipText = Builder.label({
		parent = chip,
		name = "Level",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.92, 0.9),
		anchor = Vector2.new(0.5, 0.5),
		stroke = 0, -- the chip is navy already; an outline would only blur the text
		zIndex = 6,
	})

	local hit = Instance.new("TextButton")
	hit.Name = "Hit_" .. worldId
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AnchorPoint = Vector2.new(0.5, 0.5)
	hit.Position = UDim2.fromScale(cx, cy)
	hit.Size = UDim2.fromScale(HIT, HIT)
	hit.ZIndex = 9
	hit.Parent = map
	hit.Activated:Connect(function()
		Builder.playSound(Sounds.Click)
		selectWorld(worldId)
	end)

	return {
		worldId = worldId,
		disc = disc,
		stroke = stroke,
		chip = chip,
		chipText = chipText,
		dot = dot,
	}
end

-- The orbit map: a square on the left, the star and its glow in the middle, a ring and a planet per world.
local function buildMap(body: Frame)
	local map = Builder.frame({
		parent = body,
		name = "Map",
		position = UDim2.fromScale(MAP_CX, BODY_Y + BODY_H / 2),
		size = UDim2.fromScale(MAP_W, BODY_H),
		anchor = Vector2.new(0.5, 0.5),
		aspect = 1,
		zIndex = 3,
	})
	for id = 1, #Worlds do
		local diameter = ringDiameter(id)
		local ring = Builder.frame({
			parent = map,
			name = "Ring_" .. id,
			position = UDim2.fromScale(0.5, 0.5),
			size = UDim2.fromScale(diameter, diameter),
			anchor = Vector2.new(0.5, 0.5),
			corner = Theme.Corner.Pill,
			stroke = RING_STROKE,
			strokeColor = Theme.Colors.Outline,
			zIndex = 3,
		})
		local ringStroke = ring:FindFirstChildOfClass("UIStroke")
		if ringStroke then
			ringStroke.Transparency = RING_TRANSPARENCY
		end
	end
	Builder.frame({
		parent = map,
		name = "Glow",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(GLOW, GLOW),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		transparency = 0.75,
		corner = Theme.Corner.Pill,
		zIndex = 4,
	})
	Builder.frame({
		parent = map,
		name = "Star",
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(STAR, STAR),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.Colors.Featured,
		corner = Theme.Corner.Pill,
		stroke = STROKE_LIT,
		strokeColor = Theme.Colors.Outline,
		zIndex = 4,
	})
	planets = {}
	for id = 1, #Worlds do
		table.insert(planets, buildPlanet(map, id))
	end
end

-- The card on the right: every piece is built once; refresh decides which show and what they say.
local function buildDetail(body: Frame)
	local frame = Builder.frame({
		parent = body,
		name = "Card",
		position = UDim2.fromScale(CARD_X, BODY_Y),
		size = UDim2.fromScale(CARD_W, BODY_H),
		color = Theme.Colors.White,
		corner = Theme.Corner.Card,
		stroke = Theme.Stroke.Button,
		strokeColor = DIM_COLOR,
		zIndex = 3,
	})
	local stroke = frame:FindFirstChildOfClass("UIStroke") :: UIStroke
	local name = Builder.label({
		parent = frame,
		name = "Name",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(TEXT_X, NAME_Y),
		size = UDim2.fromScale(TEXT_W, NAME_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local level = Builder.label({
		parent = frame,
		name = "Level",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(TEXT_X, LEVEL_Y),
		size = UDim2.fromScale(TEXT_W, LEVEL_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local line = Builder.label({
		parent = frame,
		name = "Line",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(TEXT_X, LINE_Y),
		size = UDim2.fromScale(TEXT_W, LINE_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local pending = Builder.label({
		parent = frame,
		name = "Pending",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(TEXT_X, PENDING_Y),
		size = UDim2.fromScale(TEXT_W, PENDING_H),
		xAlign = Enum.TextXAlignment.Left,
		zIndex = 4,
	})
	local collect = Builder.button({
		parent = frame,
		name = "Collect",
		text = Strings.STARCHART_COLLECT,
		color = COLLECT_COLOR,
		position = UDim2.fromScale(TEXT_X, ROW_ONE_Y),
		size = UDim2.fromScale(COLLECT_W, BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		onCollect(selected)
	end)
	local upgrade = Builder.button({
		parent = frame,
		name = "Upgrade",
		text = Strings.STARCHART_UPGRADE,
		color = UPGRADE_COLOR,
		position = UDim2.fromScale(UPGRADE_X, ROW_ONE_Y),
		size = UDim2.fromScale(COLLECT_W, BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		onUpgrade(selected)
	end)
	local fly = Builder.button({
		parent = frame,
		name = "Fly",
		text = Strings.STARCHART_FLY,
		color = FLY_COLOR,
		position = UDim2.fromScale(TEXT_X, ROW_TWO_Y),
		size = UDim2.fromScale(TEXT_W, BUTTON_H),
		textSize = Theme.TextSize.Body,
		zIndex = 4,
	}, function()
		onFly(selected)
	end)
	detail = {
		frame = frame,
		stroke = stroke,
		name = name,
		level = level,
		line = line,
		pending = pending,
		collect = collect,
		upgrade = upgrade,
		fly = fly,
	}
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("StarChartScreen", 20)
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
		StarChartScreen.Close()
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
		size = UDim2.fromScale(0.33, 0.11),
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
		text = Strings.STARCHART_TITLE,
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
		StarChartScreen.Close()
	end)

	buildMap(body)
	buildDetail(body)

	-- Server pushes: redraw whenever the mirror changes (cheap while closed: refresh returns early).
	for _, topic in ipairs({ "world", "scrap", "outposts" }) do
		State.OnChanged(topic :: State.Topic, refresh)
	end
	-- Reduced Motion turned on or off while open: restart the pulse the new way.
	Prefs.OnChanged(function()
		if open then
			stopPulse()
			refresh()
		end
	end)
end

-- Public API -------------------------------------------------------------

function StarChartScreen.IsOpen(): boolean
	return open
end

-- Opens with the current world selected.
function StarChartScreen.Open()
	build()
	local root, body = gui, panel
	if open or not root or not body then
		return
	end
	open = true
	if State.Has() then
		selected = State.Get().world.current
	end
	stopPulse() -- the ring rests for the new selection before the pulse starts again
	refresh()
	startTick()
	root.Enabled = true
	Builder.open(body)
end

-- Stops the pulse tween and the tick thread before the close tween runs, so nothing keeps redrawing
-- (or tweening a stroke) behind a hidden screen.
function StarChartScreen.Close()
	if not open then
		return
	end
	open = false
	stopTick()
	stopPulse()
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

function StarChartScreen.Toggle()
	if open then
		StarChartScreen.Close()
	else
		StarChartScreen.Open()
	end
end

return StarChartScreen
