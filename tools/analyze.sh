#!/usr/bin/env bash
# Strict-mode type check of src/ with the Roblox API definitions. Run before every commit.
# Needs rojo and luau-lsp on PATH (rokit install), and network once to fetch the definitions.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
mkdir -p .cache
DEFS=.cache/globalTypes.d.luau
if [ ! -s "$DEFS" ]; then
  curl -sS -L -o "$DEFS" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
rojo sourcemap default.project.json -o .cache/sourcemap.json >/dev/null
luau-lsp analyze --sourcemap=.cache/sourcemap.json --definitions="$DEFS" --base-luaurc=.luaurc src
echo "analyze: clean"
