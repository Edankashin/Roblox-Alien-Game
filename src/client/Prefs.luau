--!strict
-- StarterPlayerScripts.Client.Prefs: the one place the client reads the player's preferences. The
-- server owns them (data/Settings.luau names the keys and their values; SetSetting stores one and
-- SettingsChanged pushes the whole table back), State mirrors that table under its "settings" topic,
-- and this module turns the mirror into effects: the UI SoundGroup's volume (Builder.SetSoundVolume),
-- the ambience group's volume (Ambience.SetVolumeScale), the music group's volume (MusicDirector.SetVolumeScale), and the booleans the renderers and the
-- camera ask for. Reduced motion also follows the system switch (UserGameSettings.ReducedMotion, read
-- under pcall: it is missing on some clients). Reads before the profile arrives answer the data
-- defaults. Nothing here decides anything: every value is whatever the server said last.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("data"):WaitForChild("Settings"))
local State = require(script.Parent:WaitForChild("State"))
local Builder = require(script.Parent:WaitForChild("UI"):WaitForChild("Builder"))
local Ambience = require(script.Parent:WaitForChild("World"):WaitForChild("Ambience"))
local MusicDirector = require(script.Parent:WaitForChild("World"):WaitForChild("MusicDirector"))

local Prefs = {}

-- data/Settings keys this module applies itself; the rest are read by their owners.
local SOUNDS_KEY = "Sounds"
local AMBIENCE_KEY = "Ambience"
local MUSIC_KEY = "Music"
local REDUCED_MOTION_KEY = "ReducedMotion"
local SILHOUETTES_KEY = "Silhouettes"

local changed = Instance.new("BindableEvent")
local started = false

-- The system's reduced-motion switch; false when it cannot be read.
local function systemReducedMotion(): boolean
	local ok, value = pcall(function(): boolean
		return UserSettings():GetService("UserGameSettings").ReducedMotion
	end)
	return ok and value == true
end

-- The stored number for `key`: a 0-based index into the key's levels, or 0/1 for a toggle. The data
-- default until the profile arrives (State seeds its mirror from the defaults); 0 for an unknown key.
function Prefs.Level(key: string): number
	local value = State.GetSettings()[key]
	if type(value) == "number" then
		return value
	end
	local def = Settings.ById[key]
	return if def then def.default else 0
end

-- The multiplier `key` stands for: levels[index + 1] for a "level" key (1 when the index is out of
-- range), the 0/1 itself for a toggle, 1 for a key the data does not name.
function Prefs.Multiplier(key: string): number
	local def = Settings.ById[key]
	if not def then
		return 1
	end
	local level = Prefs.Level(key)
	local levels = def.levels
	if def.kind == "level" and levels then
		local multiplier = levels[math.floor(level) + 1]
		return if multiplier ~= nil then multiplier else 1
	end
	return level
end

-- The profile toggle or the system switch: either one shortens tweens and skips shakes.
function Prefs.ReducedMotion(): boolean
	return Prefs.Level(REDUCED_MOTION_KEY) == 1 or systemReducedMotion()
end

-- Uncaught species render as dark silhouettes until approached.
function Prefs.Silhouettes(): boolean
	return Prefs.Level(SILHOUETTES_KEY) == 1
end

-- Runs after every change has been applied: a SettingsChanged push, the profile, the system switch.
function Prefs.OnChanged(callback: () -> ()): RBXScriptConnection
	return changed.Event:Connect(callback)
end

local function apply()
	Builder.SetSoundVolume(Prefs.Multiplier(SOUNDS_KEY))
	Ambience.SetVolumeScale(Prefs.Multiplier(AMBIENCE_KEY))
	MusicDirector.SetVolumeScale(Prefs.Multiplier(MUSIC_KEY))
	changed:Fire()
end

-- Applies the current values at once, then again on every change of the mirror or the system switch.
function Prefs.Start()
	if started then
		return
	end
	started = true
	State.OnChanged("settings", apply)
	pcall(function()
		UserSettings():GetService("UserGameSettings"):GetPropertyChangedSignal("ReducedMotion"):Connect(apply)
	end)
	apply()
end

return Prefs
