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
--
-- Landmarks: the layout's Landmarks list stands each hero set piece (the crash wreck, a cave mouth, the
-- great vent) from Shared/Props at its fixed point under Workspace.World.Landmarks, builds nothing when
-- its prop is missing, and makes the open-floor and region scatter keep clear of its clearRadius. When
-- Layout.Props names a hero shrine model it replaces the stone ring, the pedestal mesh and the glow ball
-- (the invisible pedestal anchor still carries LandmarkId); a world without one keeps the part-built shrine.
--
-- Imported meshes: every landmark first tries the layout's prop (Shared/Props, named by Layout.Props) and
-- keeps its part-built placeholder as the fallback. Pure scenery (trees, rocks, cones) is replaced
-- outright by the mesh; the shrine's pedestal stays as an invisible anchor (it is the PrimaryPart and
-- carries LandmarkId) with the mesh as its child. A scattered landmark draws the same random numbers
-- whether or not its mesh exists, so the seeded world is laid out identically with and without imports.
--
-- The home planet (Place.IsHome, world 0; data/Home) builds neither the shrine nor the landmarks. When the layout
-- sets PlotCells it draws the plot for the house grid right after the camp pad: one flat block named "Plot" of
-- PlotCells x PlotCellStuds studs a side, PlotOffsetStuds past the pad on +Z, resting on the floor; GetPlotCenter
-- says where it is for the house grid. After the plot the home also stands three trophy-hangar pads in a row on -Z
-- of the camp (HangarPad1..3, flat cylinders the client draws the launched worlds' hulls on), a placeholder Kiosk
-- block for the spin wheel and a placeholder Mailbox block, each only when the layout sets its fields; the
-- placeholders' sizes and colours are layout data (data/Home).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local Layouts = require(Shared.data.Layouts)
local Place = require(Shared.Place)
local Biomes = require(Shared.Biomes)
local Props = require(Shared.Props)

local Meadow = {}

local Layout: Layouts.Layout = Place.Layout() -- this place's world; fixed for the server's lifetime
local propNames: Layouts.PropNames? = Layout.Props -- nil: this world imports nothing, every landmark is a placeholder
local NO_NAMES: { string } = {}
local landmarkList: { Layouts.Landmark } = Layout.Landmarks or {} -- hero set pieces; empty when the layout lists none

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
local HANGAR_PAD_COUNT = 3 -- the trophy hangar's row: HangarPad1..3, centred on the layout's HangarCenterZ
local REGION_POINT_TRIES = 20 -- a region draw that lands inside a landmark's clearance is redrawn this many times at most
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

-- The plot's numbers from the layout, or nil when the layout has no plot (PlotCells unset). Its centre sits on
-- +Z at the pad's radius plus the offset plus half the side.
type PlotShape = { side: number, centerZ: number, thickness: number, color: string }
local function plotShape(): PlotShape?
	local cells = Layout.PlotCells
	if cells == nil then
		return nil
	end
	local cellStuds, offset, thickness, color = Layout.PlotCellStuds, Layout.PlotOffsetStuds, Layout.PlotThickness, Layout.PlotColor
	if cellStuds == nil or offset == nil or thickness == nil or color == nil then
		warn(("[%s] Meadow: layout %d sets PlotCells but not every Plot field; no plot drawn"):format(Config.WorkingTitle, Layout.WorldId))
		return nil
	end
	local side = cells * cellStuds
	return { side = side, centerZ = Layout.CampPadRadius + offset + side / 2, thickness = thickness, color = color }
end

-- A placeholder block for the home's kiosk or mailbox: resting on the floor at the spot, turned by its yaw.
local function standBlock(name: string, spot: Layouts.Spot, size: Layouts.Size3, hex: string, floorTop: number, parent: Instance)
	local cframe = CFrame.new(spot.x, floorTop + size.y / 2, spot.z) * CFrame.Angles(0, math.rad(spot.yaw), 0)
	basePart(name, Enum.PartType.Block, Vector3.new(size.x, size.y, size.z), cframe, hex, parent)
end

-- The home planet's trophy-hangar pads, kiosk and mailbox (42d), each built only when the layout sets its fields:
-- HANGAR_PAD_COUNT upright cylinders HangarSpacingStuds apart in a row at z = HangarCenterZ (as thick as the plot),
-- then the two placeholder blocks. A layout that sets part of a group warns and skips that group.
local function buildHomeStands(floorTop: number, parent: Instance)
	local centerZ = Layout.HangarCenterZ
	if centerZ ~= nil then
		local spacing, radius, color, thickness = Layout.HangarSpacingStuds, Layout.HangarPadRadius, Layout.HangarPadColor, Layout.PlotThickness
		if spacing == nil or radius == nil or color == nil or thickness == nil then
			warn(("[%s] Meadow: layout %d sets HangarCenterZ but not every Hangar field (or the plot's thickness); no hangar pads drawn"):format(Config.WorkingTitle, Layout.WorldId))
		else
			local middle = (HANGAR_PAD_COUNT + 1) / 2
			for i = 1, HANGAR_PAD_COUNT do
				uprightCylinder("HangarPad" .. i, radius, thickness, Vector3.new((i - middle) * spacing, floorTop + thickness / 2, centerZ), color, parent)
			end
		end
	end
	local kiosk, kioskSize, kioskColor = Layout.Kiosk, Layout.KioskSize, Layout.KioskColor
	if kiosk and kioskSize and kioskColor then
		standBlock("Kiosk", kiosk, kioskSize, kioskColor, floorTop, parent)
	elseif kiosk or kioskSize or kioskColor then
		warn(("[%s] Meadow: layout %d sets part of the Kiosk but not all of it; no kiosk drawn"):format(Config.WorkingTitle, Layout.WorldId))
	end
	local mailbox, mailboxSize, mailboxColor = Layout.Mailbox, Layout.MailboxSize, Layout.MailboxColor
	if mailbox and mailboxSize and mailboxColor then
		standBlock("Mailbox", mailbox, mailboxSize, mailboxColor, floorTop, parent)
	elseif mailbox or mailboxSize or mailboxColor then
		warn(("[%s] Meadow: layout %d sets part of the Mailbox but not all of it; no mailbox drawn"):format(Config.WorkingTitle, Layout.WorldId))
	end
end

local function shrineFlat(): Vector3
	return Vector3.new(Layout.Shrine.x, 0, Layout.Shrine.z)
end

-- True when a flat point is at least every landmark's clearRadius away from that landmark's point. The
-- check reads the layout, not the imported meshes, so the scatter is the same with and without imports.
local function clearOfLandmarks(point: Vector3): boolean
	for _, landmark in ipairs(landmarkList) do
		if flatDistance(point, Vector3.new(landmark.x, 0, landmark.z)) < landmark.clearRadius then
			return false
		end
	end
	return true
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

-- A random flat point on the open floor, clear of the camp, of the edge, of the shrine ring and of every
-- landmark, and never inside a region that `avoid` rejects.
local function scatterPoint(rng: Random, avoid: (Layouts.Region) -> boolean): Vector3
	local half = Layout.FloorSize / 2 - Layout.ScatterEdgeMargin
	local shrineClear = Layout.Shrine.radius + Config.ShrineScatterClearance
	local shrine = shrineFlat()
	while true do
		local x = rng:NextNumber(-half, half)
		local z = rng:NextNumber(-half, half)
		local point = Vector3.new(x, 0, z)
		if math.sqrt(x * x + z * z) >= Layout.ScatterMinFromCamp and flatDistance(point, shrine) >= shrineClear and clearOfLandmarks(point) then
			local region = Biomes.Region(Biomes.At(point))
			if region == nil or not avoid(region) then
				return point
			end
		end
	end
end

-- The three draws every scattered landmark makes, always, in this order: which of its kinds to use, its
-- turn, and its scale jitter. They are taken whether or not an imported mesh exists, so the shared rng
-- (and with it every later position) is the same with and without imports.
local function drawProp(rng: Random, kinds: { string }): (number, number, number)
	local pick = rng:NextInteger(1, math.max(1, #kinds))
	local yaw = rng:NextNumber(0, math.pi * 2)
	local jitter = rng:NextNumber(-Config.PropScaleJitter, Config.PropScaleJitter)
	return pick, yaw, jitter
end

-- Stands the picked mesh on the ground at a flat point, named as its placeholder would have been; nil when
-- the layout lists no kind or the mesh was never imported (the caller builds the placeholder).
local function placeScenery(kinds: { string }, pick: number, name: string, at: Vector3, groundY: number, yaw: number, jitter: number, parent: Instance): Model?
	if #kinds == 0 then
		return nil
	end
	local model = Props.Place(kinds[pick], CFrame.new(at.X, groundY, at.Z) * CFrame.Angles(0, yaw, 0), 1 + jitter, parent, true)
	if model then
		model.Name = name
	end
	return model
end

-- A rock resting on `groundY` at a flat point; size and turn come from the shared rng. The imported mesh
-- is authored at the layout's rock size, so it is only jittered, not sized.
local function buildRock(name: string, at: Vector3, groundY: number, rng: Random, parent: Instance): Instance
	local size = Vector3.new(
		rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax),
		rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax) * ROCK_HEIGHT_FACTOR,
		rng:NextNumber(Layout.RockSizeMin, Layout.RockSizeMax)
	)
	local kinds = if propNames then propNames.rock else NO_NAMES
	local pick, yaw, jitter = drawProp(rng, kinds)
	local model = placeScenery(kinds, pick, name, at, groundY, yaw, jitter, parent)
	if model then
		return model
	end
	local cframe = CFrame.new(at.X, groundY + size.Y / 2, at.Z) * CFrame.Angles(0, yaw, 0)
	return basePart(name, Enum.PartType.Block, size, cframe, Layout.RockColor, parent)
end

-- A trunk resting on `groundY` with a leaf ball on top; the leaves are a child of the trunk. The layout's
-- trunk and leaf colours make it a meadow oak or a snow pine. An imported tree replaces both outright.
local function buildTree(name: string, at: Vector3, groundY: number, rng: Random, parent: Instance): Instance
	local height = rng:NextNumber(Layout.TrunkHeightMin, Layout.TrunkHeightMax)
	local leavesRadius = rng:NextNumber(Layout.LeavesRadiusMin, Layout.LeavesRadiusMax)
	local kinds = if propNames then propNames.tree else NO_NAMES
	local pick, yaw, jitter = drawProp(rng, kinds)
	local model = placeScenery(kinds, pick, name, at, groundY, yaw, jitter, parent)
	if model then
		return model
	end
	local trunk = uprightCylinder(name, Layout.TrunkRadius, height, Vector3.new(at.X, groundY + height / 2, at.Z), Layout.TrunkColor, parent)
	local leaves = basePart("Leaves", Enum.PartType.Ball, Vector3.one * (leavesRadius * 2), CFrame.new(at.X, groundY + height + leavesRadius * LEAVES_SINK_FACTOR, at.Z), Layout.LeavesColor, trunk)
	leaves.CanCollide = false
	return trunk
end

-- A geyser cone resting on `groundY`: CONE_TIERS upright cylinders stacked to `height`, each tier
-- narrower than the one below so the stack tapers. The upper tiers are children of the base. An imported
-- cone replaces the stack (its mesh is authored at the layout's cone size; radius and height are only the
-- placeholder's).
local function buildCone(name: string, at: Vector3, groundY: number, radius: number, height: number, hex: string, rng: Random, parent: Instance): Instance
	local kinds = if propNames then propNames.cone else NO_NAMES
	local pick, yaw, jitter = drawProp(rng, kinds)
	local model = placeScenery(kinds, pick, name, at, groundY, yaw, jitter, parent)
	if model then
		return model
	end
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

-- A random point inside a region, redrawn while it falls inside a landmark's clearance (at most
-- REGION_POINT_TRIES draws in all; the last one is kept). A point that is already clear costs one draw, so
-- a region with no landmark near it scatters exactly as it would without any.
local function regionPoint(name: string, rng: Random, minFromCamp: number, maxFromCamp: number): Vector3
	local point = Biomes.RandomPointIn(name, rng, minFromCamp, maxFromCamp)
	local tries = 1
	while not clearOfLandmarks(point) and tries < REGION_POINT_TRIES do
		point = Biomes.RandomPointIn(name, rng, minFromCamp, maxFromCamp)
		tries += 1
	end
	return point
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
		local at = regionPoint(name, rng, minFromCamp, maxFromCamp)
		buildTree(name .. "Tree" .. i, at, patchTop, rng, parent)
	end
	for i = 1, region.rockCount do
		local at = regionPoint(name, rng, minFromCamp, maxFromCamp)
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
			local at = regionPoint(name, rng, minFromCamp, maxFromCamp)
			buildCone(name .. "Cone" .. i, at, patchTop, coneRadius, coneHeight, coneColor, rng, parent)
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
-- client finds it under Workspace.World.Landmarks without knowing the layout. With imported meshes the
-- pedestal cylinder stays as an invisible, still solid anchor (it is the PrimaryPart) and the mesh is its
-- child; each stone is the mesh or, failing that, a block. Meshes are tinted to the layout's colours.
-- A hero shrine model (Layout.Props.shrine) replaces all of that but the anchor: the invisible, still
-- solid pedestal stays as the PrimaryPart with LandmarkId, the hero model is its sibling, untinted (its
-- palette is in its own materials), and no pedestal mesh, glow ball or stone ring is built.
local function buildShrine(groundY: number, parent: Instance)
	local shrine = Layout.Shrine
	local model = Instance.new("Model")
	model.Name = SHRINE_NAME

	local height = pedestalHeight()
	local pedestal = uprightCylinder("Pedestal", shrine.radius * PEDESTAL_RADIUS_FACTOR, height, Vector3.new(shrine.x, groundY + height / 2, shrine.z), shrine.pedestalColor, model)
	pedestal:SetAttribute("LandmarkId", SHRINE_NAME)
	model.PrimaryPart = pedestal

	local heroName = if propNames then propNames.shrine else nil
	local hero = if heroName and Props.Find(heroName) then Props.Place(heroName, CFrame.new(shrine.x, groundY, shrine.z), 1, model, true) else nil
	if hero then
		pedestal.Transparency = 1
		model.Parent = parent
		return
	end

	if propNames then
		local mesh = Props.Place(propNames.pedestal, CFrame.new(shrine.x, groundY, shrine.z), 1, pedestal, true)
		if mesh then
			pedestal.Transparency = 1
			Props.Tint(mesh, shrine.pedestalColor)
		end
	end

	local glowRadius = shrine.stoneHeight * GLOW_RADIUS_FACTOR
	local glow = basePart("Glow", Enum.PartType.Ball, Vector3.one * (glowRadius * 2), CFrame.new(shrine.x, groundY + height + glowRadius, shrine.z), shrine.glowColor, model)
	glow.Material = Enum.Material.Neon
	glow.CanCollide = false

	local stoneSize = Vector3.new(shrine.stoneHeight * STONE_WIDTH_FACTOR, shrine.stoneHeight, shrine.stoneHeight * STONE_DEPTH_FACTOR)
	for i = 1, shrine.stoneCount do
		local angle = (i - 1) / shrine.stoneCount * math.pi * 2
		local at = Vector3.new(shrine.x + math.cos(angle) * shrine.radius, groundY + shrine.stoneHeight / 2, shrine.z + math.sin(angle) * shrine.radius)
		-- yaw the stone so its depth axis points at the centre: the broad face looks inward
		local yaw = CFrame.Angles(0, math.pi / 2 - angle, 0)
		local mesh = if propNames then Props.Place(propNames.shrineStone, CFrame.new(at.X, groundY, at.Z) * yaw, 1, model, true) else nil
		if mesh then
			mesh.Name = "Stone" .. i
			Props.Tint(mesh, shrine.stoneColor)
		else
			basePart("Stone" .. i, Enum.PartType.Block, stoneSize, CFrame.new(at) * yaw, shrine.stoneColor, model)
		end
	end

	model.Parent = parent
end

-- The first BasePart under a model, or nil when it has none.
local function firstBasePart(model: Model): BasePart?
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

-- Stands every hero landmark of the layout on the ground at its point, in list order, and prints one line
-- saying how many were placed and which props were missing (nothing is built for those). A landmark with
-- a landmarkId carries it as an attribute on the model's PrimaryPart (the first BasePart when the prop
-- has none), which is how the client's LandmarkRenderer finds it.
local function placeLandmarks(floorTop: number, parent: Instance)
	local placed = 0
	local missing: { string } = {}
	for _, landmark in ipairs(landmarkList) do
		local flat = Vector3.new(landmark.x, 0, landmark.z)
		local ground = floorTop + regionLift(flat)
		local frame = CFrame.new(landmark.x, ground, landmark.z) * CFrame.Angles(0, math.rad(landmark.yaw), 0)
		local model = Props.Place(landmark.name, frame, landmark.scale, parent, true)
		if model then
			placed += 1
			model.Name = landmark.name
			local landmarkId = landmark.landmarkId
			if landmarkId then
				local anchor = model.PrimaryPart
				if not anchor then
					anchor = firstBasePart(model)
					model.PrimaryPart = anchor
				end
				if anchor then
					anchor:SetAttribute("LandmarkId", landmarkId)
				end
			end
		else
			table.insert(missing, landmark.name)
		end
	end
	local line = ("[%s] world %d: landmarks placed %d of %d"):format(Config.WorkingTitle, Layout.WorldId, placed, #landmarkList)
	if #missing > 0 then
		line ..= (" (missing: %s)"):format(table.concat(missing, ", "))
	end
	print(line)
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

	-- The home's plot for the house grid: a flat block on the floor, past the pad on +Z.
	local plot = plotShape()
	if plot then
		basePart("Plot", Enum.PartType.Block, Vector3.new(plot.side, plot.thickness, plot.side), CFrame.new(0, floorTop + plot.thickness / 2, plot.centerZ), plot.color, world)
	end

	-- The trophy hangar's pads, the spin wheel kiosk and the mailbox (home only: other layouts set none of them).
	buildHomeStands(floorTop, world)

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

	-- The world's landmark. Scatter already kept clear of its ring (scatterPoint). The home has neither.
	if not Place.IsHome() then
		local shrineAt = shrineFlat()
		buildShrine(floorTop + regionLift(shrineAt), landmarks)

		-- Hero set pieces from the layout; scatter already kept clear of each one (clearOfLandmarks).
		placeLandmarks(floorTop, landmarks)
	end

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

-- The middle of the plot's top face, where the house grid stands (the home planet; see the header), or nil
-- when this layout has no plot. Derived from the layout like GetShrinePosition.
function Meadow.GetPlotCenter(): Vector3?
	local plot = plotShape()
	if not plot then
		return nil
	end
	return Vector3.new(0, Meadow.GetFloorTop() + plot.thickness, plot.centerZ)
end

return Meadow
