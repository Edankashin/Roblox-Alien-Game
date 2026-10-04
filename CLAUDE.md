# Roblox Alien Game

A Roblox collection game for a two-person team: players crash-land on planets, catch cute aliens with a timing-bar minigame, the aliens build a ship, and the ship flies to the next themed world. Design in `docs/GAME_DESIGN.md`. Build plan and readiness checklist in `docs/PRE_PRODUCTION.md`. Research behind the design in `reports/` and `research_notes/`. Reference-video lessons in `media/tiktok/NOTES.md`. The knowledge vault (glossary, UI playbook, engine notes, art pipeline) lives in `docs/vault/` once created; read it before UI or asset work and write corrections back into it.

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

## How to run

- `rojo serve` in the repo, connect the Rojo plugin in Studio, press Play.
- Studio MCP for live instance edits: enable Studio as MCP server in the AI Assistant settings and connect the client.
- Test multiplayer with Studio's multi-client test. Check every screen in the device emulator at iPhone SE and iPad sizes.

## Working with the team

- Commit on the working branch; never commit audio or raw frame dumps from `media/tiktok/out/`.
- When a review corrects the look of something, update the UI Playbook in the same change.
