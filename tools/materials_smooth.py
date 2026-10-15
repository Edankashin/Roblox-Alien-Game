#!/usr/bin/env python3
"""Make every materials.json smooth by default: drop the tiled texture maps that read as grain, keep the ones the design wants.

The rule is tools/blender/surface_defaults.py (docs/vault/06-art-pipelines/Surface-Pass.md, "No grain (2026-10-15)"): a slot's `texture`
stays only when its key is on KEEP_TEXTURE (stone, ice); any other key is dropped and the slot becomes SmoothPlastic when it had no
`material` or Fabric or Grass (the Roblox materials that went with those maps). The vertex gradient, `glossy` and every other field stay.
Run `python3 -I tools/model_assets.py --write` after it: ModelAssets.Surfaces is generated from these files.

  python3 -I tools/materials_smooth.py                  # report what would change (no file is written)
  python3 -I tools/materials_smooth.py --write          # rewrite the files that change (idempotent: a second run changes nothing)
  python3 -I tools/materials_smooth.py --check          # exit 1 when any file would change (the CI form)
  python3 -I tools/materials_smooth.py --models DIR     # a scratch copy laid out like assets/models (species folders and props/<Id>)

Offline, standard library only. Covers assets/models/<Id>/materials.json (the 35 species) and assets/models/props/<Id>/materials.json
(no prop names a texture today, so none changes). It never touches a GLB, an FBX or notes.md.
"""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/blender'))
import surface_defaults  # noqa: E402


def material_files(models):
    """Every materials.json under `models`: the species folders, then the props."""
    return sorted(models.glob('*/materials.json')) + sorted(models.glob('props/*/materials.json'))


def load(path):
    try:
        entries = json.loads(path.read_text())
    except ValueError as exc:
        raise SystemExit(f'cannot read {path}: {exc}')
    if not isinstance(entries, list) or not all(isinstance(entry, dict) for entry in entries):
        raise SystemExit(f'{path}: materials.json must be a list of slot objects')
    return entries


def plan(models):
    """[(path, smoothed entries, [one line per changed slot])] for the files that change."""
    changes = []
    for path in material_files(models):
        entries = load(path)
        result = [surface_defaults.smoothed(entry) for entry in entries]
        if result == entries:
            continue
        lines = [f'{old["name"]}: {old["texture"]} + {old.get("material", "no material")} -> {new["material"]}, no texture'
                 for old, new in zip(entries, result) if old != new]
        changes.append((path, result, lines))
    return changes


def textured_slots(files):
    return sum(1 for path in files for entry in load(path) if 'texture' in entry)


def main(argv=None):
    parser = argparse.ArgumentParser(description='Smooth every materials.json: no tiled texture off the allowlist')
    parser.add_argument('--models', default=str(ROOT / 'assets/models'), help='models folder (default assets/models)')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true', help='rewrite the files that change')
    mode.add_argument('--check', action='store_true', help='exit 1 when any file would change')
    args = parser.parse_args(argv)
    models = Path(args.models).resolve()
    if not models.is_dir():
        print(f'no models folder: {models}')
        return 2
    files = material_files(models)
    changes = plan(models)
    slots = sum(len(lines) for _, _, lines in changes)
    for path, _, lines in changes:
        print(f'{path.parent.name}: ' + '; '.join(lines))
    allowed = ', '.join(surface_defaults.KEEP_TEXTURE)
    if args.write:
        for path, result, _ in changes:
            path.write_text(json.dumps(result, indent=2) + '\n')
        print(f'written: {len(files)} materials.json, {len(changes)} rewritten, {slots} slots lost their texture, '
              f'{textured_slots(files)} keep one ({allowed})')
        return 0
    if args.check:
        if changes:
            print(f'materials_smooth: {len(changes)} materials.json are not smooth by default ({slots} slots); '
                  'run python3 -I tools/materials_smooth.py --write')
            return 1
        print(f'materials_smooth: clean ({len(files)} materials.json, {textured_slots(files)} slots keep a texture: {allowed})')
        return 0
    print(f'{len(files)} materials.json, {len(changes)} would change, {slots} slots would lose their texture, '
          f'{textured_slots(files) - slots} would keep one ({allowed}); nothing written, pass --write')
    return 0


if __name__ == '__main__':
    sys.exit(main())
