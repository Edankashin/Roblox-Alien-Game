--!strict
-- data/PixelIcons: every icon is whole rectangles on its grid (8 by 8, Theme.Block.PixelGrid, or the finer one Grids names) with a
-- colour that is a Theme.Colors key or a six-digit hex string, and every power-up, lure and egg tier the UI shows has one (UI
-- Playbook "Block cells", "Pixel icons"). tools/tests/test_block_theme.py checks that a named colour is a real Theme.Colors key and
-- that the default grid equals Theme.Block.PixelGrid (Theme needs the Roblox runtime).
local Shared = game:GetService("ReplicatedStorage").Shared
local PixelIcons = require(Shared.data.PixelIcons)
local PowerUps = require(Shared.data.PowerUps)
local Lures = require(Shared.data.Lures)
local Tiers = require(Shared.data.Tiers)

-- The Menu's icons (Decision B53): each depicts its screen, on a 16 by 16 grid.
local MENU_ICONS = { "Shop", "Aliens", "Codex", "Ship", "Quests", "Gifts", "Settings", "Ranks", "Mail", "Menu", "Friends" }

local function whole(n: number): boolean
	return n == math.floor(n)
end

describe("PixelIcons", function()
	it("draws every icon as whole rectangles inside its grid in a known colour", function()
		for key, pixels in pairs(PixelIcons.Icons) do
			assert(#pixels > 0, key .. " is empty")
			local GRID = PixelIcons.GridOf(key)
			for index, pixel in ipairs(pixels) do
				local x, y, w, h, colour = pixel[1], pixel[2], pixel[3], pixel[4], pixel[5]
				local where = key .. " #" .. index
				assert(type(x) == "number" and type(y) == "number" and type(w) == "number" and type(h) == "number", where)
				assert(whole(x) and whole(y) and whole(w) and whole(h), where .. " is not whole pixels")
				assert(x >= 0 and y >= 0 and w >= 1 and h >= 1 and x + w <= GRID and y + h <= GRID, where .. " leaves the grid")
				assert(type(colour) == "string", where .. " has no colour")
				local hex = string.match(colour, "^%x%x%x%x%x%x$") ~= nil
				local named = string.match(colour, "^%u%a+$") ~= nil
				assert(hex or named, where .. " colour " .. colour)
			end
		end
	end)
	it("has an icon for every power-up, every lure and every egg tier", function()
		for id in pairs(PowerUps) do
			assert(PixelIcons.Icons[id] ~= nil, "power-up " .. id .. " has no pixel icon")
		end
		for _, id in ipairs(Lures.Order) do
			assert(PixelIcons.Icons[id] ~= nil, "lure " .. id .. " has no pixel icon")
		end
		assert(PixelIcons.Icons.Egg ~= nil, "no plain egg")
		for _, tier in ipairs(Tiers.Order) do
			assert(PixelIcons.Icons["Egg" .. tier] ~= nil, "no egg for " .. tier)
		end
	end)
	it("keeps the icons small: 20 frames or fewer each on 8 by 8, 70 on 16 by 16", function()
		for key, pixels in pairs(PixelIcons.Icons) do
			local limit = if PixelIcons.GridOf(key) > PixelIcons.DefaultGrid then 70 else 20
			assert(#pixels <= limit, key .. " draws " .. #pixels .. " frames")
		end
	end)
	it("names only real icons in Grids, and an icon with no entry is on the default grid", function()
		for key, grid in pairs(PixelIcons.Grids) do
			assert(PixelIcons.Icons[key] ~= nil, key .. " has a grid but no icon")
			assert(grid == 16, key .. " is on a grid of " .. grid)
		end
		assert(PixelIcons.GridOf("Scrap") == PixelIcons.DefaultGrid, "Scrap is not on the default grid")
		assert(PixelIcons.DefaultGrid == 8, "the default grid moved")
	end)
	it("has a 16 by 16 icon for every Menu screen, the Menu button itself and the Shop", function()
		for _, key in ipairs(MENU_ICONS) do
			assert(PixelIcons.Icons[key] ~= nil, key .. " has no pixel icon")
			assert(PixelIcons.GridOf(key) == 16, key .. " is not on the 16 by 16 grid")
		end
	end)
	it("covers a good share of a Menu icon's grid, so it reads (no speck)", function()
		for _, key in ipairs(MENU_ICONS) do
			local area = 0
			for _, pixel in ipairs(PixelIcons.Icons[key]) do
				area += (pixel[3] :: number) * (pixel[4] :: number)
			end
			assert(area >= 16 * 16 / 3, key .. " covers only " .. area .. " pixels")
		end
	end)
	it("has the padlock a locked Ship module row wears: 8 by 8, small, and a share of its grid covered so it reads", function()
		local lock = PixelIcons.Icons.Lock
		assert(lock ~= nil, "no Lock icon")
		expect(PixelIcons.GridOf("Lock")).toEqual(PixelIcons.DefaultGrid)
		local area = 0
		for _, pixel in ipairs(lock) do
			area += (pixel[3] :: number) * (pixel[4] :: number)
		end
		assert(area >= 8 * 8 / 2 and #lock <= 12, "the padlock covers " .. area .. " pixels in " .. #lock .. " frames")
	end)
	it("has the three marks the richness pass adds (StarChart, Robux, Check): 8 by 8, small, and covering enough to read", function()
		for _, key in ipairs({ "StarChart", "Robux", "Check" }) do
			local icon = PixelIcons.Icons[key]
			assert(icon ~= nil, "no " .. key .. " icon")
			expect(PixelIcons.GridOf(key)).toEqual(PixelIcons.DefaultGrid)
			local area = 0
			for _, pixel in ipairs(icon) do
				area += (pixel[3] :: number) * (pixel[4] :: number)
			end
			assert(area >= 8 * 8 / 3 and #icon <= 14, key .. " covers " .. area .. " pixels in " .. #icon .. " frames")
		end
	end)
	it("has an icon for every panel header (data/Panels Headers)", function()
		local Panels = require(Shared.data.Panels)
		for id, header in pairs(Panels.Headers) do
			assert(PixelIcons.Icons[header.icon] ~= nil, id .. " names the icon " .. header.icon .. ", which is not drawn")
		end
		for kind, stamp in pairs(Panels.Stamps) do
			assert(stamp.icon == "" or PixelIcons.Icons[stamp.icon] ~= nil, kind .. " stamp icon " .. stamp.icon)
		end
	end)
end)

return true
