--!strict
-- ReplicatedStorage.Shared.Biomes: which biome a point of World 1 is in, from the regions in
-- data/Meadow.luau. The server uses it to pick spawn tables and place nodes; the client uses it for
-- the HUD biome chip. Everything outside a region is Meadow.

local Types = require(script.Parent.types.Types)
local Layout = require(script.Parent.data.Meadow)

local Biomes = {}

local function flatDistance(x1: number, z1: number, x2: number, z2: number): number
	local dx, dz = x1 - x2, z1 - z2
	return math.sqrt(dx * dx + dz * dz)
end

function Biomes.At(position: Vector3): Types.Biome
	for name, region in pairs(Layout.Regions) do
		if flatDistance(position.X, position.Z, region.x, region.z) <= region.radius then
			if name == "Forest" or name == "Cave" then
				return name
			end
		end
	end
	return "Meadow"
end

-- The region record for a biome, or nil for the Meadow (which is the whole floor).
function Biomes.Region(biome: string): Layout.Region?
	return Layout.Regions[biome]
end

-- A random flat point (y = 0) inside a biome: within the region circle minus the edge margin, or, for
-- the Meadow, in the ring around the camp that keeps clear of both regions.
function Biomes.RandomPointIn(biome: string, rng: Random, minFromCamp: number, maxFromCamp: number): Vector3
	local region = Layout.Regions[biome]
	if region then
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = (region.radius - Layout.RegionEdgeMargin) * math.sqrt(rng:NextNumber())
		return Vector3.new(region.x + math.cos(angle) * radius, 0, region.z + math.sin(angle) * radius)
	end
	for _ = 1, 20 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(minFromCamp, maxFromCamp)
		local point = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if Biomes.At(point) == "Meadow" then
			return point
		end
	end
	return Vector3.new(minFromCamp, 0, 0)
end

return Biomes
