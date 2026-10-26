"""Tests for the character bar pilots (Decision B54): tools/blocky/kits.py (the world kits), tools/blocky/pilots.py (the four plans) and the
`bar_*` checks of tools/blocky/spec.py. Standard library only (./tools/test.sh runs it; no Blender).
"""
from __future__ import annotations

import copy
import math
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
        expect = {"Mossbop": (2.873, "Moop"), "Radish": (3.5, "Raddis"), "Panpipe": (3.5, "Syrinx"), "Fenripup": (3.5, "Fenrir")}
        for sid, (h, name) in expect.items():
            spec = S.load(CREATURES / ("%s.md" % sid))
            self.assertAlmostEqual(S.counts(spec)["height"], h, places=2)
            self.assertEqual(spec["front"]["name"], name)

    def test_part_budgets_hold(self):
        for sid in PILOTS:
            c = S.counts(S.load(CREATURES / ("%s.md" % sid)))
            self.assertLessEqual(c["tris"], S.tri_cap(PILOTS[sid]), sid)

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



class SecondPass(unittest.TestCase):
    """PILOT-2 (2026-10-26): the bolder pilots. Big backdrops, 6 to 8 satellites of 0.5 to 0.9 studs, visible metal, shaped energy, stances."""

    def spec(self, sid):
        return S.load(CREATURES / ("%s.md" % sid))

    def test_satellites_are_six_to_eight_and_half_a_stud_to_nine_tenths(self):
        for sid in ("Radish", "Panpipe", "Fenripup"):
            spec = self.spec(sid)
            self.assertTrue(6 <= spec["front"]["bar_satellites"] <= 8, sid)
            parts = [p for p in S.expand(spec["parts"]) if p["moves"] == spec["front"]["bar_orbit"]]
            pieces = {}
            for p in parts:
                pieces.setdefault(p["name"].rstrip("abcdefghijklmnopqrstuvwxyz"), []).append(p)
            self.assertEqual(len(pieces), spec["front"]["bar_satellites"], sid)
            for name, members in pieces.items():
                lo, hi = S.bounds(members)
                longest = max(hi[i] - lo[i] for i in range(3))
                self.assertTrue(0.5 - 1e-6 <= longest <= 0.9 + 1e-6, "%s %s %.3f" % (sid, name, longest))

    def test_the_backdrops_are_big_and_shallow(self):
        wide = {"Radish": ("halo", 2.5), "Panpipe": ("eclipse", 2.4), "Fenripup": ("halo", 3.0)}   # the moving object, at least this many studs across
        for sid, (key, across) in wide.items():
            members = [p for p in S.expand(self.spec(sid)["parts"]) if p["moves"] == key]
            lo, hi = S.bounds(members)
            self.assertLess(hi[2] - lo[2], 0.5 + 1e-6, sid)
            self.assertGreaterEqual(hi[0] - lo[0], across, sid)
            self.assertGreater(lo[2], 0.5, sid)   # behind the body

    def test_the_crescent_stands_taller_than_the_pup(self):
        parts = S.expand(self.spec("Fenripup")["parts"])
        moon = [p for p in parts if p["name"].startswith("Crescent")]
        pup = [p for p in parts if not p["name"].startswith("Crescent")]
        self.assertGreater(S.bounds(moon)[1][1], S.bounds(pup)[1][1])
        self.assertGreaterEqual(S.bounds(moon)[1][1] - S.bounds(moon)[0][1], 3.4)

    def test_metal_trim_is_a_quarter_stud_thick(self):
        thick = {"Radish": ["BrassBand"], "Panpipe": ["Girth", "CuffH", "CuffFL", "CuffFR", "Circlet"],
                 "Fenripup": ["FrontBandR", "FrontBandL", "HindBandR", "HindBandL", "TailBand"]}
        for sid, names in thick.items():
            parts = {p["name"]: p for p in self.spec(sid)["parts"]}
            for n in names:
                self.assertIn(n, parts, sid)
                self.assertEqual(parts[n]["slot"], "Trim", n)
                self.assertGreaterEqual(sorted(parts[n]["size"])[1], 0.25 - 1e-9, "%s %s" % (sid, n))   # two of its three sides are a quarter stud or more

    def test_shaped_energy_is_modelled(self):
        radish = self.spec("Radish")["parts"]
        names = {p["name"] for p in radish}
        self.assertTrue({"FlameO0", "FlameM0", "FlameI0"} <= names)                     # three layered teardrops
        flame = [p for p in radish if p["name"].startswith("FlameO")]
        widths = [p["size"][0] for p in sorted(flame, key=lambda p: p["at"][1])]
        self.assertEqual(widths.index(max(widths)), 1)                                   # widest in the belly
        self.assertEqual(widths[1:], sorted(widths[1:], reverse=True))                   # then narrowing to the tip
        names = {p["name"] for p in self.spec("Fenripup")["parts"]}
        self.assertTrue({"Breath0T", "Breath1T", "Breath2T"} <= names)                    # three rings of frost breath

    def test_every_pilot_stands_in_a_rest_pose(self):
        groups = {"Mossbop": {"lean"}, "Radish": {"wing"}, "Panpipe": {"head", "fore"}, "Fenripup": {"head", "tail"}}
        for sid, want in groups.items():
            spec = self.spec(sid)
            self.assertEqual(set(S.rest_groups(spec)), want, sid)
            self.assertEqual({p["pose"] for p in spec["parts"] if p.get("pose")}, want, sid)
            self.assertEqual(S.validate_rest(spec), [], sid)
        spec = self.spec("Fenripup")
        plate = S.face_plate(spec)
        self.assertAlmostEqual(plate["rot"][0], 12.0, places=3)                           # the head is up 12 degrees (v2b: the face reads square-on), the plate with it

    def test_v2b_syrinx_eclipse_reads_against_the_dark_body(self):
        spec = self.spec("Panpipe")
        parts = S.expand(spec["parts"])
        disc = [p for p in parts if p["name"].startswith("Moon") and p["moves"] == "eclipse"]
        rim = [p for p in disc if p["slot"] == "Glow"]
        face = [p for p in disc if p["slot"] == "BodyDark"]
        self.assertTrue(rim and face)
        centre = max(p["at"][1] + p["size"][1] / 2 for p in disc) - 1.5                    # the disc is 3 studs across
        self.assertAlmostEqual(centre, 1.75, places=3)
        top_rim = max(p["at"][1] + p["size"][1] / 2 for p in rim)
        top_face = max(p["at"][1] + p["size"][1] / 2 for p in face)
        self.assertGreaterEqual(top_rim - top_face, 0.5 - 1e-9)                            # the lit rim is two cells (0.5 stud) thick
        rays = [p for p in parts if p["name"].startswith("Ray") and p["moves"] == "eclipse"]
        self.assertTrue(rays)
        octants = {round(math.degrees(math.atan2(p["at"][0], p["at"][1] - 1.75)) / 45) % 8 for p in rays}
        self.assertEqual(len(octants), 8)                                                  # eight rays, one a compass point
        palette = S.palette(spec)
        self.assertGreater(S.lstar(palette["accent"]), 65)                                 # the accent is a pale violet: the shards and buds read as lit
        self.assertGreater(S.lstar(palette["trim"]), 63)                                   # the brass one tone brighter (it was 60)
        shards = [p for p in parts if p["moves"] == "shards" and p["name"].startswith(("Sat0", "Sat2", "Sat4", "Sat6"))]
        self.assertTrue(any(p["slot"] == "Accessory" for p in shards))                     # the eclipse shards are lit slabs, not the body's dark violet

    def test_v2b_fenrir_has_one_moon_a_clean_brow_and_a_breath_clear_of_the_face(self):
        spec = self.spec("Fenripup")
        parts = S.expand(spec["parts"])
        self.assertFalse([p["name"] for p in parts if p["name"].startswith("Moon")])       # the brow moon is cut: the crescent is the moon
        self.assertEqual(spec["front"]["hero"], "Crescent1")
        self.assertLessEqual(spec["rig"]["rest"]["head"]["rot"][0], 12)                    # the head turns up no more than 12 degrees
        head = next(p for p in parts if p["name"] == "Head")
        hx = max(abs(head["at"][0]) + head["size"][0] / 2, 1.0)
        for p in parts:
            if p["name"].startswith("Breath"):
                self.assertGreaterEqual(abs(p["at"][0]) - p["size"][0] / 2, hx - 1e-6, p["name"])   # beside the head, not over it

    def test_moop_leans_and_has_one_leaf_up(self):
        parts = {p["name"]: p for p in S.expand(self.spec("Mossbop")["parts"])}
        self.assertLess(parts["Head"]["rot"][2], -10)                                      # the whole ball rolled
        self.assertEqual(len(parts), 12)                                                  # still a Common's 12 blocks
        angles = sorted(abs(parts[n]["rot"][2]) for n in ("LeafL", "LeafR"))
        self.assertGreater(angles[1], 60)                                                 # one leaf nearly upright
        self.assertLess(angles[0], 60)                                                    # the other lower

    def test_the_caps_follow_the_tier(self):
        for sid, tier in PILOTS.items():
            self.assertLessEqual(S.counts(self.spec(sid))["tris"], S.tri_cap(tier), sid)
        self.assertEqual(S.tri_cap("Cosmic"), 6000)
        self.assertEqual(S.tri_cap("Epic"), 4000)


if __name__ == "__main__":
    unittest.main()
