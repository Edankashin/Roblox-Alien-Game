#!/usr/bin/env python3
"""Lit review renders of one model from several sides: front, tq (the 30 degree view `preview.py --lit` writes), side, back.

The review views of the design pass (docs/vault/06-art-pipelines/Design-Pass.md): `preview.py`'s own lit_scene, surface_variant, lights and framing,
with the model turned about z under an empty so the camera and the sun stay put (front = the camera at yaw 0, tq = 30 degrees, side = 90). Cycles on
the CPU, one JPEG per species and view: <out>/<Id>_<view><suffix>.jpg. The slot colours come from the model's materials.json, as Roblox colours a MeshPart
(a shipped GLB carries them washed out). Needs a Python with the bpy module:

  python3 tools/blender/review_views.py --models DIR --species Id,Id --out DIR [--views front,tq,side] [--size 420] [--samples 48]
                                        [--backdrop A9C7E6] [--suffix _x] [--extent 4.2]

`--extent` frames every view by that length (studs) instead of the model's own longest side: pass the longer of the old body's and the new one's
longest sides to a pair of renders and they come out to scale. It only reads the GLBs; it never writes next to them.
"""
import argparse
import json
import math
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402
import preview as P  # noqa: E402

TURN = {"tq": 0.0, "front": -30.0, "side": -120.0, "back": 150.0, "side_r": 60.0}


def render(models, sid, view, out, size, samples, backdrop_hex, suffix, force_extent=0.0):
    backdrop = P.backdrop_linear(backdrop_hex) if backdrop_hex else None
    scene = P.lit_scene(size, backdrop)
    scene.cycles.samples = samples
    scene.render.resolution_x = size
    entries = json.loads((models / sid / "materials.json").read_text())
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(models / sid / ("%s.glb" % sid)))
    objs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    for o in objs:
        P.surface_variant(o, entries, "/nonexistent")
        by_name = {e["name"]: e for e in entries}
        for slot in o.material_slots:  # the slot colours from materials.json, as Roblox colours a MeshPart (the shipped GLBs carry them washed out)
            mat = slot.material
            e = by_name.get(re.sub(r"\.\d{3}$", "", mat.name))
            bsdf = P.principled_of(mat)
            if e is None or bsdf is None:
                continue
            link = next((k for k in mat.node_tree.links if k.to_node == bsdf and k.to_socket.name == "Base Color"), None)
            if link is not None and link.from_node.type == "MIX":
                link.from_node.inputs[7].default_value = P.hex_linear(e["hex"])
            elif link is None:
                bsdf.inputs["Base Color"].default_value = P.hex_linear(e["hex"])
    bpy.context.view_layer.update()
    lo, hi = P.scene_bounds(objs)
    extent = force_extent or max(hi - lo)
    pivot = bpy.data.objects.new("pivot", None)
    scene.collection.objects.link(pivot)
    for o in bpy.data.objects:
        if o not in before and o.parent is None and o is not pivot:
            o.parent = pivot
    pivot.rotation_euler = (0.0, 0.0, math.radians(TURN[view]))
    bpy.context.view_layer.update()
    lo, hi = P.scene_bounds(objs)
    centre = (lo + hi) * 0.5
    yaw, pitch = math.radians(30.0), math.radians(18.0)
    direction = Vector((-math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * 1.3
    cam_data.clip_end = extent * 40.0
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = centre + direction * extent * 8.0
    cam.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    scene.camera = cam
    bpy.ops.mesh.primitive_plane_add(size=extent * 20.0, location=(centre.x, centre.y, 0.0))
    floor = bpy.context.active_object
    floor_mat = bpy.data.materials.new("Floor")
    floor_mat.use_nodes = True
    fc = (0.93, 0.9, 0.82, 1.0) if backdrop is None else (backdrop[0] * 0.8, backdrop[1] * 0.8, backdrop[2] * 0.8, 1.0)
    P.principled_of(floor_mat).inputs["Base Color"].default_value = fc
    P.principled_of(floor_mat).inputs["Roughness"].default_value = 1.0
    floor.data.materials.append(floor_mat)
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.2
    sun.angle = math.radians(14.0)
    sun.color = (1.0, 0.95, 0.88)
    sun_obj = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = Vector(P.SUN_DIRECTION).to_track_quat("Z", "Y").to_euler()
    fill = bpy.data.lights.new("Fill", "AREA")
    fill.energy = 120.0 * extent
    fill.size = extent * 3.0
    fill.color = (0.78, 0.86, 1.0)
    fill_obj = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fill_obj)
    fill_obj.location = centre + Vector((extent * 3.0, -extent * 2.0, extent * 2.0))
    fill_obj.rotation_euler = (centre - fill_obj.location).to_track_quat("-Z", "Y").to_euler()
    target = out / ("%s_%s%s.jpg" % (sid, view, suffix))
    target.parent.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(target)
    bpy.ops.render.render(write_still=True)
    print("%-14s %-6s %s" % (sid, view, target.name), flush=True)


def extent_of(models, sid):
    """The longest side (studs) of the model's bounding box: what `render` frames a view by when no --extent is given."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(models / sid / ("%s.glb" % sid)))
    objs = [o for o in bpy.data.objects if o.type == "MESH"]
    bpy.context.view_layer.update()
    lo, hi = P.scene_bounds(objs)
    return float(max(hi - lo))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", required=True)
    ap.add_argument("--species", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--views", default="front,tq,side")
    ap.add_argument("--size", type=int, default=420)
    ap.add_argument("--samples", type=int, default=48)
    ap.add_argument("--backdrop", default="")
    ap.add_argument("--suffix", default="")
    ap.add_argument("--extent", type=float, default=0.0, help="frame every view by this length (studs) instead of the model's own longest side")
    ap.add_argument("--old", default="", help="a folder of the shipped bodies: for each <Id>V2 also render <Id> from it (--old-views), and frame both by the longer "
                    "of the two bodies' longest sides, so the old body and the new one are to scale")
    ap.add_argument("--old-views", default="tq,front")
    a = ap.parse_args(argv)
    models = pathlib.Path(a.models)
    for sid in a.species.split(","):
        extent = a.extent
        base = sid[:-2] if sid.endswith("V2") else None
        old = pathlib.Path(a.old) if a.old and base and (pathlib.Path(a.old) / base / ("%s.glb" % base)).exists() else None
        if old is not None and not extent:
            extent = max(extent_of(models, sid), extent_of(old, base))
        for view in a.views.split(","):
            render(models, sid, view, pathlib.Path(a.out), a.size, a.samples, a.backdrop, a.suffix, extent)
        if old is not None:
            for view in a.old_views.split(","):
                render(old, base, view, pathlib.Path(a.out), a.size, a.samples, a.backdrop, a.suffix, extent)


if __name__ == "__main__":
    main()
