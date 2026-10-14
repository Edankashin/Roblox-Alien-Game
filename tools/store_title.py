#!/usr/bin/env python3
"""Put a short outlined title on a store thumbnail: Fredoka One, thick navy outline, soft drop shadow.

  python3 -I tools/store_title.py IN.png "CATCH CUTE ALIENS" OUT.png [--pos top|bottom] [--fill HEX]

The text is one line sized so its outer edge (outline included) spans --width of the image; a real newline
in the text makes two lines, the widest one spanning. The outline is --outline-pct of the image height (2.5%).
Defaults are the game's colours: outline Theme.Colors.Outline 1B1F3B, fill Theme.Colors.Panel cream FFF4DC
(Legendary gold is Theme.Rarity.Legendary F59E0B). The result is saved as a PNG, quantised to 256 colours
when it would pass 1 MB, as the renders are. Font: assets/fonts/FredokaOne.ttf (SIL Open Font License).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "fonts", "FredokaOne.ttf")
MAX_BYTES = 1_000_000


def rgb(hex_colour):
    h = hex_colour.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def fit(draw, text, target, stroke):
    """Largest font size whose text, outline included, spans target px (ink width is linear in size)."""
    l, _, r, _ = draw.multiline_textbbox((0, 0), text, font=ImageFont.truetype(FONT, 100), align="center")
    return max(10, int((target - 2 * stroke) * 100 / (r - l)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("text", help="the title; use a real newline (or \\n) for two lines")
    ap.add_argument("out")
    ap.add_argument("--pos", choices=("top", "bottom"), default="bottom", help="which third carries the title")
    ap.add_argument("--fill", default="FFF4DC", help="fill colour, hex")
    ap.add_argument("--outline", default="1B1F3B", help="outline colour, hex")
    ap.add_argument("--width", type=float, default=0.70, help="fraction of the image width the text spans")
    ap.add_argument("--outline-pct", type=float, default=2.5, help="outline thickness, percent of image height")
    ap.add_argument("--margin", type=float, default=0.03, help="gap from the image edge, fraction of height")
    a = ap.parse_args()
    text = a.text.replace("\\n", "\n")

    img = Image.open(a.src).convert("RGB")
    w, h = img.size
    stroke = round(a.outline_pct / 100 * h)
    probe = ImageDraw.Draw(img)

    size = fit(probe, text, a.width * w, stroke)
    # The outline eats a single space, so give each word gap about two outline widths and fit again.
    gap = max(1, round(2.2 * stroke / ImageFont.truetype(FONT, size).getlength(" ")))
    text = text.replace(" ", " " * gap)
    size = fit(probe, text, a.width * w, stroke)
    font = ImageFont.truetype(FONT, size)
    kw = dict(font=font, align="center", spacing=int(stroke * 0.3), stroke_width=stroke)
    l, t, r, b = probe.multiline_textbbox((0, 0), text, **kw)
    x = (w - (r - l)) / 2 - l
    y = a.margin * h - t if a.pos == "top" else h - a.margin * h - b

    # Soft drop shadow: the same outlined shape in dark navy, nudged down and blurred.
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).multiline_text((x, y + stroke * 0.35), text, fill=255, stroke_fill=255, **kw)
    mask = mask.filter(ImageFilter.GaussianBlur(stroke * 0.3)).point(lambda v: int(v * 0.5))
    img.paste((10, 12, 30), mask=mask)
    ImageDraw.Draw(img).multiline_text((x, y), text, fill=rgb(a.fill), stroke_fill=rgb(a.outline), **kw)

    img.save(a.out, optimize=True)
    if os.path.getsize(a.out) > MAX_BYTES:
        img.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG).save(a.out, optimize=True)
    nbytes = os.path.getsize(a.out)
    print(f"{a.out}: {w}x{h}, font {size}px, outline {stroke}px, ink {int(r - l)}x{int(b - t)}px at {a.pos}, {nbytes / 1000:.0f} kB")
    return 0 if nbytes <= MAX_BYTES else 1


if __name__ == "__main__":
    sys.exit(main())
