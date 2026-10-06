--!strict
-- ReplicatedStorage.Shared.Capture: the capture-bar math that both sides must agree on.
-- The server judges a tap with these functions; the client animates the ticker with the same
-- position() from the same startClock (via workspace:GetServerTimeNow()), so what the player sees
-- is what the server scores. Change the formula here and nowhere else.

local Capture = {}

export type Outcome = "Perfect" | "Good" | "Miss"

-- Ticker position in [0, 1] after `elapsed` seconds. A triangle wave: 0 -> 1 -> 0 over one period
-- of 1 / tickerSpeed seconds. Negative elapsed (the sweep has not started yet) sits at 0.
function Capture.position(elapsed: number, tickerSpeed: number): number
	if elapsed <= 0 or tickerSpeed <= 0 then
		return 0
	end
	local period = 1 / tickerSpeed
	local phase = (elapsed % period) / period -- 0..1 through the cycle
	if phase < 0.5 then
		return phase * 2
	end
	return 2 - phase * 2
end

-- Score a ticker position against the zones. Zones are widths (fractions of the bar) centred on zoneCenter.
function Capture.outcome(pos: number, zoneCenter: number, goodZone: number, perfectZone: number): Outcome
	local distance = math.abs(pos - zoneCenter)
	if distance <= perfectZone / 2 then
		return "Perfect"
	end
	if distance <= goodZone / 2 then
		return "Good"
	end
	return "Miss"
end

-- True when a miss landed within `margin` of the Good zone's edge (the near-miss flash).
function Capture.isNearMiss(pos: number, zoneCenter: number, goodZone: number, margin: number): boolean
	local distance = math.abs(pos - zoneCenter)
	return distance > goodZone / 2 and distance <= goodZone / 2 + margin
end

-- Visible span of a zone along the bar, clamped to [0, 1]. Returns start, width.
function Capture.zoneSpan(zoneCenter: number, width: number): (number, number)
	local left = math.clamp(zoneCenter - width / 2, 0, 1)
	local right = math.clamp(zoneCenter + width / 2, 0, 1)
	return left, right - left
end

-- The zone's centre `elapsed` seconds into a sweep under a variant's drift (data/CatchVariants.luau):
-- the rolled `base` plus a sine swing of `amplitude` over `periodSeconds`, offset by `phase` (radians,
-- rolled by the server per sweep so the swing cannot be memorised), clamped to [clampMin, clampMax].
-- An amplitude or period of 0 gives `base`. Negative elapsed (before the sweep starts) reads as 0.
function Capture.driftCenter(elapsed: number, base: number, amplitude: number, periodSeconds: number, phase: number, clampMin: number, clampMax: number): number
	if amplitude <= 0 or periodSeconds <= 0 then
		return base
	end
	local t = math.max(elapsed, 0)
	local center = base + amplitude * math.sin(phase + (t / periodSeconds) * 2 * math.pi)
	return math.clamp(center, clampMin, clampMax)
end

return Capture
