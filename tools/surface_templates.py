#!/usr/bin/env python3
"""Generate the SurfaceAppearance templates Rojo ships, one per row of src/shared/data/Textures.luau.

Why: a game Script cannot create a SurfaceAppearance (Instance.new then .ColorMap fails with "lacking capability Plugin",
docs/vault/04-roblox-engine/SurfaceAppearance-Capability.md). What does work is cloning one that was made ahead of time, at
plugin level, which is what a Rojo build does with a .model.json. Services/Models clones
ReplicatedStorage.Shared.SurfaceTemplates.<key> and sets its Color. The Image ids live in Textures.luau only; this tool copies
them, so they never exist in two places by hand.

One file per row: src/shared/SurfaceTemplates/<key>.model.json (the file name is the Textures key and the instance name).
Properties: ColorMap, NormalMap and RoughnessMap as rbxassetid://<id> (a MetalnessMap too when a row ever gets a `metalnessMap`),
AlphaMode Overlay (the engine default, written out) and Color white (the loader sets the part's colour on each clone).
An id of 0 means not uploaded yet: the file is still written, that property left out, and the loader skips the row
(ModelInstall.MapsOf wants all three ids).

Offline, standard library only. --write (default) regenerates the files and removes stale ones; --check fails when any file
differs from what Textures.luau says (CI parity: tools/tests/test_surfaces.py runs it); --self-test checks the rendering.
"""
import argparse
import json
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint_data import TableReader

ROOT = Path(__file__).resolve().parents[1]
TEXTURES = Path('src/shared/data/Textures.luau')
OUTPUT = Path('src/shared/SurfaceTemplates')
SUFFIX = '.model.json'
# Textures.luau field -> SurfaceAppearance property (the maps; tiling is not a property of the appearance).
MAPS = (('colorMap', 'ColorMap'), ('normalMap', 'NormalMap'), ('roughnessMap', 'RoughnessMap'), ('metalnessMap', 'MetalnessMap'))
ALPHA_MODE = 'Overlay'
WHITE = [1, 1, 1]


def template(row):
    """One row's .model.json content as a dict (a map with a zero or absent id is left out)."""
    properties = {}
    for field, prop in MAPS:
        asset = row.get(field, 0)
        if type(asset) is not int or asset < 0:
            raise ValueError(f'{field} must be a non-negative integer, got {asset!r}')
        if asset > 0:
            properties[prop] = f'rbxassetid://{asset}'
    properties['AlphaMode'] = ALPHA_MODE
    properties['Color'] = list(WHITE)
    return {'ClassName': 'SurfaceAppearance', 'Properties': properties}


def render(row):
    return json.dumps(template(row), indent=2) + '\n'


def files(textures):
    """file name -> text, for every Textures row (sorted)."""
    out = {}
    for key, row in sorted(textures.items()):
        if not isinstance(key, str) or not re.fullmatch(r'[a-z][a-z0-9]*', key):
            raise ValueError(f'Textures key {key!r} must be lower-case letters and digits')
        if not isinstance(row, dict):
            raise ValueError(f'Textures.{key} is not a row')
        try:
            out[key + SUFFIX] = render(row)
        except ValueError as exc:
            raise ValueError(f'Textures.{key}: {exc}') from exc
    if not out:
        raise ValueError('Textures.luau has no rows')
    return out


def existing(folder):
    return {path.name: path.read_text() for path in sorted(folder.glob('*' + SUFFIX))} if folder.is_dir() else {}


def self_test():
    row = {'colorMap': 11, 'normalMap': 22, 'roughnessMap': 33, 'tiling': {1: 2, 2: 2}}
    assert template(row) == {'ClassName': 'SurfaceAppearance', 'Properties': {
        'ColorMap': 'rbxassetid://11', 'NormalMap': 'rbxassetid://22', 'RoughnessMap': 'rbxassetid://33',
        'AlphaMode': 'Overlay', 'Color': [1, 1, 1]}}
    assert 'NormalMap' not in template(dict(row, normalMap=0))['Properties']  # 0 = not uploaded: omitted
    assert template(dict(row, metalnessMap=44))['Properties']['MetalnessMap'] == 'rbxassetid://44'
    assert set(files({'fur': row, 'moss': row})) == {'fur.model.json', 'moss.model.json'}
    assert json.loads(render(row)) == template(row) and render(row).endswith('}\n')
    for bad in ({'colorMap': -1}, {'colorMap': '5'}, {'colorMap': 1.5}):
        try:
            template(bad)
        except ValueError:
            continue
        raise AssertionError(f'{bad} accepted')
    for bad_key in ({'Fur': row}, {'fur skin': row}, {}):
        try:
            files(bad_key)
        except ValueError:
            continue
        raise AssertionError(f'{bad_key} accepted')
    print('surface templates self-test: 5 passed (properties, omitted zero id, metalness, file names, invalid input)')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true', help='regenerate src/shared/SurfaceTemplates (default)')
    mode.add_argument('--check', action='store_true', help='fail if any file differs from Textures.luau')
    mode.add_argument('--self-test', action='store_true', help='run deterministic offline checks')
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
            return 0
        wanted = files(TableReader().read(ROOT / TEXTURES))
        folder = ROOT / OUTPUT
        have = existing(folder)
        if args.check:
            problems = [f'{name}: missing' for name in sorted(wanted.keys() - have.keys())]
            problems += [f'{name}: no Textures row' for name in sorted(have.keys() - wanted.keys())]
            problems += [f'{name}: differs from Textures.luau' for name in sorted(wanted.keys() & have.keys()) if wanted[name] != have[name]]
            if problems:
                raise ValueError('SurfaceTemplates are stale (' + '; '.join(problems) + '); run python3 -I tools/surface_templates.py --write')
        else:
            folder.mkdir(parents=True, exist_ok=True)
            for name in sorted(have.keys() - wanted.keys()):
                (folder / name).unlink()
            for name, text in wanted.items():
                (folder / name).write_text(text)
        unset = sorted(name[:-len(SUFFIX)] for name, text in wanted.items()
                       if not all(f'"{prop}"' in text for _, prop in MAPS[:3]))
        print(f'surface templates: {len(wanted)} rows; {"checked" if args.check else "wrote"} {OUTPUT}'
              + (f'; not uploaded yet (a map id is 0): {", ".join(unset)}' if unset else ''))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('surface templates: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
