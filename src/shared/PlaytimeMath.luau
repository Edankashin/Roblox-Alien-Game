--!strict
-- ReplicatedStorage.Shared.PlaytimeMath: the playtime gifts' (data/Playtime) clock maths, shared so the server's
-- accrual and claim checks and the client's cards, countdowns and HUD badge agree. Pure functions of the data table
-- and the seconds played today; nothing here reads a clock or a profile. A gift is "claimed" by the string key of its
-- index (PlaytimeMath.Key), the shape profile.playtime.claimed and Types.PlaytimeState carry.

local Config = require(script.Parent.data.Config)
local Playtime = require(script.Parent.data.Playtime)

local PlaytimeMath = {}

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600

-- The day index of a wall-clock second: whole days since the epoch with the day starting at `resetHourUtc`, so
-- every server agrees on when the played time starts again (the same UTC day index Welcome Week uses, shifted).
function PlaytimeMath.DayOf(now: number, resetHourUtc: number): number
	return math.floor((now - resetHourUtc * SECONDS_PER_HOUR) / Config.GiftDaySeconds)
end

-- The claimed-map key of gift `index`.
function PlaytimeMath.Key(index: number): string
	return tostring(index)
end

-- Whole minutes as seconds (data/Playtime counts gifts in minutes, the clock in seconds).
function PlaytimeMath.MinutesToSeconds(minutes: number): number
	return minutes * SECONDS_PER_MINUTE
end

-- Seconds of play gift `index` needs, or nil for an index outside the table.
function PlaytimeMath.SecondsNeeded(index: number): number?
	local gift = Playtime.Gifts[index]
	if gift == nil then
		return nil
	end
	return PlaytimeMath.MinutesToSeconds(gift.minutes)
end

-- Whether `seconds` of play today reach gift `index`.
function PlaytimeMath.IsUnlocked(seconds: number, index: number): boolean
	local needed = PlaytimeMath.SecondsNeeded(index)
	return needed ~= nil and seconds >= needed
end

-- The first gift not yet unlocked and the seconds of play it still needs; nil, nil when every gift is unlocked.
-- A claimed gift is always an unlocked one, so `claimed` never changes the answer; it is accepted so a caller can
-- pass a state's two fields to this and to ReadyCount alike.
function PlaytimeMath.NextGift(seconds: number, _claimed: { [string]: boolean }?): (number?, number?)
	for index = 1, #Playtime.Gifts do
		local needed = PlaytimeMath.SecondsNeeded(index) :: number
		if seconds < needed then
			return index, needed - seconds
		end
	end
	return nil, nil
end

-- How many gifts are unlocked and not yet claimed (the HUD badge).
function PlaytimeMath.ReadyCount(seconds: number, claimed: { [string]: boolean }): number
	local count = 0
	for index = 1, #Playtime.Gifts do
		if PlaytimeMath.IsUnlocked(seconds, index) and claimed[PlaytimeMath.Key(index)] ~= true then
			count += 1
		end
	end
	return count
end

return PlaytimeMath
