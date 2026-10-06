--!strict
-- Layout numbers for the home planet (docs/GAME_DESIGN.md section 10; the plan's milestone 42a), world id 0:
-- the player's own place, unlocked by the first launch. One small floor with the camp pad at the origin (the
-- ship and the stations still work here), the plot for the house grid on the far side (42a's second part), no
-- biome regions, no scatter, no key-material nodes, no shrine built (Meadow skips it at home; the Shrine row
-- below only satisfies the Layout shape). Every Layout key is here because the builder reads them all.

export type Region = {
	x: number,
	z: number,
	radius: number,
	floorColor: string,
	treeCount: number,
	rockCount: number,
	roofHeight: number?,
	roofColor: string?,
	wallCount: number?,
	wallColor: string?,
	coneCount: number?,
	coneRadius: number?,
	coneHeight: number?,
	coneColor: string?,
}

local Regions: { [string]: Region } = {}

return {
	WorldId = 0,
	BaseBiome = "Home", -- the whole floor; nothing spawns on it
	Regions = Regions,
	RegionPatchThickness = 0.3,
	RegionRoofThickness = 1,
	RegionEdgeMargin = 6,
	RegionWallRadius = 4,
	-- never built at home (the builder skips the shrine on world 0); the row keeps the Layout shape whole
	Shrine = { x = 0, z = 90, radius = 10, stoneCount = 0, stoneHeight = 5, stoneColor = "9E9E8E", pedestalColor = "C8C4A8", glowColor = "2ECC71" },
	Props = { tree = {}, rock = {}, cone = {}, shrineStone = "ShrineStone", pedestal = "Pedestal", shrine = nil },
	Landmarks = {},
	Seed = 20261006,
	FloorSize = 200,
	FloorThickness = 1,
	FloorColor = "9ED6F0",
	CampPadRadius = 12,
	CampPadThickness = 0.4,
	CampPadColor = "FFF4DC",
	SpawnPadSize = 6,
	SpawnPadThickness = 0.2,
	SpawnPadColor = "FFC83D",
	RockCount = 0,
	RockColor = "8E8E8E",
	RockSizeMin = 2,
	RockSizeMax = 6,
	TreeCount = 0,
	TrunkColor = "7B4A2D",
	TrunkRadius = 1.2,
	TrunkHeightMin = 6,
	TrunkHeightMax = 10,
	LeavesColor = "3F9B3A",
	LeavesRadiusMin = 3,
	LeavesRadiusMax = 5,
	ScatterMinFromCamp = 36,
	ScatterEdgeMargin = 15,
	NodeSeed = 20261007,
	NodeMinFromCamp = 40,
	NodeMaxFromCamp = 85,
	NodeMinSeparation = 8,
	NodeSize = 3,
	NodeHoverStuds = 0.5,
	NodeSpinSeconds = 8,
	NodeWaitingTransparency = 0.6,
	-- the plot for the house grid (42a, second part): a square of PlotCells x PlotCells cells of PlotCellStuds, its
	-- near edge PlotOffsetStuds from the camp pad's far side on +Z
	PlotCells = 6,
	PlotCellStuds = 4,
	PlotOffsetStuds = 24,
	PlotColor = "E8DCC0",
	PlotThickness = 0.3,
	-- the trophy hangar (42d): one scaled ship per world the player has launched from, in a row on -Z of the camp
	HangarCenterZ = -40, -- the row's centre, studs from the origin on -Z
	HangarSpacingStuds = 14, -- between ships in the row
	HangarScale = 0.35, -- over the ship hull's own size
	HangarPadRadius = 5,
	HangarPadColor = "B9B9C9",
	-- the spin wheel kiosk and the mailbox (42d): fixed points off the camp pad on -X and +X
	Kiosk = { x = -22, z = 0, yaw = 90 },
	Mailbox = { x = 22, z = 0, yaw = -90 },
	KioskInteractDistance = 10,
	MailboxInteractDistance = 10,
}
