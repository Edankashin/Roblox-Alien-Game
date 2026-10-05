--!strict
-- ReplicatedStorage.Shared.Props: the one place that knows about the imported scenery meshes,
-- ReplicatedStorage.<Config.ModelFolderName>.<Config.PropsFolderName>.<Name> (trees, rocks, geyser cones,
-- the shrine stones, the ship hull, the station and heater models...). Each prop is one Model with a
-- MeshPart per material, its pivot at the feet, authored at 1 unit = 1 stud. They are imported into
-- Studio by hand and Rojo never carries them, so every lookup is a FindFirstChild at runtime and every
-- caller (the server's world builder, the client's camp renderer, the Heaters service) falls back to its
-- part-built placeholder when Place answers nil. Shared so both sides use one technique: Place clones the
-- source, scales it from the source's own recorded scale, anchors every part and stands it on a point.
-- Nothing here decides an outcome; it only draws what the data tables and the server say.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.data.Config)

local Props = {}

-- Model:ScaleTo is absolute (1 = the size the model was built at), so each source's own factor is read
-- once and every clone scales from that baseline; nothing done to a clone later can shift it.
local sourceScale: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function folder(): Instance?
	local models = ReplicatedStorage:FindFirstChild(Config.ModelFolderName)
	if not models then
		return nil
	end
	return models:FindFirstChild(Config.PropsFolderName)
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

-- The source Model for a prop, ReplicatedStorage.<ModelFolderName>.<PropsFolderName>.<name>, or nil
-- when the folder, or that child, or a Model of that name is missing. Never yields: FindFirstChild only.
function Props.Find(name: string): Model?
	local root = folder()
	if not root then
		return nil
	end
	local found = root:FindFirstChild(name)
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

-- Clones the prop, scales it to `scale` times the source's own size, stands it on `cframe` (the point
-- under the model's bottom centre, with the CFrame's rotation) and parents it under `parent`. Every
-- BasePart comes out Anchored with CanQuery and CanTouch off; CanCollide is `collide` (trees, rocks and
-- the shrine keep it on so players walk around them; the heater lamp turns it off). The model's pivot is
-- the bottom centre of its bounding box. Returns the placed Model, or nil when the prop was never
-- imported, so the caller builds its placeholder.
function Props.Place(name: string, cframe: CFrame, scale: number, parent: Instance, collide: boolean): Model?
	local source = Props.Find(name)
	if not source then
		return nil
	end
	local baseline = sourceScale[source]
	if baseline == nil then
		baseline = source:GetScale()
		sourceScale[source] = baseline
	end
	local clone = source:Clone()
	clone.Name = name
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = collide
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	clone:ScaleTo(baseline * scale)
	local minV, maxV = worldBounds(clone)
	clone.WorldPivot = CFrame.new((minV.X + maxV.X) / 2, minV.Y, (minV.Z + maxV.Z) / 2)
	clone:PivotTo(cframe)
	clone.Parent = parent
	return clone
end

-- Recolours a placed prop: every BasePart under the model takes `hex`, except Neon parts, which keep
-- their own colour so a prop's glowing details survive a layout's palette (the shrine's tint).
function Props.Tint(model: Model, hex: string)
	local color = Color3.fromHex(hex)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Material ~= Enum.Material.Neon then
			descendant.Color = color
		end
	end
end

return Props
