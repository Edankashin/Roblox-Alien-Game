--!strict
-- When the weekly leaderboard period starts and resets, shared so the client can show the countdown
-- the server will act on. Pure functions of a clock (os.time) and data/Leaderboard.

local Leaderboard = require(script.Parent.data.Leaderboard)

local LeaderboardMath = {}

local DAY = 24 * 3600
local WEEK = 7 * DAY

-- The most recent reset instant at or before `now`: ResetWeekday at ResetHourUtc, UTC.
function LeaderboardMath.PeriodStart(now: number): number
	local t = os.date("!*t", now)
	local secondsIntoDay = t.hour * 3600 + t.min * 60 + t.sec
	local daysSinceResetDay = (t.wday - Leaderboard.ResetWeekday) % 7
	local start = now - daysSinceResetDay * DAY - secondsIntoDay + Leaderboard.ResetHourUtc * 3600
	if start > now then
		start -= WEEK
	end
	return start
end

-- The period's id, the UTC date of its start: "2026-10-02". Store keys and client labels use it.
function LeaderboardMath.PeriodId(now: number): string
	return os.date("!%Y-%m-%d", LeaderboardMath.PeriodStart(now))
end

-- The next reset instant after `now`.
function LeaderboardMath.NextReset(now: number): number
	return LeaderboardMath.PeriodStart(now) + WEEK
end

-- The OrderedDataStore key for the period `now` falls in.
function LeaderboardMath.StoreKey(now: number): string
	return Leaderboard.StoreName .. "_" .. LeaderboardMath.PeriodId(now)
end

return LeaderboardMath
