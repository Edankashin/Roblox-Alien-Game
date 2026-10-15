"""Tests for the Surface pass data and tools, with no Blender and no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). The pass is a chain: materials.json (a slot's material, texture, glossy) -> tools/model_assets.py ->
src/shared/data/ModelAssets.Surfaces -> Shared/ModelInstall.SurfacePlan -> Services/Models. These tests keep the two copies of the
material list in step, the generated table fresh, every materials.json row valid, and the baked textures complete and small.
"""
from __future__ import annotations

import importlib.util
import json
import pathlib
import re
import subprocess
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import lint_data  # noqa: E402
from luau_tables import load  # noqa: E402

_SPEC = importlib.util.spec_from_file_location("species_recipes", ROOT / "tools/blender/species_recipes.py")
sr = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(sr)  # type: ignore[union-attr]

TEXTURES = load(str(ROOT / "src/shared/data/Textures.luau"))
MAX_TEXTURE_BYTES = 300_000


def model_folders():
    folders = [d for d in sorted((ROOT / "assets/models").iterdir()) if d.is_dir() and d.name != "props"]
    folders += [d for d in sorted((ROOT / "assets/models/props").iterdir()) if d.is_dir()]
    return [d for d in folders if (d / "materials.json").is_file()]


class MaterialList(unittest.TestCase):
    def test_luau_and_python_lists_match(self):
        source = lint_data.uncomment((ROOT / "src/shared/ModelInstall.luau").read_text())
        block = re.search(r"ModelInstall\.SurfaceMaterials\s*=\s*\{(.*?)\}\s*::", source, re.S)
        self.assertIsNotNone(block, "ModelInstall.SurfaceMaterials not found")
        self.assertEqual(re.findall(r'"(\w+)"', block[1]), list(lint_data.SURFACE_MATERIALS))

    def test_every_listed_name_is_a_roblox_material(self):
        # The names of Enum.Material that the pass may use; a typo here would be a silent fallback at runtime.
        known = {"Plastic", "SmoothPlastic", "Neon", "Metal", "Foil", "Wood", "WoodPlanks", "Fabric", "Leather", "Rubber", "Grass", "Slate",
                 "Rock", "Pebble", "Granite", "Marble", "Sand", "Sandstone", "Snow", "Ice", "Glass", "Mud"}
        self.assertEqual(set(lint_data.SURFACE_MATERIALS), known)
        self.assertEqual(len(set(lint_data.SURFACE_MATERIALS)), len(lint_data.SURFACE_MATERIALS))


class GeneratedTable(unittest.TestCase):
    def test_model_assets_is_fresh(self):
        result = subprocess.run([sys.executable, "-I", "tools/model_assets.py", "--check"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_model_assets_self_test_passes(self):
        result = subprocess.run([sys.executable, "-I", "tools/model_assets.py", "--self-test"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("passed", result.stdout)

    def test_surface_templates_are_fresh(self):
        # The SurfaceAppearance templates Rojo ships (src/shared/SurfaceTemplates/<key>.model.json) are generated from data/Textures.
        result = subprocess.run([sys.executable, "-I", "tools/surface_templates.py", "--check"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_surface_templates_self_test_passes(self):
        result = subprocess.run([sys.executable, "-I", "tools/surface_templates.py", "--self-test"], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("passed", result.stdout)

    def test_data_lint_is_clean(self):
        tables = lint_data.TableReader()
        loaded = {f.stem: tables.read(f) for f in (ROOT / "src/shared/data").glob("*.luau")}
        self.assertEqual(lint_data.lint_surfaces(loaded), [])


class SurfaceTemplates(unittest.TestCase):
    """Services/Models clones ReplicatedStorage.Shared.SurfaceTemplates.<key> (a script cannot create a SurfaceAppearance)."""

    def test_one_template_per_texture_row_carrying_its_ids(self):
        folder = ROOT / "src/shared/SurfaceTemplates"
        self.assertEqual({f.name for f in folder.iterdir()}, {key + ".model.json" for key in TEXTURES})
        for key, row in TEXTURES.items():
            with self.subTest(key=key):
                template = json.loads((folder / (key + ".model.json")).read_text())
                self.assertEqual(template["ClassName"], "SurfaceAppearance")
                props = template["Properties"]
                for field, prop in (("colorMap", "ColorMap"), ("normalMap", "NormalMap"), ("roughnessMap", "RoughnessMap")):
                    if row[field] > 0:
                        self.assertEqual(props[prop], "rbxassetid://%d" % row[field])
                    else:
                        self.assertNotIn(prop, props)
                self.assertEqual(props["Color"], [1, 1, 1])

    def test_the_loader_clones_a_template_and_never_creates_one(self):
        source = lint_data.uncomment((ROOT / "src/server/Services/Models.luau").read_text())
        self.assertNotIn("Instance.new(\"SurfaceAppearance\")", source)
        self.assertIn("template:Clone()", source)
        self.assertIn("Config.SurfaceTemplatesFolderName", source)
        config = load(str(ROOT / "src/shared/data/Config.luau"))
        self.assertEqual(config["SurfaceTemplatesFolderName"], "SurfaceTemplates")
        self.assertGreater(config["SurfaceTemplatesWaitSeconds"], 0)

    def test_the_folder_is_built_by_the_default_project_through_src_shared(self):
        # src/shared is mapped as ReplicatedStorage.Shared in all three Rojo projects, so the templates need no mapping of their own.
        for name in ("default", "world2", "home"):
            project = json.loads((ROOT / (name + ".project.json")).read_text())
            self.assertEqual(project["tree"]["ReplicatedStorage"]["Shared"]["$path"], "src/shared")


class MaterialsJson(unittest.TestCase):
    def test_surface_fields_are_valid_where_present(self):
        seen = 0
        for folder in model_folders():
            for entry in json.loads((folder / "materials.json").read_text()):
                with self.subTest(model=folder.name, slot=entry["name"]):
                    if "material" in entry:
                        self.assertIn(entry["material"], lint_data.SURFACE_MATERIALS)
                    if "texture" in entry:
                        self.assertIn(entry["texture"], TEXTURES)
                    if "glossy" in entry:
                        self.assertIsInstance(entry["glossy"], bool)
                    seen += any(k in entry for k in lint_data.SURFACE_KEYS)
        self.assertGreater(seen, 0)

    def test_the_world_one_species_follow_the_concept_list(self):
        wanted = {
            "Mossbop": {"Body": "Grass"}, "Pebblet": {"Body": "Slate"}, "Glimmo": {"Body": "Glass", "Accessory": "Neon"},
            "Twiglet": {"Body": "Wood"}, "Buzzlebee": {"Body": "Fabric"}, "Lanternewt": {"Accessory": "Neon"},
            "Snailbyte": {"Accessory": "Metal"}, "Rocklobber": {"Accessory": "Neon"}, "Zapfinch": {"Accessory": "Neon"},
            "Sparkfox": {"Body": "SmoothPlastic", "Accessory": "Neon"}, "Thunderhog": {"Accessory": "Neon"}, "Gloomoth": {"Accessory": "Glass"},
            "Gaiabloom": {"Trim": "Neon"}, "Radish": {"Accessory": "Neon"}, "Panpipe": {"Accessory": "Neon"}, "Puffpuff": {},
        }
        for sid, materials in wanted.items():
            entries = {e["name"]: e for e in json.loads((ROOT / "assets/models" / sid / "materials.json").read_text())}
            for slot, entry in entries.items():
                with self.subTest(model=sid, slot=slot):
                    self.assertEqual(entry.get("material"), materials.get(slot))
                    self.assertEqual(entry.get("glossy", False), slot in ("EyeWhite", "EyeHighlight"))

    def test_the_frostbyte_species_follow_the_concept_list(self):
        # Snow for the snow bodies, Ice for icicles and the iceberg shell, Fabric for scarves, caps and fur, Glass for the aurora
        # crest, Neon for the glow parts and the ember, Metal for the kettle; every eye slot glossy and nothing else.
        wanted = {
            "Flufflet": {"Body": "Snow", "BodyDark": "Fabric", "Accessory": "Fabric"}, "Snowbun": {"Body": "Snow", "BodyDark": "Fabric"},
            "Drippo": {"Body": "Ice", "BodyDark": "Ice", "Accessory": "Fabric"},
            "Kettlepuff": {"Body": "Metal", "BodyDark": "Metal", "Accessory": "Metal"},
            "Chipmole": {"Body": "Fabric", "Accessory": "Ice"}, "Pengoo": {"Body": "Fabric", "Accessory": "Fabric", "Belly": "Fabric"},
            "Flapsicle": {"Body": "Fabric", "Accessory": "Ice"}, "Toastoad": {"Body": "Leather", "BodyDark": "Leather", "Accessory": "Pebble"},
            "Emberchin": {"Body": "Pebble", "BodyDark": "Slate", "Accessory": "Neon"},
            "Reindazzle": {"Body": "Fabric", "BodyDark": "Ice", "Accessory": "Neon"},
            "Shellberg": {"Body": "Ice", "BodyDark": "Fabric", "Accessory": "Neon"}, "Capybubble": {"Body": "Fabric", "Accessory": "Neon"},
            "Shimmerlynx": {"Body": "Fabric", "Accessory": "Neon", "Trim": "Fabric"},
            "Frostfang": {"Body": "Fabric", "Accessory": "Ice", "Trim": "Fabric"},
            "Skaddle": {"Body": "Snow", "BodyDark": "Fabric", "Accessory": "Ice", "Trim": "Neon"}, "Fenripup": {"Body": "Fabric", "Accessory": "Neon"},
        }
        self.assertEqual(len(wanted), 16)
        for sid, materials in wanted.items():
            entries = {e["name"]: e for e in json.loads((ROOT / "assets/models" / sid / "materials.json").read_text())}
            for slot, entry in entries.items():
                with self.subTest(model=sid, slot=slot):
                    self.assertEqual(entry.get("material"), materials.get(slot))
                    self.assertEqual(entry.get("glossy", False), slot in ("EyeWhite", "EyeHighlight"))
                    if "texture" in entry:
                        self.assertIn(entry["texture"], ("fur", "ice"))
                        self.assertEqual(entry["texture"] == "ice", entry["material"] == "Ice")

    def test_a_regeneration_keeps_the_surface_fields(self):
        # alien_base.write_materials_entries cannot import here (it needs bpy), so read its rule from the source.
        source = (ROOT / "tools/blender/alien_base.py").read_text()
        self.assertIn('SURFACE_KEYS = ("material", "texture", "glossy")', source)
        self.assertIn("entry[key] = old[entry[\"name\"]][key]", source)


class SurfaceNumbers(unittest.TestCase):
    def test_the_blender_pass_numbers_are_sane(self):
        s = sr.SURFACE
        self.assertTrue(0 < s["smooth_angle"] < 90)
        self.assertGreater(s["bevel_width"], 0)
        self.assertGreaterEqual(s["bevel_segments"], 1)
        self.assertTrue(0 < s["bevel_angle"] < 90)
        self.assertGreater(s["bevel_min_dim"], 0)
        g = s["gradient"]
        self.assertTrue(0 < g["belly"] < g["crown"] <= 1.0, "the gradient is a multiplier: crown at most 1, belly darker")
        self.assertTrue(0 <= g["down"] < 1)
        self.assertIn("Body", g["slots"])
        for face in sr.FACE_SLOTS:
            self.assertNotIn(face, g["slots"], "the face stays white")


class BakedTextures(unittest.TestCase):
    def test_every_texture_key_has_a_pattern_three_small_pngs_and_a_readme_line(self):
        script = (ROOT / "tools/blender/bake_textures.py").read_text()
        readme = (ROOT / "assets/textures/README.md").read_text()
        for key in TEXTURES:
            with self.subTest(key=key):
                self.assertRegex(script, r'"%s":\s*%s\b' % (key, key), "no pattern in bake_textures.PATTERNS")
                self.assertIn("- `%s`:" % key, readme)
                for kind in ("color", "normal", "roughness"):
                    path = ROOT / "assets/textures" / key / ("%s_%s.png" % (key, kind))
                    self.assertTrue(path.is_file(), str(path))
                    self.assertLessEqual(path.stat().st_size, MAX_TEXTURE_BYTES)
                    head = path.read_bytes()[:33]
                    self.assertEqual(head[:8], b"\x89PNG\r\n\x1a\n")
                    self.assertEqual(int.from_bytes(head[16:20], "big"), 512)
                    self.assertEqual(int.from_bytes(head[20:24], "big"), 512)

    def test_no_stray_texture_folder(self):
        folders = {d.name for d in (ROOT / "assets/textures").iterdir() if d.is_dir()}
        self.assertEqual(folders, set(TEXTURES))


if __name__ == "__main__":
    unittest.main()
