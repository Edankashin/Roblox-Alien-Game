--!strict
-- Pixel icons for the block-cell UI (UI Playbook "Block cells", Decide-Now 43: "pixel icons on an 8 by 8 grid"), drawn from the
-- approved HUD board ("HUD in block cells" on the Catch an Alien UI canvas). Each icon is a list of rectangles on an 8 by 8 grid,
-- { x, y, w, h, colour }, drawn in order (a later rectangle covers an earlier one). The colour is a Theme.Colors key or a six-digit
-- hex string (Theme.Hex reads it). Builder.pixelIcon draws one as frames in a square, so no image is uploaded and nothing waits
-- on moderation. Keys are the same as data/Icons (the menu and top-button ids, Scrap, the event banner's icon key).
-- PreferOverPack: where a key has both, the block HUD shows the pixel icon instead of the uploaded flat icon, so a block button
-- never carries a rendered round icon (B44: one look). Set it false to bring the pack back.

export type Pixel = { number | string }

local PixelIcons = {}

PixelIcons.PreferOverPack = true

local Icons: { [string]: { Pixel } } = {
	-- a gold scrap cube with a lit corner and a shaded side
	Scrap = {
		{ 1, 1, 6, 6, "Outline" },
		{ 2, 2, 4, 4, "Featured" },
		{ 2, 2, 2, 1, "FFE9A6" },
		{ 5, 4, 1, 2, "D99A00" },
	},
	-- a falling star with two embers
	Shower = {
		{ 5, 0, 3, 3, "White" },
		{ 3, 3, 2, 2, "FFE9A6" },
		{ 1, 5, 2, 2, "Featured" },
	},
	-- three bars, the middle one tallest
	Ranks = {
		{ 1, 4, 2, 3, "Outline" },
		{ 3, 1, 2, 6, "Outline" },
		{ 5, 3, 2, 4, "Outline" },
	},
	-- a cog with a hole the button's blue
	Settings = {
		{ 3, 0, 2, 8, "Outline" },
		{ 0, 3, 8, 2, "Outline" },
		{ 1, 1, 6, 6, "Outline" },
		{ 3, 3, 2, 2, "Select" },
	},
	-- a dollar-like S with a bar through it
	Shop = {
		{ 3, 0, 2, 8, "Outline" },
		{ 1, 1, 6, 2, "Outline" },
		{ 1, 3, 2, 1, "Outline" },
		{ 1, 4, 6, 1, "Outline" },
		{ 5, 5, 2, 1, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
	},
	-- a green alien face with two shining eyes
	Aliens = {
		{ 1, 1, 6, 6, "Outline" },
		{ 2, 2, 4, 4, "7FD27A" },
		{ 2, 3, 1, 2, "Outline" },
		{ 5, 3, 1, 2, "Outline" },
		{ 2, 3, 1, 1, "White" },
		{ 5, 3, 1, 1, "White" },
		{ 3, 5, 2, 1, "Outline" },
	},
	-- a cream page with a question mark
	Codex = {
		{ 1, 1, 6, 6, "Outline" },
		{ 2, 2, 4, 4, "Panel" },
		{ 3, 3, 2, 1, "Outline" },
		{ 3, 5, 1, 1, "Outline" },
	},
	-- a rocket with a window and a flame
	Ship = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 5, "Outline" },
		{ 3, 2, 2, 2, "White" },
		{ 1, 4, 1, 3, "Outline" },
		{ 6, 4, 1, 3, "Outline" },
		{ 3, 6, 2, 2, "FF8A3D" },
	},
	-- an exclamation mark
	Quests = {
		{ 3, 0, 2, 5, "Outline" },
		{ 3, 6, 2, 2, "Outline" },
	},
	-- a present with a bow
	Gifts = {
		{ 1, 3, 6, 5, "Outline" },
		{ 2, 4, 4, 3, "FFE9A6" },
		{ 3, 3, 2, 5, "Outline" },
		{ 2, 1, 2, 2, "Outline" },
		{ 4, 1, 2, 2, "Outline" },
	},
	-- an hourglass with gold sand (not on the board: drawn to match it)
	Playtime = {
		{ 1, 0, 6, 1, "Outline" },
		{ 2, 1, 4, 2, "Outline" },
		{ 3, 2, 2, 1, "Featured" },
		{ 3, 3, 2, 2, "Outline" },
		{ 2, 5, 4, 2, "Outline" },
		{ 3, 5, 2, 1, "Featured" },
		{ 1, 7, 6, 1, "Outline" },
	},
}
PixelIcons.Icons = Icons

return PixelIcons
