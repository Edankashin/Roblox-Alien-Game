--!strict
-- The worlds in order. Every world has one special weather with a signature alien that spawns only while
-- it runs (World 1: Rain and the Thunderhog). The clock rolls the special weather with `chance` each
-- time the weather changes and picks evenly among `normal` otherwise. Later worlds' ids and species
-- are placeholders until those worlds are built; the Spawns tables key species lists by these ids.
export type SpecialWeather = { id: string, speciesId: string, chance: number }
export type WorldDef = {
	id: number,
	name: string,
	biomes: { string },
	warden: string,
	rule: string,
	weather: { normal: { string }, special: SpecialWeather },
	placeId: number, -- the Roblox place that runs this world (TeleportService); 0 until it is published
	built: boolean, -- its layout, spawn tables and species exist; false while the world is only designed (the data lint skips its species references)
	catchVariant: string?, -- data/CatchVariants row every catch in this world runs unless the species says otherwise; nil = Standard
}

local list: { [number]: WorldDef } = {
	-- The home planet (section 10): the player's own place, unlocked by the first launch; no warden, no spawns, no
	-- special weather (an empty warden and species id are skipped by the data lint). ipairs and # never see [0].
	[0] = { id = 0, name = "Home Planet", biomes = { "Home" }, warden = "", rule = "Home", weather = { normal = { "Clear", "Rain" }, special = { id = "Clear", speciesId = "", chance = 0 } }, placeId = 73774874008460, built = true },
	[1] = { id = 1, name = "Verdant Crash Site", biomes = { "Meadow", "Forest", "Cave" }, warden = "Gaiabloom", rule = "DayNightRain", weather = { normal = { "Clear", "Fog" }, special = { id = "Rain", speciesId = "Thunderhog", chance = 0.34 } } , placeId = 0, built = true },
	[2] = { id = 2, name = "Frostbyte", biomes = { "Snowfield", "IceCave", "GeyserField" }, warden = "Skaddle", rule = "Blizzard", weather = { normal = { "Clear", "Snow" }, special = { id = "Blizzard", speciesId = "Frostfang", chance = 0.3 } } , placeId = 112829778258240, built = true },
	[3] = { id = 3, name = "Neon Grid", biomes = { "Rooftops", "ServerFarm", "Undercity" }, warden = "Hephaestron", rule = "PowerSurge", weather = { normal = { "Clear", "Smog" }, special = { id = "PowerSurge", speciesId = "Voltwisp", chance = 0.3 } } , placeId = 0, built = false, catchVariant = "Chase" },
	[4] = { id = 4, name = "Emberfall", biomes = { "LavaFields", "ObsidianCaves", "AshForest" }, warden = "Vulcanine", rule = "HeatMeter", weather = { normal = { "Clear", "Haze" }, special = { id = "Ashfall", speciesId = "Cinderling", chance = 0.3 } } , placeId = 0, built = false },
	[5] = { id = 5, name = "Tidepool", biomes = { "Reef", "KelpForest", "Trench" }, warden = "Poseidolphin", rule = "Tides", weather = { normal = { "Clear", "Mist" }, special = { id = "KingTide", speciesId = "Pearlback", chance = 0.3 } } , placeId = 0, built = false, catchVariant = "Reel" },
	[6] = { id = 6, name = "Dreamdrift", biomes = { "CandyCliffs", "CloudSea", "MusicBoxHollow" }, warden = "Morpheep", rule = "GravityFlip", weather = { normal = { "Clear", "Drift" }, special = { id = "GravityFlip", speciesId = "Floatling", chance = 0.3 } } , placeId = 0, built = false },
	[7] = { id = 7, name = "The Void Hub", biomes = { "Gate" }, warden = "Nyxling", rule = "Endgame", weather = { normal = { "Clear" }, special = { id = "Eclipse", speciesId = "Shadeling", chance = 0.25 } } , placeId = 0, built = false },
}

return list
