--!strict
-- ServerScriptService.Server.Services.DailyQuests: the daily and weekly quests (Shared/data/DailyQuests).
-- Three are dealt per period from each pool, deterministically per player and period: the seed mixes the
-- period id's characters, the UserId and SeedSalt, so a rejoin or another server shows the same set. The
-- daily period is the UTC date of its start (rolling at DailyResetHourUtc); the weekly period is the
-- leaderboard's (Shared/LeaderboardMath). Other services report what the player did (Quests forwards
-- OnCatch, OnCollect and OnCraft here), this service counts it into profile.quests.daily and .weekly,
-- pays on claim through Gifts.GrantRewards, rerolls one daily quest a day, and pushes DailyQuestsChanged.
-- The client renders the screen; every count, deal and grant is decided here.
-- Requires run one way: Quests requires this module to forward, so this module never requires Gifts
-- (Gifts -> Economy -> Quests -> here). Codes hands over Gifts.GrantRewards through SetRewardGranter at Init.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local DailyQuestsData = require(Shared.data.DailyQuests)
local AnalyticsData = require(Shared.data.Analytics)
local Worlds = require(Shared.data.Worlds)
local Place = require(Shared.Place)
local Net = require(Shared.Net)
local LeaderboardMath = require(Shared.LeaderboardMath)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)

local DailyQuests = {}

export type Snapshot = {
	daily: Types.PeriodQuests,
	weekly: Types.PeriodQuests,
	dailyResetsAt: number,
	weeklyResetsAt: number,
}

type Period = "daily" | "weekly"
type Matcher = (DailyQuestsData.Objective) -> boolean

local REMOTE_RATE_PER_SECOND = 4 -- ClaimDailyQuest, RerollDailyQuest and GetDailyQuests calls per player per second
local SECONDS_PER_DAY = 24 * 3600
local SECONDS_PER_HOUR = 3600
local SEED_MIX = 31 -- the seed is a polynomial hash of the period id, kept under SEED_MODULUS
local SEED_MODULUS = 2147483647
local SPECIAL_WEATHER: string = Worlds[Place.WorldId()].weather.special.id -- the catchSpecial condition

-- Quest rows by id, per pool.
local dailyById: { [string]: DailyQuestsData.Quest } = {}
local weeklyById: { [string]: DailyQuestsData.Quest } = {}
for _, quest in ipairs(DailyQuestsData.Daily) do
	dailyById[quest.id] = quest
end
for _, quest in ipairs(DailyQuestsData.Weekly) do
	weeklyById[quest.id] = quest
end

-- Friendship answers for this session, friendCache[askerUserId][otherUserId]. Filled on a catch, cleared
-- when either player leaves.
local friendCache: { [number]: { [number]: boolean } } = {}
-- Gifts.GrantRewards, registered by Codes at Init (see the header).
local rewardGranter: ((Player, { any }) -> boolean)? = nil

-- Periods and dealing ----------------------------------------------------

-- The id of the daily period `now` falls in: the UTC date of its start.
local function dailyPeriodId(now: number): string
	return os.date("!%Y-%m-%d", now - DailyQuestsData.DailyResetHourUtc * SECONDS_PER_HOUR)
end

-- The next DailyResetHourUtc, UTC, after `now`.
local function dailyNextReset(now: number): number
	local shifted = now - DailyQuestsData.DailyResetHourUtc * SECONDS_PER_HOUR
	local dayStart = shifted - shifted % SECONDS_PER_DAY
	return dayStart + SECONDS_PER_DAY + DailyQuestsData.DailyResetHourUtc * SECONDS_PER_HOUR
end

local function stateOf(profile: Types.Profile, period: Period): Types.PeriodQuests
	if period == "daily" then
		return profile.quests.daily
	end
	return profile.quests.weekly
end

local function indexOf(period: Period): { [string]: DailyQuestsData.Quest }
	return if period == "daily" then dailyById else weeklyById
end

-- The deterministic seed of one player's deal for one period.
local function seedFor(periodId: string, userId: number): number
	local seed = DailyQuestsData.SeedSalt
	for i = 1, #periodId do
		seed = (seed * SEED_MIX + string.byte(periodId, i)) % SEED_MODULUS
	end
	return (seed * SEED_MIX + userId) % SEED_MODULUS
end

-- `count` distinct ids from the pool, drawn with `rng` (a partial shuffle, so none repeats).
local function dealIds(pool: { DailyQuestsData.Quest }, count: number, rng: Random): { string }
	local bag: { string } = {}
	for _, quest in ipairs(pool) do
		table.insert(bag, quest.id)
	end
	local out: { string } = {}
	for _ = 1, math.min(count, #bag) do
		table.insert(out, table.remove(bag, rng:NextInteger(1, #bag)) :: string)
	end
	return out
end

local function dealPeriod(state: Types.PeriodQuests, periodId: string, pool: { DailyQuestsData.Quest }, count: number, userId: number)
	state.period = periodId
	state.ids = dealIds(pool, count, Random.new(seedFor(periodId, userId)))
	state.progress = {}
	state.claimed = {}
	state.rerolls = 0
end

-- Deals a fresh set into every period that has rolled over since the profile's last one. Runs inside
-- PlayerData.Update; true when anything was dealt.
local function ensureDealt(userId: number, profile: Types.Profile, now: number): boolean
	local changed = false
	local dailyId = dailyPeriodId(now)
	if profile.quests.daily.period ~= dailyId then
		dealPeriod(profile.quests.daily, dailyId, DailyQuestsData.Daily, DailyQuestsData.DailyCount, userId)
		changed = true
	end
	local weeklyId = LeaderboardMath.PeriodId(now)
	if profile.quests.weekly.period ~= weeklyId then
		dealPeriod(profile.quests.weekly, weeklyId, DailyQuestsData.Weekly, DailyQuestsData.WeeklyCount, userId)
		changed = true
	end
	return changed
end

local function snapshotOf(profile: Types.Profile, now: number): Snapshot
	return {
		daily = profile.quests.daily,
		weekly = profile.quests.weekly,
		dailyResetsAt = dailyNextReset(now),
		weeklyResetsAt = LeaderboardMath.NextReset(now),
	}
end

local function push(player: Player)
	local profile = PlayerData.Get(player)
	if profile then
		Net.event("DailyQuestsChanged"):FireClient(player, snapshotOf(profile, os.time()))
	end
end

-- Progress ----------------------------------------------------------------

-- Counts one toward every dealt, unclaimed quest of the period whose objective `matches`, never past
-- its count. True when anything moved.
local function bump(state: Types.PeriodQuests, byId: { [string]: DailyQuestsData.Quest }, matches: Matcher): boolean
	local changed = false
	for _, id in ipairs(state.ids) do
		local quest = byId[id]
		if quest and not state.claimed[id] and matches(quest.objective) then
			local have = state.progress[id] or 0
			if have < quest.objective.count then
				state.progress[id] = have + 1
				changed = true
			end
		end
	end
	return changed
end

-- Deals what is due, then counts `matches` into both periods; pushes when anything changed.
local function advance(player: Player, matches: Matcher)
	local changed = false
	local now = os.time()
	local ok = PlayerData.Update(player, function(profile)
		if ensureDealt(player.UserId, profile, now) then
			changed = true
		end
		if bump(profile.quests.daily, dailyById, matches) then
			changed = true
		end
		if bump(profile.quests.weekly, weeklyById, matches) then
			changed = true
		end
	end)
	if ok and changed then
		push(player)
	end
end

local function hasCondition(conditions: { Types.Condition }, wanted: string?): boolean
	if wanted == nil then
		return false
	end
	for _, active in ipairs(conditions) do
		if active == wanted then
			return true
		end
	end
	return false
end

-- Whether any Roblox friend of `player` is in this server. IsFriendsWithAsync yields and can fail, so each
-- pair is asked once per session (a failure is not cached and counts as no friend).
local function friendInServer(player: Player): boolean
	local mine = friendCache[player.UserId]
	if not mine then
		mine = {}
		friendCache[player.UserId] = mine
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local known: boolean? = mine[other.UserId]
			if known == nil then
				local theirs = friendCache[other.UserId]
				known = if theirs then theirs[player.UserId] else nil
			end
			if known == nil then
				local ok, result = pcall(function()
					return player:IsFriendsWithAsync(other.UserId)
				end)
				if ok then
					known = result
					mine[other.UserId] = result
				end
			end
			if known == true then
				return true
			end
		end
	end
	return false
end

-- Economy.GrantAlien reports every alien that enters a profile (through Quests.OnCatch): its tier, the
-- conditions active at the time and whether the catch was perfect. Counts catchCount, catchCondition,
-- catchTier, catchSpecial, catchWithFriend and perfectCount. Runs in its own thread: the friend check
-- can yield, and the catch must not wait for it.
function DailyQuests.OnCatch(player: Player, tier: Types.Tier, conditions: { Types.Condition }, perfect: boolean)
	task.spawn(function()
		local friend = friendInServer(player)
		advance(player, function(objective: DailyQuestsData.Objective): boolean
			local kind = objective.kind
			if kind == "catchCount" then
				return true
			elseif kind == "catchCondition" then
				return hasCondition(conditions, objective.condition)
			elseif kind == "catchTier" then
				return objective.tier == tier
			elseif kind == "catchSpecial" then
				return hasCondition(conditions, SPECIAL_WEATHER)
			elseif kind == "catchWithFriend" then
				return friend
			elseif kind == "perfectCount" then
				return perfect
			end
			return false
		end)
	end)
end

-- Materials reports a collected node (through Quests.OnCollect). Counts collectAny.
function DailyQuests.OnCollect(player: Player)
	advance(player, function(objective: DailyQuestsData.Objective): boolean
		return objective.kind == "collectAny"
	end)
end

-- Shop reports a crafted (bought) lure (through Quests.OnCraft). Counts craft objectives for that lure.
function DailyQuests.OnCraft(player: Player, lureId: string)
	advance(player, function(objective: DailyQuestsData.Objective): boolean
		return objective.kind == "craft" and objective.lure == lureId
	end)
end

-- Remotes -----------------------------------------------------------------

-- ClaimDailyQuest(period, id) -> (ok, reason). Pays a finished quest once. Reasons: RateLimited,
-- NoProfile, NotDealt (a bad period or id, or one not in the player's set), NotDone, AlreadyClaimed.
-- A claimed daily quest counts toward the weekly dailyClaims objectives.
local function onClaim(player: Player, period: any, id: any): (boolean, string?)
	if not Net.allow(player, "ClaimDailyQuest", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	if (period ~= "daily" and period ~= "weekly") or type(id) ~= "string" then
		return false, "NotDealt"
	end
	local which: Period = period
	local questId: string = id
	local reason: string? = nil
	local rewards: { DailyQuestsData.Reward }? = nil
	local dealt = false
	local ok = PlayerData.Update(player, function(profile)
		dealt = ensureDealt(player.UserId, profile, os.time())
		local state = stateOf(profile, which)
		local quest = indexOf(which)[questId]
		if not quest or not table.find(state.ids, questId) then
			reason = "NotDealt"
		elseif state.claimed[questId] then
			reason = "AlreadyClaimed"
		elseif (state.progress[questId] or 0) < quest.objective.count then
			reason = "NotDone"
		else
			state.claimed[questId] = true
			if which == "daily" then
				bump(profile.quests.weekly, weeklyById, function(objective: DailyQuestsData.Objective): boolean
					return objective.kind == "dailyClaims"
				end)
			end
			rewards = quest.rewards
		end
	end)
	if not ok then
		return false, "NoProfile"
	end
	if rewards == nil then
		if dealt then
			push(player)
		end
		return false, reason
	end
	local grant = rewardGranter
	if grant then
		grant(player, rewards)
	else
		warn(("[%s] DailyQuests: no reward granter registered (Codes.Init), %s not paid"):format(Config.WorkingTitle, questId))
	end
	Analytics.Event(player, AnalyticsData.Events.DailyQuest, 1, { period = which :: string, id = questId, action = "claim" })
	push(player)
	return true, nil
end

-- RerollDailyQuest(id) -> (ok, reason). Swaps one unclaimed daily quest for a pool quest not in today's
-- set, clearing its progress; RerollsPerDay a day. Reasons: RateLimited, NoProfile, NotDealt,
-- AlreadyClaimed, NoRerolls (none left, or no other quest left to deal).
local function onReroll(player: Player, id: any): (boolean, string?)
	if not Net.allow(player, "RerollDailyQuest", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	if type(id) ~= "string" then
		return false, "NotDealt"
	end
	local questId: string = id
	local now = os.time()
	local reason: string? = nil
	local dealt = false
	local rerolled = false
	local ok = PlayerData.Update(player, function(profile)
		dealt = ensureDealt(player.UserId, profile, now)
		local state = profile.quests.daily
		local at = table.find(state.ids, questId)
		if not at then
			reason = "NotDealt"
		elseif state.claimed[questId] then
			reason = "AlreadyClaimed"
		elseif state.rerolls >= DailyQuestsData.RerollsPerDay then
			reason = "NoRerolls"
		else
			local candidates: { string } = {}
			for _, quest in ipairs(DailyQuestsData.Daily) do
				if not table.find(state.ids, quest.id) then
					table.insert(candidates, quest.id)
				end
			end
			if #candidates == 0 then
				reason = "NoRerolls"
			else
				local pick = candidates[Random.new(now):NextInteger(1, #candidates)]
				state.ids[at] = pick
				state.progress[questId] = nil
				state.progress[pick] = nil
				state.claimed[pick] = nil
				state.rerolls += 1
				rerolled = true
			end
		end
	end)
	if not ok then
		return false, "NoProfile"
	end
	if dealt or rerolled then
		push(player)
	end
	if not rerolled then
		return false, reason
	end
	Analytics.Event(player, AnalyticsData.Events.DailyQuest, 1, { period = "daily", id = questId, action = "reroll" })
	return true, nil
end

-- GetDailyQuests() -> Snapshot?. The current sets with their reset instants; nil when rate limited or
-- before the profile loads.
local function onGet(player: Player): Snapshot?
	if not Net.allow(player, "GetDailyQuests", REMOTE_RATE_PER_SECOND) then
		return nil
	end
	local now = os.time()
	local dealt = false
	local ok = PlayerData.Update(player, function(profile)
		dealt = ensureDealt(player.UserId, profile, now)
	end)
	local profile = PlayerData.Get(player)
	if not ok or not profile then
		return nil
	end
	if dealt then
		push(player)
	end
	return snapshotOf(profile, now)
end

-- Public API -------------------------------------------------------------

-- Codes registers Gifts.GrantRewards here at Init (the require runs Gifts -> Economy -> Quests -> here).
function DailyQuests.SetRewardGranter(callback: (Player, { any }) -> boolean)
	rewardGranter = callback
end

-- Studio only (Dev /dq reset): forgets the dealt sets and deals them again, with empty progress, at once.
function DailyQuests.DevReset(player: Player)
	PlayerData.Update(player, function(profile)
		profile.quests.daily.period = ""
		profile.quests.weekly.period = ""
		ensureDealt(player.UserId, profile, os.time())
	end)
	push(player)
end

local function completeAll(state: Types.PeriodQuests, byId: { [string]: DailyQuestsData.Quest })
	for _, id in ipairs(state.ids) do
		local quest = byId[id]
		if quest and not state.claimed[id] then
			state.progress[id] = quest.objective.count
		end
	end
end

-- Studio only (Dev /dq done): every dealt, unclaimed quest of both periods is at its count.
function DailyQuests.DevComplete(player: Player)
	PlayerData.Update(player, function(profile)
		ensureDealt(player.UserId, profile, os.time())
		completeAll(profile.quests.daily, dailyById)
		completeAll(profile.quests.weekly, weeklyById)
	end)
	push(player)
end

function DailyQuests.Init()
	Net.event("DailyQuestsChanged")
	Net.func("ClaimDailyQuest").OnServerInvoke = onClaim
	Net.func("RerollDailyQuest").OnServerInvoke = onReroll
	Net.func("GetDailyQuests").OnServerInvoke = onGet

	-- Deal on load, before the client asks; the push covers a client that pulled its profile early.
	PlayerData.OnLoaded(function(player: Player, _profile: Types.Profile)
		PlayerData.Update(player, function(profile)
			ensureDealt(player.UserId, profile, os.time())
		end)
		push(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		friendCache[player.UserId] = nil
		for _, theirs in pairs(friendCache) do
			theirs[player.UserId] = nil
		end
	end)
end

function DailyQuests.Start() end

return DailyQuests
