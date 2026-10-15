--!strict
-- The per-species effects (data/Effects) and the rules the client's World.SpeciesFx draws them by (Shared/EffectsMath): the
-- table shapes, the tier gate (LayersFor), the caps (Resolve, PickActive and the beam and light limits), the ground ring, the
-- dark variant, the idle, beam and orbit clocks and the sound clock (the beat, the spacing per alien and the per-second cap).
-- tools/lint_data.py checks the same data from the Python side.
local Shared = game:GetService("ReplicatedStorage").Shared
local EffectsMath = require(Shared.EffectsMath)
local Effects = require(Shared.data.Effects)
local Species = require(Shared.data.Species)
local Tiers = require(Shared.data.Tiers)
local Icons = require(Shared.data.Icons)
local Sounds = require(Shared.data.Sounds)

local KINDS = { Emitter = true, Beam = true, Light = true, Trail = true, Orbit = true }
local MOTIONS = { Still = true, Bob = true, Hover = true, Flap = true, Spin = true, Breathe = true }

local function count(layers, kind: string): number
	local total = 0
	for _, layer in ipairs(layers) do
		if layer.kind == kind then
			total += 1
		end
	end
	return total
end

describe("the data", function()
	it("has a row for every species and no row for an unknown one", function()
		for _, def in ipairs(Species.List) do
			expect(Effects.Species[def.id] ~= nil).toEqual(true)
		end
		for id in pairs(Effects.Species) do
			expect(Species.ById[id] ~= nil).toEqual(true)
		end
	end)

	it("gives every layer a known kind, a hex colour, a real region and a real sprite", function()
		for id, fx in pairs(Effects.Species) do
			expect(#fx.layers > 0).toEqual(true)
			for _, layer in ipairs(fx.layers) do
				expect(KINDS[layer.kind]).toEqual(true)
				expect(#layer.color).toEqual(6)
				expect(tonumber(layer.color, 16) ~= nil).toEqual(true)
				expect(Effects.Attach[layer.at] ~= nil).toEqual(true)
				if layer.to ~= nil then
					expect(Effects.Attach[layer.to] ~= nil).toEqual(true)
				end
				if layer.sprite ~= nil then
					expect(Icons.Particles[layer.sprite] ~= nil).toEqual(true)
				end
			end
			expect(MOTIONS[fx.idle.kind]).toEqual(true)
			expect(id ~= "").toEqual(true)
		end
	end)

	it("names the five regions the brief asks for", function()
		for _, region in ipairs({ "Top", "Back", "Tail", "Eyes", "Feet" }) do
			expect(Effects.Attach[region] ~= nil).toEqual(true)
		end
	end)

	it("keeps the Thunderhog's lightning between two quill regions, striking every two seconds", function()
		local beam = Effects.Species.Thunderhog.layers[1]
		expect(beam.kind).toEqual("Beam")
		expect(beam.at ~= beam.to).toEqual(true)
		expect(beam.flicker).toEqual(2)
		expect(Effects.Species.Thunderhog.layers[2].kind).toEqual("Emitter")
	end)

	it("gives a Flap species its wing part names, and nobody else", function()
		for _, fx in pairs(Effects.Species) do
			if fx.idle.kind == "Flap" then
				expect(fx.idle.parts ~= nil and #fx.idle.parts > 0).toEqual(true)
			else
				expect(fx.idle.parts == nil).toEqual(true)
			end
		end
	end)

	it("has a Spin that turns whole circles, so its loop is seamless", function()
		for _, fx in pairs(Effects.Species) do
			if fx.idle.kind == "Spin" then
				expect(fx.idle.amplitude % 360).toEqual(0)
			end
		end
	end)
end)

describe("the tier ladder", function()
	it("has a rule for every tier and none for a tier that does not exist", function()
		for _, tier in ipairs(Tiers.Order) do
			expect(Effects.Tiers[tier] ~= nil).toEqual(true)
		end
		for tier in pairs(Effects.Tiers) do
			expect(Tiers.Tiers[tier] ~= nil).toEqual(true)
		end
	end)

	it("never falls going up Tiers.Order", function()
		local previous = nil
		for _, tier in ipairs(Tiers.Order) do
			local rule = Effects.Tiers[tier]
			if previous then
				expect(rule.layersAllowed >= previous.layersAllowed).toEqual(true)
				expect(rule.rateScale >= previous.rateScale).toEqual(true)
				expect(rule.sizeScale >= previous.sizeScale).toEqual(true)
				expect(rule.lightScale >= previous.lightScale).toEqual(true)
				for _, flag in ipairs({ "trail", "orbit", "groundRing", "dark" }) do
					expect(previous[flag] == true and rule[flag] ~= true).toEqual(false)
				end
			end
			previous = rule
		end
	end)

	it("lets Common and Uncommon draw one layer, Rare two, Epic three", function()
		expect(Effects.Tiers.Common.layersAllowed).toEqual(1)
		expect(Effects.Tiers.Uncommon.layersAllowed).toEqual(1)
		expect(Effects.Tiers.Rare.layersAllowed).toEqual(2)
		expect(Effects.Tiers.Epic.layersAllowed).toEqual(3)
	end)

	it("adds the ring from Legendary, the orbit and trail from Cosmic, the dark variant at Secret only", function()
		expect(Effects.Tiers.Epic.groundRing).toEqual(false)
		expect(Effects.Tiers.Legendary.groundRing).toEqual(true)
		expect(Effects.Tiers.Legendary.orbit).toEqual(false)
		expect(Effects.Tiers.Cosmic.orbit).toEqual(true)
		expect(Effects.Tiers.Cosmic.trail).toEqual(true)
		expect(Effects.Tiers.Cosmic.dark).toEqual(false)
		expect(Effects.Tiers.Secret.dark).toEqual(true)
	end)

	it("defines at least as many layers for a species as its own tier draws, up to four", function()
		for _, def in ipairs(Species.List) do
			local wanted = math.min(Effects.Tiers[def.tier].layersAllowed, 4)
			expect(#Effects.Species[def.id].layers >= wanted).toEqual(true)
		end
	end)
end)

describe("LayersFor", function()
	it("returns nothing for an unknown species or tier", function()
		expect(#EffectsMath.LayersFor("Nobody", "Epic")).toEqual(0)
		expect(#EffectsMath.LayersFor("Thunderhog", "Mythic")).toEqual(0)
	end)

	it("takes the first layers a tier allows, in the data's order", function()
		local common = EffectsMath.LayersFor("Thunderhog", "Common")
		expect(#common).toEqual(1)
		expect(common[1].kind).toEqual("Beam")
		expect(#EffectsMath.LayersFor("Thunderhog", "Rare")).toEqual(2)
		local epic = EffectsMath.LayersFor("Thunderhog", "Epic")
		expect(#epic).toEqual(3)
		expect(epic[1].kind).toEqual("Beam")
		expect(epic[2].kind).toEqual("Emitter")
		expect(epic[3].kind).toEqual("Light")
	end)

	it("never draws more layers going up the ladder, for any species", function()
		for _, def in ipairs(Species.List) do
			local previous = 0
			for _, tier in ipairs(Tiers.Order) do
				local drawn = #EffectsMath.LayersFor(def.id, tier)
				expect(drawn >= previous).toEqual(true)
				previous = drawn
			end
		end
	end)

	it("makes the species' own tier the grandest: more layers on average at each step up", function()
		local sums: { [string]: number } = {}
		local counts: { [string]: number } = {}
		for _, def in ipairs(Species.List) do
			sums[def.tier] = (sums[def.tier] or 0) + #EffectsMath.LayersFor(def.id, def.tier)
			counts[def.tier] = (counts[def.tier] or 0) + 1
		end
		local previous = 0
		for _, tier in ipairs(Tiers.Order) do
			expect(counts[tier] ~= nil).toEqual(true)
			local average = (sums[tier] :: number) / (counts[tier] :: number)
			expect(average >= previous).toEqual(true)
			previous = average
		end
		local common = (sums.Common :: number) / (counts.Common :: number)
		local secret = (sums.Secret :: number) / (counts.Secret :: number)
		expect(secret > common).toEqual(true)
	end)

	it("holds every species at every tier to the beam and light caps", function()
		for _, def in ipairs(Species.List) do
			for _, tier in ipairs(Tiers.Order) do
				local layers = EffectsMath.LayersFor(def.id, tier)
				expect(count(layers, "Beam") <= Effects.Caps.MaxBeams).toEqual(true)
				expect(count(layers, "Light") <= Effects.Caps.MaxLights).toEqual(true)
			end
		end
	end)

	it("drops a fifth beam and a second light from a crowded species", function()
		local saved = Effects.Species.Sparkfox
		local function crowded(kinds: { string }): { any }
			local layers = {}
			for index, kind in ipairs(kinds) do
				if kind == "Beam" then
					table.insert(layers, { kind = "Beam", color = "FFFFFF", at = "Top", to = "Feet", width = 0.05, flicker = 2, segments = 4 })
				else
					table.insert(layers, { kind = "Light", color = "FFFFFF", at = "Top", brightness = index, range = 2 })
				end
			end
			return layers
		end
		local function drawn(kinds: { string }): any
			local row: any = { element = "Test", idle = { kind = "Still", amplitude = 0, period = 1 }, layers = crowded(kinds) }
			Effects.Species.Sparkfox = row
			local layers = EffectsMath.LayersFor("Sparkfox", "Secret")
			Effects.Species.Sparkfox = saved
			return layers
		end
		local beams = drawn({ "Beam", "Beam", "Beam", "Beam", "Beam", "Light" })
		expect(count(beams, "Beam")).toEqual(Effects.Caps.MaxBeams)
		expect(count(beams, "Light")).toEqual(1)
		local lights = drawn({ "Beam", "Light", "Light", "Light", "Light", "Light" })
		expect(count(lights, "Light")).toEqual(Effects.Caps.MaxLights)
		expect(count(lights, "Beam")).toEqual(1)
	end)

	it("adds a trail and an orbit at Cosmic when the species has neither, in the species' colour", function()
		local layers = EffectsMath.LayersFor("Mossbop", "Cosmic")
		expect(#layers).toEqual(3)
		expect(count(layers, "Orbit")).toEqual(1)
		expect(count(layers, "Trail")).toEqual(1)
		local signature = Effects.Species.Mossbop.layers[1].color
		expect(layers[2].color).toEqual(signature)
		expect(layers[3].color).toEqual(signature)
		expect(#EffectsMath.LayersFor("Mossbop", "Epic")).toEqual(1)
	end)

	it("does not double an orbit or a trail the species already has", function()
		local radish = EffectsMath.LayersFor("Radish", "Cosmic")
		expect(count(radish, "Orbit")).toEqual(1)
		expect(count(radish, "Trail")).toEqual(1)
		local fenripup = EffectsMath.LayersFor("Fenripup", "Cosmic")
		expect(count(fenripup, "Orbit")).toEqual(1)
		expect(count(fenripup, "Trail")).toEqual(1)
		expect(#fenripup).toEqual(#Effects.Species.Fenripup.layers)
	end)

	it("sinks Secret colours toward the dark colour and leaves Cosmic alone", function()
		local data = Effects.Species.Panpipe.layers
		local dark = EffectsMath.LayersFor("Panpipe", "Secret")
		local plain = EffectsMath.LayersFor("Panpipe", "Cosmic")
		expect(dark[1].color ~= data[1].color).toEqual(true)
		expect(dark[1].color).toEqual(EffectsMath.Mix(data[1].color, Effects.Dark.Color, Effects.Dark.Mix))
		expect(plain[1].color).toEqual(data[1].color)
		expect(dark[1].glow).toBeClose((data[1].glow or Effects.Look.DefaultGlow) * Effects.Dark.GlowScale, 1e-9)
		expect(data[1].color).toEqual("B28CFF") -- the data row itself is untouched
	end)
end)

describe("the ground ring", function()
	it("is for Legendary and above, flat, in the species' colour", function()
		for _, tier in ipairs({ "Common", "Uncommon", "Rare", "Epic" }) do
			expect(EffectsMath.GroundRingFor("Gaiabloom", tier) == nil).toEqual(true)
		end
		for _, tier in ipairs({ "Legendary", "Cosmic" }) do
			local ring = EffectsMath.GroundRingFor("Gaiabloom", tier)
			expect(ring ~= nil).toEqual(true)
			expect((ring :: any).flat).toEqual(true)
			expect((ring :: any).color).toEqual(Effects.Species.Gaiabloom.layers[1].color)
		end
		local secret = EffectsMath.GroundRingFor("Panpipe", "Secret")
		expect((secret :: any).color).toEqual(EffectsMath.Mix(Effects.Species.Panpipe.layers[1].color, Effects.Dark.Color, Effects.Dark.Mix))
		expect(EffectsMath.GroundRingFor("Gaiabloom", "Mythic") == nil).toEqual(true)
	end)
end)

describe("the caps", function()
	it("keeps the phone cap under the desktop cap, with positive budgets", function()
		expect(Effects.Caps.MobileRateCap <= Effects.Caps.DesktopRateCap).toEqual(true)
		expect(Effects.Caps.MobileRateCap).toEqual(100)
		expect(Effects.Caps.DesktopRateCap).toEqual(400)
		expect(Effects.Caps.MaxBeams).toEqual(4)
		expect(Effects.Caps.MaxLights).toEqual(1)
		expect(Effects.Caps.MaxActive).toEqual(12)
		expect(Effects.Caps.MaxSoundsPerSecond).toEqual(2)
		expect(EffectsMath.RateCap(true)).toEqual(100)
		expect(EffectsMath.RateCap(false)).toEqual(400)
	end)

	it("holds every resolved rate under the device cap, for every species, tier and device", function()
		for _, def in ipairs(Species.List) do
			for _, tier in ipairs(Tiers.Order) do
				local layers = EffectsMath.LayersFor(def.id, tier)
				local ring = EffectsMath.GroundRingFor(def.id, tier)
				if ring then
					table.insert(layers, ring)
				end
				for _, layer in ipairs(layers) do
					for _, mobile in ipairs({ true, false }) do
						local resolved = EffectsMath.Resolve(layer, tier, mobile, 1)
						if resolved.rate ~= nil then
							expect(resolved.rate <= EffectsMath.RateCap(mobile)).toEqual(true)
							expect(resolved.rate > 0).toEqual(true)
						end
					end
				end
			end
		end
	end)

	it("clamps a rate that would pass the cap, and leaves the data row alone", function()
		local layer = { kind = "Emitter", color = "FFFFFF", at = "Top", rate = 300, size = 0.1, lifetime = 1, speed = 0.1, spread = 10 } :: any
		expect(EffectsMath.Resolve(layer, "Cosmic", true, 1).rate).toEqual(100)
		expect(EffectsMath.Resolve(layer, "Cosmic", false, 1).rate).toEqual(400)
		expect(layer.rate).toEqual(300)
	end)

	it("scales rate, size and light by the tier", function()
		local mote = Effects.Species.Mossbop.layers[1]
		local common = EffectsMath.Resolve(mote, "Common", false, 1)
		local cosmic = EffectsMath.Resolve(mote, "Cosmic", false, 1)
		expect(common.rate).toBeClose((mote.rate :: number) * Effects.Tiers.Common.rateScale, 1e-9)
		expect(common.size).toBeClose((mote.size :: number) * Effects.Tiers.Common.sizeScale, 1e-9)
		expect((cosmic.rate :: number) > (common.rate :: number)).toEqual(true)
		expect((cosmic.size :: number) > (common.size :: number)).toEqual(true)
		expect(EffectsMath.Resolve(mote, "Common", false, 2).size).toBeClose((mote.size :: number) * Effects.Tiers.Common.sizeScale * 2, 1e-9)
		local lantern = Effects.Species.Lanternewt.layers[1]
		local dim = EffectsMath.Resolve(lantern, "Common", false, 1)
		local bright = EffectsMath.Resolve(lantern, "Secret", false, 1)
		expect((bright.brightness :: number) > (dim.brightness :: number)).toEqual(true)
		expect(dim.brightness).toBeClose((lantern.brightness :: number) * Effects.Tiers.Common.lightScale, 1e-9)
	end)

	it("picks the nearest MaxActive and no farther than the distance limit", function()
		local out: { [number]: boolean } = {}
		EffectsMath.PickActive({ 5, 1, 9, 3, 7 }, 2, 100, out)
		expect(out[2]).toEqual(true)
		expect(out[4]).toEqual(true)
		expect(out[1] == nil and out[3] == nil and out[5] == nil).toEqual(true)
		EffectsMath.PickActive({ 5, 1, 9, 3, 7 }, 2, 4, out)
		expect(out[2]).toEqual(true)
		expect(out[4]).toEqual(true)
		expect(out[1] == nil).toEqual(true)
		EffectsMath.PickActive({ 5, 1, 9, 3, 7 }, 2, 2, out)
		expect(out[2]).toEqual(true)
		expect(out[4] == nil).toEqual(true)
		EffectsMath.PickActive({ 4, 4, 4 }, 2, 100, out)
		expect(out[1] == true and out[2] == true and out[3] == nil).toEqual(true)
	end)

	it("keeps at most MaxActive of twenty aliens, nearest first", function()
		local distances: { number } = {}
		for index = 1, 20 do
			distances[index] = (21 - index) * 3 -- the last is the nearest
		end
		local out: { [number]: boolean } = {}
		EffectsMath.PickActive(distances, Effects.Caps.MaxActive, Effects.Caps.ActiveDistance, out)
		local kept = 0
		for index = 1, 20 do
			if out[index] then
				kept += 1
				expect(index > 20 - Effects.Caps.MaxActive).toEqual(true)
			end
		end
		expect(kept).toEqual(Effects.Caps.MaxActive)
	end)
end)

describe("idle motion", function()
	it("never lifts below the ground, for any species at any time", function()
		for _, fx in pairs(Effects.Species) do
			for step = 0, 60 do
				local lift = EffectsMath.Idle(fx.idle, step * 0.37, 1.3, 1)
				expect(lift >= -1e-9).toEqual(true)
			end
		end
	end)

	it("bobs between 0 and its amplitude, scaled by the alien's size", function()
		local bob = { kind = "Bob", amplitude = 0.4, period = 2 } :: any
		local low, high = math.huge, -math.huge
		for step = 0, 200 do
			local lift = EffectsMath.Idle(bob, step * 0.01, 0, 1)
			low, high = math.min(low, lift), math.max(high, lift)
		end
		expect(low).toBeClose(0, 1e-3)
		expect(high).toBeClose(0.4, 1e-3)
		expect(select(1, EffectsMath.Idle(bob, 0.5, 0, 2))).toBeClose(2 * select(1, EffectsMath.Idle(bob, 0.5, 0, 1)), 1e-9)
	end)

	it("hovers around its amplitude and sways by HoverSway of it", function()
		local hover = { kind = "Hover", amplitude = 0.5, period = 3 } :: any
		for step = 0, 100 do
			local lift = EffectsMath.Idle(hover, step * 0.05, 0, 1)
			expect(lift >= 0.5 * (1 - Effects.Motion.HoverSway) - 1e-9).toEqual(true)
			expect(lift <= 0.5 * (1 + Effects.Motion.HoverSway) + 1e-9).toEqual(true)
		end
	end)

	it("breathes by rocking within its amplitude in degrees", function()
		local breathe = { kind = "Breathe", amplitude = 4, period = 2 } :: any
		local widest = 0
		for step = 0, 200 do
			local _, yaw, pitch = EffectsMath.Idle(breathe, step * 0.01, 0, 1)
			expect(yaw).toEqual(0)
			widest = math.max(widest, math.abs(pitch))
		end
		expect(widest).toBeClose(math.rad(4), 1e-3)
	end)

	it("spins whole circles: a seamless loop, and a pure function of the clock", function()
		local spin = { kind = "Spin", amplitude = 360, period = 10 } :: any
		local _, a = EffectsMath.Idle(spin, 3, 0, 1)
		local _, b = EffectsMath.Idle(spin, 13, 0, 1)
		expect(b - a).toBeClose(math.rad(360), 1e-9)
		local _, again = EffectsMath.Idle(spin, 3, 0, 1)
		expect(again).toEqual(a) -- same clock, same pose: nothing accumulates
	end)

	it("poses nothing for Still and Flap (a Flap moves its wing parts instead)", function()
		for _, kind in ipairs({ "Still", "Flap" }) do
			local lift, yaw, pitch = EffectsMath.Idle({ kind = kind, amplitude = 20, period = 1 } :: any, 0.3, 0, 1)
			expect(lift == 0 and yaw == 0 and pitch == 0).toEqual(true)
		end
	end)

	it("swings a Flap within its amplitude, and falls back to a bob when the model has no wing", function()
		local flap = Effects.Species.Zapfinch.idle
		local widest = 0
		for step = 0, 400 do
			widest = math.max(widest, math.abs(EffectsMath.FlapAngle(flap, step * 0.01, 0)))
		end
		expect(widest).toBeClose(math.rad(flap.amplitude), 1e-3)
		expect(EffectsMath.FlapAngle({ kind = "Bob", amplitude = 1, period = 1 } :: any, 0.2, 0)).toEqual(0)
		expect(EffectsMath.EffectiveMotion(flap, true).kind).toEqual("Flap")
		local fallback = EffectsMath.EffectiveMotion(flap, false)
		expect(fallback.kind).toEqual("Bob")
		expect(fallback.amplitude).toEqual(Effects.Motion.FlapFallbackStuds)
		expect(fallback.period).toEqual(flap.period)
		expect(EffectsMath.EffectiveMotion(Effects.Species.Mossbop.idle, false).kind).toEqual("Breathe")
	end)
end)

describe("beams, pulses and orbits", function()
	local flash = Effects.Look.BeamFlashSeconds
	local steps = Effects.Look.BeamSteps

	it("strikes for BeamFlashSeconds once every flicker seconds", function()
		local on, bend = EffectsMath.BeamState(0.01, 2, 0)
		expect(on).toEqual(true)
		expect(bend).toEqual(1)
		expect((EffectsMath.BeamState(flash + 0.01, 2, 0))).toEqual(false)
		expect((EffectsMath.BeamState(1.9, 2, 0))).toEqual(false)
		expect((EffectsMath.BeamState(2.01, 2, 0))).toEqual(true)
	end)

	it("redraws the bend BeamSteps times a strike and a new one each strike, 0 while dark", function()
		local seen: { [number]: boolean } = {}
		local distinct = 0
		for tick = 0, 17 do
			local on, bend = EffectsMath.BeamState(tick * 0.01, 2, 0)
			expect(on).toEqual(true)
			if not seen[bend] then
				seen[bend] = true
				distinct += 1
			end
		end
		expect(distinct).toEqual(steps)
		local _, firstOfNext = EffectsMath.BeamState(2.001, 2, 0)
		expect(firstOfNext).toEqual(steps + 1)
		local dark, id = EffectsMath.BeamState(1, 2, 0)
		expect(dark).toEqual(false)
		expect(id).toEqual(0)
	end)

	it("slides a beam against the others with its offset, and stays lit when it never rests", function()
		expect((EffectsMath.BeamState(0.01, 2, 0.5))).toEqual(false)
		expect((EffectsMath.BeamState(1.55, 2, 0.5))).toEqual(true)
		expect((EffectsMath.BeamState(1, flash, 0))).toEqual(true)
	end)

	it("keeps a pulse between 1 - PulseDepth and 1", function()
		local low, high = math.huge, -math.huge
		for step = 0, 400 do
			local value = EffectsMath.Pulse(step * 0.01, 3, 0.7)
			low, high = math.min(low, value), math.max(high, value)
		end
		expect(low).toBeClose(1 - Effects.Look.PulseDepth, 1e-3)
		expect(high).toBeClose(1, 1e-3)
		expect(EffectsMath.Pulse(5, 0, 0)).toEqual(1)
	end)

	it("spaces orbit motes evenly round the circle", function()
		local a = EffectsMath.OrbitAngle(1, 4, 1, 4, 0)
		local b = EffectsMath.OrbitAngle(1, 4, 2, 4, 0)
		expect(b - a).toBeClose(math.pi / 2, 1e-9)
		expect(EffectsMath.OrbitAngle(5, 4, 1, 4, 0) - a).toBeClose(math.pi * 2, 1e-9)
	end)
end)

describe("the sound clock", function()
	local look = Effects.Look
	local TAU = math.pi * 2

	it("keeps the sound keys real and the spacing positive", function()
		expect(look.SoundEverySeconds).toEqual(8)
		expect(look.SoundRollOffMin > 0 and look.SoundRollOffMin < look.SoundRollOffMax).toEqual(true)
		expect(look.SoundMaxSeconds > 0).toEqual(true)
		for id, fx in pairs(Effects.Species) do
			if fx.sound ~= nil then
				expect(type((Sounds :: any)[fx.sound])).toEqual("string")
			end
			expect(id ~= "").toEqual(true)
		end
	end)

	it("rides the strike clock of a beam, and the idle cycle of one without", function()
		local period, offset = EffectsMath.SoundClock(2, 0.5, 1.2, 1)
		expect(period).toEqual(2)
		expect(offset).toEqual(0.5)
		local idlePeriod, idleOffset = EffectsMath.SoundClock(nil, 0, 1.2, math.pi)
		expect(idlePeriod).toEqual(1.2)
		expect(idleOffset).toBeClose(0.6, 1e-9) -- half a turn of phase is half a period
		local steady, steadyOffset = EffectsMath.SoundClock(look.BeamFlashSeconds, 0.3, 0.8, 0) -- a beam that never rests has no strike to ride
		expect(steady).toEqual(0.8)
		expect(steadyOffset).toEqual(0)
		local still, stillOffset = EffectsMath.SoundClock(nil, 0, 0, TAU / 4)
		expect(still).toEqual(look.SoundEverySeconds)
		expect(stillOffset).toBeClose(look.SoundEverySeconds / 4, 1e-9)
	end)

	it("counts one beat per period, and none for a clock with no period", function()
		expect(EffectsMath.SoundBeat(0, 2, 0)).toEqual(0)
		expect(EffectsMath.SoundBeat(1.99, 2, 0)).toEqual(0)
		expect(EffectsMath.SoundBeat(2, 2, 0)).toEqual(1)
		expect(EffectsMath.SoundBeat(9.9, 2, 0)).toEqual(4)
		expect(EffectsMath.SoundBeat(1.5, 2, 0.5)).toEqual(1) -- the offset slides the beat earlier
		expect(EffectsMath.SoundBeat(100, 0, 0)).toEqual(0)
	end)

	it("beats exactly when its beam strikes", function()
		local flicker, offset = 2, 0.65
		local period, slide = EffectsMath.SoundClock(flicker, offset, 9, 0)
		local previous = EffectsMath.SoundBeat(0, period, slide)
		local beats = 0
		for tick = 1, 2000 do
			local now = tick * 0.01
			local beat = EffectsMath.SoundBeat(now, period, slide)
			if beat ~= previous then
				beats += 1
				local on, bend = EffectsMath.BeamState(now, flicker, offset)
				expect(on).toEqual(true) -- the strike has just begun
				expect(bend % look.BeamSteps).toEqual(1) -- on its first bend
				previous = beat
			end
		end
		expect(beats).toEqual(10) -- twenty seconds at a strike every two
	end)

	it("spaces one alien's sounds by SoundEverySeconds", function()
		expect(EffectsMath.SoundDue(0, -math.huge, 8)).toEqual(true)
		expect(EffectsMath.SoundDue(7.99, 0, 8)).toEqual(false)
		expect(EffectsMath.SoundDue(8, 0, 8)).toEqual(true)
	end)

	it("plays a fast beat no oftener than SoundEverySeconds", function()
		local period, slide = EffectsMath.SoundClock(nil, 0, 0.8, 2) -- a hop four times faster than the spacing wants
		local lastBeat = EffectsMath.SoundBeat(0, period, slide)
		local lastPlayed = -math.huge
		local recent: { number } = {}
		local plays: { number } = {}
		for tick = 1, 60 * 60 do
			local now = tick / 60
			local beat = EffectsMath.SoundBeat(now, period, slide)
			if beat ~= lastBeat then
				lastBeat = beat
				if EffectsMath.SoundDue(now, lastPlayed, look.SoundEverySeconds) and EffectsMath.TakeSoundSlot(recent, now, Effects.Caps.MaxSoundsPerSecond) then
					lastPlayed = now
					table.insert(plays, now)
				end
			end
		end
		expect(#plays >= 6).toEqual(true) -- a minute at one every eight seconds or a little over
		for index = 2, #plays do
			expect(plays[index] - plays[index - 1] >= look.SoundEverySeconds).toEqual(true)
		end
	end)

	it("lets at most MaxSoundsPerSecond start in any second, and frees a slot after one second", function()
		local cap = Effects.Caps.MaxSoundsPerSecond
		local recent: { number } = {}
		for index = 1, cap do
			expect(EffectsMath.TakeSoundSlot(recent, 10 + index * 0.25, cap)).toEqual(true)
		end
		expect(EffectsMath.TakeSoundSlot(recent, 10.75, cap)).toEqual(false)
		expect(#recent).toEqual(cap) -- a refusal records nothing
		expect(EffectsMath.TakeSoundSlot(recent, 11.25, cap)).toEqual(true) -- the first (10.25) is a whole second old now
		expect(EffectsMath.TakeSoundSlot(recent, 11.4, cap)).toEqual(false)
		expect(EffectsMath.TakeSoundSlot({}, 0, 0)).toEqual(false)
	end)

	it("holds the cap across a crowd of aliens asking all at once", function()
		local cap = Effects.Caps.MaxSoundsPerSecond
		local seed = 7
		local function chance(): number -- a small deterministic generator in 0 to 1 (the headless runner has no Random)
			seed = (seed * 1103515245 + 12345) % 2147483648
			return seed / 2147483648
		end
		local recent: { number } = {}
		local started: { number } = {}
		for tick = 1, 60 * 30 do
			local now = tick / 60
			for _ = 1, 12 do
				if chance() < 0.15 and EffectsMath.TakeSoundSlot(recent, now, cap) then
					table.insert(started, now)
				end
			end
		end
		expect(#started > 0).toEqual(true)
		for index, at in ipairs(started) do
			local inWindow = 0
			for other = index, 1, -1 do
				if at - started[other] < 1 then
					inWindow += 1
				else
					break
				end
			end
			expect(inWindow <= cap).toEqual(true)
		end
	end)
end)

describe("placement", function()
	it("finds a region inside a box: the top at the top, the feet at the bottom, the eyes toward the front", function()
		local x, y, z = EffectsMath.AttachOffset("Top", -1, 0, -1, 2, 4, 2)
		expect(x).toBeClose(0, 1e-9)
		expect(y).toBeClose(4, 1e-9)
		expect(z).toBeClose(0, 1e-9)
		local _, feetY = EffectsMath.AttachOffset("Feet", -1, 0, -1, 2, 4, 2)
		expect(feetY).toBeClose(Effects.Attach.Feet.y * 4, 1e-9)
		local _, _, eyesZ = EffectsMath.AttachOffset("Eyes", -1, 0, -1, 2, 4, 2)
		expect(eyesZ < 0).toEqual(true)
		local _, _, tailZ = EffectsMath.AttachOffset("Tail", -1, 0, -1, 2, 4, 2)
		expect(tailZ > 0).toEqual(true)
		local leftX = EffectsMath.AttachOffset("BackL", -1, 0, -1, 2, 4, 2)
		local rightX = EffectsMath.AttachOffset("BackR", -1, 0, -1, 2, 4, 2)
		expect(leftX < 0 and rightX > 0).toEqual(true)
	end)

	it("follows the box when it is off-centre, and falls back to the body for an unknown region", function()
		local x, y, z = EffectsMath.AttachOffset("Top", 10, 5, -3, 2, 4, 2)
		expect(x).toBeClose(11, 1e-9)
		expect(y).toBeClose(9, 1e-9)
		expect(z).toBeClose(-2, 1e-9)
		local bx, by = EffectsMath.AttachOffset("Nowhere", 0, 0, 0, 2, 4, 2)
		expect(bx).toBeClose(1, 1e-9)
		expect(by).toBeClose(2, 1e-9)
	end)

	it("mixes hex colours", function()
		expect(EffectsMath.Mix("000000", "FFFFFF", 0.5)).toEqual("808080")
		expect(EffectsMath.Mix("FF0000", "FF0000", 0.7)).toEqual("FF0000")
		expect(EffectsMath.Mix("102030", "FFFFFF", 0)).toEqual("102030")
	end)
end)
return true
