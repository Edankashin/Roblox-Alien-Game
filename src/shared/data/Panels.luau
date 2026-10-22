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
