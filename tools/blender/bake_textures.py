#!/usr/bin/env python3
"""Bake the shared surface textures (the Surface pass, layer C) to tileable 512 x 512 PNGs with headless Blender.

One procedural node tree per key of src/shared/data/Textures.luau (fur, moss, stone, ice, scales), built from noise and
voronoi textures and rendered flat with Cycles in three passes: a colour map, a roughness map and a height map from which the
normal map is computed (an OpenGL, tangent-space normal map, which is the only kind Roblox reads). Output, under assets/textures/<key>/:

  <key>_color.png      near-white detail (0.7 to 1.0 grey, mean about 0.92): the model slot's own colour tints it through SurfaceAppearance.Color,
                       so one set serves every species
  <key>_normal.png     OpenGL normal map, computed from the height pass with wrap-around differences
  <key>_roughness.png  grey, white = rough (SurfaceAppearance.RoughnessMap)

Every map tiles: the 2D UV is mapped onto a 4D torus before the 4D noise and voronoi nodes read it, so the left edge meets the right
edge and the top meets the bottom exactly, and the normal map wraps with np.roll. Each PNG is kept under 300 KB (the PNG writer picks the
best row filter, and quantises the values a little more if a map would be bigger). assets/textures/README.md gets a line per key.
Nothing is uploaded: the Mac session runs the image upload and pastes the Image ids into src/shared/data/Textures.luau.

  python3 tools/blender/bake_textures.py                    # every key in Textures.luau, plain Python with the bpy module
  blender -b -P tools/blender/bake_textures.py -- --only fur,moss
  python3 tools/blender/bake_textures.py --out /some/folder --size 256

Exit code 1 if a map would not fit 300 KB or a key in Textures.luau has no pattern here. A new key needs a pattern in PATTERNS.
"""
import argparse
import math
import pathlib
import struct
import sys
import tempfile
import zlib

import bpy  # first: with the bpy module, mathutils only imports after it
import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import luau_tables  # noqa: E402

ROOT = HERE.parent.parent
TEXTURES = ROOT / "src/shared/data/Textures.luau"
MAX_BYTES = 300_000  # "under 300 KB" in either sense (decimal or 1024)
BLUR_PASSES = 2  # of the height field, before the normal map is taken from it
TAU = 2.0 * math.pi


# ------------------------------------------------------------------------------------------------ node helpers
class Graph:
    """A tiny wrapper over a material node tree: math on sockets and floats, and the torus coordinates that make noise tile."""

    def __init__(self, tree):
        self.t = tree
        self.n = tree.nodes
        self.l = tree.links
        uv = self.n.new("ShaderNodeTexCoord")
        sep = self.n.new("ShaderNodeSeparateXYZ")
        self.l.new(uv.outputs["UV"], sep.inputs["Vector"])
        self.u, self.v = sep.outputs["X"], sep.outputs["Y"]
        # u, v in 0..1 -> two circles: (cos, sin) of 2 pi u and of 2 pi v, the 4D torus every texture reads
        cu, su = self.circle(self.u)
        cv, sv = self.circle(self.v)
        self.torus = (cu, su, cv, sv)

    def put(self, socket, value):
        if value is None:
            return
        if isinstance(value, (int, float)):
            socket.default_value = value
        else:
            self.l.new(value, socket)

    def math(self, op, a, b=None, c=None, clamp=False):
        node = self.n.new("ShaderNodeMath")
        node.operation = op
        node.use_clamp = clamp
        for index, value in enumerate((a, b, c)):
            self.put(node.inputs[index], value)
        return node.outputs[0]

    def add(self, a, b): return self.math("ADD", a, b)
    def sub(self, a, b): return self.math("SUBTRACT", a, b)
    def mul(self, a, b): return self.math("MULTIPLY", a, b)

    def circle(self, x):
        angle = self.math("MULTIPLY", x, TAU)
        return self.math("COSINE", angle), self.math("SINE", angle)

    def remap(self, x, lo, hi, out_lo=0.0, out_hi=1.0, smooth=False):
        node = self.n.new("ShaderNodeMapRange")
        node.data_type = "FLOAT"
        node.interpolation_type = "SMOOTHSTEP" if smooth else "LINEAR"
        node.clamp = True
        self.put(node.inputs["Value"], x)
        for name, value in (("From Min", lo), ("From Max", hi), ("To Min", out_lo), ("To Max", out_hi)):
            node.inputs[name].default_value = value
        return node.outputs["Result"]

    def coords(self, features):
        """The torus scaled so a texture with scale 1 has about `features` features across the tile."""
        radius = features / TAU
        cu, su, cv, sv = self.torus
        vector = self.n.new("ShaderNodeCombineXYZ")
        self.l.new(self.math("MULTIPLY", cu, radius), vector.inputs["X"])
        self.l.new(self.math("MULTIPLY", su, radius), vector.inputs["Y"])
        self.l.new(self.math("MULTIPLY", cv, radius), vector.inputs["Z"])
        return vector.outputs["Vector"], self.math("MULTIPLY", sv, radius)

    def noise(self, features, detail=3.0, roughness=0.5, distortion=0.0):
        node = self.n.new("ShaderNodeTexNoise")
        node.noise_dimensions = "4D"
        node.noise_type = "FBM"
        node.normalize = True
        vector, w = self.coords(features)
        self.l.new(vector, node.inputs["Vector"])
        self.l.new(w, node.inputs["W"])
        node.inputs["Scale"].default_value = 1.0
        node.inputs["Detail"].default_value = detail
        node.inputs["Roughness"].default_value = roughness
        node.inputs["Distortion"].default_value = distortion
        return node.outputs["Fac"]

    def voronoi(self, features, feature="F1", randomness=1.0):
        node = self.n.new("ShaderNodeTexVoronoi")
        node.voronoi_dimensions = "4D"
        node.feature = feature
        node.distance = "EUCLIDEAN"
        vector, w = self.coords(features)
        self.l.new(vector, node.inputs["Vector"])
        self.l.new(w, node.inputs["W"])
        node.inputs["Scale"].default_value = 1.0
        node.inputs["Randomness"].default_value = randomness
        return node

    def edge(self, features, randomness=1.0):
        """F2 - F1 of a voronoi: 0 on the lines between cells, growing toward each cell's middle."""
        first = self.voronoi(features, "F1", randomness).outputs["Distance"]
        second = self.voronoi(features, "F2", randomness).outputs["Distance"]
        return self.sub(second, first)


# ------------------------------------------------------------------------------------------------ the five patterns
# Each returns (colour, height, roughness) as scalar sockets in 0..1. Colour is near-white detail: the slot colour tints it.
def fur(g):
    coarse = g.noise(5.0, 2.0, 0.5)
    fine = g.noise(20.0, 1.0, 0.6)
    tuft = g.add(g.mul(fine, 0.7), g.mul(coarse, 0.3))
    colour = g.remap(g.mul(fine, g.add(0.62, g.mul(coarse, 0.38))), 0.1, 0.9, 0.86, 1.0)
    return colour, tuft, g.remap(fine, 0.2, 0.8, 0.78, 0.95)


def moss(g):
    cell = g.voronoi(9.0, "F1", 1.0).outputs["Distance"]
    dome = g.remap(cell, 0.0, 0.75, 1.0, 0.0, smooth=True)
    grain = g.noise(16.0, 3.0, 0.55)
    height = g.add(g.mul(dome, 0.7), g.mul(grain, 0.3))
    return g.remap(height, 0.1, 0.9, 0.84, 1.0), height, g.remap(dome, 0.0, 1.0, 0.92, 0.8)


def stone(g):
    body = g.noise(3.5, 5.0, 0.55)
    crack = g.remap(g.edge(5.0), 0.0, 0.14, 0.0, 1.0, smooth=True)  # 0 in a crack, 1 inside a block
    height = g.add(g.mul(body, 0.6), g.mul(crack, 0.4))
    colour = g.mul(g.remap(body, 0.2, 0.8, 0.84, 1.0), g.remap(crack, 0.0, 1.0, 0.7, 1.0))
    return colour, height, g.remap(body, 0.2, 0.8, 0.78, 0.97)


def ice(g):
    cloud = g.noise(2.5, 3.0, 0.45)
    fleck = g.noise(12.0, 2.0, 0.5)
    frost = g.remap(g.edge(4.0), 0.0, 0.08, 1.0, 0.0, smooth=True)  # 1 on a frost line
    colour = g.add(g.remap(cloud, 0.2, 0.8, 0.9, 0.97), g.mul(frost, 0.08))
    height = g.sub(g.add(g.mul(cloud, 0.3), 0.5), g.mul(frost, 0.35))
    rough = g.add(g.remap(fleck, 0.2, 0.8, 0.14, 0.3), g.mul(frost, 0.38))
    return g.math("MINIMUM", colour, 1.0), height, rough


def scales(g):
    cells = g.voronoi(8.0, "F1", 0.45)
    near = cells.outputs["Distance"]
    rim = g.remap(g.edge(8.0, 0.45), 0.0, 0.2, 0.0, 1.0, smooth=True)  # 0 on the seam between scales
    sep = g.n.new("ShaderNodeSeparateColor")
    g.l.new(cells.outputs["Color"], sep.inputs["Color"])
    tone = g.remap(sep.outputs["Red"], 0.0, 1.0, 0.9, 1.0)
    dome = g.remap(near, 0.0, 0.7, 1.0, 0.3, smooth=True)
    colour = g.mul(tone, g.remap(rim, 0.0, 1.0, 0.72, 1.0))
    return colour, g.mul(rim, dome), g.remap(rim, 0.0, 1.0, 0.7, 0.36)


PATTERNS = {"fur": fur, "moss": moss, "stone": stone, "ice": ice, "scales": scales}
# Strength of the normal map per key: how steep the height pass is read (1 = the height's own slope in pixels, x this).
BUMP = {"fur": 4.0, "moss": 5.0, "stone": 6.0, "ice": 3.0, "scales": 6.0}
ABOUT = {
    "fur": "short fine tufts over a slow clump pattern, rough and soft (Sparkfox, Buzzlebee, anything furry)",
    "moss": "round velvety clumps (Mossbop, Pebblet's cap, Twiglet's leaf)",
    "stone": "blocky grey rock with dark cracks, rough (Pebblet, Rocklobber, cave props)",
    "ice": "smooth pale cloud with bright frost lines, glossy (the Frostbyte species)",
    "scales": "a field of small shiny domes with seams (newts, lizards, fish)",
}


# ------------------------------------------------------------------------------------------------ rendering
def make_scene(size):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 4
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = False
    scene.cycles.max_bounces = 0
    scene.cycles.pixel_filter_type = "BOX"
    scene.cycles.filter_width = 1.0
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "OPEN_EXR"
    scene.render.image_settings.color_depth = "32"
    scene.render.image_settings.color_mode = "RGB"
    scene.view_settings.view_transform = "Raw"  # emission value in, the same value out
    scene.view_settings.look = "None"
    scene.render.dither_intensity = 0.0
    world = bpy.data.worlds.new("World")
    world.color = (0.0, 0.0, 0.0)
    scene.world = world
    # a plane exactly the size of the frame under an orthographic camera: pixel (i, j) reads UV ((i + .5) / size, (j + .5) / size)
    bpy.ops.mesh.primitive_plane_add(size=2.0)
    plane = bpy.context.active_object
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 2.0
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    cam.location = (0.0, 0.0, 2.0)
    scene.camera = cam
    return scene, plane


def render_passes(key, size):
    """Render the pattern three times (colour, roughness, height) and return three float arrays, 0..1, row 0 at the bottom."""
    scene, plane = make_scene(size)
    material = bpy.data.materials.new(key)
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.clear()
    graph = Graph(tree)
    colour, height, rough = PATTERNS[key](graph)
    emit = tree.nodes.new("ShaderNodeEmission")
    out = tree.nodes.new("ShaderNodeOutputMaterial")
    tree.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    plane.data.materials.append(material)
    results = []
    with tempfile.TemporaryDirectory() as folder:
        for name, socket in (("color", colour), ("rough", rough), ("height", height)):
            for link in list(tree.links):
                if link.to_node == emit:
                    tree.links.remove(link)
            combine = tree.nodes.new("ShaderNodeCombineColor")
            for channel in ("Red", "Green", "Blue"):
                tree.links.new(socket, combine.inputs[channel])
            tree.links.new(combine.outputs["Color"], emit.inputs["Color"])
            path = str(pathlib.Path(folder) / (name + ".exr"))
            scene.render.filepath = path
            bpy.ops.render.render(write_still=True)
            image = bpy.data.images.load(path)
            image.colorspace_settings.name = "Non-Color"
            flat = np.empty(size * size * 4, dtype=np.float32)
            image.pixels.foreach_get(flat)
            pixels = flat.reshape(size, size, 4)[:, :, :3]
            results.append(pixels.mean(axis=2))
            bpy.data.images.remove(image)
            tree.nodes.remove(combine)
    return results


def normal_map(height, strength):
    """OpenGL tangent-space normals from a height field, with wrap-around differences so the map tiles. Row 0 is the bottom."""
    for _ in range(BLUR_PASSES):  # a [1 2 1] blur each way, wrapping: the per-pixel grain is what makes a normal map heavy
        for axis in (0, 1):
            height = (np.roll(height, 1, axis=axis) + 2.0 * height + np.roll(height, -1, axis=axis)) * 0.25
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5
    scale = strength * height.shape[0] / 64.0  # slope per pixel, scaled so a texture looks the same at any size
    nx, ny, nz = -dx * scale, -dy * scale, np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    return np.stack([nx / length, ny / length, nz / length], axis=2) * 0.5 + 0.5


# ------------------------------------------------------------------------------------------------ PNG writer
def _chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def _filtered(rows, bpp):
    """Each row with the PNG filter (None, Sub, Up, Average, Paeth) that gives the smallest sum of absolute values."""
    out = bytearray()
    previous = np.zeros(rows.shape[1], dtype=np.int16)
    for row in rows.astype(np.int16):
        left = np.concatenate([np.zeros(bpp, dtype=np.int16), row[:-bpp]])
        corner = np.concatenate([np.zeros(bpp, dtype=np.int16), previous[:-bpp]])
        paeth_p = left + previous - corner
        pa, pb, pc = np.abs(paeth_p - left), np.abs(paeth_p - previous), np.abs(paeth_p - corner)
        predictor = np.where((pa <= pb) & (pa <= pc), left, np.where(pb <= pc, previous, corner))
        candidates = [row, row - left, row - previous, row - ((left + previous) // 2), row - predictor]
        candidates = [(c & 255).astype(np.uint8) for c in candidates]
        best = min(range(5), key=lambda i: int(np.minimum(candidates[i].astype(np.int16), 256 - candidates[i].astype(np.int16)).sum()))
        out.append(best)
        out += candidates[best].tobytes()
        previous = row
    return bytes(out)


def png_bytes(rgb):
    """An 8-bit RGB PNG from an (h, w, 3) uint8 array, row 0 at the top."""
    height, width, _ = rgb.shape
    raw = _filtered(rgb.reshape(height, width * 3), 3)
    return (b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + _chunk(b"IDAT", zlib.compress(raw, 9)) + _chunk(b"IEND", b""))


def fit_png(rgb01, name):
    """Quantise as little as needed to stay under MAX_BYTES: (png bytes, levels used)."""
    for levels in (256, 224, 192, 160, 128, 96, 64, 48, 32, 24, 16):
        step = 255.0 / (levels - 1)
        values = np.clip(np.round(np.round(np.clip(rgb01, 0.0, 1.0) * 255.0 / step) * step), 0, 255).astype(np.uint8)
        data = png_bytes(values[::-1])  # Blender's row 0 is the bottom; PNG's is the top
        if len(data) <= MAX_BYTES:
            return data, levels
    raise ValueError("%s does not fit in %d KB even at 16 levels" % (name, MAX_BYTES // 1000))


def bake(key, out_root, size):
    colour, rough, height = render_passes(key, size)
    folder = out_root / key
    folder.mkdir(parents=True, exist_ok=True)
    maps = {
        "color": np.stack([colour] * 3, axis=2),
        "normal": normal_map(height, BUMP[key]),
        "roughness": np.stack([rough] * 3, axis=2),
    }
    sizes = {}
    for kind, rgb in maps.items():
        data, levels = fit_png(rgb, "%s_%s" % (key, kind))
        (folder / ("%s_%s.png" % (key, kind))).write_bytes(data)
        sizes[kind] = (len(data), levels)
    seam = max(abs(float(colour[:, 0].mean() - colour[:, -1].mean())), abs(float(colour[0, :].mean() - colour[-1, :].mean())))
    return sizes, seam


def write_readme(out_root, keys, sizes, size):
    lines = [
        "# Surface textures (the Surface pass, layer C)",
        "",
        "Generated by `python3 tools/blender/bake_textures.py` (headless Blender: procedural noise and voronoi nodes on a 4D torus, so every map tiles; the",
        "normal map is computed from the height pass). %d x %d PNGs, each under 300 KB. The colour maps are near-white detail: a slot's own colour tints them" % (size, size),
        "(SurfaceAppearance.Color), so one set serves every species. Upload as images (the Mac session, `tools/upload_assets.py --images` style), then paste the three",
        "Image ids per key into `src/shared/data/Textures.luau` (`colorMap`, `normalMap`, `roughnessMap`); a slot takes a set through its `texture` key in",
        "`assets/models/<Id>/materials.json`. See `docs/vault/06-art-pipelines/Surface-Pass.md`.",
        "",
    ]
    for key in keys:
        s = sizes[key]
        lines.append("- `%s`: %s. `%s_color.png` %d KB, `%s_normal.png` %d KB, `%s_roughness.png` %d KB." % (
            key, ABOUT[key], key, s["color"][0] // 1000, key, s["normal"][0] // 1000, key, s["roughness"][0] // 1000))
    (out_root / "README.md").write_text("\n".join(lines) + "\n")


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    ap = argparse.ArgumentParser(description="Bake the shared surface textures to assets/textures")
    ap.add_argument("--out", default=str(ROOT / "assets/textures"), help="output folder (default assets/textures)")
    ap.add_argument("--only", default="", help="comma list of keys (default: every key in Textures.luau)")
    ap.add_argument("--size", type=int, default=512, help="pixels per side (default 512)")
    args = ap.parse_args(argv)
    keys = list(luau_tables.load(str(TEXTURES)))
    if args.only:
        wanted = [k.strip() for k in args.only.split(",") if k.strip()]
        unknown = [k for k in wanted if k not in keys]
        if unknown:
            print("not a key of Textures.luau: %s" % ", ".join(unknown))
            sys.exit(2)
        keys = wanted
    missing = [k for k in keys if k not in PATTERNS]
    if missing:
        print("no pattern in bake_textures.py for: %s" % ", ".join(missing))
        sys.exit(1)
    out_root = pathlib.Path(args.out)
    if not out_root.is_absolute():
        out_root = pathlib.Path.cwd() / out_root
    sizes, failed = {}, []
    for key in keys:
        try:
            sizes[key], seam = bake(key, out_root, args.size)
            print("%-7s %s  seam %.4f" % (key, "  ".join("%s %d KB (%d levels)" % (k, v[0] // 1000, v[1]) for k, v in sizes[key].items()), seam), flush=True)
        except Exception as exc:  # noqa: BLE001
            failed.append(key)
            print("%-7s FAILED: %s" % (key, exc), flush=True)
    if not failed and not args.only:
        write_readme(out_root, keys, sizes, args.size)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
