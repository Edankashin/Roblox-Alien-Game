--!strict
-- StarterPlayerScripts.Client.World.WildRenderer: presentation for every wild alien part under
-- Workspace.World.Wild. The server places a plain anchored part with attributes; this module adds the
-- nameplate (name + tier in its colour, visible within NameplateDistance), bobs the part locally
-- (the server never moves it, so a local CFrame does not fight replication), and renders species
-- the player has not caught as dark silhouettes until they walk within ShadowRevealDistance.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Species = require(Shared:WaitForChild("data"):WaitForChild("Species"))
local Strings = require(Shared:WaitForChild("strings"):WaitForChild("en"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local WildRenderer = {}

type Record = {
	part: Part,
	species: string,
	tier: string,
	base: CFrame,
	phase: number,
	realColor: Color3,
	shadowed: boolean,
	plate: BillboardGui,
	nameLabel: TextLabel,
}

local records: { [Part]: Record } = {}
local known: { [string]: boolean } = {}
local rng = Random.new()
local wildFolder: Folder? = nil
local renderConn: RBXScriptConnection? = nil
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

local function buildPlate(part: Part, name: string, tier: string): (BillboardGui, TextLabel)
	local plate = Instance.new("BillboardGui")
	plate.Name = "Nameplate"
	plate.Adornee = part
	plate.Size = UDim2.fromScale(7, 2) -- studs
	plate.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + Config.WildBobStuds + 1.2, 0)
	plate.MaxDistance = Config.NameplateDistance
	plate.AlwaysOnTop = false
	plate.LightInfluence = 0
	plate.ResetOnSpawn = false
	local scale = Instance.new("UIScale")
	scale.Parent = plate
	local nameLabel = Builder.label({
		parent = plate,
		name = "Name",
		text = name,
		textSize = Theme.TextSize.Label,
		size = UDim2.fromScale(1, 0.55),
	})
	Builder.label({
		parent = plate,
		name = "Tier",
		text = Builder.text("TIER_" .. tier),
		textSize = Theme.TextSize.Body,
		position = UDim2.fromScale(0, 0.55),
		size = UDim2.fromScale(1, 0.45),
		color = Builder.tierColor(tier),
	})
	plate.Parent = part
	return plate, nameLabel
end

local function applyShadow(record: Record)
	record.shadowed = true
	record.part.Color = Theme.Shadow
	record.part.Material = Enum.Material.SmoothPlastic
	record.nameLabel.Text = Strings.UNKNOWN_NAME
end

local function reveal(record: Record)
	if not record.shadowed then
		return
	end
	record.shadowed = false
	local def = Species.ById[record.species]
	record.nameLabel.Text = if def then def.name else record.species
	TweenService:Create(record.part, TweenInfo.new(Theme.Tween.Open * 2, Enum.EasingStyle.Quad), { Color = record.realColor }):Play()
	local scale = record.plate:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = 1.35
		TweenService:Create(scale, TweenInfo.new(Theme.Tween.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function track(instance: Instance)
	if not instance:IsA("Part") or records[instance] then
		return
	end
	local species = instance:GetAttribute("SpeciesId")
	local tier = instance:GetAttribute("Tier")
	if type(species) ~= "string" or type(tier) ~= "string" then
		return
	end
	local def = Species.ById[species]
	local displayName = if def then def.name else species
	local plate, nameLabel = buildPlate(instance, displayName, tier)
	local record: Record = {
		part = instance,
		species = species,
		tier = tier,
		base = instance.CFrame,
		phase = rng:NextNumber(0, math.pi * 2),
		realColor = instance.Color,
		shadowed = false,
		plate = plate,
		nameLabel = nameLabel,
	}
	records[instance] = record
	if not known[species] then
		applyShadow(record)
	end
end

local function untrack(instance: Instance)
	local record = records[instance :: any]
	if record then
		records[instance :: any] = nil
		if record.plate.Parent then
			record.plate:Destroy()
		end
	end
end

local function onRender()
	local now = os.clock()
	local at = rootPosition()
	local omega = math.pi * 2 * Config.WildBobHz
	for part, record in pairs(records) do
		if not part.Parent then
			continue
		end
		local dy = math.sin(now * omega + record.phase) * Config.WildBobStuds
		part.CFrame = record.base + Vector3.new(0, dy, 0)
		if at and record.shadowed and (record.base.Position - at).Magnitude <= Config.ShadowRevealDistance then
			reveal(record)
		end
	end
end

-- Public API -------------------------------------------------------------

-- `knownSpecies` is the set of species the player has caught (from the profile's codex).
function WildRenderer.Start(knownSpecies: { [string]: boolean })
	known = knownSpecies
	local world = Workspace:WaitForChild("World")
	local wild = world:WaitForChild("Wild") :: Folder
	wildFolder = wild
	for _, child in ipairs(wild:GetChildren()) do
		track(child)
	end
	wild.ChildAdded:Connect(track)
	wild.ChildRemoved:Connect(untrack)
	if renderConn then
		renderConn:Disconnect()
	end
	renderConn = RunService.RenderStepped:Connect(onRender)
end

-- A species was just caught: it is no longer a silhouette anywhere.
function WildRenderer.MarkKnown(species: string)
	known[species] = true
	for _, record in pairs(records) do
		if record.species == species then
			reveal(record)
		end
	end
end

-- The nearest wild part within maxDistance of the player, with its distance.
function WildRenderer.Nearest(maxDistance: number): (Part?, number)
	local at = rootPosition()
	if not at then
		return nil, math.huge
	end
	local best: Part? = nil
	local bestDistance = maxDistance
	for part, record in pairs(records) do
		if part.Parent then
			local distance = (record.base.Position - at).Magnitude
			if distance <= bestDistance then
				best = part
				bestDistance = distance
			end
		end
	end
	return best, bestDistance
end

-- The wild part under a screen point, if any (tap-to-catch on the alien itself).
function WildRenderer.PartAtScreenPoint(x: number, y: number): Part?
	local camera = Workspace.CurrentCamera
	local wild = wildFolder
	if not camera or not wild then
		return nil
	end
	local ray = camera:ScreenPointToRay(x, y) -- input positions include the GUI inset
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { wild }
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	if hit and hit.Instance:IsA("Part") and records[hit.Instance] then
		return hit.Instance
	end
	return nil
end

return WildRenderer
