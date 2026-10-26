"""Tests for the lifted triangle caps and the rest-pose groups of the B54 pilot's second pass (tools/blocky/spec.py `tri_cap`, `apply_rest`,
`rig.rest`, the `pose` field). Standard library only (./tools/test.sh runs it; no Blender).
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
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"


def part(**kw):
    raw = {"name": "P", "slot": "Body", "size": [1, 1, 1], "at": [0, 0, 0]}
    raw.update(kw)
    return S.normalise(raw)


class Caps(unittest.TestCase):
    def test_the_cap_climbs_with_the_tier(self):
        self.assertEqual([S.tri_cap(t) for t in S.TIER_ORDER], [2500, 2500, 2500, 4000, 6000, 6000, 6000])
        self.assertEqual(S.tri_cap(None), S.TRI_CAP)
        self.assertEqual(S.TRI_CAP, 2500)       # a prop keeps 2,500


class RestPose(unittest.TestCase):
    def test_euler_round_trips(self):
        for rot in ([0, 0, 0], [20, 0, 0], [-25, 14, 0], [10, -16, 12], [0, 0, -110], [14, 0, 20]):
            got = S.matrix_euler(S.rot_matrix(rot))
            a, b = S.rot_matrix(rot), S.rot_matrix(got)
            for i in range(3):
                for j in range(3):
                    self.assertAlmostEqual(a[i][j], b[i][j], places=5, msg=str(rot))

    def test_a_pitch_swings_the_part_about_its_pivot(self):
        # a block 1 stud in front of the pivot (z = -1), the pivot at the origin, turned 90 degrees about x: it ends up above or below
        p = part(at=[0, 0, -1], pose="g")
        p["rest"] = {"rot": [90, 0, 0], "pivot": [0, 0, 0]}
        out = S.expand([p])[0]
        self.assertAlmostEqual(out["at"][0], 0.0, places=6)
        self.assertAlmostEqual(abs(out["at"][1]), 1.0, places=6)
        self.assertAlmostEqual(out["at"][2], 0.0, places=6)
        self.assertNotIn("rest", out)
        self.assertAlmostEqual(abs(out["rot"][0]), 90.0, places=4)

    def test_no_rest_leaves_the_part_alone(self):
        p = part(at=[0.25, 1, 0.5], rot=[10, 0, 0])
        out = S.expand([p])[0]
        self.assertEqual(out["at"], [0.25, 1, 0.5])
        self.assertEqual(out["rot"], [10, 0, 0])

    def test_a_mirrored_pair_is_posed_then_reflected(self):
        p = part(at=[0.5, 1, -1], mirror="x", pose="g")
        p["rest"] = {"rot": [-20, 0, 0], "pivot": [0, 1, 0]}
        right, left = S.expand([p])
        self.assertAlmostEqual(right["at"][0], 0.5)
        self.assertAlmostEqual(left["at"][0], -0.5)
        self.assertAlmostEqual(right["at"][1], left["at"][1])
        self.assertAlmostEqual(right["at"][2], left["at"][2])
        self.assertAlmostEqual(right["rot"][0], left["rot"][0], places=4)

    def test_a_pivot_rides_the_group(self):
        p = part(at=[0, 2, -1], moves="ear", pivot=[0, 2, -1], pose="g")
        p["rest"] = {"rot": [0, 0, 90], "pivot": [0, 1, -1]}
        out = S.expand([p])[0]
        self.assertAlmostEqual(out["pivot"][0], -1.0, places=5)
        self.assertAlmostEqual(out["pivot"][1], 1.0, places=5)


class Validation(unittest.TestCase):
    def load(self):
        return S.load(CREATURES / "Fenripup.md")

    def test_a_group_with_no_part_and_a_part_with_no_group_are_errors(self):
        spec = self.load()
        spec["rig"] = dict(spec["rig"], rest={"ghost": {"rot": [10, 0, 0], "pivot": [0, 0, 0]}})
        errors = S.validate_rest(spec)
        self.assertTrue(any("not used" in e for e in errors), errors)
        spec = self.load()
        spec["parts"][0]["pose"] = "nothing"
        self.assertTrue(any("no such group" in e for e in S.validate_rest(spec)))

    def test_the_head_turns_at_most_25_degrees_and_the_rest_35(self):
        spec = self.load()
        host = S.face_host(spec)
        if not host.get("pose"):
            self.skipTest("the face host is not posed")
        key = host["pose"]
        bad = copy.deepcopy(spec)
        bad["rig"]["rest"][key]["rot"] = [-30, 0, 0]
        S.attach_rest(bad)
        self.assertTrue(any("holds the face" in e for e in S.validate_rest(bad)))
        self.assertEqual(S.validate_rest(spec), [])

    def test_the_posed_pilots_stay_axis_aligned_as_authored(self):
        for sid in ("Fenripup",):
            spec = S.load(CREATURES / ("%s.md" % sid))
            for p in spec["parts"]:
                if p["bevel"]:
                    self.assertTrue(all(abs(a) < 1e-9 for a in p["rot"]), "%s %s" % (sid, p["name"]))


if __name__ == "__main__":
    unittest.main()
