#!/usr/bin/env python3
"""World generator: a hand-authored, seeded world description -> a block-cell height map, greedy-merged into Parts, emitted as Luau data.

    python3 -I tools/blocky/world_gen.py                # both worlds and the kit, written into src/shared/data/
    python3 -I tools/blocky/world_gen.py --check        # regenerate in memory and fail if the committed files differ
    python3 -I tools/blocky/world_gen.py --report       # counts against the budget, reachability, one line each

Inputs: tools/blocky/worlds/world1.json, world2.json (the description of each world: features applied in order) and kit.json (the
ground kinds, the placeholder recipes of every scatter prop, the budgets). Outputs: src/shared/data/WorldGen1.luau, WorldGen2.luau and
WorldKit.luau. The Luau builder (ServerScriptService.Server.Services.Meadow) reads the generated tables; Shared/WorldGrid answers
"how high is the ground here" from them. Standard library only, deterministic (a hash noise of its own, never Python's `hash`).

The grid: `size` studs a side, a column every `cell` studs (2: one ground block of the B44 world cell, 8 cells across), heights in whole
studs relative to the camp's ground (the floor top the old builder used). A column is a cap (the top stud, the kind's top and side tile)
over a body (the kind's body tile, down to the world's base) only where a neighbour is two or more studs lower, so the side of a cliff
shows dirt or rock under a grass fringe and a 1-stud step shows only the cap. Equal columns are greedy-merged into rectangles inside
chunks of `chunk` cells, so a part never crosses a streaming chunk.
"""
from __future__ import annotations

import argparse
import json
import math
import pathlib
import sys
from collections import deque

ROOT = pathlib.Path(__file__).resolve().parents[2]
WORLDS = ROOT / "tools/blocky/worlds"
OUT = ROOT / "src/shared/data"
FACE_BITS = {"xp": 1, "xn": 2, "zp": 4, "zn": 8}   # +X, -X, +Z, -Z faces of a merged rectangle that show a side (a lower neighbour)
JUMP = 6            # studs an avatar climbs with a jump (Roblox's default jump is about 7.2): no column is a trap deeper than this
WALK = 1            # studs an avatar walks up without a jump: the main places are reachable at this
SEPARATION_TRIES = 30


# --- noise ------------------------------------------------------------------------------------------------------------------------------

def _hash(ix: int, iz: int, seed: int) -> float:
    h = (ix * 374761393 + iz * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFFFF) / 0x1000000


def _smooth(t: float) -> float:
    return t * t * (3 - 2 * t)


def vnoise(x: float, z: float, seed: int) -> float:
    """Value noise in [0, 1) on a unit lattice, smoothstep-interpolated."""
    ix, iz = math.floor(x), math.floor(z)
    fx, fz = _smooth(x - ix), _smooth(z - iz)
    a, b = _hash(ix, iz, seed), _hash(ix + 1, iz, seed)
    c, d = _hash(ix, iz + 1, seed), _hash(ix + 1, iz + 1, seed)
    return (a + (b - a) * fx) * (1 - fz) + (c + (d - c) * fx) * fz


def fbm(x: float, z: float, seed: int, scale: float, octaves: int) -> float:
    """Fractal noise in about [0, 1): `octaves` layers, each twice the frequency and half the weight."""
    total, weight, norm, freq = 0.0, 1.0, 0.0, 1.0 / scale
    for o in range(octaves):
        total += vnoise(x * freq, z * freq, seed + 101 * o) * weight
        norm += weight
        weight *= 0.5
        freq *= 2.0
    return total / norm


class Rng:
    """A small deterministic generator (xorshift64*), so the scatter is the same on every Python."""

    def __init__(self, seed: int):
        self.s = (seed * 0x9E3779B97F4A7C15 + 1) & 0xFFFFFFFFFFFFFFFF or 1

    def next(self) -> float:
        s = self.s
        s ^= (s >> 12)
        s ^= (s << 25) & 0xFFFFFFFFFFFFFFFF
        s ^= (s >> 27)
        self.s = s
        return (((s * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) / float(1 << 53)

    def uniform(self, a: float, b: float) -> float:
        return a + (b - a) * self.next()

    def choice(self, seq):
        return seq[min(len(seq) - 1, int(self.next() * len(seq)))]


# --- shapes -----------------------------------------------------------------------------------------------------------------------------

def _seg_dist(px, pz, ax, az, bx, bz):
    """Distance from a point to a segment and the segment parameter (0..1) of the nearest point."""
    dx, dz = bx - ax, bz - az
    ll = dx * dx + dz * dz
    t = 0.0 if ll == 0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / ll))
    qx, qz = ax + dx * t, az + dz * t
    return math.hypot(px - qx, pz - qz), t


def shape_distance(shape: dict, x: float, z: float, seed: int = 0) -> float:
    """Signed distance in studs from a shape's edge (negative inside). circle {x,z,r}, ellipse {x,z,rx,rz,rot}, poly {pts}.
    `wobble` (studs) roughens the edge with noise so a plateau is not a perfect disc."""
    kind = shape.get("type", "circle")
    if kind == "circle":
        d = math.hypot(x - shape["x"], z - shape["z"]) - shape["r"]
    elif kind == "ellipse":
        rot = math.radians(shape.get("rot", 0.0))
        dx, dz = x - shape["x"], z - shape["z"]
        lx = dx * math.cos(rot) + dz * math.sin(rot)
        lz = -dx * math.sin(rot) + dz * math.cos(rot)
        k = math.hypot(lx / shape["rx"], lz / shape["rz"])
        d = (k - 1.0) * min(shape["rx"], shape["rz"])
    elif kind == "poly":
        pts = shape["pts"]
        inside = False
        best = math.inf
        for a, b in zip(pts, pts[1:] + pts[:1]):
            if (a[1] > z) != (b[1] > z):
                cross = a[0] + (z - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
                if x < cross:
                    inside = not inside
            best = min(best, _seg_dist(x, z, a[0], a[1], b[0], b[1])[0])
        d = -best if inside else best
    elif kind == "rect":
        dx = abs(x - (shape["x0"] + shape["x1"]) / 2) - (shape["x1"] - shape["x0"]) / 2
        dz = abs(z - (shape["z0"] + shape["z1"]) / 2) - (shape["z1"] - shape["z0"]) / 2
        d = math.hypot(dx, dz) if (dx > 0 and dz > 0) else max(dx, dz)
    else:
        raise ValueError(f"unknown shape {kind}")
    wobble = shape.get("wobble", 0.0)
    if wobble:
        d += wobble * (vnoise(x / 9.0, z / 9.0, seed + 7) - 0.5) * 2.0
    return d


def shape_bounds(shape: dict, pad: float) -> tuple[float, float, float, float]:
    kind = shape.get("type", "circle")
    w = shape.get("wobble", 0.0) + pad
    if kind == "circle":
        r = shape["r"] + w
        return shape["x"] - r, shape["z"] - r, shape["x"] + r, shape["z"] + r
    if kind == "ellipse":
        r = max(shape["rx"], shape["rz"]) + w
        return shape["x"] - r, shape["z"] - r, shape["x"] + r, shape["z"] + r
    if kind == "poly":
        xs = [p[0] for p in shape["pts"]]
        zs = [p[1] for p in shape["pts"]]
        return min(xs) - w, min(zs) - w, max(xs) + w, max(zs) + w
    return shape["x0"] - w, shape["z0"] - w, shape["x1"] + w, shape["z1"] + w


def polyline_nearest(pts, x, z):
    """(distance, arc length at the nearest point, segment index) of a point to a polyline."""
    best = (math.inf, 0.0, 0)
    run = 0.0
    for k, (a, b) in enumerate(zip(pts, pts[1:])):
        d, t = _seg_dist(x, z, a[0], a[1], b[0], b[1])
        seg = math.hypot(b[0] - a[0], b[1] - a[1])
        if d < best[0]:
            best = (d, run + t * seg, k)
        run += seg
    return best


# --- the world ----------------------------------------------------------------------------------------------------------------------------

class World:
    def __init__(self, desc: dict, kit: dict):
        self.desc, self.kit = desc, kit
        self.seed = desc["seed"]
        self.size = desc["size"]
        self.cell = desc["cell"]
        self.n = self.size // self.cell
        self.origin = -self.size / 2
        self.chunk = desc.get("chunk", 32)
        n2 = self.n * self.n
        self.H = [0.0] * n2
        self.K = [desc["base"]["kind"]] * n2
        self.lock = [False] * n2         # set by a feature that must survive the clean-up (paths, flats, rings)
        self.water: list = [None] * n2   # water top over the column, or None
        self.water_kind: list = [None] * n2
        self.water_bottom: list = [None] * n2   # set where the water runs over a room carved under it (the nook): its bed stays up
        self.nospawn = [False] * n2
        self.path_cells: set[int] = set()
        self.solids: list[tuple] = []    # (x0, y0, z0, x1, y1, z1, kind, walk) studs, relative to the camp ground; walk: a deck you stand on
        self.falls: list[tuple] = []     # (x, z, width, y0, y1, yaw, kind): a vertical sheet of water
        self.carve_under: list[tuple] = []
        self.props: list[tuple] = []     # (name, x, y, z, yaw, scale)
        self.spots: list[dict] = []
        self.fx: list[dict] = []
        self.h: list[int] = []

    # grid helpers
    def centre(self, i: int, j: int) -> tuple[float, float]:
        return self.origin + (i + 0.5) * self.cell, self.origin + (j + 0.5) * self.cell

    def index_at(self, x: float, z: float) -> int:
        i = min(self.n - 1, max(0, int((x - self.origin) // self.cell)))
        j = min(self.n - 1, max(0, int((z - self.origin) // self.cell)))
        return j * self.n + i

    def cells_in(self, x0, z0, x1, z1):
        i0 = max(0, int((x0 - self.origin) // self.cell))
        i1 = min(self.n - 1, int((x1 - self.origin) // self.cell))
        j0 = max(0, int((z0 - self.origin) // self.cell))
        j1 = min(self.n - 1, int((z1 - self.origin) // self.cell))
        for j in range(j0, j1 + 1):
            for i in range(i0, i1 + 1):
                x, z = self.centre(i, j)
                yield j * self.n + i, x, z

    def shape_cells(self, shape, pad=0.0):
        x0, z0, x1, z1 = shape_bounds(shape, pad)
        for idx, x, z in self.cells_in(x0, z0, x1, z1):
            yield idx, x, z, shape_distance(shape, x, z, self.seed)

    def height(self, x: float, z: float) -> int:
        return self.h[self.index_at(x, z)]

    def top(self, x: float, z: float) -> float:
        idx = self.index_at(x, z)
        w = self.water[idx]
        return w if w is not None and self.water_bottom[idx] is None else float(self.h[idx])

    # --- features on the float field ---------------------------------------------------------------------------------------------------

    def f_base(self, f):
        amp, scale, octaves = f["amp"], f["scale"], f.get("octaves", 3)
        for j in range(self.n):
            for i in range(self.n):
                x, z = self.centre(i, j)
                self.H[j * self.n + i] = f["height"] + amp * (fbm(x, z, self.seed, scale, octaves) - 0.5) * 2.0

    def f_edge(self, f):
        width, height, half = f["width"], f["height"], self.size / 2
        for j in range(self.n):
            for i in range(self.n):
                x, z = self.centre(i, j)
                inset = min(half - abs(x), half - abs(z))
                ragged = width * (0.7 + 0.6 * vnoise(x / 23.0, z / 23.0, self.seed + 3))
                if inset < ragged:
                    t = 1.0 - inset / ragged
                    idx = j * self.n + i
                    lift = height * _smooth(t) * (0.75 + 0.5 * vnoise(x / 11.0, z / 11.0, self.seed + 5))
                    step = f.get("terrace")
                    if step:
                        lift = math.floor(lift / step + 0.5) * step
                    self.H[idx] = (math.floor(self.H[idx] + 0.5) if step else self.H[idx]) + lift
                    if t > f.get("kindFrom", 0.5):
                        self.K[idx] = f["kind"]

    def f_paint(self, f):
        only = f.get("on")
        thresh = f.get("noise")
        for idx, x, z, d in self.shape_cells(f["shape"]):
            if d > 0 or (only and self.K[idx] not in only):
                continue
            if thresh is not None and vnoise(x / f.get("noiseScale", 10.0), z / f.get("noiseScale", 10.0), self.seed + 17) < thresh:
                continue
            self.K[idx] = f["kind"]

    def f_hill(self, f):
        """Adds a hill: dome or cone profile, `h` high at the centre, optionally terraced into ledges every `terrace` studs."""
        shape = f["shape"]
        r = shape.get("r", max(shape.get("rx", 0), shape.get("rz", 0)))
        terrace = f.get("terrace")
        for idx, x, z, d in self.shape_cells(shape):
            if d >= 0:
                continue
            t = min(1.0, -d / r)
            lift = f["h"] * (_smooth(t) if f.get("profile", "dome") == "dome" else t)
            if terrace:
                lift = math.floor(lift / terrace + 0.5) * terrace
            self.H[idx] += lift
            if f.get("kind"):
                self.K[idx] = f["kind"]

    def f_plateau(self, f):
        """Raises a shape to `h` (max with the ground) with a hard cliff edge, and optional `ledges` [[width, h], ...] outside it:
        each ring outside the edge stands at its own height, so the cliff can be climbed ledge by ledge."""
        ledges = f.get("ledges", [])
        reach = sum(w for w, _ in ledges)
        for idx, x, z, d in self.shape_cells(f["shape"], reach):
            if d <= 0:
                self.H[idx] = max(self.H[idx], f["h"]) if not f.get("set") else f["h"]
                if f.get("kind"):
                    self.K[idx] = f["kind"]
                self.lock[idx] = self.lock[idx] or f.get("lock", False)
                continue
            out = 0.0
            for width, height in ledges:
                out += width
                if d <= out:
                    if height > self.H[idx]:
                        self.H[idx] = height
                        if f.get("ledgeKind"):
                            self.K[idx] = f["ledgeKind"]
                    break

    def f_flat(self, f):
        """Sets a shape to `h` and blends the ground towards it over `blend` studs outside."""
        blend = f.get("blend", 0.0)
        for idx, x, z, d in self.shape_cells(f["shape"], blend):
            if d <= 0:
                self.H[idx] = f["h"]
                self.lock[idx] = True
                if f.get("kind"):
                    self.K[idx] = f["kind"]
            elif blend and d < blend:
                t = _smooth(d / blend)
                self.H[idx] = f["h"] + (self.H[idx] - f["h"]) * t

    def f_bumps(self, f):
        """`count` small mounds (snow drifts, hummocks) of radius r and height h at random points inside a shape."""
        rng = Rng(self.seed + f.get("seed", 0))
        x0, z0, x1, z1 = shape_bounds(f["shape"], 0)
        placed = 0
        tries = 0
        while placed < f["count"] and tries < f["count"] * 20:
            tries += 1
            cx, cz = rng.uniform(x0, x1), rng.uniform(z0, z1)
            if shape_distance(f["shape"], cx, cz, self.seed) > 0:
                continue
            r = rng.uniform(*f["r"])
            h = rng.uniform(*f["h"])
            for idx, x, z, d in self.shape_cells({"type": "circle", "x": cx, "z": cz, "r": r}):
                if d < 0 and not self.lock[idx]:
                    self.H[idx] += h * _smooth(-d / r)
                    if f.get("kind"):
                        self.K[idx] = f["kind"]
            placed += 1

    def f_ring(self, f):
        """A wall ring (a cave's rock rim): cells between r - thick and r stand at `h`, except inside the `gaps` (degrees, atan2(z, x)
        about the centre), which are left as they are so a path can walk in."""
        cx, cz, r, thick = f["x"], f["z"], f["r"], f["thick"]
        for idx, x, z in self.cells_in(cx - r - 6, cz - r - 6, cx + r + 6, cz + r + 6):
            d = math.hypot(x - cx, z - cz) + f.get("wobble", 0) * (vnoise(x / 7.0, z / 7.0, self.seed + 29) - 0.5) * 2
            if r - thick <= d <= r:
                ang = math.degrees(math.atan2(z - cz, x - cx)) % 360
                if any(a0 <= ang <= a1 for a0, a1 in f.get("gaps", [])):
                    continue
                self.H[idx] = max(self.H[idx], f["h"] + f.get("jag", 0) * (vnoise(x / 5.0, z / 5.0, self.seed + 31) - 0.5) * 2)
                self.K[idx] = f["kind"]
                self.lock[idx] = True

    def f_basin(self, f):
        """A pond or a lake: the shape's floor goes down to `bed` with `water` on top (None: a frozen lake with no water box), a `shore`
        band of `shoreKind` at the waterline, and `kind` on the bed."""
        shore = f.get("shore", 0.0)
        for idx, x, z, d in self.shape_cells(f["shape"], shore):
            if d <= 0:
                self.H[idx] = f["bed"]
                self.K[idx] = f["kind"]
                self.lock[idx] = True
                if f.get("water") is not None:
                    self.water[idx] = f["water"]
                    self.water_kind[idx] = f.get("waterKind", "water")
                    self.nospawn[idx] = True
            elif d <= shore:
                self.H[idx] = min(self.H[idx], f.get("shoreH", 0.0))
                self.K[idx] = f.get("shoreKind", self.K[idx])

    def f_river(self, f):
        """A river along a polyline: segment k carries water at levels[k] (a waterfall sheet where the level drops at a joint), its bed
        `depth` under the water top, its banks `bank` studs wide brought down to the waterline."""
        pts, width, levels, depth, bank = f["pts"], f["width"], f["levels"], f["depth"], f.get("bank", 2.0)
        xs = [p[0] for p in pts]
        zs = [p[1] for p in pts]
        pad = width / 2 + bank + 2
        for idx, x, z in self.cells_in(min(xs) - pad, min(zs) - pad, max(xs) + pad, max(zs) + pad):
            d, _, k = polyline_nearest(pts, x, z)
            level = levels[k]
            if d <= width / 2:
                self.H[idx] = level + 0.25 - depth
                self.K[idx] = f.get("kind", "bed")
                self.water[idx] = level
                self.water_kind[idx] = f.get("waterKind", "water")
                self.nospawn[idx] = True
                self.lock[idx] = True
            elif d <= width / 2 + bank and not self.lock[idx]:
                self.H[idx] = min(self.H[idx], level + 0.25)
                if f.get("bankKind"):
                    self.K[idx] = f["bankKind"]
        for k in range(1, len(levels)):
            if levels[k] < levels[k - 1]:
                (ax, az), (bx, bz) = pts[k - 1], pts[k]
                yaw = math.degrees(math.atan2(bx - ax, bz - az))
                self.falls.append((bx, bz, width + 1.0, levels[k], levels[k - 1], yaw, f.get("waterKind", "water")))

    def f_stones(self, f):
        """Stepping stones: each listed point's cell rises to `h` out of the water, so a river can be crossed by hopping."""
        for x, z in f["pts"]:
            idx = self.index_at(x, z)
            self.H[idx] = f["h"]
            self.K[idx] = f.get("kind", "stone")
            self.water[idx] = None
            self.water_kind[idx] = None
            self.lock[idx] = True

    def f_carve(self, f):
        """Sets a shape to `h` (a nook floor, a cave floor) and locks it."""
        for idx, x, z, d in self.shape_cells(f["shape"]):
            if d <= 0:
                self.H[idx] = f["h"]
                self.lock[idx] = True
                if f.get("kind"):
                    self.K[idx] = f["kind"]
                if f.get("dry"):
                    self.water[idx] = None

    def f_spot(self, f):
        self.spots.append(dict(f))

    def f_fx(self, f):
        self.fx.append(dict(f))

    # --- after quantising ------------------------------------------------------------------------------------------------------------

    def quantise(self):
        self.h = [int(math.floor(v + 0.5)) for v in self.H]

    def clean(self, passes=2):
        """Removes single-cell spikes and pits: an unlocked cell whose four neighbours (three of four) share a height takes it."""
        n = self.n
        for _ in range(passes):
            new = self.h[:]
            for j in range(1, n - 1):
                for i in range(1, n - 1):
                    idx = j * n + i
                    if self.lock[idx]:
                        continue
                    nb = [self.h[idx - 1], self.h[idx + 1], self.h[idx - n], self.h[idx + n]]
                    for v in sorted(set(nb)):
                        if v != self.h[idx] and nb.count(v) >= 3:
                            new[idx] = v
                            break
                    else:
                        # a one-cell-wide sliver (both neighbours across it agree) joins them
                        if nb[0] == nb[1] != self.h[idx] and abs(nb[0] - self.h[idx]) == 1:
                            new[idx] = nb[0]
                        elif nb[2] == nb[3] != self.h[idx] and abs(nb[2] - self.h[idx]) == 1:
                            new[idx] = nb[2]
            self.h = new

    def f_path(self, f):
        """A walkable path along a polyline, `width` studs wide: its heights follow the ground but rise at most `slope` studs a stud
        (cut into the ground by default: `cut` 1 is all trench, 0 all embankment), then every two touching path cells differ by one stud at most, so the path climbs a
        cliff as stairs cut into it. Cells already under water are left alone (a bridge goes there)."""
        pts, width, slope = f["pts"], f["width"], f.get("slope", 0.4)
        total = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:]))
        step = self.cell / 2
        samples = max(2, int(total / step) + 1)
        along: list[float] = []
        ground: list[float] = []
        for s in range(samples):
            dist = total * s / (samples - 1)
            run = 0.0
            for a, b in zip(pts, pts[1:]):
                seg = math.hypot(b[0] - a[0], b[1] - a[1])
                if run + seg >= dist or (a, b) == (pts[-2], pts[-1]):
                    t = 0 if seg == 0 else (dist - run) / seg
                    x, z = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                    break
                run += seg
            along.append(dist)
            ground.append(self.top(x, z) if self.water[self.index_at(x, z)] is None else self.h[self.index_at(x, z)])
        if "fix" in f:
            for at, value in f["fix"]:
                k = min(range(samples), key=lambda q: abs(along[q] - at * total))
                ground[k] = value
        lo, hi = ground[:], ground[:]
        for k in range(1, samples):
            lo[k] = min(lo[k], lo[k - 1] + slope * step)
            hi[k] = max(hi[k], hi[k - 1] - slope * step)
        for k in range(samples - 2, -1, -1):
            lo[k] = min(lo[k], lo[k + 1] + slope * step)
            hi[k] = max(hi[k], hi[k + 1] - slope * step)
        mix = f.get("cut", 1.0)
        g = [lo[k] * mix + hi[k] * (1 - mix) for k in range(samples)]
        xs = [p[0] for p in pts]
        zs = [p[1] for p in pts]
        pad = width / 2 + 2
        mine: list[int] = []
        for idx, x, z in self.cells_in(min(xs) - pad, min(zs) - pad, max(xs) + pad, max(zs) + pad):
            d, at, _ = polyline_nearest(pts, x, z)
            if d > width / 2 or self.water[idx] is not None:
                continue
            k = min(samples - 1, max(0, int(round(at / step))))
            self.h[idx] = int(math.floor(g[k] + 0.5))
            if not f.get("keepKind"):
                self.K[idx] = f["kind"]
            self.lock[idx] = True
            self.path_cells.add(idx)
            mine.append(idx)
        self._relax(set(mine))

    def _relax(self, cells: set[int]):
        n = self.n
        changed = True
        while changed:
            changed = False
            for idx in cells:
                i, j = idx % n, idx // n
                for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ii, jj = i + di, j + dj
                    if 0 <= ii < n and 0 <= jj < n:
                        nb = jj * n + ii
                        if nb in cells and self.h[idx] > self.h[nb] + 1:
                            self.h[idx] = self.h[nb] + 1
                            changed = True

    def f_under(self, f):
        """A room under the ground (a nook behind the waterfall, a grotto): the shape's columns drop to `floor` and a ceiling solid
        fills from `ceiling` up to where the column used to end, so a river can still run over it."""
        rows: dict[tuple, list[int]] = {}
        for idx, x, z, d in self.shape_cells(f["shape"]):
            if d > 0:
                continue
            old = self.h[idx]
            if self.water[idx] is not None:
                self.water_bottom[idx] = float(old)
            self.nospawn[idx] = False
            self.h[idx] = f["floor"]
            self.K[idx] = f.get("kind", self.K[idx])
            self.lock[idx] = True
            if old > f["ceiling"]:
                rows.setdefault((f["ceiling"], old, f.get("roofKind", "stone")), []).append(idx)
        for (y0, y1, kind), cells in sorted(rows.items()):
            for i, j, w, d in merge_cells(set(cells), self.n, self.chunk):
                x0, z0 = self.origin + i * self.cell, self.origin + j * self.cell
                self.solids.append((x0, y0, z0, x0 + w * self.cell, y1, z0 + d * self.cell, kind, 0))

    def f_roof(self, f):
        """A cave roof: solid from `y0` to `y1` over every cell of the circle whose column is lower than y0, except the `holes`."""
        cells = set()
        for idx, x, z, d in self.shape_cells(f["shape"]):
            if d > 0 or self.h[idx] >= f["y0"]:
                continue
            if any(math.hypot(x - hx, z - hz) <= hr for hx, hz, hr in f.get("holes", [])):
                continue
            cells.add(idx)
        for i, j, w, d in merge_cells(cells, self.n, self.chunk):
            x0, z0 = self.origin + i * self.cell, self.origin + j * self.cell
            self.solids.append((x0, f["y0"], z0, x0 + w * self.cell, f["y1"], z0 + d * self.cell, f["kind"], 0))

    def f_solid(self, f):
        """Explicit boxes: a bridge, stepping logs, a lookout deck. y is relative to the ground under the box's centre when `onGround`."""
        for b in f["boxes"]:
            x0, z0, x1, z1 = b["x0"], b["z0"], b["x1"], b["z1"]
            base = 0.0
            if b.get("onGround"):
                base = float(self.h[self.index_at((x0 + x1) / 2, (z0 + z1) / 2)])
            self.solids.append((x0, base + b["y0"], z0, x1, base + b["y1"], z1, b.get("kind", f.get("kind", "wood")), 1 if b.get("walk", True) else 0))
            for idx, x, z in self.cells_in(x0 + 0.01, z0 + 0.01, x1 - 0.01, z1 - 0.01):
                if b.get("blocks", True):
                    self.nospawn[idx] = True

    def f_prop(self, f):
        """Fixed props: [name, x, z, yaw, scale] each, standing on the ground (or the water top for a lily pad), y + `lift`."""
        for row in f["items"]:
            name, x, z = row[0], row[1], row[2]
            yaw = row[3] if len(row) > 3 else 0.0
            scale = row[4] if len(row) > 4 else 1.0
            y = self.top(x, z) + f.get("lift", 0.0)
            if f.get("onSolid"):
                y = f["onSolid"]
            self.props.append((name, x, y, z, yaw, scale))

    def f_scatter(self, f):
        """`count` props of the `names` at random points of a shape (or the whole map), at least `spacing` studs from every other
        scattered prop, on a column whose kind is in `on`, on flat ground (no neighbour more than `slope` studs off), clear of paths,
        water and `avoid` circles; `near` keeps them within studs of water (reeds, lily pads use `onWater`)."""
        rng = Rng(self.seed + f.get("seed", 0) + 7919 * len(self.props))
        shape = f.get("shape", {"type": "rect", "x0": self.origin, "z0": self.origin, "x1": -self.origin, "z1": -self.origin})
        x0, z0, x1, z1 = shape_bounds(shape, 0)
        spacing = f.get("spacing", 6.0)
        placed = 0
        tries = 0
        own: list[tuple[float, float]] = []
        while placed < f["count"] and tries < f["count"] * SEPARATION_TRIES:
            tries += 1
            x, z = rng.uniform(x0, x1), rng.uniform(z0, z1)
            name = rng.choice(f["names"])
            yaw = round(rng.uniform(0, 360) / f.get("yawStep", 1)) * f.get("yawStep", 1)
            scale = rng.uniform(*f.get("scale", [0.9, 1.1]))
            if shape_distance(shape, x, z, self.seed) > 0 or abs(x) > self.size / 2 - 4 or abs(z) > self.size / 2 - 4:
                continue
            if not self._fits(x, z, f, spacing, own):
                continue
            idx = self.index_at(x, z)
            if f.get("onWater"):
                y = self.water[idx]
            else:
                y = float(self.h[idx])
            own.append((x, z))
            self.props.append((name, round(x, 2), y, round(z, 2), round(yaw, 1), round(scale, 2)))
            placed += 1

    def _fits(self, x, z, f, spacing, own) -> bool:
        idx = self.index_at(x, z)
        if f.get("onWater"):
            if self.water[idx] is None or self.water_kind[idx] != "water":
                return False
        else:
            if self.water[idx] is not None or self.nospawn[idx]:
                return False
            if idx in self.path_cells and not f.get("onPath"):
                return False
            on = f.get("on")
            if on and self.K[idx] not in on:
                return False
            n = self.n
            i, j = idx % n, idx // n
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ii, jj = i + di, j + dj
                if 0 <= ii < n and 0 <= jj < n:
                    nb = jj * n + ii
                    if abs(self.h[nb] - self.h[idx]) > f.get("slope", 0):
                        return False
                    if not f.get("onPath") and nb in self.path_cells and f.get("pathClear", True):
                        return False
        near = f.get("nearWater")
        if near:
            if not any(self.water[self.index_at(x + dx, z + dz)] is not None for dx in (-near, 0, near) for dz in (-near, 0, near)):
                return False
        for ax, az, ar in self.desc.get("keepClear", []) + f.get("avoid", []):
            if math.hypot(x - ax, z - az) < ar:
                return False
        for px in self.props:
            if math.hypot(px[1] - x, px[3] - z) < f.get("minFromAll", 2.5):
                return False
        for ox, oz in own:
            if math.hypot(ox - x, oz - z) < spacing:
                return False
        if f.get("underRoof") is False:
            for s in self.solids:
                if s[0] <= x <= s[3] and s[2] <= z <= s[5]:
                    return False
        return True

    def f_along(self, f):
        """Props beside a polyline every `every` studs from `start` to `end` (studs along it), `offset` studs to one side (`side` 1 or
        -1) or alternating (`side` 0); `parallel` turns each so its local X runs along the line (a fence)."""
        pts = f["pts"]
        segs = [(a, b, math.hypot(b[0] - a[0], b[1] - a[1])) for a, b in zip(pts, pts[1:])]
        total = sum(l for _, _, l in segs)
        s, k = f.get("start", 0.0), 0
        end = total - f.get("end", 0.0)
        names = f["names"]
        while s <= end + 1e-6:
            run = 0.0
            for a, b, l in segs:
                if run + l >= s or (a, b, l) == segs[-1]:
                    t = 0 if l == 0 else (s - run) / l
                    px, pz = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                    dx, dz = (b[0] - a[0]) / (l or 1), (b[1] - a[1]) / (l or 1)
                    break
                run += l
            side = f.get("side", 0) or (1 if k % 2 == 0 else -1)
            x, z = px - dz * f["offset"] * side, pz + dx * f["offset"] * side
            idx = self.index_at(x, z)
            if self.water[idx] is None and (idx not in self.path_cells or f.get("onPath")):
                yaw = math.degrees(math.atan2(-dz, dx)) if f.get("parallel") else f.get("yaw", 0.0)
                self.props.append((names[k % len(names)], round(x, 2), float(self.h[idx]), round(z, 2), round(yaw, 1), f.get("scaleOne", 1.0)))
            s += f["every"]
            k += 1

    def f_hang(self, f):
        """Icicles and the like hang from cliff tops: up to `count` cliff edges (a drop of at least `drop` studs) inside the shape get one,
        at the edge, turned to face out over the drop."""
        rng = Rng(self.seed + f.get("seed", 0) + 31)
        n = self.n
        edges = []
        for idx, x, z, d in self.shape_cells(f["shape"]):
            if d > 0 or idx in self.path_cells:
                continue
            i, j = idx % n, idx // n
            for di, dj, yaw in ((1, 0, 90), (-1, 0, 270), (0, 1, 0), (0, -1, 180)):
                ii, jj = i + di, j + dj
                if 0 <= ii < n and 0 <= jj < n and self.h[idx] - self.h[jj * n + ii] >= f["drop"]:
                    edges.append((x + di * self.cell / 2, z + dj * self.cell / 2, self.h[idx], yaw))
                    break
        picked: list[tuple] = []
        while edges and len(picked) < f["count"]:
            e = edges.pop(int(rng.next() * len(edges)))
            if all(math.hypot(e[0] - p[0], e[1] - p[1]) >= f.get("spacing", 8) for p in picked):
                picked.append(e)
        for x, z, h, yaw in picked:
            self.props.append((f["name"], round(x, 2), float(h), round(z, 2), float(yaw), 1.0))

    # --- the build ---------------------------------------------------------------------------------------------------------------

    def run(self):
        late = {"path", "under", "roof", "solid", "prop", "scatter", "hang", "spot", "fx", "along"}
        feats = self.desc["features"]
        for f in feats:
            if f["type"] not in late:
                getattr(self, "f_" + f["type"])(f)
        self.quantise()
        self.clean(self.desc.get("cleanPasses", 3))
        for f in feats:
            if f["type"] in late:
                getattr(self, "f_" + f["type"])(f)
        self.base = min(self.h) - 2
        return self


# --- merging ------------------------------------------------------------------------------------------------------------------------------

def merge_cells(cells: set[int], n: int, chunk: int, free: set[int] | None = None) -> list[tuple[int, int, int, int]]:
    """Greedy rectangles covering a set of cells (all of one key) exactly once, never crossing a chunk border: (i, j, w, d) in cells.
    `free` cells may be covered too, any number of times (a column whose part would be hidden inside the ground there anyway), so a
    rectangle can run under a higher column instead of stopping at it."""
    free = free or set()
    out = []
    done: set[int] = set()

    def ok(c: int) -> bool:
        return (c in cells and c not in done) or (c in free and c not in cells)

    for idx in sorted(cells):
        if idx in done:
            continue
        i, j = idx % n, idx // n
        ci1 = min(n, (i // chunk + 1) * chunk)
        cj1 = min(n, (j // chunk + 1) * chunk)
        w = 1
        while i + w < ci1 and ok(j * n + i + w):
            w += 1
        d = 1
        while j + d < cj1 and all(ok((j + d) * n + i + q) for q in range(w)):
            d += 1
        # trim free-only rows and columns off the far edges: they add nothing
        while d > 1 and not any(((j + d - 1) * n + i + q) in cells for q in range(w)):
            d -= 1
        while w > 1 and not any(((j + r) * n + i + w - 1) in cells for r in range(d)):
            w -= 1
        for dj in range(d):
            for q in range(w):
                c = (j + dj) * n + i + q
                if c in cells:
                    done.add(c)
        out.append((i, j, w, d))
    return out


def side_mask(world: World, i, j, w, d, level: int) -> int:
    """Which of a rectangle's four sides show: a side shows where any neighbour beyond it is lower than `level` (the top of what
    shows on that side: the cap's bottom for a cap, so a 1-stud step shows the cap's side; the body's top for a body)."""
    n, h = world.n, world.h
    mask = 0
    for side, cells in (("xp", [(i + w, j + q) for q in range(d)]), ("xn", [(i - 1, j + q) for q in range(d)]),
                        ("zp", [(i + q, j + d) for q in range(w)]), ("zn", [(i + q, j - 1) for q in range(w)])):
        for ci, cj in cells:
            if not (0 <= ci < n and 0 <= cj < n) or h[cj * n + ci] < level:
                mask |= FACE_BITS[side]
                break
    return mask


def build_parts(world: World):
    n, h, K = world.n, world.h, world.K
    kinds = world.kit["kinds"]
    caps: dict[tuple, set] = {}
    bodies: dict[tuple, set] = {}
    for idx in range(n * n):
        caps.setdefault((h[idx], K[idx]), set()).add(idx)
        i, j = idx % n, idx // n
        low = min(h[jj * n + ii] if 0 <= ii < n and 0 <= jj < n else world.base
                  for ii, jj in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)))
        if low < h[idx] - 1:
            bodies.setdefault((h[idx], kinds[K[idx]]["body"], K[idx]), set()).add(idx)
    # the lowest neighbour of every column: a part at level L may run under a column whose four neighbours all reach L (its volume
    # there is inside the ground, below every face anyone can see)
    floor = [0] * (n * n)
    for idx in range(n * n):
        i, j = idx % n, idx // n
        floor[idx] = min(h[jj * n + ii] if 0 <= ii < n and 0 <= jj < n else world.base
                         for ii, jj in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)))
    cap_rows = []
    for (top, kind), cells in sorted(caps.items()):
        free = {c for c in range(n * n) if h[c] > top and floor[c] >= top} if len(cells) > 1 else set()
        for i, j, w, d in merge_cells(cells, n, world.chunk, free):
            cap_rows.append((i, j, w, d, top, kind, side_mask(world, i, j, w, d, top)))
    body_rows = []
    for (top, _, kind), cells in sorted(bodies.items()):
        free = {c for c in range(n * n) if h[c] >= top and floor[c] >= top - 1} if len(cells) > 1 else set()
        for i, j, w, d in merge_cells(cells, n, world.chunk, free):
            body_rows.append((i, j, w, d, top - 1, kind, side_mask(world, i, j, w, d, top - 1)))
    waters: dict[tuple, set] = {}
    for idx in range(n * n):
        if world.water[idx] is not None:
            bottom = world.water_bottom[idx] if world.water_bottom[idx] is not None else h[idx]
            waters.setdefault((bottom, world.water[idx], world.water_kind[idx]), set()).add(idx)
    water_rows = []
    for (bottom, top, kind), cells in sorted(waters.items(), key=lambda kv: (kv[0][0], kv[0][1], kv[0][2])):
        for i, j, w, d in merge_cells(cells, n, world.chunk):
            water_rows.append((i, j, w, d, float(bottom), float(top), kind))
    return cap_rows, body_rows, water_rows


# --- checks -----------------------------------------------------------------------------------------------------------------------

def reach(world: World, start: tuple[float, float], climb: int) -> list[bool]:
    """Cells reachable from a point walking over columns, stepping up at most `climb` studs (down any height). Water is wadeable."""
    n, h = world.n, world.h
    seen = [False] * (n * n)
    s = world.index_at(*start)
    seen[s] = True
    q = deque([s])
    while q:
        idx = q.popleft()
        i, j = idx % n, idx // n
        for ii, jj in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
            if 0 <= ii < n and 0 <= jj < n:
                nb = jj * n + ii
                if not seen[nb] and h[nb] - h[idx] <= climb:
                    seen[nb] = True
                    q.append(nb)
    return seen


def traps(world: World) -> int:
    """Columns from which the camp cannot be reached even with a jump (a pit or a ledge boxed in by walls higher than JUMP)."""
    n, h = world.n, world.h
    back = [False] * (n * n)
    s = world.index_at(0.0, 0.0)
    back[s] = True
    q = deque([s])
    while q:   # walking backwards: a neighbour can come here if this column is at most JUMP above it
        idx = q.popleft()
        i, j = idx % n, idx // n
        for ii, jj in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
            if 0 <= ii < n and 0 <= jj < n:
                nb = jj * n + ii
                if not back[nb] and h[idx] - h[nb] <= JUMP:
                    back[nb] = True
                    q.append(nb)
    edge = world.desc.get("edgeIgnore", 0)
    count = 0
    for idx in range(n * n):
        i, j = idx % n, idx // n
        if min(i, j, n - 1 - i, n - 1 - j) < edge:
            continue
        if not back[idx]:
            count += 1
    return count


def must_reach(world: World) -> list[tuple[str, float, float]]:
    """The points every player must reach on foot: the shrine, the landmarks, the biome centres and every spot not marked `jump`."""
    pts = [("Shrine", world.desc["shrine"][0], world.desc["shrine"][1])]
    for name, x, z in world.desc.get("landmarks", []):
        pts.append((name, x, z))
    for s in world.spots:
        if not s.get("jump"):
            pts.append((s["id"], s["x"], s["z"]))
    return pts


def counts(world: World, caps, bodies, waters) -> dict:
    kit = world.kit
    textures = 0
    for row in caps:
        textures += 1 + bin(row[6]).count("1")
    for row in bodies:
        textures += bin(row[6]).count("1")
    textures += len(waters) + len(world.falls)
    recipes = kit["recipes"]
    placeholder = sum(len(recipes[p[0]]["boxes"]) for p in world.props if p[0] in recipes)
    lights = sum(1 for p in world.props if p[0] in recipes and recipes[p[0]].get("light"))
    return {
        "caps": len(caps), "bodies": len(bodies), "water": len(waters), "falls": len(world.falls), "solids": len(world.solids),
        "groundParts": len(caps) + len(bodies) + len(waters) + len(world.falls) + len(world.solids) + 1,
        "textures": textures, "scatter": len(world.props), "placeholderParts": placeholder, "lights": lights, "fxEmitters": len(world.fx),
    }


# --- Luau ---------------------------------------------------------------------------------------------------------------------------------

def num(v) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int) or (isinstance(v, float) and v.is_integer()):
        return str(int(v))
    return repr(round(float(v), 3))


def lua_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def flat_rows(rows, per_line=12) -> str:
    items = [", ".join(num(v) if not isinstance(v, str) else lua_str(v) for v in row) for row in rows]
    lines = []
    for k in range(0, len(items), per_line):
        lines.append("\t\t" + ", ".join(items[k:k + per_line]) + ",")
    return "\n".join(lines)


def emit_world(world: World, caps, bodies, waters, stats) -> str:
    kinds = sorted({r[5] for r in caps} | {r[5] for r in bodies} | {r[6] for r in waters} | {s[6] for s in world.solids}
                   | {f[6] for f in world.falls})
    kid = {k: i + 1 for i, k in enumerate(kinds)}
    names = sorted({p[0] for p in world.props})
    nid = {k: i + 1 for i, k in enumerate(names)}
    d = world.desc
    out = []
    out.append("--!strict")
    out.append(f"-- GENERATED by tools/blocky/world_gen.py from tools/blocky/worlds/world{d['world']}.json: do not edit by hand, edit the")
    out.append("-- description and run `python3 -I tools/blocky/world_gen.py`. The ground of World " + str(d["world"]) + " in block cells:")
    out.append("-- every row is flat numbers (see data/WorldKit.luau for the row shapes); the builder is ServerScriptService.Server.Services.Meadow and")
    out.append("-- Shared/WorldGrid answers the ground height at a point from Caps and Water.")
    out.append(f"-- Counts: {stats['caps']} caps, {stats['bodies']} bodies, {stats['water']} water, {stats['falls']} falls, {stats['solids']} solids, "
               f"{stats['scatter']} props ({stats['placeholderParts']} placeholder parts, {stats['lights']} lights), {stats['textures']} textures once the tiles are uploaded.")
    out.append("local Types = require(script.Parent.Parent.types.Types)")
    out.append("")
    out.append("local gen: Types.WorldGen = {")
    out.append(f"\tWorld = {d['world']},")
    out.append(f"\tCell = {world.cell}, -- studs a column")
    out.append(f"\tCount = {world.n}, -- columns a side")
    out.append(f"\tOrigin = {num(world.origin)}, -- the x and z of the grid's corner (column 0 starts here)")
    out.append(f"\tBase = {world.base}, -- the bottom of every body, studs relative to the camp ground")
    out.append(f"\tChunk = {world.chunk}, -- columns a streaming chunk side; no part crosses one")
    out.append("\tKinds = { " + ", ".join(lua_str(k) for k in kinds) + " },")
    out.append("\tProps = { " + ", ".join(lua_str(k) for k in names) + " },")
    out.append("\t-- i, j, w, d (columns), top (studs), kind, sides (bits: 1 +X, 2 -X, 4 +Z, 8 -Z)")
    out.append("\tCaps = {")
    out.append(flat_rows([(r[0], r[1], r[2], r[3], r[4], kid[r[5]], r[6]) for r in caps]))
    out.append("\t},")
    out.append("\t-- i, j, w, d, top (studs; the body runs from Base up to it), kind, sides")
    out.append("\tBodies = {")
    out.append(flat_rows([(r[0], r[1], r[2], r[3], r[4], kid[r[5]], r[6]) for r in bodies]))
    out.append("\t},")
    out.append("\t-- i, j, w, d, bottom, top (studs), kind")
    out.append("\tWater = {")
    out.append(flat_rows([(r[0], r[1], r[2], r[3], r[4], r[5], kid[r[6]]) for r in waters]))
    out.append("\t},")
    out.append("\t-- x, z (the sheet's centre at the lip), width, bottom, top, yaw (degrees), kind: a waterfall")
    out.append("\tFalls = {")
    out.append(flat_rows([(round(f[0], 2), round(f[1], 2), f[2], f[3], f[4], round(f[5], 1), kid[f[6]]) for f in world.falls]))
    out.append("\t},")
    out.append("\t-- x0, y0, z0, x1, y1, z1 (studs), kind, walk (1: a deck the ground height follows: a bridge, a log, a lookout; 0: a roof)")
    out.append("\tSolids = {")
    out.append(flat_rows([(s[0], s[1], s[2], s[3], s[4], s[5], kid[s[6]], s[7]) for s in world.solids], 8))
    out.append("\t},")
    out.append("\t-- i, j, w, d: dry columns nothing spawns on (under a bridge, a log, a deck)")
    out.append("\tNoSpawn = {")
    dry = {idx for idx in range(world.n * world.n) if world.nospawn[idx] and world.water[idx] is None}
    out.append(flat_rows(merge_cells(dry, world.n, world.chunk), 12))
    out.append("\t},")
    out.append("\t-- prop, x, y (the ground top under it), z, yaw (degrees), scale")
    out.append("\tPlace = {")
    out.append(flat_rows([(nid[p[0]], p[1], p[2], p[3], p[4], p[5]) for p in world.props], 8))
    out.append("\t},")
    out.append("\t-- the beautiful places: rare-alien spots (luck multiplies the tier odds of a spawn that lands inside) and named nooks")
    out.append("\tSpots = {")
    for s in world.spots:
        y = world.top(s["x"], s["z"])
        out.append(f"\t\t{{ id = {lua_str(s['id'])}, x = {num(s['x'])}, y = {num(y)}, z = {num(s['z'])}, radius = {num(s['r'])}, luck = {num(s.get('luck', 1))} }},")
    out.append("\t},")
    out.append("\t-- ambient effects at a place (client only; their look is data/WorldFx by kind)")
    out.append("\tFx = {")
    for e in world.fx:
        y = e["y"] if "y" in e else world.top(e["x"], e["z"])
        y += e.get("lift", 0)
        out.append(f"\t\t{{ kind = {lua_str(e['kind'])}, x = {num(e['x'])}, y = {num(y)}, z = {num(e['z'])}, size = {num(e.get('size', 8))} }},")
    out.append("\t},")
    out.append("\tStats = { " + ", ".join(f"{k} = {num(v)}" for k, v in sorted(stats.items())) + " },")
    out.append("}")
    out.append("")
    out.append("return gen")
    out.append("")
    return "\n".join(out)


def emit_kit(kit: dict) -> str:
    out = ["--!strict",
           "-- GENERATED by tools/blocky/world_gen.py from tools/blocky/worlds/kit.json: do not edit by hand. The shared kit of the generated",
           "-- worlds (WorldGen1, WorldGen2): each ground kind's tile keys (ids in data/BlockTiles), fallback colours and Material; how water",
           "-- looks; the block-built placeholder of every scatter prop (used until the props worker's mesh of that name is imported); and the",
           "-- budget each world is held to (tools/tests/test_world_gen.py, tests/WorldGrid.spec.luau).",
           "local Types = require(script.Parent.Parent.types.Types)",
           "",
           "local Kinds: { [string]: Types.GroundKind } = {"]
    for name, k in sorted(kit["kinds"].items()):
        out.append(f"\t{name} = {{ top = {lua_str(k['top'])}, side = {lua_str(k['side'])}, body = {lua_str(k['body'])}, color = {lua_str(k['color'])}, "
                   f"sideColor = {lua_str(k['sideColor'])}, bodyColor = {lua_str(k['bodyColor'])}, material = {lua_str(k['material'])}, spawn = {num(k['spawn'])} }},")
    out.append("}")
    out.append("")
    out.append("local Water: { [string]: Types.WaterLook } = {")
    for name, w in sorted(kit["water"].items()):
        out.append(f"\t{name} = {{ transparency = {num(w['transparency'])}, reflectance = {num(w['reflectance'])} }},")
    out.append("}")
    out.append("")
    out.append("local Recipes: { [string]: Types.PropRecipe } = {")
    for name, r in sorted(kit["recipes"].items()):
        out.append(f"\t{name} = {{")
        if r.get("hang"):
            out.append("\t\thang = true,")
        light = r.get("light")
        if light:
            out.append(f"\t\tlight = {{ color = {lua_str(light['color'])}, range = {num(light['range'])}, brightness = {num(light['brightness'])}, "
                       f"at = {{ {', '.join(num(v) for v in light['at'])} }} }},")
        out.append("\t\tboxes = {")
        for b in r["boxes"]:
            extra = ""
            if b.get("collide"):
                extra += ", collide = true"
            if b.get("neon"):
                extra += ", neon = true"
            if b.get("roll"):
                extra += f", roll = {num(b['roll'])}"
            out.append(f"\t\t\t{{ size = {{ {', '.join(num(v) for v in b['size'])} }}, at = {{ {', '.join(num(v) for v in b['at'])} }}, "
                       f"color = {lua_str(b['color'])}, material = {lua_str(b['material'])}{extra} }},")
        out.append("\t\t},")
        out.append("\t},")
    out.append("}")
    out.append("")
    b = kit["budgets"]
    out.append("-- per world: ground parts (caps, bodies, water, falls, solids and the base), Texture objects once every tile id is real, scattered")
    out.append("-- props, the parts of their placeholders, PointLights, ambient emitters")
    out.append("local Budget: Types.WorldBudget = { " + ", ".join(f"{k} = {num(v)}" for k, v in sorted(b.items())) + " }")
    out.append("")
    out.append("return {")
    out.append("\tKinds = Kinds,")
    out.append("\tWater = Water,")
    out.append("\tRecipes = Recipes,")
    out.append("\tBudget = Budget,")
    out.append("}")
    out.append("")
    return "\n".join(out)


# --- main ---------------------------------------------------------------------------------------------------------------------------

def load(world_id: int) -> tuple[dict, dict]:
    kit = json.loads((WORLDS / "kit.json").read_text())
    desc = json.loads((WORLDS / f"world{world_id}.json").read_text())
    return desc, kit


def generate(world_id: int):
    desc, kit = load(world_id)
    world = World(desc, kit).run()
    caps, bodies, waters = build_parts(world)
    stats = counts(world, caps, bodies, waters)
    return world, caps, bodies, waters, stats


def check_world(world: World, stats: dict) -> list[str]:
    """Problems that fail the build: an unknown kind or prop, a budget broken, a must-reach place not reachable on foot, a trap."""
    problems = []
    kit = world.kit
    for k in set(world.K):
        if k not in kit["kinds"]:
            problems.append(f"unknown kind {k}")
    for s in world.solids:
        if s[6] not in kit["kinds"]:
            problems.append(f"unknown solid kind {s[6]}")
    for p in world.props:
        if p[0] not in kit["recipes"]:
            problems.append(f"prop {p[0]} has no placeholder recipe")
    for key, cap in kit["budgets"].items():
        if stats[key] > cap:
            problems.append(f"{key} {stats[key]} over the budget {cap}")
    walk = reach(world, (0.0, 0.0), WALK)
    for name, x, z in must_reach(world):
        if not walk[world.index_at(x, z)]:
            problems.append(f"{name} at ({x}, {z}) is not reachable on foot from the camp")
    t = traps(world)
    if t:
        problems.append(f"{t} columns are traps (no way back to camp with a jump)")
    return problems


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="fail if the committed Luau differs from a fresh generation")
    ap.add_argument("--report", action="store_true", help="print the counts and checks only")
    ap.add_argument("--worlds", default="1,2")
    args = ap.parse_args(argv)
    kit = json.loads((WORLDS / "kit.json").read_text())
    outputs = {OUT / "WorldKit.luau": emit_kit(kit)}
    failed = False
    for wid in [int(w) for w in args.worlds.split(",")]:
        world, caps, bodies, waters, stats = generate(wid)
        problems = check_world(world, stats)
        line = ", ".join(f"{k} {v}" for k, v in stats.items())
        print(f"world {wid}: {line}")
        for p in problems:
            print(f"world {wid}: PROBLEM {p}")
        failed = failed or bool(problems)
        outputs[OUT / f"WorldGen{wid}.luau"] = emit_world(world, caps, bodies, waters, stats)
    if args.report:
        return 1 if failed else 0
    if args.check:
        stale = [p for p, text in outputs.items() if not p.exists() or p.read_text() != text]
        for p in stale:
            print(f"stale: {p.relative_to(ROOT)} (run python3 -I tools/blocky/world_gen.py)")
        return 1 if stale or failed else 0
    for path, text in outputs.items():
        path.write_text(text)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
