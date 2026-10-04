# Setup: attaching Claude to Roblox Studio and installing the toolchain

Everything below runs on your Mac. This repo pins the CLI toolchain; Studio, its plugins, and Claude Desktop are app installs. Links and commands were checked against Roblox's current docs on 2026-10-04.

## 0. One command for the CLI side

```bash
git clone https://github.com/Edankashin/Roblox-Alien-Game && cd Roblox-Alien-Game
git checkout claude/alien-system-research
./tools/setup-mac.sh            # add WITH_OBSIDIAN=1 in front to also install Obsidian
```

It installs Node and Claude Code, Rokit and Rojo 7.7.1 (pinned in `rokit.toml`), the Rojo Studio plugin, ffmpeg and yt-dlp, and registers the Studio MCP server with Claude Code. Then it prints the manual steps below.

## 1. Roblox Studio

Install from https://create.roblox.com/docs/studio/setup, sign in with the account that will own the experience, and open it once. The MCP server is built into Studio; keep Studio on the latest version.

## 2. Attach Claude to Studio (the important one)

Studio ships its own MCP server. Any MCP client can read the game tree, read and edit scripts, insert assets, generate meshes and materials, run Luau, start and stop play mode, read the output log, capture the viewport, and simulate input.

**In Studio**

1. Open **Assistant** (the button two to the left of your profile picture).
2. Click **…** then **Manage MCP Servers**.
3. Turn on **Enable Studio as MCP server**.
4. Expand **Quick connect** and toggle **Claude Code**. Toggle **Claude Desktop** too if you use it. If a client is missing from the list, install it and restart Studio.
5. Fully restart Studio and the client. Back in the same panel, a green indicator shows how many clients are connected.

**Fallbacks if Quick connect does not list your client**

- Claude Code, from the repo folder: the checked-in `.mcp.json` already points at the Mac server path, so Claude Code picks it up when started inside the repo. To register it for every project instead:

  ```bash
  claude mcp add --transport stdio --scope user Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
  ```

- Claude Desktop: Settings, Developer, Edit Config, and add

  ```json
  { "mcpServers": { "Roblox_Studio": { "command": "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP" } } }
  ```

- Windows uses `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` instead of the Mac path.

**Verify**: in Claude Code type `/mcp` and confirm `Roblox_Studio` is connected, then ask it to "list the connected Studio instances" (the `list_roblox_studios` tool). Every tool call targets a `studio_id`, so one client can drive several open Studio windows.

Docs: https://create.roblox.com/docs/studio/mcp. Roblox's older open-source server (`Roblox/studio-rust-mcp-server`) is no longer developed; use the built-in one.

## 3. Rojo (code sync)

`rokit.toml` pins Rojo. After the script, in the repo:

```bash
rojo serve
```

In Studio, open the Rojo plugin (Plugins tab), connect to `localhost:34872`, and the `src/` tree appears under ReplicatedStorage.Shared, ServerScriptService.Server and StarterPlayerScripts.Client as mapped in `default.project.json`. Rojo carries code and data; the MCP connection carries live instance edits and testing. Both stay on while building.

If `rojo plugin install` fails, install "Rojo" from the Creator Store inside Studio.

## 4. Studio plugins (Creator Store, install from inside Studio or the links)

| Plugin | Use here | Link |
|---|---|---|
| Stravant GapFill & Extrude | close seams between ship modules and camp parts | https://create.roblox.com/store/asset/165687726 |
| Stravant ResizeAlign | snap parts together precisely | search "Stravant - ResizeAlign" in the Creator Store and confirm the author is stravant (a re-upload titled "[Use Original] Fixed ResizeAlign and GapFill" exists; use the original) |
| Stravant Redupe | station rows, fence lines, codex pedestals, repeated hull plates | https://create.roblox.com/store/asset/73064993918325 |
| Brushtool 2.1 (XAXA) | scatter biome props | https://create.roblox.com/store/asset/2268520847 |
| Archimedes v3.1.9 (Scriptos) | round camp pads, curved hull pieces, arches | https://create.roblox.com/store/asset/144938633 |
| Rojo | code sync | `rojo plugin install`, or the Creator Store |

Only install plugins from the authors named; plugins run with full access to your places.

## 5. Claude Code and the knowledge vault

Claude Code is installed by the script (`npm install -g @anthropic-ai/claude-code`). Run it from the repo folder so it reads `CLAUDE.md` and the vault:

```bash
cd Roblox-Alien-Game && claude
```

The vault lives at `docs/vault/`. If you like Obsidian for reading and editing it, install it (`WITH_OBSIDIAN=1 ./tools/setup-mac.sh` or https://obsidian.md) and open `docs/vault` as a vault. It is plain markdown either way, so every Claude session reads it without Obsidian.

## 6. Claude Design (creature generation)

Claude Design is an Anthropic Labs product launched April 17, 2026, in research preview for Claude Pro, Max, Team and Enterprise subscribers. It is what the reference creator used to generate Roblox-ready models with VFX and animation sets plus a Lua installer. Access it from the Claude app with a paid plan; the per-species prompt template is in `docs/PRE_PRODUCTION.md` section 10.6 and `docs/vault/06-art-pipelines/Creature-Generation.md`.

Free fallback built into Studio: the MCP server's `generate_mesh` (textured mesh from a text prompt), `generate_material` and `generate_procedural_model` tools, which Claude Code can call directly once connected.

## 7. Reference videos in future

Save the TikTok, then from the repo:

```bash
yt-dlp --write-info-json -f "mp4/best" -o "media/tiktok/<code>.%(ext)s" "https://www.tiktok.com/t/<code>/"
git add media/tiktok && git commit -m "Add reference video <code>" && git push
```

The cloud session processes it with `tools/watch_video.py`.

## 8. Order of operations for the first build day

1. Run the script, install Studio and the plugins, connect Rojo and MCP, see the green indicator.
2. Answer the decisions list in `docs/PRE_PRODUCTION.md` section 2.
3. Send the build prompt from section 9. The first deliverable is the vertical slice in section 5.
