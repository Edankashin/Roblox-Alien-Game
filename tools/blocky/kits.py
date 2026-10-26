#!/usr/bin/env python3
"""World accent kits, satellites, backdrops and aura rings for the character bar (Decision B54, Blocky-Style section 10).

Every world owns a small kit of modelled accents and every alien of that world wears some of it, more as the tier climbs. A piece is a small
element built from cells (boxes on the sixteenth or eighth grid, a cone6 for a faceted shard) with a size on the quarter-stud grid and an
attach rule: the zones of a body it may sit on. This module is the data and the geometry; `tools/blocky/pilots.py` holds the four pilots' plans
and writes the generated parts into their spec notes. Standard library only (it imports under `python3 -I`).

  python3 -I tools/blocky/kits.py            # list both kits: each piece, its size, its attach zones and its cost in blocks and triangles
  python3 -I tools/blocky/kits.py --check    # every piece's cells lie in its declared size and on its grid; exit 1 when one does not

Local frame of a piece: +x tangent (right), +y tangent (up on a wall, toward the front on a top), +z OUT of the surface it sits on, the origin at
the centre of the piece's footprint on that surface. `place(piece, at, normal)` maps the frame to the alien's space (+y up, it faces -z):
normal "-z" is its front, "+z" its back, "+x" its right side, "-x" its left, "+y" a top, "-y" an underside (a drop hangs from one).
"""
from __future__ import annotations

import math
import sys

# ------------------------------------------------------------------------------------------------ the numbers (Blocky-Style section 10)
QUARTER = 0.25
# how many kit pieces an alien of the tier wears (a mirrored pair is two pieces): Common one, Uncommon two, Rare three or four, Epic five or
# six, Legendary and up as many as the silhouette holds
TIER_COUNT = {"Common": (1, 1), "Uncommon": (2, 2), "Rare": (3, 4), "Epic": (5, 6), "Legendary": (7, 99), "Cosmic": (7, 99), "Secret": (7, 99)}
SATELLITES = (6, 10)          # Rare and up: modelled pieces on the signature-piece orbit
SATELLITE_FROM = "Rare"
BACKDROP_FROM = "Legendary"   # one disc, ring or crest behind the body, under a stud deep
BACKDROP_DEPTH = 1.0
AURA_FROM = "Cosmic"          # Cosmic and Secret: a ground ring of cells
TIERS = ("Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic", "Secret")

# local frame (x, y, z) to the alien's space, by the surface's outward normal: (axis of local x, axis of local y, axis of local z) each a signed
# index into the world's (x, y, z); +1 for +x, -1 for -x, and so on, written as (index, sign)
FRAMES = {
    "-z": ((0, 1), (1, 1), (2, -1)),
    "+z": ((0, -1), (1, 1), (2, 1)),
    "+x": ((2, 1), (1, 1), (0, 1)),
    "-x": ((2, -1), (1, 1), (0, -1)),
    "+y": ((0, 1), (2, -1), (1, 1)),
    "-y": ((0, 1), (2, 1), (1, -1)),
}


def snap(v, g=0.0625):
    return round(v / g) * g


class Cell:
    """One box of a piece in the local frame: centre (x, y, z), size (sx, sy, sz); slot, material, shape; a tilt in degrees about local x, y, z."""

    def __init__(self, c, s, slot="Body", material=None, shape="box", tilt=(0, 0, 0)):
        self.c, self.s, self.slot, self.material, self.shape, self.tilt = tuple(c), tuple(s), slot, material, shape, tuple(tilt)


def _box(x0, x1, y0, y1, z0, z1, slot="Body", material=None, shape="box", tilt=(0, 0, 0)):
    """A cell from its extents (the readable way to write a piece)."""
    return Cell(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (x1 - x0, y1 - y0, z1 - z0), slot, material, shape, tilt)


class Piece:
    """A kit piece: its name, world, what it is, the attach zones it may sit on, the lowest tier that may wear it, and the cells builder
    (a function of the grid `g`: 0.125, or 0.0625 from Epic up)."""

    def __init__(self, name, world, what, zones, build, tier_from="Common", fine_from="Epic", note=""):
        self.name, self.world, self.what, self.zones, self.build, self.tier_from, self.fine_from, self.note = (
            name, world, what, tuple(zones), build, tier_from, fine_from, note)

    def cells(self, g=0.125, lite=False):
        return self.build(g, lite)

    def extent(self, g=0.125, lite=False):
        lo, hi = [1e9] * 3, [-1e9] * 3
        for c in self.cells(g, lite):
            for i in range(3):
                lo[i] = min(lo[i], c.c[i] - c.s[i] / 2)
                hi[i] = max(hi[i], c.c[i] + c.s[i] / 2)
        return lo, hi

    def size(self, g=0.125, lite=False):
        """The bounding box rounded up to the quarter-stud grid: the piece's declared size."""
        lo, hi = self.extent(g, lite)
        return tuple(math.ceil((hi[i] - lo[i]) / QUARTER - 1e-9) * QUARTER for i in range(3))

    def cost(self, g=0.125, lite=False):
        cs = self.cells(g, lite)
        return len(cs), sum({"box": 12, "wedge": 8, "cone6": 10, "ico1": 20}[c.shape] for c in cs)


# ------------------------------------------------------------------------------------------------ Verdant (World 1): moss, vines, buds, sap, bark
def _moss_cells(g, lite=False):
    # a pad of moss: a slab, a smaller step on it and two lit tufts, the stepped moss cell of the world
    return [_box(-0.25, 0.25, -0.25, 0.25, 0, g, "Body", "moss"),
            _box(-0.125, 0.25, -0.125, 0.125, g, 2 * g, "Body", "moss"),
            _box(-0.125, 0.0, 0.0, 0.125, 2 * g, 3 * g, "Accessory", "moss")]


def _blossom_bud(g, lite=False):
    # a stalk and a closed bud: two petals round a lit heart, the Verdant bloom
    return [_box(0, g, 0, g, 0, 2 * g, "BodyDark", "wood"),
            _box(-g, g + g, 0, g, 2 * g, 3 * g, "Accessory"),
            _box(0, g, 0, g, 3 * g, 4 * g, "Accessory")]


def _sap_drop(g, lite=False):
    # an amber teardrop hanging from an edge: a neck, a full middle and a lit round tip (it hangs along +z, so place it on an underside)
    # (the neck and tip are one cell wide and sit half a cell off the body's centre, so every face stays on the grid: the drop leans a little)
    cells = [_box(0, g, 0, g, 0, g, "Trim", "metal"), _box(-g, g, -g, g, g, 2 * g, "Trim", "metal")]
    if not lite:   # a Common has no glow: its drop is the neck and the body only
        cells.append(_box(0, g, 0, g, 2 * g, 3 * g, "Glow", "crystal"))
    return cells


def _sap_run(g, lite=False):
    # sap running down a wall: a thin neck, then a fat amber drop under it, a lit speck on the drop (no speck on a Common)
    cells = [_box(0, g, -g, 0, 0, g, "Trim", "metal"), _box(-g, g, -3 * g, -g, 0, g, "Trim", "metal")]
    if not lite:
        cells.append(_box(0, g, -2 * g, -g, g, 2 * g, "Glow", "crystal"))
    return cells


def _flat_clump(g, lite=False):
    return [_box(-0.25, 0.25, -0.125, 0.125, 0, g, "Body", "moss"), _box(-0.125, 0.125, -0.125, 0.125, g, 2 * g, "Body", "moss")]


# ------------------------------------------------------------------------------------------------ Frostbyte (World 2): rims, shards, flakes, silver, aurora
def _ice_shard(g, lite=False):
    # two faceted shards leaning apart (cone6: a six-sided point, 10 triangles), a tall one and a short one
    return [_box(-0.125, 0.125, -0.125, 0.125, 0, 0.5, "Accessory", "ice", "cone6", (14, 0, 0)),
            _box(0.0625, 0.1875, -0.0625, 0.0625, 0, 0.25, "Accessory", "ice", "cone6", (0, 0, -16))]


def _snowflake(g, lite=False):
    # a six-point glyph in the sixteenth grid: a plus and four corner dots of silver, flat on the surface (Epic and up); `lite` is the plus and a
    # lit heart (three blocks)
    t = 0.0625
    base = [_box(-0.125, 0.125, 0, t, 0, t, "Trim", "metal"), _box(0, t, -0.125, 0.125, 0, t, "Trim", "metal")]
    if lite:
        return base + [_box(0, t, 0, t, t, 2 * t, "Glow", "crystal")]
    return base + [_box(x, x + t, y, y + t, 0, t, "Trim", "metal") for x in (-0.125, 0.0625) for y in (-0.125, 0.0625)]


def _frost_rim(g, lite=False):
    # a lip of pale ice along an edge, three icicle teeth hanging off it (Epic and up)
    return [_box(-0.25, 0.25, 0, 0.125, 0, 0.0625, "Accessory", "ice")] + [
        _box(x, x + 0.0625, 0, 0.125, 0.0625, 0.1875, "Accessory", "ice") for x in (-0.1875, 0.0, 0.1875)]


def _aurora_wisp(g, lite=False):
    # a ribbon of lit cells that steps sideways as it rises: the wisp of the northern light (Epic and up)
    xs = (0.0, 0.0625, 0.125, 0.0625, 0.0, -0.0625)
    return [_box(x - 0.0625, x + 0.0625, 0, 0.0625, i * 0.125, (i + 1) * 0.125, "Glow", "crystal") for i, x in enumerate(xs)]


# ------------------------------------------------------------------------------------------------ satellites: small pieces for the orbit (Rare and up)
# Each is a flat cell figure that faces outward from the ring it is strung on. The world kits supply two (the leaf blade, the frost shard),
# and every alien adds its own theme: Raddis's suns, Syrinx's eclipse shards and wool tufts, Fenrir's moon phases.
def _sun_cross(g, lite=False):
    # a lit pixel sun: two crossing bars and a raised amber heart (Epic and up grid)
    return [_box(-0.25, 0.25, -0.0625, 0.0625, 0, 0.125, "Glow", "crystal"), _box(-0.0625, 0.0625, -0.25, 0.25, 0, 0.125, "Glow", "crystal"),
            _box(-0.125, 0.125, -0.125, 0.125, 0.125, 0.1875, "Trim", "metal")]


def _leaf_blade(g, lite=False):
    # a broad leaf cut in two cells, leaning 15 degrees: the Verdant satellite
    return [_box(-0.1875, 0.1875, 0, 0.3125, 0, 0.0625, "Accessory", "moss", "box", (0, 0, 15)),
            _box(-0.0625, 0.0625, 0.3125, 0.4375, 0, 0.0625, "Accessory", "moss", "box", (0, 0, 15))]


def _frost_shard(g, lite=False):
    # one faceted shard, a cone6, leaning: the Frostbyte satellite
    return [_box(-0.125, 0.125, -0.125, 0.125, 0, 0.5, "Accessory", "ice", "cone6", (18, 0, 0))]


def _eclipse_shard(g, lite=False):
    # a chip of the dark moon: a slab with a lit violet rim cell on its edge
    return [_box(-0.1875, 0.1875, -0.1875, 0.125, 0, 0.0625, "BodyDark", None, "box", (0, 0, 15)),
            _box(-0.1875, 0.1875, 0.125, 0.1875, 0, 0.0625, "Glow", "crystal", "box", (0, 0, 15))]


def _wool_tuft(g, lite=False):
    # a puff of dark wool: two stacked cells
    return [_box(-0.1875, 0.1875, -0.1875, 0.1875, 0, 0.125, "BodyDark", "wool"), _box(-0.125, 0.25, -0.125, 0.25, 0.125, 0.1875, "BodyDark", "wool")]


def _note_glyph(g, lite=False):
    # a lit music note: a head, a stem and a flag (Epic and up grid)
    return [_box(-0.125, 0.125, -0.25, -0.125, 0, 0.0625, "Glow", "crystal"), _box(0, 0.125, -0.125, 0.25, 0, 0.0625, "Glow", "crystal"),
            _box(0.125, 0.25, 0.125, 0.25, 0, 0.0625, "Glow", "crystal")]


def _moon_full(g, lite=False):
    # a gibbous moon, half a stud across: a lit octagon of two bars with a dark limb on its right, so it reads against snow
    return [_box(-0.25, 0.125, -0.125, 0.125, 0, 0.0625, "Glow", "crystal"), _box(-0.125, 0.125, -0.25, 0.25, 0, 0.0625, "Glow", "crystal"),
            _box(0.125, 0.25, -0.125, 0.125, 0, 0.0625, "Body", "fur")]


def _moon_half(g, lite=False):
    return [_box(0, 0.25, -0.125, 0.125, 0, 0.0625, "Glow", "crystal"), _box(0, 0.125, -0.25, 0.25, 0, 0.0625, "Glow", "crystal"),
            _box(-0.25, 0, -0.125, 0.125, 0, 0.0625, "Body", "fur"), _box(-0.125, 0, -0.25, 0.25, 0, 0.0625, "Body", "fur")]


def _moon_crescent(g, lite=False):
    return [_box(-0.25, 0.125, -0.125, 0.125, 0, 0.0625, "Body", "fur"), _box(-0.125, 0, -0.25, 0.25, 0, 0.0625, "Body", "fur"),
            _box(0.125, 0.25, -0.125, 0.125, 0, 0.0625, "Glow", "crystal"), _box(0, 0.125, 0.125, 0.25, 0, 0.0625, "Glow", "crystal"),
            _box(0, 0.125, -0.25, -0.125, 0, 0.0625, "Glow", "crystal")]


def _moon_new(g, lite=False):
    return [_box(-0.25, 0.25, -0.125, 0.125, 0, 0.0625, "Body", "fur"), _box(-0.125, 0.125, -0.25, 0.25, 0, 0.0625, "Body", "fur"),
            _box(0.125, 0.1875, 0, 0.0625, 0.0625, 0.125, "Glow", "crystal")]


PIECES = {p.name: p for p in (
    Piece("moss_cells", "Verdant", "a pad of stepped moss cells with a lit tuft", ("head_top", "back", "shoulder", "haunch", "base"), _moss_cells),
    Piece("blossom_bud", "Verdant", "a stalk and a closed bud of two petals", ("head_top", "back", "horn", "haunch", "crown"), _blossom_bud),
    Piece("sap_drop", "Verdant", "an amber teardrop (neck, body, lit tip) that hangs from an edge", ("brow", "band", "horn", "chin", "edge"), _sap_drop),
    Piece("sap_run", "Verdant", "amber sap running down a wall: a neck and a fat drop under it, a lit speck on it", ("flank", "cheek", "trunk", "side"), _sap_run),
    Piece("flat_clump", "Verdant", "a two-step moss clump, the cheap moss for a Common", ("head_top", "base"), _flat_clump),
    Piece("ice_shard", "Frostbyte", "two faceted cone6 shards leaning apart", ("head_top", "back", "shoulder", "haunch", "tail"), _ice_shard),
    Piece("snowflake_stud", "Frostbyte", "a six-point silver glyph flat on a flank or a plate", ("flank", "shoulder", "cheek", "plate"), _snowflake, "Epic"),
    Piece("frost_rim", "Frostbyte", "a lip of pale ice with three icicle teeth along an edge", ("head_top", "back", "edge", "ear"), _frost_rim, "Epic"),
    Piece("leaf_blade", "Verdant", "a broad leaf in two cells leaning 15 degrees (a satellite)", ("orbit",), _leaf_blade),
    Piece("frost_shard", "Frostbyte", "one faceted cone6 shard leaning (a satellite)", ("orbit",), _frost_shard),
    Piece("sun_cross", "Raddis", "a lit pixel sun: two crossing bars and a raised heart (a satellite)", ("orbit",), _sun_cross, "Epic"),
    Piece("eclipse_shard", "Syrinx", "a chip of the dark moon with a lit violet rim (a satellite)", ("orbit",), _eclipse_shard, "Epic"),
    Piece("note_glyph", "Syrinx", "a lit music note: head, stem and flag (a satellite)", ("orbit",), _note_glyph, "Epic"),
    Piece("wool_tuft", "Syrinx", "a puff of dark wool in two cells (a satellite)", ("orbit",), _wool_tuft, "Epic"),
    Piece("moon_full", "Fenrir", "a gibbous moon, a lit octagon with a dark limb (a satellite)", ("orbit",), _moon_full, "Epic"),
    Piece("moon_half", "Fenrir", "a half moon, the left half dark (a satellite)", ("orbit",), _moon_half, "Epic"),
    Piece("moon_crescent", "Fenrir", "a crescent moon, only its right rim lit (a satellite)", ("orbit",), _moon_crescent, "Epic"),
    Piece("moon_new", "Fenrir", "a new moon, dark with one lit pixel (a satellite)", ("orbit",), _moon_new, "Epic"),
    Piece("aurora_wisp", "Frostbyte", "a ribbon of six lit cells stepping sideways as it rises", ("tail", "shoulder", "back"), _aurora_wisp, "Epic"),
)}
# the band pieces are built round a column, not placed on a surface: see band() and vine_wrap() below
WRAPS = {
    "bark_band": ("Verdant", "a ring of bark cells round a limb or a body", "BodyDark", "wood"),
    "vine_wrap": ("Verdant", "a vine that winds up a column in a quarter turn a step", "Accessory", "moss"),
    "silver_band": ("Frostbyte", "a ring of silver cells round a limb or a body", "Trim", "metal"),
}
KITS = {
    "Verdant": ("moss_cells", "vine_wrap", "blossom_bud", "sap_drop", "bark_band"),
    "Frostbyte": ("frost_rim", "ice_shard", "snowflake_stud", "silver_band", "aurora_wisp"),
}


# ------------------------------------------------------------------------------------------------ placing
def _fmt(v):
    v = round(v, 5)
    return str(int(v)) if v == int(v) else ("%.5f" % v).rstrip("0").rstrip(".")


def part(name, slot, size, at, rot=None, shape="box", material=None, mirror=False, moves=None, pivot=None):
    """A part dict in the spec's own vocabulary (size and at in studs)."""
    p = {"name": name, "slot": slot, "size": [round(s, 5) for s in size], "at": [round(a, 5) for a in at]}
    if rot and any(abs(r) > 1e-9 for r in rot):
        p["rot"] = list(rot)
    if shape != "box":
        p["shape"] = shape
    if material and material not in ("skin",):
        p["material"] = material
    if mirror:
        p["mirror"] = "x"
    if moves:
        p["moves"] = moves
        p["pivot"] = [round(v, 5) for v in pivot]
    return p


def line(p):
    """One part as the note's flow mapping."""
    keys = ["name", "slot", "size", "at", "rot", "shape", "mirror", "moves", "pivot", "material"]
    out = []
    for k in keys:
        if k not in p:
            continue
        v = p[k]
        if isinstance(v, list):
            v = "[" + ", ".join(_fmt(x) for x in v) + "]"
        out.append("%s: %s" % (k, v))
    return "  - {" + ", ".join(out) + "}"


def place(piece, name, at, normal="+y", g=0.125, mirror=False, spin=0, moves=None, pivot=None, scale=1.0, lite=False, slots=None):
    """The parts of one piece placed with its origin at `at` on a surface with outward `normal`. `spin` quarter turns (0 to 3) of the piece about
    its own outward axis; the tilts of a cell (the shard's lean) are given about the local axes and carried over to the world's (a lean about
    local x on a top is a lean about world x; on a wall the axes swap). `lite` builds the cheap version (no glow); `slots` maps a cell's slot to
    the alien's (a Common wears the drop in its accent slot). Names are <name>a, <name>b ..."""
    fr = FRAMES[normal]
    out = []
    for i, c in enumerate(piece.cells(g, lite)):
        lc = [c.c[0] * scale, c.c[1] * scale, c.c[2] * scale]
        ls = [abs(v) * scale for v in c.s]
        for _ in range(spin % 4):
            lc[0], lc[1] = -lc[1], lc[0]
            ls[0], ls[1] = ls[1], ls[0]
        wc, ws, rot = [0.0] * 3, [0.0] * 3, [0.0] * 3
        for li in range(3):
            wi, sg = fr[li]
            wc[wi] = sg * lc[li]
            ws[wi] = ls[li]
            rot[wi] += sg * c.tilt[li]
        wc = [at[i2] + wc[i2] for i2 in range(3)]
        out.append(part("%s%s" % (name, "abcdefghijklmnopqrstuvwxyz"[i]), (slots or {}).get(c.slot, c.slot), ws, wc, rot, c.shape, c.material, mirror, moves, pivot))
    return out


def band(name, centre, size, t=0.125, h=0.125, slot="BodyDark", material="wood", faces=("-z", "+z", "+x", "-x"), moves=None, pivot=None):
    """A ring of cells round a column or a body at `centre` (the middle of the ring), `size` = (w, d) of what it wraps; `t` proud, `h` tall.
    One strip a face (leave out the one a collar or a plate already covers); the strips on the +x and -x faces run the whole depth and the
    front and back ones the whole width plus the corners."""
    cx, cy, cz = centre
    w, d = size
    out = []
    for face in faces:
        if face == "-z":
            sz, at = (w + 2 * t, h, t), (cx, cy, cz - (d + t) / 2)
        elif face == "+z":
            sz, at = (w + 2 * t, h, t), (cx, cy, cz + (d + t) / 2)
        elif face == "+x":
            sz, at = (t, h, d), (cx + (w + t) / 2, cy, cz)
        else:
            sz, at = (t, h, d), (cx - (w + t) / 2, cy, cz)
        out.append(part("%s%s" % (name, {"-z": "F", "+z": "B", "+x": "R", "-x": "L"}[face]), slot, sz, at, None, "box", material, False, moves, pivot))
    return out


def vine_wrap(name, base, size, height, steps=4, t=0.125, slot="Accessory", material="moss", moves=None, pivot=None, faces=("-z", "+x", "+z", "-x")):
    """A vine winding up a column of footprint `size` = (w, d) centred on `base` (x, y of its lowest point, z): one strip a quarter turn, each a
    step higher, so from every side it reads as a diagonal wrap. `steps` strips over `height`; `faces` is the order of the faces it crosses
    (leave out the one a collar or a plate already covers)."""
    cx, y0, cz = base
    w, d = size
    h = height / steps
    out = []
    for k in range(steps):
        y = y0 + h * (k + 0.5)
        face = faces[k % len(faces)]
        if face == "-z":
            sz, at = (w + 2 * t, h, t), (cx, y, cz - (d + t) / 2)
        elif face == "+z":
            sz, at = (w + 2 * t, h, t), (cx, y, cz + (d + t) / 2)
        elif face == "+x":
            sz, at = (t, h, d + 2 * t), (cx + (w + t) / 2, y, cz)
        else:
            sz, at = (t, h, d + 2 * t), (cx - (w + t) / 2, y, cz)
        out.append(part("%s%d" % (name, k), slot, sz, at, None, "box", material, False, moves, pivot))
    return out


# ------------------------------------------------------------------------------------------------ rings and discs of cells
def ring_rects(r_out, r_in, cell, cx=0.0, cz=0.0):
    """A ring of square cells on the ground plane as the fewest rectangles: the cell rows of an annulus, each row's runs merged. Returns
    [(x0, x1, z0, z1)] in studs, centred on (cx, cz). Rows of equal runs stack into one taller rectangle."""
    n = int(math.ceil(r_out / cell)) + 1
    rows = []
    for j in range(-n, n):
        zc = (j + 0.5) * cell
        runs, start = [], None
        for i in range(-n, n + 1):
            xc = (i + 0.5) * cell
            rr = math.hypot(xc, zc)
            inside = r_in <= rr <= r_out
            if inside and start is None:
                start = i
            if (not inside or i == n) and start is not None:
                runs.append((start, i if not inside else i + 1))
                start = None
        rows.append((j, tuple(runs)))
    out, k = [], 0
    while k < len(rows):
        j, runs = rows[k]
        m = k
        while m + 1 < len(rows) and rows[m + 1][1] == runs and runs:
            m += 1
        for (a, b) in runs:
            out.append((cx + a * cell, cx + b * cell, cz + j * cell, cz + (rows[m][0] + 1) * cell))
        k = m + 1
    return out


def crescent_backdrop(name, centre, big, small, shift, z, row=0.25, cell=0.125, thick=0.125, slot="Trim", material="metal", moves=None, pivot=None):
    """A crescent moon standing behind the body, in cells: the outer disc of radius `big` minus an inner disc of radius `small` shifted `shift`
    studs to the left (its horns point left), centred on (x, y) = `centre` in the plane z. Rows of `row` studs, each row's runs in `cell`
    columns, so a 3-stud moon is a dozen blocks. One part a run, all one moving object when `moves` is given."""
    cx, cy = centre
    out = []
    n = int(round(2 * big / row))
    k = 0
    for j in range(n):
        y0 = cy - big + j * row
        yc = y0 + row / 2
        runs, start = [], None
        m = int(math.ceil(big / cell)) + 1
        for i in range(-m, m + 1):
            xc = cx + (i + 0.5) * cell
            inside = False
            for dy in (y0 + 0.02, yc, y0 + row - 0.02):
                in_big = math.hypot(xc - cx, dy - cy) <= big
                in_small = math.hypot(xc - (cx - shift), dy - cy) < small
                inside = inside or (in_big and not in_small)
            if inside and start is None:
                start = i
            if (not inside) and start is not None:
                runs.append((start, i))
                start = None
        for (a, b) in runs:
            out.append(part("%s%d" % (name, k), slot, ((b - a) * cell, row, thick), (cx + (a + b) / 2 * cell, y0 + row / 2, z), None, "box",
                            material, False, moves, pivot))
            k += 1
    return out


def aura_dashes(name, centre, r, n=12, long=0.375, wide=0.125, thick=0.0625, slot="Glow", material="crystal", moves="aura", start=0.0, grid=0.0625,
                alt=None):
    """The cheap ground aura: `n` dashes of cells on a circle of radius `r` round `centre` (x, z) on the ground, each lying along the circle's
    tangent to the nearest axis (so it stays an axis-aligned box), all one moving object `moves` that pivots on the centre and breathes. `alt`
    is a (slot, material) every second dash wears instead (a dark rune between lit ones, so the ring reads on snow too)."""
    cx, cz = centre
    pivot = [cx, thick / 2, cz]
    out = []
    for i in range(n):
        a = start + 2 * math.pi * i / n
        px, pz = cx + r * math.sin(a), cz - r * math.cos(a)
        tx, tz = math.cos(a), math.sin(a)   # the tangent
        size = (long, thick, wide) if abs(tx) >= abs(tz) else (wide, thick, long)
        sl, mat = (alt if alt and i % 2 else (slot, material))
        out.append(part("%s%d" % (name, i), sl, size, (snap(px, grid * 2), thick / 2, snap(pz, grid * 2)), None, "box", mat, False, moves, pivot))
    return out


def aura_ring(name, centre, r_out, cell, slot="Glow", material="crystal", thick=0.0625, band=0.25, moves="aura"):
    """The ground aura: a ring of cells on the ground (y 0 to `thick`), one moving object `moves` pivoting on its centre so it can breathe."""
    cx, cz = centre
    out = []
    pivot = [cx, thick / 2, cz]
    for i, (x0, x1, z0, z1) in enumerate(ring_rects(r_out, r_out - band, cell, cx, cz)):
        out.append(part("%s%d" % (name, i), slot, (x1 - x0, thick, z1 - z0), ((x0 + x1) / 2, thick / 2, (z0 + z1) / 2), None, "box", material, False, moves, pivot))
    return out


def orbit(pieces, name, centre, radius, y, tilt=0.0, moves="sat", pivot=None, g=0.125, start=0.0, scales=None, spins=None):
    """Pieces strung on one circle round `centre` (x, z), at height `y` plus `tilt` times the sine of the angle (the ring tilted, as Raddis's sun
    ring is). `pieces` is a list of Piece or (Piece, normal) in order; each faces outward (the nearest side of the four). All are one moving
    object `moves` whose pivot is the ring's centre at the mean height, so the rig's spin turns the whole ring."""
    cx, cz = centre
    pivot = pivot or [cx, y, cz]
    n = len(pieces)
    out = []
    for i, pc in enumerate(pieces):
        piece, normal = pc if isinstance(pc, tuple) else (pc, None)
        a = start + 2 * math.pi * i / n
        px, pz = cx + radius * math.sin(a), cz - radius * math.cos(a)   # a = 0 is the front (-z)
        py = y + tilt * math.sin(a)
        if normal is None:
            nx, nz = math.sin(a), -math.cos(a)
            normal = ("+x" if nx > 0 else "-x") if abs(nx) > abs(nz) else ("+z" if nz > 0 else "-z")
        # the piece's footprint centre sits on the circle; snap to the sixteenth grid so every face lies on a grid
        out += place(piece, "%s%d" % (name, i), (snap(px, g / 2), snap(py, g / 2), snap(pz, g / 2)), normal, g,
                     moves=moves, pivot=pivot, scale=(scales[i] if scales else 1.0), spin=(spins[i] if spins else 0))
    return out


def counts(parts):
    return len(parts), sum({"box": 12, "wedge": 8, "cone6": 10, "ico1": 20}[p.get("shape", "box")] * (2 if p.get("mirror") == "x" else 1) for p in parts)


# ------------------------------------------------------------------------------------------------ the CLI
def listing():
    for world, names in KITS.items():
        print("%s kit" % world)
        for n in names:
            if n in PIECES:
                p = PIECES[n]
                b, t = p.cost(0.125)
                print("  %-15s %s  size %s  %d blocks, %d tris  zones: %s" % (n, p.what, "x".join(_fmt(v) for v in p.size()), b, t, ", ".join(p.zones)))
            else:
                w, what, slot, mat = WRAPS[n]
                print("  %-15s %s  (a wrap: band() or vine_wrap(), slot %s, material %s)" % (n, what, slot, mat))
    print("tier counts:", ", ".join("%s %s" % (t, "-".join(str(v) for v in c)) for t, c in TIER_COUNT.items()))


def check():
    bad = 0
    for p in PIECES.values():
        for g in ((0.0625,) if TIERS.index(p.tier_from) >= TIERS.index("Epic") else (0.125, 0.0625)):
            lo, hi = p.extent(g)
            for c in p.cells(g):
                for i in range(3):
                    for edge in (c.c[i] - c.s[i] / 2, c.c[i] + c.s[i] / 2):
                        step = 0.03125 if (c.shape != "box" or any(c.tilt)) else min(g, 0.0625)
                        if abs(edge / step - round(edge / step)) > 1e-6:
                            print("%s (g %g): a cell face at %g is off the %g grid" % (p.name, g, edge, step))
                            bad += 1
            if max(hi[i] - lo[i] for i in range(3)) > 1.0 + 1e-9:
                print("%s: bigger than a stud" % p.name)
                bad += 1
    print("kits: %s" % ("%d problems" % bad if bad else "clean"))
    return 1 if bad else 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(check())
    listing()
