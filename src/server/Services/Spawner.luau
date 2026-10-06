--!strict
-- ServerScriptService.Server.Services.Spawner: keeps wild aliens around every player.
-- Each wild alien is a lightweight record here plus one anchored Part under Workspace.World.Wild
-- carrying attributes (SpeciesId, Tier, Overlay, Size, Variant, SpawnId, Condition, Biome, and ReservedFor when one
-- player alone may catch it). No Humanoids, no server animation: the client bobs and labels them. The
-- server owns which species exist where and when, so the tier roll, the overlay roll, the size roll
-- (Shared/data/Sizes: a band id the catch carries into the record and its Scrap), the catch variant
-- (Shared/data/CatchVariants: the species' own, else this world's, else Standard) and the
-- condition gating all live here. A spawn's biome is the one its landing point is in (Shared/Biomes),
-- so the Forest grove and the Cave get their own tables. Conditions are a set (WorldClock.GetConditions:
-- the special weather while it runs, plus Night or Day), so a rainy night offers both Rain and Night
-- species. The tier roll uses the highest luck (Buffs.Luck) among the players within SpawnRadius of
-- the spawn point, so standing next to a lucky friend makes everyone's spawns better. During a Meteor
-- Shower (Events.IsShowerActive) the Cosmic tier, 0 in the Tiers data, gets Config.ShowerCosmicShare
-- percent times luck, taken out of the Common remainder like every other tier; chooseSpecies falls
-- back down the tiers in a biome with no Cosmic available. The Alien of the Week and the week's overlay are
-- decided here from Weekly: in the drop's world a share of spawns (data/Weekly SpawnChance) is that species in
-- any biome with no tier roll, and while the week's weather shows a share (OverlayChance) carries the week's
-- overlay in place of the usual overlay roll. The weekly species is exempt from the condition despawn, so a
-- limited one (Quest, Night) stays for its week.
-- Placed spawns (SpawnAt: the Warden the Field Notes horn summons) skip the density, weather and cull
-- rules and live on their own lifetime; Quests hears every removal through OnRemoved.
-- The home planet (Place.IsHome, world 0) has no wild: Start runs no tick there, so nothing ever spawns.

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
local WeeklyData = require(Shared.data.Weekly)
local Sizes = require(Shared.data.Sizes)
local CatchVariants = require(Shared.data.CatchVariants)
local Worlds = require(Shared.data.Worlds)
local Biomes = require(Shared.Biomes)
local Place = require(Shared.Place)
local WorldClock = require(script.Parent.WorldClock)
local Meadow = require(script.Parent.Meadow)
local Buffs = require(script.Parent.Buffs)
local Events = require(script.Parent.Events)
local Weekly = require(script.Parent.Weekly)

local Spawner = {}

export type WildSpawn = {
	spawnId: string,
	species: string,
	tier: Types.Tier,
	overlay: Types.Overlay,
	size: string, -- the size band id (Shared/data/Sizes), rolled once when it spawns
	variant: string, -- the CatchVariants row id its encounter runs: the species' variant, else this world's, else Standard
	condition: Types.Condition, -- the condition it needs; "Any" never despawns for weather
	biome: Types.Biome, -- where it landed; its species came from this biome's table
	position: Vector3,
	part: Part,
	reservedFor: number?, -- UserId of the one player who may catch it (a summoned Warden); nil for wild spawns
}

-- "retreat" is a despawn the caller asked for (a reserved encounter was abandoned), so a listener can tell.
export type RemoveReason = "caught" | "fled" | "despawn" | "cull" | "retreat"

type PendingRespawn = { position: Vector3, readyAt: number }
type Presence = { player: Player, position: Vector3 } -- a player with a character this tick

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
local removedListeners: { (WildSpawn, RemoveReason) -> () } = {} -- Quests tracks the Warden through these

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
-- Cosmic has no wild share of its own: it spawns only while a Meteor Shower runs (Config.ShowerCosmicShare).
local function rollTier(luck: number): string
	luck = math.clamp(luck, 1, Config.LuckCap)
	local cosmicShare = if Events.IsShowerActive() then Config.ShowerCosmicShare else 0
	local weights: { [string]: number } = {}
	local upperTotal = 0
	for _, tier in ipairs(Tiers.Order) do
		if tier ~= "Common" then
			local share = Tiers.Tiers[tier].share
			if tier == "Cosmic" then
				share += cosmicShare
			end
			local w = share * luck
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

-- The biome's "Any" list plus the list of every condition active right now.
local function availableSpecies(biome: Types.Biome, conditions: { Types.Condition }): { string }
	local table_ = Spawns.Biomes[biome]
	local out: { string } = {}
	if not table_ then
		return out
	end
	for _, id in ipairs(table_.Any or {}) do
		table.insert(out, id)
	end
	for _, condition in ipairs(conditions) do
		if condition ~= "Any" then
			for _, id in ipairs(table_[condition] or {}) do
				table.insert(out, id)
			end
		end
	end
	return out
end

-- Choose a species of the rolled tier that can appear in the biome now; fall back down the tier order
-- if none can.
local function chooseSpecies(biome: Types.Biome, tier: string, conditions: { Types.Condition }): Types.SpeciesDef?
	local available = availableSpecies(biome, conditions)
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

-- A weighted pick over the Sizes bands in roll order (their odds sum to 100); luck does not touch it.
local function rollSize(): string
	local roll = rng:NextNumber(0, 100)
	local acc = 0
	for _, band in ipairs(Sizes.Bands) do
		acc += band.odds
		if roll < acc then
			return band.id
		end
	end
	return Sizes.Default
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

-- The highest luck among the players within SpawnRadius of `around`. The player being topped up is
-- always one of them (distance 0), so this is at least their own.
local function luckAround(around: Vector3, present: { Presence }): number
	local best = 1
	for _, entry in ipairs(present) do
		if flatDistance(entry.position, around) <= Config.SpawnRadius then
			best = math.max(best, Buffs.Luck(entry.player))
		end
	end
	return best
end

-- Seats one wild part at a flat point (Y re-read from the surface there) and records it. The caller
-- has already chosen the species, the overlay and the size band; the catch variant is resolved here from the
-- species row, then the world, then the default. Everything the client reads is an attribute on the
-- part. A reservedFor UserId is written as the ReservedFor attribute so the client can label it.
local function place(def: Types.SpeciesDef, flat: Vector3, overlay: Types.Overlay, sizeBand: string, reservedFor: number?): WildSpawn
	local biome: Types.Biome = Biomes.At(flat)
	local size = BASE_SIZE * def.placeholder.scale
	local position = Vector3.new(flat.X, Meadow.GetSurfaceTop(flat) + Config.WildHoverStuds + size / 2, flat.Z)
	local spawnId = HttpService:GenerateGUID(false)

	-- the catch variant: the species' own, else this world's, else Standard; an unknown id falls back to Standard
	local variant: string = def.variant or Worlds[Place.WorldId()].catchVariant or CatchVariants.Default
	if not CatchVariants.Rows[variant] then
		warn(("Spawner: species %s names unknown catch variant %s; using %s"):format(def.id, variant, CatchVariants.Default))
		variant = CatchVariants.Default
	end

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
	part:SetAttribute("Size", sizeBand)
	part:SetAttribute("Variant", variant)
	part:SetAttribute("SpawnId", spawnId)
	part:SetAttribute("Condition", def.condition)
	part:SetAttribute("Biome", biome)
	if reservedFor then
		part:SetAttribute("ReservedFor", reservedFor)
	end
	part.Parent = folder()

	local spawn: WildSpawn = {
		spawnId = spawnId,
		species = def.id,
		tier = def.tier,
		overlay = overlay,
		size = sizeBand,
		variant = variant,
		condition = def.condition,
		biome = biome,
		position = position,
		part = part,
		reservedFor = reservedFor,
	}
	spawns[spawnId] = spawn
	return spawn
end

local function createSpawn(around: Vector3, conditions: { Types.Condition }, luck: number): WildSpawn?
	-- where it lands decides which biome's table it rolls from
	local flat = findPosition(around, BASE_SIZE)
	if not flat then
		return nil
	end
	local biome: Types.Biome = Biomes.At(flat)
	-- the Alien of the Week takes its share of the world's spawns, in any biome; an unknown id rolls normally
	local def: Types.SpeciesDef? = nil
	local weekly = Weekly.ActiveSpecies()
	if weekly and rng:NextNumber() < WeeklyData.SpawnChance then
		def = Species.ById[weekly]
	end
	if not def then
		def = chooseSpecies(biome, rollTier(luck), conditions)
	end
	if not def then
		return nil
	end
	local overlay: Types.Overlay
	local weeklyOverlay = Weekly.OverlayActive()
	if weeklyOverlay and rng:NextNumber(0, 100) < WeeklyData.OverlayChance then
		overlay = weeklyOverlay :: Types.Overlay
	else
		overlay = rollOverlay()
	end
	return place(def, flat, overlay, rollSize(), nil)
end

-- Wild spawns within SpawnRadius of a point; a reserved spawn takes no density slot.
local function nearCount(around: Vector3, now: number): number
	local count = 0
	for _, spawn in pairs(spawns) do
		if not spawn.reservedFor and flatDistance(spawn.position, around) <= Config.SpawnRadius then
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
	local conditions: { Types.Condition } = WorldClock.GetConditions()

	-- expire respawn timers
	for index = #pending, 1, -1 do
		if pending[index].readyAt <= now then
			table.remove(pending, index)
		end
	end

	local present: { Presence } = {}
	local roots: { Vector3 } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local root = rootOf(player)
		if root then
			table.insert(present, { player = player, position = root.Position })
			table.insert(roots, root.Position)
		end
	end

	-- conditional spawns leave when their condition ends; far spawns are culled. A reserved spawn lives
	-- on its own lifetime (SpawnAt) and is left alone by both. The Alien of the Week ignores its own condition
	-- (Panpipe's is Quest, which no clock ever offers), so it stays while its week runs.
	local weekly = Weekly.ActiveSpecies()
	for spawnId, spawn in pairs(spawns) do
		local wild = spawn.reservedFor == nil
		if wild and spawn.condition ~= "Any" and spawn.species ~= weekly and not table.find(conditions, spawn.condition) then
			Spawner.RemoveSpawn(spawnId, "despawn")
		elseif wild and #roots > 0 then
			local nearest = math.huge
			for _, at in ipairs(roots) do
				nearest = math.min(nearest, flatDistance(spawn.position, at))
			end
			if nearest > Config.SpawnCullDistance then
				Spawner.RemoveSpawn(spawnId, "cull")
			end
		end
	end

	-- top up density around each player, rolling tiers with the best luck nearby
	for _, entry in ipairs(present) do
		local at = entry.position
		local missing = Config.SpawnDensityTarget - nearCount(at, now)
		if missing > 0 then
			local luck = luckAround(at, present)
			for _ = 1, missing do
				if not createSpawn(at, conditions, luck) then
					break
				end
			end
		end
	end
end

-- Public API -------------------------------------------------------------

function Spawner.GetSpawn(spawnId: string): WildSpawn?
	return spawns[spawnId]
end

-- The overlay roll every wild spawn gets, for aliens granted outside the wild (Peddler eggs) so they
-- carry the same odds (Overlays chances).
function Spawner.RollOverlay(): Types.Overlay
	return rollOverlay()
end

-- The size roll every wild spawn gets (Sizes odds), for aliens granted outside the wild (eggs, gifts,
-- shop grants) so they carry the same odds. Returns a Sizes band id.
function Spawner.RollSize(): string
	return rollSize()
end

-- Places one spawn of a known species exactly where asked (a flat point; Y comes from the surface
-- there), with the species' tier and the given overlay, outside the camp-clearance and density rules.
-- reservedFor restricts the catch to that UserId (Catching refuses everyone else). lifetimeSeconds,
-- when given, removes it with reason "despawn" once it runs out, unless it was caught or removed first.
-- size is a Sizes band id (an unknown id falls back to the default band); nil rolls one.
-- Nil only when the species id is unknown.
function Spawner.SpawnAt(position: Vector3, speciesId: string, overlay: Types.Overlay, reservedFor: number?, lifetimeSeconds: number?, size: string?): WildSpawn?
	local def = Species.ById[speciesId]
	if not def then
		return nil
	end
	local band: string = if size == nil then rollSize() elseif Sizes.ById[size] then size else Sizes.Default
	local spawn = place(def, position, overlay, band, reservedFor)
	if lifetimeSeconds and lifetimeSeconds > 0 then
		local spawnId = spawn.spawnId
		task.delay(lifetimeSeconds, function()
			if spawns[spawnId] == spawn then
				Spawner.RemoveSpawn(spawnId, "despawn")
			end
		end)
	end
	return spawn
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
	-- a caught or fled wild alien keeps its density slot until the respawn timer runs out; a placed
	-- (reserved) spawn never held one
	if (reason == "caught" or reason == "fled") and not spawn.reservedFor then
		table.insert(pending, {
			position = spawn.position,
			readyAt = os.clock() + rng:NextNumber(Config.SpawnRespawnMinSeconds, Config.SpawnRespawnMaxSeconds),
		})
	end
	-- each listener runs in its own thread so one failing service cannot stall a removal
	for _, callback in ipairs(removedListeners) do
		task.spawn(callback, spawn, reason)
	end
end

-- Server-side hook: `callback` runs with the record and the reason every time a spawn is removed, for
-- any reason. Quests follows the Warden it summoned through this (caught, fled, lifetime, retreat).
function Spawner.OnRemoved(callback: (WildSpawn, RemoveReason) -> ())
	table.insert(removedListeners, callback)
end

function Spawner.Init()
	folder()
end

function Spawner.Start()
	if Place.IsHome() then
		print(("[%s] Spawner: this is the home planet; no wild spawns"):format(Config.WorkingTitle))
		return
	end
	task.spawn(function()
		while true do
			tick()
			task.wait(Config.SpawnTickSeconds)
		end
	end)
end

return Spawner
