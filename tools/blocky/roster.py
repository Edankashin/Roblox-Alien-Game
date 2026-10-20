#!/usr/bin/env python3
"""The roster sheet of one world: every species in tier order as a grid of lit three-quarter renders with its name, tier and measured
numbers, under the to-scale lineup beside the 5-stud avatar, with the world's 64 px silhouette row and its worst pair at the foot.

Python 3 with Pillow (system Python, not Blender's). Inputs: the notes (tools/blocky/spec.py), the build folder of
tools/blender/blocky_build.py (<Id>_tq.png or <Id>_tq_cells.png, lineup.png) and, for the silhouettes, the notes alone.

  python3 -I tools/blocky/roster.py --notes <sixteen notes in tier order> --build <dir> --refs docs/vault/06-art-pipelines/refs/blocky \\
      --out media/studio/<date>/world1_roster_v1.jpg --silhouettes docs/vault/06-art-pipelines/refs/blocky/world1_silhouettes_16.png
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


def render_of(folders, sid):
    """The lit three-quarter cell render of `sid` from the first folder that has one (a build folder's PNG or the vault's JPG)."""
    for folder in folders:
        for stem in ("%s_tq_cells" % sid, "%s_tq" % sid):
            im = L._image(pathlib.Path(folder) / (stem + ".png"))
            if im is not None:
                return im
    return None


def roster(specs, build, out_path, title, cols=4, refs=None):
    W, pad, gap = 2400, 40, 20
    tile = (W - 2 * pad - (cols - 1) * gap) // cols
    banner, numbers_h = 48, 118
    folders = [build] + ([refs] if refs else [])
    row_h = banner + tile + numbers_h
    rows = -(-len(specs) // cols)
    lineup = next((im for im in (L._image(build / ("lineup%s.png" % sfx)) for sfx in ("_cells", "")) if im is not None), None)
    lh = int((W - 2 * pad) * lineup.height / lineup.width) if lineup is not None else 0
    sil, worst = L.silhouette_row(specs)
    H = 120 + (lh + 50 if lineup is not None else 0) + rows * (row_h + gap) + 90 + sil.height + 50
    img = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.text((pad, 28), title, font=L.font(40, True), fill=INK)
    d.text((pad, 82), "Every species of the world in tier order, built from its spec note (Obsidian) with block cells, lit in Blender; every number "
           "measured from the build. Scratch builds: nothing under assets/models changed.", font=L.font(20), fill=MUTED)
    y = 120
    if lineup is not None:
        img.paste(L.fit(lineup, W - 2 * pad, lh, "#FFFFFF"), (pad, y))
        d.text((pad + 12, y + 8), "To scale beside a 5-stud avatar: " + ", ".join(s["front"]["name"] for s in specs), font=L.font(22, True), fill=INK)
        y += lh + 50
    for k, s in enumerate(specs):
        f = s["front"]
        sid, tier = f["id"], f["tier"]
        r, c = divmod(k, cols)
        x = pad + c * (tile + gap)
        yy = y + r * (row_h + gap)
        tier_hex = SH.TIER_HEX.get(tier, "#999999")
        d.rectangle([x, yy, x + tile, yy + row_h], fill="#FBF8F2", outline="#E2DACB")
        d.rectangle([x, yy, x + tile, yy + banner], fill=tier_hex)
        d.text((x + 14, yy + 8), "%s  %s" % (f["name"], tier.upper()), font=L.font(28, True), fill=INK if tier in LIGHT_TIERS else "#FFFFFF")
        d.text((x + tile - 14, yy + 14), sid, font=L.font(18), fill=INK if tier in LIGHT_TIERS else "#FFFFFF", anchor="ra")
        im = render_of(folders, sid)
        if im is not None:
            img.paste(L.fit(im, tile, tile, "#FFFFFF"), (x, yy + banner))
        cnt = S.counts(s)
        ov = f.get("overlap") or []
        line1 = "%d blocks (%s band %d to %d), %s tris, %.2f studs = %.1f avatars" % (cnt["blocks"], tier, *S.TIERS[tier]["blocks"], f.get("tris"), cnt["height"],
                                                                                 cnt["height"] / 5.0)
        line2 = "hero %s; overlap with the sheet %s" % (f.get("hero"), ("%.3f to %.3f" % (min(ov), max(ov))) if len(ov) == 4 else "not built")
        line3 = "moving: %s" % (", ".join(S.movers(S.expand(s["parts"]))) or "none")
        d.text((x + 12, yy + banner + tile + 10), line1, font=L.font(18), fill=INK)
        d.text((x + 12, yy + banner + tile + 36), line2, font=L.font(17), fill=MUTED)
        d.text((x + 12, yy + banner + tile + 60), line3, font=L.font(17), fill=MUTED)
        pal = S.palette(s)
        for j, (role, hexcol) in enumerate(pal.items()):
            d.rectangle([x + 12 + j * 34, yy + banner + tile + 88, x + 40 + j * 34, yy + banner + tile + 110], fill=hexcol, outline="#888888")
    y += rows * (row_h + gap)
    d.text((pad, y + 24), "Silhouette test (front views, 64 px, each in its own frame): worst boxed overlap %.2f (%s / %s); under 0.7 passes" % worst,
           font=L.font(26, True), fill=INK)
    img.paste(sil, (pad, y + 70))
    img = img.crop((0, 0, W, min(H, y + 70 + sil.height + 40)))
    img.save(out_path, quality=88)
    return out_path


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--notes", required=True, help="comma list of creature notes, in tier order")
    ap.add_argument("--build", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--silhouettes", default="", help="also write the world's 64 px silhouette row with every pair's overlap here")
    ap.add_argument("--title", default="World 1 roster v1: all sixteen Verdant aliens in block cells")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--refs", default="", help="a second folder of renders (the vault's refs/blocky, <Id>_tq_cells.jpg) for species not in --build")
    a = ap.parse_args(argv)
    specs = [S.load(n) for n in a.notes.split(",") if n]
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    print(roster(specs, pathlib.Path(a.build), out, a.title, a.cols, a.refs or None))
    if a.silhouettes:
        print(L.silhouettes(specs, a.silhouettes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
