--!strict
-- StarterPlayerScripts.Client.State: the client's mirror of its own profile. The server owns the real
-- one and pushes changes (ScrapChanged, StationsChanged, ModulesChanged, InventoryChanged, RateChanged,
-- SettingsChanged, PurchasesChanged, ServerLuckChanged, ShowerChanged, CatchRushChanged, CompanionsChanged,
-- WeeklyChanged, HomeChanged, MailChanged, HomeView);
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
local Place = require(Shared:WaitForChild("Place"))

local State = {}

-- The daily and weekly quest sets with the instants (server wall clock, os.time scale) each one rolls over.
export type DailyQuestsSnapshot = { daily: Types.PeriodQuests, weekly: Types.PeriodQuests, dailyResetsAt: number, weeklyResetsAt: number }

-- "profile" fires once when the whole profile arrives; every topic listener also runs then.
export type Topic = "scrap" | "stations" | "modules" | "inventory" | "gear" | "rate" | "clock" | "biome" | "codex" | "buffs" | "peddler" | "luck" | "quests" | "tutorial" | "gifts" | "shower" | "rush" | "settings" | "purchases" | "serverLuck" | "world" | "outposts" | "friends" | "companions" | "weekly" | "home" | "mail" | "visit" | "profile"

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
local weeklyOffset = 0 -- the Studio shift of the weekly rotation in whole weeks (WeeklyChanged, GetWeekly); 0 in play
local weeklyKnown = false -- the server has said it (a push or the GetWeekly answer)
local homePushed = false -- a HomeChanged push has landed, so a late GetHome answer is older and is dropped
local mailPushed = false -- a MailChanged push has landed, so a late GetMail answer's letters are older and are dropped
local homeView: Types.HomeView? = nil -- the home planet of someone else this client is looking at (HomeView, GetVisit); nil at your own home
local visitPushed = false -- a HomeView push has landed, so a late GetVisit answer is older and is dropped
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

-- The weekly rotation's shift as the server last said (WeeklyChanged, seeded by GetWeekly); 0 until it does and
-- in play. Pass it to WeeklyMath with State.Now() to find the Alien of the Week.
function State.GetWeeklyOffset(): number
	return weeklyOffset
end

-- Whether the server has said the offset yet, so a banner for the week waits for the real value.
function State.HasWeekly(): boolean
	return weeklyKnown
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

-- Visiting (milestone 42e) ----------------------------------------------------

-- The server's HomeView (a push, or the GetVisit answer): the home planet this client is looking at, or nil when
-- it looks at its own. A refresh of the same home carries the same ownerId. Fires "visit", on which the renderers
-- redraw and the bootstrap toasts the arrival and the return.
function State.SetHomeView(view: Types.HomeView?)
	homeView = view
	fire("visit")
end

function State.GetHomeView(): Types.HomeView?
	return homeView
end

-- Whether the client is looking at someone else's home (a view is set).
function State.IsVisiting(): boolean
	return homeView ~= nil
end

-- A guest is anyone not standing at their own camp: visiting a home, or in a place that is not the world their
-- ship is on (Studio's /world in the home place).
function State.IsGuest(): boolean
	if homeView ~= nil then
		return true
	end
	local p = profile
	return p ~= nil and Place.WorldId() ~= p.world.current
end

-- The house grid to draw: the viewed home's items while visiting, else the player's own.
function State.HomeItems(): { [string]: Types.HomeItem }
	local view = homeView
	if view then
		return view.items
	end
	local p = profile
	return if p then p.home.items else {}
end

-- The aliens on display to draw: the viewed home's while visiting, else every record of the player's own with a
-- habitat set (uid -> record).
function State.DisplayedAliens(): { [string]: Types.AlienRecord }
	local view = homeView
	if view then
		return view.displayed
	end
	local out: { [string]: Types.AlienRecord } = {}
	local p = profile
	if p then
		for uid, record in pairs(p.aliens) do
			if record.habitat ~= nil then
				out[uid] = record
			end
		end
	end
	return out
end

-- The worlds whose ship hulls stand in the hangar, ascending: the viewed home's while visiting, else the numeric
-- keys of the player's own outposts table.
function State.LaunchedWorlds(): { number }
	local view = homeView
	if view then
		return view.launchedWorlds
	end
	local ids: { number } = {}
	local p = profile
	if p then
		for key in pairs(p.world.outposts) do
			local id = tonumber(key)
			if id ~= nil then
				table.insert(ids, id)
			end
		end
	end
	table.sort(ids)
	return ids
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

-- One pull of the mailbox, seeded into the profile that is already in: the letters unless a push already landed
-- (it is newer and wins), and the visitors, which no push carries. A failed or malformed call leaves the profile's
-- own copy. Runs in its own thread: the boot pull, and State.RefreshVisitors.
local function pullMail()
	local ok, answer = pcall(function(): any
		return Net.func("GetMail"):InvokeServer()
	end)
	if not ok or type(answer) ~= "table" or not profile then
		return
	end
	local reply = answer :: { mail: { Types.MailItem }?, visitors: { Types.Visitor }? }
	local visitors = reply.visitors
	if type(visitors) == "table" then
		profile.home.visitors = visitors
	end
	local mail = reply.mail
	if not mailPushed and type(mail) == "table" then
		profile.home.mail = mail
	end
	fire("mail")
end

-- Asks the server for the Visitor Book again (a visitor just came in; no push carries the book, so the Mail screen
-- would show the old names until the next load). Fires "mail" when the answer lands.
function State.RefreshVisitors()
	task.spawn(pullMail)
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
	task.spawn(function()
		-- The weekly rotation's shift: a push whenever the week or the shift changes, and one pull for a
		-- client that joined after the last push (a push that already arrived is newer and wins).
		Net.event("WeeklyChanged").OnClientEvent:Connect(function(offset: number)
			weeklyOffset = offset
			weeklyKnown = true
			fire("weekly")
		end)
		local ok, answer = pcall(function(): any
			return Net.func("GetWeekly"):InvokeServer()
		end)
		if ok and not weeklyKnown and type(answer) == "number" then
			weeklyOffset = answer
			weeklyKnown = true
			fire("weekly")
		end
	end)
	task.spawn(function()
		-- The house grid (data/HomeBuild): every change the server accepts comes back as the whole item table
		-- (uid -> item), which replaces the profile's copy; the HomeRenderer and the Build screen redraw on "home".
		Net.event("HomeChanged").OnClientEvent:Connect(function(items: { [string]: Types.HomeItem })
			homePushed = true
			if profile then
				profile.home.items = items
				fire("home")
			end
		end)
	end)
	task.spawn(function()
		-- One pull for a client that joined after the last push, seeded into the profile that is already in; a push
		-- that arrived first is newer and wins. A failed call leaves the profile's own copy.
		local ok, answer = pcall(function(): any
			return Net.func("GetHome"):InvokeServer()
		end)
		if ok and not homePushed and type(answer) == "table" and profile then
			profile.home.items = answer :: { [string]: Types.HomeItem }
			fire("home")
		end
	end)
	task.spawn(function()
		-- The mailbox (data/Mail): every change to the letters comes back as the whole list (newest last), which
		-- replaces the profile's copy; the Mail screen redraws on "mail". The Visitor Book rides only the pull.
		Net.event("MailChanged").OnClientEvent:Connect(function(mail: { Types.MailItem })
			mailPushed = true
			if profile then
				profile.home.mail = mail
				fire("mail")
			end
		end)
	end)
	task.spawn(pullMail)
	task.spawn(function()
		-- The home someone else is viewing (HomeView): set, refreshed or cleared (nil) by the server. One pull for a
		-- client that joined after the last push (a teleported visitor, a rejoin); a push that already landed is newer
		-- and wins. nil answers (your own home) and failed calls change nothing.
		Net.event("HomeView").OnClientEvent:Connect(function(view: Types.HomeView?)
			visitPushed = true
			State.SetHomeView(view)
		end)
		local ok, answer = pcall(function(): any
			return Net.func("GetVisit"):InvokeServer()
		end)
		if ok and not visitPushed and type(answer) == "table" then
			State.SetHomeView(answer :: Types.HomeView)
		end
	end)
end

return State
