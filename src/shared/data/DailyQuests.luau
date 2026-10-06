--!strict
-- Daily and weekly quests (docs/GAME_DESIGN.md section 9: three of each, paying Scrap, lures and spins;
-- the Growth Playbook adds one reroll a day). Three are dealt per period from each pool, seeded by the
-- period and the player so a rejoin shows the same set; daily resets at DailyResetHourUtc, weekly on the
-- leaderboard's Friday cadence (Shared/LeaderboardMath). Objectives count in the profile; the server
-- advances and pays on claim. Every number here.

export type Objective = {
	-- catchCount: any catch; catchCondition: a catch while `condition` is active (Night, Day);
	-- catchTier: a catch of `tier`; catchSpecial: a catch during this world's special weather;
	-- catchWithFriend: a catch while a Roblox friend is in the server; perfectCount: a perfect-zone catch;
	-- collectAny: any key material picked up; craft: a lure crafted (`lure`); dailyClaims: daily quests claimed
	kind: "catchCount" | "catchCondition" | "catchTier" | "catchSpecial" | "catchWithFriend" | "perfectCount" | "collectAny" | "craft" | "dailyClaims",
	count: number,
	tier: string?,
	condition: string?,
	lure: string?,
}
export type Reward = { kind: "scrap" | "lure" | "spin" | "powerUp", id: string?, amount: number } -- the kinds Gifts.GrantRewards pays (promo codes share the shape)
export type Quest = { id: string, objective: Objective, rewards: { Reward } }

local Daily: { Quest } = {
	{ id = "D_catch5", objective = { kind = "catchCount", count = 5 }, rewards = { { kind = "scrap", amount = 300 } } },
	{ id = "D_night2", objective = { kind = "catchCondition", count = 2, condition = "Night" }, rewards = { { kind = "lure", id = "Lure1", amount = 2 } } },
	{ id = "D_uncommon", objective = { kind = "catchTier", count = 1, tier = "Uncommon" }, rewards = { { kind = "spin", amount = 1 } } },
	{ id = "D_special2", objective = { kind = "catchSpecial", count = 2 }, rewards = { { kind = "scrap", amount = 500 } } },
	{ id = "D_friend5", objective = { kind = "catchWithFriend", count = 5 }, rewards = { { kind = "spin", amount = 1 }, { kind = "scrap", amount = 300 } } },
	{ id = "D_perfect3", objective = { kind = "perfectCount", count = 3 }, rewards = { { kind = "scrap", amount = 400 } } },
	{ id = "D_collect6", objective = { kind = "collectAny", count = 6 }, rewards = { { kind = "lure", id = "Lure1", amount = 1 }, { kind = "scrap", amount = 200 } } },
	{ id = "D_craft1", objective = { kind = "craft", count = 1, lure = "Lure1" }, rewards = { { kind = "scrap", amount = 250 } } },
}

local Weekly: { Quest } = {
	{ id = "W_catch40", objective = { kind = "catchCount", count = 40 }, rewards = { { kind = "scrap", amount = 2500 }, { kind = "spin", amount = 2 } } },
	{ id = "W_rare3", objective = { kind = "catchTier", count = 3, tier = "Rare" }, rewards = { { kind = "lure", id = "Lure2", amount = 2 }, { kind = "scrap", amount = 1000 } } },
	{ id = "W_night10", objective = { kind = "catchCondition", count = 10, condition = "Night" }, rewards = { { kind = "scrap", amount = 1500 } } },
	{ id = "W_collect25", objective = { kind = "collectAny", count = 25 }, rewards = { { kind = "lure", id = "Lure1", amount = 5 }, { kind = "scrap", amount = 800 } } },
	{ id = "W_perfect10", objective = { kind = "perfectCount", count = 10 }, rewards = { { kind = "spin", amount = 3 } } },
	{ id = "W_friend15", objective = { kind = "catchWithFriend", count = 15 }, rewards = { { kind = "scrap", amount = 2000 }, { kind = "spin", amount = 2 } } },
	{ id = "W_daily5", objective = { kind = "dailyClaims", count = 5 }, rewards = { { kind = "spin", amount = 3 }, { kind = "scrap", amount = 1500 } } },
}

return {
	Daily = Daily,
	Weekly = Weekly,
	DailyCount = 3, -- dealt per day
	WeeklyCount = 3, -- dealt per week
	DailyResetHourUtc = 0, -- the daily set rolls over at this UTC hour
	RerollsPerDay = 1, -- free rerolls of one daily quest per day
	-- a period's seed mixes the period id and the user id so every server deals the same set to a player
	SeedSalt = 7919,
}
