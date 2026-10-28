--!strict
-- Shared.HudStages (the quiet HUD, Clean-UI-Pass package A) and the data it reads (data/Hud, data/Tutorial HudStages): the staged
-- reveal (every element hidden for a fresh profile, each appearing exactly at its step, all shown when the tutorial is done), the
-- one event chip's source and line, the top-right stack, and the objective line that holds each tutorial hint whole at the 14 px
-- floor on iPhone SE and an iPad. The goal card (UI richness pass, package A): the bar's fraction for a counted tutorial step and a
-- Field Notes step, the reward chip, the shares of the plate's width, and the Field Notes titles fitting beside the reward chip.
local Shared = game:GetService("ReplicatedStorage").Shared
local HudStages = require(Shared.HudStages)
local HudData = require(Shared.data.Hud)
local Tutorial = require(Shared.data.Tutorial)
local Quests = require(Shared.data.Quests)
local PixelIcons = require(Shared.data.PixelIcons)
local Strings = require(Shared.strings.en)

local FLOOR = 14 -- Theme.TextSize.Min (the headless sandbox cannot require Theme; tools/tests/test_menu_hud.py keeps the two equal)
local SE = { w = 667, h = 375 }
local IPAD = { w = 1024, h = 768 }
local WIDE = { w = 1600, h = 900 }
local ELEMENTS = { "Shop", "Menu", "ShipBar", "PlaceChip", "EventChip", "Landmarks", "Radar" }
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
		-- The radar column waits for the end of the tutorial even when the account owns Radar Mk1 (Explorer Pack), and a finished tutorial shows it at once.
		expect(HudStages.Shown("Radar", 1, false)).toEqual(false)
		expect(HudStages.Shown("Radar", indexOf("T7"), false)).toEqual(false)
		expect(HudStages.Shown("Radar", DONE, false)).toEqual(true)
		expect(HudStages.Shown("Radar", 1, true)).toEqual(true)
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
	it("shows a running Rush or Shower first, then a countdown, then a standing event, then luck, else nothing", function()
		expect(HudStages.EventSlot(true, true, true, true)).toEqual("banner") -- a Rush or Shower running now
		expect(HudStages.EventSlot(true, true, false, true)).toEqual("banner")
		expect(HudStages.EventSlot(false, false, true, true)).toEqual("countdown")
		expect(HudStages.EventSlot(false, false, false, true)).toEqual("luck")
		expect(HudStages.EventSlot(false, false, false, false)).toEqual(nil)
		expect(HudStages.EventSlot(true, false, false, false)).toEqual("banner")
	end)
	it("lets a countdown to a Rush take the chip from server luck, the season and the weekly event (job 65: /rush in 20 under server luck)", function()
		expect(HudStages.EventSlot(true, false, true, true)).toEqual("countdown") -- a standing banner and a countdown due
		expect(HudStages.EventSlot(true, false, true, false)).toEqual("countdown")
		expect(HudStages.EventSlot(true, false, false, true)).toEqual("banner") -- the countdown ended: the standing banner returns
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

describe("HudStages goal card", function()
	it("fills a counted step by its counter over its count and leaves an uncounted one empty", function()
		expect(HudStages.Fraction(1, 3)).toBeClose(1 / 3, 1e-9)
		expect(HudStages.Fraction(2, 3)).toBeClose(2 / 3, 1e-9)
		expect(HudStages.Fraction(0, 3)).toEqual(0)
		expect(HudStages.Fraction(3, 3)).toEqual(1)
		expect(HudStages.Fraction(5, 3)).toEqual(1) -- a surplus never overfills
		expect(HudStages.Fraction(-1, 3)).toEqual(0)
		expect(HudStages.Fraction(0, 0)).toEqual(nil) -- no count: a trough with no fill, no fake progress
	end)
	it("sums a Field Notes step's objectives, each capped at its own count", function()
		local have, need = HudStages.NotesProgress({ { id = "a", count = 5 } }, { a = 3 })
		expect(have).toEqual(3)
		expect(need).toEqual(5)
		have, need = HudStages.NotesProgress({ { id = "a", count = 1 }, { id = "b", count = 1 } }, { a = 4, b = 0 })
		expect(have).toEqual(1) -- the surplus on a does not make up for b
		expect(need).toEqual(2)
		expect(HudStages.Fraction(have, need)).toEqual(0.5)
		have, need = HudStages.NotesProgress({ { id = "a", count = 2 } }, {})
		expect(have).toEqual(0)
		expect(need).toEqual(2)
		have, need = HudStages.NotesProgress({}, { a = 1 })
		expect(HudStages.Fraction(have, need)).toEqual(nil)
	end)
	it("takes the first reward with a picture and an amount for the chip, and none when a step pays only gear, an item or an alien", function()
		local chip = HudStages.GoalReward({ { kind = "gear", id = "Radar1" }, { kind = "scrap", amount = 500 }, { kind = "lure", id = "Lure1", amount = 3 } })
		assert(chip ~= nil, "no chip")
		expect(chip.key).toEqual("Scrap")
		expect(chip.amount).toEqual(500)
		chip = HudStages.GoalReward({ { kind = "spin", amount = 2 } })
		assert(chip ~= nil, "no chip")
		expect(chip.key).toEqual("Spin")
		expect(HudStages.GoalReward({ { kind = "gear", id = "Boots" } })).toEqual(nil)
		expect(HudStages.GoalReward({ { kind = "item", id = "WardenHorn", amount = 1 } })).toEqual(nil)
		expect(HudStages.GoalReward({ { kind = "encounter", id = "Gaiabloom" } })).toEqual(nil)
		expect(HudStages.GoalReward({})).toEqual(nil)
	end)
	it("draws a pixel icon for every reward chip a Field Notes step can show", function()
		for world, steps in pairs(Quests.FieldNotes) do
			for _, step in ipairs(steps) do
				local chip = HudStages.GoalReward(step.rewards :: any)
				if chip then
					assert(PixelIcons.Icons[chip.key] ~= nil, ("world %d %s: no pixel icon %s"):format(world, step.id, chip.key))
				end
			end
		end
	end)
	it("shares the plate's width so the text, the counter and the reward add up inside it", function()
		local goal = HudData.Goal
		for _, case in ipairs({ { false, false }, { true, false }, { true, true }, { false, true } }) do
			local shares = HudStages.GoalShares(case[1], case[2])
			local used = shares.text + shares.counter + shares.reward
			assert(used <= goal.ChipRight + 1e-9, ("counted %s rewarded %s uses %.2f"):format(tostring(case[1]), tostring(case[2]), used))
			if shares.reward > 0 then
				assert(shares.text + shares.counter + shares.reward + goal.ChipGap <= 1, "the chips run off the plate")
			end
		end
		expect(HudStages.GoalShares(true, true).text).toEqual(goal.TextShareReward)
		expect(HudStages.GoalShares(true, true).counter).toEqual(goal.CounterShare)
		expect(HudStages.GoalShares(true, true).reward).toEqual(goal.RewardShare)
		expect(HudStages.GoalShares(true, false).text).toEqual(goal.TextShareCounter)
		expect(HudStages.GoalShares(false, false).text).toEqual(goal.TextShare)
	end)
	for _, screen in ipairs({ SE, IPAD, WIDE }) do
		it(screen.w .. "x" .. screen.h .. ": every Field Notes title fits its plate beside the reward chip, within the line and width limits", function()
			for world, steps in pairs(Quests.FieldNotes) do
				for _, step in ipairs(steps) do
					local title = (Strings :: any)["FN_" .. step.id .. "_TITLE"]
					assert(type(title) == "string", step.id .. " has no title")
					local o = HudStages.Objective(utf8.len(title) or #title, true, screen.w, screen.h, FLOOR, true)
					assert(o.lines >= 1 and o.lines <= HudData.Goal.MaxLines, ("world %d %s has %d lines"):format(world, step.id, o.lines))
					assert(o.width <= HudData.Goal.MaxWidth + 1e-9, step.id .. " is " .. o.width .. " wide")
				end
			end
		end)
	end
	it("a reward chip narrows the text: the same hint takes at least as many lines or as much width", function()
		local plain = HudStages.Objective(30, true, SE.w, SE.h, FLOOR, false)
		local rewarded = HudStages.Objective(30, true, SE.w, SE.h, FLOOR, true)
		assert(rewarded.lines >= plain.lines and rewarded.width >= plain.width - 1e-9, "the reward chip gave the text more room")
	end)
	it("keeps the goal card inside the Clean pass height: the plate grows in width first, and a one-line title is one bar high", function()
		local o = HudStages.Objective(14, true, WIDE.w, WIDE.h, FLOOR, true) -- a short title beside the chips
		expect(o.lines).toEqual(1)
		expect(o.height).toBeClose(HudData.Goal.LineHeight, 1e-9)
	end)
end)

return true
