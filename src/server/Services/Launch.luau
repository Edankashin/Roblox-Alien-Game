--!strict
-- ServerScriptService.Server.Services.Launch: the ship lifts off and the player moves to the next
-- world. Every world is its own place in one universe (GAME_DESIGN sections 8 and 17; Shared/Place says
-- which world this place runs, Shared/data/Worlds carries each world's placeId). The client asks through
-- the Launch RemoteFunction once the ship is complete; this service alone decides: the profile must be on
-- this place's world, every module of it complete (Shared/Economy.activeModuleIndex is nil), and a next
-- world must exist. On yes, in one PlayerData.Update, the profile moves to the next world, unlocks it and
-- opens an outpost on the world it leaves; then the client hears Launched (the lift and the fade) and,
-- Config.LaunchTeleportDelaySeconds later, the server teleports the player to the next world's place
-- when that place is published (placeId > 0). A world not yet published (placeId 0) launches the same way
-- on the profile; the client shows its "opens when published" line and the camp returns. Studio never
-- teleports (TeleportAsync errors there), so Studio counts every place as not live and says so at Start.
-- A failed teleport warns and leaves the player where they are: the profile already says the next
-- world, so the next join of that world's place carries on from there.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Worlds = require(Shared.data.Worlds)
local Economy = require(Shared.Economy)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local AnalyticsData = require(Shared.data.Analytics)

local Launch = {}

local REMOTE_RATE_PER_SECOND = 2 -- Launch calls per player per second
-- The custom event name for a launch (value 1; fields from, to). It belongs in Shared/data/Analytics.Events
-- beside the other chart names; it lives here until that table carries it.

local inFlight: { [number]: boolean } = {} -- a launch accepted and not yet teleported (or given up), by UserId

-- A place is live when it has a published id and this is not Studio (TeleportAsync errors in Studio).
local function placeIsLive(world: Worlds.WorldDef): boolean
	return world.placeId > 0 and not RunService:IsStudio()
end

-- The move itself, Config.LaunchTeleportDelaySeconds after the launch was accepted: the player is still
-- here and the place is live, or nothing happens (the client has already shown the fade and the camp).
local function teleportLater(player: Player, nextWorld: Worlds.WorldDef, placeLive: boolean)
	task.delay(Config.LaunchTeleportDelaySeconds, function()
		if player.Parent ~= Players then
			inFlight[player.UserId] = nil
			return
		end
		if not placeLive then
			inFlight[player.UserId] = nil
			return
		end
		local ok, err = pcall(function(): any
			return TeleportService:TeleportAsync(nextWorld.placeId, { player })
		end)
		if not ok then
			warn(("[%s] Launch: teleport of %s to world %d (place %d) failed: %s"):format(Config.WorkingTitle, player.Name, nextWorld.id, nextWorld.placeId, tostring(err)))
			inFlight[player.UserId] = nil
		end
		-- On success the player leaves this server; PlayerRemoving clears the flag. A failure Roblox reports
		-- after the call returned reaches TeleportInitFailed below.
	end)
end

-- Launch() -> (ok, reason). Reasons: RateLimited, NoProfile, Busy (a launch is already in flight),
-- WrongWorld (the profile's ship is on another world than this place runs), NotComplete (a module of this
-- world is not finished), NoNextWorld (this is the last world).
local function onLaunch(player: Player): (boolean, string?)
	if not Net.allow(player, "Launch", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if inFlight[player.UserId] then
		return false, "Busy"
	end
	local here = Place.WorldId()
	if profile.world.current ~= here then
		return false, "WrongWorld"
	end
	if Economy.activeModuleIndex(profile, here) ~= nil then
		return false, "NotComplete"
	end
	local nextId = here + 1
	local nextWorld: Worlds.WorldDef? = Worlds[nextId]
	if not nextWorld then
		return false, "NoNextWorld"
	end
	inFlight[player.UserId] = true
	local now = os.time()
	local ok = PlayerData.Update(player, function(p: Types.Profile)
		p.world.current = nextId
		if not table.find(p.world.unlocked, nextId) then
			table.insert(p.world.unlocked, nextId)
		end
		local key = tostring(here)
		if not p.world.outposts[key] then
			p.world.outposts[key] = { level = 1, lastCollect = now }
		end
	end)
	if not ok then
		inFlight[player.UserId] = nil
		return false, "NoProfile"
	end
	local placeLive = placeIsLive(nextWorld)
	Analytics.Event(player, AnalyticsData.Events.Launch, 1, { from = tostring(here), to = tostring(nextId) })
	Net.event("Launched"):FireClient(player, nextId, placeLive)
	print(("[%s] Launch: %s lifts off from world %d to world %d (%s)"):format(Config.WorkingTitle, player.Name, here, nextId, if placeLive then "place " .. tostring(nextWorld.placeId) else "no live place"))
	teleportLater(player, nextWorld, placeLive)
	return true, nil
end

function Launch.Init()
	Net.event("Launched")
	Net.func("Launch").OnServerInvoke = onLaunch
end

function Launch.Start()
	Players.PlayerRemoving:Connect(function(player: Player)
		inFlight[player.UserId] = nil
	end)
	-- A teleport Roblox refuses after TeleportAsync returned: the player stays; say why and let them try again.
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		if inFlight[player.UserId] then
			inFlight[player.UserId] = nil
			warn(("[%s] Launch: teleport of %s failed (%s): %s"):format(Config.WorkingTitle, player.Name, result.Name, message))
		end
	end)

	local here = Place.WorldId()
	local thisWorld = Worlds[here]
	local nextWorld: Worlds.WorldDef? = Worlds[here + 1]
	local tail: string
	if nextWorld then
		local placeText = if nextWorld.placeId > 0 then tostring(nextWorld.placeId) else "not published"
		tail = ("next world %d place %s"):format(nextWorld.id, placeText)
	else
		tail = "last world"
	end
	if RunService:IsStudio() then
		tail ..= "; Studio: teleports are skipped (every place counts as not live)"
	end
	print(("[%s] Launch: this is world %d (%s); %s"):format(Config.WorkingTitle, here, thisWorld.name, tail))
end

return Launch
