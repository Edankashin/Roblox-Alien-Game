"""Tests for Decision B46 in the blocky tools: the eye library (tools/blocky/eyes.py), the spec checks it adds to tools/blocky/spec.py (the
eyes on the face plate, B45's one height band, the motion ladder, the flourish gate, the finer bands) and the rig data writer
(tools/blocky/rigs.py, which must leave src/shared/data/Rigs.luau in step with the notes). Standard library only; ./tools/test.sh runs it.
"""
from __future__ import annotations

import copy
import importlib.util
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))


def _load(name, rel):
    spec = importlib.util.spec_from_file_location(name, ROOT / rel)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


E = _load("eyes", "tools/blocky/eyes.py")
S = _load("blocky_spec_b46", "tools/blocky/spec.py")
R = _load("blocky_rigs", "tools/blocky/rigs.py")
CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
MOOP = CREATURES / "Mossbop.md"
RADDIS = CREATURES / "Radish.md"


def errors_of(spec):
    return S.validate(spec)[0]


class Library(unittest.TestCase):
    def test_at_least_eighteen_designs_on_every_rung(self):
        self.assertGreaterEqual(len(E.DESIGNS), 18)
        by_tier = {}
        for d in E.DESIGNS.values():
            by_tier.setdefault(d["tier"], []).append(d["key"])
        for tier in E.TIER_ORDER:
            self.assertGreaterEqual(len(by_tier.get(tier, [])), 2, tier)
        self.assertGreaterEqual(len(by_tier["Common"]), 5)

    def test_frames_by_rung(self):
        for key, d in E.DESIGNS.items():
            names = E.frame_names(key)
            self.assertEqual(names[:3], ["open", "half", "closed"], key)
            rank = E.tier_rank(d["tier"])
            self.assertEqual(sum(n.startswith("glint") for n in names), 2 if rank >= E.tier_rank("Rare") else 0, key)
            cycle = [n for n in names if n.startswith("cycle")]
            self.assertEqual(len(cycle), E.CYCLE_FRAMES.get(d["tier"], 0), key)
            frames = E.eye_frames(key)
            size = (len(frames[0][1][0]), len(frames[0][1]))
            for name, grid in frames:
                self.assertEqual((len(grid[0]), len(grid)), size, (key, name))
                self.assertTrue(all(ch == "." or ch in E.ROLES for row in grid for ch in row), (key, name))

    def test_the_blink_closes_and_a_cycle_moves(self):
        def ink(grid):
            return sum(ch != "." for row in grid for ch in row)
        for key, d in E.DESIGNS.items():
            frames = dict(E.eye_frames(key))
            if not d["arc"]:
                self.assertLess(ink(frames["half"]), ink(frames["open"]), key)
            self.assertLess(ink(frames["closed"]), ink(frames["open"]), key)
            cycle = [g for n, g in E.eye_frames(key) if n.startswith("cycle")]
            if cycle:
                self.assertGreaterEqual(len({tuple(map(tuple, g)) for g in cycle}), len(cycle) // 2, key)

    def test_every_design_has_a_shine_and_densities_follow_the_floor(self):
        for key, d in E.DESIGNS.items():
            if not d["arc"]:
                self.assertTrue(any("w" in row for row in E.open_grid(key)), key)
            self.assertEqual(E.DENSITY[d["tier"]], 32 if E.tier_rank(d["tier"]) >= E.tier_rank("Legendary") else 16)

    def test_plate_sheet(self):
        spec = S.load(RADDIS)
        frames = E.plate_frames(spec["eyes"], S.face_host(spec))
        self.assertEqual(len(frames), 13)
        w, h, rgba = E.plate_sheet_rgba(frames, E.resolve_colours(spec["eyes"], S.palette(spec)))
        self.assertEqual((w, h), (56 * 4, 28 * 4))
        self.assertEqual(len(rgba), w * h * 4)


class SpecB46(unittest.TestCase):
    def test_the_pilots_are_clean_and_on_the_b46_format(self):
        for path in (MOOP, RADDIS):
            spec = S.load(path)
            self.assertTrue(S.is_b46(spec), path.name)
            self.assertEqual(errors_of(spec), [], path.name)
        self.assertGreaterEqual(S.motion_count(S.load(RADDIS)), 8)
        self.assertGreaterEqual(S.motion_count(S.load(MOOP)), 2)

    def test_b45_height_is_an_error_on_the_new_format_and_pending_on_the_old(self):
        spec = S.load(MOOP)
        for p in spec["parts"]:
            if p["name"] == "Spore":
                p["at"][1] += 1.5
                p["pivot"][1] += 1.5
        spec["front"]["height"] = S.counts(spec)["height"]
        self.assertTrue(any(e.startswith("B45:") for e in errors_of(spec)))
        # any note still on the old format (the roster batches convert them one by one; Gaiabloom went over in Roster w1_high)
        olds = [s for s in (S.load(p) for p in sorted(CREATURES.glob("*.md"))) if not S.is_b46(s) and S.counts(s)["height"] > S.BAND_HEIGHT[1]]
        if not olds:
            return
        old = olds[0]
        errors, warnings = S.validate(old)
        self.assertEqual(errors, [])
        self.assertTrue(any(w.startswith("B45 pending") for w in warnings))
        self.assertTrue(any(w.startswith("B46 pending") for w in warnings))

    def test_eye_tier_floor(self):
        spec = S.load(MOOP)
        spec["eyes"]["key"] = "galaxy"
        self.assertTrue(any("tier floor" in e for e in errors_of(spec)))
        spec["eyes"]["key"] = "nope"
        self.assertTrue(any("not in the eye library" in e for e in errors_of(spec)))
        raddis = S.load(RADDIS)
        raddis["eyes"]["key"] = "halo"
        self.assertTrue(any("its own rung" in e for e in errors_of(raddis)))

    def test_plate_must_fit_the_head(self):
        spec = S.load(MOOP)
        spec["eyes"]["plate"] = [2.5, 1]
        self.assertTrue(any("runs off" in e for e in errors_of(spec)))

    def test_motion_ladder_and_blink(self):
        spec = S.load(RADDIS)
        for key in ("halo", "wing", "orb", "mote", "leaf"):
            del spec["rig"]["clips"][key]
        errs = errors_of(spec)
        self.assertTrue(any("has no clip" in e for e in errs))
        self.assertTrue(any("moving things" in e for e in errs))
        spec = S.load(MOOP)
        del spec["rig"]["clips"]["face"]
        self.assertTrue(any("blink" in e for e in errors_of(spec)))

    def test_flourish_gate(self):
        spec = S.load(MOOP)
        spec["rig"]["flourish"] = {"every": 10, "length": 1.5, "moves": [{"part": "root", "kind": "hop", "amp": 0.2, "at": 0, "for": 1}]}
        self.assertTrue(any("has no flourish" in e for e in errors_of(spec)))
        raddis = S.load(RADDIS)
        del raddis["rig"]["flourish"]
        self.assertTrue(any("has a flourish" in e for e in errors_of(raddis)))
        raddis = S.load(RADDIS)
        raddis["rig"]["flourish"]["length"] = 1.5
        self.assertTrue(any("lasts" in e for e in errors_of(raddis)))

    def test_clip_ranges(self):
        spec = S.load(MOOP)
        spec["rig"]["clips"]["sprout"] = [{"kind": "sway", "amp": 80, "period": 3}]
        self.assertTrue(any("degrees" in e for e in errors_of(spec)))
        spec["rig"]["clips"]["sprout"] = [{"kind": "wobble", "amp": 8, "period": 3}]
        self.assertTrue(any("kind" in e for e in errors_of(spec)))

    def test_mirrored_clip_changes_sign(self):
        r = S.rig(S.load(RADDIS))
        self.assertEqual(r["clips"]["wingR"][0]["amp"], -r["clips"]["wingL"][0]["amp"])
        self.assertEqual(r["clips"]["moteR"][0]["amp"], r["clips"]["moteL"][0]["amp"])   # an orbit about y keeps its sign

    def test_new_bands_and_finer_grid(self):
        self.assertEqual(S.DETAIL_GRID["Cosmic"], 0.0625)
        for tier in S.TIER_ORDER:
            self.assertGreaterEqual(S.BANDS_B46[tier][1], S.TIERS[tier]["blocks"][1])


class Rigs(unittest.TestCase):
    def test_rigs_luau_is_up_to_date(self):
        text, rows = R.generate()
        self.assertEqual((ROOT / "src/shared/data/Rigs.luau").read_text(encoding="utf-8"), text,
                         "run python3 -I tools/blocky/rigs.py")
        self.assertIn("Radish", {r["id"] for r in rows})

    def test_python_pose_matches_the_luau_math(self):
        pose = R.new_pose()
        R.accumulate(pose, {"kind": "bob", "amp": 0.1, "period": 2, "phase": 0, "axis": "y"}, 0.5, 0)
        self.assertAlmostEqual(pose["p"][1], 0.1)
        pose = R.new_pose()
        R.accumulate_move(pose, {"kind": "turn", "amp": 360, "axis": "y", "at": 0, "for": 1}, 1)
        self.assertAlmostEqual(pose["r"][1], 2 * 3.141592653589793)
        face = R.row(S.load(RADDIS))["face"]
        self.assertEqual(R.face_frame(face, 0.03, 0), face["half"])


if __name__ == "__main__":
    unittest.main()
