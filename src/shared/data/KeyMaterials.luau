--!strict
-- Found only by exploring. Nodes respawn; condition gates when they are available (a Night-only node
-- hides by day). nodes is how many the server scatters in the material's biome; 0 means quest only.
export type KeyMaterialDef = {
	name: string,
	world: number,
	biome: string,
	condition: string,
	dropCount: number,
	respawnSeconds: number,
	nodes: number,
	color: string,
	shape: "Ball" | "Block" | "Cylinder",
	glows: boolean?, -- Neon material, so a node reads in a dark cave or under the canopy
}

local list: { [string]: KeyMaterialDef } = {
	WreckPlate = { name = "Wreck Plate", world = 1, biome = "Meadow", condition = "Any", dropCount = 1, respawnSeconds = 30, nodes = 6, color = "8A9BA8", shape = "Block" },
	Glowroot = { name = "Glowroot", world = 1, biome = "Forest", condition = "Any", dropCount = 1, respawnSeconds = 120, nodes = 4, color = "9BE564", shape = "Cylinder", glows = true },
	CaveCrystal = { name = "Cave Crystal", world = 1, biome = "Cave", condition = "Night", dropCount = 1, respawnSeconds = 180, nodes = 3, color = "68C9FE", shape = "Ball", glows = true },
	StormShard = { name = "Storm Shard", world = 1, biome = "Meadow", condition = "Rain", dropCount = 1, respawnSeconds = 240, nodes = 3, color = "FFEF4A", shape = "Block", glows = true },
	WardenCore = { name = "Warden's Core", world = 1, biome = "Meadow", condition = "Quest", dropCount = 1, respawnSeconds = 0, nodes = 0, color = "2ECC71", shape = "Ball" },
	-- World 2, Frostbyte. Frost Cores also feed World 3's Nav Array through the Outpost (GAME_DESIGN section 8).
	IcePlate = { name = "Ice Plate", world = 2, biome = "Snowfield", condition = "Any", dropCount = 1, respawnSeconds = 30, nodes = 6, color = "BFE3F7", shape = "Block" },
	GeyserPearl = { name = "Geyser Pearl", world = 2, biome = "GeyserField", condition = "Any", dropCount = 1, respawnSeconds = 120, nodes = 4, color = "FFD6A5", shape = "Ball", glows = true },
	FrostCore = { name = "Frost Core", world = 2, biome = "IceCave", condition = "Night", dropCount = 1, respawnSeconds = 180, nodes = 3, color = "7FDBFF", shape = "Ball", glows = true },
	BlizzardShard = { name = "Blizzard Shard", world = 2, biome = "Snowfield", condition = "Blizzard", dropCount = 1, respawnSeconds = 240, nodes = 3, color = "E0F7FF", shape = "Block", glows = true },
	SkaddleCore = { name = "Skaddle's Core", world = 2, biome = "Snowfield", condition = "Quest", dropCount = 1, respawnSeconds = 0, nodes = 0, color = "F7F9FC", shape = "Ball" },
}

return list
