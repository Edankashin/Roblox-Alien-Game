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

### C5. Headless tests for the newer shared maths — open

Goal: the suite from C3 covers `WeeklyMath` (the week index from the epoch, a dated override, IsLimited, IsCurrent), the fusion fodder rule as a pure function (move the "copies at or below the kept copy's level" selection from `Economy.Fuse` into `Shared/FusionMath.luau` with the same behaviour, then test it: a capped Lv 3 over four plain copies refuses, five plain copies fuse, resting before seated), `Growth.StageAt` at the thresholds, and `OutpostMath.Pending` at the cap. Keep production behaviour identical; `./tools/analyze.sh` clean, `./tools/test.sh` green with the new specs listed in its output.

Files: `src/shared/FusionMath.luau` (new), `src/server/Services/Economy.luau` (call the shared function; no other change), `tests/WeeklyMath.spec.luau`, `tests/FusionMath.spec.luau`, `tests/Growth.spec.luau` (extend).

### C6. Data lint: table shapes code can walk — open

Goal: the lesson in `docs/vault/04-roblox-engine/Data-Tables.md` as lint rules in `tools/lint_data.py`: a table whose keys are numbers (`Radar`, `Layouts`, `Worlds`) must not carry string keys other than the ones listed in an allow-list in the script (`Radar.Mk2`), every `Order` list and `Rotation` list is dense (no holes) and every id in it exists in its table, every `Spawns` biome key is in the Biome union (already), every `Species.ride` is a Traversal with a `Mounts.Traversals` row, every `HomeBuild` habitat row has `worldId` and `capacity`, and every `Weekly.Rotation` species exists with `limited` species listed in no Spawns table. Report in `Data-Lint.md`; the lint must stay green on the current data.

Files: `tools/lint_data.py`, `docs/vault/02-how-we-work/Data-Lint.md`.

### C7. Balance report, second pass — open

Goal: extend `tools/balance.py` with the systems that landed after the plan's section 3.3: fusion (four spare copies per level; the share of catches that become fodder at the median), growth (the speed bonus by time seated), companions (perk sums for a median set of three), habitats (Scrap per hour by tier for three displayed), the Catch Rush payouts (per round, by rank), the weekly drop's share, and the outposts. Report the Scrap sources per hour of active play and per day of offline time, and flag any source above 30 percent of the total. Then the World 2 opening from C4: with the carried crew earning about 3,100 Scrap/min, World 2 finishes faster than World 1. Propose (do not apply) a World 2 module curve that makes its continuous completion about 1.5 times World 1's, keyed to the income a median player carries in, and show the simulated times for the proposal beside the live ones.

Files: `tools/balance.py`, `docs/vault/01-game-design/Balance-Report.md`.

### C8 and later — not open yet

The look replication pass (icons v2 rendered in Eevee, the soft sprite set, 9-slice plates, species texture passes, world dressing) comes after the mechanics are polished and tested, with Ethan's collaborator on the design; those cards are written then.
