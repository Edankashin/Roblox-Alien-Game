--!strict
-- The generated worlds (data/WorldGen1, WorldGen2 from tools/blocky/world_gen.py) read through Shared/WorldGrid: the rows are whole,
-- the counts match what the generator recorded and stay under data/WorldKit's Budget, every kind, tile and prop the rows name exists,
-- the camp ground is the old floor top (clients read it from MeadowFloor), the shrine stands on flat dry ground, every biome region of
-- the layout has spawnable ground at its heart, water never takes a spawn, and every rare spot is a dry place the spawner can use.
local Shared = game:GetService("ReplicatedStorage").Shared
local WorldGrid = require(Shared.WorldGrid)
local WorldKit = require(Shared.data.WorldKit)
local BlockTiles = require(Shared.data.BlockTiles)
local Layouts = require(Shared.data.Layouts)
local Spawns = require(Shared.data.Spawns)

local spawnKinds: { [string]: boolean } = {}
for name, kind in pairs(WorldKit.Kinds) do
	spawnKinds[name] = kind.spawn
end

for _, worldId in ipairs({ 1, 2 }) do
	local grid = WorldGrid.For(worldId)
	assert(grid, "no grid for world " .. worldId)
	local gen = grid.gen
	local layout = Layouts[worldId]

	describe("WorldGrid world " .. worldId, function()
		it("has whole rows", function()
			for name, stride in pairs(WorldGrid.Stride) do
				local rows = (gen :: any)[name] :: { number }
				expect(#rows % stride).toEqual(0)
			end
		end)

		it("counts what the generator recorded, under the budget", function()
			local counts = WorldGrid.Counts(gen, WorldKit.Recipes)
			for key, value in pairs(counts) do
				expect(value).toEqual(gen.Stats[key])
				expect(value <= (WorldKit.Budget :: any)[key]).toEqual(true)
			end
		end)

		it("names only known kinds, tiles and props", function()
			for _, name in ipairs(gen.Kinds) do
				local kind = WorldKit.Kinds[name]
				expect(kind ~= nil).toEqual(true)
				for _, key in ipairs({ kind.top, kind.side, kind.body }) do
					expect(BlockTiles.Ids[key] ~= nil).toEqual(true)
				end
			end
			for _, name in ipairs(gen.Props) do
				expect(WorldKit.Recipes[name] ~= nil).toEqual(true)
			end
		end)

		it("keeps every rectangle on the grid", function()
			for _, name in ipairs({ "Caps", "Bodies", "Water" }) do
				local rows = (gen :: any)[name] :: { number }
				for r = 1, #rows, 7 do
					expect(rows[r] >= 0 and rows[r + 1] >= 0).toEqual(true)
					expect(rows[r] + rows[r + 2] <= gen.Count and rows[r + 1] + rows[r + 3] <= gen.Count).toEqual(true)
					-- a rectangle never crosses a streaming chunk
					expect(rows[r] // gen.Chunk).toEqual((rows[r] + rows[r + 2] - 1) // gen.Chunk)
					expect(rows[r + 1] // gen.Chunk).toEqual((rows[r + 1] + rows[r + 3] - 1) // gen.Chunk)
				end
			end
		end)

		it("stands the camp on the old floor top", function()
			for _, at in ipairs({ { 0, 0 }, { 10, 0 }, { 0, -12 }, { -8, 8 } }) do
				expect(WorldGrid.SurfaceAt(grid, at[1], at[2])).toEqual(0)
			end
		end)

		it("stands the shrine on flat dry ground", function()
			local shrine = layout.Shrine
			local ground = WorldGrid.SurfaceAt(grid, shrine.x, shrine.z)
			for angle = 0, 330, 30 do
				local x = shrine.x + math.cos(math.rad(angle)) * shrine.radius
				local z = shrine.z + math.sin(math.rad(angle)) * shrine.radius
				expect(WorldGrid.SurfaceAt(grid, x, z)).toEqual(ground)
				expect(grid.water[WorldGrid.Index(grid, x, z)] == nil).toEqual(true)
			end
		end)

		it("has spawnable ground at the heart of every biome region", function()
			for name, region in pairs(layout.Regions) do
				local found = false
				for dx = -10, 10, 2 do
					if WorldGrid.IsSpawnable(grid, region.x + dx, region.z + dx, spawnKinds) then
						found = true
					end
				end
				expect(found).toEqual(true)
				expect(table.find(Spawns.LiveBiomes[worldId], name) ~= nil).toEqual(true)
			end
		end)

		it("never spawns in water", function()
			for c, _ in pairs(grid.water) do
				local i = (c - 1) % gen.Count
				local j = (c - 1) // gen.Count
				local x = gen.Origin + (i + 0.5) * gen.Cell
				local z = gen.Origin + (j + 0.5) * gen.Cell
				expect(WorldGrid.IsSpawnable(grid, x, z, spawnKinds)).toEqual(false)
			end
		end)

		it("gives every rare spot dry, spawnable ground and its surface height", function()
			expect(#gen.Spots >= 4).toEqual(true)
			for _, spot in ipairs(gen.Spots) do
				expect(spot.luck >= 1).toEqual(true)
				expect(WorldGrid.IsSpawnable(grid, spot.x, spot.z, spawnKinds)).toEqual(true)
				expect(WorldGrid.SpotAt(grid, spot.x, spot.z) ~= nil).toEqual(true)
				local surface = WorldGrid.SurfaceAt(grid, spot.x, spot.z)
				expect(surface >= spot.y).toEqual(true)
			end
		end)

		it("reads a deck over the ground where a bridge or a lookout stands", function()
			local decks = 0
			for c, top in pairs(grid.deck) do
				local i = (c - 1) % gen.Count
				local j = (c - 1) // gen.Count
				local x = gen.Origin + (i + 0.5) * gen.Cell
				local z = gen.Origin + (j + 0.5) * gen.Cell
				expect(WorldGrid.SurfaceAt(grid, x, z) >= top).toEqual(true)
				decks += 1
			end
			expect(decks > 0).toEqual(true)
		end)

		it("lets every fall drop", function()
			for r = 1, #gen.Falls, WorldGrid.Stride.Falls do
				expect(gen.Falls[r + 3] < gen.Falls[r + 4]).toEqual(true)
			end
		end)
	end)
end

describe("WorldGrid without a generated world", function()
	it("has no grid for the home planet or an unbuilt world", function()
		expect(WorldGrid.For(0) == nil).toEqual(true)
		expect(WorldGrid.For(3) == nil).toEqual(true)
	end)
end)

return {}
