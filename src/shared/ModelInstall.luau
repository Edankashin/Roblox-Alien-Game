--!strict
-- ReplicatedStorage.Shared.ModelInstall: the pure rules of the model installer, with no Instances so the
-- headless tests can run them (tests/ModelInstall.spec.luau). It mirrors tools/studio/install_models.luau
-- (slotOf, the material choice in applyMaterials, the part sort, the "glow" fallback of normalise); the
-- server's runtime loader (Services/Models) uses it, and the Studio installer can take it over later so the
-- two never drift. The inputs are the generated rows in data/ModelAssets (Materials, NeonEmissionAbove,
-- MetalMetallicFrom). A GLB upload arrives as one MeshPart per material slot, named <Model>, <Model>2,
-- <Model>3... in slot order; these functions turn those names back into slots and the slots into materials.
-- Nothing here decides an outcome or touches the world.
--
-- The surface layer (docs/vault/06-art-pipelines/Surface-Pass.md) sits on top: a slot's optional `material`, `texture`
-- and `glossy` fields (data/ModelAssets.Surfaces, from materials.json) turn into a SurfacePlan here, as names and
-- numbers only. Services/Models maps the material name to the Enum and builds the SurfaceAppearance; a slot with no
-- fields gets the plan it always had.

local Types = require(script.Parent.types.Types)

local ModelInstall = {}

-- One MeshPart as the sort sees it: its slot number from SlotOf and its place in the model's descendant order.
export type SlotEntry = { slot: number, order: number }

export type SurfaceSpec = Types.SurfaceSpec
export type TextureRow = Types.TextureRow
-- The three Image ids a SurfaceAppearance takes (all non-zero, else there is no plan for maps).
export type SurfaceMaps = { colorMap: number, normalMap: number, roughnessMap: number }
-- What to do to one MeshPart: the Enum.Material name to set, the Reflectance (0 = leave it), and the maps when its
-- texture is uploaded.
export type SurfacePlan = { material: string, reflectance: number, maps: SurfaceMaps? }

export type PropCollision = Types.PropCollision
-- What to do to one placed prop's parts: CanCollide, and the CollisionFidelity name to set on each MeshPart ("Box", "Hull" or
-- "Precise"), or nil to leave the fidelity as imported (a prop with no data/Props row).
export type CollisionPlan = { canCollide: boolean, fidelity: ("Box" | "Hull" | "Precise")? }

-- The Roblox Material names a materials.json `material` may use (the names of Enum.Material; tools/lint_data.py keeps
-- the same list in SURFACE_MATERIALS and tools/tests/test_surfaces.py checks the two match). Neon, Metal and
-- SmoothPlastic stay on the list because a slot may name them outright.
ModelInstall.SurfaceMaterials = {
	"Plastic", "SmoothPlastic", "Neon", "Metal", "Foil", "Wood", "WoodPlanks", "Fabric", "Leather", "Rubber",
	"Grass", "Slate", "Rock", "Pebble", "Granite", "Marble", "Sand", "Sandstone", "Snow", "Ice", "Glass", "Mud",
} :: { string }
local materialAllowed: { [string]: boolean } = {}
for _, name in ipairs(ModelInstall.SurfaceMaterials) do
	materialAllowed[name] = true
end

local FIRST_SLOT = 1 -- a part with no numeric suffix is slot 1
local GLOW_WORD = "glow" -- the installer's fallback for a prop without Materials rows

-- Slot number of a GLB part from its name: no suffix = 1, "<Model>2" = 2. The model's own name is stripped
-- first, so a model whose name ends in a digit still reads right ("Rock2" is slot 1 of model "Rock2", "Rock23"
-- is slot 3). The trailing digits are the slot; a name with no trailing digits is slot 1.
function ModelInstall.SlotOf(partName: string, modelName: string): number
	local rest = partName
	if string.sub(rest, 1, #modelName) == modelName then
		rest = string.sub(rest, #modelName + 1)
	end
	local digits = string.match(rest, "(%d+)$")
	if digits then
		return tonumber(digits) or FIRST_SLOT
	end
	return FIRST_SLOT
end

-- The material name a Materials row asks for: "Neon" when its emission is above neonAbove, else "Metal" when its
-- metallic is at least metalFrom, else "SmoothPlastic". (Roughness is in the rows but Roblox has no per-part
-- roughness, so it is not applied.)
function ModelInstall.MaterialFor(metallic: number, emission: number, neonAbove: number, metalFrom: number): "Neon" | "Metal" | "SmoothPlastic"
	if emission > neonAbove then
		return "Neon"
	elseif metallic >= metalFrom then
		return "Metal"
	end
	return "SmoothPlastic"
end

-- The indices of `entries` sorted by slot, then by original order (then by index, so equal entries keep their
-- places). The loader builds one entry per MeshPart and walks the result to pair part i with Materials row i.
function ModelInstall.Order(entries: { SlotEntry }): { number }
	local indices: { number } = {}
	for index in ipairs(entries) do
		table.insert(indices, index)
	end
	table.sort(indices, function(a: number, b: number): boolean
		local left, right = entries[a], entries[b]
		if left.slot ~= right.slot then
			return left.slot < right.slot
		end
		if left.order ~= right.order then
			return left.order < right.order
		end
		return a < b
	end)
	return indices
end

-- The bare name a loaded MeshPart answers to: the model's name stripped off the front (an importer may prefix it) and a
-- trailing ".001" or digit suffix stripped off the end (the slot number of an old blockout, or a duplicate counter).
function ModelInstall.BareName(partName: string, modelName: string): string
	local rest = partName
	if string.sub(rest, 1, #modelName) == modelName and #rest > #modelName then
		rest = string.sub(rest, #modelName + 1)
	end
	rest = string.gsub(rest, "^[_%.%-]+", "")
	rest = string.gsub(rest, "[%._]%d+$", "")
	return rest
end

-- Pairs a model's MeshParts with its Materials rows. A part whose name (or BareName) is a row's name takes that row, so a
-- block-cell model's moving parts and FacePlate keep the names data/Rigs looks them up by whatever order the importer gave
-- them; the parts left over take the rows left over in slot order (ModelInstall.Order), as every old blockout did.
-- Returns, for each row position, the index of its part in `partNames` (absent when there is no part for that row).
function ModelInstall.Assign(partNames: { string }, entries: { SlotEntry }, rowNames: { string }, modelName: string): { [number]: number }
	local assigned: { [number]: number } = {}
	local usedPart: { [number]: boolean } = {}
	local rowByName: { [string]: number } = {}
	for position, rowName in ipairs(rowNames) do
		if rowByName[rowName] == nil then
			rowByName[rowName] = position
		end
	end
	for _, pass in ipairs({ "exact", "bare" }) do
		for index, partName in ipairs(partNames) do
			if not usedPart[index] then
				local key = if pass == "exact" then partName else ModelInstall.BareName(partName, modelName)
				local position = rowByName[key]
				if position and assigned[position] == nil then
					assigned[position] = index
					usedPart[index] = true
				end
			end
		end
	end
	local freeRows: { number } = {}
	for position in ipairs(rowNames) do
		if assigned[position] == nil then
			table.insert(freeRows, position)
		end
	end
	local next = 1
	for _, index in ipairs(ModelInstall.Order(entries)) do
		if not usedPart[index] then
			local position = freeRows[next]
			if not position then
				break
			end
			assigned[position] = index
			usedPart[index] = true
			next += 1
		end
	end
	return assigned
end

-- True when a part name contains "glow", in any case. A prop with no Materials rows gets Neon on its MeshParts
-- named like that.
function ModelInstall.IsGlowName(name: string): boolean
	return string.find(string.lower(name), GLOW_WORD, 1, true) ~= nil
end

-- True when `name` is on the SurfaceMaterials list.
function ModelInstall.IsSurfaceMaterial(name: string): boolean
	return materialAllowed[name] == true
end

-- A texture row's maps when all three ids are non-zero, else nil (a half-uploaded set is not used).
function ModelInstall.MapsOf(row: TextureRow?): SurfaceMaps?
	if row and row.colorMap > 0 and row.normalMap > 0 and row.roughnessMap > 0 then
		return { colorMap = row.colorMap, normalMap = row.normalMap, roughnessMap = row.roughnessMap }
	end
	return nil
end

-- The plan for one slot. `base` is the material name MaterialFor chose (Neon, Metal or SmoothPlastic); `spec` is the
-- slot's Surfaces row (nil = untouched: the base material, no reflectance, no maps); `textures` is data/Textures;
-- `gloss` is Config.ModelGlossReflectance.
-- Material: an explicit `material` on the SurfaceMaterials list wins (so Grass beats the emission rule, and a part can be
-- Glass although it glows), else `glossy` asks for SmoothPlastic, else the base. Reflectance: `gloss` when glossy, else 0.
-- Maps: the named texture's three ids when all are non-zero.
function ModelInstall.SurfacePlan(base: string, spec: SurfaceSpec?, textures: { [string]: TextureRow }, gloss: number): SurfacePlan
	if not spec then
		return { material = base, reflectance = 0, maps = nil }
	end
	local material = base
	local named = spec.material
	if named ~= nil and materialAllowed[named] then
		material = named
	elseif spec.glossy == true then
		material = "SmoothPlastic"
	end
	local textureKey = spec.texture
	return {
		material = material,
		reflectance = if spec.glossy == true then gloss else 0,
		maps = if textureKey ~= nil then ModelInstall.MapsOf(textures[textureKey]) else nil,
	}
end

-- The values a data/Props row's `collision` may take (Types.PropCollision; tools/lint_data.py keeps the same list in
-- PROP_COLLISIONS and tools/tests/test_lint_props.py checks the two match).
ModelInstall.PropCollisions = { "Box", "Hull", "Precise", "None" } :: { string }

-- The colour slots a block-cell prop's MeshParts are named by (tools/blocky/export_models.py PROP_SLOTS), the keys a row's
-- `slots` may use (tools/lint_data.py keeps the same list in PROP_SLOTS).
ModelInstall.PropSlots = { "Body", "BodyDark", "Accessory", "Trim", "Glow" } :: { string }

-- The collision one part of a placed prop takes: the row's `slots` entry for the part's name when it has one, else the row's
-- own collision; nil when the prop has no row.
function ModelInstall.SlotCollision(row: Types.PropRow?, partName: string): PropCollision?
	if row == nil then
		return nil
	end
	local slots = row.slots
	if slots == nil then
		return row.collision
	end
	local own: PropCollision? = nil
	if partName == "Body" then
		own = slots.Body
	elseif partName == "BodyDark" then
		own = slots.BodyDark
	elseif partName == "Accessory" then
		own = slots.Accessory
	elseif partName == "Trim" then
		own = slots.Trim
	elseif partName == "Glow" then
		own = slots.Glow
	end
	return own or row.collision
end

-- The plan for one placed prop. `collision` is its data/Props row (nil = no row: the caller's `collide` and the imported
-- fidelity stand); `collide` is what the caller asked for (Props.Place's argument). A "None" row never collides, and a caller
-- that turns collision off gets no collision from any row; either way nothing touches the part, so it takes Box, the cheapest
-- fidelity. Otherwise the row's own shape: Box, Hull or Precise (PreciseConvexDecomposition).
function ModelInstall.CollisionPlan(collision: PropCollision?, collide: boolean): CollisionPlan
	if collision == nil then
		return { canCollide = collide, fidelity = nil }
	end
	if collision == "None" or not collide then
		return { canCollide = false, fidelity = "Box" }
	end
	return { canCollide = true, fidelity = collision }
end

return ModelInstall
