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

-- Which wild aliens wear a nameplate (Clean-UI-Pass, "World labels"): the nearest `maxShown` within `range` studs, plus every one within
-- `alwaysStuds` however many there are. `distances` is one number per alien in a fixed order (a hidden alien passes math.huge and is
-- never shown); the answer is one boolean per alien, in the same order. Equal distances keep their order, so the choice does not
-- flicker between two aliens at the same spot.
function PlateMath.Shown(distances: { number }, maxShown: number, alwaysStuds: number, range: number): { boolean }
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
		local distance = distances[index]
		if distance <= alwaysStuds then
			shown[index] = true
			count += 1
		elseif distance <= range and count < maxShown then
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
