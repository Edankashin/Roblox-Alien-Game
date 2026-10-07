--!strict
-- ServerScriptService.Server.Services.Peddler: the merchant ship on a server-wide clock.
-- One visit clock for the whole server: every Config.PeddlerIntervalSeconds a visit begins, rolls
-- Peddler.OffersPerVisit distinct offers from Peddler.Pool by weight, and stays for
-- Config.PeddlerVisitSeconds. Stock is shared (everyone sees the same three offers, so players tell
-- each other what landed) and each player may buy each offer once per visit. Everything is priced in
-- Scrap, so nothing here is a paid random item. The egg kind grants an alien through
-- Economy.GrantAlien, which writes the record, pays the codex and seats it exactly like a catch.
-- The client renders the landing and the Trade screen; it only sends an offer index.
-- The home planet (Place.IsHome, world 0) gets no visits: the clock never starts there.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local PeddlerData = require(Shared.data.Peddler)
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

local Peddler = {}

type PowerUpDef = { name: string, seconds: number, effect: string, value: number, sellable: boolean }

local REMOTE_RATE_PER_SECOND = 4 -- PeddlerBuy calls per player per second
local SNAPSHOT_RATE_PER_SECOND = 2 -- GetPeddler calls per player per second

-- PowerUps.luau is a fixed-shape table, so its rows are gathered here to be looked up by offer id.
local POWER_UPS: { [string]: PowerUpDef } = {}
for id, def in pairs(PowerUps :: { [string]: PowerUpDef }) do
	POWER_UPS[id] = def
end

local rng = Random.new()
local visit: Types.PeddlerVisit? = nil
local bought: { [number]: { [number]: boolean } } = {} -- UserId -> offer index -> true, for the current visit

-- This player's purchases in the current visit (by UserId, so a rejoin changes nothing).
local function purchasesOf(player: Player): { [number]: boolean }
	local mine = bought[player.UserId]
	if mine then
		return mine
	end
	local fresh: { [number]: boolean } = {}
	bought[player.UserId] = fresh
	return fresh
end

-- Pushes -----------------------------------------------------------------

local function pushScrap(player: Player, profile: Types.Profile)
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
end

local function pushInventory(player: Player, profile: Types.Profile)
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
end

-- Visits -----------------------------------------------------------------

-- OffersPerVisit distinct rows drawn from the pool by weight, without replacement. The rows are copied
-- into the net payload shape (no weight) so the client only sees what it needs.
local function rollOffers(): { Types.PeddlerOffer }
	local remaining = table.clone(PeddlerData.Pool)
	local out: { Types.PeddlerOffer } = {}
	for _ = 1, math.min(PeddlerData.OffersPerVisit, #remaining) do
		local total = 0
		for _, row in ipairs(remaining) do
			total += row.weight
		end
		local roll = rng:NextNumber(0, total)
		local pick = #remaining
		local acc = 0
		for index, row in ipairs(remaining) do
			acc += row.weight
			if roll < acc then
				pick = index
				break
			end
		end
		local row = remaining[pick]
		table.remove(remaining, pick)
		table.insert(out, { id = row.id, kind = row.kind, scrap = row.scrap, amount = row.amount, tier = row.tier })
	end
	return out
end

local function beginVisit()
	table.clear(bought)
	local fresh: Types.PeddlerVisit = { offers = rollOffers(), endsAt = os.time() + Config.PeddlerVisitSeconds }
	visit = fresh
	Net.event("PeddlerChanged"):FireAllClients(fresh)
end

local function endVisit()
	visit = nil
	table.clear(bought)
	Net.event("PeddlerChanged"):FireAllClients(nil)
end

-- Eggs -------------------------------------------------------------------

-- The world an egg hatches from: this place's world, or at home (which has no wild species) the furthest
-- world the player has unlocked (Exploit-Review D5: a home egg used to resolve to nothing).
local function eggWorld(player: Player): number
	local here = Place.WorldId()
	if here ~= 0 then
		return here
	end
	local best = 1
	local profile = PlayerData.Get(player)
	if profile then
		for _, id in ipairs(profile.world.unlocked) do
			if id > best then
				best = id
			end
		end
	end
	return best
end

-- A random species of the offer's tier from the world this place runs that can be owned outside a quest.
local function pickEggSpecies(tier: string?, world: number): string?
	if not tier then
		return nil
	end
	local candidates: { string } = {}
	for _, def in ipairs(Species.List) do
		if def.tier == tier and def.world == world and def.condition ~= "Quest" then
			table.insert(candidates, def.id)
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

-- Remotes ----------------------------------------------------------------

-- GetPeddler() -> PeddlerVisit?. The current visit for a late joiner, nil between visits.
local function onGetPeddler(player: Player): Types.PeddlerVisit?
	if not Net.allow(player, "GetPeddler", SNAPSHOT_RATE_PER_SECOND) then
		return nil
	end
	return visit
end

-- PeddlerBuy(index) -> (ok, reason, grant). index is 1..#offers of the current visit; grant is the
-- GrantResult of an egg so the client can show the Reveal, nil for every other kind.
-- Reasons: BadArgs, RateLimited, NoProfile, NoVisit, AlreadyBought, NotEnoughScrap, Unknown (an offer
-- whose id or tier resolves to nothing in the data tables; nothing is charged).
local function onPeddlerBuy(player: Player, index: any): (boolean, string?, Types.GrantResult?)
	if type(index) ~= "number" or index ~= index or index % 1 ~= 0 then
		return false, "BadArgs"
	end
	if not Net.allow(player, "PeddlerBuy", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local current = visit
	if not current then
		return false, "NoVisit"
	end
	local offer = current.offers[index]
	if not offer then
		return false, "BadArgs"
	end
	local mine = purchasesOf(player)
	if mine[index] then
		return false, "AlreadyBought"
	end

	-- Resolve what the offer grants before any Scrap moves, so a bad data row refuses cleanly.
	local kind = offer.kind
	local eggSpecies: string? = nil
	if kind == "lure" then
		if not Lures.Lures[offer.id] then
			return false, "Unknown"
		end
	elseif kind == "powerUp" then
		if not POWER_UPS[offer.id] then
			return false, "Unknown"
		end
	elseif kind == "egg" then
		eggSpecies = pickEggSpecies(offer.tier, eggWorld(player))
		if not eggSpecies then
			return false, "Unknown"
		end
	elseif kind ~= "scrap" then
		return false, "Unknown"
	end

	local reason: string? = nil
	PlayerData.Update(player, function(p)
		if p.scrap < offer.scrap then
			reason = "NotEnoughScrap"
			return
		end
		p.scrap -= offer.scrap
		if kind == "lure" then
			p.inventory.lures[offer.id] = (p.inventory.lures[offer.id] or 0) + 1
		elseif kind == "powerUp" then
			p.inventory.powerUps[offer.id] = (p.inventory.powerUps[offer.id] or 0) + 1
		elseif kind == "scrap" then
			p.scrap += offer.amount or 0
		end
	end)
	if reason then
		return false, reason
	end

	mine[index] = true -- once per offer per visit
	Analytics.Event(player, AnalyticsData.Events.PeddlerBuy, 1, { kind = kind })
	Analytics.Economy(player, "Sink", offer.scrap, profile.scrap, "Shop", AnalyticsData.Economy.Sinks.Peddler)

	if eggSpecies then
		-- GrantAlien pushes ScrapChanged (the price is already off) and the camp, and returns the Reveal.
		local grant = Economy.GrantAlien(player, eggSpecies, Spawner.RollOverlay(), false)
		return true, nil, grant
	end
	if offer.scrap > 0 or kind == "scrap" then
		pushScrap(player, profile)
	end
	if kind == "lure" or kind == "powerUp" then
		pushInventory(player, profile)
	end
	return true, nil, nil
end

-- Public API -------------------------------------------------------------

function Peddler.GetVisit(): Types.PeddlerVisit?
	return visit
end

function Peddler.Init()
	for _, name in ipairs({ "PeddlerChanged", "ScrapChanged", "InventoryChanged" }) do
		Net.event(name)
	end
	Net.func("GetPeddler").OnServerInvoke = onGetPeddler
	Net.func("PeddlerBuy").OnServerInvoke = onPeddlerBuy
end

function Peddler.Start()
	if Place.IsHome() then
		print(("[%s] Peddler: this is the home planet; no visits"):format(Config.WorkingTitle))
		return
	end
	-- The interval is measured from one visit's start to the next, so the gap is interval minus stay.
	task.spawn(function()
		task.wait(Config.PeddlerFirstVisitSeconds)
		while true do
			beginVisit()
			task.wait(Config.PeddlerVisitSeconds)
			endVisit()
			task.wait(math.max(0, Config.PeddlerIntervalSeconds - Config.PeddlerVisitSeconds))
		end
	end)
	print(("[%s] Peddler: %d of %d offers every %ss, staying %ss"):format(
		Config.WorkingTitle,
		PeddlerData.OffersPerVisit,
		#PeddlerData.Pool,
		tostring(Config.PeddlerIntervalSeconds),
		tostring(Config.PeddlerVisitSeconds)
	))
end

return Peddler
