"""Tests for tools/lint_data.lint_props (data/Props, how each imported prop collides), with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). The shipped table must pass, each rule the lint states must fail when the table breaks it, and the
Python and Luau lists of collision names must match (Shared/ModelInstall.PropCollisions, tests/ModelInstall.spec.luau).
"""
from __future__ import annotations

import copy
import pathlib
import re
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import lint_data  # noqa: E402


def tables():
    reader = lint_data.TableReader()
    return {name: reader.read(ROOT / f"src/shared/data/{name}.luau") for name in ("Props", "ModelAssets")}


class PropsLint(unittest.TestCase):
    def setUp(self):
        self.tables = copy.deepcopy(tables())

    def failures(self):
        return lint_data.lint_props(self.tables)

    def rows(self):
        return self.tables["Props"]["Rows"]

    def test_the_shipped_table_passes(self):
        self.assertEqual(self.failures(), [])

    def test_every_imported_prop_has_a_row(self):
        names = self.tables["ModelAssets"]["PropNames"]
        self.assertTrue(names)
        self.assertEqual(set(self.rows()), set(names))

    def test_a_missing_row_fails(self):
        del self.rows()["MeadowTree"]
        self.assertTrue(any("MeadowTree" in f and "no row" in f for f in self.failures()))

    def test_a_row_for_an_unknown_prop_fails(self):
        self.rows()["Bench"] = {"collision": "Hull"}
        self.assertTrue(any("Bench" in f and "PropNames" in f for f in self.failures()))

    def test_an_unknown_collision_fails(self):
        self.rows()["MeadowRock"]["collision"] = "Mesh"
        self.assertTrue(any("MeadowRock.collision" in f for f in self.failures()))

    def test_a_row_without_a_collision_or_with_extra_fields_fails(self):
        self.rows()["MeadowRock"] = {}
        self.rows()["IceRock"] = {"collision": "Hull", "mass": 1}
        found = self.failures()
        self.assertTrue(any("MeadowRock" in f and "just collision" in f for f in found))
        self.assertTrue(any("IceRock" in f and "just collision" in f for f in found))

    def test_a_missing_table_fails(self):
        self.tables["Props"] = {}
        self.assertTrue(self.failures())

    def test_luau_and_python_lists_match(self):
        source = lint_data.uncomment((ROOT / "src/shared/ModelInstall.luau").read_text())
        match = re.search(r"ModelInstall\.PropCollisions\s*=\s*\{([^}]*)\}", source)
        self.assertIsNotNone(match)
        self.assertEqual(tuple(re.findall(r'"(\w+)"', match[1])), lint_data.PROP_COLLISIONS)

    def test_the_types_union_names_the_same_values(self):
        source = lint_data.uncomment((ROOT / "src/shared/types/Types.luau").read_text())
        match = re.search(r"export\s+type\s+PropCollision\s*=\s*((?:\"\w+\"\s*\|?\s*)+)", source)
        self.assertIsNotNone(match)
        self.assertEqual(tuple(re.findall(r'"(\w+)"', match[1])), lint_data.PROP_COLLISIONS)


if __name__ == "__main__":
    unittest.main()
