--!strict
-- Pixel icons for the block-cell UI (UI Playbook "Block cells", Decide-Now 43: "pixel icons on an 8 by 8 grid"), drawn from the
-- approved HUD board ("HUD in block cells" on the Catch an Alien UI canvas). Each icon is a list of rectangles on an 8 by 8 grid,
-- { x, y, w, h, colour }, drawn in order (a later rectangle covers an earlier one). The colour is a Theme.Colors key or a six-digit
-- hex string (Theme.Hex reads it). Builder.pixelIcon draws one as frames in a square, so no image is uploaded and nothing waits
-- on moderation. Keys are the same as data/Icons (the menu and top-button ids, Scrap, the event banner's icon key, the power-up
-- and lure ids), plus Egg and Egg<Tier> for the eggs (tests/PixelIcons.spec.luau checks the grid, the colours and the cover).
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
	-- the Starter Pack: a gold present with a red ribbon and bow (the HUD offer button and the Shop card; TikTok batch 9)
	StarterPack = {
		{ 0, 2, 8, 6, "Outline" },
		{ 1, 3, 6, 1, "FFE9A6" },
		{ 1, 5, 6, 2, "Featured" },
		{ 3, 2, 2, 6, "E5383B" },
		{ 1, 0, 2, 2, "E5383B" },
		{ 5, 0, 2, 2, "E5383B" },
		{ 3, 1, 2, 1, "Outline" },
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
	-- Power-ups, lures and eggs (drawn after the board's set, in its style: an outline ink one pixel round, the colour inside,
	-- a lit pixel). The power-up and lure keys are their data ids (data/PowerUps, data/Lures); an egg is Egg<Tier>, its speckles in
	-- the tier's rarity colour (Theme.Rarity), or Egg for an egg of no tier. data/Icons.Aliases sends Egg<Tier> to the tier's pack
	-- badge, so with PreferOverPack off an egg still shows the image it showed before.
	-- a gold lightning bolt
	SpeedBurst = {
		{ 4, 0, 3, 1, "Outline" },
		{ 3, 1, 4, 1, "Outline" },
		{ 2, 2, 4, 1, "Outline" },
		{ 1, 3, 7, 2, "Outline" },
		{ 3, 5, 4, 1, "Outline" },
		{ 2, 6, 4, 1, "Outline" },
		{ 2, 7, 3, 1, "Outline" },
		{ 4, 1, 2, 1, "Featured" },
		{ 3, 2, 2, 1, "Featured" },
		{ 2, 3, 3, 1, "Featured" },
		{ 4, 4, 3, 1, "Featured" },
		{ 4, 5, 2, 1, "Featured" },
		{ 3, 6, 2, 1, "Featured" },
		{ 4, 3, 1, 1, "FFE9A6" },
	},
	-- a bullseye: a blue ring round a white one round a navy centre (the zone held still)
	SteadyHands = {
		{ 2, 0, 4, 1, "Outline" },
		{ 1, 1, 6, 1, "Outline" },
		{ 0, 2, 8, 4, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 2, 1, 4, 1, "Select" },
		{ 1, 2, 6, 1, "Select" },
		{ 1, 3, 2, 2, "Select" },
		{ 5, 3, 2, 2, "Select" },
		{ 1, 5, 6, 1, "Select" },
		{ 2, 6, 4, 1, "Select" },
		{ 2, 2, 4, 1, "White" },
		{ 2, 3, 1, 2, "White" },
		{ 5, 3, 1, 2, "White" },
		{ 2, 5, 4, 1, "White" },
	},
	-- a radar screen: a navy disc with a green cross and a white blip
	ScannerPulse = {
		{ 2, 0, 4, 1, "Outline" },
		{ 1, 1, 6, 1, "Outline" },
		{ 0, 2, 8, 4, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 2, 1, 4, 1, "2A2F55" },
		{ 1, 2, 6, 4, "2A2F55" },
		{ 2, 6, 4, 1, "2A2F55" },
		{ 4, 1, 1, 3, "7FD27A" },
		{ 6, 3, 1, 1, "White" },
		{ 1, 4, 6, 1, "7FD27A" },
		{ 4, 5, 1, 2, "7FD27A" },
	},
	-- a four-leaf clover with a light vein in each leaf
	LuckyCharm = {
		{ 1, 0, 2, 1, "Outline" },
		{ 5, 0, 2, 1, "Outline" },
		{ 0, 1, 8, 2, "Outline" },
		{ 1, 3, 6, 2, "Outline" },
		{ 0, 5, 8, 2, "Outline" },
		{ 1, 7, 2, 1, "Outline" },
		{ 5, 7, 2, 1, "Outline" },
		{ 1, 1, 2, 1, "7FD27A" },
		{ 5, 1, 2, 1, "7FD27A" },
		{ 1, 2, 6, 1, "7FD27A" },
		{ 2, 3, 4, 2, "7FD27A" },
		{ 1, 5, 6, 1, "7FD27A" },
		{ 1, 6, 2, 1, "7FD27A" },
		{ 5, 6, 2, 1, "7FD27A" },
		{ 1, 1, 1, 1, "B8F0B0" },
		{ 6, 1, 1, 1, "B8F0B0" },
		{ 1, 6, 1, 1, "B8F0B0" },
		{ 6, 6, 1, 1, "B8F0B0" },
	},
	-- a red horseshoe magnet with silver tips
	ScrapMagnet = {
		{ 0, 0, 3, 4, "Outline" },
		{ 5, 0, 3, 4, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 1, 1, 1, 4, "Close" },
		{ 6, 1, 1, 4, "Close" },
		{ 1, 5, 6, 1, "Close" },
		{ 2, 6, 4, 1, "Close" },
		{ 1, 1, 1, 1, "BFC3D6" },
		{ 6, 1, 1, 1, "BFC3D6" },
	},
	-- a white clock with gold rim and navy hands (a station working a double shift)
	DoubleShift = {
		{ 2, 0, 4, 1, "Outline" },
		{ 1, 1, 6, 1, "Outline" },
		{ 0, 2, 8, 4, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 2, 1, 4, 1, "Featured" },
		{ 1, 2, 2, 3, "Featured" },
		{ 4, 2, 3, 2, "Featured" },
		{ 6, 4, 1, 1, "Featured" },
		{ 1, 5, 6, 1, "Featured" },
		{ 2, 6, 4, 1, "Featured" },
		{ 2, 2, 1, 3, "White" },
		{ 4, 2, 2, 2, "White" },
		{ 2, 5, 4, 1, "White" },
	},
	-- the Twig Lure: a line, a brown twig body and a hook
	Lure1 = {
		{ 3, 0, 1, 2, "Outline" },
		{ 2, 2, 4, 1, "Outline" },
		{ 1, 3, 6, 1, "Outline" },
		{ 2, 4, 4, 1, "Outline" },
		{ 3, 5, 1, 2, "Outline" },
		{ 1, 6, 1, 1, "Outline" },
		{ 2, 7, 1, 1, "Outline" },
		{ 3, 2, 2, 1, "8B5A2B" },
		{ 2, 3, 4, 1, "8B5A2B" },
		{ 3, 4, 2, 1, "8B5A2B" },
		{ 4, 3, 1, 1, "FFE9A6" },
	},
	-- the Glow Lure: a line, a blue body with a white glowing core and a hook
	Lure2 = {
		{ 3, 0, 1, 2, "Outline" },
		{ 2, 2, 4, 1, "Outline" },
		{ 1, 3, 6, 1, "Outline" },
		{ 2, 4, 4, 1, "Outline" },
		{ 3, 5, 1, 2, "Outline" },
		{ 1, 6, 1, 1, "Outline" },
		{ 2, 7, 1, 1, "Outline" },
		{ 3, 2, 2, 1, "Select" },
		{ 2, 3, 4, 1, "Select" },
		{ 3, 4, 2, 1, "Select" },
		{ 3, 3, 2, 1, "White" },
	},
	-- the Star Lure: a line, a gold star body with a white sparkle and a hook
	Lure3 = {
		{ 3, 0, 1, 1, "Outline" },
		{ 2, 1, 1, 1, "Outline" },
		{ 3, 1, 1, 1, "Featured" },
		{ 4, 1, 1, 1, "Outline" },
		{ 0, 2, 2, 1, "Outline" },
		{ 2, 2, 2, 1, "Featured" },
		{ 4, 2, 1, 1, "White" },
		{ 5, 2, 2, 1, "Outline" },
		{ 1, 3, 1, 4, "Outline" },
		{ 2, 3, 3, 1, "Featured" },
		{ 5, 3, 1, 3, "Outline" },
		{ 2, 4, 1, 1, "Featured" },
		{ 4, 4, 1, 1, "Featured" },
		{ 3, 6, 1, 1, "Outline" },
		{ 2, 7, 1, 1, "Outline" },
	},
	-- a cream egg with a lit pixel and two darker speckles (an egg of no tier)
	Egg = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 5, 2, 1, 1, "D9C9A0" },
		{ 3, 4, 1, 1, "D9C9A0" },
	},
	-- a cream egg speckled in the Common colour (B0B0B0)
	EggCommon = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "B0B0B0" },
		{ 1, 4, 1, 1, "B0B0B0" },
		{ 5, 4, 1, 1, "B0B0B0" },
		{ 4, 6, 1, 1, "B0B0B0" },
	},
	-- a cream egg speckled in the Uncommon colour (57F96C)
	EggUncommon = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "57F96C" },
		{ 1, 4, 1, 1, "57F96C" },
		{ 5, 4, 1, 1, "57F96C" },
		{ 4, 6, 1, 1, "57F96C" },
	},
	-- a cream egg speckled in the Rare colour (3B82F6)
	EggRare = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "3B82F6" },
		{ 1, 4, 1, 1, "3B82F6" },
		{ 5, 4, 1, 1, "3B82F6" },
		{ 4, 6, 1, 1, "3B82F6" },
	},
	-- a cream egg speckled in the Epic colour (C026D3)
	EggEpic = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "C026D3" },
		{ 1, 4, 1, 1, "C026D3" },
		{ 5, 4, 1, 1, "C026D3" },
		{ 4, 6, 1, 1, "C026D3" },
	},
	-- a cream egg speckled in the Legendary colour (F59E0B)
	EggLegendary = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "F59E0B" },
		{ 1, 4, 1, 1, "F59E0B" },
		{ 5, 4, 1, 1, "F59E0B" },
		{ 4, 6, 1, 1, "F59E0B" },
	},
	-- a cream egg speckled in the Cosmic colour (EC4899)
	EggCosmic = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "EC4899" },
		{ 1, 4, 1, 1, "EC4899" },
		{ 5, 4, 1, 1, "EC4899" },
		{ 4, 6, 1, 1, "EC4899" },
	},
	-- a cream egg speckled in the Secret colour (111111)
	EggSecret = {
		{ 3, 0, 2, 1, "Outline" },
		{ 2, 1, 4, 1, "Outline" },
		{ 1, 2, 6, 2, "Outline" },
		{ 0, 4, 8, 2, "Outline" },
		{ 1, 6, 6, 1, "Outline" },
		{ 2, 7, 4, 1, "Outline" },
		{ 3, 1, 2, 1, "Panel" },
		{ 2, 2, 4, 2, "Panel" },
		{ 1, 4, 6, 2, "Panel" },
		{ 2, 6, 4, 1, "Panel" },
		{ 2, 2, 1, 1, "White" },
		{ 4, 2, 1, 1, "111111" },
		{ 1, 4, 1, 1, "111111" },
		{ 5, 4, 1, 1, "111111" },
		{ 4, 6, 1, 1, "111111" },
	},
}
PixelIcons.Icons = Icons

return PixelIcons
