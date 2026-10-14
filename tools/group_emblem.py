#!/usr/bin/env python3
"""Make the Roblox group emblem: the Moop face in a circle, a cream ring, the short name on a banner.

  python3 -I tools/group_emblem.py [NAME] [--out media/group/emblem_v1.png] [--preview PATH] [--face PNG]

512x512 PNG (the size Roblox's own icon docs recommend; shown around 150x150 in lists). The banner, not
text on an arc, carries the name: it stays legible at 150x150. --preview also saves that 150x150 version
for a legibility check (delete it before committing). Colours are read from src/shared/Theme.luau
(Outline navy, Panel cream, Featured gold) so a re-skin follows; the font is assets/fonts/FredokaOne.ttf
(SIL Open Font License). NAME defaults to MOOP (the group is Moop Games); re-run with "CRASH PLANET" if the group takes the game's name.
"""
import argparse
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "FredokaOne.ttf")
FACE = os.path.join(ROOT, "media", "store", "2026-10-14", "icon_Mossbop_v2.png")
S = 2  # draw at 2x, then downsample for smooth edges
SIZE = 512
FACE_CENTRE, FACE_RADIUS = (512, 540), 392  # the crop circle on the 1024 icon: the crown tip to the bottom of the body


def theme(name, fallback):
    """One colour from Theme.Colors, e.g. Outline = Color3.fromHex("1B1F3B")."""
    try:
        src = open(os.path.join(ROOT, "src", "shared", "Theme.luau"), encoding="utf-8").read()
        h = re.search(name + r'\s*=\s*Color3\.fromHex\("([0-9A-Fa-f]{6})"\)', src).group(1)
    except (OSError, AttributeError):
        h = fallback
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def circle_face(path, diameter):
    """The Mossbop face cropped to a circle (antialiased through a 4x mask)."""
    img = Image.open(path).convert("RGB")
    cx, cy = FACE_CENTRE
    img = img.crop((cx - FACE_RADIUS, cy - FACE_RADIUS, cx + FACE_RADIUS, cy + FACE_RADIUS)).resize((diameter, diameter), Image.LANCZOS)
    mask = Image.new("L", (diameter * 4, diameter * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, diameter * 4 - 1, diameter * 4 - 1), fill=255)
    img.putalpha(mask.resize((diameter, diameter), Image.LANCZOS))
    return img


def build(name, face_path):
    navy, cream, gold = theme("Outline", "1B1F3B"), theme("Panel", "FFF4DC"), theme("Featured", "FFC83D")
    dark_gold = tuple(int(c * 0.78) for c in gold)
    w = SIZE * S
    img = Image.new("RGB", (w, w), navy)
    d = ImageDraw.Draw(img)

    # Face in the upper part: cream ring (thick), a navy hairline outside it, then the circle.
    cx, cy, ring, r_face = w // 2, 212 * S, 22 * S, 168 * S
    d.ellipse((cx - r_face - ring, cy - r_face - ring, cx + r_face + ring, cy + r_face + ring), fill=cream)
    d.ellipse((cx - r_face - 4 * S, cy - r_face - 4 * S, cx + r_face + 4 * S, cy + r_face + 4 * S), fill=navy)  # hairline between sky and ring
    face = circle_face(face_path, 2 * r_face)
    img.paste(face, (cx - r_face, cy - r_face), face)

    # Banner across the bottom: gold, navy outline, a darker lip, the name in cream with a navy outline.
    bx0, bx1, by0, by1, edge = 40 * S, w - 40 * S, 352 * S, 468 * S, 9 * S
    d.rounded_rectangle((bx0, by0, bx1, by1), radius=30 * S, fill=navy)
    d.rounded_rectangle((bx0 + edge, by0 + edge, bx1 - edge, by1 - edge), radius=22 * S, fill=dark_gold)
    d.rounded_rectangle((bx0 + edge, by0 + edge, bx1 - edge, by1 - edge - 12 * S), radius=22 * S, fill=gold)
    stroke = 8 * S
    probe = ImageFont.truetype(FONT, 100)
    l, t, r, b = d.textbbox((0, 0), name, font=probe, stroke_width=0)
    size = min(int((bx1 - bx0 - 2 * edge - 28 * S) * 100 / (r - l)), 92 * S)  # fit the banner, never huge
    font = ImageFont.truetype(FONT, size)
    l, t, r, b = d.textbbox((0, 0), name, font=font, stroke_width=stroke)
    tx = (w - (r - l)) / 2 - l
    ty = (by0 + by1 - 12 * S) / 2 - (t + b) / 2
    d.text((tx, ty), name, font=font, fill=cream, stroke_width=stroke, stroke_fill=navy)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name", nargs="?", default="MOOP", help="the short name on the banner")
    ap.add_argument("--out", default=os.path.join(ROOT, "media", "group", "emblem_v1.png"))
    ap.add_argument("--face", default=FACE, help="the 1024x1024 icon the face is cropped from")
    ap.add_argument("--preview", help="also save a 150x150 version here, to check it reads small")
    a = ap.parse_args()
    img = build(a.name.upper(), a.face)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    img.save(a.out, optimize=True)
    if os.path.getsize(a.out) > 1_000_000:  # keep it under 1 MB, as the store renders are
        img.quantize(256).save(a.out, optimize=True)
    if a.preview:
        img.resize((150, 150), Image.LANCZOS).save(a.preview)
    print(f"wrote {a.out} ({os.path.getsize(a.out) // 1024} KB)")


if __name__ == "__main__":
    main()
