# Decisions log

Record each team decision from PRE_PRODUCTION section 2 here with the date, so a future session never re-asks.

| # | Decision | Choice | Date |
|---|---|---|---|
| 1 | Game name | Undecided; code uses working title "AlienGame" until chosen | 2026-10-04 |
| 2 | Art style | Smooth low-poly, the style of the top sims (Adopt Me, Grow a Garden, Steal an Egg) | 2026-10-04 |
| 3 | Jobs at launch | 3 jobs: Gather, Build, Spark. Camp art cozy, not industrial | 2026-10-04 |
| 4 | Companions | Yes, 3 slots | 2026-10-04 |
| 5 | Splicing | None. No breeding or lab; Secrets come from codex Sets | 2026-10-04 |
| 6 | Theft or borrow | Borrow only. Raid mode parked for a later decision | 2026-10-04 |
| 7 | World order | Verdant, Frostbyte, Neon Grid | 2026-10-04 |
| 8 | Event rerun policy | Vault Rotation in every monthly event plus annual full reopening | 2026-10-04 |
| 9 | Permanent luck pass | Not at launch | 2026-10-04 |
| 10 | Mounts use a companion slot | Yes | 2026-10-04 |
| 11 | Scrap for Robux | Never. Play it safe; maximise player count | 2026-10-04 |
| 12 | Pantheon scope | Most famous figures only; codex organised into themed Sets (Greek, Norse, Egyptian, Myth Beasts) | 2026-10-04 |
| 13 | UI font | Fredoka One, replicating the top games | 2026-10-04 |
| 14 | UI palette and dialect | Stud dialect modelled on Steal an Egg; hex values in UI-Playbook.md | 2026-10-04 |
| 15 | Icon pack | Placeholder icons until chosen; references in 05-ui-design/refs | 2026-10-04 |
| 16 | Group ownership | Roblox group co-owned by Ethan and collaborator | 2026-10-04 |

## Build decisions (code, not product)

| # | Decision | Choice | Date |
|---|---|---|---|
| B1 | Camp rendering | Each player's stations, workers and ship are rendered on their own client at the shared camp pad (`Workspace.ClientCamp`). The server owns the state; nothing of the camp replicates. Plots per player come later with the home planet | 2026-10-04 |
| B2 | Module order | Modules build strictly in order; only the first incomplete module accepts Scrap and parts | 2026-10-04 |
| B3 | Assembly speed | `Config.AssemblyPlayerSpeed` (1x, the player's own crew) plus the summed work speed of the aliens at the module's job station. Assembly extrapolates by wall clock from `ModuleProgress.updatedAt`, so it continues offline with no extra code | 2026-10-04 |
| B4 | Offline income | `OfflineRate` (50%) of the live rate, counting at most `OfflineCapSeconds`; shown once on join as a toast when the absence is at least `OfflineMinSeconds` | 2026-10-04 |
| B5 | Key materials | Shared per-server nodes, first come first served, respawn per `KeyMaterials` row; collected into the player's inventory and moved into the module from the Ship screen | 2026-10-04 |
| B6 | Biomes as regions | World 1's Forest and Cave are circular regions on the one Meadow floor (`data/Meadow.luau` Regions), not separate places; `Shared/Biomes.At` decides the biome of any point for spawns, nodes and the HUD chip | 2026-10-05 |
| B7 | Condition-gated nodes | A node whose material needs Night or Rain stays visible but dim with "Only at night" on its plate while the condition is not met; a collected node vanishes until it respawns | 2026-10-05 |
| B8 | Catch announcements | Catches of `Config.AnnounceMinTier` (Rare) and above post a server-wide banner naming player, rarity and species; lower tiers stay private | 2026-10-05 |
| B9 | Studio chat commands | `/scrap N`, `/night`, `/day`, `/rain`, `/clear` exist only when `RunService:IsStudio()`; the Dev service never runs live | 2026-10-05 |
| B10 | Slot growth | Thrusters completion raises every station to 2 slots, Nav Array to 3 (`Modules.unlocksSlots`), per decision 16's proposal, pending the team's confirmation | 2026-10-05 |
| B11 | Blender via MCP | Models are built and edited in Blender through the `mcp-for-blender` server registered in `.mcp.json`; exports go to `assets/models/` and into Studio through Import 3D. Save before any code-executing session | 2026-10-05 |
