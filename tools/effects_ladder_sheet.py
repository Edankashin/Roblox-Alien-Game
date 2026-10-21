#!/usr/bin/env python3
"""A drawn contact sheet of B46's effects ladder, read from src/shared/data/Effects.luau, for review.

One panel per tier, left to right, each the same block alien at the same height (B45: rarer is not bigger) wearing the effect
stack its example species draws at its own tier (the tier gate of Shared/EffectsMath.LayersFor: kinds, layersAllowed and the
tier's extras), with the pixel sprites of tools/pixel_sprites.py tinted as an emitter would. Under each panel: the layer
count, the kinds and the moments (timers, the flourish, the spawn moment). A diagram, not a render: every kind is drawn as one
frozen frame (a burst mid-flight, a ring half out, the pillar at full), labelled as such.

    python3 -I tools/effects_ladder_sheet.py media/studio/2026-10-21/effects_ladder_v1.png
"""
from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lint_data  # noqa: E402
import pixel_sprites  # noqa: E402

ROOT = lint_data.ROOT
EXAMPLES = {'Common': 'Pebblet', 'Uncommon': 'Snailbyte', 'Rare': 'Zapfinch', 'Epic': 'Thunderhog', 'Legendary': 'Gaiabloom',
            'Cosmic': 'Radish', 'Secret': 'Panpipe'}
PANEL_W, PANEL_H = 300, 560
TEXT_H = 250
TOP = 70
ALIEN_W, ALIEN_H = 96, 120  # the same for every tier (B45)
SKY = (22, 22, 40)
GROUND = (40, 52, 44)


def hexrgb(value: str) -> "tuple[int, int, int]":
    number = int(value, 16)
    return (number >> 16) & 255, (number >> 8) & 255, number & 255


def mix(a: str, b: str, t: float) -> str:
    ca, cb = hexrgb(a), hexrgb(b)
    return '%02X%02X%02X' % tuple(round(x + (y - x) * t) for x, y in zip(ca, cb))


def layers_for(effects, sid: str, tier: str) -> "list[dict]":
    """EffectsMath.LayersFor in Python: the drawn layers, then the tier's extras in the accent, dark for a dark tier."""
    rule = effects['Tiers'][tier]
    row = effects['Species'][sid]
    drawn = [dict(layer) for layer in lint_data.drawn_layers(row, rule, effects['Caps'])]
    kinds = {layer['kind'] for layer in drawn}
    timed_ring = any(layer['kind'] == 'RingPulse' and layer.get('every') for layer in drawn)
    accent = row.get('accent') or row['layers'][1]['color']
    extras = effects['Extras']
    for flag, name, kind, missing in (('orbit', 'Orbit', 'Orbit', 'Orbit' not in kinds), ('trail', 'Trail', 'Trail', 'Trail' not in kinds),
                                      ('groundRing', 'GroundRing', 'RingPulse', not timed_ring), ('aura', 'Aura', 'Aura', 'Aura' not in kinds),
                                      ('pillar', 'Pillar', 'Pillar', 'Pillar' not in kinds)):
        if rule.get(flag) and missing:
            extra = dict(extras[name])
            extra['color'] = accent
            extra['extra'] = True
            drawn.append(extra)
    if rule.get('dark'):
        dark = effects['Dark']
        for layer in drawn:
            amount = dark['MomentMix'] if layer['kind'] in ('Pillar', 'RingPulse') else dark['Mix']
            layer['color'] = mix(layer['color'], dark['Color'], amount)
    return drawn


class Panel:
    def __init__(self, image: Image.Image, x0: int, sprites, attach, rng: random.Random):
        self.image = image
        self.x0 = x0
        self.sprites = sprites
        self.attach = attach
        self.rng = rng
        self.cx = x0 + PANEL_W // 2
        self.feet = TOP + PANEL_H - 90
        self.glow = Image.new('RGBA', image.size, (0, 0, 0, 0))  # soft light, blurred before the alien goes on

    def point(self, region: str) -> "tuple[float, float]":
        p = self.attach.get(region, self.attach['Body'])
        return self.cx + p['x'] * ALIEN_W * 1.1 + max(p['z'], 0) * ALIEN_W, self.feet - p['y'] * ALIEN_H

    def sprite(self, key: str | None, color: str, x: float, y: float, size: float, alpha: float = 1.0):
        base = self.sprites.get(key or 'PixelMote', self.sprites['PixelMote'])
        if base.width > pixel_sprites.GRID:  # a sheet: its fullest frame
            base = base.crop((0, pixel_sprites.GRID, pixel_sprites.GRID, pixel_sprites.GRID * 2)) if key == 'PixelTwinkle' else base.crop((0, 0, pixel_sprites.GRID, pixel_sprites.GRID))
        side = max(8, int(size))
        side -= side % 4
        scaled = base.resize((side, side), Image.NEAREST)
        rgb = hexrgb(color)
        tinted = Image.new('RGBA', scaled.size)
        src, dst = scaled.load(), tinted.load()
        for yy in range(side):
            for xx in range(side):
                r, _, _, a = src[xx, yy]
                k = 0.45 + 0.55 * r / 255
                dst[xx, yy] = (min(255, int(rgb[0] * k + 40 * (r / 255))), min(255, int(rgb[1] * k + 40 * (r / 255))),
                               min(255, int(rgb[2] * k + 40 * (r / 255))), int(a * alpha))
        self.image.alpha_composite(tinted, (int(x - side / 2), int(y - side / 2)))

    def soft(self, color: str, x: float, y: float, radius: float, strength: float):
        draw = ImageDraw.Draw(self.glow)
        rgb = hexrgb(color)
        for step in range(6, 0, -1):
            r = radius * step / 6
            draw.ellipse((x - r, y - r, x + r, y + r), fill=rgb + (int(255 * strength * (1 - step / 7) / 2),))

    # each kind, one frozen frame
    def layer(self, layer: dict, scale: dict):
        kind = layer['kind']
        color = layer['color']
        x, y = self.point(layer['at'])
        size = max(12, layer.get('size', 0.1) * ALIEN_H * scale['sizeScale'] * 1.6)
        sprite = layer.get('sprite')
        if kind == 'Emitter':
            n = max(2, min(9, round(layer.get('rate', 1) * scale['rateScale'] * 1.4)))
            rise = layer.get('rise', 0)
            for _ in range(n):
                dx = self.rng.uniform(-1, 1) * (0.25 + layer.get('spread', 30) / 360) * ALIEN_W * 0.8
                dy = -abs(self.rng.gauss(0, 1)) * ALIEN_H * (0.35 if rise >= 0 else -0.35)
                if layer.get('dir') == 'Back':
                    dx, dy = abs(dx) + 20, dy * 0.3
                self.sprite(sprite, color, x + dx, y + dy, size, self.rng.uniform(0.55, 1))
        elif kind == 'Burst':
            n = max(1, min(18, layer.get('count', 1)))
            reach = (0.3 + layer.get('speed', 0.2)) * ALIEN_H * 0.55
            for index in range(n):
                angle = -math.pi / 2 + (index - (n - 1) / 2) * min(0.5, 2.6 / n) * (2 if layer.get('spread', 60) > 120 else 1)
                r = reach * self.rng.uniform(0.6, 1)
                self.sprite(sprite, color, x + math.cos(angle) * r, y + math.sin(angle) * r * (0.6 if layer.get('rise', 0) < 0 else 1), size)
        elif kind == 'Sparkle':
            self.sprite('PixelTwinkle', color, x, y, max(16, size * 1.3))
        elif kind == 'Light':
            self.soft(color, x, y, layer.get('range', 2) * ALIEN_H * 0.45 * scale['sizeScale'], min(1, layer.get('brightness', 1) * scale['lightScale']))
        elif kind == 'Beam':
            x2, y2 = self.point(layer.get('to', layer['at']))
            if layer['at'] == layer.get('to'):
                return
            draw = ImageDraw.Draw(self.image)
            points = [(x, y)]
            for index in range(1, 5):
                t = index / 5
                points.append((x + (x2 - x) * t + self.rng.uniform(-9, 9), y + (y2 - y) * t - 14 + self.rng.uniform(-9, 9)))
            points.append((x2, y2))
            draw.line(points, fill=hexrgb(color) + (255,), width=4)
            draw.line(points, fill=(255, 255, 255, 255), width=1)
        elif kind == 'Trail':
            draw = ImageDraw.Draw(self.image)
            x2, y2 = self.point(layer.get('to', 'Feet'))
            rgb = hexrgb(color)
            for index in range(6):
                t = index / 6
                off = 10 + index * 12
                draw.line((x + off, y + 4 * math.sin(index), x2 + off, y2 + 4 * math.sin(index)), fill=rgb + (int(170 * (1 - t)),), width=3)
        elif kind == 'Orbit':
            count = layer.get('count', 3)
            r = layer.get('radius', 0.6) * ALIEN_H * 1.2
            draw = ImageDraw.Draw(self.image)
            draw.ellipse((x - r, y - r * 0.28, x + r, y + r * 0.28), outline=hexrgb(color) + (70,), width=1)
            for index in range(count):
                angle = math.tau * index / count + 0.4
                self.sprite(sprite, color, x + math.cos(angle) * r, y + math.sin(angle) * r * 0.28, max(12, size))
        elif kind == 'RingPulse':
            r = layer.get('size', 2) * ALIEN_H * 0.32
            draw = ImageDraw.Draw(self.image)
            rgb = hexrgb(color)
            for step, a in ((1.0, 230), (0.7, 150), (0.42, 90)):
                draw.ellipse((x - r * step, y - r * step * 0.22, x + r * step, y + r * step * 0.22), outline=rgb + (a,), width=4)
        elif kind == 'Pillar':
            width = max(10, layer.get('width', 0.4) * ALIEN_H * 0.7)
            rgb = hexrgb(color)
            core = hexrgb(mix(color, 'FFFFFF', 0.65))
            column = Image.new('RGBA', self.image.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(column)
            draw.rectangle((x - width / 2, TOP + 2, x + width / 2, y), fill=rgb + (150,))
            draw.rectangle((x - width / 6, TOP + 2, x + width / 6, y), fill=core + (235,))
            self.glow.alpha_composite(column.filter(ImageFilter.GaussianBlur(10)))
            self.image.alpha_composite(column)
        elif kind == 'Aura':
            shell = Image.new('RGBA', self.image.size, (0, 0, 0, 0))
            draw = ImageDraw.Draw(shell)
            r = layer.get('size', 1.25) * ALIEN_H * 0.55
            cy = self.feet - ALIEN_H * 0.5
            # a stepped (pixel) shell: concentric squares, each a softer cell
            for step, a in ((1.0, 40), (0.85, 60), (0.7, 80)):
                half = r * step
                draw.rectangle((self.cx - half, cy - half, self.cx + half, cy + half), fill=hexrgb(color) + (a,))
            self.glow.alpha_composite(shell)


def draw_alien(image: Image.Image, cx: float, feet: float, body: str, dark: bool):
    """The same block alien in every panel: a body block and a head block on the face-cell grid, two eyes."""
    draw = ImageDraw.Draw(image)
    cell = 8
    rgb = hexrgb(body)
    shade = tuple(max(0, c - 28) for c in rgb)
    lit = tuple(min(255, c + 22) for c in rgb)
    for x0, y0, w, h in ((cx - ALIEN_W / 2, feet - ALIEN_H * 0.55, ALIEN_W, ALIEN_H * 0.55), (cx - ALIEN_W * 0.4, feet - ALIEN_H, ALIEN_W * 0.8, ALIEN_H * 0.47)):
        draw.rectangle((x0, y0, x0 + w, y0 + h), fill=rgb)
        draw.rectangle((x0, y0, x0 + w, y0 + cell), fill=lit)
        x = x0
        while x <= x0 + w:
            draw.line((x, y0, x, y0 + h), fill=shade, width=1)
            x += cell
        y = y0
        while y <= y0 + h:
            draw.line((x0, y, x0 + w, y), fill=shade, width=1)
            y += cell
        draw.rectangle((x0, y0, x0 + w, y0 + h), outline=tuple(max(0, c - 60) for c in rgb), width=2)
    eye = (250, 250, 255) if dark else (24, 22, 36)
    for side in (-1, 1):
        ex = cx + side * ALIEN_W * 0.17
        ey = feet - ALIEN_H * 0.78
        draw.rectangle((ex - 7, ey - 10, ex + 7, ey + 10), fill=eye)
        draw.rectangle((ex - 5, ey - 8, ex - 1, ey - 4), fill=(255, 255, 255) if not dark else (180, 140, 255))


def describe(layers: "list[dict]", rule: dict, row: dict, flourish_default: float) -> "list[str]":
    own = [layer for layer in layers if not layer.get('extra')]
    extras = [layer['kind'] for layer in layers if layer.get('extra')]
    lines = [f"{len(own)} species layers" + (f" + {len(extras)} tier extras" if extras else '')]
    kinds = []
    for layer in own:
        tag = layer['kind']
        if layer.get('every'):
            tag += f" /{layer['every']:g}s"
        if layer.get('flourish'):
            tag += ' (flourish)'
        kinds.append(tag)
    for start in range(0, len(kinds), 2):
        lines.append('  ' + ', '.join(kinds[start:start + 2]))
    if extras:
        lines.append('+ ' + ', '.join(extras))
    moments = []
    if rule.get('flourish'):
        moments.append(f"flourish every {row.get('flourishEvery', flourish_default):g}s")
    if rule.get('spawnMoment'):
        moments.append('spawn moment (sky pillar)')
    if rule.get('dark'):
        moments.append('shadow palette')
    lines.append('moments: ' + (moments[0] if moments else 'timers only'))
    lines.extend('  ' + moment for moment in moments[1:])
    lines.append(f"x{rule['rateScale']:g} rate, burst <= {rule['burstMax']}")
    return lines


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    reader = lint_data.TableReader()
    effects = reader.read(ROOT / 'src/shared/data/Effects.luau')
    tiers = reader.read(ROOT / 'src/shared/data/Tiers.luau')
    order = list(tiers['Order'].values())
    sprites = pixel_sprites.sprites()
    width = PANEL_W * len(order)
    height = TOP + PANEL_H + TEXT_H
    image = Image.new('RGBA', (width, height), SKY + (255,))
    head = ImageDraw.Draw(image)
    head.text((16, 14), "Effects ladder v1 (B46): rarity shows by effects, detail and motion, never by size (B45: every alien 2 to 3.5 studs)", fill=(240, 240, 248))
    head.text((16, 36), "Drawn from src/shared/data/Effects.luau (each tier's example species at its own tier); one frozen frame per kind; pixel sprites from tools/pixel_sprites.py", fill=(170, 170, 190))
    rng = random.Random(46)
    glow_all = Image.new('RGBA', image.size, (0, 0, 0, 0))
    panels = []
    for index, tier in enumerate(order):
        x0 = index * PANEL_W
        draw = ImageDraw.Draw(image)
        draw.rectangle((x0 + 2, TOP, x0 + PANEL_W - 2, TOP + PANEL_H), fill=SKY)
        draw.rectangle((x0 + 2, TOP + PANEL_H - 90, x0 + PANEL_W - 2, TOP + PANEL_H), fill=GROUND)
        panel = Panel(image, x0, sprites, effects['Attach'], rng)
        panels.append(panel)
    # back to front: lights and auras under everything, then the alien, then the rest
    stacks = []
    for index, tier in enumerate(order):
        sid = EXAMPLES[tier]
        layers = layers_for(effects, sid, tier)
        stacks.append((tier, sid, layers))
        for layer in layers:
            if layer['kind'] in ('Light', 'Aura', 'Pillar', 'RingPulse'):
                panels[index].layer(layer, effects['Tiers'][tier])
        blurred = panels[index].glow.filter(ImageFilter.GaussianBlur(6))
        box = (panels[index].x0 + 2, TOP, panels[index].x0 + PANEL_W - 2, TOP + PANEL_H)
        glow_all.alpha_composite(blurred.crop(box), (box[0], box[1]))  # each panel's light stays in its panel
    image.alpha_composite(glow_all)
    for index, (tier, sid, layers) in enumerate(stacks):
        rule = effects['Tiers'][tier]
        body = mix('7F8FA6', '0B0618', 0.5) if rule.get('dark') else '8A9BB0'
        draw_alien(image, panels[index].cx, panels[index].feet, body, rule.get('dark', False))
        for layer in layers:
            if layer['kind'] not in ('Light', 'Aura', 'Pillar', 'RingPulse'):
                panels[index].layer(layer, rule)
    draw = ImageDraw.Draw(image)
    for index, (tier, sid, layers) in enumerate(stacks):
        x0 = index * PANEL_W
        rule = effects['Tiers'][tier]
        colour = hexrgb(tiers['Tiers'][tier]['color'])
        if tier == 'Secret':
            colour = (178, 140, 255)
        draw.rectangle((x0 + 2, TOP - 8, x0 + PANEL_W - 2, TOP - 2), fill=colour)
        ty = TOP + PANEL_H + 10
        draw.text((x0 + 12, ty), f"{tier}: {sid}", fill=colour)
        row = effects['Species'][sid]
        for line_index, line in enumerate(describe(layers, rule, row, effects['Look']['FlourishEvery'])):
            draw.text((x0 + 12, ty + 22 + line_index * 17), line, fill=(222, 222, 232))
        draw.line((x0 + PANEL_W - 1, TOP, x0 + PANEL_W - 1, height), fill=(60, 60, 84), width=2)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    image.convert('RGB').save(args.out)
    print(f'effects ladder: {args.out}')


if __name__ == '__main__':
    main()
