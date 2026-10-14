--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local ModelInstall = require(Shared.ModelInstall)
local ModelAssets = require(Shared.data.ModelAssets)
local Textures = require(Shared.data.Textures)
local Types = require(Shared.types.Types)
local F = require(script.Parent.Fixtures)

-- The thresholds come from the generated table, never from literals here.
local neonAbove = ModelAssets.NeonEmissionAbove
local metalFrom = ModelAssets.MetalMetallicFrom
local step = F.quarter -- a gap well inside both thresholds' neighbourhoods

-- A Materials row is { renamedPart, hex, roughness, metallic, emission }.
local ROW_FIELDS = 5
local HEX_DIGITS = 6
local NAME_FIELD, HEX_FIELD, ROUGHNESS_FIELD, METALLIC_FIELD, EMISSION_FIELD = 1, 2, 3, 4, 5

local function sortedNames(map)
	local names = {}
	for name in pairs(map) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

describe("ModelInstall.SlotOf (the numeric suffix of a GLB part)", function()
	it("a part with no suffix is slot 1", function()
		expect(ModelInstall.SlotOf("Mossbop", "Mossbop")).toEqual(1)
		expect(ModelInstall.SlotOf("Body", "Mossbop")).toEqual(1)
	end)
	it("a numeric suffix is the slot", function()
		expect(ModelInstall.SlotOf("Mossbop2", "Mossbop")).toEqual(2)
		expect(ModelInstall.SlotOf("Mossbop7", "Mossbop")).toEqual(7)
		expect(ModelInstall.SlotOf("Mossbop12", "Mossbop")).toEqual(12)
	end)
	it("a model name that ends in a letter strips cleanly", function()
		expect(ModelInstall.SlotOf("IceRockB", "IceRockB")).toEqual(1)
		expect(ModelInstall.SlotOf("IceRockB3", "IceRockB")).toEqual(3)
	end)
	it("a model name that ends in a digit is stripped before the digits are read", function()
		expect(ModelInstall.SlotOf("Rock2", "Rock2")).toEqual(1)
		expect(ModelInstall.SlotOf("Rock23", "Rock2")).toEqual(3)
		expect(ModelInstall.SlotOf("Rock22", "Rock2")).toEqual(2)
	end)
	it("a bare number is that slot", function()
		expect(ModelInstall.SlotOf("3", "Mossbop")).toEqual(3)
	end)
	it("a name that does not start with the model name is read as it stands", function()
		expect(ModelInstall.SlotOf("Mesh4", "Mossbop")).toEqual(4)
		expect(ModelInstall.SlotOf("Mesh", "Mossbop")).toEqual(1)
	end)
	it("only trailing digits count", function()
		expect(ModelInstall.SlotOf("Body2Dark", "Mossbop")).toEqual(1)
		expect(ModelInstall.SlotOf("Mossbop2Dark", "Mossbop")).toEqual(1)
	end)
	it("every model's GLB part names read back as slots 1..N in order", function()
		for _, name in ipairs(sortedNames(ModelAssets.Materials)) do
			for slot = 1, #ModelAssets.Materials[name] do
				local partName = if slot == 1 then name else name .. tostring(slot)
				expect(ModelInstall.SlotOf(partName, name)).toEqual(slot)
			end
		end
	end)
end)

describe("ModelInstall.MaterialFor (Neon, Metal or SmoothPlastic)", function()
	local low = metalFrom - step
	it("emission above the neon threshold is Neon, whatever the metallic", function()
		expect(ModelInstall.MaterialFor(low, neonAbove + step, neonAbove, metalFrom)).toEqual("Neon")
		expect(ModelInstall.MaterialFor(metalFrom, neonAbove + step, neonAbove, metalFrom)).toEqual("Neon")
		expect(ModelInstall.MaterialFor(metalFrom + step, neonAbove + step, neonAbove, metalFrom)).toEqual("Neon")
	end)
	it("emission exactly at the neon threshold is not Neon", function()
		expect(ModelInstall.MaterialFor(low, neonAbove, neonAbove, metalFrom)).toEqual("SmoothPlastic")
		expect(ModelInstall.MaterialFor(metalFrom, neonAbove, neonAbove, metalFrom)).toEqual("Metal")
	end)
	it("emission below the neon threshold is not Neon", function()
		expect(ModelInstall.MaterialFor(low, neonAbove - step, neonAbove, metalFrom)).toEqual("SmoothPlastic")
		expect(ModelInstall.MaterialFor(metalFrom, neonAbove - step, neonAbove, metalFrom)).toEqual("Metal")
	end)
	it("metallic at the metal threshold or above is Metal", function()
		expect(ModelInstall.MaterialFor(metalFrom, neonAbove, neonAbove, metalFrom)).toEqual("Metal")
		expect(ModelInstall.MaterialFor(metalFrom + step, neonAbove, neonAbove, metalFrom)).toEqual("Metal")
	end)
	it("metallic just under the metal threshold is SmoothPlastic", function()
		expect(ModelInstall.MaterialFor(low, neonAbove, neonAbove, metalFrom)).toEqual("SmoothPlastic")
	end)
	it("the thresholds are the arguments, not constants", function()
		expect(ModelInstall.MaterialFor(step, step, step, step)).toEqual("Metal")
		expect(ModelInstall.MaterialFor(step, step + step, step, step + step)).toEqual("Neon")
		expect(ModelInstall.MaterialFor(step, step, step, step + step)).toEqual("SmoothPlastic")
	end)
	it("the data rows use all three materials, and every row named Glow is Neon", function()
		local seen = {}
		for _, name in ipairs(sortedNames(ModelAssets.Materials)) do
			for _, row in ipairs(ModelAssets.Materials[name]) do
				local kind = ModelInstall.MaterialFor(row[METALLIC_FIELD], row[EMISSION_FIELD], neonAbove, metalFrom)
				seen[kind] = true
				if row[NAME_FIELD] == "Glow" then
					assert(kind == "Neon", name .. " Glow row is " .. kind)
				end
			end
		end
		expect(seen.Neon).toEqual(true)
		expect(seen.Metal).toEqual(true)
		expect(seen.SmoothPlastic).toEqual(true)
	end)
end)

describe("ModelInstall.Order (slot, then original order)", function()
	it("an empty list gives an empty order", function()
		expect(#ModelInstall.Order({})).toEqual(0)
	end)
	it("sorts by slot", function()
		local order = ModelInstall.Order({
			{ slot = 3, order = 1 },
			{ slot = 1, order = 2 },
			{ slot = 2, order = 3 },
		})
		expect(table.concat(order, ",")).toEqual("2,3,1")
	end)
	it("ties on slot fall back to the original order", function()
		local order = ModelInstall.Order({
			{ slot = 1, order = 4 },
			{ slot = 1, order = 2 },
			{ slot = 2, order = 3 },
			{ slot = 1, order = 1 },
		})
		expect(table.concat(order, ",")).toEqual("4,2,1,3")
	end)
	it("entries equal in both keep their list positions", function()
		local order = ModelInstall.Order({
			{ slot = 2, order = 5 },
			{ slot = 1, order = 5 },
			{ slot = 1, order = 5 },
			{ slot = 2, order = 5 },
		})
		expect(table.concat(order, ",")).toEqual("2,3,1,4")
	end)
	it("returns every index once and leaves the input alone", function()
		local entries = {
			{ slot = 2, order = 1 },
			{ slot = 2, order = 2 },
			{ slot = 1, order = 3 },
		}
		local order = ModelInstall.Order(entries)
		expect(#order).toEqual(#entries)
		local seen = {}
		for _, index in ipairs(order) do
			seen[index] = true
		end
		for index = 1, #entries do
			expect(seen[index]).toEqual(true)
		end
		expect(entries[1].slot).toEqual(2)
		expect(entries[3].order).toEqual(3)
	end)
	it("a model's parts in slot order line up with its rows", function()
		-- GLB parts arrive in any descendant order; parts named <Model>, <Model>2... sort back into slot order.
		for _, name in ipairs(sortedNames(ModelAssets.Materials)) do
			local rows = ModelAssets.Materials[name]
			local entries = {}
			for slot = #rows, 1, -1 do
				local partName = if slot == 1 then name else name .. tostring(slot)
				table.insert(entries, { slot = ModelInstall.SlotOf(partName, name), order = #entries + 1 })
			end
			local order = ModelInstall.Order(entries)
			for position, index in ipairs(order) do
				expect(entries[index].slot).toEqual(position)
			end
		end
	end)
end)

describe("ModelInstall.IsGlowName", function()
	it("matches glow in any case, anywhere in the name", function()
		expect(ModelInstall.IsGlowName("Glow")).toEqual(true)
		expect(ModelInstall.IsGlowName("glow")).toEqual(true)
		expect(ModelInstall.IsGlowName("GLOW")).toEqual(true)
		expect(ModelInstall.IsGlowName("EmberGlow2")).toEqual(true)
		expect(ModelInstall.IsGlowName("Glowing")).toEqual(true)
	end)
	it("does not match other names", function()
		expect(ModelInstall.IsGlowName("Body")).toEqual(false)
		expect(ModelInstall.IsGlowName("")).toEqual(false)
		expect(ModelInstall.IsGlowName("Gl ow")).toEqual(false)
		expect(ModelInstall.IsGlowName("Gl.ow")).toEqual(false)
	end)
end)

describe("ModelAssets (the generated loader inputs)", function()
	it("every Materials row has 5 fields with a 6-hex-digit colour second", function()
		for _, name in ipairs(sortedNames(ModelAssets.Materials)) do
			local rows = ModelAssets.Materials[name]
			assert(#rows > 0, name .. " has no rows")
			for index, row in ipairs(rows) do
				local where = name .. " row " .. tostring(index)
				assert(#row == ROW_FIELDS, where .. " has " .. tostring(#row) .. " fields")
				assert(type(row[NAME_FIELD]) == "string" and row[NAME_FIELD] ~= "", where .. " has no part name")
				local hex = row[HEX_FIELD]
				assert(type(hex) == "string" and #hex == HEX_DIGITS and string.match(hex, "^%x+$") ~= nil, where .. " colour is not 6 hex digits")
				for _, field in ipairs({ ROUGHNESS_FIELD, METALLIC_FIELD, EMISSION_FIELD }) do
					assert(type(row[field]) == "number", where .. " field " .. tostring(field) .. " is not a number")
				end
			end
		end
	end)
	it("every PropNames key has an asset id", function()
		for _, name in ipairs(sortedNames(ModelAssets.PropNames)) do
			local id = ModelAssets.AssetIds[name]
			assert(type(id) == "number" and id > 0, name .. " has no asset id")
		end
	end)
	it("every model with Materials rows has an asset id, and the other way round", function()
		for _, name in ipairs(sortedNames(ModelAssets.Materials)) do
			assert(ModelAssets.AssetIds[name] ~= nil, name .. " has rows but no asset id")
		end
		for _, name in ipairs(sortedNames(ModelAssets.AssetIds)) do
			assert(ModelAssets.Materials[name] ~= nil, name .. " has an asset id but no rows")
		end
	end)
end)

-- The Surface pass: the plan for one slot, the material list, data/Textures and the generated Surfaces rows -----------------
local gloss = F.quarter -- stands in for Config.ModelGlossReflectance: the plan only passes the number through
local baseKinds = { "Neon", "Metal", "SmoothPlastic" } -- the three names MaterialFor can return
local uploaded: ModelInstall.TextureRow = { colorMap = F.one, normalMap = F.two, roughnessMap = F.one + F.two, tiling = { F.two, F.two } }
local halfUploaded: ModelInstall.TextureRow = { colorMap = F.one, normalMap = F.zero, roughnessMap = F.two, tiling = { F.one, F.one } }
local sets: { [string]: ModelInstall.TextureRow } = { fur = uploaded, moss = halfUploaded }
local surfaces = ModelAssets.Surfaces :: { [string]: { [string]: Types.SurfaceSpec } }
local EYE_SLOTS = { "EyeWhite", "EyeHighlight" }

describe("ModelInstall.SurfacePlan", function()
	it("a slot with no row keeps its base material, no reflectance and no maps", function()
		for _, base in ipairs(baseKinds) do
			local plan = ModelInstall.SurfacePlan(base, nil, sets, gloss)
			expect(plan.material).toEqual(base)
			expect(plan.reflectance).toEqual(F.zero)
			expect(plan.maps == nil).toEqual(true)
		end
	end)
	it("a row with no fields changes nothing either", function()
		local plan = ModelInstall.SurfacePlan("Metal", {}, sets, gloss)
		expect(plan.material).toEqual("Metal")
		expect(plan.reflectance).toEqual(F.zero)
		expect(plan.maps == nil).toEqual(true)
	end)
	it("an explicit material wins over the base, so Grass beats the emission rule", function()
		for _, base in ipairs(baseKinds) do
			expect(ModelInstall.SurfacePlan(base, { material = "Grass" }, sets, gloss).material).toEqual("Grass")
		end
	end)
	it("glossy asks for SmoothPlastic and the reflectance", function()
		local plan = ModelInstall.SurfacePlan("Metal", { glossy = true }, sets, gloss)
		expect(plan.material).toEqual("SmoothPlastic")
		expect(plan.reflectance).toEqual(gloss)
	end)
	it("glossy with an explicit material keeps that material and still gets the reflectance", function()
		local plan = ModelInstall.SurfacePlan("SmoothPlastic", { glossy = true, material = "Glass" }, sets, gloss)
		expect(plan.material).toEqual("Glass")
		expect(plan.reflectance).toEqual(gloss)
	end)
	it("glossy = false is the same as no field", function()
		local plan = ModelInstall.SurfacePlan("Neon", { glossy = false }, sets, gloss)
		expect(plan.material).toEqual("Neon")
		expect(plan.reflectance).toEqual(F.zero)
	end)
	it("a material off the list is ignored: the base, or SmoothPlastic when glossy", function()
		expect(ModelInstall.SurfacePlan("Metal", { material = "NotAMaterial" }, sets, gloss).material).toEqual("Metal")
		expect(ModelInstall.SurfacePlan("Metal", { material = "NotAMaterial", glossy = true }, sets, gloss).material).toEqual("SmoothPlastic")
	end)
	it("the maps are the texture's three ids once all of them are non-zero", function()
		local plan = ModelInstall.SurfacePlan("SmoothPlastic", { texture = "fur" }, sets, gloss)
		local maps = plan.maps
		assert(maps ~= nil, "an uploaded set gave no maps")
		expect(maps.colorMap).toEqual(uploaded.colorMap)
		expect(maps.normalMap).toEqual(uploaded.normalMap)
		expect(maps.roughnessMap).toEqual(uploaded.roughnessMap)
	end)
	it("a half-uploaded set, an unknown key and a spec with no texture give no maps", function()
		expect(ModelInstall.SurfacePlan("SmoothPlastic", { texture = "moss" }, sets, gloss).maps == nil).toEqual(true)
		expect(ModelInstall.SurfacePlan("SmoothPlastic", { texture = "velvet" }, sets, gloss).maps == nil).toEqual(true)
		expect(ModelInstall.SurfacePlan("SmoothPlastic", { material = "Grass" }, sets, gloss).maps == nil).toEqual(true)
	end)
	it("a texture alone leaves the material and the reflectance alone", function()
		local plan = ModelInstall.SurfacePlan("Metal", { texture = "fur" }, sets, gloss)
		expect(plan.material).toEqual("Metal")
		expect(plan.reflectance).toEqual(F.zero)
	end)
end)

describe("ModelInstall.MapsOf", function()
	it("needs a row and every id above zero", function()
		expect(ModelInstall.MapsOf(nil) == nil).toEqual(true)
		expect(ModelInstall.MapsOf(halfUploaded) == nil).toEqual(true)
		expect(ModelInstall.MapsOf({ colorMap = F.zero, normalMap = F.one, roughnessMap = F.one, tiling = { F.one, F.one } }) == nil).toEqual(true)
		expect(ModelInstall.MapsOf({ colorMap = F.one, normalMap = F.one, roughnessMap = F.zero, tiling = { F.one, F.one } }) == nil).toEqual(true)
		expect(ModelInstall.MapsOf(uploaded) ~= nil).toEqual(true)
	end)
end)

describe("ModelInstall.SurfaceMaterials", function()
	it("has no duplicates and holds the three names MaterialFor returns", function()
		local seen: { [string]: boolean } = {}
		for _, name in ipairs(ModelInstall.SurfaceMaterials) do
			assert(not seen[name], name .. " is listed twice")
			seen[name] = true
		end
		for _, base in ipairs(baseKinds) do
			assert(seen[base], base .. " is missing from SurfaceMaterials")
		end
	end)
	it("IsSurfaceMaterial agrees with the list", function()
		for _, name in ipairs(ModelInstall.SurfaceMaterials) do
			expect(ModelInstall.IsSurfaceMaterial(name)).toEqual(true)
		end
		expect(ModelInstall.IsSurfaceMaterial("NotAMaterial")).toEqual(false)
		expect(ModelInstall.IsSurfaceMaterial("")).toEqual(false)
	end)
end)

describe("data/Textures", function()
	it("every row has three Image ids (whole numbers, zero until uploaded) and a positive { u, v } tiling", function()
		for _, key in ipairs(sortedNames(Textures)) do
			local row = Textures[key] :: Types.TextureRow
			for _, id in ipairs({ row.colorMap, row.normalMap, row.roughnessMap }) do
				assert(id >= F.zero and id == math.floor(id), key .. " has an id that is not a whole number")
			end
			assert(#row.tiling == F.two, key .. " tiling is not { u, v }")
			assert(row.tiling[1] > F.zero and row.tiling[2] > F.zero, key .. " tiling must be positive")
		end
	end)
end)

describe("ModelAssets.Surfaces (the generated rows)", function()
	it("every row names a model with an asset id and a slot its Materials rows list, with known fields only", function()
		for _, model in ipairs(sortedNames(surfaces)) do
			assert(ModelAssets.AssetIds[model] ~= nil, model .. " has Surfaces rows but no asset id")
			local slotNames: { [string]: boolean } = {}
			for _, row in ipairs(ModelAssets.Materials[model]) do
				slotNames[row[NAME_FIELD] :: string] = true
			end
			for _, slot in ipairs(sortedNames(surfaces[model])) do
				local where = model .. "." .. slot
				assert(slotNames[slot], where .. " is not one of the model's slots")
				local fields = 0
				for field in pairs(surfaces[model][slot]) do
					fields += 1
					assert(field == "material" or field == "texture" or field == "glossy", where .. " has an unknown field " .. tostring(field))
				end
				assert(fields > 0, where .. " is an empty row")
			end
		end
	end)
	it("every material is on the list, every texture exists, and glossy is only ever true", function()
		for _, model in ipairs(sortedNames(surfaces)) do
			for _, slot in ipairs(sortedNames(surfaces[model])) do
				local spec = surfaces[model][slot]
				local where = model .. "." .. slot
				if spec.material ~= nil then
					assert(ModelInstall.IsSurfaceMaterial(spec.material), where .. " material " .. spec.material .. " is not on the list")
				end
				if spec.texture ~= nil then
					assert((Textures :: { [string]: Types.TextureRow })[spec.texture] ~= nil, where .. " names the unknown texture " .. spec.texture)
				end
				assert(spec.glossy == nil or spec.glossy == true, where .. " glossy must be true or absent")
			end
		end
	end)
	it("a model with any surface row has both eye slots glossy", function()
		for _, model in ipairs(sortedNames(surfaces)) do
			for _, slot in ipairs(EYE_SLOTS) do
				local spec = surfaces[model][slot]
				assert(spec ~= nil and spec.glossy == true, model .. "." .. slot .. " is not glossy")
			end
		end
	end)
	it("the planned material of every Surfaces row is a name the plan can return", function()
		for _, model in ipairs(sortedNames(surfaces)) do
			for _, slot in ipairs(sortedNames(surfaces[model])) do
				local plan = ModelInstall.SurfacePlan(baseKinds[1], surfaces[model][slot], Textures :: { [string]: Types.TextureRow }, gloss)
				assert(ModelInstall.IsSurfaceMaterial(plan.material), model .. "." .. slot .. " plans " .. plan.material)
			end
		end
	end)
end)
return true
