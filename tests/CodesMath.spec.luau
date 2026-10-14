--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.CodesMath)
local Data = require(Shared.data.Codes)
local Gifts = require(Shared.data.Gifts)
local PowerUps = require(Shared.data.PowerUps)
local F = require(script.Parent.Fixtures)

-- Calendar expectations come from the standard UTC calendar (TZ=UTC is set by test.sh for os.time's local input),
-- independently of the numbers in the data table.
local function utc(month: number, day: number, hour: number, min: number, sec: number): number
	return os.time({ year = 2026, month = month, day = day, hour = hour, min = min, sec = sec })
end

describe("CodesMath", function()
	it("a code with no window works at any time", function()
		local window = { expiresAt = F.zero }
		expect(Math.Status(window, F.zero)).toEqual("Active")
		expect(Math.Status(window, utc(12, 31, 23, 59, 59))).toEqual("Active")
	end)
	it("startsAt is the first good second, expiresAt the last", function()
		local window = { startsAt = utc(10, 16, 0, 0, 0), expiresAt = utc(10, 31, 23, 59, 59) }
		expect(Math.Status(window, window.startsAt - F.one)).toEqual("NotYet")
		expect(Math.Status(window, window.startsAt)).toEqual("Active")
		expect(Math.Status(window, window.expiresAt)).toEqual("Active")
		expect(Math.Status(window, window.expiresAt + F.one)).toEqual("Expired")
	end)
	it("an expiry alone and a start alone each hold their side only", function()
		local expiring = { expiresAt = utc(10, 31, 23, 59, 59) }
		expect(Math.Status(expiring, F.zero)).toEqual("Active")
		expect(Math.Status(expiring, expiring.expiresAt + F.one)).toEqual("Expired")
		local late = { startsAt = utc(10, 16, 0, 0, 0), expiresAt = F.zero }
		expect(Math.Status(late, late.startsAt - F.one)).toEqual("NotYet")
		expect(Math.Status(late, utc(12, 31, 23, 59, 59))).toEqual("Active")
	end)
	it("LAUNCHWEEK is live from 2026-10-16 00:00 UTC to the end of 2026-10-31 UTC", function()
		local code = Data.Codes.LAUNCHWEEK
		expect(code ~= nil).toEqual(true)
		expect(Math.Status(code, utc(10, 15, 23, 59, 59))).toEqual("NotYet")
		expect(Math.Status(code, utc(10, 16, 0, 0, 0))).toEqual("Active")
		expect(Math.Status(code, utc(10, 31, 23, 59, 59))).toEqual("Active")
		expect(Math.Status(code, utc(11, 1, 0, 0, 0))).toEqual("Expired")
	end)
	it("LAUNCHWEEK pays 300 Scrap and one Lucky Charm", function()
		local rewards = Data.Codes.LAUNCHWEEK.rewards
		expect(#rewards).toEqual(F.one + F.one)
		expect(rewards[F.one].kind).toEqual("scrap")
		expect(rewards[F.one].amount).toEqual(300)
		expect(rewards[F.one + F.one].kind).toEqual("powerUp")
		expect(rewards[F.one + F.one].id).toEqual("LuckyCharm")
		expect(rewards[F.one + F.one].amount).toEqual(F.one)
		expect(PowerUps.LuckyCharm ~= nil).toEqual(true)
	end)
	it("every code's window is well formed: a start comes before a deadline", function()
		for name, code in pairs(Data.Codes) do
			assert(code.expiresAt >= F.zero, name .. ": negative expiresAt")
			local startsAt = code.startsAt
			if startsAt ~= nil and code.expiresAt > F.zero then
				assert(startsAt < code.expiresAt, name .. ": startsAt is not before expiresAt")
			end
		end
	end)
end)

-- Welcome Week day 2 is the two boosts a player saves for the next session.
describe("Welcome Week day 2", function()
	it("pays one Speed Burst with one Lucky Charm alongside, both power-ups the data knows", function()
		local row = Gifts[F.two]
		expect(row.day).toEqual(F.two)
		expect(row.reward.kind).toEqual("powerUp")
		expect(row.reward.id).toEqual("SpeedBurst")
		expect(row.reward.amount).toEqual(F.one)
		local also = row.also
		assert(also ~= nil and #also == F.one, "day 2 should carry exactly one extra reward")
		expect(also[F.one].kind).toEqual("powerUp")
		expect(also[F.one].id).toEqual("LuckyCharm")
		expect(also[F.one].amount).toEqual(F.one)
		expect(PowerUps.SpeedBurst ~= nil and PowerUps.LuckyCharm ~= nil).toEqual(true)
	end)
	it("day 7's Epic Egg is still the last gift", function()
		local last = Gifts[#Gifts]
		expect(last.day).toEqual(#Gifts)
		expect(last.reward.kind).toEqual("egg")
		expect(last.reward.tier).toEqual("Epic")
	end)
end)
return true
