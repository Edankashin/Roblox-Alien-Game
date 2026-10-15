#!/usr/bin/env python3
"""List every materials.json slot that uses a dark, busy Roblox material, and flag the warm mid-light ones.

Why: in Studio (2026-10-15, the Mac session) Fabric turned Sparkfox's Body, FF6B35, into a dark maroon in daylight: the
Fabric texture is dark and busy, and it multiplies a saturated mid-light warm colour down. The same could be true of other
bodies, so this prints every slot whose `material` is Fabric, Grass, Slate or Sand with its hex, its relative luminance
(WCAG: sRGB to linear, 0.2126 R + 0.7152 G + 0.0722 B) and whether it has a `texture` key (a slot with a texture is
expected to show its maps instead of the material's own look once its SurfaceAppearance clone is on, to be confirmed in
Studio, so the darkening matters most where `tex` is "-").
A row is flagged WARM when its hex is warm (hue 0 to 65 or 345 to 360 degrees), saturated (HSV saturation at least 0.35) and
mid-light (luminance 0.15 to 0.65). The net is drawn around the one observed case (Sparkfox: hue 16, saturation 0.79,
luminance 0.32), not measured, so a flag means "look at this in daylight", never "this is wrong". Nothing here edits a
colour or a material; changing a slot is a decision for a person looking at it in Studio.

Offline, standard library only. Usage: python3 -I tools/fabric_audit.py [--flagged] [--materials Fabric,Grass,...]
"""
import argparse
import colorsys
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
MATERIALS = ('Fabric', 'Grass', 'Slate', 'Sand')  # dark, busy Roblox material textures
WARM_HUES = ((0.0, 65.0), (345.0, 360.0))  # degrees
MIN_SATURATION = 0.35  # HSV
LUMINANCE_RANGE = (0.15, 0.65)  # relative luminance, 0 black to 1 white


def linear(channel):
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def parse(hex_text):
    if not isinstance(hex_text, str) or len(hex_text) != 6:
        raise ValueError(f'bad hex {hex_text!r}')
    return tuple(int(hex_text[i:i + 2], 16) / 255 for i in (0, 2, 4))


def luminance(hex_text):
    r, g, b = (linear(c) for c in parse(hex_text))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hue_saturation(hex_text):
    h, s, _ = colorsys.rgb_to_hsv(*parse(hex_text))
    return h * 360, s


def is_warm_mid_light(hex_text):
    hue, saturation = hue_saturation(hex_text)
    warm = any(low <= hue <= high for low, high in WARM_HUES)
    low, high = LUMINANCE_RANGE
    return warm and saturation >= MIN_SATURATION and low <= luminance(hex_text) <= high


def rows(root, materials):
    """(kind, model, slot, material, hex, luminance, has texture, flagged) for every slot using one of `materials`."""
    out = []
    for kind, folder in (('species', root / 'assets/models'), ('prop', root / 'assets/models/props')):
        if not folder.is_dir():
            continue
        for path in sorted(folder.glob('*/materials.json')):
            for entry in json.loads(path.read_text()):
                if entry.get('material') in materials:
                    hex_text = entry['hex'].upper()
                    out.append((kind, path.parent.name, entry['name'], entry['material'], hex_text, luminance(hex_text),
                                'texture' in entry, is_warm_mid_light(hex_text)))
    return sorted(out, key=lambda r: (r[3], r[0], r[1], r[2]))


def line(row):
    kind, model, slot, material, hex_text, lum, textured, flagged = row
    hue, saturation = hue_saturation(hex_text)
    return (f'{material:<7} {model + "." + slot:<26} {hex_text}  L {lum:.2f}  hue {hue:3.0f}  sat {saturation:.2f}  '
            f'tex {"yes" if textured else "-"}{"  WARM" if flagged else ""}{"  (prop)" if kind == "prop" else ""}')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--flagged', action='store_true', help='print only the warm mid-light rows')
    parser.add_argument('--materials', default=','.join(MATERIALS), help='comma-separated Roblox materials to audit')
    args = parser.parse_args()
    materials = tuple(name for name in args.materials.split(',') if name)
    try:
        found = rows(ROOT, materials)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('fabric audit: ' + str(exc), file=sys.stderr)
        return 1
    flagged = [row for row in found if row[7]]
    if not args.flagged:
        print(f'{len(found)} slots use {", ".join(materials)} (L = relative luminance, tex = has a texture key):')
        for row in found:
            print('  ' + line(row))
        print()
    print(f'{len(flagged)} warm mid-light slots (hue 0-65 or 345-360, saturation >= {MIN_SATURATION}, '
          f'L {LUMINANCE_RANGE[0]} to {LUMINANCE_RANGE[1]}); Fabric darkened Sparkfox, so look at these in daylight:')
    for row in flagged:
        print('  ' + line(row))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
