--!strict
-- The HUD's Menu drop-down (UI Playbook "Menu drop-down and icons (B52)", Decision B53): the Shop stays on the left edge on its own,
-- one Menu button sits under it, and every other screen is a row of the panel that drops from the Menu button. The numbers here are
-- fractions of the screen height unless they say pixels (Shared/MenuMath turns them into a layout; UI/Hud places it, Scale only).
-- Every number here, never in code.

local Menu = {
	RowHeight = 0.075, -- a row's height on a tall screen: 50 px at 663 px
	MinRowPx = 44, -- and never under this on a short one (Theme.TapMin: tools/tests/test_block_theme.py keeps the two equal)
	RowGap = 0.008, -- between rows
	Pad = 0.012, -- the panel's inner margin, inside its ink
	Bottom = 0.97, -- the panel never reaches below this (the rows scroll instead)
	WidthAspect = 4.6, -- a row is this many times as wide as it is tall, in pixels
	MaxWidth = 0.4, -- of the screen width, at most
	IconShare = 0.74, -- the icon tile's height, as a fraction of the row's
	BadgeShare = 0.5, -- a row's red count, as a fraction of the row's height
	Dim = 0.55, -- the outside-tap layer's dim over the world while the drop-down is open (0 clear, 1 black)
}

return Menu
