--!strict
-- ReplicatedStorage.Shared.SeasonMath: which seasonal event (data/Seasons) a moment falls in, shared so the Codex
-- stamps, the HUD banner, the Quests screen and the server's spawn, clock and track rules agree. Pure functions of a
-- clock (the server's os.time, or workspace:GetServerTimeNow() on the client) and the data tables. `override` is a
-- season id forced on by Dev's /season in Studio (nil in play): that season counts as running with its whole window
-- left on the clock, so the banner has something to count.

local Seasons = require(script.Parent.data.Seasons)

local SeasonMath = {}

export type Current = { season: Seasons.Season, secondsLeft: number }

-- The season row with this id, or nil.
function SeasonMath.Find(id: string): Seasons.Season?
	return Seasons.ById[id]
end

-- The season running at `now`: the forced one when `override` names a season, else the first row whose window
-- holds `now`. nil when none runs.
function SeasonMath.Current(now: number, override: string?): Current?
	if override ~= nil then
		local forced = Seasons.ById[override]
		if forced then
			local left = forced.endsAt - now
			if left <= 0 then
				left = forced.endsAt - forced.startsAt
			end
			return { season = forced, secondsLeft = left }
		end
	end
	for _, season in ipairs(Seasons.List) do
		if now >= season.startsAt and now < season.endsAt then
			return { season = season, secondsLeft = season.endsAt - now }
		end
	end
	return nil
end

-- Whether a species is an event alien of any season (Vaulted outside its window). Track-only rewards are not
-- limited by this rule: they never spawn, so there is nothing to vault.
function SeasonMath.IsLimited(species: string): boolean
	for _, season in ipairs(Seasons.List) do
		if table.find(season.species, species) ~= nil then
			return true
		end
	end
	return false
end

-- Whether `species` spawns because of the season running at `now`: an event alien of it, or one it brings back.
function SeasonMath.IsCurrent(species: string, now: number, override: string?): boolean
	local current = SeasonMath.Current(now, override)
	if not current then
		return false
	end
	return table.find(current.season.species, species) ~= nil or table.find(current.season.returns, species) ~= nil
end

-- Whether `species` is back for the season running at `now` (the Vault Rotation), not an event alien of it.
function SeasonMath.IsReturning(species: string, now: number, override: string?): boolean
	local current = SeasonMath.Current(now, override)
	return current ~= nil and table.find(current.season.returns, species) ~= nil
end

-- The night-length multiplier at `now`: the running season's, else 1.
function SeasonMath.NightScale(now: number, override: string?): number
	local current = SeasonMath.Current(now, override)
	return if current then current.season.nightScale else 1
end

-- Whether a track quest's objective is met by `progress` (the saved counts by quest id).
function SeasonMath.TrackDone(quest: Seasons.Quest, progress: { [string]: number }): boolean
	return (progress[quest.id] or 0) >= quest.objective.count
end

return SeasonMath
