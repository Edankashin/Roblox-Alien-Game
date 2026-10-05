--!strict
-- StarterPlayerScripts.Client.World.CampRenderer: the player's own camp, drawn locally from the profile
-- mirror (State). The server never builds a camp; it only pushes stations, aliens and module progress,
-- and this module turns those into parts under a client-created Workspace.ClientCamp folder (made with
-- Instance.new on the client, so nothing here replicates). Layout numbers come from data.Camp, the
-- camp pad centre is the origin, and everything rests on Workspace.World.MeadowFloor.
--
-- Ship: a landing slab plus one part per module of the current world. Complete modules are solid;
-- the module being built pulses as a ghost; later modules sit as faint ghosts. Completion is judged
-- the same way the Ship screen does, by extrapolating progress with Economy.progressAt, so a module
-- snaps in the moment the clock says it is done, before the server's push arrives.
-- Stations: one block per unlocked job with a nameplate (station name and its Scrap per minute).
-- Imported meshes (Shared/Props, named in Camp.Props): the ship's hull stands on the slab and each
-- station has its own model; the part-built slab and station blocks stay as invisible anchors under them
-- (nameplates, collision and the lift read the parts) and are the visible fallback when a mesh was never
-- imported. The module parts stay placeholders either way: their ghost, pulse and snap-pop visuals are
-- part-based.
-- Workers: a small placeholder per assigned alien in the slot row beside its station, bobbing locally,
-- or the species mesh (World.Models) at Camp.WorkerScale stood on the slot pad when one exists.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Economy = require(Shared:WaitForChild("Economy"))
local Props = require(Shared:WaitForChild("Props"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Camp = require(Shared:WaitForChild("data"):WaitForChild("Camp"))
local Jobs = require(Shared:WaitForChild("data"):WaitForChild("Jobs"))
local Modules = require(Shared:WaitForChild("data"):WaitForChild("Modules"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Models = require(script.Parent:WaitForChild("Models"))

local CampRenderer = {}

local FOLDER_NAME = "ClientCamp"
local REFRESH_SECONDS = 0.5 -- module progress is re-read this often between server pushes
local PLATE_LIFT = 1.2 -- studs between the top of a part (plus its bob) and its nameplate

-- Cylinders point along X. Camp cylinders stand upright like Meadow's trees, except these, which are
-- antennas and keep their axis along X.
local HORIZONTAL_CYLINDERS: { [string]: boolean } = { NavArray = true }

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

type JobDef = { name: string, station: string, verb: string, commonsOnly: boolean, unlockWorld: number }
local jobDefs: { [string]: JobDef } = Jobs.Jobs

type ModuleVisual = "Complete" | "Active" | "Ghost"

type ModuleRecord = {
	id: string,
	part: Part,
	targetSize: Vector3,
	visual: ModuleVisual?, -- nil until the first evaluation
	pulse: Tween?,
}

type StationRecord = {
	job: string,
	part: Part,
	rateLabel: TextLabel,
}

type WorkerRecord = {
	uid: string,
	job: string,
	slot: number,
	species: string,
	part: Part, -- the placeholder, or an invisible anchor as tall as the mesh that carries the plate and the bob
	base: CFrame,
	phase: number,
	model: Model?, -- the mesh clone when the species has one
	modelBase: CFrame?, -- its rest pivot: feet on the slot pad, facing the station
}

local localPlayer = Players.LocalPlayer
local rng = Random.new()

local folder: Folder? = nil
local floorTop: number? = nil
local builtWorld: number? = nil
local shipCentre: Vector3 = Camp.ShipOffset
local modules: { ModuleRecord } = {}
local shipBase: Part? = nil -- the landing slab; the module parts live in `modules`
local liftRest: { [BasePart]: CFrame }? = nil -- where each ship part rested before LiftShip; nil while landed
local liftTweens: { Tween } = {}
local stations: { [string]: StationRecord } = {}
local workers: { [string]: WorkerRecord } = {}
local connections: { RBXScriptConnection } = {}
local running = false

-- Parts -------------------------------------------------------------------

local function newPart(name: string, shape: Enum.PartType, size: Vector3, cframe: CFrame, hex: string, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = Color3.fromHex(hex)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Size and rotation for a placeholder so its world extents match the data's (width, height, depth).
-- An upright cylinder swaps X and Y and rolls 90 degrees, the way Meadow stands its trunks up.
local function orient(id: string, shape: string, size: Vector3): (Vector3, CFrame)
	if shape == "Cylinder" and not HORIZONTAL_CYLINDERS[id] then
		return Vector3.new(size.Y, size.X, size.Z), CFrame.Angles(0, 0, math.rad(90))
	end
	return size, CFrame.identity
end

local function groundY(): number
	return floorTop or 0
end

-- Nameplates ---------------------------------------------------------------

-- A two-line plate above a part, built with Builder so it is Fredoka One, outlined and Scale-only.
-- Returns the plate and the second line so callers can update or hide it.
local function buildPlate(part: Part, lift: number, line1: string, line2: string, line2Color: Color3): (BillboardGui, TextLabel)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(7, 2) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + lift + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = line1,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 0.55),
	})
	local second = Builder.label({
		parent = plate,
		name = "Detail",
		text = line2,
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0, 0.55),
		size = UDim2.fromScale(1, 0.45),
		color = line2Color,
	})
	plate.Parent = part
	return plate, second
end

-- Ship -----------------------------------------------------------------------

local function stopPulse(record: ModuleRecord)
	local pulse = record.pulse
	if pulse then
		pulse:Cancel()
		record.pulse = nil
	end
end

local function snapIn(record: ModuleRecord)
	record.part.Size = record.targetSize * Camp.SnapPopScale
	TweenService:Create(
		record.part,
		TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = record.targetSize }
	):Play()
end

local function applyVisual(record: ModuleRecord, visual: ModuleVisual)
	local previous = record.visual
	if previous == visual then
		return
	end
	record.visual = visual
	stopPulse(record)
	local part = record.part
	if visual == "Complete" then
		part.Transparency = 0
		part.CanCollide = true
		part.CanQuery = true
		if previous ~= nil then
			snapIn(record)
		end
	elseif visual == "Active" then
		part.CanCollide = false
		part.CanQuery = false
		part.Transparency = Camp.GhostTransparency
		local pulse = TweenService:Create(
			part,
			TweenInfo.new(Camp.ActivePulseSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.5 }
		)
		record.pulse = pulse
		pulse:Play()
	else
		part.CanCollide = false
		part.CanQuery = false
		part.Transparency = Camp.GhostTransparency
	end
end

-- Progress as the Ship screen shows it: the server's last write extrapolated at the pushed assembly speed.
local function visuallyComplete(profile: Types.Profile, world: number, def: Modules.ModuleDef): boolean
	local state = Economy.moduleState(profile, world, def.id)
	if not state then
		return false
	end
	if Economy.isComplete(state) then
		return true
	end
	local speed = State.GetRate().assemblySpeed[def.job] or Config.AssemblyPlayerSpeed
	return Economy.progressAt(def, state, speed, State.Now()) >= 1
end

local function refreshModules()
	if not State.Has() or builtWorld == nil then
		return
	end
	local profile = State.Get()
	local world = builtWorld
	local activeSeen = false
	for _, record in ipairs(modules) do
		local def = Economy.moduleDef(world, record.id)
		if not def then
			continue
		end
		if visuallyComplete(profile, world, def) then
			applyVisual(record, "Complete")
		elseif not activeSeen then
			activeSeen = true
			applyVisual(record, "Active")
		else
			applyVisual(record, "Ghost")
		end
	end
end

local function buildShip(parent: Folder, world: number)
	local base = Camp.ShipBaseSize
	local baseCentre = Vector3.new(Camp.ShipOffset.X, groundY() + Camp.ShipOffset.Y + base.Y / 2, Camp.ShipOffset.Z)
	shipCentre = baseCentre
	local slab = newPart("ShipBase", Enum.PartType.Block, base, CFrame.new(baseCentre), Camp.ShipBaseColor, parent)
	shipBase = slab
	-- The imported hull stands on the ground under the slab's centre; the slab stays as its invisible anchor.
	-- Modules stay placeholder parts below (their ghost and snap visuals are part-based).
	if Props.Place(Camp.Props.ship, CFrame.new(baseCentre.X, baseCentre.Y - base.Y / 2, baseCentre.Z), 1, slab, true) then
		slab.Transparency = 1
	end
	local baseTop = baseCentre + Vector3.new(0, base.Y / 2, 0)

	for _, def in ipairs(Economy.moduleDefs(world)) do
		local layout = Camp.Modules[def.id]
		if not layout then
			continue
		end
		local size, rotation = orient(def.id, layout.shape, layout.size)
		local part = newPart(def.id, SHAPES[layout.shape] or Enum.PartType.Block, size, CFrame.new(baseTop + layout.offset) * rotation, layout.color, parent)
		part.Transparency = Camp.GhostTransparency
		part.CanCollide = false
		part.CanQuery = false
		table.insert(modules, { id = def.id, part = part, targetSize = size, visual = nil, pulse = nil })
	end
end

-- Lift-off ----------------------------------------------------------------------
-- The launch sequence raises the whole ship (the slab and every module part) and puts it back. The
-- rest CFrames are remembered on the first lift so a reset lands exactly where buildShip put them.

local function shipParts(): { BasePart }
	local parts: { BasePart } = {}
	local base = shipBase
	if base and base.Parent then
		table.insert(parts, base)
		-- the imported hull's meshes ride with the slab
		for _, descendant in ipairs(base:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
	end
	for _, record in ipairs(modules) do
		if record.part.Parent then
			table.insert(parts, record.part)
		end
	end
	return parts
end

local function cancelLift()
	for _, tween in ipairs(liftTweens) do
		tween:Cancel()
	end
	liftTweens = {}
end

-- Stations ---------------------------------------------------------------------

local function rateText(profile: Types.Profile, job: string): string
	local perMinute = Economy.stationRate(profile, job) * 60
	if perMinute <= 0 then
		return ""
	end
	return Builder.text("HUD_SCRAP_PER_MIN"):format(Builder.formatNumber(perMinute))
end

local function refreshStationRates()
	if not State.Has() then
		return
	end
	local profile = State.Get()
	for job, record in pairs(stations) do
		local text = rateText(profile, job)
		record.rateLabel.Text = text
		record.rateLabel.Visible = text ~= ""
	end
end

local function buildStations(parent: Folder, world: number)
	for _, job in ipairs(Jobs.Order) do
		local jobDef = jobDefs[job]
		local layout = Camp.Stations[job]
		if not jobDef or not layout or jobDef.unlockWorld > world then
			continue
		end
		local centre = Vector3.new(layout.offset.X, groundY() + layout.offset.Y + layout.size.Y / 2, layout.offset.Z)
		local part = newPart(job .. "Station", Enum.PartType.Block, layout.size, CFrame.new(centre), layout.color, parent)
		part.CanCollide = true
		if job == "Spark" then
			part.Material = Enum.Material.Neon -- the Glow Flower glows
		end
		-- The imported model stands on the ground under the block's centre; the block stays as its invisible
		-- anchor (collision and nameplate), and is the visible placeholder when the mesh was never imported.
		local propName = Camp.Props.stations[job]
		if propName and Props.Place(propName, CFrame.new(centre.X, centre.Y - layout.size.Y / 2, centre.Z), 1, part, false) then
			part.Transparency = 1
		end
		local _, rateLabel = buildPlate(part, 0, Builder.text("STATION_" .. job), "", Theme.Colors.Featured)
		rateLabel.Visible = false
		stations[job] = { job = job, part = part, rateLabel = rateLabel }
	end
	refreshStationRates()
end

-- Workers ----------------------------------------------------------------------

local function removeWorker(uid: string)
	local record = workers[uid]
	if record then
		workers[uid] = nil
		record.part:Destroy()
		local model = record.model
		if model then
			model:Destroy()
		end
	end
end

local function addWorker(parent: Folder, uid: string, record: Types.AlienRecord, job: string, slot: number)
	local layout = Camp.Stations[job]
	local def = Species.ById[record.species]
	if not layout or not def then
		return
	end
	local along = Camp.SlotOffsetFromStation + (slot - 1) * Camp.SlotSpacing
	local at = layout.offset + layout.slotDirection * along
	local feet = Vector3.new(at.X, groundY(), at.Z) -- the slot pad; the placeholder's bottom rests here
	local part: Part
	local base: CFrame
	local model: Model? = Models.Clone(def, Config.ModelWorkerScale * Camp.WorkerScale)
	local modelBase: CFrame? = nil
	if model then
		-- The mesh stands on the pad facing its station. An invisible anchor part as tall as the mesh
		-- carries the nameplate and the bob exactly as the placeholder part does.
		local height = Models.Height(model)
		base = CFrame.new(feet + Vector3.new(0, height / 2, 0))
		part = newPart(uid, Enum.PartType.Block, Vector3.one * height, base, def.placeholder.color, parent)
		part.Transparency = 1
		local facing = CFrame.lookAt(feet, feet - layout.slotDirection)
		model:PivotTo(facing)
		model.Name = uid .. "Model"
		model.Parent = parent
		modelBase = facing
	else
		local size = 2 * def.placeholder.scale * Camp.WorkerScale
		base = CFrame.new(feet + Vector3.new(0, size / 2, 0))
		if def.placeholder.shape == "Cylinder" then
			base = base * CFrame.Angles(0, 0, math.rad(90)) -- stand it upright
		end
		part = newPart(uid, SHAPES[def.placeholder.shape] or Enum.PartType.Ball, Vector3.one * size, base, def.placeholder.color, parent)
	end
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	buildPlate(part, Camp.WorkerBobStuds, def.name, Builder.text("TIER_" .. def.tier), Builder.tierColor(def.tier))
	workers[uid] = {
		uid = uid,
		job = job,
		slot = slot,
		species = record.species,
		part = part,
		base = base,
		phase = rng:NextNumber(0, math.pi * 2),
		model = model,
		modelBase = modelBase,
	}
end

-- Workers that still stand where the profile says keep their part (and their bob phase); the rest
-- are rebuilt.
local function refreshWorkers()
	local parent = folder
	if not parent or not State.Has() or builtWorld == nil then
		return
	end
	local profile = State.Get()
	local wanted: { [string]: boolean } = {}
	for job in pairs(stations) do
		local station = profile.stations[job]
		if not station then
			continue
		end
		for slot, uid in ipairs(station.assigned) do
			local record = profile.aliens[uid]
			if not record then
				continue
			end
			wanted[uid] = true
			local existing: WorkerRecord? = workers[uid]
			if existing and (existing.job ~= job or existing.slot ~= slot or existing.species ~= record.species) then
				removeWorker(uid)
				existing = nil
			end
			if not existing then
				addWorker(parent, uid, record, job, slot)
			end
		end
	end
	for uid in pairs(workers) do
		if not wanted[uid] then
			removeWorker(uid)
		end
	end
end

local function onRender()
	local now = os.clock()
	local omega = math.pi * 2 * Camp.WorkerBobHz
	for _, record in pairs(workers) do
		local lift = Vector3.new(0, math.sin(now * omega + record.phase) * Camp.WorkerBobStuds, 0)
		record.part.CFrame = record.base + lift
		local model, modelBase = record.model, record.modelBase
		if model and modelBase then
			model:PivotTo(modelBase + lift)
		end
	end
end

-- Lifecycle --------------------------------------------------------------------

local function teardownCamp()
	cancelLift()
	liftRest = nil
	shipBase = nil
	for _, record in ipairs(modules) do
		stopPulse(record)
	end
	modules = {}
	stations = {}
	workers = {}
	builtWorld = nil
	local existing = folder
	if existing then
		existing:ClearAllChildren()
	end
end

-- Builds the whole camp for the profile's current world, replacing any earlier build of another world.
local function ensureBuilt()
	local parent = folder
	if not parent or floorTop == nil or not State.Has() then
		return
	end
	local world = State.Get().world.current
	if builtWorld == world then
		return
	end
	teardownCamp()
	builtWorld = world
	buildShip(parent, world)
	buildStations(parent, world)
	refreshModules()
	refreshWorkers()
end

local function onModulesChanged()
	ensureBuilt()
	refreshModules()
end

local function onStationsChanged()
	ensureBuilt()
	refreshStationRates()
	refreshWorkers()
end

-- Public API -------------------------------------------------------------

-- Creates Workspace.ClientCamp and draws the camp once the floor and the profile are both known.
-- Returns at once; the floor wait runs in its own thread.
function CampRenderer.Start()
	if running then
		return
	end
	running = true

	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	folder = created

	table.insert(connections, State.OnChanged("modules", onModulesChanged))
	table.insert(connections, State.OnChanged("stations", onStationsChanged))
	table.insert(connections, State.OnChanged("rate", refreshModules))
	table.insert(connections, RunService.RenderStepped:Connect(onRender))

	task.spawn(function()
		local world = Workspace:WaitForChild("World")
		local floor = world:WaitForChild("MeadowFloor")
		if not running or not floor:IsA("BasePart") then
			return
		end
		floorTop = floor.Position.Y + floor.Size.Y / 2
		ensureBuilt()
		-- Assembly keeps running between pushes, so poll the clock for modules that finish quietly.
		while running do
			task.wait(REFRESH_SECONDS)
			if running then
				refreshModules()
			end
		end
	end)
end

-- World position of the ship (the centre of its landing slab), for the Build button's distance check.
function CampRenderer.ShipPosition(): Vector3
	return shipCentre
end

-- Raises every ship part (the slab and the module parts) by `studs` over `seconds`, Quad In, so the
-- take-off starts slow and leaves fast. onDone runs when the lift ends (at once with no ship built;
-- also when a rebuild cancels it, so a sequence never stalls). A lift while already lifted restarts
-- from the remembered rest frames; ResetShip puts the ship back.
function CampRenderer.LiftShip(studs: number, seconds: number, onDone: (() -> ())?)
	cancelLift()
	local rest = liftRest or {}
	liftRest = rest
	local parts = shipParts()
	if #parts == 0 then
		if onDone then
			task.spawn(onDone)
		end
		return
	end
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local lift = Vector3.new(0, studs, 0)
	local first: Tween? = nil
	for _, part in ipairs(parts) do
		local from = rest[part] or part.CFrame
		rest[part] = from
		part.CFrame = from
		local tween = TweenService:Create(part, info, { CFrame = from + lift })
		table.insert(liftTweens, tween)
		tween:Play()
		if not first then
			first = tween
		end
	end
	if first and onDone then
		-- Every tween shares the duration, so the first one's end is the lift's end, cancelled or not.
		first.Completed:Connect(function()
			onDone()
		end)
	end
end

-- Stops any lift and puts every ship part back on its rest CFrame. Nothing to do while landed.
function CampRenderer.ResetShip()
	cancelLift()
	local rest = liftRest
	liftRest = nil
	if not rest then
		return
	end
	for part, cframe in pairs(rest) do
		if part.Parent then
			part.CFrame = cframe
		end
	end
end

-- Distance from the local character to the ship, or math.huge without a character.
function CampRenderer.DistanceToShip(): number
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		return (root.Position - shipCentre).Magnitude
	end
	return math.huge
end

function CampRenderer.Stop()
	if not running then
		return
	end
	running = false
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	teardownCamp()
	floorTop = nil
	local existing = folder
	folder = nil
	if existing then
		existing:Destroy()
	end
end

return CampRenderer
