--!strict
-- Which species can appear where and when. The spawner picks a tier by luck-adjusted share,
-- then a species of that tier that is available in the biome under the current condition.
-- "Any" species are always available; "Day", "Night" and a weather id ("Rain", "Blizzard") only during that condition.
export type BiomeTable = { [string]: { string } }

local Biomes: { [string]: BiomeTable } = {
	Meadow = {
		Any = { "Mossbop", "Puffpuff", "Sparkfox" },
		Day = { "Buzzlebee" },
		Night = {},
		Rain = { "Thunderhog" },
		Shower = { "Radish" }, -- Cosmics only exist during a Meteor Shower
	},
	Forest = {
		Any = { "Glimmo", "Twiglet", "Zapfinch" },
		Day = {},
		Night = { "Lanternewt" },
		Rain = {},
		Shower = { "Radish" },
	},
	Cave = {
		Any = { "Pebblet", "Snailbyte", "Rocklobber" },
		Day = {},
		Night = { "Gloomoth" },
		Rain = {},
		Shower = { "Radish" },
	},
	-- World 2, Frostbyte. Blizzard is its special weather; Frostfang is the only species that rolls in it.
	Snowfield = {
		Any = { "Flufflet", "Snowbun", "Reindazzle" },
		Day = { "Pengoo" },
		Night = {},
		Blizzard = { "Frostfang" },
		Shower = { "Fenripup" },
	},
	IceCave = {
		Any = { "Drippo", "Chipmole", "Shellberg" },
		Day = {},
		Night = { "Flapsicle", "Shimmerlynx" },
		Blizzard = {},
		Shower = { "Fenripup" },
	},
	GeyserField = {
		Any = { "Kettlepuff", "Toastoad", "Emberchin", "Capybubble" },
		Day = {},
		Night = {},
		Blizzard = {},
		Shower = { "Fenripup" },
	},
}

return {
	Biomes = Biomes,
	-- The biomes each world's layout draws, by world id: the base biome first, then its two regions
	-- (data/Meadow.luau and data/Frostbyte.luau Regions; Shared/Place picks the world the place runs).
	LiveBiomes = {
		[1] = { "Meadow", "Forest", "Cave" },
		[2] = { "Snowfield", "IceCave", "GeyserField" },
	},
}
