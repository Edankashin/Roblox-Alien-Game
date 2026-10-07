--!strict
-- ReplicatedStorage.Shared.VisitRules: the pure rules of visiting (data/Visiting), read by the server (Visiting
-- decides) and the client (the Visit screen and the Wave action only hint). Who may enter a home by its HomeLock
-- level, how many waves a visitor has left today, how much wave Scrap an owner can still receive today, and the
-- tallies after a wave, which user ids VisitHome takes, which aliens a visitor already waved at today, and the numbering
-- that lets a newer visit request replace an older one still waiting on its friend check. A "day" is
-- Config.GiftDaySeconds long, counted from the epoch, the same day the gifts use.

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

-- Whether `value` is a user id VisitHome may be asked about: a whole number from 1 to VisitingData.MaxUserId. Studio's
-- test players have negative ids, so with `allowStudioIds` (true only in Studio) -MaxUserId to -1 pass as well. NaN,
-- infinities, fractions, zero and anything that is not a number fail.
function VisitRules.IsOwnerId(value: any, allowStudioIds: boolean): boolean
	if type(value) ~= "number" or value % 1 ~= 0 then
		return false -- NaN and infinities fail the remainder test
	end
	if value >= 1 then
		return value <= VisitingData.MaxUserId
	end
	return allowStudioIds and value <= -1 and value >= -VisitingData.MaxUserId
end

-- Visit requests. Each in-server visit request (and each leave) takes the visitor's next number from `book`; when the
-- request's friend check returns it carries on only if its number is still the latest, so the last thing the visitor
-- asked for decides, whatever order the checks finish in.
function VisitRules.NextRequest(book: { [number]: number }, userId: number): number
	local request = (book[userId] or 0) + 1
	book[userId] = request
	return request
end

function VisitRules.IsLatestRequest(book: { [number]: number }, userId: number, request: number): boolean
	return book[userId] == request
end

-- Whether the visitor already waved at this alien of this owner's home on the gift day of `now`.
function VisitRules.HasWaved(book: Types.WavedBook?, now: number, ownerId: number, uid: string): boolean
	if book == nil or book.day ~= VisitRules.DayOf(now) then
		return false
	end
	local set = book.owners[ownerId]
	return set ~= nil and set[uid] == true
end

-- The book with this alien marked as waved at on the gift day of `now`; a book from an earlier day starts over.
function VisitRules.MarkWaved(book: Types.WavedBook?, now: number, ownerId: number, uid: string): Types.WavedBook
	local day = VisitRules.DayOf(now)
	local current: Types.WavedBook = if book ~= nil and book.day == day then book else { day = day, owners = {} }
	local set = current.owners[ownerId]
	if set == nil then
		set = {}
		current.owners[ownerId] = set
	end
	set[uid] = true
	return current
end

return VisitRules
