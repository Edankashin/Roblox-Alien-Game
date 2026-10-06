--!strict
-- ServerScriptService.Server.Services.Mail: the mailbox on the home planet (docs/GAME_DESIGN.md section 10;
-- Shared/data/Mail has the numbers). A letter is a MailItem in profile.home.mail (newest last): who sent it, one
-- line, Social-style rewards and when. Mail.Send writes one, cuts the line to TextMaxChars, drops the oldest
-- letter unread while more than MaxLetters wait, and pushes MailChanged. Mail.Claim pays a letter's rewards through
-- Gifts.GrantRewards (Scrap, lures, power-ups, spins) and removes the letter. Mail.Visited writes the Visitor Book
-- (profile.home.visitors, newest last, MaxVisitors names); 42e calls it, nothing here does.
--
-- The claim cannot pay twice: the letter comes out of profile.home.mail FIRST, in its own PlayerData.Update, and
-- only then are its rewards granted. A second ClaimMail for the same uid, however it interleaves, finds no letter
-- and answers Unknown. Gifts.GrantRewards answers false only before it has written anything (no loaded profile),
-- and then the letter goes back to the place it was taken from, so a refused claim loses nothing. Nothing here
-- yields between taking the letter and the grant, so a save cannot catch the half-way state. (The other order, grant
-- then remove, would pay twice the moment anything between the two steps yielded.) If the grant itself threw, the
-- letter would be lost rather than paid twice: the safer failure for a gift.
--
-- Economy reporting: Gifts.GrantRewards pushes Scrap, the inventory and the spin balance but reports no Economy
-- source of its own, so a claim reports the letter's Scrap part here under the Mail source. The client opens the
-- mailbox with GetMail (the letters and the Visitor Book) and claims with ClaimMail(uid) -> (ok, reason); every
-- server-side change after that arrives as MailChanged (the letters). MailArrived (no arguments; fired by the
-- developer panel's mail verb in Admin) tells every client to toast that a letter came. Requires PlayerData, Gifts,
-- Analytics and Net; Admin and Dev call it, nothing it requires requires it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local MailData = require(Shared.data.Mail)
local AnalyticsData = require(Shared.data.Analytics)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local Gifts = require(script.Parent.Gifts)
local Analytics = require(script.Parent.Analytics)

local Mail = {}

export type MailState = { mail: { Types.MailItem }, visitors: { Types.Visitor } }

local function log(message: string)
	print(("[%s] Mail: %s"):format(Config.WorkingTitle, message))
end

-- At most `max` characters (not bytes, so a multi-byte character is never split).
local function cutChars(text: string, max: number): string
	local limit = utf8.offset(text, max + 1)
	if limit then
		return string.sub(text, 1, limit - 1)
	end
	return text
end

-- A copy of the reward rows, so a letter never shares a table with its sender (Admin sends the same rows to
-- every player).
local function copyRewards(rewards: { Types.SocialReward }): { Types.SocialReward }
	local out: { Types.SocialReward } = {}
	for _, row in ipairs(rewards) do
		table.insert(out, { kind = row.kind, id = row.id, amount = row.amount })
	end
	return out
end

local function pushMail(player: Player, profile: Types.Profile)
	Net.event("MailChanged"):FireClient(player, profile.home.mail)
end

-- Public API -------------------------------------------------------------

-- Puts a letter in the player's mailbox: `from` is shown as is, `text` is cut to MailData.TextMaxChars, the
-- rewards are copied. The oldest letters go while more than MailData.MaxLetters wait. Returns false when the
-- player has no loaded profile (nothing is written).
function Mail.Send(player: Player, from: string, text: string, rewards: { Types.SocialReward }): boolean
	local letter: Types.MailItem = {
		uid = HttpService:GenerateGUID(false),
		from = from,
		text = cutChars(text, MailData.TextMaxChars),
		rewards = copyRewards(rewards),
		sentAt = os.time(),
	}
	local waiting = 0
	local ok = PlayerData.Update(player, function(profile)
		table.insert(profile.home.mail, letter)
		while #profile.home.mail > MailData.MaxLetters do
			table.remove(profile.home.mail, 1)
		end
		waiting = #profile.home.mail
	end)
	if not ok then
		return false
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushMail(player, profile)
	end
	log(("letter from %s to %s (%d waiting)"):format(from, player.Name, waiting))
	return true
end

-- Pays the letter with this uid and removes it. Returns true, or false with a reason: NoProfile, Unknown (no such
-- letter: a wrong uid, or one already claimed), Failed (Gifts refused the rewards; the letter stays where it was).
-- The order is in the header: remove first, then grant, put it back if the grant is refused.
function Mail.Claim(player: Player, uid: string): (boolean, string?)
	if not PlayerData.Get(player) then
		return false, "NoProfile"
	end
	local taken: { letter: Types.MailItem?, index: number } = { letter = nil, index = 0 }
	PlayerData.Update(player, function(profile)
		for index, item in ipairs(profile.home.mail) do
			if item.uid == uid then
				taken.letter = table.remove(profile.home.mail, index)
				taken.index = index
				break
			end
		end
	end)
	local letter = taken.letter
	if not letter then
		return false, "Unknown"
	end
	if not Gifts.GrantRewards(player, letter.rewards) then
		PlayerData.Update(player, function(profile)
			table.insert(profile.home.mail, math.min(taken.index, #profile.home.mail + 1), letter)
		end)
		return false, "Failed"
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushMail(player, profile)
	end
	Analytics.Event(player, AnalyticsData.Events.MailClaim, 1, { from = letter.from })
	local scrap = 0
	for _, reward in ipairs(letter.rewards) do
		if reward.kind == "scrap" then
			scrap += reward.amount
		end
	end
	if profile and scrap > 0 then
		Analytics.Economy(player, "Source", scrap, profile.scrap, "Gameplay", AnalyticsData.Economy.Sources.Mail)
	end
	log(("%s claimed a letter from %s"):format(player.Name, letter.from))
	return true, nil
end

-- Writes `visitorName` into the player's Visitor Book (newest last, the oldest names go past
-- MailData.MaxVisitors) and pushes MailChanged. 42e calls this when someone visits.
function Mail.Visited(player: Player, visitorName: string)
	local ok = PlayerData.Update(player, function(profile)
		table.insert(profile.home.visitors, { name = visitorName, at = os.time() })
		while #profile.home.visitors > MailData.MaxVisitors do
			table.remove(profile.home.visitors, 1)
		end
	end)
	local profile = PlayerData.Get(player)
	if ok and profile then
		pushMail(player, profile)
	end
end

-- Remotes ----------------------------------------------------------------

-- ClaimMail(uid) -> (ok, reason). Reasons: BadArgs, RateLimited, then Mail.Claim's.
local function onClaim(player: Player, uid: any): (boolean, string?)
	if type(uid) ~= "string" then
		return false, "BadArgs"
	end
	if not Net.allow(player, "ClaimMail", MailData.ClaimsPerSecond) then
		return false, "RateLimited"
	end
	return Mail.Claim(player, uid)
end

-- GetMail() -> { mail, visitors }: the letters and the Visitor Book, for a client that opens the mailbox after the
-- last MailChanged (empty before the profile loads or when rate limited; the next MailChanged fills it in).
local function onGetMail(player: Player): MailState
	if not Net.allow(player, "GetMail", MailData.ClaimsPerSecond) then
		return { mail = {}, visitors = {} }
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return { mail = {}, visitors = {} }
	end
	return { mail = profile.home.mail, visitors = profile.home.visitors }
end

function Mail.Init()
	Net.event("MailChanged")
	Net.event("MailArrived")
	Net.func("ClaimMail").OnServerInvoke = onClaim
	Net.func("GetMail").OnServerInvoke = onGetMail
end

function Mail.Start()
	log(("up to %d letters of %d characters, %d visitor names kept"):format(MailData.MaxLetters, MailData.TextMaxChars, MailData.MaxVisitors))
end

return Mail
