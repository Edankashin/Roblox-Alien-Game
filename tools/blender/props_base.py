#!/usr/bin/env python3
"""Procedural scenery and camp props: 16 low-poly meshes for ReplicatedStorage.Models.Props, as GLB and FBX.

The sibling of alien_base.py. The game looks these up by exact name (src/shared/Props.luau, the world builders,
the camp renderer, the Heaters service) and falls back to part-built placeholders when one is missing, so the
names, footprints and pivots below are a contract with the layouts' scatter spacing. See
docs/vault/06-art-pipelines/Map-Dressing.md for the whole workflow.

Conventions (same as alien_base.py): Z-up, 1 Blender unit = 1 stud, the prop stands on z = 0 with its pivot at
the bottom centre (trees: the trunk axis). Flat Principled materials, one per colour, no textures. All parts are
joined into ONE mesh object named after the prop with its material slots kept, so Studio's Import 3D makes one
MeshPart per material. Faces are flat shaded. Rocks and crowns get a slight deterministic vertex jitter (seeded by
the prop name) so a re-run never changes a file. The glTF and FBX exporters convert to Y-up with their defaults:
Blender +Y (the ship's length, the table's depth) becomes Roblox Z.

Usage (plain Python with the bpy module, or inside a Blender binary):
    python3 tools/blender/props_base.py [--props MeadowTree,IceRock] [--out assets/models/props] [--all]
    blender -b -P tools/blender/props_base.py -- --all

Output per prop: assets/models/props/<Name>/<Name>.glb, <Name>.fbx, notes.md, materials.json (written by
alien_base.export through write_materials_json, so species and props share one format).
Budget 300 to 900 triangles per prop since the 2026-10-06 look pass (trees are placed about 30 times per world). Exit code 1 when any prop is over
900, 3 when a footprint misses the size the game's placeholders use, 2 for an unknown prop name.
"""
import argparse
import datetime
import math
import pathlib
import random
import sys
import zlib

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from alien_base import export, hex_to_rgb, make_material, triangle_count  # noqa: E402

TOOL_NAME = "tools/blender/props_base.py, bpy %s" % bpy.app.version_string
TRI_MIN = 300
TRI_MAX = 900
GLOW_STRENGTH = 2.0


# ------------------------------------------------------------------------------------- profile helpers
def circ(n, rx, ry=None, cx=0.0, cy=0.0, rot=0.0):
    """n points of an ellipse, counter-clockwise seen from +Z. Use n in {4, 8, 12, 16} so the bounds are exact."""
    ry = rx if ry is None else ry
    return [(cx + rx * math.cos(rot + 2 * math.pi * k / n), cy + ry * math.sin(rot + 2 * math.pi * k / n)) for k in range(n)]


def rect(hx, hy, cx=0.0, cy=0.0):
    return [(cx + hx, cy - hy), (cx + hx, cy + hy), (cx - hx, cy + hy), (cx - hx, cy - hy)]


def chamfered(hx, hy, c):
    """A rectangle with its four corners cut by c: eight points, counter-clockwise."""
    return [(hx, -(hy - c)), (hx, hy - c), (hx - c, hy), (-(hx - c), hy),
            (-hx, hy - c), (-hx, -(hy - c)), (-(hx - c), -hy), (hx - c, -hy)]


def rrect(hx, hy, r, seg=4):
    """A rounded rectangle, 4 * (seg + 1) points, counter-clockwise, starting on the bottom-right corner."""
    pts = []
    for cx, cy, a0 in ((hx - r, -(hy - r), -90), (hx - r, hy - r, 0), (-(hx - r), hy - r, 90), (-(hx - r), -(hy - r), 180)):
        for k in range(seg + 1):
            a = math.radians(a0 + 90.0 * k / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def scaled(pts, sx, sy=None):
    sy = sx if sy is None else sy
    return [(x * sx, y * sy) for x, y in pts]


def rot_z(deg):
    return Matrix.Rotation(math.radians(deg), 4, "Z")


def rot_y(deg):
    return Matrix.Rotation(math.radians(deg), 4, "Y")


def move(x, y, z):
    return Matrix.Translation((x, y, z))


# ------------------------------------------------------------------------------------------- the builder
class Prop:
    """One prop under construction: a single bmesh, a list of material slots, a seeded random source."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.mats = {}  # material name -> (hex, make_material kwargs), in slot order
        self.rng = random.Random(zlib.crc32(name.encode()))

    def material(self, name, hex_str, **kw):
        self.mats[name] = (hex_str, kw)

    def _slot(self, mat):
        return list(self.mats).index(mat)

    def tag(self, verts, mat):
        idx = self._slot(mat)
        for v in verts:
            for f in v.link_faces:
                f.material_index = idx

    # ---- primitives: each returns the new vertices so the caller can move, jitter or fit them -----------
    def loft(self, rings, mat, caps=(False, True), cap_mats=None):
        """Skin a stack of rings. rings = [(z, [(x, y), ...]), ...] bottom to top, counter-clockwise from +Z, all
        with the same point count except an apex ring of a single point. mat is a material name or one name per
        interval. caps = (bottom, top): the bottom cap faces down, the top cap faces up (a dish floor is a top cap)."""
        bm = self.bm
        rv = [[bm.verts.new((x, y, z)) for x, y in pts] for z, pts in rings]
        intervals = len(rings) - 1
        mats = list(mat) if isinstance(mat, (list, tuple)) else [mat] * intervals
        for i in range(intervals):
            a, b, idx = rv[i], rv[i + 1], self._slot(mats[i])
            for k in range(max(len(a), len(b))):
                quad = [a[k % len(a)], a[(k + 1) % len(a)], b[(k + 1) % len(b)], b[k % len(b)]]
                quad = list(dict.fromkeys(quad))  # an apex collapses a quad into a triangle
                if len(quad) >= 3:
                    bm.faces.new(quad).material_index = idx
        cm = cap_mats or (mats[0], mats[-1])
        if caps[0] and len(rv[0]) > 2:
            bm.faces.new(list(reversed(rv[0]))).material_index = self._slot(cm[0])
        if caps[1] and len(rv[-1]) > 2:
            bm.faces.new(rv[-1]).material_index = self._slot(cm[1])
        return [v for ring in rv for v in ring]

    def ico(self, level, mat, jitter=0.0, rot=0.0):
        """Unit icosphere, level 0 = 20 triangles, 1 = 80, 2 = 320. Jitter is a fraction of the radius."""
        verts = bmesh.ops.create_icosphere(self.bm, subdivisions=level + 1, radius=1.0)["verts"]
        spin = rot_z(rot)
        for v in verts:
            v.co = spin @ v.co
            if jitter:
                v.co *= 1.0 + self.rng.uniform(-jitter, jitter)
                v.co += Vector([self.rng.uniform(-jitter, jitter) for _ in range(3)]) * 0.5
        self.tag(verts, mat)
        return verts

    def box(self, mat, size, centre, rz=0.0, ry=0.0):
        verts = bmesh.ops.create_cube(self.bm, size=1.0)["verts"]
        m = move(*centre) @ rot_z(rz) @ rot_y(ry) @ Matrix.Diagonal((size[0], size[1], size[2], 1.0))
        self.place(verts, m)
        self.tag(verts, mat)
        return verts

    # ---- edits -----------------------------------------------------------------------------------------
    @staticmethod
    def place(verts, matrix):
        for v in verts:
            v.co = matrix @ v.co

    @staticmethod
    def bounds(verts):
        xs, ys, zs = [v.co.x for v in verts], [v.co.y for v in verts], [v.co.z for v in verts]
        return Vector((min(xs), min(ys), min(zs))), Vector((max(xs), max(ys), max(zs)))

    def fit(self, verts, size, centre):
        """Scale the verts' bounding box to exactly `size` and put its centre on `centre`."""
        lo, hi = self.bounds(verts)
        for v in verts:
            v.co = Vector((
                centre[0] + (v.co.x - (lo.x + hi.x) / 2) * size[0] / (hi.x - lo.x),
                centre[1] + (v.co.y - (lo.y + hi.y) / 2) * size[1] / (hi.y - lo.y),
                centre[2] + (v.co.z - (lo.z + hi.z) / 2) * size[2] / (hi.z - lo.z)))

    @staticmethod
    def flatten(verts, below):
        """Squash every vertex under `below` onto z = 0 so a boulder sits flat instead of balancing on a pole."""
        for v in verts:
            if v.co.z < below:
                v.co.z = 0.0

    def retag(self, verts, mat, test):
        """Move the faces of `verts` that pass test(face) to another material (a moss cap on top faces)."""
        idx = self._slot(mat)
        seen = set()
        for v in verts:
            for f in v.link_faces:
                if f not in seen:
                    seen.add(f)
                    f.normal_update()
                    if test(f):
                        f.material_index = idx

    def finish(self):
        """Join everything into one mesh object named after the prop, flat shaded, with a slot per material."""
        bm = self.bm
        bm.normal_update()
        for f in bm.faces:
            f.smooth = False
        me = bpy.data.meshes.new(self.name)
        bm.to_mesh(me)
        bm.free()
        for name, (hex_str, kw) in self.mats.items():
            mat = make_material(name, hex_to_rgb(hex_str), **kw)
            me.materials.append(mat)
        me.update()
        obj = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        return obj


# ----------------------------------------------------------------------------------------------- recipes
def trunk(p, height, r_base=1.2, r_top=1.0, flare=1.45):
    """A 10-sided trunk with a root flare at the foot; the top is inside the crown, so no caps are built."""
    p.loft([(0.0, circ(10, r_base * flare)), (0.5, circ(10, r_base * 1.08)), (1.4, circ(10, r_base)), (height, circ(10, r_top))],
           "Trunk", caps=(False, False))


def mark(p):
    """The vertex count now; bmesh appends new vertices, so added(p, mark) is everything built since."""
    return len(p.bm.verts)


def added(p, start):
    """The vertices created since mark() returned `start`. bmesh ops can invalidate vertex lists an earlier op
    returned, so multi-part fits gather their verts by index instead."""
    p.bm.verts.ensure_lookup_table()
    return [p.bm.verts[i] for i in range(start, len(p.bm.verts))]


def crown(p, lobes, size, centre):
    """Several jittered leaf lobes fitted together to one bounding box, so the silhouette is lumpy, not a ball."""
    before = mark(p)
    for level, (cx, cy, cz), r, rot in lobes:
        m = mark(p)
        p.ico(level, "Leaves", jitter=0.07, rot=rot)
        p.fit(added(p, m), (2 * r, 2 * r, 1.8 * r), (cx, cy, cz))
    verts = added(p, before)
    p.fit(verts, size, centre)
    return verts


def chip(verts, normal, keep):
    """One chipped edge: every vertex beyond `keep` along `normal` is pushed back onto that plane (a flat facet)."""
    n = Vector(normal).normalized()
    for v in verts:
        d = v.co.dot(n)
        if d > keep:
            v.co -= n * (d - keep)


def meadow_tree(p):
    p.material("Trunk", "7B4A2D")
    p.material("Leaves", "3F9B3A")
    trunk(p, 8.0)
    crown(p, [(2, (0.0, 0.0, 0.0), 3.0, 11), (1, (-2.2, 0.8, -0.6), 2.0, 40), (1, (2.0, -0.9, -0.3), 2.1, 75)],
          (8.0, 8.0, 7.2), (0.0, 0.0, 10.4))


def meadow_tree_b(p):
    p.material("Trunk", "7B4A2D")
    p.material("Leaves", "3F9B3A")
    trunk(p, 10.0)
    branch = p.loft([(0.0, circ(6, 0.45)), (2.6, circ(6, 0.3))], "Trunk", caps=(False, False))
    p.place(branch, move(0.2, 0.0, 8.2) @ rot_y(42))
    crown(p, [(2, (-1.0, 0.0, 0.0), 3.4, 5), (1, (2.4, 0.4, 1.4), 2.5, 20), (1, (0.6, -1.2, 2.4), 2.0, 60)],
          (9.2, 7.0, 7.1), (0.1, 0.0, 12.55))


def snow_pine(p):
    p.material("Trunk", "7A8C96")
    p.material("Snow", "DDEFF5")
    trunk(p, 9.0, flare=1.6)
    # four drooping tiers with a jagged sixteen-point fringe; the bottom tier reaches radius 4.5 (the footprint)
    for z0, radius, height, spin in ((2.6, 4.5, 4.4, 0.0), (5.2, 3.7, 4.2, 11.0), (7.8, 2.9, 4.0, 22.0), (10.4, 2.0, 4.6, 33.0)):
        star = [(x * (1.0 if k % 2 == 0 else 0.84), y * (1.0 if k % 2 == 0 else 0.84))
                for k, (x, y) in enumerate(circ(16, radius, rot=math.radians(spin)))]
        p.loft([(z0, star), (z0 + 0.35, scaled(star, 0.82)), (z0 + height, [(0.0, 0.0)])], "Snow", caps=(True, False))
    mound = p.ico(1, "Snow", jitter=0.05, rot=7)
    p.fit(mound, (4.2, 4.2, 1.2), (0.0, 0.0, 0.3))
    p.flatten(mound, 0.3)


def ice_spire(p):
    p.material("Ice", "A9D8EA")
    p.material("IceTip", "E8F7FD")

    def shard(x, y, height, base, lean, spin, sides=8):
        # a tapered prism with a two-step faceted tip in the lighter material; the lean shears the top away from the
        # base, so the foot stays flat on z = 0
        lx, ly = lean
        rings = [
            (0.0, circ(sides, base, cx=x, cy=y, rot=spin)),
            (0.45 * height, circ(sides, base * 0.82, cx=x + lx * 0.45, cy=y + ly * 0.45, rot=spin + 0.1)),
            (0.72 * height, circ(sides, base * 0.55, cx=x + lx * 0.72, cy=y + ly * 0.72, rot=spin + 0.18)),
            (0.88 * height, circ(sides, base * 0.25, cx=x + lx * 0.88, cy=y + ly * 0.88, rot=spin + 0.25)),
            (height, [(x + lx, y + ly)]),
        ]
        p.loft(rings, ["Ice", "Ice", "IceTip", "IceTip"], caps=(True, False))

    shard(0.0, 0.0, 10.0, 2.0, (0.25, 0.1), 0.0)
    shard(2.3, 0.7, 5.0, 1.1, (1.1, 0.4), 0.3)
    shard(-1.9, -1.0, 3.5, 0.85, (-0.9, -0.55), 0.6)
    shard(0.9, -1.8, 2.6, 0.7, (0.5, -0.8), 0.9, sides=6)
    shard(-1.1, 1.6, 4.2, 0.8, (-0.7, 0.9), 1.2, sides=6)
    base = p.ico(1, "Ice", jitter=0.12, rot=17)
    p.fit(base, (4.2, 3.4, 1.0), (0.0, 0.0, 0.3))
    p.flatten(base, 0.3)


def boulder(p, mat, level, size, jitter, flat, rot):
    verts = p.ico(level, mat, jitter=jitter, rot=rot)
    p.fit(verts, size, (0.0, 0.0, size[2] / 2))
    p.flatten(verts, flat * size[2])
    return verts


def settle(p, verts, size):
    """Fit a multi-part rock (every vertex of the prop) to its exact footprint, resting face on z = 0."""
    p.fit(added(p, 0), size, (0.0, 0.0, size[2] / 2))


def meadow_rock(p):
    p.material("Rock", "8E8E8E")
    v = boulder(p, "Rock", 2, (4.0, 4.0, 2.8), 0.09, 0.22, 0)
    chip(v, (0.7, -0.5, 0.5), 1.9)
    settle(p, v, (4.0, 4.0, 2.8))


def meadow_rock_b(p):
    p.material("Rock", "8E8E8E")
    p.material("Moss", "3F9B3A")
    v = boulder(p, "Rock", 2, (5.0, 4.0, 2.0), 0.09, 0.25, 36)
    chip(v, (-0.6, 0.6, 0.4), 1.6)
    m = mark(p)
    p.ico(1, "Rock", jitter=0.12, rot=12)
    pebble = added(p, m)
    p.fit(pebble, (1.4, 1.2, 0.8), (2.0, -1.3, 0.35))
    p.flatten(pebble, 0.15)
    settle(p, None, (5.0, 4.0, 2.0))
    p.bm.verts.ensure_lookup_table()
    p.retag([p.bm.verts[i] for i in range(m)], "Moss", lambda f: f.normal.z > 0.55 and f.calc_center_median().z > 0.45 * 2.0)


def ice_rock(p):
    p.material("IceRock", "A9B7C0")
    v = boulder(p, "IceRock", 2, (4.0, 4.0, 3.0), 0.12, 0.35, 0)
    chip(v, (0.4, 0.6, 0.7), 1.8)
    chip(v, (-0.8, -0.2, 0.3), 1.5)
    for size, centre, rot in (((1.6, 1.5, 1.3), (1.05, -0.95, 0.65), 20), ((1.2, 1.2, 1.0), (-1.0, 1.0, 0.5), 50)):
        m = mark(p)
        p.ico(1, "IceRock", jitter=0.14, rot=rot)
        chunk = added(p, m)
        p.fit(chunk, size, centre)
        p.flatten(chunk, 0.35 * size[2])
    settle(p, None, (4.0, 4.0, 3.0))


def ice_rock_b(p):
    p.material("IceRock", "A9B7C0")
    v = boulder(p, "IceRock", 2, (3.0, 3.0, 4.0), 0.1, 0.25, 24)
    chip(v, (0.8, -0.5, 0.35), 2.2)
    chip(v, (-0.7, 0.5, 0.2), 1.4)
    settle(p, v, (3.0, 3.0, 4.0))


def geyser_cone(p):
    p.material("Cone", "8C5A3C")
    p.material("Rim", "B07A55")
    p.material("Crater", "4A2E1E")
    mid = [(x * f, y * f) for (x, y), f in zip(circ(12, 2.15), (p.rng.uniform(0.93, 1.07) for _ in range(12)))]
    # outer slope, the pale rim ring on top, the dark dish wall sinking 1 unit, then the dish floor as the top cap
    rings = [
        (0.0, circ(12, 3.0)),
        (3.4, mid),
        (7.0, circ(12, 1.4)),
        (7.0, circ(12, 1.0)),
        (6.0, circ(12, 0.75)),
    ]
    p.loft(rings, ["Cone", "Cone", "Rim", "Crater"], caps=(False, True), cap_mats=("Cone", "Crater"))


def shrine_stone(p):
    p.material("Stone", "9E9E8E")  # one material: the game tints the stone per world
    base = chamfered(1.0, 0.625, 0.22)
    rings = [(0.0, base), (3.7, scaled(base, 0.88)), (4.55, scaled(base, 0.78)), (5.0, scaled(base, 0.58))]
    p.loft(rings, "Stone", caps=(False, True))


def pedestal(p):
    p.material("Stone", "C8C4A8")
    # a 1.0 tall disc of radius 2.5 under a 0.5 tall disc of radius 2.0, both with a small bevel
    rings = [
        (0.0, circ(16, 2.35)), (0.12, circ(16, 2.5)), (0.88, circ(16, 2.5)), (1.0, circ(16, 2.35)),
        (1.0, circ(16, 1.9)), (1.12, circ(16, 2.0)), (1.38, circ(16, 2.0)), (1.5, circ(16, 1.85)),
    ]
    p.loft(rings, "Stone", caps=(False, True))


def ship_hull(p):
    p.material("Plate", "5B6472")
    p.material("Lip", "8A93A0")
    p.material("Feet", "3A4049")
    hx, hy, corner = 6.0, 10.0, 2.5
    # the slab: z 0 to 0.5 with a bevelled underside; its top face is exactly z = 0.5, the plane the modules stack on
    p.loft([(0.0, rrect(hx - 0.25, hy - 0.25, corner - 0.25)), (0.2, rrect(hx, hy, corner)), (0.5, rrect(hx, hy, corner))],
           "Plate", caps=(True, True))
    # the rim lip: 0.25 above the plate (limit 0.3), 0.3 wide, flush with the slab edge
    p.loft([(0.5, rrect(hx, hy, corner)), (0.75, rrect(hx, hy, corner)),
            (0.75, rrect(hx - 0.3, hy - 0.3, corner - 0.3)), (0.5, rrect(hx - 0.3, hy - 0.3, corner - 0.3))],
           "Lip", caps=(False, False))
    # four skid feet from z = -0.4 up into the slab
    for fx in (-3.6, 3.6):
        for fy in (-6.5, 6.5):
            p.loft([(-0.4, rect(0.6, 1.5, fx, fy)), (0.0, rect(0.5, 1.3, fx, fy))], "Feet", caps=(True, False))


def gather_station(p):
    p.material("Top", "FFC83D")
    p.material("Legs", "A0722C")
    p.box("Top", (6.0, 1.7, 0.2), (0.0, 0.0, 1.4))                   # tabletop, top face at z = 1.5
    for side in (-1, 1):
        for off in (1.11, 1.38):                                       # two seat planks each side, seat top at z 0.7
            p.box("Top", (5.4, 0.24, 0.2), (0.0, side * off, 0.6))
    for lx in (-2.2, 2.2):                                            # an A-frame at each end
        for side in (-1, 1):
            p.loft([(0.0, rect(0.17, 0.14, lx, side * 1.36)), (1.3, rect(0.17, 0.12, lx, side * 0.4))], "Legs", caps=(True, False))
        p.box("Legs", (0.22, 2.1, 0.14), (lx, 0.0, 0.46))             # crossbar under the benches


def build_station(p):
    p.material("Wood", "8B5A2B")
    p.material("Plank", "C99A5B")
    p.material("Metal", "8A93A0", roughness=0.5, metallic=0.4)
    p.box("Wood", (5.0, 3.0, 0.4), (0.0, 0.0, 1.7))                  # heavy top, top face at z = 1.9
    for lx in (-2.05, 2.05):
        for ly in (-1.05, 1.05):
            p.box("Wood", (0.5, 0.5, 1.5), (lx, ly, 0.75))
    p.box("Wood", (3.6, 1.7, 0.2), (0.0, 0.0, 0.6))                  # lower shelf
    for i, (dx, dy, spin) in enumerate(((0.0, 0.0, 0.0), (0.06, -0.05, 5.0), (-0.05, 0.04, -4.0), (0.04, 0.06, 7.0))):
        p.box("Plank", (1.9, 1.0, 0.15), (-1.35 + dx, dy, 1.975 + 0.15 * i), rz=spin)   # plank stack up to z = 2.5
    # anvil-like block: foot, waist, face with a tapering horn, top at z = 2.5
    p.box("Metal", (1.1, 0.8, 0.2), (1.0, 0.0, 2.0))
    p.box("Metal", (0.6, 0.5, 0.2), (1.0, 0.0, 2.2))
    p.box("Metal", (1.2, 0.7, 0.2), (1.0, 0.0, 2.4))
    horn = p.loft([(0.0, rect(0.1, 0.35)), (0.7, rect(0.03, 0.1))], "Metal", caps=(True, True))
    p.place(horn, move(1.6, 0.0, 2.4) @ rot_y(90))


def spark_station(p):
    p.material("Stem", "3F9B3A")
    p.material("Petal", "A855F7")
    p.material("Glow", "FFC83D", emission=GLOW_STRENGTH)
    p.loft([(0.0, circ(6, 0.25)), (2.5, circ(6, 0.22))], "Stem", caps=(False, False))
    for z, spin, tilt in ((0.5, 0.0, 62.0), (1.2, 200.0, 58.0)):    # two small leaf blades
        leaf = p.loft([(0.0, [(0.0, 0.0)]), (0.5, rect(0.03, 0.2)), (1.1, [(0.0, 0.0)])], "Stem", caps=(False, False))
        p.place(leaf, rot_z(spin) @ move(0.12, 0.0, z) @ rot_y(tilt))
    petal = [
        (2.5, rect(0.05, 0.1, 0.12, 0.0)),
        (3.2, rect(0.06, 0.3, 0.55, 0.0)),
        (3.7, rect(0.05, 0.28, 0.85, 0.0)),
        (4.0, [(1.0, 0.0)]),
    ]
    for k in range(6):                                                # the bell: 6 petals opening upward to radius 1
        p.place(p.loft(petal, "Petal", caps=(True, False)), rot_z(60.0 * k))
    ball = p.ico(1, "Glow")
    p.fit(ball, (0.8, 0.8, 0.8), (0.0, 0.0, 3.2))                     # radius 0.4 glowing centre


def heater_lamp(p):
    p.material("Metal", "3A4049", roughness=0.5, metallic=0.4)
    p.material("Glow", "FF8C42", emission=GLOW_STRENGTH)
    # bowl: radius 1.5 at the rim (z 1.2), 0.8 tall, a dish inside
    p.loft([(0.4, circ(12, 0.5)), (0.8, circ(12, 1.15)), (1.2, circ(12, 1.5)), (1.2, circ(12, 1.28)), (0.95, circ(12, 0.7))],
           "Metal", caps=(True, True))
    for k in range(3):                                                # three splayed legs, feet on z = 0
        a = math.radians(90 + 120 * k)
        p.loft([(0.0, circ(4, 0.13, cx=1.2 * math.cos(a), cy=1.2 * math.sin(a), rot=math.pi / 4)),
                (0.65, circ(4, 0.12, cx=0.55 * math.cos(a), cy=0.55 * math.sin(a), rot=math.pi / 4))], "Metal", caps=(True, False))
    # three flame cones rising from the bowl; the tallest reaches z = 2.6
    for cx, cy, r, tip, curl in ((0.0, 0.1, 0.42, 2.6, (0.12, 0.05)), (0.62, -0.3, 0.32, 2.15, (-0.1, 0.08)), (-0.5, -0.5, 0.3, 1.95, (0.08, -0.1))):
        mid_z = 1.0 + (tip - 1.0) * 0.5
        p.loft([(1.0, circ(6, r, cx=cx, cy=cy)),
                (mid_z, circ(6, r * 0.7, cx=cx + curl[0], cy=cy + curl[1])),
                (tip, [(cx + curl[0] * 2.0, cy + curl[1] * 2.0)])], "Glow", caps=(True, False))


# Each row: build function, expected (W, D, H) in studs with None where the brief gives no number, tolerance in
# studs, and the one-line description for notes.md. The expected sizes are the game's placeholder sizes.
SPECS = {
    "MeadowTree": (meadow_tree, (8.0, 8.0, 14.0), 0.3, "Round oak: 8 tall trunk, one squashed leaf sphere"),
    "MeadowTreeB": (meadow_tree_b, (9.3, 7.0, 15.7), 1.0, "Oak with a 10 tall trunk and a two-lobed crown"),
    "SnowPine": (snow_pine, (9.0, 9.0, 15.0), 0.3, "Snow pine: grey trunk, three stacked snow cones"),
    "IceSpire": (ice_spire, (None, None, 10.0), 0.2, "Faceted ice crystal cluster: a 10 tall shard and two leaning shards"),
    "MeadowRock": (meadow_rock, (4.0, 4.0, 2.8), 0.05, "Lumpy grey boulder"),
    "MeadowRockB": (meadow_rock_b, (5.0, 4.0, 2.0), 0.05, "Wider, flatter boulder with a moss cap"),
    "IceRock": (ice_rock, (4.0, 4.0, 3.0), 0.05, "Angular ice boulder with two small chunks"),
    "IceRockB": (ice_rock_b, (3.0, 3.0, 4.0), 0.05, "Upright ice shard rock"),
    "GeyserCone": (geyser_cone, (6.0, 6.0, 7.0), 0.05, "Tapered vent cone with a crater dish sunk 1 stud into the top"),
    "ShrineStone": (shrine_stone, (2.0, 1.25, 5.0), 0.05, "Standing stone, tapered and bevelled (one Stone material, tinted per world)"),
    "Pedestal": (pedestal, (5.0, 5.0, 1.5), 0.05, "Two stacked discs, radius 2.5 and 2.0 (one Stone material)"),
    "ShipHull": (ship_hull, (12.0, 20.0, None), 0.05, "Landing pad hull: slab with its top at z = 0.5, rim lip, four skid feet down to z = -0.4"),
    "GatherStation": (gather_station, (6.0, 3.0, 1.5), 0.05, "Picnic table: top at 1.5, two seat planks each side at 0.7, A-frame legs"),
    "BuildStation": (build_station, (5.0, 3.0, 2.5), 0.05, "Workbench with a plank stack on one end and an anvil block on the other"),
    "SparkStation": (spark_station, (2.0, 2.0, 4.0), 0.3, "Glow flower: green stem, six purple petals, emissive centre ball"),
    "HeaterLamp": (heater_lamp, (3.0, 3.0, 2.6), 0.05, "Brazier on three legs with three emissive flame cones"),
}


# ------------------------------------------------------------------------------------------------- checks
def mesh_bounds(mesh):
    lo = Vector((min(v.co.x for v in mesh.vertices), min(v.co.y for v in mesh.vertices), min(v.co.z for v in mesh.vertices)))
    hi = Vector((max(v.co.x for v in mesh.vertices), max(v.co.y for v in mesh.vertices), max(v.co.z for v in mesh.vertices)))
    return lo, hi


def check_size(name, lo, hi, expected, tol):
    """Problems as strings: footprint versus the placeholder size, feet on z = 0, and the ShipHull plane."""
    problems = []
    size = hi - lo
    for axis, label, want in zip(range(3), ("W", "D", "H"), expected):
        if want is not None and abs(size[axis] - want) > tol:
            problems.append("%s %.2f, wanted %.2f +/- %.2f" % (label, size[axis], want, tol))
    if name == "ShipHull":
        if abs(lo.z + 0.4) > 0.01:
            problems.append("skid feet bottom %.2f, wanted -0.40" % lo.z)
        if hi.z > 0.8 + 1e-6:
            problems.append("rim lip top %.2f, limit 0.8" % hi.z)
    elif abs(lo.z) > 0.01:
        problems.append("bottom at z = %.2f, wanted 0" % lo.z)
    return problems


def top_plane(mesh):
    """Highest z that a big flat upward face reaches inside the lip: the plane modules stack on (ShipHull)."""
    best = None
    for poly in mesh.polygons:
        if poly.normal.z > 0.99 and len(poly.vertices) > 8:
            z = mesh.vertices[poly.vertices[0]].co.z
            best = z if best is None else max(best, z)
    return best


def colour_lines(prop_mats):
    return ", ".join("%s #%s%s" % (n, h, " (emissive %.1f)" % GLOW_STRENGTH if "emission" in kw else "") for n, (h, kw) in prop_mats.items())


def write_notes(path, name, what, mats, tris, lo, hi, glb, fbx):
    size = hi - lo
    lines = [
        "# %s prop" % name,
        "",
        "- Date: %s" % datetime.date.today().isoformat(),
        "- Tool: %s" % TOOL_NAME,
        "- What: %s" % what,
        "- Footprint (W x D x H, studs): %.2f x %.2f x %.2f (Blender X x Y x Z; Y becomes Roblox Z on export)" % (size.x, size.y, size.z),
        "- Vertical extent: z %.2f to %.2f; pivot at the bottom centre (origin), the model stands on z = 0" % (lo.z, hi.z),
        "- Triangles: %d (budget %d to %d)" % (tris, TRI_MIN, TRI_MAX),
        "- Colours / materials (one per colour, flat, no textures): %s" % colour_lines(mats),
        "- Shading: flat; rocks and crowns carry a slight seeded vertex jitter, so a re-run reproduces the same file",
        "- Files: %s (%d bytes), %s (%d bytes)" % (glb.name, glb.stat().st_size, fbx.name, fbx.stat().st_size),
        "- Studio import: File -> Import 3D on the GLB, scale 1, one MeshPart per material, rename the Model to exactly `%s`, "
        "parent under ReplicatedStorage.Models.Props, Anchored on. See docs/vault/06-art-pipelines/Map-Dressing.md." % name,
        "",
        "Blockout tier: a procedural stand-in. Replace with a hand-modelled mesh of the same footprint and pivot when one exists.",
        "",
    ]
    path.write_text("\n".join(lines))


# ---------------------------------------------------------------------------------------------------- run
def build_prop(name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build, expected, tol, what = SPECS[name]
    p = Prop(name)
    build(p)
    mats = dict(p.mats)
    obj = p.finish()
    return obj, mats, expected, tol, what


def parse_args():
    argv = sys.argv[1:]
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser(description="Generate low-poly scenery and camp props for ReplicatedStorage.Models.Props")
    ap.add_argument("--props", default="", help="comma-separated prop names (default: all)")
    ap.add_argument("--out", default=str(ROOT / "assets/models/props"), help="output root (default assets/models/props)")
    ap.add_argument("--all", action="store_true", help="build every prop (default when --props is empty)")
    return ap.parse_args(argv)


def main():
    args = parse_args()
    wanted = [s.strip() for s in args.props.split(",") if s.strip()]
    if wanted and not args.all:
        missing = [w for w in wanted if w not in SPECS]
        if missing:
            print("unknown prop: %s (known: %s)" % (", ".join(missing), ", ".join(SPECS)))
            sys.exit(2)
        names = wanted
    else:
        names = list(SPECS)
    out_root = pathlib.Path(args.out)
    if not out_root.is_absolute():
        out_root = pathlib.Path.cwd() / out_root

    over, wrong, total_bytes = [], [], 0
    print("%-14s %5s  %-22s %-14s  %s" % ("prop", "tris", "W x D x H (studs)", "z range", "glb / fbx bytes"))
    for name in names:
        obj, mats, expected, tol, what = build_prop(name)
        tris = triangle_count(obj.data)
        lo, hi = mesh_bounds(obj.data)
        size = hi - lo
        problems = check_size(name, lo, hi, expected, tol)
        if name == "ShipHull":
            plane = top_plane(obj.data)
            if plane is None or abs(plane - 0.5) > 0.001:
                problems.append("top plane z = %s, wanted 0.50" % plane)
        out_dir = out_root / name
        glb, fbx = export(obj, out_dir, name)
        write_notes(out_dir / "notes.md", name, what, mats, tris, lo, hi, glb, fbx)
        sizes = (glb.stat().st_size, fbx.stat().st_size)
        total_bytes += sum(sizes)
        flag = ""
        if tris > TRI_MAX:
            over.append(name)
            flag += "  OVER BUDGET"
        elif tris < TRI_MIN:
            flag += "  under %d" % TRI_MIN
        if problems:
            wrong.append(name)
            flag += "  SIZE: " + "; ".join(problems)
        print("%-14s %5d  %5.2f x %5.2f x %5.2f   %5.2f..%5.2f  %6d / %6d%s" % (
            name, tris, size.x, size.y, size.z, lo.z, hi.z, sizes[0], sizes[1], flag), flush=True)

    print("")
    print("%d props, %.2f MB total, written under %s" % (len(names), total_bytes / 1e6, out_root))
    if over:
        print("over %d triangles: %s" % (TRI_MAX, ", ".join(over)))
        sys.exit(1)
    if wrong:
        print("footprint differs from the placeholder size: %s" % ", ".join(wrong))
        sys.exit(3)


if __name__ == "__main__":
    main()
