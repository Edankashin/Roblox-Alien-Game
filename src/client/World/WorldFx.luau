--!strict
-- StarterPlayerScripts.Client.World.WorldFx: the ambient effects that live at places in a generated world (World 1: mist at the
-- waterfall, sparkle on the pond, falling petals in the grove and by the shrine, fireflies by night, block butterflies over the meadow
-- by day, glints in the crystal grotto, light shafts in the cave; World 2: mist over the frozen lake, ice glints, steam off the hot
-- spring and the geysers, aurora ribbons in the night sky), and the slow drift of the water tile over the generated water and
-- waterfalls. Where each stands is the world's rows (Shared/WorldGrid, data/WorldGen<id> Fx); how it looks is data/WorldFx by kind.
-- Everything is created on the client under a client-only Workspace.WorldFx folder (nothing replicates) and is pure presentation.
-- Phone budget: every WorldFx.CheckSeconds the MaxActive nearest particle or butterfly places within ActiveRadius of the camera run
-- and the rest ramp off (all of them while a heavy weather in WorldFx.PauseIn runs); shafts and ribbons are single Beams, shown or hidden by day and night. Reduced Motion (Prefs): no particles,
-- no butterflies, no drifting water; the shafts and a still aurora stay. A world with no generated ground does nothing.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FxData = require(Shared:WaitForChild("data"):WaitForChild("WorldFx"))
local BlockTiles = require(Shared:WaitForChild("data"):WaitForChild("BlockTiles"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Place = require(Shared:WaitForChild("Place"))
local WorldGrid = require(Shared:WaitForChild("WorldGrid"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Theme = require(Shared:WaitForChild("Theme"))
local LightingData = require(Shared:WaitForChild("data"):WaitForChild("Lighting"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Prefs = require(script.Parent.Parent:WaitForChild("Prefs"))

local WorldFx = {}

local FOLDER_NAME = "WorldFx"

type Fly = { body: Part, left: Part, right: Part, phase: number, radius: number, lift: number, color: Color3 }
type Entry = {
	spot: Types.WorldFxSpot,
	row: FxData.Row,
	position: Vector3,
	part: Part?, -- the emitter's box, or the beam's anchor
	emitter: ParticleEmitter?,
	beam: Beam?,
	flies: { Fly },
	active: boolean,
}

local started = false
local entries: { Entry } = {}
local folderInstance: Folder? = nil
local floorTop = 0
local waterDrift = 0 -- studs the water tile has slid
local fallDrift = 0

local function folder(): Folder
	local existing = folderInstance
	if existing and existing.Parent then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folderInstance = created
	return created
end

local function invisiblePart(name: string, size: Vector3, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder()
	return part
end

local function vec(values: { number }): Vector3
	return Vector3.new(values[1] or 0, values[2] or 0, values[3] or 0)
end

local function colorSequence(hexes: { string }): ColorSequence
	if #hexes <= 1 then
		return ColorSequence.new(Theme.Hex(hexes[1] or "FFFFFF"))
	end
	return ColorSequence.new(Theme.Hex(hexes[1]), Theme.Hex(hexes[#hexes]))
end

-- Whether a row's time of day holds now at a place: a place inside a biome that is night at any hour (data/Lighting BiomeAlways, the
-- Starhollow Forest) counts as night there.
local function timeFits(when: FxData.When, position: Vector3): boolean
	if when == "always" then
		return true
	end
	local night = State.GetClock().isNight or LightingData.BiomeAlways[Biomes.At(position)] == "Night"
	return if when == "night" then night else not night
end

local function buildEmitter(entry: Entry, row: FxData.Particles)
	local size = entry.spot.size
	local part = invisiblePart(entry.spot.kind, vec(row.box) * size + Vector3.new(0.1, 0.1, 0.1), entry.position)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(row.lifetime[1], row.lifetime[2])
	emitter.Speed = NumberRange.new(row.speed[1], row.speed[2])
	emitter.Size = NumberSequence.new(row.sizeStart, row.sizeEnd)
	emitter.Color = colorSequence(row.color)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, row.transparency),
		NumberSequenceKeypoint.new(0.7, row.transparency),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = row.lightEmission
	emitter.SpreadAngle = Vector2.new(row.spread, row.spread)
	emitter.Acceleration = vec(row.acceleration)
	emitter.Drag = row.drag
	emitter.RotSpeed = NumberRange.new(row.rotation[1], row.rotation[2])
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.EmissionDirection = Enum.NormalId.Top
	if row.texture ~= 0 then
		emitter.Texture = "rbxassetid://" .. tostring(row.texture)
	end
	local direction = vec(row.direction)
	if direction.Magnitude > 1e-3 and math.abs(direction.Unit.Y) < 0.999 then
		-- turn the box so its Top face points along the row's direction
		local up = direction.Unit
		local right = up:Cross(Vector3.zAxis)
		part.CFrame = CFrame.fromMatrix(entry.position, right.Unit, up)
	elseif direction.Y < 0 then
		part.CFrame = CFrame.new(entry.position) * CFrame.Angles(math.pi, 0, 0)
	end
	emitter.Parent = part
	entry.part = part
	entry.emitter = emitter
end

local function buildFlies(entry: Entry, row: FxData.Butterflies)
	for index = 1, row.count do
		local color = Theme.Hex(row.colors[(index - 1) % #row.colors + 1])
		local function block(name: string, size: { number }, tint: Color3): Part
			local part = invisiblePart(name, vec(size), entry.position)
			part.Transparency = 1
			part.Color = tint
			part.Material = Enum.Material.SmoothPlastic
			return part
		end
		table.insert(entry.flies, {
			body = block("Butterfly", row.body, Theme.Hex(row.bodyColor)),
			left = block("Wing", row.wing, color),
			right = block("Wing", row.wing, color),
			phase = (index - 1) / row.count,
			radius = entry.spot.size * (0.25 + 0.5 * ((index * 37) % 10) / 10),
			lift = row.height[1] + (row.height[2] - row.height[1]) * ((index * 53) % 10) / 10,
			color = color,
		})
	end
end

local function buildShaft(entry: Entry, row: FxData.Shaft)
	local top = invisiblePart("Shaft", Vector3.one, entry.position + Vector3.new(0, row.height, 0))
	local a0 = Instance.new("Attachment")
	a0.Parent = top
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -row.height, 0)
	a1.Parent = top
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = entry.spot.size * row.width
	beam.Width1 = entry.spot.size * row.width * 1.4
	beam.Color = ColorSequence.new(Theme.Hex(row.color))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, row.transparency), NumberSequenceKeypoint.new(1, row.endTransparency) })
	beam.LightEmission = row.lightEmission
	beam.FaceCamera = true
	beam.Segments = 2
	beam.Enabled = false
	beam.Parent = top
	entry.part = top
	entry.beam = beam
end

local function buildRibbons(entry: Entry, row: FxData.Ribbon)
	local anchor = invisiblePart("Aurora", Vector3.one, entry.position)
	local span = entry.spot.size
	for index = 1, row.count do
		local offset = (index - (row.count + 1) / 2) * row.width * 0.9
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(-span / 2, offset * 0.4, offset)
		a0.Parent = anchor
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(span / 2, -offset * 0.3, offset * 0.6)
		a1.Parent = anchor
		local beam = Instance.new("Beam")
		beam.Name = "Ribbon" .. index
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = row.width
		beam.Width1 = row.width * 0.7
		beam.Color = colorSequence({ row.colors[(index - 1) % #row.colors + 1], row.colors[index % #row.colors + 1] })
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, row.transparency),
			NumberSequenceKeypoint.new(0.75, row.transparency),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.LightEmission = row.lightEmission
		beam.CurveSize0 = row.sway
		beam.CurveSize1 = -row.sway
		beam.Segments = 24
		beam.Enabled = false
		beam.Parent = anchor
		if index == 1 then
			entry.beam = beam
		end
	end
	entry.part = anchor
end

local function setRate(entry: Entry, on: boolean)
	local emitter = entry.emitter
	if emitter == nil then
		return
	end
	local row = entry.row
	if row.sort ~= "particles" then
		return
	end
	TweenService:Create(emitter, TweenInfo.new(FxData.FadeSeconds, Enum.EasingStyle.Linear), { Rate = if on then row.rate else 0 }):Play()
end

local function setFlies(entry: Entry, on: boolean)
	for _, fly in ipairs(entry.flies) do
		local transparency = if on then 0 else 1
		fly.body.Transparency = transparency
		fly.left.Transparency = transparency
		fly.right.Transparency = transparency
	end
end

-- Re-picks the running places: the MaxActive nearest particle or butterfly places within ActiveRadius whose time fits (none under
-- Reduced Motion), and shows each beam whose time fits.
local function refresh()
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local eye = camera.CFrame.Position
	local reduced = Prefs.ReducedMotion() or FxData.PauseIn[State.GetClock().weather] == true
	local candidates: { Entry } = {}
	for _, entry in ipairs(entries) do
		local row = entry.row
		if row.sort == "shaft" or row.sort == "ribbon" then
			local show = timeFits(row.when, entry.position)
			local anchor = entry.part
			if anchor then
				for _, child in ipairs(anchor:GetChildren()) do
					if child:IsA("Beam") then
						child.Enabled = show
					end
				end
			end
		elseif not reduced and timeFits(row.when, entry.position) and (entry.position - eye).Magnitude <= FxData.ActiveRadius then
			table.insert(candidates, entry)
		end
	end
	table.sort(candidates, function(a: Entry, b: Entry): boolean
		return (a.position - eye).Magnitude < (b.position - eye).Magnitude
	end)
	local wanted: { [Entry]: boolean } = {}
	for index = 1, math.min(FxData.MaxActive, #candidates) do
		wanted[candidates[index]] = true
	end
	for _, entry in ipairs(entries) do
		local on = wanted[entry] == true
		if on ~= entry.active then
			entry.active = on
			if entry.row.sort == "particles" then
				setRate(entry, on)
			elseif entry.row.sort == "butterflies" then
				setFlies(entry, on)
			end
		end
	end
end

-- Per frame: the running butterflies flutter, the aurora sways, the water tile drifts (all skipped under Reduced Motion).
local function step(dt: number)
	if Prefs.ReducedMotion() then
		return
	end
	local now = os.clock()
	for _, entry in ipairs(entries) do
		local row = entry.row
		if entry.active and row.sort == "butterflies" then
			for _, fly in ipairs(entry.flies) do
				local t = (now / row.loopSeconds + fly.phase) * math.pi * 2
				local x = entry.position.X + math.cos(t) * fly.radius
				local z = entry.position.Z + math.sin(t * 2) * fly.radius * 0.5
				local y = entry.position.Y + fly.lift + math.sin(t * 3) * 0.6
				local heading = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x - math.sin(t), y, z + math.cos(t * 2)))
				local flap = math.sin(now / row.flapSeconds * math.pi * 2) * 0.9
				fly.body.CFrame = heading
				local half = fly.left.Size.X / 2
				fly.left.CFrame = heading * CFrame.Angles(0, 0, flap) * CFrame.new(-half, 0, 0)
				fly.right.CFrame = heading * CFrame.Angles(0, 0, -flap) * CFrame.new(half, 0, 0)
			end
		elseif row.sort == "ribbon" and entry.part then
			local swing = math.sin(now / row.swaySeconds * math.pi * 2)
			for _, child in ipairs((entry.part :: Part):GetChildren()) do
				if child:IsA("Beam") and child.Enabled then
					child.CurveSize0 = row.sway * swing
					child.CurveSize1 = -row.sway * swing * 0.7
				end
			end
		end
	end
	if BlockTiles.Ids.Water.id ~= 0 or BlockTiles.Ids.GlowWater.id ~= 0 then
		waterDrift = (waterDrift + dt * BlockTiles.WaterDrift) % BlockTiles.StudsPerTile
		fallDrift = (fallDrift + dt * BlockTiles.FallDrift) % BlockTiles.StudsPerTile
		for _, part in ipairs(CollectionService:GetTagged(BlockTiles.WaterTag)) do
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Texture") then
					child.OffsetStudsU = waterDrift
					child.OffsetStudsV = waterDrift * 0.5
				end
			end
		end
		for _, part in ipairs(CollectionService:GetTagged(BlockTiles.FallTag)) do
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Texture") then
					child.OffsetStudsV = -fallDrift
				end
			end
		end
	end
end

function WorldFx.Start()
	if started then
		return
	end
	started = true
	local grid = WorldGrid.For(Place.WorldId())
	if grid == nil then
		return
	end
	floorTop = Place.Layout().FloorThickness / 2
	for _, spot in ipairs(grid.gen.Fx) do
		local row = FxData.Kinds[spot.kind]
		if row then
			local entry: Entry = {
				spot = spot,
				row = row,
				position = Vector3.new(spot.x, floorTop + spot.y, spot.z),
				part = nil,
				emitter = nil,
				beam = nil,
				flies = {},
				active = false,
			}
			if row.sort == "particles" then
				buildEmitter(entry, row)
			elseif row.sort == "butterflies" then
				buildFlies(entry, row)
			elseif row.sort == "shaft" then
				buildShaft(entry, row)
			elseif row.sort == "ribbon" then
				buildRibbons(entry, row)
			end
			table.insert(entries, entry)
		else
			warn(("WorldFx: no data/WorldFx row for kind %s"):format(spot.kind))
		end
	end
	State.OnChanged("clock", refresh)
	refresh()
	task.spawn(function()
		while true do
			task.wait(FxData.CheckSeconds)
			refresh()
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return WorldFx
