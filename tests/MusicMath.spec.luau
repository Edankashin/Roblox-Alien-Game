--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Math = require(Shared.MusicMath)
local Music = require(Shared.data.Music)
local Sounds = require(Shared.data.Sounds)
local Tiers = require(Shared.data.Tiers)
local Seasons = require(Shared.data.Seasons)
local F = require(script.Parent.Fixtures)

local home = F.zero
local verdant = F.one
local frostbyte = F.two
local launchId = Music.Events.Launch
local intenseId = Music.Capture.intense
local baseId = Music.Capture.base

-- A world id the music data does not list.
local unlisted = F.zero
while Music.Worlds[unlisted] ~= nil do
	unlisted += F.one
end

-- What is going on, with every flag off; a test sets what it needs.
local function flagsFor(worldId: number): Math.Flags
	return { worldId = worldId, isNight = false, resting = false, capture = nil, event = nil, launch = false }
end

-- Runs `body` with every row's asset id at 0 (nothing chosen yet), whatever the data holds, then puts the ids back
-- even when the body fails. The tests below that need "silent" or "one row filled" use it so they keep passing after
-- the Mac session fills real ids.
local function silenced(body: () -> ())
	local saved: { [string]: number } = {}
	for id, row in pairs(Music.Rows) do
		saved[id] = row.assetId
		row.assetId = F.zero
	end
	local ok, message = pcall(body)
	for id, row in pairs(Music.Rows) do
		row.assetId = saved[id]
	end
	assert(ok, message)
end

-- Inside `silenced`: gives bed `id` a real asset id for the length of `body`.
local function withId(id: string, body: () -> ())
	local row = Music.Rows[id]
	row.assetId = F.one
	local ok, message = pcall(body)
	row.assetId = F.zero
	assert(ok, message)
end

describe("MusicMath rows", function()
	it("every row is well formed", function()
		local count = F.zero
		for _, row in pairs(Music.Rows) do
			count += F.one
			expect(row.assetId >= F.zero and row.assetId % F.one == F.zero).toEqual(true)
			expect(row.volume > F.zero and row.volume <= F.one).toEqual(true)
			expect(row.fadeIn >= F.zero and row.fadeOut >= F.zero).toEqual(true)
			expect(row.layer == "bed" or row.layer == "layer").toEqual(true)
			expect(type(row.loop)).toEqual("boolean")
		end
		expect(count > F.zero).toEqual(true)
	end)
	it("the world map, the capture pair, the events and the menu layer all name rows of the right layer", function()
		for _, beds in pairs(Music.Worlds) do
			expect(Music.Rows[beds.day].layer).toEqual("bed")
			expect(Music.Rows[beds.night].layer).toEqual("bed")
		end
		expect(Music.Rows[baseId].layer).toEqual("bed")
		expect(Music.Rows[intenseId].layer).toEqual("bed")
		for _, id in pairs(Music.Events) do
			expect(Music.Rows[id].layer).toEqual("bed")
		end
		expect(Music.Rows[Music.Resting].layer).toEqual("bed")
		expect(Music.Rows[Music.MenuLayer].layer).toEqual("layer")
		expect(table.find(Tiers.Order, Music.Capture.intenseFromTier) ~= nil).toEqual(true)
	end)
	it("the priorities run launch, intense capture, events, plain capture, resting, world beds", function()
		local function priority(id: string): number
			return Music.Rows[id].priority
		end
		local world = Math.WorldBed(verdant, false) :: string
		local lowestEvent = math.min(priority(Music.Events.Shower), priority(Music.Events.Rush))
		local highestEvent = math.max(priority(Music.Events.Shower), priority(Music.Events.Rush))
		for _, season in ipairs(Seasons.List) do
			if Music.Rows[season.id] then
				lowestEvent = math.min(lowestEvent, priority(season.id))
				highestEvent = math.max(highestEvent, priority(season.id))
			end
		end
		expect(priority(launchId) > priority(intenseId)).toEqual(true)
		expect(priority(intenseId) > highestEvent).toEqual(true)
		expect(lowestEvent > priority(baseId)).toEqual(true)
		expect(priority(baseId) > priority(Music.Resting)).toEqual(true)
		expect(priority(Music.Resting) > priority(world)).toEqual(true)
		expect(priority(Music.Events.Shower) > priority(Music.Events.Rush)).toEqual(true)
	end)
end)

describe("MusicMath state resolution", function()
	it("WorldBed is the day or night row of the world, Home on the home planet either way, nil for an unlisted world", function()
		expect(Math.WorldBed(verdant, false)).toEqual(Music.Worlds[verdant].day)
		expect(Math.WorldBed(verdant, true)).toEqual(Music.Worlds[verdant].night)
		expect(Math.WorldBed(frostbyte, false)).toEqual(Music.Worlds[frostbyte].day)
		expect(Math.WorldBed(frostbyte, true)).toEqual(Music.Worlds[frostbyte].night)
		expect(Math.WorldBed(home, false)).toEqual(Math.WorldBed(home, true))
		expect(Math.WorldBed(home, true)).toEqual(Music.Worlds[home].day)
		expect(Math.WorldBed(unlisted, false)).toEqual(nil)
		expect(Math.WorldBed(-F.one, true)).toEqual(nil)
	end)
	it("with nothing else going on the world's bed plays, day and night", function()
		local flags = flagsFor(verdant)
		expect(Math.Pick(flags)).toEqual(Music.Worlds[verdant].day)
		flags.isNight = true
		expect(Math.Pick(flags)).toEqual(Music.Worlds[verdant].night)
		expect(Math.Pick(flagsFor(home))).toEqual(Music.Worlds[home].day)
		expect(Math.Pick(flagsFor(unlisted))).toEqual(nil)
		expect(#Math.Candidates(flagsFor(unlisted))).toEqual(F.zero)
	end)
	it("a plain capture beats resting and the world bed; the intense one replaces the plain one", function()
		local flags = flagsFor(verdant)
		flags.resting = true
		expect(Math.Pick(flags)).toEqual(Music.Resting)
		flags.capture = "base"
		expect(Math.Pick(flags)).toEqual(baseId)
		flags.capture = "intense"
		expect(Math.Pick(flags)).toEqual(intenseId)
		flags.capture = nil
		flags.resting = false
		expect(Math.Pick(flags)).toEqual(Music.Worlds[verdant].day)
	end)
	it("an event beats a plain capture and resting, and the intense capture beats an event", function()
		local flags = flagsFor(verdant)
		flags.resting = true
		flags.capture = "base"
		flags.event = Music.Events.Shower
		expect(Math.Pick(flags)).toEqual(Music.Events.Shower)
		flags.capture = "intense"
		expect(Math.Pick(flags)).toEqual(intenseId)
		flags.capture = nil
		flags.resting = false
		expect(Math.Pick(flags)).toEqual(Music.Events.Shower)
	end)
	it("a Shower beats a Rush, and a Rush beats the season, whichever is named as the event", function()
		local season = Seasons.List[F.one].id
		local flags = flagsFor(verdant)
		flags.event = Math.EventState(true, true, season)
		expect(Math.Pick(flags)).toEqual(Music.Events.Shower)
		flags.event = Math.EventState(false, true, season)
		expect(Math.Pick(flags)).toEqual(Music.Events.Rush)
		flags.event = Math.EventState(false, false, season)
		expect(Math.Pick(flags)).toEqual(season)
	end)
	it("the launch beats everything and the next bed returns when it ends", function()
		local flags = flagsFor(verdant)
		flags.resting = true
		flags.capture = "intense"
		flags.event = Music.Events.Rush
		flags.launch = true
		expect(Math.Pick(flags)).toEqual(launchId)
		expect(Math.Candidates(flags)[F.one]).toEqual(launchId)
		flags.launch = false
		expect(Math.Pick(flags)).toEqual(intenseId)
	end)
	it("Candidates lists every bed once, strongest first; an unknown or layer row named as the event is skipped", function()
		local flags = flagsFor(verdant)
		flags.resting = true
		flags.capture = "base"
		flags.event = Music.Events.Rush
		local list = Math.Candidates(flags)
		expect(#list).toEqual(F.two * F.two)
		expect(list[F.one]).toEqual(Music.Events.Rush)
		expect(list[F.two]).toEqual(baseId)
		expect(list[F.two + F.one]).toEqual(Music.Resting)
		expect(list[F.two * F.two]).toEqual(Music.Worlds[verdant].day)
		flags.event = "NoSuchBed"
		expect(Math.Pick(flags)).toEqual(baseId)
		flags.event = Music.MenuLayer
		expect(Math.Pick(flags)).toEqual(baseId)
	end)
	it("Audible is nil while every id is 0, and a silent winner leaves the strongest row with an id playing", function()
		silenced(function()
			local flags = flagsFor(verdant)
			flags.capture = "base"
			expect(Math.Audible(flags)).toEqual(nil)
			expect(Math.Pick(flags)).toEqual(baseId) -- still the state the game is in
			local world = Music.Worlds[verdant].day
			withId(world, function()
				expect(Math.Pick(flags)).toEqual(baseId)
				expect(Math.Audible(flags)).toEqual(world) -- the world's bed keeps playing under a silent capture row
				Music.Rows[baseId].assetId = F.one
				expect(Math.Audible(flags)).toEqual(baseId)
				Music.Rows[baseId].assetId = F.zero
				flags.capture = nil
				expect(Math.Audible(flags)).toEqual(world)
			end)
		end)
	end)
	it("EventState picks the Shower, then the Rush, then a season that has a row, else nil", function()
		local season = Seasons.List[F.one].id
		expect(Math.EventState(true, false, nil)).toEqual(Music.Events.Shower)
		expect(Math.EventState(true, true, season)).toEqual(Music.Events.Shower)
		expect(Math.EventState(false, true, season)).toEqual(Music.Events.Rush)
		expect(Math.EventState(false, false, season)).toEqual(season)
		expect(Math.EventState(false, false, "NoSuchSeason")).toEqual(nil)
		expect(Math.EventState(false, false, Music.MenuLayer)).toEqual(nil)
		expect(Math.EventState(false, false, nil)).toEqual(nil)
	end)
	it("CaptureKind is intense from the data's tier up and base below it", function()
		local from = table.find(Tiers.Order, Music.Capture.intenseFromTier) :: number
		for index, tier in ipairs(Tiers.Order) do
			expect(Math.CaptureKind(tier)).toEqual(if index >= from then "intense" else "base")
		end
		expect(Math.CaptureKind(Music.Capture.intenseFromTier)).toEqual("intense")
		expect(Math.CaptureKind(Tiers.Order[from - F.one])).toEqual("base")
		expect(Math.CaptureKind("NoSuchTier")).toEqual("base")
		expect(Math.CaptureKind("")).toEqual("base")
	end)
end)

describe("MusicMath mixing", function()
	it("Step moves toward the target by dt over the seconds and never past it", function()
		local seconds = Music.Rows[Music.Worlds[verdant].day].fadeIn
		local half = seconds / F.two
		expect(Math.Step(F.zero, F.one, half, seconds)).toBeClose(F.half, F.tolerance)
		expect(Math.Step(F.half, F.one, half, seconds)).toEqual(F.one)
		expect(Math.Step(F.half, F.one, seconds * F.two, seconds)).toEqual(F.one)
		expect(Math.Step(F.one, F.zero, half, seconds)).toBeClose(F.half, F.tolerance)
		expect(Math.Step(F.quarter, F.zero, seconds, seconds)).toEqual(F.zero)
		expect(Math.Step(F.zero, F.one, half, F.zero)).toEqual(F.one) -- a fade of zero seconds jumps
		expect(Math.Step(F.one, F.one, half, seconds)).toEqual(F.one)
	end)
	it("Curve runs 0 to 1 and a bed fading in against one fading out keeps constant power", function()
		expect(Math.Curve(F.zero)).toEqual(F.zero)
		expect(Math.Curve(F.one)).toBeClose(F.one, F.tolerance)
		expect(Math.Curve(-F.one)).toEqual(F.zero)
		expect(Math.Curve(F.two)).toBeClose(F.one, F.tolerance)
		for _, level in ipairs({ F.quarter, F.half, F.one - F.quarter }) do
			expect(Math.Curve(level) ^ F.two + Math.Curve(F.one - level) ^ F.two).toBeClose(F.one, F.tolerance)
		end
	end)
	it("a crossfade over equal times keeps the summed power constant through the whole fade", function()
		local seconds = Music.Rows[Music.Worlds[verdant].day].fadeIn
		local dt = seconds / (F.two * F.two * F.two * F.two)
		local incoming, outgoing = F.zero, F.one
		while incoming < F.one do
			incoming = Math.Step(incoming, F.one, dt, seconds)
			outgoing = Math.Step(outgoing, F.zero, dt, seconds)
			expect(Math.Curve(incoming) ^ F.two + Math.Curve(outgoing) ^ F.two).toBeClose(F.one, F.tolerance)
		end
		expect(outgoing).toEqual(F.zero)
	end)
	it("MenuGain falls to the layer row's volume and DuckGain to the ducking gain", function()
		expect(Math.MenuGain(F.zero)).toEqual(F.one)
		expect(Math.MenuGain(F.one)).toBeClose(Music.Rows[Music.MenuLayer].volume, F.tolerance)
		expect(Math.MenuGain(F.half) < F.one and Math.MenuGain(F.half) > Music.Rows[Music.MenuLayer].volume).toEqual(true)
		expect(Math.DuckGain(F.zero)).toEqual(F.one)
		expect(Math.DuckGain(F.one)).toBeClose(Music.Ducking.Gain, F.tolerance)
	end)
	it("BedVolume multiplies the row's volume by the curve, the menu layer and the duck; the launch bed is not ducked", function()
		local id = Music.Worlds[verdant].day
		local row = Music.Rows[id]
		expect(Math.BedVolume(id, F.zero, F.zero, F.zero)).toEqual(F.zero)
		expect(Math.BedVolume(id, F.one, F.zero, F.zero)).toBeClose(row.volume, F.tolerance)
		expect(Math.BedVolume(id, F.one, F.one, F.zero)).toBeClose(row.volume * Math.MenuGain(F.one), F.tolerance)
		expect(Math.BedVolume(id, F.one, F.zero, F.one)).toBeClose(row.volume * Music.Ducking.Gain, F.tolerance)
		expect(Math.BedVolume(launchId, F.one, F.zero, F.one)).toBeClose(Music.Rows[launchId].volume, F.tolerance)
		expect(Math.BedVolume("NoSuchBed", F.one, F.zero, F.zero)).toEqual(F.zero)
	end)
end)

describe("MusicMath stingers", function()
	it("every Reveal tier and the launch hit have a Sounds slot and a ducking length that rises with the tier", function()
		local previous = F.zero
		for _, tier in ipairs(Tiers.Order) do
			local key = "Reveal." .. tier
			expect(Math.SoundId(key)).toEqual(Sounds.Reveal[tier])
			expect(Music.Ducking.StingerSeconds[key] ~= nil).toEqual(true)
			expect(Math.StingerSeconds(key) >= previous).toEqual(true)
			previous = Math.StingerSeconds(key)
		end
		expect(Math.SoundId("Launch")).toEqual(Sounds.Launch)
		expect(Math.StingerSeconds("Launch")).toEqual(Music.Ducking.StingerSeconds.Launch)
	end)
	it("an unlisted stinger ducks for the default length and an unknown path has no id", function()
		expect(Math.StingerSeconds("Nope")).toEqual(Music.Ducking.DefaultStingerSeconds)
		expect(Math.SoundId("Nope")).toEqual("")
		expect(Math.SoundId("Reveal.Nope")).toEqual("")
		expect(Math.SoundId("Reveal")).toEqual("")
		expect(Math.SoundId("Launch.Deeper")).toEqual("")
		expect(Math.SoundId("")).toEqual("")
	end)
	it("IsRealId rejects the empty string and the zero placeholder", function()
		expect(Math.IsRealId("")).toEqual(false)
		expect(Math.IsRealId("rbxassetid://" .. tostring(F.zero))).toEqual(false)
		expect(Math.IsRealId("rbxassetid://" .. tostring(F.one))).toEqual(true)
	end)
end)
return true
