"""Tests for the character bar across World 2's Rare-and-up aliens (Decisions B54 to B56): tools/blocky/bar_w2.py, the six notes it writes, and the
rule 8 reads (mass clarity and value contrast, Blocky-Style section 10). Standard library only (./tools/test.sh runs it; no Blender).
"""
from __future__ import annotations

import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
import bar_w2 as B  # noqa: E402
import kits as K  # noqa: E402
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
TIERS = {"Reindazzle": "Rare", "Shellberg": "Rare", "Capybubble": "Rare", "Shimmerlynx": "Epic", "Frostfang": "Epic", "Skaddle": "Legendary"}
HEIGHTS = {"Reindazzle": 3.42, "Shellberg": 3.0, "Capybubble": 3.25, "Shimmerlynx": 3.42, "Frostfang": 3.4, "Skaddle": 3.43}


class BarW2(unittest.TestCase):
    def spec(self, sid):
        return S.load(CREATURES / ("%s.md" % sid))

    def test_every_note_is_current_and_clean(self):
        self.assertEqual(B.main(["--check"]), 0)
        for sid, tier in TIERS.items():
            spec = self.spec(sid)
            self.assertEqual(spec["front"]["tier"], tier)
            errors, _ = S.validate(spec)
            self.assertEqual(errors, [], sid)

    def test_height_stays_in_the_band_and_names_are_kept(self):
        for sid, h in HEIGHTS.items():
            c = S.counts(self.spec(sid))
            self.assertAlmostEqual(c["height"], h, delta=0.01, msg=sid)
            self.assertTrue(2.0 <= c["height"] <= 3.5, sid)

    def test_tier_counts_and_satellites(self):
        for sid, tier in TIERS.items():
            front = self.spec(sid)["front"]
            lo, hi = K.TIER_COUNT[tier]
            self.assertTrue(lo <= front["bar_kit"] <= hi, sid)
            self.assertTrue(6 <= front["bar_satellites"] <= 8, sid)
            self.assertEqual(front["bar_world"], "Frostbyte")
        self.assertTrue(self.spec("Skaddle")["front"].get("bar_backdrop"))

    def test_the_budgets_hold(self):
        for sid, tier in TIERS.items():
            c = S.counts(self.spec(sid))
            self.assertLessEqual(c["tris"], S.tri_cap(tier), sid)

    def test_every_alien_stands_in_a_rest_pose(self):
        for sid in TIERS:
            self.assertTrue(self.spec(sid)["rig"].get("rest"), sid)

    def test_nothing_crosses_the_face(self):
        # the satellites stand beside or behind the face plate's column, never in front of it (z < the head's front and |x| inside the head)
        for sid in TIERS:
            spec = self.spec(sid)
            orbit = spec["front"]["bar_orbit"]
            host = S.face_host(spec)
            parts = S.expand(spec["parts"])
            head = next(p for p in parts if p["source"] == host["name"])
            front = head["at"][2] - head["size"][2] / 2
            half = head["at"][0] + head["size"][0] / 2
            for p in parts:
                if p.get("moves") == orbit or p["name"].startswith("Sat"):
                    if p["at"][2] < front - 0.25 and abs(p["at"][0]) < half:
                        self.fail("%s: %s stands in front of the face" % (sid, p["name"]))

    def test_rule_8_the_body_is_a_step_off_the_snow(self):
        # Frostbyte's snow is L* 94 to 97: a body on it needs a clear step (the pale lavender, tan and white bodies were the failures), or a dark backdrop
        for sid in ("Reindazzle", "Shellberg", "Capybubble", "Shimmerlynx", "Frostfang"):
            pal = S.palette(self.spec(sid))
            self.assertLessEqual(S.lstar(pal["body"]), 75, sid)
        pal = S.palette(self.spec("Skaddle"))
        self.assertGreater(S.lstar(pal["body"]), 90)
        back = [p for p in S.expand(self.spec("Skaddle")["parts"]) if p.get("moves") == "frost"]
        self.assertTrue(any(p["slot"] == "BodyDark" for p in back))                  # the white owl stands against a dark disc
        self.assertLess(S.lstar(pal["second"]), 50)

    def test_rule_8_satellites_have_one_lit_colour_and_an_edge(self):
        for sid in TIERS:
            spec = self.spec(sid)
            sats = [p for p in S.expand(spec["parts"]) if p.get("moves") == spec["front"]["bar_orbit"]]
            self.assertTrue(any(p["slot"] == "Glow" for p in sats), sid)             # a lit part
            self.assertTrue(any(p["slot"] == "BodyDark" for p in sats), sid)         # and a dark frame, so it has an edge on snow

    def test_the_satellite_ring_is_not_a_flat_neon_part(self):
        # an object over half Glow exports as a flat Neon part with no cell texture: the dark frames must be kept
        for sid in TIERS:
            spec = self.spec(sid)
            sats = [p for p in S.expand(spec["parts"]) if p.get("moves") == spec["front"]["bar_orbit"]]
            glow = sum(p["size"][0] * p["size"][1] + p["size"][1] * p["size"][2] + p["size"][0] * p["size"][2] for p in sats if p["slot"] == "Glow")
            total = sum(p["size"][0] * p["size"][1] + p["size"][1] * p["size"][2] + p["size"][0] * p["size"][2] for p in sats)
            self.assertLess(glow / total, 0.5, sid)


if __name__ == "__main__":
    unittest.main()
