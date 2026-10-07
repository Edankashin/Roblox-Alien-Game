#!/usr/bin/env bash
# Run the real shared modules in the pinned, dependency-free Luau interpreter.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
LUAU_VERSION=0.741 # Keep in sync with tools/ci/install-tools.sh.
LUAU_BIN="$HOME/.local/bin/luau-$LUAU_VERSION"
if [[ ! -x "$LUAU_BIN" ]]; then
  ./tools/ci/install-tools.sh --luau-only
fi
# Luau's sandbox has no file IO. Bundle unchanged source as strings for the
# runner's loadstring/setfenv loader; all generated files stay in ignored cache.
python3 - "$LUAU_BIN" <<'PY'
from pathlib import Path
import subprocess
import os
import sys
import time

root = Path.cwd()
# Only the pure schema is bundled from server; services remain unavailable.
files = (sorted((root / 'src/shared').rglob('*.luau'))
         + [root / 'src/server/ProfileSchema.luau']
         + sorted((root / 'tests').glob('*.luau')))
specs = sorted((root / 'tests').glob('*.spec.luau'))
if not specs:
    raise SystemExit('headless: no specs found')
output = root / '.cache/headless/sources.luau'
output.parent.mkdir(parents=True, exist_ok=True)

def literal(source):
    equals = '='
    while ']' + equals + ']' in source:
        equals += '='
    return '[' + equals + '[' + source + ']' + equals + ']'

rows = []
for path in files:
    if path.name != 'run.luau':
        rows.append(f'[ {literal(path.relative_to(root).as_posix())} ] = {literal(path.read_text())},')
output.write_text('return {\n' + '\n'.join(rows) + '\n}\n')
start = time.perf_counter()
result = subprocess.run([sys.argv[1], 'tests/run.luau'], env={**os.environ, 'TZ': 'UTC'})
print(f'headless: runtime {time.perf_counter() - start:.3f}s ({len(specs)} specs)', flush=True)
raise SystemExit(result.returncode)
PY
