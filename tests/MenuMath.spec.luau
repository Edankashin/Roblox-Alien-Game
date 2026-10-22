--!strict
-- Shared/MenuMath: the Menu drop-down's layout (Decision B53). Rows are never under the 44 px tap floor on any screen, the panel
-- never runs past Menu.Bottom (it scrolls), its rows tile the canvas without overlap, and the Menu button's badge is the sum of its
-- rows'. The zero-value rules (luck x1.0, Friend Boost +0%) are here because they are pure. iPhone SE (667 by 375) and an iPad
-- (1024 by 768) are the sizes the HUD is checked at.
local Shared = game:GetService("ReplicatedStorage").Shared
local MenuMath = require(Shared.MenuMath)
local Menu = require(Shared.data.Menu)

-- The drop-down's top is the Menu slot's bottom: the stack starts at 0.19 and each slot is 0.13 tall (Theme.Menu.SlotH).
-- tools/tests/test_menu_hud.py keeps these equal to the HUD's.
local DROP_TOP = 0.19 + 2 * 0.13
local ROWS = 8 -- Aliens, Codex, Ship, Quests, Gifts, Mail, Settings, Leaderboard (plus Friends, Playtime and the offer when they show)
local MOST_ROWS = 11

local SCREENS = {
	{ name = "iPhone SE", w = 667, h = 375 },
	{ name = "Studio default", w = 1154, h = 663 },
	{ name = "iPad", w = 1024, h = 768 },
	{ name = "phone portrait", w = 375, h = 667 },
}

local function layout(screen: { name: string, w: number, h: number }, rows: number): MenuMath.Layout
	local rowH = MenuMath.RowHeight(screen.h, Menu.RowHeight, Menu.MinRowPx)
	return MenuMath.Panel(rows, rowH, Menu.RowGap, Menu.Pad, Menu.Bottom - DROP_TOP)
end

describe("MenuMath.RowHeight", function()
	it("never goes under the tap floor in pixels", function()
		for _, screen in ipairs(SCREENS) do
			local rowH = MenuMath.RowHeight(screen.h, Menu.RowHeight, Menu.MinRowPx)
			assert(rowH * screen.h >= Menu.MinRowPx - 1e-9, screen.name .. ": " .. rowH * screen.h .. " px")
		end
	end)
	it("keeps the designed height where it already clears the floor", function()
		expect(MenuMath.RowHeight(663, Menu.RowHeight, Menu.MinRowPx)).toEqual(Menu.RowHeight)
	end)
	it("takes the floor on a short screen", function()
		expect(MenuMath.RowHeight(375, Menu.RowHeight, Menu.MinRowPx)).toBeClose(44 / 375, 1e-9)
	end)
	it("falls back to the design height with no screen yet", function()
		expect(MenuMath.RowHeight(0, Menu.RowHeight, Menu.MinRowPx)).toEqual(Menu.RowHeight)
	end)
end)

describe("MenuMath.Panel", function()
	it("stays above the bottom of the screen on every size", function()
		for _, screen in ipairs(SCREENS) do
			for rows = 1, 12 do
				local panel = layout(screen, rows)
				assert(DROP_TOP + panel.height <= Menu.Bottom + 1e-9, screen.name .. " with " .. rows .. " rows runs off the screen")
			end
		end
	end)
	it("fits a few rows whole and scrolls the rest", function()
		local panel = layout(SCREENS[2], 3)
		expect(panel.scrolls).toEqual(false)
		expect(panel.canvas).toBeClose(1, 1e-9)
		local many = layout(SCREENS[1], MOST_ROWS)
		expect(many.scrolls).toEqual(true)
		assert(many.canvas > 1, "a scrolling canvas is taller than its window")
	end)
	it("shows at least three whole rows on every size even with a full menu", function()
		for _, screen in ipairs(SCREENS) do
			local shown = MenuMath.RowsShown(layout(screen, MOST_ROWS))
			assert(shown >= 3, screen.name .. " shows only " .. shown .. " rows")
		end
	end)
	it("tiles its rows down the canvas without overlap", function()
		for _, screen in ipairs(SCREENS) do
			local panel = layout(screen, ROWS)
			assert(#panel.rowY == ROWS)
			for index = 2, ROWS do
				assert(panel.rowY[index] >= panel.rowY[index - 1] + panel.rowH - 1e-9, screen.name .. " row " .. index .. " overlaps")
			end
			assert(panel.rowY[ROWS] + panel.rowH <= 1 + 1e-9, screen.name .. " last row leaves the canvas")
			assert(panel.rowY[1] > 0, "the first row sits inside the padding")
		end
	end)
	it("keeps each row at least the tap floor tall in pixels, canvas and all", function()
		for _, screen in ipairs(SCREENS) do
			local panel = layout(screen, ROWS)
			local px = panel.rowH * panel.canvas * panel.height * screen.h
			assert(px >= Menu.MinRowPx - 1e-6, screen.name .. " row is " .. px .. " px")
		end
	end)
	it("is empty with no rows or no room", function()
		expect(MenuMath.Panel(0, 0.1, 0.01, 0.01, 0.5).height).toEqual(0)
		expect(MenuMath.Panel(3, 0.1, 0.01, 0.01, 0).height).toEqual(0)
	end)
end)

describe("MenuMath.PanelWidth", function()
	it("is the row's aspect in pixels, capped", function()
		local rowH = 44 / 375
		local width = MenuMath.PanelWidth(667, 375, rowH, Menu.WidthAspect, Menu.MaxWidth)
		expect(width * 667).toBeClose(44 * Menu.WidthAspect, 1e-6)
		expect(MenuMath.PanelWidth(375, 667, 44 / 667, Menu.WidthAspect, Menu.MaxWidth)).toEqual(Menu.MaxWidth)
	end)
	it("leaves the right half of every landscape screen to the world", function()
		for _, screen in ipairs(SCREENS) do
			if screen.w > screen.h then
				local rowH = MenuMath.RowHeight(screen.h, Menu.RowHeight, Menu.MinRowPx)
				local width = MenuMath.PanelWidth(screen.w, screen.h, rowH, Menu.WidthAspect, Menu.MaxWidth)
				assert(0.015 + width <= 0.5, screen.name .. " panel reaches " .. 0.015 + width)
			end
		end
	end)
end)

describe("MenuMath badges", function()
	it("adds the rows' counts for the Menu button", function()
		expect(MenuMath.BadgeTotal({ Gifts = 3, Quests = 1, Mail = 0 }, {})).toEqual(4)
	end)
	it("leaves a hidden row out", function()
		expect(MenuMath.BadgeTotal({ Gifts = 3, Playtime = 2 }, { Playtime = true })).toEqual(3)
	end)
	it("is zero with no badges", function()
		expect(MenuMath.BadgeTotal({}, {})).toEqual(0)
	end)
	it("writes the count, 99+ past two places, nothing at zero", function()
		expect(MenuMath.BadgeText(0)).toEqual("")
		expect(MenuMath.BadgeText(7)).toEqual("7")
		expect(MenuMath.BadgeText(99)).toEqual("99")
		expect(MenuMath.BadgeText(100)).toEqual("99+")
	end)
end)

describe("MenuMath zero-value lines", function()
	it("hides the luck line at x1.0, however the float lands", function()
		expect(MenuMath.LuckShown(1)).toEqual(false)
		expect(MenuMath.LuckShown(1.04)).toEqual(false)
		expect(MenuMath.LuckShown(0.96)).toEqual(false)
	end)
	it("shows the luck line once it reads x1.1 or more, or under x1.0", function()
		expect(MenuMath.LuckShown(1.05)).toEqual(true)
		expect(MenuMath.LuckShown(1.5)).toEqual(true)
		expect(MenuMath.LuckShown(0.5)).toEqual(true)
	end)
	it("hides the Friend Boost chip at +0%", function()
		expect(MenuMath.FriendBoostShown(0)).toEqual(false)
		expect(MenuMath.FriendBoostShown(0.004)).toEqual(false)
	end)
	it("shows the Friend Boost chip from +1%", function()
		expect(MenuMath.FriendBoostShown(0.05)).toEqual(true)
		expect(MenuMath.FriendBoostShown(0.005)).toEqual(true)
	end)
end)

return true
