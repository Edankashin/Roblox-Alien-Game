#!/usr/bin/env python3
"""The character bar pilot sheet (Decision B54): each pilot before (the 2026-10-21 export) and after, front and three-quarter beside the 5-stud
avatar, with its tier and height printed, and a strip of each pilot from the game camera's distance (16 studs, slightly above).

Python 3 with Pillow (system Python, not Blender's). The renders come from tools/blender/pilot_shots.py (<Id>_front.png, _tq.png, _cam.png in a
folder for each state); the numbers come from the notes (tools/blocky/spec.py), the before ones from a folder of the old notes
(the 2026-10-21 export's, from commit ceed6b6).

  python3 -I tools/blocky/pilot_sheet.py --before-notes <dir> --before-shots <dir> --after-shots <dir> --out media/studio/2026-10-26/pilot_bar_v1.jpg
"""
from __future__ import annotations

import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf"
PAPER, INK, MUTED, GOOD, BAD = "#F6F0E6", "#1B1F3B", "#5F6375", "#1F7A4D", "#A33B3B"
PILOTS = ("Mossbop", "Radish", "Panpipe", "Fenripup")
WIDTH, MARGIN, GAP = 2000, 28, 14
IMG_W = 380


def font(n, bold=False):
    try:
        return ImageFont.truetype(FONT % ("Bold" if bold else "Regular"), n)
    except OSError:
        return ImageFont.load_default()


def fit(path, w, h=None):
    im = Image.open(path).convert("RGB")
    s = w / im.width
    return im.resize((w, int(im.height * s)), Image.LANCZOS)


def wrap(draw, text, fnt, width):
    lines, cur = [], ""
    for word in text.split():
        t = (cur + " " + word).strip()
        if draw.textlength(t, font=fnt) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def facts(spec):
    c = S.counts(spec)
    f = spec["front"]
    return {"name": f["name"], "id": f["id"], "tier": f["tier"], "world": int(f.get("world", 1)), "height": c["height"], "blocks": c["blocks"],
            "tris": int(f.get("tris") or c["tris"]), "objects": c["movers"], "motion": c["motion"], "kit": f.get("bar_kit", 0), "sats": f.get("bar_satellites", 0),
            "stance": f.get("bar_stance", "")}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--before-notes", required=True)
    ap.add_argument("--before-shots", required=True)
    ap.add_argument("--after-shots", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--quality", type=int, default=80)
    a = ap.parse_args(argv)
    before_dir, after_dir = pathlib.Path(a.before_shots), pathlib.Path(a.after_shots)
    rows = []
    for sid in PILOTS:
        b = facts(S.load(pathlib.Path(a.before_notes) / ("%s.md" % sid)))
        n = facts(S.load(CREATURES / ("%s.md" % sid)))
        rows.append((sid, b, n))
    f_title, f_sub, f_name, f_txt, f_small, f_cap = font(40, True), font(20), font(30, True), font(19), font(16), font(17, True)
    text_w = WIDTH - 2 * MARGIN - 4 * IMG_W - 4 * GAP
    # heights
    sample = fit(after_dir / "Mossbop_front.png", IMG_W)
    row_h = sample.height + 38
    cam_h = fit(after_dir / "Mossbop_cam.png", 470).height + 34
    H = 150 + 4 * row_h + 70 + 2 * cam_h + 70 + 40
    sheet = Image.new("RGB", (WIDTH, H), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((MARGIN, 22), "Character bar pilot v1, 2026-10-26: four aliens, four tiers, one bar (Decision B54)", font=f_title, fill=INK)
    d.text((MARGIN, 76), "Each alien before (today's 2026-10-21 export) and after: the same face, name and height, rebuilt with its world's accent kit, a posed stance,", font=f_sub, fill=MUTED)
    d.text((MARGIN, 102), "a satellite orbit on the rig, a backdrop (Cosmic and Secret) and a ground aura that breathes. Every picture beside the 5-stud avatar. Blender, Cycles; nothing uploaded.", font=f_sub, fill=MUTED)
    y = 146
    cols = ["before, front", "before, three-quarter", "after, front", "after, three-quarter"]
    for ci, label in enumerate(cols):
        x = MARGIN + text_w + GAP + ci * (IMG_W + GAP)
        d.text((x, y), label, font=f_cap, fill=(MUTED if ci < 2 else GOOD))
    y += 26
    for sid, b, n in rows:
        d.text((MARGIN, y), "%s" % n["name"], font=f_name, fill=INK)
        d.text((MARGIN, y + 38), "%s, World %d (%s)" % (n["tier"], n["world"], "Verdant" if n["world"] == 1 else "Frostbyte"), font=f_txt, fill=INK)
        d.text((MARGIN, y + 62), "height %.2f studs (avatar 5)" % n["height"], font=f_txt, fill=INK)
        lines = [
            "blocks %d to %d, triangles %d to %d (Blender)" % (b["blocks"], n["blocks"], b["tris"], n["tris"]),
            "moving things %d to %d" % (b["motion"], n["motion"]),
            "kit pieces %d to %d" % (b.get("kit", 0), n["kit"]),
        ]
        if n["sats"]:
            lines.append("satellites 0 to %d on the orbit" % n["sats"])
        yy = y + 90
        for ln in lines:
            d.text((MARGIN, yy), ln, font=f_small, fill=MUTED)
            yy += 21
        for ln in wrap(d, "Stance: " + n["stance"], f_small, text_w - 10)[:6]:
            d.text((MARGIN, yy + 4), ln, font=f_small, fill=INK)
            yy += 21
        for ci, name in enumerate(("%s_front.png", "%s_tq.png")):
            im = fit(before_dir / (name % sid), IMG_W)
            sheet.paste(im, (MARGIN + text_w + GAP + ci * (IMG_W + GAP), y))
        for ci, name in enumerate(("%s_front.png", "%s_tq.png")):
            im = fit(after_dir / (name % sid), IMG_W)
            sheet.paste(im, (MARGIN + text_w + GAP + (2 + ci) * (IMG_W + GAP), y))
        y += row_h
    y += 8
    d.text((MARGIN, y), "From the game camera: 16 studs away, slightly above, a 70 degree field of view (the middle of a 1080p frame at 1:1, the avatar beside)", font=f_name, fill=INK)
    y += 44
    for label, folder, colour in (("BEFORE", before_dir, MUTED), ("AFTER", after_dir, GOOD)):
        d.text((MARGIN, y), label, font=f_cap, fill=colour)
        y += 24
        x = MARGIN
        for sid, b, n in rows:
            im = fit(folder / ("%s_cam.png" % sid), 470)
            sheet.paste(im, (x, y))
            d.text((x + 6, y + 4), "%s, %s" % (n["name"], n["tier"]), font=f_cap, fill=INK)
            x += 470 + GAP
        y += cam_h - 24
    y += 6
    d.text((MARGIN, y), "Frostbyte stands on snow and Verdant on grass, as in play; what reads at 16 studs is the silhouette, the lit satellites and the colour blocks, not the cells.", font=f_small, fill=MUTED)
    sheet = sheet.crop((0, 0, WIDTH, y + 40))
    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=a.quality, optimize=True)
    print("wrote %s %dx%d %d KB" % (out, sheet.width, sheet.height, out.stat().st_size // 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
