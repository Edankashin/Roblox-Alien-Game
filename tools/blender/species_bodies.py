#!/usr/bin/env python3
"""Silhouette pass builder: rebuild a species' body from its recipe in tools/blender/species_recipes.py.

The same pattern as tools/blender/event_species.py. For each species named it imports assets/models/<Id>/<Id>.glb only for
its materials (the slot names and their order stay exactly as they were; every slot must be used, so the GLB keeps one
primitive per slot), builds the recipe's primitive steps and the face (eyes with whites, pupils and highlights, optional
lids, and a mouth), joins everything into one mesh, fits it to the recipe's height (a uniform scale, normally under 3
percent) with the lowest point on z = 0 and the face on -Y, and re-exports GLB and FBX in place with alien_base.py's export
settings. materials.json gets the recipe's palette, glow and metal values (slot names and order untouched) and notes.md gets
the new triangle count, height, accessory line and a line about this pass. It prints the triangle count and height per species.

  python3 tools/blender/species_recipes.py                  # no Blender needed: check every recipe first
  blender -b -P tools/blender/species_bodies.py -- --species Mossbop,Pebblet,Puffpuff
  blender -b -P tools/blender/species_bodies.py -- --species batch1            # a whole batch (1..5), or world1
  python3 tools/blender/species_bodies.py --species batch1 --models /some/copy # plain Python with the bpy module
  python3 tools/blender/preview.py --species Mossbop,Pebblet,Puffpuff          # then look at the renders

--models points at a folder laid out like assets/models (default assets/models); use a copy to try a recipe without touching
the repo's files. Exit code 1 if any species fails or goes over 2,500 triangles.
"""
import argparse
import datetime
import json
import pathlib
import re
import sys

import bpy  # first: with the bpy module, bmesh and mathutils only import after it
import bmesh
from mathutils import Matrix

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import species_recipes as SR  # noqa: E402

ROOT = HERE.parent.parent
TOOL = "tools/blender/species_bodies.py"


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description="Rebuild species bodies from tools/blender/species_recipes.py")
    ap.add_argument("--species", required=True, help="comma list of ids, or batchN, or world1")
    ap.add_argument("--models", default=str(ROOT / "assets/models"), help="models folder (default assets/models)")
    return ap.parse_args(argv)


def hex_to_rgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def principled(mat):
    return next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)


class Kit:
    """Builds the parts as separate objects, each carrying every material slot in the old order, then joins them."""

    def __init__(self, mats):
        self.mats = mats  # ordered [(name, material)]
        self.index = {n: i for i, (n, _) in enumerate(mats)}
        self.parts = []

    def _take(self, obj, slot, smooth):
        if slot == "EyeHighlight" and slot not in self.index:
            slot = "EyeWhite"  # the three event species have no highlight slot; their glint is white
        if slot not in self.index:
            raise KeyError("slot %s is not one of this model's materials (%s)" % (slot, ", ".join(n for n, _ in self.mats)))
        obj.data.materials.clear()
        for _, m in self.mats:
            obj.data.materials.append(m)
        for p in obj.data.polygons:
            p.material_index = self.index[slot]
            p.use_smooth = smooth
        self.parts.append(obj)

    @staticmethod
    def _cut(obj, half):
        """Keep the top (or bottom) half of a UV sphere: the cut is the plane z = 0 of the sphere's own axes."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        if half == "top":
            doomed = [v for v in bm.verts if v.co.z < -1e-5]
        else:
            doomed = [v for v in bm.verts if v.co.z > 1e-5]
        bmesh.ops.delete(bm, geom=doomed, context="VERTS")
        bm.to_mesh(obj.data)
        bm.free()

    def add(self, p):
        prim, n, loc = p["prim"], p["segments"], tuple(p["loc"])
        if prim == "sphere":
            bpy.ops.mesh.primitive_uv_sphere_add(segments=n, ring_count=SR._rings(n, bool(p["half"])), radius=1.0, location=loc)
        elif prim == "icosphere":
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=n, radius=1.0, location=loc)
        elif prim == "cube":
            bpy.ops.mesh.primitive_cube_add(size=2.0, location=loc)
        elif prim == "cylinder":
            bpy.ops.mesh.primitive_cylinder_add(vertices=n, radius=1.0, depth=2.0, location=loc)
        elif prim == "cone":
            bpy.ops.mesh.primitive_cone_add(vertices=n, radius1=1.0, radius2=p["tip"], depth=2.0, location=loc)
        elif prim == "torus":
            bpy.ops.mesh.primitive_torus_add(major_segments=n, minor_segments=p["mseg"], major_radius=1.0, minor_radius=p["minor"], location=loc)
        else:
            raise ValueError("unknown primitive %r" % prim)
        obj = bpy.context.active_object
        obj.name = "%s.%s" % (p["name"], prim)
        if prim == "sphere" and p["half"]:
            self._cut(obj, p["half"])
        obj.rotation_euler = Matrix(p["rot"]).to_euler()
        obj.scale = p["scale"]
        self._take(obj, p["slot"], not p["flat"])

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


def apply_materials(mats, rec):
    """Write the recipe's palette, glow and metal onto the imported materials (by slot name)."""
    by_name = dict(mats)
    for slot, value in rec.get("palette", {}).items():
        rgb = hex_to_rgb(value)
        m = by_name[slot]
        bsdf = principled(m)
        bsdf.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
        m.diffuse_color = (rgb[0], rgb[1], rgb[2], 1.0)
    for slot, strength in rec.get("glow", {}).items():
        bsdf = principled(by_name[slot])
        bsdf.inputs["Emission Color"].default_value = bsdf.inputs["Base Color"].default_value
        bsdf.inputs["Emission Strength"].default_value = strength
    for slot, metallic in rec.get("metal", {}).items():
        by_name[slot].metallic = metallic
        principled(by_name[slot]).inputs["Metallic"].default_value = metallic


def fit(obj, height):
    """Lowest point to z = 0, then a uniform scale to the recipe's height (exact, so notes.md gets the recipe's height)."""
    zs = [v.co.z for v in obj.data.vertices]
    lo, hi = min(zs), max(zs)
    scale = height / (hi - lo)
    obj.data.transform(Matrix.Translation((0.0, 0.0, -lo)))
    if scale != 1.0:
        obj.data.transform(Matrix.Scale(scale, 4))
    obj.data.update()
    zs = [v.co.z for v in obj.data.vertices]
    return min(zs), max(zs), scale


def update_files(folder, sid, rec, tris, height):
    entries = json.loads((folder / "materials.json").read_text())
    for e in entries:
        if e["name"] in rec.get("palette", {}):
            e["hex"] = rec["palette"][e["name"]].upper()
        if e["name"] in rec.get("glow", {}):
            e["emission"] = rec["glow"][e["name"]]
        if e["name"] in rec.get("metal", {}):
            e["metallic"] = rec["metal"][e["name"]]
    (folder / "materials.json").write_text(json.dumps(entries, indent=2) + "\n")
    notes = (folder / "notes.md").read_text()
    notes = re.sub(r"- Triangles: .*", "- Triangles: %d (silhouette pass, %s)" % (tris, TOOL), notes)
    notes = re.sub(r"- Height: [\d.]+ units", "- Height: %.2f units" % height, notes)
    acc = next((e for e in entries if e["name"] == "Accessory"), None)
    if acc is not None:
        extra = (", emissive %g" % acc["emission"] if acc["emission"] else "") + (", metallic" if acc["metallic"] else "")
        notes = re.sub(r"- Accessory: .*", "- Accessory: %s (silhouette pass; #%s%s)" % (rec["hero"], acc["hex"], extra), notes)
    for e in entries:
        if e["name"] in ("BodyDark", "Accessory", "Trim"):
            notes = re.sub(r"(%s #)[0-9A-Fa-f]{6}" % e["name"], r"\g<1>" + e["hex"], notes)
    line = "- Silhouette pass %s: rebuilt from primitives by %s from tools/blender/species_recipes.py. Silhouette: %s. Hero: %s." % (
        datetime.date.today().isoformat(), TOOL, rec["silhouette"], rec["hero"])
    if "- Silhouette pass" in notes:
        notes = re.sub(r"- Silhouette pass.*", lambda m: line, notes)
    else:
        notes = notes.rstrip("\n") + "\n" + line + "\n"
    (folder / "notes.md").write_text(notes)


def build(sid, models):
    rec = SR.RECIPES[sid]
    if rec["status"] != "recipe":
        raise RuntimeError("%s is a TODO stub in species_recipes.py" % sid)
    folder = models / sid
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(folder / ("%s.glb" % sid)))
    old = next(o for o in bpy.data.objects if o.type == "MESH")
    mats = [(s.material.name, s.material) for s in old.material_slots]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    apply_materials(mats, rec)
    kit = Kit(mats)
    for part in SR.expand(rec):
        kit.add(part)
    obj = kit.join(sid)
    used = {p.material_index for p in obj.data.polygons}
    if used != set(range(len(mats))):
        raise RuntimeError("unused slots: %s" % ", ".join(mats[i][0] for i in sorted(set(range(len(mats))) - used)))
    lo, hi, scale = fit(obj, rec["height"])
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris > SR.TRI_BUDGET:
        raise RuntimeError("%d triangles is over the %d cap (nothing was exported)" % (tris, SR.TRI_BUDGET))
    bpy.ops.export_scene.gltf(filepath=str(folder / ("%s.glb" % sid)), export_format="GLB", export_apply=True, export_animations=False,
                              export_yup=True, use_selection=False, export_materials="EXPORT", export_lights=False, export_cameras=False)
    bpy.ops.export_scene.fbx(filepath=str(folder / ("%s.fbx" % sid)), use_selection=False, apply_scale_options="FBX_SCALE_ALL",
                             mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
    update_files(folder, sid, rec, tris, hi - lo)
    return tris, lo, hi, scale, len(mats)


def main():
    args = parse_args()
    models = pathlib.Path(args.models)
    if not models.is_absolute():
        models = pathlib.Path.cwd() / models
    failed = []
    for sid in SR.ids_for(args.species):
        try:
            tris, lo, hi, scale, slots = build(sid, models)
            guide = SR.TRI_GUIDE[SR.RECIPES[sid]["tier"]]
            print("%-11s tris=%d height=%.2f z=%.2f..%.2f fit=x%.3f slots=%d%s" % (
                sid, tris, hi - lo, lo, hi, scale, slots, "  (over the %d target)" % guide if tris > guide else ""), flush=True)
        except Exception as exc:  # noqa: BLE001
            failed.append(sid)
            print("%-11s FAILED: %s" % (sid, exc), flush=True)
    if failed:
        print("failed: %s" % ", ".join(failed))
        sys.exit(1)
    print("next: python3 tools/blender/preview.py --species %s" % args.species)


if __name__ == "__main__":
    main()
