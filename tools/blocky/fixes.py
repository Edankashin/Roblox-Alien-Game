#!/usr/bin/env python3
"""The World 1 fixes sheet: the five species the roster review named, before (the vault's earlier render) and after (the new build), the
event aliens with their VFX previews and concept-sheet thumbnails and measured numbers, and the whole world's 64 px silhouette row with
its worst pair. Python 3 with Pillow (system Python, not Blender's).

  python3 -I tools/blocky/fixes.py --fixed Snailbyte,Glimmo,Puffpuff,Gloomoth,Pebblet --new Wisplet,Spookum,Nebulyn \\
      --before <dir of the old <Id>_tq_cells.jpg> --build <dir of the new <Id>_tq_cells.png, <Id>_vfx_cells.png> --sheets <dir of <Id>_sheet.png> \\
      --world-notes <every note of the world, comma list, tier order> --out media/studio/<date>/world1_fixes_v1.jpg \\
      --silhouettes docs/vault/06-art-pipelines/refs/blocky/world1_silhouettes_19.png --title "..."
"""
from __future__ import annotations

import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from PIL import Image, ImageDraw  # noqa: E402

import ladder as L  # noqa: E402
import sheet as SH  # noqa: E402
import spec as S  # noqa: E402

PAPER, INK, MUTED, PANEL = "#F6F0E6", "#1B1F3B", "#5F6375", "#FFFFFF"
LIGHT_TIERS = ("Common", "Uncommon")
NOTES = "docs/vault/07-alien-game/Creatures/%s.md"


def _render(folder, sid, kind="tq"):
    for stem in ("%s_%s_cells" % (sid, kind), "%s_%s" % (sid, kind)):
        im = L._image(pathlib.Path(folder) / (stem + ".png"))
        if im is not None:
            return im
    return None


def banner(d, x, y, w, spec, h=48, size=26):
    f = spec["front"]
    tier = f["tier"]
    d.rectangle([x, y, x + w, y + h], fill=SH.TIER_HEX.get(tier, "#999999"))
    fill = INK if tier in LIGHT_TIERS else "#FFFFFF"
    d.text((x + 12, y + 8), "%s  %s" % (f["name"], tier.upper()), font=L.font(size, True), fill=fill)
    d.text((x + w - 12, y + 14), f["id"], font=L.font(16), fill=fill, anchor="ra")


def numbers(spec):
    f = spec["front"]
    c = S.counts(spec)
    ov = f.get("overlap") or []
    return [
        "%d blocks (%s band %d to %d), %s tris of 2,500, %.2f studs = %.1f avatars" % (c["blocks"], f["tier"], *S.TIERS[f["tier"]]["blocks"], f.get("tris"),
                                                                                    c["height"], c["height"] / 5.0),
        "hero %s; overlap with the sheet %s; moving: %s" % (f.get("hero"), ("%.3f to %.3f" % (min(ov), max(ov))) if len(ov) == 4 else "not built",
                                                            ", ".join(S.movers(S.expand(spec["parts"]))) or "none"),
    ]


def fixes_sheet(fixed, new, before, build, sheets, world_specs, out_path, title, reasons=None):
    W, pad, gap = 2400, 40, 20
    reasons = reasons or {}
    d_probe = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    # section 1: the five fixes, before and after, two per row
    pair_w = (W - 2 * pad - gap) // 2
    tile = (pair_w - 3 * 12) // 2
    row1_h = 48 + tile + 96
    rows1 = -(-len(fixed) // 2)
    # section 2: the event aliens, one row each: render, VFX preview, sheet thumbnail, numbers
    tile2 = 420
    row2_h = 48 + tile2 + 20
    sil, worst = L.silhouette_row(world_specs)
    H = 130 + rows1 * (row1_h + gap) + 70 + len(new) * (row2_h + gap) + 90 + sil.height + 50
    img = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.text((pad, 28), title, font=L.font(40, True), fill=INK)
    d.text((pad, 82), "Left of each pair: the roster v1 build. Right: the same species after the fix, built from its spec note with block cells and lit in "
           "Blender; every number measured from the build. Scratch builds: nothing under assets/models changed.", font=L.font(20), fill=MUTED)
    y = 130
    for k, spec in enumerate(fixed):
        f = spec["front"]
        sid = f["id"]
        r, c = divmod(k, 2)
        x = pad + c * (pair_w + gap)
        yy = y + r * (row1_h + gap)
        d.rectangle([x, yy, x + pair_w, yy + row1_h], fill="#FBF8F2", outline="#E2DACB")
        banner(d, x, yy, pair_w, spec)
        b = L._image(pathlib.Path(before) / ("%s_tq_cells.jpg" % sid))
        a = _render(build, sid)
        if b is not None:
            img.paste(L.fit(b, tile, tile, PANEL), (x + 12, yy + 48 + 6))
        if a is not None:
            img.paste(L.fit(a, tile, tile, PANEL), (x + 12 + tile + 12, yy + 48 + 6))
        d.text((x + 12 + tile + 2, yy + 48 + 6 + tile // 2), ">", font=L.font(30, True), fill=MUTED, anchor="mm")
        d.text((x + 16, yy + 54), "before", font=L.font(18, True), fill=INK)
        d.text((x + 12 + tile + 16, yy + 54), "after", font=L.font(18, True), fill=INK)
        ty = yy + 48 + tile + 14
        for i, line in enumerate(L.wrap_text(d, reasons.get(sid, ""), L.font(17), pair_w - 24)[:2]):
            d.text((x + 12, ty + i * 22), line, font=L.font(17), fill=INK)
        for i, line in enumerate(numbers(spec)):
            d.text((x + 12, ty + 46 + i * 22), line, font=L.font(16), fill=MUTED)
    y += rows1 * (row1_h + gap)
    d.text((pad, y + 16), "The Haunted Nebula event aliens: render, VFX preview (a Blender preview; in game Effects.luau draws them), concept sheet",
           font=L.font(28, True), fill=INK)
    y += 70
    for spec in new:
        f = spec["front"]
        sid = f["id"]
        d.rectangle([pad, y, W - pad, y + row2_h], fill="#FBF8F2", outline="#E2DACB")
        banner(d, pad, y, W - 2 * pad, spec, size=28)
        x = pad + 12
        tq = _render(build, sid)
        if tq is not None:
            img.paste(L.fit(tq, tile2, tile2, PANEL), (x, y + 58))
        x += tile2 + 16
        vfx = _render(build, sid, "vfx")
        if vfx is not None:
            img.paste(L.fit(vfx, tile2, tile2), (x, y + 58))
        x += tile2 + 16
        sh = L._image(pathlib.Path(sheets) / ("%s_sheet.png" % sid))
        sheet_w = 820
        if sh is not None:
            img.paste(L.fit(sh, sheet_w, tile2, PANEL), (x, y + 58))
        x += sheet_w + 16
        ty = y + 64
        for i, line in enumerate(L.wrap_text(d, reasons.get(sid, ""), L.font(18), W - pad - x - 12)):
            d.text((x, ty + i * 24), line, font=L.font(18), fill=INK)
            ty += 0
        ty += 24 * len(L.wrap_text(d, reasons.get(sid, ""), L.font(18), W - pad - x - 12)) + 12
        for i, line in enumerate(numbers(spec)):
            for j, sub in enumerate(L.wrap_text(d, line, L.font(17), W - pad - x - 12)):
                d.text((x, ty), sub, font=L.font(17), fill=MUTED)
                ty += 22
        pal = S.palette(spec)
        for j, (role, hexcol) in enumerate(pal.items()):
            d.rectangle([x + j * 40, y + row2_h - 50, x + 32 + j * 40, y + row2_h - 18], fill=hexcol, outline="#888888")
        y += row2_h + gap
    d.text((pad, y + 24), "Silhouette test, all %d World 1 species (front views, 64 px, each in its own frame): worst boxed overlap %.2f (%s / %s); under 0.7 passes" % (
        (len(world_specs),) + worst), font=L.font(26, True), fill=INK)
    img.paste(sil, (pad, y + 70))
    img = img.crop((0, 0, W, min(H, y + 70 + sil.height + 40)))
    img.save(out_path, quality=88)
    return out_path


REASONS = {
    "Snailbyte": "The copper coil read as a riveted tower: now a stepped spiral, the whorl drawn in cells on the core's flat faces (the new `whorl` motif) with the outer turn wound round it in four tapering steps, yawed 20 degrees to the camera.",
    "Glimmo": "The wing covers read as two sticks: now plates a stud deep and a quarter thick, hinged at the crown and lifted 25 degrees.",
    "Puffpuff": "A cube under the fluff: now a voxel round (a woolly step on top, the calyx as the step below) with three cone seeds standing out and the hero seed floating as a fourth.",
    "Gloomoth": "Busy comb antennae and a collar-block ruff: now one flat feathered blade a side with a lit tip, and a ruff of three wool steps with a tuft at each shoulder.",
    "Pebblet": "The boxiest of the roster: the cairn's bottom stone is a wide slab offset right, so the top steps down, and a wedge of stone is proud of the camera-side flank, a chip out of the rock.",
    "Wisplet": "Wispkin, Rare: a cold blue flame with a shy face, the `ember` motif's lit tongues on every flame block, a lilac tip, two flamelets floating beside it and an iron lantern's bail arched over it (the hero). Shadow element; a soft blue light.",
    "Spookum": "Grin, Epic: a round ghost with a jack-o'-lantern grin cut into the house face and lit orange from inside, a brass pumpkin stem (the hero) on its crown, pumpkin ribs, a stepped emblem, six tatters with three violet-lit tips, arms that wave and a chain.",
    "Nebulyn": "Cosmoo, Legendary: a violet nebula cloud on the `nebula` motif (billows, a dust lane, star cells in the glow), magenta puffs, two gold constellations, and a tail of cloud curling up behind it in five steps with stars along it (the hero), two floating free and one fallen to the grass.",
}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--fixed", required=True, help="comma list of the fixed species ids")
    ap.add_argument("--new", required=True, help="comma list of the new species ids")
    ap.add_argument("--before", required=True)
    ap.add_argument("--build", required=True)
    ap.add_argument("--sheets", required=True)
    ap.add_argument("--world-notes", required=True, help="comma list of every note of the world, tier order, for the silhouette row")
    ap.add_argument("--out", required=True)
    ap.add_argument("--silhouettes", default="", help="also write the world's 64 px silhouette row with every pair's overlap here")
    ap.add_argument("--title", default="World 1 fixes v1: the five roster fixes before and after, and the three Haunted Nebula event aliens")
    a = ap.parse_args(argv)
    fixed = [S.load(NOTES % i) for i in a.fixed.split(",") if i]
    new = [S.load(NOTES % i) for i in a.new.split(",") if i]
    world = [S.load(n) for n in a.world_notes.split(",") if n]
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    print(fixes_sheet(fixed, new, a.before, pathlib.Path(a.build), a.sheets, world, out, a.title, REASONS))
    if a.silhouettes:
        print(L.silhouettes(world, a.silhouettes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
