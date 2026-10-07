--!strict
-- ServerScriptService.Server.Services.Playtime: playtime gifts (milestone 49; every number is in Shared/data/Playtime).
-- Six gifts unlock by the minutes a player has actively played today. A loop every Playtime.TickSeconds adds that much to
-- profile.playtime.seconds for each loaded player who is not resting (Afk.IsResting: a player standing idle for
-- Afk.IdleAfterSeconds earns the half-rate crew income but no gift time), so the count is the server's alone and leaving
-- the game loses nothing: the seconds and the claims are saved with the profile and a rejoin the same day picks them up.
-- A new day (Shared/PlaytimeMath.DayOf at Playtime.ResetHourUtc) starts the count and the claims again, forward only (a
-- server whose clock reads an earlier day never wipes a later one). Playtime.Enabled false stops the clock and the claims
-- (ClaimPlaytimeGift answers Disabled) and tells the client to hide the button.
--
-- The client is told with PlaytimeChanged(Types.PlaytimeState) when the ready count changes (a gift unlocks or is
-- claimed), on a new day, and when resting starts or ends (so its local countdown starts again from the server's count),
-- and pulls with GetPlaytime when it joins and each time the screen opens. It derives the cards, the countdowns and the
-- HUD badge from the data table and Shared/PlaytimeMath; nothing else travels.
--
-- ClaimPlaytimeGift(index) -> (ok, reason, grant). Non-egg rewards are paid through Gifts.GrantRewards (the one reward
-- path daily quests, codes and mail use); the egg is hatched with Gifts.GrantEgg (the Welcome Week egg's path) and comes
-- back as the GrantResult the client turns into a Reveal. The claim is marked only after the grant went through, so a bad
-- data row refuses (Unknown) and the gift stays claimable. Reasons: BadArgs, RateLimited, Disabled, NoProfile, Locked,
-- AlreadyClaimed, Unknown. Nothing here costs Scrap or Robux.
--
-- Boot (Service-Boot.md): nothing yields in Init or Start; the loop runs in its own thread.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local PlaytimeData = require(Shared.data.Playtime)
local AnalyticsData = require(Shared.data.Analytics)
local PlaytimeMath = require(Shared.PlaytimeMath)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Afk = require(script.Parent.Afk)
local Gifts = require(script.Parent.Gifts)
local Analytics = require(script.Parent.Analytics)

local Playtime = {}

local CLAIM_RATE_PER_SECOND = 4 -- ClaimPlaytimeGift calls per player per second
local GET_RATE_PER_SECOND = 2 -- GetPlaytime calls per player per second
local GIFTS = PlaytimeData.Gifts

local lastReady: { [number]: number } = {} -- the ready count each player's client last heard, by UserId
local lastResting: { [number]: boolean } = {} -- whether they were resting at the last tick, by UserId
local claiming: { [number]: boolean } = {} -- a claim being paid right now, by UserId

-- Day ------------------------------------------------------------------------

local function today(): number
	return PlaytimeMath.DayOf(os.time(), PlaytimeData.ResetHourUtc)
end

-- A later day starts the count and the claims again (inside PlayerData.Update). Forward only. True when it rolled.
local function rollDay(profile: Types.Profile, day: number): boolean
	local progress = profile.playtime
	if day <= progress.day then
		return false
	end
	progress.day = day
	progress.seconds = 0
	progress.claimed = {}
	return true
end

-- Rolls the player's profile to `day`, written through PlayerData.Update. True when it rolled.
local function roll(player: Player, day: number): boolean
	local rolled = false
	PlayerData.Update(player, function(p)
		rolled = rollDay(p, day)
	end)
	return rolled
end

-- Pushes -------------------------------------------------------------------

local function stateOf(progress: Types.PlaytimeProgress): Types.PlaytimeState
	return { enabled = PlaytimeData.Enabled, seconds = progress.seconds, claimed = progress.claimed }
end

-- Sends the client the state and remembers what it heard.
local function push(player: Player, progress: Types.PlaytimeProgress)
	lastReady[player.UserId] = PlaytimeMath.ReadyCount(progress.seconds, progress.claimed)
	Net.event("PlaytimeChanged"):FireClient(player, stateOf(progress))
end

-- Tick ---------------------------------------------------------------------

-- One pass over every loaded player: the day rolls over, active play adds a tick, and the client hears about a changed
-- ready count, a new day or a change in resting.
local function tick()
	if not PlaytimeData.Enabled then
		return
	end
	local day = today()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(player)
		if profile then
			local rolled = roll(player, day)
			local resting = Afk.IsResting(player)
			if not resting then
				PlayerData.Update(player, function(p)
					p.playtime.seconds += PlaytimeData.TickSeconds
				end)
			end
			local progress = profile.playtime
			local userId = player.UserId
			local ready = PlaytimeMath.ReadyCount(progress.seconds, progress.claimed)
			if rolled or ready ~= lastReady[userId] or resting ~= (lastResting[userId] == true) then
				lastResting[userId] = resting
				push(player, progress)
			end
		end
	end
end

-- Join ---------------------------------------------------------------------

-- Runs on the live profile before the join payload is sent: a new day has started the count again by the time the
-- client first asks. No push: the client pulls (GetPlaytime) when it starts.
local function onLoaded(player: Player, profile: Types.Profile)
	rollDay(profile, today())
	lastReady[player.UserId] = PlaytimeMath.ReadyCount(profile.playtime.seconds, profile.playtime.claimed)
	lastResting[player.UserId] = false
end

-- Remotes ------------------------------------------------------------------

-- GetPlaytime() -> PlaytimeState?: the player's state today (after rolling the day), nil when rate limited or with no
-- profile. Not a push, so a call is the client's own pull, and like every handler it counts as use of the game (Afk).
local function onGetPlaytime(player: Player): Types.PlaytimeState?
	if not Net.allow(player, "GetPlaytime", GET_RATE_PER_SECOND) then
		return nil
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return nil
	end
	roll(player, today())
	return stateOf(profile.playtime)
end

-- Pays one gift's reward: an egg is hatched (the GrantResult comes back for the Reveal), anything else goes through the
-- gifts' reward path after the data row is checked. Returns whether it was paid and the egg's GrantResult.
local function pay(player: Player, reward: PlaytimeData.Reward): (boolean, Types.GrantResult?)
	if reward.kind == "egg" then
		local grant = Gifts.GrantEgg(player, reward.tier)
		return grant ~= nil, grant
	end
	return Gifts.IsGrantable(reward) and Gifts.GrantRewards(player, { reward }), nil
end

-- ClaimPlaytimeGift(index) -> (ok, reason, grant). index is 1..#Gifts; grant is the GrantResult of an egg so the client
-- can show the Reveal, nil for every other kind. The claim is written only after the reward was paid.
local function onClaimPlaytimeGift(player: Player, index: any): (boolean, string?, Types.GrantResult?)
	if type(index) ~= "number" or index ~= index or index % 1 ~= 0 or index < 1 or index > #GIFTS then
		return false, "BadArgs"
	end
	if not Net.allow(player, "ClaimPlaytimeGift", CLAIM_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if not PlaytimeData.Enabled then
		return false, "Disabled"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local userId = player.UserId
	if claiming[userId] then
		return false, "AlreadyClaimed" -- another claim is still being paid; the answer to it carries the result
	end
	if roll(player, today()) then
		push(player, profile.playtime) -- a new day began since the client last heard: it hears the empty one with the refusal
	end
	local progress = profile.playtime
	if not PlaytimeMath.IsUnlocked(progress.seconds, index) then
		return false, "Locked"
	end
	local key = PlaytimeMath.Key(index)
	if progress.claimed[key] then
		return false, "AlreadyClaimed"
	end

	-- Pay first; the claim is marked only when the reward went through. `claiming` holds a second call out in case any
	-- step of the grant yields, and the pcall releases it if one throws.
	local reward = GIFTS[index].reward
	claiming[userId] = true
	local called, paid, result = pcall(pay, player, reward)
	claiming[userId] = nil
	if not called then
		warn(("[%s] Playtime: paying gift %d failed: %s"):format(Config.WorkingTitle, index, tostring(paid)))
	end
	if called ~= true or paid ~= true then
		return false, "Unknown" -- a reward whose id or tier resolves to nothing in the data tables (or the profile went away)
	end
	local grant = result :: Types.GrantResult?

	PlayerData.Update(player, function(p)
		p.playtime.claimed[key] = true
	end)
	push(player, profile.playtime)
	Analytics.Event(player, AnalyticsData.Events.PlaytimeGift, index)
	if reward.kind == "scrap" then
		Analytics.Economy(player, "Source", reward.amount, profile.scrap, "TimedReward", AnalyticsData.Economy.Sources.Playtime)
	end
	return true, nil, grant
end

-- Public API -----------------------------------------------------------------

-- Developer overrides (Studio commands, guarded by Dev): add played time today (negative takes it back, to nothing at
-- the least) so any gift can be reached in seconds, or clear today's time and claims. Both push at once.
function Playtime.DevAddMinutes(player: Player, minutes: number)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	roll(player, today())
	PlayerData.Update(player, function(p)
		p.playtime.seconds = math.max(0, p.playtime.seconds + PlaytimeMath.MinutesToSeconds(math.floor(minutes)))
	end)
	push(player, profile.playtime)
end

function Playtime.DevReset(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	PlayerData.Update(player, function(p)
		p.playtime.day = today()
		p.playtime.seconds = 0
		p.playtime.claimed = {}
	end)
	push(player, profile.playtime)
end

function Playtime.Init()
	Net.event("PlaytimeChanged")
	Net.func("GetPlaytime").OnServerInvoke = onGetPlaytime
	Net.func("ClaimPlaytimeGift").OnServerInvoke = onClaimPlaytimeGift
	PlayerData.OnLoaded(onLoaded)
end

function Playtime.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		lastReady[player.UserId] = nil
		lastResting[player.UserId] = nil
		claiming[player.UserId] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(PlaytimeData.TickSeconds)
			local ok, err = pcall(function(): any
				tick()
				return nil
			end)
			if not ok then
				warn(("[%s] Playtime: tick failed: %s"):format(Config.WorkingTitle, tostring(err)))
			end
		end
	end)
	local minutes: { string } = {}
	for _, gift in ipairs(GIFTS) do
		table.insert(minutes, tostring(gift.minutes))
	end
	print(("[%s] Playtime: %s; gifts at %s min, %ds ticks, day resets at %02d:00 UTC"):format(
		Config.WorkingTitle,
		if PlaytimeData.Enabled then "on" else "off (Shared/data/Playtime Enabled = false)",
		table.concat(minutes, ", "),
		PlaytimeData.TickSeconds,
		PlaytimeData.ResetHourUtc
	))
end

return Playtime
