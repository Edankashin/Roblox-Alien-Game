#!/usr/bin/env python3
"""Check client offsets/fonts and ratchet colour constructors; report raw-button sound candidates.

No network or Roblox runtime. Token-based direct-call checks skip comments/strings;
button callbacks are a documented heuristic, not an all-path sound proof.
"""
from collections import Counter
from pathlib import Path
import argparse
import hashlib
import json
import re
import sys
import subprocess
sys.path.insert(0, str(Path(__file__).resolve().parent))
from lint_data import ROOT, LEX

GRID_MARKER = '-- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)'
# Immutable initial C11 ceilings: SHA256(path + normalized constructor), count.
# The JSON baseline can remove entries/reduce counts, never add to this ceiling.
# Updating these ceilings requires an explicit coordinator-approved rule change.
APPROVED_COLOURS = {'09fc62aa2652f2b528d9a1daca3d4bf426e688cd42eb74134a178461f1de6e8b': 1,
 '0ef0fb8702b87a23bf6b5a9e1c22c6c01ba1a7df23c694c3d942bca330d43470': 1,
 '12f7e64e13fadaaee7d31cd41840d928a6aa6b17ddcaff07a5f9e1efda1bdfbd': 1,
 '1b8a8983d0b04ee54457e9e68254de81283d6c065d0d2676c65cc1f9d769bf94': 2,
 '2cbd1032f0c06d24ec9c335bbb49bb08571edd732b095ff111d9e9c541909232': 1,
 '79ca1a5fe9a99a276acd72f09d00445275685cc294e2ab568d2d0f3b3ff7f0bb': 1,
 '9e9b823e330b0987f8a5ecca07720bf363a299c146e81e61aad3c7e5fcbd9ede': 3,
 'a36da8c0d494aca4a25c73e894656e94a9458be2267ea70b39c4442b99598412': 1,
 'ab0360b85972d94d1c9f0f0ffce8a79b2bdfd3e3d435f40194de01f73c3aab2c': 3,
 'c005d04a7e67385716bc09c2390f1516d2f97e6a5fe53892d32c1fd419a3b28c': 1,
 'c0a344a9cd3cb269f8cb6f180bec2f1bddfe7dc2672f05e7bd21a6e1a95bffba': 1,
 'c4a82a45c569b18a45f9b39d0fb248588c84c2b32268eaddbe295b3b3458efc1': 1,
 'c85b3e121dcd11e856f513afcb722026543f9c553e0330ad09566b2f7c2a1e81': 1,
 'e379730ea501dd97c5acdc7b25829e62ad234a9cfa8b7176629e484c1a6becde': 1,
 'fca8edd9fa18bed8982e24963607e2349a690130ef5faca2665adb38139fe23a': 1}


def lex(source):
    return [(m.group(), m.start(), m.end()) for m in LEX.finditer(source)
            if not m.group().startswith('--')]


def call_end(ts, opening):
    depth = 0
    for i in range(opening, len(ts)):
        if ts[i][0] == '(': depth += 1
        elif ts[i][0] == ')':
            depth -= 1
            if depth == 0: return i
    raise ValueError('unclosed constructor/callback call')


def arguments(ts, opening, end):
    result, part, depth = [], [], 0
    for token, _, _ in ts[opening + 1:end]:
        if token == ',' and depth == 0:
            result.append(part); part = []
        else:
            part.append(token)
            if token in ('(', '{', '['): depth += 1
            elif token in (')', '}', ']'): depth -= 1
    if part: result.append(part)
    return result


def zero(arg):
    # Only a literal zero is proven; variable/computed offsets require review.
    value = ''.join(arg).strip('()')
    try:
        return float(value) == 0
    except ValueError:
        return False


def fingerprint(path, expression):
    return hashlib.sha256((path + '\n' + expression).encode()).hexdigest()


def scans(root):
    failures, exceptions, buttons = [], [], []
    colours = Counter()
    locations = {}
    for path in sorted((root / 'src/client').rglob('*.luau')):
        rel = path.relative_to(root).as_posix()
        source = path.read_text()
        lines = source.splitlines()
        ts = lex(source)
        words = [t[0] for t in ts]
        def where(i): return f'{rel}:{source.count(chr(10), 0, ts[i][1]) + 1}'
        # Resolve local helpers whose leading straight-line body plays a sound.
        helpers = {}
        for i in range(len(ts) - 3):
            if words[i] == 'function' and re.fullmatch(r'\w+', words[i + 1]) and words[i + 2] == '(':
                end = call_end(ts, i + 2)
                start = end + 1
                stop = start
                while stop < len(ts) and words[stop] not in ('if', 'for', 'while', 'repeat', 'return', 'end', 'function'):
                    stop += 1
                helpers[words[i + 1]] = words[start:stop]
        def sounds(body, seen=None):
            seen = set() if seen is None else seen
            if any(body[j:j + 4] == ['Builder', '.', 'playSound', '('] for j in range(len(body) - 3)):
                return True
            for j, token in enumerate(body[:-1]):
                if body[j + 1] == '(' and token in helpers and token not in seen:
                    if sounds(helpers[token], seen | {token}): return True
            return False
        for i in range(len(ts) - 3):
            obj, dot, method, opening = words[i:i + 4]
            if obj == 'Enum' and dot == '.' and method == 'Font' and rel != 'src/client/UI/Builder.luau':
                failures.append(where(i) + ': font must come from Theme/Builder')
            if dot != '.' or opening != '(':
                continue
            relevant = (obj, method) in {('UDim2', 'new'), ('UDim2', 'fromOffset'), ('UDim', 'new'),
                                        ('Color3', 'new'), ('Color3', 'fromHex'), ('Color3', 'fromRGB'),
                                        ('Font', 'new'), ('Instance', 'new')}
            if not relevant: continue
            end = call_end(ts, i + 3)
            args = arguments(ts, i + 3, end)
            if obj == 'Font' and rel != 'src/client/UI/Builder.luau':
                failures.append(where(i) + ': font must come from Theme/Builder')
            if obj == 'Color3':
                expression = ' '.join(words[i:end + 1])
                key = (rel, expression)
                colours[key] += 1
                locations.setdefault(key, []).append(where(i))
            if obj in ('UDim', 'UDim2'):
                property_name = words[i - 2] if i >= 2 and words[i - 1] == '=' else ''
                bad = obj == 'UDim2' and (method == 'fromOffset' or len(args) != 4 or not zero(args[1]) or not zero(args[3]))
                if obj == 'UDim' and property_name.lower() in ('size', 'position'):
                    bad = len(args) == 2 and zero(args[0]) and not zero(args[1])
                if bad:
                    line = source.count('\n', 0, ts[i][1])
                    same_line = '\n' not in source[ts[i][1]:ts[end][2]]
                    marked = lines[line].rstrip().endswith(GRID_MARKER)
                    vertical_only = obj == 'UDim2' and ((method == 'new' and len(args) == 4 and zero(args[1]) and zero(args[2]))
                        or (method == 'fromOffset' and len(args) == 2 and zero(args[0])))
                    allowed = same_line and marked and property_name in ('CellSize', 'CellPadding') and vertical_only
                    if allowed: exceptions.append(where(i) + ': ' + property_name + ' marked grid pixel height')
                    else: failures.append(where(i) + ': non-Scale offset (' + obj + '.' + method + ')')
            if obj == 'Instance' and method == 'new' and args and args[0] in [['"TextButton"'], ['"ImageButton"'], ["'TextButton'"], ["'ImageButton'"]]:
                if not rel.startswith('src/client/UI/'): continue
                var = words[i - 2] if i >= 2 and words[i - 1] == '=' else None
                connected, audible = False, False
                if var:
                    for j in range(end + 1, len(ts) - 5):
                        if words[j:j + 3] == ['local', var, '=']: break
                        if words[j:j + 2] == [var, '.'] and words[j + 2] in ('Activated', 'MouseButton1Click') and words[j + 3:j + 6] == [':', 'Connect', '(']:
                            connected = True
                            close = call_end(ts, j + 5)
                            body = words[j + 6:close]
                            audible = audible or sounds(body) or (len(body) == 1 and body[0] in helpers and sounds(helpers[body[0]]))
                # Builder.button is the shared sound-playing constructor, inspected
                # above too; consumers of Builder.button are not raw creations.
                status = 'sound found' if connected and audible else ('handler has no resolved sound' if connected else 'no Activated/MouseButton1Click handler')
                buttons.append((where(i), var or '<unbound>', status))
    return failures, exceptions, buttons, colours, locations


def audit(root=ROOT):
    failures, exceptions, buttons, colours, locations = scans(root)
    baseline = json.loads((root / 'tools/lint_ui_baseline.json').read_text())
    # Compare local history too, so a previously removed allowance cannot be
    # restored merely because it existed at C11. Shallow CI may lack HEAD^;
    # the immutable initial ceiling still applies in that case.
    previous = []
    if (root / '.git').exists():
        for revision in ('HEAD', 'HEAD^'):
            result = subprocess.run(['git', 'show', revision + ':tools/lint_ui_baseline.json'],
                                    cwd=root, capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                old = json.loads(result.stdout)
                previous.append({(e['path'], e['expression']): e['count'] for e in old['colours']})
    allowed = {}
    for entry in baseline['colours']:
        key = (entry['path'], entry['expression'])
        count = entry['count']
        ceiling = APPROVED_COLOURS.get(fingerprint(*key), 0)
        if key in allowed or type(count) is not int or not 0 < count <= ceiling:
            failures.append('baseline: invalid/new/increased colour allowance: ' + str(key))
            continue
        if any(count > old.get(key, 0) for old in previous):
            failures.append('baseline: allowance increased against Git history: ' + str(key))
        allowed[key] = count
    for key, count in sorted(colours.items()):
        if count > allowed.get(key, 0):
            failures.append(f'{locations[key][0]}: new colour constructor ({count} occurrences; baseline {allowed.get(key, 0)}): {key[1]}')
    for key, count in sorted(allowed.items()):
        if colours[key] < count:
            failures.append(f'baseline: shrink stale colour allowance {key[0]}: {key[1]} ({count} -> {colours[key]})')
    return {'failures': failures, 'exceptions': exceptions, 'buttons': buttons,
            'colours': colours, 'locations': locations}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT, help='repository root (default: this checkout)')
    parser.add_argument('--list-baseline', action='store_true', help='list audited colour allowances and current source locations; never expand the baseline')
    args = parser.parse_args()
    result = audit(args.root)
    for failure in result['failures']: print('FAIL UI: ' + failure)
    for exception in result['exceptions']: print('allow UI: ' + exception)
    silent = [row for row in result['buttons'] if row[2] != 'sound found']
    for path, var, reason in silent: print(f'warning UI: {path}: {var}: {reason} (advisory)')
    if args.list_baseline:
        for key, count in sorted(result['colours'].items()):
            print(f'baseline UI: {", ".join(result["locations"][key])}: {key[1]} × {count}')
    print(f'UI lint: {sum(result["colours"].values())} baseline colour calls, {len(result["exceptions"])} grid exceptions, {len(result["buttons"])} raw buttons, {len(silent)} silent-tap candidates')
    print('UI lint: ' + ('FAILED' if result['failures'] else 'clean'))
    return bool(result['failures'])


if __name__ == '__main__':
    sys.exit(main())
