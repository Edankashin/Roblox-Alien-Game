--!strict
-- ReplicatedStorage.Shared.EffectsMath: the rules behind the per-species effects (data/Effects), shared so the client's
-- World.SpeciesFx and the headless tests agree. Pure functions of the data table and the numbers passed in; nothing here
-- touches an Instance, a clock or the camera, so it runs in the plain Luau interpreter.
-- LayersFor is the tier gate: the first `layersAllowed` of a species' layers, held to the beam and light caps, plus the
-- trail and orbit a tier adds when the species has none, in the dark variant for a tier that asks for it.
-- Resolve scales one layer for a tier and a device and holds its rate under the cap. Idle, FlapAngle, BeamState, Pulse and
-- OrbitAngle are absolute functions of the clock (never accumulated), so a skipped frame cannot make a motion drift.
-- PickActive is the nearest-first cap. AttachOffset turns a region name and a bounds box into a point.
-- The sound clock: SoundClock picks the beat an alien's sound rides (a beam's strike clock, else its idle cycle), SoundBeat says
-- which beat a moment falls in, SoundDue is the per-alien spacing and TakeSoundSlot the per-second cap across all aliens.

local Effects = require(script.Parent.data.Effects)
local Types = require(script.Parent.types.Types)

local EffectsMath = {}

local FALLBACK_REGION = "Body"
local FALLBACK_COLOR = "FFFFFF"

-- A hex colour's red, green and blue, 0 to 255 each.
local function channels(hex: string): (number, number, number)
	local value = tonumber(hex, 16) or 0
	return math.floor(value / 65536) % 256, math.floor(value / 256) % 256, value % 256
end

-- `hexA` moved `t` (0 to 1) of the way to `hexB`, as a hex string.
function EffectsMath.Mix(hexA: string, hexB: string, t: number): string
	local ar, ag, ab = channels(hexA)
	local br, bg, bb = channels(hexB)
	local function step(from: number, to: number): number
		return math.clamp(math.floor(from + (to - from) * t + 0.5), 0, 255)
	end
	return string.format("%02X%02X%02X", step(ar, br), step(ag, bg), step(ab, bb))
end

-- A shallow copy, so a caller can change a field without touching the data row.
local function copy(layer: Types.EffectLayer): Types.EffectLayer
	local out: any = {}
	for key, value in pairs(layer :: any) do
		out[key] = value
	end
	return out :: Types.EffectLayer
end

local function darken(layer: Types.EffectLayer): Types.EffectLayer
	local out = copy(layer)
	out.color = EffectsMath.Mix(layer.color, Effects.Dark.Color, Effects.Dark.Mix)
	if layer.kind == "Emitter" or layer.kind == "Orbit" then
		out.glow = (layer.glow or Effects.Look.DefaultGlow) * Effects.Dark.GlowScale
	end
	return out
end

-- The colour a species' extras and ring wear: its strongest layer's.
local function signature(speciesId: string): string
	local fx = Effects.Species[speciesId]
	local first = if fx then fx.layers[1] else nil
	return if first then first.color else FALLBACK_COLOR
end

-- The layers a species draws at a tier, strongest first: nothing for an unknown species or tier.
-- Never more than Caps.MaxBeams beams or Caps.MaxLights lights. The returned rows are the data's own unless the tier is dark,
-- so a caller must not change them (Resolve copies).
function EffectsMath.LayersFor(speciesId: string, tier: string): { Types.EffectLayer }
	local out: { Types.EffectLayer } = {}
	local rule = Effects.Tiers[tier]
	local fx = Effects.Species[speciesId]
	if not rule or not fx then
		return out
	end
	local beams, lights = 0, 0
	local hasTrail, hasOrbit = false, false
	for index, layer in ipairs(fx.layers) do
		if index > rule.layersAllowed then
			break
		end
		if layer.kind == "Beam" then
			if beams >= Effects.Caps.MaxBeams then
				continue
			end
			beams += 1
		elseif layer.kind == "Light" then
			if lights >= Effects.Caps.MaxLights then
				continue
			end
			lights += 1
		elseif layer.kind == "Trail" then
			hasTrail = true
		elseif layer.kind == "Orbit" then
			hasOrbit = true
		end
		table.insert(out, layer)
	end
	local color = signature(speciesId)
	if rule.orbit and not hasOrbit then
		local extra = copy(Effects.Extras.Orbit)
		extra.color = color
		table.insert(out, extra)
	end
	if rule.trail and not hasTrail then
		local extra = copy(Effects.Extras.Trail)
		extra.color = color
		table.insert(out, extra)
	end
	if rule.dark then
		for index, layer in ipairs(out) do
			out[index] = darken(layer)
		end
	end
	return out
end

-- The ring that pulses out along the ground at a tier that asks for one (Legendary and up), in the species' colour; nil below.
function EffectsMath.GroundRingFor(speciesId: string, tier: string): Types.EffectLayer?
	local rule = Effects.Tiers[tier]
	if not rule or not rule.groundRing then
		return nil
	end
	local ring = copy(Effects.Extras.GroundRing)
	ring.color = signature(speciesId)
	return if rule.dark then darken(ring) else ring
end

-- The emitter rate cap for a device, particles per second.
function EffectsMath.RateCap(mobile: boolean): number
	return if mobile then Effects.Caps.MobileRateCap else Effects.Caps.DesktopRateCap
end

-- One layer as a tier and a device draw it (still in heights): the rate times the tier's rateScale and held under the device
-- cap; sizes (particles, beam width, light range) times the tier's sizeScale and the caller's `sizeScale`; light brightness
-- times lightScale. A copy; the data row is untouched. An unknown tier scales nothing.
function EffectsMath.Resolve(layer: Types.EffectLayer, tier: string, mobile: boolean, sizeScale: number): Types.EffectLayer
	local out = copy(layer)
	local rule = Effects.Tiers[tier]
	local rateScale = if rule then rule.rateScale else 1
	local tierSize = if rule then rule.sizeScale else 1
	local lightScale = if rule then rule.lightScale else 1
	local grow = tierSize * sizeScale
	local cap = EffectsMath.RateCap(mobile)
	if layer.rate ~= nil then
		out.rate = math.min(layer.rate * rateScale, cap)
	end
	if layer.size ~= nil then
		out.size = layer.size * grow
	end
	if layer.kind == "Beam" and layer.width ~= nil then
		out.width = layer.width * grow
	end
	if layer.kind == "Light" then
		if layer.brightness ~= nil then
			out.brightness = layer.brightness * lightScale
		end
		if layer.range ~= nil then
			out.range = layer.range * tierSize
		end
	end
	return out
end

-- Motion helpers -----------------------------------------------------------

-- The motion a species really plays: a Flap with no wing part in its model bobs instead, by Motion.FlapFallbackStuds.
function EffectsMath.EffectiveMotion(motion: Types.IdleMotion, hasWingParts: boolean): Types.IdleMotion
	if motion.kind == "Flap" and not hasWingParts then
		return { kind = "Bob", amplitude = Effects.Motion.FlapFallbackStuds, period = motion.period }
	end
	return motion
end

local TAU = math.pi * 2

-- The idle pose at clock time `now`: (lift in studs, yaw in radians, pitch in radians), applied about the feet. `phase`
-- (radians) keeps a crowd out of step; `scale` is the alien's size against a 1.0-scale one. Lift is never negative, so the
-- feet never sink into the ground. Flap and Still pose nothing here (a Flap moves its wing parts: FlapAngle).
function EffectsMath.Idle(motion: Types.IdleMotion, now: number, phase: number, scale: number): (number, number, number)
	local kind = motion.kind
	if kind == "Still" or kind == "Flap" or motion.period <= 0 then
		return 0, 0, 0
	end
	local turns = now / motion.period
	local wave = math.sin(TAU * turns + phase)
	if kind == "Bob" then
		return motion.amplitude * scale * (0.5 + 0.5 * wave), 0, 0
	elseif kind == "Hover" then
		return motion.amplitude * scale * (1 + Effects.Motion.HoverSway * wave), 0, 0
	elseif kind == "Breathe" then
		local lift = Effects.Motion.BreatheLiftPerDegree * motion.amplitude * scale * (0.5 + 0.5 * wave)
		return lift, 0, math.rad(motion.amplitude) * wave
	elseif kind == "Spin" then
		return 0, math.rad(motion.amplitude) * turns + phase, 0
	end
	return 0, 0, 0
end

-- A Flap's swing at clock time `now`, radians (up is positive; the wing on the left of the body takes the opposite sign).
function EffectsMath.FlapAngle(motion: Types.IdleMotion, now: number, phase: number): number
	if motion.kind ~= "Flap" or motion.period <= 0 then
		return 0
	end
	return math.rad(motion.amplitude) * math.sin(TAU * now / motion.period + phase)
end

-- Whether a beam is struck at clock time `now`, and which bend it shows: a strike lasts Look.BeamFlashSeconds once every
-- `flicker` seconds (`offset` slides a beam against the others) and redraws its bend Look.BeamSteps times. The second
-- value counts strikes' bends upward forever, 0 while dark, so a caller redraws only when it changes.
function EffectsMath.BeamState(now: number, flicker: number, offset: number): (boolean, number)
	local flash = Effects.Look.BeamFlashSeconds
	local steps = Effects.Look.BeamSteps
	if flicker <= flash then
		return true, 1
	end
	local t = now + offset
	local cycle = math.floor(t / flicker)
	local into = t - cycle * flicker
	if into >= flash then
		return false, 0
	end
	return true, cycle * steps + math.floor(into / (flash / steps)) + 1
end

-- A glowing light's multiplier at `now`, from 1 - Look.PulseDepth up to 1, one swell every `period` seconds.
function EffectsMath.Pulse(now: number, period: number, phase: number): number
	if period <= 0 then
		return 1
	end
	return 1 - Effects.Look.PulseDepth * (0.5 - 0.5 * math.cos(TAU * now / period + phase))
end

-- Where mote `index` of `count` is on its circle at clock time `now`, radians.
function EffectsMath.OrbitAngle(now: number, period: number, index: number, count: number, phase: number): number
	if period <= 0 or count <= 0 then
		return phase
	end
	return TAU * (now / period + (index - 1) / count) + phase
end

-- Sound -----------------------------------------------------------------------

-- The beat an alien's sound rides, as (period, offset) for SoundBeat: the strike clock of its beam when it has one (the sound
-- lands with the bolt: the same period and offset BeamState takes), else the start of its idle cycle (the motion's period, slid
-- by the alien's phase so a crowd is out of step), else Look.SoundEverySeconds when the motion has no period (a Still).
function EffectsMath.SoundClock(beamFlicker: number?, beamOffset: number, motionPeriod: number, phase: number): (number, number)
	if beamFlicker ~= nil and beamFlicker > Effects.Look.BeamFlashSeconds then
		return beamFlicker, beamOffset
	end
	local period = if motionPeriod > 0 then motionPeriod else Effects.Look.SoundEverySeconds
	return period, phase / TAU * period
end

-- Which beat of a clock `now` falls in (a whole number that goes up by one at each beat; the first beat of a beam clock is the
-- one that turns the strike on). A caller plays on a change. A clock with no period never beats.
function EffectsMath.SoundBeat(now: number, period: number, offset: number): number
	if period <= 0 then
		return 0
	end
	return math.floor((now + offset) / period)
end

-- Whether an alien that last played at `lastPlayed` may play again at `now`: at least `everySeconds` apart (use -math.huge for
-- an alien that has not played yet).
function EffectsMath.SoundDue(now: number, lastPlayed: number, everySeconds: number): boolean
	return now - lastPlayed >= everySeconds
end

-- The per-second cap across every alien: `recent` is the caller's list of the times sounds started (oldest first). Drops the
-- ones a second or more old, then, if fewer than `perSecond` remain, records `now` and answers true; otherwise answers false and
-- records nothing. So no one-second window holds more than `perSecond` sounds.
function EffectsMath.TakeSoundSlot(recent: { number }, now: number, perSecond: number): boolean
	while #recent > 0 and now - recent[1] >= 1 do
		table.remove(recent, 1)
	end
	if #recent >= perSecond then
		return false
	end
	table.insert(recent, now)
	return true
end

-- Placement ------------------------------------------------------------------

-- The point of a named region inside a box: the box's minimum corner and its size in, x y z out (a region the data does not
-- name falls back to the middle of the body).
function EffectsMath.AttachOffset(region: string, minX: number, minY: number, minZ: number, sizeX: number, sizeY: number, sizeZ: number): (number, number, number)
	local point = Effects.Attach[region] or Effects.Attach[FALLBACK_REGION]
	return minX + sizeX / 2 + point.x * sizeX, minY + point.y * sizeY, minZ + sizeZ / 2 + point.z * sizeZ
end

local ranking: { number } = {}
local NO_DISTANCES: { number } = {}
local ranked: { number } = NO_DISTANCES

local function nearer(a: number, b: number): boolean
	local da, db = ranked[a], ranked[b]
	if da == db then
		return a < b
	end
	return da < db
end

-- The nearest-first cap: marks in `out` (cleared first) the indices of the `maxActive` smallest distances, ignoring any
-- beyond `maxDistance`. Ties go to the lower index. `out` is the caller's buffer, so a recheck allocates nothing once it
-- has grown.
function EffectsMath.PickActive(distances: { number }, maxActive: number, maxDistance: number, out: { [number]: boolean })
	table.clear(out)
	table.clear(ranking)
	ranked = distances
	for index, distance in ipairs(distances) do
		if distance <= maxDistance then
			table.insert(ranking, index)
		end
	end
	table.sort(ranking, nearer)
	for rank = 1, math.min(maxActive, #ranking) do
		out[ranking[rank]] = true
	end
	ranked = NO_DISTANCES -- let go of the caller's list
end

return EffectsMath
