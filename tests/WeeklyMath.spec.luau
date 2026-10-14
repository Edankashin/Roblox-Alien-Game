--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.WeeklyMath)
local Data = require(Shared.data.Weekly)
local Species = require(Shared.data.Species)
local Spawns = require(Shared.data.Spawns)
local Leaderboard = require(Shared.data.Leaderboard)
local F = require(script.Parent.Fixtures)
local week = F.advanceReset(Data.Epoch, F.one) - Data.Epoch
describe("WeeklyMath", function()
	it("epoch starts rotation and full rotation wraps", function()
		expect(Math.IndexAt(Data.Epoch)).toEqual(F.one)
		expect(Math.IndexAt(Data.Epoch + week * #Data.Rotation)).toEqual(F.one)
		expect(Math.IndexAt(Data.Epoch, -F.one)).toEqual(#Data.Rotation)
		expect(Math.IndexAt(Data.Epoch - week)).toEqual(#Data.Rotation)
	end)
	it("Current flips at the configured Friday boundary", function()
		local before = Math.Current(Data.Epoch - F.one)
		local at = Math.Current(Data.Epoch)
		expect(before.drop).toEqual(Data.Rotation[#Data.Rotation])
		expect(before.secondsLeft).toEqual(F.one)
		expect(at.drop).toEqual(Data.Rotation[F.one])
		expect(at.weekStart).toEqual(Data.Epoch)
		expect(at.secondsLeft).toEqual(week)
	end)
	it("dated override wins only at zero or omitted offset", function()
		local id = os.date("!%Y-%m-%d", Data.Epoch)
		local saved = Data.Overrides[id]
		local override = table.clone(Data.Rotation[#Data.Rotation])
		override.limited = true
		Data.Overrides[id] = override
		local current = Math.Current(Data.Epoch)
		local zero = Math.Current(Data.Epoch, F.zero)
		local shifted = Math.Current(Data.Epoch, F.one)
		local limited = Math.IsLimited(override.species)
		Data.Overrides[id] = saved
		expect(current.drop).toEqual(override)
		expect(zero.drop).toEqual(override)
		expect(current.index).toEqual(F.zero)
		expect(shifted.drop).toEqual(Data.Rotation[F.two])
		expect(limited).toEqual(true)
	end)
	it("launch week carries a World 1 drop only for its own week", function()
		local key = "2026-10-16"
		local drop = Data.Overrides[key]
		local launchStart = os.time({ year = 2026, month = 10, day = 16, hour = Leaderboard.ResetHourUtc }) -- TZ=UTC in test.sh
		local rotationBefore = Math.Current(launchStart - F.one)
		local first = Math.Current(launchStart)
		local last = Math.Current(launchStart + week - F.one)
		local after = Math.Current(launchStart + week)
		expect(drop ~= nil).toEqual(true)
		expect(os.date("!%Y-%m-%d", launchStart)).toEqual(key)
		expect(first.weekId).toEqual(key)
		expect(first.drop).toEqual(drop)
		expect(first.index).toEqual(F.zero)
		expect(last.drop).toEqual(drop)
		expect(last.secondsLeft).toEqual(F.one)
		expect(rotationBefore.drop).toEqual(Data.Rotation[rotationBefore.index])
		expect(rotationBefore.index > F.zero).toEqual(true)
		expect(after.drop).toEqual(Data.Rotation[after.index])
		expect(after.index > F.zero).toEqual(true)
		-- a shifted rotation never lands on the override (the offset steps the rotation, the override is dated)
		expect(Math.Current(launchStart, F.one).index > F.zero).toEqual(true)
	end)
	it("the launch drop is a reachable World 1 Rare or Uncommon, featured and not limited", function()
		local drop = Data.Overrides["2026-10-16"]
		local def = Species.ById[drop.species]
		local inMeadow = false
		for _, list in pairs(Spawns.Biomes.Meadow) do
			inMeadow = inMeadow or table.find(list, drop.species) ~= nil
		end
		expect(def ~= nil).toEqual(true)
		expect(drop.worldId).toEqual(F.one)
		expect(def.world).toEqual(F.one)
		expect(def.tier == "Rare" or def.tier == "Uncommon").toEqual(true)
		expect(inMeadow).toEqual(true)
		expect(drop.limited).toEqual(false)
		expect(Math.IsLimited(drop.species)).toEqual(false)
		expect(drop.weather == nil and drop.overlay == nil).toEqual(true)
	end)
	it("IsLimited and IsCurrent cover every species", function()
		for _, species in ipairs(Species.List) do
			local limited = false
			for _, row in ipairs(Data.Rotation) do
				limited = limited or (row.species == species.id and row.limited)
			end
			for _, row in pairs(Data.Overrides) do
				limited = limited or (row.species == species.id and row.limited)
			end
			expect(Math.IsLimited(species.id)).toEqual(limited)
			expect(Math.IsCurrent(species.id, Data.Epoch)).toEqual(species.id == Data.Rotation[F.one].species)
		end
		expect(Math.IsLimited("NoSuchSpecies")).toEqual(false)
		expect(Math.IsCurrent("NoSuchSpecies", Data.Epoch)).toEqual(false)
	end)
end)
return true
