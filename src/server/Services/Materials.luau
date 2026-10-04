--!strict
-- ServerScriptService.Server.Services.Materials: key material nodes scattered over the world.
-- Each node is one anchored Part under Workspace.World.Materials carrying attributes (MaterialId,
-- NodeId, Available); the client shows Collect inside MaterialInteractDistance and asks the server
-- to take it. Nodes are shared by everyone on the server, first come first served, and come back
-- after the material's respawnSeconds. Only WreckPlate is placed in the Meadow for now; the node
-- builder takes any material id so later biomes can add their own.

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local KeyMaterials = require(Shared.data.KeyMaterials)
local Layout = require(Shared.data.Meadow)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Meadow = require(script.Parent.Meadow)

local Materials = {}

type MaterialDef = { name: string, world: number, biome: string, condition: string, dropCount: number, respawnSeconds: number }
type Node = { nodeId: string, materialId: string, part: Part, available: boolean }

local FOLDER_NAME = "Materials"
local MEADOW_MATERIAL = "WreckPlate" -- the one material the placeholder Meadow scatters
local PLACEMENT_ATTEMPTS = 40 -- tries to find a point clear of other nodes before giving up on one
local REMOTE_RATE_PER_SECOND = 4

local defs: { [string]: MaterialDef } = KeyMaterials
local nodes: { [string]: Node } = {}

local function flatDistance(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function clearOfNodes(position: Vector3): boolean
	for _, node in pairs(nodes) do
		if flatDistance(node.part.Position, position) < Layout.NodeMinSeparation then
			return false
		end
	end
	return true
end

-- A point in the ring between NodeMinFromCamp and NodeMaxFromCamp, clear of the nodes placed so far.
local function scatterPoint(rng: Random): Vector3?
	for _ = 1, PLACEMENT_ATTEMPTS do
		local angle = rng:NextNumber(0, math.pi * 2)
		local radius = rng:NextNumber(Layout.NodeMinFromCamp, Layout.NodeMaxFromCamp)
		local position = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if clearOfNodes(position) then
			return position
		end
	end
	return nil
end

local function setAvailable(node: Node, available: boolean)
	node.available = available
	node.part:SetAttribute("Available", available)
	node.part.Transparency = if available then 0 else 1
	node.part.CanQuery = available -- the client finds nodes by raycast; a taken one is not a target
end

-- One node of any material at a flat position; the part floats NodeHoverStuds over the floor.
local function buildNode(materialId: string, flat: Vector3, parent: Instance): Node
	local nodeId = HttpService:GenerateGUID(false)
	local y = Meadow.GetFloorTop() + Layout.NodeHoverStuds + Layout.NodeSize / 2
	local part = Instance.new("Part")
	part.Name = materialId
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.one * Layout.NodeSize
	part.CFrame = CFrame.new(flat.X, y, flat.Z)
	part.Color = Color3.fromHex(Layout.NodeColor)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part:SetAttribute("MaterialId", materialId)
	part:SetAttribute("NodeId", nodeId)
	part:SetAttribute("Available", true)
	part.Parent = parent
	local node: Node = { nodeId = nodeId, materialId = materialId, part = part, available = true }
	nodes[nodeId] = node
	return node
end

-- Hides the node and brings it back after the material's respawn time (0 means it never returns).
local function take(node: Node)
	setAvailable(node, false)
	local def = defs[node.materialId]
	local seconds = if def then def.respawnSeconds else 0
	if seconds <= 0 then
		return
	end
	task.delay(seconds, function()
		if node.part.Parent then
			setAvailable(node, true)
		end
	end)
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Remotes ----------------------------------------------------------------

local function onCollectMaterial(player: Player, nodeId: any): (boolean, string?)
	if type(nodeId) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "CollectMaterial", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	local node = nodes[nodeId]
	if not node then
		return false, "NoNode"
	end
	if not node.available then
		return false, "Taken"
	end
	local at = rootPosition(player)
	if not at then
		return false, "NoCharacter"
	end
	if (at - node.part.Position).Magnitude > Config.MaterialInteractDistance + Config.MaterialDistanceSlack then
		return false, "TooFar"
	end
	local def = defs[node.materialId]
	if not def then
		return false, "NoNode"
	end
	local materialId = node.materialId
	local keyMaterials: { [string]: number } = {}
	PlayerData.Update(player, function(profile)
		profile.inventory.keyMaterials[materialId] = (profile.inventory.keyMaterials[materialId] or 0) + def.dropCount
		keyMaterials = profile.inventory.keyMaterials
	end)
	take(node)
	Net.event("InventoryChanged"):FireClient(player, keyMaterials)
	Net.event("MaterialCollected"):FireClient(player, materialId, def.dropCount)
	return true
end

-- Public API -------------------------------------------------------------

function Materials.Init()
	Net.event("InventoryChanged")
	Net.event("MaterialCollected")
	Net.func("CollectMaterial").OnServerInvoke = onCollectMaterial

	-- Meadow has already built (or found) Workspace.World by this point in the boot order.
	local world = Workspace:WaitForChild("World")
	local folder = world:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = world
	end
	-- Deterministic scatter: every server places the same plates, so directions between players stay true.
	local rng = Random.new(Layout.NodeSeed)
	for _ = 1, Layout.WreckPlateNodes do
		local at = scatterPoint(rng)
		if at then
			buildNode(MEADOW_MATERIAL, at, folder)
		end
	end
end

function Materials.Start()
	local count = 0
	for _ in pairs(nodes) do
		count += 1
	end
	print(("[%s] Materials: %d nodes placed"):format(Config.WorkingTitle, count))
end

return Materials
