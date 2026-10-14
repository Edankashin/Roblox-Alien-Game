--!strict
-- Welcome Week: unlocks by days played, never by consecutive days. Missing a day loses nothing.
-- `reward` leads the tile (its icon, an egg's tier colour); `also` is an optional list of lure, powerUp or spin rewards
-- paid in the same claim (never Scrap or an egg: the claim's Scrap analytics count the lead only). A row with `also`
-- names itself with its GIFT_LABEL_<label> string, since no single item name covers it.
-- Day 2 is the two boosts a player saves for the next session (Speed Burst 60 s, Lucky Charm 10 min): a reason to come back.
return {
	{ day = 1, label = "Welcome Pack", reward = { kind = "scrap", amount = 300 } },
	{
		day = 2,
		label = "Boost Pair",
		reward = { kind = "powerUp", id = "SpeedBurst", amount = 1 },
		also = { { kind = "powerUp", id = "LuckyCharm", amount = 1 } },
	},
	{ day = 3, label = "Speed Burst", reward = { kind = "powerUp", id = "SpeedBurst", amount = 2 } },
	{ day = 4, label = "Scrap Bundle", reward = { kind = "scrap", amount = 1500 } },
	{ day = 5, label = "Free Spin", reward = { kind = "spin", amount = 2 } },
	{ day = 6, label = "Glow Lure", reward = { kind = "lure", id = "Lure2", amount = 1 } },
	{ day = 7, label = "Epic Egg", reward = { kind = "egg", tier = "Epic", amount = 1 } },
}
