--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.OutpostMath)
local Data = require(Shared.data.Outposts)
local Materials = require(Shared.data.KeyMaterials)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local F = require(script.Parent.Fixtures)
local world = Worlds[F.one].id
local level = Data.Levels[F.one]
-- This interval is exactly one hour in the live config; derive a calendar hour
-- independently so changes to the offline cap do not alter the units.
local date = os.date("!*t", F.zero)
date.hour += F.one
local hour = os.time(date) - F.zero
local state = { level = F.one, lastCollect = F.boundary }
describe("OutpostMath", function()
	it("Yield includes exactly this world's non-excluded node materials", function()
		local ids = Math.Yield(world)
		local expected = {}
		for id, row in pairs(Materials) do
			if row.world == world and row.nodes > F.zero and not table.find(Data.ExcludedConditions, row.condition) then
				table.insert(expected, id)
			end
		end
		table.sort(expected)
		expect(table.concat(ids, ",")).toEqual(table.concat(expected, ","))
	end)
	it("levels clamp and terminal upgrade is nil", function()
		expect(Math.Level(F.zero)).toEqual(level)
		expect(Math.MaxLevel()).toEqual(#Data.Levels)
		expect(Math.Level(#Data.Levels + F.one)).toEqual(Data.Levels[#Data.Levels])
		expect(Math.UpgradeCost(F.one)).toEqual(level.upgradeScrap)
		expect(Math.UpgradeCost(#Data.Levels)).toEqual(nil)
	end)
	for name, elapsed in pairs({ before = -F.tick, at = F.zero, hour = hour, cap = Data.CollectCapSeconds, beyond = Data.CollectCapSeconds + Config.GiftDaySeconds }) do
		it("Pending production " .. name, function()
			local result = Math.Pending(state, world, state.lastCollect + elapsed)
			local counted = math.clamp(elapsed, F.zero, Data.CollectCapSeconds)
			expect(result.seconds).toEqual(counted)
			expect(result.scrap).toEqual(math.floor(counted / hour * level.scrapPerHour))
			expect(result.materialCount).toEqual(math.floor(counted / hour * level.materialsPerHour))
			local sum, low, high = F.zero, math.huge, F.zero
			for _, id in ipairs(Math.Yield(world)) do
				local amount = result.materials[id] or F.zero
				sum += amount; low = math.min(low, amount); high = math.max(high, amount)
			end
			expect(sum).toEqual(result.materialCount)
			expect(high - low <= F.one).toEqual(true)
		end)
	end
end)
return true
