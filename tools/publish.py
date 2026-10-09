#!/usr/bin/env python3
"""Check and build the three places; offline --dry-run is the default.

Official reference: https://create.roblox.com/docs/cloud/guides/usage-place-publishing
POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions
?versionType=Published (or Saved), application/octet-stream .rbxl body;
x-api-key, universe-places:write; response: versionNumber.
--apply publishes; --saved uploads an unpublished version. Until the runtime
model loader is approved, the Mac must use --saved, never --apply.
--self-test uses fake processes and HTTP, never credentials or the network.
"""
import argparse
import contextlib
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from create_products import HTTP, ToolError, positive, resolve_universe
from luau_tables import load

ROOT = Path(__file__).resolve().parents[1]
PROJECTS = (('world1', 'default.project.json', 1),
            ('world2', 'world2.project.json', 2),
            ('home', 'home.project.json', 0))
CHECKS = (('./tools/analyze.sh',), (sys.executable, '-I', 'tools/lint_data.py'),
          ('./tools/test.sh',), ('./tools/lint.sh',))


def run(command, root):
    try:
        result = subprocess.run(command, cwd=root, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, check=False,
                                env={k: v for k, v in os.environ.items() if k != 'ROBLOX_API_KEY'})
    except OSError:
        raise ToolError('cannot run ' + command[0] + '; check the tool installation and PATH') from None
    # Credentials are never needed by builds/checks or inherited by their children.
    print(result.stdout, end='')
    if result.returncode:
        raise ToolError('command failed: ' + command[0])
    return result.stdout


def checked_build(root, only=None, runner=run):
    for command in CHECKS:
        output = runner(command, root)
        if command == CHECKS[0] and 'analyze: clean' not in output.splitlines():
            raise ToolError('analyze did not report analyze: clean')
    worlds = load(root / 'src/shared/data/Worlds.luau')
    selected = []
    for name, project, world in PROJECTS:
        if only and only != name:
            continue
        try:
            place = positive(worlds[world]['placeId'])
        except (KeyError, TypeError, ToolError):
            raise ToolError(name + ' needs a positive Worlds placeId; refusing to build/upload') from None
        selected.append((name, project, place))
    (root / 'build').mkdir(exist_ok=True)
    builds = []
    for name, project, place in selected:
        relative = 'build/' + name + '.rbxl'
        target = root / relative
        # Remove an old artifact so a broken builder cannot publish yesterday's file.
        target.unlink(missing_ok=True)
        runner(('rojo', 'build', project, '-o', relative), root)
        if not target.is_file() or target.stat().st_size == 0:
            raise ToolError('build produced no place: ' + relative)
        builds.append((name, place, target))
        print(f'{name}: place {place}, {target.stat().st_size} bytes, {relative}')
    return builds


def upload(http, root, builds, universe, saved):
    universe = resolve_universe(http, root, universe)
    version_type = 'Saved' if saved else 'Published'
    for name, place, target in builds:
        path = f'/universes/v1/{universe}/places/{place}/versions?versionType={version_type}'
        response = http.request('POST', path, target.read_bytes(), 'application/octet-stream')
        version = positive(response.get('versionNumber'))
        print(f'{name}: {version_type}, version {version}')


def execute(args, root=ROOT, runner=run, http_factory=HTTP):
    builds = checked_build(root, args.only, runner)
    if not (args.apply or args.saved):
        print('dry-run: checks and builds only; no network requests')
        return
    key = os.environ.get('ROBLOX_API_KEY')
    if not key:
        raise ToolError('ROBLOX_API_KEY is required for --apply or --saved')
    upload(http_factory(key), root, builds, args.universe, args.saved)


def parser():
    result = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = result.add_mutually_exclusive_group()
    mode.add_argument('--dry-run', action='store_true', help='run checks and build only (default, offline)')
    mode.add_argument('--apply', action='store_true', help='publish built places; requires approved runtime model loader')
    mode.add_argument('--saved', action='store_true', help='upload Saved versions without publishing')
    mode.add_argument('--self-test', action='store_true', help='run offline process/HTTP tests')
    result.add_argument('--only', choices=[p[0] for p in PROJECTS], help='build/upload just this place')
    result.add_argument('--universe', type=int, help='positive universe id; otherwise resolve World 1, then World 2')
    return result


def self_test():
    class PublishTests(unittest.TestCase):
        def setUp(self):
            self.temp = tempfile.TemporaryDirectory()
            self.addCleanup(self.temp.cleanup)
            self.root = Path(self.temp.name)
            self.commands = []
            self.requests = []
            self.worlds = {world: {'placeId': index + 1} for index, (_, _, world) in enumerate(PROJECTS)}
            self.loader = patch(__name__ + '.load', return_value=self.worlds)
            self.loader.start()
            self.addCleanup(self.loader.stop)
            self.output = contextlib.redirect_stdout(io.StringIO())
            self.output.__enter__()
            self.addCleanup(self.output.__exit__, None, None, None)

        def runner(self, command, root):
            self.commands.append(command)
            if command[0] == 'rojo':
                (root / command[-1]).write_bytes(b'fake rbxl')
            return 'analyze: clean\n'

        def request(self, method, path, body=None, content_type=None):
            self.requests.append((method, path, body, content_type))
            return {'universeId': 42} if method == 'GET' else {'versionNumber': 7}

        def test_default_is_offline_and_builds_all(self):
            with patch.dict(os.environ, {}, clear=True):
                execute(parser().parse_args([]), self.root, self.runner,
                        lambda _: self.fail('dry-run attempted HTTP'))
            self.assertEqual(self.commands[:len(CHECKS)], list(CHECKS))
            self.assertEqual(len(self.commands), len(CHECKS) + len(PROJECTS))
            self.assertEqual(sorted(p.stem for p in (self.root / 'build').iterdir()), sorted(p[0] for p in PROJECTS))

        def test_only_home_maps_world_zero(self):
            builds = checked_build(self.root, 'home', self.runner)
            self.assertEqual([(n, p) for n, p, _ in builds], [('home', self.worlds[0]['placeId'])])
            self.assertIn('home.project.json', self.commands[-1])

        def test_zero_refuses_before_build(self):
            self.worlds[0]['placeId'] = 0
            with self.assertRaises(ToolError): checked_build(self.root, runner=self.runner)
            self.assertEqual(self.commands, list(CHECKS))

        def test_check_failure_stops(self):
            for failed in CHECKS:
                self.commands.clear()
                def fail(command, root):
                    self.commands.append(command)
                    if command == failed: raise ToolError('failed')
                    return 'analyze: clean\n'
                with self.assertRaises(ToolError): checked_build(self.root, runner=fail)
                self.assertEqual(self.commands, list(CHECKS[:CHECKS.index(failed) + 1]))

        def test_children_never_receive_key(self):
            result = subprocess.CompletedProcess([], 0, '')
            with patch.dict(os.environ, {'ROBLOX_API_KEY': 'fake-secret'}), patch('subprocess.run', return_value=result) as process:
                run(CHECKS[0], self.root)
            self.assertNotIn('ROBLOX_API_KEY', process.call_args.kwargs['env'])

        def test_missing_clean_marker_stops(self):
            with self.assertRaises(ToolError): checked_build(self.root, runner=lambda *_: '')
            self.assertFalse((self.root / 'build').exists())

        def test_empty_or_stale_build_refused(self):
            (self.root / 'build').mkdir()
            (self.root / 'build/world1.rbxl').write_bytes(b'stale')
            with self.assertRaises(ToolError): checked_build(self.root, runner=lambda *_: 'analyze: clean\n')
            self.assertFalse((self.root / 'build/world1.rbxl').exists())

        def test_saved_and_published_payloads(self):
            builds = checked_build(self.root, runner=self.runner)
            for saved, expected in ((True, 'Saved'), (False, 'Published')):
                self.requests.clear()
                upload(self, self.root, builds, 42, saved)
                self.assertEqual(len(self.requests), len(PROJECTS))
                for request, (_, place, _) in zip(self.requests, builds):
                    self.assertEqual(request, ('POST', f'/universes/v1/42/places/{place}/versions?versionType={expected}', b'fake rbxl', 'application/octet-stream'))

        def test_missing_key_refused(self):
            with patch.dict(os.environ, {}, clear=True), self.assertRaises(ToolError):
                execute(parser().parse_args(['--saved']), self.root, self.runner)

        def test_resolver_world_two_fallback(self):
            with patch('create_products.load', return_value=self.worlds):
                for first in (self.worlds[1]['placeId'], 0):
                    self.worlds[1]['placeId'] = first
                    self.requests.clear()
                    self.assertEqual(resolve_universe(self, self.root, None), 42)
                    expected = first or self.worlds[2]['placeId']
                    self.assertEqual(self.requests[0][1], f'/universes/v1/places/{expected}/universe')

        def test_invalid_response_refused(self):
            builds = checked_build(self.root, 'home', self.runner)
            with patch.object(self, 'request', return_value={'versionNumber': 0}), self.assertRaises(ToolError):
                upload(self, self.root, builds, 42, True)

    suite = unittest.defaultTestLoader.loadTestsFromTestCase(PublishTests)
    return 0 if unittest.TextTestRunner(verbosity=1).run(suite).wasSuccessful() else 1


def main():
    args = parser().parse_args()
    if args.self_test:
        return self_test()
    if args.universe is not None:
        try: positive(args.universe)
        except ToolError: parser().error('--universe must be positive')
    try:
        execute(args)
        return 0
    except (ToolError, OSError, ValueError, KeyError, TypeError) as exc:
        # Shared HTTP handles key redaction; also redact any local diagnostic.
        message = str(exc)
        key = os.environ.get('ROBLOX_API_KEY')
        if key: message = message.replace(key, '[redacted]')
        print('publish: ' + message, file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
