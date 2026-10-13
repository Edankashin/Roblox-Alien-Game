#!/usr/bin/env python3
"""Look pass for the three Haunted Nebula species (overnight job 15): each gets its concept instead of the
shared ball-and-tuft body that alien_base.py gives every species.

For each of Wisplet, Spookum and Nebulyn this imports assets/models/<Id>/<Id>.glb only for its materials (the
slot names, order and colours stay exactly as they were), rebuilds the body from primitives, joins it into one
mesh whose slots keep the old order (every slot used, so the GLB keeps one primitive per slot), keeps the height
from notes.md and the pivot at the feet (z = 0, face on -Y, Z-up), and re-exports GLB and FBX in place with
alien_base.py's export settings. notes.md gets the new triangle count and a line about this pass.
  Wisplet  a teardrop flame leaning a little, a lantern ring at the base, a shy face low and close-set
  Spookum  a ghost: dome and skirt ending in 8 rounded scallops, floating 0.4 above the pivot, triangle eyes,
           a zig-zag pumpkin grin
  Nebulyn  a puffy cloud of four spheres, two big bright eyes, a tail of gold glowing stars trailing back and up

Usage: blender -b -P tools/blender/event_species.py -- [--species Wisplet,Spookum,Nebulyn]
"""
import argparse
import json
import math
import pathlib
import re
import sys

import bmesh
import bpy
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
MODELS = ROOT / "assets/models"


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--species", default="Wisplet,Spookum,Nebulyn")
    return ap.parse_args(argv)


class Kit:
    """Builds parts as separate objects, each with one material, then joins them keeping the slot order."""

    def __init__(self, mats):
        self.mats = mats  # ordered [(name, material)]
        self.index = {n: i for i, (n, _) in enumerate(mats)}
        self.parts = []

    def _take(self, obj, mat, smooth=True):
        obj.data.materials.clear()
        for _, m in self.mats:
            obj.data.materials.append(m)
        for p in obj.data.polygons:
            p.material_index = self.index[mat]
            p.use_smooth = smooth
        self.parts.append(obj)
        return obj

    def sphere(self, loc, scale, mat, segs=16, rings=10):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=rings, radius=1.0, location=loc)
        o = bpy.context.active_object
        o.scale = scale
        return self._take(o, mat)

    def cylinder(self, loc, radius, depth, mat, verts=24):
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc, end_fill_type="NOTHING")
        return self._take(bpy.context.active_object, mat)

    def torus(self, loc, major, minor, mat):
        bpy.ops.mesh.primitive_torus_add(major_segments=24, minor_segments=8, major_radius=major, minor_radius=minor, location=loc)
        return self._take(bpy.context.active_object, mat)

    def mesh(self, name, verts, faces, mat, smooth=False):
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], faces)
        me.update()
        o = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(o)
        return self._take(o, mat, smooth)

    def join(self, name):
        bpy.ops.object.select_all(action="DESELECT")
        for o in self.parts:
            o.select_set(True)
        bpy.context.view_layer.objects.active = self.parts[0]
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        bpy.ops.object.join()
        obj = bpy.context.active_object
        obj.name = obj.data.name = name
        return obj


def eye(kit, x, z, surface_y, r, look=0.0):
    """A flattened white disc on the surface with a pupil and a white catch-light in front of it."""
    kit.sphere((x, surface_y - r * 0.15, z), (r, r * 0.45, r), "EyeWhite", 12, 6)
    kit.sphere((x + look, surface_y - r * 0.5, z - r * 0.1), (r * 0.6, r * 0.3, r * 0.62), "Pupil", 10, 5)


def surface_y(cx, cz, r, x, z, cy=0.0):
    """Front (-Y) surface of a sphere of radius r centred (cx, cy, cz) at (x, z)."""
    d = r * r - (x - cx) ** 2 - (z - cz) ** 2
    return cy - math.sqrt(max(d, 0.0))


def ellipsoid_y(x, z, r, rz, cz):
    """Front (-Y) surface of an ellipsoid of radius r, half-height rz, centred on the z axis at cz."""
    return -r * math.sqrt(max(0.0, 1.0 - (x / r) ** 2 - ((z - cz) / rz) ** 2))


def build_wisplet(kit, h):
    r = h * 0.36
    cz = r * 1.05
    body = kit.sphere((0, 0, 0), (1, 1, 1), "Body", 24, 16)
    for v in body.data.vertices:  # ball -> teardrop flame: taper the top half to a point, lean it a little
        t = (v.co.z + 1.0) / 2.0
        w = 1.0 if t < 0.55 else max(0.0, 1.0 - (t - 0.55) / 0.45) ** 0.9
        lean = 0.35 * max(0.0, t - 0.4) ** 2
        v.co = Vector((v.co.x * w * r + lean * r, v.co.y * w * r, v.co.z * r * (1.0 if t < 0.5 else 1.0 + (t - 0.5) * 1.6) + cz))
    top = max(v.co.z for v in body.data.vertices)
    for v in body.data.vertices:  # scale to the height: lantern ring at the base, the tip at h
        v.co.z = (v.co.z - (cz - r)) * (h - 0.12) / (top - (cz - r)) + 0.12
    kit.torus((0, 0, 0.16), r * 0.78, r * 0.12, "BodyDark")
    kit.sphere((0, -r * 0.86, 0.17), (r * 0.12, r * 0.08, r * 0.12), "Accessory", 10, 6)  # a glowing gem on the front of the lantern ring
    ez = h * 0.36
    for x in (-r * 0.26, r * 0.26):
        eye(kit, x, ez, surface_y(0, 0.12 + r, r, x, ez) + 0.02, r * 0.2, look=r * 0.03)
    kit.sphere((0.0, surface_y(0, 0.12 + r, r, 0, ez - r * 0.38) - 0.01, ez - r * 0.38), (r * 0.09, r * 0.05, r * 0.05), "Mouth", 10, 6)


def build_spookum(kit, h):
    lift, R = 0.4, 1.25
    s = 0.42
    cz = h - R - 0.16  # the wisp on top ends at h
    hem = lift + s
    kit.sphere((0, 0, cz), (R, R, R), "Body", 20, 12)
    kit.cylinder((0, 0, (cz + hem) / 2), R, cz - hem, "Body")
    for i in range(8):  # the wavy hem: eight rounded scallops round the skirt's bottom edge
        a = math.radians(22.5 + 45 * i)
        kit.sphere((math.cos(a) * R * 0.86, math.sin(a) * R * 0.86, hem), (s, s, s), "BodyDark" if i % 2 else "Body", 12, 6)
    kit.sphere((0, 0, hem + 0.05), (R * 0.9, R * 0.9, 0.18), "BodyDark", 20, 6)
    ez = cz + 0.15
    for side in (-1, 1):  # jack-o'-lantern eyes: dark triangles pressed onto the face, a white catch-light
        x0 = side * 0.42
        tri = [(x0 - 0.2, ez - 0.14), (x0 + 0.2, ez - 0.14), (x0 + side * 0.04, ez + 0.2)]
        verts = []
        for (x, z) in tri:
            y = surface_y(0, cz, R, x, z)
            verts += [(x, y - 0.03, z), (x, y + 0.04, z)]
        kit.mesh("Eye", verts, [(0, 2, 4), (1, 5, 3), (0, 1, 3, 2), (2, 3, 5, 4), (4, 5, 1, 0)], "Pupil")
        kit.sphere((x0 - side * 0.05, surface_y(0, cz, R, x0, ez) - 0.05, ez - 0.02), (0.05, 0.02, 0.05), "EyeWhite", 8, 4)
    # the pumpkin grin: a zig-zag strip that follows the curve of the face
    xs = [-0.62 + 0.124 * i for i in range(11)]
    zt = [cz - 0.26 + (0.1 if i % 2 else -0.07) for i in range(11)]
    zb = [cz - 0.5 - 0.12 * math.cos(math.pi * (i / 10.0 - 0.5)) for i in range(11)]
    verts = []
    for x, a, b in zip(xs, zt, zb):
        for z in (a, b):
            y = surface_y(0, cz, R, x, z) if z >= cz else -math.sqrt(R * R - x * x)  # below the dome: the skirt
            verts += [(x, y - 0.03, z), (x, y + 0.05, z)]
    faces = []
    for i in range(10):
        a, b = 4 * i, 4 * (i + 1)
        faces += [(a, b, b + 2, a + 2), (a + 1, a + 3, b + 3, b + 1), (a, a + 1, b + 1, b), (a + 2, b + 2, b + 3, a + 3)]
    faces += [(0, 2, 3, 1), (40, 41, 43, 42)]
    kit.mesh("Grin", verts, faces, "Mouth")
    kit.sphere((0.15, 0.1, h - 0.2), (0.14, 0.14, 0.2), "Accessory", 10, 6)  # a little blue wisp on top
    kit.torus((-0.95, 0.1, cz + 0.65), 0.16, 0.06, "Trim")  # a purple bow-ring on one side of the head
    kit.sphere((-0.95, 0.1, cz + 0.65), (0.09, 0.09, 0.09), "Trim", 8, 4)


def octahedron(kit, c, r, mat):
    x, y, z = c
    v = [(x + r, y, z), (x - r, y, z), (x, y + r, z), (x, y - r, z), (x, y, z + r * 1.3), (x, y, z - r * 1.3)]
    f = [(0, 2, 4), (2, 1, 4), (1, 3, 4), (3, 0, 4), (2, 0, 5), (1, 2, 5), (3, 1, 5), (0, 3, 5)]
    kit.mesh("Star", v, f, mat)


def build_nebulyn(kit, h):
    cz = 1.25
    puffs = [((0, 0, cz), 1.0, "Body"), ((-0.85, 0.15, cz - 0.15), 0.72, "Body"), ((0.85, 0.15, cz - 0.15), 0.72, "Body"),
             ((0.15, 0.45, cz + 0.6), 0.75, "Body"), ((0, 0.1, cz - 0.55), 0.62, "BodyDark")]
    for c, r, m in puffs:
        kit.sphere(c, (r, r, r * 0.82), m, 16, 10)
    ez = cz + 0.1
    for x in (-0.36, 0.36):
        eye(kit, x, ez, ellipsoid_y(x, ez, 1.0, 0.82, cz) + 0.02, 0.27, look=0.0)
        kit.sphere((x - 0.08, ellipsoid_y(x, ez, 1.0, 0.82, cz) - 0.15, ez + 0.1), (0.06, 0.02, 0.06), "EyeWhite", 8, 4)
    kit.sphere((0, ellipsoid_y(0, ez - 0.36, 1.0, 0.82, cz) - 0.01, ez - 0.36), (0.13, 0.05, 0.07), "Mouth", 10, 6)
    # the tail of stars, trailing back (+Y) and up to the full height
    tail = [((0.35, 1.05, cz + 0.9), 0.17), ((0.7, 1.45, cz + 1.4), 0.15), ((0.95, 1.75, cz + 1.85), 0.13)]
    for c, r in tail:
        octahedron(kit, c, r, "Accessory")
    octahedron(kit, (1.15, 2.0, h - 0.26), 0.2, "Trim")


def main():
    args = parse_args()
    for sid in [s.strip() for s in args.species.split(",") if s.strip()]:
        folder = MODELS / sid
        notes = (folder / "notes.md").read_text()
        h = float(re.search(r"Height: ([\d.]+)", notes).group(1))
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(folder / ("%s.glb" % sid)))
        old = next(o for o in bpy.data.objects if o.type == "MESH")
        mats = [(s.material.name, s.material) for s in old.material_slots]
        for o in list(bpy.data.objects):
            bpy.data.objects.remove(o)
        if sid == "Nebulyn" or sid == "Wisplet":  # the glowing bits: an emission on their own material
            m = dict(mats)["Accessory"]
            bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
            bsdf.inputs["Emission Color"].default_value = bsdf.inputs["Base Color"].default_value
            bsdf.inputs["Emission Strength"].default_value = 1.5
        kit = Kit(mats)
        {"Wisplet": build_wisplet, "Spookum": build_spookum, "Nebulyn": build_nebulyn}[sid](kit, h)
        obj = kit.join(sid)
        lo = min(v.co.z for v in obj.data.vertices)
        hi = max(v.co.z for v in obj.data.vertices)
        tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
        used = {p.material_index for p in obj.data.polygons}
        assert used == set(range(len(mats))), "%s: unused slots %s" % (sid, set(range(len(mats))) - used)
        bpy.ops.export_scene.gltf(filepath=str(folder / ("%s.glb" % sid)), export_format="GLB", export_apply=True, export_animations=False,
                                  export_yup=True, use_selection=False, export_materials="EXPORT", export_lights=False, export_cameras=False)
        bpy.ops.export_scene.fbx(filepath=str(folder / ("%s.fbx" % sid)), use_selection=False, apply_scale_options="FBX_SCALE_ALL",
                                 mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
        entries = json.loads((folder / "materials.json").read_text())
        for e in entries:
            if e["name"] == "Accessory" and sid in ("Nebulyn", "Wisplet"):
                e["emission"] = 1.5
        (folder / "materials.json").write_text(json.dumps(entries, indent=2) + "\n")
        notes = re.sub(r"- Triangles: .*", "- Triangles: %d (look pass, tools/blender/event_species.py)" % tris, notes)
        if "Look pass:" not in notes:
            notes = notes.rstrip("\n") + "\n- Look pass: %s rebuilt from primitives by tools/blender/event_species.py to its concept (same slots, height and pivot).\n" % sid
        (folder / "notes.md").write_text(notes)
        print("%-8s tris=%d z=%.2f..%.2f slots=%d" % (sid, tris, lo, hi, len(mats)), flush=True)


if __name__ == "__main__":
    main()
