#!/usr/bin/env python3
"""The world's shared tile textures (Decision B44): one 64 x 64 PNG a ground material, 2 x 2 studs at the world cell (0.25 studs), so 8 x 8
cells of 8 texels, made by the block-cell rules of tools/blocky/cells.py (Blocky-Style "Cells": square flat cells, a jitter in L* only at
1 : 6 : 1, motifs in whole and half steps of L* 6, the edge rule, a one-texel grout a step down) in the world palettes of Blocky-Style
"Environment" (E3) and "World 2: Frostbyte palette".

Every tile repeats without a seam: each hash is taken on the cell's position modulo the tile (8 cells), each lattice (blobs, cobbles, plates)
wraps on the tile, and every row and column pattern has a period that divides 8. The block edge of a tile (a grass top's half-step rim, a dirt
brick's border) is part of the pattern: a field of tiles reads as a field of 2-stud blocks, as the dioramas do (E1).

The keys are shared with the world worker, who references them through a data table (image id 0 until the Mac uploads them):

  GrassTop GrassSide Dirt Path Stone Sand Water WoodPlank Snow SnowSide PackedSnow Ice FrozenWater Rock
  MoonPath MoonGrass GlowWater   (World 1's Starhollow Forest, the moonlit region of Decision B48)

  python3 -I tools/blocky/world_tiles.py                     # write assets/textures/blocky_tiles/<Key>.png and the contact sheet
  python3 -I tools/blocky/world_tiles.py --sheet <png>       # the contact sheet elsewhere (each tile 3 x 3, so a seam would show)
  python3 -I tools/blocky/world_tiles.py --check             # the PNGs on disk are what this tool makes, 64 x 64, and seamless

Standard library for the tiles (raster.write_png); Pillow only for the contact sheet.
"""
from __future__ import annotations

import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
import cells as C  # noqa: E402
import raster  # noqa: E402

N = 8                   # cells a tile side: 2 studs at the world cell of 0.25
PX = C.PX               # texels a cell (8), so a tile is 64 x 64
SIZE = N * PX
OUT = ROOT / "assets/textures/blocky_tiles"
SHEET = ROOT / "media/studio/2026-10-21/world_tiles_v2.png"   # v1 (the fourteen) stays beside it
STEP = C.STEP

# key: (world, material whose PARAMS (jitter, grout) it takes, base hex, aux hex, accent hex, what it is)
TILES = {
    "GrassTop": (1, "grass", "#6FBF4A", None, None, "the meadow's top: faint blobs, a lit blade in twenty, the rim a half step down"),
    "GrassSide": (1, "grass", "#6FBF4A", "#8A5A3B", None, "a grass block's side: the fringe one to three cells deep over dirt"),
    "Dirt": (1, "dirt", "#8A5A3B", None, None, "dirt bricks: two 2 x 1 stud brick faces, blobs and pebbles, framed"),
    "Path": (1, "stone", "#C9B48A", None, None, "the cobbled path: cobbles about three cells, one-cell cracks"),
    "Stone": (1, "stone", "#9E9E8E", None, None, "World 1 stone: dressed slabs four cells square, a joint a step down"),
    "Sand": (1, "dirt", "#E8D3A0", None, None, "the pond's shore: wind ripples a half step, grains a step off"),
    "Water": (1, "water", "#3FA2E6", None, None, "the pond: diagonal ripple dashes, a sparkle; no grout"),
    "WoodPlank": (1, "wood", "#C08A55", None, None, "camp decking: four planks two cells wide, grain rows, a staggered joint, nails"),
    "Snow": (2, "snow", "#F2F6FA", None, None, "Frostbyte's top: soft drifts, a sparkle in sixty, the rim a full step down"),
    "SnowSide": (2, "snow", "#F2F6FA", "#B9CADA", None, "a snow block's side: the lip two to four cells deep over packed snow"),
    "PackedSnow": (2, "packed_snow", "#B9CADA", None, None, "packed snow: strata every third row (3, 3, 2), ice grains"),
    "Ice": (2, "ice", "#BFEBFA", None, None, "clear ice: a light band on the other diagonal every eight cells, a sparkle"),
    "FrozenWater": (2, "frozen_water", "#A9D6F5", None, None, "the frozen pond: four plates a tile, cracks on most borders, a bubble"),
    "Rock": (2, "stone", "#A9B7C0", None, None, "Frostbyte rock: ledges two or three rows tall, broken by cracks, chips"),
    # World 1's Starhollow Forest (B48), moonlit: a pale lavender path, deep teal-green grass, glowing pool water
    "MoonPath": (1, "stone", "#CBC2EE", None, None, "Starhollow's pale lavender path: cobbles about three cells, one-cell cracks"),
    "MoonGrass": (1, "grass", "#2B6F68", None, "#9A7EE6", "Starhollow's grass: deep teal-green blobs, a lit blade, violet specks"),
    "GlowWater": (1, "water", "#2648B8", None, "#9FE6FF", "the moon pool and the stream: deep blue, bright ripple dashes, sparkles"),
}
KEYS = tuple(TILES)


# ------------------------------------------------------------------------------------------------ periodic hashing
def h(seed, i, j, *more):
    """C.rand on the cell's place modulo the tile: the same cell in every repeat."""
    return C.rand(seed, i % N, j % N, *more)


def pnoise(seed, i, j, spacing):
    """Value noise on a lattice every `spacing` cells (a divisor of N) that wraps on the tile; in [0, 1)."""
    m = N // spacing
    x0, y0 = i // spacing, j // spacing
    fx = (i - x0 * spacing + 0.5) / spacing
    fy = (j - y0 * spacing + 0.5) / spacing
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = C.rand(seed, x0 % m, y0 % m), C.rand(seed, (x0 + 1) % m, y0 % m)
    c, d = C.rand(seed, x0 % m, (y0 + 1) % m), C.rand(seed, (x0 + 1) % m, (y0 + 1) % m)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def region(i, j, seeds):
    """The index of the nearest seed (x, y in cells) to the cell's centre, distances wrapped on the tile."""
    best, rid = 1e9, 0
    for k, (sx, sy) in enumerate(seeds):
        dx = abs(i + 0.5 - sx) % N
        dy = abs(j + 0.5 - sy) % N
        dx, dy = min(dx, N - dx), min(dy, N - dy)
        d = dx * dx + dy * dy
        if d < best:
            best, rid = d, k
    return rid


def lattice_seeds(seed, per_side):
    """`per_side` squared seeds, one jittered inside each square of a per_side x per_side lattice over the tile."""
    s = N / per_side
    return [(a * s + 0.1 * s + 0.8 * s * C.rand(seed, a, b), b * s + 0.1 * s + 0.8 * s * C.rand(seed + 1, a, b))
            for a in range(per_side) for b in range(per_side)]


COBBLES = lattice_seeds(121, 3)      # nine cobbles on 8 cells: about 2.7 across, the bible's "three"
PLATES = lattice_seeds(131, 2)      # four plates a tile, about four cells across (two tiles make the bible's seven-cell plate pattern)


# ------------------------------------------------------------------------------------------------ the tiles: (key, steps, material) a cell
# i runs left to right, j bottom to top, both 0..7; `top` is the tile's top row (j = 7). Each returns the colour key ('base', 'aux',
# 'accent'), the steps of L* 6 the motif moves it, and the material whose jitter and grout the cell takes.
def _rim(i, j, amount):
    """A top face's rim (the block edge of a top): `amount` steps on the border cells."""
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    return amount if (i in (0, N - 1) or j in (0, N - 1)) else 0.0


def _side_edge(i, j, rows, top_step, edge_step):
    """The edge rule on a side face `rows` tall whose bottom row is j0: the top row `top_step`, the left, right and bottom border `edge_step`."""
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    j0, nv = rows
    jj = j - j0
    if jj == nv - 1:
        return top_step
    if i in (0, N - 1) or jj == 0:
        return edge_step
    return 0.0


def grass_top(i, j):
    lvl = 0.5 * C.level(pnoise(201, i, j, 4), 0.36, 0.64)
    if h(203, i, j) < 0.05:
        lvl += 1.0
    return "base", lvl + _rim(i, j, -0.5), "grass"


def dirt_cell(i, j, key="base"):
    lvl = 0.5 * C.level(pnoise(211, i, j, 2), 0.36, 0.64)
    r = h(213, i, j)
    if r < 0.03:
        lvl += 1.0
    elif r > 0.97:
        lvl -= 1.0
    return key, lvl


FRINGE = [1 + (C.rand(221, i) < 0.55) + (C.rand(223, i) < 0.2) for i in range(N)]


def grass_side(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    depth = N - 1 - j
    if depth < FRINGE[i]:
        return "base", (0.5 if depth == 0 else 0.0) + (-0.5 if i in (0, N - 1) else 0.0), "grass"
    key, lvl = dirt_cell(i, j, "aux")
    return key, lvl + _side_edge(i, j, (0, N), 0.0, -0.5), "dirt"


def dirt(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    key, lvl = dirt_cell(i, j)
    rows = (0, 4) if j < 4 else (4, 4)
    return key, lvl + _side_edge(i, j, rows, 0.0, -0.5), "dirt"


def path(i, j):
    rid = region(i, j, COBBLES)
    if region(i + 1, j, COBBLES) != rid or region(i, j - 1, COBBLES) != rid:
        return "base", -1.5, "stone"
    lv = (-0.75, 0.0, 0.0, 0.75)[int(C.rand(225, rid) * 4)]
    return "base", lv + 0.5 + _rim(i, j, 0.5), "stone"


def stone(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    # dressed slabs four cells square in a running bond (the upper row shifted by two), each a quarter step off, the joint a step down
    row = j // 4
    shift = 2 * row
    col = ((i + shift) % N) // 4
    if j % 4 == 3 or (i + shift) % 4 == 3:
        return "base", -1.0, "stone"
    lv = (-0.5, -0.25, 0.25, 0.5)[int(C.rand(231, row, col) * 4)]
    if h(233, i, j) < 0.04:
        lv += 1.0  # a chip catching the light
    return "base", lv + 0.5, "stone"


def sand(i, j):
    # wind ripples: a line a half step down wandering one row up or down along the tile (period 8), a lit cell on its sunny side; grains
    wave = int(round(1.0 * math.sin(2 * math.pi * i / N)))
    k = (j - wave) % 4
    lvl = -0.5 if k == 0 else (0.5 if k == 1 else 0.0)
    r = h(241, i, j)
    if r < 0.04:
        lvl += 1.0
    elif r > 0.97:
        lvl -= 1.0
    return "base", lvl, "dirt"


def water(i, j):
    if (i + 2 * j) % N == 0 and C.rand(251, (i % N) // 3, j % N) < 0.7:
        return "base", 1.0, "water"
    if h(253, i, j) < 0.02:
        return "base", 2.5, "water"
    return "base", 0.3 * C.level(pnoise(255, i, j, 4)), "water"


def wood_plank(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    # four planks two cells wide running across; each plank's top row lit and bottom row a step down (the gap); one joint a plank, staggered;
    # a nail a step and a half up beside each joint; a fixed shade per plank and a grain row in each
    plank = j // 2
    joint = (2 * plank + int(C.rand(261, plank) * 2) * 3) % N
    if i == joint:
        return "base", -1.5, "wood"
    lvl = (-0.5, 0.0, 0.25, 0.5)[int(C.rand(263, plank) * 4)]
    lvl += -1.0 if j % 2 == 0 else 0.5
    if (i - joint) % N == 1 and j % 2 == 1:
        return "base", 1.5, "wood"
    if C.rand(265, plank, i // 3) < 0.25:
        lvl -= 0.5  # a grain streak
    return "base", lvl, "wood"


def snow(i, j):
    lvl = 0.5 * C.level(pnoise(271, i, j, 4), 0.33, 0.67)
    if h(273, i, j) < C.SNOW_SPARKLE * 1.5:
        lvl += 1.0
    return "base", lvl + _rim(i, j, -1.0), "snow"


LIP = [C.SNOW_LIP[0] + (C.rand(281, i) < 0.5) + (C.rand(283, i) < 0.25) for i in range(N)]
STRATA = (0, 3, 6)   # the strata every third row, as near as eight rows allow (3, 3, 2)


def packed_cell(i, j, key="base"):
    lvl = 0.0
    if j % N in STRATA and C.rand(285, (i % N) // 3, j % N) < 0.8:
        lvl = -0.5
    if h(287, i, j) < 0.04:
        lvl += 0.75
    return key, lvl


def snow_side(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    depth = N - 1 - j
    lip = LIP[i]
    if depth < lip:
        return "base", (0.5 if depth == 0 else (-1.0 if depth == lip - 1 else 0.0)) + (-0.5 if i in (0, N - 1) and depth else 0.0), "snow"
    key, lvl = packed_cell(i, j, "aux")
    return key, lvl + _side_edge(i, j, (0, N), 0.0, -0.5), "packed_snow"


def packed_snow(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    key, lvl = packed_cell(i, j)
    return key, lvl + _side_edge(i, j, (0, N), 0.0, -0.5), "packed_snow"


def ice(i, j):
    d = (i - j) % N
    lvl = {0: 1.5, 1: 0.5}.get(d, 0.0)
    if (i + j) % N == N // 2:
        lvl -= 0.5
    if h(291, i, j) < 0.02:
        lvl = 2.0
    return "base", lvl + _rim(i, j, 1.0), "ice"


def frozen_water(i, j):
    rid = region(i, j, PLATES)
    for other in (region(i + 1, j, PLATES), region(i, j - 1, PLATES)):
        if other != rid and C.rand(293, (i % N) // 2, (j % N) // 2) < 0.75:
            return "base", -1.5, "frozen_water"
    if h(295, i, j) < 0.03:
        return "base", 0.5, "frozen_water"
    return "base", 0.25 * C.level(pnoise(297, i, j, 4), 0.3, 0.7), "frozen_water"


LEDGES = ((0, 3), (3, 2), (5, 3))   # (bottom row, rows): three ledges up the tile, 3, 2 and 3 rows tall


def rock(i, j):
    i, j = i % N, j % N   # a block edge or a column table: the place inside the tile
    # a rock face in ledges: each ledge a fixed shade, its top row lit and its bottom row in shadow, broken by one or two vertical cracks;
    # a pale chip now and then
    k = next(n for n, (j0, rows) in enumerate(LEDGES) if j0 <= j < j0 + rows)
    j0, rows = LEDGES[k]
    lv = (-0.75, -0.25, 0.25, 0.75)[int(C.rand(301, k) * 4)]
    crack = (int(C.rand(303, k) * N) + (i >= 4) * 4) % N
    if i == crack and C.rand(305, k, i) < 0.85:
        return "base", -1.5, "stone"
    if j == j0 + rows - 1:
        lv += 1.0
    elif j == j0:
        lv -= 1.0
    if h(307, i, j) < 0.04:
        lv += 1.0
    return "base", lv, "stone"


def moon_grass(i, j):
    # the meadow's grass top (blobs, a lit blade, the half-step rim) with a violet speck (the accent) in about fourteen
    key, lvl, mat = grass_top(i, j)
    if h(311, i, j) < 0.07 and lvl < 0.75:
        return "accent", 0.0, mat
    return key, lvl, mat


def glow_water(i, j):
    # the pool: deep blue, ripple dashes on the water diagonal in the bright accent (the light on the water), a lit row beside them, a
    # sparkle in thirty, a slow half-step swell between; no grout (water)
    if (i + 2 * j) % N == 0 and C.rand(321, (i % N) // 3, j % N) < 0.75:
        return "accent", 0.0, "water"
    if (i + 2 * j) % N == 1 and C.rand(323, (i % N) // 3, j % N) < 0.45:
        return "base", 1.5, "water"
    if h(325, i, j) < 0.035:
        return "accent", 1.5, "water"
    return "base", 0.5 * C.level(pnoise(327, i, j, 4)), "water"


RAW = {"GrassTop": grass_top, "GrassSide": grass_side, "Dirt": dirt, "Path": path, "Stone": stone, "Sand": sand, "Water": water,
            "WoodPlank": wood_plank, "Snow": snow, "SnowSide": snow_side, "PackedSnow": packed_snow, "Ice": ice, "FrozenWater": frozen_water,
            "Rock": rock, "MoonPath": path, "MoonGrass": moon_grass, "GlowWater": glow_water}
# the painters as the tile calls them: a cell's place taken modulo the tile, so a lookup one tile over is the same cell
PAINTERS = {k: (lambda f: (lambda i, j: f(i % N, j % N)))(f) for k, f in RAW.items()}


def jitter(i, j, mat):
    r = h(41, i, j, C.MAT_ID[mat])
    return -1 if r < C.JITTER_SHARE else (1 if r >= 1.0 - C.JITTER_SHARE else 0)


def tile(key):
    """The tile as RGB bytes, 64 x 64, row 0 at the top."""
    _, _, base, aux, accent, _ = TILES[key]
    cols = {"base": C.hex_rgb(base), "aux": C.hex_rgb(aux or base), "accent": C.hex_rgb(accent or base)}
    buf = bytearray(SIZE * SIZE * 3)
    stride = SIZE * 3
    for j in range(N):
        for i in range(N):
            ck, steps, mat = PAINTERS[key](i, j)
            params = C.PARAMS[mat]
            rgb = C.shade(cols[ck], steps * STEP + jitter(i, j, mat) * params["jitter"])
            weight = params.get("grout", 1.0)
            dark = bytes(C.shade(rgb, C.GROUT_STEPS * STEP * weight)) if weight else bytes(rgb)
            gx, gy = i * PX, (N - 1 - j) * PX
            for r in range(PX):
                k = (gy + r) * stride + gx * 3
                if weight and r >= PX - C.GROUT:
                    buf[k:k + PX * 3] = dark * PX
                else:
                    buf[k:k + (PX - C.GROUT) * 3] = bytes(rgb) * (PX - C.GROUT)
                    buf[k + (PX - C.GROUT) * 3:k + PX * 3] = (dark if weight else bytes(rgb)) * C.GROUT
    return buf


def seamless(key):
    """True when the tile repeats without a seam: the painter gives the same cell one tile over in every direction. The painters take any
    cell position (wrapped below), and every hash, lattice and row pattern inside them has a period that divides the tile."""
    raw = RAW[key]
    for j in range(N):
        for i in range(N):
            a = raw(i, j)
            for di, dj in ((N, 0), (0, N), (N, N), (-N, 0), (0, -N)):
                if raw(i + di, j + dj) != a:
                    return False
    return True


def write_all(out=OUT):
    out.mkdir(parents=True, exist_ok=True)
    for key in KEYS:
        raster.write_png(str(out / ("%s.png" % key)), SIZE, SIZE, tile(key), 3)
    return [out / ("%s.png" % k) for k in KEYS]


def contact_sheet(path=SHEET, repeat=3, scale=2):
    """Every tile 3 x 3 at twice size (nearest), so a seam would show as a line through each square, with its key, world, colours and motif."""
    from PIL import Image, ImageDraw, ImageFont
    try:
        bold = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 22)
        reg = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 14)
    except OSError:
        bold = reg = ImageFont.load_default()
    cols = 5
    block = SIZE * repeat * scale
    cell_w, cell_h = block + 30, block + 92
    rows = (len(KEYS) + cols - 1) // cols
    W, H = cols * cell_w + 30, rows * cell_h + 110
    sheet = Image.new("RGB", (W, H), "#F6F0E6")
    d = ImageDraw.Draw(sheet)
    d.text((20, 16), "World tiles v2 (Blocky-Style, Cells; Decision B44): each 64 x 64 tile (2 x 2 studs, 8 x 8 cells) shown 3 x 3 at 2x, "
           "so a seam would cross every square", font=bold, fill="#1B1F3B")
    d.text((20, 50), "assets/textures/blocky_tiles/<Key>.png from tools/blocky/world_tiles.py. Flat cells, jitter in L* only at 1 : 6 : 1, motifs "
           "in steps of L* 6, the block edge in the pattern, a one-texel grout a step down (half on grass, snow and ice, none on water)",
           font=reg, fill="#5F6375")
    for k, key in enumerate(KEYS):
        world, mat, base, aux, _, what = TILES[key]
        img = Image.frombytes("RGB", (SIZE, SIZE), bytes(tile(key)))
        big = Image.new("RGB", (SIZE * repeat, SIZE * repeat))
        for a in range(repeat):
            for b in range(repeat):
                big.paste(img, (a * SIZE, b * SIZE))
        big = big.resize((block, block), Image.Resampling.NEAREST)
        ox, oy = 20 + (k % cols) * cell_w, 86 + (k // cols) * cell_h
        sheet.paste(big, (ox, oy))
        d.text((ox, oy + block + 6), "%s  (World %d, %s)" % (key, world, mat), font=bold, fill="#1B1F3B")
        d.text((ox, oy + block + 34), "  ".join(x for x in (base, aux) if x), font=reg, fill="#5F6375")
        d.text((ox, oy + block + 52), what[:62], font=reg, fill="#5F6375")
        if len(what) > 62:
            d.text((ox, oy + block + 68), what[62:124], font=reg, fill="#5F6375")
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    return path


def check(out=OUT):
    """[] when every PNG is on disk, 64 x 64 and byte-for-byte what tile() paints, and every tile repeats without a seam."""
    problems = []
    for key in KEYS:
        p = out / ("%s.png" % key)
        if not p.is_file():
            problems.append("missing %s" % p.name)
            continue
        w, h_ = raster.read_png_size(str(p)) if hasattr(raster, "read_png_size") else _png_size(p)
        if (w, h_) != (SIZE, SIZE):
            problems.append("%s is %dx%d, not %dx%d" % (p.name, w, h_, SIZE, SIZE))
        tmp = out / (".%s.check.png" % key)
        raster.write_png(str(tmp), SIZE, SIZE, tile(key), 3)
        same = tmp.read_bytes() == p.read_bytes()
        tmp.unlink()
        if not same:
            problems.append("%s differs from what the tool paints (python3 -I tools/blocky/world_tiles.py)" % p.name)
        if not seamless(key):
            problems.append("%s does not repeat seamlessly" % key)
    return problems


def _png_size(path):
    import struct
    data = pathlib.Path(path).read_bytes()[:24]
    return struct.unpack(">II", data[16:24])


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if "--check" in argv:
        problems = check()
        for p in problems:
            print("  " + p)
        print("world tiles: %d keys, %s" % (len(KEYS), "clean" if not problems else "%d problems" % len(problems)))
        return 1 if problems else 0
    sheet = pathlib.Path(argv[argv.index("--sheet") + 1]) if "--sheet" in argv else SHEET
    paths = write_all()
    print("world tiles: wrote %d tiles to %s" % (len(paths), OUT.relative_to(ROOT)))
    print("contact sheet: %s" % contact_sheet(sheet))
    return 0


if __name__ == "__main__":
    sys.exit(main())
