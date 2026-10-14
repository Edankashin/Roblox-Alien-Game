#!/usr/bin/env python3
"""Thumbnail renders of the blockout aliens for silhouette review without opening Blender.

For every assets/models/<SpeciesId>/<SpeciesId>.glb this imports the mesh, frames it with an orthographic
camera from the front-left (30 degrees off the front, slightly above) and renders two 256x256 PNGs with the
Workbench engine, flat shading, grey background:
  <SpeciesId>.png        material colours (what Studio will show)
  <SpeciesId>_grey.png   Workbench colour type SINGLE: a solid silhouette, the design's greyscale check
If Workbench cannot start headless (no GPU/display) the script falls back to Cycles on the CPU with
emission-only materials, which gives the same flat look. --engine forces one.

--lit is the Surface pass review (docs/vault/06-art-pipelines/Surface-Pass.md): one lit Cycles render per species, the pre-surface
body on the left (flat colours) and the surface build on the right (--models), so the gradient, the glossy eyes, the Neon glow and any
baked texture sets from assets/textures show side by side. See lit_main below.

Usage: python3 tools/blender/preview.py [--models assets/models] [--species Mossbop,Radish] [--engine auto|workbench|cycles]
       blender -b -P tools/blender/preview.py -- --species Mossbop
       python3 tools/blender/preview.py --lit --models <surface build> --compare <plain build> --species Mossbop --out <folder>
"""
import argparse
import json
import math
import pathlib
import re
import subprocess
import sys

import bpy
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SIZE = 256
BACKGROUND = (0.55, 0.55, 0.55)
SILHOUETTE = (0.16, 0.16, 0.16)


def parse_args():
    argv = sys.argv[1:]
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser(description="Render blockout thumbnails")
    ap.add_argument("--models", default=str(ROOT / "assets/models"))
    ap.add_argument("--species", default="")
    ap.add_argument("--engine", default="auto", choices=("auto", "workbench", "cycles"))
    ap.add_argument("--lit", action="store_true", help="the Surface pass review render (see lit_main): before | after, lit, Cycles on the CPU")
    ap.add_argument("--compare", default="", help="--lit: a models folder built with --no-surface, drawn on the left as the before")
    ap.add_argument("--textures", default=str(ROOT / "assets/textures"), help="--lit: the baked texture sets (bake_textures.py)")
    ap.add_argument("--out", default="", help="--lit: where <Id>_surface.jpg goes (default: next to each GLB)")
    ap.add_argument("--size", type=int, default=512, help="--lit: pixels per side of one model's half of the image")
    ap.add_argument("--samples", type=int, default=64, help="--lit: Cycles samples")
    return ap.parse_args(argv)


def workbench_available():
    """Probe Workbench in a child process: a missing GPU context can crash the interpreter, not just raise."""
    probe = (
        "import bpy\n"
        "bpy.ops.wm.read_factory_settings(use_empty=True)\n"
        "s = bpy.context.scene\n"
        "s.render.engine = 'BLENDER_WORKBENCH'\n"
        "s.render.resolution_x = s.render.resolution_y = 16\n"
        "cam = bpy.data.objects.new('Cam', bpy.data.cameras.new('Cam')); s.collection.objects.link(cam); s.camera = cam\n"
        "s.render.filepath = '/dev/null'\n"
        "bpy.ops.render.render(write_still=False)\n"
        "print('WORKBENCH_OK')\n"
    )
    try:
        r = subprocess.run([sys.executable, "-c", probe], capture_output=True, text=True, timeout=120)
    except Exception as exc:  # noqa: BLE001
        print("workbench probe failed to run: %s" % exc)
        return False
    ok = r.returncode == 0 and "WORKBENCH_OK" in r.stdout
    if not ok:
        tail = (r.stderr or r.stdout).strip().splitlines()[-3:]
        print("workbench unavailable headless (%s)" % " | ".join(tail))
    return ok


def scene_bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for corner in o.bound_box:
            p = o.matrix_world @ Vector(corner)
            lo = Vector((min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z)))
            hi = Vector((max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z)))
    return lo, hi


def setup_camera(scene, objs):
    lo, hi = scene_bounds(objs)
    centre = (lo + hi) * 0.5
    extent = max(hi - lo)
    # front-left, 30 degrees off the front (-Y), 18 degrees above the horizon
    yaw = math.radians(30.0)
    pitch = math.radians(18.0)
    direction = Vector((-math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * 1.25
    cam_data.clip_end = extent * 20.0
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = centre + direction * extent * 4.0
    cam.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    scene.camera = cam


def setup_common(scene):
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.film_transparent = False
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    world = bpy.data.worlds.new("World")
    world.use_nodes = False
    world.color = BACKGROUND
    scene.world = world


def render_workbench(scene, path_colour, path_grey):
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "FLAT"
    shading.color_type = "MATERIAL"
    shading.show_cavity = False
    shading.show_shadows = False
    shading.show_object_outline = True
    scene.display.render_aa = "8"
    scene.render.filepath = str(path_colour)
    bpy.ops.render.render(write_still=True)
    shading.color_type = "SINGLE"
    shading.single_color = SILHOUETTE
    shading.show_object_outline = False
    scene.render.filepath = str(path_grey)
    bpy.ops.render.render(write_still=True)


def flatten_materials(single=None):
    """Turn every imported material into emission-only so Cycles gives flat colours with no lighting."""
    for mat in bpy.data.materials:
        if not mat.use_nodes or mat.node_tree is None:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        colour = single if single is not None else tuple(bsdf.inputs["Base Color"].default_value)[:3]
        bsdf.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
        bsdf.inputs["Emission Color"].default_value = (colour[0], colour[1], colour[2], 1.0)
        bsdf.inputs["Emission Strength"].default_value = 1.0
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.0
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = 0.0


def render_cycles(scene, path_colour, path_grey):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    scene.cycles.max_bounces = 1
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND"), None)
    if bg is not None:
        bg.inputs["Color"].default_value = (BACKGROUND[0], BACKGROUND[1], BACKGROUND[2], 1.0)
        bg.inputs["Strength"].default_value = 1.0
    flatten_materials()
    scene.render.filepath = str(path_colour)
    bpy.ops.render.render(write_still=True)
    flatten_materials(single=SILHOUETTE)
    scene.render.filepath = str(path_grey)
    bpy.ops.render.render(write_still=True)


# ------------------------------------------------------------------------------------------------ --lit
SUN_DIRECTION = (-0.55, -0.45, 0.7)  # where the sun sits relative to the model: front-left and high, like the camera
GLOSS_ROUGHNESS = 0.12  # a glossy slot (eyes, highlights): Roblox's SmoothPlastic with a Reflectance, drawn as a tight highlight
ROUGH_MATERIAL = 0.9  # every other Roblox material, drawn matte: Blender cannot show Grass or Fabric, only the maps and the colour
NEON_STRENGTH = 2.0


def principled_of(mat):
    return next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)


def surface_variant(obj, entries, textures_root):
    """Dress one imported model like the surface build: material, glossy and texture fields of its materials.json. The glTF importer
    has already multiplied the exported vertex colour into each Base Color (as Roblox does with the part's Color)."""
    by_name = {e["name"]: e for e in entries}
    notes = []
    for slot in obj.material_slots:
        mat = slot.material
        if mat is None or not mat.use_nodes:
            continue
        entry = by_name.get(re.sub(r"\.\d{3}$", "", mat.name), {})
        bsdf = principled_of(mat)
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        bsdf.inputs["Roughness"].default_value = ROUGH_MATERIAL
        material = entry.get("material", "")
        if entry.get("glossy"):
            bsdf.inputs["Roughness"].default_value = GLOSS_ROUGHNESS
            if "Specular IOR Level" in bsdf.inputs:
                bsdf.inputs["Specular IOR Level"].default_value = 1.0
        if material == "Neon" or entry.get("emission", 0) > 0:
            bsdf.inputs["Emission Color"].default_value = bsdf.inputs["Base Color"].default_value
            bsdf.inputs["Emission Strength"].default_value = NEON_STRENGTH
        if material in ("Metal", "Foil"):
            bsdf.inputs["Metallic"].default_value = 0.85
            bsdf.inputs["Roughness"].default_value = 0.35
        if material == "Glass":
            bsdf.inputs["Roughness"].default_value = 0.05
            if "Transmission Weight" in bsdf.inputs:
                bsdf.inputs["Transmission Weight"].default_value = 0.5
        key = entry.get("texture")
        folder = pathlib.Path(textures_root) / key if key else None
        if key and (folder / (key + "_color.png")).exists():
            def image(kind, colour):
                node = nodes.new("ShaderNodeTexImage")
                node.image = bpy.data.images.load(str(folder / ("%s_%s.png" % (key, kind))), check_existing=True)
                node.image.colorspace_settings.name = "sRGB" if colour else "Non-Color"
                node.extension = "REPEAT"
                return node
            colour_node, rough_node, normal_node = image("color", True), image("roughness", False), image("normal", False)
            # tint the (near white) colour map with the slot's colour, then the vertex gradient the importer already wired in
            tint = nodes.new("ShaderNodeMix")  # RGBA mix: inputs 0 = Factor, 6 = A, 7 = B; output 2 = Result
            tint.data_type = "RGBA"
            tint.blend_type = "MULTIPLY"
            tint.inputs[0].default_value = 1.0
            links.new(colour_node.outputs["Color"], tint.inputs[6])
            tint.inputs[7].default_value = bsdf.inputs["Base Color"].default_value
            into = next((l for l in links if l.to_node == bsdf and l.to_socket.name == "Base Color"), None)
            if into is not None and into.from_node.type == "MIX":
                links.new(tint.outputs[2], into.from_node.inputs[6])  # the importer's vertex-colour multiply takes the tinted map
            else:
                links.new(tint.outputs[2], bsdf.inputs["Base Color"])
            notes.append(entry["name"] + ":" + key)
            links.new(rough_node.outputs["Color"], bsdf.inputs["Roughness"])
            normal = nodes.new("ShaderNodeNormalMap")
            links.new(normal_node.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
    return notes


def lit_scene(size):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.max_bounces = 4
    try:
        scene.cycles.use_denoising = True
    except Exception:  # noqa: BLE001
        pass
    scene.render.resolution_x, scene.render.resolution_y = size * 2, size
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "JPEG"
    scene.render.image_settings.quality = 88
    scene.render.image_settings.color_mode = "RGB"
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (1.0, 0.96, 0.86, 1.0)
    bg.inputs["Strength"].default_value = 0.75
    scene.world = world
    return scene


def lit_main(args, models):
    out_root = pathlib.Path(args.out) if args.out else None
    plain_root = pathlib.Path(args.compare) if args.compare else None
    wanted = [s.strip() for s in args.species.split(",") if s.strip()]
    if not wanted:
        print("--lit needs --species")
        sys.exit(2)
    failures = []
    for sid in wanted:
        try:
            scene = lit_scene(args.size)
            scene.cycles.samples = args.samples
            entries = json.loads((models / sid / "materials.json").read_text())
            before = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=str(models / sid / ("%s.glb" % sid)))
            after_objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
            notes = []
            for obj in after_objs:
                notes += surface_variant(obj, entries, args.textures)
            before_objs = []
            if plain_root is not None:
                before = set(bpy.data.objects)
                bpy.ops.import_scene.gltf(filepath=str(plain_root / sid / ("%s.glb" % sid)))
                before_objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
            bpy.context.view_layer.update()
            lo, hi = scene_bounds(after_objs)
            extent = max(hi - lo)
            width = max(hi.x - lo.x, hi.y - lo.y)
            gap = width * 1.15
            yaw, pitch = math.radians(30.0), math.radians(18.0)
            direction = Vector((-math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
            right = (-direction).cross(Vector((0.0, 0.0, 1.0))).normalized()
            for obj in before_objs:
                obj.location = obj.location - right * gap * 0.5
            for obj in after_objs:
                obj.location = obj.location + right * gap * (0.5 if before_objs else 0.0)
            everything = before_objs + after_objs
            lo, hi = scene_bounds(everything)
            centre = (lo + hi) * 0.5
            cam_data = bpy.data.cameras.new("Cam")
            cam_data.type = "ORTHO"
            cam_data.ortho_scale = max(extent * 1.3 * (2.0 if before_objs else 1.0), (hi.x - lo.x) * 1.15)
            cam_data.clip_end = extent * 40.0
            cam = bpy.data.objects.new("Cam", cam_data)
            scene.collection.objects.link(cam)
            cam.location = centre + direction * extent * 8.0
            cam.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
            scene.camera = cam
            if not before_objs:
                scene.render.resolution_x = args.size
            # a floor to catch the shadows, and a sun plus a soft fill
            bpy.ops.mesh.primitive_plane_add(size=extent * 20.0, location=(centre.x, centre.y, 0.0))
            floor = bpy.context.active_object
            floor_mat = bpy.data.materials.new("Floor")
            floor_mat.use_nodes = True
            principled_of(floor_mat).inputs["Base Color"].default_value = (0.93, 0.9, 0.82, 1.0)
            principled_of(floor_mat).inputs["Roughness"].default_value = 1.0
            floor.data.materials.append(floor_mat)
            sun = bpy.data.lights.new("Sun", "SUN")
            sun.energy = 3.2
            sun.angle = math.radians(14.0)
            sun.color = (1.0, 0.95, 0.88)
            sun_obj = bpy.data.objects.new("Sun", sun)
            scene.collection.objects.link(sun_obj)
            sun_obj.rotation_euler = Vector(SUN_DIRECTION).to_track_quat("Z", "Y").to_euler()
            fill = bpy.data.lights.new("Fill", "AREA")
            fill.energy = 120.0 * extent
            fill.size = extent * 3.0
            fill.color = (0.78, 0.86, 1.0)
            fill_obj = bpy.data.objects.new("Fill", fill)
            scene.collection.objects.link(fill_obj)
            fill_obj.location = centre + Vector((extent * 3.0, -extent * 2.0, extent * 2.0))
            fill_obj.rotation_euler = (centre - fill_obj.location).to_track_quat("-Z", "Y").to_euler()
            target = (out_root or (models / sid)) / ("%s_surface.jpg" % sid)
            target.parent.mkdir(parents=True, exist_ok=True)
            scene.render.filepath = str(target)
            bpy.ops.render.render(write_still=True)
            print("%-12s %s (%d B)  textures: %s" % (sid, target.name, target.stat().st_size, ", ".join(notes) or "none"), flush=True)
        except Exception as exc:  # noqa: BLE001
            failures.append(sid)
            print("%-12s FAILED: %s" % (sid, exc), flush=True)
    if failures:
        sys.exit(1)


def main():
    args = parse_args()
    models = pathlib.Path(args.models)
    if not models.is_absolute():
        models = pathlib.Path.cwd() / models
    if args.lit:
        lit_main(args, models)
        return
    wanted = {s.strip() for s in args.species.split(",") if s.strip()}
    folders = sorted(p for p in models.iterdir() if p.is_dir() and (p / ("%s.glb" % p.name)).exists())
    if wanted:
        folders = [p for p in folders if p.name in wanted]
    if not folders:
        print("no GLBs found under %s" % models)
        sys.exit(2)

    engine = args.engine
    if engine == "auto":
        engine = "workbench" if workbench_available() else "cycles"
    print("engine: %s" % engine)

    failures = []
    for folder in folders:
        sid = folder.name
        glb = folder / ("%s.glb" % sid)
        png = folder / ("%s.png" % sid)
        grey = folder / ("%s_grey.png" % sid)
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True)
            bpy.ops.import_scene.gltf(filepath=str(glb))
            scene = bpy.context.scene
            bpy.context.view_layer.update()
            objs = [o for o in scene.objects if o.type == "MESH"]
            setup_common(scene)
            setup_camera(scene, objs)
            if engine == "workbench":
                render_workbench(scene, png, grey)
            else:
                render_cycles(scene, png, grey)
            print("%-12s %s (%d B), %s (%d B)" % (sid, png.name, png.stat().st_size, grey.name, grey.stat().st_size), flush=True)
        except Exception as exc:  # noqa: BLE001
            failures.append(sid)
            print("%-12s FAILED: %s" % (sid, exc), flush=True)
    if failures:
        print("thumbnails failed for: %s" % ", ".join(failures))
        sys.exit(1)


if __name__ == "__main__":
    main()
