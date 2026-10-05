--!strict
-- ServerScriptService.Server.Services.Meadow: builds the placeholder World 1 under Workspace.World
-- so a fresh baseplate has ground, a camp pad with a SpawnLocation, a few landmarks to walk between,
-- and the two biome regions from data/Meadow.luau (a Forest grove and a roofed Cave) drawn as coloured
-- floor patches with their own scatter. Server-side so every client sees the same world; parts only,
-- no scripts attached. Skips entirely when Workspace.World already exists (a hand-built or saved
-- world wins).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.data.Meadow)
local Biomes = require(Shared.Biomes)

local Meadow = {}

local WORLD_FOLDER = "World"
local WILD_FOLDER = "Wild"
local ROCK_HEIGHT_FACTOR = 0.7 -- rocks are squatter than they are wide
local LEAVES_SINK_FACTOR = 0.6 -- the leaf ball sits this fraction of its radius above the trunk top

local function basePart(name: string, shape: Enum.PartType, size: Vector3, cframe: CFrame, hex: string, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = Color3.fromHex(hex)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Cylinders point along X; this stands one upright with the given height and radius.
local function uprightCylinder(name: string, radius: number, height: number, position: Vector3, hex: string, parent: Instance): Part
	local cframe = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	return basePart(name, Enum.PartType.Cylinder, Vector3.new(height, radius * 2, radius * 2), cframe, hex, parent)
end

-- How far the walkable surface sits above the floor top at a flat point: the patch thickness inside a
-- region, nothing on the open meadow.
local function regionLift(position: Vector3): number
	for _, region in pairs(Layout.Regions) do
		local dx, dz = position.X - region.x, position.Z - region.z
		if math.sqrt(dx * dx + dz * dz) <= region.radius then
			return Layout.RegionPatchThickness
		end
	end
	return 0
end

-- A random flat point on the open floor, clear of the camp and of the edge, and never inside `avoid`
-- (so no trees under the Cave roof and no rocks in the Forest grove).
local function scatterPoint(rng: Random, avoid: string): Vector3
	local half = Layout.FloorSize / 2 - Layout.ScatterEdgeMargin
	while true do
		local x = rng:NextNumber(-half, half)
		local z = rng:NextNumber(-half, half)
		local point = Vector3.new(x, 0, z)
		if math.sqrt(x * x + z * z) >= Layout.ScatterMinFromCamp and Biomes.At(point) ~= avoid then
			return point
		end
	end
end

-- A rock resting on `groundY` at a flat point; size and turn come from the shared rng.
local function buildRock(name: string, at: Vector3, groundY: number, rng: Random, parent: Instance): Part
	local size = Vector3.new(
		rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax),
		rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax) * ROCK_HEIGHT_FACTOR,
		rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax)
	)
	local cframe = CFrame.new(at.X, groundY + size.Y / 2, at.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	return basePart(name, Enum.PartType.Block, size, cframe, Layout.RockColor, parent)
end

-- A trunk resting on `groundY` with a leaf ball on top; the leaves are a child of the trunk.
local function buildTree(name: string, at: Vector3, groundY: number, rng: Random, parent: Instance): Part
	local height = rng:NextNumber(Layout.TrunkHeightMin, Layout.TrunkHeightMax)
	local trunk = uprightCylinder(name, Layout.TrunkRadius, height, Vector3.new(at.X, groundY + height / 2, at.Z), Layout.TrunkColor, parent)
	local leavesRadius = rng:NextNumber(Layout.LeavesRadiusMin, Layout.LeavesRadiusMax)
	local leaves = basePart("Leaves", Enum.PartType.Ball, Vector3.one * (leavesRadius * 2), CFrame.new(at.X, groundY + height + leavesRadius * LEAVES_SINK_FACTOR, at.Z), Layout.LeavesColor, trunk)
	leaves.CanCollide = false
	return trunk
end

-- One biome region: a coloured floor patch, its own trees and rocks on the patch top and, when the
-- region has a roofHeight, a roof slab held up by pillars around the rim with open gaps between them.
local function buildRegion(name: string, region: Layout.Region, floorTop: number, rng: Random, parent: Instance)
	local patchTop = floorTop + Layout.RegionPatchThickness
	uprightCylinder(name .. "Floor", region.radius, Layout.RegionPatchThickness, Vector3.new(region.x, floorTop + Layout.RegionPatchThickness / 2, region.z), region.floorColor, parent)

	-- Biomes.RandomPointIn keeps region points RegionEdgeMargin inside the rim; the camp ring arguments
	-- only apply to the Meadow and are never reached for a named region.
	for i = 1, region.treeCount do
		local at = Biomes.RandomPointIn(name, rng, Layout.ScatterMinFromCamp, Layout.FloorSize / 2 - Layout.ScatterEdgeMargin)
		buildTree(name .. "Tree" .. i, at, patchTop, rng, parent)
	end
	for i = 1, region.rockCount do
		local at = Biomes.RandomPointIn(name, rng, Layout.ScatterMinFromCamp, Layout.FloorSize / 2 - Layout.ScatterEdgeMargin)
		buildRock(name .. "Rock" .. i, at, patchTop, rng, parent)
	end

	local roofHeight = region.roofHeight
	if roofHeight then
		local roofColor = region.roofColor or region.floorColor
		local roof = basePart(name .. "Roof", Enum.PartType.Block, Vector3.new(region.radius * 2, Layout.RegionRoofThickness, region.radius * 2), CFrame.new(region.x, floorTop + roofHeight, region.z), roofColor, parent)
		roof.CanCollide = true

		local wallCount = region.wallCount or 0
		local wallColor = region.wallColor or roofColor
		local rimRadius = region.radius - Layout.RegionWallRadius
		for i = 1, wallCount do
			local angle = (i - 1) / wallCount * math.pi * 2
			local at = Vector3.new(region.x + math.cos(angle) * rimRadius, patchTop + roofHeight / 2, region.z + math.sin(angle) * rimRadius)
			uprightCylinder(name .. "Wall" .. i, Layout.RegionWallRadius, roofHeight, at, wallColor, parent)
		end
	end
end

function Meadow.Init()
	if Workspace:FindFirstChild(WORLD_FOLDER) then
		return
	end
	local world = Instance.new("Folder")
	world.Name = WORLD_FOLDER

	local wild = Instance.new("Folder")
	wild.Name = WILD_FOLDER
	wild.Parent = world

	-- Floor: the part sits at Y = 0 so its top surface is at FloorThickness / 2.
	local floorTop = Layout.FloorThickness / 2
	basePart("MeadowFloor", Enum.PartType.Block, Vector3.new(Layout.FloorSize, Layout.FloorThickness, Layout.FloorSize), CFrame.new(0, 0, 0), Layout.FloorColor, world)

	-- Camp pad at the origin with the SpawnLocation on top.
	local padY = floorTop + Layout.CampPadThickness / 2
	uprightCylinder("CampPad", Layout.CampPadRadius, Layout.CampPadThickness, Vector3.new(0, padY, 0), Layout.CampPadColor, world)

	-- A thin visible square flush on the pad so the spawn point reads as part of the camp.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CampSpawn"
	spawn.Size = Vector3.new(Layout.SpawnPadSize, Layout.SpawnPadThickness, Layout.SpawnPadSize)
	spawn.CFrame = CFrame.new(0, floorTop + Layout.CampPadThickness + Layout.SpawnPadThickness / 2, 0)
	spawn.Color = Color3.fromHex(Layout.SpawnPadColor)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	-- Deterministic scatter so every server (and every reconnect) sees the same landmarks. One rng
	-- feeds the regions and then the open meadow; regions go in name order because pairs() order is
	-- not stable between servers.
	local rng = Random.new(Layout.Seed)
	local regionNames: { string } = {}
	for name in pairs(Layout.Regions) do
		table.insert(regionNames, name)
	end
	table.sort(regionNames)
	for _, name in ipairs(regionNames) do
		buildRegion(name, Layout.Regions[name], floorTop, rng, world)
	end

	-- Open-meadow scatter. A landmark that lands on a region patch rests on the patch, not the floor.
	for i = 1, Layout.RockCount do
		local at = scatterPoint(rng, "Forest")
		buildRock("Rock" .. i, at, floorTop + regionLift(at), rng, world)
	end
	for i = 1, Layout.TreeCount do
		local at = scatterPoint(rng, "Cave")
		buildTree("Tree" .. i, at, floorTop + regionLift(at), rng, world)
	end

	world.Parent = Workspace
end

-- Public API -------------------------------------------------------------

-- Height of the floor's top face; the camp pad and anything at the origin sit on this.
function Meadow.GetFloorTop(): number
	local world = Workspace:FindFirstChild(WORLD_FOLDER)
	local floor = if world then world:FindFirstChild("MeadowFloor") else nil
	if floor and floor:IsA("BasePart") then
		return floor.Position.Y + floor.Size.Y / 2
	end
	return 0
end

-- Height of the walkable surface at a flat point: the region patch top inside any region, else the
-- floor top. The Spawner and Materials seat aliens and nodes relative to it.
function Meadow.GetSurfaceTop(position: Vector3): number
	return Meadow.GetFloorTop() + regionLift(position)
end

function Meadow.GetHalfSize(): number
	return Layout.FloorSize / 2
end

function Meadow.GetCampRadius(): number
	return Layout.CampPadRadius
end

return Meadow
