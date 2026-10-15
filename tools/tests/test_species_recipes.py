"""Tests for tools/blender/species_recipes.py (the silhouette recipes), with no Blender.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). The recipes are checked against the repo's own assets/models/<Id>/notes.md and materials.json,
so a changed height, a renamed slot or an over-budget recipe fails here before the Mac builds it.
"""
from __future__ import annotations

import importlib.util
import math
import pathlib
import re
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
_SPEC = importlib.util.spec_from_file_location("species_recipes", ROOT / "tools/blender/species_recipes.py")
sr = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(sr)  # type: ignore[union-attr]


def species_ids():
    text = (ROOT / "src/shared/data/Species.luau").read_text()
    return re.findall(r'\{ id = "(\w+)"', text)


def shipped():
    """The recipes of real species. The prototypes (`"prototype": True`: the heroes FenripupV2 and Skydrake, and the eight `<Id>V2` design-pass
    recipes) have no Species.luau row and no assets/models folder of their own, so the tests that compare recipes with those files skip them, the
    way the event species are skipped by status; HeroPrototypes and DesignPassPrototypes below check them on their own terms."""
    return {k: v for k, v in sr.RECIPES.items() if not v.get("prototype")}


class RecipeCoverage(unittest.TestCase):
    def test_every_species_has_an_entry_and_every_entry_is_a_species(self):
        self.assertEqual(sorted(species_ids()), sorted(shipped()))

    def test_every_entry_has_its_silhouette_hero_and_height(self):
        for sid, rec in sr.RECIPES.items():
            with self.subTest(sid):
                self.assertTrue(rec["silhouette"].strip())
                self.assertTrue(rec["hero"].strip())
                self.assertGreater(rec["height"], 1.0)
                self.assertIn(rec["status"], ("recipe", "TODO"))

    def test_the_sixteen_world_one_and_sixteen_frostbyte_recipes_are_full_and_the_rest_are_stubs(self):
        full = [k for k, v in shipped().items() if v["status"] == "recipe"]
        self.assertEqual(len(full), 32)
        for sid in full:
            world, batch = sr.RECIPES[sid]["world"], sr.RECIPES[sid]["batch"]
            self.assertIn(world, (1, 2))
            self.assertIn(batch, (1, 2, 3, 4, 5) if world == 1 else (6, 7, 8, 9), sid)
        self.assertEqual(sum(1 for k in full if sr.RECIPES[k]["world"] == 1), 16)
        self.assertEqual(sum(1 for k in full if sr.RECIPES[k]["world"] == 2), 16)
        stubs = [k for k, v in shipped().items() if v["status"] == "TODO"]
        self.assertEqual(sorted(stubs), ["Nebulyn", "Spookum", "Wisplet"])  # the Haunted Nebula species keep their event bodies
        for sid in stubs:
            self.assertEqual(sr.RECIPES[sid]["steps"], [])
            self.assertIn("TODO", sr.RECIPES[sid]["todo"])

    def test_batches_are_three_or_four_species(self):
        counts = {}
        for rec in shipped().values():
            if rec["status"] == "recipe":
                counts[rec["batch"]] = counts.get(rec["batch"], 0) + 1
        self.assertEqual(sorted(counts), [1, 2, 3, 4, 5, 6, 7, 8, 9])
        self.assertTrue(all(3 <= n <= 4 for n in counts.values()), counts)

    def test_world_and_batch_ids_pick_the_right_species(self):
        self.assertEqual(len(sr.ids_for("world1")), 16)
        self.assertEqual(len(sr.ids_for("world2")), 16)
        self.assertEqual(sr.ids_for("batch6"), ["Flufflet", "Snowbun", "Drippo", "Kettlepuff"])
        self.assertEqual(set(sr.ids_for("world1")) & set(sr.ids_for("world2")), set())
        self.assertEqual(len(sr.ids_for("all")), 32)

    def test_every_frostbyte_species_has_a_full_recipe_at_its_notes_height(self):
        text = (ROOT / "src/shared/data/Species.luau").read_text()
        world2 = re.findall(r'\{ id = "(\w+)"[^\n]*world = 2', text)
        self.assertEqual(sorted(world2), sorted(k for k, v in shipped().items() if v["world"] == 2))
        for sid in world2:
            with self.subTest(sid):
                self.assertEqual(sr.RECIPES[sid]["status"], "recipe")
                self.assertAlmostEqual(sr.RECIPES[sid]["height"], sr.notes_height(sid), delta=0.005)

    def test_the_frostbyte_silhouette_lines_are_all_different(self):
        lines = [v["silhouette"] for v in sr.RECIPES.values() if v["world"] == 2]
        self.assertEqual(len(lines), len(set(lines)))


class RecipeChecks(unittest.TestCase):
    def test_every_full_recipe_passes_the_checker(self):
        for sid, rec in shipped().items():
            if rec["status"] != "recipe":
                continue
            with self.subTest(sid):
                problems, tris, height, low, declared = sr.check(sid)
                hard = [p for p in problems if not p.startswith("note:")]
                self.assertEqual(hard, [])
                self.assertLessEqual(tris, sr.TRI_BUDGET)
                self.assertAlmostEqual(low, 0.0, delta=0.05)
                self.assertAlmostEqual(height, declared, delta=0.03 * declared)

    def test_every_full_recipe_uses_every_slot_of_its_materials_json(self):
        for sid, rec in shipped().items():
            if rec["status"] != "recipe":
                continue
            with self.subTest(sid):
                slots = sr.material_slots(sid)
                used = sr.slots_used(sr.expand(rec))
                self.assertEqual(set(slots), used)

    def test_recipe_heights_equal_the_notes_heights(self):
        for sid, rec in sr.RECIPES.items():
            nh = sr.notes_height(sid)
            if nh is not None and not rec.get("height_note"):
                with self.subTest(sid):
                    self.assertAlmostEqual(rec["height"], nh, delta=0.005)

    def test_palette_glow_and_metal_name_real_slots(self):
        for sid, rec in shipped().items():
            if rec["status"] != "recipe":
                continue
            slots = sr.material_slots(sid)
            for key in ("palette", "glow", "metal"):
                for slot in rec.get(key, {}):
                    with self.subTest("%s %s %s" % (sid, key, slot)):
                        self.assertIn(slot, slots)

    def test_exactly_one_glowing_slot_and_it_is_the_accessory(self):
        for sid, rec in shipped().items():
            if rec["status"] == "recipe" and rec.get("glow"):
                with self.subTest(sid):
                    self.assertEqual(list(rec["glow"]), ["Accessory"])


class HeroPrototypes(unittest.TestCase):
    """FenripupV2 and Skydrake (docs/vault/06-art-pipelines/Hero-Aliens.md): recipes for `species_sculpt.py --method hybrid` on a scratch
    models folder. They carry the Trim slot (eight slots, the Epic and Legendary shape) and a `sweep` body or tail."""
    SLOTS = {"Body", "EyeWhite", "Pupil", "Mouth", "BodyDark", "Accessory", "Trim", "EyeHighlight"}

    def heroes(self):
        return {k: v for k, v in sr.RECIPES.items() if v.get("prototype") and k in ("FenripupV2", "Skydrake")}

    def test_the_two_heroes_exist_and_are_prototypes(self):
        self.assertEqual(sorted(self.heroes()), ["FenripupV2", "Skydrake"])
        for sid, rec in self.heroes().items():
            self.assertEqual(rec["status"], "recipe", sid)
            self.assertTrue(rec["silhouette"].strip() and rec["hero"].strip(), sid)

    def test_group_ids_skip_them_but_a_name_picks_them(self):
        for token in ("all", "world1", "world2", "batch0"):
            self.assertFalse({"FenripupV2", "Skydrake"} & set(sr.ids_for(token)), token)
        self.assertEqual(sr.ids_for("FenripupV2,Skydrake"), ["FenripupV2", "Skydrake"])

    def test_they_pass_the_checker_apart_from_the_notes(self):
        for sid in self.heroes():
            with self.subTest(sid):
                problems, tris, height, low, declared = sr.check(sid)
                self.assertEqual([p for p in problems if not p.startswith("note:")], [])
                self.assertAlmostEqual(low, 0.0, delta=0.05)
                self.assertAlmostEqual(height, declared, delta=0.03 * declared)

    def test_every_slot_is_one_of_the_eight_and_every_one_is_used(self):
        for sid, rec in self.heroes().items():
            with self.subTest(sid):
                used = sr.slots_used(sr.expand(rec))
                self.assertEqual(used, self.SLOTS)
                for key in ("palette", "glow", "metal"):
                    self.assertLessEqual(set(rec.get(key, {})), self.SLOTS)
                self.assertEqual(list(rec.get("glow", {})), ["Accessory"])

    def test_the_sweep_step_carries_its_points_and_a_radius_for_each(self):
        for sid, rec in self.heroes().items():
            sweeps = [p for p in sr.expand(rec) if p["prim"] == "sweep"]
            self.assertTrue(sweeps, sid)
            for p in sweeps:
                self.assertEqual(len(p["pts"]), len(p["radii"]))
                self.assertIn(p["slot"], ("Body", "BodyDark"), "a sweep is core only: an Accessory or Trim sweep would be taken for a crisp part")
        with self.assertRaises(ValueError):
            sr.sweep("Body", [(0, 0, 0), (0, 1, 0)], [0.2])

    def test_the_catmull_rom_helper_passes_through_its_control_points(self):
        pts = [(0.0, 0.0, 0.0), (1.0, 0.5, 0.2), (2.0, 0.0, 0.9), (2.5, 1.0, 1.5)]
        for i, q in enumerate(pts):
            pos, tan = sr.crom(pts, i / (len(pts) - 1))
            for k in range(3):
                self.assertAlmostEqual(pos[k], q[k], places=9)
            self.assertAlmostEqual(math.sqrt(sum(v * v for v in tan)), 1.0, places=9)


class DesignPassPrototypes(unittest.TestCase):
    """The eight `<Id>V2` recipes of the first design pass (docs/vault/06-art-pipelines/Design-Pass.md): a new base design for a species whose shape
    barely changed, built by `species_sculpt.py --method hybrid` on a scratch copy of its folder renamed `<Id>V2`. Each keeps its species' tier,
    world, height, slots, palette and glow, so a later swap into assets/models changes the shape and nothing else."""
    BATCH = ("Mossbop", "Glimmo", "Puffpuff", "Drippo", "Kettlepuff", "Flufflet", "Capybubble", "Pengoo")

    def v2(self):
        return {b: sr.RECIPES[b + "V2"] for b in self.BATCH}

    def test_the_eight_exist_and_are_prototypes_of_real_species(self):
        ids = set(species_ids())
        for base, rec in self.v2().items():
            with self.subTest(base):
                self.assertIn(base, ids)
                self.assertTrue(rec["prototype"])
                self.assertEqual(rec["status"], "recipe")
                self.assertEqual(rec["batch"], 0)
                for key in ("tier", "world", "biome"):
                    self.assertEqual(rec[key], sr.RECIPES[base][key])
        self.assertEqual(sorted(k for k, v in sr.RECIPES.items() if v.get("prototype")), sorted(["FenripupV2", "Skydrake"] + [b + "V2" for b in self.BATCH]))

    def test_each_keeps_the_notes_height_of_its_species(self):
        for base, rec in self.v2().items():
            with self.subTest(base):
                self.assertAlmostEqual(rec["height"], sr.notes_height(base), delta=0.005)

    def test_group_ids_skip_them_but_a_name_picks_them(self):
        names = [b + "V2" for b in self.BATCH]
        for token in ("all", "world1", "world2", "batch0", "batch1", "batch6", "batch7", "batch8"):
            self.assertFalse(set(names) & set(sr.ids_for(token)), token)
        self.assertEqual(sr.ids_for(",".join(names)), names)

    def test_they_pass_the_checker_apart_from_the_notes(self):
        for base in self.BATCH:
            with self.subTest(base):
                problems, tris, height, low, declared = sr.check(base + "V2")
                self.assertEqual([p for p in problems if not p.startswith("note:")], [])
                self.assertAlmostEqual(low, 0.0, delta=0.05)  # the lowest point rests on the ground: the builder fits it to z = 0

    def test_every_slot_of_the_species_materials_json_is_used_and_no_other(self):
        for base, rec in self.v2().items():
            with self.subTest(base):
                self.assertEqual(sr.slots_used(sr.expand(rec)), set(sr.material_slots(base)))

    def test_palette_glow_and_metal_are_the_shipped_recipes(self):
        for base, rec in self.v2().items():
            for key in ("palette", "glow", "metal"):
                with self.subTest("%s %s" % (base, key)):
                    self.assertEqual(rec.get(key, {}), sr.RECIPES[base].get(key, {}))

    def test_the_silhouette_and_hero_lines_are_new(self):
        for base, rec in self.v2().items():
            with self.subTest(base):
                self.assertNotEqual(rec["silhouette"], sr.RECIPES[base]["silhouette"])
                self.assertNotEqual(rec["hero"], sr.RECIPES[base]["hero"])
        lines = [rec["silhouette"] for rec in sr.RECIPES.values()]
        self.assertEqual(len(lines), len(set(lines)))

    def test_the_face_host_is_a_sphere_step_and_the_mouth_is_open(self):
        for base, rec in self.v2().items():
            with self.subTest(base):
                host = sr._find_host(rec, rec["face"]["on"])
                self.assertAlmostEqual(host["loc"][0], 0.0, places=6)  # the face needs its host on the centre line
                self.assertIn(rec["face"]["mouth"], ("o", "smile", "wide", "zigzag"))
                self.assertGreaterEqual(rec["face"].get("eye_scale", 1.0), 1.0)  # the goofy big eyes stay

    def test_a_sweep_stays_in_a_core_slot_and_ribbons_carry_a_width_per_point(self):
        for base, rec in self.v2().items():
            with self.subTest(base):
                for p in sr.expand(rec):
                    if p["prim"] == "sweep":
                        self.assertIn(p["slot"], ("Body", "BodyDark"))
                        self.assertEqual(len(p["pts"]), len(p["radii"]))
                for band in rec.get("ribbons", []):
                    self.assertEqual(len(band["pts"]), len(band["widths"]))
                    self.assertIn(band["slot"], sr.material_slots(base))

    def test_only_the_accessory_glows(self):
        for base, rec in self.v2().items():
            with self.subTest(base):
                self.assertLessEqual(set(rec.get("glow", {})), {"Accessory"})


class Maths(unittest.TestCase):
    def test_mirror_matrix_matches_the_mirrored_euler(self):
        for rot in ((10, 20, 30), (0, 45, 0), (-30, 15, 70), (90, 0, 25)):
            a = sr.mirror_matrix(sr.euler_matrix(rot))
            b = sr.euler_matrix((rot[0], -rot[1], -rot[2]))
            for i in range(3):
                for j in range(3):
                    self.assertAlmostEqual(a[i][j], b[i][j], places=9)

    def test_aim_turns_the_z_axis_to_the_direction(self):
        for d in ((1, 0, 0), (0, -1, 0), (0.3, 0.4, 0.8), (-0.5, 0.2, -0.6), (0, 0, 1)):
            want = sr._unit(d)
            got = sr.mv(sr.euler_matrix(sr.aim(d)), (0.0, 0.0, 1.0))
            for i in range(3):
                self.assertAlmostEqual(got[i], want[i], places=6)

    def test_front_hit_is_on_the_surface_with_an_outward_normal(self):
        c, s = (0.2, 0.1, 1.0), (1.3, 1.2, 1.0)
        R = sr.euler_matrix((10, 20, 30))
        p, n = sr._hit_front(c, R, s, 0.3, 1.2)
        q = sr.mv(tuple(tuple(R[j][i] for j in range(3)) for i in range(3)), (p[0] - c[0], p[1] - c[1], p[2] - c[2]))
        self.assertAlmostEqual(sum((q[i] / s[i]) ** 2 for i in range(3)), 1.0, places=6)
        self.assertLess(n[1], 0.0)
        self.assertAlmostEqual(math.sqrt(sum(v * v for v in n)), 1.0, places=9)

    def test_triangle_counts_of_the_primitives(self):
        def part(prim, seg, **kw):
            d = {"prim": prim, "segments": seg, "half": None, "tip": 0.0, "mseg": 6}
            d.update(kw)
            return d
        self.assertEqual(sr.part_tris(part("sphere", 12)), 2 * 12 * 5)
        self.assertEqual(sr.part_tris(part("sphere", 12, half="top")), 12 * 5)
        self.assertEqual(sr.part_tris(part("icosphere", 2)), 80)
        self.assertEqual(sr.part_tris(part("cube", 1)), 12)
        self.assertEqual(sr.part_tris(part("cylinder", 8)), 28)
        self.assertEqual(sr.part_tris(part("cone", 6)), 10)
        self.assertEqual(sr.part_tris(part("cone", 6, tip=0.5)), 20)
        self.assertEqual(sr.part_tris(part("torus", 16, mseg=4)), 128)

    def test_a_mirrored_step_is_built_twice_and_a_centred_one_once(self):
        rec = {"steps": [sr.sph("Body", (0, 0, 1), 1.0, name="body"), sr.sph("BodyDark", (0.5, 0, 0.2), 0.2, mirror=True, name="foot"),
                         sr.sph("Accessory", (0, 0, 2), 0.2, mirror=True, name="top")],
               "face": {"on": "body", "mouth": "o"}}
        parts = sr.expand(rec)
        self.assertEqual([p["name"] for p in parts if p["slot"] == "BodyDark"], ["foot", "foot"])
        self.assertEqual(len([p for p in parts if p["slot"] == "Accessory"]), 1)
        xs = sorted(p["loc"][0] for p in parts if p["slot"] == "BodyDark")
        self.assertEqual(xs, [-0.5, 0.5])

    def test_the_face_sits_in_front_of_its_host(self):
        rec = {"steps": [sr.sph("Body", (0, 0, 1), (1.0, 1.0, 1.0), name="body")], "face": {"on": "body", "mouth": "zigzag", "lid": 0.3}}
        parts = sr.expand(rec)
        for p in parts:
            if p["slot"] in sr.FACE_SLOTS:
                self.assertLess(p["loc"][1], 0.2, p["name"])
        self.assertEqual({p["slot"] for p in parts if p["slot"] in sr.FACE_SLOTS}, {"EyeWhite", "Pupil", "Mouth", "EyeHighlight"})


if __name__ == "__main__":
    unittest.main()
