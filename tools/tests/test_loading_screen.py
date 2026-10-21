"""The loading screen in block cells (src/first/LoadingScreen.client.luau; UI Playbook "The loading screen in block cells"): its
block-cell numbers are Theme.Block's, it keeps no rounded or gradient look and no Offset, and its layout fits at iPhone SE
(667x375) and iPad (1080x810): square cells big enough to read, the 14 px text floor, nothing overlapping the line it should not.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'  (./tools/test.sh runs it too).
The script runs before ReplicatedStorage exists and cannot require Theme or BlockMath, so it mirrors them; this keeps the copies
honest and does the fit arithmetic a Luau spec would (the script itself needs the Roblox runtime).
"""
from __future__ import annotations

import pathlib
import re
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(HERE))
import lint_data  # noqa: E402
from test_block_theme import block_numbers  # noqa: E402

SCRIPT = ROOT / "src/first/LoadingScreen.client.luau"
SCREENS = {"iPhone SE": (667, 375), "iPad": (1080, 810)}
TEXT_MIN = 14
MIN_CELL_PX = 4.5  # a cell under this is all edge (UI Playbook "Thin bands are flat")


def numbers(source: str) -> dict[str, float]:
    """Every `local A, B = 1, 2` or `local A = 1` line of plain numbers."""
    found: dict[str, float] = {}
    for names, values in re.findall(r"^local ([A-Z_, ]+?) = ([\d., ]+?)\s*(?:--|$)", source, re.M):
        keys = [n.strip() for n in names.split(",")]
        nums = [v.strip() for v in values.split(",")]
        if len(keys) == len(nums):
            for key, value in zip(keys, nums):
                found[key] = float(value)
    return found


def fit(size_x: float, size_y: float, aspect: float, parent_w: float, parent_h: float) -> tuple[float, float]:
    """BlockMath.FitPx: the largest box of `aspect` inside the Scale bounds."""
    w, h = size_x * parent_w, size_y * parent_h
    if w / h > aspect:
        return h * aspect, h
    return w, w / aspect


def aspect_of(cols: float, rows: float, ink: float) -> float:
    return (cols + 2 * ink) / (rows + 2 * ink)


class LoadingScreen(unittest.TestCase):
    def setUp(self):
        self.raw = SCRIPT.read_text()
        self.source = lint_data.uncomment(self.raw)
        self.n = numbers(self.raw)
        self.block = block_numbers()

    def test_it_mirrors_theme_block(self):
        for local, key in (("INK", "Ink"), ("GROUT", "Grout"), ("GROUT_ALPHA", "GroutAlpha"), ("TOP_ALPHA", "TopAlpha"),
                           ("EDGE_ALPHA", "EdgeAlpha"), ("JITTER_ALPHA", "JitterAlpha"), ("SEED", "Seed")):
            self.assertEqual(self.n[local], self.block[key], local)

    def test_it_mirrors_the_jitter_hash(self):
        block_math = (ROOT / "src/shared/BlockMath.luau").read_text()
        for constant in ("374761393", "668265263", "2246822519", "3266489917"):
            self.assertIn(constant, block_math)
            self.assertIn(constant, self.source)

    def test_no_old_look_no_offset_no_requires(self):
        for banned in ("UICorner", "UIGradient", "UDim2.new(", "UDim.new(", "require(script", "Shared.", "ImageLabel"):
            self.assertNotIn(banned, self.source, banned)

    def test_the_fit(self):
        n, ink = self.n, self.n["INK"]
        for name, (sw, sh) in SCREENS.items():
            with self.subTest(screen=name):
                stage, _ = fit(n["STAGE_W"], n["STAGE_H"], 1, sw, sh)
                island_w = n["ISLAND_W"] * stage
                island_cell = island_w / (n["ISLAND_COLS"] + 2 * ink)
                rock_cell = n["ROCK_W"] * stage / (n["ROCK_COLS"] + 2 * ink)
                bar_w, bar_h = fit(n["BAR_W"], n["BAR_H"], aspect_of(n["BAR_COLS"], n["BAR_ROWS"], ink), sw, sh)
                bar_cell = bar_h / (n["BAR_ROWS"] + 2 * ink)
                alien_px = n["ALIEN_SIDE"] * stage / n["PIXELS"]
                for label, cell in (("island", island_cell), ("rock", rock_cell), ("bar", bar_cell)):
                    self.assertGreaterEqual(cell, MIN_CELL_PX, f"{label} cell {cell:.1f} px")
                self.assertGreaterEqual(alien_px, 3, "an alien pixel")
                self.assertGreaterEqual(bar_cell * ink, 2, "the bar's ink")
                # the two lines hold the 14 px floor
                self.assertGreaterEqual(n["STATUS_H"] * sh, TEXT_MIN)
                self.assertGreaterEqual(n["TITLE_H"] * sh, TEXT_MIN)
                # top to bottom with no overlap: title, stage (with the hanging rock), bar, status, and all on screen
                title_bottom = (n["TITLE_Y"] + n["TITLE_H"] / 2) * sh
                stage_top = n["STAGE_Y"] * sh - stage / 2
                rock_h = n["ROCK_W"] * stage / aspect_of(n["ROCK_COLS"], n["ROCK_ROWS"], ink)
                rock_bottom = stage_top + n["ROCK_TOP"] * stage + rock_h
                peak_top = stage_top + (n["ALIEN_PEAK"] - n["ALIEN_SIDE"]) * stage
                bar_top, bar_bottom = n["BAR_Y"] * sh - bar_h / 2, n["BAR_Y"] * sh + bar_h / 2
                status_top = (n["STATUS_Y"] - n["STATUS_H"] / 2) * sh
                status_bottom = (n["STATUS_Y"] + n["STATUS_H"] / 2) * sh
                self.assertLessEqual(title_bottom, peak_top, "the hop reaches the title")
                self.assertLessEqual(rock_bottom, bar_top, "the rock reaches the bar")
                self.assertLessEqual(bar_bottom, status_top, "the bar reaches the line")
                self.assertLessEqual(status_bottom, sh)
                self.assertLessEqual(bar_w, sw)
                # the alien stands on the island's grass
                self.assertGreaterEqual(n["ALIEN_REST"], n["ISLAND_TOP"])
                self.assertLess(n["ALIEN_REST"], n["ISLAND_TOP"] + island_cell * (1 + ink) / stage)

    def test_the_text_strokes_stay_theme_numbers(self):
        theme = (ROOT / "src/shared/Theme.luau").read_text()
        for local, key in (("STROKE_REFERENCE", "ReferenceHeight"), ("STROKE_MIN", "MinScale"), ("STROKE_MAX", "MaxScale")):
            value = re.search(rf"\b{key} = ([\d.]+)", theme)
            self.assertTrue(value, key)
            self.assertEqual(self.n[local], float(value[1]), local)


if __name__ == "__main__":
    unittest.main()
