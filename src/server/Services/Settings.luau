--!strict
-- ServerScriptService.Server.Services.Settings: the player's preferences (Shared/data/Settings names
-- the keys and the values each accepts). The client sends a key and a value and nothing else; the
-- server checks both against the data table, writes profile.settings through PlayerData.Update and
-- pushes the whole settings table back (SettingsChanged), so the client applies exactly what was
-- saved. A fresh profile starts at the data defaults (PlayerData's template and the v3 migration);
-- Settings.Get reads a stored value for other services with the data default as the fallback.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared.types.Types)
local Config = require(Shared.data.Config)
local SettingsData = require(Shared.data.Settings)
local Net = require(Shared.Net)
local PlayerData = require(script.Parent.PlayerData)

local Settings = {}

local REMOTE_RATE_PER_SECOND = 6 -- SetSetting calls per player per second (a slider dragged quickly)

-- Pushes -----------------------------------------------------------------

local function pushSettings(player: Player, profile: Types.Profile)
	local state: Types.SettingsState = profile.settings
	Net.event("SettingsChanged"):FireClient(player, state)
end

-- Validation ---------------------------------------------------------------

-- A whole number inside the key's range: 0..#levels-1 for a level, 0 or 1 for a toggle.
local function isAllowed(def: SettingsData.SettingDef, value: any): boolean
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
		return false
	end
	if def.kind == "level" then
		local levels = def.levels
		local count = if levels then #levels else 0
		return value >= 0 and value <= count - 1
	end
	return value == 0 or value == 1
end

-- Remotes ----------------------------------------------------------------

-- SetSetting(key, value) -> (ok, reason). Reasons: BadArgs (a key the data table does not name, a value
-- that is not a whole number, a level outside 0..#levels-1, a toggle outside 0..1), RateLimited, NoProfile.
local function onSetSetting(player: Player, key: any, value: any): (boolean, string?)
	if type(key) ~= "string" then
		return false, "BadArgs"
	end
	local def = SettingsData.ById[key]
	if not def or not isAllowed(def, value) then
		return false, "BadArgs"
	end
	if not Net.allow(player, "SetSetting", REMOTE_RATE_PER_SECOND) then
		return false, "RateLimited"
	end
	local accepted: number = value
	local ok = PlayerData.Update(player, function(profile)
		profile.settings[key] = accepted
	end)
	if not ok then
		return false, "NoProfile"
	end
	local profile = PlayerData.Get(player)
	if profile then
		pushSettings(player, profile)
	end
	return true, nil
end

-- Public API -------------------------------------------------------------

-- The stored value of a preference, or its data default when the profile is not loaded or has no value
-- (an unknown key reads 0).
function Settings.Get(player: Player, key: string): number
	local profile = PlayerData.Get(player)
	local stored = if profile then profile.settings[key] else nil
	if stored ~= nil then
		return stored
	end
	local def = SettingsData.ById[key]
	return if def then def.default else 0
end

function Settings.Init()
	Net.event("SettingsChanged")
	Net.func("SetSetting").OnServerInvoke = onSetSetting
end

function Settings.Start()
	print(("[%s] Settings: %d preferences"):format(Config.WorkingTitle, #SettingsData.Order))
end

return Settings
