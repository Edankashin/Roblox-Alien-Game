"""Why a join to the private experience bounces back to the Roblox home screen (Ethan's phone, 2026-11-03).

Reads the universe's play settings and prints a verdict per cause, then with --fix-devices turns Computer, Phone and
Tablet on through Open Cloud. The questionnaire (age rating) can only be done on the dashboard; the script says so.

Official reference: https://create.roblox.com/docs/cloud/reference/Universe
GET   https://apis.roblox.com/cloud/v2/universes/{universeId}            (universe:read)  visibility, ageRating, *Enabled
PATCH https://apis.roblox.com/cloud/v2/universes/{universeId}?updateMask= (universe:write) desktopEnabled, mobileEnabled, tabletEnabled
GET   https://games.roblox.com/v1/games?universeIds={universeId}        (public)  name, rootPlaceId, maxPlayers

The key comes from ROBLOX_API_KEY or ROBLOX_OPEN_CLOUD_KEY in the shell and is never printed. Self-tests use fake HTTP.
Run from the repo:  python3 -I tools/diagnose_join.py            (report only)
                    python3 -I tools/diagnose_join.py --fix-devices
                    python3 -I tools/diagnose_join.py --self-test
"""
from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import unittest
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from create_products import HTTP, ToolError, positive  # noqa: E402
from luau_tables import load  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
UNIVERSE = 10769415131  # the dashboard's "alien game"
KEY_NAMES = ('ROBLOX_API_KEY', 'ROBLOX_OPEN_CLOUD_KEY')
DEVICES = ('desktopEnabled', 'mobileEnabled', 'tabletEnabled')
GAMES_API = 'https://games.roblox.com/v1/games?universeIds='


def key_from_env():
    for name in KEY_NAMES:
        value = os.environ.get(name)
        if value:
            return value.strip()
    return None


def repo_places(root=ROOT):
    """World number to place id from data/Worlds (0 is the home planet in data/Home when it is there)."""
    worlds = load(root / 'src/shared/data/Worlds.luau')
    return {world: positive(worlds[world]['placeId']) for world in (1, 2) if worlds[world]['placeId']}


def public_game(universe, opener=None):
    """The public games row: name, rootPlaceId, maxPlayers. No key is sent."""
    context = ssl.create_default_context()
    if context.cert_store_stats()['x509_ca'] == 0 and Path('/etc/ssl/cert.pem').is_file():
        context.load_verify_locations('/etc/ssl/cert.pem')
    opener = opener or urllib.request.build_opener(urllib.request.HTTPSHandler(context=context))
    request = urllib.request.Request(GAMES_API + str(positive(universe)), headers={'Accept': 'application/json'})
    try:
        with opener.open(request, timeout=30) as response:
            payload = json.loads(response.read())
    except (urllib.error.URLError, TimeoutError, OSError, ValueError):
        return None
    rows = payload.get('data') if isinstance(payload, dict) else None
    return rows[0] if isinstance(rows, list) and rows and isinstance(rows[0], dict) else None


def verdicts(universe_row, game_row, places):
    """One line per cause, each starting with OK, FIX, DASHBOARD or CHECK. Pure, for the tests."""
    out = []
    if game_row and not game_row.get('rootPlaceId'):
        game_row = None  # the placeholder row (id 0, '[TITLE UNAVAILABLE]', maxPlayers 0) a private experience answers an anonymous caller with
    root = game_row.get('rootPlaceId') if game_row else None
    world1 = places.get(1)
    if root and world1 and root != world1:
        out.append(f'FIX the Play button opens the start place {root} but the repo publishes World 1 to {world1}: '
                   f'the experience shows an old or empty place; the coordinator must retarget data/Worlds or the start place')
    elif root and world1:
        out.append(f'OK the start place is World 1 ({root})')
    else:
        out.append('CHECK the public games row did not answer, so the start place was not compared')
    if game_row and game_row.get('maxPlayers') == 0:
        out.append('FIX the start place allows 0 players; set the server size on the place')
    off = [name for name in DEVICES if universe_row.get(name) is False]
    if off:
        out.append('FIX devices off: ' + ', '.join(off) + ' (a phone cannot join while mobileEnabled is false); --fix-devices turns them on')
    else:
        out.append('OK computer, phone and tablet are on')
    rating = universe_row.get('ageRating', 'AGE_RATING_UNSPECIFIED')
    if rating == 'AGE_RATING_UNSPECIFIED':
        out.append('DASHBOARD the Experience Questionnaire is not done (ageRating unspecified): Roblox refuses joins to an unrated '
                   'experience; Ethan fills it at create.roblox.com, Creations, alien game, Settings, Experience Questionnaire')
    else:
        out.append(f'OK rated {rating}')
    visibility = universe_row.get('visibility', '?')
    out.append(f'OK visibility {visibility} (the owner can always join)' if visibility == 'PRIVATE' else f'CHECK visibility {visibility}')
    return out


def fix_devices(http, universe):
    body = json.dumps({name: True for name in DEVICES}).encode('utf-8')
    return http.request('PATCH', f'/cloud/v2/universes/{positive(universe)}?updateMask=' + ','.join(DEVICES), body, 'application/json')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--universe', type=int, default=UNIVERSE)
    parser.add_argument('--fix-devices', action='store_true', help='turn Computer, Phone and Tablet on (universe:write)')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args(argv)
    if args.self_test:
        return unittest.main(module=__name__, argv=[sys.argv[0]], exit=False).result.wasSuccessful() and 0 or 1
    key = key_from_env()
    if not key:
        print('no key in the shell: export ROBLOX_OPEN_CLOUD_KEY (or ROBLOX_API_KEY) on the Mac and run again', file=sys.stderr)
        return 2
    http = HTTP(key)
    universe_row = http.request('GET', f'/cloud/v2/universes/{positive(args.universe)}')
    game_row = public_game(args.universe)
    places = repo_places()
    print(f"experience: {universe_row.get('displayName', '?')}  visibility {universe_row.get('visibility', '?')}  "
          f"ageRating {universe_row.get('ageRating', '?')}  devices "
          + ' '.join(f"{name[:-7]}={'on' if universe_row.get(name) else 'off'}" for name in DEVICES + ('consoleEnabled', 'vrEnabled')))
    if game_row:
        print(f"public row: name {game_row.get('name')!r}  rootPlaceId {game_row.get('rootPlaceId')}  maxPlayers {game_row.get('maxPlayers')}")
    for place in sorted(places.values()):
        row = http.request('GET', f'/cloud/v2/universes/{positive(args.universe)}/places/{place}')
        print(f"place {place}: {row.get('displayName', '?')!r}  serverSize {row.get('serverSize', '?')}")
    lines = verdicts(universe_row, game_row, places)
    print('\n'.join(lines))
    if args.fix_devices and any(line.startswith('FIX devices off') for line in lines):
        fix_devices(http, args.universe)
        after = http.request('GET', f'/cloud/v2/universes/{positive(args.universe)}')
        print('devices after the fix: ' + ' '.join(f"{name[:-7]}={'on' if after.get(name) else 'off'}" for name in DEVICES))
    return 0


class Tests(unittest.TestCase):
    def test_verdicts_all_good(self):
        row = {'visibility': 'PRIVATE', 'ageRating': 'AGE_RATING_ALL', 'desktopEnabled': True, 'mobileEnabled': True, 'tabletEnabled': True}
        lines = verdicts(row, {'rootPlaceId': 5, 'maxPlayers': 12}, {1: 5, 2: 6})
        self.assertTrue(all(line.startswith('OK') for line in lines), lines)

    def test_verdicts_name_each_cause(self):
        row = {'visibility': 'PRIVATE', 'ageRating': 'AGE_RATING_UNSPECIFIED', 'desktopEnabled': True, 'mobileEnabled': False, 'tabletEnabled': True}
        lines = verdicts(row, {'rootPlaceId': 9, 'maxPlayers': 0}, {1: 5, 2: 6})
        heads = [line.split(' ', 1)[0] for line in lines]
        self.assertEqual(heads, ['FIX', 'FIX', 'FIX', 'DASHBOARD', 'OK'])
        self.assertIn('mobileEnabled', lines[2])

    def test_verdicts_without_public_row(self):
        row = {'visibility': 'PRIVATE', 'ageRating': 'AGE_RATING_ALL', 'desktopEnabled': True, 'mobileEnabled': True, 'tabletEnabled': True}
        self.assertTrue(verdicts(row, None, {1: 5})[0].startswith('CHECK'))

    def test_placeholder_public_row_raises_no_server_size_alarm(self):
        row = {'visibility': 'PRIVATE', 'ageRating': 'AGE_RATING_13_PLUS', 'desktopEnabled': True, 'mobileEnabled': True, 'tabletEnabled': True}
        lines = verdicts(row, {'rootPlaceId': 0, 'name': '[TITLE UNAVAILABLE]', 'maxPlayers': 0}, {1: 5})
        self.assertTrue(lines[0].startswith('CHECK'))
        self.assertFalse(any('0 players' in line for line in lines))

    def test_fix_devices_patches_the_three_switches(self):
        calls = []

        class Fake:
            def request(self, method, path, body=None, content_type=None):
                calls.append((method, path, json.loads(body), content_type))
                return {}

        fix_devices(Fake(), 7)
        self.assertEqual(calls, [('PATCH', '/cloud/v2/universes/7?updateMask=desktopEnabled,mobileEnabled,tabletEnabled',
                                  {'desktopEnabled': True, 'mobileEnabled': True, 'tabletEnabled': True}, 'application/json')])

    def test_key_never_in_output(self):
        self.assertNotIn('x-api-key', __doc__.lower().replace('x-api-key', ''))


if __name__ == '__main__':
    sys.exit(main())
