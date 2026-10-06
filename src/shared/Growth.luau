--!strict
-- ReplicatedStorage.Shared.Growth: the growth-stage math both sides read (data/Growth.luau rows). The
-- server adds worked time to records and decides when one crosses a stage; the client draws the stage.
-- Everything here is a pure function of a record's workedSeconds, so what the Aliens screen shows is
-- what the server's work speed uses.

local Types = require(script.Parent.types.Types)
local GrowthData = require(script.Parent.data.Growth)

local Growth = {}

-- The last stage whose threshold `workedSeconds` has reached (the first stage below that).
function Growth.StageAt(workedSeconds: number): GrowthData.Stage
	local stages = GrowthData.Stages
	local current = stages[1]
	for _, stage in ipairs(stages) do
		if workedSeconds >= stage.workedSeconds then
			current = stage
		else
			break
		end
	end
	return current
end

-- A record's stage; a record from before growth (no workedSeconds) is at the first stage.
function Growth.StageOf(record: Types.AlienRecord): GrowthData.Stage
	return Growth.StageAt(record.workedSeconds or 0)
end

-- The stage after `stage` in worked order, or nil at the last one.
function Growth.Next(stage: GrowthData.Stage): GrowthData.Stage?
	local stages = GrowthData.Stages
	for index, candidate in ipairs(stages) do
		if candidate.id == stage.id then
			return stages[index + 1]
		end
	end
	return nil
end

-- Seconds of work still needed for the next stage, or nil at the last one.
function Growth.SecondsToNext(workedSeconds: number): number?
	local nextStage = Growth.Next(Growth.StageAt(workedSeconds))
	if not nextStage then
		return nil
	end
	return math.max(0, nextStage.workedSeconds - workedSeconds)
end

-- The work speed multiplier a record's stage adds (1 at the first stage).
function Growth.SpeedMultiplier(record: Types.AlienRecord): number
	return 1 + Growth.StageOf(record).speedBonus
end

-- The model scale multiplier a record's stage adds (1 at the first stage).
function Growth.ScaleMultiplier(record: Types.AlienRecord): number
	return 1 + Growth.StageOf(record).scaleBonus
end

return Growth
