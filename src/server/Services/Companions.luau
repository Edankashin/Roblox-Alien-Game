--!strict
-- ServerScriptService.Server.Services.Companions: the aliens that follow a player (data/Companions). A
-- companion is a resting record whose uid sits in profile.companions, in slot order; it is never seated at a
-- station (Economy skips those uids when seating) and it gives one small perk while it follows, by its first
-- job and tier. This service owns the list: the slot count, follow and unfollow, the Companion Token, the
-- perk sums Buffs reads, and the snapshot every client draws the followers from (CompanionsChanged to all
-- clients on any change, GetAllCompanions for a late joiner). The client renders; it never decides who follows.
-- Riding (data/Mounts): one follower whose species has a `ride` trait can be ridden by its owner. Which uid is
-- ridden is runtime state by UserId, never saved (a rejoin is on foot): SetMount (remote) and SetRiding set it,
-- Riding reads it for Shop (speed, jump, hips), and the snapshot carries it as `riding` while that uid is in the
-- rows. When the ridden uid stops being a follower (a fusion consumed it, the owner unfollowed it) Push and
-- SetFollowing clear the entry and tell the OnChanged listeners, so the rider is dropped to the ground at once.
-- Slots: Config.CompanionSlots, plus PassSlots with the CompanionSlot4 pass, plus profile.companionSlots (one
-- TokenSlots per token used), capped at MaxSlots. Perks: the sum over followers of PerkByJob[first job].amount
-- times TierFactor[tier], per kind, capped by PerkCap[kind].
-- A uid whose record is gone (fused away, old data) is dropped from the list whenever the list is read for a
-- change or a snapshot, so it self-heals. Requires only PlayerData, Analytics, Monetization and shared modules,
-- so Buffs and Economy can require it; it never requires either back. Buffs registers its luck push
-- through Companions.OnChanged at Init.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Species = require(Shared.data.Species)
local CompanionsData = require(Shared.data.Companions)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Monetization = require(script.Parent.Monetization)

local Companions = {}

local REMOTE_RATE_PER_SECOND = 4 -- SetCompanion, UseCompanionToken and SetMount calls per player per second
local PASS_ID = "CompanionSlot4" -- the Shop.luau pass row that adds PassSlots
local UNKNOWN_SPECIES = "Unknown" -- the analytics species field when the record is already gone
local UNKNOWN_TRAVERSAL = "Unknown" -- the analytics traversal field when the record is already gone

local listeners: { (Player) -> () } = {} -- Buffs: re-send luck and buffs when a list changes; Shop: re-apply movement
local riding: { [number]: string } = {} -- UserId -> the uid that player rides (runtime only, never saved)

-- Helpers ----------------------------------------------------------------

-- Drops every uid from the list whose record no longer exists. Runs inside PlayerData.Update. True when any went.
local function prune(profile: Types.Profile): boolean
	local dropped = false
	for index = #profile.companions, 1, -1 do
		if not profile.aliens[profile.companions[index]] then
			table.remove(profile.companions, index)
			dropped = true
		end
	end
	return dropped
end

-- True when the uid is a follower whose record still exists.
local function isFollower(profile: Types.Profile, uid: string): boolean
	return profile.aliens[uid] ~= nil and table.find(profile.companions, uid) ~= nil
end

-- Forgets the ridden uid when it is no longer a follower (fused away, unfollowed). True when an entry went.
local function dropStaleRiding(player: Player, profile: Types.Profile): boolean
	local uid = riding[player.UserId]
	if uid ~= nil and not isFollower(profile, uid) then
		riding[player.UserId] = nil
		return true
	end
	return false
end

-- The owner's snapshot as every client draws it. Prunes stale uids first (one Update, only when needed).
local function snapshotOf(player: Player, profile: Types.Profile): Types.CompanionsSnapshot
	local stale = false
	for _, uid in ipairs(profile.companions) do
		if not profile.aliens[uid] then
			stale = true
			break
		end
	end
	if stale then
		PlayerData.Update(player, prune)
	end
	local rows: { Types.CompanionRow } = {}
	local ridden = riding[player.UserId]
	local carried: string? = nil -- the ridden uid, only while it is one of the rows
	for _, uid in ipairs(profile.companions) do
		local record = profile.aliens[uid]
		if record then
			if uid == ridden then
				carried = uid
			end
			table.insert(rows, {
				uid = record.uid,
				species = record.species,
				size = record.size,
				overlay = record.overlay,
				level = record.level,
				workedSeconds = record.workedSeconds,
			})
		end
	end
	return { userId = player.UserId, rows = rows, riding = carried }
end

local function broadcast(player: Player, profile: Types.Profile)
	Net.event("CompanionsChanged"):FireAllClients(snapshotOf(player, profile))
end

-- Query API --------------------------------------------------------------

-- Slots this player can use right now: the base, plus the pass, plus token slots, capped at MaxSlots.
function Companions.SlotCount(player: Player, profile: Types.Profile): number
	local slots = Config.CompanionSlots + profile.companionSlots
	if Monetization.OwnsPass(player, PASS_ID) then
		slots += CompanionsData.PassSlots
	end
	return math.min(slots, CompanionsData.MaxSlots)
end

-- The summed perk of one kind (catchScrap, zone, luck, radar) across this player's followers, capped by
-- PerkCap[kind]; 0 without a profile. A follower whose record or species is gone adds nothing.
function Companions.Perk(player: Player, kind: string): number
	local profile = PlayerData.Get(player)
	if not profile then
		return 0
	end
	local total = 0
	for _, uid in ipairs(profile.companions) do
		local record = profile.aliens[uid]
		local def = if record then Species.ById[record.species] else nil
		local firstJob = if def then def.jobs[1] else nil
		if def and firstJob then
			local perk = CompanionsData.PerkByJob[firstJob.job]
			local factor = CompanionsData.TierFactor[def.tier]
			if perk and factor and perk.kind == kind then
				total += perk.amount * factor
			end
		end
	end
	local cap = CompanionsData.PerkCap[kind]
	if cap then
		return math.min(total, cap)
	end
	return total
end

-- The uid this player rides and its species def, when that uid is still a follower whose species has a `ride`
-- trait; otherwise nil, and a stale entry is forgotten (the caller reads the new state, no push here).
function Companions.Riding(player: Player): (string?, Types.SpeciesDef?)
	local uid = riding[player.UserId]
	if uid == nil then
		return nil, nil
	end
	local profile = PlayerData.Get(player)
	local record = if profile and isFollower(profile, uid) then profile.aliens[uid] else nil
	local def = if record then Species.ById[record.species] else nil
	if def and def.ride then
		return uid, def
	end
	riding[player.UserId] = nil
	return nil, nil
end

-- Server-side hook: `callback` runs with the owner after their list or their mount changes (Buffs re-sends
-- luck, Shop re-applies movement).
function Companions.OnChanged(callback: (Player) -> ())
	table.insert(listeners, callback)
end

-- Re-sends this player's snapshot to every client and tells the OnChanged listeners. Economy calls it when a
-- fusion changed a follower (a consumed copy dropped, or the kept copy gained a level).
function Companions.Push(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	dropStaleRiding(player, profile) -- a fusion that consumed the mount ends the ride in this same push
	broadcast(player, profile)
	for _, callback in ipairs(listeners) do
		callback(player)
	end
end

-- Follow and unfollow -----------------------------------------------------

-- Follow appends the uid to the list; unfollow removes it. Idempotent: following a follower, or unfollowing
-- a non-follower the player owns, succeeds and changes nothing. Reasons: NoProfile, NotOwned (no such record),
-- Displayed (the record is on display in a home habitat; take it off display first), Seated (the record has a
-- station), Full (no free slot). Validation of the arguments and the rate limit are
-- the remote's; Dev calls this directly.
function Companions.SetFollowing(player: Player, uid: string, follow: boolean): (boolean, string?)
	local reason: string? = nil
	local changed = false
	local species = UNKNOWN_SPECIES
	local ok = PlayerData.Update(player, function(profile)
		prune(profile)
		local record = profile.aliens[uid]
		if record then
			species = record.species
		end
		local at = table.find(profile.companions, uid)
		if not follow then
			if at then
				table.remove(profile.companions, at)
				changed = true
			elseif not record then
				reason = "NotOwned"
			end
			return
		end
		if not record then
			reason = "NotOwned"
			return
		end
		if at then
			return
		end
		if record.habitat ~= nil then
			reason = "Displayed"
			return
		end
		if record.station ~= nil then
			reason = "Seated"
			return
		end
		if #profile.companions >= Companions.SlotCount(player, profile) then
			reason = "Full"
			return
		end
		table.insert(profile.companions, uid)
		changed = true
	end)
	if not ok then
		return false, "NoProfile"
	end
	if reason then
		return false, reason
	end
	-- An unfollowed mount (or one the prune dropped) ends the ride; that counts as a change for the listeners.
	local profile = PlayerData.Get(player)
	local dismounted = if profile then dropStaleRiding(player, profile) else false
	if changed then
		Analytics.Event(player, AnalyticsData.Events.Companion, 1, { action = if follow then "follow" else "unfollow", species = species })
	end
	if changed or dismounted then
		Companions.Push(player)
	end
	return true, nil
end

-- Riding ------------------------------------------------------------------

-- Mounts the follower with this uid, or dismounts with nil (ok even on foot). The same uid again is ok and
-- changes nothing; another uid swaps the mount. Reasons: NoProfile, NotFollowing (not in the list after the
-- prune), NotRideable (its species has no `ride`). Validation of the argument and the rate limit are the
-- remote's; Dev calls this directly. A change logs the Mount event, then pushes the snapshot.
function Companions.SetRiding(player: Player, uid: string?): (boolean, string?)
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local current = riding[player.UserId]
	local species = UNKNOWN_SPECIES
	local traversal = UNKNOWN_TRAVERSAL
	if uid == nil then
		if current == nil then
			return true, nil
		end
		local record = profile.aliens[current]
		local def = if record then Species.ById[record.species] else nil
		if def then
			species = def.id
			traversal = def.ride or UNKNOWN_TRAVERSAL
		end
		riding[player.UserId] = nil
		Analytics.Event(player, AnalyticsData.Events.Mount, 1, { action = "dismount", species = species, traversal = traversal })
		Companions.Push(player)
		return true, nil
	end
	PlayerData.Update(player, prune)
	local record = profile.aliens[uid]
	if not record or not table.find(profile.companions, uid) then
		return false, "NotFollowing"
	end
	local def = Species.ById[record.species]
	if not def or not def.ride then
		return false, "NotRideable"
	end
	if current == uid then
		return true, nil
	end
	riding[player.UserId] = uid
	traversal = def.ride
	Analytics.Event(player, AnalyticsData.Events.Mount, 1, { action = "mount", species = def.id, traversal = traversal })
	Companions.Push(player)
	return true, nil
end

-- Spends one Companion Token for TokenSlots more slots. Reasons: NoProfile, NoToken, MaxSlots (the total is
-- already at MaxSlots, so the token is kept).
function Companions.UseToken(player: Player): (boolean, string?)
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	local reason: string? = nil
	PlayerData.Update(player, function(p)
		local held = p.inventory.items[CompanionsData.TokenItem] or 0
		if held <= 0 then
			reason = "NoToken"
			return
		end
		if Companions.SlotCount(player, p) >= CompanionsData.MaxSlots then
			reason = "MaxSlots"
			return
		end
		p.inventory.items[CompanionsData.TokenItem] = held - 1
		p.companionSlots += CompanionsData.TokenSlots
	end)
	if reason then
		return false, reason
	end
	Net.event("InventoryChanged"):FireClient(player, profile.inventory)
	Analytics.Event(player, AnalyticsData.Events.Companion, 1, { action = "token" })
	return true, nil
end

-- Remotes ----------------------------------------------------------------

-- SetCompanion(uid, follow) -> (ok, reason). Reasons: BadArgs, RateLimited, NoProfile, NotOwned, Displayed, Seated, Full.
local function onSetCompanion(player: Player, uid: any, follow: any): (boolean, string?)
	if type(uid) ~= "string" or type(follow) ~= "boolean" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "SetCompanion", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return Companions.SetFollowing(player, uid, follow)
end

-- SetMount(uid) -> (ok, reason): uid is the follower to ride, or nil to get off. Reasons: BadArgs, RateLimited,
-- NoProfile, NotFollowing, NotRideable.
local function onSetMount(player: Player, uid: any): (boolean, string?)
	if uid ~= nil and type(uid) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "SetMount", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return Companions.SetRiding(player, uid)
end

-- UseCompanionToken() -> (ok, reason). Reasons: RateLimited, NoProfile, NoToken, MaxSlots.
local function onUseCompanionToken(player: Player): (boolean, string?)
	if not Net.allow(player, "UseCompanionToken", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	return Companions.UseToken(player)
end

-- GetAllCompanions() -> one snapshot per player whose profile is loaded, for a client that joined late.
local function onGetAllCompanions(_player: Player): { Types.CompanionsSnapshot }
	local all: { Types.CompanionsSnapshot } = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.Get(other)
		if profile then
			table.insert(all, snapshotOf(other, profile))
		end
	end
	return all
end

-- Public API -------------------------------------------------------------

function Companions.Init()
	for _, name in ipairs({ "CompanionsChanged", "InventoryChanged" }) do
		Net.event(name)
	end
	Net.func("SetCompanion").OnServerInvoke = onSetCompanion
	Net.func("UseCompanionToken").OnServerInvoke = onUseCompanionToken
	Net.func("SetMount").OnServerInvoke = onSetMount
	Net.func("GetAllCompanions").OnServerInvoke = onGetAllCompanions
	-- The owner's followers reach every client as soon as the profile loads (a client that is not listening
	-- yet gets them from GetAllCompanions).
	PlayerData.OnLoaded(function(player: Player, profile: Types.Profile)
		broadcast(player, profile)
	end)
end

function Companions.Start()
	-- An empty snapshot on leave, so every client clears that player's followers.
	Players.PlayerRemoving:Connect(function(player: Player)
		riding[player.UserId] = nil
		local empty: Types.CompanionsSnapshot = { userId = player.UserId, rows = {} }
		Net.event("CompanionsChanged"):FireAllClients(empty)
	end)
	print(("[%s] Companions: base %d slots, up to %d"):format(Config.WorkingTitle, Config.CompanionSlots, CompanionsData.MaxSlots))
end

return Companions
