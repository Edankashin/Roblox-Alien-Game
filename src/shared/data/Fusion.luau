--!strict
-- Fusion (docs/GAME_DESIGN.md: "four duplicates of a species fuse into +1 level on one copy; surplus always
-- has a destination"). A fusion consumes DuplicatesPerLevel spare copies of one species and raises the kept
-- copy's level by one, up to MaxFusionLevels above the starting level (Config.LevelSpeedStep is the work-speed
-- step per level). The kept copy is the best of the species (overlay rank, then size scale, then time worked,
-- then level), the consumed ones are the worst, and seated copies are consumed only when no resting copy
-- is left. No Scrap changes hands: the level is the reward. Every number here, never in code.
return {
	DuplicatesPerLevel = 4, -- spare copies consumed per level gained
	MaxFusionLevels = 2, -- levels a copy can gain over its starting level (level 1 becomes at most 3)
	ConsumeRestingFirst = true, -- resting copies are consumed before seated ones
	ToastEach = true, -- the client toasts every fusion, not only the first
}
