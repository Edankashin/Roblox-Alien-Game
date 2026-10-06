--!strict
-- ServerScriptService.Server.Services.Habitats: aliens on display in the home planet's habitats (GAME_DESIGN
-- section 10; data/Habitats has the numbers, data/HomeBuild the habitat rows with their worldId and capacity). A
-- resting alien of a habitat's world can be put on display in it at home: its record carries the habitat's item uid
-- (record.habitat), it is never seated and never follows while that is set (Economy skips it when seating,
-- Companions refuses to make it follow), and the client draws it roaming inside the habitat from the records.
-- Income is lazy, like an outpost: nothing ticks. SettleIncome pays the time since profile.home.habitatSettled,
-- capped at CollectCapSeconds, times the summed ScrapPerHourByTier of every displayed alien, floored, and moves the
-- clock to now; less than SettleMinSeconds since the last settle pays nothing and leaves the clock alone. It runs
-- when the profile loads at the home place (the load at the home place is also what a fly home ends in, so Launch
-- needs no call; OnArrivedHome is the same settle for a caller that wants it), and silently inside SetDisplay
-- before the displayed set changes, so a copy never earns for time before it was put on display or loses what it
-- earned before it came off (that silent payout only pushes the Scrap counter; the toast is the arrival's).
-- A habitat item that is no longer on the profile (removed, or wiped by a dev command) leaves its aliens with a
-- stale uid: Prune clears those, and runs inside every settle and every SetDisplay.
-- Server authority: the client sends a record uid and a habitat uid (SetDisplay) and nothing else. Requires
-- PlayerData, Analytics, Economy (PushCamp), Companions (a follower put on display is unfollowed first) and shared
-- data; Economy never requires this module back, and only the bootstrap's order and Dev touch it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Species = require(Shared.data.Species)
local HabitatsData = require(Shared.data.Habitats)
local HomeData = require(Shared.data.HomeBuild)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Economy = require(script.Parent.Economy)
local Companions = require(script.Parent.Companions)

local Habitats = {}

local pendingIncome: { [number]: number } = {} -- Scrap paid by the load-time settle, kept until the client claims it, by UserId

local REMOTE_RATE_PER_SECOND = 4 -- SetDisplay calls per player per second (the same as SetCompanion)
local SECONDS_PER_HOUR = 3600 -- the rates in data/Habitats are per hour: a unit conversion
local UNKNOWN_SPECIES = "Unknown" -- the analytics species field when the record is already gone

-- Helpers ----------------------------------------------------------------

-- Scrap per hour all displayed aliens pay together: the sum of ScrapPerHourByTier over every record that has a
-- habitat uid. Run it after Prune, so every uid counted is a habitat that still exists. A species or tier the
-- data no longer lists pays nothing.
local function hourlyRate(profile: Types.Profile): number
	local total = 0
	for _, record in pairs(profile.aliens) do
		if record.habitat ~= nil then
			local def = Species.ById[record.species]
			local rate = if def then HabitatsData.ScrapPerHourByTier[def.tier] else nil
			total += rate or 0
		end
	end
	return total
end

-- Inside an Update, after Prune: pays what the displayed aliens are owed up to `now` into profile.scrap and moves
-- the clock to now. Pays nothing and leaves the clock alone when fewer than SettleMinSeconds passed since the
-- last settle. Returns the Scrap paid (floored; a long idle stretch with nothing on display moves the clock and pays 0).
local function bank(profile: Types.Profile, now: number): number
	local elapsed = now - profile.home.habitatSettled
	if elapsed < HabitatsData.SettleMinSeconds then
		return 0
	end
	local seconds = math.clamp(elapsed, 0, HabitatsData.CollectCapSeconds)
	local owed = math.floor(seconds * hourlyRate(profile) / SECONDS_PER_HOUR)
	profile.scrap += owed
	profile.home.habitatSettled = now
	return owed
end

-- Tells the client the Scrap total changed and reports the payout to the economy dashboard.
local function reportPaid(player: Player, paid: number)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	Net.event("ScrapChanged"):FireClient(player, profile.scrap)
	Analytics.Economy(player, "Source", paid, profile.scrap, "Gameplay", AnalyticsData.Economy.Sources.Habitat)
end

-- Public API -------------------------------------------------------------

-- Inside PlayerData.Update: clears `habitat` on every record whose habitat item is no longer on the profile.
-- Returns true when any record changed (the caller pushes the camp).
function Habitats.Prune(profile: Types.Profile): boolean
	local changed = false
	for _, record in pairs(profile.aliens) do
		local at = record.habitat
		if at ~= nil and profile.home.items[at] == nil then
			record.habitat = nil
			changed = true
		end
	end
	return changed
end

-- Puts the record `uid` on display in the habitat item `habitatUid`, or takes it off display with nil (ok, and a
-- no-op, when it was not on display; allowed away from home). Returns true, or false with a reason: NoProfile,
-- NotAtHome (display only works at the home planet), NotOwned (no such record), NoHabitat (no placed item with that
-- uid, or it is not a habitat), WrongWorld (the species' world is not the habitat's worldId), Full (the habitat
-- already holds its capacity), Seated (the record has a station), or Companions' own refusal when the unfollow
-- fails. A follower is unfollowed first (a kid chose to display it); a refusal changes nothing, the unfollow
-- included. Putting a record where it already is succeeds and changes nothing; putting it in another habitat moves it.
function Habitats.SetDisplay(player: Player, uid: string, habitatUid: string?): (boolean, string?)
	if habitatUid ~= nil and not Place.IsHome() then
		return false, "NotAtHome"
	end
	local reason: string? = nil
	local changed = false
	local pruned = false
	local mustUnfollow = false -- the record follows the player: the checks passed, nothing is written until it stops
	local paid = 0
	local species = UNKNOWN_SPECIES
	local function attempt(profile: Types.Profile)
		reason = nil
		changed = false
		mustUnfollow = false
		paid = 0
		if Habitats.Prune(profile) then
			pruned = true
		end
		local record = profile.aliens[uid]
		if not record then
			reason = "NotOwned"
			return
		end
		species = record.species
		if habitatUid == nil then
			if record.habitat ~= nil then
				paid = bank(profile, os.time()) -- what it earned so far is paid before it leaves
				record.habitat = nil
				changed = true
			end
			return
		end
		local placed = profile.home.items[habitatUid]
		local row = if placed then HomeData.ById[placed.itemId] else nil
		if not row or row.kind ~= "habitat" then
			reason = "NoHabitat"
			return
		end
		local def = Species.ById[record.species]
		if not def or def.world ~= row.worldId then
			reason = "WrongWorld"
			return
		end
		if record.habitat == habitatUid then
			return
		end
		local inside = 0
		for _, other in pairs(profile.aliens) do
			if other.habitat == habitatUid then
				inside += 1
			end
		end
		if inside >= (row.capacity or 0) then
			reason = "Full"
			return
		end
		if record.station ~= nil then
			reason = "Seated"
			return
		end
		if table.find(profile.companions, uid) ~= nil then
			mustUnfollow = true
			return
		end
		paid = bank(profile, os.time()) -- the copies already there are paid up before the set changes
		record.habitat = habitatUid
		changed = true
	end
	if not PlayerData.Update(player, attempt) then
		return false, "NoProfile"
	end
	if mustUnfollow then
		local unfollowed, why = Companions.SetFollowing(player, uid, false)
		if not unfollowed then
			return false, why
		end
		if not PlayerData.Update(player, attempt) then
			return false, "NoProfile"
		end
	end
	if paid > 0 then
		reportPaid(player, paid)
	end
	if changed or pruned then
		Economy.PushCamp(player) -- the client draws the displayed aliens from the records
	end
	if reason then
		return false, reason
	end
	if changed then
		Analytics.Event(player, AnalyticsData.Events.Display, 1, { action = if habitatUid ~= nil then "on" else "off", species = species })
		print(("[%s] Habitats: %s %s %s"):format(
			Config.WorkingTitle,
			player.Name,
			if habitatUid ~= nil then "put on display" else "took off display",
			species
		))
	end
	return true, nil
end

-- Pays what the displayed aliens are owed since the last settle (see the header for the maths), moves the clock to
-- now, pushes ScrapChanged, reports the Habitat source and tells the client (HabitatIncome, the Scrap paid) when
-- the amount is above zero. Pays nothing and leaves the clock alone when fewer than SettleMinSeconds passed. Returns
-- the Scrap paid (0 without a profile).
-- `atLoad` marks the settle that runs as the profile loads: the client is not listening yet, so the amount is
-- also kept for ClaimHabitatIncome (the client asks once at boot, like the offline summary).
function Habitats.SettleIncome(player: Player, atLoad: boolean?): number
	local paid = 0
	local pruned = false
	local ok = PlayerData.Update(player, function(profile)
		pruned = Habitats.Prune(profile)
		paid = bank(profile, os.time())
	end)
	if not ok then
		return 0
	end
	if pruned then
		Economy.PushCamp(player)
	end
	if paid > 0 then
		reportPaid(player, paid)
		if atLoad then
			pendingIncome[player.UserId] = (pendingIncome[player.UserId] or 0) + paid
		end
		Net.event("HabitatIncome"):FireClient(player, paid)
		print(("[%s] Habitats: %s earned %d Scrap from the habitats"):format(Config.WorkingTitle, player.Name, paid))
	end
	return paid
end

-- The player has arrived at the home planet: settles the habitat income. The load at the home place calls this
-- (a fly home ends in that load, so Launch does not), and a second call right after pays nothing (under
-- SettleMinSeconds). Does nothing at any other place. Returns the Scrap paid.
function Habitats.OnArrivedHome(player: Player, atLoad: boolean?): number
	if not Place.IsHome() then
		return 0
	end
	return Habitats.SettleIncome(player, atLoad)
end

-- Remotes ----------------------------------------------------------------

-- SetDisplay(uid, habitatUid) -> (ok, reason): habitatUid is the habitat item to display in, or nil to take the
-- alien off display. Reasons: BadArgs, RateLimited, then Habitats.SetDisplay's.
local function onSetDisplay(player: Player, uid: any, habitatUid: any): (boolean, string?)
	if type(uid) ~= "string" or (habitatUid ~= nil and type(habitatUid) ~= "string") then
		return false, "BadArgs"
	end
	if not Net.allow(player, "SetDisplay", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return Habitats.SetDisplay(player, uid, habitatUid)
end

-- ClaimHabitatIncome() -> the Scrap the load-time settle paid and the client has not heard about yet (0 when none);
-- cleared once answered.
local function onClaimHabitatIncome(player: Player): number
	local pending = pendingIncome[player.UserId] or 0
	pendingIncome[player.UserId] = nil
	return pending
end

function Habitats.Init()
	Net.event("HabitatIncome")
	Net.event("ScrapChanged")
	Net.func("SetDisplay").OnServerInvoke = onSetDisplay
	Net.func("ClaimHabitatIncome").OnServerInvoke = onClaimHabitatIncome
	-- The arrival at the home place is the profile loading there; the other worlds never settle habitats.
	PlayerData.OnLoaded(function(player: Player, _profile: Types.Profile)
		Habitats.OnArrivedHome(player, true)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		pendingIncome[player.UserId] = nil
	end)
end

function Habitats.Start()
	print(("[%s] Habitats: up to %d hours of income owed, settled on arriving home"):format(
		Config.WorkingTitle,
		HabitatsData.CollectCapSeconds // SECONDS_PER_HOUR
	))
end

return Habitats
