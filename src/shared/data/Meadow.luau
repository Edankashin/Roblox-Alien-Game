--!strict
-- Layout numbers for the placeholder Meadow the server builds under Workspace.World.
-- Placeholder art only: flat floor, a camp pad at the origin, scattered rocks and trees.
return {
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
	-- key material nodes (Materials service), scattered with their own seed
	NodeSeed = 20261005,
	WreckPlateNodes = 6,
	NodeMinFromCamp = 40,
	NodeMaxFromCamp = 85, -- close enough that the tutorial's three plates are a short walk
	NodeMinSeparation = 8,
	NodeSize = 3,
	NodeColor = "8A9BA8",
	NodeHoverStuds = 0.5,
}
