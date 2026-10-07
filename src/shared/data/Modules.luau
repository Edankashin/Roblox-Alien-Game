--!strict
-- Ship modules per world. Each has three gates: Scrap, a key material, and assembly time at summed work speed 1x.
-- unlocksSlots: completing the module raises every station to this many slots (free slot growth, decision 16).
export type ModuleDef = { id: string, name: string, scrap: number, keyMaterial: string, keyCount: number, assemblySeconds: number, job: string, weight: number, unlocksSlots: number? }

local Worlds: { [number]: { ModuleDef } } = {
	-- World 1 pacing (2026-10-07, Ethan: not beatable in a day without hours of play; progress shows early, the goal far off;
	-- decision B14). Continuous play launches after about 3.9 h (tools/balance.py, optimistic) to 6 h (tools/progression_sim.py);
	-- one session a day launches on about day 5 at 30 min, day 6 at 45 min, day 10 at 20 min. Freebies are under 3% of the
	-- Scrap; the gates resting and offline time cannot pay are the night crystals, the rain shards and the Warden.
	[1] = {
		{ id = "HullFrame", name = "Hull Frame", scrap = 300, keyMaterial = "WreckPlate", keyCount = 3, assemblySeconds = 60, job = "Build", weight = 0.10 },
		{ id = "Thrusters", name = "Thrusters", scrap = 2000, keyMaterial = "Glowroot", keyCount = 4, assemblySeconds = 420, job = "Build", weight = 0.15, unlocksSlots = 2 },
		{ id = "LifePod", name = "Life Pod", scrap = 45000, keyMaterial = "CaveCrystal", keyCount = 9, assemblySeconds = 3600, job = "Spark", weight = 0.20 },
		{ id = "NavArray", name = "Nav Array", scrap = 180000, keyMaterial = "StormShard", keyCount = 12, assemblySeconds = 7200, job = "Spark", weight = 0.25, unlocksSlots = 3 },
		{ id = "EngineCore", name = "Engine Core", scrap = 600000, keyMaterial = "WardenCore", keyCount = 1, assemblySeconds = 14400, job = "Build", weight = 0.30 },
	},
	-- World 2, Frostbyte: assembly at 1.5x World 1. Scrap is keyed to what a median player carries in from the retuned World 1
	-- (about 5,000 Scrap/min of crew income, tools/balance.py): the first module costs about 12 minutes of that income, then a
	-- steady climb, so World 2 takes about 1.5 times World 1's play time (5.6 h continuous, day 7 at 30 min a day; decision B14).
	-- The Frost Engine takes Skaddle's Core from the finale.
	[2] = {
		{ id = "HeatShield", name = "Heat Shield", scrap = 60000, keyMaterial = "IcePlate", keyCount = 5, assemblySeconds = 90, job = "Build", weight = 0.10 },
		{ id = "IceDrill", name = "Ice Drill", scrap = 150000, keyMaterial = "GeyserPearl", keyCount = 5, assemblySeconds = 630, job = "Build", weight = 0.15, unlocksSlots = 2 },
		{ id = "CryoPod", name = "Cryo Pod", scrap = 300000, keyMaterial = "FrostCore", keyCount = 8, assemblySeconds = 5400, job = "Spark", weight = 0.20 },
		{ id = "BeaconArray", name = "Beacon Array", scrap = 600000, keyMaterial = "BlizzardShard", keyCount = 8, assemblySeconds = 10800, job = "Spark", weight = 0.25, unlocksSlots = 3 },
		{ id = "FrostEngine", name = "Frost Engine", scrap = 1000000, keyMaterial = "SkaddleCore", keyCount = 1, assemblySeconds = 21600, job = "Build", weight = 0.30 },
	},
}

return { Worlds = Worlds }
