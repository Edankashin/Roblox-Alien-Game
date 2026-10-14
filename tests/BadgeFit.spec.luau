--!strict
-- Overlay badges fit their names (Shared/BadgeFit): the Reveal's badge grows to the longest name, an Aliens card's wraps to
-- one pill per word when the name is wider than the card's row, and the speed chip never lands on a badge. The widths are the
-- advance widths of assets/fonts/FredokaOne.ttf at the 14 px floor, which is what Builder.overlayName gets from TextService
-- (the same numbers the UI Playbook quotes: "Hop off" 49.5 px, "Scann" 40.7 px); the first test ties them to the data, so a new
-- or renamed overlay has to be measured before this passes.
local Shared = game:GetService("ReplicatedStorage").Shared
local BadgeFit = require(Shared.BadgeFit)
local Overlays = require(Shared.data.Overlays)
local Strings = require(Shared.strings.en)

local function name(text: string, whole: number, words: { { string | number } }): BadgeFit.Name
	local lines: { BadgeFit.Line } = {}
	for _, word in ipairs(words) do
		table.insert(lines, { text = word[1] :: string, px = word[2] :: number })
	end
	return { whole = { text = text, px = whole }, words = lines }
end

local FIXTURES: { [string]: BadgeFit.Name } = {
	Shiny = name("Shiny", 36.7, { { "Shiny", 36.7 } }),
	Gold = name("Gold", 31.3, { { "Gold", 31.3 } }),
	Crystal = name("Crystal", 49.9, { { "Crystal", 49.9 } }),
	Rainbow = name("Rainbow", 56.5, { { "Rainbow", 56.5 } }),
	Spectral = name("Spectral", 56.6, { { "Spectral", 56.6 } }),
	LaunchGold = name("Launch Gold", 84.0, { { "Launch", 49.2 }, { "Gold", 31.3 } }),
}

-- The Reveal's badge: 0.42 of the card before it was fitted (label 0.86 of it), at most 0.92. The Aliens card's: 0.5 at least,
-- 0.92 across the whole top row, 0.55 while it leaves the speed chip (0.36 wide, 0.04 margins, 0.01 gap) its corner.
local TEXT_FRACTION = 0.9
local SLACK = 2
local reveal: BadgeFit.Params = { textFraction = TEXT_FRACTION, slackPx = SLACK, minWidth = 0.42, maxWidth = 0.92 }
local card: BadgeFit.Params = { textFraction = TEXT_FRACTION, slackPx = SLACK, minWidth = 0.5, maxWidth = 0.92, besideMax = 0.55 }
local SPEED_W, MARGIN, GAP = 0.36, 0.04, 0.01

describe("BadgeFit", function()
	it("has a measured fixture for every overlay that shows a badge, matching the English strings", function()
		local strings: { [string]: string } = Strings :: any
		for _, overlay in ipairs(Overlays.Order) do
			local fixture = FIXTURES[overlay]
			expect(fixture ~= nil).toEqual(true)
			expect(fixture.whole.text).toEqual(strings["OVERLAY_" .. overlay])
		end
	end)

	describe("Reveal badge (one line, grows left)", function()
		it("stays at its old width where the name already fits, and gives an unknown parent the minimum", function()
			expect(BadgeFit.Width(FIXTURES.Shiny.whole.px, 400, reveal)).toEqual(0.42)
			expect(BadgeFit.Width(84, 0, reveal)).toEqual(0.42)
		end)

		it("holds Launch Gold at the iPhone SE card (168 px) where the old 0.42 cut it", function()
			local longest = FIXTURES.LaunchGold.whole.px
			local oldLabelPx = 0.86 * 0.42 * 168
			expect(oldLabelPx < longest).toEqual(true)
			local width = BadgeFit.Width(longest, 168, reveal)
			expect(width > 0.42 and width < 0.92).toEqual(true)
			expect(TEXT_FRACTION * width * 168 >= longest).toEqual(true)
		end)

		it("holds every name at every card width from 120 px up, unless capped", function()
			for px = 120, 420, 3 do
				for _, fixture in pairs(FIXTURES) do
					local width = BadgeFit.Width(fixture.whole.px, px, reveal)
					expect(width >= 0.42 and width <= 0.92).toEqual(true)
					if width < 0.92 then
						expect(TEXT_FRACTION * width * px >= fixture.whole.px).toEqual(true)
					end
				end
			end
		end)
	end)

	describe("Aliens card badge", function()
		it("keeps a short name beside the speed chip, one line, on row 0", function()
			local plan = BadgeFit.Card(FIXTURES.Shiny, 82.1, card)
			expect(#plan.texts).toEqual(1)
			expect(plan.speedRow).toEqual(0)
			expect(plan.levelRow).toEqual(1)
		end)

		it("takes the whole row for a name the speed chip leaves no room for, and moves the chips under it", function()
			local plan = BadgeFit.Card(FIXTURES.Spectral, 82.1, card)
			expect(#plan.texts).toEqual(1)
			expect(plan.widths[1] > 0.55 and plan.widths[1] <= 0.92).toEqual(true)
			expect(plan.speedRow).toEqual(1)
			expect(plan.levelRow).toEqual(1)
		end)

		it("wraps Launch Gold to a pill per word at the phone card (82 px), the speed chip beside the last word", function()
			local plan = BadgeFit.Card(FIXTURES.LaunchGold, 82.1, card)
			expect(#plan.texts).toEqual(2)
			expect(plan.texts[1]).toEqual("Launch")
			expect(plan.texts[2]).toEqual("Gold")
			expect(plan.speedRow).toEqual(1)
			expect(plan.levelRow).toEqual(2)
		end)

		it("shows Launch Gold whole on one line from about 105 px up, beside the speed chip from the iPad's 176 px", function()
			local at115 = BadgeFit.Card(FIXTURES.LaunchGold, 115, card)
			expect(#at115.texts).toEqual(1)
			expect(at115.texts[1]).toEqual("Launch Gold")
			expect(at115.speedRow).toEqual(1)
			local at176 = BadgeFit.Card(FIXTURES.LaunchGold, 176, card)
			expect(#at176.texts).toEqual(1)
			expect(at176.speedRow).toEqual(0)
		end)

		it("never cuts a name and never lets a badge meet the speed chip, at any card width from 78 px up", function()
			for px = 78, 260, 2 do
				for _, fixture in pairs(FIXTURES) do
					local plan = BadgeFit.Card(fixture, px, card)
					local lines = #plan.texts
					expect(lines >= 1 and lines <= #fixture.words).toEqual(true)
					expect(plan.levelRow).toEqual(lines)
					expect(plan.speedRow >= 0 and plan.speedRow <= lines).toEqual(true)
					for line = 1, lines do
						local width = plan.widths[line]
						expect(width >= 0.5 and width <= 0.92).toEqual(true)
						-- the text of this line fits its label, unless the row itself is too narrow for the word (capped)
						local text = if lines == 1 then fixture.whole.px else fixture.words[line].px
						if width < 0.92 then
							expect(TEXT_FRACTION * width * px >= text).toEqual(true)
						end
					end
					if plan.speedRow < lines then
						local width = plan.widths[plan.speedRow + 1]
						expect(MARGIN + width + GAP <= 1 - MARGIN - SPEED_W + 1e-9).toEqual(true)
					end
				end
			end
		end)
	end)
end)
return true
