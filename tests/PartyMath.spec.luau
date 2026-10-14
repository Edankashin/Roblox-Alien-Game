--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Party = require(Shared.PartyMath)
local Config = require(Shared.data.Config)
local F = require(script.Parent.Fixtures)

describe("PartyMath (the co-play measurement)", function()
	it("counts only the true entries of a pair row", function()
		local row = { [F.one] = true, [F.two] = false, [F.two + F.one] = true }
		expect(Party.CountFriends(row)).toEqual(F.two)
	end)
	it("a missing or empty row is no friends", function()
		expect(Party.CountFriends(nil)).toEqual(F.zero)
		expect(Party.CountFriends({})).toEqual(F.zero)
	end)
	it("a row of known non-friends is no friends", function()
		expect(Party.CountFriends({ [F.one] = false, [F.two] = false })).toEqual(F.zero)
	end)
	it("the first Party event is never held back", function()
		expect(Party.GapElapsed(nil, F.zero, Config.PartyEventGapSeconds)).toEqual(true)
	end)
	it("the next one waits for PartyEventGapSeconds, then goes", function()
		local gap = Config.PartyEventGapSeconds
		expect(Party.GapElapsed(F.one, F.one, gap)).toEqual(false)
		expect(Party.GapElapsed(F.one, F.one + gap - F.one, gap)).toEqual(false)
		expect(Party.GapElapsed(F.one, F.one + gap, gap)).toEqual(true)
	end)
end)
return true
