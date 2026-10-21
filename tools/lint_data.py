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
# The Roblox Material names a materials.json `material` may use (the Surface pass, docs/vault/06-art-pipelines/Surface-Pass.md).
# Shared/ModelInstall.SurfaceMaterials keeps the same list; tools/tests/test_surfaces.py checks the two match.
SURFACE_MATERIALS = ('Plastic', 'SmoothPlastic', 'Neon', 'Metal', 'Foil', 'Wood', 'WoodPlanks', 'Fabric', 'Leather', 'Rubber',
                     'Grass', 'Slate', 'Rock', 'Pebble', 'Granite', 'Marble', 'Sand', 'Sandstone', 'Snow', 'Ice', 'Glass', 'Mud')
SURFACE_KEYS = ('material', 'texture', 'glossy')
# The values a data/Props row's `collision` may take. Shared/ModelInstall.PropCollisions keeps the same list;
# tools/tests/test_lint_props.py checks the two match.
PROP_COLLISIONS = ('Box', 'Hull', 'Precise', 'None')
TEXTURE_FIELDS = ('colorMap', 'normalMap', 'roughnessMap')
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
    # The shelf (Shop screen): categories, ribbons, seals and cards name each other and the items they show.
    hexes = lambda value: isinstance(value, str) and re.fullmatch(r'[0-9A-Fa-f]{6}', value) is not None
    categories = shop['Categories']
    unique(categories, 'id', 'Shop.Categories')
    theme = (ROOT / 'src/shared/Theme.luau').read_text()
    rarity = re.search(r'Theme\.Rarity\s*=\s*\{(.*?)\n\}', theme, re.S)
    rarity_hexes = {h.upper() for h in re.findall(r'fromHex\("([0-9A-Fa-f]{6})"\)', rarity[1])} if rarity else set()
    check(bool(rarity_hexes), 'Shop.Categories: Theme.Rarity colours unavailable')
    scrap_ids = set()
    for category in categories.values():
        where = 'Shop.Categories.' + str(category.get('id'))
        check(hexes(category.get('color')), f'{where}: colour must be a six-digit hex string')
        check(str(category.get('color')).upper() not in rarity_hexes, f'{where}: category colour is a rarity colour')
        scrap_ids.update((category.get('scrap') or {}).values())
    check(len({str(c.get('color')).upper() for c in categories.values()}) == len(categories), 'Shop.Categories: colours must differ')
    launch_sections = {s['section'] for s in shop['Launch'].values()}
    check(launch_sections <= {c['id'] for c in categories.values()}, 'Shop.Launch: a section has no category')
    gear_ids = {k for k, v in tables['Gear'].items() if isinstance(v, dict)} | {'Radar' + str(k) for k in tables['Radar'] if type(k) is int and k > 0}
    for sid in scrap_ids:
        check(sid in tables['Lures']['Lures'] or sid in gear_ids, f'Shop.Categories: unknown Scrap item {sid!r}')
    shelf_ids = {sid for s in shop['Launch'].values() for sid in s['items'].values()} | scrap_ids
    for key, table in (('Ribbons', shop['Ribbons']), ('Seals', shop['Seals'])):
        for rid, row in table.items():
            check(hexes(row.get('color')), f'Shop.{key}.{rid}: colour must be a six-digit hex string')
    icon_keys = set(tables['Icons']['Icons']) | set(tables['Icons']['Aliases'])
    for cid, card in shop['Cards'].items():
        where = 'Shop.Cards.' + str(cid)
        check(cid in shelf_ids, f'{where}: not on the shelf')
        check(card.get('ribbon') is None or card['ribbon'] in shop['Ribbons'], f'{where}: unknown ribbon {card.get("ribbon")!r}')
        check(card.get('seal') is None or card['seal'] in shop['Seals'], f'{where}: unknown seal {card.get("seal")!r}')
        check(card.get('icon') is None or card['icon'] in icon_keys, f'{where}: unknown icon {card.get("icon")!r}')
        check(items.get(cid, {}).get('oddsOnWheel') is not True or card.get('note') == 'SeeOdds', f'{where}: a paid spin card must link its odds')
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
        start, end = row.get('startsAt'), row['expiresAt']
        check(finite(end) and end >= 0, f'Codes.{name}: expiresAt must be 0 (no deadline) or a unix second')
        check(start is None or (finite(start) and start > 0 and (end == 0 or start < end)),
              f'Codes.{name}: startsAt must be a unix second before expiresAt')
    for day, row in tables['Gifts'].items():
        also = row.get('also')
        if also is not None:
            rewards(also, f'Gifts.{day}.also', {'spin', 'lure', 'powerUp'})
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


def lint_surfaces(tables):
    """data/Textures rows and data/ModelAssets.Surfaces rows (the Surface pass): shapes, names and references."""
    failures = []
    textures = tables.get('Textures')
    if not isinstance(textures, dict):
        return ['Textures.luau: required table unavailable']
    def finite(value):
        return type(value) in (int, float) and math.isfinite(value)
    for key, row in sorted(textures.items(), key=lambda kv: str(kv[0])):
        where = f'Textures.{key}'
        if not isinstance(key, str) or not re.fullmatch(r'[a-z][a-z0-9]*', key):
            failures.append(f'{where}: key must be lower-case letters and digits')
        if not isinstance(row, dict) or set(row) != set(TEXTURE_FIELDS) | {'tiling'}:
            failures.append(f'{where}: expected colorMap, normalMap, roughnessMap and tiling')
            continue
        for field in TEXTURE_FIELDS:
            if type(row[field]) is not int or row[field] < 0:
                failures.append(f'{where}.{field}: expected an Image id (a non-negative integer, 0 = not uploaded)')
        tiling = row['tiling']
        if not (isinstance(tiling, dict) and set(tiling) == {1, 2} and all(finite(v) and v > 0 for v in tiling.values())):
            failures.append(where + '.tiling: expected { u, v } with two positive numbers')
    assets = tables.get('ModelAssets') or {}
    ids, materials = assets.get('AssetIds', {}), assets.get('Materials', {})
    for model, slots in sorted((assets.get('Surfaces') or {}).items()):
        if model not in ids:
            failures.append(f'ModelAssets.Surfaces.{model}: no such model in AssetIds')
            continue
        names = {row[1] for row in (materials.get(model) or {}).values()}
        for slot, spec in sorted(slots.items()):
            where = f'ModelAssets.Surfaces.{model}.{slot}'
            if slot not in names:
                failures.append(f'{where}: no such slot in Materials.{model}')
            if not isinstance(spec, dict) or not spec or set(spec) - set(SURFACE_KEYS):
                failures.append(f'{where}: expected a row with some of {", ".join(SURFACE_KEYS)}')
                continue
            if 'material' in spec and spec['material'] not in SURFACE_MATERIALS:
                failures.append(f'{where}.material: {spec["material"]!r} is not on the SurfaceMaterials list')
            if 'texture' in spec and spec['texture'] not in textures:
                failures.append(f'{where}.texture: unknown texture {spec["texture"]!r}')
            if 'glossy' in spec and spec['glossy'] is not True:
                failures.append(f'{where}.glossy: only true is written (leave the field out for a plain slot)')
    return failures


def lint_props(tables):
    """data/Props: one row per imported prop (data/ModelAssets.PropNames), and each row's collision is one of PROP_COLLISIONS."""
    rows = (tables.get('Props') or {}).get('Rows')
    names = (tables.get('ModelAssets') or {}).get('PropNames')
    if not isinstance(rows, dict) or not isinstance(names, dict):
        return ['Props.luau: Rows (and ModelAssets.PropNames) unavailable']
    failures = []
    for name in sorted(names, key=str):
        if name not in rows:
            failures.append(f'Props.Rows.{name}: no row for an imported prop (add one with a collision of {", ".join(PROP_COLLISIONS)})')
    for name, row in sorted(rows.items(), key=lambda kv: str(kv[0])):
        where = f'Props.Rows.{name}'
        if name not in names:
            failures.append(f'{where}: not in ModelAssets.PropNames')
        if not isinstance(row, dict) or set(row) != {'collision'}:
            failures.append(f'{where}: expected a row with just collision')
        elif row['collision'] not in PROP_COLLISIONS:
            failures.append(f'{where}.collision: {row["collision"]!r} is not one of {", ".join(PROP_COLLISIONS)}')
    return failures


EFFECT_KINDS = ('Emitter', 'Beam', 'Light', 'Trail', 'Orbit', 'Burst', 'Sparkle', 'RingPulse', 'Pillar', 'Aura')
EFFECT_DIRECTIONS = ('Up', 'Front', 'Back', 'Down')
MOTION_KINDS = ('Still', 'Bob', 'Hover', 'Flap', 'Spin', 'Breathe')
# The numbers each layer kind must carry (data/Effects; Types.EffectLayer lists them); lengths are in alien heights.
EFFECT_NUMBERS = {'Emitter': ('rate', 'size', 'lifetime', 'speed', 'spread'),
                  'Beam': ('width', 'flicker', 'segments'),
                  'Light': ('brightness', 'range'),
                  'Trail': ('lifetime', 'width'),
                  'Orbit': ('count', 'radius', 'period', 'rate', 'size', 'lifetime'),
                  'Burst': ('count', 'size', 'lifetime', 'speed', 'spread'),
                  'Sparkle': ('count', 'size', 'lifetime'),
                  'RingPulse': ('count', 'size', 'lifetime'),
                  'Pillar': ('reach', 'width', 'lifetime'),
                  'Aura': ('rate', 'size', 'lifetime')}
# Kinds that fire `count` at once (on `every` and/or the flourish), and kinds that flow at a rate.
EFFECT_FIRED = ('Burst', 'Sparkle', 'RingPulse')
EFFECT_FLOWING = ('Emitter', 'Orbit', 'Aura')
EFFECT_REQUIRED_REGIONS = ('Top', 'Back', 'Tail', 'Eyes', 'Feet')
EFFECT_LADDER = ('layersAllowed', 'rateScale', 'sizeScale', 'lightScale', 'burstMax')
EFFECT_FLAGS = ('trail', 'orbit', 'groundRing', 'aura', 'pillar', 'flourish', 'spawnMoment', 'dark')
EFFECT_CAPS = ('MobileRateCap', 'DesktopRateCap', 'MobileAlienParticles', 'DesktopAlienParticles', 'MobileBurstMax', 'DesktopBurstMax',
               'MaxBeams', 'MaxLights', 'MaxPillars', 'MaxActive', 'MaxActiveMobile', 'ActiveDistance', 'NearDistance', 'FarRateScale',
               'MomentDistance', 'MaxMoments', 'MaxSoundsPerSecond')
EFFECT_SHEET_LAYOUTS = ('Grid2x2', 'Grid4x4')
EFFECT_SHEET_MODES = ('Loop', 'OneShot', 'PingPong', 'Random')
# B46's ladder, what a species' own tier must show in the layers it draws (the extras the tier adds count too):
# Uncommon a second colour; Rare a soft light and a sparkle; Epic a signature Burst; Legendary and up a flourish, the ground
# (an orbit and a ring); Cosmic and Secret the sky too (a trail, an aura and a pillar).
EFFECT_TIER_MUSTS = {'Rare': ('Light', 'Sparkle'),
                     'Epic': ('Light', 'Sparkle', 'Burst'),
                     'Legendary': ('Orbit', 'RingPulse'),
                     'Cosmic': ('Orbit', 'RingPulse', 'Trail', 'Aura', 'Pillar'),
                     'Secret': ('Orbit', 'RingPulse', 'Trail', 'Aura', 'Pillar')}


def drawn_layers(row, rule, caps):
    """The species' own layers a tier draws, as EffectsMath.LayersFor takes them (kinds gate, layersAllowed, the beam, light and
    pillar caps); the extras are not included."""
    out, seen = [], {}
    limits = {'Beam': caps.get('MaxBeams', 0), 'Light': caps.get('MaxLights', 0), 'Pillar': caps.get('MaxPillars', 0)}
    allowed = rule.get('kinds', {})
    for layer in row.get('layers', {}).values():
        if len(out) >= rule.get('layersAllowed', 0):
            break
        kind = layer.get('kind') if isinstance(layer, dict) else None
        if allowed.get(kind) is not True:
            continue
        if kind in limits and seen.get(kind, 0) >= limits[kind]:
            continue
        seen[kind] = seen.get(kind, 0) + 1
        out.append(layer)
    return out


def live_particles(layers, rule):
    """EffectsMath.LiveParticles of the layers at a tier's rateScale (flowing rate x lifetime, an Orbit's per mote, plus the
    largest firing, held to the tier's burstMax)."""
    flowing, largest = 0.0, 0
    for layer in layers:
        kind = layer.get('kind')
        if kind in EFFECT_FLOWING:
            motes = layer.get('count', 1) if kind == 'Orbit' else 1
            flowing += layer.get('rate', 0) * rule.get('rateScale', 1) * layer.get('lifetime', 0) * motes
        elif kind in EFFECT_FIRED:
            largest = max(largest, min(layer.get('count', 1), rule.get('burstMax', 1)))
    return flowing + largest


def lint_effects(tables, types):
    """data/Effects: every species has a row; layers name real regions, kinds and sprites; rates stay under the caps; the tier
    ladder only climbs (B46: Common one touch ... Cosmic and Secret the sky); each species shows its own tier's rung. The tier
    gate itself is covered by tests/Effects.spec.luau."""
    effects = tables.get('Effects')
    if not isinstance(effects, dict):
        return ['Effects.luau: required table unavailable']
    failures = []
    def check(ok, message):
        if not ok:
            failures.append(message)
    def finite(value):
        return type(value) in (int, float) and math.isfinite(value)
    def positive(value):
        return finite(value) and value > 0
    def whole(value):
        return finite(value) and float(value).is_integer()
    def fraction(value):
        return finite(value) and 0 <= value <= 1
    def hexcolor(value):
        return isinstance(value, str) and re.fullmatch(r'[0-9A-Fa-f]{6}', value) is not None
    def union(name):
        found = re.search(r'export\s+type\s+' + name + r'\s*=\s*((?:"[^"]+"\s*\|?\s*)+)', types)
        return set(re.findall(r'"([^"]+)"', found[1])) if found else set()
    check(union('EffectKind') == set(EFFECT_KINDS), 'Types.EffectKind: differs from the kinds lint_data knows')
    check(union('MotionKind') == set(MOTION_KINDS), 'Types.MotionKind: differs from the motions lint_data knows')
    check(union('EmitDirection') == set(EFFECT_DIRECTIONS), 'Types.EmitDirection: differs from the directions lint_data knows')
    caps, attach, look = effects['Caps'], effects['Attach'], effects['Look']
    particles = tables['Icons']['Particles']
    for key in EFFECT_CAPS:
        check(positive(caps.get(key)), f'Effects.Caps.{key}: expected a positive number')
    for low, high in (('MobileRateCap', 'DesktopRateCap'), ('MobileAlienParticles', 'DesktopAlienParticles'),
                      ('MobileBurstMax', 'DesktopBurstMax'), ('MaxActiveMobile', 'MaxActive'), ('NearDistance', 'ActiveDistance')):
        check(positive(caps.get(low)) and positive(caps.get(high)) and caps[low] <= caps[high],
              f'Effects.Caps: {low} must not exceed {high}')
    check(fraction(caps.get('FarRateScale')), 'Effects.Caps.FarRateScale: expected 0 to 1')
    for key in ('MaxBeams', 'MaxLights', 'MaxPillars', 'MaxActive', 'MaxActiveMobile', 'MaxMoments', 'MobileBurstMax', 'DesktopBurstMax'):
        check(whole(caps.get(key)), f'Effects.Caps.{key}: expected a whole number')
    for region in EFFECT_REQUIRED_REGIONS:
        check(region in attach, f'Effects.Attach.{region}: required region missing')
    for name, point in attach.items():
        where = f'Effects.Attach.{name}'
        ok = isinstance(point, dict) and set(point) == {'x', 'y', 'z'} and all(finite(v) for v in point.values())
        check(ok, where + ': expected x, y and z fractions')
        if ok:
            check(-0.75 <= point['x'] <= 0.75 and -0.75 <= point['z'] <= 0.75 and -0.25 <= point['y'] <= 1.5,
                  where + ': outside the alien (x and z within 0.75 of the centre, y within -0.25 to 1.5 of the height)')
    check(whole(look['BeamSteps']) and look['BeamSteps'] >= 1, 'Effects.Look.BeamSteps: expected a whole number of 1 or more')
    check(0 < look['FadeIn'] < look['FadeOut'] < 1, 'Effects.Look: FadeIn must be below FadeOut, both inside 0 to 1')
    for key, value in look.items():
        check(finite(value) and value >= 0, f'Effects.Look.{key}: expected a non-negative number')
    for key in ('SoundEverySeconds', 'SoundRollOffMin', 'SoundRollOffMax', 'SoundMaxSeconds', 'FlourishEvery', 'ExternalHold',
                'FlareSeconds', 'MomentWindow', 'EyeSparkleMax', 'RingDrift'):
        check(positive(look.get(key)), f'Effects.Look.{key}: expected a positive number')
    check(positive(look.get('SoundRollOffMin')) and positive(look.get('SoundRollOffMax')) and look['SoundRollOffMin'] < look['SoundRollOffMax'],
          'Effects.Look: SoundRollOffMin must be below SoundRollOffMax')
    for key in ('SparklePeak', 'AuraTransparency', 'AuraFrom', 'PillarTransparency', 'CoreWidth', 'CoreMix', 'FlourishFirst'):
        check(fraction(look.get(key)) and 0 < look[key] < 1, f'Effects.Look.{key}: expected a fraction inside 0 to 1')
    check(fraction(look.get('PillarIn')) and fraction(look.get('PillarOut')) and look['PillarIn'] + look['PillarOut'] <= 1,
          'Effects.Look: PillarIn and PillarOut must fit inside the life together')
    check(finite(look.get('FlareBoost')) and look['FlareBoost'] >= 1, 'Effects.Look.FlareBoost: expected 1 or more')
    for key, value in effects['Motion'].items():
        check(finite(value) and value >= 0, f'Effects.Motion.{key}: expected a non-negative number')
    for key, value in effects['Reduced'].items():
        check(positive(value), f'Effects.Reduced.{key}: expected a positive number')
    dark = effects['Dark']
    check(hexcolor(dark.get('Color')) and fraction(dark.get('Mix')) and fraction(dark.get('MomentMix')) and fraction(dark.get('GlowScale')),
          'Effects.Dark: expected a hex Color, and a Mix, MomentMix and GlowScale between 0 and 1')
    for key, fallback in effects['SpriteFallback'].items():
        check(key in particles, f'Effects.SpriteFallback.{key}: not a key of Icons.Particles')
        check(fallback in particles and fallback != key, f'Effects.SpriteFallback.{key}: {fallback!r} is not another key of Icons.Particles')
    for key, sheet in effects['Sheets'].items():
        where = f'Effects.Sheets.{key}'
        check(key in particles, where + ': not a key of Icons.Particles')
        check(isinstance(sheet, dict) and sheet.get('layout') in EFFECT_SHEET_LAYOUTS and sheet.get('mode') in EFFECT_SHEET_MODES
              and positive(sheet.get('fps')), where + ': expected a layout (' + ', '.join(EFFECT_SHEET_LAYOUTS) + '), a mode and fps')
        check(key in effects['SpriteFallback'], where + ': a sheet needs a SpriteFallback (a single sprite to wear until it is uploaded)')
    ladder = list(tables['Tiers']['Order'].values())
    rules = effects['Tiers']
    check(set(rules) == set(ladder), 'Effects.Tiers: expected exactly one rule per tier in Tiers.Order')
    previous = None
    top_rate = 1
    for tier in ladder:
        rule = rules.get(tier)
        if not isinstance(rule, dict):
            continue
        where = f'Effects.Tiers.{tier}'
        check(set(rule) == set(EFFECT_LADDER) | set(EFFECT_FLAGS) | {'kinds'}, where + ': expected kinds, ' + ', '.join(EFFECT_LADDER + EFFECT_FLAGS))
        check(all(positive(rule.get(key)) for key in EFFECT_LADDER) and whole(rule.get('layersAllowed')) and whole(rule.get('burstMax')),
              where + ': layersAllowed and burstMax (whole) and the scales must be positive numbers')
        check(all(isinstance(rule.get(key), bool) for key in EFFECT_FLAGS), where + ': ' + ', '.join(EFFECT_FLAGS) + ' must be true or false')
        kinds = rule.get('kinds')
        kinds_ok = isinstance(kinds, dict) and len(kinds) > 0 and all(k in EFFECT_KINDS and v is True for k, v in kinds.items())
        check(kinds_ok, where + '.kinds: expected a set of EffectKinds (Kind = true)')
        if previous is not None:
            for key in EFFECT_LADDER:
                check(rule.get(key, 0) >= previous.get(key, 0), f'{where}.{key}: below the tier under it (the ladder must not fall)')
            for key in EFFECT_FLAGS:
                check(rule.get(key) is True or previous.get(key) is not True, f'{where}.{key}: a higher tier cannot drop what the tier under it adds')
            if kinds_ok and isinstance(previous.get('kinds'), dict):
                check(set(kinds) >= set(previous['kinds']), f'{where}.kinds: a higher tier cannot drop a kind the tier under it draws')
        previous = rule
        top_rate = max(top_rate, rule.get('rateScale', 1))
    def layer_ok(layer, where):
        kind = layer.get('kind') if isinstance(layer, dict) else None
        if kind not in EFFECT_KINDS:
            failures.append(f'{where}.kind: unknown kind {kind!r}')
            return
        check(hexcolor(layer.get('color')), where + '.color: expected a six-digit hex colour')
        check(layer.get('at') in attach, f'{where}.at: unknown region {layer.get("at")!r}')
        for key in EFFECT_NUMBERS[kind]:
            value = layer.get(key)
            if key in ('speed', 'spread'):
                check(finite(value) and value >= 0, f'{where}.{key}: a {kind} needs a {key} of 0 or more')
            else:
                check(positive(value), f'{where}.{key}: a {kind} needs a positive {key}')
        if kind in ('Beam', 'Trail'):
            check(layer.get('to') in attach, f'{where}.to: unknown region {layer.get("to")!r}')
        if kind == 'Beam':
            check(layer.get('to') != layer.get('at'), where + ': a beam needs two different regions')
            check(positive(layer.get('flicker')) and layer['flicker'] > look['BeamFlashSeconds'], where + '.flicker: must be longer than Look.BeamFlashSeconds')
            check(whole(layer.get('segments')) and 2 <= layer['segments'] <= 16, where + '.segments: expected a whole number from 2 to 16')
        if kind == 'Orbit':
            check(whole(layer.get('count')) and 1 <= layer['count'] <= 8, where + '.count: expected a whole number from 1 to 8')
        if kind in EFFECT_FIRED:
            check(whole(layer.get('count')) and layer['count'] >= 1, where + '.count: expected a whole number of 1 or more')
            check(layer.get('every') is not None or layer.get('flourish') is True or where.startswith('Effects.SpawnMoment'),
                  where + ': a firing needs an `every` or `flourish = true` (the spawn moment fires once)')
        check(layer.get('every') is None or positive(layer['every']), where + '.every: expected seconds above zero')
        check(layer.get('flourish') is None or isinstance(layer['flourish'], bool), where + '.flourish: expected true or false')
        if kind == 'Pillar':
            check(layer.get('flourish') is True or where.startswith('Effects.SpawnMoment'), where + ': a Pillar shows on the flourish (flourish = true)')
        if kind in ('Emitter', 'Orbit', 'Aura') and positive(layer.get('rate')):
            check(layer['rate'] * top_rate <= caps['MobileRateCap'],
                  f'{where}.rate: {layer["rate"]:g} x the top tier rateScale {top_rate:g} is over the mobile cap {caps["MobileRateCap"]}')
        if kind in ('Emitter', 'Burst'):
            check(layer.get('dir') is None or layer['dir'] in EFFECT_DIRECTIONS, f'{where}.dir: unknown direction {layer.get("dir")!r}')
        if layer.get('at') == 'Eyes':
            check(kind == 'Sparkle' and finite(layer.get('size')) and layer['size'] <= look['EyeSparkleMax'],
                  f'{where}: only a Sparkle no larger than Look.EyeSparkleMax may hang at the Eyes (never a cloud over the face)')
        check(layer.get('glow') is None or fraction(layer['glow']), where + '.glow: expected 0 to 1')
        check(layer.get('pulse') is None or positive(layer['pulse']), where + '.pulse: expected seconds above zero')
        check(layer.get('spin') is None or finite(layer['spin']), where + '.spin: expected degrees a second')
        sprite = layer.get('sprite')
        check(sprite is None or sprite in particles, f'{where}.sprite: {sprite!r} is not a key of Icons.Particles')
    for name, layer in effects['Extras'].items():
        layer_ok(layer, f'Effects.Extras.{name}')
    moment = effects.get('SpawnMoment')
    check(isinstance(moment, dict) and len(moment) > 0, 'Effects.SpawnMoment: expected a non-empty list of layers')
    if isinstance(moment, dict):
        for index, layer in moment.items():
            layer_ok(layer, f'Effects.SpawnMoment.{index}')
        check(any(layer.get('kind') == 'Pillar' for layer in moment.values()), 'Effects.SpawnMoment: the moment reaches the sky (a Pillar)')
    species = {row['id']: row for row in tables['Species']['List'].values()}
    rows = effects['Species']
    for sid in sorted(species.keys() - rows.keys()):
        failures.append(f'Effects.Species.{sid}: no effects row')
    for sid in sorted(rows.keys() - species.keys()):
        failures.append(f'Effects.Species.{sid}: no such species')
    for sid, row in sorted(rows.items()):
        if sid not in species:
            continue
        where = f'Effects.Species.{sid}'
        tier = species[sid]['tier']
        rule = rules.get(tier, {})
        check(isinstance(row.get('element'), str) and row['element'] != '', where + '.element: expected a label')
        check(row.get('accent') is None or hexcolor(row['accent']), where + '.accent: expected a six-digit hex colour')
        check(row.get('flourishEvery') is None or positive(row['flourishEvery']), where + '.flourishEvery: expected seconds above zero')
        layers = row.get('layers')
        ok = isinstance(layers, dict) and len(layers) > 0 and set(layers) == set(range(1, len(layers) + 1))
        check(ok, where + '.layers: expected a dense, non-empty list')
        if ok:
            for index, layer in layers.items():
                layer_ok(layer, f'{where}.layers.{index}')
            kinds = [layer.get('kind') for layer in layers.values()]
            check(kinds.count('Beam') <= caps['MaxBeams'], f'{where}: more beams than Effects.Caps.MaxBeams')
            check(kinds.count('Light') <= caps['MaxLights'], f'{where}: more lights than Effects.Caps.MaxLights')
            check(kinds.count('Pillar') <= caps['MaxPillars'], f'{where}: more pillars than Effects.Caps.MaxPillars')
            allowed = rule.get('kinds', {})
            for index, layer in layers.items():
                check(allowed.get(layer.get('kind')) is True, f'{where}.layers.{index}: a {tier} may not draw a {layer.get("kind")}')
                if layer.get('kind') in EFFECT_FIRED and whole(layer.get('count')):
                    check(layer['count'] <= rule.get('burstMax', 0), f'{where}.layers.{index}.count: over the {tier} burstMax {rule.get("burstMax")}')
            wanted = rule.get('layersAllowed', 1)
            check(len(layers) >= wanted, f'{where}: a {tier} draws {wanted} layers (it defines {len(layers)})')
            drawn = drawn_layers(row, rule, caps)
            shown = {layer.get('kind') for layer in drawn}
            if rule.get('orbit'):
                shown.add('Orbit')
            if rule.get('groundRing'):
                shown.add('RingPulse')
            for flag, kind in (('trail', 'Trail'), ('aura', 'Aura'), ('pillar', 'Pillar')):
                if rule.get(flag):
                    shown.add(kind)
            for kind in EFFECT_TIER_MUSTS.get(tier, ()):
                check(kind in shown, f'{where}: a {tier} shows a {kind} (B46 ladder)')
            if tier == 'Uncommon':
                check(len({layer.get('color') for layer in drawn}) >= 2, f'{where}: an Uncommon adds a touch in a second colour')
            if rule.get('flourish'):
                check(any(layer.get('flourish') is True for layer in drawn), f'{where}: a {tier} has a signature flourish (a layer with flourish = true)')
            live = live_particles(drawn, rule)
            check(live <= caps['DesktopAlienParticles'], f'{where}: about {live:.0f} live particles, over Caps.DesktopAlienParticles')
        idle = row.get('idle')
        if not isinstance(idle, dict) or idle.get('kind') not in MOTION_KINDS:
            failures.append(where + '.idle: expected a motion with a known kind')
        else:
            kind = idle['kind']
            check(finite(idle.get('amplitude')) and idle['amplitude'] >= 0, where + '.idle.amplitude: expected a number from 0')
            check(kind == 'Still' or positive(idle.get('period')), where + '.idle.period: expected seconds above zero')
            if kind == 'Spin':
                check(positive(idle.get('amplitude')) and idle['amplitude'] % 360 == 0, where + '.idle: a Spin turns whole circles (amplitude a multiple of 360)')
            parts = idle.get('parts')
            if kind == 'Flap':
                check(isinstance(parts, dict) and len(parts) > 0 and all(isinstance(v, str) for v in parts.values()), where + '.idle.parts: a Flap names its wing parts')
            else:
                check(parts is None, where + '.idle.parts: only a Flap names parts')
        sound = row.get('sound')
        check(sound is None or isinstance(tables['Sounds'].get(sound), str), f'{where}.sound: {sound!r} is not a string key of data/Sounds')
    return failures


def lint_reveal(tables, root=ROOT):
    """data/Reveal: positive durations and counts, the card's entrance inside its hold, the Rare total inside its band, a flag
    row for every tier of data/Tiers Order that agrees with the ladder (Grand from Legendary up, an iris only for a tier
    without rays, the ground ring only on a Grand tier), colour keys that exist in Theme, a button tall enough to tap."""
    data = tables.get('Reveal')
    if not isinstance(data, dict):
        return ['Reveal.luau: required table unavailable']
    failures = []
    def check(ok, message):
        if not ok:
            failures.append(message)
    def finite(value):
        return type(value) in (int, float) and math.isfinite(value)
    def positive(key):
        check(finite(data.get(key)) and data[key] > 0, f'Reveal.{key}: expected a positive number')
    def whole(key, minimum):
        check(type(data.get(key)) is int and data[key] >= minimum, f'Reveal.{key}: expected a whole number of at least {minimum}')
    def fraction(key):
        check(finite(data.get(key)) and 0 < data[key] <= 1, f'Reveal.{key}: expected a fraction in (0, 1]')
    for key in ('CrackSecondsPerTap', 'AutoCrackSeconds', 'ShardSeconds', 'RaySpinSeconds', 'CardDropSeconds', 'HoldSeconds',
                'WordDropSeconds', 'WordFadeSeconds', 'ButtonSlideSeconds', 'ReducedMotionSeconds', 'TapRingPulseSeconds',
                'TotalMinSeconds', 'TotalMaxSeconds', 'ReferenceHeight', 'PromptPx', 'PromptMaxPx', 'WordPx', 'WordMaxPx',
                'ButtonHeightPx', 'TapPulseScale', 'TapRingPulse', 'PushInScale', 'PopScale', 'RaySpinUpDegrees', 'ShardSpinDegrees',
                'WobbleStartDegrees', 'WobbleEndDegrees', 'ShardDistance', 'ShardAspect', 'EggAspect', 'CrackThickness'):
        positive(key)
    for key in ('CrackTaps', 'ShardCount', 'RayCount'):
        whole(key, 1)
    whole('ConfettiCount', 0)
    for key in ('QuietSeconds', 'SkipGuardSeconds', 'OddsDelaySeconds', 'ChipDelaySeconds', 'ButtonDelaySeconds'):
        check(finite(data.get(key)) and data[key] >= 0, f'Reveal.{key}: expected zero or more seconds')
    check(finite(data.get('LegendaryShardScale')) and data['LegendaryShardScale'] >= 1, 'Reveal.LegendaryShardScale: expected 1 or more')
    for key in ('Skip', 'CatchCrack'):
        check(type(data.get(key)) is bool, f'Reveal.{key}: expected a boolean')
    for key in ('GlowTransparencyStart', 'GlowTransparencyEnd', 'GlowBurstTransparency', 'GlowSoftness', 'DotEmptyTransparency',
                'RayTransparency', 'IrisTransparency'):
        check(finite(data.get(key)) and 0 <= data[key] <= 1, f'Reveal.{key}: expected a transparency in [0, 1]')
    check(finite(data.get('GlowTransparencyStart')) and finite(data.get('GlowTransparencyEnd')) and data['GlowTransparencyEnd'] < data['GlowTransparencyStart'],
          'Reveal.GlowTransparencyEnd: the glow must leak more by the last tap (a lower transparency than the start)')
    check(finite(data.get('WobbleStartDegrees')) and finite(data.get('WobbleEndDegrees')) and data['WobbleEndDegrees'] >= data['WobbleStartDegrees'],
          'Reveal.WobbleEndDegrees: each tap wobbles at least as hard as the one before')
    for key in ('GlowHeight', 'GlowCoreScale', 'TapRingHeight', 'EggHeight', 'ShardHeight', 'IrisHeight', 'RingWidth', 'RingHeight',
                'RingY', 'StageY', 'PromptY', 'PromptWidth', 'DotHeight', 'DotY', 'WordWidth', 'ButtonWidth', 'ButtonMargin',
                'ButtonBottom', 'ButtonSlideDistance', 'OddsHeight', 'CardDropDistance', 'FooterY', 'FooterWidth', 'FooterHeight'):
        check(finite(data.get(key)) and 0 < data[key] <= 1.5, f'Reveal.{key}: expected a screen fraction above 0')
    check(finite(data.get('OddsWidth')) and data['OddsWidth'] >= 1, 'Reveal.OddsWidth: the chance pill must be at least as wide as the card')
    check(finite(data.get('ButtonWidth')) and finite(data.get('ButtonMargin')) and 2 * (data['ButtonWidth'] + data['ButtonMargin']) < 1,
          'Reveal: the two buttons must leave the middle of the screen free')
    check(finite(data.get('FooterWidth')) and finite(data.get('ButtonWidth')) and finite(data.get('ButtonMargin')) and data['FooterWidth'] <= 1 - 2 * (data['ButtonWidth'] + data['ButtonMargin']) + 1e-9,
          'Reveal.FooterWidth: the footer must fit between the two buttons')
    # The card's entrance fits inside its hold, in order.
    if all(finite(data.get(k)) for k in ('OddsDelaySeconds', 'ChipDelaySeconds', 'ButtonDelaySeconds', 'ButtonSlideSeconds', 'HoldSeconds')):
        check(data['OddsDelaySeconds'] <= data['ChipDelaySeconds'] <= data['ButtonDelaySeconds'],
              'Reveal: the odds line, then the chips, then the buttons (OddsDelaySeconds <= ChipDelaySeconds <= ButtonDelaySeconds)')
        check(data['ButtonDelaySeconds'] + data['ButtonSlideSeconds'] <= data['HoldSeconds'],
              'Reveal: the buttons must be up inside HoldSeconds (ButtonDelaySeconds + ButtonSlideSeconds)')
    # Tap targets: the buttons are 44 px or more at the reference height, the prompt is not under the 14 px floor.
    theme = (root / 'src/shared/Theme.luau').read_text()
    tap = re.search(r'Theme\.TapMin\s*=\s*(\d+)', theme)
    minimum = re.search(r'TextSize\s*=\s*\{[^}]*Min\s*=\s*(\d+)', theme)
    check(bool(tap) and finite(data.get('ButtonHeightPx')) and data['ButtonHeightPx'] >= int(tap[1]),
          'Reveal.ButtonHeightPx: under Theme.TapMin (44 px)')
    check(bool(minimum) and finite(data.get('PromptPx')) and data['PromptPx'] >= int(minimum[1]), 'Reveal.PromptPx: under the 14 px text floor')
    # Colour keys name real Theme colours.
    def theme_keys(block):
        found = re.search(r'Theme\.' + block + r'\s*=\s*\{(.*?)\n\}', theme, re.S)
        return set(re.findall(r'^\s*(\w+)\s*=', found[1], re.M)) if found else set()
    colors, rarity = theme_keys('Colors'), theme_keys('Rarity')
    check(bool(colors) and bool(rarity), 'Reveal: Theme.Colors or Theme.Rarity unavailable')
    check(data.get('GroundRingRarity') in rarity, f'Reveal.GroundRingRarity: {data.get("GroundRingRarity")!r} is not a Theme.Rarity key')
    # Rows that are lists of numbers.
    lines = data.get('CrackLines')
    check(isinstance(lines, dict) and len(lines) >= 1, 'Reveal.CrackLines: expected at least one crack line')
    for index, line in (lines or {}).items():
        check(isinstance(line, dict) and len(line) >= 1, f'Reveal.CrackLines.{index}: expected bars')
        for bar_index, bar in (line or {}).items():
            ok = isinstance(bar, dict) and len(bar) == 4 and all(finite(v) for v in bar.values())
            check(ok, f'Reveal.CrackLines.{index}.{bar_index}: expected { "{x, y, length, degrees}" }')
            if ok:
                check(0 <= bar[1] <= 1 and 0 <= bar[2] <= 1 and bar[3] > 0, f'Reveal.CrackLines.{index}.{bar_index}: outside the egg')
    for index, row in (data.get('Speckles') or {}).items():
        ok = isinstance(row, dict) and len(row) == 3 and all(finite(v) for v in row.values())
        check(ok and 0 <= row[1] <= 1 and 0 <= row[2] <= 1 and 0 < row[3] <= 0.3, f'Reveal.Speckles.{index}: expected {{x, y, diameter}} inside the egg')
    # One flag row per tier of the ladder, in agreement with it.
    order = list(tables['Tiers']['Order'].values())
    flags = data.get('Tiers')
    check(isinstance(flags, dict) and set(flags) == set(order), 'Reveal.Tiers: needs exactly one row for every tier of data/Tiers Order')
    if isinstance(flags, dict):
        grand_from = order.index('Legendary') if 'Legendary' in order else len(order)
        for position, tier in enumerate(order):
            row = flags.get(tier)
            where = f'Reveal.Tiers.{tier}'
            if not isinstance(row, dict):
                continue
            for key in ('Rays', 'Grand', 'GroundRing', 'Iris', 'Word', 'Confetti'):
                check(type(row.get(key)) is bool, f'{where}.{key}: expected a boolean')
            check(finite(row.get('DimExtra')) and 0 <= row['DimExtra'] < 1, f'{where}.DimExtra: expected a number in [0, 1)')
            check(row.get('Grand') == (position >= grand_from), f'{where}.Grand: Legendary and every tier above it, and only those, are Grand')
            check(not row.get('GroundRing') or row.get('Grand'), f'{where}.GroundRing: the ground ring belongs to a Grand tier')
            check(not (row.get('Iris') and row.get('Rays')), f'{where}: an iris opens instead of rays, not with them')
            check(not row.get('Iris') or (finite(row.get('DimExtra')) and row['DimExtra'] > 0), f'{where}.DimExtra: an iris tier dims the screen further')
            check(row.get('Confetti') == (position >= order.index('Epic')) if 'Epic' in order else True, f'{where}.Confetti: Epic and above')
            for key in ('SecondRayColor', 'WordAccent'):
                check(row.get(key) is None or row[key] in colors, f'{where}.{key}: {row.get(key)!r} is not a Theme.Colors key')
        # The Rare total: crack + shard beat (rays or iris spend the spin) + card drop + hold, inside its band.
        rare = flags.get('Rare')
        needed = ('CrackTaps', 'CrackSecondsPerTap', 'ShardSeconds', 'RaySpinSeconds', 'CardDropSeconds', 'HoldSeconds', 'LegendaryShardScale',
                  'TotalMinSeconds', 'TotalMaxSeconds')
        if isinstance(rare, dict) and all(finite(data.get(k)) for k in needed):
            beat = data['ShardSeconds'] + (data['RaySpinSeconds'] if rare.get('Rays') or rare.get('Iris') else 0)
            beat *= data['LegendaryShardScale'] if rare.get('Grand') else 1
            total = data['CrackTaps'] * data['CrackSecondsPerTap'] + beat + data['CardDropSeconds'] + data['HoldSeconds']
            check(data['TotalMinSeconds'] <= total <= data['TotalMaxSeconds'],
                  f'Reveal: the Rare total is {total:g} s, outside {data["TotalMinSeconds"]:g} to {data["TotalMaxSeconds"]:g} s')
    # The tick sound the crack plays exists.
    check(isinstance(tables.get('Sounds', {}).get('CrackTick'), str), 'Sounds.CrackTick: the Reveal crack tick is missing')
    return failures


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
                'Tutorial', 'Layouts', 'Sizes', 'Spins', 'Icons', 'CatchVariants', 'Growth', 'Tiers', 'Props', 'ModelAssets',
                'Radar', 'Mounts', 'HomeBuild', 'Home', 'Weekly', 'Seasons', 'Shop', 'Settings', 'Codes', 'Lures', 'PowerUps', 'Textures', 'Effects', 'Sounds', 'Reveal'}
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
    failures.extend(lint_surfaces(tables))
    failures.extend(lint_props(tables))
    failures.extend(lint_effects(tables, types))
    failures.extend(lint_reveal(tables, root))
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
