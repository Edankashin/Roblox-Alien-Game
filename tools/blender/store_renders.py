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

Usage: blender -b -P tools/blender/store_renders.py -- [--out media/store/2026-10-14] [--samples 64] [--suffix _v2]
"""
import argparse
import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MODELS = ROOT / "assets/models"
DAY = ((0.45, 0.72, 0.98), (1.0, 0.95, 0.84))
WINTER = ((0.18, 0.45, 0.92), (0.86, 0.93, 1.0))
DUSK = ((0.10, 0.07, 0.30), (0.45, 0.25, 0.62))
NAVY = (0.06, 0.08, 0.22)
ICONS = ["Mossbop", "Sparkfox", "Thunderhog"]
TALL = ("Thunderhog", "Reindazzle", "Frostfang")


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(description="Render store icons and thumbnails")
    ap.add_argument("--out", default=str(ROOT / "media/store/2026-10-14"))
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--suffix", default="_v2")
    return ap.parse_args(argv)


def glb_path(name):
    for p in (MODELS / name / ("%s.glb" % name), MODELS / "props" / name / ("%s.glb" % name)):
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


def setup_scene(w, h, samples, sky, sun_energy=3.0):
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
    sun.data.energy, sun.data.angle, sun.data.color = sun_energy, math.radians(8), (1.0, 0.93, 0.82)
    sun.rotation_euler = (math.radians(50), 0, math.radians(-35))
    sc.collection.objects.link(sun)
    return sc


def outline(sc, width_px):
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
    ls.linestyle.color = NAVY
    ls.linestyle.thickness = width_px


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


def main():
    args = parse_args()
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
