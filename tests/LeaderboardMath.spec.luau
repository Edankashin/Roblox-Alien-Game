--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.LeaderboardMath)
local Data = require(Shared.data.Leaderboard)
local Config = require(Shared.data.Config)
local F = require(script.Parent.Fixtures)
local previous = F.advanceReset(F.boundary, -F.one)
local nextReset = F.advanceReset(F.boundary, F.one)
describe("LeaderboardMath", function()
	for name, row in pairs({
		previousDay = { F.boundary - Config.GiftDaySeconds, previous },
		beforeHour = { F.boundary - F.tick, previous },
		atHour = { F.boundary, F.boundary },
		afterHour = { F.boundary + F.tick, F.boundary },
		nextDay = { F.boundary + Config.GiftDaySeconds, F.boundary },
		nextWeek = { nextReset, nextReset },
	}) do
		it("period start and id " .. name, function()
			local now, expected = row[F.one], row[F.two]
			expect(Math.PeriodStart(now)).toEqual(expected)
			expect(Math.PeriodId(now)).toEqual(os.date("!%Y-%m-%d", expected))
			expect(Math.StoreKey(now)).toEqual(Data.StoreName .. "_" .. os.date("!%Y-%m-%d", expected))
		end)
	end
	it("NextReset advances strictly across the reset", function()
		expect(Math.NextReset(F.boundary - F.tick)).toEqual(F.boundary)
		expect(Math.NextReset(F.boundary)).toEqual(nextReset)
	end)
end)
return true
