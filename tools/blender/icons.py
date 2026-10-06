#!/usr/bin/env python3
"""Flat UI icons and particle sprites (Look pass L5): one family of two-tone icons with a thick dark outline.

Every icon is two to four flat extruded shapes (circles, rounded rectangles, stars, gears, a glyph) in the picture
plane, rendered in Workbench with FLAT lighting so each part is one solid colour, and outlined with an
inverted-hull Solidify shell in the outline colour (backface culling hides the shell's front, leaving a rim of
even width around every part). Transparent background, 128 x 128, written to assets/icons/<Key>.png, plus a contact
sheet. The keys are the names the data table maps (Scrap, the key materials, gear, menu buttons, rarity badges,
events, power-ups and lures by their data ids). Particle sprites are drawn directly as 64 x 64 white-on-alpha
images (the emitter tints them): assets/particles/Raindrop.png, Flake.png, Wisp.png.

Usage (inside a Blender binary; the Mac's python3 has no bpy):
    blender -b --factory-startup -P tools/blender/icons.py -- [--only Scrap,Shop] [--no-sheet]
Exit code 2 for an unknown key.
"""
import argparse
import math
import pathlib
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
ICON_DIR = ROOT / "assets/icons"
PARTICLE_DIR = ROOT / "assets/particles"
SHEET = ROOT / "docs/vault/05-ui-design/refs/look-l5/icons-sheet.png"

SIZE = 128
VIEW = 2.5            # orthographic width in units; the icon art lives inside -1..1
OUTLINE = 0.085       # outline width in units (about 4 px at 128)
OUTLINE_HEX = "1B1F3B"
DEPTH = 0.08          # extrusion depth of every flat part
LAYER = 0.25          # y gap between stacked layers (layer 0 at the back)


# ----------------------------------------------------------------------------------------------- shapes
def circle(r, cx=0.0, cz=0.0, n=40, sx=1.0, sz=1.0):
    return [(cx + r * sx * math.cos(2 * math.pi * k / n), cz + r * sz * math.sin(2 * math.pi * k / n)) for k in range(n)]


def regpoly(n, r, rot=90.0, cx=0.0, cz=0.0, sx=1.0, sz=1.0):
    return [(cx + r * sx * math.cos(math.radians(rot) + 2 * math.pi * k / n),
             cz + r * sz * math.sin(math.radians(rot) + 2 * math.pi * k / n)) for k in range(n)]


def star(points, r_out, r_in, rot=90.0, cx=0.0, cz=0.0):
    pts = []
    for k in range(points * 2):
        r = r_out if k % 2 == 0 else r_in
        a = math.radians(rot) + math.pi * k / points
        pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return pts


def gear(teeth, r_out, r_in, cx=0.0, cz=0.0, rot=0.0):
    pts = []
    for k in range(teeth):
        base = math.radians(rot) + 2 * math.pi * k / teeth
        step = 2 * math.pi / teeth
        for frac, r in ((0.0, r_in), (0.15, r_out), (0.45, r_out), (0.6, r_in)):
            a = base + frac * step
            pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return pts


def rrect(w, h, r, cx=0.0, cz=0.0, seg=5, rot=0.0):
    hx, hz = w / 2, h / 2
    r = min(r, hx - 1e-3, hz - 1e-3)
    pts = []
    for ccx, ccz, a0 in ((hx - r, -(hz - r), -90), (hx - r, hz - r, 0), (-(hx - r), hz - r, 90), (-(hx - r), -(hz - r), 180)):
        for k in range(seg + 1):
            a = math.radians(a0 + 90.0 * k / seg)
            pts.append((ccx + r * math.cos(a), ccz + r * math.sin(a)))
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    return [(cx + x * c - z * s, cz + x * s + z * c) for x, z in pts]


def moved(pts, dx=0.0, dz=0.0, rot=0.0, sx=1.0, sz=1.0):
    c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    return [(dx + (x * sx) * c - (z * sz) * s, dz + (x * sx) * s + (z * sz) * c) for x, z in pts]


def arc_band(r_out, r_in, a0, a1, cx=0.0, cz=0.0, n=16):
    """A thick arc (radar waves, a horseshoe) as one polygon."""
    outer = [(cx + r_out * math.cos(math.radians(a0 + (a1 - a0) * k / n)), cz + r_out * math.sin(math.radians(a0 + (a1 - a0) * k / n))) for k in range(n + 1)]
    inner = [(cx + r_in * math.cos(math.radians(a1 - (a1 - a0) * k / n)), cz + r_in * math.sin(math.radians(a1 - (a1 - a0) * k / n))) for k in range(n + 1)]
    return outer + inner


def bolt(s=1.0, cx=0.0, cz=0.0):
    return moved([(-0.15, 0.9), (0.45, 0.9), (0.1, 0.15), (0.45, 0.15), (-0.3, -0.95), (-0.05, -0.15), (-0.45, -0.15)], cx, cz, sx=s, sz=s)


def teardrop(r, cx=0.0, cz=0.0, tip=1.0, n=28):
    """A drop pointing up: a circle whose top half is pulled into a point."""
    pts = []
    for k in range(n):
        a = -math.pi / 2 + 2 * math.pi * k / n
        x, z = r * math.cos(a), r * math.sin(a)
        if z > 0:
            f = z / r
            x *= (1 - f) ** 1.2
            z = z + f * f * r * tip
        pts.append((cx + x, cz + z))
    return pts


# ---------------------------------------------------------------------------------------------- the icons
# Each icon: a list of parts, back to front. A part is (shape points | ("text", glyph, size), hex colour, x/z offset
# for text). Colours: a base tone and a lighter or darker accent per icon, so the set reads two-tone.
def P(pts, hex_):
    return ("poly", pts, hex_)


def T(glyph, size, hex_, cx=0.0, cz=0.0):
    return ("text", (glyph, size, cx, cz), hex_)


def RING(r, tilt, hex_, cx=0.0, cz=0.0, minor=0.07):
    return ("ring", (r, tilt, cx, cz, minor), hex_)


def cloud(cz=0.15, hex_="E8EEF7"):
    return [P(circle(0.42, -0.38, cz - 0.05), hex_), P(circle(0.5, 0.1, cz + 0.12), hex_), P(circle(0.36, 0.52, cz - 0.08), hex_),
            P(rrect(1.6, 0.5, 0.25, 0.05, cz - 0.25), hex_)]


def flake(r, hex_, cx=0.0, cz=0.0, arm=0.12):
    pts = []
    parts = []
    for k in range(3):
        parts.append(P(rrect(2 * r, arm, arm / 2, cx, cz, rot=60 * k + 90), hex_))
    return parts


ICONS = {
    # currency
    "Scrap": [P(gear(10, 0.95, 0.78), "C77B1C"), P(circle(0.62), "F2A93B"), P(circle(0.26), "C77B1C")],
    # key materials (colours from data/KeyMaterials.luau)
    "WreckPlate": [P(rrect(1.6, 1.2, 0.12, rot=-12), "5E6E7A"), P(rrect(1.3, 0.9, 0.08, 0.02, 0.04, rot=-12), "8A9BA8"),
                   P(circle(0.09, -0.5, 0.42), "5E6E7A"), P(circle(0.09, 0.52, -0.38), "5E6E7A")],
    "Glowroot": [P(rrect(0.36, 1.5, 0.18, 0.0, -0.25, rot=8), "5E9E3A"), P(circle(0.42, 0.06, 0.55), "9BE564"), P(circle(0.16, -0.06, 0.66), "E4FFC8")],
    "CaveCrystal": [P(regpoly(6, 0.95, rot=90, sx=0.75), "2E8BC9"), P(regpoly(6, 0.62, rot=90, sx=0.75, cz=0.08), "68C9FE"),
                    P([(-0.18, 0.55), (0.05, 0.55), (-0.25, 0.1)], "D6F1FF")],
    "StormShard": [P(bolt(1.0), "C9A800"), P(bolt(0.62, 0.02, 0.0), "FFEF4A")],
    "WardenCore": [P(circle(0.9), "1E8549"), P(circle(0.62, 0.0, 0.02), "2ECC71"), P(circle(0.18, -0.25, 0.3), "C8FFDE")],
    "IcePlate": [P(rrect(1.6, 1.15, 0.14, rot=10), "7FB8DA"), P(rrect(1.3, 0.85, 0.1, 0.02, 0.04, rot=10), "BFE3F7"),
                 P([(-0.45, 0.25), (-0.15, 0.25), (-0.5, -0.05)], "F2FBFF")],
    "GeyserPearl": [P(circle(0.85), "D9A66B"), P(circle(0.62, 0.04, 0.05), "FFD6A5"), P(circle(0.17, -0.22, 0.3), "FFF4E6")],
    "FrostCore": [P(circle(0.9), "2F9FD0"), P(circle(0.66), "7FDBFF")] + flake(0.48, "E8FBFF", arm=0.13),
    "BlizzardShard": [P(regpoly(4, 0.98, rot=90, sx=0.62), "8FC9E6"), P(regpoly(4, 0.62, rot=90, sx=0.62, cz=0.06), "E0F7FF")],
    "SkaddleCore": [P(circle(0.9), "AFC3D6"), P(circle(0.64), "F7F9FC"), P(teardrop(0.2, 0.0, -0.1, tip=1.6), "7FB8DA")],
    # gear (the data id for the boots is Boots; the key here is SpeedBoots as asked)
    "SpeedBoots": [P([(-0.6, 0.7), (0.05, 0.7), (0.05, -0.15), (0.75, -0.3), (0.75, -0.7), (-0.6, -0.7)], "C0392B"),
                   P(rrect(1.45, 0.24, 0.1, 0.07, -0.62), "F2F2F2"), P([(-0.95, 0.35), (-0.55, 0.55), (-0.55, 0.1), (-0.95, 0.15)], "FFC83D")],
    "Hoverboard": [P(rrect(1.9, 0.5, 0.25, 0.0, 0.1, rot=-8), "3B82F6"), P(rrect(1.5, 0.16, 0.08, 0.0, 0.14, rot=-8), "A5D4FF"),
                   P(rrect(1.2, 0.18, 0.09, 0.0, -0.38), "7FE3FF")],
    "Radar1": [P(circle(0.95), "1E6B3A"), P(arc_band(0.5, 0.36, 0, 360, n=32), "57F96C"), P([(0.0, 0.0), (0.9, 0.2), (0.75, 0.55)], "B6FFC6")],
    "Radar2": [P(circle(0.95), "1E6B3A"), P(arc_band(0.7, 0.58, 0, 360, n=32), "57F96C"), P(arc_band(0.36, 0.24, 0, 360, n=32), "57F96C"),
               P([(0.0, 0.0), (0.9, 0.2), (0.75, 0.55)], "B6FFC6")],
    "Radar3": [P(circle(0.95), "1E6B3A"), P(arc_band(0.78, 0.68, 0, 360, n=32), "57F96C"), P(arc_band(0.52, 0.42, 0, 360, n=32), "57F96C"),
               P(arc_band(0.26, 0.16, 0, 360, n=32), "57F96C"), P([(0.0, 0.0), (0.9, 0.2), (0.75, 0.55)], "B6FFC6")],
    "Heater": [P(teardrop(0.42, 0.0, 0.0, tip=1.4), "FF8C42"), P(teardrop(0.22, 0.0, -0.05, tip=1.2), "FFD166"),
               P(arc_band(0.85, 0.0, 180, 360, 0.0, -0.2, n=20), "3A4049")],
    # menu buttons
    "Shop": [P([(-0.9, 0.0), (-0.35, 0.75), (0.85, 0.75), (0.85, -0.75), (-0.35, -0.75)], "FFC83D"), P(circle(0.15, -0.3, 0.0), "B07A1A"),
             T("$", 0.95, "B07A1A", 0.32, -0.02)],
    "Aliens": [P(circle(0.9, 0.0, -0.05), "6BCB3F"), P(circle(0.17, -0.3, 0.12), "1B1F3B"), P(circle(0.17, 0.3, 0.12), "1B1F3B"),
               P(regpoly(3, 0.25, rot=90, cx=0.0, cz=0.85, sx=0.8), "A855F7")],
    "Codex": [P(rrect(1.4, 1.75, 0.12), "7B4AE2"), P(rrect(0.24, 1.75, 0.08, -0.58, 0.0), "4B2A9E"), P(rrect(0.75, 0.32, 0.08, 0.12, 0.4), "E9DDFF")],
    "Ship": [P([(-0.55, -0.65), (-0.85, -0.85), (-0.55, -0.1)], "C0392B"), P([(0.55, -0.65), (0.85, -0.85), (0.55, -0.1)], "C0392B"),
             P(rrect(0.8, 1.35, 0.35, 0.0, -0.15), "E8EEF7"), P(regpoly(3, 0.48, rot=90, cz=0.75, sx=0.85), "C0392B"), P(circle(0.17, 0.0, 0.05), "68C9FE")],
    "Quests": [P(rrect(1.4, 1.75, 0.18), "F5E6C4"), P(rrect(1.6, 0.26, 0.13, 0.0, 0.78), "C99A5B"), T("!", 1.35, "E74C3C", 0.0, -0.05)],
    "Gifts": [P(rrect(1.6, 1.1, 0.1, 0.0, -0.3), "E74C3C"), P(rrect(0.3, 1.1, 0.04, 0.0, -0.3), "FFC83D"),
              P(circle(0.3, -0.27, 0.45, sz=0.7), "FFC83D"), P(circle(0.3, 0.27, 0.45, sz=0.7), "FFC83D")],
    "Settings": [P(gear(8, 0.95, 0.72, rot=10), "8A93A0"), P(circle(0.3), "4A5160")],
    "Ranks": [P(rrect(0.6, 0.95, 0.05, -0.62, -0.47), "C0C7D1"), P(rrect(0.6, 0.65, 0.05, 0.62, -0.62), "CD7F32"),
              P(rrect(0.64, 1.3, 0.05, 0.0, -0.3), "FFC83D"), P(star(5, 0.3, 0.13, cz=0.65), "FFF1B8")],
    "StarChart": [P(circle(0.62), "4F7BE8"), ("ring", (0.98, 16.0, 0.0, 0.0, 0.08), "FFC83D"), P(circle(0.16, -0.2, 0.22), "A5C0FF")],
    # rarity badges: the Playbook's shape per tier in the Theme rarity colours, a lighter inner shape for the second tone
    "Common": [P(circle(0.9), "B0B0B0"), P(circle(0.5), "DCDCDC")],
    "Uncommon": [P(rrect(1.6, 1.6, 0.14), "57F96C"), P(rrect(0.9, 0.9, 0.08), "B3FFBE")],
    "Rare": [P(regpoly(3, 1.0, rot=90, cz=-0.12), "3B82F6"), P(regpoly(3, 0.52, rot=90, cz=-0.12), "A5C8FF")],
    "Epic": [P(regpoly(4, 1.0, rot=90, sx=0.8), "C026D3"), P(regpoly(4, 0.52, rot=90, sx=0.8), "EBA6F3")],
    "Legendary": [P(star(5, 1.0, 0.45, cz=-0.05), "F59E0B"), P(star(5, 0.5, 0.22, cz=-0.05), "FFD98A")],
    "Cosmic": [P(star(12, 1.0, 0.7), "EC4899"), P(circle(0.48), "FBC2E0")],
    "Secret": [P(circle(0.9), "111111"), T("?", 1.3, "F7F9FC", 0.0, -0.02)],
    # events
    "Shower": [P([(-0.05, -0.55), (0.95, 0.75), (0.75, 0.95), (-0.5, 0.05)], "C084FC"), P(circle(0.42, -0.25, -0.25), "7B4AE2"), P(circle(0.18, -0.3, -0.15), "E9DDFF")],
    "Peddler": [P(circle(0.45, 0.0, 0.1, sz=0.85), "A5D4FF"), P(circle(0.95, 0.0, -0.18, sz=0.32), "FF8C42"), P(rrect(1.0, 0.12, 0.06, 0.0, -0.18), "FFD166")],
    "Rain": cloud(0.3, "C8D3E0") + [P(teardrop(0.12, -0.4, -0.65, tip=1.4), "3B82F6"), P(teardrop(0.12, 0.05, -0.8, tip=1.4), "3B82F6"),
                                    P(teardrop(0.12, 0.5, -0.65, tip=1.4), "3B82F6")],
    "Snow": cloud(0.3, "D9E4F0") + flake(0.26, "7FDBFF", -0.35, -0.65, arm=0.08) + flake(0.26, "7FDBFF", 0.4, -0.7, arm=0.08),
    "Blizzard": flake(0.62, "E0F7FF", -0.15, 0.1, arm=0.16) + [P(rrect(1.2, 0.14, 0.07, 0.3, -0.62), "7FDBFF"), P(rrect(0.8, 0.14, 0.07, 0.5, -0.85), "7FDBFF")],
    "Fog": [P(rrect(1.7, 0.3, 0.15, 0.0, 0.48), "B8C2CC"), P(rrect(1.4, 0.3, 0.15, 0.15, 0.0), "D7DEE5"), P(rrect(1.7, 0.3, 0.15, -0.05, -0.48), "B8C2CC")],
    # power-ups (data/PowerUps.luau ids)
    "SpeedBurst": [P(circle(0.92), "FF6B35"), P(bolt(0.75), "FFEF4A")],
    "SteadyHands": [P(circle(0.92), "2E8BC9"), P(circle(0.6), "E8F4FF"), P(circle(0.28), "2E8BC9")],
    "ScannerPulse": [P(circle(0.22, -0.55, -0.55), "1E6B3A"), P(arc_band(0.75, 0.6, 0, 90, -0.55, -0.55), "57F96C"),
                     P(arc_band(1.25, 1.1, 0, 90, -0.55, -0.55), "57F96C")],
    "LuckyCharm": [P(rrect(0.14, 0.7, 0.07, 0.15, -0.55, rot=-20), "2E7D32"), P(circle(0.33, -0.27, 0.27), "57C35A"), P(circle(0.33, 0.27, 0.27), "57C35A"),
                   P(circle(0.33, -0.27, -0.2), "57C35A"), P(circle(0.33, 0.27, -0.2), "57C35A"), P(circle(0.14, 0.0, 0.04), "B6F5B8")],
    "ScrapMagnet": [P(arc_band(0.85, 0.42, 180, 360, 0.0, 0.1), "E74C3C"), P(rrect(0.43, 0.32, 0.04, -0.635, 0.26), "E8EEF7"),
                    P(rrect(0.43, 0.32, 0.04, 0.635, 0.26), "E8EEF7")],
    "DoubleShift": [P(circle(0.92), "F2A93B"), P(circle(0.7), "FFF4E0"), P(rrect(0.12, 0.5, 0.06, 0.0, 0.2), "1B1F3B"), P(rrect(0.4, 0.12, 0.06, 0.17, 0.0), "1B1F3B")],
    # lures (data/Lures.luau ids): one hook body, a different bait per tier
    "Lure1": [P(arc_band(0.5, 0.36, 180, 360, 0.05, -0.35), "8A93A0"), P(rrect(0.14, 0.95, 0.07, 0.48, 0.1), "8A93A0"), P(circle(0.3, 0.48, 0.6), "8B5A2B")],
    "Lure2": [P(arc_band(0.5, 0.36, 180, 360, 0.05, -0.35), "8A93A0"), P(rrect(0.14, 0.95, 0.07, 0.48, 0.1), "8A93A0"), P(circle(0.34, 0.48, 0.6), "9BE564"),
              P(circle(0.13, 0.4, 0.68), "E4FFC8")],
    "Lure3": [P(arc_band(0.5, 0.36, 180, 360, 0.05, -0.35), "8A93A0"), P(rrect(0.14, 0.95, 0.07, 0.48, 0.1), "8A93A0"), P(star(5, 0.45, 0.2, cx=0.48, cz=0.58), "FFC83D")],
}


# ---------------------------------------------------------------------------------------------- building
def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


_mats = {}


def material(hex_):
    if hex_ not in _mats:
        m = bpy.data.materials.new("C" + hex_)
        rgb = tuple(srgb_to_linear(c) for c in hex_rgb(hex_))
        m.diffuse_color = (*rgb, 1.0)
        m.use_backface_culling = True
        _mats[hex_] = m
    return _mats[hex_]


def outlined(obj, hex_):
    """Give obj its flat colour and an inverted-hull outline shell."""
    obj.data.materials.clear()
    obj.data.materials.append(material(hex_))
    obj.data.materials.append(material(OUTLINE_HEX))
    mod = obj.modifiers.new("Outline", "SOLIDIFY")
    mod.thickness = OUTLINE
    mod.offset = 1.0
    mod.use_flip_normals = True
    mod.use_rim = False
    mod.material_offset = 1


def poly_object(name, pts, y):
    """Extrude a 2D outline (x, z) into a flat slab facing -Y at depth y."""
    bm = bmesh.new()
    front = [bm.verts.new((x, y, z)) for x, z in pts]
    back = [bm.verts.new((x, y + DEPTH, z)) for x, z in pts]
    face = bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    n = len(pts)
    for k in range(n):
        bm.faces.new([front[k], back[k], back[(k + 1) % n], front[(k + 1) % n]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    if face is None:
        pass
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def text_object(name, glyph, size, cx, cz, y):
    cu = bpy.data.curves.new(name, "FONT")
    cu.body = glyph
    cu.size = size
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.extrude = DEPTH / 2
    obj = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(obj)
    obj.rotation_euler = (math.radians(90), 0.0, 0.0)
    obj.location = (cx, y + DEPTH / 2, cz)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj.select_set(False)
    return bpy.context.view_layer.objects.active


def ring_object(name, r, tilt, cx, cz, minor, y):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=minor, major_segments=48, minor_segments=8,
                                     location=(cx, y, cz), rotation=(math.radians(tilt), math.radians(-18), 0.0))
    obj = bpy.context.active_object
    obj.name = name
    return obj


def build_icon(key):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    parts = ICONS[key]
    for i, (kind, data, hex_) in enumerate(parts):
        y = -LAYER * i
        if kind == "poly":
            obj = poly_object("%s_%d" % (key, i), data, y)
        elif kind == "text":
            glyph, size, cx, cz = data
            obj = text_object("%s_%d" % (key, i), glyph, size, cx, cz, y)
        else:
            r, tilt, cx, cz, minor = data
            obj = ring_object("%s_%d" % (key, i), r, tilt, cx, cz, minor, y + LAYER * (i - 1) * 0.5)
        outlined(obj, hex_)
    render_to(ICON_DIR / ("%s.png" % key))


def render_to(path):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "FLAT"
    sc.display.shading.color_type = "MATERIAL"
    sc.display.shading.show_backface_culling = True
    sc.display.shading.show_shadows = False
    sc.display.shading.show_cavity = False
    sc.display.shading.show_specular_highlight = False
    sc.display.render_aa = "16"
    sc.view_settings.view_transform = "Standard"
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = SIZE
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = VIEW
    cam = bpy.data.objects.new("Cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.location = (0.0, -20.0, 0.0)
    cam.rotation_euler = (math.radians(90), 0.0, 0.0)
    path.parent.mkdir(parents=True, exist_ok=True)
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


# --------------------------------------------------------------------------------------------- particles
def save_rgba(path, rgba):
    """rgba: H x W x 4 floats 0..1, row 0 at the top."""
    h, w, _ = rgba.shape
    img = bpy.data.images.new(path.stem, w, h, alpha=True)
    img.alpha_mode = "STRAIGHT"
    img.pixels = np.flipud(rgba).ravel().tolist()
    img.filepath_raw = str(path)
    img.file_format = "PNG"
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save()
    bpy.data.images.remove(img)


def particles():
    n = 64
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float64)
    u, v = (xx + 0.5) / n * 2 - 1, (yy + 0.5) / n * 2 - 1      # -1..1, v down
    out = {}
    # Raindrop: a soft vertical streak, brightest in the lower middle, fading up and out
    a = np.exp(-(u / 0.13) ** 2) * np.clip(1 - ((v - 0.15) / 0.85) ** 2, 0, 1)
    out["Raindrop"] = a
    # Flake: six thin arms with a few side ticks, soft edged
    ang, rad = np.arctan2(v, u), np.hypot(u, v)
    arm = np.zeros_like(u)
    for k in range(6):
        t = math.radians(60 * k)
        along = u * math.cos(t) + v * math.sin(t)
        across = -u * math.sin(t) + v * math.cos(t)
        line = np.exp(-(across / 0.06) ** 2) * (along > 0) * (along < 0.88)
        tick = np.zeros_like(u)
        for pos in (0.45, 0.65):
            for side in (-1, 1):
                ta, tb = math.cos(math.radians(45 * side)), math.sin(math.radians(45 * side))
                da, dc = along - pos, across
                al2 = da * ta + dc * tb
                ac2 = -da * tb + dc * ta
                tick += np.exp(-(ac2 / 0.05) ** 2) * (al2 > 0) * (al2 < 0.22)
        arm = np.maximum(arm, np.maximum(line, np.clip(tick, 0, 1)))
    arm = np.maximum(arm, np.exp(-(rad / 0.16) ** 2))
    out["Flake"] = np.clip(arm, 0, 1)
    # Wisp: a soft blob with a gently lumpy edge
    lump = 1 + 0.12 * np.sin(3 * ang + 0.7) + 0.08 * np.sin(5 * ang + 2.1)
    out["Wisp"] = np.clip(1 - (rad / (0.85 * lump)) ** 2, 0, 1) ** 1.6
    for name, alpha in out.items():
        rgba = np.ones((n, n, 4))
        rgba[..., 3] = alpha
        save_rgba(PARTICLE_DIR / ("%s.png" % name), rgba)


# ------------------------------------------------------------------------------------------- contact sheet
def contact_sheet(keys):
    cols, cell, pad = 8, SIZE, 12
    rows = math.ceil(len(keys) / cols)
    w, h = cols * (cell + pad) + pad, rows * (cell + pad) + pad
    sheet = np.ones((h, w, 4))
    sheet[..., :3] = np.array(hex_rgb("FFF4DE"))
    for i, key in enumerate(keys):
        img = bpy.data.images.load(str(ICON_DIR / ("%s.png" % key)))
        px = np.flipud(np.array(img.pixels[:]).reshape(img.size[1], img.size[0], 4))
        bpy.data.images.remove(img)
        r, c = divmod(i, cols)
        y0, x0 = pad + r * (cell + pad), pad + c * (cell + pad)
        a = px[..., 3:4]
        region = sheet[y0:y0 + cell, x0:x0 + cell, :3]
        sheet[y0:y0 + cell, x0:x0 + cell, :3] = px[..., :3] * a + region * (1 - a)
    save_rgba(SHEET, sheet)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser(description="Render the flat UI icon set and the particle sprites")
    ap.add_argument("--only", default="", help="comma-separated icon keys (default: all)")
    ap.add_argument("--no-sheet", action="store_true")
    return ap.parse_args(argv)


def main():
    args = parse_args()
    keys = [k.strip() for k in args.only.split(",") if k.strip()] or list(ICONS)
    unknown = [k for k in keys if k not in ICONS]
    if unknown:
        print("unknown icon key: %s" % ", ".join(unknown))
        sys.exit(2)
    for key in keys:
        build_icon(key)
        print("icon %s" % key, flush=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    particles()
    print("particles Raindrop, Flake, Wisp")
    if not args.no_sheet:
        contact_sheet(list(ICONS))
        print("sheet %s (%d icons)" % (SHEET.relative_to(ROOT), len(ICONS)))


if __name__ == "__main__":
    main()
