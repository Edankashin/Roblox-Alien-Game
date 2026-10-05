--!strict
-- ServerScriptService.Server.Services.Buffs: active power-ups and the player's luck number.
-- A power-up lives in profile.buffs as id -> seconds remaining, so it survives a rejoin, and it only
-- counts down here, while the player is online (design: a kid never wastes one by closing the app).
-- Other services read the live effects through the query API below (Shop for speed, Catching for
-- zones, Economy for Scrap and income, Spawner for luck); none of them read profile.buffs directly.
-- Luck is one number per player: 1, plus an active Lucky Charm, plus the night bonus, plus the server's
-- Meteor Shower bonus (Events.ServerLuckBonus), plus the soft pity that rises with every catch below
-- Config.PityResetMinTier, capped at Config.LuckCap.
--
-- Shop owns WalkSpeed and requires this module for the speed multiplier, so this module never requires
-- Shop back: Shop registers Shop.ApplyMovement through Buffs.OnMovementChanged at Init and that
-- callback runs whenever a speed buff starts or ends. The shower runs the other way: this module
-- requires Events for the bonus (Events requires only WorldClock, Net and Config, so the graph stays
-- acyclic) and registers Buffs.PushLuckAll through Events.OnShowerChanged at Init, so every player's
-- LuckChanged is re-sent when a shower starts or ends without Events ever requiring Buffs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Tiers = require(Shared.data.Tiers)
local PowerUps = require(Shared.data.PowerUps)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local WorldClock = require(script.Parent.WorldClock)
local Events = require(script.Parent.Events)

local Buffs = {}

type PowerUpDef = { name: string, seconds: number, effect: string, value: number, sellable: boolean }

local REMOTE_RATE_PER_SECOND = 4 -- UsePowerUp calls per player per second

-- PowerUps.luau is a fixed-shape table, so its rows are gathered here to be looked up by the id the
-- client sends. Every row has the same shape; a new row only needs adding to the data table.
local DEFS: { [string]: PowerUpDef } = {}
for id, def in pairs(PowerUps :: { [string]: PowerUpDef }) do
	DEFS[id] = def
end

local movementListeners: { (Player) -> () } = {} -- Shop.ApplyMovement, see the header
local sincePush: { [number]: number } = {} -- seconds since the last BuffsChanged push, by UserId
local wasNight = false

-- Pushes -----------------------------------------------------------------

local function pushBuffs(player: Player, profile: Types.Profile)
	Net.event("BuffsChanged"):FireClient(player, profile.buffs)
	sincePush[player.UserId] = 0
end

local function pushLuck(player: Player)
	Net.event("LuckChanged"):FireClient(player, Buffs.Luck(player))
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

-- Effects ----------------------------------------------------------------

local function isActive(profile: Types.Profile, id: string): boolean
	local left = profile.buffs[id]
	return left ~= nil and left > 0
end

-- The strongest value among this profile's active buffs with the given effect; 0 when none is active.
-- One power-up per effect exists in the data, so this is normally just that one's value.
local function activeValue(profile: Types.Profile?, effect: string): number
	if not profile then
		return 0
	end
	local best = 0
	for id, left in pairs(profile.buffs) do
		local def = DEFS[id]
		if def and left > 0 and def.effect == effect and def.value > best then
			best = def.value
		end
	end
	return best
end

-- What other services and the client must hear when a buff of this effect starts or ends.
local function afterChange(player: Player, effect: string)
	if effect == "speed" then
		for _, callback in ipairs(movementListeners) do
			callback(player)
		end
	elseif effect == "luck" then
		pushLuck(player)
	end
end

-- Query API --------------------------------------------------------------
-- Pure reads of profile.buffs against the PowerUps data. Safe without a profile (neutral values).

-- WalkSpeed factor: 1 + the value of an active "speed" buff, else 1.
function Buffs.SpeedMultiplier(player: Player): number
	return 1 + activeValue(PlayerData.Get(player), "speed")
end

-- Fraction both capture zones grow by: the value of an active "zone" buff, else 0.
function Buffs.ZoneBonus(player: Player): number
	return activeValue(PlayerData.Get(player), "zone")
end

-- Catch pay factor: 1 + the value of an active "catchScrap" buff, else 1.
function Buffs.CatchScrapMultiplier(player: Player): number
	return 1 + activeValue(PlayerData.Get(player), "catchScrap")
end

-- Station income factor: the value of an active "stationScrap" buff (Double Shift is 2), else 1.
function Buffs.StationMultiplier(player: Player): number
	local value = activeValue(PlayerData.Get(player), "stationScrap")
	return if value > 0 then value else 1
end

-- The one luck number the Spawner rolls tiers with and the HUD shows: 1 + Lucky Charm + night bonus
-- + the server's shower bonus + soft pity, capped at Config.LuckCap.
function Buffs.Luck(player: Player): number
	local profile = PlayerData.Get(player)
	local luck = 1 + activeValue(profile, "luck")
	if profile then
		luck += profile.luck.pity
	end
	if WorldClock.IsNight() then
		luck += Config.LuckNightBonus
	end
	luck += Events.ServerLuckBonus()
	return math.min(luck, Config.LuckCap)
end

-- Re-sends LuckChanged to every loaded player: for the server-wide parts of luck (night, the shower).
function Buffs.PushLuckAll()
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerData.Get(player) then
			pushLuck(player)
		end
	end
end

-- Pity -------------------------------------------------------------------

-- Economy.GrantAlien calls this for every alien that enters a profile: a catch of PityResetMinTier or
-- above clears the pity bonus, anything below raises it by PityStepPerCatch up to PityMax.
function Buffs.OnCatch(player: Player, tier: Types.Tier)
	local rank = table.find(Tiers.Order, tier) or 0
	local resetRank = table.find(Tiers.Order, Config.PityResetMinTier) or math.huge
	local ok = PlayerData.Update(player, function(profile)
		if rank >= resetRank then
			profile.luck.pity = 0
		else
			profile.luck.pity = math.min(Config.PityMax, profile.luck.pity + Config.PityStepPerCatch)
		end
	end)
	if ok then
		pushLuck(player)
	end
end

-- Shop registers its WalkSpeed setter here (see the header for why the require runs one way only).
function Buffs.OnMovementChanged(callback: (Player) -> ())
	table.insert(movementListeners, callback)
end

-- Remotes ----------------------------------------------------------------

-- UsePowerUp(id) -> (ok, reason). id is a PowerUps row id the player holds in inventory.powerUps.
-- Reasons: BadArgs, RateLimited, NoProfile, Unknown, NoneHeld, AlreadyActive.
local function onUsePowerUp(player: Player, id: any): (boolean, string?)
	if type(id) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "UsePowerUp", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local def = DEFS[id]
	if not def then
		return false, "Unknown"
	end
	local reason: string? = nil
	PlayerData.Update(player, function(p)
		local held = p.inventory.powerUps[id] or 0
		if held <= 0 then
			reason = "NoneHeld"
			return
		end
		if isActive(p, id) then
			reason = "AlreadyActive"
			return
		end
		p.inventory.powerUps[id] = held - 1
		p.buffs[id] = def.seconds
	end)
	if reason then
		return false, reason
	end
	pushInventory(player, profile)
	pushBuffs(player, profile)
	afterChange(player, def.effect)
	return true, nil
end

-- Tick -------------------------------------------------------------------

-- Counts every online player's active buffs down by dt, drops the ones that reach 0, and pushes
-- BuffsChanged when one ends or every BuffPushSeconds while any is active (the client counts down
-- between pushes, so an idle profile gets nothing).
local function tick(dt: number)
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(player)
		if profile then
			local ended: { string } = {}
			local active = false
			PlayerData.Update(player, function(p)
				for id, left in pairs(p.buffs) do
					local remaining = left - dt
					if remaining <= 0 then
						p.buffs[id] = nil
						table.insert(ended, id)
					else
						p.buffs[id] = remaining
						active = true
					end
				end
			end)
			local since = (sincePush[player.UserId] or 0) + dt
			sincePush[player.UserId] = since
			if #ended > 0 or (active and since >= Config.BuffPushSeconds) then
				pushBuffs(player, profile)
			end
			for _, id in ipairs(ended) do
				local def = DEFS[id]
				if def then
					afterChange(player, def.effect)
				end
			end
		end
	end
end

-- Public API -------------------------------------------------------------

function Buffs.Init()
	for _, name in ipairs({ "BuffsChanged", "LuckChanged", "InventoryChanged" }) do
		Net.event(name)
	end
	Net.func("UsePowerUp").OnServerInvoke = onUsePowerUp
	-- The join payload already carries profile.buffs; these pushes cover a client that pulled its
	-- profile early, and LuckChanged has no other first push.
	PlayerData.OnLoaded(function(player: Player, profile: Types.Profile)
		pushBuffs(player, profile)
		pushLuck(player)
	end)
	-- The shower bonus is part of every player's luck, so a start or end re-sends the number to all
	-- (registered here rather than required from Events; see the header).
	Events.OnShowerChanged(function()
		Buffs.PushLuckAll()
	end)
end

function Buffs.Start()
	wasNight = WorldClock.IsNight()
	-- The night bonus is part of every player's luck, so a day/night flip re-sends the number to all.
	WorldClock.OnChanged(function()
		local night = WorldClock.IsNight()
		if night == wasNight then
			return
		end
		wasNight = night
		Buffs.PushLuckAll()
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		sincePush[player.UserId] = nil
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Config.BuffTickSeconds)
			local now = os.clock()
			tick(now - last)
			last = now
		end
	end)

	local count = 0
	for _ in pairs(DEFS) do
		count += 1
	end
	print(("[%s] Buffs: %d power-ups, ticking every %ss"):format(Config.WorkingTitle, count, tostring(Config.BuffTickSeconds)))
end

return Buffs
