--!strict
-- ReplicatedStorage.Shared.Countdown: seconds to the short forms a countdown reads in ("2d 4h", "1h 12m", "6m",
-- "45s") and the clock form of a timer that is running now ("4:20"). Pure functions of a number and the TIME_*
-- strings; the "What's on" card on the Quests screen is the first reader, and the unit words stay in
-- strings/en so they can be translated. Never a negative time: a time already past reads as zero.
--
-- Short rounds down (a countdown reads "6m" from 6m 59s to 6m 0s and "59s" below a minute) and keeps two units
-- while they help: days and hours under Config.CountdownDaysOnlyFrom days, hours and minutes under a day, a
-- whole number of hours alone ("2h"). Clock rounds up (the last second reads 0:01, never 0:00 early).

local Config = require(script.Parent.data.Config)
local Strings = require(script.Parent.strings.en)

local Countdown = {}

local MINUTE = 60
local HOUR = 3600
local DAY = 86400

-- A whole, non-negative number of seconds; NaN and infinity read as zero.
local function whole(seconds: number): number
	if seconds ~= seconds or seconds == math.huge then
		return 0
	end
	return math.max(0, seconds)
end

-- "2d 4h" up to Config.CountdownDaysOnlyFrom days, then "4d"; "1h 12m" (or "2h" on the hour); "6m"; "45s".
function Countdown.Short(seconds: number): string
	local total = math.floor(whole(seconds))
	if total >= DAY then
		local days = total // DAY
		local hours = (total % DAY) // HOUR
		if days >= Config.CountdownDaysOnlyFrom or hours == 0 then
			return Strings.TIME_D:format(days)
		end
		return Strings.TIME_DH:format(days, hours)
	elseif total >= HOUR then
		local minutes = (total % HOUR) // MINUTE
		if minutes == 0 then
			return Strings.TIME_H:format(total // HOUR)
		end
		return Strings.TIME_HM:format(total // HOUR, minutes)
	elseif total >= MINUTE then
		return Strings.TIME_M:format(total // MINUTE)
	end
	return Strings.TIME_S:format(total)
end

-- "4:20" (minutes and seconds), "1:02:05" from an hour up.
function Countdown.Clock(seconds: number): string
	local total = math.ceil(whole(seconds))
	if total >= HOUR then
		return Strings.TIME_CLOCK_H:format(total // HOUR, (total % HOUR) // MINUTE, total % MINUTE)
	end
	return Strings.TIME_CLOCK:format(total // MINUTE, total % MINUTE)
end

return Countdown
