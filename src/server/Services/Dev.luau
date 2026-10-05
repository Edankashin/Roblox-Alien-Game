--!strict
-- ServerScriptService.Server.Services.Dev: chat commands for testing, available only in Studio.
-- Typed in the chat box: /scrap 1000, /night, /day, /rain, /clear. Nothing here exists in a live
-- server, so none of it can be abused; the guard is RunService:IsStudio() at Init.

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
end

function Dev.Start()
	if enabled then
		print(("[%s] Dev: Studio chat commands on (/scrap N, /night, /day, /rain, /clear, /weather <id>, /horn, /step N)"):format(Config.WorkingTitle))
	end
end

return Dev
