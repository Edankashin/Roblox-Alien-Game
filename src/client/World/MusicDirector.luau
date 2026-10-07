--!strict
-- StarterPlayerScripts.Client.World.MusicDirector: the game's music, pure presentation. The bootstrap tells it what
-- is going on (the world and the clock, a catch bar, a running event, resting, the launch, a panel open) and it
-- plays the one bed that wins, crossfaded, from the rows in Shared/data/Music (rules in Shared/MusicMath).
--   * One bed at a time, by priority: launch > intense capture > events (Shower, Rush, season) > plain capture >
--     resting > the world's day or night bed (the home planet's Home). A change crossfades: the old bed fades out
--     over its fadeOut while the new one fades in over its fadeIn, on an equal-power curve.
--   * A "layer" row (the menu modifier) does not choose a bed: while a panel is open it lowers the active bed's gain
--     to the row's volume, and lifts it again when the panel closes.
--   * A stinger (Stinger, a path into data/Sounds) plays its one-shot through the UI group and ducks the bed for its
--     length (Music.Ducking). A silent stinger (id 0) neither plays nor ducks.
--   * A row with assetId 0 is silent but still tracked: the Studio Output line "[title] Music: <state>" prints the
--     state the game is in either way. If the winning row is silent, the strongest row below it that has an id
--     keeps playing, so tracks can be filled in one at a time. Nothing is loaded for an id of 0.
--   * The player's Music level (Prefs, data/Settings "Music") is the SoundGroup's volume; the rows' volumes are the
--     mix underneath it.
-- One Sound per voice under a SoundGroup "Music" in SoundService, a voice destroyed when it has faded out. Fades are
-- stepped on Heartbeat only while something is moving, so an idle mix costs nothing. Nothing here decides anything.

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("data"):WaitForChild("Config"))
local Music = require(Shared:WaitForChild("data"):WaitForChild("Music"))
local MusicMath = require(Shared:WaitForChild("MusicMath"))
local Builder = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Builder"))

local MusicDirector = {}

local GROUP_NAME = "Music"
local ASSET_PREFIX = "rbxassetid://"

type Voice = { sound: Sound, level: number }

local started = false
local group: SoundGroup? = nil
local volumeScale = 1 -- the player's Music level (Prefs.Multiplier), the group's volume
local voices: { [string]: Voice } = {} -- bed row id -> its Sound and fade level (0 silent, 1 fully in)
local connection: RBXScriptConnection? = nil

-- What is going on.
local flags: MusicMath.Flags = { worldId = 0, isNight = false, resting = false, capture = nil, event = nil, launch = false }
local worldSet = false -- SetWorldState has been called: until then no bed is chosen
local menuOpen = false
local menuLevel = 0 -- 0 closed .. 1 fully applied, eased
local duckLevel = 0 -- 0 none .. 1 fully ducked, eased
local duckUntil = 0 -- os.clock() until which a stinger holds the duck
local audible: string? = nil -- the bed row the voices fade toward
local announced = false
local lastState: string? = nil -- the last state printed

-- Studio-only: the state the game is in, whenever it changes.
local function announce(state: string?)
	if announced and state == lastState then
		return
	end
	announced = true
	lastState = state
	if RunService:IsStudio() then
		print(("[%s] Music: %s"):format(Config.WorkingTitle, state or "none"))
	end
end

local function destroyVoice(id: string)
	local voice = voices[id]
	voices[id] = nil
	if voice then
		voice.sound:Stop()
		voice.sound:Destroy()
	end
end

-- Builds the Sound for bed `id` (only for a real asset id) and starts it silent, to be faded in by the stepper.
local function createVoice(id: string)
	local row = Music.Rows[id]
	local parent = group
	if row == nil or parent == nil or row.assetId == 0 then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = id
	sound.SoundId = ASSET_PREFIX .. ("%d"):format(row.assetId)
	sound.Looped = row.loop
	sound.Volume = 0
	sound.SoundGroup = parent
	sound.Parent = parent
	sound:Play()
	voices[id] = { sound = sound, level = 0 }
end

-- One Heartbeat of the mix: eases the menu layer and the duck, moves every voice toward its target, applies the
-- volumes. Returns true while anything is still moving.
local function step(dt: number): boolean
	local moving = false

	local menuRow = Music.Rows[Music.MenuLayer]
	local menuTarget = if menuOpen then 1 else 0
	if menuLevel ~= menuTarget then
		local seconds = if menuRow == nil then 0 elseif menuOpen then menuRow.fadeIn else menuRow.fadeOut
		menuLevel = MusicMath.Step(menuLevel, menuTarget, dt, seconds)
		if menuLevel ~= menuTarget then
			moving = true
		end
	end

	local ducked = os.clock() < duckUntil
	local duckTarget = if ducked then 1 else 0
	if duckLevel ~= duckTarget then
		local seconds = if ducked then Music.Ducking.AttackSeconds else Music.Ducking.RestoreSeconds
		duckLevel = MusicMath.Step(duckLevel, duckTarget, dt, seconds)
	end
	if ducked or duckLevel ~= 0 then
		moving = true
	end

	for id, voice in pairs(voices) do
		local row = Music.Rows[id]
		local target = if id == audible then 1 else 0
		local seconds = if target == 1 then row.fadeIn else row.fadeOut
		voice.level = MusicMath.Step(voice.level, target, dt, seconds)
		voice.sound.Volume = MusicMath.BedVolume(id, voice.level, menuLevel, duckLevel)
		if target == 0 and voice.level <= 0 then
			destroyVoice(id)
		elseif voice.level ~= target then
			moving = true
		end
	end
	return moving
end

-- Starts stepping the mix (a no-op when it already runs); the connection drops itself when everything has settled.
local function wake()
	if connection ~= nil or not started then
		return
	end
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if not step(dt) then
			local existing = connection
			connection = nil
			if existing then
				existing:Disconnect()
			end
		end
	end)
end

-- Re-reads the flags: prints the state when it changed and, when the bed to hear changed, builds its voice and
-- sets the crossfade going.
local function reconcile()
	if not started or not worldSet then
		return
	end
	announce(MusicMath.Pick(flags))
	local bed = MusicMath.Audible(flags)
	if bed == audible then
		return
	end
	audible = bed
	if bed ~= nil and voices[bed] == nil then
		createVoice(bed)
	end
	wake()
end

-- Public API -------------------------------------------------------------

-- Builds the "Music" SoundGroup and begins following the state it is told. Safe to call twice.
function MusicDirector.Start()
	if started then
		return
	end
	started = true
	local soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = GROUP_NAME
	soundGroup.Volume = volumeScale
	soundGroup.Parent = SoundService
	group = soundGroup
	reconcile()
end

-- The place's world (0 is the home planet) and whether the clock says night: picks that world's day or night bed.
function MusicDirector.SetWorldState(worldId: number, isNight: boolean)
	worldSet = true
	flags.worldId = worldId
	flags.isNight = isNight
	reconcile()
end

-- The catch bar: "base" for a plain catch, "intense" for Legendary and above, nil when no catch is open.
function MusicDirector.SetCapture(kind: MusicMath.CaptureKind?)
	flags.capture = kind
	reconcile()
end

-- The running event's row id (data/Music Events, or the season's id); nil when none runs. The caller picks which
-- event applies (MusicMath.EventState); the director just plays it.
function MusicDirector.SetEvent(stateName: string?)
	flags.event = stateName
	reconcile()
end

-- Whether the launch sequence is playing: the launch cue takes the mix until it ends.
function MusicDirector.SetLaunch(active: boolean)
	flags.launch = active
	reconcile()
end

-- Whether the crew is resting (the quiet bed).
function MusicDirector.SetResting(resting: boolean)
	flags.resting = resting
	reconcile()
end

-- Whether a menu or panel is open: the menu layer lowers the active bed while it is.
function MusicDirector.SetMenuOpen(open: boolean)
	if menuOpen == open then
		return
	end
	menuOpen = open
	wake()
end

-- Plays the one-shot at `soundKey` (a path into data/Sounds: "Reveal.Legendary", "Launch") and ducks the bed for its
-- length. A silent slot (id 0) plays nothing and ducks nothing; Studio prints it either way.
function MusicDirector.Stinger(soundKey: string)
	local id = MusicMath.SoundId(soundKey)
	local real = MusicMath.IsRealId(id)
	if RunService:IsStudio() then
		print(("[%s] Music: stinger %s%s"):format(Config.WorkingTitle, soundKey, if real then "" else " (silent)"))
	end
	if not real then
		return
	end
	Builder.playSound(id)
	duckUntil = math.max(duckUntil, os.clock() + MusicMath.StingerSeconds(soundKey))
	wake()
end

-- The player's Music level (Prefs applies it): the SoundGroup's volume, now and whenever Start builds it later.
function MusicDirector.SetVolumeScale(scale: number)
	volumeScale = math.max(0, scale)
	local existing = group
	if existing then
		existing.Volume = volumeScale
	end
end

return MusicDirector
