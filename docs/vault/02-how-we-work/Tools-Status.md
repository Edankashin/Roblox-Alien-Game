---
tags: [how-we-work, tooling, tracker]
aliases: [Tools status]
up: "[[How-We-Work]]"
---
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
| ccusage | Token survey 2026-10-05 | Adopt now | **in use**: `npx -y ccusage daily` and `session` ran on the Mac 2026-10-14 (overnight job 12), no install | Mac: `npx ccusage` once a week into the log |
| rtk | Token survey | Adopt now as a trial | **decided, not installed** | Ethan's yes for a `brew install` on the Mac |
| ccstatusline | Token survey | Adopt now | **decided, not installed** | Optional; Ethan's call |
| StyLua | Token survey (Roblox tools) | Adopt now | **decided, not added** (not on the Mac either; nor selene, lune) | Coordinator: add to `rokit.toml` with a config matching today's style, as an advisory check first so no mass reformat collides with Codex |
| ProfileStore | Token survey (Roblox tools) | Adopt now, pending the team's OK | **chosen instead**: our own `PlayerData` (one key, UpdateAsync, session lock, schema migrations at v16, tested in C10, purchase saves durable since D8) does the same job | Kept ours on 2026-10-07 when Ethan asked to adopt every adopt decision: a swap rewrites every save path and migrates every player's data for no feature gain; revisit only if ours shows a save bug |
| Graphify, Ponytail, Roblox Claude Skills, Agent Skills, OmniRoute and others | TikTok ZPL8Hb7yS, add-on list | Skip, with reasons in [[Claude-Plugins]] | **skip** | None |
| Headroom, caveman, context-mode, beads, basic-memory, Task Observer and others | Token survey | Later | **later** | Revisit when a need shows |
| yt-dlp (on the Mac) | Ethan's TikTok links, the reference batches | Adopt | **in use** (Mac; saves the reference videos into `media/tiktok/`, `/opt/anaconda3/bin/yt-dlp`, run again for batch 6 on 2026-10-14 (overnight job 17); it refuses `/photo/` posts, so a slideshow is read from the post page's embedded data; `tools/watch_video.py` then makes the sheets and transcript) | Done |
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
| Claude Design | rigged, animated models with VFX (the standalone app's 3D mode) | **chosen instead** for models and animation: Blender MCP for models; **superseded 2026-10-15 for mockups and comps** by the Claude Design row under "Added from the design research" (in use, never for meshes); animation not started | Revisit for species animation after launch: batch 6 (ZPLS5oQoQ, ZPLSah2VR, 2026-10-14) shows 63 animals animated in three or four batched prompts, with the viewer's animation absent from the exported GLB (so animation has to be rebuilt in Studio or Blender anyway) |
| Meshy, 3D AI Studio, Tripo | generated meshes with polygon control | **chosen instead**: Blender MCP; no accounts or keys (Mac audit); Tripo P1 is a hero-species trial since 2026-10-15, see the Tripo row under "Added from the design research" | The Mac ranks Meshy or 3D AI Studio sixth for real models; paid accounts are Ethan's call |
| Nano Banana, Higgsfield | image and video generation (reference batch 3 list) | candidates only; no accounts | Option for icons v2 and trailer shots; Ethan's call |
| Lemonade.gg, Ropilot Astra | AI game-dev services seen in references | reference only | None |
| Gemini or another image model | icon sets and reference sheets | **not used** | Part of the icons v2 plan Ethan asked for: the image-model route is one of the options, needs an account |
| Studio MCP `generate_mesh`, `generate_material` | quick placeholders | available, little used | Use for placeholders in milestone 48 |
| Blender as the `bpy` Python module (headless, in the cloud session) | the 32 species bodies, preview sheets and store renders without the Mac or Blender open (`tools/blender/species_bodies.py`, `preview.py`, `store_renders.py`) | **in use** (`bpy` 5.0.1; the proof run of 2026-10-14 and all 32 bodies rebuilt with surfaces on 2026-10-15, while the Mac slept) | Done; the Mac's Blender and its MCP stay for looking at a result live |
| Blender MCP `generate_3d` (Tripo, Hunyuan3D, Hyper3D Rodin) | one textured mesh from text or an image, for a few hero species ([[Character-Pipeline]] section 2.2) | **decided, not installed**; needs Ethan's yes on credits | Ethan decides after the vendor prices are checked (Character-Pipeline section 4); Hunyuan3D's licence excludes the EU and UK; TRELLIS and local Hunyuan3D do not run on the 8 GB Mac |
| QuadriFlow and voxel remesh (Blender's own `quadriflow_remesh` and Remesh modifier) | the fuse pass: one skin per species at about 2,000 triangles ([[Character-Pipeline]] section 2.3) | **in use** (the sculpt prototype, 2026-10-15: metaballs chosen, the remesh kept as the hard-surface fallback; see [[Sculpt-Pass]]) | **in use** once the prototype's result is accepted and a species passes the three ship checks |
| Pillow (Python imaging library) | thumbnails, preview sheets and the group emblem (`tools/store_compose.py`, `store_title.py`, `names_sheet.py`, `group_emblem.py`); also re-saves the vault's embedded sheets under 400 KB | **in use** (cloud session) | Done |

## Added from the design research (2026-10-15)

From the [report](../../../reports/Roblox%20creature%20UI%20and%20Claude%20workflows.md) and Ethan's call to use Claude Design and connect Obsidian ([[Decisions]] B30, B33). Same columns as the first table. Setup steps for the Obsidian rows are in [[Setup-and-Tips]]; Ethan installs, the Mac verifies.

| Tool | Where it came from | Decision | State | Next step and owner |
|---|---|---|---|---|
| Claude Design (the in-chat canvas) | Ethan's request 2026-10-15; the creators' videos (batch 6) used the standalone app | Adopt as the review surface for mockups at 844x390 and 1080x810, species sheets on Blender turnarounds, thumbnail comps and a hatch-timing prototype; never meshes, shipped UI, raster icons or animation ([[Claude-Design-Brief]]) | **in use** for mockups and comps (the canvas exists: [Catch an Alien UI](https://claude.ai/artifact/GsddVfW4nSoBSRpEpCSvi4)); `/design` from the Mac session is unverified | Ethan picks boards. The standalone app closes 2026-12-14 with no project migration: start nothing there, export PNGs into the repo. Mac: confirm `claude --version` is v2.1.265 or later and `/design` appears |
| mcp-for-blender | the project's new name (was `blender-mcp`; `.mcp.json` already runs `uvx mcp-for-blender`); the "Blender MCP" row above is the same tool | Adopt, to look and not to build: `look` with `angles` for turnarounds, `get_scene_info`; builds stay headless `bpy` | **in use** on the Mac | None. `generate_3d` can cost credits: not without Ethan's yes. The socket has no authentication: save the file before code runs |
| Tripo (P1 low-poly plus `retopologize`) | the report; the Blender research worker's note | A trial for hero species only: one species prompt through Tripo P1, Meshy and Rodin, judged on the three ship checks ([[Character-Pipeline]]) | **decided, not installed**; costs credits (about 10 to 15 USD for the trial; 40 credits observed for a P1 low-poly text-to-3D) | Ethan's yes on credits, then a worker runs it through Tripo's own API (in the Blender MCP add-on Tripo is Premium-only). Read the current terms before shipping anything from a free tier |
| Obsidian Local REST API plugin plus an MCP server (`mcp-obsidian`) | the report; Ethan's request to connect Obsidian directly | Adopt for heading-targeted edits and search by frontmatter in the open vault; Mac only, Obsidian must be open | **decided, not installed** (Mac 2026-10-15: no community plugins in the vault, no `.obsidian/plugins`) | Ethan: the steps in [[Setup-and-Tips]] "Obsidian connected to Claude". Mac: verify (reads only), then set this row to in use |
| Obsidian CLI | the report (shipped in Obsidian v1.12, February 2026); the Obsidian row above says "its command line is off" | Adopt for `search`, `backlinks`, `daily:append`, `property:set`; talks to the running app over IPC | **decided, not enabled** (Mac 2026-10-15: Obsidian 1.14.4 running, `obsidian` on the PATH via Homebrew, but it answers "Command line interface is not enabled") | Ethan: Settings, General, turn on the command line interface. Mac: verify |
| kepano/obsidian-skills | the report (the Obsidian CEO's skill pack, 49.6k stars, wraps the CLI) | Adopt after the CLI is on | **decided, not installed** | Ethan types the install himself in his Claude Code (a session does not install into itself); the line is in the repo's README |
| Roblox StyleSheets (CSS-like styles with tokens, themes, state selectors; client beta since 2026-01-20) | the report | Noted, not adopted: `Theme.luau` and `Builder` stay the token source; only one StyleSheet binds to a tree | **later** | Revisit if a rebuild wants declared hover, press and selected states |

Two Studio plugins the report names for lighting work, optional and not installed (the other plugins are in the table above): Elttob's Atmos skybox browser, and a Lighting Preset Manager that snapshots the whole Lighting stack, which is faster for auditioning a grade than editing `Lighting.luau` blind ([[Decisions]] B31).

## Added from the model toolchain decision (2026-10-15)

Ethan: "Incorporate Blockbench, Blender and Substance Painter to create these character models." The research, the chain, the file formats and the probe are in [[Model-Toolchain]]. Same columns as the first table.

| Tool | Where it came from | Decision | State | Next step and owner |
|---|---|---|---|---|
| Blockbench 5.2.2 (free, GPL v3) | Ethan's decision 2026-10-15 | Adopt as the desk where a person hand-paints the species texture and keyframes idle, walk and hatch on a group or armature rig; the cloud writes the `.bbmodel` it opens; glTF out to Studio ([[Model-Toolchain]] sections 1 to 3) | **decided, not installed** (Mac 2026-10-15: not in /Applications, ~/Applications, Spotlight or Homebrew; no account, no money; the app from `blockbench.net`, or the browser build at `web.blockbench.net`) | Ethan: download the macOS build. Mac: the glTF animation probe in [[Model-Toolchain]] section 6, then this row to in use |
| Substance 3D Painter | Ethan's decision 2026-10-15 | Adopt only for the PBR coat on hero species, after a trial: one texture set per slot, our export preset, maps into `assets/textures/` ([[Model-Toolchain]] section 3.2) | **needs Ethan's decision on the licence** (Mac 2026-10-15: not installed, no Steam, no Adobe Creative Cloud; only Adobe Digital Editions is on the Mac): Steam perpetual about $200 (no Assets library), Adobe Collection about $60 a month, or the free student licence (non-commercial, so a trial licence only); the 8 GB Mac is below the published 16 GB minimum (prices and requirements are snippets) | Ethan: pick the licence, or say no; the 30-day trial first, on the Mac with Studio closed, to see whether it runs at all. Cloud: the preset and `tools/painter/export_species.py`, written blind. Mac: run it once inside Painter |
| Blender glTF export with skins and animations (`bpy.ops.export_scene.gltf`, `export_animations`, `export_skins`, 4 influences) | the toolchain research | Adopt as the rig route when a species is rigged in Blender rather than Blockbench; headless, so the same `bpy` scripts drive it | **to verify** (the exporter is in use for the 32 meshes; no rig or animation has been exported from it yet) | Mac: the second half of the probe in [[Model-Toolchain]] section 6 (a Blender-rigged cube with one action into Studio), then in use |
| `tools/blockbench/to_bbmodel.py` (the cloud bbmodel writer) | the toolchain research, [[Model-Toolchain]] section 6 | Adopt: turns a species folder (GLB plus `materials.json`) into a Blockbench Generic Model project with a mesh and a group per slot, a flat palette texture (or a baked `<Id>_palette.png` from `tools/blender/unwrap_bake.py` next to the GLB, [[Surface-Pass]]) and an example `idle`; no Blender, standard library plus Pillow ([[Model-Toolchain]] "The writer") | **built, not yet verified in Blockbench** (unit tests and `--check` pass in the cloud; all 35 species build; the first two files are `media/blockbench/Sparkfox.bbmodel` and `Mossbop.bbmodel`) | Mac: open `media/blockbench/Sparkfox.bbmodel` in Blockbench, screenshot, report what fails (the checklist is in [[Model-Toolchain]] "The writer"); then this row to in use |

## Added from TikTok batches 7 and 8 (2026-10-15)

Nine references were read (`media/tiktok/NOTES.md`). The three tools Ethan named for batch 8 (Blockbench, Blender, Substance Painter) already have rows above; none of the six videos shows or names Blockbench or Substance Painter, so no row changes state ([[Model-Toolchain]] section 5, "From the owner's references (batch 8)"). Claude Design, Obsidian and the Studio MCP also have rows above. The one tool named in these nine that had no row:

| Tool | Where it came from | Decision | State | Next step and owner |
|---|---|---|---|---|
| Free API tiers: NVIDIA NIM (40 requests a minute), Baseten, OpenRouter (50 requests a day), and an unnamed "secret" GitHub repo of copy-paste config snippets for Claude Code and Cursor | TikTok ZPLSQBRMa (milesreevesai), batch 7; not part of Ethan's UI or toolchain asks | Not adopted: the limits are far below a coding session, routing Claude Code through another provider is a tool-stack choice for Ethan, and the repo cannot be vetted because the video never names it | none | None unless Ethan asks; keep provider keys in the shell environment only ([[Handoff]] "Secrets") |

## The rule from now on

1. A tool mentioned by Ethan or a reference gets a row here the same day, with a decision.
2. "Adopt" is not done until the row says **in use** and someone verified it on the Mac.
3. Installs that change a Claude session's own setup (plugins, permission rules) are run by Ethan; everything else goes to the Mac session with Ethan's approval in its window.
4. The coordinator reviews this page at the start of each working block and chases every **decided, not installed** row.
