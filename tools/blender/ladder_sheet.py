"""The rank ladder: every <Id>V2 prototype on one sheet, a row per tier.

Usage: python3 -I tools/blender/ladder_sheet.py <folder> <out.jpg>
<folder> holds models/<Id>V2/notes.md (the height) and renders/<Id>V2_tq.jpg, the three-quarter
view from review_views.py (--views tq --size 320 --samples 32 --backdrop F3EDE2), one call per species.
"""
import re
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

L = Path(sys.argv[1]); out = Path(sys.argv[2])
F = "/usr/share/fonts/truetype/liberation/LiberationSans-%s.ttf"
def font(n, b=False): return ImageFont.truetype(F % ("Bold" if b else "Regular"), n)
ROWS = [
    ("Common", "B0B0B0", "cute", [("Mossbop","Moop"),("Pebblet","Pebblet"),("Glimmo","Glim"),("Twiglet","Twiglo"),("Puffpuff","Dandel"),("Flufflet","Mitt"),("Snowbun","Flurra"),("Drippo","Dreep"),("Chipmole","Digling"),("Kettlepuff","Kettlet")]),
    ("Uncommon", "57F96C", "cute", [("Snailbyte","Snibble"),("Buzzlebee","Buzzik"),("Lanternewt","Lantrin"),("Pengoo","Pengoo"),("Flapsicle","Eekle"),("Toastoad","Soakum"),("Emberchin","Sizz")]),
    ("Rare", "3B82F6", "cute to cool", [("Rocklobber","Boulden"),("Zapfinch","Zirrit"),("Sparkfox","Vixa"),("Reindazzle","Blinkar"),("Shellberg","Floe"),("Capybubble","Snorzo")]),
    ("Epic", "C026D3", "cool to fierce", [("Thunderhog","Voltus"),("Frostfang","Sabrek"),("Gloomoth","Iridia"),("Shimmerlynx","Aurelyx")]),
    ("Legendary", "F59E0B", "fierce", [("Gaiabloom","Gaira"),("Skaddle","Skadra")]),
    ("Cosmic, Secret", "EC4899", "spectacular", [("Radish","Raddis"),("Panpipe","Syrinx")]),
]
T = 180; PAD = 12; LEFT = 200; HEAD = 96
W = LEFT + 10 * (T + PAD) + PAD
H = HEAD + len(ROWS) * (T + 64) + 40
img = Image.new("RGB", (W, H), "#F6F0E6"); d = ImageDraw.Draw(img)
d.text((PAD, 14), "The rank ladder: all 31 redesigns, one row per tier (three-quarter view, each framed to its own size)", font=font(26, True), fill="#1B1F3B")
d.text((PAD, 50), "Prototype recipes on scratch builds, nothing under assets/models changed. Height in studs under each name. Fenrir (Cosmic) is the hero built by hand; the three event species are not in this pass.", font=font(16), fill="#555555")
y = HEAD
for tier, hexc, mood, items in ROWS:
    col = "#" + hexc
    d.rectangle([PAD, y, PAD + 8, y + T + 40], fill=col)
    d.text((PAD + 18, y + 8), tier, font=font(22, True), fill="#1B1F3B")
    d.text((PAD + 18, y + 38), "%d species" % len(items), font=font(15), fill="#555555")
    d.text((PAD + 18, y + 60), "mood: " + mood, font=font(15), fill="#555555")
    x = LEFT
    for sid, name in items:
        p = L / "renders" / ("%sV2_tq.jpg" % sid)
        tile = Image.open(p).convert("RGB").resize((T, T), Image.LANCZOS) if p.exists() else Image.new("RGB", (T, T), "#DDDDDD")
        img.paste(tile, (x, y))
        d.rectangle([x, y, x + T - 1, y + T - 1], outline=col, width=3)
        h = ""
        notes = L / "models" / ("%sV2" % sid) / "notes.md"
        try:
            m = re.search(r"Height:\s*([0-9]+(?:\.[0-9]+)?)", notes.read_text())
            if m: h = "%.1f studs" % float(m.group(1))
        except OSError:
            pass
        d.text((x + 4, y + T + 4), name, font=font(17, True), fill="#1B1F3B")
        d.text((x + 4, y + T + 24), h, font=font(13), fill="#666666")
        x += T + PAD
    y += T + 64
img.save(out, quality=88)
print(out, img.size)
