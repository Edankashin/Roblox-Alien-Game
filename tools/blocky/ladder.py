#!/usr/bin/env python3
"""The blocky review sheet: the prototypes side by side to scale beside a 5-stud avatar, each with its three-quarter render, its VFX preview,
its concept-sheet thumbnail and its numbers (blocks, triangles, height, silhouette overlap per view). Also writes the two small images the style
bible embeds: the house face on every prototype (house_face.png) and a world's 64 px silhouette row (world<N>_silhouettes.png).

Python 3 with Pillow (system Python, not Blender's). Inputs come from the notes (tools/blocky/spec.py), the build folder of
tools/blender/blocky_build.py (<Id>_tq.png, <Id>_vfx.png, lineup.png) and the sheet folder of tools/blocky/sheet.py (<Id>_sheet.png).

  python3 -I tools/blocky/ladder.py --notes Mossbop.md,Thunderhog.md,Radish.md --build <dir> --sheets <dir> --out media/studio/<date>/blocky_ladder_v1.jpg \\
      --extras docs/vault/06-art-pipelines/refs/blocky
  python3 -I tools/blocky/ladder.py --layout rows --notes <seven notes in tier order> --build <dir> --sheets <dir> --out .../blocky_ladder_v2.jpg \\
      --before <folder of loop 1's <Id>_tq.jpg> --before-ids Mossbop,Thunderhog,Radish --title "..."     # one row per creature, a before/after strip
"""
from __future__ import annotations

import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import raster  # noqa: E402
import sheet as SH  # noqa: E402
import spec as S  # noqa: E402

FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf"
PAPER, INK, MUTED = "#F6F0E6", "#1B1F3B", "#5F6375"


def font(n, bold=False):
    try:
        return ImageFont.truetype(FONT % ("Bold" if bold else "Regular"), n)
    except OSError:
        return ImageFont.load_default()


def fit(img, w, h, bg=PAPER):
    img = img.convert("RGB")
    s = min(w / img.width, h / img.height)
    im = img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.LANCZOS)
    out = Image.new("RGB", (w, h), bg)
    out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return out


def face_image(spec, cell=14):
    rows = spec["face"]["rows"]
    im = Image.new("RGB", (len(rows[0]) * cell, len(rows) * cell))
    d = ImageDraw.Draw(im)
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            d.rectangle([c * cell, r * cell, (c + 1) * cell - 1, (r + 1) * cell - 1], fill=S.face_colour(spec, ch))
    return im


def house_face(specs, path):
    tiles = [face_image(s) for s in specs]
    h = max(t.height for t in tiles) + 40
    out = Image.new("RGB", (sum(t.width for t in tiles) + 30 * (len(tiles) + 1), h + 20), PAPER)
    d = ImageDraw.Draw(out)
    x = 30
    for s, t in zip(specs, tiles):
        out.paste(t, (x, 10))
        d.text((x, t.height + 18), "%s (%s), %d x %d" % (s["front"]["name"], s["front"]["tier"], len(s["face"]["rows"][0]), len(s["face"]["rows"])),
               font=font(16, True), fill=INK)
        x += t.width + 30
    out.save(path)
    return path


def silhouettes(specs, path, size=64, zoom=2):
    """Every species of a world as a 64 px black shape (front view, each in its own frame) in one row, with the boxed overlap of each pair."""
    masks = []
    for s in specs:
        fr = SH.frames(s)["front"]
        masks.append(SH.view_mask(s, "front", fr, size))
    pad = 24
    n_pairs = len(specs) * (len(specs) - 1) // 2
    cols = 1 if n_pairs <= 6 else 3  # a long pair list wraps into columns
    per_col = -(-n_pairs // cols)
    out = Image.new("RGB", (max(420, len(specs) * (size * zoom + pad) + pad), size * zoom + 90 + 20 * per_col), "#FFFFFF")
    d = ImageDraw.Draw(out)
    for i, (s, m) in enumerate(zip(specs, masks)):
        im = Image.new("L", (size, size), 255)
        im.putdata([0 if v else 255 for v in m])
        out.paste(im.resize((size * zoom, size * zoom), Image.NEAREST), (pad + i * (size * zoom + pad), 10))
        d.text((pad + i * (size * zoom + pad), size * zoom + 16), s["front"]["name"], font=font(15, True), fill=INK)
    pairs, worst = [], (0.0, "")
    for i in range(len(specs)):
        for j in range(i + 1, len(specs)):
            v = raster.iou(boxed(masks[i], size), boxed(masks[j], size))
            name = "%s/%s" % (specs[i]["front"]["name"], specs[j]["front"]["name"])
            pairs.append("%s %.2f" % (name, v))
            worst = max(worst, (v, name))
    verdict = "passes" if worst[0] < 0.7 else "FAILS"
    d.text((pad, size * zoom + 42), "boxed overlap of each pair (under 0.7 passes); worst %s %.2f: %s" % (worst[1], worst[0], verdict), font=font(13, True),
           fill=MUTED)
    for k, line in enumerate(pairs):
        d.text((pad + (k // per_col) * 300, size * zoom + 66 + 20 * (k % per_col)), line, font=font(13), fill=MUTED)
    print("  " + "; ".join(pairs))
    out.save(path)
    return path


def boxed(mask, size, n=48):
    """The shape cropped to its bounding box and stretched to n x n (the Silhouette-Pass check: the shape alone)."""
    ys = [i // size for i, v in enumerate(mask) if v]
    xs = [i % size for i, v in enumerate(mask) if v]
    if not ys:
        return bytearray(n * n)
    y0, y1, x0, x1 = min(ys), max(ys), min(xs), max(xs)
    out = bytearray(n * n)
    for r in range(n):
        for c in range(n):
            sy = y0 + int((r + 0.5) * (y1 - y0 + 1) / n)
            sx = x0 + int((c + 0.5) * (x1 - x0 + 1) / n)
            out[r * n + c] = mask[sy * size + sx]
    return out


def ladder(specs, build, sheets, out_path, title):
    W = 2400
    col_w = (W - 80) // len(specs)
    lineup = Image.open(build / "lineup.png")
    lh = int(W * lineup.height / lineup.width * 0.92)
    tile = col_w - 40
    H = 120 + lh + 40 + 70 + tile + 24 + tile + 24 + 28 + int(tile * 0.62) + 300
    img = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.text((40, 30), title, font=font(40, True), fill=INK)
    d.text((40, 82), "Blocky prototypes, World 1, built from their spec notes (Obsidian), drawn as sheets for Claude Design, built and rendered in Blender. "
           "Scratch builds: nothing under assets/models changed.", font=font(20), fill=MUTED)
    img.paste(fit(lineup, W - 80, lh, "#FFFFFF"), (40, 120))
    d.text((52, 128), "To scale: a 5-stud avatar, then Moop, Voltus and Raddis", font=font(22, True), fill=INK)
    y0 = 120 + lh + 40
    for i, s in enumerate(specs):
        f = s["front"]
        sid = f["id"]
        x = 40 + i * col_w
        tier_hex = SH.TIER_HEX.get(f["tier"], "#999999")
        d.rectangle([x, y0, x + tile, y0 + 54], fill=tier_hex)
        d.text((x + 16, y0 + 10), "%s  %s" % (f["name"], f["tier"].upper()), font=font(30, True), fill="#FFFFFF" if f["tier"] not in ("Common",) else INK)
        y = y0 + 70
        img.paste(fit(Image.open(build / ("%s_tq.png" % sid)), tile, tile, "#FFFFFF"), (x, y))
        d.text((x + 10, y + 8), "three-quarter, lit", font=font(18, True), fill=INK)
        y += tile + 24
        vfx = build / ("%s_vfx.png" % sid)
        if vfx.exists():
            img.paste(fit(Image.open(vfx), tile, tile), (x, y))
        else:
            d.rectangle([x, y, x + tile, y + tile], fill="#E9E2D6")
            d.text((x + tile // 2, y + tile // 2), "No VFX: a Common has no glow and no light\n(the sprout's unfurl is a procedural move)", font=font(22),
                   fill=MUTED, anchor="mm", align="center")
        y += tile + 24
        sh = int(tile * 0.62)
        d.text((x, y), "concept sheet (the SVG goes on the Claude Design canvas)", font=font(18, True), fill=INK)
        y += 28
        img.paste(fit(Image.open(sheets / ("%s_sheet.png" % sid)), tile, sh, "#FFFFFF"), (x, y))
        y += sh + 20
        c = S.counts(s)
        ov = f.get("overlap") or []
        rows = [
            ("blocks", "%d  (%s band %d to %d)" % (c["blocks"], f["tier"], *S.TIERS[f["tier"]]["blocks"])),
            ("triangles", "%s of 2,500  (bevel %s x %s)" % (f.get("tris"), f.get("bevel_width"), f.get("bevel_segments"))),
            ("height", "%.2f studs = %.1f avatars" % (c["height"], c["height"] / 5.0)),
            ("silhouette overlap", "front %s, right %s, top %s, back %s" % tuple(("%.3f" % v) for v in ov) if len(ov) == 4 else "not built"),
            ("moving parts", ", ".join(S.movers(S.expand(s["parts"]))) or "none"),
            ("hero", str(f.get("hero"))),
        ]
        for k, (label, value) in enumerate(rows):
            d.text((x, y + k * 32), label, font=font(20, True), fill=INK)
            d.text((x + 220, y + k * 32), value, font=font(20), fill=INK)
    img.save(out_path, quality=88)
    return out_path


def _image(path, fallback_suffixes=(".png", ".jpg")):
    """Open <path> or the same stem with another suffix (a build folder holds PNGs, the vault JPGs)."""
    path = pathlib.Path(path)
    for p in [path] + [path.with_suffix(s) for s in fallback_suffixes]:
        if p.exists():
            return Image.open(p)
    return None


def silhouette_row(specs, size=64, zoom=2):
    """The 64 px front silhouettes of `specs` side by side (an image) and the worst boxed overlap of any pair."""
    masks = [SH.view_mask(s, "front", SH.frames(s)["front"], size) for s in specs]
    pad = 24
    out = Image.new("RGB", (len(specs) * (size * zoom + pad) + pad, size * zoom + 40), "#FFFFFF")
    d = ImageDraw.Draw(out)
    for i, (s, m) in enumerate(zip(specs, masks)):
        im = Image.new("L", (size, size), 255)
        im.putdata([0 if v else 255 for v in m])
        out.paste(im.resize((size * zoom, size * zoom), Image.NEAREST), (pad + i * (size * zoom + pad), 6))
        d.text((pad + i * (size * zoom + pad), size * zoom + 12), s["front"]["name"], font=font(16, True), fill=INK)
    worst = max((raster.iou(boxed(masks[i], size), boxed(masks[j], size)), specs[i]["front"]["name"], specs[j]["front"]["name"])
                for i in range(len(specs)) for j in range(i + 1, len(specs)))
    return out, worst


def ladder_rows(specs, build, sheets, out_path, title, before=None, before_ids=()):
    """The review sheet for a full ladder: the lineup to scale, then one row per creature (its numbers, the lit three-quarter view, the VFX
    preview from Rare up, the concept-sheet thumbnail), then a before/after strip for `before_ids` (renders of an earlier loop in `before`)
    and the 64 px silhouette row with its worst pair."""
    W, pad, row_h, tile = 2400, 40, 430, 400
    lineup = Image.open(build / "lineup.png")
    lh = int((W - 2 * pad) * lineup.height / lineup.width)
    strip_h = 120 + 380 if before_ids else 0
    sil, worst = silhouette_row(specs)
    H = 130 + lh + 50 + len(specs) * (row_h + 20) + strip_h + 90 + sil.height + 60
    img = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.text((pad, 28), title, font=font(40, True), fill=INK)
    d.text((pad, 82), "World 1, built from the spec notes (Obsidian), drawn as sheets for Claude Design, built and rendered in Blender. Scratch builds: "
           "nothing under assets/models changed. Every number is measured from the build.", font=font(20), fill=MUTED)
    img.paste(fit(lineup, W - 2 * pad, lh, "#FFFFFF"), (pad, 120))
    d.text((pad + 12, 128), "To scale beside a 5-stud avatar: " + ", ".join(s["front"]["name"] for s in specs), font=font(22, True), fill=INK)
    y = 120 + lh + 40
    for s in specs:
        f = s["front"]
        sid, tier = f["id"], f["tier"]
        tier_hex = SH.TIER_HEX.get(tier, "#999999")
        d.rectangle([pad, y, W - pad, y + row_h], fill="#FBF8F2", outline="#E2DACB")
        d.rectangle([pad, y, pad + 560, y + 56], fill=tier_hex)
        d.text((pad + 16, y + 10), "%s  %s" % (f["name"], tier.upper()), font=font(32, True), fill="#FFFFFF" if tier not in ("Common", "Uncommon") else INK)
        c = S.counts(s)
        ov = f.get("overlap") or []
        lines = [
            ("id", "%s, hero %s" % (sid, f.get("hero"))),
            ("blocks", "%d  (%s band %d to %d)" % (c["blocks"], tier, *S.TIERS[tier]["blocks"])),
            ("triangles", "%s of 2,500" % f.get("tris")),
            ("height", "%.2f studs = %.1f avatars" % (c["height"], c["height"] / 5.0)),
            ("overlap", " / ".join("%.3f" % v for v in ov) if len(ov) == 4 else "not built"),
            ("moving", ", ".join(S.movers(S.expand(s["parts"]))) or "none"),
        ]
        for k, (label, value) in enumerate(lines):
            d.text((pad + 16, y + 74 + k * 40), label, font=font(20, True), fill=INK)
            d.text((pad + 150, y + 74 + k * 40), value, font=font(20), fill=INK)
        pal = S.palette(s)
        for k, (role, hexcol) in enumerate(pal.items()):
            d.rectangle([pad + 16 + k * 58, y + row_h - 52, pad + 66 + k * 58, y + row_h - 16], fill=hexcol, outline="#888888")
        x = pad + 580
        tq = _image(build / ("%s_tq.png" % sid))
        if tq is not None:
            img.paste(fit(tq, tile, tile, "#FFFFFF"), (x, y + 15))
        x += tile + 20
        vfx = _image(build / ("%s_vfx.png" % sid))
        if vfx is not None:
            img.paste(fit(vfx, tile, tile), (x, y + 15))
        else:
            d.rectangle([x, y + 15, x + tile, y + 15 + tile], fill="#E9E2D6")
            d.text((x + tile // 2, y + 15 + tile // 2), "No VFX preview below Rare:\n%s" % ("no glow, no light" if tier == "Common" else "one touch, no glow"),
                   font=font(22), fill=MUTED, anchor="mm", align="center")
        x += tile + 20
        sh = _image(sheets / ("%s_sheet.png" % sid))
        if sh is not None:
            img.paste(fit(sh, W - pad - x - 15, tile, "#FFFFFF"), (x, y + 15))
        y += row_h + 20
    if before_ids:
        d.text((pad, y + 10), "Loop 1 to loop 2: the three prototypes before (left of each pair) and after", font=font(28, True), fill=INK)
        y += 60
        pair_w = (W - 2 * pad - 2 * 40) // len(before_ids)
        for i, sid in enumerate(before_ids):
            x = pad + i * (pair_w + 40)
            b = _image(pathlib.Path(before) / ("%s_tq.jpg" % sid))
            a = _image(build / ("%s_tq.png" % sid))
            half = (pair_w - 30) // 2
            for k, im in enumerate((b, a)):
                if im is not None:
                    img.paste(fit(im, half, 340, "#FFFFFF"), (x + k * (half + 30), y))
            d.text((x + half + 4, y + 160), ">", font=font(30, True), fill=MUTED)
            d.text((x, y + 346), "%s: loop 1 | loop 2" % next(s["front"]["name"] for s in specs if s["front"]["id"] == sid), font=font(20, True), fill=INK)
        y += 380
    d.text((pad, y + 30), "Silhouette test (front views, 64 px, each in its own frame): worst boxed overlap %.2f (%s / %s); under 0.7 passes" % worst,
           font=font(26, True), fill=INK)
    img.paste(sil, (pad, y + 80))
    img = img.crop((0, 0, W, min(H, y + 80 + sil.height + 40)))
    img.save(out_path, quality=88)
    return out_path


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--notes", required=True, help="comma list of creature notes, in ladder order")
    ap.add_argument("--build", required=True)
    ap.add_argument("--sheets", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--extras", default="", help="a folder for house_face.png and world<N>_silhouettes.png")
    ap.add_argument("--title", default="Blocky ladder v1: Common, Epic, Cosmic")
    ap.add_argument("--layout", default="columns", choices=("columns", "rows"), help="columns (a few creatures) or rows (a whole ladder)")
    ap.add_argument("--before", default="", help="rows layout: a folder of an earlier loop's <Id>_tq.jpg for the before/after strip")
    ap.add_argument("--before-ids", default="", help="rows layout: comma list of ids for the before/after strip")
    a = ap.parse_args(argv)
    specs = [S.load(n) for n in a.notes.split(",") if n]
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    if a.layout == "rows":
        print(ladder_rows(specs, pathlib.Path(a.build), pathlib.Path(a.sheets), out, a.title, a.before, [i for i in a.before_ids.split(",") if i]))
    else:
        print(ladder(specs, pathlib.Path(a.build), pathlib.Path(a.sheets), out, a.title))
    if a.extras:
        ex = pathlib.Path(a.extras)
        ex.mkdir(parents=True, exist_ok=True)
        print(house_face(specs, ex / "house_face.png"))
        worlds = sorted({s["front"]["world"] for s in specs})
        for w in worlds:
            print(silhouettes([s for s in specs if s["front"]["world"] == w], ex / ("world%s_silhouettes.png" % w)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
