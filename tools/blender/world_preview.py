"""Preview of a generated block-cell world (tools/blocky/world_gen.py) in Blender: the ground exactly as Services/Meadow builds it (caps,
bodies, water, falls, solids, the same rows), every face wearing a 2 x 2 stud tile of the B44 cell rules (tools/blocky/cells.py
swatch faces in the kind's own colours, nearest filtering), and the scattered props as their block placeholders (data/WorldKit
recipes), since the props worker's meshes are not imported here. Two views: the whole map from above and a hero three-quarter over
the camp, the way the dioramas were shot.

    bpyenv/bin/python tools/blender/world_preview.py -- --world 1 --out <scratch> [--views top,hero] [--size 1600] [--samples 24]

Writes world<id>_<view>.png into --out (never under assets/). The review copies go to media/studio/<date>/ as JPEGs.
"""
from __future__ import annotations

import argparse
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import cells as C  # noqa: E402
import world_gen as G  # noqa: E402

# Which cell motif paints each tile key (Blocky-Style C4 and the cold set), and which swatch face it is.
TILE_MOTIF = {
    "GrassTop": ("grass", "+y"), "GrassSide": ("grass", "-z"), "Dirt": ("dirt", "-z"), "Path": ("stone", "+y"),
    "Stone": ("stone", "+y"), "Sand": ("dirt", "+y"), "Water": ("water", "+y"), "WoodPlank": ("wood", "-z"),
    "Snow": ("snow", "+y"), "SnowSide": ("snow", "-z"), "PackedSnow": ("packed_snow", "-z"), "Ice": ("ice", "+y"),
    "FrozenWater": ("frozen_water", "+y"), "Rock": ("stone", "-z"),
}
SKY = {1: ((0.62, 0.80, 0.95), (1.0, 0.96, 0.88), 3.6, (52.0, 0.0, 135.0)),
       2: ((0.52, 0.66, 0.84), (1.0, 0.97, 0.92), 2.2, (40.0, 0.0, 150.0))}
FLOOR_TOP = 0.5


def bl(x, y, z):
    """Roblox (x, y up, z) to Blender (x, -z, y up)."""
    return (x, -z, y)


def srgb_to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_lin(h, a=1.0):
    h = h.lstrip("#")
    return tuple(srgb_to_lin(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4)) + (a,)


_images: dict = {}


def tile_image(key: str, base: str, aux: str) -> bpy.types.Image:
    """The 64 x 64 tile of a key in a kind's colours (top or side face of a 2-stud swatch cube)."""
    motif, face = TILE_MOTIF[key]
    name = f"{key}_{base}_{aux}"
    if name in _images:
        return _images[name]
    faces = C.swatch_faces(motif, base, aux, aux, studs=2)
    w, h, data = faces[face]
    img = bpy.data.images.new(name, w, h, alpha=False)
    img.colorspace_settings.name = "sRGB"  # before the pixels: changing it regenerates a generated image
    px = [0.0] * (w * h * 4)
    for row in range(h):
        src = (h - 1 - row) * w * 3
        for col in range(w):
            r, g, b = data[src + col * 3], data[src + col * 3 + 1], data[src + col * 3 + 2]
            k = (row * w + col) * 4
            px[k], px[k + 1], px[k + 2], px[k + 3] = r / 255, g / 255, b / 255, 1.0
    img.pixels = px
    _images[name] = img
    return img


_mats: dict = {}


def tile_material(key: str, base: str, aux: str, water=False, glow=False) -> bpy.types.Material:
    name = f"M_{key}_{base}_{aux}_{int(water)}"
    if name in _mats:
        return _mats[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True  # noqa: deprecated in 6.0, still needed in 5.0
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = tile_image(key, base, aux)
    tex.interpolation = "Closest"
    tex.extension = "REPEAT"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.15 if water else 0.85
    if water:
        bsdf.inputs["Alpha"].default_value = 0.78
        mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else None
    if glow:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 2.0
    _mats[name] = mat
    return mat


def flat_material(hexcol: str, neon=False) -> bpy.types.Material:
    name = f"F_{hexcol}_{int(neon)}"
    if name in _mats:
        return _mats[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True  # noqa: deprecated in 6.0, still needed in 5.0
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = hex_lin(hexcol)
    bsdf.inputs["Roughness"].default_value = 0.8
    if neon:
        bsdf.inputs["Emission Color"].default_value = hex_lin(hexcol)
        bsdf.inputs["Emission Strength"].default_value = 4.0
    _mats[name] = mat
    return mat


class MeshBatch:
    """Quads grouped by material, each with its UVs, flushed into one object per material."""

    def __init__(self):
        self.groups: dict = {}

    def quad(self, mat, verts, uvs):
        g = self.groups.setdefault(mat.name, (mat, [], [], []))
        base = len(g[1])
        g[1].extend(bl(*v) for v in verts)
        g[2].append((base, base + 1, base + 2, base + 3))
        g[3].extend(uvs)

    def flush(self, coll):
        for name, (mat, verts, faces, uvs) in self.groups.items():
            mesh = bpy.data.meshes.new(name)
            mesh.from_pydata(verts, [], faces)
            layer = mesh.uv_layers.new(name="UV")
            for loop in mesh.loops:
                layer.data[loop.index].uv = uvs[loop.vertex_index]
            mesh.materials.append(mat)
            mesh.validate()
            obj = bpy.data.objects.new(name, mesh)
            coll.objects.link(obj)


def box_faces(batch, x0, y0, z0, x1, y1, z1, top_mat, side_mat, bottom_mat=None, sides=0xF, top=True, pin_top=True):
    """The faces of an axis-aligned box in Roblox studs; UVs in world studs over the 2-stud tile (side tiles pinned to the box's top
    when pin_top, else to the world's 2-stud rows)."""
    s = 2.0

    def v_of(y):
        return 1.0 - (y1 - y) / s if pin_top else y / s

    if top:
        batch.quad(top_mat, [(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)],
                   [(x0 / s, z0 / s), (x1 / s, z0 / s), (x1 / s, z1 / s), (x0 / s, z1 / s)])
    if bottom_mat is not None:
        batch.quad(bottom_mat, [(x0, y0, z1), (x1, y0, z1), (x1, y0, z0), (x0, y0, z0)],
                   [(x0 / s, z1 / s), (x1 / s, z1 / s), (x1 / s, z0 / s), (x0 / s, z0 / s)])
    if sides & 1:   # +X
        batch.quad(side_mat, [(x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1)],
                   [(-z1 / s, v_of(y0)), (-z0 / s, v_of(y0)), (-z0 / s, v_of(y1)), (-z1 / s, v_of(y1))])
    if sides & 2:   # -X
        batch.quad(side_mat, [(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)],
                   [(z0 / s, v_of(y0)), (z1 / s, v_of(y0)), (z1 / s, v_of(y1)), (z0 / s, v_of(y1))])
    if sides & 4:   # +Z
        batch.quad(side_mat, [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
                   [(x0 / s, v_of(y0)), (x1 / s, v_of(y0)), (x1 / s, v_of(y1)), (x0 / s, v_of(y1))])
    if sides & 8:   # -Z
        batch.quad(side_mat, [(x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0)],
                   [(-x1 / s, v_of(y0)), (-x0 / s, v_of(y0)), (-x0 / s, v_of(y1)), (-x1 / s, v_of(y1))])


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return ((c, 0, s), (0, 1, 0), (-s, 0, c))


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return ((c, -s, 0), (s, c, 0), (0, 0, 1))


def mul(m, v):
    return tuple(sum(m[r][k] * v[k] for k in range(3)) for r in range(3))


def prop_boxes(batch, recipe, x, y, z, yaw, scale):
    ry = rot_y(math.radians(yaw))
    for b in recipe["boxes"]:
        rz = rot_z(math.radians(b.get("roll", 0)))
        hx, hy, hz = (b["size"][0] * scale / 2, b["size"][1] * scale / 2, b["size"][2] * scale / 2)
        at = (b["at"][0] * scale, b["at"][1] * scale, b["at"][2] * scale)
        corners = []
        for sx, sy, sz in ((-1, -1, -1), (1, -1, -1), (1, 1, -1), (-1, 1, -1), (-1, -1, 1), (1, -1, 1), (1, 1, 1), (-1, 1, 1)):
            local = mul(rz, (sx * hx, sy * hy, sz * hz))
            p = mul(ry, (at[0] + local[0], at[1] + local[1], at[2] + local[2]))
            corners.append((x + p[0], y + p[1], z + p[2]))
        mat = flat_material(b["color"], b.get("neon", False))
        for f in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (0, 4, 7, 3)):
            batch.quad(mat, [corners[k] for k in f], [(0, 0), (1, 0), (1, 1), (0, 1)])


def build(world_id: int):
    world, caps, bodies, waters, stats = G.generate(world_id)
    kinds = world.kit["kinds"]
    cell, origin = world.cell, world.origin
    batch = MeshBatch()
    for i, j, w, d, top, kind, mask in caps:
        k = kinds[kind]
        x0, z0 = origin + i * cell, origin + j * cell
        glow = k["material"] == "Neon"
        box_faces(batch, x0, FLOOR_TOP + top - 1, z0, x0 + w * cell, FLOOR_TOP + top, z0 + d * cell,
                  tile_material(k["top"], k["color"], k["sideColor"], glow=glow), tile_material(k["side"], k["color"], k["sideColor"], glow=glow),
                  sides=mask)
    for i, j, w, d, top, kind, mask in bodies:
        k = kinds[kind]
        x0, z0 = origin + i * cell, origin + j * cell
        box_faces(batch, x0, FLOOR_TOP + world.base, z0, x0 + w * cell, FLOOR_TOP + top, z0 + d * cell, None,
                  tile_material(k["body"], k["bodyColor"], k["bodyColor"]), sides=mask, top=False, pin_top=False)
    for i, j, w, d, bottom, top, kind in waters:
        k = kinds[kind]
        x0, z0 = origin + i * cell, origin + j * cell
        box_faces(batch, x0, FLOOR_TOP + bottom, z0, x0 + w * cell, FLOOR_TOP + top, z0 + d * cell,
                  tile_material(k["top"], k["color"], k["color"], water=True), None, sides=0)
    for x, z, width, bottom, top, yaw, kind in world.falls:
        k = kinds[kind]
        a = math.radians(yaw)
        ux, uz = math.cos(a), -math.sin(a)   # the sheet's local X (across the flow)
        mat = tile_material(k["side"], "CFEFFF", "9FD8F5", water=True)
        p0 = (x - ux * width / 2, FLOOR_TOP + bottom, z - uz * width / 2)
        p1 = (x + ux * width / 2, FLOOR_TOP + bottom, z + uz * width / 2)
        batch.quad(mat, [p0, p1, (p1[0], FLOOR_TOP + top, p1[2]), (p0[0], FLOOR_TOP + top, p0[2])],
                   [(0, 0), (width / 2, 0), (width / 2, (top - bottom) / 2), (0, (top - bottom) / 2)])
    for x0, y0, z0, x1, y1, z1, kind, walk in world.solids:
        k = kinds[kind]
        box_faces(batch, x0, FLOOR_TOP + y0, z0, x1, FLOOR_TOP + y1, z1, tile_material(k["top"], k["color"], k["sideColor"]),
                  tile_material(k["side"], k["color"], k["sideColor"]), tile_material(k["body"], k["bodyColor"], k["bodyColor"]), pin_top=True)
    recipes = world.kit["recipes"]
    for name, x, y, z, yaw, scale in world.props:
        prop_boxes(batch, recipes[name], x, FLOOR_TOP + y, z, yaw, scale)
    # the camp pad and the shrine stand-ins (the real ones are client and landmark models)
    pad = flat_material("FFF4DC")
    box_faces(batch, -11, FLOOR_TOP, -11, 11, FLOOR_TOP + 0.4, 11, pad, pad)
    sx, sz = world.desc["shrine"]
    sy = FLOOR_TOP + world.h[world.index_at(sx, sz)]
    stone = flat_material("9E9E8E" if world_id == 1 else "BFD9E6")
    for n in range(8):
        a = n / 8 * math.tau
        cx, cz = sx + math.cos(a) * 10, sz + math.sin(a) * 10
        box_faces(batch, cx - 1, sy, cz - 1, cx + 1, sy + 5, cz + 1, stone, stone)
    glow = flat_material("2ECC71" if world_id == 1 else "68C9FE", neon=True)
    box_faces(batch, sx - 1, sy + 1.5, sz - 1, sx + 1, sy + 3.5, sz + 1, glow, glow)
    coll = bpy.context.scene.collection
    batch.flush(coll)
    return world, stats


def setup(scene, world_id, samples):
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 3
    scene.cycles.use_denoising = True
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    sky, sun_col, energy, rot = SKY[world_id]
    w = bpy.data.worlds.new("Sky")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = sky + (1.0,)
    bg.inputs["Strength"].default_value = 0.9
    scene.world = w
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = energy
    sun.color = sun_col
    sun.angle = math.radians(6)
    obj = bpy.data.objects.new("Sun", sun)
    obj.rotation_euler = tuple(math.radians(a) for a in rot)
    scene.collection.objects.link(obj)


def camera(scene, view, size, world_id):
    data = bpy.data.cameras.new(view)
    data.clip_end = 2000.0
    cam = bpy.data.objects.new(view, data)
    scene.collection.objects.link(cam)
    if view == "top":
        data.type = "ORTHO"
        data.ortho_scale = 404
        cam.location = Vector((0, 0, 300))
        cam.rotation_euler = (0, 0, 0)
        scene.render.resolution_x = size
        scene.render.resolution_y = size
    else:
        pos, target, lens = HERO[world_id][view]
        data.lens = lens
        cam.location = Vector(bl(*pos))
        cam.rotation_euler = (Vector(bl(*target)) - Vector(bl(*pos))).to_track_quat("-Z", "Y").to_euler()
        scene.render.resolution_x = size
        scene.render.resolution_y = int(size * 9 / 16)
    scene.camera = cam


# Roblox studs: (camera position, look-at point, lens mm) per world. "hero" is the game's three-quarter over the camp at diorama
# scale, looking out to the world's set pieces; "wide" takes the whole map in from a corner.
HERO = {
    1: {"hero": ((62.0, 44.0, -62.0), (-34.0, 4.0, 70.0), 26.0),
        "falls": ((-30.0, 18.0, 66.0), (-66.0, 6.0, 104.0), 28.0),
        "wide": ((150.0, 120.0, -215.0), (-30.0, 0.0, 40.0), 30.0)},
    2: {"hero": ((62.0, 44.0, -40.0), (-40.0, 4.0, 60.0), 26.0),
        "lake": ((20.0, 30.0, -20.0), (70.0, 0.0, -90.0), 28.0),
        "wide": ((150.0, 120.0, -215.0), (-30.0, 0.0, 40.0), 30.0)},
}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--world", type=int, default=1, choices=(1, 2))
    ap.add_argument("--out", required=True)
    ap.add_argument("--views", default="top,hero")
    ap.add_argument("--size", type=int, default=1600)
    ap.add_argument("--samples", type=int, default=24)
    a = ap.parse_args(argv)
    out = pathlib.Path(a.out)
    if "assets" in out.resolve().parts:
        print("refusing to write under assets/")
        return 2
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    world, stats = build(a.world)
    print("built", stats, flush=True)
    setup(scene, a.world, a.samples)
    scene.render.image_settings.file_format = "PNG"
    for view in [v for v in a.views.split(",") if v]:
        camera(scene, view, a.size, a.world)
        scene.render.filepath = str(out / f"world{a.world}_{view}.png")
        bpy.ops.render.render(write_still=True)
        print("rendered", scene.render.filepath, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
