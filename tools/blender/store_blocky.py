"""The launch store set in the block-cell look (B44, B49): three icon options (A, B, C) and six thumbnail options (1 to 6), rendered from
the exported block-cell models in assets/models/ and the generated worlds (world_preview.build), then finished by
tools/store_blocky_compose.py (Pillow, system python3): the painted sky, bloom, the thick navy outline round the aliens, the 2D overlays
(the capture bar and the reveal card in block cells), the Fredoka One title on 1, 3 and 5, the 64 px icon strip and the choice sheet.

Run through store_renders.py, so it can be re-run after any model pass lands (it reads assets/models as they are on the branch):

    $BPY tools/blender/store_renders.py --set 2026-10-22 [--only A,B,1] [--samples 48] [--scale 0.5]

Each shot writes into a scratch folder (--raw-dir, default the system temp dir): <shot>_raw.png (RGBA, the sky transparent), the alien
masks <shot>_hero.png and <shot>_cast.png (the alpha of each group as seen, everything else held out) and <shot>.json (the frame size and the
projected points the overlays need). Nothing is written under assets/.
"""
from __future__ import annotations

import json
import math
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools/blocky"))

import bpy  # noqa: E402
from bpy_extras.object_utils import world_to_camera_view  # noqa: E402
from mathutils import Vector  # noqa: E402

import world_preview as WP  # noqa: E402

MODELS = ROOT / "assets/models"
SCALE = 1.0
SAMPLES = 48
RAW: pathlib.Path = pathlib.Path(".")
GLOW = {"Common": 0.0, "Uncommon": 0.0, "Rare": 1.0, "Epic": 1.6, "Legendary": 2.2, "Cosmic": 3.0, "Secret": 3.0}
TIER_HEX = {"Common": "B0B0B0", "Uncommon": "57F96C", "Rare": "3B82F6", "Epic": "C026D3", "Legendary": "F59E0B", "Cosmic": "EC4899",
            "Secret": "8B5CF6"}  # Secret's tier colour is near-black, so its light is its own glow (Syrinx's violet, Blocky-Style 7)


# ------------------------------------------------------------------------------------------------ scene
def new_scene(w, h, world_id=None, night=False, sky=None, sun=None):
    """An empty scene (or a generated world), Cycles on the CPU, film transparent (compose paints the sky), Standard view."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    WP._images.clear()
    WP._mats.clear()
    WP._lib.clear()
    sc = bpy.context.scene
    for name in ("Hero", "Cast", "FX"):
        sc.collection.children.link(bpy.data.collections.new(name))
    world = None
    if world_id:
        world, _ = WP.build(world_id)
    WP.setup(sc, world_id or 1, SAMPLES, night)
    if world is not None and night:
        WP.night_lights(world, sc)
    if sky:
        bg = sc.world.node_tree.nodes["Background"]
        bg.inputs["Color"].default_value = (*sky[0], 1.0)
        bg.inputs["Strength"].default_value = sky[1]
    if sun:
        s = bpy.data.objects["Sun"]
        s.data.energy, s.data.color = sun[0], sun[1]
        s.rotation_euler = tuple(math.radians(a) for a in sun[2])
    sc.render.film_transparent = True
    sc.render.resolution_x, sc.render.resolution_y = round(w * SCALE), round(h * SCALE)
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.max_bounces = 4
    sc.cycles.transparent_max_bounces = 12
    return sc, world


def ground_y(world, x, z):
    """Roblox ground height at (x, z) of a generated world."""
    return WP.FLOOR_TOP + world.top(x, z)


def at(world, x, z, lift=0.0):
    """Blender point on the ground of a generated world at Roblox (x, z)."""
    return Vector(WP.bl(x, ground_y(world, x, z) + lift, z))


def frames_of(sid):
    """(frame names, columns) of a species' face sheet, from its notes.md."""
    text = (MODELS / sid / "notes.md").read_text(encoding="utf-8")
    m = re.search(r"frames \(([^)]*)\) in \S+, (\d+) a row", text)
    if not m:
        return ["open"], 1
    return [f.strip() for f in m.group(1).split(",")], int(m.group(2))


def set_face(objs, sid, frame):
    """Show a named flipbook frame on the imported FacePlate by moving its UVs (the GLB maps frame 0)."""
    names, cols = frames_of(sid)
    if frame not in names:
        return
    k = names.index(frame)
    rows = math.ceil(len(names) / cols)
    du, dv = (k % cols) / cols, -(k // cols) / rows
    for o in objs:
        if o.type == "MESH" and o.name.startswith("FacePlate"):
            for loop in o.data.uv_layers.active.data:
                loop.uv = (loop.uv[0] + du, loop.uv[1] + dv)


def boost_glow(objs, factor):
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if not m or not m.node_tree:
                continue
            for n in m.node_tree.nodes:
                if n.type == "BSDF_PRINCIPLED" and n.inputs["Emission Strength"].default_value > 0:
                    n.inputs["Emission Strength"].default_value *= factor


def alien(sid, pos, face=None, yaw=0.0, frame="open", group="Hero", glow=1.0, scale=1.0):
    """Import an exported block-cell alien at a Blender point, turned to look at `face` (a Blender point) plus `yaw` degrees."""
    layer = bpy.context.view_layer.layer_collection.children[group]
    bpy.context.view_layer.active_layer_collection = layer
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(MODELS / sid / f"{sid}.glb"))
    objs = [o for o in bpy.data.objects if o not in before]
    root = bpy.data.objects.new(sid, None)
    bpy.data.collections[group].objects.link(root)
    for o in objs:
        if o.parent is None:
            o.parent = root
        for slot in o.material_slots:
            if slot.material and slot.material.node_tree:
                for n in slot.material.node_tree.nodes:
                    if n.type == "TEX_IMAGE":
                        n.interpolation = "Closest"
    rot = math.radians(yaw)
    if face is not None:
        d = Vector(face) - Vector(pos)
        rot += math.atan2(d.y, d.x) - math.pi / 2  # the model's front is Blender +Y
    root.location = Vector(pos)
    root.rotation_euler = (0.0, 0.0, rot)
    root.scale = (scale, scale, scale)
    set_face(objs, sid, frame)
    if glow != 1.0:
        boost_glow(objs, glow)
    bpy.context.view_layer.update()
    return root, [o for o in objs if o.type == "MESH"]


def prop(name, pos, yaw=0.0, scale=1.0, group="FX"):
    """A block-cell prop's exported mesh at a Blender point (not outlined)."""
    WP.place_mesh(bpy.data.collections[group], name, *WP_from_bl(pos), yaw, scale)


def WP_from_bl(p):
    """Blender (x, y, z up) to Roblox (x, y up, z): the inverse of WP.bl."""
    return (p[0], p[2], -p[1])


def bounds(objs):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    return lo, hi


def emissive(name, hexcol, strength, alpha=1.0):
    """An emission material (see-through where alpha < 1), the block-cell effects' Neon."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out, emit = nt.nodes.new("ShaderNodeOutputMaterial"), nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = WP.hex_lin(hexcol)
    emit.inputs["Strength"].default_value = strength
    if alpha < 1.0:
        mix, clear = nt.nodes.new("ShaderNodeMixShader"), nt.nodes.new("ShaderNodeBsdfTransparent")
        mix.inputs[0].default_value = alpha
        nt.links.new(clear.outputs[0], mix.inputs[1])
        nt.links.new(emit.outputs[0], mix.inputs[2])
        nt.links.new(mix.outputs[0], out.inputs["Surface"])
    else:
        nt.links.new(emit.outputs[0], out.inputs["Surface"])
    return mat


def cube(centre, size, mat, rot_z=0.0, group="FX", dims=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=Vector(centre))
    o = bpy.context.active_object
    o.scale = dims if dims else (size, size, size)
    o.rotation_euler = (0.0, 0.0, rot_z)
    o.data.materials.append(mat)
    for c in list(o.users_collection):
        c.objects.unlink(o)
    bpy.data.collections[group].objects.link(o)
    return o


def ring(centre, radius, hexcol, count=24, cell=0.22, strength=6.0, z=0.06):
    """A ground ring of square glowing cells (RingPulse, the Legendary and up's ground ring)."""
    mat = emissive(f"Ring{hexcol}", hexcol, strength)
    for k in range(count):
        a = k / count * math.tau
        cube(Vector(centre) + Vector((math.cos(a) * radius, math.sin(a) * radius, z)), cell, mat, rot_z=a, dims=(cell, cell, cell * 0.5))


def pool(centre, radius, hexcol, strength=1.6):
    """A light pool: a stepped disc of three flat cells (Spectacle presence from Rare)."""
    for k, (r, a) in enumerate(((1.0, 0.25), (0.72, 0.35), (0.45, 0.5))):
        s = radius * r * 2
        cube(Vector(centre) + Vector((0, 0, 0.02 + k * 0.012)), s, emissive(f"Pool{hexcol}{k}", hexcol, strength, alpha=a), rot_z=math.radians(45),
             dims=(s, s, 0.02))


def pillar(centre, width, height, hexcol, strength=3.0, alpha=0.35):
    """A pillar of light straight up (Cosmic and Secret), a see-through emissive column in stepped cells."""
    for k, (wf, af) in enumerate(((1.0, 0.35), (0.6, 0.7), (0.3, 1.0))):
        w = width * wf
        cube(Vector(centre) + Vector((0, 0, height / 2)), w, emissive(f"Pillar{hexcol}{k}", hexcol, strength, alpha=alpha * af),
             dims=(w, w, height))


def motes(centre, radius, hexcol, count=6, cell=0.16, height=1.6, avoid=None, strength=6.0, seed=1):
    """Orbiting glowing cells round the body (Legendary up), none in front of the face (towards `avoid`, a Blender point)."""
    mat = emissive(f"Mote{hexcol}", hexcol, strength)
    c = Vector(centre)
    fwd = None
    if avoid is not None:
        fwd = (Vector(avoid) - c)
        fwd.z = 0
        fwd.normalize()
    for k in range(count):
        a = (k + 0.5 * (seed % 2)) / count * math.tau + seed
        p = c + Vector((math.cos(a) * radius, math.sin(a) * radius, height + 0.35 * math.sin(3 * a)))
        if fwd is not None and (p - c).normalized().dot(fwd) > 0.55:
            continue
        cube(p, cell, mat, rot_z=a)


def point_light(pos, hexcol, energy, radius=0.5):
    data = bpy.data.lights.new("L", "POINT")
    data.color = WP.hex_lin(hexcol)[:3]
    data.energy = energy
    data.shadow_soft_size = radius
    o = bpy.data.objects.new("L", data)
    o.location = Vector(pos)
    bpy.context.scene.collection.objects.link(o)
    return o


def area_light(pos, target, hexcol, energy, size=3.0):
    data = bpy.data.lights.new("A", "AREA")
    data.color = WP.hex_lin(hexcol)[:3]
    data.energy = energy
    data.size = size
    o = bpy.data.objects.new("A", data)
    o.location = Vector(pos)
    o.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(o)
    return o


def camera(pos, target, lens, focus=None, fstop=None):
    sc = bpy.context.scene
    data = bpy.data.cameras.new("Cam")
    data.lens = lens
    data.clip_start = 0.1
    data.clip_end = 3000.0
    if focus:
        data.dof.use_dof = True
        data.dof.focus_distance = focus
        data.dof.aperture_fstop = fstop or 2.8
    cam = bpy.data.objects.new("Cam", data)
    sc.collection.objects.link(cam)
    cam.location = Vector(pos)
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    bpy.context.view_layer.update()
    return cam


def project(points):
    """Blender points to image fractions (x right, y down) in the current camera."""
    sc = bpy.context.scene
    out = {}
    for k, p in points.items():
        v = world_to_camera_view(sc, sc.camera, Vector(p))
        out[k] = [round(v.x, 4), round(1.0 - v.y, 4)]
    return out


def mask(group, path):
    """The alpha of one collection as the camera sees it: every other object held out, a few samples, no denoise."""
    sc = bpy.context.scene
    keep = set(bpy.data.collections[group].all_objects)
    saved = {o.name: o.is_holdout for o in sc.objects}
    for o in sc.objects:
        o.is_holdout = o not in keep
    samples, denoise = sc.cycles.samples, sc.cycles.use_denoising
    sc.cycles.samples, sc.cycles.use_denoising = 6, False
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    sc.cycles.samples, sc.cycles.use_denoising = samples, denoise
    for o in sc.objects:
        o.is_holdout = saved.get(o.name, False)


def finish(shot, meta, points=None):
    """Render the beauty pass, the hero and cast masks and the JSON for the compose step."""
    sc = bpy.context.scene
    sc.render.filepath = str(RAW / f"{shot}_raw.png")
    bpy.ops.render.render(write_still=True)
    print("rendered", shot, flush=True)
    for group in ("Hero", "Cast"):
        if bpy.data.collections[group].all_objects:
            mask(group, RAW / f"{shot}_{group.lower()}.png")
    meta = dict(meta, size=[sc.render.resolution_x, sc.render.resolution_y], points=project(points or {}))
    (RAW / f"{shot}.json").write_text(json.dumps(meta, indent=1))


def clear_props(centre, radius):
    """Remove the world's placed prop meshes standing within `radius` studs (ground distance) of a Blender point: a camera's foreground."""
    for o in list(bpy.context.scene.collection.objects):
        if o.type != "MESH" or o.name.startswith(("M_", "F_")):
            continue
        d = o.matrix_world.translation - Vector(centre)
        if math.hypot(d.x, d.y) < radius:
            bpy.data.objects.remove(o)


def head_of(objs, lift=0.0):
    lo, hi = bounds(objs)
    return Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z + lift)), Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, (lo.z + hi.z) / 2))


# ------------------------------------------------------------------------------------------------ icons (1024 square, composed to 512)
def icon_a():
    """Moop's face close-up on the meadow, the crashed ship behind (out of focus), a deep blue day sky."""
    sc, world = new_scene(1024, 1024, world_id=1, sky=((0.75, 0.86, 1.0), 1.0), sun=(3.4, (1.0, 0.95, 0.85), (50, 0, 160)))
    # the wreck stands at Roblox (28, -12); Moop stands between it and the camp, the camera low beyond Moop looking back at the wreck
    p = at(world, 34.0, 6.0)
    wreck = at(world, 28.0, -12.0)
    away = (p - wreck)
    away.z = 0
    away.normalize()
    side = Vector((-away.y, away.x, 0))
    cam_pos = p + away * 4.4 + side * 0.9 + Vector((0, 0, 1.55))
    _, objs = alien("Mossbop", p, face=cam_pos, yaw=-8)
    head, mid = head_of(objs)
    area_light(cam_pos + Vector((1.5, 0.5, 1.5)), mid, "FFF6E6", 180, 2.5)
    cam = camera(cam_pos, mid + Vector((0.12, 0, 0.08)), 40, focus=(cam_pos - mid).length, fstop=2.0)
    finish("icon_A", {"sky": "day"}, {"head": head, "mid": mid})


def icon_b():
    """Raddis glowing at night in the Starhollow: its sun halo, the solar eyes, the glowcaps behind."""
    sc, world = new_scene(1024, 1024, world_id=1, night=True)
    p = at(world, 131.0, 112.0)
    cam_pos = p + Vector((-3.4, -4.6, 2.2))
    _, objs = alien("Radish", p, face=cam_pos, yaw=4, frame="cycle2", glow=1.1)
    head, mid = head_of(objs)
    ring(p, 1.9, "FFB347", count=22, strength=4)
    motes(p, 2.1, "FFE36B", count=7, height=2.4, avoid=cam_pos, seed=2, strength=3)
    point_light(p + Vector((0, 0, 4.6)), "FFC85A", 60, 0.6)
    area_light(cam_pos + Vector((0.8, 0, 1.2)), mid, "FFE2B8", 70, 2.0)
    area_light(p + Vector((2.5, 3.5, 3.5)), mid, "C9A8FF", 220, 3.0)
    camera(cam_pos, mid + Vector((0, 0, 0.12)), 38, focus=(cam_pos - mid).length, fstop=2.2)
    finish("icon_B", {"sky": "night", "bloom": 1.0, "aura": "FFC24A"}, {"head": head, "mid": mid})


def icon_c():
    """Three aliens of rising rarity squeezed together: Moop (Common), Vixa (Rare) and Aurelyx (Epic) on the meadow."""
    sc, world = new_scene(1024, 1024, world_id=1, sky=((0.78, 0.86, 1.0), 1.0), sun=(3.2, (1.0, 0.95, 0.86), (48, 0, 200)))
    base = at(world, 32.0, 31.0)
    cam_pos = base + Vector((0.0, -9.8, 3.1))
    _, a = alien("Mossbop", base + Vector((-1.85, -0.45, 0)), face=cam_pos, yaw=10)
    # Aurelyx, the rarest, stands behind on a grass block so its face shows between the two
    batch = WP.MeshBatch()
    gx, gy = base.x + 0.05, -(base.y + 1.0)
    WP.box_faces(batch, gx - 1.0, base.z - 1.0, gy - 1.0, gx + 1.0, base.z + 1.0, gy + 1.0, WP.tile_material("GrassTop", "6FBF4A", "8A5A3B"),
                 WP.tile_material("GrassSide", "6FBF4A", "8A5A3B"), sides=0xF)
    batch.flush(bpy.data.collections["FX"])
    _, b = alien("Shimmerlynx", base + Vector((0.05, 1.0, 1.0)), face=cam_pos, yaw=0, glow=1.0)
    _, c = alien("Sparkfox", base + Vector((1.7, -0.5, 0)), face=cam_pos, yaw=-12)
    lo, hi = bounds(a + b + c)
    mid = (lo + hi) / 2
    pool(base + Vector((1.7, -0.5, 0)), 0.9, TIER_HEX["Rare"])
    area_light(cam_pos + Vector((2, 0, 2)), mid, "FFF6E6", 260, 3.0)
    camera(cam_pos, mid + Vector((0, 0, 0.1)), 42, focus=(cam_pos - mid).length, fstop=2.8)
    finish("icon_C", {"sky": "day"}, {"mid": mid, "top": Vector((mid.x, mid.y, hi.z))})


# ------------------------------------------------------------------------------------------------ thumbnails (1920 x 1080)
SHIP_NOTE = ROOT / "docs/vault/07-alien-game/Props/Ship.md"


def ghost_above(objs, cut_z):
    """Half-built: every material above world height cut_z turns into the module ghost (a see-through Select-blue glow), as CampRenderer
    draws the modules not yet built."""
    done = set()
    for o in objs:
        for slot in o.material_slots:
            m = slot.material
            if not m or m.name in done or not m.node_tree:
                continue
            done.add(m.name)
            nt = m.node_tree
            out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
            src = out.inputs["Surface"].links[0].from_socket
            geo, sep, cmp_ = nt.nodes.new("ShaderNodeNewGeometry"), nt.nodes.new("ShaderNodeSeparateXYZ"), nt.nodes.new("ShaderNodeMath")
            cmp_.operation = "GREATER_THAN"
            cmp_.inputs[1].default_value = cut_z
            nt.links.new(geo.outputs["Position"], sep.inputs[0])
            nt.links.new(sep.outputs["Z"], cmp_.inputs[0])
            emit, clear, mixg, mix = (nt.nodes.new("ShaderNodeEmission"), nt.nodes.new("ShaderNodeBsdfTransparent"),
                                      nt.nodes.new("ShaderNodeMixShader"), nt.nodes.new("ShaderNodeMixShader"))
            emit.inputs["Color"].default_value = WP.hex_lin("68C9FE")
            emit.inputs["Strength"].default_value = 1.4
            mixg.inputs[0].default_value = 0.42
            nt.links.new(clear.outputs[0], mixg.inputs[1])
            nt.links.new(emit.outputs[0], mixg.inputs[2])
            nt.links.new(cmp_.outputs[0], mix.inputs[0])
            nt.links.new(src, mix.inputs[1])
            nt.links.new(mixg.outputs[0], mix.inputs[2])
            nt.links.new(mix.outputs[0], out.inputs["Surface"])


def thumb_1():
    """The camp moment: aliens at work round the half-built ship, the player, a Rare popping out of its portal of cells."""
    import blocky_build as B
    import cells as C
    import spec as S
    sc, world = new_scene(1920, 1080, world_id=1, sky=((0.75, 0.86, 1.0), 1.0), sun=(3.4, (1.0, 0.95, 0.85), (52, 0, 150)))
    camp = WP.camp_layout()
    sx, sz = camp["ship"]
    ship_at = Vector(WP.bl(sx, WP.FLOOR_TOP + 1.25, sz))
    tmp = pathlib.Path(bpy.app.tempdir or "/tmp")
    layer = bpy.context.view_layer.layer_collection.children["FX"]
    bpy.context.view_layer.active_layer_collection = layer
    made = B.build(S.load(SHIP_NOTE), str(tmp), offset=tuple(ship_at), cell=C.WORLD_CELL)
    for o in made["objects"]:   # the game's ship stands about 1.5 times the diorama prop on its 12 x 20 slab
        o.scale = (1.5, 1.5, 1.5)
        o.location = ship_at + (o.location - ship_at) * 1.5
    ghost_above(made["objects"], ship_at.z + 3.6)
    # the cast at the stations (Roblox offsets from data/Camp.luau), the player on the deck, the Rare's portal in front
    cam_pos = Vector(WP.bl(-4.0, 5.2, 26.0))
    clear_props(cam_pos, 9.0)
    # the workers round the ship's front: carrying to it (facing it) or looking up at the camera; Buzzik flies a load over
    workers = [("Twiglet", (-7.5, -9.5), "ship", 0), ("Pebblet", (6.5, -8.5), "ship", 0), ("Mossbop", (-10.5, 2.0), "cam", 0),
               ("Puffpuff", (-3.0, -4.0), "cam", 0), ("Glimmo", (3.5, -1.0), "cam", 0), ("Buzzlebee", (1.0, -7.0), "ship", 3.2),
               ("Snailbyte", (-13.0, -6.0), "ship", 0)]
    for sid, (x, z), look, lift in workers:
        alien(sid, at(world, x, z, lift), face=Vector(WP.bl(sx, 2, sz)) if look == "ship" else cam_pos, yaw=0, group="Cast")
    player = at(world, -4.0, 9.0)
    port = at(world, 6.5, 13.5, 1.0)
    for o in B.avatar(tuple(player), out_dir=str(tmp)):
        for c in list(o.users_collection):
            c.objects.unlink(o)
        bpy.data.collections["Cast"].objects.link(o)
        o.rotation_euler = (0, 0, math.atan2(port.y - player.y, port.x - player.x) - math.pi / 2)
    # the portal: a square of Rare-blue cells standing up, its face a see-through glow, the Rare half through it
    face_dir = (cam_pos - port)
    face_dir.z = 0
    face_dir.normalize()
    yaw = math.atan2(face_dir.y, face_dir.x)
    side = Vector((-math.sin(yaw), math.cos(yaw), 0))
    blue, pale = emissive("PortalCell", "3B82F6", 6.0), emissive("PortalPale", "9CC8FF", 8.0)
    n, half, cell = 9, 2.2, 0.48
    for k in range(n):
        t = -half + k * (2 * half / (n - 1))
        for p in (port + side * t + Vector((0, 0, 0.6)), port + side * t + Vector((0, 0, 0.6 + 2 * half)),
                  port + side * -half + Vector((0, 0, 0.6 + half + t)), port + side * half + Vector((0, 0, 0.6 + half + t))):
            cube(p, cell, pale if k % 3 == 1 else blue, rot_z=yaw)
    cube(port + Vector((0, 0, 0.6 + half)) - face_dir * 0.1, 1, emissive("PortalFace", "3B82F6", 2.5, alpha=0.45), rot_z=yaw,
         dims=(0.06, 2 * half, 2 * half))
    rare = port + face_dir * 0.7 + Vector((0, 0, 1.2))
    _, robjs = alien("Zapfinch", rare, face=cam_pos, yaw=0, frame="glint1", glow=GLOW["Rare"] * 1.5)
    for k in range(10):
        a = k * 2.4
        cube(port + face_dir * (0.4 + 0.25 * (k % 3)) + side * (math.cos(a) * 2.8) + Vector((0, 0, 2.8 + math.sin(a) * 2.6)), 0.22,
             pale if k % 2 else blue, rot_z=a)
    point_light(rare + face_dir * 1.2, "6FA8FF", 260, 1.0)
    head, mid = head_of(robjs)
    target = Vector(WP.bl(1.0, 3.6, -2.0))
    camera(cam_pos, target, 24, focus=(cam_pos - mid).length, fstop=5.6)
    finish("thumb_1", {"sky": "day", "title": True}, {"rare": mid, "portal": port + Vector((0, 0, 0.6 + half))})


def thumb_2():
    """The catch: Gaira (Legendary) at dusk in the meadow, its gold ground ring, light and orbiting motes; the bar goes on in compose."""
    sc, world = new_scene(1920, 1080, world_id=1, sky=((0.62, 0.55, 0.95), 0.75), sun=(2.4, (1.0, 0.78, 0.55), (72, 0, 230)))
    p = at(world, -40.0, 30.0)
    cam_pos = p + Vector((0.0, -10.5, 2.3))
    _, objs = alien("Gaiabloom", p, face=cam_pos, yaw=-14, frame="cycle1", glow=1.0)
    head, mid = head_of(objs)
    ring(p, 2.2, "F59E0B", count=28, strength=4)
    ring(p, 3.0, "FFD36B", count=34, strength=2.5, cell=0.16)
    motes(p, 2.0, "FFE07A", count=9, height=2.4, avoid=cam_pos, seed=3, strength=3)
    pool(p, 1.6, "F59E0B", strength=0.8)
    point_light(mid + Vector((0, -1.2, 0.6)), "FFD58A", 160, 0.8)
    area_light(cam_pos + Vector((1.5, 0, 2.0)), mid, "FFF1D8", 260, 3.0)
    area_light(p + Vector((-3, 4, 3)), mid, "B07BFF", 400, 3.0)
    camera(cam_pos, mid + Vector((0, 0, -0.85)), 40, focus=(cam_pos - mid).length, fstop=2.0)
    finish("thumb_2", {"sky": "dusk", "bloom": 0.7, "aura": "F59E0B", "bar": "Legendary"}, {"head": head, "mid": mid, "feet": p})


def thumb_3():
    """The Starhollow Forest at night: the lavender path, glowcaps, the floating island and its waterfall; Lantrin on the path."""
    sc, world = new_scene(1920, 1080, world_id=1, night=True)
    cam_pos = Vector(WP.bl(96.0, 9.0, 100.0))
    look = Vector(WP.bl(176.0, 31.0, 125.0))
    clear_props(cam_pos, 5.0)
    hp = at(world, 101.5, 106.5)
    _, objs = alien("Lanternewt", hp, face=cam_pos, yaw=6, glow=1.5)
    head, mid = head_of(objs)
    point_light(mid + Vector((0, 0, 0.8)), "FFD9A0", 60, 0.5)
    area_light(cam_pos + Vector((1, 0, 1.5)), mid, "D8C8FF", 120, 3.0)
    camera(cam_pos, look, 24, focus=(cam_pos - mid).length, fstop=4.0)
    finish("thumb_3", {"sky": "night", "bloom": 1.0, "title": True, "stars": True},
           {"hero": mid, "island": Vector(WP.bl(158.0, 52.0, 160.0))})


def thumb_4():
    """World 2 Frostbyte at night: the frozen lake, pines, Fenrir with its gibbous moon; the aurora and the big moon are painted in compose."""
    sc, world = new_scene(1920, 1080, world_id=2, night=True)
    bg = sc.world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.10, 0.16, 0.34, 1.0)
    bg.inputs["Strength"].default_value = 1.0
    s = bpy.data.objects["Sun"]
    s.data.energy, s.data.color = 0.9, (0.70, 0.82, 1.0)
    hp = at(world, 48.0, -60.0)
    cam_pos = hp + Vector((-3.2, 9.2, 2.0))
    _, objs = alien("Fenripup", hp, face=cam_pos, yaw=-6, frame="cycle3", glow=1.2)
    head, mid = head_of(objs)
    motes(hp, 1.8, "B9D4FF", count=7, height=2.2, avoid=cam_pos, seed=4)
    ring(hp, 1.8, "8FD0FF", count=22, strength=3)
    area_light(cam_pos + Vector((1.2, 0, 1.5)), mid, "DDE9FF", 200, 2.5)
    area_light(hp + Vector((2.5, -3.0, 2.5)), mid, "7FE8D0", 300, 3.0)
    look = mid + Vector((3.5, -10.0, 2.6))
    camera(cam_pos, look, 26, focus=(cam_pos - mid).length, fstop=3.2)
    finish("thumb_4", {"sky": "aurora", "bloom": 0.8, "stars": True}, {"hero": mid, "head": head})


LADDER = [("Mossbop", "Common"), ("Lanternewt", "Uncommon"), ("Sparkfox", "Rare"), ("Thunderhog", "Epic"), ("Gaiabloom", "Legendary"),
          ("Radish", "Cosmic"), ("Panpipe", "Secret")]


def thumb_5():
    """The rarity ladder: Common to Secret on block pedestals that step up, each glowing more (light pool, aura, ring, motes, pillar)."""
    sc, world = new_scene(1920, 1080, sky=((0.20, 0.18, 0.45), 1.2), sun=(2.6, (1.0, 0.94, 0.86), (55, 0, 200)))
    cam_pos = Vector((0.0, -31.0, 7.0))
    stone = WP.tile_material("Stone", "8E8AA8", "6E6A8E")
    grass = WP.tile_material("GrassTop", "6FBF4A", "8A5A3B")
    side = WP.tile_material("GrassSide", "6FBF4A", "8A5A3B")
    batch = WP.MeshBatch()
    pts = {}
    n = len(LADDER)
    for k, (sid, tier) in enumerate(LADDER):
        x = (k - (n - 1) / 2) * 3.55
        y = 0.5 * abs(k - (n - 1) / 2) ** 1.2
        h = 0.5 + 0.25 * k
        # a 2 x 2 stud grass block per alien on a stone plinth (Roblox coords for box_faces: x, y up, z = -Blender y)
        WP.box_faces(batch, x - 1.25, -2.0, -y - 1.25, x + 1.25, h - 0.5, -y + 1.25, stone, stone, sides=0xF)
        WP.box_faces(batch, x - 1.25, h - 0.5, -y - 1.25, x + 1.25, h, -y + 1.25, grass, side, sides=0xF)
        p = Vector((x, y, h))
        _, objs = alien(sid, p, face=cam_pos, yaw=0, glow=1.0, frame="glint1" if k >= 2 else "open")
        lo, hi = bounds(objs)
        col = TIER_HEX[tier]
        if k >= 1:
            pool(p, 0.9 + 0.08 * k, col, strength=0.4 + 0.25 * k)
        if k >= 2:
            point_light(p + Vector((0, -1.0, 1.4)), col, 10 + 12 * k, 0.6)
        if k >= 4:
            ring(p, 1.45, col, count=20, strength=3.5, cell=0.18)
            motes(p, 1.35, col, count=6, height=hi.z - p.z + 0.2, avoid=cam_pos, seed=k, strength=3)
        if k >= 5:
            pillar(p, 1.3, 40.0, "FF8AD0" if tier == "Cosmic" else "A57CFF", strength=1.2, alpha=0.25)
        pts[tier] = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, (lo.z + hi.z) / 2))
        pts[tier + "_top"] = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, hi.z))
    batch.flush(bpy.data.collections["FX"])
    area_light(cam_pos + Vector((0, 4, 6)), Vector((0, 0, 2)), "FFF4E6", 2200, 12.0)
    camera(cam_pos, Vector((0.0, 0.0, 3.6)), 40)
    finish("thumb_5", {"sky": "ladder", "bloom": 0.8, "title": True, "tiers": [t for _, t in LADDER]}, pts)


def thumb_6():
    """The reveal: Raddis for the Cosmic card, seen straight on, transparent; the card, its pixel sky and the bursts are drawn in compose."""
    sc, world = new_scene(1200, 1200, sky=((0.9, 0.86, 1.0), 1.1), sun=(3.0, (1.0, 0.95, 0.88), (45, 0, 210)))
    p = Vector((0, 0, 0))
    cam_pos = Vector((1.6, -9.0, 2.6))
    _, objs = alien("Radish", p, face=cam_pos, yaw=-6, frame="cycle4", glow=1.0)
    lo, hi = bounds(objs)
    mid = (lo + hi) / 2
    area_light(cam_pos + Vector((2, 0, 3)), mid, "FFF4E6", 400, 4.0)
    area_light(Vector((-3, 3, 4)), mid, "FF9AD8", 300, 3.0)
    camera(cam_pos, mid, 50)
    finish("thumb_6", {"sky": "none", "card": "Cosmic"}, {"mid": mid})


SHOTS = {"A": ("icon_A", icon_a), "B": ("icon_B", icon_b), "C": ("icon_C", icon_c), "1": ("thumb_1", thumb_1), "2": ("thumb_2", thumb_2),
         "3": ("thumb_3", thumb_3), "4": ("thumb_4", thumb_4), "5": ("thumb_5", thumb_5), "6": ("thumb_6", thumb_6)}


def run(raw_dir, only=None, samples=48, scale=1.0):
    """Render the shots (all, or the keys in `only`) into raw_dir; returns the shot names rendered."""
    global RAW, SAMPLES, SCALE
    RAW, SAMPLES, SCALE = pathlib.Path(raw_dir), samples, scale
    RAW.mkdir(parents=True, exist_ok=True)
    done = []
    for key, (name, fn) in SHOTS.items():
        if only and key not in only:
            continue
        fn()
        done.append(name)
    return done
