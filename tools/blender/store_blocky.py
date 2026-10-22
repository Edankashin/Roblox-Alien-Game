"""The launch store set in the block-cell look (B44, B49): three icon options (A, B, C) and six thumbnail options (1 to 6), rendered from
the exported block-cell models in assets/models/ and the generated worlds (world_preview.build), then finished by
tools/store_blocky_compose.py (Pillow, system python3): the painted sky, bloom, the thick navy outline round the aliens, the 2D overlays
(the capture bar and the reveal card in block cells), the Fredoka One title on 1, 3 and 5, the 64 px icon strip and the choice sheet.

Run through store_renders.py, so it can be re-run after any model pass lands (it reads assets/models as they are on the branch):

    $BPY tools/blender/store_renders.py --set 2026-10-22 [--only A,B,1] [--samples 48] [--scale 0.5]
    $BPY tools/blender/store_renders.py --set 2026-10-22 --only S1,S2,S3      (the scenic hero thumbnails; each also writes <shot>_depth.png)

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
    finish("icon_B", {"sky": "night", "bloom": 0.6, "aura": "FFC24A"}, {"head": head, "mid": mid})


def icon_c():
    """Three aliens of rising rarity squeezed together: Moop (Common), Vixa (Rare) and Aurelyx (Epic) on the meadow."""
    sc, world = new_scene(1024, 1024, world_id=1, sky=((0.78, 0.86, 1.0), 1.0), sun=(3.2, (1.0, 0.95, 0.86), (48, 0, 200)))
    base = at(world, 32.0, 31.0)
    cam_pos = base + Vector((0.0, -9.8, 3.6))
    clear_props(cam_pos, 6.0)
    _, a = alien("Mossbop", base + Vector((-2.0, -0.45, 0)), face=cam_pos, yaw=10)
    # Aurelyx, the rarest, stands behind on a grass block so its face shows between the two
    batch = WP.MeshBatch()
    gx, gy = base.x - 0.45, -(base.y + 1.0)
    WP.box_faces(batch, gx - 1.0, base.z - 1.0, gy - 1.0, gx + 1.0, base.z + 1.0, gy + 1.0, WP.tile_material("GrassTop", "6FBF4A", "8A5A3B"),
                 WP.tile_material("GrassSide", "6FBF4A", "8A5A3B"), sides=0xF)
    batch.flush(bpy.data.collections["FX"])
    _, b = alien("Shimmerlynx", base + Vector((-0.45, 1.0, 1.0)), face=cam_pos, yaw=0, glow=1.0)
    _, c = alien("Sparkfox", base + Vector((1.9, -0.5, 0)), face=cam_pos, yaw=-12)
    lo, hi = bounds(a + b + c)
    mid = (lo + hi) / 2
    pool(base + Vector((1.9, -0.5, 0)), 0.9, TIER_HEX["Rare"])
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


def half_built_ship(cut=3.2, offset=(0.0, 0.0)):
    """The ship on the camp's bay, built from its prop note at the world cell, scaled as the game stands it, every part above `cut` studs the
    blue module ghost (the modules not yet built). `offset` moves it (Roblox x, z) with a shifted world. Returns (Roblox ship x, z)."""
    import blocky_build as B
    import cells as C
    import spec as S
    camp = WP.camp_layout()
    sx, sz = camp["ship"]
    sx, sz = sx + offset[0], sz + offset[1]
    ship_at = Vector(WP.bl(sx, WP.FLOOR_TOP + 1.25, sz))
    tmp = pathlib.Path(bpy.app.tempdir or "/tmp")
    layer = bpy.context.view_layer.layer_collection.children["FX"]
    bpy.context.view_layer.active_layer_collection = layer
    made = B.build(S.load(SHIP_NOTE), str(tmp), offset=tuple(ship_at), cell=C.WORLD_CELL)
    for o in made["objects"]:   # the game's ship stands about 1.5 times the diorama prop on its 12 x 20 slab
        o.scale = (1.3, 1.3, 1.3)
        o.location = ship_at + (o.location - ship_at) * 1.3
    ghost_above(made["objects"], ship_at.z + cut)
    return sx, sz


def thumb_1():
    """The camp moment: aliens at work round the half-built ship, the player, a Rare popping out of its portal of cells."""
    import blocky_build as B
    sc, world = new_scene(1920, 1080, world_id=1, sky=((0.75, 0.86, 1.0), 1.0), sun=(3.4, (1.0, 0.95, 0.85), (52, 0, 150)))
    sx, sz = half_built_ship()
    tmp = pathlib.Path(bpy.app.tempdir or "/tmp")
    # the cast at the stations (Roblox offsets from data/Camp.luau), the player on the deck, the Rare's portal in front
    # the camera stands south-west of the ship on the deck (Roblox studs); d runs to the ship, r to the right of the view
    cx, cz = -10.0, 1.0
    dx, dz = sx - cx, sz - cz
    dl = math.hypot(dx, dz)
    dx, dz = dx / dl, dz / dl
    rx, rz = -dz, dx

    def rel(fwd, right):
        return (cx + dx * fwd + rx * right, cz + dz * fwd + rz * right)

    cam_pos = Vector(WP.bl(cx, 5.5, cz))
    clear_props(cam_pos, 8.0)
    # the workers round the ship's front: carrying to it (facing it) or looking up at the camera; Buzzik flies a load over
    workers = [("Twiglet", rel(17.0, -5.5), "ship", 0), ("Pebblet", rel(15.5, 5.0), "ship", 0), ("Mossbop", rel(11.0, -5.5), "cam", 0),
               ("Puffpuff", rel(13.0, -1.5), "cam", 0), ("Glimmo", rel(11.0, 2.0), "cam", 0.6), ("Buzzlebee", rel(16.5, 0.5), "ship", 3.6),
               ("Snailbyte", rel(18.0, -9.0), "ship", 0)]
    for sid, (x, z), look, lift in workers:
        alien(sid, at(world, x, z, lift), face=Vector(WP.bl(sx, 2, sz)) if look == "ship" else cam_pos, yaw=0, group="Cast")
    player = at(world, *rel(7.5, -2.2))
    port = at(world, *rel(9.5, 5.0), 1.0)
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
    target = Vector(WP.bl(*((lambda p: (p[0], 4.2, p[1]))(rel(18.0, 0.8)))))
    camera(cam_pos, target, 22, focus=(cam_pos - mid).length, fstop=5.6)
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
    finish("thumb_2", {"sky": "dusk", "bloom": 0.5, "aura": "F59E0B", "bar": "Legendary"}, {"head": head, "mid": mid, "feet": p})


def thumb_3():
    """The Starhollow Forest at night: the lavender path, glowcaps, the floating island and its waterfall; Lantrin on the path."""
    sc, world = new_scene(1920, 1080, world_id=1, night=True)
    cam_pos = Vector(WP.bl(96.0, 4.8, 100.0))
    look = Vector(WP.bl(172.0, 28.0, 128.0))
    hp = at(world, 103.7, 102.7)
    _, objs = alien("Lanternewt", hp, face=cam_pos, yaw=6, glow=1.5)
    head, mid = head_of(objs)
    point_light(mid + Vector((0, 0, 0.8)), "FFD9A0", 60, 0.5)
    area_light(cam_pos + Vector((1, 0, 1.5)), mid, "D8C8FF", 120, 3.0)
    camera(cam_pos, look, 18, focus=(cam_pos - mid).length, fstop=5.6)
    finish("thumb_3", {"sky": "night", "bloom": 1.0, "title": "left", "stars": True},
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
    look = mid + Vector((3.5, -10.0, 0.6))
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


# ------------------------------------------------------------------------------------------------ scenic hero thumbnails S1 to S3
# Ethan, 2026-10-22: "I want the thumbnail to show the most beautiful version of the world so that it is scenic and shows what the game
# offers." Three vistas of the generated worlds with the real models, each finished by compose's scenic path (store_blocky_compose.py):
# the stepped-cell sky, aerial haze from a depth pass, bloom on the glow cells, an aura behind each glowing rare, the navy outline per
# group, the title over the top third (and a no-title copy).
def rb(x, y, z):
    """A Roblox point (x, y up, z) as a Blender Vector."""
    return Vector(WP.bl(x, y, z))


def group(name):
    """A collection of the scene (made if missing); each one gets its own mask, outline and aura in compose."""
    if name not in bpy.data.collections:
        bpy.context.scene.collection.children.link(bpy.data.collections.new(name))
    return name


def aim(pos, toward, pitch):
    """A look-at point from Blender `pos`, level with it in the ground direction of Blender `toward`, tilted `pitch` degrees (down < 0)."""
    d = Vector(toward) - Vector(pos)
    d.z = 0
    d.normalize()
    return Vector(pos) + d * 50.0 + Vector((0, 0, 50.0 * math.tan(math.radians(pitch))))


def view_axes(cam):
    """The camera's level forward and right unit vectors in the Blender ground plane."""
    m = cam.matrix_world.to_3x3()
    f, r = m @ Vector((0, 0, -1)), m @ Vector((1, 0, 0))
    f.z = r.z = 0
    return f.normalized(), r.normalized()


def ground_in_view(world, cam, fx, dist, lift=0.0, shift=(0.0, 0.0)):
    """The ground point `dist` studs out along the frame column `fx` (0 left, 1 right): where to stand an alien so it lands in that
    column. `shift` is the world's Roblox (x, z) offset when two worlds share a scene (S3)."""
    f, r = view_axes(cam)
    d = (f + r * ((2 * fx - 1) * 18.0 / cam.data.lens)).normalized()
    p = cam.location + d * dist
    return at(world, p.x - shift[0], -p.y - shift[1], lift) + Vector((shift[0], -shift[1], 0))


def focus(cam, distance, fstop):
    """Gentle depth of field on a camera already placed."""
    cam.data.dof.use_dof = True
    cam.data.dof.focus_distance = distance
    cam.data.dof.aperture_fstop = fstop


def sun_from(direction, energy, colour, angle=3.0):
    """Turn the scene's sun so its light comes from `direction` (a Blender vector pointing at the sun)."""
    s = bpy.data.objects["Sun"]
    s.data.energy, s.data.color, s.data.angle = energy, colour, math.radians(angle)
    s.rotation_euler = Vector(direction).normalized().to_track_quat("Z", "Y").to_euler()
    return s


def ambient(colour, strength):
    """The sky's light on the scene (compose paints the sky the camera sees)."""
    bg = bpy.context.scene.world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*colour, 1.0)
    bg.inputs["Strength"].default_value = strength


def depth_pass(path, far):
    """The camera distance of every visible surface over `far` (clamped to 1), as a 16-bit grey PNG (sRGB-encoded by the Standard view);
    the sky stays transparent. Compose turns it into aerial haze. One material override, a few samples, no denoise."""
    sc = bpy.context.scene
    mat = bpy.data.materials.new("DepthOverride")
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    cam, div, emit, out = (nt.nodes.new("ShaderNodeCameraData"), nt.nodes.new("ShaderNodeMath"), nt.nodes.new("ShaderNodeEmission"),
                           nt.nodes.new("ShaderNodeOutputMaterial"))
    div.operation, div.use_clamp = "DIVIDE", True
    div.inputs[1].default_value = far
    nt.links.new(cam.outputs["View Distance"], div.inputs[0])
    nt.links.new(div.outputs[0], emit.inputs["Color"])
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    vl = bpy.context.view_layer
    vl.material_override = mat
    st = sc.render.image_settings
    bg = sc.world.node_tree.nodes["Background"]
    saved = (sc.cycles.samples, sc.cycles.use_denoising, st.color_depth, st.color_mode, sc.render.film_transparent,
             tuple(bg.inputs["Color"].default_value), bg.inputs["Strength"].default_value)
    sc.cycles.samples, sc.cycles.use_denoising, sc.render.film_transparent = 4, False, False
    st.color_mode, st.color_depth = "BW", "16"
    bg.inputs["Color"].default_value, bg.inputs["Strength"].default_value = (1.0, 1.0, 1.0, 1.0), 1.0   # the sky reads as far
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    sc.cycles.samples, sc.cycles.use_denoising, st.color_depth, st.color_mode, sc.render.film_transparent = saved[:5]
    bg.inputs["Color"].default_value, bg.inputs["Strength"].default_value = saved[5], saved[6]
    vl.material_override = None


def finish_scenic(shot, meta, groups, points=None):
    """The beauty pass, the depth pass, one mask per alien group and the JSON for compose. `groups` maps a collection name to its
    {"outline": px at 1080 high, "aura": hex or None}."""
    sc = bpy.context.scene
    sc.render.filepath = str(RAW / f"{shot}_raw.png")
    bpy.ops.render.render(write_still=True)
    print("rendered", shot, flush=True)
    depth_pass(RAW / f"{shot}_depth.png", meta["far"])
    for name in groups:
        if bpy.data.collections[name].all_objects:
            mask(name, RAW / f"{shot}_{name.lower()}.png")
    meta = dict(meta, scenic=True, groups=groups, size=[sc.render.resolution_x, sc.render.resolution_y], points=project(points or {}))
    (RAW / f"{shot}.json").write_text(json.dumps(meta, indent=1))


def scatter_cells(cam, hexcols, count, near, far, size, seed, strength=0.0, low=0.15, high=0.75, group_name="FX", spread=1.0, centre=0.5):
    """Small cells floating in the view between `near` and `far` studs (petals by day, fireflies at night when `strength` > 0), placed by
    frame fractions so they land where the camera looks; rows `low` to `high` of the frame (0 top)."""
    import random as _r
    rnd = _r.Random(seed)
    mats = [emissive(f"Mote{h}{strength}", h, strength) if strength > 0 else WP.flat_material(h) for h in hexcols]
    m = cam.matrix_world.to_3x3()
    fwd, right, up = m @ Vector((0, 0, -1)), m @ Vector((1, 0, 0)), m @ Vector((0, 1, 0))
    tx, ty = 18.0 / cam.data.lens, 10.125 / cam.data.lens
    for k in range(count):
        d = rnd.uniform(near, far)
        fx, fy = rnd.uniform(centre - spread / 2, centre + spread / 2), rnd.uniform(low, high)
        p = cam.location + fwd * d + right * ((2 * fx - 1) * tx * d) + up * ((1 - 2 * fy) * ty * d)
        s = size * rnd.uniform(0.7, 1.3)
        cube(p, s, mats[k % len(mats)], rot_z=rnd.uniform(0, 3), group=group_name).rotation_euler = (rnd.uniform(0, 1), rnd.uniform(0, 1), 0)


def glow_up(sid, p, tier, cam_pos, hexcol=None, light=1.0, flying=False):
    """A rare's presence at its feet (Spectacle, rarer is cooler): the light pool from Rare, the ground ring and the orbiting motes from
    Legendary, a warm point light on the face."""
    col = hexcol or TIER_HEX[tier]
    rank = list(GLOW).index(tier)
    if not flying and rank >= 4:   # below Legendary a flat pool reads as a rug in a wide shot; the light alone carries it
        pool(p, 1.0 + 0.1 * rank, col, strength=0.3 + 0.12 * rank)
    if rank >= 4:
        ring(p, 2.0, col, count=26, strength=4)
        motes(p, 1.9, col, count=8, height=2.5, avoid=cam_pos, seed=rank, strength=4)
    point_light(p + (Vector(cam_pos) - Vector(p)).normalized() * 2.2 + Vector((0, 0, 2.6)), col, (25 + 18 * rank) * light, 1.2)


def place_cast(world, cam, cast, glows=(), shift=(0.0, 0.0), side=None):
    """Stand each (species, group, frame column fx, distance, lift, yaw, face frame) in the view, clearing the props round its feet; the
    species in `glows` get their presence (glow_up). With `side` ("near" or "far", S3) a spot on the wrong side of the seam, or in the
    river, is pushed further out along its column. Prints where each lands and whether the terrain hides its head. Returns
    {species: (feet, middle, head)}."""
    sc = bpy.context.scene
    out = {}
    for sid, grp, fx, dist, lift, yaw, frame in cast:
        p = ground_in_view(world, cam, fx, dist, lift, shift)
        for _ in range(120 if side else 0):
            x, z = p.x, -p.y
            if (z < seam_z(x) - 8.0) if side == "near" else (z > seam_z(x) + 2.0):
                break
            dist += 1.0
            p = ground_in_view(world, cam, fx, dist, lift, shift)
        clear_props(p, 2.5)
        _, objs = alien(sid, p, face=cam.location, yaw=yaw, frame=frame, group=grp)
        head, mid = head_of(objs)
        if sid in glows:
            glow_up(sid, p - Vector((0, 0, lift)), glows[sid][0], cam.location, hexcol=glows[sid][1], light=glows[sid][2], flying=lift > 0)
        ray = head - cam.location
        hit, _, _, _, obj, _ = sc.ray_cast(bpy.context.view_layer.depsgraph, cam.location, ray.normalized(), distance=ray.length)
        hidden = hit and obj not in objs
        v = world_to_camera_view(sc, cam, mid)
        print(f"  cast {sid}: frame {v.x:.2f},{1 - v.y:.2f} at {(mid - cam.location).length:.0f} studs{' HIDDEN by ' + obj.name if hidden else ''}",
              flush=True)
        out[sid] = (p, mid, head)
    return out


def open_sightline(cam_pos, target, radius, names=("MoonTree",), rays=24):
    """Leave out the placed props named `names` that stand between the camera and a landmark (a disc of `radius` studs round `target`):
    the one liberty the scenic shots take with the world, so the floating island shows through the canopy. Prints what it removed."""
    import random as _r
    sc = bpy.context.scene
    rnd = _r.Random(3)
    gone = set()
    for k in range(rays):
        t = Vector(target) + Vector((rnd.uniform(-radius, radius), rnd.uniform(-radius, radius), rnd.uniform(-radius, radius) * 0.6))
        for _ in range(6):
            bpy.context.view_layer.update()
            d = t - Vector(cam_pos)
            hit, _, _, _, obj, _ = sc.ray_cast(bpy.context.view_layer.depsgraph, Vector(cam_pos), d.normalized(), distance=d.length)
            if not hit or not obj.name.startswith(names):
                break
            gone.add(obj.name)
            bpy.data.objects.remove(obj)
    print(f"  sightline: removed {len(gone)} props ({', '.join(sorted(gone))})", flush=True)
    return len(gone)


def scenic_s1():
    """S1, the meadow vista: from the highlands by the lookout over World 1 at golden hour. The plateau's river running to the waterfall into
    the pond, blossom trees, the camp with the half-built ship and its flag, the crashed ship smoking, the paths, aliens of rising rarity
    spread from the plateau rim to the meadow (Moop near the camera, Gaira glowing mid-ground), the Starhollow's violet canopy and the
    floating island with its glowing fall on the horizon. The sun is low behind the camera's right shoulder."""
    sc, world = new_scene(1920, 1080, world_id=1)
    ambient((0.55, 0.62, 0.98), 0.55)
    half_built_ship()
    cam_pos = rb(-112.0, 16.0, 100.0)
    camp_p, isle_p = at(world, 0.0, 0.0), rb(158.0, 50.0, 160.0)
    d1, d2 = camp_p - cam_pos, isle_p - cam_pos
    d1.z = d2.z = 0
    toward = cam_pos + d1.normalized() * 0.5 + d2.normalized() * 0.5
    cam = camera(cam_pos, aim(cam_pos, toward, -5.5), 22)
    f, r = view_axes(cam)
    sun_from(-f * 0.45 + r * 0.9 + Vector((0, 0, 0.30)), 4.2, (1.0, 0.70, 0.44))
    ambient((0.50, 0.58, 0.98), 0.45)
    groups = {"Hero": {"outline": 12, "aura": None}, "Legend": {"outline": 7, "aura": "F59E0B", "aura_r": 22},
              "Rare": {"outline": 6, "aura": "3B82F6", "aura_r": 16}, "Cast": {"outline": 5, "aura": None}}
    for g in groups:
        group(g)
    cast = place_cast(world, cam, [("Mossbop", "Hero", 0.30, 19.5, 0.0, -10, "open"),
                                   ("Puffpuff", "Cast", 0.42, 26.0, 0.0, 6, "open"),
                                   ("Sparkfox", "Rare", 0.52, 29.0, 0.0, 4, "glint1"),
                                   ("Buzzlebee", "Cast", 0.36, 26.0, 4.2, 8, "open"),
                                   ("Gaiabloom", "Legend", 0.63, 33.0, 0.0, -10, "cycle1"),
                                   ("Gloomoth", "Cast", 0.84, 26.0, 2.6, -18, "glint1")],
                      glows={"Gaiabloom": ("Legendary", None, 3.5), "Sparkfox": ("Rare", None, 2.0)})
    feet, mid, head = cast["Mossbop"]
    area_light(cam_pos + r * 3.0 + Vector((0, 0, -2.0)), mid, "FFE9D0", 500, 4.0)
    scatter_cells(cam, ("FFC2DC", "FFE0EC", "FF9EC4"), 40, 14.0, 70.0, 0.08, seed=7, low=0.1, high=0.75)
    focus(cam, (cam_pos - mid).length, 2.4)
    horizon = cam_pos + f * 2000.0
    finish_scenic("thumb_S1", {"sky": "golden", "far": 420.0, "haze": [0.34, 40.0], "bloom": 0.45, "title": "left",
                               "leak": ["FFD29A", 1.0, 0.0, 0.9, 0.35], "grade": "warm"},
                  groups, {"horizon": horizon, "hero": mid, "head": head, "island": isle_p, "camp": camp_p})


def scenic_s2():
    """S2, the Starhollow at dusk: from the meadow's edge where the lavender path enters the forest, the moon trees with their light drips,
    the lanterns and glowcaps along the path, fireflies, the Star Island floating over the far end with its halo and glowing fall, and
    three rares in their signature glow on the path (Raddis in its gold sun ring, Iridia fluttering, Lantrin with its lamp); the meadow on
    the right still in the low sun's warm light, the sky going from violet night over the forest to the sunset over the meadow."""
    sc, world = new_scene(1920, 1080, world_id=1, night=True)
    ambient((0.17, 0.14, 0.40), 1.0)
    cam_pos = at(world, 58.0, 56.0, 3.8)
    isle_p = rb(158.0, 50.0, 160.0)
    toward = rb(120.0, 0.0, 150.0)
    cam = camera(cam_pos, aim(cam_pos, toward, 4.0), 18)
    clear_props(cam_pos, 10.0)
    open_sightline(cam_pos, isle_p + Vector((0, 0, 4.0)), 14.0, rays=70)
    open_sightline(cam_pos, isle_p - Vector((0, 0, 22.0)), 4.0, rays=20)   # and the top of its glowing fall
    boost_glow([o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith("StarIsland")], 3.0)
    point_light(isle_p + Vector((0, 0, -6.0)), "BFE6FF", 2500, 4.0)
    f, r = view_axes(cam)
    west = Vector((-1.0, 0.0, 0.0))
    sun_from(west + Vector((0, 0, 0.12)), 2.6, (1.0, 0.56, 0.36))
    groups = {"Hero": {"outline": 12, "aura": "FFB347", "aura_r": 30}, "Iridia": {"outline": 7, "aura": "B57CFF", "aura_r": 22},
              "Lantrin": {"outline": 7, "aura": "FFC46B", "aura_r": 16}, "Cast": {"outline": 5, "aura": None}}
    for g in groups:
        group(g)
    cast = place_cast(world, cam, [("Radish", "Hero", 0.50, 15.0, 0.0, 4, "cycle2"),
                                   ("Lanternewt", "Lantrin", 0.30, 18.0, 0.0, 10, "open"),
                                   ("Gloomoth", "Iridia", 0.71, 17.0, 2.2, -14, "glint1")],
                      glows={"Radish": ("Cosmic", "FFB347", 2.0), "Gloomoth": ("Epic", "B57CFF", 1.6), "Lanternewt": ("Uncommon", "FFC46B", 1.2)})
    feet, mid, head = cast["Radish"]
    area_light(cam_pos + r * 2.0 + Vector((0, 0, 1.0)), mid, "FFE2B8", 120, 2.5)
    area_light(feet + Vector((0, 0, 4.0)) - f * 3.0, mid, "C9A8FF", 300, 3.0)
    scatter_cells(cam, ("FFF6C8", "C8F4FF", "FFC8EE", "E2CCFF"), 150, 9.0, 60.0, 0.09, seed=11, strength=9.0, low=0.15, high=0.75)
    focus(cam, (cam_pos - mid).length, 2.2)
    horizon = cam_pos + f * 2000.0
    finish_scenic("thumb_S2", {"sky": "dusk_right", "far": 300.0, "haze": [0.28, 30.0], "bloom": 0.9, "title": "left",
                               "leak": ["FFB27A", 1.0, 0.25, 0.8, 0.3], "grade": None},
                  groups, {"horizon": horizon, "hero": mid, "head": head, "island": isle_p})


# S3 joins the two generated worlds along World 1's own meadow river: World 1 keeps its rows on the camp's side of the river (the water and
# its near bank included), World 2 is shifted by S3_OFFSET and keeps its rows on the far side, so Frostbyte's snow, frozen lake, spires and
# pines begin at the river's far bank. Boxes the seam cuts are split in 2-stud strips and closed with their cut face; props stand only well
# inside their own side. Nothing is written back: both worlds are generated from their rows exactly as the game builds them.
S3_RIVER = [(-30, 84), (-10, 74), (20, 66), (50, 56), (80, 40), (110, 18), (140, -6), (170, -30), (204, -50)]   # data: world1.json river
S3_OFFSET = (-50.0, 195.0)   # World 2's (x, z) shift: its frozen lake lands just across the river, its camp and cave out of view


def seam_z(x):
    """The seam's Roblox z at x: World 1's river centre line plus its half width (the far water edge), extended past its ends."""
    pts = S3_RIVER
    if x <= pts[0][0]:
        (ax, az), (bx, bz) = pts[0], pts[1]
    elif x >= pts[-1][0]:
        (ax, az), (bx, bz) = pts[-2], pts[-1]
    else:
        k = next(i for i in range(len(pts) - 1) if pts[i][0] <= x <= pts[i + 1][0])
        (ax, az), (bx, bz) = pts[k], pts[k + 1]
    return az + (bz - az) * (x - ax) / (bx - ax) + 3.0


def build_clipped(world_id, near_side, offset=(0.0, 0.0)):
    """WP.build of one world shifted by `offset` (Roblox x, z) and clipped to one side of the seam (near_side: World 1's camp side, else the
    far side). Returns (world, the new objects)."""
    ox, oz = offset

    def keep(x, z, tol=0.0):
        return z <= seam_z(x) + tol if near_side else z >= seam_z(x) - tol

    orig = WP.bl, WP.box_faces, WP.MeshBatch.quad, WP.place_mesh

    def bl(x, y, z):
        return (x + ox, -(z + oz), y)

    def quad(self, mat, verts, uvs):
        if keep(sum(v[0] for v in verts) / 4 + ox, sum(v[2] for v in verts) / 4 + oz, 0.05):
            orig[2](self, mat, verts, uvs)

    def box(batch, x0, y0, z0, x1, y1, z1, top_mat, side_mat, bottom_mat=None, sides=0xF, top=True, pin_top=True):
        corner = (x1, z1) if near_side else (x0, z0)   # the seam's z falls with x, so this corner decides a whole box
        if keep(corner[0] + ox, corner[1] + oz):
            return orig[1](batch, x0, y0, z0, x1, y1, z1, top_mat, side_mat, bottom_mat, sides, top, pin_top)
        x = x0
        while x < x1 - 1e-6:
            xe = min(x1, x + 2.0)
            zs = seam_z((x + xe) / 2 + ox) - oz
            a, b = (z0, min(z1, zs)) if near_side else (max(z0, zs), z1)
            if b > a + 1e-6:
                more = ((4 if near_side else 8) | 3) if side_mat is not None else 0
                orig[1](batch, x, y0, a, xe, y1, b, top_mat, side_mat, bottom_mat, sides | more, top, pin_top)
            x = xe

    def place(coll, name, x, y, z, yaw, scale, hang=False):
        if not keep(x + ox, z + oz, -2.0):
            return True   # across the seam: neither the mesh nor its placeholder
        return orig[3](coll, name, x, y, z, yaw, scale, hang)

    before = set(bpy.data.objects)
    WP.bl, WP.box_faces, WP.MeshBatch.quad, WP.place_mesh = bl, box, quad, place
    try:
        world, _ = WP.build(world_id)
        world.preview_lights = [lt for lt in world.preview_lights if keep(lt[0] + ox, lt[2] + oz, -1.0)]
        WP.night_lights(world, bpy.context.scene)
    finally:
        WP.bl, WP.box_faces, WP.MeshBatch.quad, WP.place_mesh = orig
    return world, [o for o in bpy.data.objects if o not in before]


def into(objs, name):
    """Move objects into a scene collection of their own (made if missing)."""
    group(name)
    coll = bpy.data.collections[name]
    for o in objs:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        coll.objects.link(o)
    return coll


def link_light(light_obj, names):
    """Light only the collections named (Cycles light linking): World 1's sun on World 1, Frostbyte's moon on Frostbyte."""
    rc = bpy.data.collections.new(light_obj.name + "Receivers")
    for n in names:
        rc.children.link(bpy.data.collections[n])
    light_obj.light_linking.receiver_collection = rc


def scenic_s3():
    """S3, the two worlds: one panorama from the camp's side of World 1's meadow river. On the left the sunlit meadow, the camp with the
    half-built ship and the crashed ship, Moop and friends in golden light; across the river Frostbyte begins: snow, the frozen lake with
    its ice spires, snow pines, Fenrir with its moon glow and Mitt, under an aurora night sky. The river is the seam, so it reads as one
    place with two worlds in it."""
    sc, _ = new_scene(1920, 1080)
    w1, objs1 = build_clipped(1, True)
    into(objs1, "W1")
    half_built_ship()
    into(list(bpy.data.collections["FX"].objects), "W1")
    w2, objs2 = build_clipped(2, False, S3_OFFSET)
    into(objs2, "W2")
    ambient((0.42, 0.50, 0.85), 0.55)
    cam_pos = at(w1, -45.0, 80.0, 10.0)
    toward = cam_pos + Vector((math.cos(math.radians(28)), math.sin(math.radians(28)), 0))
    cam = camera(cam_pos, aim(cam_pos, toward, -6.0), 18)
    f, r = view_axes(cam)
    groups = {"Hero": {"outline": 11, "aura": None}, "Cast": {"outline": 5, "aura": None},
              "Fenrir": {"outline": 11, "aura": "8FD0FF", "aura_r": 30}, "Cast2": {"outline": 5, "aura": None}}
    for g in groups:
        group(g)
    place_cast(w1, cam, [("Mossbop", "Hero", 0.40, 19.0, 0.0, -14, "open"),
                         ("Buzzlebee", "Cast", 0.26, 24.0, 3.6, 10, "open"),
                         ("Sparkfox", "Cast", 0.50, 32.0, 0.0, -4, "glint1")],
               glows={"Sparkfox": ("Rare", None, 1.5)}, side="near")
    fen = place_cast(w2, cam, [("Fenripup", "Fenrir", 0.79, 23.0, 0.0, 16, "cycle3"),
                               ("Flufflet", "Cast2", 0.67, 38.0, 0.0, 12, "open"),
                               ("Pengoo", "Cast2", 0.91, 30.0, 0.0, 20, "open")],
                     glows={"Fenripup": ("Cosmic", "8FD0FF", 2.0)}, shift=S3_OFFSET, side="far")
    feet, mid, head = fen["Fenripup"]
    area_light(cam_pos + r * 2.0 + Vector((0, 0, 0.5)), mid, "DDE9FF", 200, 2.5)
    scatter_cells(cam, ("FFFFFF", "E6F2FF"), 70, 8.0, 60.0, 0.08, seed=5, strength=1.3, low=0.05, high=0.7, spread=0.4, centre=0.8)
    focus(cam, (cam_pos - mid).length, 2.8)
    day = sun_from(-f * 0.5 - r * 0.3 + Vector((0, 0, 0.45)), 4.0, (1.0, 0.80, 0.58))
    link_light(day, ["W1", "Hero", "Cast"])
    moon_data = bpy.data.lights.new("Moon", "SUN")
    moon_data.energy, moon_data.color, moon_data.angle = 1.6, (0.62, 0.76, 1.0), math.radians(2)
    moon = bpy.data.objects.new("Moon", moon_data)
    sc.collection.objects.link(moon)
    moon.rotation_euler = (f * 0.6 - r * 0.4 + Vector((0, 0, 0.5))).normalized().to_track_quat("Z", "Y").to_euler()
    link_light(moon, ["W2", "Fenrir", "Cast2"])
    horizon = cam_pos + f * 2000.0
    seam_far = rb(150.0, 0.0, seam_z(150.0))
    finish_scenic("thumb_S3", {"sky": "twoworld", "far": 460.0, "haze": [0.26, 40.0], "bloom": 0.6, "title": "center", "grade": None},
                  groups, {"horizon": horizon, "seam_far": seam_far, "hero": mid})


SHOTS = {"A": ("icon_A", icon_a), "B": ("icon_B", icon_b), "C": ("icon_C", icon_c), "1": ("thumb_1", thumb_1), "2": ("thumb_2", thumb_2),
         "3": ("thumb_3", thumb_3), "4": ("thumb_4", thumb_4), "5": ("thumb_5", thumb_5), "6": ("thumb_6", thumb_6),
         "S1": ("thumb_S1", scenic_s1), "S2": ("thumb_S2", scenic_s2), "S3": ("thumb_S3", scenic_s3)}


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
