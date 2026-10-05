--!strict
-- Which species can appear where and when. The spawner picks a tier by luck-adjusted share,
-- then a species of that tier that is available in the biome under the current condition.
-- "Any" species are always available; "Day", "Night", "Rain" only during that condition.
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
}

return {
	Biomes = Biomes,
	-- World 1 biomes that exist as regions on the floor (see data/Meadow.luau Regions)
	LiveBiomes = { "Meadow", "Forest", "Cave" },
}
