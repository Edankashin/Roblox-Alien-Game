--!strict
-- Shared.HudStages: the arithmetic of the quiet HUD (docs/vault/05-ui-design/Clean-UI-Pass.md, package A). Which HUD elements a new
-- player has earned (the staged reveal: data/Tutorial HudStages), which of the three event sources owns the one event chip, the
-- chip's one line, how tall a plate is on a short screen, the top-right stack, and how big the objective line must be to hold a
-- hint whole at the 14 px floor. Pure numbers and strings, no Roblox types: tests/HudStages.spec.luau runs it headless, including
-- iPhone SE (667 by 375) and an iPad. UI/Hud, UI/TutorialHint and UI/Compass place the results with Scale only.

local HudData = require(script.Parent.data.Hud)
local Tutorial = require(script.Parent.data.Tutorial)

local HudStages = {}

-- ---------------------------------------------------------------------------
-- The staged reveal
-- ---------------------------------------------------------------------------

-- Whether `element` shows for a player at tutorial step `stepIndex` (the server's tutorialStep: 1 for a fresh profile, past the last
-- step once the tutorial is over; `done` says so). `stages` maps an element to the id of the step it waits for ("T0": no wait), and
-- `ids` lists the steps' ids in order: an element shows once its step is complete, i.e. when the player is past it. An element with no
-- stage, or one whose step id is unknown, always shows: a typo in the data never hides the HUD.
function HudStages.ShownWith(stages: { [string]: string }, ids: { string }, element: string, stepIndex: number, done: boolean): boolean
	if done then
		return true
	end
	local waitsFor = stages[element]
	if waitsFor == nil or waitsFor == "T0" then
		return true
	end
	for index, id in ipairs(ids) do
		if id == waitsFor then
			return stepIndex > index
		end
	end
	return true
end

local stepIds: { string } = {}
for _, step in ipairs(Tutorial.Steps) do
	table.insert(stepIds, step.id)
end

-- ShownWith on the game's data (data/Tutorial HudStages and Steps).
function HudStages.Shown(element: string, stepIndex: number, done: boolean): boolean
	return HudStages.ShownWith(Tutorial.HudStages, stepIds, element, stepIndex, done)
end

-- Whether a tutorial step index is past the last step.
function HudStages.IsDone(stepIndex: number): boolean
	return stepIndex > #Tutorial.Steps
end

-- ---------------------------------------------------------------------------
-- The event chip
-- ---------------------------------------------------------------------------

export type EventSlot = "banner" | "countdown" | "luck"

-- Which of the sources the one chip shows, highest first: a Rush or a Shower that is running now (the "banner" the bootstrap feeds
-- Hud.SetEventBanner with `bannerLive` true), a countdown to a Rush or a shower (the player can join in seconds), then the banner of a
-- standing state (server luck, the seasonal or the weekly event: it lasts minutes to days, so an imminent Rush outranks it, the Mac's
-- job 65 finding), then luck that is not x1.0. Nothing when none holds: the chip is gone, not dimmed. The countdown is only ever fed
-- inside its warning window, so it never hides a state for long.
function HudStages.EventSlot(hasBanner: boolean, bannerLive: boolean, hasCountdown: boolean, luckShown: boolean): EventSlot?
	if hasBanner and bannerLive then
		return "banner"
	elseif hasCountdown then
		return "countdown"
	elseif hasBanner then
		return "banner"
	elseif luckShown then
		return "luck"
	end
	return nil
end

local MIDDLE_DOT = "\u{B7}"

-- The chip's one line from the banner's two: the name (without a closing "!") and the time left, e.g. "Meteor Shower" and
-- "4m 12s left" make "4m 12s". `leftSuffix` is the translated " left" the subtitle ends with, `format` the line's "%s %s". A subtitle
-- with a middle dot ("Zapfinch · 3d 4h left") keeps what is after the last dot. No subtitle: the name alone.
function HudStages.EventLine(name: string, subtitle: string?, leftSuffix: string, format: string): string
	local title = name
	if string.sub(title, -1) == "!" then
		title = string.sub(title, 1, -2)
	end
	if subtitle == nil or subtitle == "" then
		return title
	end
	local time = subtitle
	local from = 1
	while true do
		local found, last = string.find(time, MIDDLE_DOT, from, true)
		if not found or not last then
			break
		end
		from = last + 1
	end
	time = string.sub(time, from)
	if leftSuffix ~= "" and string.sub(time, -#leftSuffix) == leftSuffix then
		time = string.sub(time, 1, -#leftSuffix - 1)
	end
	time = (string.gsub(time, "^%s+", ""))
	time = (string.gsub(time, "%s+$", ""))
	if time == "" then
		return title
	end
	return string.format(format, title, time)
end

-- ---------------------------------------------------------------------------
-- Layout
-- ---------------------------------------------------------------------------

-- A fraction of the screen's size, but never fewer than `minPx` pixels on a screen `screenPx` tall (or wide).
function HudStages.AtLeast(frac: number, minPx: number, screenPx: number): number
	if screenPx <= 0 then
		return frac
	end
	return math.max(frac, minPx / screenPx)
end

-- The tops of a stack of plates: the first at `top`, each next `gap` under the one before, a plate not shown taking no room. `heights`
-- and `shown` are in the stack's order; the answer has one top per plate (a hidden plate's is where it would stand).
function HudStages.Stack(top: number, gap: number, heights: { number }, shown: { boolean }): { number }
	local tops: { number } = {}
	local at = top
	for index, height in ipairs(heights) do
		tops[index] = at
		if shown[index] then
			at += height + gap
		end
	end
	return tops
end

export type GoalSlots = {
	shipWidth: number, -- of the screen's width
	shipHeight: number, -- of the screen's height
	lineTop: number, -- the objective line's top, under the bar
}

-- The goal plate's slots on a `screenW` by `screenH` screen: the ship bar's width and height (taller on a short screen, so its
-- 14 px line holds; never narrower than `minAspect` times its height, so "Ship 100%" fits) and where the objective line starts.
function HudStages.GoalSlots(screenW: number, screenH: number, minAspect: number): GoalSlots
	local goal = HudData.Goal
	local height = HudStages.AtLeast(goal.ShipHeight, goal.MinHeightPx, screenH)
	local width = goal.Width
	if screenW > 0 and screenH > 0 then
		width = math.max(width, height * screenH * minAspect / screenW)
	end
	return { shipWidth = width, shipHeight = height, lineTop = goal.Top + height + goal.LineGap }
end

export type Objective = {
	width: number, -- of the screen's width
	height: number, -- of the screen's height
	lines: number,
}

-- How big the objective line is for a hint of `chars` letters (with `counter`, the "1/3" chip that takes room from the text) so the
-- text holds whole at `floorPx` (the 14 px floor): the smallest number of lines that fits the bar's width, else the fewest that fit by
-- widening the plate up to its maximum, else the most lines allowed at the maximum width. The height is the lines' own, never under the
-- bar's. An estimate (a letter is CharEm ems wide, WrapSlack for the words that wrap early); the Studio check judges the rest.
function HudStages.Objective(chars: number, counter: boolean, screenW: number, screenH: number, floorPx: number): Objective
	local goal = HudData.Goal
	local lineH = HudStages.AtLeast(goal.LineHeight, goal.MinHeightPx, screenH)
	if screenW <= 0 or screenH <= 0 then
		return { width = goal.Width, height = lineH, lines = 1 }
	end
	local share = if counter then goal.TextShareCounter else goal.TextShare
	local baseW = goal.Width * screenW
	local maxW = goal.MaxWidth * screenW
	local textPx = math.max(0, chars) * floorPx * goal.CharEm * goal.WrapSlack
	local function need(lines: number): number
		return textPx / lines / share
	end
	local lines = goal.MaxLines
	local widthPx = maxW
	local fitted = false
	for count = 1, goal.MaxLines do
		if need(count) <= baseW then
			lines, widthPx, fitted = count, baseW, true
			break
		end
	end
	if not fitted then
		for count = 1, goal.MaxLines do
			if need(count) <= maxW then
				lines, widthPx, fitted = count, need(count), true
				break
			end
		end
	end
	local heightPx = lines * floorPx * goal.LineEm + goal.PadPx
	return {
		width = widthPx / screenW,
		height = math.max(lineH, heightPx / screenH),
		lines = lines,
	}
end

return HudStages
