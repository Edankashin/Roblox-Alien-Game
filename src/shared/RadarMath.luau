--!strict
-- Shared.RadarMath: the arithmetic of the radar column (Client.UI.RadarColumn, data/Radar, Decision B52). The column lists the wild
-- aliens near the player, nearest first, as shadows or real faces. Pure numbers, strings and booleans, no Roblox types:
-- tests/RadarMath.spec.luau runs it headless. Nothing here reads a position, an attribute or the profile; the column does that and
-- asks these functions what to list, in which order and whether a slot shows the shadow.

local RadarMath = {}

-- A tier of alien the column never lists, so a Secret is never told even as a shadow (the Mk2 "???" ping and its heartbeat went
-- with the minimap: a sound that quickens near a Secret would tell its direction).
RadarMath.NeverListed = "Secret"

-- The flat (XZ) distance of an offset: the radar ignores height, as the minimap did.
function RadarMath.Flat(dx: number, dz: number): number
	return math.sqrt(dx * dx + dz * dz)
end

-- True when an alien of this tier may be listed at all.
function RadarMath.TierListed(tierName: string): boolean
	return tierName ~= RadarMath.NeverListed
end

-- Whether an alien `flat` studs away is within the column's reach: inside the tier's `range`, or, while a Scanner Pulse runs,
-- anywhere in the player's biome (`sameBiome`). A tier with no radar (range 0) reaches nothing unless the pulse covers it.
function RadarMath.Reaches(flat: number, range: number, pulse: boolean, sameBiome: boolean): boolean
	if pulse and sameBiome then
		return true
	end
	return range > 0 and flat <= range
end

-- How many slots the column has: the tier's, or the pulse's when a Scanner Pulse runs and that is more (so the pulse works
-- without a radar). Never negative.
function RadarMath.Slots(tierSlots: number, pulse: boolean, pulseSlots: number): number
	local count = if pulse then math.max(tierSlots, pulseSlots) else tierSlots
	return math.max(0, math.floor(count))
end

-- True when a slot shows the black shadow: the player has no catch of the species in the codex. `catches` is the codex entry's
-- count, nil when the species has no entry.
function RadarMath.Shadowed(catches: number?): boolean
	return catches == nil or catches <= 0
end

-- Offers one alien to the nearest-first list kept in the parallel arrays `distances` and `items` (the first `count` entries are
-- live, ascending by distance). The list never grows past `limit`: an alien farther than a full list's last entry is dropped, a
-- nearer one pushes the last off. Equal distances keep the one that arrived first ahead. Returns the new count. Allocates
-- nothing, so the column can run it for every wild alien on every refresh (RadarRefreshSeconds) without a table per pass.
function RadarMath.Offer<T>(distances: { number }, items: { T }, count: number, limit: number, distance: number, item: T): number
	if limit <= 0 then
		return 0
	end
	local at = count + 1 -- where it sits if it goes last
	if count >= limit then
		if distance >= distances[count] then
			return count
		end
		at = count -- it takes the last place, which the list drops
	end
	while at > 1 and distances[at - 1] > distance do
		distances[at] = distances[at - 1]
		items[at] = items[at - 1]
		at -= 1
	end
	distances[at] = distance
	items[at] = item
	return math.min(count + 1, limit)
end

-- The scroll's layout and motion (Decision B57, data/RadarScroll). Heights are fractions of the screen height. ---------------

-- The sheet's full height for `slots` slots: a roller at each end, a pad of paper inside each, and one pitch per slot. 0 for no slots.
function RadarMath.ScrollHeight(slots: number, roller: number, pad: number, pitch: number): number
	if slots <= 0 then
		return 0
	end
	return 2 * roller + 2 * pad + slots * pitch
end

-- Where slot `index` (1 is the nearest alien, at the top) begins, from the screen's top, for a sheet starting at `top`.
function RadarMath.SlotTop(index: number, top: number, roller: number, pad: number, pitch: number): number
	return top + roller + pad + (index - 1) * pitch
end

-- How much of a slot the open sheet has uncovered, 0 to 1: nothing while the paper ends above the slot, all of it once the paper's
-- usable bottom (`paperBottom` less the bottom roller and pad) passes the slot's end. The unrolling reveals the slots top-down by it.
function RadarMath.Reveal(slotTop: number, pitch: number, paperBottom: number, roller: number, pad: number): number
	if pitch <= 0 then
		return 1
	end
	return math.clamp((paperBottom - roller - pad - slotTop) / pitch, 0, 1)
end

-- Moves `current` toward `target` by at most `step` (never past it). The unroll and the slot fades are this, so they land exactly.
function RadarMath.Approach(current: number, target: number, step: number): number
	if current < target then
		return math.min(target, current + step)
	end
	return math.max(target, current - step)
end

-- A fade from one end to the other lasting `seconds`: how far a value moves (0 to 1) in `dt`. No time to spend (Reduced Motion) or a
-- zero length jumps the whole way.
function RadarMath.FadeStep(dt: number, seconds: number): number
	if seconds <= 0 then
		return 1
	end
	return math.max(0, dt) / seconds
end

-- What one slot does this frame. `showing` is the species its picture holds now (nil: nothing), `wanted` the one the order puts there.
-- Answers the opacity to head for and whether to put `wanted` in the picture now: a picture that must change fades out first and is
-- swapped only once invisible, then fades in, so the order never pops. `alpha` is the slot's current opacity.
function RadarMath.SlotPlan(
	showing: string?,
	showingShadowed: boolean,
	wanted: string?,
	wantedShadowed: boolean,
	alpha: number
): (number, boolean)
	local same = showing == wanted and (wanted == nil or showingShadowed == wantedShadowed)
	if same then
		return (if wanted ~= nil then 1 else 0), false
	end
	if alpha <= 0 then
		return (if wanted ~= nil then 1 else 0), true
	end
	return 0, false
end

return RadarMath
