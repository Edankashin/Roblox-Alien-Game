#!/usr/bin/env python3
"""The v2b pilot sheet (PILOT-3, Decision B54): Syrinx and Fenrir, v2 beside v2b, from the front and from the game camera's 16 studs, each beside
the 5-stud avatar.

Python 3 with Pillow. The renders come from tools/blender/pilot_shots.py (--views front,cam) for each state, <Id>_front.png and <Id>_cam.png:

  python3 -I tools/blocky/pilot_sheet_v2b.py --v2 <dir> --v2b <dir> --out media/studio/2026-10-26/pilot_bar_v2b.jpg
"""
from __future__ import annotations

import argparse
import pathlib

from PIL import Image, ImageDraw, ImageFont

FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf"
PAPER, INK, MUTED, GOOD = "#F6F0E6", "#1B1F3B", "#5F6375", "#1F7A4D"
ROWS = (("Panpipe", "Syrinx, Secret, World 1", "a lit rim two cells thick round a darker face, eight pale rays, pale violet shards, brighter brass"),
        ("Fenripup", "Fenrir, Cosmic, World 2", "the brow moon cut (the crescent is the moon), the head up 12 degrees, frost rings clear of the face, brighter silver"))
W, MARGIN, GAP, COL = 1360, 28, 14, 640


def font(n, bold=False):
    try:
        return ImageFont.truetype(FONT % ("Bold" if bold else "Regular"), n)
    except OSError:
        return ImageFont.load_default()


def fit(path, w):
    im = Image.open(path).convert("RGB")
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--v2", required=True)
    ap.add_argument("--v2b", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    d0, d1 = pathlib.Path(a.v2), pathlib.Path(a.v2b)
    blocks = []
    for sid, title, what in ROWS:
        shots = [[fit(d / ("%s_%s.png" % (sid, view)), COL) for d in (d0, d1)] for view in ("front", "cam")]
        blocks.append((title, what, shots))
    height = 130 + sum(36 + 30 + shots[0][0].height + 30 + shots[1][0].height + 24 for _, _, shots in blocks) + 40
    sheet = Image.new("RGB", (W, height), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((MARGIN, 22), "Character bar pilot v2b, 2026-10-26: Syrinx and Fenrir, the two reads fixed (Decision B54)", font=font(30, True), fill=INK)
    d.text((MARGIN, 66), "v2 on the left, v2b on the right, each beside the 5-stud avatar: from the front, and from the game camera (16 studs away, slightly above,", font=font(19), fill=MUTED)
    d.text((MARGIN, 90), "a 70 degree field of view, the middle of a 1080p frame at 1:1). Blender, Cycles; nothing uploaded.", font=font(19), fill=MUTED)
    y = 130
    for title, what, shots in blocks:
        d.text((MARGIN, y), title, font=font(26, True), fill=INK)
        d.text((MARGIN + 330, y + 5), "v2b: " + what, font=font(17), fill=GOOD)
        y += 36
        for label, row in zip(("front", "16 studs"), shots):
            d.text((MARGIN, y), "%s: v2 (before)" % label, font=font(16, True), fill=MUTED)
            d.text((MARGIN + COL + GAP, y), "%s: v2b (after)" % label, font=font(16, True), fill=GOOD)
            y += 30
            for i, im in enumerate(row):
                sheet.paste(im, (MARGIN + i * (COL + GAP), y))
            y += row[0].height
        y += 24
    sheet = sheet.crop((0, 0, MARGIN + 2 * COL + GAP + MARGIN, y + 10))
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    q = 88
    while True:
        sheet.save(out, "JPEG", quality=q, optimize=True)
        if out.stat().st_size < 780_000 or q <= 60:
            break
        q -= 4
    print("wrote %s (%d x %d, %d KB, quality %d)" % (out, sheet.width, sheet.height, out.stat().st_size // 1024, q))


if __name__ == "__main__":
    main()
