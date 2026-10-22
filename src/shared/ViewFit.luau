--!strict
-- Shared.ViewFit: the arithmetic of a species thumbnail (Client.UI.SpeciesThumb), the real model in a small ViewportFrame on an
-- Aliens or Codex card instead of the placeholder shape's name (Studio 2026-10-22: the cards printed "Ball" with every model
-- uploaded). Pure numbers, no Roblox types: tests/ViewFit.spec.luau runs it headless.

local ViewFit = {}

-- How far from the centre of a box `sizeX` by `sizeY` by `sizeZ` studs a camera with a vertical field of view of `fovDeg`
-- degrees stands so the whole box shows in a square view, with `margin` (1 = touching) to spare: the box's bounding sphere
-- (radius half its diagonal) is tangent to the view cone at radius / sin(fov / 2), from any direction. A square view's horizontal
-- field equals its vertical one, so the sphere fits both ways. A degenerate box (no size) answers the margin alone, so a camera
-- is never placed on the target.
function ViewFit.Distance(sizeX: number, sizeY: number, sizeZ: number, fovDeg: number, margin: number): number
	local radius = math.sqrt(sizeX * sizeX + sizeY * sizeY + sizeZ * sizeZ) / 2
	local half = math.rad(math.clamp(fovDeg, 1, 179)) / 2
	return math.max(radius / math.sin(half), 1) * margin
end

-- How far from the centre of a box `sizeX` by `sizeY` by `sizeZ` studs (its axes the world's) a camera stands, looking at the centre
-- from the direction (`dirX`, `dirY`, `dirZ`) (from the centre toward the camera, any length), so every corner of the box is inside
-- a view `aspect` wide for its height (the field of view `fovDeg` is the vertical one), with `margin` (1 = touching) to spare. The
-- sphere fit above leaves a lanky model small in a wide picture: this one fits the box itself, so the model fills the picture's
-- height (Studio 2026-10-22: the model showed tiny in its card). Never nearer than 1 stud, never on the target.
function ViewFit.BoxDistance(
	sizeX: number,
	sizeY: number,
	sizeZ: number,
	dirX: number,
	dirY: number,
	dirZ: number,
	fovDeg: number,
	aspect: number,
	margin: number
): number
	local length = math.sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ)
	if length < 1e-6 then
		return ViewFit.Distance(sizeX, sizeY, sizeZ, fovDeg, margin)
	end
	-- The camera looks along f = -direction; right = f x up, up = right x f (a camera that is not straight above or below).
	local fx, fy, fz = -dirX / length, -dirY / length, -dirZ / length
	local rx, ry, rz = -fz, 0, fx -- f x (0, 1, 0)
	local rl = math.sqrt(rx * rx + rz * rz)
	if rl < 1e-6 then
		rx, ry, rz = 1, 0, 0 -- looking straight down or up
	else
		rx, rz = rx / rl, rz / rl
	end
	local ux, uy, uz = ry * fz - rz * fy, rz * fx - rx * fz, rx * fy - ry * fx
	local tanV = math.tan(math.rad(math.clamp(fovDeg, 1, 179)) / 2)
	local tanH = tanV * math.max(aspect, 0.05)
	local need = 0
	for _, sx in ipairs({ -0.5, 0.5 }) do
		for _, sy in ipairs({ -0.5, 0.5 }) do
			for _, sz in ipairs({ -0.5, 0.5 }) do
				local px, py, pz = sx * sizeX, sy * sizeY, sz * sizeZ
				local depthOffset = px * fx + py * fy + pz * fz -- along the line of sight; the corner's depth is distance + this
				local across = math.abs(px * rx + py * ry + pz * rz)
				local up = math.abs(px * ux + py * uy + pz * uz)
				need = math.max(need, across / tanH - depthOffset, up / tanV - depthOffset)
			end
		end
	end
	return math.max(need, 1) * margin
end

-- Whether a card from `top` to `bottom` (px, the screen's y) is near enough the visible window `viewTop` to `viewBottom` of its
-- scrolling grid to carry a live thumbnail: inside it, or within `margin` px above or below (a row's scroll ahead). A card far
-- off the window drops its view, so a grid of a hundred aliens holds a few rows of ViewportFrames, not a hundred.
function ViewFit.Near(top: number, bottom: number, viewTop: number, viewBottom: number, margin: number): boolean
	return bottom >= viewTop - margin and top <= viewBottom + margin
end

return ViewFit
