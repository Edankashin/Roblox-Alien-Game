--!strict
-- ReplicatedStorage.Shared.MusicMath: the music director's rules (data/Music), shared so the client's director and the
-- headless tests agree. Pure functions of the data tables and the flags passed in; nothing here touches a Sound, a
-- clock or the camera. Which bed wins: Candidates lists every bed that applies to the flags, strongest first (the
-- row's priority; ties keep the order launch, event, capture, resting, world); Pick is the first, the state the
-- game is in; Audible is the first with a real asset id, so a row still at 0 never silences the bed under it.
-- Step and Curve are the mixer's fade: a level moves linearly in the row's seconds and the gain follows an
-- equal-power curve, so two beds crossing do not dip in loudness.

local Music = require(script.Parent.data.Music)
local Sounds = require(script.Parent.data.Sounds)
local Tiers = require(script.Parent.data.Tiers)

local MusicMath = {}

export type CaptureKind = "base" | "intense"

-- What is going on: the place's world (0 is the home), the clock's night flag, resting, the catch bar's kind (nil
-- when none is open), the running event's row id (nil when none) and whether the launch sequence plays.
export type Flags = {
	worldId: number,
	isNight: boolean,
	resting: boolean,
	capture: CaptureKind?,
	event: string?,
	launch: boolean,
}

local EMPTY_ID = "rbxassetid://0"

-- The row id of the world bed for this world and time of day, or nil when the world has no music yet.
function MusicMath.WorldBed(worldId: number, isNight: boolean): string?
	local beds = Music.Worlds[worldId]
	if not beds then
		return nil
	end
	return if isNight then beds.night else beds.day
end

-- Puts `id` into `list` before the first entry of lower priority, so equal priorities keep their insertion order.
local function insertByPriority(list: { string }, id: string)
	local priority = Music.Rows[id].priority
	for index, existing in ipairs(list) do
		if Music.Rows[existing].priority < priority then
			table.insert(list, index, id)
			return
		end
	end
	table.insert(list, id)
end

-- Every bed that applies to the flags, strongest first. An id with no row, or a row that is a layer, is skipped.
function MusicMath.Candidates(flags: Flags): { string }
	local list: { string } = {}
	local function add(id: string?)
		if id == nil then
			return
		end
		local row = Music.Rows[id]
		if row ~= nil and row.layer == "bed" then
			insertByPriority(list, id)
		end
	end
	if flags.launch then
		add(Music.Events.Launch)
	end
	add(flags.event)
	if flags.capture == "intense" then
		add(Music.Capture.intense)
	elseif flags.capture == "base" then
		add(Music.Capture.base)
	end
	if flags.resting then
		add(Music.Resting)
	end
	add(MusicMath.WorldBed(flags.worldId, flags.isNight))
	return list
end

-- The state the game is in: the strongest candidate, nil when nothing applies.
function MusicMath.Pick(flags: Flags): string?
	return MusicMath.Candidates(flags)[1]
end

-- The bed to hear: the strongest candidate that has a real asset id, nil when none does.
function MusicMath.Audible(flags: Flags): string?
	for _, id in ipairs(MusicMath.Candidates(flags)) do
		if Music.Rows[id].assetId ~= 0 then
			return id
		end
	end
	return nil
end

-- The event row the running events ask for: a Meteor Shower first, then a Catch Rush, then the season (`seasonId`,
-- already judged eligible for this world by the caller); nil when none runs or the season has no music row.
function MusicMath.EventState(shower: boolean, rush: boolean, seasonId: string?): string?
	if shower then
		return Music.Events.Shower
	end
	if rush then
		return Music.Events.Rush
	end
	if seasonId ~= nil then
		local row = Music.Rows[seasonId]
		if row ~= nil and row.layer == "bed" then
			return seasonId
		end
	end
	return nil
end

-- Which catch music a tier opens with: "intense" from Music.Capture.intenseFromTier up (Legendary, Cosmic, Secret),
-- "base" below it and for a tier the data does not list.
function MusicMath.CaptureKind(tier: string): CaptureKind
	local from = table.find(Tiers.Order, Music.Capture.intenseFromTier)
	local at = table.find(Tiers.Order, tier)
	if from ~= nil and at ~= nil and at >= from then
		return "intense"
	end
	return "base"
end

-- One step of a fade: `current` moves toward `target` by dt / seconds (a fade of zero seconds jumps), never past it.
function MusicMath.Step(current: number, target: number, dt: number, seconds: number): number
	if seconds <= 0 then
		return target
	end
	local delta = dt / seconds
	if current < target then
		return math.min(target, current + delta)
	end
	return math.max(target, current - delta)
end

-- The equal-power gain of a fade level (0..1): sin(level * pi / 2), so a bed fading in and one fading out over the
-- same time sum to constant power.
function MusicMath.Curve(level: number): number
	return math.sin(math.clamp(level, 0, 1) * math.pi / 2)
end

-- The gain multiplier of the menu layer at `level` (0 = closed, 1 = fully applied): from 1 down to the layer row's volume.
function MusicMath.MenuGain(level: number): number
	local layer = Music.Rows[Music.MenuLayer]
	local floor = if layer then layer.volume else 1
	return 1 - math.clamp(level, 0, 1) * (1 - floor)
end

-- The gain multiplier of a stinger's duck at `level` (0 = none, 1 = fully ducked): from 1 down to Ducking.Gain.
function MusicMath.DuckGain(level: number): number
	return 1 - math.clamp(level, 0, 1) * (1 - Music.Ducking.Gain)
end

-- The Sound volume of bed `id` before the player's Music preference: the row's volume times the fade curve, the
-- menu layer and the duck. The launch bed owns the mix, so a stinger's duck does not touch it.
function MusicMath.BedVolume(id: string, level: number, menuLevel: number, duckLevel: number): number
	local row = Music.Rows[id]
	if row == nil then
		return 0
	end
	local duck = if id == Music.Events.Launch then 1 else MusicMath.DuckGain(duckLevel)
	return row.volume * MusicMath.Curve(level) * MusicMath.MenuGain(menuLevel) * duck
end

-- How long a stinger (a path into data/Sounds, "Reveal.Legendary" or "Launch") ducks the bed.
function MusicMath.StingerSeconds(key: string): number
	return Music.Ducking.StingerSeconds[key] or Music.Ducking.DefaultStingerSeconds
end

-- The asset id string at a path into data/Sounds ("Reveal.Legendary", "Launch"); "" when the path names nothing
-- or something that is not an id. A placeholder is returned as it is (rbxassetid://0).
function MusicMath.SoundId(key: string): string
	local node: any = Sounds
	for part in string.gmatch(key, "[^%.]+") do
		if type(node) ~= "table" then
			return ""
		end
		node = node[part]
	end
	return if type(node) == "string" then node else ""
end

-- Whether a Sounds id is a real one (not empty and not the rbxassetid://0 placeholder).
function MusicMath.IsRealId(id: string): boolean
	return id ~= "" and id ~= EMPTY_ID
end

return MusicMath
