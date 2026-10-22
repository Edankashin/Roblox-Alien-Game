#!/usr/bin/env python3
"""The eye library (Decision B46): every alien wears its own eyes from this library, drawn on a separate face plate.

B46, Ethan: "They shouldn't all have the same eyes and rarer aliens should look a lot more exclusive and cooler/cuter." So the single house eye
of Blocky-Style rule 3 is retired for a library of original eye designs, each with a key, a tier floor, pixel frames and colour roles. The ladder:
Common simple and readable (a bean, a round dot, happy arcs, sleepy lids, a button, a pebble); Uncommon a two-tone iris; Rare a coloured iris, a
shine and a glint; Epic a star, heart, gem or rune pupil with coloured lashes or a lit rim; Legendary layered glowing irises with an animated
sparkle; Cosmic galaxy, nebula or solar irises whose frames swirl; Secret dark eyes with one accent. Every design is big, soft and has a shine:
rarer is cooler or cuter, never fiercer. The shapes are ours (no other game's eyes).

The face plate: the eyes, the mouth and the cheeks are drawn on a thin plate proud of the head's front with its own small texture (nearest
filtering), so the eye resolution and the flipbook frames are independent of the body cell (Blocky-Style C1 keeps the body). The plate's pixel
density is set by the design's tier floor: 16 pixels a stud for the Common to Epic designs (two eye pixels a body cell on a 2-stud head) and 32
for Legendary and up ("eyes no lower species has, on a finer face grid"). Frames: open, half, closed (the blink) for every design; two glint frames
from Rare up; an iris cycle of 6 (Legendary) or 8 (Cosmic, Secret) frames from Legendary up. The game flips them on the plate (data/Rigs,
World.RigAnimator); the sheet lays them out in rows of SHEET_COLUMNS.

Standard library only (Pillow is used only by --sheet), and no import of spec.py (spec.py imports this), so Blender's Python can load it.

  python3 -I tools/blocky/eyes.py --list                                  # every design: key, tier floor, size, frames, roles
  python3 -I tools/blocky/eyes.py --sheet docs/vault/06-art-pipelines/refs/blocky/eye_library_v1.png   # the library sheet (Pillow)
"""
from __future__ import annotations

import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent

TIER_ORDER = ("Common", "Uncommon", "Rare", "Epic", "Legendary", "Cosmic", "Secret")
DENSITY = {"Common": 16, "Uncommon": 16, "Rare": 16, "Epic": 16, "Legendary": 32, "Cosmic": 32, "Secret": 32}  # plate pixels a stud
CYCLE_FRAMES = {"Legendary": 6, "Cosmic": 8, "Secret": 8}   # iris-cycle frames by the design's tier floor
GLINT_FRAMES = 2            # Rare and up: two glint frames (a small sparkle, then a bigger one)
SHEET_COLUMNS = 4           # frames per row in a species' plate sheet (a squarish image for one upload)
SHEET_MAX = 1024            # Roblox scales an uploaded image down to 1024 a side, so the exported sheet fits it
SHEET_SCALES = (8, 4)       # texels a face pixel in the exported sheet: 8 where the sheet fits SHEET_MAX at 8, else 4 (the 32-a-stud faces).
                            # One texel a face pixel read soft in Studio (Aurelyx at 3 studs, 2026-10-22): Roblox block-compresses an image
                            # in 4 x 4 texel blocks, and a block holding four or five colours of a multicolour eye (Aurelyx's pink-dotted
                            # mint iris, its rune cross, its lilac sparkle pixels) comes out as blended mud with a dotted alpha fringe, then
                            # filters it; at 4 or 8 texels a face pixel every block holds one colour and filtering only touches a pixel's rim
# the timings the game plays the frames at (written into data/Rigs by tools/blocky/rigs.py; every number in data)
BLINK_SECONDS = 0.18        # one blink: half, closed, half
GLINT_EVERY = {"Rare": 3.5, "Epic": 3.0, "Legendary": 2.5, "Cosmic": 2.5, "Secret": 3.0}   # seconds between glints
GLINT_SECONDS = 0.3         # one glint: small, big, small
CYCLE_FPS = {"Legendary": 6, "Cosmic": 8, "Secret": 6}       # iris-cycle frames a second

# the colour roles a design's pixels use (one character each); '.' is the transparent plate, so the head shows through
ROLES = {
    "k": "ink", "w": "shine", "s": "sparkle", "i": "iris", "j": "iris2", "g": "glint", "l": "lash", "r": "rim", "p": "pupil",
    "a": "deep", "b": "mid", "c": "bright", "t": "tongue", "h": "cheek",
}
# where a role's colour comes from when the spec's `eyes.colours` does not name it: palette roles in order (the first the palette has), or a hex
DEFAULTS = {
    "ink": ("ink",), "shine": ("#FFFFFF",), "sparkle": ("#FFFFFF",), "iris": ("accent", "body"), "iris2": ("second", "ink"),
    "glint": ("glow", "accent"), "lash": ("trim", "accent"), "rim": ("glow", "accent"), "pupil": ("glow", "trim", "accent"),
    "deep": ("second", "ink"), "mid": ("accent",), "bright": ("glow", "accent"), "tongue": ("#FF7F98",), "cheek": ("#FF9DBB",),
}
MOUTHS = ("none", "smile", "grin", "open", "cat", "o", "tooth")
CHEEKS = ("none", "blush", "dots", "hearts", "stars")
CHEEK_FLOOR = {"none": "Common", "blush": "Common", "dots": "Common", "hearts": "Epic", "stars": "Legendary"}


# ------------------------------------------------------------------------------------------------ the pixel grid
def parse(rows):
    return [list(r) for r in rows]


def blank(w, h):
    return [["."] * w for _ in range(h)]


def rows_of(grid):
    return ["".join(r) for r in grid]


def disc(w, h, cx, cy, rx, ry):
    """The pixels whose centres fall inside the ellipse (cx, cy, rx, ry) in pixel units (x right, y down)."""
    return {(x, y) for y in range(h) for x in range(w) if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0}


def put(grid, pts, ch):
    for x, y in pts:
        if 0 <= y < len(grid) and 0 <= x < len(grid[0]):
            grid[y][x] = ch


def rim(pts):
    """The pixels of a set with a 4-neighbour outside it."""
    return {(x, y) for x, y in pts if any((x + dx, y + dy) not in pts for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}


def _hash(*keys):
    h = 0x9E3779B97F4A7C15
    for k in keys:
        h ^= (int(k) + 0x632BE59BD9B4E019 + (h << 6) + (h >> 2)) & ((1 << 64) - 1)
        h = (h * 0xBF58476D1CE4E5B9) & ((1 << 64) - 1)
        h ^= h >> 31
    return (h & 0xFFFFFF) / float(0x1000000)


# ------------------------------------------------------------------------------------------------ the designs
# Each design: key, tier floor, a label, its open frame (or a cycle function that draws frame k of n), the glint's place (Rare and up), and
# `arc` for eyes already closed in a smile (their blink flattens the arc). Drawn as the eye on the viewer's left; the right eye is the mirror.
DESIGNS = {}


def design(key, tier, label, rows=None, draw=None, glint=None, arc=False, roles_hint=""):
    DESIGNS[key] = {"key": key, "tier": tier, "label": label, "rows": rows, "draw": draw, "glint": glint, "arc": arc, "hint": roles_hint}


# --- Common: simple and readable, one shine, ink only (the button takes the iris colour)
design("bean", "Common", "bean: a tall soft bean, one square shine", rows=[
    "..kkk..",
    ".kkkkk.",
    "kwwkkkk",
    "kwwkkkk",
    "kkkkkkk",
    "kkkkkkk",
    "kkkkkkk",
    ".kkkkk.",
    "..kkk..",
])
design("dot", "Common", "dot: a round dot, one shine pixel", rows=[
    ".kkkk.",
    "kwwkkk",
    "kwkkkk",
    "kkkkkk",
    "kkkkkk",
    ".kkkk.",
])
design("happy", "Common", "happy: closed in a smile, two soft arcs", arc=True, rows=[
    "..kkk..",
    ".kk.kk.",
    "kk...kk",
    "k.....k",
])
design("sleepy", "Common", "sleepy: a half lid with a lash, a shine under it", rows=[
    "kkkkkkkk",
    ".kkkkkk.",
    ".kwwkkk.",
    ".kkkkkk.",
    "..kkkk..",
])
design("button", "Common", "button: a round iris button, two holes, a shine", rows=[
    ".kkkkk.",
    "kwiiiik",
    "kiiiiik",
    "kikikik",
    "kiiiiik",
    "kiiiiik",
    ".kkkkk.",
])
design("pebble", "Common", "pebble: a wide soft oval, a long shine", rows=[
    ".kkkkkk.",
    "kwwkkkkk",
    "kwkkkkkk",
    "kkkkkkkk",
    "kkkkkkkk",
    ".kkkkkk.",
])


def _round_eye(w, h, iris, pupil, shine=((1, 1, 2, 2),), lower_shine=None, rim_role="k"):
    """An outlined round eye: `iris(grid, inside)` colours the inside, `pupil` (cx, cy, rx, ry) or None, shines as (x, y, w, h) boxes."""
    g = blank(w, h)
    body = disc(w, h, w / 2, h / 2, w / 2, h / 2)
    put(g, body, "k")
    inside = body - rim(body)
    iris(g, inside)
    if pupil:
        put(g, disc(w, h, *pupil) & inside, "k")
    for x0, y0, bw, bh in shine:
        put(g, {(x, y) for x in range(x0, x0 + bw) for y in range(y0, y0 + bh)} & body, "w")
    if lower_shine:
        put(g, {lower_shine} & body, "w")
    if rim_role != "k":
        put(g, rim(body), rim_role)
    return g


def _split_iris(top, bottom, cut=0.5):
    def paint(g, inside):
        h = len(g)
        put(g, {(x, y) for x, y in inside if y < h * cut}, top)
        put(g, {(x, y) for x, y in inside if y >= h * cut}, bottom)
    return paint


def _fill(ch):
    return lambda g, inside: put(g, inside, ch)


# --- Uncommon: a two-tone iris
design("twotone", "Uncommon", "twotone: a round iris, dark over light, a big pupil",
       draw=lambda: _round_eye(8, 9, _split_iris("j", "i"), (4, 4.6, 1.7, 2.1), ((1, 1, 2, 2),), (5, 6)))


def _droplet():
    g = blank(8, 9)
    body = disc(8, 9, 4, 5.2, 4, 3.8) | {(3, 0), (4, 0), (3, 1), (4, 1), (2, 1), (5, 1)}
    put(g, body, "k")
    inside = body - rim(body)
    put(g, inside, "i")
    put(g, {(x, y) for x, y in inside if y >= 6}, "j")
    put(g, disc(8, 9, 4, 4.6, 1.5, 2) & inside, "k")
    put(g, {(2, 3), (2, 4), (3, 3)} & body, "w")
    return g


design("droplet", "Uncommon", "droplet: a dewdrop, a light band at its foot", draw=_droplet)


def _moonlet():
    g = _round_eye(8, 9, _fill("i"), (4, 4.2, 2, 2.4), ((1, 1, 2, 2),))
    body = disc(8, 9, 4, 4.5, 4, 4.5)
    inside = body - rim(body)
    crescent = {(x, y) for x, y in inside if y >= 6 and g[y][x] != "w"}
    put(g, crescent, "j")
    return g


design("moonlet", "Uncommon", "moonlet: a pupil over a second-tone crescent", draw=_moonlet)


# --- Rare: a coloured iris, a shine and a glint (the glint flashes in the glint frames)
def _glimmer():
    g = _round_eye(8, 9, _fill("i"), (4, 4.6, 1.6, 2), ((1, 1, 2, 2), (5, 6, 1, 1)))
    body = disc(8, 9, 4, 4.5, 4, 4.5)
    inside = body - rim(body)
    put(g, {(x, y) for x, y in rim(inside) if y >= 5 and g[y][x] == "i"}, "j")
    put(g, {(2, 6)}, "g")
    return g


design("glimmer", "Rare", "glimmer: a coloured iris ringed darker, two shines, a glint", draw=_glimmer, glint=(1, 6))


def _crescent():
    g = blank(8, 10)
    body = disc(8, 10, 4, 5, 3.6, 5)
    put(g, body, "k")
    inside = body - rim(body)
    put(g, {(x, y) for x, y in inside if 4 <= y <= 6}, "i")
    put(g, {(x, y) for x, y in body if y >= 7}, "g")
    put(g, {(x, y) for x, y in body if y == 9}, ".")
    put(g, {(2, 1), (2, 2), (3, 1), (2, 3)} & body, "w")
    put(g, {(5, 7)} & body, "w")
    return g


design("crescent", "Rare", "crescent: an ink drop over a lit crescent, a band of iris", draw=_crescent, glint=(6, 8))


def _bubble():
    g = _round_eye(8, 9, _fill("i"), (4.3, 4.8, 1.3, 1.6), ())
    put(g, {(1, 3), (1, 2), (2, 1), (3, 1)}, "w")
    put(g, {(5, 6)}, "g")
    put(g, {(2, 6), (3, 7)}, "j")
    return g


design("bubble", "Rare", "bubble: a big glossy iris, an arc of shine, a glint", draw=_bubble, glint=(6, 1))


# --- Epic: a star, heart, gem or rune pupil, coloured lashes or a lit rim
def _with_lashes(g, side="outer"):
    """Two lash pixels in the lash colour above the outer corner (the eye is the viewer's left one: outer is left)."""
    out = blank(len(g[0]) + 1, len(g) + 1)
    for y, row in enumerate(g):
        for x, ch in enumerate(row):
            out[y + 1][x + 1] = ch
    put(out, {(0, 1), (1, 0), (2, 1)}, "l")
    return out


def _star():
    g = _round_eye(8, 9, _split_iris("j", "i", 0.45), None, ((1, 1, 2, 1),))
    put(g, {(4, 3), (3, 4), (4, 4), (5, 4), (4, 5), (3, 6), (5, 6), (4, 6)} - {(4, 6)}, "p")
    put(g, {(2, 4), (6, 4)}, "p")
    return _with_lashes(g)


design("starry", "Epic", "starry: a star pupil in a two-tone iris, coloured lashes", draw=_star, glint=(7, 2))


def _heart():
    g = _round_eye(8, 9, _split_iris("i", "j", 0.62), None, ((1, 1, 2, 1),))
    put(g, {(2, 3), (3, 3), (5, 3), (6, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (3, 5), (4, 5), (5, 5), (4, 6)}, "p")
    put(g, {(2, 3)}, "w")
    return _with_lashes(g)


design("hearty", "Epic", "hearty: a heart pupil, a shine on its lobe, coloured lashes", draw=_heart, glint=(7, 7))


def _gem():
    g = _round_eye(8, 9, _fill("i"), None, ((1, 1, 2, 1),), rim_role="r")
    put(g, {(4, 2), (3, 3), (4, 3), (5, 3), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (3, 5), (4, 5), (5, 5), (4, 6)}, "p")
    put(g, {(3, 3), (2, 4), (3, 4)}, "w")
    put(g, {(5, 5), (4, 6)}, "j")
    return g


design("gem", "Epic", "gem: a faceted diamond pupil, a lit rim", draw=_gem, glint=(1, 7))


def _rune():
    g = _round_eye(8, 9, _split_iris("j", "i", 0.5), None, ((1, 1, 1, 2),), rim_role="r")
    put(g, {(3, 2), (4, 2), (5, 2), (5, 3), (3, 4), (4, 4), (5, 4), (3, 5), (3, 6), (4, 6), (5, 6)}, "p")  # a looped glyph of our own
    return g


design("rune", "Epic", "rune: a looped glyph for a pupil, a lit rim", draw=_rune, glint=(7, 2))


# --- Legendary and up: 16 x 18 at 32 pixels a stud, the iris drawn per frame (frame k of n), a sparkle moving round it
LW, LH = 16, 18
LC = (LW / 2, LH / 2)


def _big_eye(rim_role="k"):
    g = blank(LW, LH)
    body = disc(LW, LH, LC[0], LC[1], LW / 2, LH / 2)
    put(g, body, "k")
    inside = body - rim(body)
    iris = disc(LW, LH, LC[0], LC[1] + 0.5, 6.2, 6.8) & inside
    if rim_role != "k":
        put(g, rim(body), rim_role)
    return g, body, inside, iris


def _polar(x, y, cy_shift=0.5):
    dx, dy = x + 0.5 - LC[0], y + 0.5 - (LC[1] + cy_shift)
    return math.hypot(dx, dy), math.atan2(dy, dx)


def _shines(g, body):
    put(g, {(3, 3), (4, 3), (3, 4), (4, 4), (5, 3), (3, 5)} & body, "w")
    put(g, {(11, 13), (12, 12)} & body, "w")


def _orbit_sparkle(g, body, k, n, radius=7.4):
    ang = -math.pi / 2 + 2 * math.pi * k / n
    x, y = int(LC[0] + radius * math.cos(ang)), int(LC[1] + 0.5 + radius * math.sin(ang) * 1.05)
    put(g, {(x, y)} & body, "s")


def _halo(k, n):
    g, body, inside, iris = _big_eye()
    for x, y in iris:
        r, _ = _polar(x, y)
        band = int(math.floor(r * 0.75 - k * 3.0 / n)) % 3
        g[y][x] = "abc"[band]
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 2.2, 2.4) & iris, "k")
    _shines(g, body)
    _orbit_sparkle(g, body, k, n)
    return g


design("halo", "Legendary", "halo: layered glowing rings that breathe outward, a sparkle round the iris", draw=_halo, glint=(14, 3))


def _bloom(k, n):
    g, body, inside, iris = _big_eye()
    for x, y in iris:
        r, th = _polar(x, y)
        petal = int(math.floor((th + 2 * math.pi * k / (n * 6)) / (2 * math.pi / 6))) % 2
        g[y][x] = "a" if r > 5.6 else ("c" if petal else "b")
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 2.0, 2.2) & iris, "p")
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 1.1, 1.2) & iris, "k")
    _shines(g, body)
    _orbit_sparkle(g, body, k, n)
    return g


design("bloom", "Legendary", "bloom: a flower of six glowing petals turning slowly, a sparkle", draw=_bloom, glint=(1, 14))


def _aurora(k, n):
    g, body, inside, iris = _big_eye(rim_role="r")
    for x, y in iris:
        v = math.sin(0.95 * y + 1.3 * math.sin(0.55 * x + 2 * math.pi * k / n) - 2 * math.pi * k / n)
        g[y][x] = "c" if v > 0.45 else ("b" if v > -0.35 else "a")
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 1.9, 2.3) & iris, "k")
    _shines(g, body)
    _orbit_sparkle(g, body, k, n)
    return g


design("aurora", "Legendary", "aurora: curtains of light drifting up the iris, a lit rim", draw=_aurora, glint=(14, 14))


# --- Cosmic: galaxy, nebula and solar irises whose frames swirl
def _stars(g, iris, k, n, share=0.07):
    for x, y in iris:
        if _hash(x, y, 11) < share:
            g[y][x] = "s" if (int(_hash(x, y, 12) * n) + k) % 3 else "c"


def _galaxy(k, n):
    g, body, inside, iris = _big_eye()
    for x, y in iris:
        r, th = _polar(x, y)
        arm = math.cos(2 * (th - 0.55 * r) + 2 * math.pi * k / n)
        g[y][x] = "c" if (r < 1.6 or arm > 0.6) else ("b" if arm > -0.15 else "a")
    _stars(g, {p for p in iris if g[p[1]][p[0]] == "a"}, k, n, 0.12)
    _shines(g, body)
    return g


design("galaxy", "Cosmic", "galaxy: a two-armed spiral galaxy that turns, twinkling stars", draw=_galaxy, glint=(14, 3))


def _noise(x, y, s):
    x0, y0 = math.floor(x), math.floor(y)
    fx, fy = x - x0, y - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    v = [[_hash(x0 + i, y0 + j, s) for i in (0, 1)] for j in (0, 1)]
    return (v[0][0] * (1 - fx) + v[0][1] * fx) * (1 - fy) + (v[1][0] * (1 - fx) + v[1][1] * fx) * fy


def _nebula(k, n):
    g, body, inside, iris = _big_eye()
    a = 2 * math.pi * k / n
    for x, y in iris:
        r, th = _polar(x, y)
        u, v = r * math.cos(th + a * 0.5), r * math.sin(th + a * 0.5)  # the cloud field turns a half lap a cycle
        val = 0.65 * _noise(u / 2.6 + 9, v / 2.6 + 9, 31) + 0.35 * _noise(u / 1.3 + 3, v / 1.3 + 3, 32)
        g[y][x] = "c" if val > 0.62 else ("b" if val > 0.42 else "a")
    _stars(g, {p for p in iris if g[p[1]][p[0]] == "a"}, k, n, 0.14)
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 1.2, 1.3) & iris, "c")
    _shines(g, body)
    return g


design("nebula", "Cosmic", "nebula: a turning cloud of three colours, a bright heart, stars", draw=_nebula, glint=(1, 3))


def _solar(k, n):
    g, body, inside, iris = _big_eye(rim_role="r")
    for x, y in iris:
        r, th = _polar(x, y)
        ray = math.cos(8 * (th + 0.18 * r) - 2 * math.pi * k / n)
        g[y][x] = "c" if r < 2.4 else ("b" if ray > 0.15 else "a")
    put(g, rim(iris) - {(x, y) for x, y in iris if y < 4}, "r")
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 1.0, 1.1) & iris, "w")
    _shines(g, body)
    return g


design("solar", "Cosmic", "solar: a sun whose pinwheel rays swirl round a white-hot core, a lit rim", draw=_solar, glint=(14, 14))


# --- Secret: dark eyes, one accent
def _void(k, n):
    g, body, inside, iris = _big_eye()
    put(g, iris, "a")
    for x, y in rim(iris):
        _, th = _polar(x, y)
        if int(math.floor((th + math.pi) / (2 * math.pi / 8) + 2.0 * k / n)) % 2 == 0:   # eight dashes, a quarter dash a frame
            g[y][x] = "r"
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 1.3, 1.4) & iris, "r")
    put(g, {(3, 3), (4, 3), (3, 4)} & body, "w")
    return g


design("void", "Secret", "void: a dark iris, a dashed ring of the one accent that turns", draw=_void, glint=(14, 3))


def _eclipse(k, n):
    g, body, inside, iris = _big_eye()
    put(g, iris, "a")
    ring = rim(iris) | rim(iris - rim(iris))
    for x, y in ring:
        _, th = _polar(x, y)
        g[y][x] = "r" if math.cos(5 * th - 2 * math.pi * k / n) > -0.3 else "b"
    put(g, iris - ring, "k")
    put(g, {(3, 3), (4, 3), (3, 4)} & body, "w")
    _orbit_sparkle(g, body, k, n, radius=7.6)
    return g


design("eclipse", "Secret", "eclipse: a black sun, a corona of the accent flaring round it", draw=_eclipse, glint=(1, 14))


# --- Roster w2_high (2026-10-21): Frostbyte's own eyes. `frost` (Epic) a six-point snowflake pupil lit in a two-tone ice iris with a lit rim
# (Sabrek); `lunar` (Cosmic) a moon that waxes and wanes across the iris over its 8 frames, the dark of it full of twinkling stars, a lit rim
# (Fenrir, the Moon element). Both big, soft and with a shine; cooler, never fiercer.
def _frost():
    g = _round_eye(9, 9, _split_iris("j", "i", 0.5), None, ((1, 1, 2, 1),), rim_role="r")
    put(g, {(4, 2), (2, 3), (4, 3), (6, 3), (3, 4), (4, 4), (5, 4), (2, 5), (4, 5), (6, 5), (4, 6)}, "p")
    put(g, {(4, 4)}, "w")
    return g


design("frost", "Epic", "frost: a six-point snowflake pupil lit in a two-tone ice iris, a lit rim", draw=_frost, glint=(7, 2))


def _lunar(k, n):
    g, body, inside, iris = _big_eye(rim_role="r")
    put(g, iris, "a")
    _stars(g, iris, k, n, 0.16)
    # the moon: a disc in the iris's middle; its terminator sweeps across it, new to full to new, over the cycle
    moon = disc(LW, LH, LC[0], LC[1] + 0.5, 4.2, 4.4) & iris
    phase = (1.23 + 2 * math.pi * k / n) % (2 * math.pi)   # frame 0 (the open eye) is a waxing crescent a third lit
    for x, y in moon:
        u = (x + 0.5 - LC[0]) / 4.2
        lit = u > math.cos(phase) if phase < math.pi else u < -math.cos(phase)
        g[y][x] = "c" if lit else "b"
    put(g, {(x, y) for x, y in rim(moon)}, "b")
    put(g, {(x, y) for x, y in moon if g[y][x] == "c" and _hash(x, y, 41) < 0.12}, "b")   # two or three craters on the lit face
    _shines(g, body)
    return g


design("lunar", "Cosmic", "lunar: a moon that waxes and wanes across a starry iris, a lit rim", draw=_lunar, glint=(14, 3))


# ------------------------------------------------------------------------------------------------ frames
def tier_rank(tier):
    return TIER_ORDER.index(tier)


def cycle_count(key):
    return CYCLE_FRAMES.get(DESIGNS[key]["tier"], 0)


def has_glint(key):
    return tier_rank(DESIGNS[key]["tier"]) >= tier_rank("Rare")


def open_grid(key, k=0):
    d = DESIGNS[key]
    if d["rows"] is not None:
        return parse(d["rows"])
    n = cycle_count(key)
    return d["draw"](k, n) if n else d["draw"]()


def _extent(grid):
    ys = [y for y, r in enumerate(grid) if any(ch != "." for ch in r)]
    xs = [x for r in grid for x, ch in enumerate(r) if ch != "."]
    return min(xs), max(xs), min(ys), max(ys)


def half_grid(key):
    """The blink's half frame: the lid down to a little under half the eye, its edge an ink line (an arc eye sinks a pixel). A design with its
    own `half` rows (Polish w2: kindle) uses them instead."""
    if DESIGNS[key].get("half"):
        return parse(DESIGNS[key]["half"])
    g = open_grid(key)
    h, w = len(g), len(g[0])
    if DESIGNS[key]["arc"]:
        out = blank(w, h)
        for y in range(h - 1, 0, -1):
            out[y] = list(g[y - 1])
        return out
    x0, x1, y0, y1 = _extent(g)
    cut = y0 + int(math.ceil((y1 - y0 + 1) * 0.45))
    out = [list(r) for r in g]
    for y in range(y0, cut):
        out[y] = ["."] * w
    lid = [x for x in range(w) if any(g[y][x] != "." for y in range(cut, h))]
    for x in lid:
        out[cut][x] = "k"
    return out


def closed_grid(key):
    """The blink's closed frame: a soft downward curve of ink across the eye's width, a little under its middle."""
    g = open_grid(key)
    h, w = len(g), len(g[0])
    x0, x1, y0, y1 = _extent(g)
    out = blank(w, h)
    if DESIGNS[key]["arc"]:
        mid = y1
        for x in range(x0, x1 + 1):
            out[mid][x] = "k"
        return out
    width = x1 - x0 + 1
    base = y0 + int(round((y1 - y0) * 0.6))
    for x in range(x0, x1 + 1):
        t = (x - x0 + 0.5) / width
        dip = int(round(math.sin(math.pi * t) * max(1, width // 5)))
        y = min(h - 1, base + dip)
        out[y][x] = "k"
        if width >= 12:
            out[min(h - 1, y + 1)][x] = "k" if 0.25 < t < 0.75 else out[min(h - 1, y + 1)][x]
    return out


def glint_grid(key, size):
    """A glint frame: a sparkle at the design's glint point, a plus of `size` (1 small, 2 big), drawn over the open eye and the plate."""
    g = open_grid(key)
    gx, gy = DESIGNS[key]["glint"]
    pts = {(gx, gy)} | {(gx + d * sx, gy + d * sy) for d in range(1, size + 1) for sx, sy in ((1, 0), (-1, 0), (0, 1), (0, -1))}
    if size >= 2 and len(g[0]) >= 12:
        pts |= {(gx + 1, gy + 1), (gx - 1, gy - 1), (gx + 1, gy - 1), (gx - 1, gy + 1)}
    put(g, pts, "s")
    return g


def eye_frames(key):
    """[(name, grid)] of one eye (the viewer's left one): open, half, closed, glint1 and glint2 (Rare and up), cycle0.. (Legendary and up)."""
    out = [("open", open_grid(key)), ("half", half_grid(key)), ("closed", closed_grid(key))]
    if has_glint(key):
        out += [("glint%d" % (i + 1), glint_grid(key, i + 1)) for i in range(GLINT_FRAMES)]
    for k in range(cycle_count(key)):
        out.append(("cycle%d" % k, open_grid(key, k)))
    return out


def frame_names(key):
    return [name for name, _ in eye_frames(key)]


def roles_used(key):
    used = set()
    for _, g in eye_frames(key):
        used |= {ch for r in g for ch in r if ch != "."}
    return sorted(ROLES[ch] for ch in used)


# ------------------------------------------------------------------------------------------------ the mouth and the cheeks (16 a stud; doubled at 32)
MOUTH_ROWS = {
    "none": [],
    "smile": ["k..k", ".kk."],
    "grin": ["k....k", ".kttk.", "..kk.."],
    "open": [".kk.", "ktTk", ".kk."],
    "cat": ["k.k.k", ".k.k."],
    "o": [".k.", "k.k", ".k."],
    "tooth": ["k...k", ".kwk."],
}
CHEEK_ROWS = {
    "none": [],
    "blush": ["hh"],
    "dots": ["h.h"],
    "hearts": ["h.h", "hhh", ".h."],
    "stars": [".h.", "hhh", ".h."],
}


def _scaled(rows, f):
    return ["".join(ch * f for ch in r) for r in rows for _ in range(f)]


# ------------------------------------------------------------------------------------------------ the plate
def plate_layout(eyes, head):
    """Where the plate sits and how big its texture is. `eyes`: the spec's `eyes` mapping; `head`: the host part (size, at). Returns
    {'density', 'w', 'h', 'size', 'centre', 'eye_l', 'eye_r', 'eye_w', 'eye_h', 'mouth', 'cheeks'} in plate pixels (x right, y down) and studs."""
    key = eyes["key"]
    d = DESIGNS[key]
    dens = DENSITY[d["tier"]]
    size = [float(v) for v in eyes.get("plate") or (head["size"][0] * 0.875, head["size"][1] * 0.7)]
    at = [float(v) for v in eyes.get("at") or (head["at"][0], head["at"][1] - head["size"][1] * 0.1)]
    w, h = int(round(size[0] * dens)), int(round(size[1] * dens))
    eye = open_grid(key)
    ew, eh = len(eye[0]), len(eye)
    spread = float(eyes.get("spread") or size[0] * 0.28)
    cx = w / 2.0
    top = int(eyes.get("eye_top", 1 if dens == 16 else 2))
    exl = int(round(cx - spread * dens - ew / 2.0))
    exr = w - exl - ew
    f = dens // 16
    mouth = _scaled(MOUTH_ROWS[eyes.get("mouth", "smile")], f)
    cheek = _scaled(CHEEK_ROWS[eyes.get("cheeks", "blush")], f)
    mw = len(mouth[0]) if mouth else 0
    mouth_xy = (int(round(cx - mw / 2.0)), top + eh - (2 * f if d["arc"] is False else 0) + f)
    if d["arc"]:
        mouth_xy = (mouth_xy[0], top + eh + f)
    cw = len(cheek[0]) if cheek else 0
    cy = top + eh + (0 if d["arc"] else -f)
    cheeks = [(exl - cw // 2, cy), (exr + ew - cw + cw // 2, cy)] if cheek else []
    return {"density": dens, "w": w, "h": h, "size": size, "centre": at, "eye_l": (exl, top), "eye_r": (exr, top), "eye_w": ew, "eye_h": eh,
            "mouth": (mouth, mouth_xy), "cheeks": (cheek, cheeks), "spread": spread}


def plate_frames(eyes, head):
    """[(name, rows)] of the whole plate per frame: both eyes (the right one mirrored), the mouth and the cheeks, '.' transparent. Raises
    ValueError when a piece falls off the plate."""
    lay = plate_layout(eyes, head)
    w, h = lay["w"], lay["h"]
    out = []
    for name, eye in eye_frames(eyes["key"]):
        g = blank(w, h)
        mouth, (mx, my) = lay["mouth"]
        cheek, cheeks = lay["cheeks"]
        for rows, (ox, oy) in [(cheek, c) for c in cheeks] + [(mouth, (mx, my))]:
            for y, r in enumerate(rows):
                for x, ch in enumerate(r):
                    if ch != ".":
                        _place(g, ox + x, oy + y, ch, w, h, "mouth or cheek")
        for (ox, oy), grid in ((lay["eye_l"], eye), (lay["eye_r"], [list(reversed(r)) for r in eye])):
            for y, r in enumerate(grid):
                for x, ch in enumerate(r):
                    if ch != ".":
                        _place(g, ox + x, oy + y, ch, w, h, "eye")
        out.append((name, rows_of(g)))
    return out


def _place(g, x, y, ch, w, h, what):
    if not (0 <= x < w and 0 <= y < h):
        raise ValueError("the %s runs off the %dx%d plate at (%d, %d): make the plate bigger or move the eyes" % (what, w, h, x, y))
    g[y][x] = ch


def resolve_colours(eyes, palette):
    """{char: '#RRGGBB'} for every role: the spec's `eyes.colours` (a palette role or a hex) first, then DEFAULTS. `palette` is {role: hex}.
    'T' (the open mouth's inside) shares the tongue."""
    given = eyes.get("colours") or {}
    out = {}
    for ch, role in ROLES.items():
        chain = [given[role]] if role in given else list(DEFAULTS[role])
        hexcol = None
        for v in chain:
            v = str(v)
            if v in palette:
                hexcol = palette[v]
                break
            if v.startswith("#") and len(v) == 7:
                hexcol = v.upper()
                break
        out[ch] = hexcol or "#FF00FF"
    out["T"] = out["t"]
    return out


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def sheet_layout(n, columns=SHEET_COLUMNS):
    cols = min(columns, n)
    return cols, (n + cols - 1) // cols


def sheet_scale(frame_w, frame_h, n, columns=SHEET_COLUMNS):
    """Texels a face pixel in the exported sheet of `n` frames of frame_w x frame_h pixels: the first of SHEET_SCALES that keeps the sheet
    within SHEET_MAX a side (1 if none does)."""
    cols, nrows = sheet_layout(n, columns)
    for k in SHEET_SCALES:
        if cols * frame_w * k <= SHEET_MAX and nrows * frame_h * k <= SHEET_MAX:
            return k
    return 1


def plate_sheet_rgba(frames, colours, columns=SHEET_COLUMNS, scale=1):
    """(width, height, RGBA bytes, row 0 at the top) of the plate's flipbook: frame i at column i % columns, row i // columns, each face
    pixel a `scale` x `scale` block of texels (nearest: the same picture, crisp under block compression and filtering; sheet_scale)."""
    fh, fw = len(frames[0][1]), len(frames[0][1][0])
    cols, nrows = sheet_layout(len(frames), columns)
    W, H = cols * fw * scale, nrows * fh * scale
    buf = bytearray(W * H * 4)
    for i, (_, rows) in enumerate(frames):
        ox, oy = (i % cols) * fw * scale, (i // cols) * fh * scale
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if ch == ".":
                    continue
                texel = bytes(_rgb(colours[ch]) + (255,)) * scale
                for dy in range(scale):
                    k = ((oy + y * scale + dy) * W + ox + x * scale) * 4
                    buf[k:k + 4 * scale] = texel
    return W, H, bytes(buf)


def write_png_rgba(path, w, h, rgba):
    import struct
    import zlib
    raw = b"".join(b"\x00" + rgba[y * w * 4:(y + 1) * w * 4] for y in range(h))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    pathlib.Path(path).write_bytes(png)


# ------------------------------------------------------------------------------------------------ the library sheet (Pillow)
# demo colours per rung for the sheet (a Verdant green skin under every eye; each rung's roles in colours a species of it might wear)
DEMO = {
    "Common": {"body": "#6CCB5F", "accent": "#D9F36B", "second": "#2F7A4B", "ink": "#142019"},
    "Uncommon": {"body": "#FFD34D", "accent": "#5CC8FF", "second": "#1E5FA8", "ink": "#1B1A2E"},
    "Rare": {"body": "#FF8A3D", "accent": "#3BC9A0", "second": "#16655A", "glow": "#FFE36B", "ink": "#21140F"},
    "Epic": {"body": "#8E6BFF", "accent": "#FFB3E6", "second": "#3A2378", "trim": "#FFD34D", "glow": "#FF5FA2", "ink": "#160F2A"},
    "Legendary": {"body": "#F4EBD9", "accent": "#FF7FC8", "second": "#7A2E86", "trim": "#FFC94D", "glow": "#FFE36B", "ink": "#1E1426"},
    "Cosmic": {"body": "#D7265C", "accent": "#2CC5B2", "second": "#2A1E66", "trim": "#FFB21E", "glow": "#FFE36B", "ink": "#2A1530"},
    "Secret": {"body": "#3A3F55", "accent": "#8E6BFF", "second": "#14121C", "trim": "#9AA0B4", "glow": "#B28CFF", "ink": "#0B0A10"},
}
DEMO_EYES = {
    "Cosmic": {"deep": "second", "mid": "accent", "bright": "glow"},
    "Secret": {"deep": "second", "mid": "#2A2840", "rim": "glow", "sparkle": "glow"},
    "Legendary": {"deep": "second", "mid": "accent", "bright": "glow"},
}


def library_sheet(path, scale_small=12, scale_big=6):
    """Every design in tier order: its tier, key and label, and every frame on a patch of a tier's skin colour, at one physical size (the
    16-a-stud designs drawn at `scale_small`, the 32-a-stud ones at `scale_big`)."""
    from PIL import Image, ImageDraw, ImageFont
    try:
        bold = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 20)
        reg = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 14)
        big = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 30)
    except OSError:
        bold = reg = big = ImageFont.load_default()
    keys = sorted(DESIGNS, key=lambda k: (tier_rank(DESIGNS[k]["tier"]), list(DESIGNS).index(k)))
    pad, label_w, cell = 16, 300, 6 * 18 + 22
    max_frames = max(len(eye_frames(k)) for k in keys)
    W = label_w + max_frames * (cell + 6) + pad * 2
    row_h = cell + 26
    H = 130 + len(keys) * row_h + 40
    img = Image.new("RGB", (W, H), "#F6F0E6")
    d = ImageDraw.Draw(img)
    d.text((pad, 14), "Eye library v1 (Decision B46): %d designs, each with its own frames, on the face plate" % len(keys), font=big, fill="#1B1F3B")
    d.text((pad, 56), "Open, half, closed (the blink) for all; two glint frames from Rare; an iris cycle of 6 (Legendary) or 8 (Cosmic, Secret) "
           "frames that swirl. Common to Epic at 16 px a stud, Legendary and up at 32 (a finer face grid). Every eye big, soft and with a shine.",
           font=reg, fill="#5F6375")
    d.text((pad, 78), "Each eye shown at the same physical size (0.5 stud wide) on a patch of a skin of its rung; the right eye is the mirror. "
           "Colours are demo colours: a species picks its own in its note's `eyes.colours`.", font=reg, fill="#5F6375")
    tier_hex = {"Common": "#8A8A8A", "Uncommon": "#2DBE4A", "Rare": "#3B82F6", "Epic": "#C026D3", "Legendary": "#E08A00", "Cosmic": "#EC4899",
                "Secret": "#111111"}
    y = 110
    last_tier = None
    for key in keys:
        des = DESIGNS[key]
        tier = des["tier"]
        pal = DEMO[tier]
        cols = resolve_colours({"colours": DEMO_EYES.get(tier, {})}, pal)
        if tier != last_tier:
            d.line((pad, y, W - pad, y), fill="#D2CABB", width=2)
            last_tier = tier
        d.text((pad, y + 10), tier.upper(), font=reg, fill=tier_hex[tier])
        d.text((pad, y + 28), key, font=bold, fill="#1B1F3B")
        label = des["label"].split(": ", 1)[-1]
        words, line, ly = label.split(), "", y + 54
        for wd in words:
            if d.textlength(line + " " + wd, font=reg) > label_w - 30:
                d.text((pad, ly), line.strip(), font=reg, fill="#5F6375")
                ly += 17
                line = ""
            line += " " + wd
        d.text((pad, ly), line.strip(), font=reg, fill="#5F6375")
        scale = scale_small if DENSITY[tier] == 16 else scale_big
        for i, (name, grid) in enumerate(eye_frames(key)):
            ox = pad + label_w + i * (cell + 6)
            oy = y + 8
            d.rectangle((ox, oy, ox + cell, oy + cell), fill=pal["body"])
            gw, gh = len(grid[0]) * scale, len(grid) * scale
            gx, gy = ox + (cell - gw) // 2, oy + (cell - gh) // 2
            for yy, r in enumerate(grid):
                for xx, ch in enumerate(r):
                    if ch != ".":
                        d.rectangle((gx + xx * scale, gy + yy * scale, gx + (xx + 1) * scale - 1, gy + (yy + 1) * scale - 1), fill=cols[ch])
            d.text((ox + 4, oy + cell + 2), name, font=reg, fill="#5F6375")
        y += row_h
    img.save(path)
    return path


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if "--list" in argv:
        for key, d in DESIGNS.items():
            g = open_grid(key)
            print("%-9s %-10s %2dx%-2d @%d/stud  %-60s roles: %s" % (key, d["tier"], len(g[0]), len(g), DENSITY[d["tier"]],
                                                                   ", ".join(frame_names(key)), ", ".join(roles_used(key))))
        print("%d designs" % len(DESIGNS))
        return 0
    if "--sheet" in argv:
        print(library_sheet(argv[argv.index("--sheet") + 1]))
        return 0
    print(__doc__)
    return 2


# ------------------------------------------------------------------------------------------------ Roster w2_low (2026-10-21)
# World 2's four Uncommons ran one design short of the Uncommon rung. Appended here in one block; drawn like the rest (the viewer's left eye).
design("kindle", "Uncommon", "kindle: a dark iris lit from below, two tongues of ember glow rising beside a big pupil", rows=[
    "..kkkk..",
    ".kjjjjk.",
    "kwwjjjjk",
    "kwwkkjjk",
    "kjkkkkjk",
    "kikkkkik",
    "kiikkiik",
    ".kiiiik.",
    "..kkkk..",
])
# ------------------------------------------------------------------------------------------------ Roster w1_high (2026-10-21)
# Added by the Roster w1_high batch, after the library above (kept above the __main__ guard so --list and --sheet see it).
def _echo(k, n):
    """Secret: a dark iris where rings of the one accent ripple outward from a lit core and fade as they go, like a note heard from far
    away (Syrinx, the shadow goat with the pipes); a new ring is born every half cycle."""
    g, body, inside, iris = _big_eye()
    put(g, iris, "a")
    spacing = 3.2
    for x, y in iris:
        r, _ = _polar(x, y)
        wave = (r - spacing * k / n) % spacing
        if r > 1.6 and wave < 0.95:
            g[y][x] = "r" if r < 4.6 else "b"
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 1.4, 1.5) & iris, "r")
    put(g, disc(LW, LH, LC[0], LC[1] + 0.5, 0.6, 0.6) & iris, "s")
    put(g, {(3, 3), (4, 3), (3, 4)} & body, "w")
    return g


design("echo", "Secret", "echo: a dark iris where rings of the one accent ripple out from a lit core and fade, a note heard from far away",
       draw=_echo, glint=(14, 3))
# ------------------------------------------------------------------------------------------------ Polish w2 (2026-10-21)
# World 2's polish pass. (1) kindle's half frame: the generic lid (a flat ink bar over the lit lower half) made Sizz look cross for its 0.18 s,
# a scowl over two glowing lower corners; its own half is a rounded lid (an arch, like a content squint) over a dark iris with its shine, the
# ember only in two bottom pixels (a first try kept the red iris band and the lit corners, and the half eye read as a pair of lips). (2) `beam`, one new Common design: Mitt's `happy` arcs (7 x 4) read small on its 2-stud snowball, so a bigger, bolder
# closed smile, 9 x 5 with two-pixel arcs (28 percent of the head's width), for Frostbyte's one arc-eyed Common.
DESIGNS["kindle"]["half"] = [
    "........",
    "........",
    "........",
    "........",
    "..kkkk..",
    ".kwkkkk.",
    "kkkkkkkk",
    ".kkiikk.",
    "..kkkk..",
]
design("beam", "Common", "beam: a big closed smile, two-pixel arcs, for a round face that wants a bigger happy eye", arc=True, rows=[
    "...kkk...",
    ".kkkkkkk.",
    "kkk...kkk",
    "kk.....kk",
    "k.......k",
])


# ------------------------------------------------------------------------------------------------ Polish w1 (2026-10-21)
# Added by the Polish w1 batch. `starlit` (Legendary): the library's big eyes are 16 x 18 pixels at 32 a stud, a quarter of a 2-stud head;
# Cosmoo's read small on its cloud, so this one is 22 x 24 (a third of the head): layered rings that breathe outward like `halo`, a four-point
# star for a pupil and three twinkling stars in the iris that take turns over the 6 frames.
SW, SH = 22, 24
SC = (SW / 2, SH / 2)


def _starlit(k, n):
    g = blank(SW, SH)
    body = disc(SW, SH, SC[0], SC[1], SW / 2, SH / 2)
    put(g, body, "k")
    inside = body - rim(body)
    iris = disc(SW, SH, SC[0], SC[1] + 0.5, 8.6, 9.4) & inside
    cy = SC[1] + 0.5
    for x, y in iris:
        r = math.hypot(x + 0.5 - SC[0], y + 0.5 - cy)
        g[y][x] = "abc"[int(math.floor(r * 0.6 - k * 3.0 / n)) % 3]
    star = {(x, y) for x, y in iris if abs(x + 0.5 - SC[0]) ** 0.5 + abs(y + 0.5 - cy) ** 0.5 <= 2.25}
    put(g, star, "k")
    twinkles = [(6, 15), (15, 8), (14, 16)]
    for i, (tx, ty) in enumerate(twinkles):
        if (k + 2 * i) % n < 3:
            put(g, {(tx, ty)} & iris, "s")
    put(g, {(4, 4), (5, 4), (6, 4), (4, 5), (5, 5), (6, 5), (4, 6), (5, 6), (7, 4)} & body, "w")
    put(g, {(16, 18), (17, 17)} & body, "w")
    return g


design("starlit", "Legendary", "starlit: big layered rings that breathe outward round a four-point star pupil, three stars twinkling in turn",
       draw=_starlit, glint=(18, 4))
# `plush` (Common): `button` is 7 x 7 with clipped corners, and on Glim it read as two little screens; this one is an octagon, rounder at 16
# pixels a stud, a plush toy's sewn button with two holes and a shine.
design("plush", "Common", "plush: a round sewn button, two holes, a shine", rows=[
    "..kkkk..",
    ".kwiiik.",
    "kwwiiiik",
    "kiiiiiik",
    "kikiikik",
    "kiiiiiik",
    ".kiiiik.",
    "..kkkk..",
])


if __name__ == "__main__":
    sys.exit(main())
