--!strict
-- ServerScriptService.Server.Services.Economy: the camp. Owns every mutation of station seating,
-- module gates and assembly, pays station income into profiles on a fixed tick, settles offline time
-- on join, and pushes each result to the owning client. All the maths comes from the shared
-- ReplicatedStorage.Shared.Economy module so the client extrapolates with the same formulas; this
-- service only decides when the real profile changes. Clients send module ids and nothing else.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Species = require(Shared.data.Species)
local Modules = require(Shared.data.Modules)
local Economy = require(Shared.Economy)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)

local EconomyService = {}

local REMOTE_RATE_PER_SECOND = 4 -- ModulePay, ModuleInsertKey and StationOptimize calls per player per second

local carries: { [number]: number } = {} -- fractional Scrap not yet paid out, by UserId
-- Settled on join and handed over when the client asks (ClaimOfflineSummary), because a push at load
-- time can arrive before the client's scripts are listening.
local pendingOffline: { [number]: Types.OfflineSummary } = {}

-- Pushes -----------------------------------------------------------------

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushRate(player: Player, profile: Types.Profile)
	Net.event("RateChanged"):FireClient(player, Economy.campState(profile))
end

local function pushStations(player: Player, profile: Types.Profile)
	Net.event("StationsChanged"):FireClient(player, profile.stations, profile.aliens)
end

local function pushModules(player: Player, profile: Types.Profile)
	local worldId = profile.world.current
	Net.event("ModulesChanged"):FireClient(player, worldId, profile.modules[tostring(worldId)] or {})
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

local function announceCompleted(player: Player, worldId: number, completed: { string })
	for _, moduleId in ipairs(completed) do
		Net.event("ModuleCompleted"):FireClient(player, worldId, moduleId)
	end
end

-- Everything a seating change touches: who stands where, the rates, and the re-based progress.
local function pushCamp(player: Player, profile: Types.Profile)
	pushStations(player, profile)
	pushRate(player, profile)
	pushModules(player, profile)
end

-- Module state -----------------------------------------------------------

local function ensureModuleState(profile: Types.Profile, worldId: number, moduleId: string): Types.ModuleProgress
	local key = tostring(worldId)
	local world = profile.modules[key]
	if not world then
		world = {}
		profile.modules[key] = world
	end
	local state = world[moduleId]
	if not state then
		local fresh: Types.ModuleProgress = { scrapPaid = 0, keyPaid = 0, progress = 0, started = false, completedAt = nil, updatedAt = os.time() }
		world[moduleId] = fresh
		state = fresh
	end
	return state
end

local function ensureWorldModules(profile: Types.Profile)
	local worldId = profile.world.current
	for _, def in ipairs(Economy.moduleDefs(worldId)) do
		ensureModuleState(profile, worldId, def.id)
	end
end

-- The module being built right now (modules complete in order), or nil once the ship is done.
local function activeModule(profile: Types.Profile): (Modules.ModuleDef?, Types.ModuleProgress?)
	local worldId = profile.world.current
	local index = Economy.activeModuleIndex(profile, worldId)
	if not index then
		return nil, nil
	end
	local def = Economy.moduleDefs(worldId)[index]
	return def, ensureModuleState(profile, worldId, def.id)
end

-- Once both gates are paid the clock starts; both sides extrapolate progress from updatedAt.
local function maybeStart(def: Modules.ModuleDef, state: Types.ModuleProgress)
	if state.started or not Economy.gatesPaid(def, state) then
		return
	end
	state.started = true
	state.progress = 0
	state.updatedAt = os.time()
end

-- Writes the active module's extrapolated progress into the profile so later extrapolation (here and
-- on the client) starts from now. Returns the ids of modules that finished in this call.
local function snapshotModules(profile: Types.Profile): { string }
	local completed: { string } = {}
	local def, state = activeModule(profile)
	if not def or not state or not state.started then
		return completed
	end
	local now = os.time()
	local progress = Economy.progressAt(def, state, Economy.assemblySpeed(profile, def.job), now)
	state.updatedAt = now
	if progress >= 1 then
		state.progress = 1
		state.completedAt = now
		table.insert(completed, def.id)
	else
		state.progress = progress
	end
	return completed
end

-- Seating ----------------------------------------------------------------
-- record.station / record.slot and station.assigned always agree: slot is the index in assigned.

-- The station for this job when it exists and has a free slot.
local function openStation(profile: Types.Profile, job: string): Types.StationState?
	local station = profile.stations[job]
	if station and #station.assigned < station.slots then
		return station
	end
	return nil
end

local function assign(record: Types.AlienRecord, station: Types.StationState, job: Types.Job)
	table.insert(station.assigned, record.uid)
	record.station = job
	record.slot = #station.assigned
end

local function unassign(profile: Types.Profile, record: Types.AlienRecord)
	local job = record.station
	record.station = nil
	record.slot = nil
	if not job then
		return
	end
	local station = profile.stations[job]
	if not station then
		return
	end
	local index = table.find(station.assigned, record.uid)
	if index then
		table.remove(station.assigned, index)
	end
	for slot, uid in ipairs(station.assigned) do
		local other = profile.aliens[uid]
		if other then
			other.slot = slot
		end
	end
end

-- Jobs this alien can work in this world, best first.
local function jobsOf(profile: Types.Profile, record: Types.AlienRecord): { Types.Job }
	local def = Species.ById[record.species]
	if not def then
		return {}
	end
	return Economy.jobsFor(def, profile.world.current)
end

-- Seats the alien at the first of its jobs with a free slot. False when every one is full.
local function placeInOpenSlot(profile: Types.Profile, record: Types.AlienRecord, jobs: { Types.Job }): boolean
	-- Annotated local: the type checker widens an unannotated loop variable of a singleton union to string.
	for index = 1, #jobs do
		local job: Types.Job = jobs[index]
		local station = openStation(profile, job)
		if station then
			assign(record, station, job)
			return true
		end
	end
	return false
end

-- The slowest alien seated at any of these jobs, and its speed.
local function slowestWorker(profile: Types.Profile, jobs: { Types.Job }): (Types.AlienRecord?, number)
	local slowest: Types.AlienRecord? = nil
	local slowestSpeed = math.huge
	for _, job in ipairs(jobs) do
		local station = profile.stations[job]
		if station then
			for _, uid in ipairs(station.assigned) do
				local record = profile.aliens[uid]
				if record then
					local speed = Economy.workSpeed(record)
					if speed < slowestSpeed then
						slowest = record
						slowestSpeed = speed
					end
				end
			end
		end
	end
	return slowest, slowestSpeed
end

-- A newcomer takes an open slot at its best job, or bumps the slowest worker it beats. The bumped
-- alien only looks for open slots, so one catch never cascades through the whole camp.
local function seatNewcomer(profile: Types.Profile, record: Types.AlienRecord)
	local jobs = jobsOf(profile, record)
	if placeInOpenSlot(profile, record, jobs) then
		return
	end
	local slow, slowSpeed = slowestWorker(profile, jobs)
	if not slow or slowSpeed >= Economy.workSpeed(record) then
		return
	end
	unassign(profile, slow)
	placeInOpenSlot(profile, record, jobs)
	placeInOpenSlot(profile, slow, jobsOf(profile, slow))
end

-- Clears every station and reseats all aliens fastest first, each at its best job with room.
local function reseatAll(profile: Types.Profile)
	for _, station in pairs(profile.stations) do
		table.clear(station.assigned)
	end
	local ordered: { Types.AlienRecord } = {}
	for _, record in pairs(profile.aliens) do
		record.station = nil
		record.slot = nil
		table.insert(ordered, record)
	end
	table.sort(ordered, function(a, b)
		local speedA, speedB = Economy.workSpeed(a), Economy.workSpeed(b)
		if speedA ~= speedB then
			return speedA > speedB
		end
		return a.uid < b.uid -- deterministic on ties
	end)
	for _, record in ipairs(ordered) do
		placeInOpenSlot(profile, record, jobsOf(profile, record))
	end
end

-- Remotes ----------------------------------------------------------------

-- Runs fn against the live profile inside PlayerData.Update. fn returns a refusal reason or nil.
local function mutate(player: Player, fn: (Types.Profile) -> string?): (boolean, string?)
	local reason: string? = nil
	local ok = PlayerData.Update(player, function(profile)
		reason = fn(profile)
	end)
	if not ok then
		return false, "NoProfile"
	end
	if reason then
		return false, reason
	end
	return true, nil
end

local function onModulePay(player: Player, moduleId: any): (boolean, string?)
	if type(moduleId) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "ModulePay", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local ok, reason = mutate(player, function(profile)
		local def, state = activeModule(profile)
		if not def or not state or def.id ~= moduleId then
			return "NotActive"
		end
		local remaining = def.scrap - state.scrapPaid
		if remaining <= 0 then
			return "AlreadyPaid"
		end
		if profile.scrap < remaining then
			return "NotEnoughScrap"
		end
		profile.scrap -= remaining
		state.scrapPaid = def.scrap
		maybeStart(def, state)
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushScrap(player, profile)
		pushModules(player, profile)
	end
	return true
end

local function onModuleInsertKey(player: Player, moduleId: any): (boolean, string?)
	if type(moduleId) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "ModuleInsertKey", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local ok, reason = mutate(player, function(profile)
		local def, state = activeModule(profile)
		if not def or not state or def.id ~= moduleId then
			return "NotActive"
		end
		local missing = def.keyCount - state.keyPaid
		if missing <= 0 then
			return "AlreadyFull"
		end
		local held = profile.inventory.keyMaterials[def.keyMaterial] or 0
		local move = math.min(missing, held)
		if move <= 0 then
			return "NoMaterial"
		end
		profile.inventory.keyMaterials[def.keyMaterial] = held - move
		state.keyPaid += move
		maybeStart(def, state)
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushInventory(player, profile)
		pushModules(player, profile)
	end
	return true
end

-- The client calls this once after it boots; the summary is handed over once and forgotten.
local function onClaimOfflineSummary(player: Player): Types.OfflineSummary?
	if not Net.allow(player, "ClaimOfflineSummary", REMOTE_RATE_PER_SECOND) then
		return nil
	end
	local summary = pendingOffline[player.UserId]
	pendingOffline[player.UserId] = nil
	return summary
end

local function onStationOptimize(player: Player): (boolean, string?)
	if not Net.allow(player, "StationOptimize", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local completed: { string } = {}
	local ok = PlayerData.Update(player, function(profile)
		completed = snapshotModules(profile) -- bank progress at the old speed before the crew moves
		reseatAll(profile)
	end)
	if not ok then
		return false, "NoProfile"
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushCamp(player, profile)
		announceCompleted(player, profile.world.current, completed)
	end
	return true
end

-- Income -----------------------------------------------------------------

-- Pays dt seconds of station income to every loaded player, whole Scrap only, and re-bases assembly.
local function tickIncome(dt: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(player)
		if profile then
			local before = profile.scrap
			local completed: { string } = {}
			PlayerData.Update(player, function(p)
				local carry = (carries[player.UserId] or 0) + Economy.totalRate(p) * dt
				local whole = math.floor(carry)
				carries[player.UserId] = carry - whole
				p.scrap += whole
				completed = snapshotModules(p)
			end)
			if profile.scrap ~= before then
				pushScrap(player, profile)
			end
			if #completed > 0 then
				pushModules(player, profile)
				announceCompleted(player, profile.world.current, completed)
			end
		end
	end
end

-- Join -------------------------------------------------------------------

-- Runs before the join payload is sent, so the client boots from a settled profile. Changes still go
-- through PlayerData.Update so every mutation has one door.
local function onLoaded(player: Player, _profile: Types.Profile)
	local live = PlayerData.Get(player)
	if not live then
		return
	end
	local scrapBefore = live.scrap
	local summary: Types.OfflineSummary? = nil
	PlayerData.Update(player, function(profile)
		ensureWorldModules(profile)
		if profile.lastSeen <= 0 then
			return
		end
		local away = os.time() - profile.lastSeen
		if away < Config.OfflineMinSeconds then
			return
		end
		local gain = Economy.offlineScrap(profile, away)
		profile.scrap += gain
		local completed = snapshotModules(profile) -- assembly ran on the wall clock while away
		if gain > 0 or #completed > 0 then
			summary = { awaySeconds = away, scrap = gain, completedModules = completed }
		end
	end)
	if summary then
		pendingOffline[player.UserId] = summary
	end
	-- The join payload carries all of this; the pushes cover a client that pulled its profile early.
	pushCamp(player, live)
	if live.scrap ~= scrapBefore then
		pushScrap(player, live)
	end
end

-- Public API -------------------------------------------------------------

-- Called by Catching once the catch is written: seat the newcomer and tell the client.
function EconomyService.OnCaught(player: Player, uid: string)
	local completed: { string } = {}
	local ok = PlayerData.Update(player, function(profile)
		local record = profile.aliens[uid]
		if not record then
			return
		end
		completed = snapshotModules(profile) -- bank progress at the old speed before the crew changes
		seatNewcomer(profile, record)
	end)
	local profile = PlayerData.Get(player)
	if not ok or not profile then
		return
	end
	pushCamp(player, profile)
	announceCompleted(player, profile.world.current, completed)
end

function EconomyService.Init()
	for _, name in ipairs({ "ScrapChanged", "RateChanged", "StationsChanged", "ModulesChanged", "InventoryChanged", "ModuleCompleted" }) do
		Net.event(name)
	end
	Net.func("ModulePay").OnServerInvoke = onModulePay
	Net.func("ModuleInsertKey").OnServerInvoke = onModuleInsertKey
	Net.func("StationOptimize").OnServerInvoke = onStationOptimize
	Net.func("ClaimOfflineSummary").OnServerInvoke = onClaimOfflineSummary
	PlayerData.OnLoaded(onLoaded)
end

function EconomyService.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		carries[player.UserId] = nil
		pendingOffline[player.UserId] = nil
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Config.IncomeTickSeconds)
			local now = os.clock()
			tickIncome(now - last)
			last = now
		end
	end)
	print(("[%s] Economy: ticking every %ss"):format(Config.WorkingTitle, tostring(Config.IncomeTickSeconds)))
end

return EconomyService
