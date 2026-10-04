--!strict
-- Found only by exploring. Nodes respawn; condition gates when they are visible.
return {
	WreckPlate = { name = "Wreck Plate", world = 1, biome = "Meadow", condition = "Any", dropCount = 1, respawnSeconds = 30 },
	Glowroot = { name = "Glowroot", world = 1, biome = "Forest", condition = "Any", dropCount = 1, respawnSeconds = 120 },
	CaveCrystal = { name = "Cave Crystal", world = 1, biome = "Cave", condition = "Night", dropCount = 1, respawnSeconds = 180 },
	StormShard = { name = "Storm Shard", world = 1, biome = "Meadow", condition = "Rain", dropCount = 1, respawnSeconds = 240 },
	WardenCore = { name = "Warden's Core", world = 1, biome = "Meadow", condition = "Quest", dropCount = 1, respawnSeconds = 0 },
}
