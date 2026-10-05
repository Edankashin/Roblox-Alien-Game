--!strict
-- Promo codes (Growth Playbook section 3): a small table handed to creators and posted with updates,
-- each claimed once per player, paying Scrap, lures or spins. Never traded for a like or a rating.
-- Codes are upper-case without spaces; `expiresAt` is an os.time deadline, 0 for no deadline.

export type Reward = { kind: "scrap" | "lure" | "spin", id: string?, amount: number }
export type Code = { rewards: { Reward }, expiresAt: number }

local Codes: { [string]: Code } = {
	WELCOME = { rewards = { { kind = "scrap", amount = 500 }, { kind = "lure", id = "Lure1", amount = 2 } }, expiresAt = 0 },
	CRASHLANDING = { rewards = { { kind = "spin", amount = 2 } }, expiresAt = 0 },
}

return {
	Codes = Codes,
	MaxLength = 24, -- longer input is refused before any lookup
	RedeemPerSecond = 1, -- remote rate per player
}
