--!strict
-- Growth stages (docs/GAME_DESIGN.md section 5, "Size rolls and growth"): an alien at a station grows
-- Hatchling to Grown to Elder by time worked, each stage a visible size step and a small speed bump.
-- A reward with no feeding, no hunger and no decay: the record's workedSeconds only ever goes up. The
-- server adds the income tick's seconds to every seated alien and, on a rejoin, the time away (capped
-- like offline Scrap) to the aliens that were seated when the player left. Stages are in worked order;
-- a record's stage is the last one whose workedSeconds it has reached. Every number here, never in code.

export type Stage = {
	id: string,
	workedSeconds: number, -- time at a station needed to reach this stage
	speedBonus: number, -- added to the alien's work speed multiplier (0.1 = +10%)
	scaleBonus: number, -- added to the model scale wherever the alien is drawn (0.08 = +8%)
	label: boolean, -- whether the Aliens screen names the stage (STAGE_<id>)
}

local Stages: { Stage } = {
	{ id = "Hatchling", workedSeconds = 0, speedBonus = 0, scaleBonus = 0, label = false },
	{ id = "Grown", workedSeconds = 7200, speedBonus = 0.10, scaleBonus = 0.08, label = true }, -- two hours at a station
	{ id = "Elder", workedSeconds = 86400, speedBonus = 0.25, scaleBonus = 0.16, label = true }, -- a day at a station
}

local ById: { [string]: Stage } = {}
for _, stage in ipairs(Stages) do
	ById[stage.id] = stage
end

return {
	Stages = Stages, -- in worked order, first is the starting stage
	ById = ById,
	Default = "Hatchling",
	OfflineCountsWhileSeated = true, -- time away counts as worked time for aliens seated at leave, up to the offline Scrap cap
	GrewToastMax = 3, -- a rejoin names at most this many aliens that grew while away; past that one line gives the count
}
