#!/usr/bin/env python3
"""Contact sheet for the UV unwrap and palette bake. Plain Python with Pillow, no Blender.

One cell per species, eight to a row: the lit render of the unwrapped, textured GLB on the left (`preview.py --lit --textured`) and its
baked palette texture on the right at 128 px (the islands on a light grey ground: the transparent space between them), with the island
count and the texel coverage under the name. A species that failed a check (the tool's report says so) gets a red name, a red frame and
the first problem. The JPEG is kept under 450 KB.

  python3 tools/blender/unwrap_bake.py --species recipes --out /scratch/uvbake --report /scratch/uvbake_report.json
  python3 tools/blender/preview.py --lit --textured --backdrop A9C7E6 --models /scratch/uvbake --size 256 --samples 32 \\
      --species <the ids, comma separated> --out /scratch/renders
  python3 tools/blender/uv_bake_sheet.py --models /scratch/uvbake --renders /scratch/renders --report /scratch/uvbake_report.json \\
      --out docs/vault/06-art-pipelines/refs/surface-pass/uv_bake_sheet.jpg --copy media/studio/2026-10-15/uv_bake_sheet.jpg
"""
import argparse
import json
import pathlib
import shutil

from PIL import Image, ImageDraw, ImageFont

RENDER = 160     # px: the lit render
PALETTE = 128    # px: the palette texture
PAD = 6
LABEL = 34       # px of text above each cell
COLUMNS = 8
BACKGROUND = (250, 246, 238)
GROUND = (222, 224, 230)   # what the transparent texels are drawn on
INK = (32, 28, 40)
RED = (200, 30, 40)
LIMIT = 450 * 1024


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow older than 10.1
        return ImageFont.load_default()


def palette_thumb(path):
    """The palette at PALETTE px on a grey ground (Pillow resizes RGBA premultiplied, so the transparent edge does not darken it)."""
    image = Image.open(path).convert("RGBA").resize((PALETTE, PALETTE), Image.BOX)
    ground = Image.new("RGBA", (PALETTE, PALETTE), GROUND + (255,))
    return Image.alpha_composite(ground, image).convert("RGB")


def main():
    ap = argparse.ArgumentParser(description="Contact sheet of the UV unwrap and palette bake")
    ap.add_argument("--models", required=True, help="the unwrap_bake.py output folder (<Id>/<Id>_palette.png)")
    ap.add_argument("--renders", required=True, help="the folder with <Id>_surface.jpg from preview.py --lit --textured")
    ap.add_argument("--report", required=True, help="the JSON written by unwrap_bake.py --report")
    ap.add_argument("--out", required=True)
    ap.add_argument("--copy", help="also copy the finished sheet here")
    args = ap.parse_args()
    report = json.loads(pathlib.Path(args.report).read_text())
    rows = report["species"]
    models, renders = pathlib.Path(args.models), pathlib.Path(args.renders)
    cell_w, cell_h = RENDER + PALETTE + PAD, max(RENDER, PALETTE) + LABEL
    count = len(rows)
    lines = (count + COLUMNS - 1) // COLUMNS
    caption_h = 26
    width = COLUMNS * (cell_w + PAD) + PAD
    height = PAD + lines * (cell_h + PAD) + caption_h
    sheet = Image.new("RGB", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    big, small = font(13), font(11)
    failed = 0
    for index, row in enumerate(rows):
        sid = row["id"]
        x = PAD + (index % COLUMNS) * (cell_w + PAD)
        y = PAD + (index // COLUMNS) * (cell_h + PAD)
        bad = bool(row["problems"])
        failed += bad
        draw.text((x + 2, y), sid, fill=RED if bad else INK, font=big)
        if bad:
            draw.text((x + 2, y + 16), "FAILED: " + row["problems"][0][:44], fill=RED, font=small)
        else:
            draw.text((x + 2, y + 16), "%d islands, %d%% covered" % (row["islands"], round(row["coverage"])), fill=INK, font=small)
        top = y + LABEL
        render_path = renders / ("%s_surface.jpg" % sid)
        if render_path.is_file():
            sheet.paste(Image.open(render_path).convert("RGB").resize((RENDER, RENDER), Image.LANCZOS), (x, top))
        palette_path = models / sid / ("%s_palette.png" % sid)
        if palette_path.is_file():
            sheet.paste(palette_thumb(palette_path), (x + RENDER + PAD, top))
        if bad:
            draw.rectangle((x - 2, y - 2, x + cell_w + 1, y + cell_h + 1), outline=RED, width=2)
    settings = report.get("settings", {})
    good = [r for r in rows if not r["problems"]]
    caption = "Smart UV Project, angle limit %g, island margin %g, %d px palette (drawn at %d)%s. %d species, %d failed" % (
        settings.get("angle_limit", 0), settings.get("island_margin", 0), settings.get("size", 0), PALETTE,
        ", soft AO" if settings.get("ao") else "", count, failed)
    if good:
        caption += "; islands %d to %d, coverage %d to %d%%" % (min(r["islands"] for r in good), max(r["islands"] for r in good),
                                                               round(min(r["coverage"] for r in good)), round(max(r["coverage"] for r in good)))
    draw.text((PAD + 2, height - caption_h + 6), caption, fill=INK, font=small)
    out = pathlib.Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    for quality in (88, 82, 76, 70, 64, 58, 50):
        sheet.save(out, quality=quality, optimize=True)
        if out.stat().st_size < LIMIT:
            break
    print("%s (%d x %d, %d KB, quality %d, %d failed)" % (out, width, height, out.stat().st_size // 1024, quality, failed))
    if out.stat().st_size >= LIMIT:
        raise SystemExit("the sheet is over 450 KB even at quality 50")
    if args.copy:
        target = pathlib.Path(args.copy)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(out, target)
        print("copied to %s" % target)


if __name__ == "__main__":
    main()
