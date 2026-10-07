--!strict
-- ReplicatedStorage.Shared.Proximity: the distance rules the server uses before it honours an action that has to be
-- done near something (a purchase at the Peddler's ship, a wave at a home's plot). Plain numbers in, so the headless
-- tests can run them; callers pass a character's root position and the target's. A check that gets a NaN or an
-- infinity answers false, never true: the comparisons are written so that anything unordered fails them.

local Proximity = {}

-- Whether point a is within `range` studs of point b, in all three axes.
function Proximity.Within(ax: number, ay: number, az: number, bx: number, by: number, bz: number, range: number): boolean
	local dx, dy, dz = ax - bx, ay - by, az - bz
	return math.sqrt(dx * dx + dy * dy + dz * dz) <= range
end

-- The flat (X and Z) distance from a point to the nearest point of a square centred on (cx, cz) with half-side
-- `half`: 0 anywhere inside it.
function Proximity.FlatGapToSquare(px: number, pz: number, cx: number, cz: number, half: number): number
	local gapX = math.max(math.abs(px - cx) - half, 0)
	local gapZ = math.max(math.abs(pz - cz) - half, 0)
	return math.sqrt(gapX * gapX + gapZ * gapZ)
end

-- Whether a point is within `range` studs (flat) of the square's edge, or inside it.
function Proximity.WithinSquare(px: number, pz: number, cx: number, cz: number, half: number, range: number): boolean
	return Proximity.FlatGapToSquare(px, pz, cx, cz, half) <= range
end

return Proximity
