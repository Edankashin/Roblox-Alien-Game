"""Tests for tools/blocky/export_models.py --check (no Blender): the exported folders in assets/models against their notes and Rigs.luau.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'  (./tools/test.sh runs it too).
A copy of one real export is broken one way at a time (a part renamed, a pivot moved, the face turned round, the model lifted, a file
missing, materials.json out of order), and check_folder must name each fault; the repo's own folders must pass.
"""
from __future__ import annotations

import io
import json
import pathlib
import shutil
import struct
import sys
import tempfile
import unittest
from contextlib import redirect_stdout

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
import export_models as X  # noqa: E402
import spec as S  # noqa: E402

SID = "Mossbop"
SOURCE = ROOT / "assets/models" / SID
EXPORTED = (SOURCE / (SID + "_atlas.png")).exists()


def repack(path, edit):
    """Rewrite a GLB's JSON chunk through `edit(doc)`, keeping its binary chunk."""
    doc, binary = X.read_glb(path)
    edit(doc)
    text = json.dumps(doc).encode()
    text += b" " * (-len(text) % 4)
    binary += b"\0" * (-len(binary) % 4)
    body = struct.pack("<I4s", len(text), b"JSON") + text + struct.pack("<I4s", len(binary), b"BIN\0") + binary
    pathlib.Path(path).write_bytes(struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body)


def node(doc, name):
    return next(n for n in doc["nodes"] if n.get("name") == name)


@unittest.skipUnless(EXPORTED, "assets/models/Mossbop is not a block-cell export in this checkout")
class CheckFolder(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = S.load(ROOT / "docs/vault/07-alien-game/Creatures" / (SID + ".md"))
        cls.row = X.luau_rigs()[SID]

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.folder = pathlib.Path(self._tmp.name) / SID
        shutil.copytree(SOURCE, self.folder)
        self.glb = self.folder / (SID + ".glb")

    def tearDown(self):
        self._tmp.cleanup()

    def problems(self):
        return X.check_folder(self.folder, self.spec, self.row)

    def assertNamed(self, words):
        found = self.problems()
        self.assertTrue(any(words in p for p in found), "expected %r in %r" % (words, found))

    def test_the_real_export_is_clean(self):
        self.assertEqual(self.problems(), [])

    def test_a_missing_file(self):
        (self.folder / (SID + "_face.png")).unlink()
        self.assertEqual(self.problems(), ["missing %s_face.png" % SID])

    def test_a_moving_part_renamed(self):
        repack(self.glb, lambda d: node(d, "sprout").update(name="Sprout"))
        self.assertNamed("no mesh named sprout")
        self.assertNamed("unexpected mesh Sprout")

    def test_a_pivot_off_its_rigs_row(self):
        def move(d):
            node(d, "floatR")["translation"][1] += 0.25
        repack(self.glb, move)
        self.assertNamed("floatR sits at")

    def test_the_face_turned_round(self):
        def turn(d):
            # mirror the plate's quad through z: its winding (normal) flips and it sits behind the head
            node(d, "FacePlate")["scale"] = [1, 1, -1]
        repack(self.glb, turn)
        self.assertNamed("carries a rotation or scale")

    def test_lifted_off_the_ground(self):
        def lift(d):
            for n in d["nodes"]:
                n["translation"] = [t + (0.5 if k == 1 else 0.0) for k, t in enumerate(n.get("translation", [0, 0, 0]))]
        repack(self.glb, lift)
        self.assertNamed("the feet are at y = 0.5000")

    def test_off_centre(self):
        def shift(d):
            for n in d["nodes"]:
                n["translation"] = [t + (0.3 if k == 0 else 0.0) for k, t in enumerate(n.get("translation", [0, 0, 0]))]
        repack(self.glb, shift)
        self.assertNamed("not the bottom centre")

    def test_taller_than_the_band_and_the_rig(self):
        def stretch(d):
            for mesh in d["meshes"]:
                for prim in mesh["primitives"]:
                    acc = d["accessors"][prim["attributes"]["POSITION"]]
                    acc["max"][1] *= 2.0
        repack(self.glb, stretch)
        self.assertNamed("outside 2 to 3.5")
        self.assertNamed("Rigs.luau says 2.475")

    def test_a_blurred_texture(self):
        repack(self.glb, lambda d: d["samplers"][0].update(magFilter=9729))
        self.assertNamed("not nearest")

    def test_materials_json_out_of_order(self):
        path = self.folder / "materials.json"
        entries = json.loads(path.read_text())
        entries.reverse()
        path.write_text(json.dumps(entries))
        self.assertNamed("materials.json names")

    def test_notes_disagree_on_triangles(self):
        path = self.folder / "notes.md"
        path.write_text(path.read_text().replace("- Triangles: ", "- Triangles: 9"))
        self.assertNamed("notes.md says")

    def test_a_face_sheet_of_the_wrong_size(self):
        shutil.copyfile(self.folder / (SID + "_atlas.png"), self.folder / (SID + "_face.png"))
        self.assertNamed("the Rigs.luau layout wants 84x16")


class Roster(unittest.TestCase):
    def test_a_note_on_the_old_format_is_pending(self):
        spec = S.load(ROOT / "docs/vault/07-alien-game/Creatures" / (SID + ".md"))
        old = dict(spec)
        old.pop("eyes", None)
        self.assertFalse(S.is_b46(old))

    def test_png_size_reads_the_header(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "x.png"
            path.write_bytes(b"\x89PNG\r\n\x1a\n" + struct.pack(">I4sII", 13, b"IHDR", 28, 16) + b"\0" * 9)
            self.assertEqual(X.png_size(path), (28, 16))
            path.write_bytes(b"GIF89a" + b"\0" * 20)
            with self.assertRaises(ValueError):
                X.png_size(path)

    def test_notes_triangles(self):
        self.assertEqual(X.notes_triangles("# x\n- Triangles: 214 (cap 2500)\n"), 214)
        self.assertIsNone(X.notes_triangles("# x\n- Height: 2\n"))


@unittest.skipUnless(EXPORTED, "assets/models holds no block-cell export in this checkout")
class TheRepo(unittest.TestCase):
    def test_every_exported_folder_passes_the_check(self):
        out = io.StringIO()
        with redirect_stdout(out):
            code = X.run_check()
        self.assertEqual(code, 0, out.getvalue())

    def test_every_note_is_on_b46_and_exported(self):
        ready, skipped = X.roster()
        self.assertEqual(skipped, [])
        for sid, _, _ in ready:
            with self.subTest(sid):
                self.assertTrue((ROOT / "assets/models" / sid / (sid + "_atlas.png")).exists())

    def test_the_installers_block_cell_table_is_fresh(self):
        source = (ROOT / "tools/studio/install_models.luau").read_text()
        start = source.index("-- BEGIN BLOCK-CELL PASTE")
        start = source.index("\n", start) + 1
        end = source.index("-- END BLOCK-CELL PASTE")
        self.assertEqual(source[start:end].strip(), X.emit_luau().strip(),
                         "paste `python3 -I tools/blocky/export_models.py --emit-luau` into tools/studio/install_models.luau")

    def test_no_texture_or_model_id_is_invented(self):
        self.assertNotRegex(X.emit_luau(), r"(cellMap|faceMap) = [1-9]")

    def test_asset_ids_marks_the_new_files_not_uploaded_and_invents_no_id(self):
        ids = json.loads((ROOT / "assets/models/asset_ids.json").read_text())
        ready, _ = X.roster()
        for sid, _, _ in ready:
            entry = ids.get(sid)
            if entry is None:
                continue
            with self.subTest(sid):
                self.assertIs(entry["pendingUpload"]["uploaded"], False)
                self.assertIn("assets/models/%s/%s.glb" % (sid, sid), entry["pendingUpload"]["files"])
                self.assertNotIn("assetId", entry["pendingUpload"])


if __name__ == "__main__":
    unittest.main()
