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

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Place = require(Shared:WaitForChild("Place"))
local Props = require(Shared:WaitForChild("Props"))
local HomeBuild = require(Shared:WaitForChild("data"):WaitForChild("HomeBuild"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local HomeRenderer = {}

local FOLDER_NAME = "ClientHome"
local GHOST_NAME = "Ghost"
local UID_ATTRIBUTE = "HomeUid" -- on a placed item's part or prop model: the uid the server gave it
local GHOST_ATTRIBUTE = "HomeGhost" -- on the ghost part
local QUARTER_TURN = math.pi / 2 -- the roll that stands a Cylinder (its axis is X) upright
local TURN_PER_STEP = math.pi * 2 / HomeBuild.RotationSteps -- radians for one rotation step
local PROP_SCALE = 1 -- props stand at their authored size

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

-- The plot's part with the two numbers the data gives it (data/Home PlotCells and PlotCellStuds).
type Grid = { part: BasePart, cells: number, studs: number }
-- What stands drawn for a uid: the item as it was drawn (to spot a change) and the instance that shows it.
type Drawn = { item: Types.HomeItem, instance: Instance }

local localPlayer = Players.LocalPlayer

local running = false
local folder: Folder? = nil
local grid: Grid? = nil
local drawn: { [string]: Drawn } = {}
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

-- Builds one placed item: its prop when the row names one that was imported, else its placeholder. Both
-- collide (players walk around them), can be hit by a ray, and carry the uid.
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

-- Public API -------------------------------------------------------------

-- Creates Workspace.ClientHome and draws the mirror's items once the plot and the profile are both known.
-- Home only; returns at once (the plot wait runs in its own thread).
function HomeRenderer.Start()
	if running or not Place.IsHome() then
		return
	end
	running = true
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folder = created
	State.OnChanged("home", redraw)
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
