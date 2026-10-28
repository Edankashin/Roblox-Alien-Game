"""Tests for the HUD's Menu drop-down (Decision B53), with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). The headless spec tests/MenuMath.spec.luau mirrors the HUD's column numbers (it cannot require Theme or
the Hud); this checks that they are the ones the HUD uses, that the 44 px row floor is the theme's tap floor, that every row the
bootstrap adds has a name and a 16 by 16 pixel icon, and that the old top-button and six-button stack API is gone.
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
import menu_icons  # noqa: E402


def source(path: str) -> str:
    return lint_data.uncomment((ROOT / path).read_text())


class MenuHud(unittest.TestCase):
    def setUp(self):
        self.hud = source("src/client/UI/Hud.luau")
        self.boot = source("src/client/init.client.luau")
        self.spec = (ROOT / "tests/MenuMath.spec.luau").read_text()
        self.theme = source("src/shared/Theme.luau")
        self.strings = source("src/shared/strings/en.luau")
        self.icons = (ROOT / "src/shared/data/PixelIcons.luau").read_text()
        self.menu = source("src/shared/data/Menu.luau")

    def number(self, text: str, name: str) -> float:
        found = re.search(rf"\b{name}\s*=\s*([\d.]+)", text)
        self.assertTrue(found, f"{name} not found")
        return float(found[1])

    def test_the_spec_mirrors_the_column(self):
        found = re.search(r"local COLUMN_TOP, SLOT_H, SLOT_W, SLOT_ASPECT = ([\d.]+), ([\d.]+), ([\d.]+), ([\d.]+)", self.spec)
        self.assertTrue(found, "the spec's column line moved")
        self.assertEqual(float(found[1]), self.number(self.hud, "local MENU_TOP"))
        menu = re.search(r"Theme\.Menu\s*=\s*\{([^}]*)\}", self.theme)
        self.assertTrue(menu, "Theme.Menu not found")
        self.assertEqual(float(found[2]), self.number(menu[1], "SlotH"))
        self.assertEqual(float(found[3]), self.number(menu[1], "SlotW"))
        self.assertEqual(float(found[4]), self.number(menu[1], "Aspect"))

    def test_the_menu_slot_is_the_second_and_hangs_the_panel(self):
        self.assertEqual(self.number(self.hud, "local MENU_SLOT_INDEX"), 1)
        self.assertIn("MENU_TOP + MENU_SLOT * MENU_SLOT_INDEX + slotH", self.hud)

    def test_the_row_floor_is_the_tap_floor(self):
        self.assertEqual(self.number(self.menu, "MinRowPx"), self.number(self.theme, r"Theme\.TapMin"))

    def test_a_row_is_taller_than_the_floor_on_a_tall_screen(self):
        # 0.075 of 663 px (the Studio default window) is 50 px.
        self.assertGreaterEqual(self.number(self.menu, "RowHeight") * 663, self.number(self.menu, "MinRowPx"))

    def test_the_panel_stays_above_the_bottom(self):
        self.assertLessEqual(self.number(self.menu, "Bottom"), 0.98)

    def test_every_row_has_a_name_and_a_sixteen_grid_icon(self):
        ids = re.findall(r'Hud\.AddMenuRow\("(\w+)"', self.boot) + ["Menu", "Shop"]
        self.assertGreaterEqual(len(ids), 10)
        grids = re.search(r"local Grids[^{]*\{(.*?)\n\}", self.icons, re.S)
        self.assertTrue(grids, "PixelIcons Grids not found")
        for row in ids:
            self.assertRegex(self.strings, rf'\bMENU_{row}\s*=\s*"', f"{row} has no MENU_ name")
            if row not in ("Playtime",):
                self.assertRegex(grids[1], rf"\b{row}\s*=\s*16", f"{row} is not on the 16 by 16 grid")

    def test_the_offer_row_has_a_name_and_an_icon(self):
        self.assertRegex(self.strings, r'\bMENU_StarterPack\s*=\s*"')
        self.assertRegex(self.icons, r"\n\tStarterPack = \{")

    def test_the_icon_data_is_what_the_drawings_make(self):
        # tools/menu_icons.py holds the drawings; src/shared/data/PixelIcons.luau holds what the game reads (run it with --write)
        menu_icons.check()
        self.assertIn(menu_icons.luau(), self.icons, "PixelIcons.luau is out of date: python3 -I tools/menu_icons.py --write")

    def test_the_old_top_button_api_is_gone(self):
        for name in ("AddTopButton", "SetTopButtonVisible", "layoutTopButtons"):
            self.assertNotIn(name, self.hud)
            self.assertNotIn(name, self.boot)

    def test_the_left_edge_keeps_only_the_shop_as_a_standalone_button(self):
        self.assertEqual(re.findall(r'Hud\.AddMenuButton\("(\w+)"', self.boot), ["Shop"])

    def test_the_menu_button_is_a_rounded_square(self):
        # three face rows leave the plus the corner cuts made of a 3 by 3 block; six read as a rounded square
        self.assertGreaterEqual(self.number(self.hud, "local MENU_BUTTON_ROWS"), 5)

    def test_zero_lines_go_through_the_pure_rules(self):
        self.assertIn("MenuMath.LuckShown(luck)", self.hud)
        self.assertIn("MenuMath.FriendBoostShown(boost)", self.hud)


class QuietHud(unittest.TestCase):
    """The clean UI pass, package A (docs/vault/05-ui-design/Clean-UI-Pass.md): the quiet HUD keeps its public API, hides behind
    panels, grows in stages, and keeps its numbers in data."""

    def setUp(self):
        self.hud = source("src/client/UI/Hud.luau")
        self.hint = source("src/client/UI/TutorialHint.luau")
        self.compass = source("src/client/UI/Compass.luau")
        self.compass_data = source("src/shared/data/Compass.luau")
        self.tutorial = source("src/shared/data/Tutorial.luau")
        self.hud_data = source("src/shared/data/Hud.luau")
        self.stages_spec = (ROOT / "tests/HudStages.spec.luau").read_text()
        self.theme = source("src/shared/Theme.luau")
        self.strings = source("src/shared/strings/en.luau")

    def test_the_bootstraps_calls_still_exist(self):
        for name in ("SetEventBanner", "SetEventCountdown", "SetLuck", "SetFriendBoost", "SetBiome", "SetBiomeLabel", "SetClock",
                     "SetShip", "SetShipTicks", "SetMenuVisible", "SetVisible", "SetStage"):
            self.assertRegex(self.hud, rf"function Hud\.{name}\(", name)

    def test_the_hud_hides_behind_a_panel_by_polling_the_screens(self):
        self.assertIn("Screens.IsAnyOpen()", self.hud)
        self.assertIn("HudData.PanelPollSeconds", self.hud)
        self.assertRegex(self.hud_data, r"PanelPollSeconds\s*=\s*0\.1\b")

    def test_the_old_centre_column_is_gone(self):
        for name in ("buildLuckLine", "buildEventBanner", "buildBiomeChip", "buildShowerChip", "CENTER_SHIFT", "BANNER_SUB_H"):
            self.assertNotIn(name, self.hud)

    def test_the_tutorial_hint_is_the_objective_line_and_drives_the_stages(self):
        self.assertNotIn("BOTTOM = 0.79", self.hint)
        self.assertIn("Hud.SetStage(", self.hint)
        self.assertIn("Compass.SetStage(", self.hint)
        self.assertIn("HudStages.Objective(", self.hint)
        self.assertIn("TUT_DONE", self.hint)

    def test_every_staged_element_has_a_stage_in_data(self):
        for element in ("Shop", "Menu", "ShipBar", "PlaceChip", "EventChip", "Landmarks"):
            self.assertRegex(self.tutorial, rf'\b{element}\s*=\s*"T\d"', element)

    def test_the_spec_floor_is_the_themes_text_floor(self):
        floor = re.search(r"local FLOOR = (\d+)", self.stages_spec)
        self.assertTrue(floor, "the spec's FLOOR line moved")
        sizes = re.search(r"Theme\.TextSize\s*=\s*\{[^}]*\bMin\s*=\s*(\d+)", self.theme)
        self.assertTrue(sizes, "Theme.TextSize not found")
        self.assertEqual(int(floor[1]), int(sizes[1]))

    def test_the_compass_line_names_only_goals_and_landmarks_wait(self):
        rows = re.findall(r'\{ id = "(\w+)", kind = "(\w+)".*?goal = (true|false)(, afterTutorial = true)? \}', self.compass_data)
        self.assertGreaterEqual(len(rows), 8)
        for ident, kind, goal, after in rows:
            self.assertEqual(goal == "true", kind in ("waypoint", "target", "peddler"), ident)
            self.assertEqual(bool(after), kind == "landmark", ident)
        self.assertIn("marker.goal", self.compass)
        self.assertIn("marker.afterTutorial", self.compass)

    def test_the_power_up_caption_is_gone(self):
        self.assertNotIn("HUD_POWERUPS", self.strings)
        self.assertNotIn("Caption", source("src/client/UI/PowerUpBar.luau"))

    def test_the_new_strings_sit_after_their_anchor(self):
        # The anchor line is TUT_PROGRESS; the UI richness pass (package A) appends its own block directly after it, so the Hud's lines
        # follow the anchor, not necessarily the very next line.
        self.assertRegex(self.strings, r'TUT_PROGRESS = "%d/%d",\s+(?:[^\n]*\n\s*)*?HUD_EVENT_LINE = ')

    def test_the_hud_keeps_strings_and_numbers_out_of_logic(self):
        # Scale only, and the layout numbers come from data/Hud
        self.assertNotIn("UDim2.fromOffset", self.hud)
        self.assertNotIn("UDim2.new(", self.hud)
        for key in ("Goal", "Chips", "Plates"):
            self.assertRegex(self.hud_data, rf"\b{key}\s*=\s*\{{")


if __name__ == "__main__":
    unittest.main()
