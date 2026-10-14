#!/usr/bin/env python3
"""Generate ModelAssets.luau from uploaded IDs, the Studio installer's literal data and the surface fields of materials.json.

The Surface pass adds a Surfaces table: per model and slot name, the optional `material` (a Roblox Material name),
`texture` (a key of src/shared/data/Textures.luau) and `glossy` (true) that assets/models/<Name>/materials.json (or
assets/models/props/<Name>/materials.json) carries beside the slot's colour. A slot without those fields has no row.

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
from lint_data import LiteralParser, SURFACE_MATERIALS, TableReader, uncomment

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path('src/shared/data/ModelAssets.luau')
TEXTURES = Path('src/shared/data/Textures.luau')


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


def surface_files(root, names):
    """name -> the parsed materials.json list, for every named model whose folder has one (species, then props)."""
    found = {}
    for name in names:
        for folder in (root / 'assets/models' / name, root / 'assets/models/props' / name):
            path = folder / 'materials.json'
            if path.is_file():
                try:
                    found[name] = json.loads(path.read_text())
                except ValueError as exc:
                    raise ValueError(f'cannot read {path}: {exc}') from exc
                break
    return found


def surface_rows(name, entries, slot_names, textures):
    """One model's Surfaces rows: {slot name: {material?, texture?, glossy?}} from its materials.json entries."""
    if not isinstance(entries, list) or not all(isinstance(entry, dict) for entry in entries):
        raise ValueError('materials.json must be a list of slot objects: ' + name)
    rows, seen = {}, set()
    for entry in entries:
        slot = entry.get('name')
        if slot in seen:
            raise ValueError(f'duplicate slot name {slot!r}: {name}')
        seen.add(slot)
        spec = {}
        if 'material' in entry:
            if entry['material'] not in SURFACE_MATERIALS:
                raise ValueError(f'{name}.{slot}: material {entry["material"]!r} is not one of {", ".join(SURFACE_MATERIALS)}')
            spec['material'] = entry['material']
        if 'texture' in entry:
            if entry['texture'] not in textures:
                raise ValueError(f'{name}.{slot}: texture {entry["texture"]!r} is not a key of data/Textures ({", ".join(sorted(textures))})')
            spec['texture'] = entry['texture']
        if 'glossy' in entry:
            if type(entry['glossy']) is not bool:
                raise ValueError(f'{name}.{slot}: glossy must be true or false')
            if entry['glossy']:
                spec['glossy'] = True
        if not spec:
            continue
        if slot not in slot_names:
            raise ValueError(f'{name}: surface fields on slot {slot!r}, which is not one of the installer rows ({", ".join(slot_names)})')
        rows[slot] = spec
    return rows


def data(uploaded, installer, files=None, textures=()):
    ids, props, materials, surfaces = {}, {}, {}, {}
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
            if files and name in files:
                found = surface_rows(name, files[name], [row[1] for _, row in sorted(rows.items())], textures)
                if found:
                    surfaces[name] = found
    return dict(AssetIds=ids, PropNames=props, Materials=materials, Surfaces=surfaces,
                Normalise=installer['NORMALISE'], ModelFolderName=installer['MODELS_FOLDER'],
                PropsFolderName=installer['PROPS_FOLDER'], NeonEmissionAbove=installer['NEON_EMISSION_ABOVE'],
                MetalMetallicFrom=installer['METAL_METALLIC_FROM'])


class Raw(str):
    """Luau source written as it is (a reference to a local declared above)."""


def surface_literal(rows):
    """Surfaces: one line per slot, models and slots sorted: Body = { glossy = true, material = "Grass", texture = "moss" }."""
    if not rows: return '{}'
    out = '{\n'
    for name, slots in sorted(rows.items()):
        out += '\t' + name + ' = {\n'
        for slot, spec in sorted(slots.items()):
            out += '\t\t' + slot + ' = { ' + ', '.join(key + ' = ' + literal(spec[key]) for key in sorted(spec)) + ' },\n'
        out += '\t},\n'
    return out + '}'


def literal(value, depth=0):
    if isinstance(value, Raw): return str(value)
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
-- Inputs: assets/models/asset_ids.json; tools/studio/install_models.luau literal data; the material, texture and
-- glossy fields of assets/models/**/materials.json (Surfaces).
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
-- Surfaces[name][slotName] = { material = Roblox Material name, texture = key of data/Textures, glossy = true }, any
-- of the three, for the slots whose materials.json carries them (the Surface pass, Surface-Pass.md). A slot with no
-- row, or a model with no Surfaces entry, keeps the look above. Services/Models applies them after the colours.

local Types = require(script.Parent.Parent.types.Types)

''' + 'local Materials: { [string]: { { string | number } } } = ' + literal(rows['Materials']) + '\n\n' + 'local Surfaces: { [string]: { [string]: Types.SurfaceSpec } } = ' + surface_literal(rows['Surfaces']) + '\n\nreturn ' + literal(dict(rows, Materials=Raw('Materials'), Surfaces=Raw('Surfaces'))) + '\n'


def self_test(uploaded, installer):
    first = next(iter(sorted(uploaded)))
    slots = [row[1] for _, row in sorted(installer['MATERIALS'][first].items())]
    textures = {'fur': {}, 'moss': {}}
    files = {first: [{'slot': i + 1, 'name': n, 'hex': 'FFFFFF'} for i, n in enumerate(slots)]}
    files[first][0]['material'] = 'Grass'
    files[first][0]['texture'] = 'moss'
    files[first][-1]['glossy'] = True
    files[first][-1]['material'] = 'Glass'
    if len(slots) > 2:
        files[first][1]['glossy'] = False  # false is the same as absent: no row
    rows = data(uploaded, installer, files, textures)
    assert rows['Surfaces'] == {first: {slots[0]: {'material': 'Grass', 'texture': 'moss'},
                                        slots[-1]: {'material': 'Glass', 'glossy': True}}}
    source = render(rows)
    with tempfile.TemporaryDirectory() as directory:
        (Path(directory) / 'data').mkdir()
        (Path(directory) / 'types').mkdir()
        (Path(directory) / 'types/Types.luau').write_text('')  # the generated file requires ../types/Types
        target = Path(directory) / 'data/ModelAssets.luau'
        target.write_text(source)
        parsed = TableReader().read(target)
    assert parsed == rows
    assert parsed['AssetIds'] == {name: row['assetId'] for name, row in uploaded.items()}
    assert render(data(dict(reversed(list(uploaded.items()))), installer, files, textures)) == source
    for name, slot_rows in parsed['Materials'].items():
        assert slot_rows == installer['MATERIALS'][name]
    assert 'Materials = Materials' in source and 'Surfaces = Surfaces' in source
    assert data(uploaded, installer)['Surfaces'] == {}  # nothing in materials.json, nothing in the table
    invalid = dict(uploaded)
    invalid[first] = dict(uploaded[first], assetId=0)
    try: data(invalid, installer)
    except ValueError: pass
    else: raise AssertionError('zero asset id accepted')
    def refused(change, what):
        broken = {first: [dict(entry) for entry in files[first]]}
        change(broken[first])
        try: data(uploaded, installer, broken, textures)
        except ValueError: return
        raise AssertionError(what + ' accepted')
    refused(lambda e: e[0].update(material='Lava'), 'a material off the list')
    refused(lambda e: e[0].update(texture='velvet'), 'an unknown texture')
    refused(lambda e: e[0].update(glossy='yes'), 'a glossy that is not a boolean')
    refused(lambda e: e[0].update(name='NoSuchSlot'), 'a surface on a slot the installer does not list')
    refused(lambda e: e.append(dict(e[0])), 'a duplicate slot name')
    print('model assets self-test: 7 passed (round trip, IDs, order, materials, surfaces, invalid ID, invalid surfaces)')


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
        textures = TableReader().read(ROOT / TEXTURES)
        rows = data(uploaded, installer, surface_files(ROOT, sorted(uploaded)), textures)
        if args.check:
            if TableReader().read(ROOT / OUTPUT) != rows:
                raise ValueError('ModelAssets data is stale; run python3 -I tools/model_assets.py --write')
        else:
            (ROOT / OUTPUT).write_text(render(rows))
        count = sum(len(slots) for slots in rows['Materials'].values())
        surfaced = sum(len(slots) for slots in rows['Surfaces'].values())
        print(f'model assets: {len(rows["AssetIds"])} models, {len(rows["PropNames"])} props, '
              f'{count} material slots, {surfaced} surface slots; {"checked" if args.check else "wrote"} {OUTPUT} '
              f'({time.perf_counter() - started:.3f}s)')
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print('model assets: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
