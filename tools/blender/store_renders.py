#!/usr/bin/env python3
"""Store icon candidates and thumbnails from the alien and prop GLBs (overnight job 11, docs/STORE-PAGE.md).

Same import as preview.py, but lit and shaded: Cycles on the CPU, a warm key sun and a soft sky, a vertical
sky-blue to cream gradient seen by the camera only, and a ground plane (a shadow catcher for the icons).
  icon_<Species>.png        1024x1024, one alien filling about 70% of the frame, three-quarter view from above
  thumb_verdant.png         1920x1080, five World 1 aliens on green grass in front of the ShipHull prop
  thumb_frostbyte.png       1920x1080, five World 2 aliens on snow in front of the IceSpire prop

Usage: blender -b -P tools/blender/store_renders.py -- [--out media/store/2026-10-14] [--samples 64]
"""
import argparse
import math
import pathlib
import sys

import bpy
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MODELS = ROOT / "assets/models"
SKY_TOP = (0.45, 0.72, 0.98)
SKY_BOTTOM = (1.0, 0.95, 0.84)
ICONS = ["Mossbop", "Sparkfox", "Thunderhog"]
SCENES = {
    "thumb_verdant": (["Mossbop", "Puffpuff", "Buzzlebee", "Sparkfox", "Thunderhog"], "ShipHull", (0.30, 0.62, 0.22)),
    "thumb_frostbyte": (["Flufflet", "Snowbun", "Pengoo", "Reindazzle", "Frostfang"], "IceSpire", (0.92, 0.95, 1.0)),
}


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(description="Render store icons and thumbnails")
    ap.add_argument("--out", default=str(ROOT / "media/store/2026-10-14"))
    ap.add_argument("--samples", type=int, default=64)
    return ap.parse_args(argv)


def glb_path(name):
    for p in (MODELS / name / ("%s.glb" % name), MODELS / "props" / name / ("%s.glb" % name)):
        if p.exists():
            return p
    raise FileNotFoundError(name)


def import_model(name, location=(0, 0, 0), height=None, yaw=0.0, extent=None):
    """Import one GLB, parent its meshes to an empty at its feet, optionally scale it to a height or a largest extent."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(glb_path(name)))
    objs = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    lo, hi = bounds([o for o in objs if o.type == "MESH"])
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    root.location = (((lo.x + hi.x) / 2), ((lo.y + hi.y) / 2), lo.z)
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


def bounds(objs):
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
    return lo, hi


def setup_scene(w, h, samples):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGB"
    try:
        sc.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    nt = world.node_tree
    nodes, links = nt.nodes, nt.links
    out = next(n for n in nodes if n.type == "OUTPUT_WORLD")
    for n in [n for n in nodes if n.type != "OUTPUT_WORLD"]:
        nodes.remove(n)
    coord, sep, ramp = nodes.new("ShaderNodeTexCoord"), nodes.new("ShaderNodeSeparateXYZ"), nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*SKY_BOTTOM, 1)
    ramp.color_ramp.elements[1].color = (*SKY_TOP, 1)
    seen, lit = nodes.new("ShaderNodeBackground"), nodes.new("ShaderNodeBackground")
    lit.inputs["Color"].default_value = (0.85, 0.9, 1.0, 1)
    lit.inputs["Strength"].default_value = 0.8
    path, mix = nodes.new("ShaderNodeLightPath"), nodes.new("ShaderNodeMixShader")
    links.new(coord.outputs["Window"], sep.inputs[0])
    links.new(sep.outputs["Y"], ramp.inputs[0])
    links.new(ramp.outputs["Color"], seen.inputs["Color"])
    links.new(path.outputs["Is Camera Ray"], mix.inputs[0])
    links.new(lit.outputs[0], mix.inputs[1])
    links.new(seen.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], out.inputs["Surface"])
    sc.world = world
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy, sun.data.angle, sun.data.color = 3.0, math.radians(8), (1.0, 0.93, 0.82)
    sun.rotation_euler = (math.radians(50), 0, math.radians(-35))
    sc.collection.objects.link(sun)
    return sc


def ground(sc, colour, catcher):
    bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, 0))
    plane = bpy.context.active_object
    if catcher:
        plane.is_shadow_catcher = True
    else:
        mat = bpy.data.materials.new("Ground")
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = (*colour, 1)
        bsdf.inputs["Roughness"].default_value = 0.9
        plane.data.materials.append(mat)


def camera(sc, target, distance, yaw, pitch, lens):
    d = Vector((-math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)), -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)), math.sin(math.radians(pitch))))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = lens
    cam.location = target + d * distance
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(cam)
    sc.camera = cam


def render(sc, path):
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print("rendered %s" % path, flush=True)


def main():
    args = parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in ICONS:
        sc = setup_scene(1024, 1024, args.samples)
        ground(sc, None, catcher=True)
        _, meshes = import_model(name, yaw=-20)
        lo, hi = bounds(meshes)
        size = max(hi - lo)
        # a 50 mm lens frames about 0.72 x distance across; size / 0.7 of frame -> distance
        camera(sc, (lo + hi) * 0.5, size / 0.7 / 0.72, 25, 20, 50)
        render(sc, out / ("icon_%s.png" % name))
    for key, (species, prop, colour) in SCENES.items():
        sc = setup_scene(1920, 1080, args.samples)
        ground(sc, colour, catcher=False)
        import_model(prop, location=(0, 13, 0), extent=16.0, yaw=15)
        for i, name in enumerate(species):
            x = (i - 2) * 4.2
            import_model(name, location=(x, abs(i - 2) * 1.2, 0), height=2.6 + (0.6 if name in ("Thunderhog", "Reindazzle", "Frostfang") else 0), yaw=(i - 2) * -12)
        camera(sc, Vector((0, 4, 2.6)), 26, 0, 12, 40)
        render(sc, out / ("%s.png" % key))


if __name__ == "__main__":
    main()
