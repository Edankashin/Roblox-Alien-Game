#!/usr/bin/env python3
"""Silhouette pass builder: rebuild a species' body from its recipe in tools/blender/species_recipes.py.

The same pattern as tools/blender/event_species.py. For each species named it imports assets/models/<Id>/<Id>.glb only for
its materials (the slot names and their order stay exactly as they were; every slot must be used, so the GLB keeps one
primitive per slot), builds the recipe's primitive steps and the face (eyes with whites, pupils and highlights, optional
lids, and a mouth), joins everything into one mesh, fits it to the recipe's height (a uniform scale, normally under 3
percent) with the lowest point on z = 0 and the face on -Y, and re-exports GLB and FBX in place with alien_base.py's export
settings. materials.json gets the recipe's palette, glow and metal values (slot names and order untouched) and notes.md gets
the new triangle count, height, accessory line and a line about this pass. It prints the triangle count and height per species.

The Surface pass (docs/vault/06-art-pipelines/Surface-Pass.md, numbers in species_recipes.SURFACE) runs by default: every smooth
part (and every cube) is shaded smooth by angle, cubes and cylinders thick enough get a two-segment bevel before the join, a
greyscale top-to-bottom vertex colour (lighter crown, darker belly, a little darker again facing the ground) is written to the mesh and
exported in the GLB, and a slot whose materials.json names a `texture` has its UVs scaled by that texture's tiling (data/Textures).
A body that would go over the triangle cap with the bevel is built again without it. `--no-surface` skips all of it and writes the
output this script wrote before the pass.

  python3 tools/blender/species_recipes.py                  # no Blender needed: check every recipe first
  blender -b -P tools/blender/species_bodies.py -- --species Mossbop,Pebblet,Puffpuff
  blender -b -P tools/blender/species_bodies.py -- --species batch1            # a whole batch (1..5), or world1
  python3 tools/blender/species_bodies.py --species batch1 --models /some/copy # plain Python with the bpy module
  python3 tools/blender/preview.py --species Mossbop,Pebblet,Puffpuff          # then look at the renders
  blender -b -P tools/blender/species_bodies.py -- --species Mossbop --no-surface    # the pre-surface output
  python3 tools/blender/preview.py --lit --species Mossbop                      # the lit review render (gradient, gloss, textures)

--models points at a folder laid out like assets/models (default assets/models); use a copy to try a recipe without touching
the repo's files. Exit code 1 if any species fails or goes over 2,500 triangles.
"""
import argparse
import datetime
import json
import math
import pathlib
import re
import sys

import bpy  # first: with the bpy module, bmesh and mathutils only import after it
import bmesh
from mathutils import Matrix

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import species_recipes as SR  # noqa: E402
import luau_tables  # noqa: E402

ROOT = HERE.parent.parent
TOOL = "tools/blender/species_bodies.py"
TEXTURES = ROOT / "src/shared/data/Textures.luau"
GRADIENT_ATTRIBUTE = "Col"


class OverBudget(RuntimeError):
    """The body went over the triangle cap (nothing was exported)."""


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description="Rebuild species bodies from tools/blender/species_recipes.py")
    ap.add_argument("--species", required=True, help="comma list of ids, or batchN, or world1")
    ap.add_argument("--models", default=str(ROOT / "assets/models"), help="models folder (default assets/models)")
    ap.add_argument("--no-surface", action="store_true",
                    help="skip the Surface pass (smoothing, bevel, vertex gradient, UV tiling): the pre-pass output")
    return ap.parse_args(argv)


def hex_to_rgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def principled(mat):
    return next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)


class Kit:
    """Builds the parts as separate objects, each carrying every material slot in the old order, then joins them."""

    def __init__(self, mats, surface=None):
        self.mats = mats  # ordered [(name, material)]
        self.index = {n: i for i, (n, _) in enumerate(mats)}
        self.parts = []
        self.surface = surface  # species_recipes.SURFACE, or None for the pre-pass output
        self.bevelled = 0

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
        if self.surface:
            self._soften(obj, p)

    def _soften(self, obj, p):
        """The Surface pass on one part: a bevel on a thick cube or cylinder, then smooth shading by angle (a part the recipe
        marks flat stays flat, except a cube, which is a hard primitive the bevel and the smoothing are for)."""
        S = self.surface
        # The thinnest size in studs, from the recipe's scale (obj.dimensions is stale until the next depsgraph update).
        sx, sy, sz = p["scale"]
        thin = 2.0 * min(sx, sy, sz) if p["prim"] in ("cube", "cylinder") else 0.0
        if p["prim"] in ("cube", "cylinder") and thin >= S["bevel_min_dim"] and S["bevel_segments"] > 0:
            bpy.ops.object.select_all(action="DESELECT")
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            # Bake the scale first so the width is in studs and a squashed cube is not bevelled unevenly.
            bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = min(S["bevel_width"], 0.2 * thin)
            mod.segments = S["bevel_segments"]
            mod.limit_method = "ANGLE"
            mod.angle_limit = math.radians(S["bevel_angle"])
            bpy.ops.object.modifier_apply(modifier=mod.name)
            self.bevelled += 1
        if not p["flat"] or p["prim"] == "cube":
            shade_by_angle(obj.data, math.radians(S["smooth_angle"]))

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


def shade_by_angle(mesh, angle):
    """Smooth shading with the edges sharper than `angle` (radians) left creased: Shade Smooth by Angle without an operator."""
    limit = math.cos(angle)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for face in bm.faces:
        face.smooth = True
    for edge in bm.edges:
        if len(edge.link_faces) == 2:
            a, b = edge.link_faces
            edge.smooth = a.normal.dot(b.normal) >= limit
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()


def smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def paint_gradient(obj, mats, gradient):
    """Write a greyscale colour attribute (crown 1.0 to belly darker by height, darker again where the normal faces down).
    Roblox multiplies it with the part's Color, so only the listed slots take it; the face and the rest stay 1.0."""
    mesh = obj.data
    zs = [v.co.z for v in mesh.vertices]
    lo, hi = min(zs), max(zs)
    span = max(hi - lo, 1e-6)
    listed = {i for i, (name, _) in enumerate(mats) if name in gradient["slots"]}
    if GRADIENT_ATTRIBUTE in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes[GRADIENT_ATTRIBUTE])
    attribute = mesh.color_attributes.new(GRADIENT_ATTRIBUTE, "FLOAT_COLOR", "CORNER")
    mesh.color_attributes.active_color = attribute
    mesh.color_attributes.render_color_index = list(mesh.color_attributes).index(attribute)
    for poly in mesh.polygons:
        for loop in poly.loop_indices:
            vertex = mesh.vertices[mesh.loops[loop].vertex_index]
            value = 1.0
            if poly.material_index in listed:
                t = smoothstep((vertex.co.z - lo) / span)
                value = gradient["belly"] + (gradient["crown"] - gradient["belly"]) * t
                value *= 1.0 - gradient["down"] * max(0.0, -vertex.normal.z)
                value = max(0.0, min(1.0, value))
            attribute.data[loop].color = (value, value, value, 1.0)
    return min(d.color[0] for d in attribute.data), max(d.color[0] for d in attribute.data)


def textures_of(folder):
    """{slot name: texture key} from the model's materials.json (the Surface pass `texture` field)."""
    entries = json.loads((folder / "materials.json").read_text())
    return {e["name"]: e["texture"] for e in entries if e.get("texture")}


def tile_uvs(obj, mats, slot_textures, rows):
    """Scale the UVs of every face in a slot that names a texture by that texture's tiling (SurfaceAppearance has no tiling
    property; the repeat lives in the UVs). Returns how many faces were scaled."""
    layer = obj.data.uv_layers.active
    if layer is None or not slot_textures:
        return 0
    scaled = 0
    for poly in obj.data.polygons:
        key = slot_textures.get(mats[poly.material_index][0])
        if key is None:
            continue
        u, v = rows[key]["tiling"]
        for loop in poly.loop_indices:
            x, y = layer.data[loop].uv
            layer.data[loop].uv = (x * u, y * v)
        scaled += 1
    return scaled


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


def update_files(folder, sid, rec, tris, height, surface=None):
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
    if surface:
        grad = surface["gradient"]
        sline = ("- Surface pass %s: smooth by angle (%g degrees), a %g-stud bevel with %d segments on thick cubes and cylinders, a greyscale "
                 "vertex gradient exported in the GLB (crown %g, belly %g, %g more facing down); per-slot material, texture and glossy live in "
                 "materials.json (docs/vault/06-art-pipelines/Surface-Pass.md)." % (
                     datetime.date.today().isoformat(), surface["smooth_angle"], surface["bevel_width"], surface["bevel_segments"],
                     grad["crown"], grad["belly"], grad["down"]))
        if "- Surface pass" in notes:
            notes = re.sub(r"- Surface pass.*", lambda m: sline, notes)
        else:
            notes = notes.rstrip("\n") + "\n" + sline + "\n"
    (folder / "notes.md").write_text(notes)


def build(sid, models, surface=None):
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
    kit = Kit(mats, surface)
    for part in SR.expand(rec):
        kit.add(part)
    obj = kit.join(sid)
    used = {p.material_index for p in obj.data.polygons}
    if used != set(range(len(mats))):
        raise RuntimeError("unused slots: %s" % ", ".join(mats[i][0] for i in sorted(set(range(len(mats))) - used)))
    lo, hi, scale = fit(obj, rec["height"])
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris > SR.TRI_BUDGET:
        raise OverBudget("%d triangles is over the %d cap (nothing was exported)" % (tris, SR.TRI_BUDGET))
    extra = {}
    if surface:
        shade = paint_gradient(obj, mats, surface["gradient"])
        tiled = tile_uvs(obj, mats, textures_of(folder), luau_tables.load(str(TEXTURES)))
        extra = {"export_vertex_color": "ACTIVE"}
        build.report = "bevelled=%d gradient=%.2f..%.2f tiled=%d" % (kit.bevelled, shade[0], shade[1], tiled)
    else:
        build.report = "no surface"
    bpy.ops.export_scene.gltf(filepath=str(folder / ("%s.glb" % sid)), export_format="GLB", export_apply=True, export_animations=False,
                              export_yup=True, use_selection=False, export_materials="EXPORT", export_lights=False, export_cameras=False,
                              **extra)
    bpy.ops.export_scene.fbx(filepath=str(folder / ("%s.fbx" % sid)), use_selection=False, apply_scale_options="FBX_SCALE_ALL",
                             mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
    update_files(folder, sid, rec, tris, hi - lo, surface)
    return tris, lo, hi, scale, len(mats)


def main():
    args = parse_args()
    models = pathlib.Path(args.models)
    if not models.is_absolute():
        models = pathlib.Path.cwd() / models
    failed = []
    surface = None if args.no_surface else SR.SURFACE
    for sid in SR.ids_for(args.species):
        try:
            try:
                tris, lo, hi, scale, slots = build(sid, models, surface)
            except OverBudget:
                if not surface or not surface["bevel_segments"]:
                    raise
                # The bevel pushed it over the cap: build it again without the bevel (the smoothing and the gradient stay).
                tris, lo, hi, scale, slots = build(sid, models, dict(surface, bevel_segments=0))
                build.report += " (bevel dropped: over the cap with it)"
            guide = SR.TRI_GUIDE[SR.RECIPES[sid]["tier"]]
            print("%-11s tris=%d height=%.2f z=%.2f..%.2f fit=x%.3f slots=%d%s  [%s]" % (
                sid, tris, hi - lo, lo, hi, scale, slots, "  (over the %d target)" % guide if tris > guide else "", build.report), flush=True)
        except Exception as exc:  # noqa: BLE001
            failed.append(sid)
            print("%-11s FAILED: %s" % (sid, exc), flush=True)
    if failed:
        print("failed: %s" % ", ".join(failed))
        sys.exit(1)
    print("next: python3 tools/blender/preview.py --species %s" % args.species)


if __name__ == "__main__":
    main()
