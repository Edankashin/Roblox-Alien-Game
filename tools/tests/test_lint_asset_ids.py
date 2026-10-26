"""Tests for tools/lint_data.lint_asset_ids: one asset id is never used under two asset types (the Studio Output line
"ContentId: rbxassetid://<id> failed due to: Asset type does not match requested type"), with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
"""
from __future__ import annotations

import copy
import json
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import lint_data  # noqa: E402

NAMES = ("Sounds", "Music", "Icons", "BlockTiles", "Textures", "Lighting", "ModelAssets")


class AssetIdLint(unittest.TestCase):
    def setUp(self):
        reader = lint_data.TableReader()
        self.pristine = {name: reader.read(ROOT / f"src/shared/data/{name}.luau") for name in NAMES}

    def failures(self, change=None):
        tables = copy.deepcopy(self.pristine)
        if change:
            change(tables)
        return lint_data.lint_asset_ids(tables, ROOT)

    def test_shipped_tables_are_clean(self):
        self.assertEqual(self.failures(), [])

    def test_reads_ids_of_every_type(self):
        kinds = {kind for rows in lint_data.asset_id_uses(self.pristine, ROOT).values() for kind, _ in rows}
        self.assertEqual(kinds, {"sound", "image", "model", "decal"})

    def test_a_sound_id_pasted_into_icons_fails(self):
        def change(tables):
            tables["Icons"]["Icons"]["Aliens"] = int(tables["Sounds"]["Click"].split("//")[1])
        found = self.failures(change)
        self.assertEqual(len(found), 1)
        self.assertIn("image and sound", found[0])
        self.assertIn("Sounds.Click", found[0])
        self.assertIn("Icons.Icons.Aliens", found[0])

    def test_an_image_id_in_music_fails(self):
        def change(tables):
            tables["Music"]["Rows"]["Home"]["assetId"] = tables["BlockTiles"]["Ids"]["Dirt"]["id"]
        self.assertTrue(any("image and sound" in f for f in self.failures(change)))

    def test_a_decal_id_used_as_an_image_fails(self):
        def change(tables):
            rows = json.loads((ROOT / "assets/icons/asset_ids.json").read_text())
            tables["Icons"]["Icons"]["Codex"] = next(iter(rows.values()))["assetId"]
        self.assertTrue(any("decal and image" in f for f in self.failures(change)))

    def test_a_model_id_in_sounds_fails(self):
        def change(tables):
            tables["Sounds"]["Fled"] = "rbxassetid://%d" % next(iter(tables["ModelAssets"]["AssetIds"].values()))
        self.assertTrue(any("model and sound" in f for f in self.failures(change)))

    def test_the_same_id_twice_under_one_type_is_fine(self):
        def change(tables):
            tables["Sounds"]["Fled"] = tables["Sounds"]["Click"]
        self.assertEqual(self.failures(change), [])

    def test_zero_is_not_an_id(self):
        def change(tables):
            tables["Icons"]["Icons"]["Aliens"] = 0
            tables["Sounds"]["Fled"] = "rbxassetid://0"
            tables["Music"]["Rows"]["Home"]["assetId"] = 0
        self.assertEqual(self.failures(change), [])


if __name__ == "__main__":
    unittest.main()
