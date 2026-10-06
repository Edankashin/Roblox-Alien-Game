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

-- The imported prop names (ReplicatedStorage.<Config.ModelFolderName>.<Config.PropsFolderName>) a world's
-- builder tries before its part-built placeholders: scattered kinds are lists (one is picked at random
-- per landmark; an empty list keeps the placeholder), the shrine's two pieces are single names.
export type PropNames = {
	tree: { string },
	rock: { string },
	cone: { string },
	shrineStone: string,
	pedestal: string,
	shrine: string?, -- a hero Shrine model (Look plan L3) that replaces the stone ring and glow when it exists; the pedestal anchor stays
}

-- A hero landmark (Look plan L3): one imported set piece placed once at a fixed point. Nothing is built
-- when its prop is missing (no placeholder), scatter keeps clear of it, and the client can find it by
-- landmarkId when one is set. Yaw is degrees about the up axis; a model's front is +Z as exported.
export type Landmark = {
	name: string, -- the prop under ReplicatedStorage.<ModelFolderName>.<PropsFolderName> (Shared/Props)
	x: number,
	z: number,
	yaw: number, -- degrees
	scale: number,
	clearRadius: number, -- open-floor and region scatter keep this far from the point
	landmarkId: string?, -- LandmarkId attribute for the client's waypoints; nil for pure scenery
}

-- A fixed point on the floor with the way a placeholder faces (yaw in degrees about the up axis), and a box size
-- in studs: the home planet's kiosk and mailbox.
export type Spot = { x: number, z: number, yaw: number }
export type Size3 = { x: number, y: number, z: number }

export type Layout = {
	WorldId: number, -- the world this layout belongs to (Worlds.luau)
	BaseBiome: string, -- the biome everywhere outside a region (Types.Biome)
	Regions: { [string]: Region }, -- keyed by biome name
	RegionPatchThickness: number, -- the coloured floor patch sits this high on the floor
	RegionRoofThickness: number, -- the flat slab over a roofed region
	RegionEdgeMargin: number, -- nodes and region scatter stay this far inside the region edge
	RegionWallRadius: number, -- the rim pillars' radius
	Shrine: Shrine,
	Props: PropNames?, -- imported meshes to use where they exist; nil or a missing prop means the placeholder
	Landmarks: { Landmark }?, -- hero set pieces at fixed points, built only when their prop exists
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
	-- the home planet's plot (world 0 only; the world builder draws it when PlotCells is set)
	PlotCells: number?,
	PlotCellStuds: number?,
	PlotOffsetStuds: number?,
	PlotColor: string?,
	PlotThickness: number?,
	-- the home planet's trophy hangar, spin wheel kiosk and mailbox (world 0 only; the builder draws each when its
	-- fields are set, the client reads the same numbers for the hulls and the interaction distances)
	HangarCenterZ: number?,
	HangarSpacingStuds: number?,
	HangarScale: number?,
	HangarPadRadius: number?,
	HangarPadColor: string?,
	Kiosk: Spot?,
	KioskSize: Size3?,
	KioskColor: string?,
	KioskInteractDistance: number?,
	Mailbox: Spot?,
	MailboxSize: Size3?,
	MailboxColor: string?,
	MailboxInteractDistance: number?,
}

local Meadow = require(script.Parent.Meadow)
local Frostbyte = require(script.Parent.Frostbyte)
local Home = require(script.Parent.Home)

local list: { [number]: Layout } = {
	[0] = Home, -- the home planet (section 10): no regions, no scatter, a plot for the house grid
	[1] = Meadow,
	[2] = Frostbyte,
}

return list
