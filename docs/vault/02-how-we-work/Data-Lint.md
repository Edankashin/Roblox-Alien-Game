# Data lint

Run `python3 tools/lint_data.py` from any directory. Python 3 and its standard library are the only dependencies. Exit 0 means clean; exit 1 prints one diagnostic per failing reference/check followed by the failure count. CI runs this automatically. `--root /path/to/checkout` supports validation against a separate fixture tree.

## Checks and sources

| Check | Files read under `src/shared/` |
| --- | --- |
| Spawn species exist; spawn biome keys belong to the Biome union | `data/Spawns.luau`, `data/Species.luau`, `types/Types.luau` |
| Material references exist, including node waypoints and nested node rows | `data/Modules.luau`, `data/Quests.luau`, `data/Tutorial.luau`, `data/Layouts.luau` and its required `Meadow.luau`/`Frostbyte.luau`, `data/KeyMaterials.luau` |
| Every species world exists; every world's warden and special-weather species exist | `data/Species.luau`, `data/Worlds.luau` |
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

10 failures: Worlds 3–7 each reference an absent warden and special-weather species. Placeholder worlds are checked too; `placeId = 0` is not an exemption. No data was changed. The full identifiers are recorded in Codex-Reports.md. Eighteen isolated mutation checks passed, including zero-ID particle acceptance, required icon PNGs, orphan PNGs, bad references, odds, growth and aura. Temporary fixture edits did not touch game data.
