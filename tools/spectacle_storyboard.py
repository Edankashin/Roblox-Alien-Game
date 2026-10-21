#!/usr/bin/env python3
"""Draw the spectacle storyboard: one row per tier, a frame strip for the arrival, the presence and the catch.

Reads src/shared/data/Spectacle.luau (the arrival kinds, beacons, pools, ornaments, footprints, bubbles, flashes, spirals,
shockwaves, slow-mo and escapes), data/Effects (each example species' accent) and data/Tiers (the tier colours), so the sheet
shows what World.Spectacle draws. A 2D diagram, side on, in block cells (B44); every alien at one height (B45).

    python3 -I tools/spectacle_storyboard.py media/studio/2026-10-21/spectacle_v1.png
"""
from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lint_data  # noqa: E402

ROOT = lint_data.ROOT
EXAMPLES = {'Common': 'Mossbop', 'Uncommon': 'Lanternewt', 'Rare': 'Wisplet', 'Epic': 'Shimmerlynx', 'Legendary': 'Gaiabloom',
            'Cosmic': 'Radish', 'Secret': 'Panpipe'}
FW, FH = 190, 170  # one frame
LABEL_W = 170
HEAD_H = 110
GAP = 14  # between the three sections
SKY = (98, 179, 236)
SKY_NIGHT = (30, 34, 70)
GROUND = (111, 191, 74)
DIRT = (138, 90, 59)
INK = (27, 31, 59)
WHITE = (255, 255, 255)
FONT = ROOT / 'assets/fonts/FredokaOne.ttf'
SECTIONS = (('Arrival', 4), ('Presence', 2), ('Catch', 4))


def rgb(value: str) -> "tuple[int, int, int]":
    number = int(value, 16)
    return (number >> 16) & 255, (number >> 8) & 255, number & 255


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def font(size: int):
    try:
        return ImageFont.truetype(str(FONT), size)
    except OSError:
        return ImageFont.load_default()


class Frame:
    """One frame: a sky, a ground strip, and helpers in frame coordinates (feet of the alien at (cx, ground))."""

    def __init__(self, sheet: Image.Image, x0: int, y0: int, night: bool = False, dim: float = 0.0):
        self.sheet = sheet
        self.x0, self.y0 = x0, y0
        self.layer = Image.new('RGBA', (FW, FH), (0, 0, 0, 0))
        self.glow = Image.new('RGBA', (FW, FH), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.layer)
        self.g = ImageDraw.Draw(self.glow)
        sky = SKY_NIGHT if night else SKY
        if dim:
            sky = lerp(sky, (10, 6, 30), dim)
        self.d.rectangle((0, 0, FW, FH), fill=sky)
        self.ground = FH - 34
        self.d.rectangle((0, self.ground, FW, FH), fill=GROUND)
        self.d.rectangle((0, self.ground + 8, FW, FH), fill=DIRT)
        for x in range(0, FW, 16):  # tile seams: the meadow in cells
            self.d.line((x, self.ground, x, FH), fill=lerp(DIRT, INK, 0.25))
        self.cx = FW // 2

    def cell(self, x, y, side, color, alpha=255, glow=False):
        box = (x - side / 2, y - side / 2, x + side / 2, y + side / 2)
        self.d.rectangle(box, fill=tuple(color) + (alpha,), outline=lerp(color, INK, 0.35) + (alpha,))
        if glow:
            self.g.rectangle((box[0] - 3, box[1] - 3, box[2] + 3, box[3] + 3), fill=tuple(color) + (min(alpha, 150),))

    def alien(self, x, feet, color, scale=1.0, alpha=255, turn=0.0, tilt=0.0, sleeping=False):
        """A block alien: a body block, a head block, a face plate with two eyes, little feet; `turn` slides the face."""
        w, h = 34 * scale, 22 * scale
        hw, hh = 30 * scale, 24 * scale
        body = (x - w / 2, feet - h, x + w / 2, feet)
        head = (x - hw / 2 + tilt, feet - h - hh, x + hw / 2 + tilt, feet - h)
        dark = lerp(color, INK, 0.35)
        self.d.rectangle(body, fill=tuple(color) + (alpha,), outline=dark + (alpha,), width=2)
        self.d.rectangle(head, fill=tuple(lerp(color, WHITE, 0.15)) + (alpha,), outline=dark + (alpha,), width=2)
        for fx in (-w / 3, w / 3):
            self.d.rectangle((x + fx - 4 * scale, feet - 3 * scale, x + fx + 4 * scale, feet), fill=dark + (alpha,))
        ex = x + tilt + turn * 6 * scale
        eye_y = feet - h - hh * 0.55
        for side in (-1, 1):
            ex2 = ex + side * 6 * scale
            if sleeping:
                self.d.line((ex2 - 3 * scale, eye_y, ex2 + 3 * scale, eye_y), fill=INK + (alpha,), width=max(1, int(2 * scale)))
            else:
                self.d.rectangle((ex2 - 2.5 * scale, eye_y - 4 * scale, ex2 + 2.5 * scale, eye_y + 3 * scale), fill=INK + (alpha,))
                self.d.rectangle((ex2 - 1.5 * scale, eye_y - 3 * scale, ex2, eye_y - 1.5 * scale), fill=WHITE + (alpha,))
        return feet - h - hh

    def player(self, x):
        """The 5-stud avatar, half out of frame, for scale and as the one who is noticed."""
        top = self.ground - 76
        self.d.rectangle((x - 9, top, x + 9, top + 18), fill=(255, 214, 170), outline=INK, width=2)
        self.d.rectangle((x - 12, top + 18, x + 12, top + 50), fill=(70, 120, 220), outline=INK, width=2)
        self.d.rectangle((x - 11, top + 50, x + 11, self.ground), fill=(60, 60, 80), outline=INK, width=2)
        return top

    def glyph(self, rows, x, y, cell, ink, plate=True):
        width, height = len(rows[1]), len(rows)
        side = max(width, height) + 2
        size = side * cell
        x0, y0 = x - size / 2, y - size / 2
        if plate:
            self.d.rectangle((x0, y0, x0 + size, y0 + size), fill=WHITE, outline=INK, width=2)
        ox = x0 + (side - width) / 2 * cell
        oy = y0 + (side - height) / 2 * cell
        for r in range(1, height + 1):
            for c, ch in enumerate(rows[r]):
                if ch == 'X':
                    self.d.rectangle((ox + c * cell, oy + (r - 1) * cell, ox + (c + 1) * cell - 1, oy + r * cell - 1), fill=ink)

    def column(self, x, top, bottom, width, color, alpha):
        self.g.rectangle((x - width, top, x + width, bottom), fill=tuple(color) + (alpha,))
        self.d.rectangle((x - width / 3, top, x + width / 3, bottom), fill=tuple(lerp(color, WHITE, 0.6)) + (alpha,))

    def pool(self, x, y, radius, color, alpha=120):
        r = radius
        for box in ((x - r, y - 0.3 * r, x + r, y + 0.3 * r), (x - 0.6 * r, y - 0.5 * r, x + 0.6 * r, y + 0.5 * r)):
            self.g.rectangle(box, fill=tuple(color) + (alpha,))

    def ring(self, x, y, radius, count, color, side=6, alpha=255):
        for i in range(count):
            a = 2 * math.pi * i / count
            self.cell(x + math.cos(a) * radius, y + math.sin(a) * radius * 0.3, side, color, alpha, glow=True)

    def caption(self, text):
        self.d.text((6, 4), text, font=font(13), fill=WHITE, stroke_width=2, stroke_fill=INK)

    def paste(self):
        blurred = self.glow.filter(ImageFilter.GaussianBlur(5))
        frame = Image.alpha_composite(self.layer, blurred)
        frame = Image.alpha_composite(frame, self.glow)
        self.sheet.alpha_composite(frame, (self.x0, self.y0))
        ImageDraw.Draw(self.sheet).rectangle((self.x0, self.y0, self.x0 + FW - 1, self.y0 + FH - 1), outline=INK, width=2)


def arrival_frames(sheet, x, y, tier, row, accent, tier_color, glyphs, rng):
    kind = row['kind']
    beacon = row['beacon']
    for i, k in enumerate((0.2, 0.45, 0.7, 1.0)):
        f = Frame(sheet, x + i * FW, y, dim=(0.45 if kind == 'Beam' and k < 1 else 0.0))
        g = f.ground
        if kind == 'None':
            # no arrival: the notice instead (wander, the player comes, "!" and a hop, turned to the player)
            if i >= 1:
                f.player(FW - 22)
            hop = 10 if i == 2 else 0
            top = f.alien(f.cx - (8 if i == 0 else 0), g - hop, accent, turn=(1 if i >= 2 else 0))
            if i == 2:
                f.glyph(glyphs['Alert'], f.cx, top - 22, 3, rgb('FFD43B'))
            f.caption(('wanders', 'a player comes', '"!" and a hop', 'turns to watch')[i])
        elif kind == 'Pop':
            side = 70 * (min(k / 0.4, 1) if k <= 0.4 else max(0, 1 - (k - 0.4) / 0.6))
            body = g - 24
            if side > 2:
                for j in range(12):
                    t = j / 12 * 4
                    e = int(t)
                    a = (t - e) * 2 - 1
                    px, py = ((a, -1), (1, a), (-a, 1), (-1, -a))[e]
                    f.cell(f.cx + px * side / 2, body + py * side / 2, 7, tier_color, glow=True)
            if k >= 0.4:
                f.alien(f.cx, g, accent)
            f.caption(('portal opens', 'it pops through', 'portal closes', 'there')[i])
        elif kind == 'Burst':
            body = g - 24
            if k < 0.25:
                for j in range(16):
                    a = rng.random() * 6.28
                    f.cell(f.cx + math.cos(a) * 40, body + math.sin(a) * 30, 6, tier_color, 160, glow=True)
            else:
                f.alien(f.cx, g, accent)
                s = min((k - 0.25) / 0.75, 1)
                if s < 1:
                    f.g.ellipse((f.cx - 60, body - 50, f.cx + 60, body + 50), fill=tier_color + (int(140 * (1 - s)),))
                    for j in range(16):
                        a = j / 16 * 6.28
                        r = 20 + 60 * s
                        f.cell(f.cx + math.cos(a) * r, body + math.sin(a) * r * 0.8 + 30 * s * s, 6, tier_color, int(255 * (1 - s)), glow=True)
            if beacon != 0 and k >= 1:
                f.column(f.cx, 0, g - 50, 5, tier_color, 120)
            f.caption(('cells gather', 'burst + light', 'cells fall', 'beacon 20 s')[i])
        elif kind == 'Star':
            if k < 0.45:
                s = k / 0.45
                sx, sy = f.cx + 70 * (1 - s), g - 150 * (1 - s * s)
                for t in range(8):
                    f.g.rectangle((sx + t * 5 - 3, sy - t * 9 - 3, sx + t * 5 + 3, sy - t * 9 + 3), fill=tier_color + (200 - t * 22,))
                f.cell(sx, sy, 12, lerp(tier_color, WHITE, 0.5), glow=True)
            else:
                f.alien(f.cx, g, accent)
                s = (k - 0.45) / 0.55
                if s < 1:
                    f.ring(f.cx, g - 2, 20 + 60 * s, 20, tier_color, alpha=int(255 * (1 - s * 0.7)))
                    f.g.ellipse((f.cx - 50, g - 70, f.cx + 50, g + 10), fill=tier_color + (int(120 * (1 - s)),))
                else:
                    f.column(f.cx, 0, g - 50, 6, tier_color, 120)
            f.caption(('a star falls', 'it lands', 'ring blooms', 'beacon stays')[i])
        elif kind == 'Beam':
            beam = k < 1
            if beam:
                f.g.rectangle((f.cx - 26, 0, f.cx + 26, g), fill=tier_color + (110,))
                f.d.rectangle((f.cx - 8, 0, f.cx + 8, g), fill=lerp(tier_color, WHITE, 0.6) + (150,))
            lift = 0 if k >= 0.8 else 90 * (1 - min(1, (k - 0.15) / 0.65))
            f.alien(f.cx, g - lift, accent)
            if k >= 0.7:
                s = min(1, (k - 0.7) / 0.3)
                f.ring(f.cx, g - 2, 30 + 50 * s, 24, tier_color, alpha=int(255 * (1 - 0.6 * s)))
            if not beam:
                f.column(f.cx, 0, g - 50, 7, tier_color, 130)
            f.caption(('sky dims, beam', 'it descends', 'shockwave', 'beacon stays')[i])
        elif kind == 'Glitch':
            vignette = (0.6, 0.2, 0.7, 0)[i]
            body = g - 24
            s = min(k / 0.8, 1)
            if k < 0.8:
                for j in range(24):
                    a, r = rng.random() * 6.28, rng.random()
                    tx, ty = f.cx + (r - 0.5) * 28, body + (rng.random() - 0.5) * 40
                    fx, fy = f.cx + math.cos(a) * 70, body + math.sin(a) * 50
                    step = math.floor(s * 12) / 12
                    f.cell(fx + (tx - fx) * step, fy + (ty - fy) * step, 6, tier_color, glow=True)
            else:
                f.alien(f.cx, g, accent)
            if k >= 1:
                f.column(f.cx, 0, g - 50, 5, tier_color, 120)
            if vignette:
                edge = Image.new('RGBA', (FW, FH), (0, 0, 0, 0))
                ed = ImageDraw.Draw(edge)
                for d in range(18):
                    alpha = int(220 * vignette * (1 - d / 18))
                    ed.rectangle((d, d, FW - 1 - d, FH - 1 - d), outline=rgb('1A0B33') + (alpha,))
                f.layer = Image.alpha_composite(f.layer, edge)
                f.d = ImageDraw.Draw(f.layer)
            f.caption(('edge flickers', 'cells drawn in', 'assembling', 'there, beacon')[i])
        f.paste()


def presence_frames(sheet, x, y, tier, row, pers, accent, tier_color, glyphs, world_colors, arrival):
    # frame 1: wandering, wearing its presence; frame 2: noticing the player (a heart: a species they have caught), or asleep
    for i in range(2):
        night = i == 1 and tier in ('Common', 'Uncommon')
        f = Frame(sheet, x + i * FW, y, night=night)
        g = f.ground
        if arrival['beacon'] == -1:
            f.column(f.cx, 0, g - 50, 5, tier_color, 90)
        if row['pool'] > 0:
            f.pool(f.cx, g + 2, 46 * row['pool'] / 0.9, accent, 140)
        if row['footprints'] and i == 0:
            for j in range(4):
                c = rgb(world_colors[(j % len(world_colors)) + 1])
                f.cell(f.cx - 30 - j * 16, g + 4 + (j % 2) * 4, 6 + (1 if j < 2 else 0), c, alpha=255 - j * 45, glow=True)
        if row['trail'] > 0 and i == 0:
            for j in range(10):
                f.cell(f.cx - 22 - j * 7, g - 8 - (j % 3) * 5, 4, lerp(accent, WHITE, 0.4), alpha=230 - j * 20, glow=True)
        if row['aura'] > 0:
            f.g.ellipse((f.cx - 34, g - 62, f.cx + 34, g + 4), fill=accent + (70,))
        if row['shimmer'] == 'StarField':
            for j in range(12):
                f.cell(f.cx + (j * 37 % 70) - 35, g - 6 - (j * 23 % 60), 3, WHITE, glow=True)
        elif row['shimmer'] == 'Haze':
            for j in range(8):
                f.g.rectangle((f.cx - 30 + j * 8, g - 70 + (j % 3) * 10, f.cx - 24 + j * 8, g - 40 + (j % 3) * 10), fill=rgb('2A1F3D') + (110,))
        if night:
            top = f.alien(f.cx, g, accent, sleeping=True, tilt=4)
            f.glyph(glyphs['Z'], f.cx + 20, top - 10, 2, rgb('DDE6FF'), plate=False)
            f.glyph(glyphs['Z'], f.cx + 32, top - 30, 3, rgb('DDE6FF'), plate=False)
            f.caption('asleep at night: Zz')
        else:
            if i == 1:
                f.player(FW - 22)
            top = f.alien(f.cx - (10 if i == 0 else 0), g - (8 if i == 1 else 0), accent, turn=(1 if i == 1 else -1))
            n = row['ornaments']
            for j in range(n):
                a = 2 * math.pi * j / max(n, 1) + 0.6
                f.cell(f.cx - (10 if i == 0 else 0) + math.cos(a) * 26, top - 6 + math.sin(a) * 6, 7, lerp(accent, WHITE, 0.35), glow=True)
            if i == 1:
                f.glyph(glyphs['Heart'], f.cx, top - 26, 3, rgb('FF5C8A'))
            labels = []
            if row['pool'] > 0:
                labels.append('pool')
            if n:
                labels.append(f'{n} glyph')
            if row['footprints']:
                labels.append('prints')
            if row['trail'] > 0:
                labels.append('trail')
            f.caption((', '.join(labels)) if i == 0 and labels else ('wanders, plays' if i == 0 else
                      ('heart + flourish' if pers['approachFlourish'] else 'heart: known species')))
        f.paste()


def catch_frames(sheet, x, y, tier, row, accent, tier_color):
    for i in range(4):
        f = Frame(sheet, x + i * FW, y, dim=(0.25 if i == 2 and row['slowmo'] > 0 else 0.0))
        g = f.ground
        if i == 0:
            # the bar: its Good band flashing in the alien's colour, the Perfect band brighter
            bx0, bx1, by = 20, FW - 20, 70
            f.d.rectangle((bx0, by, bx1, by + 22), fill=(40, 44, 70), outline=INK, width=2)
            f.d.rectangle((70, by + 3, 120, by + 19), fill=accent)
            f.d.rectangle((88, by + 3, 102, by + 19), fill=lerp(accent, WHITE, 0.4))
            f.d.polygon(((95, by - 12), (101, by - 4), (89, by - 4)), fill=WHITE, outline=INK)
            for j in range(row['flashes'] + 1):
                f.cell(30 + j * 14, by + 40, 8, accent, glow=True)
            f.caption(f"hit flashes x{row['flashes']} (+1 Perfect)")
        elif i in (1, 2):
            # the spiral into the device (the player's hand at the right)
            hand = (FW - 24, g - 50)
            f.player(FW - 22)
            s = 0.35 if i == 1 else 0.8
            start = (f.cx - 30, g - 22)
            for t in range(24):
                u = t / 24 * s
                a = 2 * math.pi * row['turns'] * u
                r = 22 * (1 - u)
                px = start[0] + (hand[0] - start[0]) * u + math.cos(a) * r
                py = start[1] + (hand[1] - start[1]) * u - 18 * math.sin(math.pi * u) + math.sin(a) * r * 0.4
                f.cell(px, py, 3, lerp(accent, WHITE, 0.5), 140, glow=True)
            u = s
            px = start[0] + (hand[0] - start[0]) * u
            py = start[1] + (hand[1] - start[1]) * u - 18 * math.sin(math.pi * u)
            f.alien(px, py + 20 * (1 - u * u), accent, scale=1 - 0.9 * u * u)
            if i == 1:
                for j in range(min(row['cells'], 20)):
                    a = j / 20 * 6.28
                    f.cell(start[0] + math.cos(a) * 34, start[1] + math.sin(a) * 26, 4, accent, glow=True)
                if row['shockwave']:
                    f.ring(start[0], g - 2, 50, min(row['shockwave'], 20), accent, side=5)
                if row['nudge']:
                    for d in (-1, 1):
                        f.d.line((6 if d < 0 else FW - 6, 30, 6 if d < 0 else FW - 6, 60), fill=WHITE, width=3)
            if i == 2 and row['slowmo']:
                for j in range(5):
                    f.d.line((px - 40, py - 30 + j * 10, px - 12, py - 30 + j * 10), fill=WHITE + (160,), width=2)
            cap = 'cell burst, spiral' if i == 1 else 'into the device'
            if i == 1 and row['shockwave']:
                cap = 'burst, shockwave, nudge'
            if i == 2 and row['slowmo']:
                cap = 'slow-mo into device'
            f.caption(cap)
        else:
            # the escape: a puff and hops away, or a Secret blinking out
            if row['escape'] == 'BlinkOut':
                f.alien(f.cx - 20, g, accent, alpha=110)
                f.alien(f.cx + 6, g, accent, alpha=40)
                for j in range(8):
                    f.cell(f.cx - 20 + (j * 13 % 40) - 20, g - 10 - (j * 7 % 40), 5, rgb('2A1F3D'))
                f.caption('fled: blinks out')
            else:
                for j in range(6):
                    f.g.ellipse((20 + j * 6, g - 18 - j * 2, 44 + j * 6, g - 4), fill=(255, 255, 255, 150))
                hops = row['escapeHops']
                for j in range(hops):
                    hx = 60 + j * 38
                    f.d.arc((hx - 18, g - 50, hx + 18, g - 10), 180, 360, fill=WHITE, width=2)
                f.alien(60 + hops * 38 - 10, g - 14, accent, scale=0.8)
                f.caption(f'fled: puff, {hops} hops')
        f.paste()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    reader = lint_data.TableReader()
    spectacle = reader.read(ROOT / 'src/shared/data/Spectacle.luau')
    effects = reader.read(ROOT / 'src/shared/data/Effects.luau')
    tiers = reader.read(ROOT / 'src/shared/data/Tiers.luau')
    order = list(tiers['Order'].values())
    glyphs = spectacle['Glyphs']
    frames = sum(n for _, n in SECTIONS)
    width = LABEL_W + frames * FW + GAP * (len(SECTIONS) - 1) + 10
    height = HEAD_H + len(order) * (FH + 10) + 10
    sheet = Image.new('RGBA', (width, height), (20, 22, 40, 255))
    head = ImageDraw.Draw(sheet)
    head.text((16, 12), 'Spectacle v1: how each tier arrives, carries itself and is caught (B46: rarer is cooler, never bigger)',
              font=font(26), fill=WHITE, stroke_width=2, stroke_fill=INK)
    head.text((16, 48), 'Drawn from src/shared/data/Spectacle.luau, Effects.luau and Tiers.luau; side-on diagram, every alien one height (B45); '
              'the server decides every outcome, the client only dresses it. Reduced Motion: still versions.',
              font=font(14), fill=(190, 196, 220))
    x = LABEL_W
    for name, n in SECTIONS:
        head.text((x + 6, HEAD_H - 28), name, font=font(20), fill=WHITE, stroke_width=2, stroke_fill=INK)
        x += n * FW + GAP
    rng = random.Random(46)
    for index, tier in enumerate(order):
        y = HEAD_H + index * (FH + 10)
        sid = EXAMPLES[tier]
        fx = effects['Species'][sid]
        accent = rgb(fx.get('accent') or fx['layers'][1]['color'])
        tier_color = accent if tier == 'Secret' else rgb(tiers['Tiers'][tier]['color'])
        head.rectangle((8, y, LABEL_W - 10, y + FH), fill=tier_color if tier != 'Secret' else (17, 17, 17), outline=INK, width=3)
        head.text((18, y + 14), tier, font=font(24), fill=WHITE, stroke_width=3, stroke_fill=INK)
        head.text((18, y + 50), sid, font=font(16), fill=WHITE, stroke_width=2, stroke_fill=INK)
        arrival = spectacle['Arrivals'][tier]
        lines = [f"arrival: {arrival['kind']}", f"beacon: {'stays' if arrival['beacon'] == -1 else (str(arrival['beacon']) + ' s' if arrival['beacon'] else 'none')}",
                 f"notice {spectacle['Personality'][tier]['notice']} studs"]
        for j, line in enumerate(lines):
            head.text((18, y + 84 + j * 22), line, font=font(14), fill=WHITE, stroke_width=2, stroke_fill=INK)
        x = LABEL_W
        arrival_frames(sheet, x, y, tier, arrival, accent, tier_color, glyphs, rng)
        x += 4 * FW + GAP
        world_colors = spectacle['Footprints'][1 if index % 2 == 0 else 2]
        presence_frames(sheet, x, y, tier, spectacle['Presence'][tier], spectacle['Personality'][tier], accent, tier_color, glyphs,
                        world_colors, arrival)
        x += 2 * FW + GAP
        catch_frames(sheet, x, y, tier, spectacle['Catch'][tier], accent, tier_color)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert('RGB').save(args.out)
    print(f'wrote {args.out} ({width} x {height})')


if __name__ == '__main__':
    main()
