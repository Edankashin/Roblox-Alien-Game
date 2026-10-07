# Tools status: every tool mentioned, decided, and actually in use

Written 2026-10-07 after Ethan asked why Obsidian, mentioned several times, was never installed. The answer: the vault idea was built (`docs/vault/`, read before every task), but the Obsidian app itself was treated as optional and that was never said plainly; and more generally, tools were given "adopt" verdicts with install commands in [[Claude-Plugins]] and the plan, but every install needed a step on the Mac and nothing tracked a decision through to "installed and verified". This page is that tracker. A decision is not done until the last column says verified.

States: **in use** (installed and part of the workflow), **decided, not installed** (the gap this page exists to close), **chosen instead** (a different tool does the job), **later** or **skip** (deliberately not now). "Mac audit" means the Mac session is checking the real install state (requested 2026-10-07).

## Workflow and AI tools

| Tool | Where it came from | Decision | State | Next step and owner |
|---|---|---|---|---|
| Obsidian (app) | TikTok ZPLRwG4Co, Ethan's messages | The vault idea adopted 2026-10-04; the app not installed | **in use** since 2026-10-07 (Mac session: installed, `docs/vault` registered, daily log in `08-log/`); its command line is off | Optional: Settings, General, Advanced turns the CLI on |
| Roblox Studio MCP | TikTok ZPLRwqGrt | Adopt | **in use** (Mac; enabled for Studio and the Claude CLI 2026-10-07) | Done |
| Blender MCP | TikToks ZPLRw3ubt, ZPL8Hb7yS | Adopt | **in use** (32 species, props, icons modelled through it) | Done |
| Rojo, luau-lsp, rokit | Build plan | Adopt | **in use** (`rokit.toml`, `tools/analyze.sh`) | Done |
| Codex CLI | Ethan | Adopt | **in use** (queue in [[Codex-Queue]]; the Mac starts batch runs) | Done |
| Claude Code Setup plugin | Ethan's add-on list 2026-10-05 | Adopt now | **in use** (1.0.0, user and project scope, Mac audit 2026-10-07) | Done |
| claude-mem | Ethan's add-on list | Adopt as a one-week trial | **half working** (13.31.0 enabled, its search server connects, but its packages did not install: it needs `bun`, not on the Mac) | Ethan's yes for `brew install bun` (or the official bun installer), then the trial week |
| Roblox Dev plugin (ivar-anon) | TikTok ZPL8Hb7yS | Adopt after a dry run | **decided, not installed** (no record) | Ethan runs the install line (Claude sessions do not install plugins into themselves), then the Mac runs the dry run in [[Claude-Plugins]] |
| Roblox Studio skill (ShiroKSH) | TikTok ZPL8Hb7yS | Adopt for World 2 map work | **decided, not installed** | Same as above, before the World 2 map pass |
| Superpowers | TikTok ZPL8Hb7yS | Try on one big build | **decided, not installed** | Same; tried on the cinematic milestone (47) |
| ccusage | Token survey 2026-10-05 | Adopt now | **available** through `npx` (npx 11.11.0 on the Mac), never run | Mac: `npx ccusage` once a week into the log |
| rtk | Token survey | Adopt now as a trial | **decided, not installed** | Ethan's yes for a `brew install` on the Mac |
| ccstatusline | Token survey | Adopt now | **decided, not installed** | Optional; Ethan's call |
| StyLua | Token survey (Roblox tools) | Adopt now | **decided, not added** (not on the Mac either; nor selene, lune) | Coordinator: add to `rokit.toml` with a config matching today's style, as an advisory check first so no mass reformat collides with Codex |
| ProfileStore | Token survey (Roblox tools) | Adopt now, pending the team's OK | **chosen instead**: our own `PlayerData` (one key, UpdateAsync, session lock, schema migrations at v16, tested in C10, purchase saves durable since D8) does the same job | Kept ours on 2026-10-07 when Ethan asked to adopt every adopt decision: a swap rewrites every save path and migrates every player's data for no feature gain; revisit only if ours shows a save bug |
| Graphify, Ponytail, Roblox Claude Skills, Agent Skills, OmniRoute and others | TikTok ZPL8Hb7yS, add-on list | Skip, with reasons in [[Claude-Plugins]] | **skip** | None |
| Headroom, caveman, context-mode, beads, basic-memory, Task Observer and others | Token survey | Later | **later** | Revisit when a need shows |

| ffmpeg, yt-dlp, Whisper (sherpa-onnx) | Reference video processing | Adopt | **in use** (ffmpeg and yt-dlp on the Mac; Whisper needs `SHERPA_WHISPER_DIR` set on the Mac, the cloud session downloads its own model) | Fine as is |
| Codex CLI on PATH | Mac audit | | the CLI lives inside ChatGPT.app, not on PATH | Optional: the Mac calls it by its full path |
| Discord community server | Growth references | Later (launch assets) | Discord installed; no server | Part of store presence (Look plan L6) |
| "raw alone" for UI making and animation | Ethan, 2026-10-05 ([[Requests]]) | **dropped** by Ethan on 2026-10-07 | none | None |

## Roblox Studio plugins (TikTok ZPLRKPFKv, "what pro devs actually use")

| Plugin | Used for | State | Next step |
|---|---|---|---|
| Rojo | code sync | **in use** | Done |
| GapFill & Extrude, ResizeAlign, Redupe (Stravant) | ship seams, snapping, repeated rows | **not installed** (Mac audit: only Rojo's plugin present) | Prices pending the Mac's Studio screenshot; free ones installed through the Mac, paid ones need Ethan's yes (Robux) |
| Brushtool 2 | scattering biome props | **not installed** | Same; needed for the Moonlit Forest dressing (milestone 48) |
| Archimedes v3 | round pads, arches | **not installed** | Same |

## Asset tools (TikToks ZPLRw3ubt, ZPL8MNKUy, ZPL8uaNaS)

| Tool | Used for | State | Next step |
|---|---|---|---|
| Blender (through MCP) | species, props, icons, sprites | **installed, not connected now** (Blender 5.2.2; the add-on handshake fails while Blender is closed) | When the next model pass starts: open Blender and Start MCP Server; if the add-on is outdated, `uvx mcp-for-blender install-addon` |
| Claude Design | rigged, animated models with VFX | **chosen instead**: Blender MCP for models; animation not started | Revisit for species animation; check what Ethan's plan includes |
| Meshy, 3D AI Studio, Tripo | generated meshes with polygon control | **chosen instead**: Blender MCP; no accounts or keys (Mac audit) | The Mac ranks Meshy or 3D AI Studio sixth for real models; paid accounts are Ethan's call |
| Nano Banana, Higgsfield | image and video generation (reference batch 3 list) | candidates only; no accounts | Option for icons v2 and trailer shots; Ethan's call |
| Lemonade.gg, Ropilot Astra | AI game-dev services seen in references | reference only | None |
| Gemini or another image model | icon sets and reference sheets | **not used** | Part of the icons v2 plan Ethan asked for: the image-model route is one of the options, needs an account |
| Studio MCP `generate_mesh`, `generate_material` | quick placeholders | available, little used | Use for placeholders in milestone 48 |

## The rule from now on

1. A tool mentioned by Ethan or a reference gets a row here the same day, with a decision.
2. "Adopt" is not done until the row says **in use** and someone verified it on the Mac.
3. Installs that change a Claude session's own setup (plugins, permission rules) are run by Ethan; everything else goes to the Mac session with Ethan's approval in its window.
4. The coordinator reviews this page at the start of each working block and chases every **decided, not installed** row.
