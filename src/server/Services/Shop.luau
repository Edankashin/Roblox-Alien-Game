--!strict
-- ServerScriptService.Server.Services.Shop: the Scrap shop. Sells lures (Shared/data/Lures), the
-- movement gear Scrap can buy (Shared/data/Gear) and the radar tiers (Shared/data/Radar) for the one
-- currency. Every purchase is decided here:
-- the client sends a kind and an id and nothing else; the server checks the price against the live
-- profile, deducts, grants, and pushes the result (ScrapChanged, InventoryChanged, GearChanged).
-- Scrap is never sold for Robux; the Robux catalog in Shared/data/Shop is a later service's job.
-- This service also owns WalkSpeed: a character runs at Gear.BaseWalkSpeed times the best movement
-- multiplier its player owns times an active Speed Burst (Buffs.SpeedMultiplier), set from the server
-- on spawn, on profile load, on purchase and when a speed buff starts or ends. The client never sets
-- it. The requires run one way: Shop requires Buffs for the multiplier and hands Buffs its
-- ApplyMovement through Buffs.OnMovementChanged, so Buffs never requires Shop back; and Shop requires
-- Quests to report a crafted lure (Quests.OnCraft) and hands Quests its GrantGear through
-- Quests.SetGearGranter (the Field Notes pay gear), so Quests never requires Shop back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Lures = require(Shared.data.Lures)
local Gear = require(Shared.data.Gear)
local Radar = require(Shared.data.Radar)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Buffs = require(script.Parent.Buffs)
local Quests = require(script.Parent.Quests)
local Analytics = require(script.Parent.Analytics)

local Shop = {}

type GearRow = { name: string, speedMultiplier: number, scrap: number, unlock: string }
type RadarRow = { name: string, range: number, scrap: number, unlock: string? }

local REMOTE_RATE_PER_SECOND = 4 -- ShopBuy calls per player per second
local HUMANOID_WAIT_SECONDS = 10 -- a fresh character gets this long to grow its Humanoid before the speed set is skipped

-- Gear.luau is a fixed-shape table (it also carries BaseWalkSpeed), so its rows are picked out here to
-- be looked up by the id the client sends.
local GEAR_ROWS: { [string]: GearRow } = { Boots = Gear.Boots, Hoverboard = Gear.Hoverboard, Glider = Gear.Glider, JetBoost = Gear.JetBoost }
-- The profile.gear flag each gear id sets. Jet Boost has no flag yet (World 3 traversal, a later milestone).
local GEAR_FLAG: { [string]: string } = { Boots = "boots", Hoverboard = "hoverboard", Glider = "glider" }
-- Gear Scrap can buy today: the rows whose unlock is an alternative route, not a requirement. The Glider
-- waits on the first launch and Jet Boost on World 3 field notes, so both answer "Locked" for now.
local SCRAP_BUYABLE: { [string]: boolean } = { Boots = true, Hoverboard = true }
-- The radar is one number on the profile (gear.radar, the tier owned), bought or granted one tier at a
-- time under the ids Radar1..Radar3. Only Mk1 exists as a feature yet, so the higher tiers answer Locked.
local RADAR_TIER: { [string]: number } = { Radar1 = 1, Radar2 = 2, Radar3 = 3 }
local RADAR_BUYABLE: { [number]: boolean } = { [1] = true }
local RADAR_ROWS: { [number]: RadarRow } = (Radar :: any) :: { [number]: RadarRow }

-- profile.gear is a fixed-shape table and the id arrives as a string, so its flags are read and written
-- through these two helpers and nowhere else.
local function hasGear(profile: Types.Profile, field: string): boolean
	local flags: { [string]: any } = profile.gear :: any
	return flags[field] == true
end

local function grantGear(profile: Types.Profile, field: string)
	local flags: { [string]: any } = profile.gear :: any
	flags[field] = true
end

-- Pushes -----------------------------------------------------------------

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

local function pushGear(player: Player, profile: Types.Profile)
	Net.event("GearChanged"):FireClient(player, profile.gear)
end

-- Movement ---------------------------------------------------------------

-- Gear.BaseWalkSpeed times the best speedMultiplier among the gear this player owns (none -> 1),
-- times an active Speed Burst (none -> 1).
local function walkSpeedFor(player: Player): number
	local profile = PlayerData.Get(player)
	local best = 1
	if profile then
		for id, field in pairs(GEAR_FLAG) do
			local row = GEAR_ROWS[id]
			if row and hasGear(profile, field) and row.speedMultiplier > best then
				best = row.speedMultiplier
			end
		end
	end
	return Gear.BaseWalkSpeed * best * Buffs.SpeedMultiplier(player)
end

-- Sets the current character's WalkSpeed from the profile and buffs. Safe to call with no character.
-- Public so Buffs can re-apply it (through OnMovementChanged) when a speed buff starts or ends.
function Shop.ApplyMovement(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = walkSpeedFor(player)
	end
end

-- A fresh character may not carry its Humanoid the instant CharacterAdded fires, so wait for it.
local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", HUMANOID_WAIT_SECONDS)
	if humanoid and humanoid:IsA("Humanoid") and player.Character == character then
		humanoid.WalkSpeed = walkSpeedFor(player)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
	local current = player.Character
	if current then
		task.spawn(onCharacterAdded, player, current)
	end
end

-- Purchases --------------------------------------------------------------

-- Runs fn against the live profile inside PlayerData.Update. fn returns a refusal reason or nil.
local function mutate(player: Player, fn: (Types.Profile) -> string?): (boolean, string?)
	local reason: string? = nil
	local ok = PlayerData.Update(player, function(profile)
		reason = fn(profile)
	end)
	if not ok then
		return false, "NoProfile"
	end
	if reason then
		return false, reason
	end
	return true, nil
end

local function buyLure(player: Player, id: string): (boolean, string?)
	local def = Lures.Lures[id]
	if not def then
		return false, "Unknown"
	end
	local ok, reason = mutate(player, function(profile)
		if profile.scrap < def.scrap then
			return "NotEnoughScrap"
		end
		profile.scrap -= def.scrap
		profile.inventory.lures[id] = (profile.inventory.lures[id] or 0) + 1
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushScrap(player, profile)
		pushInventory(player, profile)
		Analytics.Event(player, AnalyticsData.Events.ShopBuy, 1, { kind = "lure", id = id })
		Analytics.Economy(player, "Sink", def.scrap, profile.scrap, "Shop", AnalyticsData.Economy.Sinks.Shop)
	end
	Quests.OnCraft(player, id) -- a bought lure is a crafted lure for the Field Notes
	return true, nil
end

-- Radar tiers are bought in order: the next tier only, for its Scrap price.
local function buyRadar(player: Player, tier: number): (boolean, string?)
	local row = RADAR_ROWS[tier]
	if not row then
		return false, "Unknown"
	end
	if not RADAR_BUYABLE[tier] then
		return false, "Locked"
	end
	local ok, reason = mutate(player, function(profile)
		if profile.gear.radar >= tier then
			return "AlreadyOwned"
		end
		if profile.gear.radar ~= tier - 1 then
			return "Locked"
		end
		if profile.scrap < row.scrap then
			return "NotEnoughScrap"
		end
		profile.scrap -= row.scrap
		profile.gear.radar = tier
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushScrap(player, profile)
		pushGear(player, profile)
		Analytics.Event(player, AnalyticsData.Events.ShopBuy, 1, { kind = "gear", id = "Radar" .. tostring(tier) })
		Analytics.Economy(player, "Sink", row.scrap, profile.scrap, "Shop", AnalyticsData.Economy.Sinks.Shop)
	end
	return true, nil
end

local function buyGear(player: Player, id: string): (boolean, string?)
	local radarTier = RADAR_TIER[id]
	if radarTier then
		return buyRadar(player, radarTier)
	end
	local row = GEAR_ROWS[id]
	if not row then
		return false, "Unknown"
	end
	local field = GEAR_FLAG[id]
	if not SCRAP_BUYABLE[id] or not field then
		return false, "Locked"
	end
	local ok, reason = mutate(player, function(profile)
		if hasGear(profile, field) then
			return "AlreadyOwned"
		end
		if profile.scrap < row.scrap then
			return "NotEnoughScrap"
		end
		profile.scrap -= row.scrap
		grantGear(profile, field)
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushScrap(player, profile)
		pushGear(player, profile)
		Analytics.Event(player, AnalyticsData.Events.ShopBuy, 1, { kind = "gear", id = id })
		Analytics.Economy(player, "Sink", row.scrap, profile.scrap, "Shop", AnalyticsData.Economy.Sinks.Shop)
	end
	Shop.ApplyMovement(player)
	return true, nil
end

-- Remotes ----------------------------------------------------------------

-- ShopBuy(kind, id) -> (ok, reason). kind is "lure" or "gear"; id is a Lures.Lures or Gear row id, or
-- Radar1..Radar3 for a radar tier. Reasons: BadArgs, RateLimited, NoProfile, Unknown, Locked,
-- AlreadyOwned, NotEnoughScrap.
local function onShopBuy(player: Player, kind: any, id: any): (boolean, string?)
	if (kind ~= "lure" and kind ~= "gear") or type(id) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "ShopBuy", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	if kind == "lure" then
		return buyLure(player, id)
	end
	return buyGear(player, id)
end

-- Public API -------------------------------------------------------------

-- Hands a player a gear row for free (a Field Notes reward): sets its profile flag, pushes GearChanged
-- and re-applies WalkSpeed. Unlock rules do not apply; the reward is the unlock. A radar id raises
-- gear.radar to that tier (never lowers it). Returns false with Unknown (no row, or no flag yet),
-- NoProfile, or AlreadyOwned (nothing changes; a caller may treat that as done).
function Shop.GrantGear(player: Player, id: string): (boolean, string?)
	local radarTier = RADAR_TIER[id]
	if radarTier then
		if not RADAR_ROWS[radarTier] then
			return false, "Unknown"
		end
		local ok, reason = mutate(player, function(profile)
			if profile.gear.radar >= radarTier then
				return "AlreadyOwned"
			end
			profile.gear.radar = radarTier
			return nil
		end)
		if not ok then
			return false, reason
		end
		local profile = PlayerData.Get(player)
		if profile then
			pushGear(player, profile)
		end
		return true, nil
	end
	local field = GEAR_FLAG[id]
	if not GEAR_ROWS[id] or not field then
		return false, "Unknown"
	end
	local ok, reason = mutate(player, function(profile)
		if hasGear(profile, field) then
			return "AlreadyOwned"
		end
		grantGear(profile, field)
		return nil
	end)
	if not ok then
		return false, reason
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushGear(player, profile)
	end
	Shop.ApplyMovement(player)
	return true, nil
end

function Shop.Init()
	for _, name in ipairs({ "ScrapChanged", "InventoryChanged", "GearChanged" }) do
		Net.event(name)
	end
	Net.func("ShopBuy").OnServerInvoke = onShopBuy
	-- The Field Notes pay gear through this service so the flag, the push and the speed stay in one place.
	Quests.SetGearGranter(Shop.GrantGear)
	-- The character can spawn before the profile loads (base speed); once it loads, the speed catches up.
	PlayerData.OnLoaded(function(player: Player, _profile: Types.Profile)
		Shop.ApplyMovement(player)
	end)
	-- A Speed Burst starting or ending re-applies the speed (see the header for the one-way require).
	Buffs.OnMovementChanged(function(player: Player)
		Shop.ApplyMovement(player)
	end)
end

function Shop.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	local gearCount = 0
	for _ in pairs(SCRAP_BUYABLE) do
		gearCount += 1
	end
	print(("[%s] Shop: %d lures and %d gear for Scrap"):format(Config.WorkingTitle, #Lures.Order, gearCount))
end

return Shop
