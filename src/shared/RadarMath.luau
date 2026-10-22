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

return RadarMath
