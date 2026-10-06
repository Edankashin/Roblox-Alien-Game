--!strict
-- ReplicatedStorage.Shared.VisitRules: the pure rules of visiting (data/Visiting), read by the server (Visiting
-- decides) and the client (the Visit screen and the Wave action only hint). Who may enter a home by its HomeLock
-- level, how many waves a visitor has left today, how much wave Scrap an owner can still receive today, and the
-- tallies after a wave. A "day" is Config.GiftDaySeconds long, counted from the epoch, the same day the gifts use.

local Types = require(script.Parent.types.Types)
local VisitingData = require(script.Parent.data.Visiting)
local Config = require(script.Parent.data.Config)

local VisitRules = {}

-- The day index of a clock reading.
function VisitRules.DayOf(now: number): number
	return math.floor(now / Config.GiftDaySeconds)
end

-- Whether `viewerId` may enter the home of `ownerId` whose HomeLock preference is `lock`. The owner always may.
-- Returns true, or false with the reason: OwnerOnly, FriendsOnly. A lock value the data does not name reads as
-- owner-only, the safest reading.
function VisitRules.CanVisit(lock: number, viewerId: number, ownerId: number, isFriend: boolean): (boolean, string?)
	if viewerId == ownerId then
		return true, nil
	end
	if lock == VisitingData.LockAnyone then
		return true, nil
	end
	if lock == VisitingData.LockFriends then
		if isFriend then
			return true, nil
		end
		return false, "FriendsOnly"
	end
	return false, "OwnerOnly"
end

-- Waves a visitor may still make at `now`: the day's full allowance once the tally's day is over, else what is
-- left of it (never below 0).
function VisitRules.WavesLeft(tally: Types.WaveTally, now: number): number
	if tally.day ~= VisitRules.DayOf(now) then
		return VisitingData.WavesPerDay
	end
	return math.max(VisitingData.WavesPerDay - tally.sent, 0)
end

-- Scrap an owner can still receive from live waves at `now` (never below 0): the cap on a new day, else the cap
-- less what the day already paid.
function VisitRules.OwnerRoom(tally: Types.WaveTally, now: number): number
	if tally.day ~= VisitRules.DayOf(now) then
		return VisitingData.WaveOwnerScrapCapPerDay
	end
	return math.max(VisitingData.WaveOwnerScrapCapPerDay - tally.got, 0)
end

-- The tally after the player made one wave at `now`: a new day starts both counts over.
function VisitRules.AfterWave(tally: Types.WaveTally, now: number): Types.WaveTally
	local day = VisitRules.DayOf(now)
	if tally.day ~= day then
		return { day = day, sent = 1, got = 0 }
	end
	return { day = day, sent = tally.sent + 1, got = tally.got }
end

-- The tally after the player, as an owner, received `scrap` from a live wave at `now` (already limited to OwnerRoom).
function VisitRules.AfterGot(tally: Types.WaveTally, now: number, scrap: number): Types.WaveTally
	local day = VisitRules.DayOf(now)
	if tally.day ~= day then
		return { day = day, sent = 0, got = scrap }
	end
	return { day = day, sent = tally.sent, got = tally.got + scrap }
end

-- Scrap an away owner's inbox can still take from waves at `now` (never below 0), by the same cap as OwnerRoom.
function VisitRules.InboxRoom(waves: Types.InboxWaves, now: number): number
	if waves.day ~= VisitRules.DayOf(now) then
		return VisitingData.WaveOwnerScrapCapPerDay
	end
	return math.max(VisitingData.WaveOwnerScrapCapPerDay - waves.scrap, 0)
end

-- An inbox's wave tally after one more wave at `now` worth `scrap` (already limited to InboxRoom): a new day
-- starts over, so a letter never reports two days as one.
function VisitRules.AfterInboxWave(waves: Types.InboxWaves, now: number, scrap: number): Types.InboxWaves
	local day = VisitRules.DayOf(now)
	if waves.day ~= day then
		return { day = day, count = 1, scrap = scrap }
	end
	return { day = day, count = waves.count + 1, scrap = waves.scrap + scrap }
end

return VisitRules
