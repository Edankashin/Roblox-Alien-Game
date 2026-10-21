--!strict
-- ReplicatedStorage.Shared.data.BlockTiles: the block-cell ground tiles (B44) the generated worlds wear. One PNG per key at
-- assets/textures/blocky_tiles/<Key>.png, 64 x 64 px, one tile = 2 x 2 studs at the world cell of 0.25 studs (8 cells of 8 px),
-- made by the props worker with tools/blocky/cells.py. The keys are shared with the props worker; data/WorldKit's ground kinds name
-- them per face (top, side, body). Ids are Decal/Image asset ids, 0 until the uploader fills them in: while a key's id is 0,
-- Services/Meadow gives that face no Texture and the part keeps its kind's plain colour and fitting Material (data/WorldKit), so the
-- world reads the same, flatter, with or without the tiles. tools/upload_assets.py fills each row's id (the `<Key> = { id = 0 }`
-- convention) from assets/textures/blocky_tiles/asset_ids.json. MoonPath, MoonGrass and GlowWater are the Starhollow Forest's
-- (B48): the pale lavender path, the moonlit grass and the glowing water.

local Ids: { [string]: { id: number } } = {
	GrassTop = { id = 0 },
	GrassSide = { id = 0 },
	Dirt = { id = 0 },
	Path = { id = 0 },
	Stone = { id = 0 },
	Sand = { id = 0 },
	Water = { id = 0 },
	WoodPlank = { id = 0 },
	Snow = { id = 0 },
	SnowSide = { id = 0 },
	PackedSnow = { id = 0 },
	Ice = { id = 0 },
	FrozenWater = { id = 0 },
	Rock = { id = 0 },
	MoonPath = { id = 0 },
	MoonGrass = { id = 0 },
	GlowWater = { id = 0 },
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
	MoonPath = "SmoothPlastic",
	MoonGrass = "Grass",
	GlowWater = "Neon",
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
