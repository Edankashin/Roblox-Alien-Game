--!strict
-- Layout numbers for the placeholder World 1 the server builds under Workspace.World.
-- Placeholder art only: one flat floor with the camp pad at the origin, scattered rocks and trees, and
-- two biome regions drawn as coloured patches: a dense Forest grove and a roofed Cave. Everything
-- outside a region is Meadow. Shared/Biomes.luau answers "which biome is this point in" from Regions.
export type Region = {
	x: number,
	z: number,
	radius: number,
	floorColor: string,
	treeCount: number, -- trees scattered inside the region (on top of the global scatter)
	rockCount: number,
	roofHeight: number?, -- a flat roof slab at this height makes the Cave read as a cave
	roofColor: string?,
	wallCount: number?, -- upright pillars around the rim, leaving gaps to walk through
	wallColor: string?,
	coneCount: number?, -- geyser cones (World 2's Geyser Field); none in the meadow
	coneRadius: number?,
	coneHeight: number?,
	coneColor: string?,
}

local Regions: { [string]: Region } = {
	Forest = { x = 130, z = 120, radius = 70, floorColor = "2E6B2B", treeCount = 40, rockCount = 4 },
	Cave = { x = -130, z = -120, radius = 60, floorColor = "5A5A66", treeCount = 0, rockCount = 28, roofHeight = 14, roofColor = "4A4A55", wallCount = 26, wallColor = "6E6E7A" },
}

return {
	WorldId = 1,
	BaseBiome = "Meadow", -- everywhere outside a region
	Regions = Regions,
	RegionPatchThickness = 0.3, -- the coloured floor patch sits this high on the floor
	RegionRoofThickness = 1, -- the flat slab over a roofed region (the Cave ceiling)
	RegionEdgeMargin = 6, -- nodes and region scatter stay this far inside the region edge
	RegionWallRadius = 4, -- 26 pillars of this radius around the Cave rim leave gaps of about 5 studs
	-- the Shrine of the Warden: a stone ring with a pedestal, the world's landmark (Field Notes finale)
	Shrine = { x = 0, z = 155, radius = 10, stoneCount = 8, stoneHeight = 5, stoneColor = "9E9E8E", pedestalColor = "C8C4A8", glowColor = "2ECC71" },
	Seed = 20261004, -- deterministic scatter so every server builds the same meadow
	FloorSize = 400,
	FloorThickness = 1,
	FloorColor = "6FBF4A",
	CampPadRadius = 12,
	CampPadThickness = 0.4,
	CampPadColor = "FFF4DC",
	SpawnPadSize = 6,
	SpawnPadThickness = 0.2,
	SpawnPadColor = "FFC83D",
	RockCount = 24,
	RockColor = "8E8E8E",
	RockSizeMin = 2,
	RockSizeMax = 6,
	TreeCount = 30,
	TrunkColor = "7B4A2D",
	TrunkRadius = 1.2,
	TrunkHeightMin = 6,
	TrunkHeightMax = 10,
	LeavesColor = "3F9B3A",
	LeavesRadiusMin = 3,
	LeavesRadiusMax = 5,
	ScatterMinFromCamp = 36, -- rocks and trees keep this far from the origin (the ship and stations sit inside)
	ScatterEdgeMargin = 15, -- and this far from the floor edge
	-- key material nodes (Materials service), scattered with their own seed; counts, colours and shapes
	-- per material live in KeyMaterials.luau
	NodeSeed = 20261005,
	NodeMinFromCamp = 40, -- Meadow nodes sit in this ring around the camp
	NodeMaxFromCamp = 85, -- close enough that the tutorial's three plates are a short walk
	NodeMinSeparation = 8,
	NodeSize = 3,
	NodeHoverStuds = 0.5,
	NodeSpinSeconds = 8, -- client-side slow turn
	NodeWaitingTransparency = 0.6, -- a node whose condition is not met shows as a ghost, not a target
}
