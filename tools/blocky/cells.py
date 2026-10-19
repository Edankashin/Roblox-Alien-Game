#!/usr/bin/env python3
"""Block-cell textures (Decision B44): every face of every block is a grid of small square cells, each a flat square a shade off its slot
colour, darker at the block's edges and lighter along its top, with a motif per material. The rules are the "Cells" section of
docs/vault/06-art-pipelines/Blocky-Style.md; every number below is one of them.

The pieces, all standard library (Blender's Python has no Pillow, and the build imports this module):

  * `islands(parts, cell)`  one island per visible face of every block: a box projection in the part's own frame, so cells are square, the
    same size on every block and on one grid with their neighbours; faces hidden inside or under another static block are culled
  * `pack(islands)`         shelf-packs the islands into one atlas per creature (a power of two, at most 1024 at 8 texels a cell)
  * `paint(...)`            fills the atlas: the motif, the edge rule, the jitter, and the face drawn cell for cell on the head's front
  * `uv(island, u, v)`      the atlas coordinate of a point on a face, for the build's UV layer

Pillow is used only by the swatch sheet. Deterministic: every random choice is a hash of the cell's grid position and a fixed seed.

  python3 -I tools/blocky/cells.py --swatches <out.png>                       # every material motif as a 4 x 4 stud swatch (Pillow)
  python3 -I tools/blocky/cells.py --swatches-cold <out.png>                  # World 2's six cold motifs (snow, packed snow, ice, frozen water, pine, fur)
  python3 -I tools/blocky/cells.py --atlas docs/vault/07-alien-game/Creatures/Mossbop.md --out <dir>   # one creature's atlas PNG
  python3 -I tools/blocky/cells.py --stats docs/vault/07-alien-game/Creatures/*.md                     # cell size, islands, atlas size
"""
from __future__ import annotations

import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import raster  # noqa: E402
import spec as S  # noqa: E402

# ------------------------------------------------------------------------------------------------ the numbers (Blocky-Style.md, "Cells")
WORLD_CELL = 0.25       # studs: the cell of the ground and every prop, 4 a stud (the quarter-stud grid of rule 2)
FACE_COLS = 16          # a creature's cell is its face cell: the head's width over the face's 16 columns
PX = 8                  # texels a cell side in the atlas (nearest filtering: the cell is the pixel, PX only buys the grout and a bilinear fallback)
GUTTER = 2              # texels of each island's edge colour repeated round it, so mip levels and bilinear filtering never bleed
ATLAS_MAX = 4096        # a creature fits 1024 at PX 8; the diorama's ground may need more
STEP = 6.0              # L* of one shade step: motifs and edges move in steps
JITTER = 2.5            # L* of one jitter level; a cell takes -1, 0 or +1 level, a hash of its grid position (value only, never hue)
JITTER_SHARE = 0.12     # the share of cells a jitter level down, and the same share up (1 : 6 : 1); the rest sit on the colour itself
EDGE_MIN = 3            # a face needs 3 cells across before it gets an edge; smaller detail blocks stay flat
FACE_FRINGE = 2         # rows at the top of the head's front that keep the head's material motif (Moop's moss fringe); the rest is skin
GROUT = 1               # texels of grout on each cell's right and bottom edge, a step darker: the cells read as little blocks (0 turns it off)
GROUT_STEPS = -1.0      # the grout's shade, times the material's `grout` weight (water has none: a grid on water reads as pool tiles)
SEED = 44               # B44
MATERIALS = S.MATERIALS
DEFAULT_MATERIAL = S.DEFAULT_MATERIAL
# per material: jitter in L*; edge steps (top row of a side, border of a side, rim of a top, border of a bottom); grout weight (default 1)
PARAMS = {
    "skin": {"jitter": 2.5, "side_top": 1.0, "side_edge": -1.0, "top_rim": 0.5, "bottom": -1.0},
    "moss": {"jitter": 2.5, "side_top": 1.0, "side_edge": -1.0, "top_rim": 0.0, "bottom": -1.0},
    "grass": {"jitter": 2.5, "side_top": 0.0, "side_edge": -0.5, "top_rim": -0.5, "bottom": -1.0, "grout": 0.5},
    "dirt": {"jitter": 3.0, "side_top": 0.0, "side_edge": -0.5, "top_rim": -0.5, "bottom": -1.0},
    "stone": {"jitter": 2.5, "side_top": 1.0, "side_edge": -1.0, "top_rim": 0.5, "bottom": -1.0},
    "metal": {"jitter": 1.5, "side_top": 1.0, "side_edge": -1.0, "top_rim": 1.0, "bottom": -1.0},
    "crystal": {"jitter": 1.5, "side_top": 1.0, "side_edge": 1.0, "top_rim": 1.0, "bottom": 0.0},
    "wood": {"jitter": 2.0, "side_top": 0.5, "side_edge": -1.0, "top_rim": 0.0, "bottom": -1.0},
    "water": {"jitter": 1.5, "side_top": 1.0, "side_edge": 0.0, "top_rim": 0.0, "bottom": 0.0, "grout": 0.0},
    "glow": {"jitter": 1.0, "side_top": 0.0, "side_edge": 0.0, "top_rim": 0.0, "bottom": 0.0, "grout": 0.5},
    "wool": {"jitter": 2.5, "side_top": 1.0, "side_edge": -1.0, "top_rim": 0.5, "bottom": -1.0},
    # World 2 Frostbyte's cold set (Blocky-Style "World 2: Frostbyte palette")
    "snow": {"jitter": 2.0, "side_top": 0.5, "side_edge": -0.5, "top_rim": -1.0, "bottom": -1.0, "grout": 0.5},
    "packed_snow": {"jitter": 2.0, "side_top": 0.0, "side_edge": -0.5, "top_rim": -0.5, "bottom": -1.0},
    "ice": {"jitter": 1.0, "side_top": 1.0, "side_edge": 1.0, "top_rim": 1.0, "bottom": 0.0, "grout": 0.5},
    "frozen_water": {"jitter": 1.0, "side_top": 0.5, "side_edge": 0.0, "top_rim": 0.0, "bottom": 0.0, "grout": 0.0},
    "pine": {"jitter": 2.5, "side_top": 0.5, "side_edge": -1.0, "top_rim": 0.0, "bottom": -1.0},
    "fur": {"jitter": 2.5, "side_top": 1.0, "side_edge": -1.0, "top_rim": 0.5, "bottom": -1.0},
}
# Blender surface per material (the slot's own roughness and metal hold where a material has no entry)
SURFACE = {"water": {"rough": 0.12, "metal": 0.0}, "crystal": {"rough": 0.22, "metal": 0.0}, "metal": {"rough": 0.45, "metal": 0.35},
           "grass": {"rough": 0.85}, "dirt": {"rough": 0.95}, "stone": {"rough": 0.8}, "moss": {"rough": 0.8}, "wood": {"rough": 0.75},
           "snow": {"rough": 0.9}, "packed_snow": {"rough": 0.95}, "ice": {"rough": 0.18, "metal": 0.0}, "frozen_water": {"rough": 0.1, "metal": 0.0},
           "pine": {"rough": 0.85}, "fur": {"rough": 0.7}}

# ------------------------------------------------------------------------------------------------ orientation: a face's axes in the part's frame
# orient: (normal axis, normal sign, (u axis, u sign), (v axis, v sign)). The front (-z) runs u from the viewer's left, which is the creature's
# right (+x), so face column 0 lands where the sheet draws it; sides run v up; the top runs v toward the back.
ORIENTS = {
    "-z": (2, -1, (0, -1), (1, 1)),
    "+z": (2, 1, (0, 1), (1, 1)),
    "+x": (0, 1, (2, -1), (1, 1)),
    "-x": (0, -1, (2, 1), (1, 1)),
    "+y": (1, 1, (0, -1), (2, 1)),
    "-y": (1, -1, (0, -1), (2, -1)),
}
ORIENT_ID = {o: i for i, o in enumerate(ORIENTS)}
MAT_ID = {m: 101 + 17 * i for i, m in enumerate(MATERIALS)}


def kind(orient):
    return "top" if orient == "+y" else ("bottom" if orient == "-y" else "side")


def orient_of(normal):
    """The orient of the box face a (part-frame) normal belongs to: its largest component; ties go y, then z, then x (a wedge's slope is a top)."""
    order = (1, 2, 0)
    axis = max(order, key=lambda a: (abs(normal[a]) + (1e-6 if a == 1 else (5e-7 if a == 2 else 0.0))))
    sign = 1 if normal[axis] >= 0 else -1
    return "%s%s" % ("+" if sign > 0 else "-", "xyz"[axis])


def project(orient, p_local, size):
    """(u, v) in studs on the box face `orient` of a part of `size`, from a point in the part's frame (centred, unrotated)."""
    _, _, (ua, us), (va, vs) = ORIENTS[orient]
    return size[ua] / 2 + us * p_local[ua], size[va] / 2 + vs * p_local[va]


# ------------------------------------------------------------------------------------------------ hashing (deterministic across Pythons)
_MASK = (1 << 64) - 1


def _mix(x):
    x &= _MASK
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & _MASK
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & _MASK
    return x ^ (x >> 31)


def rand(*keys):
    """A float in [0, 1) from integer keys (splitmix64), the same on every run and in every Python."""
    h = SEED * 0x9E3779B97F4A7C15
    for k in keys:
        h = _mix(h ^ ((int(k) & _MASK) + 0x9E3779B97F4A7C15))
    return (h >> 11) / float(1 << 53)


def noise(seed, x, y, spacing):
    """Value noise at cell (x, y): a hash on a lattice every `spacing` cells, smoothly interpolated; in [0, 1)."""
    x0, y0 = x // spacing, y // spacing
    fx = (x - x0 * spacing + 0.5) / spacing
    fy = (y - y0 * spacing + 0.5) / spacing
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = rand(seed, x0, y0), rand(seed, x0 + 1, y0)
    c, d = rand(seed, x0, y0 + 1), rand(seed, x0 + 1, y0 + 1)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def level(n, lo=0.38, hi=0.62):
    return -1 if n < lo else (1 if n > hi else 0)


# ------------------------------------------------------------------------------------------------ colour: shade in L* (CIELAB), keep the hue
def _lin(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _gam(c):
    return 255.0 * (12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055)


_WHITE = (0.95047, 1.0, 1.08883)


def rgb_to_lab(rgb):
    r, g, b = (_lin(c) for c in rgb)
    xyz = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b, 0.2126729 * r + 0.7151522 * g + 0.0721750 * b,
           0.0193339 * r + 0.1191920 * g + 0.9503041 * b)
    f = [t / w for t, w in zip(xyz, _WHITE)]
    f = [v ** (1 / 3) if v > 216 / 24389 else (24389 / 27 * v + 16) / 116 for v in f]
    return 116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2])


def lab_to_rgb(lab):
    L, a, b = lab
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200
    inv = lambda t: t ** 3 if t ** 3 > 216 / 24389 else (116 * t - 16) / (24389 / 27)  # noqa: E731
    x, y, z = inv(fx) * _WHITE[0], inv(fy) * _WHITE[1], inv(fz) * _WHITE[2]
    r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z
    g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z
    bl = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z
    return tuple(_gam(min(max(c, 0.0), 1.0)) if 0.0 <= c <= 1.0 else (-1.0 if c < 0 else 256.0) for c in (r, g, bl))


def _in_gamut(rgb):
    return all(-0.5 <= c <= 255.5 for c in rgb)


_SHADE = {}


def shade(rgb, dl):
    """`rgb` (0 to 255) moved by `dl` in L*, hue and chroma kept; where the result leaves sRGB the chroma gives way first, never the hue."""
    key = (tuple(rgb), round(dl, 3))
    hit = _SHADE.get(key)
    if hit is not None:
        return hit
    L, a, b = rgb_to_lab(rgb)
    L = min(100.0, max(0.0, L + dl))
    out = lab_to_rgb((L, a, b))
    if not _in_gamut(out):
        lo, hi = 0.0, 1.0
        for _ in range(18):
            mid = (lo + hi) / 2
            if _in_gamut(lab_to_rgb((L, a * mid, b * mid))):
                lo = mid
            else:
                hi = mid
        out = lab_to_rgb((L, a * lo, b * lo))
    res = tuple(int(round(min(255.0, max(0.0, c)))) for c in out)
    _SHADE[key] = res
    return res


def hex_rgb(h):
    return S.hex_rgb(h)


# ------------------------------------------------------------------------------------------------ the cell
def creature_cell(spec):
    """A creature's cell in studs: its face cell (the head's width over the face's columns), so face and body are one grid. No face: the world cell."""
    host = S.face_host(spec)
    face = spec.get("face") or {}
    rows = face.get("rows") or []
    if host is None or not rows:
        return WORLD_CELL
    return host["size"][0] / len(rows[0])


def part_material(part):
    m = part.get("material")
    if m:
        return str(m)
    return "glow" if part.get("slot") == "Glow" else DEFAULT_MATERIAL


# ------------------------------------------------------------------------------------------------ islands
def _box(part):
    lo = [part["at"][i] - part["size"][i] / 2 for i in range(3)]
    hi = [part["at"][i] + part["size"][i] / 2 for i in range(3)]
    return lo, hi


def _plain(part):
    return part.get("shape", "box") == "box" and not any(abs(a) > 1e-9 for a in part.get("rot", (0, 0, 0)))


def covered(part, orient, others, eps=1e-6):
    """True when the face `orient` of an unrotated box lies inside, or flat against, one other unrotated static box that spans all of it."""
    if not _plain(part):
        return False
    axis, sign, (ua, _), (va, _) = ORIENTS[orient]
    lo, hi = _box(part)
    c = hi[axis] if sign > 0 else lo[axis]
    for o in others:
        if o is part or not _plain(o) or o.get("moves", "none") != "none":
            continue
        olo, ohi = _box(o)
        inside = (olo[axis] - eps <= c < ohi[axis] - eps) if sign > 0 else (olo[axis] + eps < c <= ohi[axis] + eps)
        if not inside:
            continue
        if all(olo[a] - eps <= lo[a] and hi[a] <= ohi[a] + eps for a in (ua, va)):
            return True
    return False


def _neighbours(parts, statics, bucket=4.0):
    """{id(part): [static boxes whose bounds touch it]}, through a bucket grid, so culling the diorama's thousand ground blocks stays quick."""
    grid = {}

    def keys(p):
        lo, hi = _box(p) if _plain(p) else S.bounds([p])
        return [(a, b, c) for a in range(int(math.floor(lo[0] / bucket)), int(math.floor(hi[0] / bucket)) + 1)
                for b in range(int(math.floor(lo[1] / bucket)), int(math.floor(hi[1] / bucket)) + 1)
                for c in range(int(math.floor(lo[2] / bucket)), int(math.floor(hi[2] / bucket)) + 1)]
    for s in statics:
        if _plain(s):
            for k in keys(s):
                grid.setdefault(k, []).append(s)
    out = {}
    for p in parts:
        seen, lst = set(), []
        for k in keys(p):
            for s in grid.get(k, ()):
                if id(s) not in seen and s is not p:
                    seen.add(id(s))
                    lst.append(s)
        out[id(p)] = lst
    return out


def islands(parts, cell, cull=True, statics=None):
    """One island per face of every part (six for every shape: a wedge's slope, a cone's sides and an icosahedron's facets all fall on the
    face of the box they fill). Hidden faces of plain static boxes are culled when `cull`. Each island: part name, orient, cells (nu, nv),
    the face's size in studs, the cell's world origin, the material and the part itself."""
    statics = statics if statics is not None else [p for p in parts if p.get("moves", "none") == "none"]
    near = _neighbours(parts, statics) if cull else {}
    out = []
    for p in parts:
        for orient, (axis, sign, (ua, us), (va, vs)) in ORIENTS.items():
            # a bevelled mass is built whole (its strips join every face), and a moving part may swing clear: neither loses a face
            if cull and not p.get("bevel") and p.get("moves", "none") == "none" and covered(p, orient, near.get(id(p), ())):
                continue
            su, sv = p["size"][ua], p["size"][va]
            nu, nv = max(1, int(round(su / cell))), max(1, int(round(sv / cell)))
            lo, hi = _box(p)
            # the world position of the island's (u, v) = (0, 0) corner along each axis, for grid-coherent motifs
            u0 = (hi[ua] if us < 0 else lo[ua]) * us
            v0 = (hi[va] if vs < 0 else lo[va]) * vs
            plane = hi[axis] if sign > 0 else lo[axis]
            out.append({"part": p["name"], "orient": orient, "nu": nu, "nv": nv, "su": su, "sv": sv, "u0": u0, "v0": v0, "plane": plane,
                        "cell": cell, "material": part_material(p), "slot": p.get("slot"), "tilted": not _plain(p), "src": p})
    return out


def pack(isl, px=PX, gutter=GUTTER, limit=ATLAS_MAX):
    """Shelf-pack the islands (tallest first) into the smallest power-of-two atlas, at most `limit` wide; sets each island's x, y (its top-left
    texel inside the gutter). Returns (width, height)."""
    sizes = [(i["nu"] * px + 2 * gutter, i["nv"] * px + 2 * gutter) for i in isl]
    order = sorted(range(len(isl)), key=lambda k: (-sizes[k][1], -sizes[k][0], k))
    area = sum(w * h for w, h in sizes)
    best = None
    w = 64
    while w <= limit:
        if max((s[0] for s in sizes), default=0) <= w:
            x = y = row_h = 0
            pos = {}
            for k in order:
                sw, sh = sizes[k]
                if x + sw > w:
                    x, y, row_h = 0, y + row_h, 0
                pos[k] = (x, y)
                x += sw
                row_h = max(row_h, sh)
            used = y + row_h
            h = 64
            while h < used:
                h *= 2
            if h <= limit:
                cand = (w * h, abs(math.log2(w / h)), w, h, pos)
                if best is None or cand[:2] < best[:2]:
                    best = cand
        if w * w >= area * 4:
            break
        w *= 2
    if best is None:
        raise ValueError("the islands do not fit a %d atlas; lower PX" % limit)
    _, _, w, h, pos = best
    for k, (x, y) in pos.items():
        isl[k]["x"], isl[k]["y"] = x + gutter, y + gutter
    return w, h


def uv(island, u, v, width, height, px=PX):
    """The atlas coordinate (Blender's: v up from the bottom) of the point (u, v) studs on the island's face."""
    tx = island["x"] + (u / island["su"]) * island["nu"] * px
    ty = island["y"] + (1.0 - v / island["sv"]) * island["nv"] * px
    return tx / width, 1.0 - ty / height


# ------------------------------------------------------------------------------------------------ motifs
class Cell:
    """What a motif sees of one cell: its place on the face (i from the left, j from the bottom), the face's size in cells, the cell's
    grid position (gu, gv; continuous across neighbouring blocks), the face's kind and the part it belongs to."""
    __slots__ = ("i", "j", "nu", "nv", "gu", "gv", "plane", "orient", "kind", "part", "mat")

    def __init__(self, i, j, nu, nv, gu, gv, plane, orient, part, mat):
        self.i, self.j, self.nu, self.nv = i, j, nu, nv
        self.gu, self.gv, self.plane, self.orient = gu, gv, plane, orient
        self.kind = kind(orient)
        self.part, self.mat = part, mat

    @property
    def depth(self):
        """Rows from the top of a side face (0 is the top row)."""
        return self.nv - 1 - self.j


def _skin(c):
    return "base", 0.0


MOSS_AMP, MOSS_CLUMP = 1.0, 3   # moss tufts a full step light or dark, in clumps about three cells across (the moss test in the bible)


def _moss(c):
    # tufts: soft blobs of light and shade a few cells across, the sunlit top a half step up, the shaded foot a half step down; lime
    # sprigs (the accent) dot the top; on a side the top moss hangs down in a ragged fringe a step lighter than the moss under it
    n = noise(MAT_ID["moss"] + c.plane, c.gu, c.gv, MOSS_CLUMP)
    lvl = MOSS_AMP * level(n, 0.4, 0.6)
    if c.kind == "top":
        if rand(7, c.gu, c.gv, c.plane) < 0.025:
            return "accent", 0.0
        return "base", lvl + 0.5
    if c.kind == "side":
        drip = 2 + int(rand(3, c.gu, c.plane) * 3)
        if c.depth < drip:
            if c.depth == 0 and rand(9, c.gu, c.plane) < 0.07:
                return "accent", 0.0
            return "base", lvl + 0.6
        return "base", lvl - 0.5 - (0.5 if c.j == 0 else 0.0)
    return "base", lvl - 1.0


def _dirt(c, key="base"):
    # packed earth: faint blobs, a pebble every twenty cells or so (a step up or down), no lines
    n = noise(MAT_ID["dirt"] + c.plane, c.gu, c.gv, 3)
    lvl = 0.5 * level(n, 0.36, 0.64)
    r = rand(11, c.gu, c.gv, c.plane)
    if r < 0.03:
        lvl += 1.0
    elif r > 0.97:
        lvl -= 1.0
    return key, lvl


def _grass(c):
    # the top is grass: faint blobs and a light blade cell now and then; the sides are dirt (the `second` colour) under a grass fringe one to
    # three cells deep, its top row lit
    if c.kind == "top":
        n = noise(MAT_ID["grass"] + c.plane, c.gu, c.gv, 4)
        lvl = 0.5 * level(n, 0.36, 0.64)
        if rand(13, c.gu, c.gv, c.plane) < 0.05:
            lvl += 1.0
        return "base", lvl
    if c.kind == "side":
        depth = 1 + (rand(15, c.gu, c.plane) < 0.55) + (rand(17, c.gu, c.plane) < 0.2)
        if c.depth < depth:
            return "base", (0.5 if c.depth == 0 else 0.0)
        return _dirt(c, "aux")
    return _dirt(c, "aux")


def _region(gu, gv, s=3):
    """The cobble a cell belongs to: the nearest of the seed points scattered one to a 3 x 3 lattice square."""
    cx, cy = gu // s, gv // s
    best, rid = 1e9, (cx, cy)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            ax, ay = cx + dx, cy + dy
            px_ = ax * s + 0.5 + rand(21, ax, ay) * (s - 1)
            py_ = ay * s + 0.5 + rand(23, ax, ay) * (s - 1)
            d = (gu + 0.5 - px_) ** 2 + (gv + 0.5 - py_) ** 2
            if d < best:
                best, rid = d, (ax, ay)
    return rid


def _stone(c):
    # cobbles about three cells across, each a quarter step off the others, parted by a one-cell crack a step and a half darker (drawn on
    # one side of each border only, so cracks stay one cell wide); the top a half step up
    rid = _region(c.gu, c.gv)
    if _region(c.gu + 1, c.gv) != rid or _region(c.gu, c.gv - 1) != rid:
        return "base", -1.5
    lv = (-0.75, 0.0, 0.0, 0.75)[int(rand(25, rid[0], rid[1], c.plane) * 4)]
    return "base", lv + (0.5 if c.kind == "top" else 0.0)


def _metal(c):
    # panels four cells square: a seam a step down along two sides, a rivet a step and a half up inside each panel's corner, a faint
    # brushed row now and then; a face under four cells across is one plain plate
    if c.nu < 4 or c.nv < 4:
        return "base", 0.0
    if c.gu % 4 == 0 or c.gv % 4 == 0:
        return "base", -1.0
    if c.gu % 4 == 1 and c.gv % 4 == 3:
        return "base", 1.5
    return "base", (0.3 if rand(27, c.gv, c.plane) < 0.3 else 0.0)


def _crystal(c):
    # facets: a light diagonal band every six cells (two steps up, then one), a half-step shadow between; its edges catch the light
    d = (c.gu + c.gv) % 6
    return "base", {0: 2.0, 1: 1.0, 3: -0.5}.get(d, 0.0)


def _wood(c):
    # grain along the block's longest side: each grain line a fixed shade (a step down, level, or a half up), broken every few cells; a
    # knot now and then; on end grain, square rings
    size = c.part["size"]
    _, _, (ua, _), (va, _) = ORIENTS[c.orient]
    longest = max(range(3), key=lambda a: size[a])
    if longest not in (ua, va):
        ci, cj = (c.nu - 1) / 2.0, (c.nv - 1) / 2.0
        r = int(max(abs(c.i - ci), abs(c.j - cj)) + 0.5)
        return "base", (-1.0 if r == 0 else (-0.6 if r % 2 else 0.2))
    line, along = (c.gu, c.gv) if longest == va else (c.gv, c.gu)
    lv = (-1.0, 0.0, 0.0, 0.5)[int(rand(29, line, c.plane) * 4)]
    if rand(31, line, along // 4, c.plane) < 0.18:
        lv = 0.0
    if rand(33, line, along, c.plane) < 0.02:
        lv = -1.75
    return "base", lv


def _water(c):
    # ripples: short light dashes on a diagonal, a sparkle cell now and then; a side darkens with depth, a half step every two rows
    if c.kind == "top":
        if (c.gu + 2 * c.gv) % 9 == 0 and rand(35, c.gu // 3, c.gv) < 0.7:
            return "base", 1.0
        if rand(37, c.gu, c.gv) < 0.012:
            return "base", 2.5
        return "base", 0.3 * level(noise(MAT_ID["water"], c.gu, c.gv, 4))
    if c.kind == "side":
        return "base", -min(2.0, 0.5 * (c.depth // 2))
    return "base", -2.0


def _glow(c):
    # emissive cells: a lit core half a step up inside a border at the colour itself (only on faces three cells or more across); a full
    # step washes a light glow colour to white
    if c.nu >= EDGE_MIN and c.nv >= EDGE_MIN and 0 < c.i < c.nu - 1 and 0 < c.j < c.nv - 1:
        return "base", 0.5
    return "base", 0.0


def _wool(c):
    # shag: soft blobs two cells across, a half step either way, the top a half step up; one cell in thirty a fleck of the accent colour, so
    # a dark coat still sparkles in daylight (Syrinx's violet)
    if rand(43, c.gu, c.gv, c.plane) < 0.035:
        return "accent", 0.0
    lvl = 0.6 * level(noise(MAT_ID["wool"] + c.plane, c.gu, c.gv, 2), 0.4, 0.6)
    return "base", lvl + (0.5 if c.kind == "top" else 0.0)


# ---- World 2 Frostbyte's cold set. Each moves cells in whole or half steps on a pattern a viewer can name (C6: never noise).
SNOW_LIP = (2, 4)       # a snow top hangs over a side in a drift lip two to four cells deep (deeper than the grass fringe: snow drifts)
SNOW_SPARKLE = 0.016    # one top cell in sixty catches the light, a full step up
PACKED_STRATA = 3       # packed snow: a strata line every third row, the fallen layers
ICE_BAND = 8            # ice: a light band every eight cells on the other diagonal to crystal's six
FROZEN_PLATE = 7        # the frozen pond: plates about seven cells across, cracks on about six borders in ten
FUR_LATTICE = 3         # fur: one tuft in a three-by-three lattice square, in about half the squares


def _packed_snow(c, key="base"):
    # packed snow: strata, a line a half step down every third row (the fallen layers), broken every few cells; an ice grain in
    # twenty-five a half step up; a top face (rare: packed snow lies under snow) is soft blobs instead
    if c.kind == "top":
        n = noise(MAT_ID["packed_snow"] + c.plane, c.gu, c.gv, 4)
        return key, 0.5 * level(n, 0.36, 0.64)
    lvl = 0.0
    if c.gv % PACKED_STRATA == 0 and rand(57, c.gu // 3, c.gv, c.plane) < 0.8:
        lvl = -0.5
    if rand(59, c.gu, c.gv, c.plane) < 0.04:
        lvl += 0.75
    return key, lvl


def _snow(c):
    # the snow top: soft drifts (half-step blobs five cells across) and a sparkle cell in sixty a full step up; a side is the snow lip, two to
    # four cells deep, its top row lit and its ragged bottom row a step down (the drift's shadow), over packed snow (the `aux` colour); the bottom is packed snow
    if c.kind == "top":
        n = noise(MAT_ID["snow"] + c.plane, c.gu, c.gv, 5)
        lvl = 0.5 * level(n, 0.33, 0.67)
        if rand(51, c.gu, c.gv, c.plane) < SNOW_SPARKLE:
            lvl += 1.0
        return "base", lvl
    if c.kind == "side":
        lip = SNOW_LIP[0] + (rand(53, c.gu, c.plane) < 0.5) + (rand(55, c.gu, c.plane) < 0.25)
        if c.depth < lip:
            return "base", (0.5 if c.depth == 0 else (-1.0 if c.depth == lip - 1 else 0.0))
        return _packed_snow(c, "aux")
    return _packed_snow(c, "aux")


def _ice(c):
    # clear ice, as crystal but colder: a light band every eight cells on the other diagonal (a step and a half up, then a half), a faint
    # crossing band a half step down on crystal's diagonal, a sparkle cell in seventy two steps up; its edges catch the light (PARAMS)
    d = (c.gu - c.gv) % ICE_BAND
    lvl = {0: 1.5, 1: 0.5}.get(d, 0.0)
    if (c.gu + c.gv) % ICE_BAND == ICE_BAND // 2:
        lvl -= 0.5
    if rand(61, c.gu, c.gv, c.plane) < 0.014:
        lvl = 2.0
    return "base", lvl


def _frozen_water(c):
    # the pond, frozen: a pale top in plates about seven cells across, parted by cracks one cell wide a step and a half down that run on
    # about six borders in ten (so they read as cracks, not tiles); a trapped bubble a half step up in forty; no grout; a side darkens with
    # depth as water does, a half step every two rows
    if c.kind == "top":
        rid = _region(c.gu, c.gv, FROZEN_PLATE)
        for other in (_region(c.gu + 1, c.gv, FROZEN_PLATE), _region(c.gu, c.gv - 1, FROZEN_PLATE)):
            if other != rid:
                a, b = sorted((rid, other))
                if rand(63, a[0], a[1], b[0], b[1], c.plane) < 0.6:
                    return "base", -1.5
        if rand(67, c.gu, c.gv, c.plane) < 0.025:
            return "base", 0.5
        return "base", 0.25 * level(noise(MAT_ID["frozen_water"] + c.plane, c.gu, c.gv, 5), 0.3, 0.7)
    if c.kind == "side":
        return "base", -min(2.0, 0.5 * (c.depth // 2))
    return "base", -2.0


def _pine(c):
    # needle rows: on a side, fronds two cells tall, the top row of each a half step up and its underside a half step down, broken every few
    # cells so the fronds hang in ragged layers; a lit needle tip (the accent: snow dust on a snow pine) in forty; a top in square rings
    if rand(65, c.gu, c.gv, c.plane) < 0.025:
        return "accent", 0.0
    if c.kind == "top":
        ci, cj = (c.nu - 1) / 2.0, (c.nv - 1) / 2.0
        r = int(max(abs(c.i - ci), abs(c.j - cj)) + 0.5)
        return "base", (0.5 if r % 2 else -0.25)
    if rand(69, c.gu // 3, c.gv // 2, c.plane) < 0.2:
        return "base", 0.0
    return "base", (0.5 if c.gv % 2 else -0.5)


def _fur(c):
    # soft flecks for cold-world bodies: in each three-by-three lattice square one tuft at a hashed spot, in about half the squares, two
    # cells tall (a half step down over three quarters down; one tuft in four, and every tuft on a top face, lit instead); nothing else
    # moves, so the coat reads as fur with a few tufts, never as noise
    ax, ay = c.gu // FUR_LATTICE, c.gv // FUR_LATTICE
    for lx, ly in ((ax, ay), (ax, ay - 1)):   # a tuft may start in the square below and reach up into this one
        if rand(71, lx, ly, c.plane) < 0.5:
            tx = lx * FUR_LATTICE + int(rand(73, lx, ly, c.plane) * FUR_LATTICE)
            ty = ly * FUR_LATTICE + int(rand(75, lx, ly, c.plane) * (FUR_LATTICE - 1))
            if c.gu == tx and ty <= c.gv <= ty + 1:
                lit = c.kind == "top" or rand(77, lx, ly, c.plane) < 0.25   # on a top, and on one tuft in four, the tuft catches the light
                return "base", (0.5 if lit else -0.5) if c.gv == ty else (0.25 if lit else -0.75)
    return "base", 0.0


MOTIFS = {"skin": _skin, "moss": _moss, "grass": _grass, "dirt": _dirt, "stone": _stone, "metal": _metal, "crystal": _crystal,
          "wood": _wood, "water": _water, "glow": _glow, "wool": _wool,
          "snow": _snow, "packed_snow": _packed_snow, "ice": _ice, "frozen_water": _frozen_water, "pine": _pine, "fur": _fur}


def edge_steps(c, params):
    """The edge rule: on a side, the top row a step lighter and the other border cells a step darker; a top's rim and a bottom's border by
    the material. Only along a direction three cells or more across."""
    wide, tall = c.nu >= EDGE_MIN, c.nv >= EDGE_MIN
    on_lr = wide and (c.i == 0 or c.i == c.nu - 1)
    on_tb = tall and (c.j == 0 or c.j == c.nv - 1)
    if c.kind == "side":
        if tall and c.j == c.nv - 1:
            return params["side_top"]
        if on_lr or (tall and c.j == 0):
            return params["side_edge"]
        return 0.0
    if on_lr or on_tb:
        return params["top_rim"] if c.kind == "top" else params["bottom"]
    return 0.0


def jitter_level(c):
    r = rand(41, MAT_ID[c.mat], ORIENT_ID[c.orient], c.plane, c.gu, c.gv)
    return -1 if r < JITTER_SHARE else (1 if r >= 1.0 - JITTER_SHARE else 0)


def cell_colour(c, colours, face_rgb=None, flat=False):
    """The flat colour of one cell. `colours`: {'base', 'aux', 'accent'} as RGB. `face_rgb`: the face's own colour for a face cell that is
    not the head's body colour (the ink, the shine, the crescent, the cheeks): it is drawn exactly, never shaded."""
    if face_rgb is not None:
        return face_rgb
    if flat:
        return colours["base"]
    params = PARAMS.get(c.mat, PARAMS["skin"])
    key, steps = MOTIFS.get(c.mat, _skin)(c)
    rgb = colours.get(key) or colours["base"]
    dl = (steps + edge_steps(c, params)) * STEP + jitter_level(c) * params["jitter"]
    return shade(rgb, dl)


def island_cells(island, colours, face=None, flat=False):
    """[(i, j, rgb)] for every cell of one island. `face`: {'rows', 'rgb': {char: rgb}, 'body': set of chars} on the host's front."""
    out = []
    cell = island["cell"]
    plane = int(round(island["plane"] / cell * 2))
    for j in range(island["nv"]):
        for i in range(island["nu"]):
            gu = int(math.floor((island["u0"] + (i + 0.5) * island["su"] / island["nu"]) / cell))
            gv = int(math.floor((island["v0"] + (j + 0.5) * island["sv"] / island["nv"]) / cell))
            mat = island["material"]
            frgb = None
            if face is not None:
                ch = face["rows"][island["nv"] - 1 - j][i]
                if ch not in face["body"]:
                    frgb = face["rgb"][ch]
                elif island["nv"] - 1 - j >= FACE_FRINGE:
                    mat = "skin"  # the face stays calm: below a two-row fringe the head's front is plain skin cells, whatever its material
            c = Cell(i, j, island["nu"], island["nv"], gu, gv, plane, island["orient"], island["src"], mat)
            out.append((i, j, cell_colour(c, colours, frgb, flat)))
    return out


def paint(isl, width, height, colours_of, face=None, px=PX, gutter=GUTTER, grout=GROUT, background=(255, 0, 255), flat=False):
    """The atlas as RGB bytes, row 0 at the top. `colours_of(island)` gives the island's {'base', 'aux', 'accent'}; `face` (as island_cells)
    applies to the island whose part is face['part'] and orient is the front. Each island's edge texels repeat into its gutter. `flat`
    paints every cell its slot colour (the face still drawn): the look before cells, for the before-and-after sheet."""
    buf = bytearray(bytes(background) * (width * height))
    stride = width * 3
    for isl_ in isl:
        f = face if (face is not None and isl_["part"] == face.get("part") and isl_["orient"] == "-z") else None
        if f is not None and (len(f["rows"]) != isl_["nv"] or len(f["rows"][0]) != isl_["nu"]):
            raise ValueError("the face is %dx%d cells but the head's front is %dx%d" % (len(f["rows"][0]), len(f["rows"]), isl_["nu"], isl_["nv"]))
        cols = colours_of(isl_)
        x0, y0, nv = isl_["x"], isl_["y"], isl_["nv"]
        weight = 0.0 if flat else PARAMS.get(isl_["material"], PARAMS["skin"]).get("grout", 1.0)
        for i, j, rgb in island_cells(isl_, cols, f, flat):
            row_px = bytes(rgb) * px
            gx = x0 + i * px
            gy = y0 + (nv - 1 - j) * px
            for r in range(px):
                k = (gy + r) * stride + gx * 3
                buf[k:k + px * 3] = row_px
            if grout and weight:
                dark = bytes(shade(rgb, GROUT_STEPS * STEP * weight))
                for r in range(px):
                    k = (gy + r) * stride + (gx + px - grout) * 3
                    buf[k:k + grout * 3] = dark * grout
                for r in range(px - grout, px):
                    k = (gy + r) * stride + gx * 3
                    buf[k:k + px * 3] = dark * px
        # the gutter: repeat the island's edge texels outward
        w_px, h_px = isl_["nu"] * px, isl_["nv"] * px
        for r in range(h_px):
            k = (y0 + r) * stride
            left = buf[k + x0 * 3:k + x0 * 3 + 3]
            right = buf[k + (x0 + w_px - 1) * 3:k + (x0 + w_px) * 3]
            buf[k + (x0 - gutter) * 3:k + x0 * 3] = left * gutter
            buf[k + (x0 + w_px) * 3:k + (x0 + w_px + gutter) * 3] = right * gutter
        top = buf[y0 * stride + (x0 - gutter) * 3:y0 * stride + (x0 + w_px + gutter) * 3]
        bot = buf[(y0 + h_px - 1) * stride + (x0 - gutter) * 3:(y0 + h_px - 1) * stride + (x0 + w_px + gutter) * 3]
        for g in range(1, gutter + 1):
            k = (y0 - g) * stride + (x0 - gutter) * 3
            buf[k:k + len(top)] = top
            k = (y0 + h_px - 1 + g) * stride + (x0 - gutter) * 3
            buf[k:k + len(bot)] = bot
    return buf


# ------------------------------------------------------------------------------------------------ a creature's atlas, end to end
def creature_colours(spec):
    """colours_of(island) for a creature: the slot's colour as the base, the palette's second and accent as aux and accent."""
    pal = {r: hex_rgb(h) for r, h in S.palette(spec).items()}

    def colours_of(island):
        base = pal[S.SLOT_ROLE[island["slot"]]]
        return {"base": base, "aux": pal.get("second", base), "accent": pal.get("accent", base), "glow": pal.get("glow", base)}
    return colours_of


def face_cells(spec):
    """The face as the painter takes it: the host's name, the rows, each character's RGB, and which characters are the head's own colour."""
    face = spec.get("face")
    host = S.face_host(spec)
    if not face or host is None:
        return None
    legend = face.get("legend") or {}
    body_role = S.SLOT_ROLE[host["slot"]]
    return {"part": host["name"], "rows": face["rows"], "rgb": {ch: hex_rgb(S.face_colour(spec, ch)) for ch in legend},
            "body": {ch for ch, v in legend.items() if str(v) == body_role}}


def atlas(spec, px=PX, gutter=GUTTER, grout=GROUT, cell=None, flat=False, parts=None):
    """Plan, pack and paint one creature (or prop): {'cell', 'islands', 'width', 'height', 'rgb'}."""
    parts = parts if parts is not None else S.expand(spec["parts"])
    cell = cell or creature_cell(spec)
    isl = islands(parts, cell)
    w, h = pack(isl, px, gutter)
    rgb = paint(isl, w, h, creature_colours(spec), face_cells(spec), px, gutter, grout, flat=flat)
    return {"cell": cell, "islands": isl, "width": w, "height": h, "rgb": rgb}


def write_atlas(spec, path, **kw):
    a = atlas(spec, **kw)
    raster.write_png(str(path), a["width"], a["height"], a["rgb"], 3)
    return a


# ------------------------------------------------------------------------------------------------ the swatch sheet (Pillow)
# World 1 colours for the swatches: the meadow's own (src/shared/data/Meadow.luau: floor 6FBF4A, rock 8E8E8E, trunk 7B4A2D, leaves 3F9B3A)
SWATCH = [
    ("skin", "#FF7A30", None, None, "the creature default (Vixa's orange)"),
    ("moss", "#6CCB5F", None, "#D9F36B", "Moop, leaf clumps: tufts, a lit fringe"),
    ("grass", "#6FBF4A", "#8A5A3B", None, "ground tops; sides dirt under a fringe"),
    ("dirt", "#8A5A3B", None, None, "the ground under the grass"),
    ("stone", "#9E9E8E", None, None, "rocks and the path: cobbles"),
    ("metal", "#B8C2CF", None, None, "the ship, trim: panels, rivets"),
    ("crystal", "#7FE3F0", None, None, "crystals, wings: light diagonals"),
    ("wood", "#7B4A2D", None, None, "trunks, roots, reeds: grain rows"),
    ("water", "#3FA2E6", None, None, "the pond: ripples, a sparkle"),
    ("glow", "#FFE36B", None, None, "emissive cells, used sparingly"),
    ("wool", "#4A4166", None, "#8E6BFF", "Syrinx's coat: shag, accent flecks"),
]
# World 2 colours for the cold swatches (Blocky-Style "World 2: Frostbyte palette": snow F2F6FA over packed snow B9CADA, ice BFEBFA,
# the frozen pond A9D6F5, pine needles 2F6B5E dusted with snow, Sabrek's blue coat 4F9BD8)
SWATCH_COLD = [
    ("snow", "#F2F6FA", "#B9CADA", None, "ground tops: drifts, a sparkle; sides a snow lip over packed snow"),
    ("packed_snow", "#B9CADA", None, None, "under the snow: strata, ice grains"),
    ("ice", "#BFEBFA", None, None, "the cave, the arch, icicles: the other diagonal"),
    ("frozen_water", "#A9D6F5", None, None, "the pond: plates and cracks, a bubble"),
    ("pine", "#2F6B5E", None, "#F2F6FA", "pine crowns: needle rows, snow dust"),
    ("fur", "#4F9BD8", None, None, "cold-world bodies: tufts on a lattice"),
]


def swatch_faces(material, base, aux=None, accent=None, studs=4, cell=WORLD_CELL, px=PX):
    """{orient: (w, h, RGB bytes)}: the top, front and left faces of a `studs` cube painted in one material, row 0 at the top."""
    part = {"name": "Swatch", "slot": "Body", "size": [studs, studs, studs], "at": [0, studs / 2, 0], "rot": [0, 0, 0], "shape": "box",
            "moves": "none", "material": material}
    isl = [i for i in islands([part], cell, cull=False) if i["orient"] in ("+y", "-z", "-x")]
    cols = {"base": hex_rgb(base), "aux": hex_rgb(aux or base), "accent": hex_rgb(accent or base)}
    out = {}
    for i in isl:
        i["x"] = i["y"] = 0
        w, h = i["nu"] * px, i["nv"] * px
        out[i["orient"]] = (w, h, paint([i], w, h, lambda _i: cols, None, px, 0))
    return out


def swatch_cube(imgs, s):
    """A 2:1 dimetric cube from three s x s face images (Pillow), nearest-neighbour so every cell stays a crisp parallelogram: the top as a
    rhombus, the front on the left, the left side on the right (the view from the front-left), the sides a little shaded."""
    from PIL import Image
    near = Image.Resampling.NEAREST
    canvas = Image.new("RGBA", (2 * s, 2 * s), (0, 0, 0, 0))

    def put(img, data, dim):
        warped = img.convert("RGBA").transform((2 * s, 2 * s), Image.Transform.AFFINE, data, resample=near, fillcolor=(0, 0, 0, 0))
        if dim:
            black = Image.new("RGBA", warped.size, (0, 0, 0, int(255 * dim)))
            warped = Image.alpha_composite(warped, Image.composite(black, Image.new("RGBA", warped.size, (0, 0, 0, 0)), warped))
        canvas.alpha_composite(warped)
    # inverse maps (output X, Y -> input x, y): top from the left corner (0, s/2), x up-right and y down-right; sides straight down
    put(imgs["-z"], (1.0, 0.0, 0.0, -0.5, 1.0, -s / 2), 0.12)
    put(imgs["-x"], (1.0, 0.0, -s, 0.5, 1.0, -1.5 * s), 0.26)
    put(imgs["+y"], (0.5, -1.0, s / 2, 0.5, 1.0, -s / 2), 0.0)
    return canvas


def swatch_sheet(path, px=PX, swatches=None, title=None):
    """Every material as a 4 x 4 stud swatch: a small cube (top and two sides) and its front face flat, with the motif's name, use and
    colours. The board image for the Claude Design canvas (Pillow). `swatches` picks a set (SWATCH, the World 1 eleven, by default;
    SWATCH_COLD is World 2's six)."""
    swatches = SWATCH if swatches is None else swatches
    title = title or "Cell materials (Blocky-Style, Cells): each motif on a 4 x 4 stud block, 4 cells a stud, World 1 colours"
    from PIL import Image, ImageDraw, ImageFont
    try:
        bold = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 22)
        reg = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 15)
    except OSError:
        bold = reg = ImageFont.load_default()
    s = 16 * px
    cube_s = int(s * 0.8)
    tile_w, tile_h = 2 * cube_s + s + 40, 2 * cube_s + 70
    cols = 4
    rows = (len(swatches) + cols - 1) // cols
    W, H = cols * tile_w + 30, rows * tile_h + 100
    sheet = Image.new("RGB", (W, H), "#F6F0E6")
    d = ImageDraw.Draw(sheet)
    d.text((20, 16), title, font=bold, fill="#1B1F3B")
    d.text((20, 48), "Flat square cells, nearest filtering. Jitter in value only (L* %.1f, %d%% of cells down and %d%% up); a step (L* %d) darker at the "
           "edges, lighter along the top; a %d-texel grout a step down; a motif per material" % (JITTER, JITTER_SHARE * 100, JITTER_SHARE * 100,
                                                                                               STEP, GROUT), font=reg, fill="#5F6375")
    for k, (mat, base, aux, accent, note) in enumerate(swatches):
        faces = swatch_faces(mat, base, aux, accent, px=px)
        imgs = {o: Image.frombytes("RGB", (w, h), bytes(b)) for o, (w, h, b) in faces.items()}
        ox, oy = 20 + (k % cols) * tile_w, 84 + (k // cols) * tile_h
        cube = swatch_cube(imgs, s).resize((2 * cube_s, 2 * cube_s), Image.Resampling.NEAREST)
        sheet.paste(cube, (ox, oy), cube)
        flat = imgs["-z"]
        sheet.paste(flat, (ox + 2 * cube_s + 16, oy + cube_s - s // 2))
        ty = oy + 2 * cube_s - 6
        d.text((ox, ty), mat, font=bold, fill="#1B1F3B")
        d.text((ox + max(110, int(d.textlength(mat, font=bold)) + 14), ty + 4), note, font=reg, fill="#5F6375")
        d.text((ox, ty + 28), "  ".join(h for h in (base, aux, accent) if h), font=reg, fill="#5F6375")
    sheet.save(path)
    return path


def stats(paths):
    rows = []
    for p in paths:
        spec = S.load(p)
        a = atlas(spec)
        cells = sum(i["nu"] * i["nv"] for i in a["islands"])
        h = S.counts(spec)["height"]
        rows.append((spec["front"]["id"], spec["front"]["tier"], a["cell"], 1 / a["cell"], h / a["cell"], len(a["islands"]), cells, a["width"], a["height"]))
    return rows


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if "--swatches" in argv:
        print(swatch_sheet(argv[argv.index("--swatches") + 1]))
        return 0
    if "--swatches-cold" in argv:
        print(swatch_sheet(argv[argv.index("--swatches-cold") + 1], swatches=SWATCH_COLD,
                           title="Cell materials, the cold set (Blocky-Style, World 2: Frostbyte palette): each motif on a 4 x 4 stud block, 4 cells a stud"))
        return 0
    if "--atlas" in argv:
        note = argv[argv.index("--atlas") + 1]
        out = pathlib.Path(argv[argv.index("--out") + 1]) if "--out" in argv else pathlib.Path(".")
        out.mkdir(parents=True, exist_ok=True)
        spec = S.load(note)
        path = out / ("%s_cells.png" % spec["front"]["id"])
        a = write_atlas(spec, path)
        print("%s cell %.4f studs, %d islands, atlas %dx%d -> %s" % (spec["front"]["id"], a["cell"], len(a["islands"]), a["width"], a["height"], path))
        return 0
    if "--stats" in argv:
        paths = [a for a in argv if not a.startswith("--")]
        print("%-12s %-9s %8s %8s %10s %7s %6s %s" % ("id", "tier", "cell", "per stud", "cells tall", "islands", "cells", "atlas"))
        for r in stats(paths):
            print("%-12s %-9s %8.4f %8.2f %10.1f %7d %6d %dx%d" % r)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
