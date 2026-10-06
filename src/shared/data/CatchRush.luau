--!strict
-- The Catch Rush (docs/PRE_PRODUCTION.md 10.12): a short shared round on the server clock that any
-- newcomer understands in five seconds. Every IntervalSeconds of os.time() (the wall clock, so every
-- server rushes at the same moment, like the Meteor Shower) a round runs for DurationSeconds; every wild
-- catch counts; at the end the players with at least MinCatches are ranked and paid from Rewards by rank
-- (everyone else with a catch gets Participation), the winner is announced server-wide, and the next
-- round is already on the clock. A round that would start during a Meteor Shower is skipped when
-- SkipDuringShower is true, so the two events never fight for the banner. Every number here, never in code.

export type Reward = { kind: string, id: string?, amount: number } -- the Gifts.GrantRewards shape

local Rewards: { [number]: { Reward } } = {
	[1] = { { kind = "scrap", amount = 500 }, { kind = "spin", amount = 1 } },
	[2] = { { kind = "scrap", amount = 300 } },
	[3] = { { kind = "scrap", amount = 200 } },
}

return {
	IntervalSeconds = 600, -- a round starts at every multiple of this since the epoch
	DurationSeconds = 90,
	WarnSeconds = 30, -- the countdown chip appears this long before a round
	PushSeconds = 10, -- how often the server refreshes the round state on clients while it runs or is near
	MinCatches = 1, -- catches needed to be ranked or paid
	TopCount = 3, -- ranks shown and paid from Rewards
	Rewards = Rewards,
	Participation = { { kind = "scrap", amount = 50 } }, -- any ranked player past TopCount with at least MinCatches
	SkipDuringShower = true,
	TieBreak = "earliest", -- equal catches: the player who reached that count first ranks higher
}
