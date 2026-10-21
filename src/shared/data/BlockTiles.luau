--!strict
-- ReplicatedStorage.Shared.data.BlockTiles: the block-cell ground tiles (B44) the generated worlds wear. One PNG per key at
-- assets/textures/blocky_tiles/<Key>.png, 64 x 64 px, one tile = 2 x 2 studs at the world cell of 0.25 studs (8 cells of 8 px),
-- made by the props worker with tools/blocky/cells.py. The keys are shared with the props worker; data/WorldKit's ground kinds name
-- them per face (top, side, body). Ids are Decal/Image asset ids, 0 until the uploader fills them in: while a key's id is 0,
-- Services/Meadow gives that face no Texture and the part keeps its kind's plain colour and fitting Material (data/WorldKit), so the
-- world reads the same, flatter, with or without the tiles.

local Ids: { [string]: number } = {
	GrassTop = 0,
	GrassSide = 0,
	Dirt = 0,
	Path = 0,
	Stone = 0,
	Sand = 0,
	Water = 0,
	WoodPlank = 0,
	Snow = 0,
	SnowSide = 0,
	PackedSnow = 0,
	Ice = 0,
	FrozenWater = 0,
	Rock = 0,
}

-- The Roblox Material a face falls back to while its tile id is 0 (a cap uses its kind's own Material, data/WorldKit; a body and a
-- solid's sides use their tile's).
local FallbackMaterial: { [string]: string } = {
	GrassTop = "Grass",
	GrassSide = "Grass",
	Dirt = "Ground",
	Path = "Cobblestone",
	Stone = "Slate",
	Sand = "Sand",
	Water = "SmoothPlastic",
	WoodPlank = "WoodPlanks",
	Snow = "Snow",
	SnowSide = "Snow",
	PackedSnow = "Sand",
	Ice = "Ice",
	FrozenWater = "Ice",
	Rock = "Slate",
}

return {
	Ids = Ids,
	FallbackMaterial = FallbackMaterial,
	StudsPerTile = 2, -- a tile covers 2 x 2 studs: one ground block's top, 8 cells across
	-- A cap is 1 stud tall, so its side shows the top half of the side tile (the grass fringe over the first dirt rows): the tile's top
	-- edge is pinned to the cap's top. A body's side tile is pinned to the world's 2-stud rows so neighbouring bodies line up.
	WaterTransparency = 0.35, -- the water tile over the translucent water part
	-- The client's water drift (World.WorldFx): studs a second the water tile slides, and the waterfall's tile, downwards.
	WaterDrift = 0.25,
	FallDrift = 3,
	WaterTag = "WorldWater", -- CollectionService tags the server puts on the generated water and waterfall parts
	FallTag = "WorldFall",
}
