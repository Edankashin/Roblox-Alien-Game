#!/usr/bin/env bash
# Pinned Linux x86_64 release archives for the ubuntu-latest CI runner.
set -euo pipefail

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo "CI installer requires Linux x86_64; use Rokit on other platforms." >&2
  exit 1
fi

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
DOWNLOADS="$REPO/.cache/ci-downloads"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$DOWNLOADS" "$BIN_DIR"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

install_release() {
  local name="$1" url="$2" archive="$3" sha256="$4"
  local path="$DOWNLOADS/$archive"
  if [[ ! -f "$path" ]]; then
    curl --fail --silent --show-error --location --retry 3 \
      "$url" -o "$TEMP_DIR/$archive"
    mv "$TEMP_DIR/$archive" "$path"
  fi
  # Validate both fresh downloads and restored cache entries before extraction.
  printf '%s  %s\n' "$sha256" "$path" | sha256sum --check --status
  unzip -p "$path" "$name" > "$TEMP_DIR/$name"
  install -m 755 "$TEMP_DIR/$name" "$BIN_DIR/$name"
}

# Keep these pins and the workflow's cache key in sync.
install_release rojo \
  https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip \
  rojo-7.7.1-linux-x86_64.zip \
  00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4
install_release luau-lsp \
  https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip \
  luau-lsp-1.70.1-linux-x86_64.zip \
  1a2ea1ae4f98f8946cefd970a4b54853e11ab4775e6932faa7f60cf920346567

"$BIN_DIR/rojo" --version
"$BIN_DIR/luau-lsp" --version
