"""Tests for the character bar across World 1's Rare and up (Decisions B54 to B56, worker BAR-W1): tools/blocky/bar_w1.py (the nine plans and the
aliens' own satellite pieces) and the notes they write. Standard library only (./tools/test.sh runs it; no Blender).
"""
from __future__ import annotations

import pathlib
import re
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
import bar_w1 as B  # noqa: E402
import kits as K  # noqa: E402
import pilots as P  # noqa: E402
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
TIERS = {"Rocklobber": "Rare", "Zapfinch": "Rare", "Sparkfox": "Rare", "Wisplet": "Rare", "Thunderhog": "Epic", "Gloomoth": "Epic", "Spookum": "Epic",
         "Gaiabloom": "Legendary", "Nebulyn": "Legendary"}
FACES = {"Rocklobber": "crescent", "Zapfinch": "bubble", "Sparkfox": "glimmer", "Wisplet": "crescent", "Thunderhog": "starry", "Gloomoth": "gem", "Spookum": "hearty",
         "Gaiabloom": "bloom", "Nebulyn": "starlit"}
NAMES = {"Rocklobber": "Boulden", "Zapfinch": "Zirrit", "Sparkfox": "Vixa", "Wisplet": "Wispkin", "Thunderhog": "Voltus", "Gloomoth": "Iridia", "Spookum": "Grin",
         "Gaiabloom": "Gaira", "Nebulyn": "Cosmoo"}


def load(sid):
    return S.load(CREATURES / ("%s.md" % sid))


class BarW1(unittest.TestCase):
    def test_the_plans_are_the_nine_aliens_and_their_notes_are_current(self):
        self.assertEqual(set(B.PLANS), set(TIERS))
        self.assertEqual(P.main(["--check"]), 0)

    def test_every_note_validates_at_its_tier(self):
        for sid, tier in TIERS.items():
            spec = load(sid)
            self.assertEqual(spec["front"]["tier"], tier, sid)
            self.assertEqual(S.validate(spec)[0], [], sid)

    def test_names_and_faces_are_kept(self):
        for sid in TIERS:
            spec = load(sid)
            self.assertEqual(spec["front"]["name"], NAMES[sid])
            self.assertEqual(spec["eyes"]["key"], FACES[sid], sid)

    def test_each_wears_its_tiers_kit_and_satellites(self):
        for sid, tier in TIERS.items():
            front = load(sid)["front"]
            lo, hi = K.TIER_COUNT[tier]
            self.assertTrue(lo <= front["bar_kit"] <= hi, "%s kit %s" % (sid, front["bar_kit"]))
            self.assertTrue(K.SATELLITES[0] <= front["bar_satellites"] <= K.SATELLITES[1], sid)
            self.assertEqual("bar_backdrop" in front, tier == "Legendary", sid)
            self.assertNotIn("bar_aura", front, sid)   # the aura is Cosmic and Secret's

    def test_heights_stay_in_the_band_and_triangles_under_the_cap(self):
        for sid, tier in TIERS.items():
            c = S.counts(load(sid))
            self.assertTrue(S.BAND_HEIGHT[0] <= c["height"] <= S.BAND_HEIGHT[1] + 1e-6, "%s %.3f" % (sid, c["height"]))
            self.assertLessEqual(c["tris"], S.tri_cap(tier), sid)

    def test_every_alien_stands_in_a_rest_pose(self):
        for sid in TIERS:
            spec = load(sid)
            groups = set(S.rest_groups(spec))
            self.assertTrue(groups, sid)
            self.assertEqual({p["pose"] for p in spec["parts"] if p.get("pose")}, groups, sid)
            self.assertEqual(S.validate_rest(spec), [], sid)
            self.assertTrue(str(spec["front"]["bar_stance"]).strip(), sid)

    def test_the_satellites_are_the_aliens_own_pieces(self):
        own = set(B.OWN)
        for name in ("geode_half", "cairn_stack", "bolt_zig", "spark_ring", "paint_splat", "paint_pot", "lantern_pane", "wisp_orb", "charge_cell", "thunder_puff",
                     "mini_moth", "moonflower", "candle_stick", "grin_pumpkin", "glass_tulip", "gilded_seed", "north_star", "mini_planet"):
            self.assertIn(name, own)
            lo, hi = K.PIECES[name].extent(0.0625)
            longest = max(hi[i] - lo[i] for i in range(3))
            self.assertTrue(K.SATELLITE_SIZE[0] - 1e-6 <= longest <= K.SATELLITE_SIZE[1] + 1e-6, "%s %.3f" % (name, longest))

    def test_the_rings_keep_the_old_object_names_the_effects_hang_on(self):
        # Wispkin's panes, Grin's candles and Cosmoo's comet were already moving rings: the effects pieces name them by part
        for sid, key in (("Wisplet", "glass"), ("Spookum", "candles"), ("Nebulyn", "comet"), ("Zapfinch", "arc")):
            keys = S.movers(S.expand(load(sid)["parts"]))
            self.assertIn(key, keys, sid)

    def test_the_legendary_backdrops_are_shallow_and_behind(self):
        for sid in ("Gaiabloom", "Nebulyn"):
            spec = load(sid)
            name = spec["front"]["bar_backdrop"]
            members = S.movers(S.expand(spec["parts"]))[name]["parts"]
            lo, hi = S.bounds(members)
            self.assertLessEqual(hi[2] - lo[2], K.BACKDROP_DEPTH + 1e-6, sid)
            self.assertGreater(lo[2], 0, sid)

    def test_the_notes_carry_their_prompt_lists(self):
        for sid in TIERS:
            text = (CREATURES / ("%s.md" % sid)).read_text(encoding="utf-8")
            self.assertIn("## Character bar (B54)", text, sid)
            for word in ("Theme.", "Gains", "Stance", "Face intent.", "Three values", "Must-nots."):
                self.assertIn(word, text, "%s: %s" % (sid, word))


if __name__ == "__main__":
    unittest.main()
