--!strict
-- ServerScriptService.Server.Services.Materials: key material nodes scattered over World 1.
-- Each node is one anchored Part under Workspace.World.Materials carrying attributes (MaterialId,
-- NodeId, Available, WaitingFor); the client shows Collect inside MaterialInteractDistance and asks
-- the server to take it. Nodes are shared by everyone on the server, first come first served, and
-- come back after the material's respawnSeconds. Every KeyMaterials row with nodes > 0 is scattered
-- in its own biome (Shared/Biomes); a row with a condition (Night, Rain) is only available while the
-- WorldClock says so (WorldClock.HasCondition: a rainy night is both Rain and Night) and shows as a
-- ghost otherwise, so a player can find it by day and come back. Every collect is reported to Quests
-- for the Field Notes.

local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local KeyMaterials = require(Shared.data.KeyMaterials)
local Layout = require(Shared.data.Meadow)
local Biomes = require(Shared.Biomes)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Meadow = require(script.Parent.Meadow)
local WorldClock = require(script.Parent.WorldClock)
local Quests = require(script.Parent.Quests)

local Materials = {}

type Node = {
	nodeId: string,
	materialId: string,
	def: KeyMaterials.KeyMaterialDef,
	part: Part,
	taken: boolean, -- collected and waiting on its respawn timer
}

local FOLDER_NAME = "Materials"
local WORLD_ID = 1 -- the placeholder Meadow is World 1; later worlds scatter their own rows
local PLACEMENT_ATTEMPTS = 40 -- tries to find a point clear of other nodes before giving up on one
local REMOTE_RATE_PER_SECOND = 4

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}

local defs: { [string]: KeyMaterials.KeyMaterialDef } = KeyMaterials
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

-- A point inside the material's biome (the camp ring for the Meadow, the region circle otherwise),
-- clear of the nodes placed so far.
local function scatterPoint(biome: string, rng: Random): Vector3?
	for _ = 1, PLACEMENT_ATTEMPTS do
		local position = Biomes.RandomPointIn(biome, rng, Layout.NodeMinFromCamp, Layout.NodeMaxFromCamp)
		if clearOfNodes(position) then
			return position
		end
	end
	return nil
end

-- Availability -------------------------------------------------------------

local function conditionMet(def: KeyMaterials.KeyMaterialDef): boolean
	return def.condition == "Any" or WorldClock.HasCondition(def.condition)
end

local function isAvailable(node: Node): boolean
	return not node.taken and conditionMet(node.def)
end

-- Everything the client reads is derived here from the two inputs, taken and conditionMet:
--   taken            -> invisible, not a raycast target, WaitingFor ""
--   condition unmet  -> ghosted, not a raycast target, WaitingFor = the condition name
--   available        -> solid, raycast target, WaitingFor ""
local function applyVisual(node: Node)
	local met = conditionMet(node.def)
	local available = not node.taken and met
	local part = node.part
	part:SetAttribute("Available", available)
	part:SetAttribute("WaitingFor", if not node.taken and not met then node.def.condition else "")
	part.Transparency = if node.taken then 1 elseif not met then Layout.NodeWaitingTransparency else 0
	part.CanQuery = available -- the client finds nodes by raycast; only an available one is a target
end

-- One node at a flat position; the part floats NodeHoverStuds over the surface it stands on.
local function buildNode(materialId: string, def: KeyMaterials.KeyMaterialDef, flat: Vector3, parent: Instance): Node
	local nodeId = HttpService:GenerateGUID(false)
	local y = Meadow.GetSurfaceTop(flat) + Layout.NodeHoverStuds + Layout.NodeSize / 2
	local part = Instance.new("Part")
	part.Name = materialId
	part.Shape = SHAPES[def.shape] or Enum.PartType.Block
	part.Size = Vector3.one * Layout.NodeSize
	local cframe = CFrame.new(flat.X, y, flat.Z)
	if def.shape == "Cylinder" then
		cframe = cframe * CFrame.Angles(0, 0, math.rad(90)) -- stand it upright
	end
	part.CFrame = cframe
	part.Color = Color3.fromHex(def.color)
	part.Material = if def.glows then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part:SetAttribute("MaterialId", materialId)
	part:SetAttribute("NodeId", nodeId)
	local node: Node = { nodeId = nodeId, materialId = materialId, def = def, part = part, taken = false }
	applyVisual(node)
	part.Parent = parent
	nodes[nodeId] = node
	return node
end

-- Hides the node and brings it back after the material's respawn time (0 means it never returns).
-- The timer runs regardless of the condition; the condition gate is re-applied when it fires.
local function take(node: Node)
	node.taken = true
	applyVisual(node)
	local seconds = node.def.respawnSeconds
	if seconds <= 0 then
		return
	end
	task.delay(seconds, function()
		if node.part.Parent then
			node.taken = false
			applyVisual(node)
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
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local node = nodes[nodeId]
	if not node then
		return false, "NoNode"
	end
	if not isAvailable(node) then
		return false, "Taken"
	end
	local at = rootPosition(player)
	if not at then
		return false, "NoCharacter"
	end
	if (at - node.part.Position).Magnitude > Config.MaterialInteractDistance + Config.MaterialDistanceSlack then
		return false, "TooFar"
	end
	local def = node.def
	local materialId = node.materialId
	PlayerData.Update(player, function(p)
		p.inventory.keyMaterials[materialId] = (p.inventory.keyMaterials[materialId] or 0) + def.dropCount
	end)
	take(node)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
	Net.event("MaterialCollected"):FireClient(player, materialId, def.dropCount)
	Quests.OnCollect(player, materialId)
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

	-- Deterministic scatter: one rng for every material, materials in id order (pairs() order is not
	-- stable between servers), so every server places the same nodes and directions between players
	-- stay true.
	local materialIds: { string } = {}
	for materialId in pairs(defs) do
		table.insert(materialIds, materialId)
	end
	table.sort(materialIds)
	local rng = Random.new(Layout.NodeSeed)
	for _, materialId in ipairs(materialIds) do
		local def = defs[materialId]
		if def.world == WORLD_ID and def.nodes > 0 then
			for _ = 1, def.nodes do
				local at = scatterPoint(def.biome, rng)
				if at then
					buildNode(materialId, def, at, folder)
				end
			end
		end
	end
end

function Materials.Start()
	-- Night and Rain nodes appear and ghost with the clock; respawn timers run on their own.
	WorldClock.OnChanged(function()
		for _, node in pairs(nodes) do
			applyVisual(node)
		end
	end)

	local count = 0
	for _ in pairs(nodes) do
		count += 1
	end
	print(("[%s] Materials: %d nodes placed"):format(Config.WorkingTitle, count))
end

return Materials
