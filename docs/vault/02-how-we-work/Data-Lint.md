---
tags: [how-we-work, tooling, lint]
aliases: [Data lint, Vault lint]
up: "[[How-We-Work]]"
---
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
| **No asset id is used under two asset types** (2026-10-26): every real id (not 0) in Sounds and Music (sound), Icons, BlockTiles, Textures and the Lighting sky (image), ModelAssets.AssetIds (model) and the uploader's four `asset_ids.json` files (an image upload's `assetId` is a Decal and its `imageId` the Image; models are models) must have one type. Engine message when it breaks: `ContentId: rbxassetid://N failed due to: Asset type does not match requested type`. `tools/tests/test_lint_asset_ids.py` mutates a pasted id into each wrong table. | Sounds, Music, Icons, BlockTiles, Textures, Lighting, ModelAssets |
| **Streaming matches its project files** (2026-10-26): `data/Streaming` `MinRadius` is at least `Config.SpawnRadius`, `TargetRadius` is not under it and not past World 1/2's farthest corner from the camp, `Enabled` has a row per built world, `default.project.json`, `world2.project.json` and `home.project.json` carry the same `StreamingEnabled`, `StreamingMinRadius`, `StreamingTargetRadius` and `StreamingIntegrityMode` as the table says for their `WorldId`, and the five server services that make the Persistent containers call `WorldContainer.Get`. `tools/tests/test_lint_streaming.py`. | Streaming, Config, Worlds, WorldGen1, WorldGen2, the project files |

Found: **none** on the current tree. The exact-finding warning baseline is empty; any new finding fails. No data values were changed. **31 isolated in-memory mutations** each produced diagnostics, covering holes/nil, unknown references, dimensions/caps, windows, duplicate ids, prohibited grants, reward shapes and settings. Lint runtime was below one second on the Mac.

## Dynamic string coverage (C8)

`./tools/lint.sh` runs `python3 -I tools/lint_strings.py`. The declared family map resolves ids from data, Types unions, HUD menu calls and the actual ShopScreen tabs/launch rows. Unknown dynamic prefixes or missing required keys fail. Literal keys and both Strings/strings aliases count as direct uses. COND_SHORT overrides are optional because NearbyPanel falls back to COND_PHRASE; gift labels follow Gifts data. This is conservative lexical coverage, not runtime reachability proof.

Families found: `BIOME_`, `BUILD_KIND_`, `CONDITION_`, `COND_PHRASE_`, `COND_SHORT_`, `FN_`, `GEAR_`, `GIFT_LABEL_`, `HOME_ITEM_`, `ITEM_`, `JOB_`, `LANDMARK_`, `LURE_`, `MATERIAL_`, `MENU_`, `MENU_GLYPH_`, `MODULE_`, `OBJ_`, `OFFER_`, `OVERLAY_`, `OVERLAY_A_`, `PEDDLER_KIND_`, `PERK_`, `POWERUP_`, `POWERUP_DESC_`, `REWARD_`, `SEASON_`, `SEGMENT_`, `SETTINGS_`, `SETTINGS_LEVEL_`, `SHAPE_`, `SHOP_DESC_`, `SHOP_ITEM_`, `SHOP_SECTION_`, `SHOP_TAB_`, `SIZE_`, `STAGE_`, `STATION_`, `TIER_`, `TIER_A_`, `WEATHER_`, `WORLD_`.

Added only: `LANDMARK_CrashSite`, `LANDMARK_CaveMouth`, `LANDMARK_GreatVent`, `LANDMARK_IceCaveMouth`.

Unused candidates (36), retained for coordinator review: `ACTION_RIDE`, `ALIENS_RESTING`, `ALIENS_RIDING`, `CAMP_IDLE`, `CAMP_WORKER`, `COMING_SOON`, `CONDITION_Ashfall`, `CONDITION_Day`, `CONDITION_Eclipse`, `CONDITION_GravityFlip`, `CONDITION_KingTide`, `CONDITION_PowerSurge`, `HEATER_NAME`, `HUD_SCRAP`, `LAUNCH_GO`, `LAUNCH_WELCOME`, `MODULE_COMPLETE`, `MODULE_NEEDS_KEY`, `QUESTS_TITLE`, `RUSH_OVER`, `SHIP_TAB_BAR`, `SHOP_BUY_ROBUX`, `SHOP_ITEM_HoverSkinStarter`, `SHOP_ROBUX_SOON`, `SHOWER_INCOMING`, `TOAST_NEW_DAY`, `VERB_Build`, `VERB_Gather`, `VERB_Spark`, `VERB_Tinker`, `WEEKLY_CHIP_WORLD`, `WORLD_3`, `WORLD_4`, `WORLD_5`, `WORLD_6`, `WORLD_7`.

Two isolated mutations verify unknown-family and missing-key failures; normal run is below one second. New dynamic lookups that use other code shapes need a scanner extension; direct Strings.X references also remain covered by Luau analysis.

## Vault lint (`tools/lint_vault.py`)

Run `python3 -I tools/lint_vault.py` (add `-v` to list every finding); `./tools/lint.sh` runs it as its last step and prints `vault: clean` or the counts. Python 3 and its standard library are the only dependencies. It walks `docs/vault/**/*.md` and matches `[[links]]` by file stem, case-sensitive, the Obsidian way: a link may carry `|alias`, `#heading` and `^block` parts, or a folder path (`[[05-ui-design/refs/README|refs]]`, needed because three notes are named README; a bare `[[README]]` means the root one). Fenced code and `inline code` are ignored, so a note can show link syntax safely. Links in frontmatter (`up: "[[Start-Here]]"`) count. An `![[image.png]]` embed must name a file that exists in the vault.

| Check | What fails it | Result |
|---|---|---|
| Broken links | a `[[target]]` with no note of that name anywhere in the vault (a doc outside the vault gets a pointer note, as [[STORE-PAGE]] does, or a relative markdown link) | **fails** (exit 1) |
| Orphan notes | no inbound link from another note; the daily logs under `08-log/` do not count as sources, but a log nothing links is an orphan | warning |
| No outbound link | a note that links to nothing | warning |
| Folders without a hub | no note in the folder named after its topic (`06-art-pipelines/Art-Pipelines.md`, `00-start-here/Start-Here.md`), or a hub that does not link every note in its folder | warning |
| Frontmatter | no YAML frontmatter with `tags` | warning |
| Log headings | a `## ` heading in a daily log whose section has no `[[link]]` (the `CLAUDE.md` rule: lasting facts move to their topic note and the log links it) | warning |

First run on 2026-10-15 (before the vault pass): 31 broken links, 11 orphans, 21 notes with no outbound link, 9 folders without a hub, 51 notes without frontmatter tags, 9 log headings with no link. A new note goes into its folder's hub in the same change; [[How-We-Work]] lists this note with the other checks.
