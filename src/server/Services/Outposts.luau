--!strict
-- ServerScriptService.Server.Services.Outposts: the camps the player leaves behind (GAME_DESIGN section 8).
-- Launch writes profile.world.outposts[worldId] = { level, lastCollect }; from then on that camp produces
-- Scrap and its world's key materials, lazily: nothing ticks, the pending amount is the time since
-- lastCollect (capped at Shared/data/Outposts.CollectCapSeconds) times the level's rates, worked out by
-- Shared/OutpostMath. The player collects it from the Star Chart (CollectOutpost), upgrades the camp with
-- Scrap (UpgradeOutpost), and flying to a world banks its outpost first (Launch.FlyTo calls Collect with
-- force). The ship's own world never pays through its outpost (its camp's stations pay instead): Collect
-- answers Current there, and an upgrade there grants nothing pending. Leaving a world stamps its outpost
-- (Touch) so the time the ship spent there is never paid twice. Every grant is one PlayerData.Update;
-- the client hears ScrapChanged and InventoryChanged (the same remotes Gifts and Economy use) and
-- OutpostsChanged (the whole profile.world.outposts table). The client shows the rates and the clock from
-- OutpostMath; it never decides what is granted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local OutpostsData = require(Shared.data.Outposts)
local Worlds = require(Shared.data.Worlds)
local AnalyticsData = require(Shared.data.Analytics)
local OutpostMath = require(Shared.OutpostMath)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)

local Outposts = {}

local COLLECT_RATE_PER_SECOND = 2 -- CollectOutpost calls per player per second
local UPGRADE_RATE_PER_SECOND = 2 -- UpgradeOutpost calls per player per second
local TRANSACTION = "Gameplay" -- Analytics.Economy transaction type

-- Helpers -------------------------------------------------------------------

local function emptyPending(): OutpostMath.Pending
	return { scrap = 0, materials = {}, materialCount = 0, seconds = 0 }
end

-- A world id from a remote argument: a whole number that names a world in Shared/data/Worlds.
local function worldFrom(value: any): number?
	if typeof(value) ~= "number" then
		return nil
	end
	local id: number = value
	if id ~= id or id % 1 ~= 0 or not Worlds[id] then
		return nil
	end
	return id
end

-- Writes a pending amount into the profile (call inside PlayerData.Update).
local function bank(p: Types.Profile, pending: OutpostMath.Pending)
	p.scrap += pending.scrap
	for id, count in pairs(pending.materials) do
		p.inventory.keyMaterials[id] = (p.inventory.keyMaterials[id] or 0) + count
	end
end

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

local function pushOutposts(player: Player, profile: Types.Profile)
	Net.event("OutpostsChanged"):FireClient(player, profile.world.outposts)
end

-- After a change: the pushes for what moved, then the Source event for the granted Scrap (the balance
-- right after the grant, before any cost). `profile` is live.
local function announce(player: Player, profile: Types.Profile, pending: OutpostMath.Pending, balanceAfterGrant: number, scrapMoved: boolean)
	if scrapMoved then
		pushScrap(player, profile)
	end
	if pending.materialCount > 0 then
		pushInventory(player, profile)
	end
	pushOutposts(player, profile)
	Analytics.Economy(player, "Source", pending.scrap, balanceAfterGrant, TRANSACTION, AnalyticsData.Economy.Sources.Outpost)
end

-- Public API ------------------------------------------------------------------

-- Grants what the outpost on `worldId` has produced and restarts its clock at now. Returns (ok, reason,
-- pending). Reasons: NoProfile, NoWorld, NoOutpost, Current (the ship is on that world: its camp pays
-- instead), TooSoon (less than Outposts.CollectMinSeconds since lastCollect), Nothing (no Scrap and no
-- materials pending). With force = true the Current, TooSoon and Nothing refusals are skipped and
-- whatever is pending is granted, an empty pending included; a world with no outpost yet then answers ok
-- with an empty pending (nothing to bank) rather than NoOutpost, so a flight never fails on it.
function Outposts.Collect(player: Player, worldId: number, force: boolean): (boolean, string?, OutpostMath.Pending?)
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile", nil
	end
	if not worldFrom(worldId) then
		return false, "NoWorld", nil
	end
	local key = tostring(worldId)
	local state = profile.world.outposts[key]
	if not state then
		if force then
			return true, nil, emptyPending()
		end
		return false, "NoOutpost", nil
	end
	local now = os.time()
	if not force then
		if profile.world.current == worldId then
			return false, "Current", nil
		end
		if now - state.lastCollect < OutpostsData.CollectMinSeconds then
			return false, "TooSoon", nil
		end
	end
	local pending = OutpostMath.Pending(state, worldId, now)
	if not force and pending.scrap == 0 and pending.materialCount == 0 then
		return false, "Nothing", nil
	end
	-- Nothing yields between the reads above and this write, so the state is still the one priced.
	local granted = PlayerData.Update(player, function(p: Types.Profile)
		local live = p.world.outposts[key]
		if not live then
			return
		end
		bank(p, pending)
		live.lastCollect = now
	end)
	if not granted then
		return false, "NoProfile", nil
	end
	local live = PlayerData.Get(player)
	if live then
		announce(player, live, pending, live.scrap, pending.scrap > 0)
	end
	return true, nil, pending
end

-- Stamps the outpost on `worldId` at `now`, opening it at level 1 when it does not exist yet. Used when
-- the player leaves a world so the time the ship spent there is not paid again by its outpost.
function Outposts.Touch(player: Player, worldId: number, now: number)
	if not worldFrom(worldId) then
		return
	end
	local key = tostring(worldId)
	local ok = PlayerData.Update(player, function(p: Types.Profile)
		local state = p.world.outposts[key]
		if state then
			state.lastCollect = now
		else
			p.world.outposts[key] = { level = 1, lastCollect = now }
		end
	end)
	if ok then
		local live = PlayerData.Get(player)
		if live then
			pushOutposts(player, live)
		end
	end
end

-- Studio testing (Dev /outpost): opens the outpost on `worldId` at level 1 when missing and sets its
-- lastCollect `hours` hours before now, so the Star Chart has something to collect.
function Outposts.DevBackdate(player: Player, worldId: number, hours: number)
	if not worldFrom(worldId) then
		return
	end
	local key = tostring(worldId)
	local past = math.floor(os.time() - math.max(0, hours) * 3600)
	local ok = PlayerData.Update(player, function(p: Types.Profile)
		local state = p.world.outposts[key]
		if state then
			state.lastCollect = past
		else
			p.world.outposts[key] = { level = 1, lastCollect = past }
		end
	end)
	if ok then
		local live = PlayerData.Get(player)
		if live then
			pushOutposts(player, live)
		end
	end
end

-- Remotes ------------------------------------------------------------------------

-- CollectOutpost(worldId) -> (ok, reason, scrap, materialCount). Reasons: RateLimited, NoProfile, NoWorld,
-- NoOutpost, Current, TooSoon, Nothing (see Outposts.Collect).
local function onCollect(player: Player, worldArg: any): (boolean, string?, number?, number?)
	if not Net.allow(player, "CollectOutpost", COLLECT_RATE_PER_SECOND) then
		return false, "RateLimited", nil, nil
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile", nil, nil
	end
	local worldId = worldFrom(worldArg)
	if not worldId then
		return false, "NoWorld", nil, nil
	end
	local ok, reason, pending = Outposts.Collect(player, worldId, false)
	if not ok or not pending then
		return false, reason or "NoProfile", nil, nil
	end
	return true, nil, pending.scrap, pending.materialCount
end

-- UpgradeOutpost(worldId) -> (ok, reason). Reasons: RateLimited, NoProfile, NoWorld, NoOutpost, Maxed,
-- NotEnoughScrap. What the outpost has produced is granted first (so the old rate is not re-rated) except
-- on the ship's own world, where it grants nothing; then the level rises, the clock restarts and the cost
-- is paid. The Scrap just granted counts toward the cost.
local function onUpgrade(player: Player, worldArg: any): (boolean, string?)
	if not Net.allow(player, "UpgradeOutpost", UPGRADE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local worldId = worldFrom(worldArg)
	if not worldId then
		return false, "NoWorld"
	end
	local key = tostring(worldId)
	local state = profile.world.outposts[key]
	if not state then
		return false, "NoOutpost"
	end
	local cost = OutpostMath.UpgradeCost(state.level)
	if not cost then
		return false, "Maxed"
	end
	local now = os.time()
	local pending = if profile.world.current == worldId then emptyPending() else OutpostMath.Pending(state, worldId, now)
	if profile.scrap + pending.scrap < cost then
		return false, "NotEnoughScrap"
	end
	-- Nothing yields between the checks above and this write, so the balance and the state still hold.
	local done = PlayerData.Update(player, function(p: Types.Profile)
		local live = p.world.outposts[key]
		if not live then
			return
		end
		bank(p, pending)
		live.level += 1
		live.lastCollect = now
		p.scrap -= cost
	end)
	if not done then
		return false, "NoProfile"
	end
	local live = PlayerData.Get(player)
	if live then
		announce(player, live, pending, live.scrap + cost, true) -- the cost always moves the balance
		Analytics.Economy(player, "Sink", cost, live.scrap, TRANSACTION, AnalyticsData.Economy.Sinks.Outpost)
	end
	return true, nil
end

function Outposts.Init()
	Net.event("ScrapChanged")
	Net.event("InventoryChanged")
	Net.event("OutpostsChanged")
	Net.func("CollectOutpost").OnServerInvoke = onCollect
	Net.func("UpgradeOutpost").OnServerInvoke = onUpgrade
end

function Outposts.Start() end

return Outposts
