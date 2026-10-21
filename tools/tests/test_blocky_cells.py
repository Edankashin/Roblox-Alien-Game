"""Tests for tools/blocky/cells.py (the block-cell textures, Decision B44) and the spec's `material` key and prop notes.

Standard library only (./tools/test.sh runs it; no Blender, no Pillow). The rules under test are the "Cells" and "Environment" sections of
docs/vault/06-art-pipelines/Blocky-Style.md: the face cell, the jitter, the edges and grout, the motifs, the face drawn cell for cell, culling,
packing and the atlas coordinates; and every creature and prop note must plan, pack and paint.
"""
from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
_C = importlib.util.spec_from_file_location("blocky_cells", ROOT / "tools/blocky/cells.py")
C = importlib.util.module_from_spec(_C)
_C.loader.exec_module(C)  # type: ignore[union-attr]
S = C.S
CREATURES = sorted((ROOT / "docs/vault/07-alien-game/Creatures").glob("*.md"))
PROPS = sorted((ROOT / "docs/vault/07-alien-game/Props").glob("*.md"))


def part(name="Block", size=(1, 1, 1), at=(0, 0.5, 0), slot="Body", material=None, **kw):
    raw = {"name": name, "slot": slot, "size": list(size), "at": list(at)}
    if material:
        raw["material"] = material
    raw.update(kw)
    return S.normalise(raw)


def one_island(p, orient, cell=0.25):
    return next(i for i in C.islands([p], cell, cull=False) if i["orient"] == orient)


class Hashing(unittest.TestCase):
    def test_rand_is_deterministic_and_in_range(self):
        self.assertEqual(C.rand(1, 2, 3), C.rand(1, 2, 3))
        self.assertNotEqual(C.rand(1, 2, 3), C.rand(1, 2, 4))
        values = [C.rand(5, k, -k) for k in range(2000)]
        self.assertTrue(all(0.0 <= v < 1.0 for v in values))
        self.assertAlmostEqual(sum(values) / len(values), 0.5, delta=0.03)

    def test_noise_in_range_and_smooth(self):
        vals = [C.noise(3, x, y, 3) for x in range(-6, 6) for y in range(-6, 6)]
        self.assertTrue(all(0.0 <= v <= 1.0 for v in vals))
        # neighbours differ less than far cells on average (blobs, not static)
        near = sum(abs(C.noise(3, x, 0, 3) - C.noise(3, x + 1, 0, 3)) for x in range(200)) / 200
        far = sum(abs(C.noise(3, x, 0, 3) - C.noise(3, x + 17, 0, 3)) for x in range(200)) / 200
        self.assertLess(near, far)


class Colour(unittest.TestCase):
    def test_zero_shade_is_identity(self):
        for h in ("#6CCB5F", "#FFC83D", "#4A4166", "#F0E6CE", "#142019"):
            rgb = S.hex_rgb(h)
            self.assertTrue(all(abs(a - b) <= 1 for a, b in zip(C.shade(rgb, 0.0), rgb)), h)

    def test_shade_moves_lightness_not_hue(self):
        import math
        for h in ("#6CCB5F", "#FF7A30", "#8B5CF6", "#3FA2E6"):
            rgb = S.hex_rgb(h)
            L0, a0, b0 = C.rgb_to_lab(rgb)
            for dl in (-6.0, 6.0):
                L1, a1, b1 = C.rgb_to_lab(C.shade(rgb, dl))
                self.assertAlmostEqual(L1 - L0, dl, delta=1.2, msg=h)
                hue0, hue1 = math.atan2(b0, a0), math.atan2(b1, a1)
                self.assertLess(abs(math.remainder(hue1 - hue0, 2 * math.pi)), 0.12, h)

    def test_out_of_gamut_gives_chroma_not_hue(self):
        import math
        rgb = S.hex_rgb("#FFE36B")   # a light yellow a step up leaves sRGB at full chroma (at +12 it is white, where hue means nothing)
        out = C.shade(rgb, 6.0)
        self.assertTrue(all(0 <= c <= 255 for c in out))
        L0, a0, b0 = C.rgb_to_lab(rgb)
        L1, a1, b1 = C.rgb_to_lab(out)
        self.assertAlmostEqual(L1 - L0, 6.0, delta=0.6)
        self.assertLess(math.hypot(a1, b1), math.hypot(a0, b0))
        self.assertLess(abs(math.remainder(math.atan2(b1, a1) - math.atan2(b0, a0), 2 * math.pi)), 0.05)


class Geometry(unittest.TestCase):
    def test_orient_of(self):
        self.assertEqual(C.orient_of((0, 0, -1)), "-z")
        self.assertEqual(C.orient_of((1, 0, 0)), "+x")
        self.assertEqual(C.orient_of((0, -1, 0)), "-y")
        self.assertEqual(C.orient_of((0, 0.7071, -0.7071)), "+y")   # a wedge's slope, a bevel's 45-degree strip: the top
        self.assertEqual(C.orient_of((0.7071, 0, -0.7071)), "-z")   # front beats side

    def test_front_runs_from_the_creatures_right(self):
        # rule 3: face column 0 is on the viewer's left, the creature's right (+x)
        self.assertEqual(C.project("-z", (1.0, -0.5, -0.5), (2, 1, 1)), (0.0, 0.0))
        self.assertEqual(C.project("-z", (-1.0, 0.5, -0.5), (2, 1, 1)), (2.0, 1.0))
        u, v = C.project("+x", (0.5, 0.0, -0.5), (1, 1, 1))
        self.assertEqual(v, 0.5)

    def test_island_cells_are_whole_and_square(self):
        p = part(size=(2, 1, 1.5), at=(0, 0.5, 0))
        isl = {i["orient"]: i for i in C.islands([p], 0.25, cull=False)}
        self.assertEqual(len(isl), 6)
        self.assertEqual((isl["-z"]["nu"], isl["-z"]["nv"]), (8, 4))
        self.assertEqual((isl["+x"]["nu"], isl["+x"]["nv"]), (6, 4))
        self.assertEqual((isl["+y"]["nu"], isl["+y"]["nv"]), (8, 6))
        # a face smaller than a cell still gets one, never zero or a sliver
        tiny = one_island(part(size=(0.125, 0.125, 0.125), at=(0, 0.0625, 0)), "-z")
        self.assertEqual((tiny["nu"], tiny["nv"]), (1, 1))


class Culling(unittest.TestCase):
    def test_stacked_blocks_lose_their_shared_faces(self):
        a = part("A", (2, 1, 2), (0, 0.5, 0))
        b = part("B", (2, 1, 2), (0, 1.5, 0))
        names = {(i["part"], i["orient"]) for i in C.islands([a, b], 0.25)}
        self.assertNotIn(("A", "+y"), names)
        self.assertNotIn(("B", "-y"), names)
        self.assertIn(("A", "-y"), names)
        self.assertIn(("B", "+y"), names)
        self.assertEqual(len(names), 10)

    def test_a_smaller_cover_hides_nothing(self):
        a = part("A", (2, 1, 2), (0, 0.5, 0))
        b = part("B", (1, 1, 1), (0, 1.5, 0))
        names = {(i["part"], i["orient"]) for i in C.islands([a, b], 0.25)}
        self.assertIn(("A", "+y"), names)       # only partly covered: kept
        self.assertNotIn(("B", "-y"), names)    # fully on A: culled

    def test_bevelled_and_moving_parts_keep_every_face(self):
        a = part("A", (2, 1, 2), (0, 0.5, 0))
        bev = part("Bev", (2, 1, 2), (0, 1.5, 0), bevel=True)
        mover = part("Wing", (2, 1, 2), (0, 2.5, 0), moves="wing", pivot=[0, 2, 0])
        names = {(i["part"], i["orient"]) for i in C.islands([a, bev, mover], 0.25)}
        self.assertEqual(sum(1 for n in names if n[0] == "Bev"), 6)
        self.assertEqual(sum(1 for n in names if n[0] == "Wing"), 6)
        self.assertNotIn(("A", "+y"), names)    # the bevelled mass still hides what is under it

    def test_hidden_by_extra_boxes(self):
        a = part("A", (2, 1, 2), (0, 0.5, 0))
        floor = {"name": "Floor", "size": [4, 1, 4], "at": [0, -0.5, 0], "rot": [0, 0, 0], "shape": "box", "moves": "none"}
        names = {(i["part"], i["orient"]) for i in C.islands([a], 0.25, statics=[a, floor])}
        self.assertNotIn(("A", "-y"), names)


class Packing(unittest.TestCase):
    def test_no_overlap_and_power_of_two(self):
        parts = [part("P%d" % k, (0.5 + 0.25 * (k % 5), 1, 0.75), (3 * k, 0.5, 0)) for k in range(20)]
        isl = C.islands(parts, 0.125)
        w, h = C.pack(isl)
        self.assertEqual(w & (w - 1), 0)
        self.assertEqual(h & (h - 1), 0)
        rects = []
        for i in isl:
            x0, y0 = i["x"] - C.GUTTER, i["y"] - C.GUTTER
            x1, y1 = i["x"] + i["nu"] * C.PX + C.GUTTER, i["y"] + i["nv"] * C.PX + C.GUTTER
            self.assertTrue(0 <= x0 and 0 <= y0 and x1 <= w and y1 <= h)
            rects.append((x0, y0, x1, y1))
        for k, a in enumerate(rects):
            for b in rects[k + 1:]:
                self.assertFalse(a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3], (a, b))

    def test_uv_corners(self):
        isl = C.islands([part(size=(1, 1, 1))], 0.25, cull=False)
        w, h = C.pack(isl)
        i = isl[0]
        u0, v0 = C.uv(i, 0.0, 0.0, w, h)
        u1, v1 = C.uv(i, i["su"], i["sv"], w, h)
        self.assertAlmostEqual(u0, i["x"] / w)
        self.assertAlmostEqual(v0, 1 - (i["y"] + i["nv"] * C.PX) / h)   # v = 0 is the island's bottom row
        self.assertAlmostEqual(u1, (i["x"] + i["nu"] * C.PX) / w)
        self.assertAlmostEqual(v1, 1 - i["y"] / h)


class Motifs(unittest.TestCase):
    def test_every_material_has_a_motif_and_params(self):
        self.assertEqual(tuple(C.MATERIALS), tuple(S.MATERIALS))
        for m in C.MATERIALS:
            self.assertIn(m, C.MOTIFS)
            self.assertIn(m, C.PARAMS)

    def test_jitter_share(self):
        p = part(size=(8, 8, 8), at=(0, 4, 0))
        isl = one_island(p, "-z", 0.125)
        levels = []
        for j in range(isl["nv"]):
            for i in range(isl["nu"]):
                c = C.Cell(i, j, isl["nu"], isl["nv"], i, j, 0, "-z", p, "skin")
                levels.append(C.jitter_level(c))
        n = len(levels)
        self.assertAlmostEqual(levels.count(-1) / n, C.JITTER_SHARE, delta=0.03)
        self.assertAlmostEqual(levels.count(1) / n, C.JITTER_SHARE, delta=0.03)

    def test_edge_rule(self):
        p = part(size=(1, 1, 1))
        params = C.PARAMS["skin"]
        side = lambda i, j: C.edge_steps(C.Cell(i, j, 4, 4, i, j, 0, "-z", p, "skin"), params)  # noqa: E731
        self.assertEqual(side(1, 3), params["side_top"])     # top row lit
        self.assertEqual(side(0, 1), params["side_edge"])    # left border darker
        self.assertEqual(side(1, 0), params["side_edge"])    # bottom border darker
        self.assertEqual(side(1, 1), 0.0)                    # inside: nothing
        small = C.Cell(0, 0, 2, 2, 0, 0, 0, "-z", p, "skin")
        self.assertEqual(C.edge_steps(small, params), 0.0)   # under three cells: no edge

    def test_grass_sides_are_dirt_under_a_fringe(self):
        p = part(size=(2, 1, 2), at=(0, 0.5, 0), material="grass")
        isl = one_island(p, "-z")
        cols = {"base": S.hex_rgb("#6FBF4A"), "aux": S.hex_rgb("#8A5A3B"), "accent": S.hex_rgb("#6FBF4A")}
        cells = {(i, j): rgb for i, j, rgb in C.island_cells(isl, cols)}
        top = [cells[(i, isl["nv"] - 1)] for i in range(isl["nu"])]
        bottom = [cells[(i, 0)] for i in range(isl["nu"])]
        greenish = lambda rgb: rgb[1] > rgb[0]  # noqa: E731
        self.assertTrue(all(greenish(c) for c in top))
        self.assertFalse(any(greenish(c) for c in bottom))

    def test_flat_paints_the_slot_colour(self):
        p = part(size=(1, 1, 1), material="moss")
        isl = one_island(p, "+y")
        cols = {"base": (10, 200, 30), "aux": (0, 0, 0), "accent": (255, 255, 0)}
        self.assertTrue(all(rgb == (10, 200, 30) for _, _, rgb in C.island_cells(isl, cols, flat=True)))

    def test_grout_and_no_grout_on_water(self):
        for material, expect in (("skin", True), ("water", False)):
            p = part(size=(1, 1, 1), material=material)
            isl = [one_island(p, "-z")]
            isl[0]["x"] = isl[0]["y"] = 0
            w, h = isl[0]["nu"] * C.PX, isl[0]["nv"] * C.PX
            buf = C.paint(isl, w, h, lambda _i: {"base": (120, 160, 200), "aux": (0, 0, 0), "accent": (0, 0, 0)}, px=C.PX, gutter=0, grout=1)
            # texel (PX - 1, 1) is a cell's right grout column, texel (PX - 2, 1) inside the same cell
            px = lambda x, y: tuple(buf[(y * w + x) * 3:(y * w + x) * 3 + 3])  # noqa: E731
            darker = sum(px(C.PX - 1, 1)) < sum(px(C.PX - 2, 1))
            self.assertEqual(darker, expect, material)


class Notes(unittest.TestCase):
    def test_the_face_cell_is_the_body_cell(self):
        cells = {}
        for path in CREATURES:
            spec = S.load(path)
            host = S.face_host(spec)
            cells[spec["front"]["id"]] = C.creature_cell(spec)
            self.assertAlmostEqual(C.creature_cell(spec), host["size"][0] / len(spec["face"]["rows"][0]))
        self.assertEqual(cells["Mossbop"], 0.125)
        self.assertEqual(cells["Radish"], 0.0625)   # B45 and B46: a 2-stud head at 32 columns, so the Cosmic carries finer cells

    def test_every_creature_paints_with_its_face(self):
        for path in CREATURES:
            spec = S.load(path)
            a = C.atlas(spec)
            self.assertLessEqual(max(a["width"], a["height"]), 1024, path.name)
            face = C.face_cells(spec)
            front = next(i for i in a["islands"] if i["part"] == face["part"] and i["orient"] == "-z")
            self.assertEqual((front["nu"], front["nv"]), (len(face["rows"][0]), len(face["rows"])), path.name)
            # every ink, shine, crescent and cheek cell is drawn exactly
            for i, j, rgb in C.island_cells(front, C.creature_colours(spec)(front), face):
                ch = face["rows"][front["nv"] - 1 - j][i]
                if ch not in face["body"]:
                    self.assertEqual(rgb, face["rgb"][ch], (path.name, i, j))

    def test_deterministic(self):
        spec = S.load(CREATURES[0])
        self.assertEqual(C.atlas(spec)["rgb"], C.atlas(spec)["rgb"])

    def test_props_validate_and_paint_at_the_world_cell(self):
        self.assertGreaterEqual(len(PROPS), 5)
        for path in PROPS:
            spec = S.load(path)
            errors, _ = S.validate(spec)
            self.assertEqual(errors, [], path.name)
            self.assertEqual(C.creature_cell(spec), C.WORLD_CELL)
            C.atlas(spec)


class SpecMaterial(unittest.TestCase):
    def test_defaults(self):
        self.assertEqual(part().get("material"), "skin")
        self.assertEqual(part(slot="Glow")["material"], "glow")
        self.assertEqual(part(material="moss")["material"], "moss")

    def test_unknown_material_is_an_error(self):
        spec = S.load(CREATURES[0])
        spec["parts"][0]["material"] = "velvet"
        errors, _ = S.validate(spec)
        self.assertTrue(any("material" in e for e in errors), errors)

    def test_a_prop_must_stand_on_the_ground(self):
        spec = S.load(PROPS[0])
        for p in spec["parts"]:
            p["at"] = [p["at"][0], p["at"][1] + 0.5, p["at"][2]]
        errors, _ = S.validate(spec)
        self.assertTrue(any("stands on y = 0" in e for e in errors), errors)


if __name__ == "__main__":
    unittest.main()
