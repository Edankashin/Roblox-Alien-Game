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
	},
	Forest = {
		Any = { "Glimmo", "Twiglet", "Zapfinch" },
		Day = {},
		Night = { "Lanternewt" },
		Rain = {},
	},
	Cave = {
		Any = { "Pebblet", "Snailbyte", "Rocklobber" },
		Day = {},
		Night = { "Gloomoth" },
		Rain = {},
	},
}

return {
	Biomes = Biomes,
	-- vertical slice: only the Meadow is live
	LiveBiomes = { "Meadow" },
}
