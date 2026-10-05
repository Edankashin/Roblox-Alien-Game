--!strict
-- ReplicatedStorage.Shared.Biomes: which biome a point of this place's world is in, from the regions
-- of the layout Shared/Place picks by the Workspace attribute WorldId (data/Layouts.luau: Meadow for
-- World 1, Frostbyte for World 2). The server uses it to pick spawn tables and place nodes; the client
-- uses it for the HUD biome chip. Everything outside a region is the layout's BaseBiome (Meadow on
-- World 1, Snowfield on World 2).

local Types = require(script.Parent.types.Types)
local Layouts = require(script.Parent.data.Layouts)
local Place = require(script.Parent.Place)

local Biomes = {}

local function flatDistance(x1: number, z1: number, x2: number, z2: number): number
	local dx, dz = x1 - x2, z1 - z2
	return math.sqrt(dx * dx + dz * dz)
end

-- A layout's region keys and its BaseBiome are biome names by contract (Types.Biome lists every
-- world's three), so the region key is the answer; the cast records that contract.
function Biomes.At(position: Vector3): Types.Biome
	local layout = Place.Layout()
	for name, region in pairs(layout.Regions) do
		if flatDistance(position.X, position.Z, region.x, region.z) <= region.radius then
			return name :: Types.Biome
		end
	end
	return layout.BaseBiome :: Types.Biome
end

-- The region record for a biome, or nil for the base biome (which is the whole floor).
function Biomes.Region(biome: string): Layouts.Region?
	return Place.Layout().Regions[biome]
end

-- A random flat point (y = 0) inside a biome: within the region circle minus the edge margin, or, for
-- the base biome, in the ring around the camp that keeps clear of every region.
function Biomes.RandomPointIn(biome: string, rng: Random, minFromCamp: number, maxFromCamp: number): Vector3
	local layout = Place.Layout()
	local region = layout.Regions[biome]
	if region then
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = (region.radius - layout.RegionEdgeMargin) * math.sqrt(rng:NextNumber())
		return Vector3.new(region.x + math.cos(angle) * radius, 0, region.z + math.sin(angle) * radius)
	end
	for _ = 1, 20 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(minFromCamp, maxFromCamp)
		local point = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if Biomes.At(point) == layout.BaseBiome then
			return point
		end
	end
	return Vector3.new(minFromCamp, 0, 0)
end

return Biomes
