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


# Explicit shape exception: legacy Radar.Mk2 is skipped by numeric-row consumers.
NUMERIC_STRING_KEYS = {'Radar': {'Mk2'}, 'Layouts': set(), 'Worlds': set()}
# CompanionSlot4 is read live by Companions, rather than granted at purchase.
LIVE_PASSES = {'CompanionSlot4'}
# Exact existing findings only; new findings must fail. Empty after baseline inspection.
SHAPE_WARNINGS = set()


def lint_shapes(tables, strings, types):
    failures = []
    def check(ok, message):
        if not ok:
            failures.append(message)
    def finite(value):
        return type(value) in (int, float) and math.isfinite(value)
    def dense(value):
        return (isinstance(value, dict) and set(value) == set(range(1, len(value) + 1))
                and all(type(k) is int and v is not None for k, v in value.items()))
    def unique(rows, key, where):
        ids = [row.get(key) for row in rows.values()]
        check(None not in ids and len(ids) == len(set(ids)), f'{where}: {key} values must be present and unique')
    species = tables['Species']['ById']
    worlds = tables['Worlds']
    spawns = {v for _, _, v, _ in walk(tables['Spawns']['Biomes']) if isinstance(v, str)}
    for name, allowed in NUMERIC_STRING_KEYS.items():
        for key in tables[name]:
            check(type(key) is int or key in allowed, f'{name}.{key}: unexpected non-numeric row key')
    # Explicit owners prevent a new Order family silently validating against unrelated ids.
    owners = {'CatchVariants': 'Rows', 'Jobs': 'Jobs', 'Lures': 'Lures',
              'Overlays': 'Overlays', 'Tiers': 'Tiers', 'Settings': 'Order', 'Weekly': 'Rotation'}
    for name, table in sorted(tables.items()):
        for path, key, values, parent in walk(table):
            if key not in ('Order', 'Rotation'):
                continue
            check(dense(values), f'{name}.{path}: list must be dense without nil entries')
            check(name in owners, f'{name}.{path}: no declared row owner')
            if not isinstance(values, dict) or name not in owners:
                continue
            if name == 'Weekly':
                for i, row in values.items():
                    check(isinstance(row, dict) and row.get('species') in species,
                          f'Weekly.Rotation.{i}: unknown species')
            elif name == 'Settings':
                unique(values, 'key', 'Settings.Order')
            else:
                for i, value in values.items():
                    check(value in parent[owners[name]], f'{name}.{path}.{i}: unknown row {value!r}')
    match = re.search(r'export\s+type\s+Traversal\s*=\s*((?:"[^"]+"\s*\|?\s*)+)', types)
    traversals = set(re.findall(r'"([^"]+)"', match[1])) if match else set()
    check(bool(match), 'Types.Traversal: union unavailable')
    for sid, row in species.items():
        ride = row.get('ride')
        check(ride is None or (ride in traversals and ride in tables['Mounts']['Traversals']),
              f'Species.{sid}.ride: unknown traversal {ride!r}')
    for sid in tables['Mounts']['SeatStuds']:
        check(sid in species, f'Mounts.SeatStuds.{sid}: unknown species')
    for i, row in tables['HomeBuild']['Items'].items():
        where = f'HomeBuild.Items.{i}'
        if row['kind'] == 'habitat':
            world = worlds.get(row.get('worldId'), {})
            check(world.get('built') is True, f'{where}: habitat worldId must name a built world')
            check(finite(row.get('capacity')) and row['capacity'] > 0, f'{where}: capacity must be positive')
        for key in ('cellsX', 'cellsZ'):
            check(finite(row.get(key)) and 1 <= row[key] <= tables['Home']['PlotCells'], f'{where}.{key}: outside plot')
        check(row['kind'] in tables['HomeBuild']['Caps'], f'{where}: missing kind cap')
    for collection in ('Rotation', 'Overrides'):
        for i, row in tables['Weekly'][collection].items():
            check(row['species'] in species, f'Weekly.{collection}.{i}: unknown species')
            check(not row['limited'] or row['species'] not in spawns, f'Weekly.{collection}.{i}: limited species in Spawns')
    def rewards(rows, where, kinds):
        for i, row in rows.items():
            kind = row.get('kind')
            check(kind in kinds, f'{where}.{i}: unknown reward kind {kind!r}')
            check(finite(row.get('amount')) and row['amount'] > 0, f'{where}.{i}: reward amount must be positive')
            ids = {'alien': species, 'lure': tables['Lures']['Lures'], 'powerUp': tables['PowerUps']}
            if kind in ids:
                check(row.get('id') in ids[kind], f'{where}.{i}: unknown {kind} id {row.get("id")!r}')
            elif row.get('id') is not None:
                check(False, f'{where}.{i}: {kind} reward must not have an id')
    windows = []
    event_ids = set()
    for row in tables['Seasons']['List'].values():
        where = 'Seasons.' + row['id']
        valid = finite(row.get('startsAt')) and finite(row.get('endsAt')) and row['startsAt'] < row['endsAt']
        check(valid, f'{where}: startsAt must precede endsAt')
        if valid:
            windows.append((row['startsAt'], row['endsAt'], row['id']))
        event_ids.update(row['species'].values())
        for sid in row['species'].values():
            check(sid in species, f'{where}: unknown event species {sid!r}')
            check(sid not in spawns, f'{where}: event species {sid!r} in Spawns')
        for sid in row['returns'].values():
            check(sid in species, f'{where}: unknown returning species {sid!r}')
        overlay = row.get('overlay')
        check(overlay is None or overlay in tables['Overlays']['Overlays'], f'{where}: unknown overlay {overlay!r}')
        unique(row['track'], 'id', where + '.track')
        for quest in row['track'].values():
            rewards(quest['rewards'], where + '.' + quest['id'], {'alien', 'lure', 'powerUp', 'scrap', 'spin'})
            event_ids.update(r.get('id') for r in quest['rewards'].values() if r['kind'] == 'alien')
    windows.sort()
    for i, (start, end, sid) in enumerate(windows):
        for other_start, other_end, other in windows[:i]:
            check(start >= other_end, f'Seasons.{sid}: window overlaps {other}')
    shop = tables['Shop']
    unique(shop['Items'], 'id', 'Shop.Items')
    items = {r['id']: r for r in shop['Items'].values()}
    for section in shop['Launch'].values():
        for sid in section['items'].values():
            check(sid in items, f'Shop.Launch: unknown item {sid!r}')
            check(sid in shop['Grants'] or (sid in LIVE_PASSES and items.get(sid, {}).get('kind') == 'pass'),
                  f'Shop.Launch.{sid}: missing grant or live-pass allowance')
    never = set(shop['NeverSold'].values())
    for sid, grants in shop['Grants'].items():
        for i, grant in grants.items():
            kind, gid = grant['kind'], grant.get('id')
            alien = species.get(gid, {})
            prohibited = (gid in never or kind.lower() in {s.lower() for s in never}
                          or ('LegendaryAliens' in never and kind == 'alien' and
                              (grant.get('tier') == 'Legendary' or alien.get('tier') == 'Legendary'))
                          or ('EventAliens' in never and kind == 'alien' and gid in event_ids)
                          or ('Mounts' in never and kind == 'alien' and alien.get('ride') is not None))
            check(not prohibited, f'Shop.Grants.{sid}.{i}: violates NeverSold')
    for row in tables['Settings']['Order'].values():
        where = 'Settings.' + row['key']
        levels = row.get('levels') or {}
        if row.get('levelKeys') is not None:
            keys = row['levelKeys']
            check(dense(keys) and dense(levels) and len(keys) == len(levels), f'{where}: levelKeys must match levels')
            for key in keys.values():
                check(key in strings, f'{where}: missing level string {key!r}')
        maximum = len(levels) - 1 if row['kind'] == 'level' else 1
        check(type(row['default']) is int and 0 <= row['default'] <= maximum, f'{where}: default out of range')
    for name, row in tables['Codes']['Codes'].items():
        rewards(row['rewards'], 'Codes.' + name, {'scrap', 'spin', 'lure', 'powerUp'})
    return sorted(set(failures))


def lint_music(tables):
    """data/Music: well-formed rows, and every id the director looks up exists (rows, worlds, tiers, Sounds paths)."""
    music, failures = tables.get('Music'), []
    if music is None:
        return ['Music.luau: table unavailable']
    rows, layers = music['Rows'], {'bed', 'layer'}
    for name, row in rows.items():
        where = f'Music.Rows.{name}'
        if type(row.get('assetId')) is not int or row['assetId'] < 0:
            failures.append(f'{where}.assetId: expected a non-negative integer (0 = not chosen yet)')
        volume = row.get('volume')
        if type(volume) not in (int, float) or not 0 < volume <= 1:
            failures.append(f'{where}.volume: expected a number in (0, 1]')
        for key in ('fadeIn', 'fadeOut'):
            if type(row.get(key)) not in (int, float) or row[key] < 0:
                failures.append(f'{where}.{key}: expected non-negative seconds')
        if type(row.get('loop')) is not bool:
            failures.append(f'{where}.loop: expected a boolean')
        if row.get('layer') not in layers:
            failures.append(f'{where}.layer: expected "bed" or "layer"')
        if type(row.get('priority')) is not int:
            failures.append(f'{where}.priority: expected an integer')
    beds = {name for name, row in rows.items() if row.get('layer') == 'bed'}
    worlds = {row['id'] for row in tables['Worlds'].values() if isinstance(row, dict) and 'id' in row}
    for world, pair in music['Worlds'].items():
        if world not in worlds:
            failures.append(f'Music.Worlds.{world}: unknown world')
        for part in ('day', 'night'):
            if pair.get(part) not in beds:
                failures.append(f'Music.Worlds.{world}.{part}: unknown bed {pair.get(part)!r}')
    for kind, name in music['Events'].items():
        if name not in beds:
            failures.append(f'Music.Events.{kind}: unknown bed {name!r}')
    for kind in ('base', 'intense'):
        if music['Capture'][kind] not in beds:
            failures.append(f'Music.Capture.{kind}: unknown bed {music["Capture"][kind]!r}')
    if music['Capture']['intenseFromTier'] not in tables['Tiers']['Order'].values():
        failures.append('Music.Capture.intenseFromTier: unknown tier')
    if music['Resting'] not in beds:
        failures.append('Music.Resting: unknown bed')
    if rows.get(music['MenuLayer'], {}).get('layer') != 'layer':
        failures.append('Music.MenuLayer: expected a row with layer "layer"')
    for season in tables['Seasons']['List'].values():
        if season['id'] in rows and season['id'] not in beds:
            failures.append(f'Music.Rows.{season["id"]}: a season row must be a bed')
    ducking = music['Ducking']
    if not 0 <= ducking['Gain'] <= 1:
        failures.append('Music.Ducking.Gain: expected a number in [0, 1]')
    for key in ('AttackSeconds', 'RestoreSeconds', 'DefaultStingerSeconds'):
        if type(ducking[key]) not in (int, float) or ducking[key] < 0:
            failures.append(f'Music.Ducking.{key}: expected non-negative seconds')
    sounds = tables['Sounds']
    for key, seconds in ducking['StingerSeconds'].items():
        node = sounds
        for part in key.split('.'):
            node = node.get(part) if isinstance(node, dict) else None
        if not isinstance(node, str):
            failures.append(f'Music.Ducking.StingerSeconds.{key}: no such path in Sounds')
        if type(seconds) not in (int, float) or seconds <= 0:
            failures.append(f'Music.Ducking.StingerSeconds.{key}: expected positive seconds')
    for tier in tables['Tiers']['Order'].values():
        if 'Reveal.' + tier not in ducking['StingerSeconds']:
            failures.append(f'Music.Ducking.StingerSeconds: no length for Reveal.{tier}')
    return failures


def lint_cinematics(tables):
    """data/Cinematics: well-formed shots, every rule resolvable in its world's layout, the arrival moments, seen keys and Legendary budget."""
    data, failures = tables.get('Cinematics'), []
    if data is None:
        return ['Cinematics.luau: table unavailable']
    kinds = {'orbitCamp': ('radius', 'height', 'angle'), 'overBiome': ('biome', 'height'),
             'behindCharacter': ('back', 'height'), 'towardTarget': ('distance', 'height'), 'current': ()}
    easings = {style + direction for style in ('Quad', 'Sine') for direction in ('In', 'Out', 'InOut')}
    numeric = lambda value: type(value) in (int, float) and math.isfinite(value)
    worlds = {row['id']: row for row in tables['Worlds'].values() if isinstance(row, dict) and 'id' in row}
    anchors = {}

    def world_of(moment_id):
        for world_id in worlds:
            if moment_id == f'{data["ArrivalPrefix"]}{world_id}':
                return world_id
        return None

    for moment_id, moment in data['Moments'].items():
        where = f'Cinematics.Moments.{moment_id}'
        for flag in ('letterbox', 'skippable', 'skipOnReducedMotion'):
            if type(moment.get(flag)) is not bool:
                failures.append(f'{where}.{flag}: expected a boolean')
        stinger = moment.get('stinger')
        if stinger is not None:
            node = tables['Sounds']
            for part in str(stinger).split('.'):
                node = node.get(part) if isinstance(node, dict) else None
            if not isinstance(node, str):
                failures.append(f'{where}.stinger: no such path in Sounds')
        shots = moment.get('shots') or {}
        if not shots or set(shots) != set(range(1, len(shots) + 1)):
            failures.append(f'{where}.shots: expected a dense, non-empty list')
            continue
        layout = tables['Layouts'].get(world_of(moment_id))
        total = 0
        for index, shot in shots.items():
            at = f'{where}.shots.{index}'
            seconds = shot.get('seconds')
            if not numeric(seconds) or seconds < 0 or (index > 1 and seconds <= 0):
                failures.append(f'{at}.seconds: expected seconds (0 only for the opening frame)')
            else:
                total += seconds
            if shot.get('easing') not in easings:
                failures.append(f'{at}.easing: expected Quad or Sine with In, Out or InOut, found {shot.get("easing")!r}')
            if not numeric(shot.get('blur')) or not 0 <= shot['blur'] <= 1:
                failures.append(f'{at}.blur: expected a number in [0, 1]')
            if shot.get('fov') is not None and (not numeric(shot['fov']) or not 0 < shot['fov'] <= 120):
                failures.append(f'{at}.fov: expected degrees in (0, 120]')
            anchor = shot.get('anchor')
            if anchor is not None:
                if not isinstance(anchor, str) or not anchor.startswith(moment_id):
                    failures.append(f'{at}.anchor: expected a name starting with {moment_id}')
                elif anchor in anchors:
                    failures.append(f'{at}.anchor: {anchor!r} is also used by {anchors[anchor]}')
                else:
                    anchors[anchor] = at
            rule = shot.get('fallback')
            if not isinstance(rule, dict) or rule.get('kind') not in kinds:
                failures.append(f'{at}.fallback.kind: unknown rule {rule.get("kind") if isinstance(rule, dict) else rule!r}')
                continue
            for field in kinds[rule['kind']]:
                value = rule.get(field)
                if (field == 'biome' and not isinstance(value, str)) or (field != 'biome' and not numeric(value)):
                    failures.append(f'{at}.fallback.{field}: required by {rule["kind"]}')
            if rule['kind'] == 'overBiome':
                regions = layout['Regions'] if layout is not None else {}
                if rule.get('biome') not in regions:
                    failures.append(f'{at}.fallback.biome: {rule.get("biome")!r} is not a region of this moment\'s world layout')
        arrival = world_of(moment_id)
        if arrival is not None:
            low, high = data['ArrivalSeconds']['min'], data['ArrivalSeconds']['max']
            if arrival == 0 and not 0 < total < low:
                failures.append(f'{where}: the home arrival must be shorter than {low} seconds, found {total:g}')
            elif arrival != 0 and not low <= total <= high:
                failures.append(f'{where}: an arrival must run {low} to {high} seconds, found {total:g}')
    for world_id, row in worlds.items():
        if row.get('built'):
            moment_id = f'{data["ArrivalPrefix"]}{world_id}'
            if moment_id not in data['Moments']:
                failures.append(f'Cinematics.Moments: built world {world_id} has no {moment_id} moment')
            if not data['SeenKeys'].get(moment_id):
                failures.append(f'Cinematics.SeenKeys: built world {world_id} has no {moment_id} key')
    for key, flag in data['SeenKeys'].items():
        if flag is not True or key not in data['Moments']:
            failures.append(f'Cinematics.SeenKeys.{key}: expected true and a moment of that name')
    legendary = data['Moments'].get('Legendary')
    if legendary is None:
        failures.append('Cinematics.Moments.Legendary: missing')
    else:
        total = sum(shot['seconds'] for shot in legendary['shots'].values())
        if total + tables['Config']['LegendaryRumbleSeconds'] >= data['LegendaryBudgetSeconds']:
            failures.append(f'Cinematics.Moments.Legendary: push-in {total:g} s plus the rumble must stay under {data["LegendaryBudgetSeconds"]:g} s')
        if any(shot['blur'] != 0 for shot in legendary['shots'].values()):
            failures.append('Cinematics.Moments.Legendary: the push-in has no blur')
    bars = data['Letterbox']
    if not numeric(bars.get('barHeight')) or not 0 < bars['barHeight'] < 0.5:
        failures.append('Cinematics.Letterbox.barHeight: expected a screen fraction in (0, 0.5)')
    for path, value in (('Letterbox.fadeSeconds', bars.get('fadeSeconds')), ('SkipAfterSeconds', data['SkipAfterSeconds']),
                        ('ReducedMotionHoldSeconds', data['ReducedMotionHoldSeconds'])):
        if not numeric(value) or value < 0:
            failures.append(f'Cinematics.{path}: expected non-negative seconds')
    focus = data['DepthOfField']
    for key in ('FocusDistance', 'InFocusRadius', 'NearFactor', 'FarFactor'):
        if not numeric(focus.get(key)) or focus[key] < 0:
            failures.append(f'Cinematics.DepthOfField.{key}: expected a non-negative number')
    if not data['RigParents'] or not isinstance(data['RigFolder'], str):
        failures.append('Cinematics.RigParents/RigFolder: expected a folder name and at least one parent')
    return failures


def model_asset_warnings(tables, root):
    """Advisory coverage: missing meshes retain the existing runtime placeholders."""
    requested = {}
    def need(name, where):
        if isinstance(name, str) and name:
            requested.setdefault(name, set()).add(where)
    def family(value, where):
        for path, _, name, _ in walk(value):
            need(name, where + '.' + path)
    for row in tables['Species']['List'].values():
        need(row.get('model') or row['id'], 'Species.' + row['id'])
    for world, layout in tables['Layouts'].items():
        family(layout.get('Props') or {}, f'Layouts.{world}.Props')
        for index, row in (layout.get('Landmarks') or {}).items():
            need(row.get('name'), f'Layouts.{world}.Landmarks.{index}')
    family(tables['Camp']['Props'], 'Camp.Props')
    need(tables['Config']['HeaterPropName'], 'Config.HeaterPropName')
    for row in tables['HomeBuild']['Items'].values():
        need(row.get('prop'), 'HomeBuild.' + row['id'])
    # Today's variable lookups are covered above; include direct literal calls too.
    for path in sorted((root / 'src').rglob('*.luau')):
        source = uncomment(path.read_text())
        for match in re.finditer(r'\bProps\.(?:Place|Find)\s*\(\s*["\']([^"\']+)["\']', source):
            need(match[1], str(path.relative_to(root)))
    assets = (tables.get('ModelAssets') or {}).get('AssetIds', {})
    return [f'ModelAssets.{name}: no positive asset id (requested by {", ".join(sorted(locations))})'
            for name, locations in sorted(requested.items())
            if type(assets.get(name)) is not int or assets[name] <= 0]


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
                'Tutorial', 'Layouts', 'Sizes', 'Spins', 'Icons', 'CatchVariants', 'Growth', 'Tiers',
                'Radar', 'Mounts', 'HomeBuild', 'Home', 'Weekly', 'Seasons', 'Shop', 'Settings', 'Codes', 'Lures', 'PowerUps'}
    for name in sorted(required - tables.keys()):
        failures.append(f'{name}.luau: required table unavailable')
    if not required <= tables.keys():
        return failures

    def reference(where, value, allowed, kind):
        if value not in allowed:
            failures.append(f'{where}: unknown {kind} {value!r}')

    species = {row['id']: row for row in tables['Species']['List'].values()}
    worlds = {row['id']: row for row in tables['Worlds'].values() if isinstance(row, dict) and 'id' in row}
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
        # A world that is only designed (built = false) names species that do not exist yet; its
        # references are checked once it is built. The variant must exist either way.
        # The home planet (world 0) has no warden and no special species: an empty id is skipped.
        if row.get('built', True):
            if row['warden'] != '':
                reference(f'Worlds.{world}.warden', row['warden'], species, 'species')
            if row['weather']['special']['speciesId'] != '':
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
    for finding in model_asset_warnings(tables, root):
        print('warning: ' + finding)
    failures.extend(lint_music(tables))
    failures.extend(lint_cinematics(tables))
    for finding in lint_shapes(tables, strings, types):
        if finding in SHAPE_WARNINGS:
            print('warning: ' + finding)
        else:
            failures.append(finding)
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
