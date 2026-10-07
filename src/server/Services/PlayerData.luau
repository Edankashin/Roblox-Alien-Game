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
local CinematicsData = require(Shared.data.Cinematics)
local Net = require(Shared.Net)
local ProfileSchema = require(script.Parent.Parent.ProfileSchema)
local schema = ProfileSchema.new(Config, SettingsData, Jobs, CinematicsData)
local template: () -> Types.Profile = schema.template
local migrate: (any) -> Types.Profile = schema.migrate
local isFromTheFuture = schema.isFromTheFuture

local PlayerData = {}

local STORE_NAME = "PlayerData"
local LOAD_RETRIES = 6
local LOAD_RETRY_SECONDS = 5

local profiles: { [number]: Types.Profile } = {}
-- Plain callbacks, not a BindableEvent: they run synchronously, before the join payload is sent, on the
-- live profile (a BindableEvent would hand them a copy and run after the client already has stale data).
local loadedCallbacks: { (Player, Types.Profile) -> () } = {}
local store: DataStore? = nil
local memoryOnly = false

local function keyOf(userId: number): string
	return "User_" .. tostring(userId)
end

local function keyFor(player: Player): string
	return keyOf(player.UserId)
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
	local newer = false
	local ok, result = pcall(function()
		return ds:UpdateAsync(keyFor(player), function(old)
			if old ~= nil and lockIsHeldElsewhere(old) then
				locked = true
				return nil -- cancel: another server holds this profile
			end
			if old ~= nil and isFromTheFuture(old) then
				newer = true
				return nil -- cancel: a newer game version wrote this save; this server must not own it
			end
			local data = if old ~= nil then migrate(old) else migrate(template())
			data.lock = { jobId = game.JobId, time = os.time() }
			return data
		end)
	end)
	if not ok then
		return nil, tostring(result)
	end
	if newer then
		return nil, "newer"
	end
	if locked or result == nil then
		return nil, "locked"
	end
	return result :: Types.Profile, nil
end

-- Writes the player's profile. Answers true when the write landed (or there is no store to write to:
-- memory-only profiles), false when it failed or another server holds the lock.
local function save(player: Player, releaseLock: boolean): boolean
	local profile = profiles[player.UserId]
	if not profile then
		return false
	end
	profile.lastSeen = os.time()
	if memoryOnly or not store then
		return true
	end
	local ds = store :: DataStore
	local snapshot = profile
	local written = false
	local ok, err = pcall(function()
		ds:UpdateAsync(keyFor(player), function(old)
			if old ~= nil and lockIsHeldElsewhere(old) then
				written = false
				return nil -- never overwrite a profile another server now owns
			end
			local data = table.clone(snapshot)
			data.lock = if releaseLock then nil else { jobId = game.JobId, time = os.time() }
			written = true
			return data
		end)
	end)
	if not ok then
		warn(("[%s] save failed for %s: %s"):format(Config.WorkingTitle, player.Name, tostring(err)))
		return false
	end
	return written
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
		player:Kick(if lastErr == "locked" then strings.ERR_LOCKED elseif lastErr == "newer" then strings.ERR_NEWER else strings.ERR_LOAD)
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

-- Writes the profile now and answers whether it landed (true for memory-only profiles). Yields. For a
-- moment that must be durable before the game answers anyone: a paid receipt (Monetization) is reported
-- granted only after this succeeds.
function PlayerData.SaveNow(player: Player): boolean
	return save(player, false)
end

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

-- A look at another player's save without the session lock (Visiting shows an away owner's home from it): the
-- stored data migrated in memory, never written back, never kept here (the caller caches). nil with memory-only
-- profiles, when the store is unreachable (a warning) or when no save exists. The copy may be minutes old when
-- that player is online in another server, and nothing read from it may be written anywhere. Yields (GetAsync).
function PlayerData.Peek(userId: number): Types.Profile?
	if memoryOnly or not store then
		return nil
	end
	local ds = store :: DataStore
	local ok, result = pcall(function()
		return ds:GetAsync(keyOf(userId))
	end)
	if not ok then
		warn(("[%s] peek at %d failed: %s"):format(Config.WorkingTitle, userId, tostring(result)))
		return nil
	end
	if result == nil then
		return nil
	end
	return sanitized(migrate(result))
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
