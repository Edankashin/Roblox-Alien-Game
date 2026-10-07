--!strict
-- ServerScriptService.Server.Services.Visiting: seeing a friend's home planet (docs/GAME_DESIGN.md section 10, milestone
-- 42e; Shared/data/Visiting has the numbers, Shared/VisitRules the pure rules, Types.HomeView what a visitor is shown).
-- Every player here has a "viewing owner": the user id of the home they see, themselves unless they visit. A HomeView
-- (the owner's house grid, the aliens on display, the worlds launched from) is built from the owner's live profile when
-- they are in this server, else from their save read without the session lock (PlayerData.Peek, cached
-- PeekCacheSeconds, never written back). The server owns every outcome; the client draws the view it is pushed.
-- Two paths bring a visitor to a home:
--   * In this server (Studio, a public home server, or the owner stands here): VisitHome on a player here switches the
--     view with no teleport (Visiting.ViewHome); the owner's Visitor Book gets the name and VisitorArrived fires.
--   * The trip: the owner's home is a reserved server of the home place, its access code kept in a MemoryStore map
--     (first writer wins) keyed by the owner's user id. Launch.Trip teleports the visitor with the code and the owner's
--     id in the teleport data; on arrival (the OnLoaded hook below) the teleport data is read once and is the viewing
--     owner. The owner's own fly home teleports to that same server (the HomeOptions hook Launch calls), so friends
--     already there see them arrive. Studio and a home place without an id never take this path (NoPlace).
-- The lock level (Settings HomeLock) is checked on both paths from the owner's profile (live, or the Peek on the trip).
-- The in-server path reads the lock again after the friend check (which yields), a visitor's newest request wins over an
-- older one still waiting (VisitRules.NextRequest), and an owner who tightens the lock sends every guest who no longer
-- qualifies back to their own home (Settings.OnChanged, closeHome; the guest hears HomeClosed, then HomeView(nil)).
-- VisitHome takes only plausible user ids (VisitRules.IsOwnerId), and the reads it causes of other players' saves and
-- home servers share one token bucket for the server (data/Visiting LookupBurst, LookupRefillSeconds): when it is empty
-- the answer is Crowded.
-- Wave at a displayed alien pays the visitor and the owner a little Scrap through Gifts.GrantRewards, capped per day
-- (VisitRules), once per alien per owner per day however often the visitor comes back, and only from within
-- VisitingData.WaveDistance of the owner's plot; an owner who is not in the server is paid through the HomeInbox.
-- The HomeInbox (DataStore HomeInbox, key = owner id, Types.HomeInbox) is what visitors leave for an owner who is not
-- here: Visitor Book lines and the day's wave count and Scrap. It is drained at the owner's next load (any place) into
-- Mail.Visited lines and one letter from "Visitors"; with memory-only profiles (Studio) it is a plain table here.
-- Views refresh when the owner builds or displays (HomeBuild.OnChanged, Habitats.OnChanged) and when they load; a viewer
-- whose owner leaves keeps the last view.
-- Nothing here yields on the boot thread: the MemoryStore map and DataStore handle are made in a pcall at Init, and
-- every GetAsync, UpdateAsync, ReserveServer and Peek runs in a remote handler or a task.spawn.
-- Requires PlayerData, Analytics, Launch (hooks, Trip), HomeBuild and Habitats (listeners), Mail, Meadow (the plot's
-- place), Gifts and Settings and shared code; the bootstrap requires every service before it runs any Init, so Gifts and
-- Settings (later in the order) are only called from handlers and Settings.OnChanged (a list append), after every module
-- is loaded. Only the bootstrap and Dev require this module.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local Home = require(Shared.data.Home)
local VisitingData = require(Shared.data.Visiting)
local SettingsData = require(Shared.data.Settings)
local MailData = require(Shared.data.Mail)
local AnalyticsData = require(Shared.data.Analytics)
local Strings = require(Shared.strings.en)
local VisitRules = require(Shared.VisitRules)
local TokenBucket = require(Shared.TokenBucket)
local Proximity = require(Shared.Proximity)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Launch = require(script.Parent.Launch)
local HomeBuild = require(script.Parent.HomeBuild)
local Habitats = require(script.Parent.Habitats)
local Mail = require(script.Parent.Mail)
local Meadow = require(script.Parent.Meadow)
local Gifts = require(script.Parent.Gifts)
local Settings = require(script.Parent.Settings)

local Visiting = {}

local VISIT_RATE_PER_SECOND = 2 -- VisitHome calls per player per second
local WAVE_RATE_PER_SECOND = 4 -- Wave calls per player per second
local GET_RATE_PER_SECOND = 2 -- GetVisit calls per player per second
local HOME_LOCK_KEY = "HomeLock" -- the Settings row that says who may visit

type Fetch = { waiters: { thread }, profile: Types.Profile? }
type Peeked = { profile: Types.Profile, at: number }

local viewing: { [number]: number } = {} -- the owner a player looks at, by UserId; absent = their own home
local onTrip: { [number]: boolean } = {} -- true for a player who arrived by teleport at another's home server (not an in-server view)
local waved: { [number]: Types.WavedBook } = {} -- the displayed aliens a player waved at today, by owner, by UserId (kept across views)
local viewRequests: { [number]: number } = {} -- the number of each player's newest visit request or leave, by UserId (VisitRules.NextRequest)
local views: { [number]: Types.HomeView } = {} -- the last view built of each owner, kept while anyone looks at it
local peeked: { [number]: Peeked } = {} -- owners' saves read without a lock, by owner id
local fetching: { [number]: Fetch } = {} -- a Peek in flight, by owner id; later askers wait for it
local names: { [number]: string } = {} -- owner names looked up from the user id, by owner id
local memoryInbox: { [number]: Types.HomeInbox } = {} -- the inbox when there is no DataStore (Studio), by owner id

local homeMap: MemoryStoreSortedMap? = nil
local inboxStore: DataStore? = nil
-- Reads of another player's save (PlayerData.Peek) and of the home server map, for every visitor together.
local lookupBudget = TokenBucket.New(VisitingData.LookupBurst, VisitingData.LookupRefillSeconds, os.clock())

local function log(message: string)
	print(("[%s] Visiting: %s"):format(Config.WorkingTitle, message))
end

-- The name other players see for a player: the display name, the username when there is none (the Visit screen lists
-- display names, so the Visitor Book, the arrival toast and the wave toast say the same name). Logs keep usernames.
local function shownName(player: Player): string
	return if player.DisplayName ~= "" then player.DisplayName else player.Name
end

-- Where the player's character stands (its root), or nil while it has none.
local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Where the home's plot stands: its centre and half its side. nil when this place has no plot.
local function plotSquare(): (Vector3?, number)
	local centre = Meadow.GetPlotCenter()
	local layout = Place.Layout()
	local cells, studs = layout.PlotCells, layout.PlotCellStuds
	if centre == nil or cells == nil or studs == nil then
		return nil, 0
	end
	return centre, cells * studs / 2
end

-- Names and views --------------------------------------------------------

-- The owner's name: the live Player's, else the one looked up from the user id (kept), else the data's fallback.
-- Yields only for an owner who is not here and not looked up yet.
local function nameOf(ownerId: number): string
	local live = Players:GetPlayerByUserId(ownerId)
	if live then
		names[ownerId] = shownName(live)
		return names[ownerId]
	end
	local known = names[ownerId]
	if known then
		return known
	end
	local ok, result = pcall(function(): string
		return Players:GetNameFromUserIdAsync(ownerId)
	end)
	if ok and type(result) == "string" then
		names[ownerId] = result
		return result
	end
	return Strings.VISIT_UNKNOWN_NAME
end

-- What a visitor sees of a home, from a profile (live or a save read without a lock): the house grid, a copy of every
-- record whose habitat is a placed item, and the worlds with an outpost (the hangar), ascending.
local function buildView(ownerId: number, ownerName: string, profile: Types.Profile): Types.HomeView
	local displayed: { [string]: Types.AlienRecord } = {}
	for uid, record in pairs(profile.aliens) do
		local at = record.habitat
		if at ~= nil and profile.home.items[at] ~= nil then
			displayed[uid] = table.clone(record)
		end
	end
	local launched: { number } = {}
	for key in pairs(profile.world.outposts) do
		local worldId = tonumber(key)
		if worldId then
			table.insert(launched, worldId)
		end
	end
	table.sort(launched)
	return { ownerId = ownerId, ownerName = ownerName, items = profile.home.items, displayed = displayed, launchedWorlds = launched }
end

-- The view of a home whose owner is in this server with a loaded profile, rebuilt now and kept; nil when not. Never yields.
local function liveView(ownerId: number): Types.HomeView?
	local owner = Players:GetPlayerByUserId(ownerId)
	local profile = if owner then PlayerData.Get(owner) else nil
	if not owner or not profile then
		return nil
	end
	local view = buildView(ownerId, shownName(owner), profile)
	views[ownerId] = view
	return view
end

local function storePeek(ownerId: number, profile: Types.Profile)
	local now = os.clock()
	for id, entry in pairs(peeked) do
		if now - entry.at >= VisitingData.PeekCacheSeconds then
			peeked[id] = nil
		end
	end
	peeked[ownerId] = { profile = profile, at = now }
end

-- The owner's profile: the live one when they are in this server, else their save read without the lock (kept
-- PeekCacheSeconds; a lookup already running answers every asker). nil when there is no save or it cannot be read.
-- `charged` (a visitor's request) spends a token of the server's lookup budget on a save that has to be read, and
-- answers nil with the reason "Crowded" when none is left; the live profile, the cache and a read already running cost
-- nothing. Yields on a Peek. Whatever it returns is read only.
local function profileOf(ownerId: number, charged: boolean?): (Types.Profile?, string?)
	local owner = Players:GetPlayerByUserId(ownerId)
	local live = if owner then PlayerData.Get(owner) else nil
	if live then
		return live, nil
	end
	local cached = peeked[ownerId]
	if cached and os.clock() - cached.at < VisitingData.PeekCacheSeconds then
		return cached.profile, nil
	end
	local running = fetching[ownerId]
	if running then
		table.insert(running.waiters, coroutine.running())
		coroutine.yield()
		return running.profile, nil
	end
	if charged and not TokenBucket.Take(lookupBudget, os.clock()) then
		return nil, "Crowded"
	end
	local fetch: Fetch = { waiters = {}, profile = nil }
	fetching[ownerId] = fetch
	local ok, result = pcall(PlayerData.Peek, ownerId)
	fetching[ownerId] = nil
	if ok then
		fetch.profile = result
	else
		warn(("[%s] Visiting: reading the save of %d failed: %s"):format(Config.WorkingTitle, ownerId, tostring(result)))
	end
	local found = fetch.profile
	if found then
		storePeek(ownerId, found)
	end
	for _, waiter in ipairs(fetch.waiters) do
		task.spawn(waiter)
	end
	return found, nil
end

-- The view of an owner's home from whatever answers (live profile, save, or the last view kept); nil when none does.
-- Yields when the owner's save has to be read.
local function viewFor(ownerId: number): Types.HomeView?
	local live = liveView(ownerId)
	if live then
		return live
	end
	local profile = profileOf(ownerId)
	if not profile then
		return views[ownerId]
	end
	local view = buildView(ownerId, nameOf(ownerId), profile)
	views[ownerId] = view
	return view
end

-- Drops the kept view of every owner nobody looks at and who is not here (`leaving` is still in Players during its
-- PlayerRemoving, so it counts as gone).
local function pruneViews(leaving: Player?)
	for ownerId in pairs(views) do
		local here = Players:GetPlayerByUserId(ownerId)
		local ownerStays = here ~= nil and here ~= leaving
		local watched = false
		for userId, viewed in pairs(viewing) do
			if viewed == ownerId and (leaving == nil or userId ~= leaving.UserId) then
				watched = true
				break
			end
		end
		if not ownerStays and not watched then
			views[ownerId] = nil
		end
	end
end

local function pushView(player: Player, view: Types.HomeView?)
	Net.event("HomeView"):FireClient(player, view)
end

-- Pushes a rebuilt view of this owner's home to everyone in this server who looks at it.
local function refreshViewers(ownerId: number)
	local viewers: { Player } = {}
	for userId, viewed in pairs(viewing) do
		if viewed == ownerId then
			local viewer = Players:GetPlayerByUserId(userId)
			if viewer then
				table.insert(viewers, viewer)
			end
		end
	end
	if #viewers == 0 then
		return
	end
	local view = liveView(ownerId)
	if not view then
		return
	end
	for _, viewer in ipairs(viewers) do
		pushView(viewer, view)
	end
end

-- Switches a player's view to another owner's home and the client is told. The waved book stays: an alien already
-- waved at today stays waved at, however often the visitor switches views.
local function setViewing(player: Player, ownerId: number, view: Types.HomeView)
	viewing[player.UserId] = ownerId
	onTrip[player.UserId] = nil -- an in-server view: going home is leaving the view
	pushView(player, view)
end

-- The HomeInbox ----------------------------------------------------------

local function emptyInbox(): Types.HomeInbox
	return { visitors = {}, waves = { day = 0, count = 0, scrap = 0 } }
end

-- A stored value read as an inbox: anything that is not a table with the two fields starts empty.
local function normalized(old: any): Types.HomeInbox
	if type(old) ~= "table" then
		return emptyInbox()
	end
	local stored: { [string]: any } = old
	local visitors = if type(stored.visitors) == "table" then stored.visitors else {}
	local waves = if type(stored.waves) == "table" then stored.waves else { day = 0, count = 0, scrap = 0 }
	return { visitors = visitors, waves = waves }
end

local function isEmpty(inbox: Types.HomeInbox): boolean
	return #inbox.visitors == 0 and inbox.waves.count <= 0
end

-- Applies `fn` to the owner's inbox (a copy of what is stored, or an empty one) and keeps the newest MaxVisitors names.
-- `fn` may run more than once (UpdateAsync retries), so it must work from the inbox it is given alone. The write runs
-- in its own thread; with memory-only profiles, or no store, it changes this server's table at once.
local function appendInbox(ownerId: number, fn: (Types.HomeInbox) -> ())
	local function apply(old: any): Types.HomeInbox
		local inbox = normalized(old)
		fn(inbox)
		while #inbox.visitors > MailData.MaxVisitors do
			table.remove(inbox.visitors, 1)
		end
		return inbox
	end
	local store = inboxStore
	if PlayerData.IsMemoryOnly() or store == nil then
		memoryInbox[ownerId] = apply(memoryInbox[ownerId])
		return
	end
	task.spawn(function()
		local ok, err = pcall(function(): any
			return store:UpdateAsync(tostring(ownerId), apply)
		end)
		if not ok then
			warn(("[%s] Visiting: the inbox of %d could not be written: %s"):format(Config.WorkingTitle, ownerId, tostring(err)))
		end
	end)
end

-- Puts a drained inbox back in front of what has arrived since (the owner left before it could be delivered).
local function restoreInbox(ownerId: number, older: Types.HomeInbox)
	appendInbox(ownerId, function(inbox: Types.HomeInbox)
		for index, visitor in ipairs(older.visitors) do
			table.insert(inbox.visitors, index, visitor)
		end
		if older.waves.count > 0 then
			if inbox.waves.count == 0 then
				inbox.waves = older.waves
			elseif inbox.waves.day == older.waves.day then
				inbox.waves = { day = inbox.waves.day, count = inbox.waves.count + older.waves.count, scrap = inbox.waves.scrap + older.waves.scrap }
			end
		end
	end)
end

-- Takes everything visitors left for this player and delivers it: one Visitor Book line each, in order, and one letter
-- from "Visitors" with the waves' Scrap. Yields (UpdateAsync): run it in its own thread.
local function drainInbox(player: Player)
	local ownerId = player.UserId
	local taken: Types.HomeInbox? = nil
	local store = inboxStore
	if PlayerData.IsMemoryOnly() or store == nil then
		taken = memoryInbox[ownerId]
		memoryInbox[ownerId] = nil
	else
		local ok, err = pcall(function(): any
			return store:UpdateAsync(tostring(ownerId), function(old: any): any
				taken = if old ~= nil then normalized(old) else nil
				local found = taken
				if found == nil or isEmpty(found) then
					return nil -- nothing to take: the store is left alone
				end
				return emptyInbox()
			end)
		end)
		if not ok then
			warn(("[%s] Visiting: the inbox of %s could not be read: %s"):format(Config.WorkingTitle, player.Name, tostring(err)))
			return
		end
	end
	local inbox = taken
	if inbox == nil or isEmpty(inbox) then
		return
	end
	if player.Parent ~= Players or PlayerData.Get(player) == nil then
		restoreInbox(ownerId, inbox) -- left meanwhile: nothing is lost, it waits for the next load
		return
	end
	for _, visitor in ipairs(inbox.visitors) do
		Mail.Visited(player, visitor.name)
	end
	if inbox.waves.count > 0 then
		local rewards: { Types.SocialReward } = {}
		if inbox.waves.scrap > 0 then
			table.insert(rewards, { kind = "scrap", amount = inbox.waves.scrap })
		end
		Mail.Send(player, Strings.MAIL_FROM_VISITORS, Strings.MAIL_WAVES_TEXT:format(inbox.waves.count), rewards)
	end
	log(("%s collects %d visitor(s) and %d wave(s) left while away"):format(player.Name, #inbox.visitors, inbox.waves.count))
end

-- Reserved servers -------------------------------------------------------

-- The access code of an owner's home server: the MemoryStore map's, else a freshly reserved server whose code is
-- written first-writer-wins (a second reserve made at the same moment is discarded). nil when anything fails.
-- Yields: run it from a handler or a thread.
local function reservedCode(ownerId: number, placeId: number): string?
	local map = homeMap
	if not map then
		return nil
	end
	local key = tostring(ownerId)
	local okGet, existing = pcall(function(): any
		return map:GetAsync(key)
	end)
	if not okGet then
		warn(("[%s] Visiting: the home server map could not be read: %s"):format(Config.WorkingTitle, tostring(existing)))
		return nil
	end
	if type(existing) == "table" and type((existing :: { [string]: any }).code) == "string" then
		return (existing :: { [string]: any }).code
	end
	local okReserve, code, serverId = pcall(function(): (string, string)
		return TeleportService:ReserveServer(placeId)
	end)
	if not okReserve then
		warn(("[%s] Visiting: reserving a home server failed: %s"):format(Config.WorkingTitle, tostring(code)))
		return nil
	end
	local okSet, value = pcall(function(): any
		return map:UpdateAsync(key, function(old: any): any
			if old ~= nil then
				return old
			end
			return { code = code, serverId = serverId, at = os.time() }
		end, VisitingData.CodeTtlSeconds)
	end)
	if not okSet or type(value) ~= "table" or type((value :: { [string]: any }).code) ~= "string" then
		warn(("[%s] Visiting: the home server map could not be written: %s"):format(Config.WorkingTitle, tostring(value)))
		return nil
	end
	return (value :: { [string]: any }).code
end

-- Teleport options that land in the owner's reserved home server, with the owner's id in the teleport data.
local function optionsFor(ownerId: number, code: string): TeleportOptions
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = code
	options:SetTeleportData({ [VisitingData.TeleportDataKey] = ownerId })
	return options
end

local function homeWorld(): Worlds.WorldDef
	return Worlds[Home.WorldId]
end

-- Whether a visit can teleport at all: the home place has an id and this is not Studio.
local function homePlaceIsLive(): boolean
	return homeWorld().placeId > 0 and not RunService:IsStudio()
end

-- Launch's HomeOptions hook: the player's OWN reserved home server. nil in Studio, with no live home place, or when
-- the lookup fails (the public home place is used then, as before).
local function homeOptions(player: Player): TeleportOptions?
	if not homePlaceIsLive() then
		return nil
	end
	local code = reservedCode(player.UserId, homeWorld().placeId)
	if not code then
		return nil
	end
	return optionsFor(player.UserId, code)
end

-- Locks ------------------------------------------------------------------

-- Whether the two are Roblox friends. IsFriendsWithAsync yields and errors for ids Roblox does not know: false then.
local function areFriends(player: Player, otherId: number): boolean
	local ok, result = pcall(function(): boolean
		return player:IsFriendsWithAsync(otherId)
	end)
	return ok and result == true
end

-- The HomeLock level a stored profile carries, the data default when it has none.
local function storedLock(profile: Types.Profile): number
	local stored = profile.settings[HOME_LOCK_KEY]
	if stored ~= nil then
		return stored
	end
	local def = SettingsData.ById[HOME_LOCK_KEY]
	return if def then def.default else VisitingData.LockOwnerOnly
end

-- Whether `lock` lets the visitor in; a friend check (which yields) only when the lock asks for one.
local function mayEnter(visitor: Player, ownerId: number, lock: number): (boolean, string?)
	local friend = lock == VisitingData.LockFriends and areFriends(visitor, ownerId)
	return VisitRules.CanVisit(lock, visitor.UserId, ownerId, friend)
end

-- Whether the visitor may be in this player's home under the lock as it stands when the answer is ready. The friend check
-- yields and the owner may change the lock meanwhile, so the lock is read again after it; the friend answer is the one
-- the check gave. (The owner must still be here: a player who left has no lock to read.)
local function mayStay(visitor: Player, owner: Player): (boolean, string?)
	local friend = Settings.Get(owner, HOME_LOCK_KEY) == VisitingData.LockFriends and areFriends(visitor, owner.UserId)
	return VisitRules.CanVisit(Settings.Get(owner, HOME_LOCK_KEY), visitor.UserId, owner.UserId, friend)
end

-- The teleport data: the owner this player was sent to see, or nil (a direct join, a plain teleport, their own id).
local function teleportOwner(player: Player): number?
	local ok, data = pcall(function(): any
		return player:GetJoinData().TeleportData
	end)
	if not ok or type(data) ~= "table" then
		return nil
	end
	local value = (data :: { [string]: any })[VisitingData.TeleportDataKey]
	if VisitRules.IsOwnerId(value, RunService:IsStudio()) and value ~= player.UserId then
		return value
	end
	return nil
end

-- Public API -------------------------------------------------------------

-- The user id of the home this player is looking at: their own unless they visit.
function Visiting.OwnerOf(player: Player): number
	return viewing[player.UserId] or player.UserId
end

-- Whether the player is a guest: looking at another's home, or standing at a place that is not the world their ship is
-- on (Launch lets a guest fly to the ship's world without moving the profile).
function Visiting.IsGuest(player: Player): boolean
	if Visiting.OwnerOf(player) ~= player.UserId then
		return true
	end
	local profile = PlayerData.Get(player)
	return profile ~= nil and Place.WorldId() ~= profile.world.current
end

-- Whether the player looks at another home in THIS server (the in-server visit), as opposed to having travelled to
-- the owner's home server. Launch asks before a flight home: an in-server visitor's own home is right here.
function Visiting.IsInServerView(player: Player): boolean
	return viewing[player.UserId] ~= nil and onTrip[player.UserId] ~= true
end

-- Back to looking at their own home and the client hears HomeView(nil). A visit request still waiting on its friend
-- check is replaced by this (it ends without a view); what the player waved at today stays waved at.
function Visiting.LeaveView(player: Player)
	local previous = viewing[player.UserId]
	viewing[player.UserId] = nil
	VisitRules.NextRequest(viewRequests, player.UserId)
	pushView(player, nil)
	if previous ~= nil then
		log(("%s is back at their own home"):format(player.Name))
		pruneViews(nil)
	end
end

-- The in-server visit: `owner` is a player here and this place is the home. Returns true, or false with a reason:
-- NotAtHome, Self, NoProfile, OwnerOnly or FriendsOnly (the lock), NoHome (the owner's home is not unlocked),
-- Superseded (the visitor asked for another view, or left, while the friend check ran). Viewing the owner already
-- viewed answers true and changes nothing. Yields for the friend check only; after it the request is dropped unless it
-- is still the visitor's newest, both players are still here, and the lock (read again) still lets the visitor in.
function Visiting.ViewHome(player: Player, owner: Player): (boolean, string?)
	if not Place.IsHome() then
		return false, "NotAtHome"
	end
	if owner == player then
		return false, "Self"
	end
	local request = VisitRules.NextRequest(viewRequests, player.UserId)
	local ownerId = owner.UserId
	if viewing[player.UserId] == ownerId then
		return true, nil
	end
	if not PlayerData.Get(player) or not PlayerData.Get(owner) then
		return false, "NoProfile"
	end
	local allowed, why = mayStay(player, owner)
	if not VisitRules.IsLatestRequest(viewRequests, player.UserId, request) then
		return false, "Superseded"
	end
	local ownerProfile = PlayerData.Get(owner)
	if player.Parent ~= Players or owner.Parent ~= Players or not ownerProfile then
		return false, "NoProfile" -- one of them left during the friend check
	end
	if not allowed then
		return false, why
	end
	if not ownerProfile.home.unlocked then
		return false, "NoHome"
	end
	local view = liveView(ownerId)
	if not view then
		return false, "NoProfile"
	end
	setViewing(player, ownerId, view)
	Mail.Visited(owner, shownName(player))
	Net.event("VisitorArrived"):FireClient(owner, shownName(player))
	Analytics.Event(player, AnalyticsData.Events.Visit, 1, { owner = tostring(ownerId), how = "here" })
	log(("%s visits %s's home in this server"):format(player.Name, owner.Name))
	return true, nil
end

-- The owner changed their lock: everyone looking at their home who no longer qualifies goes back to their own home, with
-- HomeClosed (the owner's name and OwnerOnly or FriendsOnly) for the toast before the HomeView(nil). Under Friends each
-- guest's friend check runs in its own thread (it yields); a guest who left, looks elsewhere by then, or whose owner
-- left is left alone.
local function closeHome(owner: Player)
	local ownerId = owner.UserId
	local guests: { Player } = {}
	for userId, viewed in pairs(viewing) do
		local guest = if viewed == ownerId and userId ~= ownerId then Players:GetPlayerByUserId(userId) else nil
		if guest then
			table.insert(guests, guest)
		end
	end
	for _, guest in ipairs(guests) do
		task.spawn(function()
			local allowed, why = mayStay(guest, owner)
			if allowed or guest.Parent ~= Players or owner.Parent ~= Players or PlayerData.Get(owner) == nil or viewing[guest.UserId] ~= ownerId then
				return
			end
			Net.event("HomeClosed"):FireClient(guest, shownName(owner), why)
			Visiting.LeaveView(guest)
			log(("%s's home closed to %s (%s); they look at their own"):format(owner.Name, guest.Name, tostring(why)))
		end)
	end
end

-- Settings.OnChanged: a home lock that is not Anyone sends the guests it does not admit home.
local function onSettingChanged(owner: Player, key: string, _previous: number, value: number)
	if key == HOME_LOCK_KEY and value ~= VisitingData.LockAnyone then
		closeHome(owner)
	end
end

-- Remotes ----------------------------------------------------------------

-- VisitHome(ownerId) -> (ok, reason). Reasons: BadArgs (not a whole number from 1 to VisitingData.MaxUserId; Studio's
-- negative test ids pass in Studio only), RateLimited, NoProfile, Self, then the in-server path's (Visiting.ViewHome's)
-- when the owner is a player here at the home place; else the trip path's: NoPlace (no live home place), Away (the
-- owner's save or home server cannot be reached), NoHome, OwnerOnly, FriendsOnly, Busy (a flight is already in
-- progress), Crowded (the server's budget for reading other players' saves and home servers is spent for now).
local function onVisitHome(player: Player, ownerArg: any): (boolean, string?)
	if type(ownerArg) ~= "number" or not VisitRules.IsOwnerId(ownerArg, RunService:IsStudio()) then
		return false, "BadArgs"
	end
	if not Net.allow(player, "VisitHome", VISIT_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	local ownerId: number = ownerArg
	if ownerId == player.UserId then
		return false, "Self"
	end
	if viewing[player.UserId] == ownerId then
		return true, nil -- already there (in this server or arrived by trip): nothing to change, nowhere to fly
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	if owner and Place.IsHome() then
		return Visiting.ViewHome(player, owner)
	end
	-- The trip.
	local world = homeWorld()
	if not homePlaceIsLive() then
		return false, "NoPlace"
	end
	local ownerProfile, refusal = profileOf(ownerId, true)
	if not ownerProfile then
		return false, refusal or "Away"
	end
	if not ownerProfile.home.unlocked then
		return false, "NoHome"
	end
	local allowed, why = mayEnter(player, ownerId, storedLock(ownerProfile))
	if not allowed then
		return false, why
	end
	if not TokenBucket.Take(lookupBudget, os.clock()) then
		return false, "Crowded" -- the home server map read below is a lookup too
	end
	local code = reservedCode(ownerId, world.placeId)
	if not code then
		return false, "Away"
	end
	if player.Parent ~= Players then
		return false, "NoProfile"
	end
	local started = Launch.Trip(player, world, optionsFor(ownerId, code))
	if not started then
		return false, "Busy"
	end
	Analytics.Event(player, AnalyticsData.Events.Visit, 1, { owner = tostring(ownerId), how = "trip" })
	log(("%s takes a trip to the home of %d"):format(player.Name, ownerId))
	return true, nil
end

-- Wave(uid) -> (ok, reason, species, scrap): a wave at a displayed alien of the home the player looks at. Reasons:
-- BadArgs, RateLimited, NoProfile, NotVisiting, NotDisplayed, NoCharacter, TooFar (farther than VisitingData.WaveDistance
-- from the owner's plot, where the aliens roam), Again (this alien already got one from this player today), Cap
-- (today's waves are used up). On ok, the visitor's Scrap and `species`; the owner is paid at once when here (up to
-- their day's room), else through their inbox. Nothing yields between the checks and the payments.
local function onWave(player: Player, uid: any): (boolean, string?, string?, number?)
	if type(uid) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "Wave", WAVE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local ownerId = viewing[player.UserId]
	if ownerId == nil or ownerId == player.UserId then
		return false, "NotVisiting"
	end
	local view = liveView(ownerId) or views[ownerId]
	local record = if view then view.displayed[uid] else nil
	if not record then
		return false, "NotDisplayed"
	end
	local at = rootPosition(player)
	if not at then
		return false, "NoCharacter"
	end
	local plot, half = plotSquare()
	if plot == nil or not Proximity.WithinSquare(at.X, at.Z, plot.X, plot.Z, half, VisitingData.WaveDistance) then
		return false, "TooFar" -- also what a position that is not a number answers
	end
	local now = os.time()
	if VisitRules.HasWaved(waved[player.UserId], now, ownerId, uid) then
		return false, "Again"
	end
	if VisitRules.WavesLeft(profile.home.waves, now) <= 0 then
		return false, "Cap"
	end
	local species = record.species
	local sources = AnalyticsData.Economy.Sources
	waved[player.UserId] = VisitRules.MarkWaved(waved[player.UserId], now, ownerId, uid)

	-- The visitor.
	local amount = VisitingData.WaveScrapVisitor
	PlayerData.Update(player, function(p: Types.Profile)
		p.home.waves = VisitRules.AfterWave(p.home.waves, now)
	end)
	Gifts.GrantRewards(player, { { kind = "scrap", amount = amount } })
	Analytics.Economy(player, "Source", amount, profile.scrap, "Gameplay", sources.Wave)
	Analytics.Event(player, AnalyticsData.Events.Wave, amount, { owner = tostring(ownerId), species = species })

	-- The owner: here, or through the inbox.
	local owner = Players:GetPlayerByUserId(ownerId)
	local ownerProfile = if owner then PlayerData.Get(owner) else nil
	if owner and ownerProfile then
		local scrap = math.min(VisitingData.WaveScrapOwner, VisitRules.OwnerRoom(ownerProfile.home.waves, now))
		PlayerData.Update(owner, function(p: Types.Profile)
			p.home.waves = VisitRules.AfterGot(p.home.waves, now, scrap)
		end)
		if scrap > 0 then
			Gifts.GrantRewards(owner, { { kind = "scrap", amount = scrap } })
			Analytics.Economy(owner, "Source", scrap, ownerProfile.scrap, "Gameplay", sources.Wave)
		end
		Net.event("WaveReceived"):FireClient(owner, shownName(player), species, scrap)
	else
		appendInbox(ownerId, function(inbox: Types.HomeInbox)
			local scrap = math.min(VisitingData.WaveScrapOwner, VisitRules.InboxRoom(inbox.waves, now))
			inbox.waves = VisitRules.AfterInboxWave(inbox.waves, now, scrap)
		end)
	end
	log(("%s waved at %d's %s (+%d Scrap)"):format(player.Name, ownerId, species, amount))
	return true, nil, species, amount
end

-- GetVisit() -> the view the player looks at, nil when they look at their own home (a client that boots late asks once).
local function onGetVisit(player: Player): Types.HomeView?
	if not Net.allow(player, "GetVisit", GET_RATE_PER_SECOND) then
		return nil
	end
	local ownerId = viewing[player.UserId]
	if ownerId == nil or ownerId == player.UserId then
		return nil
	end
	return views[ownerId]
end

-- Arrivals ---------------------------------------------------------------

-- The first look of a player sent to see an owner's home (the viewing owner is already set): the lock is checked once
-- more against the owner's profile as it is now (the sending server checked it too, but the owner may have closed the
-- home since, and a stale teleport is the one thing a client could replay), then the view is built, the owner told
-- (Visitor Book and VisitorArrived when here, the inbox when away) and the view pushed. A home that cannot be shown,
-- or is closed to them now, leaves them looking at their own. Yields (the owner's save): run it in its own thread.
local function arrive(player: Player, ownerId: number)
	local profile = profileOf(ownerId)
	local allowed = false
	local why: string? = "Away"
	if profile then
		if profile.home.unlocked then
			allowed, why = mayEnter(player, ownerId, storedLock(profile))
		else
			why = "NoHome"
		end
	end
	local view = if allowed then viewFor(ownerId) else nil
	if player.Parent ~= Players or viewing[player.UserId] ~= ownerId then
		return -- left, or already looking elsewhere
	end
	if not view then
		viewing[player.UserId] = nil
		warn(("[%s] Visiting: no home to show %s at %d (%s); they look at their own"):format(Config.WorkingTitle, player.Name, ownerId, if allowed then "no view" else tostring(why)))
		return
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	if owner and PlayerData.Get(owner) then
		Mail.Visited(owner, shownName(player))
		Net.event("VisitorArrived"):FireClient(owner, shownName(player))
	else
		local name = shownName(player)
		local at = os.time()
		appendInbox(ownerId, function(inbox: Types.HomeInbox)
			table.insert(inbox.visitors, { name = name, at = at })
		end)
	end
	Analytics.Event(player, AnalyticsData.Events.Visit, 1, { owner = tostring(ownerId), how = "arrive" })
	log(("%s arrives at the home of %s"):format(player.Name, view.ownerName))
	task.defer(pushView, player, view) -- after the profile reached the client
end

-- PlayerData.OnLoaded: runs on the load thread, so nothing here yields. The teleport data is read once; a player who
-- owns what other players look at has those views refreshed from the live profile now.
local function onLoaded(player: Player, _profile: Types.Profile)
	local ownerId = if Place.IsHome() then teleportOwner(player) else nil
	if ownerId ~= nil then
		viewing[player.UserId] = ownerId
		onTrip[player.UserId] = true -- arrived by teleport: going home is a flight to their own home server
		task.spawn(arrive, player, ownerId)
	end
	task.defer(drainInbox, player) -- after ProfileLoaded went out, so the letters it writes reach a client that has the profile
	refreshViewers(player.UserId)
end

local function onRemoving(player: Player)
	viewing[player.UserId] = nil
	onTrip[player.UserId] = nil
	viewRequests[player.UserId] = nil -- a request still waiting on its friend check finds itself replaced
	local book = waved[player.UserId]
	if book and book.day ~= VisitRules.DayOf(os.time()) then
		waved[player.UserId] = nil -- today's stays, so leaving and coming back does not wipe it; an old day's goes
	end
	pruneViews(player)
end

function Visiting.Init()
	Net.event("HomeView")
	Net.event("VisitorArrived")
	Net.event("WaveReceived")
	Net.event("HomeClosed")
	Net.func("VisitHome").OnServerInvoke = onVisitHome
	Net.func("Wave").OnServerInvoke = onWave
	Net.func("GetVisit").OnServerInvoke = onGetVisit
	-- Neither handle yields, but both can throw without API access: the service works (in memory) without them.
	local okMap, map = pcall(function(): MemoryStoreSortedMap
		return MemoryStoreService:GetSortedMap(VisitingData.MemoryStoreMap)
	end)
	if okMap then
		homeMap = map
	else
		warn(("[%s] Visiting: MemoryStore unavailable (%s); visits by trip are off."):format(Config.WorkingTitle, tostring(map)))
	end
	local okStore, store = pcall(function(): DataStore
		return DataStoreService:GetDataStore(VisitingData.InboxStoreName)
	end)
	if okStore then
		inboxStore = store
	else
		warn(("[%s] Visiting: DataStore unavailable (%s); the visitors' inbox stays in this server."):format(Config.WorkingTitle, tostring(store)))
	end
	Launch.SetVisiting({ IsGuest = Visiting.IsGuest, HomeOptions = homeOptions, LeaveView = Visiting.LeaveView, IsInServerView = Visiting.IsInServerView })
	PlayerData.OnLoaded(onLoaded)
	HomeBuild.OnChanged(function(owner: Player)
		refreshViewers(owner.UserId)
	end)
	Habitats.OnChanged(function(owner: Player)
		refreshViewers(owner.UserId)
	end)
	Settings.OnChanged(onSettingChanged)
	Players.PlayerRemoving:Connect(onRemoving)
end

function Visiting.Start()
	local world = homeWorld()
	log(("%d waves a day at %d Scrap each (the owner gets %d, up to %d a day); the home place is %s; the visitors' inbox is in %s"):format(
		VisitingData.WavesPerDay,
		VisitingData.WaveScrapVisitor,
		VisitingData.WaveScrapOwner,
		VisitingData.WaveOwnerScrapCapPerDay,
		if homePlaceIsLive() then "live (place " .. tostring(world.placeId) .. ")" else "not live (visits work in this server only)",
		if PlayerData.IsMemoryOnly() or inboxStore == nil then "this server" else "the DataStore"
	))
end

return Visiting
