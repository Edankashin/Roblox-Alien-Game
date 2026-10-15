#!/usr/bin/env python3
"""Sculpt pass prototype: one continuous skin per creature, built from the same recipe as species_bodies.py.

species_bodies.py joins the recipe's primitives, so every limb, ear and accessory sits on the body and the join shows. This builder
fuses them instead: the recipe's volumes become ONE mesh whose joins are blended (no seam), the face is part of the skin (shallow eye
sockets, the open mouth an indent, glossy eyes set into the sockets) and the seven material slots are assigned by face afterwards, so
materials.json, ModelAssets and the slot order are untouched. Plain Python with the bpy module, like species_bodies.py. It writes GLB,
FBX and notes.md like that script does, so point --models at a SCRATCH copy of the folders (it refuses assets/models).

  cp -r assets/models/Mossbop /scratch/models/Mossbop                                              # a copy of the folder first
  python3 tools/blender/species_sculpt.py --species Mossbop --models /scratch/models               # metaballs (the method that won)
  python3 tools/blender/species_sculpt.py --species Mossbop --models /scratch/models --method remesh   # the other candidate
  python3 tools/blender/species_sculpt.py --species Mossbop --models /scratch/models --set stiff=4 --set face.sink=0.3   # try a number
  python3 tools/blender/preview.py --lit --models /scratch/models --compare assets/models --species Mossbop --out /scratch/renders
  python3 tools/blender/preview.py --models /scratch/models --species Mossbop                      # the black shape (<Id>_grey.png)

How a species is built (every number is in DEFAULTS, a species overrides keys in SPECIES, and its `edit` function may change the recipe's
volumes without touching species_recipes.py):
  1. The recipe is expanded (species_recipes.expand). Spheres become ellipsoid metaball elements, calibrated so an element alone has the
     recipe's radii; rods, cones and cylinders become chains of balls and a torus a ring of them, each calibrated so the chain's surface
     is at the recipe's radius (a chain sums its fields); a cube is one rounded-box element. Overlapping elements ADD their fields, so the
     surface bulges into a fillet where two meet: a limb grows out of the body, the stiffness says how wide the blend is.
  2. The face is planned on the fused field (not on the host sphere): eyes and the mouth are snapped to the real skin, each eye gets a
     NEGATIVE element (a soft socket), the mouth a negative element (an indent), a lid is a positive Body element over the eye.
  3. Blender polygonizes the field (object.convert, 40,000 to 90,000 triangles), a COLLAPSE decimate takes it to the budget
     (a vertex group keeps more triangles round the face and on fine features), SMOOTH + SHRINKWRAP rounds relax the triangles back onto
     the polygonized surface, and the skin is cut along every slot contour so each colour boundary is a clean line.
  4. Each skin face gets the slot whose elements have the largest summed field there (the mouth outline gives Mouth); the skin is
     shaded with the field's own normals (smooth however coarse the triangles); the eyes (glossy spheres sunk into the sockets), any
     `separate` shell (a halo, flowers, tassels) and any `ribbons` band are joined; fitted to the height, smart-projected, gradient,
     texture tiling and export as species_bodies.py does.
--method remesh is the other candidate (join the primitives, boolean-carve the face, VOXEL remesh, SMOOTH, the same steps 3 and 4);
the note docs/vault/06-art-pipelines/Sculpt-Pass.md says why metaballs won.
"""
import argparse
import datetime
import json
import math
import pathlib
import re
import sys
import time

import bpy  # first: with the bpy module, bmesh and mathutils only import after it
import bmesh
import numpy as np
from mathutils import Matrix

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import species_recipes as SR  # noqa: E402
import species_bodies as SB  # noqa: E402
import luau_tables  # noqa: E402

TOOL = "tools/blender/species_sculpt.py"
THR = 0.6  # Blender's default metaball threshold; the calibration below assumes it

# ------------------------------------------------------------------------------------------------ the numbers
# Everything tunable lives here. A species overrides any key in SPECIES[sid].
DEFAULTS = {
    "stiff": 3.0,        # metaball stiffness of a body volume: low = a wide soft blend, high = a tight one (the reach is a / K(stiff))
    "stiff_thin": 3.0,   # stiffness of the chains (rods, cones, rings)
    "res": 0.04,         # metaball polygonizer cell size in studs (the smallest feature is about two cells)
    "tris": 2400,        # the target for the whole mesh; the cap is SR.TRI_BUDGET
    "fine": 0.2,         # a chain or band thinner than this (studs of radius) is a fine feature: the decimate keeps it more triangles
    "fine_detail": 0.4,  # the decimate weight on fine features (smaller keeps more)
    "chain_gap": 0.5,    # chain spacing as a fraction of the local tube radius
    "tube_grow": 1.0,    # scales every chain's radius (a chain sums fields, so a thin one reads fatter than its rod)
    "voxel": 0.032,      # remesh: voxel size as a fraction of the height
    "smooth_iter": 12,   # remesh: SMOOTH modifier iterations
    "smooth_fac": 0.55,
    "field_normals": True,  # shade the skin with the field's own normals (smooth however coarse the triangles are)
    "budget_check": True,  # False (--set budget_check=false) lets a debug build go over the cap
    "relax": 5,          # rounds of SMOOTH + SHRINKWRAP after the decimate
    "cut": True,         # cut the skin along the slot contours (a clean colour boundary) after the decimate
    "cut_share": 0.8,    # the decimate aims for this share of the budget; the cuts add the rest
    "separate": (),      # step names built as their own smooth shells (thin floating rings); their base still sinks into the body
    "face_recipe": None, # {key: value} merged into the recipe's face dict (eye_scale, lid, ...) for this build only
    "ribbons": (),       # [{"slot", "name", "pts", "widths", "thick"}]: continuous bands built as shells (see ribbon_object)
    "edit": None,        # a function(parts) -> parts: the sculpt's own changes to the recipe's volumes (the recipe file stays as it is)
    "face": {
        "eye_segments": 12,    # eyeball sphere segments
        "sink": 0.4,           # how far the eyeball is moved into the head, in eye radii
        "socket_reach": (1.55, 1.25, 1.55),   # socket negative element reach in eye radii (x, depth, z)
        "socket_stiff": 1.5,  # its strength (the dent depth is about stiff / field gradient)
        "socket_back": 0.1,    # socket centre behind the skin, in eye radii
        "lid_grow": 1.0,       # lid ellipsoid scale
        "mouth_reach": (1.5, 1.4, 1.5),   # mouth negative element reach as a multiple of the mouth ellipsoid radii
        "mouth_stiff": 1.1,
        "mouth_scale": 1.3,    # extra scale on the mouth ellipsoid (the Mouth slot area and the dent)
        "eye_boost": 1.2,      # the recipe's eye_scale times this (a sunk eye reads smaller than one that sits on the skin)
        "detail": 0.45,        # decimate weight in the face zones (smaller keeps more triangles there)
        "zone": 0.9,           # zone radius as a multiple of the element's largest reach
    },
}


# ------------------------------------------------------------------------------------------------ the four prototype species
def _steps(*steps):
    """Recipe step dicts (SR.sph, SR.rod ...) as parts, mirrored ones twice, the way species_recipes.expand does for the steps."""
    out = []
    for st in steps:
        R = SR.euler_matrix(st["rot"])
        out.append(SR._part(st, st["loc"], R))
        if st["mirror"] and abs(st["loc"][0]) > 1e-6:
            out.append(SR._part(st, (-st["loc"][0],) + tuple(st["loc"][1:]), SR.mirror_matrix(R)))
    return out


def _without(parts, *names):
    return [p for p in parts if p["name"] not in names]


def edit_mossbop(parts):
    """The sprout stands clear of the blend: a longer stalk and a higher bud (the fused moss swallowed the recipe's short one)."""
    return _without(parts, "stalk", "bud", "leaf") + _steps(
        SR.rod("BodyDark", (0.12, 0.05, 1.85), (0.24, 0.05, 2.4), 0.12, 0.095, segments=7, name="stalk"),
        SR.sph("Accessory", (0.25, 0.05, 2.5), (0.25, 0.25, 0.24), segments=10, name="bud"),
        SR.sph("BodyDark", (0.55, 0.05, 2.24), (0.27, 0.07, 0.13), rot=(0, -25, -10), segments=8, name="leaf"),
        SR.sph("BodyDark", (-0.1, 0.05, 2.22), (0.27, 0.07, 0.13), rot=(0, 25, 10), segments=8, name="leaf"))


def edit_sparkfox(parts):
    """Ears and cheek tufts as tapered tubes with a blunt tip (a point is thinner than the polygonizer's cell and is lost)."""
    return _without(parts, "ear", "innerear", "cheek") + _steps(
        SR.rod("Body", (0.48, -0.25, 1.8), (0.92, -0.1, 2.5), 0.4, 0.08, segments=8, mirror=True, name="ear"),
        SR.rod("BodyDark", (0.52, -0.45, 1.9), (0.86, -0.3, 2.36), 0.23, 0.06, segments=8, mirror=True, name="innerear"),
        SR.rod("BodyDark", (0.78, -0.38, 1.38), (1.32, -0.55, 1.26), 0.25, 0.07, segments=8, mirror=True, name="cheek"))


def edit_gaiabloom(parts):
    """Thicker legs (a stag on rods read as a table) that the body flows into."""
    return _without(parts, "leg") + _steps(
        SR.rod("Body", (0.55, -0.3, 1.5), (0.6, -0.4, 0.2), 0.3, 0.2, segments=6, mirror=True, name="leg"),
        SR.rod("Body", (0.55, 1.5, 1.45), (0.62, 1.55, 0.2), 0.3, 0.2, segments=6, mirror=True, name="leg"))


def edit_flufflet(parts):
    """The scarf's tail is one continuous band (ribbons below), not the recipe's chain of boxes."""
    return _without(parts, "streamer")


SPECIES = {
    "Mossbop": {"stiff": 5.0, "stiff_thin": 4.0, "edit": edit_mossbop, "face": {"socket_stiff": 1.8, "sink": 0.45},
                "separate": ("stalk", "bud", "leaf")},  # the sprout: a stalk the fused moss would swallow, so a shell sunk into the head
    "Sparkfox": {"stiff": 4.5, "stiff_thin": 4.0, "edit": edit_sparkfox, "face": {"lid_grow": 0.8}},
    "Gaiabloom": {"stiff": 4.0, "stiff_thin": 4.0, "separate": ("halo", "groundring", "flower"), "fine": 0.16, "edit": edit_gaiabloom,
                  "face_recipe": {"eye_scale": 1.3}, "face": {"lid_grow": 0.7}},
    "Flufflet": {"res": 0.03, "separate": ("tassel",), "fine": 0.1, "stiff": 3.5, "edit": edit_flufflet,
                 "face": {"lid_grow": 0.55, "socket_stiff": 0.9, "socket_reach": (1.4, 1.2, 1.4), "sink": 0.35}, "face_recipe": {"eye_tilt": -2.0, "lid": 0.16},
                 "ribbons": [{"slot": "Accessory", "name": "streamer", "pts": SR._STREAMER, "thick": 0.065,
                              "widths": [0.3, 0.3, 0.29, 0.28, 0.27, 0.26, 0.25, 0.24, 0.23, 0.22]}]},
}


def cfg_of(sid, override=None):
    out = json.loads(json.dumps(DEFAULTS, default=list))
    for source in (SPECIES.get(sid, {}), override or {}):
        for k, v in source.items():
            if isinstance(v, dict) and isinstance(out.get(k), dict):
                out[k].update(v)
            else:
                out[k] = v
    return out


# ------------------------------------------------------------------------------------------------ the metaball field
def kfac(s):
    """An isolated element of stiffness s and reach 1 has its surface at radius K(s) (Blender: s * (1 - d^2 / reach^2)^3 = THR)."""
    return math.sqrt(1.0 - (THR / s) ** (1.0 / 3.0))


def calib_ball(rho, d, s):
    """Reach of the balls in an endless chain (spacing d, stiffness s) whose surface sits at radius rho."""
    lo, hi = rho * 1.0005, rho / kfac(s)

    def field(b):
        n = int(b / d) + 1
        z = np.arange(-n, n + 1) * d
        v = 1.0 - (rho * rho + z * z) / (b * b)
        return float((s * np.clip(v, 0.0, None) ** 3).sum())

    for _ in range(36):
        mid = 0.5 * (lo + hi)
        if field(mid) < THR:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def cap_reach(rho, b, d, s):
    """How far past the last ball of a chain (spacing d, reach b, stiffness s) the surface sits on the axis."""
    lo, hi = 0.0, b

    def field(u):
        j = np.arange(0, int(b / d) + 2) * d
        v = 1.0 - ((u + j) ** 2) / (b * b)
        return float((s * np.clip(v, 0.0, None) ** 3).sum())

    if field(0.0) < THR:
        return 0.0
    for _ in range(36):
        mid = 0.5 * (lo + hi)
        if field(mid) > THR:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


class Field:
    """The element list, and Blender's metaball field in numpy (checked against converted single elements)."""

    def __init__(self):
        self.items = []

    def add(self, co, R, size, s, slot, name, neg=False, kind="ELLIPSOID", radius=1.0, fine=False):
        """kind ELLIPSOID: `size` is the reach on each local axis (radius 1). kind CUBE: `size` is the box half extents and `radius` the
        reach beyond the box (Blender measures the distance to the box and divides by the radius)."""
        self.items.append({"co": np.array(co, float), "R": np.array(R, float).reshape(3, 3), "size": np.array(size, float),
                           "s": float(s), "neg": bool(neg), "slot": slot, "name": name, "kind": kind, "radius": float(radius), "fine": bool(fine)})

    def contribution(self, item, P):
        q = (P - item["co"]) @ item["R"]
        if item["kind"] == "CUBE":
            q = np.maximum(np.abs(q) - item["size"], 0.0) / item["radius"]
        else:
            q = q / item["size"]
        v = 1.0 - (q * q).sum(axis=1)
        return item["s"] * np.clip(v, 0.0, None) ** 3

    def total(self, P, negatives=True):
        out = np.zeros(len(P))
        for it in self.items:
            if it["neg"] and not negatives:
                continue
            out += (-1.0 if it["neg"] else 1.0) * self.contribution(it, P)
        return out

    def surface_t(self, P, N, lo=-0.7, hi=0.9):
        """Distance t along N from P at which the positive field falls to the threshold (the skin before the face is carved)."""
        for _ in range(40):
            mid = 0.5 * (lo + hi)
            if self.total((P + N * mid)[None, :], negatives=False)[0] > THR:
                lo = mid
            else:
                hi = mid
        return 0.5 * (lo + hi)

    def slot_totals(self, P):
        """{slot: summed positive field} at the points P: the slot with the largest total owns the point (a sum, like the field itself,
        so a ring of balls owns its band evenly and not scallop by scallop)."""
        out = {}
        for it in self.items:
            if it["neg"]:
                continue
            c = self.contribution(it, P)
            out[it["slot"]] = out[it["slot"]] + c if it["slot"] in out else c
        return out

    def dominant_slot(self, P):
        totals = self.slot_totals(P)
        names = list(totals)
        stack = np.stack([totals[n] for n in names])
        best = stack.argmax(axis=0)
        return np.array(names, dtype=object)[best]

    def fine_share(self, P):
        """Fraction of the positive field that comes from fine elements (thin chains) at each point."""
        fine = np.zeros(len(P))
        total = np.zeros(len(P))
        for it in self.items:
            if it["neg"]:
                continue
            c = self.contribution(it, P)
            total += c
            if it["fine"]:
                fine += c
        return fine / np.maximum(total, 1e-9)


def add_sphere(field, p, stiff):
    k = kfac(stiff)
    field.add(p["loc"], p["rot"], tuple(v / k for v in p["scale"]), stiff, p["slot"], p["name"])


def add_chain(field, p, stiff, gap, grow, res, fine_below):
    """A rod, cone or cylinder as a chain of ellipsoid elements along its z axis, each calibrated so the chain's surface sits at the
    primitive's radius (a chain sums its fields, so a single ball per radius would read much fatter)."""
    R = np.array(p["rot"], float)
    c = np.array(p["loc"], float)
    sx, sy, sz = p["scale"]
    tip = p["tip"] if p["prim"] == "cone" else 1.0
    floor = 0.5 * res

    def radii(z):  # local z in [-sz, sz]
        f = (z + sz) / (2.0 * sz)
        t = 1.0 - (1.0 - tip) * f
        return max(sx * t * grow, floor), max(sy * t * grow, floor)

    r0, r1 = radii(-sz), radii(sz)
    rho0, rho1 = math.sqrt(r0[0] * r0[1]), math.sqrt(r1[0] * r1[1])
    mean = 0.5 * (rho0 + rho1)
    d = max(gap * mean, 0.5 * res)
    # the caps: the surface should end where the primitive ends
    b0, b1 = calib_ball(rho0, d, stiff), calib_ball(rho1, d, stiff)
    u0, u1 = cap_reach(rho0, b0, d, stiff), cap_reach(rho1, b1, d, stiff)
    za, zb = -sz + u0, sz - u1
    if zb < za:
        za = zb = 0.0
    n = max(1, int(math.ceil((zb - za) / d))) + 1 if zb > za else 1
    for i in range(n):
        z = za + (zb - za) * (i / (n - 1) if n > 1 else 0.5)
        rx, ry = radii(z)
        rho = math.sqrt(rx * ry)
        dd = (zb - za) / (n - 1) if n > 1 else d
        b = calib_ball(rho, max(dd, 0.5 * res), stiff)
        field.add(c + R @ np.array([0.0, 0.0, z]), R, (b * rx / rho, b * ry / rho, b), stiff, p["slot"], p["name"], fine=rho < fine_below)


def add_ring(field, p, stiff, gap, grow, res, fine_below):
    """A torus as a ring of calibrated balls."""
    R = np.array(p["rot"], float)
    c = np.array(p["loc"], float)
    sx, sy, sz = p["scale"]
    rho = max(p["minor"] * 0.5 * (sx + sy) * grow, 0.5 * res)
    squash = sz / (0.5 * (sx + sy))
    circ = 2.0 * math.pi * 0.5 * (sx + sy)
    n = max(8, int(math.ceil(circ / max(gap * rho, 0.5 * res))))
    d = circ / n
    b = calib_ball(rho, d, stiff)
    for i in range(n):
        a = 2.0 * math.pi * i / n
        pos = np.array([sx * math.cos(a), sy * math.sin(a), 0.0])
        field.add(c + R @ pos, R, (b, b, b * squash), stiff, p["slot"], p["name"], fine=rho < fine_below)


def add_box(field, p, stiff, res, fine_below):
    """A cube (a flat knitted band, a plank) as ONE rounded-box element: the thinnest half extent becomes the rounding radius, so a
    band 0.12 thick stays a band (an ellipsoid per piece would read as a string of beads)."""
    R = np.array(p["rot"], float)
    half = np.array(p["scale"], float)
    rho = max(float(half.min()), 0.5 * res)
    box = np.maximum(half - rho, 0.0)
    field.add(p["loc"], R, box, stiff, p["slot"], p["name"], kind="CUBE", radius=rho / kfac(stiff), fine=rho < fine_below)


def build_field(body_parts, cfg):
    field = Field()
    for p in body_parts:
        if p["name"] in cfg["separate"]:
            continue
        if p["prim"] in ("sphere", "icosphere"):
            add_sphere(field, p, cfg["stiff"])
        elif p["prim"] in ("cylinder", "cone"):
            add_chain(field, p, cfg["stiff_thin"], cfg["chain_gap"], cfg["tube_grow"], cfg["res"], cfg["fine"])
        elif p["prim"] == "torus":
            add_ring(field, p, cfg["stiff_thin"], cfg["chain_gap"], cfg["tube_grow"], cfg["res"], cfg["fine"])
        elif p["prim"] == "cube":
            add_box(field, p, cfg["stiff_thin"], cfg["res"], cfg["fine"])
        else:
            raise NotImplementedError("%s step %r: build it as a separate shell" % (p["prim"], p["name"]))
    return field


# ------------------------------------------------------------------------------------------------ the face
def face_plan(rec, face_parts, field, fc):
    """Split the recipe's face parts into eyes, the mouth and lids; snap each onto the real fused skin; return what to build:
    (eye meshes [part dicts], negative elements to add to the field, positive lids, the mouth region (centre, R, radii) or None)."""
    eyes, mouth, cur = [], None, None
    for p in face_parts:
        n = p["name"]
        if n == "eye":
            cur = {"eye": p}
            eyes.append(cur)
        elif n in ("pupil", "glint", "lid"):
            cur[n] = p
        elif n == "mouth":
            mouth = p
    meshes, negatives, lids = [], [], []
    for g in eyes:
        e = g["eye"]
        Q = np.array(e["rot"], float)
        r = e["scale"][0]
        ey = Q[:, 1]
        N = -ey
        P = np.array(e["loc"], float) - 0.15 * r * ey
        t = field.surface_t(P, N)
        shift = N * t  # the host's analytic surface to the fused skin
        inward = ey * fc["sink"] * r
        for key in ("eye", "pupil", "glint"):
            part = dict(g[key])
            part["loc"] = tuple(np.array(part["loc"], float) + shift + inward)
            part["segments"] = fc["eye_segments"] if key == "eye" else part["segments"]
            meshes.append(part)
        # the socket: a negative element centred a little behind the skin
        centre = P + shift + ey * fc["socket_back"] * r
        reach = (fc["socket_reach"][0] * r, fc["socket_reach"][1] * r, fc["socket_reach"][2] * r)
        negatives.append((centre, Q, reach, fc["socket_stiff"], "socket"))
        if "lid" in g:
            # the recipe's lid is a half ellipsoid standing on its lower edge; as a metaball it is a whole ellipsoid filling that span
            lid = g["lid"]
            lr = np.array(lid["scale"], float)
            Rl = np.array(lid["rot"], float)
            lids.append({"loc": np.array(lid["loc"], float) + shift + Rl[:, 2] * lr[2] * 0.5, "R": Rl,
                         "radii": np.array([lr[0], lr[1] * 1.15, lr[2] * 0.5]) * fc["lid_grow"], "r": r, "shift": shift})
    region = None
    if mouth is not None:
        Q = np.array(mouth["rot"], float)
        sx, sy, sz = mouth["scale"]
        m = SR.MOUTHS[rec["face"].get("mouth", "o")]
        u = sx / m["scale"][0]
        ey = Q[:, 1]
        N = -ey
        P = np.array(mouth["loc"], float) - Q @ np.array([0.0, 0.1 * u, m["z"] * u])
        shift = N * field.surface_t(P, N)
        scale = fc["mouth_scale"]
        radii = np.array([sx, sy, sz]) * scale
        centre = np.array(mouth["loc"], float) + shift
        if m["half"]:
            centre = centre + Q @ np.array([0.0, 0.0, -0.25 * sz * scale])  # the half-moon hangs below its top edge
        reach = tuple(fc["mouth_reach"][i] * radii[i] for i in range(3))
        negatives.append((centre, Q, reach, fc["mouth_stiff"], "mouth"))
        region = (centre, Q, radii)
    return meshes, negatives, lids, region


# ------------------------------------------------------------------------------------------------ building
def ribbon_object(name, pts, halfw, thick):
    """One continuous band along a path (a scarf tail, a banner): a thin box lofted through the points, `halfw` the half height at each
    point (the broad face stands upright, like species_recipes._ribbon) and `thick` the half thickness. A single smooth strip and not
    a chain of separate boxes, so it reads as one knitted piece."""
    pts = [np.array(p, float) for p in pts]
    verts, faces = [], []
    n = len(pts)
    for i, p in enumerate(pts):
        f = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        f = f / np.linalg.norm(f)
        u = np.array([0.0, 0.0, 1.0]) - f * f[2]
        u = u / np.linalg.norm(u)
        sd = np.cross(u, f)
        for su, ss in ((1, 1), (1, -1), (-1, -1), (-1, 1)):
            verts.append(tuple(p + su * halfw[i] * u + ss * thick * sd))
    for i in range(n - 1):
        a, b = 4 * i, 4 * (i + 1)
        for k in range(4):
            faces.append((a + k, a + (k + 1) % 4, b + (k + 1) % 4, b + k))
    faces.append((0, 3, 2, 1))
    faces.append((4 * (n - 1), 4 * (n - 1) + 1, 4 * (n - 1) + 2, 4 * (n - 1) + 3))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    bmesh_tri = bmesh.new()
    bmesh_tri.from_mesh(mesh)
    bmesh.ops.triangulate(bmesh_tri, faces=bmesh_tri.faces)
    bmesh_tri.to_mesh(mesh)
    bmesh_tri.free()
    SB.shade_by_angle(mesh, math.radians(55.0))
    return obj


def face_zones(negatives, fc):
    """(centre, radius) of each eye socket and the mouth, where the decimate keeps more triangles."""
    out = []
    for centre, Q, reach, st, kind in negatives:
        out.append((np.array(centre), max(reach) * fc["zone"]))
    return out


def import_materials(folder, sid):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(folder / ("%s.glb" % sid)))
    old = next(o for o in bpy.data.objects if o.type == "MESH")
    mats = [(s.material.name, s.material) for s in old.material_slots]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    return mats


def add_lids(field, lids, cfg):
    """A lid is a positive Body element over the top of the eye: it grows out of the head like a brow."""
    k = kfac(cfg["stiff"])
    for lid in lids:
        field.add(lid["loc"], lid["R"], lid["radii"] / k, cfg["stiff"], "Body", "lid")


def mesh_from_metaball(field, cfg):
    """All elements into one metaball object, polygonized by object.convert. Returns the new mesh object."""
    mb = bpy.data.metaballs.new("skin")
    mb.threshold = THR
    mb.resolution = mb.render_resolution = cfg["res"]
    mb.update_method = "UPDATE_ALWAYS"

    def put(co, R, size, s, neg, kind="ELLIPSOID", radius=1.0):
        el = mb.elements.new(type=kind)
        el.co = tuple(co)
        el.rotation = Matrix(np.array(R).reshape(3, 3).tolist()).to_quaternion()
        el.radius = radius
        el.size_x, el.size_y, el.size_z = (min(20.0, float(v)) for v in size)
        el.stiffness = min(10.0, s)
        el.use_negative = bool(neg)

    for it in field.items:  # the carving (negative) elements are in the field too, see build()
        put(it["co"], it["R"], it["size"], it["s"], it["neg"], it["kind"], it["radius"])
    obj = bpy.data.objects.new("skin", mb)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return bpy.context.view_layer.objects.active


def clean_mesh(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-6)
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def decimate(obj, target, symmetric=False, zones=(), detail=1.0, fine=None, fine_detail=1.0):
    """COLLAPSE decimate to about `target` triangles. Symmetry about x is available but off: it leaves flipped slivers on the mirror plane
    (thin dark lines down the back). `zones` are (centre, radius) spheres (the eyes and the mouth) where the vertex-group weight falls to
    `detail` (a SMALLER weight collapses less: 0 locks a vertex), so the dents keep triangles; `fine` gives the share of fine features."""
    n = tri_count(obj)
    if n <= target:
        return n
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = target / float(n)
    mod.use_collapse_triangulate = True
    if symmetric:
        mod.use_symmetry = True
        mod.symmetry_axis = "X"
    if (zones and detail < 1.0) or (fine is not None and fine_detail < 1.0):
        co = np.array([v.co[:] for v in obj.data.vertices])
        w = np.ones(len(co))
        if fine is not None and fine_detail < 1.0:
            share = np.clip(fine(co), 0.0, 1.0)
            w = np.minimum(w, 1.0 - (1.0 - fine_detail) * share)
        for centre, radius in (zones if detail < 1.0 else ()):
            t = np.clip(np.linalg.norm(co - centre, axis=1) / radius, 0.0, 1.0)
            fall = t * t * (3.0 - 2.0 * t)  # 0 at the centre, 1 at the rim
            w = np.minimum(w, detail + (1.0 - detail) * fall)
        vg = obj.vertex_groups.new(name="detail")
        for i in range(len(co)):
            vg.add([i], float(w[i]), "REPLACE")
        mod.vertex_group = "detail"
        mod.vertex_group_factor = 1.0
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for g in list(obj.vertex_groups):
        obj.vertex_groups.remove(g)
    return tri_count(obj)


def relax(obj, target_obj, rounds, smooth_iter=2, factor=0.5):
    """Even the triangles out (SMOOTH) and put the vertices back on the fused surface (SHRINKWRAP to the polygonized mesh), a few times."""
    bpy.context.view_layer.objects.active = obj
    for _ in range(rounds):
        mod = obj.modifiers.new("Relax", "SMOOTH")
        mod.iterations = smooth_iter
        mod.factor = factor
        bpy.ops.object.modifier_apply(modifier=mod.name)
        sw = obj.modifiers.new("Wrap", "SHRINKWRAP")
        sw.target = target_obj
        sw.wrap_method = "NEAREST_SURFACEPOINT"
        bpy.ops.object.modifier_apply(modifier=sw.name)


def smooth_all(obj):
    for p in obj.data.polygons:
        p.use_smooth = True


def carve_remesh(kit_obj, negatives, region):
    """remesh method: boolean-subtract an ellipsoid per negative element (cut at the element's visible size, not its reach)."""
    for centre, Q, reach, s, kind in negatives:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0, location=tuple(centre))
        cut = bpy.context.active_object
        cut.rotation_euler = Matrix(np.array(Q).tolist()).to_euler()
        # the reach is the soft falloff; the cut is a bit under half of it so the dent is shallow
        cut.scale = tuple(0.62 * v for v in reach)
        bpy.ops.object.select_all(action="DESELECT")
        kit_obj.select_set(True)
        bpy.context.view_layer.objects.active = kit_obj
        mod = kit_obj.modifiers.new("Carve", "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.solver = "EXACT"
        mod.object = cut
        mod.use_self = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cut)


def skin_by_remesh(body_parts, mats, negatives, cfg, height):
    kit = SB.Kit(mats, None)
    for p in body_parts:
        q = dict(p)
        if q["prim"] == "sphere":
            q["segments"] = max(16, q["segments"] * 2)
        elif q["prim"] in ("cylinder", "cone", "torus"):
            q["segments"] = max(10, q["segments"] * 2)
        kit.add(q)
    obj = kit.join("skin")
    carve_remesh(obj, negatives, None)
    mod = obj.modifiers.new("Remesh", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = cfg["voxel"] * height
    mod.adaptivity = 0.0
    mod.use_smooth_shade = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if cfg["smooth_iter"]:
        mod = obj.modifiers.new("Smooth", "SMOOTH")
        mod.iterations = cfg["smooth_iter"]
        mod.factor = cfg["smooth_fac"]
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.clear()
    return obj


def face_centres(mesh):
    n = len(mesh.polygons)
    out = np.empty(n * 3)
    mesh.polygons.foreach_get("center", out)
    return out.reshape(n, 3)


def assign_slots(obj, mats, field, region, index):
    mesh = obj.data
    mesh.materials.clear()
    for _, m in mats:
        mesh.materials.append(m)
    C = face_centres(mesh)
    slots = field.dominant_slot(C)
    idx = np.array([index[s] for s in slots], dtype=np.int32)
    if region is not None:
        centre, Q, radii = region
        q = (C - centre) @ Q / radii
        inside = (q * q).sum(axis=1) <= 1.0
        idx[inside] = index["Mouth"]
    mesh.polygons.foreach_set("material_index", idx)
    mesh.update()
    return int((idx == index["Mouth"]).sum())


def cut_along(bm, value, iters=14, eps=2e-3):
    """Split the mesh along the zero contour of value(P) (an (N, 3) -> (N,) function): every edge whose end values differ in sign is
    split where the value crosses zero (bisected on the real function) and the faces are cut between the new vertices, so the colour
    boundary of a slot is a clean line and not a staircase of big triangles. Returns how many edges were split."""
    verts = list(bm.verts)
    for i, v in enumerate(verts):
        v.index = i
    P = np.array([v.co[:] for v in verts])
    g = value(P)
    # an end value within eps of zero counts as ON the contour (an earlier cut put it there): no second cut beside it
    crossing = [e for e in bm.edges if g[e.verts[0].index] * g[e.verts[1].index] < 0.0
                and min(abs(g[e.verts[0].index]), abs(g[e.verts[1].index])) > eps]
    if not crossing:
        return 0
    A = np.array([e.verts[0].co[:] for e in crossing])
    B = np.array([e.verts[1].co[:] for e in crossing])
    ga = np.array([g[e.verts[0].index] for e in crossing])
    lo, hi = np.zeros(len(crossing)), np.ones(len(crossing))
    for _ in range(iters):
        mid = 0.5 * (lo + hi)
        gm = value(A + (B - A) * mid[:, None])
        same = gm * ga > 0.0
        lo = np.where(same, mid, lo)
        hi = np.where(same, hi, mid)
    t = 0.5 * (lo + hi)
    new = set()
    for e, f in zip(crossing, t):
        v0 = e.verts[0]
        _, nv = bmesh.utils.edge_split(e, v0, float(f))
        new.add(nv)
    for face in list(bm.faces):
        nv = [v for v in face.verts if v in new]
        if len(nv) == 2:
            bmesh.utils.face_split(face, nv[0], nv[1])
    bmesh.ops.triangulate(bm, faces=list(bm.faces), quad_method="BEAUTY", ngon_method="BEAUTY")
    return len(crossing)


def cut_slots(obj, field, region):
    """Cut the skin along every slot contour (one per slot with a positive element) and along the mouth's outline."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    slots = []
    for it in field.items:
        if not it["neg"] and it["slot"] not in slots:
            slots.append(it["slot"])
    cuts = 0
    if len(slots) > 1:
        for slot in slots[1:]:  # every boundary is the contour of at least two slots, so the first (Body) needs none of its own
            def value(P, slot=slot):
                totals = field.slot_totals(P)
                other = np.max([v for k, v in totals.items() if k != slot], axis=0)
                return totals[slot] - other

            cuts += cut_along(bm, value)
    if region is not None:
        centre, Q, radii = region

        def inside(P):
            q = (P - centre) @ Q / radii
            return 1.0 - (q * q).sum(axis=1)

        cuts += cut_along(bm, inside)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return cuts


def field_normals(field, P, h=0.012):
    """Unit surface normals at the points P from the gradient of the fused field (central differences), carving included. They are
    exact for the smooth surface the decimated triangles only approximate, so the shading stays smooth however coarse the mesh is."""
    g = np.zeros_like(P)
    for axis in range(3):
        d = np.zeros(3)
        d[axis] = h
        g[:, axis] = (field.total(P + d) - field.total(P - d)) / (2.0 * h)
    n = -g
    length = np.linalg.norm(n, axis=1, keepdims=True)
    return n / np.maximum(length, 1e-9)


def set_field_normals(obj, field):
    mesh = obj.data
    P = np.array([v.co[:] for v in mesh.vertices])
    mesh.normals_split_custom_set_from_vertices([tuple(n) for n in field_normals(field, P)])


def smooth_slots(obj, passes=1):
    """A face whose neighbours across its edges are mostly one other slot takes that slot (removes single-face specks)."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    for _ in range(passes):
        new = [f.material_index for f in bm.faces]
        for f in bm.faces:
            nb = [g.material_index for e in f.edges for g in e.link_faces if g is not f]
            if nb and f.material_index not in nb:
                new[f.index] = max(set(nb), key=nb.count)
        for f in bm.faces:
            f.material_index = new[f.index]
    bm.to_mesh(obj.data)
    bm.free()


def uv_project(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")


def update_files(folder, sid, rec, tris, height, method, seconds):
    notes = (folder / "notes.md").read_text()
    notes = re.sub(r"- Triangles: .*", "- Triangles: %d (sculpt pass, %s)" % (tris, TOOL), notes)
    notes = re.sub(r"- Height: [\d.]+ units", "- Height: %.2f units" % height, notes)
    line = ("- Sculpt pass %s: one fused skin (%s) built by %s from tools/blender/species_recipes.py in %.0f s; eyes sunk into carved "
            "sockets, the mouth an indent." % (datetime.date.today().isoformat(), method, TOOL, seconds))
    if "- Sculpt pass" in notes:
        notes = re.sub(r"- Sculpt pass.*", lambda m: line, notes)
    else:
        notes = notes.rstrip("\n") + "\n" + line + "\n"
    (folder / "notes.md").write_text(notes)


def build(sid, models, method, override=None):
    t0 = time.time()
    cfg = cfg_of(sid, override)
    rec = SR.RECIPES[sid]
    if rec["status"] != "recipe":
        raise RuntimeError("%s is a TODO stub" % sid)
    face = dict(rec["face"])
    face.update(cfg["face_recipe"] or {})  # the sculpt's own face tweaks (the recipe file stays as it is)
    face["eye_scale"] = face.get("eye_scale", 1.0) * cfg["face"]["eye_boost"]
    rec = dict(rec, face=face)
    folder = models / sid
    mats = import_materials(folder, sid)
    SB.apply_materials(mats, rec)
    index = {n: i for i, (n, _) in enumerate(mats)}
    parts = SR.expand(rec)
    nface = len(SR.face_parts(rec))
    body_parts, fparts = parts[:-nface], parts[-nface:]
    if cfg["edit"]:
        body_parts = cfg["edit"](body_parts)
    field = build_field(body_parts, cfg)
    meshes, negatives, lids, region = face_plan(rec, fparts, field, cfg["face"])
    add_lids(field, lids, cfg)
    for centre, Q, reach, st, kind in negatives:
        field.add(centre, Q, reach, st, kind, kind, neg=True)
    t_field = time.time()

    sep_parts = [p for p in body_parts if p["name"] in cfg["separate"]]
    # eyes, pupils, glints and the separate shells are ordinary primitives
    kit = SB.Kit(mats, SR.SURFACE)  # the shells (and the eyes) get the surface pass's bevel and smoothing; the skin is shaded below
    if method == "metaball":
        skin = mesh_from_metaball(field, cfg)
        clean_mesh(skin)
        raw_tris = tri_count(skin)
    else:
        lid_parts = [p for p in fparts if p["name"] == "lid"]  # the recipe's half-sphere lids join the union (the metaball path has soft ones)
        skin = skin_by_remesh([p for p in body_parts if p["name"] not in cfg["separate"]] + lid_parts, mats, negatives, cfg, rec["height"])
        clean_mesh(skin)
        raw_tris = tri_count(skin)
    t_poly = time.time()
    ribbons = [(r["slot"], ribbon_object(r["name"], r["pts"], r["widths"], r["thick"])) for r in cfg["ribbons"]]
    extra_tris = sum(SR.part_tris(p) for p in meshes + sep_parts) + sum(tri_count(o) for _, o in ribbons)
    target = max(300, cfg["tris"] - extra_tris)
    raw_mesh = skin.data
    raw_obj = bpy.data.objects.new("raw", raw_mesh.copy())
    bpy.context.scene.collection.objects.link(raw_obj)
    raw_obj.hide_set(True)
    want = target * cfg["cut_share"]
    zones = [(c, rad) for c, rad in face_zones(negatives, cfg["face"])]
    cuts = 0
    for _ in range(4):
        skin.data = raw_mesh.copy()
        decimate(skin, want, zones=zones, detail=cfg["face"]["detail"], fine=field.fine_share, fine_detail=cfg["fine_detail"])
        skin.data.validate()
        if cfg["relax"]:
            relax(skin, raw_obj, cfg["relax"])
        cuts = cut_slots(skin, field, region) if cfg["cut"] else 0
        final_skin = tri_count(skin)
        if final_skin <= target:
            break
        want *= 0.97 * target / final_skin
    bpy.data.objects.remove(raw_obj)
    smooth_all(skin)
    if cfg["field_normals"]:
        set_field_normals(skin, field)
    assign_slots(skin, mats, field, region, index)
    kit.parts.append(skin)
    for p in meshes + sep_parts:
        kit.add(p)
    for slot, ob in ribbons:
        kit._take(ob, slot, True)
    obj = kit.join(sid)
    used = {p.material_index for p in obj.data.polygons}
    if used != set(range(len(mats))):
        raise RuntimeError("unused slots: %s" % ", ".join(mats[i][0] for i in sorted(set(range(len(mats))) - used)))
    lo, hi, scale = SB.fit(obj, rec["height"])
    tris = tri_count(obj)
    if tris > SR.TRI_BUDGET and cfg["budget_check"]:
        raise SB.OverBudget("%d triangles is over the %d cap" % (tris, SR.TRI_BUDGET))
    uv_project(obj)
    shade = SB.paint_gradient(obj, mats, SR.SURFACE["gradient"])
    tiled = SB.tile_uvs(obj, mats, SB.textures_of(folder), luau_tables.load(str(SB.TEXTURES)))
    bpy.ops.export_scene.gltf(filepath=str(folder / ("%s.glb" % sid)), export_format="GLB", export_apply=True, export_animations=False,
                              export_yup=True, use_selection=False, export_materials="EXPORT", export_lights=False, export_cameras=False,
                              export_vertex_color="ACTIVE")
    bpy.ops.export_scene.fbx(filepath=str(folder / ("%s.fbx" % sid)), use_selection=False, apply_scale_options="FBX_SCALE_ALL",
                             mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
    seconds = time.time() - t0
    update_files(folder, sid, rec, tris, hi - lo, method, seconds)
    info = {"tris": tris, "raw": raw_tris, "height": hi - lo, "fit": scale, "elements": len(field.items), "cuts": cuts, "seconds": seconds,
            "t_field": t_field - t0, "t_poly": t_poly - t_field, "gradient": shade, "tiled": tiled, "skin_tris": final_skin}
    return info


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description="Build species as one fused skin (prototype)")
    ap.add_argument("--species", required=True, help="comma list of ids")
    ap.add_argument("--models", required=True, help="a SCRATCH copy of the model folders (written in place; never assets/models)")
    ap.add_argument("--method", default="metaball", choices=("metaball", "remesh"))
    ap.add_argument("--set", action="append", default=[], help="override a number: key=value (e.g. res=0.03 or face.sink=0.3)")
    return ap.parse_args(argv)


def parse_overrides(items):
    out = {}
    for it in items:
        key, val = it.split("=", 1)
        try:
            value = json.loads(val)
        except ValueError:
            value = val
        if "." in key:
            a, b = key.split(".", 1)
            out.setdefault(a, {})[b] = value
        else:
            out[key] = value
    return out


def main():
    args = parse_args()
    models = pathlib.Path(args.models).resolve()
    if models == (SB.ROOT / "assets/models").resolve():
        raise SystemExit("refusing to write into assets/models: pass a scratch copy with --models")
    override = parse_overrides(args.set)
    failed = []
    for sid in SR.ids_for(args.species):
        try:
            i = build(sid, models, args.method, override)
            print("%-10s %s tris=%d (skin %d, raw %d) height=%.2f fit=x%.3f elements=%d cuts=%d  %.0f s (field %.1f, polygonize %.1f)" % (
                sid, args.method, i["tris"], i["skin_tris"], i["raw"], i["height"], i["fit"], i["elements"], i["cuts"], i["seconds"],
                i["t_field"], i["t_poly"]), flush=True)
        except Exception as exc:  # noqa: BLE001
            import traceback
            traceback.print_exc()
            failed.append(sid)
            print("%-10s FAILED: %s" % (sid, exc), flush=True)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
