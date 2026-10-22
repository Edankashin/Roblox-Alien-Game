"""Runs tools/create_products.py's own self-test (fake HTTP, temporary copies, no network, never the environment key).

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). It covers the create plan and write-back, and the price sync of Decision B51 (Server Luck x4 at
599): a read-only check never writes, an update sends only the price, a matching or Roblox-managed price is left alone, and an
update that does not read back is refused.
"""
from __future__ import annotations

import contextlib
import io
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import create_products  # noqa: E402


class CreateProducts(unittest.TestCase):
    def test_self_test_passes(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            create_products.self_test()
        self.assertIn("create products self-test:", out.getvalue())

    def test_price_plan_matches_data(self):
        rows = {row["id"]: row for row in create_products.price_plan()}
        self.assertEqual(rows["ServerLuck4x"]["price"], 599)
        self.assertEqual(rows["ServerLuck4x"]["kind"], "product")


if __name__ == "__main__":
    unittest.main()
