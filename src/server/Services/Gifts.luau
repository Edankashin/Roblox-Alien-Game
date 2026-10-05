--!strict
-- ServerScriptService.Server.Services.Gifts: Welcome Week and the spin wheel.
-- Welcome Week (Shared/data/Gifts) unlocks by days played, never by consecutive days: a "day" is a
-- UTC day index (os.time() over Config.GiftDaySeconds) and profile.gifts.daysPlayed grows by one the
-- first time the profile loads on a new day. Day N of the week opens once daysPlayed reaches N and each
-- day is claimed once (profile.gifts.claimed[day]). The wheel (Shared/data/Spins) gives
-- Spins.FreePerDay free spins on each new day (profile.spins.free, reset on load) and banks the spins
-- gifts and later systems hand out (profile.spins.banked); a spin spends a free one first. Every
-- segment has value and the odds live in the data. Nothing here costs Scrap or Robux, so none of it
-- is a paid random item. Rewards write into the profile here; an egg goes through Economy.GrantAlien
-- like a catch or a Peddler egg (record, codex, Scrap, seating, Reveal) with the wild overlay odds
-- (Spawner.RollOverlay). The client renders the calendar and the wheel; it sends a day or nothing.
-- Spins bought with Robux (a Starter Pack's five) are banked here too: Gifts registers its "spins"
-- granter with Monetization at Init, so the balance and its GiftsChanged push stay in one place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local GiftsData = require(Shared.data.Gifts)
local Spins = require(Shared.data.Spins)
local Lures = require(Shared.data.Lures)
local PowerUps = require(Shared.data.PowerUps)
local Species = require(Shared.data.Species)
local AnalyticsData = require(Shared.data.Analytics)
local Place = require(Shared.Place)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Spawner = require(script.Parent.Spawner)
local Economy = require(script.Parent.Economy)
local Analytics = require(script.Parent.Analytics)
local Monetization = require(script.Parent.Monetization)

local Gifts = {}

-- scrap and spin carry an amount; lure, powerUp and token carry a data id and an amount; egg a tier.
type Reward = { kind: string, id: string?, amount: number?, tier: string? }
type GiftRow = { day: number, label: string, reward: Reward }
type Segment = { id: string, label: string, odds: number, reward: Reward }
type PowerUpDef = { name: string, seconds: number, effect: string, value: number, sellable: boolean }

local CLAIM_RATE_PER_SECOND = 4 -- ClaimGift calls per player per second
local SPIN_RATE_PER_SECOND = 2 -- Spin calls per player per second
local ODDS_TOTAL = 100 -- what a wheel's odds are meant to sum to (Spins.luau); the roll uses the real sum

-- The data tables are mixed-shape literals, so their rows are read through these typed views.
local ROWS: { GiftRow } = (GiftsData :: any) :: { GiftRow }
local SEGMENTS: { Segment } = (Spins.Segments :: any) :: { Segment }
local POWER_UPS: { [string]: PowerUpDef } = {}
for id, def in pairs(PowerUps :: { [string]: PowerUpDef }) do
	POWER_UPS[id] = def
end

local rng = Random.new()

-- Days ----------------------------------------------------------------------

-- The UTC day index: every profile on every server agrees on when a day ticks over.
local function today(): number
	return math.floor(os.time() / Config.GiftDaySeconds)
end

-- Pushes ------------------------------------------------------------------

local function pushGifts(player: Player, profile: Types.Profile)
	local state: Types.GiftState = {
		daysPlayed = profile.gifts.daysPlayed,
		claimed = profile.gifts.claimed,
		freeSpins = profile.spins.free,
		bankedSpins = profile.spins.banked,
	}
	Net.event("GiftsChanged"):FireClient(player, state)
end

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

-- Rewards -----------------------------------------------------------------

-- A random species of the tier from the world this place runs that can be owned outside a quest and
-- outside an event (the Shower Cosmic stays a shower catch).
local function pickEggSpecies(tier: string?, world: number): string?
	if not tier then
		return nil
	end
	local candidates: { string } = {}
	for _, def in ipairs(Species.List) do
		if def.tier == tier and def.world == world and def.condition ~= "Quest" and def.condition ~= "Shower" then
			table.insert(candidates, def.id)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

-- Checks a reward against the data tables before anything is written, so a bad row refuses cleanly
-- (reason "Unknown") instead of granting nothing. Eggs are resolved by the caller (pickEggSpecies).
local function isKnownReward(reward: Reward): boolean
	local kind = reward.kind
	local id = reward.id
	if kind == "scrap" or kind == "spin" then
		return type(reward.amount) == "number"
	elseif kind == "lure" then
		return id ~= nil and Lures.Lures[id] ~= nil
	elseif kind == "powerUp" then
		return id ~= nil and POWER_UPS[id] ~= nil
	elseif kind == "token" then
		-- A companion-slot token: the companions milestone consumes profile.inventory.items[id].
		return id ~= nil and id ~= ""
	end
	return false
end

-- Writes a scrap, lure, powerUp, spin or token reward into the profile (inside PlayerData.Update).
-- Returns whether Scrap and whether the inventory changed, for the pushes.
local function applyReward(p: Types.Profile, reward: Reward): (boolean, boolean)
	local amount = reward.amount or 0
	local id = reward.id or ""
	local kind = reward.kind
	if kind == "scrap" then
		p.scrap += amount
		return true, false
	elseif kind == "lure" then
		p.inventory.lures[id] = (p.inventory.lures[id] or 0) + amount
		return false, true
	elseif kind == "powerUp" then
		p.inventory.powerUps[id] = (p.inventory.powerUps[id] or 0) + amount
		return false, true
	elseif kind == "spin" then
		p.spins.banked += amount
		return false, false
	elseif kind == "token" then
		p.inventory.items[id] = (p.inventory.items[id] or 0) + amount
		return false, true
	end
	return false, false
end

-- Cumulative roll over the segments' odds (the Peddler's weight technique); the last segment catches a
-- roll that lands on the total.
local function rollSegment(): number
	local total = 0
	for _, segment in ipairs(SEGMENTS) do
		total += segment.odds
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	for index, segment in ipairs(SEGMENTS) do
		acc += segment.odds
		if roll < acc then
			return index
		end
	end
	return #SEGMENTS
end

-- Join ----------------------------------------------------------------------

-- Runs on the live profile before the join payload is sent: a new day counts as played and refills the
-- free spins (a first-ever load makes daysPlayed 1). The free spins also refill when their own day
-- stamp is stale, so a profile saved before the wheel existed starts with its daily spin.
local function onLoaded(player: Player, profile: Types.Profile)
	local day = today()
	if profile.gifts.lastPlayDay ~= day then
		profile.gifts.daysPlayed += 1
		profile.gifts.lastPlayDay = day
		profile.spins.free = Spins.FreePerDay
		profile.spins.lastFree = day
	end
	if profile.spins.lastFree ~= day then
		profile.spins.free = Spins.FreePerDay
		profile.spins.lastFree = day
	end
	pushGifts(player, profile)
end

-- Remotes -------------------------------------------------------------------

-- ClaimGift(day) -> (ok, reason, grant). day is 1..#Gifts; grant is the GrantResult of an egg so the
-- client can show the Reveal, nil for every other kind. An egg row grants one alien per claim.
-- Reasons: BadArgs, RateLimited, NoProfile, Locked (day > daysPlayed), AlreadyClaimed, Unknown (a
-- reward whose id or tier resolves to nothing in the data tables; nothing is written).
local function onClaimGift(player: Player, day: any): (boolean, string?, Types.GrantResult?)
	if type(day) ~= "number" or day ~= day or day % 1 ~= 0 or day < 1 or day > #ROWS then
		return false, "BadArgs"
	end
	if not Net.allow(player, "ClaimGift", CLAIM_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if day > profile.gifts.daysPlayed then
		return false, "Locked"
	end
	local key = tostring(day)
	if profile.gifts.claimed[key] then
		return false, "AlreadyClaimed"
	end

	-- Resolve what the row grants before the claim is marked, so a bad data row refuses cleanly.
	local reward = ROWS[day].reward
	local eggSpecies: string? = nil
	if reward.kind == "egg" then
		eggSpecies = pickEggSpecies(reward.tier, Place.WorldId())
		if not eggSpecies then
			return false, "Unknown"
		end
	elseif not isKnownReward(reward) then
		return false, "Unknown"
	end

	local scrapChanged, inventoryChanged = false, false
	PlayerData.Update(player, function(p)
		p.gifts.claimed[key] = true -- once per day of the week
		if not eggSpecies then
			scrapChanged, inventoryChanged = applyReward(p, reward)
		end
	end)

	local grant: Types.GrantResult? = nil
	if eggSpecies then
		-- GrantAlien writes the record, pays the codex, seats it and pushes ScrapChanged and the camp.
		grant = Economy.GrantAlien(player, eggSpecies, Spawner.RollOverlay(), false)
	end
	if scrapChanged then
		pushScrap(player, profile)
	end
	if inventoryChanged then
		pushInventory(player, profile)
	end
	pushGifts(player, profile)
	Analytics.Event(player, AnalyticsData.Events.GiftClaim, day)
	if scrapChanged then
		Analytics.Economy(player, "Source", reward.amount or 0, profile.scrap, "TimedReward", AnalyticsData.Economy.Sources.Gift)
	end
	return true, nil, grant
end

-- Spin() -> (ok, reason, result). Spends a free spin first, else a banked one, rolls a segment by its
-- odds and grants its reward; result names the segment (id and 1-based index) so the client can land
-- the wheel on it. Reasons: RateLimited, NoProfile, NoSpins, Unknown (a segment whose reward id
-- resolves to nothing in the data tables; no spin is spent).
local function onSpin(player: Player): (boolean, string?, Types.SpinResult?)
	if not Net.allow(player, "Spin", SPIN_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if profile.spins.free <= 0 and profile.spins.banked <= 0 then
		return false, "NoSpins"
	end
	local index = rollSegment()
	local segment = SEGMENTS[index]
	if not segment or not isKnownReward(segment.reward) then
		return false, "Unknown"
	end

	local scrapChanged, inventoryChanged = false, false
	PlayerData.Update(player, function(p)
		if p.spins.free > 0 then
			p.spins.free -= 1
		else
			p.spins.banked -= 1
		end
		scrapChanged, inventoryChanged = applyReward(p, segment.reward)
	end)

	if scrapChanged then
		pushScrap(player, profile)
	end
	if inventoryChanged then
		pushInventory(player, profile)
	end
	pushGifts(player, profile) -- the spin balance moved (and a "spin" reward would bank more)
	Analytics.Event(player, AnalyticsData.Events.Spin, 1, { segmentId = segment.id })
	if scrapChanged then
		Analytics.Economy(player, "Source", segment.reward.amount or 0, profile.scrap, "Gameplay", AnalyticsData.Economy.Sources.Spin)
	end
	return true, nil, { segmentId = segment.id, index = index }
end

-- Public API -------------------------------------------------------------

-- Developer overrides (Studio commands, guarded by Dev): set the days played (0..#Gifts) so any day of
-- the week can be claimed, and bank extra spins. Both push GiftsChanged so the screen updates at once.
function Gifts.DevSetDays(player: Player, days: number)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	PlayerData.Update(player, function(p)
		p.gifts.daysPlayed = math.clamp(math.floor(days), 0, #ROWS)
	end)
	pushGifts(player, profile)
end

function Gifts.DevAddSpins(player: Player, count: number)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	PlayerData.Update(player, function(p)
		p.spins.banked = math.max(0, p.spins.banked + math.floor(count))
	end)
	pushGifts(player, profile)
end

-- Applies a list of rewards (the Reward rows of data/Social.luau or any other table of the same shape) to
-- a loaded profile in one PlayerData.Update with the same applyReward a gift claim uses, then pushes Scrap,
-- the inventory and the spin balance exactly as a claim does. Kinds: scrap, lure, powerUp, spin; a row of
-- any other kind, or one whose id resolves to nothing in the data tables, is skipped with a warn. Returns
-- false when the player has no loaded profile (nothing is written).
local GRANTABLE_KINDS: { [string]: boolean } = { scrap = true, lure = true, powerUp = true, spin = true }

function Gifts.GrantRewards(player: Player, rewards: { any }): boolean
	local profile = PlayerData.Get(player)
	if not profile then
		return false
	end
	local scrapChanged = false
	local inventoryChanged = false
	local ok = PlayerData.Update(player, function(p)
		for _, row in ipairs(rewards) do
			local reward: Reward? = if type(row) == "table" then (row :: any) :: Reward else nil
			if reward and GRANTABLE_KINDS[reward.kind] and isKnownReward(reward) then
				local scrap, inventory = applyReward(p, reward)
				scrapChanged = scrapChanged or scrap
				inventoryChanged = inventoryChanged or inventory
			else
				warn(("[%s] Gifts.GrantRewards: skipped a reward of unknown kind or id (%s)"):format(Config.WorkingTitle, if reward then tostring(reward.kind) else typeof(row)))
			end
		end
	end)
	if not ok then
		return false
	end
	if scrapChanged then
		pushScrap(player, profile)
	end
	if inventoryChanged then
		pushInventory(player, profile)
	end
	pushGifts(player, profile)
	return true
end

function Gifts.Init()
	for _, name in ipairs({ "GiftsChanged", "ScrapChanged", "InventoryChanged" }) do
		Net.event(name)
	end
	Net.func("ClaimGift").OnServerInvoke = onClaimGift
	Net.func("Spin").OnServerInvoke = onSpin
	PlayerData.OnLoaded(onLoaded)
	-- Robux spins bank like gifted ones and the wheel screen hears the new balance at once.
	Monetization.SetGranter("spins", function(player: Player, grant: Monetization.Grant): (boolean, string?)
		local profile = PlayerData.Get(player)
		if not profile then
			return false, "NoProfile"
		end
		local amount = math.max(0, math.floor(grant.amount or 0))
		PlayerData.Update(player, function(p)
			p.spins.banked += amount
		end)
		pushGifts(player, profile)
		return true, nil
	end)
end

function Gifts.Start()
	local total = 0
	for _, segment in ipairs(SEGMENTS) do
		total += segment.odds
	end
	if total ~= ODDS_TOTAL then
		warn(("[%s] Gifts: wheel odds sum to %s, not %d (Shared/data/Spins)"):format(Config.WorkingTitle, tostring(total), ODDS_TOTAL))
	end
	print(("[%s] Gifts: %d Welcome Week days, %d wheel segments, %d free spin(s) a day"):format(
		Config.WorkingTitle,
		#ROWS,
		#SEGMENTS,
		Spins.FreePerDay
	))
end

return Gifts
