"""Tests for the character bar pilots (Decision B54): tools/blocky/kits.py (the world kits), tools/blocky/pilots.py (the four plans) and the
`bar_*` checks of tools/blocky/spec.py. Standard library only (./tools/test.sh runs it; no Blender).
"""
from __future__ import annotations

import copy
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
import kits as K  # noqa: E402
import pilots as P  # noqa: E402
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
PILOTS = {"Mossbop": "Common", "Radish": "Cosmic", "Panpipe": "Secret", "Fenripup": "Cosmic"}


def errors_of(spec):
    return S.validate(spec)[0]


class Kits(unittest.TestCase):
    def test_every_piece_is_clean_and_on_the_quarter_grid(self):
        self.assertEqual(K.check(), 0)
        for piece in K.PIECES.values():
            size = piece.size(0.125)
            for v in size:
                self.assertAlmostEqual(v / K.QUARTER, round(v / K.QUARTER), msg=piece.name)
            self.assertLessEqual(max(size), 1.0, piece.name)

    def test_each_world_has_five_kit_pieces(self):
        self.assertEqual(set(K.KITS), {"Verdant", "Frostbyte"})
        for world, names in K.KITS.items():
            self.assertEqual(len(names), 5, world)
            for n in names:
                self.assertTrue(n in K.PIECES or n in K.WRAPS, n)

    def test_the_tier_counts_climb(self):
        order = [K.TIER_COUNT[t] for t in K.TIERS]
        self.assertEqual(order[0], (1, 1))
        self.assertEqual(order[1], (2, 2))
        self.assertEqual(order[2], (3, 4))
        self.assertEqual(order[3], (5, 6))
        for t in ("Legendary", "Cosmic", "Secret"):
            self.assertGreaterEqual(K.TIER_COUNT[t][1], 7)

    def test_place_puts_the_piece_on_its_surface(self):
        parts = K.place(K.PIECES["ice_shard"], "S", (0.5, 2.0, 0.0), "+y")
        self.assertTrue(all(p["at"][1] >= 2.0 for p in parts))                     # it grows up from a top
        parts = K.place(K.PIECES["sap_drop"], "D", (0.5, 2.0, 0.0), "-y")
        self.assertTrue(all(p["at"][1] <= 2.0 for p in parts))                     # it hangs from an underside
        parts = K.place(K.PIECES["snowflake_stud"], "F", (1.0, 1.0, 0.0), "+x")
        self.assertTrue(all(p["at"][0] >= 1.0 for p in parts))                     # it is flat on a side

    def test_aura_rings_lie_on_the_ground(self):
        for p in K.aura_dashes("A", (0, 0), 1.75, n=12):
            self.assertAlmostEqual(p["at"][1] - p["size"][1] / 2, 0.0)
            self.assertEqual(p["moves"], "aura")

    def test_the_crescent_is_a_crescent(self):
        rows = K.crescent_backdrop("C", (0, 1.875), 1.625, 1.4, 0.55, 1.4375)
        self.assertGreaterEqual(len(rows), 10)
        top = max(p["at"][1] + p["size"][1] / 2 for p in rows)
        self.assertLessEqual(top, 3.5 + 1e-9)
        mid = [p for p in rows if abs(p["at"][1] - 1.875) < 0.2]
        self.assertTrue(all(p["at"][0] - p["size"][0] / 2 > 0.3 for p in mid))      # the middle rows are the thick right side only


class Pilots(unittest.TestCase):
    def test_every_pilot_note_is_current_and_clean(self):
        self.assertEqual(P.main(["--check"]), 0)
        for sid, tier in PILOTS.items():
            spec = S.load(CREATURES / ("%s.md" % sid))
            self.assertEqual(spec["front"]["tier"], tier)
            self.assertEqual(errors_of(spec), [], sid)
            self.assertIn("bar_kit", spec["front"])

    def test_tier_counts_of_what_each_pilot_wears(self):
        for sid, tier in PILOTS.items():
            front = S.load(CREATURES / ("%s.md" % sid))["front"]
            lo, hi = K.TIER_COUNT[tier]
            self.assertTrue(lo <= front["bar_kit"] <= hi, sid)
            if tier != "Common":
                self.assertTrue(6 <= front["bar_satellites"] <= 10, sid)
                self.assertIn("bar_backdrop", front)
                self.assertIn("bar_aura", front)

    def test_the_face_height_and_names_are_kept(self):
        expect = {"Mossbop": (2.475, "Moop"), "Radish": (3.438, "Raddis"), "Panpipe": (3.5, "Syrinx"), "Fenripup": (3.5, "Fenrir")}
        for sid, (h, name) in expect.items():
            spec = S.load(CREATURES / ("%s.md" % sid))
            self.assertAlmostEqual(S.counts(spec)["height"], h, places=2)
            self.assertEqual(spec["front"]["name"], name)

    def test_part_budgets_hold(self):
        for sid in PILOTS:
            c = S.counts(S.load(CREATURES / ("%s.md" % sid)))
            self.assertLessEqual(c["tris"], S.TRI_CAP, sid)

    def test_no_fangs_on_the_calm_faces(self):
        parts = S.load(CREATURES / "Fenripup.md")["parts"]
        self.assertFalse([p for p in parts if "Fang" in p["name"]])

    def test_the_bar_checks_have_teeth(self):
        spec = S.load(CREATURES / "Radish.md")
        bad = copy.deepcopy(spec)
        bad["front"]["bar_kit"] = 2
        self.assertTrue(any("kit pieces" in e for e in errors_of(bad)))
        bad = copy.deepcopy(spec)
        bad["front"]["bar_satellites"] = 14
        self.assertTrue(any("satellites" in e for e in errors_of(bad)))
        bad = copy.deepcopy(spec)
        bad["front"]["bar_orbit"] = "nothing"
        self.assertTrue(any("bar_orbit" in e for e in errors_of(bad)))
        bad = copy.deepcopy(spec)
        bad["front"]["bar_aura"] = "wing"
        self.assertTrue(any("ground aura" in e for e in errors_of(bad)))
        bad = copy.deepcopy(spec)
        bad["front"]["bar_stance"] = ""
        self.assertTrue(any("stance" in e for e in errors_of(bad)))
        bad = copy.deepcopy(spec)
        bad["front"]["bar_backdrop"] = "nothing"
        self.assertTrue(any("backdrop" in e for e in errors_of(bad)))
        common = S.load(CREATURES / "Mossbop.md")
        common["front"]["bar_kit"] = 2
        self.assertTrue(any("kit pieces" in e for e in errors_of(common)))


if __name__ == "__main__":
    unittest.main()
