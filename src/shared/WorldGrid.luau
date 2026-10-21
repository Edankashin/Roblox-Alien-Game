--!strict
-- ReplicatedStorage.Shared.WorldGrid: the ground of a generated world (data/WorldGen1, WorldGen2, written by
-- tools/blocky/world_gen.py) as a grid you can ask "how high is the ground here, is there water, may an alien spawn here". Pure: it
-- reads the generated rows and never touches an Instance, so the server (Services/Meadow's surface heights, the Spawner) and the
-- client (World/WorldFx) share one answer and the headless specs run it. A world with no generated ground (the home planet, a world
-- not built yet) has no grid: For returns nil and every caller keeps its flat-floor behaviour.
--
-- Rows (flat number arrays, one row after another):
--   Caps    i, j, w, d, top, kind, sides   a rectangle of columns (grid cells), its top in studs over the camp ground, its kind's index
--                                          in Kinds, and which sides show (bits 1 +X, 2 -X, 4 +Z, 8 -Z). A cap may run under higher
--                                          columns (hidden in the ground there), so a cell's height is the highest cap over it.
--   Bodies  i, j, w, d, top, kind, sides   the column below a cap, from Base up to top, only where a side shows more than the cap.
--   Water   i, j, w, d, bottom, top, kind  a water volume (not solid).
--   Falls   x, z, width, bottom, top, yaw, kind   a vertical sheet of falling water (yaw: degrees, the flow along local +Z).
--   Solids  x0, y0, z0, x1, y1, z1, kind, walk     a box in studs; walk 1 is a deck the ground height follows (a bridge, a log).
--   NoSpawn i, j, w, d                     dry cells nothing spawns on.
--   Place   prop, x, y, z, yaw, scale      a scattered prop (its index in Props), standing on y.

local Types = require(script.Parent.types.Types)

local WorldGrid = {}

export type Grid = {
	gen: Types.WorldGen,
	count: number,
	cell: number,
	origin: number,
	heights: { number }, -- column top by cell index (1-based: j * count + i + 1)
	kinds: { number }, -- index into gen.Kinds
	water: { [number]: number }, -- water top where there is water
	deck: { [number]: number }, -- the top of a walkable solid over the cell, where higher than the column
	nospawn: { [number]: boolean },
}

local CAP, BODY, WATER, SOLID, NOSPAWN, PLACE, FALL = 7, 7, 7, 8, 4, 6, 7
WorldGrid.Stride = { Caps = CAP, Bodies = BODY, Water = WATER, Solids = SOLID, NoSpawn = NOSPAWN, Place = PLACE, Falls = FALL }

-- The generated worlds by world id, loaded on first ask (a client only ever loads its own world's rows).
local loaders: { [number]: () -> Types.WorldGen } = {
	[1] = function(): Types.WorldGen
		return require(script.Parent.data.WorldGen1) :: Types.WorldGen
	end,
	[2] = function(): Types.WorldGen
		return require(script.Parent.data.WorldGen2) :: Types.WorldGen
	end,
}
local cache: { [number]: Grid } = {}

local function forRect(gen: Types.WorldGen, i: number, j: number, w: number, d: number, visit: (number) -> ())
	local count = gen.Count
	for jj = j, j + d - 1 do
		for ii = i, i + w - 1 do
			visit(jj * count + ii + 1)
		end
	end
end

-- Builds the grid from a world's rows: the highest cap over each cell, its water, its deck, its no-spawn flag.
function WorldGrid.Build(gen: Types.WorldGen): Grid
	local count = gen.Count
	local heights = table.create(count * count, gen.Base)
	local kinds = table.create(count * count, 0)
	local caps = gen.Caps
	for r = 1, #caps, CAP do
		local top, kind = caps[r + 4], caps[r + 5]
		forRect(gen, caps[r], caps[r + 1], caps[r + 2], caps[r + 3], function(c: number)
			if kinds[c] == 0 or top > heights[c] then
				heights[c] = top
				kinds[c] = kind
			end
		end)
	end
	-- water resting on its column (water running over a carved room, the nook behind the waterfall, is overhead, not here)
	local water: { [number]: number } = {}
	local rows = gen.Water
	for r = 1, #rows, WATER do
		local bottom, top = rows[r + 4], rows[r + 5]
		forRect(gen, rows[r], rows[r + 1], rows[r + 2], rows[r + 3], function(c: number)
			if bottom <= heights[c] then
				water[c] = top
			end
		end)
	end
	local nospawn: { [number]: boolean } = {}
	local dry = gen.NoSpawn
	for r = 1, #dry, NOSPAWN do
		forRect(gen, dry[r], dry[r + 1], dry[r + 2], dry[r + 3], function(c: number)
			nospawn[c] = true
		end)
	end
	local deck: { [number]: number } = {}
	local solids = gen.Solids
	local cell, origin = gen.Cell, gen.Origin
	for r = 1, #solids, SOLID do
		if solids[r + 7] == 1 then
			local top = solids[r + 4]
			-- every cell whose centre lies inside the box's footprint
			local i0 = math.max(0, math.ceil((solids[r] - origin) / cell - 0.5))
			local i1 = math.min(count - 1, math.floor((solids[r + 3] - origin) / cell - 0.5))
			local j0 = math.max(0, math.ceil((solids[r + 2] - origin) / cell - 0.5))
			local j1 = math.min(count - 1, math.floor((solids[r + 5] - origin) / cell - 0.5))
			for jj = j0, j1 do
				for ii = i0, i1 do
					local c = jj * count + ii + 1
					if top > (deck[c] or -math.huge) then
						deck[c] = top
					end
				end
			end
		end
	end
	return {
		gen = gen,
		count = count,
		cell = cell,
		origin = origin,
		heights = heights,
		kinds = kinds,
		water = water,
		deck = deck,
		nospawn = nospawn,
	}
end

-- The grid of a world, or nil when the world has no generated ground. Built once per world and kept.
function WorldGrid.For(worldId: number): Grid?
	local known = cache[worldId]
	if known then
		return known
	end
	local loader = loaders[worldId]
	if loader == nil then
		return nil
	end
	local grid = WorldGrid.Build(loader())
	cache[worldId] = grid
	return grid
end

-- The cell index under a flat point, clamped to the grid (a point past the edge reads the edge column).
function WorldGrid.Index(grid: Grid, x: number, z: number): number
	local i = math.clamp(math.floor((x - grid.origin) / grid.cell), 0, grid.count - 1)
	local j = math.clamp(math.floor((z - grid.origin) / grid.cell), 0, grid.count - 1)
	return j * grid.count + i + 1
end

-- Whether a flat point lies on the grid at all.
function WorldGrid.Inside(grid: Grid, x: number, z: number): boolean
	local span = grid.count * grid.cell
	return x >= grid.origin and z >= grid.origin and x < grid.origin + span and z < grid.origin + span
end

-- The top of the column under a point, in studs over the camp ground.
function WorldGrid.GroundAt(grid: Grid, x: number, z: number): number
	return grid.heights[WorldGrid.Index(grid, x, z)]
end

-- What a thing stands on at a point: the column, or the water over it, or a deck (a bridge, a lookout) over it, whichever is highest.
function WorldGrid.SurfaceAt(grid: Grid, x: number, z: number): number
	local c = WorldGrid.Index(grid, x, z)
	local top = grid.heights[c]
	local water = grid.water[c]
	if water and water > top then
		top = water
	end
	local deck = grid.deck[c]
	if deck and deck > top then
		top = deck
	end
	return top
end

-- The ground kind's name under a point.
function WorldGrid.KindAt(grid: Grid, x: number, z: number): string
	return grid.gen.Kinds[grid.kinds[WorldGrid.Index(grid, x, z)]] or ""
end

-- Whether a wild alien may land at a point: on the grid, no water, not under a bridge or a log, on a kind that allows it (`spawnKinds`
-- is data/WorldKit's spawn flag by kind name).
function WorldGrid.IsSpawnable(grid: Grid, x: number, z: number, spawnKinds: { [string]: boolean }): boolean
	if not WorldGrid.Inside(grid, x, z) then
		return false
	end
	local c = WorldGrid.Index(grid, x, z)
	if grid.water[c] ~= nil or grid.nospawn[c] then
		return false
	end
	return spawnKinds[grid.gen.Kinds[grid.kinds[c]] or ""] == true
end

-- The spot a flat point lies in (the first listed whose radius holds it), or nil.
function WorldGrid.SpotAt(grid: Grid, x: number, z: number): Types.WorldSpot?
	for _, spot in ipairs(grid.gen.Spots) do
		local dx, dz = x - spot.x, z - spot.z
		if dx * dx + dz * dz <= spot.radius * spot.radius then
			return spot
		end
	end
	return nil
end

-- Every spot within `range` studs of a flat point, nearest first.
function WorldGrid.SpotsNear(grid: Grid, x: number, z: number, range: number): { Types.WorldSpot }
	local out: { Types.WorldSpot } = {}
	for _, spot in ipairs(grid.gen.Spots) do
		local dx, dz = x - spot.x, z - spot.z
		if dx * dx + dz * dz <= range * range then
			table.insert(out, spot)
		end
	end
	table.sort(out, function(a: Types.WorldSpot, b: Types.WorldSpot): boolean
		return (a.x - x) ^ 2 + (a.z - z) ^ 2 < (b.x - x) ^ 2 + (b.z - z) ^ 2
	end)
	return out
end

local function bits(mask: number): number
	local n = 0
	for _, bit in ipairs({ 1, 2, 4, 8 }) do
		if bit32.band(mask, bit) ~= 0 then
			n += 1
		end
	end
	return n
end

-- The counts the budget (data/WorldKit Budget) holds, recomputed from the rows: ground parts (caps, bodies, water, falls, solids and
-- the one base slab), Texture objects once every tile is real (a cap's top and shown sides, a body's shown sides, each water part's top
-- and each fall's face, all six faces of a solid), scattered props, the parts of their placeholders and their lights.
function WorldGrid.Counts(gen: Types.WorldGen, recipes: { [string]: Types.PropRecipe }): { [string]: number }
	local caps, bodies = #gen.Caps // CAP, #gen.Bodies // BODY
	local textures = 0
	for r = 1, #gen.Caps, CAP do
		textures += 1 + bits(gen.Caps[r + 6])
	end
	for r = 1, #gen.Bodies, BODY do
		textures += bits(gen.Bodies[r + 6])
	end
	local water, falls, solids = #gen.Water // WATER, #gen.Falls // FALL, #gen.Solids // SOLID
	textures += water + falls + 6 * solids
	local scatter, parts, lights = 0, 0, 0
	for r = 1, #gen.Place, PLACE do
		scatter += 1
		local recipe = recipes[gen.Props[gen.Place[r]]]
		if recipe then
			parts += #recipe.boxes
			if recipe.light then
				lights += 1
			end
		end
	end
	return {
		groundParts = caps + bodies + water + falls + solids + 1,
		textures = textures,
		scatter = scatter,
		placeholderParts = parts,
		lights = lights,
		fxEmitters = #gen.Fx,
	}
end

return WorldGrid
