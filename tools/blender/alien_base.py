#!/usr/bin/env python3
"""Procedural blockout aliens: one stylised low-poly mesh per species row, exported as GLB and FBX.

Reads src/shared/data/Species.luau and Tiers.luau through tools/luau_tables.py and builds, for each
species, the recipe from docs/vault/06-art-pipelines/Creature-Generation.md: a round compact body from
the placeholder shape, two big eyes, a tiny mouth, four stubby limbs, one accessory picked from the
concept string by keyword, and the tier dressing from docs/GAME_DESIGN.md section 15 (Rare 110% with
metallic accessory, Epic 120% with a collar, Legendary 125% with halo and ground ring, Cosmic 150% with an
emissive accessory, Secret as Cosmic with a black body). Flat colours, one material per colour, all parts
joined into ONE mesh object named after the species so Studio's Import 3D makes one MeshPart per material.

Units: 1 Blender unit = 1 stud. The alien is built Z-up standing on z = 0; the glTF and FBX exporters
convert to Y-up with their defaults.

Usage (plain Python with the bpy module, or inside a Blender binary):
    python3 tools/blender/alien_base.py [--species Mossbop,Radish] [--out assets/models] [--all]
    blender -b -P tools/blender/alien_base.py -- --all

Output per species: assets/models/<SpeciesId>/<SpeciesId>.glb, <SpeciesId>.fbx, notes.md, materials.json.
materials.json lists the material slots in order (colour, roughness, metallic, emission) because an Open Cloud
upload of the GLB keeps one MeshPart per slot but drops the colours; the Studio installer colours each part by index.
Exit code is non-zero if any species exceeds 1,500 triangles after all detail reductions.
"""
import argparse
import colorsys
import datetime
import json
import math
import os
import pathlib
import re
import sys

import bpy
import bmesh
from mathutils import Euler, Matrix, Vector

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from luau_tables import load  # noqa: E402

DATA = ROOT / "src/shared/data"
TOOL_NAME = "tools/blender/alien_base.py, bpy %s" % bpy.app.version_string

TRI_MIN = 500
TRI_MAX = 1500
BODY_HEIGHT_UNITS = 2.2       # times placeholder.scale, before the tier scale
GOLD = "FFC83D"
SILVER = "C8CDD3"

TIER_SCALE = {"Common": 1.0, "Uncommon": 1.0, "Rare": 1.1, "Epic": 1.2, "Legendary": 1.25, "Cosmic": 1.5, "Secret": 1.5}

# Accessory keyword table. First match wins, so order matters (a "glowing tail" is a tail).
ACCESSORY_RULES = [
    (("antler", "stag"), "antlers"),
    (("wing",), "wings"),
    (("quill", "lightning"), "quills"),
    (("shell",), "shell"),
    (("tail",), "tail"),
    (("crest", "antenna"), "crest"),
    (("hat", "leaf"), "leaf_hat"),
    (("radish", "sun"), "sun_disk"),
    (("pipe", "goat"), "horns"),
    (("backpack",), "backpack"),
    (("claw", "crab"), "claws"),
    (("puff", "dandelion"), "puff_ring"),
    (("firefly", "jelly", "glow"), "glow_bulb"),
]

# Segment counts per detail level (0 = richest). The builder steps down a level while over budget.
DETAIL = [
    dict(body=(20, 10), eye=(10, 5), pupil=(8, 4), highlight=(6, 3), mouth=(8, 4), limb=(8, 4), acc=(10, 5), small=(6, 3), torus=(16, 6), cyl=8, disk=24),
    dict(body=(16, 8), eye=(8, 4), pupil=(6, 3), highlight=(4, 3), mouth=(6, 3), limb=(6, 3), acc=(8, 4), small=(5, 3), torus=(12, 5), cyl=6, disk=16),
    dict(body=(12, 6), eye=(6, 3), pupil=(5, 3), highlight=(4, 3), mouth=(5, 3), limb=(5, 3), acc=(6, 3), small=(4, 3), torus=(10, 4), cyl=6, disk=12),
]


# ----------------------------------------------------------------------------------------------- colours
def hex_to_rgb(hex_str):
    h = hex_str.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "".join("%02X" % int(round(max(0.0, min(1.0, c)) * 255)) for c in rgb)


def darken(rgb, amount=0.35):
    """35% darker; near-black bodies get lighter limbs instead so the limbs still read."""
    h, s, v = colorsys.rgb_to_hsv(*rgb)
    if v < 0.25:
        return colorsys.hsv_to_rgb(h, s, min(1.0, v + 0.22))
    return colorsys.hsv_to_rgb(h, s, v * (1.0 - amount))


def accessory_colour(body_rgb, concept):
    """Complement of the body (hue + 150 degrees); gold when the concept names gold or glow; silver for metal."""
    c = concept.lower()
    if re.search(r"\b(gold|glow|radiant|shin)", c):
        return hex_to_rgb(GOLD), "gold"
    if re.search(r"\b(metal|steel|iron|chrome)", c):
        return hex_to_rgb(SILVER), "silver"
    h, s, v = colorsys.rgb_to_hsv(*body_rgb)
    if s < 0.2:
        # grey, white or black body: a hue rotation would stay grey, so pick a saturated sky blue
        return colorsys.hsv_to_rgb(0.56, 0.8, 1.0), "sky"
    return colorsys.hsv_to_rgb((h + 150.0 / 360.0) % 1.0, max(0.55, s), max(0.75, v)), "complement"


# --------------------------------------------------------------------------------------------- materials
def make_material(name, rgb, roughness=0.8, metallic=0.0, emission=0.0):
    mat = bpy.data.materials.new(name)
    if mat.node_tree is None:  # Blender 5 materials start with nodes; older builds need the switch
        mat.use_nodes = True
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf is not None:
        def set_input(label, value):
            if label in bsdf.inputs:
                bsdf.inputs[label].default_value = value
        set_input("Base Color", (rgb[0], rgb[1], rgb[2], 1.0))
        set_input("Roughness", roughness)
        set_input("Metallic", metallic)
        if emission > 0.0:
            set_input("Emission Color", (rgb[0], rgb[1], rgb[2], 1.0))
            set_input("Emission Strength", emission)
    # viewport / Workbench colour, so thumbnails and Studio previews show the same flat colour
    mat.diffuse_color = (rgb[0], rgb[1], rgb[2], 1.0)
    mat.roughness = roughness
    mat.metallic = metallic
    return mat


# ----------------------------------------------------------------------------------- materials.json
MATERIALS_JSON = "materials.json"
_SUFFIX = re.compile(r"\.\d{3}$")


def _principled(mat):
    """The Principled BSDF of a material, found by type (node names are localised)."""
    if mat is None or mat.node_tree is None:
        return None
    return next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)


def material_entries(objs):
    """One entry per material slot, object by object then slot by slot, for materials.json.

    hex is the Principled Base Color default value written back through rgb_to_hex. make_material stores
    hex_to_rgb(hex) as the Base Color with no transfer function, and the glTF exporter writes that number as
    baseColorFactor, so the importer returns it unchanged: rgb_to_hex is the exact inverse and a Body written
    as 7FBF5A reads back as 7FBF5A. A sRGB curve here would shift every colour.
    """
    entries = []
    for obj in objs:
        for slot in obj.material_slots:
            mat = slot.material
            if mat is None:
                continue
            bsdf = _principled(mat)
            if bsdf is not None:
                colour = tuple(bsdf.inputs["Base Color"].default_value)[:3]
                roughness = float(bsdf.inputs["Roughness"].default_value)
                metallic = float(bsdf.inputs["Metallic"].default_value)
                emission = float(bsdf.inputs["Emission Strength"].default_value) if "Emission Strength" in bsdf.inputs else 0.0
            else:
                colour = tuple(mat.diffuse_color)[:3]
                roughness, metallic, emission = float(mat.roughness), float(mat.metallic), 0.0
            entries.append({
                "slot": len(entries) + 1,
                "name": _SUFFIX.sub("", mat.name),
                "hex": rgb_to_hex(colour),
                "roughness": round(roughness, 4),
                "metallic": round(metallic, 4),
                "emission": round(emission, 4),
            })
    return entries


def write_materials_entries(entries, out_dir):
    out_dir = pathlib.Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / MATERIALS_JSON
    path.write_text(json.dumps(entries, indent=2) + "\n")
    return path


def write_materials_json(obj, out_dir):
    """Write out_dir/materials.json from the joined object's material_slots (slot 1 = the first MeshPart)."""
    return write_materials_entries(material_entries([obj]), out_dir)


# ----------------------------------------------------------------------------------------------- bodies
class Body:
    """Analytic description of the body volume so faces, limbs and accessories can sit on its surface."""

    def __init__(self, shape, height):
        self.shape = shape
        self.h = height
        if shape == "Block":
            self.hx, self.hy, self.hz = 0.475 * height, 0.425 * height, 0.5 * height
        elif shape == "Cylinder":
            self.r, self.hz = 0.36 * height, 0.5 * height
            self.hx = self.hy = self.r
        else:  # Ball (default): ellipsoid, slightly squashed in z
            self.r = height / 1.8
            self.rz = 0.9 * self.r
            self.hx = self.hy = self.r
            self.hz = self.rz
        self.cz = self.hz  # centre height (bottom on z = 0, top on z = height)

    def half_width_at(self, z):
        """Horizontal half-extent of the body at height z (0 at the poles of a ball)."""
        if self.shape == "Block" or self.shape == "Cylinder":
            return self.hx
        w = (z - self.cz) / self.rz
        return self.r * math.sqrt(max(0.0, 1.0 - w * w))

    def surface_y(self, x, z, sign=-1.0):
        """y of the body surface at (x, z) on the front (sign -1) or back (sign +1)."""
        if self.shape == "Block":
            return sign * self.hy
        if self.shape == "Cylinder":
            return sign * math.sqrt(max(0.0, self.r * self.r - x * x))
        u = x / self.r
        w = (z - self.cz) / self.rz
        return sign * self.r * math.sqrt(max(0.0, 1.0 - u * u - w * w))


class Builder:
    def __init__(self, species, tier_colour_hex, detail):
        self.sp = species
        self.d = DETAIL[detail]
        self.parts = []  # (object, material)
        ph = species["placeholder"]
        self.tier = species["tier"]
        self.shape = ph.get("shape", "Ball")
        self.h = BODY_HEIGHT_UNITS * float(ph.get("scale", 1.0))
        self.body = Body(self.shape, self.h)

        body_hex = "1A1A1A" if self.tier == "Secret" else ph.get("color", "FFFFFF")
        body_rgb = hex_to_rgb(body_hex)
        acc_rgb, acc_rule = accessory_colour(body_rgb, species.get("concept", ""))
        self.acc_rule = acc_rule
        self.accessory = pick_accessory(species.get("concept", ""))
        acc_metallic = 1.0 if (self.tier in ("Rare",) or acc_rule == "silver") else 0.0
        acc_emission = 3.0 if (self.tier in ("Cosmic", "Secret") or self.accessory == "glow_bulb") else 0.0
        acc_rough = 0.35 if acc_metallic else 0.8
        self.colours = {
            "Body": body_hex.upper(), "BodyDark": rgb_to_hex(darken(body_rgb)), "Accessory": rgb_to_hex(acc_rgb),
            "Trim": tier_colour_hex.upper(),
        }
        self.mat = {
            "Body": make_material("Body", body_rgb),
            "BodyDark": make_material("BodyDark", darken(body_rgb)),
            "EyeWhite": make_material("EyeWhite", (1.0, 1.0, 1.0), roughness=0.5),
            "Pupil": make_material("Pupil", (0.03, 0.03, 0.04), roughness=0.4),
            "Mouth": make_material("Mouth", (0.18, 0.05, 0.08)),
            "Accessory": make_material("Accessory", acc_rgb, roughness=acc_rough, metallic=acc_metallic, emission=acc_emission),
            "Trim": make_material("Trim", hex_to_rgb(tier_colour_hex), roughness=0.3, metallic=1.0),
        }
        self.acc_metallic = bool(acc_metallic)
        self.acc_emissive = acc_emission > 0.0

    # ---- primitives -------------------------------------------------------------------------------
    def _take(self, mat_key, smooth=True):
        obj = bpy.context.view_layer.objects.active
        obj.data.materials.append(self.mat[mat_key])
        for p in obj.data.polygons:
            p.use_smooth = smooth
        self.parts.append(obj)
        return obj

    def sphere(self, mat_key, radius, loc, segs, scale=(1, 1, 1), rot=(0, 0, 0)):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segs[0], ring_count=segs[1], radius=radius, location=loc)
        obj = self._take(mat_key)
        obj.scale = scale
        obj.rotation_euler = rot
        return obj

    def half_sphere(self, mat_key, radius, loc, segs, rot=(0, 0, 0)):
        obj = self.sphere(mat_key, radius, loc, segs, rot=rot)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -1e-5], context="VERTS")
        bm.to_mesh(obj.data)
        bm.free()
        return obj

    def cylinder(self, mat_key, radius, depth, loc, rot=(0, 0, 0), verts=None, smooth=True):
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts or self.d["cyl"], radius=radius, depth=depth, location=loc)
        obj = self._take(mat_key, smooth=smooth)
        obj.rotation_euler = rot
        return obj

    def cone(self, mat_key, r1, r2, depth, loc, rot=(0, 0, 0), verts=None):
        bpy.ops.mesh.primitive_cone_add(vertices=verts or self.d["cyl"], radius1=r1, radius2=r2, depth=depth, location=loc)
        obj = self._take(mat_key)
        obj.rotation_euler = rot
        return obj

    def cube(self, mat_key, size, loc, scale=(1, 1, 1), bevel=0.0, segments=3, rot=(0, 0, 0)):
        bpy.ops.mesh.primitive_cube_add(size=size, location=loc)
        obj = self._take(mat_key, smooth=False)
        obj.scale = scale
        obj.rotation_euler = rot
        if bevel > 0.0:
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = bevel
            mod.segments = segments
            mod.limit_method = "NONE"
        return obj

    def torus(self, mat_key, major, minor, loc, rot=(0, 0, 0)):
        bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=self.d["torus"][0],
                                         minor_segments=self.d["torus"][1], location=loc, rotation=rot)
        return self._take(mat_key)

    @staticmethod
    def along(start, rot, length):
        """Point `length` along the local +Z of a part rotated by Euler `rot`, from `start`."""
        direction = Euler(rot, "XYZ").to_matrix() @ Vector((0.0, 0.0, 1.0))
        return Vector(start) + direction * length

    # ---- body, face, limbs ------------------------------------------------------------------------
    def build_body(self):
        h, b = self.h, self.body
        if self.shape == "Block":
            self.cube("Body", 1.0, (0, 0, b.cz), scale=(2 * b.hx, 2 * b.hy, 2 * b.hz), bevel=0.18 * h, segments=3)
        elif self.shape == "Cylinder":
            bpy.ops.mesh.primitive_cylinder_add(vertices=self.d["body"][0], radius=b.r, depth=h, location=(0, 0, b.cz))
            obj = self._take("Body", smooth=False)
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = 0.12 * h
            mod.segments = 3
            mod.limit_method = "ANGLE"
            mod.angle_limit = math.radians(30)
        else:
            self.sphere("Body", b.r, (0, 0, b.cz), self.d["body"], scale=(1.0, 1.0, 0.9))

    def build_face(self):
        h, b = self.h, self.body
        eye_r = 0.11 * h  # eyes are 22% of the body height
        eye_z = 0.66 * h
        for side in (-1.0, 1.0):
            x = side * 0.21 * h
            y = b.surface_y(x, eye_z, -1.0) + 0.45 * eye_r
            self.sphere("EyeWhite", eye_r, (x, y, eye_z), self.d["eye"])
            px, py, pz = x, y - 0.62 * eye_r, eye_z + 0.02 * h
            self.sphere("Pupil", 0.5 * eye_r, (px, py, pz), self.d["pupil"])
            self.sphere("EyeWhite", 0.18 * eye_r, (px - 0.2 * eye_r, py - 0.42 * eye_r, pz + 0.22 * eye_r), self.d["highlight"])
        mouth_r = 0.06 * h
        mz = 0.44 * h
        my = b.surface_y(0.0, mz, -1.0) + 0.25 * mouth_r
        self.sphere("Mouth", mouth_r, (0.0, my, mz), self.d["mouth"], scale=(1.3, 0.5, 0.6))

    def build_limbs(self):
        h, b = self.h, self.body
        limb_r = 0.16 * h
        zs = 0.75
        for sx in (-1.0, 1.0):
            for sy in (-1.0, 1.0):
                x = sx * 0.55 * b.hx
                y = sy * 0.5 * b.hy
                self.sphere("BodyDark", limb_r, (x, y, limb_r * zs), self.d["limb"], scale=(1.0, 1.1, zs))

    # ---- accessories ------------------------------------------------------------------------------
    def build_accessory(self):
        getattr(self, "acc_" + self.accessory)()

    def acc_tuft(self):
        h = self.h
        top = (0.0, 0.0, h + 0.07 * h)
        for i, (dx, ry) in enumerate(((0.0, 0.0), (-0.06 * h, -0.5), (0.06 * h, 0.5))):
            self.cone("Accessory", 0.06 * h, 0.0, 0.26 * h, (dx, 0.0, top[2]), rot=(-0.1, ry, 0.0))

    def acc_antlers(self):
        h = self.h
        for s in (-1.0, 1.0):
            base = Vector((s * 0.18 * h, 0.02 * h, 0.96 * h))
            trunk_rot = (-0.17, s * 0.35, 0.0)
            self.cylinder("Accessory", 0.06 * h, 0.52 * h, self.along(base, trunk_rot, 0.26 * h), rot=trunk_rot)
            for frac, rot, length in ((0.28, (0.35, s * 1.05, 0.0), 0.26 * h), (0.52, (-0.45, s * 0.8, 0.0), 0.24 * h)):
                attach = self.along(base, trunk_rot, frac * 0.52 * h)
                self.cylinder("Accessory", 0.045 * h, length, self.along(attach, rot, length * 0.5), rot=rot)
            tip = self.along(base, trunk_rot, 0.52 * h)
            self.sphere("Accessory", 0.065 * h, tip, self.d["small"])

    def acc_wings(self):
        h, b = self.h, self.body
        z = 0.62 * h
        y = b.surface_y(0.0, z, 1.0) * 0.75
        for s in (-1.0, 1.0):
            self.sphere("Accessory", 0.5 * h, (s * 0.55 * h, y, z + 0.05 * h), self.d["acc"],
                        scale=(1.0, 0.12, 0.55), rot=(0.3, -s * 0.4, s * 0.15))

    def acc_quills(self):
        h, b = self.h, self.body
        rows = [(0.0, (0.0, 0.3, 0.6, 0.9, 1.2)), (0.16 * h, (0.25, 0.65, 1.05)), (-0.16 * h, (0.25, 0.65, 1.05))]
        for x, thetas in rows:
            k = math.sqrt(max(0.0, 1.0 - (x / b.hx) ** 2))
            for th in thetas:
                base = Vector((x, math.sin(th) * b.hy * k * 0.97, b.cz + math.cos(th) * b.hz * k * 0.97))
                if self.shape != "Ball":
                    base = Vector((x, math.sin(th) * b.hy * 0.9, b.cz + math.cos(th) * b.hz * 0.9))
                rot = (-th, 0.0, 0.0)
                self.cone("Accessory", 0.075 * h, 0.0, 0.34 * h, self.along(base, rot, 0.12 * h), rot=rot)

    def acc_shell(self):
        h, b = self.h, self.body
        z = 0.6 * h
        rot = (-0.64, 0.0, 0.0)  # flat side against the back, dome pointing back and up
        centre = (0.0, b.surface_y(0.0, z, 1.0) + 0.02 * h, z + 0.04 * h)
        self.half_sphere("Accessory", 0.5 * h, centre, self.d["acc"], rot=rot)
        self.torus("Accessory", 0.48 * h, 0.04 * h, centre, rot=rot)

    def acc_tail(self):
        h, b = self.h, self.body
        pos = Vector((0.0, b.surface_y(0.0, 0.3 * h, 1.0) - 0.04 * h, 0.3 * h))
        segments = ((math.radians(25), 0.3 * h, 0.11 * h, 0.085 * h), (math.radians(55), 0.28 * h, 0.085 * h, 0.06 * h),
                    (math.radians(80), 0.24 * h, 0.06 * h, 0.035 * h))
        for phi, length, r1, r2 in segments:
            rot = (phi - math.pi / 2.0, 0.0, 0.0)
            self.cone("Body", r1, r2, length, self.along(pos, rot, length * 0.5), rot=rot)
            pos = self.along(pos, rot, length)
        self.sphere("Accessory", 0.14 * h, pos, self.d["acc"])

    def acc_crest(self):
        h = self.h
        for s in (-1.0, 1.0):
            base = Vector((s * 0.1 * h, 0.0, 0.97 * h))
            rot = (-0.15, s * 0.45, 0.0)
            self.cylinder("Accessory", 0.03 * h, 0.45 * h, self.along(base, rot, 0.225 * h), rot=rot)
            self.sphere("Accessory", 0.075 * h, self.along(base, rot, 0.45 * h), self.d["small"])

    def acc_leaf_hat(self):
        h = self.h
        self.sphere("Accessory", 0.42 * h, (0.1 * h, 0.04 * h, h + 0.06 * h), self.d["acc"], scale=(0.6, 1.0, 0.16), rot=(0.35, 0.25, 0.5))
        self.cylinder("Accessory", 0.03 * h, 0.22 * h, (-0.05 * h, -0.02 * h, h + 0.12 * h), rot=(-0.4, -0.2, 0.0))

    def acc_sun_disk(self):
        h, b = self.h, self.body
        z = 0.78 * h
        self.cylinder("Accessory", 0.5 * h, 0.04 * h, (0.0, b.surface_y(0.0, z, 1.0) + 0.08 * h, z),
                      rot=(math.pi / 2.0, 0.0, 0.0), verts=self.d["disk"], smooth=False)
        for ry in (-0.45, 0.0, 0.45):
            loc = self.along((0.0, 0.0, h - 0.02 * h), (0.0, ry, 0.0), 0.2 * h)
            self.sphere("Accessory", 0.2 * h, loc, self.d["small"], scale=(0.35, 0.14, 1.0), rot=(0.0, ry, 0.0))

    def acc_horns(self):
        h = self.h
        for s in (-1.0, 1.0):
            rot = (-0.25, s * 0.55, 0.0)
            base = Vector((s * 0.2 * h, -0.02 * h, 0.9 * h))
            self.cone("Accessory", 0.08 * h, 0.012 * h, 0.34 * h, self.along(base, rot, 0.17 * h), rot=rot)

    def acc_backpack(self):
        h, b = self.h, self.body
        z = 0.55 * h
        depth = 0.38 * h * 0.7
        self.cube("Accessory", 0.38 * h, (0.0, b.surface_y(0.0, z, 1.0) + depth * 0.5, z), scale=(1.0, 0.7, 1.25), bevel=0.04 * h, segments=2)

    def acc_claws(self):
        h, b = self.h, self.body
        for s in (-1.0, 1.0):
            self.sphere("Accessory", 0.24 * h, (s * (b.hx + 0.1 * h), -b.hy * 0.8, 0.3 * h), self.d["acc"], scale=(1.0, 1.2, 0.9))

    def acc_puff_ring(self):
        h, b = self.h, self.body
        z = 0.72 * h
        ring_r = b.half_width_at(z) + 0.06 * h
        n = 12
        for i in range(n):
            a = 2.0 * math.pi * i / n
            self.sphere("Accessory", 0.1 * h, (math.cos(a) * ring_r, math.sin(a) * ring_r, z), self.d["small"])

    def acc_glow_bulb(self):
        h = self.h
        base = Vector((0.0, 0.0, 0.97 * h))
        rot = (-0.35, 0.0, 0.0)
        self.cylinder("BodyDark", 0.028 * h, 0.42 * h, self.along(base, rot, 0.21 * h), rot=rot)
        self.sphere("Accessory", 0.15 * h, self.along(base, rot, 0.44 * h), self.d["acc"])

    # ---- tier dressing ----------------------------------------------------------------------------
    def build_tier_dressing(self):
        h, b = self.h, self.body
        notes = []
        if self.tier == "Epic":
            z = 0.8 * h
            self.torus("Trim", b.half_width_at(z) * 1.02 + 0.02 * h, 0.045 * h, (0.0, 0.0, z))
            notes.append("collar torus")
        elif self.tier == "Legendary":
            self.torus("Trim", 0.4 * h, 0.035 * h, (0.0, 0.0, h + 0.2 * h))
            self.torus("Trim", max(b.hx, b.hy) * 1.35, 0.04 * h, (0.0, 0.0, 0.04 * h))
            notes.append("halo torus")
            notes.append("ground ring torus")
        if self.tier == "Rare":
            notes.append("metallic accessory")
        if self.tier in ("Cosmic", "Secret"):
            notes.append("emissive accessory")
        if self.tier == "Secret":
            notes.append("black body")
        # The size step per tier is already in placeholder.scale (Species.luau: Thunderhog 1.2,
        # Gaiabloom 1.25, Ra-dish 1.2), so the tier table here only documents it; applying both would
        # double the step and push the top tiers past the 2 to 3 unit guidance.
        scale = 1.0
        documented = TIER_SCALE.get(self.tier, 1.0)
        if documented != 1.0:
            notes.insert(0, "tier size %d%% (carried by placeholder.scale)" % round(documented * 100))
        return notes, scale

    # ---- join -------------------------------------------------------------------------------------
    def join(self, name, scale):
        """Evaluate modifiers, bake transforms and merge every part into one mesh, keeping material slots."""
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        bm = bmesh.new()
        slots = []
        for obj in self.parts:
            ev = obj.evaluated_get(depsgraph)
            me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=depsgraph)
            me.transform(obj.matrix_world)
            mat = obj.data.materials[0]
            if mat not in slots:
                slots.append(mat)
            idx = slots.index(mat)
            for p in me.polygons:
                p.material_index = idx
            bm.from_mesh(me)
            bpy.data.meshes.remove(me)
        final = bpy.data.meshes.new(name)
        bm.to_mesh(final)
        bm.free()
        for mat in slots:
            final.materials.append(mat)
        if scale != 1.0:
            final.transform(Matrix.Scale(scale, 4))
        final.update()
        for obj in self.parts:
            bpy.data.objects.remove(obj, do_unlink=True)
        self.parts = []
        out = bpy.data.objects.new(name, final)
        bpy.context.scene.collection.objects.link(out)
        bpy.context.view_layer.objects.active = out
        out.select_set(True)
        return out


def pick_accessory(concept):
    c = concept.lower()
    for keywords, acc in ACCESSORY_RULES:
        for kw in keywords:
            if re.search(r"\b" + kw, c):
                return acc
    return "tuft"


def triangle_count(mesh):
    return sum(len(p.vertices) - 2 for p in mesh.polygons)


def mesh_height(mesh):
    zs = [v.co.z for v in mesh.vertices]
    return (max(zs) - min(zs)) if zs else 0.0


# -------------------------------------------------------------------------------------------------- run
def build_species(species, tier_colour_hex, detail):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    builder = Builder(species, tier_colour_hex, detail)
    builder.build_body()
    builder.build_face()
    builder.build_limbs()
    builder.build_accessory()
    dressing, scale = builder.build_tier_dressing()
    obj = builder.join(species["id"], scale)
    return builder, obj, dressing


def export(obj, out_dir, species_id):
    out_dir.mkdir(parents=True, exist_ok=True)
    glb = out_dir / ("%s.glb" % species_id)
    fbx = out_dir / ("%s.fbx" % species_id)
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", export_apply=True, export_animations=False,
                              export_yup=True, use_selection=False, export_materials="EXPORT", export_lights=False, export_cameras=False)
    bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=False, apply_scale_options="FBX_SCALE_ALL",
                             mesh_smooth_type="FACE", bake_anim=False, add_leaf_bones=False, path_mode="AUTO")
    write_materials_json(obj, out_dir)  # props_base.py reaches this through export() as well
    return glb, fbx


def write_notes(path, species, builder, accessory, dressing, tris, height, detail, glb, fbx):
    lines = [
        "# %s blockout" % species["id"],
        "",
        "- Date: %s" % datetime.date.today().isoformat(),
        "- Tool: %s" % TOOL_NAME,
        "- Name: %s (%s)" % (species.get("name", species["id"]), species.get("tier", "?")),
        "- Concept: %s" % species.get("concept", ""),
        "- Body: %s, placeholder colour #%s, placeholder scale %s" % (builder.shape, builder.colours["Body"], species["placeholder"].get("scale", 1)),
        "- Accessory: %s (keyword match on the concept; colour rule: %s, #%s%s%s)" % (
            accessory, builder.acc_rule, builder.colours["Accessory"],
            ", metallic" if builder.acc_metallic else "", ", emissive" if builder.acc_emissive else ""),
        "- Tier dressing: %s" % (", ".join(dressing) if dressing else "none (Common/Uncommon: the accessory is the prop)"),
        "- Triangles: %d (budget %d to %d, detail level %d)" % (tris, TRI_MIN, TRI_MAX, detail),
        "- Height: %.2f units (1 unit = 1 stud), standing on the origin, built Z-up and exported Y-up" % height,
        "- Materials (one per colour, flat, no textures): Body #%s, BodyDark #%s, EyeWhite, Pupil, Mouth, Accessory #%s%s" % (
            builder.colours["Body"], builder.colours["BodyDark"], builder.colours["Accessory"],
            (", Trim #%s" % builder.colours["Trim"]) if builder.tier in ("Epic", "Legendary") else ""),
        "- Facing: the face is on -Y in Blender. The FBX exporter (forward -Z, up Y) writes it on -Z, Roblox's front; the GLB exporter writes it on +Z (glTF forward), so a GLB import needs Config.ModelFacesPlusZ = true.",
        "- Files: %s (%d bytes), %s (%d bytes)" % (glb.name, glb.stat().st_size, fbx.name, fbx.stat().st_size),
        "- Studio import: File -> Import 3D, keep scale 1, one MeshPart per material (each part gets its Color).",
        "",
        "Blockout tier: a procedural stand-in. Replace with an AI-generated or hand-modelled mesh of the same height when one exists.",
        "",
    ]
    path.write_text("\n".join(lines))


def parse_args():
    argv = sys.argv[1:]
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser(description="Generate blockout alien meshes from Species.luau")
    ap.add_argument("--species", default="", help="comma-separated species ids (default: all)")
    ap.add_argument("--out", default=str(ROOT / "assets/models"), help="output root (default assets/models)")
    ap.add_argument("--all", action="store_true", help="build every species (default when --species is empty)")
    return ap.parse_args(argv)


def main():
    args = parse_args()
    species_list = load(DATA / "Species.luau")["List"]
    tiers = load(DATA / "Tiers.luau")["Tiers"]
    wanted = [s.strip() for s in args.species.split(",") if s.strip()]
    if wanted:
        by_id = {s["id"]: s for s in species_list}
        missing = [w for w in wanted if w not in by_id]
        if missing:
            print("unknown species: %s" % ", ".join(missing))
            sys.exit(2)
        species_list = [by_id[w] for w in wanted]
    out_root = pathlib.Path(args.out)
    if not out_root.is_absolute():
        out_root = pathlib.Path.cwd() / out_root

    rows = []
    over_budget = []
    total_bytes = 0
    for sp in species_list:
        tier_colour = tiers.get(sp["tier"], {}).get("color", "FFFFFF")
        detail = 0
        while True:
            builder, obj, dressing = build_species(sp, tier_colour, detail)
            tris = triangle_count(obj.data)
            if tris <= TRI_MAX or detail >= len(DETAIL) - 1:
                break
            detail += 1
        height = mesh_height(obj.data)
        out_dir = out_root / sp["id"]
        glb, fbx = export(obj, out_dir, sp["id"])
        write_notes(out_dir / "notes.md", sp, builder, builder.accessory, dressing, tris, height, detail, glb, fbx)
        sizes = (glb.stat().st_size, fbx.stat().st_size)
        total_bytes += sum(sizes)
        flag = ""
        if tris > TRI_MAX:
            over_budget.append(sp["id"])
            flag = "  OVER BUDGET"
        elif tris < TRI_MIN:
            flag = "  under %d" % TRI_MIN
        rows.append((sp["id"], builder.accessory, tris, height, sizes[0], sizes[1]))
        print("%-12s %-10s tris=%4d  height=%.2f  glb=%6d B  fbx=%6d B  detail=%d%s" % (
            sp["id"], builder.accessory, tris, height, sizes[0], sizes[1], detail, flag), flush=True)

    print("")
    print("%d species, %.2f MB total" % (len(rows), total_bytes / 1e6))
    if over_budget:
        print("over %d triangles: %s" % (TRI_MAX, ", ".join(over_budget)))
        sys.exit(1)


if __name__ == "__main__":
    main()
