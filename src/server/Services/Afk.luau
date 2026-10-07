--!strict
-- ServerScriptService.Server.Services.Afk: resting in the game (milestone 46; every number is in Shared/data/Afk).
-- A player who neither moves nor uses the game for Afk.IdleAfterSeconds is resting, and Buffs.StationMultiplier pays
-- their stations at Afk.IncomeScale of the usual rate for as long as they stay. Playing is worth about twice as much
-- and earns catches and progress on top, so resting is for the nights and the school days, never better than playing.
-- Being away (the game closed) pays the same half rate but stops after Config.OfflineCapSeconds; resting never runs out.
--
-- Activity is two signals. MOVEMENT: every Afk.CheckSeconds the loop reads each loaded player's root part and counts
-- the FLAT (X and Z) distance since the last check; Afk.MoveStuds or more is movement. Flat, not 3D, so a jump in
-- place (the usual anti-AFK macro) does not count, while any walk, ride or fall-and-walk does. USE: Net.allow, which
-- every server handler calls, reports each call to the listener this module sets at Init (Net.SetActivityListener), so
-- any remote a player calls is use of the game, except AfkRejoin (the client's automatic request, never a person) and
-- the pulls the client makes by itself on a server push (a weekly flip, a season change, a missed alien list delta: rare, and they only wake a
-- resting player for the next two minutes, which is the free direction). A resting player who is active again wakes at
-- once on a remote call and at the next check on movement.
--
-- Resting is announced with AfkChanged(Types.AfkState): at the start, every check while it lasts (earned = the Scrap
-- gained since the start, so the client's "Earned while resting" rises) and at the end. The Rest analytics event goes
-- out on waking and on leaving. The camp rate the HUD shows is not pushed from here: RateChanged carries the rate with
-- no income factor in it (Double Shift's included), so the client scales its per-minute line by Afk.IncomeScale while
-- the last AfkChanged says resting (init.client's showRate); the server pays at the scale through Buffs.
--
-- Roblox disconnects a player with no input for 20 minutes and nothing prevents that, so the client asks (AfkRejoin)
-- at Afk.RejoinAfterIdleSeconds, and the server teleports the player to this same server (TeleportOptions.ServerInstanceId
-- is this JobId), which resets Roblox's timer; the resting screen shows "Keeping your spot..." (AfkRejoining, sent on
-- every accepted request, which is also how /afk rejoin reaches the screen). AfkRejoin refuses NotResting unless the
-- player rests, answers Private in a reserved or private server (ServerInstanceId cannot reach one: the homes, and
-- the friends' visits, are reserved servers, so the idle cutoff applies there and offline income covers the stretch), and
-- Failed when TeleportAsync errors. Studio skips teleports (they error there), so it prints what it would do.
-- AfkWake is the resting screen's "Back to play" button, any press while resting, and (at most every
-- AfkData.ActivityPingSeconds) a press or scroll while playing that no other remote reports, like browsing a menu: a
-- call to it is use of the game like any other, so it wakes
-- the player at once.
--
-- Requires PlayerData, Analytics and Net with shared code only; Buffs requires this module for the income scale and Dev
-- calls it. Boot (Service-Boot.md): no network call runs in Init or Start; TeleportAsync runs inside the remote handler.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local AfkData = require(Shared.data.Afk)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)

local Afk = {}

local REJOIN_RATE_PER_SECOND = 1 -- AfkRejoin calls per player per second
local WAKE_RATE_PER_SECOND = 2 -- AfkWake calls per player per second
local REJOIN_REMOTE = "AfkRejoin" -- the one remote that is not use of the game (see the header)

type Record = {
	lastPosition: Vector3?, -- the root part's position at the last check
	lastActive: number, -- os.clock() of the last movement or use of the game
	resting: boolean,
	restStart: number, -- os.time() when this rest began
	scrapAtStart: number, -- the profile's Scrap then
	earned: number, -- the last figure pushed, for a leave that finds the profile already gone
}

local records: { [number]: Record } = {} -- by UserId
local rejoining: { [number]: boolean } = {} -- a rejoin accepted and not yet gone (or refused after the call), by UserId

-- Records ----------------------------------------------------------------

local function recordOf(player: Player): Record
	local existing = records[player.UserId]
	if existing then
		return existing
	end
	local created: Record = { lastPosition = nil, lastActive = os.clock(), resting = false, restStart = 0, scrapAtStart = 0, earned = 0 }
	records[player.UserId] = created
	return created
end

local function pushState(player: Player, resting: boolean, since: number, earned: number)
	local state: Types.AfkState = { resting = resting, since = since, earned = earned }
	Net.event("AfkChanged"):FireClient(player, state)
end

-- Scrap gained since the rest began (never negative), kept on the record for a leave.
local function earnedOf(player: Player, record: Record): number
	local profile = PlayerData.Get(player)
	if profile then
		record.earned = math.max(0, profile.scrap - record.scrapAtStart)
	end
	return record.earned
end

-- Resting ----------------------------------------------------------------

local restListeners: { (Player) -> () } = {}

-- Tells the listeners (Buffs, which re-pushes the HUD's rate through Economy) that this player's resting changed.
local function fireRestChanged(player: Player)
	for _, callback in ipairs(restListeners) do
		task.spawn(callback, player)
	end
end

local function startRest(player: Player, record: Record, profile: Types.Profile)
	record.resting = true
	record.restStart = os.time()
	record.scrapAtStart = profile.scrap
	record.earned = 0
	pushState(player, true, record.restStart, 0)
	fireRestChanged(player)
	print(("[%s] Afk: %s is resting"):format(Config.WorkingTitle, player.Name))
end

-- The rest is over: the player moved, used the game, pressed the button, or is leaving (nobody to push to then).
local function endRest(player: Player, record: Record, leaving: boolean)
	record.resting = false
	local seconds = math.max(0, os.time() - record.restStart)
	local earned = earnedOf(player, record)
	if not leaving then
		pushState(player, false, record.restStart, earned)
		fireRestChanged(player)
	end
	Analytics.Event(player, AnalyticsData.Events.Rest, seconds, { earned = tostring(earned) })
end

-- Net.allow's listener: a call by the player is use of the game, except the rejoin request.
local function onActivity(player: Player, remote: string)
	if remote == REJOIN_REMOTE or player.Parent ~= Players then
		return
	end
	local record = recordOf(player)
	record.lastActive = os.clock()
	if record.resting then
		endRest(player, record, false)
	end
end

-- One pass over every player: movement since the last check, then who starts, keeps or ends resting.
local function check()
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(player)
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if profile and root and root:IsA("BasePart") then
			local record = recordOf(player)
			local position = root.Position
			local last = record.lastPosition
			if last then
				local flat = Vector3.new(position.X - last.X, 0, position.Z - last.Z)
				if flat.Magnitude >= AfkData.MoveStuds then
					record.lastActive = now
				end
			end
			record.lastPosition = position
			local idle = now - record.lastActive
			if record.resting then
				if idle < AfkData.IdleAfterSeconds then
					endRest(player, record, false)
				else
					pushState(player, true, record.restStart, earnedOf(player, record))
				end
			elseif idle >= AfkData.IdleAfterSeconds then
				startRest(player, record, profile)
			end
		end
	end
end

local function onPlayerRemoving(player: Player)
	local record = records[player.UserId]
	if record and record.resting then
		endRest(player, record, true)
	end
	records[player.UserId] = nil
	rejoining[player.UserId] = nil
end

-- Rejoin -----------------------------------------------------------------

-- The rejoin itself, for the remote and for /afk rejoin: (ok, reason). Reasons: NotResting, Private, Failed.
local function rejoin(player: Player): (boolean, string?)
	local record = records[player.UserId]
	if not record or not record.resting then
		return false, "NotResting"
	end
	if RunService:IsStudio() then
		print(("[%s] Afk: would rejoin %s to this server (Studio skips teleports)"):format(Config.WorkingTitle, player.Name))
		Net.event("AfkRejoining"):FireClient(player)
		return true, nil
	end
	if game.PrivateServerId ~= "" then
		return false, "Private" -- the idle cutoff applies in a reserved or private server; offline income covers it
	end
	if rejoining[player.UserId] then
		return true, nil -- already on its way
	end
	rejoining[player.UserId] = true
	local options = Instance.new("TeleportOptions")
	options.ServerInstanceId = game.JobId
	local ok, err = pcall(function(): any
		return TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		rejoining[player.UserId] = nil
		warn(("[%s] Afk: rejoin of %s failed: %s"):format(Config.WorkingTitle, player.Name, tostring(err)))
		return false, "Failed"
	end
	Net.event("AfkRejoining"):FireClient(player)
	return true, nil
end

-- Remotes ----------------------------------------------------------------

-- AfkRejoin() -> (ok, reason). Reasons: RateLimited, NotResting, Private, Failed. Not use of the game (see onActivity).
local function onAfkRejoin(player: Player): (boolean, string?)
	if not Net.allow(player, REJOIN_REMOTE, REJOIN_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return rejoin(player)
end

-- AfkWake(): the resting screen's button. Net.allow reports the call to onActivity, which wakes the player.
local function onAfkWake(player: Player)
	Net.allow(player, "AfkWake", WAKE_RATE_PER_SECOND)
end

-- Public API -------------------------------------------------------------

-- Runs `callback(player)` after a player starts or stops resting (Buffs forwards it as a station multiplier change).
function Afk.OnRestChanged(callback: (Player) -> ())
	table.insert(restListeners, callback)
end

function Afk.IsResting(player: Player): boolean
	local record = records[player.UserId]
	return record ~= nil and record.resting
end

-- Dev: rest now (the current position is the baseline, so moving wakes) or wake now.
function Afk.DevRest(player: Player, on: boolean)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local record = recordOf(player)
	if on then
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		record.lastPosition = if root and root:IsA("BasePart") then root.Position else nil
		record.lastActive = os.clock() - AfkData.IdleAfterSeconds -- idle for exactly the threshold: the next check keeps the rest
		if not record.resting then
			startRest(player, record, profile)
		end
	else
		record.lastActive = os.clock() -- so the next check does not start it again
		if record.resting then
			endRest(player, record, false)
		end
	end
end

-- Dev: the same path as the remote (Studio only prints it, and the resting screen shows its line).
function Afk.DevRejoin(player: Player): (boolean, string?)
	return rejoin(player)
end

function Afk.Init()
	Net.event("AfkChanged")
	Net.event("AfkRejoining")
	Net.event("AfkWake").OnServerEvent:Connect(onAfkWake)
	Net.func("AfkRejoin").OnServerInvoke = onAfkRejoin
	Net.SetActivityListener(onActivity)
end

function Afk.Start()
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	-- A rejoin Roblox refuses after TeleportAsync returned: the player stays, and may be asked again.
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		if rejoining[player.UserId] then
			rejoining[player.UserId] = nil
			warn(("[%s] Afk: rejoin of %s failed (%s): %s"):format(Config.WorkingTitle, player.Name, result.Name, message))
		end
	end)
	task.spawn(function()
		while true do
			task.wait(AfkData.CheckSeconds)
			local ok, err = pcall(function(): any
				check()
				return nil
			end)
			if not ok then
				warn(("[%s] Afk: check failed: %s"):format(Config.WorkingTitle, tostring(err)))
			end
		end
	end)
	local where = if RunService:IsStudio() then "Studio: rejoin only prints" else "rejoin to this server"
	print(("[%s] Afk: resting after %ds idle (income x%s), checked every %ds; %s at %ds idle"):format(
		Config.WorkingTitle,
		AfkData.IdleAfterSeconds,
		tostring(AfkData.IncomeScale),
		AfkData.CheckSeconds,
		where,
		AfkData.RejoinAfterIdleSeconds
	))
end

return Afk
