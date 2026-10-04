--!strict
-- Three jobs at launch, named to feel like play. Tinker arrives with World 3.
return {
	Order = { "Gather", "Build", "Spark" },
	Jobs = {
		Gather = { name = "Gather", station = "Picnic Table", verb = "gathering", commonsOnly = true, unlockWorld = 1 },
		Build = { name = "Build", station = "Treehouse Bench", verb = "building", commonsOnly = false, unlockWorld = 1 },
		Spark = { name = "Spark", station = "Glow Flower", verb = "sparking", commonsOnly = false, unlockWorld = 1 },
		Tinker = { name = "Tinker", station = "Gadget Nook", verb = "tinkering", commonsOnly = false, unlockWorld = 3 },
	},
}
