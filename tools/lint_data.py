#!/usr/bin/env python3
"""Read Luau literal data without executing it; validate cross-table references."""
from __future__ import annotations

import argparse
import ast
import math
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LEX = re.compile(r'''--\[(=*)\[.*?\]\1\]|--[^\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?|[A-Za-z_]\w*|\S''', re.S)


def tokens(source: str) -> list[str]:
    return [m.group() for m in LEX.finditer(source) if not m.group().startswith('--')]


def uncomment(source: str) -> str:
    return LEX.sub(lambda m: re.sub(r'[^\n]', ' ', m.group())
                   if m.group().startswith('--') else m.group(), source)


class ParseError(ValueError):
    pass


class LiteralParser:
    """Small, intentionally non-executing table/expression parser, not a Luau VM."""
    def __init__(self, source, env, require):
        self.items, self.i, self.env, self.require = tokens(source), 0, env, require

    def peek(self):
        return self.items[self.i] if self.i < len(self.items) else ''

    def take(self, expected=None):
        value = self.peek()
        if not value or (expected is not None and value != expected):
            raise ParseError(f'expected {expected!r}, found {value!r}')
        self.i += 1
        return value

    def expression(self, minimum=0):
        token = self.take()
        if token == '{':
            value, index = {}, 1
            while self.peek() != '}':
                if self.peek() == '[':
                    self.take('['); key = self.expression(); self.take(']'); self.take('=')
                elif self.i + 1 < len(self.items) and self.items[self.i + 1] == '=':
                    key = self.take(); self.take('=')
                else:
                    key, index = index, index + 1
                if key in value:
                    raise ParseError(f'duplicate table key {key!r}')
                value[key] = self.expression()
                if self.peek() not in (',', ';', '}'):
                    raise ParseError(f'unsupported expression before {self.peek()!r}')
                if self.peek() != '}':
                    self.take()
            self.take('}')
        elif token == '(':
            value = self.expression(); self.take(')')
        elif token == '-':
            value = -self.expression(30)
        elif token[0] in ('"', "'"):
            value = ast.literal_eval(token)
        elif token[0].isdigit():
            value = float(token) if any(c in token for c in '.eE') else int(token)
        elif token in ('true', 'false', 'nil'):
            value = {'true': True, 'false': False, 'nil': None}[token]
        elif token == 'Vector3':
            self.take('.'); self.take('new'); self.take('(')
            components = [self.expression()]
            while self.peek() == ',':
                self.take(','); components.append(self.expression())
            self.take(')')
            if len(components) != 3:
                raise ParseError('Vector3.new needs three components')
            value = tuple(components)  # Retain the literal; no Roblox constructor runs.
        elif token == 'require':
            self.take('(')
            path = self.take('script')
            while self.peek() == '.':
                self.take('.'); path += '.' + self.take()
            self.take(')')
            value = self.require(path)
        elif token in self.env:
            value = self.env[token]
        else:
            raise ParseError(f'unsupported value {token!r}')
        while self.peek() in ('.', '['):
            if self.take() == '.':
                key = self.take()
            else:
                key = self.expression(); self.take(']')
            value = value[key]
        precedence = {'+': 10, '-': 10, '*': 20, '/': 20, '%': 20}
        while self.peek() in precedence and precedence[self.peek()] >= minimum:
            op = self.take()
            right = self.expression(precedence[op] + 1)
            if op == '+': value += right
            elif op == '-': value -= right
            elif op == '*': value *= right
            elif op == '/': value /= right
            else: value %= right
        if self.peek() == ':':
            self.take(':'); self.take(':')
            if self.peek() == '{':
                depth = 0
                while True:
                    part = self.take()
                    depth += (part == '{') - (part == '}')
                    if depth == 0:
                        break
            else:
                self.take()  # A named type annotation.
        return value


class TableReader:
    """Resolve sibling requires, literals, aliases and the repo's ById loops."""
    def __init__(self):
        self.cache = {}

    def read(self, path: Path):
        path = path.resolve()
        if path in self.cache:
            return self.cache[path]
        source = uncomment(path.read_text())
        env = {}

        def require(reference):
            target = path
            for part in reference.split('.')[1:]:
                target = target.parent if part == 'Parent' else target / part
            return self.read(target.with_suffix('.luau'))

        def parse(text):
            return LiteralParser(text, env, require).expression()

        # Type-only modules have no runtime rows to interpret.
        if path.name == 'Types.luau' and path.parent.name == 'types':
            return {}
        try:
            for match in re.finditer(r'^local\s+(\w+)(?:\s*:[^\n=]+)?\s*=', source, re.M):
                env[match[1]] = parse(source[match.end():])
            # Derived indexes are declared empty and populated by this exact idiom.
            loop = r'for\s+_,\s*(\w+)\s+in\s+ipairs\((\w+)\)\s+do\s+(\w+)\[\1\.id\]\s*=\s*\1\s+end'
            for match in re.finditer(loop, source):
                env[match[3]].update({row['id']: row for row in env[match[2]].values()})
            returned = list(re.finditer(r'^return\s+', source, re.M))
            if len(returned) != 1:
                raise ParseError('expected one top-level return')
            result = parse(source[returned[0].end():])
            self.cache[path] = result
            return result
        except (ValueError, KeyError, TypeError, IndexError) as exc:
            raise ParseError(f'{path.name}: {exc}') from exc


def load_table(path: Path):
    """Public parser entry point reused by balance.py. Arrays are 1-based dicts."""
    return TableReader().read(path)


def walk(value, path=''):
    if isinstance(value, dict):
        for key, child in value.items():
            location = f'{path}.{key}' if path else str(key)
            yield location, key, child, value
            yield from walk(child, location)


def lint(root: Path = ROOT) -> list[str]:
    data = root / 'src/shared/data'
    reader = TableReader()
    tables, failures = {}, []
    for file in sorted(data.glob('*.luau')):
        try:
            tables[file.stem] = reader.read(file)
        except (OSError, ParseError) as exc:
            failures.append(f'{file.name}: parse failure: {exc}')
    try:
        strings = reader.read(root / 'src/shared/strings/en.luau')
    except (OSError, ParseError) as exc:
        return failures + [f'en.luau: parse failure: {exc}']
    required = {'Species', 'Worlds', 'Spawns', 'KeyMaterials', 'Modules', 'Quests',
                'Tutorial', 'Layouts', 'Sizes', 'Spins', 'Icons', 'CatchVariants', 'Growth', 'Tiers'}
    for name in sorted(required - tables.keys()):
        failures.append(f'{name}.luau: required table unavailable')
    if not required <= tables.keys():
        return failures

    def reference(where, value, allowed, kind):
        if value not in allowed:
            failures.append(f'{where}: unknown {kind} {value!r}')

    species = {row['id']: row for row in tables['Species']['List'].values()}
    worlds = {row['id']: row for row in tables['Worlds'].values()}
    types = uncomment((root / 'src/shared/types/Types.luau').read_text())
    union = re.search(r'export\s+type\s+Biome\s*=\s*((?:"[^"]+"\s*\|?\s*)+)', types)
    if union is None:
        failures.append('Types.luau: Biome union unavailable')
    biomes = set(re.findall(r'"([^"]+)"', union[1])) if union else set()
    for biome, conditions in tables['Spawns']['Biomes'].items():
        reference(f'Spawns.Biomes.{biome}', biome, biomes, 'biome')
        for condition, ids in conditions.items():
            for index, value in ids.items():
                reference(f'Spawns.{biome}.{condition}.{index}', value, species, 'species')
    for name in ('Modules', 'Quests', 'Tutorial', 'Layouts'):
        for path, key, value, row in walk(tables[name]):
            if key in ('keyMaterial', 'material', 'materialId') or (
                key == 'waypointTarget' and row.get('waypoint') == 'node'
            ) or (key == 'id' and row.get('kind') in ('material', 'keyMaterial')):
                reference(f'{name}.{path}', value, tables['KeyMaterials'], 'material')
    for name, row in species.items():
        reference(f'Species.{name}.world', row['world'], worlds, 'world')
        if row.get('variant') is not None:
            reference(f'Species.{name}.variant', row['variant'], tables['CatchVariants']['Rows'], 'catch variant')
    for world, row in worlds.items():
        reference(f'Worlds.{world}.warden', row['warden'], species, 'species')
        reference(f'Worlds.{world}.weather.special.speciesId', row['weather']['special']['speciesId'], species, 'species')
        if row.get('catchVariant') is not None:
            reference(f'Worlds.{world}.catchVariant', row['catchVariant'], tables['CatchVariants']['Rows'], 'catch variant')
    for name, key in (('Sizes', 'Bands'), ('Spins', 'Segments')):
        odds = [row.get('odds') for row in tables[name][key].values()]
        if not all(type(n) in (int, float) and math.isfinite(n) and n >= 0 for n in odds):
            failures.append(f'{name}.{key}: odds must be finite non-negative numbers')
        elif not math.isclose(sum(odds), 100, rel_tol=0, abs_tol=1e-9):
            failures.append(f'{name}.{key}: odds sum to {sum(odds):g}, expected 100')
    fields = {'hint', 'labelKey', 'hintKey', 'nameKey', 'holdHintKey'}
    prefixes = ('REWARD_', 'MATERIAL_', 'SPECIES_', 'STATION_', 'JOB_', 'TIER_',
                'SIZE_', 'STAGE_', 'MENU_', 'COMPASS_')
    for name, table in tables.items():
        for path, key, value, _ in walk(table):
            if isinstance(value, str) and (key in fields or value.startswith(prefixes)):
                reference(f'{name}.{path}', value, strings, 'strings key')
    images = tables['Icons']
    pngs = {p.stem for directory in ('icons', 'particles') for p in (root / 'assets' / directory).rglob('*.png')}
    for group in ('Icons', 'Particles'):
        for key, asset_id in images[group].items():
            if key not in pngs and not (group == 'Particles' and type(asset_id) is int and asset_id == 0):
                failures.append(f'Icons.{group}.{key}: no PNG in assets/icons or assets/particles')
    for key in sorted(pngs - (images['Icons'].keys() | images['Particles'].keys())):
        failures.append(f'assets/{key}.png: no Icons or Particles key')
    previous = -math.inf
    for row in tables['Growth']['Stages'].values():
        value = row.get('workedSeconds')
        if type(value) not in (int, float) or not math.isfinite(value) or value <= previous:
            failures.append(f'Growth.{row.get("id")}: workedSeconds must be numeric and strictly ascending')
        if type(value) in (int, float):
            previous = value
    for name, row in tables['Tiers']['Tiers'].items():
        if type(row.get('aura')) not in (int, float) or not math.isfinite(row['aura']):
            failures.append(f'Tiers.{name}.aura: expected a finite number')
    return failures


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT, help='repository root (defaults to this checkout)')
    args = parser.parse_args()
    try:
        failures = lint(args.root)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        failures = [f'data lint: cannot validate tables: {exc}']
    for failure in failures:
        print(failure)
    print(f'data lint: {len(failures)} failure(s)' if failures else 'data lint: clean')
    return int(bool(failures))


if __name__ == '__main__':
    sys.exit(main())
