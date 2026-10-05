--!strict
-- StarterPlayerScripts.Client.World.Ambience: the looping background sound. One looped Sound per
-- Sounds.Ambience entry that has a real id, all under a SoundGroup "Ambience" in SoundService whose
-- Volume is Sounds.Volume.Ambience times the player's Ambience level (SetVolumeScale, from Prefs). The active loop follows State.GetConditions() by PRIORITY (a
-- Meteor Shower beats the world's special weather beats Night beats Day), and a change crossfades the
-- old loop out and the new one in over Config.AmbienceFadeSeconds. With every id still a placeholder
-- (rbxassetid://0) nothing is created and nothing plays. Pure presentation: the conditions are the
-- server's; this only picks which loop to hear.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("data"):WaitForChild("Sounds"))
local State = require(script.Parent.Parent:WaitForChild("State"))

local Ambience = {}

local EMPTY_SOUND = "rbxassetid://0"
local GROUP_NAME = "Ambience"
-- Which loop wins when several conditions hold at once: the first entry here that is both an active
-- condition and a loop with a real id. "Rain" is World 1's special weather; later worlds add theirs
-- to Sounds.Ambience and to this list.
local PRIORITY: { string } = { "Shower", "Rain", "Night", "Day" }

local group: SoundGroup? = nil
local loops: { [string]: Sound } = {} -- condition id -> its looped Sound (only real ids)
local fades: { [string]: Tween } = {} -- the volume tween in flight per loop
local active: string? = nil
local connections: { RBXScriptConnection } = {}
local running = false
local volumeScale = 1 -- the player's Ambience level (Prefs.Multiplier), on top of Sounds.Volume.Ambience

-- Helpers ----------------------------------------------------------------

local function ambienceIds(): { [string]: string }
	return Sounds.Ambience
end

-- The loop to hear right now, or nil when no active condition has one.
local function pick(): string?
	local activeSet: { [string]: boolean } = {}
	for _, condition in ipairs(State.GetConditions()) do
		activeSet[condition] = true
	end
	for _, id in ipairs(PRIORITY) do
		if loops[id] and activeSet[id] then
			return id
		end
	end
	return nil
end

-- Eases one loop's Volume to `volume`; onDone runs only if the fade finishes (a newer fade cancels it).
local function fadeTo(id: string, volume: number, onDone: (() -> ())?)
	local sound = loops[id]
	if not sound then
		return
	end
	local previous = fades[id]
	if previous then
		previous:Cancel()
	end
	local info = TweenInfo.new(Config.AmbienceFadeSeconds, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(sound, info, { Volume = volume })
	fades[id] = tween
	tween.Completed:Once(function(state: Enum.PlaybackState)
		if fades[id] == tween then
			fades[id] = nil
		end
		if state == Enum.PlaybackState.Completed and onDone then
			onDone()
		end
	end)
	tween:Play()
end

-- Re-reads the conditions and crossfades if the winning loop changed.
local function apply()
	local next = pick()
	if next == active then
		return
	end
	local previous = active
	active = next
	if previous then
		local old = loops[previous]
		fadeTo(previous, 0, function()
			if active ~= previous and old then
				old:Stop()
			end
		end)
	end
	if next then
		local sound = loops[next]
		if sound and not sound.IsPlaying then
			sound.Volume = 0
			sound:Play()
		end
		fadeTo(next, 1)
	end
end

-- Public API -------------------------------------------------------------

-- Builds the SoundGroup and the loops with real ids, then follows the clock and shower pushes. With
-- no real ids it builds nothing and returns at once.
function Ambience.Start()
	if running then
		return
	end
	running = true

	local soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = GROUP_NAME
	soundGroup.Volume = Sounds.Volume.Ambience * volumeScale
	soundGroup.Parent = SoundService
	group = soundGroup

	loops = {}
	for id, assetId in pairs(ambienceIds()) do
		if assetId ~= "" and assetId ~= EMPTY_SOUND then
			local sound = Instance.new("Sound")
			sound.Name = id
			sound.SoundId = assetId
			sound.Looped = true
			sound.Volume = 0
			sound.SoundGroup = soundGroup
			sound.Parent = soundGroup
			loops[id] = sound
		end
	end
	if next(loops) == nil then
		return -- every ambience is still a placeholder: nothing to crossfade
	end

	table.insert(connections, State.OnChanged("clock", apply))
	table.insert(connections, State.OnChanged("shower", apply))
	apply()
end

-- The player's Ambience level: the group's volume becomes Sounds.Volume.Ambience * scale, now and
-- whenever Start builds the group later.
function Ambience.SetVolumeScale(scale: number)
	volumeScale = math.max(0, scale)
	local existing = group
	if existing then
		existing.Volume = Sounds.Volume.Ambience * volumeScale
	end
end

-- Stops every loop at once and removes the group.
function Ambience.Stop()
	if not running then
		return
	end
	running = false
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}
	for _, tween in pairs(fades) do
		tween:Cancel()
	end
	fades = {}
	for _, sound in pairs(loops) do
		sound:Stop()
	end
	loops = {}
	active = nil
	local existing = group
	group = nil
	if existing then
		existing:Destroy()
	end
end

return Ambience
