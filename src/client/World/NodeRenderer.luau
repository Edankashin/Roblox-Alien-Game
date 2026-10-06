--!strict
-- StarterPlayerScripts.Client.World.NodeRenderer: presentation for the key-material nodes the server
-- places under Workspace.World.Materials. Each node is a plain anchored part with attributes
-- (MaterialId, NodeId, Available, WaitingFor); the server hides it while it is collected and dims it
-- while its condition is not met (WaitingFor names the condition, e.g. "Night"). This module adds the
-- nameplate (the material's name, plus "Only at night" while waiting, visible within NameplateDistance)
-- and a gentle bob and slow spin, both local: the server never moves a node, so a local CFrame does
-- not fight replication. Both pause while a node is unavailable. Nothing here decides anything; the
-- Collect flow asks the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Place = require(Shared:WaitForChild("Place"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local NodeRenderer = {}

local FOLDER_NAME = "Materials"
local PLATE_LIFT = 1.2 -- studs between the top of the node (plus its bob) and its nameplate
local PLATE_W = 7 -- studs
local PLATE_H = 2
local NAME_H = 0.55 -- the name line's share of the plate's height; the hidden-hint line takes the rest
-- The material's icon, when the pack has it: a square the name line's height at the plate's left edge, with
-- the name shifted right by its width plus a gap (of the plate's width). The plate is wider than tall, so
-- the square's width as a fraction of the plate is its height share scaled by the plate's proportions.
local PLATE_ICON_W = NAME_H * PLATE_H / PLATE_W
local PLATE_ICON_GAP = 0.02

type Record = {
	part: Part,
	materialId: string,
	nodeId: string,
	base: CFrame,
	phase: number,
	available: boolean,
	plate: BillboardGui,
	hintLabel: TextLabel,
	availableConn: RBXScriptConnection,
	waitingConn: RBXScriptConnection,
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

local function buildPlate(part: Part, materialId: string): (BillboardGui, TextLabel)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(PLATE_W, PLATE_H) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + Config.WildBobStuds + PLATE_LIFT, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	local icon = Builder.icon({
		parent = plate,
		name = "Icon",
		key = materialId, -- the material ids are the icon keys
		size = UDim2.fromScale(PLATE_ICON_W, NAME_H),
	})
	local shift = if icon then PLATE_ICON_W + PLATE_ICON_GAP else 0
	Builder.label({
		parent = plate,
		name = "Name",
		text = Builder.text("MATERIAL_" .. materialId),
		textSize = Theme.TextSize.Label,
		color = Theme.Colors.Featured,
		position = UDim2.fromScale(shift, 0),
		size = UDim2.fromScale(1 - shift, NAME_H),
	})
	local hint = Builder.label({
		parent = plate,
		name = "Hint",
		text = "",
		textSize = Theme.TextSize.Body,
		color = Theme.Colors.Select,
		position = UDim2.fromScale(0, NAME_H),
		size = UDim2.fromScale(1, 1 - NAME_H),
	})
	hint.Visible = false
	plate.Parent = part
	return plate, hint
end

local function readAvailable(part: Part): boolean
	local value = part:GetAttribute("Available")
	return if type(value) == "boolean" then value else true
end

local function readWaitingFor(part: Part): string
	local value = part:GetAttribute("WaitingFor")
	return if type(value) == "string" then value else ""
end

-- Available: plate on, bob and spin run. Waiting on a condition: plate on with the hint, parked still.
-- Taken: plate off, parked still.
local function refresh(record: Record)
	local available = readAvailable(record.part)
	local waitingFor = readWaitingFor(record.part)
	record.available = available
	record.plate.Enabled = available or waitingFor ~= ""
	record.hintLabel.Visible = not available and waitingFor ~= ""
	if waitingFor ~= "" then
		record.hintLabel.Text = Strings.NODE_HIDDEN_HINT:format(Builder.text("CONDITION_" .. waitingFor))
	end
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
	local plate, hint = buildPlate(instance, materialId)
	local function onAttribute()
		local current = records[instance]
		if current then
			refresh(current)
		end
	end
	local record: Record = {
		part = instance,
		materialId = materialId,
		nodeId = nodeId,
		base = instance.CFrame,
		phase = rng:NextNumber(0, math.pi * 2),
		available = true,
		plate = plate,
		hintLabel = hint,
		availableConn = instance:GetAttributeChangedSignal("Available"):Connect(onAttribute),
		waitingConn = instance:GetAttributeChangedSignal("WaitingFor"):Connect(onAttribute),
	}
	records[instance] = record
	refresh(record)
end

local function untrack(instance: Instance)
	if not instance:IsA("Part") then
		return
	end
	local record = records[instance]
	if record then
		records[instance] = nil
		record.availableConn:Disconnect()
		record.waitingConn:Disconnect()
		if record.plate.Parent then
			record.plate:Destroy()
		end
	end
end

local function onRender()
	local now = os.clock()
	local omega = math.pi * 2 * Config.WildBobHz
	local spin = math.pi * 2 / Place.Layout().NodeSpinSeconds
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
