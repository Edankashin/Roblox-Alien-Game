--!strict
-- Welcome Week: unlocks by days played, never by consecutive days. Missing a day loses nothing.
return {
	{ day = 1, label = "Welcome Pack", reward = { kind = "scrap", amount = 300 } },
	{ day = 2, label = "Twig Lure", reward = { kind = "lure", id = "Lure1", amount = 2 } },
	{ day = 3, label = "Speed Burst", reward = { kind = "powerUp", id = "SpeedBurst", amount = 2 } },
	{ day = 4, label = "Scrap Bundle", reward = { kind = "scrap", amount = 1500 } },
	{ day = 5, label = "Free Spin", reward = { kind = "spin", amount = 2 } },
	{ day = 6, label = "Glow Lure", reward = { kind = "lure", id = "Lure2", amount = 1 } },
	{ day = 7, label = "Epic Egg", reward = { kind = "egg", tier = "Epic", amount = 1 } },
}
