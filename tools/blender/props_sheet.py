#!/usr/bin/env python3
"""The props sheet: every block-cell prop (docs/vault/07-alien-game/Props/, the notes `tools/blocky/export_models.py --props` exports) lit,
in rows to scale, each row beside the 5-stud avatar, built by the same route as the game's models (tools/blender/blocky_build.py at the
world cell). The review image for Ethan and the Claude Design canvas (Blocky-Style "Environment", Decision B44).

Two steps, because Blender's Python has no Pillow:

  BPY=<python with bpy>
  $BPY tools/blender/props_sheet.py --out <scratch dir> [--size 520] [--samples 32]     # one lit PNG a row and rows.json (labels' places)
  python3 -I tools/blender/props_sheet.py --compose <scratch dir> --sheet media/studio/2026-10-21/props_v1.jpg

The rows: World 1's trees and rocks, World 1's small things, World 2, the landmarks, the camp. Each prop faces the camera as the game's
front (the note's -Z), turned a little so its side shows.
"""
from __future__ import annotations

import argparse
import json
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
PROPS = ROOT / "docs/vault/07-alien-game/Props"

ROWS = [
    ("World 1 Verdant: trees, rocks and the bigger scatter",
     ["MeadowTree", "MeadowTreeB", "BlossomTree", "Boulder", "MeadowRock", "MeadowRockB", "Bush", "Log", "Mushroom"]),
    ("World 1 Verdant: the small scatter and the paths", ["FlowerPatch", "LilyPad", "Reeds", "Fence", "Lantern", "Signpost"]),
    ("World 2 Frostbyte", ["SnowPine", "SnowPineB", "IceSpire", "IceCrystalCluster", "IceRock", "IceRockB", "SnowBush", "FrozenLog",
                           "SnowDrift", "Icicles", "IceLantern", "HeaterLamp"]),
    ("Landmarks", ["CrashWreck", "CaveMouth", "IceCaveMouth", "GeyserVent", "GeyserCone"]),
    ("The shrine and the camp", ["Shrine", "Pedestal", "ShrineStone", "ShipHull", "BuildStation", "GatherStation", "SparkStation"]),
]
GAP = 1.5


def render_rows(out, size, samples):
    sys.path.insert(0, str(HERE))
    sys.path.insert(0, str(ROOT / "tools/blocky"))
    import bpy
    from bpy_extras.object_utils import world_to_camera_view
    from mathutils import Vector
    import blocky_build as B
    C, S = B.C, B.S
    out = pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)
    meta = []
    for r, (title, names) in enumerate(ROWS):
        scene = B.reset()
        objs = list(B.avatar((0, 0, 0), out_dir=out))
        x = 2.0 + GAP
        tallest = 5.0
        centres = []
        for name in names:
            spec = S.load(PROPS / ("%s.md" % name))
            lo, hi = S.bounds(S.expand(spec["parts"]))
            w = hi[0] - lo[0]
            x += w / 2
            cx = -(lo[0] + hi[0]) / 2  # Blender X is the spec's -x: the bounds' centre lands on x
            made = B.build(spec, out, offset=(x - cx, -(lo[2] + hi[2]) / 2, 0.0), prefix="R%d%s_" % (r, name), cell=C.WORLD_CELL)
            objs += made["objects"]
            for o in made["objects"]:
                if o.name.endswith("Glow"):
                    pass
            centres.append((name, x, hi[1]))
            x += w / 2 + GAP
            tallest = max(tallest, hi[1])
        aspect = max(2.0, round((x + 2.0) / tallest * 0.82, 2))
        cam, centre, extent = B.tq_camera(scene, objs, yaw=12.0, pitch=16.0, margin=1.08, aspect=aspect)
        B.lit_setup(scene, size, samples, extent=extent, centre=centre)
        B.add_lights(scene, centre, extent)
        scene.render.resolution_x = int(size * aspect)
        scene.render.resolution_y = size
        path = out / ("props_row%d.png" % r)
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        bpy.context.view_layer.update()
        labels = []
        for name, px, top in centres:
            p = world_to_camera_view(scene, cam, Vector((px, 0.0, 0.0)))
            labels.append({"name": name, "u": p.x, "v": 1.0 - p.y})
        meta.append({"title": title, "png": path.name, "labels": labels})
        print("row %d: %s (%d props)" % (r, path, len(names)), flush=True)
    (out / "rows.json").write_text(json.dumps(meta, indent=1))
    return 0


def compose(folder, sheet):
    from PIL import Image, ImageDraw, ImageFont
    sys.path.insert(0, str(ROOT / "tools/blocky"))
    import spec as S
    folder = pathlib.Path(folder)
    meta = json.loads((folder / "rows.json").read_text())
    try:
        bold = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 22)
        small = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 15)
        reg = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 13)
    except OSError:
        bold = small = reg = ImageFont.load_default()
    width = 2600
    rows = []
    for m in meta:
        im = Image.open(folder / m["png"]).convert("RGB")
        scale = width / im.width
        im = im.resize((width, int(im.height * scale)), Image.Resampling.LANCZOS)
        rows.append((m, im))
    H = 110 + sum(im.height + 96 for _, im in rows)
    out = Image.new("RGB", (width + 40, H), "#F6F0E6")
    d = ImageDraw.Draw(out)
    d.text((20, 16), "Props v1 in block cells (Decision B44): %d props, each lit and to scale in its row beside the 5-stud avatar" %
           sum(len(m["labels"]) for m, _ in rows), font=bold, fill="#1B1F3B")
    d.text((20, 50), "docs/vault/07-alien-game/Props/<Name>.md -> tools/blocky/export_models.py --props -> assets/models/props/<Name>/. World cell 0.25 studs; "
           "glow cells become Neon. Under each name: the triangles exported and the budget, and the collision.", font=reg, fill="#5F6375")
    y = 86
    for m, im in rows:
        d.text((20, y), m["title"], font=bold, fill="#1B1F3B")
        y += 32
        out.paste(im, (20, y))
        for lab in m["labels"]:
            spec = S.load(PROPS / ("%s.md" % lab["name"]))
            notes = ROOT / "assets/models/props" / lab["name"] / "notes.md"
            tris = "?"
            if notes.exists():
                for line in notes.read_text().splitlines():
                    if line.startswith("- Triangles:"):
                        tris = line.split(":", 1)[1].split()[0]
            cx = 20 + lab["u"] * im.width
            t1 = lab["name"]
            t2 = "%s / %s tris, %s" % (tris, spec["front"].get("budget"), spec["front"].get("collision"))
            for t, f, dy, col in ((t1, small, 6, "#1B1F3B"), (t2, reg, 26, "#5F6375")):
                tw = d.textlength(t, font=f)
                d.text((cx - tw / 2, y + im.height + dy), t, font=f, fill=col)
        y += im.height + 64
    pathlib.Path(sheet).parent.mkdir(parents=True, exist_ok=True)
    out.save(sheet, quality=90)
    print(sheet)
    return 0


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", help="a scratch folder for the row renders (never assets/models)")
    ap.add_argument("--size", type=int, default=520, help="each row's height in pixels")
    ap.add_argument("--samples", type=int, default=32)
    ap.add_argument("--compose", help="the folder of row renders to compose (no Blender)")
    ap.add_argument("--sheet", default=str(ROOT / "media/studio/2026-10-21/props_v1.jpg"))
    a = ap.parse_args(argv)
    if a.compose:
        return compose(a.compose, a.sheet)
    if not a.out:
        ap.error("pass --out <scratch dir> (with Blender) or --compose <dir>")
    if "assets/models" in str(pathlib.Path(a.out).resolve()):
        print("refusing to write under assets/models")
        return 2
    return render_rows(a.out, a.size, a.samples)


if __name__ == "__main__":
    sys.exit(main())
