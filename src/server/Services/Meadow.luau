--!strict
-- ServerScriptService.Server.Services.Meadow: builds the placeholder world this place runs under
-- Workspace.World, from the layout Shared/Place picks by the Workspace attribute WorldId
-- (data/Layouts.luau: Meadow for World 1, Frostbyte for World 2). A fresh baseplate gets ground, a camp
-- pad with a SpawnLocation, scattered rocks and trees, the layout's biome regions drawn as coloured
-- floor patches with their own scatter (a grove of trees, a roofed and walled cave, a field of geyser
-- cones: whichever fields the region carries) and the Shrine of the Warden (a stone ring with a
-- glowing pedestal under Workspace.World.Landmarks, where the Field Notes horn is sounded). Server-side
-- so every client sees the same world; parts only, no scripts attached. Skips entirely when
-- Workspace.World already exists (a hand-built or saved world wins). The service keeps its World 1
-- name: it is the one world builder, whichever world the place is.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local Layouts = require(Shared.data.Layouts)
local Place = require(Shared.Place)
local Biomes = require(Shared.Biomes)

local Meadow = {}

local Layout: Layouts.Layout = Place.Layout() -- this place's world; fixed for the server's lifetime

local WORLD_FOLDER = "World"
local WILD_FOLDER = "Wild"
local LANDMARKS_FOLDER = "Landmarks"
-- The floor part's name is historical (the World 1 placeholder was "the Meadow"); it is the same in
-- every world because clients wait for it by name (World.Waypoint reads the floor top from it).
local FLOOR_NAME = "MeadowFloor"
local SHRINE_NAME = "Shrine" -- the Model's name and its LandmarkId attribute
local ROCK_HEIGHT_FACTOR = 0.7 -- rocks are squatter than they are wide
local LEAVES_SINK_FACTOR = 0.6 -- the leaf ball sits this fraction of its radius above the trunk top
local CONE_TIERS = 3 -- a geyser cone is this many stacked cylinders, each narrower than the one below
-- Shrine proportions, all relative to Layout.Shrine (stoneHeight and radius) so one data change rescales it.
local STONE_WIDTH_FACTOR = 0.4 -- a standing stone is this fraction of its height wide
local STONE_DEPTH_FACTOR = 0.25 -- and this fraction deep
local PEDESTAL_RADIUS_FACTOR = 0.25 -- pedestal radius as a fraction of the shrine radius
local PEDESTAL_HEIGHT_FACTOR = 0.3 -- pedestal height as a fraction of the stone height
local GLOW_RADIUS_FACTOR = 0.15 -- the glow ball's radius as a fraction of the stone height

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
-- region, nothing on the open floor.
local function regionLift(position: Vector3): number
	for _, region in pairs(Layout.Regions) do
		local dx, dz = position.X - region.x, position.Z - region.z
		if math.sqrt(dx * dx + dz * dz) <= region.radius then
			return Layout.RegionPatchThickness
		end
	end
	return 0
end

local function flatDistance(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function shrineFlat(): Vector3
	return Vector3.new(Layout.Shrine.x, 0, Layout.Shrine.z)
end

local function pedestalHeight(): number
	return Layout.Shrine.stoneHeight * PEDESTAL_HEIGHT_FACTOR
end

-- Where the open-floor scatter may not land. Trees stay out of roofed regions and geyser fields (no
-- pines under a cave roof or among the cones); rocks stay out of groves (a region with its own trees).
local function treesAvoid(region: Layouts.Region): boolean
	return region.roofHeight ~= nil or (region.coneCount or 0) > 0
end

local function rocksAvoid(region: Layouts.Region): boolean
	return region.treeCount > 0
end

-- A random flat point on the open floor, clear of the camp, of the edge and of the shrine ring, and
-- never inside a region that `avoid` rejects.
local function scatterPoint(rng: Random, avoid: (Layouts.Region) -> boolean): Vector3
	local half = Layout.FloorSize / 2 - Layout.ScatterEdgeMargin
	local shrineClear = Layout.Shrine.radius + Config.ShrineScatterClearance
	local shrine = shrineFlat()
	while true do
		local x = rng:NextNumber(-half, half)
		local z = rng:NextNumber(-half, half)
		local point = Vector3.new(x, 0, z)
		if math.sqrt(x * x + z * z) >= Layout.ScatterMinFromCamp and flatDistance(point, shrine) >= shrineClear then
			local region = Biomes.Region(Biomes.At(point))
			if region == nil or not avoid(region) then
				return point
			end
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

-- A trunk resting on `groundY` with a leaf ball on top; the leaves are a child of the trunk. The layout's
-- trunk and leaf colours make it a meadow oak or a snow pine.
local function buildTree(name: string, at: Vector3, groundY: number, rng: Random, parent: Instance): Part
	local height = rng:NextNumber(Layout.TrunkHeightMin, Layout.TrunkHeightMax)
	local trunk = uprightCylinder(name, Layout.TrunkRadius, height, Vector3.new(at.X, groundY + height / 2, at.Z), Layout.TrunkColor, parent)
	local leavesRadius = rng:NextNumber(Layout.LeavesRadiusMin, Layout.LeavesRadiusMax)
	local leaves = basePart("Leaves", Enum.PartType.Ball, Vector3.one * (leavesRadius * 2), CFrame.new(at.X, groundY + height + leavesRadius * LEAVES_SINK_FACTOR, at.Z), Layout.LeavesColor, trunk)
	leaves.CanCollide = false
	return trunk
end

-- A geyser cone resting on `groundY`: CONE_TIERS upright cylinders stacked to `height`, each tier
-- narrower than the one below so the stack tapers. The upper tiers are children of the base.
local function buildCone(name: string, at: Vector3, groundY: number, radius: number, height: number, hex: string, parent: Instance): Part
	local tierHeight = height / CONE_TIERS
	local function tier(index: number, tierParent: Instance): Part
		local tierRadius = radius * (CONE_TIERS - index + 1) / CONE_TIERS
		local tierName = if index == 1 then name else "Tier" .. index
		return uprightCylinder(tierName, tierRadius, tierHeight, Vector3.new(at.X, groundY + tierHeight * (index - 0.5), at.Z), hex, tierParent)
	end
	local base = tier(1, parent)
	for index = 2, CONE_TIERS do
		tier(index, base)
	end
	return base
end

-- One biome region: a coloured floor patch, its own trees, rocks and geyser cones on the patch top
-- and, when the region has a roofHeight, a roof slab held up by pillars around the rim with open gaps
-- between them.
local function buildRegion(name: string, region: Layouts.Region, floorTop: number, rng: Random, parent: Instance)
	local patchTop = floorTop + Layout.RegionPatchThickness
	uprightCylinder(name .. "Floor", region.radius, Layout.RegionPatchThickness, Vector3.new(region.x, floorTop + Layout.RegionPatchThickness / 2, region.z), region.floorColor, parent)

	-- Biomes.RandomPointIn keeps region points RegionEdgeMargin inside the rim; the camp ring arguments
	-- only apply to the base biome and are never reached for a named region.
	local minFromCamp = Layout.ScatterMinFromCamp
	local maxFromCamp = Layout.FloorSize / 2 - Layout.ScatterEdgeMargin
	for i = 1, region.treeCount do
		local at = Biomes.RandomPointIn(name, rng, minFromCamp, maxFromCamp)
		buildTree(name .. "Tree" .. i, at, patchTop, rng, parent)
	end
	for i = 1, region.rockCount do
		local at = Biomes.RandomPointIn(name, rng, minFromCamp, maxFromCamp)
		buildRock(name .. "Rock" .. i, at, patchTop, rng, parent)
	end

	-- Geyser cones (the Geyser Field): the layout gives count, radius, height and colour; a region that
	-- names a count but not a shape borrows the tree trunk's radius and shortest height, and the floor's colour.
	local coneCount = region.coneCount or 0
	if coneCount > 0 then
		local coneRadius = region.coneRadius or Layout.TrunkRadius
		local coneHeight = region.coneHeight or Layout.TrunkHeightMin
		local coneColor = region.coneColor or region.floorColor
		for i = 1, coneCount do
			local at = Biomes.RandomPointIn(name, rng, minFromCamp, maxFromCamp)
			buildCone(name .. "Cone" .. i, at, patchTop, coneRadius, coneHeight, coneColor, parent)
		end
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

-- The Shrine of the Warden: a ring of upright stones facing a central pedestal with a Neon glow ball
-- on top. One Model named Shrine whose PrimaryPart (the pedestal) carries LandmarkId = "Shrine", so the
-- client finds it under Workspace.World.Landmarks without knowing the layout.
local function buildShrine(groundY: number, parent: Instance)
	local shrine = Layout.Shrine
	local model = Instance.new("Model")
	model.Name = SHRINE_NAME

	local height = pedestalHeight()
	local pedestal = uprightCylinder("Pedestal", shrine.radius * PEDESTAL_RADIUS_FACTOR, height, Vector3.new(shrine.x, groundY + height / 2, shrine.z), shrine.pedestalColor, model)
	pedestal:SetAttribute("LandmarkId", SHRINE_NAME)
	model.PrimaryPart = pedestal

	local glowRadius = shrine.stoneHeight * GLOW_RADIUS_FACTOR
	local glow = basePart("Glow", Enum.PartType.Ball, Vector3.one * (glowRadius * 2), CFrame.new(shrine.x, groundY + height + glowRadius, shrine.z), shrine.glowColor, model)
	glow.Material = Enum.Material.Neon
	glow.CanCollide = false

	local stoneSize = Vector3.new(shrine.stoneHeight * STONE_WIDTH_FACTOR, shrine.stoneHeight, shrine.stoneHeight * STONE_DEPTH_FACTOR)
	for i = 1, shrine.stoneCount do
		local angle = (i - 1) / shrine.stoneCount * math.pi * 2
		local at = Vector3.new(shrine.x + math.cos(angle) * shrine.radius, groundY + shrine.stoneHeight / 2, shrine.z + math.sin(angle) * shrine.radius)
		-- yaw the block so its depth axis points at the centre: the broad face looks inward
		local cframe = CFrame.new(at) * CFrame.Angles(0, math.pi / 2 - angle, 0)
		basePart("Stone" .. i, Enum.PartType.Block, stoneSize, cframe, shrine.stoneColor, model)
	end

	model.Parent = parent
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

	local landmarks = Instance.new("Folder")
	landmarks.Name = LANDMARKS_FOLDER
	landmarks.Parent = world

	-- Floor: the part sits at Y = 0 so its top surface is at FloorThickness / 2.
	local floorTop = Layout.FloorThickness / 2
	basePart(FLOOR_NAME, Enum.PartType.Block, Vector3.new(Layout.FloorSize, Layout.FloorThickness, Layout.FloorSize), CFrame.new(0, 0, 0), Layout.FloorColor, world)

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
	-- feeds the regions and then the open floor; regions go in name order because pairs() order is
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

	-- Open-floor scatter. A landmark that lands on a region patch rests on the patch, not the floor.
	for i = 1, Layout.RockCount do
		local at = scatterPoint(rng, rocksAvoid)
		buildRock("Rock" .. i, at, floorTop + regionLift(at), rng, world)
	end
	for i = 1, Layout.TreeCount do
		local at = scatterPoint(rng, treesAvoid)
		buildTree("Tree" .. i, at, floorTop + regionLift(at), rng, world)
	end

	-- The world's landmark. Scatter already kept clear of its ring (scatterPoint).
	local shrineAt = shrineFlat()
	buildShrine(floorTop + regionLift(shrineAt), landmarks)

	world.Parent = Workspace
end

-- Public API -------------------------------------------------------------

-- Height of the floor's top face; the camp pad and anything at the origin sit on this.
function Meadow.GetFloorTop(): number
	local world = Workspace:FindFirstChild(WORLD_FOLDER)
	local floor = if world then world:FindFirstChild(FLOOR_NAME) else nil
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

-- The top of the shrine's pedestal: where the horn is sounded (Quests measures ShrineInteractDistance
-- from here) and where the Warden is summoned next to. Derived from the layout, so it is right even
-- when a hand-built world skipped the build.
function Meadow.GetShrinePosition(): Vector3
	local flat = shrineFlat()
	return Vector3.new(flat.X, Meadow.GetSurfaceTop(flat) + pedestalHeight(), flat.Z)
end

return Meadow
