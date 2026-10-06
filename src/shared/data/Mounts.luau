--!strict
-- Mounts (docs/GAME_DESIGN.md section 6, "Mounts (rideable aliens)"): a species with a `ride` traversal on its
-- row (Species.luau) can be ridden once it follows the player (data/Companions): the rider sits on it, moves at
-- a speed set by the mount's tier (an Epic matches the Hoverboard, a Legendary is 20% faster, a Cosmic 40%) and
-- jumps by its traversal. Riding keeps the companion slot the mount already holds and its perk. Mounts are never
-- sold. Every number here, never in code; the traversal names a species can carry are Types.Traversal.

export type TraversalRow = {
	speedScale: number, -- multiplies the tier speed (1 = the tier's speed)
	jumpScale: number, -- multiplies the character's jump power or jump height while riding (1 = unchanged)
	nameKey: string, -- strings key for the traversal's word ("Sprint")
}

local Traversals: { [string]: TraversalRow } = {
	Sprint = { speedScale = 1, jumpScale = 1.6, nameKey = "RIDE_Sprint" }, -- fastest ground movement and a big leap
	Hover = { speedScale = 1, jumpScale = 1.2, nameKey = "RIDE_Hover" }, -- a float over ice and small gaps (no slow terrain exists yet to ignore)
	Glide = { speedScale = 1, jumpScale = 1, nameKey = "RIDE_Glide" }, -- World 3; a long glide comes with the Glider Pack's rules
	Swim = { speedScale = 1, jumpScale = 1, nameKey = "RIDE_Swim" }, -- World 5
	Climb = { speedScale = 1, jumpScale = 1, nameKey = "RIDE_Climb" }, -- World 3
}

-- WalkSpeed multiplier over Gear.BaseWalkSpeed while riding, by the mount's tier (lower tiers never carry `ride`).
local SpeedByTier: { [string]: number } = { Epic = 1.6, Legendary = 1.92, Cosmic = 2.24, Secret = 2.24 }

-- How far the rider's hips are lifted over their normal hip height while riding, by species, in studs (the
-- mount is drawn under the rider's feet at that lift); Default for a rideable species not listed.
local SeatStuds: { [string]: number } = {
	Thunderhog = 2.6, -- its quills reach 0.4 studs over the body, so the rider sits above them
	Gaiabloom = 3.2,
	Radish = 2.4,
	Frostfang = 2.2,
	Skaddle = 2.6,
	Fenripup = 2.4,
}

return {
	Traversals = Traversals,
	SpeedByTier = SpeedByTier,
	SeatStuds = SeatStuds,
	DefaultSeatStuds = 2.2,
	-- The character's jump as Roblox sets it; the traversal's jumpScale multiplies whichever the Humanoid uses.
	BaseJumpPower = 50,
	BaseJumpHeight = 7.2,
}
