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
-- Generated ground (B44 block cells, 2026-10-21): a world with a generated grid (Shared/WorldGrid over data/WorldGen1 and WorldGen2,
-- written by tools/blocky/world_gen.py) is built from it instead of the flat floor and its coloured patches: caps, bodies, water,
-- waterfalls and solids (roofs, bridges, decks) as plain Parts in streaming chunk Models under World/Ground, each face wearing its
-- block-cell tile (data/BlockTiles) once that id is real and the kind's colour and Material until then; one base slab under everything;
-- invisible walls only at the map edge. The cap under the camp is MeadowFloor (its top is the old floor top, so every client that reads
-- it still finds the camp ground). The scattered props (World/Scatter) are the props worker's meshes where imported, else block-built
-- placeholders from data/WorldKit. The shrine and the landmarks stand on the generated ground; the regions keep their ids and circles
-- (Shared/Biomes), only the look moved into the ground. GetSurfaceTop, IsSpawnable and GetGrid answer from the grid.
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

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local Layouts = require(Shared.data.Layouts)
local LightingData = require(Shared.data.Lighting)
local Place = require(Shared.Place)
local Biomes = require(Shared.Biomes)
local Props = require(Shared.Props)
local Types = require(Shared.types.Types)
local WorldGrid = require(Shared.WorldGrid)
local WorldKit = require(Shared.data.WorldKit)
local BlockTiles = require(Shared.data.BlockTiles)

local Meadow = {}

local Layout: Layouts.Layout = Place.Layout() -- this place's world; fixed for the server's lifetime
local propNames: Layouts.PropNames? = Layout.Props -- nil: this world imports nothing, every landmark is a placeholder
local NO_NAMES: { string } = {}
local landmarkList: { Layouts.Landmark } = Layout.Landmarks or {} -- hero set pieces; empty when the layout lists none
-- The generated block-cell ground of this world (data/WorldGen<id>), or nil (the home planet keeps the flat placeholder floor).
local grid: WorldGrid.Grid? = WorldGrid.For(Layout.WorldId)
local builtGenerated = false -- true once Init built the generated ground (a hand-built Workspace.World skips it and keeps flat heights)
local spawnKinds: { [string]: boolean } = {}
for kindName, kind in pairs(WorldKit.Kinds) do
	spawnKinds[kindName] = kind.spawn
end

local WORLD_FOLDER = "World"
local WILD_FOLDER = "Wild"
local LANDMARKS_FOLDER = "Landmarks"
local SCATTER_FOLDER = "Scatter" -- the generated world's props, each its own atomic Model
local WATER_TAG = BlockTiles.WaterTag -- the client drifts the water tile on these (World.WorldFx)
local FALL_TAG = BlockTiles.FallTag
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

-- Marks a part as ground: the client's LightingDirector lerps the colour of every part carrying this tag toward the night
-- look's `groundTint` (data/Lighting) and back by day. The tag replicates; the colour change is client-side only.
local function markGround(part: Part): Part
	CollectionService:AddTag(part, LightingData.GroundTag)
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

-- How far the walkable surface sits above the floor top at a flat point: the generated ground's column, water or deck there when
-- this world has one, else the old region patch thickness.
local function surfaceLift(position: Vector3): number
	local generated = grid
	if generated then
		return WorldGrid.SurfaceAt(generated, position.X, position.Z)
	end
	return regionLift(position)
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
	markGround(uprightCylinder(name .. "Floor", region.radius, Layout.RegionPatchThickness, Vector3.new(region.x, floorTop + Layout.RegionPatchThickness / 2, region.z), region.floorColor, parent))

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
		local ground = floorTop + surfaceLift(flat)
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

-- The generated ground (B44 block cells) -------------------------------------------------------------------------------------------

local function enumMaterial(name: string): Enum.Material
	local ok, material = pcall(function(): Enum.Material
		return (Enum.Material :: any)[name]
	end)
	return if ok and material then material else Enum.Material.SmoothPlastic
end

local function tileId(key: string): number
	local row = BlockTiles.Ids[key]
	return if row then row.id else 0
end

-- One Texture tiling a block-cell tile over a face, StudsPerTile a side. `pinTop` aligns a side tile's top edge with the face's top (a
-- cap shows the grass fringe); otherwise the tile is pinned to the world's 2-stud rows from `faceTop`.
local function addTexture(part: BasePart, key: string, face: Enum.NormalId, faceTop: number?, transparency: number?)
	local id = tileId(key)
	if id == 0 then
		return
	end
	local texture = Instance.new("Texture")
	texture.Name = key
	texture.Texture = "rbxassetid://" .. id
	texture.Face = face
	texture.StudsPerTileU = BlockTiles.StudsPerTile
	texture.StudsPerTileV = BlockTiles.StudsPerTile
	if faceTop then
		texture.OffsetStudsV = faceTop % BlockTiles.StudsPerTile
	end
	texture.Transparency = transparency or 0
	texture.Parent = part
end

-- The side faces a row's bits name: 1 +X (Right), 2 -X (Left), 4 +Z (Back), 8 -Z (Front).
local SIDE_FACES: { { bit: number, face: Enum.NormalId } } = {
	{ bit = 1, face = Enum.NormalId.Right },
	{ bit = 2, face = Enum.NormalId.Left },
	{ bit = 4, face = Enum.NormalId.Back },
	{ bit = 8, face = Enum.NormalId.Front },
}

local function groundPart(name: string, size: Vector3, position: Vector3, hex: string, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Color = Color3.fromHex(hex)
	part.Material = material
	part.Anchored = true
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- The streaming chunk Model a column belongs to, made on first use (World/Ground/Chunk_<ci>_<cj>).
local function chunkOf(chunks: { [string]: Model }, groundFolder: Instance, gen: Types.WorldGen, i: number, j: number): Model
	local key = (i // gen.Chunk) .. "_" .. (j // gen.Chunk)
	local known: Model? = chunks[key]
	if known then
		return known
	end
	local created = Instance.new("Model")
	created.Name = "Chunk_" .. key
	created.ModelStreamingMode = Enum.ModelStreamingMode.Default
	created.Parent = groundFolder
	chunks[key] = created
	return created
end

-- A scatter prop's block-built placeholder (data/WorldKit Recipes) standing on `cframe` at `scale`: a Model of plain parts, the
-- collidable ones (trunks, rocks, logs, fences) queryable so the wild aliens' wander raycast sees them, the decor (leaves, petals,
-- flowers) neither colliding nor queryable. A recipe with a light carries one PointLight.
local function buildRecipe(name: string, recipe: Types.PropRecipe, cframe: CFrame, scale: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local tall = 0
	for _, box in ipairs(recipe.boxes) do
		tall = math.max(tall, (box.at[2] + box.size[2] / 2) * scale)
	end
	local first: Part? = nil
	for index, box in ipairs(recipe.boxes) do
		local part = Instance.new("Part")
		part.Name = if index == 1 then "Base" else "Block" .. index
		part.Size = Vector3.new(box.size[1], box.size[2], box.size[3]) * scale
		part.CFrame = cframe * CFrame.new(box.at[1] * scale, box.at[2] * scale, box.at[3] * scale) * CFrame.Angles(0, 0, math.rad(box.roll or 0))
		part.Color = Color3.fromHex(box.color)
		part.Material = if box.neon then Enum.Material.Neon else enumMaterial(box.material)
		part.Anchored = true
		part.CanCollide = box.collide == true
		part.CanQuery = box.collide == true
		part.CanTouch = false
		part.CastShadow = tall >= WorldKit.Build.decorShadowBelow and not box.neon
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model
		if first == nil then
			first = part
		end
	end
	local light = recipe.light
	if light and first then
		local attachment = Instance.new("Attachment")
		attachment.Name = "Light"
		attachment.WorldCFrame = cframe * CFrame.new(light.at[1] * scale, light.at[2] * scale, light.at[3] * scale)
		attachment.Parent = first
		local point = Instance.new("PointLight")
		point.Color = Color3.fromHex(light.color)
		point.Range = light.range * scale
		point.Brightness = light.brightness
		point.Shadows = false
		point.Parent = attachment
	end
	model.PrimaryPart = first
	model.Parent = parent
	return model
end

-- Every scattered prop of the generated world: the props worker's mesh of that name when it is imported (Shared/Props), else the
-- block-built placeholder. A hanging prop (icicles) hangs below its point: a mesh is lowered by its own height.
local function placeGeneratedProps(gen: Types.WorldGen, floorTop: number, parent: Instance)
	local place = gen.Place
	local meshes, placeholders = 0, 0
	for r = 1, #place, WorldGrid.Stride.Place do
		local name = gen.Props[place[r]]
		local cframe = CFrame.new(place[r + 1], floorTop + place[r + 2], place[r + 3]) * CFrame.Angles(0, math.rad(place[r + 4]), 0)
		local scale = place[r + 5]
		local recipe = WorldKit.Recipes[name]
		local mesh = Props.Place(name, cframe, scale, parent, true)
		if mesh then
			meshes += 1
			mesh.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			if recipe and recipe.hang then
				mesh:PivotTo(mesh:GetPivot() * CFrame.new(0, -mesh:GetExtentsSize().Y, 0))
			end
		elseif recipe then
			placeholders += 1
			buildRecipe(name, recipe, cframe, scale, parent)
		end
	end
	print(("[%s] world %d: %d props (%d meshes, %d block placeholders)"):format(Config.WorkingTitle, gen.World, meshes + placeholders, meshes, placeholders))
end

-- The generated ground of this world (data/WorldGen<id>, Shared/WorldGrid): caps, bodies, water, falls and solids as plain Parts in
-- streaming chunks under World/Ground, the base slab under everything and invisible walls at the map edge. A face wears its block-cell
-- tile (data/BlockTiles) when that id is real, else the kind's colour and a fitting Material. The cap under the camp is MeadowFloor.
local function buildGround(gen: Types.WorldGen, floorTop: number, world: Instance)
	local cell, origin = gen.Cell, gen.Origin
	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "Ground"
	groundFolder.Parent = world
	local chunks: { [string]: Model } = {}
	local campI = math.floor((0 - origin) / cell)
	local floorNamed = false

	local caps = gen.Caps
	for r = 1, #caps, WorldGrid.Stride.Caps do
		local i, j, w, d, top = caps[r], caps[r + 1], caps[r + 2], caps[r + 3], caps[r + 4]
		local kindName = gen.Kinds[caps[r + 5]]
		local kind = WorldKit.Kinds[kindName]
		local textured = tileId(kind.top) ~= 0
		local isFloor = not floorNamed and top == 0 and i <= campI and campI < i + w and j <= campI and campI < j + d
		local part = groundPart(if isFloor then FLOOR_NAME else "Cap", Vector3.new(w * cell, 1, d * cell),
			Vector3.new(origin + (i + w / 2) * cell, floorTop + top - 0.5, origin + (j + d / 2) * cell),
			kind.color, if textured then Enum.Material.SmoothPlastic else enumMaterial(kind.material), chunkOf(chunks, groundFolder, gen, i, j))
		floorNamed = floorNamed or isFloor
		addTexture(part, kind.top, Enum.NormalId.Top)
		for _, side in ipairs(SIDE_FACES) do
			if bit32.band(caps[r + 6], side.bit) ~= 0 then
				addTexture(part, kind.side, side.face)
			end
		end
		if kind.tint then
			markGround(part)
		end
	end

	local bodies = gen.Bodies
	for r = 1, #bodies, WorldGrid.Stride.Bodies do
		local i, j, w, d, top = bodies[r], bodies[r + 1], bodies[r + 2], bodies[r + 3], bodies[r + 4]
		local kind = WorldKit.Kinds[gen.Kinds[bodies[r + 5]]]
		local height = top - gen.Base
		local textured = tileId(kind.body) ~= 0
		local part = groundPart("Body", Vector3.new(w * cell, height, d * cell),
			Vector3.new(origin + (i + w / 2) * cell, floorTop + gen.Base + height / 2, origin + (j + d / 2) * cell),
			kind.bodyColor, if textured then Enum.Material.SmoothPlastic else enumMaterial(BlockTiles.FallbackMaterial[kind.body] or kind.material),
			chunkOf(chunks, groundFolder, gen, i, j))
		for _, side in ipairs(SIDE_FACES) do
			if bit32.band(bodies[r + 6], side.bit) ~= 0 then
				addTexture(part, kind.body, side.face, top)
			end
		end
		markGround(part)
	end

	local water = gen.Water
	for r = 1, #water, WorldGrid.Stride.Water do
		local i, j, w, d, bottom, top = water[r], water[r + 1], water[r + 2], water[r + 3], water[r + 4], water[r + 5]
		local kindName = gen.Kinds[water[r + 6]]
		local kind = WorldKit.Kinds[kindName]
		local look = WorldKit.Water[kindName]
		local part = groundPart("Water", Vector3.new(w * cell, top - bottom, d * cell),
			Vector3.new(origin + (i + w / 2) * cell, floorTop + (bottom + top) / 2, origin + (j + d / 2) * cell),
			kind.color, Enum.Material.SmoothPlastic, chunkOf(chunks, groundFolder, gen, i, j))
		part.CanCollide = false
		part.CastShadow = false
		part.Transparency = if look then look.transparency else 0.3
		part.Reflectance = if look then look.reflectance else 0
		if look and look.neon then
			part.Material = Enum.Material.Neon
		end
		addTexture(part, kind.top, Enum.NormalId.Top, nil, BlockTiles.WaterTransparency)
		CollectionService:AddTag(part, WATER_TAG)
	end

	local falls = gen.Falls
	local build = WorldKit.Build
	for r = 1, #falls, WorldGrid.Stride.Falls do
		local x, z, width, bottom, top, yaw = falls[r], falls[r + 1], falls[r + 2], falls[r + 3], falls[r + 4], falls[r + 5]
		local fallKind = gen.Kinds[falls[r + 6]]
		local kind = WorldKit.Kinds[fallKind]
		local look = WorldKit.Water[fallKind]
		local glowing = look ~= nil and look.neon
		local part = groundPart("Fall", Vector3.new(width, top - bottom, build.fallThickness),
			Vector3.new(x, floorTop + (bottom + top) / 2, z), if glowing then kind.color else build.fallColor,
			if glowing then Enum.Material.Neon else Enum.Material.SmoothPlastic, world)
		part.CFrame = CFrame.new(x, floorTop + (bottom + top) / 2, z) * CFrame.Angles(0, math.rad(yaw), 0)
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = false
		part.Transparency = build.fallTransparency
		addTexture(part, kind.side, Enum.NormalId.Front, nil, BlockTiles.WaterTransparency)
		addTexture(part, kind.side, Enum.NormalId.Back, nil, BlockTiles.WaterTransparency)
		CollectionService:AddTag(part, FALL_TAG)
	end

	local solids = gen.Solids
	for r = 1, #solids, WorldGrid.Stride.Solids do
		local x0, y0, z0, x1, y1, z1 = solids[r], solids[r + 1], solids[r + 2], solids[r + 3], solids[r + 4], solids[r + 5]
		local kind = WorldKit.Kinds[gen.Kinds[solids[r + 6]]]
		local textured = tileId(kind.top) ~= 0
		local i = math.floor(((x0 + x1) / 2 - origin) / cell)
		local j = math.floor(((z0 + z1) / 2 - origin) / cell)
		local part = groundPart(if solids[r + 7] == 1 then "Deck" else "Roof", Vector3.new(x1 - x0, y1 - y0, z1 - z0),
			Vector3.new((x0 + x1) / 2, floorTop + (y0 + y1) / 2, (z0 + z1) / 2), kind.color,
			if textured then Enum.Material.SmoothPlastic else enumMaterial(kind.material), chunkOf(chunks, groundFolder, gen, math.clamp(i, 0, gen.Count - 1), math.clamp(j, 0, gen.Count - 1)))
		addTexture(part, kind.top, Enum.NormalId.Top)
		addTexture(part, kind.body, Enum.NormalId.Bottom)
		for _, side in ipairs(SIDE_FACES) do
			addTexture(part, kind.side, side.face)
		end
		markGround(part)
	end

	-- the base slab: nothing can fall out of the world from under a column
	local span = gen.Count * cell
	local baseKind = WorldKit.Kinds[gen.Kinds[1]]
	local base = groundPart("WorldBase", Vector3.new(span, build.baseThickness, span),
		Vector3.new(origin + span / 2, floorTop + gen.Base - build.baseThickness / 2, origin + span / 2), baseKind.bodyColor,
		enumMaterial(BlockTiles.FallbackMaterial[baseKind.body] or "Ground"), groundFolder)
	base.CastShadow = false

	-- invisible walls at the map edge, the only invisible walls in the world
	local wallY = floorTop + gen.Base + build.edgeWallHeight / 2
	local half = build.edgeWallThickness / 2
	for _, wall in ipairs({
		{ size = Vector3.new(build.edgeWallThickness, build.edgeWallHeight, span), at = Vector3.new(origin - half, wallY, origin + span / 2) },
		{ size = Vector3.new(build.edgeWallThickness, build.edgeWallHeight, span), at = Vector3.new(origin + span + half, wallY, origin + span / 2) },
		{ size = Vector3.new(span, build.edgeWallHeight, build.edgeWallThickness), at = Vector3.new(origin + span / 2, wallY, origin - half) },
		{ size = Vector3.new(span, build.edgeWallHeight, build.edgeWallThickness), at = Vector3.new(origin + span / 2, wallY, origin + span + half) },
	}) do
		local part = groundPart("EdgeWall", wall.size, wall.at, "FFFFFF", Enum.Material.SmoothPlastic, world)
		part.Transparency = 1
		part.CanQuery = false
		part.CastShadow = false
	end
	if not floorNamed then
		warn(("[%s] world %d: no generated cap at the camp at height 0; MeadowFloor is missing"):format(Config.WorkingTitle, gen.World))
	end
end

-- The camp pad, its SpawnLocation, the home plot and the home stands, on the floor top (the old flat builder and the generated one
-- share it: the generated camp is a flat green at the floor top). `deckBuilt`: the generated ground already lays the camp's deck at
-- the origin (a solid of CampPadThickness, world<id>.json), so the round pad is not drawn over it; the SpawnLocation stands
-- at the same height either way.
local function buildCamp(floorTop: number, world: Instance, deckBuilt: boolean?)
	if not deckBuilt then
		local padY = floorTop + Layout.CampPadThickness / 2
		uprightCylinder("CampPad", Layout.CampPadRadius, Layout.CampPadThickness, Vector3.new(0, padY, 0), Layout.CampPadColor, world)
	end

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
end

-- Whether the generated ground lays a deck over the camp's centre at the pad's height (the camp deck of world<id>.json; a solid
-- with walk off, so the grid keeps the camp contract: SurfaceAt is the floor top there, as under the old round pad).
local function hasCampDeck(gen: Types.WorldGen): boolean
	local solids = gen.Solids
	for r = 1, #solids, WorldGrid.Stride.Solids do
		local x0, y0, z0, x1, y1, z1 = solids[r], solids[r + 1], solids[r + 2], solids[r + 3], solids[r + 4], solids[r + 5]
		if y0 <= 0 and math.abs(y1 - Layout.CampPadThickness) < 0.01 and x0 < 0 and 0 < x1 and z0 < 0 and 0 < z1 then
			return true
		end
	end
	return false
end

-- A generated world: the ground, the camp, the props, then the shrine and the landmarks on the ground under them.
local function buildGenerated(gen: Types.WorldGen, world: Instance, landmarks: Instance)
	local floorTop = Layout.FloorThickness / 2
	buildGround(gen, floorTop, world)
	buildCamp(floorTop, world, hasCampDeck(gen))
	local scatter = Instance.new("Folder")
	scatter.Name = SCATTER_FOLDER
	scatter.Parent = world
	placeGeneratedProps(gen, floorTop, scatter)
	if not Place.IsHome() then
		buildShrine(floorTop + surfaceLift(shrineFlat()), landmarks)
		placeLandmarks(floorTop, landmarks)
	end
	for _, model in ipairs(landmarks:GetChildren()) do
		if model:IsA("Model") then
			model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end
	end
	print(("[%s] world %d: generated ground built (%d ground parts, budget %d)"):format(Config.WorkingTitle, gen.World, gen.Stats.groundParts, WorldKit.Budget.groundParts))
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

	-- A world with generated ground (Worlds 1 and 2) is built from it; the rest (the home planet) keep the flat placeholder below.
	local generated = grid
	if generated then
		buildGenerated(generated.gen, world, landmarks)
		builtGenerated = true
		world.Parent = Workspace
		return
	end

	-- Floor: the part sits at Y = 0 so its top surface is at FloorThickness / 2.
	local floorTop = Layout.FloorThickness / 2
	markGround(basePart(FLOOR_NAME, Enum.PartType.Block, Vector3.new(Layout.FloorSize, Layout.FloorThickness, Layout.FloorSize), CFrame.new(0, 0, 0), Layout.FloorColor, world))

	-- Camp pad at the origin with the SpawnLocation on top, the home plot and stands.
	buildCamp(floorTop, world)

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
-- On a generated world it is the ground under the point (Shared/WorldGrid: the column, the water over it or a bridge or deck).
function Meadow.GetSurfaceTop(position: Vector3): number
	if builtGenerated then
		return Meadow.GetFloorTop() + surfaceLift(position)
	end
	return Meadow.GetFloorTop() + regionLift(position)
end

-- Whether a wild alien may land at a flat point: on a generated world, not in water, not under a bridge or a log, on a ground kind
-- that allows it (data/WorldKit); anywhere on the old flat floor.
function Meadow.IsSpawnable(position: Vector3): boolean
	local generated = grid
	if builtGenerated and generated then
		return WorldGrid.IsSpawnable(generated, position.X, position.Z, spawnKinds)
	end
	return true
end

-- The generated ground's grid (the Spawner reads its rare spots), or nil on a flat placeholder world.
function Meadow.GetGrid(): WorldGrid.Grid?
	return if builtGenerated then grid else nil
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
