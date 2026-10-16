#!/usr/bin/env python3
"""The review sheet of a design-pass batch (docs/vault/06-art-pipelines/Design-Pass.md): one row per species with the current body, the `<Id>V2`
front, three-quarter and side, the two 64 px black shapes, the triangles, the species' tier and mood, the overlap with its old body and the closest
other species of its world with its overlap. Plain Python 3 with numpy and Pillow, no Blender:

  python3 tools/blender/design_sheet.py --batch 2 --renders DIR --models SCRATCH/models --models OTHER/models --shipped SCRATCH/shipped --out sheet.jpg

--renders holds what `review_views.py --old` writes (<Id>_tq.jpg, <Id>V2_front.jpg, <Id>V2_tq.jpg, <Id>V2_side.jpg); --models are the folders of
`<Id>V2/<Id>V2.glb` and `<Id>V2_grey.png` (searched in order: the batch's own, then earlier batches', which stand in for their old bodies when the
closest species of a world is looked up); --shipped holds the old bodies (`<Id>/<Id>.glb`, `<Id>_grey.png` from `preview.py`). The triangles, the
size and the lowest point are read from the GLB itself. The JPEG quality is lowered until the file is under 450 KB.
"""
import argparse
import json
import pathlib
import re
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import overlap as OV  # noqa: E402

ROOT = OV.ROOT
BG, INK, SOFT = (248, 243, 232), (44, 38, 34), (120, 110, 100)
PILL = {"cute": (244, 163, 196), "cool": (111, 177, 232), "fierce": (226, 84, 62), "spectacular": (240, 184, 46)}
CELL, SHAPE = 232, 128
WORLD = {1: "World 1 Verdant", 2: "World 2 Frostbyte"}

BATCHES = {
    "1": {
        "title": "Design pass, batch 1: eight species whose shape barely changed get a new base design (hybrid sculpt, scratch builds, nothing under assets/models changed)",
        "rows": [
            ("Mossbop", "cute", "a crouching moss tuft: sprout crest on a moss mat, one arm waving"),
            ("Glimmo", "cute", "an upright jelly firefly: swept wings, curling antennae, a paper-lantern abdomen"),
            ("Drippo", "cute", "an icicle imp: tapering to a drip, a crown of ice drips, floating mitts, an imp tail"),
            ("Kettlepuff", "cute", "a pear-bellied kettle critter: spout snout and steam, a tilted lid hat, a handle tail"),
            ("Flufflet", "cute", "a mitten-eared snow pup: whipping scarf, one paw raised"),
            ("Puffpuff", "cute", "a cloud puff: two fans of seed rays for wings, a stem tail"),
            ("Capybubble", "cute", "a loafing capybara: a bubble crown round a tangerine, bubbles rising"),
            ("Pengoo", "cute", "a round tux penguin: flipper arms, beak, a tiny backpack"),
        ],
    },
    "2": {
        "title": "Design pass, batch 2: the eight rarer species whose faces carry a mood get a body that carries it (hybrid sculpt, scratch builds, nothing under assets/models changed)",
        "rows": [
            ("Thunderhog", "fierce", "a low forward-leaning storm boar: tusks, clawed forelegs, a swept crest of lightning quills"),
            ("Frostfang", "fierce", "a sabre-tooth cat: high shoulders, two long icicle fangs, a frost mane"),
            ("Skaddle", "fierce", "a lean hunter gliding on gold skates: a blade-ring halo, a whipping scarf"),
            ("Gloomoth", "cool", "a slender night moth: four crystal wings spread wide, plumed antennae, a chest jewel"),
            ("Shimmerlynx", "cool", "a long lean lynx: tufted ears, one paw raised, an aurora crest flowing back"),
            ("Reindazzle", "cool", "a stately reindeer: a wide crown of branching icicle antlers, the glowing nose"),
            ("Rocklobber", "fierce", "a cave crab: boulder claws raised high, a faceted shell, six legs planted wide"),
            ("Gaiabloom", "spectacular", "a proud stag: tree antlers in bloom, a gold nimbus, a flower ring on its lawn"),
        ],
    },
}


def font(size, bold=False):
    path = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf" % ("Bold" if bold else "Regular")
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def glb_stats(path):
    """Triangles (by material name), size in studs (x, depth, height) and the lowest point of a GLB, read from its JSON chunk (glTF is Y up)."""
    data = pathlib.Path(path).read_bytes()
    off, doc = 12, None
    while off < len(data):
        length, kind = struct.unpack("<II", data[off:off + 8])
        if kind == 0x4E4F534A:
            doc = json.loads(data[off + 8:off + 8 + length])
        off += 8 + length
    tris, by_slot, lo, hi = 0, {}, [1e9] * 3, [-1e9] * 3
    for mesh in doc["meshes"]:
        for prim in mesh["primitives"]:
            n = doc["accessors"][prim["indices"]]["count"] // 3
            tris += n
            name = doc["materials"][prim["material"]]["name"] if "material" in prim else "?"
            by_slot[name] = by_slot.get(name, 0) + n
            acc = doc["accessors"][prim["attributes"]["POSITION"]]
            lo = [min(a, b) for a, b in zip(lo, acc["min"])]
            hi = [max(a, b) for a, b in zip(hi, acc["max"])]
    size = (hi[0] - lo[0], hi[2] - lo[2], hi[1] - lo[1])
    return {"tris": tris, "slots": by_slot, "size": size, "low": lo[1]}


def species_info(luau=None):
    text = pathlib.Path(luau or ROOT / "src/shared/data/Species.luau").read_text()
    out = {}
    for m in re.finditer(r'\{ id = "(\w+)", name = "([^"]*)",[^\n]*?tier = "(\w+)"[^\n]*?world = (\d)', text):
        out[m.group(1)] = {"name": m.group(2), "tier": m.group(3), "world": int(m.group(4))}
    return out


def content_box(im, bg, thr=36):
    a = np.asarray(im.convert("RGB"), dtype=np.int16)
    diff = np.abs(a - np.array(bg, dtype=np.int16)).max(axis=2)
    ys, xs = np.nonzero(diff > thr)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def shape_image(mask, size):
    return Image.fromarray(np.where(mask, 30, 238).astype(np.uint8)).resize((size, size), Image.NEAREST).convert("RGB")


def wrap(d, text, fnt, width):
    lines, line = [], ""
    for w in text.split():
        if d.textlength(line + " " + w, font=fnt) > width:
            lines.append(line.strip())
            line = w
        else:
            line += " " + w
    return lines + [line.strip()]


def compose(batch, renders, models, shipped, out, luau=None):
    spec = BATCHES[batch]
    shapes = OV.Shapes(models, shipped)
    world_of = OV.worlds(luau)
    info = species_info(luau)
    rows = spec["rows"]
    w_label, w_cells, w_shapes, w_text = 214, CELL * 4, SHAPE * 2 + 30, 300
    width = w_label + w_cells + w_shapes + w_text + 24
    head, row_h = 108, CELL + 14
    sheet = Image.new("RGB", (width, head + row_h * len(rows) + 10), BG)
    d = ImageDraw.Draw(sheet)
    d.text((14, 10), spec["title"], font=font(19, True), fill=INK)
    d.text((14, 38), "Per row: the current body, then the V2 prototype front, three-quarter and side (lit renders to scale); the black shapes at 64 px (now, V2); the numbers.",
           font=font(15), fill=SOFT)
    d.text((14, 58), "Overlap = intersection over union of the black shapes, plain 64 px / boxed 48 px (each cropped to its box). Bars: under 0.85 against its old body, under 0.7 against any other species of its world.",
           font=font(15), fill=SOFT)
    for i, c in enumerate(["now", "V2 front", "V2 three-quarter", "V2 side"]):
        d.text((w_label + i * CELL + 8, head - 18), c, font=font(14, True), fill=INK)
    d.text((w_label + w_cells + 12, head - 18), "black shape, 64 px: now | V2", font=font(14, True), fill=INK)
    d.text((w_label + w_cells + w_shapes + 12, head - 18), "numbers", font=font(14, True), fill=INK)
    result = {}
    for r, (sid, mood, blurb) in enumerate(rows):
        y0, v2 = head + r * row_h, sid + "V2"
        names = [("%s_tq.jpg" % sid), ("%s_front.jpg" % v2), ("%s_tq.jpg" % v2), ("%s_side.jpg" % v2)]
        imgs = [Image.open(pathlib.Path(renders) / n) for n in names]
        bg = imgs[0].getpixel((4, 4))
        boxes = [content_box(im, bg) for im in imgs]
        x0, y0b = min(b[0] for b in boxes), min(b[1] for b in boxes)
        x1, y1 = max(b[2] for b in boxes), max(b[3] for b in boxes)
        side = int(max(x1 - x0, y1 - y0) * 1.1)
        cx, cy = (x0 + x1) // 2, (y0b + y1) // 2
        box = (cx - side // 2, cy - side // 2)
        for i, im in enumerate(imgs):
            canvas = Image.new("RGB", (side, side), bg)  # a crop past the render's edge takes the backdrop colour, not black
            canvas.paste(im, (-box[0], -box[1]))
            sheet.paste(canvas.resize((CELL, CELL), Image.LANCZOS), (w_label + i * CELL, y0))
        # the label: id, display name and tier, world, the mood pill, the blurb
        meta = info[sid]
        d.text((14, y0 + 6), sid, font=font(20, True), fill=INK)
        d.text((14, y0 + 32), "%s  (%s)" % (meta["name"], meta["tier"]), font=font(14), fill=SOFT)
        d.text((14, y0 + 50), WORLD[meta["world"]], font=font(14), fill=SOFT)
        pw = int(d.textlength(mood, font=font(13, True))) + 16
        d.rounded_rectangle((14, y0 + 72, 14 + pw, y0 + 92), radius=9, fill=PILL[mood])
        d.text((22, y0 + 75), mood, font=font(13, True), fill=(255, 255, 255))
        for k, line in enumerate(wrap(d, blurb, font(14), w_label - 26)):
            d.text((14, y0 + 104 + 18 * k), line, font=font(14), fill=INK)
        # the shapes
        sx = w_label + w_cells + 12
        for k, name in enumerate((sid, v2)):
            sheet.paste(shape_image(shapes.mask(name), SHAPE), (sx + k * (SHAPE + 6), y0 + 8))
        # the numbers
        tx = w_label + w_cells + w_shapes + 12
        new, old = glb_stats(shapes.path(v2).parent / (v2 + ".glb")), glb_stats(shapes.path(sid).parent / (sid + ".glb"))
        vs_old = shapes.pair(v2, sid)
        near = OV.neighbours(shapes, v2, world_of)[0]
        d.text((tx, y0 + 6), "%s triangles" % format(new["tris"], ","), font=font(17, True), fill=INK)
        d.text((tx, y0 + 30), "(now %s)   size %s studs" % (format(old["tris"], ","), " x ".join("%.1f" % q for q in new["size"])), font=font(13), fill=SOFT)
        d.text((tx, y0 + 58), "overlap with its old body", font=font(13), fill=SOFT)
        d.text((tx, y0 + 74), "%.2f / %.2f" % vs_old, font=font(17, True), fill=INK)
        d.text((tx, y0 + 108), "closest in its world", font=font(13), fill=SOFT)
        d.text((tx, y0 + 124), near[0].replace("V2", " V2"), font=font(17, True), fill=INK)
        d.text((tx, y0 + 148), "%.2f / %.2f" % (near[1], near[2]), font=font(17, True), fill=INK)
        sheet.paste(shape_image(shapes.mask(near[0]), 64), (tx + 128, y0 + 112))
        d.line([(10, y0 + row_h - 4), (width - 10, y0 + row_h - 4)], fill=(222, 214, 200), width=1)
        result[sid] = {"tris": new["tris"], "old_tris": old["tris"], "size": new["size"], "low": new["low"], "slots": new["slots"], "mood": mood,
                       "vs_old": vs_old, "closest": near}
    out = pathlib.Path(out)
    for q in (78, 72, 66, 60, 52, 46):
        sheet.save(out, quality=q, optimize=True, progressive=True)
        if out.stat().st_size < 440 * 1024:
            break
    print(out, out.stat().st_size, sheet.size, "quality", q)
    return result


def main(argv=None):
    ap = argparse.ArgumentParser(description="Compose the review sheet of a design-pass batch")
    ap.add_argument("--batch", required=True, choices=sorted(BATCHES))
    ap.add_argument("--renders", required=True)
    ap.add_argument("--models", action="append", required=True)
    ap.add_argument("--shipped", default=str(ROOT / "assets/models"))
    ap.add_argument("--out", required=True)
    ap.add_argument("--luau", default="")
    ap.add_argument("--json", default="", help="also write the numbers of the rows here")
    a = ap.parse_args(argv)
    res = compose(a.batch, a.renders, a.models, a.shipped, a.out, a.luau or None)
    if a.json:
        pathlib.Path(a.json).write_text(json.dumps(res, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
