--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.WeeklyMath)
local Data = require(Shared.data.Weekly)
local Species = require(Shared.data.Species)
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
