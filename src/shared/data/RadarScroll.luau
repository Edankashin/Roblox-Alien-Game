--!strict
-- The radar scroll's look (UI Playbook "Radar column", Decision B57): every number the client's RadarColumn lays out. Ethan,
-- 2026-10-26: "one long rectangle ... shows the silhouette and shadow of the aliens on a white or something similar background.
-- Almost like if you opened up a scroll vertically." Heights are fractions of the SCREEN height, widths fractions of the screen
-- width (all Scale, no Offset); the pure arithmetic is Shared/RadarMath (ScrollHeight, SlotTop, Reveal), checked in
-- tests/RadarMath.spec.luau against the chip stack above and the Catch button below at iPhone SE and iPad.
return {
	X = 0.985, -- the scroll's right edge, of the screen width (the old column's and the chips')
	Top = 0.228, -- its top, of the screen height: under the weather, biome and shower chips (which end near 0.219)
	Width = 0.055, -- of the screen width
	CornerScale = 0.33, -- the paper's corner radius, of its width (UICorner Scale resolves against the shorter side)
	EdgePx = 2, -- the thin dark edge, in px at Theme.Stroke.ReferenceHeight (Builder.stroke scales it)
	RollerHeight = 0.02, -- each rolled end, of the screen height
	RollerOverhang = 1.1, -- a roller's width, as a multiple of the paper's: the roll pokes out a little past the sheet
	RollerEdgePx = 1.5,
	Pad = 0.008, -- paper between a roller and the first or last slot
	SlotPitch = 0.057, -- one slot's height including its air: equal spacing down the sheet
	ArtHeight = 0.053, -- the square a silhouette is drawn in, of the screen height (about 20 px at iPhone SE)
	ArtCentre = 0.46, -- where the art's centre sits in its slot, of the slot's height; the ground shadow sits under the feet
	GroundWidth = 0.62, -- the ground shadow ellipse's width, of the paper's width
	GroundHeight = 0.2, -- and its height, of a slot's
	GroundCentre = 0.86, -- and where its centre sits in the slot, of the slot's height
	GroundTransparency = 0.72,
	DropOffsetX = 0.002, -- the soft drop shadow behind the sheet: two layers, each offset down and right of the paper
	DropOffsetY = 0.006,
	DropGrow = 0.0025, -- how far the outer layer spreads past the inner, of the screen width
	DropTransparency = 0.8, -- the inner layer; the outer one is fainter (DropOuterTransparency)
	DropOuterTransparency = 0.9,
	UnrollSeconds = 0.35, -- the sheet opens from the top to its full height over this long; Reduced Motion: at once
	FadeSeconds = 0.2, -- a slot's silhouette fades in or out over this long when the order changes; Reduced Motion: at once
}
