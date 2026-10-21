#!/usr/bin/env python3
"""The home planet preview (world 0, Decision B49 launch polish): the house plot as Services/Meadow builds it, dressed with the nine
block-cell home props a player can place (data/HomeBuild), in daylight. Headless Blender (bpy 5.0).

What is drawn, from src/shared/data/Home.luau: the floor in GrassTop columns (2 x 1 x 2 studs, the tile's block), the plot (PlotCells x
PlotCellStuds a side, PlotOffsetStuds past the camp pad on +Z) in Path cobbles, the edge of the camp pad and the cobbled walk to it (the
walk is the preview's, the game has none), and on the plot one example layout on its 4-stud cells: the two habitats in the front row
with two aliens on display in each (at their authored size; the game draws them at Habitats.DisplayScale), the fountain in the middle
with a flag and two planters, and the cabin, the tower with a bench beside it and the dome along the back. Each item faces the camp, as a player would
turn it. The props and the aliens come through the same route as the game's models (tools/blender/blocky_build.py on the spec notes).

  BPY=<python with bpy>
  $BPY tools/blender/home_preview.py --out <scratch dir> [--size 1600] [--samples 32]

Writes home_preview.png into --out (a scratch folder, never assets/models); the review copy is media/studio/2026-10-21/home_preview_v1.jpg.
"""
from __future__ import annotations

import argparse
import math
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools/blocky"))

import bpy  # noqa: E402

import blocky_build as B  # noqa: E402
import blocky_scene as BS  # noqa: E402
import world_tiles as WT  # noqa: E402

C, S = B.C, B.S
PROPS = ROOT / "docs/vault/07-alien-game/Props"
CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
HOME = ROOT / "src/shared/data/Home.luau"


def home_number(key):
    match = re.search(r"^\s*%s = ([\d.]+)," % key, HOME.read_text(), re.M)
    if not match:
        raise SystemExit("home_preview: %s not found in data/Home.luau" % key)
    return float(match[1])


PAD_R = home_number("CampPadRadius")
CELLS, CELL = int(home_number("PlotCells")), home_number("PlotCellStuds")
SIDE = CELLS * CELL
PLOT_Z0 = PAD_R + home_number("PlotOffsetStuds")       # the plot's near edge on +Z (Blender +Y)
PLOT_TOP = 1.25                                          # the cobbles stand a quarter stud over the grass (the game's plot is 0.3)
GROUND_TOP = 1.0
COLUMN = 2
X0, X1, Y0, Y1 = -22, 22, -4, int(PLOT_Z0 + SIDE) + 10
GRASS, DIRT, PATH = WT.TILES["GrassTop"][2], WT.TILES["Dirt"][2], WT.TILES["Path"][2]
PAD = "#FFF4DC"                                          # data/Home CampPadColor

# (note, cell x, cell z, cells wide, cells deep) on the plot, counted from its -X, near corner as World.HomeRenderer does
LAYOUT = [
    ("HabitatVerdant", 0, 0, 3, 3), ("HabitatFrostbyte", 3, 0, 3, 3),
    ("Planter", 0, 3, 1, 1), ("Flag", 1, 3, 1, 1), ("Fountain", 2, 3, 2, 2), ("Planter", 5, 3, 1, 1),
    ("RoomCabin", 0, 4, 2, 2), ("RoomTower", 2, 5, 1, 1), ("Bench", 3, 5, 1, 1), ("RoomDome", 4, 4, 2, 2),
]
# aliens on display: (species note, plot x, plot z in studs from the plot's near-left corner, yaw)
DISPLAY = [("Mossbop", 3.5, 4.0, -20), ("Sparkfox", 8.0, 6.5, 25), ("Pengoo", 16.0, 4.5, 10), ("Snowbun", 20.0, 7.0, -30)]
AVATAR = (1.0, PLOT_Z0 - 3.0, 200)


def on_plot(x, y):
    return -SIDE / 2 <= x <= SIDE / 2 and PLOT_Z0 <= y <= PLOT_Z0 + SIDE


def ground_spec():
    parts = []
    for i in range((X1 - X0) // COLUMN):
        for j in range((Y1 - Y0) // COLUMN):
            x, y = X0 + COLUMN * i + 1, Y0 + COLUMN * j + 1
            name = "c%d_%d" % (i, j)
            if on_plot(x, y):
                parts.append({"name": name, "slot": "Accessory", "material": "stone", "size": [COLUMN, PLOT_TOP, COLUMN], "at": [-x, PLOT_TOP / 2, y]})
            elif math.hypot(x, y) < PAD_R:
                parts.append({"name": name, "slot": "Trim", "material": "stone", "size": [COLUMN, GROUND_TOP + 0.25, COLUMN],
                              "at": [-x, (GROUND_TOP + 0.25) / 2, y]})
            elif abs(x) < 3 and y < PLOT_Z0:
                parts.append({"name": name, "slot": "Accessory", "material": "stone", "size": [COLUMN, GROUND_TOP, COLUMN], "at": [-x, GROUND_TOP / 2, y]})
            else:
                parts.append({"name": name, "slot": "Body", "material": "grass", "size": [COLUMN, GROUND_TOP, COLUMN], "at": [-x, GROUND_TOP / 2, y]})
    front = {"id": "HomeGround", "palette": [GRASS, DIRT, PATH, PAD], "roles": ["body", "second", "accent", "trim"]}
    floor = {"name": "Floor", "slot": "BodyDark", "size": [X1 - X0 + 2, 1, Y1 - Y0 + 2], "at": [0, -0.5, (Y0 + Y1) / 2], "rot": [0, 0, 0],
             "shape": "box", "moves": "none", "bevel": False}
    return {"front": front, "parts": [S.normalise(p, k) for k, p in enumerate(parts)], "face": None}, [floor]


def build(out):
    scene = B.reset()
    ground, hidden = ground_spec()
    made = B.build(ground, out, cell=C.WORLD_CELL, hidden_by=hidden)
    print("ground: %d blocks, %d triangles" % (len(ground["parts"]), made["tris"]), flush=True)
    left = -SIDE / 2
    for n, (note, cx, cz, w, d) in enumerate(LAYOUT):
        spec = S.load(PROPS / ("%s.md" % note))
        lo, hi = S.bounds(S.expand(spec["parts"]))
        # the export puts the bounds' bottom centre on the pivot, and the renderer stands that on the footprint's centre
        X = left + (cx + w / 2) * CELL + (lo[0] + hi[0]) / 2
        Y = PLOT_Z0 + (cz + d / 2) * CELL - (lo[2] + hi[2]) / 2
        BS.place(spec, out, X, Y, PLOT_TOP, 0.0, prefix="H%d_" % n, cell=C.WORLD_CELL)
    for n, (note, px, pz, yaw) in enumerate(DISPLAY):
        spec = S.load(CREATURES / ("%s.md" % note))
        BS.place(spec, out, left + px, PLOT_Z0 + pz, PLOT_TOP + 0.25, yaw, prefix="A%d_" % n)
    X, Y, yaw = AVATAR
    B.build(B.avatar_spec(), out, offset=(X, Y, GROUND_TOP), cell=C.WORLD_CELL, rot=(0, 0, math.radians(yaw)))
    BS.world_and_sun(scene)
    return scene


def render(scene, out, size, samples):
    BS.camera(scene, "home", (24.0, PLOT_Z0 - 30.0, 30.0), (0.5, PLOT_Z0 + SIDE / 2 - 1.0, 2.0), 30.0)
    scene.render.resolution_x = size
    scene.render.resolution_y = int(size * 9 / 16)
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 4
    scene.cycles.use_denoising = True
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    scene.render.filepath = str(pathlib.Path(out) / "home_preview.png")
    bpy.ops.render.render(write_still=True)
    print("rendered %s" % scene.render.filepath, flush=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", required=True, help="a scratch folder (never assets/models)")
    ap.add_argument("--size", type=int, default=1600, help="width in pixels (16:9)")
    ap.add_argument("--samples", type=int, default=32)
    a = ap.parse_args(argv)
    if "assets/models" in str(pathlib.Path(a.out).resolve()):
        print("refusing to write under assets/models")
        return 2
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    render(build(out), out, a.size, a.samples)
    return 0


if __name__ == "__main__":
    sys.exit(main())
