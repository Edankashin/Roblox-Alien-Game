--!strict
-- Field Notes: one chain per world, five steps, never expires, one step at a time, each step pays.
-- Objectives count up in profile.quests.progress by objective id; the server advances the step when the
-- player claims. Player-facing text lives in strings: FN_<stepId>_TITLE, FN_<stepId>_LEGEND, and the
-- OBJ_<kind> templates. Rewards use the same kinds the Peddler and spins use.
export type Objective = {
	id: string, -- unique across the world's chain
	kind: "catchCount" | "catchCondition" | "catchTier" | "catchTierCondition" | "collect" | "craft" | "soundHorn",
	count: number,
	tier: string?, -- catchTier, catchTierCondition
	condition: string?, -- catchCondition, catchTierCondition, soundHorn (the condition the horn needs)
	material: string?, -- collect
	lure: string?, -- craft
}
export type Reward = { kind: "gear" | "lure" | "scrap" | "spin" | "item" | "encounter", id: string?, amount: number? }
export type Step = { id: string, objectives: { Objective }, rewards: { Reward } }

local FieldNotes: { [number]: { Step } } = {
	[1] = {
		{ id = "W1S1", objectives = { { id = "w1s1_catch", kind = "catchCount", count = 5 } }, rewards = { { kind = "gear", id = "Boots" } } },
		{ id = "W1S2", objectives = { { id = "w1s2_night", kind = "catchCondition", count = 1, condition = "Night" }, { id = "w1s2_crystal", kind = "collect", count = 1, material = "CaveCrystal" } }, rewards = { { kind = "gear", id = "Radar1" }, { kind = "scrap", amount = 500 }, { kind = "lure", id = "Lure1", amount = 3 } } },
		{ id = "W1S3", objectives = { { id = "w1s3_craft", kind = "craft", count = 1, lure = "Lure2" }, { id = "w1s3_rare", kind = "catchTier", count = 1, tier = "Rare" } }, rewards = { { kind = "spin", amount = 1 }, { kind = "lure", id = "Lure2", amount = 1 } } },
		{ id = "W1S4", objectives = { { id = "w1s4_epic", kind = "catchTierCondition", count = 1, tier = "Epic", condition = "Rain" } }, rewards = { { kind = "item", id = "WardenHorn", amount = 1 } } },
		{ id = "W1S5", objectives = { { id = "w1s5_horn", kind = "soundHorn", count = 1, condition = "Night" } }, rewards = { { kind = "encounter", id = "Gaiabloom" } } },
	},
	-- World 2, Frostbyte. No gear rewards yet (Radar2 is not buyable), so the steps pay Scrap, lures and spins instead.
	-- The horn is the same WardenHorn item as World 1; a second copy is harmless because it is never consumed.
	[2] = {
		{ id = "W2S1", objectives = { { id = "w2s1_catch", kind = "catchCount", count = 8 } }, rewards = { { kind = "scrap", amount = 800 }, { kind = "lure", id = "Lure1", amount = 3 } } },
		{ id = "W2S2", objectives = { { id = "w2s2_night", kind = "catchCondition", count = 1, condition = "Night" }, { id = "w2s2_core", kind = "collect", count = 1, material = "FrostCore" } }, rewards = { { kind = "scrap", amount = 1500 }, { kind = "lure", id = "Lure2", amount = 2 }, { kind = "spin", amount = 1 } } },
		{ id = "W2S3", objectives = { { id = "w2s3_craft", kind = "craft", count = 1, lure = "Lure2" }, { id = "w2s3_rare", kind = "catchTier", count = 1, tier = "Rare" } }, rewards = { { kind = "spin", amount = 2 }, { kind = "lure", id = "Lure2", amount = 1 } } },
		{ id = "W2S4", objectives = { { id = "w2s4_epic", kind = "catchTierCondition", count = 1, tier = "Epic", condition = "Blizzard" } }, rewards = { { kind = "item", id = "WardenHorn", amount = 1 }, { kind = "scrap", amount = 3000 } } },
		{ id = "W2S5", objectives = { { id = "w2s5_horn", kind = "soundHorn", count = 1, condition = "Night" } }, rewards = { { kind = "encounter", id = "Skaddle" } } },
	},
}

return {
	FieldNotes = FieldNotes,
	HornItem = "WardenHorn", -- the item the finale needs; never consumed
}
