--!strict
-- ReplicatedStorage.Shared.RewardIcon: the pixel-icon key a gift reward shows on its card (Welcome Week in data/Gifts, Playtime in
-- data/Playtime; the same reward kinds as the wheel in data/Spins). One place, so a new reward kind cannot reach a card without a picture:
-- tests/RewardIcon.spec.luau checks every reward in both tables resolves to a drawn icon in data/PixelIcons.
--   scrap -> Scrap; lure and powerUp -> their id (Lure1, SpeedBurst, ...); egg -> "Egg" and the tier (EggRare); spin -> Spin (the wheel).

export type Reward = { kind: string, id: string?, amount: number?, tier: string? }

local RewardIcon = {}

function RewardIcon.Key(reward: Reward): string?
	if reward.kind == "scrap" then
		return "Scrap"
	elseif reward.kind == "lure" or reward.kind == "powerUp" then
		return reward.id
	elseif reward.kind == "egg" then
		return "Egg" .. (reward.tier or "") -- the pixel egg in its tier's speckles; the pack falls back to the tier badge
	elseif reward.kind == "spin" then
		return "Spin"
	end
	return nil
end

return RewardIcon
