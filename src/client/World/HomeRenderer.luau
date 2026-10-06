--!strict
-- StarterPlayerScripts.Client.World.HomeRenderer: the house grid on the home planet, drawn locally from the
-- profile mirror (State "home"). The server alone decides what stands on the plot (PlaceHomeItem and
-- RemoveHomeItem answer, HomeChanged pushes the whole table); this module only turns that table into parts
-- under a client-made Workspace.ClientHome folder (Instance.new on the client, so nothing replicates) and
-- redraws by uid diff: an item that left or moved is destroyed, a new one is built, the rest stay put.
-- Home only: elsewhere Start does nothing and every query answers nil, math.huge or empty.
--
-- The grid: the plot is the server's Workspace.World.Plot block. Its cells are PlotCellStuds square (data/Home),
-- PlotCells a side, counted 0-based from the plot's -X,-Z corner, and every position here is worked out from the
-- part's own CFrame and Size, so the maths follows the part wherever the world builder put it. An item's cell is
-- the corner of its footprint (the -X,-Z end): it covers cellsX by cellsZ cells from there, the two swapped for
-- rotations 1 and 3 (data/HomeBuild). Rotation is quarter turns about Y.
--
-- Looks: an item with an imported prop (Shared/Props, named by the row's `prop`) is that prop stood on the
-- footprint's centre; without one it is the row's placeholder: a Block of the footprint's size, an upright
-- Cylinder of the footprint's two sides, or a Ball as wide as the smallest of the footprint's sides and the
-- height (a Ball cannot be squashed), each `placeholder.height` tall and standing on the plot's top. Placed
-- items are anchored and collidable so players walk around them. The ghost (SetGhost) is the same
-- placeholder half see-through and lifted a hair so it never z-fights the plot; it never collides.
-- Every placed item and the ghost can be hit by a ray (CanQuery on) and carries an attribute naming it
-- (HomeUid, HomeGhost), so a tap on a tall tower resolves to the tower, not the ground behind it.
--
-- Habitats (milestone 42c, data/Habitats): an item of kind "habitat" is its prop when one was imported, else a
-- Model of its placeholder pad plus a fence ring (Habitats.PostsPerSide posts per side, corners shared, each
-- FencePostStuds square and FenceHeightStuds tall, in the pad's colour darkened, flush with the footprint's edge).
-- The aliens on display are drawn from the mirror, not from the item: every record in State's aliens whose
-- `habitat` names a placed habitat gets a model (World.Models at Habitats.DisplayScale times its size band and
-- growth stage) or its placeholder shape, with a name plate (the species name), standing on the pad inside
-- Workspace.ClientHome.Displayed. They wander: one RenderStepped for all picks a random spot WanderInsetStuds
-- inside the footprint's edges, walks to it at WanderSpeedStudsPerSecond facing the way it goes, stands still
-- WanderPauseMin to WanderPauseMax seconds, and picks again. The set is rebuilt by uid diff on the "stations" and
-- "home" topics: a record that left the habitat (or whose species, size or stage changed) is destroyed.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Place = require(Shared:WaitForChild("Place"))
local Props = require(Shared:WaitForChild("Props"))
local Growth = require(Shared:WaitForChild("Growth"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local HomeBuild = require(Shared:WaitForChild("data"):WaitForChild("HomeBuild"))
local Habitats = require(Shared:WaitForChild("data"):WaitForChild("Habitats"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Sizes = require(Shared:WaitForChild("data"):WaitForChild("Sizes"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Models = require(script.Parent:WaitForChild("Models"))

local HomeRenderer = {}

local FOLDER_NAME = "ClientHome"
local DISPLAY_FOLDER_NAME = "Displayed" -- under ClientHome: the aliens on display
local GHOST_NAME = "Ghost"
local UID_ATTRIBUTE = "HomeUid" -- on a placed item's part or prop model: the uid the server gave it
local GHOST_ATTRIBUTE = "HomeGhost" -- on the ghost part
local QUARTER_TURN = math.pi / 2 -- the roll that stands a Cylinder (its axis is X) upright
local TURN_PER_STEP = math.pi * 2 / HomeBuild.RotationSteps -- radians for one rotation step
local PROP_SCALE = 1 -- props stand at their authored size
local PLATE_LIFT = 1.2 -- studs between the top of a displayed alien and its name plate, as in the other renderers
local PLATE_WIDTH = 7 -- studs: a BillboardGui's Scale is studs
local PLATE_HEIGHT = 1

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

-- The plot's part with the two numbers the data gives it (data/Home PlotCells and PlotCellStuds).
type Grid = { part: BasePart, cells: number, studs: number }
-- What stands drawn for a uid: the item as it was drawn (to spot a change) and the instance that shows it.
type Drawn = { item: Types.HomeItem, instance: Instance }
-- A habitat's footprint in its own frame: the middle of its top face on the plot, its turn (a rotation, no
-- position), half its size along its own X and Z, and the height of its pad (what a displayed alien stands on).
type Habitat = { center: Vector3, turn: CFrame, halfX: number, halfZ: number, rise: number }
-- One alien on display. Its place (x, z) and goal are in the habitat's own frame, so a habitat turned by a
-- redraw carries its aliens with it; `heading` is the unit direction (X, Z) it faces in that frame.
type Display = {
	uid: string,
	habitatUid: string,
	species: string,
	size: string, -- the size band id it is drawn at (data/Sizes)
	stage: string, -- the growth stage id it is drawn at (data/Growth)
	habitat: Habitat,
	part: Part, -- the placeholder, or an invisible anchor as tall as the mesh that carries the plate
	model: Model?, -- the mesh clone when the species has one
	height: number, -- studs from the feet to the top of what is drawn
	upright: CFrame, -- the roll that stands a placeholder cylinder up; identity otherwise
	x: number,
	z: number,
	goalX: number,
	goalZ: number,
	heading: Vector3,
	pause: number, -- seconds left standing still; 0 while walking to the goal
}

local localPlayer = Players.LocalPlayer
local rng = Random.new()

local running = false
local folder: Folder? = nil
local displayFolder: Folder? = nil
local grid: Grid? = nil
local drawn: { [string]: Drawn } = {}
local displays: { [string]: Display } = {}
local ghost: Part? = nil

-- Grid maths ----------------------------------------------------------------

-- The footprint in cells (along X, along Z) of an item turned `rotation` quarter turns.
local function footprint(def: HomeBuild.Item, rotation: number): (number, number)
	if rotation % 2 == 1 then
		return def.cellsZ, def.cellsX
	end
	return def.cellsX, def.cellsZ
end

-- The world point on the plot's top face at `x`, `z` cells from its -X,-Z corner (fractions are fine).
local function plotPoint(g: Grid, x: number, z: number): Vector3
	local size = g.part.Size
	return g.part.CFrame:PointToWorldSpace(Vector3.new(x * g.studs - size.X / 2, size.Y / 2, z * g.studs - size.Z / 2))
end

-- The plot's own turn followed by `rotation` quarter turns about Y, with no position.
local function turnOf(g: Grid, rotation: number): CFrame
	return g.part.CFrame.Rotation * CFrame.Angles(0, rotation * TURN_PER_STEP, 0)
end

-- Parts -----------------------------------------------------------------------

-- The row's placeholder as an anchored Part standing on the plot at the footprint's centre, `lift` studs up,
-- parented under `parent`. Nil for an item id the data does not know.
local function placeholder(g: Grid, itemId: string, cellX: number, cellZ: number, rotation: number, lift: number, parent: Instance): Part?
	local def = HomeBuild.ById[itemId]
	if not def then
		return nil
	end
	local look = def.placeholder
	local width, depth = def.cellsX * g.studs, def.cellsZ * g.studs
	local size: Vector3
	local rise: number -- the part's height, so its middle sits half of it above the plot
	local roll = CFrame.identity
	if look.shape == "Cylinder" then
		size = Vector3.new(look.height, width, depth) -- a Cylinder's axis is X: length first, then the two diameters
		rise = look.height
		roll = CFrame.Angles(0, 0, QUARTER_TURN)
	elseif look.shape == "Ball" then
		local diameter = math.min(width, depth, look.height)
		size = Vector3.one * diameter
		rise = diameter
	else
		size = Vector3.new(width, look.height, depth)
		rise = look.height
	end
	local w, d = footprint(def, rotation)
	local part = Instance.new("Part")
	part.Name = itemId
	part.Shape = SHAPES[look.shape] or Enum.PartType.Block
	part.Size = size
	part.CFrame = CFrame.new(plotPoint(g, cellX + w / 2, cellZ + d / 2)) * turnOf(g, rotation) * CFrame.new(0, rise / 2 + lift, 0) * roll
	part.Color = Color3.fromHex(look.color)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- The footprint of a placed habitat in its own frame; nil for an item that is not a habitat.
local function habitatOf(g: Grid, item: Types.HomeItem): Habitat?
	local def = HomeBuild.ById[item.itemId]
	if not def or def.kind ~= "habitat" then
		return nil
	end
	local w, d = footprint(def, item.rotation)
	return {
		center = plotPoint(g, item.cellX + w / 2, item.cellZ + d / 2),
		turn = turnOf(g, item.rotation),
		halfX = def.cellsX * g.studs / 2,
		halfZ = def.cellsZ * g.studs / 2,
		rise = def.placeholder.height,
	}
end

-- The placeholder habitat: a Model of the row's pad and a ring of fence posts around its edge. Posts stand on the
-- pad, flush with the footprint's edge, Habitats.PostsPerSide to a side with the corner posts shared, each in the
-- pad's colour darkened. The pad and the posts collide and can be hit by a ray; the Model carries the uid.
local function drawHabitat(g: Grid, parent: Instance, item: Types.HomeItem, habitat: Habitat): Model?
	local model = Instance.new("Model")
	model.Name = item.itemId
	local pad = placeholder(g, item.itemId, item.cellX, item.cellZ, item.rotation, 0, model)
	if not pad then
		model:Destroy()
		return nil
	end
	pad.CanCollide = true
	pad.CanQuery = true
	local postColor = Builder.darker(pad.Color)
	local postSize = Vector3.new(Habitats.FencePostStuds, Habitats.FenceHeightStuds, Habitats.FencePostStuds)
	local reachX = habitat.halfX - Habitats.FencePostStuds / 2 -- the posts' middles, so their outer faces sit on the edge
	local reachZ = habitat.halfZ - Habitats.FencePostStuds / 2
	local gaps = math.max(1, Habitats.PostsPerSide - 1) -- spaces between the posts along one side
	local base = CFrame.new(habitat.center) * habitat.turn
	local index = 0
	for side = 0, 3 do
		for step = 0, gaps - 1 do
			local along = step / gaps -- 0 at the side's first corner, short of 1 so the next side owns its corner
			local x: number, z: number
			if side == 0 then -- along +X on the -Z edge
				x, z = -reachX + 2 * reachX * along, -reachZ
			elseif side == 1 then -- along +Z on the +X edge
				x, z = reachX, -reachZ + 2 * reachZ * along
			elseif side == 2 then -- along -X on the +Z edge
				x, z = reachX - 2 * reachX * along, reachZ
			else -- along -Z on the -X edge
				x, z = -reachX, reachZ - 2 * reachZ * along
			end
			index += 1
			local post = Instance.new("Part")
			post.Name = "Post" .. index
			post.Size = postSize
			post.CFrame = base * CFrame.new(x, habitat.rise + postSize.Y / 2, z)
			post.Color = postColor
			post.Material = Enum.Material.SmoothPlastic
			post.Anchored = true
			post.CanCollide = true
			post.CanQuery = true
			post.CastShadow = false
			post.TopSurface = Enum.SurfaceType.Smooth
			post.BottomSurface = Enum.SurfaceType.Smooth
			post.Parent = model
		end
	end
	model:SetAttribute(UID_ATTRIBUTE, item.uid)
	model.Parent = parent
	return model
end

-- Builds one placed item: its prop when the row names one that was imported, else its placeholder (a habitat's
-- is a pad with a fence). All collide (players walk around them), can be hit by a ray, and carry the uid.
local function drawItem(g: Grid, parent: Instance, item: Types.HomeItem): Instance?
	local def = HomeBuild.ById[item.itemId]
	if not def then
		return nil
	end
	local propName = def.prop
	if propName then
		local w, d = footprint(def, item.rotation)
		local base = CFrame.new(plotPoint(g, item.cellX + w / 2, item.cellZ + d / 2)) * turnOf(g, item.rotation)
		local model = Props.Place(propName, base, PROP_SCALE, parent, true)
		if model then
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.CanQuery = true -- Props.Place turns it off; a tap on the prop must find the prop
				end
			end
			model:SetAttribute(UID_ATTRIBUTE, item.uid)
			return model
		end
	end
	local habitat = habitatOf(g, item)
	if habitat then
		return drawHabitat(g, parent, item, habitat)
	end
	local part = placeholder(g, item.itemId, item.cellX, item.cellZ, item.rotation, 0, parent)
	if part then
		part.CanCollide = true
		part.CanQuery = true
		part:SetAttribute(UID_ATTRIBUTE, item.uid)
	end
	return part
end

local function sameItem(a: Types.HomeItem, b: Types.HomeItem): boolean
	return a.itemId == b.itemId and a.cellX == b.cellX and a.cellZ == b.cellZ and a.rotation == b.rotation
end

-- Redraws by uid diff against the mirror: what left or changed is destroyed, what is new is built.
local function redraw()
	local parent, g = folder, grid
	if not parent or not g or not State.Has() then
		return
	end
	local items = State.Get().home.items
	for uid, record in pairs(drawn) do
		local item = items[uid]
		if item == nil or not sameItem(record.item, item) then
			record.instance:Destroy()
			drawn[uid] = nil
		end
	end
	for uid, item in pairs(items) do
		if drawn[uid] == nil then
			local instance = drawItem(g, parent, item)
			if instance then
				drawn[uid] = { item = item, instance = instance }
			end
		end
	end
end

-- Displayed aliens -------------------------------------------------------------

-- How far from the habitat's middle an alien may walk along its own X and Z: the footprint's half sizes less
-- Habitats.WanderInsetStuds, never below zero.
local function wanderReach(habitat: Habitat): (number, number)
	return math.max(0, habitat.halfX - Habitats.WanderInsetStuds), math.max(0, habitat.halfZ - Habitats.WanderInsetStuds)
end

local function randomSpot(habitat: Habitat): (number, number)
	local reachX, reachZ = wanderReach(habitat)
	return rng:NextNumber(-reachX, reachX), rng:NextNumber(-reachZ, reachZ)
end

local function newDisplayPart(name: string, shape: Enum.PartType, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- The species name over the alien, Fredoka One and outlined through Builder, shown inside NameplateDistance.
local function buildPlate(part: Part, name: string, height: number)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(PLATE_WIDTH, PLATE_HEIGHT) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, height / 2 + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = name,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 1),
	})
	plate.Parent = part
end

-- Puts a display's parts at its place on the pad, facing the way it goes.
local function placeDisplay(display: Display)
	local habitat = display.habitat
	local feet = habitat.center + habitat.turn:VectorToWorldSpace(Vector3.new(display.x, habitat.rise, display.z))
	local facing = CFrame.lookAt(Vector3.zero, habitat.turn:VectorToWorldSpace(display.heading))
	local pivot = CFrame.new(feet) * facing
	display.part.CFrame = pivot * CFrame.new(0, display.height / 2, 0) * display.upright
	local model = display.model
	if model then
		model:PivotTo(pivot)
	end
end

local function buildDisplay(parent: Folder, record: Types.AlienRecord, def: Types.SpeciesDef, habitatUid: string, habitat: Habitat): Display
	local band = Sizes.ById[record.size] or Sizes.ById[Sizes.Default]
	local scale = Habitats.DisplayScale * band.scale * Growth.ScaleMultiplier(record)
	local color = Color3.fromHex(def.placeholder.color)
	local model: Model? = Models.Clone(def, scale)
	local part: Part
	local height: number
	local upright = CFrame.identity
	if model then
		-- The mesh's pivot is its bottom centre; the invisible anchor is as tall as the mesh and carries the plate.
		height = Models.Height(model)
		part = newDisplayPart(record.uid, Enum.PartType.Block, Vector3.one * height, color)
		part.Transparency = 1
		model.Name = record.uid .. "Model"
		model.Parent = parent
	else
		height = 2 * def.placeholder.scale * scale
		part = newDisplayPart(record.uid, SHAPES[def.placeholder.shape] or Enum.PartType.Ball, Vector3.one * height, color)
		if def.placeholder.shape == "Cylinder" then
			upright = CFrame.Angles(0, 0, QUARTER_TURN) -- stand it upright, as CompanionRenderer does
		end
	end
	buildPlate(part, def.name, height)
	part.Parent = parent
	local x, z = randomSpot(habitat)
	local angle = rng:NextNumber(0, math.pi * 2)
	local display: Display = {
		uid = record.uid,
		habitatUid = habitatUid,
		species = record.species,
		size = record.size,
		stage = Growth.StageOf(record).id,
		habitat = habitat,
		part = part,
		model = model,
		height = height,
		upright = upright,
		x = x,
		z = z,
		goalX = x,
		goalZ = z,
		heading = Vector3.new(math.cos(angle), 0, math.sin(angle)),
		pause = rng:NextNumber(Habitats.WanderPauseMin, Habitats.WanderPauseMax), -- staggered, so they do not all set off together
	}
	placeDisplay(display)
	return display
end

local function destroyDisplay(display: Display)
	display.part:Destroy()
	local model = display.model
	if model then
		model:Destroy()
	end
end

-- The same alien in the same habitat after a redraw: take the habitat's new footprint and stay inside it.
local function retarget(display: Display, habitat: Habitat)
	display.habitat = habitat
	local reachX, reachZ = wanderReach(habitat)
	display.x = math.clamp(display.x, -reachX, reachX)
	display.z = math.clamp(display.z, -reachZ, reachZ)
	display.goalX = math.clamp(display.goalX, -reachX, reachX)
	display.goalZ = math.clamp(display.goalZ, -reachZ, reachZ)
end

-- Brings the drawn aliens in line with the mirror by uid: a record that left its habitat (or whose habitat is gone,
-- or whose species, size band or growth stage changed) is destroyed, a record on display that is not drawn yet is
-- built. Everything else keeps its place and its walk.
local function syncDisplays()
	local parent, g = displayFolder, grid
	if not parent or not g or not State.Has() then
		return
	end
	local profile = State.Get()
	local items = profile.home.items
	for uid, display in pairs(displays) do
		local record = profile.aliens[uid]
		local habitatUid = if record then record.habitat else nil
		local item = if habitatUid ~= nil then items[habitatUid] else nil
		local habitat = if item then habitatOf(g, item) else nil
		if
			record == nil
			or habitat == nil
			or habitatUid ~= display.habitatUid
			or record.species ~= display.species
			or record.size ~= display.size
			or Growth.StageOf(record).id ~= display.stage
		then
			destroyDisplay(display)
			displays[uid] = nil
		else
			retarget(display, habitat)
		end
	end
	for uid, record in pairs(profile.aliens) do
		local habitatUid = record.habitat
		if habitatUid == nil or displays[uid] ~= nil then
			continue
		end
		local item = items[habitatUid]
		local habitat = if item then habitatOf(g, item) else nil
		local def = Species.ById[record.species]
		if habitat and def then
			displays[uid] = buildDisplay(parent, record, def, habitatUid, habitat)
		end
	end
end

-- One frame for every displayed alien: stand still until the pause runs out, then pick a spot inside the habitat
-- and walk to it at Habitats.WanderSpeedStudsPerSecond, facing the way it goes; on arrival, pause again.
local function onRender(dt: number)
	for _, display in pairs(displays) do
		if display.pause > 0 then
			display.pause -= dt
			if display.pause <= 0 then
				display.pause = 0
				display.goalX, display.goalZ = randomSpot(display.habitat)
			end
		else
			local toX, toZ = display.goalX - display.x, display.goalZ - display.z
			local distance = math.sqrt(toX * toX + toZ * toZ)
			local step = Habitats.WanderSpeedStudsPerSecond * dt
			if step >= distance then
				display.x, display.z = display.goalX, display.goalZ
				display.pause = rng:NextNumber(Habitats.WanderPauseMin, Habitats.WanderPauseMax)
			else
				display.heading = Vector3.new(toX / distance, 0, toZ / distance)
				display.x += toX / distance * step
				display.z += toZ / distance * step
			end
		end
		placeDisplay(display)
	end
end

-- Public API -------------------------------------------------------------

-- Creates Workspace.ClientHome and draws the mirror's items (and the aliens on display in its habitats) once the
-- plot and the profile are both known. Home only; returns at once (the plot wait runs in its own thread).
function HomeRenderer.Start()
	if running or not Place.IsHome() then
		return
	end
	running = true
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folder = created
	local shown = Instance.new("Folder")
	shown.Name = DISPLAY_FOLDER_NAME
	shown.Parent = created
	displayFolder = shown
	State.OnChanged("home", function()
		redraw()
		syncDisplays()
	end)
	State.OnChanged("stations", syncDisplays)
	RunService.RenderStepped:Connect(onRender)
	task.spawn(function()
		local layout = Place.Layout()
		local cells, studs = layout.PlotCells, layout.PlotCellStuds
		if cells == nil or studs == nil then
			return -- this layout has no plot
		end
		local plot = Workspace:WaitForChild("World"):WaitForChild("Plot")
		if not plot:IsA("BasePart") then
			return
		end
		grid = { part = plot, cells = cells, studs = studs }
		redraw()
		syncDisplays()
	end)
end

-- The cell under a world point, 0-based from the plot's -X,-Z corner, or nil nil when the point is off the plot.
function HomeRenderer.CellAt(worldPosition: Vector3): (number?, number?)
	local g = grid
	if not g then
		return nil, nil
	end
	local size = g.part.Size
	local at = g.part.CFrame:PointToObjectSpace(worldPosition)
	local x = (at.X + size.X / 2) / g.studs
	local z = (at.Z + size.Z / 2) / g.studs
	if x < 0 or z < 0 then
		return nil, nil
	end
	local cellX, cellZ = math.floor(x), math.floor(z)
	if cellX >= g.cells or cellZ >= g.cells then
		return nil, nil
	end
	return cellX, cellZ
end

-- The middle of a cell on the plot's top face (the origin before the plot is known).
function HomeRenderer.CellCenter(cellX: number, cellZ: number): Vector3
	local g = grid
	if not g then
		return Vector3.zero
	end
	return plotPoint(g, cellX + 0.5, cellZ + 0.5)
end

-- Flat (X and Z) distance from the local character's root to the plot's centre; math.huge without a plot or a character.
function HomeRenderer.PlotDistance(): number
	local g = grid
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not g or not root or not root:IsA("BasePart") then
		return math.huge
	end
	local dx, dz = root.Position.X - g.part.Position.X, root.Position.Z - g.part.Position.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- The placed item whose footprint covers a cell, from the mirror; nil for an empty cell.
function HomeRenderer.ItemAt(cellX: number, cellZ: number): Types.HomeItem?
	if not State.Has() then
		return nil
	end
	for _, item in pairs(State.Get().home.items) do
		local def = HomeBuild.ById[item.itemId]
		if def then
			local w, d = footprint(def, item.rotation)
			if cellX >= item.cellX and cellX < item.cellX + w and cellZ >= item.cellZ and cellZ < item.cellZ + d then
				return item
			end
		end
	end
	return nil
end

-- The habitats of a world on the plot, from the mirror, each with how many places are free (its capacity less the
-- aliens on display in it), in uid order. Empty away from home or before the profile is in.
function HomeRenderer.HabitatsFor(worldId: number): { { uid: string, free: number } }
	local out: { { uid: string, free: number } } = {}
	if not running or not State.Has() then
		return out
	end
	local profile = State.Get()
	local counts: { [string]: number } = {}
	for _, record in pairs(profile.aliens) do
		local habitatUid = record.habitat
		if habitatUid ~= nil then
			counts[habitatUid] = (counts[habitatUid] or 0) + 1
		end
	end
	for uid, item in pairs(profile.home.items) do
		local def = HomeBuild.ById[item.itemId]
		if def and def.kind == "habitat" and def.worldId == worldId then
			table.insert(out, { uid = uid, free = math.max(0, (def.capacity or 0) - (counts[uid] or 0)) })
		end
	end
	table.sort(out, function(a, b)
		return a.uid < b.uid
	end)
	return out
end

-- Shows the ghost: the item's placeholder half see-through at a cell, turned `rotation` quarter turns. Any
-- ghost already up is replaced; a nil item or cell clears it.
function HomeRenderer.SetGhost(itemId: string?, cellX: number?, cellZ: number?, rotation: number)
	local existing = ghost
	if existing then
		existing:Destroy()
		ghost = nil
	end
	local g, parent = grid, folder
	if not g or not parent or itemId == nil or cellX == nil or cellZ == nil then
		return
	end
	local part = placeholder(g, itemId, cellX, cellZ, rotation, HomeBuild.PreviewLift, parent)
	if not part then
		return
	end
	part.Name = GHOST_NAME
	part.Transparency = HomeBuild.GhostTransparency
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part:SetAttribute(GHOST_ATTRIBUTE, true)
	ghost = part
end

-- Ray helpers for the Build screen ----------------------------------------------

-- The server's plot part, for the ray's reach; nil until it has arrived and away from home.
function HomeRenderer.Plot(): BasePart?
	local g = grid
	return if g then g.part else nil
end

-- What a tap's ray may hit: the plot and the ghost, or with `withItems` the plot and every placed item (the
-- ghost is not in that set; placing and removing never share a ray). Empty away from home.
function HomeRenderer.RayTargets(withItems: boolean): { Instance }
	local g, parent = grid, folder
	if not g or not parent then
		return {}
	end
	local targets: { Instance } = { g.part }
	if withItems then
		for _, record in pairs(drawn) do
			table.insert(targets, record.instance)
		end
	else
		local current = ghost
		if current then
			table.insert(targets, current)
		end
	end
	return targets
end

-- What a ray hit belongs to: the uid of the placed item (nil for the plot, the ghost or anything else) and
-- whether it is the ghost.
function HomeRenderer.Identify(instance: Instance): (string?, boolean)
	local parent = folder
	local current: Instance? = instance
	while current and current ~= parent and current ~= Workspace do
		local uid = current:GetAttribute(UID_ATTRIBUTE)
		if type(uid) == "string" then
			return uid, false
		end
		if current:GetAttribute(GHOST_ATTRIBUTE) == true then
			return nil, true
		end
		current = current.Parent
	end
	return nil, false
end

return HomeRenderer
