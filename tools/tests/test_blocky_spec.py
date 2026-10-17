"""Tests for tools/blocky/spec.py: the YAML subset, the note reader, mirror expansion, geometry, the validator and the write-back.

Standard library only (./tools/test.sh runs it; no Blender). The rules under test are the numbered rules of
docs/vault/06-art-pipelines/Blocky-Style.md; the three prototype notes in docs/vault/07-alien-game/Creatures must validate clean.
"""
from __future__ import annotations

import copy
import importlib.util
import math
import pathlib
import sys
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
_SPEC = importlib.util.spec_from_file_location("blocky_spec", ROOT / "tools/blocky/spec.py")
S = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(S)  # type: ignore[union-attr]
CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"

FACE_ROWS = [
    "................",
    "................",
    "...kk......kk...",
    "..kwkk....kkwk..",
    "..kwkk....kkwk..",
    "..kkkk....kkkk..",
    "..kgwk....kwgk..",
    "...gg.k..k.gg...",
    "..pp...kk...pp..",
    "................",
]

NOTE = '''---
tags: [alien-game, creature, blocky]
id: Testbop
name: Testy
world: 1
tier: Common
status: concept
height: 2.25
blocks: 0
tris: 0
bevel_width: 0.05
bevel_segments: 2
palette: ["#6CCB5F", "#2F7A4B", "#D9F36B", "#142019"]
roles: [body, second, accent, ink]
hero: Horn
artboard: ""
render: ""
glb: ""
---
# Testbop

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.375, 0], bevel: true}
  - {name: Belly, slot: BodyDark, size: [1.5, 0.5, 1.25], at: [0, 0.5, 0], bevel: true}  # a comment
  - {name: Foot, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0.5, 0.125, 0], mirror: x}
  - {name: Horn, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0, 2.125, 0], shape: cone6}
  - {name: Ear, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [0.75, 2.125, 0.5], rot: [0, 0, -20], mirror: x, moves: ear, pivot: [0.75, 2, 0.5]}
```

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF8FA3"
  rows:
%s
```
''' % "\n".join('    - "%s"' % r for r in FACE_ROWS)


def note_spec(text=NOTE):
    spec = S.read_note(text)
    spec["parts"] = [S.normalise(p, i) for i, p in enumerate(spec["parts"])]
    return spec


def errors_of(spec):
    return S.validate(spec)[0]


class YamlSubset(unittest.TestCase):
    def test_flow_mapping_with_lists_and_comments(self):
        data = S.load_yaml('parts:\n  - {name: A, size: [1, 0.5, 2], bevel: true, hex: "#FF00AA"}  # trailing\n  - {name: "B c", mirror: x}\n')
        self.assertEqual(data["parts"][0], {"name": "A", "size": [1, 0.5, 2], "bevel": True, "hex": "#FF00AA"})
        self.assertEqual(data["parts"][1], {"name": "B c", "mirror": "x"})

    def test_nested_mapping_quoted_keys_and_block_list(self):
        data = S.load_yaml('face:\n  host: Head\n  legend:\n    ".": body\n    "k": ink\n  rows:\n    - "..k.."\n    - ".kkk."\n')
        self.assertEqual(data["face"]["legend"], {".": "body", "k": "ink"})
        self.assertEqual(data["face"]["rows"], ["..k..", ".kkk."])

    def test_scalars(self):
        data = S.load_yaml('a: 1\nb: -2.5\nc: true\nd: ""\ne: [x, "y z", 3]\nf: null\ng: "[[Link.jpg]]"\n')
        self.assertEqual(data, {"a": 1, "b": -2.5, "c": True, "d": "", "e": ["x", "y z", 3], "f": None, "g": "[[Link.jpg]]"})

    def test_hash_inside_quotes_is_not_a_comment(self):
        self.assertEqual(S.load_yaml('palette: ["#112233", "#AABBCC"]  # two\n'), {"palette": ["#112233", "#AABBCC"]})

    def test_matches_pyyaml_on_the_prototype_notes(self):
        try:
            import yaml  # noqa: PLC0415
        except ImportError:
            self.skipTest("PyYAML not installed")
        for path in sorted(CREATURES.glob("*.md")):
            text = path.read_text(encoding="utf-8")
            for block in S.FENCE.finditer(text):
                self.assertEqual(S.load_yaml(block.group(1)), yaml.safe_load(block.group(1)), path.name)
            front = S.FRONT.match(text).group(1)
            self.assertEqual(S.load_yaml(front), yaml.safe_load(front), path.name)


class Note(unittest.TestCase):
    def test_read_note(self):
        spec = note_spec()
        self.assertEqual(spec["front"]["id"], "Testbop")
        self.assertEqual(len(spec["parts"]), 5)
        self.assertEqual(spec["face"]["host"], "Head")
        self.assertEqual(spec["parts"][0]["rot"], [0.0, 0.0, 0.0])
        self.assertEqual(spec["parts"][1]["mirror"], "none")

    def test_unknown_field_is_an_error(self):
        with self.assertRaises(S.SpecError):
            S.normalise({"name": "X", "slot": "Body", "size": [1, 1, 1], "at": [0, 0.5, 0], "colour": "red"})

    def test_missing_parts_block(self):
        with self.assertRaises(S.SpecError):
            S.read_note("---\nid: X\n---\nno blocks\n")


class Expand(unittest.TestCase):
    def test_mirror_names_positions_rotations_and_pivots(self):
        parts = S.expand(note_spec()["parts"])
        names = [p["name"] for p in parts]
        self.assertEqual(names, ["Head", "Belly", "FootR", "FootL", "Horn", "EarR", "EarL"])
        ear_r, ear_l = parts[5], parts[6]
        self.assertEqual(ear_r["at"], [0.75, 2.125, 0.5])
        self.assertEqual(ear_l["at"], [-0.75, 2.125, 0.5])
        self.assertEqual(ear_l["rot"], [0.0, 0.0, 20.0])
        self.assertEqual(ear_l["pivot"], [-0.75, 2.0, 0.5])
        self.assertEqual(ear_l["source"], "Ear")

    def test_mirrored_part_is_the_reflection(self):
        part = S.normalise({"name": "W", "slot": "Body", "size": [1, 0.25, 0.5], "at": [1.5, 2, 0.25], "rot": [15, -20, 10], "mirror": "x"})
        right, left = S.expand([part])
        rv, _ = S.part_mesh(right)
        lv, _ = S.part_mesh(left)
        reflected = sorted((round(-x, 6), round(y, 6), round(z, 6)) for x, y, z in rv)
        self.assertEqual(reflected, sorted((round(x, 6), round(y, 6), round(z, 6)) for x, y, z in lv))

    def test_movers_group_by_pivot(self):
        parts = S.expand(note_spec()["parts"])
        movers = S.movers(parts)
        self.assertEqual(sorted(movers), ["earL", "earR"])
        halo = [S.normalise({"name": "R%d" % i, "slot": "Trim", "size": [0.5, 0.5, 0.5], "at": [i, 3, 1], "moves": "halo", "pivot": [0, 3, 1]})
                for i in range(3)]
        self.assertEqual(list(S.movers(S.expand(halo))), ["halo"])


class Geometry(unittest.TestCase):
    def test_box_vertices(self):
        part = S.normalise({"name": "B", "slot": "Body", "size": [2, 1, 4], "at": [1, 0.5, -2]})
        verts, faces = S.part_mesh(part)
        self.assertEqual(len(verts), 8)
        self.assertEqual(len(faces), 6)
        xs, ys, zs = zip(*verts)
        self.assertEqual((min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)), (0, 2, 0, 1, -4, 0))

    def test_rotation_about_y_turns_x_into_minus_z(self):
        m = S.rot_matrix([0, 90, 0])
        v = [sum(m[i][k] * (1, 0, 0)[k] for k in range(3)) for i in range(3)]
        self.assertAlmostEqual(v[0], 0)
        self.assertAlmostEqual(v[2], -1)

    def test_shapes_fill_their_box_and_count_triangles(self):
        for shape, tris in (("box", 12), ("wedge", 8), ("cone6", 10), ("ico1", 20)):
            verts, faces = S.UNIT[shape]
            for i in range(3):
                self.assertAlmostEqual(min(v[i] for v in verts), -0.5, msg=shape)
                self.assertAlmostEqual(max(v[i] for v in verts), 0.5, msg=shape)
            self.assertEqual(sum(len(f) - 2 for f in faces), tris, shape)

    def test_faces_wind_outward(self):
        for shape, (verts, faces) in S.UNIT.items():
            mid = [sum(v[t] for v in verts) / len(verts) for t in range(3)]  # inside every convex shape (the wedge's slope passes through 0)
            for f in faces:
                a, b, c = (verts[i] for i in f[:3])
                u = [b[t] - a[t] for t in range(3)]
                v = [c[t] - a[t] for t in range(3)]
                n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
                centre = [sum(verts[i][t] for i in f) / len(f) - mid[t] for t in range(3)]
                self.assertGreater(sum(n[t] * centre[t] for t in range(3)), 0, "%s face %s" % (shape, f))

    def test_wedge_slope_faces_front_and_up(self):
        verts, _ = S.UNIT["wedge"]
        top = [v for v in verts if v[1] > 0]
        self.assertTrue(all(v[2] > 0 for v in top))  # full height at the back (+z), as Roblox's WedgePart

    def test_counts(self):
        c = S.counts(note_spec())
        self.assertEqual(c["blocks"], 7)
        self.assertEqual(c["tris"], 108 * 2 + 12 * 2 + 10 + 12 * 2)
        self.assertEqual(c["masses"], 2)
        self.assertEqual(c["movers"], 2)


class Validate(unittest.TestCase):
    def setUp(self):
        self.spec = note_spec()
        self.spec["front"]["height"] = S.counts(self.spec)["height"]

    def part(self, name):
        return next(p for p in self.spec["parts"] if p["name"] == name)

    def assertRule(self, needle):
        errs = errors_of(self.spec)
        self.assertTrue(any(needle in e for e in errs), "no error with %r in %s" % (needle, errs))

    def test_the_base_spec_is_clean(self):
        self.assertEqual(errors_of(self.spec), [])

    def test_off_grid_size_and_face(self):
        self.part("Horn")["size"] = [0.3, 0.25, 0.25]
        self.assertRule("off the 0.125 grid")
        self.part("Horn")["size"] = [0.25, 0.25, 0.25]
        self.part("Horn")["at"] = [0.1, 2.125, 0]
        self.assertRule("half grid")

    def test_mass_size_on_the_quarter_grid(self):
        self.part("Belly")["size"] = [1.5, 0.375, 1.25]
        self.part("Belly")["at"] = [0, 0.4375, 0]
        self.assertRule("off the 0.25 grid")

    def test_tilts(self):
        self.part("Ear")["rot"] = [0, 0, -30]
        self.assertRule("a tilt is 10 to 25")
        self.part("Ear")["rot"] = [0, 0, -70]  # a quarter turn and 20 more is fine
        self.assertNotIn(True, ["tilt is" in e for e in errors_of(self.spec)])
        self.part("Ear")["at"] = [0.7, 2.125, 0.5]
        self.assertRule("tilted part's centre")

    def test_bevel_only_on_axis_aligned_boxes_and_the_width_rule(self):
        self.part("Horn")["bevel"] = True
        self.assertRule("only a box mass is bevelled")
        self.part("Horn")["bevel"] = False
        self.spec["front"]["bevel_width"] = 0.2
        self.assertRule("bevel_width")

    def test_height_and_ground(self):
        self.spec["front"]["height"] = 3.0
        self.assertRule("does not match the tallest point")
        self.spec["front"]["height"] = S.counts(self.spec)["height"]
        for p in self.spec["parts"]:
            p["at"][1] += 0.125
            if p["pivot"]:
                p["pivot"][1] += 0.125
        self.spec["front"]["height"] = S.counts(self.spec)["height"]
        self.assertRule("feet stand on y = 0")

    def test_head_share(self):
        self.part("Head")["size"] = [2, 0.75, 1.75]
        self.part("Head")["at"] = [0, 1.125, 0]
        self.spec["front"]["height"] = S.counts(self.spec)["height"]
        self.assertRule("of the height")

    def test_ladder_blocks(self):
        for i in range(3):
            self.spec["parts"].append(S.normalise({"name": "Dot%d" % i, "slot": "BodyDark", "size": [0.125, 0.125, 0.125],
                                                   "at": [0.5625, 1 + 0.25 * i, -0.9375], "mirror": "x"}))
        self.assertRule("a Common has 5 to 10")

    def test_glow_tiers(self):
        self.spec["front"]["palette"].append("#FFFF00")
        self.spec["front"]["roles"].append("glow")
        self.part("Horn")["slot"] = "Glow"
        self.assertRule("a Common has no glow region")

    def test_palette_ink_and_greyscale(self):
        self.spec["front"]["palette"][3] = "#777777"
        self.assertRule("near-black")
        self.spec["front"]["palette"][3] = "#142019"
        self.spec["front"]["palette"][1] = "#6ACB60"
        self.assertRule("apart in greyscale")

    def test_face_rows_border_and_eye(self):
        face = self.spec["face"]
        face["rows"] = FACE_ROWS[:-1]
        self.assertRule("for square cells")
        face["rows"] = list(FACE_ROWS)
        face["rows"][0] = "k" + FACE_ROWS[0][1:]
        self.assertRule("the face border")
        face["rows"] = [r.replace("w", "k") for r in FACE_ROWS]
        self.assertRule("the house eye is not on the face")

    def test_mirror_on_the_centre_line_and_pivots(self):
        self.part("Horn")["mirror"] = "x"
        self.assertRule("centred on x = 0")
        self.part("Horn")["mirror"] = "none"
        self.part("Horn")["moves"] = "float"
        self.assertRule("has no pivot")

    def test_too_many_movers(self):
        for i in range(2):
            self.spec["parts"].append(S.normalise({"name": "Tail%d" % i, "slot": "BodyDark", "size": [0.125, 0.125, 0.125],
                                                   "at": [0.25 * i, 0.5625, 0.6875], "moves": "tail", "pivot": [0.25 * i + 0.01, 0.5, 0.625]}))
        self.spec["parts"].append(S.normalise({"name": "Orb", "slot": "Accessory", "size": [0.25, 0.25, 0.25], "at": [0, 1.875, -1], "moves": "float",
                                               "pivot": [0, 1.875, -1]}))
        self.assertRule("moving objects")

    def test_prototype_notes_are_clean(self):
        for path in sorted(CREATURES.glob("*.md")):
            spec = S.load(path)
            errors, _ = S.validate(spec)
            self.assertEqual(errors, [], path.name)
            self.assertIn(spec["front"]["tier"], S.TIERS)


class WriteBack(unittest.TestCase):
    def test_set_front_replaces_in_place_and_appends(self):
        text = "---\nid: X\nblocks: 0\nlist:\n  - a\n  - b\ntris: 0\n---\n# body\n"
        out = S.set_front(text, {"blocks": 12, "list": [1, 2], "overlap": [0.99, 0.98], "render": "[[X_tq.jpg]]"})
        self.assertIn("blocks: 12\n", out)
        self.assertIn("list: [1, 2]\ntris: 0\n", out)
        self.assertIn("overlap: [0.99, 0.98]\n", out)
        self.assertIn('render: "[[X_tq.jpg]]"\n', out)
        self.assertTrue(out.endswith("---\n# body\n"))
        self.assertEqual(S.load_yaml(S.FRONT.match(out).group(1))["render"], "[[X_tq.jpg]]")

    def test_lstar(self):
        self.assertAlmostEqual(S.lstar("#000000"), 0, places=3)
        self.assertAlmostEqual(S.lstar("#FFFFFF"), 100, places=3)
        self.assertTrue(40 < S.lstar("#777777") < 60)


if __name__ == "__main__":
    unittest.main()
