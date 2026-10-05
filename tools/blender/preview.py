#!/usr/bin/env python3
"""Thumbnail renders of the blockout aliens for silhouette review without opening Blender.

For every assets/models/<SpeciesId>/<SpeciesId>.glb this imports the mesh, frames it with an orthographic
camera from the front-left (30 degrees off the front, slightly above) and renders two 256x256 PNGs with the
Workbench engine, flat shading, grey background:
  <SpeciesId>.png        material colours (what Studio will show)
  <SpeciesId>_grey.png   Workbench colour type SINGLE: a solid silhouette, the design's greyscale check
If Workbench cannot start headless (no GPU/display) the script falls back to Cycles on the CPU with
emission-only materials, which gives the same flat look. --engine forces one.

Usage: python3 tools/blender/preview.py [--models assets/models] [--species Mossbop,Radish] [--engine auto|workbench|cycles]
       blender -b -P tools/blender/preview.py -- --species Mossbop
"""
import argparse
import math
import pathlib
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


def main():
    args = parse_args()
    models = pathlib.Path(args.models)
    if not models.is_absolute():
        models = pathlib.Path.cwd() / models
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
