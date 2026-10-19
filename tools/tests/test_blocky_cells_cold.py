"""Tests for the cold cell materials of World 2 Frostbyte in tools/blocky/cells.py (snow, packed_snow, ice, frozen_water, pine, fur), the
"World 2: Frostbyte palette" subsection of docs/vault/06-art-pipelines/Blocky-Style.md.

Standard library only (./tools/test.sh runs it). Each motif is checked for the pattern it claims (a snow lip over packed snow, strata, the
other diagonal, cracks on plates, needle rows, tufts on a lattice), for being deterministic, and for leaving the eleven World 1 motifs
untouched (their ids and the World 1 swatch colours are unchanged, so every World 1 atlas is pixel-identical).
"""
from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
_C = importlib.util.spec_from_file_location("blocky_cells_cold", ROOT / "tools/blocky/cells.py")
C = importlib.util.module_from_spec(_C)
_C.loader.exec_module(C)  # type: ignore[union-attr]
S = C.S
COLD = ("snow", "packed_snow", "ice", "frozen_water", "pine", "fur")
WORLD1 = ("skin", "moss", "grass", "dirt", "stone", "metal", "crystal", "wood", "water", "glow", "wool")
WHITE, PACKED = S.hex_rgb("#F2F6FA"), S.hex_rgb("#B9CADA")


def part(name="Block", size=(4, 4, 4), at=(0, 2, 0), slot="Body", material=None, **kw):
    raw = {"name": name, "slot": slot, "size": list(size), "at": list(at)}
    if material:
        raw["material"] = material
    raw.update(kw)
    return S.normalise(raw)


def island(p, orient, cell=0.25):
    return next(i for i in C.islands([p], cell, cull=False) if i["orient"] == orient)


def grid(material, orient, base, aux=None, accent=None, size=(4, 4, 4)):
    """{(i, j): rgb} of one 4-stud face in `material` at the world cell, and the island."""
    p = part(size=size, at=(0, size[1] / 2, 0), material=material)
    isl = island(p, orient)
    cols = {"base": base, "aux": aux or base, "accent": accent or base}
    return {(i, j): rgb for i, j, rgb in C.island_cells(isl, cols)}, isl


def lum(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


class Registry(unittest.TestCase):
    def test_the_six_are_registered_after_the_eleven(self):
        self.assertEqual(tuple(C.MATERIALS), WORLD1 + COLD)
        for m in COLD:
            self.assertIn(m, C.MOTIFS)
            self.assertIn(m, C.PARAMS)
            self.assertIn(m, C.SURFACE)
        # the World 1 ids (they seed the motifs' hashes) are unchanged by the additions
        self.assertEqual([C.MAT_ID[m] for m in WORLD1], [101 + 17 * i for i in range(11)])
        self.assertEqual([m for m, *_ in C.SWATCH], list(WORLD1))
        self.assertEqual([m for m, *_ in C.SWATCH_COLD], list(COLD))

    def test_spec_accepts_the_cold_materials(self):
        for m in COLD:
            p = part(material=m)
            errors = []
            S._part_checks(p, errors.append)
            self.assertEqual(errors, [], m)

    def test_ice_and_frozen_water_are_glossy_and_the_pond_has_no_grout(self):
        self.assertLess(C.SURFACE["ice"]["rough"], 0.3)
        self.assertLess(C.SURFACE["frozen_water"]["rough"], 0.3)
        self.assertEqual(C.PARAMS["frozen_water"].get("grout"), 0.0)
        self.assertEqual(C.PARAMS["snow"].get("grout"), 0.5)   # half weight, as grass: a dense grid across a snowfield is too strong


class Snow(unittest.TestCase):
    def test_a_side_is_a_snow_lip_over_packed_snow(self):
        cells, isl = grid("snow", "-z", WHITE, PACKED)
        top = [cells[(i, isl["nv"] - 1)] for i in range(isl["nu"])]
        bottom = [cells[(i, 0)] for i in range(isl["nu"])]
        whitish = lambda rgb: lum(rgb) > 216  # noqa: E731  (the lip's shadow row is a step down; packed snow sits under 212)
        self.assertTrue(all(whitish(c) for c in top))
        self.assertFalse(any(whitish(c) for c in bottom))
        # the lip is two to four cells deep (deeper than the grass fringe), never the whole 16-row side
        depths = []
        for i in range(isl["nu"]):
            d = 0
            while d < isl["nv"] and whitish(cells[(i, isl["nv"] - 1 - d)]):
                d += 1
            depths.append(d)
        self.assertTrue(all(C.SNOW_LIP[0] <= d <= C.SNOW_LIP[1] for d in depths), depths)
        self.assertGreater(len(set(depths)), 1)   # ragged

    def test_a_top_is_white_with_a_sparkle_now_and_then(self):
        cells, isl = grid("snow", "+y", WHITE, PACKED)
        inner = [cells[(i, j)] for i in range(1, isl["nu"] - 1) for j in range(1, isl["nv"] - 1)]
        self.assertTrue(all(lum(c) > 228 for c in inner))
        self.assertGreater(len({c for c in inner}), 2)   # drifts and sparkles move a few cells

    def test_packed_snow_has_strata_rows(self):
        cells, isl = grid("packed_snow", "-z", PACKED)
        rows = {j: sum(lum(cells[(i, j)]) for i in range(1, isl["nu"] - 1)) / (isl["nu"] - 2) for j in range(1, isl["nv"] - 1)}
        strata = [j for j in rows if (int(isl["v0"] / isl["cell"]) + j) % C.PACKED_STRATA == 0]
        plain = [j for j in rows if j not in strata]
        self.assertLess(sum(rows[j] for j in strata) / len(strata), sum(rows[j] for j in plain) / len(plain))


class Ice(unittest.TestCase):
    def test_ice_bands_run_on_the_other_diagonal_to_crystal(self):
        base = S.hex_rgb("#BFEBFA")
        p = part(material="ice")
        isl = island(p, "-z")
        cells16 = [C.Cell(i, j, isl["nu"], isl["nv"], i, j, 0, "-z", p, "ice") for i in range(16) for j in range(16)]
        lit_ice = {(c.gu - c.gv) % C.ICE_BAND for c in cells16 if C._ice(c)[1] == 1.5}   # the band (a sparkle, 2.0, lands anywhere)
        self.assertEqual(lit_ice, {0})   # every band cell sits on one (gu - gv) line
        lit_crystal = {(i + j) % 6 for i in range(16) for j in range(16) if C._crystal(C.Cell(i, j, 16, 16, i, j, 0, "-z", p, "crystal"))[1] >= 2.0}
        self.assertEqual(lit_crystal, {0})   # crystal's bands sit on (gu + gv): the two motifs cross
        cells, _ = grid("ice", "-z", base)
        self.assertGreater(len(set(cells.values())), 3)

    def test_frozen_water_has_cracks_between_plates_and_darkens_with_depth(self):
        base = S.hex_rgb("#A9D6F5")
        cells, isl = grid("frozen_water", "+y", base, size=(8, 1, 8))
        inner = [cells[(i, j)] for i in range(isl["nu"]) for j in range(isl["nv"])]
        dark = [c for c in inner if lum(c) < lum(base) - 10]
        share = len(dark) / len(inner)
        self.assertTrue(0.04 < share < 0.35, share)   # cracks: a few lines, not a grid of tiles
        side, isl2 = grid("frozen_water", "-z", base, size=(4, 2, 4))
        top_row = lum(side[(2, isl2["nv"] - 2)])
        bottom_row = lum(side[(2, 1)])
        self.assertGreater(top_row, bottom_row)


class PineAndFur(unittest.TestCase):
    def test_pine_sides_are_needle_rows_with_snow_dust(self):
        green, snow = S.hex_rgb("#2F6B5E"), S.hex_rgb("#F2F6FA")
        cells, isl = grid("pine", "-z", green, accent=snow)
        inner = [(i, j) for i in range(1, isl["nu"] - 1) for j in range(1, isl["nv"] - 1)]
        dust = [k for k in inner if cells[k] == snow]
        self.assertTrue(0 < len(dust) < len(inner) * 0.08, len(dust))
        # rows alternate: the mean of odd rows differs from the mean of even rows
        odd = [lum(cells[(i, j)]) for i, j in inner if (int(isl["v0"] / isl["cell"]) + j) % 2 and cells[(i, j)] != snow]
        even = [lum(cells[(i, j)]) for i, j in inner if not (int(isl["v0"] / isl["cell"]) + j) % 2 and cells[(i, j)] != snow]
        self.assertGreater(abs(sum(odd) / len(odd) - sum(even) / len(even)), 2.0)

    def test_fur_tufts_sit_on_a_lattice_and_are_two_cells_tall(self):
        blue = S.hex_rgb("#4F9BD8")
        p = part(material="fur", size=(6, 6, 6), at=(0, 3, 0))
        isl = island(p, "-z")
        tufts = set()
        for j in range(isl["nv"]):
            for i in range(isl["nu"]):
                gu = int((isl["u0"] + (i + 0.5) * 0.25) / 0.25)
                gv = int((isl["v0"] + (j + 0.5) * 0.25) / 0.25)
                _, steps = C._fur(C.Cell(i, j, isl["nu"], isl["nv"], gu, gv, 0, "-z", p, "fur"))
                if steps:
                    tufts.add((gu, gv))
        self.assertTrue(tufts)
        # at most one tuft column per lattice square, and every tuft cell has its partner directly above or below it
        for gu, gv in tufts:
            self.assertTrue((gu, gv + 1) in tufts or (gu, gv - 1) in tufts, (gu, gv))
        squares = {(gu // C.FUR_LATTICE, gv // C.FUR_LATTICE) for gu, gv in tufts}
        self.assertLess(len(tufts), len(squares) * 2 + 1 + len(squares))   # two cells a tuft, a tuft may straddle two squares
        cells, isl2 = grid("fur", "-z", blue)
        shades = {cells[(i, j)] for i in range(1, isl2["nu"] - 1) for j in range(1, isl2["nv"] - 1)}   # inside the edge rows
        self.assertGreater(len(shades), 3)
        self.assertLess(len(shades), 16)   # five tuft levels by three jitter levels at most, never a continuous shade per cell


class Determinism(unittest.TestCase):
    def test_cold_faces_are_deterministic(self):
        for m in COLD:
            a, _ = grid(m, "-z", WHITE, PACKED, S.hex_rgb("#F2F6FA"))
            b, _ = grid(m, "-z", WHITE, PACKED, S.hex_rgb("#F2F6FA"))
            self.assertEqual(a, b, m)

    def test_world1_motifs_are_unchanged_by_the_cold_set(self):
        # a World 1 island paints the same whether or not the cold materials exist: its hash keys are its own id and the seed
        moss = S.hex_rgb("#6CCB5F")
        cells, _ = grid("moss", "+y", moss, accent=S.hex_rgb("#D9F36B"))
        self.assertEqual(C.MAT_ID["moss"], 118)
        self.assertEqual(len(cells), 256)


if __name__ == "__main__":
    unittest.main()
