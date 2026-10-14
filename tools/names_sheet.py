#!/usr/bin/env python3
"""Make the species-name picture sheets Ethan picks from.

  python3 -I tools/names_sheet.py [--out media/names]

Reads the candidate tables in docs/vault/01-game-design/Species-Names.md (the "####" heading over each
table is the header band's text; "World 2 ..." headings go to sheet_world2.png, everything else, event
aliens included, to sheet_world1.png) and draws one cell per species: the preview png from
assets/models/<Id>/<Id>.png (a coloured circle with the id when the png is missing), the current name in
small grey, then "A ...", "B ...", "C ..." in outlined text. Colours come from src/shared/Theme.luau
(Panel cream, Outline navy, Codex purple) and src/shared/data/Tiers.luau (a band takes its tier's colour);
the font is assets/fonts/FredokaOne.ttf. Each sheet is at most 1600 px wide and 1.5 MB.
"""
import argparse
import functools
import os
import re

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets", "fonts", "FredokaOne.ttf")
NOTE = os.path.join(ROOT, "docs", "vault", "01-game-design", "Species-Names.md")
W, PAD, GAP, COLS = 1600, 20, 14, 5
CELL_W = (W - 2 * PAD - (COLS - 1) * GAP) // COLS
IMG, LINE, SMALL, BAND = 196, 50, 26, 66
CELL_H = IMG + 14 + SMALL + 10 + 3 * LINE + 8
MAX_BYTES = 1_500_000


def read(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as f:
        return f.read()


def rgb(h):
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(round(a[i] * (1 - t) + b[i] * t) for i in range(3))


@functools.lru_cache(maxsize=None)
def font(size):
    return ImageFont.truetype(FONT, size)


def text(d, xy, s, size, fill, stroke=0, anchor="la", maxw=None):
    """Draw s, shrinking the size until it fits maxw. The outline is navy when stroke > 0."""
    f = font(size)
    while maxw and f.getlength(s) + 2 * stroke > maxw and size > 12:
        size -= 1
        f = font(size)
    d.text(xy, s, font=f, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=NAVY)


def load_theme():
    theme = read("src", "shared", "Theme.luau")
    col = lambda n: rgb(re.search(n + r'\s*=\s*Color3\.fromHex\("(\w{6})"\)', theme).group(1))
    tiers = {m[0]: rgb(m[1]) for m in re.findall(r'(\w+) = \{ share.*?color = "(\w{6})"', read("src", "shared", "data", "Tiers.luau"))}
    return col("Panel"), col("Outline"), col("Codex"), tiers


def load_species():
    return {m[0]: (m[1], rgb(m[2])) for m in re.findall(r'\{ id = "(\w+)", name = "([^"]+)".*?color = "(\w{6})"', read("src", "shared", "data", "Species.luau"))}


def load_groups(species):
    """[(heading, [(id, A, B, C)])] in the note's order."""
    groups = []
    for line in read("docs", "vault", "01-game-design", "Species-Names.md").splitlines():
        if line.startswith("#### "):
            groups.append((line[5:].strip(), []))
        elif groups and line.startswith("|"):
            c = [x.strip() for x in line.strip().strip("|").split("|")]
            if c[0] in species and len(c) >= 5:
                groups[-1][1].append((c[0], c[2], c[3], c[4]))
    return [g for g in groups if g[1]]


def preview(sid, color):
    p = os.path.join(ROOT, "assets", "models", sid, sid + ".png")
    if os.path.exists(p):
        im = Image.open(p).convert("RGB").resize((IMG, IMG), Image.LANCZOS)
    else:
        im = Image.new("RGB", (IMG, IMG), CREAM)
        d = ImageDraw.Draw(im)
        d.ellipse((IMG * 0.1, IMG * 0.1, IMG * 0.9, IMG * 0.9), fill=color, outline=NAVY, width=5)
        text(d, (IMG / 2, IMG / 2), sid, 30, (255, 255, 255), 3, "mm", IMG * 0.8)
    mask = Image.new("L", (IMG, IMG), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, IMG - 1, IMG - 1), 22, fill=255)
    im.putalpha(mask)
    return im


def draw_sheet(groups, species, tiers, path):
    rows = sum((len(g[1]) + COLS - 1) // COLS for g in groups)
    height = PAD * 2 + len(groups) * (BAND + GAP) + rows * (CELL_H + GAP)
    img = Image.new("RGB", (W, height), CREAM)
    d = ImageDraw.Draw(img)
    y = PAD
    for heading, items in groups:
        tier = heading.split(",")[-1].split(":")[0].strip()
        colour = tiers.get(tier, CODEX)
        d.rounded_rectangle((PAD, y, W - PAD, y + BAND), 18, fill=colour, outline=NAVY, width=4)
        text(d, (PAD + 22, y + BAND / 2 + 1), heading, 38, (255, 255, 255), 5, "lm", W - 2 * PAD - 44)
        y += BAND + GAP
        for n, (sid, a, b, c) in enumerate(items):
            x = PAD + (n % COLS) * (CELL_W + GAP)
            cy = y + (n // COLS) * (CELL_H + GAP)
            d.rounded_rectangle((x, cy, x + CELL_W, cy + CELL_H), 22, fill=mix(colour, CREAM, 0.8), outline=NAVY, width=4)
            pic = preview(sid, species[sid][1])
            img.paste(pic, (x + (CELL_W - IMG) // 2, cy + 8), pic)
            ty = cy + 8 + IMG + 6
            text(d, (x + CELL_W / 2, ty), "now: " + species[sid][0], SMALL, (110, 110, 120), 0, "ma", CELL_W - 20)
            for k, (letter, name) in enumerate(zip("ABC", (a, b, c))):
                ly = ty + SMALL + 10 + k * LINE
                d.ellipse((x + 12, ly + 5, x + 12 + 38, ly + 43), fill=NAVY)
                text(d, (x + 31, ly + 25), letter, 28, (255, 255, 255), 0, "mm")
                text(d, (x + 58, ly), name, 40, (255, 255, 255), 5, "la", CELL_W - 70)
        y += ((len(items) + COLS - 1) // COLS) * (CELL_H + GAP)
    img.save(path, optimize=True)
    if os.path.getsize(path) > MAX_BYTES:  # flat colours: a 256-colour palette is lossless enough
        img.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)
    print(f"{os.path.relpath(path, ROOT)}: {img.width}x{img.height}, {os.path.getsize(path) // 1024} KB, {sum(len(g[1]) for g in groups)} species")


CREAM, NAVY, CODEX, TIERS = load_theme()

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "media", "names"))
    out = ap.parse_args().out
    os.makedirs(out, exist_ok=True)
    species = load_species()
    groups = load_groups(species)
    draw_sheet([g for g in groups if not g[0].startswith("World 2")], species, TIERS, os.path.join(out, "sheet_world1.png"))
    draw_sheet([g for g in groups if g[0].startswith("World 2")], species, TIERS, os.path.join(out, "sheet_world2.png"))
