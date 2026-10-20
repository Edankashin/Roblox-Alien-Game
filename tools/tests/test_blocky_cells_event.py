"""Tests for the three cell materials of the World 1 fixes and the Haunted Nebula event in tools/blocky/cells.py (whorl, ember, nebula), the
"World 1 fixes and the event species" section of docs/vault/06-art-pipelines/Blocky-Style.md.

Standard library only (./tools/test.sh runs it). Each motif is checked for the pattern it claims (a coil on a slab's flat faces and panels
elsewhere, lit tongues rising from the bottom of a flame with a ragged crest, billows with star cells in the glow colour), for being
deterministic, and for leaving the seventeen earlier motifs untouched (their ids and swatch colours are unchanged, so every earlier atlas is
pixel-identical).
"""
from __future__ import annotations

import importlib.util
import math
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
_C = importlib.util.spec_from_file_location("blocky_cells_event", ROOT / "tools/blocky/cells.py")
C = importlib.util.module_from_spec(_C)
_C.loader.exec_module(C)  # type: ignore[union-attr]
S = C.S
EARLIER = ("skin", "moss", "grass", "dirt", "stone", "metal", "crystal", "wood", "water", "glow", "wool",
           "snow", "packed_snow", "ice", "frozen_water", "pine", "fur")
EVENT = ("whorl", "ember", "nebula")
COPPER, FLAME, CLOUD = S.hex_rgb("#C9803E"), S.hex_rgb("#9BE7FF"), S.hex_rgb("#5B3FA8")
STAR, WHITE = S.hex_rgb("#FFF3B0"), S.hex_rgb("#FFFFFF")


def part(name="Block", size=(4, 4, 4), at=(0, 2, 0), slot="Body", material=None, **kw):
    raw = {"name": name, "slot": slot, "size": list(size), "at": list(at)}
    if material:
        raw["material"] = material
    raw.update(kw)
    return S.normalise(raw)


def island(p, orient, cell=0.25):
    return next(i for i in C.islands([p], cell, cull=False) if i["orient"] == orient)


def grid(material, orient, base, aux=None, accent=None, glow=None, size=(4, 4, 4), cell=0.25):
    """{(i, j): rgb} of one face in `material`, and the island."""
    p = part(size=size, at=(0, size[1] / 2, 0), material=material)
    isl = island(p, orient, cell)
    cols = {"base": base, "aux": aux or base, "accent": accent or base, "glow": glow or accent or base}
    return {(i, j): rgb for i, j, rgb in C.island_cells(isl, cols)}, isl


def steps(material, p, orient, cell=0.25):
    """{(i, j): (key, steps)} of the raw motif over one face, without edges or jitter."""
    isl = island(p, orient, cell)
    plane = int(round(isl["plane"] / cell * 2))   # as island_cells keys the hashes
    out = {}
    for j in range(isl["nv"]):
        for i in range(isl["nu"]):
            gu = math.floor((isl["u0"] + (i + 0.5) * cell) / cell)   # floored, as island_cells does (int() would round negatives up)
            gv = math.floor((isl["v0"] + (j + 0.5) * cell) / cell)
            out[(i, j)] = C.MOTIFS[material](C.Cell(i, j, isl["nu"], isl["nv"], gu, gv, plane, orient, p, material))
    return out, isl


def near(a, b, tol=24):
    """True when two RGB cells are the same colour up to the jitter and an edge step."""
    return max(abs(x - y) for x, y in zip(a, b)) < tol


def lum(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


class Registry(unittest.TestCase):
    def test_the_three_are_registered_after_the_seventeen(self):
        self.assertEqual(tuple(C.MATERIALS)[:len(EARLIER)], EARLIER)
        self.assertEqual(tuple(C.MATERIALS)[len(EARLIER):len(EARLIER) + 3], EVENT)
        for m in EVENT:
            self.assertIn(m, C.MOTIFS)
            self.assertIn(m, C.PARAMS)
            self.assertIn(m, C.SURFACE)
        # the earlier ids (they seed the motifs' hashes) are unchanged by the additions
        self.assertEqual([C.MAT_ID[m] for m in EARLIER], [101 + 17 * i for i in range(len(EARLIER))])
        self.assertEqual([m for m, *_ in C.SWATCH_EVENT], list(EVENT))
        self.assertEqual([m for m, *_ in C.SWATCH], list(EARLIER[:11]))

    def test_spec_accepts_the_event_materials(self):
        for m in EVENT:
            errors = []
            S._part_checks(part(material=m), errors.append)
            self.assertEqual(errors, [], m)

    def test_the_whorl_is_metal_and_the_flame_has_a_soft_grout(self):
        self.assertGreater(C.SURFACE["whorl"]["metal"], 0.0)
        self.assertEqual(C.PARAMS["ember"].get("grout"), 0.5)
        self.assertLess(C.SURFACE["ember"]["rough"], 0.5)


class Whorl(unittest.TestCase):
    SLAB = (1.0, 1.75, 1.75)   # Snibble's shell core: a slab standing edge-on, its thin side across x

    def test_the_coil_is_on_the_flat_faces_only(self):
        p = part(size=self.SLAB, at=(0, 0.875, 0), material="whorl")
        for orient in ("-x", "+x"):
            raw, isl = steps("whorl", p, orient, 0.125)
            self.assertEqual((isl["nu"], isl["nv"]), (14, 14))
            line = [k for k, (_, s) in raw.items() if s == -2.0]
            ridge = [k for k, (_, s) in raw.items() if s == 0.5]
            self.assertTrue(0.3 < len(line) / len(raw) < 0.6, len(line) / len(raw))   # two cells of line in every four rings, not a grid
            self.assertTrue(ridge)
            # the whorl's eye: the centre cells a step down
            self.assertEqual({raw[(i, j)][1] for i in (6, 7) for j in (6, 7)}, {-1.0})
        # the narrow faces take the metal panels (a seam a step down every fourth cell)
        raw, isl = steps("whorl", p, "-z", 0.125)
        self.assertEqual((isl["nu"], isl["nv"]), (8, 14))
        self.assertNotIn(-2.0, {s for _, s in raw.values()})
        self.assertIn(-1.0, {s for _, s in raw.values()})

    def test_the_line_is_one_spiral_that_steps_out_each_quarter_of_a_lap(self):
        p = part(size=self.SLAB, at=(0, 0.875, 0), material="whorl")
        raw, isl = steps("whorl", p, "-x", 0.125)
        # read the line ring by ring: each ring carries one arc (about half its lap, never the whole ring), rings r, r + 1 and r + 2 carry
        # different quarters, and one lap later (ring r + 4) the next turn sits on the same quarter as ring r
        arcs = {}
        for (i, j), (_, s) in raw.items():
            if s == -2.0:
                ring, t = C._square_turn(i + 0.5 - 7, j + 0.5 - 7)
                arcs.setdefault(ring, []).append(t)
        self.assertEqual(sorted(arcs), list(range(1, 7)))

        def span(ts):   # the arc's length round the lap (it may wrap past t = 1)
            s = sorted(ts)
            return 1.0 - max((s[(k + 1) % len(s)] - s[k]) % 1.0 for k in range(len(s)))

        def mean(ts):   # the arc's middle, as a circular mean
            return (math.atan2(sum(math.sin(2 * math.pi * t) for t in ts), sum(math.cos(2 * math.pi * t) for t in ts)) / (2 * math.pi)) % 1.0

        def apart(a, b):
            d = abs(a - b) % 1.0
            return min(d, 1.0 - d)
        mid = {r: mean(v) for r, v in arcs.items()}
        for r, ts in arcs.items():
            self.assertLess(span(ts), 0.6, (r, ts))
            self.assertLess(len(ts), 8 * r)   # ring r has 8r perimeter cells; the line takes a part of them
        self.assertTrue(all(apart(mid[a], mid[b]) > 0.2 for a, b in ((1, 2), (2, 3), (1, 3))), mid)
        P = C.WHORL_PITCH
        self.assertLess(apart(mid[1], mid[1 + P]), 0.15, mid)
        self.assertLess(apart(mid[2], mid[2 + P]), 0.15, mid)

    def test_a_small_face_has_no_room_for_a_coil(self):
        # a 4-cell face takes the metal panels (one seam, one rivet); a 3-cell face is one plain plate
        p = part(size=(0.25, 0.5, 0.5), at=(0, 0.25, 0), material="whorl")
        raw, isl = steps("whorl", p, "-x", 0.125)
        self.assertLess(max(isl["nu"], isl["nv"]), C.WHORL_MIN)
        self.assertNotIn(-2.0, {s for _, s in raw.values()})
        tiny = part(size=(0.25, 0.375, 0.375), at=(0, 0.1875, 0), material="whorl")
        raw, _ = steps("whorl", tiny, "-x", 0.125)
        self.assertEqual({s for _, s in raw.values()}, {0.0})

    def test_a_whorl_face_is_deterministic_and_keeps_the_hue(self):
        a, _ = grid("whorl", "-x", COPPER, cell=0.125, size=(1, 2, 2))
        b, _ = grid("whorl", "-x", COPPER, cell=0.125, size=(1, 2, 2))
        self.assertEqual(a, b)
        self.assertGreater(len(set(a.values())), 3)
        for rgb in a.values():
            self.assertGreater(rgb[0], rgb[1])
            self.assertGreater(rgb[1], rgb[2])   # every cell stays copper: red over green over blue


class Ember(unittest.TestCase):
    def test_tongues_rise_from_the_bottom_with_a_ragged_crest(self):
        p = part(size=(4, 4, 4), at=(0, 2, 0), material="ember")
        raw, isl = steps("ember", p, "-z")
        heights = []
        for i in range(isl["nu"]):
            h = 0
            while h < isl["nv"] and raw[(i, h)][1] >= 1.0:
                h += 1
            heights.append(h)
            # above the lit tongue: one crest cell at a half step, then the colour itself (or a spark)
            if h < isl["nv"]:
                self.assertEqual(raw[(i, h)][1], 0.5)
            for j in range(h + 1, isl["nv"]):
                self.assertIn(raw[(i, j)], (("base", 0.0), ("accent", 0.0)))
        lo, hi = C.EMBER_TONGUE
        self.assertTrue(all(int(round(lo * isl["nv"])) - 1 <= h <= int(round(hi * isl["nv"])) for h in heights), heights)
        self.assertGreater(len(set(heights)), 2)   # ragged, not a straight waterline

    def test_a_flame_side_is_lighter_at_the_bottom_than_the_top(self):
        cells, isl = grid("ember", "-z", FLAME, accent=WHITE)
        bottom = [lum(cells[(i, 1)]) for i in range(1, isl["nu"] - 1)]
        top = [lum(cells[(i, isl["nv"] - 2)]) for i in range(1, isl["nu"] - 1)]
        self.assertGreater(sum(bottom) / len(bottom), sum(top) / len(top))
        sparks = [k for k, rgb in cells.items() if rgb == WHITE]
        self.assertLess(len(sparks), len(cells) * 0.05)
        self.assertTrue(all(j >= isl["nv"] * C.EMBER_TONGUE[0] - 1 for _, j in sparks))   # sparks sit above the tongues, never in the core
        # the bottom face is the flame's core, a full step up; the top a half step
        self.assertEqual(C._ember(C.Cell(2, 2, 8, 8, 2, 2, 0, "-y", part(material="ember"), "ember")), ("base", 1.0))
        self.assertEqual(C._ember(C.Cell(2, 2, 8, 8, 2, 2, 0, "+y", part(material="ember"), "ember")), ("base", 0.5))

    def test_ember_is_deterministic(self):
        a, _ = grid("ember", "+x", FLAME, accent=WHITE)
        b, _ = grid("ember", "+x", FLAME, accent=WHITE)
        self.assertEqual(a, b)


class Nebula(unittest.TestCase):
    def test_stars_are_glow_cells_in_about_one_cell_in_forty(self):
        p = part(size=(8, 8, 8), at=(0, 4, 0), material="nebula")
        raw, isl = steps("nebula", p, "-z")
        stars = [k for k, (key, _) in raw.items() if key == "glow"]
        share = len(stars) / len(raw)
        self.assertTrue(0.01 < share < 0.05, share)
        # a twinkle: some stars have all four neighbours lifted three quarters of a step over the billow
        halos = [k for k, (key, s) in raw.items() if key == "base" and s % 1 == 0.75 or (key == "base" and (s - 0.75) % 1 == 0)]
        self.assertTrue(halos)
        cells, _ = grid("nebula", "-z", CLOUD, glow=STAR, size=(8, 8, 8))
        # a star cell is the glow colour (shaded only by the jitter and an edge step, so still far lighter than any cloud cell)
        painted = [k for k, rgb in cells.items() if lum(rgb) > 150]
        self.assertEqual(sorted(painted), sorted(stars))
        self.assertTrue(all(cells[k][0] >= cells[k][1] >= cells[k][2] for k in stars))   # and keeps the star's warm hue

    def test_billows_and_a_dust_lane_move_in_half_and_whole_steps_only(self):
        p = part(size=(8, 8, 8), at=(0, 4, 0), material="nebula")
        raw, _ = steps("nebula", p, "+x")
        levels = {s for key, s in raw.values() if key == "base"}
        self.assertTrue(all(abs(s * 4 - round(s * 4)) < 1e-9 for s in levels), levels)   # quarter multiples at most: never a continuous shade
        self.assertLess(len(levels), 13)   # billow, lane and twinkle combine to a dozen fixed levels at most
        self.assertGreater(len(levels), 2)
        # the dust lane sits on the (gu + gv) diagonal: every cell a full step or more down lies on a lane line, two cells wide
        isl = island(p, "+x")
        lane = [k for k, (key, s) in raw.items() if key == "base" and s <= -1.0]
        self.assertTrue(lane)
        for i, j in lane:
            gu = math.floor((isl["u0"] + (i + 0.5) * 0.25) / 0.25)
            gv = math.floor((isl["v0"] + (j + 0.5) * 0.25) / 0.25)
            self.assertIn((gu + gv) % C.NEBULA_LANE, (0, 1), (i, j))

    def test_nebula_is_deterministic_and_the_top_is_lighter(self):
        a, _ = grid("nebula", "-z", CLOUD, glow=STAR)
        b, _ = grid("nebula", "-z", CLOUD, glow=STAR)
        self.assertEqual(a, b)
        top, _ = grid("nebula", "+y", CLOUD, glow=STAR)
        side, _ = grid("nebula", "-z", CLOUD, glow=STAR)
        inner = lambda cells, isl_n=16: [lum(c) for (i, j), c in cells.items() if 0 < i < isl_n - 1 and 0 < j < isl_n - 1 and c != STAR]  # noqa: E731
        self.assertGreater(sum(inner(top)) / len(inner(top)), sum(inner(side)) / len(inner(side)))


class Earlier(unittest.TestCase):
    def test_earlier_motifs_are_unchanged_by_the_event_set(self):
        moss = S.hex_rgb("#6CCB5F")
        cells, _ = grid("moss", "+y", moss, accent=S.hex_rgb("#D9F36B"))
        self.assertEqual(C.MAT_ID["moss"], 118)
        self.assertEqual(C.MAT_ID["fur"], 101 + 17 * 16)
        self.assertEqual(len(cells), 256)
        # a swatch face of an earlier material paints the same with the glow key present (no earlier motif returns it)
        faces = C.swatch_faces("wool", "#4A4166", None, "#8E6BFF")
        self.assertEqual(len(faces), 3)


if __name__ == "__main__":
    unittest.main()
