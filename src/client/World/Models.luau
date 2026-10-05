--!strict
-- StarterPlayerScripts.Client.World.Models: the one place that knows about ReplicatedStorage.Models.
-- Species meshes are imported into Studio by hand (one Model per species, one MeshPart per material;
-- see .claude/skills/import-model) and Rojo never carries them, so every lookup is a FindFirstChild at
-- runtime and every caller falls back to the placeholder shape when the Model is missing. A clone comes
-- out anchored, with no collisions, queries or touches, scaled, with its face toward -Z (the Roblox
-- front) and its pivot at the bottom centre of its bounding box, so PivotTo(cframe) stands it on that
-- point. Nothing here decides an outcome; it only renders what the server and the data tables say.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Theme = require(Shared:WaitForChild("Theme"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))

local Models = {}

-- Attributes on each part that remember the look SetShadow paints over, so un-shadowing restores it exactly.
local ORIG_COLOR = "OrigColor"
local ORIG_MATERIAL = "OrigMaterial"
local ORIG_TEXTURE = "OrigTexture"

-- Model:ScaleTo is absolute (1 = the size the model was built at), so each source's own factor is read
-- once and every clone scales from that baseline; nothing done to a clone later can shift it.
local sourceScale: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local materialsByName: { [string]: Enum.Material } = {}
for _, item in ipairs(Enum.Material:GetEnumItems()) do
	materialsByName[item.Name] = item :: any
end

local function folder(): Instance?
	return ReplicatedStorage:FindFirstChild(Config.ModelFolderName)
end

-- World-axis-aligned bounds of every BasePart in the model (the import may leave parts rotated, so
-- GetBoundingBox's orientation is not trusted for the feet).
local function worldBounds(model: Model): (Vector3, Vector3)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local cf, half = descendant.CFrame, descendant.Size / 2
			local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
			local extent = Vector3.new(
				math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
				math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
				math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
			)
			minV = minV:Min(cf.Position - extent)
			maxV = maxV:Max(cf.Position + extent)
		end
	end
	if minV.X == math.huge then
		return Vector3.zero, Vector3.zero
	end
	return minV, maxV
end

-- Public API -------------------------------------------------------------

-- Whether the model folder exists at all (false in a place where nothing has been imported yet).
function Models.Available(): boolean
	return folder() ~= nil
end

-- The source Model for a species, ReplicatedStorage.<ModelFolderName>.<def.model or def.id>, or nil.
-- Never yields: FindFirstChild only.
function Models.Find(def: Types.SpeciesDef): Model?
	local root = folder()
	if not root then
		return nil
	end
	local found = root:FindFirstChild(def.model or def.id)
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

-- A clone of the species model at `scale` times the source's size, ready to PivotTo: every BasePart
-- anchored, CanCollide/CanQuery/CanTouch off, CastShadow on; the face toward the pivot's -Z (turned
-- 180 degrees when Config.ModelFacesPlusZ); the pivot upright at the bottom centre of the bounding
-- box. Nil when the species has no model.
function Models.Clone(def: Types.SpeciesDef, scale: number): Model?
	local source = Models.Find(def)
	if not source then
		return nil
	end
	local baseline = sourceScale[source]
	if baseline == nil then
		baseline = source:GetScale()
		sourceScale[source] = baseline
	end
	local clone = source:Clone()
	clone.Name = def.id
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = true
		end
	end
	clone:ScaleTo(baseline * scale)
	-- The turn lives in the pivot's rotation, not in a PivotTo: PivotTo keeps the parts' offsets from
	-- the pivot, so a turn made that way would be undone by the caller's own PivotTo. With the pivot
	-- yawed 180 degrees relative to the parts, a face built toward +Z ends up along the pivot's -Z.
	local minV, maxV = worldBounds(clone)
	local bottom = Vector3.new((minV.X + maxV.X) / 2, minV.Y, (minV.Z + maxV.Z) / 2)
	local facing = if Config.ModelFacesPlusZ then CFrame.Angles(0, math.pi, 0) else CFrame.identity
	clone.WorldPivot = CFrame.new(bottom) * facing
	return clone
end

-- Height of a (cloned) model in studs; the pivot is upright, so the extents' Y is the world height.
function Models.Height(model: Model): number
	return model:GetExtentsSize().Y
end

-- Shadowed: every part painted Theme.Shadow in SmoothPlastic with any texture dropped, the original
-- Color, Material and TextureID kept in attributes on the part. Un-shadowed: those restored exactly.
function Models.SetShadow(model: Model, shadowed: boolean)
	for _, descendant in ipairs(model:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end
		if shadowed then
			if descendant:GetAttribute(ORIG_COLOR) == nil then
				descendant:SetAttribute(ORIG_COLOR, descendant.Color)
				descendant:SetAttribute(ORIG_MATERIAL, descendant.Material.Name)
				if descendant:IsA("MeshPart") then
					descendant:SetAttribute(ORIG_TEXTURE, descendant.TextureID)
				end
			end
			descendant.Color = Theme.Shadow
			descendant.Material = Enum.Material.SmoothPlastic
			if descendant:IsA("MeshPart") then
				descendant.TextureID = ""
			end
		else
			local color = descendant:GetAttribute(ORIG_COLOR)
			if typeof(color) == "Color3" then
				descendant.Color = color
			end
			local material = descendant:GetAttribute(ORIG_MATERIAL)
			if type(material) == "string" and materialsByName[material] then
				descendant.Material = materialsByName[material]
			end
			local texture = descendant:GetAttribute(ORIG_TEXTURE)
			if type(texture) == "string" and descendant:IsA("MeshPart") then
				descendant.TextureID = texture
			end
		end
	end
end

return Models
