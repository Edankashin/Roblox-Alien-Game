--!strict
-- ServerScriptService.Server.Services.Sightings: the Warden crossing the map on a fixed server clock (GAME_DESIGN
-- section 12, "Warden sightings"). A sighting starts at every multiple of SightingData.IntervalSeconds of the wall
-- clock (the same epoch as os.time(), shared by every server, like the Meteor Shower in Events) and lasts the
-- path's length divided by SightingData.SpeedStudsPerSecond, so every server in the game walks its Warden at the
-- same moment and the state needs no save: it is a pure function of the time. While one runs this service keeps
-- ONE anchored, non-colliding, non-queryable Part named after the world's Warden species id under
-- Workspace.World.Sightings (next to Wild), with the attributes SpeciesId and Progress (0..1 along the path), and
-- every SightingData.TickSeconds sets its CFrame to the point `elapsed * speed` studs along the path's polyline
-- (interpolated inside a segment, facing the segment's direction), its bottom on the floor (Meadow.GetFloorTop(),
-- no hover). A server that boots or a sighting that is joined mid-interval draws the part from its current point.
-- At the end the part is destroyed. Clients hear SightingChanged (FireAllClients) with a Types.SightingState at
-- every start and end and every SightingData.PushSeconds while one runs, and a late joiner asks GetSighting once.
-- The client only renders: it draws the Warden's mesh on the part with a trail at its feet.
-- Every player online at a start is counted once through Analytics (Events.Sighting, field species).
-- A world that is listed in SightingData.Hidden, has no path in SightingData.Paths, or whose Worlds row names a
-- warden that is not in Species has no sighting at all: the state stays inactive with an empty species.
-- Sightings.Force (Studio commands, guarded by Dev) starts one now (it walks the whole path from the first point
-- and a running one restarts) or ends the running one at once; a forced end or the end of a forced run mutes the
-- clock's own sighting that was in progress, so the Warden never reappears halfway along the path.
--
-- What it never decides: the Warden here cannot be caught, marked or tapped. The part is not a wild spawn and it
-- lives outside the Wild folder on purpose, so the Spawner, Catching, the radar and the tap raycast never see it
-- (the Warden you can catch is the Field Notes finale's, a reserved wild spawn, in Quests and Spawner). Nothing
-- here touches Scrap, a profile or a save.
--
-- Requires run one way: this module requires Meadow (the floor and the World folder), Analytics, Net, Place and
-- shared data only. Nothing here requires Spawner or Catching, and no service requires this one but Dev.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local AnalyticsData = require(Shared.data.Analytics)
local SightingData = require(Shared.data.Sightings)
local Species = require(Shared.data.Species)
local Worlds = require(Shared.data.Worlds)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local Meadow = require(script.Parent.Meadow)
local Analytics = require(script.Parent.Analytics)

local Sightings = {}

local FOLDER_NAME = "Sightings" -- Workspace.World.Sightings, next to Wild
local SNAPSHOT_RATE_PER_SECOND = 2 -- GetSighting calls per player per second
local MILLISECONDS_PER_SECOND = 1000 -- DateTime counts milliseconds; the clock is read in seconds

type Segment = { startAt: number, length: number, ax: number, az: number, dirX: number, dirZ: number }

local worldId = Place.WorldId()
local speciesId: string = Worlds[worldId].warden
local speciesDef: Types.SpeciesDef? = Species.ById[speciesId]

-- The path, measured once: every non-zero segment with its unit direction and the distance walked when it starts.
local segments: { Segment } = {}
local pathLength = 0

local function measurePath()
	local points = SightingData.Paths[worldId]
	if not points then
		return
	end
	for i = 2, #points do
		local a, b = points[i - 1], points[i]
		local dx, dz = b.x - a.x, b.z - a.z
		local length = math.sqrt(dx * dx + dz * dz)
		if length > 0 then
			table.insert(segments, { startAt = pathLength, length = length, ax = a.x, az = a.z, dirX = dx / length, dirZ = dz / length })
			pathLength += length
		end
	end
end
measurePath()

local function isHidden(): boolean
	for _, id in ipairs(SightingData.Hidden) do
		if id == worldId then
			return true
		end
	end
	return false
end

local interval = SightingData.IntervalSeconds
local enabled = speciesDef ~= nil
	and pathLength > 0
	and SightingData.SpeedStudsPerSecond > 0
	and interval > 0
	and not isHidden()
local duration = if enabled then pathLength / SightingData.SpeedStudsPerSecond else 0 -- seconds one sighting lasts

type Run = { key: number, elapsed: number } -- key names the run (its start time) so a restart is told from a continuation

local part: Part? = nil -- the Warden's part while a sighting runs
local activeKey: number? = nil -- the key of the run the part belongs to
local lastPush = 0 -- os.clock() of the last SightingChanged broadcast
local forcedStartedAt: number? = nil -- wall-clock second a forced run began (Sightings.Force); it beats the clock while it runs
local mutedUntil: number? = nil -- wall-clock second until which the clock's own sighting is ignored

-- Clock maths -------------------------------------------------------------
-- The wall clock in seconds with millisecond precision, on the same epoch as os.time(), so the part moves smoothly
-- between whole seconds. phase = seconds since the most recent start (the clock modulo the interval); the sighting
-- is on for the first `duration` seconds of every interval and the next start is interval - phase away.

local function now(): number
	return DateTime.now().UnixTimestampMillis / MILLISECONDS_PER_SECOND
end

-- Ignore the clock's own sighting that is in progress at `t` until it would have ended.
local function muteWindow(t: number)
	local phase = t % interval
	if phase < duration then
		mutedUntil = t + (duration - phase)
	end
end

-- The run in progress at `t` (seconds into it), or nil. A forced run that has run its course is cleared here and
-- swallows the clock's sighting that is in progress, so nothing resumes halfway along the path.
local function currentRun(t: number): Run?
	if not enabled then
		return nil
	end
	local forced = forcedStartedAt
	if forced then
		local elapsed = t - forced
		if elapsed < duration then
			return { key = forced, elapsed = math.max(0, elapsed) }
		end
		forcedStartedAt = nil
		muteWindow(t)
	end
	local phase = t % interval
	if phase >= duration then
		return nil
	end
	local muted = mutedUntil
	if muted and t < muted then
		return nil
	end
	return { key = math.floor(t / interval) * interval, elapsed = phase }
end

local function stateFor(run: Run?, t: number): Types.SightingState
	if not enabled then
		return { active = false, species = "", secondsLeft = 0, nextInSeconds = 0 }
	end
	if run then
		return { active = true, species = speciesId, secondsLeft = math.max(0, math.ceil(duration - run.elapsed)), nextInSeconds = 0 }
	end
	return { active = false, species = speciesId, secondsLeft = 0, nextInSeconds = math.ceil(interval - t % interval) }
end

-- The part ----------------------------------------------------------------

local function sightingsFolder(): Folder
	local world = Workspace:WaitForChild("World")
	local existing = world:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = world
	return created
end

-- The flat point `distance` studs along the path (clamped to its ends) and the unit direction of the segment it is in.
local function pointAt(distance: number): (number, number, number, number)
	local d = math.clamp(distance, 0, pathLength)
	for _, segment in ipairs(segments) do
		if d <= segment.startAt + segment.length then
			local into = d - segment.startAt
			return segment.ax + segment.dirX * into, segment.az + segment.dirZ * into, segment.dirX, segment.dirZ
		end
	end
	local last = segments[#segments]
	return last.ax + last.dirX * last.length, last.az + last.dirZ * last.length, last.dirX, last.dirZ
end

-- Seats `target` at `elapsed` seconds into the walk: on the polyline, facing along its segment, its bottom on the floor.
local function seat(target: Part, elapsed: number)
	local x, z, dirX, dirZ = pointAt(elapsed * SightingData.SpeedStudsPerSecond)
	local position = Vector3.new(x, Meadow.GetFloorTop() + target.Size.Y / 2, z)
	target.CFrame = CFrame.lookAt(position, position + Vector3.new(dirX, 0, dirZ))
	target:SetAttribute("Progress", math.clamp(elapsed / duration, 0, 1))
end

local function createPart(def: Types.SpeciesDef, elapsed: number): Part
	local made = Instance.new("Part")
	made.Name = def.id
	made.Shape = Enum.PartType.Ball
	made.Size = Vector3.one * (def.placeholder.scale * SightingData.Scale)
	made.Color = Color3.fromHex(def.placeholder.color)
	made.Material = Enum.Material.SmoothPlastic
	made.Anchored = true
	made.CanCollide = false
	made.CanTouch = false
	made.CanQuery = false -- not tappable, not hit by the capture raycast
	made.CastShadow = false
	made:SetAttribute("SpeciesId", def.id)
	seat(made, elapsed)
	made.Parent = sightingsFolder()
	return made
end

-- Broadcast and run handling -----------------------------------------------

local function broadcast(state: Types.SightingState)
	Net.event("SightingChanged"):FireAllClients(state)
	lastPush = os.clock()
end

local function begin(run: Run, t: number)
	local def = speciesDef
	if not def then
		return
	end
	activeKey = run.key
	part = createPart(def, run.elapsed)
	local state = stateFor(run, t)
	broadcast(state)
	for _, player in ipairs(Players:GetPlayers()) do
		Analytics.Event(player, AnalyticsData.Events.Sighting, 1, { species = def.id })
	end
	print(("[%s] Sightings: %s crosses world %d now, %ds left (%d studs, every %ss)"):format(
		Config.WorkingTitle,
		def.id,
		worldId,
		state.secondsLeft,
		math.floor(pathLength),
		tostring(interval)
	))
end

local function finish(t: number)
	local walking = part
	if walking then
		walking:Destroy()
	end
	part = nil
	activeKey = nil
	broadcast(stateFor(nil, t))
end

local function tick()
	local t = now()
	local run = currentRun(t)
	local key = activeKey
	if key ~= nil and (run == nil or run.key ~= key) then
		finish(t)
	end
	if run and activeKey == nil then
		begin(run, t)
		return
	end
	local walking = part
	if run and walking then
		seat(walking, run.elapsed)
		if os.clock() - lastPush >= SightingData.PushSeconds then
			broadcast(stateFor(run, t))
		end
	end
end

-- Remotes ----------------------------------------------------------------

-- GetSighting() -> SightingState. The clock for a late joiner; nil only when rate limited.
local function onGetSighting(player: Player): Types.SightingState?
	if not Net.allow(player, "GetSighting", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	local t = now()
	return stateFor(currentRun(t), t)
end

-- Public API -------------------------------------------------------------

-- The sighting clock right now: active, the Warden's species id (empty on a world with no sighting),
-- secondsLeft (0 when not active) and nextInSeconds to the next start (0 while active).
function Sightings.GetState(): Types.SightingState
	local t = now()
	return stateFor(currentRun(t), t)
end

function Sightings.IsActive(): boolean
	return Sightings.GetState().active
end

-- Developer override (Studio commands): true starts a sighting now that walks the whole path from its first point
-- (a running one restarts); false ends the running one at once and mutes the clock's own sighting until the moment
-- it would have ended. Either way the start or end handling runs at once (part, SightingChanged). A world with no
-- sighting ignores both.
function Sightings.Force(active: boolean)
	if not enabled then
		return
	end
	local t = now()
	if active then
		forcedStartedAt = t
	else
		forcedStartedAt = nil
		muteWindow(t)
	end
	tick()
end

function Sightings.Init()
	Net.event("SightingChanged")
	Net.func("GetSighting").OnServerInvoke = onGetSighting
end

function Sightings.Start()
	sightingsFolder() -- Workspace.World exists (Meadow builds it at Init); the folder is ready for the client to wait on
	if not enabled then
		print(("[%s] Sightings: none on world %d (hidden, no path, or no %s species)"):format(Config.WorkingTitle, worldId, speciesId))
		return
	end
	-- A server that boots mid-sighting joins it at once, from its current point; otherwise the loop sees the next start.
	tick()
	task.spawn(function()
		while true do
			task.wait(SightingData.TickSeconds)
			tick()
		end
	end)
	print(("[%s] Sightings: %s walks world %d every %ss for %ds, next start in %ds"):format(
		Config.WorkingTitle,
		speciesId,
		worldId,
		tostring(interval),
		math.ceil(duration),
		math.ceil(interval - now() % interval)
	))
end

return Sightings
