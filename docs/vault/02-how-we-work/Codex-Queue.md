# Codex job queue

How the second agent (OpenAI Codex with GPT-6 Astra, on Ethan's Mac) works with the Claude coordinator without anyone relaying files by hand. The coordinator writes job cards here; Ethan tells Codex "take the next open job" (the standing prompt is in `Codex-Prompt.md`); Codex does exactly the card, pushes, and appends its report to `Codex-Reports.md`; the coordinator pulls, reviews the diff, and marks the card done or writes a follow-up card. Codex never takes a card that is not `open`, never edits a file its card does not name, and never touches `src/` game logic unless the card says so.

Card states: `open` (take it), `taken by codex <date>` (in progress), `review` (pushed, waiting on the coordinator), `done`, `dropped`.

Batch mode: when Ethan says "do all open cards", Codex takes every `open` card in order without stopping between them, one commit and one report per card, and stops only at the end or at a blocker. Pushing a file under `.github/workflows/` needs a Git credential with the `workflow` scope (`gh auth refresh -h github.com -s workflow` on the Mac); until then leave any workflow change for the coordinator to push and say so in the report.

## Rules every card inherits

- Read `AGENTS.md` and `CLAUDE.md` first. Strict Luau, every number in `src/shared/data`, every string in `src/shared/strings`, Scale-only UI, one system per change.
- Branch `claude/alien-system-research`. Before pushing: `git pull --rebase origin claude/alien-system-research`, then `export PATH=$HOME/.local/bin:$PATH; ./tools/analyze.sh` must print `analyze: clean` (install rojo 7.7.1 and luau-lsp 1.70.1 with rokit if missing; `tools/setup-mac.sh` has the steps), then push.
- Commit message: first line under 72 characters saying what changed, a body saying why, and the trailer `Agent: Codex`.
- Never commit audio or raw frame dumps from `media/tiktok/out/`. The Open Cloud key lives only in the shell; never in a file, a commit or a report.
- Report in `Codex-Reports.md`: card id, hash, what changed, what was measured, anything left open; under 300 words.

## Cards

### C1. Continuous integration on every push — done (coordinator pushed Codex's files as c298e7c; runs 37417243594, 37417307744 and 37417348148 green)

Blocked: GitHub rejected the workflow push because the OAuth credential lacks `workflow` scope.
Needed: authorize a credential with workflow-write permission, then restore the C1 implementation and verify a green Actions run.

Goal: a GitHub Actions workflow that runs the repo's own checks so neither agent can push a red tree unnoticed.

Files: `.github/workflows/check.yml` (new), `tools/ci/install-tools.sh` (new).

Do: on push and pull request to any branch, an `ubuntu-latest` job that (1) installs rojo 7.7.1 and luau-lsp 1.70.1 into `$HOME/.local/bin` from their GitHub release archives (pin the versions; cache the downloads with `actions/cache` keyed on the two version strings), (2) runs `./tools/analyze.sh`, (3) runs `python3 tools/lint_data.py` when that file exists (card C2), (4) runs `./tools/test.sh` when it exists (card C3). Fail the job on any non-zero exit. Keep the workflow under 60 lines; no third-party actions beyond `actions/checkout` and `actions/cache`. Test it by pushing and linking the green run in the report.

### C2. Data lint — done (277b885; the coordinator added a `built` flag to Worlds so designed-only worlds' species are skipped; lint green)

Goal: a script that proves the data tables agree with each other, so a typo in an id is caught before Studio.

Files: `tools/lint_data.py` (new), `docs/vault/02-how-we-work/Data-Lint.md` (new).

Do: a Python 3 standard-library script that parses the Luau data tables under `src/shared/data/` and `src/shared/strings/en.luau` as text (a small tolerant parser for the table literals the repo uses, or regexes per table; no Luau runtime) and checks, printing one line per failure and exiting 1 on any: every species id in `Spawns.luau` exists in `Species.luau`; every biome key in `Spawns.luau` is in `Types.luau`'s Biome union; every `KeyMaterials` id referenced by `Modules.luau`, `Quests.luau`, `Tutorial.luau` and `Layouts` node tables exists; every species `world` matches a `Worlds.luau` id and every world's `warden` and special `speciesId` exist in `Species.luau`; `Sizes.luau` odds sum to 100 and `Spins.luau` wedge odds sum to 100; every strings key referenced by a data row (`hint`, `labelKey`, `hintKey`, `nameKey`, `holdHintKey`, `REWARD_*`, `MATERIAL_*`, `SPECIES_*`, `STATION_*`, `JOB_*`, `TIER_*`, `SIZE_*`, `STAGE_*`, `MENU_*`, `COMPASS_*`) exists in `en.luau`; every `Icons.luau` key has a PNG under `assets/icons` or `assets/particles` and every PNG has a key; every `CatchVariants` row named by `Worlds.catchVariant` or `Species.variant` exists; `Growth` stages are in ascending `workedSeconds`; `Tiers` `aura` is a number on every row. Document each check in `Data-Lint.md` with the file it reads. Run it; fix nothing in the data yourself: list any failure in the report for the coordinator.

### C3. Headless unit tests for the shared math — done (59756ce; 41 tests pass here in 0.01 s under the pinned Luau 0.741)

Goal: the pure modules get tests that run without Studio, in seconds.

Files: `tools/test.sh` (new), `tests/` (new folder, one `*.spec.luau` per module), `docs/vault/02-how-we-work/Testing-Headless.md` (new).

Do: use the `luau` CLI (Luau's own interpreter from `luau-lang/luau` releases, pin the version, install into `$HOME/.local/bin` in `tools/ci/install-tools.sh` from card C1, or in `tools/test.sh` when missing) with a tiny test runner in `tests/run.luau` (describe/it/expect, no dependencies) that stubs `game:GetService` and `script.Parent` lookups just enough to `require` the pure shared modules by path. Cover: `Shared/Capture.luau` (`position` triangle wave at 0, a quarter, a half and a full period; `outcome` at the zone edges; `isNearMiss`; `driftCenter` with amplitude 0 returning base, with phase 0 returning base at elapsed 0, and clamping), `Shared/Growth.luau` (`StageAt` at 0, 7199, 7200, 86400; `Next`; `SecondsToNext`), `Shared/OutpostMath.luau` and `Shared/LeaderboardMath.luau` (period start and id around the reset hour and weekday), `Shared/Economy.luau` (`workSpeed` of a Common level 1 is 1; a Grown record is 1.1; `offlineScrap` respects the cap). Every number in a test comes from the data tables (require them), never retyped. `tools/test.sh` runs every spec and exits non-zero on a failure. Report the test count and runtime.

### C4. Economy balance report — done (cbc22dd, report f32110c; verdict in Codex-Reports.md: the flagged cost jumps stay, World 2's fast opening goes to C7)

Goal: the plan's section 3.3 sanity check, recomputed from the live data tables, so balance changes are judged on numbers.

Files: `tools/balance.py` (new), `docs/vault/01-game-design/Balance-Report.md` (new).

Do: a Python 3 standard-library simulator that reads `Tiers`, `Species`, `Spawns`, `Modules`, `KeyMaterials`, `Growth`, `Sizes`, `Config` (the catch, income, offline and module numbers) and `Gifts` as text (reuse card C2's parser), then simulates a median player on World 1 and World 2: catches per minute from the capture numbers (assume a 60 percent Good rate and 15 percent Perfect), the tier mix from the shares, the station crew that results with the slot unlocks, Scrap per minute over time including growth stages, and the wall-clock time to each module with and without offline time (capped as in Config). Print and write a Markdown table per world: module, Scrap needed, minutes of active play, minutes with one offline session a day; then a short list of outliers (a module more than three times the previous one, a tier that never seats). Compare with the plan's targets (first module inside five minutes, World 1 ship in a few sessions, World 2 at 1.6x Scrap and 1.5x assembly) in the report. Change no data; list suggested changes for the coordinator.

### C5. Headless tests for the newer shared maths — done (116a72f, b18f3aa; 71 tests)

Goal: `WeeklyMath` and the fusion fodder rule covered by headless specs. (`Growth`, `OutpostMath`, `SeasonMath` and `VisitRules` already have specs; extend `Growth.spec.luau` only if a threshold edge is missing.)

Do: (1) `tests/WeeklyMath.spec.luau`: `IndexAt` from `Weekly.Epoch` (week 0 is index 1, it wraps at `#Rotation`, a negative offset wraps too), `Current` one second before and at the Friday `ResetHourUtc` boundary, an `Overrides` entry winning only with offset 0, `IsLimited` and `IsCurrent`. Derive every expected value from the data tables and `tests/Fixtures.luau`, never from literals (the C3 convention). (2) Move the fusion selection (which copy is kept, which copies are fodder) out of `Economy.Fuse` into `src/shared/FusionMath.luau` as a pure function, with `Economy.Fuse` calling it and behaving identically: same reasons, same kept copy, the same order of preference between resting and seated copies, never a copy above the kept copy's level as fodder (the milestone 35 fodder fix, `docs/PRE_PRODUCTION.md` row 35), the same level cap from `data/Fusion`. Read `Economy.Fuse` and `docs/TESTING.md` "Milestone 35" first and encode today's behaviour exactly. `tests/FusionMath.spec.luau` covers each reason and each preference.

Files: `src/shared/FusionMath.luau` (new), `src/server/Services/Economy.luau` (`Fuse` calls it; no other change), `tests/WeeklyMath.spec.luau`, `tests/FusionMath.spec.luau`, `tests/Growth.spec.luau` (only if extended).

Done when: `analyze: clean`, `./tools/test.sh` green with both new spec names in its output, and the `Economy.luau` diff limited to `Fuse`.

### C6. Data lint: the rules the code relies on — done (1b07b06, 00101be; 17 rule groups)

Goal: every data-shape assumption the code makes is checked before Studio ever sees it (the lesson in `docs/vault/04-roblox-engine/Data-Tables.md`).

Do, in `tools/lint_data.py`:
- A table keyed by numbers (`Radar`, `Layouts`, `Worlds`) carries no string keys except an allow-list in the script (`Radar.Mk2`).
- Every `Order` and `Rotation` list is dense, and every id in it exists in its table.
- `Species.ride` is a Traversal with a `Mounts.Traversals` row; every `Mounts.SeatStuds` key is a species.
- `HomeBuild`: every habitat row has a built `worldId` and `capacity` above 0; every item's `cellsX` and `cellsZ` are between 1 and `Home.PlotCells`; `Caps` has every kind the items use.
- `Weekly.Rotation`: species exist; a `limited` species is in no `Spawns` table.
- `Seasons`: `startsAt` before `endsAt`; windows never overlap; event `species` exist and are in no `Spawns` table; `returns` exist; `overlay` is an `Overlays` row; track quest ids unique within a season; every reward row is valid (`alien` ids are species, `lure` and `powerUp` ids exist).
- `Shop`: item ids unique; every `Launch` id exists in `Items`; every `Launch` item has a `Grants` row or is on an allow-list of passes a service reads live (`CompanionSlot4`); no `Grants` row hands out anything named in `NeverSold` (Scrap, DoubleShift, LuckyCharm, a Legendary or event alien).
- `Settings`: a `levelKeys` list is as long as `levels` and every key is in `strings/en.luau`; every `default` is in range.
- `Codes`: every reward id exists.

If a rule finds a real problem in today's data, do not change the data: print that rule's finding as a warning (not a failure), list it under "Found" in the report, and the coordinator fixes the data.

Files: `tools/lint_data.py`, `docs/vault/02-how-we-work/Data-Lint.md`.

Done when: `python3 -I tools/lint_data.py` prints `data lint: clean` (warnings allowed only for listed findings), and each new rule has a one-line entry in `Data-Lint.md`.

### C7. Balance report, second pass — done (0c3ba45, 71dbb69; the coordinator applied a rising curve instead of the proposal, see Codex-Reports.md)

Goal: extend `tools/balance.py` with the systems that landed after the plan's section 3.3: fusion (four spare copies per level; the share of catches that become fodder at the median), growth (the speed bonus by time seated), companions (perk sums for a median set of three), habitats (Scrap per hour by tier for three displayed), the Catch Rush payouts (per round, by rank), the weekly drop's share, and the outposts. Report the Scrap sources per hour of active play and per day of offline time, and flag any source above 30 percent of the total. Then the World 2 opening from C4: with the carried crew earning about 3,100 Scrap/min, World 2 finishes faster than World 1. Propose (do not apply) a World 2 module curve that makes its continuous completion about 1.5 times World 1's, keyed to the income a median player carries in, and show the simulated times for the proposal beside the live ones.

Files: `tools/balance.py`, `docs/vault/01-game-design/Balance-Report.md`.

### C8. String coverage lint — done (8767c2c, 14dfdbd; 36 unused keys left for the polish pass)

Goal: no raw string key ever shows on screen. Direct `Strings.X` references are already checked by the type checker; the dynamic families (`Builder.text("TIER_" .. id)`) are not.

Do: `tools/lint_strings.py` (standard library; reuse C2's table reader). (1) Find every `Builder.text("PREFIX_" .. expr)` and every `("PREFIX_%s"):format` in `src/client` and `src/server`. (2) Map each prefix to the ids it is fed from, in one mapping table at the top of the script (for example `TIER_` to `Tiers`, `LURE_` to `Lures`, `SEASON_` to `Seasons.List`, `OVERLAY_` to `Overlays.Order` plus `None`, `MATERIAL_` to `KeyMaterials`, `WORLD_` to built `Worlds`, `WEATHER_` to every weather state in `Worlds` and `Weekly`, `POWERUP_` to `PowerUps`, `BIOME_`, `COND_PHRASE_`, `JOB_` and `STATION_`, `STAGE_`, `SIZE_`, `OBJ_` to every objective kind in `Quests`, `DailyQuests` and `Seasons`, `MODULE_`, `FN_`, `SHOP_DESC_`, `SHOP_TAB_`, `SHOP_SECTION_`, `SEGMENT_`, `HOME_ITEM_`, `BUILD_KIND_`, `MENU_` and `MENU_GLYPH_`). A prefix found in code with no mapping fails the lint, so a new family cannot slip through. (3) Every mapped id must have its key in `src/shared/strings/en.luau`: a missing key fails. (4) Keys in `en.luau` that nothing uses, directly or through a family, are printed as warnings and listed in the report (do not delete any). (5) Create `tools/lint.sh`, a runner for the extra lints (this card's now; later cards append theirs); CI already runs `tools/lint.sh` when it exists. If today's code has missing keys, add them to `en.luau` (adding keys only, in the voice of their neighbours) and list them in the report.

Files: `tools/lint_strings.py`, `tools/lint.sh`, `src/shared/strings/en.luau` (new keys only), `docs/vault/02-how-we-work/Data-Lint.md` (a section).

Done when: `./tools/lint.sh` passes, the report lists the families found, the keys added and the unused keys.

### C9. Remote contract lint and server-authority audit — done (0280159 to 1a627e6; 5 guards reviewed and kept)

Goal: a client that waits for a remote the server never creates hangs with no error; a handler without a rate limit or an argument check breaks the server-authority rule in `CLAUDE.md`. Both should be caught by a script, not by a playtest.

Do: `tools/lint_remotes.py`. (1) Collect every remote name created through `Net.event("X")` or `Net.func("X")` in `src/server`, every name the client uses (`Net.event`, `Net.func`, `OnClientEvent`, `InvokeServer`, `FireServer`) and every name the server fires (`FireClient`, `FireAllClients`). (2) Fail when the client uses a name no server module creates. Warn when the server creates a name no client uses, or fires one no client listens to. (3) For every `OnServerInvoke` and `OnServerEvent` handler, report whether it calls `Net.allow` before reading a profile, and whether every argument it receives is checked (`type`, `typeof`, an integer or NaN check) before use; this part is a heuristic and only reports. (4) `--write` regenerates `docs/vault/04-roblox-engine/Remotes.md` deterministically: one table row per remote (name, kind, created in, client users, rate limit, argument checks). (5) Append the contract check to `tools/lint.sh`.

Then fix what the audit flags: every flagged handler gets the missing guard at its very top, following that file's own pattern (a named local rate constant with a comment, then the file's existing refusal convention such as `return false, "BadArgs"`). No other change in those files; one commit per service file; `analyze: clean` after each.

Files: `tools/lint_remotes.py`, `tools/lint.sh`, `docs/vault/04-roblox-engine/Remotes.md` (new), and only the `src/server/Services/*.luau` handlers the audit flags.

Done when: `./tools/lint.sh` passes, `Remotes.md` lists every remote, and the audit reports no handler without a rate limit.

### C10. Save migration tests — done (3ae9543, 0e1cd34; 95 tests, the future-save rule pinned)

Resolved: coordinator supplied the future-save early return; extracted unchanged and tested.
Verified: 24 new schema cases pass, including all 14 migration steps and untouched future saves.

Goal: the save migrations (schema v1 to v15) are tested before real saves are switched on, so an old player's save can never come back broken.

Do: move `template`, `migrations`, `migrate` and the helpers they call (`defaultSettings`, `defaultSocial`, `emptyPeriodQuests`, `SCHEMA_VERSION`) out of `src/server/Services/PlayerData.luau` into `src/server/ProfileSchema.luau`, a pure module (no services, no yields, no DataStore). `PlayerData` requires it and behaves identically. Extend `tools/test.sh` to bundle that one server file next to `src/shared` so specs can require it. `tests/ProfileSchema.spec.luau`: (a) a minimal v1 save migrates to `SCHEMA_VERSION` with every `Types.Profile` field present and of the right type; (b) `migrate(template())` leaves every field of a current profile unchanged; (c) each step is idempotent; (d) the specific rules: a save with two unlocked worlds gets `home.unlocked` (v10), `habitatSettled` is set (v12), mail and visitors start empty (v13), the wave tally exists (v14), `seasons` exists (v15), unknown settings keys are dropped and missing ones take their defaults (v3); (e) a save whose version is above `SCHEMA_VERSION` is left alone. Read the migrations to infer what a v1 save held.

Files: `src/server/ProfileSchema.luau` (new), `src/server/Services/PlayerData.luau` (require it; remove the moved code only), `tools/test.sh`, `tests/ProfileSchema.spec.luau`.

Done when: `analyze: clean`, `./tools/test.sh` green with the new spec in its output, and a review of the `PlayerData.luau` diff shows only moved code.

Coordinator decision (2026-10-07), answering the blocker: (e) is now today's behaviour. `migrate` returns a save whose version is above `SCHEMA_VERSION` untouched (an early return through `isFromTheFuture`, added by the coordinator), and `tryLoad` refuses to own such a save, so old code never writes it back. Move `isFromTheFuture` with the rest, and test (e) as "returned untouched: same fields, same values".

### C11. UI rules lint — done (2a987ab, d9c2371; the catch bar's press-and-hold is its own sound path, fine)

Resolved: coordinator authorized marked vertical grid offsets; the two existing lines now carry that marker.
Verified: UI lint passes with 20 colour calls baselined and one advisory capture-backdrop tap candidate.

Goal: the UI rules in `CLAUDE.md` and the UI Playbook enforced by a script: Scale never Offset, colours from the Theme, the one font, no silent taps.

Do: `tools/lint_ui.py` over `src/client`. (1) Offset: `UDim2.fromOffset`, a `UDim2.new` with a non-zero second or fourth argument, or a non-zero `UDim.new(0, n)` in a Size or Position fails (today there are none; keep it at none). (2) Colours: `Color3.fromRGB`, `Color3.fromHex` or `Color3.new` outside `src/shared/Theme.luau`. Today about six exist in `src/client/UI`; record them in `tools/lint_ui_baseline.json` and fail only on new ones (a ratchet: the baseline may only shrink). (3) Fonts: any `Enum.Font` or `Font.new` outside `Theme` and `Builder` fails. (4) Silent taps: every `TextButton` or `ImageButton` made with `Instance.new` in `src/client/UI` must connect `Activated` (or `MouseButton1Click`) to a handler that plays a sound (`Builder.playSound`), unless it is built by `Builder.button`; report-only, with the list. Append to `tools/lint.sh`.

Files: `tools/lint_ui.py`, `tools/lint_ui_baseline.json`, `tools/lint.sh`, `docs/vault/04-roblox-engine/UI-Rules.md` (a short "Lint" section).

Done when: `./tools/lint.sh` passes and the report lists the baseline entries and the silent taps found.

Coordinator decision (2026-10-07), answering the blocker: the UI Playbook's "Grids inside scrolling frames" exception is authorized. A `UIGridLayout` `CellSize` or `CellPadding` inside a ScrollingFrame may carry a pixel height derived from an `AbsoluteSize`, and only on a line that ends with the marker comment `-- lint: grid-pixel-height (UI Playbook, Grids inside scrolling frames)`. The lint allows Offset on a marked line only when the property is `CellSize` or `CellPadding`. Add the marker to `src/client/UI/AliensScreen.luau` lines 688 and 689 (that comment is the only edit allowed in that file).

### C12. TESTING.md consistency lint — done (1801d10, 1eb6ff0; the 4 advisory lines are typed player input, fine as they are)

Goal: the Mac's Studio runs read `docs/TESTING.md` word for word; a stale command or toast text there costs a whole re-run. The code is the truth.

Do: `tools/lint_testing.py`. (1) Every chat command written in `docs/TESTING.md` (a word starting with `/` inside backticks) is registered in `src/server/Services/Dev.luau` or `Admin.luau`. (2) Every quoted player-facing line in the script ("Scanner Pulse on!", "Welcome to Player1's home!") matches a string in `en.luau`, allowing `%s`, `%d` and `%g` to match any value; lines that are not game strings (Output lines in backticks, explanations) are skipped by rule, and the rule is documented in the script. Print each mismatch with its milestone section. Then fix the wording in `TESTING.md` where the string changed in the code (edit `TESTING.md` only, never the strings), and list every fix. Append the lint to `tools/lint.sh` as warnings only.

Files: `tools/lint_testing.py`, `tools/lint.sh`, `docs/TESTING.md` (wording fixes only).

Done when: the lint runs in `tools/lint.sh`, and the report lists the mismatches found and fixed and any left for the coordinator (a line that may describe intended behaviour not yet built).

### C13. Dead code and dead data report — done (78da295, 9f6a5bb)

Goal: a list for the coordinator's polish pass of everything built and never used.

Do: `tools/deadcode.py`. (1) Public functions of every `src/server/Services` module (`function X.Y`) never referenced outside their module. (2) Public functions of `src/client/UI` and `src/client/World` modules never called. (3) Data never read: `Shop.Items` rows with no `Grants` and not in `Launch`, `Icons` ids no row points at, `Sounds` ids nothing plays, strings nothing uses (from C8), remotes no client uses (from C9). Write `docs/vault/02-how-we-work/Dead-Code.md` with each finding and a one-line suggestion (delete, keep for a named milestone in `docs/PRE_PRODUCTION.md`, or wire up). Change no code and no data.

Files: `tools/deadcode.py`, `docs/vault/02-how-we-work/Dead-Code.md`.

Done when: the report exists, every finding has a suggestion, and the script runs in under ten seconds.

### C14. Performance budget report — done (5d5b6fb, 625a161)

Goal: Roblox players are mostly on phones; find the per-frame work and instance counts that could hurt before the visual pass adds more.

Do: `tools/perf_report.py`. (1) Every `RenderStepped`, `Heartbeat` and `Stepped` connection in `src/client` and `src/server`: the file, what it loops over each frame, and whether that loop is bounded (a fixed count) or grows with players, spawns or records. (2) Instance counts per world from the data: the world builder's scatter, regions and landmarks (`data/Layouts`, `data/Meadow`, `data/Frostbyte`, `data/Home`), the spawn cap (`Config` and `data/Spawns` density), weather particle rates (`data/Weather`), and the camp. Estimate parts per world, particles per second at peak (a Shower plus Rain), and the per-frame loop sizes at 8 players. (3) Flag anything above these budgets: more than 4,000 parts in a world, more than 2,000 particles alive, a per-frame loop over more than 200 items, a per-frame loop that allocates tables. Write `docs/vault/04-roblox-engine/Performance.md`: the table, the flags and a fix suggestion for each. Change no code.

Files: `tools/perf_report.py`, `docs/vault/04-roblox-engine/Performance.md`.

Done when: the report exists with numbers derived from the data (not guessed), and each flag has a suggestion.

### C15. Shared house-grid maths, with tests — done (81a69a8, 8c3a483; 140 tests; the ghost path traced, the missing ghost was the tray swallowing taps, fixed by the build camera 3cee9d1)

Goal: the house grid's maths lives in one tested shared module that the server (`HomeBuild`) and the client (`HomeRenderer`, the Build tray's ghost) both call, so the two can never disagree. The owner reported that a Verdant Habitat pick followed by a tap on the plot showed no ghost in a two-player Studio test; Studio now prints `Build tap ignored: <reason>` for every ignored tap, but the maths should be proven too.

Do: move the footprint (an item's cells from its corner cell, its `cellsX` and `cellsZ`, swapped for rotations 1 and 3), the inside-the-plot test, the overlap test and the point-to-cell conversion (as a pure function of the plot's size and a local point) into `src/shared/HomeGrid.luau`, with `HomeBuild.luau` and `HomeRenderer.luau` calling it and behaving identically. `tests/HomeGrid.spec.luau`: every item in `data/HomeBuild` at every rotation fits at the plot's corner cell and is refused one cell past each edge; the 3x3 habitats at every cell; overlaps between a 2x2 room and a 1x1 thing; the cell of points on cell borders. While in the client code, trace the path from a card pick (`pickItem`) through `OnWorldTap` and `HomeRenderer.SetGhost` for a habitat and report any case where a pick and a tap on the plot show no ghost.

Files: `src/shared/HomeGrid.luau` (new), `src/server/Services/HomeBuild.luau`, `src/client/World/HomeRenderer.luau`, `src/client/UI/BuildScreen.luau` (only if the trace finds a real fault), `tests/HomeGrid.spec.luau`.

Done when: `analyze: clean`, the suite green with the new spec, the two service diffs limited to calling the shared module, and the report says what the trace found.

### C16. Exploit review of every remote — done (7121b69 to e1de5a2; 3 NaN-safe guards kept; D5 and D8 fixed by the coordinator, the rest decided in Exploit-Review.md)

Goal: Roblox games are attacked through their remotes by modified clients. Every remote must survive any input.

Do: for every remote in `docs/vault/04-roblox-engine/Remotes.md`, read its handler and list what a modified client could send: wrong types, NaN and infinities, negative or huge numbers, fractions where an integer is expected, another player's uid or a uid it does not own, ids missing from the data, calls from the wrong place (a world remote at home, a home remote in a world), calls while a teleport or a claim is in flight, two calls interleaving around a yield, and replays of a one-time claim. Write `docs/vault/04-roblox-engine/Exploit-Review.md`: one row per remote with the risks, the checks present, and a verdict (safe, fixed, or needs the coordinator). Fix what is missing with the smallest guard at the top of the handler, following that file's conventions, one commit per service file. Where the check can live in a pure shared module, add a headless test for it.

Files: `docs/vault/04-roblox-engine/Exploit-Review.md` (new), and only the `src/server/Services/*.luau` handlers that need a guard.

Done when: every remote has a row, every "fixed" row names its commit, the checks stay green, and anything that changes game behaviour is left as "needs the coordinator" instead of fixed.

### C17. Save size budget — done (02edfdf; storage cap decided: milestone 50)

Goal: a player's save is one DataStore value, and a value over 4 MB cannot be saved. Every catch adds an alien record and nothing removes them, so a heavy player's save grows without bound.

Do: `tools/save_budget.py`. Build profiles from `src/server/ProfileSchema.luau`'s template shape (read through C2's table reader or rebuild the shape in Python), encode them the way Roblox's JSON encoder would (compact JSON), and measure: the size of each record kind (an alien, a codex entry, a house item, a letter, a visitor, a receipt, a season track), and a heavy player's save after 1, 7, 30, 90 and 365 days at the catch rates from `tools/balance.py` (continuous play hours per day as a parameter, default 3). List every field of `Types.Profile` that can grow without limit and what bounds it today (caps, pruning). Report when the 4 MB limit is reached and propose options with their numbers: a storage cap with a "release for Scrap" action, stacking identical plain copies as a count, pruning old receipts, trimming finished season tracks. Change no code or data.

Files: `tools/save_budget.py`, `docs/vault/04-roblox-engine/Save-Budget.md`.

Done when: the report gives the day the limit is reached for the default player and for a 10-hours-a-day player, and each option's effect on that day.

### C18. Dead code cleanup, the safe class — done (efe4d00, 1aceda6, 1032608; 13 declarations and 22 strings removed, accepted)

Goal: remove what the C13 report marked as safe to delete, so the polish pass works on less code.

Do: from `docs/vault/02-how-we-work/Dead-Code.md`, delete only (a) functions with no caller anywhere (game code, Dev, tools and tests all checked), and (b) string keys no code and no data family uses (the C8 lint lists them), except strings for features the plan names as designed but not built (later worlds in `data/Worlds`, shop catalog rows, seasons) which stay. Do not remove any `Shop.Items` row (an owner decision). One commit per area (server, client, strings). Re-run `tools/lint_strings.py` and `tools/deadcode.py` after and update `Dead-Code.md` with what was removed and what was kept and why.

Files: the files the report names (deletions only), `src/shared/strings/en.luau` (deletions only), `docs/vault/02-how-we-work/Dead-Code.md`.

Done when: every check is green, and `Dead-Code.md` lists each removal with its commit.

### C19. The Studio run sheet — done (73f7112; the stale TESTING wording goes to C26)

Goal: one ordered list of every Studio check still waiting, so the owner or the Mac session can run them in one sitting without reading the whole test script.

Do: `tools/studio_queue.py --write` generates `docs/STUDIO-QUEUE.md` from `docs/TESTING.md` and the status column of `docs/PRE_PRODUCTION.md` section 5b: every milestone whose status says queued, re-check, needs a multi-client run, needs real saves or needs a published game. Group by what the run needs (World 1 place; World 2 place; home place; a two-player test; real saves; the published game), in an order that minimises place switches. Each entry: the milestone, the TESTING.md steps to run, the setup (which project file, which dev commands), and what to send back. The script is deterministic and runs in the lint runner as a check that the file is current (fail when `--write` would change it).

Files: `tools/studio_queue.py`, `tools/lint.sh`, `docs/STUDIO-QUEUE.md` (new).

Done when: `./tools/lint.sh` passes and the file lists every pending check with no duplicates.

### C20. Moment inventory — done (3218607; sound and music pass decided: milestone 51)

Goal: the owner wants every moment in the game designed for an emotion (`docs/PRE_PRODUCTION.md` section 5a): sound, music, camera, effects and phone rumble working together, with a Legendary encounter as the worked example. Before that can be designed, list what each moment does today.

Do: `docs/vault/01-game-design/Moments.md`, one row per player-facing moment, with: the trigger (the server event or client call, with file and line), what it does today for sound (the `data/Sounds` ids it plays, and whether each id is still 0), effects (`Vfx` calls), camera (`CameraDirector` calls), UI (toast, banner, Reveal), phone rumble (none exist; say so), music (none exists), and the intended emotion where `docs/GAME_DESIGN.md` states one (blank otherwise). Cover at least: the first catch ever, a catch by tier from Common to Secret, a Perfect, a miss and a flee, the catch bar opening by tier, the Reveal by tier, a rare spawn nearby, a Warden sighting, the Warden encounter, a Meteor Shower start and end, a Catch Rush start and win, the weekly flip, a season start, a module completing, the ship launching, arriving on a new world, a Star Chart flight, the home unlocking, arriving home, habitat income, mail arriving, a visitor arriving, a wave, resting and waking, fusion, a growth stage, a companion following and riding, a purchase, quest claims, a Field Notes step, Codex milestones. End with a list of every `data/Sounds` id still 0. Change no code.

Files: `docs/vault/01-game-design/Moments.md` (new).

Done when: every moment above has a row with a file and line for its trigger.

### C21. Music plan — done (0f4d223; the palette approved, ownership decided in the notes)

Goal: the owner wants music that fits the theme and what is happening at that moment. This card prepares the music director the coordinator will build.

Do: `docs/vault/06-art-pipelines/Music-Plan.md`. (1) The music states the game needs, from C20's moments and the design: exploring per world by day and night, the catch bar with an intense layer for Epic and above, Reveal stingers by tier, the Meteor Shower, the Catch Rush, the seasonal event, the launch, the home planet, resting, and the menus. For each: mood, tempo range, instruments, loop length, and how it enters and leaves. (2) A proposed data shape for `src/shared/data/Music.luau` (rows with an id, a Roblox audio asset id of 0 until chosen, volume, loop, layer, fade seconds) and the layering and crossfade rules a music director would follow. Write no code. (3) Candidate tracks from Roblox's licensed music in the Creator Store, with asset ids, only if you can browse the Creator Store from this Mac; otherwise give, per state, the search words to use in the Creator Store's Audio section.

Files: `docs/vault/06-art-pipelines/Music-Plan.md` (new).

Done when: every state has its row, and the data shape covers them all.

### C22. Create the shop items through Open Cloud — done (54b9bec; dry run checked by the coordinator, the Mac runs --apply)

Goal: Ethan stops creating game passes and developer products by hand (owner guide Part C). Roblox's Open Cloud creates them: game passes with `POST https://apis.roblox.com/game-passes/v1/universes/{universeId}/game-passes` (multipart: name, description, price, isForSale, imageFile; scope `game-pass:write`), developer products through the developer-products API (scope `developer-product:write`). Check both against the official reference (create.roblox.com/docs/cloud/reference/features/game-passes and the developer products page) before writing the calls, and note the exact paths in the script's docstring.

Do: `tools/create_products.py`. Read `src/shared/data/Shop.luau` (C2's table reader) and pick the rows that are on sale at launch (the `Launch` sections) and still have `passId`/`productId` 0. Name from `SHOP_ITEM_<id>` and description from the matching description key in `src/shared/strings/en.luau`, price from `robux`, icon from the path owner guide Part C gives for that item (skip the image with a warning if the file is missing). The universe id comes from `--universe` or `GET https://apis.roblox.com/universes/v1/places/{placeId}/universe` on World 1's placeId in `Worlds.luau` (if that is 0, use World 2's). `--dry-run` is the default and prints the plan; `--apply` creates each item, writes the returned id into its row of `Shop.luau` with a minimal text edit (nothing else in the file changes), and prints a table of ids. Before creating, list the universe's existing passes and products and reuse an item with the same name instead of making a duplicate. The key comes only from the environment variable `ROBLOX_API_KEY`: never print it, never write it, never put it in an error; on an HTTP error print the status and Roblox's message only. Add `--self-test` with a fake HTTP layer (no network): dry-run plan, id write-back on a temp copy of Shop.luau, duplicate reuse, missing key refusal.

Codex runs `--dry-run` and `--self-test` only. The Mac's Claude session runs `--apply` (the key lives in its shell).

Files: `tools/create_products.py`, `docs/vault/02-how-we-work/Hands-Off.md` (a "Shop items" section: the command and what it changes).

Done when: `--self-test` passes, `--dry-run` lists exactly the five launch items still at 0 today (Spins1, Spins5, Spins12, SlotEveryStation2, CompanionSlot4) with name, price, kind and icon path, and analyze, data lint, tests and lint.sh stay clean.

### C23. Publish the three places through Open Cloud — open

Goal: Ethan stops republishing by hand (owner guide Parts A and H). Open Cloud publishes a place file: `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published` (or `Saved`), body the .rbxl, `Content-Type: application/octet-stream`, header `x-api-key`, scope `universe-places:write`; the answer carries `versionNumber`.

Do: `tools/publish.py`. For each project (`default.project.json` to Worlds row 1's placeId, `world2.project.json` to row 2, `home.project.json` to row 0): run `rojo build <project> -o build/<name>.rbxl`, then publish it. Before anything, run `./tools/analyze.sh`, `python3 -I tools/lint_data.py`, `./tools/test.sh` and `./tools/lint.sh` and refuse unless all are clean; refuse a place whose placeId is 0. `--dry-run` is the default (checks and builds only, prints sizes); `--apply` publishes; `--saved` saves without publishing; `--only home|world1|world2`. Universe id as in C22. Key from `ROBLOX_API_KEY` only, same rules as C22. Add `build/` to `.gitignore`. `--self-test` with a fake HTTP layer.

Note for the report: a place built by Rojo carries only what Rojo maps. The species and prop meshes live only in the Studio place today (installed by `tools/studio/install_models.luau`), so a Rojo-built place shows placeholder shapes until the coordinator's runtime model loader lands (it reads C24's table). Until the coordinator says the loader is in, the Mac uses `--saved`, never `--apply`.

Files: `tools/publish.py`, `.gitignore`, `docs/vault/02-how-we-work/Hands-Off.md` ("Publishing" section).

Done when: `--self-test` passes and `--dry-run` builds all three places from a clean checkout.

### C24. The model asset table — open

Goal: the server loads the species and prop meshes itself at boot (`InsertService:LoadAsset` on the Model assets `tools/upload_assets.py` uploaded), so a place built from the repo has them and publishing needs no Studio.

Do: `tools/model_assets.py` generates `src/shared/data/ModelAssets.luau` from `assets/models/asset_ids.json`: `{ [modelName] = assetId }` sorted by name, a header saying it is generated and how to regenerate it. Read `tools/studio/install_models.luau` and move whatever per-model data the installer applies (colours, materials, scale, names it renames) into the same table as data, so the runtime loader can apply exactly what the installer does; list in the report anything the installer does that is not data. Add a data-lint warning: every model name the game looks up (species `model` fields and the prop names the builders ask `Models` for) has an asset id. Deterministic, under ten seconds.

Files: `tools/model_assets.py`, `src/shared/data/ModelAssets.luau`, `tools/lint_data.py` (the one new warning), `docs/vault/06-art-pipelines/Map-Dressing.md` (a line in "Bulk import through Open Cloud").

Done when: the table lists every uploaded model, the lint runs clean or with documented warnings, analyze stays clean.

### C25. StyLua for the whole repo — open (run last in a batch)

Goal: "Adopt now" since 2026-10-05 and never done ([[Tools-Status]]). One formatter so no session or agent reformats code by hand.

Do: add `stylua = "JohnnyMorganz/StyLua@<latest 2.x>"` to `rokit.toml`; a `stylua.toml` that matches today's style as closely as possible (tabs, column width that keeps most current lines unchanged: measure it, double quotes, `call_parentheses = "Always"`); run StyLua over `src/` and `tests/` in ONE commit titled "StyLua: format the repo" with nothing else in it, only when no other card in this batch is still open (so no rebase fights it); then add `stylua --check src tests` to `tools/lint.sh`. Verify analyze, tests and every lint stay clean after the format. Report how many files and lines changed.

Files: `rokit.toml`, `stylua.toml`, `src/**`, `tests/**` (format only), `tools/lint.sh`, `docs/vault/02-how-we-work/Tools-Status.md` (the StyLua row to **in use**).

Done when: `stylua --check` passes in `tools/lint.sh` and the format commit contains formatting only.

### C26. Correct the stale TESTING wording C19 flagged — open

Goal: the run sheet flags lines in `docs/TESTING.md` that no longer match the code (zero place ids, the retired Longer Offline pass, old toast texts, "memory profiles" where real saves are now on with `Config.UseDataStoreInStudio = true`). The code is the truth; make the test steps say what the game does today.

Do: for each line `tools/studio_queue.py` reports as stale source evidence, read the code it describes and rewrite only that sentence so it is true (keep the step's numbering and intent; never change what a step checks, only how it is worded). Regenerate `docs/STUDIO-QUEUE.md`. Report each change in one line.

Files: `docs/TESTING.md`, `docs/STUDIO-QUEUE.md`.

Done when: the run sheet reports no stale source evidence and every lint is clean.

### C27 and later — not open yet

The look replication pass (icons v2, the soft sprite set, 9-slice plates, species texture passes, world dressing to match the owner's forest and map references) comes with the visual pass; those cards are written then.
