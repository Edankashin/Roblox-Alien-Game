#!/usr/bin/env python3
"""The character bar pilots' renders (Decision B54): each alien beside the 5-stud avatar from the front and the three-quarter, and from the
game camera's distance (16 studs, slightly above, a 70 degree field of view), for the pilot sheet (tools/blocky/pilot_sheet.py).

Headless Blender (bpy 5.0), one render at a time:

  BPY=<python with bpy>
  $BPY tools/blender/pilot_shots.py --notes Mossbop.md,Radish.md --out <scratch dir> [--views front,tq,cam] [--size 560] [--samples 32]

Writes <out>/<Id>_front.png, <Id>_tq.png (alien and avatar, orthographic, lit like the roster sheets) and <Id>_cam.png (perspective, the alien
and the avatar side by side 16 studs from the camera). The notes are built with the cell atlas exactly as tools/blender/blocky_build.py does.
"""
from __future__ import annotations

import argparse
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools/blocky"))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import blocky_build as BB  # noqa: E402
import spec as S  # noqa: E402


def scene_for(spec, out, aspect=1.0):
    """The avatar at the origin and the alien to its right (the camera looks from -Y, so +X is the viewer's right)."""
    BB.reset()
    objs = list(BB.avatar((0, 0, 0), out_dir=out))
    lo, hi = S.bounds(S.expand(spec["parts"]))
    width = hi[0] - lo[0]
    x = 2.0 + 1.2 + width / 2
    made = BB.build(spec, out, offset=(x, 0.0, 0.0))
    return objs, made["objects"], x


def render_ortho(spec, out, name, yaw, pitch, size, samples):
    objs, alien, x = scene_for(spec, out)
    scene = bpy.context.scene
    allobjs = objs + alien
    aspect = 1.45
    cam, centre, extent = BB.tq_camera(scene, allobjs, yaw=yaw, pitch=pitch, margin=1.1, aspect=aspect)
    BB.lit_setup(scene, size, samples, extent=extent, centre=centre)
    BB.add_lights(scene, centre, extent)
    scene.render.resolution_x = int(size * aspect)
    scene.render.resolution_y = size
    scene.render.filepath = str(pathlib.Path(out) / name)
    bpy.ops.render.render(write_still=True)


def render_cam(spec, out, name, size, samples, distance=16.0, pitch=18.0, yaw=24.0, fov=70.0):
    """A perspective camera `distance` studs from the alien's middle, looking down `pitch` degrees from `yaw` degrees to the side; the avatar
    stands two studs to its left, as another player would."""
    objs, alien, x = scene_for(spec, out)
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    lo, hi = BB.bounds(alien)
    centre = Vector((x / 2, (lo.y + hi.y) / 2, hi.z / 2))
    d = Vector((-math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)), -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)),
                math.sin(math.radians(pitch))))
    cam_data = bpy.data.cameras.new("Game")
    cam_data.type = "PERSP"
    cam_data.sensor_fit = "VERTICAL"
    cam_data.angle_y = math.radians(fov)
    cam_data.clip_end = 400
    cam = bpy.data.objects.new("Game", cam_data)
    scene.collection.objects.link(cam)
    cam.location = centre + d * distance
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    # the world's own ground and sky: Verdant's meadow grass, Frostbyte's snow, so what reads in the strip is what reads in play
    floor, sky = (("#E4EEF6", (0.80, 0.87, 0.96)) if int(spec["front"].get("world", 1)) == 2 else ("#7DBE5C", (0.74, 0.88, 1.0)))
    BB.lit_setup(scene, size, samples, extent=6.0, centre=centre, floor_hex=floor, sky=sky)
    BB.add_lights(scene, centre, 6.0)
    # a 1080p frame (what a phone held sideways shows), rendered only in its middle: the alien and the avatar, 640 x 432 pixels at 1:1
    scene.render.resolution_x, scene.render.resolution_y = 1920, 1080
    scene.render.use_border = True
    scene.render.use_crop_to_border = True
    scene.render.border_min_x, scene.render.border_max_x = 0.32, 0.6533
    scene.render.border_min_y, scene.render.border_max_y = 0.30, 0.70
    scene.render.filepath = str(pathlib.Path(out) / name)
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--notes", required=True, help="a comma list of creature notes")
    ap.add_argument("--out", required=True, help="a scratch folder")
    ap.add_argument("--views", default="front,tq,cam")
    ap.add_argument("--size", type=int, default=560)
    ap.add_argument("--samples", type=int, default=32)
    a = ap.parse_args(argv)
    views = set(a.views.split(","))
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for note in [n for n in a.notes.split(",") if n]:
        spec = S.load(note)
        sid = spec["front"]["id"]
        if "front" in views:
            render_ortho(spec, out, "%s_front.png" % sid, 0.0, 6.0, a.size, a.samples)
        if "tq" in views:
            render_ortho(spec, out, "%s_tq.png" % sid, 30.0, 16.0, a.size, a.samples)
        if "cam" in views:
            render_cam(spec, out, "%s_cam.png" % sid, 1080, a.samples)
        print("%-10s done" % sid, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
