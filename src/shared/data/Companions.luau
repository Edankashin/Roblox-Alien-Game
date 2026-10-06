--!strict
-- Companions (docs/GAME_DESIGN.md section 5: every alien is a worker and a companion): up to Config.CompanionSlots
-- resting aliens follow the player, drawn behind the character for everyone on the server, and each gives one
-- small perk while following, by its first job, scaled by its tier. Slots grow by the +1 companion pass and by
-- Companion Tokens (the spin wheel), up to MaxSlots. A following alien is never seated at a station; a seated
-- one must rest before it follows. Every number here (Config holds the base slot count), never in code.

export type Perk = { kind: "catchScrap" | "zone" | "luck" | "radar", amount: number } -- amount at tier factor 1

local PerkByJob: { [string]: Perk } = {
	Gather = { kind = "catchScrap", amount = 0.10 }, -- more Scrap from catches
	Build = { kind = "zone", amount = 0.10 }, -- wider capture zones
	Spark = { kind = "luck", amount = 0.10 }, -- higher luck
	Tinker = { kind = "radar", amount = 0.10 }, -- longer radar range (World 3 job; no reader yet)
}

local TierFactor: { [string]: number } = { Common = 1, Uncommon = 1.2, Rare = 1.5, Epic = 2, Legendary = 2.5, Cosmic = 2.5, Secret = 2.5 }

local PerkCap: { [string]: number } = { catchScrap = 0.5, zone = 0.4, luck = 0.5, radar = 0.5 } -- summed perk of a kind never exceeds this

return {
	PerkByJob = PerkByJob,
	TierFactor = TierFactor,
	PerkCap = PerkCap,
	PassSlots = 1, -- the CompanionSlot4 pass adds this many
	TokenSlots = 1, -- each Companion Token used adds this many
	MaxSlots = 5, -- base + pass + tokens never exceed this
	TokenItem = "CompanionSlot", -- the inventory item id the spin wheel grants (data/Spins)
	-- following, in studs and per-frame fractions
	FollowDistance = 6, -- behind the character
	FollowSpacing = 3, -- between companions across the arc
	FollowLerp = 0.12, -- fraction of the remaining distance closed each frame
	CatchUpDistance = 40, -- farther than this (a teleport, a fly) the companion snaps to its spot
	Scale = 0.8, -- model scale over the species' own, times the size band and growth
	BobStuds = 0.2,
	BobHz = 0.8,
	RenderDistance = 120, -- other players' companions farther than this from the camera are not drawn
	MaxRendered = 24, -- companions drawn at once (the nearest owners first)
}
