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
| B12 | Special weather per world | Each world rolls one special weather at its own chance with one signature alien that spawns only then (World 1: Rain, Thunderhog); a banner announces it. All data in `Worlds.luau` | 2026-10-05 |
| B13 | World 2 roster | Frostbyte's 16 species, modules, key materials and Field Notes are data only (see "World 2 roster" below); its regions, Heater tool and shrine arrive with the layout | 2026-10-05 |

## World 2 roster (2026-10-05)

Frostbyte's content data, authored in the World 1 voice: 16 species (5 Common, 4 Uncommon, 3 Rare, 2 Epic, 1 Legendary, 1 Cosmic), five modules, five key materials and a five-step Field Notes chain. Data only; no service or client code changed. The biome regions, the Heater tool (place it to reveal aliens hidden by a Blizzard for 60 s) and the Shrine of Skaddle arrive with the Frostbyte layout.

| Species | Tier | Jobs | Biome | Condition | The one goofy thing |
|---|---|---|---|---|---|
| Flufflet | Common | Gather 1 | Snowfield | Any | Its knitted scarf is longer than it is |
| Snowbun | Common | Build 1 | Snowfield | Any | Snowball tail that keeps growing as it hops |
| Pengoo | Uncommon | Gather 2 | Snowfield | Day | Belly-slides everywhere, even uphill |
| Reindazzle | Rare | Spark 3 | Snowfield | Any | Icicle antlers; its nose blinks |
| Drippo | Common | Gather 1 | Ice Cave | Any | An icicle drop that drips when nervous |
| Chipmole | Common | Build 1 | Ice Cave | Any | Ice-pick claws; chips the floor wherever it stands |
| Flapsicle | Uncommon | Spark 2 | Ice Cave | Night | Icicle wings; hangs upside down from nothing |
| Shellberg | Rare | Gather 3 | Ice Cave | Any | Iceberg shell, nine-tenths of it hidden |
| Shimmerlynx | Epic | Gather 3, Spark 4 | Ice Cave | Night | Aurora crest; purrs in colours |
| Kettlepuff | Common | Spark 1 | Geyser Field | Any | A kettle that whistles when excited |
| Toastoad | Uncommon | Gather 2 | Geyser Field | Any | Soaks in the hot spring till it wrinkles |
| Emberchin | Uncommon | Spark 2 | Geyser Field | Any | Ember-quilled urchin that hops between pools |
| Capybubble | Rare | Build 3 | Geyser Field | Any | Tangerine hat; snores bubbles |
| Frostfang | Epic (Blizzard signature) | Build 4, Spark 3 | Snowfield | Blizzard | Sabre-tooth cub with icicle fangs that sneezes snowflakes; rideable |
| Skaddle | Legendary (Warden) | all 5 | Snowfield | Quest | Snow owl on tiny skis; echo of Skadi, Norse winter; rideable |
| Fenripup | Cosmic (Star-born) | all 5 | Snowfield | Shower | A puppy with a glowing moon on its forehead; echo of Fenrir; rideable |

- Modules (Scrap 1.6x World 1, assembly 1.5x): Heat Shield (Ice Plate x3) -> Ice Drill (Geyser Pearl x3, 2 slots) -> Cryo Pod (Frost Core x3) -> Beacon Array (Blizzard Shard x2, 3 slots) -> Frost Engine (Skaddle's Core).
- Key materials: Ice Plate (Snowfield, any), Geyser Pearl (Geyser Field, any, glows), Frost Core (Ice Cave, night, glows), Blizzard Shard (Snowfield, Blizzard, glows), Skaddle's Core (finale only). Frost Cores also feed World 3's Nav Array through the Outpost.
- Field Notes W2S1..W2S5: catch 8; a night catch plus a Frost Core; craft a Glow Lure plus a Rare; the Epic in a Blizzard (pays the shared Warden's Horn); sound the horn at night for Skaddle. No gear rewards because Radar2 is not buyable yet; Scrap, lures and spins instead.
- Frostfang is the only Blizzard species, per the one-signature-alien rule. Fenripup rolls in all three biomes during a Meteor Shower, like Ra-dish.
