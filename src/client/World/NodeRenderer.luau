--!strict
-- StarterPlayerScripts.Client.World.NodeRenderer: presentation for the key-material nodes the server
-- places under Workspace.World.Materials. Each node is a plain anchored part with attributes
-- (MaterialId, NodeId, Available); the server hides it (Transparency 1, Available false) while it is
-- collected and restores it on respawn. This module adds the nameplate (the material's name, visible
-- within NameplateDistance and only while available) and a gentle bob and slow spin, both local: the
-- server never moves a node, so a local CFrame does not fight replication. Both pause while a node
-- is unavailable. Nothing here decides anything; the Collect flow asks the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local NodeRenderer = {}

local FOLDER_NAME = "Materials"
local PLATE_LIFT = 1.2 -- studs between the top of the node (plus its bob) and its nameplate
local SPIN_SECONDS = 8 -- one full turn about Y takes this long; see the report note on moving it to data

type Record = {
	part: Part,
	materialId: string,
	nodeId: string,
	base: CFrame,
	phase: number,
	available: boolean,
	plate: BillboardGui,
	availableConn: RBXScriptConnection,
}

local records: { [Part]: Record } = {}
local rng = Random.new()
local renderConn: RBXScriptConnection? = nil
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

local function buildPlate(part: Part, materialId: string): BillboardGui
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(7, 1.2) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + Config.WildBobStuds + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	Builder.label({
		parent = plate,
		name = "Name",
		text = Builder.text("MATERIAL_" .. materialId),
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Featured,
	})
	plate.Parent = part
	return plate
end

local function readAvailable(part: Part): boolean
	local value = part:GetAttribute("Available")
	return if type(value) == "boolean" then value else true
end

local function setAvailable(record: Record, available: boolean)
	record.available = available
	record.plate.Enabled = available
	if not available then
		record.part.CFrame = record.base -- park it so the respawn starts from rest
	end
end

local function track(instance: Instance)
	if not instance:IsA("Part") or records[instance] then
		return
	end
	local materialId = instance:GetAttribute("MaterialId")
	local nodeId = instance:GetAttribute("NodeId")
	if type(materialId) ~= "string" or type(nodeId) ~= "string" then
		return
	end
	local plate = buildPlate(instance, materialId)
	local record: Record = {
		part = instance,
		materialId = materialId,
		nodeId = nodeId,
		base = instance.CFrame,
		phase = rng:NextNumber(0, math.pi * 2),
		available = true,
		plate = plate,
		availableConn = instance:GetAttributeChangedSignal("Available"):Connect(function()
			local current = records[instance]
			if current then
				setAvailable(current, readAvailable(instance))
			end
		end),
	}
	records[instance] = record
	setAvailable(record, readAvailable(instance))
end

local function untrack(instance: Instance)
	if not instance:IsA("Part") then
		return
	end
	local record = records[instance]
	if record then
		records[instance] = nil
		record.availableConn:Disconnect()
		if record.plate.Parent then
			record.plate:Destroy()
		end
	end
end

local function onRender()
	local now = os.clock()
	local omega = math.pi * 2 * Config.WildBobHz
	local spin = math.pi * 2 / SPIN_SECONDS
	for part, record in pairs(records) do
		if not part.Parent or not record.available then
			continue
		end
		local dy = math.sin(now * omega + record.phase) * Config.WildBobStuds
		local angle = (now * spin + record.phase) % (math.pi * 2)
		part.CFrame = record.base * CFrame.Angles(0, angle, 0) + Vector3.new(0, dy, 0)
	end
end

-- Public API -------------------------------------------------------------

-- Watches Workspace.World.Materials. Returns at once; if the folder never appears nothing is drawn.
function NodeRenderer.Start()
	if running then
		return
	end
	running = true
	if renderConn then
		renderConn:Disconnect()
	end
	renderConn = RunService.RenderStepped:Connect(onRender)
	task.spawn(function()
		local world = Workspace:WaitForChild("World")
		local materials = world:WaitForChild(FOLDER_NAME)
		if not running then
			return
		end
		for _, child in ipairs(materials:GetChildren()) do
			track(child)
		end
		table.insert(folderConns, materials.ChildAdded:Connect(track))
		table.insert(folderConns, materials.ChildRemoved:Connect(untrack))
	end)
end

-- The nearest available node within maxDistance of the player, with its distance.
function NodeRenderer.Nearest(maxDistance: number): (Part?, number)
	local at = rootPosition()
	if not at then
		return nil, math.huge
	end
	local best: Part? = nil
	local bestDistance = maxDistance
	for part, record in pairs(records) do
		if part.Parent and record.available then
			local distance = (record.base.Position - at).Magnitude
			if distance <= bestDistance then
				best = part
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

-- The server's NodeId for a tracked node part (what CollectMaterial takes), or nil for anything else.
function NodeRenderer.NodeIdOf(part: Part): string?
	local record = records[part]
	if record then
		return record.nodeId
	end
	local nodeId = part:GetAttribute("NodeId")
	return if type(nodeId) == "string" then nodeId else nil
end

-- The material a tracked node yields, or nil for anything else.
function NodeRenderer.MaterialIdOf(part: Part): string?
	local record = records[part]
	return if record then record.materialId else nil
end

function NodeRenderer.Stop()
	if not running then
		return
	end
	running = false
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	for _, connection in ipairs(folderConns) do
		connection:Disconnect()
	end
	folderConns = {}
	for part in pairs(records) do
		untrack(part)
	end
end

return NodeRenderer
