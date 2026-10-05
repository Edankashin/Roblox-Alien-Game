--!strict
-- ServerScriptService.Server.Services.Dev: chat commands for testing, available only in Studio.
-- Typed in the chat box: /scrap 1000, /night, /day, /rain, /clear, /shower, /days 7, /spins 3, /radar, /tutorial 6,
-- /buy StarterPack, /pass AutoOptimize [off], /world 2, /complete (every module of this world done, so the launch
-- can be tested in minutes), /outpost 2 3 (world 2's outpost has 3 hours to collect), /social reset | credit N | ask
-- (forget the social flags, pay N inviter rewards, show the notifications card at once), /lb N | flush (N catches on the
-- weekly board through its per-minute cap; send them to the store now and refresh the board), /dq reset | done (deal the
-- daily and weekly quests again with empty progress; finish every dealt one). Nothing
-- here exists in a live server, so none of it can be abused; the guard is RunService:IsStudio() at Init.

local RunService = game:GetService("RunService")
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
local WorldClock = require(script.Parent.WorldClock)
local Events = require(script.Parent.Events)
local Gifts = require(script.Parent.Gifts)
local Social = require(script.Parent.Social)
local Leaderboard = require(script.Parent.Leaderboard)
local DailyQuests = require(script.Parent.DailyQuests)
local Shop = require(script.Parent.Shop)
local Outposts = require(script.Parent.Outposts)
local Tutorial = require(script.Parent.Tutorial)
local Spawner = require(script.Parent.Spawner)
local Monetization = require(script.Parent.Monetization)
local Species = require(Shared.data.Species)
local Sizes = require(Shared.data.Sizes)
local Worlds = require(Shared.data.Worlds)

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

-- /world N: move the profile to world N (clamped to a world in Worlds) and unlock it, and tell the client
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
	local target = math.clamp(math.floor(requested), 1, last)
	local ok = PlayerData.Update(player, function(profile)
		profile.world.current = target
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
			end
			state.updatedAt = now
			local unlocks = def.unlocksSlots
			if unlocks then
				for _, station in pairs(profile.stations) do
					station.slots = math.clamp(math.max(station.slots, unlocks), 1, Config.StationMaxSlots)
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
		WorldClock.Force(nil, WorldClock.GetSpecialWeather().id) -- this world's special weather, Rain on World 1
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
	command("spawn", spawnSpecies)
	-- /radar: hand over the Radar Mk1 so the minimap can be tested without the Scrap or Field Notes step 2.
	-- /tutorial N: jump the tutorial to step N (8 ends it), so a later beat can be tested on its own.
	command("tutorial", function(player: Player, text: string)
		local index = tonumber(string.match(text, "%d+") or "")
		if index then
			Tutorial.DevSetStep(player, index)
			print(("[%s] dev: %s is on tutorial step %d"):format(Config.WorkingTitle, player.Name, index))
		end
	end)
	command("radar", function(player: Player)
		local ok, reason = Shop.GrantGear(player, "Radar1")
		print(("[%s] dev: %s radar grant %s"):format(Config.WorkingTitle, player.Name, if ok then "ok" else tostring(reason)))
	end)
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
end

function Dev.Start()
	if enabled then
		print(("[%s] Dev: Studio chat commands on (/scrap N, /night, /day, /rain, /clear, /weather <id>, /horn, /step N, /shower [end | in N], /spawn <id> [tiny|small|normal|big|huge], /days N, /spins N, /radar, /tutorial N, /buy <itemId>, /pass <itemId> [off], /world N, /complete, /outpost N [H], /social reset|credit N|ask, /lb N|flush, /dq reset|done)"):format(Config.WorkingTitle))
	end
end

return Dev
