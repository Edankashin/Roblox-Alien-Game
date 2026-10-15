#!/usr/bin/env python3
"""Composite the parts the thumbnail candidates need after the Blender render, then put the title on with store_title.py.

  python3 -I tools/store_compose.py TARGET RAW FINAL          TARGET is moment, reward, mystery, event or icon
  python3 -I tools/store_compose.py strip A.png B.png C.png D.png OUT.png

tools/blender/store_renders.py runs it after each render (docs/vault/01-game-design/Thumbnail-Research.md section 8); RAW is the
render (a RAW.json beside it, named like the raw file with .json, holds frame positions measured in Blender). Pillow only.
  moment    the real capture bar (Theme hexes, Rare's zone widths from src/shared/data/Tiers.luau), the tier label, "PERFECT!"
  reward    the violet gradient, Reveal-style rays and confetti behind the transparent render, "LEGENDARY"
  mystery   the "!" alert bubble, "WHO'S THAT?"
  event     "HAUNTED NEBULA"
  icon      a radial violet backdrop and a gold sparkle under the transparent render, saved 512x512, no text
  strip     four thumbnails at 192x108 side by side: the tile-size legibility check
Sizes are given for a 1920x1080 frame and scale with the raw image's width, so a half-size preview composites the same layout.
"""
import json
import math
import os
import pathlib
import random
import re
import subprocess
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
FONT = ROOT / "assets/fonts/FredokaOne.ttf"
SS = 4  # supersampling for the hand-drawn shapes
CAP = 0.74  # Fredoka One's cap height over its font size


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def theme():
    """Theme.Colors and Theme.Rarity hexes from src/shared/Theme.luau, as {"Colors.Featured": "FFC83D", ...}."""
    out, section = {}, None
    for line in (ROOT / "src/shared/Theme.luau").read_text().splitlines():
        m = re.match(r"Theme\.(\w+) = \{", line)
        if m:
            section = m.group(1)
        m = re.match(r'\s*(\w+) = Color3\.fromHex\("([0-9A-Fa-f]{6})"\)', line)
        if m and section in ("Colors", "Rarity"):
            out["%s.%s" % (section, m.group(1))] = m.group(2).upper()
    return out


def tier_zones(tier):
    sys.path.insert(0, str(HERE))
    import luau_tables
    row = luau_tables.load(str(ROOT / "src/shared/data/Tiers.luau"))["Tiers"][tier]
    return row["goodZone"], row["perfectZone"], row["color"]


def string(key):
    """A player-facing string from src/shared/strings/en.luau (the game's own words)."""
    m = re.search(r'^\s*%s = "((?:[^"\\]|\\.)*)"' % re.escape(key), (ROOT / "src/shared/strings/en.luau").read_text(), re.M)
    return m.group(1) if m else None


def font(px):
    return ImageFont.truetype(str(FONT), max(8, int(round(px))))


def load_raw(path, mode="RGB"):
    """The Blender render with its dither noise taken out: Cycles dithers the 8-bit output, which makes a 1920x1080 PNG 1.3 MB; a 3x3 median
    removes the isolated one-step noise and leaves the 14 px outline and the shapes alone (about 0.75 MB), so the thumbnail stays
    truecolour under 1 MB instead of falling back to the 256-colour palette (which bands the gradients)."""
    img = Image.open(path)
    if img.mode == "RGBA":
        r, g, b, a = img.split()
        rgb_img = Image.merge("RGB", (r, g, b)).filter(ImageFilter.MedianFilter(3))
        out = Image.merge("RGBA", (*rgb_img.split(), a))
        return out if mode == "RGBA" else out.convert(mode)
    return img.convert("RGB").filter(ImageFilter.MedianFilter(3)).convert(mode)


def meta_of(raw):
    p = pathlib.Path(raw).with_suffix(".json")
    return json.loads(p.read_text()) if p.exists() else {}


def over(base, layer):
    """Alpha-composite an RGBA layer onto an RGB or RGBA base; returns the same mode as the base."""
    mode = base.mode
    return Image.alpha_composite(base.convert("RGBA"), layer).convert(mode)


def shape_layer(size, box, painter):
    """Draw with `painter(draw, s)` (s = supersample factor) on a transparent canvas covering box=(x0,y0,x1,y1) of the image, and return
    (layer cropped to the box, x0, y0), downsampled with LANCZOS so the shapes are anti-aliased."""
    x0, y0, x1, y1 = [int(v) for v in box]
    big = Image.new("RGBA", ((x1 - x0) * SS, (y1 - y0) * SS), (0, 0, 0, 0))
    painter(ImageDraw.Draw(big), lambda v: v * SS, (x0, y0))
    return big.resize((x1 - x0, y1 - y0), Image.LANCZOS), x0, y0


def paste(img, layer, x0, y0):
    full = Image.new("RGBA", img.size, (0, 0, 0, 0))
    full.paste(layer, (x0, y0))
    return over(img, full)


def outlined_text(img, text, centre, cap_px, fill, outline, stroke):
    """Fredoka One text, its cap height cap_px, the centre of its capitals at `centre`, stroked."""
    f = font(cap_px / CAP)
    d = ImageDraw.Draw(img)
    w = d.textlength(text, font=f)
    d.text((centre[0] - w / 2, centre[1] + cap_px / 2), text, font=f, fill=rgb(fill), stroke_width=int(round(stroke)),
           stroke_fill=rgb(outline), anchor="ls")


def title(src, text, out, fill, width, pos="top", outline="1B1F3B"):
    cmd = [sys.executable, "-I", str(HERE / "store_title.py"), str(src), text, str(out), "--pos", pos, "--fill", fill, "--width", str(width),
           "--outline", outline]
    r = subprocess.run(cmd)
    if r.returncode:
        print("store_title.py returned %d (the file may be over 1 MB)" % r.returncode)
    return r.returncode


def halo(img, k, centre, colour, radius, alpha):
    """A soft bloom round a glowing part (Cycles has none): `colour` fading out from `centre` over `radius` px of a 1920 frame."""
    return over(img, radial(img.size, centre, radius * k, colour, alpha))


# ---------------------------------------------------------------------------------------------------------------- the capture bar
def capture_bar(img, k, tier="Rare", label_x=None):
    """The game's bar (src/client/UI/CaptureBar.luau): a navy trough pill, the Good zone (Confirm green) and the Perfect zone (Featured
    gold) centred on it at the tier's real widths, a white ticker with a navy outline, and the tier label in the tier colour. Layout from the
    research: 1152x76 at (960, 800), the Good zone 26% and the Perfect 8% of the bar for Rare, a 30 px gold glow, "RARE" at (960, 715)."""
    T = theme()
    good, perfect, tier_hex = tier_zones(tier)
    navy, green, gold, white = T["Colors.Outline"], T["Colors.Confirm"], T["Colors.Featured"], "FFFFFF"  # Theme.Colors.White is Color3.new(1, 1, 1)
    bw, bh, cx, cy = 1152 * k, 76 * k, 960 * k, 800 * k
    left, top = cx - bw / 2, cy - bh / 2
    gw, pw = good * bw, perfect * bw
    tick_x = cx + 17 * k  # inside the Perfect zone, off its centre: the ticker is moving
    pad = 80 * k
    box = (left - pad, top - pad, left + bw + pad, top + bh + pad)

    def paint_shadow(d, s, o):
        ox, oy = o
        d.rounded_rectangle([s(left - ox - 8 * k), s(top - oy - 8 * k + 12 * k), s(left - ox + bw + 8 * k), s(top - oy + bh + 8 * k + 12 * k)],
                            radius=s(bh / 2 + 8 * k), fill=(10, 12, 30, 200))

    layer, x0, y0 = shape_layer(img.size, box, paint_shadow)
    layer = layer.filter(ImageFilter.GaussianBlur(10 * k))
    img = paste(img, layer, x0, y0)

    def paint_bar(d, s, o):
        ox, oy = o
        X, Y = left - ox, top - oy
        edge = 8 * k
        d.rounded_rectangle([s(X - edge), s(Y - edge), s(X + bw + edge), s(Y + bh + edge)], radius=s(bh / 2 + edge), fill=rgb(navy))
        d.rounded_rectangle([s(X), s(Y), s(X + bw), s(Y + bh)], radius=s(bh / 2), fill=rgb(navy))

    layer, x0, y0 = shape_layer(img.size, box, paint_bar)
    img = paste(img, layer, x0, y0)

    # the near-miss flash's gold glow round the Perfect zone, under the zones
    def paint_glow(d, s, o):
        ox, oy = o
        px0 = cx - pw / 2 - ox
        d.rounded_rectangle([s(px0 - 6 * k), s(top - oy - 6 * k), s(px0 + pw + 6 * k), s(top - oy + bh + 6 * k)], radius=s(16 * k), fill=rgb(gold) + (235,))

    layer, x0, y0 = shape_layer(img.size, box, paint_glow)
    img = paste(img, layer.filter(ImageFilter.GaussianBlur(15 * k)), x0, y0)

    def paint_zones(d, s, o):
        ox, oy = o
        r = s(10 * k)
        d.rounded_rectangle([s(cx - gw / 2 - ox), s(top - oy), s(cx + gw / 2 - ox), s(top - oy + bh)], radius=r, fill=rgb(green))
        d.rounded_rectangle([s(cx - pw / 2 - ox), s(top - oy), s(cx + pw / 2 - ox), s(top - oy + bh)], radius=r, fill=rgb(gold))
        tw, th, ts = 14 * k, 114 * k, 6 * k
        tx0, ty0 = tick_x - tw / 2 - ox, cy - th / 2 - oy
        d.rounded_rectangle([s(tx0 - ts), s(ty0 - ts), s(tx0 + tw + ts), s(ty0 + th + ts)], radius=s(7 * k + ts), fill=rgb(navy))
        d.rounded_rectangle([s(tx0), s(ty0), s(tx0 + tw), s(ty0 + th)], radius=s(7 * k), fill=rgb(white))

    layer, x0, y0 = shape_layer(img.size, box, paint_zones)
    img = paste(img, layer, x0, y0)

    label = Image.new("RGBA", img.size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    lx = cx if label_x is None else label_x * k
    outlined_text(label, tier.upper(), (lx, 715 * k), 58 * k, tier_hex, navy, 5 * k)
    outlined_text(shadow, tier.upper(), (lx, 715 * k + 5 * k), 58 * k, "0A0C1E", "0A0C1E", 5 * k)
    shadow = shadow.filter(ImageFilter.GaussianBlur(4 * k))
    return over(over(img, shadow), label)


# ----------------------------------------------------------------------------------------------------------------- the "!" bubble
def alert_bubble(img, k, centre, diameter):
    """The game's alert bubble over an alien: a Featured-gold disc, a navy outline and a navy "!"."""
    T = theme()
    navy, gold = T["Colors.Outline"], T["Colors.Featured"]
    r = diameter / 2
    edge = max(4, 0.075 * diameter)
    pad = r * 0.6
    box = (centre[0] - r - pad, centre[1] - r - pad, centre[0] + r + pad, centre[1] + r + pad)

    def paint(d, s, o):
        ox, oy = o
        cx, cy = centre[0] - ox, centre[1] - oy
        d.ellipse([s(cx - r - edge), s(cy - r - edge), s(cx + r + edge), s(cy + r + edge)], fill=rgb(navy))
        d.ellipse([s(cx - r), s(cy - r), s(cx + r), s(cy + r)], fill=rgb(gold))
        # the UI Playbook's gloss: a lighter band across the top half of the face
        d.pieslice([s(cx - r * 0.86), s(cy - r * 0.9), s(cx + r * 0.86), s(cy + r * 0.82)], 200, 340, fill=rgb("FFE08A"))

    layer, x0, y0 = shape_layer(img.size, box, paint)
    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([pad - 2 * k, pad + 6 * k, pad + 2 * r + 2 * k, pad + 2 * r + 10 * k], fill=(10, 12, 30, 150))
    img = paste(img, shadow.filter(ImageFilter.GaussianBlur(5 * k)), x0, y0)
    img = paste(img, layer, x0, y0)
    mark = Image.new("RGBA", img.size, (0, 0, 0, 0))
    outlined_text(mark, "!", (centre[0], centre[1] + diameter * 0.02), diameter * 0.52, navy, navy, 0)
    return over(img, mark)


# --------------------------------------------------------------------------------------------------------------- the Reward backdrop
def vertical_gradient(size, top, bottom):
    w, h = size
    g = Image.linear_gradient("L").resize((w, h), Image.BILINEAR)
    return Image.composite(Image.new("RGB", size, rgb(bottom)), Image.new("RGB", size, rgb(top)), g)


def radial(size, centre, radius, colour, alpha):
    """A soft round glow: `colour` at `alpha` (0..1) in the middle fading to nothing at `radius`."""
    w, h = size
    # Pillow's radial gradient is 0 in the middle and 255 only at the corners (about 180 at the middle of each edge): scale it so 1.0 is the rim
    g = Image.radial_gradient("L").resize((int(radius * 2), int(radius * 2)), Image.BILINEAR)
    mask = g.point(lambda v: int(alpha * 255 * max(0.0, 1.0 - min(1.0, v * math.sqrt(2) / 255.0)) ** 1.6))
    full = Image.new("L", size, 0)
    full.paste(mask, (int(centre[0] - radius), int(centre[1] - radius)))
    layer = Image.new("RGBA", size, rgb(colour) + (0,))
    layer.putalpha(full)
    return layer


def rays(size, origin, count=16, colours=("FFD36B", "FFF1B0"), alpha=0.5, reach=1.25, phase=4.0):
    """The Reveal's radial burst: `count` thin wedges from `origin`, alternating colours, fading out toward the frame's edge."""
    w, h = size
    layer = Image.new("RGBA", (w * 2, h * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    r = math.hypot(w, h) * reach * 2
    ox, oy = origin[0] * 2, origin[1] * 2
    step = 360.0 / count
    for i in range(count):
        a0 = math.radians(phase + step * i)
        half = math.radians(step * 0.2)  # thin: 40% of the pitch
        pts = [(ox, oy), (ox + r * math.cos(a0 - half), oy + r * math.sin(a0 - half)), (ox + r * math.cos(a0 + half), oy + r * math.sin(a0 + half))]
        d.polygon(pts, fill=rgb(colours[i % 2]) + (255,))
    layer = layer.resize(size, Image.LANCZOS)
    fade = radial(size, origin, math.hypot(w, h) * 0.62, "FFFFFF", 1.0).getchannel("A")  # opaque near the origin, clear at the rim
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), fade.point(lambda v: int(v * alpha))))
    return layer


def confetti(size, k, avoid, seed=3, count=40):
    """About `count` small tumbling rectangles in Rare blue, Epic magenta, green and Legendary gold, each under 1.5% of the frame's width,
    kept out of the `avoid` mask (the hero's alpha) and out of the title band."""
    rnd = random.Random(seed)
    T = theme()
    colours = [T["Rarity.Rare"], T["Rarity.Epic"], T["Rarity.Uncommon"], T["Rarity.Legendary"]]
    w, h = size
    layer = Image.new("RGBA", (w * 2, h * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    placed, tries, placed_pts = 0, 0, []
    while placed < count and tries < 4000:
        tries += 1
        x, y = rnd.uniform(0.03, 0.97) * w, rnd.uniform(0.22, 0.93) * h
        if avoid.getpixel((int(x), int(y))) > 8 or any(math.hypot(x - px, y - py) < 60 * k for px, py in placed_pts):
            continue
        s = rnd.uniform(0.008, 0.013) * w  # the long side: under 1.5% of the width
        ang = rnd.uniform(0, math.pi)
        c, sn = math.cos(ang), math.sin(ang)
        hw, hh = s / 2, s / 4
        pts = [(x + c * dx - sn * dy, y + sn * dx + c * dy) for dx, dy in ((-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh))]
        col = rgb(colours[placed % 4])
        d.polygon([(px * 2, py * 2) for px, py in pts], fill=col + (255,), outline=rgb("1B1F3B"))
        placed_pts.append((x, y))
        placed += 1
    return layer.resize(size, Image.LANCZOS)


def build_reward(raw, k):
    src = load_raw(raw, "RGBA")
    size = src.size
    meta = meta_of(raw)
    head = meta.get("head", [0.5, 0.45])
    origin = (head[0] * size[0], head[1] * size[1])
    bg = vertical_gradient(size, "2A1170", "9A5BE0").convert("RGBA")
    bg = over(bg, radial(size, origin, size[1] * 0.75, "FFD36B", 0.30))
    bg = over(bg, rays(size, origin, alpha=0.42))
    bg = over(bg, confetti(size, k, src.getchannel("A").filter(ImageFilter.MaxFilter(2 * int(24 * k) + 1))))
    return over(bg, src).convert("RGB")


def build_icon(raw):
    src = load_raw(raw, "RGBA")
    size = src.size
    # radial gradient 3B1E9E (rim) to 7A3FD6 (middle): lime on violet is the complementary pair
    g = Image.radial_gradient("L").resize(size, Image.BILINEAR)
    bg = Image.composite(Image.new("RGB", size, rgb("3B1E9E")), Image.new("RGB", size, rgb("7A3FD6")), g.point(lambda v: min(255, int(v * 1.15)))).convert("RGBA")
    out = over(bg, src)
    # one small gold sparkle: a four-point star up and to the right, clear of the face
    cx, cy, r = size[0] * 0.84, size[1] * 0.17, size[0] * 0.075

    def paint(d, s, o):
        ox, oy = o
        px, py = cx - ox, cy - oy
        pts = []
        for i in range(8):
            a = math.pi / 4 * i - math.pi / 2
            rr = r if i % 2 == 0 else r * 0.32
            pts.append((s(px + rr * math.cos(a)), s(py + rr * math.sin(a))))
        d.polygon(pts, fill=rgb("FFC83D"))
        d.ellipse([s(px - r * 0.17), s(py - r * 0.17), s(px + r * 0.17), s(py + r * 0.17)], fill=rgb("FFF4DC"))

    layer, x0, y0 = shape_layer(size, (cx - r * 1.4, cy - r * 1.4, cx + r * 1.4, cy + r * 1.4), paint)
    out = paste(out, layer, x0, y0)
    return out.convert("RGB").resize((512, 512), Image.LANCZOS)


# -------------------------------------------------------------------------------------------------------------------------- strip
def strip(files, out):
    tw, th, gap = 192, 108, 8
    canvas = Image.new("RGB", (len(files) * tw + (len(files) - 1) * gap, th), rgb("1B1F3B"))
    for i, f in enumerate(files):
        canvas.paste(Image.open(f).convert("RGB").resize((tw, th), Image.LANCZOS), (i * (tw + gap), 0))
    canvas.save(out, optimize=True)
    print("%s: %dx%d, %d kB" % (out, canvas.width, canvas.height, os.path.getsize(out) // 1000))


def main():
    a = sys.argv[1:]
    if len(a) < 3:
        print(__doc__)
        return 2
    target = a[0]
    if target == "strip":
        strip(a[1:-1], a[-1])
        return 0
    raw, final = a[1], a[2]
    k = Image.open(raw).width / 1920.0
    meta = meta_of(raw)
    comp = pathlib.Path(raw).with_name(pathlib.Path(raw).stem.replace("_raw", "") + "_comp.png")
    T = theme()
    if target == "icon":
        build_icon(raw).save(final, optimize=True)
        print("%s: 512x512, %d kB" % (final, os.path.getsize(final) // 1000))
        return 0
    if target == "moment":
        img = load_raw(raw)
        if "glow" in meta:  # the tail's glowing tip: a bloom the renderer does not make
            img = halo(img, k, (meta["glow"][0] * img.width, meta["glow"][1] * img.height), "FFE066", 150, 0.75)
        img = capture_bar(img, k, label_x=470)
        img.save(comp)
        return title(comp, string("CATCH_PERFECT") or "PERFECT!", final, T["Colors.Heading"], 0.50)
    if target == "reward":
        build_reward(raw, k).save(comp)
        return title(comp, "LEGENDARY", final, T["Rarity.Legendary"], 0.52)
    if target == "mystery":
        img = load_raw(raw)
        img = alert_bubble(img, k, (0.70 * img.width, 0.30 * img.height), 0.09 * img.height)
        img.save(comp)
        return title(comp, "WHO'S THAT?", final, T["Colors.Panel"], 0.56)
    if target == "event":
        img = load_raw(raw)
        if "gold" in meta:  # the star tail's bloom (the stars are the hero)
            img = halo(img, k, (meta["gold"][0] * img.width, meta["gold"][1] * img.height), "FFD36B", 260, 0.55)
            img = halo(img, k, (meta["tip"][0] * img.width, meta["tip"][1] * img.height), "FFE9A0", 110, 0.8)
        img.save(comp)
        return title(comp, "HAUNTED NEBULA", final, T["Colors.Panel"], 0.80)
    print("unknown target %r" % target)
    return 2


if __name__ == "__main__":
    sys.exit(main())
