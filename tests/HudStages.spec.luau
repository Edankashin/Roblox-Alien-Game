--!strict
-- Shared.HudStages (the quiet HUD, Clean-UI-Pass package A) and the data it reads (data/Hud, data/Tutorial HudStages): the staged
-- reveal (every element hidden for a fresh profile, each appearing exactly at its step, all shown when the tutorial is done), the
-- one event chip's source and line, the top-right stack, and the objective line that holds each tutorial hint whole at the 14 px
-- floor on iPhone SE and an iPad.
local Shared = game:GetService("ReplicatedStorage").Shared
local HudStages = require(Shared.HudStages)
local HudData = require(Shared.data.Hud)
local Tutorial = require(Shared.data.Tutorial)
local Strings = require(Shared.strings.en)

local FLOOR = 14 -- Theme.TextSize.Min (the headless sandbox cannot require Theme; tools/tests/test_menu_hud.py keeps the two equal)
local SE = { w = 667, h = 375 }
local IPAD = { w = 1024, h = 768 }
local WIDE = { w = 1600, h = 900 }
local ELEMENTS = { "Shop", "Menu", "ShipBar", "PlaceChip", "EventChip", "Landmarks" }
local DONE = #Tutorial.Steps + 1

local function indexOf(id: string): number
	for index, step in ipairs(Tutorial.Steps) do
		if step.id == id then
			return index
		end
	end
	error("no tutorial step " .. id)
end

describe("HudStages staged reveal", function()
	it("every staged element names a real step (or T0) and every element is staged", function()
		for _, element in ipairs(ELEMENTS) do
			local waitsFor = (Tutorial.HudStages :: any)[element]
			assert(type(waitsFor) == "string", element .. " has no stage")
			if waitsFor ~= "T0" then
				indexOf(waitsFor)
			end
		end
	end)
	it("hides everything a fresh profile has not earned at step 1", function()
		for _, element in ipairs(ELEMENTS) do
			local waitsFor = (Tutorial.HudStages :: any)[element]
			if waitsFor ~= "T0" then
				expect(HudStages.Shown(element, 1, false)).toEqual(false)
			end
		end
	end)
	it("shows an element exactly once its step is complete, never before", function()
		for _, element in ipairs(ELEMENTS) do
			local waitsFor = (Tutorial.HudStages :: any)[element]
			if waitsFor ~= "T0" then
				local at = indexOf(waitsFor)
				expect(HudStages.Shown(element, at, false)).toEqual(false) -- still on the step
				expect(HudStages.Shown(element, at + 1, false)).toEqual(true) -- the step is complete
			end
		end
	end)
	it("only ever adds elements as the steps go by", function()
		for _, element in ipairs(ELEMENTS) do
			local seen = false
			for step = 1, DONE do
				local shown = HudStages.Shown(element, step, false)
				assert(shown or not seen, element .. " went away at step " .. step)
				seen = seen or shown
			end
		end
	end)
	it("shows everything at once for a finished tutorial", function()
		for _, element in ipairs(ELEMENTS) do
			expect(HudStages.Shown(element, DONE, true)).toEqual(true)
			expect(HudStages.Shown(element, 1, true)).toEqual(true)
		end
	end)
	it("the default has the Shop and the Menu appear after the first catch and the landmarks with the end of the tutorial", function()
		expect(HudStages.Shown("Shop", indexOf("T2"), false)).toEqual(false)
		expect(HudStages.Shown("Shop", indexOf("T3"), false)).toEqual(true)
		expect(HudStages.Shown("Menu", indexOf("T3"), false)).toEqual(true)
		expect(HudStages.Shown("ShipBar", indexOf("T3"), false)).toEqual(false)
		expect(HudStages.Shown("ShipBar", indexOf("T4"), false)).toEqual(true)
		expect(HudStages.Shown("Landmarks", indexOf("T7"), false)).toEqual(false)
		expect(HudStages.Shown("Landmarks", DONE, false)).toEqual(true)
	end)
	it("T0 shows an element from the first frame and nothing else changes", function()
		local ids = { "T1", "T2", "T3" }
		local stages = { Shop = "T0", Menu = "T2" }
		expect(HudStages.ShownWith(stages, ids, "Shop", 1, false)).toEqual(true)
		expect(HudStages.ShownWith(stages, ids, "Menu", 1, false)).toEqual(false)
		expect(HudStages.ShownWith(stages, ids, "Menu", 3, false)).toEqual(true)
	end)
	it("an element with no stage, or a step id that is not there, shows (a typo never hides the HUD)", function()
		local ids = { "T1", "T2" }
		expect(HudStages.ShownWith({}, ids, "Shop", 1, false)).toEqual(true)
		expect(HudStages.ShownWith({ Shop = "T9" }, ids, "Shop", 1, false)).toEqual(true)
	end)
	it("knows when the tutorial is over", function()
		expect(HudStages.IsDone(1)).toEqual(false)
		expect(HudStages.IsDone(#Tutorial.Steps)).toEqual(false)
		expect(HudStages.IsDone(#Tutorial.Steps + 1)).toEqual(true)
	end)
end)

describe("HudStages event chip", function()
	it("shows a running event first, then a countdown, then luck, else nothing", function()
		expect(HudStages.EventSlot(true, true, true)).toEqual("banner")
		expect(HudStages.EventSlot(false, true, true)).toEqual("countdown")
		expect(HudStages.EventSlot(false, false, true)).toEqual("luck")
		expect(HudStages.EventSlot(false, false, false)).toEqual(nil)
		expect(HudStages.EventSlot(true, false, false)).toEqual("banner")
	end)
	it("makes one line of the name and the time left", function()
		local suffix, format = Strings.HUD_EVENT_LEFT, Strings.HUD_EVENT_LINE
		expect(HudStages.EventLine(Strings.SHOWER_NOW, Strings.SHOWER_LEFT:format("4m 12s"), suffix, format)).toEqual("Meteor Shower 4m 12s")
		expect(HudStages.EventLine(Strings.RUSH_NOW, Strings.RUSH_LEFT:format("19s"), suffix, format)).toEqual("Catch Rush 19s")
		expect(HudStages.EventLine("Haunted Nebula", Strings.SEASON_LEFT:format("8d 0h"), suffix, format)).toEqual("Haunted Nebula 8d 0h")
	end)
	it("keeps what follows the last middle dot of a weekly line, and the name alone without a subtitle", function()
		local suffix, format = Strings.HUD_EVENT_LEFT, Strings.HUD_EVENT_LINE
		local weekly = Strings.WEEKLY_LEFT:format("Zapfinch", "3d 4h")
		expect(HudStages.EventLine(Strings.WEEKLY_BANNER, weekly, suffix, format)).toEqual("Alien of the Week 3d 4h")
		expect(HudStages.EventLine("Rush", nil, suffix, format)).toEqual("Rush")
		expect(HudStages.EventLine("Rush!", "", suffix, format)).toEqual("Rush")
	end)
	it("a subtitle that is only the suffix leaves the name", function()
		expect(HudStages.EventLine("Rush", " left", " left", "%s %s")).toEqual("Rush")
	end)
end)

describe("HudStages layout", function()
	it("never makes a plate shorter than its pixel floor", function()
		expect(HudStages.AtLeast(0.05, 22, 900)).toEqual(0.05)
		expect(HudStages.AtLeast(0.05, 22, 375)).toBeClose(22 / 375, 1e-9)
		expect(HudStages.AtLeast(0.05, 22, 0)).toEqual(0.05)
	end)
	it("stacks the shown plates one under the other and lets a hidden one take no room", function()
		local tops = HudStages.Stack(0.025, 0.01, { 0.08, 0.05, 0.045 }, { true, false, true })
		expect(tops[1]).toBeClose(0.025, 1e-9)
		expect(tops[2]).toBeClose(0.115, 1e-9)
		expect(tops[3]).toBeClose(0.115, 1e-9)
		local all = HudStages.Stack(0.025, 0.01, { 0.08, 0.05, 0.045 }, { true, true, true })
		expect(all[3]).toBeClose(0.175, 1e-9)
	end)
	it("keeps the wireframe's chips clear of the radar column on a wide screen (it starts at 0.228)", function()
		local chips = HudData.Chips
		local bottom = chips.Top + chips.PlaceHeight + chips.Gap + chips.EventHeight + chips.Gap + chips.FriendHeight
		assert(bottom <= 0.228, "the chips end at " .. bottom)
	end)
	it("keeps the goal plate under the compass strip and its line (to 0.068) and clear of the toasts and the banner slot", function()
		local goal = HudData.Goal
		assert(goal.Top >= 0.068, "the ship bar starts at " .. goal.Top)
		for _, screen in ipairs({ WIDE, IPAD }) do
			local slots = HudStages.GoalSlots(screen.w, screen.h, 4.2)
			local objective = HudStages.Objective(40, true, screen.w, screen.h, FLOOR)
			local bottom = slots.lineTop + objective.height
			assert(bottom <= 0.19, screen.w .. "x" .. screen.h .. ": the goal ends at " .. bottom .. ", into the banner slot at 0.19")
		end
	end)
	it("makes the ship bar at least as wide as a chip of its height, and taller on a short screen", function()
		local slots = HudStages.GoalSlots(SE.w, SE.h, 4.2)
		assert(slots.shipHeight * SE.h >= HudData.Goal.MinHeightPx - 1e-9, "the bar is " .. slots.shipHeight * SE.h .. " px")
		assert(slots.shipWidth * SE.w >= slots.shipHeight * SE.h * 4.2 - 1e-6, "the bar is narrower than a chip")
		local wide = HudStages.GoalSlots(WIDE.w, WIDE.h, 4.2)
		expect(wide.shipHeight).toEqual(HudData.Goal.ShipHeight)
		expect(wide.shipWidth).toEqual(HudData.Goal.Width)
		expect(wide.lineTop).toBeClose(HudData.Goal.Top + HudData.Goal.ShipHeight + HudData.Goal.LineGap, 1e-9)
	end)
end)

describe("HudStages objective line", function()
	local hints = {}
	for _, step in ipairs(Tutorial.Steps) do
		local text = (Strings :: any)[step.hint]
		assert(type(text) == "string", step.hint .. " is not a string")
		hints[step.id] = { chars = utf8.len(text) or #text, counter = step.trigger.count ~= nil }
	end
	for _, screen in ipairs({ SE, IPAD, WIDE }) do
		local label = screen.w .. "x" .. screen.h
		it(label .. ": every hint gets lines it fits in at the 14 px floor, within the width and line limits", function()
			for id, hint in pairs(hints) do
				local o = HudStages.Objective(hint.chars, hint.counter, screen.w, screen.h, FLOOR)
				assert(o.lines >= 1 and o.lines <= HudData.Goal.MaxLines, id .. " has " .. o.lines .. " lines")
				assert(o.width <= HudData.Goal.MaxWidth + 1e-9, id .. " is " .. o.width .. " wide")
				assert(o.width >= HudData.Goal.Width - 1e-9, id .. " is narrower than the bar")
				-- the plate is tall enough for its lines at the floor
				assert(o.height * screen.h >= o.lines * FLOOR * HudData.Goal.LineEm, id .. " is " .. o.height * screen.h .. " px tall")
				-- and, wherever the estimate says it fits, the lines' capacity covers the text
				local share = if hint.counter then HudData.Goal.TextShareCounter else HudData.Goal.TextShare
				local capacity = o.lines * o.width * screen.w * share
				local needed = hint.chars * FLOOR * HudData.Goal.CharEm * HudData.Goal.WrapSlack
				if o.lines < HudData.Goal.MaxLines or o.width < HudData.Goal.MaxWidth - 1e-9 then
					assert(capacity >= needed - 1e-6, id .. " holds " .. capacity .. " px of " .. needed)
				end
			end
		end)
	end
	it("a short hint is one line at the bar's width on a wide screen and the bar's own height", function()
		local o = HudStages.Objective(hints.T1.chars, hints.T1.counter, WIDE.w, WIDE.h, FLOOR)
		expect(o.lines).toEqual(1)
		expect(o.width).toBeClose(HudData.Goal.Width, 1e-9)
		expect(o.height).toBeClose(HudData.Goal.LineHeight, 1e-9)
	end)
	it("the longest hint wraps rather than running off the screen, and takes more room on a phone", function()
		local long = hints.T3
		local wide = HudStages.Objective(long.chars, long.counter, WIDE.w, WIDE.h, FLOOR)
		local phone = HudStages.Objective(long.chars, long.counter, SE.w, SE.h, FLOOR)
		assert(wide.lines >= 2, "the long hint fits on one line?")
		assert(phone.lines >= wide.lines, "the phone wraps less than the wide screen")
		assert(phone.width * SE.w > HudData.Goal.Width * SE.w, "the phone's plate did not widen")
	end)
	it("never grows with a tiny or empty screen", function()
		local o = HudStages.Objective(40, true, 0, 0, FLOOR)
		expect(o.lines).toEqual(1)
		expect(o.width).toEqual(HudData.Goal.Width)
	end)
end)

return true
