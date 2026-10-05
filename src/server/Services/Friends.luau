--!strict
-- ServerScriptService.Server.Services.Friends: the one friendship cache for this server, and the Friend
-- Boost built on it (+Config.FriendBoostPerFriend per Roblox friend present, up to
-- Config.FriendBoostMaxFriends). Buffs adds the boost to luck and multiplies station income and catch
-- Scrap by it; DailyQuests asks AnyInServer for its "with a friend" objectives.
-- IsFriendsWithAsync yields and can fail, so every lookup runs in its own task.spawn thread when a
-- player's profile loads, never inside a query. The queries below read only the cache and the stored
-- counts, so Buffs can call them from income ticks and catches without yielding. A failed lookup warns
-- once and is asked again after Config.FriendCheckRetrySeconds; until then the pair counts as no friend.
-- Requires only PlayerData, Analytics and shared modules, so Buffs and DailyQuests can require this.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)

local Friends = {}

type PairTable = { [number]: { [number]: boolean? } }

local friendPairs: PairTable = {} -- friendPairs[a][b]: the answer for the pair, symmetric; absent until known
local busy: PairTable = {} -- the pair has a lookup in flight or a retry waiting, symmetric
local present: { [number]: Player } = {} -- by UserId, while in this server
local arrival: { [number]: number } = {} -- join order by UserId, so the later of a pair is the arrival
local loaded: { [number]: boolean } = {} -- profile loaded, so FriendBoostChanged can be pushed
local counts: { [number]: number } = {} -- friends present, by UserId
local listeners: { (Player, number, string?) -> () } = {}
local arrivals = 0

-- Pair helpers -------------------------------------------------------------

local function getPair(t: PairTable, a: number, b: number): boolean?
	local row = t[a]
	if row then
		return row[b]
	end
	return nil
end

local function setPair(t: PairTable, a: number, b: number, value: boolean?)
	local rowA = t[a]
	if not rowA then
		rowA = {}
		t[a] = rowA
	end
	local rowB = t[b]
	if not rowB then
		rowB = {}
		t[b] = rowB
	end
	rowA[b] = value
	rowB[a] = value
end

-- Queries (no yield) --------------------------------------------------------

local function boostFor(count: number): number
	return math.min(count, Config.FriendBoostMaxFriends) * Config.FriendBoostPerFriend
end

-- Roblox friends of `player` in this server, from the cache.
function Friends.CountInServer(player: Player): number
	return counts[player.UserId] or 0
end

function Friends.AnyInServer(player: Player): boolean
	return Friends.CountInServer(player) > 0
end

-- The fraction added to luck and multiplied into station income and catch Scrap.
function Friends.Boost(player: Player): number
	return boostFor(Friends.CountInServer(player))
end

function Friends.OnChanged(callback: (Player, number, string?) -> ())
	table.insert(listeners, callback)
end

-- Counting ------------------------------------------------------------------

-- Re-derives one player's count from the cache; on a change pushes, reports and tells the listeners.
-- arrivedName is the display name of a friend who just arrived (nil on a leave and for the arrival itself).
local function recount(player: Player, arrivedName: string?)
	local uid = player.UserId
	local n = 0
	local row = friendPairs[uid]
	if row then
		for _, isFriend in pairs(row) do
			if isFriend then
				n += 1
			end
		end
	end
	if n == (counts[uid] or 0) then
		return
	end
	counts[uid] = n
	if loaded[uid] then
		Net.event("FriendBoostChanged"):FireClient(player, n, boostFor(n), arrivedName)
	end
	Analytics.Event(player, AnalyticsData.Events.FriendsInServer, n)
	for _, callback in ipairs(listeners) do
		callback(player, n, arrivedName)
	end
end

-- Asks Roblox about one pair (yields) and files the answer. Skips a pair that is known or already busy.
local function check(a: Player, b: Player)
	local ida, idb = a.UserId, b.UserId
	if ida == idb or getPair(friendPairs, ida, idb) ~= nil or getPair(busy, ida, idb) == true then
		return
	end
	setPair(busy, ida, idb, true)
	local ok, result = pcall(function(): any
		return a:IsFriendsWithAsync(idb)
	end)
	if present[ida] ~= a or present[idb] ~= b then
		return -- one left meanwhile; their removal already cleared the pair
	end
	if not ok then
		warn(("[%s] Friends: lookup %s/%s failed (%s); retrying in %d s"):format(Config.WorkingTitle, a.Name, b.Name, tostring(result), Config.FriendCheckRetrySeconds))
		task.delay(Config.FriendCheckRetrySeconds, function()
			if present[ida] == a and present[idb] == b then
				setPair(busy, ida, idb, nil)
				check(a, b)
			end
		end)
		return -- stays busy until the retry
	end
	setPair(busy, ida, idb, nil)
	local isFriend = result == true
	setPair(friendPairs, ida, idb, isFriend)
	if isFriend then
		local newer = if (arrival[ida] or 0) > (arrival[idb] or 0) then a else b
		recount(a, if a == newer then nil else newer.DisplayName)
		recount(b, if b == newer then nil else newer.DisplayName)
	end
end

local function onAdded(player: Player)
	arrivals += 1
	arrival[player.UserId] = arrivals
	present[player.UserId] = player
	counts[player.UserId] = 0
end

local function onLoaded(player: Player, _profile: Types.Profile)
	local uid = player.UserId
	if present[uid] ~= player then
		return
	end
	loaded[uid] = true
	local count = counts[uid] or 0
	if count > 0 then
		Net.event("FriendBoostChanged"):FireClient(player, count, boostFor(count), nil)
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and present[other.UserId] == other then
			task.spawn(check, player, other)
		end
	end
end

local function onRemoving(player: Player)
	local uid = player.UserId
	present[uid] = nil
	loaded[uid] = nil
	counts[uid] = nil
	arrival[uid] = nil
	local row = friendPairs[uid]
	local busyRow = busy[uid]
	friendPairs[uid] = nil
	busy[uid] = nil
	if busyRow then
		for other in pairs(busyRow) do
			local theirs = busy[other]
			if theirs then
				theirs[uid] = nil
			end
		end
	end
	if row then
		for other in pairs(row) do
			local theirs = friendPairs[other]
			if theirs then
				theirs[uid] = nil
			end
		end
		for other, isFriend in pairs(row) do
			local p = present[other]
			if isFriend and p then
				recount(p, nil)
			end
		end
	end
end

-- Public API ----------------------------------------------------------------

function Friends.Init()
	Net.event("FriendBoostChanged")
	for _, player in ipairs(Players:GetPlayers()) do
		onAdded(player)
	end
	Players.PlayerAdded:Connect(onAdded)
	Players.PlayerRemoving:Connect(onRemoving)
	PlayerData.OnLoaded(onLoaded)
end

function Friends.Start() end

return Friends
