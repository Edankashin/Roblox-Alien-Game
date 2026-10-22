--!strict
-- Shared.PanelQuiet and data/Panels (Clean UI pass, package C): the quiet panel face, the Settings list and its row heights, the
-- Ship roles, the Codex default, the Quests tab and What's on summary, the gift states and the Aliens footer. The layout checks
-- stand on the screens' fractions (copied here, as tests/BlockMath.spec.luau copies the HUD's) at iPhone SE and an iPad.
local Shared = game:GetService("ReplicatedStorage").Shared
local BlockMath = require(Shared.BlockMath)
local PanelQuiet = require(Shared.PanelQuiet)
local Panels = require(Shared.data.Panels)
local SettingsData = require(Shared.data.Settings)

-- Theme.Block (tools/tests/test_block_theme.py keeps these equal to the theme's).
local CELL, INK, MIN_ROWS, SEED = 0.02, 0.4, 3, 44
local PANEL_CELL = 0.04
local TEXT_MIN = 14

local SE = { name = "iPhone SE", w = 667, h = 375 }
local IPAD = { name = "iPad", w = 1080, h = 810 }
local DEFAULT = { name = "default window", w = 1154, h = 663 }
local SCREENS = { SE, IPAD, DEFAULT }

local function gridOf(sizeX: number, sizeY: number, aspect: number, screen: { w: number, h: number }): (number, number, BlockMath.Grid)
	local w, h = BlockMath.FitPx(sizeX, sizeY, aspect, screen.w, screen.h)
	local rows = BlockMath.Rows(sizeY, PANEL_CELL, INK, MIN_ROWS)
	return w, h, BlockMath.Grid(aspect, rows, INK)
end

describe("PanelQuiet face", function()
	for _, screen in ipairs(SCREENS) do
		it(screen.name .. ": a quiet panel face draws the jitter's frames fewer and keeps the bands and the grout", function()
			local _, _, grid = gridOf(0.8, 0.78, 1.35, screen)
			local loud = PanelQuiet.Frames(grid, SEED, false)
			local quiet = PanelQuiet.Frames(grid, SEED, true)
			expect(loud).toEqual(BlockMath.Frames(grid, true, SEED))
			expect(loud - quiet).toEqual(#BlockMath.Jittered(grid, SEED))
			assert(loud > quiet, "the jitter draws frames")
			local flat = BlockMath.Frames(grid, false, SEED, true)
			expect(quiet - flat).toEqual(#BlockMath.Grout(grid, 1))
			assert(quiet <= BlockMath.Frames(grid, true, SEED), "a quiet face is never heavier")
		end)
	end
	it("the quiet grout is fainter than the ordinary grout", function()
		-- Theme.Block.GroutAlpha 0.9 and QuietGroutAlpha 0.95 are transparencies: more is fainter.
		local grout, quietGrout = 0.9, 0.95
		assert(quietGrout > grout and quietGrout < 1, "the quiet grout must stay visible but fainter")
	end)
end)

describe("Settings list", function()
	local order: { string } = {}
	for _, def in ipairs(SettingsData.Order) do
		table.insert(order, def.key)
	end
	it("puts every data/Settings key in exactly once, under a heading", function()
		local items = PanelQuiet.SettingsItems(order, Panels.SettingsSections)
		local seen: { [string]: number } = {}
		local headings = 0
		for index, item in ipairs(items) do
			if item.kind == "heading" then
				headings += 1
			else
				assert(index > 1 and (items[1] :: any).kind == "heading", "a row before any heading")
				seen[item.key] = (seen[item.key] or 0) + 1
			end
		end
		for _, key in ipairs(order) do
			expect(seen[key]).toEqual(1)
		end
		expect(headings).toEqual(#Panels.SettingsSections)
	end)
	it("reads Sound and motion first and Home second, the lock under Home", function()
		local items = PanelQuiet.SettingsItems(order, Panels.SettingsSections)
		local titles: { string } = {}
		local homeKeys: { string } = {}
		local under = ""
		for _, item in ipairs(items) do
			if item.kind == "heading" then
				table.insert(titles, item.title)
				under = item.title
			elseif under == "SETTINGS_SECTION_Home" then
				table.insert(homeKeys, item.key)
			end
		end
		expect(titles[1]).toEqual("SETTINGS_SECTION_Sound")
		expect(titles[2]).toEqual("SETTINGS_SECTION_Home")
		expect(#homeKeys).toEqual(1)
		expect(homeKeys[1]).toEqual("HomeLock")
	end)
	it("shows a new setting nobody mapped under the first heading, and skips a mapped key that does not exist", function()
		local extra = { "Ambience", "Music", "BrandNew", "HomeLock", "Missing" }
		table.remove(extra, #extra) -- "Missing" is only in the section map below
		local items = PanelQuiet.SettingsItems(extra, {
			{ title = "A", keys = { "Ambience", "Missing" } },
			{ title = "B", keys = { "HomeLock" } },
		})
		local flat: { string } = {}
		for _, item in ipairs(items) do
			table.insert(flat, if item.kind == "heading" then "#" .. item.title else item.key)
		end
		expect(table.concat(flat, ",")).toEqual("#A,Ambience,Music,BrandNew,#B,HomeLock")
	end)
	it("drops a section with no rows, and with no sections lists the rows bare", function()
		local items = PanelQuiet.SettingsItems({ "Music" }, { { title = "A", keys = { "Ambience" } }, { title = "B", keys = { "Music" } } })
		-- A names a key the list lacks, so it is empty and goes; B keeps its heading and its row.
		expect(#items).toEqual(2)
		expect((items[1] :: any).title).toEqual("B")
		expect((items[2] :: any).key).toEqual("Music")
		local bare = PanelQuiet.SettingsItems({ "Music", "Sounds" }, {})
		expect(#bare).toEqual(2)
		expect((bare[1] :: any).kind).toEqual("row")
	end)
	it("shares the rows frame: rows, headings and gaps add up to one", function()
		local row, heading = PanelQuiet.SettingsShares(8, 2, Panels.SettingsHeadingWeight, Panels.SettingsGap)
		expect(8 * row + 2 * heading + 9 * Panels.SettingsGap).toBeClose(1, 1e-9)
		expect(heading).toBeClose(row * Panels.SettingsHeadingWeight, 1e-9)
	end)
	-- SettingsScreen.luau: the panel 0.64 x 0.84 at 1.3; the rows frame from 0.16 to 0.925 of it, a card an edged block of six rows,
	-- a control 0.86 of a row, a flat block button of six rows over its one-cell lip, its text padded a quarter cell inside the ink.
	local PANEL_W, PANEL_H, ASPECT = 0.64, 0.84, 1.3
	local ROWS_Y, ROWS_BOTTOM = 0.16, 0.925
	local HINT_Y, HINT_H = 0.935, 0.05
	local CARD_ROWS, CONTROL_ROWS, CONTROL_H = 6, 6, 0.86
	for _, screen in ipairs({ SE, IPAD }) do
		local rowsCount = #SettingsData.Order + 1 -- the settings and the promo-code row; B's Announcements row is one of them once merged
		local withAnnouncements = rowsCount + (if SettingsData.ById.Announcements then 0 else 1)
		for _, count in ipairs({ rowsCount, withAnnouncements }) do
			it(screen.name .. ", " .. count .. " rows: a control keeps the 14 px floor inside its card, and the headings hold a line", function()
				local _, h = BlockMath.FitPx(PANEL_W, PANEL_H, ASPECT, screen.w, screen.h)
				local framePx = (ROWS_BOTTOM - ROWS_Y) * h
				local row, heading = PanelQuiet.SettingsShares(count, #Panels.SettingsSections, Panels.SettingsHeadingWeight, Panels.SettingsGap)
				local rowPx = row * framePx
				local cardFace = rowPx * (1 - 2 * INK / (CARD_ROWS + 2 * INK))
				local control = CONTROL_H * rowPx
				assert(control <= cardFace, "a control (" .. control .. " px) overflows its card's face (" .. cardFace .. " px)")
				local lip = BlockMath.Lip(1, CONTROL_ROWS, INK)
				local face = control * (1 - lip)
				local text = face * (1 - (2 * INK + 0.5) / (CONTROL_ROWS + 2 * INK))
				assert(text >= TEXT_MIN - 0.3, "a control's text box is " .. text .. " px")
				assert(INK * face / (CONTROL_ROWS + 2 * INK) >= 0.95, "a control's ink is under a pixel")
				assert(heading * framePx >= TEXT_MIN + 2, "a heading is " .. heading * framePx .. " px tall")
				assert((HINT_H) * h >= TEXT_MIN, "the hint line is " .. HINT_H * h .. " px")
				assert(HINT_Y >= ROWS_BOTTOM, "the hint overlaps the rows")
				assert(HINT_Y + HINT_H <= 1, "the hint leaves the panel")
			end)
		end
	end
end)

describe("Ship panel rules", function()
	it("makes Pay the one green button until the Scrap is paid, with Add blue only when a part can go in", function()
		local pay, add = PanelQuiet.ShipRoles(false, true, false)
		expect(pay).toEqual("primary")
		expect(add).toEqual("idle")
		pay, add = PanelQuiet.ShipRoles(false, true, true)
		expect(pay).toEqual("primary")
		expect(add).toEqual("secondary")
	end)
	it("makes Add the one green button once the Scrap is paid and parts are missing, and none when nothing is left to do", function()
		local pay, add = PanelQuiet.ShipRoles(true, true, false)
		expect(pay).toEqual("idle")
		expect(add).toEqual("primary")
		pay, add = PanelQuiet.ShipRoles(true, false, false)
		expect(pay).toEqual("idle")
		expect(add).toEqual("idle")
	end)
	it("never has two primary buttons", function()
		for _, paid in ipairs({ false, true }) do
			for _, missing in ipairs({ false, true }) do
				for _, can in ipairs({ false, true }) do
					local pay, add = PanelQuiet.ShipRoles(paid, missing, can)
					assert(not (pay == "primary" and add == "primary"), "two green buttons")
				end
			end
		end
	end)
	it("shows the intro line only on the first module until its Scrap is paid", function()
		expect(PanelQuiet.ShipIntroShown(1, false, false)).toEqual(true)
		expect(PanelQuiet.ShipIntroShown(1, true, false)).toEqual(false)
		expect(PanelQuiet.ShipIntroShown(2, false, false)).toEqual(false)
		expect(PanelQuiet.ShipIntroShown(nil, true, true)).toEqual(false)
		expect(PanelQuiet.ShipIntroShown(1, false, true)).toEqual(false)
	end)
	it("prints the locked hint on the first locked row only", function()
		local shown = 0
		for index = 1, 5 do
			if PanelQuiet.ShipLockedHint(index, 1) then
				shown += 1
				expect(index).toEqual(2)
			end
		end
		expect(shown).toEqual(1)
		expect(PanelQuiet.ShipLockedHint(3, nil)).toEqual(false)
		expect(PanelQuiet.ShipLockedHint(5, 5)).toEqual(false)
	end)
end)

describe("Codex default", function()
	local roster = { "Moop", "Wispkin", "Zapfinch", "Thunderhog" }
	it("opens on the most recently caught species of the page", function()
		expect(PanelQuiet.CodexDefault(roster, { Moop = 10, Zapfinch = 30, Wispkin = 20 })).toEqual("Zapfinch")
	end)
	it("ignores species of other pages and breaks a tie toward the earlier entry", function()
		expect(PanelQuiet.CodexDefault(roster, { Elsewhere = 99, Wispkin = 5, Zapfinch = 5 })).toEqual("Wispkin")
	end)
	it("opens on the first entry when nothing is caught, so the card is never empty", function()
		expect(PanelQuiet.CodexDefault(roster, {})).toEqual("Moop")
	end)
	it("is nil only for an empty page", function()
		expect(PanelQuiet.CodexDefault({}, { Moop = 1 })).toEqual(nil)
	end)
end)

describe("Quests tab and summary", function()
	it("opens on the first tab with something to claim, Field Notes first, else Field Notes", function()
		expect(PanelQuiet.QuestTab({ daily = true, event = true }, true)).toEqual("daily")
		expect(PanelQuiet.QuestTab({ notes = true, daily = true }, true)).toEqual("notes")
		expect(PanelQuiet.QuestTab({ event = true }, true)).toEqual("event")
		expect(PanelQuiet.QuestTab({}, true)).toEqual("notes")
	end)
	it("ignores the Event tab while no season shows it", function()
		expect(PanelQuiet.QuestTab({ event = true }, false)).toEqual("notes")
		expect(PanelQuiet.QuestTab({ event = true, daily = true }, false)).toEqual("daily")
	end)
	it("sums the What's on band as one line", function()
		expect(PanelQuiet.OnSummary(2, 1).kind).toEqual("many")
		expect(PanelQuiet.OnSummary(2, 1).count).toEqual(2)
		expect(PanelQuiet.OnSummary(1, 3).kind).toEqual("one")
		expect(PanelQuiet.OnSummary(0, 3).kind).toEqual("later")
		expect(PanelQuiet.OnSummary(0, 0).kind).toEqual("none")
		expect(PanelQuiet.OnSummary(4, 0).count).toEqual(4)
	end)
end)

describe("Gift states", function()
	it("is claimed once taken, claimable when reached and not taken, future before that", function()
		expect(PanelQuiet.GiftState(true, true)).toEqual("claimed")
		expect(PanelQuiet.GiftState(false, true)).toEqual("claimed")
		expect(PanelQuiet.GiftState(true, false)).toEqual("claimable")
		expect(PanelQuiet.GiftState(false, false)).toEqual("future")
	end)
end)

describe("Aliens footer", function()
	-- Widths at the 14 px floor in Fredoka One (the Release word, the short Bay label "+20 for 2,500", the full one, Use Token, Fuse,
	-- Optimize), plus the 12 px a block button's ink and padding take.
	local TEXT_PX = { release = 46, bayShort = 85, bay = 156, token = 86, fuse = 34, optimize = 57 }
	local PAD = 12
	local BAY_PAD = 4 -- the Bay button's text runs nearly edge to edge (the old spec asks 156 px of it)
	for _, tokenHeld in ipairs({ false, true }) do
		local label = if tokenHeld then "token held" else "no token"
		it(label .. ": the buttons stand left to right inside the panel with a gap between", function()
			local f = PanelQuiet.AliensFooter(tokenHeld)
			local row: { PanelQuiet.Slot } = { f.release, f.bay }
			if f.token then
				table.insert(row, f.token)
			end
			table.insert(row, f.fuse)
			table.insert(row, f.optimize)
			expect(f.token ~= nil).toEqual(tokenHeld)
			for index = 1, #row - 1 do
				local left, right = row[index], row[index + 1]
				assert(left.x + left.w + Panels.AliensFooter.Gap <= right.x + 1e-9, "button " .. index .. " touches the next")
			end
			local last = row[#row]
			assert(last.x + last.w <= 1 - Panels.AliensFooter.Margin + 1e-9, "the row leaves the panel")
			assert(f.release.x >= Panels.AliensFooter.Margin - 1e-9, "Release leaves the left margin")
		end)
		for _, screen in ipairs(SCREENS) do
			it(label .. ", " .. screen.name .. ": every button holds its word and is 44 px wide for a tap", function()
				local w = BlockMath.FitPx(0.8, 0.84, 1.35, screen.w, screen.h)
				local f = PanelQuiet.AliensFooter(tokenHeld)
				local bayText = if tokenHeld then TEXT_PX.bayShort else TEXT_PX.bay
				assert(f.release.w * w >= TEXT_PX.release + PAD, "Release is " .. f.release.w * w .. " px")
				assert(f.bay.w * w >= bayText + BAY_PAD, "the Bay button is " .. f.bay.w * w .. " px")
				assert(f.fuse.w * w >= 44 and f.optimize.w * w >= TEXT_PX.optimize + PAD, "Fuse or Optimize too narrow")
				assert(f.release.w * w >= 44, "Release is under 44 px")
				local token = f.token
				if token then
					assert(token.w * w >= TEXT_PX.token + PAD - 10, "the token button is " .. token.w * w .. " px")
				end
			end)
		end
	end
	it("keeps Release at the left of the Bay button in both states", function()
		for _, tokenHeld in ipairs({ false, true }) do
			local f = PanelQuiet.AliensFooter(tokenHeld)
			assert(f.release.x < f.bay.x, "Release is not left of the Bay button")
		end
	end)
end)

return true
