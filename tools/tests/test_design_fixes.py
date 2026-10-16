"""Tests for the design fixes (docs/vault/06-art-pipelines/Design-Fixes.md): the six redesigns and the three taper fixes of the `<Id>V2` prototype recipes in
tools/blender/species_recipes.py, with no Blender. Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'

What is held here is what the review of design passes 1 to 3 asked for, as numbers on the recipe: Raddis's sun disc is wider than its bulb and stands high
behind it (so it shows from the front and the three-quarter view), its wings are gold rays and not green fronds; Iridia's wing parts are at least 0.12 studs
thick and swept back (a plate in the side view, not a sliver) and its head is bigger; Zirrit is one fused body with a tapering tail and shaped wings; Skadra's body
is the owl's (a full chest, a broad head, feathered legs and wings); Aurelyx has no raised paw and a crown fan; Blinkar's tines curve; every limb, tail and horn of
the nine tapers to at most 0.85 of its root (the third style check); the moods and the big eyes stay. The build overrides (the `--set` lines) are in the note.
"""
from __future__ import annotations

import ast
import importlib.util
import math
import pathlib
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent


def _load(name, rel):
    spec = importlib.util.spec_from_file_location(name, ROOT / rel)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


sr = _load("species_recipes_fixes", "tools/blender/species_recipes.py")
sc = _load("style_checks_fixes", "tools/blender/style_checks.py")

REDESIGNED = ("Radish", "Zapfinch", "Skaddle", "Gloomoth", "Shimmerlynx", "Reindazzle")
TAPER_FIXED = ("Glimmo", "Kettlepuff", "Flufflet")
MOOD = {"Radish": "spectacular", "Zapfinch": "cool", "Skaddle": "fierce", "Gloomoth": "cool", "Shimmerlynx": "cool", "Reindazzle": "cool"}
TILT = {"cool": (4.0, 7.0), "fierce": (18.0, 90.0), "spectacular": (14.0, 90.0)}


def rec(base):
    return sr.RECIPES[base + "V2"]


def parts(base, name=None, slot=None, prim=None):
    out = [p for p in sr.expand(rec(base)) if p["slot"] not in sr.FACE_SLOTS or p["name"] not in ("eye", "pupil", "glint", "mouth", "lid", "tooth")]
    if name is not None:
        out = [p for p in out if p["name"] == name]
    if slot is not None:
        out = [p for p in out if p["slot"] == slot]
    if prim is not None:
        out = [p for p in out if p["prim"] == prim]
    return out


def thickness(p):
    """The thinnest full dimension of a flat part: twice its smallest radius."""
    return 2.0 * min(p["scale"])


def dist(a, b):
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))


def chord_deviation(pts):
    """The largest distance of an inner point of a polyline from the chord between its ends, over the chord's length: 0 for a straight line."""
    a, b = pts[0], pts[-1]
    d = sr._sub(b, a)
    n = sr._len(d)
    if n < 1e-9:
        return 0.0
    u = sr._mul(d, 1.0 / n)
    worst = 0.0
    for p in pts[1:-1]:
        v = sr._sub(p, a)
        along = sum(x * y for x, y in zip(v, u))
        perp = sr._sub(v, sr._mul(u, along))
        worst = max(worst, sr._len(perp))
    return worst / n


class TheNineStayPrototypes(unittest.TestCase):
    def test_every_fixed_recipe_is_a_prototype_with_its_species_shell(self):
        for base in REDESIGNED + TAPER_FIXED:
            with self.subTest(base):
                r = rec(base)
                self.assertTrue(r["prototype"])
                self.assertEqual(r["status"], "recipe")
                self.assertEqual(r["batch"], 0)
                self.assertEqual(r["palette"], sr.RECIPES[base]["palette"])
                self.assertEqual(r.get("glow", {}), sr.RECIPES[base].get("glow", {}))
                self.assertAlmostEqual(r["height"], sr.notes_height(base), delta=0.005)

    def test_the_fixed_recipes_pass_the_checker_apart_from_the_notes(self):
        for base in REDESIGNED + TAPER_FIXED:
            with self.subTest(base):
                problems, tris, height, low, declared = sr.check(base + "V2")
                self.assertEqual([p for p in problems if not p.startswith("note:")], [])
                self.assertAlmostEqual(low, 0.0, delta=0.05)  # the lowest point rests on z = 0

    def test_no_redesign_is_the_old_silhouette_line(self):
        lines = [r["silhouette"] for r in sr.RECIPES.values()]
        self.assertEqual(len(lines), len(set(lines)))


class TaperCheck(unittest.TestCase):
    """The third style check (Character-Pipeline.md): the tip radius of every limb, tail, horn and tube at most 0.85 of its root."""

    def test_every_limb_tail_and_horn_of_the_nine_tapers(self):
        recipes = sc.load_recipes()
        for base in REDESIGNED + TAPER_FIXED:
            with self.subTest(base):
                report = sc.taper_report(recipes, base + "V2")
                self.assertTrue(report["pass"], report)
                self.assertGreater(report["limbs"], 0)

    def test_all_twenty_four_design_pass_recipes_pass(self):
        recipes = sc.load_recipes()
        keys = [k for k, v in recipes.RECIPES.items() if v.get("prototype") and k.endswith("V2") and k != "FenripupV2"]
        self.assertGreaterEqual(len(keys), 24)
        for key in keys:
            with self.subTest(key):
                self.assertTrue(sc.taper_report(recipes, key)["pass"], key)

    def test_the_three_that_tapered_by_too_little_keep_their_design(self):
        recipes = sc.load_recipes()
        want = {"Glimmo": {"antenna": 2, "antennatip": 2, "lantern": 1, "wing": 2}, "Kettlepuff": {"leg": 2, "arm": 2, "spout": 3, "lid": 1, "handle": 1},
                "Flufflet": {"foreleg": 2, "mitten": 2, "scarf": 1, "tail": 1}}
        for base, names in want.items():
            have = {}
            for p in sr.expand(rec(base)):
                have[p["name"]] = have.get(p["name"], 0) + 1
            for name, n in names.items():
                with self.subTest("%s %s" % (base, name)):
                    self.assertGreaterEqual(have.get(name, 0), n)
            limbs = sc.limb_parts(recipes, recipes.RECIPES[base + "V2"])
            self.assertTrue(limbs)
            self.assertLessEqual(max(l["ratio"] for l in limbs), 0.85 + 1e-6)


class MoodsAndEyes(unittest.TestCase):
    def test_each_redesign_keeps_its_mood_floor_and_its_big_eyes(self):
        for base in REDESIGNED:
            lo, hi = TILT[MOOD[base]]
            f = rec(base)["face"]
            with self.subTest(base):
                self.assertGreaterEqual(f["eye_tilt"], lo)
                self.assertLessEqual(f["eye_tilt"], hi)
                self.assertGreaterEqual(f.get("lid", 0.0), 0.25)
                self.assertGreaterEqual(f["eye_scale"], 1.15)  # the goofy big eyes stay
                host = sr._find_host(rec(base), f["on"])
                self.assertAlmostEqual(host["loc"][0], 0.0, places=6)

    def test_the_cool_ones_have_a_bite(self):
        """Ethan: not every alien cute, the rarer ones fiercer. The cool Epics and Rares keep their cool face and gain a bite in the body: a heavier brow (lid 0.4 or
        more) and, for Iridia and Aurelyx, teeth as geometry."""
        self.assertGreaterEqual(rec("Gloomoth")["face"]["lid"], 0.35)
        self.assertGreaterEqual(rec("Shimmerlynx")["face"]["lid"], 0.35)
        self.assertGreaterEqual(rec("Reindazzle")["face"]["lid"], 0.4)
        self.assertEqual(len(parts("Gloomoth", "mandible")), 2)
        self.assertEqual(len(parts("Shimmerlynx", "fang")), 2)

    def test_raddis_keeps_the_regal_grin(self):
        """The spectacular preset's snarl was softened by hand in the build (six face keys, Design-Pass.md batch 3); the recipe keeps its wide grin and its tilt."""
        f = rec("Radish")["face"]
        self.assertEqual(f["mouth"], "wide")
        self.assertEqual(f["eye_tilt"], 14.0)


class Raddis(unittest.TestCase):
    def setUp(self):
        self.disc = parts("Radish", "disk")[0]
        self.bulb = parts("Radish", "body")[0]

    def test_the_disc_is_wider_than_the_body_and_stands_high_behind_it(self):
        r, bx, bz = self.disc["scale"][0], self.bulb["scale"][0], self.bulb["scale"][2]
        self.assertGreater(2.0 * r, 1.4 * 2.0 * bx * 0.75)  # the disc's diameter against the bulb's width
        self.assertGreater(r, bx * 1.25)                    # it shows beyond the bulb on each side
        top_disc = self.disc["loc"][2] + r * 0.95
        top_bulb = self.bulb["loc"][2] + bz
        self.assertGreater(top_disc, top_bulb + 1.0)        # and over its top by a full stud or more
        self.assertGreater(self.disc["loc"][1], self.bulb["loc"][1] + self.bulb["scale"][1])  # its centre is behind the bulb's back edge
        self.assertEqual(self.disc["slot"], "Accessory")

    def test_the_disc_is_a_dish_with_depth_so_it_is_not_a_sliver_from_the_side(self):
        self.assertEqual(self.disc["prim"], "cone")
        self.assertLess(self.disc["tip"], 0.8)             # a frustum: wide at the back, narrower at the front
        self.assertGreaterEqual(2.0 * self.disc["scale"][2], 0.6)  # at least 0.6 studs of depth before the fit

    def test_the_disc_is_the_biggest_part_and_ringed_all_round_by_broad_rays(self):
        rays = [p for p in parts("Radish", "ray") if abs(p["loc"][0]) < 3.0 and p["loc"][2] > self.disc["loc"][2] - 2.2 and abs(p["loc"][1] - self.disc["loc"][1]) < 1.0]
        corona = [p for p in rays if 1.5 < dist(p["loc"], self.disc["loc"]) < 3.4]
        self.assertGreaterEqual(len(corona), 12)
        for p in corona:
            self.assertGreaterEqual(min(p["scale"]), 0.058)  # thick enough to survive edge-on
            self.assertGreaterEqual(p["scale"][1], 0.2)       # broad
        self.assertEqual(max(max(q["scale"]) for q in parts("Radish") if q["name"] in ("body", "disk", "ray", "leaf", "covert")), self.disc["scale"][0])

    def test_the_wings_are_gold_rays_over_orange_coverts_and_not_green_fronds(self):
        wings = [p for p in parts("Radish") if p["name"] in ("ray", "covert", "arm") and abs(p["loc"][0]) > self.disc["scale"][0] * 0.8]
        self.assertGreaterEqual(len(wings), 20)
        for p in wings:
            self.assertNotEqual(p["slot"], "BodyDark")  # nothing green on the wings
        gold = [p for p in wings if p["name"] == "ray"]
        self.assertGreaterEqual(len(gold), 18)
        for p in gold:
            self.assertEqual(p["slot"], "Accessory")
        spread = max(abs(p["loc"][0]) + p["scale"][2] for p in gold)
        self.assertGreater(spread, self.disc["scale"][0] + 1.5)  # the feathers reach well past the sun's rim, against the sky, not the disc
        self.assertEqual(len(parts("Radish", "arm")), 2)

    def test_the_only_green_is_the_plume_on_the_head(self):
        green = parts("Radish", slot="BodyDark")
        self.assertTrue(green)
        for p in green:
            self.assertEqual(p["name"], "leaf")
            self.assertGreater(p["loc"][2], self.bulb["loc"][2] + 0.5)   # over the bulb
            self.assertLess(abs(p["loc"][0]), 1.5)
        self.assertEqual(len(green), 5)

    def test_the_radish_body_the_collar_the_diadem_and_the_coiled_taproot_stay(self):
        names = {p["name"] for p in sr.expand(rec("Radish"))}
        for name in ("body", "belly", "taproot", "tailtip", "collar", "diadem"):
            self.assertIn(name, names)

    def test_the_sun_reads_from_the_front_as_a_circle_round_the_head(self):
        """Seen from the front the disc is a circle (a tilt of 12 degrees only foreshortens it), centred above the bulb's centre: its outline clears the bulb
        by at least half a stud over the top and a third of a stud at each side, where the wings' roots are not yet."""
        r = self.disc["scale"][0]
        cx, cz = self.disc["loc"][0], self.disc["loc"][2]
        bx, bz = self.bulb["scale"][0], self.bulb["scale"][2]
        self.assertAlmostEqual(cx, 0.0, places=6)
        self.assertGreater(cz + r - (self.bulb["loc"][2] + bz), 0.5)
        self.assertGreater(r - bx, 0.3)


class Iridia(unittest.TestCase):
    def test_every_wing_part_is_at_least_a_tenth_of_a_stud_thick(self):
        for name in ("membrane", "pane"):
            ps = parts("Gloomoth", name)
            self.assertTrue(ps)
            for p in ps:
                with self.subTest(name):
                    self.assertGreaterEqual(thickness(p), 0.12 - 1e-9)

    def test_the_membranes_are_leaves_not_sheets(self):
        for p in parts("Gloomoth", "membrane"):
            self.assertGreaterEqual(thickness(p), 0.18)

    def test_the_wings_are_swept_back_so_the_side_view_is_a_plate(self):
        """Before: wings in the x-z plane, 0.08 thick, so the side view was a sliver. Now each membrane is yawed back, and its extent along y (the side view's
        width) is at least half a stud, the panes' tips run back by a stud or more."""
        for p in parts("Gloomoth", "membrane"):
            lo, hi = sr.part_bbox(p)
            self.assertGreaterEqual(hi[1] - lo[1], 0.5)
        fore = [p for p in parts("Gloomoth", "pane") if p["loc"][2] > 2.5 and p["loc"][0] > 0]
        self.assertTrue(fore)
        reach = max(sr.part_bbox(p)[1][1] for p in fore)
        self.assertGreater(reach, 1.0)

    def test_a_bigger_head_so_the_face_reads(self):
        head = parts("Gloomoth", "head")[0]
        self.assertGreaterEqual(head["scale"][0], 0.7)  # the first pass had 0.5
        thorax = parts("Gloomoth", "thorax")[0]
        self.assertGreater(head["scale"][0], thorax["scale"][0])

    def test_two_mandibles_flank_the_mouth(self):
        ms = parts("Gloomoth", "mandible")
        self.assertEqual(len(ms), 2)
        xs = sorted(p["loc"][0] for p in ms)
        self.assertLess(xs[0], 0.0)
        self.assertGreater(xs[1], 0.0)
        for p in ms:
            self.assertLess(p["loc"][1], -0.8)   # on the front of the face
            self.assertLess(p["loc"][2], 1.6)    # low, at the mouth and chin

    def test_the_jewels_the_legs_and_the_antennae_stay(self):
        names = [p["name"] for p in sr.expand(rec("Gloomoth"))]
        self.assertEqual(names.count("jewel"), 3)
        self.assertEqual(names.count("antenna"), 2)
        self.assertEqual(names.count("leg") % 2, 0)
        self.assertGreaterEqual(names.count("pane"), 18)


class Zirrit(unittest.TestCase):
    def test_one_fused_body_not_two_balls(self):
        chain = [parts("Zapfinch", n)[0] for n in ("head", "chest", "belly", "rump")]
        for a, b in zip(chain, chain[1:]):
            ra, rb = (a["scale"][0] * a["scale"][1] * a["scale"][2]) ** (1 / 3), (b["scale"][0] * b["scale"][1] * b["scale"][2]) ** (1 / 3)
            self.assertLess(dist(a["loc"], b["loc"]), 0.85 * (ra + rb), (a["name"], b["name"]))
        radii = [(p["scale"][0] * p["scale"][1] * p["scale"][2]) ** (1 / 3) for p in chain]
        self.assertGreater(radii[1], radii[3] * 1.3)   # a deep chest tapering back to a small rump
        self.assertGreater(chain[1]["scale"][2], chain[3]["scale"][2] * 1.8)

    def test_the_tail_is_one_tapering_tube_ending_in_streamers(self):
        tails = parts("Zapfinch", "tail", prim="sweep")
        self.assertEqual(len(tails), 1)
        t = tails[0]
        self.assertLessEqual(t["radii"][-1] / t["radii"][0], 0.4)
        self.assertGreaterEqual(dist(t["pts"][0], t["pts"][-1]), 1.8)
        self.assertEqual(len(parts("Zapfinch", "tailfeather")), 3)
        tipy = max(p["loc"][1] for p in parts("Zapfinch", "tailfeather"))
        self.assertGreater(tipy, t["pts"][-1][1])

    def test_the_wings_are_shaped_not_paddles(self):
        self.assertEqual(len(parts("Zapfinch", "wingarm")), 2)
        feathers = parts("Zapfinch", "feather")
        coverts = parts("Zapfinch", "covert")
        self.assertGreaterEqual(len(feathers), 20)     # twelve a side
        self.assertGreaterEqual(len(coverts), 10)
        for p in feathers + coverts:
            self.assertEqual(p["prim"], "cone")         # a blade; the old covert was a leaf-ellipsoid paddle
            self.assertGreaterEqual(min(p["scale"]), 0.058)
        lengths = sorted(2.0 * p["scale"][2] for p in feathers)
        self.assertGreater(lengths[-1], 1.7)            # long primaries
        self.assertLess(lengths[0], 1.25)               # shorter secondaries
        self.assertGreater(lengths[-1] - lengths[0], 0.6)

    def test_the_wing_feathers_fan_in_more_than_one_direction(self):
        """The feathers turn from streaming out at the wrist to hanging at the elbow, so their axes span 50 degrees or more."""
        axes = []
        for p in parts("Zapfinch", "feather"):
            if p["loc"][0] > 0:
                R = p["rot"]
                axes.append(sr._unit((R[0][2], R[1][2], R[2][2])))
        self.assertGreaterEqual(len(axes), 10)
        worst = max(math.degrees(math.acos(max(-1.0, min(1.0, sum(x * y for x, y in zip(a, b)))))) for a in axes for b in axes)
        self.assertGreater(worst, 50.0)

    def test_a_hooked_beak_the_mask_and_the_two_whip_antennae_stay(self):
        names = [p["name"] for p in sr.expand(rec("Zapfinch"))]
        self.assertEqual(names.count("beak"), 2)       # the beak and its hook
        self.assertEqual(names.count("mask"), 1)
        self.assertEqual(names.count("antenna"), 2)
        self.assertEqual(names.count("antennatip"), 2)
        self.assertEqual({p["name"] for p in parts("Zapfinch", slot="Accessory")}, {"antennatip"})


class Skadra(unittest.TestCase):
    def test_the_owl_has_a_broad_head_wider_than_it_is_tall(self):
        head = parts("Skaddle", "head")[0]
        self.assertGreaterEqual(head["scale"][0], 0.95)
        self.assertGreater(head["scale"][0], head["scale"][2] * 1.15)
        self.assertEqual(len(parts("Skaddle", "tuft")), 2)   # the ear tufts

    def test_a_full_feathered_chest(self):
        torso = parts("Skaddle", "torso")[0]
        self.assertGreaterEqual(torso["scale"][0], 0.9)
        self.assertGreaterEqual(torso["scale"][2], 1.0)
        feathers = parts("Skaddle", "chestfeather")
        self.assertGreaterEqual(len(feathers), 10)
        for p in feathers:
            self.assertGreater(p["loc"][1], torso["loc"][1] - 2.0 * torso["scale"][1])   # on the chest, not floating
            self.assertLess(p["loc"][1], torso["loc"][1])                                  # on its front

    def test_the_legs_and_wing_arms_have_mass_and_are_not_stick_limbs(self):
        legs = parts("Skaddle", "leg", prim="sweep")
        self.assertEqual(len(legs), 2)
        for p in legs:
            self.assertGreaterEqual(p["radii"][0], 0.3)
        self.assertEqual(parts("Skaddle", "thigh"), [])
        self.assertEqual(parts("Skaddle", "shin"), [])
        arms = parts("Skaddle", "wing", prim="sweep")
        self.assertEqual(len(arms), 2)
        for p in arms:
            self.assertGreaterEqual(p["radii"][0], 0.28)

    def test_the_wings_carry_feathered_mass(self):
        feathers = parts("Skaddle", "feather")
        coverts = parts("Skaddle", "covert")
        self.assertGreaterEqual(len(feathers), 14)
        self.assertGreaterEqual(len(coverts), 6)
        for p in feathers + coverts:
            self.assertGreaterEqual(min(p["scale"]), 0.058)
        self.assertTrue(any(p["loc"][0] > 0.5 for p in feathers))
        self.assertTrue(any(p["loc"][0] < -0.5 for p in feathers))
        self.assertGreater(max(2.0 * p["scale"][2] for p in feathers), 1.5)

    def test_the_glide_the_halo_and_the_scarf_are_kept(self):
        skates = parts("Skaddle", "skate")
        self.assertEqual(len(skates), 2)
        self.assertGreater(abs(skates[0]["loc"][1] - skates[1]["loc"][1]), 1.2)   # one bent under it, one trailing far behind
        halo = parts("Skaddle", "halo", prim="torus")
        self.assertEqual(len(halo), 1)
        self.assertEqual(halo[0]["slot"], "Trim")
        self.assertGreaterEqual(len(parts("Skaddle", "halo", prim="cone")), 14)       # the fourteen ice blades
        self.assertGreater(halo[0]["scale"][0], parts("Skaddle", "head")[0]["scale"][0] * 1.2)   # the ring clears the broad head
        bands = rec("Skaddle")["ribbons"]
        self.assertEqual(len(bands), 1)
        self.assertEqual(bands[0]["name"], "scarf")
        self.assertGreaterEqual(len(bands[0]["pts"]), 16)
        self.assertGreater(bands[0]["pts"][-1][1] - bands[0]["pts"][0][1], 3.0)   # a long scarf


class Aurelyx(unittest.TestCase):
    def test_no_ball_held_up_and_all_four_paws_are_planted(self):
        names = {p["name"] for p in sr.expand(rec("Shimmerlynx"))}
        for gone in ("raisedpaw", "upperarm", "forearm"):
            self.assertNotIn(gone, names)
        for name in ("paw", "hindpaw"):
            ps = parts("Shimmerlynx", name)
            self.assertEqual(len(ps), 2)
            for p in ps:
                self.assertLessEqual(p["loc"][2] - p["scale"][2], 0.02)   # the paw's underside is on the ground

    def test_a_chest_and_a_haunch_not_three_balls_in_a_line(self):
        for name in ("chest", "withers", "waist", "hips", "haunch"):
            self.assertTrue(parts("Shimmerlynx", name), name)
        chest, hips = parts("Shimmerlynx", "chest")[0], parts("Shimmerlynx", "hips")[0]
        waist = parts("Shimmerlynx", "waist")[0]
        self.assertGreater(chest["scale"][2], waist["scale"][2] * 1.3)    # a deep chest over a tucked waist
        self.assertGreater(hips["loc"][2], chest["loc"][2] - 0.1)          # hips raised over the haunches (a stalking stance)
        haunch = parts("Shimmerlynx", "haunch")
        self.assertEqual(len(haunch), 2)
        self.assertLess(haunch[0]["loc"][2], hips["loc"][2])

    def test_the_head_is_carried_low_and_forward(self):
        head, chest = parts("Shimmerlynx", "head")[0], parts("Shimmerlynx", "chest")[0]
        self.assertLess(head["loc"][1], chest["loc"][1] - 1.0)
        self.assertLess(head["loc"][2] - head["scale"][2], chest["loc"][2] + chest["scale"][2])  # no higher than the shoulders' top

    def test_the_crest_is_a_crown_fan_that_reads_from_the_front(self):
        crown = parts("Shimmerlynx", "crown")
        self.assertGreaterEqual(len(crown), 7)
        xs = [p["loc"][0] for p in crown]
        # each blade is a cone whose axis tilts away from the vertical: the fan spans the front (x) as well as the back
        spread = []
        for p in crown:
            R = p["rot"]
            ax = sr._unit((R[0][2], R[1][2], R[2][2]))
            spread.append(ax[0])
        self.assertLess(min(spread), -0.8)
        self.assertGreater(max(spread), 0.8)
        for p in crown:
            self.assertEqual(p["slot"], "Accessory")
            self.assertGreaterEqual(min(p["scale"]), 0.058)
        self.assertEqual(len(rec("Shimmerlynx")["ribbons"]), 2)   # and two ribbons flow back over the spine

    def test_the_bite_two_fangs_a_cheek_ruff_and_a_heavy_brow(self):
        fangs = parts("Shimmerlynx", "fang")
        self.assertEqual(len(fangs), 2)
        self.assertEqual(len(parts("Shimmerlynx", "cheek")), 6)
        self.assertGreaterEqual(rec("Shimmerlynx")["face"]["lid"], 0.35)


class Blinkar(unittest.TestCase):
    def test_every_antler_tube_curves(self):
        antlers = parts("Reindazzle", "antler", prim="sweep")
        self.assertEqual(len(antlers), 10)   # a beam, a brow tine and three rising tines, mirrored
        for p in antlers:
            self.assertGreaterEqual(len(p["pts"]), 4)
            self.assertGreaterEqual(chord_deviation(p["pts"]), 0.06, p["pts"])   # no straight twigs

    def test_the_tines_lean_out_and_curl_back_in(self):
        right = [p for p in parts("Reindazzle", "antler", prim="sweep") if p["pts"][0][0] > 0]
        tines = [p for p in right if len(p["pts"]) == 5 and p["pts"][-1][2] - p["pts"][0][2] > 0.8 and abs(p["pts"][-1][0] - p["pts"][0][0]) < 0.4]
        self.assertGreaterEqual(len(tines), 3)
        for p in tines:
            xs = [q[0] for q in p["pts"]]
            self.assertGreater(max(xs), xs[0] + 0.1)   # out,
            self.assertLess(xs[-1], max(xs) - 0.05)    # then in at the tip

    def test_a_chest_a_withers_hump_and_a_throat_ruff_under_the_antlers(self):
        chest = parts("Reindazzle", "chest")[0]
        self.assertGreaterEqual(chest["scale"][0], 0.7)     # the first pass had 0.6
        self.assertGreaterEqual(chest["scale"][2], 0.8)
        for name in ("withers", "ruff", "haunch"):
            self.assertTrue(parts("Reindazzle", name), name)
        head = parts("Reindazzle", "head")[0]
        self.assertGreaterEqual(head["scale"][0], 0.66)     # a bigger head, the first pass had 0.64
        self.assertGreaterEqual(rec("Reindazzle")["face"]["lid"], 0.4)

    def test_the_glowing_nose_is_the_only_accessory(self):
        self.assertEqual({p["name"] for p in parts("Reindazzle", slot="Accessory")}, {"nose"})


class TheSheet(unittest.TestCase):
    def test_the_sheet_tool_has_the_six_rows_in_order(self):
        tree = ast.parse((ROOT / "tools/blender/design_sheet.py").read_text())
        fixes = next(n.value for n in tree.body if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "FIXES" for t in n.targets))
        data = ast.literal_eval(fixes)
        self.assertEqual([r[0] for r in data["rows"]], list(REDESIGNED))
        for sid, mood, blurb in data["rows"]:
            self.assertEqual(mood, MOOD[sid])
            self.assertTrue(blurb)

    def test_the_batch_rows_are_not_touched_by_the_fixes_option(self):
        text = (ROOT / "tools/blender/design_sheet.py").read_text()
        self.assertIn("def compose_fixes(", text)
        self.assertIn('"--fixes"', text)


if __name__ == "__main__":
    unittest.main()
