--!strict
-- ServerScriptService.Server.Services.Dev: chat commands for testing, available only in Studio.
-- Typed in the chat box: /scrap 1000, /night, /day, /rain, /clear, /shower, /days 7, /spins 3, /radar, /tutorial 6. Nothing
-- here exists in a live server, so none of it can be abused; the guard is RunService:IsStudio() at Init.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.data.Config)
local Quests = require(Shared.data.Quests)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)
local WorldClock = require(script.Parent.WorldClock)
local Events = require(script.Parent.Events)
local Gifts = require(script.Parent.Gifts)
local Shop = require(script.Parent.Shop)
local Tutorial = require(script.Parent.Tutorial)
local Spawner = require(script.Parent.Spawner)
local Species = require(Shared.data.Species)

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

-- /spawn <speciesId>: place one wild alien of that species beside the player (any tier, no luck roll),
-- so a Cosmic catch or a reserved-spawn rule can be tested on demand.
local function spawnSpecies(player: Player, text: string)
	local id = string.match(text, "^/%S+%s+(%S+)")
	if not id or not Species.ById[id] then
		print(("[%s] dev: unknown species %s"):format(Config.WorkingTitle, tostring(id)))
		return
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end
	local at = root.Position + root.CFrame.LookVector * SPAWN_OFFSET_STUDS
	local spawn = Spawner.SpawnAt(Vector3.new(at.X, 0, at.Z), id, Spawner.RollOverlay(), nil, SPAWN_LIFETIME_SECONDS)
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
end

function Dev.Start()
	if enabled then
		print(("[%s] Dev: Studio chat commands on (/scrap N, /night, /day, /rain, /clear, /weather <id>, /horn, /step N, /shower [end | in N], /spawn <id>, /days N, /spins N, /radar, /tutorial N)"):format(Config.WorkingTitle))
	end
end

return Dev
