"""Tests for tools/lint_data.lint_reveal (the Reveal's three beats, data/Reveal), with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). The shipped table must pass, and each rule the lint states must fail when the table breaks it.
"""
from __future__ import annotations

import copy
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import lint_data  # noqa: E402


def tables():
    reader = lint_data.TableReader()
    return {name: reader.read(ROOT / f"src/shared/data/{name}.luau") for name in ("Reveal", "Tiers", "Sounds")}


class RevealLint(unittest.TestCase):
    def setUp(self):
        self.pristine = tables()
        self.tables = self.pristine

    def failures(self):
        return lint_data.lint_reveal(self.tables, ROOT)

    def mutated(self, change):
        self.tables = copy.deepcopy(self.pristine)
        change(self.tables["Reveal"])
        return self.failures()

    def test_shipped_table_is_clean(self):
        self.assertEqual(self.failures(), [])

    def test_rare_total_is_inside_its_band(self):
        data = self.tables["Reveal"]
        rare = data["Tiers"]["Rare"]
        total = (data["CrackTaps"] * data["CrackSecondsPerTap"] + data["ShardSeconds"]
                 + (data["RaySpinSeconds"] if rare["Rays"] else 0) + data["CardDropSeconds"] + data["HoldSeconds"])
        self.assertGreaterEqual(total, 2.5)
        self.assertLessEqual(total, 4)

    def test_a_too_slow_rare_total_fails(self):
        failures = self.mutated(lambda d: d.update(HoldSeconds=3.0, ButtonDelaySeconds=0.45))
        self.assertTrue(any("Rare total" in f for f in failures), failures)

    def test_a_too_fast_rare_total_fails(self):
        failures = self.mutated(lambda d: d.update(CrackTaps=1, HoldSeconds=0.8, CardDropSeconds=0.1, RaySpinSeconds=0.1, ShardSeconds=0.1))
        self.assertTrue(any("Rare total" in f for f in failures), failures)

    def test_a_zero_or_negative_duration_fails(self):
        for key in ("CrackSecondsPerTap", "ShardSeconds", "RaySpinSeconds", "CardDropSeconds", "HoldSeconds", "AutoCrackSeconds"):
            for value in (0, -0.5):
                failures = self.mutated(lambda d: d.update({key: value}))
                self.assertTrue(any(f.startswith(f"Reveal.{key}:") for f in failures), (key, value, failures))

    def test_every_tier_needs_a_row(self):
        failures = self.mutated(lambda d: d["Tiers"].pop("Secret"))
        self.assertTrue(any("exactly one row for every tier" in f for f in failures), failures)
        failures = self.mutated(lambda d: d["Tiers"].update(Mythic=dict(d["Tiers"]["Rare"])))
        self.assertTrue(any("exactly one row for every tier" in f for f in failures), failures)

    def test_flags_follow_the_ladder(self):
        failures = self.mutated(lambda d: d["Tiers"]["Rare"].update(Grand=True))
        self.assertTrue(any("Reveal.Tiers.Rare.Grand" in f for f in failures), failures)
        failures = self.mutated(lambda d: d["Tiers"]["Legendary"].update(Grand=False))
        self.assertTrue(any("Reveal.Tiers.Legendary.Grand" in f for f in failures), failures)
        failures = self.mutated(lambda d: d["Tiers"]["Secret"].update(Rays=True))
        self.assertTrue(any("instead of rays" in f for f in failures), failures)
        failures = self.mutated(lambda d: d["Tiers"]["Epic"].update(GroundRing=True))
        self.assertTrue(any("ground ring belongs to a Grand tier" in f for f in failures), failures)
        failures = self.mutated(lambda d: d["Tiers"]["Rare"].update(Confetti=True))
        self.assertTrue(any("Reveal.Tiers.Rare.Confetti" in f for f in failures), failures)

    def test_colour_keys_must_exist_in_the_theme(self):
        failures = self.mutated(lambda d: d["Tiers"]["Cosmic"].update(SecondRayColor="Chartreuse"))
        self.assertTrue(any("SecondRayColor" in f and "Theme.Colors" in f for f in failures), failures)
        failures = self.mutated(lambda d: d.update(GroundRingRarity="Platinum"))
        self.assertTrue(any("GroundRingRarity" in f for f in failures), failures)

    def test_the_entrance_must_fit_in_the_hold(self):
        failures = self.mutated(lambda d: d.update(ButtonDelaySeconds=0.7))
        self.assertTrue(any("inside HoldSeconds" in f for f in failures), failures)
        failures = self.mutated(lambda d: d.update(ChipDelaySeconds=0.6))
        self.assertTrue(any("odds line, then the chips" in f for f in failures), failures)

    def test_buttons_stay_tappable(self):
        failures = self.mutated(lambda d: d.update(ButtonHeightPx=40))
        self.assertTrue(any("Theme.TapMin" in f for f in failures), failures)
        failures = self.mutated(lambda d: d.update(PromptPx=12))
        self.assertTrue(any("14 px text floor" in f for f in failures), failures)

    def test_the_glow_must_leak_more_each_tap(self):
        failures = self.mutated(lambda d: d.update(GlowTransparencyEnd=0.95))
        self.assertTrue(any("GlowTransparencyEnd" in f for f in failures), failures)


if __name__ == "__main__":
    unittest.main()
