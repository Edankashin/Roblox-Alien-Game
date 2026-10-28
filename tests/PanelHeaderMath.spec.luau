--!strict
-- Shared.PanelHeaderMath and data/Panels (UI richness pass, package A): which pills fit beside a title (they drop from the last, the
-- title stays), how a pill's template is filled, the aspect that holds a panel's width at the shell's height, and that every row of
-- Panels.Headers names a real title, real pill templates and a drawn icon. The fit checks stand on the band's fractions (copied from
-- Theme.Block.Band and Panels.Shell, which the headless sandbox cannot all require; tools/tests/test_block_theme.py keeps them equal)
-- at iPhone SE (667 by 375), an iPad and the default Studio window, with a letter of Fredoka taken as 0.58 em wide.
local Shared = game:GetService("ReplicatedStorage").Shared
local BlockMath = require(Shared.BlockMath)
local PanelHeaderMath = require(Shared.PanelHeaderMath)
local Panels = require(Shared.data.Panels)
local PixelIcons = require(Shared.data.PixelIcons)
local Strings = require(Shared.strings.en)

local EM = 0.58
local TEXT_MIN, TEXT_BODY, TEXT_LABEL = 14, 18, 24
local SHELL = Panels.Shell
local BAND = { Pad = 0.015, Icon = 0.7, Pill = 0.56, Close = 0.8, PillPad = 0.5, PillGap = 0.012, TitleGap = 0.012, CloseOverlap = 0.25, TitleStep = 0.72 }
local INK, PANEL_CELL, MIN_ROWS, SEED = 0.4, 0.04, 3, 44

local SE = { name = "iPhone SE", w = 667, h = 375 }
local IPAD = { name = "iPad", w = 1080, h = 810 }
local DEFAULT = { name = "default window", w = 1154, h = 663 }

-- Each screen's panel: its width cap (a share of the screen's width), the aspect it had at the old height and that height.
local PANELS: { [string]: { w: number, aspect: number, old: number } } = {
	Aliens = { w = 0.8, aspect = 1.35, old = 0.84 },
	Codex = { w = 0.8, aspect = 1.35, old = 0.78 },
	Ship = { w = 0.8, aspect = 1.35, old = 0.78 },
	StarChart = { w = 0.84, aspect = 1.75, old = 0.78 },
	Quests = { w = 0.8, aspect = 1.35, old = 0.78 },
	Gifts = { w = 0.8, aspect = 1.4, old = 0.78 },
	Playtime = { w = 0.92, aspect = 2, old = 0.78 },
	Shop = { w = 0.8, aspect = 1.35, old = 0.78 },
	Mail = { w = 0.8, aspect = 1.6, old = 0.78 },
	Visit = { w = 0.8, aspect = 1.6, old = 0.78 },
	Ranks = { w = 0.8, aspect = 1.15, old = 0.8 },
	Peddler = { w = 0.8, aspect = 1.35, old = 0.78 },
	Settings = { w = 0.64, aspect = 1.3, old = 0.84 },
}

local function clamp(n: number, lo: number, hi: number): number
	return math.max(lo, math.min(hi, n))
end

-- The title room and the pill widths of a header on a screen, in px, the way Builder.panelHeader lays them out.
local function fitHeader(id: string, screen: { w: number, h: number }): (number, number, { number }, number)
	local panel = PANELS[id]
	local header = Panels.Headers[id]
	local aspect = PanelHeaderMath.ShellAspect(panel.aspect, panel.old, SHELL.Height)
	local panelH = SHELL.Height * screen.h
	local panelW = math.min(panel.w * screen.w, aspect * panelH)
	local bandH = SHELL.BandHeight * panelH
	local pillH = BAND.Pill * bandH
	local pillText = clamp(pillH * 0.62, TEXT_MIN, TEXT_BODY)
	local titleText = clamp(bandH * BAND.TitleStep, TEXT_MIN, TEXT_LABEL)
	local title = #(Strings :: any)[header.title] * titleText * EM
	local pills: { number } = {}
	for _, key in ipairs(header.pills) do
		local sample = PanelHeaderMath.Format((Strings :: any)[key], { 88, 188, 188 }) -- a wide sample: two or three digits each
		table.insert(pills, PanelHeaderMath.PillWidth(#sample * pillText * EM, pillH, BAND.PillPad))
	end
	local closeW = BAND.Close * bandH
	local room = panelW * (1 - 2 * BAND.Pad) - BAND.Icon * bandH - BAND.TitleGap * panelW - closeW * (1 - BAND.CloseOverlap) - BAND.PillGap * panelW
	return room, title, pills, BAND.PillGap * panelW
end

describe("PanelHeaderMath Fit", function()
	it("shows every pill when all fit, and none when the title alone fills the room", function()
		expect(PanelHeaderMath.Fit(500, 150, { 100, 120 }, 10)).toEqual(2)
		expect(PanelHeaderMath.Fit(150, 150, { 100, 120 }, 10)).toEqual(0)
		expect(PanelHeaderMath.Fit(500, 150, {}, 10)).toEqual(0)
	end)
	it("drops the pills from the last, never the first before the second", function()
		expect(PanelHeaderMath.Fit(400, 150, { 100, 120 }, 10)).toEqual(2) -- 150 + 110 + 130 = 390
		expect(PanelHeaderMath.Fit(389, 150, { 100, 120 }, 10)).toEqual(1)
		expect(PanelHeaderMath.Fit(259, 150, { 100, 120 }, 10)).toEqual(0)
		expect(PanelHeaderMath.Fit(260, 150, { 100, 120 }, 10)).toEqual(1)
	end)
	it("keeps the title whole whatever the pills need (the pills go, the title does not wrap)", function()
		for width = 100, 600, 20 do
			local shown = PanelHeaderMath.Fit(width, 150, { 100, 120 }, 10)
			local used = 150
			for index = 1, shown do
				used += ({ 100, 120 })[index] + 10
			end
			assert(shown == 0 or used <= width, "pills overrun at " .. width)
		end
	end)
	it("lets every pill show on a panel that has not been measured", function()
		expect(PanelHeaderMath.Fit(0, 150, { 100, 120 }, 10)).toEqual(2)
	end)
	for _, screen in ipairs({ SE, IPAD, DEFAULT }) do
		it(screen.name .. ": the title keeps its room and the plain pill shows on every panel that has one", function()
			for id, header in pairs(Panels.Headers) do
				local room, title, pills, gap = fitHeader(id, screen)
				local shown = PanelHeaderMath.Fit(room, title, pills, gap)
				assert(room >= title * 0.85, id .. ": the title has " .. room .. " px for " .. title)
				if screen ~= SE then
					expect(shown).toEqual(#header.pills)
				end
				assert(#header.pills == 0 or shown >= 1 or screen == SE, id .. " shows no pill")
			end
		end)
	end
	it("iPhone SE: the pills do drop on the two-pill panels before the title wraps", function()
		local dropped = 0
		for id, header in pairs(Panels.Headers) do
			local room, title, pills, gap = fitHeader(id, SE)
			local shown = PanelHeaderMath.Fit(room, title, pills, gap)
			if shown < #header.pills then
				dropped += 1
			end
		end
		assert(dropped >= 1, "nothing drops at iPhone SE: the pill widths may be too small to test")
	end)
end)

describe("PanelHeaderMath Format", function()
	it("fills %d with whole numbers and thousands separators and %s as it is", function()
		expect(PanelHeaderMath.Format("Aliens %d / %d", { 34, 160 })).toEqual("Aliens 34 / 160")
		expect(PanelHeaderMath.Format("Scrap %s", { "99,936" })).toEqual("Scrap 99,936")
		expect(PanelHeaderMath.Format("Scrap %d", { 99936 })).toEqual("Scrap 99,936")
		expect(PanelHeaderMath.Format("You #%d", { 12 })).toEqual("You #12")
		expect(PanelHeaderMath.Format("Crew x%s", { 1.6 })).toEqual("Crew x1.6")
	end)
	it("never errors on a count that has not arrived", function()
		expect(PanelHeaderMath.Format("Aliens %d / %d", { 3 })).toEqual("Aliens 3 / 0")
		expect(PanelHeaderMath.Format("Scrap %s", {})).toEqual("Scrap ")
		expect(PanelHeaderMath.Format("Day %d", { 3, 9 })).toEqual("Day 3")
		expect(PanelHeaderMath.Format("100%% %d", { 5 })).toEqual("100% 5")
	end)
	it("rounds a fraction to the whole number a %d shows", function()
		expect(PanelHeaderMath.Format("Today %d min", { 11.6 })).toEqual("Today 12 min")
	end)
end)

describe("PanelHeaderMath ShellAspect", function()
	it("holds the panel's width in px at the shell's height", function()
		for _, screen in ipairs({ SE, IPAD, DEFAULT }) do
			local oldW = 1.35 * 0.78 * screen.h
			local newAspect = PanelHeaderMath.ShellAspect(1.35, 0.78, SHELL.Height)
			expect(newAspect * SHELL.Height * screen.h).toBeClose(oldW, 0.001)
		end
		expect(PanelHeaderMath.ShellAspect(1.3, 0.84, 0.84)).toEqual(1.3)
	end)
end)

describe("Panels Shell and Headers", function()
	it("puts the band under the Scrap pill: the panel starts at the pill's end and ends on screen", function()
		expect(SHELL.Top).toEqual(0.1)
		assert(SHELL.Top + SHELL.Height <= 1, "the panel leaves the screen")
		expect(SHELL.BandHeight).toEqual(0.13)
	end)
	it("starts a body under the band: the panel's ink plus the band's height is above BodyTop, and BodyTop leaves the panel its room", function()
		local rows = BlockMath.Rows(SHELL.Height, PANEL_CELL, INK, MIN_ROWS)
		local grid = BlockMath.Grid(1.3, rows, INK)
		local bandBottom = BlockMath.Inner(grid).y + SHELL.BandHeight
		assert(bandBottom < SHELL.BodyTop, "the band reaches " .. bandBottom .. ", the body starts at " .. SHELL.BodyTop)
		assert(SHELL.BodyTop - bandBottom < 0.03, "more than a sliver of air under the band")
	end)
	it("gives every header a real title, real pill templates, a drawn icon and a colour with an accent", function()
		local strings = Strings :: any
		local count = 0
		for id, header in pairs(Panels.Headers) do
			count += 1
			assert(type(strings[header.title]) == "string", id .. " title " .. header.title)
			assert(PixelIcons.Icons[header.icon] ~= nil, id .. " icon " .. header.icon)
			assert(#header.pills <= 2, id .. " has more than two pills")
			for _, key in ipairs(header.pills) do
				assert(type(strings[key]) == "string", id .. " pill " .. key)
				assert(string.find(strings[key], "%%[ds]") ~= nil, key .. " has no value to fill")
			end
			assert(SHELL.Accent[header.color] ~= nil, id .. " colour " .. header.color .. " has no accent")
		end
		expect(count).toEqual(13)
	end)
	it("keeps the thirteen panels of the spec", function()
		for _, id in ipairs({ "Aliens", "Codex", "Ship", "StarChart", "Quests", "Gifts", "Playtime", "Shop", "Mail", "Visit", "Ranks", "Peddler", "Settings" }) do
			assert(Panels.Headers[id] ~= nil, id .. " has no header")
		end
	end)
	it("names a colour and a word for every role and stamp, and studs only on the rarer tiers", function()
		for _, role in ipairs({ "main", "robux", "current", "select", "close", "featured" }) do
			assert(Panels.Roles[role] ~= nil, role)
		end
		for kind, stamp in pairs(Panels.Stamps) do
			assert(type((Strings :: any)[stamp.word]) == "string", kind .. " word " .. stamp.word)
		end
		expect(Panels.TierFrames.Common.studs).toEqual(0)
		expect(Panels.TierFrames.Uncommon.studs).toEqual(0)
		expect(Panels.TierFrames.Rare.studs).toEqual(1)
		expect(Panels.TierFrames.Epic.studs).toEqual(2)
		expect(Panels.TierFrames.Legendary.studs).toEqual(4)
		expect(Panels.TierFrames.Cosmic.studs).toEqual(4)
		expect(Panels.TierFrames.Secret.studs).toEqual(4)
		local previous = 0
		for _, tier in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic" }) do
			local frame = Panels.TierFrames[tier]
			assert(frame.studs >= previous and frame.studs <= 4, tier .. " studs go down the ladder")
			previous = frame.studs
		end
	end)
	it("the band is three rows and light: a header costs under 200 frames on every panel", function()
		for id, panel in pairs(PANELS) do
			local aspect = PanelHeaderMath.ShellAspect(panel.aspect, panel.old, SHELL.Height)
			local bandAspect = aspect * 0.97 / SHELL.BandHeight
			local grid = BlockMath.Grid(bandAspect, MIN_ROWS, INK)
			local frames = BlockMath.Frames(grid, true, SEED)
			assert(frames <= 200, id .. " band is " .. frames .. " frames")
		end
	end)
	it("the panel takes the shell's rows at the panel cell", function()
		local rows = BlockMath.Rows(SHELL.Height, PANEL_CELL, INK, MIN_ROWS)
		assert(rows >= 18 and rows <= 22, "rows " .. rows)
	end)
end)

return true
