--!strict
-- Ship modules per world. Each has three gates: Scrap, a key material, and assembly time at summed work speed 1x.
-- unlocksSlots: completing the module raises every station to this many slots (free slot growth, decision 16).
export type ModuleDef = { id: string, name: string, scrap: number, keyMaterial: string, keyCount: number, assemblySeconds: number, job: string, weight: number, unlocksSlots: number? }

local Worlds: { [number]: { ModuleDef } } = {
	[1] = {
		{ id = "HullFrame", name = "Hull Frame", scrap = 300, keyMaterial = "WreckPlate", keyCount = 3, assemblySeconds = 60, job = "Build", weight = 0.10 },
		{ id = "Thrusters", name = "Thrusters", scrap = 1500, keyMaterial = "Glowroot", keyCount = 3, assemblySeconds = 300, job = "Build", weight = 0.15, unlocksSlots = 2 },
		{ id = "LifePod", name = "Life Pod", scrap = 5000, keyMaterial = "CaveCrystal", keyCount = 3, assemblySeconds = 720, job = "Spark", weight = 0.20 },
		{ id = "NavArray", name = "Nav Array", scrap = 12000, keyMaterial = "StormShard", keyCount = 2, assemblySeconds = 1500, job = "Spark", weight = 0.25, unlocksSlots = 3 },
		{ id = "EngineCore", name = "Engine Core", scrap = 30000, keyMaterial = "WardenCore", keyCount = 1, assemblySeconds = 2700, job = "Build", weight = 0.30 },
	},
	-- World 2, Frostbyte: Scrap at 1.6x World 1, assembly at 1.5x. The Frost Engine takes Skaddle's Core from the finale.
	[2] = {
		{ id = "HeatShield", name = "Heat Shield", scrap = 480, keyMaterial = "IcePlate", keyCount = 3, assemblySeconds = 90, job = "Build", weight = 0.10 },
		{ id = "IceDrill", name = "Ice Drill", scrap = 2400, keyMaterial = "GeyserPearl", keyCount = 3, assemblySeconds = 450, job = "Build", weight = 0.15, unlocksSlots = 2 },
		{ id = "CryoPod", name = "Cryo Pod", scrap = 8000, keyMaterial = "FrostCore", keyCount = 3, assemblySeconds = 1080, job = "Spark", weight = 0.20 },
		{ id = "BeaconArray", name = "Beacon Array", scrap = 19200, keyMaterial = "BlizzardShard", keyCount = 2, assemblySeconds = 2250, job = "Spark", weight = 0.25, unlocksSlots = 3 },
		{ id = "FrostEngine", name = "Frost Engine", scrap = 48000, keyMaterial = "SkaddleCore", keyCount = 1, assemblySeconds = 4050, job = "Build", weight = 0.30 },
	},
}

return { Worlds = Worlds }
