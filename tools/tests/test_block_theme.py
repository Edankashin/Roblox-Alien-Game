"""Tests that Theme.Block (src/shared/Theme.luau) is what tests/BlockMath.spec.luau checks the HUD's fit with, and that the HUD
is built in block cells only, with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). Theme needs the Roblox runtime (Enum, Color3), so the headless spec cannot load it; this reads the
block as text. The spec also mirrors the HUD's sizes and aspects from src/client/UI/Hud.luau; this checks that the aspects it
names are the ones Hud uses, and that Hud keeps no rounded, gradient or gloss helper (UI Playbook "Block cells": one look).
"""
from __future__ import annotations

import pathlib
import re
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import lint_data  # noqa: E402

# The screens rebuilt in block cells after the HUD, one per change (UI Playbook "Screens after the HUD").
BLOCK_SCREENS = (
    "Compass.luau",
    "AliensScreen.luau",
    "ShopScreen.luau",
    "QuestsScreen.luau",
    "SettingsScreen.luau",
    "Toast.luau",
    "NotifyCard.luau",
    "CodexScreen.luau",
    "FeaturedCard.luau",
    "MailScreen.luau",
    "LeaderboardScreen.luau",
    "PeddlerScreen.luau",
    "PlaytimeScreen.luau",
    "VisitScreen.luau",
    "StarChartScreen.luau",
    "GiftsScreen.luau",
    "ShipScreen.luau",
    "AfkScreen.luau",
    "CinematicBars.luau",
    "TutorialHint.luau",
    "PowerUpBar.luau",
    "ReleasePanel.luau",
    "BuildScreen.luau",
    "CaptureBar.luau",
    "Reveal.luau",
)


def block_numbers():
    source = lint_data.uncomment((ROOT / "src/shared/Theme.luau").read_text())
    match = re.search(r"Theme\.Block\s*=\s*\{(.*?)\n\}", source, re.S)
    assert match, "Theme.Block not found"
    numbers = {}
    for line in match[1].splitlines():
        found = re.match(r"\s*(\w+)\s*=\s*([\d.]+)\s*,", line)
        if found:
            numbers[found[1]] = float(found[2])
    return numbers


class BlockTheme(unittest.TestCase):
    def setUp(self):
        self.block = block_numbers()
        self.spec = (ROOT / "tests/BlockMath.spec.luau").read_text()
        self.hud = lint_data.uncomment((ROOT / "src/client/UI/Hud.luau").read_text())

    def test_the_spec_uses_the_theme_numbers(self):
        found = re.search(r"local CELL, INK, MIN_ROWS, GROUT, SEED = ([\d.]+), ([\d.]+), (\d+), ([\d.]+), (\d+)", self.spec)
        self.assertTrue(found, "the spec's parameter line moved")
        for index, key in enumerate(("Cell", "Ink", "MinRows", "Grout", "Seed"), 1):
            self.assertEqual(float(found[index]), self.block[key], key)

    def test_the_cells_rule_numbers(self):
        # Blocky-Style C2 and C3: seed 44, one texel of grout at eight texels a cell.
        self.assertEqual(self.block["Seed"], 44)
        self.assertEqual(self.block["Grout"], 1 / 8)
        self.assertEqual(self.block["PixelGrid"], 8)
        # data/PixelIcons.DefaultGrid is the same number (the headless spec cannot require Theme); the Menu's icons name 16 in Grids.
        icons = (ROOT / "src/shared/data/PixelIcons.luau").read_text()
        default = re.search(r"PixelIcons\.DefaultGrid = (\d+)", icons)
        self.assertTrue(default, "PixelIcons.DefaultGrid moved")
        self.assertEqual(int(default[1]), self.block["PixelGrid"])
        for key in ("GroutAlpha", "TopAlpha", "EdgeAlpha", "JitterAlpha"):
            self.assertTrue(0 < self.block[key] < 1, key)

    def test_the_spec_mirrors_the_hud_aspects(self):
        for constant in ("SCRAP_ASPECT", "CHIP_ASPECT", "BANNER_ASPECT", "FRIEND_CHIP_ASPECT", "ACTION_ASPECT", "CLOCK_ASPECT"):
            value = re.search(rf"local {constant} = ([\d.]+)", self.hud)
            self.assertTrue(value, constant)
            self.assertRegex(self.spec, rf"aspect = {re.escape(value[1])},", constant)

    def test_the_hud_is_built_in_block_cells_only(self):
        for helper in ("Builder.pill(", "Builder.button(", "Builder.gradient(", "Builder.gloss(", "Builder.corner("):
            self.assertNotIn(helper, self.hud, helper)
        self.assertNotIn("UICorner", self.hud)

    def test_the_spec_uses_the_panel_cell(self):
        found = re.search(r"local PANEL_CELL = ([\d.]+)", self.spec)
        self.assertTrue(found, "the spec's PANEL_CELL line moved")
        self.assertEqual(float(found[1]), self.block["PanelCell"])
        self.assertEqual(self.block["PanelCell"], 2 * self.block["Cell"], "Blocky-Style C1: the big cell is twice the small one")

    def test_the_spec_uses_the_cell_budget(self):
        # Studio 2026-10-22, the start-up script timeout: the spec's "Block budget" checks every real grid against this number.
        found = re.search(r"local MAX_CELLS = (\d+)", self.spec)
        self.assertTrue(found, "the spec's MAX_CELLS line moved")
        self.assertEqual(float(found[1]), self.block["MaxCells"])
        self.assertTrue(0 < self.block["FitBudget"] < 1 / 60, "a fitted-plate batch must leave most of a frame")

    def test_the_screens_moved_to_block_cells_keep_no_old_look(self):
        # UI Playbook "Screens after the HUD": a screen in block cells has no rounded, gradient, gloss or chunky-pill helper left,
        # and no corner, stroke or gradient instance of its own (a rarity ring is a plate's ink, a button a block button).
        for name in BLOCK_SCREENS:
            source = lint_data.uncomment((ROOT / "src/client/UI" / name).read_text())
            for helper in ("Builder.pill(", "Builder.button(", "Builder.gradient(", "Builder.gloss(", "Builder.corner(",
                           "Builder.restyleButton(", "corner = Theme.Corner", "UICorner", "UIGradient"):
                self.assertNotIn(helper, source, f"{name}: {helper}")


    def test_pixel_icons_name_real_theme_colours(self):
        # data/PixelIcons: a colour that is not six hex digits is a Theme.Colors key (Builder.pixelIcon reads it there first).
        theme = lint_data.uncomment((ROOT / "src/shared/Theme.luau").read_text())
        block = re.search(r"Theme\.Colors\s*=\s*\{(.*?)\n\}", theme, re.S)
        self.assertTrue(block, "Theme.Colors not found")
        names = set(re.findall(r"^\s*(\w+)\s*=", block[1], re.M))
        icons = (ROOT / "src/shared/data/PixelIcons.luau").read_text()
        found = re.findall(r'\{ \d+, \d+, \d+, \d+, "(\w+)" \}', icons)
        self.assertTrue(found)
        for colour in found:
            if not re.fullmatch(r"[0-9A-Fa-f]{6}", colour):
                self.assertIn(colour, names, colour)


# The nine screens package A of the UI richness pass moved to Builder.panelHeader (docs/vault/05-ui-design/UI-Richness-Pass.md section 7).
BAND_SCREENS = {
    "QuestsScreen.luau": "Quests",
    "GiftsScreen.luau": "Gifts",
    "PlaytimeScreen.luau": "Playtime",
    "SettingsScreen.luau": "Settings",
    "MailScreen.luau": "Mail",
    "VisitScreen.luau": "Visit",
    "LeaderboardScreen.luau": "Ranks",
    "PeddlerScreen.luau": "Peddler",
    "ShopScreen.luau": "Shop",
}


class PanelBand(unittest.TestCase):
    def setUp(self):
        self.theme = lint_data.uncomment((ROOT / "src/shared/Theme.luau").read_text())
        self.panels = lint_data.uncomment((ROOT / "src/shared/data/Panels.luau").read_text())

    def colour_names(self):
        block = re.search(r"Theme\.Colors\s*=\s*\{(.*?)\n\}", self.theme, re.S)
        self.assertTrue(block, "Theme.Colors not found")
        return set(re.findall(r"^\s*(\w+)\s*=", block[1], re.M))

    def test_the_band_numbers_are_in_the_theme_on_one_line(self):
        found = re.search(r"^\s*Band = \{(.*)\},\s*$", self.theme, re.M)
        self.assertTrue(found, "Theme.Block.Band moved or is no longer one line")
        keys = dict(re.findall(r"(\w+) = ([\d.]+)", found[1]))
        for key in ("Pad", "Icon", "Pill", "Close", "PillPad", "PillCorner", "PillGap", "TitleGap", "CloseOverlap", "TitleStep"):
            self.assertIn(key, keys, key)
        # the one line is read by block_numbers() as a nested table: it must not shadow a Block key the spec checks
        for key in keys:
            self.assertNotIn(key, ("Cell", "Ink", "MinRows", "Grout", "Seed", "PanelCell"), key)
        self.assertEqual(float(keys["Close"]), 0.8)
        self.assertEqual(float(keys["Pill"]), 0.56)
        self.assertEqual(float(keys["Icon"]), 0.7)
        self.assertEqual(float(keys["CloseOverlap"]), 0.25)

    def test_robux_is_clear_of_legendary(self):
        robux = re.search(r'Robux = Color3\.fromHex\("(\w{6})"\)', self.theme)
        legendary = re.search(r'Legendary = Color3\.fromHex\("(\w{6})"\)', self.theme)
        self.assertTrue(robux and legendary)
        self.assertEqual(robux[1].upper(), "FF7A1A")
        self.assertNotEqual(robux[1].upper(), legendary[1].upper())

    def test_every_header_names_a_theme_colour_and_the_roles_resolve(self):
        names = self.colour_names()
        rarities = set(re.findall(r"^\s*(\w+) = Color3", re.search(r"Theme\.Rarity = \{(.*?)\n\}", self.theme, re.S)[1], re.M))
        colours = re.findall(r'color = "(\w+)", icon = "(\w+)"', self.panels)
        self.assertEqual(len(colours), 13)
        for colour, _ in colours:
            self.assertIn(colour, names, colour)
        accents = re.search(r"Accent = \{(.*?)\}", self.panels, re.S)
        self.assertTrue(accents)
        for band, accent in re.findall(r'(\w+) = "(\w+)"', accents[1]):
            self.assertIn(band, names, band)
            self.assertIn(accent, names, accent)
        roles = re.search(r"Panels\.Roles = \{(.*?)\}", self.panels, re.S)
        for role, colour in re.findall(r'(\w+) = "(\w+)"', roles[1]):
            self.assertTrue(colour in names or colour in rarities, f"{role} -> {colour}")

    def test_the_nine_screens_call_panel_header_and_not_the_old_tab(self):
        for name, panel in BAND_SCREENS.items():
            source = lint_data.uncomment((ROOT / "src/client/UI" / name).read_text())
            self.assertIn("Builder.panelHeader(", source, name)
            self.assertIn(f'panelId = "{panel}"', source, name)
            self.assertNotIn("Builder.blockHeader(", source, name)
            if name != "ShopScreen.luau":  # the Shop is a full-screen takeover with a fitted band (panelAspect 0), not a shell panel
                self.assertRegex(source, r"Panels\.Shell\.(Top|Height)", name)

    def test_the_panel_anatomy_is_built_in_the_builder_and_screens_make_no_rounded_pills(self):
        builder = lint_data.uncomment((ROOT / "src/client/UI/Builder.luau").read_text())
        for function in ("panelHeader", "sectionStrip", "stamp", "tierFrame", "tint", "roleColor", "setButtonMark"):
            self.assertIn(f"function Builder.{function}(", builder, function)
        for name in BAND_SCREENS:
            source = lint_data.uncomment((ROOT / "src/client/UI" / name).read_text())
            self.assertNotIn("UICorner", source, name)

    def test_the_goal_card_reads_the_shared_rules(self):
        hint = lint_data.uncomment((ROOT / "src/client/UI/TutorialHint.luau").read_text())
        for call in ("HudStages.Fraction(", "HudStages.NotesProgress(", "HudStages.GoalReward(", "HudStages.GoalShares(", "Builder.blockBar("):
            self.assertIn(call, hint, call)
        hud = lint_data.uncomment((ROOT / "src/shared/data/Hud.luau").read_text())
        for key in ("TextShareReward", "RewardShare", "CounterShare"):
            self.assertRegex(hud, rf"\b{key}\s*=", key)


if __name__ == "__main__":
    unittest.main()
