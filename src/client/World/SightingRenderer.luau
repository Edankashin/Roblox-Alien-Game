--!strict
-- StarterPlayerScripts.Client.World.SightingRenderer: the Warden walking the land (data/Sightings, GAME_DESIGN
-- section 12). The server keeps one anchored part named after the Warden's species id under
-- Workspace.World.Sightings while a sighting runs (attributes SpeciesId and Progress, its CFrame moved every
-- Sightings.TickSeconds along the path at the floor height, facing its travel) and destroys it at the end; it
-- decides everything about the sighting. This module only draws it, locally, for every client: the species mesh
-- (World.Models) at Sightings.Scale, or the species placeholder shape at the same scale when no mesh was imported,
-- under a client-made Workspace.ClientSightings folder with every part anchored and with collisions, queries and
-- touches off, so no raycast and no tap ever hits it. The server's own part is hidden locally (its ball would sit
-- inside the mesh), and the Warden is never in the Wild folder, so the capture flow and the radar never see it.
-- Look: an invisible anchor part as tall as the mesh (or the placeholder itself) carries the nameplate, the species
-- name only, shown inside Config.NameplateDistance. The model walks at Sightings.SpeedStudsPerSecond toward the server
-- part's feet (the part's bottom) per 60 Hz frame, so the 0.1 s steps look smooth, and turns toward its travel
-- (the server part's last flat movement; the part's own look until it has moved) by Sightings.FaceLerp.
-- Trail: every Sightings.TrailStepStuds walked, one glowing Neon ball (Sightings.TrailSizeStuds, the world's
-- TrailColorByWorld colour, a PointLight of TrailLightRange) is left at the feet; it fades out (transparency and
-- light brightness) over TrailLifeSeconds and destroys itself. A puff belongs to the folder, not to the Warden,
-- so a trail already laid finishes its fade after the Warden has gone; the most alive at once is
-- TrailLifeSeconds / (TrailStepStuds / SpeedStudsPerSecond).
-- Compass: while a sighting starts and the strip has no target, the part becomes its target (labelled
-- COMPASS_SIGHTING by the Compass); it is cleared when the part goes if it is still the target.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Place = require(Shared:WaitForChild("Place"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Sightings = require(Shared:WaitForChild("data"):WaitForChild("Sightings"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Compass = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Compass"))
local Models = require(script.Parent:WaitForChild("Models"))

local SightingRenderer = {}

local FOLDER_NAME = "ClientSightings" -- client-made Workspace folder for the Warden's parts, meshes and trail puffs
local WORLD_FOLDER = "World" -- Workspace.World, made by the server
local SIGHTINGS_FOLDER = "Sightings" -- Workspace.World.Sightings: the server's walking part, one per running sighting
local SPECIES_ATTRIBUTE = "SpeciesId" -- on the server part; its name is the same id
local PLATE_LIFT = 1.2 -- studs between the top of the Warden and its nameplate, as in the other renderers
local BASE_STUDS = 2 -- studs across a placeholder at scale 1, as every renderer draws it
local FRAME_RATE = 60 -- the frame rate Sightings.FaceLerp is a per-frame fraction at

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

type Sighting = {
	part: Part, -- the server's walking part
	body: Part, -- the placeholder, or an invisible anchor as tall as the mesh that carries the plate
	model: Model?, -- the mesh clone when the species has one
	height: number, -- studs from the feet to the top of what is drawn
	upright: CFrame, -- the roll that stands a placeholder cylinder up; identity otherwise
	feet: Vector3, -- where the drawn Warden's feet are (it eases toward the server part's)
	turn: CFrame, -- its facing, an orientation with no position
	heading: Vector3?, -- the flat direction the server part last moved in; nil until it has moved
	lastServer: Vector3, -- where the server part's feet were when it last moved
	lastPuff: Vector3, -- where the last trail puff was left
	placed: boolean, -- false until it has been put at the server part's feet
	connections: { RBXScriptConnection },
}

local running = false
local folder: Folder? = nil
local trailColor: Color3 = Theme.Colors.White
local records: { [Instance]: Sighting } = {}

-- Building ---------------------------------------------------------------------

local function newPart(name: string, shape: Enum.PartType, size: Vector3, color: Color3): Part
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

-- The species name over the Warden, Fredoka One and outlined through Builder, shown inside NameplateDistance.
-- `height` is the studs from the feet to the top of what is drawn; the body is centred half that above the feet.
local function buildPlate(body: Part, name: string, height: number): BillboardGui
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = body
	plate.Size = UDim2.fromScale(7, 1) -- studs
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
	plate.Parent = body
	return plate
end

-- Trail --------------------------------------------------------------------------

-- One glowing puff with its feet on the floor at `at`, fading out over TrailLifeSeconds and then gone.
local function dropPuff(at: Vector3)
	local parent = folder
	if not parent then
		return
	end
	local size = Sightings.TrailSizeStuds
	local puff = newPart("TrailPuff", Enum.PartType.Ball, Vector3.one * size, trailColor)
	puff.Material = Enum.Material.Neon
	puff.CFrame = CFrame.new(at + Vector3.new(0, size / 2, 0))
	local light = Instance.new("PointLight")
	light.Color = trailColor
	light.Range = Sightings.TrailLightRange
	light.Brightness = Sightings.TrailLightBrightness
	light.Parent = puff
	puff.Parent = parent
	local fade = TweenInfo.new(Sightings.TrailLifeSeconds, Enum.EasingStyle.Linear)
	TweenService:Create(puff, fade, { Transparency = 1 }):Play()
	local dim = TweenService:Create(light, fade, { Brightness = 0 })
	dim.Completed:Connect(function()
		puff:Destroy()
	end)
	dim:Play()
end

-- Following ----------------------------------------------------------------------

-- The server part's feet: its bottom, under its centre.
local function feetOf(part: Part): Vector3
	local position = part.Position
	return Vector3.new(position.X, position.Y - part.Size.Y / 2, position.Z)
end

-- The flat direction the Warden should face: where the server part last moved, else the part's own look, else
-- wherever it already faces.
local function faceDirection(s: Sighting): Vector3
	local heading = s.heading
	if heading then
		return heading
	end
	local look = s.part.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0 then
		return flat.Unit
	end
	return s.turn.LookVector
end

-- Moves the drawn feet and facing toward the server part's and drops the trail puffs; the first call puts it there.
local function advance(s: Sighting, dt: number, faceAlpha: number)
	local target = feetOf(s.part)
	local moved = Vector3.new(target.X - s.lastServer.X, 0, target.Z - s.lastServer.Z)
	if moved.Magnitude > 0 then
		s.heading = moved.Unit
		s.lastServer = target
	end
	local desired = CFrame.lookAt(Vector3.zero, faceDirection(s))
	if not s.placed then
		s.placed = true
		s.feet = target
		s.turn = desired
		s.lastPuff = target
		return
	end
	-- Walk toward the server part at the Warden's own speed (it steps ten times a second, so an exponential chase
	-- surged on every step); when it falls behind by more than CatchUpGapStuds it hurries until it is close again.
	local toTarget = target - s.feet
	local distance = toTarget.Magnitude
	if distance > 0 then
		local speed = Sightings.SpeedStudsPerSecond * (if distance > Sightings.CatchUpGapStuds then Sightings.CatchUpScale else 1)
		s.feet += toTarget.Unit * math.min(distance, speed * dt)
	end
	s.turn = s.turn:Lerp(desired, faceAlpha)
	-- One puff per TrailStepStuds walked, left exactly that far along from the last one (a slow frame catches up
	-- one puff per frame, never a burst).
	local gap = s.feet - s.lastPuff
	if gap.Magnitude >= Sightings.TrailStepStuds then
		s.lastPuff += gap.Unit * Sightings.TrailStepStuds
		dropPuff(s.lastPuff)
	end
end

-- Puts the body and the mesh at the feet and facing.
local function place(s: Sighting)
	local pivot = CFrame.new(s.feet) * s.turn
	s.body.CFrame = pivot * CFrame.new(0, s.height / 2, 0) * s.upright
	local model = s.model
	if model then
		model:PivotTo(pivot)
	end
end

local function onRender(dt: number)
	local faceAlpha = 1 - (1 - Sightings.FaceLerp) ^ (dt * FRAME_RATE)
	for _, s in pairs(records) do
		advance(s, dt, faceAlpha)
		place(s)
	end
end

-- Tracking -----------------------------------------------------------------------

local function untrack(part: Instance)
	local s = records[part]
	if not s then
		return
	end
	records[part] = nil
	for _, connection in ipairs(s.connections) do
		connection:Disconnect()
	end
	s.body:Destroy()
	local model = s.model
	if model then
		model:Destroy()
	end
	if Compass.GetTarget() == part then
		Compass.SetTarget(nil)
	end
end

-- Draws one server part: builds its parts, puts them at the part's feet and only then parents them, so no frame
-- shows them at the origin. A part whose species is unknown is left alone.
local function track(child: Instance)
	local parent = folder
	if not parent or records[child] or not child:IsA("Part") then
		return
	end
	local part: Part = child
	local attribute = part:GetAttribute(SPECIES_ATTRIBUTE)
	local def: Types.SpeciesDef? = Species.ById[if type(attribute) == "string" then attribute else part.Name]
	if not def then
		return
	end
	local color = Color3.fromHex(def.placeholder.color)
	local model: Model? = Models.Clone(def, Sightings.Scale)
	local body: Part
	local height: number
	local upright = CFrame.identity
	if model then
		-- The mesh's pivot is its bottom centre; the invisible anchor is as tall as the mesh, centred on it.
		height = Models.Height(model)
		body = newPart(def.id, Enum.PartType.Block, Vector3.one * height, color)
		body.Transparency = 1
		model.Name = def.id .. "Model"
	else
		height = BASE_STUDS * def.placeholder.scale * Sightings.Scale
		body = newPart(def.id, SHAPES[def.placeholder.shape] or Enum.PartType.Ball, Vector3.one * height, color)
		if def.placeholder.shape == "Cylinder" then
			upright = CFrame.Angles(0, 0, math.rad(90)) -- stand it upright, as the other renderers do
		end
	end
	buildPlate(body, def.name, height)
	local feet = feetOf(part)
	local s: Sighting = {
		part = part,
		body = body,
		model = model,
		height = height,
		upright = upright,
		feet = feet,
		turn = CFrame.identity,
		heading = nil,
		lastServer = feet,
		lastPuff = feet,
		placed = false,
		connections = {},
	}
	records[part] = s
	table.insert(s.connections, part.Destroying:Connect(function()
		untrack(part)
	end))
	part.LocalTransparencyModifier = 1 -- the mesh (or placeholder) drawn here replaces the server's ball
	advance(s, 1, 1)
	place(s)
	body.Parent = parent
	if model then
		model.Parent = parent
	end
	local current = Compass.GetTarget()
	if current == nil or current.Parent == nil then
		Compass.SetTarget(part)
	end
end

-- Follows the Sightings folder: every part in it now and every one added or removed later.
local function watch(sightings: Instance)
	for _, child in ipairs(sightings:GetChildren()) do
		track(child)
	end
	sightings.ChildAdded:Connect(track)
	sightings.ChildRemoved:Connect(untrack)
end

-- Public API -------------------------------------------------------------

-- Makes Workspace.ClientSightings and starts drawing the Warden whenever the server has one walking: one
-- RenderStepped connection, then (off the calling thread) a wait for Workspace.World and a watch on its Sightings
-- folder, which may appear at any time, so a client that joins late never blocks on it.
-- Safe to call once; a second call does nothing.
function SightingRenderer.Start()
	if running then
		return
	end
	running = true
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folder = created
	local hex = Sightings.TrailColorByWorld[Place.WorldId()]
	if hex then
		trailColor = Color3.fromHex(hex)
	end
	RunService.RenderStepped:Connect(onRender)
	task.spawn(function()
		local world = Workspace:WaitForChild(WORLD_FOLDER)
		local existing = world:FindFirstChild(SIGHTINGS_FOLDER)
		if existing then
			watch(existing)
		end
		world.ChildAdded:Connect(function(child: Instance)
			if child.Name == SIGHTINGS_FOLDER then
				watch(child)
			end
		end)
	end)
end

return SightingRenderer
