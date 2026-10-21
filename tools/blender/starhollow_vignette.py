#!/usr/bin/env python3
"""The Starhollow Forest vignette (Decision B48): a small night scene built from the Starhollow block-cell props and tiles, to show the mood
matches the forest TikTok (ZPLYSA3uR in media/tiktok/NOTES.md): a pale lavender path through moon trees to a little arched bridge over a
glowing stream, the moon pool in its ring of mossy stones, a grove of giant glowcaps with small ones at their feet, lanterns along the path,
fireflies and light drips, and the star island floating behind with its halo arch and waterfall. Headless Blender (bpy 5.0).

Everything comes through the prop route: the props are the spec notes in docs/vault/07-alien-game/Props/ built by
tools/blender/blocky_build.py at the world cell (exactly what tools/blocky/export_models.py --props exports), and the ground is 2 x 1 x 2
stud blocks in the MoonGrass, MoonPath and GlowWater colours of tools/blocky/world_tiles.py. The fireflies, the light drips and the
waterfall stand in for the world worker's particles and parts; the glow cells are the light sources (a point light on each, as the game's
PointLights would be).

  BPY=<python with bpy>
  $BPY tools/blender/starhollow_vignette.py --out <scratch dir> [--size 1600] [--samples 48]

Writes starhollow_vignette.png into --out (a scratch folder, never assets/models); the review copy is
media/studio/2026-10-21/starhollow_vignette_v1.jpg.
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
import blocky_scene as BS  # noqa: E402
import world_tiles as WT  # noqa: E402

C, S = B.C, B.S
PROPS = ROOT / "docs/vault/07-alien-game/Props"

# ------------------------------------------------------------------------------------------------ the layout (Blender space: X right as the
# camera sees it, Y back, Z up; a stud a unit). The ground is a grid of 2-stud columns, one block deep (its top at 1).
X0, X1, Y0, Y1, COLUMN = -32, 32, -24, 34, 2
GROUND_TOP, WATER_TOP = 1.0, 0.75
GRASS, EARTH, PATH, WATER = WT.TILES["MoonGrass"][2], "#3B3366", WT.TILES["MoonPath"][2], WT.TILES["GlowWater"][2]
PATH_POINTS = [(0.0, -26.0), (-2.5, -14.0), (2.0, -4.0), (0.0, 2.0), (0.0, 14.0), (-4.0, 20.0), (-9.0, 28.0), (-11.0, 36.0)]
POOL = (15.0, -3.0, 6.25)                   # centre x, y and the water's radius inside the ring
BRIDGE = (0.0, 8.0)


def stream_y(x):
    return 8.0 + 2.0 * math.sin(x / 9.0)


def near_path(x, y, width):
    best = 1e9
    for (ax, ay), (bx, by) in zip(PATH_POINTS, PATH_POINTS[1:]):
        dx, dy = bx - ax, by - ay
        t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
        best = min(best, math.hypot(x - ax - t * dx, y - ay - t * dy))
    return best < width


def kind_at(x, y):
    if abs(y - stream_y(x)) < 2.4 or math.hypot(x - POOL[0], y - POOL[1]) < POOL[2]:
        return "water"
    if near_path(x, y, 2.1):
        return "path"
    return "grass"


def ground_spec():
    parts = []
    nx, ny = (X1 - X0) // COLUMN, (Y1 - Y0) // COLUMN
    for i in range(nx):
        for j in range(ny):
            x, y = X0 + COLUMN * i + 1, Y0 + COLUMN * j + 1
            kind = kind_at(x, y)
            if kind == "water":
                parts.append({"name": "w%d_%d" % (i, j), "slot": "Glow", "material": "water", "size": [COLUMN, WATER_TOP, COLUMN],
                              "at": [-x, WATER_TOP / 2, y]})
            elif kind == "path":
                parts.append({"name": "p%d_%d" % (i, j), "slot": "Accessory", "material": "stone", "size": [COLUMN, GROUND_TOP, COLUMN],
                              "at": [-x, GROUND_TOP / 2, y]})
            else:
                parts.append({"name": "g%d_%d" % (i, j), "slot": "Body", "material": "grass", "size": [COLUMN, GROUND_TOP, COLUMN],
                              "at": [-x, GROUND_TOP / 2, y]})
    front = {"id": "StarhollowGround", "palette": [GRASS, EARTH, PATH, WATER], "roles": ["body", "second", "accent", "glow"]}
    floor = {"name": "Floor", "slot": "BodyDark", "size": [X1 - X0 + 2, 1, Y1 - Y0 + 2], "at": [0, -0.5, (Y0 + Y1) / 2], "rot": [0, 0, 0],
             "shape": "box", "moves": "none", "bevel": False}
    return {"front": front, "parts": [S.normalise(p, k) for k, p in enumerate(parts)], "face": None}, [floor]


# (note, X, Y, yaw degrees, Z or None for the ground top)
PLACES = [
    ("MoonTree", -15.0, -9.0, 10, None), ("MoonTreeB", -25.0, 5.0, -15, None), ("MoonTree", 13.0, 19.0, 20, None),
    ("MoonTreeB", 27.0, 9.0, 0, None), ("MoonTree", 25.0, 29.0, -10, None), ("MoonTreeB", 4.0, 30.0, 30, None),
    ("MoonTree", -27.0, -17.0, 15, None), ("MoonTreeB", 30.0, -19.0, -20, None), ("MoonTree", -22.0, 30.0, 5, None),
    ("GlowcapGiant", -18.0, 13.0, 10, None), ("GlowcapGiantBlue", -9.0, 21.0, -20, None), ("GlowcapGiantPink", -27.0, 19.0, 25, None),
    ("GlowcapSmall", -14.0, 9.5, 0, None), ("GlowcapSmall", -21.0, 9.0, 40, None), ("GlowcapSmall", -6.0, 17.0, 15, None),
    ("GlowcapSmall", -12.0, 24.0, -30, None), ("GlowcapSmall", -24.0, 15.0, 70, None), ("GlowcapSmall", 5.0, -9.0, 20, None),
    ("ArchBridge", BRIDGE[0], BRIDGE[1], 90, 0.25),
    ("MoonPoolRing", POOL[0], POOL[1], 15, 0.25),
    ("PathLantern", 3.0, -18.0, -10, None), ("PathLantern", -5.5, -10.0, 10, None), ("PathLantern", 4.5, -2.0, -20, None),
    ("PathLantern", -3.0, 15.5, 0, None), ("PathLantern", -1.0, 24.0, 15, None), ("PathLantern", 10.5, -12.0, 30, None),
    ("SteppingStone", 21.0, stream_y(21.0) - 1.75, 10, 0.25), ("SteppingStone", 22.5, stream_y(22.5) + 1.25, -15, 0.25),
    ("GlowFern", -8.0, -3.0, 0, None), ("GlowFern", 7.0, 4.0, 30, None), ("GlowFern", -10.5, -16.0, 50, None), ("GlowFern", 7.0, -13.0, 10, None),
    ("GlowFern", -16.0, 3.0, 20, None), ("GlowFern", 15.0, 12.5, -20, None),
    ("MossStone", 6.0, -9.0, 25, None), ("MossStone", -7.0, 4.0, -10, None), ("MossStone", 24.0, -2.0, 40, None), ("MossStone", 23.0, 3.5, 0, None),
]
ISLAND = (-5.0, 54.0, 22.0)
AVATAR = (0.5, -13.0, 160)


def glow_lights(spec, at, yaw, k0, scale=1.0):
    """A point light at each glow part of the note (placed at `at`, turned by `yaw` degrees), in its glow colour, brighter for a longer
    part: the game's PointLight on the glow cells. One a part, so a prop with two lamps (the bridge) lights each, not the deck between."""
    pal = S.palette(spec)
    if "glow" not in pal:
        return k0
    k = k0
    a = math.radians(yaw)
    for p in S.expand(spec["parts"]):
        if p["slot"] != "Glow":
            continue
        local = B.to_bl(p["at"])
        world = Vector((local.x * math.cos(a) - local.y * math.sin(a), local.x * math.sin(a) + local.y * math.cos(a), local.z)) + Vector(at)
        size = max(p["size"])
        BS.point_light("G%d" % k, world, pal["glow"], scale * min(700.0, 18.0 + 45.0 * size), max(0.15, size * 0.25))
        k += 1
    return k


def brighten(made, strength):
    """The glow cells at night strength (the build's 1.5 is the daylight Neon)."""
    for o in made["objects"]:
        if not o.name.endswith("Glow"):
            continue
        for mat in o.data.materials:
            for node in mat.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED":
                    node.inputs["Emission Strength"].default_value = strength


def night_world(scene):
    """A deep indigo night: the camera sees a gradient from a violet horizon to a near-black zenith with stars; the light is a faint cool sky."""
    world = bpy.data.worlds.new("Starhollow")
    world.use_nodes = True
    nt = world.node_tree
    bg = next(n for n in nt.nodes if n.type == "BACKGROUND")
    out = next(n for n in nt.nodes if n.type == "OUTPUT_WORLD")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = B.lin("#23246A")
    ramp.color_ramp.elements[1].position = 0.45
    ramp.color_ramp.elements[1].color = B.lin("#06071C")
    nt.links.new(coord.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    stars = nt.nodes.new("ShaderNodeTexVoronoi")
    stars.inputs["Scale"].default_value = 260.0
    sramp = nt.nodes.new("ShaderNodeValToRGB")
    sramp.color_ramp.elements[0].position = 0.0
    sramp.color_ramp.elements[0].color = (1.0, 1.0, 1.0, 1.0)
    sramp.color_ramp.elements[1].position = 0.045
    sramp.color_ramp.elements[1].color = (0.0, 0.0, 0.0, 1.0)
    nt.links.new(coord.outputs["Generated"], stars.inputs["Vector"])
    nt.links.new(stars.outputs["Distance"], sramp.inputs["Fac"])
    add = nt.nodes.new("ShaderNodeMix")
    add.data_type = "RGBA"
    add.blend_type = "ADD"
    add.inputs["Factor"].default_value = 0.8
    nt.links.new(ramp.outputs["Color"], add.inputs["A"])
    nt.links.new(sramp.outputs["Color"], add.inputs["B"])
    seen = nt.nodes.new("ShaderNodeBackground")
    nt.links.new(add.outputs["Result"], seen.inputs["Color"])
    seen.inputs["Strength"].default_value = 1.0
    bg.inputs["Color"].default_value = (0.10, 0.11, 0.32, 1.0)
    bg.inputs["Strength"].default_value = 0.35
    path = nt.nodes.new("ShaderNodeLightPath")
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(path.outputs["Is Camera Ray"], mix.inputs["Fac"])
    nt.links.new(bg.outputs["Background"], mix.inputs[1])
    nt.links.new(seen.outputs["Background"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    scene.world = world
    moon = bpy.data.lights.new("Moon", "SUN")
    moon.energy = 0.6
    moon.angle = math.radians(5.0)
    moon.color = (0.70, 0.74, 1.0)
    mo = bpy.data.objects.new("Moon", moon)
    scene.collection.objects.link(mo)
    mo.rotation_euler = (-Vector((0.35, 0.8, 0.55))).to_track_quat("-Z", "Y").to_euler()


def motes(count=110):
    """Fireflies (small pastel cubes drifting at 1 to 9 studs) and light drips under the canopies: the world worker's particle layers."""
    colours = ("#FFF6C8", "#C8F4FF", "#FFC8EE", "#E2CCFF")
    mats = [B.emissive("Mote%d" % k, h, 9.0) for k, h in enumerate(colours)]
    for k in range(count):
        x = X0 + (X1 - X0) * C.rand(901, k)
        y = Y0 + (Y1 - Y0) * C.rand(903, k)
        z = 1.5 + 8.0 * C.rand(905, k) ** 1.5
        B.cube("Mote%d" % k, (x, y, z), (0.16, 0.16, 0.16), mats[k % len(mats)])
    streak = B.emissive("Streak", "#C8F0FF", 4.0, alpha=0.75)
    for note, X, Y, _yaw, _z in PLACES:
        if not note.startswith("MoonTree"):
            continue
        for k in range(5):
            dx = (C.rand(911, int(X), k) - 0.5) * 10.0
            dy = (C.rand(913, int(Y), k) - 0.5) * 8.0
            z = 4.0 + 5.0 * C.rand(915, int(X), k)
            B.cube("Streak%d_%d" % (int(X), k), (X + dx, Y + dy, z), (0.06, 0.06, 1.4), streak)


def waterfall(spout):
    """The fall from the island's spout to the forest behind the ground, a glowing curtain (the world worker's part, with particles)."""
    mat = B.emissive("Fall", "#8FDFFF", 3.0, alpha=0.8)
    top = spout.z
    B.cube("Fall", (spout.x, spout.y, top / 2), (2.0, 0.5, top), mat)
    B.cube("FallFoam", (spout.x, spout.y, 0.6), (4.0, 2.5, 1.2), B.emissive("Foam", "#DDF6FF", 2.5, alpha=0.7))
    BS.point_light("FallLight", Vector((spout.x, spout.y - 3.0, 6.0)), "#8FDFFF", 2500.0, 2.0)


def build(out):
    scene = B.reset()
    ground, hidden = ground_spec()
    made = B.build(ground, out, cell=C.WORLD_CELL, hidden_by=hidden, glow=1.1)
    print("ground: %d blocks, %d triangles" % (len(ground["parts"]), made["tris"]), flush=True)
    k = 0
    for n, (note, X, Y, yaw, Z) in enumerate(PLACES):
        spec = S.load(PROPS / ("%s.md" % note))
        z = GROUND_TOP if Z is None else Z
        m = BS.place(spec, out, X, Y, z, yaw, prefix="P%d_" % n, cell=C.WORLD_CELL)
        brighten(m, 4.0)
        k = glow_lights(spec, (X, Y, z), yaw, k, 0.6 if note in ("GlowcapSmall", "GlowFern", "MossStone") else 1.0)
    # the floating island over the back of the forest, turned so its spout faces the camera
    spec = S.load(PROPS / "StarIsland.md")
    m = BS.place(spec, out, ISLAND[0], ISLAND[1], ISLAND[2], 0, prefix="Island_", cell=C.WORLD_CELL)
    brighten(m, 6.0)
    k = glow_lights(spec, ISLAND, 0, k, 2.0)
    # the spout is at the note's x = -5, z = -12 (Blender X = 5 relative, Y = -12), its lip at y = 13.5 over the island's foot
    waterfall(Vector((ISLAND[0] + 5.0, ISLAND[1] - 12.25, ISLAND[2] + 12.5)))
    X, Y, yaw = AVATAR
    B.build(B.avatar_spec(), out, offset=(X, Y, GROUND_TOP), cell=C.WORLD_CELL, rot=(0, 0, math.radians(yaw)))
    motes()
    night_world(scene)
    B.glare(scene, "Fog Glow", 0.7)
    return scene


def render(scene, out, size, samples):
    BS.camera(scene, "vignette", (7.0, -62.0, 42.0), (-3.0, 30.0, 12.0), 24.0)
    scene.render.resolution_x = size
    scene.render.resolution_y = int(size * 9 / 16)
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 4
    scene.cycles.use_denoising = True
    scene.render.filepath = str(pathlib.Path(out) / "starhollow_vignette.png")
    bpy.ops.render.render(write_still=True)
    print("rendered %s" % scene.render.filepath, flush=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", required=True, help="a scratch folder (never assets/models)")
    ap.add_argument("--size", type=int, default=1600, help="width in pixels (16:9)")
    ap.add_argument("--samples", type=int, default=48)
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
