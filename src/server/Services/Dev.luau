--!strict
-- ServerScriptService.Server.Services.Dev: chat commands for testing, available only in Studio.
-- Typed in the chat box: /scrap 1000, /night, /day, /rain, /clear, /shower [end | in N], /rush [end | in N], /sighting [end], /days 7, /spins 3, /radar [N], /tutorial 6,
-- /buy StarterPack, /pass AutoOptimize [off], /world 2 (0 is the home planet), /complete (every module of this world done, so the launch
-- can be tested in minutes), /outpost 2 3 (world 2's outpost has 3 hours to collect), /social reset | credit N | ask
-- (forget the social flags, pay N inviter rewards, show the notifications card at once), /lb N | flush (N catches on the
-- weekly board through its per-minute cap; send them to the store now and refresh the board), /dq reset | done (deal the
-- daily and weekly quests again with empty progress; finish every dealt one), /variant <id|off> (force a catch
-- variant from Shared/data/CatchVariants on every encounter you start, or go back to each spawn's own), /grow [H]
-- (H hours, default 2, of worked time for every seated alien, so a growth stage can be crossed), /dupes <id> [N]
-- (N copies, default 5, of that species with no overlay, so a fusion can be tried in seconds), /token [N] (N
-- Companion Tokens, default 1, into the inventory), /follow <id> (your first resting copy of that species
-- follows you, if a slot is free), /ride <id|off> (ride a following copy of that species, or make your first
-- resting copy follow and ride it; off gets down), /week <N|next|off> (shift the weekly drop's rotation to
-- offset N, one week on, or back to the real week), /season <id|off|done> (force a seasonal event from Shared/data/Seasons on
-- with its whole window left, back to the calendar, or fill every row of the running event's quest track), /radar [N] (the radar up to tier N, 1 to 3, default 1, each tier
-- in order), /homeclear (empty the house grid, no refund), /habitat [H] (the habitat payout clock back H hours,
-- default 2, so the next arrival at the home planet pays) | settle (pay the habitats now, print the Scrap), /mail [N]
-- (N test letters, default 1, to your own mailbox; one more than the mailbox holds shows the oldest dropped), /visit
-- <name|id> (in the home place: look at another player's home in this server, as the Visit button does) | off (back to your
-- own home), /afk (rest now: the half-rate income and the Resting screen) | off (wake) | rejoin (the rejoin the client asks for
-- after 17 idle minutes; Studio only prints it), /playtime <minutes> (add that many minutes of played time today, so a playtime
-- gift unlocks at once; negative takes minutes back) | reset (today's played time and claims cleared), /storage fill [N] (N plain Common
-- records, default as many as fit, never past the storage cap) | cap (print the record count, the cap and its parts: base, modules,
-- Storage Bay, pass, hard cap) | bay <level> (set the Storage Bay level without paying, 0 to the last), /cinematic <momentId> (play one cinematic moment
-- from Shared/data/Cinematics now: Arrival_0, Arrival_1, Arrival_2 or Legendary) | reset (forget which first arrivals were
-- watched, so each plays again on the next join) | list (print the moments and the ones watched). Nothing
-- here exists in a live server, so none of it can be abused; the guard is RunService:IsStudio() at Init.

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local Quests = require(Shared.data.Quests)
local Net = require(Shared.Net)
local Place = require(Shared.Place)
local Economy = require(Shared.Economy)
local PlayerData = require(script.Parent.PlayerData)
local EconomyService = require(script.Parent.Economy)
local WorldClock = require(script.Parent.WorldClock)
local Events = require(script.Parent.Events)
local Sightings = require(script.Parent.Sightings)
local Weekly = require(script.Parent.Weekly)
local Seasons = require(script.Parent.Seasons)
local CatchRush = require(script.Parent.CatchRush)
local Gifts = require(script.Parent.Gifts)
local Social = require(script.Parent.Social)
local Leaderboard = require(script.Parent.Leaderboard)
local DailyQuests = require(script.Parent.DailyQuests)
local Shop = require(script.Parent.Shop)
local Outposts = require(script.Parent.Outposts)
local Tutorial = require(script.Parent.Tutorial)
local Spawner = require(script.Parent.Spawner)
local Catching = require(script.Parent.Catching)
local Monetization = require(script.Parent.Monetization)
local Companions = require(script.Parent.Companions)
local Habitats = require(script.Parent.Habitats)
local Mail = require(script.Parent.Mail)
local Visiting = require(script.Parent.Visiting)
local Afk = require(script.Parent.Afk)
local Playtime = require(script.Parent.Playtime)
local CompanionsData = require(Shared.data.Companions)
local Species = require(Shared.data.Species)
local Sizes = require(Shared.data.Sizes)
local Worlds = require(Shared.data.Worlds)
local Home = require(Shared.data.Home)
local MailData = require(Shared.data.Mail)
local CatchVariants = require(Shared.data.CatchVariants)
local SeasonsData = require(Shared.data.Seasons)
local SeasonMath = require(Shared.SeasonMath)
local StorageData = require(Shared.data.Storage)
local StorageMath = require(Shared.StorageMath)
local CinematicsData = require(Shared.data.Cinematics)
local Seen = require(script.Parent.Seen)

local Dev = {}

local enabled = false

local function playerFrom(source: TextSource?): Player?
	if not source then
		return nil
	end
	return Players:GetPlayerByUserId(source.UserId)
end

local function command(alias: string, onTriggered: (Player, string) -> ())
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "Dev" .. alias
	cmd.PrimaryAlias = "/" .. alias
	cmd.Triggered:Connect(function(source: TextSource, text: string)
		local player = playerFrom(source)
		if player then
			onTriggered(player, text)
		end
	end)
	cmd.Parent = folder
end

local function grantScrap(player: Player, text: string)
	local amount = tonumber(string.match(text, "%-?%d+") or "") or 0
	if amount == 0 then
		return
	end
	local scrap = 0
	local ok = PlayerData.Update(player, function(profile)
		profile.scrap = math.max(0, profile.scrap + amount)
		scrap = profile.scrap
	end)
	if ok then
		Net.event("ScrapChanged"):FireClient(player, scrap)
		print(("[%s] dev: %s now has %d Scrap"):format(Config.WorkingTitle, player.Name, scrap))
	end
end

-- /horn: hand over the Warden's Horn so the shrine can be tested without the four earlier steps.
local function grantHorn(player: Player)
	local inventory: any = nil
	local ok = PlayerData.Update(player, function(profile)
		profile.inventory.items[Quests.HornItem] = (profile.inventory.items[Quests.HornItem] or 0) + 1
		inventory = profile.inventory
	end)
	if ok then
		Net.event("InventoryChanged"):FireClient(player, inventory)
		print(("[%s] dev: %s holds the %s"):format(Config.WorkingTitle, player.Name, Quests.HornItem))
	end
end

-- /step N: jump the current world's Field Notes to step N with empty progress.
local function setStep(player: Player, text: string)
	local step = tonumber(string.match(text, "%d+") or "")
	if not step then
		return
	end
	local state: any = nil
	local ok = PlayerData.Update(player, function(profile)
		profile.quests.fieldNotes[tostring(profile.world.current)] = math.max(1, math.floor(step))
		profile.quests.progress = {}
		state = { fieldNotes = profile.quests.fieldNotes, progress = profile.quests.progress }
	end)
	if ok then
		Net.event("QuestsChanged"):FireClient(player, state)
		print(("[%s] dev: %s is on Field Notes step %d"):format(Config.WorkingTitle, player.Name, step))
	end
end

-- /shower [end | in N]: start a Meteor Shower now (it runs its normal length), end the current one, or
-- schedule the next start N seconds from now so the countdown chip can be seen.
local function forceShower(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "in" then
		local seconds = tonumber(string.match(text, "in%s+(%d+)") or "") or 0
		Events.ForceNext(seconds)
		print(("[%s] dev: %s set the next shower %ds from now"):format(Config.WorkingTitle, player.Name, seconds))
		return
	end
	local on = word ~= "end" and word ~= "off"
	Events.Force(on)
	print(("[%s] dev: %s %s the Meteor Shower"):format(Config.WorkingTitle, player.Name, if on then "started" else "ended"))
end

-- /sighting [end]: start a Warden sighting now (the Warden walks the whole path from its first point) or end the
-- running one; prints the sighting clock afterwards.
local function forceSighting(player: Player, text: string)
	local on = string.find(text, "end", 1, true) == nil
	Sightings.Force(on)
	local state = Sightings.GetState()
	print(("[%s] dev: %s %s the Warden sighting (active=%s, %s, %ds left, next in %ds)"):format(
		Config.WorkingTitle,
		player.Name,
		if on and state.active then "started" elseif on then "could not start" else "ended",
		tostring(state.active),
		if state.species == "" then "none on this world" else state.species,
		state.secondsLeft,
		state.nextInSeconds
	))
end

-- /rush [end | in N]: start a Catch Rush round now (it runs its normal length), end the current one (it is
-- settled and paid at once), or schedule the next start N seconds from now so the countdown chip can be seen.
local function forceRush(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "in" then
		local seconds = tonumber(string.match(text, "in%s+(%d+)") or "") or 0
		CatchRush.ForceNext(seconds)
		print(("[%s] dev: %s set the next Catch Rush %ds from now"):format(Config.WorkingTitle, player.Name, seconds))
		return
	end
	local on = word ~= "end" and word ~= "off"
	CatchRush.Force(on)
	print(("[%s] dev: %s %s the Catch Rush"):format(Config.WorkingTitle, player.Name, if on then "started" else "ended"))
end

-- /week <N|next|off>: N sets the weekly rotation's offset to N weeks, next adds one, off goes back to the real
-- week. Weekly re-reads at once (the weather, the clients, the Spawner), and the week it lands on is printed.
local function setWeek(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	local offset = Weekly.GetOffset()
	if word == "next" then
		offset += 1
	elseif word == "off" then
		offset = 0
	else
		local n = tonumber(word or "")
		if not n then
			print(("[%s] dev: /week needs a number, next or off; the offset is %d"):format(Config.WorkingTitle, offset))
			return
		end
		offset = n
	end
	Weekly.SetOffset(offset)
	print(("[%s] dev: %s set the week offset to %d: %s"):format(Config.WorkingTitle, player.Name, Weekly.GetOffset(), Weekly.Describe()))
end

-- /season <id|off|done>: an id forces that season on (the clock, the clients and the Spawner follow at once, and the
-- banner counts its whole window), off goes back to the calendar, done sets every unclaimed row of the running
-- season's track to its count so the claim buttons can be tested. Anything else prints the known ids.
local function setSeason(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "off" then
		Seasons.SetOverride(nil)
		print(("[%s] dev: %s put the seasons back on the calendar"):format(Config.WorkingTitle, player.Name))
	elseif word == "done" then
		if Seasons.Current() then
			Seasons.DevComplete(player)
			print(("[%s] dev: %s has every row of the season's track finished"):format(Config.WorkingTitle, player.Name))
		else
			print(("[%s] dev: no season is running; /season <id> forces one on"):format(Config.WorkingTitle))
		end
	elseif word ~= nil and SeasonMath.Find(word) ~= nil then
		Seasons.SetOverride(word)
		print(("[%s] dev: %s forced the season %s on"):format(Config.WorkingTitle, player.Name, word))
	else
		local ids: { string } = {}
		for _, season in ipairs(SeasonsData.List) do
			table.insert(ids, season.id)
		end
		print(("[%s] dev: /season <id|off|done>; the ids are %s"):format(Config.WorkingTitle, table.concat(ids, ", ")))
	end
end

local SPAWN_OFFSET_STUDS = 8 -- a /spawn alien appears this far in front of the player
local SPAWN_LIFETIME_SECONDS = 180

-- /spawn <speciesId> [band]: place one wild alien of that species beside the player (any tier, no luck
-- roll), so a Cosmic catch or a reserved-spawn rule can be tested on demand. The optional band (tiny,
-- small, normal, big, huge; any case) forces its size, otherwise the size rolls like a wild spawn.
local function spawnSpecies(player: Player, text: string)
	local id = string.match(text, "^/%S+%s+(%S+)")
	if not id or not Species.ById[id] then
		print(("[%s] dev: unknown species %s"):format(Config.WorkingTitle, tostring(id)))
		return
	end
	local bandWord = string.match(text, "^/%S+%s+%S+%s+(%S+)")
	local band: string? = nil
	if bandWord then
		for bandId in pairs(Sizes.ById) do
			if string.lower(bandId) == string.lower(bandWord) then
				band = bandId
				break
			end
		end
		if not band then
			print(("[%s] dev: unknown size %s (tiny, small, normal, big, huge)"):format(Config.WorkingTitle, bandWord))
			return
		end
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local at = root.Position + root.CFrame.LookVector * SPAWN_OFFSET_STUDS
	local spawn = Spawner.SpawnAt(Vector3.new(at.X, 0, at.Z), id, Spawner.RollOverlay(), nil, SPAWN_LIFETIME_SECONDS, band)
	print(("[%s] dev: spawned %s for %s: %s"):format(Config.WorkingTitle, id, player.Name, if spawn then spawn.spawnId else "failed"))
end

-- /variant <id|off>: force a catch variant (Standard, Reel, Chase; any case) on every encounter this player
-- starts, so a world's bar can be played on any world. off, or no argument, clears it.
local function setVariant(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if not word or string.lower(word) == "off" then
		Catching.SetForcedVariant(player, nil)
		print(("[%s] dev: %s variant forced: off"):format(Config.WorkingTitle, player.Name))
		return
	end
	for _, id in ipairs(CatchVariants.Order) do
		if string.lower(id) == string.lower(word) then
			Catching.SetForcedVariant(player, id)
			print(("[%s] dev: %s variant forced: %s"):format(Config.WorkingTitle, player.Name, id))
			return
		end
	end
	print(("[%s] dev: unknown variant %s (%s, off)"):format(Config.WorkingTitle, word, table.concat(CatchVariants.Order, ", ")))
end

-- /grow [H]: add H hours (default 2 when missing or not a number) of worked time to every seated alien, so
-- the Grown and Elder stages can be reached without waiting; each crossing is announced like a real one.
local function growCamp(player: Player, text: string)
	local hours = tonumber(string.match(text, "^/%S+%s+(%S+)") or "") or 2
	local crossed = EconomyService.DevGrow(player, hours * 3600) -- hours to seconds, a unit conversion
	print(("[%s] dev: %s camp worked %g hours; %d alien(s) crossed a growth stage"):format(Config.WorkingTitle, player.Name, hours, crossed))
end

local DUPES_DEFAULT = 5 -- /dupes grants this many copies when N is missing (one fusion needs DuplicatesPerLevel + 1)
local DUPES_MAX = 50 -- and never more than this in one command

-- /dupes <speciesId> [N]: grant N (default 5) plain copies of that species through GrantAlien (overlay None, not
-- Perfect, size rolled like an egg), so the Fuse flow can be tested without a catch grind. The Scrap and the
-- codex move as for any grant.
local function grantDupes(player: Player, text: string)
	local id = string.match(text, "^/%S+%s+(%S+)")
	if not id or not Species.ById[id] then
		print(("[%s] dev: unknown species %s"):format(Config.WorkingTitle, tostring(id)))
		return
	end
	local asked = tonumber(string.match(text, "^/%S+%s+%S+%s+(%S+)") or "")
	local count = math.clamp(math.floor(asked or DUPES_DEFAULT), 1, DUPES_MAX)
	local granted = 0
	for _ = 1, count do
		if EconomyService.GrantAlien(player, id, "None", false, nil) then
			granted += 1
		end
	end
	print(("[%s] dev: %s granted %d copies of %s"):format(Config.WorkingTitle, player.Name, granted, id))
end

local RADAR_DEFAULT_TIER = 1 -- /radar grants up to this tier when N is missing
local RADAR_MAX_TIER = 3 -- Radar1..Radar3

-- /radar [N]: raise the radar to tier N (1..3, default 1) through Shop.GrantGear, one tier at a time in order
-- (each call raises gear.radar to that tier; AlreadyOwned counts as done), so the minimap, the Mk2 ping and the
-- Nearby panel can be tested without the Scrap, the Field Notes step or a launch. Prints the final tier or the refusal.
local function grantRadar(player: Player, text: string)
	local asked = tonumber(string.match(text, "^/%S+%s+(%S+)") or "")
	local target = math.clamp(math.floor(asked or RADAR_DEFAULT_TIER), 1, RADAR_MAX_TIER)
	if target > Shop.HighestRadarTier() then
		print(("[%s] dev: radar Mk%d is not in the game yet (the highest tier with a buy rule is Mk%d)"):format(Config.WorkingTitle, target, Shop.HighestRadarTier()))
		return
	end
	for tier = 1, target do
		local ok, reason = Shop.GrantGear(player, "Radar" .. tostring(tier))
		if not ok and reason ~= "AlreadyOwned" then
			print(("[%s] dev: %s radar grant Mk%d refused: %s"):format(Config.WorkingTitle, player.Name, tier, tostring(reason)))
			return
		end
	end
	local profile = PlayerData.Get(player)
	print(("[%s] dev: %s radar is now Mk%s"):format(Config.WorkingTitle, player.Name, if profile then tostring(profile.gear.radar) else "?"))
end

local TOKEN_DEFAULT = 1 -- /token grants this many Companion Tokens when N is missing
local TOKEN_MAX = 10 -- and never more than this in one command

-- /token [N]: put N (default 1) Companion Tokens in the inventory, so the use-token flow can be tried without
-- the wheel; the client is told through InventoryChanged.
local function grantTokens(player: Player, text: string)
	local asked = tonumber(string.match(text, "^/%S+%s+(%S+)") or "")
	local count = math.clamp(math.floor(asked or TOKEN_DEFAULT), 1, TOKEN_MAX)
	local inventory: any = nil
	local ok = PlayerData.Update(player, function(profile)
		profile.inventory.items[CompanionsData.TokenItem] = (profile.inventory.items[CompanionsData.TokenItem] or 0) + count
		inventory = profile.inventory
	end)
	if ok then
		Net.event("InventoryChanged"):FireClient(player, inventory)
		print(("[%s] dev: %s granted %d %s item(s)"):format(Config.WorkingTitle, player.Name, count, CompanionsData.TokenItem))
	end
end

-- /follow <speciesId>: the player's first resting copy of that species (lowest uid) that is not already a
-- companion starts following, through the same call the SetCompanion remote makes.
local function firstRestingCopy(profile: Types.Profile, id: string): string?
	local pick: string? = nil
	for uid, record in pairs(profile.aliens) do
		if record.species == id and record.station == nil and not table.find(profile.companions, uid) then
			if pick == nil or uid < pick then
				pick = uid
			end
		end
	end
	return pick
end

local function followSpecies(player: Player, text: string)
	local id = string.match(text, "^/%S+%s+(%S+)")
	if not id or not Species.ById[id] then
		print(("[%s] dev: unknown species %s"):format(Config.WorkingTitle, tostring(id)))
		return
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local pick = firstRestingCopy(profile, id)
	if not pick then
		print(("[%s] dev: no resting copy of %s"):format(Config.WorkingTitle, id))
		return
	end
	local ok, reason = Companions.SetFollowing(player, pick, true)
	print(("[%s] dev: %s follow %s %s"):format(Config.WorkingTitle, player.Name, id, if ok then "ok" else "refused: " .. tostring(reason)))
end

-- /ride <speciesId|off>: off gets down. A species id rides a copy of it that already follows the player; with
-- none following, the first resting copy follows first (the same call /follow makes), then it is ridden through
-- the call the SetMount remote makes.
local function rideSpecies(player: Player, text: string)
	local id = string.match(text, "^/%S+%s+(%S+)")
	if id == "off" then
		local ok, reason = Companions.SetRiding(player, nil)
		print(("[%s] dev: %s dismount %s"):format(Config.WorkingTitle, player.Name, if ok then "ok" else "refused: " .. tostring(reason)))
		return
	end
	if not id or not Species.ById[id] then
		print(("[%s] dev: unknown species %s"):format(Config.WorkingTitle, tostring(id)))
		return
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local pick: string? = nil
	for _, uid in ipairs(profile.companions) do
		local record = profile.aliens[uid]
		if record and record.species == id then
			pick = uid
			break
		end
	end
	if not pick then
		pick = firstRestingCopy(profile, id)
		if not pick then
			-- Say why: no copy at all, or every copy is seated (a seated alien never follows, so it cannot be ridden).
			local owned = 0
			for _, record in pairs(profile.aliens) do
				if record.species == id then
					owned += 1
				end
			end
			if owned == 0 then
				print(("[%s] dev: no copy of %s to ride (catch or /spawn one first)"):format(Config.WorkingTitle, id))
			else
				print(("[%s] dev: every copy of %s is working at a station; a seated alien cannot follow or be ridden (unseat one first)"):format(Config.WorkingTitle, id))
			end
			return
		end
		local followed, followReason = Companions.SetFollowing(player, pick, true)
		print(("[%s] dev: %s follow %s %s"):format(Config.WorkingTitle, player.Name, id, if followed then "ok" else "refused: " .. tostring(followReason)))
		if not followed then
			return
		end
	end
	local ok, reason = Companions.SetRiding(player, pick)
	print(("[%s] dev: %s ride %s %s"):format(Config.WorkingTitle, player.Name, id, if ok then "ok" else "refused: " .. tostring(reason)))
end

-- /storage fill [N] | cap | bay <level>: the alien storage cap (data/Storage, StorageMath). fill writes N plain Common
-- records straight into the profile (N missing: as many as fit; never past the cap the player has now), cycling through the
-- Common species, so the cap, the overflow rule and Release can be tried without a thousand catches; the codex, Scrap and
-- quests do not move. bay sets the Storage Bay level without paying (the cap and the Aliens screen follow). Every form ends
-- by printing the record count against the cap and the cap's parts.
local function storageCommand(player: Player, text: string)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local action = string.match(text, "^/%S+%s+(%S+)")
	local argument = tonumber(string.match(text, "^/%S+%s+%S+%s+(%S+)") or "")
	if action == "bay" then
		if argument == nil then
			print(("[%s] dev: /storage bay needs a level, 0 to %d"):format(Config.WorkingTitle, #StorageData.Bay.Levels))
		else
			local level = EconomyService.DevSetBayLevel(player, argument)
			print(("[%s] dev: %s Storage Bay level set to %s"):format(Config.WorkingTitle, player.Name, tostring(level)))
		end
	end
	local parts = EconomyService.StorageParts(player)
	if not parts then
		return
	end
	local held = StorageMath.CountOf(profile.aliens)
	if action == "fill" then
		local commons: { string } = {}
		for _, def in ipairs(Species.List) do
			if def.tier == "Common" then
				table.insert(commons, def.id)
			end
		end
		if #commons == 0 then
			print(("[%s] dev: no Common species to fill with"):format(Config.WorkingTitle))
			return
		end
		local room = math.max(0, parts.cap - held)
		local count = math.clamp(math.floor(argument or room), 0, room)
		PlayerData.Update(player, function(p)
			for index = 1, count do
				local uid = HttpService:GenerateGUID(false)
				p.aliens[uid] = {
					uid = uid,
					species = commons[(index - 1) % #commons + 1],
					level = 1,
					overlay = "None",
					caughtAt = os.time(),
					size = Sizes.Default,
					workedSeconds = 0,
				}
			end
		end)
		EconomyService.PushCamp(player) -- the client draws the records from this push
		held += count
		print(("[%s] dev: %s storage filled with %d Common record(s)"):format(Config.WorkingTitle, player.Name, count))
	end
	print(("[%s] dev: %s storage %d / %d (%s)"):format(Config.WorkingTitle, player.Name, held, parts.cap, if StorageMath.IsFull(held, parts.cap) then "full" elseif StorageMath.IsWarning(held, parts.cap) then "warning" else "ok"))
	print(
		("[%s] dev: %s storage cap parts: base %d + modules %d + bay %d (level %d of %d) + pass %d = %d, hard cap %d"):format(
			Config.WorkingTitle, player.Name, parts.base, parts.modules, parts.bay, profile.storage.bayLevel, #StorageData.Bay.Levels, parts.pass, parts.sum, StorageData.HardCap
		)
	)
end

-- /days N: set the Welcome Week days-played counter, so every gift tile up to N unlocks.
local function setDays(player: Player, text: string)
	local days = tonumber(string.match(text, "%d+") or "")
	if days then
		Gifts.DevSetDays(player, math.floor(days))
		print(("[%s] dev: %s has played %d days"):format(Config.WorkingTitle, player.Name, days))
	end
end

-- /spins N: bank N spins for the wheel.
local function addSpins(player: Player, text: string)
	local count = tonumber(string.match(text, "%d+") or "")
	if count then
		Gifts.DevAddSpins(player, math.floor(count))
		print(("[%s] dev: %s banked %d spins"):format(Config.WorkingTitle, player.Name, count))
	end
end

-- /buy <itemId>: grant a Robux catalog item as if its receipt had arrived (no Robux, no prompt).
local function buyItem(player: Player, text: string)
	local id = string.match(text, "^/%S+%s+(%S+)")
	if not id then
		print(("[%s] dev: /buy needs an item id (Shared/data/Shop)"):format(Config.WorkingTitle))
		return
	end
	local ok, reason = Monetization.DevGrant(player, id)
	print(("[%s] dev: %s buy %s %s"):format(Config.WorkingTitle, player.Name, id, if ok then "ok" else "refused: " .. tostring(reason)))
end

-- /pass <itemId> [off]: own (or drop) a game pass for this session; owning applies its one-time grants.
local function setPass(player: Player, text: string)
	local id, flag = string.match(text, "^/%S+%s+(%S+)%s*(%S*)")
	if not id then
		print(("[%s] dev: /pass needs an item id (Shared/data/Shop)"):format(Config.WorkingTitle))
		return
	end
	local owned = flag ~= "off"
	local ok, reason = Monetization.DevSetPass(player, id, owned)
	print(("[%s] dev: %s pass %s %s"):format(Config.WorkingTitle, player.Name, id, if ok then (if owned then "owned" else "dropped") else "refused: " .. tostring(reason)))
end

-- /world N: move the profile to world N (clamped to a world in Worlds, 0 the home planet) and unlock it, and tell the client
-- (WorldChanged, ModulesChanged) the way Launch does. Only the profile changes: the place itself is fixed
-- by its WorldId attribute, so rejoin the World N place (rojo serve world2.project.json) to stand in it.
local function setWorld(player: Player, text: string)
	local requested = tonumber(string.match(text, "%d+") or "")
	if not requested then
		print(("[%s] dev: /world needs a world number (Shared/data/Worlds)"):format(Config.WorkingTitle))
		return
	end
	local last = 0
	for id in pairs(Worlds) do
		last = math.max(last, id)
	end
	local target = math.clamp(math.floor(requested), Home.WorldId, last)
	local ok = PlayerData.Update(player, function(profile)
		profile.world.current = target
		if target == Home.WorldId then
			profile.home.unlocked = true
		end
		if not table.find(profile.world.unlocked, target) then
			table.insert(profile.world.unlocked, target)
		end
	end)
	if ok then
		-- The client mirrors keep the old world until told, exactly as after a launch: the new current world
		-- and its modules, so the Ship screen, the condition filter and the tutorial pill follow the profile.
		local moved = PlayerData.Get(player)
		if moved then
			Net.event("WorldChanged"):FireClient(player, moved.world.current, moved.world.unlocked)
			Net.event("ModulesChanged"):FireClient(player, moved.world.current, moved.modules[tostring(moved.world.current)] or {})
		end
		Tutorial.OnWorldChanged(player)
		print(("[%s] dev: %s is now on world %d (%s); this place runs world %d, rejoin the matching place"):format(Config.WorkingTitle, player.Name, target, Worlds[target].name, Place.WorldId()))
	end
end

-- /complete: mark every module of this place's world complete on the profile, written the way the Economy
-- service writes a completion (both gates paid, started, progress 1, completedAt, updatedAt, and the free
-- slot growth a module unlocks), creating the world's table and states when missing. The client hears
-- ModulesChanged with the same payload Economy pushes, and StationsChanged for the slots. The ship is then
-- complete, so the Launch button and the Launch remote can be tested without the real build.
local function completeModules(player: Player, _text: string)
	local worldId = Place.WorldId()
	local defs = Economy.moduleDefs(worldId)
	local finished = 0 -- modules that were not complete before this call
	local finishedIds: { string } = {} -- in module order, for the hooks a real completion fires
	local modulesNow: { [string]: Types.ModuleProgress } = {}
	local stationsNow: { [string]: Types.StationState } = {}
	local aliensNow: { [string]: Types.AlienRecord } = {}
	local ok = PlayerData.Update(player, function(profile)
		local key = tostring(worldId)
		local world = profile.modules[key]
		if not world then
			world = {}
			profile.modules[key] = world
		end
		local now = os.time()
		for _, def in ipairs(defs) do
			local state = world[def.id]
			if not state then
				local fresh: Types.ModuleProgress = { scrapPaid = 0, keyPaid = 0, progress = 0, started = false, completedAt = nil, updatedAt = now }
				world[def.id] = fresh
				state = fresh
			end
			state.scrapPaid = def.scrap
			state.keyPaid = def.keyCount
			state.started = true
			state.progress = 1
			if state.completedAt == nil then
				state.completedAt = now
				finished += 1
				table.insert(finishedIds, def.id)
			end
			state.updatedAt = now
			local unlocks = def.unlocksSlots
			if unlocks then
				for _, station in pairs(profile.stations) do
					local bonus = station.bonus or 0 -- bought slots ride on top of the unlock (as in Economy)
					station.slots = math.clamp(math.max(station.slots, unlocks + bonus), 1, Config.StationMaxSlots + bonus)
				end
			end
		end
		modulesNow = world
		stationsNow = profile.stations
		aliensNow = profile.aliens
	end)
	if not ok then
		return
	end
	Net.event("ModulesChanged"):FireClient(player, worldId, modulesNow)
	Net.event("StationsChanged"):FireClient(player, stationsNow, aliensNow)
	-- What a real completion fires (Economy.reportModuleComplete): the client's fanfare and pan, and the
	-- tutorial's moduleStarted and moduleComplete triggers, so T3 and T6 (and the gift pop after T6) can be
	-- reached from here. The tutorial only counts the step it is on, so an out-of-order hook is ignored.
	for _, moduleId in ipairs(finishedIds) do
		Net.event("ModuleCompleted"):FireClient(player, worldId, moduleId)
		Tutorial.OnModuleStarted(player, moduleId)
		Tutorial.OnModuleComplete(player, moduleId)
	end
	EconomyService.PushStorageAfterModules(player, finishedIds) -- the alien storage the modules add, with the client's toast
	print(("[%s] dev: %s completed %d of %d modules on world %d (%d were already done); the ship is complete"):format(Config.WorkingTitle, player.Name, finished, #defs, worldId, #defs - finished))
end

-- /outpost N [H]: world N's outpost exists (level 1) with H hours (default 1) uncollected, and world N is
-- unlocked, so the Star Chart has something to collect and fly to. Fractions are fine (/outpost 2 0.5).
local function backdateOutpost(player: Player, text: string)
	local numbers: { number } = {}
	for token in string.gmatch(text, "%d+%.?%d*") do
		local value = tonumber(token)
		if value then
			table.insert(numbers, value)
		end
	end
	local requested = numbers[1]
	if not requested then
		print(("[%s] dev: /outpost needs a world number (Shared/data/Worlds) and optionally hours"):format(Config.WorkingTitle))
		return
	end
	local worldId = math.floor(requested)
	if not Worlds[worldId] then
		print(("[%s] dev: /outpost: no world %d in Shared/data/Worlds"):format(Config.WorkingTitle, worldId))
		return
	end
	if worldId == Home.WorldId then
		print(("[%s] dev: /outpost: the home planet is never an outpost"):format(Config.WorkingTitle))
		return
	end
	local hours = math.max(0, numbers[2] or 1)
	local unlocked = false
	local ok = PlayerData.Update(player, function(profile)
		if not table.find(profile.world.unlocked, worldId) then
			table.insert(profile.world.unlocked, worldId)
			unlocked = true
		end
	end)
	if not ok then
		return
	end
	if unlocked then
		local live = PlayerData.Get(player)
		if live then
			Net.event("WorldChanged"):FireClient(player, live.world.current, live.world.unlocked)
		end
	end
	Outposts.DevBackdate(player, worldId, hours)
	print(("[%s] dev: %s world %d outpost has %g hours to collect%s"):format(Config.WorkingTitle, player.Name, worldId, hours, if unlocked then " (world unlocked)" else ""))
end

-- /social reset: forget the group, referral and notifications flags. /social credit N: pay N inviter rewards
-- (capped by the lifetime limit). /social ask: show the notifications card at once.
local function socialCommand(player: Player, text: string)
	local sub = string.match(text, "^%s*/?social%s+(%a+)") or ""
	if sub == "reset" then
		Social.DevReset(player)
		print(("[%s] dev: %s social flags reset"):format(Config.WorkingTitle, player.Name))
	elseif sub == "credit" then
		local count = tonumber(string.match(text, "%d+%s*$") or "") or 1
		local granted = Social.DevCredit(player, count)
		print(("[%s] dev: %s credited %d of %d referral(s) (the lifetime cap drops the rest)"):format(Config.WorkingTitle, player.Name, granted, count))
	elseif sub == "ask" then
		Net.event("NotifyAsk"):FireClient(player)
		print(("[%s] dev: %s notifications card sent"):format(Config.WorkingTitle, player.Name))
	else
		print(("[%s] dev: /social reset | credit N | ask"):format(Config.WorkingTitle))
	end
end

-- /lb N: count N catches on the weekly board (through its per-minute cap). /lb flush: send them and refresh.
local function leaderboardCommand(player: Player, text: string)
	local sub = string.match(text, "^%s*/?lb%s+(%S+)") or ""
	if sub == "flush" then
		Leaderboard.DevFlush()
		print(("[%s] dev: leaderboard flushed and refreshed"):format(Config.WorkingTitle))
		return
	end
	local count = tonumber(sub)
	if count and count >= 1 then
		local added = Leaderboard.DevAdd(player, count)
		print(("[%s] dev: %s counted %d of %d catches on the weekly board"):format(Config.WorkingTitle, player.Name, added, math.floor(count)))
	else
		print(("[%s] dev: /lb N | flush"):format(Config.WorkingTitle))
	end
end

-- /dq reset | done: deal the daily and weekly quests again with empty progress, or set every dealt,
-- unclaimed one to its count so the claim buttons can be tested.
local function dailyQuestsCommand(player: Player, text: string)
	local sub = string.match(text, "^%s*/?dq%s+(%S+)") or ""
	if sub == "reset" then
		DailyQuests.DevReset(player)
		print(("[%s] dev: %s has fresh daily and weekly quests"):format(Config.WorkingTitle, player.Name))
	elseif sub == "done" then
		DailyQuests.DevComplete(player)
		print(("[%s] dev: %s has every dealt daily and weekly quest finished"):format(Config.WorkingTitle, player.Name))
	else
		print(("[%s] dev: /dq reset | done"):format(Config.WorkingTitle))
	end
end

-- /homeclear: empty the house grid (profile.home.items) with no refund and push HomeChanged, so a plot can be
-- rebuilt from nothing. Prints how many items went.
local function homeClear(player: Player)
	local removed = 0
	local ok = PlayerData.Update(player, function(profile)
		for uid in pairs(profile.home.items) do
			profile.home.items[uid] = nil
			removed += 1
		end
	end)
	local profile = PlayerData.Get(player)
	if ok and profile then
		Net.event("HomeChanged"):FireClient(player, profile.home.items)
		print(("[%s] dev: %s cleared the house grid (%d item(s) removed)"):format(Config.WorkingTitle, player.Name, removed))
	end
end

local HABITAT_BACK_HOURS_DEFAULT = 2 -- /habitat moves the payout clock back this many hours when H is missing

-- /habitat [H]: move the habitat payout clock (profile.home.habitatSettled) back H hours (default 2, fractions
-- are fine), so the next arrival at the home planet pays up to the cap; prints the new clock. /habitat settle:
-- pay the habitats now (the same settle an arrival runs) and print the Scrap paid.
local function habitatCommand(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "settle" then
		local paid = Habitats.SettleIncome(player)
		print(("[%s] dev: %s habitats paid %d Scrap"):format(Config.WorkingTitle, player.Name, paid))
		return
	end
	local hours = math.max(0, tonumber(word or "") or HABITAT_BACK_HOURS_DEFAULT)
	local clock = 0
	local ok = PlayerData.Update(player, function(profile)
		profile.home.habitatSettled -= math.floor(hours * 3600) -- hours to seconds, a unit conversion
		clock = profile.home.habitatSettled
	end)
	if ok then
		print(("[%s] dev: %s habitat clock moved back %g hours to %d (%d seconds ago); the next arrival at home pays"):format(Config.WorkingTitle, player.Name, hours, clock, os.time() - clock))
	end
end

local MAIL_DEFAULT_COUNT = 1 -- /mail with no N writes this many letters
local MAIL_PAST_CAP = 1 -- and at most this many more than the mailbox holds, so the oldest being dropped can be seen

-- /mail [N]: N test letters (default 1, at most MaxLetters + 1) from your own name to your own mailbox, each with
-- the default Scrap, through Mail.Send, so the cap, the push and the claim can be tried without the developer panel.
local function mailCommand(player: Player, text: string)
	local requested = tonumber(string.match(text, "^/%S+%s+(%d+)") or "") or MAIL_DEFAULT_COUNT
	local count = math.clamp(math.floor(requested), 1, MailData.MaxLetters + MAIL_PAST_CAP)
	local sent = 0
	for k = 1, count do
		if Mail.Send(player, player.Name, ("Test letter %d"):format(k), { { kind = "scrap", amount = MailData.DefaultScrap } }) then
			sent += 1
		end
	end
	local profile = PlayerData.Get(player)
	local waiting = if profile then #profile.home.mail else 0
	if sent > 0 then
		Net.event("MailArrived"):FireClient(player) -- the "letter waiting" toast, as a real letter gives
	end
	print(("[%s] dev: %s sent %d test letter(s) to themselves (%d waiting)"):format(Config.WorkingTitle, player.Name, sent, waiting))
end

-- /visit <name|id>: at the home place, look at another player's home in this server (the in-server path of the Visit
-- button, so the lock, the Visitor Book and the Wave rules all apply); the player is found by Name (any case) or UserId.
-- /visit off: back to your own home. Prints the outcome.
local function visitCommand(player: Player, text: string)
	if not Place.IsHome() then
		print(("[%s] dev: /visit works in the home place only"):format(Config.WorkingTitle))
		return
	end
	local argument = string.match(text, "^/%S+%s+(%S+)")
	if not argument then
		print(("[%s] dev: /visit <name|id> looks at that player's home, /visit off goes back to your own"):format(Config.WorkingTitle))
		return
	end
	if string.lower(argument) == "off" then
		Visiting.LeaveView(player)
		print(("[%s] dev: %s looks at their own home"):format(Config.WorkingTitle, player.Name))
		return
	end
	local userId = tonumber(argument)
	local target: Player? = nil
	for _, other in ipairs(Players:GetPlayers()) do
		if string.lower(other.Name) == string.lower(argument) or other.UserId == userId then
			target = other
			break
		end
	end
	if not target then
		print(("[%s] dev: no player here named or numbered %s"):format(Config.WorkingTitle, argument))
		return
	end
	local ok, reason = Visiting.ViewHome(player, target)
	print(("[%s] dev: %s visits %s: %s"):format(Config.WorkingTitle, player.Name, target.Name, if ok then "ok" else tostring(reason)))
end

-- /afk: rest now (the Resting screen and the half-rate income show at once; moving or using the game wakes you).
-- /afk off: wake. /afk rejoin: the rejoin path the client asks for after 17 idle minutes (needs a rest: /afk first; Studio
-- only prints it and the screen shows its line).
local function afkCommand(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "off" then
		Afk.DevRest(player, false)
		print(("[%s] dev: %s is awake"):format(Config.WorkingTitle, player.Name))
	elseif word == "rejoin" then
		local ok, reason = Afk.DevRejoin(player)
		print(("[%s] dev: %s rejoin: %s"):format(Config.WorkingTitle, player.Name, if ok then "ok" else tostring(reason)))
	else
		Afk.DevRest(player, true)
		print(("[%s] dev: %s rests (Afk.IsResting %s)"):format(Config.WorkingTitle, player.Name, tostring(Afk.IsResting(player))))
	end
end

-- /playtime <minutes>: that many minutes of played time today (the playtime gifts unlock by it; a negative number takes
-- minutes back). /playtime reset: today's played time and claims cleared. The screen and the badge update at once.
local function playtimeCommand(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "reset" then
		Playtime.DevReset(player)
		print(("[%s] dev: %s's playtime today cleared"):format(Config.WorkingTitle, player.Name))
		return
	end
	local minutes = tonumber(word or "")
	if not minutes or minutes ~= minutes or math.abs(minutes) == math.huge then
		print(("[%s] dev: /playtime <minutes> or /playtime reset"):format(Config.WorkingTitle))
		return
	end
	Playtime.DevAddMinutes(player, minutes)
	local profile = PlayerData.Get(player)
	if profile then
		local claimed = 0
		for _ in pairs(profile.playtime.claimed) do
			claimed += 1
		end
		print(("[%s] dev: %s has played %d s today (%d claimed)"):format(Config.WorkingTitle, player.Name, profile.playtime.seconds, claimed))
	end
end

-- /cinematic <momentId>: play that cinematic moment on your client now. /cinematic reset: forget which first arrivals you
-- watched (profile.seen), so each plays again on the next join. /cinematic list (or no word): print the moments and the
-- arrivals watched. The play happens on the client (CameraDirector.PlayShots through a DevCinematic event).
local function cinematicCommand(player: Player, text: string)
	local word = string.match(text, "^/%S+%s+(%S+)")
	if word == "reset" then
		Seen.DevReset(player)
		print(("[%s] dev: %s's first arrivals forgotten"):format(Config.WorkingTitle, player.Name))
		return
	end
	if word ~= nil and word ~= "list" then
		if Seen.DevPlay(player, word) then
			print(("[%s] dev: %s plays %s"):format(Config.WorkingTitle, player.Name, word))
		else
			print(("[%s] dev: no cinematic moment called %s"):format(Config.WorkingTitle, word))
		end
		return
	end
	local ids: { string } = {}
	for id in pairs(CinematicsData.Moments) do
		table.insert(ids, id)
	end
	table.sort(ids)
	local watched = Seen.DevList(player)
	print(("[%s] dev: moments %s; watched %s"):format(Config.WorkingTitle, table.concat(ids, ", "), if #watched > 0 then table.concat(watched, ", ") else "none"))
end

-- Public API -------------------------------------------------------------

function Dev.Init()
	if not RunService:IsStudio() then
		return
	end
	enabled = true
	Net.event("ScrapChanged")
	command("scrap", grantScrap)
	command("night", function()
		WorldClock.Force(true, nil)
	end)
	command("day", function()
		WorldClock.Force(false, nil)
	end)
	command("rain", function()
		-- Rain where the world rolls it (World 1 and the home), else this world's special weather (Blizzard on World 2)
		local state = if WorldClock.HasWeatherState("Rain") then "Rain" else WorldClock.GetSpecialWeather().id
		WorldClock.Force(nil, state)
	end)
	command("clear", function()
		WorldClock.Force(nil, "Clear")
	end)
	command("horn", function(player: Player)
		grantHorn(player)
	end)
	command("step", setStep)
	command("weather", function(_player: Player, text: string)
		local state = string.match(text, "(%S+)%s*$")
		if state then
			WorldClock.Force(nil, state)
		end
	end)
	command("shower", forceShower)
	command("rush", forceRush)
	command("sighting", forceSighting)
	command("week", setWeek)
	command("season", setSeason)
	command("spawn", spawnSpecies)
	command("variant", setVariant)
	command("grow", growCamp)
	command("dupes", grantDupes)
	command("token", grantTokens)
	command("follow", followSpecies)
	command("ride", rideSpecies)
	-- /tutorial N: jump the tutorial to step N (8 ends it), so a later beat can be tested on its own.
	command("tutorial", function(player: Player, text: string)
		local index = tonumber(string.match(text, "%d+") or "")
		if index then
			local landed = Tutorial.DevSetStep(player, index)
			-- A profile that already did a step's deed skips past it (a finished profile lands on the end), so
			-- the print names the step reached, not the one asked for.
			print(("[%s] dev: %s asked for tutorial step %d and is on step %s"):format(Config.WorkingTitle, player.Name, index, tostring(landed)))
		end
	end)
	command("radar", grantRadar)
	command("days", setDays)
	command("spins", addSpins)
	command("buy", buyItem)
	command("pass", setPass)
	command("world", setWorld)
	command("complete", completeModules)
	command("outpost", backdateOutpost)
	command("social", socialCommand)
	command("lb", leaderboardCommand)
	command("dq", dailyQuestsCommand)
	command("homeclear", homeClear)
	command("habitat", habitatCommand)
	command("mail", mailCommand)
	command("visit", visitCommand)
	command("afk", afkCommand)
	command("playtime", playtimeCommand)
	command("storage", storageCommand)
	command("cinematic", cinematicCommand)
end

function Dev.Start()
	if enabled then
		print(("[%s] Dev: Studio chat commands on (/scrap N, /night, /day, /rain, /clear, /weather <id>, /horn, /step N, /shower [end | in N], /rush [end | in N], /sighting [end], /week <N|next|off>, /season <id|off|done>, /spawn <id> [tiny|small|normal|big|huge], /variant <id|off>, /grow [H], /dupes <id> [N], /token [N], /follow <id>, /ride <id|off>, /days N, /spins N, /radar [N], /tutorial N, /buy <itemId>, /pass <itemId> [off], /world N, /complete, /outpost N [H], /social reset|credit N|ask, /lb N|flush, /dq reset|done, /homeclear, /habitat [H]|settle, /mail [N], /visit <name|id>|off, /afk [off|rejoin], /playtime <minutes>|reset, /storage fill|cap|bay, /cinematic <momentId>|reset|list)"):format(Config.WorkingTitle))
	end
end

return Dev
