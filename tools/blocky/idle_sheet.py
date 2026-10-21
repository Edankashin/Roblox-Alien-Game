#!/usr/bin/env python3
"""Compose the B46 idle preview of one alien (<Id>_idle.png): the idle frames tools/blender/blocky_build.py --idle rendered (eight of the
clips, then four of one flourish from Rare up) and the face plate's flipbook frames, each labelled. Pillow; run by the build in the system
Python (Blender's has no Pillow).

  python3 -I tools/blocky/idle_sheet.py <frames dir> <Id>_face.png <out png> --id Radish --tier Cosmic --frames open,half,... --frame-size 56,28
"""
from __future__ import annotations

import pathlib
import sys


def main(argv=None):
    from PIL import Image, ImageDraw, ImageFont
    argv = sys.argv[1:] if argv is None else argv
    pos = [a for i, a in enumerate(argv) if not a.startswith("--") and (i == 0 or not argv[i - 1].startswith("--"))]
    opt = {argv[i][2:]: argv[i + 1] for i in range(len(argv) - 1) if argv[i].startswith("--")}
    fdir, face_png, out = pathlib.Path(pos[0]), pathlib.Path(pos[1]), pathlib.Path(pos[2])
    labels = (fdir / "labels.txt").read_text(encoding="utf-8").split("\n")
    shots = [Image.open(fdir / ("f%02d.png" % i)).convert("RGB") for i in range(len(labels))]
    try:
        bold = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 26)
        reg = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 16)
    except OSError:
        bold = reg = ImageFont.load_default()
    tile = 260
    idle = [(l, s) for l, s in zip(labels, shots) if l.startswith("idle")]
    flourish = [(l, s) for l, s in zip(labels, shots) if l.startswith("flourish")]
    names = opt.get("frames", "").split(",")
    fw, fh = (int(v) for v in opt.get("frame-size", "0,0").split(","))
    sheet = Image.open(face_png).convert("RGBA")
    cols = max(1, sheet.width // fw) if fw else 1
    zoom = max(1, int(150 / max(1, fw)))
    pw, ph = fw * zoom, fh * zoom
    per_row = max(1, (8 * (tile + 8)) // (pw + 12))
    plate_rows = (len(names) + per_row - 1) // per_row
    W = 30 + 8 * (tile + 8)
    H = 90 + (tile + 34) * (1 + (1 if flourish else 0)) + 40 + plate_rows * (ph + 30) + 20
    img = Image.new("RGB", (W, H), "#F6F0E6")
    d = ImageDraw.Draw(img)
    d.text((16, 14), "%s (%s): the idle, %s and the face plate (B46, rule 8)" % (opt.get("id", ""), opt.get("tier", ""),
                                                                                  "one flourish" if flourish else "no flourish below Rare"), font=bold, fill="#1B1F3B")
    d.text((16, 50), "Blender preview of the clips in data/Rigs (the math of Shared/RigMath); in the game World.RigAnimator plays them and the "
           "face plate flips its frames.", font=reg, fill="#5F6375")
    y = 84
    for row in ([idle] + ([flourish] if flourish else [])):
        for i, (label, shot) in enumerate(row):
            x = 16 + i * (tile + 8)
            img.paste(shot.resize((tile, tile)), (x, y))
            d.text((x + 4, y + tile + 4), label, font=reg, fill="#5F6375")
        y += tile + 34
    d.text((16, y + 6), "Face plate frames (%d x %d px, nearest filtering)" % (fw, fh), font=reg, fill="#1B1F3B")
    y += 34
    for i, name in enumerate(names):
        if not fw:
            break
        c, r = i % cols, i // cols
        frame = sheet.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh)).resize((pw, ph), Image.Resampling.NEAREST)
        x = 16 + (i % per_row) * (pw + 12)
        yy = y + (i // per_row) * (ph + 30)
        d.rectangle((x, yy, x + pw, yy + ph), fill="#C9C2B4")
        img.paste(frame, (x, yy), frame)
        d.text((x, yy + ph + 4), name, font=reg, fill="#5F6375")
    img.save(out)
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
