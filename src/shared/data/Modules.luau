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
}

return { Worlds = Worlds }
