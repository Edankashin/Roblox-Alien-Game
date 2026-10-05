--!strict
-- ServerScriptService.Server.Services.Economy: the camp. Owns every mutation of station seating,
-- module gates and assembly, pays station income into profiles on a fixed tick, settles offline time
-- on join, and pushes each result to the owning client. All the maths comes from the shared
-- ReplicatedStorage.Shared.Economy module so the client extrapolates with the same formulas; this
-- service only decides when the real profile changes. Clients send module ids and nothing else.
-- It is also the one door an alien enters a profile through (GrantAlien): a wild catch from Catching
-- and a Peddler egg both write the record, the codex and the Scrap here, then seat the newcomer and
-- report the catch to Quests for the Field Notes and to the Tutorial, which also hears every module
-- start (both gates paid) and completion from here.
-- Robux (Monetization) reaches the camp three ways: the alien and slots granters registered at Init
-- (a Starter Pack Rare, +1 slot on every station), the Auto Optimize pass (the crew is reseated after
-- every newcomer) and the Longer Offline pass (the offline cap grows to Config.OfflineCapSecondsPass).

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Species = require(Shared.data.Species)
local Tiers = require(Shared.data.Tiers)
local Sizes = require(Shared.data.Sizes)
local Overlays = require(Shared.data.Overlays)
local Modules = require(Shared.data.Modules)
local AnalyticsData = require(Shared.data.Analytics)
local Economy = require(Shared.Economy)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Buffs = require(script.Parent.Buffs)
local WorldClock = require(script.Parent.WorldClock)
local Quests = require(script.Parent.Quests)
local Tutorial = require(script.Parent.Tutorial)
local Spawner = require(script.Parent.Spawner)
local Monetization = require(script.Parent.Monetization)

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

-- Analytics only: how many modules this profile has ever finished, across worlds.
local function completedModuleCount(profile: Types.Profile): number
	local count = 0
	for _, world in pairs(profile.modules) do
		for _, state in pairs(world) do
			if state.completedAt ~= nil then
				count += 1
			end
		end
	end
	return count
end

-- Analytics only: a finished module, and for the first one this profile ever finished, the seconds since
-- firstSeen. Modules finish one at a time (snapshotModules completes the active one only).
local function reportModuleComplete(player: Player, worldId: number, moduleId: string)
	Analytics.Event(player, AnalyticsData.Events.ModuleComplete, 1, { moduleId = moduleId, worldId = tostring(worldId) })
	local profile = PlayerData.Get(player)
	if profile and completedModuleCount(profile) == 1 then
		Analytics.Event(player, AnalyticsData.Events.FirstModuleSeconds, os.time() - profile.firstSeen)
	end
end

-- Tells the client about each module that just finished, and the Tutorial (a moduleComplete step).
local function announceCompleted(player: Player, worldId: number, completed: { string })
	for _, moduleId in ipairs(completed) do
		Net.event("ModuleCompleted"):FireClient(player, worldId, moduleId)
		Tutorial.OnModuleComplete(player, moduleId)
		reportModuleComplete(player, worldId, moduleId)
	end
end

-- Everything a seating change touches: who stands where, the rates, and the re-based progress.
local function pushCamp(player: Player, profile: Types.Profile)
	pushStations(player, profile)
	pushRate(player, profile)
	pushModules(player, profile)
end

-- Server-wide banner for catches of Config.AnnounceMinTier and above, so rarity is read out to everyone.
local function announceCatch(player: Player, species: string, tier: Types.Tier, overlay: Types.Overlay)
	local rank = table.find(Tiers.Order, tier) or 0
	local minRank = table.find(Tiers.Order, Config.AnnounceMinTier) or math.huge
	if rank < minRank then
		return
	end
	local note: Types.Announcement = { kind = "catch", playerName = player.DisplayName, species = species, tier = tier, overlay = overlay }
	Net.event("Announcement"):FireAllClients(note)
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
		-- Free slot growth: a finished module can raise every station's slot count (never above the cap).
		local unlocks = def.unlocksSlots
		if unlocks then
			for _, station in pairs(profile.stations) do
				station.slots = math.clamp(math.max(station.slots, unlocks), 1, Config.StationMaxSlots)
			end
		end
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
	local startedId: string? = nil -- the module whose clock started with this payment (the Tutorial hears it)
	local paid = 0 -- the Scrap this call took (Analytics)
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
		paid = remaining
		state.scrapPaid = def.scrap
		local wasStarted = state.started
		maybeStart(def, state)
		if state.started and not wasStarted then
			startedId = def.id
		end
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushScrap(player, profile)
		pushModules(player, profile)
		Analytics.Economy(player, "Sink", paid, profile.scrap, "ModulePay", AnalyticsData.Economy.Sinks.Module)
	end
	if startedId then
		Tutorial.OnModuleStarted(player, startedId)
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
	local startedId: string? = nil -- the module whose clock started with these keys (the Tutorial hears it)
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
		local wasStarted = state.started
		maybeStart(def, state)
		if state.started and not wasStarted then
			startedId = def.id
		end
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
	if startedId then
		Tutorial.OnModuleStarted(player, startedId)
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

-- Banks progress at the old speed, reseats every alien fastest first and pushes the camp. The remote
-- below and the Auto Optimize pass (after every alien that enters the profile) both run this.
local function optimize(player: Player): (boolean, string?)
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

local function onStationOptimize(player: Player): (boolean, string?)
	if not Net.allow(player, "StationOptimize", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return optimize(player)
end

-- Income -----------------------------------------------------------------

-- Pays dt seconds of station income to every loaded player, whole Scrap only, and re-bases assembly.
-- An active Double Shift multiplies the tick by Buffs.StationMultiplier (1 otherwise).
local function tickIncome(dt: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(player)
		if profile then
			local before = profile.scrap
			local completed: { string } = {}
			local multiplier = Buffs.StationMultiplier(player)
			PlayerData.Update(player, function(p)
				local carry = (carries[player.UserId] or 0) + Economy.totalRate(p) * multiplier * dt
				local whole = math.floor(carry)
				carries[player.UserId] = carry - whole
				p.scrap += whole
				completed = snapshotModules(p)
			end)
			if profile.scrap ~= before then
				pushScrap(player, profile)
				Analytics.Income(player, profile.scrap - before, profile.scrap)
			end
			if #completed > 0 then
				pushCamp(player, profile) -- a completed module can also have grown the station slots
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
	-- Modules that finished while away reach the client in the summary, not as ModuleCompleted
	-- events; the Tutorial still hears each one below.
	local completedAway: { string } = {}
	PlayerData.Update(player, function(profile)
		ensureWorldModules(profile)
		if profile.lastSeen <= 0 then
			return
		end
		local away = os.time() - profile.lastSeen
		if away < Config.OfflineMinSeconds then
			return
		end
		-- Shared Economy.offlineScrap's formula, with the cap the Longer Offline pass raises
		-- (Config.OfflineCapSecondsPass instead of Config.OfflineCapSeconds).
		local cap = if Monetization.OwnsPass(player, "LongerOffline") then Config.OfflineCapSecondsPass else Config.OfflineCapSeconds
		local gain = math.floor(Economy.totalRate(profile) * Config.OfflineRate * math.clamp(away, 0, cap))
		profile.scrap += gain
		local completed = snapshotModules(profile) -- assembly ran on the wall clock while away
		completedAway = completed
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
		Analytics.Economy(player, "Source", live.scrap - scrapBefore, live.scrap, "Gameplay", AnalyticsData.Economy.Sources.Offline)
	end
	for _, moduleId in ipairs(completedAway) do
		Tutorial.OnModuleComplete(player, moduleId)
		reportModuleComplete(player, live.world.current, moduleId)
	end
end

-- Granting ---------------------------------------------------------------

local function overlayRank(overlay: Types.Overlay): number
	return table.find(Overlays.Order, overlay) or 0
end

-- Seats an alien already in the profile and tells the client about the camp. Banks assembly progress
-- at the old speed first so the crew change never rewrites history.
local function seatAndPush(player: Player, uid: string)
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

-- Public API -------------------------------------------------------------

-- An alien enters the profile: a new level-1 record, the codex entry (count, best overlay, first
-- catch), the Scrap it pays (the tier's catch pay, times Config.PerfectScrapMultiplier on a Perfect,
-- times the size band's Scrap multiplier, times an active Scrap Magnet, whole Scrap, plus the codex payout on a first catch) and the catch
-- stats, in one profile update. Then the newcomer is seated, the client hears ScrapChanged and the
-- camp pushes, pity moves, a rare enough tier is announced to the whole server, and the Field Notes
-- count the catch under every condition active now (a rainy night is both Rain and Night), and the
-- Tutorial hears the species. Returns the Reveal payload, or nil when the player has no profile (or
-- the species id is unknown). size is a Sizes band id from the wild spawn that was caught; nil (eggs,
-- gifts, shop grants) rolls one with Spawner.RollSize, and an unknown id falls back to the default band.
function EconomyService.GrantAlien(player: Player, species: string, overlay: Types.Overlay, perfect: boolean, size: string?): Types.GrantResult?
	local def = Species.ById[species]
	if not def then
		return nil
	end
	local tier: Types.Tier = def.tier
	local tierDef = Tiers.Tiers[tier]
	local magnet = Buffs.CatchScrapMultiplier(player)
	local sizeId: string = if size == nil then Spawner.RollSize() elseif Sizes.ById[size] then size else Sizes.Default
	local band = Sizes.ById[sizeId]
	local uid = HttpService:GenerateGUID(false)
	local caughtAt = os.time()
	local isNew = false
	local scrapGained = 0
	local scrapNow = 0
	local ok = PlayerData.Update(player, function(profile)
		local record: Types.AlienRecord = {
			uid = uid,
			species = species,
			level = 1,
			overlay = overlay,
			caughtAt = caughtAt,
			size = sizeId,
		}
		profile.aliens[uid] = record

		local entry = profile.codex[species]
		if not entry then
			entry = { count = 0, bestOverlay = "None", firstCaughtAt = 0 }
			profile.codex[species] = entry
		end
		isNew = entry.count == 0
		entry.count += 1
		if overlayRank(overlay) > overlayRank(entry.bestOverlay) then
			entry.bestOverlay = overlay
		end

		local pay = math.floor(tierDef.catchScrap * band.scrapMultiplier + 0.5) -- the size band's multiplier, rounded half up, before the Perfect and Magnet buffs
		if perfect then
			pay *= Config.PerfectScrapMultiplier
		end
		scrapGained = math.floor(pay * magnet)
		if isNew then
			entry.firstCaughtAt = caughtAt
			scrapGained += tierDef.codexScrap
		end
		profile.scrap += scrapGained

		profile.stats.catches += 1
		if perfect then
			profile.stats.perfects += 1
		end
		scrapNow = profile.scrap
	end)
	local profile = PlayerData.Get(player)
	if not ok or not profile then
		return nil
	end
	pushScrap(player, profile)
	seatAndPush(player, uid) -- StationsChanged, RateChanged, ModulesChanged
	if Monetization.OwnsPass(player, "AutoOptimize") then
		optimize(player) -- the Auto Optimize pass: the whole crew is reseated fastest first after every newcomer
	end
	Buffs.OnCatch(player, tier)
	announceCatch(player, species, tier, overlay)
	Quests.OnCatch(player, species, tier, WorldClock.GetConditions())
	Tutorial.OnCatch(player, species)
	-- Analytics: the catch, its Scrap split into the catch pay and the codex payout, and the first catch ever.
	local codexScrap = if isNew then tierDef.codexScrap else 0
	Analytics.Event(player, AnalyticsData.Events.Catch, 1, { tier = tier :: string, species = species, perfect = tostring(perfect) })
	Analytics.Economy(player, "Source", scrapGained - codexScrap, scrapNow - codexScrap, "Gameplay", AnalyticsData.Economy.Sources.Catch)
	Analytics.Economy(player, "Source", codexScrap, scrapNow, "Gameplay", AnalyticsData.Economy.Sources.Codex)
	if profile.stats.catches == 1 then
		Analytics.Event(player, AnalyticsData.Events.FirstCatchSeconds, os.time() - profile.firstSeen)
	end
	return { species = species, tier = tier, overlay = overlay, size = sizeId, isNew = isNew, scrapGained = scrapGained, scrap = scrapNow }
end

-- Seat an alien another service has already written into the profile and tell the client.
function EconomyService.OnCaught(player: Player, uid: string)
	seatAndPush(player, uid)
end

-- The StationOptimize remote's work without its rate limit: bank progress, reseat everyone fastest
-- first, push the camp. NoProfile is the only refusal.
function EconomyService.Optimize(player: Player): (boolean, string?)
	return optimize(player)
end

-- Every station gains `amount` slots (a Robux pass), never above Config.StationMaxSlots or below 1;
-- the client hears StationsChanged. NoProfile is the only refusal.
function EconomyService.AddSlots(player: Player, amount: number): (boolean, string?)
	local ok = PlayerData.Update(player, function(profile)
		for _, station in pairs(profile.stations) do
			station.slots = math.clamp(station.slots + math.floor(amount), 1, Config.StationMaxSlots)
		end
	end)
	local profile = PlayerData.Get(player)
	if not ok or not profile then
		return false, "NoProfile"
	end
	pushStations(player, profile)
	return true, nil
end

function EconomyService.Init()
	for _, name in ipairs({ "ScrapChanged", "RateChanged", "StationsChanged", "ModulesChanged", "InventoryChanged", "ModuleCompleted", "Announcement", "AlienGranted" }) do
		Net.event(name)
	end
	Net.func("ModulePay").OnServerInvoke = onModulePay
	Net.func("ModuleInsertKey").OnServerInvoke = onModuleInsertKey
	Net.func("StationOptimize").OnServerInvoke = onStationOptimize
	Net.func("ClaimOfflineSummary").OnServerInvoke = onClaimOfflineSummary
	PlayerData.OnLoaded(onLoaded)
	-- Robux grants that land in the camp, registered with Monetization rather than required from it (see
	-- its header): an alien of the species the grant names, which must exist and be of the grant's tier,
	-- with the wild overlay odds and no Perfect pay; and slots on every station.
	Monetization.SetGranter("alien", function(player: Player, grant: Monetization.Grant): (boolean, string?)
		local species = grant.id
		local def = if species then Species.ById[species] else nil
		if not species or not def then
			return false, "Unknown"
		end
		if grant.tier ~= nil and def.tier ~= grant.tier then
			return false, "WrongTier"
		end
		local result = EconomyService.GrantAlien(player, species, Spawner.RollOverlay(), false)
		if result then
			Net.event("AlienGranted"):FireClient(player, result) -- the client plays the Reveal for it
		end
		return result ~= nil, if result then nil else "NoProfile"
	end)
	Monetization.SetGranter("slots", function(player: Player, grant: Monetization.Grant): (boolean, string?)
		return EconomyService.AddSlots(player, grant.amount or 0)
	end)
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
