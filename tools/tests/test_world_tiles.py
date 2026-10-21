"""Tests for tools/blocky/world_tiles.py: the world's shared block-cell tile textures (Decision B44), with no Blender.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'  (./tools/test.sh runs it too).
The PNGs on disk must be what the tool paints, 64 x 64, one per shared key, and every tile must repeat without a seam.
"""
from __future__ import annotations

import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
import world_tiles as W  # noqa: E402

KEYS = ("GrassTop", "GrassSide", "Dirt", "Path", "Stone", "Sand", "Water", "WoodPlank", "Snow", "SnowSide", "PackedSnow", "Ice",
        "FrozenWater", "Rock", "MoonPath", "MoonGrass", "GlowWater")


class WorldTiles(unittest.TestCase):
    def test_the_keys_are_the_shared_list(self):
        self.assertEqual(W.KEYS, KEYS)

    def test_the_pngs_are_fresh_and_seamless(self):
        self.assertEqual(W.check(), [])

    def test_no_other_png_in_the_folder(self):
        names = {p.stem for p in W.OUT.glob("*.png")}
        self.assertEqual(names, set(KEYS))

    def test_a_tile_that_does_not_wrap_is_caught(self):
        saved = dict(W.RAW)
        W.RAW["Water"] = lambda i, j: ("base", 1.0 if i == 0 else 0.0, "water")
        try:
            self.assertFalse(W.seamless("Water"))
        finally:
            W.RAW.clear()
            W.RAW.update(saved)

    def test_every_cell_is_one_flat_colour(self):
        # a tile is 8 x 8 flat cells: every texel of a cell but its one-texel grout is the cell's colour
        rgb = W.tile("Path")
        for cj in range(W.N):
            for ci in range(W.N):
                first = None
                for y in range(cj * W.PX, cj * W.PX + W.PX - 1):
                    for x in range(ci * W.PX, ci * W.PX + W.PX - 1):
                        k = (y * W.SIZE + x) * 3
                        px = bytes(rgb[k:k + 3])
                        first = first or px
                        self.assertEqual(px, first)


if __name__ == "__main__":
    unittest.main()
