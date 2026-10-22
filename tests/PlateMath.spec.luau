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

describe("PlateMath.StackLifts", function()
	local RADIUS, STEP = Config.NameplateStackRadiusStuds, Config.NameplateStackStepStuds
	it("leaves a lone alien and a far pair where they were", function()
		expect(PlateMath.StackLifts({ 0 }, { 0 }, RADIUS, STEP)[1]).toEqual(0)
		local lifts = PlateMath.StackLifts({ 0, RADIUS + 1 }, { 0, 0 }, RADIUS, STEP)
		expect(lifts[1]).toEqual(0)
		expect(lifts[2]).toEqual(0)
	end)
	it("lifts the later of two side-by-side aliens one step, never the first", function()
		local lifts = PlateMath.StackLifts({ 0, 3 }, { 0, 0 }, RADIUS, STEP)
		expect(lifts[1]).toEqual(0)
		expect(lifts[2]).toEqual(STEP)
	end)
	it("stacks three in a clump one step apart, and the step clears a plate's height", function()
		local lifts = PlateMath.StackLifts({ 0, 2, 1 }, { 0, 1, 3 }, RADIUS, STEP)
		expect(lifts[1]).toEqual(0)
		expect(lifts[2]).toEqual(STEP)
		expect(lifts[3]).toEqual(2 * STEP)
		assert(STEP > Config.NameplateStudsH, "a step is shorter than a plate")
	end)
end)
describe("PlateMath.Shown (the clean HUD's nameplate budget)", function()
	local HudData = require(Shared.data.Hud)
	local P = HudData.Plates
	local function shown(distances: { number }): { boolean }
		return PlateMath.Shown(distances, P.MaxShown, P.AlwaysStuds, Config.NameplateDistance)
	end
	local function count(flags: { boolean }): number
		local n = 0
		for _, flag in ipairs(flags) do
			if flag then
				n += 1
			end
		end
		return n
	end
	it("shows a lone alien in range and none out of range", function()
		expect(shown({ 40 })[1]).toEqual(true)
		expect(shown({ Config.NameplateDistance + 1 })[1]).toEqual(false)
		expect(shown({ math.huge })[1]).toEqual(false)
	end)
	it("shows the nearest five and no more when they stand beyond 15 studs", function()
		local flags = shown({ 50, 20, 40, 25, 55, 22, 35, 30 })
		expect(count(flags)).toEqual(P.MaxShown)
		-- the five nearest are 20, 22, 25, 30 and 35
		expect(flags[2]).toEqual(true)
		expect(flags[6]).toEqual(true)
		expect(flags[4]).toEqual(true)
		expect(flags[8]).toEqual(true)
		expect(flags[7]).toEqual(true)
		expect(flags[1]).toEqual(false)
		expect(flags[3]).toEqual(false)
		expect(flags[5]).toEqual(false)
	end)
	it("shows every alien within 15 studs even past five", function()
		local flags = shown({ 3, 4, 5, 6, 7, 8, 9, 40, 41 })
		for index = 1, 7 do
			expect(flags[index]).toEqual(true)
		end
		expect(flags[8]).toEqual(false)
		expect(flags[9]).toEqual(false)
	end)
	it("lets a far alien in when fewer than five stand near", function()
		local flags = shown({ 5, 6, 50 })
		expect(count(flags)).toEqual(3)
	end)
	it("keeps the order of two aliens at the same distance, so the choice never flickers", function()
		local flags = PlateMath.Shown({ 30, 30, 30 }, 2, 15, 60)
		expect(flags[1]).toEqual(true)
		expect(flags[2]).toEqual(true)
		expect(flags[3]).toEqual(false)
	end)
	it("a hidden alien takes no place", function()
		local flags = PlateMath.Shown({ math.huge, 30, 31, 32, 33, 34 }, 5, 15, 60)
		expect(flags[1]).toEqual(false)
		expect(count(flags)).toEqual(5)
	end)
	it("shows the tier line only within its distance, and a node's plate by the marker rule", function()
		expect(PlateMath.TierShown(P.TierStuds, P.TierStuds)).toEqual(true)
		expect(PlateMath.TierShown(P.TierStuds + 0.1, P.TierStuds)).toEqual(false)
		expect(PlateMath.NodeRange(false, P.NodeStuds, P.NodeTargetStuds)).toEqual(P.NodeStuds)
		expect(PlateMath.NodeRange(true, P.NodeStuds, P.NodeTargetStuds)).toEqual(P.NodeTargetStuds)
		assert(P.NodeTargetStuds > Config.NameplateDistance, "a marker's node is not farther than a wild plate")
	end)
	it("keeps the budget inside the plate's own range", function()
		assert(P.AlwaysStuds <= P.TierStuds and P.TierStuds <= Config.NameplateDistance, "the distances are out of order")
		assert(P.NodeStuds <= Config.NameplateDistance, "a node's plate is drawn farther than a wild one")
	end)
end)

return true
