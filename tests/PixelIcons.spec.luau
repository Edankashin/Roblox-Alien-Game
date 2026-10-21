--!strict
-- data/PixelIcons: every icon is whole rectangles on the 8 by 8 grid (Theme.Block.PixelGrid) with a colour that is a Theme.Colors
-- key or a six-digit hex string, and every power-up, lure and egg tier the UI shows has one (UI Playbook "Block cells", "Pixel
-- icons"). tools/tests/test_block_theme.py checks that a named colour is a real Theme.Colors key (Theme needs the Roblox runtime).
local Shared = game:GetService("ReplicatedStorage").Shared
local PixelIcons = require(Shared.data.PixelIcons)
local PowerUps = require(Shared.data.PowerUps)
local Lures = require(Shared.data.Lures)
local Tiers = require(Shared.data.Tiers)

local GRID = 8

local function whole(n: number): boolean
	return n == math.floor(n)
end

describe("PixelIcons", function()
	it("draws every icon as whole rectangles inside the 8 by 8 grid in a known colour", function()
		for key, pixels in pairs(PixelIcons.Icons) do
			assert(#pixels > 0, key .. " is empty")
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
	it("keeps the new icons small: 20 frames or fewer each", function()
		for key, pixels in pairs(PixelIcons.Icons) do
			assert(#pixels <= 20, key .. " draws " .. #pixels .. " frames")
		end
	end)
end)

return true
