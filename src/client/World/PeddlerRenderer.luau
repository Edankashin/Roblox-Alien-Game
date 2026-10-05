--!strict
-- StarterPlayerScripts.Client.World.PeddlerRenderer: the Peddler's merchant ship, drawn locally under
-- its own client-only folder Workspace.ClientPeddler from the visit the server pushes
-- (PeddlerChanged, mirrored in State) or answers to GetPeddler for a late joiner. Between visits the
-- ship waits invisible Config.PeddlerHoverHeight above its landing spot (Camp.PeddlerOffset, resting
-- on Workspace.World.MeadowFloor). When a visit starts it appears and tweens down over
-- Config.PeddlerDescendSeconds, shows a gold nameplate with the time left, and takes off again when
-- the visit ends. Nothing here decides anything: the visit, its offers and its end time are the
-- server's; this only shows where the ship is so the bootstrap can offer Trade within reach.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Camp = require(Shared:WaitForChild("data"):WaitForChild("Camp"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local State = require(script.Parent.Parent:WaitForChild("State"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Toast = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Toast"))

local PeddlerRenderer = {}

local FOLDER_NAME = "ClientPeddler" -- its own folder: CampRenderer clears every child of ClientCamp when it rebuilds
local PLATE_LIFT = 1.2 -- studs between the top of the hull and its nameplate
local TICK_SECONDS = 1 -- the countdown line and the clock check refresh this often
local TRIM_THICKNESS = 0.4 -- studs; the Neon band around the hull's waist

type Parts = {
	hull: Part,
	trim: Part,
	altitude: NumberValue, -- 0 landed .. 1 hovering; tweened, both parts follow it
	plate: BillboardGui,
	leaves: TextLabel,
}

local localPlayer = Players.LocalPlayer

local parts: Parts? = nil
local flight: Tween? = nil
local floorTop: number? = nil
local landingCentre: Vector3 = Camp.PeddlerOffset
local current: Types.PeddlerVisit? = nil -- the visit in progress, or nil between visits
local shownEndsAt: number? = nil -- the visit the ship has landed (or is landing) for
local running = false

-- Helpers ----------------------------------------------------------------

local function formatTime(seconds: number): string
	if seconds ~= seconds or seconds == math.huge then
		seconds = 0
	end
	local total = math.max(0, math.ceil(seconds))
	if total >= 3600 then
		return Strings.TIME_HM:format(total // 3600, (total % 3600) // 60)
	elseif total >= 60 then
		return Strings.TIME_MS:format(total // 60, total % 60)
	end
	return Strings.TIME_S:format(total)
end

-- Workspace.ClientPeddler, created on first use (client-side only, never replicates).
local function folder(): Folder
	local existing = Workspace:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	return created
end

local function newPart(name: string, size: Vector3, hex: string, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Block
	part.Size = size
	part.Color = Color3.fromHex(hex)
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

-- Places both parts for an altitude between landed (0) and hovering (1).
local function place(built: Parts, progress: number)
	local y = landingCentre.Y + progress * Config.PeddlerHoverHeight
	local cframe = CFrame.new(landingCentre.X, y, landingCentre.Z)
	built.hull.CFrame = cframe
	built.trim.CFrame = cframe
end

local function setHidden(built: Parts, hidden: boolean)
	built.hull.Transparency = if hidden then 1 else 0
	built.trim.Transparency = if hidden then 1 else 0
	built.plate.Enabled = not hidden
end

local function refreshPlate()
	local built = parts
	local visit = current
	if not built or not visit then
		return
	end
	built.leaves.Text = Strings.PEDDLER_LEAVES:format(formatTime(visit.endsAt - State.Now()))
end

-- Flight ---------------------------------------------------------------------

-- Tweens the altitude to `to` over Config.PeddlerDescendSeconds; onDone runs only if it finishes.
local function fly(built: Parts, to: number, direction: Enum.EasingDirection, onDone: () -> ())
	local previous = flight
	if previous then
		previous:Cancel()
	end
	local info = TweenInfo.new(Config.PeddlerDescendSeconds, Enum.EasingStyle.Quad, direction)
	local tween = TweenService:Create(built.altitude, info, { Value = to })
	flight = tween
	tween.Completed:Once(function(state: Enum.PlaybackState)
		if flight == tween then
			flight = nil
		end
		if state == Enum.PlaybackState.Completed then
			onDone()
		end
	end)
	tween:Play()
end

local function land()
	local built = parts
	if not built then
		return -- ensureBuilt lands the ship once the floor is known
	end
	setHidden(built, false)
	built.hull.CanCollide = false
	refreshPlate()
	fly(built, 0, Enum.EasingDirection.Out, function()
		built.hull.CanCollide = true
		built.hull.CanQuery = true
	end)
end

local function takeOff()
	local built = parts
	if not built then
		return
	end
	built.hull.CanCollide = false
	built.hull.CanQuery = false
	built.plate.Enabled = false
	fly(built, 1, Enum.EasingDirection.In, function()
		setHidden(built, true)
	end)
end

-- Build ------------------------------------------------------------------------

local function buildPlate(hull: Part): (BillboardGui, TextLabel)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = hull
	plate.Size = UDim2.fromScale(8, 2.4) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, hull.Size.Y / 2 + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = Strings.PEDDLER_TITLE,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 0.55),
		color = Theme.Colors.Featured,
	})
	local leaves = Builder.label({
		parent = plate,
		name = "Leaves",
		text = "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0, 0.55),
		size = UDim2.fromScale(1, 0.45),
	})
	plate.Enabled = false
	plate.Parent = hull
	return plate, leaves
end

-- Builds the ship once the floor height is known, hovering and hidden; lands it if a visit is on.
local function ensureBuilt()
	local top = floorTop
	if parts or top == nil then
		return
	end
	local parent = folder()
	local size = Camp.PeddlerSize
	landingCentre = Vector3.new(Camp.PeddlerOffset.X, top + Camp.PeddlerOffset.Y + size.Y / 2, Camp.PeddlerOffset.Z)

	local hull = newPart("PeddlerShip", size, Camp.PeddlerColor, parent)
	local trim = newPart("PeddlerTrim", Vector3.new(size.X + TRIM_THICKNESS, TRIM_THICKNESS, size.Z + TRIM_THICKNESS), Camp.PeddlerColor, parent)
	trim.Material = Enum.Material.Neon
	local altitude = Instance.new("NumberValue")
	altitude.Name = "Altitude"
	altitude.Value = 1
	altitude.Parent = hull
	local plate, leaves = buildPlate(hull)
	local built: Parts = { hull = hull, trim = trim, altitude = altitude, plate = plate, leaves = leaves }
	parts = built
	altitude.Changed:Connect(function(value: number)
		place(built, value)
	end)
	place(built, 1)
	setHidden(built, true)
	if current then
		land()
	end
end

-- Visits ---------------------------------------------------------------------------

-- The one code path for a visit, pushed or fetched: a new visit lands the ship (and toasts), the same
-- visit again is kept, nil (or a visit the clock says is over) takes off.
local function apply(visit: Types.PeddlerVisit?)
	if visit and visit.endsAt <= State.Now() then
		visit = nil
	end
	if visit and shownEndsAt == visit.endsAt then
		current = visit
		refreshPlate()
		return
	end
	current = visit
	if visit then
		shownEndsAt = visit.endsAt
		Toast.Banner(Strings.PEDDLER_ARRIVED, Theme.Colors.Featured, Config.AnnounceSeconds) -- an event, so it stays up
		land()
	elseif shownEndsAt ~= nil then
		shownEndsAt = nil
		takeOff()
	end
end

-- Once a second: count the nameplate down, and leave when the clock runs out even before the
-- server's nil push arrives (which then finds nothing left to do).
local function tick()
	local visit = current
	if not visit then
		return
	end
	if visit.endsAt <= State.Now() then
		apply(nil)
		return
	end
	refreshPlate()
end

-- Public API -------------------------------------------------------------

-- Listens for visits, asks the server for one already in progress, and draws the ship once the
-- Meadow floor is in. Returns at once; the waits run in their own threads.
function PeddlerRenderer.Start()
	if running then
		return
	end
	running = true

	State.OnChanged("peddler", function()
		apply(State.GetPeddler())
	end)

	task.spawn(function()
		local world = Workspace:WaitForChild("World")
		local floor = world:WaitForChild("MeadowFloor")
		if not running or not floor:IsA("BasePart") then
			return
		end
		floorTop = floor.Position.Y + floor.Size.Y / 2
		ensureBuilt()
	end)

	-- A late joiner missed the PeddlerChanged push; the answer goes down the same path. A push that
	-- lands first wins, since it is newer.
	task.spawn(function()
		local raw = Net.func("GetPeddler"):InvokeServer()
		local visit = raw :: Types.PeddlerVisit?
		if running and visit and current == nil then
			apply(visit)
		end
	end)

	task.spawn(function()
		while running do
			task.wait(TICK_SECONDS)
			if running then
				tick()
			end
		end
	end)
end

-- World position of the landed ship (its landing spot, whether it is there yet or not).
function PeddlerRenderer.Position(): Vector3
	return landingCentre
end

-- Distance from the local character to the landed ship, or math.huge between visits or without a character.
function PeddlerRenderer.DistanceToShip(): number
	if not current then
		return math.huge
	end
	local character = localPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		return (root.Position - landingCentre).Magnitude
	end
	return math.huge
end

function PeddlerRenderer.IsVisiting(): boolean
	return current ~= nil
end

return PeddlerRenderer
