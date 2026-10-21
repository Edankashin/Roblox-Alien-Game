"""Tests for tools/lint_data.lint_effects (data/Effects, B46's steep effects ladder) and tools/pixel_sprites.py, with no Studio.

Standard library and Pillow. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). The shipped table must pass, each rung of the ladder the lint states must fail when a row breaks
it, and the pixel sprite generator must draw exactly the Pixel keys of Icons.Particles (the keys data/Effects names).
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
import pixel_sprites  # noqa: E402

NAMES = ("Effects", "Tiers", "Icons", "Species", "Sounds", "Rigs")


def tables():
    reader = lint_data.TableReader()
    return {name: reader.read(ROOT / f"src/shared/data/{name}.luau") for name in NAMES}


TYPES = (ROOT / "src/shared/types/Types.luau").read_text(encoding="utf-8")
SHIPPED = tables()


class EffectsLint(unittest.TestCase):
    def setUp(self):
        self.tables = copy.deepcopy(SHIPPED)

    def failures(self):
        return lint_data.lint_effects(self.tables, TYPES)

    def species(self, sid):
        return self.tables["Effects"]["Species"][sid]

    def assertFails(self, fragment):
        found = self.failures()
        self.assertTrue(any(fragment in line for line in found), f"no failure naming {fragment!r} in {found}")

    def test_the_shipped_table_passes(self):
        self.assertEqual(self.failures(), [])

    def test_a_common_may_not_carry_a_light(self):
        self.species("Mossbop")["layers"][1] = {"kind": "Light", "color": "FFFFFF", "at": "Top", "brightness": 1, "range": 2}
        self.assertFails("a Common may not draw a Light")

    def test_an_epic_needs_its_signature_burst(self):
        layers = self.species("Thunderhog")["layers"]
        layers[4] = {"kind": "Emitter", "color": "FFFFFF", "at": "Back", "rate": 1, "size": 0.05, "lifetime": 1, "speed": 0, "spread": 0}
        self.assertFails("a Epic shows a Burst")

    def test_a_rare_needs_a_soft_light(self):
        layers = self.species("Rocklobber")["layers"]
        layers[2] = {"kind": "Sparkle", "color": "FFFFFF", "at": "Top", "every": 3, "count": 1, "size": 0.1, "lifetime": 0.4}
        self.assertFails("a Rare shows a Light")

    def test_an_uncommon_needs_a_second_colour(self):
        layers = self.species("Snailbyte")["layers"]
        layers[2]["color"] = layers[1]["color"]
        self.assertFails("second colour")

    def test_a_legendary_needs_a_flourish(self):
        for layer in self.species("Nebulyn")["layers"].values():
            layer.pop("flourish", None)
        self.assertFails("signature flourish")

    def test_a_firing_needs_a_clock_or_the_flourish(self):
        self.species("Pebblet")["layers"][1].pop("every")
        self.assertFails("a firing needs")

    def test_only_a_small_sparkle_at_the_eyes(self):
        layer = self.species("Shimmerlynx")["layers"][5]
        self.assertEqual(layer["at"], "Eyes")
        layer["size"] = 0.3
        self.assertFails("at the Eyes")

    def test_a_piece_must_be_a_moving_part_of_the_species_rig(self):
        self.tables["Effects"]["Pieces"]["Comet"]["part"] = "nosuchpart"
        self.assertFails("which is not a moving part of Rigs.Species.Nebulyn")

    def test_a_piece_names_a_real_fallback_region(self):
        self.tables["Effects"]["Pieces"]["Geode"]["region"] = "Nowhere"
        self.assertFails("Effects.Pieces.Geode.region")

    def test_a_rare_names_its_signature_and_hangs_its_strongest_layer_there(self):
        self.species("Rocklobber").pop("signature")
        self.assertFails("names its signature piece")
        self.species("Radish")["signature"] = "Feet"
        self.assertFails("its first (strongest) layer hangs on its signature")

    def test_the_signature_fires_on_the_flourish(self):
        self.species("Shellberg")["layers"][3].pop("flourish")
        self.assertFails("fires on the flourish")

    def test_a_trail_between_two_pieces_needs_two_fallback_regions(self):
        self.tables["Effects"]["Pieces"]["CometTail"]["region"] = "Halo"
        self.assertFails("fall back to one region")

    def test_a_burst_over_its_tier_is_caught(self):
        self.species("Pebblet")["layers"][1]["count"] = 40
        self.assertFails("over the Common burstMax")

    def test_the_ladder_may_not_drop_a_kind(self):
        self.tables["Effects"]["Tiers"]["Secret"]["kinds"].pop("Aura")
        self.assertFails("cannot drop a kind")

    def test_a_pillar_shows_on_the_flourish(self):
        self.species("Radish")["layers"][5].pop("flourish")
        self.assertFails("a Pillar shows on the flourish")

    def test_a_sheet_needs_a_fallback(self):
        self.tables["Effects"]["SpriteFallback"].pop("PixelTwinkle")
        self.assertFails("a sheet needs a SpriteFallback")


class PixelSprites(unittest.TestCase):
    def test_it_draws_exactly_the_pixel_keys(self):
        drawn = set(pixel_sprites.sprites())
        pixel_keys = {key for key in SHIPPED["Icons"]["Particles"] if key.startswith("Pixel")}
        self.assertEqual(drawn, pixel_keys)
        self.assertEqual(drawn, set(SHIPPED["Effects"]["SpriteFallback"]))

    def test_a_sprite_is_one_grid_and_a_sheet_two_by_two(self):
        sheets = set(SHIPPED["Effects"]["Sheets"])
        for name, image in pixel_sprites.sprites().items():
            side = pixel_sprites.GRID * (2 if name in sheets else 1)
            self.assertEqual(image.size, (side, side), name)
            self.assertIsNotNone(image.getbbox(), name)

    def test_the_committed_pngs_match_the_generator(self):
        for name, image in pixel_sprites.sprites().items():
            path = ROOT / "assets/sprites/blocky" / f"{name}.png"
            self.assertTrue(path.is_file(), name)
            from PIL import Image
            with Image.open(path) as committed:
                self.assertEqual(committed.convert("RGBA").tobytes(), pixel_sprites.upscale(image).tobytes(), name)


if __name__ == "__main__":
    unittest.main()
