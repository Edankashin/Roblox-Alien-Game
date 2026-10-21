--!strict
-- ReplicatedStorage.Shared.EffectsMath: the rules behind the per-species effects (data/Effects), shared so the client's
-- World.SpeciesFx and the headless tests agree. Pure functions of the data table and the numbers passed in; nothing here
-- touches an Instance, a clock or the camera, so it runs in the plain Luau interpreter.
-- LayersFor is the tier gate: the first `layersAllowed` of a species' layers whose kind the tier may draw, held to the beam,
-- light and pillar caps, plus the extras a tier adds when the species has none of that kind (orbit, trail, ground ring, aura,
-- sky pillar), in the species' accent, in the dark variant for a tier that asks for it. MomentFor is the spawn moment.
-- Resolve scales one layer for a tier and a device and holds its rate and burst under the caps; FitBudget holds one alien's
-- whole set under its live-particle budget. Idle, FlapAngle, BeamState, Pulse, OrbitAngle, Beat and Envelope are absolute
-- functions of the clock (never accumulated), so a skipped frame cannot make a motion drift. FlourishEvery and FlourishDue
-- are the flourish timer. SpriteFor resolves a sprite key to an uploaded id (and its flipbook sheet), through the fallbacks.
-- PickActive is the nearest-first cap. AttachOffset turns a region name and a bounds box into a point; Place resolves a layer's
-- point to a signature piece on a named moving part (Effects.Pieces) or, when the model has no such part, its fallback region.
-- The sound clock: SoundClock picks the beat an alien's sound rides (a beam's strike clock, else its idle cycle), SoundBeat says
-- which beat a moment falls in, SoundDue is the per-alien spacing and TakeSoundSlot the per-second cap across all aliens.

local Effects = require(script.Parent.data.Effects)
local Icons = require(script.Parent.data.Icons)
local Types = require(script.Parent.types.Types)

local EffectsMath = {}

local FALLBACK_REGION = "Body"
local FALLBACK_COLOR = "FFFFFF"

-- The kinds that fire on a clock or the flourish (they throw `count` particles at once) rather than flow at a rate.
local FIRED: { [string]: boolean } = { Burst = true, Sparkle = true, RingPulse = true }
-- The kinds that hold particles at a rate (an Orbit's rate is per mote).
local FLOWING: { [string]: boolean } = { Emitter = true, Orbit = true, Aura = true }
-- The kinds a Secret's dark variant sinks only by Dark.MomentMix (a pillar or ring must still read against the night).
local MOMENT_KINDS: { [string]: boolean } = { Pillar = true, RingPulse = true }

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
	local mix = if MOMENT_KINDS[layer.kind] then Effects.Dark.MomentMix else Effects.Dark.Mix
	out.color = EffectsMath.Mix(layer.color, Effects.Dark.Color, mix)
	if FLOWING[layer.kind] or FIRED[layer.kind] then
		out.glow = (layer.glow or Effects.Look.DefaultGlow) * Effects.Dark.GlowScale
	end
	return out
end

-- The colour a species' extras, ring and spawn moment wear: its accent, else its strongest layer's.
function EffectsMath.Accent(speciesId: string): string
	local fx = Effects.Species[speciesId]
	if not fx then
		return FALLBACK_COLOR
	end
	if fx.accent ~= nil then
		return fx.accent
	end
	local first = fx.layers[1]
	return if first then first.color else FALLBACK_COLOR
end

-- An extra in the species' accent.
local function extra(layer: Types.EffectLayer, color: string): Types.EffectLayer
	local out = copy(layer)
	out.color = color
	return out
end

-- The layers a species draws at a tier, strongest first: nothing for an unknown species or tier. A layer whose kind the tier
-- may not draw is skipped and does not count against layersAllowed. Never more than Caps.MaxBeams beams, Caps.MaxLights
-- lights or Caps.MaxPillars pillars. Then the tier's extras, each only when the species drew none of that kind (the ground
-- ring only when it drew no RingPulse on a timer). The returned rows are the data's own unless they are extras or the tier is
-- dark, so a caller must not change them (Resolve copies).
function EffectsMath.LayersFor(speciesId: string, tier: string): { Types.EffectLayer }
	local out: { Types.EffectLayer } = {}
	local rule = Effects.Tiers[tier]
	local fx = Effects.Species[speciesId]
	if not rule or not fx then
		return out
	end
	local taken = 0
	local seen: { [string]: number } = {}
	local timedRing = false
	for _, layer in ipairs(fx.layers) do
		if taken >= rule.layersAllowed then
			break
		end
		local kind = layer.kind
		if not rule.kinds[kind] then
			continue
		end
		local have = seen[kind] or 0
		if (kind == "Beam" and have >= Effects.Caps.MaxBeams) or (kind == "Light" and have >= Effects.Caps.MaxLights) or (kind == "Pillar" and have >= Effects.Caps.MaxPillars) then
			continue
		end
		seen[kind] = have + 1
		if kind == "RingPulse" and layer.every ~= nil then
			timedRing = true
		end
		taken += 1
		table.insert(out, layer)
	end
	local color = EffectsMath.Accent(speciesId)
	local extras = Effects.Extras
	if rule.orbit and not seen.Orbit then
		table.insert(out, extra(extras.Orbit, color))
	end
	if rule.trail and not seen.Trail then
		table.insert(out, extra(extras.Trail, color))
	end
	if rule.groundRing and not timedRing then
		table.insert(out, extra(extras.GroundRing, color))
	end
	if rule.aura and not seen.Aura then
		table.insert(out, extra(extras.Aura, color))
	end
	if rule.pillar and not seen.Pillar then
		table.insert(out, extra(extras.Pillar, color))
	end
	if rule.dark then
		for index, layer in ipairs(out) do
			out[index] = darken(layer)
		end
	end
	return out
end

-- The spawn moment a wild arrival plays once at a tier that asks for one (Cosmic and Secret), in the species' accent (dark for a
-- dark tier); empty below or for an unknown species or tier.
function EffectsMath.MomentFor(speciesId: string, tier: string): { Types.EffectLayer }
	local out: { Types.EffectLayer } = {}
	local rule = Effects.Tiers[tier]
	if not rule or not rule.spawnMoment or not Effects.Species[speciesId] then
		return out
	end
	local color = EffectsMath.Accent(speciesId)
	for _, layer in ipairs(Effects.SpawnMoment) do
		local piece = extra(layer, color)
		table.insert(out, if rule.dark then darken(piece) else piece)
	end
	return out
end

-- Whether a layer fires on the flourish.
function EffectsMath.OnFlourish(layer: Types.EffectLayer): boolean
	return layer.flourish == true
end

-- The emitter rate cap for a device, particles per second.
function EffectsMath.RateCap(mobile: boolean): number
	return if mobile then Effects.Caps.MobileRateCap else Effects.Caps.DesktopRateCap
end

-- The most particles one firing may throw at a tier on a device.
function EffectsMath.BurstCap(tier: string, mobile: boolean): number
	local rule = Effects.Tiers[tier]
	local device = if mobile then Effects.Caps.MobileBurstMax else Effects.Caps.DesktopBurstMax
	return if rule then math.min(rule.burstMax, device) else device
end

-- One layer as a tier and a device draw it (still in heights): the rate times the tier's rateScale and held under the device
-- cap; a firing's count held under the tier's and the device's burst cap (one when the row names none); sizes (particles, beam
-- and pillar width, light range) times the tier's sizeScale and the caller's `sizeScale`; light brightness times lightScale.
-- A copy; the data row is untouched. An unknown tier scales nothing.
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
	if FIRED[layer.kind] then
		out.count = math.max(1, math.min(layer.count or 1, EffectsMath.BurstCap(tier, mobile)))
	end
	if layer.size ~= nil then
		out.size = layer.size * grow
	end
	if (layer.kind == "Beam" or layer.kind == "Pillar") and layer.width ~= nil then
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

-- The live particles a set of layers keeps at once (rate times lifetime over the flowing kinds, an Orbit's per mote) plus the
-- largest single firing: the number an alien's budget holds.
function EffectsMath.LiveParticles(layers: { Types.EffectLayer }): number
	local flowing, largest = 0, 0
	for _, layer in ipairs(layers) do
		if FLOWING[layer.kind] then
			local motes = if layer.kind == "Orbit" then layer.count or 1 else 1
			flowing += (layer.rate or 0) * (layer.lifetime or 0) * motes
		elseif FIRED[layer.kind] then
			largest = math.max(largest, layer.count or 1)
		end
	end
	return flowing + largest
end

-- The per-alien live-particle budget on a device.
function EffectsMath.AlienBudget(mobile: boolean): number
	return if mobile then Effects.Caps.MobileAlienParticles else Effects.Caps.DesktopAlienParticles
end

-- Holds a set of resolved layers (Resolve's copies: this changes them) under the device's per-alien budget: when
-- LiveParticles is over it, every rate and firing count is scaled by the same factor (a count never below one). Returns the
-- factor (1 when it already fit).
function EffectsMath.FitBudget(layers: { Types.EffectLayer }, mobile: boolean): number
	local live = EffectsMath.LiveParticles(layers)
	local budget = EffectsMath.AlienBudget(mobile)
	if live <= budget or live <= 0 then
		return 1
	end
	local factor = budget / live
	for _, layer in ipairs(layers) do
		if layer.rate ~= nil then
			layer.rate *= factor
		end
		if FIRED[layer.kind] and layer.count ~= nil then
			layer.count = math.max(1, math.floor(layer.count * factor))
		end
	end
	return factor
end

-- A firing's count at a distance: the full count near the camera, FarRateScale of it (at least one) beyond NearDistance.
function EffectsMath.FarCount(count: number, near: boolean): number
	if near then
		return count
	end
	return math.max(1, math.floor(count * Effects.Caps.FarRateScale + 0.5))
end

-- Sprites ---------------------------------------------------------------------

-- The uploaded id a sprite key draws with, and its flipbook sheet: the key's own id (and its sheet) when it is real, else its
-- SpriteFallback key's id (never a sheet: the fallback is a single sprite), else nil (the soft default sprite).
function EffectsMath.SpriteFor(key: string?): (number?, Types.SpriteSheet?)
	if key == nil then
		return nil, nil
	end
	local own = Icons.Particles[key]
	if own ~= nil and own ~= 0 then
		return own, Effects.Sheets[key]
	end
	local fallback = Effects.SpriteFallback[key]
	local other = if fallback ~= nil then Icons.Particles[fallback] else nil
	if other ~= nil and other ~= 0 then
		return other, nil
	end
	return nil, nil
end

-- Flourish --------------------------------------------------------------------

-- Seconds between two flourishes of a species on its own timer.
function EffectsMath.FlourishEvery(speciesId: string): number
	local fx = Effects.Species[speciesId]
	local every = if fx then fx.flourishEvery else nil
	return if every ~= nil and every > 0 then every else Effects.Look.FlourishEvery
end

-- When an alien that has just come up flourishes first: between FlourishFirst and 1 of a period from `now`, slid by its
-- `phase` (radians), so a crowd that comes up together does not flourish together.
function EffectsMath.FirstFlourish(now: number, every: number, phase: number): number
	local first = Effects.Look.FlourishFirst
	local share = (phase % (math.pi * 2)) / (math.pi * 2)
	return now + every * (first + (1 - first) * share)
end

-- Whether the alien's own flourish timer plays at `now`: its next time has come, and nobody outside (a rig animator calling
-- SpeciesFx.Flourish) has flourished it within Look.ExternalHold periods (use -math.huge for never).
function EffectsMath.FlourishDue(now: number, nextAt: number, externalAt: number, every: number): boolean
	return now >= nextAt and now - externalAt >= every * Effects.Look.ExternalHold
end

-- A one-off's strength at `k` (0 to 1 of its life): rises from 0 over `rise`, holds at 1, falls to 0 over the last `fall`.
-- 0 outside 0 to 1.
function EffectsMath.Envelope(k: number, rise: number, fall: number): number
	if k <= 0 or k >= 1 then
		return 0
	end
	if rise > 0 and k < rise then
		return k / rise
	end
	if fall > 0 and k > 1 - fall then
		return (1 - k) / fall
	end
	return 1
end

-- A light's multiplier during a flourish flare, `since` seconds after it began: up to Look.FlareBoost and back to 1 over
-- Look.FlareSeconds (1 outside it).
function EffectsMath.Flare(since: number): number
	local look = Effects.Look
	if since < 0 or since >= look.FlareSeconds then
		return 1
	end
	return 1 + (look.FlareBoost - 1) * math.sin(math.pi * since / look.FlareSeconds)
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

-- The same clock for a timed firing (a Burst, Sparkle or RingPulse every `every` seconds, slid by `offset`): it fires when the
-- beat changes.
EffectsMath.Beat = EffectsMath.SoundBeat

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

-- Whether `name` is a point a layer may hang on: a body region (Effects.Attach) or a signature piece (Effects.Pieces).
function EffectsMath.IsPoint(name: string?): boolean
	return name ~= nil and (Effects.Attach[name] ~= nil or Effects.Pieces[name] ~= nil)
end

-- The body region a point stands for on a model without its piece: the region itself, a piece's fallback region, else the body.
function EffectsMath.RegionOf(name: string): string
	if Effects.Attach[name] ~= nil then
		return name
	end
	local piece = Effects.Pieces[name]
	if piece ~= nil and Effects.Attach[piece.region] ~= nil then
		return piece.region
	end
	return FALLBACK_REGION
end

-- Where a layer's point resolves on one model. A signature piece whose part the model has (`hasPart(part)` true) hangs on that
-- part at its spot (x y z: fractions of the part's own size from its centre), so it follows the part as the rig moves it; a piece
-- whose part is missing (an old blockout) falls back to its region, and a region (or an unknown name) is a bounds point as before
-- (x y z 0; AttachOffset places it).
function EffectsMath.Place(name: string, hasPart: (string) -> boolean): Types.FxPlace
	local piece = Effects.Pieces[name]
	if piece ~= nil and hasPart(piece.part) then
		local spot = piece.spot
		return { part = piece.part, region = EffectsMath.RegionOf(name), x = spot[1] or 0, y = spot[2] or 0, z = spot[3] or 0 }
	end
	return { part = nil, region = EffectsMath.RegionOf(name), x = 0, y = 0, z = 0 }
end

-- The parts a species' layers hang on (its pieces' part names, each once, in layer order): what a renderer looks up in the model.
function EffectsMath.PieceParts(speciesId: string): { string }
	local out: { string } = {}
	local fx = Effects.Species[speciesId]
	if not fx then
		return out
	end
	local seen: { [string]: boolean } = {}
	for _, layer in ipairs(fx.layers) do
		for _, name in ipairs({ layer.at, layer.to or layer.at }) do
			local piece = Effects.Pieces[name]
			if piece ~= nil and not seen[piece.part] then
				seen[piece.part] = true
				table.insert(out, piece.part)
			end
		end
	end
	return out
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
