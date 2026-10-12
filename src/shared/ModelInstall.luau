--!strict
-- ReplicatedStorage.Shared.ModelInstall: the pure rules of the model installer, with no Instances so the
-- headless tests can run them (tests/ModelInstall.spec.luau). It mirrors tools/studio/install_models.luau
-- (slotOf, the material choice in applyMaterials, the part sort, the "glow" fallback of normalise); the
-- server's runtime loader (Services/Models) uses it, and the Studio installer can take it over later so the
-- two never drift. The inputs are the generated rows in data/ModelAssets (Materials, NeonEmissionAbove,
-- MetalMetallicFrom). A GLB upload arrives as one MeshPart per material slot, named <Model>, <Model>2,
-- <Model>3... in slot order; these functions turn those names back into slots and the slots into materials.
-- Nothing here decides an outcome or touches the world.

local ModelInstall = {}

-- One MeshPart as the sort sees it: its slot number from SlotOf and its place in the model's descendant order.
export type SlotEntry = { slot: number, order: number }

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

-- True when a part name contains "glow", in any case. A prop with no Materials rows gets Neon on its MeshParts
-- named like that.
function ModelInstall.IsGlowName(name: string): boolean
	return string.find(string.lower(name), GLOW_WORD, 1, true) ~= nil
end

return ModelInstall
