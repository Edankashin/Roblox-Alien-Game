"""Tests for tools/blender/style_checks.py (the three low-poly style checks), with no Blender.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'   (./tools/test.sh runs it too).
The tool reads a GLB with the pure-Python reader of tools/blockbench/to_bbmodel.py and reads recipes from species_recipes.py, so it needs no bpy; the
maths is checked on synthetic shapes (two triangles, a cube, a rounded box, a disc, small recipes built with the recipe module's own step makers) and
the whole run on one shipped model with structural assertions only (the numbers of the shipped species belong to the sheet in Character-Pipeline.md).
One test compares the hard-edge count with Blender's own bmesh in a child process; it runs when a Python with bpy is named by BPY_PYTHON (or is
the current interpreter) and is skipped otherwise, the way test_unwrap_bake.py does it.
"""
from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import math
import os
import pathlib
import subprocess
import sys
import unittest
from unittest import mock

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
_SPEC = importlib.util.spec_from_file_location("style_checks", ROOT / "tools/blender/style_checks.py")
sc = importlib.util.module_from_spec(_SPEC)
sys.modules["style_checks"] = sc
_SPEC.loader.exec_module(sc)  # type: ignore[union-attr]
sr = sc.load_recipes()


def recipe(*steps, status="recipe"):
    """A minimal recipe: just the steps (the limb check does not look at the face or the palette)."""
    return {"status": status, "steps": list(steps)}


BODY = sr.sph("Body", (0, 0, 1.2), (1.0, 1.0, 1.0), name="body")


def limbs_of(*steps):
    return sc.limb_parts(sr, recipe(BODY, *steps))


def fake_recipes(**recipes):
    """A stand-in for the recipe module with only these recipes: what taper_report and main read."""
    return type("FakeRecipes", (), {"RECIPES": recipes, "euler_matrix": staticmethod(sr.euler_matrix), "mirror_matrix": staticmethod(sr.mirror_matrix),
                                    "SMOOTH_BY_DEFAULT": sr.SMOOTH_BY_DEFAULT})


class DihedralOfTwoTriangles(unittest.TestCase):
    # two triangles sharing the edge (0,0,0)-(0,1,0), wound the same way; the first lies in the xy plane, normal +z
    A = ((0, 0, 0), (1, 0, 0), (0, 1, 0))

    def test_coplanar_triangles_do_not_bend(self):
        b = ((0, 0, 0), (0, 1, 0), (-1, 0, 0))
        self.assertAlmostEqual(sc.dihedral_deg(self.A, b), 0.0, places=6)

    def test_a_right_angle_fold_is_ninety_degrees(self):
        b = ((0, 0, 0), (0, 1, 0), (0, 0, 1))
        self.assertAlmostEqual(sc.dihedral_deg(self.A, b), 90.0, places=6)

    def test_a_shallow_fold_is_its_angle(self):
        b = ((0, 0, 0), (0, 1, 0), (-1, 0, 1))
        self.assertAlmostEqual(sc.dihedral_deg(self.A, b), 45.0, places=6)

    def test_a_triangle_folded_back_on_itself_is_a_hundred_and_eighty(self):
        b = ((0, 0, 0), (0, 1, 0), (1, 0, 0))   # same plane, wound the other way
        self.assertAlmostEqual(sc.dihedral_deg(self.A, b), 180.0, places=6)

    def test_a_degenerate_triangle_has_no_angle(self):
        flat = ((0, 0, 0), (1, 0, 0), (2, 0, 0))
        self.assertIsNone(sc.dihedral_deg(self.A, flat))

    def test_hard_is_strictly_sharper_than_the_threshold(self):
        self.assertFalse(sc.is_hard(59.9))
        self.assertFalse(sc.is_hard(60.0))
        self.assertTrue(sc.is_hard(60.1))
        self.assertFalse(sc.is_hard(None))
        self.assertTrue(sc.is_hard(45.1, threshold=45.0))


class EdgesOfAMesh(unittest.TestCase):
    def test_a_cube_has_twelve_unbevelled_hard_edges_and_no_open_edge(self):
        tris = sc.cube_mesh()
        rep = sc.edge_report(tris, ["Body"] * len(tris))
        self.assertEqual(rep[""]["hard"], 12)          # the 12 box edges; the six diagonals of the quads are flat
        self.assertEqual(rep[""]["unbevelled"], 12)
        self.assertEqual(rep[""]["small"], 0)
        self.assertEqual(rep[""]["open"], 0)
        self.assertEqual(rep[""]["edges"], 18)

    def test_a_rounded_box_has_none(self):
        tris = sc.rounded_box_mesh(0.4)
        rep = sc.edge_report(tris, ["Body"] * len(tris))
        self.assertEqual(rep[""]["hard"], 0)
        self.assertEqual(rep[""]["open"], 0)

    def test_a_sphere_has_none(self):
        tris = sc.sphere_mesh()
        rep = sc.edge_report(tris, ["Body"] * len(tris))
        self.assertEqual(rep[""]["hard"], 0)

    def test_the_hard_edges_of_a_tiny_cube_beside_a_big_plate_are_small_not_unbevelled(self):
        tiny = sc.cube_mesh(0.01)
        plate = [((-5, 0, -5), (5, 0, -5), (5, 0, 5)), ((-5, 0, -5), (5, 0, 5), (-5, 0, 5))]
        tris = tiny + plate
        rep = sc.edge_report(tris, ["Body"] * len(tris))
        self.assertEqual((rep[""]["hard"], rep[""]["unbevelled"], rep[""]["small"]), (12, 0, 12))

    def test_a_hard_edge_counts_in_both_slots_it_touches_and_once_in_the_total(self):
        tris = sc.cube_mesh()
        slots = ["Body"] * len(tris)
        slots[0] = slots[1] = "Accessory"              # one face (two triangles) in its own slot
        rep = sc.edge_report(tris, slots)
        self.assertEqual(rep[""]["hard"], 12)
        self.assertEqual(rep["Accessory"]["hard"], 4)   # the four edges of that face
        self.assertEqual(rep["Body"]["hard"], 12)
        self.assertEqual(rep["Body"]["edges"], 17)         # all but the diagonal inside that face
        self.assertEqual(rep["Accessory"]["edges"], 5)

    def test_welding_joins_the_duplicated_corners_of_a_hard_edge(self):
        tris = sc.cube_mesh()
        points, ids, keep = sc.weld(tris)
        self.assertEqual(len(points), 8)
        self.assertEqual(len(ids), 12)
        self.assertEqual(keep, list(range(12)))

    def test_a_triangle_with_a_repeated_corner_is_dropped(self):
        points, ids, keep = sc.weld([((0, 0, 0), (1, 0, 0), (0, 1, 0)), ((0, 0, 0), (0, 0, 0), (0, 1, 0))])
        self.assertEqual(len(ids), 1)
        self.assertEqual(keep, [0])

    def test_the_bevel_verdict_sets_crisp_slots_apart(self):
        tris = sc.cube_mesh()
        slots = ["Accessory"] * len(tris)
        sharp = sc.bevel_report(tris, slots, {})
        crisp = sc.bevel_report(tris, slots, {"Accessory": "test"})
        self.assertFalse(sharp["pass"])
        self.assertEqual(sharp["soft_unbevelled"], 12)
        self.assertTrue(crisp["pass"])
        self.assertEqual((crisp["soft_unbevelled"], crisp["crisp_unbevelled"]), (0, 12))
        self.assertEqual(crisp["slots"]["Accessory"]["crisp"], "test")

    def test_the_face_slots_are_not_judged(self):
        tris = sc.cube_mesh()
        rep = sc.bevel_report(tris, ["EyeWhite"] * len(tris), {})
        self.assertTrue(rep["pass"])
        self.assertEqual(rep["slots"]["EyeWhite"]["unbevelled"], 12)


class TaperMaths(unittest.TestCase):
    def test_ratio_is_tip_over_root(self):
        self.assertAlmostEqual(sc.taper_ratio(0.2, 0.1), 0.5)
        self.assertAlmostEqual(sc.taper_ratio(0.2, 0.2), 1.0)
        self.assertAlmostEqual(sc.taper_ratio(0.1, 0.2), 2.0)
        self.assertEqual(sc.taper_ratio(0.0, 0.1), 0.0)

    def test_the_bar_is_about_point_eight_five(self):
        self.assertTrue(sc.taper_ok(0.5))
        self.assertTrue(sc.taper_ok(0.85))
        self.assertTrue(sc.taper_ok(0.8500000000000001))   # Skydrake's horn: the float of 0.17 / 0.2
        self.assertFalse(sc.taper_ok(0.86))
        self.assertFalse(sc.taper_ok(1.0))
        self.assertFalse(sc.taper_ok(1.5))


class LimbsOfARecipe(unittest.TestCase):
    def test_an_even_rod_fails_and_a_taper_passes(self):
        got = limbs_of(sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, name="leg"),
                       sr.rod("Body", (0.0, 0.8, 1.2), (0.0, 1.4, 0.2), 0.2, 0.1, name="tail"))
        by = {l["name"]: l for l in got}
        self.assertFalse(by["leg"]["ok"])
        self.assertAlmostEqual(by["leg"]["ratio"], 1.0)
        self.assertEqual(by["leg"]["kind"], "rod")
        self.assertTrue(by["tail"]["ok"])
        self.assertAlmostEqual(by["tail"]["ratio"], 0.5)
        self.assertEqual(by["tail"]["kind"], "cone")

    def test_a_slight_taper_still_fails(self):
        (leg,) = limbs_of(sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, 0.18, name="leg"))
        self.assertFalse(leg["ok"])
        self.assertAlmostEqual(leg["ratio"], 0.9)

    def test_the_root_is_the_end_nearer_the_body_whichever_way_the_rod_was_written(self):
        down = limbs_of(sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, 0.1, name="leg"))[0]      # wide end written first, at the body
        up = limbs_of(sr.rod("Body", (0.6, 0, 0.1), (0.6, 0, 1.0), 0.1, 0.2, name="leg"))[0]        # the same leg written foot first
        for leg in (down, up):
            self.assertTrue(leg["ok"], leg)
            self.assertAlmostEqual(leg["ratio"], 0.5)
            self.assertAlmostEqual(leg["root"], 0.2)

    def test_a_flare_toward_the_tip_fails(self):
        (leg,) = limbs_of(sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.1, 0.2, name="leg"))     # narrow at the hip, wide at the foot
        self.assertFalse(leg["ok"])
        self.assertAlmostEqual(leg["ratio"], 2.0)

    def test_a_pointed_cone_passes(self):
        (horn,) = limbs_of(sr.spike("Accessory", (0.3, 0, 2.0), (0.3, 0, 3.0), 0.2, name="horn"))
        self.assertTrue(horn["ok"])
        self.assertAlmostEqual(horn["ratio"], 0.0)

    def test_a_mirrored_step_is_two_limbs(self):
        got = limbs_of(sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, mirror=True, name="leg"))
        self.assertEqual(len(got), 2)

    def test_a_sweep_tube_reads_its_radii_from_the_end_nearer_the_body(self):
        tail = sr.sweep("Body", [(0.0, 1.0, 1.2), (0.0, 1.6, 1.4), (0.0, 2.2, 2.0)], [0.3, 0.2, 0.1], name="tail")
        backwards = sr.sweep("Body", [(0.0, 2.2, 2.0), (0.0, 1.6, 1.4), (0.0, 1.0, 1.2)], [0.1, 0.2, 0.3], name="tail")
        even = sr.sweep("Body", [(0.0, 1.0, 1.2), (0.0, 1.6, 1.4), (0.0, 2.2, 2.0)], [0.2, 0.2, 0.2], name="tail")
        for t in (tail, backwards):
            (l,) = limbs_of(t)
            self.assertTrue(l["ok"], l)
            self.assertEqual(l["kind"], "sweep")
            self.assertAlmostEqual(l["ratio"], 1.0 / 3.0, places=2)
        (l,) = limbs_of(even)
        self.assertFalse(l["ok"])

    def test_the_trunk_and_the_neck_are_not_limbs_but_an_unlisted_tube_is(self):
        trunk = sr.sweep("Body", [(0.0, 0.0, 0.5), (0.0, 1.0, 0.6)], [0.5, 0.5], name="body")
        neck = sr.sweep("Body", [(0.0, 0.0, 2.0), (0.0, -0.5, 2.6)], [0.4, 0.4], name="neck")
        stem = sr.sweep("BodyDark", [(0.0, 0.0, 2.0), (0.0, 0.0, 2.6)], [0.1, 0.1], name="whatever")
        got = limbs_of(trunk, neck, stem)
        self.assertEqual([l["name"] for l in got], ["whatever"])

    def test_a_chain_of_balls_is_one_limb_and_a_lone_ball_is_none(self):
        shrinking = [sr.sph("Body", (0.0, 1.1 + 0.5 * i, 1.0), (0.4 - 0.1 * i,) * 3, name="tail") for i in range(3)]
        even = [sr.sph("Body", (0.0, 1.1 + 0.4 * i, 1.0), (0.3,) * 3, name="tail") for i in range(3)]
        (a,) = limbs_of(*shrinking)
        self.assertEqual((a["kind"], a["segments"]), ("chain", 3))
        self.assertTrue(a["ok"])
        self.assertAlmostEqual(a["ratio"], 0.5)
        (b,) = limbs_of(*even)
        self.assertFalse(b["ok"])
        self.assertEqual(limbs_of(sr.sph("Body", (0.0, 1.1, 1.0), (0.3,) * 3, name="tail")), [])

    def test_rods_that_meet_end_to_end_are_one_limb_judged_end_to_end(self):
        first = sr.rod("BodyDark", (0.0, -0.2, 2.1), (0.1, -0.2, 2.5), 0.1, 0.095, name="antenna")     # a bent antenna: 0.95 on its own
        second = sr.rod("BodyDark", (0.1, -0.2, 2.5), (0.3, -0.2, 2.9), 0.095, 0.06, name="antenna")
        (l,) = limbs_of(first, second)
        self.assertEqual(l["segments"], 2)
        self.assertTrue(l["ok"])
        self.assertAlmostEqual(l["ratio"], 0.6)

    def test_two_limbs_that_start_at_the_same_root_stay_two(self):
        a = sr.rod("BodyDark", (0.0, -0.2, 2.1), (0.4, -0.2, 2.9), 0.1, 0.05, name="antler")
        b = sr.rod("BodyDark", (0.0, -0.2, 2.1), (-0.4, -0.2, 2.9), 0.1, 0.05, name="antler")
        self.assertEqual(len(limbs_of(a, b)), 2)

    def test_parts_that_are_not_limbs_are_left_alone(self):
        got = limbs_of(sr.rod("Accessory", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, name="reed"), sr.sph("Body", (0.9, 0, 1.0), (0.2, 0.2, 0.2), name="ear"))
        self.assertEqual(got, [])

    def test_the_report_names_what_fails(self):
        rec = recipe(BODY, sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, mirror=True, name="leg"),
                     sr.rod("Body", (0.0, 0.8, 1.2), (0.0, 1.4, 0.2), 0.2, 0.1, name="tail"))
        fake = fake_recipes(X=rec)
        rep = sc.taper_report(fake, "X")
        self.assertFalse(rep["pass"])
        self.assertEqual(rep["limbs"], 3)
        self.assertEqual(rep["failing_parts"], 2)
        self.assertEqual(rep["failing"], [{"name": "leg", "kind": "rod", "ratio": 1.0, "count": 2}])
        self.assertEqual(sc.taper_report(fake, "nope"), {"skip": "no recipe nope"})

    def test_a_stub_has_nothing_to_check(self):
        self.assertIn("skip", sc.taper_report(fake_recipes(S={"status": "TODO", "steps": []}), "S"))


class EveryRecipeIsReadable(unittest.TestCase):
    def test_every_recipe_gives_finite_ratios(self):
        for key, rec in sr.RECIPES.items():
            if rec.get("status") != "recipe":
                continue
            with self.subTest(key):
                for l in sc.limb_parts(sr, rec):
                    self.assertTrue(math.isfinite(l["ratio"]) and l["ratio"] >= 0.0, l)
                    self.assertGreaterEqual(l["segments"], 1)

    def test_the_report_of_every_recipe_has_the_same_shape(self):
        for key in sr.RECIPES:
            with self.subTest(key):
                rep = sc.taper_report(sr, key)
                self.assertTrue("skip" in rep or {"limbs", "failing", "pass"} <= set(rep))

    def test_the_v2_keys_are_the_design_pass_prototypes(self):
        keys = sc.v2_keys(sr)
        self.assertTrue(keys)
        self.assertNotIn("FenripupV2", keys)
        for k in keys:
            self.assertTrue(sr.RECIPES[k].get("prototype"))
            self.assertTrue(k.endswith("V2"))


def disc(size=64):
    return [[1 if (math.hypot((i + 0.5) / size - 0.5, (j + 0.5) / size - 0.5) <= 0.5) else 0 for i in range(size)] for j in range(size)]


def rounded_square(radius, size=64):
    """A rounded square of corner radius `radius` (a share of the side) as a mask: the analytic reference."""
    def inside(u, v):
        x, y = min(u, 1 - u), min(v, 1 - v)
        return x >= radius or y >= radius or math.hypot(x - radius, y - radius) <= radius
    return [[1 if inside((i + 0.5) / size, (j + 0.5) / size) else 0 for i in range(size)] for j in range(size)]


class PlanOutline(unittest.TestCase):
    def test_a_filled_square_fills_every_corner(self):
        mean, four = sc.corner_fill([[1] * 64 for _ in range(64)])
        self.assertEqual(mean, 1.0)
        self.assertEqual(four, [1.0, 1.0, 1.0, 1.0])

    def test_an_empty_picture_fills_none(self):
        self.assertEqual(sc.corner_fill([[0] * 64 for _ in range(64)])[0], 0.0)

    def test_a_disc_leaves_the_corners_almost_empty(self):
        self.assertLess(sc.corner_fill(disc())[0], 0.03)

    def test_one_filled_corner_is_a_quarter(self):
        mask = [[0] * 64 for _ in range(64)]
        for j in range(10):
            for i in range(10):
                mask[j][i] = 1
        mean, four = sc.corner_fill(mask)
        self.assertAlmostEqual(mean, 0.25)
        self.assertEqual(four, [1.0, 0.0, 0.0, 0.0])

    def test_the_corner_square_is_fifteen_percent_of_the_side(self):
        # 15 percent of 64 px: pixel centres under 9.6 px, that is the first ten pixels
        mask = [[0] * 64 for _ in range(64)]
        for j in range(9):
            for i in range(9):
                mask[j][i] = 1
        self.assertAlmostEqual(sc.corner_fill(mask)[1][0], 81 / 100.0)

    def test_rasterizing_a_square_of_two_triangles_fills_the_box(self):
        grid = sc.rasterize([((0, 0), (4, 0), (4, 4)), ((0, 0), (4, 4), (0, 4))])
        self.assertEqual(sum(map(sum, grid)), 64 * 64)

    def test_rasterizing_a_circle_polygon_matches_the_disc(self):
        n = 96
        pts = [(math.cos(2 * math.pi * k / n), math.sin(2 * math.pi * k / n)) for k in range(n)]
        fan = [((0.0, 0.0), pts[k], pts[(k + 1) % n]) for k in range(n)]
        grid = sc.rasterize(fan)
        self.assertAlmostEqual(sum(map(sum, grid)) / (64.0 * 64.0), math.pi / 4.0, delta=0.02)
        self.assertLess(sc.corner_fill(grid)[0], 0.05)

    def test_an_empty_triangle_list_is_an_empty_picture(self):
        self.assertEqual(sum(map(sum, sc.rasterize([]))), 0)

    def test_the_box_stretches_a_thin_shape_to_the_square(self):
        # a 10 x 1 bar fills its own bounding box, however thin
        grid = sc.rasterize([((0, 0), (10, 0), (10, 1)), ((0, 0), (10, 1), (0, 1))])
        self.assertEqual(sc.corner_fill(grid)[0], 1.0)

    def test_the_views_are_from_above_and_from_the_front_with_y_up(self):
        plate = [((0, 0, 0), (2, 0, 0), (2, 0, 2)), ((0, 0, 0), (2, 0, 2), (0, 0, 2))]    # a square lying flat (in x and z)
        views = sc.views_of(plate)
        self.assertEqual(sum(map(sum, views["top"])), 64 * 64)      # seen from above it is a full square
        self.assertEqual(sum(map(sum, views["front"])), 0)          # seen from the front it is edge-on: a line, no area

    def test_the_closed_form_of_the_references(self):
        # a corner square of 15 percent against a quarter circle, integrated: 0.465 at a quarter of the side, 0.628 at a fifth, 0.905 at a tenth
        def analytic(r, frac=0.15, n=300):
            hit = 0
            for i in range(n):
                for j in range(n):
                    x, y = (i + 0.5) / n * frac, (j + 0.5) / n * frac
                    hit += 1 if x >= r or y >= r or math.hypot(x - r, y - r) <= r else 0
            return hit / float(n * n)
        self.assertAlmostEqual(analytic(0.25), 0.465, delta=0.005)
        self.assertAlmostEqual(analytic(0.2), 0.628, delta=0.005)
        self.assertAlmostEqual(analytic(0.1), 0.905, delta=0.005)
        # the 64 px mask reads a ten pixel corner (15.6 percent), a little fuller
        self.assertAlmostEqual(sc.corner_fill(rounded_square(0.25))[0], analytic(0.25), delta=0.06)
        self.assertAlmostEqual(sc.corner_fill(rounded_square(0.1))[0], analytic(0.1), delta=0.06)

    def test_the_calibration_shapes_agree_with_the_closed_form(self):
        table = sc.calibrate()
        self.assertEqual(table["cube"]["top"], 1.0)
        self.assertEqual(table["cube"]["front"], 1.0)
        self.assertLess(table["sphere"]["top"], 0.03)
        for r in (0.1, 0.2, 0.25, 0.3, 0.4):
            self.assertAlmostEqual(table["rounded box %.2f" % r]["top"], sc.corner_fill(rounded_square(r))[0], delta=0.04, msg=r)
            self.assertEqual(table["rounded box %.2f" % r]["top"], table["rounded box %.2f" % r]["front"])

    def test_the_bar_is_the_line_between_mostly_full_and_mostly_empty(self):
        table = sc.calibrate()
        self.assertEqual(sc.CORNER_FILL_MAX, 0.5)
        self.assertLess(table["sphere"]["top"], sc.CORNER_FILL_MAX)
        self.assertLess(sc.CORNER_FILL_MAX, table["cube"]["top"])
        self.assertAlmostEqual(table["rounded box 0.25"]["top"], sc.CORNER_FILL_MAX, delta=0.03)   # a quarter-side rounded square sits on the bar
        self.assertGreater(table["rounded box 0.20"]["top"], sc.CORNER_FILL_MAX)
        self.assertLess(table["rounded box 0.30"]["top"], sc.CORNER_FILL_MAX)
        fills = [v["top"] for k, v in table.items() if k.startswith("rounded")]
        self.assertEqual(fills, sorted(fills, reverse=True))        # rounder is emptier

    def test_the_plan_verdict(self):
        self.assertFalse(sc.plan_report(sc.cube_mesh())["pass"])
        self.assertTrue(sc.plan_report(sc.sphere_mesh())["pass"])
        self.assertTrue(sc.plan_report(sc.rounded_box_mesh(0.8, 1.0, 24))["pass"])      # corners of 40 percent of the side
        self.assertFalse(sc.plan_report(sc.rounded_box_mesh(0.2, 1.0, 24))["pass"])     # corners of 10 percent
        rep = sc.plan_report(sc.cube_mesh())
        self.assertEqual((rep["top"], rep["front"], rep["bar"]), (1.0, 1.0, sc.CORNER_FILL_MAX))


SHIPPED = ROOT / "assets/models/Mossbop/Mossbop.glb"
# the block-cell export (tools/blocky/export_models.py, Decision B46) replaced the blockout these checks were written for
BLOCK_CELL = (ROOT / "assets/models/Mossbop/Mossbop_atlas.png").exists()


class WholeRun(unittest.TestCase):
    @unittest.skipUnless(SHIPPED.exists() and not BLOCK_CELL, "assets/models/Mossbop/Mossbop.glb is not a blockout in this checkout")
    def test_a_shipped_model_gets_all_three_results(self):
        bb = sc.load_glb_reader()
        row = sc.run_species(sr, bb, "Mossbop", SHIPPED, "Mossbop", sc.MODELS)
        tris, _ = sc.read_mesh(bb, SHIPPED)
        self.assertEqual(row["triangles"], len(tris))
        self.assertGreater(row["bevel"]["edges"], len(tris))                 # a closed mesh has about 1.5 edges a triangle
        self.assertEqual(row["bevel"]["nonmanifold"], 0)
        self.assertTrue({"Body", "EyeWhite", "Pupil", "Mouth"} <= set(row["bevel"]["slots"]))
        self.assertIn(row["bevel"]["pass"], (True, False))
        self.assertTrue(0.0 <= row["plan"]["top"] <= 1.0 and 0.0 <= row["plan"]["front"] <= 1.0)
        self.assertIn("pass", row["taper"])
        text = sc.line(row)
        self.assertTrue(text.startswith("Mossbop"))
        self.assertEqual(text.count("|"), 2)
        json.dumps(row)                                                      # the sheet is JSON

    def test_a_species_with_no_glb_still_gets_its_recipe_check(self):
        key = sc.v2_keys(sr)[0]
        row = sc.run_species(sr, None, key, None, key, sc.MODELS)
        self.assertIn("skip", row["bevel"])
        self.assertIn("skip", row["plan"])
        self.assertIn("pass", row["taper"])

    def test_resolving_a_target(self):
        self.assertEqual(sc.resolve_target("Mossbop", "/m"), ("Mossbop", pathlib.Path("/m/Mossbop/Mossbop.glb"), "Mossbop"))
        self.assertEqual(sc.resolve_target("some/dir/Foo.glb", "/m"), ("Foo", pathlib.Path("some/dir/Foo.glb"), "Foo"))

    def test_the_command_line_prints_a_line_per_recipe_and_writes_json(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            out = pathlib.Path(tmp) / "sheet.json"
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                code = sc.main(["--recipe", "v2", "--json", str(out)])
            self.assertEqual(code, 0)
            sheet = json.loads(out.read_text())
        self.assertEqual(len(sheet["recipes"]), len(sc.v2_keys(sr)))
        self.assertEqual(sheet["thresholds"]["hard_angle"], 60.0)
        self.assertGreaterEqual(buf.getvalue().count("taper"), len(sheet["recipes"]))

    def test_calibrate_prints_the_references(self):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(sc.main(["--calibrate"]), 0)
        self.assertIn("cube", buf.getvalue())
        self.assertIn("sphere", buf.getvalue())

    def test_strict_exits_one_when_a_check_fails_and_zero_otherwise(self):
        bad = recipe(BODY, sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, name="leg"))
        good = recipe(BODY, sr.rod("Body", (0.6, 0, 1.0), (0.6, 0, 0.1), 0.2, 0.1, name="leg"))
        with mock.patch.object(sc, "load_recipes", return_value=fake_recipes(Bad=bad, Good=good)), contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(sc.main(["--recipe", "Bad"]), 0)
            self.assertEqual(sc.main(["--recipe", "Bad", "--strict"]), 1)
            self.assertEqual(sc.main(["--recipe", "Good", "--strict"]), 0)
        self.assertIn("taper FAIL", out.getvalue())
        self.assertIn("taper pass", out.getvalue())


def bpy_python():
    if importlib.util.find_spec("bpy") is not None:
        return sys.executable
    named = os.environ.get("BPY_PYTHON")
    if named and subprocess.run([named, "-c", "import bpy"], capture_output=True).returncode == 0:
        return named
    return None


BPY = bpy_python()
BMESH_PROBE = r"""
import math, sys, bpy, bmesh
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=sys.argv[1])
obj = [o for o in bpy.data.objects if o.type == "MESH"][0]
bm = bmesh.new(); bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
n = hard = 0
for e in bm.edges:
    if len(e.link_faces) == 2:
        n += 1
        hard += 1 if math.degrees(e.calc_face_angle()) > 60.0 + 1e-6 else 0
print(n, hard)
"""


class AgainstBlender(unittest.TestCase):
    @unittest.skipUnless(BPY and SHIPPED.exists() and not BLOCK_CELL, "bpy is not importable here (set BPY_PYTHON to a Python that has it)")
    def test_the_edge_and_hard_edge_counts_match_blenders_bmesh(self):
        probe = subprocess.run([BPY, "-c", BMESH_PROBE, str(SHIPPED)], capture_output=True, text=True, check=True)
        edges, hard = (int(v) for v in probe.stdout.split()[-2:])
        tris, slots = sc.read_mesh(sc.load_glb_reader(), SHIPPED)
        mine = sc.edge_report(tris, slots)[""]
        self.assertEqual(mine["edges"], edges)
        self.assertAlmostEqual(mine["hard"], hard, delta=max(2, hard // 100))   # Blender also counts the edges of zero-area triangles


if __name__ == "__main__":
    unittest.main()
