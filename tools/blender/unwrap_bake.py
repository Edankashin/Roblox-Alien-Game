#!/usr/bin/env python3
"""UV unwrap and palette bake: give every species GLB one clean, non-overlapping UV layout and one baked palette texture.

The sculpt and silhouette builders write GLBs whose UVs are per-primitive layouts, some tiled past 0..1 (the Surface pass scales a slot's
UVs by its shared texture's tiling), so the islands overlap. Blockbench and Substance paint on UVs, and a Roblox mesh with one texture
instead of vertex colours needs real islands. This tool loads each species GLB, runs ONE Smart UV Project over the whole creature (all
seven slots at once), packs the islands into 0..1, keeps every face on its material slot, and writes the result next to a baked palette:

  <out>/<Id>/<Id>.glb, <Id>.fbx   written the way tools/blender/species_bodies.py writes them (same export settings, so the same slot
                                  names and order, height and pivot; checked against the input, see below)
  <out>/<Id>/<Id>_palette.png     512 px: per texel the slot's materials.json hex (as linear light) times the COLOR_0 gradient where
                                  the input carries one, optionally times a soft ambient occlusion; islands bled outward so mip levels
                                  do not show seams; the space between islands is transparent
  <out>/<Id>/materials.json       copied unchanged (tools/blockbench/to_bbmodel.py and preview.py read it)
  <out>/<Id>/notes.md             the input's notes plus one line: island count, coverage, overlap and the bake settings

The bake is a numpy raster of the written GLB's own triangles (its UVs, its COLOR_0, its slot per primitive), so the texture matches the
file that ships; only the AO needs Blender (Cycles bake, --ao). Colour maths is glTF's: sRGB bytes decoded to linear, multiplied, encoded.
A shared slot texture (the Surface pass `texture` key: fur, moss, ...) relies on tiled UVs and is NOT baked in: the atlas has no tiling.

Checks after each species (one line printed per species; exit 1 if any species fails):
  * no UV outside 0..1
  * UV overlap under 1 percent of the covered texels (a coverage raster: a texel counts when two triangles reach it)
  * triangle count, per-slot triangle counts, material names and order, and the bounds (height and pivot) equal the input's
  * the shading is the input's (every output normal matches one of the input's at that position, to 0.5 percent of the vertices)
  * the palette is the stated size, and no UV triangle is collapsed to zero area

  python3 tools/blender/unwrap_bake.py --species Sparkfox,Mossbop --models assets/models --out /scratch/uvbake   # plain Python with bpy
  blender -b -P tools/blender/unwrap_bake.py -- --species world1,world2 --out /scratch/uvbake                    # a whole world (or: recipes)
  python3 tools/blender/unwrap_bake.py --all --out /scratch/uvbake --ao                                         # every folder, with AO
  python3 tools/blender/unwrap_bake.py --species recipes --out /scratch/uvbake --report /scratch/report.json    # the 32, plus a JSON summary
  python3 tools/blender/unwrap_bake.py --species Sparkfox --write-assets                                         # in place (NOT used yet)

--out is refused when it is, or sits inside, assets/models; --write-assets lifts that and writes the results over --models itself (the
input GLB is read first). Nothing under assets/models is written without the flag. Then:
  python3 tools/blender/preview.py --lit --textured --models /scratch/uvbake --species Sparkfox --out /scratch/renders
  python3 tools/blockbench/to_bbmodel.py --models /scratch/uvbake --species Sparkfox --out /scratch/bb      # reads <Id>_palette.png
"""
import argparse
import datetime
import json
import math
import pathlib
import re
import shutil
import struct
import sys
import time
import zlib

import bpy  # first: with the bpy module, mathutils and bmesh only import after it
import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools/blockbench"))
import to_bbmodel as BB  # noqa: E402  (the pure-Python GLB reader and the slot colours)

TOOL = "tools/blender/unwrap_bake.py"
MODELS = ROOT / "assets/models"
ANGLE_LIMIT = 66.0       # degrees: the Smart UV Project cut angle (species_sculpt.uv_project uses the same)
ISLAND_MARGIN = 0.004    # Smart UV Project's SCALED margin; at 512 px it leaves a gap of 5 texels or more between islands
MARGIN_METHOD = "SCALED"
SIZE = 512               # palette texture side
SUPERSAMPLE = 2          # coverage raster samples per texel side (so a tiny triangle still marks a texel)
BLEED = 2                # texels each island's colour is bled outward
AO_SAMPLES = 16
AO_STRENGTH = 0.6        # 0 = no occlusion in the palette, 1 = the baked AO as it is
AO_DISTANCE = 0.3        # occlusion reach, as a share of the creature's height
OVERLAP_LIMIT = 1.0      # percent of covered texels
UV_SLACK = 1e-5
BOUNDS_SLACK = 1e-4
SHADING_SLACK = 0.005    # share of vertices whose normal may differ from the input's (float rounding at a hard edge)
LINE = "- UV unwrap and palette bake"


class Failure(Exception):
    """A species could not be processed (not a failed check: those are listed and the species is still written)."""


# ------------------------------------------------------------------------------------------------ colour and PNG
def srgb_to_linear(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.clip(np.asarray(c, dtype=np.float64), 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1.0 / 2.4) - 0.055)


def hex_linear(h):
    h = h.strip().lstrip("#")
    return srgb_to_linear(np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)]) / 255.0)


def png_bytes(rgba):
    """An 8-bit RGBA PNG from an (H, W, 4) uint8 array. Filter 0 or Sub, whichever compresses smaller (Sub for the smooth gradient)."""
    height, width = rgba.shape[:2]
    rows = rgba.reshape(height, width * 4)
    sub = rows.copy()
    sub[:, 4:] = rows[:, 4:] - rows[:, :-4]  # uint8 arithmetic wraps, which is what the Sub filter wants

    def deflate(filter_type, data):
        raw = np.concatenate([np.full((height, 1), filter_type, np.uint8), data], axis=1).tobytes()
        return zlib.compress(raw, 9)

    plain, subbed = deflate(0, rows), deflate(1, sub)

    def chunk(tag, body):
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", min(plain, subbed, key=len)) + chunk(b"IEND", b""))


# ------------------------------------------------------------------------------------------------ the written GLB, read back
def summarize(path, entries):
    """What the checks compare: read from the GLB file itself, not from Blender."""
    glb = BB.read_glb(path)
    names = [m.get("name", "") for m in glb.materials]
    per_slot = {}
    for prim in glb.primitives:
        name = names[prim.material] if prim.material is not None else "(none)"
        per_slot[name] = per_slot.get(name, 0) + len(prim.triangles)
    points = [p for prim in glb.primitives for p in prim.positions]
    lo = [min(p[a] for p in points) for a in range(3)]
    hi = [max(p[a] for p in points) for a in range(3)]
    return {"glb": glb, "tris": glb.triangle_count, "names": names, "per_slot": per_slot, "lo": lo, "hi": hi,
            "normals": corner_normals(glb)}


def corner_normals(glb):
    """{position rounded to 1e-4: [the distinct unit normals found there]}: the shading, independent of how the vertices are split."""
    table = {}
    for prim in glb.primitives:
        for point, normal in zip(prim.positions, prim.normals or ()):
            seen = table.setdefault(tuple(round(c, 4) for c in point), [])
            if not any(sum(a * b for a, b in zip(normal, other)) > 0.9998 for other in seen):
                seen.append(normal)
    return table


def shading_drift(before, after):
    """Share of the output's vertices whose normal matches none of the input's normals at that position (within 3 degrees)."""
    if not before:
        return 0.0
    total = missed = 0
    for key, normals in after.items():
        for normal in normals:
            total += 1
            missed += not any(sum(a * b for a, b in zip(normal, other)) > 0.9986 for other in before.get(key, ()))
    return missed / max(total, 1)


def glows(entry):
    """A slot that shines on its own (Neon, or an emission above 0) takes no baked occlusion: Roblox draws it lit by itself."""
    return bool(entry) and (entry.get("material") == "Neon" or float(entry.get("emission", 0) or 0) > 0)


def triangle_arrays(glb, entries):
    """(uv, rgba, slots): (T,3,2) UVs and (T,3,4) per corner: the linear colour (slot hex times COLOR_0) and, in the fourth channel, how
    much occlusion the corner takes (1, or 0 on a glowing slot). A primitive without UVs is an error: the unwrap gave every one a layout."""
    slots = BB.build_slots(glb, entries)
    by_name = {e.get("name"): e for e in entries}
    uv, rgba = [], []
    for slot in slots:
        base = hex_linear(slot.hex)
        weight = 0.0 if glows(by_name.get(slot.name)) else 1.0
        for prim in slot.primitives:
            if prim.uvs is None:
                raise Failure("a primitive of %s has no UVs" % slot.name)
            grad = np.ones((len(prim.positions), 3))
            if prim.colors:
                grad = np.asarray([c[:3] for c in prim.colors], dtype=np.float64)
            tri = np.asarray(prim.triangles, dtype=np.int64).reshape(-1, 3)
            corners = np.concatenate([grad * base, np.full((len(grad), 1), weight)], axis=1)
            uv.append(np.asarray(prim.uvs, dtype=np.float64)[tri])
            rgba.append(corners[tri])
    return np.concatenate(uv), np.concatenate(rgba), slots


def rasterize(uv, side, values=None):
    """Fill every triangle's pixel centres on a side x side grid (u to the right, v down). Returns the per-sample hit count and, when
    `values` ((T,3,C) per corner) is given, the barycentric-interpolated values of the last triangle to reach each sample."""
    hits = np.zeros((side, side), np.uint8)
    image = None if values is None else np.zeros((side, side, values.shape[2]), np.float32)
    corners = uv * side
    for t in range(len(uv)):
        a, b, c = corners[t]
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-12:
            continue
        x0, x1 = max(int(math.floor(min(a[0], b[0], c[0]) - 0.5)), 0), min(int(math.ceil(max(a[0], b[0], c[0]) - 0.5)), side - 1)
        y0, y1 = max(int(math.floor(min(a[1], b[1], c[1]) - 0.5)), 0), min(int(math.ceil(max(a[1], b[1], c[1]) - 0.5)), side - 1)
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        w0 = ((b[1] - c[1]) * (gx - c[0]) + (c[0] - b[0]) * (gy - c[1])) / den
        w1 = ((c[1] - a[1]) * (gx - c[0]) + (a[0] - c[0]) * (gy - c[1])) / den
        w2 = 1.0 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not inside.any():
            continue
        hits[y0:y1 + 1, x0:x1 + 1] += inside.astype(np.uint8)
        if image is not None:
            v = values[t]
            blended = w0[..., None] * v[0] + w1[..., None] * v[1] + w2[..., None] * v[2]
            window = image[y0:y1 + 1, x0:x1 + 1]
            window[inside] = blended[inside]
    return hits, image


def islands_of(glb):
    """Number of UV islands: triangles are joined when they share a vertex (same position, same UV)."""
    parent = []

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    seen = {}
    count = 0
    for prim in glb.primitives:
        for tri in prim.triangles:
            me = len(parent)
            parent.append(me)
            count += 1
            for i in tri:
                key = tuple(round(c, 4) for c in prim.positions[i]) + tuple(round(c, 5) for c in prim.uvs[i])
                other = seen.setdefault(key, me)
                if other != me:
                    parent[find(me)] = find(other)
    return len({find(i) for i in range(count)})


def analyse_uvs(uv, side=SIZE, sample=SUPERSAMPLE):
    """Coverage and overlap from a raster at side * sample samples per side; both counted in texels of the `side` grid."""
    hits, _ = rasterize(uv, side * sample)
    blocks = hits.reshape(side, sample, side, sample)
    covered = blocks.max(axis=(1, 3)) >= 1
    overlapped = blocks.max(axis=(1, 3)) >= 2
    area = float(np.abs(0.5 * ((uv[:, 1, 0] - uv[:, 0, 0]) * (uv[:, 2, 1] - uv[:, 0, 1])
                                 - (uv[:, 1, 1] - uv[:, 0, 1]) * (uv[:, 2, 0] - uv[:, 0, 0]))).sum())
    return {"covered": int(covered.sum()), "overlapped": int(overlapped.sum()), "texels": side * side, "uv_area": area,
            "degenerate": int((np.abs(0.5 * ((uv[:, 1, 0] - uv[:, 0, 0]) * (uv[:, 2, 1] - uv[:, 0, 1])
                                              - (uv[:, 1, 1] - uv[:, 0, 1]) * (uv[:, 2, 0] - uv[:, 0, 0]))) < 1e-9).sum())}


# ------------------------------------------------------------------------------------------------ the palette
def bleed(colour, mask, texels):
    """Push each covered texel's colour outward `texels` times (mean of the covered 8-neighbours), so bilinear and mip lookups at an
    island's edge find its own colour. Returns the colour and the grown mask."""
    colour, mask = colour.copy(), mask.copy()
    for _ in range(texels):
        padded_c = np.pad(colour * mask[..., None], ((1, 1), (1, 1), (0, 0)))
        padded_m = np.pad(mask.astype(np.float64), 1)
        total = np.zeros_like(colour)
        count = np.zeros(mask.shape)
        h, w = mask.shape
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                total += padded_c[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
                count += padded_m[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
        fill = (~mask) & (count > 0)
        colour[fill] = total[fill] / count[fill][:, None]
        mask = mask | fill
    return colour, mask


def bake_palette(uv, rgba, size, bleed_texels, ao=None, ao_strength=AO_STRENGTH):
    """The palette as an (size, size, 4) uint8 array, plus the covered-texel mask before bleeding. `rgba` is per corner: linear light and
    the occlusion weight (triangle_arrays); `ao` (size, size) in 0..1, top row first, multiplies a texel by 1 - strength * (1 - ao) * weight."""
    hits, image = rasterize(uv, size * SUPERSAMPLE, rgba)
    sub = (hits >= 1)
    blocks = image.reshape(size, SUPERSAMPLE, size, SUPERSAMPLE, 4) * sub.reshape(size, SUPERSAMPLE, size, SUPERSAMPLE, 1)
    count = sub.reshape(size, SUPERSAMPLE, size, SUPERSAMPLE).sum(axis=(1, 3))
    covered = count > 0
    mean = np.zeros((size, size, 4))
    mean[covered] = blocks.sum(axis=(1, 3))[covered] / count[covered][:, None]
    colour = mean[..., :3]
    if ao is not None:
        colour = colour * (1.0 - ao_strength * (1.0 - ao) * mean[..., 3])[..., None]
    colour, grown = bleed(colour, covered, bleed_texels)
    out = np.zeros((size, size, 4), np.uint8)
    out[..., :3] = np.round(linear_to_srgb(colour) * 255.0).astype(np.uint8)
    out[..., 3] = np.where(grown, 255, 0)
    out[~grown, :3] = 0
    return out, covered


# ------------------------------------------------------------------------------------------------ Blender side
def load_model(glb_path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(glb_path))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise Failure("the GLB has no mesh")
    if len(meshes) > 1:  # the importer normally merges the primitives into one object; if not, join them (slot order is then checked)
        bpy.ops.object.select_all(action="DESELECT")
        for o in meshes:
            o.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
    return next(o for o in bpy.data.objects if o.type == "MESH")


def smart_unwrap(obj, angle_limit, island_margin, name):
    """One Smart UV Project over every face of the creature (all slots at once), islands packed into 0..1 with no overlap."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(angle_limit), island_margin=island_margin, margin_method=MARGIN_METHOD)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.name = obj.data.name = name


def gradient_range(obj):
    """(min, max) of the red channel of the model's vertex colour (the Surface pass gradient, imported from COLOR_0 as the active
    colour attribute, which the GLB export writes back), or None when the input carries none."""
    mesh = obj.data
    attribute = mesh.color_attributes.active_color or (mesh.color_attributes[0] if mesh.color_attributes else None)
    if attribute is None:
        return None
    values = np.zeros(len(attribute.data) * 4, dtype=np.float32)
    attribute.data.foreach_get("color", values)
    red = values.reshape(-1, 4)[:, 0]
    return float(red.min()), float(red.max())


def export_files(folder, sid, with_colour):
    """GLB and FBX with species_bodies.build's own settings."""
    extra = {"export_vertex_color": "ACTIVE"} if with_colour else {}
    bpy.ops.export_scene.gltf(filepath=str(folder / ("%s.glb" % sid)), export_format="GLB", export_apply=True, export_animations=False,
                              export_yup=True, use_selection=False, export_materials="EXPORT", export_lights=False, export_cameras=False,
                              **extra)
    bpy.ops.export_scene.fbx(filepath=str(folder / ("%s.fbx" % sid)), use_selection=False, apply_scale_options="FBX_SCALE_ALL",
                             mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="AUTO")


def bake_ao(obj, size, samples, distance):
    """Cycles ambient occlusion baked into the creature's UV layout: an (size, size) array in 0..1, top row first (the PNG's order)."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = False
    world = bpy.data.worlds.new("AOWorld")
    world.light_settings.distance = distance
    scene.world = world
    image = bpy.data.images.new("ao_target", size, size, alpha=False, float_buffer=True)
    image.generated_color = (1.0, 1.0, 1.0, 1.0)
    image.colorspace_settings.name = "Non-Color"
    for slot in obj.material_slots:
        tree = slot.material.node_tree
        node = tree.nodes.new("ShaderNodeTexImage")
        node.image = image
        tree.nodes.active = node
        node.select = True
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    scene.render.bake.margin = max(2, BLEED + 2)
    scene.render.bake.margin_type = "EXTEND"
    scene.render.bake.use_clear = False
    bpy.ops.object.bake(type="AO")
    pixels = np.zeros(size * size * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    ao = pixels.reshape(size, size, 4)[..., 0]
    return np.clip(ao[::-1], 0.0, 1.0).astype(np.float64)  # Blender's image rows run bottom to top, the PNG's top to bottom


def soften(ao, mask):
    """One 3x3 mean over the covered texels only, so the 16-sample noise of a low-sample bake does not print into the palette."""
    padded = np.pad(ao * mask, 1)
    weight = np.pad(mask.astype(np.float64), 1)
    h, w = ao.shape
    total = sum(padded[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy in (-1, 0, 1) for dx in (-1, 0, 1))
    count = sum(weight[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy in (-1, 0, 1) for dx in (-1, 0, 1))
    return np.where(count > 0, total / np.maximum(count, 1), 1.0)


# ------------------------------------------------------------------------------------------------ one species
def check_species(before, after, uv_stats, uv, palette_shape, size):
    """Every failed check as a short message."""
    problems = []
    if uv.size and (uv.min() < -UV_SLACK or uv.max() > 1.0 + UV_SLACK):
        problems.append("uv outside 0..1 (%.4f..%.4f)" % (uv.min(), uv.max()))
    overlap = 100.0 * uv_stats["overlapped"] / max(uv_stats["covered"], 1)
    if overlap >= OVERLAP_LIMIT:
        problems.append("uv overlap %.2f%% of the covered texels (limit %.0f%%)" % (overlap, OVERLAP_LIMIT))
    if after["tris"] != before["tris"]:
        problems.append("triangles %d -> %d" % (before["tris"], after["tris"]))
    if after["names"] != before["names"]:
        problems.append("slots %s -> %s" % (",".join(before["names"]), ",".join(after["names"])))
    if after["per_slot"] != before["per_slot"]:
        problems.append("triangles per slot changed")
    drift = max(abs(a - b) for a, b in zip(before["lo"] + before["hi"], after["lo"] + after["hi"]))
    if drift > BOUNDS_SLACK:
        problems.append("bounds moved by %.5f (height or pivot)" % drift)
    shade = shading_drift(before["normals"], after["normals"])
    if shade > SHADING_SLACK:
        problems.append("shading changed (%.1f%% of the normals differ from the input's)" % (100 * shade))
    if palette_shape != (size, size, 4):
        problems.append("palette is %s, not %dx%d" % ("x".join(map(str, palette_shape[:2])), size, size))
    if uv_stats["degenerate"]:
        problems.append("%d zero-area uv triangle(s)" % uv_stats["degenerate"])
    return problems


def notes_line(info, args):
    gradient = ("the COLOR_0 gradient %.2f to %.2f" % info["gradient"]) if info["gradient"] else "no vertex gradient in the input"
    ao = (", and a soft Cycles AO (%d samples, strength %g, reach %g of the height, 3x3 softened)" % (args.ao_samples, args.ao_strength, args.ao_distance)
          if args.ao else "")
    return ("%s %s: Smart UV Project over the whole creature (angle limit %g degrees, island margin %g) by %s: %d islands, %.1f percent of the "
            "%d px texture covered, UV overlap %.2f percent. %s_palette.png: %d px, the slot hex from materials.json times %s (multiplied in "
            "linear light, glTF's rule)%s, islands bled %d texels, the space between them transparent. The shared slot textures (fur and the "
            "rest) are not baked in: their tiling does not survive an atlas." % (
                LINE, datetime.date.today().isoformat(), args.angle_limit, args.island_margin, TOOL, info["islands"], info["coverage"],
                args.size, info["overlap"], info["id"], args.size, gradient, ao, args.bleed))


def write_notes(src, dst, line):
    text = src.read_text() if src.is_file() else "# notes\n"
    text = re.sub(r"%s.*" % re.escape(LINE), lambda m: line, text) if LINE in text else text.rstrip("\n") + "\n" + line + "\n"
    dst.write_text(text)


def process(sid, models, out, args):
    started = time.time()
    folder = models / sid
    source = folder / ("%s.glb" % sid)
    if not source.is_file():
        raise Failure("no %s" % source)
    entries = json.loads((folder / "materials.json").read_text()) if (folder / "materials.json").is_file() else []
    before = summarize(source, entries)
    target = out / sid
    target.mkdir(parents=True, exist_ok=True)
    obj = load_model(source)
    smart_unwrap(obj, args.angle_limit, args.island_margin, sid)
    gradient = gradient_range(obj)
    export_files(target, sid, gradient is not None)
    ao = None
    if args.ao:  # after the export: the bake adds image nodes to the materials, which the files should not see
        height = max(before["hi"][1] - before["lo"][1], 1e-6)
        ao = bake_ao(obj, args.size, args.ao_samples, args.ao_distance * height)
    result = target / ("%s.glb" % sid)
    after = summarize(result, entries)
    uv, rgba, slots = triangle_arrays(after["glb"], entries)
    stats = analyse_uvs(uv, args.size)
    if ao is not None:
        ao = soften(ao, rasterize(uv, args.size)[0] > 0)
    palette, covered = bake_palette(uv, rgba, args.size, args.bleed, ao, args.ao_strength)
    (target / ("%s_palette.png" % sid)).write_bytes(png_bytes(palette))
    problems = check_species(before, after, stats, uv, palette.shape, args.size)
    info = {"id": sid, "islands": islands_of(after["glb"]), "coverage": 100.0 * stats["covered"] / stats["texels"],
            "overlap": 100.0 * stats["overlapped"] / max(stats["covered"], 1), "gradient": gradient, "tris": after["tris"],
            "slots": len(slots), "problems": problems, "seconds": time.time() - started,
            "shading_drift": shading_drift(before["normals"], after["normals"])}
    if (folder / "materials.json").is_file() and (folder / "materials.json").resolve() != (target / "materials.json").resolve():
        shutil.copyfile(folder / "materials.json", target / "materials.json")
    write_notes(folder / "notes.md", target / "notes.md", notes_line(info, args))
    return info


# ------------------------------------------------------------------------------------------------ command line
def species_ids(spec, models):
    """Ids from a comma list; 'world1', 'world2' and 'recipes' name the recipe species (species_recipes.ids_for)."""
    ids = []
    for token in [t.strip() for t in spec.split(",") if t.strip()]:
        if token in ("world1", "world2", "recipes") or re.fullmatch(r"batch\d+", token):
            import species_recipes as SR  # noqa: E402
            ids += SR.ids_for("all" if token == "recipes" else token)
        else:
            ids.append(token)
    return list(dict.fromkeys(ids))


def all_species(models):
    return sorted(d.name for d in models.iterdir() if d.is_dir() and d.name != "props" and (d / (d.name + ".glb")).is_file())


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description="UV unwrap and palette bake for the species GLBs")
    who = ap.add_mutually_exclusive_group(required=True)
    who.add_argument("--species", help="comma list of ids, or world1 / world2 / batchN / recipes (the recipe species)")
    who.add_argument("--all", action="store_true", help="every species folder under --models (props excluded)")
    ap.add_argument("--models", default=str(MODELS), help="models folder (default assets/models)")
    ap.add_argument("--out", help="output folder, laid out like --models: <out>/<Id>/<Id>.glb ... (required unless --write-assets)")
    ap.add_argument("--write-assets", action="store_true",
                    help="write the results over --models itself (assets/models by default); without it --out may not be assets/models")
    ap.add_argument("--angle-limit", type=float, default=ANGLE_LIMIT, help="Smart UV Project angle limit in degrees (default %(default)s)")
    ap.add_argument("--island-margin", type=float, default=ISLAND_MARGIN, help="space between islands as a share of 0..1 (default %(default)s)")
    ap.add_argument("--size", type=int, default=SIZE, help="palette side in px (default %(default)s)")
    ap.add_argument("--bleed", type=int, default=BLEED, help="texels each island is bled outward (default %(default)s)")
    ap.add_argument("--ao", action="store_true", help="multiply a soft Cycles ambient-occlusion bake into the palette (off by default)")
    ap.add_argument("--ao-samples", type=int, default=AO_SAMPLES, help="Cycles samples for --ao (default %(default)s)")
    ap.add_argument("--ao-strength", type=float, default=AO_STRENGTH, help="how much of the AO shows, 0..1 (default %(default)s)")
    ap.add_argument("--ao-distance", type=float, default=AO_DISTANCE, help="AO reach as a share of the creature's height (default %(default)s)")
    ap.add_argument("--report", help="also write a JSON summary (the settings and one object per species: islands, coverage, overlap, problems) to this file")
    args = ap.parse_args(argv)
    if not 16 <= args.size <= 4096:
        ap.error("--size must be between 16 and 4096")
    if not 0.0 <= args.island_margin < 0.2:
        ap.error("--island-margin must be between 0 and 0.2")
    if not 0.0 <= args.ao_strength <= 1.0:
        ap.error("--ao-strength must be between 0 and 1")
    return args, ap


def inside(path, parent):
    path, parent = path.resolve(), parent.resolve()
    return path == parent or parent in path.parents


def main():
    args, ap = parse_args()
    models = pathlib.Path(args.models)
    models = models if models.is_absolute() else pathlib.Path.cwd() / models
    if args.write_assets:
        if args.out and pathlib.Path(args.out).resolve() != models.resolve():
            ap.error("--write-assets writes over --models itself; drop --out")
        out = models
    else:
        if not args.out:
            ap.error("--out is required (or --write-assets to write over --models)")
        out = pathlib.Path(args.out)
        out = out if out.is_absolute() else pathlib.Path.cwd() / out
        if inside(out, MODELS) or inside(out, models):
            ap.error("refusing to write into %s without --write-assets; use a scratch --out" % out)
    ids = all_species(models) if args.all else species_ids(args.species, models)
    if not ids:
        ap.error("no species to process under %s" % models)
    results, failed = [], []
    for sid in ids:
        try:
            info = process(sid, models, out, args)
        except Exception as exc:  # noqa: BLE001
            failed.append(sid)
            results.append({"id": sid, "problems": ["%s: %s" % (type(exc).__name__, exc)], "islands": 0, "coverage": 0.0, "overlap": 0.0})
            print("%-11s FAILED: %s" % (sid, exc), flush=True)
            continue
        results.append(info)
        verdict = "ok" if not info["problems"] else "FAIL (%s)" % "; ".join(info["problems"])
        print("%-11s %s  tris=%d slots=%d islands=%d coverage=%.1f%% overlap=%.2f%% gradient=%s ao=%s  %.1fs" % (
            sid, verdict, info["tris"], info["slots"], info["islands"], info["coverage"], info["overlap"],
            "%.2f..%.2f" % info["gradient"] if info["gradient"] else "none", "on" if args.ao else "off", info["seconds"]), flush=True)
        if info["problems"]:
            failed.append(sid)
    if args.report:
        settings = {k: getattr(args, k) for k in ("angle_limit", "island_margin", "size", "bleed", "ao", "ao_samples", "ao_strength", "ao_distance")}
        pathlib.Path(args.report).write_text(json.dumps({"tool": TOOL, "settings": settings, "species": results}, indent=2, default=list) + "\n")
    if results:
        good = [r for r in results if r["id"] not in failed]
        if good:
            print("islands %d..%d (mean %.0f), coverage %.1f..%.1f%% (mean %.1f%%), %d species" % (
                min(r["islands"] for r in good), max(r["islands"] for r in good), sum(r["islands"] for r in good) / len(good),
                min(r["coverage"] for r in good), max(r["coverage"] for r in good), sum(r["coverage"] for r in good) / len(good), len(good)))
    if failed:
        print("failed: %s" % ", ".join(dict.fromkeys(failed)))
        sys.exit(1)


if __name__ == "__main__":
    main()
