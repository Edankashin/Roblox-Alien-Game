--!strict
-- Promo codes (Growth Playbook section 3): a small table handed to creators and posted with updates,
-- each claimed once per player, paying Scrap, lures, spins or a power-up (through Gifts.GrantRewards). Never traded
-- for a like or a rating.
-- Codes are upper-case without spaces; `expiresAt` is an os.time deadline (the last second the code works), 0 for no
-- deadline. `startsAt` is optional: the first second it works (Shared/CodesMath.Status decides; the server asks it).

export type Reward = { kind: "scrap" | "lure" | "spin" | "powerUp", id: string?, amount: number }
export type Code = { rewards: { Reward }, expiresAt: number, startsAt: number? }

local Codes: { [string]: Code } = {
	WELCOME = { rewards = { { kind = "scrap", amount = 500 }, { kind = "lure", id = "Lure1", amount = 2 } }, expiresAt = 0 },
	CRASHLANDING = { rewards = { { kind = "spin", amount = 2 } }, expiresAt = 0 },
	SCANNER = { rewards = { { kind = "powerUp", id = "ScannerPulse", amount = 2 } }, expiresAt = 0 }, -- two Scanner Pulses: the radar reader's own code
	-- The launch-week code (PRE_PRODUCTION section 7, seed an audience): Friday 2026-10-16 00:00:00 UTC to Saturday 2026-10-31 23:59:59 UTC.
	LAUNCHWEEK = {
		rewards = { { kind = "scrap", amount = 300 }, { kind = "powerUp", id = "LuckyCharm", amount = 1 } },
		startsAt = 1792108800,
		expiresAt = 1793491199,
	},
}

return {
	Codes = Codes,
	MaxLength = 24, -- longer input is refused before any lookup
	RedeemPerSecond = 1, -- remote rate per player
}
