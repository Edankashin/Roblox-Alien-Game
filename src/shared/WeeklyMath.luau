--!strict
-- ReplicatedStorage.Shared.WeeklyMath: which weekly drop (data/Weekly) a moment falls in, shared so the Codex
-- stamps, the HUD banner and the server's spawn and weather rules agree. Pure functions of a clock (the server's
-- os.time, or workspace:GetServerTimeNow() on the client) and the data tables: the week is the leaderboard's
-- period (LeaderboardMath.PeriodStart, Friday at ResetHourUtc), the drop is the rotation row for that week
-- counted from Weekly.Epoch, unless Weekly.Overrides names the week. `offset` shifts the rotation by whole weeks
-- (Dev's /week in Studio); 0 or nil in play.

local Weekly = require(script.Parent.data.Weekly)
local LeaderboardMath = require(script.Parent.LeaderboardMath)

local WeeklyMath = {}

local WEEK = 7 * 24 * 3600

export type Current = {
	drop: Weekly.Drop,
	index: number, -- 1-based rotation index (0 for an override)
	weekId: string, -- LeaderboardMath.PeriodId of the week
	weekStart: number, -- unix seconds
	secondsLeft: number, -- until the next week starts
}

-- The rotation index for the week that starts at `weekStart`, shifted by `offset` weeks.
function WeeklyMath.IndexAt(weekStart: number, offset: number?): number
	local count = #Weekly.Rotation
	if count == 0 then
		return 0
	end
	local weeks = (weekStart - Weekly.Epoch) // WEEK + (offset or 0)
	return (weeks % count) + 1
end

-- The drop running at `now`: an override for the week's id when one exists, else the rotation row.
function WeeklyMath.Current(now: number, offset: number?): Current?
	local weekStart = LeaderboardMath.PeriodStart(now)
	local weekId = os.date("!%Y-%m-%d", weekStart)
	local override = Weekly.Overrides[weekId]
	if override and (offset or 0) == 0 then
		return { drop = override, index = 0, weekId = weekId, weekStart = weekStart, secondsLeft = weekStart + WEEK - now }
	end
	local index = WeeklyMath.IndexAt(weekStart, offset)
	local drop = Weekly.Rotation[index]
	if not drop then
		return nil
	end
	return { drop = drop, index = index, weekId = weekId, weekStart = weekStart, secondsLeft = weekStart + WEEK - now }
end

-- Whether a species is a limited weekly drop anywhere in the rotation or the overrides (Vaulted outside its week).
function WeeklyMath.IsLimited(species: string): boolean
	for _, drop in ipairs(Weekly.Rotation) do
		if drop.species == species and drop.limited then
			return true
		end
	end
	for _, drop in pairs(Weekly.Overrides) do
		if drop.species == species and drop.limited then
			return true
		end
	end
	return false
end

-- Whether `species` is the Alien of the Week at `now` (the current drop's species, limited or featured).
function WeeklyMath.IsCurrent(species: string, now: number, offset: number?): boolean
	local current = WeeklyMath.Current(now, offset)
	return current ~= nil and current.drop.species == species
end

return WeeklyMath
