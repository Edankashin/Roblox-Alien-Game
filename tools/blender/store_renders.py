#!/usr/bin/env python3
"""Store icon candidates and thumbnails from the alien and prop GLBs (overnight jobs 11 and 16, docs/STORE-PAGE.md).

Same import as preview.py, but lit and shaded: Cycles on the CPU, a warm key sun and a soft sky, a vertical
gradient seen by the camera only, a ground plane (a shadow catcher for the icons) and, from v2, a dark navy
Freestyle outline about 1% of the frame wide on every model (the top games' thick outline, Look-Plan L5b).
  icon_<Species>_v2.png      1024x1024, one alien at about 85% of the frame, centred, camera 10 degrees above eye line
  thumb_verdant_v2.png       1920x1080, five World 1 aliens before the CrashWreck, meadow trees and a rock at the
                             sides, a low slightly tilted camera, depth of field on the far trees, a sun disc
  thumb_frostbyte_v2.png     the same on pale blue snow with SnowPines and the whole IceSpire, a deeper blue sky
  thumb_legendary_v2.png     Gaiabloom alone, large and centred, a violet rim light, its gold Trim
v1 (job 11) wrote the same names without _v2; --suffix "" reproduces the names, not the old look.

The thumbnail candidates (docs/vault/01-game-design/Thumbnail-Research.md section 8) are named targets, one command each:
  --target moment    thumb_moment_v1.png    Sparkfox, a Rare-blue aura, the real capture bar, "PERFECT!"
  --target reward    thumb_reward_v1.png    Gaiabloom on a violet gradient with Reveal-style rays and confetti, "LEGENDARY"
  --target mystery   thumb_mystery_v1.png   Glim peeking from behind a rock, the "!" bubble, "WHO'S THAT?"
  --target event     thumb_event_nebula_v1.png   Cosmoo with Wispkin and Grin on a violet and teal sky, "HAUNTED NEBULA"
  --target icon      icon_v3.png            512x512, Moop's face, radial violet backdrop, a gold sparkle, no text
  --target strip     thumbs_192_strip.png   the four thumbnails at 192x108, side by side (the tile-size legibility test)
  --target thumbs    the four thumbnails, then the strip;  --target all  the four, the icon and the strip
Each target renders with Cycles to a raw PNG (a scratch folder unless --raw-dir), then tools/store_compose.py (Pillow, system
python3) adds the composited parts and calls tools/store_title.py for the outlined title. The render-only face variants (Sparkfox
wide awake with a brighter tail, Gaiabloom serene, Glim shy, Moop looking straight ahead) are built by species_bodies.build into a
temporary copy of the model folders with the recipe's face patched in memory, so assets/models and species_recipes.py never change
and a re-run always picks up the models and recipes as they are on the branch.

Usage: blender -b -P tools/blender/store_renders.py -- [--out media/store/2026-10-14] [--samples 64] [--suffix _v2]
       blender -b -P tools/blender/store_renders.py -- --target moment [--out media/store/2026-10-15] [--samples 64] [--scale 0.5]
       python3 tools/blender/store_renders.py --target moment      (with the bpy module; the same arguments)
--scale 0.5 renders at half size (outline widths scale with it) for a quick look; the default 1 is the delivered size.
"""
import argparse
import copy
import math
import pathlib
import random
import shutil
import subprocess
import sys
import tempfile

import bpy
from mathutils import Matrix, Vector

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MODELS = ROOT / "assets/models"
VARIANTS_DIR = None  # a temporary copy of some model folders with a render-only face (build_variants); looked up before MODELS
SCALE = 1.0  # --scale: the render size and the outline widths are multiplied by it (a quick look at 0.5)
DAY = ((0.45, 0.72, 0.98), (1.0, 0.95, 0.84))
WINTER = ((0.18, 0.45, 0.92), (0.86, 0.93, 1.0))
DUSK = ((0.10, 0.07, 0.30), (0.45, 0.25, 0.62))
NAVY = (0.06, 0.08, 0.22)
ICONS = ["Mossbop", "Sparkfox", "Thunderhog"]
TALL = ("Thunderhog", "Reindazzle", "Frostfang")
TARGETS = ("moment", "reward", "mystery", "event", "icon", "strip", "thumbs", "all")


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]  # blender -b -P ... -- ARGS, or plain python with bpy
    ap = argparse.ArgumentParser(description="Render store icons and thumbnails")
    ap.add_argument("--out", default=None, help="output folder (default media/store/2026-10-14, or 2026-10-15 for a --target)")
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--suffix", default="_v2")
    ap.add_argument("--target", default="v2", choices=("v2",) + TARGETS,
                    help="v2 (the default) is the original icons and thumbnails; the others are the thumbnail candidates")
    ap.add_argument("--raw-dir", default=None, help="where the raw renders go (default: a scratch folder in the system temp dir)")
    ap.add_argument("--scale", type=float, default=1.0, help="size multiplier for a quick look (0.5 is half size)")
    return ap.parse_args(argv)


def glb_path(name):
    folders = ([VARIANTS_DIR] if VARIANTS_DIR else []) + [MODELS, MODELS / "props"]
    for p in (f / name / ("%s.glb" % name) for f in folders):
        if p.exists():
            return p
    raise FileNotFoundError(name)


def bounds(objs):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    return lo, hi


def import_model(name, location=(0, 0, 0), height=None, yaw=0.0, extent=None):
    """Import one GLB into the outlined Subjects collection, parented to an empty at its feet, optionally scaled
    to a height or to a largest extent (props like the flat ShipHull pad need the extent)."""
    sc = bpy.context.scene
    layer = bpy.context.view_layer.layer_collection.children["Subjects"]
    bpy.context.view_layer.active_layer_collection = layer
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(glb_path(name)))
    objs = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    lo, hi = bounds([o for o in objs if o.type == "MESH"])
    root = bpy.data.objects.new(name, None)
    sc.collection.objects.link(root)
    root.location = ((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)
    for o in objs:
        if o.parent is None:
            o.parent = root
            o.matrix_parent_inverse = root.matrix_world.inverted()
    s = (height / (hi.z - lo.z)) if height else (extent / max(hi - lo)) if extent else 1.0
    root.scale = (s, s, s)
    root.location = location
    root.rotation_euler = (0, 0, math.radians(yaw))
    bpy.context.view_layer.update()
    return root, [o for o in objs if o.type == "MESH"]


def setup_scene(w, h, samples, sky, sun_energy=3.0, ambient=((0.85, 0.9, 1.0), 0.8), sun_color=(1.0, 0.93, 0.82),
                sun_rotation=(50, 0, -35), transparent=False, sky_top_z=None):
    """The shared scene: Cycles on the CPU, a sun, a sky gradient the camera sees and an even ambient light that does the lighting.
    sky is (top, bottom) in scene-linear. By default the gradient runs down the frame (Window coordinates); with sky_top_z it follows
    the view direction instead: the bottom colour at the horizon, the top colour from that sine of elevation up (a night scene
    whose ground meets the sky at the horizon). transparent writes an RGBA image (the sky and the ambient still light the scene)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = round(w * SCALE), round(h * SCALE)
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA" if transparent else "RGB"
    sc.render.film_transparent = transparent
    try:
        sc.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    sc.collection.children.link(bpy.data.collections.new("Subjects"))
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    nodes, links = world.node_tree.nodes, world.node_tree.links
    out = next(n for n in nodes if n.type == "OUTPUT_WORLD")
    for n in [n for n in nodes if n.type != "OUTPUT_WORLD"]:
        nodes.remove(n)
    coord, sep, ramp = nodes.new("ShaderNodeTexCoord"), nodes.new("ShaderNodeSeparateXYZ"), nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*sky[1], 1)
    ramp.color_ramp.elements[1].color = (*sky[0], 1)
    seen, lit = nodes.new("ShaderNodeBackground"), nodes.new("ShaderNodeBackground")
    lit.inputs["Color"].default_value = (*ambient[0], 1)
    lit.inputs["Strength"].default_value = ambient[1]
    path, mix = nodes.new("ShaderNodeLightPath"), nodes.new("ShaderNodeMixShader")
    if sky_top_z is None:
        links.new(coord.outputs["Window"], sep.inputs[0])
        links.new(sep.outputs["Y"], ramp.inputs[0])
    else:
        # World "Generated" coordinates are the unit view direction: Z is the sine of the elevation (0 at the horizon).
        links.new(coord.outputs["Generated"], sep.inputs[0])
        scale = nodes.new("ShaderNodeMath")
        scale.operation, scale.use_clamp = "DIVIDE", True
        scale.inputs[1].default_value = sky_top_z
        links.new(sep.outputs["Z"], scale.inputs[0])
        links.new(scale.outputs[0], ramp.inputs[0])
    links.new(ramp.outputs["Color"], seen.inputs["Color"])
    links.new(path.outputs["Is Camera Ray"], mix.inputs[0])
    links.new(lit.outputs[0], mix.inputs[1])
    links.new(seen.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], out.inputs["Surface"])
    sc.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy, sun.data.angle, sun.data.color = sun_energy, math.radians(8), sun_color
    sun.rotation_euler = tuple(math.radians(a) for a in sun_rotation)
    sc.collection.objects.link(sun)
    return sc


def outline(sc, width_px, colour=NAVY):
    """A navy Freestyle outline on the Subjects collection only (never the ground or the sun disc)."""
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    fs = sc.view_layers[0].freestyle_settings
    ls = fs.linesets[0] if fs.linesets else fs.linesets.new("Outline")
    ls.select_by_collection = True
    ls.collection = bpy.data.collections["Subjects"]
    ls.select_silhouette, ls.select_border, ls.select_crease = True, True, False
    if ls.linestyle is None:
        ls.linestyle = bpy.data.linestyles.new("Navy")
    ls.linestyle.color = colour
    ls.linestyle.thickness = width_px * SCALE


def material(name, colour, emission=0.0, roughness=0.9):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*colour, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*colour, 1)
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def ground(colour, catcher):
    bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, 0))
    plane = bpy.context.active_object
    if catcher:
        plane.is_shadow_catcher = True
    else:
        plane.data.materials.append(material("Ground", colour))


def camera(sc, target, distance, yaw, pitch, lens, roll=0.0, focus=None, fstop=None):
    d = Vector((-math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)), -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)), math.sin(math.radians(pitch))))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = lens
    sc.collection.objects.link(cam)
    target = Vector(target)
    cam.matrix_world = Matrix.Translation(target + d * distance) @ (-d).to_track_quat("-Z", "Y").to_matrix().to_4x4() @ Matrix.Rotation(math.radians(roll), 4, "Z")
    if focus:
        cam.data.dof.use_dof = True
        cam.data.dof.focus_distance = focus
        cam.data.dof.aperture_fstop = fstop
    sc.camera = cam
    return cam


def render(sc, path):
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print("rendered %s" % path, flush=True)


def lineup(species, ground_colour, sky, prop, sides, samples):
    sc = setup_scene(1920, 1080, samples, sky)
    outline(sc, 9)
    ground(ground_colour, catcher=False)
    import_model(prop, location=(0, 15, 0), extent=15.0, yaw=15)
    for name, loc, size in sides:
        import_model(name, location=loc, extent=size, yaw=loc[0] * 7)
    for i, name in enumerate(species):
        import_model(name, location=((i - 2) * 4.2, abs(i - 2) * 1.2, 0), height=2.6 + (0.6 if name in TALL else 0), yaw=(i - 2) * -12)
    return sc


# ------------------------------------------------------------------------------------------- the thumbnail candidates
# docs/vault/01-game-design/Thumbnail-Research.md section 8. Every size is a fraction of the 1920x1080 frame; a 40 mm lens on a
# 36 mm sensor frames 0.9 x distance across and 0.506 x distance tall, so a hero of height H at fraction f sits at H / (f x 0.506).
TEMP_DIRS = []  # the variant folders, removed when the run ends
OUTLINE_1B = (0.011, 0.014, 0.044)  # the game's outline navy 1B1F3B in scene-linear (the v2 NAVY is a lighter slate)
FRAME_W, FRAME_H = 0.9, 0.5063  # the frame's size over the camera distance (40 mm lens, 36 mm sensor, 16:9)
LENS = 40
# The render-only faces and glows (never written to assets/models): species id -> what to patch into a copy of its recipe.
VARIANTS = {
    "moment": {"Sparkfox": {"face": {"lid": 0.0, "eye_tilt": 0.0, "look": (0.05, -0.22), "cross": 0.12, "eye_scale": 1.3, "mouth": "o"},
                            "glow": {"Accessory": 1.5}}},
    "reward": {"Gaiabloom": {"face": {"lid": 0.0, "eye_scale": 1.5, "eye_gap": 1.25, "look": (0.0, -0.1), "mouth": "smile"}}},
    "mystery": {"Glimmo": {"face": {"lid": 0.0, "eye_scale": 1.35, "look": (0.0, -0.12), "mouth": "smile"}, "glow": {"Accessory": 1.3}}},
    "icon": {"Mossbop": {"face": {"look": (0.2, -0.15), "cross": 0.0, "eye_scale": 1.3}}},
}


def lin(hex_colour):
    """A display hex ("3B82F6") as scene-linear RGB, the values the sky and the lights take."""
    c = [int(hex_colour[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c)


def build_variants(target):
    """Build the render-only face variants for a target into a temporary copy of the model folders (VARIANTS_DIR). The recipe is
    patched in memory only, so assets/models and species_recipes.py are untouched, and the build follows whatever the recipes and
    the GLB materials are on this branch (the Surface pass included)."""
    global VARIANTS_DIR
    VARIANTS_DIR = None
    spec = VARIANTS.get(target)
    if not spec:
        return
    sys.path.insert(0, str(HERE))
    sys.path.insert(0, str(HERE.parent))
    import species_bodies as SB
    import species_recipes as SR
    VARIANTS_DIR = pathlib.Path(tempfile.mkdtemp(prefix="store_variants_"))
    TEMP_DIRS.append(VARIANTS_DIR)
    for sid, change in spec.items():
        shutil.copytree(MODELS / sid, VARIANTS_DIR / sid)
        rec = copy.deepcopy(SR.RECIPES[sid])
        rec["face"] = dict(rec["face"], **change.get("face", {}))
        rec["glow"] = dict(rec.get("glow", {}), **change.get("glow", {}))
        SR.RECIPES[sid] = rec
        tris, lo, hi, scale, slots = SB.build(sid, VARIANTS_DIR, SR.SURFACE)
        print("variant %s: %d tris, height %.2f" % (sid, tris, hi - lo), flush=True)


def to_scene(obj):
    """Move a new object out of the outlined Subjects collection (the active one after an import) into the scene's own."""
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def glow_material(name, core, edge, strength, flat=False):
    """An emission material, flat or a radial gradient from `core` (centre) to `edge` (rim) on a unit-radius disc."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    emit, out = nt.nodes.new("ShaderNodeEmission"), nt.nodes.new("ShaderNodeOutputMaterial")
    emit.inputs["Strength"].default_value = strength
    if flat:
        emit.inputs["Color"].default_value = (*core, 1)
    else:
        coord, length, ramp = nt.nodes.new("ShaderNodeTexCoord"), nt.nodes.new("ShaderNodeVectorMath"), nt.nodes.new("ShaderNodeValToRGB")
        length.operation = "LENGTH"
        ramp.color_ramp.elements[0].color = (*core, 1)
        ramp.color_ramp.elements[1].color = (*edge, 1)
        nt.links.new(coord.outputs["Object"], length.inputs[0])
        nt.links.new(length.outputs["Value"], ramp.inputs[0])
        nt.links.new(ramp.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    return mat


def soft_glow_material(name, colour, strength, alpha):
    """A see-through emission: `alpha` (0..1) in the middle of a unit-radius disc fading to nothing at the rim (a nebula blob)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    coord, length, ramp = nt.nodes.new("ShaderNodeTexCoord"), nt.nodes.new("ShaderNodeVectorMath"), nt.nodes.new("ShaderNodeValToRGB")
    length.operation = "LENGTH"
    ramp.color_ramp.interpolation = "EASE"
    ramp.color_ramp.elements[0].color = (alpha, alpha, alpha, 1)  # the middle
    ramp.color_ramp.elements[1].color = (0, 0, 0, 1)  # the rim
    emit, clear, mix, out = (nt.nodes.new("ShaderNodeEmission"), nt.nodes.new("ShaderNodeBsdfTransparent"), nt.nodes.new("ShaderNodeMixShader"),
                             nt.nodes.new("ShaderNodeOutputMaterial"))
    emit.inputs["Color"].default_value = (*colour, 1)
    emit.inputs["Strength"].default_value = strength
    nt.links.new(coord.outputs["Object"], length.inputs[0])
    nt.links.new(length.outputs["Value"], ramp.inputs[0])
    nt.links.new(ramp.outputs["Color"], mix.inputs[0])
    nt.links.new(clear.outputs[0], mix.inputs[1])
    nt.links.new(emit.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs["Surface"])
    return mat


def camera_only(obj):
    """Seen by the camera but lighting and shadowing nothing (a backdrop star or nebula blob, whose light would paint the ground)."""
    for attr in ("visible_diffuse", "visible_glossy", "visible_transmission", "visible_volume_scatter", "visible_shadow"):
        setattr(obj, attr, False)
    return obj


def glow_disc(location, radius, mat):
    """A flat disc facing the camera (-Y), out of the outlined collection."""
    bpy.ops.mesh.primitive_circle_add(vertices=64, radius=1.0, fill_type="NGON", location=location, rotation=(math.radians(90), 0, 0))
    obj = to_scene(bpy.context.active_object)
    obj.scale = (radius, radius, radius)
    obj.data.materials.append(mat)
    return obj


def glow_ring(location, radius, minor, mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=64, minor_segments=8, major_radius=radius, minor_radius=minor, location=location,
                                     rotation=(math.radians(90), 0, 0))
    obj = to_scene(bpy.context.active_object)
    obj.data.materials.append(mat)
    return obj


def glow_blob(location, size, mat, shape="sphere"):
    if shape == "sphere":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=size, location=location)
    else:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=size, location=location)
    obj = to_scene(bpy.context.active_object)
    obj.data.materials.append(mat)
    return obj


def aim(light, location, target):
    light.location = location
    light.rotation_euler = (Vector(target) - Vector(location)).to_track_quat("-Z", "Y").to_euler()


def area_light(sc, name, watts, size, colour, location, target):
    obj = bpy.data.objects.new(name, bpy.data.lights.new(name, "AREA"))
    obj.data.energy, obj.data.size, obj.data.color = watts, size, colour
    aim(obj, location, target)
    sc.collection.objects.link(obj)
    return obj


def point_light(sc, name, watts, radius, colour, location):
    obj = bpy.data.objects.new(name, bpy.data.lights.new(name, "POINT"))
    obj.data.energy, obj.data.shadow_soft_size, obj.data.color = watts, radius, colour
    obj.location = location
    sc.collection.objects.link(obj)
    return obj


def frame_point(cam, fx, fy, depth):
    """The world point at frame fractions (fx from the left, fy from the top), `depth` units in front of the camera."""
    m = cam.matrix_world
    right, up, fwd = m.to_3x3() @ Vector((1, 0, 0)), m.to_3x3() @ Vector((0, 1, 0)), m.to_3x3() @ Vector((0, 0, -1))
    return m.translation + fwd * depth + right * ((fx - 0.5) * FRAME_W * depth) + up * ((0.5 - fy) * FRAME_H * depth)


def project(sc, cam, point):
    """Frame fractions (fx from the left, fy from the top) of a world point."""
    from bpy_extras.object_utils import world_to_camera_view
    v = world_to_camera_view(sc, cam, Vector(point))
    return [round(v.x, 4), round(1.0 - v.y, 4)]


def subject_box(sc, cam, meshes, slots=None):
    """The subject's frame box (left, top, right, bottom as fractions) from its projected vertices; `slots` limits it to the polygons
    of those material slots (a ground ring that dips below the feet is left out of the framing)."""
    from bpy_extras.object_utils import world_to_camera_view
    if slots:
        pts = [p for slot in slots for p in slot_points(meshes, slot)]
    else:
        pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    views = [world_to_camera_view(sc, cam, p) for p in pts]
    return min(v.x for v in views), min(1.0 - v.y for v in views), max(v.x for v in views), max(1.0 - v.y for v in views)


def fit_camera(sc, meshes, fraction, centre_y, centre_x=None, yaw=0.0, pitch=4.0, lens=LENS, passes=5, slots=None, frame=(FRAME_W, FRAME_H),
               by_max=False):
    """Place the camera so the subject's projected height (or, with by_max, its larger side) is `fraction` of the frame, its box centred
    on `centre_y` (and on `centre_x` when given) from the top. The research's distance = H / (f x 0.506) is the first guess; a few passes
    correct the perspective and the pitch so the numbers are measured, not assumed. `frame` is the frame's (width, height) over the
    camera distance (0.9 x 0.506 for the 16:9 40 mm shots, 0.72 x 0.72 for the 50 mm square icon)."""
    lo, hi = bounds(meshes)
    centre = (lo + hi) * 0.5
    distance = (hi.z - lo.z) / (fraction * frame[1])
    target = Vector(centre)
    for _ in range(passes):
        cam = camera(sc, target, distance, yaw, pitch, lens)
        bpy.context.view_layer.update()
        x0, y0, x1, y1 = subject_box(sc, cam, meshes, slots)
        got = max(y1 - y0, x1 - x0) if by_max else y1 - y0
        distance *= got / fraction
        # a higher target puts the hero lower in the frame, so a subject centred too low (a big y) needs the target lowered
        target.z -= ((y0 + y1) / 2 - centre_y) * frame[1] * distance
        if centre_x is not None:
            right = cam.matrix_world.to_3x3() @ Vector((1, 0, 0))
            target += right * ((((x0 + x1) / 2) - centre_x) * frame[0] * distance)
        bpy.data.objects.remove(cam)
    cam = camera(sc, target, distance, yaw, pitch, lens)
    bpy.context.view_layer.update()
    return cam


def slot_points(meshes, slot):
    """The world-space vertices of every polygon that uses the material slot named `slot`."""
    pts = []
    for o in meshes:
        names = [(m.material.name.split(".")[0] if m.material else "") for m in o.material_slots]
        mw = o.matrix_world
        for poly in o.data.polygons:
            if names[poly.material_index] == slot:
                pts.extend(mw @ o.data.vertices[i].co for i in poly.vertices)
    return pts


def mean(points):
    return sum(points, Vector()) / len(points)


def finish(sc, args, name, meta=None):
    """Render the raw PNG into the raw folder with a sidecar JSON of frame positions the compositor reads, then run the compositor."""
    import json
    raw_dir = pathlib.Path(args.raw_dir) if args.raw_dir else pathlib.Path(tempfile.gettempdir()) / "store_raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    raw = raw_dir / ("%s_raw.png" % name)
    render(sc, raw)
    (raw_dir / ("%s_raw.json" % name)).write_text(json.dumps(meta or {}, indent=1))
    if SCALE == 1.0:
        final = pathlib.Path(args.out) / FINALS[name]
        final.parent.mkdir(parents=True, exist_ok=True)
    else:
        final = raw_dir / ("preview_" + FINALS[name])  # a quick look never overwrites a delivered file
    cmd = ["python3", "-I", str(ROOT / "tools/store_compose.py"), name, str(raw), str(final)]
    print("compose: " + " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True)


FINALS = {"moment": "thumb_moment_v1.png", "reward": "thumb_reward_v1.png", "mystery": "thumb_mystery_v1.png",
          "event": "thumb_event_nebula_v1.png", "icon": "icon_v3.png"}


def moment(args):
    """The Moment: Sparkfox (Rare) wide awake with a brighter glowing tail in a Rare-blue aura on the night-dim meadow. The capture
    bar, the tier label and "PERFECT!" are composited afterwards by tools/store_compose.py."""
    build_variants("moment")
    sc = setup_scene(1920, 1080, args.samples, (lin("101B5C"), lin("2F66D6")), sun_energy=2.6, ambient=((0.78, 0.86, 1.0), 0.6),
                     sun_color=(1.0, 0.97, 0.9), sky_top_z=0.2)
    outline(sc, 14, OUTLINE_1B)
    ground(lin("1E4F2A"), catcher=False)
    root, meshes = import_model("Sparkfox", height=4.0, yaw=-8)
    lo, hi = bounds(meshes)
    centre = (lo + hi) * 0.5
    rare, core = lin("3B82F6"), lin("BFE0FF")
    behind = hi.y + 1.2
    glow_disc((centre.x, behind, centre.z), 2.6, glow_material("AuraCore", core, rare, 1.3))
    glow_ring((centre.x, behind - 0.05, centre.z), 2.9, 0.07, glow_material("AuraRing", rare, rare, 2.2, flat=True))
    area_light(sc, "RareRim", 4000, 5, rare, (centre.x + 6, behind + 4, centre.z + 3), (centre.x, centre.y, centre.z))
    cam = fit_camera(sc, meshes, 0.60, 0.51, pitch=1.5)
    finish(sc, args, "moment", {"face": project(sc, cam, mean(slot_points(meshes, "EyeWhite"))), "box": subject_box(sc, cam, meshes),
                                "glow": project(sc, cam, mean([p for p in slot_points(meshes, "Accessory") if p.z > hi.z - 0.9]))})


def reward(args):
    """The Reward: Gaiabloom (Legendary) lit gold and purple from behind, rendered with a transparent background; the violet gradient,
    the Reveal-style rays, the confetti and "LEGENDARY" are composited behind and over it by tools/store_compose.py."""
    build_variants("reward")
    sc = setup_scene(1920, 1080, args.samples, (lin("2A1170"), lin("9A5BE0")), sun_energy=3.0, ambient=((0.92, 0.86, 1.0), 0.9),
                     transparent=True)
    outline(sc, 14, OUTLINE_1B)
    ground(None, catcher=True)
    root, meshes = import_model("Gaiabloom", height=6.0, yaw=6)
    lo, hi = bounds(meshes)
    centre = (lo + hi) * 0.5
    area_light(sc, "GoldRim", 5000, 5, lin("F59E0B"), (-7, hi.y + 6, 7), centre)
    area_light(sc, "CodexRim", 4000, 5, lin("A855F7"), (7, hi.y + 6, 6), centre)
    cam = fit_camera(sc, meshes, 0.72, 0.58, pitch=6, slots=("Body", "BodyDark", "Accessory"))
    head = mean(slot_points(meshes, "EyeWhite"))
    finish(sc, args, "reward", {"head": project(sc, cam, head), "box": subject_box(sc, cam, meshes)})


def mystery(args):
    """The Mystery: Glim (Common) peeking over a rock, the lamp behind it the key light, on a dim night meadow. The "!" bubble and
    "WHO'S THAT?" are composited afterwards."""
    build_variants("mystery")
    sc = setup_scene(1920, 1080, args.samples, (lin("0F0B3A"), lin("4A2A9A")), sun_energy=0.3, ambient=((0.45, 0.5, 0.95), 0.3),
                     sun_color=lin("8FB0FF"), sky_top_z=0.25)
    outline(sc, 14, OUTLINE_1B)
    ground(lin("2B2160"), catcher=False)
    rock, r_meshes = import_model("MeadowRock", location=(0.6, 2.2, 0), extent=4.0)
    rock.scale = (1.25, 1.1, 1.5 / 2.8)  # about 5 units wide, its top edge 1.5 units high (0.55 of Glim's 2.7)
    for o in r_meshes:  # a dark foreground: the rock is a silhouette the pale face rises out of
        for slot in o.material_slots:
            bsdf = next(n for n in slot.material.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
            bsdf.inputs["Base Color"].default_value = (*lin("3A3F86"), 1)
    glim, meshes = import_model("Glimmo", location=(0.5, 3.4, 0), height=2.7, yaw=0)
    bpy.context.view_layer.update()
    lo, hi = bounds(meshes)
    eyes = mean(slot_points(meshes, "EyeWhite"))
    lamp = mean([p for p in slot_points(meshes, "Accessory") if p.z < lo.z + 0.8 * (hi.z - lo.z)])
    wreck, _ = import_model("CrashWreck", location=(-6.5, 19, 0), extent=9.0, yaw=-20)
    point_light(sc, "Lamp", 600, 0.6, lin("FFD36B"), lamp)
    point_light(sc, "LampSpill", 450, 0.8, lin("FFD36B"), (eyes.x + 2.2, eyes.y - 2.4, eyes.z + 0.3))  # the lamp's glow reaching round to the face
    area_light(sc, "TealRim", 1500, 4, lin("5CE1E6"), (-7, hi.y + 4, 4), (eyes.x, eyes.y, eyes.z))
    area_light(sc, "MoonFill", 500, 6, lin("9DB8FF"), (-4, -6, 5), (eyes.x, eyes.y, eyes.z))
    width = max(hi.x - lo.x, 0.0)
    distance = width / (0.45 * FRAME_W)
    cam = camera(sc, eyes, distance, 0, 3, LENS, focus=distance, fstop=1.8)
    bpy.context.view_layer.update()
    # the wreck's one cyan window: a small glowing disc on the hull where a ray from the camera through the frame meets it
    ray = frame_point(cam, 0.13, 0.5, 20.0) - cam.matrix_world.translation
    hit, where, normal, _, _, _ = sc.ray_cast(bpy.context.view_layer.depsgraph, cam.matrix_world.translation, ray.normalized())
    if hit:
        win = glow_blob(where + normal * 0.05, 0.22, glow_material("WreckWindow", lin("5CE1E6"), lin("5CE1E6"), 3.0, flat=True), shape="ico")
        win.scale = (1.0, 0.4, 1.0)
    stars = random.Random(7)
    star_mat = glow_material("Star", lin("FFF4DC"), lin("FFF4DC"), 9.0, flat=True)
    for _ in range(25):
        camera_only(glow_blob(frame_point(cam, stars.uniform(0.04, 0.96), stars.uniform(0.03, 0.33), 70.0), stars.uniform(0.12, 0.26), star_mat, shape="ico"))
    finish(sc, args, "mystery", {"eyes": project(sc, cam, eyes), "head_width": round(width / (distance * FRAME_W), 3)})


def event(args):
    """The Haunted Nebula event thumbnail: Cosmoo (Nebulyn) large with its gold star tail, Wispkin and Grin beside it, on a violet
    and teal sky with soft nebula blobs. "HAUNTED NEBULA" is composited afterwards."""
    build_variants("event")
    sc = setup_scene(1920, 1080, args.samples, (lin("2A1170"), lin("12A3A8")), sun_energy=1.5, ambient=((0.75, 0.78, 1.0), 0.45),
                     sun_color=(1.0, 0.95, 0.9), sky_top_z=0.17)
    outline(sc, 14, OUTLINE_1B)
    ground(lin("262487"), catcher=False)
    cosmoo, c_meshes = import_model("Nebulyn", location=(0.0, 0, 0), height=4.6, yaw=-22)
    wisp, _ = import_model("Wisplet", location=(-3.7, 1.4, 0), height=1.9, yaw=-10)
    grin, g_meshes = import_model("Spookum", location=(4.0, 1.6, 0), height=2.2, yaw=12)
    lo, hi = bounds(c_meshes)
    centre = (lo + hi) * 0.5
    for radius, minor in ((4.8, 0.05), (3.4, 0.035)):  # a faint violet summoning ring on the ground under them
        bpy.ops.mesh.primitive_torus_add(major_segments=64, minor_segments=6, major_radius=radius, minor_radius=minor, location=(0, 0.6, 0.02))
        ring = to_scene(bpy.context.active_object)
        ring.data.materials.append(glow_material("SummonRing", lin("A855F7"), lin("A855F7"), 2.0, flat=True))
    area_light(sc, "GoldRim", 2800, 5, lin("F59E0B"), (-7, hi.y + 6, 7), centre)
    area_light(sc, "TealRim", 2500, 5, lin("5CE1E6"), (8, hi.y + 6, 5), centre)
    cam = fit_camera(sc, c_meshes, 0.72, 0.555, centre_x=0.5, pitch=5)
    glows = random.Random(5)
    # soft blobs high in the sky (their lower edge stays above the horizon, where the ground would cut them in a hard line)
    for fx, fy, size, colour, strength, alpha in ((0.14, 0.14, 9.0, "C026D3", 1.0, 0.6), (0.88, 0.12, 10.0, "5CE1E6", 1.0, 0.55),
                                                   (0.5, 0.16, 11.0, "A855F7", 1.0, 0.45)):
        d = camera_only(glow_disc(frame_point(cam, fx, fy, 55.0), size, soft_glow_material("Nebula", lin(colour), strength, alpha)))
        d.rotation_euler = cam.rotation_euler
    star_mat = glow_material("Star", lin("FFF4DC"), lin("FFF4DC"), 5.0, flat=True)
    for _ in range(40):
        camera_only(glow_blob(frame_point(cam, glows.uniform(0.03, 0.97), glows.uniform(0.04, 0.58), 60.0), glows.uniform(0.1, 0.26), star_mat, shape="ico"))
    gold = [p for p in slot_points(c_meshes, "Accessory") + slot_points(c_meshes, "Trim")]
    finish(sc, args, "event", {"face": project(sc, cam, mean(slot_points(c_meshes, "EyeWhite"))), "box": subject_box(sc, cam, c_meshes),
                               "gold": project(sc, cam, mean(gold)), "tip": project(sc, cam, mean(slot_points(c_meshes, "Trim")))})


def icon(args):
    """Icon v3: Moop (Mossbop) filling 82% of a 1024 frame on a transparent background, the outline 3.2% of the width (33 px); the radial
    violet backdrop and the gold sparkle are composited and the result is saved at 512 by tools/store_compose.py."""
    build_variants("icon")
    sc = setup_scene(1024, 1024, args.samples, DAY, sun_energy=3.0, transparent=True)
    outline(sc, 33, OUTLINE_1B)
    ground(None, catcher=True)
    root, meshes = import_model("Mossbop", yaw=-6)
    # a 50 mm lens frames 0.72 x distance across; centre the whole alien (sprout and feet included) a little below the middle
    cam = fit_camera(sc, meshes, 0.82, 0.52, centre_x=0.5, pitch=6, lens=50, frame=(0.72, 0.72), by_max=True)
    finish(sc, args, "icon", {"face": project(sc, cam, mean(slot_points(meshes, "EyeWhite"))), "box": subject_box(sc, cam, meshes)})


RUNNERS = {"moment": moment, "reward": reward, "mystery": mystery, "event": event, "icon": icon}


def run_target(args):
    todo = {"thumbs": ["moment", "reward", "mystery", "event", "strip"], "all": ["moment", "reward", "mystery", "event", "icon", "strip"]}
    try:
        for name in todo.get(args.target, [args.target]):
            if name == "strip":
                finals = [str(pathlib.Path(args.out) / FINALS[n]) for n in ("moment", "reward", "mystery", "event")]
                cmd = ["python3", "-I", str(ROOT / "tools/store_compose.py"), "strip", *finals, str(pathlib.Path(args.out) / "thumbs_192_strip.png")]
                print("compose: " + " ".join(cmd), flush=True)
                subprocess.run(cmd, check=True)
            else:
                RUNNERS[name](args)
    finally:
        for d in TEMP_DIRS:
            shutil.rmtree(d, ignore_errors=True)


def main():
    global SCALE
    args = parse_args()
    SCALE = args.scale
    args.out = args.out or str(ROOT / ("media/store/2026-10-14" if args.target == "v2" else "media/store/2026-10-15"))
    if args.target != "v2":
        run_target(args)
        return
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    sfx = args.suffix
    for name in ICONS:
        sc = setup_scene(1024, 1024, args.samples, DAY)
        outline(sc, 10)
        ground(None, catcher=True)
        _, meshes = import_model(name, yaw=-20)
        lo, hi = bounds(meshes)
        # a 50 mm lens frames about 0.72 x distance across: the subject at 85% of the frame
        camera(sc, (lo + hi) * 0.5, max(hi - lo) / 0.85 / 0.72, 25, 10, 50)
        render(sc, out / ("icon_%s%s.png" % (name, sfx)))

    sides = [("MeadowTree", (-15, 22, 0), 11.0), ("MeadowTreeB", (16, 24, 0), 12.0), ("MeadowRock", (10.5, 5, 0), 3.0)]
    sc = lineup(["Mossbop", "Puffpuff", "Buzzlebee", "Sparkfox", "Thunderhog"], (0.30, 0.62, 0.22), DAY, "CrashWreck", sides, args.samples)
    bpy.ops.mesh.primitive_circle_add(vertices=48, radius=4.5, fill_type="NGON", location=(-34, 120, 21), rotation=(math.radians(90), 0, 0))
    bpy.context.active_object.data.materials.append(material("SunDisc", (1.0, 0.95, 0.75), emission=6.0))
    camera(sc, (0, 4, 2.4), 20, 0, 6, 32, roll=-3, focus=20.0, fstop=1.4)
    render(sc, out / ("thumb_verdant%s.png" % sfx))

    sides = [("SnowPine", (-14, 20, 0), 12.0), ("SnowPine", (15, 23, 0), 13.0), ("IceRock", (10.5, 5, 0), 3.0)]
    sc = lineup(["Flufflet", "Snowbun", "Pengoo", "Reindazzle", "Frostfang"], (0.72, 0.84, 0.98), WINTER, "IceSpire", sides, args.samples)
    camera(sc, (0, 5, 4.0), 22, 0, 8, 32, roll=2, focus=22.0, fstop=2.0)
    render(sc, out / ("thumb_frostbyte%s.png" % sfx))

    sc = setup_scene(1920, 1080, args.samples, DUSK, sun_energy=1.5)
    outline(sc, 14)
    ground(None, catcher=True)
    _, meshes = import_model("Gaiabloom", height=6.0, yaw=-15)
    rim = bpy.data.objects.new("Rim", bpy.data.lights.new("Rim", "AREA"))
    rim.data.energy, rim.data.size, rim.data.color = 4000, 5, (0.62, 0.3, 1.0)
    rim.location = (-5, 7, 7)
    rim.rotation_euler = (-Vector((-5, 7, 4))).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(rim)
    lo, hi = bounds(meshes)
    camera(sc, (lo + hi) * 0.5 + Vector((0, 0, -0.3)), 16.5, 15, 8, 40)
    render(sc, out / ("thumb_legendary%s.png" % sfx))


if __name__ == "__main__":
    main()
