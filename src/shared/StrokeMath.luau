--!strict
-- Shared.StrokeMath: how thick a UIStroke is on a screen of a given height. UIStroke.Thickness is in pixels and takes no
-- Scale, so a fixed 2.5 px outline is a hairline on a tall tablet window and a slab on a phone next to text that
-- Builder sizes from the screen. The Theme gives each stroke its pixel thickness at the reference height
-- (Theme.Stroke.Text 2.5, Button 3, Panel 4 at 1080), and this turns it into the pixels for the real height: the same
-- fraction of the screen, held inside [minScale, maxScale] times the reference so a phone keeps a stroke that reads and
-- a 4K window does not get a fat one. Pure arithmetic, so tests/StrokeMath.spec.luau runs it headless; Builder.stroke
-- reads the camera's ViewportSize and sets the Thickness, and sets it again when the viewport changes.

local StrokeMath = {}

export type Params = {
	referenceHeight: number, -- the screen height (px) at which a Theme.Stroke value is exactly its pixels
	minScale: number, -- the smallest factor of the reference thickness (a phone window)
	maxScale: number, -- and the largest (a 1440p or 4K window)
}

-- The factor a reference thickness is multiplied by on a screen `screenHeight` px tall. A height of 0 or less (no camera
-- yet, or a headless run) is the reference look: 1.
function StrokeMath.Scale(screenHeight: number, params: Params): number
	if screenHeight <= 0 then
		return 1
	end
	return math.clamp(screenHeight / params.referenceHeight, params.minScale, params.maxScale)
end

-- The thickness in px of a stroke that is `referencePx` thick at the reference height.
function StrokeMath.Thickness(referencePx: number, screenHeight: number, params: Params): number
	return referencePx * StrokeMath.Scale(screenHeight, params)
end

return StrokeMath
