--!strict
-- ServerScriptService.Server.Services.Admin: the developer panel's server half (Shared/data/Admin).
-- One chat command in every server, live or Studio: /admin luck [bonus] [minutes] (a gifted Server Luck
-- window), /admin shower (a Meteor Shower now), /admin weather <state> (a weather state now) and
-- /admin say <text> (a line banner to everyone). Typed on one server, it is published through
-- MessagingService (Admin.Topic) and every server, the sender's included, applies what arrives, so one
-- command reaches the whole game.
--
-- The guard: the command checks the typer's UserId against Admin.DeveloperUserIds before anything else,
-- and anyone else gets nothing (no reply, no print), so the command looks absent to players. A user id is
-- public, so it is not a secret; the secret that matters is the message topic, which only game servers
-- and an Open Cloud key can reach. Each developer is limited to Admin.CommandsPerMinute commands in any
-- sliding minute (a dropped one prints a line). Every received message is checked again: `by` must be a
-- developer id, `at` within Admin.ReplayGuardSeconds of this server's clock, the fields the right types
-- and the numbers and text clamped again to their data limits. Anything else is ignored.
--
-- The fallback: when PublishAsync fails (Studio without API access) or this server could not subscribe, the
-- command is applied to this server alone and says so, so the panel can be tested without the service. With
-- no DeveloperUserIds nothing is registered and nothing is subscribed.
--
-- What it never does: touch a profile or Scrap, sell or record anything. Luck goes through
-- Monetization.GiftServerLuck (the same window a bought Server Luck opens), the shower through
-- Events.Force, the weather through WorldClock.Force (which ignores an unknown state) and the line
-- through the Announcement event. Each server that applies a command counts it once in Analytics.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local AdminData = require(Shared.data.Admin)
local AnalyticsData = require(Shared.data.Analytics)
local Strings = require(Shared.strings.en)
local Net = require(Shared.Net)
local Monetization = require(script.Parent.Monetization)
local Events = require(script.Parent.Events)
local WorldClock = require(script.Parent.WorldClock)
local Analytics = require(script.Parent.Analytics)

local Admin = {}

type Payload = {
	action: string,
	bonus: number?,
	minutes: number?,
	state: string?,
	text: string?,
	by: number,
	at: number,
}

local SECONDS_PER_MINUTE = 60 -- a unit, not a tunable: the rate window and the luck minutes
local USAGE = "usage: /admin luck [bonus] [minutes] | shower | weather <state> | say <text>"

local subscribed = false
local recentCommands: { [number]: { number } } = {} -- os.clock() of each command in the last minute, by developer UserId

-- Helpers -----------------------------------------------------------------

local function isDeveloper(userId: number): boolean
	return table.find(AdminData.DeveloperUserIds, userId) ~= nil
end

local function log(message: string)
	print(("[%s] Admin: %s"):format(Config.WorkingTitle, message))
end

-- A sliding count: true and the command is recorded while this developer has sent fewer than
-- CommandsPerMinute in the last minute.
local function withinRate(userId: number): boolean
	local now = os.clock()
	local times = recentCommands[userId]
	if not times then
		times = {}
		recentCommands[userId] = times
	end
	while #times > 0 and now - times[1] >= SECONDS_PER_MINUTE do
		table.remove(times, 1)
	end
	if #times >= AdminData.CommandsPerMinute then
		return false
	end
	table.insert(times, now)
	return true
end

-- A positive number up to `max`; nothing usable (missing, not a number, zero or less) gives the default.
local function clampOrDefault(value: any, default: number, max: number): number
	if type(value) ~= "number" or value ~= value or value <= 0 then
		return default
	end
	return math.min(value, max)
end

-- At most AnnounceMaxChars characters (not bytes, so a multi-byte character is never split).
local function cutText(text: string): string
	local limit = utf8.offset(text, AdminData.AnnounceMaxChars + 1)
	if limit then
		return string.sub(text, 1, limit - 1)
	end
	return text
end

-- Who the luck window is shown as: the data's strings key, falling back to the known key.
local function luckName(): string
	local named = (Strings :: any)[AdminData.LuckName]
	return if type(named) == "string" then named else Strings.ADMIN_LUCK_NAME
end

-- Applying ----------------------------------------------------------------

-- Does what the payload says on this server; returns a log description, or nil when there was nothing
-- usable to do (an unknown action, an unknown weather state, an empty line).
local function apply(payload: Payload): string?
	local action = payload.action
	if action == "luck" then
		local bonus = clampOrDefault(payload.bonus, AdminData.LuckBonusDefault, AdminData.LuckBonusMax)
		local minutes = clampOrDefault(payload.minutes, AdminData.LuckMinutesDefault, AdminData.LuckMinutesMax)
		Monetization.GiftServerLuck(bonus, math.max(1, math.floor(minutes * SECONDS_PER_MINUTE)), luckName())
		return ("luck +%g for %g min"):format(bonus, minutes)
	elseif action == "shower" then
		Events.Force(true)
		return "meteor shower now"
	elseif action == "weather" then
		local state = payload.state
		if type(state) ~= "string" or state == "" then
			return nil
		end
		WorldClock.Force(nil, state)
		if WorldClock.GetWeather() ~= state then
			return nil -- WorldClock ignored an unknown state
		end
		return ("weather %s"):format(state)
	elseif action == "say" then
		local text = payload.text
		if type(text) ~= "string" then
			return nil
		end
		text = cutText(text)
		if text == "" then
			return nil
		end
		local note: Types.Announcement = { kind = "notice", playerName = "", species = "", tier = "Common", overlay = "None", text = text }
		Net.event("Announcement"):FireAllClients(note)
		return ("say: %s"):format(text)
	end
	return nil
end

-- A received (or locally applied) payload: the checks, then the apply, then one analytics event for this
-- server (through the first player online) and one log line.
local function receive(data: any)
	if type(data) ~= "table" then
		return
	end
	local action, by, at = data.action, data.by, data.at
	if type(action) ~= "string" or type(by) ~= "number" or type(at) ~= "number" then
		return
	end
	if not isDeveloper(by) then
		return
	end
	if math.abs(os.time() - at) > AdminData.ReplayGuardSeconds then
		return
	end
	local payload: Payload = { action = action, bonus = data.bonus, minutes = data.minutes, state = data.state, text = data.text, by = by, at = at }
	local description = apply(payload)
	if not description then
		return
	end
	local first = Players:GetPlayers()[1]
	if first then
		Analytics.Event(first, AnalyticsData.Events.Admin, 1, { action = action, by = tostring(by) })
	end
	log(("%s (by %d)"):format(description, by))
end

local function onMessage(message: { Data: any })
	receive(message.Data)
end

-- Publishes to every server; when that fails, or this server is not subscribed to hear it back, applies it
-- here and says so.
local function publish(payload: Payload)
	local ok, err = pcall(function()
		MessagingService:PublishAsync(AdminData.Topic, payload)
	end)
	if ok and subscribed then
		return
	end
	log(if ok then "this server is not subscribed, applied locally" else ("publish failed (%s), applied locally"):format(tostring(err)))
	receive(payload)
end

-- The command ---------------------------------------------------------------

local function onCommand(player: Player, text: string)
	if not isDeveloper(player.UserId) then
		return
	end
	if not withinRate(player.UserId) then
		log(("%s is over %d commands a minute, command dropped"):format(player.Name, AdminData.CommandsPerMinute))
		return
	end
	local rest = string.match(text, "^%s*%S+%s*(.*)$") or ""
	local verb, args = string.match(rest, "^(%S+)%s*(.-)%s*$")
	if not verb then
		log(USAGE)
		return
	end
	verb = string.lower(verb)
	local payload: Payload = { action = verb, by = player.UserId, at = os.time() }
	if verb == "luck" then
		local bonusText, minutesText = string.match(args or "", "^(%S*)%s*(%S*)")
		bonusText, minutesText = bonusText or "", minutesText or ""
		local bonus = tonumber(bonusText)
		local minutes = tonumber(minutesText)
		local badBonus = bonusText ~= "" and bonus == nil
		local badMinutes = minutesText ~= "" and minutes == nil
		if badBonus or badMinutes then
			log(USAGE)
			return
		end
		payload.bonus = clampOrDefault(bonus, AdminData.LuckBonusDefault, AdminData.LuckBonusMax)
		payload.minutes = clampOrDefault(minutes, AdminData.LuckMinutesDefault, AdminData.LuckMinutesMax)
	elseif verb == "shower" then
		-- nothing more to say
	elseif verb == "weather" then
		local state = string.match(args or "", "^(%S+)")
		if not state then
			log(USAGE)
			return
		end
		payload.state = state
	elseif verb == "say" then
		local line = cutText(args or "")
		if line == "" then
			log(USAGE)
			return
		end
		-- A line typed by a person and shown to everyone goes through Roblox's text filter first, team account or
		-- not; a filter failure drops the line rather than showing it unfiltered.
		local filtered, result = pcall(function()
			return TextService:FilterStringAsync(line, player.UserId):GetNonChatStringForBroadcastAsync()
		end)
		if not filtered or type(result) ~= "string" or result == "" then
			log(("say dropped: the text filter failed (%s)"):format(tostring(result)))
			return
		end
		payload.text = cutText(result)
	else
		log(USAGE)
		return
	end
	publish(payload)
end

local function register()
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "AdminPanel"
	cmd.PrimaryAlias = "/admin"
	cmd.Triggered:Connect(function(source: TextSource, text: string)
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then
			onCommand(player, text)
		end
	end)
	cmd.Parent = folder
end

function Admin.Init()
	if #AdminData.DeveloperUserIds == 0 then
		return
	end
	register()
end

function Admin.Start()
	if #AdminData.DeveloperUserIds == 0 then
		return
	end
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(AdminData.Topic, onMessage)
	end)
	subscribed = ok
	if not ok then
		log(("could not subscribe to %s (%s); commands apply to this server only"):format(AdminData.Topic, tostring(err)))
	end
end

return Admin
