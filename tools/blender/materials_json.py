#!/usr/bin/env python3
"""Write materials.json next to every existing GLB, without regenerating any mesh.

An Open Cloud Assets upload of a .glb keeps one MeshPart per material slot (named <Name>, <Name>2, <Name>3 in
primitive order) but drops the colours, so each model folder carries a materials.json that lists the slots in
order with colour and look; the Studio installer colours each MeshPart by index. Hand-tuned meshes (Mossbop,
Pebblet, Glimmo, Twiglet, Puffpuff, Snailbyte, Buzzlebee, Lanternewt) differ from what alien_base.py would
generate, so this tool READS the GLB (fresh scene, glTF import) and never builds anything.

Format (same writer as alien_base.export): a list in slot order of
    { "slot": 1, "name": "Body", "hex": "6BCB3F", "roughness": 0.8, "metallic": 0.0, "emission": 0.0 }
hex is the Principled Base Color through alien_base.rgb_to_hex (the exact inverse of hex_to_rgb, no transfer
curve: the generator stores hex/255 as the Base Color and glTF carries it unchanged). If the importer splits a
model into several objects the slots are written object by object (sorted by name), then slot by slot.

Usage (plain Python with the bpy module, or inside a Blender binary):
    python3 tools/blender/materials_json.py --all
    python3 tools/blender/materials_json.py --only Mossbop,MeadowTree [--models assets/models]
Prints one line per model; the check column compares the slot names with the material order of the GLB
primitives. Exit code 1 if any model fails to import or the check mismatches, 2 for an unknown model name.
"""
import argparse
import json
import pathlib
import struct
import sys

import bpy

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from alien_base import ROOT, material_entries, write_materials_entries  # noqa: E402


def find_models(models_root):
    """(name, glb path) for every species folder and props/<Name> folder holding <name>.glb, species first."""
    found = []
    for d in sorted(models_root.iterdir()):
        if d.is_dir() and d.name != "props" and (d / (d.name + ".glb")).exists():
            found.append((d.name, d / (d.name + ".glb")))
    props = models_root / "props"
    if props.is_dir():
        for d in sorted(props.iterdir()):
            if d.is_dir() and (d / (d.name + ".glb")).exists():
                found.append((d.name, d / (d.name + ".glb")))
    return found


def glb_primitive_materials(path):
    """Material names in primitive order straight from the GLB's JSON chunk (the order Studio makes parts in)."""
    data = path.read_bytes()
    length = struct.unpack("<I", data[12:16])[0]
    doc = json.loads(data[20:20 + length])
    names = [m.get("name", "") for m in doc.get("materials", [])]
    return [names[p["material"]] for mesh in doc.get("meshes", []) for p in mesh["primitives"] if "material" in p]


def read_model(glb):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(glb))
    objs = sorted((o for o in bpy.data.objects if o.type == "MESH"), key=lambda o: o.name)
    return objs, material_entries(objs)


def main():
    argv = sys.argv[1:]
    if "--" in sys.argv:
        argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser(description="Write materials.json next to every GLB under assets/models")
    ap.add_argument("--all", action="store_true", help="every species and prop")
    ap.add_argument("--only", default="", help="comma-separated species ids or prop names")
    ap.add_argument("--models", default=str(ROOT / "assets/models"), help="models root (default assets/models)")
    args = ap.parse_args(argv)

    models = find_models(pathlib.Path(args.models))
    wanted = [w.strip() for w in args.only.split(",") if w.strip()]
    if wanted and not args.all:
        known = dict(models)
        missing = [w for w in wanted if w not in known]
        if missing:
            print("unknown model: %s" % ", ".join(missing))
            sys.exit(2)
        models = [(w, known[w]) for w in wanted]
    elif not wanted and not args.all:
        ap.error("pass --all or --only A,B")

    bad = 0
    for name, glb in models:
        try:
            objs, entries = read_model(glb)
        except Exception as exc:  # noqa: BLE001 - report and carry on with the next model
            bad += 1
            print("%-12s FAILED %s" % (name, exc), flush=True)
            continue
        write_materials_entries(entries, glb.parent)
        ok = [e["name"] for e in entries] == glb_primitive_materials(glb)
        if not ok:
            bad += 1
        print("%-12s objects=%d slots=%d  %s  %s" % (
            name, len(objs), len(entries), "order ok" if ok else "ORDER MISMATCH",
            " ".join("%s:%s" % (e["name"], e["hex"]) for e in entries)), flush=True)
    print("")
    print("%d models" % len(models))
    if bad:
        sys.exit(1)


if __name__ == "__main__":
    main()
