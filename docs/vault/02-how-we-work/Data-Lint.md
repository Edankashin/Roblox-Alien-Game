# Data lint

Run `python3 tools/lint_data.py` from any directory. Python 3 and its standard library are the only dependencies. Exit 0 means clean; exit 1 prints one diagnostic per failing reference/check followed by the failure count. CI runs this automatically. `--root /path/to/checkout` supports validation against a separate fixture tree.

## Checks and sources

| Check | Files read under `src/shared/` |
| --- | --- |
| Spawn species exist; spawn biome keys belong to the Biome union | `data/Spawns.luau`, `data/Species.luau`, `types/Types.luau` |
| Material references exist, including node waypoints and nested node rows | `data/Modules.luau`, `data/Quests.luau`, `data/Tutorial.luau`, `data/Layouts.luau` and its required `Meadow.luau`/`Frostbyte.luau`, `data/KeyMaterials.luau` |
| Every species world exists; every built world's warden and special-weather species exist (a row with `built = false` is only designed: its species are placeholders and are skipped until it is built) | `data/Species.luau`, `data/Worlds.luau` |
| Non-negative, finite odds sum to 100 (absolute tolerance 1e-9) | `data/Sizes.luau` Bands; `data/Spins.luau` Segments |
| Explicit string references resolve | Every `data/*.luau` table, `strings/en.luau` |
| Icons and particles match PNG basenames in either asset directory | `data/Icons.luau`, `assets/icons/**/*.png`, `assets/particles/**/*.png` |
| Species/world catch variants exist | `data/Species.luau`, `data/Worlds.luau`, `data/CatchVariants.luau` Rows |
| Growth thresholds are finite numbers and strictly ascending in row order | `data/Growth.luau` Stages |
| Every tier aura is a finite number (booleans do not count) | `data/Tiers.luau` Tiers |

String checks cover non-nil values of `hint`, `labelKey`, `hintKey`, `nameKey`, `holdHintKey`, plus string literals beginning with `REWARD_`, `MATERIAL_`, `SPECIES_`, `STATION_`, `JOB_`, `TIER_`, `SIZE_`, `STAGE_`, `MENU_`, or `COMPASS_`. This checks references present in data, not keys dynamically assembled by game logic. Plain display names are not interpreted as string keys.

Every Icons-table key requires a PNG even when its upload ID is zero. A Particles-table key with ID zero may have no PNG: Confetti, Ember, Glow, Ring, Shine, Sparkle and Star are planned sprites. Nonzero particle IDs require PNGs. Every PNG must have an Icons or Particles key; Aliases do not count as image definitions.

Current layouts supply node placement settings and derive material populations from KeyMaterials; they have no explicit material-node rows. The recursive check also covers future nested `material`, `materialId`, `keyMaterial`, and material reward `id` references in those layouts.

## Parser contract

`load_table(path)` is reusable by balance tooling. Luau arrays become ordered Python dictionaries keyed from 1; keyed tables remain dictionaries. The reader accepts comments, quoted strings, numbers, booleans, nil, nested tables, bracketed keys, local aliases, sibling `require(script.Parent...)` references, arithmetic `+ - * / %`, table type casts, and literal `Vector3.new` triples (retained as tuples, never executed). It reconstructs the existing `ById` indexing-loop idiom from each list's `id` fields. The type-only Types module supplies no runtime data.

This is a reader for the repository's literal data shape, not a general Luau interpreter. Unsupported expressions fail with a file diagnostic. It does not execute arbitrary statements or Roblox APIs. Keep executable computation out of data tables or explicitly extend the parser when introducing a new shape.

## Initial result (2026-10-06)

10 failures at first: Worlds 3–7 each reference an absent warden and special-weather species. Placeholder worlds were checked too; `placeId = 0` is not an exemption. Resolved by the coordinator with a `built` flag on every Worlds row (true for 1 and 2): a designed-only world's species references are skipped, so the lint is green and starts failing the moment a world is marked built without its species. The full identifiers are recorded in Codex-Reports.md. Eighteen isolated mutation checks passed, including zero-ID particle acceptance, required icon PNGs, orphan PNGs, bad references, odds, growth and aura. Temporary fixture edits did not touch game data.

## C6 data shapes

Run `python3 -I tools/lint_data.py`; `--help` describes the entry point. The same standard-library TableReader remains in `tools/lint_data.py` (there is no separate `luau_tables.py` in this checkout).

| Rule | Inputs |
| --- | --- |
| Numeric-row tables reject string keys; the documented `Radar.Mk2` exception is explicit | Radar, Layouts, Worlds |
| Every Order/Rotation is dense, contains no nil, and resolves to its declared row owner; unknown families fail | All data tables; Settings inline keys are unique; Weekly resolves species |
| Species ride belongs to the Traversal union and has a traversal row | Species, Types, Mounts |
| Every mount seat override names a species | Mounts.SeatStuds, Species |
| Habitat world is built and capacity is positive | HomeBuild, Worlds |
| Every footprint fits the plot; every item kind has a cap | HomeBuild, Home |
| Rotation/override species exist; limited drops never occur in ordinary spawns | Weekly, Species, Spawns |
| Season timestamps are finite, ordered and non-overlapping | Seasons |
| Event species exist and are absent from ordinary spawns; returning species exist | Seasons, Species, Spawns |
| Seasonal overlays exist and track quest ids are unique | Seasons, Overlays |
| Seasonal reward kinds, positive amounts and alien/lure/power-up ids are valid | Seasons, Species, Lures, PowerUps |
| Shop item ids are unique; Launch references exist | Shop |
| Every launch item has grants or the explicit live-pass allowance CompanionSlot4 | Shop |
| Grants cannot sell named NeverSold entries, Legendary/event/track aliens or explicit rideable aliens | Shop, Species, Seasons |
| Setting levelKeys are dense, match levels in length and exist in strings | Settings, strings/en |
| Setting defaults are integer indices in range | Settings |
| Promo code reward kinds, amounts and ids are valid | Codes, Lures, PowerUps |

Found: **none** on the current tree. The exact-finding warning baseline is empty; any new finding fails. No data values were changed. **31 isolated in-memory mutations** each produced diagnostics, covering holes/nil, unknown references, dimensions/caps, windows, duplicate ids, prohibited grants, reward shapes and settings. Lint runtime was below one second on the Mac.
