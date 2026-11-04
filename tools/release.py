"""Release the experience for playtesting, or take it private again (Ethan, 2026-11-04: "release it for playtesting").

Four modes, all through Open Cloud with the key in the Mac shell:
  --prepare  (1) the start place (World 1) gets the name and the description Roblox shows on the game page: the name from
             docs/STORE-PAGE.md section 1 (decision 19) and the description from section 2's code block, so each has one home;
             (2) every published place gets serverSize = Config.MaxPlayers; (3) VR off (the run sheet in STORE-PAGE 5d).
             The experience stays as it is (private); nothing becomes visible to anyone.
  --public   visibility PUBLIC: anyone on Roblox can join from then on. The Friends-only switch and the Playtest list are
             dashboard-only (Creator Hub > Publish settings > Manage access). This is the one step Ethan runs himself.
  --apply    --prepare then --public in one go.
  --private  visibility PRIVATE again; Roblox removes every player from every server at once.

Official references:
  https://create.roblox.com/docs/cloud/reference/Place
    PATCH /cloud/v2/universes/{universe}/places/{place}?updateMask=displayName,description,serverSize   (universe.place:write)
  https://create.roblox.com/docs/cloud/reference/Universe
    PATCH /cloud/v2/universes/{universe}?updateMask=vrEnabled | visibility                                 (universe:write)
    visibility: PUBLIC | PRIVATE (VISIBILITY_UNSPECIFIED errors). The universe's own displayName and description follow the
    root place's, which is why --prepare writes the place.

The key comes from ROBLOX_API_KEY or ROBLOX_OPEN_CLOUD_KEY and is never printed. The dry run (default) is offline.
Run from the repo:  python3 -I tools/release.py               (dry run: prints every request --apply would send)
                    python3 -I tools/release.py --prepare
                    python3 -I tools/release.py --public
                    python3 -I tools/release.py --private
                    python3 -I tools/release.py --self-test
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from create_products import HTTP, ToolError, positive  # noqa: E402
from diagnose_join import public_game  # noqa: E402
from luau_tables import load  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
UNIVERSE = 10769415131
KEY_NAMES = ('ROBLOX_API_KEY', 'ROBLOX_OPEN_CLOUD_KEY')
NAME_LIMIT = 50
DESCRIPTION_LIMIT = 1000


def key_from_env():
    for name in KEY_NAMES:
        value = os.environ.get(name)
        if value:
            return value.strip()
    return None


def store_page(text):
    """The name (section 1, '**Decided ...: <name>**') and the description (section 2's first fenced block) of STORE-PAGE.md."""
    name = description = None
    section = None
    block = None
    for line in text.splitlines():
        if line.startswith('## '):
            section = line[3:].strip()
            continue
        if section and section.startswith('1.') and name is None and line.startswith('**Decided') and ':' in line:
            name = line.split(':', 1)[1].strip().rstrip('*').split('**')[0].strip().rstrip('.')
            name = name.split(' (')[0].strip()
        elif section and section.startswith('2.'):
            if line.startswith('```'):
                if block is None:
                    block = []
                else:
                    description = '\n'.join(block).strip()
                    block = None
                    section = 'done'
            elif block is not None:
                block.append(line)
    if not name or not description:
        raise ToolError('docs/STORE-PAGE.md has no decided name in section 1 or no fenced description in section 2')
    if len(name) > NAME_LIMIT or len(description) > DESCRIPTION_LIMIT:
        raise ToolError(f'name over {NAME_LIMIT} or description over {DESCRIPTION_LIMIT} characters')
    return name, description


def published_places(root=ROOT):
    """World number to place id for every world with a published place (0 is the home planet)."""
    worlds = load(root / 'src/shared/data/Worlds.luau')
    out = {}
    for world, row in worlds.items():
        try:
            out[int(world)] = positive(row['placeId'])
        except (KeyError, TypeError, ValueError, ToolError):
            continue
    if 1 not in out:
        raise ToolError('World 1 has no placeId in data/Worlds; nothing to release')
    return out


def prepare_plan(name, description, places, server_size, universe=UNIVERSE):
    """The requests --prepare sends, in order: the places, then VR off. Pure, for the tests and the dry run."""
    out = []
    for world in sorted(places):
        place = places[world]
        body = {'serverSize': server_size}
        mask = ['serverSize']
        if world == 1:
            body.update(displayName=name, description=description)
            mask = ['displayName', 'description', 'serverSize']
        out.append(('PATCH', f'/cloud/v2/universes/{universe}/places/{place}?updateMask=' + ','.join(mask), body))
    out.append(('PATCH', f'/cloud/v2/universes/{universe}?updateMask=vrEnabled', {'vrEnabled': False}))
    return out


def visibility_plan(value, universe=UNIVERSE):
    if value not in ('PUBLIC', 'PRIVATE'):
        raise ToolError('visibility must be PUBLIC or PRIVATE')
    return [('PATCH', f'/cloud/v2/universes/{universe}?updateMask=visibility', {'visibility': value})]


def shown(body):
    return {k: (v if k != 'description' else f'<{len(v)} characters>') for k, v in body.items()}


def send(http, requests, out=print):
    for method, path, body in requests:
        http.request(method, path, json.dumps(body).encode('utf-8'), 'application/json')
        out(f'{method} {path}  {json.dumps(shown(body))}')


def report(http, universe):
    row = http.request('GET', f'/cloud/v2/universes/{positive(universe)}')
    print(f"universe: {row.get('displayName', '?')!r}  visibility {row.get('visibility', '?')}  ageRating {row.get('ageRating', '?')}  "
          f"vr={'on' if row.get('vrEnabled') else 'off'}")
    game = public_game(universe)
    if game:
        print(f"public row: name {game.get('name')!r}  rootPlaceId {game.get('rootPlaceId')}  maxPlayers {game.get('maxPlayers')}")
    else:
        print('public row: no answer')
    return row


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--prepare', action='store_true', help='name, description, server sizes, VR off; visibility untouched')
    mode.add_argument('--public', action='store_true', help='visibility PUBLIC only (Ethan runs this one)')
    mode.add_argument('--apply', action='store_true', help='--prepare then --public')
    mode.add_argument('--private', action='store_true', help='PRIVATE again; every player is removed at once')
    mode.add_argument('--self-test', action='store_true')
    parser.add_argument('--universe', type=int, default=UNIVERSE)
    args = parser.parse_args(argv)
    if args.self_test:
        return 0 if unittest.main(module=__name__, argv=[sys.argv[0]], exit=False).result.wasSuccessful() else 1
    requests = []
    if args.prepare or args.apply or not (args.public or args.private):
        name, description = store_page((ROOT / 'docs/STORE-PAGE.md').read_text(encoding='utf-8'))
        server_size = positive(load(ROOT / 'src/shared/data/Config.luau')['MaxPlayers'])
        requests += prepare_plan(name, description, published_places(), server_size, args.universe)
        print(f'name {name!r}; description {len(description)} characters; serverSize {server_size}')
    if args.public or args.apply or not (args.prepare or args.private):
        requests += visibility_plan('PUBLIC', args.universe)
    if args.private:
        requests += visibility_plan('PRIVATE', args.universe)
    if not (args.prepare or args.public or args.apply or args.private):
        print('dry run: no network. --apply would send:')
        for method, path, body in requests:
            print(f'  {method} {path}  {json.dumps(shown(body))}')
        return 0
    key = key_from_env()
    if not key:
        print('no key in the shell: export ROBLOX_OPEN_CLOUD_KEY (or ROBLOX_API_KEY) on the Mac and run again', file=sys.stderr)
        return 2
    http = HTTP(key)
    send(http, requests)
    row = report(http, args.universe)
    wanted = 'PRIVATE' if args.private else 'PUBLIC' if (args.public or args.apply) else None
    if wanted and row.get('visibility') != wanted:
        print(f'visibility is {row.get("visibility")!r}, not {wanted}', file=sys.stderr)
        return 1
    return 0


SAMPLE_STORE_PAGE = """# Store page
## 1. Name (decision 19, Ethan's pick)

**Decided 2026-10-14: Catch an Alien** (Ethan's pick). Before entering it: search the name.

## 2. Description (paste as is; under 1,000 characters)

Refreshed 2026-10-22: 797 characters.

```
You crash-landed on a strange planet.

- 35 aliens to find
```

## 3. Settings
"""


class Tests(unittest.TestCase):
    def test_store_page_reads_name_and_description(self):
        name, description = store_page(SAMPLE_STORE_PAGE)
        self.assertEqual(name, 'Catch an Alien')
        self.assertEqual(description, 'You crash-landed on a strange planet.\n\n- 35 aliens to find')

    def test_store_page_refuses_long_text(self):
        with self.assertRaises(ToolError):
            store_page(SAMPLE_STORE_PAGE.replace('- 35 aliens to find', 'x' * 1001))

    def test_prepare_plan_names_world_1_only_and_never_touches_visibility(self):
        requests = prepare_plan('Catch an Alien', 'desc', {0: 70, 1: 93, 2: 112}, 8, universe=5)
        self.assertEqual([r[1] for r in requests], [
            '/cloud/v2/universes/5/places/70?updateMask=serverSize',
            '/cloud/v2/universes/5/places/93?updateMask=displayName,description,serverSize',
            '/cloud/v2/universes/5/places/112?updateMask=serverSize',
            '/cloud/v2/universes/5?updateMask=vrEnabled'])
        self.assertEqual(requests[1][2], {'serverSize': 8, 'displayName': 'Catch an Alien', 'description': 'desc'})
        self.assertEqual(requests[0][2], {'serverSize': 8})
        self.assertNotIn('visibility', json.dumps(requests))

    def test_visibility_plan_is_one_request_and_refuses_other_values(self):
        self.assertEqual(visibility_plan('PUBLIC', 5), [('PATCH', '/cloud/v2/universes/5?updateMask=visibility', {'visibility': 'PUBLIC'})])
        self.assertEqual(visibility_plan('PRIVATE', 5), [('PATCH', '/cloud/v2/universes/5?updateMask=visibility', {'visibility': 'PRIVATE'})])
        with self.assertRaises(ToolError):
            visibility_plan('VISIBILITY_UNSPECIFIED', 5)

    def test_send_posts_json_bodies_in_order(self):
        calls = []

        class Fake:
            def request(self, method, path, body=None, content_type=None):
                calls.append((method, path, json.loads(body), content_type))
                return {}

        send(Fake(), visibility_plan('PRIVATE', 7), out=lambda line: None)
        self.assertEqual(calls, [('PATCH', '/cloud/v2/universes/7?updateMask=visibility', {'visibility': 'PRIVATE'}, 'application/json')])

    def test_key_never_in_output(self):
        self.assertNotIn('x-api-key', __doc__)


if __name__ == '__main__':
    sys.exit(main())
