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

-- Whether a card from `top` to `bottom` (px, the screen's y) is near enough the visible window `viewTop` to `viewBottom` of its
-- scrolling grid to carry a live thumbnail: inside it, or within `margin` px above or below (a row's scroll ahead). A card far
-- off the window drops its view, so a grid of a hundred aliens holds a few rows of ViewportFrames, not a hundred.
function ViewFit.Near(top: number, bottom: number, viewTop: number, viewBottom: number, margin: number): boolean
	return bottom >= viewTop - margin and top <= viewBottom + margin
end

return ViewFit
