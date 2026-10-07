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
-- FlyTo(worldId) is the Star Chart's flight to any unlocked world other than the one the ship is on: the
-- destination outpost's production is banked (Outposts.Collect with force), the world being left is
-- stamped (Outposts.Touch), the profile moves, the client hears Flew (the fade) and, after
-- Config.FlyTeleportDelaySeconds, the same teleport as a launch runs.
-- The home planet (world 0, data/Home; milestone 42a) is a world you fly to, never one you launch from or to:
-- a launch from home answers NoNextWorld; the first successful launch anywhere sets profile.home.unlocked and
-- puts the home in profile.world.unlocked (and fires HomeUnlocked once, only that first time); FlyTo accepts
-- the home when home.unlocked (a migrated save with the flag but no entry in the list gets the entry on that
-- fly), counts each arrival in home.visits, and never touches Outposts for it: the home is not an outpost, so
-- nothing is banked on arriving there and no clock is stamped when leaving it.
-- Visiting (milestone 42e) reaches this service through SetVisiting(hooks), registered by the Visiting service at Init (it
-- requires Launch, so Launch cannot require it back). A guest is a player standing at someone else's home or at a place
-- that is not the world their ship is on (hooks.IsGuest): FlyTo lets a guest fly to the world the ship is on without
-- moving the profile at all (no banking, no stamp, no visit counted, no WorldChanged: the ship never left), and
-- the same call from the home place with no live place ends the visit (hooks.LeaveView); with a live place it
-- teleports as usual. Every teleport to the home passes hooks.HomeOptions, the player's own reserved server of the
-- home place, so friends already there see them arrive; nil options (Studio, no live place, a failed lookup) mean the
-- public home place, as before. Trip(player, destination, options) is the flight that changes nothing on the profile: the
-- visit to a friend's reserved home server (Visiting builds the options) fades and teleports exactly like a fly.

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
local Tutorial = require(script.Parent.Tutorial)
local Outposts = require(script.Parent.Outposts)
local Analytics = require(script.Parent.Analytics)
local AnalyticsData = require(Shared.data.Analytics)
local Home = require(Shared.data.Home)

local Launch = {}

-- What Visiting hands over at Init: who counts as a guest, the teleport options that send a player to their own
-- reserved home server (nil: none, use the public place; may yield), and how a guest at the home place goes back to
-- looking at their own home.
export type VisitingHooks = {
	IsGuest: (Player) -> boolean,
	HomeOptions: (Player) -> TeleportOptions?,
	LeaveView: (Player) -> (),
	IsInServerView: (Player) -> boolean,
}

local hooks: VisitingHooks? = nil

local HOME_WORLD = Home.WorldId -- the home planet's world id, from its layout row

local REMOTE_RATE_PER_SECOND = 2 -- Launch calls per player per second
-- The custom event name for a launch (value 1; fields from, to). It belongs in Shared/data/Analytics.Events
-- beside the other chart names; it lives here until that table carries it.

local inFlight: { [number]: boolean } = {} -- a launch accepted and not yet teleported (or given up), by UserId

-- A place is live when it has a published id and this is not Studio (TeleportAsync errors in Studio).
local function placeIsLive(world: Worlds.WorldDef): boolean
	return world.placeId > 0 and not RunService:IsStudio()
end

-- The move itself, `delay` seconds after the launch or flight was accepted (Config.LaunchTeleportDelaySeconds
-- or Config.FlyTeleportDelaySeconds): the player is still here and the place is live, or nothing happens
-- (the client has already shown the fade and the camp). `options` rides along to TeleportAsync (the reserved
-- server access code and teleport data of a home or a visit); nil is the public place.
local function teleportLater(player: Player, nextWorld: Worlds.WorldDef, placeLive: boolean, delay: number, options: TeleportOptions?)
	task.delay(delay, function()
		if player.Parent ~= Players then
			inFlight[player.UserId] = nil
			return
		end
		if not placeLive then
			inFlight[player.UserId] = nil
			return
		end
		local ok, err = pcall(function(): any
			return TeleportService:TeleportAsync(nextWorld.placeId, { player }, options)
		end)
		if not ok then
			warn(("[%s] Launch: teleport of %s to world %d (place %d) failed: %s"):format(Config.WorkingTitle, player.Name, nextWorld.id, nextWorld.placeId, tostring(err)))
			inFlight[player.UserId] = nil
		end
		-- On success the player leaves this server; PlayerRemoving clears the flag. A failure Roblox reports
		-- after the call returned reaches TeleportInitFailed below.
	end)
end

-- The teleport to the home planet: the player's own reserved server when Visiting has one (hooks.HomeOptions looks
-- the code up, which yields, so it runs in its own thread while the client fades and counts against the same delay).
local function teleportHome(player: Player, home: Worlds.WorldDef, placeLive: boolean, delay: number)
	local visiting = hooks
	if not placeLive or visiting == nil then
		teleportLater(player, home, placeLive, delay, nil)
		return
	end
	local started = os.clock()
	task.spawn(function()
		local ok, options = pcall(function(): TeleportOptions?
			return visiting.HomeOptions(player)
		end)
		if not ok then
			warn(("[%s] Launch: home server lookup for %s failed: %s"):format(Config.WorkingTitle, player.Name, tostring(options)))
			options = nil
		end
		teleportLater(player, home, placeLive, math.max(0, delay - (os.clock() - started)), options :: TeleportOptions?)
	end)
end

-- Launch() -> (ok, reason). Reasons: RateLimited, NoProfile, Busy (a launch is already in flight),
-- WrongWorld (the profile's ship is on another world than this place runs), NotComplete (a module of this
-- world is not finished), NoNextWorld (this is the last world, or the home planet: nothing launches from home).
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
	if Place.IsHome() then
		return false, "NoNextWorld"
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
	local homeJustUnlocked = false
	local ok = PlayerData.Update(player, function(p: Types.Profile)
		p.world.current = nextId
		if not table.find(p.world.unlocked, nextId) then
			table.insert(p.world.unlocked, nextId)
		end
		-- The first launch opens the home planet: a flyable world from then on.
		if not p.home.unlocked then
			p.home.unlocked = true
			homeJustUnlocked = true
		end
		if not table.find(p.world.unlocked, HOME_WORLD) then
			table.insert(p.world.unlocked, HOME_WORLD)
		end
		-- The camp left behind is an outpost from now: opened at level 1 the first time, and on a later launch
		-- from the same world (after a Star Chart flight back) its clock restarts so the time the ship spent
		-- here, paid by the stations, is not paid again by the outpost.
		local key = tostring(here)
		local outpost = p.world.outposts[key]
		if outpost then
			outpost.lastCollect = now
		else
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
	-- The client mirrors keep the old world until told: the new current world, its (empty) modules and the
	-- outpost just opened (the Star Chart shows it without a rejoin when no teleport follows).
	local moved = PlayerData.Get(player)
	if moved then
		Net.event("WorldChanged"):FireClient(player, moved.world.current, moved.world.unlocked)
		Net.event("ModulesChanged"):FireClient(player, moved.world.current, moved.modules[tostring(moved.world.current)] or {})
		Net.event("OutpostsChanged"):FireClient(player, moved.world.outposts)
	end
	if homeJustUnlocked then
		Net.event("HomeUnlocked"):FireClient(player)
	end
	Tutorial.OnWorldChanged(player) -- off World 1 the tutorial is over: its hint and trainee go
	print(("[%s] Launch: %s lifts off from world %d to world %d (%s)"):format(Config.WorkingTitle, player.Name, here, nextId, if placeLive then "place " .. tostring(nextWorld.placeId) else "no live place"))
	teleportLater(player, nextWorld, placeLive, Config.LaunchTeleportDelaySeconds, nil)
	return true, nil
end

-- A guest flying to the world the ship is on: the profile does not move, so nothing is banked, stamped, counted or
-- pushed. At the home place, a guest whose own home is right here (an in-server visit, or no live home place to go to)
-- just goes back to their own home view (hooks.LeaveView: the client hears HomeView(nil) and says "Back at your own
-- home"); nothing flies and nothing teleports. A guest who travelled to another's home server flies home as usual.
local function flyGuest(player: Player, destination: Worlds.WorldDef, toHome: boolean): (boolean, string?)
	local placeLive = placeIsLive(destination)
	local visiting = hooks
	if toHome and Place.IsHome() and visiting and (not placeLive or visiting.IsInServerView(player)) then
		visiting.LeaveView(player)
		print(("[%s] Launch: guest %s goes back to their own home in this server"):format(Config.WorkingTitle, player.Name))
		return true, nil
	end
	Net.event("Flew"):FireClient(player, destination.id, placeLive)
	print(("[%s] Launch: guest %s flies to world %d where the ship is (%s)"):format(Config.WorkingTitle, player.Name, destination.id, if placeLive then "place " .. tostring(destination.placeId) else "no live place"))
	if toHome then
		teleportHome(player, destination, placeLive, Config.FlyTeleportDelaySeconds)
	else
		teleportLater(player, destination, placeLive, Config.FlyTeleportDelaySeconds, nil)
	end
	return true, nil
end

-- FlyTo(worldId) -> (ok, reason). Reasons: RateLimited, NoProfile, Busy (a launch or flight is already in
-- flight), NoWorld (not a world in Shared/data/Worlds), Locked (not in profile.world.unlocked), SameWorld
-- (the ship is already on it and the player is not a guest). The home planet counts as unlocked when
-- profile.home.unlocked. A guest (Visiting's hook) may fly to the world the ship is on: see flyGuest.
local function onFlyTo(player: Player, worldArg: any): (boolean, string?)
	if not Net.allow(player, "FlyTo", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if inFlight[player.UserId] then
		return false, "Busy"
	end
	if typeof(worldArg) ~= "number" then
		return false, "NoWorld"
	end
	local worldId: number = worldArg
	local destination: Worlds.WorldDef? = if worldId == worldId and worldId % 1 == 0 then Worlds[worldId] else nil
	if not destination then
		return false, "NoWorld"
	end
	local toHome = worldId == HOME_WORLD
	if toHome then
		if not profile.home.unlocked then
			return false, "Locked"
		end
	elseif not table.find(profile.world.unlocked, worldId) then
		return false, "Locked"
	end
	local origin = profile.world.current
	local visiting = hooks
	local guest = visiting ~= nil and visiting.IsGuest(player)
	if worldId == origin and not guest then
		return false, "SameWorld"
	end
	inFlight[player.UserId] = true
	if worldId == origin then
		return flyGuest(player, destination, toHome)
	end
	local now = os.time()
	-- The destination's production is banked before the ship arrives; the world being left starts its clock.
	-- The home is no outpost: nothing to bank on arriving there, no clock to stamp when leaving it.
	if not toHome then
		local banked, bankReason = Outposts.Collect(player, worldId, true)
		if not banked then
			inFlight[player.UserId] = nil
			return false, bankReason or "NoProfile"
		end
	end
	if origin ~= HOME_WORLD then
		Outposts.Touch(player, origin, now)
	end
	local ok = PlayerData.Update(player, function(p: Types.Profile)
		p.world.current = worldId
		if toHome then
			p.home.visits += 1
			-- a save migrated with home.unlocked but no entry in the list gets its entry now
			if not table.find(p.world.unlocked, HOME_WORLD) then
				table.insert(p.world.unlocked, HOME_WORLD)
			end
		end
	end)
	if not ok then
		inFlight[player.UserId] = nil
		return false, "NoProfile"
	end
	local placeLive = placeIsLive(destination)
	if toHome and Place.IsHome() and not placeLive and visiting then
		visiting.LeaveView(player) -- no teleport follows: the player stays here and looks at their own home again
	end
	Analytics.Event(player, AnalyticsData.Events.Fly, 1, { from = tostring(origin), to = tostring(worldId) })
	Net.event("Flew"):FireClient(player, worldId, placeLive)
	-- The client mirrors keep the old world until told, exactly as after a launch.
	local moved = PlayerData.Get(player)
	if moved then
		Net.event("WorldChanged"):FireClient(player, moved.world.current, moved.world.unlocked)
		Net.event("ModulesChanged"):FireClient(player, moved.world.current, moved.modules[tostring(moved.world.current)] or {})
	end
	Tutorial.OnWorldChanged(player)
	print(("[%s] Launch: %s flies from world %d to world %d (%s)"):format(Config.WorkingTitle, player.Name, origin, worldId, if placeLive then "place " .. tostring(destination.placeId) else "no live place"))
	if toHome then
		teleportHome(player, destination, placeLive, Config.FlyTeleportDelaySeconds)
	else
		teleportLater(player, destination, placeLive, Config.FlyTeleportDelaySeconds, nil)
	end
	return true, nil
end

-- Public API -------------------------------------------------------------

-- Visiting registers its hooks at Init (see the header).
function Launch.SetVisiting(visitingHooks: VisitingHooks)
	hooks = visitingHooks
end

-- A flight that changes nothing on the profile: the client hears Flew (the fade) and, after
-- Config.FlyTeleportDelaySeconds, the player teleports to `destination`'s place with `options` (a visit sends the
-- reserved server access code and the owner in the teleport data). Returns true, or false with Busy when a launch or
-- flight is already in flight. The caller has validated everything else; a place that is not live fades and stays.
function Launch.Trip(player: Player, destination: Worlds.WorldDef, options: TeleportOptions?): (boolean, string?)
	if inFlight[player.UserId] then
		return false, "Busy"
	end
	inFlight[player.UserId] = true
	local placeLive = placeIsLive(destination)
	Net.event("Flew"):FireClient(player, destination.id, placeLive)
	print(("[%s] Launch: %s takes a trip to world %d (%s)"):format(Config.WorkingTitle, player.Name, destination.id, if placeLive then "place " .. tostring(destination.placeId) else "no live place"))
	teleportLater(player, destination, placeLive, Config.FlyTeleportDelaySeconds, options)
	return true, nil
end

function Launch.Init()
	Net.event("Launched")
	Net.event("Flew")
	Net.event("HomeUnlocked")
	Net.event("WorldChanged")
	Net.event("ModulesChanged")
	Net.func("Launch").OnServerInvoke = onLaunch
	Net.func("FlyTo").OnServerInvoke = onFlyTo
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
