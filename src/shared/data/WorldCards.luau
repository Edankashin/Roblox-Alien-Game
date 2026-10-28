--!strict
-- data/WorldCards: the Star Chart's world cards and the Ship's next-stop strip (UI richness pass, package B;
-- docs/vault/05-ui-design/UI-Richness-Pass.md section 3). One row per world (data/Worlds ids, the Home planet at 0): its place colour
-- (the card's ink and its number badge; a place colour never reuses a rarity colour as a signal), the five palette colours the
-- cell diorama is drawn from while its picture is not up (sky, skyLow, far, ground, accent: the sun, moon or planet), the picture's
-- asset id (0 until the uploader fills it: nothing waits on an upload), and the line a locked card shows. Colours are six-digit
-- hex strings (Theme.Hex reads them). World 1 and World 2 are crops of the hero renders (assets/sprites/worlds/World1.png, World2.png);
-- the Home card wants a render of the camp pad (World0.png) and Worlds 3 to 7 are designed, not built, so they stay on the diorama.
-- Shared/WorldCardMath does the arithmetic (the species roster, the diorama's towers, the next stop, the grid's rows) and
-- tests/WorldCardMath.spec.luau checks it. Strings are keyed in strings/en.

export type Palette = { sky: string, skyLow: string, far: string, ground: string, accent: string }
export type WorldCardDef = {
	color: string, -- the card's ink and its number badge
	palette: Palette,
	image: number, -- the picture's asset id; 0 = not uploaded, the diorama draws
	unlockLineKey: string, -- the strings key of the locked line; a %s in it is the name of the world whose ship opens this one
	unlockAfter: number, -- the world id whose ship opens this one (0 where no world does: the Home planet, a launch opens it)
}

local Cards: { [number]: WorldCardDef } = {
	[0] = {
		color = "D8B26E",
		palette = { sky = "2B3A67", skyLow = "6B7FB5", far = "4A5575", ground = "C9A06A", accent = "FFE9A6" },
		image = 0,
		unlockLineKey = "STARCHART_HOME_LOCKED",
		unlockAfter = 0,
	},
	[1] = {
		color = "3FBF5A",
		palette = { sky = "62B3EC", skyLow = "D8EEF5", far = "3F8F4F", ground = "6BCB3F", accent = "FFD84A" },
		image = 0,
		unlockLineKey = "STARCHART_LOCKED",
		unlockAfter = 0,
	},
	[2] = {
		color = "7FD3F7",
		palette = { sky = "78A8D6", skyLow = "DDE8F2", far = "A9B7C0", ground = "F2F6FA", accent = "BFE9FF" },
		image = 0,
		unlockLineKey = "WORLDCARD_UNLOCK",
		unlockAfter = 1,
	},
	[3] = {
		color = "E11DB0",
		palette = { sky = "1B1040", skyLow = "5A2FA0", far = "2A2A6A", ground = "12122E", accent = "FF3DBE" },
		image = 0,
		unlockLineKey = "WORLDCARD_UNLOCK",
		unlockAfter = 2,
	},
	[4] = {
		color = "FF8A2B",
		palette = { sky = "3A1410", skyLow = "B3441C", far = "5A2418", ground = "2B1A18", accent = "FF8A2B" },
		image = 0,
		unlockLineKey = "WORLDCARD_UNLOCK",
		unlockAfter = 3,
	},
	[5] = {
		color = "22C2B0",
		palette = { sky = "1E7FA6", skyLow = "7ADFD0", far = "1C5E7A", ground = "E7D6A3", accent = "FFF2B8" },
		image = 0,
		unlockLineKey = "WORLDCARD_UNLOCK",
		unlockAfter = 4,
	},
	[6] = {
		color = "FF8FC4",
		palette = { sky = "C9A8FF", skyLow = "FFD9F0", far = "F7B6E0", ground = "FFE9F5", accent = "FFFFFF" },
		image = 0,
		unlockLineKey = "WORLDCARD_UNLOCK",
		unlockAfter = 5,
	},
	[7] = {
		color = "8B5CF6",
		palette = { sky = "0B0820", skyLow = "3A1E6E", far = "1A1240", ground = "0E0A24", accent = "8B5CF6" },
		image = 0,
		unlockLineKey = "WORLDCARD_UNLOCK",
		unlockAfter = 6,
	},
}

return {
	Cards = Cards,
	Columns = 2, -- the Star Chart grid's columns (two at iPhone SE as well)
	Row = 5, -- species chips on a card
	RowNarrow = 4, -- ... under NarrowPanelPx of panel width
	NarrowPanelPx = 520,
	Aspect = 2.2, -- a card's width over its height
	HeightShare = 0.26, -- a card's height as a share of the screen, for its cell rows (a screen estimate; the card keeps its aspect)
	Gap = 0.015, -- the inset of a card inside its grid slot, of the slot's width
	-- The cell diorama (a flat band picture drawn from the palette). Shares of the card's height: sky and skyLow on top, far under
	-- them, ground at the bottom (the four sum to 1). Columns are the diorama's cell columns across the card; its rows follow from the
	-- box's aspect so a cell is square. The skyline is Towers.Min to Towers.Max flat towers in `far` rising above the far band, each
	-- Towers.BaseCells plus a hash level (BlockMath.Level, -1 to 1) cells tall, so a world's skyline is the same on every build.
	Diorama = {
		Columns = 44,
		SkyShare = 0.25,
		SkyLowShare = 0.20,
		FarShare = 0.25,
		GroundShare = 0.30,
		Towers = { Min = 1, Max = 3, BaseCells = 3, WidthCells = 4, Seed = 11 },
		Accent = { Cells = 3, AtShare = 0.72, TopRows = 1, Seed = 23 }, -- the sun, moon or planet: a square block this many cells across
	},
	-- The dark block that keeps the text readable: the lower share of the height across the full width, and the left share of the
	-- rest, in two non-overlapping rectangles (a stepped L, no gradient).
	Scrim = { Transparency = 0.55, LowerShare = 0.45, LeftShare = 0.40 },
	Badge = 0.16, -- the number badge's diameter, of the card's height
	Chip = 0.14, -- a species chip's side, of the card's height
	ChipGap = 0.02, -- and the gap between chips, of the card's height
	LockedFade = 0.45, -- a locked card's face fade (Builder.setBlockFade)
	LockedImageTint = "7A7F96", -- the picture's tint while locked (it greys)
	UnknownTint = "2A2F55", -- an uncaught chip's face
	Ribbon = { Width = 0.2, Height = 0.14 }, -- the NEXT ribbon on the next stop, of the card
	NearScreens = 1, -- a picture loads once its card is within this many screens of the viewport
	OutpostTray = { Height = 0.16, Gap = 0.015 }, -- the Star Chart's outpost tray: its height of the panel, and the gap above it
	Compact = { Height = 0.17 }, -- the Ship's next-stop strip: its height of the panel
}
