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
SMOOTH_BY_DEFAULT = {"sphere": True, "icosphere": True, "cube": False, "cylinder": True, "cone": True, "torus": True}


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


# ================================================================================================ the recipes
# World 1 (Verdant): 16 full recipes, batch 1..5 = the order of tonight. The three Haunted Nebula event species were already
# rebuilt by tools/blender/event_species.py. The Frostbyte 16 are stubs until next week.

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
    "silhouette": "a wide squat mound with a bumpy skyline of seven moss clumps, two big feet and one thin sprout with a bud leaning off the top",
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
        rod("BodyDark", (0.12, 0.05, 2.0), (0.24, 0.05, 2.4), 0.06, segments=6, name="stalk"),
        sph("Accessory", (0.25, 0.05, 2.46), (0.2, 0.2, 0.18), segments=10, name="bud"),
        sph("BodyDark", (0.44, 0.05, 2.22), (0.2, 0.06, 0.1), rot=(0, -25, -10), segments=8, name="leaf"),
        sph("BodyDark", (-0.06, 0.05, 2.2), (0.2, 0.06, 0.1), rot=(0, 25, 10), segments=8, name="leaf"),
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
    "silhouette": "a starburst: a small ball ringed by twenty thin wisps each ending in a dot, standing on two leaf feet",
    "hero": "the dandelion puff: radiating wisps with yellow seed tips",
    "face": {"on": "body", "eye_scale": 1.35, "eye_gap": 1.1, "eye_tilt": -10.0, "mouth": "o", "lid": 0.25, "look": (0.0, 0.0)},
    "palette": {"BodyDark": "8FC96A", "Accessory": "FFD84A"},
    "steps": [
        sph("Body", (0, 0, 1.1), (0.74, 0.72, 0.72), segments=16, name="body"),
        sph("BodyDark", (0.36, -0.25, 0.2), (0.28, 0.46, 0.2), rot=(0, 0, 18), segments=10, mirror=True, name="leaffoot"),
    ],
}


def _puff_wisps():
    """Eleven wisps for x > 0 (mirrored), spread from the top down to the lower sides; none in front of the face."""
    out = []
    centre = (0.0, 0.0, 1.1)
    golden = math.pi * (3.0 - math.sqrt(5.0))
    cands = []
    for i in range(240):
        z = 1.0 - 2.0 * ((i + 0.5) / 240.0)
        r = math.sqrt(max(0.0, 1.0 - z * z))
        d = (r * math.cos(golden * i), r * math.sin(golden * i), z)
        if d[0] >= 0.2 and d[2] >= -0.4 and -d[1] <= 0.6:
            cands.append(d)
    cands.sort(key=lambda d: d[2])
    for k in range(11):
        d = cands[round(k * (len(cands) - 1) / 10.0)]
        out.append(rod("BodyDark", _add(centre, _mul(d, 0.6)), _add(centre, _mul(d, 0.95)), 0.035, segments=4, mirror=True, name="wisp"))
        out.append(ico("Accessory", _add(centre, _mul(d, 1.0)), 0.13, segments=1, mirror=True, name="seed"))
    out.append(rod("BodyDark", (0, 0.0, 1.7), (0, 0.0, 2.05), 0.035, segments=4, name="wisp"))
    out.append(ico("Accessory", (0, 0.0, 2.07), 0.13, segments=1, name="seed"))
    out.append(rod("BodyDark", (0, 0.5, 1.45), (0, 0.8, 1.65), 0.035, segments=4, name="wisp"))
    out.append(ico("Accessory", (0, 0.84, 1.68), 0.13, segments=1, name="seed"))
    return out


RECIPES["Puffpuff"]["steps"] += _puff_wisps()

# ---------------------------------------------------------------------------------------- batch 2: bugs and thin parts
RECIPES["Glimmo"] = {
    "tier": "Common", "world": 1, "biome": "Forest", "batch": 2, "status": "recipe", "height": 2.70,
    "silhouette": "a drooping bell on a flared skirt with a fringe of dangling tendrils, a fat round lamp swinging out behind and two bobble antennae",
    "hero": "the glowing firefly lamp hanging off its back",
    "face": {"on": "body", "eye_scale": 1.35, "eye_gap": 0.95, "eye_tilt": 0.0, "mouth": "smile", "look": (0.0, 0.1)},
    "palette": {"BodyDark": "E4A83A", "Accessory": "B8FF4F"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0, 0, 1.7), (1.15, 1.1, 0.9), segments=16, name="body"),
        cone("BodyDark", (0, 0, 0.92), (1.05, 1.0, 0.32), tip=0.7, segments=16, name="skirt"),
        sph("Accessory", (0, 1.5, 1.0), (0.75, 0.85, 0.75), segments=12, name="lamp"),
        rod("BodyDark", (0.32, -0.15, 2.42), (0.5, -0.22, 2.57), 0.04, segments=5, mirror=True, name="antenna"),
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
    "silhouette": "a wide flat crab on six thin legs: one huge boulder fist raised high with crystal spikes, the other fist small and low, so it leans like a boxer",
    "hero": "the boulder claws, the raised one sprouting glowing amber crystals",
    "face": {"on": "body", "eye_scale": 1.4, "eye_gap": 1.25, "eye_tilt": 10.0, "mouth": "zigzag", "lid": 0.3, "mouth_scale": 1.35},
    "palette": {"BodyDark": "8A857D", "Accessory": "FFA928"}, "glow": {"Accessory": 1.5}, "metal": {"Accessory": 0.0},
    "steps": [
        sph("Body", (0, 0.1, 1.0), (1.25, 0.95, 0.78), segments=16, name="body"),
        sph("BodyDark", (0.0, 0.6, 1.65), (0.55, 0.4, 0.2), segments=8, name="plate"),
        rod("Body", (1.05, -0.35, 0.85), (1.45, -0.35, 0.0), 0.13, 0.09, segments=5, mirror=True, name="leg"),
        rod("Body", (1.05, 0.15, 0.85), (1.5, 0.15, 0.0), 0.13, 0.09, segments=5, mirror=True, name="leg"),
        rod("Body", (1.0, 0.6, 0.85), (1.4, 0.65, 0.0), 0.13, 0.09, segments=5, mirror=True, name="leg"),
        rod("Body", (0.95, -0.4, 1.2), (1.25, -0.85, 1.42), 0.2, segments=6, name="arm"),
        ico("BodyDark", (1.35, -0.95, 1.45), (0.64, 0.58, 0.58), rot=(10, 0, 25), segments=2, flat=True, name="fist"),
        spike("Accessory", (1.3, -0.9, 1.8), (1.24, -0.95, 2.42), 0.3, segments=5, name="crystal"),
        spike("Accessory", (1.55, -0.9, 1.75), (1.85, -0.95, 2.28), 0.24, segments=5, name="crystal"),
        spike("Accessory", (1.05, -0.95, 1.75), (0.82, -0.95, 2.26), 0.24, segments=5, name="crystal"),
        rod("Body", (-0.95, -0.35, 0.95), (-1.2, -0.75, 0.8), 0.18, segments=6, name="arm"),
        ico("BodyDark", (-1.4, -0.85, 0.8), (0.58, 0.52, 0.52), segments=2, flat=True, name="fist"),
        spike("Accessory", (-1.4, -0.85, 1.2), (-1.36, -0.9, 1.6), 0.2, segments=5, name="crystal"),
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
_ANTLERS = []
for _p0, _p1, _r0, _r1 in (((0.3, -1.45, 3.3), (0.6, -1.45, 3.68), 0.1, 0.07), ((0.48, -1.45, 3.5), (1.2, -1.45, 3.72), 0.07, 0.05),
                           ((0.6, -1.45, 3.68), (0.62, -1.45, 3.98), 0.07, 0.05), ((0.55, -1.45, 3.62), (0.2, -1.45, 3.88), 0.06, 0.045)):
    _ANTLERS.append(rod("BodyDark", _p0, _p1, _r0, _r1, segments=6, mirror=True, name="antler"))
for _p in ((1.2, -1.45, 3.78), (0.62, -1.45, 4.03), (0.2, -1.45, 3.94)):
    _ANTLERS.append(sph("Accessory", _p, 0.16, segments=6, mirror=True, name="blossom"))

RECIPES["Gaiabloom"] = {
    "tier": "Legendary", "world": 1, "biome": "Meadow", "batch": 5, "status": "recipe", "height": 4.14,
    "silhouette": "a long-legged stag with its head high on a curved neck, a branching tree for antlers blossoming pink, a gold halo ring behind the head and a gold ring on the ground round its feet",
    "hero": "the tree antlers: bark branches with blossoms, wider than the head",
    "face": {"on": "head", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": -6.0, "mouth": "smile", "lid": 0.3},
    "palette": {"BodyDark": "8A5A2F", "Accessory": "FF8FB3"},
    "steps": [
        sph("Body", (0, 0.55, 1.95), (1.0, 1.55, 0.78), segments=12, name="body"),
        rod("Body", (0.6, -0.55, 1.5), (0.65, -0.6, 0.2), 0.24, 0.16, segments=6, mirror=True, name="leg"),
        rod("Body", (0.6, 1.5, 1.5), (0.65, 1.55, 0.2), 0.24, 0.16, segments=6, mirror=True, name="leg"),
        sph("BodyDark", (0.65, -0.62, 0.11), (0.22, 0.3, 0.11), segments=6, mirror=True, name="hoof"),
        sph("BodyDark", (0.65, 1.58, 0.11), (0.22, 0.3, 0.11), segments=6, mirror=True, name="hoof"),
        rod("Body", (0, -0.65, 2.15), (0, -1.45, 2.68), 0.6, 0.46, segments=8, name="neck"),
        sph("Body", (0, -1.5, 2.72), (0.8, 0.78, 0.7), segments=12, name="head"),
        sph("Body", (0.78, -1.35, 3.04), (0.4, 0.1, 0.22), rot=(0, 0, 35), segments=8, mirror=True, name="ear"),
        sph("BodyDark", (0, -0.95, 2.2), (0.3, 0.12, 0.45), rot=(20, 0, 0), segments=8, name="ruff"),
        sph("BodyDark", (0.38, -0.9, 2.3), (0.28, 0.12, 0.42), rot=(15, 0, 25), segments=8, mirror=True, name="ruff"),
        sph("Body", (0, 2.2, 2.3), (0.3, 0.35, 0.3), segments=10, name="tail"),
        tor("Trim", (0, -1.1, 2.92), (1.0, 1.0, 1.0), rot=(90, 0, 0), minor=0.06, segments=16, mseg=4, name="halo"),
        tor("Trim", (0, 0.5, 0.08), (2.2, 2.2, 2.2), minor=0.035, segments=18, mseg=4, name="groundring"),
        sph("Accessory", (0.95, -0.9, 0.18), 0.17, segments=6, mirror=True, name="flower"),
        sph("Accessory", (1.1, 1.3, 0.18), 0.17, segments=6, mirror=True, name="flower"),
        sph("Accessory", (0.2, -1.5, 0.16), 0.15, segments=6, name="flower"),
    ] + _ANTLERS,
}

_SUN_RAYS = []
for _k in range(12):
    _a = 30.0 * _k
    _d = (math.cos(math.radians(_a)), 0.0, math.sin(math.radians(_a)))
    _SUN_RAYS.append(cone("Accessory", (_d[0] * 1.3, 0.8, 2.14 + _d[2] * 1.3), (0.18, 0.07, 0.2), rot=aim(_d), segments=4, flat=True, name="ray"))
_RADISH_LEAVES = []
for _b, _ll in ((-62, 0.45), (-32, 0.5), (0, 0.55), (32, 0.5), (62, 0.45)):
    _d = (math.sin(math.radians(_b)), 0.1, math.cos(math.radians(_b)))
    _RADISH_LEAVES.append(sph("BodyDark", _add((0, -0.05, 2.55), _mul(_d, _ll * 0.9)), (0.3, 0.08, _ll), rot=aim(_d), segments=8, name="leaf"))

RECIPES["Radish"] = {
    "tier": "Cosmic", "world": 1, "biome": "Meadow", "batch": 5, "status": "recipe", "height": 3.64,
    "silhouette": "a round radish with a leaf crown in front of a huge sun disk ringed by twelve rays, a tilted gold orbit ring round its waist and a root-tip tail",
    "hero": "the sun disk: a glowing disc with rays behind the whole body",
    "face": {"on": "body", "eye_scale": 1.1, "eye_gap": 1.0, "eye_tilt": 0.0, "mouth": "wide", "look": (0.0, 0.12)},
    "palette": {"BodyDark": "5DBB3A", "Accessory": "FFC83D"}, "glow": {"Accessory": 3.0},
    "steps": [
        sph("Body", (0, 0, 1.5), (1.3, 1.25, 1.3), segments=16, name="body"),
        spike("Body", (0, 0.8, 0.6), (0, 1.45, 0.05), 0.3, segments=6, name="root"),
        sph("BodyDark", (0.55, -0.45, 0.2), (0.38, 0.5, 0.2), segments=8, mirror=True, name="foot"),
        cyl("Accessory", (0, 0.8, 2.14), (1.2, 1.2, 0.07), rot=(90, 0, 0), segments=24, name="disk"),
        tor("Accessory", (0, 0, 1.5), (1.9, 1.9, 1.9), rot=(18, 0, 8), minor=0.035, segments=24, mseg=4, name="orbit"),
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
_stub("Flufflet", "Common", 2, "Snowfield", 6, 2.64, "a tall snowball with a long knitted scarf whipping out behind and two mitten-shaped ears", "the knitted scarf, one trailing end")
_stub("Snowbun", "Common", 2, "Snowfield", 6, 2.04, "a pear-shaped bunny with two long upright ears and a snowball tail bigger than its head, stacked in three balls", "the tail that keeps growing")
_stub("Pengoo", "Uncommon", 2, "Snowfield", 7, 1.98, "a plump penguin lying flat on its belly mid-slide, flippers swept back, feet kicked up, a tiny backpack on its back", "the tiny backpack and the belly-slide pose")
_stub("Reindazzle", "Rare", 2, "Snowfield", 8, 3.65, "a slender long-necked reindeer with a tall fan of icicle-spike antlers and a round glowing nose", "the icicle antlers and the blinking nose")
_stub("Drippo", "Common", 2, "IceCave", 6, 2.11, "an upside-down teardrop: pointed top, round belly, two stubby legs, a loose droplet floating beside it", "the drip-drop body with its falling droplet")
_stub("Chipmole", "Common", 2, "IceCave", 7, 1.98, "a squat digger with a pointed snout and two oversized pickaxe claws raised at its sides, ice chips round its feet", "the ice-pick claws")
_stub("Flapsicle", "Uncommon", 2, "IceCave", 7, 1.76, "an upside-down bat hanging by tiny feet from nothing, wings folded round it like icicle blades (lowest point is the head at z = 0)", "the icicle wings and the hanging pose")
_stub("Shellberg", "Rare", 2, "IceCave", 8, 2.76, "a tortoise under a huge jagged iceberg shell with crystal peaks, head peeking out in a little knitted cap", "the iceberg shell with its glowing blue vein")
_stub("Shimmerlynx", "Epic", 2, "IceCave", 9, 3.82, "a sleek sitting lynx with big tufted ears, a cheek ruff and a fan of glowing aurora ribbons rising from its head", "the aurora crest")
_stub("Kettlepuff", "Common", 2, "GeyserField", 6, 2.20, "a round kettle with a curved spout, a looped handle behind, a lid knob and a ring of steam puffs floating above", "the spout and the steam ring")
_stub("Toastoad", "Uncommon", 2, "GeyserField", 7, 1.98, "a wide squat toad with bulging eye-bumps, a wrinkled ridged back and a lumpy pebble backpack", "the pebble backpack")
_stub("Emberchin", "Uncommon", 2, "GeyserField", 8, 2.24, "a flat-topped dome urchin wearing a spiked rim of twelve horizontal ember-tipped quills like a sun-hat brim, mid-hop", "the ember-tipped quill brim")
_stub("Capybubble", "Rare", 2, "GeyserField", 8, 2.98, "a long barrel-shaped capybara loafing low with a tangerine on its head and a string of bubbles rising from its snoring mouth", "the tangerine hat and the snore bubbles")
_stub("Frostfang", "Epic", 2, "Snowfield", 9, 3.37, "a stocky sabre-tooth cub with two long icicle fangs hanging from a wide-open mouth and a spiked ruff of ice quills round its neck", "the icicle fangs")
_stub("Skaddle", "Legendary", 2, "Snowfield", 9, 3.98, "an upright round snow owl with big frosty ear-tufts and wings out like ski poles, standing on two tiny skis, a snow-ring halo above", "the tiny skis and the frosty crest")
_stub("Fenripup", "Cosmic", 2, "Snowfield", 9, 4.05, "a big floppy-eared puppy sitting, thick curled tail, a glowing crescent moon on its forehead and a ring of orbiting stars", "the forehead moon")


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
    return {"prim": s["prim"], "slot": s["slot"], "loc": loc, "rot": R, "scale": s["scale"], "segments": s["segments"],
            "flat": s.get("flat", not SMOOTH_BY_DEFAULT[s["prim"]]), "minor": s.get("minor", 0.25), "mseg": s.get("mseg", 6),
            "tip": s.get("tip", 0.0), "half": s.get("half"), "name": s["name"] or s["prim"]}


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
    raise ValueError("unknown primitive %r" % prim)


def part_bbox(p):
    """(lo, hi) corners of a bound on the part (exact for ellipsoids, boxes, cylinders, cones; a cylinder bound for a torus)."""
    R, s, c = p["rot"], p["scale"], p["loc"]
    prim = p["prim"]
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
    if tris > TRI_BUDGET:
        problems.append("%d triangles is over the %d cap" % (tris, TRI_BUDGET))
    elif tris > TRI_GUIDE[rec["tier"]]:
        problems.append("note: %d triangles is over the %d target for %s" % (tris, TRI_GUIDE[rec["tier"]], rec["tier"]))
    if abs(height - rec["height"]) > 0.03 * rec["height"]:
        problems.append("height %.2f is more than 3 percent off %.2f (the builder would rescale by %.3f)" % (height, rec["height"], rec["height"] / height))
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
    """Ids from a comma list, 'world1' (every recipe), 'batchN' or 'all'."""
    out = []
    for token in [t.strip() for t in spec.split(",") if t.strip()]:
        if token in ("all", "world1"):
            out += [k for k, v in RECIPES.items() if v["status"] == "recipe" and (token == "all" or v["world"] == 1)]
        elif re.fullmatch(r"batch\d+", token):
            out += [k for k, v in RECIPES.items() if v["batch"] == int(token[5:])]
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
