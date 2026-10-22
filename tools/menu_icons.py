#!/usr/bin/env python3
"""The Menu icons (Decision B53): 16 x 16 pixel icons that depict the screen they open, for data/PixelIcons.

Each icon is drawn here as 16 rows of 16 characters (a legend turns a character into a colour) and written to
src/shared/data/PixelIcons.luau as rectangles { x, y, w, h, colour } on a 16 x 16 grid (the file's `Grids` table lists the keys
that are not on the default 8 x 8). The Luau file is the data the game reads; this script is where the drawings live.

    python3 -I tools/menu_icons.py --lua            # print the Luau entries (paste between the MENU ICONS markers)
    python3 -I tools/menu_icons.py --write          # rewrite the block between the markers in PixelIcons.luau
    python3 -I tools/menu_icons.py --sheet out.png  # (--art: from the drawings, not the file) a preview sheet drawn from the Luau data: 1x and 4x, on each icon's tile

The style is the block-cell one (B44): a navy outline one pixel round, three or four colours inside, a lit top-left and a shaded
lower-right. Colours are Theme.Colors keys or six-digit hex strings.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "src" / "shared" / "data" / "PixelIcons.luau"
GRID = 16
BEGIN = "\t-- MENU ICONS BEGIN (tools/menu_icons.py writes this block: the Menu's 16 x 16 icons, Decision B53)"
END = "\t-- MENU ICONS END"

def cog_rows() -> list[str]:
    """A cog drawn by distance and angle, so its eight teeth are the same all round: a ring with teeth, a hole, a lit upper left."""
    import math

    def filled(x: int, y: int) -> str:
        dx, dy = x - 7.5, y - 7.5
        d = math.hypot(dx, dy)
        if d <= 2.4:
            return "hole"
        if d <= 5.6:
            return "body"
        if d <= 7.4:
            angle = math.degrees(math.atan2(dy, dx)) % 45
            if min(angle, 45 - angle) <= 8.5:  # a tooth every 45 degrees, about 17 wide
                return "body"
        return ""

    grid = [[filled(x, y) for x in range(GRID)] for y in range(GRID)]
    rows = []
    for y in range(GRID):
        row = ""
        for x in range(GRID):
            cell = grid[y][x]
            if cell == "hole":
                row += "O"
            elif cell:
                row += "L" if x + y <= 9 else ("D" if x + y >= 20 else "G")
            else:
                near = any(
                    0 <= x + a < GRID and 0 <= y + b < GRID and grid[y + b][x + a] == "body"
                    for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))
                )
                row += "O" if near else "."
        rows.append(row)
    return rows


# The order is the order of the preview sheet and of the file.
ART: dict[str, dict] = {
    # a shopping bag: gold, a red heart on it, a handle, a lit left edge and a shaded right one
    "Shop": {
        "note": "a gold shopping bag with a red heart and a handle",
        "tile": "Confirm",
        "legend": {"O": "Outline", "Y": "Featured", "L": "FFE9A6", "D": "D99A00", "R": "E5383B"},
        "rows": [
            "................",
            ".....OOOOOO.....",
            "....OO....OO....",
            "....O......O....",
            "....O......O....",
            "..OOOOOOOOOOOO..",
            "..OLLLLLLLLLLO..",
            "..OLYYYYYYYYDO..",
            "..OLYRRYYRRYDO..",
            "..OLYRRRRRRYDO..",
            "..OLYRRRRRRYDO..",
            "..OLYYRRRRYYDO..",
            "..OLYYYRRYYYDO..",
            "..OLYYYYYYYYDO..",
            "..ODDDDDDDDDDO..",
            "..OOOOOOOOOOOO..",
        ],
    },
    # a cute green alien head: two antennae with gold tips, big dark eyes with a shine, a small smile
    "Aliens": {
        "note": "a cute green alien head with antennae, big eyes and a smile",
        "tile": "Featured",
        "legend": {"O": "Outline", "G": "7FD27A", "L": "B8F0B0", "D": "4FA84A", "Y": "Featured", "W": "White"},
        "rows": [
            "...OOO....OOO...",
            "...OYO....OYO...",
            "...OOO....OOO...",
            "....O......O....",
            "....O......O....",
            "....OOOOOOOO....",
            "...OLLGGGGGDO...",
            "..OLGGGGGGGGDO..",
            "..OGOWOGGOWOGO..",
            "..OGOOOGGOOOGO..",
            "..OGOOOGGOOOGO..",
            "..OGGGOGGOGGDO..",
            "...OGGGOOGGDO...",
            "....OGGGGGDO....",
            ".....OODDOO.....",
            "................",
        ],
    },
    # an open book: cream pages with lines of text, a brown cover and a blue bookmark
    "Codex": {
        "note": "an open book with cream pages, lines of text and a blue ribbon",
        "tile": "Codex",
        "legend": {"O": "Outline", "C": "Panel", "S": "D9C9A0", "B": "8B5A2B", "R": "Select"},
        "rows": [
            "................",
            "................",
            "..OOOOO..OOOOO..",
            ".OCCCCCOOCCCCCO.",
            ".OCSSSCOOCSSSCO.",
            ".OCCCCCOOCCCCCO.",
            ".OCSSSCOOCSSSCO.",
            ".OCCCCCOOCCCCCO.",
            ".OCSSSCOOCSSSCO.",
            ".OCCCCCOOCCCCCO.",
            ".OCSSCCOOCCSSCO.",
            ".OCCCCCOOCCCCCO.",
            "OBBBBBBOOBBBBBBO",
            "OOOOOOOOOOOOOOOO",
            "................",
            "................",
        ],
    },
    # a rocket on its side pointing up: white hull, red nose and fins, a blue window, an orange flame
    "Ship": {
        "note": "a rocket with a red nose and fins, a blue window and an orange flame",
        "tile": "Select",
        "legend": {"O": "Outline", "W": "White", "S": "BFC3D6", "R": "E5383B", "B": "Select", "F": "FF8A3D", "Y": "Featured"},
        "rows": [
            ".......OO.......",
            "......ORRO......",
            ".....ORRRRO.....",
            ".....OWWWWSO....",
            "....OWWOOWWSO...",
            "....OWOBBOWSO...",
            "....OWOBBOWSO...",
            "....OWWOOWWSO...",
            "..OOOWWWWWWSOOO.",
            ".ORROWWWWWSSORRO",
            ".ORRROWWWWSORRRO",
            ".OORROOOOOOORROO",
            "...OO.OFFO.OO...",
            "......OFYFO.....",
            ".......OFO......",
            "........O.......",
        ],
    },
    # a clipboard with a gold clip, lines of text and a green tick
    "Quests": {
        "note": "a clipboard with a gold clip, lines of text and a green tick",
        "tile": "Heading",
        "legend": {"O": "Outline", "C": "Panel", "S": "D9C9A0", "Y": "Featured", "G": "51DF51", "B": "8B5A2B"},
        "rows": [
            "......OOOO......",
            "..OOOOYYYYOOOO..",
            "..OBBOYYYYOBBO..",
            "..OBBBOOOOBBBO..",
            "..OBCCCCCCCCBO..",
            "..OBCCCCCCGGBO..",
            "..OBCCCCCGGCBO..",
            "..OBGGCCGGCCBO..",
            "..OBCGGGGCCCBO..",
            "..OBCCGGCCCCBO..",
            "..OBCCCCCCCCBO..",
            "..OBCSSSSSSCBO..",
            "..OBCCCCCCCCBO..",
            "..OBBBBBBBBBBO..",
            "..OOOOOOOOOOOO..",
            "................",
        ],
    },
    # a wrapped present: red box, gold ribbon and a bow
    "Gifts": {
        "note": "a wrapped present with a gold ribbon and bow",
        "tile": "Close",
        "legend": {"O": "Outline", "R": "FF4D4D", "L": "FF9A9A", "D": "C42B2B", "Y": "Featured", "W": "FFE9A6"},
        "rows": [
            "................",
            "....OOO..OOO....",
            "...OYYYOOYYYO...",
            "...OYWYYYYWYO...",
            "....OYYYYYYO....",
            "..OOOOOYYOOOOO..",
            "..OLLLLYYLLLLO..",
            "..OOOOOYYOOOOO..",
            "...OLLLYYLLLO...",
            "...ORRRYYRRDO...",
            "...ORRRYYRRDO...",
            "...ORRRYYRRDO...",
            "...ORRRYYRRDO...",
            "...ODDDYYDDDO...",
            "...OOOOOOOOOO...",
            "................",
        ],
    },
    # a cog: a grey ring of teeth round a blue face with a dark hole
    "Settings": {
        "note": "a grey cog with eight teeth and a hole",
        "tile": "Select",
        "legend": {"O": "Outline", "G": "BFC3D6", "L": "F2F4FA", "D": "8A90AD", "H": "2A2F55"},
        "rows": cog_rows(),
    },
    # a gold trophy: a cup with two handles on a stem and a base, a lit side and a star
    "Ranks": {
        "note": "a gold trophy cup with handles, a star, a stem and a base",
        "tile": "Featured",
        "legend": {"O": "Outline", "Y": "Featured", "L": "FFE9A6", "D": "D99A00", "W": "White"},
        "rows": [
            "................",
            "..OOOOOOOOOOOO..",
            "OOOLLLYYYYYDOOO.",
            "OYOLYYYYYYYYDOYO",
            "OYOLYYYWYYYYDOYO",
            "OYOLYYWWWYYYDOYO",
            ".OOLYYYWYYYYDOO.",
            "..OOLYYYYYYDOO..",
            "...OOLYYYYDOO...",
            ".....OOYYDO.....",
            "......OYYO......",
            "......OYDO......",
            ".....OOOOOO.....",
            "....OYYYYYYO....",
            "....ODDDDDDO....",
            "....OOOOOOOO....",
        ],
    },
    # an envelope: cream, a flap folded to a point, a red seal
    "Mail": {
        "note": "a cream envelope with a folded flap and a red seal",
        "tile": "Select",
        "legend": {"O": "Outline", "C": "Panel", "S": "D9C9A0", "W": "White", "R": "E5383B"},
        "rows": [
            "................",
            "................",
            "................",
            ".OOOOOOOOOOOOOO.",
            ".OWOCCCCCCCCOSO.",
            ".OWCOCCCCCCOCSO.",
            ".OWCCOCCCCOCCSO.",
            ".OWCCCOOOOCCCSO.",
            ".OWCCCCRRCCCCSO.",
            ".OWCCCRRRRCCCSO.",
            ".OWCCCCRRCCCCSO.",
            ".OWCCCCCCCCCCSO.",
            ".OSSSSSSSSSSSSO.",
            ".OOOOOOOOOOOOOO.",
            "................",
            "................",
        ],
    },
    # three bars: the menu's own icon (white on navy so it reads on any button)
    "Menu": {
        "note": "three bars, white with a shaded lower edge",
        "tile": "Select",
        "legend": {"O": "Outline", "W": "White", "S": "BFC3D6"},
        "rows": [
            "................",
            "................",
            "..OOOOOOOOOOOO..",
            "..OWWWWWWWWWSO..",
            "..OSSSSSSSSSSO..",
            "..OOOOOOOOOOOO..",
            "................",
            "..OOOOOOOOOOOO..",
            "..OWWWWWWWWWSO..",
            "..OSSSSSSSSSSO..",
            "..OOOOOOOOOOOO..",
            "................",
            "..OOOOOOOOOOOO..",
            "..OWWWWWWWWWSO..",
            "..OSSSSSSSSSSO..",
            "..OOOOOOOOOOOO..",
        ],
    },
    # two friends: a green head and a gold head, shoulders under each
    "Friends": {
        "note": "two friends, a green one and a gold one, heads and shoulders",
        "tile": "Confirm",
        "legend": {"O": "Outline", "G": "7FD27A", "L": "B8F0B0", "Y": "Featured", "W": "FFE9A6", "D": "4FA84A", "E": "D99A00"},
        "rows": [
            "................",
            "................",
            "..OOO......OOO..",
            ".OLGGO....OWYYO.",
            ".OGGGO....OYYYO.",
            ".OGGDO....OYYEO.",
            "..OOO......OOO..",
            ".OOOOO....OOOOO.",
            "OLGGGGO..OWYYYYO",
            "OGGGGDO..OYYYYEO",
            "OGGGGDO..OYYYYEO",
            "ODDDDDO..OEEEEEO",
            "OOOOOOO..OOOOOOO",
            "................",
            "................",
            "................",
        ],
    },
}


def check() -> None:
    for key, icon in ART.items():
        rows = icon["rows"]
        assert len(rows) == GRID, f"{key}: {len(rows)} rows"
        for index, row in enumerate(rows):
            assert len(row) == GRID, f"{key} row {index}: {len(row)} columns ({row!r})"
            for ch in row:
                assert ch == "." or ch in icon["legend"], f"{key} row {index}: {ch!r} is not in the legend"


def rects(icon: dict) -> list[tuple[int, int, int, int, str]]:
    """Whole rectangles that cover the drawing exactly: runs along each row, a run that repeats on the next row grown downward."""
    rows = icon["rows"]
    legend = icon["legend"]
    out: list[list] = []  # [x, y, w, h, colour]
    open_runs: dict[tuple[int, int, str], list] = {}
    for y, row in enumerate(rows):
        runs: dict[tuple[int, int, str], list] = {}
        x = 0
        while x < GRID:
            ch = row[x]
            if ch == ".":
                x += 1
                continue
            start = x
            while x < GRID and row[x] == ch:
                x += 1
            key = (start, x - start, ch)
            if key in open_runs:
                rect = open_runs[key]
                rect[3] += 1
            else:
                rect = [start, y, x - start, 1, legend[ch]]
                out.append(rect)
            runs[key] = rect
        open_runs = runs
    # the outline first, then the colours: a cover that overlaps nothing, so the order is only for reading
    out.sort(key=lambda r: (r[4] != "Outline", r[1], r[0]))
    return [(r[0], r[1], r[2], r[3], r[4]) for r in out]


def luau() -> str:
    lines = [BEGIN]
    for key, icon in ART.items():
        lines.append(f"\t-- {icon['note']}")
        lines.append(f"\t{key} = {{")
        for x, y, w, h, colour in rects(icon):
            lines.append(f'\t\t{{ {x}, {y}, {w}, {h}, "{colour}" }},')
        lines.append("\t},")
    lines.append(END)
    return "\n".join(lines) + "\n"


def write() -> None:
    text = DATA.read_text()
    block = luau()
    if BEGIN in text:
        head, rest = text.split(BEGIN, 1)
        _, tail = rest.split(END + "\n", 1)
        text = head + block + tail
    else:
        raise SystemExit("PixelIcons.luau has no MENU ICONS markers yet")
    DATA.write_text(text)


# The preview sheet, drawn from the Luau data (so it shows what the game draws) ---------------------------------------------

THEME = {
    "Panel": "FFF4DC", "Outline": "1B1F3B", "Confirm": "51DF51", "Close": "FF4D4D", "Select": "68C9FE",
    "Featured": "FFC83D", "Heading": "FFEF4A", "Codex": "A855F7", "White": "FFFFFF", "Black": "000000",
}


def parse_data() -> dict[str, list[tuple[int, int, int, int, str]]]:
    text = DATA.read_text()
    out: dict[str, list[tuple[int, int, int, int, str]]] = {}
    for key in ART:
        match = re.search(r"^\t" + key + r" = \{\n(.*?)^\t\},", text, re.S | re.M)
        if not match:
            raise SystemExit(f"{key} is not in PixelIcons.luau")
        out[key] = [
            (int(a), int(b), int(c), int(d), e)
            for a, b, c, d, e in re.findall(r'\{ (\d+), (\d+), (\d+), (\d+), "(\w+)" \}', match[1])
        ]
    return out


def colour(name: str) -> tuple[int, int, int]:
    value = THEME.get(name, name)
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def sheet(path: Path, from_art: bool = False) -> None:
    from PIL import Image, ImageDraw, ImageFont

    data = {key: rects(icon) for key, icon in ART.items()} if from_art else parse_data()
    keys = list(ART)
    pad = 12
    tile1, tile4 = 16, 64
    cell_w = tile4 + 2 * pad
    label_h = 18
    width = pad + len(keys) * cell_w
    height = label_h + pad + tile4 + 2 * pad + tile1 + 2 * pad + 20
    image = Image.new("RGB", (width, height), colour("Outline"))
    draw = ImageDraw.Draw(image)
    try:
        font = ImageFont.load_default()
    except OSError:
        font = None
    for index, key in enumerate(keys):
        x0 = pad + index * cell_w
        icon = ART[key]
        tile = colour(icon["tile"])
        for scale, y0 in ((4, label_h + pad), (1, label_h + pad + tile4 + 2 * pad)):
            size = GRID * scale
            draw.rectangle([x0, y0, x0 + size - 1, y0 + size - 1], fill=tile)
            for x, y, w, h, name in data[key]:
                draw.rectangle(
                    [x0 + x * scale, y0 + y * scale, x0 + (x + w) * scale - 1, y0 + (y + h) * scale - 1], fill=colour(name)
                )
        draw.text((x0, 4), key, fill=(255, 255, 255), font=font)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(f"wrote {path} ({width}x{height})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lua", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--sheet", type=Path)
    parser.add_argument("--art", action="store_true", help="draw the sheet from the drawings here, not from the Luau file (while drawing)")
    args = parser.parse_args()
    check()
    if args.lua:
        sys.stdout.write(luau())
    if args.write:
        write()
    if args.sheet:
        sheet(args.sheet, args.art)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
