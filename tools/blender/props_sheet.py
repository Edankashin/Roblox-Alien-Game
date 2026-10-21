#!/usr/bin/env python3
"""The props sheet: every block-cell prop (docs/vault/07-alien-game/Props/, the notes `tools/blocky/export_models.py --props` exports) lit,
in rows to scale, each row beside the 5-stud avatar, built by the same route as the game's models (tools/blender/blocky_build.py at the
world cell). The review image for Ethan and the Claude Design canvas (Blocky-Style "Environment", Decision B44).

Two steps, because Blender's Python has no Pillow:

  BPY=<python with bpy>
  $BPY tools/blender/props_sheet.py --out <scratch dir> [--size 520] [--samples 32]     # one lit PNG a row and rows.json (labels' places)
  python3 -I tools/blender/props_sheet.py --compose <scratch dir> --sheet media/studio/2026-10-21/props_v1.jpg

  $BPY tools/blender/props_sheet.py --out <scratch dir> --night      # the Starhollow Forest props at night (Decision B48), then
  python3 -I tools/blender/props_sheet.py --compose <scratch dir> --sheet media/studio/2026-10-21/starhollow_props_v1.jpg

  $BPY tools/blender/props_sheet.py --out <scratch dir> --home       # the home planet's nine props (the house grid, Decision B49), then
  python3 -I tools/blender/props_sheet.py --compose <scratch dir> --sheet media/studio/2026-10-21/home_props_v1.jpg

The rows: World 1's trees and rocks, World 1's small things, World 2, the landmarks, the camp, each on a floor in its world's tone (a
mid tone, so white snow and pale ice read against it). Each prop faces the camera as the game's
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
    ("World 1 Verdant: trees, rocks and the bigger scatter", "#A9C98A",
     ["MeadowTree", "MeadowTreeB", "BlossomTree", "Boulder", "MeadowRock", "MeadowRockB", "Bush", "Log", "Mushroom"]),
    ("World 1 Verdant: the small scatter and the paths", "#A9C98A", ["FlowerPatch", "LilyPad", "Reeds", "Fence", "Lantern", "Signpost"]),
    ("World 2 Frostbyte", "#8EA2B4", ["SnowPine", "SnowPineB", "IceSpire", "IceCrystalCluster", "IceRock", "IceRockB", "SnowBush", "FrozenLog",
                           "SnowDrift", "Icicles", "IceLantern", "HeaterLamp"]),
    ("Landmarks", "#B3AA94", ["CrashWreck", "CaveMouth", "IceCaveMouth", "GeyserVent", "GeyserCone"]),
    ("The shrine and the camp", "#B3AA94", ["Shrine", "Pedestal", "ShrineStone", "ShipHull", "BuildStation", "GatherStation", "SparkStation"]),
]
GAP = 1.5
# `--night`: the Starhollow Forest props (Decision B48) lit as the area is, at night: a deep indigo sky, a faint cool moon, and the
# props' own glow cells as the light sources (each Glow mesh brighter, with a point light in its colour), on a floor of MoonGrass's tone
ROWS_NIGHT = [
    ("Starhollow Forest: the moon trees and the giant glowcaps", "#2B4F58",
     ["MoonTree", "MoonTreeB", "GlowcapGiant", "GlowcapGiantPink", "GlowcapGiantBlue"]),
    ("Starhollow Forest: the floating landmark, the bridge and the moon pool ring", "#2B4F58", ["StarIsland", "ArchBridge", "MoonPoolRing"]),
    ("Starhollow Forest: the path lantern and the scatter", "#2B4F58",
     ["PathLantern", "GlowcapSmall", "GlowFern", "MossStone", "SteppingStone"]),
]
# `--home`: the home planet's house-grid props (data/HomeBuild `prop`), on the home's grass, in daylight
ROWS_HOME = [
    ("The home planet: the rooms (the cabin and the dome 2 x 2 cells, the tower 1 x 1; a cell is 4 studs)", "#A9C98A",
     ["RoomCabin", "RoomDome", "RoomTower"]),
    ("The home planet: the habitats (3 x 3 cells), where caught aliens of each world roam on display", "#A9C98A",
     ["HabitatVerdant", "HabitatFrostbyte"]),
    ("The home planet: the furniture (the fountain 2 x 2 cells, the rest 1 x 1)", "#A9C98A", ["Fountain", "Bench", "Planter", "Flag"]),
]
NIGHT_SKY = (0.035, 0.04, 0.12)
NIGHT_GLOW = 5.0


def night_lights(scene, centre, extent, objs, spec_by_obj):
    """A faint cool moon and fill, then a point light at each Glow mesh in its own colour (the game's PointLights on the glow cells)."""
    from mathutils import Vector
    import bpy
    import blocky_build as B
    moon = bpy.data.lights.new("Moon", "SUN")
    moon.energy = 0.55
    moon.angle = math.radians(6.0)
    moon.color = (0.72, 0.76, 1.0)
    mo = bpy.data.objects.new("Moon", moon)
    scene.collection.objects.link(mo)
    mo.rotation_euler = (-Vector((-0.35, -0.6, 0.72))).to_track_quat("-Z", "Y").to_euler()
    fill = bpy.data.lights.new("Fill", "AREA")
    fill.energy = 18.0 * extent * extent / 4.0
    fill.size = extent * 3.0
    fill.color = (0.55, 0.5, 1.0)
    fo = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fo)
    fo.location = centre + Vector((extent * 3.0, -extent * 2.0, extent * 2.0))
    fo.rotation_euler = (centre - fo.location).to_track_quat("-Z", "Y").to_euler()
    k = 0
    for o in objs:
        if not o.name.endswith("Glow") or o not in spec_by_obj:
            continue
        lo, hi = B.bounds([o])
        size = max(hi - lo)
        light = bpy.data.lights.new("GlowLight%d" % k, "POINT")
        light.energy = min(900.0, 60.0 + 30.0 * size * size)
        light.color = B.lin(spec_by_obj[o])[:3]
        light.shadow_soft_size = max(0.3, size * 0.25)
        lo_obj = bpy.data.objects.new("GlowLight%d" % k, light)
        lo_obj.location = (lo + hi) * 0.5
        scene.collection.objects.link(lo_obj)
        k += 1


def render_rows(out, size, samples, night=False, home=False):
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
    for r, (title, floor, names) in enumerate(ROWS_NIGHT if night else (ROWS_HOME if home else ROWS)):
        scene = B.reset()
        objs = list(B.avatar((0, 0, 0), out_dir=out))
        glow_hex = {}
        x = 2.0 + GAP
        tallest = 5.0
        centres = []
        for name in names:
            spec = S.load(PROPS / ("%s.md" % name))
            lo, hi = S.bounds(S.expand(spec["parts"]))
            w = hi[0] - lo[0]
            x += w / 2
            cx = -(lo[0] + hi[0]) / 2  # Blender X is the spec's -x: the bounds' centre lands on x
            made = B.build(spec, out, offset=(x - cx, -(lo[2] + hi[2]) / 2, 0.0), prefix="R%d%s_" % (r, name), cell=C.WORLD_CELL,
                           glow=NIGHT_GLOW if night else B.GLOW_BUILD)
            objs += made["objects"]
            pal = S.palette(spec)
            for o in made["objects"]:
                if o.name.endswith("Glow") and "glow" in pal:
                    glow_hex[o] = pal["glow"]
            centres.append((name, x, hi[1]))
            x += w / 2 + GAP
            tallest = max(tallest, hi[1])
        aspect = max(2.0, round((x + 2.0) / tallest * 0.82, 2))
        cam, centre, extent = B.tq_camera(scene, objs, yaw=12.0, pitch=16.0, margin=1.08, aspect=aspect)
        if night:
            B.lit_setup(scene, size, samples, sky=NIGHT_SKY, sky_strength=1.0, floor_hex=floor, extent=extent, centre=centre)
            night_lights(scene, centre, extent, objs, glow_hex)
            B.glare(scene, "Fog Glow", 0.6)
        else:
            B.lit_setup(scene, size, samples, floor_hex=floor, extent=extent, centre=centre)
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
        meta.append({"title": title, "png": path.name, "labels": labels, "night": night, "home": home})
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
    night = any(m.get("night") for m, _ in rows)
    home = any(m.get("home") for m, _ in rows)
    head = ("Starhollow Forest props v1 (Decisions B44, B48): %d props at night, lit by their own glow cells, to scale beside the 5-stud avatar"
            if night else ("Home props v1 in block cells (Decisions B44, B49): the house grid's %d props, to scale beside the 5-stud avatar"
                           if home else "Props v1 in block cells (Decision B44): %d props, each lit and to scale in its row beside the 5-stud avatar"))
    d.text((20, 16), head % sum(len(m["labels"]) for m, _ in rows), font=bold, fill="#1B1F3B")
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
    ap.add_argument("--night", action="store_true", help="the Starhollow Forest rows at night (ROWS_NIGHT), lit by their glow cells")
    ap.add_argument("--home", action="store_true", help="the home planet's house-grid props (ROWS_HOME), in daylight")
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
    return render_rows(a.out, a.size, a.samples, night=a.night, home=a.home)


if __name__ == "__main__":
    sys.exit(main())
