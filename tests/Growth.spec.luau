--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Growth = require(Shared.Growth)
local Data = require(Shared.data.Growth)
local F = require(script.Parent.Fixtures)
local hatchling, grown, elder = Data.ById.Hatchling, Data.ById.Grown, Data.ById.Elder
describe("Growth", function()
	for name, row in pairs({
		initial = { hatchling.workedSeconds, hatchling },
		beforeGrown = { grown.workedSeconds - F.tick, hatchling },
		atGrown = { grown.workedSeconds, grown },
		beforeElder = { elder.workedSeconds - F.tick, grown },
		atElder = { elder.workedSeconds, elder },
	}) do
		it("StageAt " .. name, function()
			expect(Growth.StageAt(row[F.one])).toEqual(row[F.two])
		end)
	end
	it("Next follows stage order and ends at nil", function()
		expect(Growth.Next(hatchling)).toEqual(grown)
		expect(Growth.Next(grown)).toEqual(elder)
		expect(Growth.Next(elder)).toEqual(nil)
	end)
	it("SecondsToNext follows thresholds and ends at nil", function()
		expect(Growth.SecondsToNext(hatchling.workedSeconds)).toEqual(grown.workedSeconds - hatchling.workedSeconds)
		expect(Growth.SecondsToNext(grown.workedSeconds - F.tick)).toEqual(F.tick)
		expect(Growth.SecondsToNext(grown.workedSeconds)).toEqual(elder.workedSeconds - grown.workedSeconds)
		expect(Growth.SecondsToNext(elder.workedSeconds)).toEqual(nil)
	end)
end)
return true
