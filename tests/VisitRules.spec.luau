--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Rules = require(Shared.VisitRules)
local Data = require(Shared.data.Visiting)
local Config = require(Shared.data.Config)
local F = require(script.Parent.Fixtures)
local owner = F.one
local viewer = F.two
local day = Config.GiftDaySeconds
local now = day * F.two + F.tick -- inside the third day
describe("VisitRules", function()
	it("DayOf counts whole gift days from the epoch", function()
		expect(Rules.DayOf(F.zero)).toEqual(F.zero)
		expect(Rules.DayOf(day - F.one)).toEqual(F.zero)
		expect(Rules.DayOf(day)).toEqual(F.one)
		expect(Rules.DayOf(now)).toEqual(F.two)
	end)
	for name, row in pairs({
		ownerAtOwnerOnly = { Data.LockOwnerOnly, owner, false, true, nil },
		strangerAtOwnerOnly = { Data.LockOwnerOnly, viewer, true, false, "OwnerOnly" },
		friendAtFriends = { Data.LockFriends, viewer, true, true, nil },
		strangerAtFriends = { Data.LockFriends, viewer, false, false, "FriendsOnly" },
		strangerAtAnyone = { Data.LockAnyone, viewer, false, true, nil },
		unknownLock = { Data.LockAnyone + F.one, viewer, true, false, "OwnerOnly" },
	}) do
		it("CanVisit " .. name, function()
			local ok, reason = Rules.CanVisit(row[F.one], row[F.two], owner, row[F.two + F.one])
			expect(ok).toEqual(row[F.two + F.two])
			expect(reason).toEqual(row[F.two + F.two + F.one])
		end)
	end
	it("WavesLeft is the allowance on a new day and what is left on the same day", function()
		local fresh = { day = F.zero, sent = Data.WavesPerDay, got = F.zero }
		expect(Rules.WavesLeft(fresh, now)).toEqual(Data.WavesPerDay)
		local today = { day = Rules.DayOf(now), sent = F.one, got = F.zero }
		expect(Rules.WavesLeft(today, now)).toEqual(Data.WavesPerDay - F.one)
		local spent = { day = Rules.DayOf(now), sent = Data.WavesPerDay + F.one, got = F.zero }
		expect(Rules.WavesLeft(spent, now)).toEqual(F.zero)
	end)
	it("AfterWave starts a new day over and adds on the same day", function()
		local rolled = Rules.AfterWave({ day = F.zero, sent = F.two, got = F.two }, now)
		expect(rolled.day).toEqual(Rules.DayOf(now))
		expect(rolled.sent).toEqual(F.one)
		expect(rolled.got).toEqual(F.zero)
		local same = Rules.AfterWave(rolled, now)
		expect(same.sent).toEqual(F.two)
		expect(same.got).toEqual(F.zero)
	end)
	it("OwnerRoom and AfterGot keep the daily cap", function()
		local tally = { day = Rules.DayOf(now), sent = F.zero, got = F.zero }
		expect(Rules.OwnerRoom(tally, now)).toEqual(Data.WaveOwnerScrapCapPerDay)
		local paid = Rules.AfterGot(tally, now, Data.WaveScrapOwner)
		expect(paid.got).toEqual(Data.WaveScrapOwner)
		expect(Rules.OwnerRoom(paid, now)).toEqual(Data.WaveOwnerScrapCapPerDay - Data.WaveScrapOwner)
		local full = Rules.AfterGot(tally, now, Data.WaveOwnerScrapCapPerDay + F.one)
		expect(Rules.OwnerRoom(full, now)).toEqual(F.zero)
		local rolled = Rules.AfterGot({ day = F.zero, sent = F.two, got = F.two }, now, Data.WaveScrapOwner)
		expect(rolled.sent).toEqual(F.zero)
		expect(rolled.got).toEqual(Data.WaveScrapOwner)
	end)
	it("InboxRoom and AfterInboxWave keep the daily cap and count the waves", function()
		local waves = { day = F.zero, count = F.two, scrap = Data.WaveOwnerScrapCapPerDay }
		expect(Rules.InboxRoom(waves, now)).toEqual(Data.WaveOwnerScrapCapPerDay)
		local first = Rules.AfterInboxWave(waves, now, Data.WaveScrapOwner)
		expect(first.day).toEqual(Rules.DayOf(now))
		expect(first.count).toEqual(F.one)
		expect(first.scrap).toEqual(Data.WaveScrapOwner)
		local second = Rules.AfterInboxWave(first, now, Data.WaveScrapOwner)
		expect(second.count).toEqual(F.two)
		expect(Rules.InboxRoom(second, now)).toEqual(Data.WaveOwnerScrapCapPerDay - Data.WaveScrapOwner * F.two)
	end)
end)
return true
