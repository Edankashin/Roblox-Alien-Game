--!strict
local Types = require(script.Parent.Parent.types.Types)

-- World 1 roster. The vertical slice spawns the six marked in Spawns.luau; the rest are defined so the codex can show silhouettes.
local list: { Types.SpeciesDef } = {
	{ id = "Mossbop", name = "Mossbop", concept = "moss ball, eyes", tier = "Common", jobs = { { job = "Gather", level = 1 } }, biome = "Meadow", condition = "Any", world = 1, placeholder = { shape = "Ball", color = "6BCB3F", scale = 1 }, voiceLine = "bop" },
	{ id = "Pebblet", name = "Pebblet", concept = "pebble with legs", tier = "Common", jobs = { { job = "Gather", level = 1 } }, biome = "Cave", condition = "Any", world = 1, placeholder = { shape = "Block", color = "9A9A9A", scale = 0.9 }, voiceLine = "tik" },
	{ id = "Glimmo", name = "Glimmo", concept = "jelly firefly", tier = "Common", jobs = { { job = "Spark", level = 1 } }, biome = "Forest", condition = "Any", world = 1, placeholder = { shape = "Ball", color = "FFE066", scale = 0.8 }, voiceLine = "glim" },
	{ id = "Twiglet", name = "Twiglet", concept = "stick bug, leaf hat", tier = "Common", jobs = { { job = "Gather", level = 1 } }, biome = "Forest", condition = "Any", world = 1, placeholder = { shape = "Cylinder", color = "8B5A2B", scale = 1 }, voiceLine = "twig" },
	{ id = "Puffpuff", name = "Puffpuff", concept = "dandelion puff, face", tier = "Common", jobs = { { job = "Build", level = 1 } }, biome = "Meadow", condition = "Any", world = 1, placeholder = { shape = "Ball", color = "F7F7F7", scale = 1 }, voiceLine = "puff" },
	{ id = "Snailbyte", name = "Snailbyte", concept = "snail, metal shell", tier = "Uncommon", jobs = { { job = "Gather", level = 2 } }, biome = "Cave", condition = "Any", world = 1, placeholder = { shape = "Ball", color = "7FB3D5", scale = 1 }, voiceLine = "byte" },
	{ id = "Buzzlebee", name = "Buzzlebee", concept = "bee, tiny backpack", tier = "Uncommon", jobs = { { job = "Gather", level = 2 } }, biome = "Meadow", condition = "Day", world = 1, placeholder = { shape = "Ball", color = "F4C542", scale = 0.8 }, voiceLine = "bzz" },
	{ id = "Lanternewt", name = "Lanternewt", concept = "newt, glowing tail", tier = "Uncommon", jobs = { { job = "Spark", level = 2 } }, biome = "Forest", condition = "Night", world = 1, placeholder = { shape = "Cylinder", color = "FF8C42", scale = 1 }, voiceLine = "newt" },
	{ id = "Rocklobber", name = "Rocklobber", concept = "crab, boulder claws", tier = "Rare", jobs = { { job = "Gather", level = 3 } }, biome = "Cave", condition = "Any", world = 1, placeholder = { shape = "Block", color = "C0392B", scale = 1.1 }, voiceLine = "clack" },
	{ id = "Zapfinch", name = "Zapfinch", concept = "bird, antenna crest", tier = "Rare", jobs = { { job = "Spark", level = 3 } }, biome = "Forest", condition = "Any", world = 1, placeholder = { shape = "Ball", color = "5DADE2", scale = 0.9 }, voiceLine = "zap" },
	{ id = "Sparkfox", name = "Sparkfox", concept = "fox, glowing paintbrush tail", tier = "Rare", jobs = { { job = "Build", level = 3 } }, biome = "Meadow", condition = "Any", world = 1, placeholder = { shape = "Ball", color = "FF6B35", scale = 1.1 }, voiceLine = "yip" },
	{ id = "Thunderhog", name = "Thunderhog", concept = "hedgehog, lightning quills", tier = "Epic", jobs = { { job = "Spark", level = 3 }, { job = "Build", level = 3 } }, biome = "Meadow", condition = "Rain", world = 1, ride = "Sprint", placeholder = { shape = "Ball", color = "8E44AD", scale = 1.2 }, voiceLine = "zzrt" },
	{ id = "Gloomoth", name = "Gloomoth", concept = "moth, crystal wings", tier = "Epic", jobs = { { job = "Gather", level = 3 }, { job = "Spark", level = 4 } }, biome = "Cave", condition = "Night", world = 1, placeholder = { shape = "Ball", color = "A569BD", scale = 1.2 }, voiceLine = "flut" },
	{ id = "Gaiabloom", name = "Gaiabloom", concept = "stag, tree antlers, flowers bloom where it steps", tier = "Legendary", jobs = { { job = "Gather", level = 5 }, { job = "Build", level = 5 }, { job = "Spark", level = 5 } }, biome = "Meadow", condition = "Quest", world = 1, ride = "Sprint", placeholder = { shape = "Ball", color = "2ECC71", scale = 1.25 }, voiceLine = "bloom" },
	{ id = "Panpipe", name = "Panpipe", concept = "goat, reed pipes", tier = "Secret", jobs = { { job = "Gather", level = 5 }, { job = "Build", level = 5 }, { job = "Spark", level = 5 } }, biome = "Meadow", condition = "Quest", world = 1, placeholder = { shape = "Ball", color = "222222", scale = 1.3 }, voiceLine = "toot" },
}

local byId: { [string]: Types.SpeciesDef } = {}
for _, def in ipairs(list) do
	byId[def.id] = def
end

return { List = list, ById = byId }
