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
# Blender through MCP (docs/vault/06-art-pipelines/Blender-MCP.md)
have uv || brew install uv
[ -d /Applications/Blender.app ] || brew install --cask blender || true
# The add-on installer needs Blender's user add-ons folder, which exists only after Blender has been opened
# once; create it for the installed version so a fresh machine works in one pass.
if [ -d /Applications/Blender.app ]; then
  BLENDER_VER="$(/Applications/Blender.app/Contents/MacOS/Blender --version 2>/dev/null | head -1 | sed -E 's/Blender ([0-9]+\.[0-9]+).*/\1/')"
  if [ -n "$BLENDER_VER" ]; then
    ADDONS_DIR="$HOME/Library/Application Support/Blender/$BLENDER_VER/scripts/addons"
    mkdir -p "$ADDONS_DIR"
    have uvx && BLENDERMCP_ADDONS_DIR="$ADDONS_DIR" uvx mcp-for-blender install-addon || true
  fi
fi
echo "Then in Blender: Edit > Preferences > Add-ons, enable 'Interface: MCP for Blender'; in the 3D viewport press N, open the MCP for Blender tab, click Start MCP Server."

say "Claude Code add-ons (docs/vault/02-how-we-work/Claude-Plugins.md, verdicts of 2026-10-05)"
# Team plugins are declared in .claude/settings.json (Claude Code offers to install them when this folder
# is trusted); these lines install the same two explicitly and are safe to re-run.
claude plugin install claude-code-setup@claude-plugins-official || true
claude plugin marketplace add thedotmack/claude-mem >/dev/null 2>&1 || true
claude plugin install claude-mem@thedotmack || echo "claude-mem: pick its memory provider deliberately on first run (local or your own key); see the vault page."
# Spend measurement first, then one compression trial judged against it.
# ccusage: no global install (npm -g fails with EACCES on a stock Homebrew Node); run it through npx.
echo "Weekly: run 'npx -y ccusage daily' and 'npx -y ccusage session'. Status line with context and cost: 'npx -y ccstatusline@3' once, interactive."
if [ "${WITH_RTK:-0}" = "1" ]; then
  have rtk || brew install rtk
  echo "rtk installed: a one-week trial, keep it only if ccusage shows the saving."
fi

if [ "${WITH_OBSIDIAN:-0}" = "1" ]; then
  say "Obsidian (optional; open docs/vault as a vault)"
  brew install --cask obsidian || true
fi

say "Studio MCP for Claude Code (project-scoped via .mcp.json)"
STUDIO_MCP="/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
if [ -x "$STUDIO_MCP" ]; then
  # The repo's .mcp.json is the single registration. Remove duplicates in other scopes so
  # Claude Code does not report conflicting endpoints.
  claude mcp remove Roblox_Studio -s user >/dev/null 2>&1 || true
  claude mcp remove Roblox_Studio -s local >/dev/null 2>&1 || true
  echo "Studio MCP binary found. Claude Code will offer to enable the project server (.mcp.json) when started in this folder; answer yes."
else
  echo "Roblox Studio not found at /Applications/RobloxStudio.app. Install Studio, open it once, then re-run."
fi

cat <<'MANUAL'

Remaining manual steps (GUI):
 1. Roblox Studio: https://create.roblox.com/docs/studio/setup  (install, sign in, open once)
 2. In Studio: Assistant > ... > Manage MCP Servers > turn on "Enable Studio as MCP server",
    (Quick connect is optional; the repo's .mcp.json already points Claude Code at Studio.)
    The green indicator appears only while a Claude Code session is running in this folder.
 3. Plugins (Toolbox > Creator Store > Plugins, or the links in docs/SETUP.md):
    Rojo, Stravant GapFill & Extrude, Stravant ResizeAlign, Stravant Redupe, Brushtool 2.1, Archimedes v3.
 4. Claude Desktop (optional, for Claude Design and Desktop MCP): https://claude.ai/download
 5. Open the repo in a terminal, run `rojo serve`, connect the Rojo plugin in Studio, press Play.
MANUAL
