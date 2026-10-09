#!/usr/bin/env python3
"""Generate ModelAssets.luau from uploaded IDs and the Studio installer's literal data.

Offline, standard library only. Default/--write regenerates the table; --check
compares its data (formatting may differ); --self-test checks round trips and
invalid inputs. No assets are uploaded, loaded, scaled or changed by this tool.
"""
import argparse
import json
import math
from pathlib import Path
import re
import sys
import time
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint_data import LiteralParser, TableReader, uncomment

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path('src/shared/data/ModelAssets.luau')


def installer_data(root):
    source = uncomment((root / 'tools/studio/install_models.luau').read_text())
    wanted = ('PROP_NAMES', 'MATERIALS', 'NORMALISE', 'MODELS_FOLDER', 'PROPS_FOLDER',
              'NEON_EMISSION_ABOVE', 'METAL_METALLIC_FROM')
    result = {}
    for name in wanted:
        matches = list(re.finditer(r'^local\s+' + name + r'(?:\s*:[^\n=]+)?\s*=', source, re.M))
        if len(matches) != 1:
            raise ValueError('expected one installer literal: ' + name)
        # Reuse C2's non-executing parser; never evaluate the Studio script.
        result[name] = LiteralParser(source[matches[0].end():], {}, lambda _: None).expression()
    return result


def data(uploaded, installer):
    ids, props, materials = {}, {}, {}
    for name, row in sorted(uploaded.items()):
        asset = row['assetId']
        if not re.fullmatch(r'[A-Za-z_]\w*', name) or type(asset) is not int or asset <= 0:
            raise ValueError('invalid uploaded model name/id: ' + name)
        ids[name] = asset
        if installer['PROP_NAMES'].get(name) is True:
            props[name] = True
        elif '/props/' in row.get('file', ''):
            raise ValueError('uploaded prop missing installer classification: ' + name)
        if name in installer['MATERIALS']:
            rows = installer['MATERIALS'][name]
            if not rows or set(rows) != set(range(1, len(rows) + 1)):
                raise ValueError('invalid material slot sequence: ' + name)
            for slot in rows.values():
                if (set(slot) != set(range(1, 6)) or not isinstance(slot[1], str)
                        or not re.fullmatch(r'[0-9A-Fa-f]{6}', slot[2])
                        or any(type(slot[i]) not in (int, float) or not math.isfinite(slot[i]) for i in (3, 4, 5))):
                    raise ValueError('invalid material row: ' + name)
            materials[name] = rows
    return dict(AssetIds=ids, PropNames=props, Materials=materials,
                Normalise=installer['NORMALISE'], ModelFolderName=installer['MODELS_FOLDER'],
                PropsFolderName=installer['PROPS_FOLDER'], NeonEmissionAbove=installer['NEON_EMISSION_ABOVE'],
                MetalMetallicFrom=installer['METAL_METALLIC_FROM'])


def literal(value, depth=0):
    if isinstance(value, str): return json.dumps(value, ensure_ascii=True)
    if isinstance(value, bool): return 'true' if value else 'false'
    if isinstance(value, (int, float)): return str(value)
    if not value: return '{}'
    if all(type(k) is int for k in value):
        return '{ ' + ', '.join(literal(value[k], depth) for k in sorted(value)) + ' }'
    indent = '\t' * depth
    return '{\n' + ''.join(indent + '\t' + key + ' = ' + literal(child, depth + 1) + ',\n'
                            for key, child in sorted(value.items())) + indent + '}'


def render(rows):
    return '''--!strict
-- Generated: python3 -I tools/model_assets.py --write (do not hand edit).
-- Inputs: assets/models/asset_ids.json; tools/studio/install_models.luau literal data.
-- ReplicatedStorage.Shared.data.ModelAssets: runtime loader inputs, no loading side effects.
-- AssetIds maps the exact installed model name to its uploaded Model asset id.
-- PropNames selects Models.Props; other names go directly into Models.
-- Materials[name][slot] = { renamedPart, hex, roughness, metallic, emission }.
-- Sort MeshParts by numeric suffix (strip model name first; absent suffix = 1), then
-- original descendant order. Apply matching slots only; warn when counts differ.
-- Neon when emission > NeonEmissionAbove; else Metal when metallic >= MetalMetallicFrom;
-- else SmoothPlastic. Roughness is retained but not applied. Rename parts after colouring.
-- Normalise anchors all BaseParts; creatures also disable CanCollide and CanQuery.
-- A prop without Materials keeps the installer fallback: MeshPart name containing
-- "glow" (case insensitive) gets Neon. Other imported properties are preserved.
-- The installer has no scale/pivot/rotation overrides: preserve the imported baseline.
-- Loading, folder creation, container selection and successful replacement remain loader logic.
''' + 'local Materials: { [string]: { { string | number } } } = ' + literal(rows['Materials']) + '\n\nreturn ' + literal(rows).replace('Materials = ' + literal(rows['Materials'], 1), 'Materials = Materials') + '\n'


def self_test(uploaded, installer):
    rows = data(uploaded, installer)
    source = render(rows)
    with tempfile.TemporaryDirectory() as directory:
        target = Path(directory) / 'ModelAssets.luau'
        target.write_text(source)
        parsed = TableReader().read(target)
    assert parsed == rows
    assert parsed['AssetIds'] == {name: row['assetId'] for name, row in uploaded.items()}
    assert render(data(dict(reversed(list(uploaded.items()))), installer)) == source
    for name, slots in parsed['Materials'].items():
        assert slots == installer['MATERIALS'][name]
    first = next(iter(uploaded))
    invalid = dict(uploaded)
    invalid[first] = dict(uploaded[first], assetId=0)
    try: data(invalid, installer)
    except ValueError: pass
    else: raise AssertionError('zero asset id accepted')
    print('model assets self-test: 5 passed (round trip, IDs, order, materials, invalid ID)')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--write', action='store_true', help='regenerate ModelAssets.luau (default)')
    mode.add_argument('--check', action='store_true', help='fail if generated data differs; ignore formatting')
    mode.add_argument('--self-test', action='store_true', help='run deterministic offline data checks')
    args = parser.parse_args()
    started = time.perf_counter()
    try:
        uploaded = json.loads((ROOT / 'assets/models/asset_ids.json').read_text())
        installer = installer_data(ROOT)
        if args.self_test:
            self_test(uploaded, installer)
            return 0
        rows = data(uploaded, installer)
        if args.check:
            if TableReader().read(ROOT / OUTPUT) != rows:
                raise ValueError('ModelAssets data is stale; run python3 -I tools/model_assets.py --write')
        else:
            (ROOT / OUTPUT).write_text(render(rows))
        count = sum(len(slots) for slots in rows['Materials'].values())
        print(f'model assets: {len(rows["AssetIds"])} models, {len(rows["PropNames"])} props, '
              f'{count} material slots; {"checked" if args.check else "wrote"} {OUTPUT} '
              f'({time.perf_counter() - started:.3f}s)')
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('model assets: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
