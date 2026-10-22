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
local PropData = require(script.Parent.data.Props)
local ModelAssets = require(script.Parent.data.ModelAssets)
local ModelInstall = require(script.Parent.ModelInstall)

local Props = {}

-- The Enum.CollisionFidelity each plan name from ModelInstall.CollisionPlan stands for.
local FIDELITY: { [string]: Enum.CollisionFidelity } = {
	Box = Enum.CollisionFidelity.Box,
	Hull = Enum.CollisionFidelity.Hull,
	Precise = Enum.CollisionFidelity.PreciseConvexDecomposition,
}

-- Model:ScaleTo is absolute (1 = the size the model was built at), so each source's own factor is read
-- once and every clone scales from that baseline; nothing done to a clone later can shift it.
local sourceScale: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

-- CollisionFidelity is writable only from a plugin or Open Cloud (Edit mode), not from a game script: a mesh keeps
-- the fidelity it was uploaded or installed with, and the first refusal is warned once.
local fidelityWarned = false
local function setFidelity(part: MeshPart, fidelity: Enum.CollisionFidelity)
	if part.CollisionFidelity == fidelity then
		return
	end
	local ok, err = pcall(function()
		part.CollisionFidelity = fidelity
	end)
	if not ok and not fidelityWarned then
		fidelityWarned = true
		warn(("[%s] Props: CollisionFidelity stays as uploaded (%s); only Edit mode (a plugin) can set it"):format(Config.WorkingTitle, tostring(err)))
	end
end

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

-- A prop's Glow slot wears the colour data/ModelAssets names for it, so a lamp recoloured in data (the Starhollow path lantern went
-- from warm white to amber, 2026-10-22) shows at once on a model that was installed in the place with the old hex; a prop with no
-- Glow row is left alone. Only Neon parts are touched (the slot is Neon by its emission).
local function glowColor(name: string): Color3?
	local rows = ModelAssets.Materials[name]
	if rows == nil then
		return nil
	end
	for _, row in ipairs(rows) do
		local hex = row[2]
		if row[1] == "Glow" and type(hex) == "string" then
			return Color3.fromHex(hex)
		end
	end
	return nil
end

-- Clones the prop, scales it to `scale` times the source's own size, stands it on `cframe` (the point
-- under the model's bottom centre, with the CFrame's rotation) and parents it under `parent`. Every
-- BasePart comes out Anchored with CanQuery and CanTouch off; CanCollide is `collide` (trees, rocks and
-- the shrine keep it on so players walk around them; the heater lamp turns it off) unless the prop's row in
-- data/Props says "None". Every MeshPart also gets the CollisionFidelity that row names (Box, Hull or Precise;
-- ModelInstall.CollisionPlan), where the import left the engine's Default; a row's `slots` gives a colour slot its own
-- collision (the Starhollow glowcaps: the stem boxes, the cap never collides). The model's pivot is the bottom centre
-- of its bounding box, or, for a row with `origin` (a sign arm, the camp flag), the point that far from it in the spec note's axes, turned
-- so the note's axes are the model's (the arm's local +X, which the layout yaws at its sight). Returns the placed Model, or nil when the
-- prop was never imported, so the caller builds its placeholder.
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
	local row = PropData.Rows[name]
	local glow = glowColor(name)
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if glow and descendant.Name == "Glow" and descendant.Material == Enum.Material.Neon then
				descendant.Color = glow
			end
			-- a row's `slots` can give one colour slot its own collision (ModelInstall.SlotCollision)
			local plan = ModelInstall.CollisionPlan(ModelInstall.SlotCollision(row, descendant.Name), collide)
			local fidelity = if plan.fidelity then FIDELITY[plan.fidelity] else nil
			descendant.Anchored = true
			descendant.CanCollide = plan.canCollide
			descendant.CanQuery = false
			descendant.CanTouch = false
			if fidelity and descendant:IsA("MeshPart") then
				setFidelity(descendant, fidelity)
			end
		end
	end
	clone:ScaleTo(baseline * scale)
	local minV, maxV = worldBounds(clone)
	local pivot = CFrame.new((minV.X + maxV.X) / 2, minV.Y, (minV.Z + maxV.Z) / 2)
	local origin = row and row.origin
	if origin then
		-- the export writes the note's -Z on the GLB's +Z; an upload arrives turned half a turn (Config.ModelFacesPlusZ), which puts the
		-- note's axes back on the place's, else the pivot takes that half turn itself
		local turn = if Config.ModelFacesPlusZ then CFrame.identity else CFrame.Angles(0, math.pi, 0)
		pivot = pivot * turn * CFrame.new(origin[1] * scale, origin[2] * scale, origin[3] * scale)
	end
	clone.WorldPivot = pivot
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
