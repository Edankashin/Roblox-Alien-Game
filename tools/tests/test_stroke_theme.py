"""Tests that Theme.Stroke (src/shared/Theme.luau) holds the look the stroke sizing is specified against, with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). Theme needs the Roblox runtime (Enum, Color3), so the headless spec tests/StrokeMath.spec.luau cannot
load it; this reads the block as text and checks it against the UI Playbook's numbers (2.5 px text, 3 button, 4 panel at 1080),
the spec's parameters, the join modes Builder applies, and the loading screen's copies of them.
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


def stroke_block():
    source = lint_data.uncomment((ROOT / "src/shared/Theme.luau").read_text())
    match = re.search(r"Theme\.Stroke\s*=\s*\{(.*?)\n\}", source, re.S)
    assert match, "Theme.Stroke block not found"
    return dict(re.findall(r"(\w+)\s*=\s*([\w.]+)\s*,", match[1] + ","))


class StrokeTheme(unittest.TestCase):
    def setUp(self):
        self.block = stroke_block()

    def test_the_reference_look_is_the_playbooks(self):
        self.assertEqual(float(self.block["Text"]), 2.5)
        self.assertEqual(float(self.block["Button"]), 3)
        self.assertEqual(float(self.block["Panel"]), 4)
        self.assertEqual(float(self.block["ReferenceHeight"]), 1080)

    def test_the_clamp_keeps_text_between_two_and_three_px(self):
        text, low, high = (float(self.block[k]) for k in ("Text", "MinScale", "MaxScale"))
        self.assertLess(low, 1)
        self.assertGreater(high, 1)
        self.assertGreaterEqual(text * low, 2)
        self.assertLessEqual(text * high, 3)

    def test_the_spec_uses_the_same_parameters(self):
        spec = (ROOT / "tests/StrokeMath.spec.luau").read_text()
        reference = re.search(r"local REFERENCE = (\d+)", spec)
        clamp = re.search(r"minScale = ([\d.]+), maxScale = ([\d.]+)", spec)
        pixels = re.search(r"local TEXT, BUTTON, PANEL = ([\d.]+), ([\d.]+), ([\d.]+)", spec)
        self.assertTrue(reference and clamp and pixels)
        self.assertEqual(float(reference[1]), float(self.block["ReferenceHeight"]))
        self.assertEqual(float(clamp[1]), float(self.block["MinScale"]))
        self.assertEqual(float(clamp[2]), float(self.block["MaxScale"]))
        for index, key in enumerate(("Text", "Button", "Panel"), 1):
            self.assertEqual(float(pixels[index]), float(self.block[key]))

    def test_text_gets_a_bevel_and_borders_a_miter(self):
        self.assertEqual(self.block["TextJoin"], "Enum.LineJoinMode.Bevel")
        self.assertEqual(self.block["ShapeJoin"], "Enum.LineJoinMode.Miter")

    def test_the_loading_screen_mirrors_them(self):
        source = lint_data.uncomment((ROOT / "src/first/LoadingScreen.client.luau").read_text())
        self.assertIn(f"TEXT_JOIN = {self.block['TextJoin']}", source)
        self.assertIn(f"SHAPE_JOIN = {self.block['ShapeJoin']}", source)
        self.assertIn(f"TEXT_STROKE = {self.block['Text']}", source)
        self.assertIn(f"PANEL_STROKE = {self.block['Panel']}", source)

    def test_builder_sets_the_joins_from_the_theme(self):
        source = lint_data.uncomment((ROOT / "src/client/UI/Builder.luau").read_text())
        self.assertIn("Theme.Stroke.TextJoin", source)
        self.assertIn("Theme.Stroke.ShapeJoin", source)
        self.assertEqual(source.count('Instance.new("UIStroke")'), 1, "every stroke goes through Builder.stroke")


if __name__ == "__main__":
    unittest.main()
