--!strict
-- ServerScriptService.Server.Services.Leaderboard: the weekly "Catches this week" board
-- (docs/vault/01-game-design/Growth-Playbook.md section 4; every number in Shared/data/Leaderboard, the
-- period clock in Shared/LeaderboardMath). Economy.GrantAlien reports each catch through OnCatch. A catch
-- counts into pending (at most CatchCapPerMinute per player in a sliding minute), a flush adds each
-- player's pending to their entry in this period's OrderedDataStore (name LeaderboardMath.StoreKey, key =
-- the UserId text) at most once per FlushSeconds, on leave and on shutdown, and one GetSortedAsync per
-- server per FetchSeconds feeds every client through LeaderboardChanged (and GetLeaderboard, which only
-- ever returns what is cached). When the period rolls over the old period's pending goes to the old store
-- and the new period starts empty. With memory-only profiles (Studio without API access) the store is never
-- touched: pending moves straight into known and the board is this server's players only.
--
-- Payload (LeaderboardChanged and GetLeaderboard): { periodId, resetsAt, ["local"], rows, own } where rows
-- is { { userId, name, count } } best first, and own maps each present player's UserId text to their count
-- (known + pending, so a client finds its own count). "local" is a reserved word, so it is read as
-- payload["local"]; true means the rows are this server's players only.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local LeaderboardData = require(Shared.data.Leaderboard)
local LeaderboardMath = require(Shared.LeaderboardMath)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)

local Leaderboard = {}

export type Row = { userId: number, name: string, count: number }
export type Payload = {
	periodId: string,
	resetsAt: number,
	["local"]: boolean,
	rows: { Row },
	own: { [string]: number },
}

type Period = { id: string, stamp: number, resetsAt: number, store: OrderedDataStore? }

local GET_RATE_PER_SECOND = 2 -- GetLeaderboard calls per player per second

local period: Period
local pending: { [number]: number } = {} -- by UserId: counted, not yet sent to the store
local sending: { [number]: number } = {} -- by UserId: taken out of pending, increment in flight
local known: { [number]: number } = {} -- by UserId: the stored count this period
local knownLoaded: { [number]: boolean } = {}
local loadingKnown: { [number]: boolean } = {}
local stamps: { [number]: { number } } = {} -- by UserId: os.clock of each catch in the last window
local warnedAt: { [number]: number } = {} -- by UserId: os.clock of the last cap print
local names: { [number]: string } = {}
local nameRetryAt: { [number]: number } = {}
local cachedRows: { Row } = {}
local inflight = 0 -- store writes running now, so BindToClose can wait for them
local fetching = false

local function newPeriod(now: number): Period
	return { id = LeaderboardMath.PeriodId(now), stamp = now, resetsAt = LeaderboardMath.NextReset(now) }
end
period = newPeriod(os.time())

local function tag(): string
	return ("[%s] Leaderboard"):format(Config.WorkingTitle)
end

local function storeOf(p: Period): OrderedDataStore?
	if p.store then
		return p.store
	end
	local ok, result = pcall(function(): OrderedDataStore
		return DataStoreService:GetOrderedDataStore(LeaderboardMath.StoreKey(p.stamp))
	end)
	if not ok then
		warn(("%s: ordered store unavailable (%s)"):format(tag(), tostring(result)))
		return nil
	end
	p.store = result
	return result
end

local function countOf(userId: number): number
	return (known[userId] or 0) + (sending[userId] or 0) + (pending[userId] or 0)
end

-- Payload -----------------------------------------------------------------------

local function memoryRows(): { Row }
	local rows: { Row } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local count = countOf(player.UserId)
		if count > 0 then
			table.insert(rows, { userId = player.UserId, name = player.DisplayName, count = count })
		end
	end
	table.sort(rows, function(a: Row, b: Row): boolean
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.userId < b.userId
	end)
	while #rows > LeaderboardData.TopCount do
		table.remove(rows)
	end
	return rows
end

local function buildPayload(): Payload
	local memoryOnly = PlayerData.IsMemoryOnly()
	local own: { [string]: number } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		own[tostring(player.UserId)] = countOf(player.UserId)
	end
	return {
		periodId = period.id,
		resetsAt = period.resetsAt,
		["local"] = memoryOnly,
		rows = if memoryOnly then memoryRows() else cachedRows,
		own = own,
	}
end

local function pushAll()
	Net.event("LeaderboardChanged"):FireAllClients(buildPayload())
end

local function pushTo(player: Player)
	Net.event("LeaderboardChanged"):FireClient(player, buildPayload())
end

-- Counting ----------------------------------------------------------------------

-- One catch into pending, unless the player already counted CatchCapPerMinute in the last window. Over the
-- cap the catch is dropped, with one print per window per player.
local function countCatch(player: Player): boolean
	local userId = player.UserId
	local now = os.clock()
	local list = stamps[userId]
	if not list then
		list = {}
		stamps[userId] = list
	end
	while #list > 0 and now - list[1] >= LeaderboardData.CapWindowSeconds do
		table.remove(list, 1)
	end
	if #list >= LeaderboardData.CatchCapPerMinute then
		local last = warnedAt[userId]
		if not last or now - last >= LeaderboardData.CapWindowSeconds then
			warnedAt[userId] = now
			print(("%s: %s is over %d catches a minute; the extra catches are not counted"):format(tag(), player.Name, LeaderboardData.CatchCapPerMinute))
		end
		return false
	end
	table.insert(list, now)
	pending[userId] = (pending[userId] or 0) + 1
	return true
end

-- Store ---------------------------------------------------------------------------

-- IncrementAsync in a pcall. True and the stored count on success, false on failure (warned).
local function increment(p: Period, userId: number, amount: number): (boolean, number)
	inflight += 1
	local ok, result = pcall(function(): number
		local store = storeOf(p)
		if not store then
			error("store unavailable")
		end
		local stored = store:IncrementAsync(tostring(userId), amount)
		return stored
	end)
	inflight -= 1
	if not ok then
		warn(("%s: adding %d catches for user %d failed: %s"):format(tag(), amount, userId, tostring(result)))
		return false, 0
	end
	return true, result
end

-- Catches of a finished period go to that period's store; two tries, then they are dropped.
local function flushOld(p: Period, userId: number, amount: number)
	for attempt = 1, 2 do
		if (increment(p, userId, amount)) then
			return
		end
		if attempt == 1 then
			task.wait(LeaderboardData.RetryWaitSeconds)
		end
	end
	warn(("%s: dropped %d catches of user %d for the finished period %s"):format(tag(), amount, userId, p.id))
end

-- Sends one player's pending. The amount leaves pending before the call so two flushes can never send
-- it twice; a failure puts it back for the next flush.
local function flushOne(userId: number)
	local amount = pending[userId]
	if not amount or amount <= 0 then
		return
	end
	pending[userId] = nil
	if PlayerData.IsMemoryOnly() then
		known[userId] = (known[userId] or 0) + amount
		return
	end
	local p = period
	sending[userId] = (sending[userId] or 0) + amount
	local ok, stored = increment(p, userId, amount)
	if period ~= p then
		-- The period rolled over during the call, which already replaced the tables. A failure goes to
		-- the old period's store again; a success needs nothing.
		if not ok then
			task.spawn(flushOld, p, userId, amount)
		end
		return
	end
	local left = (sending[userId] or 0) - amount
	if left > 0 then
		sending[userId] = left
	else
		sending[userId] = nil
	end
	if ok then
		known[userId] = stored -- IncrementAsync returns the new stored count
		knownLoaded[userId] = true
	else
		pending[userId] = (pending[userId] or 0) + amount
	end
end

-- Flushes everyone with pending catches in parallel and waits for them.
local function flushAll()
	local ids: { number } = {}
	for userId, amount in pairs(pending) do
		if amount > 0 then
			table.insert(ids, userId)
		end
	end
	if PlayerData.IsMemoryOnly() then
		for _, userId in ipairs(ids) do
			flushOne(userId)
		end
		return
	end
	local remaining = #ids
	for _, userId in ipairs(ids) do
		task.spawn(function()
			flushOne(userId)
			remaining -= 1
		end)
	end
	local deadline = os.clock() + LeaderboardData.CloseWaitSeconds
	while remaining > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

-- Reads the player's stored count for this period once (and again on a flush tick while it keeps failing).
local function loadKnown(player: Player)
	local userId = player.UserId
	if knownLoaded[userId] or loadingKnown[userId] then
		return
	end
	if PlayerData.IsMemoryOnly() then
		knownLoaded[userId] = true
		known[userId] = known[userId] or 0
		return
	end
	loadingKnown[userId] = true
	local p = period
	local ok, value = pcall(function(): any
		local store = storeOf(p)
		if not store then
			error("store unavailable")
		end
		local stored = store:GetAsync(tostring(userId))
		return stored
	end)
	loadingKnown[userId] = nil
	if period ~= p or player.Parent ~= Players then
		return
	end
	if ok then
		local stored = if type(value) == "number" then value else 0
		known[userId] = math.max(known[userId] or 0, stored)
		knownLoaded[userId] = true
	else
		warn(("%s: reading the count of %s failed: %s"):format(tag(), player.Name, tostring(value)))
	end
end

-- Display names ----------------------------------------------------------------------

-- Fills the name cache for ids it lacks: UserService in batches of NameBatch, then
-- Players:GetNameFromUserIdAsync one by one for what is still missing. A failed id is not retried for a
-- while; its row shows the id as text.
local function resolveNames(ids: { number })
	local cached = 0
	for _ in pairs(names) do
		cached += 1
	end
	if cached > LeaderboardData.NameCacheMax then
		names = {}
		for _, player in ipairs(Players:GetPlayers()) do
			names[player.UserId] = player.DisplayName
		end
	end
	local clock = os.clock()
	local missing: { number } = {}
	for _, userId in ipairs(ids) do
		if names[userId] == nil and (nameRetryAt[userId] or 0) <= clock then
			table.insert(missing, userId)
		end
	end
	local first = 1
	while first <= #missing do
		local batch = table.move(missing, first, math.min(first + LeaderboardData.NameBatch - 1, #missing), 1, {})
		first += LeaderboardData.NameBatch
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(batch)
		end)
		if ok then
			for _, info in ipairs(infos) do
				local name = if info.DisplayName ~= "" then info.DisplayName else info.Username
				if name ~= "" then
					names[info.Id] = name
				end
			end
		else
			warn(("%s: display name lookup failed: %s"):format(tag(), tostring(infos)))
		end
		for _, userId in ipairs(batch) do
			if names[userId] == nil then
				local okName, name = pcall(function(): string
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if okName and name ~= "" then
					names[userId] = name
				else
					nameRetryAt[userId] = os.clock() + LeaderboardData.NameRetrySeconds
				end
			end
		end
	end
end

-- Fetch -------------------------------------------------------------------------------

-- One GetSortedAsync for this period, names for the rows, then everyone hears. A failure keeps the last rows.
local function fetchTop()
	if PlayerData.IsMemoryOnly() then
		pushAll()
		return
	end
	if fetching then
		return
	end
	fetching = true
	local p = period
	local ok, entries = pcall(function(): { any }
		local store = storeOf(p)
		if not store then
			error("store unavailable")
		end
		local pages = store:GetSortedAsync(false, LeaderboardData.TopCount)
		return pages:GetCurrentPage()
	end)
	if not ok then
		warn(("%s: fetching the top %d failed: %s"):format(tag(), LeaderboardData.TopCount, tostring(entries)))
		fetching = false
		return
	end
	local top: { { userId: number, count: number } } = {}
	local ids: { number } = {}
	for _, entry in ipairs(entries) do
		local userId = if type(entry) == "table" then tonumber(entry.key) else nil
		local count = if type(entry) == "table" then entry.value else nil
		if userId and type(count) == "number" and count > 0 then
			table.insert(top, { userId = userId, count = count })
			table.insert(ids, userId)
		end
	end
	local named, err = pcall(function(): string
		resolveNames(ids)
		return ""
	end)
	if not named then
		warn(("%s: resolving names failed: %s"):format(tag(), tostring(err)))
	end
	fetching = false
	if period ~= p then
		return -- rolled over while waiting; the new period fetches for itself
	end
	local rows: { Row } = {}
	for _, item in ipairs(top) do
		table.insert(rows, { userId = item.userId, name = names[item.userId] or tostring(item.userId), count = item.count })
	end
	cachedRows = rows
	pushAll()
end

-- Rollover -------------------------------------------------------------------------------

-- When the clock has moved into a new period: the old period's pending goes to the old store, and the
-- tables start empty for the new one. No yield before the swap, so two loops cannot both do it.
local function checkRollover()
	local now = os.time()
	if LeaderboardMath.PeriodId(now) == period.id then
		return
	end
	local old = period
	local oldPending = pending
	period = newPeriod(now)
	pending = {}
	sending = {}
	known = {}
	knownLoaded = {}
	cachedRows = {}
	print(("%s: period %s ended, %s starts"):format(tag(), old.id, period.id))
	if not PlayerData.IsMemoryOnly() then
		for userId, amount in pairs(oldPending) do
			if amount > 0 then
				task.spawn(flushOld, old, userId, amount)
			end
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(loadKnown, player)
	end
	pushAll()
end

-- Seconds to sleep: the interval, shortened so a loop wakes right after the next reset.
local function sleepSeconds(interval: number): number
	local untilReset = period.resetsAt - os.time()
	return math.max(1, math.min(interval, untilReset + 1))
end

-- Players -------------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	names[player.UserId] = player.DisplayName
	loadKnown(player)
	if player.Parent == Players then
		pushTo(player)
	end
end

local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	task.spawn(function()
		flushOne(userId)
		if (pending[userId] or 0) > 0 then
			task.wait(LeaderboardData.RetryWaitSeconds)
			flushOne(userId)
		end
		local current = Players:GetPlayerByUserId(userId)
		if current == nil or current == player then
			if (pending[userId] or 0) > 0 then
				warn(("%s: dropped %d catches of user %d who left"):format(tag(), pending[userId] or 0, userId))
			end
			pending[userId] = nil
			sending[userId] = nil
			known[userId] = nil
			knownLoaded[userId] = nil
			stamps[userId] = nil
			warnedAt[userId] = nil
		end
	end)
end

local function onGetLeaderboard(player: Player): Payload?
	if not Net.allow(player, "GetLeaderboard", GET_RATE_PER_SECOND) then
		return nil
	end
	return buildPayload()
end

-- Public API ---------------------------------------------------------------------------

-- A real catch by `player`, reported by Economy.GrantAlien. Counted into the current period unless the
-- player is over the per-minute cap.
function Leaderboard.OnCatch(player: Player)
	countCatch(player)
end

-- /lb N: N catches through the same cap. Returns how many counted.
function Leaderboard.DevAdd(player: Player, count: number): number
	local added = 0
	for _ = 1, math.floor(count) do
		if not countCatch(player) then
			break -- over the cap: the rest would all be dropped
		end
		added += 1
	end
	return added
end

-- /lb flush: send everything pending now, then refresh the board at once.
function Leaderboard.DevFlush()
	flushAll()
	fetchTop()
end

function Leaderboard.Init()
	Net.event("LeaderboardChanged")
	Net.func("GetLeaderboard").OnServerInvoke = onGetLeaderboard
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(function()
		if PlayerData.IsMemoryOnly() then
			return
		end
		flushAll()
		local deadline = os.clock() + LeaderboardData.CloseWaitSeconds
		while inflight > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

function Leaderboard.Start()
	-- Flush loop: every FlushSeconds each player's pending reaches the store; a count that failed to load
	-- is read again. One failed iteration never stops the loop.
	task.spawn(function()
		while true do
			task.wait(sleepSeconds(LeaderboardData.FlushSeconds))
			local ok, err = pcall(function()
				checkRollover()
				flushAll()
				for _, player in ipairs(Players:GetPlayers()) do
					if not knownLoaded[player.UserId] then
						task.spawn(loadKnown, player)
					end
				end
			end)
			if not ok then
				warn(("%s: flush tick failed: %s"):format(tag(), tostring(err)))
			end
		end
	end)
	-- Fetch loop: one list call per server per FetchSeconds, the first right away.
	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				checkRollover()
				fetchTop()
			end)
			if not ok then
				fetching = false
				warn(("%s: fetch tick failed: %s"):format(tag(), tostring(err)))
			end
			task.wait(sleepSeconds(LeaderboardData.FetchSeconds))
		end
	end)
end

return Leaderboard
