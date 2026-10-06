#!/usr/bin/env python3
"""Hero landmarks (Look pass L3): five big set pieces for ReplicatedStorage.Models.Props, as GLB and FBX.

The sibling of props_base.py, built with its Prop class and written through the same alien_base.export, so the
folders, materials.json and conventions match: Z-up, 1 Blender unit = 1 stud, the piece stands on z = 0 with its
pivot at the bottom centre, flat Principled materials (one per colour, no textures), all parts joined into ONE
mesh named after the piece with its material slots kept, flat shading, seeded jitter so a re-run reproduces the
same file. Emissive slots carry emission > 0 in materials.json, which the Studio installer turns into Neon.

Hero pieces are seen from 60 studs, so each is a few big shapes in three to five colours, no small detail, and a
budget of 1,500 to 3,000 triangles (props_base keeps the 600 cap for scatter that is placed 30 times).

Usage (plain Python with the bpy module, or inside a Blender binary):
    python3 tools/blender/heroes_base.py [--heroes CrashWreck,Shrine] [--out assets/models/props] [--all]
    blender -b -P tools/blender/heroes_base.py -- --all

Output per piece: assets/models/props/<Name>/<Name>.glb, <Name>.fbx, notes.md, materials.json, and a review render
docs/vault/05-ui-design/refs/look-l3/<Name>.png at the standard three-quarter angle.
Exit code 1 when any piece is outside 1,500 to 3,000 triangles, 3 when a piece does not stand on z = 0, 2 for an
unknown name.
"""
import argparse
import datetime
import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
from alien_base import export, triangle_count  # noqa: E402
from props_base import Prop, circ, mesh_bounds, move, rect, rot_y, rot_z  # noqa: E402

TOOL_NAME = "tools/blender/heroes_base.py, bpy %s" % bpy.app.version_string
TRI_MIN = 1500
TRI_MAX = 3000
GLOW = 2.0
RENDER_DIR = ROOT / "docs/vault/05-ui-design/refs/look-l3"


def rot_x(deg):
    return Matrix.Rotation(math.radians(deg), 4, "X")


def boulder(p, mat, level, size, centre, jitter=0.12, rot=0.0, flat=None):
    """A jittered icosphere fitted to `size` at `centre`; `flat` squashes everything under that height to z = 0."""
    v = p.ico(level, mat, jitter=jitter, rot=rot)
    p.fit(v, size, centre)
    if flat is not None:
        p.flatten(v, flat)
    return v


def disc(p, mat, rx, ry, z=0.0, thick=0.08, n=32):
    """A thin flat disc lying on the ground (a scorch mark, a paving floor, a pool)."""
    return p.loft([(z, circ(n, rx, ry)), (z + thick, circ(n, rx, ry))], mat, caps=(True, True))


def wall_disc(p, mat, rx, rz, centre, n=24, thick=0.2):
    """A thin upright ellipse facing -Y (the dark interior of a cave mouth)."""
    v = p.loft([(0.0, circ(n, rx, rz)), (thick, circ(n, rx, rz))], mat, caps=(True, True))
    p.place(v, move(*centre) @ rot_x(90))
    return v


def hull_half(p, length, rx, ry, n=24, rings=12):
    """A capsule half along local +Z: a ragged torn end at z = 0 (dark Plate cap), a Plate band, a rounded nose."""
    out = []
    for i in range(rings):
        t = i / (rings - 1)
        f = 1.0 if t < 0.55 else math.sqrt(max(0.04, 1.0 - ((t - 0.55) / 0.45) ** 2))
        z = t * length
        pts = circ(n, rx * f, ry * f)
        if i == 0:  # ragged tear
            pts = [(x * p.rng.uniform(0.9, 1.05), y * p.rng.uniform(0.9, 1.05)) for x, y in pts]
        out.append((z, pts))
    mats = ["Hull"] * (rings - 1)
    mats[3] = mats[4] = "Plate"
    verts = p.loft(out, mats, caps=(True, False), cap_mats=("Plate", "Hull"))
    for v in verts:  # jitter the torn rim along the length so the tear is not a clean cut
        if v.co.z < 1e-6:
            v.co.z += p.rng.uniform(-0.5, 0.5)
    return verts


def is_top(face):
    return face.normal.z > 0.55


# ----------------------------------------------------------------------------------------------- recipes
def crash_wreck(p):
    p.material("Scorch", "2E2620")
    p.material("Hull", "8A93A0", roughness=0.5, metallic=0.4)
    p.material("Plate", "4A5160", roughness=0.6, metallic=0.3)
    p.material("Ember", "FF7A1A", emission=GLOW)
    p.material("EmberB", "FFC83D", emission=GLOW)
    disc(p, "Scorch", 12.0, 8.5, thick=0.06, n=32)
    # the hull split in two: each half a lofted capsule section, nose rounded, the torn end a dark ragged plate,
    # lying along Y, tipped apart and sunk a third into the ground
    for side, (gap, tilt, spin) in ((-1, (1.0, 9.0, 14.0)), (1, (1.2, -12.0, -20.0))):
        half = hull_half(p, length=8.5, rx=2.9, ry=2.4)
        p.place(half, move(side * 0.6, side * gap, 1.5) @ rot_z(spin) @ rot_y(tilt) @ rot_x(-90 * side))
    # one bent fin rising from the right half: two tapered slabs meeting at a kink
    lower = p.loft([(0.0, rect(1.5, 0.22)), (3.2, rect(1.2, 0.18))], "Hull", caps=(True, False))
    p.place(lower, move(4.6, -1.6, 2.6) @ rot_y(-14))
    upper = p.loft([(0.0, rect(1.2, 0.18)), (2.6, rect(0.35, 0.12))], "Plate", caps=(False, True))
    p.place(upper, move(5.4, -1.6, 5.7) @ rot_y(-48))
    # torn hull debris thrown clear of the split
    for k, (x, y, sx, sy, sz) in enumerate(((-8.6, -2.4, 2.2, 1.6, 1.2), (8.9, 2.6, 1.8, 2.4, 1.0), (-1.4, 6.2, 2.0, 1.4, 1.1), (2.6, -6.4, 1.6, 1.6, 0.9))):
        d = boulder(p, "Plate" if k % 2 else "Hull", 1, (sx, sy, sz), (x, y, sz * 0.4), jitter=0.15, rot=50.0 * k)
        p.flatten(d, 0.1)
    # embers in the split and on the scorch
    for k, (x, y, r, mat) in enumerate(((0.3, 0.2, 1.3, "Ember"), (-0.8, -1.2, 1.0, "EmberB"), (1.2, 1.6, 0.9, "Ember"),
                                        (-6.5, 3.6, 0.8, "EmberB"), (7.4, -3.2, 0.9, "Ember"), (-2.0, -5.2, 0.75, "EmberB"))):
        e = boulder(p, mat, 1, (2 * r, 2 * r, 1.4 * r), (x, y, 0.7 * r), jitter=0.1, rot=37.0 * k)
        p.flatten(e, 0.1)


def shrine(p):
    p.material("Paving", "B9B29A")
    p.material("Stone", "8E8E80")
    p.material("Moss", "5E9E3A")
    p.material("Glow", "9BE7FF", emission=GLOW)
    disc(p, "Paving", 8.5, 8.5, thick=0.15, n=32)
    # the stone ring: twelve squat boulders on a circle of radius 8
    for k in range(12):
        a = 2 * math.pi * k / 12
        s = boulder(p, "Stone", 1, (2.4, 1.8, 1.6), (8.0 * math.cos(a), 8.0 * math.sin(a), 0.8), jitter=0.1, rot=30.0 * k)
        p.place(s, move(0, 0, 0))
        p.flatten(s, 0.2)
        p.retag(s, "Moss", is_top)
    # three leaning monoliths around the centre, mossy on top
    for k, lean in enumerate((9.0, -7.0, 11.0)):
        a = 2 * math.pi * k / 3 + 0.4
        m = boulder(p, "Stone", 2, (2.4, 1.6, 8.5), (0.0, 0.0, 4.25), jitter=0.06, rot=20.0 * k)
        p.place(m, move(4.6 * math.cos(a), 4.6 * math.sin(a), 0.0) @ rot_z(math.degrees(a) + 90) @ rot_y(lean))
        p.flatten(m, 0.3)
        p.retag(m, "Moss", lambda f: f.normal.z > 0.75)
    # the centre: a low plinth and the glow orb above it
    p.loft([(0.0, circ(12, 1.6)), (1.0, circ(12, 1.3))], "Stone", caps=(False, True))
    orb = p.ico(2, "Glow")
    p.fit(orb, (2.4, 2.4, 2.4), (0.0, 0.0, 2.3))


def cave_mouth(p):
    p.material("Rock", "6E6A64")
    p.material("Dark", "15120F")
    p.material("Crystal", "7FE3FF", emission=GLOW)
    p.material("CrystalB", "C084FC", emission=GLOW)
    # the dark interior first, set back behind the arch
    wall_disc(p, "Dark", 3.6, 4.2, (0.0, 1.0, 4.2))
    disc(p, "Dark", 3.8, 2.4, thick=0.05, n=24)
    # an arch of three boulders: two pillars and a lintel
    for side in (-1, 1):
        b = boulder(p, "Rock", 2, (4.6, 6.0, 9.5), (side * 5.4, 1.2, 4.75), jitter=0.08, rot=25.0 * side)
        p.flatten(b, 0.4)
    boulder(p, "Rock", 3, (15.0, 6.2, 4.6), (0.0, 1.2, 10.0), jitter=0.07, rot=8.0)
    # two crystal clusters at the foot of the pillars
    for side, mat in ((-1, "Crystal"), (1, "CrystalB")):
        for k, (dx, dy, h, tilt) in enumerate(((0.0, 0.0, 3.0, 8.0), (0.8, -0.5, 2.1, -18.0), (-0.7, -0.4, 1.7, 22.0))):
            c = p.loft([(0.0, circ(6, 0.45)), (h * 0.75, circ(6, 0.38)), (h, [(0.0, 0.0)])], mat, caps=(True, False))
            p.place(c, move(side * 3.3 + dx, -2.2 + dy, 0.0) @ rot_y(tilt * side))


def geyser_vent(p):
    p.material("Rock", "6B4A36")
    p.material("Crack", "2A1A12")
    p.material("Rim", "D98A4E")
    p.material("Water", "4FB3D9")
    p.material("Glow", "F2FBFF", emission=GLOW)
    n = 24
    jit = [p.rng.uniform(0.92, 1.08) for _ in range(n)]
    ring = lambda r, z: (z, [(x * j, y * j) for (x, y), j in zip(circ(n, r), jit)])  # noqa: E731
    # the cone: a wide skirt, the slope, the hot rim, then the pool wall down to the water
    p.loft([(0.0, circ(n, 7.0)), ring(5.6, 1.2), ring(4.3, 3.0), ring(3.6, 4.4), ring(3.5, 4.9), ring(2.8, 4.9), ring(2.4, 4.3)],
           ["Rock", "Rock", "Rock", "Rim", "Rim", "Rim"], caps=(False, True), cap_mats=("Rock", "Water"))
    # three deep cracks running down the slope
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.5
        crack = p.loft([(0.0, rect(0.35, 0.9)), (3.4, rect(0.2, 0.5))], "Crack", caps=(False, True))
        p.place(crack, rot_z(math.degrees(a)) @ move(4.6, 0.0, 0.2) @ rot_y(-38))
    # tumbled rocks around the skirt
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.9
        r = boulder(p, "Rock", 2, (2.6, 2.2, 1.8), (7.4 * math.cos(a), 7.4 * math.sin(a), 0.9), jitter=0.12, rot=40.0 * k)
        p.flatten(r, 0.25)
    # the steam glow: a soft column standing in the pool
    s = p.ico(2, "Glow", jitter=0.06)
    p.fit(s, (1.9, 1.9, 6.5), (0.0, 0.0, 7.4))


def ice_cave_mouth(p):
    p.material("Ice", "CFEAF7", roughness=0.3)
    p.material("IceBlue", "6EC6F0", roughness=0.25)
    p.material("Snow", "F7FBFF")
    p.material("Dark", "0E1A26")
    wall_disc(p, "Dark", 3.6, 4.2, (0.0, 1.0, 4.2))
    disc(p, "Dark", 3.8, 2.4, thick=0.05, n=24)
    for side in (-1, 1):
        b = boulder(p, "Ice", 2, (4.4, 6.0, 9.5), (side * 5.4, 1.2, 4.75), jitter=0.06, rot=30.0 * side)
        p.flatten(b, 0.4)
        p.retag(b, "Snow", lambda f: f.normal.z > 0.6)
    lintel = boulder(p, "IceBlue", 3, (15.0, 6.2, 4.4), (0.0, 1.2, 10.0), jitter=0.05, rot=12.0)
    p.retag(lintel, "Snow", lambda f: f.normal.z > 0.5)
    # a fringe of icicles hanging from the lintel's front edge, longest in the middle
    for k in range(9):
        x = -4.8 + 1.2 * k
        length = 2.6 - abs(x) * 0.28
        ic = p.loft([(0.0, circ(6, 0.42)), (length * 0.6, circ(6, 0.25)), (length, [(0.0, 0.0)])], "IceBlue", caps=(True, False))
        p.place(ic, move(x, -1.4, 8.3) @ rot_x(180))
    # a snow drift at each foot
    for side in (-1, 1):
        d = boulder(p, "Snow", 1, (3.6, 3.0, 1.2), (side * 3.4, -2.0, 0.6), jitter=0.05, rot=15.0 * side)
        p.flatten(d, 0.2)


SPECS = {
    "CrashWreck": (crash_wreck, "World 1 crash site: the hull split in two and half buried on a scorched disc, one bent fin, glowing embers"),
    "Shrine": (shrine, "World 1 Warden shrine: a ring of twelve mossy stones, three leaning monoliths, a glowing orb on a plinth"),
    "CaveMouth": (cave_mouth, "World 1 cave mouth: an arch of three boulders, a dark interior, two glowing crystal clusters"),
    "GeyserVent": (geyser_vent, "World 2 geyser vent: a cracked rock cone, a hot rim, a blue pool and a glowing steam column"),
    "IceCaveMouth": (ice_cave_mouth, "World 2 ice cave mouth: an icy arch with a snow cap, an icicle fringe and a dark interior"),
}


# ---------------------------------------------------------------------------------------------- outputs
def colour_lines(mats):
    return ", ".join("%s #%s%s" % (n, h, " (emissive %.1f, Neon in Studio)" % GLOW if "emission" in kw else "") for n, (h, kw) in mats.items())


def write_notes(path, name, what, mats, tris, lo, hi, glb, fbx):
    size = hi - lo
    path.write_text("\n".join([
        "# %s hero piece" % name,
        "",
        "- Date: %s" % datetime.date.today().isoformat(),
        "- Tool: %s" % TOOL_NAME,
        "- What: %s" % what,
        "- Footprint (W x D x H, studs): %.2f x %.2f x %.2f (Blender X x Y x Z; Y becomes Roblox Z on export)" % (size.x, size.y, size.z),
        "- Vertical extent: z %.2f to %.2f; pivot at the bottom centre (origin), the piece stands on z = 0" % (lo.z, hi.z),
        "- Triangles: %d (hero budget %d to %d)" % (tris, TRI_MIN, TRI_MAX),
        "- Colours / materials (one per colour, flat, no textures): %s" % colour_lines(mats),
        "- Read distance: built to read at 60 studs (big shapes, no small detail)",
        "- Files: %s (%d bytes), %s (%d bytes), materials.json" % (glb.name, glb.stat().st_size, fbx.name, fbx.stat().st_size),
        "- Review render: docs/vault/05-ui-design/refs/look-l3/%s.png" % name,
        "- Studio: upload with tools/upload_assets.py and install with tools/studio/install_models.luau (parts coloured "
        "from materials.json, emissive slots Neon), or File -> Import 3D on the GLB, rename the Model to `%s`, parent under "
        "ReplicatedStorage.Models.Props, Anchored on." % name,
        "",
    ]))


def render(obj, name):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "STUDIO"
    sc.display.shading.color_type = "MATERIAL"
    sc.display.shading.show_shadows = True
    sc.render.resolution_x = sc.render.resolution_y = 512
    sc.world = bpy.data.worlds.new("W")
    sc.world.color = (0.86, 0.9, 0.95)
    lo, hi = mesh_bounds(obj.data)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z) * 1.35
    cam = bpy.data.objects.new("Cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    target = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, (hi.z - lo.z) * 0.4))
    cam.location = target + Vector((2.6, -4.5, 1.6)).normalized() * 60.0
    cam_data.clip_end = 200.0
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    sc.render.filepath = str(RENDER_DIR / ("%s.png" % name))
    bpy.ops.render.render(write_still=True)


def parse_args():
    argv = sys.argv[1:]
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser(description="Generate the hero landmark pieces for ReplicatedStorage.Models.Props")
    ap.add_argument("--heroes", default="", help="comma-separated piece names (default: all)")
    ap.add_argument("--out", default=str(ROOT / "assets/models/props"), help="output root (default assets/models/props)")
    ap.add_argument("--all", action="store_true", help="build every piece (default when --heroes is empty)")
    ap.add_argument("--no-render", action="store_true", help="skip the review renders")
    return ap.parse_args(argv)


def main():
    args = parse_args()
    wanted = [s.strip() for s in args.heroes.split(",") if s.strip()]
    if wanted and not args.all:
        missing = [w for w in wanted if w not in SPECS]
        if missing:
            print("unknown hero piece: %s (known: %s)" % (", ".join(missing), ", ".join(SPECS)))
            sys.exit(2)
        names = wanted
    else:
        names = list(SPECS)
    out_root = pathlib.Path(args.out)
    if not out_root.is_absolute():
        out_root = pathlib.Path.cwd() / out_root

    off_budget, floating = [], []
    print("%-13s %5s  %-24s %s" % ("piece", "tris", "W x D x H (studs)", "z range"))
    for name in names:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        build, what = SPECS[name]
        p = Prop(name)
        build(p)
        p.flatten(list(p.bm.verts), 0.0)  # whatever dips under the ground sits on it: half-buried, never floating
        mats = dict(p.mats)
        obj = p.finish()
        tris = triangle_count(obj.data)
        lo, hi = mesh_bounds(obj.data)
        size = hi - lo
        out_dir = out_root / name
        glb, fbx = export(obj, out_dir, name)
        write_notes(out_dir / "notes.md", name, what, mats, tris, lo, hi, glb, fbx)
        if not args.no_render:
            render(obj, name)
        flag = ""
        if not TRI_MIN <= tris <= TRI_MAX:
            off_budget.append(name)
            flag += "  OUTSIDE %d-%d" % (TRI_MIN, TRI_MAX)
        if abs(lo.z) > 0.01:
            floating.append(name)
            flag += "  BOTTOM z=%.2f" % lo.z
        print("%-13s %5d  %6.2f x %6.2f x %6.2f  %5.2f..%5.2f%s" % (name, tris, size.x, size.y, size.z, lo.z, hi.z, flag), flush=True)
    if off_budget:
        print("outside the %d to %d triangle budget: %s" % (TRI_MIN, TRI_MAX, ", ".join(off_budget)))
        sys.exit(1)
    if floating:
        print("not standing on z = 0: %s" % ", ".join(floating))
        sys.exit(3)


if __name__ == "__main__":
    main()
