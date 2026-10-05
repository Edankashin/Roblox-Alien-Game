--!strict
-- StarterPlayerScripts.Client.UI.TutorialHint: the first eight minutes, one line at a time. A wide
-- Featured-coloured pill bottom centre, above the power-up bar, with the current tutorial step's hint
-- (data/Tutorial.luau, a strings key) in white outlined text and, for a counted step, a small
-- "2/3" chip on the right. A new step slides the pill in and pops the text; a counter tick pops the
-- chip. When the server says the tutorial is over (tutorialStep past the last step) the pill shows
-- TUT_DONE for Theme.Tween.Toast seconds and then hides for good. The pill also drives the world
-- marker (World.Waypoint) from the step's waypoint kind: the nearest node of the step's material, the
-- trainee alien the server reserved for this player, the ship, or a biome's centre. Every target is
-- re-resolved on each read, so a collected node or a caught alien hands the marker to the next one.
-- Nothing here decides anything: the step and the counter are the server's (State.GetTutorial).

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Tutorial = require(Shared:WaitForChild("data"):WaitForChild("Tutorial"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Meadow = require(Shared:WaitForChild("data"):WaitForChild("Meadow"))
local Builder = require(script.Parent.Builder)
local State = require(script.Parent.Parent.State)
local CampRenderer = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("CampRenderer"))
local Waypoint = require(script.Parent.Parent:WaitForChild("World"):WaitForChild("Waypoint"))

local TutorialHint = {}

local DISPLAY_ORDER = 15 -- over the HUD (10), under the modal screens (20)

-- Screen layout. The pill's bottom edge sits above the power-up bar (whose top is near y 0.805) and
-- between the chat window (bottom-left) and the action button (bottom-right).
local CENTRE = 0.5
local BOTTOM = 0.79
local WIDTH = 0.5
local HEIGHT = 0.12 -- generous cap so the width stays the binding side of the aspect fit
local ASPECT = 8
local SLIDE = 0.05 -- a new step rises this much of the screen into place
local TEXT_X = 0.04
local TEXT_H = 0.72
local TEXT_W_FULL = 0.92 -- no chip
local TEXT_W_WITH_CHIP = 0.72
local CHIP_RIGHT = 0.97
local CHIP_W = 0.2
local CHIP_H = 0.64
local CHIP_ASPECT = 2.2

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

-- Visibility ---------------------------------------------------------------

local function applyVisible()
	local root = gui
	if root then
		root.Enabled = wanted and not finished and shownStep ~= nil
	end
end

-- Waypoint targets -----------------------------------------------------------

local function floorTop(): number
	return Waypoint.FloorTop() or Meadow.FloorThickness / 2
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
		local region = Meadow.Regions[name]
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

-- Pill ---------------------------------------------------------------------------

local function build()
	if gui then
		return
	end
	local root = Builder.screen("Tutorial", DISPLAY_ORDER)
	root.Enabled = false
	gui = root

	local frame = Builder.pill({
		parent = root,
		name = "Hint",
		position = UDim2.fromScale(CENTRE, BOTTOM),
		size = UDim2.fromScale(WIDTH, HEIGHT),
		anchor = Vector2.new(0.5, 1),
		color = Theme.Colors.Featured,
		stroke = Theme.Stroke.Button,
		strokeColor = Theme.Colors.Outline,
		aspect = ASPECT,
	})
	Builder.gradient(frame, Theme.Colors.Featured)
	frame.Visible = false
	pill = frame

	hintLabel = Builder.label({
		parent = frame,
		name = "Text",
		text = "",
		textSize = Theme.TextSize.Label,
		position = UDim2.fromScale(TEXT_X, 0.5),
		size = UDim2.fromScale(TEXT_W_FULL, TEXT_H),
		anchor = Vector2.new(0, 0.5),
		zIndex = 2,
	})

	local counter = Builder.pill({
		parent = frame,
		name = "Progress",
		position = UDim2.fromScale(CHIP_RIGHT, 0.5),
		size = UDim2.fromScale(CHIP_W, CHIP_H),
		anchor = Vector2.new(1, 0.5),
		color = Theme.Colors.Trough,
		stroke = Theme.Stroke.Text,
		strokeColor = Theme.Colors.Outline,
		aspect = CHIP_ASPECT,
		zIndex = 3,
	})
	Builder.gradient(counter, Theme.Colors.Trough)
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
		zIndex = 4,
	})
end

-- Fills the chip for a counted step (counter/count) or hides it, widening the text to the full pill.
local function setProgress(step: Tutorial.Step?, counter: number)
	local counterChip, text, label = chip, hintLabel, chipLabel
	if not counterChip or not text or not label then
		return
	end
	local count = if step then step.trigger.count else nil
	if count and count > 0 then
		label.Text = Strings.TUT_PROGRESS:format(math.clamp(counter, 0, count), count)
		counterChip.Visible = true
		text.Size = UDim2.fromScale(TEXT_W_WITH_CHIP, TEXT_H)
	else
		counterChip.Visible = false
		text.Size = UDim2.fromScale(TEXT_W_FULL, TEXT_H)
	end
end

-- Slides the pill up into place and scales it in (Builder.open), popping the text for the new line.
local function present()
	local frame, text = pill, hintLabel
	if not frame or not text then
		return
	end
	frame.Position = UDim2.fromScale(CENTRE, BOTTOM + SLIDE)
	Builder.open(frame)
	TweenService:Create(
		frame,
		TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(CENTRE, BOTTOM) }
	):Play()
	Builder.pop(text, 1.15)
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

local function refresh()
	if finished then
		return
	end
	local index, counter = State.GetTutorial()
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
