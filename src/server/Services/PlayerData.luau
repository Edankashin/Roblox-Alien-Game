--!strict
-- Player saves: one DataStore key per player, UpdateAsync everywhere, a session lock so two servers never
-- write the same profile, a schema version with migrations, autosave, and a clean release on leave.
-- In Studio without API access it falls back to an in-memory profile and says so in the output.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local SettingsData = require(Shared.data.Settings)
local Jobs = require(Shared.data.Jobs)
local Net = require(Shared.Net)

local PlayerData = {}

local STORE_NAME = "PlayerData"
local SCHEMA_VERSION = 3
local LOAD_RETRIES = 6
local LOAD_RETRY_SECONDS = 5

local profiles: { [number]: Types.Profile } = {}
-- Plain callbacks, not a BindableEvent: they run synchronously, before the join payload is sent, on the
-- live profile (a BindableEvent would hand them a copy and run after the client already has stale data).
local loadedCallbacks: { (Player, Types.Profile) -> () } = {}
local store: DataStore? = nil
local memoryOnly = false

local function keyFor(player: Player): string
	return "User_" .. tostring(player.UserId)
end

-- Every preference at its data default (data/Settings.luau).
local function defaultSettings(): { [string]: number }
	local out: { [string]: number } = {}
	for _, def in ipairs(SettingsData.Order) do
		out[def.key] = def.default
	end
	return out
end

local function template(): Types.Profile
	local stations: { [string]: Types.StationState } = {}
	for _, job in ipairs(Jobs.Order) do
		stations[job] = { slots = Config.StationStartSlots, assigned = {} }
	end
	return {
		version = SCHEMA_VERSION,
		scrap = 0,
		aliens = {},
		stations = stations,
		modules = {},
		world = { current = 1, unlocked = { 1 }, outposts = {} },
		codex = {},
		gear = { boots = false, hoverboard = false, glider = false, radar = 0 },
		companions = {},
		quests = { daily = {}, weekly = {}, fieldNotes = {}, progress = {} },
		gifts = { daysPlayed = 0, claimed = {}, lastPlayDay = 0 },
		spins = { free = 1, banked = 0, lastFree = 0 },
		luck = { pity = 0 },
		purchases = {},
		buffs = {},
		inventory = { keyMaterials = {}, lures = {}, powerUps = {}, items = {} },
		stats = { catches = 0, perfects = 0, playSeconds = 0 },
		settings = defaultSettings(),
		tutorialStep = 1,
		tutorialCounter = 0,
		lastSeen = 0,
		firstSeen = 0,
		lock = nil,
	}
end

-- Migrations run in order from the saved version up to SCHEMA_VERSION. Add one entry per bump.
local migrations: { [number]: (any) -> any } = {
	-- v2: quest objective progress and a general item bag (the Warden's Horn)
	[2] = function(data)
		data.quests = data.quests or {}
		data.quests.progress = data.quests.progress or {}
		data.inventory = data.inventory or {}
		data.inventory.items = data.inventory.items or {}
		return data
	end,
	-- v3: player preferences (the Settings screen); unknown keys are dropped, missing ones take the default
	[3] = function(data)
		local saved = if type(data.settings) == "table" then data.settings else {}
		local settings = defaultSettings()
		for key, value in pairs(saved) do
			if settings[key] ~= nil and type(value) == "number" then
				settings[key] = value
			end
		end
		data.settings = settings
		return data
	end,
}

local function migrate(data: any): Types.Profile
	local version = tonumber(data.version) or 1
	while version < SCHEMA_VERSION do
		local step = migrations[version + 1]
		if step then
			data = step(data)
		end
		version += 1
		data.version = version
	end
	-- fill any missing top-level fields from the template without touching existing values
	local fresh = template()
	for k, v in pairs(fresh) do
		if data[k] == nil then
			data[k] = v
		end
	end
	return data :: Types.Profile
end

local function lockIsHeldElsewhere(data: any): boolean
	local lock = data and data.lock
	if type(lock) ~= "table" then
		return false
	end
	if lock.jobId == game.JobId then
		return false
	end
	return (os.time() - (tonumber(lock.time) or 0)) < Config.SessionLockSeconds
end

local function tryLoad(player: Player): (Types.Profile?, string?)
	if memoryOnly or not store then
		return migrate(template()), nil
	end
	local ds = store :: DataStore
	local locked = false
	local ok, result = pcall(function()
		return ds:UpdateAsync(keyFor(player), function(old)
			if old ~= nil and lockIsHeldElsewhere(old) then
				locked = true
				return nil -- cancel: another server holds this profile
			end
			local data = if old ~= nil then migrate(old) else migrate(template())
			data.lock = { jobId = game.JobId, time = os.time() }
			return data
		end)
	end)
	if not ok then
		return nil, tostring(result)
	end
	if locked or result == nil then
		return nil, "locked"
	end
	return result :: Types.Profile, nil
end

local function save(player: Player, releaseLock: boolean)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	profile.lastSeen = os.time()
	if memoryOnly or not store then
		return
	end
	local ds = store :: DataStore
	local snapshot = profile
	local ok, err = pcall(function()
		ds:UpdateAsync(keyFor(player), function(old)
			if old ~= nil and lockIsHeldElsewhere(old) then
				return nil -- never overwrite a profile another server now owns
			end
			local data = table.clone(snapshot)
			data.lock = if releaseLock then nil else { jobId = game.JobId, time = os.time() }
			return data
		end)
	end)
	if not ok then
		warn(("[%s] save failed for %s: %s"):format(Config.WorkingTitle, player.Name, tostring(err)))
	end
end

local function sanitized(profile: Types.Profile): Types.Profile
	local copy = table.clone(profile)
	copy.lock = nil
	return copy
end

local function onPlayerAdded(player: Player)
	local profile: Types.Profile? = nil
	local lastErr: string? = nil
	for attempt = 1, LOAD_RETRIES do
		local p, err = tryLoad(player)
		if p then
			profile = p
			break
		end
		lastErr = err
		if err ~= "locked" then
			break
		end
		task.wait(LOAD_RETRY_SECONDS)
		if player.Parent ~= Players then
			return
		end
	end
	if not profile then
		local strings = require(Shared.strings.en)
		player:Kick(if lastErr == "locked" then strings.ERR_LOCKED else strings.ERR_LOAD)
		return
	end
	local now = os.time()
	if profile.firstSeen == 0 then
		profile.firstSeen = now
	end
	profiles[player.UserId] = profile
	-- Other services settle the profile first (module states, offline income), so the one payload the
	-- client boots from is already current. A failing callback must not keep the player from loading.
	for _, callback in ipairs(loadedCallbacks) do
		local ok, err = pcall(function(): any
			callback(player, profile)
			return nil
		end)
		if not ok then
			warn(("[%s] OnLoaded callback failed for %s: %s"):format(Config.WorkingTitle, player.Name, tostring(err)))
		end
	end
	if player.Parent ~= Players then
		return
	end
	Net.event("ProfileLoaded"):FireClient(player, sanitized(profile))
	print(("[%s] profile loaded for %s (scrap=%d, memoryOnly=%s)"):format(Config.WorkingTitle, player.Name, profile.scrap, tostring(memoryOnly)))
end

local function onPlayerRemoving(player: Player)
	save(player, true)
	profiles[player.UserId] = nil
	Net.forget(player)
end

-- Public API -------------------------------------------------------------

function PlayerData.Get(player: Player): Types.Profile?
	return profiles[player.UserId]
end

-- Apply a change to a loaded profile. The function receives the profile and may mutate it.
function PlayerData.Update(player: Player, fn: (Types.Profile) -> ()): boolean
	local profile = profiles[player.UserId]
	if not profile then
		return false
	end
	fn(profile)
	return true
end

-- Register a callback that runs on the live profile when it loads, before the client receives it.
function PlayerData.OnLoaded(callback: (Player, Types.Profile) -> ())
	table.insert(loadedCallbacks, callback)
end

function PlayerData.IsMemoryOnly(): boolean
	return memoryOnly
end

function PlayerData.Init()
	-- Created up front so a client that joins before its profile loads can already be listening.
	Net.event("ProfileLoaded")
	if RunService:IsStudio() and not Config.UseDataStoreInStudio then
		memoryOnly = true
		warn(("[%s] Studio: using in-memory profiles. Set Config.UseDataStoreInStudio = true after enabling Studio API access to test real saves."):format(Config.WorkingTitle))
	else
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME)
		end)
		if ok then
			store = result
		else
			memoryOnly = true
			warn(("[%s] DataStore unavailable (%s); using in-memory profiles."):format(Config.WorkingTitle, tostring(result)))
		end
	end
end

function PlayerData.Start()
	-- The client may start after ProfileLoaded already fired (Studio loads memory profiles instantly),
	-- so it can also pull the sanitized profile once its scripts are running.
	Net.func("GetProfile").OnServerInvoke = function(player: Player)
		if not Net.allow(player, "GetProfile", 2) then
			return nil
		end
		local profile = profiles[player.UserId]
		return if profile then sanitized(profile) else nil
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				save(player, false)
			end
		end
	end)

	game:BindToClose(function()
		if memoryOnly then
			return
		end
		local pending = 0
		for _, player in ipairs(Players:GetPlayers()) do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.25)
		end
	end)
end

return PlayerData
