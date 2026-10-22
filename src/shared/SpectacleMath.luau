--!strict
-- ReplicatedStorage.Shared.SpectacleMath: the rules behind the spectacle ladder (data/Spectacle), shared so the client's
-- World.Spectacle, UI.CaptureBar and the headless specs (tests/Spectacle.spec.luau) agree. Pure functions of the data and the
-- numbers passed in: nothing here touches an Instance, a clock or the camera. Every motion is an absolute function of the time
-- (or of a share of a one-off's length), never accumulated, so a skipped frame or an alien that comes back on screen is in step.
-- Rows: Arrival, Presence, Personality and CatchLook answer a tier's row (Common's for an unknown tier).
-- Arrivals and budgets: ArrivalPlan is what an arrival really plays on a device (the still version under Reduced Motion), held under
-- the device's arrival caps; ArrivalCost counts its particles and parts (SpeciesFx's spawn moment included); PresenceCost counts
-- one alien's presence; SceneCost the whole scene the 30 fps target is held to.
-- Personality: FaceYaw and TurnToward (the turn to a player), Hop, WanderPoint and WanderAt (the leash walk), IdleFor (the idle a
-- cycle plays) and IdlePose, Noticed and ApproachFlourish.
-- Catch: Flashes (the bar's flashes in the alien's colour), SpiralAt, SlowMoScale, EscapeHopAt, BlinkVisible.
-- Screen: VignetteAlpha, SkyDim, BeaconAlpha. Footprints: FootprintColors, FootprintAlpha. Glyphs: GlyphCells.

local Spectacle = require(script.Parent.data.Spectacle)
local Tiers = require(script.Parent.data.Tiers)
local Effects = require(script.Parent.data.Effects)
local EffectsMath = require(script.Parent.EffectsMath)
local Types = require(script.Parent.types.Types)

local SpectacleMath = {}

local TAU = math.pi * 2
local FALLBACK_TIER = "Common"

-- Parts an arrival of each kind builds besides its cells: the host the light and particles hang on, the falling star, the beam's
-- sky anchor.
local KIND_PARTS: { [string]: number } = { None = 0, Pop = 1, Burst = 1, Star = 2, Beam = 2, Glitch = 1 }
local POOL_PARTS = 3 -- the light pool is a stepped disc of three flat cells (a bar and its two caps)
local HOST_PARTS = 1 -- the invisible part an alien's presence hangs on
local BEACON_PARTS = 1 -- the beacon's sky anchor (its foot rides the host)
local FX_ANCHOR_PARTS = 1 -- SpeciesFx's own anchor on every alien wearing its species effects

-- Rows -------------------------------------------------------------------------

function SpectacleMath.Arrival(tier: string): Spectacle.Arrival
	return Spectacle.Arrivals[tier] or Spectacle.Arrivals[FALLBACK_TIER]
end

-- The presence rows as the client draws them: the glyph orbit and the trail of cells only from Look.OrnamentMinTier / TrailMinTier up (the
-- Clean UI pass keeps the quiet tiers quiet whatever a data row says); every other field is the row's own.
local function gatedPresence(): { [string]: Spectacle.Presence }
	local out: { [string]: Spectacle.Presence } = {}
	for tier, row in pairs(Spectacle.Presence) do
		local copy = table.clone(row)
		local rank = table.find(Tiers.Order, tier) or 0
		if rank < (table.find(Tiers.Order, Spectacle.Look.OrnamentMinTier) or 0) then
			copy.ornaments = 0
		end
		if rank < (table.find(Tiers.Order, Spectacle.Look.TrailMinTier) or 0) then
			copy.trail = 0
		end
		out[tier] = copy
	end
	return out
end
local presenceRows = gatedPresence()

function SpectacleMath.Presence(tier: string): Spectacle.Presence
	return presenceRows[tier] or presenceRows[FALLBACK_TIER]
end

function SpectacleMath.Personality(tier: string): Spectacle.Personality
	return Spectacle.Personality[tier] or Spectacle.Personality[FALLBACK_TIER]
end

function SpectacleMath.CatchLook(tier: string): Spectacle.CatchLook
	return Spectacle.Catch[tier] or Spectacle.Catch[FALLBACK_TIER]
end

local function smooth(s: number): number
	local x = math.clamp(s, 0, 1)
	return x * x * (3 - 2 * x)
end
SpectacleMath.Smooth = smooth

-- Arrivals and budgets -------------------------------------------------------------

export type ArrivalPlan = {
	kind: Spectacle.ArrivalKind,
	seconds: number,
	cells: number,
	cellStuds: number,
	particles: number,
	reach: number,
	lightPulse: number,
	fall: number,
	skyDim: number,
	vignette: boolean,
	beacon: number,
	beaconReach: number,
	beaconWidth: number,
	still: boolean, -- the Reduced Motion version: nothing flies, falls, flickers or dims; the beacon holds steady
}

-- The particles SpeciesFx's spawn moment throws at a tier on a device (its firings, each held under the tier's burst cap), and
-- the parts it builds (none: its beams and emitters hang on the alien's own anchor).
function SpectacleMath.MomentParticles(tier: string, mobile: boolean): number
	local rule = Effects.Tiers[tier]
	if not rule or not rule.spawnMoment then
		return 0
	end
	local total = 0
	for _, layer in ipairs(Effects.SpawnMoment) do
		local resolved = EffectsMath.Resolve(layer, tier, mobile, 1)
		if resolved.kind == "Burst" or resolved.kind == "Sparkle" or resolved.kind == "RingPulse" then
			total += resolved.count or 1
		end
	end
	return total
end

-- An arrival's particles and parts as planned: its cells, its firing, its fixed parts, its beacon and SpeciesFx's spawn moment.
function SpectacleMath.ArrivalCost(tier: string, plan: ArrivalPlan, mobile: boolean): (number, number)
	local particles = plan.particles + (if plan.still then 0 else SpectacleMath.MomentParticles(tier, mobile))
	local parts = plan.cells + (KIND_PARTS[plan.kind] or 0) + (if plan.beacon ~= 0 then BEACON_PARTS else 0)
	return particles, parts
end

-- What an arrival of `tier` plays on a device: the tier's row, with its cells and particles scaled down by one factor each when
-- the whole would pass the device's arrival caps. Under Reduced Motion the still version: no cells, firing, fall, dip or flicker,
-- the alien simply there, the beacon kept (it holds steady).
function SpectacleMath.ArrivalPlan(tier: string, mobile: boolean, reduced: boolean): ArrivalPlan
	local row = SpectacleMath.Arrival(tier)
	local plan: ArrivalPlan = {
		kind = row.kind,
		seconds = row.seconds,
		cells = row.cells,
		cellStuds = row.cellStuds,
		particles = row.particles,
		reach = row.reach,
		lightPulse = row.lightPulse,
		fall = row.fall,
		skyDim = row.skyDim,
		vignette = row.vignette,
		beacon = row.beacon,
		beaconReach = row.beaconReach,
		beaconWidth = row.beaconWidth,
		still = false,
	}
	if reduced then
		plan.kind = "None"
		plan.seconds = 0
		plan.cells = 0
		plan.particles = 0
		plan.lightPulse = 0
		plan.fall = 0
		plan.skyDim = 0
		plan.vignette = false
		plan.still = true
		return plan
	end
	local caps = Spectacle.Caps
	local maxParticles = if mobile then caps.MobileArrivalParticles else caps.DesktopArrivalParticles
	local maxParts = if mobile then caps.MobileArrivalParts else caps.DesktopArrivalParts
	local particles, parts = SpectacleMath.ArrivalCost(tier, plan, mobile)
	if particles > maxParticles and plan.particles > 0 then
		local over = particles - maxParticles
		plan.particles = math.max(0, plan.particles - over)
	end
	if parts > maxParts and plan.cells > 0 then
		local over = parts - maxParts
		plan.cells = math.max(0, plan.cells - over)
	end
	return plan
end

-- One alien's presence as live particles (its aura, its trail while it moves, its shimmer) and parts (the host, the pool, the
-- ornaments; the beacon is counted by the scene, which keeps only the nearest few).
function SpectacleMath.PresenceCost(tier: string): (number, number)
	local row = SpectacleMath.Presence(tier)
	local life = Spectacle.PresenceLifetime
	local particles = row.aura * life.aura + row.trail * life.trail + row.shimmerRate * life.shimmer
	local parts = row.ornaments + (if row.pool > 0 then POOL_PARTS else 0)
	if parts > 0 or particles > 0 then
		parts += HOST_PARTS
	end
	return particles, parts
end

-- The worst scene on a phone the 30 fps target is held to: `aliens` aliens of `tier` around the camera, each at the per-alien
-- species-effect budget (data/Effects) with its presence, as many arrivals as may play at once, the nearest beacons and every
-- footprint alive. Answers (particles, parts).
function SpectacleMath.SceneCost(tier: string, aliens: number, mobile: boolean): (number, number)
	local caps = Spectacle.Caps
	local presenceMax = if mobile then caps.MaxPresenceMobile else caps.MaxPresence
	local fxMax = if mobile then Effects.Caps.MaxActiveMobile else Effects.Caps.MaxActive
	local wearing = math.min(aliens, fxMax)
	local dressed = math.min(aliens, presenceMax)
	local presenceParticles, presenceParts = SpectacleMath.PresenceCost(tier)
	local particles = wearing * EffectsMath.AlienBudget(mobile) + dressed * presenceParticles
	local parts = wearing * FX_ANCHOR_PARTS + dressed * presenceParts
	local arrivals = math.min(aliens, if mobile then caps.MaxArrivalsMobile else caps.MaxArrivals)
	local plan = SpectacleMath.ArrivalPlan(tier, mobile, false)
	local arrivalParticles, arrivalParts = SpectacleMath.ArrivalCost(tier, plan, mobile)
	particles += arrivals * arrivalParticles
	parts += arrivals * arrivalParts
	local row = SpectacleMath.Arrival(tier)
	if row.beacon == -1 then
		parts += math.min(aliens, if mobile then caps.MaxBeaconsMobile else caps.MaxBeacons) * BEACON_PARTS
	end
	if SpectacleMath.Presence(tier).footprints then
		parts += if mobile then caps.MaxFootprintsMobile else caps.MaxFootprints
	end
	return particles, parts
end

-- Personality --------------------------------------------------------------------

-- The yaw (radians, about +y) that turns a model whose face looks down -z to face along (dx, dz).
function SpectacleMath.FaceYaw(dx: number, dz: number): number
	if dx == 0 and dz == 0 then
		return 0
	end
	return math.atan2(-dx, -dz)
end

-- The shortest signed turn from `from` to `to`, radians in (-pi, pi].
function SpectacleMath.AngleDelta(from: number, to: number): number
	local delta = (to - from) % TAU
	if delta > math.pi then
		delta -= TAU
	end
	return delta
end

-- `from` turned `share` (0 to 1) of the shortest way to `to`.
function SpectacleMath.TurnToward(from: number, to: number, share: number): number
	return from + SpectacleMath.AngleDelta(from, to) * math.clamp(share, 0, 1)
end

-- The share of the remaining turn to close this frame at Look.TurnRate (frame-rate independent).
function SpectacleMath.TurnShare(dt: number): number
	return 1 - math.exp(-Spectacle.Look.TurnRate * math.max(dt, 0))
end

-- The lift (studs) of a notice's hops `elapsed` seconds in: `hops` hops of Look.HopSeconds, each a little lower than the last;
-- 0 before, between and after.
function SpectacleMath.Hop(elapsed: number, hops: number, height: number): number
	local each = Spectacle.Look.HopSeconds
	if elapsed < 0 or hops <= 0 or each <= 0 or elapsed >= hops * each then
		return 0
	end
	local index = math.floor(elapsed / each)
	local s = (elapsed - index * each) / each
	return height * math.sin(math.pi * s) * (0.7 ^ index)
end

-- Whether a player at `distance` studs is noticed by an alien of `tier`.
function SpectacleMath.Noticed(tier: string, distance: number): boolean
	return distance <= SpectacleMath.Personality(tier).notice
end

-- Whether an alien of `tier` plays its flourish now: the tier has the approach flourish, the player has come within `approach`,
-- and it has not played it for this visit yet.
function SpectacleMath.ApproachFlourish(tier: string, distance: number, done: boolean): boolean
	local row = SpectacleMath.Personality(tier)
	return row.approachFlourish and not done and distance <= row.approach
end

-- A repeatable hash of two numbers into 0 to 1 (no Random object, so a crowd needs no state to stay out of step).
function SpectacleMath.Hash(a: number, b: number): number
	local x = math.sin(a * 12.9898 + b * 78.233) * 43758.5453
	return x - math.floor(x)
end

-- Where the wander of cycle `index` heads, as (dx, dz) studs from home: a point evenly spread over the disc of `leash`; cycle 0
-- and any cycle the caller rejects (a step the ground does not allow) is home.
function SpectacleMath.WanderPoint(seed: number, index: number, leash: number): (number, number)
	if leash <= 0 or index == 0 then
		return 0, 0
	end
	local r = leash * math.sqrt(SpectacleMath.Hash(seed, index))
	local a = TAU * SpectacleMath.Hash(index, seed + 1)
	return r * math.cos(a), r * math.sin(a)
end

-- Where a wanderer is in its cycle at `now`: (index, moving, k) where `index` counts cycles, `moving` is true over the first
-- Look.MoveShare of a cycle and `k` is the walk's eased progress (1 once it has arrived); `idle` is the share of the idle part of
-- the cycle gone by (0 while moving).
function SpectacleMath.WanderAt(now: number, seed: number, cycle: number): (number, boolean, number, number)
	if cycle <= 0 then
		return 0, false, 1, 0
	end
	local t = now / cycle + seed
	local index = math.floor(t)
	local into = t - index
	local share = Spectacle.Look.MoveShare
	if into < share then
		return index, true, smooth(into / share), 0
	end
	return index, false, 1, (into - share) / (1 - share)
end

-- The idle cycle `index` plays, from the tier's weights (Sleep only at night). Stable for a seed and an index.
function SpectacleMath.IdleFor(tier: string, seed: number, index: number, night: boolean): Spectacle.IdleKind
	local weights: { [string]: number } = SpectacleMath.Personality(tier).idles :: any
	local order: { string } = { "Look", "Stretch", "Sit", "Sleep", "Play" }
	local total = 0
	for _, kind in ipairs(order) do
		if night or kind ~= "Sleep" then
			total += weights[kind] or 0
		end
	end
	if total <= 0 then
		return "Look"
	end
	local roll = SpectacleMath.Hash(seed + 7, index) * total
	for _, kind in ipairs(order) do
		if night or kind ~= "Sleep" then
			roll -= weights[kind] or 0
			if roll < 0 then
				return kind :: Spectacle.IdleKind
			end
		end
	end
	return "Look"
end

-- An idle's pose at `s` (0 to 1 of the idle part of the cycle): (lift studs, yaw, pitch, roll radians), eased in and out so it
-- starts and ends at rest. `theatre` scales the amplitudes (not Play's whole spin).
function SpectacleMath.IdlePose(kind: Spectacle.IdleKind, s: number, theatre: number): (number, number, number, number)
	local look = Spectacle.Look
	if s <= 0 or s >= 1 then
		return 0, 0, 0, 0
	end
	local env = math.min(1, 5 * s, 5 * (1 - s)) -- in over the first fifth, out over the last
	if kind == "Look" then
		return 0, math.rad(look.LookYaw * theatre) * math.sin(TAU * s) * env, 0, 0
	elseif kind == "Stretch" then
		local wave = math.sin(math.pi * s)
		return look.StretchLift * theatre * wave, 0, math.rad(look.StretchPitch * theatre) * wave, 0
	elseif kind == "Sit" then
		return 0, 0, math.rad(look.SitPitch * theatre) * env, 0
	elseif kind == "Sleep" then
		return 0, 0, 0, math.rad(look.SleepRoll) * env
	elseif kind == "Play" then
		local spin = math.rad(look.PlaySpin) * smooth(math.clamp(s * 2, 0, 1))
		local hop = if s < 0.5 then look.PlayHop * theatre * math.abs(math.sin(TAU * 2 * s)) else 0
		return hop, spin, 0, 0
	end
	return 0, 0, 0, 0
end

-- Catch -----------------------------------------------------------------------------

-- How many times the bar's zone flashes in the alien's colour for a hit: the tier's flashes on a Good, one more on a Perfect,
-- none on a miss. Each flash takes Look.FlashPeriod.
function SpectacleMath.Flashes(tier: string, hit: Types.HitOutcome?): number
	local row = SpectacleMath.CatchLook(tier)
	if hit == "Perfect" then
		return row.flashes + 1
	elseif hit == "Good" then
		return row.flashes
	end
	return 0
end

-- The spiral into the device at `s` (0 to 1 of its length): (angle radians, radius share of Look.SpiralRadius, travel share of
-- the way to the device, scale share of the alien's size).
function SpectacleMath.SpiralAt(s: number, turns: number): (number, number, number, number)
	local x = math.clamp(s, 0, 1)
	local look = Spectacle.Look
	return TAU * turns * x, 1 - x, smooth(x), 1 - (1 - look.SpiralEnd) * x * x
end

-- How fast a slow-mo runs the catch's own clocks `t` seconds into one of `seconds`: down to Caps.SlowMoMinScale and back to 1.
function SpectacleMath.SlowMoScale(t: number, seconds: number): number
	if seconds <= 0 or t <= 0 or t >= seconds then
		return 1
	end
	return 1 - (1 - Spectacle.Caps.SlowMoMinScale) * math.sin(math.pi * t / seconds)
end

-- An escape `t` seconds in: (lift studs, stride share of the whole run away, done). `hops` hops of Look.EscapeHopSeconds.
function SpectacleMath.EscapeHopAt(t: number, hops: number): (number, number, boolean)
	local look = Spectacle.Look
	local each = look.EscapeHopSeconds
	if hops <= 0 or each <= 0 then
		return 0, 1, true
	end
	if t >= hops * each then
		return 0, 1, true
	end
	local x = math.max(t, 0)
	local index = math.floor(x / each)
	local s = (x - index * each) / each
	return look.EscapeHop * math.sin(math.pi * s), (index + s) / hops, false
end

-- Whether a Secret blinking out shows at `t`: Look.BlinkFlickers on-off flickers over Look.BlinkSeconds, then gone.
function SpectacleMath.BlinkVisible(t: number): boolean
	local look = Spectacle.Look
	if t < 0 then
		return true
	end
	if t >= look.BlinkSeconds then
		return false
	end
	local phase = math.floor(t / look.BlinkSeconds * look.BlinkFlickers * 2)
	return phase % 2 == 0
end

-- Screen ----------------------------------------------------------------------------

-- The Secret's screen-edge vignette at `t` of an arrival of `seconds`: its transparency (1 is clear). Look.VignetteFlickers
-- flickers, each a smooth swell (never a hard strobe), the whole held under three a second.
function SpectacleMath.VignetteAlpha(t: number, seconds: number): number
	local look = Spectacle.Look
	if seconds <= 0 or t <= 0 or t >= seconds then
		return 1
	end
	local wave = math.abs(math.sin(math.pi * look.VignetteFlickers * t / seconds))
	return 1 - (1 - look.VignetteTransparency) * wave
end

-- How many flickers a second the vignette runs at for an arrival of `seconds` (the spec holds it to three or fewer).
function SpectacleMath.VignetteRate(seconds: number): number
	if seconds <= 0 then
		return 0
	end
	return Spectacle.Look.VignetteFlickers / seconds
end

-- The sky's dip at `t` of an arrival of `seconds` whose row dims by `depth`: ramps in over Look.SkyRamp, holds, ramps out.
function SpectacleMath.SkyDim(t: number, seconds: number, depth: number): number
	if depth <= 0 or seconds <= 0 then
		return 0
	end
	local ramp = Spectacle.Look.SkyRamp / seconds
	return depth * EffectsMath.Envelope(t / seconds, ramp, ramp)
end

-- A beacon's transparency at `now`, born at `born`, standing `duration` seconds (-1 while the alien stays): fades in and out over
-- Look.BeaconFade, breathes over Look.BeaconPeriod (held still under Reduced Motion). 1 is gone.
function SpectacleMath.BeaconAlpha(now: number, born: number, duration: number, still: boolean): number
	local look = Spectacle.Look
	local age = now - born
	if duration == 0 or age < 0 or (duration > 0 and age >= duration) then
		return 1
	end
	local strength = math.clamp(age / look.BeaconFade, 0, 1)
	if duration > 0 then
		strength = math.min(strength, math.clamp((duration - age) / look.BeaconFade, 0, 1))
	end
	local breathe = if still then 0 else look.BeaconBreathe * (0.5 + 0.5 * math.sin(TAU * now / look.BeaconPeriod))
	local base = look.BeaconTransparency + breathe * (1 - look.BeaconTransparency)
	return 1 - (1 - base) * strength
end

-- How much of a beacon shows with the camera `distance` studs from it along the ground, 1 to 0: whole from Look.BeaconNearFadeStuds out,
-- gone by Look.BeaconHideStuds in, a smooth ramp between. A beacon is a column for finding an alien from far; close to it, it would fill the
-- screen with light.
function SpectacleMath.BeaconNear(distance: number): number
	local look = Spectacle.Look
	if distance >= look.BeaconNearFadeStuds then
		return 1
	end
	if distance <= look.BeaconHideStuds then
		return 0
	end
	return smooth((distance - look.BeaconHideStuds) / (look.BeaconNearFadeStuds - look.BeaconHideStuds))
end

-- Whether an arrival's screen dim (the Cosmic's sky, the Secret's edge vignette) may play at `now`: not while a panel is open, and not
-- within Look.DimGapSeconds of the last one that did (`lastDimAt`; -math.huge for none).
function SpectacleMath.DimAllowed(now: number, lastDimAt: number, panelOpen: boolean): boolean
	return not panelOpen and now - lastDimAt >= Spectacle.Look.DimGapSeconds
end

-- Footprints ------------------------------------------------------------------------

-- The bloom's colours in a world (World 1 flowers, World 2 frost), the first the centre cell.
function SpectacleMath.FootprintColors(worldId: number): { string }
	return Spectacle.Footprints[worldId] or Spectacle.FootprintDefault
end

-- A footprint's (size share, transparency share) `age` seconds after it bloomed: grows over Look.FootprintGrow, fades out over
-- the last third of Look.FootprintLife; (0, 1) once gone.
function SpectacleMath.FootprintAlpha(age: number): (number, number)
	local look = Spectacle.Look
	if age < 0 or age >= look.FootprintLife then
		return 0, 1
	end
	local size = smooth(age / look.FootprintGrow)
	local fadeFrom = look.FootprintLife * (2 / 3)
	local clear = if age > fadeFrom then (age - fadeFrom) / (look.FootprintLife - fadeFrom) else 0
	return size, clear
end

-- Glyphs ----------------------------------------------------------------------------

-- A glyph's cells as (column, row) pairs counted from 0 at the top left, and its width and height in cells; an unknown glyph is
-- empty.
function SpectacleMath.GlyphCells(name: string): ({ { number } }, number, number)
	local rows = Spectacle.Glyphs[name]
	local cells: { { number } } = {}
	if not rows then
		return cells, 0, 0
	end
	local width = 0
	for y, row in ipairs(rows) do
		width = math.max(width, #row)
		for x = 1, #row do
			if string.sub(row, x, x) == "X" then
				table.insert(cells, { x - 1, y - 1 })
			end
		end
	end
	return cells, width, #rows
end

-- How many studs over a wild part's centre a bubble's centre stands: over the top of the alien (`topOffset`: the part's centre up
-- to the top of what the player sees), its bob and its nameplate (`plateLift` studs to the plate's centre, `plateStuds` tall at
-- range; the plate only shrinks nearer), a `gap` clear, and half the bubble's own `bubbleStuds`. The bubble's bottom is so over the
-- plate's top at every distance: the Rare "!" covered the middle of the plate when it stood 0.8 over the alien (Studio 2026-10-22).
function SpectacleMath.BubbleLift(topOffset: number, bob: number, plateLift: number, plateStuds: number, gap: number, bubbleStuds: number): number
	return topOffset + bob + plateLift + plateStuds / 2 + gap + bubbleStuds / 2
end

return SpectacleMath
