#!/usr/bin/env bash
# One-shot Mac setup for the Roblox Alien Game toolchain.
# Safe to re-run. Installs CLI tools; Roblox Studio, its plugins, and Claude Desktop are
# GUI installs and are printed as manual steps at the end. See docs/SETUP.md.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
say() { printf '\n==> %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

say "Homebrew"
if ! have brew; then
  echo "Homebrew is missing. Install it from https://brew.sh then re-run this script."; exit 1
fi

say "Node.js and Claude Code"
have node || brew install node
have claude || npm install -g @anthropic-ai/claude-code
claude --version || true

say "Rokit (pins Rojo from rokit.toml)"
if ! have rokit; then
  curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
  export PATH="$HOME/.rokit/bin:$PATH"
fi
cd "$REPO" && rokit install --no-trust-check
rojo --version

say "Rojo Studio plugin"
rojo plugin install || echo "If this fails, install 'Rojo' from the Creator Store inside Studio (Toolbox > Creator Store > Plugins)."

say "Media tools for future reference videos"
have ffmpeg || brew install ffmpeg
have yt-dlp || brew install yt-dlp

if [ "${WITH_OBSIDIAN:-0}" = "1" ]; then
  say "Obsidian (optional; open docs/vault as a vault)"
  brew install --cask obsidian || true
fi

say "Studio MCP for Claude Code (project-scoped via .mcp.json, plus user-scoped fallback)"
STUDIO_MCP="/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
if [ -x "$STUDIO_MCP" ]; then
  claude mcp add --transport stdio --scope user Roblox_Studio -- "$STUDIO_MCP" || true
  echo "Registered Roblox_Studio for Claude Code. .mcp.json in the repo covers project scope."
else
  echo "Roblox Studio not found at /Applications/RobloxStudio.app. Install Studio, open it once, then re-run."
fi

cat <<'MANUAL'

Remaining manual steps (GUI):
 1. Roblox Studio: https://create.roblox.com/docs/studio/setup  (install, sign in, open once)
 2. In Studio: Assistant > ... > Manage MCP Servers > turn on "Enable Studio as MCP server",
    then Quick connect > toggle "Claude Code" (and "Claude Desktop" if you use it).
    Fully restart Studio and Claude. The panel shows a green indicator with the client count.
 3. Plugins (Toolbox > Creator Store > Plugins, or the links in docs/SETUP.md):
    Rojo, Stravant GapFill & Extrude, Stravant ResizeAlign, Stravant Redupe, Brushtool 2.1, Archimedes v3.
 4. Claude Desktop (optional, for Claude Design and Desktop MCP): https://claude.ai/download
 5. Open the repo in a terminal, run `rojo serve`, connect the Rojo plugin in Studio, press Play.
MANUAL
