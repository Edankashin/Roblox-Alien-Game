"""Tests for tools/blockbench/to_bbmodel.py (a species GLB to a Blockbench project), with no Blender and no Blockbench.

Standard library only (Pillow, when installed, adds one cross-check of the PNG). Run:
  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
(./tools/test.sh runs it too). Sparkfox and Mossbop are built from the repo's own assets/models into a temporary
folder, so a changed GLB, a renamed slot or a broken writer fails here before the Mac opens a file.
"""
from __future__ import annotations

import base64
import contextlib
import copy
import importlib.util
import io
import json
import pathlib
import struct
import tempfile
import unittest
import zlib
from unittest import mock

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
_SPEC = importlib.util.spec_from_file_location("to_bbmodel", ROOT / "tools/blockbench/to_bbmodel.py")
bb = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(bb)  # type: ignore[union-attr]

try:
    from PIL import Image
except ImportError:  # the tool and these tests work without it
    Image = None

SPECIES = ("Sparkfox", "Mossbop")


def quiet(*args):
    """bb.main(args) with its output swallowed; (exit code, stdout, stderr)."""
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        code = bb.main(list(args))
    return code, out.getvalue(), err.getvalue()


def glb_json(path):
    data = pathlib.Path(path).read_bytes()
    size = struct.unpack_from("<I", data, 12)[0]
    return json.loads(data[20:20 + size])


def glb_triangles(path):
    """Triangles by the glTF's own index accessors, independent of the tool's reader."""
    doc = glb_json(path)
    return sum(doc["accessors"][p["indices"]]["count"] // 3 for m in doc["meshes"] for p in m["primitives"])


def decode_plain_png(data):
    """(width, height, RGBA bytes) of a PNG written without filtering, which is what encode_png_plain writes."""
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    offset, idat, width = 8, b"", 0
    while offset < len(data):
        size, tag = struct.unpack_from(">I4s", data, offset)
        body = data[offset + 8:offset + 8 + size]
        if tag == b"IHDR":
            width, height, depth, colour = struct.unpack(">IIBB", body[:10])
            assert (depth, colour) == (8, 6)
        elif tag == b"IDAT":
            idat += body
        offset += 12 + size
    raw = zlib.decompress(idat)
    stride = width * 4 + 1
    rows = []
    for y in range(height):
        assert raw[y * stride] == 0, "filtered row"
        rows.append(raw[y * stride + 1:(y + 1) * stride])
    return width, height, b"".join(rows)


def sparkfox_project():
    folder = ROOT / "assets/models/Sparkfox"
    return bb.build_project("Sparkfox", bb.read_glb(folder / "Sparkfox.glb"), bb.load_entries(folder))


def texture_bytes(project):
    return base64.b64decode(project["textures"][0]["source"].split(",", 1)[1])


def pack_glb(doc, blob):
    doc = dict(doc, buffers=[{"byteLength": len(blob)}])
    text = json.dumps(doc).encode()
    text += b" " * (-len(text) % 4)
    blob += b"\0" * (-len(blob) % 4)
    total = 12 + 8 + len(text) + 8 + len(blob)
    return (struct.pack("<4sII", b"glTF", 2, total) + struct.pack("<I4s", len(text), b"JSON") + text
            + struct.pack("<I4s", len(blob), b"BIN\0") + blob)


def quad_glb(material=None, uv_scale=1.0):
    """A unit quad (two triangles, counter-clockwise from +Z) as one mesh of two primitives on one material,
    instanced by two nodes: one moved and doubled, one mirrored in x (which flips the winding). `uv_scale` stretches
    the UVs (past 1 they leave 0..1)."""
    positions = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)]
    blob = b"".join(struct.pack("<3f", *p) for p in positions)                    # 0..48
    blob += b"".join(struct.pack("<3f", 0, 0, 1) for _ in positions)               # 48..96
    blob += b"".join(struct.pack("<2f", u * uv_scale, v * uv_scale) for u, v in ((0, 1), (1, 1), (1, 0), (0, 0)))  # 96..128
    blob += b"".join(struct.pack("<4H", 65535, 0, 32768, 65535) for _ in positions)  # 128..160
    blob += struct.pack("<6H", 0, 1, 2, 0, 2, 3)                                   # 160..172
    views = [{"buffer": 0, "byteOffset": o, "byteLength": n} for o, n in ((0, 48), (48, 48), (96, 32), (128, 32), (160, 12))]
    accessors = [{"bufferView": 0, "componentType": 5126, "count": 4, "type": "VEC3"},
                 {"bufferView": 1, "componentType": 5126, "count": 4, "type": "VEC3"},
                 {"bufferView": 2, "componentType": 5126, "count": 4, "type": "VEC2"},
                 {"bufferView": 3, "componentType": 5123, "count": 4, "type": "VEC4", "normalized": True},
                 {"bufferView": 4, "componentType": 5123, "count": 6, "type": "SCALAR"}]
    prim = {"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2, "COLOR_0": 3}, "indices": 4}
    if material is not None:
        prim["material"] = material
    doc = {"asset": {"version": "2.0"}, "scene": 0, "scenes": [{"nodes": [0, 1]}],
           "nodes": [{"mesh": 0, "translation": [10, 0, 0], "scale": [2, 2, 2]}, {"mesh": 0, "translation": [0, 5, 0], "scale": [-1, 1, 1]}],
           "meshes": [{"primitives": [dict(prim), dict(prim)]}], "bufferViews": views, "accessors": accessors}
    if material is not None:
        doc["materials"] = [{"name": "Blue Body", "pbrMetallicRoughness": {"baseColorFactor": [0, 0, 1, 1]}}]
    return pack_glb(doc, blob)


class BuiltSpecies(unittest.TestCase):
    """Sparkfox and Mossbop written once into a temporary folder."""

    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory()
        cls.out = pathlib.Path(cls._tmp.name)
        code, _, err = quiet("--species", *SPECIES, "--out", str(cls.out))
        assert code == 0, err
        cls.projects = {sid: json.loads((cls.out / (sid + ".bbmodel")).read_text()) for sid in SPECIES}

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def slot_names(self, sid):
        return [e["name"] for e in json.loads((ROOT / "assets/models" / sid / "materials.json").read_text())]

    def test_meta_is_a_generic_model_in_format_5(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                self.assertEqual(project["meta"], {"format_version": "5.0", "model_format": "free", "box_uv": False})
                self.assertEqual(project["name"], sid)
                self.assertEqual(project["resolution"], {"width": 128, "height": 128})

    def test_one_mesh_per_slot_at_most_seven(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                meshes = [e for e in project["elements"] if e["type"] == "mesh"]
                self.assertEqual(len(meshes), len(project["elements"]))
                self.assertLessEqual(len(meshes), 7)
                self.assertEqual([m["name"] for m in meshes], [n + "Mesh" for n in self.slot_names(sid)])

    def test_face_count_equals_the_glb_triangle_count(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                faces = sum(len(e["faces"]) for e in project["elements"])
                self.assertEqual(faces, glb_triangles(ROOT / "assets/models" / sid / (sid + ".glb")))
                for element in project["elements"]:
                    for face in element["faces"].values():
                        self.assertEqual(len(face["vertices"]), 3)
                        self.assertEqual(face["texture"], 0)

    def test_welding_shares_vertices_between_faces(self):
        for sid, project in self.projects.items():
            for element in project["elements"]:
                with self.subTest(sid + element["name"]):
                    self.assertLess(len(element["vertices"]), 3 * len(element["faces"]))

    def test_positions_are_sixteen_blockbench_units_per_glb_unit(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                doc = glb_json(ROOT / "assets/models" / sid / (sid + ".glb"))
                top = max(doc["accessors"][p["attributes"]["POSITION"]]["max"][1] for m in doc["meshes"] for p in m["primitives"])
                built = max(v[1] for e in project["elements"] for v in e["vertices"].values())
                self.assertAlmostEqual(built, top * 16, places=2)

    def test_palette_texture_decodes_to_128_by_128(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                self.assertEqual(len(project["textures"]), 1)
                texture = project["textures"][0]
                self.assertTrue(texture["internal"])
                self.assertEqual((texture["width"], texture["height"]), (128, 128))
                self.assertEqual(bb.png_size(texture_bytes(project)), (128, 128))
                if Image is not None:
                    image = Image.open(io.BytesIO(texture_bytes(project)))
                    image.load()
                    self.assertEqual(image.size, (128, 128))

    def test_groups_are_named_after_the_slots_and_hold_their_mesh(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                names = self.slot_names(sid)
                self.assertEqual([g["name"] for g in project["groups"]], names)
                self.assertEqual([n["uuid"] for n in project["outliner"]], [g["uuid"] for g in project["groups"]])
                for node, element in zip(project["outliner"], project["elements"]):
                    self.assertEqual(node["children"], [element["uuid"]])
                for group, element in zip(project["groups"], project["elements"]):
                    points = list(element["vertices"].values())
                    for axis in range(3):
                        low, high = min(p[axis] for p in points), max(p[axis] for p in points)
                        self.assertTrue(low - 1e-3 <= group["origin"][axis] <= high + 1e-3, (group["name"], axis))

    def test_the_idle_animation_is_a_two_second_bob_on_body(self):
        for sid, project in self.projects.items():
            with self.subTest(sid):
                self.assertEqual([a["name"] for a in project["animations"]], ["idle"])
                idle = project["animations"][0]
                self.assertEqual((idle["length"], idle["loop"]), (2.0, "loop"))
                body = next(g for g in project["groups"] if g["name"] == "Body")
                self.assertEqual(list(idle["animators"]), [body["uuid"]])
                frames = idle["animators"][body["uuid"]]["keyframes"]
                self.assertEqual([k["time"] for k in frames], [0, 1.0, 2.0])
                self.assertEqual({k["channel"] for k in frames}, {"position"})
                self.assertEqual(frames[0]["data_points"], frames[2]["data_points"])
                self.assertGreater(float(frames[1]["data_points"][0]["y"]), 0)

    def test_no_idle_writes_an_empty_animation_list(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(quiet("--species", "Sparkfox", "--no-idle", "--out", tmp)[0], 0)
            self.assertEqual(json.loads((pathlib.Path(tmp) / "Sparkfox.bbmodel").read_text())["animations"], [])

    def test_output_is_deterministic(self):
        with tempfile.TemporaryDirectory() as tmp:
            quiet("--species", "Mossbop", "--out", tmp)
            first = json.loads((pathlib.Path(tmp) / "Mossbop.bbmodel").read_text())
        second = self.projects["Mossbop"]
        self.assertEqual(first["groups"], second["groups"])
        self.assertEqual(first["elements"], second["elements"])
        self.assertEqual(first["animations"], second["animations"])

    def test_every_face_lands_on_its_slots_palette_colour(self):
        """With the built-in PNG encoder (readable without Pillow): each face's UV centre samples the slot's hex."""
        with mock.patch.object(bb, "encode_png", bb.encode_png_plain):
            for sid in SPECIES:
                folder = ROOT / "assets/models" / sid
                project = bb.build_project(sid, bb.read_glb(folder / (sid + ".glb")), bb.load_entries(folder))
                width, height, pixels = decode_plain_png(texture_bytes(project))
                self.assertEqual((width, height), (128, 128))
                hexes = {e["name"]: e["hex"] for e in json.loads((folder / "materials.json").read_text())}
                for group, element in zip(project["groups"], project["elements"]):
                    for face in element["faces"].values():
                        u = sum(uv[0] for uv in face["uv"].values()) / 3
                        v = sum(uv[1] for uv in face["uv"].values()) / 3
                        offset = (int(v) * width + int(u)) * 4
                        got = "%02X%02X%02X" % tuple(pixels[offset:offset + 3])
                        self.assertEqual(got, hexes[group["name"]], (sid, group["name"]))
                        self.assertEqual(pixels[offset + 3], 255)

    @unittest.skipIf(Image is None, "Pillow is not installed")
    def test_pillow_and_the_built_in_encoder_draw_the_same_pixels(self):
        pixels = bb.palette_pixels([bb.Slot("A", 0, "FF6B35", []), bb.Slot("B", 1, "08080A", [])], bb.palette_layout(2, 32), 32)
        plain = decode_plain_png(bb.encode_png_plain(32, 32, pixels))
        image = Image.open(io.BytesIO(bb.encode_png(32, 32, pixels))).convert("RGBA")
        self.assertEqual(plain, (32, 32, image.tobytes()))

    def test_check_passes_on_the_written_files(self):
        code, out, err = quiet("--species", *SPECIES, "--check", "--out", str(self.out))
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(out.count(": ok ("), 2)


class CheckCatchesBreakage(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.good = json.loads(json.dumps(sparkfox_project()))

    def broken(self, edit):
        project = copy.deepcopy(self.good)
        edit(project)
        return bb.check_project(project)

    def assertCaught(self, edit, fragment):
        problems = self.broken(edit)
        self.assertTrue(any(fragment in p for p in problems), (fragment, problems[:3]))

    def test_the_untouched_project_is_clean(self):
        self.assertEqual(bb.check_project(self.good), [])

    def test_face_with_a_missing_vertex(self):
        def edit(p):
            face = next(iter(p["elements"][0]["faces"].values()))
            face["vertices"][0] = "nope"
        self.assertCaught(edit, "missing vertices")

    def test_uv_outside_the_resolution(self):
        def edit(p):
            face = next(iter(p["elements"][0]["faces"].values()))
            face["uv"][face["vertices"][0]] = [129, 5]
        self.assertCaught(edit, "outside the 128x128 texture")

    def test_uv_missing_for_a_vertex(self):
        def edit(p):
            face = next(iter(p["elements"][0]["faces"].values()))
            del face["uv"][face["vertices"][0]]
        self.assertCaught(edit, "one uv per vertex")

    def test_texture_index_without_a_texture(self):
        def edit(p):
            p["textures"] = []
        self.assertCaught(edit, "points at texture 0 but the file has 0")

    def test_duplicate_uuid(self):
        def edit(p):
            p["groups"][1]["uuid"] = p["groups"][0]["uuid"]
        self.assertCaught(edit, "is used twice")

    def test_group_name_with_a_space_or_a_repeat(self):
        self.assertCaught(lambda p: p["groups"][0].update(name="Left Ear"), "ASCII letters, digits and underscores")
        self.assertCaught(lambda p: p["groups"][1].update(name=p["groups"][0]["name"]), "used twice")

    def test_element_missing_from_the_outliner(self):
        self.assertCaught(lambda p: p["outliner"][0].update(children=[]), "appears 0 times in the outliner")

    def test_texture_png_that_does_not_match_its_entry(self):
        self.assertCaught(lambda p: p["textures"][0].update(width=64), "the PNG is 128x128")
        self.assertCaught(lambda p: p["textures"][0].update(source="data:image/png;base64,AAAA"), "not a PNG")

    def test_wrong_model_format_or_box_uv(self):
        self.assertCaught(lambda p: p["meta"].update(model_format="java_block"), "not 'free'")
        self.assertCaught(lambda p: p["meta"].update(box_uv=True), "box_uv")

    def test_keyframe_past_the_animation_length_and_unknown_animator(self):
        def late(p):
            animator = next(iter(p["animations"][0]["animators"].values()))
            animator["keyframes"][-1]["time"] = 9
        self.assertCaught(late, "outside 0..2.0")
        self.assertCaught(lambda p: p["animations"][0].update(animators={"zzz": {"keyframes": []}}), "unknown uuid")

    def test_file_that_is_not_json_or_not_there(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "x.bbmodel"
            self.assertIn("cannot read", bb.check_file(path)[0])
            path.write_text("{ not json")
            self.assertIn("not valid JSON", bb.check_file(path)[0])
            path.write_text("[]")
            self.assertEqual(bb.check_file(path), ["the file is not a JSON object"])
            path.write_text(json.dumps({"meta": {}, "elements": 3}))
            self.assertTrue(any("is not a list" in p for p in bb.check_file(path)))

    def test_cli_check_fails_on_a_broken_file(self):
        project = copy.deepcopy(self.good)
        project["groups"][0]["name"] = "Bad Name"
        with tempfile.TemporaryDirectory() as tmp:
            (pathlib.Path(tmp) / "Sparkfox.bbmodel").write_text(json.dumps(project))
            code, _, err = quiet("--species", "Sparkfox", "--check", "--out", tmp)
        self.assertEqual(code, 1)
        self.assertIn("problem(s)", err)
        self.assertEqual(quiet("--species", "Sparkfox", "--check", "--out", "/nonexistent-folder")[0], 1)


def tiny_png(width=8, height=4):
    """A small RGBA PNG from the tool's own built-in encoder (a horizontal ramp), so the test needs no Pillow."""
    pixels = bytearray()
    for _ in range(height):
        for x in range(width):
            pixels += bytes((x * 255 // (width - 1), 64, 255 - x * 255 // (width - 1), 255))
    return bb.encode_png_plain(width, height, bytes(pixels))


class BakedPalette(unittest.TestCase):
    """A <Id>_palette.png next to the GLB (tools/blender/unwrap_bake.py) is the project's texture at its own size."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = pathlib.Path(self._tmp.name)
        self.folder = self.dir / "models" / "Tiny"
        self.folder.mkdir(parents=True)
        self.out = self.dir / "out"
        self.png = tiny_png()
        (self.folder / "Tiny.glb").write_bytes(quad_glb(material=0))
        (self.folder / "materials.json").write_text(json.dumps([{"slot": 1, "name": "Blue Body", "hex": "336699"}]))
        (self.folder / "Tiny_palette.png").write_bytes(self.png)

    def run_cli(self, *extra):
        return quiet("--species", "Tiny", "--models", str(self.dir / "models"), "--out", str(self.out), *extra)

    def written(self):
        return json.loads((self.out / "Tiny.bbmodel").read_text())

    def test_the_palette_is_the_texture_at_its_own_resolution(self):
        code, stdout, err = self.run_cli()
        self.assertEqual((code, err), (0, ""))
        self.assertIn("8x4 baked palette", stdout)
        project = self.written()
        self.assertEqual(project["resolution"], {"width": 8, "height": 4})
        self.assertEqual(len(project["textures"]), 1)
        texture = project["textures"][0]
        self.assertEqual((texture["width"], texture["height"], texture["uv_width"], texture["uv_height"]), (8, 4, 8, 4))
        self.assertEqual(texture["name"], "Tiny_palette.png")
        self.assertEqual(texture_bytes(project), self.png)  # the file's bytes, embedded as they are
        self.assertEqual(bb.check_project(project), [])

    def test_faces_keep_the_glbs_uvs_scaled_to_the_palette(self):
        self.run_cli()
        uvs = {tuple(pair) for element in self.written()["elements"] for face in element["faces"].values() for pair in face["uv"].values()}
        # the quad's uvs are (0,1) (1,1) (1,0) (0,0): u times 8, v times 4, no flip and no per-slot fitting
        self.assertEqual(uvs, {(0.0, 4.0), (8.0, 4.0), (8.0, 0.0), (0.0, 0.0)})

    def test_without_a_palette_png_the_flat_palette_is_the_fallback(self):
        (self.folder / "Tiny_palette.png").unlink()
        code, stdout, err = self.run_cli()
        self.assertEqual((code, err), (0, ""))
        self.assertIn("128x128 flat palette", stdout)
        project = self.written()
        self.assertEqual(project["resolution"], {"width": 128, "height": 128})
        self.assertEqual(project["textures"][0]["name"], "Tiny.png")

    def test_flat_ignores_a_palette_png(self):
        code, stdout, _ = self.run_cli("--flat", "--size", "32")
        self.assertEqual(code, 0)
        self.assertIn("32x32 flat palette", stdout)
        self.assertEqual(self.written()["resolution"], {"width": 32, "height": 32})

    def test_uvs_outside_0_to_1_are_refused_with_the_way_out(self):
        (self.folder / "Tiny.glb").write_bytes(quad_glb(material=0, uv_scale=2.0))
        code, _, err = self.run_cli()
        self.assertEqual(code, 1)
        self.assertIn("leave 0..1", err)
        self.assertIn("unwrap_bake.py", err)
        self.assertEqual(self.run_cli("--flat")[0], 0)  # the flat palette fits any uvs

    def test_a_palette_file_that_is_not_a_png_is_refused(self):
        (self.folder / "Tiny_palette.png").write_bytes(b"not a png at all, just text of some length........")
        code, _, err = self.run_cli()
        self.assertEqual(code, 1)
        self.assertIn("Tiny_palette.png", err)
        self.assertIn("not a PNG", err)

    def test_check_passes_on_the_baked_project(self):
        self.run_cli()
        code, out, err = quiet("--species", "Tiny", "--check", "--out", str(self.out))
        self.assertEqual((code, err), (0, ""))
        self.assertIn(": ok (", out)

    def test_a_non_square_palette_works(self):
        (self.folder / "Tiny_palette.png").write_bytes(tiny_png(16, 2))
        self.assertEqual(self.run_cli()[0], 0)
        self.assertEqual(self.written()["resolution"], {"width": 16, "height": 2})


class GlbReader(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.dir = pathlib.Path(self._tmp.name)

    def write(self, name, data):
        path = self.dir / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return path

    def test_nodes_move_points_and_a_mirror_keeps_the_faces_outward(self):
        glb = bb.read_glb(self.write("quad.glb", quad_glb(material=0)))
        self.assertEqual((len(glb.primitives), glb.triangle_count), (4, 8))
        moved, mirrored = glb.primitives[0], glb.primitives[2]
        self.assertEqual(moved.positions[2], (12.0, 2.0, 0.0))
        self.assertEqual(mirrored.positions[1], (-1.0, 5.0, 0.0))
        for prim in glb.primitives:
            for a, b, c in prim.triangles:
                pa, pb, pc = prim.positions[a], prim.positions[b], prim.positions[c]
                cross_z = (pb[0] - pa[0]) * (pc[1] - pa[1]) - (pb[1] - pa[1]) * (pc[0] - pa[0])
                self.assertGreater(cross_z, 0)  # counter-clockwise from +Z, mirrored or not
        self.assertEqual(moved.normals[0], (0.0, 0.0, 1.0))
        self.assertEqual(moved.uvs[0], (0.0, 1.0))

    def test_vertex_colours_are_read_and_normalised(self):
        prim = bb.read_glb(self.write("quad.glb", quad_glb(material=0))).primitives[0]
        self.assertEqual(len(prim.colors), 4)
        self.assertEqual(prim.colors[0][:2], (1.0, 0.0))
        self.assertAlmostEqual(prim.colors[0][2], 32768 / 65535)

    def test_primitives_on_one_material_share_one_slot_with_a_colour(self):
        glb = bb.read_glb(self.write("quad.glb", quad_glb(material=0)))
        slots = bb.build_slots(glb, [])
        self.assertEqual([(s.name, s.hex, len(s.primitives)) for s in slots], [("Blue_Body", "0000FF", 4)])
        listed = bb.build_slots(glb, [{"slot": 1, "name": "Blue Body", "hex": "#ff6b35"}])
        self.assertEqual(listed[0].hex, "FF6B35")
        by_position = bb.build_slots(glb, [{"slot": 1, "name": "Renamed", "hex": "112233"}])
        self.assertEqual(by_position[0].hex, "112233")
        with self.assertRaises(bb.ToolError):
            bb.build_slots(glb, [{"slot": 1, "name": "Blue Body", "hex": "blue"}])

    def test_a_primitive_without_a_material_becomes_one_unassigned_slot(self):
        slots = bb.build_slots(bb.read_glb(self.write("quad.glb", quad_glb())), [])
        self.assertEqual([(s.name, s.hex) for s in slots], [("Unassigned", "FFFFFF")])

    def test_project_from_a_synthetic_glb_passes_its_own_check(self):
        glb = bb.read_glb(self.write("quad.glb", quad_glb(material=0)))
        project = bb.build_project("Quad", glb, [], size=32)
        self.assertEqual(bb.check_project(project), [])
        self.assertEqual(sum(len(e["faces"]) for e in project["elements"]), 8)
        self.assertEqual(project["resolution"], {"width": 32, "height": 32})

    def test_a_collapsed_corner_keeps_its_face(self):
        glb = bb.read_glb(self.write("quad.glb", quad_glb(material=0)))
        prim = glb.primitives[0]
        prim.positions[2] = prim.positions[1]  # two corners of the first triangle now coincide
        project = bb.build_project("Quad", glb, [], size=32)
        self.assertEqual(bb.check_project(project), [])
        self.assertEqual(sum(len(e["faces"]) for e in project["elements"]), 8)

    def test_bad_files_are_refused_with_a_message(self):
        good = quad_glb(material=0)
        for label, data in (("not a glb", b"hello world, this is not a model"), ("truncated", good[:60]),
                            ("version", good[:4] + struct.pack("<I", 1) + good[8:])):
            with self.subTest(label), self.assertRaises(bb.ToolError):
                bb.read_glb(self.write(label + ".glb", data))

    def test_the_cli_reports_unknown_species_and_bad_options(self):
        models = self.dir / "models"
        models.mkdir()
        code, _, err = quiet("--species", "Nope", "--models", str(models), "--out", str(self.dir / "out"))
        self.assertEqual(code, 1)
        self.assertIn("no Nope/Nope.glb", err)
        self.assertEqual(quiet("--species", "Nope", "--size", "8")[0], 1)
        with self.assertRaises(SystemExit):
            quiet()

    def test_all_covers_species_folders_and_skips_props(self):
        models, out = self.dir / "models", self.dir / "out"
        self.write("models/Tiny/Tiny.glb", quad_glb(material=0))
        self.write("models/Tiny/materials.json", json.dumps([{"slot": 1, "name": "Blue Body", "hex": "336699"}]).encode())
        self.write("models/props/Chair/Chair.glb", quad_glb(material=0))
        code, stdout, err = quiet("--all", "--models", str(models), "--out", str(out))
        self.assertEqual((code, err), (0, ""))
        self.assertEqual(sorted(p.name for p in out.iterdir()), ["Tiny.bbmodel"])
        self.assertIn("Tiny: 1 meshes, 8 faces", stdout)
        self.assertEqual(quiet("--species", "Chair", "--models", str(models), "--out", str(out))[0], 0)
        self.assertTrue((out / "Chair.bbmodel").is_file())
        self.assertEqual(quiet("--all", "--check", "--models", str(models), "--out", str(out))[0], 0)


if __name__ == "__main__":
    unittest.main()
