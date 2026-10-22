--!strict
-- Shared.PlateMath: how far a stud-sized nameplate (a BillboardGui whose Size is in studs, Scale) is shrunk so it never fills the
-- screen as the camera comes close. A billboard sized in studs grows on the screen as 1 / distance: the wild nameplate (7 by 2
-- studs) covered a third of the screen with the camera three studs off and two neighbours' plates overlapped (Studio
-- 2026-10-22). The renderer multiplies the plate's stud size by Scale, so its height on the screen holds at `maxShare` from the
-- distance where it would pass it inward, and stays exactly as before beyond it (readable at range). Pure numbers:
-- tests/PlateMath.spec.luau.

local PlateMath = {}

-- The share of the screen's height a thing `studsTall` high takes at `distance` studs from a camera whose vertical field of view
-- is `fovDeg` degrees.
function PlateMath.Share(distance: number, studsTall: number, fovDeg: number): number
	local visible = 2 * math.max(distance, 1e-3) * math.tan(math.rad(math.clamp(fovDeg, 1, 179)) / 2)
	return studsTall / visible
end

-- The factor on a plate's stud size: 1 while the plate takes `maxShare` of the screen's height or less, else the factor that
-- brings it back to `maxShare`, never under `minScale`.
function PlateMath.Scale(distance: number, studsTall: number, fovDeg: number, maxShare: number, minScale: number): number
	local share = PlateMath.Share(distance, studsTall, fovDeg)
	if share <= maxShare then
		return 1
	end
	return math.max(minScale, maxShare / share)
end

-- How high each plate of a crowd stands so two never lie on one another. `xs` and `zs` are the aliens' flat positions in a fixed
-- order (the order they appeared in): each takes `step` studs per earlier alien within `radius` studs of it, so the first of a
-- pair stays where it was and the second stands one step up, a third two. Returns one lift per alien, in the same order.
-- Camera-free on purpose: the stack is the same from every side, and it is judged a few times a second, not every frame.
function PlateMath.StackLifts(xs: { number }, zs: { number }, radius: number, step: number): { number }
	local lifts: { number } = {}
	local radiusSquared = radius * radius
	for i = 1, #xs do
		local below = 0
		for j = 1, i - 1 do
			local dx, dz = xs[j] - xs[i], zs[j] - zs[i]
			if dx * dx + dz * dz < radiusSquared then
				below += 1
			end
		end
		lifts[i] = below * step
	end
	return lifts
end

-- The stack with a depth limit: like StackLifts, but an alien that would stand more than `maxDepth` steps up (`maxDepth` or more earlier
-- plates within `radius`) loses its plate, so a crowd of plates never climbs into the compass strip. Only plates that are kept count
-- as neighbours below a later one. Returns the lifts and, per alien, whether its plate is kept (a dropped alien's lift is 0).
function PlateMath.Stack(xs: { number }, zs: { number }, radius: number, step: number, maxDepth: number): ({ number }, { boolean })
	local lifts: { number } = {}
	local keeps: { boolean } = {}
	local radiusSquared = radius * radius
	for i = 1, #xs do
		local below = 0
		for j = 1, i - 1 do
			if keeps[j] then
				local dx, dz = xs[j] - xs[i], zs[j] - zs[i]
				if dx * dx + dz * dz < radiusSquared then
					below += 1
				end
			end
		end
		keeps[i] = below < maxDepth
		lifts[i] = if keeps[i] then below * step else 0
	end
	return lifts, keeps
end

-- Which wild aliens wear a nameplate (Clean-UI-Pass, "World labels"): the nearest `maxShown` within `range` studs, never more (a crowd
-- close by does not lift the cap: six aliens 8 studs away draw five plates). `distances` is one number per alien in a fixed order (a
-- hidden alien passes math.huge and is never shown); the answer is one boolean per alien, in the same order. Equal distances keep their
-- order, so the choice does not flicker between two aliens at the same spot.
function PlateMath.Shown(distances: { number }, maxShown: number, range: number): { boolean }
	local order: { number } = {}
	for index = 1, #distances do
		order[index] = index
	end
	table.sort(order, function(a: number, b: number): boolean
		if distances[a] == distances[b] then
			return a < b
		end
		return distances[a] < distances[b]
	end)
	local shown: { boolean } = {}
	for index = 1, #distances do
		shown[index] = false
	end
	local count = 0
	for _, index in ipairs(order) do
		if distances[index] <= range and count < maxShown then
			shown[index] = true
			count += 1
		end
	end
	return shown
end

-- Whether a plate's second line (the tier) shows at `distance` studs: within `tierStuds`; farther, the name alone.
function PlateMath.TierShown(distance: number, tierStuds: number): boolean
	return distance <= tierStuds
end

-- How far a node's plate is drawn: `nodeStuds` for any node, `targetStuds` (far) for the one a marker points at.
function PlateMath.NodeRange(isTarget: boolean, nodeStuds: number, targetStuds: number): number
	return if isTarget then targetStuds else nodeStuds
end

return PlateMath
