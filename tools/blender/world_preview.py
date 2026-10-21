"""Preview of a generated block-cell world (tools/blocky/world_gen.py) in Blender: the ground exactly as Services/Meadow builds it (caps,
bodies, water, falls, solids, the same rows), every face wearing a 2 x 2 stud tile of the B44 cell rules (tools/blocky/cells.py
swatch faces in the kind's own colours, nearest filtering), every placed prop as its exported block-cell mesh
(assets/models/props/<Name>/<Name>.glb, as Shared/Props places it) or, where none is exported, its block placeholder (data/WorldKit
recipes), the landmarks of the world's layout (data/Meadow.luau or Frostbyte.luau Landmarks: the crash wreck, the cave mouths, the
vent) at their yaw, the shrine, and the camp as CampRenderer stands it (data/Camp.luau: the ShipHull, the three stations, the yellow
spawn pad on the camp deck). Views: the whole map from above, a hero three-quarter over the camp the way the dioramas were shot, and
`camp`, the camp close up.

    bpyenv/bin/python tools/blender/world_preview.py -- --world 1 --out <scratch> [--views top,hero,camp] [--size 1600] [--samples 24]
        [--placeholders]    (every prop as its block placeholder: the look before the meshes)

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

import re  # noqa: E402

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import cells as C  # noqa: E402
import world_gen as G  # noqa: E402

# Which cell motif paints each tile key (Blocky-Style C4 and the cold set), and which swatch face it is.
TILE_MOTIF = {
    "GrassTop": ("grass", "+y"), "GrassSide": ("grass", "-z"), "Dirt": ("dirt", "-z"), "Path": ("stone", "+y"),
    "Stone": ("stone", "+y"), "Sand": ("dirt", "+y"), "Water": ("water", "+y"), "WoodPlank": ("wood", "-z"),
    "Snow": ("snow", "+y"), "SnowSide": ("snow", "-z"), "PackedSnow": ("packed_snow", "-z"), "Ice": ("ice", "+y"),
    "FrozenWater": ("frozen_water", "+y"), "Rock": ("stone", "-z"),
    "MoonPath": ("stone", "+y"), "MoonGrass": ("grass", "+y"), "GlowWater": ("water", "+y"),
}
NIGHT = ((0.035, 0.035, 0.11), (0.62, 0.70, 1.0), 0.5, (40.0, 0.0, 210.0))   # the Starhollow's moonlit sky and moon
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


# ------------------------------------------------------------------------------------------------ the exported prop meshes
PROPS_DIR = ROOT / "assets/models/props"
DATA = ROOT / "src/shared/data"
LAYOUT_FILE = {1: "Meadow.luau", 2: "Frostbyte.luau"}
_lib: dict = {}
USE_MESHES = True


def prop_library(name: str):
    """The exported mesh of a prop, imported once and kept out of the scene: ([(mesh data, matrix)], height), or None when the prop has
    no export (its block placeholder stands in)."""
    if name in _lib:
        return _lib[name]
    glb = PROPS_DIR / name / f"{name}.glb"
    if not USE_MESHES or not name or not glb.is_file():
        _lib[name] = None
        return None
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(glb))
    new = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    parts, top = [], 0.0
    for o in new:
        if o.type != "MESH":
            continue
        parts.append((o.data, o.matrix_world.copy()))
        top = max(top, max((o.matrix_world @ Vector(c)).z for c in o.bound_box))
        for slot in o.material_slots:
            if slot.material and slot.material.node_tree:
                for n in slot.material.node_tree.nodes:
                    if n.type == "TEX_IMAGE":
                        n.interpolation = "Closest"
    for o in new:
        bpy.data.objects.remove(o)
    _lib[name] = (parts, top)
    return _lib[name]


def place_mesh(coll, name, x, y, z, yaw, scale, hang=False):
    """Stand a prop's exported mesh at Roblox (x, y, z) turned `yaw` degrees about +Y (Blender +Z), as Props.Place does; a hanging prop
    (icicles) is lowered by its height. False when the prop has no export."""
    lib = prop_library(name)
    if lib is None:
        return False
    parts, height = lib
    drop = height * scale if hang else 0.0
    m = Matrix.Translation(Vector(bl(x, y - drop, z))) @ Matrix.Rotation(math.radians(yaw), 4, "Z") @ Matrix.Scale(scale, 4)
    for data, local in parts:
        obj = bpy.data.objects.new(name, data)
        obj.matrix_world = m @ local
        coll.objects.link(obj)
    return True


def layout_landmarks(world_id: int):
    """(name, x, z, yaw, scale) of every landmark in the world's layout (data/Meadow.luau or Frostbyte.luau Landmarks)."""
    text = (DATA / LAYOUT_FILE[world_id]).read_text(encoding="utf-8")
    pat = r'\{ name = "(\w+)", x = (-?[\d.]+), z = (-?[\d.]+), yaw = (-?[\d.]+), scale = ([\d.]+)'
    return [(m[0], float(m[1]), float(m[2]), float(m[3]), float(m[4])) for m in re.findall(pat, text)]


def camp_layout():
    """The camp as data/Camp.luau lays it out: the ship's offset and model, each station's offset and model."""
    text = (DATA / "Camp.luau").read_text(encoding="utf-8")
    ship = re.search(r"ShipOffset = Vector3.new\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", text)
    stations = {m[0]: (float(m[1]), float(m[3])) for m in re.findall(r"\t(Gather|Build|Spark) = \{ offset = Vector3.new\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", text)}
    names = dict(re.findall(r"(Gather|Build|Spark) = \"(\w+)\"", text))
    shipname = re.search(r'ship = "(\w+)"', text)
    return {"ship": (float(ship[1]), float(ship[3])), "stations": stations, "names": names, "shipName": shipname[1] if shipname else "ShipHull"}


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
        glow = world.kit["water"].get(kind, {}).get("neon", False)
        box_faces(batch, x0, FLOOR_TOP + bottom, z0, x0 + w * cell, FLOOR_TOP + top, z0 + d * cell,
                  tile_material(k["top"], k["color"], k["color"], water=True, glow=glow), None, sides=0)
    for x, z, width, bottom, top, yaw, kind in world.falls:
        k = kinds[kind]
        a = math.radians(yaw)
        ux, uz = math.cos(a), -math.sin(a)   # the sheet's local X (across the flow)
        glow = world.kit["water"].get(kind, {}).get("neon", False)
        mat = tile_material(k["side"], k["color"] if glow else "CFEFFF", "9FD8F5", water=True, glow=glow)
        p0 = (x - ux * width / 2, FLOOR_TOP + bottom, z - uz * width / 2)
        p1 = (x + ux * width / 2, FLOOR_TOP + bottom, z + uz * width / 2)
        batch.quad(mat, [p0, p1, (p1[0], FLOOR_TOP + top, p1[2]), (p0[0], FLOOR_TOP + top, p0[2])],
                   [(0, 0), (width / 2, 0), (width / 2, (top - bottom) / 2), (0, (top - bottom) / 2)])
    for x0, y0, z0, x1, y1, z1, kind, walk in world.solids:
        k = kinds[kind]
        box_faces(batch, x0, FLOOR_TOP + y0, z0, x1, FLOOR_TOP + y1, z1, tile_material(k["top"], k["color"], k["sideColor"]),
                  tile_material(k["side"], k["color"], k["sideColor"]), tile_material(k["body"], k["bodyColor"], k["bodyColor"]), pin_top=True)
    recipes = world.kit["recipes"]
    lights = []
    coll = bpy.context.scene.collection
    meshes = placeholders = 0
    for name, x, y, z, yaw, scale in world.props:
        if place_mesh(coll, name, x, FLOOR_TOP + y, z, yaw, scale, hang=recipes[name].get("hang", False)):
            meshes += 1
        else:
            placeholders += 1
            prop_boxes(batch, recipes[name], x, FLOOR_TOP + y, z, yaw, scale)
        light = recipes[name].get("light")
        if light:
            at = mul(rot_y(math.radians(yaw)), tuple(v * scale for v in light["at"]))
            lights.append((x + at[0], FLOOR_TOP + y + at[1], z + at[2], light["color"], light["range"] * scale, light["brightness"]))
    # the glowing falls of the effects rows drawn as an emissive sheet (the client's beam)
    for e in world.fx:
        if e["kind"] == "IslandFall":
            y0 = FLOOR_TOP + world.top(e["x"], e["z"])
            mat = flat_material("8FE6FF", neon=True)
            w2 = e.get("size", 6) * 0.4
            batch.quad(mat, [(e["x"] - w2, y0, e["z"]), (e["x"] + w2, y0, e["z"]), (e["x"] + w2, y0 + 44, e["z"]), (e["x"] - w2, y0 + 44, e["z"])],
                       [(0, 0), (1, 0), (1, 1), (0, 1)])
            batch.quad(mat, [(e["x"], y0, e["z"] - w2), (e["x"], y0, e["z"] + w2), (e["x"], y0 + 44, e["z"] + w2), (e["x"], y0 + 44, e["z"] - w2)],
                       [(0, 0), (1, 0), (1, 1), (0, 1)])
    # the wreck's smoke: a few pale puffs drifting off the engine (the client's WorldFx emitter, data/WorldFx WreckSmoke)
    for e in world.fx:
        if e["kind"] == "WreckSmoke":
            y0 = FLOOR_TOP + world.top(e["x"], e["z"]) + e.get("lift", 0)
            for dx, dy, dz, s, col in ((0, 0.6, 0, 1.4, "6E6862"), (0.5, 2.0, 0.2, 2.0, "8A847E"), (1.3, 3.7, 0.5, 2.5, "A39E98"),
                                       (2.3, 5.6, 0.9, 2.8, "B9B4AD"), (3.4, 7.6, 1.3, 3.0, "CBC7C1")):
                m = flat_material(col)
                cx, cy, cz = e["x"] + dx, y0 + dy, e["z"] + dz
                box_faces(batch, cx - s / 2, cy - s / 2, cz - s / 2, cx + s / 2, cy + s / 2, cz + s / 2, m, m, bottom_mat=m)
    # the landmarks of the layout, at their yaw on the ground under their centre
    for name, x, z, yaw, scale in layout_landmarks(world_id):
        if not place_mesh(coll, name, x, FLOOR_TOP + world.h[world.index_at(x, z)], z, yaw, scale):
            print("no export for landmark", name, flush=True)
    # the camp as CampRenderer stands it on MeadowFloor (the deck itself is a ground solid): the ship's hull, the stations, the spawn pad
    camp = camp_layout()
    place_mesh(coll, camp["shipName"], camp["ship"][0], FLOOR_TOP, camp["ship"][1], 0, 1)
    for job, (x, z) in camp["stations"].items():
        place_mesh(coll, camp["names"].get(job, ""), x, FLOOR_TOP, z, 0, 1)
    spawn = flat_material("FFC83D")
    box_faces(batch, -3, FLOOR_TOP + 0.4, -3, 3, FLOOR_TOP + 0.6, 3, spawn, spawn)
    # the shrine: World 1's hero model; World 2's ring of shrine stones round the pedestal (data/<layout> Props)
    sx, sz = world.desc["shrine"]
    sy = FLOOR_TOP + world.h[world.index_at(sx, sz)]
    if not (world_id == 1 and place_mesh(coll, "Shrine", sx, sy, sz, 0, 1)):
        stone = flat_material("9E9E8E" if world_id == 1 else "BFD9E6")
        for n in range(8):
            a = n / 8 * math.tau
            cx, cz = sx + math.cos(a) * 10, sz + math.sin(a) * 10
            if not place_mesh(coll, "ShrineStone", cx, sy, cz, math.degrees(math.pi / 2 - a), 1):
                box_faces(batch, cx - 1, sy, cz - 1, cx + 1, sy + 5, cz + 1, stone, stone)
        if not place_mesh(coll, "Pedestal", sx, sy, sz, 0, 1):
            glow = flat_material("2ECC71" if world_id == 1 else "68C9FE", neon=True)
            box_faces(batch, sx - 1, sy + 1.5, sz - 1, sx + 1, sy + 3.5, sz + 1, glow, glow)
    print("props: %d meshes, %d block placeholders" % (meshes, placeholders), flush=True)
    batch.flush(coll)
    world.preview_lights = lights
    return world, stats


def night_lights(world, scene):
    """The props' PointLights as Blender point lights (the night shot is lit by them, B48: light from the props)."""
    for k, (x, y, z, color, rng, brightness) in enumerate(world.preview_lights):
        data = bpy.data.lights.new(f"P{k}", "POINT")
        data.color = hex_lin(color)[:3]
        data.energy = 40.0 * brightness * (rng / 14.0) ** 2
        data.shadow_soft_size = 0.6
        obj = bpy.data.objects.new(f"P{k}", data)
        obj.location = Vector(bl(x, y, z))
        scene.collection.objects.link(obj)


def setup(scene, world_id, samples, night=False):
    scene.render.engine = "CYCLES"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 3
    scene.cycles.use_denoising = True
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    sky, sun_col, energy, rot = NIGHT if night else SKY[world_id]
    w = bpy.data.worlds.new("Sky")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = sky + (1.0,)
    bg.inputs["Strength"].default_value = 2.2 if night else 0.9
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
        "camp": ((34.0, 20.0, -44.0), (-2.0, 1.0, 2.0), 22.0),
        "falls": ((-30.0, 18.0, 66.0), (-66.0, 6.0, 104.0), 28.0),
        "starhollow": ((62.0, 48.0, 38.0), (138.0, 18.0, 136.0), 24.0),
        "wide": ((150.0, 120.0, -215.0), (-30.0, 0.0, 40.0), 30.0)},
    2: {"hero": ((62.0, 44.0, -40.0), (-40.0, 4.0, 60.0), 26.0),
        "camp": ((34.0, 20.0, -44.0), (-2.0, 1.0, 2.0), 22.0),
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
    ap.add_argument("--night", action="store_true", help="the moonlit look (the Starhollow Forest is night at any hour)")
    ap.add_argument("--placeholders", action="store_true", help="every prop as its block placeholder (no exported meshes)")
    a = ap.parse_args(argv)
    global USE_MESHES
    USE_MESHES = not a.placeholders
    out = pathlib.Path(a.out)
    if "assets" in out.resolve().parts:
        print("refusing to write under assets/")
        return 2
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    world, stats = build(a.world)
    print("built", stats, flush=True)
    setup(scene, a.world, a.samples, a.night)
    if a.night:
        night_lights(world, scene)
    scene.render.image_settings.file_format = "PNG"
    for view in [v for v in a.views.split(",") if v]:
        camera(scene, view, a.size, a.world)
        scene.render.filepath = str(out / f"world{a.world}_{view}.png")
        bpy.ops.render.render(write_still=True)
        print("rendered", scene.render.filepath, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
