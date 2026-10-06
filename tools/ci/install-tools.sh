#!/usr/bin/env bash
# Pinned CI tools; --luau-only also installs the headless interpreter on macOS.
set -euo pipefail

MODE="${1:-all}"
if [[ "$MODE" != all && "$MODE" != --luau-only ]]; then
  echo "usage: $0 [--luau-only]" >&2
  exit 1
fi
if [[ "$MODE" == all && ( "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ) ]]; then
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
  if [[ "$(uname -s)" == Linux ]]; then
    printf '%s  %s\n' "$sha256" "$path" | sha256sum --check --status
  else
    printf '%s  %s\n' "$sha256" "$path" | shasum -a 256 --check --status
  fi
  unzip -p "$path" "$name" > "$TEMP_DIR/$name"
  install -m 755 "$TEMP_DIR/$name" "$BIN_DIR/${5:-$name}"
}

if [[ "$MODE" == all ]]; then
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
fi

# A versioned filename lets test.sh require the exact interpreter without relying
# on a --version flag (the upstream Luau CLI does not provide one).
LUAU_VERSION=0.741
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    LUAU_PLATFORM=ubuntu
    LUAU_SHA256=134dc762ad26232af83e43f98dec03ff6030dd3a4452f9408b9d50ccea025503 ;;
  Darwin-arm64|Darwin-x86_64)
    LUAU_PLATFORM=macos
    LUAU_SHA256=839cc1de39b0f765fbaea8e89421c12acfed6bd3d8d2cc2a2d3fc64bdde32b0f ;;
  *) echo "Unsupported Luau platform: $(uname -s)-$(uname -m)" >&2; exit 1 ;;
esac
install_release luau \
  "https://github.com/luau-lang/luau/releases/download/$LUAU_VERSION/luau-$LUAU_PLATFORM.zip" \
  "luau-$LUAU_VERSION-$LUAU_PLATFORM.zip" "$LUAU_SHA256" "luau-$LUAU_VERSION"
echo "Installed Luau $LUAU_VERSION ($LUAU_PLATFORM)"
