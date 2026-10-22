#!/usr/bin/env python3
"""Build a blocky creature from its spec note in headless Blender (bpy 5.0), export a GLB, render the review views and score the silhouettes.

The step "Build" of docs/vault/06-art-pipelines/Blocky-Style.md. It reads the same note as the concept sheet (tools/blocky/spec.py parses it,
tools/blocky/sheet.py frames the views), so the board and the model come from one table:

  * every part is made from the unit shape the sheet draws (box, wedge, cone6, ico1), scaled, rotated and placed in studs (1 Blender unit = 1
    stud, no object scale); a bevelled mass is a box with the note's one bevel width and segments, and only masses are bevelled
  * mirrored parts come from spec.expand; static parts are merged into one mesh per slot (Body, BodyDark, Accessory, Trim, Glow); each moving
    part (spec.movers: a halo, a wing, an ear ...) stays its own object with its origin on its pivot, for the game's tweens (Decision B39)
  * every face of every block is box-projected onto the creature's one block-cell atlas (tools/blocky/cells.py, Decision B44): square cells
    of the face's size on every block, a shade off the slot colour, darker at block edges, a motif per part `material`, the face drawn cell
    for cell on the head's front; nearest filtering (the twin of ResampleMode Pixelated); faces hidden under another static block are culled.
    --flat paints the same atlas in flat slot colours (the look before cells)
  * the GLB goes to --out (a scratch folder; never assets/models), faces -Y in Blender like every model in the repo, so the glTF is +Y up

Renders (Cycles on the CPU): the four orthographic views in the sheet's frames (alpha masks; overlap with the sheet's masks is printed and written
back), a lit three-quarter view, and for Rare and up a VFX preview (emissive glow regions; spark cubes and an arc kept on the body for Epic;
orbiting cubes and a ground ring from Legendary; a light column for Cosmic). The preview is labelled as one: the in-game effects come from
src/shared/data/Effects.luau.

  BPY=<python with bpy>
  $BPY tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Mossbop.md --sheet <sheet dir> --out <scratch dir> [--write]
  $BPY tools/blender/blocky_build.py --lineup Mossbop.md,Thunderhog.md,Radish.md --out <scratch dir>     # all to scale beside a 5-stud avatar

--sheet is where sheet.py wrote <Id>_mask_<view>.png (it is drawn first when missing). --write puts blocks, the measured triangles and the
overlaps into the note's frontmatter. --samples, --size and --skip (ortho,tq,vfx) trim the renders; --suffix names the outputs
(<Id>_tq<suffix>.png, for example _cells); --flat renders without cells.
"""
from __future__ import annotations

import argparse
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools/blocky"))

import bpy  # noqa: E402  (first: bmesh and mathutils come with it)
import bmesh  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import cells as C  # noqa: E402
import eyes as E  # noqa: E402
import raster  # noqa: E402
import rigs as RG  # noqa: E402
import sheet as SH  # noqa: E402
import spec as S  # noqa: E402

ROUGH = 0.55          # SmoothPlastic
TRIM_ROUGH, TRIM_METAL = 0.3, 0.6
GLOW_BUILD = 1.5      # emission strength in the GLB and the lit view (Neon in Studio)
GLOW_VFX = 4.0        # in the VFX preview (rendered with AgX, so the element colour holds instead of clipping to white)
TIER_HEX = SH.TIER_HEX


def to_bl(v):
    """Spec space (x right of the creature, y up, z back; it faces -Z) to Blender (faces -Y, Z up): a proper rotation, so windings hold."""
    return Vector((-v[0], v[2], v[1]))


def lin(hexcol, alpha=1.0):
    r, g, b = S.hex_rgb(hexcol)

    def f(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), alpha)


# ------------------------------------------------------------------------------------------------ the cell atlas and materials
def cell_atlas(spec, parts, out_dir, name, cell=None, flat=False, px=None, grout=None, hidden_by=()):
    """Plan, pack and paint the block-cell atlas of one creature or prop (tools/blocky/cells.py), save it as <name>_atlas.png and load it with
    nearest filtering. Returns {'image', 'index': {(part, orient): island}, 'w', 'h', 'px', 'cell'}."""
    cell = cell or C.creature_cell(spec)
    px = C.texels(cell) if px is None else px
    grout = C.GROUT if grout is None else grout
    # `hidden_by`: boxes that are not built but hide faces (the diorama's floor under its ground)
    isl = C.islands(parts, cell, statics=[p for p in parts if p["moves"] == "none"] + list(hidden_by))
    w, h = C.pack(isl, px)
    rgb = C.paint(isl, w, h, C.creature_colours(spec), C.face_cells(spec), px, grout=grout, flat=flat)
    path = pathlib.Path(out_dir) / ("%s_atlas.png" % name)
    raster.write_png(str(path), w, h, rgb, 3)
    img = bpy.data.images.load(str(path), check_existing=False)
    img.name = "%s_atlas" % name
    return {"image": img, "index": {(i["part"], i["orient"]): i for i in isl}, "w": w, "h": h, "px": px, "cell": cell, "islands": isl}


def make_material(name, hexcol, slot, image=None, glow=GLOW_BUILD, surface=None):
    """A slot material. With `image` (the cell atlas) the base colour, and a Glow slot's emission, come from the texture, sampled with
    nearest filtering (Closest, the Blender twin of SurfaceAppearance.ResampleMode = Pixelated). `surface` (cells.SURFACE) sets the
    roughness and metal of a cell material (water and crystal glossy, ground matte)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = lin(hexcol)
    bsdf.inputs["Roughness"].default_value = ROUGH
    if slot == "Trim":
        bsdf.inputs["Roughness"].default_value = TRIM_ROUGH
        bsdf.inputs["Metallic"].default_value = TRIM_METAL
    for key, socket in (("rough", "Roughness"), ("metal", "Metallic")):
        if surface and key in surface:
            bsdf.inputs[socket].default_value = surface[key]
    if slot == "Glow":
        bsdf.inputs["Emission Color"].default_value = lin(hexcol)
        bsdf.inputs["Emission Strength"].default_value = glow
    if image is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Closest"
        tex.extension = "EXTEND"
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        if slot == "Glow":
            nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    return mat


# ------------------------------------------------------------------------------------------------ geometry
def to_spec(b):
    """Blender space back to spec space (the inverse of to_bl)."""
    return Vector((-b[0], b[2], b[1]))


def _local(part, p_spec):
    """A spec-space point in the part's own frame: centred on `at`, the rotation undone."""
    m = S.rot_matrix(part["rot"])
    d = [p_spec[i] - part["at"][i] for i in range(3)]
    return [sum(m[k][i] * d[k] for k in range(3)) for i in range(3)]  # R transposed


def _local_dir(part, n_spec):
    m = S.rot_matrix(part["rot"])
    return [sum(m[k][i] * n_spec[k] for k in range(3)) for i in range(3)]


def add_part(bm, part, pivot, mat_index, seg, width, uv, atlas=None):
    """Add one expanded part to `bm` (Blender space, relative to `pivot`); return the new faces. With `atlas` (cell_atlas) every face is
    box-projected onto its island (the box face its normal points through, in the part's own frame), so cells are square, the same size on
    every block and on one grid; a plain box's faces that the atlas culled (hidden inside or under another static block) are not built."""
    off = to_bl(pivot)
    existing = set(bm.faces)
    if part["bevel"]:
        made = bmesh.ops.create_cube(bm, size=1.0)
        verts = made["verts"]
        for v in verts:
            local = (v.co.x * part["size"][0], v.co.y * part["size"][1], v.co.z * part["size"][2])
            # create_cube is built in Blender space; read it as spec space so the sizes go on the right axes
            spec_pt = (local[0] + part["at"][0], local[1] + part["at"][1], local[2] + part["at"][2])
            v.co = to_bl(spec_pt) - off
        edges = list({e for v in verts for e in v.link_edges})
        for f in {f for v in verts for f in v.link_faces}:
            f.normal_update()  # the stored normals predate the move (which flips x); stale ones make the bevel bulge outward
        res = bmesh.ops.bevel(bm, geom=verts + edges, offset=width, offset_type="OFFSET", segments=seg, profile=0.5,
                              affect="EDGES", clamp_overlap=True)
        for f in res["faces"]:
            f.smooth = True  # the bevel strips shade smooth, the big faces stay flat: a rounded highlight on a crisp block
        faces = [f for f in bm.faces if f not in existing]
    else:
        pts, idx = S.part_mesh(part)
        vs = [bm.verts.new(to_bl(p) - off) for p in pts]
        faces = []
        plain = part["shape"] == "box" and not any(abs(a) > 1e-9 for a in part["rot"])
        for f in idx:
            if atlas is not None and plain:
                # the unit box's faces are in ORIENTS order of their normals; skip the ones the atlas culled
                a, b, c = (Vector(pts[f[k]]) for k in range(3))
                orient = C.orient_of(_local_dir(part, list((b - a).cross(c - a))))
                if (part["name"], orient) not in atlas["index"]:
                    continue
            try:
                faces.append(bm.faces.new([vs[i] for i in f]))
            except ValueError:
                pass
        for f in faces:
            f.smooth = False
    for f in faces:
        f.material_index = mat_index
        for loop in f.loops:
            loop[uv].uv = (0.5, 0.5)
    if atlas is not None:
        for f in faces:
            f.normal_update()
            orient = C.orient_of(_local_dir(part, list(to_spec(f.normal))))
            island = atlas["index"].get((part["name"], orient))
            if island is None:
                continue
            for loop in f.loops:
                p_local = _local(part, to_spec(loop.vert.co + off))
                u, v = C.project(orient, p_local, part["size"])
                loop[uv].uv = C.uv(island, u, v, atlas["w"], atlas["h"], atlas["px"])
    return faces


def build(spec, out_dir, cycle=False, glow=GLOW_BUILD, offset=(0.0, 0.0, 0.0), prefix="", flat=False, cell=None, rot=(0.0, 0.0, 0.0),
          hidden_by=(), px=None):
    """Make the creature's (or prop's) objects in the current scene, every face on its cell atlas. Returns {'objects': [...], 'tris': n,
    'atlas': (w, h)}. `flat` paints the atlas in flat slot colours (the look before B44); `rot` (Blender XYZ Euler, radians) turns the whole
    build about its origin before `offset` (Blender space) moves it; `hidden_by` (spec boxes) cull faces without being built; `px` (texels a cell) overrides cells.texels (a big prop at 4 so its atlas fits 1024)."""
    front = spec["front"]
    sid = front["id"]
    seg = int(front.get("bevel_segments") or 2)
    width = float(front.get("bevel_width") or 0.0)
    parts = S.expand(spec["parts"])
    pal = S.palette(spec)
    atlas = cell_atlas(spec, parts, out_dir, prefix + sid, cell, flat, hidden_by=hidden_by, px=px)
    mats = {}

    def material_for(p):
        key = (p["slot"], p["material"])
        if key not in mats:
            default = p["material"] == ("glow" if p["slot"] == "Glow" else C.DEFAULT_MATERIAL)
            name = "%s%s_%s" % (prefix, sid, p["slot"]) + ("" if default else "_" + p["material"])
            mats[key] = make_material(name, pal[S.SLOT_ROLE[p["slot"]]], p["slot"], atlas["image"], glow, C.SURFACE.get(p["material"]))
        return mats[key]
    cycle_mats = []
    if cycle and front.get("glow_cycle"):
        cycle_mats = [make_material("%s%s_Glow%d" % (prefix, sid, i), h, "Glow", None, glow) for i, h in enumerate(front["glow_cycle"])]
    groups = {}
    for slot in S.SLOTS:
        members = [p for p in parts if p["moves"] == "none" and p["slot"] == slot]
        if members:
            groups[slot] = {"pivot": [0.0, 0.0, 0.0], "parts": members}
    for key, g in S.movers(parts).items():
        groups[key] = g
    objects, tris = [], 0
    glow_k = 0
    for key, g in groups.items():
        bm = bmesh.new()
        uv = bm.loops.layers.uv.new("UVMap")
        slots_here = []
        for p in g["parts"]:
            mat = material_for(p)
            if p["slot"] == "Glow" and cycle_mats:
                mat = cycle_mats[glow_k % len(cycle_mats)]
                glow_k += 1
            if mat not in slots_here:
                slots_here.append(mat)
            add_part(bm, p, g["pivot"], slots_here.index(mat), seg, width, uv, atlas)
        if not bm.faces:
            bm.free()
            continue
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        mesh = bpy.data.meshes.new("%s%s_%s" % (prefix, sid, key))
        bm.to_mesh(mesh)
        bm.free()
        for m in slots_here:
            mesh.materials.append(m)
        obj = bpy.data.objects.new("%s%s" % (prefix, key), mesh)
        obj.location = to_bl(g["pivot"])
        if any(rot):
            obj.rotation_euler = tuple(rot)
            obj.location = obj.rotation_euler.to_matrix() @ obj.location
        obj.location += Vector(offset)
        bpy.context.scene.collection.objects.link(obj)
        mesh.calc_loop_triangles()
        tris += len(mesh.loop_triangles)
        objects.append(obj)
    plate = face_plate(spec, out_dir, prefix, offset, rot)
    if plate is not None:
        objects.append(plate)
        tris += 2
        groups["FacePlate"] = None
    return {"objects": objects, "tris": tris, "groups": list(groups), "atlas": (atlas["w"], atlas["h"]), "cell": atlas["cell"]}


def face_plate(spec, out_dir, prefix="", offset=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0)):
    """B46: the face plate as its own object (`FacePlate`, origin at its centre, the name data/Rigs and World.RigAnimator look for): one
    quad a sixty-fourth of a stud proud of the head's front, textured with the plate's flipbook sheet (<Id>_face.png, tools/blocky/eyes.py;
    nearest filtering, alpha), its UVs on frame 0 (the open eyes). A Mapping node offsets the UVs to show another frame (set_plate_frame).
    None for a note on the old format."""
    part = S.face_plate(spec)
    if part is None:
        return None
    sid = spec["front"]["id"]
    eyes = spec["eyes"]
    frames = E.plate_frames(eyes, S.face_host(spec))
    k = E.sheet_scale(len(frames[0][1][0]), len(frames[0][1]), len(frames))   # texels a face pixel (eyes.SHEET_SCALES; data/Rigs agrees)
    W, H, rgba = E.plate_sheet_rgba(frames, E.resolve_colours(eyes, S.palette(spec)), scale=k)
    fw, fh = len(frames[0][1][0]) * k, len(frames[0][1]) * k
    path = pathlib.Path(out_dir) / ("%s_face.png" % sid)
    E.write_png_rgba(str(path), W, H, rgba)
    img = bpy.data.images.load(str(path), check_existing=False)
    img.name = "%s%s_face" % (prefix, sid)
    img.alpha_mode = "STRAIGHT"
    mat = bpy.data.materials.new("%s%s_Face" % (prefix, sid))
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Roughness"].default_value = 0.4
    uvn = nt.nodes.new("ShaderNodeUVMap")
    mapping = nt.nodes.new("ShaderNodeMapping")
    mapping.name = "PlateFrame"
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    tex.extension = "CLIP"
    nt.links.new(uvn.outputs["UV"], mapping.inputs["Vector"])
    nt.links.new(mapping.outputs["Vector"], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    if "plate" not in mat:
        mat["plate"] = 1
    mat["plate_grid"] = [W, H, fw, fh]
    (cx, cy, cz), (w, h, _) = part["at"], part["size"]
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    corners = [((cx + w / 2, cy + h / 2), (0.0, 1.0)), ((cx - w / 2, cy + h / 2), (fw / W, 1.0)),
               ((cx - w / 2, cy - h / 2), (fw / W, 1.0 - fh / H)), ((cx + w / 2, cy - h / 2), (0.0, 1.0 - fh / H))]
    off = to_bl(part["pivot"])
    vs = [bm.verts.new(to_bl((x, y, cz)) - off) for (x, y), _ in corners]
    face = bm.faces.new(vs)
    face.normal_update()
    if face.normal.dot(to_bl((0.0, 0.0, -1.0))) < 0:
        face.normal_flip()
    for loop in face.loops:
        k = vs.index(loop.vert)
        loop[uv].uv = corners[k][1]
    mesh = bpy.data.meshes.new("%s%s_FacePlate" % (prefix, sid))
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new("%sFacePlate" % prefix, mesh)
    obj.location = to_bl(part["pivot"])
    if any(rot):
        obj.rotation_euler = tuple(rot)
        obj.location = obj.rotation_euler.to_matrix() @ obj.location
    obj.location += Vector(offset)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def set_plate_frame(obj, frame):
    """Shows flipbook frame `frame` (0-based, SHEET_COLUMNS a row) on a face plate object built by face_plate."""
    for mat in obj.data.materials:
        if mat is None or "plate_grid" not in mat:
            continue
        W, H, fw, fh = (int(v) for v in mat["plate_grid"])
        cols = max(1, W // fw)
        node = mat.node_tree.nodes.get("PlateFrame")
        if node is not None:
            node.inputs["Location"].default_value = ((frame % cols) * fw / W, -(frame // cols) * fh / H, 0.0)


AVATAR_SKIN, AVATAR_SHIRT = "#A3A2A5", "#0D69AC"  # the plain Roblox-default look: medium stone grey skin, a bright blue shirt and trousers


def avatar_spec(colour=AVATAR_SKIN, shirt=AVATAR_SHIRT):
    """The 5-stud scale figure as a spec, so it goes through the same cell route (skin cells at the world cell). The parts go in unexpanded:
    build() mirrors them once (SH.avatar_parts() is already expanded, and expanding it again stacked two copies of each arm and leg, whose
    coincident faces recalc_face_normals turned inside out, so the lineups drew them black). Head and arms grey, torso and legs blue."""
    parts = [S.normalise(dict(p, slot="BodyDark" if p["name"] in ("torso", "leg") else "Body"), i) for i, p in enumerate(SH.AVATAR)]
    return {"front": {"id": "Avatar", "palette": [colour, shirt], "roles": ["body", "second"]}, "parts": parts, "face": None}


def avatar(offset, colour=AVATAR_SKIN, out_dir=None, flat=False):
    """The avatar's objects (the grey and the blue mesh)."""
    out_dir = out_dir or bpy.app.tempdir
    made = build(avatar_spec(colour), out_dir, offset=offset, prefix="", flat=flat, cell=C.WORLD_CELL)
    return made["objects"]


# ------------------------------------------------------------------------------------------------ scene, cameras, renders
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    return scene


def look(cam, position, forward, up):
    f = forward.normalized()
    u = up.normalized()
    r = f.cross(u).normalized()
    u = r.cross(f).normalized()
    m = Matrix(((r.x, u.x, -f.x), (r.y, u.y, -f.y), (r.z, u.z, -f.z)))
    cam.matrix_world = Matrix.Translation(position) @ m.to_4x4()


VIEW_AXES = {  # spec space: (forward, up, point on the view plane for (u, v), where the camera sits back along -forward)
    "front": ((0, 0, 1), (0, 1, 0), lambda u, v: (-u, v, 0)),
    "right": ((-1, 0, 0), (0, 1, 0), lambda u, v: (0, v, -u)),
    "back": ((0, 0, -1), (0, 1, 0), lambda u, v: (u, v, 0)),
    "top": ((0, -1, 0), (0, 0, 1), lambda u, v: (-u, 0, v)),
}


def ortho_camera(scene, view, frame, distance=200.0):
    forward, up, point = VIEW_AXES[view]
    cam_data = bpy.data.cameras.new("Ortho")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = frame["side"]
    cam_data.clip_start = 0.1
    cam_data.clip_end = distance * 2
    cam = bpy.data.objects.new("Ortho", cam_data)
    scene.collection.objects.link(cam)
    p = Vector(point(*frame["centre"])) - Vector(forward) * distance
    look(cam, to_bl(p), to_bl(forward), to_bl(up))
    scene.camera = cam
    return cam


def flat_materials(objects):
    """Emission-only copies of the slot colours (and the face texture) for the orthographic views: they read like the sheet."""
    for obj in objects:
        for i, mat in enumerate(obj.data.materials):
            flat = mat.copy()
            nt = flat.node_tree
            bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
            tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
            out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
            em = nt.nodes.new("ShaderNodeEmission")
            em.inputs["Color"].default_value = bsdf.inputs["Base Color"].default_value
            if tex is not None:
                nt.links.new(tex.outputs["Color"], em.inputs["Color"])
            em.inputs["Strength"].default_value = 1.0
            if "plate_grid" in mat and tex is not None:
                # the face plate: transparent where the sheet is (the head shows through), the sheet's colour elsewhere
                tr = nt.nodes.new("ShaderNodeBsdfTransparent")
                mix = nt.nodes.new("ShaderNodeMixShader")
                nt.links.new(tex.outputs["Alpha"], mix.inputs["Fac"])
                nt.links.new(tr.outputs["BSDF"], mix.inputs[1])
                nt.links.new(em.outputs["Emission"], mix.inputs[2])
                nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
            else:
                nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
            obj.data.materials[i] = flat


def render_ortho(spec, objects, out_dir, sheet_dir, samples=8):
    scene = bpy.context.scene
    scene.render.resolution_x = scene.render.resolution_y = SH.MASK_SIZE
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = False
    scene.cycles.max_bounces = 0
    world = bpy.data.worlds.new("Flat")
    world.color = (1, 1, 1)
    scene.world = world
    flat_materials(objects)
    frames = SH.frames(spec)
    sid = spec["front"]["id"]
    scores = {}
    for view in SH.VIEWS:
        ortho_camera(scene, view, frames[view])
        path = pathlib.Path(out_dir) / ("%s_ortho_%s.png" % (sid, view))
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        w, h, built = raster.png_mask(str(path), use_alpha=True)
        ref_path = pathlib.Path(sheet_dir) / ("%s_mask_%s.png" % (sid, view))
        _, _, ref = raster.png_mask(str(ref_path), use_alpha=False)
        scores[view] = round(raster.iou(built, ref), 3)
        print("%-12s %-6s overlap with the sheet %.3f" % (sid, view, scores[view]), flush=True)
    return scores


def lit_setup(scene, size, samples, sky=(0.86, 0.92, 1.0), sky_strength=0.9, floor_hex="#E9E2CF", extent=4.0, centre=Vector((0, 0, 0))):
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.cycles.samples = samples
    scene.cycles.max_bounces = 4
    try:
        scene.cycles.use_denoising = True
    except Exception:  # noqa: BLE001
        pass
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (sky[0], sky[1], sky[2], 1.0)
    bg.inputs["Strength"].default_value = sky_strength
    scene.world = world
    bpy.ops.mesh.primitive_plane_add(size=extent * 40.0, location=(centre.x, centre.y, 0.0))
    floor = bpy.context.active_object
    fm = bpy.data.materials.new("Floor")
    fm.use_nodes = True
    fb = next(n for n in fm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    fb.inputs["Base Color"].default_value = lin(floor_hex)
    fb.inputs["Roughness"].default_value = 1.0
    floor.data.materials.append(fm)
    return floor


def add_lights(scene, centre, extent, sun_energy=3.2, fill_energy=110.0):
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = sun_energy
    sun.angle = math.radians(14.0)
    sun.color = (1.0, 0.95, 0.88)
    so = bpy.data.objects.new("Sun", sun)
    scene.collection.objects.link(so)
    so.rotation_euler = Vector((-0.55, -0.45, 0.7)).to_track_quat("Z", "Y").to_euler()
    fill = bpy.data.lights.new("Fill", "AREA")
    fill.energy = fill_energy * extent * extent / 4.0
    fill.size = extent * 3.0
    fill.color = (0.78, 0.86, 1.0)
    fo = bpy.data.objects.new("Fill", fill)
    scene.collection.objects.link(fo)
    fo.location = centre + Vector((extent * 3.0, -extent * 2.0, extent * 2.0))
    fo.rotation_euler = (centre - fo.location).to_track_quat("-Z", "Y").to_euler()


def bounds(objects):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objects:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector((min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z)))
            hi = Vector((max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z)))
    return lo, hi


def tq_camera(scene, objects, yaw=30.0, pitch=16.0, margin=1.22, aspect=1.0):
    bpy.context.view_layer.update()
    lo, hi = bounds(objects)
    centre = (lo + hi) * 0.5
    extent = max(hi - lo)
    d = Vector((-math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)), -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)),
                math.sin(math.radians(pitch))))
    cam_data = bpy.data.cameras.new("TQ")
    cam_data.type = "ORTHO"
    cam_data.clip_end = extent * 60
    cam = bpy.data.objects.new("TQ", cam_data)
    scene.collection.objects.link(cam)
    cam.location = centre + d * extent * 10.0
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    # fit: project the bounding box corners on the camera plane
    bpy.context.view_layer.update()
    inv = cam.matrix_world.inverted()
    xs, ys = [], []
    for o in objects:
        for c in o.bound_box:
            p = inv @ (o.matrix_world @ Vector(c))
            xs.append(p.x)
            ys.append(p.y)
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    cam_data.ortho_scale = max(w * margin, h * margin * aspect)
    cam_data.shift_x = ((max(xs) + min(xs)) / 2) / cam_data.ortho_scale
    cam_data.shift_y = ((max(ys) + min(ys)) / 2) / cam_data.ortho_scale
    return cam, centre, extent


def label(scene, cam, text, size_frac=0.035, colour=(1, 1, 1)):
    """A caption in the bottom-left corner of an orthographic camera's frame (a text object parented to the camera)."""
    curve = bpy.data.curves.new("Label", "FONT")
    curve.body = text
    scale = cam.data.ortho_scale
    curve.size = scale * size_frac
    obj = bpy.data.objects.new("Label", curve)
    scene.collection.objects.link(obj)
    mat = bpy.data.materials.new("LabelMat")
    mat.use_nodes = True
    nt = mat.node_tree
    out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (colour[0], colour[1], colour[2], 1)
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    curve.materials.append(mat)
    obj.parent = cam
    sx, sy = cam.data.shift_x * scale, cam.data.shift_y * scale
    obj.location = (sx - scale * 0.47, sy - scale * 0.47, -1.0)
    return obj


def glare(scene, kind="Fog Glow", strength=1.0):
    """Bloom on the VFX preview through the compositor (Blender 5.0's node-group compositor); skipped quietly if the API differs."""
    try:
        ng = bpy.data.node_groups.new("VfxGlare", "CompositorNodeTree")
        rl = ng.nodes.new("CompositorNodeRLayers")
        gl = ng.nodes.new("CompositorNodeGlare")
        out = ng.nodes.new("NodeGroupOutput")
        ng.interface.new_socket("Image", in_out="OUTPUT", socket_type="NodeSocketColor")
        ng.links.new(rl.outputs["Image"], gl.inputs["Image"])
        ng.links.new(gl.outputs["Image"], out.inputs[0])
        for value in (kind, kind.upper().replace(" ", "_")):
            try:
                gl.inputs["Type"].default_value = value
                break
            except Exception:  # noqa: BLE001
                continue
        for name, value in (("Threshold", 0.9), ("Strength", strength), ("Size", 0.6), ("Quality", "High")):
            try:
                gl.inputs[name].default_value = value
            except Exception:  # noqa: BLE001
                pass
        scene.compositing_node_group = ng
        scene.render.use_compositing = True
        return True
    except Exception as exc:  # noqa: BLE001
        print("glare skipped: %s" % exc)
        return False


def emissive(name, hexcol, strength, alpha=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    for n in list(nt.nodes):
        if n.type == "BSDF_PRINCIPLED":
            nt.nodes.remove(n)
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = lin(hexcol)
    em.inputs["Strength"].default_value = strength
    if alpha < 1.0:
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        mix = nt.nodes.new("ShaderNodeMixShader")
        mix.inputs["Fac"].default_value = alpha
        nt.links.new(tr.outputs["BSDF"], mix.inputs[1])
        nt.links.new(em.outputs["Emission"], mix.inputs[2])
        nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    else:
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    return mat


def cube(name, centre_bl, size, mat, rot_z=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    obj.location = centre_bl
    obj.rotation_euler = (0, 0, rot_z)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def effect_layers(sid, path=None):
    """The species' effect layers from src/shared/data/Effects.luau, read-only: [{'kind': 'Light', 'color': 'C084FC', ...}]. The preview takes
    its light, spark, orbit and arc colours from here, so it shows the colours the game will draw."""
    import re
    text = pathlib.Path(path or ROOT / "src/shared/data/Effects.luau").read_text(encoding="utf-8")
    m = re.search(r"\n\t%s = \{(.*?)\n\t\},?\n" % re.escape(sid), text, re.S)
    if not m:
        return []
    out = []
    for row in re.finditer(r"\{ kind = \"(\w+)\"([^}]*)\}", m.group(1)):
        layer = {"kind": row.group(1)}
        for k, v in re.findall(r"(\w+) = (\"[^\"]*\"|[-\d.]+)", row.group(2)):
            layer[k] = v.strip('"')
        out.append(layer)
    return out


def vfx_layers(spec, objects, tier):
    """The preview's effect geometry, outward from the body by tier (Blocky-Style rule 7). Returns the objects added."""
    front = spec["front"]
    pal = S.palette(spec)
    glow_hex = pal.get("glow", pal.get("accent"))
    tier_hex = TIER_HEX.get(tier, "#FFFFFF")
    parts = S.expand(spec["parts"])
    lo, hi = S.bounds(parts)
    height = hi[1]
    width = max(hi[0] - lo[0], hi[2] - lo[2])
    centre = Vector(((lo[0] + hi[0]) / 2, height / 2, (lo[2] + hi[2]) / 2))
    rank = S.TIER_ORDER.index(tier)
    added = []
    fx = effect_layers(front["id"])
    first = lambda kind, default: next(("#" + l["color"] for l in fx if l["kind"] == kind and l.get("color")), default)  # noqa: E731
    light_hex = first("Light", glow_hex)
    spark_hex = first("Emitter", glow_hex)
    arc_hex = first("Beam", glow_hex)
    orbit_hex = first("Orbit", glow_hex)
    print("%-12s effects from Effects.luau: %s" % (front["id"], ", ".join("%s %s" % (l["kind"], l["color"]) for l in fx if l.get("color")) or "none"), flush=True)
    spark = emissive("Spark", spark_hex, GLOW_VFX * 2.0)
    tips = [p for p in parts if p["slot"] == "Glow"]
    # Rare and up: a soft light in the element colour, hung where Effects.luau hangs it (Back: 0.75 of the height, a little behind the centre)
    light = bpy.data.lights.new("BodyLight", "POINT")
    light.energy = 60.0 * height * (1.0 + 0.5 * max(0, rank - 2))
    light.color = lin(light_hex)[:3]
    light.shadow_soft_size = height * 0.25
    lo_obj = bpy.data.objects.new("BodyLight", light)
    lo_obj.location = to_bl((centre[0], height * 0.85, centre[2] + (hi[2] - lo[2]) * 0.15))
    bpy.context.scene.collection.objects.link(lo_obj)
    added.append(lo_obj)
    import random
    rnd = random.Random(7)
    host = S.face_host(spec)

    def over_face(c, margin=0.25):
        """True when a point sits in front of the face (rule 7: no effect crosses the head's front)."""
        if host is None:
            return False
        (hx, hy, hz), (w, h, dz) = host["at"], host["size"]
        return abs(c[0] - hx) < w / 2 + margin and abs(c[1] - hy) < h / 2 + margin and c[2] < hz - dz / 2 + margin
    if rank >= S.TIER_ORDER.index("Epic"):
        # sparks kept on the body: small cubes on a shell a third to two thirds of a stud out from the glow parts, upper side; none over the face
        scale = (height / 3.75) ** 0.5
        for p in tips:
            for _ in range(2 if rank == 3 else 1):
                d = Vector((rnd.uniform(-1, 1), rnd.uniform(0.1, 1), rnd.uniform(-1, 1))).normalized() * rnd.uniform(0.35, 0.7) * scale
                c = Vector(p["at"]) + d
                if over_face(c):
                    continue
                s = rnd.choice((0.09, 0.12, 0.15)) * scale
                added.append(cube("spark", to_bl(c), (s, s, s), spark, rnd.uniform(0, 1.5)))
        # arcs named in the note (`arcs: ["A>B", ...]`, expanded part names): a zigzag of thin bars from the top of A to the top of B,
        # a white core in an element-coloured sleeve
        by_name = {p["name"]: p for p in parts}
        core = emissive("ArcCore", "#FFFFFF", GLOW_VFX * 2.0)
        sleeve = emissive("Arc", arc_hex, GLOW_VFX * 1.4, alpha=0.75)
        for arc in front.get("arcs") or []:
            a_name, _, b_name = str(arc).partition(">")
            if a_name not in by_name or b_name not in by_name:
                print("arc %r: no such parts" % arc)
                continue
            A, B = (Vector(max(S.part_mesh(by_name[n])[0], key=lambda v: v[1])) for n in (a_name, b_name))
            pts = [A]
            steps = 9
            for k in range(1, steps):
                side = 1 if k % 2 else -1
                bump = Vector((side * rnd.uniform(0.1, 0.24), 0.3 * math.sin(math.pi * k / steps) + rnd.uniform(-0.1, 0.1), side * rnd.uniform(-0.15, 0.15)))
                pts.append(A.lerp(B, k / steps) + bump)
            pts.append(B)
            for k in range(len(pts) - 1):
                p0, p1 = to_bl(pts[k]), to_bl(pts[k + 1])
                seg_len = (p1 - p0).length + 0.03
                for thick, mat in ((0.022, core), (0.07, sleeve)):
                    o = cube("arc", (p0 + p1) / 2, (thick, thick, seg_len), mat)
                    o.rotation_euler = (p1 - p0).to_track_quat("Z", "Y").to_euler()
                    added.append(o)
    if rank >= S.TIER_ORDER.index("Legendary"):
        # orbiting cubes a stud out from the skin, and a ground ring in the tier colour: the effects touch the ground
        orbit = emissive("Orbit", orbit_hex, GLOW_VFX * 1.2)
        n = 10
        r = width * 0.62
        for k in range(n):
            ang = 2 * math.pi * k / n
            y = height * (0.55 + 0.12 * math.sin(3 * ang))
            c = (centre[0] + r * math.cos(ang), y, centre[2] + r * math.sin(ang) * 0.75)
            if over_face(c):
                continue
            s = 0.18 * (height / 5) ** 0.5
            added.append(cube("orbit", to_bl(c), (s, s, s), orbit, ang))
        # the ring is in the tier colour; the Secret's tier colour is near-black, so its ring is its own violet (the Cosmic set in shadow)
        ring = emissive("GroundRing", orbit_hex if tier == "Secret" else tier_hex, GLOW_VFX * 0.8)
        rr = width * 0.55
        n = 40
        cb = to_bl(centre)
        for k in range(n):
            ang = 2 * math.pi * k / n
            c = Vector((cb.x + rr * math.cos(ang), cb.y + rr * math.sin(ang), 0.03))
            seg_w = 2 * math.pi * rr / n * 0.82
            added.append(cube("ring", c, (seg_w, 0.35 * (height / 5) ** 0.5, 0.05), ring, ang + math.pi / 2))
    if tier == "Secret":
        # shadow smoke that falls instead of rising: dark translucent cubes round the feet (Effects.luau's dark Feet emitter)
        smoke = bpy.data.materials.new("Smoke")
        smoke.use_nodes = True
        sb = next(n for n in smoke.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        sb.inputs["Base Color"].default_value = lin("#1A1626")
        sb.inputs["Roughness"].default_value = 1.0
        sb.inputs["Alpha"].default_value = 0.75
        for _ in range(26):
            ang = rnd.uniform(0, 2 * math.pi)
            r = width * rnd.uniform(0.3, 0.6)
            c = (centre[0] + r * math.cos(ang), rnd.uniform(0.15, height * 0.22), centre[2] + r * math.sin(ang) * 0.8)
            s = rnd.choice((0.25, 0.35, 0.45)) * (height / 5) ** 0.5
            added.append(cube("smoke", to_bl(c), (s, s, s), smoke, rnd.uniform(0, 1.5)))
    if rank >= S.TIER_ORDER.index("Cosmic"):
        # a light column from the top into the sky
        top = max((p for p in parts if p["slot"] == "Glow"), key=lambda p: p["at"][1])
        float_part = next((p for p in parts if p["moves"] == "float"), top)
        base = Vector(float_part["at"])
        col_h = height * 3.0
        beam = emissive("Beam", light_hex, GLOW_VFX * 0.7, alpha=0.3)
        c = to_bl((base[0], base[1] + col_h / 2, base[2]))
        bw = min(1.6, 0.12 * height)   # B45: a 3.5-stud Cosmic gets a column in proportion (1.6 studs was for the 14-stud builds)
        added.append(cube("beam", c, (bw, bw, col_h), beam))
        core = emissive("BeamCore", "#FFF6DC", GLOW_VFX * 1.2, alpha=0.6)
        added.append(cube("beamcore", c, (bw / 4, bw / 4, col_h), core))
        # the corona: a strong light at the centre of the turning part (the sun behind the head), rimming the head in its colour
        halo = [p for p in parts if p["moves"] == "halo"]
        if halo:
            corona = bpy.data.lights.new("Corona", "POINT")
            corona.energy = 120.0 * height
            corona.color = lin(light_hex)[:3]
            corona.shadow_soft_size = height * 0.15
            co = bpy.data.objects.new("Corona", corona)
            ring_front = min(p["at"][2] - p["size"][2] / 2 for p in halo)
            co.location = to_bl((halo[0]["pivot"][0], halo[0]["pivot"][1], ring_front - 0.15))
            bpy.context.scene.collection.objects.link(co)
            added.append(co)
    return added


# ------------------------------------------------------------------------------------------------ the idle preview (B46)
SPEC_TO_BL = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))   # to_bl as a matrix (its own inverse)


def _spec_matrix(pose, around):
    """The pose (rigs.new_pose: offset, turn as Roblox's CFrame.Angles x y z, scale) about the spec point `around`, as a 4x4 in spec space."""
    rx, ry, rz = pose["r"]
    rot = Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y") @ Matrix.Rotation(rz, 4, "Z")
    sc = Matrix.Diagonal((pose["s"][0], pose["s"][1], pose["s"][2], 1.0))
    a = Vector(around)
    return Matrix.Translation(a + Vector(pose["p"])) @ rot @ sc @ Matrix.Translation(-a)


def pose_objects(spec, objs, rest, row, now, offset=0.0, flourish_at=None):
    """Poses the built objects for time `now` (seconds) with the same math as Shared/RigMath (tools/blocky/rigs.py): each moving object
    about its pivot, then the whole body about its feet. `flourish_at`: seconds into the flourish to show instead of the clock's own."""
    fl = row["flourish"]
    elapsed = flourish_at if flourish_at is not None else -1.0
    if flourish_at is None and fl and fl["every"] > 0:
        into = (now + offset * fl["every"]) % fl["every"]
        elapsed = into if into < fl["length"] else -1.0
    root = RG.new_pose()
    for c in row["root"]:
        RG.accumulate(root, c, now, offset)
    if fl and elapsed >= 0:
        for m in fl["moves"]:
            if m["part"] == "root":
                RG.accumulate_move(root, m, elapsed)
    m_root = _spec_matrix(root, (0.0, 0.0, 0.0))
    parts = {p["name"]: p for p in row["parts"]}
    centre = row["centre"]
    for o in objs:
        key = o.name
        local = Matrix.Identity(4)
        if key in parts:
            pose = RG.new_pose()
            for c in parts[key]["clips"]:
                RG.accumulate(pose, c, now, offset)
            if fl and elapsed >= 0:
                for m in fl["moves"]:
                    if m["part"] == key:
                        RG.accumulate_move(pose, m, elapsed)
            piv = parts[key]["pivot"]
            local = _spec_matrix(pose, (piv[0] + centre[0], piv[1], piv[2] + centre[2]))
        o.matrix_world = SPEC_TO_BL @ (m_root @ local) @ SPEC_TO_BL @ rest[o.name]


def run_idle(spec, out, size, samples, frames=8):
    """<Id>_idle.png: eight frames of the idle (between flourishes), four of one flourish (from Rare up), and the face plate's frames,
    rendered lit at the three-quarter view, composed by tools/blocky/idle_sheet.py (Pillow, in the system Python)."""
    import subprocess
    sid = spec["front"]["id"]
    row = RG.row(spec)
    fdir = out / ("%s_idle_frames" % sid)
    fdir.mkdir(parents=True, exist_ok=True)
    for old in fdir.glob("*.png"):
        old.unlink()
    scene = reset()
    objs = build(spec, out)["objects"]
    bpy.context.view_layer.update()
    rest = {o.name: o.matrix_world.copy() for o in objs}
    cam, centre, extent = tq_camera(scene, objs, margin=1.5)
    lit_setup(scene, size, samples, extent=extent, centre=centre)
    add_lights(scene, centre, extent)
    plate = next((o for o in objs if o.name == "FacePlate"), None)
    face = row["face"]
    fl = row["flourish"]
    t0 = (fl["length"] + 0.6) if fl else 0.4
    shots = []
    for k in range(frames):
        now = t0 + k * 0.45
        frame = RG.face_frame(face, now, 0.0)
        if k == 3:
            frame = face["closed"]          # one frame shows the blink
        elif k == 5 and face["glint"]:
            frame = face["glint"][-1]       # and one the big glint
        shots.append(("idle %.2fs" % now, now, None, frame))
    if fl:
        for s in (0.12, 0.35, 0.6, 0.85):
            at = s * fl["length"]
            shots.append(("flourish %.1fs" % at, 50.0, at, face["cycle"][int(at * 8) % len(face["cycle"])] if face["cycle"] else face["open"]))
    names = []
    for i, (name, now, at, frame) in enumerate(shots):
        pose_objects(spec, objs, rest, row, now, 0.0, at)
        if plate is not None:
            set_plate_frame(plate, frame)
        scene.render.filepath = str(fdir / ("f%02d.png" % i))
        bpy.ops.render.render(write_still=True)
        names.append(name)
        print("%-12s idle %s" % (sid, name), flush=True)
    (fdir / "labels.txt").write_text("\n".join(names), encoding="utf-8")
    sheet = out / ("%s_idle.png" % sid)
    cmd = ["python3", "-I", str(ROOT / "tools/blocky/idle_sheet.py"), str(fdir), str(out / ("%s_face.png" % sid)), str(sheet), "--id", sid,
           "--tier", spec["front"]["tier"], "--frames", ",".join(E.frame_names(spec["eyes"]["key"])), "--frame-size", "%d,%d" % (face["frameWidth"], face["frameHeight"])]
    subprocess.run(cmd, check=False)
    print("%-12s %s" % (sid, sheet), flush=True)


# ------------------------------------------------------------------------------------------------ the runs
def export_glb(path):
    kwargs = dict(filepath=str(path), export_format="GLB", use_selection=False, export_yup=True, export_apply=True, export_materials="EXPORT")
    try:
        bpy.ops.export_scene.gltf(**kwargs)
    except TypeError:
        kwargs.pop("export_materials")
        bpy.ops.export_scene.gltf(**kwargs)


def run_one(note, sheet_dir, out_dir, size, samples, skip, write, flat=False, suffix="", idle=False):
    spec = S.load(note)
    errors, _ = S.validate(spec)
    if errors:
        print("%s: %d spec errors; fix the note first:\n  %s" % (note, len(errors), "\n  ".join(errors)))
        return 1
    sid = spec["front"]["id"]
    tier = spec["front"]["tier"]
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    sheet_dir = pathlib.Path(sheet_dir) if sheet_dir else out
    if not (sheet_dir / ("%s_mask_front.png" % sid)).exists():
        SH.write_all(spec, sheet_dir)
    # build and export
    scene = reset()
    built = build(spec, out, flat=flat)
    glb = out / ("%s%s.glb" % (sid, suffix))
    export_glb(glb)
    print("%-12s built %d objects (%s), %d triangles, cell %.4f studs, atlas %dx%d -> %s" % (
        sid, len(built["objects"]), ", ".join(built["groups"]), built["tris"], built["cell"], built["atlas"][0], built["atlas"][1], glb), flush=True)
    result = {"tris": built["tris"], "glb": str(glb), "overlap": None}
    # the orthographic views and the silhouette check
    if "ortho" not in skip:
        result["overlap"] = render_ortho(spec, built["objects"], out, sheet_dir)
    # the lit three-quarter view
    if "tq" not in skip:
        scene = reset()
        objs = build(spec, out, flat=flat)["objects"]
        cam, centre, extent = tq_camera(scene, objs)
        lit_setup(scene, size, samples, extent=extent, centre=centre)
        add_lights(scene, centre, extent)
        scene.render.filepath = str(out / ("%s_tq%s.png" % (sid, suffix)))
        bpy.ops.render.render(write_still=True)
        print("%-12s %s" % (sid, scene.render.filepath), flush=True)
    # the VFX preview, Rare and up
    if "vfx" not in skip and S.TIER_ORDER.index(tier) >= S.TIER_ORDER.index("Rare"):
        scene = reset()
        objs = build(spec, out, cycle=True, glow=GLOW_VFX, flat=flat)["objects"]
        extra = vfx_layers(spec, objs, tier)
        if S.TIER_ORDER.index(tier) >= S.TIER_ORDER.index("Cosmic"):
            # the turning disk is the hero: in the preview its gold is lit as well as its rays
            for o in objs:
                if o.name.startswith("halo"):
                    for i, m in enumerate(o.data.materials):
                        if "_Trim" in m.name:
                            lit = m.copy()
                            b = next(n for n in lit.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
                            b.inputs["Emission Color"].default_value = b.inputs["Base Color"].default_value
                            b.inputs["Emission Strength"].default_value = 1.2
                            o.data.materials[i] = lit
        frame_objs = objs + [o for o in extra if o.type == "MESH" and not o.name.startswith("beam")]
        cam, centre, extent = tq_camera(scene, frame_objs, yaw=20.0, pitch=12.0, margin=1.3)
        lit_setup(scene, size, samples, sky=(0.13, 0.14, 0.32), sky_strength=1.2, floor_hex="#3A3D66", extent=extent, centre=centre)
        add_lights(scene, centre, extent, sun_energy=1.6, fill_energy=70.0)
        try:
            scene.view_settings.view_transform = "AgX"  # emissive parts keep their hue instead of clipping to white
        except TypeError:
            pass
        glare(scene)
        label(scene, cam, "VFX PREVIEW (Blender) - in game the effects come from Effects.luau", 0.028)
        scene.render.filepath = str(out / ("%s_vfx%s.png" % (sid, suffix)))
        bpy.ops.render.render(write_still=True)
        print("%-12s %s" % (sid, scene.render.filepath), flush=True)
    if idle and S.is_b46(spec):
        run_idle(spec, out, min(size, 420), max(16, samples // 2))
    if write:
        updates = {"blocks": S.counts(spec)["blocks"], "tris": built["tris"]}
        if result["overlap"]:
            updates["overlap"] = [result["overlap"][v] for v in SH.VIEWS]
        text = S.set_front(pathlib.Path(note).read_text(encoding="utf-8"), updates)
        pathlib.Path(note).write_text(text, encoding="utf-8")
        print("%-12s wrote %s into %s" % (sid, ", ".join(updates), note), flush=True)
    return 0


def run_lineup(notes, out_dir, size, samples, flat=False, suffix=""):
    """Every creature to scale in one row beside the 5-stud avatar, lit, a gentle three-quarter view."""
    scene = reset()
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    objs = list(avatar((0, 0, 0), out_dir=out, flat=flat))
    gap = 1.5
    x = 2.0 + gap  # the avatar is 4 studs wide; the camera looks from -Y, so +X is to the right on screen
    tallest = 5.0
    for note in notes:
        spec = S.load(note)
        lo, hi = S.bounds(S.expand(spec["parts"]))
        w = hi[0] - lo[0]
        x += w / 2
        made = build(spec, out, offset=(x, 0.0, 0.0), prefix="L", flat=flat)
        objs += made["objects"]
        x += w / 2 + gap
        tallest = max(tallest, hi[1])
    # wide enough for the whole row: the row's width over its tallest member, never narrower than 2.2 to 1
    aspect = max(2.2, round((x + 2.0) / tallest * 0.9, 2))
    cam, centre, extent = tq_camera(scene, objs, yaw=10.0, pitch=8.0, margin=1.06, aspect=aspect)
    lit_setup(scene, size, samples, extent=extent, centre=centre)
    add_lights(scene, centre, extent)
    scene.render.resolution_x = int(size * aspect)
    scene.render.resolution_y = size
    scene.render.filepath = str(out / ("lineup%s.png" % suffix))
    bpy.ops.render.render(write_still=True)
    print("lineup %s" % scene.render.filepath, flush=True)
    return 0


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--spec", default="", help="a creature note (or a comma list)")
    ap.add_argument("--sheet", default="", help="the folder of the sheet's <Id>_mask_<view>.png (default: --out)")
    ap.add_argument("--out", required=True, help="a scratch folder for the GLB and the renders (never assets/models)")
    ap.add_argument("--size", type=int, default=640)
    ap.add_argument("--samples", type=int, default=48)
    ap.add_argument("--skip", default="", help="comma list of ortho, tq, vfx")
    ap.add_argument("--write", action="store_true", help="write blocks, triangles and overlaps into the note")
    ap.add_argument("--lineup", default="", help="comma list of notes rendered side by side to scale with the avatar")
    ap.add_argument("--flat", action="store_true", help="flat slot colours, no cells (the look before B44)")
    ap.add_argument("--suffix", default="", help="added to every output name, e.g. _cells")
    ap.add_argument("--idle", action="store_true", help="B46: also render the idle preview <Id>_idle.png (8 idle frames, a flourish, the plate)")
    a = ap.parse_args(argv)
    if "assets/models" in str(pathlib.Path(a.out).resolve()):
        print("refusing to write under assets/models: builds go to a scratch folder until Ethan approves a sheet (B43)")
        return 2
    if a.lineup:
        return run_lineup([n for n in a.lineup.split(",") if n], a.out, a.size, a.samples, a.flat, a.suffix)
    rc = 0
    for note in [n for n in a.spec.split(",") if n]:
        rc |= run_one(note, a.sheet, a.out, a.size, a.samples, set(a.skip.split(",")), a.write, a.flat, a.suffix, a.idle)
    return rc


if __name__ == "__main__":
    sys.exit(main())
