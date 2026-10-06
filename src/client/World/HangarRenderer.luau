--!strict
-- StarterPlayerScripts.Client.World.HangarRenderer: the trophy hangar on the home planet (milestone 42d). The
-- world builder stands three upright pads in a row on -Z of the camp (Workspace.World.HangarPad1..3; data/Home
-- HangarCenterZ, HangarSpacingStuds, HangarPadRadius); this module puts one trophy on each pad for every world
-- the player has launched from, drawn locally from the profile mirror (State "world" and "outposts") under a
-- client-made Workspace.ClientHangar folder, so nothing replicates. The server alone decides which worlds the
-- player has launched from (the keys of profile.world.outposts); this only turns that list into parts.
--
-- A trophy is the ship hull (Camp.Props.ship through Props.Place at Home.HangarScale of its size) standing on the
-- pad's top, or, while the hull was never imported, a Block of the Hull Frame's size (Camp.Modules.HullFrame) times Home.HangarScale in
-- Camp.ShipBaseColor. On top of it sits the pilot's silhouette, a Ball as wide as the camp ship's life pod is
-- (Camp.Modules.LifePod) at the same Home.HangarScale, in Theme.Shadow, and over that a name plate with the world's
-- name (HANGAR_PLATE over WORLD_<id>). The worlds go onto the pads in ascending id order, the lowest id on
-- HangarPad1; a world with no pad left stays undrawn. Home only: elsewhere Start does nothing.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Place = require(Shared:WaitForChild("Place"))
local Props = require(Shared:WaitForChild("Props"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Camp = require(Shared:WaitForChild("data"):WaitForChild("Camp"))
local Home = require(Shared:WaitForChild("data"):WaitForChild("Home"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local HangarRenderer = {}

local FOLDER_NAME = "ClientHangar"
local PAD_PREFIX = "HangarPad" -- the server's pads are HangarPad1, HangarPad2, ...
local PLATE_LIFT = 1.2 -- studs between the top of the pilot and its name plate, as in the other renderers
local PLATE_WIDTH = 9 -- studs: a BillboardGui's Scale is studs; wide enough for "Verdant Crash Site"
local PLATE_HEIGHT = 1.2

-- What stands on one pad: the pad it was drawn for and the world it shows (to spot a change), and its Model.
type Stand = { pad: BasePart, worldId: number, model: Model }

local running = false
local folder: Folder? = nil
local worldFolder: Instance? = nil -- Workspace.World, once the pads are known to be there
local stands: { [number]: Stand } = {} -- by pad number

-- The worlds the player has launched from, ascending: the keys of the mirror's outposts table.
local function launchedWorlds(): { number }
	local ids: { number } = {}
	if not State.Has() then
		return ids
	end
	for key in pairs(State.Get().world.outposts) do
		local id = tonumber(key)
		if id ~= nil then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

-- The middle of a pad's top face. Read from the part's own bounds, so it holds however the builder turned the
-- cylinder to stand it up.
local function topCentre(pad: BasePart): Vector3
	local cframe, half = pad.CFrame, pad.Size / 2
	local rise = math.abs(cframe.RightVector.Y) * half.X + math.abs(cframe.UpVector.Y) * half.Y + math.abs(cframe.LookVector.Y) * half.Z
	return Vector3.new(cframe.Position.X, cframe.Position.Y + rise, cframe.Position.Z)
end

-- An anchored, collision-free, shadow-free part (a trophy is for looking at).
local function newPart(name: string, shape: Enum.PartType, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- The world's name over the pilot, Fredoka One and outlined through Builder, shown inside NameplateDistance.
local function buildPlate(pilot: Part, worldId: number, pilotSize: number)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = pilot
	plate.Size = UDim2.fromScale(PLATE_WIDTH, PLATE_HEIGHT) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, pilotSize / 2 + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = Strings.HANGAR_PLATE:format(Builder.text("WORLD_" .. tostring(worldId))),
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 1),
	})
	plate.Parent = pilot
end

-- One trophy on `pad`: the hull (or its placeholder) on the pad's top, the pilot's ball on the hull's top, the plate.
local function buildStand(parent: Folder, pad: BasePart, worldId: number): Stand
	local model = Instance.new("Model")
	model.Name = "Hangar" .. tostring(worldId)
	local top = topCentre(pad)
	local scale = Home.HangarScale
	local height: number
	local hull = Props.Place(Camp.Props.ship, CFrame.new(top), scale, model, false)
	if hull then
		height = hull:GetExtentsSize().Y
	else
		-- The hull frame's size, not the flat base slab: a plate 0.175 studs thick read as nothing on the pad.
		local size = Camp.Modules.HullFrame.size * scale
		newPart("Hull", Enum.PartType.Block, size, CFrame.new(top + Vector3.new(0, size.Y / 2, 0)), Color3.fromHex(Camp.ShipBaseColor), model)
		height = size.Y
	end
	local pilotSize = Camp.Modules.LifePod.size.X * scale
	local pilot = newPart("Pilot", Enum.PartType.Ball, Vector3.one * pilotSize, CFrame.new(top + Vector3.new(0, height + pilotSize / 2, 0)), Theme.Shadow, model)
	buildPlate(pilot, worldId, pilotSize)
	model.Parent = parent
	return { pad = pad, worldId = worldId, model = model }
end

-- Brings the trophies in line with the mirror by pad: a pad whose world changed (or that is itself a new part) is
-- cleared and redrawn, an empty pad with a launched world gets its trophy, the rest stay put.
local function redraw()
	local parent, base = folder, worldFolder
	if not parent or not base or not State.Has() then
		return
	end
	local ids = launchedWorlds()
	local number = 1
	while true do
		local found = base:FindFirstChild(PAD_PREFIX .. tostring(number))
		if found == nil or not found:IsA("BasePart") then
			break
		end
		local wanted = ids[number]
		local stand = stands[number]
		if stand and (stand.worldId ~= wanted or stand.pad ~= found) then
			stand.model:Destroy()
			stands[number] = nil
		end
		if wanted ~= nil and stands[number] == nil then
			stands[number] = buildStand(parent, found, wanted)
		end
		number += 1
	end
	for index, stand in pairs(stands) do
		if index >= number then -- its pad is gone
			stand.model:Destroy()
			stands[index] = nil
		end
	end
end

-- Public API -------------------------------------------------------------

-- Creates Workspace.ClientHangar and draws the trophies once the pads and the profile are both known. Home only;
-- returns at once (the pad wait runs in its own thread).
function HangarRenderer.Start()
	if running or not Place.IsHome() then
		return
	end
	running = true
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folder = created
	State.OnChanged("world", redraw)
	State.OnChanged("outposts", redraw)
	task.spawn(function()
		local container = Workspace:WaitForChild("World")
		container:WaitForChild(PAD_PREFIX .. "1")
		worldFolder = container
		redraw()
	end)
end

return HangarRenderer
