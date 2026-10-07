--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.PlaytimeMath)
local Data = require(Shared.data.Playtime)
local Lures = require(Shared.data.Lures)
local PowerUps = require(Shared.data.PowerUps)
local Tiers = require(Shared.data.Tiers)
local F = require(script.Parent.Fixtures)
-- Calendar expectations come from the standard UTC calendar (TZ=UTC is set by test.sh for os.time's local input),
-- independently of PlaytimeMath's own day formula.
local function at(day: number, hour: number): number
	return os.time({ year = 2026, month = F.two * F.two * F.two + F.two, day = day, hour = hour, min = F.zero, sec = F.zero })
end
local minute = os.time({ year = 2026, month = F.one, day = F.one, hour = F.zero, min = F.one, sec = F.zero })
	- os.time({ year = 2026, month = F.one, day = F.one, hour = F.zero, min = F.zero, sec = F.zero })
local hour = os.time({ year = 2026, month = F.one, day = F.one, hour = F.one, min = F.zero, sec = F.zero })
	- os.time({ year = 2026, month = F.one, day = F.one, hour = F.zero, min = F.zero, sec = F.zero })
local dayLength = at(F.two, F.zero) - at(F.one, F.zero)
local gifts = Data.Gifts
local function needed(index: number): number
	return gifts[index].minutes * minute
end
describe("PlaytimeMath", function()
	it("DayOf holds each day as [reset hour, next reset hour) for the data's hour and another", function()
		local first = F.two * F.two + F.one -- the day of the month the calendar checks start on
		for _, resetHour in ipairs({ Data.ResetHourUtc, Data.ResetHourUtc + F.two + F.one }) do
			local start = at(first, resetHour)
			local nextStart = at(first + F.one, resetHour)
			local today = Math.DayOf(start, resetHour)
			expect(Math.DayOf(start - F.one, resetHour)).toEqual(today - F.one)
			expect(Math.DayOf(nextStart - F.one, resetHour)).toEqual(today)
			expect(Math.DayOf(nextStart, resetHour)).toEqual(today + F.one)
		end
		-- The epoch, with the day starting at midnight, is day 0, and the hours before a later reset belong to the day before.
		expect(Math.DayOf(F.zero, F.zero)).toEqual(F.zero)
		expect(Math.DayOf(F.zero, F.one)).toEqual(-F.one)
		expect(Math.DayOf(hour, F.one)).toEqual(F.zero)
	end)
	it("IsUnlocked opens each gift at its minutes and holds out-of-range indexes locked", function()
		for index = 1, #gifts do
			expect(Math.IsUnlocked(needed(index) - F.one, index)).toEqual(false)
			expect(Math.IsUnlocked(needed(index), index)).toEqual(true)
			expect(Math.IsUnlocked(needed(index) + minute, index)).toEqual(true)
		end
		expect(Math.IsUnlocked(needed(#gifts), F.zero)).toEqual(false)
		expect(Math.IsUnlocked(needed(#gifts), #gifts + F.one)).toEqual(false)
	end)
	it("NextGift names the first locked gift and what it still needs, then nothing past the last", function()
		local index, left = Math.NextGift(F.zero, {})
		expect(index).toEqual(F.one)
		expect(left).toEqual(needed(F.one))
		for gift = 1, #gifts - F.one do
			index, left = Math.NextGift(needed(gift), {})
			expect(index).toEqual(gift + F.one)
			expect(left).toEqual(needed(gift + F.one) - needed(gift))
		end
		index, left = Math.NextGift(needed(#gifts) - F.one, {})
		expect(index).toEqual(#gifts)
		expect(left).toEqual(F.one)
		index, left = Math.NextGift(needed(#gifts), {})
		expect(index).toEqual(nil)
		expect(left).toEqual(nil)
	end)
	it("ReadyCount counts unlocked gifts that are not claimed", function()
		expect(Math.ReadyCount(F.zero, {})).toEqual(F.zero)
		expect(Math.ReadyCount(needed(F.one), {})).toEqual(F.one)
		expect(Math.ReadyCount(needed(F.two + F.one), {})).toEqual(F.two + F.one)
		expect(Math.ReadyCount(needed(F.two + F.one), { [Math.Key(F.one)] = true })).toEqual(F.two)
		-- A claim entry for a gift that is still locked takes nothing from the count.
		expect(Math.ReadyCount(needed(F.one), { [Math.Key(#gifts)] = true })).toEqual(F.one)
		local all: { [string]: boolean } = {}
		for index = 1, #gifts do
			all[Math.Key(index)] = true
		end
		expect(Math.ReadyCount(needed(#gifts), all)).toEqual(F.zero)
		expect(Math.ReadyCount(needed(#gifts), {})).toEqual(#gifts)
	end)
	it("the data's gifts rise in minutes, land on a server tick and name rewards that exist", function()
		expect(#gifts > F.zero).toEqual(true)
		expect(Data.TickSeconds > F.zero).toEqual(true)
		expect(Data.ResetHourUtc >= F.zero and Data.ResetHourUtc * hour < dayLength).toEqual(true)
		local previous = F.zero
		for index, gift in ipairs(gifts) do
			expect(gift.minutes > previous).toEqual(true)
			previous = gift.minutes
			expect(needed(index) % Data.TickSeconds).toEqual(F.zero)
			expect(gift.reward.amount > F.zero).toEqual(true)
			local reward = gift.reward
			if reward.kind == "lure" then
				expect(Lures.Lures[reward.id or ""] ~= nil).toEqual(true)
			elseif reward.kind == "powerUp" then
				expect(PowerUps[reward.id or ""] ~= nil).toEqual(true)
			elseif reward.kind == "egg" then
				expect(Tiers.Tiers[reward.tier or ""] ~= nil).toEqual(true)
			end
		end
	end)
end)
return true
