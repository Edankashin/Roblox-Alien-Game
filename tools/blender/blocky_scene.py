#!/usr/bin/env python3
"""World 1 landscape sample: a 48 x 32 stud meadow diorama built from the same block cells as the creatures (Decision B44), rendered in
headless Blender (bpy 5.0). The "Environment" section of docs/vault/06-art-pipelines/Blocky-Style.md. `--world 2` builds the Frostbyte
diorama instead (the "World 2: Frostbyte palette" subsection): snow over packed snow and ice, a frozen pond, an ice cave mouth at the foot
of a packed-snow cliff, snow pines, ice crystals, snow rocks, the camp's heater as the one warm light, and the six World 2 aliens.

Everything comes through the creature route:

  * the ground is 2 x 1 x 2 stud blocks of the four kinds in docs/vault/07-alien-game/Props/GrassBlock.md (grass over dirt, a cobbled path,
    the pond's water over its bed), stacked on a height map with a step up to a plateau and a ledge, at the world cell (4 cells a stud);
    hidden faces are culled, the diorama's underside too
  * the props are the spec notes in docs/vault/07-alien-game/Props/ (Tree, Rock, Crystal, Ship, Flower), built by
    tools/blender/blocky_build.py's `build` exactly as a creature is, at the world cell
  * the seven World 1 creatures (docs/vault/07-alien-game/Creatures/) and the 5-stud avatar stand in it to scale, each on its own atlas

Two renders: the hero shot (a three-quarter game camera, soft daylight, World 1's sky) and a second, lower angle among the creatures.

  BPY=<python with bpy>
  $BPY tools/blender/blocky_scene.py --out <scratch dir> [--size 1920] [--samples 64] [--views hero,low] [--no-creatures] [--world 2]

Writes world1_hero.png and world1_low.png (world2_... with --world 2) and the atlases into --out, a scratch folder (never assets/models).
"""
from __future__ import annotations

import argparse
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools/blocky"))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import blocky_build as B  # noqa: E402

C, S, SH = B.C, B.S, B.SH
PROPS = ROOT / "docs/vault/07-alien-game/Props"
CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"

# ------------------------------------------------------------------------------------------------ the layout (Blender space: X right as the
# hero camera sees it, Y back, Z up; one unit a stud). The ground is a grid of 2-stud columns, i across X and j across Y.
WIDTH, DEPTH, COLUMN = 48, 32, 2
NI, NJ = WIDTH // COLUMN, DEPTH // COLUMN
MEADOW = 3          # the meadow's top, in studs (two dirt blocks and the grass)
PLATEAU = 4         # the step up at the back
LEDGE = 5           # the high ledge at the back left, where the crystal sits
POND_BED, WATER_TOP = 2, 2.75
POND = {(i, j) for i in range(15, 20) for j in range(2, 6)} - {(15, 2), (19, 2), (15, 5), (19, 5)}
PATH = [(12, 0), (12, 1), (11, 1), (11, 2), (11, 3), (10, 3), (10, 4), (10, 5), (9, 5), (9, 6), (8, 6), (8, 7), (7, 7), (7, 8)]
# World 1's sky: a day blue over a pale warm horizon (Lighting.luau's Verdant haze, 210 190 120, warms the horizon); the sun warm white
SKY_ZENITH, SKY_HORIZON = "#62B3EC", "#D8EEF5"
SUN_COLOUR = (1.0, 0.95, 0.86)
FLOWER_COLOURS = ("#FF8FB0", "#FFD34D", "#F7F3EA")
# (note, X, Y, yaw degrees: positive turns the front toward +X, the hero camera's side)
CREATURE_PLACES = [
    ("Mossbop", -0.5, -11.0, 26), ("Buzzlebee", -6.0, -9.5, 32), ("Sparkfox", 5.5, -11.5, 20), ("Thunderhog", 8.5, -1.5, 28),
    ("Gaiabloom", 15.5, 2.5, 22), ("Radish", -3.0, 11.0, 18), ("Panpipe", 11.5, 11.5, 30),
]
AVATAR_PLACE = (-3.5, -5.5, 25)
PROP_PLACES = [  # (note, X, Y, yaw, extra Euler x degrees, sink studs)
    ("Tree", 19.0, 12.0, 15, 0, 0.0), ("Tree", -20.0, -11.5, -20, 0, 0.0),
    ("Rock", 3.0, 3.5, 10, 0, 0.0), ("Rock", 19.5, -13.0, -25, 0, 0.0), ("Rock", -8.5, 14.0, 40, 0, 0.0),
    ("Crystal", -19.0, 12.5, 20, 0, 0.0),
    ("Ship", -13.5, -3.5, -35, 12, 0.7),
]


def column_centre(i, j):
    return -WIDTH / 2 + COLUMN * i + COLUMN / 2, -DEPTH / 2 + COLUMN * j + COLUMN / 2


def height_map():
    """{(i, j): (top, kind)}: kind is grass, path or water (water's top is the bed; the water block sits on it)."""
    out = {}
    for i in range(NI):
        for j in range(NJ):
            top = MEADOW
            if j >= 11 or (j == 10 and 14 <= i <= 18):
                top = PLATEAU
            if (j >= 13 and i <= 6) or (j == 12 and i <= 3):
                top = LEDGE
            if (i, j) in ((2, 3), (3, 3), (2, 4)):
                top = PLATEAU
            kind = "grass"
            if (i, j) in POND:
                top, kind = POND_BED, "water"
            elif (i, j) in PATH:
                kind = "path"
            out[(i, j)] = (top, kind)
    return out


def ground_at(x, y, hm):
    i = min(NI - 1, max(0, int((x + WIDTH / 2) // COLUMN)))
    j = min(NJ - 1, max(0, int((y + DEPTH / 2) // COLUMN)))
    top, kind = hm[(i, j)]
    return WATER_TOP if kind == "water" else top


def ground_spec(hm):
    """The ground as one spec: GrassBlock's palette and its four kinds stacked on the height map, in spec space (x = -X, z = Y)."""
    gb = S.load(PROPS / "GrassBlock.md")
    kinds = {p["name"]: p for p in gb["parts"]}
    parts = []

    def block(name, kind, x, y0, h, z):
        k = kinds[kind]
        parts.append(S.normalise({"name": name, "slot": k["slot"], "material": k["material"], "size": [COLUMN, h, COLUMN],
                                  "at": [-x, y0 + h / 2, z]}))
    for (i, j), (top, kind) in sorted(hm.items()):
        x, y = column_centre(i, j)
        for level in range(int(top)):
            last = level == int(top) - 1
            if not last or kind == "water":
                block("d%d_%d_%d" % (i, j, level), "Dirt", x, level, 1, y)
            elif kind == "path":
                block("p%d_%d" % (i, j), "Path", x, level, 1, y)
            else:
                block("g%d_%d" % (i, j), "Grass", x, level, 1, y)
        if kind == "water":
            block("w%d_%d" % (i, j), "Water", x, top, WATER_TOP - top, y)
    floor = {"name": "Floor", "slot": "BodyDark", "size": [WIDTH + 2, 1, DEPTH + 2], "at": [0, -0.5, 0], "rot": [0, 0, 0], "shape": "box",
             "moves": "none", "bevel": False}
    spec = {"front": dict(gb["front"], id="Ground"), "parts": parts, "face": None}
    return spec, [floor]


def debris(x, y, z):
    """Three ground blocks the crash threw up round the ship's nose: half-size grass blocks tilted in the turf (GrassBlock's kinds)."""
    gb = S.load(PROPS / "GrassBlock.md")
    grass = next(p for p in gb["parts"] if p["name"] == "Grass")
    parts = []
    for k, (dx, dz, rx, rz) in enumerate(((-1.25, -1.5, 20, 15), (1.0, -2.0, -15, 20), (-2.25, 0.75, 15, -20))):
        parts.append(S.normalise({"name": "Clod%d" % k, "slot": "Body", "material": "grass", "size": [1, 0.5, 1],
                                  "at": [dx, 0.25 + 0.0625 * k, dz], "rot": [rx, 0, rz]}))
    return {"front": dict(gb["front"], id="Debris"), "parts": parts, "face": None}


# ------------------------------------------------------------------------------------------------ World 2 Frostbyte (the same grid; its
# own height map, ground kinds from Props/SnowBlock.md, props, places, sky and sun; World 1's values above are untouched)
W2_FIELD = 3          # the snowfield's top: two packed-snow blocks and the snow
W2_RISE = 4           # the step up at the back
W2_LEDGE = 5          # the ledge at the back right, where a crystal stands
W2_CLIFF = 9          # the packed-snow cliff behind the cave mouth, back left: its exposed sides show the strata
W2_POND_BED, W2_ICE_TOP = 2, 2.75
W2_POND = {(i, j) for i in range(14, 19) for j in range(2, 7)} - {(14, 2), (18, 2), (14, 6), (18, 6), (14, 3), (18, 6)}
W2_CLIFF_COLS = {(i, j) for i in range(1, 11) for j in range(14, 16)} | {(i, 13) for i in range(2, 4)}
W2_ICE_FLOOR = {(5, 12), (6, 12), (7, 12), (6, 11), (5, 13), (6, 13), (7, 13), (8, 13), (4, 13)}
W2_TRAIL = [(12, 0), (12, 1), (11, 2), (11, 3), (10, 4), (10, 5), (9, 6), (9, 7), (8, 8), (8, 9), (7, 10), (7, 11)]
# Frostbyte's sky: Lighting.luau's world 2 look (atmosphere 200 220 240 over a decay of 160 190 220, a tint of 235 245 255, a soft sun):
# a cold blue zenith over a pale, hazy horizon; the sun a soft cool white, lower and wider than Verdant's
W2_SKY_ZENITH, W2_SKY_HORIZON = "#78A8D6", "#DDE8F2"
W2_SUN_COLOUR = (0.95, 0.97, 1.0)
W2_CREATURE_PLACES = [
    ("Flufflet", -1.5, -8.5, 24), ("Pengoo", 3.5, -12.5, 32), ("Reindazzle", -7.0, -11.5, 16), ("Frostfang", 1.5, -2.0, 28),
    ("Skaddle", -15.5, 1.5, 24), ("Fenripup", 13.0, 9.0, 42),
]
W2_AVATAR_PLACE = (-6.5, -4.5, 22)
W2_PROP_PLACES = [  # (note, X, Y, yaw, extra Euler x degrees, sink studs)
    ("PineTree", 20.5, 13.0, 15, 0, 0.0), ("PineTree", -21.0, -11.0, -20, 0, 0.0), ("PineTree", 21.5, -11.5, 35, 0, 0.0),
    ("PineTree", -21.5, 9.0, 10, 0, 0.0),
    ("SnowRock", 5.5, 4.5, 10, 0, 0.0), ("SnowRock", 17.5, -4.5, -25, 0, 0.0), ("SnowRock", -16.5, -9.0, 40, 0, 0.0),
    ("IceCrystal", 21.0, 7.5, 20, 0, 0.0), ("IceCrystal", 9.0, -13.5, -15, 0, 0.0),
    ("IceArch", -11.0, 11.0, 12, 0, 0.0),
    ("Heater", -10.0, -8.0, 30, 0, 0.0),
]


def height_map2():
    """{(i, j): (top, kind)} for Frostbyte: kind is snow, trail, ice, cliff or frozen (the pond: top is the bed; the ice block sits on it)."""
    out = {}
    for i in range(NI):
        for j in range(NJ):
            top = W2_FIELD
            if j >= 11 or (j == 10 and 3 <= i <= 8):
                top = W2_RISE
            if (j >= 13 and i >= 18) or (j == 12 and i >= 21):
                top = W2_LEDGE
            if (i, j) in ((20, 4), (21, 4), (20, 5)):
                top = W2_RISE
            kind = "snow"
            if (i, j) in W2_CLIFF_COLS:
                top, kind = W2_CLIFF, "cliff"
            elif (i, j) in W2_POND:
                top, kind = W2_POND_BED, "frozen"
            elif (i, j) in W2_ICE_FLOOR:
                kind = "ice"
            elif (i, j) in W2_TRAIL:
                kind = "trail"
            out[(i, j)] = (top, kind)
    return out


def ground_at2(x, y, hm):
    i = min(NI - 1, max(0, int((x + WIDTH / 2) // COLUMN)))
    j = min(NJ - 1, max(0, int((y + DEPTH / 2) // COLUMN)))
    top, kind = hm[(i, j)]
    return W2_ICE_TOP if kind == "frozen" else top


def ground_spec2(hm):
    """The Frostbyte ground as one spec: SnowBlock's palette and kinds stacked on the height map, in spec space (x = -X, z = Y)."""
    sb = S.load(PROPS / "SnowBlock.md")
    kinds = {p["name"]: p for p in sb["parts"]}
    parts = []

    def block(name, kind, x, y0, h, z):
        k = kinds[kind]
        parts.append(S.normalise({"name": name, "slot": k["slot"], "material": k["material"], "size": [COLUMN, h, COLUMN],
                                  "at": [-x, y0 + h / 2, z]}))
    for (i, j), (top, kind) in sorted(hm.items()):
        x, y = column_centre(i, j)
        for level in range(int(top)):
            last = level == int(top) - 1
            if not last or kind == "frozen":
                block("u%d_%d_%d" % (i, j, level), "Cliff" if kind == "cliff" else "PackedSnow", x, level, 1, y)
            elif kind == "trail":
                block("t%d_%d" % (i, j), "PackedSnow", x, level, 1, y)
            elif kind == "ice":
                block("i%d_%d" % (i, j), "Ice", x, level, 1, y)
            else:
                block("s%d_%d" % (i, j), "Snow", x, level, 1, y)
        if kind == "frozen":
            block("f%d_%d" % (i, j), "FrozenWater", x, top, W2_ICE_TOP - top, y)
    floor = {"name": "Floor", "slot": "BodyDark", "size": [WIDTH + 2, 1, DEPTH + 2], "at": [0, -0.5, 0], "rot": [0, 0, 0], "shape": "box",
             "moves": "none", "bevel": False}
    spec = {"front": dict(sb["front"], id="Ground2"), "parts": parts, "face": None}
    return spec, [floor]


def snow_lumps(hm, out, taken):
    """Drifts on the open snow: low snow blocks (SnowBlock's Snow kind at half size), a deterministic scatter on the quarter-stud grid;
    with the world cell the lip covers their whole side, so each is a mound of snow on the snow."""
    sb = S.load(PROPS / "SnowBlock.md")
    snow = next(p for p in sb["parts"] if p["name"] == "Snow")
    n = 0
    for (i, j), (top, kind) in sorted(hm.items()):
        if kind != "snow" or C.rand(14, i, j) > 0.16:
            continue
        x, y = column_centre(i, j)
        x += round((C.rand(16, i, j) - 0.5) * 1.2 * 4) / 4
        y += round((C.rand(18, i, j) - 0.5) * 1.2 * 4) / 4
        if any(abs(x - tx) < r and abs(y - ty) < r for tx, ty, r in taken):
            continue
        w = 0.75 + 0.25 * int(C.rand(20, i, j) * 3)
        parts = [S.normalise({"name": "Lump", "slot": snow["slot"], "material": snow["material"], "size": [w, 0.5, w], "at": [0, 0.25, 0]})]
        spec = {"front": dict(sb["front"], id="Lump"), "parts": parts, "face": None}
        place(spec, out, x, y, top, yaw=0, prefix="D%d_" % n, cell=C.WORLD_CELL)
        n += 1
    return n


def world_and_sun2(scene):
    """Frostbyte's daylight: a cold sky gradient, a brighter blue-grey ambient (the haze) and a soft, low, cool sun."""
    world = bpy.data.worlds.new("Frostbyte")
    world.use_nodes = True
    nt = world.node_tree
    bg = next(n for n in nt.nodes if n.type == "BACKGROUND")
    out = next(n for n in nt.nodes if n.type == "OUTPUT_WORLD")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = B.lin(W2_SKY_HORIZON)
    ramp.color_ramp.elements[1].position = 0.6
    ramp.color_ramp.elements[1].color = B.lin(W2_SKY_ZENITH)
    nt.links.new(coord.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    seen = nt.nodes.new("ShaderNodeBackground")
    nt.links.new(ramp.outputs["Color"], seen.inputs["Color"])
    seen.inputs["Strength"].default_value = 1.0
    bg.inputs["Color"].default_value = (0.66, 0.76, 0.9, 1.0)
    bg.inputs["Strength"].default_value = 0.9
    path = nt.nodes.new("ShaderNodeLightPath")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(path.outputs["Is Camera Ray"], mix.inputs["Fac"])
    nt.links.new(bg.outputs["Background"], mix.inputs[1])
    nt.links.new(seen.outputs["Background"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    scene.world = world
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.2
    sun.angle = math.radians(11.0)
    sun.color = W2_SUN_COLOUR
    so = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(so)
    so.rotation_euler = (-Vector((-0.55, -0.7, 0.45))).to_track_quat("-Z", "Y").to_euler()


def build_scene2(out, creatures=True):
    scene = B.reset()
    hm = height_map2()
    ground, hidden = ground_spec2(hm)
    made = B.build(ground, out, cell=C.WORLD_CELL, hidden_by=hidden)
    print("ground: %d blocks, %d triangles, atlas %dx%d" % (len(ground["parts"]), made["tris"], made["atlas"][0], made["atlas"][1]), flush=True)
    taken = []
    stats = {"ground": made}
    for k, (note, X, Y, yaw, pitch, sink) in enumerate(W2_PROP_PLACES):
        spec = S.load(PROPS / ("%s.md" % note))
        Z = ground_at2(X, Y, hm) - sink
        m = place(spec, out, X, Y, Z, yaw, pitch, prefix="P%d_" % k, cell=C.WORLD_CELL)
        stats["%s%d" % (note, k)] = m
        taken.append((X, Y, {"PineTree": 3.0, "IceArch": 4.5, "Heater": 1.5}.get(note, 1.8)))
        if note == "IceCrystal":
            point_light("CrystalLight%d" % k, Vector((X, Y - 0.6, Z + 2.4)), "#8ADBFF", 120.0, 0.6)
        if note == "Heater":
            # the one warm light of the world: at the grate, on the drum's front, turned by the prop's yaw
            a = math.radians(yaw)
            front = Vector((math.sin(a) * 1.1, -math.cos(a) * 1.1, 0)) + Vector((X, Y, Z + 1.0))
            point_light("HeaterLight", front, "#FFA64D", 90.0, 0.5)
    if creatures:
        for note, X, Y, yaw in W2_CREATURE_PLACES:
            spec = S.load(CREATURES / ("%s.md" % note))
            Z = ground_at2(X, Y, hm)
            place(spec, out, X, Y, Z, yaw, prefix="C_")
            lo, hi = S.bounds(S.expand(spec["parts"]))
            taken.append((X, Y, max(hi[0] - lo[0], hi[2] - lo[2]) / 2 + 0.75))
        X, Y, yaw = W2_AVATAR_PLACE
        B.build(B.avatar_spec(), out, offset=(X, Y, ground_at2(X, Y, hm)), cell=C.WORLD_CELL, rot=(0, 0, math.radians(yaw)))
        taken.append((X, Y, 1.5))
    for i, j in W2_TRAIL:
        taken.append(column_centre(i, j) + (1.2,))
    stats["lumps"] = snow_lumps(hm, out, taken)
    world_and_sun2(scene)
    return scene, stats


# ------------------------------------------------------------------------------------------------ the scene
def world_and_sun(scene):
    """World 1's daylight: the camera sees a sky gradient (zenith to a pale horizon); the lighting is a soft sky plus a warm sun."""
    world = bpy.data.worlds.new("Verdant")
    world.use_nodes = True
    nt = world.node_tree
    bg = next(n for n in nt.nodes if n.type == "BACKGROUND")
    out = next(n for n in nt.nodes if n.type == "OUTPUT_WORLD")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = B.lin(SKY_HORIZON)
    ramp.color_ramp.elements[1].position = 0.55
    ramp.color_ramp.elements[1].color = B.lin(SKY_ZENITH)
    nt.links.new(coord.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    seen = nt.nodes.new("ShaderNodeBackground")
    nt.links.new(ramp.outputs["Color"], seen.inputs["Color"])
    seen.inputs["Strength"].default_value = 1.0
    bg.inputs["Color"].default_value = (0.78, 0.86, 1.0, 1.0)
    bg.inputs["Strength"].default_value = 0.85
    path = nt.nodes.new("ShaderNodeLightPath")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(path.outputs["Is Camera Ray"], mix.inputs["Fac"])
    nt.links.new(bg.outputs["Background"], mix.inputs[1])
    nt.links.new(seen.outputs["Background"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    scene.world = world
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.6
    sun.angle = math.radians(8.0)
    sun.color = SUN_COLOUR
    so = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(so)
    so.rotation_euler = Vector((-0.45, -0.75, 0.62)).normalized().to_track_quat("Z", "Y").to_euler()
    # flip: a sun points along its -Z, so aim it from the light toward the ground
    so.rotation_euler = (-Vector((-0.45, -0.75, 0.62))).to_track_quat("-Z", "Y").to_euler()


def point_light(name, at, colour_hex, energy, radius):
    light = bpy.data.lights.new(name, "POINT")
    light.energy = energy
    light.color = B.lin(colour_hex)[:3]
    light.shadow_soft_size = radius
    obj = bpy.data.objects.new(name, light)
    obj.location = at
    bpy.context.scene.collection.objects.link(obj)
    return obj


def place(spec, out, X, Y, Z, yaw=0.0, pitch=0.0, prefix="", cell=None):
    return B.build(spec, out, offset=(X, Y, Z), prefix=prefix, cell=cell, rot=(math.radians(pitch), 0.0, math.radians(yaw)))


def flowers(hm, out, taken):
    """Flowers on free grass, three petal colours, a deterministic scatter on the quarter-stud grid."""
    base = S.load(PROPS / "Flower.md")
    n = 0
    for (i, j), (top, kind) in sorted(hm.items()):
        if kind != "grass" or C.rand(5, i, j) > 0.22:
            continue
        x, y = column_centre(i, j)
        x += round((C.rand(6, i, j) - 0.5) * 1.2 * 4) / 4
        y += round((C.rand(8, i, j) - 0.5) * 1.2 * 4) / 4
        if any(abs(x - tx) < r and abs(y - ty) < r for tx, ty, r in taken):
            continue
        colour = FLOWER_COLOURS[int(C.rand(10, i, j) * len(FLOWER_COLOURS))]
        spec = dict(base, front=dict(base["front"], palette=[colour] + list(base["front"]["palette"][1:])))
        place(spec, out, x, y, top, yaw=C.rand(12, i, j) * 90, prefix="F%d_" % n)
        n += 1
    return n


def build_scene(out, creatures=True):
    scene = B.reset()
    hm = height_map()
    ground, hidden = ground_spec(hm)
    made = B.build(ground, out, cell=C.WORLD_CELL, hidden_by=hidden)
    print("ground: %d blocks, %d triangles, atlas %dx%d" % (len(ground["parts"]), made["tris"], made["atlas"][0], made["atlas"][1]), flush=True)
    taken = []
    stats = {"ground": made}
    for k, (note, X, Y, yaw, pitch, sink) in enumerate(PROP_PLACES):
        spec = S.load(PROPS / ("%s.md" % note))
        Z = ground_at(X, Y, hm) - sink
        m = place(spec, out, X, Y, Z, yaw, pitch, prefix="P%d_" % k, cell=C.WORLD_CELL)
        stats["%s%d" % (note, k)] = m
        taken.append((X, Y, 3.0 if note in ("Tree", "Ship") else 1.8))
        if note == "Crystal":
            point_light("CrystalLight", Vector((X, Y - 0.6, Z + 2.2)), "#9AF6FF", 140.0, 0.6)
        if note == "Ship":
            # the throw of the crash: clods at the nose; the nose points along the ship's -Y, turned by its yaw
            a = math.radians(yaw)
            nose = Vector((math.sin(a) * 5.5, -math.cos(a) * 5.5, 0)) * 1.0 + Vector((X, Y, 0))
            place(debris(0, 0, 0), out, nose.x, nose.y, ground_at(nose.x, nose.y, hm), yaw, 0, prefix="Clod_", cell=C.WORLD_CELL)
            tail = Vector((-math.sin(a) * 4.8, math.cos(a) * 4.8, 0)) + Vector((X, Y, Z + 2.4))
            point_light("Exhaust", tail, "#FFB347", 40.0, 0.4)
    if creatures:
        for note, X, Y, yaw in CREATURE_PLACES:
            spec = S.load(CREATURES / ("%s.md" % note))
            Z = ground_at(X, Y, hm)
            place(spec, out, X, Y, Z, yaw, prefix="C_")
            lo, hi = S.bounds(S.expand(spec["parts"]))
            taken.append((X, Y, max(hi[0] - lo[0], hi[2] - lo[2]) / 2 + 0.75))
        X, Y, yaw = AVATAR_PLACE
        B.build(B.avatar_spec(), out, offset=(X, Y, ground_at(X, Y, hm)), cell=C.WORLD_CELL, rot=(0, 0, math.radians(yaw)))
        taken.append((X, Y, 1.5))
    for i, j in PATH:
        taken.append(column_centre(i, j) + (1.2,))
    stats["flowers"] = flowers(hm, out, taken)
    world_and_sun(scene)
    return scene, stats


def camera(scene, name, position, target, lens=50.0):
    data = bpy.data.cameras.new(name)
    data.lens = lens
    data.clip_end = 1000.0
    cam = bpy.data.objects.new(name, data)
    scene.collection.objects.link(cam)
    cam.location = Vector(position)
    cam.rotation_euler = (Vector(target) - Vector(position)).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    return cam


VIEWS = {
    # the hero: a three-quarter game camera from the front right, high enough to read the whole diorama and its cut-away sides
    "hero": ((34.0, -58.0, 41.0), (-1.0, 2.0, 4.5), 45.0),
    # the second angle: low from the front left, among the small creatures, the Cosmic and the Secret towering behind
    "low": ((-21.0, -33.0, 11.5), (3.0, 2.0, 5.0), 32.0),
}


def render(scene, out, view, size, samples, world=1):
    pos, target, lens = VIEWS[view]
    camera(scene, view, pos, target, lens)
    scene.render.resolution_x = size
    scene.render.resolution_y = int(size * 9 / 16)
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 4
    scene.cycles.use_denoising = True
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    scene.render.filepath = str(pathlib.Path(out) / ("world%d_%s.png" % (world, view)))
    bpy.ops.render.render(write_still=True)
    print("rendered %s" % scene.render.filepath, flush=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", required=True, help="a scratch folder (never assets/models)")
    ap.add_argument("--size", type=int, default=1920, help="width in pixels (16:9)")
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--views", default="hero,low")
    ap.add_argument("--no-creatures", action="store_true")
    ap.add_argument("--world", type=int, default=1, choices=(1, 2), help="1 Verdant (the meadow), 2 Frostbyte (the snowfield)")
    a = ap.parse_args(argv)
    if "assets/models" in str(pathlib.Path(a.out).resolve()):
        print("refusing to write under assets/models (B43)")
        return 2
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    if a.world == 2:
        scene, stats = build_scene2(out, creatures=not a.no_creatures)
        print("snow lumps: %d" % stats["lumps"], flush=True)
    else:
        scene, stats = build_scene(out, creatures=not a.no_creatures)
        print("flowers: %d" % stats["flowers"], flush=True)
    for view in [v for v in a.views.split(",") if v]:
        render(scene, out, view, a.size, a.samples, a.world)
    return 0


if __name__ == "__main__":
    sys.exit(main())
