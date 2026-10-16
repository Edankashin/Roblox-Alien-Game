#!/usr/bin/env python3
"""Three low-poly style checks on the creature models (docs/vault/06-art-pipelines/Character-Pipeline.md, section 3.5, "Three style checks next to
the render checks"; Kenney's rules for cute low poly). They are cheap to measure and catch "shapes mashed together" before a render does.

  1. bevel   A bevel on every hard edge. On the mesh, every edge whose two faces turn by more than HARD_ANGLE degrees and are both large (at least
             LARGE_FACE of the model's surface each, so no bevel strip or small detail sits between them) is an "unbevelled hard edge". Counted per
             material slot of the GLB (the slots of assets/models/<Id>/materials.json). A crisp slot may be sharp: one whose recipe parts are mostly
             flat-shaded on purpose or named like a crisp thing (crystal, blade, shard), or an Accessory or Trim slot of a hard material (Ice, Glass,
             Slate, Pebble, Metal) or on a stone or ice species (a Body or BodyDark of those). It is counted and listed apart and never fails. The
             face slots are listed but not judged. Pass: the share of unbevelled hard edges over the other slots is at most BEVEL_SHARE_MAX.
  2. taper   Limbs taper root to tip. Read from the recipe (tools/blender/species_recipes.py, imported read-only), not the mesh: every limb-like part
             (legs, arms, tails, horns, antlers, antennae and other tubes: LIMB_NAMES) is a rod (cylinder), a cone, a `sweep` tube or a chain of
             balls; its radius at the root end (the end nearer the body) is compared with the radius at the tip. An even rod or a flare fails;
             the tip must be at most TAPER_MAX of the root. Needs no mesh, so it also runs on the `<Id>V2` prototype recipes, which have no GLB.
  3. plan    A plan outline closer to a rounded square than a box. The mesh is projected to a black shape from above and from the front (64 px, the
             bounding box stretched to the square); the share of the four corner squares (CORNER_FRAC of the box side) the shape fills is the corner
             fill. A hard box fills them (1.0), a round body leaves them empty (0.01), a rounded square in between. Pass: both views at most
             CORNER_FILL_MAX, the line between mostly full and mostly empty; `--calibrate` prints the cube, the sphere and the rounded boxes it is read from.

The mesh checks (1 and 3) read the GLB with the pure-Python reader of tools/blockbench/to_bbmodel.py, so the whole tool runs under plain Python too,
without bpy; the project's headless Blender Python runs it just the same. Check 2 only reads recipe data.

  python3 tools/blender/style_checks.py Mossbop Thunderhog              # species Ids: assets/models/<Id>/<Id>.glb, and the recipe of that Id
  python3 tools/blender/style_checks.py --all                           # every shipped model folder (the sheet of Character-Pipeline.md)
  python3 tools/blender/style_checks.py --recipe ThunderhogV2,v2        # check 2 only, on recipe keys; `v2` = every design-pass <Id>V2 prototype
  python3 tools/blender/style_checks.py --all -v --json /scratch/style.json   # per-slot and per-limb detail, and the sheet as JSON
  python3 tools/blender/style_checks.py --calibrate                     # the cube, sphere and rounded-box numbers behind the plan bar
  python3 tools/blender/style_checks.py path/to/Some.glb               # a GLB path (the recipe is looked up by its file stem)

Y is up in the GLB (glTF), so "from above" projects (x, z) and "from the front" projects (x, y). Exit status 0, or 1 with --strict when anything fails.
"""
from __future__ import annotations

import argparse
import collections
import importlib.util
import json
import math
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MODELS = ROOT / "assets/models"

# ---------------------------------------------------------------------------------------------------- the thresholds (why each is what it is: Character-Pipeline.md)
HARD_ANGLE = 60.0       # degrees between the two face normals: the 60 degrees of the clay check (section 3.5, check 2) and the surface pass's bevel_angle
LARGE_FACE = 0.0025     # a face is "large" at 0.25 percent of the model's surface (about 0.06 stud2 of a 25 stud2 creature). The surface pass bevels 0.05 studs wide
                        # (species_recipes.SURFACE), so a bevel strip along a one stud edge is 0.05 stud2, 0.2 percent: under the line. A modelled face is over it
COPLANAR = 0.05         # degrees: triangles that bend less than this across an edge are one flat face (a quad's two triangles), so a face is a face, not half of one
BEVEL_SHARE_MAX = 0.01  # at most 1 percent of the non-crisp edges may be unbevelled hard edges: one stray prism (a cube is 12 edges, a five-sided leg about 15, of
                        # roughly 1,500 to 3,000 edges) passes, two or a boxy build fails
TAPER_MAX = 0.85        # tip radius over root radius: "at most about 0.85"
CORNER_FRAC = 0.15      # the corner squares of the plan check, as a share of the box side
SIZE = 64               # the black shape's resolution
# The plan bar is set by calibrate(): see its docstring. The value is asserted against the references by the unit tests and printed by `--calibrate`.
CORNER_FILL_MAX = 0.50

HARD_MATERIALS = ("Ice", "Glass", "Slate", "Pebble", "Metal", "Granite", "Rock", "Marble", "Basalt", "Concrete", "DiamondPlate", "CorrodedMetal")
CRISP_SLOT_NAMES = ("Accessory", "Trim")   # a hard material only makes these slots crisp; a Body in Ice is still a body
CRISP_SHARE = 0.5                          # a slot is crisp when at least this share of its recipe parts are flat-shaded or crisp by name
CRISP_PART_NAMES = ("crystal", "shard", "blade", "pane", "peak", "pick", "chip", "gem", "jewel", "crowngem", "crownember", "ember", "pebble",
                    "aurora", "star", "ray", "quill", "claw", "fang", "tusk", "skate", "ski")
FACE_SLOTS = ("EyeWhite", "Pupil", "Mouth", "EyeHighlight")

# The recipe part names that are limbs (check 2). Not limbs: ears, wings (membranes), necks, claws, quills, reeds (pipes are even by design).
LIMB_NAMES = {
    "leg": "leg", "foreleg": "leg", "hindleg": "leg", "thigh": "leg", "thighbone": "leg", "shin": "leg", "shank": "leg", "hock": "leg",
    "arm": "arm", "upperarm": "arm", "forearm": "arm",
    "tail": "tail", "tailtip": "tail",
    "horn": "horn", "antler": "horn", "tusk": "horn",
    "antenna": "tube", "stalk": "tube", "stem": "tube", "sproutstalk": "tube", "leafstem": "tube", "tendril": "tube", "wisp": "tube",
    "icicle": "tube", "abdomen": "tube", "stinger": "tube", "root": "tube",
}
SWEEP_NOT_LIMBS = ("body", "neck")   # a sweep with these names is the trunk or a neck, not a limb
# The recipe parts that make up the body, for finding which end of a limb is the root.
CORE_NAMES = ("body", "torso", "chest", "hips", "waist", "thorax", "barrel", "rump", "brisket", "haunch", "head", "withers", "bodytilt", "belly")


# ---------------------------------------------------------------------------------------------------- tiny vector maths
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def norm(a):
    return math.sqrt(dot(a, a))


# ---------------------------------------------------------------------------------------------------- check 1: hard edges
def face_normal_area(tri):
    """(unit normal, area) of a triangle of three points; the normal is None for a degenerate one."""
    c = cross(sub(tri[1], tri[0]), sub(tri[2], tri[0]))
    n = norm(c)
    if n < 1e-12:
        return None, 0.0
    return (c[0] / n, c[1] / n, c[2] / n), n / 2.0


def normals_angle(n1, n2):
    """Degrees between two unit normals (0 flat, 90 a box corner, 180 folded back on itself)."""
    return math.degrees(math.acos(max(-1.0, min(1.0, dot(n1, n2)))))


def dihedral_deg(tri_a, tri_b):
    """The dihedral angle of two triangles that share an edge, as Blender's Select Sharp Edges reads it: the angle between their face normals
    (0 for two coplanar triangles, 90 across a box edge). None when either triangle is degenerate. Both triangles must wind the same way."""
    n1, _ = face_normal_area(tri_a)
    n2, _ = face_normal_area(tri_b)
    if n1 is None or n2 is None:
        return None
    return normals_angle(n1, n2)


def is_hard(angle, threshold=HARD_ANGLE):
    return angle is not None and angle > threshold + 1e-9


def weld(tris, places=5):
    """Index the corners of a triangle soup by position: ([(x, y, z)], [(i, j, k)]), triangles with a repeated corner dropped.
    Corners that share a position (the duplicates at a hard edge or a UV seam) get one index; `places` is the rounding in the model's units."""
    index, points, out, keep = {}, [], [], []
    for n, tri in enumerate(tris):
        ids = []
        for p in tri:
            key = (round(p[0], places), round(p[1], places), round(p[2], places))
            i = index.get(key)
            if i is None:
                i = index[key] = len(points)
                points.append(p)
            ids.append(i)
        if len(set(ids)) == 3:
            out.append(tuple(ids))
            keep.append(n)
    return points, out, keep


def polygon_areas(edges, normals, areas, flat_deg=COPLANAR):
    """The area of the polygon each triangle belongs to: neighbours across an edge that bends by less than flat_deg are one face (the two triangles of
    a quad, the fan of a cap), so "a large face" means a modelled face and not half of one."""
    parent = list(range(len(areas)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for faces in edges.values():
        if len(faces) == 2 and normals[faces[0]] is not None and normals[faces[1]] is not None:
            if normals_angle(normals[faces[0]], normals[faces[1]]) < flat_deg:
                parent[find(faces[0])] = find(faces[1])
    total = collections.defaultdict(float)
    for t, a in enumerate(areas):
        total[find(t)] += a
    return [total[find(t)] for t in range(len(areas))]


def edge_report(tris, slots, hard_angle=HARD_ANGLE, large_face=LARGE_FACE):
    """The edges of a triangle soup (three points per triangle, one slot name per triangle) and the hard ones among them.

    Returns {slot: {"edges": n, "hard": n, "unbevelled": n, "small": n}} plus the key "": the same counts once over the whole model, and the numbers
    "open" (edges with one face) and "nonmanifold" (three or more). An edge between two slots counts in both slots and once in the total.
    hard        edges whose two faces turn by more than hard_angle degrees
    unbevelled  the hard edges whose two faces are both at least large_face of the model's surface (nothing small, no bevel strip, between them)
    small       the hard edges left out because a face is smaller than that (a bevel strip, a tooth, a rim of a small detail)"""
    points, ids, keep = weld(tris)
    normals, areas = [], []
    for n in keep:
        nrm, area = face_normal_area(tris[n])
        normals.append(nrm)
        areas.append(area)
    total = sum(areas) or 1.0
    edges = collections.defaultdict(list)
    for t, (a, b, c) in enumerate(ids):
        for u, v in ((a, b), (b, c), (c, a)):
            edges[(u, v) if u < v else (v, u)].append(t)
    areas = polygon_areas(edges, normals, areas)
    zero = {"edges": 0, "hard": 0, "unbevelled": 0, "small": 0}
    report = {"": dict(zero, open=0, nonmanifold=0)}
    for key, faces in edges.items():
        if len(faces) == 1:
            report[""]["open"] += 1
            continue
        if len(faces) > 2:
            report[""]["nonmanifold"] += 1
            continue
        t1, t2 = faces
        if normals[t1] is None or normals[t2] is None:
            continue
        angle = normals_angle(normals[t1], normals[t2])
        hard = is_hard(angle, hard_angle)
        big = areas[t1] >= large_face * total and areas[t2] >= large_face * total
        owners = {slots[keep[t1]], slots[keep[t2]]}
        for who in owners | {""}:
            row = report.setdefault(who, dict(zero))
            row["edges"] += 1
            if hard:
                row["hard"] += 1
                row["unbevelled" if big else "small"] += 1
    return report


# ---------------------------------------------------------------------------------------------------- check 3: the plan outline
def rasterize(tris2d, size=SIZE):
    """The black shape of a list of 2D triangles ((x, y) x 3) on a size x size grid: the bounding box of the triangles is stretched to the square,
    so a thin shape and a fat one are measured the same way (the boxed metric of overlap.py). Returns a list of rows of 0/1, row 0 at the top (+y).
    A pixel is black when its centre is inside a triangle."""
    if not tris2d:
        return [[0] * size for _ in range(size)]
    xs = [p[0] for t in tris2d for p in t]
    ys = [p[1] for t in tris2d for p in t]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    sx = size / (x1 - x0) if x1 > x0 else 0.0
    sy = size / (y1 - y0) if y1 > y0 else 0.0
    grid = [[0] * size for _ in range(size)]
    for t in tris2d:
        p = [((q[0] - x0) * sx, (y1 - q[1]) * sy) for q in t]   # pixel units, row 0 = top
        (ax, ay), (bx, by), (cx, cy) = p
        det = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(det) < 1e-12:
            continue
        i0, i1 = max(0, int(math.floor(min(ax, bx, cx) - 0.5))), min(size - 1, int(math.ceil(max(ax, bx, cx) - 0.5)))
        j0, j1 = max(0, int(math.floor(min(ay, by, cy) - 0.5))), min(size - 1, int(math.ceil(max(ay, by, cy) - 0.5)))
        for j in range(j0, j1 + 1):
            py = j + 0.5
            row = grid[j]
            for i in range(i0, i1 + 1):
                px = i + 0.5
                u = ((by - cy) * (px - cx) + (cx - bx) * (py - cy)) / det
                v = ((cy - ay) * (px - cx) + (ax - cx) * (py - cy)) / det
                if u >= -1e-9 and v >= -1e-9 and u + v <= 1.0 + 1e-9:
                    row[i] = 1
    return grid


def corner_fill(mask, frac=CORNER_FRAC):
    """How much of the four corner squares (each frac of the box side) a black shape fills: (mean of the four, [top-left, top-right, bottom-left,
    bottom-right]). 1.0 for a filled box, near 0 for a disc. A pixel counts in a corner when its centre is within frac of the box of that corner."""
    size = len(mask)
    cells = [i for i in range(size) if (i + 0.5) / size < frac]
    lo = cells
    hi = [size - 1 - i for i in cells]
    corners = []
    for rows in (lo, hi):
        for cols in (lo, hi):
            n = len(rows) * len(cols)
            corners.append(sum(mask[j][i] for j in rows for i in cols) / n if n else 0.0)
    return sum(corners) / 4.0, corners


def views_of(tris):
    """The two black shapes of a triangle soup in glTF axes (Y up): from above (x, z) and from the front (x, y)."""
    top = [tuple((p[0], p[2]) for p in t) for t in tris]
    front = [tuple((p[0], p[1]) for p in t) for t in tris]
    return {"top": rasterize(top), "front": rasterize(front)}


def plan_report(tris, bar=None):
    """{"top": fill, "front": fill, "corners": {view: [4 fills]}, "bar": bar, "pass": bool} for a triangle soup."""
    bar = CORNER_FILL_MAX if bar is None else bar
    out = {"corners": {}}
    for view, mask in views_of(tris).items():
        mean, four = corner_fill(mask)
        out[view] = round(mean, 3)
        out["corners"][view] = [round(c, 3) for c in four]
    out["bar"] = bar
    out["pass"] = out["top"] <= bar and out["front"] <= bar
    return out


# ---------------------------------------------------------------------------------------------------- calibration shapes (built here, no Blender)
def outward(tris):
    """Wind every triangle of a convex shape centred on the origin so its normal points away from the centre (a consistent skin for dihedral_deg)."""
    out = []
    for t in tris:
        n, _ = face_normal_area(t)
        c = ((t[0][0] + t[1][0] + t[2][0]) / 3.0, (t[0][1] + t[1][1] + t[2][1]) / 3.0, (t[0][2] + t[1][2] + t[2][2]) / 3.0)
        out.append(t if n is None or dot(n, c) >= 0 else (t[0], t[2], t[1]))
    return out


def cube_mesh(half=1.0):
    """The 12 triangles of an axis-aligned cube."""
    v = [(sx * half, sy * half, sz * half) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
    quads = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    out = []
    for a, b, c, d in quads:
        out.append((v[a], v[b], v[c]))
        out.append((v[a], v[c], v[d]))
    return outward(out)


def sphere_mesh(radius=1.0, segments=32, rings=16):
    """A UV sphere as triangles."""
    def pt(i, j):
        th, ph = math.pi * j / rings, 2.0 * math.pi * i / segments
        return (radius * math.sin(th) * math.cos(ph), radius * math.cos(th), radius * math.sin(th) * math.sin(ph))
    out = []
    for j in range(rings):
        for i in range(segments):
            a, b, c, d = pt(i, j), pt(i + 1, j), pt(i + 1, j + 1), pt(i, j + 1)
            if j > 0:            # at the top pole a == b, so the first triangle is left out there (and the second at the bottom pole)
                out.append((a, b, c))
            if j < rings - 1:
                out.append((a, c, d))
    return outward(out)


def rounded_box_mesh(radius, half=1.0, n=12):
    """A box of half-size `half` with its corners and edges rounded by `radius` (a sphere of that radius swept over the inner box): built from a
    subdivided cube whose points are pushed onto the rounded surface. radius = half is a sphere; radius near 0 is a box."""
    inner = half - radius

    def project(p):
        c = tuple(max(-inner, min(inner, x)) for x in p)
        d = sub(p, c)
        m = norm(d)
        if m < 1e-12:
            return p
        return (c[0] + radius * d[0] / m, c[1] + radius * d[1] / m, c[2] + radius * d[2] / m)
    faces = []
    for axis in range(3):
        for sgn in (-1.0, 1.0):
            grid = []
            for a in range(n + 1):
                row = []
                for b in range(n + 1):
                    u, v = -1.0 + 2.0 * a / n, -1.0 + 2.0 * b / n
                    p = [0.0, 0.0, 0.0]
                    p[axis] = sgn
                    p[(axis + 1) % 3], p[(axis + 2) % 3] = u, v
                    row.append(project(tuple(half * x for x in p)))
                grid.append(row)
            faces.append(grid)
    out = []
    for grid in faces:
        for a in range(n):
            for b in range(n):
                p00, p10, p11, p01 = grid[a][b], grid[a + 1][b], grid[a + 1][b + 1], grid[a][b + 1]
                out.append((p00, p10, p11))
                out.append((p00, p11, p01))
    return outward(out)


def calibrate(radii=(0.1, 0.15, 0.2, 0.25, 0.3, 0.4)):
    """The corner fill, in both views, of the references that set the plan bar: a cube (1.0), a sphere (0.01) and rounded boxes whose corner radius
    is a share of the box side (0.1 a barely softened box, 0.5 a sphere). Returns {name: {"top": fill, "front": fill, "side": share}}.

    The bar, CORNER_FILL_MAX = 0.50, is the line between "mostly full" and "mostly empty" that the section 3.5 wording draws ("a hard box fills
    them; a rounded square or a round body leaves them mostly empty"). It is the midpoint of the cube (1.0) and the sphere (0.01), and a rounded box
    whose corners are a quarter of the side lands on it (0.51; 0.47 if the corner is cut with only three facets). A box rounded by a fifth of the
    side or less (0.66, 0.77, 0.88) fails, a third or more (0.34, 0.11) passes. The 64 px raster reads a corner square of 10 px (15.6 percent), a
    little fuller than the analytic 15 percent (0.465 at a quarter); `test_style_checks.py` checks both against a closed form."""
    table = {}
    cases = [("cube", cube_mesh(1.0), 0.0), ("sphere", sphere_mesh(1.0), 0.5)]
    for r in radii:
        cases.append(("rounded box %.2f" % r, rounded_box_mesh(r * 2.0, 1.0, 24), r))
    for name, tris, side in cases:
        rep = plan_report(tris)
        table[name] = {"top": rep["top"], "front": rep["front"], "side": side}
    return table


# ---------------------------------------------------------------------------------------------------- check 2: limbs taper (from the recipe)
def taper_ratio(root_radius, tip_radius):
    """The tip radius over the root radius (1.0 an even rod, below 1 tapering, above 1 flaring)."""
    return tip_radius / root_radius if root_radius > 1e-9 else 0.0


def taper_ok(ratio, taper_max=TAPER_MAX):
    return ratio <= taper_max + 1e-6


def load_recipes():
    """tools/blender/species_recipes.py, read-only (no sys.path change, no write)."""
    spec = importlib.util.spec_from_file_location("species_recipes_ro", HERE / "species_recipes.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _expand(sr, rec):
    """The recipe's steps as parts (the mirrored ones twice), without the face: dicts of prim, name, slot, loc, R, scale, tip, flat and, for a sweep,
    pts and radii. Uses only sr.euler_matrix and sr.mirror_matrix, the maths the builders use."""
    parts = []
    for s in rec.get("steps", []):
        R = sr.euler_matrix(s["rot"])
        base = {"prim": s["prim"], "name": s.get("name") or s["prim"], "slot": s["slot"], "scale": s["scale"], "tip": s.get("tip", 0.0),
                "flat": s.get("flat", not sr.SMOOTH_BY_DEFAULT[s["prim"]])}
        if s["prim"] == "sweep":
            parts.append(dict(base, loc=s["loc"], R=R, pts=s["pts"], radii=s["radii"]))
            continue
        parts.append(dict(base, loc=s["loc"], R=R))
        if s.get("mirror") and abs(s["loc"][0]) > 1e-6:
            parts.append(dict(base, loc=(-s["loc"][0], s["loc"][1], s["loc"][2]), R=sr.mirror_matrix(R)))
    return parts


def _mv(R, v):
    return tuple(sum(R[i][k] * v[k] for k in range(3)) for i in range(3))


def _mvT(R, v):
    return tuple(sum(R[k][i] * v[k] for k in range(3)) for i in range(3))


def _depth(p, cores):
    """How far a point is from the body, in body radii: the smallest (|local position| - 1) over the core ellipsoids (0 on a surface, negative inside)."""
    best = None
    for c in cores:
        q = _mvT(c["R"], sub(p, c["loc"]))
        q = tuple(q[i] / max(c["scale"][i], 1e-6) for i in range(3))
        d = norm(q) - 1.0
        best = d if best is None or d < best else best
    return best


def _radius(scale):
    """The effective radius of an ellipse or ellipsoid of these radii: the geometric mean."""
    r = 1.0
    for v in scale:
        r *= max(v, 1e-9)
    return r ** (1.0 / len(scale))


def _ends(part):
    """(end A, radius A, end B, radius B) of a rod, cone or sweep: a cone's big end is at -z and its small end, `tip` times as wide, at +z."""
    if part["prim"] == "sweep":
        return part["pts"][0], part["radii"][0], part["pts"][-1], part["radii"][-1]
    s, c, R = part["scale"], part["loc"], part["R"]
    half = _mv(R, (0.0, 0.0, s[2]))
    ring = math.sqrt(max(s[0], 1e-9) * max(s[1], 1e-9))
    big = (c[0] - half[0], c[1] - half[1], c[2] - half[2])
    small = (c[0] + half[0], c[1] + half[1], c[2] + half[2])
    if part["prim"] == "cylinder":
        return big, ring, small, ring
    return big, ring, small, ring * part["tip"]


def _components(items, linked):
    """Connected components (lists of indices) of items under the symmetric relation linked(i, j)."""
    left = list(range(len(items)))
    out = []
    while left:
        comp = [left.pop(0)]
        grew = True
        while grew:
            grew = False
            for j in list(left):
                if any(linked(i, j) for i in comp):
                    comp.append(j)
                    left.remove(j)
                    grew = True
        out.append(comp)
    return out


def limb_parts(sr, rec):
    """The limb-like parts of a recipe with their taper: [{"name", "family", "kind", "slot", "segments", "root", "tip", "ratio", "ok"}].

    A limb piece is a cylinder ("rod"), cone or sweep named in LIMB_NAMES (a sweep is any tube but the trunk and the neck), or a ball of such a name.
    Pieces of one name whose ends meet make one limb (a bent antenna of three rods, a tail of four cones, a tail of beads), judged end to end: the
    radius at the free end nearer the body over the radius at the free end farthest from it. A single ball is a blob, not a limb.
    The body is the recipe's own body parts (CORE_NAMES); with none to measure from, the root is the wide end."""
    parts = _expand(sr, rec)
    cores = [p for p in parts if p["name"] in CORE_NAMES and p["prim"] in ("sphere", "icosphere")]
    pieces, balls = [], []
    for p in parts:
        name = p["name"]
        tube = p["prim"] == "sweep" and name not in SWEEP_NOT_LIMBS
        if name not in LIMB_NAMES and not tube:
            continue
        if p["prim"] in ("cylinder", "cone", "sweep"):
            a, ra, b, rb = _ends(p)
            if cores:       # the root end is the end nearer the body
                root_is_a = _depth(a, cores) <= _depth(b, cores)
            else:
                root_is_a = ra >= rb
            (root, rr), (tip, rt) = ((a, ra), (b, rb)) if root_is_a else ((b, rb), (a, ra))
            pieces.append({"name": name, "slot": p["slot"], "kind": {"cylinder": "rod", "cone": "cone", "sweep": "sweep"}[p["prim"]],
                           "root": root, "root_r": rr, "tip": tip, "tip_r": rt})
        elif p["prim"] in ("sphere", "icosphere"):
            balls.append(p)
    out = []

    def finish(name, slot, kind, n, root, tip):
        ratio = taper_ratio(root, tip)
        out.append({"name": name, "family": LIMB_NAMES.get(name, "tube"), "kind": kind, "slot": slot, "segments": n, "root": round(root, 4),
                    "tip": round(tip, 4), "ratio": round(ratio, 3), "ok": taper_ok(ratio)})

    def continues(p, q):    # q carries on from p: same name and slot, and p's tip end meets q's root end (a fork at the root is not a chain)
        return (p["name"], p["slot"]) == (q["name"], q["slot"]) and \
            norm(sub(p["tip"], q["root"])) <= 0.5 * (p["tip_r"] + q["root_r"]) + 0.03

    for comp in _components(pieces, lambda i, j: continues(pieces[i], pieces[j]) or continues(pieces[j], pieces[i])):
        group = [pieces[i] for i in comp]
        starts = [p for p in group if not any(q is not p and continues(q, p) for q in group)] or group
        first = min(starts, key=lambda p: _depth(p["root"], cores)) if cores else max(starts, key=lambda p: p["root_r"])
        ends = [p for p in group if not any(q is not p and continues(p, q) for q in group)] or group
        last = max(ends, key=lambda p: norm(sub(p["tip"], first["root"])))
        finish(first["name"], first["slot"], first["kind"], len(group), first["root_r"], last["tip_r"])

    def touch(p, q):
        return (p["name"], p["slot"]) == (q["name"], q["slot"]) and \
            norm(sub(p["loc"], q["loc"])) <= 1.15 * (_radius(p["scale"]) + _radius(q["scale"]))

    for comp in _components(balls, lambda i, j: touch(balls[i], balls[j])):
        if len(comp) < 2:
            continue
        members = [balls[i] for i in comp]
        members.sort(key=(lambda m: _depth(m["loc"], cores)) if cores else (lambda m: -_radius(m["scale"])))
        finish(members[0]["name"], members[0]["slot"], "chain", len(members), _radius(members[0]["scale"]), _radius(members[-1]["scale"]))
    return out


def taper_report(sr, key):
    """The check-2 result for one recipe key: {"limbs": n, "failing": [{"name", "kind", "ratio", "count"}], "pass": bool} or {"skip": why}."""
    rec = sr.RECIPES.get(key)
    if rec is None:
        return {"skip": "no recipe %s" % key}
    if rec.get("status") != "recipe" or not rec.get("steps"):
        return {"skip": "stub recipe (no steps)"}
    limbs = limb_parts(sr, rec)
    bad = collections.OrderedDict()
    for l in limbs:
        if not l["ok"]:
            k = (l["name"], l["kind"], round(l["ratio"], 2))
            bad[k] = bad.get(k, 0) + 1
    failing = [{"name": n, "kind": kd, "ratio": r, "count": c} for (n, kd, r), c in bad.items()]
    ratios = [l["ratio"] for l in limbs]
    return {"limbs": len(limbs), "failing": failing, "failing_parts": sum(f["count"] for f in failing), "worst": max(ratios) if ratios else None,
            "pass": not failing}


# ---------------------------------------------------------------------------------------------------- reading the GLB and the slots
def load_glb_reader():
    spec = importlib.util.spec_from_file_location("to_bbmodel_ro", ROOT / "tools/blockbench/to_bbmodel.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def slot_of(name):
    return re.sub(r"\.\d{3}$", "", name or "Unassigned")


def read_mesh(bb, path):
    """([triangle of three (x, y, z) points], [slot name per triangle]) from a GLB, in world space, glTF axes (Y up)."""
    glb = bb.read_glb(path)
    tris, slots = [], []
    for prim in glb.primitives:
        mat = glb.materials[prim.material] if prim.material is not None and prim.material < len(glb.materials) else {}
        slot = slot_of(mat.get("name"))
        for a, b, c in prim.triangles:
            tris.append((prim.positions[a], prim.positions[b], prim.positions[c]))
            slots.append(slot)
    return tris, slots


def slot_entries(folder):
    f = pathlib.Path(folder) / "materials.json"
    if not f.exists():
        return {}
    return {e["name"]: e for e in json.loads(f.read_text())}


def crisp_slots(sr, key, entries):
    """{slot: why} for the slots allowed to be sharp. Three reasons, each of them data:
      the recipe's parts in the slot are mostly crisp: flat-shaded on purpose (`flat`: the faceted rocks, shards and bolts) or named like a crisp
        thing (CRISP_PART_NAMES: crystals, blades, panes, peaks, chips, gems);
      the slot is an Accessory or Trim whose own materials.json material is hard (Ice, Glass, Slate, Pebble, Metal);
      the slot is an Accessory or Trim on a stone or ice species: one whose Body or BodyDark is of a hard material.
    The face slots are never crisp, and a Body in Ice is still a body."""
    out = {}
    rec = sr.RECIPES.get(key) if sr is not None else None
    if rec and rec.get("steps"):
        count = collections.defaultdict(lambda: [0, 0])
        for p in _expand(sr, rec):
            if p["slot"] in FACE_SLOTS:
                continue
            count[p["slot"]][0] += 1 if (p["flat"] or p["name"] in CRISP_PART_NAMES) else 0
            count[p["slot"]][1] += 1
        for slot, (crisp, n) in count.items():
            if n and crisp / n >= CRISP_SHARE:
                out[slot] = "recipe parts flat or crisp (%d of %d)" % (crisp, n)
    hard_body = [s for s in ("Body", "BodyDark") if entries.get(s, {}).get("material") in HARD_MATERIALS]
    for slot, e in entries.items():
        if slot in CRISP_SLOT_NAMES and slot not in out:
            if e.get("material") in HARD_MATERIALS:
                out[slot] = "%s material" % e["material"]
            elif hard_body:
                out[slot] = "on a species with a %s %s" % (entries[hard_body[0]]["material"], hard_body[0])
    return out


def bevel_report(tris, slots, crisp, hard_angle=HARD_ANGLE, large_face=LARGE_FACE, bar=BEVEL_SHARE_MAX):
    """Check 1 on a mesh: per slot the edge counts, the crisp slots set apart, and the verdict on the rest."""
    rep = edge_report(tris, slots, hard_angle, large_face)
    total = rep.pop("")
    per = {}
    for slot, row in sorted(rep.items()):
        share = row["unbevelled"] / row["edges"] if row["edges"] else 0.0
        per[slot] = {"edges": row["edges"], "hard": row["hard"], "unbevelled": row["unbevelled"], "small": row["small"], "share": round(share, 4),
                     "crisp": crisp.get(slot)}
    # The verdict is over the body slots that are not crisp; the face slots (eyes, mouth) are listed but not judged here (the face
    # is render check 3 of section 3.5). An edge between a crisp and a soft slot counts in both slots: the soft side is not allowed the sharpness.
    soft = [r for s, r in per.items() if not r["crisp"] and s not in FACE_SLOTS]
    edges = sum(r["edges"] for r in soft)
    unb = sum(r["unbevelled"] for r in soft)
    share = unb / edges if edges else 0.0
    crisp_unb = sum(r["unbevelled"] for s, r in per.items() if r["crisp"])
    return {"slots": per, "edges": total["edges"], "hard": total["hard"], "unbevelled": total["unbevelled"], "open": total["open"],
            "nonmanifold": total["nonmanifold"], "soft_edges": edges, "soft_unbevelled": unb, "share": round(share, 4),
            "crisp_unbevelled": crisp_unb, "bar": bar, "pass": share <= bar}


# ---------------------------------------------------------------------------------------------------- the run
def resolve_target(target, models):
    """(label, glb path or None, recipe key or None) from a species Id or a GLB path."""
    p = pathlib.Path(target)
    if p.suffix.lower() == ".glb":
        return p.stem, p, p.stem
    return target, pathlib.Path(models) / target / ("%s.glb" % target), target


def all_targets(models):
    return sorted(d.name for d in pathlib.Path(models).iterdir() if d.is_dir() and (d / ("%s.glb" % d.name)).exists())


def v2_keys(sr):
    """The design-pass prototypes: every `<Id>V2` recipe key but the hero FenripupV2 (the batch 1 and 2 recipes of Design-Pass.md)."""
    return [k for k, v in sr.RECIPES.items() if k.endswith("V2") and v.get("prototype") and k != "FenripupV2"]


def run_species(sr, bb, label, glb, key, models):
    row = {"id": label}
    folder = pathlib.Path(glb).parent if glb else None
    if glb is not None and pathlib.Path(glb).exists():
        tris, slots = read_mesh(bb, glb)
        entries = slot_entries(folder)
        row["triangles"] = len(tris)
        row["bevel"] = bevel_report(tris, slots, crisp_slots(sr, key, entries))
        row["plan"] = plan_report(tris)
    else:
        row["bevel"] = {"skip": "no GLB"}
        row["plan"] = {"skip": "no GLB"}
    row["taper"] = taper_report(sr, key) if key else {"skip": "no recipe"}
    return row


def verdict(part):
    if "skip" in part:
        return "n/a"
    return "pass" if part["pass"] else "FAIL"


def line(row):
    """One line per species: the three results with pass or FAIL (n/a when the input for a check is missing)."""
    b, t, p = row["bevel"], row["taper"], row["plan"]
    parts = []
    if b.get("skip") != "recipe only":
        if "skip" in b:
            parts.append("bevel n/a (%s)" % b["skip"])
        else:
            parts.append("bevel %-4s %3d/%-4d %4.1f%%%s" % (verdict(b), b["soft_unbevelled"], b["soft_edges"], 100.0 * b["share"],
                                                           (" +%d crisp" % b["crisp_unbevelled"]) if b["crisp_unbevelled"] else ""))
    if "skip" in t:
        parts.append("taper n/a (%s)" % t["skip"])
    else:
        text = "taper %-4s %d/%d" % (verdict(t), t["failing_parts"], t["limbs"])
        if t["failing"]:
            text += " " + ", ".join("%s%s %.2f" % (f["name"], ("x%d" % f["count"]) if f["count"] > 1 else "", f["ratio"]) for f in t["failing"])
        parts.append(text)
    if p.get("skip") != "recipe only":
        parts.append("plan n/a (%s)" % p["skip"] if "skip" in p else "plan %-4s top %.2f front %.2f" % (verdict(p), p["top"], p["front"]))
    return "%-13s %s" % (row["id"], " | ".join(parts))


def detail(row):
    """The per-slot lines of --verbose: every slot with a hard edge or a crisp reason."""
    out = []
    b = row["bevel"]
    if "skip" not in b:
        for slot, r in b["slots"].items():
            if r["hard"] or r["crisp"]:
                out.append("    slot %-12s edges %5d hard %4d unbevelled %4d small %4d share %5.1f%%%s" % (
                    slot, r["edges"], r["hard"], r["unbevelled"], r["small"], 100.0 * r["share"], ("  crisp: " + r["crisp"]) if r["crisp"] else ""))
        out.append("    open edges %d, non-manifold %d, triangles %d" % (b["open"], b["nonmanifold"], row["triangles"]))
    for f in row["taper"].get("failing", []):
        out.append("    limb %-10s %-6s tip/root %.2f x%d" % (f["name"], f["kind"], f["ratio"], f["count"]))
    return out


def summarize(rows, top=3):
    """How many rows pass each check, and the worst few: {check: {"checked": n, "passed": n, "worst": [(id, number)]}}. The number is the
    unbevelled share (bevel), the share of limbs that fail (taper) or the larger corner fill (plan)."""
    keyed = {"bevel": lambda r: r["bevel"]["share"], "taper": lambda r: r["taper"]["failing_parts"] / max(r["taper"]["limbs"], 1),
             "plan": lambda r: max(r["plan"]["top"], r["plan"]["front"])}
    ties = {"bevel": lambda r: r["bevel"]["soft_unbevelled"], "taper": lambda r: r["taper"]["failing_parts"], "plan": lambda r: 0}
    out = {}
    for check, key in keyed.items():
        have = [r for r in rows if "skip" not in r[check]]
        worst = sorted(have, key=lambda r: (key(r), ties[check](r)), reverse=True)[:top]
        out[check] = {"checked": len(have), "passed": sum(1 for r in have if r[check]["pass"]),
                      "failed": [r["id"] for r in have if not r[check]["pass"]], "worst": [(r["id"], round(key(r), 3)) for r in worst]}
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description="Three low-poly style checks: bevelled hard edges, tapering limbs, a rounded plan outline")
    ap.add_argument("targets", nargs="*", help="species Ids or GLB paths")
    ap.add_argument("--all", action="store_true", help="every <Id>/<Id>.glb under --models")
    ap.add_argument("--recipe", default="", help="comma list of recipe keys for check 2 only (e.g. ThunderhogV2); `v2` = every design-pass <Id>V2 prototype")
    ap.add_argument("--models", default=str(MODELS), help="folder laid out like assets/models")
    ap.add_argument("--json", default="", help="write the sheet here as JSON")
    ap.add_argument("--calibrate", action="store_true", help="print the cube, sphere and rounded-box fills behind the plan bar")
    ap.add_argument("-v", "--verbose", action="store_true", help="per-slot lines under each species")
    ap.add_argument("--strict", action="store_true", help="exit 1 when any check fails")
    args = ap.parse_args(argv)
    sr = load_recipes()
    sheet = {"thresholds": {"hard_angle": HARD_ANGLE, "large_face": LARGE_FACE, "bevel_share_max": BEVEL_SHARE_MAX, "taper_max": TAPER_MAX,
                            "corner_frac": CORNER_FRAC, "corner_fill_max": CORNER_FILL_MAX, "size": SIZE}, "species": [], "recipes": []}
    if args.calibrate:
        print("plan calibration (corner fill, mean of the four corners of %.0f%%, %d px): bar %.2f" % (100 * CORNER_FRAC, SIZE, CORNER_FILL_MAX))
        sheet["calibration"] = calibrate()
        for name, v in sheet["calibration"].items():
            print("  %-18s top %.3f  front %.3f" % (name, v["top"], v["front"]))
    todo = [resolve_target(t, args.models) for t in (all_targets(args.models) if args.all else [])]
    todo += [resolve_target(t, args.models) for t in args.targets]
    keys = []
    for k in [x for x in args.recipe.split(",") if x]:
        keys += v2_keys(sr) if k == "v2" else [k]
    if not todo and not keys and not args.calibrate:
        ap.error("name a species or a GLB, or use --all, --recipe or --calibrate")
    bb = load_glb_reader()
    failed = 0
    for label, glb, key in todo:
        row = run_species(sr, bb, label, glb, key, args.models)
        sheet["species"].append(row)
        print(line(row))
        if args.verbose:
            for extra in detail(row):
                print(extra)
        failed += sum(1 for part in ("bevel", "taper", "plan") if verdict(row[part]) == "FAIL")
    for key in keys:
        t = taper_report(sr, key)
        row = {"id": key, "bevel": {"skip": "recipe only"}, "plan": {"skip": "recipe only"}, "taper": t}
        sheet["recipes"].append(row)
        print(line(row))
        failed += 1 if verdict(t) == "FAIL" else 0
    if len(sheet["species"]) > 1:
        sheet["summary"] = summarize(sheet["species"])
        print("")
        for check, v in sheet["summary"].items():
            print("%-6s %2d of %2d pass; worst %s" % (check, v["passed"], v["checked"], ", ".join("%s %.2f" % w for w in v["worst"])))
    if len(sheet["recipes"]) > 1:
        sheet["recipe_summary"] = summarize([dict(r, bevel={"skip": 1}, plan={"skip": 1}) for r in sheet["recipes"]])["taper"]
        v = sheet["recipe_summary"]
        print("recipes: taper %d of %d pass; worst %s" % (v["passed"], v["checked"], ", ".join("%s %.2f" % w for w in v["worst"])))
    if args.json:
        pathlib.Path(args.json).write_text(json.dumps(sheet, indent=1))
    return 1 if args.strict and failed else 0


if __name__ == "__main__":
    sys.exit(main())
