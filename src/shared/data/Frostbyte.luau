--!strict
-- Layout numbers for the placeholder World 2, Frostbyte, the server builds under Workspace.World when
-- the Workspace attribute WorldId is 2 (world2.project.json). Same keys as Meadow.luau; data/Layouts.luau
-- types both as one Layout shape. Placeholder art only: a snow floor with the camp pad at the origin,
-- grey-blue rocks and white-and-blue "pines", and two biome regions drawn as coloured patches: the Ice
-- Cave (roofed and walled like World 1's Cave) and the Geyser Field (open, orange-brown ground, geyser
-- cones instead of trees). Everything outside a region is Snowfield. The shrine is the Warden Skaddle's.
export type Region = {
	x: number,
	z: number,
	radius: number,
	floorColor: string,
	treeCount: number, -- trees scattered inside the region (on top of the global scatter)
	rockCount: number,
	roofHeight: number?, -- a flat roof slab at this height makes the Ice Cave read as a cave
	roofColor: string?,
	wallCount: number?, -- upright pillars around the rim, leaving gaps to walk through
	wallColor: string?,
	coneCount: number?, -- geyser cones: upright tapered stacks, the Geyser Field's "trees"
	coneRadius: number?,
	coneHeight: number?,
	coneColor: string?,
}

local Regions: { [string]: Region } = {
	IceCave = { x = -130, z = -120, radius = 60, floorColor = "9FD3E8", treeCount = 0, rockCount = 20, roofHeight = 14, roofColor = "7FB8D4", wallCount = 26, wallColor = "B9E1F0" },
	GeyserField = { x = 130, z = 120, radius = 70, floorColor = "C98B5A", treeCount = 0, rockCount = 6, coneCount = 14, coneRadius = 3, coneHeight = 7, coneColor = "8C5A3C" },
}

return {
	WorldId = 2,
	BaseBiome = "Snowfield", -- everywhere outside a region
	Regions = Regions,
	RegionPatchThickness = 0.3, -- the coloured floor patch sits this high on the floor
	RegionRoofThickness = 1, -- the flat slab over a roofed region (the Ice Cave ceiling)
	RegionEdgeMargin = 6, -- nodes and region scatter stay this far inside the region edge
	RegionWallRadius = 4, -- 26 pillars of this radius around the Ice Cave rim leave gaps of about 5 studs
	-- the Shrine of the Warden Skaddle: a pale stone ring with an ice-blue glow
	Shrine = { x = 0, z = 155, radius = 10, stoneCount = 8, stoneHeight = 5, stoneColor = "BFD9E6", pedestalColor = "E8F4F8", glowColor = "68C9FE" },
	-- imported prop names (Shared/Props); the placeholder parts below are the fallback when one is missing
	Props = { tree = { "SnowPine", "IceSpire" }, rock = { "IceRock", "IceRockB" }, cone = { "GeyserCone" }, shrineStone = "ShrineStone", pedestal = "Pedestal", shrine = nil }, -- no hero shrine: its moss palette is World 1's
	-- hero set pieces (Look plan L3): the great vent at the Geyser Field's heart (the cones scatter around it),
	-- the ice cave mouth just outside the Ice Cave rim on the camp side, turned to face the camp
	Landmarks = {
		{ name = "GeyserVent", x = 130, z = 120, yaw = 0, scale = 1, clearRadius = 14, landmarkId = "GreatVent" },
		{ name = "IceCaveMouth", x = -82, z = -75, yaw = 47, scale = 1, clearRadius = 14, landmarkId = "IceCaveMouth" },
	},
	Seed = 20261010, -- deterministic scatter so every server builds the same snowfield
	FloorSize = 400,
	FloorThickness = 1,
	FloorColor = "EAF2F8", -- snow
	CampPadRadius = 12,
	CampPadThickness = 0.4,
	CampPadColor = "FFF4DC", -- the same cream as World 1: the camp is the player's, not the planet's
	SpawnPadSize = 6,
	SpawnPadThickness = 0.2,
	SpawnPadColor = "FFC83D",
	RockCount = 24,
	RockColor = "A9B7C0",
	RockSizeMin = 2,
	RockSizeMax = 6,
	TreeCount = 24,
	TrunkColor = "7A8C96", -- snow pines: grey-blue trunks under white-blue crowns
	TrunkRadius = 1.2,
	TrunkHeightMin = 6,
	TrunkHeightMax = 10,
	LeavesColor = "DDEFF5",
	LeavesRadiusMin = 3,
	LeavesRadiusMax = 5,
	ScatterMinFromCamp = 36, -- rocks and trees keep this far from the origin (the ship and stations sit inside)
	ScatterEdgeMargin = 15, -- and this far from the floor edge
	-- key material nodes (Materials service), scattered with their own seed; counts, colours and shapes
	-- per material live in KeyMaterials.luau (world = 2 rows)
	NodeSeed = 20261011,
	NodeMinFromCamp = 40, -- Snowfield nodes sit in this ring around the camp
	NodeMaxFromCamp = 85,
	NodeMinSeparation = 8,
	NodeSize = 3,
	NodeHoverStuds = 0.5,
	NodeSpinSeconds = 8, -- client-side slow turn
	NodeWaitingTransparency = 0.6, -- a node whose condition is not met shows as a ghost, not a target
	-- no house plot on a wild world (the home planet's layout sets these); spelled out so the Layout shape matches
	PlotCells = nil,
	PlotCellStuds = nil,
	PlotOffsetStuds = nil,
	PlotColor = nil,
	PlotThickness = nil,
}
