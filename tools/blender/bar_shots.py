#!/usr/bin/env python3
"""The character bar roster renders (Decisions B54 to B56): the pilot shots (tools/blender/pilot_shots.py) plus a face view.

Headless Blender (bpy 5.0), one render at a time:

  BPY=<python with bpy>
  $BPY tools/blender/bar_shots.py --notes Reindazzle.md,Shellberg.md --out <scratch dir> [--views front,tq,cam,face] [--size 560] [--samples 32]

`front`, `tq` and `cam` are pilot_shots.py's (the alien beside the 5-stud avatar, orthographic front and three-quarter, and the game camera 16
studs away on the world's own ground). `face` is the review sheet's face view: the alien straight on, orthographic, the camera on its front, the
frame 3 studs across and centred on the head (the face host), nothing else in the picture but the sky, so a face reads as it will in the codex
and the reveal and can be put beside a best-seller's (Character-References, "The appeal check"). Writes <out>/<Id>_face.png, 512 px square.
"""
from __future__ import annotations

import argparse
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import blocky_build as BB  # noqa: E402
import pilot_shots as PS  # noqa: E402
import spec as S  # noqa: E402

FACE_FRAME = 3.0   # studs across


def render_face(spec, out, name, size, samples, frame=FACE_FRAME):
    BB.reset()
    built = BB.build(spec, out, offset=(0.0, 0.0, 0.0))
    scene = bpy.context.scene
    host = S.face_host(spec)
    posed = [p for p in S.expand(spec["parts"]) if p["source"] == host["name"]][0]
    centre = BB.to_bl(posed["at"])
    # the plate sits on the host's front (spec -z, Blender -y); look at the head from the front, level
    cam_data = bpy.data.cameras.new("Face")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = frame
    cam_data.clip_start = 0.1
    cam_data.clip_end = 200
    cam = bpy.data.objects.new("Face", cam_data)
    scene.collection.objects.link(cam)
    BB.look(cam, centre + Vector((0, -60, 0)), Vector((0, 1, 0)), Vector((0, 0, 1)))
    scene.camera = cam
    BB.lit_setup(scene, size, samples, sky=(0.80, 0.87, 0.96), extent=4.0, centre=centre)
    BB.add_lights(scene, centre, 4.0)
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.filepath = str(pathlib.Path(out) / name)
    bpy.ops.render.render(write_still=True)
    return built


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--notes", required=True, help="a comma list of creature notes")
    ap.add_argument("--out", required=True, help="a scratch folder")
    ap.add_argument("--views", default="front,tq,cam,face")
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
            PS.render_ortho(spec, out, "%s_front.png" % sid, 0.0, 6.0, a.size, a.samples)
        if "tq" in views:
            PS.render_ortho(spec, out, "%s_tq.png" % sid, 30.0, 16.0, a.size, a.samples)
        if "cam" in views:
            PS.render_cam(spec, out, "%s_cam.png" % sid, 1080, a.samples)
        if "face" in views:
            render_face(spec, out, "%s_face.png" % sid, 512, a.samples)
        print("%-10s done" % sid, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
