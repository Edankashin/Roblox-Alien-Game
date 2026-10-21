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
BLOCK_SCREENS = ("Compass.luau", "NearbyPanel.luau", "AliensScreen.luau", "ShopScreen.luau", "QuestsScreen.luau", "SettingsScreen.luau", "Toast.luau", "NotifyCard.luau", "CodexScreen.luau", "MailScreen.luau", "LeaderboardScreen.luau", "PeddlerScreen.luau")


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

    def test_the_screens_moved_to_block_cells_keep_no_old_look(self):
        # UI Playbook "Screens after the HUD": a screen in block cells has no rounded, gradient, gloss or chunky-pill helper left,
        # and no corner, stroke or gradient instance of its own (a rarity ring is a plate's ink, a button a block button).
        for name in BLOCK_SCREENS:
            source = lint_data.uncomment((ROOT / "src/client/UI" / name).read_text())
            for helper in ("Builder.pill(", "Builder.button(", "Builder.gradient(", "Builder.gloss(", "Builder.corner(",
                           "Builder.restyleButton(", "corner = Theme.Corner", "UICorner", "UIGradient"):
                self.assertNotIn(helper, source, f"{name}: {helper}")


if __name__ == "__main__":
    unittest.main()
