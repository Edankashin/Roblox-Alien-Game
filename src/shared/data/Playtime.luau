--!strict
-- Playtime gifts (milestone 49): six gifts unlocked by the minutes a player has actively played today. The server counts
-- the minutes (Services/Playtime: TickSeconds at a time, never while Afk.IsResting), keeps them across rejoins the same
-- day (profile.playtime), and starts again at ResetHourUtc; leaving loses nothing, and a gift once unlocked stays
-- claimable until the day ends. Why they exist: the Growth Playbook chose to skip them, the stats slideshow lists them
-- first for playtime, and PRE_PRODUCTION decision 5c-1 measured them: tools/progression_sim.py --playtime (these six
-- gifts at 5, 10, 20, 30, 45 and 60 minutes played a day) moves World 1's launch by no day for any play pattern, so they
-- are a dopamine source and a reason to stay, not a pace change. Rewards use the shapes Welcome Week (data/Gifts) and
-- the wheel (data/Spins) use: scrap and spin carry an amount; lure and powerUp an id and an amount; an egg a tier (one
-- alien of that tier from this world, granted like the Welcome Week egg). Nothing here is sold for Robux and no gift
-- costs Scrap. Every number here.

export type Reward = { kind: "scrap" | "lure" | "powerUp" | "spin" | "egg", id: string?, amount: number, tier: string? }
export type Gift = { minutes: number, reward: Reward }

local Gifts: { Gift } = {
	{ minutes = 5, reward = { kind = "scrap", amount = 150 } },
	{ minutes = 10, reward = { kind = "lure", id = "Lure1", amount = 1 } },
	{ minutes = 20, reward = { kind = "powerUp", id = "SpeedBurst", amount = 1 } },
	{ minutes = 30, reward = { kind = "spin", amount = 1 } },
	{ minutes = 45, reward = { kind = "powerUp", id = "LuckyCharm", amount = 1 } },
	{ minutes = 60, reward = { kind = "egg", tier = "Rare", amount = 1 } },
}

return {
	Enabled = true, -- false hides the HUD button and the screen, stops the clock, and ClaimPlaytimeGift answers Disabled
	ResetHourUtc = 0, -- the day's played time and claims start again at this UTC hour
	TickSeconds = 5, -- the server adds this much played time to each active player every this many seconds
	Gifts = Gifts,
}
