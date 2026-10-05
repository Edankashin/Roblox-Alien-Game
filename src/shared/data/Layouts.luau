--!strict
-- One placeholder layout per world, by world id: the numbers the server's world builder
-- (Services/Meadow), Shared/Biomes and the node scatter (Services/Materials) read for the place they run
-- in (Shared/Place picks the entry by the Workspace attribute WorldId). Every layout has the same keys,
-- typed here as one Layout shape, so the builder never asks which world it is in: a region with a
-- roofHeight gets a roof and walls, one with a coneCount gets geyser cones, and everything outside a
-- region is the layout's BaseBiome. World 1 is data/Meadow.luau, World 2 is data/Frostbyte.luau.

-- A biome region: a coloured floor patch (a circle at x, z) with its own scatter. Its key in a layout's
-- Regions table is the biome name (Types.Biome).
export type Region = {
	x: number,
	z: number,
	radius: number,
	floorColor: string,
	treeCount: number, -- trees scattered inside the region (on top of the global scatter)
	rockCount: number,
	roofHeight: number?, -- a flat roof slab at this height makes a region read as a cave
	roofColor: string?,
	wallCount: number?, -- upright pillars around the rim, leaving gaps to walk through
	wallColor: string?,
	coneCount: number?, -- geyser cones (upright tapered stacks) scattered inside the region
	coneRadius: number?, -- the cone's base radius
	coneHeight: number?,
	coneColor: string?,
}

-- The Shrine of the Warden: a stone ring with a pedestal, the world's landmark (Field Notes finale).
export type Shrine = {
	x: number,
	z: number,
	radius: number,
	stoneCount: number,
	stoneHeight: number,
	stoneColor: string,
	pedestalColor: string,
	glowColor: string,
}

export type Layout = {
	WorldId: number, -- the world this layout belongs to (Worlds.luau)
	BaseBiome: string, -- the biome everywhere outside a region (Types.Biome)
	Regions: { [string]: Region }, -- keyed by biome name
	RegionPatchThickness: number, -- the coloured floor patch sits this high on the floor
	RegionRoofThickness: number, -- the flat slab over a roofed region
	RegionEdgeMargin: number, -- nodes and region scatter stay this far inside the region edge
	RegionWallRadius: number, -- the rim pillars' radius
	Shrine: Shrine,
	Seed: number, -- deterministic scatter so every server builds the same world
	FloorSize: number,
	FloorThickness: number,
	FloorColor: string,
	CampPadRadius: number,
	CampPadThickness: number,
	CampPadColor: string,
	SpawnPadSize: number,
	SpawnPadThickness: number,
	SpawnPadColor: string,
	RockCount: number,
	RockColor: string,
	RockSizeMin: number,
	RockSizeMax: number,
	TreeCount: number,
	TrunkColor: string,
	TrunkRadius: number,
	TrunkHeightMin: number,
	TrunkHeightMax: number,
	LeavesColor: string,
	LeavesRadiusMin: number,
	LeavesRadiusMax: number,
	ScatterMinFromCamp: number, -- rocks and trees keep this far from the origin (the ship and stations sit inside)
	ScatterEdgeMargin: number, -- and this far from the floor edge
	-- key material nodes (Materials service), scattered with their own seed; counts, colours and shapes
	-- per material live in KeyMaterials.luau
	NodeSeed: number,
	NodeMinFromCamp: number, -- base-biome nodes sit in this ring around the camp
	NodeMaxFromCamp: number,
	NodeMinSeparation: number,
	NodeSize: number,
	NodeHoverStuds: number,
	NodeSpinSeconds: number, -- client-side slow turn
	NodeWaitingTransparency: number, -- a node whose condition is not met shows as a ghost, not a target
}

local Meadow = require(script.Parent.Meadow)
local Frostbyte = require(script.Parent.Frostbyte)

local list: { [number]: Layout } = {
	[1] = Meadow,
	[2] = Frostbyte,
}

return list
