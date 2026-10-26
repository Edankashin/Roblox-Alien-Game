"""Tests for tools/blocky/sheet.py and tools/blocky/raster.py: the view projections, the painter's order, the frames and masks the Blender
build is scored against, the face's placement, the PNG writer and reader, and the SVG sheet.

Standard library only (./tools/test.sh runs it; no Blender, and no Pillow: the PNG sheet is not drawn here).
"""
from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
import unittest
import zlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))
_SH = importlib.util.spec_from_file_location("blocky_sheet", ROOT / "tools/blocky/sheet.py")
SH = importlib.util.module_from_spec(_SH)
_SH.loader.exec_module(SH)  # type: ignore[union-attr]
S = SH.S
R = SH.raster
CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"


def box_spec(parts, face=None):
    spec = {"front": {"id": "T", "palette": ["#808080", "#202020", "#101010"], "roles": ["body", "second", "ink"]},
            "parts": [S.normalise(p, i) for i, p in enumerate(parts)], "face": face}
    return spec


class Projection(unittest.TestCase):
    def test_axes(self):
        p = (1.0, 2.0, 3.0)
        self.assertEqual(SH.project("front", p), (-1.0, 2.0))  # from -Z: the creature's right (+X) is on the viewer's left
        self.assertEqual(SH.project("right", p), (-3.0, 2.0))  # from +X: the face (-Z) is on the right
        self.assertEqual(SH.project("back", p), (1.0, 2.0))
        self.assertEqual(SH.project("top", p), (-1.0, 3.0))  # from above: the front (-Z) is at the bottom

    def test_depth_is_away_from_the_viewer(self):
        near, far = (0, 0, -1), (0, 0, 1)
        self.assertLess(SH.depth("front", near), SH.depth("front", far))
        self.assertLess(SH.depth("back", far), SH.depth("back", near))
        self.assertLess(SH.depth("right", (1, 0, 0)), SH.depth("right", (-1, 0, 0)))
        self.assertLess(SH.depth("top", (0, 2, 0)), SH.depth("top", (0, 1, 0)))

    def test_rotated_part_polygon_is_its_hull(self):
        part = S.normalise({"name": "A", "slot": "Body", "size": [1, 1, 1], "at": [0, 0.5, 0], "rot": [0, 0, 20]})
        poly = SH.part_polygon("front", part)
        self.assertEqual(len(poly), 4)
        part2 = dict(part, rot=[0, 0, 0])
        self.assertEqual(sorted(SH.part_polygon("front", part2)), [(-0.5, 0.0), (-0.5, 1.0), (0.5, 0.0), (0.5, 1.0)])


class Painter(unittest.TestCase):
    def test_a_band_round_a_mass_is_hidden_by_the_mass_from_behind(self):
        spec = box_spec([
            {"name": "Torso", "slot": "Body", "size": [1.75, 1.5, 2.5], "at": [0, 1.25, 1.125], "bevel": True},
            {"name": "Band", "slot": "BodyDark", "size": [2, 1.75, 0.25], "at": [0, 1.25, 1.875]},
        ])
        order = [payload[0]["name"] for _, kind, payload in SH.view_items(spec, "back") if kind == "part"]
        self.assertEqual(order, ["Band", "Torso"])  # the torso's back face is nearer than the band, so it is drawn last
        order = [payload[0]["name"] for _, kind, payload in SH.view_items(spec, "front") if kind == "part"]
        self.assertEqual(order, ["Band", "Torso"])  # from the front too: only its rim shows round the torso
        order = [payload[0]["name"] for _, kind, payload in SH.view_items(spec, "right") if kind == "part"]
        self.assertEqual(order, ["Torso", "Band"])  # from the side it stands proud of the torso's flank

    def test_face_is_drawn_on_the_head_before_parts_in_front_of_it(self):
        face = {"host": "Head", "legend": {".": "body", "k": "ink"}, "rows": ["k" + "." * 15] + ["." * 16] * 7}
        spec = box_spec([
            {"name": "Head", "slot": "Body", "size": [2, 1, 1], "at": [0, 1, 0]},
            {"name": "Gem", "slot": "BodyDark", "size": [0.5, 0.25, 0.125], "at": [0, 1.25, -0.5625]},
        ], face)
        kinds = [(kind, payload[0]["name"] if kind == "part" else "") for _, kind, payload in SH.view_items(spec, "front")]
        self.assertEqual(kinds, [("part", "Head"), ("face", ""), ("part", "Gem")])


class Face(unittest.TestCase):
    def test_column_zero_is_the_creatures_right_side(self):
        face = {"host": "Head", "legend": {".": "body", "k": "ink"}, "rows": ["k" + "." * 15] + ["." * 16] * 7}
        spec = box_spec([{"name": "Head", "slot": "Body", "size": [2, 1, 1], "at": [0, 1.5, 0]}], face)
        cells = SH.face_cells(spec, S.face_host(spec))
        self.assertEqual(len(cells), 1)
        u0, v0, u1, v1, hexcol = cells[0]
        self.assertEqual((u0, u1), (-1.0, -0.875))  # front view u = -x: the head's +X edge, the viewer's left
        self.assertEqual((v0, v1), (1.875, 2.0))
        self.assertEqual(hexcol, "#101010")


class FramesAndMasks(unittest.TestCase):
    def setUp(self):
        self.spec = box_spec([{"name": "Block", "slot": "Body", "size": [2, 1, 1], "at": [1, 0.5, 0]}])

    def test_frames_contain_every_view(self):
        fr = SH.frames(self.spec)
        for view in SH.VIEWS:
            u0, u1, v0, v1 = SH.extents(view, S.expand(self.spec["parts"]))
            cu, cv = fr[view]["centre"]
            half = fr[view]["side"] / 2
            self.assertTrue(cu - half < u0 and u1 < cu + half and cv - half < v0 and v1 < cv + half, view)

    def test_mask_area_matches_the_box(self):
        frame = {"centre": [-1.0, 0.5], "side": 4.0}
        m = SH.view_mask(self.spec, "front", frame, size=200)
        # the 2 x 1 stud face in a 4-stud frame at 200 px is 100 x 50 px
        self.assertEqual(sum(m), 100 * 50)
        rows = [r for r in range(200) if any(m[r * 200:(r + 1) * 200])]
        self.assertEqual((rows[0], rows[-1]), (75, 124))

    def test_masks_of_the_prototypes_are_not_empty(self):
        for path in sorted(CREATURES.glob("*.md")):
            spec = S.load(path)
            fr = SH.frames(spec)
            for view in SH.VIEWS:
                m = SH.view_mask(spec, view, fr[view], size=64)
                self.assertGreater(sum(m), 64 * 64 * 0.05, "%s %s" % (path.name, view))


class Raster(unittest.TestCase):
    def test_fill_square_and_triangle(self):
        m = bytearray(100)
        R.fill_convex(m, 10, 10, [(2, 2), (6, 2), (6, 6), (2, 6)])
        self.assertEqual(sum(m), 16)
        t = bytearray(100)
        R.fill_convex(t, 10, 10, [(0, 0), (10, 0), (0, 10)])
        self.assertEqual(sum(t), 45)  # the centres strictly under the diagonal

    def test_hull(self):
        pts = [(0, 0), (1, 0), (1, 1), (0, 1), (0.5, 0.5), (0.2, 0.8)]
        self.assertEqual(sorted(R.hull(pts)), [(0, 0), (0, 1), (1, 0), (1, 1)])

    def test_iou(self):
        a, b = bytearray([1, 1, 0, 0]), bytearray([0, 1, 1, 0])
        self.assertAlmostEqual(R.iou(a, b), 1 / 3)
        self.assertEqual(R.iou(a, a), 1.0)
        self.assertEqual(R.iou(bytearray(4), bytearray(4)), 0.0)

    def test_png_round_trip(self):
        with tempfile.TemporaryDirectory() as d:
            m = bytearray(12 * 7)
            R.fill_convex(m, 12, 7, [(1, 1), (9, 1), (9, 5), (1, 5)])
            R.mask_png(d + "/m.png", 12, 7, m)
            w, h, back = R.png_mask(d + "/m.png")
            self.assertEqual((w, h), (12, 7))
            self.assertEqual(bytes(back), bytes(m))
            rgba = bytes([10, 20, 30, 255, 40, 50, 60, 0] * 3)
            R.write_png(d + "/c.png", 2, 3, rgba, 4)
            self.assertEqual(R.read_png(d + "/c.png"), (2, 3, 4, bytearray(rgba)))
            _, _, alpha = R.png_mask(d + "/c.png")
            self.assertEqual(list(alpha), [1, 0] * 3)

    def test_png_reader_undoes_every_row_filter(self):
        import struct
        w, h = 3, 5
        rows = [bytes([(r * 37 + c * 11) % 256 for c in range(w)]) for r in range(h)]

        def filt(kind, row, prev):
            out = bytearray()
            for x in range(w):
                left = row[x - 1] if x else 0
                up = prev[x]
                ul = prev[x - 1] if x else 0
                if kind == 0:
                    pred = 0
                elif kind == 1:
                    pred = left
                elif kind == 2:
                    pred = up
                elif kind == 3:
                    pred = (left + up) // 2
                else:
                    p = left + up - ul
                    pa, pb, pc = abs(p - left), abs(p - up), abs(p - ul)
                    pred = left if pa <= pb and pa <= pc else (up if pb <= pc else ul)
                out.append((row[x] - pred) & 255)
            return bytes([kind]) + bytes(out)

        raw, prev = b"", bytes(w)
        for r in range(h):
            raw += filt(r % 5, rows[r], prev)
            prev = rows[r]

        def chunk(kind, body):
            return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
        with tempfile.TemporaryDirectory() as d:
            pathlib.Path(d + "/f.png").write_bytes(png)
            self.assertEqual(bytes(R.read_png(d + "/f.png")[3]), b"".join(rows))


class Sheet(unittest.TestCase):
    def test_layout_shares_one_scale_and_baseline_left_to_right(self):
        spec = S.load(CREATURES / "Thunderhog.md")
        L = SH.layout(spec)
        xs = [L["panels"][v]["x"] for v in list(SH.VIEWS) + ["avatar"]]
        self.assertEqual(xs, sorted(xs))
        for a, b in zip(list(SH.VIEWS) + ["avatar"], (list(SH.VIEWS) + ["avatar"])[1:]):
            self.assertLessEqual(L["panels"][a]["x"] + L["panels"][a]["w"], L["panels"][b]["x"] + 1e-6)
        self.assertGreater(L["scale"], 0)
        self.assertAlmostEqual(L["height"], 3.375)   # Voltus after its B45 resize (Roster w1_high, 2026-10-21)

    def test_svg_sheet_has_every_view_and_the_numbers(self):
        spec = S.load(CREATURES / "Mossbop.md")
        with tempfile.TemporaryDirectory() as d:
            SH.draw_sheet(spec, SH.SvgCanvas).save(d + "/s.svg")
            svg = pathlib.Path(d + "/s.svg").read_text()
        for needle in ("FRONT (from -Z)", "RIGHT (from +X)", "TOP (front down)", "BACK (from +Z)", "AVATAR", "Moop", "H 2.87", "Face plate: `bean`", "#6CCB5F"):
            self.assertIn(needle, svg)
        parts = len(S.expand(spec["parts"]))
        self.assertGreaterEqual(svg.count("<polygon"), parts * 4)
        self.assertTrue(svg.startswith("<svg") and svg.rstrip().endswith("</svg>"))


if __name__ == "__main__":
    unittest.main()
