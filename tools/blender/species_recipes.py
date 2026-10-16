#!/usr/bin/env python3
"""Silhouette recipes: one body recipe per species, the data tools/blender/species_bodies.py builds from.

Plain Python, no bpy. The bible is docs/vault/06-art-pipelines/Silhouette-Pass.md (read it first: the rules, one row
per species, the order of the nights). This file holds the numbers.

Axes and units: 1 unit = 1 stud, Z up, the face on -Y, the pivot at the feet (the lowest point sits on z = 0), x to the
viewer's right when looking at the face. Heights are the heights in assets/models/<Id>/notes.md.

A recipe is a dict:
    tier, world, biome, batch      where it sits in the order (1..5 = World 1 tonight, 6..9 = the Frostbyte nights, 0 = built already)
    status                         "recipe" (built from `steps`) or "TODO" (a stub: only the silhouette line is settled)
    silhouette, hero               one line each: the black shape and the one hero feature (the bible repeats them)
    height                         total height in studs; species_bodies.py fits the mesh to it (uniform scale, under 3 percent)
    face                           how the face sits on the host step (see FACE below)
    palette                        {slot: "HEX"} colours to write (Body stays the Species.luau placeholder colour)
    glow, metal                    {slot: emission strength} and {slot: metallic 0..1}; a slot not named keeps its old value
    steps                          primitive steps, built in order

A step (make them with sph, ico, cyl, cone, cube, tor, rod or spike below):
    {"prim": "sphere|icosphere|cube|cylinder|cone|torus", "slot": <material slot>, "loc": (x, y, z), "rot": (deg, deg, deg),
     "scale": (x, y, z), "segments": n, "mirror": True|False, "name": "..."} plus optional "flat" (flat shading), "tip"
     (cone: the small end's radius as a fraction of the big end's, default 0 = a point), "minor" (torus tube radius as a
     fraction of the major radius, default 0.25) and "mseg" (torus tube segments, default 6).
    Every primitive has radius 1 (a cube has half-size 1, a cylinder and a cone have half-height 1, a cone's big end is at
    -z), so `scale` is the radii: scale (0.5, 0.5, 1.0) on a cylinder is 2 studs long and 1 stud across. `rot` is an XYZ Euler
    in degrees (X first). `segments` is the segment count of a sphere (rings = half of it), the sides of a cylinder or cone,
    the segments round a torus, and the subdivision level of an icosphere (1 = 20 faces, 2 = 80, 3 = 320). `mirror` also builds
    the step on the other side of x (location x negated, rotation mirrored); a step centred on x = 0 is never doubled.

FACE: {"on": <name of the sphere step the face sits on>, "eye_scale": 1.0, "eye_gap": 1.0, "eye_tilt": 0.0, "mouth": "o|smile|zigzag|wide"}
    1.0 is the Mossbop look: the eyes' centres about 38 percent of the host's width apart, each eye's radius a fifth of the
    host's radius. eye_tilt is the slant of the lids in degrees (positive = fierce, the inner ends low; negative = soft, the
    inner ends high) and only shows when "lid" > 0. Optional: "lid" (0..0.6, the fraction of each eye covered from the top by
    a half-lid in body colour), "look" (dx, dz) shifts both pupils (fractions of the eye radius), "cross" pulls both pupils
    toward the nose (goofy), "eye_asym" makes the left eye bigger by that fraction and the right one smaller, "eye_height"
    (default 0.66, how far up the host the eyes sit), "mouth_drop" (default 0.22, how far below the eyes the mouth sits, as a
    fraction of the host's height), "mouth_scale" (default 1) and "lift" (studs, pushes the face off the host, for faceted
    bodies). Mouths: "o" a small round open mouth, "smile" a half-moon grin, "wide" a big half-moon grin, "zigzag" a half-moon
    grin with four teeth. The face needs a sphere or icosphere host with its centre line on x = 0.

The face slots (EyeWhite, Pupil, Mouth, EyeHighlight) are used only by the face. Steps use Body, BodyDark, Accessory and, for
Epic and Legendary, Trim. `python3 tools/blender/species_recipes.py` checks every recipe without Blender: triangle estimate,
height, slots against materials.json, the face host.

Two additions for the hero prototypes (docs/vault/06-art-pipelines/Hero-Aliens.md):
    sweep(slot, pts, radii, name)  a step of prim "sweep": one tube through the points (a Catmull-Rom curve) with a radius per point,
                                   for a tail or a serpent body. Only `species_sculpt.py --method hybrid` builds it (as ONE chain of
                                   calibrated balls in the core, so keep it in Body or BodyDark: an Accessory or Trim sweep would be
                                   taken for a crisp part); `species_bodies.py` has no such primitive and refuses a recipe that has one.
    "prototype": True              a recipe that is not a shipped species (no assets/models folder, no Species.luau row): the `all`,
                                   `world1`, `world2` and `batchN` ids skip it, name it to build it, and the tests do not hold it to
                                   Species.luau or to a shipped materials.json.

The design pass (docs/vault/06-art-pipelines/Design-Pass.md) adds eight `<Id>V2` prototypes, one per species of its first batch, in the DESIGN PASS 1
block below the heroes: each keeps its species' height, slots, palette and glow and gives it a new base design. They share the helper `_leaf` (a flat
ellipsoid: a wing, a mitten, a flipper, a sprout leaf). A recipe may carry `"ribbons"` (FluffletV2's scarf streamer): the band data for
`species_sculpt.py --set ribbons=<json>`, which reads it from the command line; `expand` ignores it. Batch 2 (DESIGN PASS 2) adds eight more and the helpers
`_msweep` and `_zig`, batch 3 (DESIGN PASS 3: Radish, Panpipe, Zapfinch, Sparkfox, Shellberg, Snailbyte, Pebblet, Flapsicle) eight more with no new helper.
"""
import argparse
import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MODELS = ROOT / "assets/models"

TRI_BUDGET = 2500  # the hard cap per species
TRI_GUIDE = {"Common": 1800, "Uncommon": 1800, "Rare": 1800, "Epic": 2200, "Legendary": 2200, "Cosmic": 2200, "Secret": 2200}  # the target per tier: phones draw dozens at once
FACE_SLOTS = ("EyeWhite", "Pupil", "Mouth", "EyeHighlight")
DEFAULT_SEGMENTS = {"sphere": 12, "icosphere": 2, "cube": 1, "cylinder": 8, "cone": 8, "torus": 16}
SMOOTH_BY_DEFAULT = {"sphere": True, "icosphere": True, "cube": False, "cylinder": True, "cone": True, "torus": True, "sweep": True}

# The Surface pass (docs/vault/06-art-pipelines/Surface-Pass.md, layer B): what species_bodies.py does to a built body so the
# hard primitives stop reading as flat plastic. `--no-surface` skips all of it and keeps the old output byte for byte.
#   smooth_angle   degrees. Every part that is smooth (or a cube) is shaded smooth, with the edges sharper than this left creased
#                  (Blender's Shade Smooth by Angle). Parts a recipe marks flat=True (the faceted rocks, crystals and shards) stay flat.
#   bevel_*        a Bevel modifier on cubes and cylinders, applied before the join: width in studs, 2 segments, only edges sharper than
#                  bevel_angle (a cylinder's side seams are softer than that, so only the rims and cube corners round), and not on
#                  anything thinner than bevel_min_dim in any direction (a rod or a reed would lose its shape and its triangles).
#   gradient       a greyscale vertex colour written to the mesh and exported in the GLB. Roblox multiplies it with the part's Color,
#                  so the slot's hue is untouched: crown 1.0 (no change) at the top, belly darker at the feet, `down` more again where
#                  the surface faces the ground (a fake ambient occlusion). Only the listed slots take it; the face stays white.
SURFACE = {
    "smooth_angle": 55.0,
    "bevel_width": 0.05,
    "bevel_segments": 2,
    "bevel_angle": 60.0,
    "bevel_min_dim": 0.4,
    "gradient": {"crown": 1.0, "belly": 0.7, "down": 0.18, "slots": ("Body", "BodyDark", "Accessory", "Trim", "Belly")},
}


# ------------------------------------------------------------------------------------------------ tiny maths
def _rx(a):
    c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
    return ((1.0, 0.0, 0.0), (0.0, c, -s), (0.0, s, c))


def _ry(a):
    c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
    return ((c, 0.0, s), (0.0, 1.0, 0.0), (-s, 0.0, c))


def _rz(a):
    c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
    return ((c, -s, 0.0), (s, c, 0.0), (0.0, 0.0, 1.0))


def mm(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def mv(m, v):
    return tuple(sum(m[i][k] * v[k] for k in range(3)) for i in range(3))


def euler_matrix(rot):
    """Blender's XYZ Euler (degrees): X first, then Y, then Z, about the global axes."""
    return mm(_rz(rot[2]), mm(_ry(rot[1]), _rx(rot[0])))


def mirror_matrix(m):
    """M R M for M = diag(-1, 1, 1): the rotation of the mirrored part."""
    return tuple(tuple(m[i][j] * (-1.0 if (i == 0) != (j == 0) else 1.0) for j in range(3)) for i in range(3))


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _mul(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def _len(a):
    return math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


def _unit(a):
    n = _len(a)
    return (a[0] / n, a[1] / n, a[2] / n)


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def aim(d):
    """Euler degrees that turn a primitive's +z axis toward direction d."""
    d = _unit(d)
    return (math.degrees(-math.asin(max(-1.0, min(1.0, d[1])))), math.degrees(math.atan2(d[0], d[2])), 0.0)


def polar(r, deg):
    """(cos, sin) scaled by r: a point on a circle, angle in degrees."""
    return (r * math.cos(math.radians(deg)), r * math.sin(math.radians(deg)))


# ------------------------------------------------------------------------------------------------ step makers
def step(prim, slot, loc, scale, rot=(0.0, 0.0, 0.0), segments=None, mirror=False, name="", **extra):
    if isinstance(scale, (int, float)):
        scale = (scale, scale, scale)
    out = {"prim": prim, "slot": slot, "loc": tuple(float(v) for v in loc), "rot": tuple(float(v) for v in rot),
           "scale": tuple(float(v) for v in scale), "segments": int(segments or DEFAULT_SEGMENTS[prim]),
           "mirror": bool(mirror), "name": name}
    out.update(extra)
    return out


def sph(slot, loc, scale, **kw):
    return step("sphere", slot, loc, scale, **kw)


def ico(slot, loc, scale, **kw):
    return step("icosphere", slot, loc, scale, **kw)


def cyl(slot, loc, scale, **kw):
    return step("cylinder", slot, loc, scale, **kw)


def cone(slot, loc, scale, **kw):
    return step("cone", slot, loc, scale, **kw)


def cube(slot, loc, scale, **kw):
    return step("cube", slot, loc, scale, **kw)


def tor(slot, loc, scale, **kw):
    return step("torus", slot, loc, scale, **kw)


def rod(slot, a, b, r, r2=None, segments=6, **kw):
    """A cylinder (a tapered cone when r2 is given) from point a to point b: radius r at a, r2 at b."""
    d = _sub(b, a)
    half = _len(d) / 2.0
    mid = _mul(_add(a, b), 0.5)
    if r2 is None or abs(r2 - r) < 1e-9:
        return step("cylinder", slot, mid, (r, r, half), rot=aim(d), segments=segments, **kw)
    return step("cone", slot, mid, (r, r, half), rot=aim(d), segments=segments, tip=r2 / r, **kw)


def spike(slot, base, tip, r, segments=5, **kw):
    """A cone from base (its wide end, radius r) to tip (a point)."""
    d = _sub(tip, base)
    return step("cone", slot, _mul(_add(base, tip), 0.5), (r, r, _len(d) / 2.0), rot=aim(d), segments=segments, **kw)


def ellipsoid_point(c, s, ux, uy, uz):
    """The point on an upright ellipsoid (centre c, radii s) in direction (ux, uy, uz), pushed out to the surface."""
    n = math.sqrt(ux * ux + uy * uy + uz * uz)
    return (c[0] + s[0] * ux / n, c[1] + s[1] * uy / n, c[2] + s[2] * uz / n)


def sweep(slot, pts, radii, name=""):
    """A tube through the points (a Catmull-Rom curve) with a radius at each point: a tail or a serpent body as ONE tapering shape.
    Built only by species_sculpt.py --method hybrid (see the docstring at the top); the step has the keys expand() needs."""
    pts = [tuple(float(v) for v in p) for p in pts]
    radii = [float(r) for r in radii]
    if len(pts) != len(radii) or len(pts) < 2:
        raise ValueError("a sweep needs one radius per point and at least two points")
    return {"prim": "sweep", "slot": slot, "name": name, "loc": pts[0], "rot": (0.0, 0.0, 0.0), "scale": (max(radii),) * 3, "segments": 0,
            "mirror": False, "pts": pts, "radii": radii}


def crom(pts, u):
    """The point of the Catmull-Rom curve through pts (the curve species_sculpt.add_sweep uses) at u in [0, 1] along the control points
    (equal parameter steps, not equal length), and the unit tangent there: ((x, y, z), (tx, ty, tz))."""
    n = len(pts) - 1
    f = max(0.0, min(1.0, u)) * n
    i = min(int(f), n - 1)
    t = f - i
    p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, n)]
    pos, tan = [], []
    for k in range(3):
        pos.append(0.5 * (2 * p1[k] + (p2[k] - p0[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t * t + (3 * p1[k] - p0[k] - 3 * p2[k] + p3[k]) * t ** 3))
        tan.append(0.5 * ((p2[k] - p0[k]) + 2 * (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t + 3 * (3 * p1[k] - p0[k] - 3 * p2[k] + p3[k]) * t * t))
    return tuple(pos), _unit(tuple(tan))


# ================================================================================================ the recipes
# World 1 (Verdant): 16 full recipes, batch 1..5 = the order of tonight. The three Haunted Nebula event species were already
# rebuilt by tools/blender/event_species.py. The Frostbyte 16 follow the event stubs, between the FROSTBYTE markers (written 2026-10-15).

RECIPES = {}


def _bolt(slot, base, d, lengths, radii, bend=38.0):
    """A lightning bolt: three tapered cones that zig and zag in the YZ plane, starting at `base` heading along d."""
    steps = []
    p = base
    for i, (ln, r) in enumerate(zip(lengths, radii)):
        a = math.radians(bend * (1 if i % 2 else -1) if i else 0.0)
        d = (d[0], d[1] * math.cos(a) - d[2] * math.sin(a), d[1] * math.sin(a) + d[2] * math.cos(a))
        d = _unit(d)
        q = _add(p, _mul(d, ln))
        r2 = radii[i + 1] if i + 1 < len(radii) else 0.0
        steps.append(rod(slot, p, q, r, r2 if r2 > 0 else 0.02, segments=4, flat=True))
        p = q
    return steps


# ---------------------------------------------------------------------------------------- batch 1: round commons
RECIPES["Mossbop"] = {
    "tier": "Common", "world": 1, "biome": "Meadow", "batch": 1, "status": "recipe", "height": 2.64,
    "silhouette": "a wide squat mound with a bumpy skyline of seven moss clumps, two big feet and one sturdy sprout with a bud leaning off the top",
    "hero": "the moss: lumpy clumps over a smooth ball, and the sprout with an orange bud",
    "face": {"on": "body", "eye_scale": 1.2, "eye_gap": 1.0, "eye_tilt": 0.0, "mouth": "o", "look": (0.1, -0.1), "cross": 0.06},
    "palette": {"BodyDark": "3F8F2E", "Accessory": "FF8A3D"},
    "steps": [
        sph("Body", (0, 0, 1.05), (1.3, 1.2, 1.0), segments=20, name="body"),
        sph("BodyDark", (0.62, -0.6, 0.24), (0.42, 0.5, 0.24), segments=10, mirror=True, name="foot"),
        sph("BodyDark", (0.8, 0.5, 0.22), (0.38, 0.42, 0.22), segments=10, mirror=True, name="foot"),
        sph("BodyDark", (-0.5, 0.25, 1.95), (0.46, 0.42, 0.34), segments=8, name="moss"),
        sph("BodyDark", (0.55, 0.15, 1.92), (0.4, 0.38, 0.32), segments=8, name="moss"),
        sph("BodyDark", (0.0, 0.95, 1.55), (0.55, 0.45, 0.45), segments=8, name="moss"),
        sph("BodyDark", (-1.18, 0.05, 1.45), (0.36, 0.36, 0.34), segments=8, name="moss"),
        sph("BodyDark", (1.2, 0.3, 1.25), (0.32, 0.32, 0.3), segments=8, name="moss"),
        sph("BodyDark", (-0.1, -0.62, 1.93), (0.3, 0.26, 0.24), segments=8, name="moss"),
        sph("BodyDark", (0.75, 0.85, 0.95), (0.3, 0.3, 0.28), segments=8, name="moss"),
        rod("BodyDark", (0.12, 0.05, 1.95), (0.24, 0.05, 2.36), 0.11, 0.09, segments=7, name="stalk"),
        sph("Accessory", (0.25, 0.05, 2.41), (0.24, 0.24, 0.23), segments=10, name="bud"),
        sph("BodyDark", (0.5, 0.05, 2.18), (0.27, 0.07, 0.13), rot=(0, -25, -10), segments=8, name="leaf"),
        sph("BodyDark", (-0.08, 0.05, 2.16), (0.27, 0.07, 0.13), rot=(0, 25, 10), segments=8, name="leaf"),
    ],
}

RECIPES["Pebblet"] = {
    "tier": "Common", "world": 1, "biome": "Cave", "batch": 1, "status": "recipe", "height": 2.37,
    "silhouette": "a faceted egg-shaped stone lifted on two long legs with big flat feet, stone-chip fists out to the sides and a mossy patch on top",
    "hero": "the legs: a pebble with real legs, daylight under its belly",
    "face": {"on": "body", "eye_scale": 0.9, "eye_gap": 0.85, "eye_tilt": -8.0, "mouth": "wide", "lid": 0.3, "lift": 0.05},
    "palette": {"BodyDark": "6B6760", "Accessory": "78C850"},
    "steps": [
        ico("Body", (0, 0.05, 1.42), (1.15, 1.0, 0.88), rot=(4, 6, 8), segments=2, flat=True, name="body"),
        ico("Body", (-0.8, 0.55, 1.95), (0.4, 0.38, 0.36), segments=1, flat=True, name="bump"),
        ico("Body", (0.85, 0.45, 0.95), (0.36, 0.34, 0.34), segments=1, flat=True, name="bump"),
        rod("BodyDark", (0.42, 0.05, 0.85), (0.45, -0.02, 0.1), 0.17, segments=7, mirror=True, name="leg"),
        sph("BodyDark", (0.45, -0.14, 0.1), (0.33, 0.46, 0.1), segments=10, mirror=True, name="foot"),
        ico("BodyDark", (1.22, -0.1, 1.15), (0.28, 0.28, 0.28), segments=1, flat=True, mirror=True, name="fist"),
        sph("Accessory", (0.0, 0.05, 2.2), (0.62, 0.55, 0.16), segments=10, name="moss"),
        sph("Accessory", (-0.45, 0.1, 2.1), (0.34, 0.3, 0.13), segments=8, name="moss"),
        sph("Accessory", (0.42, -0.05, 2.12), (0.3, 0.28, 0.12), segments=8, name="moss"),
    ],
}

RECIPES["Puffpuff"] = {
    "tier": "Common", "world": 1, "biome": "Meadow", "batch": 1, "status": "recipe", "height": 2.20,
    "silhouette": "a starburst: a small ball ringed by about twenty wisps in even rings, each ending in a seed dot, standing on two leaf feet",
    "hero": "the dandelion puff: radiating wisps with yellow seed tips",
    "face": {"on": "body", "eye_scale": 1.35, "eye_gap": 1.1, "eye_tilt": -10.0, "mouth": "o", "lid": 0.25, "look": (0.0, 0.0)},
    "palette": {"BodyDark": "8FC96A", "Accessory": "FFD84A"},
    "steps": [
        sph("Body", (0, 0, 1.1), (0.74, 0.72, 0.72), segments=16, name="body"),
        sph("BodyDark", (0.36, -0.25, 0.2), (0.28, 0.46, 0.2), rot=(0, 0, 18), segments=10, mirror=True, name="leaffoot"),
    ],
}


# (elevation in degrees above the horizon, azimuths in degrees from +x towards the back (+y)): each azimuth is built on both sides of x
# (mirrored), so a ring of 0, 60 and -60 is a full hexagon of six; 90 is the back of the ring, on the centre line (built once).
PUFF_RINGS = ((62.0, (0.0, 60.0, -60.0)), (34.0, (30.0, -30.0, 90.0)), (6.0, (0.0, 60.0, -32.0)), (-22.0, (30.0, 90.0)))


def _puff_wisps():
    """Seed wisps in even rings round the ball (PUFF_RINGS), one on top, none in front of the face."""
    out = []
    centre = (0.0, 0.0, 1.1)
    for elev, azimuths in PUFF_RINGS:
        for az in azimuths:
            e, a = math.radians(elev), math.radians(az)
            d = (math.cos(e) * math.cos(a), math.cos(e) * math.sin(a), math.sin(e))
            if d[1] < -0.62 and elev < 40.0:
                continue  # in front of the eyes and the mouth
            mirror = abs(d[0]) > 0.05
            out.append(rod("BodyDark", _add(centre, _mul(d, 0.6)), _add(centre, _mul(d, 0.95)), 0.045, segments=4, mirror=mirror, name="wisp"))
            out.append(ico("Accessory", _add(centre, _mul(d, 1.0)), 0.13, segments=1, mirror=mirror, name="seed"))
    out.append(rod("BodyDark", (0, 0.0, 1.7), (0, 0.0, 2.02), 0.045, segments=4, name="wisp"))
    out.append(ico("Accessory", (0, 0.0, 2.07), 0.13, segments=1, name="seed"))
    return out


RECIPES["Puffpuff"]["steps"] += _puff_wisps()

# ---------------------------------------------------------------------------------------- batch 2: bugs and thin parts
RECIPES["Glimmo"] = {
    "tier": "Common", "world": 1, "biome": "Forest", "batch": 2, "status": "recipe", "height": 2.70,
    "silhouette": "a drooping bell on a flared skirt with a fringe of dangling tendrils, a fat round lamp held out beside it on a curled stalk and two bobble antennae",
    "hero": "the glowing firefly lamp swinging beside the bell",
    "face": {"on": "body", "eye_scale": 1.35, "eye_gap": 0.95, "eye_tilt": 0.0, "mouth": "smile", "look": (0.0, 0.1)},
    "palette": {"BodyDark": "E4A83A", "Accessory": "B8FF4F"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0, 0, 1.7), (1.05, 1.0, 0.85), segments=16, name="body"),
        cone("BodyDark", (0, 0, 0.92), (1.0, 0.95, 0.32), tip=0.7, segments=16, name="skirt"),
        rod("BodyDark", (0.7, 0.2, 2.05), (1.4, 0.1, 2.52), 0.09, 0.075, segments=6, name="stalk"),
        rod("BodyDark", (1.4, 0.1, 2.52), (1.95, 0.0, 2.2), 0.075, 0.07, segments=6, name="stalk"),
        sph("Accessory", (1.95, -0.05, 1.7), (0.55, 0.55, 0.62), segments=12, name="lamp"),
        rod("BodyDark", (0.32, -0.15, 2.3), (0.5, -0.22, 2.5), 0.045, segments=5, mirror=True, name="antenna"),
        sph("Accessory", (0.5, -0.22, 2.6), 0.1, segments=8, mirror=True, name="antennatip"),
    ],
}
for _a in range(8):
    _x, _y = polar(0.86, 22.5 + 45.0 * _a)
    RECIPES["Glimmo"]["steps"].append(rod("BodyDark", (_x, _y, 0.72), (_x * 1.12, _y * 1.12, 0.0), 0.13, 0.05, segments=6, name="tendril"))
for _a in range(4):
    _x, _y = polar(0.45, 45.0 + 90.0 * _a)
    RECIPES["Glimmo"]["steps"].append(rod("BodyDark", (_x, _y, 0.75), (_x * 1.1, _y * 1.1, 0.12), 0.1, 0.04, segments=6, name="tendril"))

RECIPES["Twiglet"] = {
    "tier": "Common", "world": 1, "biome": "Forest", "batch": 2, "status": "recipe", "height": 2.71,
    "silhouette": "a big round head on a thin stick body with four long bent legs like a spider, and a huge tilted leaf for a hat",
    "hero": "the leaf hat, wider than the head, with its midrib",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.05, "eye_tilt": 0.0, "mouth": "o", "look": (-0.1, -0.05), "cross": 0.1},
    "palette": {"BodyDark": "5C3A1C", "Accessory": "6FBF3F"},
    "steps": [
        sph("Body", (0, 0, 1.72), (0.88, 0.82, 0.82), segments=16, name="head"),
        rod("Body", (0, 0.05, 1.0), (0, 0.1, 0.65), 0.2, segments=7, name="neck"),
        sph("Body", (0, 0.1, 0.66), (0.32, 0.34, 0.3), segments=8, name="hips"),
        rod("BodyDark", (0.15, -0.0, 0.7), (0.8, -0.35, 1.0), 0.09, 0.07, segments=5, mirror=True, name="thigh"),
        rod("BodyDark", (0.8, -0.35, 1.0), (1.1, -0.7, 0.0), 0.07, 0.05, segments=5, mirror=True, name="shin"),
        rod("BodyDark", (0.15, 0.2, 0.7), (0.8, 0.55, 1.0), 0.09, 0.07, segments=5, mirror=True, name="thigh"),
        rod("BodyDark", (0.8, 0.55, 1.0), (1.1, 0.95, 0.0), 0.07, 0.05, segments=5, mirror=True, name="shin"),
        sph("BodyDark", (0.8, -0.35, 1.0), 0.12, segments=6, mirror=True, name="knee"),
        sph("BodyDark", (0.8, 0.55, 1.0), 0.12, segments=6, mirror=True, name="knee"),
        sph("BodyDark", (1.1, -0.72, 0.06), (0.14, 0.2, 0.06), segments=6, mirror=True, name="toe"),
        sph("BodyDark", (1.1, 0.97, 0.06), (0.14, 0.2, 0.06), segments=6, mirror=True, name="toe"),
        rod("BodyDark", (0.25, -0.3, 0.92), (0.62, -0.6, 0.62), 0.065, segments=5, mirror=True, name="arm"),
        sph("BodyDark", (0.64, -0.62, 0.6), 0.1, segments=6, mirror=True, name="hand"),
        sph("Accessory", (0.12, 0.0, 2.44), (1.15, 0.52, 0.12), rot=(0, -10, 18), segments=12, name="leaf"),
        cube("BodyDark", (0.12, 0.0, 2.52), (1.08, 0.03, 0.025), rot=(0, -10, 18), name="rib"),
    ],
}

RECIPES["Buzzlebee"] = {
    "tier": "Uncommon", "world": 1, "biome": "Meadow", "batch": 2, "status": "recipe", "height": 1.76,
    "silhouette": "a low round bee hovering on four dot feet, a head with huge eyes in front, a striped abdomen ending in a stinger, two wings up and out and a big box backpack",
    "hero": "the tiny backpack: a brown box with a flap, bigger than it should be, and a bright buckle",
    "face": {"on": "head", "eye_scale": 1.6, "eye_gap": 1.15, "eye_tilt": 0.0, "mouth": "wide", "look": (0.0, 0.05), "cross": 0.12},
    "palette": {"BodyDark": "6B4423", "Accessory": "A8E6FF"},
    "steps": [
        sph("Body", (0, -0.45, 0.95), (0.78, 0.74, 0.74), segments=14, name="head"),
        sph("Body", (0, 0.35, 0.92), (0.78, 0.8, 0.72), segments=14, name="thorax"),
        sph("BodyDark", (0, 1.05, 0.82), (0.68, 0.6, 0.62), segments=12, name="stripe"),
        sph("Body", (0, 1.55, 0.76), (0.52, 0.5, 0.52), segments=12, name="tail"),
        spike("BodyDark", (0, 1.95, 0.72), (0, 2.4, 0.7), 0.12, segments=6, name="stinger"),
        sph("Accessory", (0.85, 0.45, 1.4), (0.62, 0.34, 0.07), rot=(0, -35, 20), segments=10, mirror=True, name="wing"),
        cube("BodyDark", (0, 1.12, 1.22), (0.4, 0.28, 0.42), name="pack"),
        cube("BodyDark", (0, 1.12, 1.62), (0.36, 0.3, 0.06), name="flap"),
        cube("Accessory", (0, 1.42, 1.5), (0.1, 0.04, 0.12), name="buckle"),
        rod("BodyDark", (0.25, -0.55, 1.55), (0.38, -0.62, 1.66), 0.04, segments=5, mirror=True, name="antenna"),
        sph("BodyDark", (0.38, -0.62, 1.68), 0.08, segments=6, mirror=True, name="antennatip"),
        sph("BodyDark", (0.45, -0.35, 0.12), (0.14, 0.14, 0.12), segments=6, mirror=True, name="leg"),
        sph("BodyDark", (0.45, 0.6, 0.12), (0.14, 0.14, 0.12), segments=6, mirror=True, name="leg"),
    ],
}

RECIPES["Lanternewt"] = {
    "tier": "Uncommon", "world": 1, "biome": "Forest", "batch": 2, "status": "recipe", "height": 2.27,
    "silhouette": "a long low newt on four splayed legs, chin near the ground, with its tail curling up and out to one side in a tall hook and a caged lantern hanging from the tip",
    "hero": "the glowing tail lantern, with a cage ring and a cap",
    "face": {"on": "head", "eye_scale": 1.1, "eye_gap": 1.2, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.25},
    "palette": {"BodyDark": "8C3F1C", "Accessory": "FFD84A"}, "glow": {"Accessory": 2.5},
    "steps": [
        sph("Body", (0, 0.45, 0.8), (0.78, 1.05, 0.72), segments=12, name="torso"),
        sph("Body", (0, -0.8, 0.85), (0.86, 0.82, 0.8), segments=14, name="head"),
        rod("Body", (0.55, -0.3, 0.6), (0.85, -0.55, 0.1), 0.16, segments=5, mirror=True, name="leg"),
        rod("Body", (0.6, 0.95, 0.6), (0.9, 1.15, 0.1), 0.16, segments=5, mirror=True, name="leg"),
        sph("BodyDark", (0.85, -0.65, 0.07), (0.25, 0.33, 0.07), segments=6, mirror=True, name="foot"),
        sph("BodyDark", (0.9, 1.2, 0.07), (0.25, 0.33, 0.07), segments=6, mirror=True, name="foot"),
        sph("BodyDark", (0.36, 0.1, 1.46), (0.18, 0.18, 0.09), segments=6, mirror=True, name="spot"),
        sph("BodyDark", (0.0, 0.7, 1.48), (0.2, 0.2, 0.1), segments=6, name="spot"),
        sph("BodyDark", (0.4, 1.1, 1.22), (0.17, 0.17, 0.09), segments=6, mirror=True, name="spot"),
        sph("Body", (-0.2, 1.4, 0.92), (0.46, 0.5, 0.46), segments=10, name="tail"),
        sph("Body", (-0.7, 1.75, 1.1), (0.38, 0.4, 0.38), segments=10, name="tail"),
        sph("Body", (-1.15, 1.85, 1.45), (0.3, 0.32, 0.3), segments=10, name="tail"),
        sph("Body", (-1.4, 1.7, 1.85), (0.24, 0.26, 0.24), segments=10, name="tail"),
        rod("BodyDark", (-1.42, 1.62, 2.0), (-1.55, 1.2, 2.18), 0.06, segments=5, name="hook"),
        sph("Accessory", (-1.55, 1.15, 1.62), (0.36, 0.36, 0.38), segments=12, name="lantern"),
        tor("BodyDark", (-1.55, 1.15, 1.62), (0.4, 0.4, 0.4), minor=0.14, segments=12, mseg=4, name="cage"),
        spike("BodyDark", (-1.55, 1.15, 1.94), (-1.55, 1.15, 2.2), 0.2, segments=8, name="cap"),
    ],
}

# ---------------------------------------------------------------------------------------- batch 3: props on round bodies
RECIPES["Snailbyte"] = {
    "tier": "Uncommon", "world": 1, "biome": "Cave", "batch": 3, "status": "recipe", "height": 2.51,
    "silhouette": "a long flat foot with the head raised on a neck like a periscope and a huge coiled disc shell standing up on its back, two eyestalk nubs",
    "hero": "the metal shell: a stepped spiral of five discs, silver and dark in turn",
    "face": {"on": "head", "eye_scale": 1.1, "eye_gap": 1.2, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.4},
    "palette": {"BodyDark": "4F7390", "Accessory": "C8CDD3"}, "metal": {"Accessory": 1.0},
    "steps": [
        sph("Body", (0, 0.2, 0.34), (0.85, 1.55, 0.34), segments=14, name="foot"),
        sph("BodyDark", (0, 0.2, 0.14), (0.92, 1.62, 0.16), segments=12, name="sole"),
        sph("Body", (0, -0.75, 0.9), (0.68, 0.7, 0.65), segments=12, name="neck"),
        sph("Body", (0, -0.8, 1.5), (0.95, 0.9, 0.88), segments=16, name="head"),
        rod("BodyDark", (0.3, -0.85, 2.2), (0.45, -0.95, 2.4), 0.05, segments=5, mirror=True, name="stalk"),
        sph("BodyDark", (0.45, -0.95, 2.42), 0.09, segments=6, mirror=True, name="stalktip"),
        sph("Accessory", (0, 1.0, 1.42), (0.6, 1.08, 1.08), segments=10, name="shell"),
        sph("BodyDark", (0.0, 0.95, 1.44), (0.72, 0.85, 0.85), segments=10, name="shell"),
        sph("Accessory", (0.0, 1.05, 1.36), (0.82, 0.65, 0.65), segments=10, name="shell"),
        sph("BodyDark", (0.0, 0.93, 1.34), (0.9, 0.47, 0.47), segments=10, name="shell"),
        sph("Accessory", (0.0, 1.01, 1.4), (0.98, 0.28, 0.28), segments=10, name="shell"),
    ],
}

RECIPES["Rocklobber"] = {
    "tier": "Rare", "world": 1, "biome": "Cave", "batch": 3, "status": "recipe", "height": 2.42,
    "silhouette": "a crab standing tall on six thin legs with its body lifted clear of the ground: one huge boulder fist raised beside it under a tall crown of amber crystals, the other fist small and low, so it leans like a boxer",
    "hero": "the boulder claws, the raised one sprouting a tall crown of glowing amber crystals",
    "face": {"on": "body", "eye_scale": 1.4, "eye_gap": 1.25, "eye_tilt": 10.0, "mouth": "zigzag", "lid": 0.3, "mouth_scale": 1.35},
    "palette": {"BodyDark": "8A857D", "Accessory": "FFA928"}, "glow": {"Accessory": 1.5}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0.1, 1.2), (0.95, 0.8, 0.62), segments=16, name="body"),
        sph("BodyDark", (0.0, 0.5, 1.75), (0.5, 0.36, 0.18), segments=8, name="plate"),
        rod("Body", (0.65, -0.3, 1.0), (1.05, -0.3, 0.0), 0.13, 0.09, segments=5, mirror=True, name="leg"),
        rod("Body", (0.7, 0.15, 1.0), (1.1, 0.15, 0.0), 0.13, 0.09, segments=5, mirror=True, name="leg"),
        rod("Body", (0.65, 0.55, 1.0), (1.0, 0.6, 0.0), 0.13, 0.09, segments=5, mirror=True, name="leg"),
        rod("Body", (0.7, -0.15, 1.2), (1.05, -0.12, 1.3), 0.2, segments=6, name="arm"),
        ico("BodyDark", (1.3, -0.12, 1.32), (0.8, 0.72, 0.7), rot=(10, 0, 25), segments=2, flat=True, name="fist"),
        spike("Accessory", (1.28, -0.17, 1.75), (1.23, -0.22, 2.42), 0.3, segments=5, name="crystal"),
        spike("Accessory", (1.63, -0.14, 1.7), (1.88, -0.22, 2.2), 0.24, segments=5, name="crystal"),
        spike("Accessory", (0.93, -0.2, 1.72), (0.74, -0.27, 2.18), 0.24, segments=5, name="crystal"),
        spike("Accessory", (1.38, 0.1, 1.72), (1.46, 0.15, 2.1), 0.18, segments=5, name="crystal"),
        rod("Body", (-0.6, -0.35, 1.0), (-0.8, -0.65, 0.85), 0.18, segments=6, name="arm"),
        ico("BodyDark", (-0.95, -0.8, 0.78), (0.52, 0.47, 0.47), segments=2, flat=True, name="fist"),
        spike("Accessory", (-0.95, -0.8, 1.1), (-0.92, -0.85, 1.5), 0.2, segments=5, name="crystal"),
    ],
}

RECIPES["Zapfinch"] = {
    "tier": "Rare", "world": 1, "biome": "Forest", "batch": 3, "status": "recipe", "height": 2.86,
    "silhouette": "a plump bird balanced on two thin legs with a fan of three tail feathers behind, stubby wings out to the sides and a three-pronged antenna crest rising from the head",
    "hero": "the antenna crest: three glowing rods ending in round tips",
    "face": {"on": "body", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": 8.0, "mouth": "o", "lid": 0.3, "look": (0.05, 0.0)},
    "palette": {"BodyDark": "2F5F8F", "Accessory": "FFE45C"}, "glow": {"Accessory": 1.5}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0, 1.5), (1.05, 0.98, 0.98), segments=16, name="body"),
        rod("BodyDark", (0.38, 0.05, 0.7), (0.42, -0.05, 0.1), 0.09, segments=6, mirror=True, name="leg"),
        sph("BodyDark", (0.42, -0.25, 0.06), (0.3, 0.45, 0.06), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (1.0, 0.2, 1.4), (0.18, 0.6, 0.4), rot=(0, -15, 20), segments=10, mirror=True, name="wing"),
        sph("BodyDark", (0.0, 1.0, 1.15), (0.14, 0.1, 0.65), rot=(-48, 0, 0), segments=8, name="tail"),
        sph("BodyDark", (0.2, 0.98, 1.12), (0.14, 0.1, 0.6), rot=(-48, 0, -24), segments=8, mirror=True, name="tail"),
        rod("Accessory", (0, -0.05, 2.35), (0, -0.05, 2.66), 0.045, segments=5, name="crest"),
        sph("Accessory", (0, -0.05, 2.71), 0.15, segments=8, name="crest"),
        rod("Accessory", (0.2, -0.05, 2.38), (0.5, -0.05, 2.58), 0.045, segments=5, mirror=True, name="crest"),
        sph("Accessory", (0.5, -0.05, 2.63), 0.13, segments=8, mirror=True, name="crest"),
    ],
}

# ---------------------------------------------------------------------------------------- batch 4: fans and sweeps
RECIPES["Sparkfox"] = {
    "tier": "Rare", "world": 1, "biome": "Meadow", "batch": 4, "status": "recipe", "height": 2.50,
    "silhouette": "a sitting fox with a round head, two tall pointed ears and cheek tufts, and a thick tail rising behind like a paintbrush with a glowing tip above the ears",
    "hero": "the paintbrush tail: a tapering handle, a ferrule ring and glowing bristles",
    "face": {"on": "head", "eye_scale": 1.05, "eye_gap": 1.1, "eye_tilt": 10.0, "mouth": "smile", "lid": 0.3},
    "palette": {"BodyDark": "A8431C", "Accessory": "FFE066"}, "glow": {"Accessory": 2.0}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0.4, 0.8), (0.72, 0.92, 0.72), segments=12, name="torso"),
        sph("Body", (0, -0.3, 1.5), (1.02, 0.82, 0.74), segments=14, name="head"),
        spike("Body", (0.5, -0.25, 1.85), (0.9, -0.12, 2.55), 0.36, segments=6, mirror=True, name="ear"),
        spike("BodyDark", (0.53, -0.42, 1.92), (0.84, -0.3, 2.44), 0.2, segments=6, mirror=True, name="innerear"),
        spike("BodyDark", (0.8, -0.35, 1.35), (1.25, -0.5, 1.25), 0.2, segments=6, mirror=True, name="cheek"),
        rod("Body", (0.4, -0.35, 0.8), (0.42, -0.55, 0.1), 0.17, segments=6, mirror=True, name="foreleg"),
        sph("BodyDark", (0.42, -0.62, 0.09), (0.22, 0.3, 0.09), segments=8, mirror=True, name="paw"),
        sph("Body", (0.75, 0.55, 0.55), (0.45, 0.55, 0.5), segments=10, mirror=True, name="haunch"),
        sph("BodyDark", (0.65, 0.2, 0.09), (0.25, 0.4, 0.09), segments=8, mirror=True, name="hindpaw"),
        sph("Body", (0.5, 1.25, 0.7), (0.4, 0.45, 0.4), segments=10, name="tail"),
        sph("Body", (1.15, 1.15, 1.0), (0.34, 0.4, 0.36), segments=10, name="tail"),
        sph("Body", (1.6, 0.9, 1.4), (0.3, 0.34, 0.34), segments=10, name="tail"),
        tor("BodyDark", (1.7, 0.7, 1.74), (0.27, 0.27, 0.27), rot=aim((0.25, -0.3, 0.5)), minor=0.3, segments=12, mseg=4, name="ferrule"),
        sph("Accessory", (1.78, 0.55, 2.0), (0.34, 0.34, 0.5), rot=aim((0.25, -0.3, 0.5)), segments=10, name="bristles"),
        spike("Accessory", (1.84, 0.45, 2.22), (1.9, 0.38, 2.5), 0.24, segments=8, name="bristletip"),
    ],
}

_THUNDER_QUILLS = []
for _x, _angles in ((0.0, (-20, 5, 30, 55, 80)), (0.75, (-5, 20, 45, 70)), (-0.75, (-5, 20, 45, 70))):
    for _phi in _angles:
        _s, _c = math.sin(math.radians(_phi)), math.cos(math.radians(_phi))
        _k = math.sqrt(max(0.0, 1.0 - (_x / 1.45) ** 2))
        _base = (_x, 0.45 + 1.5 * _s * _k, 1.4 + 1.1 * _c * _k)
        _THUNDER_QUILLS += _bolt("Accessory", _base, (_x * 0.35, _s, _c), (0.34, 0.3, 0.26), (0.17, 0.12, 0.09))

RECIPES["Thunderhog"] = {
    "tier": "Epic", "world": 1, "biome": "Meadow", "batch": 4, "status": "recipe", "height": 3.37,
    "silhouette": "a low pear-shaped hedgehog nosing forward, a magenta collar behind the face and a mane of thirteen jagged lightning-bolt quills fanned over its back",
    "hero": "the lightning quills: zigzag bolts that glow",
    "face": {"on": "head", "eye_scale": 1.15, "eye_gap": 1.1, "eye_tilt": 12.0, "mouth": "zigzag", "lid": 0.32, "mouth_scale": 1.25},
    "palette": {"BodyDark": "5C2C70", "Accessory": "FFE23B"}, "glow": {"Accessory": 2.0},
    "steps": [
        sph("Body", (0, 0.45, 1.4), (1.45, 1.55, 1.15), segments=16, name="rump"),
        sph("Body", (0, -1.1, 1.2), (1.0, 0.95, 0.9), segments=16, name="head"),
        tor("Trim", (0, -0.62, 1.25), (1.05, 1.05, 1.05), rot=(90, 0, 0), minor=0.11, segments=16, mseg=5, name="collar"),
        sph("BodyDark", (0.75, -0.4, 0.22), (0.35, 0.45, 0.22), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (0.85, 1.0, 0.2), (0.38, 0.45, 0.2), segments=8, mirror=True, name="foot"),
    ] + _THUNDER_QUILLS,
}

_WING_SHARDS = []
for _alpha, _len_, _w in ((56, 1.75, 0.5), (39, 1.7, 0.52), (22, 1.55, 0.5), (5, 1.25, 0.44), (-15, 0.85, 0.34)):
    _d = (math.cos(math.radians(_alpha)), 0.12, math.sin(math.radians(_alpha)))
    _s0 = (0.6, 0.4, 1.2)
    _WING_SHARDS.append(cone("Accessory", _add(_s0, _mul(_d, _len_ / 2.0)), (_w, 0.06, _len_ / 2.0), rot=aim(_d), segments=4, flat=True, mirror=True, name="shard"))

RECIPES["Gloomoth"] = {
    "tier": "Epic", "world": 1, "biome": "Cave", "batch": 4, "status": "recipe", "height": 2.64,
    "silhouette": "a plump fuzzy moth on stubby legs with a ruff, two huge V-spread wings made of ten glowing crystal blades and two feathery antennae, a magenta gem on its chest",
    "hero": "the crystal wings: five flat shards a side, glowing teal",
    "face": {"on": "body", "eye_scale": 1.25, "eye_gap": 1.0, "eye_tilt": -10.0, "mouth": "o", "lid": 0.0, "look": (0.0, 0.08)},
    "palette": {"BodyDark": "6B447B", "Accessory": "5CF0D0"}, "glow": {"Accessory": 1.5},
    "steps": [
        sph("Body", (0, 0.1, 1.3), (0.95, 0.88, 1.05), segments=16, name="body"),
        sph("BodyDark", (0.78, 0.0, 1.95), (0.3, 0.3, 0.28), segments=8, mirror=True, name="ruff"),
        sph("BodyDark", (0.6, 0.55, 2.12), (0.28, 0.28, 0.26), segments=8, mirror=True, name="ruff"),
        sph("BodyDark", (0.25, 0.85, 2.2), (0.26, 0.26, 0.24), segments=8, mirror=True, name="ruff"),
        ico("Trim", (0, -0.74, 0.85), (0.17, 0.12, 0.2), segments=1, flat=True, name="gem"),
        rod("BodyDark", (0.35, -0.1, 0.5), (0.4, -0.15, 0.05), 0.16, segments=6, mirror=True, name="leg"),
        sph("BodyDark", (0.4, -0.22, 0.06), (0.2, 0.3, 0.06), segments=8, mirror=True, name="foot"),
        rod("BodyDark", (0.25, -0.25, 2.25), (0.5, -0.35, 2.5), 0.05, segments=5, mirror=True, name="antenna"),
        ico("Accessory", (0.5, -0.35, 2.55), 0.09, segments=1, flat=True, mirror=True, name="antennatip"),
    ] + _WING_SHARDS,
}

# ---------------------------------------------------------------------------------------- batch 5: the regal three
# Gaiabloom: the grand one. The head is held high on a steep neck above a proud, forward chest; the antlers spread far wider than the body
# (about 4 studs against its 1.6) in front of a big gold halo that rings the head from behind.
_ANT_Y, _ANT_Z0 = -1.5, 3.5
_ANTLERS = []
for _p0, _p1, _r0, _r1 in (((0.26, _ANT_Y, _ANT_Z0), (0.85, _ANT_Y, 3.7), 0.15, 0.115),    # the main beam sweeps up and out
                           ((0.85, _ANT_Y, 3.7), (1.78, _ANT_Y, 3.82), 0.115, 0.085),
                           ((0.85, _ANT_Y, 3.7), (0.82, _ANT_Y, 3.92), 0.1, 0.075),      # a tine up from the elbow
                           ((1.35, _ANT_Y, 3.78), (1.46, _ANT_Y, 3.94), 0.085, 0.065),   # a tine up from the outer beam
                           ((0.4, _ANT_Y, 3.55), (0.14, _ANT_Y, 3.85), 0.1, 0.07)):      # an inner tine leaning toward the centre
    _ANTLERS.append(rod("BodyDark", _p0, _p1, _r0, _r1, segments=6, mirror=True, name="antler"))
for _p in ((1.82, _ANT_Y, 3.84), (0.82, _ANT_Y, 3.95), (1.46, _ANT_Y, 3.96), (0.14, _ANT_Y, 3.88)):
    _ANTLERS.append(sph("Accessory", _p, 0.2, segments=6, mirror=True, name="blossom"))

RECIPES["Gaiabloom"] = {
    "tier": "Legendary", "world": 1, "biome": "Meadow", "batch": 5, "status": "recipe", "height": 4.14,
    "silhouette": "a long-legged stag standing proud: a big forward chest, the head held high on a steep neck, a branching tree for antlers blossoming pink and spread far wider than the body, a big gold halo ringing the head from behind and a gold ring on the ground round its feet",
    "hero": "the tree antlers: bark branches with blossoms, spread wide over the halo",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.0, "eye_tilt": -6.0, "mouth": "smile", "lid": 0.3},
    "palette": {"BodyDark": "8A5A2F", "Accessory": "FF8FB3"},
    "steps": [
        sph("Body", (0, 0.75, 1.65), (0.82, 1.3, 0.6), segments=12, name="body"),
        sph("Body", (0, -0.4, 1.85), (0.8, 0.75, 0.78), segments=10, name="chest"),
        rod("Body", (0.55, -0.3, 1.5), (0.6, -0.4, 0.2), 0.24, 0.16, segments=6, mirror=True, name="leg"),
        rod("Body", (0.55, 1.5, 1.45), (0.62, 1.55, 0.2), 0.24, 0.16, segments=6, mirror=True, name="leg"),
        sph("BodyDark", (0.6, -0.45, 0.11), (0.22, 0.3, 0.11), segments=6, mirror=True, name="hoof"),
        sph("BodyDark", (0.62, 1.6, 0.11), (0.22, 0.3, 0.11), segments=6, mirror=True, name="hoof"),
        rod("Body", (0, -0.7, 2.2), (0, -1.4, 3.0), 0.44, 0.33, segments=8, name="neck"),
        sph("Body", (0, -1.5, 3.0), (0.74, 0.72, 0.65), segments=12, name="head"),
        sph("Body", (0.7, -1.4, 3.2), (0.42, 0.1, 0.23), rot=(0, 0, 35), segments=8, mirror=True, name="ear"),
        sph("BodyDark", (0, -1.02, 2.15), (0.3, 0.12, 0.42), rot=(20, 0, 0), segments=6, name="ruff"),
        sph("BodyDark", (0.4, -0.95, 2.3), (0.28, 0.12, 0.4), rot=(15, 0, 25), segments=6, mirror=True, name="ruff"),
        sph("Body", (0, 2.25, 2.15), (0.3, 0.35, 0.3), segments=10, name="tail"),
        tor("Trim", (0, -0.95, 2.95), (1.15, 1.15, 1.15), rot=(90, 0, 0), minor=0.1, segments=20, mseg=4, name="halo"),
        tor("Trim", (0, 0.5, 0.08), (1.9, 1.9, 1.9), minor=0.055, segments=16, mseg=4, name="groundring"),
        sph("Accessory", (0.95, -0.9, 0.18), 0.17, segments=6, mirror=True, name="flower"),
        sph("Accessory", (1.1, 1.3, 0.18), 0.17, segments=6, mirror=True, name="flower"),
        sph("Accessory", (0.2, -1.5, 0.16), 0.15, segments=6, name="flower"),
    ] + _ANTLERS,
}

# Radish: a smaller round body in front of a big rising sun. The disk (radius _SUN_R) is wider than the body so it frames it from
# behind; nine rays fan over the top (the ones that would dig into the ground are left out); the leaves are four broad blades that
# rise from the crown and curl outward and down like a radish top, not the spiky crown of a pineapple.
_SUN_C, _SUN_R, _SUN_TIP = (0.0, 0.85, 1.66), 1.5, 1.88
_SUN_RAYS = []
for _k in range(-1, 8):
    _a = 30.0 * _k
    _d = (math.cos(math.radians(_a)), 0.0, math.sin(math.radians(_a)))
    _mid = (_SUN_R + _SUN_TIP) / 2.0 + 0.02
    _SUN_RAYS.append(cone("Accessory", (_d[0] * _mid, _SUN_C[1], _SUN_C[2] + _d[2] * _mid), (0.2, 0.08, (_SUN_TIP - _SUN_R) / 2.0 + 0.05),
                          rot=aim(_d), segments=4, flat=True, name="ray"))
_RADISH_LEAVES = []
_CROWN = (0.0, 0.0, 2.25)
# (azimuth from +x towards the back in degrees, stem elevation, blade elevation: negative = drooping, stem length, blade length, blade width);
# each is built on both sides
for _az, _e1, _e2, _ls, _lb, _w in ((8.0, 48.0, -20.0, 0.85, 1.25, 0.4), (70.0, 70.0, 40.0, 0.8, 1.1, 0.36)):
    _a = math.radians(_az)
    _u = (math.cos(math.radians(_e1)) * math.cos(_a), math.cos(math.radians(_e1)) * math.sin(_a), math.sin(math.radians(_e1)))
    _v = (math.cos(math.radians(_e2)) * math.cos(_a), math.cos(math.radians(_e2)) * math.sin(_a), math.sin(math.radians(_e2)))
    _end = _add(_CROWN, _mul(_u, _ls))
    _RADISH_LEAVES.append(rod("BodyDark", _CROWN, _end, 0.09, 0.07, segments=6, mirror=True, name="leafstem"))
    _RADISH_LEAVES.append(sph("BodyDark", _add(_end, _mul(_v, _lb / 2.0 - 0.05)), (_w, 0.06, _lb / 2.0), rot=aim(_v), segments=10, mirror=True, name="leaf"))

RECIPES["Radish"] = {
    "tier": "Cosmic", "world": 1, "biome": "Meadow", "batch": 5, "status": "recipe", "height": 3.64,
    "silhouette": "a round radish with four broad leaves curling out of its crown in front of a huge rising sun disk, wider than the body and fanned with nine rays, a tilted gold orbit ring round its waist and a root-tip tail",
    "hero": "the sun disk: a glowing disc with rays behind the whole body, wider than it",
    "face": {"on": "body", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": 0.0, "mouth": "wide", "look": (0.0, 0.12)},
    "palette": {"BodyDark": "5DBB3A", "Accessory": "FFC83D"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0, 0, 1.3), (1.15, 1.1, 1.1), segments=16, name="body"),
        spike("Body", (0, 0.7, 0.6), (0, 1.3, 0.05), 0.28, segments=6, name="root"),
        sph("BodyDark", (0.5, -0.4, 0.2), (0.36, 0.46, 0.2), segments=8, mirror=True, name="foot"),
        cyl("Accessory", _SUN_C, (_SUN_R, _SUN_R, 0.07), rot=(90, 0, 0), segments=28, name="disk"),
        tor("Accessory", (0, 0, 1.3), (1.75, 1.75, 1.75), rot=(18, 0, 8), minor=0.035, segments=24, mseg=4, name="orbit"),
    ] + _SUN_RAYS + _RADISH_LEAVES,
}

_PANPIPE_REEDS = []
for _b, _l in ((-66, 0.9), (-44, 1.05), (-22, 1.2), (0, 1.3), (22, 1.2), (44, 1.05), (66, 0.9)):
    _d = (math.sin(math.radians(_b)), 0.0, math.cos(math.radians(_b)))
    _hub = (0.0, 1.25, 2.1)
    _PANPIPE_REEDS.append(rod("Accessory", _add(_hub, _mul(_d, 0.3)), _add(_hub, _mul(_d, _l)), 0.1, segments=6, name="reed"))

RECIPES["Panpipe"] = {
    "tier": "Secret", "world": 1, "biome": "Meadow", "batch": 5, "status": "recipe", "height": 3.40,
    "silhouette": "a round black goat on two stubby hooves with curling bone horns, a little beard and a fan of seven reed pipes spread behind its head like a peacock",
    "hero": "the reed-pipe fan: seven glowing pipes in a half circle behind the head",
    "face": {"on": "body", "eye_scale": 1.05, "eye_gap": 1.1, "eye_tilt": 14.0, "mouth": "o", "lid": 0.38, "mouth_scale": 1.1},
    "palette": {"BodyDark": "E9DDBA", "Accessory": "4FD8FF", "Mouth": "7A1F3D"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0, 0, 1.75), (1.2, 1.1, 1.2), segments=16, name="body"),
        rod("Body", (0.55, 0.0, 0.8), (0.6, 0.0, 0.2), 0.28, 0.24, segments=7, mirror=True, name="leg"),
        sph("BodyDark", (0.6, -0.12, 0.17), (0.36, 0.46, 0.17), segments=8, mirror=True, name="hoof"),
        rod("BodyDark", (0.5, -0.1, 2.8), (0.95, -0.12, 3.0), 0.2, 0.15, segments=6, mirror=True, name="horn"),
        rod("BodyDark", (0.95, -0.12, 3.0), (1.2, -0.12, 3.25), 0.15, 0.1, segments=6, mirror=True, name="horn"),
        rod("BodyDark", (1.2, -0.12, 3.25), (1.05, -0.1, 3.4), 0.1, 0.03, segments=6, mirror=True, name="horn"),
        sph("Body", (1.2, -0.1, 2.2), (0.5, 0.15, 0.22), rot=(0, 0, 15), segments=8, mirror=True, name="ear"),
        spike("BodyDark", (0, -1.0, 1.35), (0, -1.0, 0.85), 0.22, segments=6, name="beard"),
        cyl("BodyDark", (0, 1.25, 2.1), (0.3, 0.3, 0.1), rot=(90, 0, 0), segments=12, name="hub"),
        tor("Accessory", (0, 0, 0.05), (2.0, 2.0, 2.0), minor=0.035, segments=20, mseg=4, name="glowring"),
    ] + _PANPIPE_REEDS,
}


# ---------------------------------------------------------------------------------------- stubs (TODO)
def _stub(sid, tier, world, biome, batch, height, silhouette, hero, note="TODO: the recipe steps, next week (the Frostbyte nights)."):
    RECIPES[sid] = {"tier": tier, "world": world, "biome": biome, "batch": batch, "status": "TODO", "height": height,
                    "silhouette": silhouette, "hero": hero, "face": None, "palette": {}, "steps": [], "todo": note}


_EVENT = "TODO (only if Ethan wants a change): already built by tools/blender/event_species.py; revisit its face (eyes, mouth) before the body."
_stub("Wisplet", "Rare", 1, "Forest", 0, 2.11, "a teardrop flame leaning a little, a lantern ring round its base, a shy close-set face low on the body",
      "the flame body and its glowing lantern gem", _EVENT)
_stub("Spookum", "Epic", 1, "Cave", 0, 3.17, "a round ghost with eight scalloped hem lobes, floating a hand above the ground, triangle eyes and a zig-zag pumpkin grin",
      "the scalloped hem and the pumpkin grin", _EVENT)
_stub("Nebulyn", "Legendary", 1, "Meadow", 0, 3.52, "a puffy four-lobe cloud with two big bright eyes and a trailing tail of five gold stars curving up and back",
      "the star tail", _EVENT)
# ==== FROSTBYTE BEGIN (the 16 World 2 recipes) ====
# World 2 (Frostbyte): 16 full recipes, batch 6..9 = F1..F4 (docs/vault/06-art-pipelines/Silhouette-Pass.md). Rounded snow and ice, knitted
# accessories, pale blues and whites with one warm accent per alien; coolness grows with the tier. The white puffs of Kettlepuff's steam and
# Capybubble's bubbles use the EyeWhite slot (glossy white); no other slot in these recipes is white.


def _euler_xyz(R):
    """Blender's XYZ Euler angles in degrees for a 3x3 rotation matrix (R = Rz Ry Rx, the order euler_matrix builds)."""
    b = -math.asin(max(-1.0, min(1.0, R[2][0])))
    if abs(math.cos(b)) < 1e-6:
        return (math.degrees(math.atan2(-R[1][2], R[1][1])), math.degrees(b), 0.0)
    return (math.degrees(math.atan2(R[2][1], R[2][2])), math.degrees(b), math.degrees(math.atan2(R[1][0], R[0][0])))


def _ribbon(slot, pts, widths, thick, name):
    """A flat band along a polyline, one thin box per segment, so it reads as a knitted strip and not a string of beads. The broad face
    stands upright (the width is in z, `widths` are half-heights) and the band is `thick` across the path in the ground plane."""
    out = []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        d = _sub(b, a)
        f = _unit(d)
        y = _unit(_sub((0.0, 0.0, 1.0), _mul(f, f[2])))
        x = _cross(y, f)
        R = ((x[0], y[0], f[0]), (x[1], y[1], f[1]), (x[2], y[2], f[2]))
        out.append(cube(slot, _mul(_add(a, b), 0.5), (thick, widths[i], _len(d) * 0.54), rot=_euler_xyz(R), name=name))
    return out


def _blade_chain(slot, base, tops, wobble, width, thick, name):
    """A zigzag of flat cones rising from `base` to `tops` (z of the tip), swinging +-wobble in x: an aurora ribbon seen from the front."""
    pts = [base]
    n = 3
    for i in range(1, n + 1):
        t = i / float(n)
        pts.append((base[0] + (wobble if i % 2 else -wobble) * (1.0 if i < n else 0.3), base[1], base[2] + (tops - base[2]) * t))
    out = []
    for i in range(n):
        a, b = pts[i], pts[i + 1]
        d = _sub(b, a)
        last = i == n - 1
        out.append(cone(slot, _mul(_add(a, b), 0.5), (width * (1.0 - 0.18 * i), thick, _len(d) / 2.0 * 1.05), rot=aim(d), tip=0.0 if last else 0.72, segments=4, flat=True, name=name))
    return out


# ---------------------------------------------------------------------------------------- F1: round commons (batch 6)
_STREAMER = []  # the scarf's free end: a band that leaves the knot to the side and back and ripples as it goes
for _i in range(10):
    _u = _i / 9.0
    _run, _sway = 2.2 * _u, 0.25 * math.sin(2.0 * math.pi * _u)
    _STREAMER.append((-0.4 - 0.78 * _run - 0.62 * _sway, 0.68 + 0.62 * _run - 0.78 * _sway, 0.8 + 0.5 * _u + 0.2 * math.sin(2.0 * math.pi * _u * 1.3)))

RECIPES["Flufflet"] = {
    "tier": "Common", "world": 2, "biome": "Snowfield", "batch": 6, "status": "recipe", "height": 2.64,
    "silhouette": "a tall snowball with a knitted coral scarf round its neck, one long streamer whipping out behind and to the side, and two blue mitten-shaped ears",
    "hero": "the knitted scarf: a ring round the neck and one streamer flicking out with tassels",
    "face": {"on": "body", "eye_scale": 1.2, "eye_gap": 0.92, "eye_tilt": -8.0, "mouth": "o", "lid": 0.25, "look": (0.06, 0.05)},
    "palette": {"BodyDark": "9DB7D5", "Accessory": "FF7A59"},
    "steps": [
        sph("Body", (0, 0, 1.2), (0.9, 0.86, 1.1), segments=16, name="body"),
        sph("BodyDark", (0.42, -0.3, 0.14), (0.32, 0.44, 0.16), segments=10, mirror=True, name="foot"),
        tor("Accessory", (0, 0, 0.72), (0.86, 0.82, 0.86), minor=0.23, segments=16, mseg=5, name="scarf"),
        sph("Accessory", (-0.4, 0.66, 0.78), (0.3, 0.28, 0.28), segments=8, name="knot"),
        sph("BodyDark", (0.58, 0.05, 2.18), (0.25, 0.15, 0.4), rot=(0, 0, -20), segments=10, mirror=True, name="mitten"),
        sph("BodyDark", (0.86, 0.05, 2.08), (0.12, 0.1, 0.18), rot=(0, 0, -50), segments=8, mirror=True, name="thumb"),
    ] + _ribbon("Accessory", _STREAMER, [0.3, 0.3, 0.29, 0.28, 0.27, 0.26, 0.25, 0.24, 0.23], 0.06, "streamer")
      + [cone("Accessory", (_STREAMER[-1][0] - 0.1 * k, _STREAMER[-1][1] - 0.08 * k, _STREAMER[-1][2] - 0.34), (0.05, 0.05, 0.2), rot=(180, 0, 0), segments=5, name="tassel") for k in (-1, 0, 1)],
}

RECIPES["Snowbun"] = {
    "tier": "Common", "world": 2, "biome": "Snowfield", "batch": 6, "status": "recipe", "height": 2.04,
    "silhouette": "a pear-shaped bunny sitting up with two long upright ears and a tail of three snowballs growing in a curl behind it, bigger than its head",
    "hero": "the tail that keeps growing: three snowballs in a rising curl",
    "face": {"on": "head", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": -6.0, "mouth": "smile", "lid": 0.2},
    "palette": {"BodyDark": "A9C3DD", "Accessory": "FF9EB5"},
    "steps": [
        sph("Body", (0, 0.15, 0.62), (0.88, 0.82, 0.62), segments=14, name="body"),
        sph("Body", (0, -0.4, 1.0), (0.56, 0.52, 0.5), segments=14, name="head"),
        sph("Body", (0.25, -0.3, 1.42), (0.13, 0.1, 0.62), rot=(0, 10, 0), segments=10, mirror=True, name="ear"),
        sph("Accessory", (0.25, -0.37, 1.4), (0.07, 0.05, 0.47), rot=(0, 10, 0), segments=8, mirror=True, name="innerear"),
        sph("BodyDark", (0.42, -0.5, 0.14), (0.28, 0.5, 0.14), segments=10, mirror=True, name="foot"),
        sph("Accessory", (0, -0.92, 1.05), (0.08, 0.06, 0.07), segments=8, name="nose"),
        sph("Body", (0, 0.95, 0.5), (0.5, 0.5, 0.5), segments=12, name="tail"),
        sph("Body", (0, 1.4, 1.0), (0.4, 0.4, 0.4), segments=12, name="tail"),
        sph("Body", (0, 1.65, 1.62), (0.33, 0.33, 0.33), segments=10, name="tail"),
    ],
}

RECIPES["Drippo"] = {
    "tier": "Common", "world": 2, "biome": "IceCave", "batch": 6, "status": "recipe", "height": 2.11,
    "silhouette": "a tall drop with a round belly and a long pointed top wearing a tiny knitted cap with a pompom, two stubby legs and a small droplet floating beside it",
    "hero": "the drip-drop body with its falling droplet",
    "face": {"on": "belly", "eye_scale": 1.25, "eye_gap": 0.85, "eye_tilt": -10.0, "mouth": "o", "lid": 0.25},
    "palette": {"BodyDark": "6FA9D6", "Accessory": "FF8E5B"},
    "steps": [
        sph("Body", (0, 0, 0.66), (0.8, 0.76, 0.58), segments=18, name="belly"),
        spike("Body", (0, 0, 0.9), (0, 0, 1.98), 0.7, segments=16, name="point"),
        cyl("BodyDark", (0.3, -0.1, 0.12), (0.2, 0.2, 0.12), segments=8, mirror=True, name="leg"),
        rod("Accessory", (0, 0, 1.7), (0.18, 0, 2.0), 0.23, 0.14, segments=10, name="cap"),
        rod("Accessory", (0.18, 0, 2.0), (0.44, 0, 1.9), 0.14, 0.07, segments=8, name="cap"),
        tor("Accessory", (0, 0, 1.7), (0.23, 0.23, 0.23), minor=0.38, segments=12, mseg=5, name="cuff"),
        sph("Accessory", (0.47, 0, 1.86), 0.1, segments=8, name="pompom"),
        sph("BodyDark", (1.25, -0.1, 0.9), 0.2, segments=10, name="droplet"),
        spike("BodyDark", (1.25, -0.1, 1.0), (1.25, -0.1, 1.45), 0.15, segments=10, name="droplettip"),
        sph("BodyDark", (-1.05, 0.2, 0.5), 0.12, segments=8, name="droplet"),
        spike("BodyDark", (-1.05, 0.2, 0.56), (-1.05, 0.2, 0.8), 0.09, segments=8, name="droplettip"),
    ],
}

RECIPES["Kettlepuff"] = {
    "tier": "Common", "world": 2, "biome": "GeyserField", "batch": 6, "status": "recipe", "height": 2.20,
    "silhouette": "a squat round kettle with a long upswept copper spout on one side, a looped handle on the other, a domed lid with a knob and a ring of six steam puffs floating above",
    "hero": "the spout and the steam ring",
    "face": {"on": "body", "eye_scale": 1.5, "eye_gap": 0.95, "eye_tilt": 0.0, "mouth": "o", "look": (0.0, 0.08)},
    "palette": {"BodyDark": "9F9A92", "Accessory": "E8793A"},
    "steps": [
        sph("Body", (0, 0, 0.62), (1.05, 1.0, 0.62), segments=20, name="body"),
        sph("BodyDark", (0, 0, 1.2), (0.6, 0.58, 0.2), segments=12, name="lid"),
        sph("BodyDark", (0, 0, 1.48), 0.13, segments=8, name="knob"),
        rod("Accessory", (0.8, 0, 0.62), (1.45, 0, 0.95), 0.24, 0.16, segments=8, name="spout"),
        rod("Accessory", (1.45, 0, 0.95), (1.85, 0, 1.45), 0.16, 0.11, segments=8, name="spout"),
        tor("Accessory", (-1.15, 0.1, 0.75), (0.5, 0.5, 0.5), rot=(90, 0, 0), minor=0.3, segments=14, mseg=5, name="handle"),
    ] + [sph("EyeWhite", (0.6 * math.cos(math.radians(a)), 0.6 * math.sin(math.radians(a)), 1.95), 0.2 + 0.05 * (i % 2), segments=8, name="steam")
         for i, a in enumerate(range(0, 360, 60))],
}

# ---------------------------------------------------------------------------------------- F2: limbs and props (batch 7)
RECIPES["Chipmole"] = {
    "tier": "Common", "world": 2, "biome": "IceCave", "batch": 7, "status": "recipe", "height": 1.98,
    "silhouette": "a squat mole with a pointed snout and both arms raised, each fist gripping a tall pickaxe with a double-ended ice head, ice chips scattered round its feet",
    "hero": "the ice-pick claws, raised like a cheer",
    "face": {"on": "body", "eye_scale": 0.85, "eye_gap": 0.95, "eye_tilt": 8.0, "mouth": "wide", "lid": 0.3},
    "palette": {"BodyDark": "3B4656", "Accessory": "9CD3F0", "Mouth": "E8685A"},
    "steps": [
        sph("Body", (0, 0.1, 0.85), (1.05, 0.95, 0.78), segments=16, name="body"),
        spike("BodyDark", (0, -0.8, 0.98), (0, -1.3, 0.94), 0.15, segments=8, name="snout"),
        sph("BodyDark", (0.55, -0.35, 0.13), (0.32, 0.42, 0.14), segments=10, mirror=True, name="foot"),
        rod("Body", (0.85, -0.05, 1.05), (1.12, -0.18, 1.3), 0.2, 0.17, segments=7, mirror=True, name="arm"),
        sph("Body", (1.14, -0.2, 1.36), 0.25, segments=10, mirror=True, name="fist"),
        rod("BodyDark", (1.14, -0.2, 0.9), (1.14, -0.2, 1.8), 0.14, segments=6, mirror=True, name="handle"),
        rod("Accessory", (1.14, -0.2, 1.8), (1.55, -0.2, 1.8), 0.2, 0.15, segments=6, mirror=True, flat=True, name="pick"),
        spike("Accessory", (1.55, -0.2, 1.8), (1.95, -0.2, 1.42), 0.15, segments=6, mirror=True, flat=True, name="pick"),
        rod("Accessory", (1.14, -0.2, 1.8), (0.78, -0.2, 1.8), 0.2, 0.15, segments=6, mirror=True, flat=True, name="pick"),
        spike("Accessory", (0.78, -0.2, 1.8), (0.5, -0.2, 1.45), 0.15, segments=6, mirror=True, flat=True, name="pick"),
        ico("Accessory", (0.95, -0.85, 0.12), 0.15, segments=1, flat=True, mirror=True, name="chip"),
        ico("Accessory", (0.4, -1.2, 0.1), 0.13, segments=1, flat=True, mirror=True, name="chip"),
        sph("BodyDark", (0, 1.0, 0.4), (0.2, 0.24, 0.18), segments=8, name="tail"),
    ],
}

RECIPES["Pengoo"] = {
    "tier": "Uncommon", "world": 2, "biome": "Snowfield", "batch": 7, "status": "recipe", "height": 1.98,
    "silhouette": "a plump penguin lying flat on its belly mid-slide, head up in front, flippers swept back, orange feet kicked up behind, a tiny box backpack on its back",
    "hero": "the tiny backpack and the belly-slide pose",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.1, "eye_tilt": -6.0, "mouth": "wide", "lid": 0.1, "eye_height": 0.62},
    "palette": {"BodyDark": "1C293C", "Accessory": "FF8A3D"},
    "steps": [
        sph("Body", (0, 0.35, 0.68), (0.8, 1.35, 0.68), segments=16, name="body"),
        sph("Body", (0, -1.0, 0.95), (0.62, 0.6, 0.58), segments=16, name="head"),
        sph("Belly", (0, -0.45, 0.4), (0.66, 0.9, 0.4), segments=14, name="belly"),
        sph("BodyDark", (1.0, 0.35, 0.72), (0.1, 0.75, 0.28), rot=(15, 0, -17), segments=10, mirror=True, name="flipper"),
        cone("Accessory", (0.5, 1.75, 1.2), (0.32, 0.09, 0.45), rot=(160, 0, 10), segments=5, mirror=True, name="foot"),
        spike("BodyDark", (0, 1.55, 0.6), (0, 2.15, 0.85), 0.22, segments=6, name="tail"),
        cube("Accessory", (0, 0.6, 1.55), (0.4, 0.3, 0.34), name="backpack"),
        cube("BodyDark", (0, 0.6, 1.9), (0.42, 0.32, 0.05), name="flap"),
    ],
}

RECIPES["Flapsicle"] = {
    "tier": "Uncommon", "world": 2, "biome": "IceCave", "batch": 7, "status": "recipe", "height": 1.76,
    "silhouette": "an upside-down bat hanging by two tiny pink toes with nothing above them, wings folded round it as four hanging icicle blades, big pink ears, the head at the bottom",
    "hero": "the icicle wings and the hanging pose",
    "face": {"on": "head", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": -8.0, "mouth": "smile", "lid": 0.35},
    "palette": {"BodyDark": "F28DA6", "Accessory": "9FE3FF"},
    "steps": [
        sph("Body", (0, -0.1, 0.58), (0.62, 0.58, 0.58), segments=16, name="head"),
        sph("Body", (0, 0.1, 1.2), (0.7, 0.62, 0.52), segments=14, name="body"),
        spike("BodyDark", (0.4, -0.05, 0.9), (1.05, 0.0, 1.38), 0.25, segments=6, mirror=True, name="ear"),
        spike("Accessory", (0.62, 0.1, 1.55), (1.15, 0.0, 0.15), 0.32, segments=5, flat=True, mirror=True, name="blade"),
        spike("Accessory", (0.4, 0.45, 1.5), (0.7, 0.5, 0.35), 0.26, segments=5, flat=True, mirror=True, name="blade"),
        sph("BodyDark", (0.14, 0.1, 1.68), (0.1, 0.12, 0.1), segments=8, mirror=True, name="toe"),
    ],
}

RECIPES["Toastoad"] = {
    "tier": "Uncommon", "world": 2, "biome": "GeyserField", "batch": 7, "status": "recipe", "height": 1.98,
    "silhouette": "a very wide squat toad with two eye bumps under heavy lids, three wrinkle ridges across its back, bent hind legs and a lumpy cluster of blue pebbles on its back",
    "hero": "the pebble backpack",
    "face": {"on": "head", "eye_scale": 1.4, "eye_gap": 1.2, "eye_tilt": -4.0, "mouth": "wide", "lid": 0.4},
    "palette": {"BodyDark": "974926", "Accessory": "9FB3C8"},
    "steps": [
        sph("Body", (0, 0.35, 0.72), (1.2, 1.0, 0.7), segments=12, name="body"),
        sph("Body", (0, -0.55, 0.82), (1.0, 0.7, 0.6), segments=12, name="head"),
        sph("Body", (0.5, -0.7, 1.3), 0.3, segments=8, mirror=True, name="eyebump"),
        sph("Body", (1.0, 0.75, 0.52), (0.4, 0.65, 0.45), segments=8, mirror=True, name="thigh"),
        sph("BodyDark", (1.05, 0.05, 0.1), (0.32, 0.5, 0.1), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (0.7, -1.05, 0.1), (0.28, 0.4, 0.1), segments=8, mirror=True, name="foot"),
        ico("Accessory", (0, 0.9, 1.58), 0.4, segments=1, flat=True, name="pebble"),
        ico("Accessory", (0.5, 0.85, 1.35), 0.3, segments=1, flat=True, mirror=True, name="pebble"),
        ico("Accessory", (0.25, 1.2, 1.3), 0.28, segments=1, flat=True, mirror=True, name="pebble"),
        ico("Accessory", (0, 0.45, 1.5), 0.27, segments=1, flat=True, name="pebble"),
    ],
}
for _dy in (0.0, 0.42, 0.8):
    _f = math.sqrt(1.0 - (_dy / 1.0) ** 2)
    RECIPES["Toastoad"]["steps"].append(tor("BodyDark", (0, 0.35 + _dy, 0.72), (1.2 * _f * 1.02, 0.7 * _f * 1.01, 1.2 * _f * 1.02), rot=(90, 0, 0),
                                            minor=0.07, segments=12, mseg=4, name="ridge"))

# ---------------------------------------------------------------------------------------- F3: rims, fans and shells (batch 8)
RECIPES["Emberchin"] = {
    "tier": "Uncommon", "world": 2, "biome": "GeyserField", "batch": 8, "status": "recipe", "height": 2.24,
    "silhouette": "a round urchin mid-hop wearing a cocked sun-hat: a small crown and a wide brim of twelve horizontal quills ending in glowing embers, one leg lifted",
    "hero": "the ember-tipped quill brim",
    "face": {"on": "body", "eye_scale": 1.15, "eye_gap": 1.0, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.25, "eye_height": 0.5},
    "palette": {"BodyDark": "A66730", "Accessory": "FFD23F"}, "glow": {"Accessory": 2.5},
    "steps": [
        sph("Body", (0, 0, 1.0), (0.95, 0.9, 0.78), segments=16, name="body"),
        sph("BodyDark", (0, 0, 1.62), (0.6, 0.58, 0.45), half="top", segments=12, name="crown"),
        ico("Accessory", (0, 0, 2.1), 0.13, segments=1, flat=True, name="crownember"),
        cyl("BodyDark", (-0.45, -0.1, 0.2), (0.2, 0.2, 0.2), segments=8, name="leg"),
        rod("BodyDark", (0.5, -0.05, 0.42), (0.7, -0.5, 0.32), 0.2, 0.16, segments=8, name="leg"),
        sph("BodyDark", (0.72, -0.58, 0.26), (0.26, 0.34, 0.12), segments=8, name="foot"),
    ],
}
for _k in range(12):
    _a = math.radians(15.0 + 30.0 * _k)
    _c, _s = math.cos(_a), math.sin(_a)
    _tilt = 0.2  # the brim is cocked: one side lower
    RECIPES["Emberchin"]["steps"].append(rod("BodyDark", (0.5 * _c, 0.5 * _s, 1.62 + _tilt * 0.5 * _c), (1.4 * _c, 1.4 * _s, 1.52 + _tilt * 1.4 * _c),
                                             0.22, 0.07, segments=5, flat=True, name="quill"))
    RECIPES["Emberchin"]["steps"].append(ico("Accessory", (1.5 * _c, 1.5 * _s, 1.5 + _tilt * 1.5 * _c), 0.19, segments=1, flat=True, name="ember"))

_ANTLER_FAN = []
for _ang, _ln in ((-10, 0.9), (12, 0.96), (34, 0.9), (56, 0.76), (76, 0.58)):
    _b = (0.25, -1.05, 2.66)
    _d = (math.sin(math.radians(_ang)), 0.0, math.cos(math.radians(_ang)))
    _ANTLER_FAN.append(spike("BodyDark", _b, _add(_b, _mul(_d, _ln)), 0.18, segments=5, flat=True, mirror=True, name="antler"))

RECIPES["Reindazzle"] = {
    "tier": "Rare", "world": 2, "biome": "Snowfield", "batch": 8, "status": "recipe", "height": 3.65,
    "silhouette": "a slender reindeer prancing, body tilted up, front legs folded in the air, back legs trailing, a long neck, a tall fan of ten icicle spikes for antlers and a big round glowing nose",
    "hero": "the icicle antlers and the glowing nose",
    "face": {"on": "head", "eye_scale": 1.0, "eye_gap": 1.0, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.3, "mouth_drop": 0.32},
    "palette": {"BodyDark": "8795AD", "Accessory": "FF6B4A"}, "glow": {"Accessory": 2.0}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0.4, 1.4), (0.72, 1.15, 0.62), rot=(-20, 0, 0), segments=14, name="bodytilt"),
        rod("Body", (0, -0.7, 1.7), (0, -1.05, 2.1), 0.34, 0.24, segments=7, name="neck"),
        sph("Body", (0, -1.2, 2.36), (0.5, 0.56, 0.46), segments=14, name="head"),
        sph("Accessory", (0, -1.8, 2.36), 0.2, segments=10, name="nose"),
        sph("Body", (0.55, -1.05, 2.51), (0.3, 0.1, 0.14), rot=(0, 0, 20), segments=8, mirror=True, name="ear"),
        rod("Body", (0.32, 1.4, 1.25), (0.4, 1.78, 0.14), 0.18, 0.11, segments=6, mirror=True, name="hindleg"),
        sph("BodyDark", (0.4, 1.8, 0.09), (0.13, 0.17, 0.1), segments=6, mirror=True, name="hoof"),
        rod("Body", (0.34, -0.5, 1.55), (0.45, -1.0, 1.3), 0.17, 0.12, segments=6, mirror=True, name="foreleg"),
        rod("Body", (0.45, -1.0, 1.3), (0.5, -1.1, 0.95), 0.12, 0.1, segments=6, mirror=True, name="foreleg"),
        sph("BodyDark", (0.5, -1.12, 0.9), (0.12, 0.16, 0.1), segments=6, mirror=True, name="hoof"),
        sph("BodyDark", (0, 1.75, 1.3), 0.2, segments=8, name="tail"),
    ] + _ANTLER_FAN,
}

RECIPES["Shellberg"] = {
    "tier": "Rare", "world": 2, "biome": "IceCave", "batch": 8, "status": "recipe", "height": 2.76,
    "silhouette": "a tortoise under a huge jagged iceberg shell crowned with six glowing crystal peaks, its head peeking out of the front in a little knitted cap with a pompom",
    "hero": "the iceberg shell with its glowing crystal peaks and vein",
    "face": {"on": "head", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": -10.0, "mouth": "smile", "lid": 0.35, "eye_height": 0.5},
    "palette": {"BodyDark": "E8785A", "Accessory": "CFF1FF"}, "glow": {"Accessory": 1.2}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0.2, 0.55), (1.1, 1.25, 0.55), segments=14, name="body"),
        ico("Body", (0, 0.35, 0.98), (1.4, 1.5, 0.88), rot=(4, 0, 6), segments=2, flat=True, name="shell"),
        sph("Body", (0, -1.45, 0.62), (0.55, 0.55, 0.5), segments=14, name="head"),
        cyl("Body", (0.8, -0.7, 0.25), (0.3, 0.3, 0.25), segments=8, mirror=True, name="leg"),
        cyl("Body", (0.85, 1.0, 0.25), (0.3, 0.3, 0.25), segments=8, mirror=True, name="leg"),
        sph("BodyDark", (0, -1.45, 0.98), (0.56, 0.54, 0.44), half="top", segments=12, name="cap"),
        tor("BodyDark", (0, -1.45, 0.99), (0.54, 0.52, 0.54), minor=0.26, segments=14, mseg=4, name="cuff"),
        sph("BodyDark", (0, -1.45, 1.46), 0.13, segments=8, name="pompom"),
        spike("Accessory", (0, 0.45, 1.55), (0.05, 0.5, 2.76), 0.44, segments=5, flat=True, name="peak"),
        spike("Accessory", (0.62, 0.1, 1.5), (0.95, 0.05, 2.45), 0.32, segments=5, flat=True, mirror=True, name="peak"),
        spike("Accessory", (0.65, 0.95, 1.4), (0.98, 1.15, 2.3), 0.3, segments=5, flat=True, mirror=True, name="peak"),
        spike("Accessory", (0, 1.15, 1.35), (0, 1.4, 2.2), 0.28, segments=5, flat=True, name="peak"),
        spike("Accessory", (0.95, -0.4, 1.2), (1.3, -0.45, 1.8), 0.22, segments=5, flat=True, mirror=True, name="peak"),
        tor("Accessory", (0, 0.35, 0.98), (1.41, 1.52, 1.3), minor=0.05, segments=16, mseg=4, name="vein"),
    ],
}

RECIPES["Capybubble"] = {
    "tier": "Rare", "world": 2, "biome": "GeyserField", "batch": 8, "status": "recipe", "height": 2.98,
    "silhouette": "a long barrel-shaped capybara loafing low with a tangerine on its head and a string of growing bubbles rising up and to the side from its snoring mouth",
    "hero": "the tangerine hat and the snore bubbles",
    "face": {"on": "head", "eye_scale": 1.0, "eye_gap": 1.2, "eye_tilt": -6.0, "mouth": "o", "lid": 0.45},
    "palette": {"BodyDark": "927F68", "Accessory": "FF8A1F"}, "glow": {"Accessory": 1.0}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0.45, 0.88), (1.0, 1.35, 0.88), segments=14, name="barrel"),
        sph("Body", (0, -1.2, 0.95), (0.82, 0.8, 0.7), segments=14, name="head"),
        sph("BodyDark", (0.55, -0.9, 1.55), (0.18, 0.1, 0.14), segments=8, mirror=True, name="ear"),
        sph("BodyDark", (0.6, -0.5, 0.1), (0.28, 0.4, 0.1), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (0.65, 1.3, 0.1), (0.28, 0.4, 0.1), segments=8, mirror=True, name="foot"),
        sph("Accessory", (0, -1.1, 1.95), 0.42, segments=12, name="tangerine"),
        spike("BodyDark", (0, -1.1, 2.3), (0, -1.1, 2.5), 0.07, segments=6, name="stem"),
        sph("BodyDark", (0.22, -1.1, 2.42), (0.2, 0.08, 0.1), rot=(0, 0, 20), segments=8, name="leaf"),
        sph("EyeWhite", (0.2, -2.15, 0.7), 0.1, segments=8, name="bubble"),
        sph("EyeWhite", (0.5, -2.2, 1.1), 0.14, segments=8, name="bubble"),
        sph("EyeWhite", (0.85, -2.1, 1.6), 0.19, segments=10, name="bubble"),
        sph("EyeWhite", (1.15, -1.95, 2.15), 0.25, segments=10, name="bubble"),
        sph("EyeWhite", (1.2, -1.8, 2.68), 0.3, segments=12, name="bubble"),
    ],
}

# ---------------------------------------------------------------------------------------- F4: the top four (batch 9)
_AURORA = []
for _x, _top, _wob in ((-0.42, 3.4, 0.12), (-0.21, 3.66, -0.12), (0.0, 3.82, 0.12), (0.21, 3.62, -0.12), (0.42, 3.36, 0.12)):
    _AURORA += _blade_chain("Accessory", (_x, -0.2, 2.85), _top, _wob, 0.16, 0.04, "aurora")

RECIPES["Shimmerlynx"] = {
    "tier": "Epic", "world": 2, "biome": "IceCave", "batch": 9, "status": "recipe", "height": 3.82,
    "silhouette": "a sleek lynx sitting bolt upright on long front legs, tall tufted ears, a pink cheek ruff, and five waving aurora ribbons of different heights rising from between its ears",
    "hero": "the aurora crest: five glowing ribbons of glass",
    "face": {"on": "head", "eye_scale": 1.15, "eye_gap": 1.1, "eye_tilt": 14.0, "mouth": "smile", "lid": 0.3, "mouth_scale": 0.85},
    "palette": {"BodyDark": "827E9C", "Accessory": "5CF0D0"}, "glow": {"Accessory": 1.5},
    "steps": [
        sph("Body", (0, 0.55, 0.75), (0.85, 0.95, 0.75), segments=14, name="haunch"),
        sph("Body", (0, 0.0, 1.45), (0.62, 0.6, 0.95), segments=14, name="torso"),
        sph("Body", (0, -0.2, 2.35), (0.78, 0.7, 0.6), segments=16, name="head"),
        tor("Trim", (0, -0.1, 1.85), (0.82, 0.76, 0.82), minor=0.3, segments=14, mseg=5, name="ruff"),
        spike("Trim", (0.55, -0.3, 2.2), (1.15, -0.25, 1.95), 0.18, segments=6, mirror=True, name="cheek"),
        spike("Trim", (0.5, -0.3, 2.1), (1.0, -0.3, 1.6), 0.16, segments=6, mirror=True, name="cheek"),
        rod("Body", (0.3, -0.35, 1.35), (0.32, -0.62, 0.14), 0.17, 0.13, segments=6, mirror=True, name="foreleg"),
        sph("BodyDark", (0.32, -0.7, 0.1), (0.2, 0.3, 0.1), segments=8, mirror=True, name="paw"),
        spike("Body", (0.45, -0.1, 2.7), (0.58, -0.05, 3.3), 0.27, segments=6, mirror=True, name="ear"),
        spike("BodyDark", (0.58, -0.05, 3.2), (0.62, -0.02, 3.6), 0.1, segments=5, mirror=True, name="eartuft"),
        sph("BodyDark", (0, 1.5, 0.4), (0.2, 0.26, 0.2), segments=8, name="tail"),
    ] + _AURORA,
}

_RUFF = []
for _k in range(5):
    _ph = math.radians(90.0 + 27.5 * _k)
    _c, _s = math.cos(_ph), math.sin(_ph)
    _RUFF.append(spike("Accessory", (0.72 * _c, 0.05 + 0.72 * _s, 1.75), (1.5 * _c, 0.05 + 1.5 * _s, 2.55), 0.22, segments=5, flat=True, mirror=(_k > 0), name="quill"))

RECIPES["Frostfang"] = {
    "tier": "Epic", "world": 2, "biome": "Snowfield", "batch": 9, "status": "recipe", "height": 3.37,
    "silhouette": "a stocky sabre-tooth cub on all fours with an oversized head, two long icicle fangs hanging far below its open mouth and a spiked collar of nine ice quills round its neck",
    "hero": "the icicle fangs",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.1, "eye_tilt": 12.0, "mouth": "zigzag", "lid": 0.3, "mouth_scale": 1.2},
    "palette": {"BodyDark": "487797", "Accessory": "E8F7FF", "Mouth": "C94F3D"},
    "steps": [
        sph("Body", (0, 0.45, 1.05), (1.05, 1.0, 0.9), segments=14, name="body"),
        sph("Body", (0, -0.45, 2.3), (1.0, 0.9, 0.85), segments=16, name="head"),
        tor("Trim", (0, -0.05, 1.7), (0.9, 0.85, 0.9), minor=0.2, segments=14, mseg=5, name="collar"),
        sph("Body", (0.7, -0.3, 3.05), (0.3, 0.2, 0.3), segments=8, mirror=True, name="ear"),
        sph("BodyDark", (0.6, -0.9, 0.2), (0.3, 0.42, 0.2), segments=8, mirror=True, name="paw"),
        sph("BodyDark", (0.75, 1.2, 0.2), (0.32, 0.45, 0.2), segments=8, mirror=True, name="foot"),
        sph("Body", (0, 1.5, 0.8), (0.3, 0.3, 0.3), segments=8, name="tail"),
        spike("Accessory", (0.38, -1.3, 2.2), (0.4, -1.34, 1.05), 0.17, segments=6, mirror=True, name="fang"),
            ] + _RUFF,
}

RECIPES["Skaddle"] = {
    "tier": "Legendary", "world": 2, "biome": "Snowfield", "batch": 9, "status": "recipe", "height": 3.98,
    "silhouette": "an upright round snow owl on two tiny skis, frosty ice tufts on its head under a floating gold halo, and long wings held out and down like a pair of ski poles with baskets",
    "hero": "the tiny skis and the frosty crest",
    "face": {"on": "body", "eye_scale": 1.5, "eye_gap": 0.9, "eye_tilt": 0.0, "mouth": "o", "look": (0.0, 0.06)},
    "palette": {"BodyDark": "A9C5E0", "Accessory": "8FD8FF"},
    "steps": [
        sph("Body", (0, 0, 1.95), (1.2, 1.1, 1.25), segments=18, name="body"),
        rod("BodyDark", (0.4, -0.1, 0.95), (0.42, -0.1, 0.4), 0.14, segments=6, mirror=True, name="leg"),
        cube("Accessory", (0.42, -0.1, 0.24), (0.28, 1.15, 0.05), rot=(-9, 0, 0), mirror=True, name="ski"),
        cube("Trim", (0.42, -0.1, 0.37), (0.2, 0.2, 0.07), mirror=True, name="binding"),
        spike("Accessory", (0.55, -0.1, 3.0), (0.95, -0.1, 3.75), 0.3, segments=6, flat=True, mirror=True, name="tuft"),
        spike("Accessory", (0, -0.1, 3.1), (0, -0.1, 3.55), 0.2, segments=6, flat=True, name="crest"),
        tor("Trim", (0, 0, 3.88), (0.78, 0.78, 0.78), minor=0.13, segments=16, mseg=5, name="halo"),
    ],
}


def _wing_pole(shoulder, tip):
    """One wing held out and down like a ski pole: the pole, a flat feathered vane over its upper part and a basket near the tip."""
    d = _sub(tip, shoulder)

    def along(u):
        return _add(shoulder, _mul(d, u))
    return [rod("Accessory", shoulder, tip, 0.08, 0.05, segments=6, mirror=True, name="pole"),
            sph("BodyDark", along(0.3), (0.26, 0.07, 0.78), rot=aim(d), segments=10, mirror=True, name="wing"),
            tor("Accessory", along(0.86), (0.22, 0.22, 0.22), minor=0.22, segments=12, mseg=4, mirror=True, name="basket")]


RECIPES["Skaddle"]["steps"] += _wing_pole((1.05, 0.05, 2.3), (2.05, 0.1, 0.35))

_STARS = []
for _phi in (30, 120, 210, 300):
    _pr = math.radians(_phi)
    _c = (0.0, 0.3, 2.3)
    _sp = (_c[0] + 2.1 * math.cos(_pr), _c[1] + 2.1 * math.sin(_pr) * math.cos(math.radians(25)), _c[2] + 2.1 * math.sin(_pr) * math.sin(math.radians(25)))
    _STARS.append(cone("Accessory", (_sp[0], _sp[1], _sp[2] + 0.18), (0.28, 0.28, 0.18), rot=(0, 0, 45), segments=4, flat=True, name="star"))
    _STARS.append(cone("Accessory", (_sp[0], _sp[1], _sp[2] - 0.18), (0.28, 0.28, 0.18), rot=(180, 0, 45), segments=4, flat=True, name="star"))
_MOON = []
for _i, (_th, _rr) in enumerate(((95, 0.07), (123, 0.13), (151, 0.18), (180, 0.2), (209, 0.18), (237, 0.13), (265, 0.07))):
    _mx = 0.12 + 0.32 * math.cos(math.radians(_th))
    _mz = 3.66 + 0.32 * math.sin(math.radians(_th))
    _my = -0.3 - 0.92 * math.sqrt(max(0.05, 1.0 - _mx ** 2 - ((_mz - 3.15) / 0.9) ** 2)) - 0.03  # on the head's surface
    _MOON.append(sph("Accessory", (_mx, _my, _mz), _rr, segments=8, name="moon"))

RECIPES["Fenripup"] = {
    "tier": "Cosmic", "world": 2, "biome": "Snowfield", "batch": 9, "status": "recipe", "height": 4.05,
    "silhouette": "a big floppy-eared puppy sitting with a huge head, a thick tail curling up behind it, a glowing crescent moon on its forehead and four star shapes orbiting round it",
    "hero": "the forehead moon",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.0, "eye_tilt": -6.0, "mouth": "smile", "lid": 0.25, "eye_height": 0.56},
    "palette": {"BodyDark": "261E46", "Accessory": "FFC83D"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0, 0.5, 0.95), (1.15, 1.2, 0.95), segments=14, name="haunch"),
        sph("Body", (0, -0.05, 1.7), (0.95, 0.9, 1.1), segments=14, name="torso"),
        sph("Body", (0, -0.3, 3.15), (1.0, 0.92, 0.9), segments=18, name="head"),
        rod("Body", (0.45, -0.55, 1.5), (0.48, -0.9, 0.12), 0.25, 0.2, segments=7, mirror=True, name="foreleg"),
        sph("BodyDark", (0.48, -1.0, 0.12), (0.3, 0.4, 0.14), segments=8, mirror=True, name="paw"),
        sph("BodyDark", (0.9, -0.4, 0.14), (0.35, 0.55, 0.15), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (1.05, -0.2, 2.8), (0.28, 0.16, 0.7), rot=(0, -10, 0), segments=8, mirror=True, name="ear"),
        sph("Body", (0, 1.5, 0.6), 0.45, segments=8, name="tail"),
        sph("Body", (0, 1.95, 0.95), 0.4, segments=8, name="tail"),
        sph("Body", (0, 2.1, 1.5), 0.36, segments=8, name="tail"),
        sph("Body", (0, 1.95, 2.0), 0.32, segments=8, name="tail"),
        sph("BodyDark", (0, 1.6, 2.25), 0.3, segments=8, name="tailtip"),
    ] + _MOON + _STARS,
}
# ==== FROSTBYTE END ====

# ==== HEROES BEGIN (prototypes, not shipped species: docs/vault/06-art-pipelines/Hero-Aliens.md; written 2026-10-15, round 2 the same day) ====
# Two hero aliens the owner asked for on 2026-10-15: a scarier, stronger Fenrir and a sky dragon. Both are `"prototype": True` recipes: they have
# no assets/models folder and no Species.luau row, `all`/`world2`/`batchN` skip them, and the tests do not hold them to the shipped files. They
# are built with `species_sculpt.py --method hybrid` on a scratch models folder (the exact commands are in Hero-Aliens.md) and carry the Trim slot.
# Round 2 (same day) reworked both after the first sheet: Fenrir a wedge-headed stalker, Skydrake a wedge-headed S-curve (Hero-Aliens.md "Round 2").


def _basis(d, thin):
    """Euler degrees whose local z runs along d and whose local x (the thin axis of a blade) is `thin` made perpendicular to d."""
    f = _unit(d)
    x = _unit(_sub(thin, _mul(f, sum(a * b for a, b in zip(thin, f)))))
    y = _cross(f, x)
    return _euler_xyz(((x[0], y[0], f[0]), (x[1], y[1], f[1]), (x[2], y[2], f[2])))


def _blade(slot, base, d, length, thin, wide, name, thin_axis=(1.0, 0.0, 0.0), mirror=False, segments=4):
    """A crisp wedge: a flattened pyramid standing on `base` and pointing along d, `thin` (half size) across thin_axis and `wide` across
    the other way. A fur break, a mane lock, an ear, a claw. Four sides is six triangles; the hybrid builder makes a crisp cone at least
    five-sided (crisp_detail 1.0), so eight triangles each, and a wedge thinner than 0.1 (half size) gets no bevel."""
    f = _unit(d)
    return cone(slot, _add(base, _mul(f, length / 2.0)), (thin, wide, length / 2.0), rot=_basis(f, thin_axis), segments=segments, flat=True,
                mirror=mirror, name=name)


def _fin(slot, base, d, length, wide, thick, name, wide_dir=(0.0, 0.0, 1.0), mirror=False, segments=4):
    """A swept fin: a _blade whose broad face is named by the direction it spans (`wide_dir`, made perpendicular to d) instead of by the thin axis:
    a fin standing on the back spans up, a plate laid on a neck spans round it."""
    f = _unit(d)
    w = _unit(_sub(wide_dir, _mul(f, sum(a * b for a, b in zip(wide_dir, f)))))
    return _blade(slot, base, d, length, thick, wide, name, thin_axis=_cross(f, w), mirror=mirror, segments=segments)


def _crescent(slot, centre, radius, tilt, r_max, name, a0=150.0, a1=390.0, n=6, r_tip=0.035, segments=6):
    """A crescent moon standing upright (it opens upward, the horns curl in) made of tapered rods: the arc runs from a0 to a1 degrees round
    `centre` in the XZ plane, then leans back by `tilt` degrees about x. The tube is r_max at the bottom of the arc and r_tip at the horns."""
    pts, rad = [], []
    for i in range(n + 1):
        th = math.radians(a0 + (a1 - a0) * i / n)
        x, zl = radius * math.cos(th), radius * math.sin(th)
        t = math.radians(tilt)
        pts.append(_add(centre, (x, zl * math.sin(t), zl * math.cos(t))))
        rad.append(r_tip + (r_max - r_tip) * math.sin(math.pi * i / n) ** 0.8)
    return [rod(slot, pts[i], pts[i + 1], rad[i], rad[i + 1], segments=segments, name=name) for i in range(n)]


def _chain(slot, pts, radii, name, segments=4, mirror=True):
    """A thin tapering tube through the points as one rod per span (a whisker, a tine): radius radii[i] at pts[i]."""
    return [rod(slot, pts[i], pts[i + 1], radii[i], radii[i + 1], segments=segments, mirror=mirror, name=name) for i in range(len(pts) - 1)]


# ---------------------------------------------------------------------------------------- Fenrir v2 (a wolf, not a puppy)
# Round 2. Facing -Y. A stalker: the chest sits low between long legs, the haunches are raised (hips above the withers), the head is carried
# low and forward and is a WEDGE (a narrow skull, a long muzzle that tapers to a nose far forward, a lower jaw hung beneath it), the hind legs are
# Z-shaped (thigh, knee forward, hock back, a thin cannon to a big paw). Core (fused): the barrel, neck, head, muzzle and jaw, the four legs and
# paws, the tail sweep. Crisp: the ears, the ruff (large plates laid back round the neck), a few big fins sweeping back along the spine and
# shoulders, cheek tufts, claws, fangs, the crescent, the shoulder links and the rune plate. The mouth and the fangs are placed against the build's
# own mouth (the hybrid cuts the mouth into the muzzle and drops the `zigzag` teeth): the numbers in the fang comment come from probing it.
_FV2_NECK = ((0.0, -1.4, 2.75), (0.0, -2.3, 2.55))
_FV2_HEAD = (0.0, -2.85, 2.5)
# the centre-line spheres of the barrel (y, z, y radius, z radius): _fv2_top(y) is the height of the back there
_FV2_SPINE = ((-0.95, 2.2, 1.1, 0.95), (0.35, 2.75, 0.85, 0.6), (1.1, 3.15, 0.8, 0.76))
_FV2 = []


def _fv2_top(y):
    best = 0.0
    for cy, cz, ry, rz in _FV2_SPINE:
        if abs(y - cy) < ry:
            best = max(best, cz + rz * math.sqrt(1.0 - ((y - cy) / ry) ** 2))
    return best


def _fv2_ruff():
    """Eight big plates laid back round the neck (an outward and backward sweep, each broad across the neck): a ruff that frames the face and
    streams over the shoulders, not a ring of spikes."""
    a0, a1 = _FV2_NECK
    axis = _unit(_sub(a1, a0))
    up = _unit(_sub((0.0, 0.0, 1.0), _mul(axis, axis[2])))
    out = []
    for phi, ln, wide in ((55, 1.8, 0.5), (90, 1.7, 0.48), (125, 1.5, 0.44)):
        ph = math.radians(phi)
        r = _add(_mul(up, math.cos(ph)), (math.sin(ph), 0.0, 0.0))
        c = _add(a0, _mul(_sub(a1, a0), 0.5))
        out.append(_blade("BodyDark", _add(c, _mul(r, 0.5)), _add(_mul(r, 0.7), _mul(axis, -0.75)), ln, 0.09, wide, "ruff", thin_axis=r, mirror=True))
    return out


_FV2 += _fv2_ruff()
# the back: five big fins sweeping back along the spine (a continuous ridge of breaks, not a row of spikes): y, length, half width
for _y, _ln, _w in ((-0.6, 1.6, 0.5), (0.0, 1.7, 0.52), (0.6, 1.6, 0.5), (1.2, 1.4, 0.46)):
    _FV2.append(_fin("BodyDark", (0.0, _y, _fv2_top(_y) - 0.25), (0.0, 0.82, 0.57), _ln, _w, 0.09, "ridge", wide_dir=(0.0, -0.57, 0.82)))
# the shoulder and haunch breaks: three pairs of long fins swept back and out along the flanks
for _b, _d, _ln in (((0.8, -0.9, 3.0), (0.5, 0.85, 0.25), 1.6), ((0.7, 0.85, 3.5), (0.5, 0.85, 0.15), 1.4)):
    _FV2.append(_fin("BodyDark", _b, _d, _ln, 0.36, 0.09, "break", wide_dir=(0.0, 0.0, 1.0), mirror=True))
# claws: three on each paw, pointing forward and down
for _dx in (-0.23, 0.0, 0.23):
    _FV2.append(_blade("Trim", (0.85 + _dx, -2.0, 0.22), (0.0, -0.8, -0.4), 0.5, 0.08, 0.08, "claw", mirror=True, segments=5))
    _FV2.append(_blade("Trim", (0.8 + _dx, 0.65, 0.22), (0.0, -0.8, -0.4), 0.5, 0.08, 0.08, "claw", mirror=True, segments=5))
# spurs: a dewclaw behind each wrist and a spur at each hock, silver, pointing back and down
_FV2.append(_blade("Trim", (0.88, -1.05, 0.85), (0.1, 0.75, -0.55), 0.55, 0.08, 0.1, "claw", mirror=True, segments=5))
_FV2.append(_blade("Trim", (0.84, 1.75, 1.0), (0.1, 0.9, -0.3), 0.6, 0.08, 0.1, "claw", mirror=True, segments=5))
# four fangs on the open mouth (placed against the mouth the sculpt cuts in the muzzle): two long upper canines hanging from the lip, two shorter
# lower ones standing in the jaw between them
_FV2.append(spike("EyeWhite", (0.3, -4.2, 2.15), (0.4, -4.35, 1.3), 0.12, segments=6, mirror=True, name="fang"))
_FV2.append(spike("EyeWhite", (0.15, -4.3, 1.78), (0.15, -4.38, 2.2), 0.09, segments=6, mirror=True, name="fang"))
# the crescent on the forehead, standing up between the ears
_FV2 += _crescent("Accessory", (0.0, -3.1, 3.72), 0.6, 20.0, 0.16, "moon", a0=140.0, a1=400.0, n=7)
# two chain links on one shoulder (interlocked: one flat to the flank, one turned a quarter) and a rune plate on the other
_FV2.append(tor("Trim", (1.3, -0.95, 2.95), (0.5, 0.5, 0.5), rot=aim((1.0, 0.1, 0.25)), minor=0.3, segments=6, mseg=4, name="link"))
_FV2.append(tor("Trim", (1.32, -0.95, 2.35), (0.48, 0.48, 0.48), rot=aim((0.3, 1.0, 0.1)), minor=0.3, segments=6, mseg=4, name="link"))
_FV2.append(cyl("Trim", (-1.3, -0.95, 2.8), (0.5, 0.5, 0.07), rot=aim((-1.0, 0.1, 0.25)), segments=6, name="plate"))
for _p0, _p1 in (((-1.38, -0.95, 3.18), (-1.4, -0.95, 2.4)), ((-1.38, -1.4, 2.5), (-1.4, -0.95, 2.82)), ((-1.38, -0.5, 2.5), (-1.4, -0.95, 2.82))):
    _FV2.append(rod("Accessory", _p0, _p1, 0.06, segments=4, name="rune"))

RECIPES["FenripupV2"] = {
    "tier": "Cosmic", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 5.1,
    "silhouette": "a low long wolf stalking on four long clawed legs, chest low and haunches raised, a wedge head with a long muzzle and four fangs, tall ears, a ruff and big swept-back fur breaks along the back, a bushy tail curled to one side and a glowing crescent moon standing on the forehead",
    "hero": "the forehead crescent, the ruff and the fangs",
    "face": {"on": "head", "eye_scale": 2.0, "eye_gap": 1.42, "eye_tilt": 22.0, "mouth": "wide", "lid": 0.6, "eye_height": 0.62, "mouth_drop": 0.3, "look": (0.0, 0.0)},
    "palette": {"Body": "3B2E6B", "BodyDark": "8E84CC", "Accessory": "FFC83D", "Trim": "C9D3F0", "Mouth": "4A0E1A"}, "glow": {"Accessory": 3.0}, "metal": {"Trim": 0.85},
    "steps": [
        sph("Body", (0.0, -0.95, 2.2), (1.1, 1.1, 0.95), segments=16, name="chest"),
        sph("Body", (0.78, -1.0, 2.55), (0.62, 0.7, 0.7), segments=10, mirror=True, name="shoulder"),
        sph("Body", (0.0, 0.35, 2.75), (0.72, 0.85, 0.6), segments=14, name="waist"),
        sph("Body", (0.0, 1.1, 3.15), (0.84, 0.8, 0.76), segments=14, name="hips"),
        sph("Body", (0.7, 1.1, 2.8), (0.55, 0.78, 0.9), segments=10, mirror=True, name="thigh"),
        rod("Body", _FV2_NECK[0], _FV2_NECK[1], 0.74, 0.62, segments=10, name="neck"),
        sph("Body", _FV2_HEAD, (0.7, 0.84, 0.7), segments=16, name="head"),
        rod("Body", (0.0, -3.2, 2.58), (0.0, -5.1, 2.27), 0.42, 0.3, segments=10, name="muzzle"),
        rod("Body", (0.0, -3.0, 1.98), (0.0, -4.8, 1.45), 0.34, 0.26, segments=10, name="jaw"),
        sph("Body", (0.0, -5.25, 2.3), (0.26, 0.22, 0.19), segments=8, name="nose"),
        # long forelegs tapering to a slim wrist, big flat paws; Z-shaped hind legs (thigh, shank, a thin cannon) and big hind paws
        rod("Body", (0.8, -0.95, 2.35), (0.84, -1.3, 0.32), 0.52, 0.29, segments=8, mirror=True, name="foreleg"),
        sph("Body", (0.85, -1.45, 0.2), (0.44, 0.74, 0.23), segments=10, mirror=True, name="paw"),
        rod("Body", (0.7, 1.15, 2.75), (0.76, 0.65, 1.75), 0.5, 0.34, segments=8, mirror=True, name="thighbone"),
        rod("Body", (0.76, 0.65, 1.75), (0.8, 1.65, 0.95), 0.34, 0.24, segments=8, mirror=True, name="shank"),
        rod("Body", (0.8, 1.65, 0.95), (0.8, 1.5, 0.3), 0.24, 0.22, segments=8, mirror=True, name="cannon"),
        sph("Body", (0.8, 1.2, 0.2), (0.42, 0.7, 0.23), segments=10, mirror=True, name="hindpaw"),
        sweep("Body", [(0.0, 1.5, 3.3), (0.1, 2.2, 3.4), (0.4, 2.8, 3.7), (0.9, 3.25, 4.1), (1.5, 3.3, 4.4), (1.9, 2.9, 4.7), (1.9, 2.35, 4.9)],
              [0.38, 0.58, 0.72, 0.76, 0.66, 0.42, 0.08], name="tail"),
        # tall ears: flat wedges, thin front to back, with a darker inner ear
        _blade("Body", (0.46, -2.55, 3.0), (0.3, 0.2, 1.0), 1.45, 0.09, 0.5, "ear", thin_axis=(0.0, 1.0, 0.0), mirror=True),
        _blade("BodyDark", (0.46, -2.68, 3.1), (0.3, 0.2, 1.0), 1.0, 0.05, 0.3, "innerear", thin_axis=(0.0, 1.0, 0.0), mirror=True),
        _fin("BodyDark", (0.6, -2.95, 2.6), (0.75, 0.55, 0.1), 1.1, 0.3, 0.09, "cheek", wide_dir=(0.0, 0.0, 1.0), mirror=True),
        _fin("BodyDark", (0.55, -2.9, 2.25), (0.65, 0.6, -0.3), 0.9, 0.26, 0.09, "cheek", wide_dir=(0.0, 0.0, 1.0), mirror=True),
        # tail tufts on the outside of the curl
        _fin("BodyDark", (0.4, 2.5, 3.8), (0.4, 0.7, 0.5), 1.2, 0.34, 0.09, "tuft", wide_dir=(0.0, 0.0, 1.0)),
        _fin("BodyDark", (1.0, 3.6, 4.1), (0.6, 0.6, 0.5), 1.1, 0.32, 0.09, "tuft", wide_dir=(0.0, 0.0, 1.0)),
        _fin("BodyDark", (2.25, 3.0, 4.55), (0.9, 0.3, 0.2), 0.9, 0.28, 0.09, "tuft", wide_dir=(0.0, 0.0, 1.0)),
    ] + _FV2,
}
# ---------------------------------------------------------------------------------------- Skydrake (an original sky dragon)
# Round 2. Facing -Y, the body in one pronounced S-curve (x, z) with a smaller bend in y (the neck leans toward the viewer, the tail trails
# away), the head up on the centre line at the top, high above the tail. The body is ONE sweep (a tube of calibrated balls, thick at the chest,
# tapering to the tail tip that rests on the ground). Core (fused): the sweep, the wedge skull, the long snout, the jaw and the brow ridges.
# Crisp: the mane (one continuous ridge of large white fins from the head to the tail, with flares at the head), the cheek frills, the
# twice-branched gold antlers, the long gold whiskers, four small clawed feet and the pearl held under the chin in a gold cradle.
# The head is built from offsets about its centre scaled by _SKY_HS, so its size is one number.
_SKY_PATH = [(2.2, 1.7, 0.1), (1.8, 1.8, 0.15), (1.2, 1.6, 0.22), (0.55, 1.2, 0.36), (-0.1, 0.8, 0.62), (-0.85, 0.4, 1.02), (-1.4, 0.1, 1.57),
             (-1.5, -0.1, 2.2), (-1.0, -0.2, 2.8), (-0.2, -0.15, 3.25), (0.75, 0.0, 3.65), (1.25, -0.15, 4.2), (1.0, -0.4, 4.7), (0.35, -0.7, 5.0)]
_SKY_RADII = [0.06, 0.11, 0.2, 0.32, 0.42, 0.5, 0.54, 0.55, 0.54, 0.52, 0.5, 0.48, 0.47, 0.5]
_SKY_HC = (0.0, -1.0, 5.1)   # the head's centre
_SKY_HS = 1.3                 # the head's scale: every head offset and radius below is in units of this
_SKY = []


def _h(dx, dy, dz):
    """A point of the head: the offset (dx, dy, dz) from its centre, scaled."""
    return (_SKY_HC[0] + dx * _SKY_HS, _SKY_HC[1] + dy * _SKY_HS, _SKY_HC[2] + dz * _SKY_HS)


def _oval(slot, a, b, wx, wz, wx2, wz2, name, segments=10):
    """A rod from a to b (mostly along y) with an oval section: half width wx and half height wz at a, wx2 and wz2 at b (a snout is deeper than wide)."""
    d = _sub(b, a)
    return cone(slot, _mul(_add(a, b), 0.5), (wx, wz, _len(d) / 2.0), rot=aim(d), tip=wx2 / wx, segments=segments, name=name)


def _sky_at(u):
    """The body at u in [0, 1] from the tail tip to the neck: (point, tangent toward the head, dorsal direction, side direction, radius).
    Dorsal is +y (the back of the neck faces away from the viewer, so the mane stands up behind the head and fans out to both sides)."""
    p, t = crom(_SKY_PATH, u)
    d = _unit(_sub((0.0, 1.0, 0.0), _mul(t, t[1])))
    n = _cross(t, d)
    f = max(0.0, min(1.0, u)) * (len(_SKY_PATH) - 1)
    i = min(int(f), len(_SKY_PATH) - 2)
    return p, t, d, n, _SKY_RADII[i] + (_SKY_RADII[i + 1] - _SKY_RADII[i]) * (f - i)


# the mane: ONE continuous ridge of large white fins from the head to the tail (each overlaps the next), streaming back along the body
for _k in range(15):
    _u = 0.985 - _k * 0.0467
    _p, _t, _d, _n, _r = _sky_at(_u)
    _f = _k / 14.0
    _SKY.append(_fin("BodyDark", _add(_p, _mul(_d, _r * 0.55)), _add(_mul(_d, 0.55), _mul(_t, -0.85)), 2.0 - 1.3 * _f, 0.62 - 0.36 * _f, 0.07,
                     "mane", wide_dir=_t))
# the mane flares out at the head: a pair of side fins at the first three stations
for _u, _ln in ((0.97, 1.4), (0.9, 1.25), (0.83, 1.1)):
    _p, _t, _d, _n, _r = _sky_at(_u)
    for _s in (-1, 1):
        _SKY.append(_fin("BodyDark", _add(_add(_p, _mul(_d, _r * 0.3)), _mul(_n, _s * _r * 0.5)),
                         _add(_add(_mul(_d, 0.3), _mul(_n, _s * 0.8)), _mul(_t, -0.6)), _ln, 0.32, 0.07, "mane", wide_dir=_d))
# cheek frills: white fins thrown out and back from the jaw hinge, so the head is wide at the back and narrow at the nose (a wedge from the front)
for _b, _d, _ln in (((0.4, 0.15, 0.0), (0.9, 0.4, 0.1), 1.0), ((0.36, 0.2, -0.25), (0.8, 0.5, -0.3), 0.8)):
    _SKY.append(_fin("BodyDark", _h(*_b), _d, _ln * _SKY_HS, 0.26 * _SKY_HS, 0.07, "frill", wide_dir=(0.0, 0.0, 1.0), mirror=True))
# antler horns, branched twice: a main beam sweeping back from the skull with two tines, and each tine forks into two prongs. Gold.
_HORN = (((0.26, 0.05, 0.35), (0.42, 0.4, 0.8), 0.1, 0.085, 5), ((0.42, 0.4, 0.8), (0.55, 0.9, 1.15), 0.085, 0.065, 5),
         ((0.55, 0.9, 1.15), (0.5, 1.45, 1.35), 0.065, 0.02, 5))
for _a, _b, _r0, _r1, _sg in _HORN:
    _SKY.append(rod("Trim", _h(*_a), _h(*_b), _r0 * _SKY_HS, _r1 * _SKY_HS, segments=_sg, mirror=True, name="horn"))
for _pts, _rr in (([(0.42, 0.4, 0.8), (0.85, 0.55, 1.15)], (0.06, 0.045)),   # first tine
                  ([(0.85, 0.55, 1.15), (1.1, 0.5, 1.6)], (0.045, 0.015)), ([(0.85, 0.55, 1.15), (1.25, 0.75, 1.25)], (0.04, 0.012)),   # its two prongs
                  ([(0.55, 0.9, 1.15), (0.95, 1.05, 1.5)], (0.055, 0.04)),    # second tine
                  ([(0.95, 1.05, 1.5), (1.1, 1.0, 1.95)], (0.04, 0.014)), ([(0.95, 1.05, 1.5), (1.35, 1.35, 1.55)], (0.035, 0.012))):   # its two prongs
    _SKY += _chain("Trim", [_h(*q) for q in _pts], [v * _SKY_HS for v in _rr], "horn", segments=4)
# long whiskers from the sides of the snout, gold, swept back past the neck
_SKY += _chain("Trim", [_h(*q) for q in ((0.18, -1.0, -0.3), (0.6, -1.1, -0.25), (1.2, -0.9, -0.4), (1.9, -0.4, -0.65), (2.6, 0.3, -1.0))],
               (0.05, 0.045, 0.036, 0.027, 0.016), "whisker")
_SKY += _chain("Trim", [_h(*q) for q in ((0.16, -0.95, -0.45), (0.55, -1.1, -0.55), (1.0, -0.95, -0.8), (1.5, -0.55, -1.1))],
               (0.045, 0.038, 0.028, 0.016), "whisker")
# four small clawed feet: a short mitten of a leg out to each side of the body (wide at the paw), two gold claws on each
for _u in (0.8, 0.42):
    _p, _t, _d, _n, _r = _sky_at(_u)
    for _s in (-1, 1):
        _a = _add(_add(_p, _mul(_n, _s * _r * 0.8)), _mul(_d, -_r * 0.3))
        _tip = _add(_add(_a, _mul(_n, _s * 0.3)), (0.0, -0.2, -0.45))
        _SKY.append(cone("Body", _mul(_add(_a, _tip), 0.5), (0.2, 0.2, _len(_sub(_tip, _a)) / 2.0), rot=aim(_sub(_a, _tip)), tip=0.5, segments=6, name="foot"))
        for _c in (-1, 1):
            _cb = _add(_tip, (0.09 * _c, 0.0, 0.0))
            _SKY.append(_blade("Trim", _cb, _add(_sub(_tip, _a), (0.5 * _c, 0.0, 0.0)), 0.27, 0.055, 0.055, "claw", segments=5))
# the pearl, larger, held under the chin in a small gold cradle
_SKY.append(sph("Accessory", _h(0.0, -0.95, -1.1), 0.55, segments=12, name="pearl"))
_SKY.append(tor("Trim", _h(0.0, -0.95, -1.1 + 0.2 / _SKY_HS), (0.5, 0.5, 0.5), minor=0.16, segments=8, mseg=4, name="cradle"))
_SKY += _chain("Trim", [_h(0.15, -0.9, -0.62), _h(0.15, -0.95, -1.1 + 0.2 / _SKY_HS)], (0.04, 0.04), "tether", segments=4)

RECIPES["Skydrake"] = {
    "tier": "Legendary", "world": 0, "biome": "Sky", "batch": 0, "status": "recipe", "prototype": True, "height": 7.57,
    "silhouette": "a long pale-jade serpent in one deep S-curve, tail on the ground and the head carried high, a wedge head with a brow ridge and a long snout, twice-branched gold antlers, a continuous ridge of white fins down the neck and back, long swept-back whiskers, four small clawed feet and a glowing pearl held under the chin",
    "hero": "the S-curve body with its white mane, the antlers and the pearl",
    "face": {"on": "head", "eye_scale": 1.5, "eye_gap": 1.35, "eye_tilt": 0.0, "mouth": "wide", "look": (0.0, 0.1), "cross": 0.08, "eye_height": 0.62, "mouth_drop": 0.3, "mouth_scale": 1.35},
    "palette": {"Body": "9AD8BA", "BodyDark": "F4F7F2", "Accessory": "CFE8FF", "Trim": "F2B632", "Mouth": "7A1F3D"}, "glow": {"Accessory": 2.5}, "metal": {"Trim": 0.9},
    "steps": [
        sweep("Body", _SKY_PATH, _SKY_RADII, name="body"),
        sph("Body", _h(0.0, 0.0, 0.0), (0.52 * _SKY_HS, 0.62 * _SKY_HS, 0.48 * _SKY_HS), segments=16, name="head"),
        _oval("Body", _h(0.0, -0.3, -0.2), _h(0.0, -1.8, -0.38), 0.3 * _SKY_HS, 0.4 * _SKY_HS, 0.2 * _SKY_HS, 0.27 * _SKY_HS, name="snout"),
        _oval("Body", _h(0.0, -0.25, -0.55), _h(0.0, -1.5, -0.7), 0.2 * _SKY_HS, 0.24 * _SKY_HS, 0.13 * _SKY_HS, 0.15 * _SKY_HS, name="jaw"),
        # the brow ridge: a thick rod over each eye, from the bridge of the snout back along the skull
        rod("Body", _h(0.06, -0.55, 0.5), _h(0.55, 0.05, 0.42), 0.1 * _SKY_HS, 0.035 * _SKY_HS, segments=8, mirror=True, name="brow"),
    ] + _SKY,
}
# ==== HEROES END ====

# ==== DESIGN PASS 1 BEGIN (prototypes, not shipped species: docs/vault/06-art-pipelines/Design-Pass.md; written 2026-10-15) ====
# The per-species design pass, batch 1: eight species whose shape barely changed through the sculpt passes get a new base design and a feature
# set of their world, as `<Id>V2` prototype recipes. Each is `"prototype": True` (no assets/models folder of its own, no Species.luau row; the
# group ids skip it, a name picks it, the tests do not hold it to the shipped files) and keeps its species' height, slots and palette. They are
# built with `species_sculpt.py --method hybrid` on a scratch copy of the species' model folder renamed `<Id>V2`; the exact command lines
# (the `--set` overrides) are in Design-Pass.md. Facing -Y, feet on z 0, as everywhere in this file.


def _leaf(slot, base, d, length, wide, thick, name, thin_axis=(1.0, 0.0, 0.0), mirror=False, segments=8, **kw):
    """A flat leaf: an ellipsoid standing on `base` and running along d for `length`, `wide` the half width and `thick` the half thickness
    (across thin_axis). A sprout leaf, a wing, a mitten, a flipper. Thinner than 0.1 and off the ground, the hybrid takes it for a crisp part."""
    f = _unit(d)
    return sph(slot, _add(base, _mul(f, length / 2.0)), (thick, wide, length / 2.0), rot=_basis(f, thin_axis), segments=segments, mirror=mirror,
               name=name, **kw)


# ---------------------------------------------------------------------------------------- Mossbop v2
# A crouching moss tuft: a pale face low in front of an arched back, a dark moss mat over the ridge of the back with a crest of three little sprouts
# (a stalk and a pair of round seed leaves each) growing out of it, the orange-budded one standing tallest in the middle, two stubby arms (one
# planted, one raised in a wave), a tail tuft and two dark feet.
def _sprout(y, z, rise, leaf, name="sprout", lean=0.15):
    """One seedling on the ridge of the back at (0, y, z): a stalk `rise` tall and a pair of round leaves opening to either side of its top."""
    top = (0.0, y, z + rise)
    return [rod("BodyDark", (0.0, y, z - 0.1), top, 0.09, 0.07, segments=6, name=name + "stalk"),
            _leaf("BodyDark", top, (0.85, lean, 0.45), leaf, 0.24, 0.055, name + "leaf", thin_axis=(0.0, 1.0, 0.0), mirror=True, segments=10)]


RECIPES["MossbopV2"] = {
    "tier": "Common", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 2.64,
    "silhouette": "a crouching moss tuft: a pale face low in front of an arched back under a dark moss mat, a crest of three little sprouts (a stalk and two round seed leaves each) growing from the mat with the orange-budded one tallest in the middle, one stubby arm planted and one raised in a wave, a tail tuft",
    "hero": "the sprout crest: three seedlings growing from the moss mat on the arched back and the orange bud on the tallest",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.0, "eye_tilt": 0.0, "mouth": "o", "look": (0.12, -0.08), "cross": 0.06},
    "palette": {"BodyDark": "3F8F2E", "Accessory": "FF8A3D"},
    "steps": [
        sph("Body", (0.0, -0.8, 0.85), (0.95, 0.85, 0.75), segments=18, name="head"),
        sph("Body", (0.0, 0.4, 1.0), (1.05, 1.1, 0.82), segments=16, name="body"),
        sph("BodyDark", (0.0, 1.45, 0.65), (0.4, 0.45, 0.36), segments=10, name="tuft"),
        sph("BodyDark", (0.0, 0.4, 1.62), (0.62, 1.0, 0.3), segments=14, name="moss"),
        sph("BodyDark", (0.62, 0.3, 0.2), (0.42, 0.52, 0.22), segments=10, mirror=True, name="foot"),
        rod("Body", (-0.95, -0.35, 0.9), (-1.2, -1.0, 0.3), 0.26, 0.22, segments=8, name="arm"),
        sph("BodyDark", (-1.2, -1.05, 0.24), (0.3, 0.34, 0.24), segments=10, name="paw"),
        rod("Body", (0.95, -0.3, 1.0), (1.5, -0.55, 1.8), 0.26, 0.22, segments=8, name="arm"),
        sph("BodyDark", (1.55, -0.57, 1.92), 0.34, segments=10, name="paw"),
    ] + _sprout(-0.2, 1.66, 0.32, 0.52, lean=0.1) + _sprout(0.4, 1.78, 0.6, 0.68, lean=0.15) + _sprout(1.0, 1.68, 0.4, 0.55, lean=0.4) + [
        sph("Accessory", (0.0, 0.4, 2.5), (0.22, 0.22, 0.22), segments=10, name="bud"),
    ],
}


# ---------------------------------------------------------------------------------------- Glimmo v2
# A jelly firefly hovering upright and leaning: a big glassy head over a small thorax, two long amber wings swept out and back, two long curling
# antennae with bobbles, and the glowing lantern (the Accessory, the one part that glows) hanging under it, swung to one side: a lamp with a cap, a
# bottom cap and a tassel.
_GL_U = _unit((-0.3, -0.1, 1.0))  # the lantern's axis, bottom to top
_GL_C = (0.65, 0.4, 0.9)
_GL_ANT = []  # the antennae: each a short run of rods that curls outward, tipped with a bobble
for _s in (-1, 1):
    _p = (_s * 0.4, -0.35, 2.65)
    for _k, (_d, _r0, _r1) in enumerate((((0.35 * _s, -0.1, 1.0), 0.06, 0.052), ((0.8 * _s, -0.1, 0.6), 0.052, 0.045), ((1.0 * _s, -0.05, 0.1), 0.045, 0.036))):
        _q = _add(_p, _mul(_unit(_d), 0.34))
        _GL_ANT.append(rod("BodyDark", _p, _q, _r0, _r1, segments=5, name="antenna"))
        _p = _q
    _GL_ANT.append(sph("BodyDark", _add(_p, (0.0, 0.0, 0.05)), 0.12, segments=8, name="antennatip"))
RECIPES["GlimmoV2"] = {
    "tier": "Common", "world": 1, "biome": "Forest", "batch": 0, "status": "recipe", "prototype": True, "height": 2.70,
    "silhouette": "a jelly firefly hovering upright and leaning: a big round head over a small body, two long amber wings swept out and back, two long curling antennae with bobbles, and a glowing paper-lantern abdomen with a cap and a tassel hanging under it and swung to one side",
    "hero": "the lantern abdomen with its caps and tassel, and the swept wings",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 0.98, "eye_tilt": 0.0, "mouth": "smile", "look": (0.0, 0.1)},
    "palette": {"BodyDark": "E4A83A", "Accessory": "B8FF4F"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0.0, -0.25, 1.9), (0.92, 0.85, 0.86), segments=18, name="head"),
        sph("Body", (0.2, 0.15, 1.35), (0.5, 0.5, 0.46), segments=14, name="thorax"),
        sph("Accessory", _GL_C, (0.64, 0.62, 0.7), rot=_basis(_GL_U, (1.0, 0.0, 0.0)), segments=14, name="lantern"),
        cyl("BodyDark", _add(_GL_C, _mul(_GL_U, 0.7)), (0.36, 0.36, 0.07), rot=aim(_GL_U), segments=12, name="cap"),
        cyl("BodyDark", _sub(_GL_C, _mul(_GL_U, 0.7)), (0.3, 0.3, 0.07), rot=aim(_GL_U), segments=12, name="cap"),
        spike("BodyDark", _sub(_GL_C, _mul(_GL_U, 0.74)), _sub(_GL_C, _mul(_GL_U, 0.96)), 0.09, segments=6, name="tassel"),
        _leaf("BodyDark", (-0.1, 0.2, 1.5), (-0.85, 0.55, 0.45), 1.8, 0.56, 0.05, "wing", thin_axis=(0.5, 0.5, 0.7), segments=12),
        _leaf("BodyDark", (0.5, 0.25, 1.5), (0.85, 0.55, 0.4), 1.6, 0.52, 0.05, "wing", thin_axis=(-0.5, 0.5, 0.7), segments=12),
    ] + _GL_ANT,
}


# ---------------------------------------------------------------------------------------- Puffpuff v2
# A puff with a stem tail and seed wings: a fluffy cloud of a ball on two leaf feet, a green stem curling out to one side as a tail with a pair of
# seedling leaves at the tip, and two wings raised in a V that are fans of rays, each ray tipped with a yellow seed.
_PF_C = (0.0, 0.0, 1.3)
_PF_FLUFF = ((0.9, 0.1, 0.35), (-0.9, 0.1, 0.35), (0.75, 0.45, -0.3), (-0.75, 0.45, -0.3), (0.0, 0.9, 0.4), (0.45, 0.2, 0.88), (-0.45, 0.2, 0.88), (0.0, 0.55, -0.8))
_PF_SEEDS = []  # the wing fans: five rays each, spread in the wing's plane from straight up to level
for _s in (1, -1):
    for _phi, _ln in ((8.0, 1.15), (28.0, 1.3), (48.0, 1.4), (68.0, 1.35), (88.0, 1.2)):
        _d = _unit((_s * math.sin(math.radians(_phi)), 0.3, math.cos(math.radians(_phi))))
        _a = (_s * 0.6, 0.3, 1.55)
        _PF_SEEDS.append((_a, _add(_a, _mul(_d, _ln))))
RECIPES["PuffpuffV2"] = {
    "tier": "Common", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 2.20,
    "silhouette": "a puff with a stem tail and seed wings: a fluffy cloud of a ball on two leaf feet, a green stem curling out to one side as a tail with a pair of seedling leaves, and two wings raised in a V that are fans of rays tipped with yellow seeds",
    "hero": "the seed wings and the stem tail",
    "face": {"on": "body", "eye_scale": 1.3, "eye_gap": 1.05, "eye_tilt": -10.0, "mouth": "o", "lid": 0.12, "look": (0.0, 0.0)},
    "palette": {"BodyDark": "8FC96A", "Accessory": "FFD84A"},
    "steps": [
        sph("Body", _PF_C, (0.85, 0.82, 0.8), segments=18, name="body"),
        sph("BodyDark", (0.38, -0.2, 0.13), (0.3, 0.46, 0.14), segments=10, mirror=True, name="leaffoot"),
        sweep("BodyDark", [(0.25, 0.55, 1.0), (0.8, 0.9, 0.75), (1.3, 0.8, 0.4), (1.55, 0.35, 0.16)], [0.2, 0.17, 0.13, 0.09], name="stem"),
        _leaf("BodyDark", (1.55, 0.35, 0.16), (0.5, -0.6, 0.5), 0.6, 0.18, 0.05, "seedling", thin_axis=(0.0, 0.0, 1.0)),
        _leaf("BodyDark", (1.55, 0.35, 0.16), (0.9, 0.2, 0.55), 0.6, 0.18, 0.05, "seedling", thin_axis=(0.0, 0.0, 1.0)),
    ] + [sph("Body", _add(_PF_C, _mul(_unit(dv), 0.66)), 0.4, segments=10, name="fluff") for dv in _PF_FLUFF]
      + [rod("Body", a, b, 0.095, 0.06, segments=6, name="ray") for a, b in _PF_SEEDS]
      + [sph("Accessory", b, 0.15, segments=6, name="seed") for a, b in _PF_SEEDS],
}


# ---------------------------------------------------------------------------------------- Drippo v2
# An icicle imp: a round head that tapers into a long hanging icicle that ends in a fat drop about to fall (the drop rests on the ground and is the spawn point of the falling-drop effect), a coral crown (a circlet with six ice drips
# tipped with beads) on its head, pointed ice ears, two big mitts floating at its sides (one raised) and a pointed imp tail.
_DR_CROWN = []
for _a in (270.0, 220.0, 320.0, 160.0, 20.0, 90.0):
    _c, _s = math.cos(math.radians(_a)), math.sin(math.radians(_a))
    _tall = 0.52 if _a == 270.0 else 0.4
    _b = (0.6 * _c, -0.02 + 0.56 * _s, 1.66)
    _t = (_b[0] + 0.1 * _c, _b[1] + 0.1 * _s, _b[2] + _tall)
    _DR_CROWN += [spike("Accessory", _b, _t, 0.12, segments=6, name="drip"), sph("Accessory", (_t[0], _t[1], _t[2] + 0.04), 0.085, segments=6, name="bead")]
RECIPES["DrippoV2"] = {
    "tier": "Common", "world": 2, "biome": "IceCave", "batch": 0, "status": "recipe", "prototype": True, "height": 2.11,
    "silhouette": "an icicle imp: a round head that tapers into a long hanging icicle that ends in a fat drop about to fall, a coral crown of six drips tipped with beads, pointed ears, two big mitts floating at its sides and a pointed tail",
    "hero": "the drip crown and the mitt hands",
    "face": {"on": "head", "eye_scale": 1.25, "eye_gap": 0.95, "eye_tilt": 6.0, "mouth": "o", "lid": 0.2, "eye_height": 0.5},
    "palette": {"BodyDark": "6FA9D6", "Accessory": "FF8E5B"},
    "steps": [
        sph("Body", (0.0, 0.0, 1.32), (0.78, 0.72, 0.56), segments=16, name="head"),
        sweep("Body", [(0.0, 0.05, 1.2), (0.0, 0.05, 0.8), (0.0, 0.05, 0.5), (0.0, 0.05, 0.32), (0.0, 0.05, 0.15)], [0.6, 0.46, 0.22, 0.08, 0.15], name="icicle"),
        sph("BodyDark", (1.2, -0.25, 1.15), (0.38, 0.34, 0.4), segments=12, name="mitt"),
        sph("BodyDark", (1.42, -0.25, 1.5), (0.14, 0.12, 0.2), segments=8, name="thumb"),
        sph("BodyDark", (-1.0, -0.3, 0.55), (0.34, 0.32, 0.36), segments=12, name="mitt"),
        sph("BodyDark", (-1.15, -0.3, 0.85), (0.13, 0.12, 0.2), segments=8, name="thumb"),
        spike("BodyDark", (0.6, 0.0, 1.3), (1.3, 0.0, 1.62), 0.15, segments=6, mirror=True, name="ear"),
        sweep("BodyDark", [(0.0, 0.55, 0.75), (0.0, 1.0, 0.6), (0.4, 1.3, 0.8), (0.7, 1.35, 1.2)], [0.15, 0.12, 0.1, 0.07], name="tail"),
        spike("BodyDark", (0.7, 1.35, 1.2), (0.85, 1.35, 1.6), 0.14, segments=6, name="tailtip"),
        tor("Accessory", (0.0, -0.02, 1.64), (0.62, 0.58, 0.62), minor=0.2, segments=16, mseg=5, name="band"),
    ] + _DR_CROWN,
}


# ---------------------------------------------------------------------------------------- Kettlepuff v2
# A round-bellied steam critter: a pear of a body (a broad round belly under a narrower chest that carries the face) on two stubby feet, a stout copper
# spout for a snout curling up from the right cheek (clear of the eyes and the open mouth) with two puffs of steam rising from it, a tilted grey lid for a hat with a knob, one stubby arm planted
# and one raised, and a big handle looped behind like a tail.
RECIPES["KettlepuffV2"] = {
    "tier": "Common", "world": 2, "biome": "GeyserField", "batch": 0, "status": "recipe", "prototype": True, "height": 2.20,
    "silhouette": "a round-bellied steam critter: a pear of a body on two stubby feet, a stout copper spout for a snout curling up from the cheek with two puffs of steam rising from it, a tilted grey lid for a hat, one stubby arm waving and a big handle looped behind like a tail",
    "hero": "the spout snout with its steam, the tilted lid hat and the handle tail",
    "face": {"on": "chest", "eye_scale": 1.6, "eye_gap": 1.35, "eye_tilt": 0.0, "mouth": "o", "look": (0.0, 0.08), "eye_height": 0.62, "mouth_drop": 0.3},
    "palette": {"BodyDark": "9F9A92", "Accessory": "E8793A"},
    "steps": [
        sph("Body", (0.0, 0.05, 0.58), (1.0, 0.9, 0.52), segments=20, name="belly"),
        sph("Body", (0.0, -0.05, 1.0), (0.8, 0.72, 0.56), segments=18, name="chest"),
        rod("BodyDark", (0.42, -0.15, 0.4), (0.44, -0.25, 0.22), 0.26, 0.2, segments=8, mirror=True, name="leg"),
        sph("BodyDark", (0.44, -0.3, 0.14), (0.3, 0.4, 0.14), segments=10, mirror=True, name="foot"),
        rod("Body", (0.9, -0.25, 0.7), (1.3, -0.45, 0.45), 0.22, 0.16, segments=8, name="arm"),
        rod("Body", (-0.65, -0.3, 0.9), (-1.1, -0.7, 1.4), 0.22, 0.16, segments=8, name="arm"),
        rod("Accessory", (0.5, -0.5, 0.8), (0.82, -0.85, 0.8), 0.27, 0.21, segments=12, name="spout"),
        rod("Accessory", (0.82, -0.85, 0.8), (1.02, -1.15, 0.95), 0.21, 0.18, segments=12, name="spout"),
        rod("Accessory", (1.02, -1.15, 0.95), (1.12, -1.3, 1.25), 0.18, 0.16, segments=12, name="spout"),
        tor("Accessory", (1.12, -1.3, 1.3), (0.19, 0.19, 0.19), rot=aim((0.1, -0.1, 1.0)), minor=0.3, segments=12, mseg=4, name="lip"),
        sph("EyeWhite", (1.14, -1.3, 1.62), 0.16, segments=8, name="puff"),
        sph("EyeWhite", (1.22, -1.26, 1.88), 0.22, segments=8, name="puff"),
        sph("BodyDark", (0.08, 0.0, 1.55), (0.62, 0.58, 0.27), rot=(0, 10, 0), segments=14, name="lid"),
        tor("BodyDark", (0.06, 0.0, 1.47), (0.66, 0.62, 0.66), rot=(0, 10, 0), minor=0.14, segments=14, mseg=4, name="rim"),
        sph("Accessory", (0.2, 0.0, 1.84), 0.14, segments=8, name="knob"),
        tor("Accessory", (0.0, 1.1, 0.82), (0.62, 0.62, 0.62), rot=(0, 90, 0), minor=0.2, segments=20, mseg=5, name="handle"),
    ],
}


# ---------------------------------------------------------------------------------------- Flufflet v2
# A mitten-eared snow pup: a snowball head on a snowball body (a snowman stack with puppy legs), two big knitted mitten ears held out sideways, each
# with a thumb, a coral scarf round the neck (a ring across the join of head and body) with its streamer whipping back to the left, one front paw raised and a curled tail.
_FL_KNOT = (-0.7, 0.02, 1.3)
_FL_STREAMER = []  # the scarf's free end: a band that leaves the knot at the neck, goes left and back and ripples a little as it goes
for _i in range(16):
    _u = _i / 15.0
    _FL_STREAMER.append((_FL_KNOT[0] - 0.12 - 1.05 * _u - 0.16 * math.sin(2.0 * math.pi * _u), _FL_KNOT[1] + 0.12 + 1.15 * _u + 0.12 * math.sin(2.0 * math.pi * _u),
                         _FL_KNOT[2] - 0.05 + 0.45 * _u + 0.13 * math.sin(2.0 * math.pi * _u * 1.3)))
_FL_NECK = _unit((0.0, 0.82, -0.57))  # the line from the head's centre to the body's: the scarf ring lies across it, where the two balls meet
RECIPES["FluffletV2"] = {
    "tier": "Common", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 2.64,
    "silhouette": "a snow pup: a snowball head on a snowball body, two big knitted mitten ears held out sideways with their thumbs up, a coral scarf round the neck with a streamer whipping back, one front paw raised and a curled tail",
    "hero": "the mitten ears and the whipping scarf",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 0.95, "eye_tilt": -8.0, "mouth": "o", "lid": 0.2, "look": (0.06, 0.05)},
    "palette": {"BodyDark": "9DB7D5", "Accessory": "FF7A59"},
    "ribbons": [{"slot": "Accessory", "name": "streamer", "pts": _FL_STREAMER, "thick": 0.07, "widths": [0.22 - 0.07 * (_i / 15.0) ** 2 for _i in range(16)]}],
    "steps": [
        sph("Body", (0.0, 0.55, 0.95), (1.0, 0.95, 0.9), segments=18, name="body"),
        sph("Body", (0.0, -0.5, 1.68), (0.88, 0.8, 0.8), segments=18, name="head"),
        rod("Body", (-0.5, -0.2, 0.95), (-0.52, -0.6, 0.25), 0.26, 0.2, segments=8, name="foreleg"),
        sph("BodyDark", (-0.52, -0.66, 0.15), (0.3, 0.4, 0.16), segments=10, name="paw"),
        rod("Body", (0.5, -0.2, 1.0), (0.95, -0.7, 1.35), 0.24, 0.18, segments=8, name="foreleg"),
        sph("BodyDark", (1.02, -0.78, 1.4), 0.3, segments=10, name="paw"),
        sph("BodyDark", (0.6, 1.0, 0.17), (0.34, 0.48, 0.17), segments=10, mirror=True, name="paw"),
        sweep("Body", [(0.0, 1.3, 0.95), (0.0, 1.8, 1.2), (0.0, 1.85, 1.65)], [0.26, 0.2, 0.14], name="tail"),
        _leaf("BodyDark", (0.55, -0.4, 2.1), (0.95, 0.0, 0.3), 1.0, 0.36, 0.11, "mitten", thin_axis=(0.0, 1.0, 0.0), mirror=True),
        _leaf("BodyDark", (1.2, -0.4, 2.5), (0.15, 0.0, 1.0), 0.46, 0.15, 0.11, "thumb", thin_axis=(0.0, 1.0, 0.0), mirror=True),
        tor("Accessory", (0.0, -0.02, 1.35), (0.66, 0.66, 0.66), rot=aim(_FL_NECK), minor=0.38, segments=16, mseg=5, name="scarf"),
        sph("Accessory", _FL_KNOT, (0.27, 0.27, 0.27), segments=8, name="knot"),
    ],
}


# ---------------------------------------------------------------------------------------- Capybubble v2
# A capybara loafing flat as a loaf: a long low barrel, a heavy head with a blunt boxy muzzle, two small round ears, four stubby feet and a crown of
# soap bubbles round a tangerine on its head with a column of bubbles rising from it, the bubbles growing as they climb.
RECIPES["CapybubbleV2"] = {
    "tier": "Rare", "world": 2, "biome": "GeyserField", "batch": 0, "status": "recipe", "prototype": True, "height": 2.98,
    "silhouette": "a capybara loafing flat as a loaf: a long low barrel, a heavy head with a blunt boxy muzzle, small round ears, stubby feet, and a crown of soap bubbles round a tangerine on its head with a column of bubbles rising from it",
    "hero": "the bubble crown round the tangerine and the rising column",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.2, "eye_tilt": -6.0, "mouth": "o", "lid": 0.35},
    "palette": {"BodyDark": "927F68", "Accessory": "FF8A1F"}, "glow": {"Accessory": 1.0}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0.0, 0.6, 0.58), (0.95, 1.45, 0.58), segments=16, name="barrel"),
        sph("Body", (0.0, -1.1, 0.68), (0.76, 0.68, 0.55), segments=16, name="head"),
        sph("Body", (0.0, -1.62, 0.52), (0.46, 0.42, 0.32), segments=12, name="muzzle"),
        sph("BodyDark", (0.0, -1.96, 0.68), (0.18, 0.13, 0.13), segments=8, name="nose"),
        sph("BodyDark", (0.55, -0.85, 1.15), (0.18, 0.12, 0.2), segments=8, mirror=True, name="ear"),
        sph("BodyDark", (0.6, -0.45, 0.12), (0.28, 0.4, 0.12), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (0.62, 1.4, 0.12), (0.28, 0.4, 0.12), segments=8, mirror=True, name="foot"),
        sph("Accessory", (0.0, -1.1, 1.5), 0.46, segments=12, name="tangerine"),
        sph("BodyDark", (0.0, -1.1, 1.94), (0.12, 0.12, 0.05), segments=6, name="calyx"),
    ] + [sph("EyeWhite", (0.72 * math.cos(math.radians(360.0 * i / 7.0)), -1.1 + 0.72 * math.sin(math.radians(360.0 * i / 7.0)), 1.28),
             0.23 + 0.04 * (i % 2), segments=8, name="bubble") for i in range(7)]
      + [sph("EyeWhite", p, r, segments=10, name="bubble") for p, r in (((0.4, -0.75, 1.95), 0.36), ((0.55, -0.6, 2.42), 0.3), ((0.62, -0.5, 2.78), 0.2))],
}


# ---------------------------------------------------------------------------------------- Pengoo v2
# A round penguin in a tux: an egg of a body leaning to one side with a white belly shield, a small orange beak above the open mouth, two paddle
# flipper arms (one up in a wave), orange webbed feet, a tail wedge and a tiny orange backpack with a flap.
RECIPES["PengooV2"] = {
    "tier": "Uncommon", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 1.98,
    "silhouette": "a round penguin in a tux: an egg of a body leaning to one side with a white belly shield, a small orange beak above the open mouth, two paddle flipper arms (one waving), orange webbed feet, a tail wedge and a tiny orange backpack",
    "hero": "the flipper arms and the tiny backpack",
    "face": {"on": "body", "eye_scale": 1.15, "eye_gap": 1.1, "eye_tilt": -6.0, "mouth": "wide", "lid": 0.1, "eye_height": 0.72},
    "palette": {"BodyDark": "1C293C", "Accessory": "FF8A3D"},
    "steps": [
        sph("Body", (0.0, 0.05, 0.95), (0.9, 0.86, 0.94), rot=(0, 8, 0), segments=18, name="body"),
        sph("Belly", (0.0, -0.5, 0.6), (0.6, 0.5, 0.52), segments=14, name="belly"),
        _leaf("BodyDark", (-0.8, 0.0, 1.1), (-1.0, -0.1, -0.1), 1.3, 0.36, 0.09, "flipper", thin_axis=(0.0, 1.0, 0.0), segments=12),
        _leaf("BodyDark", (0.8, 0.0, 1.15), (0.55, -0.1, 0.95), 1.25, 0.36, 0.09, "flipper", thin_axis=(0.0, 1.0, 0.0), segments=12),
        spike("Accessory", (0.0, -0.8, 1.2), (0.0, -1.3, 1.05), 0.17, segments=5, name="beak"),
        sph("Accessory", (0.38, -0.5, 0.1), (0.34, 0.52, 0.11), segments=10, mirror=True, name="foot"),
        spike("BodyDark", (0.0, 0.85, 0.35), (0.0, 1.35, 0.12), 0.2, segments=6, name="tail"),
        cube("Accessory", (0.0, 0.95, 1.1), (0.4, 0.22, 0.42), name="backpack"),
        cube("BodyDark", (0.0, 0.97, 1.55), (0.42, 0.25, 0.06), name="flap"),
    ],
}
# ==== DESIGN PASS 1 END ====


# ==== DESIGN PASS 2 BEGIN (prototypes, not shipped species: docs/vault/06-art-pipelines/Design-Pass.md "Batch 2"; written 2026-10-15) ====
# The per-species design pass, batch 2: the eight rarer species whose faces carry a mood (Sculpt-Pass.md "Temperament moods") but whose bodies were
# still round cute things. Each `<Id>V2` is a `"prototype": True` recipe that keeps its species' height, slots, palette and glow and gives it a body
# that carries its temperament: stance, proportions, a silhouette of its own, a feature set of its world. Built with `species_sculpt.py --method
# hybrid` on a scratch copy of the species' folder renamed `<Id>V2`, with `--set face.mood=<mood>` (the V2 keys are not in the sculpt's SPECIES
# table); the exact command lines are in Design-Pass.md. Facing -Y, feet on z 0, as everywhere in this file. Helpers from the hero and batch 1 blocks
# (_blade, _fin, _leaf, _chain, _crescent, _basis) are reused.


def _msweep(slot, pts, radii, name):
    """A sweep and its mirror image across x = 0 (a pair of horns, tines or legs): one step when the curve lies on the centre line."""
    out = [sweep(slot, pts, radii, name)]
    if any(abs(p[0]) > 1e-6 for p in pts):
        out.append(sweep(slot, [(-p[0], p[1], p[2]) for p in pts], radii, name))
    return out


def _zig(slot, base, d, lengths, radii, bend, name, mirror=False):
    """A lightning-bolt quill: tapered flat-shaded cones that zig and zag (the direction turns by +-bend degrees about the x axis at each joint),
    starting at `base` heading along d; radii[i] is the radius at the start of cone i, the last cone ends in a point."""
    out, p = [], base
    d = _unit(d)
    for i, (ln, r) in enumerate(zip(lengths, radii)):
        if i:
            a = math.radians(bend * (1 if i % 2 else -1))
            d = _unit((d[0], d[1] * math.cos(a) - d[2] * math.sin(a), d[1] * math.sin(a) + d[2] * math.cos(a)))
        q = _add(p, _mul(d, ln))
        r2 = radii[i + 1] if i + 1 < len(radii) else 0.02
        out.append(rod(slot, p, q, r, r2, segments=4, flat=True, mirror=mirror, name=name))
        p = q
    return out


# ---------------------------------------------------------------------------------------- Thunderhog v2
# A storm beast, not a hedgehog ball: a low, forward-leaning boar, a wedge that is heavy and high at the shoulders and falls away to a low rump. The big
# head is carried low and forward under the hump, thick forelegs stand planted wide on clawed paws, a short snout grins (the mood's four teeth) between
# two curved magenta tusks, and two magenta spikes stand on each shoulder. A dark mane runs from the nape to the rump and the quills grow out of it as a
# crest of yellow lightning bolts that sweep back and lie flatter toward the tail, tallest over the shoulders. The tail is a raised bolt.
_TH_BACK = ((-2.3, 1.2, 0.98, 0.85), (-0.8, 1.9, 1.1, 1.0), (0.3, 1.55, 0.78, 0.7), (1.1, 1.2, 0.68, 0.6))  # the centre-line spheres of the trunk (y, z, y radius, z radius)


def _th_top(y):
    """The height of the back at y, from the trunk's spheres."""
    best = 0.0
    for cy, cz, ry, rz in _TH_BACK:
        if abs(y - cy) < ry:
            best = max(best, cz + rz * math.sqrt(1.0 - ((y - cy) / ry) ** 2))
    return best


_TH_QUILLS = []
for _y, _ln, _x in ((-2.25, 0.7, 0.0), (-1.75, 0.95, 0.0), (-1.3, 1.2, 0.0), (-0.9, 1.5, 0.0), (-0.5, 1.6, 0.0), (-0.1, 1.5, 0.0), (0.3, 1.35, 0.0), (0.7, 1.2, 0.0),
                    (1.1, 1.0, 0.0), (1.45, 0.8, 0.0), (-0.75, 1.05, 0.55), (-0.25, 1.2, 0.58), (0.25, 1.05, 0.52), (0.75, 0.9, 0.46)):
    _t = max(0.0, (_y + 1.3) / 2.8)  # 0 at the nape, 1 over the rump
    _TH_QUILLS += _zig("Accessory", (_x, _y, _th_top(_y) - (0.22 if _x else 0.12)), (0.0, 0.6 + 1.0 * _t, 1.0 - 0.65 * _t),
                       (_ln * 0.4, _ln * 0.34, _ln * 0.3), (0.25 if not _x else 0.2, 0.19, 0.12), 46.0, "quill", mirror=bool(_x))
_TH_PAWS = []
for _px, _py, _pz, _n in ((1.1, -1.75, 0.16, 3), (0.9, 1.5, 0.12, 3)):
    for _k in range(_n):
        _dx = (_k - (_n - 1) / 2.0) * 0.27
        _TH_PAWS.append(_blade("Trim", (_px + _dx, _py - 0.45, _pz + 0.02), (_dx * 0.3, -0.85, -0.3), 0.5, 0.09, 0.08, "claw", mirror=True, segments=5))
RECIPES["ThunderhogV2"] = {
    "tier": "Epic", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 3.37,
    "silhouette": "a low forward-leaning storm boar, a wedge heavy and high at the shoulders and falling away to a low rump: a big head carried low and forward with a short snout, two curved magenta tusks and a grin, thick forelegs on clawed paws, magenta shoulder spikes, a dark mane running back from the nape under a swept-back crest of glowing yellow lightning-bolt quills and a raised bolt tail",
    "hero": "the swept-back crest of lightning-bolt quills and the heavy forelegs",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.15, "eye_tilt": 18.0, "mouth": "zigzag", "lid": 0.32, "mouth_scale": 1.25, "eye_height": 0.62, "mouth_drop": 0.3},
    "palette": {"BodyDark": "5C2C70", "Accessory": "FFE23B"}, "glow": {"Accessory": 2.0},
    "steps": [
        sph("Body", (0.0, -0.8, 1.9), (1.15, 1.1, 1.0), segments=16, name="chest"),
        sph("Body", (0.9, -0.85, 2.05), (0.62, 0.7, 0.62), segments=12, mirror=True, name="shoulder"),
        sph("Body", (0.0, 0.3, 1.55), (0.78, 0.9, 0.7), segments=16, name="waist"),
        sph("Body", (0.0, 1.1, 1.2), (0.68, 0.8, 0.6), segments=14, name="rump"),
        sph("Body", (0.0, -2.3, 1.2), (0.98, 1.02, 0.85), segments=16, name="head"),
        sph("BodyDark", (0.0, -0.3, 2.25), (0.5, 2.1, 0.38), rot=(10, 0, 0), segments=14, name="mane"),
        rod("Body", (0.98, -0.95, 1.85), (1.15, -1.5, 0.3), 0.58, 0.36, segments=10, mirror=True, name="foreleg"),
        sph("BodyDark", (1.1, -1.75, 0.2), (0.52, 0.7, 0.22), segments=10, mirror=True, name="paw"),
        sph("Body", (0.62, 1.2, 1.15), (0.42, 0.66, 0.6), segments=12, mirror=True, name="haunch"),
        rod("Body", (0.76, 1.35, 1.0), (0.85, 1.7, 0.26), 0.3, 0.24, segments=8, mirror=True, name="hindleg"),
        sph("BodyDark", (0.88, 1.5, 0.14), (0.4, 0.58, 0.16), segments=10, mirror=True, name="hindpaw"),
        sweep("BodyDark", [(0.0, 1.6, 1.3), (0.0, 2.3, 1.55), (0.0, 2.85, 2.2), (0.0, 2.9, 3.0)], [0.32, 0.24, 0.17, 0.1], name="tail"),
        rod("Trim", (0.62, -2.85, 0.75), (0.85, -3.25, 1.1), 0.17, 0.15, segments=6, mirror=True, name="tusk"),
        spike("Trim", (0.85, -3.25, 1.1), (0.72, -3.35, 1.8), 0.15, segments=6, mirror=True, name="tusk"),
        spike("Trim", (1.0, -1.05, 2.4), (1.4, -0.65, 3.35), 0.2, segments=6, mirror=True, name="pauldron"),
        spike("Trim", (1.15, -0.55, 2.25), (1.7, -0.2, 2.9), 0.17, segments=6, mirror=True, name="pauldron"),
    ] + _zig("Accessory", (0.0, 2.9, 3.0), (0.0, -0.1, 1.0), (0.45, 0.38, 0.3), (0.13, 0.11, 0.08), 46.0, "quill") + _TH_QUILLS + _TH_PAWS,
}

# ---------------------------------------------------------------------------------------- Frostfang v2
# A sabre-tooth cat of the snowfield, not a round cub: shoulders high and heavy, the brisket hanging low between thick forelegs, a back that slopes
# to short hind legs, a big low head carrying two long icicle fangs over the open grin (the mood's four teeth between them), and a frost mane: a
# lion's ruff of ice spikes radiating round the neck, swept back and out in two rings, wider than the shoulders. Magenta metal claws on the big paws.
_FF_MANE = []
_FF_AXIS = (0.0, -1.0, 2.15)  # the neck: the mane's spikes radiate from a ring round this point, along the y axis
for _ring, (_y0, _r0, _ln, _tilt) in enumerate(((0.0, 0.62, 1.35, 0.55), (0.45, 0.75, 1.7, 0.8))):
    for _phi in (-35, -10, 15, 40, 65, 90):
        _a = math.radians(_phi)
        _out = (math.cos(_a), 0.0, math.sin(_a))
        _base = (_FF_AXIS[0] + _out[0] * _r0, _FF_AXIS[1] + _y0, _FF_AXIS[2] + _out[2] * _r0)
        _d = (_out[0] * 0.9, _tilt, _out[2] * 0.9 + 0.05)
        _FF_MANE.append(spike("Accessory", _base, _add(_base, _mul(_unit(_d), _ln * (1.0 - 0.1 * abs(_phi - 40) / 40.0))), 0.26 - 0.03 * _ring, segments=5, flat=True,
                              mirror=(_phi != 90), name="mane"))
_FF_CLAWS = []
for _px, _py, _pz in ((0.98, -1.6, 0.16), (0.88, 1.6, 0.12)):
    for _k in range(3):
        _dx = (_k - 1) * 0.27
        _FF_CLAWS.append(_blade("Trim", (_px + _dx, _py - 0.4, _pz + 0.02), (_dx * 0.3, -0.85, -0.3), 0.48, 0.09, 0.08, "claw", mirror=True, segments=5))
RECIPES["FrostfangV2"] = {
    "tier": "Epic", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 3.37,
    "silhouette": "a sabre-tooth cat standing on four legs, shoulders high and heavy, chest slung low between thick forelegs, a back sloping to short hind legs and a stub tail, a big low head with two long icicle fangs over a grin, and a wide frost mane of two rings of swept-back ice spikes round the neck",
    "hero": "the two long icicle fangs and the frost mane",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.12, "eye_tilt": 18.0, "mouth": "zigzag", "lid": 0.3, "mouth_scale": 1.2, "eye_height": 0.62, "mouth_drop": 0.3},
    "palette": {"BodyDark": "487797", "Accessory": "E8F7FF", "Mouth": "C94F3D"},
    "steps": [
        sph("Body", (0.0, -0.5, 2.35), (1.0, 1.05, 0.95), segments=16, name="withers"),
        sph("Body", (0.78, -0.55, 2.25), (0.55, 0.7, 0.75), segments=12, mirror=True, name="shoulder"),
        sph("Body", (0.0, -0.7, 1.7), (0.8, 0.9, 0.7), segments=14, name="brisket"),
        sph("Body", (0.0, 0.55, 2.0), (0.78, 0.9, 0.72), segments=16, name="waist"),
        sph("Body", (0.0, 1.4, 1.6), (0.7, 0.85, 0.66), segments=14, name="hips"),
        sph("Body", (0.6, 1.5, 1.3), (0.44, 0.64, 0.62), segments=12, mirror=True, name="haunch"),
        sph("Body", (0.0, -1.9, 1.85), (0.95, 0.9, 0.8), segments=16, name="head"),
        spike("Body", (0.58, -1.55, 2.5), (0.85, -1.4, 3.3), 0.3, segments=6, mirror=True, name="ear"),
        rod("Body", (0.88, -0.6, 2.15), (0.98, -1.25, 0.3), 0.5, 0.34, segments=10, mirror=True, name="foreleg"),
        sph("BodyDark", (0.98, -1.4, 0.18), (0.46, 0.64, 0.2), segments=10, mirror=True, name="paw"),
        rod("Body", (0.7, 1.45, 1.25), (0.8, 1.82, 0.28), 0.3, 0.24, segments=8, mirror=True, name="hindleg"),
        sph("BodyDark", (0.86, 1.62, 0.13), (0.4, 0.56, 0.15), segments=10, mirror=True, name="hindpaw"),
        sweep("BodyDark", [(0.0, 1.9, 1.7), (0.0, 2.6, 1.6), (0.0, 3.1, 2.0), (0.0, 3.2, 2.6)], [0.26, 0.2, 0.15, 0.12], name="tail"),
        spike("Accessory", (0.0, 3.2, 2.5), (0.0, 3.0, 3.3), 0.2, segments=5, flat=True, name="tailtuft"),
        spike("Accessory", (0.05, 3.25, 2.4), (0.0, 3.7, 3.0), 0.16, segments=5, flat=True, name="tailtuft"),
        spike("Accessory", (0.4, -2.57, 1.67), (0.5, -2.8, 0.05), 0.2, segments=6, mirror=True, name="fang"),
        sph("BodyDark", (0.74, 0.05, 2.0), (0.12, 0.13, 0.5), rot=(0, 0, 0), segments=8, mirror=True, name="stripe"),
        sph("BodyDark", (0.76, 0.55, 2.0), (0.12, 0.13, 0.5), segments=8, mirror=True, name="stripe"),
        sph("BodyDark", (0.72, 1.05, 1.95), (0.12, 0.13, 0.46), segments=8, mirror=True, name="stripe"),
    ] + _FF_MANE + _FF_CLAWS,
}

# ---------------------------------------------------------------------------------------- Skaddle v2
# A snow owl on ice skates (design fixes, docs/vault/06-art-pipelines/Design-Fixes.md): the glide, the blade-ring halo and the scarf of the first pass, on a body where the owl is back: a full
# feathered chest (a deep egg of a trunk leaning forward, scaled with three rows of pale feather points), a BROAD round owl head wider than it is tall with two swept
# ear tufts, thick feathered legs ending in boots on two gold skate blades (one leg bent under it, the other trailing far behind), and wing-arms with feathered mass
# in place of stick limbs: a tapering arm each, short white coverts shingled over a row of long ice-blue flight feathers that fan off it, one wing reaching forward
# and one swept back. The halo is a gold ring with fourteen ice blades standing behind the head (wide enough to clear it), and the long ice-blue scarf whips out
# behind in a wave.
_SK_HALO_C, _SK_HALO_TILT, _SK_HALO_R = (0.0, 0.4, 3.4), 12.0, 1.4  # a nimbus standing behind the head, tilted back by 12 degrees
_SK_RING_E2 = (0.0, math.sin(math.radians(_SK_HALO_TILT)), math.cos(math.radians(_SK_HALO_TILT)))  # the ring's second in-plane axis (the first is x)
_SK_BLADES = []
for _k in range(14):
    _th = math.radians(360.0 / 14.0 * _k + 12.0)
    _dir = (math.cos(_th), math.sin(_th) * _SK_RING_E2[1], math.sin(_th) * _SK_RING_E2[2])
    _b0 = _add(_SK_HALO_C, _mul(_dir, _SK_HALO_R * 0.92))
    _SK_BLADES.append(spike("Accessory", _b0, _add(_b0, _mul(_dir, 0.7 if _k % 2 else 0.5)), 0.16, segments=4, flat=True, name="halo"))


def _sk_wing(arm, braw, n=10):
    """A wing's feathers off its arm (a list of three points, shoulder, elbow, wrist): long ice-blue flight feathers fanned from the wrist (streaming out) to the
    elbow (hanging) in the plane of the arm and `braw` (the way the trailing edge points), white coverts shingled over every second root on the upper face."""
    a = _unit(_sub(arm[2], arm[0]))
    b = _unit(_sub(braw, _mul(a, sum(x * y for x, y in zip(a, braw)))))
    nrm = _unit(_cross(b, a))
    if nrm[2] < 0.0:
        nrm = _mul(nrm, -1.0)
    out = []
    for k in range(n):
        ph = 6.0 + 8.0 * k
        p, tn = crom(arm, 1.0 - 0.8 * (ph - 6.0) / 72.0)
        d = _add(_mul(a, math.cos(math.radians(ph))), _mul(b, math.sin(math.radians(ph))))
        ln = 2.0 - 0.013 * ph
        out.append(_blade("Accessory", _add(p, _mul(nrm, 0.015 * k)), d, ln, 0.07, 0.4, "feather", thin_axis=nrm, segments=5))
        if k % 2 == 0:
            out.append(_blade("BodyDark", _add(p, _mul(nrm, 0.14 + 0.015 * k)), d, 0.6 * ln, 0.07, 0.46, "covert", thin_axis=nrm, segments=5))
    return out


_SK_ARM_B = [(0.85, -0.05, 2.75), (1.6, 0.25, 3.0), (2.4, 0.75, 3.15)]       # the wing swept back (on +x)
_SK_ARM_F = [(-0.85, -0.15, 2.75), (-1.6, -0.45, 2.95), (-2.4, -0.9, 3.0)]   # the wing reaching forward (on -x)
_SK_ARM_R = [0.3, 0.22, 0.13]
_SK_FEATHERS = _sk_wing(_SK_ARM_B, (0.25, 0.3, -1.0)) + _sk_wing(_SK_ARM_F, (-0.05, 0.4, -1.0))
_SK_TORSO = ((0.0, -0.25, 2.15), (0.95, 0.8, 1.05), euler_matrix((15.0, 0.0, 0.0)))   # the trunk ellipsoid: centre, radii, rotation


def _sk_front(x, z):
    """The point and the outward normal where a ray along +y at (x, z) first meets the trunk ellipsoid (the front of the chest)."""
    c, s, R = _SK_TORSO
    Rt = tuple(tuple(R[j][i] for j in range(3)) for i in range(3))
    lo, hi = -3.0, c[1]
    for _ in range(40):  # bisect for the first crossing from outside (-y) to inside
        mid = 0.5 * (lo + hi)
        q = mv(Rt, (x - c[0], mid - c[1], z - c[2]))
        if sum((q[i] / s[i]) ** 2 for i in range(3)) > 1.0:
            lo = mid
        else:
            hi = mid
    q = mv(Rt, (x - c[0], hi - c[1], z - c[2]))
    n = mv(R, tuple(q[i] / s[i] ** 2 for i in range(3)))
    return (x, hi, z), _unit(n)


_SK_CHEST = []
for _z, _n, _ln in ((2.6, 4, 0.32), (2.25, 5, 0.32), (1.9, 4, 0.3)):  # barring on the chest: rows of pale feather points lying down the front, tips out
    for _i in range(_n):
        _x = (_i - (_n - 1) / 2.0) * 0.3
        _pt, _nm = _sk_front(_x, _z)
        _SK_CHEST.append(_blade("BodyDark", _add(_pt, _mul(_nm, -0.06)), _add((0.0, 0.0, -1.0), _mul(_nm, 0.55)), _ln, 0.07, 0.2, "chestfeather", thin_axis=_cross(_nm, (0.0, 0.0, 1.0)), segments=4))
_SK_SCARF = []  # the scarf's free end: leaves the knot at the neck, runs back and up, rippling as it goes
for _i in range(16):
    _u = _i / 15.0
    _SK_SCARF.append((0.05 * math.sin(6.0 * _u), -0.3 + 4.0 * _u, 2.5 + 0.85 * _u + 0.3 * math.sin(2.0 * math.pi * 1.6 * _u)))
RECIPES["SkaddleV2"] = {
    "tier": "Legendary", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 3.98,
    "silhouette": "a snow owl gliding on two gold ice skates, one leg bent under it and one trailing far behind, a full feathered chest leaning forward under a broad round head with swept-back ear tufts, thick feathered legs, one feathered wing reaching forward and one swept back, a blade-ring halo tilted behind the head and a long ice-blue scarf whipping out behind in a wave",
    "hero": "the blade-ring halo, the feathered wings, the whipping scarf and the skates",
    "face": {"on": "head", "eye_scale": 1.5, "eye_gap": 0.95, "eye_tilt": 18.0, "mouth": "smile", "lid": 0.3, "eye_height": 0.62, "mouth_drop": 0.28},
    "palette": {"BodyDark": "A9C5E0", "Accessory": "8FD8FF"},
    "ribbons": [{"slot": "Accessory", "name": "scarf", "pts": _SK_SCARF, "thick": 0.06, "widths": [0.3 - 0.12 * (_i / 15.0) ** 1.5 for _i in range(16)]}],
    "steps": [
        sph("Body", (0.0, 0.15, 1.5), (0.7, 0.7, 0.5), segments=14, name="hips"),
        sph("Body", (0.0, -0.25, 2.15), (0.95, 0.8, 1.05), rot=(15.0, 0.0, 0.0), segments=18, name="torso"),
        sph("Body", (0.0, -0.65, 3.15), (1.0, 0.78, 0.8), segments=18, name="head"),
        spike("BodyDark", (0.62, -0.55, 3.75), (1.15, 0.1, 4.55), 0.24, segments=5, mirror=True, name="tuft"),
        sweep("Body", [(-0.35, 0.0, 1.6), (-0.5, -0.45, 1.0), (-0.42, -0.3, 0.42)], [0.34, 0.26, 0.17], name="leg"),
        sph("BodyDark", (-0.4, -0.35, 0.3), (0.22, 0.4, 0.2), segments=10, name="boot"),
        cube("Trim", (-0.4, -0.35, 0.07), (0.05, 0.62, 0.04), name="skate"),
        rod("Trim", (-0.4, -0.95, 0.08), (-0.4, -1.1, 0.22), 0.045, 0.03, segments=4, name="skatetip"),
        sweep("Body", [(0.35, 0.15, 1.55), (0.6, 0.75, 1.0), (0.78, 1.3, 0.45)], [0.34, 0.26, 0.17], name="leg"),
        sph("BodyDark", (0.8, 1.35, 0.3), (0.22, 0.4, 0.2), rot=(0.0, 0.0, -12.0), segments=10, name="boot"),
        cube("Trim", (0.82, 1.4, 0.07), (0.05, 0.62, 0.04), rot=(0.0, 0.0, -12.0), name="skate"),
        rod("Trim", (0.7, 0.85, 0.08), (0.64, 0.72, 0.22), 0.045, 0.03, segments=4, name="skatetip"),
        sweep("Body", _SK_ARM_B, _SK_ARM_R, name="wing"),
        sweep("Body", _SK_ARM_F, _SK_ARM_R, name="wing"),
        sph("Accessory", (0.12, -0.45, 2.6), (0.24, 0.24, 0.24), segments=8, name="knot"),
        tor("Trim", _SK_HALO_C, (_SK_HALO_R,) * 3, rot=(90.0 - _SK_HALO_TILT, 0.0, 0.0), minor=0.07, segments=24, mseg=4, name="halo"),
    ] + _SK_BLADES + _SK_FEATHERS + _SK_CHEST,
}


# ---------------------------------------------------------------------------------------- Gloomoth v2
# A night moth of the cave, slender and elegant but with a bite (design fixes, docs/vault/06-art-pipelines/Design-Fixes.md): a BIG head so the face reads, with a heavier brow and
# two curved dark mandibles at the mouth, on a tall slim thorax in a fuzzy collar, a long tapering abdomen trailing behind with a few small jewels, standing on
# four thin legs. Four crystal wings held up and SWEPT BACK like a moth at rest (two big fore-wings, two smaller hind-wings), so from the side they are a roof of
# diagonal plates and not a sliver: each membrane is a faceted leaf 0.2 studs thick, and the glass panes laid on it are ribs 0.13 thick that reach past its
# rim in a row of crystal points. Two curving antennae with feathered plumes and a faceted jewel on its chest.
def _gm_dir(rise, sweep):
    """The direction of a wing's span: `rise` degrees above the horizontal, swept back (toward +y) by `sweep` degrees."""
    a, t = math.radians(rise), math.radians(sweep)
    return (math.cos(a) * math.cos(t), math.cos(a) * math.sin(t), math.sin(a))


_GM_SWEEP = (30.0, 24.0)   # fore-wing and hind-wing sweep
_GM_WINGS = [
    # the wing membranes: big faceted leaves in the dark body colour 0.2 thick, the fore-wings swept up, out and back, the hind-wings smaller and swept down and back
    ico("BodyDark", _add((0.3, 0.1, 1.65), _mul(_gm_dir(28.0, _GM_SWEEP[0]), 1.4)), (1.45, 0.1, 0.9), rot=(0.0, -28.0, _GM_SWEEP[0]), segments=2, flat=True, mirror=True, name="membrane"),
    ico("BodyDark", _add((0.3, 0.1, 1.2), _mul(_gm_dir(-30.0, _GM_SWEEP[1]), 0.95)), (0.95, 0.1, 0.6), rot=(0.0, 30.0, _GM_SWEEP[1]), segments=2, flat=True, mirror=True, name="membrane"),
]


def _gm_fan(shoulder, angles, lengths, wide, name, sweep):
    """The crystal ribs of a wing: slim glass panes fanned from the shoulder in the plane of the swept wing (angles in degrees above the horizontal, out to +x,
    swept back by `sweep`), mirrored, 0.13 thick, standing a little proud of the membrane and reaching past its rim so the edge is a row of crystal points."""
    out = []
    t = math.radians(sweep)
    n = (-math.sin(t), math.cos(t), 0.0)
    for a, ln in zip(angles, lengths):
        d = _add(_mul((math.cos(t), math.sin(t), 0.0), math.cos(math.radians(a))), (0.0, 0.0, math.sin(math.radians(a))))
        out.append(_blade("Accessory", _add(shoulder, _mul(n, -0.07)), d, ln, 0.065, wide, name, thin_axis=n, mirror=True, segments=4))
    return out


_GM_WINGS += _gm_fan((0.28, 0.1, 1.65), (82, 64, 46, 29, 13), (1.9, 2.5, 2.9, 2.75, 2.25), 0.24, "pane", _GM_SWEEP[0])
_GM_WINGS += _gm_fan((0.28, 0.1, 1.2), (-16, -34, -52, -70), (1.6, 1.7, 1.4, 1.1), 0.22, "pane", _GM_SWEEP[1])
_GM_ANT = [(0.25, -0.38, 2.5), (0.38, -0.42, 2.85), (0.68, -0.37, 3.2), (1.05, -0.17, 3.42)]
_GM_PLUMES = []
for _s in (1, -1):
    _ap = [(_s * q[0], q[1], q[2]) for q in _GM_ANT]
    for _u in (0.3, 0.5, 0.7, 0.9):
        _p, _tn = crom(_ap, _u)
        _GM_PLUMES.append(_blade("Accessory", _p, (_s * 0.2, 0.25, 0.85), 0.5 - 0.1 * _u, 0.04, 0.12, "plume", thin_axis=(0.0, 1.0, 0.0), segments=4))
        _GM_PLUMES.append(_blade("Accessory", _p, (_s * 0.95, 0.15, 0.1), 0.45 - 0.1 * _u, 0.04, 0.12, "plume", thin_axis=(0.0, 1.0, 0.0), segments=4))
RECIPES["GloomothV2"] = {
    "tier": "Epic", "world": 1, "biome": "Cave", "batch": 0, "status": "recipe", "prototype": True, "height": 2.64,
    "silhouette": "a night moth with a big head, a heavy brow and two curved mandibles, on a tall slim thorax and a long tapering abdomen, standing on four thin legs, four thick crystal wings held up and swept back like a moth at rest (two big fore-wings, two smaller hind-wings), two curving antennae with feathered plumes and a faceted jewel on its chest",
    "hero": "the four swept crystal wings, the jewel on its chest and the mandibles",
    "face": {"on": "head", "eye_scale": 1.25, "eye_gap": 1.05, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.4, "look": (0.0, 0.08), "eye_height": 0.62, "mouth_drop": 0.3},
    "palette": {"BodyDark": "6B447B", "Accessory": "5CF0D0"}, "glow": {"Accessory": 1.5},
    "steps": [
        sph("Body", (0.0, -0.35, 1.95), (0.74, 0.68, 0.68), segments=18, name="head"),
        sph("Body", (0.0, 0.05, 1.3), (0.42, 0.44, 0.72), segments=16, name="thorax"),
        sph("BodyDark", (0.0, -0.1, 1.55), (0.48, 0.44, 0.26), segments=10, name="ruff"),
        sph("BodyDark", (0.3, 0.0, 1.45), (0.25, 0.25, 0.22), segments=8, mirror=True, name="ruff"),
        sweep("Body", [(0.0, 0.3, 1.0), (0.0, 0.85, 0.75), (0.0, 1.35, 0.5), (0.0, 1.65, 0.3)], [0.28, 0.22, 0.16, 0.07], name="abdomen"),
        ico("Trim", (0.0, -0.42, 1.25), (0.2, 0.14, 0.26), segments=1, flat=True, name="jewel"),
        ico("Trim", (0.0, 0.62, 0.8), 0.1, segments=1, flat=True, name="jewel"),
        ico("Trim", (0.0, 1.0, 0.62), 0.09, segments=1, flat=True, name="jewel"),
        spike("Trim", (0.5, -0.75, 1.8), (0.42, -1.25, 1.25), 0.13, segments=5, mirror=True, name="mandible"),
        rod("BodyDark", (0.25, 0.1, 0.8), (0.45, 0.2, 0.4), 0.09, 0.07, segments=6, mirror=True, name="leg"),
        rod("BodyDark", (0.45, 0.2, 0.4), (0.55, 0.05, 0.03), 0.07, 0.06, segments=6, mirror=True, name="leg"),
        rod("BodyDark", (0.25, -0.1, 0.8), (0.45, -0.4, 0.4), 0.09, 0.07, segments=6, mirror=True, name="leg"),
        rod("BodyDark", (0.45, -0.4, 0.4), (0.5, -0.55, 0.03), 0.07, 0.06, segments=6, mirror=True, name="leg"),
        sph("BodyDark", (0.55, 0.03, 0.05), (0.14, 0.2, 0.05), segments=6, mirror=True, name="foot"),
        sph("BodyDark", (0.5, -0.57, 0.05), (0.14, 0.2, 0.05), segments=6, mirror=True, name="foot"),
        sweep("BodyDark", _GM_ANT, [0.07, 0.06, 0.05, 0.04], name="antenna"),
        sweep("BodyDark", [(-q[0], q[1], q[2]) for q in _GM_ANT], [0.07, 0.06, 0.05, 0.04], name="antenna"),
    ] + _GM_WINGS + _GM_PLUMES,
}


# ---------------------------------------------------------------------------------------- Shimmerlynx v2
# A lynx stalking, not a lynx posing (design fixes, docs/vault/06-art-pipelines/Design-Fixes.md): all four paws planted, the head carried low and forward on a thick neck, the shoulders (a
# withers ridge over a deep chest) high and the hips raised over great folded haunches, the belly tucked, the elbows back and the hocks bent: a trunk that is a deep
# chest running into a tucked waist and a heavy rump, not three balls in a line. Tall black-tufted ears, a full magenta cheek ruff, a bobbed tail with a dark tip and
# a snarl: a heavier brow over the narrowed eye and two short fangs over the grin. The aurora crest is a CROWN: a fan of nine glowing glass blades standing behind
# the head from a crown gem and swept back (a fan from the front, a row of swept blades from the side), with two glass ribbons flowing back over the spine from it.
_SL_AURORA = []
for _sg in (-1.0, 1.0):
    _pts = []
    for _i in range(18):
        _u = _i / 17.0
        _pts.append((_sg * (0.15 + 0.85 * _u ** 1.4), -1.55 + 4.4 * _u, 3.2 + 0.75 * math.sin(math.pi * min(1.0, _u * 1.15)) + 0.3 * math.sin(2.0 * math.pi * (1.5 * _u + (0.0 if _sg < 0 else 0.4))) - 0.6 * _u ** 2))
    _SL_AURORA.append({"slot": "Accessory", "name": "aurora", "pts": _pts, "thick": 0.06, "widths": [0.15 + 0.28 * math.sin(math.pi * (_i + 1.5) / 20.0) ** 0.7 for _i in range(18)]})
_SL_GEM = (0.0, -1.7, 3.15)
_SL_CROWN = []
for _al in (-72.0, -54.0, -36.0, -18.0, 0.0, 18.0, 36.0, 54.0, 72.0):
    _d = _unit((math.sin(math.radians(_al)), 0.42 * math.cos(math.radians(_al)), math.cos(math.radians(_al))))
    _SL_CROWN.append(_blade("Accessory", _SL_GEM, _d, 1.9 * math.cos(math.radians(_al) * 0.6), 0.07, 0.24, "crown", thin_axis=_cross(_d, (1.0, 0.0, 0.0)), segments=4))
RECIPES["ShimmerlynxV2"] = {
    "tier": "Epic", "world": 2, "biome": "IceCave", "batch": 0, "status": "recipe", "prototype": True, "height": 3.82,
    "silhouette": "a lynx stalking with all four paws planted, the head low and forward on a thick neck, high shoulders over a deep chest, raised hips over folded haunches, tall black-tufted ears, a full magenta cheek ruff, a snarl of two short fangs under a heavy brow, and an aurora crown: a fan of nine glowing glass blades standing behind the head and swept back, with two glass ribbons flowing back over the spine",
    "hero": "the aurora crown fan behind the head and the stalking stance",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.1, "eye_tilt": 7.0, "mouth": "smile", "lid": 0.4, "mouth_scale": 0.85, "eye_height": 0.62, "mouth_drop": 0.3},
    "palette": {"BodyDark": "827E9C", "Accessory": "5CF0D0"}, "glow": {"Accessory": 1.5},
    "ribbons": _SL_AURORA,
    "steps": [
        sph("Body", (0.0, -0.7, 2.0), (0.74, 1.0, 0.88), segments=18, name="chest"),
        sph("Body", (0.0, -0.5, 2.4), (0.64, 0.75, 0.58), segments=14, name="withers"),
        sph("Body", (0.0, 0.55, 1.8), (0.56, 0.9, 0.58), segments=16, name="waist"),
        sph("Body", (0.0, 1.55, 2.05), (0.68, 0.76, 0.72), segments=16, name="hips"),
        sph("Body", (0.5, 1.65, 1.6), (0.4, 0.68, 0.68), segments=12, mirror=True, name="haunch"),
        rod("Body", (0.0, -1.2, 2.35), (0.0, -1.75, 2.4), 0.52, 0.48, segments=10, name="neck"),
        sph("Body", (0.0, -2.05, 2.35), (0.88, 0.76, 0.72), segments=16, name="head"),
        spike("Body", (0.5, -1.95, 2.75), (0.68, -1.85, 3.95), 0.3, segments=6, mirror=True, name="ear"),
        spike("BodyDark", (0.67, -1.85, 3.8), (0.72, -1.8, 4.45), 0.12, segments=5, mirror=True, name="eartuft"),
        _blade("Trim", (0.62, -2.0, 2.5), (1.0, 0.2, -0.1), 1.0, 0.07, 0.22, "cheek", thin_axis=(0.0, 0.0, 1.0), mirror=True),
        _blade("Trim", (0.58, -1.95, 2.3), (0.9, 0.35, -0.5), 0.9, 0.07, 0.2, "cheek", thin_axis=(0.0, 0.0, 1.0), mirror=True),
        _blade("Trim", (0.5, -1.9, 2.1), (0.6, 0.35, -0.9), 0.8, 0.07, 0.18, "cheek", thin_axis=(0.0, 0.0, 1.0), mirror=True),
        spike("EyeWhite", (0.26, -2.68, 2.2), (0.28, -2.8, 1.65), 0.13, segments=5, mirror=True, name="fang"),
        sph("BodyDark", (0.58, -1.2, 0.12), (0.3, 0.46, 0.13), segments=10, mirror=True, name="paw"),
        sph("BodyDark", (0.6, 1.4, 0.12), (0.3, 0.46, 0.13), segments=10, mirror=True, name="hindpaw"),
        sweep("Body", [(0.0, 2.25, 2.15), (0.0, 2.75, 2.0), (0.0, 3.2, 1.8)], [0.3, 0.24, 0.17], name="tail"),
        sph("BodyDark", (0.0, 3.35, 1.75), (0.22, 0.22, 0.22), segments=8, name="tailtip"),
        ico("Accessory", _SL_GEM, (0.15, 0.12, 0.22), segments=1, flat=True, name="crowngem"),
    ] + _msweep("Body", [(0.5, -0.75, 1.9), (0.6, -0.35, 1.15), (0.58, -0.95, 0.5), (0.56, -1.1, 0.2)], [0.34, 0.27, 0.22, 0.2], "foreleg")
      + _msweep("Body", [(0.6, 1.6, 1.7), (0.72, 1.05, 0.95), (0.64, 1.8, 0.55), (0.6, 1.5, 0.2)], [0.42, 0.32, 0.25, 0.2], "hindleg") + _SL_CROWN,
}


# ---------------------------------------------------------------------------------------- Reindazzle v2
# A stately reindeer of the snowfield with a body that holds up its crown (design fixes, docs/vault/06-art-pipelines/Design-Fixes.md): a deep broad chest with a withers hump and a thick shaggy
# throat ruff, a tucked waist and heavy haunches on four long slim legs, a long neck and a bigger head under a heavier brow with the big glowing nose at the front of the
# face, and a wide crown of icicle antlers whose tines CURVE: from each side a main beam sweeps out, back and up in an S, a hooked brow tine curls forward and up, and
# three tines rise from the beam leaning out and curling in at their tips, every one a tapering tube of ice that grows out of the skull as one skin. A tuft of a tail behind.
_RZ_BEAM = [(0.3, -1.55, 3.3), (0.85, -1.7, 3.8), (1.5, -1.55, 4.15), (2.1, -1.2, 4.35), (2.7, -0.85, 4.7)]
_RZ_BEAM_R = [0.17, 0.15, 0.12, 0.09, 0.05]
_RZ_ANTLERS = _msweep("BodyDark", _RZ_BEAM, _RZ_BEAM_R, "antler")
_RZ_ANTLERS += _msweep("BodyDark", [(0.42, -1.62, 3.4), (0.5, -2.0, 3.45), (0.58, -2.35, 3.8), (0.5, -2.55, 4.3), (0.38, -2.6, 4.65)], [0.12, 0.1, 0.08, 0.055, 0.03], "antler")  # the brow tine: forward, then hooked up
for _u, _rise, _lean in ((0.3, 1.1, 0.26), (0.58, 1.3, 0.3), (0.86, 1.1, 0.26)):  # three tines rise from the beam, leaning out and curling in at the tip
    _p, _tn = crom(_RZ_BEAM, _u)
    _RZ_ANTLERS += _msweep("BodyDark", [_p, _add(_p, (0.1 * _lean / 0.3, 0.0, 0.3 * _rise)), _add(_p, (_lean, 0.04, 0.62 * _rise)), _add(_p, (_lean - 0.1, 0.08, 0.92 * _rise)),
                                         _add(_p, (_lean - 0.26, 0.1, 1.12 * _rise))], [0.11, 0.095, 0.075, 0.05, 0.03], "antler")
RECIPES["ReindazzleV2"] = {
    "tier": "Rare", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 3.65,
    "silhouette": "a stately reindeer standing proud on four long slim legs, a deep broad chest with a withers hump and a shaggy throat ruff, a long neck and a high head under a heavy brow with a big glowing nose at the front of the face, and a very wide crown of icicle antlers with curved tines: a main beam sweeping out and back in an S with a hooked brow tine forward and three tines rising from it, leaning out and curling in at their tips",
    "hero": "the wide crown of curving icicle antlers and the glowing nose",
    "face": {"on": "head", "eye_scale": 1.7, "eye_gap": 1.15, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.45, "eye_height": 0.7, "mouth_drop": 0.54},
    "palette": {"BodyDark": "8795AD", "Accessory": "FF6B4A"}, "glow": {"Accessory": 2.0}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0.0, -0.45, 1.8), (0.74, 0.95, 0.82), segments=18, name="chest"),
        sph("Body", (0.0, -0.2, 2.3), (0.55, 0.65, 0.5), segments=12, name="withers"),
        sph("Body", (0.0, 0.7, 1.7), (0.55, 0.8, 0.58), segments=14, name="waist"),
        sph("Body", (0.0, 1.5, 1.75), (0.62, 0.68, 0.64), segments=14, name="hips"),
        sph("Body", (0.46, 1.55, 1.4), (0.32, 0.55, 0.58), segments=10, mirror=True, name="haunch"),
        rod("Body", (0.0, -0.85, 2.05), (0.0, -1.35, 2.7), 0.44, 0.34, segments=10, name="neck"),
        sph("Body", (0.0, -1.65, 2.9), (0.68, 0.7, 0.64), segments=16, name="head"),
        sph("Accessory", (0.0, -2.33, 2.86), 0.2, segments=12, name="nose"),
        sph("Body", (0.0, -1.05, 1.95), (0.55, 0.6, 0.7), segments=12, name="ruff"),
        sph("Body", (0.72, -1.55, 3.15), (0.32, 0.1, 0.15), rot=(0, 0, 22), segments=8, mirror=True, name="ear"),
        rod("Body", (0.38, -0.6, 1.5), (0.42, -0.75, 0.22), 0.22, 0.12, segments=8, mirror=True, name="foreleg"),
        sph("BodyDark", (0.42, -0.8, 0.1), (0.14, 0.2, 0.1), segments=8, mirror=True, name="hoof"),
        rod("Body", (0.4, 1.5, 1.4), (0.46, 1.9, 0.8), 0.22, 0.15, segments=8, mirror=True, name="thigh"),
        rod("Body", (0.46, 1.9, 0.8), (0.45, 1.72, 0.15), 0.15, 0.11, segments=8, mirror=True, name="hindleg"),
        sph("BodyDark", (0.45, 1.75, 0.1), (0.14, 0.2, 0.1), segments=8, mirror=True, name="hoof"),
        sph("Body", (0.0, 2.2, 1.9), 0.24, segments=8, name="tail"),
    ] + _RZ_ANTLERS,
}


# ---------------------------------------------------------------------------------------- Rocklobber v2
# A cave crab built to fight, not a crab with one fist: a wide low red body with a scowl and a grin of four teeth, a faceted stone shell over its back
# crowned with three amber crystals, six jointed legs planted wide (three a side, knees up, feet out), and two boulder claws held HIGH over its head
# on thick bent arms, each a faceted fist with a smaller stone for the pincer's other jaw and a cluster of glowing amber crystals on its knuckles.
_RL_CLAWS = []
for _c in ((1.8, -0.55, 2.5, 1.85, -0.6, 3.2), (2.15, -0.5, 2.35, 2.55, -0.5, 2.95), (1.45, -0.5, 2.45, 1.3, -0.45, 3.05)):
    _RL_CLAWS.append(spike("Accessory", (_c[0], _c[1], _c[2]), (_c[3], _c[4], _c[5]), 0.24, segments=5, flat=True, mirror=True, name="crystal"))
_RL_LEGS = []
for _y, _kz in ((-0.55, 1.45), (0.25, 1.55), (0.95, 1.45)):  # the legs: out from the body's edge, a high knee, then down and out to the foot
    _RL_LEGS.append(rod("Body", (0.85, _y, 1.0), (1.65, _y * 1.2, _kz), 0.19, 0.15, segments=6, mirror=True, name="leg"))
    _RL_LEGS.append(rod("Body", (1.65, _y * 1.2, _kz), (2.25, _y * 1.45, 0.08), 0.15, 0.1, segments=6, mirror=True, name="leg"))
    _RL_LEGS.append(sph("BodyDark", (2.3, _y * 1.45, 0.07), (0.15, 0.17, 0.07), segments=6, mirror=True, name="foot"))
RECIPES["RocklobberV2"] = {
    "tier": "Rare", "world": 1, "biome": "Cave", "batch": 0, "status": "recipe", "prototype": True, "height": 2.42,
    "silhouette": "a wide low cave crab with a faceted stone shell crowned with amber crystals, six jointed legs planted wide with their knees up, and two boulder claws held high over its head on thick bent arms, each a faceted fist with a smaller stone for the other jaw and a cluster of amber crystals on its knuckles",
    "hero": "the two boulder claws raised high with their amber crystals and the faceted stone shell",
    "face": {"on": "body", "eye_scale": 1.4, "eye_gap": 1.25, "eye_tilt": 18.0, "mouth": "zigzag", "lid": 0.3, "mouth_scale": 1.35, "eye_height": 0.66, "mouth_drop": 0.3},
    "palette": {"BodyDark": "8A857D", "Accessory": "FFA928"}, "glow": {"Accessory": 1.5}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0.0, 0.0, 1.0), (1.15, 0.95, 0.6), segments=16, name="body"),
        ico("BodyDark", (0.0, 0.4, 1.4), (1.05, 0.85, 0.55), rot=(-8.0, 0.0, 0.0), segments=2, flat=True, name="shell"),
        spike("Accessory", (0.0, 0.3, 1.8), (0.0, 0.3, 2.45), 0.26, segments=5, flat=True, name="crystal"),
        spike("Accessory", (0.45, 0.65, 1.7), (0.7, 0.75, 2.2), 0.2, segments=5, flat=True, mirror=True, name="crystal"),
        rod("Body", (0.9, -0.3, 1.1), (1.45, -0.5, 1.5), 0.32, 0.28, segments=8, mirror=True, name="arm"),
        rod("Body", (1.45, -0.5, 1.5), (1.75, -0.55, 1.95), 0.28, 0.26, segments=8, mirror=True, name="arm"),
        ico("BodyDark", (1.8, -0.55, 2.0), (0.78, 0.72, 0.66), rot=(8.0, 0.0, 22.0), segments=2, flat=True, mirror=True, name="fist"),
        ico("BodyDark", (1.4, -1.1, 2.35), (0.42, 0.38, 0.36), rot=(0.0, 0.0, 30.0), segments=2, flat=True, mirror=True, name="thumb"),
    ] + _RL_LEGS + _RL_CLAWS,
}

# ---------------------------------------------------------------------------------------- Gaiabloom v2
# A tall proud stag of the meadow, not a short deer with a ring: long slim legs (one forefoot lifted in a stately step), a deep chest thrust forward under a
# shaggy bark-brown ruff, a long swan neck curving up to a head held high, a gold nimbus ring behind the head and a TREE for antlers, each a trunk of
# bark with brow tine, side branches and an inner branch growing out of the skull as one skin, every branch tip in pink bloom. It stands on a patch of
# lawn (a thin green disc its hooves grow out of) ringed with pink flowers, so it carries its own ground.
_GB_ANTLER = [
    ((0.22, -1.25, 4.0), (0.5, -1.2, 4.4), (0.85, -1.1, 4.85), (1.05, -1.0, 5.35)), (0.17, 0.14, 0.105, 0.06),   # the trunk
    ((0.5, -1.2, 4.4), (1.0, -1.15, 4.5), (1.5, -1.1, 4.8)), (0.12, 0.095, 0.055),                               # the lower side branch
    ((0.85, -1.1, 4.85), (1.35, -1.05, 5.05), (1.8, -1.0, 5.45)), (0.11, 0.085, 0.05),                            # the upper side branch
    ((0.3, -1.25, 4.1), (0.4, -1.65, 4.4), (0.45, -1.95, 4.8)), (0.11, 0.085, 0.05),                              # the brow tine, forward
    ((1.0, -1.05, 5.2), (0.6, -1.05, 5.55), (0.3, -1.05, 5.9)), (0.1, 0.08, 0.05),                             # the inner branch, curling toward the centre
]
_GB_ANTLERS = []
for _i in range(0, len(_GB_ANTLER), 2):
    _GB_ANTLERS += _msweep("BodyDark", list(_GB_ANTLER[_i]), list(_GB_ANTLER[_i + 1]), "antler")
_GB_BLOOMS = [ico("Accessory", p, 0.2, segments=1, flat=True, mirror=True, name="blossom")
              for p in ((1.05, -1.0, 5.4), (1.5, -1.1, 4.85), (1.82, -1.0, 5.5), (0.45, -1.95, 4.85), (0.3, -1.05, 5.95))]
_GB_FLOWERS = []
for _k in range(12):  # a ring of flowers round the lawn's rim
    _a = math.radians(30.0 * _k + 10.0)
    _GB_FLOWERS.append(ico("Accessory", (1.65 * math.cos(_a), 0.45 + 2.1 * math.sin(_a), 0.2), 0.17, segments=1, flat=True, name="flower"))
RECIPES["GaiabloomV2"] = {
    "tier": "Legendary", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 4.14,
    "silhouette": "a tall proud stag on long slim legs with one forefoot lifted, a deep chest under a shaggy ruff, a long swan neck and a high head with a gold nimbus ring behind it, antlers that are a tree (a trunk with a brow tine, two side branches and an inner branch, every tip in pink bloom), standing on a thin patch of lawn ringed with pink flowers",
    "hero": "the tree antlers in bloom, the gold nimbus and the ring of flowers on its lawn",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.0, "eye_tilt": 14.0, "mouth": "wide", "lid": 0.3, "eye_height": 0.66, "mouth_drop": 0.24},
    "palette": {"BodyDark": "8A5A2F", "Accessory": "FF8FB3"},
    "steps": [
        sph("Body", (0.0, -0.3, 1.95), (0.55, 0.7, 0.6), segments=16, name="chest"),
        sph("Body", (0.0, 0.55, 1.9), (0.5, 0.68, 0.5), segments=14, name="waist"),
        sph("Body", (0.0, 1.25, 1.9), (0.5, 0.55, 0.5), segments=14, name="hips"),
        sph("BodyDark", (0.0, -0.8, 2.35), (0.42, 0.34, 0.55), segments=10, name="ruff"),
        sweep("Body", [(0.0, -0.7, 2.2), (0.0, -1.1, 2.7), (0.0, -1.2, 3.15), (0.0, -1.15, 3.5)], [0.36, 0.3, 0.27, 0.25], name="neck"),
        sph("Body", (0.0, -1.3, 3.75), (0.64, 0.66, 0.56), segments=16, name="head"),
        sph("Body", (0.6, -1.2, 3.95), (0.34, 0.1, 0.17), rot=(0, 0, 28), segments=8, mirror=True, name="ear"),
        sph("Body", (0.4, 1.3, 1.7), (0.3, 0.46, 0.46), segments=10, mirror=True, name="haunch"),
        rod("Body", (0.34, 1.25, 1.75), (0.42, 1.55, 0.95), 0.27, 0.17, segments=8, mirror=True, name="thigh"),
        rod("Body", (0.42, 1.55, 0.95), (0.42, 1.4, 0.14), 0.17, 0.13, segments=8, mirror=True, name="hindleg"),
        sph("BodyDark", (0.42, 1.42, 0.12), (0.18, 0.25, 0.12), segments=8, mirror=True, name="hoof"),
        rod("Body", (0.33, -0.35, 1.8), (0.38, -0.45, 0.95), 0.22, 0.15, segments=8, name="foreleg"),
        rod("Body", (0.38, -0.45, 0.95), (0.4, -0.55, 0.14), 0.15, 0.13, segments=8, name="foreleg"),
        sph("BodyDark", (0.4, -0.58, 0.12), (0.18, 0.25, 0.12), segments=8, name="hoof"),
        rod("Body", (-0.33, -0.35, 1.8), (-0.4, -0.95, 1.5), 0.22, 0.15, segments=8, name="foreleg"),
        rod("Body", (-0.4, -0.95, 1.5), (-0.4, -1.0, 0.8), 0.15, 0.13, segments=8, name="foreleg"),
        sph("BodyDark", (-0.4, -1.05, 0.78), (0.18, 0.25, 0.12), segments=8, name="hoof"),
        tor("Trim", (0.0, -0.85, 3.9), (1.05, 1.05, 1.05), rot=(90.0, 0.0, 0.0), minor=0.07, segments=24, mseg=4, name="halo"),
        sph("Body", (0.0, 0.45, 0.07), (1.75, 2.2, 0.07), segments=18, name="lawn"),
    ] + _GB_ANTLERS + _GB_BLOOMS + _GB_FLOWERS,
}

# ==== DESIGN PASS 2 END ====


# ==== DESIGN PASS 3 BEGIN (prototypes, not shipped species: docs/vault/06-art-pipelines/Design-Pass.md "Batch 3"; written 2026-10-16) ====
# The per-species design pass, batch 3: the top of the ladder (Raddis the Cosmic and Syrinx the Secret, the two grandest bodies so far), the cool Rares
# (Zirrit, Vixa), the Rare joke Floe, and the three cute ones that stood in the worst overlap pairs (Pebblet, Snibble, Eekle). Each `<Id>V2` is a
# `"prototype": True` recipe that keeps its species' height, slots, palette and glow and gives it a new body. Built with `species_sculpt.py --method
# hybrid` on a scratch copy of the species' folder renamed `<Id>V2`, with `--set face.mood=<mood>` where the species is not cute (the V2 keys are not
# in the sculpt's SPECIES table); the exact command lines are in Design-Pass.md. Facing -Y, feet on z 0, as everywhere in this file. Helpers from the
# hero and the earlier batches (_blade, _leaf, _basis, _msweep, crom) are reused; no helper is new. Part names are the effect's hooks: `disk`, `ray`,
# `reed`, `antennatip`, `bristles`, `crystal`, `shell`, `icicle`, `membrane` are what the import step splits out (the tests list them).


# ---------------------------------------------------------------------------------------- Raddis v2 (Radish)
# The winged sun, rebuilt so the sun shows (design fixes, docs/vault/06-art-pipelines/Design-Fixes.md): a fat orange radish hovering in front of a BIG gold sun
# disc that stands high behind it (a shallow dish tilted back, wider than the bulb by half again, ringed by long broad rays all the way round the top and
# the sides), so from the front the sun is a circle with a corona and not a burst behind the head. The wings are no longer green fronds on a tube: each is a
# fan of long gold ray feathers growing out of the radish's shoulder and swept back (the longest in the middle of the fan), the short orange covert blades
# of the radish's own colour laid over their roots, so the gold wing never melts into the gold disc. A plume of five broad green leaves on its head over a
# gold diadem, a gold collar, a grinning face under a brow, and a taproot that hangs under the bulb and curls round on the ground like a tail with a gold tip.
# The disc, the rays and the feathers are the glowing Accessory (`disk` and `ray` are split out for the effect: the disc spins and the rays sweep; the
# crown leaves are `leaf`).
_RD_DISC = (0.0, 1.7, 3.6)
_RD_DISC_R = 2.35
_RD_NORMAL = _unit((0.0, -1.0, 0.22))      # the disc faces the viewer and leans back, its top further from the camera
_RD_UP = _unit(_sub((0.0, 0.0, 1.0), _mul(_RD_NORMAL, _RD_NORMAL[2])))   # up in the plane of the disc
_RD_RAYS = []
for _k in range(17):  # a corona of broad rays round the disc, long and short in turn, none at the bottom where the taproot hangs
    _a = math.radians(-30.0 + 12.5 * _k)
    _d = _add(_mul((1.0, 0.0, 0.0), math.cos(_a)), _mul(_RD_UP, math.sin(_a)))
    _long = _k % 2 == 0
    _RD_RAYS.append(_blade("Accessory", _add(_RD_DISC, _mul(_d, _RD_DISC_R - 0.12)), _d, 1.05 if _long else 0.65, 0.09, 0.32 if _long else 0.25, "ray", thin_axis=_RD_NORMAL))
_RD_ARM = [(1.3, 0.3, 2.2), (2.1, 0.4, 3.1), (3.0, 0.45, 3.9), (3.9, 0.45, 4.4)]   # the wing's leading edge: up and out from the shoulder, the wrist high
_RD_ARM_R = [0.36, 0.3, 0.22, 0.1]
_RD_WING = []
for _k in range(14):  # flight feathers fan off the arm, turning from hanging at the shoulder to pointing up and out at the wrist, growing longer, broad enough to overlap; a broad orange covert over the roots of every second one
    _u = 0.08 + 0.92 * _k / 13.0
    _p, _tn = crom(_RD_ARM, _u)
    _e = math.radians(-72.0 + 104.0 * _u ** 1.2)
    _d = _unit((math.cos(_e), 0.25, math.sin(_e)))
    _ln = 1.5 + 1.35 * _u ** 1.2
    _RD_WING.append(_blade("Accessory", (_p[0], _p[1] + 0.12 + 0.02 * _k, _p[2] - 0.1), _d, _ln, 0.075, 0.46, "ray", thin_axis=(0.0, 1.0, 0.0), mirror=True, segments=5))
    if _k % 2 == 0:
        _RD_WING.append(_blade("Body", (_p[0], _p[1] - 0.12, _p[2] - 0.05), _d, 0.62 * _ln, 0.075, 0.5, "covert", thin_axis=(0.0, 1.0, 0.0), mirror=True, segments=5))
_RD_CROWN = []
for _az, _ln, _w in ((-56.0, 1.4, 0.22), (-28.0, 1.95, 0.26), (0.0, 2.4, 0.28), (28.0, 1.95, 0.26), (56.0, 1.4, 0.22)):
    _s, _c = math.sin(math.radians(_az)), math.cos(math.radians(_az))
    _RD_CROWN.append(_leaf("BodyDark", (_s * 0.7, -0.05, 2.95 + 0.1 * _c), (_s * 0.8, 0.1, _c), _ln, _w, 0.09, "leaf", thin_axis=(0.0, 1.0, 0.0), segments=8))


RECIPES["RadishV2"] = {
    "tier": "Cosmic", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 3.64,
    "silhouette": "the winged sun: a fat orange radish hovering in front of a huge gold sun disc that stands high behind it ringed all round by long rays, two great wings of long gold ray feathers fanned out and swept back from its shoulders over short orange coverts, a plume of five broad leaves on its head and a taproot curling on the ground like a tail",
    "hero": "the huge gold sun disc with its corona of rays behind the head, and the two fans of gold ray feathers",
    "face": {"on": "body", "eye_scale": 1.5, "eye_gap": 1.0, "eye_tilt": 14.0, "mouth": "wide", "lid": 0.3, "look": (0.0, 0.1), "eye_height": 0.7, "mouth_drop": 0.24},
    "palette": {"BodyDark": "5DBB3A", "Accessory": "FFC83D"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0.0, -0.05, 2.15), (1.55, 1.4, 1.3), segments=22, name="body"),
        sph("Body", (0.0, 0.1, 1.35), (0.95, 0.85, 0.65), segments=14, name="belly"),
        sweep("Body", [(0.0, 0.15, 1.0), (0.0, 0.25, 0.6), (0.3, 0.6, 0.38), (0.9, 0.85, 0.27), (1.5, 0.45, 0.2), (1.5, -0.2, 0.15), (1.05, -0.6, 0.11), (0.6, -0.6, 0.08)],
              [0.36, 0.3, 0.25, 0.2, 0.16, 0.13, 0.09, 0.06], name="taproot"),
        spike("Accessory", (0.62, -0.6, 0.1), (0.2, -0.5, 0.18), 0.1, segments=6, name="tailtip"),
        tor("Accessory", (0.0, -0.02, 1.55), (1.43, 1.29, 1.43), minor=0.1, segments=20, mseg=4, name="collar"),
        cone("Accessory", _add(_RD_DISC, (0.0, -0.05, 0.0)), (_RD_DISC_R, _RD_DISC_R, 0.35), rot=aim(_RD_NORMAL), tip=0.62, segments=32, name="disk"),
        tor("Accessory", (0.0, -0.05, 2.95), (1.28, 1.15, 1.28), minor=0.12, segments=20, mseg=4, name="diadem"),
    ] + _msweep("Body", _RD_ARM, _RD_ARM_R, "arm") + _RD_RAYS + _RD_WING + _RD_CROWN,
}


# ---------------------------------------------------------------------------------------- Syrinx v2 (Panpipe)
# The satyr: a black goat standing up on goat legs (one S-curved tube each, hip to hoof, a cream cloven hoof and a cream hock tuft), a lean torso leaning
# forward under a big head with a pointed cream beard, long flat ears, and the grandest horns of the roster: two cream arcs that sweep up, round and down far
# wider than the body. Behind the head a raft of nine glowing cyan reeds fans out of a bone hub, graded in length like a real panpipe and dished back at the
# sides so it is a bowl and not a wall, bound by a bone ring (the Accessory: `reed` is split out for the notes). One arm raised, one low, both in a cyan
# cuff; a cyan gem between the horns.
_PP_HUB = (0.0, 0.8, 2.75)
_PP_REEDS = []
for _i in range(9):
    _t = math.radians(-80.0 + 20.0 * _i)
    _d = _unit((math.sin(_t), 0.18 + 0.5 * (1.0 - math.cos(_t)), math.cos(_t)))
    _ln = 1.25 + 0.04 * _i + 0.2 * math.cos(_t)
    _PP_REEDS.append(rod("Accessory", _add(_PP_HUB, _mul(_d, 0.5)), _add(_PP_HUB, _mul(_d, _ln)), 0.14, segments=8, name="reed"))
_PP_HORN = ((0.45, -0.5, 3.15), (0.9, -0.4, 3.6), (1.45, -0.1, 3.75), (1.9, 0.2, 3.35), (1.95, 0.4, 2.8), (1.6, 0.35, 2.5))
_PP_HORN_R = (0.26, 0.24, 0.2, 0.15, 0.1, 0.05)


def _pp_arm(pts, radii, hand, claw_dir):
    out = [sweep("Body", list(pts), list(radii), "arm"), sph("Body", hand, 0.27, segments=12, name="hand")]
    d = _unit(_sub(pts[-1], pts[-2]))
    out.append(cyl("Accessory", _add(pts[-1], _mul(d, -0.1)), (0.25, 0.25, 0.09), rot=aim(d), segments=8, name="cuff"))
    for dx in (-0.14, 0.0, 0.14):
        base = (hand[0] + dx, hand[1] - 0.2, hand[2] + claw_dir[2] * 0.15)
        out.append(spike("BodyDark", base, (base[0] + dx * 0.5, base[1] - 0.25, base[2] + claw_dir[2] * 0.3), 0.06, segments=5, name="claw"))
    return out


RECIPES["PanpipeV2"] = {
    "tier": "Secret", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 3.40,
    "silhouette": "a black satyr goat standing up on S-curved goat legs with cream hooves and hock tufts, leaning forward under a big head with a pointed cream beard, vast cream horns sweeping up and round far wider than the body, one arm raised, and a bowl of nine glowing cyan reeds fanned out behind the head, graded in length like a panpipe",
    "hero": "the sweeping horns and the fan of nine graded reeds",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.1, "eye_tilt": 14.0, "mouth": "wide", "lid": 0.38, "mouth_scale": 0.9, "eye_height": 0.6, "mouth_drop": 0.3},
    "palette": {"BodyDark": "E9DDBA", "Accessory": "4FD8FF", "Mouth": "7A1F3D"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0.0, 0.2, 1.55), (0.62, 0.52, 0.4), segments=14, name="hips"),
        sph("Body", (0.0, 0.05, 1.9), (0.52, 0.48, 0.42), segments=14, name="belly"),
        sph("Body", (0.0, -0.2, 2.35), (0.85, 0.68, 0.62), segments=16, name="chest"),
        sph("Body", (0.72, -0.1, 2.45), 0.36, segments=12, mirror=True, name="shoulder"),
        sph("Body", (0.0, -0.5, 2.9), (0.88, 0.84, 0.86), segments=18, name="head"),
        _leaf("Body", (0.78, -0.45, 3.0), (1.0, 0.15, -0.3), 1.05, 0.3, 0.13, "ear", thin_axis=(0.0, 1.0, 0.3), mirror=True, segments=10),
        sweep("BodyDark", [(0.0, -1.1, 2.45), (0.0, -1.3, 2.0), (0.0, -1.2, 1.55)], [0.24, 0.16, 0.04], name="beard"),
        sweep("Body", [(0.0, 0.55, 1.55), (0.0, 0.95, 1.7), (0.0, 1.2, 2.0)], [0.2, 0.12, 0.05], name="tail"),
        cyl("BodyDark", _PP_HUB, (0.34, 0.34, 0.12), rot=(90.0, 0.0, 0.0), segments=14, name="hub"),
        tor("BodyDark", _PP_HUB, (1.1, 1.1, 1.1), rot=(90.0, 0.0, 0.0), minor=0.08, segments=20, mseg=4, name="band"),
        ico("Accessory", (0.0, -1.1, 3.55), (0.12, 0.1, 0.22), segments=1, flat=True, name="gem"),
        _blade("BodyDark", (0.5, 0.38, 0.8), (0.15, 1.0, -0.3), 0.55, 0.06, 0.15, "tuft", thin_axis=(1.0, 0.0, 0.0), mirror=True),
    ] + _msweep("Body", [(0.42, 0.2, 1.55), (0.52, -0.35, 1.05), (0.46, 0.3, 0.62), (0.43, -0.05, 0.3), (0.42, -0.12, 0.16)], [0.36, 0.27, 0.19, 0.13, 0.12], "leg")
      + [sph("BodyDark", (0.42, -0.2, 0.1), (0.18, 0.28, 0.1), segments=10, mirror=True, name="hoof")]
      + _msweep("BodyDark", list(_PP_HORN), list(_PP_HORN_R), "horn")
      + _pp_arm(((0.78, -0.1, 2.25), (1.2, -0.1, 1.85), (1.45, -0.45, 1.5)), (0.2, 0.16, 0.14), (1.5, -0.5, 1.42), (0, 0, -1.0))
      + _pp_arm(((-0.78, -0.1, 2.3), (-1.25, -0.25, 2.7), (-1.45, -0.55, 3.1)), (0.2, 0.16, 0.14), (-1.48, -0.6, 3.25), (0, 0, 1.0))
      + _PP_REEDS,
}


# ---------------------------------------------------------------------------------------- Zirrit v2 (Zapfinch)
# A sharp little shrike, rebuilt as one bird (design fixes, docs/vault/06-art-pipelines/Design-Fixes.md): a deep keeled chest under a big head, a belly and a rump that
# run into one teardrop body, and a tail that tapers from the rump to a point of three long streamers, standing tall on two thin legs and leaning forward. A
# dark eye mask, a bigger hooked dark beak (a hook on its tip) between a narrowed eye and a smirk. The wings are shaped: a tapering arm from the shoulder (the
# shoulder swells out of the chest) to a wrist held up and back, flight feathers fanned off it in a row that turns from hanging at the elbow to streaming out
# at the wrist (long pointed primaries with gaps between their tips, shorter secondaries inboard), and sky-blue shingled coverts over their roots, so the wing is
# a tilted layered plate and not a paddle. Two long whip antennae curve up and out of the head, each ending in a glowing yellow tip (the Accessory: a spark
# jumps between the two `antennatip` parts; the `covert` and `feather` parts flick for the wings).
_ZF_ARM = [(0.72, -0.05, 1.9), (1.3, 0.4, 2.25), (1.8, 1.0, 2.45)]   # the wing's arm: shoulder, elbow, wrist (held up and back)
_ZF_ARM_R = [0.27, 0.2, 0.12]
_ZF_A = _unit(_sub(_ZF_ARM[2], _ZF_ARM[0]))
_ZF_B = _unit(_sub((0.5, 0.3, -1.0), _mul(_ZF_A, sum(a * b for a, b in zip(_ZF_A, (0.5, 0.3, -1.0))))))   # across the wing, toward the trailing edge (down, a little out)
_ZF_N = _unit(_cross(_ZF_B, _ZF_A))   # the wing's upper face
_ZF_WING = []
for _k in range(12):  # the flight feathers: from the wrist (long primaries streaming out) to the elbow (short secondaries hanging down)
    _ph = 4.0 + 7.0 * _k
    _u = 1.0 - 0.8 * (_ph - 4.0) / 77.0
    _p, _tn = crom(_ZF_ARM, _u)
    _d = _add(_mul(_ZF_A, math.cos(math.radians(_ph))), _mul(_ZF_B, math.sin(math.radians(_ph))))
    _ln = 2.0 - 0.0115 * _ph
    _ZF_WING.append(_blade("BodyDark", _add(_p, _mul(_ZF_N, 0.015 * _k)), _d, _ln, 0.08, 0.26, "feather", thin_axis=_ZF_N, mirror=True, segments=5))
    if _k % 2 == 1:  # sky-blue coverts shingled over the roots of the feathers, on the upper face
        _ZF_WING.append(_blade("Body", _add(_p, _mul(_ZF_N, 0.15 + 0.02 * _k)), _d, 0.6 * _ln, 0.075, 0.32, "covert", thin_axis=_ZF_N, mirror=True, segments=5))
RECIPES["ZapfinchV2"] = {
    "tier": "Rare", "world": 1, "biome": "Forest", "batch": 0, "status": "recipe", "prototype": True, "height": 2.86,
    "silhouette": "a sharp little shrike made of one body: a deep chest under a big head running into a teardrop belly and a tail that tapers to three long streamers, standing tall and leaning forward on two thin legs, a hooked dark beak, wings held up and back (a tapering arm with long pointed primaries fanned off it and shingled coverts), and two long whip antennae curving up and out with glowing tips",
    "hero": "the two whip antennae with their glowing tips, the feathered wings held up and back and the long tapering tail",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.0, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.3, "mouth_scale": 0.9, "eye_height": 0.62, "mouth_drop": 0.32, "look": (0.1, 0.0)},
    "palette": {"BodyDark": "2F5F8F", "Accessory": "FFE45C"}, "glow": {"Accessory": 1.5}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0.0, -0.1, 1.55), (0.86, 0.82, 0.95), segments=18, name="chest"),
        sph("Body", (0.0, 0.45, 1.3), (0.74, 0.8, 0.72), segments=16, name="belly"),
        sph("Body", (0.0, 1.05, 1.15), (0.5, 0.62, 0.45), segments=14, name="rump"),
        sph("Body", (0.0, -0.5, 2.3), (0.88, 0.82, 0.82), segments=18, name="head"),
        sweep("Body", [(0.0, 1.2, 1.1), (0.0, 1.95, 0.95), (0.0, 2.65, 0.8), (0.0, 3.25, 0.7)], [0.36, 0.28, 0.2, 0.1], name="tail"),
        spike("BodyDark", (0.0, -1.25, 2.2), (0.0, -1.95, 2.0), 0.19, segments=5, name="beak"),
        spike("BodyDark", (0.0, -1.85, 2.02), (0.0, -1.9, 1.62), 0.1, segments=5, name="beak"),
        sph("BodyDark", (0.42, -0.3, 0.07), (0.22, 0.42, 0.07), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (0.0, -1.05, 2.42), (0.82, 0.26, 0.3), segments=14, name="mask"),
    ] + _msweep("BodyDark", [(0.38, 0.25, 0.95), (0.42, 0.0, 0.5), (0.42, -0.1, 0.12)], [0.15, 0.11, 0.09], "leg") + _msweep("Body", _ZF_ARM, _ZF_ARM_R, "wingarm") + _ZF_WING
      + [_blade("BodyDark", (0.1, 3.2, 0.72), (0.3, 1.0, -0.22), 1.55, 0.08, 0.24, "tailfeather", thin_axis=(0.0, 0.0, 1.0), mirror=True),
         _blade("BodyDark", (0.0, 3.25, 0.74), (0.0, 1.0, -0.12), 1.9, 0.08, 0.26, "tailfeather", thin_axis=(0.0, 0.0, 1.0))]
      + _msweep("BodyDark", [(0.3, -0.45, 2.9), (0.58, -0.4, 3.3), (0.55, -0.43, 3.7), (0.34, -0.5, 3.98)], [0.1, 0.085, 0.075, 0.06], "antenna")
      + [sph("Accessory", (0.32, -0.5, 4.1), 0.18, segments=8, mirror=True, name="antennatip")],
}


# ---------------------------------------------------------------------------------------- Vixa v2 (Sparkfox)
# A sly standing fox, not a sitting cub: a compact lean body on four slim legs with one front paw raised, a big head carried low and forward under two tall
# ears and swept cheek tufts, and the paintbrush: a long tail that arches up behind it and out to the right like a swan's neck, ending in a rust ferrule ring
# and a big glowing brush hanging point down toward the ground, with a drop about to fall (the Accessory: `bristles` and `drop` are split out for the
# paint-spark trail and the falling drop).
_VX_TAIL = [(0.0, 1.1, 1.3), (0.3, 1.7, 1.9), (0.95, 2.1, 2.3), (1.6, 1.95, 2.25), (1.95, 1.65, 1.95)]
_VX_TAIL_R = [0.34, 0.3, 0.26, 0.22, 0.18]
_VX_D = _unit((0.2, -0.25, -0.95))   # the brush's axis, hanging down
_VX_F = (1.98, 1.6, 1.87)            # the ferrule
RECIPES["SparkfoxV2"] = {
    "tier": "Rare", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 2.50,
    "silhouette": "a sly standing fox, compact and lean on four slim legs with one front paw raised, a big low head under two tall ears and swept cheek tufts, and a long tail arching up behind and out to the right like a swan's neck to a ferrule ring and a big glowing paintbrush hanging point down with a drop about to fall",
    "hero": "the paintbrush tail: a swan-neck arch ending in a ferrule and a glowing brush that drips",
    "face": {"on": "head", "eye_scale": 1.25, "eye_gap": 1.1, "eye_tilt": 6.0, "mouth": "smile", "lid": 0.3, "eye_height": 0.62, "mouth_drop": 0.3, "look": (0.12, 0.0)},
    "palette": {"BodyDark": "A8431C", "Accessory": "FFE066"}, "glow": {"Accessory": 2.0}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0.0, -0.45, 1.3), (0.7, 0.72, 0.7), segments=16, name="chest"),
        sph("Body", (0.0, 0.25, 1.25), (0.5, 0.6, 0.55), segments=14, name="waist"),
        sph("Body", (0.0, 0.8, 1.25), (0.54, 0.55, 0.58), segments=14, name="hips"),
        sph("Body", (0.0, -1.3, 1.8), (0.86, 0.78, 0.76), segments=18, name="head"),
        spike("Body", (0.45, -1.15, 2.35), (0.7, -1.05, 3.2), 0.34, segments=6, mirror=True, name="ear"),
        spike("BodyDark", (0.47, -1.3, 2.45), (0.64, -1.23, 3.05), 0.19, segments=6, mirror=True, name="innerear"),
        spike("BodyDark", (0.72, -1.2, 1.75), (1.3, -0.9, 1.6), 0.22, segments=6, mirror=True, name="cheek"),
        sweep("Body", _VX_TAIL, _VX_TAIL_R, name="tail"),
        tor("BodyDark", _VX_F, (0.3, 0.3, 0.3), rot=aim(_VX_D), minor=0.34, segments=14, mseg=4, name="ferrule"),
        sph("Accessory", _add(_VX_F, _mul(_VX_D, 0.55)), (0.42, 0.42, 0.7), rot=aim(_VX_D), segments=12, name="bristles"),
        spike("Accessory", _add(_VX_F, _mul(_VX_D, 1.0)), _add(_VX_F, _mul(_VX_D, 1.5)), 0.28, segments=8, name="bristletip"),
        sph("Accessory", _add(_VX_F, _mul(_VX_D, 1.78)), (0.1, 0.1, 0.14), segments=8, name="drop"),
        sph("BodyDark", (-0.4, -0.95, 0.09), (0.2, 0.32, 0.09), segments=8, name="paw"),
        sph("BodyDark", (0.45, 1.15, 0.09), (0.22, 0.36, 0.09), segments=8, mirror=True, name="hindpaw"),
        sph("BodyDark", (0.52, -1.3, 1.35), (0.2, 0.3, 0.19), segments=8, name="raisedpaw"),
    ] + [sweep("Body", [(-0.38, -0.6, 1.0), (-0.4, -0.8, 0.5), (-0.4, -0.88, 0.1)], [0.22, 0.15, 0.12], "foreleg"),
         sweep("Body", [(0.38, -0.6, 1.0), (0.5, -1.0, 0.95), (0.52, -1.25, 1.3)], [0.21, 0.15, 0.13], "foreleg")]
      + _msweep("Body", [(0.42, 0.85, 1.1), (0.58, 1.25, 0.75), (0.45, 1.15, 0.15)], [0.32, 0.22, 0.13], "hindleg"),
}


# ---------------------------------------------------------------------------------------- Floe v2 (Shellberg)
# The joke, built: a stout tortoise on four stubby legs lugging a whole iceberg on its back, the tip of it: a faceted ice shell of two stacked blocks under a
# tilted spire, crowned with glowing pale crystals, and a coral lifebuoy round its waist as the waterline (nine-tenths of the berg is hidden). Under it a
# patient round face on a short neck, big sleepy eyes and a small smile, and a stubby tail. The shell, the spire and the crystals are the faceted crisp
# parts (`shell`, `peak`), the crystals the glowing Accessory (`crystal`), the lifebuoy `buoy` (a coral ring).
RECIPES["ShellbergV2"] = {
    "tier": "Rare", "world": 2, "biome": "IceCave", "batch": 0, "status": "recipe", "prototype": True, "height": 2.76,
    "silhouette": "a stout tortoise on four stubby legs lugging a whole iceberg: two stacked faceted ice blocks under a tilted spire crowned with glowing crystals, a coral lifebuoy round its waist as the waterline, and a patient round face on a short neck",
    "hero": "the iceberg shell with its spire and glowing crystals, and the lifebuoy waterline",
    "face": {"on": "head", "eye_scale": 1.4, "eye_gap": 1.0, "eye_tilt": -8.0, "mouth": "smile", "lid": 0.35, "eye_height": 0.58},
    "palette": {"BodyDark": "E8785A", "Accessory": "CFF1FF"}, "glow": {"Accessory": 1.2}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0.0, 0.2, 0.62), (1.1, 1.2, 0.55), segments=16, name="body"),
        ico("Body", (0.0, 0.35, 1.05), (1.3, 1.4, 0.7), rot=(4.0, 0.0, 6.0), segments=2, flat=True, name="shell"),
        ico("Body", (0.25, 0.45, 1.55), (0.95, 1.0, 0.6), rot=(0.0, 0.0, 25.0), segments=2, flat=True, name="shell"),
        cone("Body", (0.35, 0.55, 2.35), (0.78, 0.55, 1.0), rot=(-14.0, 10.0, 18.0), segments=6, flat=True, name="peak"),
        cone("Body", (-0.75, 0.2, 1.95), (0.5, 0.42, 0.75), rot=(10.0, -12.0, -20.0), segments=6, flat=True, name="peak"),
        cone("Body", (0.95, 1.05, 1.7), (0.42, 0.38, 0.55), rot=(-18.0, 14.0, 25.0), segments=6, flat=True, name="peak"),
        ico("Body", (-0.7, 0.9, 1.35), (0.5, 0.5, 0.44), rot=(10.0, 0.0, -15.0), segments=1, flat=True, name="shell"),
        spike("Accessory", (-0.2, -0.05, 2.05), (-0.35, -0.12, 2.6), 0.17, segments=5, flat=True, name="crystal"),
        spike("Accessory", (0.9, 0.5, 1.85), (1.25, 0.5, 2.5), 0.22, segments=5, flat=True, name="crystal"),
        spike("Accessory", (0.6, 0.55, 3.0), (0.75, 0.6, 3.5), 0.16, segments=5, flat=True, name="crystal"),
        spike("Accessory", (-0.3, 1.2, 1.9), (-0.4, 1.3, 2.4), 0.16, segments=5, flat=True, name="crystal"),
        tor("BodyDark", (0.0, 0.3, 0.95), (1.45, 1.55, 1.45), minor=0.14, segments=18, mseg=5, name="buoy"),
        sph("Body", (0.0, -1.5, 0.72), (0.66, 0.66, 0.6), segments=16, name="head"),
        rod("Body", (0.0, -0.9, 0.6), (0.0, -1.35, 0.7), 0.42, 0.36, segments=10, name="neck"),
        rod("Body", (0.78, -0.65, 0.5), (0.85, -0.72, 0.12), 0.32, 0.26, segments=10, mirror=True, name="foreleg"),
        rod("Body", (0.82, 0.95, 0.5), (0.9, 1.0, 0.12), 0.32, 0.26, segments=10, mirror=True, name="hindleg"),
        sph("BodyDark", (0.88, -0.85, 0.08), (0.3, 0.4, 0.1), segments=8, mirror=True, name="foot"),
        sph("BodyDark", (0.92, 0.9, 0.08), (0.3, 0.4, 0.1), segments=8, mirror=True, name="foot"),
        sweep("Body", [(0.0, 1.4, 0.55), (0.0, 1.8, 0.5), (0.0, 2.1, 0.62)], [0.3, 0.2, 0.08], name="tail"),
    ],
}


# ---------------------------------------------------------------------------------------- Snibble v2 (Snailbyte)
# A real snail with a real spiral: a long flat foot with a steel-blue sole, a neck and a big round head raised on it with two eyestalks tipped with silver
# balls, and on its back the metal shell: a coil of 40 balls on a spiral that grows from a small boss to a fat last whorl, the whorls banded silver and
# steel in pairs like a wound spring, the axis turned out and to the front so the spiral faces the viewer at three-quarters. The balls are core parts (one skin
# with the body; the build names its crisp parts, so the silver ones are not crisp): `shell` is split out for the glint that sweeps it.
_SN_C = (0.05, 0.95, 1.5)
_SN_A = _unit((0.5, -0.85, 0.15))
_SN_U = _unit(_cross((0.0, 0.0, 1.0), _SN_A))
_SN_V = _cross(_SN_A, _SN_U)
_SN_SHELL = []
for _i in range(40):
    _s = _i / 39.0
    _th = 2.0 * math.pi * 2.25 * _s
    _r = 0.1 + 1.05 * _s
    _rho = 0.15 + 0.17 * _s
    _a = 0.5 * (1.0 - _s)
    _p = _add(_add(_SN_C, _mul(_SN_A, _a)), _add(_mul(_SN_U, _r * math.cos(_th)), _mul(_SN_V, _r * math.sin(_th))))
    _SN_SHELL.append(sph("Accessory" if (_i // 2) % 2 == 0 else "BodyDark", _p, _rho, segments=10, name="shell"))
RECIPES["SnailbyteV2"] = {
    "tier": "Uncommon", "world": 1, "biome": "Cave", "batch": 0, "status": "recipe", "prototype": True, "height": 2.51,
    "silhouette": "a snail with a real spiral shell: a long flat foot, a big round head raised on a neck with two eyestalks tipped with silver balls, and on its back a coiled metal shell of banded silver and steel whorls growing from a small boss to a fat last whorl, turned out so the spiral faces the viewer",
    "hero": "the spiral metal shell: banded silver and steel whorls growing round from the boss",
    "face": {"on": "head", "eye_scale": 1.25, "eye_gap": 1.05, "eye_tilt": 4.0, "mouth": "smile", "lid": 0.3},
    "palette": {"BodyDark": "4F7390", "Accessory": "C8CDD3"}, "metal": {"Accessory": 1.0},
    "steps": [
        sph("Body", (0.0, 0.3, 0.36), (0.8, 1.75, 0.36), segments=14, name="foot"),
        sph("BodyDark", (0.0, 0.3, 0.14), (0.9, 1.82, 0.16), segments=12, name="sole"),
        sph("Body", (0.0, -0.85, 0.95), (0.62, 0.62, 0.7), segments=12, name="neck"),
        sph("Body", (0.0, -1.15, 1.6), (0.92, 0.86, 0.84), segments=18, name="head"),
        rod("BodyDark", (0.38, -1.2, 2.25), (0.55, -1.3, 2.75), 0.1, 0.07, segments=6, mirror=True, name="stalk"),
        sph("Accessory", (0.56, -1.31, 2.82), 0.17, segments=8, mirror=True, name="stalktip"),
    ] + _SN_SHELL,
}


# ---------------------------------------------------------------------------------------- Pebblet v2 (Pebblet)
# A pebble with legs, mid-stride: a wide lopsided faceted boulder (a flat-shaded stone with three smaller lumps on it) on two short thick legs with big
# flat feet, one lifted in a goofy step, two stubby arms with stone-chip fists (one up in a wave), a green moss toupee on top, and the face on the front facet.
# The feet are the `foot` parts for the grit puff; the moss the only Accessory.
RECIPES["PebbletV2"] = {
    "tier": "Common", "world": 1, "biome": "Cave", "batch": 0, "status": "recipe", "prototype": True, "height": 2.37,
    "silhouette": "a wide lopsided faceted boulder mid-stride on two short thick legs with big flat feet, one lifted, two stubby arms with stone fists (one waving), three lumps on its back and a green moss toupee on top",
    "hero": "the short thick legs in mid-stride under a wide faceted stone",
    "face": {"on": "body", "eye_scale": 1.15, "eye_gap": 0.9, "eye_tilt": -8.0, "mouth": "wide", "lid": 0.3, "lift": 0.05, "look": (0.12, 0.0)},
    "palette": {"BodyDark": "6B6760", "Accessory": "78C850"},
    "steps": [
        ico("Body", (0.0, 0.05, 1.75), (1.3, 1.1, 1.0), rot=(4.0, 6.0, 8.0), segments=2, flat=True, name="body"),
        ico("Body", (-0.9, 0.6, 2.3), (0.42, 0.4, 0.38), segments=1, flat=True, name="bump"),
        ico("Body", (0.95, 0.5, 1.3), (0.4, 0.38, 0.36), segments=1, flat=True, name="bump"),
        ico("Body", (0.4, 0.95, 2.2), (0.36, 0.34, 0.34), segments=1, flat=True, name="bump"),
        rod("Body", (0.55, 0.1, 1.15), (0.6, 0.0, 0.2), 0.36, 0.27, segments=8, name="leg"),
        sph("BodyDark", (0.62, -0.2, 0.1), (0.46, 0.62, 0.12), segments=10, name="foot"),
        rod("Body", (-0.55, 0.0, 1.15), (-0.72, -0.75, 0.6), 0.36, 0.27, segments=8, name="leg"),
        sph("BodyDark", (-0.74, -0.85, 0.5), (0.44, 0.58, 0.15), rot=(-15.0, 0.0, 0.0), segments=10, name="foot"),
        rod("Body", (1.1, -0.05, 1.8), (1.55, -0.25, 1.35), 0.24, 0.18, segments=8, name="arm"),
        ico("BodyDark", (1.65, -0.3, 1.2), (0.36, 0.34, 0.34), segments=1, flat=True, name="fist"),
        rod("Body", (-1.1, -0.05, 1.8), (-1.55, -0.25, 2.35), 0.24, 0.18, segments=8, name="arm"),
        ico("BodyDark", (-1.63, -0.3, 2.5), (0.36, 0.34, 0.34), segments=1, flat=True, name="fist"),
        sph("Accessory", (0.1, 0.05, 2.7), (0.75, 0.62, 0.2), segments=10, name="moss"),
        sph("Accessory", (-0.5, 0.2, 2.58), (0.36, 0.32, 0.15), segments=8, name="moss"),
        sph("Accessory", (0.55, -0.1, 2.6), (0.34, 0.3, 0.14), segments=8, name="moss"),
    ],
}


# ---------------------------------------------------------------------------------------- Eekle v2 (Flapsicle)
# A bat hanging by two tiny pink toes from nothing, head down and face up the right way, its wings spread and drooped round it like a cape: each wing an arm
# (an indigo core tube, shoulder, elbow, wrist) from whose wrist five icicle fingers fan down to the ground, four flat triangles of pale ice stretched between
# them (the apex at the wrist, the base along the fringe) so the lower edge is a bat's scallop of points; two big pink ears flaring up and out, a fuzzy round
# body and a big round head. The fingers and membranes are the Accessory (`icicle` and `membrane`, split out for the flap and the frost dust).
_EK_W = (1.6, 0.06, 1.4)
_EK_T = ((0.72, 0.12, 0.2), (1.0, 0.1, 0.12), (1.35, 0.09, 0.1), (1.75, 0.08, 0.14), (2.1, 0.08, 0.36))
_EK_WING = [spike("Accessory", _EK_W, _t, 0.12, segments=5, flat=True, mirror=True, name="icicle") for _t in _EK_T]
for _k in range(4):
    _m = _mul(_add(_EK_T[_k], _EK_T[_k + 1]), 0.5)
    _d = _sub(_EK_W, _m)
    _EK_WING.append(_blade("Accessory", _m, _d, _len(_d), 0.06, _len(_sub(_EK_T[_k + 1], _EK_T[_k])) * 0.5 + 0.04, "membrane", thin_axis=(0.0, 1.0, 0.0), mirror=True))
RECIPES["FlapsicleV2"] = {
    "tier": "Uncommon", "world": 2, "biome": "IceCave", "batch": 0, "status": "recipe", "prototype": True, "height": 1.76,
    "silhouette": "a fuzzy bat hanging by two tiny pink toes from nothing, wings spread wide and drooped: an arm and five icicle fingers a side fanning from the wrist to the ground with four triangles of pale ice between them and a scalloped edge, two big pink ears flaring up and out of a big round head at the bottom",
    "hero": "the spread ice wings: icicle fingers with membranes between them",
    "face": {"on": "head", "eye_scale": 1.25, "eye_gap": 1.0, "eye_tilt": -6.0, "mouth": "smile", "lid": 0.3},
    "palette": {"BodyDark": "F28DA6", "Accessory": "9FE3FF"},
    "steps": [
        sph("Body", (0.0, 0.1, 1.15), (0.64, 0.6, 0.52), segments=14, name="body"),
        sph("Body", (0.0, -0.15, 0.58), (0.64, 0.6, 0.58), segments=16, name="head"),
        _leaf("BodyDark", (0.5, -0.1, 0.8), (0.6, 0.0, 0.8), 1.1, 0.38, 0.1, "ear", thin_axis=(0.0, 1.0, 0.0), mirror=True, segments=8),
        rod("BodyDark", (0.14, 0.1, 1.45), (0.16, 0.1, 1.74), 0.11, 0.08, segments=6, mirror=True, name="toe"),
        spike("BodyDark", (0.16, 0.1, 1.74), (0.2, 0.0, 1.88), 0.07, segments=5, mirror=True, name="claw"),
    ] + _msweep("Body", [(0.5, 0.15, 1.4), (1.05, 0.1, 1.68), _EK_W], [0.22, 0.16, 0.1], "arm") + _EK_WING,
}

# ==== DESIGN PASS 3 END ====


# ==== DESIGN PASS 4 BEGIN (prototypes, not shipped species: docs/vault/06-art-pipelines/Design-Pass.md "Batch 4"; written 2026-10-16) ====
# The per-species design pass, batch 4: the last seven species, all Common or Uncommon, the cute end of the ladder: Buzzik (Buzzlebee), Lantrin (Lanternewt),
# Twiglo (Twiglet) in World 1 and Soakum (Toastoad), Sizz (Emberchin), Flurra (Snowbun), Digling (Chipmole) in World 2. Each `<Id>V2` is a `"prototype": True`
# recipe that keeps its species' height, slots, palette and glow and gives it a body of its own: cute and goofy, big eyes, never a ball with one prop. Built with
# `species_sculpt.py --method hybrid` on a scratch copy of the species' folder renamed `<Id>V2` (all seven are the cute face: no mood flag); the exact command lines
# are in Design-Pass.md. Facing -Y, feet on z 0, as everywhere in this file. Helpers from the hero and the earlier batches (_blade, _leaf, _msweep, _chain) are
# reused; no helper is new. Part names are the effect's hooks (the tests list them): `wing`, `leaf`, `lantern`, `pebble`, `ember`, `tail`, `claw`.


# ---------------------------------------------------------------------------------------- Twiglo v2 (Twiglet)
# A stick bug on its hind legs: a big round head on a thin knobbly twig of a body (three dark nodes on the trunk) that drags a long abdomen behind it, curling
# up at the tip, two grasshopper legs with high knees, one arm waving and one hanging, two curling antennae, a pair of buds sprouting on its back and a leaf hat
# of three leaves in a pinwheel (the brim droops to the left, another leaf lifts to the right, a third stands up in the middle). The thin chains are core
# (the build lists only the leaves and buds as crisp), so the legs, arms and antennae grow out of the skin as smooth tubes.
RECIPES["TwigletV2"] = {
    "tier": "Common", "world": 1, "biome": "Forest", "batch": 0, "status": "recipe", "prototype": True, "height": 2.71,
    "silhouette": "a stick bug standing on two high-kneed twig legs with a big round head on a thin knobbly body, a long abdomen trailing behind, one arm waving, curling antennae and a pinwheel hat of three green leaves",
    "hero": "the leaf hat: three leaves in a pinwheel on a head too big for the twig body",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.05, "eye_tilt": 0.0, "mouth": "wide", "look": (-0.1, -0.05), "cross": 0.1},
    "palette": {"BodyDark": "5C3A1C", "Accessory": "6FBF3F"},
    "steps": [
        sph("Body", (0.0, -0.1, 2.3), (0.62, 0.57, 0.55), segments=18, name="head"),
        sph("Body", (0.0, 0.25, 0.95), (0.3, 0.28, 0.26), segments=10, name="hips"),
        sweep("Body", [(0.0, 0.25, 0.95), (0.0, 0.15, 1.4), (0.0, 0.05, 1.85)], [0.24, 0.2, 0.2], "body"),
        sweep("Body", [(0.0, 0.28, 0.95), (0.0, 0.8, 0.72), (0.05, 1.3, 0.62), (0.2, 1.7, 0.78), (0.4, 1.95, 1.05)], [0.22, 0.19, 0.15, 0.1, 0.05], "abdomen"),
        sph("BodyDark", (0.0, 0.17, 1.2), (0.3, 0.28, 0.07), segments=10, name="node"),
        sph("BodyDark", (0.0, 0.1, 1.52), (0.28, 0.26, 0.07), segments=10, name="node"),
        sph("BodyDark", (0.0, 0.05, 1.82), (0.27, 0.25, 0.07), segments=10, name="node"),
    ] + _msweep("BodyDark", [(0.15, 0.25, 0.95), (0.8, 0.3, 1.35), (1.05, 0.25, 0.7), (1.1, 0.2, 0.1)], [0.2, 0.15, 0.12, 0.09], "leg") + [
        sph("BodyDark", (0.8, 0.3, 1.35), 0.17, segments=8, mirror=True, name="knee"),
        sph("BodyDark", (1.11, 0.1, 0.07), (0.24, 0.38, 0.07), segments=8, mirror=True, name="foot"),
        sweep("BodyDark", [(0.2, -0.05, 1.75), (0.75, -0.2, 1.8), (1.1, -0.3, 2.15), (1.25, -0.3, 2.5)], [0.13, 0.11, 0.09, 0.07], "arm"),
        sph("BodyDark", (1.27, -0.3, 2.6), 0.12, segments=8, name="hand"),
        sweep("BodyDark", [(-0.2, -0.05, 1.75), (-0.85, -0.1, 1.6), (-1.2, -0.2, 1.3), (-1.25, -0.25, 0.95)], [0.13, 0.11, 0.09, 0.07], "arm"),
        sph("BodyDark", (-1.25, -0.25, 0.88), 0.12, segments=8, name="hand"),
    ] + _chain("BodyDark", [(0.42, -0.3, 2.65), (0.75, -0.5, 2.9), (1.1, -0.55, 2.85), (1.3, -0.5, 2.6)], [0.075, 0.06, 0.05, 0.04], "antenna", segments=5) + [
        sph("BodyDark", (1.31, -0.5, 2.56), 0.09, segments=6, mirror=True, name="antennatip"),
        _leaf("Accessory", (0.05, -0.05, 2.78), (-0.8, -0.35, 0.1), 1.8, 0.5, 0.07, "leaf", thin_axis=(0.0, 0.0, 1.0)),
        _leaf("Accessory", (-0.05, 0.05, 2.78), (0.85, 0.3, 0.3), 1.6, 0.45, 0.07, "leaf", thin_axis=(0.0, 0.0, 1.0)),
        _leaf("Accessory", (0.0, 0.0, 2.82), (0.1, -0.25, 1.0), 0.7, 0.3, 0.07, "leaf", thin_axis=(0.0, 1.0, 0.0)),
        _leaf("Accessory", (0.12, 0.2, 1.4), (0.8, 0.6, 0.7), 0.6, 0.16, 0.06, "bud", thin_axis=(0.0, 0.0, 1.0)),
        _leaf("Accessory", (-0.12, 0.2, 1.15), (-0.8, 0.6, 0.6), 0.5, 0.14, 0.06, "bud", thin_axis=(0.0, 0.0, 1.0)),
    ],
}


# ---------------------------------------------------------------------------------------- Buzzik v2 (Buzzlebee)
# An upright chubby bee hovering: a big-eyed head on a pear of a body made of four bands (yellow, brown, yellow, brown) with the stinger out of the back of
# the last, two big translucent wings flaring up and out of the shoulders and two small ones under them, two curling antennae with bobbles, two tiny arms, two
# stub legs, and on its back the tiny backpack: a honeycomb cell (a flat-shaded hexagonal prism, axis across the body so the hexagon shows from the side) with a
# hexagonal rim plate and a blue buckle on each side.
RECIPES["BuzzlebeeV2"] = {
    "tier": "Uncommon", "world": 1, "biome": "Meadow", "batch": 0, "status": "recipe", "prototype": True, "height": 1.76,
    "silhouette": "an upright chubby bee hovering: a big-eyed head over a pear of a striped body with a stinger, two big translucent wings flaring up and out and two small ones under them, curling antennae, and a hexagonal honeycomb backpack",
    "hero": "the translucent wings over a striped pear body and the honeycomb-cell backpack",
    "face": {"on": "head", "eye_scale": 1.6, "eye_gap": 1.15, "eye_tilt": 0.0, "mouth": "wide", "look": (0.0, 0.05), "cross": 0.12},
    "palette": {"BodyDark": "6B4423", "Accessory": "A8E6FF"},
    "steps": [
        sph("Body", (0.0, -0.3, 1.3), (0.62, 0.58, 0.56), segments=16, name="head"),
        sph("Body", (0.0, 0.0, 0.98), (0.5, 0.46, 0.34), segments=14, name="thorax"),
        sph("BodyDark", (0.0, 0.08, 0.7), (0.6, 0.54, 0.3), segments=14, name="stripe"),
        sph("Body", (0.0, 0.18, 0.46), (0.62, 0.56, 0.27), segments=14, name="belly"),
        sph("BodyDark", (0.0, 0.3, 0.3), (0.5, 0.45, 0.22), segments=12, name="stripe"),
        spike("BodyDark", (0.0, 0.5, 0.26), (0.0, 0.98, 0.08), 0.12, segments=6, name="stinger"),
    ] + _msweep("BodyDark", [(0.28, -0.3, 0.42), (0.34, -0.42, 0.22), (0.34, -0.44, 0.06)], [0.12, 0.1, 0.08], "leg") + [
        sph("BodyDark", (0.34, -0.5, 0.05), (0.14, 0.2, 0.05), segments=8, mirror=True, name="foot"),
    ] + _msweep("BodyDark", [(0.45, -0.1, 1.0), (0.68, -0.32, 0.85), (0.72, -0.5, 0.65)], [0.1, 0.085, 0.07], "arm") + [
        sph("BodyDark", (0.72, -0.52, 0.6), 0.1, segments=8, mirror=True, name="hand"),
        _leaf("Accessory", (0.3, 0.25, 1.1), (0.6, 0.5, 0.9), 1.35, 0.38, 0.065, "wing", thin_axis=(0.45, -0.8, 0.35), mirror=True, segments=10),
        _leaf("Accessory", (0.3, 0.28, 0.98), (0.9, 0.5, 0.2), 0.85, 0.24, 0.06, "wing", thin_axis=(0.2, -0.3, 1.0), mirror=True, segments=10),
    ] + _chain("BodyDark", [(0.22, -0.4, 1.78), (0.4, -0.5, 2.0), (0.62, -0.58, 2.05)], [0.06, 0.05, 0.04], "antenna", segments=5) + [
        sph("BodyDark", (0.64, -0.59, 2.06), 0.09, segments=6, mirror=True, name="antennatip"),
        cyl("BodyDark", (0.0, 0.78, 0.82), (0.4, 0.4, 0.3), rot=(0.0, 90.0, 0.0), segments=6, flat=True, name="pack"),
        cyl("BodyDark", (0.33, 0.78, 0.82), (0.47, 0.47, 0.05), rot=(0.0, 90.0, 0.0), segments=6, flat=True, mirror=True, name="flap"),
        sph("Accessory", (0.42, 0.78, 0.82), (0.05, 0.12, 0.12), segments=8, mirror=True, name="buckle"),
    ],
}


# ---------------------------------------------------------------------------------------- Lantrin v2 (Lanternewt)
# A newt standing up like a person: an S of a body from a low pair of bent hind legs with webbed feet to a wide flat head with short back-swept gills, one chubby
# arm waving and one on its belly, a spotted back, and a thick tail that loops out round its right side and up to hang a caged lantern, level with its head,
# from a hook at the tip.
RECIPES["LanternewtV2"] = {
    "tier": "Uncommon", "world": 1, "biome": "Forest", "batch": 0, "status": "recipe", "prototype": True, "height": 2.27,
    "silhouette": "a newt standing up on its hind legs in an S, a wide flat head with short gills, one chubby arm waving and one on its belly, a spotted back, and a thick tail that loops out round its side and up to hold a caged glowing lantern beside its head",
    "hero": "the tail that loops up to hang the glowing lantern",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.15, "eye_tilt": -4.0, "mouth": "wide", "lid": 0.15, "eye_height": 0.8, "mouth_drop": 0.3, "mouth_scale": 1.2},
    "palette": {"BodyDark": "8C3F1C", "Accessory": "FFD84A"}, "glow": {"Accessory": 2.5},
    "steps": [
        sph("Body", (0.0, -0.45, 1.95), (0.85, 0.75, 0.55), segments=18, name="head"),
        sph("Body", (0.0, 0.5, 0.75), (0.58, 0.58, 0.52), segments=14, name="hips"),
        sweep("Body", [(0.0, 0.55, 0.7), (0.0, 0.35, 1.1), (0.0, 0.0, 1.5), (0.0, -0.25, 1.8)], [0.55, 0.52, 0.46, 0.4], "body"),
        sweep("Body", [(0.0, 0.8, 0.55), (0.7, 1.2, 0.5), (1.5, 1.1, 0.9), (2.05, 0.6, 1.6), (2.05, 0.0, 2.2), (1.75, -0.3, 2.5)], [0.42, 0.34, 0.28, 0.22, 0.17, 0.12], "tail"),
    ] + _msweep("Body", [(0.5, 0.5, 0.8), (0.9, 0.4, 0.55), (0.95, 0.2, 0.12)], [0.3, 0.22, 0.16], "leg") + [
        sph("BodyDark", (0.97, 0.03, 0.06), (0.32, 0.42, 0.06), segments=8, mirror=True, name="foot"),
        sweep("Body", [(-0.4, -0.1, 1.45), (-0.95, -0.3, 1.5), (-1.2, -0.4, 1.95)], [0.22, 0.17, 0.13], "arm"),
        sph("BodyDark", (-1.22, -0.42, 2.05), 0.16, segments=8, name="hand"),
        sweep("Body", [(0.4, -0.1, 1.5), (0.75, -0.35, 1.25), (0.55, -0.5, 0.95)], [0.22, 0.17, 0.13], "arm"),
        sph("BodyDark", (0.53, -0.52, 0.9), 0.16, segments=8, name="hand"),
        _leaf("BodyDark", (0.7, -0.35, 2.15), (0.75, 0.5, 0.55), 0.6, 0.13, 0.06, "gill", thin_axis=(0.0, 0.0, 1.0), mirror=True, segments=6),
        _leaf("BodyDark", (0.8, -0.4, 2.0), (0.9, 0.35, 0.1), 0.6, 0.13, 0.06, "gill", thin_axis=(0.0, 0.0, 1.0), mirror=True, segments=6),
        _leaf("BodyDark", (0.72, -0.45, 1.88), (0.8, 0.4, -0.4), 0.5, 0.12, 0.06, "gill", thin_axis=(0.0, 0.0, 1.0), mirror=True, segments=6),
        sph("BodyDark", (0.3, -0.3, 2.42), (0.16, 0.16, 0.08), segments=6, mirror=True, name="spot"),
        sph("BodyDark", (0.0, -0.4, 2.48), (0.18, 0.18, 0.08), segments=6, name="spot"),
        sph("BodyDark", (0.3, 0.5, 1.28), (0.15, 0.15, 0.07), segments=6, mirror=True, name="spot"),
        sph("Accessory", (1.75, -0.3, 1.95), (0.38, 0.38, 0.42), segments=14, name="lantern"),
        tor("BodyDark", (1.75, -0.3, 1.95), (0.43, 0.43, 0.43), minor=0.14, segments=12, mseg=4, name="cage"),
        spike("BodyDark", (1.75, -0.3, 2.3), (1.75, -0.3, 2.58), 0.2, segments=8, name="cap"),
    ],
}


# ---------------------------------------------------------------------------------------- Soakum v2 (Toastoad)
# A toad sitting up in a warm spring, pruney from the soak: a pear of a body with three dark wrinkle folds round the belly, a wide flat head with two eye bumps
# under heavy lids and a wide grin, folded hind legs with big flat feet, one arm waving and one on its belly, and on its back the pebble backpack: a cairn of
# four faceted stones, each smaller than the one under it, leaning over its head.
RECIPES["ToastoadV2"] = {
    "tier": "Uncommon", "world": 2, "biome": "GeyserField", "batch": 0, "status": "recipe", "prototype": True, "height": 1.98,
    "silhouette": "a toad sitting up with a pear-shaped body ringed with dark wrinkle folds, a wide flat head with two eye bumps and a wide grin, folded hind legs with big feet, one arm waving, and a leaning cairn of four faceted pebbles on its back",
    "hero": "the pebble cairn on its back and the wrinkle folds of the soak",
    "face": {"on": "head", "eye_scale": 1.4, "eye_gap": 1.2, "eye_tilt": -4.0, "mouth": "wide", "lid": 0.4, "mouth_scale": 1.5, "mouth_drop": 0.3},
    "palette": {"BodyDark": "974926", "Accessory": "9FB3C8"},
    "steps": [
        sph("Body", (0.0, 0.2, 0.8), (0.95, 0.85, 0.8), segments=16, name="body"),
        sph("Body", (0.0, -0.45, 1.45), (0.95, 0.75, 0.55), segments=18, name="head"),
        sph("Body", (0.5, -0.45, 1.88), 0.3, segments=10, mirror=True, name="eyebump"),
        sph("BodyDark", (0.0, 0.2, 0.46), (1.0, 0.9, 0.1), segments=14, name="fold"),
        sph("BodyDark", (0.0, 0.2, 0.7), (1.0, 0.9, 0.1), segments=14, name="fold"),
        sph("BodyDark", (0.0, 0.2, 0.94), (0.96, 0.86, 0.1), segments=14, name="fold"),
        sph("BodyDark", (0.0, -1.18, 1.5), (0.13, 0.09, 0.08), segments=8, name="nose"),
        sph("Body", (0.8, 0.3, 0.55), (0.42, 0.6, 0.45), segments=12, mirror=True, name="thigh"),
    ] + _msweep("BodyDark", [(0.85, -0.1, 0.45), (1.1, -0.65, 0.25), (0.95, -1.0, 0.1)], [0.26, 0.2, 0.15], "leg") + [
        sph("BodyDark", (0.95, -1.15, 0.07), (0.3, 0.4, 0.07), segments=10, mirror=True, name="foot"),
        sweep("Body", [(-0.6, -0.2, 1.15), (-1.0, -0.45, 0.9), (-0.95, -0.75, 0.6)], [0.2, 0.16, 0.13], "arm"),
        sph("BodyDark", (-0.95, -0.82, 0.55), (0.16, 0.2, 0.14), segments=8, name="hand"),
        sweep("Body", [(0.6, -0.2, 1.15), (1.05, -0.4, 1.4), (1.2, -0.55, 1.8)], [0.2, 0.16, 0.13], "arm"),
        sph("BodyDark", (1.22, -0.58, 1.9), (0.16, 0.2, 0.14), segments=8, name="hand"),
        ico("Accessory", (0.05, 0.95, 0.95), (0.55, 0.45, 0.42), rot=(0.0, 0.0, 20.0), segments=1, flat=True, name="pebble"),
        ico("Accessory", (0.28, 0.88, 1.5), (0.42, 0.36, 0.33), rot=(10.0, 0.0, -25.0), segments=1, flat=True, name="pebble"),
        ico("Accessory", (0.52, 0.82, 1.95), (0.33, 0.28, 0.26), rot=(0.0, 10.0, 30.0), segments=1, flat=True, name="pebble"),
        ico("Accessory", (0.78, 0.78, 2.3), (0.25, 0.22, 0.2), rot=(0.0, 0.0, 10.0), segments=1, flat=True, name="pebble"),
    ],
}


# ---------------------------------------------------------------------------------------- Sizz v2 (Emberchin)
# A sea urchin in mid-hop: an egg of a body with a bare face, one foot kicked back and one reaching forward, two stubby arms (one up), and the quills: nineteen
# of them in five rings round the back and sides, all swept back by the hop, of different lengths, each a brown spike ending in a glowing ember bead.
_EM_C = (0.0, 0.05, 1.0)
_EM_S = (0.85, 0.8, 0.75)
_EM_QUILLS = []
for _e, _azs, _lens in ((80, (0,), (0.75,)), (56, (20, 90, 160, 230, 300), (0.62, 0.55, 0.65, 0.58, 0.6)), (30, (330, 30, 90, 150, 210), (0.62, 0.65, 0.58, 0.7, 0.6)),
                        (4, (350, 55, 115, 175, 200), (0.6, 0.66, 0.56, 0.68, 0.6)), (-26, (30, 100, 170), (0.55, 0.5, 0.56))):
    for _k, _a in enumerate(_azs):
        _ar, _er = math.radians(_a), math.radians(_e)
        _d0 = (math.cos(_er) * math.cos(_ar), math.cos(_er) * math.sin(_ar), math.sin(_er))
        _b = ellipsoid_point(_EM_C, _mul(_EM_S, 0.88), *_d0)
        _d = _unit(_add(_d0, (0.0, 0.5, 0.1)))
        _q = _add(_b, _mul(_d, _lens[_k]))
        _EM_QUILLS.append(spike("BodyDark", _b, _q, 0.2, segments=5, flat=True, name="quill"))
        _EM_QUILLS.append(ico("Accessory", _add(_q, _mul(_d, 0.04)), 0.11, segments=1, flat=True, name="ember"))
RECIPES["EmberchinV2"] = {
    "tier": "Uncommon", "world": 2, "biome": "GeyserField", "batch": 0, "status": "recipe", "prototype": True, "height": 2.24,
    "silhouette": "a sea urchin in mid-hop: an egg of a body with a bare face under nineteen swept-back brown quills of different lengths, each ending in a glowing ember, one foot kicked back and one reaching forward, one stubby arm up",
    "hero": "the swept-back quills with glowing ember tips",
    "face": {"on": "body", "eye_scale": 1.25, "eye_gap": 1.0, "eye_tilt": -2.0, "mouth": "smile", "lid": 0.15, "eye_height": 0.55},
    "palette": {"BodyDark": "A66730", "Accessory": "FFD23F"}, "glow": {"Accessory": 2.5},
    "steps": [
        sph("Body", _EM_C, _EM_S, segments=16, name="body"),
        sweep("BodyDark", [(0.35, -0.1, 0.5), (0.5, -0.45, 0.28), (0.55, -0.7, 0.12)], [0.22, 0.17, 0.13], "leg"),
        sph("BodyDark", (0.56, -0.8, 0.07), (0.24, 0.34, 0.07), segments=8, name="foot"),
        sweep("BodyDark", [(-0.35, 0.1, 0.5), (-0.5, 0.45, 0.4), (-0.55, 0.75, 0.6)], [0.22, 0.17, 0.13], "leg"),
        sph("BodyDark", (-0.56, 0.85, 0.65), (0.24, 0.34, 0.07), rot=(-40.0, 0.0, 0.0), segments=8, name="foot"),
        sweep("Body", [(0.8, -0.15, 1.0), (1.15, -0.3, 1.3), (1.3, -0.35, 1.6)], [0.17, 0.14, 0.11], "arm"),
        sph("BodyDark", (1.32, -0.36, 1.68), 0.14, segments=8, name="hand"),
        sweep("Body", [(-0.8, -0.15, 1.0), (-1.1, -0.4, 0.95), (-1.15, -0.7, 0.8)], [0.17, 0.14, 0.11], "arm"),
        sph("BodyDark", (-1.15, -0.75, 0.76), 0.14, segments=8, name="hand"),
    ] + _EM_QUILLS,
}


# ---------------------------------------------------------------------------------------- Flurra v2 (Snowbun)
# A snow bunny sitting up: a head bigger than its pear of a body, one ear straight up and one tipped out sideways, pink inner ears and nose, a tuft of frost
# between the ears, tiny paws held to the chest, big flat hind feet pointing forward, and the tail: a snowball as big as its head, lumpy with snow clumps.
RECIPES["SnowbunV2"] = {
    "tier": "Common", "world": 2, "biome": "Snowfield", "batch": 0, "status": "recipe", "prototype": True, "height": 2.04,
    "silhouette": "a snow bunny sitting up with a head bigger than its body, one ear straight up and one tipped out sideways, tiny paws at its chest, big flat feet, and a lumpy snowball tail bigger than its head",
    "hero": "the snowball tail, bigger than its head and lumpy with snow",
    "face": {"on": "head", "eye_scale": 1.2, "eye_gap": 1.0, "eye_tilt": -6.0, "mouth": "smile", "lid": 0.2},
    "palette": {"BodyDark": "A9C3DD", "Accessory": "FF9EB5"},
    "steps": [
        sph("Body", (0.0, 0.2, 0.8), (0.56, 0.52, 0.72), segments=16, name="body"),
        sph("Body", (0.0, -0.2, 1.7), (0.74, 0.66, 0.62), segments=18, name="head"),
        _leaf("Body", (0.3, -0.12, 2.15), (0.2, 0.0, 1.0), 1.3, 0.24, 0.075, "ear", thin_axis=(0.0, 1.0, 0.0)),
        _leaf("Accessory", (0.3, -0.2, 2.2), (0.2, 0.0, 1.0), 1.05, 0.12, 0.06, "innerear", thin_axis=(0.0, 1.0, 0.0)),
        _leaf("Body", (-0.34, -0.12, 2.12), (-0.85, 0.0, 0.55), 1.2, 0.24, 0.075, "ear", thin_axis=(0.0, 1.0, 0.0)),
        _leaf("Accessory", (-0.37, -0.2, 2.16), (-0.85, 0.0, 0.55), 0.95, 0.12, 0.06, "innerear", thin_axis=(0.0, 1.0, 0.0)),
        sph("Accessory", (0.0, -0.84, 1.76), (0.09, 0.07, 0.07), segments=8, name="nose"),
        sph("BodyDark", (0.0, -0.1, 2.3), (0.18, 0.14, 0.1), segments=8, name="tuft"),
        sph("Body", (0.5, 0.1, 0.45), (0.32, 0.42, 0.38), segments=12, mirror=True, name="haunch"),
        sph("BodyDark", (0.5, -0.65, 0.14), (0.32, 0.64, 0.14), segments=10, mirror=True, name="foot"),
    ] + _msweep("Body", [(0.42, 0.0, 1.15), (0.58, -0.3, 0.98), (0.4, -0.5, 1.02)], [0.13, 0.11, 0.09], "arm") + [
        sph("Body", (0.38, -0.54, 1.04), 0.13, segments=8, mirror=True, name="paw"),
        sph("Body", (0.0, 1.28, 0.95), 0.7, segments=16, name="tail"),
        sph("BodyDark", (0.45, 1.58, 1.25), 0.2, segments=10, name="clump"),
        sph("BodyDark", (-0.4, 1.73, 0.85), 0.18, segments=10, name="clump"),
        sph("BodyDark", (0.1, 1.63, 1.55), 0.17, segments=10, name="clump"),
    ],
}


# ---------------------------------------------------------------------------------------- Digling v2 (Chipmole)
# A mole mid-dig, rump high and head low: a tubby velvet body with a small nose pointing out between the eyes and the grin, one huge spade paw wound up with three
# ice claws fanned like a pick, the other paw on the floor with three ice claws in the ice and four chips kicked up, two stub legs and a tail nub.
RECIPES["ChipmoleV2"] = {
    "tier": "Common", "world": 2, "biome": "IceCave", "batch": 0, "status": "recipe", "prototype": True, "height": 1.98,
    "silhouette": "a tubby mole mid-dig, rump high and head low, with a small pointed nose, one huge spade paw wound up with three ice-pick claws fanned out and the other paw on the floor with three ice claws in the ice, chips flying",
    "hero": "the spade paws with fanned ice-pick claws",
    "face": {"on": "head", "eye_scale": 1.3, "eye_gap": 1.05, "eye_tilt": -4.0, "mouth": "wide", "lid": 0.15, "mouth_drop": 0.3},
    "palette": {"BodyDark": "3B4656", "Accessory": "9CD3F0", "Mouth": "E8685A"},
    "steps": [
        sph("Body", (0.0, 0.3, 1.0), (0.92, 1.05, 0.88), segments=16, name="body"),
        sph("Body", (0.0, -0.8, 0.8), (0.68, 0.62, 0.58), segments=16, name="head"),
        rod("Body", (0.0, -1.2, 0.86), (0.0, -1.7, 0.72), 0.17, 0.12, segments=8, name="snout"),
        sph("BodyDark", (0.0, -1.75, 0.7), 0.13, segments=8, name="nose"),
        sweep("Body", [(0.75, -0.1, 1.05), (1.25, 0.05, 1.35), (1.4, -0.4, 1.55)], [0.3, 0.26, 0.24], "arm"),
        sph("BodyDark", (1.43, -0.5, 1.66), (0.5, 0.3, 0.42), segments=12, name="paw"),
        sweep("Body", [(-0.75, -0.1, 0.95), (-1.2, -0.5, 0.65), (-1.1, -0.95, 0.42)], [0.3, 0.26, 0.24], "arm"),
        sph("BodyDark", (-1.08, -1.08, 0.36), (0.48, 0.3, 0.3), segments=12, name="paw"),
    ] + [
        spike("Accessory", (1.43 + _dx, -0.65, 1.85), (1.43 + 1.9 * _dx, -0.85, 2.5), 0.11, segments=5, flat=True, name="claw") for _dx in (-0.3, 0.0, 0.3)
    ] + [
        spike("Accessory", (-1.08 + _dx, -1.27, 0.4), (-1.08 + 1.5 * _dx, -1.85, 0.07), 0.11, segments=5, flat=True, name="claw") for _dx in (-0.3, 0.0, 0.3)
    ] + _msweep("BodyDark", [(0.5, 0.3, 0.6), (0.58, 0.2, 0.4), (0.6, 0.05, 0.2)], [0.3, 0.24, 0.2], "leg") + [
        sph("BodyDark", (0.0, 1.25, 0.95), (0.2, 0.24, 0.18), segments=8, name="tail"),
        ico("Accessory", (-1.7, -1.5, 0.13), 0.14, segments=1, flat=True, name="chip"),
        ico("Accessory", (-0.5, -1.95, 0.12), 0.13, segments=1, flat=True, name="chip"),
        ico("Accessory", (-1.9, -0.9, 0.12), 0.12, segments=1, flat=True, name="chip"),
        ico("Accessory", (-0.95, -2.1, 0.1), 0.1, segments=1, flat=True, name="chip"),
    ],
}

# ==== DESIGN PASS 4 END ====


# ================================================================================================ the engine
# Everything below turns a recipe into a flat list of parts (the steps, mirrored, plus the face), and checks it. It is plain
# Python on purpose: species_bodies.py only has to hand each part to Blender, and this file can prove a recipe is sane first.

def _find_host(rec, name):
    for s in rec["steps"]:
        if s["name"] == name and s["prim"] in ("sphere", "icosphere"):
            return s
    raise ValueError("the face host %r is not a sphere or icosphere step of this recipe" % name)


def _extent(R, s):
    """Half-extents along the world axes of an ellipsoid with rotation R and radii s."""
    return tuple(math.sqrt(sum((R[i][j] * s[j]) ** 2 for j in range(3))) for i in range(3))


def _hit_front(c, R, s, x, z):
    """Where a ray along +y at (x, z) first meets an ellipsoid (centre c, rotation R, radii s): (point, outward normal)."""
    Rt = tuple(tuple(R[j][i] for j in range(3)) for i in range(3))
    o = mv(Rt, (x - c[0], -1000.0 - c[1], z - c[2]))
    d = mv(Rt, (0.0, 1.0, 0.0))
    o = tuple(o[i] / s[i] for i in range(3))
    d = tuple(d[i] / s[i] for i in range(3))
    a = sum(v * v for v in d)
    b = 2.0 * sum(o[i] * d[i] for i in range(3))
    cc = sum(v * v for v in o) - 1.0
    disc = b * b - 4.0 * a * cc
    if disc < 0.0:
        raise ValueError("no body at x=%.2f z=%.2f: the face point is outside the host's outline" % (x, z))
    t = (-b - math.sqrt(disc)) / (2.0 * a)
    u = tuple(o[i] + t * d[i] for i in range(3))
    n = _unit(mv(R, tuple(u[i] / s[i] for i in range(3))))
    return (x, -1000.0 + t, z), n


def _frame(n):
    """Rotation whose local -y points along the outward normal n and whose local z stays upright."""
    ey = _mul(n, -1.0)
    ex = _cross(ey, (0.0, 0.0, 1.0))
    ex = (1.0, 0.0, 0.0) if _len(ex) < 1e-6 else _unit(ex)
    ez = _cross(ex, ey)
    return ((ex[0], ey[0], ez[0]), (ex[1], ey[1], ez[1]), (ex[2], ey[2], ez[2]))


def _fpart(prim, slot, loc, rot, scale, segments, half=None, name="face"):
    return {"prim": prim, "slot": slot, "loc": loc, "rot": rot, "scale": scale, "segments": segments, "flat": False,
            "minor": 0.25, "mseg": 6, "tip": 0.0, "half": half, "name": name}


MOUTHS = {  # half-ellipsoid radii in mouth units (u = the unscaled eye radius), height of its top edge, teeth
    "o": {"half": None, "scale": (0.62, 0.32, 0.74), "z": 0.0, "teeth": 0},
    "smile": {"half": "bottom", "scale": (1.0, 0.36, 0.62), "z": 0.2, "teeth": 0},
    "wide": {"half": "bottom", "scale": (1.5, 0.4, 0.95), "z": 0.3, "teeth": 0},
    "zigzag": {"half": "bottom", "scale": (1.2, 0.38, 0.7), "z": 0.25, "teeth": 4},
}


def face_parts(rec):
    """The eyes (white, pupil, highlight, optional lid) and the mouth, placed on the host's surface."""
    f = rec["face"]
    host = _find_host(rec, f.get("on", "body"))
    c, s, R = host["loc"], host["scale"], euler_matrix(host["rot"])
    ex, ey, ez = _extent(R, s)
    r0 = 0.2 * min(ex, 1.15 * ez)
    lift = f.get("lift", 0.0)
    z_eye = (c[2] - ez) + f.get("eye_height", 0.66) * 2.0 * ez
    x_eye = 0.38 * ex * f.get("eye_gap", 1.0)
    look = f.get("look", (0.0, -0.05))
    lid = f.get("lid", 0.0)
    parts = []
    for sgn in (-1, 1):
        r = r0 * f.get("eye_scale", 1.0) * (1.0 - sgn * f.get("eye_asym", 0.0))
        P, N = _hit_front(c, R, s, sgn * x_eye, z_eye)
        P = _add(P, _mul(N, lift))
        Q = _frame(N)

        def L(x, y, z, P=P, Q=Q, r=r):
            return _add(P, mv(Q, (x * r, y * r, z * r)))

        lx = max(-0.32, min(0.32, look[0] - sgn * f.get("cross", 0.0)))
        lz = max(-0.3, min(0.3, look[1]))
        parts.append(_fpart("sphere", "EyeWhite", L(0, 0.15, 0), Q, (r, 0.75 * r, r), 12, name="eye"))
        parts.append(_fpart("sphere", "Pupil", L(lx, -0.45, lz), Q, (0.58 * r, 0.30 * r, 0.58 * r), 8, name="pupil"))
        parts.append(_fpart("sphere", "EyeHighlight", L(lx - 0.18, -0.69, lz + 0.22), Q, (0.17 * r, 0.08 * r, 0.17 * r), 6, name="glint"))
        if lid > 0.0:
            ze = 1.0 - 2.0 * lid
            th = -sgn * f.get("eye_tilt", 0.0)
            Rl = mm(Q, _ry(th))
            centre = _add(P, mv(Q, mv(_ry(th), (0.0, 0.1 * r, ze * r))))
            parts.append(_fpart("sphere", "Body", centre, Rl, (1.14 * r, 0.78 * r, (0.12 + 2.0 * lid) * r), 12, half="top", name="lid"))
    m = MOUTHS[f.get("mouth", "o")]
    u = r0 * f.get("mouth_scale", 1.0)
    z_m = z_eye - f.get("mouth_drop", 0.22) * 2.0 * ez
    P, N = _hit_front(c, R, s, 0.0, z_m)
    P = _add(P, _mul(N, lift))
    Q = _frame(N)
    sx, sy, sz = m["scale"]
    parts.append(_fpart("sphere", "Mouth", _add(P, mv(Q, (0.0, 0.1 * u, m["z"] * u))), Q, (sx * u, sy * u, sz * u), 12 if m["half"] else 10, half=m["half"], name="mouth"))
    n = m["teeth"]
    for i in range(n):
        tx = (i - (n - 1) / 2.0) * 0.62 * u
        parts.append(_fpart("cone", "EyeWhite", _add(P, mv(Q, (tx, -0.3 * u, (m["z"] - 0.13) * u))), mm(Q, _rx(180.0)),
                            (0.2 * u, 0.1 * u, 0.17 * u), 4, name="tooth"))
    return parts


def _part(s, loc, R):
    out = {"prim": s["prim"], "slot": s["slot"], "loc": loc, "rot": R, "scale": s["scale"], "segments": s["segments"],
           "flat": s.get("flat", not SMOOTH_BY_DEFAULT[s["prim"]]), "minor": s.get("minor", 0.25), "mseg": s.get("mseg", 6),
           "tip": s.get("tip", 0.0), "half": s.get("half"), "name": s["name"] or s["prim"]}
    if s["prim"] == "sweep":
        out["pts"], out["radii"] = s["pts"], s["radii"]
    return out


def expand(rec):
    """The recipe as a list of parts: the steps (mirrored ones twice) and then the face. Each part has a 3x3 rotation matrix."""
    parts = []
    for s in rec["steps"]:
        R = euler_matrix(s["rot"])
        parts.append(_part(s, s["loc"], R))
        if s["mirror"] and abs(s["loc"][0]) > 1e-6:
            parts.append(_part(s, (-s["loc"][0], s["loc"][1], s["loc"][2]), mirror_matrix(R)))
    parts += face_parts(rec)
    return parts


# ------------------------------------------------------------------------------------------------ estimates
def _rings(n, half):
    return 2 * max(2, int(n / 4.0 + 0.5)) if half else max(3, n // 2)


def part_tris(p):
    n, prim = p["segments"], p["prim"]
    if prim == "sphere":
        rings = _rings(n, p["half"])
        return n * (rings - 1) * (1 if p["half"] else 2)
    if prim == "icosphere":
        return 20 * 4 ** (n - 1)
    if prim == "cube":
        return 12
    if prim == "cylinder":
        return 4 * n - 4
    if prim == "cone":
        return 2 * n - 2 if p["tip"] <= 0.0 else 4 * n - 4
    if prim == "torus":
        return 2 * n * p["mseg"]
    if prim == "sweep":
        return 24 * len(p["pts"])  # a rough guess: the sculpt builder decimates the core to its own budget, so the real count is the build's
    raise ValueError("unknown primitive %r" % prim)


def part_bbox(p):
    """(lo, hi) corners of a bound on the part (exact for ellipsoids, boxes, cylinders, cones; a cylinder bound for a torus)."""
    R, s, c = p["rot"], p["scale"], p["loc"]
    prim = p["prim"]
    if prim == "sweep":  # the control points grown by their radii (the curve itself bulges a little past them)
        lo = tuple(min(q[i] - r for q, r in zip(p["pts"], p["radii"])) for i in range(3))
        hi = tuple(max(q[i] + r for q, r in zip(p["pts"], p["radii"])) for i in range(3))
        return lo, hi
    if prim in ("sphere", "icosphere"):
        e = _extent(R, s)
        return _sub(c, e), _add(c, e)
    if prim == "cube":
        e = tuple(sum(abs(R[i][j]) * s[j] for j in range(3)) for i in range(3))
        return _sub(c, e), _add(c, e)
    axis = (R[0][2] * s[2], R[1][2] * s[2], R[2][2] * s[2])
    ring = tuple(math.hypot(R[i][0] * s[0], R[i][1] * s[1]) for i in range(3))
    if prim == "cylinder":
        e = tuple(abs(axis[i]) + ring[i] for i in range(3))
        return _sub(c, e), _add(c, e)
    if prim == "cone":
        base, top = _sub(c, axis), _add(c, axis)
        t = p["tip"]
        lo = tuple(min(base[i] - ring[i], top[i] - t * ring[i]) for i in range(3))
        hi = tuple(max(base[i] + ring[i], top[i] + t * ring[i]) for i in range(3))
        return lo, hi
    if prim == "torus":
        m = p["minor"]
        e = tuple(abs(R[i][2]) * m * s[2] + math.hypot(R[i][0] * s[0] * (1 + m), R[i][1] * s[1] * (1 + m)) for i in range(3))
        return _sub(c, e), _add(c, e)
    raise ValueError("unknown primitive %r" % prim)


def estimate(parts):
    """(triangles, (lo, hi)) for a list of parts."""
    tris = sum(part_tris(p) for p in parts)
    boxes = [part_bbox(p) for p in parts]
    lo = tuple(min(b[0][i] for b in boxes) for i in range(3))
    hi = tuple(max(b[1][i] for b in boxes) for i in range(3))
    return tris, (lo, hi)


def slots_used(parts):
    return {p["slot"] for p in parts}


def notes_height(sid):
    f = MODELS / sid / "notes.md"
    if not f.exists():
        return None
    m = re.search(r"Height: ([\d.]+)", f.read_text())
    return float(m.group(1)) if m else None


def material_slots(sid):
    """The slot names of assets/models/<Id>/materials.json, in order (None when the folder has none)."""
    f = MODELS / sid / "materials.json"
    if not f.exists():
        return None
    import json
    return [e["name"] for e in json.loads(f.read_text())]


def check(sid):
    """Problems and numbers for one recipe: (problems, tris, estimated height, lowest z, declared height)."""
    rec = RECIPES[sid]
    problems = []
    if rec["status"] != "recipe":
        return problems, 0, 0.0, 0.0, rec["height"]
    try:
        parts = expand(rec)
    except ValueError as exc:
        return ["face: %s" % exc], 0, 0.0, 0.0, rec["height"]
    tris, (lo, hi) = estimate(parts)
    height = hi[2] - lo[2]
    if tris > TRI_BUDGET and rec.get("prototype"):
        problems.append("note: %d triangles by the primitive estimate; a prototype is built by species_sculpt.py --method hybrid, which fuses the core and sets its own count" % tris)
    elif tris > TRI_BUDGET:
        problems.append("%d triangles is over the %d cap" % (tris, TRI_BUDGET))
    elif tris > TRI_GUIDE[rec["tier"]]:
        problems.append("note: %d triangles is over the %d target for %s" % (tris, TRI_GUIDE[rec["tier"]], rec["tier"]))
    if abs(height - rec["height"]) > 0.03 * rec["height"]:
        problems.append("%sheight %.2f is more than 3 percent off %.2f (the builder would rescale by %.3f)" % (
            "note: " if rec.get("prototype") else "", height, rec["height"], rec["height"] / height))  # a prototype is free to be fitted
    if abs(lo[2]) > 0.05:
        problems.append("lowest point z=%.2f, the feet belong on z=0" % lo[2])
    slots = material_slots(sid)
    used = slots_used(parts)
    if slots is not None and "EyeHighlight" not in slots:
        used = {"EyeWhite" if s == "EyeHighlight" else s for s in used}  # the event species have no highlight slot: the glint uses EyeWhite
    if slots is not None:
        for sl in used - set(slots):
            problems.append("slot %s is not in materials.json (%s)" % (sl, ", ".join(slots)))
        for sl in set(slots) - used:
            problems.append("slot %s is never used" % sl)
    nh = notes_height(sid)
    if nh is not None and abs(nh - rec["height"]) > 0.005 and not rec.get("height_note"):
        problems.append("height %.2f differs from notes.md (%.2f) with no height_note" % (rec["height"], nh))
    for sl, v in rec.get("palette", {}).items():
        if not re.fullmatch(r"[0-9A-Fa-f]{6}", v):
            problems.append("palette %s: %r is not a 6-digit hex" % (sl, v))
    return problems, tris, height, lo[2], rec["height"]


def ids_for(spec):
    """Ids from a comma list, 'world1' or 'world2' (every recipe of that world), 'batchN' or 'all'. The group ids skip the hero prototypes
    (`"prototype": True`); name one (FenripupV2, Skydrake) to pick it."""
    out = []
    for token in [t.strip() for t in spec.split(",") if t.strip()]:
        if token in ("all", "world1", "world2"):
            out += [k for k, v in RECIPES.items() if v["status"] == "recipe" and not v.get("prototype") and (token == "all" or v["world"] == int(token[5:]))]
        elif re.fullmatch(r"batch\d+", token):
            out += [k for k, v in RECIPES.items() if v["batch"] == int(token[5:]) and not v.get("prototype")]
        elif token in RECIPES:
            out.append(token)
        else:
            raise SystemExit("unknown species or batch: %s" % token)
    seen = []
    for i in out:
        if i not in seen:
            seen.append(i)
    return seen


def main():
    ap = argparse.ArgumentParser(description="Check the silhouette recipes without Blender")
    ap.add_argument("--species", default="all", help="comma list, 'world1', 'batchN' or 'all' (default all)")
    args = ap.parse_args()
    ids = ids_for(args.species) if args.species != "all" else list(RECIPES)
    bad = 0
    todo = 0
    print("%-12s %-10s %-5s %-6s %5s  %-11s %s" % ("species", "tier", "world", "batch", "tris", "height", "status"))
    for sid in ids:
        rec = RECIPES[sid]
        problems, tris, height, low, declared = check(sid)
        hard = [p for p in problems if not p.startswith("note:")]
        if rec["status"] != "recipe":
            todo += 1
            print("%-12s %-10s %-5s %-6s %5s  %-11s TODO" % (sid, rec["tier"], rec["world"], rec["batch"], "-", "%.2f" % declared))
            continue
        bad += 1 if hard else 0
        print("%-12s %-10s %-5s %-6s %5d  %-11s %s" % (sid, rec["tier"], rec["world"], rec["batch"], tris, "%.2f/%.2f" % (height, declared), "ok" if not problems else ""))
        for p in problems:
            print("    - %s" % p)
    print("")
    print("%d recipes, %d TODO stubs, %d with problems" % (len(ids) - todo, todo, bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
