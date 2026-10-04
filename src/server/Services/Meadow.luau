--!strict
-- ServerScriptService.Server.Services.Meadow: builds the placeholder Meadow under Workspace.World
-- so a fresh baseplate has ground, a camp pad with a SpawnLocation, and a few landmarks to walk
-- between. Server-side so every client sees the same world; parts only, no scripts attached.
-- Skips entirely when Workspace.World already exists (a hand-built or saved world wins).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared.data.Meadow)

local Meadow = {}

local WORLD_FOLDER = "World"
local WILD_FOLDER = "Wild"

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

local function scatterPoint(rng: Random): Vector3
	local half = Layout.FloorSize / 2 - Layout.ScatterEdgeMargin
	while true do
		local x = rng:NextNumber(-half, half)
		local z = rng:NextNumber(-half, half)
		if math.sqrt(x * x + z * z) >= Layout.ScatterMinFromCamp then
			return Vector3.new(x, 0, z)
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

	-- Deterministic scatter so every server (and every reconnect) sees the same landmarks.
	local rng = Random.new(Layout.Seed)
	for i = 1, Layout.RockCount do
		local at = scatterPoint(rng)
		local size = Vector3.new(
			rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax),
			rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax) * 0.7,
			rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax)
		)
		local cframe = CFrame.new(at.X, floorTop + size.Y / 2, at.Z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		basePart("Rock" .. i, Enum.PartType.Block, size, cframe, Layout.RockColor, world)
	end
	for i = 1, Layout.TreeCount do
		local at = scatterPoint(rng)
		local height = rng:NextNumber(Layout.TrunkHeightMin, Layout.TrunkHeightMax)
		local trunk = uprightCylinder("Tree" .. i, Layout.TrunkRadius, height, Vector3.new(at.X, floorTop + height / 2, at.Z), Layout.TrunkColor, world)
		local leavesRadius = rng:NextNumber(Layout.LeavesRadiusMin, Layout.LeavesRadiusMax)
		local leaves = basePart("Leaves", Enum.PartType.Ball, Vector3.one * (leavesRadius * 2), CFrame.new(at.X, floorTop + height + leavesRadius * 0.6, at.Z), Layout.LeavesColor, trunk)
		leaves.CanCollide = false
	end

	world.Parent = Workspace
end

-- Height of the walkable surface; the Spawner places aliens relative to it.
function Meadow.GetFloorTop(): number
	local world = Workspace:FindFirstChild(WORLD_FOLDER)
	local floor = if world then world:FindFirstChild("MeadowFloor") else nil
	if floor and floor:IsA("BasePart") then
		return floor.Position.Y + floor.Size.Y / 2
	end
	return 0
end

function Meadow.GetHalfSize(): number
	return Layout.FloorSize / 2
end

function Meadow.GetCampRadius(): number
	return Layout.CampPadRadius
end

return Meadow
