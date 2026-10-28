--!strict
-- data/Panels: the numbers and mappings of the calm panels (Clean UI pass, package C; docs/vault/05-ui-design/Clean-UI-Pass.md).
-- Shared/PanelQuiet does the arithmetic and tests/PanelQuiet.spec.luau checks it; the screens read this table and never hold the
-- numbers. Strings are keyed in strings/en.

export type Section = { title: string, keys: { string } }

local Panels = {}

-- Settings: the two section headings and the data/Settings keys under each, in display order. A key that is in data/Settings but
-- named nowhere here lands under the first heading (PanelQuiet.SettingsItems), so a new setting always shows. The promo-code row
-- follows the last section. `HeadingWeight` is a heading's height as a share of a row's; `Gap` the space between two items, of the
-- rows frame.
Panels.SettingsSections = {
	{ title = "SETTINGS_SECTION_Sound", keys = { "Ambience", "Music", "Sounds", "ReducedMotion", "Silhouettes", "Announcements" } },
	{ title = "SETTINGS_SECTION_Home", keys = { "HomeLock" } },
} :: { Section }
Panels.SettingsHeadingWeight = 0.7
Panels.SettingsGap = 0.01

-- Quests: the tab a panel opens on when more than one has something to claim (the first listed wins), and Field Notes when none has.
Panels.QuestTabPriority = { "notes", "daily", "event" }
Panels.QuestTabDefault = "notes"

-- The shell every modal panel wears (UI richness pass, docs/vault/05-ui-design/UI-Richness-Pass.md section 2, package A). Fractions of
-- the screen unless a name says otherwise. The panel keeps its screen's width (PanelHeaderMath.ShellAspect turns the old aspect into
-- the one that holds it at the new height); the HUD hides all but the Scrap pill while a panel is open and that pill ends at Top, so the
-- band clears it. BandHeight is the header band's height as a share of the panel's, BodyTint how far the cream body leans toward the
-- band's colour (Builder.tint), Accent the colour (a Theme.Colors key) of the second status pill for each band colour.
Panels.Shell = {
	Height = 0.84,
	Top = 0.11,
	BandHeight = 0.13,
	BodyTint = 0.12,
	-- Where a body's first row may start, as a share of the panel's height: under the band (the panel's ink, about 0.019, plus
	-- BandHeight) with a little air. Every panel at the shell's height has 20 rows at the panel cell, so this is one number.
	BodyTop = 0.16,
	-- A takeover with no plate of its own (the Shop) puts the X this far right, of the screen's width.
	EdgeRight = 0.99,
	-- and starts its icon this far from the left, of the screen's width, clear of Roblox's own buttons (the old Shop title stood at 0.16).
	TakeoverLeft = 0.12,
	Accent = { Featured = "Select", Select = "Featured", Codex = "Featured", ShopBackdrop = "Featured" },
}

-- One row per panel (section 2 "Per-panel header"): the band's colour (a Theme.Colors key), the icon (a data/PixelIcons key, the
-- screen's Menu row), the title (a strings key) and the pills' templates (strings keys; pill 1 is plain, pill 2 the accent).
-- Builder.panelHeader reads the row; the screen passes each pill's values to setPills, read from State where it already reads them.
export type Header = { color: string, icon: string, title: string, pills: { string } }
Panels.Headers = {
	Aliens = { color = "Featured", icon = "Aliens", title = "ALIENS_TITLE", pills = { "PILL_ALIENS", "PILL_COMPANIONS" } },
	Codex = { color = "Codex", icon = "Codex", title = "CODEX_TITLE", pills = { "PILL_CODEX_FOUND", "PILL_CODEX_PAGE" } },
	Ship = { color = "Featured", icon = "Ship", title = "SHIP_TITLE", pills = { "PILL_SHIP_MODULES", "PILL_SHIP_CREW" } },
	StarChart = { color = "Select", icon = "StarChart", title = "STARCHART_TITLE", pills = { "PILL_WORLDS", "PILL_READY" } },
	Quests = { color = "Select", icon = "Quests", title = "QUESTS_TITLE", pills = { "PILL_QUESTS_CLAIM", "PILL_QUESTS_NOTES" } },
	Gifts = { color = "Featured", icon = "Gifts", title = "GIFTS_TITLE", pills = { "PILL_GIFTS_DAY", "PILL_GIFTS_SPINS" } },
	Playtime = { color = "Featured", icon = "Playtime", title = "PLAYTIME_TITLE", pills = { "PILL_PLAYTIME_TODAY", "PILL_PLAYTIME_GIFTS" } },
	Shop = { color = "ShopBackdrop", icon = "Shop", title = "SHOP_TITLE", pills = { "PILL_SHOP_SCRAP" } },
	Mail = { color = "Select", icon = "Mail", title = "MAIL_TITLE", pills = { "PILL_MAIL_LETTERS", "PILL_MAIL_CLAIM" } },
	Visit = { color = "Select", icon = "Friends", title = "VISIT_TITLE", pills = { "PILL_VISIT_ONLINE" } },
	Ranks = { color = "Featured", icon = "Ranks", title = "LB_TITLE", pills = { "PILL_RANKS_YOU" } },
	Peddler = { color = "Featured", icon = "Shop", title = "PEDDLER_TITLE", pills = { "PEDDLER_LEAVES" } },
	Settings = { color = "Select", icon = "Settings", title = "SETTINGS_TITLE", pills = {} },
} :: { [string]: Header }

-- Button colour roles (section 2): no screen picks a colour of its own. Each value names a Theme.Colors key, or a Theme.Rarity key
-- for the grey (the Common grey every inactive button already wears). Builder.roleColor(role) resolves it.
--   main: the one main action of a card or footer; robux: any button whose price is Robux (always with the Robux icon); current: the
--   thing that is already so (HERE, Following, Owned, disabled; with the Check icon); select: a secondary action beside the main one;
--   close: the X and a destructive confirm only; featured: tags and pills, never a button.
Panels.Roles = {
	main = "Confirm",
	robux = "Robux",
	current = "Common",
	select = "Select",
	close = "Close",
	featured = "Featured",
} :: { [string]: string }

-- Tile states (Builder.stamp): a flat block chip across a tile's bottom edge, one at a time. `color` as in Roles, `word` a strings key,
-- `icon` a data/PixelIcons key or "". Height is the chip's share of the tile's, Inset the margin at each side, of the tile's width.
export type Stamp = { color: string, word: string, icon: string }
Panels.Stamps = {
	Owned = { color = "Common", word = "ROLE_OWNED", icon = "Check" },
	Equipped = { color = "Confirm", word = "ROLE_EQUIPPED", icon = "Check" },
	Companion = { color = "Confirm", word = "ROLE_COMPANION", icon = "" },
	Riding = { color = "Featured", word = "ROLE_RIDING", icon = "" },
} :: { [string]: Stamp }
Panels.StampHeight = 0.18
Panels.StampInset = 0.05

-- Tier frames (Builder.tierFrame): the rarity ink stays; the ladder adds studs (a flat cell in the tier colour a step lighter,
-- Lighten, filling a corner notch of the card) at the corners in the order TopLeft, TopRight, BottomLeft, BottomRight, and a face tint
-- toward the tier colour. At most four more frames a card; rarer is never bigger (B45) and never fiercer (B46).
export type TierFrame = { studs: number, tint: number }
Panels.TierFrames = {
	Common = { studs = 0, tint = 0 },
	Uncommon = { studs = 0, tint = 0 },
	Rare = { studs = 1, tint = 0 },
	Epic = { studs = 2, tint = 0 },
	Legendary = { studs = 4, tint = 0.12 },
	Cosmic = { studs = 4, tint = 0.18 },
	Secret = { studs = 4, tint = 0.18 },
} :: { [string]: TierFrame }
Panels.StudLighten = 0.35
Panels.StudOrder = { "TopLeft", "TopRight", "BottomLeft", "BottomRight" }

-- Section strips (Builder.sectionStrip): a plain flat plate, full width, in the band's colour a step darker. Height is its share of
-- the body's (callers in a list pass their own share), Darken the step, CountWidth the count pill's share of the strip.
Panels.Strip = {
	Height = 0.05,
	Darken = 0.2,
	CountHeight = 0.72,
	CountPad = 0.5,
	Pad = 0.02,
}

-- Aliens footer (fractions of the panel's width): the button row, left to right: Release, the Storage Bay button; at the right edge
-- (a Companion Token button, while a token is held), Fuse, Optimize. With a token held the Bay button takes its short label and
-- width (STORAGE_BAY_SHORT) so the row still fits an iPhone SE panel.
Panels.AliensFooter = {
	Margin = 0.02,
	Gap = 0.01,
	Release = 0.15,
	ReleaseWithToken = 0.14,
	Bay = 0.38,
	BayWithToken = 0.23,
	Token = 0.21,
	Fuse = 0.165,
	Optimize = 0.175,
}

-- Featured plus grid (UI richness pass, package C; docs/vault/05-ui-design/UI-Richness-Pass.md section 4). Shared/FeaturedMath does the
-- arithmetic and tests/FeaturedMath.spec.luau checks it; UI/FeaturedCard draws the card and the Aliens and Codex screens place it.
-- Fractions of the panel (x of its width, y of its height) unless a name says Px. At a panel of MinPanelW by MinPanelH px or more (the
-- default Studio window and an iPad) the side mode shows: the featured card on the left, the grid on the right. Under that (an iPhone SE
-- panel is 425 by 315) the strip mode shows: the card as one strip across the top of the body, the grid full width under it.
Panels.Featured = {
	MinPanelW = 620,
	MinPanelH = 330,
	MaxFlavour = 48, -- characters of one flavour line (strings FLAVOUR_<species>, FLAVOUR_TIER_<tier>)
	-- Side mode: the card and the grid share the body's width; Wide is a full-width row (the strip mode's card and grid, the station strip).
	Side = { CardX = 0.02, CardW = 0.30, GridX = 0.34, GridW = 0.64 },
	Wide = { X = 0.02, W = 0.96 },
	-- Aliens: the station strip sits across the top in both modes (StationY, StationH); the card and the grid fill the rest down to the footer.
	Aliens = {
		StationY = 0.165,
		StationH = 0.175,
		SideTop = 0.345,
		StripTop = 0.345, -- the strip mode's card, StripH tall (0.2 of the body, which is 0.82 of the panel, less a little), then its grid
		StripH = 0.16,
		StripGridTop = 0.51,
		Bottom = 0.854, -- the footer's button row starts at 0.864
		-- The grid's columns: the cell's width and the gap, of the grid's canvas width (a UIGridLayout cell: the height is the width in px).
		Columns = { side = 3, strip = 5 },
		Cell = { side = 0.31, strip = 0.18 },
		Gap = { side = 0.035, strip = 0.02 },
	},
	-- Codex: no station strip, so the card and the grid start under the band. MinCellPx is the narrowest a tile may be (a ten-letter name
	-- at the 14 px floor needs about 80), Columns the fewest and most across, GapPx the space between tiles and between sections, StripPx
	-- the section strip's least height (a 14 px label needs 22).
	Codex = {
		SideTop = 0.17,
		Bottom = 0.975,
		StripTop = 0.17,
		StripH = 0.16,
		StripGridTop = 0.335,
		MinCellPx = 80,
		MinColumns = 3,
		MaxColumns = 5,
		GapPx = 6,
		StripPx = 22,
		StripShare = 0.07, -- a section strip's height, of the grid window's, never under StripPx
	},
	-- The side card, top to bottom, as fractions of the card's height (FeaturedMath.SideLayout): the model on its plinth takes what the
	-- rest leaves, then the tier tag, the name, the flavour line (two lines of 14 px at the narrowest card), up to three fact lines (the
	-- Codex), and the buttons (a second one, Ride or Display, stands under the main one). Pad is the card's margin, Gap the space between.
	Card = {
		Pad = 0.035,
		Gap = 0.012,
		Tag = 0.07,
		Name = 0.09,
		Flavour = 0.13,
		Fact = 0.062,
		Button = 0.12,
		ButtonGap = 0.012,
		ViewMin = 0.2,
		InsetX = 0.06, -- the text's margin at each side, of the card's width
		TagW = 0.62, -- the tier tag's width, of the card's
	},
	-- The strip card (FeaturedMath.StripLayout), fractions of the strip's height or width: the plinth is square, PlinthH of the strip tall;
	-- the main button takes MainW of its width on the right, the second one SideW left of it; the name row and the flavour row stack in
	-- the column between, the tier tag at the right end of the name row (TagW of the column).
	StripCard = {
		Pad = 0.012,
		Gap = 0.012,
		PlinthH = 0.84,
		MainW = 0.27,
		SideW = 0.19,
		ButtonH = 0.72,
		NameY = 0.05,
		NameH = 0.46,
		FlavourY = 0.55,
		FlavourH = 0.4,
		TagW = 0.34,
		TagH = 0.4,
	},
	ButtonScreenH = 0.06, -- a card button's height, of the screen's (Builder.blockButtonRows), so its cells match a footer button's
	PlinthTint = 0.55, -- the plinth's face: the tier colour this far toward white
	ViewInset = 0.04, -- the model's view inside the plinth, of the plinth, at each side
	FactSize = 14, -- px of a fact line (a quiet line, one line, truncated)
}

return Panels
