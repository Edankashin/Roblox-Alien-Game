--!strict
-- ServerScriptService.Server.Services.Spawner: keeps wild aliens around every player.
-- Each wild alien is a lightweight record here plus one anchored Part under Workspace.World.Wild
-- carrying attributes (SpeciesId, Tier, Overlay, SpawnId, Condition, Biome). No Humanoids, no server
-- animation: the client bobs and labels them. The server owns which species exist where and when,
-- so the tier roll, the overlay roll and the condition gating all live here. A spawn's biome is the
-- one its landing point is in (Shared/Biomes), so the Forest grove and the Cave get their own tables.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Tiers = require(Shared.data.Tiers)
local Species = require(Shared.data.Species)
local Spawns = require(Shared.data.Spawns)
local Overlays = require(Shared.data.Overlays)
local Biomes = require(Shared.Biomes)
local WorldClock = require(script.Parent.WorldClock)
local Meadow = require(script.Parent.Meadow)

local Spawner = {}

export type WildSpawn = {
	spawnId: string,
	species: string,
	tier: Types.Tier,
	overlay: Types.Overlay,
	condition: Types.Condition, -- the condition it needs; "Any" never despawns for weather
	biome: Types.Biome, -- where it landed; its species came from this biome's table
	position: Vector3,
	part: Part,
}

export type RemoveReason = "caught" | "fled" | "despawn" | "cull"

type PendingRespawn = { position: Vector3, readyAt: number }

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Block = Enum.PartType.Block,
	Cylinder = Enum.PartType.Cylinder,
}
local PLACEMENT_ATTEMPTS = 12
local BASE_SIZE = 2 -- studs across at placeholder scale 1; also the nominal size a point is seated with before the species is known

local rng = Random.new()
local spawns: { [string]: WildSpawn } = {}
local pending: { PendingRespawn } = {}
local wildFolder: Folder? = nil

local function folder(): Folder
	if wildFolder then
		return wildFolder
	end
	local world = Workspace:WaitForChild("World")
	local wild = world:FindFirstChild("Wild")
	if not wild then
		wild = Instance.new("Folder")
		wild.Name = "Wild"
		wild.Parent = world
	end
	wildFolder = wild :: Folder
	return wild :: Folder
end

-- Luck scales every share above Common; Common takes what is left (or 0 if luck pushes past 100%).
local function rollTier(luck: number): string
	luck = math.clamp(luck, 1, Config.LuckCap)
	local weights: { [string]: number } = {}
	local upperTotal = 0
	for _, tier in ipairs(Tiers.Order) do
		if tier ~= "Common" then
			local w = Tiers.Tiers[tier].share * luck
			weights[tier] = w
			upperTotal += w
		end
	end
	weights.Common = math.max(0, 100 - upperTotal)
	local total = math.max(100, upperTotal)
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, tier in ipairs(Tiers.Order) do
		acc += weights[tier]
		if roll < acc then
			return tier
		end
	end
	return "Common"
end

local function availableSpecies(biome: Types.Biome, condition: Types.Condition): { string }
	local table_ = Spawns.Biomes[biome]
	local out: { string } = {}
	if not table_ then
		return out
	end
	for _, id in ipairs(table_.Any or {}) do
		table.insert(out, id)
	end
	if condition ~= "Any" then
		for _, id in ipairs(table_[condition] or {}) do
			table.insert(out, id)
		end
	end
	return out
end

-- Choose a species of the rolled tier that can appear in the biome now; fall back down the tier order
-- if none can.
local function chooseSpecies(biome: Types.Biome, tier: string, condition: Types.Condition): Types.SpeciesDef?
	local available = availableSpecies(biome, condition)
	local tierIndex = table.find(Tiers.Order, tier) or 1
	for index = tierIndex, 1, -1 do
		local wanted = Tiers.Order[index]
		local candidates: { Types.SpeciesDef } = {}
		for _, id in ipairs(available) do
			local def = Species.ById[id]
			if def and def.tier == wanted then
				table.insert(candidates, def)
			end
		end
		if #candidates > 0 then
			return candidates[rng:NextInteger(1, #candidates)]
		end
	end
	return nil
end

local function rollOverlay(): Types.Overlay
	local roll = rng:NextNumber(0, 100)
	local acc = 0
	for _, name in ipairs(Overlays.Order) do
		acc += Overlays.Overlays[name].chance
		if roll < acc then
			return name :: Types.Overlay
		end
	end
	return "None"
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function flatDistance(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function tooCloseToOthers(position: Vector3): boolean
	for _, spawn in pairs(spawns) do
		if flatDistance(spawn.position, position) < Config.SpawnMinSeparation then
			return true
		end
	end
	return false
end

-- A random walkable point within SpawnRadius of `around`, clear of the camp pad and other spawns. The
-- caller re-seats Y once it knows the species; separation is judged on the flat distance only.
local function findPosition(around: Vector3, size: number): Vector3?
	local half = Meadow.GetHalfSize() - 2
	local floorTop = Meadow.GetFloorTop()
	local campClear = Meadow.GetCampRadius() + Config.SpawnCampClearance
	for _ = 1, PLACEMENT_ATTEMPTS do
		local angle = rng:NextNumber(0, math.pi * 2)
		-- sqrt keeps the distribution even over the disc instead of bunching at the centre
		local radius = Config.SpawnRadius * math.sqrt(rng:NextNumber())
		radius = math.max(radius, Config.SpawnMinDistanceFromPlayer)
		local x = math.clamp(around.X + math.cos(angle) * radius, -half, half)
		local z = math.clamp(around.Z + math.sin(angle) * radius, -half, half)
		local position = Vector3.new(x, floorTop + Config.WildHoverStuds + size / 2, z)
		if math.sqrt(x * x + z * z) >= campClear and not tooCloseToOthers(position) then
			return position
		end
	end
	return nil
end

local function createSpawn(around: Vector3, condition: Types.Condition): WildSpawn?
	-- where it lands decides which biome's table it rolls from
	local flat = findPosition(around, BASE_SIZE)
	if not flat then
		return nil
	end
	local biome: Types.Biome = Biomes.At(flat)
	local tier = rollTier(1.0) -- luck hook: server luck, showers and charms plug in here later
	local def = chooseSpecies(biome, tier, condition)
	if not def then
		return nil
	end
	local size = BASE_SIZE * def.placeholder.scale
	local position = Vector3.new(flat.X, Meadow.GetSurfaceTop(flat) + Config.WildHoverStuds + size / 2, flat.Z)
	local spawnId = HttpService:GenerateGUID(false)
	local overlay: Types.Overlay = rollOverlay()

	local part = Instance.new("Part")
	part.Name = def.id
	part.Shape = SHAPES[def.placeholder.shape] or Enum.PartType.Ball
	part.Size = Vector3.one * size
	local cframe = CFrame.new(position)
	if def.placeholder.shape == "Cylinder" then
		cframe = cframe * CFrame.Angles(0, 0, math.rad(90)) -- stand it upright
	end
	part.CFrame = cframe
	part.Color = Color3.fromHex(def.placeholder.color)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true -- the client taps aliens by raycast
	part.CastShadow = false
	part:SetAttribute("SpeciesId", def.id)
	part:SetAttribute("Tier", def.tier)
	part:SetAttribute("Overlay", overlay)
	part:SetAttribute("SpawnId", spawnId)
	part:SetAttribute("Condition", def.condition)
	part:SetAttribute("Biome", biome)
	part.Parent = folder()

	local spawn: WildSpawn = {
		spawnId = spawnId,
		species = def.id,
		tier = def.tier,
		overlay = overlay,
		condition = def.condition,
		biome = biome,
		position = position,
		part = part,
	}
	spawns[spawnId] = spawn
	return spawn
end

local function nearCount(around: Vector3, now: number): number
	local count = 0
	for _, spawn in pairs(spawns) do
		if flatDistance(spawn.position, around) <= Config.SpawnRadius then
			count += 1
		end
	end
	-- a caught or fled alien keeps its slot until its respawn timer runs out
	for _, entry in ipairs(pending) do
		if entry.readyAt > now and flatDistance(entry.position, around) <= Config.SpawnRadius then
			count += 1
		end
	end
	return count
end

local function tick()
	local now = os.clock()
	local condition: Types.Condition = WorldClock.GetCondition()

	-- expire respawn timers
	for index = #pending, 1, -1 do
		if pending[index].readyAt <= now then
			table.remove(pending, index)
		end
	end

	local roots: { Vector3 } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local root = rootOf(player)
		if root then
			table.insert(roots, root.Position)
		end
	end

	-- conditional spawns leave when their condition ends; far spawns are culled
	for spawnId, spawn in pairs(spawns) do
		if spawn.condition ~= "Any" and spawn.condition ~= condition then
			Spawner.RemoveSpawn(spawnId, "despawn")
		elseif #roots > 0 then
			local nearest = math.huge
			for _, at in ipairs(roots) do
				nearest = math.min(nearest, flatDistance(spawn.position, at))
			end
			if nearest > Config.SpawnCullDistance then
				Spawner.RemoveSpawn(spawnId, "cull")
			end
		end
	end

	-- top up density around each player
	for _, at in ipairs(roots) do
		local missing = Config.SpawnDensityTarget - nearCount(at, now)
		for _ = 1, missing do
			if not createSpawn(at, condition) then
				break
			end
		end
	end
end

-- Public API -------------------------------------------------------------

function Spawner.GetSpawn(spawnId: string): WildSpawn?
	return spawns[spawnId]
end

function Spawner.RemoveSpawn(spawnId: string, reason: RemoveReason)
	local spawn = spawns[spawnId]
	if not spawn then
		return
	end
	spawns[spawnId] = nil
	if spawn.part.Parent then
		spawn.part:Destroy()
	end
	if reason == "caught" or reason == "fled" then
		table.insert(pending, {
			position = spawn.position,
			readyAt = os.clock() + rng:NextNumber(Config.SpawnRespawnMinSeconds, Config.SpawnRespawnMaxSeconds),
		})
	end
end

function Spawner.Init()
	folder()
end

function Spawner.Start()
	task.spawn(function()
		while true do
			tick()
			task.wait(Config.SpawnTickSeconds)
		end
	end)
end

return Spawner
