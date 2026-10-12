--!strict
-- ServerScriptService.Server.Services.Models: the runtime model loader. The 53 species and prop meshes
-- (ReplicatedStorage.<Config.ModelFolderName>.<Name>, and .<Config.PropsFolderName>.<Name> for the scenery) were
-- only ever installed into the Studio place files by hand (tools/studio/install_models.luau), and Rojo carries no
-- meshes, so a place built from the repo (tools/publish.py) showed placeholder shapes. This service loads them at
-- boot from their uploaded asset ids (data/ModelAssets, generated from assets/models/asset_ids.json) with
-- InsertService:LoadAsset, so a Rojo-built place has every model and publishing needs no Studio.
--
-- Each load ports the installer exactly: pick the Model out of the loaded container, name it, colour its MeshParts
-- from ModelAssets.Materials (slot order, ModelInstall.SlotOf / Order / MaterialFor, the part renamed to the row's
-- name after colouring), normalise (every BasePart Anchored; a creature also CanCollide and CanQuery off; a prop with
-- no Materials rows gets Neon on its glow-named MeshParts), then parent it to its folder. A name whose folder already
-- holds a Model of that name is "present" and skipped: that is the Studio case, where the hand-installed models stay
-- as they are and a connected Studio place loads nothing. A failure (LoadAsset errors, or the asset holds no Model
-- with parts) leaves the folder untouched, so the client keeps its placeholder; a just-uploaded asset can sit in
-- moderation for a few hours, and Retry tries the failed names again.
--
-- Boot position: before Meadow, which places the world's props through Shared/Props.Place at Init, so Models.Init
-- waits (at most Config.ModelLoadTimeoutSeconds) for the loads before the world is built. A load still running after
-- that keeps going and parents its model when it finishes: the client looks models up with FindFirstChild at render
-- time, so a late model is used by later spawns and by the next server's world. It requires only shared code.
--
-- LoadAsset only loads assets the experience's owner owns (or that are public models): a collaborator's Studio may
-- fail every load with a permission error and fall back to placeholders, which is harmless. Nothing here touches
-- Scrap, a catch or any outcome; it only decides which meshes exist.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local ModelAssets = require(Shared.data.ModelAssets)
local ModelInstall = require(Shared.ModelInstall)

local Models = {}

export type Status = {
	loaded: number,
	present: number,
	failed: number,
	pending: number,
	failedNames: { string },
}

local POLL_SECONDS = 0.1 -- how often Init checks whether the loads have finished
local FAILED_NAMES_SHOWN = 10 -- the boot warning names this many failed models

-- The generated tables, typed as maps (their literal types list every key).
local assetIds = ModelAssets.AssetIds :: { [string]: number }
local propNames = ModelAssets.PropNames :: { [string]: boolean }
local materialRows = ModelAssets.Materials

local materialByName: { [string]: Enum.Material } = {
	Neon = Enum.Material.Neon,
	Metal = Enum.Material.Metal,
	SmoothPlastic = Enum.Material.SmoothPlastic,
}

-- State ------------------------------------------------------------------

local modelsFolder: Folder? = nil
local propsFolder: Folder? = nil
local loadedCount = 0
local presentCount = 0
local pendingCount = 0 -- queued or in flight
local failedReasons: { [string]: string } = {} -- failed name -> why (the first line of the error)
local queue: { string } = {}
local queueHead = 1 -- the next name in `queue` a worker takes
local workerCount = 0
local batchStartedAt = os.clock() -- when the loads now running (or last run) were queued
local bootReported = false -- Init has printed its line; later drains print their own

local function failedList(): { string }
	local names: { string } = {}
	for name in pairs(failedReasons) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- Loading ----------------------------------------------------------------

-- LoadAsset returns a container Model. The imported Model is normally its only child; when the parts sit directly
-- in the container, the container is the model.
local function pickModel(container: Instance): Model?
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Model") then
			return child
		end
	end
	if container:IsA("Model") and container:FindFirstChildWhichIsA("BasePart", true) then
		return container
	end
	return nil
end

-- Colours the model's MeshParts from its Materials rows and renames each to its row's name. Returns how many parts
-- were coloured. Warns once when the part count and the row count differ.
local function applyMaterials(model: Model, name: string, rows: { { string | number } }): number
	local parts: { MeshPart } = {}
	local entries: { ModelInstall.SlotEntry } = {}
	for order, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			table.insert(parts, descendant)
			table.insert(entries, { slot = ModelInstall.SlotOf(descendant.Name, name), order = order })
		end
	end
	if #parts ~= #rows then
		warn(("[%s] Models: %s has %d MeshParts but ModelAssets.Materials lists %d; colouring the parts that exist"):format(Config.WorkingTitle, name, #parts, #rows))
	end
	local coloured = 0
	for position, index in ipairs(ModelInstall.Order(entries)) do
		local row = rows[position]
		if not row then
			break
		end
		local part = parts[index]
		local metallic = row[4] :: number
		local emission = row[5] :: number
		part.Color = Color3.fromHex(row[2] :: string)
		part.Material = materialByName[ModelInstall.MaterialFor(metallic, emission, ModelAssets.NeonEmissionAbove, ModelAssets.MetalMetallicFrom)]
		part.Name = row[1] :: string
		coloured += 1
	end
	return coloured
end

local function normalise(model: Model, isProp: boolean, hasMaterials: boolean)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			if not isProp then
				descendant.CanCollide = false
				descendant.CanQuery = false
			end
			if isProp and not hasMaterials and descendant:IsA("MeshPart") and ModelInstall.IsGlowName(descendant.Name) then
				descendant.Material = Enum.Material.Neon
			end
		end
	end
end

-- One model, start to finish. Returns nil when it landed in its folder, else the reason it did not (nothing is
-- parented then). An error thrown outside the LoadAsset pcall reaches the worker's own pcall.
local function load(name: string): string?
	local models, props = modelsFolder, propsFolder
	if not models or not props then
		return "the model folders are missing"
	end
	local id = assetIds[name]
	local ok, loaded = pcall(function(): Instance
		return InsertService:LoadAsset(id)
	end)
	if not ok then
		return tostring(loaded)
	end
	local container = loaded :: Instance
	local model = pickModel(container)
	if not model or not model:FindFirstChildWhichIsA("BasePart", true) then
		container:Destroy()
		return "asset loaded but holds no Model with parts"
	end
	local isProp = propNames[name] == true
	local target = if isProp then props else models
	model.Parent = nil -- detach first: destroying the container below would take the model with it
	model.Name = name
	if container ~= model then
		container:Destroy()
	end
	local rows = materialRows[name]
	if rows then
		applyMaterials(model, name, rows)
	end
	if ModelAssets.Normalise then
		normalise(model, isProp, rows ~= nil)
	end
	local old = target:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model.Parent = target
	return nil
end

local function summary(): string
	return ("[%s] Models: %d loaded, %d present, %d failed, %d pending after %.1f s"):format(
		Config.WorkingTitle,
		loadedCount,
		presentCount,
		#failedList(),
		pendingCount,
		os.clock() - batchStartedAt
	)
end

-- The summary line, and a warning naming the first failures when there are any.
local function report()
	print(summary())
	local names = failedList()
	if #names == 0 then
		return
	end
	local shown: { string } = {}
	for index = 1, math.min(#names, FAILED_NAMES_SHOWN) do
		table.insert(shown, names[index])
	end
	warn(
		("[%s] Models: %d failed (%s%s); the client keeps its placeholders for them. First error, %s: %s. A just-uploaded asset can be in moderation for a few hours; Retry (Studio: /models retry) loads the failed ones again."):format(
			Config.WorkingTitle,
			#names,
			table.concat(shown, ", "),
			if #names > #shown then ", ..." else "",
			names[1],
			failedReasons[names[1]]
		)
	)
end

-- A pool worker: takes names from the shared queue until it is empty. The pool's size is
-- Config.ModelLoadConcurrency, so at most that many LoadAsset calls are in flight at once.
local function worker()
	while queueHead <= #queue do
		local name = queue[queueHead]
		queueHead += 1
		local ok, reason = pcall(load, name)
		if ok and reason == nil then
			loadedCount += 1
		else
			failedReasons[name] = string.match(tostring(reason), "^[^\n]*") or ""
		end
		pendingCount -= 1
	end
	workerCount -= 1
	-- The last worker out after Init has stopped waiting (late loads, or a Retry) reports the batch.
	if workerCount == 0 and pendingCount == 0 and bootReported then
		report()
	end
end

local function enqueue(names: { string })
	if pendingCount == 0 then
		batchStartedAt = os.clock()
	end
	for _, name in ipairs(names) do
		table.insert(queue, name)
	end
	pendingCount += #names
	local limit = math.max(1, Config.ModelLoadConcurrency)
	while workerCount < limit and workerCount < #queue - queueHead + 1 do
		workerCount += 1
		task.spawn(worker)
	end
end

-- Folders ----------------------------------------------------------------

-- The child Folder `name` of `parent`, created when missing. Nil (with a warning) when a same-named child exists
-- and is not a Folder.
local function ensureFolder(parent: Instance, name: string): Folder?
	local existing = parent:FindFirstChild(name)
	if existing then
		if existing:IsA("Folder") then
			return existing
		end
		warn(("[%s] Models: %s exists but is a %s, not a Folder; the loader is off"):format(Config.WorkingTitle, existing:GetFullName(), existing.ClassName))
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- Public API -------------------------------------------------------------

-- The counts so far and the failed names (sorted). Loads still pending are not in any other count.
function Models.Status(): Status
	local names = failedList()
	return {
		loaded = loadedCount,
		present = presentCount,
		failed = #names,
		pending = pendingCount,
		failedNames = names,
	}
end

-- Queues every failed name again on the same pool and returns how many were queued (the pool prints its line
-- when the last of them finishes). Studio's /models retry calls it.
function Models.Retry(): number
	local names = failedList()
	for _, name in ipairs(names) do
		failedReasons[name] = nil
	end
	if #names > 0 then
		enqueue(names)
	end
	return #names
end

function Models.Init()
	if not Config.LoadModelsAtBoot then
		print(("[%s] Models: runtime loading is off (Config.LoadModelsAtBoot); models installed in the place stay, the rest show placeholders"):format(Config.WorkingTitle))
		return
	end
	local models = ensureFolder(ReplicatedStorage, Config.ModelFolderName)
	if not models then
		return
	end
	local props = ensureFolder(models, Config.PropsFolderName)
	if not props then
		return
	end
	modelsFolder, propsFolder = models, props

	local names: { string } = {}
	for name in pairs(assetIds) do
		table.insert(names, name)
	end
	table.sort(names)

	batchStartedAt = os.clock()
	local toLoad: { string } = {}
	for _, name in ipairs(names) do
		local target = if propNames[name] == true then props else models
		local existing = target:FindFirstChild(name)
		if existing and existing:IsA("Model") then
			presentCount += 1
		else
			table.insert(toLoad, name)
		end
	end
	if #toLoad > 0 then
		enqueue(toLoad)
	end

	while pendingCount > 0 and os.clock() - batchStartedAt < Config.ModelLoadTimeoutSeconds do
		task.wait(POLL_SECONDS)
	end
	bootReported = true
	report()
end

return Models
