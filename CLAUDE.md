# Roblox Alien Game

A Roblox collection game for a two-person team: players crash-land on planets, catch cute aliens with a timing-bar minigame, the aliens build a ship, and the ship flies to the next themed world. New here (a person or a session)? Start with `docs/vault/00-start-here/Handoff.md`, then the shared to-do list `docs/vault/00-start-here/Board.md` (claim a row before working on it). Design in `docs/GAME_DESIGN.md`. Build plan and readiness checklist in `docs/PRE_PRODUCTION.md`. Research behind the design in `reports/` and `research_notes/`. Reference-video lessons in `media/tiktok/NOTES.md`. The knowledge vault (glossary, UI playbook, engine notes, art pipeline) lives in `docs/vault/`, which is also the team's Obsidian vault; read it before UI or asset work and write corrections back into it.

## Vault logging

- Every session (coordinator, the Mac session, workers) logs what it learned or settled in `docs/vault/08-log/YYYY-MM-DD.md`: one dated note per day, a heading per session, short bullets (what was done, what was found, what was decided, what is left). Append; never rewrite another session's lines.
- Anything lasting moves out of the log into its topic note (engine fact to 04, UI lesson to 05, decision to `07-alien-game/Decisions.md`) and the log line links it with `[[Note-Name]]`.
- Use Obsidian-style links (`[[Note-Name]]`) between notes so the graph stays connected. Never put keys, tokens or other secrets in the vault.

## Rules

- Luau in strict mode. Shared types in `src/shared/types`.
- Server authority for everything that touches Scrap, catches, spawns, timers, purchases and saves. The client renders and animates; it never decides outcomes.
- One currency, Scrap. It is never sold for Robux. No second premium currency.
- Every number (costs, odds, timers, spawn weights, prices) lives in a data table under `src/shared/data`, never in logic.
- Every player-facing string lives in `src/shared/strings`, keyed, for translation.
- UI: Scale, never Offset, for Position and Size. Build UI in code from the theme module. Follow the UI Playbook in `docs/vault/05-ui-design/UI-Playbook.md`. Fredoka One, outlined text over the world, chunky outlined buttons, standard rarity colours. No glassmorphism, no web fonts, no silent taps.
- Aliens are lightweight server records rendered on the client. No server-side Humanoids for creatures.
- Saves: one key per player, `UpdateAsync`, session locking, schema version with migrations.
- Paid random items show per-item odds summing to 100%, have no dud outcome, and are hidden where `PolicyService.ArePaidRandomItemsRestricted` is true.
- One system per change. Name the instance path. Say where each script goes and why.

## Project structure (Rojo)

- `default.project.json` maps the tree into Studio.
- `src/server/` ServerScriptService: services (spawning, catching, stations, modules, offline, saves, events, shop, quests, spins, peddler).
- `src/client/` StarterPlayerScripts: HUD, screens, capture bar, radar, camera, tweens, sounds.
- `src/shared/` ReplicatedStorage: data tables, strings, types, theme module, net wrapper.
- `docs/` design, plan, vault. `tools/` scripts. `media/` reference material.

## Before committing code

- `./tools/analyze.sh` must print `analyze: clean` (strict Luau analysis with Roblox definitions through the Rojo sourcemap).

## How to run

- `rojo serve` in the repo, connect the Rojo plugin in Studio, press Play.
- Studio MCP for live instance edits: enable Studio as MCP server in the AI Assistant settings and connect the client.
- Test multiplayer with Studio's multi-client test. Check every screen in the device emulator at iPhone SE and iPad sizes.

## Token economy

- Build workers run on Sonnet with a complete brief; the coordinator plans, reviews and wires. Workers read their files in one or two commands, write whole files, and report in under 300 words. Rules and tools in `docs/vault/02-how-we-work/Token-Economy.md`.

## Working with the team

- Commit on the working branch; never commit audio or raw frame dumps from `media/tiktok/out/`.
- When a review corrects the look of something, update the UI Playbook in the same change.
- Every tool mentioned by Ethan or a reference gets a row in `docs/vault/02-how-we-work/Tools-Status.md` the same day; a decision is not done until its row says **in use**, verified on the Mac. Chase every "decided, not installed" row at the start of a working block.
