"""Tests for tools/blender/unwrap_bake.py (UV unwrap and palette bake), run on Sparkfox and Mossbop.

The tool needs Blender's Python module (bpy), which the plain Python these tests run under usually lacks, so the tool runs in a child
process: the current interpreter when it can import bpy, otherwise the Python named by the BPY_PYTHON environment variable. With neither
every test is skipped with that message (the way to run them: BPY_PYTHON=/path/to/python-with-bpy python3 -I -m unittest ...). Standard
library only here: the checks read the written GLB with tools/blockbench/to_bbmodel.py's reader and decode the palette PNG by hand, and
the overlap count is a second, independent (pure Python) rasteriser, so a bug in the tool's own raster does not hide itself.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import math
import os
import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
TOOL = ROOT / "tools/blender/unwrap_bake.py"
MODELS = ROOT / "assets/models"
SPECIES = ("Sparkfox", "Mossbop")
BLOCK_CELL = any((MODELS / s / (s + "_atlas.png")).exists() for s in SPECIES)
RETIRED = "assets/models holds the block-cell models now (tools/blocky/export_models.py, Decision B46); this tool was built for the retired blockouts"
SIZE = 512

_SPEC = importlib.util.spec_from_file_location("to_bbmodel", ROOT / "tools/blockbench/to_bbmodel.py")
bb = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(bb)  # type: ignore[union-attr]


def bpy_python():
    """A Python that can import bpy, or None."""
    if importlib.util.find_spec("bpy") is not None:
        return sys.executable
    named = os.environ.get("BPY_PYTHON")
    if named:
        probe = subprocess.run([named, "-c", "import bpy"], capture_output=True)
        if probe.returncode == 0:
            return named
    return None


PYTHON = bpy_python()
SKIP = "bpy is not importable here (pip install bpy, or set BPY_PYTHON to a Python that has it); the unwrap tests need Blender's module"


def run_tool(*args):
    return subprocess.run([PYTHON, str(TOOL), *args], capture_output=True, text=True, cwd=str(ROOT), timeout=600)


def decode_png(data):
    """(width, height, RGBA bytes) of an 8-bit RGBA PNG written with filter 0 or Sub (what the tool writes)."""
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    offset, idat = 8, b""
    while offset < len(data):
        size, tag = struct.unpack_from(">I4s", data, offset)
        body = data[offset + 8:offset + 8 + size]
        if tag == b"IHDR":
            width, height, depth, colour = struct.unpack(">IIBB", body[:10])
            assert (depth, colour) == (8, 6), "expected 8-bit RGBA"
        elif tag == b"IDAT":
            idat += body
        offset += 12 + size
    raw = zlib.decompress(idat)
    stride = width * 4 + 1
    rows = []
    for y in range(height):
        kind, line = raw[y * stride], bytearray(raw[y * stride + 1:(y + 1) * stride])
        assert kind in (0, 1), "unexpected PNG filter %d" % kind
        if kind == 1:
            for i in range(4, len(line)):
                line[i] = (line[i] + line[i - 4]) & 255
        rows.append(bytes(line))
    return width, height, b"".join(rows)


def srgb_to_linear(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_srgb_byte(c):
    c = min(max(c, 0.0), 1.0)
    return round(255 * (12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055))


def glb_uvs(glb):
    return [uv for prim in glb.primitives for uv in prim.uvs]


def overlap_share(glb, side=256):
    """Share of the covered texels that two triangles reach, by a plain-Python raster of pixel centres at `side` (independent of the tool)."""
    seen = {}
    for prim in glb.primitives:
        for a, b, c in prim.triangles:
            (ax, ay), (bx, by), (cx, cy) = ((prim.uvs[i][0] * side, prim.uvs[i][1] * side) for i in (a, b, c))
            den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(den) < 1e-12:
                continue
            for y in range(max(int(min(ay, by, cy)), 0), min(int(max(ay, by, cy)) + 1, side)):
                for x in range(max(int(min(ax, bx, cx)), 0), min(int(max(ax, bx, cx)) + 1, side)):
                    px, py = x + 0.5, y + 0.5
                    w0 = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / den
                    w1 = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / den
                    if w0 >= 0 and w1 >= 0 and 1 - w0 - w1 >= 0:
                        seen[(x, y)] = seen.get((x, y), 0) + 1
    return sum(1 for n in seen.values() if n > 1) / max(len(seen), 1)


@unittest.skipIf(PYTHON is None, SKIP)
@unittest.skipIf(BLOCK_CELL, RETIRED)
class UnwrapAndBake(unittest.TestCase):
    """Sparkfox and Mossbop through the tool once, into a temporary folder."""

    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory()
        cls.out = pathlib.Path(cls._tmp.name) / "out"
        cls.report = pathlib.Path(cls._tmp.name) / "report.json"
        cls.result = run_tool("--species", ",".join(SPECIES), "--out", str(cls.out), "--report", str(cls.report))
        assert cls.result.returncode == 0, cls.result.stdout[-1500:] + cls.result.stderr[-1500:]

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def entries(self, sid):
        return json.loads((MODELS / sid / "materials.json").read_text())

    def test_one_line_per_species_and_a_clean_exit(self):
        lines = [l for l in self.result.stdout.splitlines() if l.split(" ")[0] in SPECIES]
        self.assertEqual(len(lines), 2)
        for line, sid in zip(lines, SPECIES):
            self.assertTrue(line.startswith(sid), line)
            self.assertIn(" ok ", line)
            self.assertIn("islands=", line)
            self.assertIn("coverage=", line)

    def test_the_files_are_written(self):
        for sid in SPECIES:
            for name in (sid + ".glb", sid + ".fbx", sid + "_palette.png", "materials.json", "notes.md"):
                self.assertTrue((self.out / sid / name).is_file(), (sid, name))
            self.assertEqual((self.out / sid / "materials.json").read_text(), (MODELS / sid / "materials.json").read_text())

    def test_every_uv_is_inside_0_to_1(self):
        for sid in SPECIES:
            with self.subTest(sid):
                glb = bb.read_glb(self.out / sid / (sid + ".glb"))
                uvs = glb_uvs(glb)
                self.assertTrue(uvs)
                self.assertGreaterEqual(min(min(uv) for uv in uvs), -1e-5)
                self.assertLessEqual(max(max(uv) for uv in uvs), 1 + 1e-5)

    def test_the_islands_do_not_overlap(self):
        for sid in SPECIES:
            with self.subTest(sid):
                glb = bb.read_glb(self.out / sid / (sid + ".glb"))
                self.assertLess(overlap_share(glb), 0.01)

    def test_triangles_slots_height_and_pivot_are_unchanged(self):
        for sid in SPECIES:
            with self.subTest(sid):
                before, after = bb.read_glb(MODELS / sid / (sid + ".glb")), bb.read_glb(self.out / sid / (sid + ".glb"))
                self.assertEqual(after.triangle_count, before.triangle_count)
                self.assertEqual([m["name"] for m in after.materials], [m["name"] for m in before.materials])
                self.assertEqual([m["name"] for m in after.materials], [e["name"] for e in self.entries(sid)])

                def per_slot(glb):
                    counts = {}
                    for prim in glb.primitives:
                        name = glb.materials[prim.material]["name"]
                        counts[name] = counts.get(name, 0) + len(prim.triangles)
                    return counts

                self.assertEqual(per_slot(after), per_slot(before))
                for axis in range(3):
                    for pick in (min, max):
                        a = pick(p[axis] for prim in before.primitives for p in prim.positions)
                        b = pick(p[axis] for prim in after.primitives for p in prim.positions)
                        self.assertAlmostEqual(a, b, places=3, msg=(sid, axis, pick.__name__))

    def test_vertex_colours_still_travel_in_the_glb(self):
        for sid in SPECIES:
            with self.subTest(sid):
                glb = bb.read_glb(self.out / sid / (sid + ".glb"))
                reds = [c[0] for prim in glb.primitives for c in (prim.colors or [])]
                self.assertTrue(reds)
                self.assertAlmostEqual(min(reds), 0.57, delta=0.02)  # the Surface pass gradient, 0.57 at the belly
                self.assertAlmostEqual(max(reds), 1.0, delta=0.01)

    def test_the_palette_is_512_square_rgba(self):
        for sid in SPECIES:
            with self.subTest(sid):
                width, height, pixels = decode_png((self.out / sid / (sid + "_palette.png")).read_bytes())
                self.assertEqual((width, height), (SIZE, SIZE))
                opaque = sum(1 for i in range(3, len(pixels), 4) if pixels[i] == 255)
                self.assertGreater(opaque, 0.4 * SIZE * SIZE)
                self.assertLess(opaque, SIZE * SIZE)  # the space between islands stays transparent

    def test_triangles_sample_their_slot_colour_times_the_gradient(self):
        """At each big triangle's UV centre the palette holds the slot hex times the mean vertex gradient (linear light), within a few levels."""
        for sid in SPECIES:
            with self.subTest(sid):
                width, _, pixels = decode_png((self.out / sid / (sid + "_palette.png")).read_bytes())
                glb = bb.read_glb(self.out / sid / (sid + ".glb"))
                checked = good = 0
                for slot in bb.build_slots(glb, self.entries(sid)):
                    base = [srgb_to_linear(int(slot.hex[i:i + 2], 16)) for i in (0, 2, 4)]
                    for prim in slot.primitives:
                        for tri in prim.triangles:
                            (ax, ay), (bx, by), (cx, cy) = (prim.uvs[i] for i in tri)
                            area = 0.5 * abs((bx - ax) * (cy - ay) - (by - ay) * (cx - ax)) * SIZE * SIZE
                            if area < 6:
                                continue
                            u, v = (ax + bx + cx) / 3, (ay + by + cy) / 3
                            offset = (int(v * SIZE) * width + int(u * SIZE)) * 4
                            mean = sum(prim.colors[i][0] for i in tri) / 3
                            expected = [linear_to_srgb_byte(b * mean) for b in base]
                            checked += 1
                            good += all(abs(pixels[offset + k] - expected[k]) <= 8 for k in range(3)) and pixels[offset + 3] == 255
                self.assertGreater(checked, 200)
                self.assertGreater(good / checked, 0.97, (good, checked))

    def test_a_flat_slot_is_its_exact_hex(self):
        """The Pupil has no gradient (COLOR_0 is 1.0 there): its texels are materials.json's hex, byte for byte."""
        sid = "Sparkfox"
        width, _, pixels = decode_png((self.out / sid / (sid + "_palette.png")).read_bytes())
        glb = bb.read_glb(self.out / sid / (sid + ".glb"))
        pupil = next(s for s in bb.build_slots(glb, self.entries(sid)) if s.name == "Pupil")
        want = tuple(int(pupil.hex[i:i + 2], 16) for i in (0, 2, 4))
        hits = 0
        for prim in pupil.primitives:
            for tri in prim.triangles:
                (ax, ay), (bx, by), (cx, cy) = (prim.uvs[i] for i in tri)
                if 0.5 * abs((bx - ax) * (cy - ay) - (by - ay) * (cx - ax)) * SIZE * SIZE < 6:
                    continue
                offset = (int(((ay + by + cy) / 3) * SIZE) * width + int(((ax + bx + cx) / 3) * SIZE)) * 4
                hits += tuple(pixels[offset:offset + 3]) == want
        self.assertGreater(hits, 0)

    def test_notes_record_islands_coverage_and_the_bake(self):
        report = {r["id"]: r for r in json.loads(self.report.read_text())["species"]}
        for sid in SPECIES:
            with self.subTest(sid):
                notes = (self.out / sid / "notes.md").read_text()
                line = next(l for l in notes.splitlines() if l.startswith("- UV unwrap and palette bake"))
                self.assertIn("%d islands" % report[sid]["islands"], line)
                self.assertIn("angle limit 66", line)
                self.assertIn("island margin", line)
                self.assertIn("512 px", line)
                self.assertIn("percent of the 512 px texture covered", line)
                self.assertIn("- Triangles:", notes)  # the input's own notes are kept
                self.assertEqual(report[sid]["problems"], [])
                self.assertGreater(report[sid]["islands"], 50)
                self.assertGreater(report[sid]["coverage"], 20.0)
                self.assertLess(report[sid]["overlap"], 1.0)

    def test_to_bbmodel_reads_the_palette(self):
        with tempfile.TemporaryDirectory() as tmp:
            for sid in SPECIES:
                target, summary = bb.write_species(self.out, sid, pathlib.Path(tmp), 128, True)
                self.assertIn("512x512 baked palette", summary)
                project = json.loads(target.read_text())
                self.assertEqual(project["resolution"], {"width": SIZE, "height": SIZE})
                self.assertEqual(bb.check_file(target), [])
                faces = sum(len(e["faces"]) for e in project["elements"])
                self.assertEqual(faces, bb.read_glb(self.out / sid / (sid + ".glb")).triangle_count)


@unittest.skipIf(PYTHON is None, SKIP)
class Guards(unittest.TestCase):
    def sha(self, path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def test_assets_models_is_refused_without_write_assets(self):
        before = {p: self.sha(p) for p in (MODELS / "Sparkfox").iterdir()}
        result = run_tool("--species", "Sparkfox", "--out", str(MODELS))
        self.assertEqual(result.returncode, 2, result.stdout[-500:])
        self.assertIn("--write-assets", result.stderr)
        self.assertEqual({p: self.sha(p) for p in (MODELS / "Sparkfox").iterdir()}, before)
        inside = run_tool("--species", "Sparkfox", "--out", str(MODELS / "scratch"))
        self.assertEqual(inside.returncode, 2)
        self.assertFalse((MODELS / "scratch").exists())

    def test_out_is_required_without_write_assets(self):
        result = run_tool("--species", "Sparkfox")
        self.assertEqual(result.returncode, 2)
        self.assertIn("--out is required", result.stderr)

    def test_write_assets_writes_over_a_models_folder_and_nothing_else(self):
        real = {p: self.sha(p) for p in (MODELS / "Sparkfox").iterdir()}
        with tempfile.TemporaryDirectory() as tmp:
            models = pathlib.Path(tmp) / "models"
            shutil.copytree(MODELS / "Sparkfox", models / "Sparkfox")
            input_glb = self.sha(models / "Sparkfox" / "Sparkfox.glb")
            result = run_tool("--species", "Sparkfox", "--models", str(models), "--write-assets")
            self.assertEqual(result.returncode, 0, result.stdout[-1500:] + result.stderr[-1500:])
            folder = models / "Sparkfox"
            self.assertTrue((folder / "Sparkfox_palette.png").is_file())
            self.assertNotEqual(self.sha(folder / "Sparkfox.glb"), input_glb)  # unwrapped in place
            glb = bb.read_glb(folder / "Sparkfox.glb")
            self.assertLessEqual(max(max(uv) for uv in glb_uvs(glb)), 1 + 1e-5)
            self.assertEqual(sum(1 for l in (folder / "notes.md").read_text().splitlines() if l.startswith("- UV unwrap and palette bake")), 1)
            again = run_tool("--species", "Sparkfox", "--models", str(models), "--write-assets")  # a second run replaces the line, not repeats it
            self.assertEqual(again.returncode, 0)
            self.assertEqual(sum(1 for l in (folder / "notes.md").read_text().splitlines() if l.startswith("- UV unwrap and palette bake")), 1)
            self.assertEqual(run_tool("--species", "Sparkfox", "--models", str(models), "--write-assets", "--out", tmp).returncode, 2)
        self.assertEqual({p: self.sha(p) for p in (MODELS / "Sparkfox").iterdir()}, real)  # the repo's own files were never touched

    def test_an_unknown_species_fails_with_a_message_and_exit_1(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = run_tool("--species", "NoSuchSpecies", "--out", tmp)
            self.assertEqual(result.returncode, 1)
            self.assertIn("NoSuchSpecies", result.stdout)
            self.assertIn("FAILED", result.stdout)


if __name__ == "__main__":
    unittest.main()
