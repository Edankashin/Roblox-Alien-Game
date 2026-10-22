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
	GrassTop = { id = 72071000941144 },
	GrassSide = { id = 93929327563572 },
	Dirt = { id = 87039096831974 },
	Path = { id = 128350674031844 },
	Stone = { id = 73817659093323 },
	Sand = { id = 92025485252134 },
	Water = { id = 97411225063277 },
	WoodPlank = { id = 74331885950873 },
	Snow = { id = 81900410980982 },
	SnowSide = { id = 101995460155466 },
	PackedSnow = { id = 85243641260203 },
	Ice = { id = 117869840481831 },
	FrozenWater = { id = 77491655426458 },
	Rock = { id = 132549908191567 },
	MoonPath = { id = 83599135331067 },
	MoonGrass = { id = 111155293601459 },
	GlowWater = { id = 99487710748544 },
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
