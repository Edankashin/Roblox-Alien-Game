--!strict
-- Install the uploaded models into the open place. Run it in Studio's command bar (View > Command Bar,
-- paste the whole file, press Enter) or through the Studio MCP execute_luau tool. Studio must be signed
-- in as the user (or a member of the group) that owns the assets.
--
-- 1. python3 tools/upload_assets.py            (once; fills assets/models/asset_ids.json)
-- 2. python3 tools/upload_assets.py --emit-luau | pbcopy
-- 3. Replace the two tables between the PASTE markers below with the output, then run this file.
--
-- For each entry: InsertService:LoadAsset(assetId) inside a pcall, take the Model inside, name it
-- exactly the key, and parent it under ReplicatedStorage.Models (aliens) or ReplicatedStorage.Models.Props
-- (names in PROP_NAMES). An existing child of the same name is replaced only after the new one loaded,
-- so a failed or still-moderated asset leaves the old model alone. Safe to run again.
-- Folder names match Config.ModelFolderName and Config.PropsFolderName in src/shared/data/Config.luau.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MODELS_FOLDER = "Models"
local PROPS_FOLDER = "Props"
-- Same fix-ups the by-hand import steps ask for (Map-Dressing.md, import-model skill): every part
-- Anchored; creatures also CanCollide and CanQuery off; a prop's MeshPart named "Glow" gets Neon.
local NORMALISE = true

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

local function normalise(model: Model, isProp: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if not isProp then
				descendant.CanCollide = false
				descendant.CanQuery = false
			end
			if isProp and descendant:IsA("MeshPart") and descendant.Name:lower():find("glow", 1, true) then
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
	if NORMALISE then
		normalise(model, isProp)
	end
	local old = target:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model.Parent = target
	return true, target:GetFullName()
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
