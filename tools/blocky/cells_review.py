#!/usr/bin/env python3
"""The block-cell review sheets (Decision B44): the seven creatures before and after cells with a close-up of every material motif, and the
World 1 diorama. Python 3 with Pillow (system Python, not Blender's).

  python3 -I tools/blocky/cells_review.py cells --notes <seven notes in tier order> --before <dir of <Id>_tq.jpg> --build <dir of
      <Id>_tq_cells.png> --out media/studio/<date>/blocky_cells_v1.jpg
  python3 -I tools/blocky/cells_review.py scene --scene <dir of world1_hero.png, world1_low.png> --out media/studio/<date>/world1_scene_v1.jpg
  python3 -I tools/blocky/cells_review.py scene --world 2 --scene <dir of world2_hero.png, world2_low.png> --out .../world2_scene_v1.jpg
  python3 -I tools/blocky/cells_review.py copies --notes ... --build <dir> --scene <dir> --refs docs/vault/06-art-pipelines/refs/blocky
      # <Id>_tq_cells.jpg, <Id>_vfx_cells.jpg, world1_hero.jpg, world1_low.jpg and cell_materials.png into the vault's refs

The numbers on the sheets are measured, not typed: each creature's cell, cells tall, islands and atlas size come from tools/blocky/cells.py,
its draw calls from its parts (spec.movers).
"""
from __future__ import annotations

import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import cells as C  # noqa: E402
import spec as S  # noqa: E402

FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf"
PAPER, INK, MUTED, PANEL = "#F6F0E6", "#1B1F3B", "#5F6375", "#FFFFFF"
TIER_HEX = {"Common": "#9A9A9A", "Uncommon": "#3FBF55", "Rare": "#3B82F6", "Epic": "#C026D3", "Legendary": "#F59E0B", "Cosmic": "#EC4899",
            "Secret": "#111111"}


def font(n, bold=False):
    try:
        return ImageFont.truetype(FONT % ("Bold" if bold else "Regular"), n)
    except OSError:
        return ImageFont.load_default()


def fit(img, w, h, bg=PANEL):
    img = img.convert("RGB")
    s = min(w / img.width, h / img.height)
    im = img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.LANCZOS)
    out = Image.new("RGB", (w, h), bg)
    out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return out


def find(folder, stem):
    for ext in (".png", ".jpg"):
        p = pathlib.Path(folder) / (stem + ext)
        if p.exists():
            return p
    return None


def wrap(d, text, fnt, width):
    """Split `text` into lines no wider than `width` pixels in `fnt`."""
    words, lines, line = text.split(), [], ""
    for w in words:
        trial = (line + " " + w).strip()
        if d.textlength(trial, font=fnt) <= width:
            line = trial
        else:
            lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines


def numbers(spec):
    """The measured cell numbers of one creature: cell (studs), cells a stud, cells tall, islands, cells, atlas size, draw calls today and
    with the atlas (all static slots in one MeshPart, a Neon glow part apart, plus one per moving object)."""
    parts = S.expand(spec["parts"])
    cell = C.creature_cell(spec)
    isl = C.islands(parts, cell)
    w, h = C.pack(isl)
    movers = len(S.movers(parts))
    static_slots = {p["slot"] for p in parts if p["moves"] == "none"}
    glow = "Glow" in static_slots
    return {"cell": cell, "per_stud": 1 / cell, "tall": S.counts(spec)["height"] / cell, "islands": len(isl),
            "cells": sum(i["nu"] * i["nv"] for i in isl), "atlas": (w, h), "calls_now": len(static_slots) + movers,
            "calls_atlas": 1 + (1 if glow else 0) + movers, "movers": movers}


def cells_sheet(notes, before, build, out, title):
    specs = [S.load(n) for n in notes]
    W = 2400
    pad, gap = 24, 18
    per_row = 4
    pair_w = (W - 2 * pad - (per_row - 1) * gap) // per_row
    tile = (pair_w - 8) // 2
    row_h = tile + 96
    rows = (len(specs) + per_row - 1) // per_row
    sw_px = 8
    swatch = 16 * sw_px
    mats_h = swatch + 120
    H = 120 + rows * (row_h + gap) + mats_h + 110
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((pad, 22), title, font=font(40, True), fill=INK)
    d.text((pad, 74), "Left of each pair: the loop 2 build in flat slot colours. Right: the same build with block cells (tools/blocky/cells.py). "
           "Same spec, same camera; every number measured from the build.", font=font(20), fill=MUTED)
    y0 = 120
    for k, spec in enumerate(specs):
        f = spec["front"]
        sid, tier = f["id"], f["tier"]
        r, c = divmod(k, per_row)
        x = pad + c * (pair_w + gap)
        y = y0 + r * (row_h + gap)
        d.rectangle([x, y, x + pair_w, y + row_h], fill=PANEL)
        d.rectangle([x, y, x + pair_w, y + 40], fill=TIER_HEX.get(tier, INK))
        d.text((x + 12, y + 7), "%s  %s" % (f["name"], tier.upper()), font=font(24, True), fill="#FFFFFF")
        b = find(before, "%s_tq" % sid)
        a = find(build, "%s_tq_cells" % sid)
        if b:
            sheet.paste(fit(Image.open(b), tile, tile), (x + 2, y + 44))
        if a:
            sheet.paste(fit(Image.open(a), tile, tile), (x + tile + 6, y + 44))
        n = numbers(spec)
        line1 = "cell %.3f studs (%.1f a stud), %d cells tall, face cell = body cell" % (n["cell"], n["per_stud"], round(n["tall"]))
        line2 = "atlas %dx%d, %d islands, %d cells; draw calls %d now, %d with the atlas" % (
            n["atlas"][0], n["atlas"][1], n["islands"], n["cells"], n["calls_now"], n["calls_atlas"])
        d.text((x + 10, y + 50 + tile), line1, font=font(17), fill=INK)
        d.text((x + 10, y + 74 + tile), line2, font=font(17), fill=MUTED)
    # the empty slots of the last row: the rule card
    used = len(specs) % per_row
    if used:
        x = pad + used * (pair_w + gap)
        y = y0 + (rows - 1) * (row_h + gap)
        wbox = W - pad - x
        d.rectangle([x, y, x + wbox, y + row_h], fill=PANEL)
        d.text((x + 16, y + 14), "The cell rules (Blocky-Style, Cells)", font=font(26, True), fill=INK)
        rules = [
            "Density: a creature's cell is its face cell (head width / 16): 0.125 studs on a 2-stud head, 0.375 on Raddis's 6, so rarer "
            "creatures carry more cells per height (20 on Moop, 37 to 38 from Gaira up). The world cell is 0.25 (4 a stud).",
            "Jitter: value only, L* %.1f; %d%% of cells a level down, %d%% up, a hash of the cell." % (C.JITTER, C.JITTER_SHARE * 100, C.JITTER_SHARE * 100),
            "Edges: a side's top row a step (L* %d) lighter, its other border a step darker, on faces 3 cells or more across. Grout: 1 "
            "texel in 8, a step down (half on grass, none on water)." % C.STEP,
            "Motifs: skin, moss, grass, dirt, stone, metal, crystal, wood, water, glow, wool.",
            "Face: drawn cell for cell on the head's front; below a 2-row fringe the front is plain skin cells.",
            "Never noise: flat squares, nearest filtering, a fixed seed; no gradients, no grain.",
        ]
        fnt = font(15)
        ty = y + 50
        for i, rule in enumerate(rules):
            lines = wrap(d, rule, fnt, wbox - 60)
            d.text((x + 16, ty), "%d" % (i + 1), font=font(16, True), fill=INK)
            for line in lines:
                d.text((x + 40, ty), line, font=fnt, fill=INK)
                ty += 19
            ty += 4
    # the material close-ups
    y = y0 + rows * (row_h + gap) + 8
    d.text((pad, y), "One face of each material motif, close up (a 4 x 4 stud face at the world cell, 8 texels a cell, nearest)", font=font(26, True), fill=INK)
    y += 44
    n_sw = len(C.SWATCH)
    cell_w = (W - 2 * pad) // n_sw
    for k, (mat, base, aux, accent, note) in enumerate(C.SWATCH):
        faces = C.swatch_faces(mat, base, aux, accent, px=sw_px)
        o = "-z"
        fw, fh, buf = faces[o]
        img = Image.frombytes("RGB", (fw, fh), bytes(buf))
        side = cell_w - 16
        img = img.resize((side, side), Image.Resampling.NEAREST)
        x = pad + k * cell_w
        sheet.paste(img, (x, y))
        d.text((x, y + side + 8), mat, font=font(20, True), fill=INK)
    # the verdict line
    y = H - 80
    d.text((pad, y), "Read: the cells make every block read as built from little blocks without noise; Gaira's pale body gains value from the grout, "
           "Moop's moss reads as clumps,", font=font(20), fill=INK)
    d.text((pad, y + 30), "Syrinx's dark coat sparkles with violet flecks. Glow parts keep their cells (a lit core). Proposal for Ethan's yes: nothing "
           "under assets/models changed (B43, B44).", font=font(20), fill=INK)
    sheet.save(out, quality=90)
    return out


SCENE_NOTES = {
    1: ("A 48 x 32 stud meadow built from the same block cells as the creatures: 2-stud ground blocks, props from spec notes, the seven "
        "aliens and the 5-stud avatar to scale. Blender render.", [
        "Ground: GrassBlock's four kinds (grass over dirt, a",
        "cobbled path, the pond's water) on a height map with a",
        "step to a plateau and a ledge; 2 x 1 x 2 stud blocks at",
        "the world cell (4 a stud), hidden faces culled.",
        "",
        "Props from spec notes, the creature route: Tree,",
        "Rock, Crystal, Ship (pitched 12 degrees nose-down,",
        "clods of turf thrown up round its nose), Flower.",
        "",
        "One rule set everywhere: flat cells, value jitter, a",
        "step darker at block edges and lighter on top, a",
        "1-texel grout (half on grass, none on water), a motif",
        "per material. World 1's sky: day blue over a pale",
        "warm horizon; a warm sun.",
        "",
        "Nothing under assets/models or src changed.",
    ]),
    2: ("A 48 x 32 stud snowfield built from the same block cells as the creatures: 2-stud ground blocks in the cold materials, props from "
        "spec notes, every World 2 alien and the 5-stud avatar to scale. Blender render.", [
        "Ground: SnowBlock's kinds (snow over packed snow, a",
        "trodden trail, the ice floor at the cave mouth, the",
        "frozen pond) on a height map with a rise, a ledge and",
        "a packed-snow cliff; 2 x 1 x 2 stud blocks at the world",
        "cell (4 a stud), hidden faces culled.",
        "",
        "Props from spec notes, the creature route: PineTree,",
        "SnowRock, IceCrystal, IceArch (the cave mouth at the",
        "cliff's foot), Heater (the camp's one warm light).",
        "",
        "The cold set of cell materials: snow (a drift lip over",
        "packed strata), ice (bands on the other diagonal),",
        "frozen water (plates and cracks, no grout), pine",
        "(needle rows, snow dust), fur on the aliens. The sky",
        "from Lighting.luau's Frostbyte look: a cold blue over",
        "a pale haze; a soft, low, cool sun.",
        "",
        "Nothing under assets/models or src changed.",
    ]),
}


def scene_sheet(scene_dir, out, title, world=1):
    hero = Image.open(pathlib.Path(scene_dir) / ("world%d_hero.png" % world)).convert("RGB")
    low = Image.open(pathlib.Path(scene_dir) / ("world%d_low.png" % world)).convert("RGB")
    subtitle, notes = SCENE_NOTES[world]
    W = 1920
    hero = hero.resize((W, int(W * hero.height / hero.width)), Image.LANCZOS)
    low_w = 1280
    low = low.resize((low_w, int(low_w * low.height / low.width)), Image.LANCZOS)
    H = 110 + hero.height + 16 + low.height + 24
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((24, 20), title, font=font(38, True), fill=INK)
    d.text((24, 70), subtitle, font=font(19), fill=MUTED)
    sheet.paste(hero, (0, 110))
    y = 110 + hero.height + 16
    sheet.paste(low, (0, y))
    x = low_w + 24
    d.text((x, y + 4), "Second angle: low, among the small rungs", font=font(24, True), fill=INK)
    for i, line in enumerate(notes):
        d.text((x, y + 48 + i * 27), line, font=font(19), fill=INK if line and not line.startswith("Nothing") else MUTED)
    sheet.save(out, quality=90)
    return out


def copies(notes, build, scene_dir, refs, world=1):
    """World 1: `<Id>_tq_cells` renders, the world's two angles and the eleven-motif swatch sheet into the vault's refs. World 2 (built with
    cells from the start, so its renders are `<Id>_tq` and `<Id>_vfx`): the same names in the refs, the world2 angles and the cold swatches."""
    refs = pathlib.Path(refs)
    refs.mkdir(parents=True, exist_ok=True)
    done = []
    for n in notes:
        sid = S.load(n)["front"]["id"]
        for kind in ("tq", "vfx"):
            src = find(build, "%s_%s_cells" % (sid, kind)) or (find(build, "%s_%s" % (sid, kind)) if world != 1 else None)
            if src:
                dst = refs / ("%s_%s_cells.jpg" % (sid, kind))
                Image.open(src).convert("RGB").save(dst, quality=90)
                done.append(dst)
    if scene_dir:
        for view in ("hero", "low"):
            src = pathlib.Path(scene_dir) / ("world%d_%s.png" % (world, view))
            if src.exists():
                dst = refs / ("world%d_%s.jpg" % (world, view))
                Image.open(src).convert("RGB").save(dst, quality=90)
                done.append(dst)
    if world == 1:
        done.append(C.swatch_sheet(str(refs / "cell_materials.png")))
    else:
        done.append(C.swatch_sheet(str(refs / "cell_materials_cold.png"), swatches=C.SWATCH_COLD,
                                   title="Cell materials, the cold set (Blocky-Style, World 2: Frostbyte palette): each motif on a 4 x 4 stud block, 4 cells a stud"))
    return done


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("what", choices=("cells", "scene", "copies"))
    ap.add_argument("--notes", default="")
    ap.add_argument("--before", default="")
    ap.add_argument("--build", default="")
    ap.add_argument("--scene", default="")
    ap.add_argument("--refs", default="")
    ap.add_argument("--out", default="")
    ap.add_argument("--title", default="")
    ap.add_argument("--world", type=int, default=1, help="scene and copies: 1 Verdant, 2 Frostbyte")
    a = ap.parse_args(argv)
    notes = [n for n in a.notes.split(",") if n]
    if a.what == "cells":
        print(cells_sheet(notes, a.before, a.build, a.out, a.title or "Block cells v1: the seven World 1 rungs, flat and with cells"))
    elif a.what == "scene":
        default = {1: "World 1 Verdant: the meadow in block cells, with its seven aliens", 2: "World 2 Frostbyte: the snowfield in block cells, with its six aliens"}
        print(scene_sheet(a.scene, a.out, a.title or default[a.world], a.world))
    else:
        for p in copies(notes, a.build, a.scene, a.refs, a.world):
            print(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
