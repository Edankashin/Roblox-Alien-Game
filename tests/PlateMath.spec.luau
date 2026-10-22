--!strict
-- Shared.PlateMath: a wild nameplate's size clamp (Client.World.WildRenderer, data/Config NameplateMaxScreenShare). The plate is
-- 7 by 2 studs; Roblox's default camera field of view is 70 degrees.
local Shared = game:GetService("ReplicatedStorage").Shared
local PlateMath = require(Shared.PlateMath)
local Config = require(Shared.data.Config)

local STUDS_TALL = 2
local FOV = 70
local SHARE = Config.NameplateMaxScreenShare
local MIN = Config.NameplateMinScale

describe("PlateMath", function()
	it("leaves a plate at range exactly as it was (readable as before)", function()
		for _, distance in ipairs({ 15, 20, 40, Config.NameplateDistance }) do
			expect(PlateMath.Scale(distance, STUDS_TALL, FOV, SHARE, MIN)).toEqual(1)
		end
	end)
	it("holds a near plate at the share of the screen, whatever the distance inside the clamp", function()
		for _, distance in ipairs({ 0.5, 1, 3, 6, 10 }) do
			local scale = PlateMath.Scale(distance, STUDS_TALL, FOV, SHARE, MIN)
			assert(scale < 1, "no clamp at " .. distance)
			local share = PlateMath.Share(distance, STUDS_TALL * scale, FOV)
			assert(math.abs(share - SHARE) < 1e-9 or scale == MIN, "share " .. share .. " at " .. distance)
		end
	end)
	it("is continuous where the clamp starts and never grows as the camera comes closer", function()
		local edge = STUDS_TALL / (2 * math.tan(math.rad(FOV) / 2) * SHARE)
		expect(math.abs(PlateMath.Scale(edge * 0.999, STUDS_TALL, FOV, SHARE, MIN) - 1) < 0.01).toEqual(true)
		local last = math.huge
		for step = 600, 1, -1 do
			local distance = step / 10
			local scale = PlateMath.Scale(distance, STUDS_TALL, FOV, SHARE, MIN)
			local px = PlateMath.Share(distance, STUDS_TALL * scale, FOV)
			-- under about 0.7 studs (the camera nearly inside the plate) the floor scale holds instead
			assert(px <= SHARE + 1e-9 or scale == MIN, "taller than the share at " .. distance)
			assert(scale <= last + 1e-12, "the scale grew at " .. distance)
			last = scale
		end
	end)
	it("keeps both lines over the 14 px floor at the clamp on an iPhone SE (375 px tall)", function()
		-- WildRenderer: the name is 0.55 of the plate, the tier line 0.45.
		local plate = SHARE * 375
		assert(0.45 * plate >= 14, "the tier line is " .. 0.45 * plate .. " px")
	end)
	it("never answers under the floor scale, nor for a camera inside the plate", function()
		expect(PlateMath.Scale(0, STUDS_TALL, FOV, SHARE, MIN)).toEqual(MIN)
		expect(PlateMath.Scale(-1, STUDS_TALL, FOV, SHARE, MIN)).toEqual(MIN)
	end)
end)
return true
