--!strict
-- StarterPlayerScripts.Client.World.LandmarkRenderer: nameplates for the world's landmarks under
-- Workspace.World.Landmarks (World 1: the Shrine of Gaiabloom, where the Field Notes finale sounds the
-- horn). The server builds each landmark as a Model whose PrimaryPart carries the string attribute
-- LandmarkId; this module adds a gold nameplate (LANDMARK_<id>, visible within NameplateDistance)
-- above that part and answers where each landmark is, so the bootstrap can offer "Sound the horn"
-- within ShrineInteractDistance. Nothing here decides anything: the horn tap asks the server.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local LandmarkRenderer = {}

local FOLDER_NAME = "Landmarks"
local PLATE_LIFT = 1.2 -- studs between the top of the primary part and its nameplate (as NodeRenderer)

type Record = { id: string, model: Model, part: BasePart, plate: BillboardGui }

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

local function buildPlate(part: BasePart, id: string): BillboardGui
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(7, 2) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = Builder.text("LANDMARK_" .. id),
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(0, 0.2),
		size = UDim2.fromScale(1, 0.6),
	})
	plate.Parent = part
	return plate
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
	records[id] = { id = id, model = instance, part = primary, plate = buildPlate(primary, id) }
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
