#!/usr/bin/env python3
"""A drawn sheet of the signature-piece effects (the Rare pass, 2026-10-21), read from src/shared/data/Effects.luau, for review.

One card per Rare to Secret species, rarest last: the alien drawn from its creature note's parts (a flat-shaded three-quarter view,
no Blender; the same parts the GLB exports), its signature piece's moving object outlined in white, and the effect layers its own
tier draws (Shared/EffectsMath.LayersFor, without the tier's extras) frozen in one frame at the points they hang on: a layer on a
signature piece (Effects.Pieces) at the piece's spot on its part, with the path the rig carries it on (data/Rigs: a spin is a
dotted circle, so an orbiting emitter's trail lies along it), the rest at their body regions. Beside it, in words: the piece, each
layer on it (kind, colour, numbers, what fires on the flourish) and the rest. A diagram, not a render: a burst is drawn mid-flight
and dashed when it waits for the flourish, a pillar at full height, a light as a soft disc of its range.

    python3 -I tools/signature_vfx_sheet.py media/studio/2026-10-21/signature_vfx_v1.png
"""
from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE / 'blocky'))
import lint_data  # noqa: E402
import spec as blocky_spec  # noqa: E402

ROOT = lint_data.ROOT
NOTES = ROOT / 'docs/vault/07-alien-game/Creatures'
RENDERS = ROOT / 'docs/vault/06-art-pipelines/refs/blocky'
ORDER = ('Rare', 'Epic', 'Legendary', 'Cosmic', 'Secret')
TIER_HEX = {'Rare': '3B82F6', 'Epic': 'A855F7', 'Legendary': 'F59E0B', 'Cosmic': 'EC4899', 'Secret': '6B21A8'}
COLUMNS = 3
CARD_W, CARD_H = 660, 360
STAGE_W = 330
HEADER_H = 150
PAD = 18
SKY = (18, 20, 38)
PAPER = (246, 240, 230)
INK = (32, 30, 40)
YAW, PITCH = math.radians(-32), math.radians(22)
LIGHT = (0.45, 0.8, -0.4)


def font(size: int, bold: bool = False):
    name = 'DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf'
    for base in ('/usr/share/fonts/truetype/dejavu', '/Library/Fonts', '/System/Library/Fonts/Supplemental'):
        path = Path(base) / name
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def rgb(value: str) -> 'tuple[int, int, int]':
    value = value.lstrip('#')
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def project(p):
    """Note space (studs: x the alien's right, y up, z back) to the view: (screen x, screen y up, depth away from the camera)."""
    x, y, z = p
    xa = x * math.cos(YAW) + z * math.sin(YAW)
    za = -x * math.sin(YAW) + z * math.cos(YAW)
    yb = y * math.cos(PITCH) + za * math.sin(PITCH)
    zb = -y * math.sin(PITCH) + za * math.cos(PITCH)
    return -xa, yb, zb


def layers_drawn(effects, sid, tier):
    return [dict(layer) for layer in lint_data.drawn_layers(effects['Species'][sid], effects['Tiers'][tier], effects['Caps'])]


class Alien:
    """One creature note: its parts, bounds, moving objects, and where an Effects point lands in note space."""

    def __init__(self, sid, effects, rigs):
        self.spec = blocky_spec.load(NOTES / f'{sid}.md')
        self.parts = blocky_spec.expand(self.spec['parts'])
        self.lo, self.hi = blocky_spec.bounds(self.parts)
        self.movers = blocky_spec.movers(self.parts)
        self.effects = effects
        self.rig = rigs.get(sid) or {}

    def size(self):
        return [self.hi[i] - self.lo[i] for i in range(3)]

    def region(self, name):
        attach = self.effects['Attach'].get(name) or self.effects['Attach']['Body']
        sx, sy, sz = self.size()
        return ((self.lo[0] + self.hi[0]) / 2 + attach['x'] * sx, self.lo[1] + attach['y'] * sy, (self.lo[2] + self.hi[2]) / 2 + attach['z'] * sz)

    def piece_point(self, name):
        """(point, mover key, its pivot) of a piece, or None when the note has no such moving object."""
        piece = self.effects['Pieces'].get(name)
        if not piece or piece['part'] not in self.movers:
            return None
        mover = self.movers[piece['part']]
        ml, mh = blocky_spec.bounds(mover['parts'])
        spot = [piece['spot'][i + 1] for i in range(3)]
        point = tuple((ml[i] + mh[i]) / 2 + spot[i] * (mh[i] - ml[i]) for i in range(3))
        return point, piece['part'], mover['pivot']

    def point(self, name):
        found = self.piece_point(name)
        if found:
            return found[0]
        if name in self.effects['Pieces']:
            return self.region(self.effects['Pieces'][name]['region'])
        return self.region(name)

    def spin(self, part):
        """The axis ('x', 'y' or 'z') of the part's spin clip in data/Rigs, or None."""
        for row in (self.rig.get('parts') or {}).values():
            if row.get('name') == part:
                for clip in (row.get('clips') or {}).values():
                    if clip.get('kind') == 'spin':
                        return clip.get('axis', 'y')
        return None


class Stage:
    """The card's picture: note space onto a box of the image, studs to pixels."""

    def __init__(self, alien, box):
        self.alien = alien
        self.box = box
        corners = [project((x, y, z)) for x in (alien.lo[0], alien.hi[0]) for y in (alien.lo[1], alien.hi[1]) for z in (alien.lo[2], alien.hi[2])]
        xs, ys = [c[0] for c in corners], [c[1] for c in corners]
        left, top, right, bottom = box
        self.scale = min((right - left) * 0.62 / (max(xs) - min(xs)), (bottom - top) * 0.55 / (max(ys) - min(ys)))
        self.cx = (left + right) / 2 - (max(xs) + min(xs)) / 2 * self.scale
        self.cy = bottom - 46 + min(ys) * self.scale

    def xy(self, p):
        sx, sy, _ = project(p)
        return self.cx + sx * self.scale, self.cy - sy * self.scale


def draw_alien(img, stage, highlight):
    """Flat-shaded faces, far first; the faces of the moving object `highlight` outlined in white."""
    alien = stage.alien
    draw = ImageDraw.Draw(img)
    faces = []
    for part in alien.parts:
        verts, polys = blocky_spec.part_mesh(part)
        hexv = blocky_spec.slot_hex(alien.spec, part['slot']) if part.get('slot') in blocky_spec.SLOT_ROLE else '#888888'
        glow = part.get('slot') == 'Glow'
        mine = part['moves'] != 'none' and any(p is part for p in alien.movers.get(highlight, {}).get('parts', []))
        for poly in polys:
            pts = [verts[i] for i in poly]
            a, b, c = pts[0], pts[1], pts[2]
            u = [b[k] - a[k] for k in range(3)]
            v = [c[k] - a[k] for k in range(3)]
            n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
            length = math.sqrt(sum(t * t for t in n)) or 1
            n = tuple(t / length for t in n)
            # cull a face that looks away from the camera (the camera looks along +depth)
            _, _, d0 = project((0, 0, 0))
            _, _, dn = project(n)
            if dn - d0 > 0.02:
                continue
            depth = sum(project(p)[2] for p in pts) / len(pts)
            shade = 0.55 + 0.45 * max(0.0, sum(n[k] * LIGHT[k] for k in range(3)) / math.sqrt(sum(t * t for t in LIGHT)))
            col = rgb(hexv)
            col = tuple(min(255, int(ch * (1.0 if glow else shade) + (40 if glow else 0))) for ch in col)
            faces.append((depth, [stage.xy(p) for p in pts], col, mine))
    faces.sort(key=lambda f: -f[0])
    for _, pts, col, mine in faces:
        draw.polygon(pts, fill=col, outline=(255, 255, 255) if mine else tuple(max(0, ch - 50) for ch in col))


def spin_path(alien, stage, point, pivot, axis, steps=48):
    out = []
    for k in range(steps + 1):
        a = 2 * math.pi * k / steps
        rel = [point[i] - pivot[i] for i in range(3)]
        if axis == 'y':
            x = pivot[0] + rel[0] * math.cos(a) - rel[2] * math.sin(a)
            z = pivot[2] + rel[0] * math.sin(a) + rel[2] * math.cos(a)
            p = (x, point[1], z)
        elif axis == 'z':
            p = (pivot[0] + rel[0] * math.cos(a) - rel[1] * math.sin(a), pivot[1] + rel[0] * math.sin(a) + rel[1] * math.cos(a), point[2])
        else:
            p = (point[0], pivot[1] + rel[1] * math.cos(a) - rel[2] * math.sin(a), pivot[2] + rel[1] * math.sin(a) + rel[2] * math.cos(a))
        out.append(stage.xy(p))
    return out


def star(draw, x, y, r, col):
    draw.polygon([(x, y - r), (x + r * 0.28, y - r * 0.28), (x + r, y), (x + r * 0.28, y + r * 0.28), (x, y + r),
                  (x - r * 0.28, y + r * 0.28), (x - r, y), (x - r * 0.28, y - r * 0.28)], fill=col)


def draw_effects(img, stage, alien, layers, signature):
    """Glows (lights, pillars, trails, auras) on a blurred layer screened over the picture; sprites crisp on top."""
    rnd = random.Random(7)
    glow = Image.new('RGB', img.size, (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    crisp = ImageDraw.Draw(img)
    height = alien.size()[1]
    px = stage.scale  # pixels a stud
    marks = []
    for layer in layers:
        col = rgb(layer['color'])
        at = layer['at']
        found = alien.piece_point(at)
        p = alien.point(at)
        sx, sy = stage.xy(p)
        path = None
        if found:
            axis = alien.spin(found[1])
            if axis:
                path = spin_path(alien, stage, found[0], found[2], axis)
        kind = layer['kind']
        if kind == 'Light':
            r = min(layer.get('range', 2) * height * px * 0.35, 120)
            for k in range(6, 0, -1):
                rr = r * k / 6
                gd.ellipse([sx - rr, sy - rr, sx + rr, sy + rr], fill=tuple(int(c * (0.18 + 0.1 * (6 - k))) for c in col))
        elif kind == 'Pillar':
            w = max(4, layer.get('width', 0.3) * height * px)
            gd.rectangle([sx - w / 2, stage.box[1], sx + w / 2, sy], fill=col)
            gd.rectangle([sx - w / 6, stage.box[1], sx + w / 6, sy], fill=(255, 255, 255))
        elif kind == 'Aura':
            r = layer.get('size', 1) * height * px / 2
            gd.ellipse([sx - r, sy - r, sx + r, sy + r], outline=col, width=max(3, int(r / 5)))
        elif kind == 'Trail':
            q = stage.xy(alien.point(layer.get('to') or 'Feet'))
            ribbon = path[:12] if path else [(sx + 14 * k, sy + 3 * k) for k in range(8)]
            dx, dy = q[0] - sx, q[1] - sy
            for k in range(len(ribbon) - 1):
                fade = 1 - k / len(ribbon)
                (x0, y0), (x1, y1) = ribbon[k], ribbon[k + 1]
                gd.polygon([(x0, y0), (x1, y1), (x1 + dx * fade, y1 + dy * fade), (x0 + dx * fade, y0 + dy * fade)], fill=tuple(int(c * fade) for c in col))
        elif kind == 'Beam':
            q = stage.xy(alien.point(layer['to']))
            pts = [(sx, sy)]
            for k in range(1, 6):
                t = k / 6
                pts.append((sx + (q[0] - sx) * t + rnd.uniform(-6, 6), sy + (q[1] - sy) * t + rnd.uniform(-6, 6)))
            pts.append(q)
            gd.line(pts, fill=col, width=5)
            crisp.line(pts, fill=(255, 255, 255), width=1)
        elif kind == 'Orbit':
            r = layer.get('radius', 0.5) * height * px
            for k in range(int(layer.get('count', 3))):
                a = 2 * math.pi * k / layer.get('count', 3)
                ox, oy = sx + r * math.cos(a), sy + r * 0.35 * math.sin(a)
                crisp.rectangle([ox - 3, oy - 3, ox + 3, oy + 3], fill=col)
        elif kind == 'RingPulse':
            r = layer.get('size', 2) * height * px * 0.25
            gd.ellipse([sx - r, sy - r * 0.3, sx + r, sy + r * 0.3], outline=col, width=4)
        marks.append((layer, sx, sy, path, col))
    soft = glow.filter(ImageFilter.GaussianBlur(5))
    img.paste(ImageChops.screen(img.convert('RGB'), soft))
    crisp = ImageDraw.Draw(img)
    for layer, sx, sy, path, col in marks:
        kind = layer['kind']
        cell = max(3, int(layer.get('size', 0.05) * height * stage.scale * 0.8))
        if kind == 'Emitter':
            n = min(18, max(5, int(layer.get('rate', 4))))
            for k in range(n):
                if path and len(path) > 2:
                    ox, oy = path[min(len(path) - 1, 1 + k)]
                else:
                    spread = 4 + k * 2.2
                    fall = layer.get('rise', 0) or 0
                    ox, oy = sx + rnd.uniform(-spread, spread), sy - k * 3 * (1 if fall >= 0 else -1)
                crisp.rectangle([ox - cell / 2, oy - cell / 2, ox + cell / 2, oy + cell / 2], fill=col)
        elif kind == 'Sparkle':
            star(crisp, sx, sy, cell * 1.6 + 3, col)
        elif kind == 'Burst':
            n = min(14, int(layer.get('count', 6)))
            reach = 20 + layer.get('speed', 0.3) * 40
            for k in range(n):
                a = 2 * math.pi * k / n
                ox, oy = sx + reach * math.cos(a), sy + reach * math.sin(a) * 0.8
                if layer.get('flourish') and not layer.get('every'):
                    crisp.line([(sx + 0.5 * (ox - sx), sy + 0.5 * (oy - sy)), (ox, oy)], fill=col, width=1)
                crisp.rectangle([ox - cell / 2, oy - cell / 2, ox + cell / 2, oy + cell / 2], fill=col)
        if path:
            crisp.line(path, fill=(220, 220, 255), width=1, joint=None)
            for k in range(0, len(path), 2):
                crisp.point(path[k], fill=(255, 255, 255))


def kind_words(layer):
    kind = layer['kind']
    sprite = (layer.get('sprite') or '').replace('Pixel', '').lower() or 'glow'
    when = []
    if layer.get('every'):
        when.append(f"every {layer['every']:g} s")
    if layer.get('flourish'):
        when.append('on the flourish')
    when = ' and '.join(when)
    if kind == 'Emitter':
        return f"{sprite} stream, {layer['rate']:g} a second, {layer['lifetime']:g} s"
    if kind == 'Light':
        pulse = f", pulse {layer['pulse']:g} s" if layer.get('pulse') else ''
        return f"light {layer['brightness']:g}, range {layer['range']:g} heights{pulse}; flares on the flourish"
    if kind == 'Sparkle':
        return f"{sprite} sparkle {when}"
    if kind == 'Burst':
        return f"burst of {layer['count']} {sprite} {when}"
    if kind == 'Trail':
        return f"ribbon trail to {layer.get('to')}, {layer['lifetime']:g} s, tapering"
    if kind == 'Beam':
        return f"bolt to {layer.get('to')}, a strike every {layer['flicker']:g} s"
    if kind == 'Pillar':
        return f"column of light {layer['reach']:g} heights up, on the flourish"
    if kind == 'Aura':
        return f"held {sprite} shell, {layer['size']:g} heights"
    if kind == 'Orbit':
        return f"{layer['count']} {sprite} motes circling"
    if kind == 'RingPulse':
        return f"ground ring {when}"
    return kind


def on_signature(name, signature, pieces):
    same = name in pieces and signature in pieces and pieces[name]['part'] == pieces[signature]['part']
    return name.startswith(signature) or same


def wrap(draw, text, fnt, width):
    words, lines, line = text.split(), [], ''
    for word in words:
        trial = (line + ' ' + word).strip()
        if draw.textlength(trial, font=fnt) > width and line:
            lines.append(line)
            line = word
        else:
            line = trial
    if line:
        lines.append(line)
    return lines


def card(sid, name, tier, effects, rigs):
    img = Image.new('RGB', (CARD_W, CARD_H), PAPER)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, STAGE_W, CARD_H], fill=SKY)
    alien = Alien(sid, effects, rigs)
    row = effects['Species'][sid]
    signature = row.get('signature')
    pieces = effects['Pieces']
    stage = Stage(alien, (0, 0, STAGE_W, CARD_H))
    found = alien.piece_point(signature) if signature else None
    draw_alien(img, stage, found[1] if found else None)
    drawn = layers_drawn(effects, sid, tier)
    draw_effects(img, stage, alien, drawn, signature)
    draw = ImageDraw.Draw(img)
    draw.text((10, CARD_H - 22), 'a diagram: one frozen frame, the tier\'s extras left out', font=font(11), fill=(170, 170, 200))
    x, y = STAGE_W + 14, 12
    draw.text((x, y), name, font=font(24, True), fill=INK)
    tw = draw.textlength(name, font=font(24, True))
    draw.rounded_rectangle([x + tw + 10, y + 5, x + tw + 10 + draw.textlength(tier, font=font(13, True)) + 14, y + 25], radius=6, fill=rgb(TIER_HEX[tier]))
    draw.text((x + tw + 17, y + 7), tier, font=font(13, True), fill=(255, 255, 255))
    y += 34
    piece = pieces.get(signature)
    where = f"part `{piece['part']}` (falls back to {piece['region']})" if piece else 'a static point of the body'
    for line in wrap(draw, f"{sid}. Signature: {signature}, {where}", font(13), CARD_W - x - 12):
        draw.text((x, y), line, font=font(13), fill=(90, 86, 100))
        y += 17
    y += 4
    mine = [layer for layer in drawn if on_signature(layer['at'], signature, pieces)]
    rest = [layer for layer in drawn if layer not in mine]
    draw.text((x, y), 'On the piece', font=font(14, True), fill=INK)
    y += 20
    for layer in mine:
        draw.rectangle([x, y + 3, x + 11, y + 14], fill=rgb(layer['color']), outline=INK)
        lines = wrap(draw, f"{layer['kind']} at {layer['at']}: {kind_words(layer)}", font(12), CARD_W - x - 30)
        for k, line in enumerate(lines):
            draw.text((x + 18, y), line, font=font(12), fill=INK)
            y += 15
        y += 3
    if rest:
        y += 4
        draw.text((x, y), 'Round it', font=font(14, True), fill=INK)
        y += 20
        text = '; '.join(f"{layer['kind']} at {layer['at']}" for layer in rest)
        for line in wrap(draw, text, font(12), CARD_W - x - 118):  # clear of the render thumbnail
            draw.text((x, y), line, font=font(12), fill=(70, 66, 80))
            y += 15
    render = RENDERS / f'{sid}_tq_cells.jpg'
    if render.exists():
        thumb = Image.open(render).convert('RGB')
        thumb.thumbnail((96, 96))
        img.paste(thumb, (CARD_W - thumb.width - 8, CARD_H - thumb.height - 8))
    return img


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('out', nargs='?', default=str(ROOT / 'media/studio/2026-10-21/signature_vfx_v1.png'))
    args = parser.parse_args(argv)
    reader = lint_data.TableReader()
    effects = reader.read(ROOT / 'src/shared/data/Effects.luau')
    species = reader.read(ROOT / 'src/shared/data/Species.luau')
    rigs = reader.read(ROOT / 'src/shared/data/Rigs.luau')['Species']
    rows = [r for r in species['List'].values() if r['tier'] in ORDER and effects['Species'][r['id']].get('signature')]
    rows.sort(key=lambda r: (ORDER.index(r['tier']), r.get('world', 0), r['id']))
    cards = [card(r['id'], r.get('name') or r['id'], r['tier'], effects, rigs) for r in rows]
    nrows = math.ceil(len(cards) / COLUMNS)
    sheet = Image.new('RGB', (PAD + COLUMNS * (CARD_W + PAD), HEADER_H + nrows * (CARD_H + PAD) + PAD), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((PAD, 18), 'Signature VFX v1, 2026-10-21: each Rare to Secret alien\'s effects led by its signature piece', font=font(32, True), fill=INK)
    intro = ('From src/shared/data/Effects.luau (Pieces, and each row\'s signature). A layer on a piece hangs on that moving part of the '
             'block-cell model, so it rides the rig: an orbiting piece (dotted path) leaves its stream as a trail and carries its light '
             'round; on the rig\'s flourish (World.RigAnimator -> SpeciesFx.Flourish) the piece\'s burst or sparkle fires and its light '
             'flares. On an old blockout without the part the layer falls back to the region named. The moving object is outlined '
             'in white. Under Reduced Motion each keeps one still light. Phone budget: 120 live particles an alien; these use 2 to 73.')
    y = 64
    for line in wrap(draw, intro, font(15), sheet.width - 2 * PAD):
        draw.text((PAD, y), line, font=font(15), fill=(80, 76, 90))
        y += 20
    for index, image in enumerate(cards):
        cx = PAD + (index % COLUMNS) * (CARD_W + PAD)
        cy = HEADER_H + (index // COLUMNS) * (CARD_H + PAD)
        sheet.paste(image, (cx, cy))
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f'wrote {out} ({sheet.width} x {sheet.height}, {len(cards)} species)')


if __name__ == '__main__':
    main()
