#!/usr/bin/env python3
"""Before/after sheet for the sculpt pass. Plain Python with Pillow, no Blender.

One column per species: the lit render of the current body on top and of the sculpted body below (both halves of the two-up image
`preview.py --lit --compare` writes: before on the left, after on the right), then the black shapes at 64 px (before | after, magnified
2x so the pixels show), and the triangle counts read from each model's notes.md. The JPEG is kept under 500 KB.

  python3 tools/blender/preview.py --lit --models /scratch/models --compare assets/models --textures /nonexistent \\
      --species Mossbop,Sparkfox --out /scratch/renders            # --textures /nonexistent: no baked maps on either, a fair look
  python3 tools/blender/preview.py --models /scratch/models --species Mossbop,Sparkfox         # the black shapes (<Id>_grey.png)
  python3 tools/blender/sculpt_sheet.py --species Mossbop,Sparkfox --renders /scratch/renders --after /scratch/models \\
      --out docs/vault/06-art-pipelines/refs/sculpt-pass/before_after.jpg
"""
import argparse
import pathlib
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
CELL = 380      # px per lit cell
SHAPE = 64      # the black shape's size, as it would be seen on a phone
MAGNIFY = 2
BACKGROUND = (250, 244, 232)
INK = (32, 28, 40)


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow older than 10.1
        return ImageFont.load_default()


def triangles(models, sid):
    notes = (models / sid / "notes.md").read_text()
    match = re.search(r"- Triangles: (\d+)", notes)
    return int(match.group(1)) if match else 0


def main():
    ap = argparse.ArgumentParser(description="Before/after sheet of the sculpt pass")
    ap.add_argument("--species", required=True)
    ap.add_argument("--renders", required=True, help="folder with <Id>_surface.jpg from preview.py --lit --compare")
    ap.add_argument("--after", required=True, help="the scratch models folder (for <Id>_grey.png and the triangle count)")
    ap.add_argument("--before", default=str(ROOT / "assets/models"), help="the models folder the 'before' came from (default assets/models)")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    ids = [s.strip() for s in args.species.split(",") if s.strip()]
    before, after, renders = pathlib.Path(args.before), pathlib.Path(args.after), pathlib.Path(args.renders)
    label_h, strip_h, pad = 34, SHAPE * MAGNIFY + 34, 8
    width = len(ids) * (CELL + pad) + pad
    height = pad + label_h + 2 * (CELL + pad) + strip_h + pad
    sheet = Image.new("RGB", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    big, small = font(20), font(14)
    for col, sid in enumerate(ids):
        x = pad + col * (CELL + pad)
        two_up = Image.open(renders / ("%s_surface.jpg" % sid)).convert("RGB")
        half = two_up.width // 2
        draw.text((x + 4, pad), sid, fill=INK, font=big)
        draw.text((x + CELL - 4, pad + 4), "%s -> %s tris" % (format(triangles(before, sid), ","), format(triangles(after, sid), ",")),
                  fill=INK, font=small, anchor="ra")
        for row, (box, name) in enumerate((((0, 0, half, two_up.height), "before"), ((half, 0, two_up.width, two_up.height), "after"))):
            y = pad + label_h + row * (CELL + pad)
            sheet.paste(two_up.crop(box).resize((CELL, CELL), Image.LANCZOS), (x, y))
            draw.text((x + 6, y + 4), name, fill=INK, font=small)
        y = pad + label_h + 2 * (CELL + pad)
        for k, (models, name) in enumerate(((before, "before"), (after, "after"))):
            shape = Image.open(models / sid / ("%s_grey.png" % sid)).convert("RGB").resize((SHAPE, SHAPE), Image.LANCZOS)
            shape = shape.resize((SHAPE * MAGNIFY, SHAPE * MAGNIFY), Image.NEAREST)
            sheet.paste(shape, (x + 36 + k * (SHAPE * MAGNIFY + 36), y))
            draw.text((x + 36 + k * (SHAPE * MAGNIFY + 36), y + SHAPE * MAGNIFY + 4), "%s 64 px" % name, fill=INK, font=small)
    out = pathlib.Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    for quality in (88, 82, 76, 70, 64):
        sheet.save(out, quality=quality, optimize=True)
        if out.stat().st_size < 500 * 1024:
            break
    print("%s (%d x %d, %d KB, quality %d)" % (out, width, height, out.stat().st_size // 1024, quality))


if __name__ == "__main__":
    main()
