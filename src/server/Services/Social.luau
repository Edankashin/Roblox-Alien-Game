--!strict
-- ServerScriptService.Server.Services.Social: the group gift, the referral rewards and the notifications ask
-- (docs/vault/01-game-design/Growth-Playbook.md sections 3 and 5; every number in Shared/data/Social).
-- Group: ClaimGroupReward checks Player:IsInGroupAsync on the server and pays Social.GroupReward once per
-- profile. Referral: on load the join data's ReferredByPlayerId pays the invitee once (profile.social) and
-- credits the inviter, who is paid per invitee up to a lifetime cap; an inviter who is in another server or
-- offline is credited through a small DataStore ("Social", key referrals_<UserId>) that their next load
-- drains. Notifications: the server only decides when the opt-in card may show (the NotifyAsk event); the
-- prompt itself is client-only (ExperienceNotificationService). Rewards are written through
-- Gifts.GrantRewards. Nothing here gates progress and a like or favorite is never rewarded.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local SocialData = require(Shared.data.Social)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)
local Gifts = require(script.Parent.Gifts)

local Social = {}

export type Snapshot = {
	groupId: number,
	inGroup: boolean,
	groupClaimed: boolean,
	referralsRewarded: number,
	referredBy: number,
}

local GET_RATE_PER_SECOND = 2 -- GetSocial calls per player per second
local CLAIM_RATE_PER_SECOND = 2 -- ClaimGroupReward calls per player per second
local ASK_RATE_PER_SECOND = 2 -- NotifyAskSeen calls per player per second
local STORE_NAME = "Social"
local BANK_KEY_PREFIX = "referrals_"

-- Whether each player is in the group, checked once per player per session by GetSocial; ClaimGroupReward
-- always asks again. Keyed by UserId and dropped on leave.
local inGroupCache: { [number]: boolean } = {}
local pendingInvitee: { [number]: boolean } = {} -- by UserId: the invitee toast waits for the client's first GetSocial (the load hook runs before the client listens)
local bankStore: DataStore? = nil

-- Group ---------------------------------------------------------------------

-- Player:IsInGroupAsync yields (Roblox caches it per peer) and can fail, so it runs in a pcall; nil means
-- the check failed and nothing is cached.
local function queryGroup(player: Player): boolean?
	local ok, result = pcall(function(): boolean
		return player:IsInGroupAsync(SocialData.GroupId)
	end)
	if not ok then
		warn(("[%s] Social: group check failed for %s: %s"):format(Config.WorkingTitle, player.Name, tostring(result)))
		return nil
	end
	return result == true
end

-- GetSocial's answer: the session cache, asking once on a miss. False for no group and for a failed check.
local function cachedInGroup(player: Player): boolean
	if SocialData.GroupId == 0 then
		return false
	end
	local cached = inGroupCache[player.UserId]
	if cached ~= nil then
		return cached
	end
	local fresh = queryGroup(player)
	if fresh == nil then
		return false
	end
	if player.Parent == Players then
		inGroupCache[player.UserId] = fresh
	end
	return fresh
end

-- Snapshot and pushes --------------------------------------------------------

-- Everything the Social screen shows. The group check runs first (it may yield) so the profile fields are
-- read afterwards, current as of the moment the snapshot is built.
local function buildSnapshot(player: Player): Snapshot?
	local inGroup = cachedInGroup(player)
	local profile = PlayerData.Get(player)
	if not profile then
		return nil
	end
	local social = profile.social
	return {
		groupId = SocialData.GroupId,
		inGroup = inGroup,
		groupClaimed = social.groupClaimed,
		referralsRewarded = social.referralsRewarded,
		referredBy = social.referredBy,
	}
end

-- SocialChanged(snapshot), pushed after any change. Built in its own thread so a caller on the load path or
-- inside a handler never waits on the first group check.
local function pushSocial(player: Player)
	task.spawn(function()
		local snapshot = buildSnapshot(player)
		if snapshot and player.Parent == Players then
			Net.event("SocialChanged"):FireClient(player, snapshot)
		end
	end)
end

-- Referral bank ---------------------------------------------------------------

local function getBankStore(): DataStore?
	if bankStore then
		return bankStore
	end
	local ok, result = pcall(function(): DataStore
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if not ok then
		warn(("[%s] Social: DataStore unavailable (%s); referral credits for offline inviters are skipped."):format(Config.WorkingTitle, tostring(result)))
		return nil
	end
	bankStore = result
	return result
end

local function bankKey(userId: number): string
	return BANK_KEY_PREFIX .. tostring(userId)
end

-- Adds `delta` credits to an inviter's bank. Skipped with a print on in-memory profiles (Studio without
-- API access), where there is nothing to bank into.
local function addToBank(inviterId: number, delta: number)
	if PlayerData.IsMemoryOnly() then
		print(("[%s] Social: memory-only profiles, referral credit for user %d not banked"):format(Config.WorkingTitle, inviterId))
		return
	end
	local store = getBankStore()
	if not store then
		return
	end
	local ok, err = pcall(function()
		store:UpdateAsync(bankKey(inviterId), function(old: any): any
			return (tonumber(old) or 0) + delta
		end)
	end)
	if not ok then
		warn(("[%s] Social: banking a referral credit for user %d failed: %s"):format(Config.WorkingTitle, inviterId, tostring(err)))
	end
end

-- Rewards -------------------------------------------------------------------

-- Pays the inviter ReferralInviter once per credit while the lifetime cap is not reached. Each credit counts
-- (referralsRewarded), pays, tells the client (ReferralGranted "inviter") and reports. Credits past the cap
-- are dropped. False when the player has no loaded profile (nothing is paid, so the caller can bank it).
-- The Scrap part of a social grant as an economy source (the lures and spins are items, not currency).
local function reportScrap(player: Player, rewards: { SocialData.Reward })
	local amount = 0
	for _, reward in ipairs(rewards) do
		if reward.kind == "scrap" then
			amount += reward.amount
		end
	end
	local live = PlayerData.Get(player)
	if amount > 0 and live then
		Analytics.Economy(player, "Source", amount, live.scrap, "Gameplay", AnalyticsData.Economy.Sources.Social)
	end
end

local function creditInviter(player: Player, count: number): boolean
	local profile = PlayerData.Get(player)
	if not profile then
		return false
	end
	local credits = math.max(0, math.floor(count))
	local paid = 0
	for _ = 1, credits do
		if profile.social.referralsRewarded >= SocialData.ReferralMaxRewarded then
			break
		end
		PlayerData.Update(player, function(p)
			p.social.referralsRewarded += 1
		end)
		Gifts.GrantRewards(player, SocialData.ReferralInviter)
		reportScrap(player, SocialData.ReferralInviter)
		Net.event("ReferralGranted"):FireClient(player, "inviter")
		Analytics.Event(player, AnalyticsData.Events.Referral, 1, { role = "inviter" })
		paid += 1
	end
	if paid > 0 then
		pushSocial(player)
	end
	return true
end

-- Hands the inviter their credit: at once when they are in this server with a loaded profile, else banked.
local function creditOrBank(inviterId: number)
	local inviter = Players:GetPlayerByUserId(inviterId)
	if inviter and creditInviter(inviter, 1) then
		return
	end
	addToBank(inviterId, 1)
end

-- Drains the player's own bank (read the count and set it to 0 in one UpdateAsync) and credits it. If they
-- left, or the profile is gone, before it could be paid, the credits go back into the bank.
local function collectBank(player: Player)
	if PlayerData.IsMemoryOnly() then
		return
	end
	local store = getBankStore()
	if not store then
		return
	end
	local count = 0
	local ok, err = pcall(function()
		store:UpdateAsync(bankKey(player.UserId), function(old: any): any
			count = math.max(0, math.floor(tonumber(old) or 0))
			if count == 0 then
				return nil -- nothing banked: cancel the write
			end
			return 0
		end)
	end)
	if not ok then
		warn(("[%s] Social: reading %s's referral bank failed: %s"):format(Config.WorkingTitle, player.Name, tostring(err)))
		return
	end
	if count > 0 and not (player.Parent == Players and creditInviter(player, count)) then
		addToBank(player.UserId, count)
	end
end

-- The inviter's UserId from the join data, or 0 when there is none (a plain join, or the call failed).
local function referrerId(player: Player): number
	local ok, data = pcall(function(): any
		return player:GetJoinData()
	end)
	if not ok or type(data) ~= "table" then
		return 0
	end
	local value: any = data.ReferredByPlayerId
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value <= 0 then
		return 0
	end
	return value
end

-- Join ----------------------------------------------------------------------

-- Runs on the live profile before the join payload is sent: counts the session, pays the invitee at once
-- (so the payload already holds it) and leaves everything that yields (the bank) to a thread of its own.
local function onLoaded(player: Player, profile: Types.Profile)
	local social = profile.social
	social.sessions += 1

	local inviterId = referrerId(player)
	local firstReferral = inviterId > 0 and inviterId ~= player.UserId and social.referredBy == 0 and not social.referralClaimed
	if firstReferral then
		social.referredBy = inviterId
		social.referralClaimed = true
		Gifts.GrantRewards(player, SocialData.ReferralInvitee)
		reportScrap(player, SocialData.ReferralInvitee)
		pendingInvitee[player.UserId] = true
		Analytics.Event(player, AnalyticsData.Events.Referral, 1, { role = "invitee" })
	end
	task.spawn(function()
		if firstReferral then
			creditOrBank(inviterId)
		end
		collectBank(player)
	end)

	-- The notifications card: never in the first session, only once per cooldown, only while the flag is on.
	if
		SocialData.NotificationsEnabled
		and social.sessions >= SocialData.NotifyAskMinSession
		and os.time() - social.notifyAskedAt >= SocialData.NotifyAskCooldownSeconds
	then
		task.delay(SocialData.NotifyAskAfterSeconds, function()
			if player.Parent == Players and PlayerData.Get(player) then
				Net.event("NotifyAsk"):FireClient(player)
			end
		end)
	end
end

-- Remotes -------------------------------------------------------------------

-- GetSocial() -> Snapshot?. nil when rate limited or before the profile loads.
local function onGetSocial(player: Player): Snapshot?
	if not Net.allow(player, "GetSocial", GET_RATE_PER_SECOND) then
		return nil
	end
	if pendingInvitee[player.UserId] then
		pendingInvitee[player.UserId] = nil
		Net.event("ReferralGranted"):FireClient(player, "invitee")
	end
	return buildSnapshot(player)
end

-- ClaimGroupReward() -> (ok, reason). Reasons: RateLimited, NoProfile, NoGroup (Social.GroupId is 0),
-- AlreadyClaimed, NotMember (IsInGroupAsync is false or failed). The membership is asked again on every
-- claim; the claim flag is set in the same step that re-checks it after that yield, so two calls in flight
-- pay once.
local function onClaimGroupReward(player: Player): (boolean, string?)
	if not Net.allow(player, "ClaimGroupReward", CLAIM_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false, "NoProfile"
	end
	if SocialData.GroupId == 0 then
		return false, "NoGroup"
	end
	if profile.social.groupClaimed then
		return false, "AlreadyClaimed"
	end
	local member = queryGroup(player)
	if player.Parent ~= Players then
		return false, "NoProfile"
	end
	if not member then
		-- Someone who left the group since the cache was filled: the screen hears it.
		if member == false and inGroupCache[player.UserId] == true then
			inGroupCache[player.UserId] = false
			pushSocial(player)
		end
		return false, "NotMember"
	end
	inGroupCache[player.UserId] = true
	local live = PlayerData.Get(player)
	if not live then
		return false, "NoProfile"
	end
	if live.social.groupClaimed then
		return false, "AlreadyClaimed"
	end
	live.social.groupClaimed = true
	Gifts.GrantRewards(player, SocialData.GroupReward)
	reportScrap(player, SocialData.GroupReward)
	Analytics.Event(player, AnalyticsData.Events.GroupReward)
	pushSocial(player)
	return true, nil
end

-- NotifyAskSeen(answer) -> boolean. The client reports what the player chose on the notifications card
-- ("yes" or "no", anything else counts as "no"); the card will not come back for the cooldown.
local function onNotifyAskSeen(player: Player, answer: any): boolean
	if not Net.allow(player, "NotifyAskSeen", ASK_RATE_PER_SECOND) then
		return false
	end
	local ok = PlayerData.Update(player, function(p)
		p.social.notifyAskedAt = os.time()
	end)
	if not ok then
		return false
	end
	local choice = if answer == "yes" then "yes" else "no"
	Analytics.Event(player, AnalyticsData.Events.NotifyAsk, 1, { answer = choice })
	pushSocial(player)
	return true
end

-- Public API -------------------------------------------------------------

-- Developer overrides (Studio commands, guarded by Dev): forget every social flag so the group gift, the
-- referral rewards and the notifications card can be tried again, and credit an inviter reward.
function Social.DevReset(player: Player)
	local ok = PlayerData.Update(player, function(p)
		p.social.groupClaimed = false
		p.social.referralClaimed = false
		p.social.referredBy = 0
		p.social.referralsRewarded = 0
		p.social.notifyAskedAt = 0
	end)
	if ok then
		pushSocial(player)
	end
end

function Social.DevCredit(player: Player, count: number)
	creditInviter(player, count)
end

function Social.Init()
	for _, name in ipairs({ "SocialChanged", "NotifyAsk", "ReferralGranted" }) do
		Net.event(name)
	end
	Net.func("GetSocial").OnServerInvoke = onGetSocial
	Net.func("ClaimGroupReward").OnServerInvoke = onClaimGroupReward
	Net.func("NotifyAskSeen").OnServerInvoke = onNotifyAskSeen
	PlayerData.OnLoaded(onLoaded)
	Players.PlayerRemoving:Connect(function(player: Player)
		inGroupCache[player.UserId] = nil
		pendingInvitee[player.UserId] = nil
	end)
end

function Social.Start() end

return Social
