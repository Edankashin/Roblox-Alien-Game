#!/usr/bin/env python3
"""The 64 px black-shape overlap of the design pass (docs/vault/06-art-pipelines/Design-Pass.md): is a new body a different shape from the old one and from
every other species of its world? Plain Python 3 with numpy and Pillow, no Blender: it reads the `<Id>_grey.png` that `preview.py` writes (a solid black
silhouette on grey, one per model folder).

  python3 tools/blender/overlap.py --models /scratch/models --species ThunderhogV2,FrostfangV2          # old body and the closest species of the world
  python3 tools/blender/overlap.py --models /scratch/models --pairs                                      # every pair of a world, highest first

A shape is the grey PNG shrunk to 64 x 64 by a box filter and thresholded (black below 153 of 255). Two numbers per pair, both intersection over union:
  plain  the two 64 px shapes as `preview.py` frames them (30 degree view, each framed by its own longest side)
  boxed  each shape cropped to its bounding box and stretched to 48 x 48 (the Silhouette-Pass check: the shape alone, the aspect ignored)
The bars of the design pass: under 0.85 against the species' own old body, under 0.7 against every other species of its world. For scale, the hybrid
rebuild of an unchanged body scored 0.85 to 0.98 against the old one (Sculpt-Pass.md, pass 2).

Where a species' shape comes from: `--models` (repeatable) are folders of `<Id>/<Id>_grey.png`, searched in order, then `--shipped` (default
assets/models). A neighbour is the species' `<Id>V2` when one of the folders has it (the prototypes of earlier batches stand in for their old bodies),
else the shipped body. The world of a species is read from src/shared/data/Species.luau.
"""
import argparse
import json
import pathlib
import re
import sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
THRESHOLD = 153.0  # black below this of 255 (0.6)
SIZE = 64
BOX = 48


class Shapes:
    """Where the grey PNGs are: the scratch model folders first, then the shipped ones."""

    def __init__(self, folders, shipped=None):
        self.folders = [pathlib.Path(f) for f in folders] + [pathlib.Path(shipped) if shipped else ROOT / "assets/models"]
        self.cache = {}

    def path(self, sid):
        for f in self.folders:
            p = f / sid / ("%s_grey.png" % sid)
            if p.exists():
                return p
        return None

    def has(self, sid):
        return self.path(sid) is not None

    def mask(self, sid):
        if sid not in self.cache:
            p = self.path(sid)
            if p is None:
                raise FileNotFoundError("no %s_grey.png in %s" % (sid, ", ".join(str(f) for f in self.folders)))
            self.cache[sid] = mask64(p)
        return self.cache[sid]

    def pair(self, a, b):
        return pair_of(self.mask(a), self.mask(b))


def mask64(path):
    """The black shape of a grey PNG at 64 x 64: a bool array, True where black."""
    im = Image.open(path).convert("L").resize((SIZE, SIZE), Image.BOX)
    return np.asarray(im, dtype=np.float32) < THRESHOLD


def boxed(m, n=BOX):
    """The shape cropped to its bounding box and stretched to n x n."""
    ys, xs = np.nonzero(m)
    if not len(ys):
        return np.zeros((n, n), dtype=bool)
    crop = m[ys.min():ys.max() + 1, xs.min():xs.max() + 1].astype(np.float32)
    im = Image.fromarray((crop * 255).astype(np.uint8)).resize((n, n), Image.BILINEAR)
    return np.asarray(im, dtype=np.float32) > 127.0


def iou(a, b):
    union = np.logical_or(a, b).sum()
    return float(np.logical_and(a, b).sum() / union) if union else 0.0


def pair_of(a, b):
    """(plain, boxed) intersection over union of two masks."""
    return iou(a, b), iou(boxed(a), boxed(b))


def worlds(luau=None):
    """{species id: world} from Species.luau."""
    text = pathlib.Path(luau or ROOT / "src/shared/data/Species.luau").read_text()
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'\{ id = "(\w+)"[^\n]*?world = (\d)', text)}


def base_of(sid):
    return sid[:-2] if sid.endswith("V2") else sid


def neighbours(shapes, sid, world_of):
    """The other species of sid's world with their overlap: [(id, plain, boxed)], the highest first. A species with a V2 in the folders is that V2."""
    base = base_of(sid)
    out = []
    for other, w in world_of.items():
        if w != world_of.get(base) or other == base:
            continue
        stand_in = other + "V2" if shapes.has(other + "V2") else other
        if shapes.has(stand_in):
            out.append((stand_in,) + shapes.pair(sid, stand_in))
    out.sort(key=lambda r: -max(r[1], r[2]))
    return out


def report(shapes, ids, world_of, top=3):
    rows = {}
    for sid in ids:
        old = shapes.pair(sid, base_of(sid)) if sid.endswith("V2") and shapes.has(base_of(sid)) else None
        near = neighbours(shapes, sid, world_of)[:top]
        rows[sid] = {"black": int(shapes.mask(sid).sum()), "old": old, "closest": near}
        print("%-14s black px %4d | vs old body: %s | closest in world: %s" % (
            sid, rows[sid]["black"], "plain %.3f boxed %.3f" % old if old else "-",
            ", ".join("%s %.2f/%.2f" % r for r in near)))
    return rows


def all_pairs(shapes, world_of, top=25):
    """Every pair of one world by overlap, highest first (the V2s of the folders stand in for their old bodies)."""
    rows = []
    for w in sorted(set(world_of.values())):
        members = [(base_of(s) + "V2" if shapes.has(base_of(s) + "V2") else s) for s, ww in world_of.items() if ww == w]
        members = [m for m in members if shapes.has(m)]
        for i, a in enumerate(members):
            for b in members[i + 1:]:
                p, q = shapes.pair(a, b)
                rows.append((max(p, q), p, q, a, b, w))
    rows.sort(reverse=True)
    print("%d pairs; top %d by the higher of plain and boxed" % (len(rows), top))
    for _, p, q, a, b, w in rows[:top]:
        print("  W%d %-14s %-14s %.2f | %.2f" % (w, a, b, p, q))
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser(description="64 px black-shape overlap of new bodies against the old ones and their world")
    ap.add_argument("--models", action="append", default=[], help="a folder of <Id>/<Id>_grey.png (repeatable; searched in order)")
    ap.add_argument("--shipped", default=str(ROOT / "assets/models"), help="the shipped model folders (searched last)")
    ap.add_argument("--species", default="", help="comma list of ids (a V2 id is also compared with its old body)")
    ap.add_argument("--pairs", action="store_true", help="every pair of each world instead")
    ap.add_argument("--json", default="", help="write the numbers of --species here")
    ap.add_argument("--luau", default="", help="Species.luau (default: the repo's)")
    args = ap.parse_args(argv)
    shapes = Shapes(args.models, args.shipped)
    world_of = worlds(args.luau or None)
    if args.pairs:
        all_pairs(shapes, world_of)
        return 0
    ids = [s for s in args.species.split(",") if s]
    if not ids:
        ap.error("--species or --pairs")
    rows = report(shapes, ids, world_of)
    if args.json:
        pathlib.Path(args.json).write_text(json.dumps(rows, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
