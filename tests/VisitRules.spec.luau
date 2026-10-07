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

describe("VisitRules.IsOwnerId (VisitHome's argument)", function()
	local nan = F.zero / F.zero
	local inf = F.one / F.zero
	local largest = Data.MaxUserId
	it("takes whole numbers from 1 to MaxUserId", function()
		expect(Rules.IsOwnerId(F.one, false)).toEqual(true)
		expect(Rules.IsOwnerId(owner, false)).toEqual(true)
		expect(Rules.IsOwnerId(largest, false)).toEqual(true)
	end)
	it("refuses anything past MaxUserId", function()
		expect(Rules.IsOwnerId(largest + F.one, false)).toEqual(false)
		expect(Rules.IsOwnerId(largest * F.two, false)).toEqual(false)
		expect(Rules.IsOwnerId(inf, false)).toEqual(false)
	end)
	it("refuses zero, fractions, NaN and what is not a number", function()
		expect(Rules.IsOwnerId(F.zero, true)).toEqual(false)
		expect(Rules.IsOwnerId(F.half, true)).toEqual(false)
		expect(Rules.IsOwnerId(owner + F.half, true)).toEqual(false)
		expect(Rules.IsOwnerId(nan, true)).toEqual(false)
		expect(Rules.IsOwnerId("1", true)).toEqual(false)
		expect(Rules.IsOwnerId(nil, true)).toEqual(false)
		expect(Rules.IsOwnerId({}, true)).toEqual(false)
	end)
	it("takes negative test-player ids only when Studio allows them", function()
		expect(Rules.IsOwnerId(-F.one, false)).toEqual(false)
		expect(Rules.IsOwnerId(-largest, false)).toEqual(false)
		expect(Rules.IsOwnerId(-F.one, true)).toEqual(true)
		expect(Rules.IsOwnerId(-F.two, true)).toEqual(true)
		expect(Rules.IsOwnerId(-largest, true)).toEqual(true)
		expect(Rules.IsOwnerId(-largest - F.one, true)).toEqual(false)
		expect(Rules.IsOwnerId(-inf, true)).toEqual(false)
	end)
end)

describe("VisitRules visit requests (the friend check yields)", function()
	it("numbers each visitor's requests one after the other", function()
		local book = {}
		expect(Rules.NextRequest(book, viewer)).toEqual(F.one)
		expect(Rules.NextRequest(book, viewer)).toEqual(F.two)
		expect(Rules.NextRequest(book, owner)).toEqual(F.one)
	end)
	it("only the newest request is still wanted when its check returns", function()
		local book = {}
		local first = Rules.NextRequest(book, viewer)
		local second = Rules.NextRequest(book, viewer)
		expect(Rules.IsLatestRequest(book, viewer, first)).toEqual(false)
		expect(Rules.IsLatestRequest(book, viewer, second)).toEqual(true)
	end)
	it("requests that finish out of order leave the newest one in charge", function()
		local book = {}
		local toFriend = Rules.NextRequest(book, viewer) -- asked first, finishes last
		local toStranger = Rules.NextRequest(book, viewer)
		expect(Rules.IsLatestRequest(book, viewer, toStranger)).toEqual(true)
		expect(Rules.IsLatestRequest(book, viewer, toFriend)).toEqual(false)
	end)
	it("a leave takes a number too, so a request waiting at the time ends without a view", function()
		local book = {}
		local waiting = Rules.NextRequest(book, viewer)
		Rules.NextRequest(book, viewer) -- LeaveView
		expect(Rules.IsLatestRequest(book, viewer, waiting)).toEqual(false)
	end)
	it("one visitor's requests do not replace another's", function()
		local book = {}
		local mine = Rules.NextRequest(book, viewer)
		Rules.NextRequest(book, owner)
		expect(Rules.IsLatestRequest(book, viewer, mine)).toEqual(true)
	end)
	it("a visitor who left (no number kept) has no request left to finish", function()
		local book = {}
		local waiting = Rules.NextRequest(book, viewer)
		book[viewer] = nil
		expect(Rules.IsLatestRequest(book, viewer, waiting)).toEqual(false)
	end)
end)

describe("VisitRules waved book (once per alien per owner per day)", function()
	local uid = "alien-a"
	local other = "alien-b"
	it("nothing is waved at before the first wave", function()
		expect(Rules.HasWaved(nil, now, owner, uid)).toEqual(false)
	end)
	it("a wave marks that alien of that owner and no other", function()
		local book = Rules.MarkWaved(nil, now, owner, uid)
		expect(Rules.HasWaved(book, now, owner, uid)).toEqual(true)
		expect(Rules.HasWaved(book, now, owner, other)).toEqual(false)
		expect(Rules.HasWaved(book, now, viewer, uid)).toEqual(false)
	end)
	it("leaving and coming back the same day does not reset it (the book is kept, not cleared per visit)", function()
		local book = Rules.MarkWaved(nil, now, owner, uid)
		book = Rules.MarkWaved(book, now + F.tick, viewer, other) -- a visit to someone else in between
		expect(Rules.HasWaved(book, now + F.tick, owner, uid)).toEqual(true)
		expect(Rules.HasWaved(book, now + F.tick, viewer, other)).toEqual(true)
	end)
	it("the next gift day starts the book over", function()
		local book = Rules.MarkWaved(nil, now, owner, uid)
		local tomorrow = now + Config.GiftDaySeconds
		expect(Rules.HasWaved(book, tomorrow, owner, uid)).toEqual(false)
		local fresh = Rules.MarkWaved(book, tomorrow, owner, other)
		expect(fresh.day).toEqual(Rules.DayOf(tomorrow))
		expect(Rules.HasWaved(fresh, tomorrow, owner, other)).toEqual(true)
		expect(Rules.HasWaved(fresh, tomorrow, owner, uid)).toEqual(false)
	end)
end)
return true
