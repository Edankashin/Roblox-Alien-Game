--!strict
-- ServerScriptService.Server.Services.CatchRush: the Catch Rush on a fixed server clock.
-- A round starts at every multiple of CatchRushData.IntervalSeconds of os.time() (the wall clock, shared
-- by every server, like the Meteor Shower in Events) and runs for CatchRushData.DurationSeconds, so the
-- state of the round needs no save: it is a pure function of the time. While a round runs every wild
-- catch counts (Catching calls CatchRush.OnCatch beside Leaderboard.OnCatch; eggs and shop aliens do
-- not). When SkipDuringShower is set and a Meteor Shower is running at the moment a round would start,
-- that round is skipped and the slot stays inactive (a server that boots mid-slot decides at boot).
-- Ranking: every player with at least MinCatches, by catches descending, then by who reached that count
-- first (TieBreak "earliest", an os.clock() stamp taken at each catch). Counts live in memory for the
-- one round only and are cleared at its end; a player who leaves mid-round drops out of the table.
-- At the end the ranked players are paid through Gifts.GrantRewards (Rewards by rank up to TopCount,
-- Participation for the rest), each player present hears CatchRushResult, the winner is announced to
-- everyone through the Announcement event (kind "rush"), and Analytics gets a CatchRush event per ranked
-- player plus the Scrap paid as economy source Rush (GrantRewards reports nothing itself, so no double count).
-- Clients hear CatchRushChanged (FireAllClients) at every start and end, every PushSeconds while a round
-- runs or is within WarnSeconds of starting, and on every count change while it runs (at most one push a
-- second), and a late joiner asks GetCatchRush once; that reply also carries the asker's own row when
-- they have catches outside the top. The client only renders.
-- CatchRush.Force and CatchRush.ForceNext (Studio commands, guarded by Dev) override the clock like
-- Events.Force and Events.ForceNext: a forced round runs DurationSeconds from now; a forced end settles
-- the round at once and mutes the clock's own round until it would have ended.
--
-- Requires run one way: this module requires Gifts, Events, Analytics, PlayerData, Net and shared data.
-- Catching requires this module; nothing Gifts requires comes back here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Data = require(Shared.data.CatchRush)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Events = require(script.Parent.Events)
local Gifts = require(script.Parent.Gifts)

local CatchRush = {}

type Clock = { active: boolean, secondsLeft: number, nextInSeconds: number }
type Tally = { catches: number, reachedAt: number } -- reachedAt: os.clock() when the count last went up
type Entry = { player: Player, catches: number, reachedAt: number }

local SNAPSHOT_RATE_PER_SECOND = 2 -- GetCatchRush calls per player per second
local TICK_SECONDS = 1 -- how often the loop looks at the clock; a start or end is seen within this
local COUNT_PUSH_GAP_SECONDS = 1 -- a count change reaches clients at most this often

local counts: { [Player]: Tally } = {} -- this round's catches
local wasActive = false -- the last state the loop acted on
local dirty = false -- a count changed since the last broadcast
local lastPush = 0 -- os.clock() of the last CatchRushChanged broadcast
local forcedEndsAt: number? = nil -- os.time() a forced round ends (CatchRush.Force); beats the clock while in the future
local mutedUntil: number? = nil -- os.time() until which the clock's own round is ignored (a forced end)
local forcedStartAt: number? = nil -- os.time() a forced round starts (CatchRush.ForceNext); it then runs its normal length
local decidedSlot: number? = nil -- os.time() start of the clock slot whose run-or-skip was decided
local slotRuns = false -- that decision: true runs the round, false skips it for a shower

-- Clock maths -------------------------------------------------------------
-- phase = seconds since the most recent start (os.time() modulo the interval). A round is active for the
-- first DurationSeconds of every interval unless its slot was skipped; the next start is interval - phase
-- away. Expired overrides are simply ignored here, so nothing needs clearing.

-- Whether the slot that began at `start` runs. Decided once, the first time the slot is looked at (the
-- loop looks every second, so on a running server that is its start), and then kept for the whole slot.
local function slotIsRun(start: number): boolean
	if decidedSlot ~= start then
		decidedSlot = start
		slotRuns = not (Data.SkipDuringShower and Events.IsShowerActive())
	end
	return slotRuns
end

local function readClock(): Clock
	local now = os.time()
	local forcedStart = forcedStartAt
	if forcedStart then
		if now < forcedStart then
			return { active = false, secondsLeft = 0, nextInSeconds = forcedStart - now }
		elseif now < forcedStart + Data.DurationSeconds then
			return { active = true, secondsLeft = forcedStart + Data.DurationSeconds - now, nextInSeconds = 0 }
		end
		forcedStartAt = nil -- ran its course; the clock takes over again
	end
	local forcedEnd = forcedEndsAt
	if forcedEnd and now < forcedEnd then
		return { active = true, secondsLeft = forcedEnd - now, nextInSeconds = 0 }
	end
	local p = now % Data.IntervalSeconds
	local active = p < Data.DurationSeconds and slotIsRun(now - p)
	local muted = mutedUntil
	if muted and now < muted then
		active = false
	end
	return {
		active = active,
		secondsLeft = if active then Data.DurationSeconds - p else 0,
		nextInSeconds = if active then 0 else Data.IntervalSeconds - p,
	}
end

-- Counts and ranking ------------------------------------------------------

-- Every player with at least MinCatches, best first: catches descending, then the earlier count (TieBreak
-- "earliest"), then user id so the order is the same every time.
local function ranked(): { Entry }
	local list: { Entry } = {}
	for player, tally in pairs(counts) do
		if tally.catches >= Data.MinCatches then
			table.insert(list, { player = player, catches = tally.catches, reachedAt = tally.reachedAt })
		end
	end
	table.sort(list, function(a: Entry, b: Entry): boolean
		if a.catches ~= b.catches then
			return a.catches > b.catches
		end
		if a.reachedAt ~= b.reachedAt then
			return a.reachedAt < b.reachedAt
		end
		return a.player.UserId < b.player.UserId
	end)
	return list
end

local function rowOf(player: Player, catches: number): Types.CatchRushRow
	return { userId = player.UserId, name = player.DisplayName, catches = catches }
end

-- The state a client renders: the clock plus the top TopCount rows and, for a late joiner (`asker`), their
-- own row after them when they have catches and are outside the top.
local function buildState(clock: Clock, asker: Player?): Types.CatchRushState
	local rows: { Types.CatchRushRow } = {}
	local askerInTop = false
	for index, entry in ipairs(ranked()) do
		if index > Data.TopCount then
			break
		end
		table.insert(rows, rowOf(entry.player, entry.catches))
		if entry.player == asker then
			askerInTop = true
		end
	end
	if asker and not askerInTop then
		local tally = counts[asker]
		if tally and tally.catches > 0 then
			table.insert(rows, rowOf(asker, tally.catches))
		end
	end
	return { active = clock.active, secondsLeft = clock.secondsLeft, nextInSeconds = clock.nextInSeconds, rows = rows }
end

local function broadcast(clock: Clock)
	Net.event("CatchRushChanged"):FireAllClients(buildState(clock, nil))
	lastPush = os.clock()
	dirty = false
end

-- The end of a round ------------------------------------------------------

-- Pay and tell one player present. `rank` is 0 for anyone not ranked (nothing paid).
local function settlePlayer(player: Player, catches: number, rank: number)
	local rewards: { any } = {}
	if rank >= 1 then
		local row = if rank <= Data.TopCount then Data.Rewards[rank] else nil
		local granted = row or Data.Participation
		if Gifts.GrantRewards(player, granted) then
			rewards = granted
			local scrap = 0
			for _, reward in ipairs(granted) do
				if reward.kind == "scrap" then
					scrap += reward.amount
				end
			end
			local live = PlayerData.Get(player)
			if scrap > 0 and live then
				Analytics.Economy(player, "Source", scrap, live.scrap, "Gameplay", AnalyticsData.Economy.Sources.Rush)
			end
		end
		Analytics.Event(player, AnalyticsData.Events.CatchRush, catches, { rank = tostring(rank) })
	end
	local result: Types.CatchRushResult = { rank = rank, catches = catches, rewards = rewards }
	Net.event("CatchRushResult"):FireClient(player, result)
end

-- The round is over: rank, pay, tell everyone, clear. The table is taken and cleared first so nothing
-- below can see a half-settled round, and each player is settled in a thread of their own so one failing
-- grant cannot stall the clock or the other players.
local function settle()
	local order = ranked()
	local rankOf: { [Player]: number } = {}
	for index, entry in ipairs(order) do
		rankOf[entry.player] = index
	end
	local tallies = counts
	counts = {}
	local winner = order[1]
	if winner then
		local note: Types.Announcement = {
			kind = "rush",
			playerName = winner.player.DisplayName,
			species = "",
			tier = "Common",
			overlay = "None",
			catches = winner.catches,
		}
		Net.event("Announcement"):FireAllClients(note)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local tally = tallies[player]
		task.spawn(settlePlayer, player, if tally then tally.catches else 0, rankOf[player] or 0)
	end
end

-- The loop ----------------------------------------------------------------

local function tick()
	local clock = readClock()
	if clock.active ~= wasActive then
		wasActive = clock.active
		if clock.active then
			counts = {} -- a fresh round
		else
			settle()
		end
		broadcast(clock)
		return
	end
	local gap = os.clock() - lastPush
	local watching = clock.active or clock.nextInSeconds <= Data.WarnSeconds
	if (watching and gap >= Data.PushSeconds) or (clock.active and dirty and gap >= COUNT_PUSH_GAP_SECONDS) then
		broadcast(clock)
	end
end

-- Remotes ----------------------------------------------------------------

-- GetCatchRush() -> CatchRushState. The round for a late joiner, with their own row when they are outside
-- the top; nil only when rate limited.
local function onGetCatchRush(player: Player): Types.CatchRushState?
	if not Net.allow(player, "GetCatchRush", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	return buildState(readClock(), player)
end

-- Public API -------------------------------------------------------------

-- One wild catch by `player`. Counts only while a round is active; the clock is looked at first so a
-- catch in the first or last moments of a round lands on the right side of it.
function CatchRush.OnCatch(player: Player)
	tick()
	if not wasActive then
		return
	end
	local tally = counts[player]
	if tally then
		tally.catches += 1
		tally.reachedAt = os.clock()
	else
		counts[player] = { catches = 1, reachedAt = os.clock() }
	end
	dirty = true
	if os.clock() - lastPush >= COUNT_PUSH_GAP_SECONDS then
		broadcast(readClock())
	end
end

-- The round right now, computed from os.time(): active, secondsLeft (0 when not active), nextInSeconds
-- to the next start (0 while active) and the top rows so far.
function CatchRush.GetState(): Types.CatchRushState
	return buildState(readClock(), nil)
end

function CatchRush.IsActive(): boolean
	return readClock().active
end

-- Developer override (Studio commands): true starts a round now that ends DurationSeconds later (a
-- running one is extended to that); false ends the current round now, whether forced or from the clock
-- (it is settled and paid at once), and mutes the clock's own round until the moment it would have ended.
function CatchRush.Force(active: boolean)
	local now = os.time()
	forcedStartAt = nil
	if active then
		forcedEndsAt = now + Data.DurationSeconds
		mutedUntil = nil
	else
		forcedEndsAt = nil
		local p = now % Data.IntervalSeconds
		if p < Data.DurationSeconds then
			mutedUntil = now + (Data.DurationSeconds - p)
		end
	end
	tick()
end

-- Developer override: the next round starts `seconds` from now (so the countdown chip and its pushes can
-- be seen without waiting for the next mark) and then runs its normal length.
function CatchRush.ForceNext(seconds: number)
	forcedEndsAt = nil
	forcedStartAt = os.time() + math.max(1, math.floor(seconds))
	tick()
end

function CatchRush.Init()
	Net.event("CatchRushChanged")
	Net.event("CatchRushResult")
	Net.func("GetCatchRush").OnServerInvoke = onGetCatchRush
	Players.PlayerRemoving:Connect(function(player: Player)
		if counts[player] then
			counts[player] = nil
			dirty = true
		end
	end)
end

function CatchRush.Start()
	-- A server that boots mid-round joins it at once (with empty counts); otherwise the loop sees the next start.
	local clock = readClock()
	wasActive = clock.active
	lastPush = os.clock()

	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			tick()
		end
	end)

	if clock.active then
		print(("[%s] CatchRush: round active now, %ds left; every %ss for %ss"):format(
			Config.WorkingTitle,
			clock.secondsLeft,
			tostring(Data.IntervalSeconds),
			tostring(Data.DurationSeconds)
		))
	else
		print(("[%s] CatchRush: every %ss for %ss, next start in %ds"):format(
			Config.WorkingTitle,
			tostring(Data.IntervalSeconds),
			tostring(Data.DurationSeconds),
			clock.nextInSeconds
		))
	end
end

return CatchRush
