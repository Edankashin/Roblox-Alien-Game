"""Tests for tools/blocky/world_gen.py, the block-cell world generator (docs/vault/06-art-pipelines/World-Gen.md).

Standard library only (./tools/test.sh runs it). The generation is deterministic and the committed Luau matches it; the greedy merge
covers every column with exactly its own cap and only ever runs a part under a column where it is hidden in the ground; paths never
step more than one stud; the shrine, the landmarks and every spot not marked `jump` are reachable on foot from the camp and no column
is a trap; the counts stay under the kit's budget; the props, kinds and the layout's shrine agree with the data the game reads.
"""
from __future__ import annotations

import importlib.util
import pathlib
import re
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
_G = importlib.util.spec_from_file_location("world_gen", ROOT / "tools/blocky/world_gen.py")
G = importlib.util.module_from_spec(_G)
_G.loader.exec_module(G)  # type: ignore[union-attr]

WORLDS = (1, 2)
_cache: dict = {}


def gen(wid):
    if wid not in _cache:
        _cache[wid] = G.generate(wid)
    return _cache[wid]


class Noise(unittest.TestCase):
    def test_value_noise_is_deterministic_and_bounded(self):
        for x, z in ((0.0, 0.0), (3.7, -2.2), (101.5, 44.25)):
            a = G.vnoise(x, z, 7)
            self.assertEqual(a, G.vnoise(x, z, 7))
            self.assertTrue(0.0 <= a < 1.0)
        self.assertNotEqual(G.vnoise(1.5, 1.5, 1), G.vnoise(1.5, 1.5, 2))

    def test_rng_is_deterministic(self):
        a, b = G.Rng(5), G.Rng(5)
        self.assertEqual([a.next() for _ in range(10)], [b.next() for _ in range(10)])

    def test_shapes(self):
        self.assertAlmostEqual(G.shape_distance({"type": "circle", "x": 0, "z": 0, "r": 10}, 13, 0), 3.0)
        self.assertLess(G.shape_distance({"type": "rect", "x0": -2, "z0": -2, "x1": 2, "z1": 2}, 0, 0), 0)
        self.assertAlmostEqual(G.shape_distance({"type": "rect", "x0": -2, "z0": -2, "x1": 2, "z1": 2}, 5, 6), 5.0)
        self.assertLess(G.shape_distance({"type": "poly", "pts": [[0, 0], [10, 0], [0, 10]]}, 2, 2), 0)


class Merge(unittest.TestCase):
    def test_merge_covers_each_cell_once_inside_chunks(self):
        n, chunk = 12, 5
        cells = {j * n + i for j in range(n) for i in range(n) if (i * 7 + j * 3) % 5 != 0}
        rects = G.merge_cells(cells, n, chunk)
        seen = []
        for i, j, w, d in rects:
            self.assertEqual(i // chunk, (i + w - 1) // chunk)
            self.assertEqual(j // chunk, (j + d - 1) // chunk)
            seen += [(j + b) * n + i + a for b in range(d) for a in range(w)]
        self.assertEqual(sorted(seen), sorted(cells))

    def test_free_cells_join_rectangles_without_double_cover(self):
        n = 6
        cells = {j * n + i for j in range(n) for i in range(n) if i != 2}
        free = {j * n + 2 for j in range(n)}
        with_free = G.merge_cells(cells, n, 6, free)
        without = G.merge_cells(cells, n, 6)
        self.assertLess(len(with_free), len(without))
        covered = [(j + b) * n + i + a for i, j, w, d in with_free for b in range(d) for a in range(w)]
        self.assertEqual(sorted(c for c in covered if c in cells), sorted(cells))


class Worlds(unittest.TestCase):
    def test_deterministic_and_committed(self):
        for wid in WORLDS:
            world, caps, bodies, waters, stats = gen(wid)
            again = G.generate(wid)
            self.assertEqual(caps, again[1])
            self.assertEqual(world.props, again[0].props)
            committed = (ROOT / f"src/shared/data/WorldGen{wid}.luau").read_text()
            self.assertEqual(committed, G.emit_world(world, caps, bodies, waters, stats), "run python3 -I tools/blocky/world_gen.py")
        import json
        kit = json.loads((ROOT / "tools/blocky/worlds/kit.json").read_text())
        self.assertEqual((ROOT / "src/shared/data/WorldKit.luau").read_text(), G.emit_kit(kit))

    def test_checks_pass(self):
        for wid in WORLDS:
            world, caps, bodies, waters, stats = gen(wid)
            self.assertEqual(G.check_world(world, stats), [])

    def test_caps_give_every_column_its_height_and_hide_the_rest(self):
        for wid in WORLDS:
            world, caps, bodies, waters, stats = gen(wid)
            n, h = world.n, world.h
            best = [None] * (n * n)
            for i, j, w, d, top, kind, mask in caps:
                for b in range(d):
                    for a in range(w):
                        c = (j + b) * n + i + a
                        if h[c] == top and world.K[c] == kind:
                            self.assertIsNone(best[c], "a column covered twice by its own cap")
                            best[c] = top
                        else:
                            # a cap under a higher column: every neighbour of that column reaches the cap's top
                            self.assertGreater(h[c], top)
                            ci, cj = c % n, c // n
                            for ii, jj in ((ci + 1, cj), (ci - 1, cj), (ci, cj + 1), (ci, cj - 1)):
                                if 0 <= ii < n and 0 <= jj < n:
                                    self.assertGreaterEqual(h[jj * n + ii], top)
            self.assertNotIn(None, best)

    def test_paths_step_one_stud_at_most(self):
        for wid in WORLDS:
            world = gen(wid)[0]
            n = world.n
            for c in world.path_cells:
                i, j = c % n, c // n
                for ii, jj in ((i + 1, j), (i, j + 1)):
                    nb = jj * n + ii
                    if nb in world.path_cells:
                        self.assertLessEqual(abs(world.h[c] - world.h[nb]), 1)

    def test_the_camp_is_flat_at_the_old_floor_top(self):
        for wid in WORLDS:
            world = gen(wid)[0]
            for x in range(-30, 31, 6):
                for z in range(-30, 31, 6):
                    if x * x + z * z <= 30 * 30:
                        self.assertEqual(world.h[world.index_at(x, z)], 0)

    def test_the_layout_shrine_matches_the_description(self):
        names = {1: "Meadow", 2: "Frostbyte"}
        for wid in WORLDS:
            world = gen(wid)[0]
            text = (ROOT / f"src/shared/data/{names[wid]}.luau").read_text()
            m = re.search(r"Shrine = \{ x = (-?\d+), z = (-?\d+)", text)
            self.assertIsNotNone(m)
            self.assertEqual([int(m.group(1)), int(m.group(2))], world.desc["shrine"])
            for name, x, z in world.desc["landmarks"]:
                if f'name = "{name}"' in text:
                    self.assertRegex(text, r'name = "%s", x = %d, z = %d' % (name, x, z))

    def test_props_have_recipes_and_stand_on_the_ground(self):
        for wid in WORLDS:
            world = gen(wid)[0]
            for name, x, y, z, yaw, scale in world.props:
                self.assertIn(name, world.kit["recipes"])
                self.assertTrue(-200 < x < 200 and -200 < z < 200)
                self.assertTrue(0.5 <= scale <= 1.5)

    def test_the_camp_is_a_deck_with_a_kerb_and_keeps_its_gameplay_clear(self):
        """The camp deck (Services/Meadow draws no round pad over it) is CampPadThickness at the origin and off the grid (walk 0), so
        SurfaceAt stays the floor top; the stations, the ship's hull, the spawn pad and the peddler's landing spot stay free of props."""
        camp = (ROOT / "src/shared/data/Camp.luau").read_text(encoding="utf-8")
        peddler = re.search(r"PeddlerOffset = Vector3.new\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", camp)
        keep = [(-17, 6, 3.5), (17, 6, 3.5), (0, 19, 2), (0, 0, 4.5), (float(peddler[1]), float(peddler[3]), 4.5)]
        for wid in WORLDS:
            world = gen(wid)[0]
            thick = float(re.search(r"CampPadThickness = ([\d.]+)", (ROOT / "src/shared/data" / ("Meadow.luau" if wid == 1 else "Frostbyte.luau"))
                                    .read_text(encoding="utf-8"))[1])
            decks = [s for s in world.solids if s[0] < 0 < s[3] and s[2] < 0 < s[5] and s[1] <= 0 and abs(s[4] - thick) < 0.01]
            self.assertEqual(len(decks), 1)
            self.assertEqual(decks[0][7], 0)
            self.assertGreaterEqual(sum(1 for s in world.solids if abs(s[0]) <= 14 and abs(s[3]) <= 14 and abs(s[2]) <= 14 and abs(s[5]) <= 14) - 1, 8)
            for name, x, y, z, yaw, scale in world.props:
                for kx, kz, r in keep:
                    self.assertGreater((x - kx) ** 2 + (z - kz) ** 2, r * r, f"world {wid}: {name} at ({x}, {z}) crowds ({kx}, {kz})")
                self.assertFalse(-6 < x < 6 and -30 < z < -10, f"world {wid}: {name} at ({x}, {z}) is under the ship's hull")
            arms = ("SignArmHigh", "SignArmMid", "SignArmLow") if wid == 1 else ("IceSignArmHigh", "IceSignArmMid", "IceSignArmLow")
            self.assertTrue({"SightPost", "CampCrate", "CampFlag", *arms} <= {p[0] for p in world.props})

    def test_every_world_has_its_exploration(self):
        want = {1: {"Lookout", "WaterfallNook", "MoonPool", "GlowcapGrove", "CrystalGrotto"},
                2: {"AuroraRidge", "FrozenFallNook", "CrystalHall", "HotSpring", "LakeIsle"}}
        for wid in WORLDS:
            world = gen(wid)[0]
            self.assertTrue(want[wid] <= {s["id"] for s in world.spots})
            for s in world.spots:
                self.assertGreaterEqual(s["luck"], 1)
        self.assertGreaterEqual(len(gen(1)[0].falls), 1)


if __name__ == "__main__":
    unittest.main()
