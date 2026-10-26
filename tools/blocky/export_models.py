#!/usr/bin/env python3
"""Export the rebuilt block-cell aliens into assets/models (Decision B46, "Then finalize"; B27 still holds: nothing is uploaded or published).

For every creature note on the B46 format (tools/blocky/spec.py reports no "B45 pending" or "B46 pending"), this builds the alien with
tools/blender/blocky_build.py and writes assets/models/<Id>/:

  <Id>.glb, <Id>.fbx   1 unit = 1 stud, Y up, facing -Z (Roblox's front) with its right on +X, the pivot (origin) at the bottom centre of its
                       bounds. One mesh a MeshPart, one material each: `Body` (every static cell block merged, Decision B44's one atlas),
                       `Glow` (the static glow blocks, Neon in Studio), every moving object by its rig name with its origin on its pivot (the
                       names and pivots of src/shared/data/Rigs.luau), and `FacePlate` (the eyes, mouth and cheeks on their own sheet)
  <Id>_atlas.png       the block-cell atlas every cell face samples (nearest filtering; SurfaceAppearance ResampleMode Pixelated in Studio)
  <Id>_face.png        the face plate's flipbook: frames left to right, eyes.SHEET_COLUMNS a row (Rigs face.columns, RigMath.FrameOffset);
                       the plate's UVs show frame 0 (open)
  materials.json       one entry a MeshPart in GLB node order: slot, name, hex, roughness, metallic, emission (the schema the installer and
                       upload_assets.py --emit-luau already read; emission > 0 is Neon), plus `colorMap` (the PNG the part samples),
                       `pixelated` and, on the plate, `alphaMode`
  notes.md             tool, spec note, height, blocks, triangles, parts, eye key, frames
  <Id>.png, <Id>_grey.png   256 x 256 thumbnails like tools/blender/preview.py (front-left orthographic, flat colour, and the silhouette)

Modes:
  BPY=<python with bpy>
  $BPY tools/blocky/export_models.py --all                 # every note on B46; prints the pending notes it skipped
  $BPY tools/blocky/export_models.py --species Mossbop,Radish
  python3 -I tools/blocky/export_models.py --check         # no Blender: every exported folder against its note and Rigs.luau
  python3 -I tools/blocky/export_models.py --check --species Mossbop
  python3 -I tools/blocky/export_models.py --emit-luau     # the BLOCK_CELL table for tools/studio/install_models.luau
  $BPY tools/blocky/export_models.py --props [A,B]         # the props (docs/vault/07-alien-game/Props/, Decision B44) into assets/models/props
  python3 -I tools/blocky/export_models.py --check --props # every exported prop folder against its note (plain --check covers both)
  python3 -I tools/blocky/export_models.py --emit-luau --props   # the BLOCK_CELL_PROPS table for the installer

The prop route ("props" section below): one MeshPart per colour slot (Body, BodyDark, Accessory, Trim on the atlas; Glow Neon), static,
the pivot at the bottom centre, the front (the note's -Z) on +Z in the game, the atlas at most 1024 a side (8 texels a cell, or 4).

--check reads the GLB (header, JSON chunk and the binary chunk) and checks: every file present; the mesh nodes are exactly Body, Glow (when
the alien has static glow), the rig's moving parts and FacePlate, one primitive each, translation only; each moving part's node sits on its
Rigs.luau pivot; the bounds stand on y = 0 centred on x = z = 0, 2 to 3.5 studs tall and as tall as the Rigs row; the face plate looks
along -Z; triangles under the cap and as notes.md says; materials.json names the nodes in order; nearest samplers; the face sheet's size is
the Rigs row's layout. A species that is still pending is listed, not checked. Exit 1 on any problem, 2 on bad usage.

Files under the folder that the export does not write (an old blockout's leftovers) are deleted and printed. asset_ids.json is only marked:
an exported species that has an old upload gets `pendingUpload` (the new files, not uploaded); its old assetId stays until the Mac
uploads (Decision B47: tools/finalize_upload.sh runs `python3 -I tools/upload_assets.py --blocky`), so the game keeps its old mesh,
which World.RigAnimator leaves alone, until then. An upload that records its file's sha256 is never marked: the upload sends a
changed file again by its hash, and the game keeps the uploaded id until then.
"""
from __future__ import annotations

import argparse
import datetime
import json
import math
import pathlib
import shutil
import struct
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools"))
import eyes as E  # noqa: E402
import rigs as RG  # noqa: E402
import spec as S  # noqa: E402

CREATURES = ROOT / "docs/vault/07-alien-game/Creatures"
MODELS = ROOT / "assets/models"
RIGS_LUAU = ROOT / "src/shared/data/Rigs.luau"
IDS_FILE = MODELS / "asset_ids.json"
IMAGE_IDS_FILE = MODELS / "image_ids.json"   # the atlas and face sheet Decal and Image ids (upload_assets.py --blocky)
TOOL = "tools/blocky/export_models.py"

HEIGHT_BAND = (2.0, 3.5)        # Decision B45: every alien 2 to 3.5 studs
TRI_CAP = S.TRI_CAP             # the cap of a prop; an alien's is S.tri_cap(its tier) (B54: Epic 4,000, Legendary and up 6,000)
CELLS = "Body"                  # the merged static cell mesh
GLOW = "Glow"                   # the static glow blocks (Neon)
FACE = RG.FACE_PART             # "FacePlate"
CELL_ROUGH = 0.55               # blocky_build.ROUGH (SmoothPlastic)
PLATE_ROUGH = 0.4
GLOW_EMISSION = 1.5             # blocky_build.GLOW_BUILD: emission > 0 makes the installer pick Neon
TOL = 1e-3                      # studs, for pivots
TOL_CENTRE = 0.02               # studs, for the bottom centre: the rounded corners of a rest-posed bevelled mass sit up to 0.02 inside its sharp box (B54)
HEIGHT_TOL = 0.01               # studs, the exported height against the Rigs row
PLATE_PROUD = 1.0 / 64.0        # the face plate stands this far proud of the head (spec.face_plate); when it is the front-most point the
                                # bounds' centre moves half of it from the one rigs.centre_of measures the pivots from
PREVIEW = 256
NEAREST = 9728                  # glTF sampler magFilter
NEAREST_MIN = (9728, 9984)      # minFilter NEAREST or NEAREST_MIPMAP_NEAREST (what Blender writes for Closest)


def suffix_files(sid):
    """Every file the export writes into assets/models/<Id>/."""
    return [sid + ".glb", sid + ".fbx", sid + "_atlas.png", sid + "_face.png", "materials.json", "notes.md", sid + ".png", sid + "_grey.png"]


# ------------------------------------------------------------------------------------------------ the roster
def pending_reasons(spec):
    """The "B45 pending" and "B46 pending" warnings spec.py gives a note on the old format (empty on B46), or its errors."""
    errors, warnings = S.validate(spec)
    if errors:
        return ["spec error: " + e for e in errors]
    return [w for w in warnings if w.startswith("B45 pending") or w.startswith("B46 pending")]


def roster(only=None, folder=CREATURES):
    """([(sid, note path, spec)] ready to export, [(sid, reason)] skipped), in note order; `only` limits it to those ids."""
    ready, skipped = [], []
    for path in sorted(pathlib.Path(folder).glob("*.md")):
        spec = S.load(path)
        sid = spec["front"].get("id") or path.stem
        if only and sid not in only:
            continue
        reasons = pending_reasons(spec)
        if reasons or not S.is_b46(spec) or not spec.get("rig"):
            skipped.append((sid, reasons[0] if reasons else "no eyes or rig block"))
        else:
            ready.append((sid, path, spec))
    return ready, skipped


def luau_rigs(path=RIGS_LUAU):
    from luau_tables import load
    return load(str(path))["Species"]


# ------------------------------------------------------------------------------------------------ reading a GLB and a PNG (standard library)
def read_glb(path):
    """(the JSON document, the binary chunk) of a .glb."""
    data = pathlib.Path(path).read_bytes()
    magic, version, _ = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2:
        raise ValueError("not a glTF 2 binary")
    off, doc, binary = 12, None, b""
    while off < len(data):
        length, kind = struct.unpack_from("<I4s", data, off)
        chunk = data[off + 8:off + 8 + length]
        if kind == b"JSON":
            doc = json.loads(chunk)
        elif kind == b"BIN\x00":
            binary = chunk
        off += 8 + length
    if doc is None:
        raise ValueError("no JSON chunk")
    return doc, binary


_COMPONENTS = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
_WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def accessor(doc, binary, index):
    """The values of accessor `index` as a list of tuples."""
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    fmt = _COMPONENTS[acc["componentType"]]
    n = _WIDTH[acc["type"]]
    size = struct.calcsize("<" + fmt)
    stride = view.get("byteStride") or size * n
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    return [struct.unpack_from("<%d%s" % (n, fmt), binary, start + i * stride) for i in range(acc["count"])]


def mesh_nodes(doc):
    """[(node name, node, mesh)] for every node with a mesh, in node order."""
    out = []
    for node in doc.get("nodes", []):
        if "mesh" in node:
            out.append((node.get("name", ""), node, doc["meshes"][node["mesh"]]))
    return out


def png_size(path):
    data = pathlib.Path(path).read_bytes()[:24]
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", data[16:24])


def glb_summary(path):
    """What --check needs from a GLB: per mesh node its translation, primitive count, triangle count and (min, max) in model space, the
    face plate's normal, and the samplers' filters."""
    doc, binary = read_glb(path)
    nodes = []
    for name, node, mesh in mesh_nodes(doc):
        t = node.get("translation", [0.0, 0.0, 0.0])
        lo, hi, tris, normal = [math.inf] * 3, [-math.inf] * 3, 0, None
        for prim in mesh["primitives"]:
            pos = doc["accessors"][prim["attributes"]["POSITION"]]
            lo = [min(lo[k], pos["min"][k] + t[k]) for k in range(3)]
            hi = [max(hi[k], pos["max"][k] + t[k]) for k in range(3)]
            count = doc["accessors"][prim["indices"]]["count"] if "indices" in prim else pos["count"]
            tris += count // 3
            if name == FACE and normal is None:
                pts = accessor(doc, binary, prim["attributes"]["POSITION"])
                idx = [i[0] for i in accessor(doc, binary, prim["indices"])] if "indices" in prim else [0, 1, 2]
                a, b, c = (pts[idx[k]] for k in range(3))
                u = [b[k] - a[k] for k in range(3)]
                v = [c[k] - a[k] for k in range(3)]
                n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
                length = math.sqrt(sum(x * x for x in n)) or 1.0
                normal = [x / length for x in n]
        nodes.append({"name": name, "translation": list(t), "rotated": "rotation" in node or "scale" in node or "matrix" in node,
                      "primitives": len(mesh["primitives"]), "tris": tris, "lo": lo, "hi": hi, "normal": normal})
    samplers = [(s.get("magFilter"), s.get("minFilter")) for s in doc.get("samplers", [])]
    return {"nodes": nodes, "samplers": samplers, "images": len(doc.get("images", []))}


# ------------------------------------------------------------------------------------------------ the check
def expected_parts(spec, row):
    """(the required mesh names in no particular order, the optional ones): Body, every rig part, FacePlate; Glow when it has static glow."""
    parts = S.expand(spec["parts"])
    required = [CELLS] + [p["name"] for p in row["parts"]] + [FACE]
    optional = [GLOW] if any(p["slot"] == "Glow" and p["moves"] == "none" for p in parts) else []
    return required, optional


def notes_triangles(text):
    for line in text.splitlines():
        if line.startswith("- Triangles:"):
            try:
                return int(line.split(":", 1)[1].split()[0].rstrip(";,"))
            except ValueError:
                return None
    return None


def check_folder(folder, spec, row):
    """Problems (strings) with one exported folder against its note (spec) and its Rigs.luau row; [] when it is right."""
    folder = pathlib.Path(folder)
    sid = spec["front"]["id"]
    problems = []
    for name in suffix_files(sid):
        f = folder / name
        if not f.is_file() or f.stat().st_size == 0:
            problems.append("missing " + name)
    if problems:
        return problems
    if row is None:
        return ["no row in Rigs.luau"]
    try:
        g = glb_summary(folder / (sid + ".glb"))
    except (OSError, ValueError, KeyError, IndexError, struct.error) as exc:
        return ["unreadable GLB: %s" % exc]
    names = [n["name"] for n in g["nodes"]]
    required, optional = expected_parts(spec, row)
    for name in required:
        if name not in names:
            problems.append("no mesh named %s" % name)
    for name in names:
        if name not in required and name not in optional:
            problems.append("unexpected mesh %s (not Body, Glow, a Rigs.luau part or FacePlate)" % name)
    if len(set(names)) != len(names):
        problems.append("two meshes share a name")
    by = {n["name"]: n for n in g["nodes"]}
    for n in g["nodes"]:
        if n["primitives"] != 1:
            problems.append("%s has %d primitives (one material each, so one MeshPart each)" % (n["name"], n["primitives"]))
        if n["rotated"]:
            problems.append("%s carries a rotation or scale (translation only)" % n["name"])
    for part in row["parts"]:
        node = by.get(part["name"])
        if node and any(abs(node["translation"][k] - part["pivot"][k]) > TOL for k in range(3)):
            problems.append("%s sits at %s, Rigs.luau pivot %s" % (part["name"], _fmt(node["translation"]), _fmt(part["pivot"])))
    lo = [min(n["lo"][k] for n in g["nodes"]) for k in range(3)]
    hi = [max(n["hi"][k] for n in g["nodes"]) for k in range(3)]
    height = hi[1] - lo[1]
    if abs(lo[1]) > TOL:
        problems.append("the feet are at y = %.4f, not 0" % lo[1])
    if abs(lo[0] + hi[0]) / 2 > TOL_CENTRE or abs(lo[2] + hi[2]) / 2 > PLATE_PROUD / 2 + TOL_CENTRE:
        problems.append("the pivot is not the bottom centre (bounds centre x %.4f, z %.4f)" % ((lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2))
    if not HEIGHT_BAND[0] - TOL <= height <= HEIGHT_BAND[1] + TOL:
        problems.append("%.3f studs tall, outside %g to %g (B45)" % (height, *HEIGHT_BAND))
    if abs(height - row["height"]) > HEIGHT_TOL:
        problems.append("%.3f studs tall, Rigs.luau says %.3f" % (height, row["height"]))
    plate = by.get(FACE)
    if plate and (plate["normal"] is None or plate["normal"][2] > -0.85):   # a head turned up to 25 degrees (B54 rest pose) still looks -Z
        problems.append("the face plate does not look along -Z (normal %s)" % _fmt(plate["normal"] or []))
    tris = sum(n["tris"] for n in g["nodes"])
    cap = S.tri_cap(spec["front"].get("tier"))
    if tris > cap:
        problems.append("%d triangles, over the cap of %d" % (tris, cap))
    noted = notes_triangles((folder / "notes.md").read_text(encoding="utf-8"))
    if noted != tris:
        problems.append("notes.md says %s triangles, the GLB has %d" % (noted, tris))
    if not g["samplers"] or any(mag != NEAREST or minf not in NEAREST_MIN for mag, minf in g["samplers"]):
        problems.append("a texture sampler is not nearest (%s)" % g["samplers"])
    try:
        entries = json.loads((folder / "materials.json").read_text(encoding="utf-8"))
    except ValueError as exc:
        entries = []
        problems.append("materials.json unreadable: %s" % exc)
    if [e.get("name") for e in entries] != names:
        problems.append("materials.json names %s, the GLB's meshes are %s" % ([e.get("name") for e in entries], names))
    for i, e in enumerate(entries):
        for key in ("slot", "name", "hex", "roughness", "metallic", "emission"):
            if key not in e:
                problems.append("materials.json entry %d has no %s" % (i + 1, key))
        if e.get("slot") != i + 1:
            problems.append("materials.json entry %d is slot %s" % (i + 1, e.get("slot")))
        if "colorMap" in e and not (folder / e["colorMap"]).is_file():
            problems.append("materials.json %s names %s, which is not in the folder" % (e.get("name"), e["colorMap"]))
    face = row["face"]
    want = (face["columns"] * face["frameWidth"], math.ceil(face["frames"] / face["columns"]) * face["frameHeight"])
    try:
        got = png_size(folder / (sid + "_face.png"))
        if tuple(got) != want:
            problems.append("%s_face.png is %dx%d, the Rigs.luau layout wants %dx%d" % (sid, got[0], got[1], want[0], want[1]))
    except ValueError as exc:
        problems.append("%s_face.png: %s" % (sid, exc))
    return problems


def _fmt(v):
    return "[" + ", ".join("%.4f" % x for x in v) + "]"


def run_check(only=None, models=MODELS, creatures=CREATURES, rigs_path=RIGS_LUAU):
    ready, skipped = roster(only, creatures)
    rigs = luau_rigs(rigs_path)
    bad = 0
    for sid, _, spec in ready:
        problems = check_folder(pathlib.Path(models) / sid, spec, rigs.get(sid))
        computed = RG.row(spec)
        live = rigs.get(sid)
        if live is not None:
            if [p["name"] for p in live["parts"]] != [p["name"] for p in computed["parts"]] or abs(live["height"] - computed["height"]) > TOL:
                problems.append("Rigs.luau is stale for this note (python3 -I tools/blocky/rigs.py)")
        if problems:
            bad += 1
            print("%-12s FAIL" % sid)
            for p in problems:
                print("    " + p)
        else:
            print("%-12s ok" % sid)
    for sid, why in skipped:
        print("%-12s pending, not checked (%s)" % (sid, why.split(":")[0]))
    print("check: %d exported species, %d failed, %d pending" % (len(ready), bad, len(skipped)))
    return 1 if bad else 0


# ------------------------------------------------------------------------------------------------ the export (needs bpy)
def _bpy_modules():
    try:
        import bpy  # noqa: F401
    except ImportError:
        print("export_models: the export needs Blender's Python (bpy); --check runs without it")
        sys.exit(2)
    sys.path.insert(0, str(ROOT / "tools/blender"))
    import blocky_build as BB
    return BB


def _join(bpy, objs, name):
    """Join `objs` into one object named `name` (its mesh named the same)."""
    if len(objs) > 1:
        with bpy.context.temp_override(active_object=objs[0], object=objs[0], selected_objects=objs, selected_editable_objects=objs):
            bpy.ops.object.join()
    obj = objs[0]
    obj.name = name
    obj.data.name = name
    return obj


def _one_material(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.material_index = 0


def _glow_share(obj):
    """The share of the object's faces on a Glow-slot material."""
    mats = obj.data.materials
    polys = obj.data.polygons
    if not polys:
        return 0.0
    glow = sum(1 for p in polys if mats[p.material_index] is not None and "_Glow" in mats[p.material_index].name)
    return glow / len(polys)


def _flat_preview(bpy, scene, objs, png, grey):
    """preview.py's two thumbnails, from the textures: an orthographic front-left view, flat (each texel its own colour), and the silhouette."""
    sys.path.insert(0, str(ROOT / "tools/blender"))
    import preview as PV
    PV.SIZE = PREVIEW
    PV.setup_common(scene)
    PV.setup_camera(scene, objs)
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    scene.cycles.max_bounces = 1
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == "BACKGROUND"), None)
    if bg is not None:
        bg.inputs["Color"].default_value = (*PV.BACKGROUND, 1.0)
        bg.inputs["Strength"].default_value = 1.0
    for mat in {m for o in objs for m in o.data.materials if m is not None}:
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
        for link in list(bsdf.inputs["Base Color"].links) + list(bsdf.inputs["Emission Color"].links):
            nt.links.remove(link)
        bsdf.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
        if tex is not None:
            nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = 1.0
        bsdf.inputs["Metallic"].default_value = 0.0
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.0
    scene.render.filepath = str(png)
    bpy.ops.render.render(write_still=True)
    for mat in {m for o in objs for m in o.data.materials if m is not None}:
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        for link in list(bsdf.inputs["Emission Color"].links) + list(bsdf.inputs["Alpha"].links):
            nt.links.remove(link)
        bsdf.inputs["Alpha"].default_value = 1.0
        bsdf.inputs["Emission Color"].default_value = (*PV.SILHOUETTE, 1.0)
    scene.render.filepath = str(grey)
    bpy.ops.render.render(write_still=True)


def _hex(h):
    return str(h).lstrip("#").upper()


def mover_hex(spec, name):
    """A moving part's own colour (its largest block's slot), the MeshPart Color shown until its texture is uploaded."""
    pal = S.palette(spec)
    group = S.movers(S.expand(spec["parts"]))[name]["parts"]
    big = max(group, key=lambda p: p["size"][0] * p["size"][1] * p["size"][2])
    return pal.get(S.SLOT_ROLE[big["slot"]], pal["body"])


def export_one(sid, note, spec, models=MODELS, previews=True):
    """Build and write assets/models/<Id>/. Returns (summary dict, [deleted stale file names])."""
    BB = _bpy_modules()
    import bpy
    from mathutils import Matrix
    out = pathlib.Path(models) / sid
    out.mkdir(parents=True, exist_ok=True)
    row = RG.row(spec)
    pal = S.palette(spec)
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="export_%s_" % sid))
    try:
        scene = BB.reset()
        built = BB.build(spec, tmp)
        objs = {o.name: o for o in built["objects"]}
        atlas_png, face_png = tmp / ("%s_atlas.png" % sid), tmp / ("%s_face.png" % sid)
        atlas = next(i for i in bpy.data.images if i.name == "%s_atlas" % sid)
        cells_mat = BB.make_material("%s_Cells" % sid, pal["body"], "Body", atlas)
        glow_hex = pal.get("glow", pal["accent"] if "accent" in pal else pal["body"])
        glow_mat = BB.make_material("%s_Glow" % sid, glow_hex, "Glow", atlas, BB.GLOW_BUILD)
        mover_names = [p["name"] for p in row["parts"]]
        statics = [objs[k] for k in S.SLOTS if k in objs and k != GLOW]
        parts = []  # (object, kind, material)
        body = _join(bpy, statics, CELLS)
        _one_material(body, cells_mat)
        parts.append(body)
        if GLOW in objs:
            _one_material(objs[GLOW], glow_mat)
            objs[GLOW].data.name = GLOW
            parts.append(objs[GLOW])
        glow_movers = set()
        for name in mover_names:
            obj = objs.get(name)
            if obj is None:
                raise RuntimeError("%s: the build has no object %s (Rigs.luau names it)" % (sid, name))
            if _glow_share(obj) > 0.5:
                glow_movers.add(name)
            _one_material(obj, glow_mat if name in glow_movers else cells_mat)
            obj.data.name = name
            parts.append(obj)
        plate = objs[FACE]
        plate.data.name = FACE
        parts.append(plate)
        extra = {o.name for o in scene.objects if o.type == "MESH"} - {o.name for o in parts}
        if extra:
            raise RuntimeError("%s: unexpected objects %s" % (sid, sorted(extra)))
        # the pivot at the bottom centre of the bounds (rigs.centre_of: the same centre the Rigs pivots are measured from)
        c = RG.centre_of(spec)
        shift = BB.to_bl([c[0], 0.0, c[2]])
        for o in parts:
            o.location -= shift
            if o.name in (CELLS, GLOW):  # the static meshes keep their origin on the model's: bottom centre, translation 0
                o.data.transform(Matrix.Translation(o.location))
                o.location = (0.0, 0.0, 0.0)
        bpy.context.view_layer.update()
        for p in row["parts"]:
            got = BB.to_spec(objs[p["name"]].location)
            if any(abs(got[k] - p["pivot"][k]) > TOL for k in range(3)):
                raise RuntimeError("%s: %s's origin %s is not its Rigs pivot %s" % (sid, p["name"], list(got), p["pivot"]))
        # face -Z in Roblox: blocky_build faces -Y in Blender, which glTF and FBX (forward -Z, up Y) both write on +Z; half a turn about the
        # vertical, baked into the mesh data so every node carries a translation only, puts the face on -Z and the right side on +X
        turn = Matrix.Rotation(math.pi, 4, "Z")
        for o in parts:
            o.data.transform(turn)
            o.location = turn @ o.location
        bpy.context.view_layer.update()
        glb, fbx = out / (sid + ".glb"), out / (sid + ".fbx")
        bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_selection=False, export_yup=True, export_apply=True,
                                  export_materials="EXPORT", export_animations=False, export_lights=False, export_cameras=False)
        bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=False, object_types={"MESH"}, apply_scale_options="FBX_SCALE_ALL",
                                 mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="COPY", embed_textures=True)
        shutil.copyfile(atlas_png, out / (sid + "_atlas.png"))
        shutil.copyfile(face_png, out / (sid + "_face.png"))
        summary = glb_summary(glb)
        tris = sum(n["tris"] for n in summary["nodes"])
        entries = []
        for n in summary["nodes"]:
            name = n["name"]
            if name == FACE:
                host = S.face_host(spec)
                entry = {"hex": _hex(pal[S.SLOT_ROLE[host["slot"]]]), "roughness": PLATE_ROUGH, "metallic": 0.0, "emission": 0.0,
                         "colorMap": sid + "_face.png", "pixelated": True, "alphaMode": "Transparency"}
            elif name == GLOW or name in glow_movers:
                entry = {"hex": _hex(glow_hex), "roughness": CELL_ROUGH, "metallic": 0.0, "emission": GLOW_EMISSION}
            else:
                entry = {"hex": _hex(pal["body"] if name == CELLS else mover_hex(spec, name)), "roughness": CELL_ROUGH, "metallic": 0.0, "emission": 0.0,
                         "colorMap": sid + "_atlas.png", "pixelated": True}
            entries.append(dict({"slot": len(entries) + 1, "name": name}, **entry))
        (out / "materials.json").write_text(json.dumps(entries, indent=2) + "\n", encoding="utf-8")
        aw, ah = png_size(out / (sid + "_atlas.png"))
        info = {"sid": sid, "note": note, "spec": spec, "row": row, "tris": tris, "nodes": [n["name"] for n in summary["nodes"]],
                "glow_movers": sorted(glow_movers), "atlas": (aw, ah), "cell": built["cell"], "bpy": bpy.app.version_string,
                "glb": glb.stat().st_size, "fbx": fbx.stat().st_size}
        (out / "notes.md").write_text(notes_text(info), encoding="utf-8")
        if previews:
            # turned back to the build's -Y front, the view preview.py frames; the preview rewires the materials, after the files are out
            for o in parts:
                o.data.transform(turn)
                o.location = turn @ o.location
            bpy.context.view_layer.update()
            _flat_preview(bpy, scene, parts, out / (sid + ".png"), out / (sid + "_grey.png"))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    keep = set(suffix_files(sid))
    stale = sorted(f.name for f in out.iterdir() if f.is_file() and f.name not in keep)
    for name in stale:
        (out / name).unlink()
    return info, stale


def notes_text(info):
    spec, row, sid = info["spec"], info["row"], info["sid"]
    front = spec["front"]
    face = row["face"]
    names = E.frame_names(spec["eyes"]["key"])
    pivots = {p["name"]: p["pivot"] for p in row["parts"]}
    listed = []
    for name in info["nodes"]:
        if name == CELLS:
            listed.append("`Body` (every static block, the cell atlas)")
        elif name == GLOW:
            listed.append("`Glow` (the static glow blocks, Neon)")
        elif name == FACE:
            listed.append("`FacePlate` (the face sheet, frame 0)")
        else:
            kind = "Neon" if name in info["glow_movers"] else "cells"
            listed.append("`%s` (moves, %s, pivot %s)" % (name, kind, ", ".join(RG._num(v) for v in pivots[name])))
    note_rel = pathlib.Path(info["note"]).resolve().relative_to(ROOT).as_posix()
    lines = [
        "# %s block-cell model" % sid,
        "",
        "- Date: %s" % datetime.date.today().isoformat(),
        "- Tool: %s (tools/blender/blocky_build.py, bpy %s); Decision B46, \"Then finalize\". Not uploaded (B27): every texture and image id is 0" % (TOOL, info["bpy"]),
        "- Spec note: %s (%s, World %s, %s, status %s)" % (note_rel, front.get("name", sid), front.get("world", "?"), front.get("tier", "?"), front.get("status", "?")),
        "- Height: %s studs (1 unit = 1 stud); the origin is the bottom centre of the bounds; Y up, facing -Z (Roblox's front), its right on +X, in the GLB and the FBX alike" % RG._num(row["height"]),
        "- Blocks: %d" % S.counts(spec)["blocks"],
        "- Triangles: %d (cap %d)" % (info["tris"], S.tri_cap(front.get("tier"))),
        "- Cells: %s studs a cell, atlas %s_atlas.png %dx%d, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)" % (
            RG._num(info["cell"]), sid, info["atlas"][0], info["atlas"][1]),
        "- Parts (one MeshPart each, in GLB order, names as in src/shared/data/Rigs.luau): %s" % "; ".join(listed),
        "- Eyes: `%s`; the face plate is %dx%d px a frame, %d frames (%s) in %s_face.png, %d a row (Rigs face.columns)" % (
            spec["eyes"]["key"], face["frameWidth"], face["frameHeight"], face["frames"], ", ".join(names), sid, face["columns"]),
        "- Rig: %d moving parts, root clips %d, flourish %s; played by World.RigAnimator from Rigs.luau (the blink squashes the plate until the face sheet is uploaded)" % (
            len(row["parts"]), len(row["root"]), "every %ss" % RG._num(row["flourish"]["every"]) if row["flourish"] else "none"),
        "- Files: %s.glb (%d bytes), %s.fbx (%d bytes, texture embedded), %s_atlas.png, %s_face.png, materials.json, %s.png and %s_grey.png (256 px previews)" % (
            sid, info["glb"], sid, info["fbx"], sid, sid, sid, sid),
        "- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected; or the upload route. See .claude/skills/import-model",
        "",
        "Regenerate with `$BPY tools/blocky/export_models.py --species %s`; check with `python3 -I tools/blocky/export_models.py --check --species %s`." % (sid, sid),
        "",
    ]
    return "\n".join(lines)


def mark_pending(sids, ids_file=IDS_FILE):
    """asset_ids.json: an exported species with an old upload gets `pendingUpload` (the new files, not uploaded). No id is invented or removed."""
    if not ids_file.exists():
        return []
    ids = json.loads(ids_file.read_text(encoding="utf-8"))
    marked = []
    for sid in sids:
        entry = ids.get(sid)
        # an upload that records its file's sha256 needs no mark: upload_assets.py --blocky sends a changed file again by its hash, and
        # the game keeps the uploaded id (ModelAssets, the installer) until then, where a mark would zero it at the next fill
        if not isinstance(entry, dict) or entry.get("sha256"):
            continue
        entry["pendingUpload"] = {
            "files": ["assets/models/%s/%s" % (sid, f) for f in (sid + ".glb", sid + "_atlas.png", sid + "_face.png")],
            "exportedAt": datetime.date.today().isoformat(),
            "uploaded": False,
            "note": "block-cell export (B46); assetId is still the old blockout until `upload_assets.py --redo --only %s`" % sid,
        }
        marked.append(sid)
    tmp = ids_file.with_name(ids_file.name + ".tmp")
    tmp.write_text(json.dumps(ids, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(ids_file)
    return marked


def run_export(only=None, previews=True):
    ready, skipped = roster(only)
    if only:
        unknown = sorted(set(only) - {s for s, _, _ in ready} - {s for s, _ in skipped})
        if unknown:
            print("export_models: no note for %s" % ", ".join(unknown))
            return 2
    rigs = luau_rigs()
    done, deleted, failed = [], [], []
    for sid, note, spec in ready:
        if sid not in rigs:
            failed.append(sid)
            print("%-12s FAIL no row in Rigs.luau (python3 -I tools/blocky/rigs.py)" % sid, flush=True)
            continue
        info, stale = export_one(sid, note, spec, previews=previews)
        problems = check_folder(MODELS / sid, spec, rigs[sid])
        deleted += ["%s/%s" % (sid, s) for s in stale]
        if problems:
            failed.append(sid)
            print("%-12s FAIL %s" % (sid, "; ".join(problems)), flush=True)
        else:
            done.append(sid)
            print("%-12s ok  %d tris, %s, %s tall%s" % (sid, info["tris"], ", ".join(info["nodes"]), RG._num(info["row"]["height"]),
                                                      ("; deleted " + ", ".join(stale)) if stale else ""), flush=True)
    marked = mark_pending(done)
    for sid, why in skipped:
        print("%-12s skipped: %s" % (sid, why), flush=True)
    print("export: %d exported, %d failed, %d skipped (pending); %d marked pendingUpload in asset_ids.json; stale files deleted: %s" % (
        len(done), len(failed), len(skipped), len(marked), ", ".join(deleted) or "none"), flush=True)
    return 1 if failed else 0


def _image_id(entry):
    value = entry.get("imageId") if isinstance(entry, dict) else None
    return value if isinstance(value, int) and not isinstance(value, bool) and value > 0 else 0


def emit_luau(models=MODELS, ids_file=IDS_FILE, image_ids_file=IMAGE_IDS_FILE):
    """The BLOCK_CELL table for tools/studio/install_models.luau (between its BLOCK-CELL PASTE markers), from every exported folder's
    materials.json: per species its new Model asset id (0 until upload_assets.py --blocky records the block-cell upload in asset_ids.json:
    `blockCell` true and no `pendingUpload`, so the installer never loads the old blockout), the Image ids of the cell atlas and the face
    sheet (assets/models/image_ids.json "<Id>/atlas" and "<Id>/face", 0 until uploaded and resolved), and its parts in GLB order with the
    colour, Neon and the map each samples. upload_assets.py --fill-blocky pastes it."""
    ids = json.loads(pathlib.Path(ids_file).read_text(encoding="utf-8")) if pathlib.Path(ids_file).exists() else {}
    images = json.loads(pathlib.Path(image_ids_file).read_text(encoding="utf-8")) if pathlib.Path(image_ids_file).exists() else {}
    lines = ["local BLOCK_CELL: { [string]: BlockCellRow } = {"]
    for folder in sorted(p for p in pathlib.Path(models).iterdir() if p.is_dir()):
        sid = folder.name
        if not (folder / (sid + "_atlas.png")).exists():
            continue
        entry = ids.get(sid) if isinstance(ids.get(sid), dict) else {}
        uploaded = entry.get("blockCell") is True and "pendingUpload" not in entry
        asset = int(entry.get("assetId", 0)) if uploaded else 0
        lines.append("\t%s = {" % sid)
        lines.append("\t\tassetId = %d, cellMap = %d, faceMap = %d," % (
            asset, _image_id(images.get(sid + "/atlas")), _image_id(images.get(sid + "/face"))))
        lines.append("\t\tparts = {")
        for e in json.loads((folder / "materials.json").read_text(encoding="utf-8")):
            neon = e.get("emission", 0) > 0
            kind = "" if neon else ("face" if e.get("colorMap") == sid + "_face.png" else "cell")
            lines.append('\t\t\t{ name = "%s", hex = "%s", neon = %s, map = "%s" },' % (e["name"], e["hex"], "true" if neon else "false", kind))
        lines.append("\t\t},")
        lines.append("\t},")
    lines.append("}")
    return "\n".join(lines)


# ------------------------------------------------------------------------------------------------ props (the --props route)
# A prop note (docs/vault/07-alien-game/Props/<Name>.md, `kind: prop`) whose frontmatter `glb` names assets/models/props/<Name>/<Name>.glb
# is exported into that folder in the block-cell format: one MeshPart per colour slot the note uses (Body, BodyDark, Accessory, Trim on the
# atlas; Glow Neon), static, the pivot at the bottom centre, the front (the note's -Z) on +Z in the game (the landmark contract of
# data/Layouts.luau: "a model's front is +Z as exported"), at the world cell (0.25 studs). The older notes (Tree, Rock, ... used only by the
# dioramas) have no such glb and are left alone.
PROP_NOTES = ROOT / "docs/vault/07-alien-game/Props"
PROP_MODELS = MODELS / "props"
PROP_SLOTS = ("Body", "BodyDark", "Accessory", "Trim", "Glow")   # spec.SLOTS without Eye, in GLB order
PROP_ATLAS_MAX = 1024     # Roblox scales an uploaded image down to 1024 a side, so a prop's atlas is made to fit
PROP_PX = (8, 4)          # texels a cell: 8 like the creatures, 4 for a landmark whose surface would not fit 1024 at 8
PROP_TOL = 0.011          # studs: the exported bounds against the note's height and footprint
PROP_COLLISIONS = ("Box", "Hull", "Precise", "None")


def prop_files(pid):
    """Every file the --props export writes into assets/models/props/<Name>/."""
    return [pid + ".glb", pid + ".fbx", pid + "_atlas.png", "materials.json", "notes.md", pid + ".png", pid + "_grey.png"]


def prop_roster(only=None, folder=PROP_NOTES):
    """([(pid, note path, spec)] of every prop note that exports into assets/models/props, [(pid, reason)] with spec errors), in note order."""
    ready, skipped = [], []
    for path in sorted(pathlib.Path(folder).glob("*.md")):
        spec = S.load(path)
        front = spec["front"]
        pid = front.get("id") or path.stem
        if not S.is_prop(spec) or not str(front.get("glb", "")).startswith("assets/models/props/"):
            continue
        if only and pid not in only:
            continue
        errors, _ = S.validate(spec)
        if errors:
            skipped.append((pid, "spec error: " + errors[0]))
        else:
            ready.append((pid, path, spec))
    return ready, skipped


def prop_slots(spec):
    """The slots the note's parts use, in PROP_SLOTS order: the MeshParts the export makes."""
    used = {p["slot"] for p in S.expand(spec["parts"])}
    return [s for s in PROP_SLOTS if s in used]


def prop_px(spec):
    """Texels a cell for this prop: the first of PROP_PX whose packed atlas fits PROP_ATLAS_MAX a side (cells.pack, as the build packs it)."""
    import cells as C
    parts = S.expand(spec["parts"])
    for px in PROP_PX:
        isl = C.islands(parts, C.WORLD_CELL, statics=[p for p in parts if p["moves"] == "none"])
        w, h = C.pack(isl, px)
        if w <= PROP_ATLAS_MAX and h <= PROP_ATLAS_MAX:
            return px
    raise ValueError("%s: the atlas does not fit %d at %d texels a cell" % (spec["front"]["id"], PROP_ATLAS_MAX, PROP_PX[-1]))


def prop_footprint(spec):
    """[W, D, H] of the prop's bounds in studs (H from its lowest point: a floating sign arm is as tall as its board)."""
    c = S.counts(spec)
    return [c["width"], c["depth"], round(c["height"] - c["bottom"], 3)]


def check_prop_folder(folder, spec):
    """Problems (strings) with one exported prop folder against its note; [] when it is right."""
    folder = pathlib.Path(folder)
    front = spec["front"]
    pid = front["id"]
    problems = []
    for name in prop_files(pid):
        f = folder / name
        if not f.is_file() or f.stat().st_size == 0:
            problems.append("missing " + name)
    if problems:
        return problems
    try:
        g = glb_summary(folder / (pid + ".glb"))
    except (OSError, ValueError, KeyError, IndexError, struct.error) as exc:
        return ["unreadable GLB: %s" % exc]
    names = [n["name"] for n in g["nodes"]]
    want = prop_slots(spec)
    if names != want:
        problems.append("the meshes are %s; the note's slots make %s" % (names, want))
    for n in g["nodes"]:
        if n["primitives"] != 1:
            problems.append("%s has %d primitives (one material each, so one MeshPart each)" % (n["name"], n["primitives"]))
        if n["rotated"] or any(abs(t) > TOL for t in n["translation"]):
            problems.append("%s is moved, turned or scaled (a static prop's meshes sit at the origin)" % n["name"])
    lo = [min(n["lo"][k] for n in g["nodes"]) for k in range(3)]
    hi = [max(n["hi"][k] for n in g["nodes"]) for k in range(3)]
    if abs(lo[1]) > TOL:
        problems.append("the prop stands at y = %.4f, not 0" % lo[1])
    if abs(lo[0] + hi[0]) / 2 > TOL or abs(lo[2] + hi[2]) / 2 > TOL:
        problems.append("the pivot is not the bottom centre (bounds centre x %.4f, z %.4f)" % ((lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2))
    size = [hi[0] - lo[0], hi[2] - lo[2], hi[1] - lo[1]]
    foot = prop_footprint(spec)
    if any(abs(size[k] - foot[k]) > PROP_TOL for k in range(3)):
        problems.append("the bounds are %s (W x D x H), the note's parts make %s" % (_fmt(size), _fmt(foot)))
    if isinstance(front.get("height"), (int, float)) and abs(size[2] - front["height"]) > PROP_TOL:
        problems.append("%.3f studs tall, the note says %s" % (size[2], front["height"]))
    tris = sum(n["tris"] for n in g["nodes"])
    budget = front.get("budget")
    if not isinstance(budget, int) or budget <= 0:
        problems.append("the note has no triangle budget")
    elif tris > budget:
        problems.append("%d triangles, over the note's budget of %d" % (tris, budget))
    if front.get("collision") not in PROP_COLLISIONS:
        problems.append("the note's collision %r is not one of %s" % (front.get("collision"), ", ".join(PROP_COLLISIONS)))
    noted = notes_triangles((folder / "notes.md").read_text(encoding="utf-8"))
    if noted != tris:
        problems.append("notes.md says %s triangles, the GLB has %d" % (noted, tris))
    textured = [n for n in names if n != GLOW]
    if textured and (not g["samplers"] or any(mag != NEAREST or minf not in NEAREST_MIN for mag, minf in g["samplers"])):
        problems.append("a texture sampler is not nearest (%s)" % g["samplers"])
    try:
        aw, ah = png_size(folder / (pid + "_atlas.png"))
        if aw > PROP_ATLAS_MAX or ah > PROP_ATLAS_MAX:
            problems.append("the atlas is %dx%d, over %d a side (Roblox would scale it down)" % (aw, ah, PROP_ATLAS_MAX))
    except ValueError as exc:
        problems.append("%s_atlas.png: %s" % (pid, exc))
    try:
        entries = json.loads((folder / "materials.json").read_text(encoding="utf-8"))
    except ValueError as exc:
        entries = []
        problems.append("materials.json unreadable: %s" % exc)
    if [e.get("name") for e in entries] != names:
        problems.append("materials.json names %s, the GLB's meshes are %s" % ([e.get("name") for e in entries], names))
    pal = S.palette(spec)
    for i, e in enumerate(entries):
        for key in ("slot", "name", "hex", "roughness", "metallic", "emission"):
            if key not in e:
                problems.append("materials.json entry %d has no %s" % (i + 1, key))
        if e.get("slot") != i + 1:
            problems.append("materials.json entry %d is slot %s" % (i + 1, e.get("slot")))
        role = S.SLOT_ROLE.get(e.get("name"))
        if role and _hex(pal.get(role, "")) != e.get("hex"):
            problems.append("materials.json %s is %s, the note's %s is %s" % (e.get("name"), e.get("hex"), role, _hex(pal.get(role, ""))))
        if (e.get("emission", 0) > 0) != (e.get("name") == GLOW):
            problems.append("materials.json %s: only Glow is emissive (Neon)" % e.get("name"))
        if "colorMap" in e and not (folder / e["colorMap"]).is_file():
            problems.append("materials.json %s names %s, which is not in the folder" % (e.get("name"), e["colorMap"]))
    return problems


def run_prop_check(only=None, models=PROP_MODELS, notes=PROP_NOTES):
    ready, skipped = prop_roster(only, notes)
    bad = 0
    for pid, _, spec in ready:
        problems = check_prop_folder(pathlib.Path(models) / pid, spec)
        if problems:
            bad += 1
            print("%-18s FAIL" % pid)
            for p in problems:
                print("    " + p)
        else:
            print("%-18s ok" % pid)
    for pid, why in skipped:
        bad += 1
        print("%-18s FAIL %s" % (pid, why))
    print("check: %d exported props, %d failed" % (len(ready), bad))
    return 1 if bad else 0


def export_prop(pid, note, spec, models=PROP_MODELS, previews=True):
    """Build and write assets/models/props/<Name>/. Returns (summary dict, [deleted stale file names])."""
    BB = _bpy_modules()
    import bpy
    from mathutils import Matrix
    import cells as C
    out = pathlib.Path(models) / pid
    out.mkdir(parents=True, exist_ok=True)
    pal = S.palette(spec)
    px = prop_px(spec)
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="export_%s_" % pid))
    try:
        scene = BB.reset()
        built = BB.build(spec, tmp, cell=C.WORLD_CELL, px=px)
        objs = {o.name: o for o in built["objects"]}
        atlas_png = tmp / ("%s_atlas.png" % pid)
        atlas = next(i for i in bpy.data.images if i.name == "%s_atlas" % pid)
        extra = set(objs) - set(PROP_SLOTS)
        if extra:
            raise RuntimeError("%s: objects %s are not colour slots (a prop has no moving parts)" % (pid, sorted(extra)))
        parts = []
        for slot in PROP_SLOTS:
            obj = objs.get(slot)
            if obj is None:
                continue
            mat = BB.make_material("%s_%s" % (pid, slot), pal[S.SLOT_ROLE[slot]], slot, atlas, BB.GLOW_BUILD if slot == GLOW else None)
            # one material a MeshPart: the build's per-material copies (a slot with two cell materials) share the one atlas anyway
            _one_material(obj, mat)
            obj.data.name = slot
            parts.append(obj)
        # the pivot at the bottom centre of the bounds, baked into the meshes so every node sits at the origin (a prop with an `origin`,
        # a floating sign arm, is lowered onto y = 0 too: data/Props `origin` puts its layout point back)
        lo, hi = S.bounds(S.expand(spec["parts"]))
        shift = BB.to_bl([(lo[0] + hi[0]) / 2, lo[1], (lo[2] + hi[2]) / 2])
        for o in parts:
            o.data.transform(Matrix.Translation(o.location - shift))
            o.location = (0.0, 0.0, 0.0)
        bpy.context.view_layer.update()
        glb, fbx = out / (pid + ".glb"), out / (pid + ".fbx")
        bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_selection=False, export_yup=True, export_apply=True,
                                  export_materials="EXPORT", export_animations=False, export_lights=False, export_cameras=False)
        bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=False, object_types={"MESH"}, apply_scale_options="FBX_SCALE_ALL",
                                 mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="COPY", embed_textures=True)
        shutil.copyfile(atlas_png, out / (pid + "_atlas.png"))
        summary = glb_summary(glb)
        tris = sum(n["tris"] for n in summary["nodes"])
        entries = []
        for n in summary["nodes"]:
            slot = n["name"]
            hexcol = _hex(pal[S.SLOT_ROLE[slot]])
            if slot == GLOW:
                entry = {"hex": hexcol, "roughness": CELL_ROUGH, "metallic": 0.0, "emission": GLOW_EMISSION}
            else:
                entry = {"hex": hexcol, "roughness": CELL_ROUGH, "metallic": 0.0, "emission": 0.0, "colorMap": pid + "_atlas.png", "pixelated": True}
            entries.append(dict({"slot": len(entries) + 1, "name": slot}, **entry))
        (out / "materials.json").write_text(json.dumps(entries, indent=2) + "\n", encoding="utf-8")
        aw, ah = png_size(out / (pid + "_atlas.png"))
        info = {"pid": pid, "note": note, "spec": spec, "tris": tris, "nodes": [n["name"] for n in summary["nodes"]], "atlas": (aw, ah), "px": px,
                "bpy": bpy.app.version_string, "glb": glb.stat().st_size, "fbx": fbx.stat().st_size}
        (out / "notes.md").write_text(prop_notes_text(info), encoding="utf-8")
        if previews:
            _flat_preview(bpy, scene, parts, out / (pid + ".png"), out / (pid + "_grey.png"))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    keep = set(prop_files(pid))
    stale = sorted(f.name for f in out.iterdir() if f.is_file() and f.name not in keep)
    for name in stale:
        (out / name).unlink()
    return info, stale


def prop_notes_text(info):
    spec, pid = info["spec"], info["pid"]
    front = spec["front"]
    foot = prop_footprint(spec)
    note_rel = pathlib.Path(info["note"]).resolve().relative_to(ROOT).as_posix()
    kinds = {"Body": "cells", "BodyDark": "cells", "Accessory": "cells", "Trim": "cells", "Glow": "Neon, no map"}
    lines = [
        "# %s block-cell prop" % pid,
        "",
        "- Date: %s" % datetime.date.today().isoformat(),
        "- Tool: %s --props (tools/blender/blocky_build.py, bpy %s); Decision B44. Not uploaded (B27): every texture and image id is 0" % (TOOL, info["bpy"]),
        "- Spec note: %s (%s, World %s, status %s)" % (note_rel, front.get("name", pid), front.get("world", "?"), front.get("status", "?")),
        "- Footprint (W x D x H, studs): %s x %s x %s; the origin is the bottom centre of the bounds; Y up, the front on +Z (the landmark contract of data/Layouts.luau), in the GLB and the FBX alike" % tuple(RG._num(v) for v in foot),
        "- Blocks: %d" % S.counts(spec)["blocks"],
        "- Triangles: %d (budget %s)" % (info["tris"], front.get("budget")),
        "- Collision: %s (src/shared/data/Props.luau)" % front.get("collision"),
    ] + (["- Origin: the layout places the note's (0, 0, 0), %s studs from the bottom centre in the note's axes (data/Props `origin`)" % (
        ", ".join(RG._num(v) for v in front["origin"]))] if front.get("origin") is not None else []) + [
        "- Cells: 0.25 studs a cell (the world cell), %d texels a cell, atlas %s_atlas.png %dx%d, nearest filtering (in Studio a SurfaceAppearance ColorMap with ResampleMode Pixelated)" % (
            info["px"], pid, info["atlas"][0], info["atlas"][1]),
        "- Parts (one MeshPart a colour slot, in GLB order): %s" % "; ".join("`%s` (%s)" % (n, kinds[n]) for n in info["nodes"]),
        "- Files: %s.glb (%d bytes), %s.fbx (%d bytes, texture embedded), %s_atlas.png, materials.json, %s.png and %s_grey.png (256 px previews)" % (
            pid, info["glb"], pid, info["fbx"], pid, pid, pid),
        "- Studio: File > Import 3D (the FBX or the GLB, scale 1), then tools/studio/install_models.luau with the model selected (BLOCK_CELL_PROPS); or the upload route",
        "",
        "Regenerate with `$BPY tools/blocky/export_models.py --props %s`; check with `python3 -I tools/blocky/export_models.py --check --props %s`." % (pid, pid),
        "",
    ]
    return "\n".join(lines)


def mark_pending_props(pids, ids_file=IDS_FILE):
    """asset_ids.json: an exported prop with an old upload gets `pendingUpload` (the new files, not uploaded), as mark_pending does for species."""
    if not ids_file.exists():
        return []
    ids = json.loads(ids_file.read_text(encoding="utf-8"))
    marked = []
    for pid in pids:
        entry = ids.get(pid)
        if not isinstance(entry, dict) or entry.get("sha256"):   # re-uploaded by its hash (mark_pending)
            continue
        entry["pendingUpload"] = {
            "files": ["assets/models/props/%s/%s" % (pid, f) for f in (pid + ".glb", pid + "_atlas.png")],
            "exportedAt": datetime.date.today().isoformat(),
            "uploaded": False,
            "note": "block-cell prop export (B44); assetId is still the old blockout until `upload_assets.py --redo --only %s`" % pid,
        }
        marked.append(pid)
    tmp = ids_file.with_name(ids_file.name + ".tmp")
    tmp.write_text(json.dumps(ids, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(ids_file)
    return marked


def run_prop_export(only=None, previews=True):
    ready, skipped = prop_roster(only)
    if only:
        unknown = sorted(set(only) - {p for p, _, _ in ready} - {p for p, _ in skipped})
        if unknown:
            print("export_models: no exportable prop note for %s" % ", ".join(unknown))
            return 2
    done, deleted, failed = [], [], []
    for pid, note, spec in ready:
        info, stale = export_prop(pid, note, spec, previews=previews)
        problems = check_prop_folder(PROP_MODELS / pid, spec)
        deleted += ["%s/%s" % (pid, s) for s in stale]
        if problems:
            failed.append(pid)
            print("%-18s FAIL %s" % (pid, "; ".join(problems)), flush=True)
        else:
            done.append(pid)
            print("%-18s ok  %d tris (budget %s), %s, atlas %dx%d at %d px%s" % (
                pid, info["tris"], spec["front"]["budget"], ", ".join(info["nodes"]), info["atlas"][0], info["atlas"][1], info["px"],
                ("; deleted " + ", ".join(stale)) if stale else ""), flush=True)
    marked = mark_pending_props(done)
    for pid, why in skipped:
        failed.append(pid)
        print("%-18s FAIL %s" % (pid, why), flush=True)
    print("export: %d props exported, %d failed; %d marked pendingUpload in asset_ids.json; stale files deleted: %s" % (
        len(done), len(failed), len(marked), ", ".join(deleted) or "none"), flush=True)
    return 1 if failed else 0


def emit_luau_props(models=PROP_MODELS, ids_file=IDS_FILE, image_ids_file=IMAGE_IDS_FILE):
    """The BLOCK_CELL_PROPS table for tools/studio/install_models.luau (between its BLOCK-CELL PROPS PASTE markers): per block-cell prop its
    new Model asset id (0 while asset_ids.json marks it pendingUpload or it was never uploaded), the atlas Image id (assets/models/image_ids.json
    "<Name>/atlas", 0 until uploaded and resolved) and its MeshParts in GLB order with the colour, Neon and the map each samples. The face map
    does not apply (a prop has no face). upload_assets.py --fill-blocky pastes it."""
    ids = json.loads(pathlib.Path(ids_file).read_text(encoding="utf-8")) if pathlib.Path(ids_file).exists() else {}
    images = json.loads(pathlib.Path(image_ids_file).read_text(encoding="utf-8")) if pathlib.Path(image_ids_file).exists() else {}
    lines = ["local BLOCK_CELL_PROPS: { [string]: BlockCellRow } = {"]
    for folder in sorted(p for p in pathlib.Path(models).iterdir() if p.is_dir()):
        pid = folder.name
        if not (folder / (pid + "_atlas.png")).exists():
            continue
        entry = ids.get(pid) if isinstance(ids.get(pid), dict) else {}
        asset = int(entry.get("assetId", 0)) if entry and "pendingUpload" not in entry else 0
        lines.append("\t%s = {" % pid)
        lines.append("\t\tassetId = %d, cellMap = %d, faceMap = 0," % (asset, _image_id(images.get(pid + "/atlas"))))
        lines.append("\t\tparts = {")
        for e in json.loads((folder / "materials.json").read_text(encoding="utf-8")):
            neon = e.get("emission", 0) > 0
            lines.append('\t\t\t{ name = "%s", hex = "%s", neon = %s, map = "%s" },' % (e["name"], e["hex"], "true" if neon else "false", "" if neon else "cell"))
        lines.append("\t\t},")
        lines.append("\t},")
    lines.append("}")
    return "\n".join(lines)


def main(argv=None):
    if argv is None:
        argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--all", action="store_true", help="every note on the B46 format")
    ap.add_argument("--species", default="", help="comma list of species ids")
    ap.add_argument("--props", nargs="?", const="*", default=None,
                    help="the prop route: every exportable prop note, or a comma list of prop names (with --check or --emit-luau: props only)")
    ap.add_argument("--check", action="store_true", help="verify the exported folders, species and props (no Blender needed)")
    ap.add_argument("--emit-luau", action="store_true", help="print the BLOCK_CELL table (with --props, BLOCK_CELL_PROPS) for tools/studio/install_models.luau")
    ap.add_argument("--no-previews", action="store_true", help="skip the two 256 px renders (they must exist for --check)")
    a = ap.parse_args(argv)
    only = {s.strip() for s in a.species.split(",") if s.strip()} or None
    props_only = None if a.props in (None, "*") else ({s.strip() for s in a.props.split(",") if s.strip()} or None)
    if a.emit_luau:
        print(emit_luau_props() if a.props is not None else emit_luau())
        return 0
    if a.check:
        if a.props is not None:
            return run_prop_check(props_only)
        code = run_check(only)
        return max(code, run_prop_check()) if only is None else code
    if a.props is not None:
        return run_prop_export(props_only, previews=not a.no_previews)
    if not a.all and not only:
        ap.error("pass --all, --species A,B, --props [A,B] or --check")
    return run_export(only, previews=not a.no_previews)


if __name__ == "__main__":
    sys.exit(main())
