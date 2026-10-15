#!/usr/bin/env python3
"""Turn a species model folder into a Blockbench project (.bbmodel) the owner can paint, rig and animate.

Reads assets/models/<Id>/<Id>.glb (a pure-Python GLB reader, no Blender) and materials.json, and writes a Generic Model
project in Blockbench format 5.0 (docs/vault/06-art-pipelines/Model-Toolchain.md section 3.1 is the schema):

* one `mesh` element per material slot, vertices welded by position and normal (so smooth surfaces stay connected and
  hard edges stay cut), one triangle per face, every face on texture 0;
* one `group` per slot, named after the slot, its origin at the slot's surface centroid (area weighted), the groups
  top level and in slot order, so a rig is built by hand by dragging groups into each other;
* the texture, embedded as a base64 PNG, one of two kinds. When a `<Id>_palette.png` sits next to the GLB (tools/blender/unwrap_bake.py
  writes it together with a re-unwrapped GLB: real, non-overlapping islands in 0..1, the slot colours and the gradient baked in) the
  project's texture is that PNG at its own resolution and every face keeps the GLB's own UVs (u times the width, v times the height;
  glTF and Blockbench both count v from the top). Otherwise the flat fallback: a palette of 128 by 128 (`--size`), a block of each
  slot's materials.json hex in a grid, with each slot's UVs fitted into its block, so the file opens already coloured; those UVs are
  the GLB's own per-primitive UVs (some are tiled past 0..1 and overlap), so detail painting wants the unwrap first. `--flat` takes
  the fallback even when a palette PNG is there;
* `meta.model_format "free"` (Generic Model), `box_uv false`, `resolution` equal to the texture size;
* one example animation, `idle`: a 2 s loop with a small position bob on the Body group, to show how animators and
  keyframes are shaped (`--no-idle` writes an empty `animations` list instead). The other slot groups are siblings, so
  they do not move until they are dragged under Body.

Unit rule (the note's sections 1 and 3.1): Blockbench writes glTF positions divided by its export scale, 16 by default,
so this tool multiplies GLB positions by 16 and copies the axes as they are (Y up, no flip, the inverse of Blockbench's
own exporter). The species GLBs are 1 unit = 1 stud, so that is 16 Blockbench units per stud, and a Blockbench glTF
export at the default scale 16 comes back at the same scale. The creature's face is on +Z in the GLB and stays there
(Blockbench's own "forward" is -Z): do not rotate the model to fix it. The metre-to-stud factor is the Mac probe's.

Vertex colours (COLOR_0) are read but not written: a Blockbench mesh has no colour attribute, the palette carries the
colour (the baked palette carries the gradient too). Output is deterministic (uuids are derived from names). Paths are relative to the repo root.

Usage (run from anywhere; standard library plus Pillow for the PNG, and a built-in encoder when Pillow is missing):
  python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox            writes media/blockbench/Sparkfox.bbmodel
  python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox --models /scratch/uvbake --out /scratch/bb     reads Sparkfox_palette.png
  python3 -I tools/blockbench/to_bbmodel.py --all --out /tmp/bb           every species folder under assets/models
  python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox --check    re-reads the written file and validates it
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import math
import re
import struct
import sys
import uuid
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MODELS = "assets/models"
DEFAULT_OUT = "media/blockbench"

FORMAT_VERSION = "5.0"          # Blockbench 5.2.2's FORMATV
UNITS_PER_GLTF_UNIT = 16        # Blockbench's default glTF export scale
TEXTURE_SIZE = 128
GUTTER = 1                      # pixels kept clear inside each palette block
IDLE_LENGTH = 2.0
IDLE_BOB_FRACTION = 0.02        # the bob's height as a share of the model's height
IDLE_BOB_MIN = 0.25             # Blockbench units
NAMESPACE = uuid.UUID("b3d4a2c0-5b1e-4c1f-9a77-0f2d6a1e8c11")
CHANNELS = ("position", "rotation", "scale")
INTERPOLATIONS = ("linear", "catmullrom", "bezier", "step")
CUBE_FACES = ("north", "east", "south", "west", "up", "down")

COMPONENT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NORMALISER = {"b": 127.0, "B": 255.0, "h": 32767.0, "H": 65535.0, "I": 4294967295.0}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
IDENTITY = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]


class ToolError(ValueError):
    """A message for the person running the tool (bad input, bad file)."""


# --------------------------------------------------------------------------------------------- GLB reader


class Primitive:
    """One glTF primitive in world space: per-vertex lists plus triangles as index triples."""

    def __init__(self, material, positions, normals, uvs, colors, triangles):
        self.material = material      # glTF material index or None
        self.positions = positions    # [(x, y, z)] in glTF units
        self.normals = normals        # [(x, y, z)] or None
        self.uvs = uvs                # [(u, v)] or None
        self.colors = colors          # [(r, g, b[, a])] or None (read, not written)
        self.triangles = triangles    # [(i, j, k)], counter-clockwise seen from the front


class Glb:
    def __init__(self, name, materials, primitives):
        self.name = name
        self.materials = materials    # the glTF material dicts
        self.primitives = primitives

    @property
    def triangle_count(self):
        return sum(len(p.triangles) for p in self.primitives)


def parse_container(data):
    """The JSON document and the BIN chunk (or None) of a GLB."""
    if len(data) < 20 or data[:4] != b"glTF":
        raise ToolError("not a GLB (no glTF header)")
    version, length = struct.unpack_from("<II", data, 4)
    if version != 2:
        raise ToolError("GLB version %d is not supported (2 only)" % version)
    if length > len(data):
        raise ToolError("GLB is truncated (header says %d bytes, file has %d)" % (length, len(data)))
    doc = binary = None
    offset = 12
    while offset + 8 <= length:
        size, kind = struct.unpack_from("<I4s", data, offset)
        body = data[offset + 8:offset + 8 + size]
        if len(body) != size:
            raise ToolError("GLB chunk runs past the end of the file")
        if kind == b"JSON" and doc is None:
            doc = json.loads(body.decode("utf-8"))
        elif kind == b"BIN\x00" and binary is None:
            binary = body
        offset += 8 + size
    if doc is None:
        raise ToolError("GLB has no JSON chunk")
    return doc, binary


def load_buffers(doc, binary):
    buffers = []
    for index, buf in enumerate(doc.get("buffers", [])):
        uri = buf.get("uri")
        if uri is None:
            if index != 0 or binary is None:
                raise ToolError("buffer %d has no data (only buffer 0 may use the BIN chunk)" % index)
            buffers.append(binary)
        elif uri.startswith("data:"):
            buffers.append(base64.b64decode(uri.split(",", 1)[1]))
        else:
            raise ToolError("buffer %d uses an external file (%s); embed it in the GLB" % (index, uri))
    return buffers


def read_accessor(doc, buffers, index):
    """Every element of an accessor as a tuple (floats, or ints for integer types)."""
    acc = doc["accessors"][index]
    if "sparse" in acc:
        raise ToolError("accessor %d is sparse, which this reader does not support" % index)
    if acc["componentType"] not in COMPONENT or acc["type"] not in WIDTH:
        raise ToolError("accessor %d has an unsupported type" % index)
    fmt, size = COMPONENT[acc["componentType"]]
    width = WIDTH[acc["type"]]
    count = acc["count"]
    if "bufferView" not in acc:
        return [(0,) * width] * count
    view = doc["bufferViews"][acc["bufferView"]]
    data = buffers[view["buffer"]]
    stride = view.get("byteStride") or width * size
    base = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    if count and base + (count - 1) * stride + width * size > len(data):
        raise ToolError("accessor %d reads past the end of its buffer" % index)
    rows = [struct.unpack_from("<" + fmt * width, data, base + i * stride) for i in range(count)]
    if acc.get("normalized") and fmt != "f":
        top = NORMALISER[fmt]
        rows = [tuple(max(c / top, -1.0) for c in row) for row in rows]
    return rows


def node_matrix(node):
    """A node's local transform as a column-major 4x4 (its matrix, or translation * rotation * scale)."""
    if "matrix" in node:
        return [float(v) for v in node["matrix"]]
    tx, ty, tz = node.get("translation", (0, 0, 0))
    x, y, z, w = node.get("rotation", (0, 0, 0, 1))
    norm = math.sqrt(x * x + y * y + z * z + w * w) or 1.0
    x, y, z, w = x / norm, y / norm, z / norm, w / norm
    sx, sy, sz = node.get("scale", (1, 1, 1))
    rot = ((1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)),
           (2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)),
           (2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)))
    m = [0.0] * 16
    for col, scale in enumerate((sx, sy, sz)):
        for row in range(3):
            m[col * 4 + row] = rot[row][col] * scale
    m[12], m[13], m[14], m[15] = tx, ty, tz, 1.0
    return m


def mat_mul(a, b):
    return [sum(a[k * 4 + r] * b[c * 4 + k] for k in range(4)) for c in range(4) for r in range(4)]


def transform_point(m, p):
    x, y, z = p
    return (m[0] * x + m[4] * y + m[8] * z + m[12], m[1] * x + m[5] * y + m[9] * z + m[13], m[2] * x + m[6] * y + m[10] * z + m[14])


def transform_direction(m, d):
    """A direction through the matrix's linear part, renormalised (right for rotations and uniform scales)."""
    x, y, z = d
    v = (m[0] * x + m[4] * y + m[8] * z, m[1] * x + m[5] * y + m[9] * z, m[2] * x + m[6] * y + m[10] * z)
    length = math.sqrt(sum(c * c for c in v)) or 1.0
    return (v[0] / length, v[1] / length, v[2] / length)


def determinant3(m):
    return m[0] * (m[5] * m[10] - m[9] * m[6]) - m[4] * (m[1] * m[10] - m[9] * m[2]) + m[8] * (m[1] * m[6] - m[5] * m[2])


def scene_nodes(doc):
    """(node, world matrix) for every node reachable from the scene, parents first."""
    nodes = doc.get("nodes", [])
    scenes = doc.get("scenes", [])
    if scenes:
        roots = scenes[doc.get("scene", 0)].get("nodes", [])
    else:
        children = {c for n in nodes for c in n.get("children", [])}
        roots = [i for i in range(len(nodes)) if i not in children]
    found = []

    def visit(index, parent, path):
        if index in path:
            raise ToolError("node %d is its own ancestor" % index)
        node = nodes[index]
        world = mat_mul(parent, node_matrix(node))
        found.append((node, world))
        for child in node.get("children", []):
            visit(child, world, path | {index})

    for root in roots:
        visit(root, IDENTITY, frozenset())
    return found


def read_primitive(doc, buffers, prim, world):
    if prim.get("mode", 4) != 4:
        raise ToolError("primitive mode %s is not triangles" % prim.get("mode"))
    attrs = prim["attributes"]
    positions = [transform_point(world, p) for p in read_accessor(doc, buffers, attrs["POSITION"])]
    normals = uvs = colors = None
    if "NORMAL" in attrs:
        normals = [transform_direction(world, n) for n in read_accessor(doc, buffers, attrs["NORMAL"])]
    if "TEXCOORD_0" in attrs:
        uvs = [(row[0], row[1]) for row in read_accessor(doc, buffers, attrs["TEXCOORD_0"])]
    if "COLOR_0" in attrs:
        colors = read_accessor(doc, buffers, attrs["COLOR_0"])
    if "indices" in prim:
        flat = [row[0] for row in read_accessor(doc, buffers, prim["indices"])]
    else:
        flat = list(range(len(positions)))
    if len(flat) % 3:
        raise ToolError("primitive index count %d is not a multiple of 3" % len(flat))
    if flat and max(flat) >= len(positions):
        raise ToolError("primitive index %d is past its %d vertices" % (max(flat), len(positions)))
    triangles = [(flat[i], flat[i + 1], flat[i + 2]) for i in range(0, len(flat), 3)]
    if determinant3(world) < 0:  # a mirrored node turns the faces inside out; put the winding right
        triangles = [(a, c, b) for a, b, c in triangles]
    return Primitive(prim.get("material"), positions, normals, uvs, colors, triangles)


def read_glb(path):
    data = Path(path).read_bytes()
    doc, binary = parse_container(data)
    buffers = load_buffers(doc, binary)
    primitives = []
    meshes = doc.get("meshes", [])
    for node, world in scene_nodes(doc):
        if "mesh" in node:
            for prim in meshes[node["mesh"]]["primitives"]:
                primitives.append(read_primitive(doc, buffers, prim, world))
    if not primitives:
        raise ToolError("the GLB has no mesh in its scene")
    return Glb(Path(path).stem, doc.get("materials", []), primitives)


# --------------------------------------------------------------------------------------------- slots and colours


class Slot:
    def __init__(self, name, material, hex_colour, primitives):
        self.name = name              # the group name (the material name, made safe)
        self.material = material      # glTF material index or None
        self.hex = hex_colour         # "RRGGBB"
        self.primitives = primitives


def safe_name(raw):
    """Blockbench bone names want unique ASCII letters, digits and underscores (Model-Toolchain section 2, gotcha 4)."""
    return re.sub(r"[^A-Za-z0-9_]", "_", raw) or "Slot"


def linear_to_srgb_byte(value):
    value = min(max(value, 0.0), 1.0)
    value = 12.92 * value if value <= 0.0031308 else 1.055 * value ** (1 / 2.4) - 0.055
    return int(round(value * 255))


def slot_colour(material_index, material, entries_by_name, entries_by_slot):
    """materials.json hex when the slot is listed (by name, then by 1-based position); else the glTF base colour."""
    entry = entries_by_name.get((material or {}).get("name")) or entries_by_slot.get((material_index or 0) + 1)
    if entry is not None:
        hex_colour = str(entry.get("hex", "")).lstrip("#")
        if not re.fullmatch(r"[0-9A-Fa-f]{6}", hex_colour):
            raise ToolError("materials.json slot %r has no six-digit hex" % entry.get("name"))
        return hex_colour.upper()
    base = ((material or {}).get("pbrMetallicRoughness") or {}).get("baseColorFactor", [1, 1, 1, 1])
    return "".join("%02X" % linear_to_srgb_byte(c) for c in base[:3])


def build_slots(glb, entries):
    """One slot per used material, in material order; primitives sharing a material share a slot."""
    by_name = {e.get("name"): e for e in entries}
    by_slot = {e.get("slot"): e for e in entries}
    groups = {}
    for prim in glb.primitives:
        groups.setdefault(prim.material, []).append(prim)
    slots, taken = [], set()
    for material_index in sorted(groups, key=lambda m: (m is None, m or 0)):
        material = glb.materials[material_index] if material_index is not None else None
        name = safe_name((material or {}).get("name") or "Unassigned")
        base, count = name, 1
        while name in taken:
            count += 1
            name = "%s_%d" % (base, count)
        taken.add(name)
        slots.append(Slot(name, material_index, slot_colour(material_index, material, by_name, by_slot), groups[material_index]))
    return slots


# --------------------------------------------------------------------------------------------- palette texture


def palette_layout(count, size):
    """Pixel rectangles (x0, y0, x1, y1), one square block per slot, row by row."""
    cols = max(1, math.ceil(math.sqrt(count)))
    cell = size // cols
    return [((i % cols) * cell, (i // cols) * cell, (i % cols + 1) * cell, (i // cols + 1) * cell) for i in range(count)]


def encode_png_plain(width, height, rgba):
    """A minimal RGBA PNG (no filtering) for machines without Pillow."""
    def chunk(tag, body):
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xFFFFFFFF)
    rows = b"".join(b"\x00" + bytes(rgba[y * width * 4:(y + 1) * width * 4]) for y in range(height))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b""))


def encode_png(width, height, rgba):
    try:
        from PIL import Image
    except ImportError:
        return encode_png_plain(width, height, rgba)
    out = io.BytesIO()
    Image.frombytes("RGBA", (width, height), bytes(rgba)).save(out, "PNG", optimize=True)
    return out.getvalue()


def palette_pixels(slots, rects, size):
    """RGBA bytes: each slot's colour fills its whole block; the rest stays transparent."""
    pixels = bytearray(size * size * 4)
    for slot, (x0, y0, x1, y1) in zip(slots, rects):
        rgba = bytes(int(slot.hex[i:i + 2], 16) for i in (0, 2, 4)) + b"\xff"
        row = rgba * (x1 - x0)
        for y in range(y0, y1):
            pixels[(y * size + x0) * 4:(y * size + x1) * 4] = row
    return pixels


def png_size(data):
    """(width, height) of a PNG, from its signature and a CRC-checked IHDR; ToolError when it is not one."""
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ToolError("texture is not a PNG")
    if zlib.crc32(data[12:29]) & 0xFFFFFFFF != struct.unpack(">I", data[29:33])[0]:
        raise ToolError("texture PNG header fails its CRC")
    return struct.unpack(">II", data[16:24])


# --------------------------------------------------------------------------------------------- project writer


def uid(species, *parts):
    return str(uuid.uuid5(NAMESPACE, "/".join((species,) + parts)))


def base36(n, width):
    digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    out = ""
    while n:
        n, r = divmod(n, 36)
        out = digits[r] + out
    return out.rjust(width, "0")


def uv_mapper(rect, uvs):
    """A function fitting this slot's UVs (uniform scale, centred) inside its palette block, inset by the gutter."""
    x0, y0, x1, y1 = rect
    gutter = GUTTER if min(x1 - x0, y1 - y0) > 2 * GUTTER else 0
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    room = min(x1 - x0, y1 - y0) - 2 * gutter
    if not uvs:
        return lambda uv: (cx, cy)
    us, vs = [uv[0] for uv in uvs], [uv[1] for uv in uvs]
    extent = max(max(us) - min(us), max(vs) - min(vs))
    if extent < 1e-9:
        return lambda uv: (cx, cy)
    scale = room / extent
    mid_u, mid_v = (max(us) + min(us)) / 2.0, (max(vs) + min(vs)) / 2.0
    return lambda uv: (round(cx + (uv[0] - mid_u) * scale, 3), round(cy + (uv[1] - mid_v) * scale, 3))


def triangle_area_and_centre(a, b, c):
    cross = ((b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1]),
             (b[2] - a[2]) * (c[0] - a[0]) - (b[0] - a[0]) * (c[2] - a[2]),
             (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]))
    return 0.5 * math.sqrt(sum(v * v for v in cross)), [(a[i] + b[i] + c[i]) / 3.0 for i in range(3)]


def slot_uvs(slot):
    """Every UV a slot's triangles use."""
    return [p.uvs[i] for p in slot.primitives if p.uvs for tri in p.triangles for i in tri]


def direct_mapper(width, height):
    """The baked palette's mapping: the GLB's UVs as they are, in pixels (both glTF and Blockbench count v from the top), clamped to
    the texture (a float32 rounding error past 0 or 1 is under a thousandth of a pixel)."""
    return lambda uv: (round(min(max(uv[0], 0.0), 1.0) * width, 3), round(min(max(uv[1], 0.0), 1.0) * height, 3))


def build_mesh(slot, fit):
    """(vertices, faces, centroid) for one slot, in Blockbench units; `fit` maps a GLB uv to the texture's pixels."""
    vertices, faces, welded = {}, {}, {}
    area_sum, weighted = 0.0, [0.0, 0.0, 0.0]

    def new_vertex(point):
        key = "v" + base36(len(vertices), 3)
        vertices[key] = list(point)
        return key

    for prim in slot.primitives:
        scaled = [tuple(round(c * UNITS_PER_GLTF_UNIT, 4) for c in p) for p in prim.positions]
        for tri in prim.triangles:
            keys = []
            for i in tri:
                normal = tuple(round(c, 2) for c in prim.normals[i]) if prim.normals else None
                weld = (scaled[i], normal)
                key = welded.get(weld)
                if key is None or key in keys:  # unseen, or a corner that collapsed onto another: give it its own vertex
                    key = new_vertex(scaled[i])
                    welded.setdefault(weld, key)
                keys.append(key)
            uv = {key: list(fit(prim.uvs[i] if prim.uvs else (0.0, 0.0))) for key, i in zip(keys, tri)}
            faces["f" + base36(len(faces), 7)] = {"vertices": keys, "uv": uv, "texture": 0}
            area, centre = triangle_area_and_centre(*(scaled[i] for i in tri))
            area_sum += area
            for axis in range(3):
                weighted[axis] += area * centre[axis]
    if area_sum > 0:
        centroid = [round(w / area_sum, 4) for w in weighted]
    else:
        points = list(vertices.values())
        centroid = [round(sum(p[axis] for p in points) / len(points), 4) for axis in range(3)]
    return vertices, faces, centroid


def idle_animation(species, group_uuid, group_name, height):
    """The example: a position bob on one group, 0 to the lift and back over IDLE_LENGTH, catmull-rom, looping."""
    lift = round(max(height * IDLE_BOB_FRACTION, IDLE_BOB_MIN), 2)

    def key(tag, time, y):
        return {"channel": "position", "data_points": [{"x": "0", "y": "%g" % y, "z": "0"}], "uuid": uid(species, "idle", tag),
                "time": time, "color": -1, "interpolation": "catmullrom"}

    return {"uuid": uid(species, "animation", "idle"), "name": "idle", "loop": "loop", "override": False, "length": IDLE_LENGTH,
            "snapping": 24, "selected": False, "anim_time_update": "", "blend_weight": "", "start_delay": "", "loop_delay": "",
            "animators": {group_uuid: {"name": group_name, "type": "bone",
                                       "keyframes": [key("k0", 0, 0), key("k1", IDLE_LENGTH / 2, lift), key("k2", IDLE_LENGTH, 0)]}}}


def check_baked_uvs(slots):
    """A baked palette only fits a GLB whose UVs are inside 0..1 (the unwrap's); otherwise ToolError."""
    for slot in slots:
        for u, v in slot_uvs(slot):
            if not (-1e-5 <= u <= 1 + 1e-5 and -1e-5 <= v <= 1 + 1e-5):
                raise ToolError("the GLB's uvs leave 0..1 (slot %s), so a baked palette does not fit it: run tools/blender/unwrap_bake.py "
                                "first, or pass --flat" % slot.name)


def build_project(species, glb, entries, size=TEXTURE_SIZE, idle=True, palette=None):
    """The whole .bbmodel document as a dict. `palette` is the bytes of a baked <Id>_palette.png (the texture then, at its own
    resolution, with the GLB's UVs as they are), or None for the flat fallback palette of `size` pixels."""
    slots = build_slots(glb, entries)
    elements, groups, outliner, tops = [], [], [], []
    if palette is not None:
        width, height = png_size(palette)
        check_baked_uvs(slots)
        fits, png, name = [direct_mapper(width, height)] * len(slots), palette, species + "_palette.png"
    else:
        width = height = size
        rects = palette_layout(len(slots), size)
        fits, png, name = [uv_mapper(rect, slot_uvs(slot)) for slot, rect in zip(slots, rects)], None, species + ".png"
    for index, (slot, fit) in enumerate(zip(slots, fits)):
        vertices, faces, centroid = build_mesh(slot, fit)
        tops.append(max(v[1] for v in vertices.values()))
        mesh_id, group_id = uid(species, "mesh", slot.name), uid(species, "group", slot.name)
        elements.append({"type": "mesh", "uuid": mesh_id, "name": slot.name + "Mesh", "color": index % 8, "origin": [0, 0, 0],
                         "rotation": [0, 0, 0], "shading": "smooth", "export": True, "visibility": True, "locked": False,
                         "render_order": "default", "vertices": vertices, "faces": faces})
        groups.append({"uuid": group_id, "name": slot.name, "origin": centroid, "rotation": [0, 0, 0], "export": True, "isOpen": True,
                       "locked": False, "visibility": True, "autouv": 0, "mirror_uv": False, "shade": True, "color": index % 8})
        outliner.append({"uuid": group_id, "isOpen": True, "children": [mesh_id]})
    if png is None:
        png = encode_png(size, size, palette_pixels(slots, rects, size))
    texture = {"uuid": uid(species, "texture"), "name": name, "path": "", "folder": "", "namespace": "", "id": "0", "group": "",
               "width": width, "height": height, "uv_width": width, "uv_height": height, "particle": False, "use_as_default": False,
               "layers_enabled": False, "sync_to_project": "", "file_format": "png", "render_mode": "default", "render_sides": "auto",
               "wrap_mode": "limited", "pbr_channel": "color", "fps": 7, "frame_time": 1, "frame_order_type": "loop", "frame_order": "",
               "frame_interpolate": False, "visible": True, "internal": True, "saved": False,
               "source": "data:image/png;base64," + base64.b64encode(png).decode("ascii")}
    animations = []
    if idle:
        target = next((g for g in groups if g["name"] == "Body"), groups[0])
        animations.append(idle_animation(species, target["uuid"], target["name"], max(tops)))
    return {"meta": {"format_version": FORMAT_VERSION, "model_format": "free", "box_uv": False}, "name": species,
            "model_identifier": species.lower(), "visible_box": [1, 1, 0], "variable_placeholders": "", "variable_placeholder_buttons": [],
            "timeline_setups": [], "unhandled_root_fields": {}, "resolution": {"width": width, "height": height}, "elements": elements,
            "groups": groups, "outliner": outliner, "textures": [texture], "animations": animations}


# --------------------------------------------------------------------------------------------- checker


def finite(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def check_texture_ref(face, where, texture_count, errors):
    ref = face.get("texture")
    if ref is not None and not (isinstance(ref, int) and not isinstance(ref, bool) and 0 <= ref < texture_count):
        errors.append("%s points at texture %r but the file has %d texture(s)" % (where, ref, texture_count))


def check_mesh(el, where, width, height, texture_count, errors):
    vertices, faces = el.get("vertices"), el.get("faces")
    if not isinstance(vertices, dict) or not isinstance(faces, dict):
        errors.append("%s needs vertices and faces objects" % where)
        return
    for key, point in vertices.items():
        if not (isinstance(point, list) and len(point) == 3 and all(finite(c) for c in point)):
            errors.append("%s: vertex %s is not three numbers" % (where, key))
    for key, face in faces.items():
        spot = "%s face %s" % (where, key)
        ring = face.get("vertices")
        if not (isinstance(ring, list) and len(ring) >= 3):
            errors.append("%s needs at least three vertices" % spot)
            continue
        if len(set(ring)) != len(ring):
            errors.append("%s repeats a vertex" % spot)
        missing = [k for k in ring if k not in vertices]
        if missing:
            errors.append("%s uses missing vertices %s" % (spot, ", ".join(map(str, missing))))
        uv = face.get("uv")
        if not isinstance(uv, dict) or set(uv) != set(ring):
            errors.append("%s needs exactly one uv per vertex" % spot)
        else:
            for k, pair in uv.items():
                if not (isinstance(pair, list) and len(pair) == 2 and all(finite(c) for c in pair)
                        and -1e-6 <= pair[0] <= width + 1e-6 and -1e-6 <= pair[1] <= height + 1e-6):
                    errors.append("%s: uv %s=%r is outside the %dx%d texture" % (spot, k, pair, width, height))
        check_texture_ref(face, spot, texture_count, errors)


def check_cube(el, where, width, height, texture_count, errors):
    faces = el.get("faces")
    if not (isinstance(el.get("from"), list) and isinstance(el.get("to"), list) and isinstance(faces, dict)):
        errors.append("%s needs from, to and faces" % where)
        return
    for name in CUBE_FACES:
        face = faces.get(name)
        if face is None:
            continue
        uv = face.get("uv")
        if not (isinstance(uv, list) and len(uv) == 4 and all(finite(c) for c in uv)
                and all(-1e-6 <= uv[i] <= width + 1e-6 for i in (0, 2)) and all(-1e-6 <= uv[i] <= height + 1e-6 for i in (1, 3))):
            errors.append("%s face %s has a uv outside the texture" % (where, name))
        check_texture_ref(face, "%s face %s" % (where, name), texture_count, errors)


def check_project(project):
    """Every broken invariant of a loaded .bbmodel, as a list of messages (empty when it is sound)."""
    if not isinstance(project, dict):
        return ["the file is not a JSON object"]
    errors = []
    meta = project.get("meta") if isinstance(project.get("meta"), dict) else {}
    if not isinstance(meta.get("format_version"), str):
        errors.append("meta.format_version is missing")
    if meta.get("model_format") != "free":
        errors.append("meta.model_format is %r, not 'free' (Generic Model)" % meta.get("model_format"))
    if meta.get("box_uv") is not False:
        errors.append("meta.box_uv must be false")
    resolution = project.get("resolution") if isinstance(project.get("resolution"), dict) else {}
    width, height = resolution.get("width"), resolution.get("height")
    if not (isinstance(width, int) and isinstance(height, int) and width > 0 and height > 0):
        errors.append("resolution needs a positive integer width and height")
        width = height = 0
    lists = {name: project.get(name) for name in ("textures", "elements", "groups", "animations", "outliner")}
    not_lists = [name for name, value in lists.items() if not isinstance(value, list)]
    if not_lists:
        return errors + ["%s is not a list" % name for name in not_lists]
    textures, elements, groups, animations = lists["textures"], lists["elements"], lists["groups"], lists["animations"]
    seen = {}

    def claim(value, where):
        if not isinstance(value, str) or not value:
            errors.append("%s has no uuid" % where)
        elif value in seen:
            errors.append("uuid %s is used twice (%s and %s)" % (value, seen[value], where))
        else:
            seen[value] = where

    for i, tex in enumerate(textures):
        claim(tex.get("uuid"), "texture %d" % i)
        source = tex.get("source")
        if source is None:
            continue
        try:
            if not source.startswith("data:image/png;base64,"):
                raise ToolError("source is not an embedded PNG data URL")
            size = png_size(base64.b64decode(source.split(",", 1)[1]))
        except (ToolError, ValueError) as exc:
            errors.append("texture %d: %s" % (i, exc))
        else:
            if size != (tex.get("width"), tex.get("height")):
                errors.append("texture %d: the PNG is %dx%d but the entry says %sx%s" % (i, size[0], size[1], tex.get("width"), tex.get("height")))
    element_ids = {}
    for i, el in enumerate(elements):
        where = "element %d (%s)" % (i, el.get("name"))
        claim(el.get("uuid"), where)
        element_ids[el.get("uuid")] = el
        if el.get("type") == "mesh":
            check_mesh(el, where, width, height, len(textures), errors)
        elif el.get("type") == "cube":
            check_cube(el, where, width, height, len(textures), errors)
        else:
            errors.append("%s has type %r (only mesh and cube are checked)" % (where, el.get("type")))
    group_ids, group_names = {}, set()
    for i, group in enumerate(groups):
        name = group.get("name")
        claim(group.get("uuid"), "group %d (%s)" % (i, name))
        group_ids[group.get("uuid")] = group
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_]+", name):
            errors.append("group %d: name %r must be ASCII letters, digits and underscores" % (i, name))
        elif name in group_names:
            errors.append("group name %s is used twice" % name)
        group_names.add(name)
        if not (isinstance(group.get("origin"), list) and len(group["origin"]) == 3 and all(finite(c) for c in group["origin"])):
            errors.append("group %s has no 3-number origin" % name)
    placed = {}

    def walk(nodes, where):
        for node in nodes:
            if isinstance(node, str):
                if node not in element_ids:
                    errors.append("outliner (%s) lists unknown element %s" % (where, node))
                placed[node] = placed.get(node, 0) + 1
            elif isinstance(node, dict) and node.get("uuid") in group_ids:
                placed[node["uuid"]] = placed.get(node["uuid"], 0) + 1
                walk(node.get("children", []), group_ids[node["uuid"]].get("name"))
            else:
                errors.append("outliner (%s) has an entry that is no element and no known group" % where)

    walk(lists["outliner"], "root")
    for key in list(element_ids) + list(group_ids):
        if placed.get(key, 0) != 1:
            errors.append("%s appears %d times in the outliner (needs 1)" % (key, placed.get(key, 0)))
    for i, anim in enumerate(animations):
        claim(anim.get("uuid"), "animation %d" % i)
        length = anim.get("length")
        if not anim.get("name"):
            errors.append("animation %d has no name" % i)
        if not (finite(length) and length > 0):
            errors.append("animation %s needs a positive length" % anim.get("name"))
            length = 0
        for key, animator in (anim.get("animators") or {}).items():
            if key not in group_ids and key not in element_ids:
                errors.append("animation %s animates unknown uuid %s" % (anim.get("name"), key))
            for kf in animator.get("keyframes", []):
                claim(kf.get("uuid"), "a keyframe of %s" % anim.get("name"))
                if kf.get("channel") not in CHANNELS:
                    errors.append("animation %s: keyframe channel %r" % (anim.get("name"), kf.get("channel")))
                if kf.get("interpolation") not in INTERPOLATIONS:
                    errors.append("animation %s: keyframe interpolation %r" % (anim.get("name"), kf.get("interpolation")))
                if not (finite(kf.get("time")) and 0 <= kf["time"] <= length):
                    errors.append("animation %s: keyframe time %r is outside 0..%s" % (anim.get("name"), kf.get("time"), length))
                if not kf.get("data_points"):
                    errors.append("animation %s: a keyframe has no data_points" % anim.get("name"))
    return errors


def check_file(path):
    """Errors for a written .bbmodel file; the JSON must load before anything else is checked."""
    try:
        project = json.loads(Path(path).read_text(encoding="utf-8"))
    except OSError as exc:
        return ["cannot read %s: %s" % (path, exc)]
    except ValueError as exc:
        return ["%s is not valid JSON: %s" % (path, exc)]
    try:
        return check_project(project)
    except (AttributeError, TypeError, KeyError) as exc:  # a field of the wrong shape: report it, do not crash
        return ["%s has a malformed field: %r" % (path, exc)]


# --------------------------------------------------------------------------------------------- command line


def resolve(path):
    path = Path(path)
    return path if path.is_absolute() else ROOT / path


def species_folder(models, species):
    for folder in (models / species, models / "props" / species):
        if (folder / (species + ".glb")).is_file():
            return folder
    raise ToolError("no %s/%s.glb under %s" % (species, species, models))


def all_species(models):
    return sorted(d.name for d in models.iterdir() if d.is_dir() and d.name != "props" and (d / (d.name + ".glb")).is_file())


def load_entries(folder):
    path = folder / "materials.json"
    if not path.is_file():
        return []
    try:
        entries = json.loads(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        raise ToolError("cannot read %s: %s" % (path, exc))
    if not isinstance(entries, list) or not all(isinstance(e, dict) for e in entries):
        raise ToolError("%s must be a list of slot objects" % path)
    return entries


def baked_palette(folder, species):
    """The bytes of <species>_palette.png next to the GLB, or None when there is none."""
    path = folder / (species + "_palette.png")
    if not path.is_file():
        return None
    data = path.read_bytes()
    try:
        png_size(data)
    except ToolError as exc:
        raise ToolError("%s: %s" % (path, exc))
    return data


def write_species(models, species, out, size, idle, flat=False):
    """Write out/<species>.bbmodel; returns (path, summary line). The result is checked before it is written. A baked
    <species>_palette.png next to the GLB is the texture unless `flat`; otherwise the flat palette of `size` pixels."""
    folder = species_folder(models, species)
    glb = read_glb(folder / (species + ".glb"))
    palette = None if flat else baked_palette(folder, species)
    project = build_project(species, glb, load_entries(folder), size, idle, palette)
    problems = check_project(project)
    if problems:
        raise ToolError("%s: the project fails its own check: %s" % (species, problems[0]))
    out.mkdir(parents=True, exist_ok=True)
    target = out / (species + ".bbmodel")
    target.write_text(json.dumps(project, separators=(",", ":")) + "\n", encoding="utf-8")
    faces = sum(len(el["faces"]) for el in project["elements"])
    texture = project["textures"][0]
    return target, "%s: %d meshes, %d faces (GLB %d triangles), %d groups, %dx%d %s" % (
        species, len(project["elements"]), faces, glb.triangle_count, len(project["groups"]), texture["width"], texture["height"],
        "baked palette" if palette is not None else "flat palette")


def check_species(out, species):
    """Print the verdict for out/<species>.bbmodel; returns True when it is sound."""
    target = out / (species + ".bbmodel")
    problems = check_file(target)
    if problems:
        print("to_bbmodel: %s: %d problem(s)" % (target, len(problems)), file=sys.stderr)
        for line in problems[:20]:
            print("  " + line, file=sys.stderr)
        return False
    project = json.loads(target.read_text(encoding="utf-8"))
    print("to_bbmodel: %s: ok (%d meshes, %d faces, %d groups, %d animation(s))" % (
        species, len(project["elements"]), sum(len(e["faces"]) for e in project["elements"]),
        len(project["groups"]), len(project["animations"])))
    return True


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    who = parser.add_mutually_exclusive_group(required=True)
    who.add_argument("--species", nargs="+", metavar="ID", help="species folder name(s), e.g. Sparkfox")
    who.add_argument("--all", action="store_true", help="every species folder under --models (props excluded)")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="write the .bbmodel files (the default)")
    mode.add_argument("--check", action="store_true", help="re-read the written files in --out and validate them; write nothing")
    parser.add_argument("--models", default=DEFAULT_MODELS, help="model folder, relative to the repo root (default %(default)s)")
    parser.add_argument("--out", default=DEFAULT_OUT, help="output folder, relative to the repo root (default %(default)s)")
    parser.add_argument("--size", type=int, default=TEXTURE_SIZE, help="side of the flat fallback palette in pixels (default %(default)s); "
                        "a baked <Id>_palette.png keeps its own size")
    parser.add_argument("--flat", action="store_true", help="write the flat palette even when a <Id>_palette.png sits next to the GLB")
    parser.add_argument("--no-idle", action="store_true", help="write an empty animations list instead of the example idle")
    args = parser.parse_args(argv)
    try:
        models, out = resolve(args.models), resolve(args.out)
        if not 16 <= args.size <= 4096:
            raise ToolError("--size must be between 16 and 4096")
        names = all_species(models) if args.all else args.species
        if not names:
            raise ToolError("no species folders under %s" % models)
        failed = 0
        for species in names:
            if args.check:
                failed += 0 if check_species(out, species) else 1
            else:
                target, summary = write_species(models, species, out, args.size, not args.no_idle, args.flat)
                print("to_bbmodel: %s -> %s" % (summary, target))
        return 1 if failed else 0
    except (ToolError, OSError, KeyError, IndexError, struct.error) as exc:
        print("to_bbmodel: %s" % exc, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
