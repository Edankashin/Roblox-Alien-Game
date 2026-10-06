--!strict
-- StarterPlayerScripts.Client.State: the client's mirror of its own profile. The server owns the real
-- one and pushes changes (ScrapChanged, StationsChanged, ModulesChanged, InventoryChanged, RateChanged,
-- SettingsChanged, PurchasesChanged, ServerLuckChanged, ShowerChanged, CatchRushChanged, CompanionsChanged);
-- this module applies them to the copy and tells screens which topic changed. Nothing here decides
-- anything; it only remembers what the server said last. InventoryChanged carries the whole inventory
-- table (key materials, lures, power-ups); GearChanged carries the gear table.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("types"):WaitForChild("Types"))
local Economy = require(Shared:WaitForChild("Economy"))
local Companions = require(Shared:WaitForChild("data"):WaitForChild("Companions"))
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Overlays = require(Shared:WaitForChild("data"):WaitForChild("Overlays"))
local Worlds = require(Shared:WaitForChild("data"):WaitForChild("Worlds"))
local Settings = require(Shared:WaitForChild("data"):WaitForChild("Settings"))

local State = {}

-- The daily and weekly quest sets with the instants (server wall clock, os.time scale) each one rolls over.
export type DailyQuestsSnapshot = { daily: Types.PeriodQuests, weekly: Types.PeriodQuests, dailyResetsAt: number, weeklyResetsAt: number }

-- "profile" fires once when the whole profile arrives; every topic listener also runs then.
export type Topic = "scrap" | "stations" | "modules" | "inventory" | "gear" | "rate" | "clock" | "biome" | "codex" | "buffs" | "peddler" | "luck" | "quests" | "tutorial" | "gifts" | "shower" | "rush" | "settings" | "purchases" | "serverLuck" | "world" | "outposts" | "friends" | "companions" | "profile"

local profile: Types.Profile? = nil
local rate: Types.CampState = { ratePerSecond = 0, assemblySpeed = {} }
local ratePushed = false -- until the server's first RateChanged, the rate is derived from the profile
local clock: Types.ClockState = { isNight = false, weather = "Clear", secondsLeft = 0, weatherSecondsLeft = 0 }
local biome: Types.Biome = "Meadow"
local buffs: { [string]: number } = {} -- id -> server wall-clock time (os.time scale) the buff ends at
local gifts: Types.GiftState = { daysPlayed = 0, claimed = {}, freeSpins = 0, bankedSpins = 0 }
local shower: Types.ShowerState = { active = false, secondsLeft = 0, nextInSeconds = 0 }
local showerAt = 0 -- State.Now() when the shower state arrived, so the client counts between pushes
local rush: Types.CatchRushState = { active = false, secondsLeft = 0, nextInSeconds = 0, rows = {} }
local rushAt = 0 -- State.Now() when the Catch Rush state arrived, so the client counts between pushes
local peddler: Types.PeddlerVisit? = nil
local luck = 1
local friendCount = 0 -- friends in this server and the luck boost they give (FriendBoostChanged), a fraction
local friendBoost = 0
local dailyResetsAt = 0 -- the last DailyQuests snapshot's reset instants; 0 until one arrives
local weeklyResetsAt = 0
-- Robux products granted and passes owned (PurchasesChanged). Until the first push the table is seeded
-- from the profile, which knows the products and the Starter Pack choice but not the passes.
local purchases: Types.PurchasesState = { purchases = {}, passes = {}, starterSpecies = nil }
local purchasesPushed = false
local serverLuck: Types.ServerLuckState = nil -- the shared luck someone bought (ServerLuckChanged); nil when none runs
local serverLuckAt = 0 -- State.Now() when it arrived, so a banner counts down between pushes
local riding: string? = nil -- the uid of the follower the local player rides (CompanionsChanged); nil on foot. Never saved: a rejoin starts on foot

-- Every data/Settings key with its value in `source`, or the data default where it is missing.
local function settingsWithDefaults(source: { [string]: number }?): Types.SettingsState
	local out: Types.SettingsState = {}
	for _, def in ipairs(Settings.Order) do
		local value = if source then source[def.key] else nil
		out[def.key] = if type(value) == "number" then value else def.default
	end
	return out
end

local settings: Types.SettingsState = settingsWithDefaults(nil) -- the data defaults until the profile arrives
local changed = Instance.new("BindableEvent")
local started = false

local function fire(topic: Topic)
	changed:Fire(topic)
end

function State.Set(p: Types.Profile)
	profile = p
	if not ratePushed then
		-- A client that booted after the server's pushes still shows the right rate: same shared maths.
		rate = Economy.campState(p)
	end
	-- The gift state is part of the profile; the join-time GiftsChanged push can land before this
	-- client listens, so the mirror is rebuilt from the profile and later pushes overwrite it.
	gifts = { daysPlayed = p.gifts.daysPlayed, claimed = p.gifts.claimed, freeSpins = p.spins.free, bankedSpins = p.spins.banked }
	-- Preferences: the profile's table filled out with the data defaults so every key reads; "profile"
	-- reaches the "settings" listeners too, so Prefs applies them from here.
	settings = settingsWithDefaults(p.settings)
	p.settings = settings
	-- Purchases: the profile knows the products and the Starter Pack choice; a PurchasesChanged push that
	-- already arrived also knows the passes and wins, so the profile takes its copy instead.
	if purchasesPushed then
		p.purchases = purchases.purchases
		p.shop.starterSpecies = purchases.starterSpecies
	else
		purchases = { purchases = p.purchases, passes = {}, starterSpecies = p.shop.starterSpecies }
	end
	fire("profile")
	fire("gifts")
end

function State.Has(): boolean
	return profile ~= nil
end

function State.Get(): Types.Profile
	local p = profile
	assert(p, "State.Get before State.Set")
	return p
end

function State.GetRate(): Types.CampState
	return rate
end

-- The last ClockChanged state the HUD received (the bootstrap feeds it in).
function State.GetClock(): Types.ClockState
	return clock
end

function State.SetClock(state: Types.ClockState)
	clock = state
	fire("clock")
end

-- The single spawn condition the server judges by: the world's special weather beats Night beats Day
-- (mirrors WorldClock.GetCondition).
function State.GetCondition(): Types.Condition
	local p = profile
	local world = Worlds[if p then p.world.current else 1]
	if world and clock.weather == world.weather.special.id then
		return (clock.weather :: any) :: Types.Condition
	end
	return if clock.isNight then "Night" else "Day"
end

-- Every condition active right now (mirrors WorldClock.GetConditions): the special weather while it
-- runs, plus Night or Day, plus Shower while a Meteor Shower runs.
function State.GetConditions(): { Types.Condition }
	local out: { Types.Condition } = {}
	local p = profile
	local world = Worlds[if p then p.world.current else 1]
	if world and clock.weather == world.weather.special.id then
		table.insert(out, (clock.weather :: any) :: Types.Condition)
	end
	table.insert(out, if clock.isNight then "Night" else "Day")
	if shower.active then
		table.insert(out, "Shower")
	end
	return out
end

-- OutpostsChanged carries the whole outposts table (world id string -> level and lastCollect).
-- Its own topic, not "world": a world change closes every screen (the ship moved), an outpost update
-- only redraws the Star Chart.
function State.SetOutposts(outposts: { [string]: Types.OutpostState })
	if profile then
		profile.world.outposts = outposts
		fire("outposts")
	end
end

-- The biome the local player stands in (the bootstrap polls Biomes.At and feeds it in).
function State.GetBiome(): Types.Biome
	return biome
end

function State.SetBiome(b: Types.Biome)
	if b ~= biome then
		biome = b
		fire("biome")
	end
end

function State.GetGifts(): Types.GiftState
	return gifts
end

-- Every data/Settings key with the value the server holds (SettingsChanged, seeded from the profile);
-- the data defaults until either arrives.
function State.GetSettings(): Types.SettingsState
	return settings
end

-- The shower clock as pushed, plus the seconds elapsed since, so countdowns run between pushes.
function State.GetShower(): (Types.ShowerState, number)
	return shower, math.max(0, Workspace:GetServerTimeNow() - showerAt)
end

-- A late joiner's GetShower answer; a push that already arrived is newer and wins.
function State.SeedShower(state: Types.ShowerState)
	if showerAt > 0 then
		return
	end
	shower = state
	showerAt = Workspace:GetServerTimeNow()
	fire("shower")
end

-- The Catch Rush clock as pushed (the round's state and its leaders), plus the seconds elapsed since,
-- so countdowns run between pushes.
function State.GetRush(): (Types.CatchRushState, number)
	return rush, math.max(0, Workspace:GetServerTimeNow() - rushAt)
end

-- A late joiner's GetCatchRush answer; a push that already arrived is newer and wins.
function State.SeedRush(state: Types.CatchRushState)
	if rushAt > 0 then
		return
	end
	rush = state
	rushAt = Workspace:GetServerTimeNow()
	fire("rush")
end

-- Robux products granted (id -> count), passes owned and the Starter Pack's Rare, plus whether the
-- server has sent them (PurchasesChanged or GetPurchases); before that the passes are unknown.
function State.GetPurchases(): (Types.PurchasesState, boolean)
	return purchases, purchasesPushed
end

-- The server's purchases state (a PurchasesChanged push or a GetPurchases answer) replaces the mirror
-- and is written back into the profile so profile readers agree.
function State.SetPurchases(state: Types.PurchasesState)
	purchases = state
	purchasesPushed = true
	local p = profile
	if p then
		p.purchases = state.purchases
		p.shop.starterSpecies = state.starterSpecies
	end
	fire("purchases")
end

-- A late GetPurchases answer; a push that already arrived is newer and wins.
function State.SeedPurchases(state: Types.PurchasesState)
	if purchasesPushed then
		return
	end
	State.SetPurchases(state)
end

local COMPANION_PASS = "CompanionSlot4" -- the data/Shop pass row that adds Companions.PassSlots (the server reads the same id)
-- Companion slots the player has right now, as the server counts them: the base (Config.CompanionSlots), plus the
-- slots Companion Tokens unlocked (profile.companionSlots), plus the pass's while it is owned, capped at
-- Companions.MaxSlots. The server judges every follow against its own count; this one only labels the screen.
function State.GetCompanionSlots(): number
	local p = profile
	local slots = Config.CompanionSlots + (if p then p.companionSlots else 0)
	if purchases.passes[COMPANION_PASS] then
		slots += Companions.PassSlots
	end
	return math.min(slots, Companions.MaxSlots)
end

-- The uid of the follower the local player rides, as the server last said (CompanionsChanged); nil on foot. The
-- Aliens screen labels the ridden card and its Ride button from it; the server alone decides who may ride.
function State.GetRiding(): string?
	return riding
end

-- The shared luck someone bought (nil when none runs) and the seconds since the server said so, so a
-- banner can count down between pushes.
function State.GetServerLuck(): (Types.ServerLuckState, number)
	local elapsed = if serverLuckAt > 0 then math.max(0, Workspace:GetServerTimeNow() - serverLuckAt) else 0
	return serverLuck, elapsed
end

-- Tutorial step (TutorialChanged) and the count toward a counted step.
function State.GetTutorial(): (number, number)
	local p = profile
	if p then
		return p.tutorialStep, p.tutorialCounter
	end
	return 1, 0
end

-- Field Notes step per world and objective counts (QuestsChanged); also readable from the profile.
function State.GetQuests(): Types.QuestState
	local p = profile
	if p then
		return { fieldNotes = p.quests.fieldNotes, progress = p.quests.progress }
	end
	return { fieldNotes = {}, progress = {} }
end

-- Applies a daily/weekly quest snapshot (GetDailyQuests result or a DailyQuestsChanged push): the two
-- period tables go into the profile mirror, the reset instants are remembered, and "quests" fires.
function State.SetDailyQuests(snapshot: DailyQuestsSnapshot)
	dailyResetsAt = snapshot.dailyResetsAt
	weeklyResetsAt = snapshot.weeklyResetsAt
	local p = profile
	if p then
		p.quests.daily = snapshot.daily
		p.quests.weekly = snapshot.weekly
	end
	fire("quests")
end

-- When the daily and the weekly set roll over, on the server wall clock (compare with State.Now()).
function State.GetQuestResets(): (number, number)
	return dailyResetsAt, weeklyResetsAt
end

-- Active power-ups as end times on the server wall clock; compare with State.Now().
function State.GetBuffs(): { [string]: number }
	return buffs
end

-- The current Peddler visit, or nil between visits.
function State.GetPeddler(): Types.PeddlerVisit?
	return peddler
end

function State.GetLuck(): number
	return luck
end

-- Friends in this server and the Friend Boost they give (a fraction), as the server last said.
function State.SetFriends(count: number, boost: number)
	friendCount = count
	friendBoost = boost
	fire("friends")
end

function State.GetFriends(): (number, number)
	return friendCount, friendBoost
end

-- Mirrors the server's codex write for a catch the server just confirmed (the CaptureHit result is
-- authoritative; this only keeps the local copy current until the next full profile).
function State.ApplyCatch(species: string, overlay: Types.Overlay)
	local p = profile
	if not p then
		return
	end
	local entry = p.codex[species]
	if not entry then
		entry = { count = 0, bestOverlay = "None", firstCaughtAt = 0 }
		p.codex[species] = entry
	end
	if entry.count == 0 then
		entry.firstCaughtAt = Workspace:GetServerTimeNow()
	end
	entry.count += 1
	local rank = table.find(Overlays.Order, overlay) or 0
	local bestRank = table.find(Overlays.Order, entry.bestOverlay) or 0
	if rank > bestRank then
		entry.bestOverlay = overlay
	end
	fire("codex")
end

-- Server-synced wall clock, comparable with ModuleProgress.updatedAt (os.time() on the server).
function State.Now(): number
	return Workspace:GetServerTimeNow()
end

function State.OnChanged(topic: Topic, fn: () -> ()): RBXScriptConnection
	return changed.Event:Connect(function(fired: Topic)
		if fired == topic or fired == "profile" then
			fn()
		end
	end)
end

-- Connects the server pushes. Each wait runs in its own thread so a remote the server has not
-- created yet never blocks the others.
function State.Start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		Net.event("ScrapChanged").OnClientEvent:Connect(function(scrap: number)
			if profile then
				profile.scrap = scrap
				fire("scrap")
			end
		end)
	end)
	task.spawn(function()
		Net.event("StationsChanged").OnClientEvent:Connect(function(stations: { [string]: Types.StationState }, aliens: { [string]: Types.AlienRecord })
			if profile then
				profile.stations = stations
				profile.aliens = aliens
				fire("stations")
			end
		end)
	end)
	task.spawn(function()
		Net.event("WorldChanged").OnClientEvent:Connect(function(current: number, unlocked: { number })
			if profile then
				profile.world.current = current
				profile.world.unlocked = unlocked
				fire("world")
			end
		end)
		Net.event("ModulesChanged").OnClientEvent:Connect(function(worldId: number, modules: { [string]: Types.ModuleProgress })
			if profile then
				profile.modules[tostring(worldId)] = modules
				fire("modules")
			end
		end)
	end)
	task.spawn(function()
		Net.event("InventoryChanged").OnClientEvent:Connect(function(inventory: { keyMaterials: { [string]: number }, lures: { [string]: number }, powerUps: { [string]: number }, items: { [string]: number } })
			if profile then
				profile.inventory = inventory
				fire("inventory")
			end
		end)
	end)
	task.spawn(function()
		Net.event("GearChanged").OnClientEvent:Connect(function(gear: { boots: boolean, hoverboard: boolean, glider: boolean, radar: number })
			if profile then
				profile.gear = gear
				fire("gear")
			end
		end)
	end)
	task.spawn(function()
		-- BuffsChanged carries seconds remaining per active power-up; stored as end times so the client
		-- can count down between pushes with State.Now().
		Net.event("BuffsChanged").OnClientEvent:Connect(function(remaining: { [string]: number })
			local now = Workspace:GetServerTimeNow()
			local next: { [string]: number } = {}
			for id, seconds in pairs(remaining) do
				next[id] = now + seconds
			end
			buffs = next
			fire("buffs")
		end)
	end)
	task.spawn(function()
		Net.event("PeddlerChanged").OnClientEvent:Connect(function(visit: Types.PeddlerVisit?)
			peddler = visit
			fire("peddler")
		end)
	end)
	task.spawn(function()
		Net.event("GiftsChanged").OnClientEvent:Connect(function(state: Types.GiftState)
			gifts = state
			if profile then
				profile.gifts.daysPlayed = state.daysPlayed
				profile.gifts.claimed = state.claimed
				profile.spins.free = state.freeSpins
				profile.spins.banked = state.bankedSpins
			end
			fire("gifts")
		end)
	end)
	task.spawn(function()
		Net.event("ShowerChanged").OnClientEvent:Connect(function(state: Types.ShowerState)
			shower = state
			showerAt = Workspace:GetServerTimeNow()
			fire("shower")
		end)
	end)
	task.spawn(function()
		Net.event("CatchRushChanged").OnClientEvent:Connect(function(state: Types.CatchRushState)
			rush = state
			rushAt = Workspace:GetServerTimeNow()
			fire("rush")
		end)
	end)
	task.spawn(function()
		Net.event("TutorialChanged").OnClientEvent:Connect(function(step: number, counter: number)
			if profile then
				profile.tutorialStep = step
				profile.tutorialCounter = counter
				fire("tutorial")
			end
		end)
	end)
	task.spawn(function()
		Net.event("QuestsChanged").OnClientEvent:Connect(function(state: Types.QuestState)
			if profile then
				profile.quests.fieldNotes = state.fieldNotes
				profile.quests.progress = state.progress
				fire("quests")
			end
		end)
	end)
	task.spawn(function()
		Net.event("LuckChanged").OnClientEvent:Connect(function(value: number)
			luck = value
			fire("luck")
		end)
	end)
	task.spawn(function()
		Net.event("SettingsChanged").OnClientEvent:Connect(function(state: Types.SettingsState)
			settings = settingsWithDefaults(state)
			if profile then
				profile.settings = settings
			end
			fire("settings")
		end)
	end)
	task.spawn(function()
		Net.event("RateChanged").OnClientEvent:Connect(function(state: Types.CampState)
			rate = state
			ratePushed = true
			fire("rate")
		end)
	end)
	task.spawn(function()
		Net.event("PurchasesChanged").OnClientEvent:Connect(function(state: Types.PurchasesState)
			State.SetPurchases(state)
		end)
	end)
	task.spawn(function()
		Net.event("ServerLuckChanged").OnClientEvent:Connect(function(state: Types.ServerLuckState)
			serverLuck = state
			serverLuckAt = Workspace:GetServerTimeNow()
			fire("serverLuck")
		end)
	end)
	task.spawn(function()
		-- Every client gets every player's followers; only the local player's own list is kept here (the
		-- companion renderer draws everyone's from the same push). The rows' order is the slot order. The push
		-- also names the uid the owner rides (nil on foot), kept the same way.
		Net.event("CompanionsChanged").OnClientEvent:Connect(function(snapshot: Types.CompanionsSnapshot)
			if profile and snapshot.userId == Players.LocalPlayer.UserId then
				local uids: { string } = {}
				for _, row in ipairs(snapshot.rows) do
					table.insert(uids, row.uid)
				end
				profile.companions = uids
				riding = snapshot.riding
				fire("companions")
			end
		end)
	end)
end

return State
