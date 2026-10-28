#!/usr/bin/env python3
"""The character bar roster sheets for one world (Decisions B54 to B56): the review sheet and the faces sheet.

Python 3 with Pillow (system Python, not Blender's). The renders come from tools/blender/bar_shots.py (<Id>_front.png, _tq.png, _cam.png and _face.png in
a folder for each state, before and after); the numbers come from the notes (tools/blocky/spec.py), the before ones from a folder of the old notes.

  python3 -I tools/blocky/bar_sheet.py --ids Reindazzle,Shellberg,Capybubble,Shimmerlynx,Frostfang,Skaddle --before-notes <dir> --before-shots <dir> \\
      --after-shots <dir> --sheet media/studio/2026-10-26/bar_w2_v1.jpg --faces media/studio/2026-10-26/bar_w2_faces.jpg [--title "World 2"]

The review sheet (`--sheet`): per alien a text column (tier, height, blocks, triangles, moving things, kit pieces, satellites, backdrop, the stance), its
front and three-quarter views before and after beside the 5-stud avatar, and below them the 16-stud strip on the world's own ground (the game camera's
distance, a 70 degree field of view, 1:1 on a 1080p frame) before and after, with the face after. The faces sheet (`--faces`): each face straight on at 3
studs across, before above and after below, with its eye design and a line on what the face is doing, so the appeal check ([[Character-References]]) can
be made at a glance.
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
PAPER, INK, MUTED, GOOD = "#F6F0E6", "#1B1F3B", "#5F6375", "#1F7A4D"
WIDTH, MARGIN, GAP = 2000, 28, 14
IMG_W = 380
WORLD_NAME = {1: "Verdant", 2: "Frostbyte"}
# the face sheet's line per alien: what the face is doing and why it is a friend (a hand-written note beside the eye design the note names)
FACE_LINES = {
    "Reindazzle": "wide amber eyes, a lit red nose and a small smile; the head cocked, listening",
    "Shellberg": "patient gold crescents, a small smile, blush; the head turned toward its own flag",
    "Capybubble": "big glossy aqua eyes, blush, a cream snout with a smile; the head nodding, dozing",
    "Shimmerlynx": "a pink star in mint under violet lashes, a cat's mouth, heart cheeks; looking you over",
    "Frostfang": "a lit snowflake pupil in an ink rim, blush, two small icicle fangs; cheeky, never fierce",
    "Skaddle": "golden rings that breathe outward, star cheeks, a plain beak; a calm warden, head rolled",
}


def font(n, bold=False):
    try:
        return ImageFont.truetype(FONT % ("Bold" if bold else "Regular"), n)
    except OSError:
        return ImageFont.load_default()


def fit(path, w):
    im = Image.open(path).convert("RGB")
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


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


def built_tris(sid):
    """The triangles Blender built for the exported model (assets/models/<Id>/notes.md), or None."""
    notes = ROOT / "assets/models" / sid / "notes.md"
    if notes.is_file():
        for line in notes.read_text(encoding="utf-8").splitlines():
            if line.startswith("- Triangles: "):
                return int(line.split(":")[1].split()[0])
    return None


def facts(spec, measured=False):
    c = S.counts(spec)
    f = spec["front"]
    return {"name": f["name"], "id": f["id"], "tier": f["tier"], "world": int(f.get("world", 1)), "height": c["height"], "blocks": c["blocks"],
            "tris": (built_tris(f["id"]) if measured else None) or int(f.get("tris") or c["tris"]), "motion": c["motion"], "kit": f.get("bar_kit", 0),
            "sats": f.get("bar_satellites", 0), "backdrop": f.get("bar_backdrop", ""), "stance": f.get("bar_stance", ""),
            "eyes": (spec.get("eyes") or {}).get("key", "")}


def review_sheet(rows, before, after, out, title, quality):
    f_title, f_sub, f_name, f_txt, f_small, f_cap = font(40, True), font(20), font(30, True), font(19), font(16), font(17, True)
    text_w = WIDTH - 2 * MARGIN - 4 * IMG_W - 4 * GAP
    sample = fit(after / ("%s_front.png" % rows[0][0]), IMG_W)
    row_a = sample.height + 12
    cam_w = 470
    cam = fit(after / ("%s_cam.png" % rows[0][0]), cam_w)
    row_b = cam.height + 30
    H = 160 + len(rows) * (row_a + row_b + 22) + 60
    sheet = Image.new("RGB", (WIDTH, H), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((MARGIN, 22), "Character bar, %s: the Rare-and-up aliens, before and after (Decisions B54 to B56)" % title, font=f_title, fill=INK)
    d.text((MARGIN, 76), "Each alien beside the 5-stud avatar, front and three-quarter, then from the game camera's 16 studs on the world's own snow (slightly above, 70 degree field of view, 1:1 on a 1080p frame).", font=f_sub, fill=MUTED)
    d.text((MARGIN, 102), "Blender, Cycles; nothing uploaded. Mass clarity and value contrast are Blocky-Style section 10 rule 8: the body one value off the snow, the kit and trim a step, the satellites one lit colour with an edge.", font=f_sub, fill=MUTED)
    y = 146
    for ci, label in enumerate(["before, front", "before, three-quarter", "after, front", "after, three-quarter"]):
        d.text((MARGIN + text_w + GAP + ci * (IMG_W + GAP), y), label, font=f_cap, fill=(MUTED if ci < 2 else GOOD))
    y += 26
    for sid, b, n in rows:
        d.line((MARGIN, y - 8, WIDTH - MARGIN, y - 8), fill="#D9D2C2", width=2)
        d.text((MARGIN, y), n["name"], font=f_name, fill=INK)
        d.text((MARGIN, y + 38), "%s, World %d (%s)" % (n["tier"], n["world"], WORLD_NAME.get(n["world"], "")), font=f_txt, fill=INK)
        d.text((MARGIN, y + 62), "height %.2f studs (avatar 5)" % n["height"], font=f_txt, fill=INK)
        lines = ["blocks %d to %d, triangles %d to %d" % (b["blocks"], n["blocks"], b["tris"], n["tris"]),
                 "moving things %d to %d" % (b["motion"], n["motion"]), "kit pieces %d to %d" % (b["kit"], n["kit"])]
        if n["sats"]:
            lines.append("satellites 0 to %d (0.5 to 0.9 stud)" % n["sats"])
        if n["backdrop"]:
            lines.append("backdrop: yes (the `%s` object)" % n["backdrop"])
        yy = y + 90
        for ln in lines:
            d.text((MARGIN, yy), ln, font=f_small, fill=MUTED)
            yy += 21
        for ln in wrap(d, "Stance: " + n["stance"], f_small, text_w - 10)[:8]:
            d.text((MARGIN, yy + 4), ln, font=f_small, fill=INK)
            yy += 20
        for ci, (folder, name) in enumerate(((before, "%s_front.png"), (before, "%s_tq.png"), (after, "%s_front.png"), (after, "%s_tq.png"))):
            sheet.paste(fit(folder / (name % sid), IMG_W), (MARGIN + text_w + GAP + ci * (IMG_W + GAP), y))
        y += row_a
        d.text((MARGIN, y + 4), "16 studs, then the face", font=f_cap, fill=MUTED)
        x = MARGIN + text_w + GAP
        for folder, label, colour in ((before, "before", MUTED), (after, "after", GOOD)):
            sheet.paste(fit(folder / ("%s_cam.png" % sid), cam_w), (x, y))
            d.text((x + 6, y + 4), label, font=f_cap, fill=colour)
            x += cam_w + GAP
        face = Image.open(after / ("%s_face.png" % sid)).convert("RGB").resize((cam.height, cam.height), Image.LANCZOS)
        sheet.paste(face, (x, y))
        d.text((x + 6, y + 4), "after, face", font=f_cap, fill=GOOD)
        y += row_b + 22
    sheet = sheet.crop((0, 0, WIDTH, y + 10))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=quality, optimize=True)
    print("wrote %s %dx%d %d KB" % (out, sheet.width, sheet.height, out.stat().st_size // 1024))


def faces_sheet(rows, before, after, out, title, quality):
    n = len(rows)
    cell = 300
    f_title, f_name, f_txt, f_small, f_cap = font(30, True), font(20, True), font(15), font(13), font(15, True)
    W = MARGIN * 2 + n * cell + (n - 1) * 8
    H = 92 + 2 * (cell + 30) + 130
    sheet = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((MARGIN, 14), "Faces, %s: each straight on at 3 studs across, before above and after below" % title, font=f_title, fill=INK)
    d.text((MARGIN, 54), "Appeal check (Character-References): is it as clean, as symmetrical, as bright as a best-seller's face; would a ten-year-old pat it; do two eyes still read at 16 studs.", font=f_txt, fill=MUTED)
    for i, (sid, b, nw) in enumerate(rows):
        x = MARGIN + i * (cell + 8)
        d.text((x, 84), "%s, %s" % (nw["name"], nw["tier"]), font=f_name, fill=INK)
        for r, (folder, label, colour) in enumerate(((before, "before", MUTED), (after, "after", GOOD))):
            im = Image.open(folder / ("%s_face.png" % sid)).convert("RGB").resize((cell, cell), Image.LANCZOS)
            yy = 112 + r * (cell + 22)
            sheet.paste(im, (x, yy))
            d.text((x + 6, yy + 4), label, font=f_cap, fill=colour)
        yy = 112 + 2 * (cell + 22) + 2
        d.text((x, yy), "eyes: %s" % nw["eyes"], font=f_small, fill=INK)
        for k, ln in enumerate(wrap(d, FACE_LINES.get(sid, ""), f_small, cell)[:5]):
            d.text((x, yy + 18 + k * 16), ln, font=f_small, fill=MUTED)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=quality, optimize=True)
    print("wrote %s %dx%d %d KB" % (out, sheet.width, sheet.height, out.stat().st_size // 1024))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--ids", required=True)
    ap.add_argument("--before-notes", required=True)
    ap.add_argument("--before-shots", required=True)
    ap.add_argument("--after-shots", required=True)
    ap.add_argument("--sheet", default=None)
    ap.add_argument("--faces", default=None)
    ap.add_argument("--title", default="World 2")
    ap.add_argument("--quality", type=int, default=78)
    ap.add_argument("--faces-quality", type=int, default=72)
    a = ap.parse_args(argv)
    before, after = pathlib.Path(a.before_shots), pathlib.Path(a.after_shots)
    rows = []
    for sid in a.ids.split(","):
        b = facts(S.load(pathlib.Path(a.before_notes) / ("%s.md" % sid)))
        nw = facts(S.load(CREATURES / ("%s.md" % sid)), measured=True)
        rows.append((sid, b, nw))
    if a.sheet:
        review_sheet(rows, before, after, pathlib.Path(a.sheet), a.title, a.quality)
    if a.faces:
        faces_sheet(rows, before, after, pathlib.Path(a.faces), a.title, a.faces_quality)
    return 0


if __name__ == "__main__":
    sys.exit(main())
