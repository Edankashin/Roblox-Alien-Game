--!strict
-- StarterPlayerScripts.Client.UI.TutorialHint: the first eight minutes, one line at a time, as the HUD's objective line. A dark
-- block plate with a gold ink joined under the ship bar in the goal plate (top centre, UI/Hud; the numbers are data/Hud Goal) holding
-- the current tutorial step's hint (data/Tutorial, a strings key) in white outlined text and, for a counted step, a small "2/3" chip
-- on the right. A new step pops the plate and turns its face gold for data/Hud Goal.StepPopSeconds, then back to the trough; a counter
-- tick pops the chip. The plate is as wide and as tall as the hint needs to hold whole at the 14 px floor (Shared/HudStages.Objective).
-- When the server says the tutorial is over (tutorialStep past the last step) the plate shows TUT_DONE for Theme.Tween.Toast seconds
-- and then hides for good. The hint also drives the world marker (World.Waypoint) from the step's waypoint kind: the nearest node of
-- the step's material, the trainee alien the server reserved for this player, the ship, or a biome's centre. Every target is
-- re-resolved on each read, so a collected node or a caught alien hands the marker to the next one.
-- Nothing here decides anything: the step and the counter are the server's (State.GetTutorial). It also tells the HUD and the compass
-- which step the player is on (Hud.SetStage, Compass.SetStage: the staged reveal, data/Tutorial HudStages).
-- The look is block cells (UI Playbook "Screens after the HUD", Decisions B44): the objective a dark block plate in cells at about
-- the HUD cell, the step counter a flat dark block.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Tutorial = require(Shared:WaitForChild("data"):WaitForChild("Tutorial"))
local HudData = require(Shared:WaitForChild("data"):WaitForChild("Hud"))
local HudStages = require(Shared:WaitForChild("HudStages"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Place = require(Shared:WaitForChild("Place"))
local Builder = require(script.Parent.Builder)
local Hud = require(script.Parent.Hud)
local Compass = require(script.Parent.Compass)
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))
local State = require(script.Parent.Parent.State)
local CampRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("CampRenderer"))
local Waypoint = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Waypoint"))

local TutorialHint = {}

local DISPLAY_ORDER = 15 -- over the HUD (10), under the modal screens (20)

-- Screen layout: the plate's place and size come from Shared/HudStages (GoalSlots, Objective) and data/Hud Goal; what is here is
-- what is inside the plate.
local CENTRE = 0.5
local TEXT_X = 0.04
local TEXT_H = 0.86 -- of the plate: the label fills it and the text scales to the lines it holds
local CHIP_RIGHT = 0.97
local CHIP_W = 0.2
local CHIP_H = 0.64
local CHIP_ASPECT = 2.2
local BAR_MIN_ASPECT = 4.2 -- the ship bar above is never narrower than a chip of its height (Hud's CHIP_ASPECT): the goal slots need it

local gui: ScreenGui? = nil
local pill: Frame? = nil
local hintLabel: TextLabel? = nil
local chip: Frame? = nil
local chipLabel: TextLabel? = nil
local wanted = true -- the bootstrap's SetVisible (captures and reveals hide the hint)
local shownStep: number? = nil -- the step the pill currently shows; nil while nothing shows
local shownCounter: number? = nil
local finished = false -- the done message has played (or the tutorial was already over on Start)
local doneGeneration = 0 -- a done message in flight; a later refresh retires it
local goldGeneration = 0 -- a gold face in flight; a newer step restarts it and an older one's return to the trough yields
local pushedStage: number? = nil -- the step last told to the HUD and the compass

-- Visibility ---------------------------------------------------------------

local function applyVisible()
	local root = gui
	if root then
		root.Enabled = wanted and not finished and shownStep ~= nil
	end
end

-- Waypoint targets -----------------------------------------------------------

local function floorTop(): number
	return Waypoint.FloorTop() or Place.Layout().FloorThickness / 2
end

local function nodePosition(materialId: string): Vector3?
	local part = Waypoint.FindNearestNode(materialId)
	return if part then part.Position else nil
end

local function spawnPosition(species: string): Vector3?
	local part = Waypoint.FindReservedSpawn(species)
	return if part then part.Position else nil
end

-- Points the marker at the step's target, or clears it for a step without one (and while hidden).
local function applyWaypoint(step: Tutorial.Step?)
	if not wanted or finished or not step or step.waypoint == "none" then
		Waypoint.Clear()
		return
	end
	local kind = step.waypoint
	if kind == "node" then
		local materialId = step.waypointTarget or ""
		Waypoint.Show(function()
			return nodePosition(materialId)
		end, Strings.WAYPOINT_node:format(Builder.text("MATERIAL_" .. materialId)))
	elseif kind == "spawn" then
		local species = if step.spawn then step.spawn.species else (step.trigger.species or "")
		local def = Species.ById[species]
		Waypoint.Show(function()
			return spawnPosition(species)
		end, Strings.WAYPOINT_spawn:format(if def then def.name else species))
	elseif kind == "ship" then
		Waypoint.Show(function()
			return CampRenderer.ShipPosition()
		end, Strings.WAYPOINT_ship)
	elseif kind == "biome" then
		local name = step.waypointTarget or ""
		local region = Place.Layout().Regions[name]
		if not region then
			Waypoint.Clear()
			return
		end
		Waypoint.Show(function()
			return Vector3.new(region.x, floorTop(), region.z)
		end, Strings.WAYPOINT_biome:format(Builder.text("BIOME_" .. name)))
	else
		Waypoint.Clear()
	end
end

-- Objective line ---------------------------------------------------------------------

-- The screen's size in pixels: the gui's (it ignores the inset, so it is the whole viewport), else the camera's.
local function screenSize(): Vector2
	local root = gui
	if root and root.AbsoluteSize.X > 0 and root.AbsoluteSize.Y > 0 then
		return root.AbsoluteSize
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(16, 9)
end

-- Sizes and places the plate for the hint it holds now: as many lines and as wide as the text needs to stay whole at the 14 px floor,
-- under the ship bar's slot (Shared/HudStages). Cheap, and called on every new line, every counter change and every resize.
local function layout()
	local frame, text, counterChip = pill, hintLabel, chip
	if not frame or not text or not counterChip then
		return
	end
	local screen = screenSize()
	local counted = counterChip.Visible
	local slots = HudStages.GoalSlots(screen.X, screen.Y, BAR_MIN_ASPECT)
	local goal = HudStages.Objective(utf8.len(text.Text) or #text.Text, counted, screen.X, screen.Y, Theme.TextSize.Min)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(CENTRE, slots.lineTop)
	frame.Size = UDim2.fromScale(goal.width, goal.height)
	local share = if counted then HudData.Goal.TextShareCounter else HudData.Goal.TextShare
	text.Position = UDim2.fromScale(TEXT_X, 0.5)
	text.Size = UDim2.fromScale(share - TEXT_X, TEXT_H)
end

local function build()
	if gui then
		return
	end
	local root = Builder.screen("Tutorial", DISPLAY_ORDER)
	root.Enabled = false
	gui = root

	-- A dark block plate with a gold ink in cells (UI Playbook "Screens after the HUD"), fitted to whatever box layout() gives it.
	local frame = Builder.blockPlate({
		parent = root,
		name = "Hint",
		color = Theme.Block.Trough,
		ink = Theme.Colors.Featured,
		position = UDim2.fromScale(CENTRE, HudData.Goal.Top + HudData.Goal.ShipHeight + HudData.Goal.LineGap),
		size = UDim2.fromScale(HudData.Goal.Width, HudData.Goal.LineHeight),
		anchor = Vector2.new(0.5, 0),
	})
	frame.Visible = false
	pill = frame
	local top = Builder.blockTop(frame)

	hintLabel = Builder.label({
		parent = frame,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(TEXT_X, 0.5),
		size = UDim2.fromScale(HudData.Goal.TextShare - TEXT_X, TEXT_H),
		anchor = Vector2.new(0, 0.5),
		zIndex = top,
	})

	local counter = Builder.blockPlate({
		parent = frame,
		name = "Progress",
		color = Builder.darker(Theme.Block.Trough),
		aspect = CHIP_ASPECT,
		rows = Theme.Block.MinRows,
		cells = false,
		position = UDim2.fromScale(CHIP_RIGHT, 0.5),
		size = UDim2.fromScale(CHIP_W, CHIP_H),
		anchor = Vector2.new(1, 0.5),
		zIndex = top,
	})
	counter.Visible = false
	chip = counter
	chipLabel = Builder.label({
		parent = counter,
		name = "Text",
		text = Strings.TUT_PROGRESS:format(0, 0),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromScale(0.86, 0.78),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = Builder.blockTop(counter),
	})
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
end

-- Fills the chip for a counted step (counter/count) or hides it; the layout then gives the text the room.
local function setProgress(step: Tutorial.Step?, counter: number)
	local counterChip, text, label = chip, hintLabel, chipLabel
	if not counterChip or not text or not label then
		return
	end
	local count = if step then step.trigger.count else nil
	if count and count > 0 then
		label.Text = Strings.TUT_PROGRESS:format(math.clamp(counter, 0, count), count)
		counterChip.Visible = true
	else
		counterChip.Visible = false
	end
	layout()
end

-- A new line: the plate scales in (Builder.open) and its face is gold for StepPopSeconds, then the dark trough again; the text pops.
-- Reduced Motion keeps the gold (it is the message, "something changed") and drops the scale and the pop.
local function present()
	local frame, text = pill, hintLabel
	if not frame or not text then
		return
	end
	goldGeneration += 1
	local mine = goldGeneration
	Builder.setBlockColor(frame, Theme.Colors.Featured)
	if not Prefs.ReducedMotion() then
		Builder.open(frame)
		Builder.pop(text, 1.15)
	else
		frame.Visible = true
	end
	task.delay(HudData.Goal.StepPopSeconds, function()
		if goldGeneration == mine then
			Builder.setBlockColor(frame, Theme.Block.Trough, TweenInfo.new(Theme.Tween.Open))
		end
	end)
end

local function showStep(step: Tutorial.Step, index: number, counter: number)
	local text = hintLabel
	if not text then
		return
	end
	doneGeneration += 1 -- a done message that was playing yields to a live step
	text.Text = Builder.text(step.hint)
	setProgress(step, counter)
	local stepChanged = shownStep ~= index
	shownStep = index
	shownCounter = counter
	applyVisible()
	if stepChanged then
		present()
		applyWaypoint(step)
	end
end

local function tickCounter(step: Tutorial.Step, counter: number)
	if shownCounter == counter then
		return
	end
	shownCounter = counter
	setProgress(step, counter)
	local counterChip = chip
	if counterChip and counterChip.Visible then
		Builder.pop(counterChip)
	end
end

-- The server said the tutorial is over: one closing line, then the pill retires.
local function showDone()
	local frame, text = pill, hintLabel
	if not frame or not text then
		finished = true
		applyVisible()
		return
	end
	Waypoint.Clear()
	doneGeneration += 1
	local mine = doneGeneration
	text.Text = Strings.TUT_DONE
	setProgress(nil, 0)
	shownStep = -1 -- "something shows" for applyVisible while the line is up
	shownCounter = nil
	applyVisible()
	present()
	task.delay(Theme.Tween.Toast, function()
		if doneGeneration ~= mine then
			return
		end
		Builder.close(frame, function()
			if doneGeneration == mine then
				finished = true
				shownStep = nil
				applyVisible()
			end
		end)
	end)
end

-- Tells the HUD and the compass which step the player is on (the staged reveal); only when it changed.
local function pushStage(index: number)
	if pushedStage == index then
		return
	end
	pushedStage = index
	Hud.SetStage(index)
	Compass.SetStage(index)
end

local function refresh()
	local index, counter = State.GetTutorial()
	pushStage(index)
	if finished then
		return
	end
	local step = Tutorial.Steps[index]
	if step then
		if shownStep == index then
			tickCounter(step, counter)
		else
			showStep(step, index, counter)
		end
	elseif index > #Tutorial.Steps then
		if shownStep ~= nil and shownStep > 0 then
			showDone()
		elseif shownStep == nil then
			-- Already over when the profile arrived (a returning player): nothing to say.
			finished = true
			Waypoint.Clear()
			applyVisible()
		end
	else
		-- A step index the data has no entry for: show nothing rather than guess.
		shownStep = nil
		shownCounter = nil
		Waypoint.Clear()
		applyVisible()
	end
end

-- Public API -------------------------------------------------------------

-- Builds the pill once, reads the current step, and follows the server's TutorialChanged pushes.
function TutorialHint.Start()
	if gui then
		return
	end
	build()
	State.OnChanged("tutorial", refresh)
	if State.Has() then
		refresh()
	end
end

-- The bootstrap hides the hint and its marker behind a catch or a reveal, and restores them after.
function TutorialHint.SetVisible(visible: boolean)
	if wanted == visible then
		return
	end
	wanted = visible
	applyVisible()
	if finished then
		return -- the marker is someone else's now (a radar blip); showDone cleared the tutorial's
	end
	local index = shownStep
	local step = if index then Tutorial.Steps[index] else nil
	applyWaypoint(step)
end

return TutorialHint
