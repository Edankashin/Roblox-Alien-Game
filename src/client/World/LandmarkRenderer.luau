--!strict
-- StarterPlayerScripts.Client.World.LandmarkRenderer: nameplates for the world's landmarks under
-- Workspace.World.Landmarks (World 1: the Shrine of Gaira, where the Field Notes finale sounds the
-- horn; the Crash Site; the Cave Entrance). The server builds each landmark as a Model whose PrimaryPart
-- carries the string attribute LandmarkId; this module adds a gold nameplate above that part (the name,
-- LANDMARK_<id>, visible within NameplateDistance) with a white legend line under it that says what the
-- place is for (LANDMARK_LEGEND_<id>, within data/Landmarks LegendStuds; playtest 1, 2026-11-05: the
-- plates were names with nothing to tap and nothing explained), and answers where each landmark is, so
-- the bootstrap can offer "Sound the horn" within ShrineInteractDistance and, at a landmark with a screen
-- behind it (data/Landmarks `opens`), that screen from LookDistance. A world may rename a landmark
-- (data/Landmarks ByWorld: World 2's shrine is Skadra's). Nothing here decides anything: the horn tap and
-- the screen open ask the server or the UI.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Landmarks = require(Shared:WaitForChild("data"):WaitForChild("Landmarks"))
local Place = require(Shared:WaitForChild("Place"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local LandmarkRenderer = {}

local FOLDER_NAME = "Landmarks"

type Record = { id: string, model: Model, part: BasePart, plate: BillboardGui, legend: TextLabel }

local records: { [string]: Record } = {} -- by landmark id
local byModel: { [Model]: string } = {}
local waiting: { [Model]: RBXScriptConnection } = {} -- models whose PrimaryPart or id has not replicated yet
local folderConns: { RBXScriptConnection } = {}
local running = false
local localPlayer = Players.LocalPlayer

local function rootPosition(): Vector3?
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- The data row for a landmark id in this world (the world's own row first, then the shared one), or nil for an id the data
-- does not know: such a landmark gets its name and no legend.
local function entryFor(id: string): Landmarks.Entry?
	local world = Landmarks.ByWorld[Place.WorldId()]
	local own = if world then world[id] else nil
	return own or Landmarks.ById[id]
end

local function nameKey(id: string): string
	local entry = entryFor(id)
	return if entry and entry.name then entry.name else "LANDMARK_" .. id
end

local function buildPlate(part: BasePart, id: string): (BillboardGui, TextLabel)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(Landmarks.PlateStuds.width, Landmarks.PlateStuds.height) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + Landmarks.LiftStuds, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = true -- a landmark is a destination; it must read through the stones
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = Builder.text(nameKey(id)),
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0, 0),
		size = UDim2.fromScale(1, Landmarks.NameShare),
	})
	local entry = entryFor(id)
	local legend = Builder.label({
		parent = plate,
		name = "Legend",
		text = if entry then Builder.text(entry.legend) else "",
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0, Landmarks.NameShare),
		size = UDim2.fromScale(1, 1 - Landmarks.NameShare),
	})
	legend.TextWrapped = true
	legend.Visible = false -- within LegendStuds (the poll)
	plate.Parent = part
	return plate, legend
end

local function stopWaiting(model: Model)
	local connection = waiting[model]
	if connection then
		connection:Disconnect()
		waiting[model] = nil
	end
end

local track: (Instance) -> ()

-- A Model can replicate before its PrimaryPart or attributes do: wait for the missing piece once.
local function waitFor(model: Model, signal: RBXScriptSignal)
	if waiting[model] then
		return
	end
	waiting[model] = signal:Connect(function()
		stopWaiting(model)
		track(model)
	end)
end

function track(instance: Instance)
	if not instance:IsA("Model") or byModel[instance] then
		return
	end
	local primary = instance.PrimaryPart
	if not primary then
		waitFor(instance, instance:GetPropertyChangedSignal("PrimaryPart"))
		return
	end
	local id = primary:GetAttribute("LandmarkId")
	if type(id) ~= "string" then
		waitFor(instance, primary:GetAttributeChangedSignal("LandmarkId"))
		return
	end
	stopWaiting(instance)
	if records[id] then
		return -- a duplicate id: the first model keeps the name
	end
	local plate, legend = buildPlate(primary, id)
	records[id] = { id = id, model = instance, part = primary, plate = plate, legend = legend }
	byModel[instance] = id
end

local function untrack(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	stopWaiting(instance)
	local id = byModel[instance]
	if not id then
		return
	end
	byModel[instance] = nil
	local record = records[id]
	if record then
		records[id] = nil
		if record.plate.Parent then
			record.plate:Destroy()
		end
	end
end

-- The legend shows within LegendStuds of the landmark and hides farther away (the name alone reads from NameplateDistance).
local function refreshLegends()
	local at = rootPosition()
	for _, record in pairs(records) do
		local near = false
		if at and record.part.Parent and record.legend.Text ~= "" then
			near = (record.part.Position - at).Magnitude <= Landmarks.LegendStuds
		end
		if record.legend.Visible ~= near then
			record.legend.Visible = near
		end
	end
end

-- Public API -------------------------------------------------------------

-- Watches Workspace.World.Landmarks. Returns at once; if the folder never appears nothing is drawn.
function LandmarkRenderer.Start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		local world = Workspace:WaitForChild("World")
		local landmarks = world:WaitForChild(FOLDER_NAME)
		if not running then
			return
		end
		for _, child in ipairs(landmarks:GetChildren()) do
			track(child)
		end
		table.insert(folderConns, landmarks.ChildAdded:Connect(track))
		table.insert(folderConns, landmarks.ChildRemoved:Connect(untrack))
		while running do
			refreshLegends()
			task.wait(Landmarks.PollSeconds)
		end
	end)
end

-- Where a landmark's primary part is, or nil while it is unknown.
function LandmarkRenderer.Position(id: string): Vector3?
	local record = records[id]
	if record and record.part.Parent then
		return record.part.Position
	end
	return nil
end

-- Studs from the player to a landmark; math.huge when either is unknown.
function LandmarkRenderer.DistanceTo(id: string): number
	local at = rootPosition()
	local target = LandmarkRenderer.Position(id)
	if not at or not target then
		return math.huge
	end
	return (target - at).Magnitude
end

-- The UI/Screens name a landmark opens from the action button (data/Landmarks `opens`), or nil for a plate alone.
function LandmarkRenderer.Opens(id: string): string?
	local entry = entryFor(id)
	return if entry then entry.opens else nil
end

-- The nearest landmark within `maxDistance` studs that opens a screen, and its distance; nil and the cap when none is that near.
function LandmarkRenderer.NearestOpening(maxDistance: number): (string?, number)
	local best: string? = nil
	local bestDistance = maxDistance
	for id in pairs(records) do
		if LandmarkRenderer.Opens(id) == nil then
			continue
		end
		local distance = LandmarkRenderer.DistanceTo(id)
		if distance <= bestDistance then
			best, bestDistance = id, distance
		end
	end
	return best, bestDistance
end

function LandmarkRenderer.Stop()
	if not running then
		return
	end
	running = false
	for _, connection in ipairs(folderConns) do
		connection:Disconnect()
	end
	folderConns = {}
	for model in pairs(byModel) do
		untrack(model)
	end
	for model in pairs(waiting) do
		stopWaiting(model)
	end
end

return LandmarkRenderer
