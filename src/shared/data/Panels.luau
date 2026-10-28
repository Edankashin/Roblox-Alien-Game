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
	Top = 0.10,
	BandHeight = 0.13,
	BodyTint = 0.12,
	-- The first row of a body under the band: the band's height plus this gap, as a share of the panel's height.
	BodyGap = 0.015,
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
	Peddler = { color = "Featured", icon = "Shop", title = "PEDDLER_TITLE", pills = { "PILL_PEDDLER_LEAVES" } },
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

return Panels
