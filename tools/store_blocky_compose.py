#!/usr/bin/env python3
"""Finish the block-cell store set from tools/blender/store_blocky.py's raw passes (Pillow and numpy, system python3).

  python3 -I tools/store_blocky_compose.py RAW_DIR OUT_DIR

For each shot in RAW_DIR (<shot>_raw.png RGBA, <shot>_hero.png and <shot>_cast.png masks, <shot>.json): paint the sky in stepped cell
bands behind the transparent render (day, dusk, night with star cells, Frostbyte's aurora and moon, the ladder's violet), add bloom where
the render glows, a tier-coloured aura behind the hero, the thick navy outline round the hero (1.4% of the frame height; 2% on the icons so
they hold at 64 px) and a thin one round the cast, then the 2D overlays in the game's block-cell UI (Theme hexes): the capture bar on 2,
the Cosmic reveal card with its pixel sky on 6, and the Fredoka One title "Catch an Alien" with a thick outline in the top third on 1, 3
and 5. Writes into OUT_DIR:
  icon_A.png, icon_B.png, icon_C.png          512 x 512, no text
  thumb_1.png ... thumb_6.png                1920 x 1080
  icons_64_strip.png                         the three icons at 64 px (the smallest size they are seen at)
  choices.jpg                                the labelled sheet for Ethan: icons A to C at full size and at 64 px, thumbnails 1 to 6
  thumb_S1.png ... thumb_S3.png              the scenic set (and <shot>_notitle.png), 1920 x 1080
  scenic_400_strip.png, scenic_choices.jpg   S1 to S3 at 400 px; the labelled scenic sheet with icon A (Ethan's pick)
The two sheets are rewritten only when one of their own shots was composed in this run.
Every PNG is kept under 2 MB (truecolour; a 256-colour palette only as a fallback). Our own art only.
"""
from __future__ import annotations

import json
import math
import os
import pathlib
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = str(ROOT / "assets/fonts/FredokaOne.ttf")
NAVY, TROUGH, CREAM = "1B1F3B", "2A2F55", "FFF4DC"
GREEN, GOLD, WHITE, SELECT = "51DF51", "FFC83D", "FFFFFF", "68C9FE"
TIER = {"Common": "B0B0B0", "Uncommon": "57F96C", "Rare": "3B82F6", "Epic": "C026D3", "Legendary": "F59E0B", "Cosmic": "EC4899",
        "Secret": "8B5CF6"}
TITLE = "Catch an Alien"
MAX_BYTES = 2_000_000


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def f3(h):
    return np.array(rgb(h), dtype=np.float32) / 255.0


# ------------------------------------------------------------------------------------------------ masks and light
def dilate(a, r):
    """Disc dilation of a float mask by r px (separable rows of a disc, numpy shifts only)."""
    r = max(1, int(round(r)))
    h, w = a.shape
    pad = np.pad(a, r)
    out = np.zeros_like(a)
    rows = {}
    for dy in range(-r, r + 1):
        hw = int(math.floor(math.sqrt(r * r - dy * dy)))
        if hw not in rows:
            m = np.zeros((h + 2 * r, w), dtype=a.dtype)
            for dx in range(-hw, hw + 1):
                np.maximum(m, pad[:, r + dx:r + dx + w], out=m)
            rows[hw] = m
        np.maximum(out, rows[hw][r + dy:r + dy + h, :], out=out)
    return out


def blur(a, radius):
    """Gaussian blur of a float HxW or HxWx3 array through Pillow (16-bit precision is plenty here)."""
    if a.ndim == 2:
        im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius))
        return np.asarray(im, dtype=np.float32) / 255.0
    return np.stack([blur(a[..., c], radius) for c in range(3)], axis=-1)


def load_mask(path, size):
    if not path.exists():
        return np.zeros((size[1], size[0]), dtype=np.float32)
    return np.asarray(Image.open(path).convert("RGBA").getchannel("A"), dtype=np.float32) / 255.0


def bloom(img, strength, k):
    """Glow round the bright parts (Cycles has none): the pixels over 0.72 luminance, blurred at two radii, added."""
    lum = img @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    bright = img * np.clip((lum - 0.8) / 0.2, 0, 1)[..., None]
    glow = blur(bright, 10 * k) * 0.9 + blur(bright, 34 * k) * 0.8
    return np.clip(img + glow * strength, 0, 1)


def outline(img, mask, r, colour=NAVY):
    ring = np.clip(dilate(mask, r) - mask, 0, 1)[..., None]
    return img * (1 - ring) + f3(colour) * ring


def aura(img, mask, colour, r, alpha=0.75):
    glow = (blur(dilate(mask, r * 0.6), r) * (1 - mask))[..., None] * alpha  # behind the hero only, never over it
    return img * (1 - glow) + f3(colour) * glow


# ------------------------------------------------------------------------------------------------ skies, in stepped cells
def cell_gradient(w, h, stops, cell):
    """A vertical gradient quantised to whole cell rows and to bands (the Reveal's pixel sky: stepped, never smooth)."""
    rows = max(2, h // cell + 1)
    t = np.linspace(0, 1, rows)
    pos = np.array([p for p, _ in stops])
    cols = np.stack([f3(c) for _, c in stops])
    band = np.stack([np.interp(t, pos, cols[:, c]) for c in range(3)], axis=-1)
    small = np.repeat(band[:, None, :], max(2, w // cell + 1), axis=1)
    jitter = np.random.default_rng(44).choice([-0.025, 0, 0, 0, 0, 0, 0.025], size=small.shape[:2])[..., None]
    small = np.clip(small + jitter, 0, 1)
    im = Image.fromarray((small * 255).astype(np.uint8), "RGB").resize((small.shape[1] * cell, small.shape[0] * cell), Image.NEAREST)
    return np.asarray(im, dtype=np.float32)[:h, :w] / 255.0


def star_cells(img, cell, count, seed, top=0.0, bottom=0.6, colour="FFFFFF"):
    rnd = random.Random(seed)
    h, w, _ = img.shape
    c = f3(colour)
    for _ in range(count):
        x = rnd.randrange(0, w - cell * 3)
        y = rnd.randrange(int(top * h), max(int(top * h) + 1, int(bottom * h)))
        s = cell if rnd.random() < 0.8 else cell * 2
        a = rnd.uniform(0.55, 1.0)
        img[y:y + s, x:x + s] = img[y:y + s, x:x + s] * (1 - a) + c * a
        if s == cell * 2 and rnd.random() < 0.6:  # a twinkle: a plus of cells
            for dx, dy in ((-cell, 0), (2 * cell, 0), (0, -cell), (0, 2 * cell)):
                yy, xx = y + dy + cell // 2, x + dx + cell // 2
                if 0 <= yy < h - cell and 0 <= xx < w - cell:
                    img[yy:yy + cell // 2 + 1, xx:xx + cell // 2 + 1] = c * 0.8 + img[yy:yy + cell // 2 + 1, xx:xx + cell // 2 + 1] * 0.2
    return img


def cloud_cells(img, cell, seed, count=5, top=0.05, bottom=0.35):
    """Flat block clouds: a few stacks of white cells, a lit top row and a shaded bottom row."""
    rnd = random.Random(seed)
    h, w, _ = img.shape
    for _ in range(count):
        cw, ch = rnd.randint(6, 12), rnd.randint(2, 3)
        x0 = rnd.randrange(0, w - cw * cell)
        y0 = rnd.randrange(int(top * h), int(bottom * h))
        for j in range(ch):
            inset = (ch - 1 - j) * rnd.randint(1, 2)
            for i in range(inset, cw - inset // 2):
                shade = 1.0 if j < ch - 1 else 0.88
                y, x = y0 + j * cell, x0 + i * cell
                img[y:y + cell, x:x + cell] = img[y:y + cell, x:x + cell] * 0.12 + np.array([1.0, 1.0, 1.0]) * shade * 0.88
    return img


def moon(img, cx, cy, r, cell):
    """A pixel moon: a disc of pale cells with a darker crater cell or two and a soft glow round it."""
    h, w, _ = img.shape
    yy, xx = np.mgrid[0:h, 0:w]
    gx, gy = (xx // cell) * cell + cell / 2, (yy // cell) * cell + cell / 2
    d = np.hypot(gx - cx, gy - cy)
    glow = np.clip(1 - np.hypot(xx - cx, yy - cy) / (r * 3.2), 0, 1) ** 2 * 0.45
    img = img * (1 - glow[..., None]) + f3("DCEBFF") * glow[..., None]
    disc = (d < r)[..., None]
    shade = np.where(((gx - cx + r * 0.3) ** 2 + (gy - cy - r * 0.2) ** 2) < (r * 0.28) ** 2, 0.86, 1.0)
    shade = np.where(((gx - cx - r * 0.35) ** 2 + (gy - cy + r * 0.35) ** 2) < (r * 0.18) ** 2, 0.88, shade)
    return np.where(disc, f3("F4F7FF") * shade[..., None], img)


def aurora(img, cell, seed=7):
    """Frostbyte's aurora: three curtains of stepped green, teal and violet cells, brightest at their lower edge."""
    h, w, _ = img.shape
    rnd = random.Random(seed)
    cols = w // cell + 1
    for k, (colour, base, amp, thick) in enumerate((("5CF2B0", 0.22, 0.07, 0.16), ("4FD8E8", 0.15, 0.05, 0.12), ("B58CFF", 0.08, 0.04, 0.1))):
        ph, fq = rnd.uniform(0, 6), rnd.uniform(1.6, 2.6)
        c = f3(colour)
        for i in range(cols):
            t = i / cols
            y_low = int((base + amp * math.sin(fq * math.tau * t + ph) + 0.03 * math.sin(7 * t + ph)) * h) // cell * cell
            n = int(thick * h * (0.6 + 0.4 * math.sin(3 * t + ph))) // cell
            for j in range(max(1, n)):
                y = y_low - j * cell
                if y < 0:
                    break
                a = 0.55 * (1 - j / max(1, n)) ** 1.3 * (0.75 + 0.25 * math.sin(11 * t + k))
                x = i * cell
                img[y:y + cell, x:x + cell] = img[y:y + cell, x:x + cell] * (1 - a) + c * a
    return img


def sky(kind, w, h, k):
    cell = max(4, int(round(12 * k)))
    if kind == "day":
        img = cell_gradient(w, h, [(0, "2C7BE5"), (0.55, "6FB8F5"), (1, "CDEFFF")], cell)
        return cloud_cells(img, cell, 5, count=4)
    if kind == "dusk":
        return star_cells(cell_gradient(w, h, [(0, "2A1F78"), (0.45, "8A4FC8"), (0.8, "F08DB8"), (1, "FFC48A")], cell), cell, 26, 3, 0, 0.3)
    if kind == "night":
        return star_cells(cell_gradient(w, h, [(0, "0A0B2A"), (0.6, "2B2470"), (1, "4E3F9E")], cell), cell, 90, 11, 0, 0.7)
    if kind == "aurora":
        img = cell_gradient(w, h, [(0, "070B26"), (0.55, "13306B"), (1, "3E6BB0")], cell)
        img = star_cells(img, cell, 80, 21, 0, 0.6)
        img = aurora(img, cell)
        return moon(img, w * 0.80, h * 0.20, h * 0.085, cell)
    if kind == "ladder":
        img = cell_gradient(w, h, [(0, "1B1F3B"), (0.5, "4A2F9E"), (1, "6948B9")], cell)
        return star_cells(img, cell, 60, 31, 0, 0.75, "D9CCFF")
    return cell_gradient(w, h, [(0, "1B1F3B"), (1, "1B1F3B")], cell)


# ------------------------------------------------------------------------------------------------ text and block UI
def title(img, text, k, align="center", width=0.62):
    """The game's title: Fredoka One, Heading yellow, a thick navy outline and a soft drop shadow, in the top third."""
    pil = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB")
    w, h = pil.size
    stroke = int(round(0.022 * h))
    probe = ImageDraw.Draw(pil)
    l, _, r, _ = probe.textbbox((0, 0), text, font=ImageFont.truetype(FONT, 100))
    size = int((width * w - 2 * stroke) * 100 / (r - l))
    font = ImageFont.truetype(FONT, size)
    l, t, r, b = probe.textbbox((0, 0), text, font=font, stroke_width=stroke)
    x = {"center": (w - (r - l)) / 2, "left": 0.035 * w, "right": 0.965 * w - (r - l)}[align] - l
    y = 0.045 * h - t
    shadow = Image.new("L", pil.size, 0)
    ImageDraw.Draw(shadow).text((x, y + stroke * 0.45), text, font=font, fill=255, stroke_width=stroke, stroke_fill=255)
    shadow = shadow.filter(ImageFilter.GaussianBlur(stroke * 0.4)).point(lambda v: int(v * 0.55))
    pil.paste(rgb("0A0C1E"), mask=shadow)
    ImageDraw.Draw(pil).text((x, y), text, font=font, fill=rgb("FFEF4A"), stroke_width=stroke, stroke_fill=rgb(NAVY))
    print(f"  title {size}px, outline {stroke}px, ink {int(r - l)}x{int(b - t)} at y {int(y + t)}..{int(y + b)} ({(y + b) / h:.2f} of h)")
    return np.asarray(pil, dtype=np.float32) / 255.0


def block_plate(d, x0, y0, cols, rows, cell, face, ink=NAVY, top=True, grout=True, seed=44):
    """The UI's block plate (UI Playbook, Block cells): whole square cells, the four corner cells cut, a navy ink round the notched shape,
    the top row lit, the bottom row and the side columns shaded, grout on each cell's right and bottom edge, a few cells a shade off."""
    inkw = max(2, int(round(cell * 0.4)))
    W, H = cols * cell, rows * cell
    for (ax, ay, bx, by) in ((x0 - inkw, y0 + cell - inkw, x0 + W + inkw, y0 + H - cell + inkw),
                             (x0 + cell - inkw, y0 - inkw, x0 + W - cell + inkw, y0 + H + inkw)):
        d.rectangle([ax, ay, bx - 1, by - 1], fill=rgb(ink))
    for (ax, ay, bx, by) in ((x0, y0 + cell, x0 + W, y0 + H - cell), (x0 + cell, y0, x0 + W - cell, y0 + H)):
        d.rectangle([ax, ay, bx - 1, by - 1], fill=rgb(face))
    rnd = random.Random(seed)
    fr = np.array(rgb(face), dtype=np.float32)
    for j in range(rows):
        for i in range(cols):
            if (i in (0, cols - 1)) and (j in (0, rows - 1)):
                continue
            c = fr.copy()
            roll = rnd.random()
            if roll < 0.125:
                c = c * 0.9
            elif roll < 0.25:
                c = c + (255 - c) * 0.1
            if top and j == 0:
                c = c + (255 - c) * 0.3
            elif j == rows - 1 or i in (0, cols - 1):
                c = c * 0.8
            cx, cy = x0 + i * cell, y0 + j * cell
            d.rectangle([cx, cy, cx + cell - 1, cy + cell - 1], fill=tuple(int(v) for v in np.clip(c, 0, 255)))
            if grout:
                g = max(1, cell // 8)
                gc = tuple(int(v * 0.9) for v in np.clip(c, 0, 255))
                d.rectangle([cx + cell - g, cy, cx + cell - 1, cy + cell - 1], fill=gc)
                d.rectangle([cx, cy + cell - g, cx + cell - 1, cy + cell - 1], fill=gc)


def capture_bar(img, k, tier="Legendary"):
    """The capture bar in block cells (CaptureBar.luau since 2026-10-21): the trough a dark plate of 3 cell rows, the Good and Perfect
    zones exact bands in Confirm green and Featured gold (Legendary's real widths from data/Tiers), the white light trail over the cells the
    sweep has passed, and the stepped pixel arrow marker (7 by 11) inside the Perfect band. 0.6 of the width, centred at 0.77 of the height."""
    pil = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB").convert("RGBA")
    w, h = pil.size
    good, perfect = {"Legendary": (0.16, 0.05), "Cosmic": (0.14, 0.04), "Rare": (0.26, 0.08)}[tier]
    cols, rows = 50, 3
    cell = int(round(0.6 * w / cols))
    x0, y0 = (w - cols * cell) // 2, int(0.775 * h) - rows * cell // 2
    shadow = Image.new("RGBA", pil.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rectangle([x0 - cell // 2, y0 + cell // 2, x0 + cols * cell + cell // 2, y0 + rows * cell + cell], fill=(10, 12, 30, 170))
    pil = Image.alpha_composite(pil, shadow.filter(ImageFilter.GaussianBlur(cell * 0.5)))
    d = ImageDraw.Draw(pil)
    block_plate(d, x0, y0, cols, rows, cell, TROUGH)
    # the zones: whole bands of the bar's width, under the grout
    for frac, colour in ((good, GREEN), (perfect, GOLD)):
        zw = frac * cols * cell
        zx = x0 + cols * cell / 2 - zw / 2
        d.rectangle([zx, y0, zx + zw, y0 + rows * cell - 1], fill=rgb(colour))
    for j in range(rows):  # redraw the grout over the zones
        d.line([x0, y0 + (j + 1) * cell - 1, x0 + cols * cell, y0 + (j + 1) * cell - 1], fill=(0, 0, 0, 40), width=max(1, cell // 8))
    for i in range(1, cols):
        d.line([x0 + i * cell - 1, y0, x0 + i * cell - 1, y0 + rows * cell], fill=(0, 0, 0, 40), width=max(1, cell // 8))
    # the sweep's light trail: the passed cells (left of the marker) a see-through white, a whole cell at a time
    marker_col = int(cols / 2 + 0.6)
    trail = Image.new("RGBA", pil.size, (0, 0, 0, 0))
    td = ImageDraw.Draw(trail)
    for i in range(1, marker_col):
        if x0 + i * cell + cell < x0 + cols * cell / 2 - good * cols * cell / 2:
            td.rectangle([x0 + i * cell, y0 + cell * 0.25, x0 + (i + 1) * cell - 2, y0 + rows * cell - cell * 0.25], fill=(255, 255, 255, 46))
    pil = Image.alpha_composite(pil, trail)
    d = ImageDraw.Draw(pil)
    # the marker: a stepped pixel arrow on a 7 x 11 grid, its head over the bar and its stem through it, navy ink one pixel round
    px = rows * cell / 6
    mx = x0 + marker_col * cell + cell / 2
    top = y0 - 4.5 * px
    shape = ["0011100", "0111110", "1111111", "0011100", "0011100", "0011100", "0011100", "0011100", "0011100", "0011100", "0011100"]
    cells = {(i, j) for j, row in enumerate(shape) for i, ch in enumerate(row) if ch == "1"}
    inked = {(i + di, j + dj) for i, j in cells for di in (-1, 0, 1) for dj in (-1, 0, 1)}
    for (i, j), colour in [(c, NAVY) for c in inked] + [(c, WHITE) for c in cells]:
        cx, cy = mx + (i - 3.5) * px, top + j * px
        d.rectangle([cx, cy, cx + px - 1, cy + px - 1], fill=rgb(colour))
    # the near-miss flash: a few gold sparkle cells either side of the Perfect band
    rnd = random.Random(9)
    for _ in range(14):
        sx = x0 + cols * cell / 2 + rnd.choice((-1, 1)) * rnd.uniform(perfect * cols * cell * 0.6, good * cols * cell * 0.9)
        sy = y0 + rnd.uniform(-1.6, rows + 0.6) * cell
        s = cell * rnd.choice((0.35, 0.5))
        d.rectangle([sx, sy, sx + s, sy + s], fill=rgb(rnd.choice((GOLD, "FFF1B0", WHITE))))
    return np.asarray(pil.convert("RGB"), dtype=np.float32) / 255.0


def reveal_card(raw_rgba, k, tier="Cosmic"):
    """Thumbnail 6, the Cosmic reveal as the game draws it in block cells (UI Playbook, The reveal in block cells): the pixel sky (8 stepped
    bands from the tier colour down to the night, star cells), the cell-ray fan, a 16-arm pixel starburst in pink and blue, the cream card
    with its tier-pink ink landing with a tilt, the gold cell frame round it (every eighth cell lit), the alien on a gold ground ring of
    square dots, and confetti cells."""
    w, h = int(1920 * k), int(1080 * k)
    cell = max(4, int(round(18 * k)))
    tc = TIER[tier]
    bands = [(i / 7, c) for i, c in enumerate(["EC4899", "C93C9A", "A1359B", "7A2F97", "582A8C", "3D2678", "2A2260", NAVY])]
    img = cell_gradient(w, h, bands, int(h / 8 / cell) * cell or cell)
    img = star_cells(img, cell, 20, 12, 0.02, 0.95, "FFE7F6")
    pil = Image.fromarray((img * 255).astype(np.uint8), "RGB").convert("RGBA")
    cx, cy = w * 0.5, h * 0.44
    # the cell-ray fan: 8 bars through the middle, 6 cells a ray each way with gaps, and the 16-arm starburst of square cells
    fan = Image.new("RGBA", pil.size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(fan)
    big = int(cell * 2.2)
    for a in range(8):
        ang = a * math.pi / 8 + 0.18
        for n in range(1, 7):
            for sgn in (1, -1):
                r = (n + 2.4) * big * 1.55
                x, y = cx + sgn * r * math.cos(ang), cy + sgn * r * math.sin(ang)
                fd.rectangle([x - big / 2, y - big / 2, x + big / 2, y + big / 2], fill=rgb("FFD1EC") + (int(170 - n * 18),))
    for a in range(16):
        ang = a * math.tau / 16
        col = "FF8AD0" if a % 2 == 0 else "8FD3FF"
        for n in range(4, 12):
            r = n * cell * 1.25
            s = cell * (1.0 if n < 11 else 1.4)
            x, y = cx + r * math.cos(ang), cy + r * math.sin(ang)
            fd.rectangle([x - s / 2, y - s / 2, x + s / 2, y + s / 2], fill=rgb(WHITE if n == 11 else col) + (230,))
    pil = Image.alpha_composite(pil, fan)
    # the card: a cream plate, 10 x 13 cells, tier-pink ink, tilted a few degrees as it lands; a soft shadow under it
    ccell = int(round(h * 0.70 / 13))
    cols, rows = 10, 13
    cw, ch = cols * ccell, rows * ccell
    pad = ccell * 2
    card = Image.new("RGBA", (cw + 2 * pad, ch + 2 * pad), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    block_plate(cd, pad, pad, cols, rows, ccell, CREAM, ink=tc)
    # the window: the pixel sky inside the card (the Cosmic's night), then the alien over it
    wx0, wy0, wcols, wrows = pad + ccell, pad + ccell, cols - 2, rows - 5
    inner = cell_gradient(wcols * ccell, wrows * ccell, [(0, "5B2A8E"), (0.6, "2A2260"), (1, "1B1F3B")], max(4, ccell // 3))
    inner = star_cells(inner, max(3, ccell // 4), 18, 5, 0.02, 0.7, "FFE7F6")
    card.paste(Image.fromarray((inner * 255).astype(np.uint8), "RGB"), (wx0, wy0))
    # the gold ground ring: 18 square gold dots on an ellipse under the alien
    gx, gy = wx0 + wcols * ccell / 2, wy0 + wrows * ccell * 0.86
    for n in range(18):
        a = n * math.tau / 18
        x, y = gx + math.cos(a) * wcols * ccell * 0.36, gy + math.sin(a) * ccell * 0.55
        s = ccell * 0.22
        cd.rectangle([x - s, y - s, x + s, y + s], fill=rgb(GOLD))
    alien = raw_rgba.crop(raw_rgba.getbbox())
    scale = min(wcols * ccell * 0.92 / alien.width, wrows * ccell * 0.86 / alien.height)
    alien = alien.resize((int(alien.width * scale), int(alien.height * scale)), Image.LANCZOS)
    a_mask = np.asarray(alien.getchannel("A"), dtype=np.float32) / 255.0
    a_rgb = np.asarray(alien.convert("RGB"), dtype=np.float32) / 255.0
    margin = int(ccell * 0.25)
    padded = np.pad(a_mask, margin)
    ring = np.clip(dilate(padded, ccell * 0.16) - padded, 0, 1)
    base = np.zeros(padded.shape + (4,), dtype=np.float32)
    base[..., :3] = f3(NAVY)
    base[..., 3] = ring
    base[margin:-margin, margin:-margin, :3] = base[margin:-margin, margin:-margin, :3] * (1 - a_mask[..., None]) + a_rgb * a_mask[..., None]
    base[margin:-margin, margin:-margin, 3] = np.maximum(base[margin:-margin, margin:-margin, 3], a_mask)
    alien = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8), "RGBA")
    card.alpha_composite(alien, (int(gx - alien.width / 2), int(gy - alien.height + ccell * 0.35)))
    # the plate under the window: a flat tier-pink block carrying a row of pixel stars (the tier, without words)
    py0 = wy0 + wrows * ccell + ccell // 3
    block_plate(cd, wx0, py0, wcols, 3, ccell, tc, ink=NAVY, grout=False)
    for n in range(5):
        sx, sy, s = wx0 + ccell * (1.4 + n * 1.3), py0 + ccell * 1.5, ccell * 0.42
        cd.polygon([(sx, sy - s * 1.4), (sx + s * 0.45, sy - s * 0.4), (sx + s * 1.4, sy), (sx + s * 0.45, sy + s * 0.4), (sx, sy + s * 1.4),
                    (sx - s * 0.45, sy + s * 0.4), (sx - s * 1.4, sy), (sx - s * 0.45, sy - s * 0.4)], fill=rgb(WHITE), outline=rgb(NAVY))
    # the gold cell frame round the card: cells on its outline, every eighth lit
    per = []
    fc = int(ccell * 0.55)
    for i in range(cols + 2):
        per.append((pad - ccell + i * ccell, pad - ccell))
    for j in range(1, rows + 1):
        per.append((pad + cw, pad - ccell + j * ccell))
    for i in range(cols + 1, -1, -1):
        per.append((pad - ccell + i * ccell, pad + ch))
    for j in range(rows, 0, -1):
        per.append((pad - ccell, pad - ccell + j * ccell))
    for n, (x, y) in enumerate(per):
        x, y = x + (ccell - fc) / 2, y + (ccell - fc) / 2
        cd.rectangle([x - 2, y - 2, x + fc + 2, y + fc + 2], fill=rgb(NAVY))
        cd.rectangle([x, y, x + fc, y + fc], fill=rgb("FFF1B0" if n % 8 == 0 else GOLD))
    card = card.rotate(-5, resample=Image.BICUBIC, expand=True)
    sh = Image.new("RGBA", pil.size, (0, 0, 0, 0))
    ox, oy = int(cx - card.width / 2), int(cy - card.height / 2 + h * 0.04)
    sh.paste((8, 6, 24, 150), (ox + int(ccell * 0.6), oy + int(ccell * 0.9)), card.getchannel("A"))
    pil = Image.alpha_composite(pil, sh.filter(ImageFilter.GaussianBlur(ccell * 0.8)))
    pil.alpha_composite(card, (ox, oy))
    # landing streak cells above the card and confetti cells round it (kept off the card)
    d = ImageDraw.Draw(pil)
    rnd = random.Random(4)
    colours = [TIER["Rare"], TIER["Epic"], TIER["Uncommon"], TIER["Legendary"], TIER["Cosmic"], "8FD3FF"]
    placed = 0
    while placed < 46:
        x, y = rnd.uniform(0.03, 0.97) * w, rnd.uniform(0.04, 0.8) * h
        if ox - ccell < x < ox + card.width + ccell and oy - ccell < y < oy + card.height:
            continue
        s = cell * rnd.choice((0.8, 1.0, 1.3))
        d.rectangle([x - 2, y - 2, x + s + 2, y + s + 2], fill=rgb(NAVY))
        d.rectangle([x, y, x + s, y + s], fill=rgb(colours[placed % len(colours)]))
        placed += 1
    return np.asarray(pil.convert("RGB"), dtype=np.float32) / 255.0


# ------------------------------------------------------------------------------------------------ the scenic set (S1 to S3)
def band_sky(w, h, stops, hz, cell, seed=44):
    """A stepped cell gradient whose stop positions are fractions of the horizon row `hz` (0 the top of the frame, 1 the horizon); below the
    horizon it holds the last colour (the terrain covers it)."""
    stops = [(p * hz, c) for p, c in stops] + [(1.0, stops[-1][1])]
    return cell_gradient(w, h, stops, cell)


def blend_x(a, b, x0, x1, cell):
    """Blend sky `a` into sky `b` across the columns x0..x1 (frame fractions), in whole cell columns (a stepped seam, never smooth)."""
    h, w, _ = a.shape
    cols = np.arange(w) // cell * cell / w
    t = np.clip((cols - x0) / max(1e-6, x1 - x0), 0, 1)
    t = (t * t * (3 - 2 * t))[None, :, None]
    return a * (1 - t) + b * t


def warm_clouds(img, cell, seed, count, top, bottom, lit="FFE9CF", shade="F2B7A8", x0=0.0, x1=1.0):
    """Block clouds lit by a low sun: a warm lit top row, a rosy underside."""
    rnd = random.Random(seed)
    h, w, _ = img.shape
    for _ in range(count):
        cw, ch = rnd.randint(7, 16), rnd.randint(2, 3)
        x0p = rnd.randrange(int(x0 * w), max(int(x0 * w) + 1, int(x1 * w) - cw * cell))
        y0 = rnd.randrange(int(top * h), max(int(top * h) + 1, int(bottom * h)))
        for j in range(ch):
            inset = (ch - 1 - j) * rnd.randint(1, 3)
            for i in range(inset, cw - inset // 2):
                c = f3(lit) if j < ch - 1 else f3(shade)
                y, x = y0 + j * cell, x0p + i * cell
                img[y:y + cell, x:x + cell] = img[y:y + cell, x:x + cell] * 0.15 + c * 0.85
    return img


def scenic_sky(kind, w, h, k, hz, seam=0.52):
    cell = max(4, int(round(12 * k)))
    if kind == "golden":   # the east at golden hour: azure overhead, lavender, then the warm peach band at the horizon
        img = band_sky(w, h, [(0, "2F63CF"), (0.35, "5E8FE6"), (0.62, "9DB3EE"), (0.8, "E3B7CF"), (0.93, "FFC7A3"), (1, "FFDDB2")], hz, cell)
        return warm_clouds(img, cell, 5, 5, 0.05, hz * 0.62)
    if kind == "dusk":     # S2: the meadow's warm sunset on the left, the Starhollow's violet night with stars on the right
        warm = band_sky(w, h, [(0, "3B3C9A"), (0.4, "7B62C2"), (0.7, "E08FB6"), (0.88, "FFB48A"), (1, "FFD49A")], hz, cell)
        warm = warm_clouds(warm, cell, 8, 3, 0.18, hz * 0.7, lit="FFC9A0", shade="C77BA8", x1=0.4)
        night = band_sky(w, h, [(0, "0B0A2E"), (0.45, "251F6B"), (0.8, "4A3593"), (1, "7A4FB8")], hz, cell)
        night = star_cells(night, cell, 110, 11, 0, hz * 0.95, "FFF4DC")
        return blend_x(warm, night, 0.0, 0.55, cell)
    if kind == "dusk_right":   # the same with the sunset on the right (the camera faces away from the west, the meadow on its right)
        night = band_sky(w, h, [(0, "0B0A2E"), (0.45, "251F6B"), (0.8, "4A3593"), (1, "7A4FB8")], hz, cell)
        night = star_cells(night, cell, 110, 11, 0, hz * 0.95, "FFF4DC")
        warm = band_sky(w, h, [(0, "2E2C86"), (0.45, "6A55B8"), (0.72, "D486B4"), (0.9, "FFAE86"), (1, "FFD08E")], hz, cell)
        warm = warm_clouds(warm, cell, 8, 3, 0.2, hz * 0.7, lit="FFC9A0", shade="C77BA8", x0=0.65)
        return blend_x(night, warm, 0.45, 1.0, cell)
    if kind == "twoworld":  # S3: World 1's golden afternoon on the left, Frostbyte's aurora night with its moon on the right
        day = band_sky(w, h, [(0, "2F6BD6"), (0.45, "6EA6EE"), (0.8, "BFD9F4"), (0.93, "FFE0B8"), (1, "FFE9C6")], hz, cell)
        day = warm_clouds(day, cell, 3, 4, 0.04, hz * 0.55, lit="FFFFFF", shade="E9D9EE", x1=0.42)
        night = band_sky(w, h, [(0, "060A24"), (0.5, "10285F"), (0.85, "2C5A9E"), (1, "5C86C4")], hz, cell)
        night = star_cells(night, cell, 120, 21, 0, hz * 0.9)
        night = aurora(night, cell)
        night = moon(night, w * 0.86, h * 0.15, h * 0.055, cell)
        return blend_x(day, night, seam - 0.1, seam + 0.1, cell)
    return sky(kind, w, h, k)


def load_depth(path, size):
    """The depth pass (a 16-bit grey PNG, sRGB-encoded, the sky white) as camera distance over `far`, 0..1."""
    if not path.exists():
        return np.ones((size[1], size[0]), dtype=np.float32)
    im = Image.open(path)
    v = np.asarray(im, dtype=np.float32) / (65535.0 if im.mode.startswith("I") else 255.0)
    if v.ndim == 3:
        v = v[..., 0]
    return np.where(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055) ** 2.4).astype(np.float32)


def grade(img, kind):
    """A gentle finish: a little more saturation and a soft S-curve (saturated, never garish); `warm` lifts the highlights' warmth."""
    lum = (img @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32))[..., None]
    img = np.clip(lum + (img - lum) * 1.12, 0, 1)
    s = img * img * (3 - 2 * img)
    img = img * 0.82 + s * 0.18
    if kind == "warm":
        img = np.clip(img * np.array([1.03, 1.0, 0.95], dtype=np.float32), 0, 1)
    return img


def light_leak(img, colour, cx, cy, radius, strength):
    """A soft low-sun glow from a corner, screened over the frame."""
    h, w, _ = img.shape
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.hypot(xx / w - cx, (yy / h - cy) * h / w) / radius
    a = (np.clip(1 - d, 0, 1) ** 2 * strength)[..., None]
    return 1 - (1 - img) * (1 - f3(colour) * a)


def vignette(img, strength=0.16):
    h, w, _ = img.shape
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.hypot((xx / w - 0.5) * 1.2, yy / h - 0.5)
    a = (np.clip((d - 0.42) / 0.4, 0, 1) ** 1.6 * strength)[..., None]
    return img * (1 - a) + f3("1B1F3B") * a


def compose_scenic(raw_dir, shot, meta):
    """S1 to S3: sky, the render over it, aerial haze from the depth pass, the grade, the auras behind the glowing rares, bloom, the
    outlines per group, the light leak and the vignette. Returns (with title, without)."""
    raw = Image.open(raw_dir / f"{shot}_raw.png").convert("RGBA")
    w, h = raw.size
    k = h / 1080
    alpha = np.asarray(raw.getchannel("A"), dtype=np.float32)[..., None] / 255.0
    col = np.asarray(raw.convert("RGB"), dtype=np.float32) / 255.0
    hz = float(np.clip(meta["points"].get("horizon", [0.5, 0.45])[1], 0.15, 0.95))
    sk = scenic_sky(meta["sky"], w, h, k, hz, float(meta["points"].get("seam_far", [0.52, 0])[0]))
    img = sk * (1 - alpha) + col * alpha
    if meta.get("haze"):
        amount, near = meta["haze"]
        depth = load_depth(raw_dir / f"{shot}_depth.png", (w, h))
        far = meta["far"]
        t = np.clip((depth * far - near) / max(1.0, far - near), 0, 1) ** 1.25 * amount
        row = sk[max(0, int(hz * h) - int(24 * k))][None, :, :]   # each column hazes towards its own sky just over the horizon
        img = img * (1 - t[..., None]) + row * t[..., None]
    img = grade(img, meta.get("grade"))
    masks = {g: load_mask(raw_dir / f"{shot}_{g.lower()}.png", (w, h)) for g in meta["groups"]}
    for g, spec in meta["groups"].items():
        if spec.get("aura") and masks[g].any():
            img = aura(img, masks[g], spec["aura"], spec.get("aura_r", 26) * k, spec.get("aura_a", 0.6))
    if meta.get("bloom"):
        img = bloom(img, meta["bloom"], k)
    for g, spec in meta["groups"].items():
        if masks[g].any():
            img = outline(img, masks[g], spec["outline"] * k)
    if meta.get("leak"):
        colour, cx, cy, radius, strength = meta["leak"]
        img = light_leak(img, colour, cx, cy, radius, strength)
    img = vignette(img)
    plain = img
    align = meta.get("title") or "center"
    titled = title(img, TITLE, k, align, 0.5 if align != "center" else 0.6)
    return titled, plain


# ------------------------------------------------------------------------------------------------ the shots
def compose(raw_dir, shot):
    meta = json.loads((raw_dir / f"{shot}.json").read_text())
    raw = Image.open(raw_dir / f"{shot}_raw.png").convert("RGBA")
    rgb_im = Image.merge("RGB", raw.split()[:3]).filter(ImageFilter.MedianFilter(3))
    raw = Image.merge("RGBA", (*rgb_im.split(), raw.getchannel("A")))
    w, h = raw.size
    icon = shot.startswith("icon")
    k = h / (1024 if icon else 1080)
    if meta.get("card"):
        return reveal_card(raw, w / 1200, meta["card"])  # the card's alien is rendered 1200 px square at full size
    alpha = np.asarray(raw.getchannel("A"), dtype=np.float32)[..., None] / 255.0
    col = np.asarray(raw.convert("RGB"), dtype=np.float32) / 255.0
    img = sky(meta.get("sky", "day"), w, h, k) * (1 - alpha) + col * alpha
    hero = load_mask(raw_dir / f"{shot}_hero.png", (w, h))
    cast = load_mask(raw_dir / f"{shot}_cast.png", (w, h))
    if meta.get("aura"):
        img = aura(img, hero, meta["aura"], (40 if icon else 34) * k, 0.8 if icon else 0.65)
    if meta.get("bloom"):
        img = bloom(img, meta["bloom"], k)
    if cast.any():
        img = outline(img, cast, 5 * k)
    if hero.any():
        img = outline(img, hero, (21 if icon else 14) * k)
    if meta.get("bar"):
        img = capture_bar(img, k, meta["bar"])
    if meta.get("title"):
        align = meta["title"] if isinstance(meta["title"], str) else "center"
        img = title(img, TITLE, k, align, 0.5 if align == "left" else 0.62)
    return img


def save_png(img, path, size=None):
    pil = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")
    if size and pil.size != size:
        pil = pil.resize(size, Image.LANCZOS)
    pil.save(path, optimize=True)
    if os.path.getsize(path) > MAX_BYTES:
        pil.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG).save(path, optimize=True)
    print(f"{path}: {pil.size[0]}x{pil.size[1]}, {os.path.getsize(path) / 1e6:.2f} MB")
    return pil


LABELS = {"icon_A": ("A", "Moop close-up, meadow, ship behind"), "icon_B": ("B", "Raddis (Cosmic) glowing at night"),
          "icon_C": ("C", "Moop, Aurelyx, Vixa: rising rarity"), "thumb_1": ("1", "The camp: half-built ship, a Rare's portal"),
          "thumb_2": ("2", "The catch: the bar on a Legendary"), "thumb_3": ("3", "Starhollow Forest at night"),
          "thumb_4": ("4", "World 2 Frostbyte: Fenrir, moon, aurora"), "thumb_5": ("5", "The rarity ladder, Common to Secret"),
          "thumb_6": ("6", "The reveal: a Cosmic card")}


def badge(d, x, y, text, size):
    font = ImageFont.truetype(FONT, size)
    stroke = max(3, size // 9)
    d.text((x, y), text, font=font, fill=rgb("FFEF4A"), stroke_width=stroke, stroke_fill=rgb(NAVY))


def sheet(out_dir, finals):
    """choices.jpg: icons A to C at 384 px with their 64 px twins, the six thumbnails at 640 x 360, each with its big letter or number."""
    W, gap = 2040, 30
    H = 120 + 470 + 2 * (360 + 90) + 40
    canvas = Image.new("RGB", (W, H), rgb("F3EEDF"))
    d = ImageDraw.Draw(canvas)
    d.text((gap, 26), "Catch an Alien: store art choices (2026-10-22)", font=ImageFont.truetype(FONT, 46), fill=rgb(NAVY))
    d.text((gap, 82), "Pick one icon (A, B or C) and the thumbnails in order, e.g. \"icon B, thumbs 3, 1, 5\". Icons show at 512 and at 64 px.",
           font=ImageFont.truetype(FONT, 24), fill=rgb("4A4F6B"))
    small = ImageFont.truetype(FONT, 22)
    x = gap
    for key in ("icon_A", "icon_B", "icon_C"):
        if key not in finals:
            continue
        im = finals[key]
        canvas.paste(im.resize((384, 384), Image.LANCZOS), (x, 130))
        canvas.paste(im.resize((64, 64), Image.LANCZOS), (x + 384 + 14, 130 + 384 - 64))
        badge(d, x + 12, 130, LABELS[key][0], 92)
        d.text((x, 130 + 392), LABELS[key][1], font=small, fill=rgb(NAVY))
        x += 384 + 14 + 64 + 2 * gap
    for n in range(6):
        key = f"thumb_{n + 1}"
        if key not in finals:
            continue
        cx, cy = gap + (n % 3) * (640 + gap), 600 + (n // 3) * (360 + 90)
        canvas.paste(finals[key].resize((640, 360), Image.LANCZOS), (cx, cy))
        badge(d, cx + 10, cy + 360 - 104, LABELS[key][0], 92)
        d.text((cx, cy + 366), LABELS[key][1], font=small, fill=rgb(NAVY))
    path = out_dir / "choices.jpg"
    canvas.save(path, quality=88, optimize=True)
    print(f"{path}: {W}x{H}, {os.path.getsize(path) / 1e6:.2f} MB")


SCENIC = {"thumb_S1": ("S1", "The meadow vista from the highlands, golden hour"),
          "thumb_S2": ("S2", "The Starhollow at dusk, the meadow glowing behind"),
          "thumb_S3": ("S3", "Two worlds: the meadow and Frostbyte, one panorama")}


def scenic_strip(out_dir, finals):
    """scenic_400_strip.png: S1 to S3 at 400 px wide (their size in a phone's game list), titled, side by side."""
    keys = [k for k in SCENIC if k in finals]
    strip = Image.new("RGB", (len(keys) * 400 + (len(keys) - 1) * 10, 225), rgb(NAVY))
    for i, key in enumerate(keys):
        strip.paste(finals[key].resize((400, 225), Image.LANCZOS), (i * 410, 0))
    strip.save(out_dir / "scenic_400_strip.png", optimize=True)
    print(out_dir / "scenic_400_strip.png")
    return strip


def scenic_sheet(out_dir, finals, icon):
    """scenic_choices.jpg: S1, S2 and S3 side by side with their big labels, each again at 400 px under it, and icon A (Ethan's pick)."""
    W, gap, tw, th = 2040, 30, 640, 360
    H = 130 + th + 70 + 225 + 60 + 300 + 40
    canvas = Image.new("RGB", (W, H), rgb("F3EEDF"))
    d = ImageDraw.Draw(canvas)
    d.text((gap, 26), "Catch an Alien: scenic thumbnails (2026-10-22)", font=ImageFont.truetype(FONT, 46), fill=rgb(NAVY))
    d.text((gap, 82), "Pick the first thumbnail: answer \"S1\", \"S2\" or \"S3\". Under each, the same at 400 px, as a phone's game list shows it.",
           font=ImageFont.truetype(FONT, 24), fill=rgb("4A4F6B"))
    small = ImageFont.truetype(FONT, 22)
    for n, key in enumerate(SCENIC):
        if key not in finals:
            continue
        x = gap + n * (tw + gap)
        canvas.paste(finals[key].resize((tw, th), Image.LANCZOS), (x, 130))
        badge(d, x + 10, 130 + th - 104, SCENIC[key][0], 92)
        d.text((x, 130 + th + 8), SCENIC[key][1], font=small, fill=rgb(NAVY))
        canvas.paste(finals[key].resize((400, 225), Image.LANCZOS), (x, 130 + th + 50))
    y = 130 + th + 50 + 225 + 40
    if icon is not None:
        canvas.paste(icon.resize((300, 300), Image.LANCZOS), (gap, y))
        canvas.paste(icon.resize((64, 64), Image.LANCZOS), (gap + 314, y + 236))
        badge(d, gap + 10, y, "A", 80)
        d.text((gap + 400, y + 110), "Icon A, Ethan's pick (2026-10-22): Moop close-up on the meadow, the crashed ship behind.",
               font=ImageFont.truetype(FONT, 26), fill=rgb(NAVY))
        d.text((gap + 400, y + 150), "Thumbnails 2 and 3 of the store: thumb 2 (the catch) and thumb 1 (the camp) from the first set.",
               font=small, fill=rgb("4A4F6B"))
    path = out_dir / "scenic_choices.jpg"
    canvas.save(path, quality=88, optimize=True)
    print(f"{path}: {W}x{H}, {os.path.getsize(path) / 1e6:.2f} MB")


def main():
    raw_dir, out_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    if "assets" in out_dir.resolve().parts:
        print("refusing to write under assets/")
        return 2
    out_dir.mkdir(parents=True, exist_ok=True)
    finals, fresh = {}, set()
    for shot in list(LABELS) + list(SCENIC):
        if not (raw_dir / f"{shot}.json").exists():
            if (out_dir / f"{shot}.png").exists():
                finals[shot] = Image.open(out_dir / f"{shot}.png").convert("RGB")
            continue
        print("compose", shot, flush=True)
        fresh.add(shot)
        meta = json.loads((raw_dir / f"{shot}.json").read_text())
        if meta.get("scenic"):
            titled, plain = compose_scenic(raw_dir, shot, meta)
            save_png(plain, out_dir / f"{shot}_notitle.png", (1920, 1080))
            finals[shot] = save_png(titled, out_dir / f"{shot}.png", (1920, 1080))
            continue
        img = compose(raw_dir, shot)
        finals[shot] = save_png(img, out_dir / f"{shot}.png", (512, 512) if shot.startswith("icon") else (1920, 1080))
    icons = [finals[k] for k in ("icon_A", "icon_B", "icon_C") if k in finals]
    if icons and fresh & {"icon_A", "icon_B", "icon_C"}:
        strip = Image.new("RGB", (len(icons) * 64 + (len(icons) - 1) * 8, 64), rgb(NAVY))
        for i, im in enumerate(icons):
            strip.paste(im.resize((64, 64), Image.LANCZOS), (i * 72, 0))
        strip.save(out_dir / "icons_64_strip.png", optimize=True)
        print(out_dir / "icons_64_strip.png")
    if fresh & set(LABELS):   # the first set's sheet is rewritten only when one of its options was re-rendered
        sheet(out_dir, finals)
    if fresh & set(SCENIC) or "icon_A" in fresh:
        scenic_strip(out_dir, finals)
        scenic_sheet(out_dir, finals, finals.get("icon_A"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
