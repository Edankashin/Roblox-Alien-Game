--!strict
-- Install the uploaded models into the open place. Run it in Studio's command bar (View > Command Bar,
-- paste the whole file, press Enter) or through the Studio MCP execute_luau tool. Studio must be signed
-- in as the user (or a member of the group) that owns the assets.
--
-- 1. python3 tools/upload_assets.py            (once; GLB by default; fills assets/models/asset_ids.json;
--                                               add --redo to replace ids from an earlier FBX run)
-- 2. python3 tools/upload_assets.py --emit-luau | pbcopy
-- 3. Replace the three tables between the PASTE markers below with the output, then run this file.
--
-- For each entry: InsertService:LoadAsset(assetId) inside a pcall, take the Model inside, name it
-- exactly the key, and parent it under ReplicatedStorage.Models (aliens) or ReplicatedStorage.Models.Props
-- (names in PROP_NAMES). An existing child of the same name is replaced only after the new one loaded,
-- so a failed or still-moderated asset leaves the old model alone. Safe to run again.
--
-- Colours (found in Studio 2026-10-05): a GLB upload arrives as one MeshPart per material slot, named
-- <Name>, <Name>2, <Name>3... in slot order, all grey with no TextureID. MATERIALS (from each model's
-- materials.json, slot order) restores them: the parts are sorted by the numeric suffix of their name
-- (no suffix = 1, Name2 = 2, ...) and part i gets entry i: Color from the hex; Material Neon when
-- emission > 0, Metal when metallic >= 0.5, else SmoothPlastic; and the part is renamed to the material
-- name (Body, EyeWhite, Glow...) so name-based rules keep working (a part named Glow, Props.Tint
-- skipping Neon). When the counts differ, the parts that exist are coloured and a warn names the model
-- and both counts. Roughness is in the table but Roblox has no per-part roughness, so it is not applied.
-- A model without a MATERIALS entry keeps the old rule: a prop MeshPart named "Glow" gets Neon.
-- Folder names match Config.ModelFolderName and Config.PropsFolderName in src/shared/data/Config.luau.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MODELS_FOLDER = "Models"
local PROPS_FOLDER = "Props"
-- Same fix-ups the by-hand import steps ask for (Map-Dressing.md, import-model skill): every part
-- Anchored; creatures also CanCollide and CanQuery off; a prop's MeshPart named "Glow" gets Neon
-- (only for a model with no MATERIALS entry; with one, the material rules above decide).
local NORMALISE = true
local NEON_EMISSION_ABOVE = 0 -- emission > this: Neon
local METAL_METALLIC_FROM = 0.5 -- metallic >= this: Metal

-- BEGIN PASTE: output of `python3 tools/upload_assets.py --emit-luau`
local ASSET_IDS: { [string]: number } = {
	BuildStation = 71841484152981,
	Buzzlebee = 88312343533381,
	Capybubble = 118785819297141,
	Chipmole = 116415285718913,
	Drippo = 132968896843991,
	Emberchin = 117002896928472,
	Fenripup = 128458850464368,
	Flapsicle = 74126006882983,
	Flufflet = 71427322162409,
	Frostfang = 106549059040288,
	Gaiabloom = 119819939062037,
	GatherStation = 131146076942669,
	GeyserCone = 95167593008344,
	Glimmo = 81746327531541,
	Gloomoth = 119571917446181,
	HeaterLamp = 114242165498092,
	IceRock = 112924370616190,
	IceRockB = 112678169840848,
	IceSpire = 98203972327875,
	Kettlepuff = 114087558859719,
	Lanternewt = 118057043685924,
	MeadowRock = 74484453710473,
	MeadowRockB = 95589978973116,
	MeadowTree = 115248150125825,
	MeadowTreeB = 116875886930580,
	Mossbop = 75392166239469,
	Panpipe = 78135237078182,
	Pebblet = 113486299211607,
	Pedestal = 79085049086276,
	Pengoo = 95704667554643,
	Puffpuff = 72546260324676,
	Radish = 84584822467630,
	Reindazzle = 106289045971403,
	Rocklobber = 84724930364833,
	Shellberg = 83475059423653,
	Shimmerlynx = 128963124361953,
	ShipHull = 89734888134185,
	ShrineStone = 74997505224230,
	Skaddle = 79167335486827,
	Snailbyte = 80661270931382,
	SnowPine = 125698340054887,
	Snowbun = 101344028973049,
	SparkStation = 128207391519162,
	Sparkfox = 74103422841124,
	Thunderhog = 133800077744332,
	Toastoad = 133730607533303,
	Twiglet = 140179596727863,
	Zapfinch = 85477205832415,
}
local PROP_NAMES: { [string]: boolean } = {
	BuildStation = true,
	GatherStation = true,
	GeyserCone = true,
	HeaterLamp = true,
	IceRock = true,
	IceRockB = true,
	IceSpire = true,
	MeadowRock = true,
	MeadowRockB = true,
	MeadowTree = true,
	MeadowTreeB = true,
	Pedestal = true,
	ShipHull = true,
	ShrineStone = true,
	SnowPine = true,
	SparkStation = true,
}
-- each row: { name, hex, roughness, metallic, emission }, in material slot order
local MATERIALS: { [string]: { { string | number } } } = {
}
-- END PASTE

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("Folder") then
			return existing
		end
		error(("%s.%s exists but is a %s, not a Folder"):format(parent:GetFullName(), name, existing.ClassName))
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- LoadAsset returns a container Model. The imported Model is normally its only child; when the
-- parts sit directly in the container, the container is the model.
local function pickModel(container: Instance): Model?
	for _, child in container:GetChildren() do
		if child:IsA("Model") then
			return child
		end
	end
	if container:IsA("Model") and container:FindFirstChildWhichIsA("BasePart", true) then
		return container
	end
	return nil
end

type PartSlot = { part: MeshPart, slot: number, order: number }

-- Slot number of a GLB part from its name: no suffix = 1, "<Name>2" = 2. The model's own name is
-- stripped first, so a model whose name ends in a digit still reads right.
local function slotOf(partName: string, modelName: string): number
	local rest = partName
	if rest:sub(1, #modelName) == modelName then
		rest = rest:sub(#modelName + 1)
	end
	local digits = rest:match("(%d+)$")
	if digits then
		return tonumber(digits) or 1
	end
	return 1
end

-- Colours the model's MeshParts from its MATERIALS rows. Returns how many parts were coloured.
local function applyMaterials(model: Model, name: string, rows: { { string | number } }): number
	local slots: { PartSlot } = {}
	for order, descendant in model:GetDescendants() do
		if descendant:IsA("MeshPart") then
			table.insert(slots, { part = descendant, slot = slotOf(descendant.Name, name), order = order })
		end
	end
	table.sort(slots, function(a: PartSlot, b: PartSlot): boolean
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end
		return a.order < b.order
	end)
	if #slots ~= #rows then
		warn(("install_models: %s has %d MeshParts but MATERIALS lists %d; colouring the parts that exist"):format(
			name,
			#slots,
			#rows
		))
	end
	local coloured = 0
	for index, slot in slots do
		local row = rows[index]
		if not row then
			break
		end
		local materialName = row[1] :: string
		local hex = row[2] :: string
		local metallic = row[4] :: number
		local emission = row[5] :: number
		local part = slot.part
		part.Color = Color3.fromHex(hex)
		if emission > NEON_EMISSION_ABOVE then
			part.Material = Enum.Material.Neon
		elseif metallic >= METAL_METALLIC_FROM then
			part.Material = Enum.Material.Metal
		else
			part.Material = Enum.Material.SmoothPlastic
		end
		part.Name = materialName
		coloured += 1
	end
	return coloured
end

local function normalise(model: Model, isProp: boolean, hasMaterials: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if not isProp then
				descendant.CanCollide = false
				descendant.CanQuery = false
			end
			if
				isProp
				and not hasMaterials
				and descendant:IsA("MeshPart")
				and descendant.Name:lower():find("glow", 1, true)
			then
				descendant.Material = Enum.Material.Neon
			end
		end
	end
end

local function install(name: string, assetId: number, models: Folder, props: Folder): (boolean, string)
	local ok, loaded = pcall(function(): Instance
		return InsertService:LoadAsset(assetId)
	end)
	if not ok then
		return false, tostring(loaded)
	end
	local container = loaded :: Instance
	local model = pickModel(container)
	if not model then
		container:Destroy()
		return false, "asset loaded but holds no Model with parts"
	end
	local isProp = PROP_NAMES[name] == true
	local target = if isProp then props else models
	model.Parent = nil
	model.Name = name
	if container ~= model then
		container:Destroy()
	end
	local rows = MATERIALS[name]
	local note = ""
	if rows then
		note = (", %d parts coloured"):format(applyMaterials(model, name, rows))
	end
	if NORMALISE then
		normalise(model, isProp, rows ~= nil)
	end
	local old = target:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model.Parent = target
	return true, target:GetFullName() .. note
end

local function main()
	local names: { string } = {}
	for name in ASSET_IDS do
		table.insert(names, name)
	end
	table.sort(names)
	if #names == 0 then
		print("install_models: ASSET_IDS is empty; paste the output of `python3 tools/upload_assets.py --emit-luau`")
		return
	end

	local models = ensureFolder(ReplicatedStorage, MODELS_FOLDER)
	local props = ensureFolder(models, PROPS_FOLDER)

	local installed = 0
	local failed = 0
	for _, name in names do
		local assetId = ASSET_IDS[name]
		local ok, detail = install(name, assetId, models, props)
		if ok then
			installed += 1
			print(("ok    %s <- %d  (%s)"):format(name, assetId, detail))
		else
			failed += 1
			warn(("FAIL  %s <- %d  %s"):format(name, assetId, detail))
		end
	end
	print(("install_models: %d installed, %d failed, %d total"):format(installed, failed, #names))
	if failed > 0 then
		print("A failure right after upload usually means the asset is still in moderation (up to a few hours); run again later.")
	end
end

main()
