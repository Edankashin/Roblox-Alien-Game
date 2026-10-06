# Codex reports

Appended by Codex after each card, newest at the bottom. The coordinator reads this after pulling.

## C1 — 2026-10-06 — blocked, ready for review

- Implementation commit: `30c1ad6` (reverted in this handoff because GitHub rejected the workflow push). Claim: `6704c55`.
- Prepared a 33-line push/pull-request workflow and a Linux installer for Rojo 7.7.1 and luau-lsp 1.70.1, with version-keyed download caching, SHA-256 verification, analysis, and conditional data-lint/test execution. Only the two C1 implementation files were changed; their additions are reverted in the final tree.
- Measured: workflow 33 lines (under 60); `bash -n` and `git diff --check` passed; official release archives contain the expected binaries; local `./tools/analyze.sh` printed `analyze: clean` before commits and attempted pushes. The authorized Mac toolchain was installed through Rokit and exposed in `$HOME/.local/bin`.
- Blocker: GitHub refused the push because the OAuth credential lacks `workflow` scope. No Actions run was created, so the Linux installer has not executed on a runner and no green-run link exists.
- Left open: authorize workflow-write access, restore the implementation, push, and link a green run. C2 and later cards remain untouched.

### Coordinator note on C1 — 2026-10-06

Codex's workflow and installer (30c1ad6) were restored and pushed by the coordinator as c298e7c; the first three runs are green (analyze clean on the runner, pinned tool hashes verified). C1 is done. The Mac's Git credential needs the `workflow` scope for Codex to push workflow files itself in future.

## C2 — 2026-10-06 — review

Implementation: `277b88570bd4ec31ed0c72d75b52e985dbae7a64`.

Added the standard-library Luau table reader and all requested cross-reference, odds, PNG, variant, growth-order and aura checks in `tools/lint_data.py`; documented inputs and parser limits in `Data-Lint.md`. Planned zero-ID Particles need no PNG; Icons always do. No data changed.

Measured: **10 lint failures**, exit 1; **18 isolated mutation checks passed**. All data modules parse. `analyze: clean` passed. [CI run 37420196543](https://github.com/Edankashin/Roblox-Alien-Game/actions/runs/37420196543) is red as expected at data lint.

Every failure is an absent Species ID referenced by Worlds:
- World 3: warden `Hephaestron`; special species `Voltwisp`.
- World 4: warden `Vulcanine`; special species `Cinderling`.
- World 5: warden `Poseidolphin`; special species `Pearlback`.
- World 6: warden `Morpheep`; special species `Floatling`.
- World 7: warden `Nyxling`; special species `Shadeling`.

Left open: coordinator resolves these placeholder references; until then CI stops before the later test step. No exclusions for unpublished worlds were introduced.

## C3 — 2026-10-06 — review

Implementation: `59756cedc035037032fc1fef46506edfe9ce8848`.

Added `tools/test.sh`, a dependency-free loader/runner, fixtures and five specs. The loader executes unchanged production source with cached path-tree modules, `script.Parent`, and a minimal ReplicatedStorage service. The installer pins official Luau **0.741** archives with checksums; Linux CI and macOS interpreter bootstrap are supported. No workflow or game files changed.

Measured: **41 tests passed, 0 failed, 0.019 s** interpreter runtime across five specs on the Mac. Includes Capture edges/drift, Growth thresholds, LeaderboardMath reset boundaries, OutpostMath production/caps and Economy speed/offline caps. Expected numbers come from required data tables. In isolated copies, a broken production formula and an empty spec directory both exited 1. Shell syntax, diff checks and `analyze: clean` passed.

Ethan clarified that OutpostMath should cover its existing production API, with period/reset tests reserved for LeaderboardMath.

[CI run 37420699789](https://github.com/Edankashin/Roblox-Alien-Game/actions/runs/37420699789): pinned Linux installation and analysis passed; C2's known lint failures stopped the job, so headless tests were skipped on Linux. Left open: coordinator data cleanup, then a complete green CI run; Mac execution is verified.

### Coordinator note on C2 and C3 — 2026-10-06

C2 accepted. The ten failures were real: Worlds 3 to 7 are designed, not built, and name species that do not exist yet. Resolved in data, not by an exclusion list: every Worlds row now carries `built` (true for 1 and 2) and the lint skips a designed-only world's species references while still checking its catch variant. The lint prints `data lint: clean`. C3 accepted: `tools/test.sh` installed the pinned Luau 0.741 and ran 41 tests in 0.01 s on the coordinator's Linux box as well as on the Mac. Both are marked done in the queue. The next green CI run will confirm the whole chain (analyze, lint, tests) on the runner.

## C4 — 2026-10-06 — review

Implementation: `cbc22ddbb48ce28a51befdbdf6ee510a2b2209c0`.

Added `tools/balance.py`, reusing C2's TableReader, and generated `Balance-Report.md`: two world tables, catch/tier mix, crew seats, slot unlocks, income including growth, continuous versus daily-offline timing, outliers and comparison with the plan. No data changed.

Measured: **102 seeded two-world simulations** (51 continuous, 51 daily); every run completed both worlds. Median World 1 first module: **1.5 active minutes**; ship: **43.3 continuous minutes**, or **1444.8 wall minutes / 34.8 active minutes** with one 30-minute session per day. World 2 ratios exactly match **1.6× Scrap / 1.5× assembly**. Saved report matches stdout and its input fingerprint matches the rebased branch. Invariant checks passed for completion, time ordering, unique seats, slot limits and offline payout/growth caps.

Three largest flagged jumps:
- World 2 Ice Drill cumulative completion: **7.89×**, 0.19 → 1.47 minutes.
- World 1 Thrusters Scrap: **5×**, 300 → 1500.
- World 2 Ice Drill Scrap: **5×**, 480 → 2400.

Current branch verification: **0 lint failures**, **58 tests passed in 0.065 s** (the coordinator expanded C3's original 41-test suite); `analyze: clean` passed. C2/C3 were already accepted and marked done by the coordinator; preserved those states.

Left open: validate movement/decision time and the full ordered Field Notes route in playtests. The simulator's explicit special-catch/night-Warden core proxy and omitted seasonal/paid/friend/fusion effects make these baseline estimates, not player telemetry.

### Coordinator note on C4 — 2026-10-06

C4 accepted (cbc22dd, report f32110c). The simulator reads the live tables through C2's reader, the fingerprint matches, and every invariant holds. Verdict on the flagged jumps, with no data change:

- **Thrusters and Ice Drill at 5x the previous module's Scrap** are cost ratios, not time spikes. In World 1 the completions land at 1.5, 4.4 and 9.2 active minutes: a gentle climb with the first module well inside the five-minute target. Income rises as fast as the costs (240 to 771 Scrap/min by Thrusters). Kept.
- **Ice Drill at 7.89x the previous completion time** is relative to 0.19 minutes: the carried crew finishes the Heat Shield in 12 seconds. The real finding is the opposite of a spike. World 2 opens too fast and finishes faster than World 1 (35.8 against 43.3 continuous minutes), because the crew, slots and savings carry over and earn about 3,100 Scrap/min from the first second. World 2 should feel like a step up, not a victory lap. Card C7 now asks for a proposed World 2 curve keyed to the carried income; the change waits for that and a cold playtest.
- **World 1's ship at 43 continuous minutes** against the plan's two to three hours is a floor: the simulator leaves out search and decision time and the ordered Field Notes route, as the report says. The cold playtest decides whether Scrap moves.


## C5 — 2026-10-06 — review

Implementation: `116a72f`; claim: `01b30fd`.

Extracted pure selection to ReplicatedStorage.Shared.FusionMath. ServerScriptService.Server.Services.Economy keeps its existing ranking, argument/profile refusals and every mutation; only Fuse changed. The selector accepts already-ranked copies and the existing cap, preserving NotEnough/MaxLevel precedence, higher-level exclusion and resting/seated/companion/habitat preference. Added WeeklyMath epoch/wrap/reset/override/limited/current coverage and the missing pre-Elder growth edge.

Measured: **58 → 71 tests**, **9 specs**, **0 failures**, **0.030 s**; analyze clean; data lint clean. Reviewed the Economy diff: only selection inside Fuse changed. BadArgs/NoProfile remain the unchanged service's responsibility; selection's two refusals are tested. No balance changes or Studio operations.

## C6 — 2026-10-06 — review

Implementation: `1b07b06`; claim: `3189257`.

Added **17 documented rule groups** for numeric keys, dense orders/rotations, traversal references, mount seats, habitat worlds/capacity/footprints/caps, weekly exclusivity, seasonal windows/species/overlays/quests/rewards, shop uniqueness/launch/grants/NeverSold, settings and codes. The C2 reader remains in lint_data.py; reused it unchanged. Radar.Mk2 and the live CompanionSlot4 pass are explicit allowances.

Found: **0 data problems**, **0 warnings**, **0 failures**; the exact-warning baseline is empty. **31 isolated mutations** all produced diagnostics. Data lint took **under 1 second**; suite remains **71 tests / 9 specs**, **0 failures**, **0.039 s**. Analysis clean. No game data changed. Left open: none.

## C7 — 2026-10-06 — review

Implementation: `0c3ba45`; claim: `2d6357c`.

Added fusion with passive removal and level/size/worked-time ordering; separate steady-state tables cover growth, three median resting companions, three displayed habitat aliens, every Catch Rush rank, weekly allocation and every outpost level. Default 11 seeds plus 21 calibration runs and 11 validation runs: **54 simulations, 4.38 s**; isolated-mode compatible; report matches stdout. **18 invariants** passed across three extra seeded runs. No data changed.

Measured: **159 median fusions, 636 fodder copies, 83.6% of catches consumed**. Median companion perks: catch Scrap **10%**, zone **10%**, luck **15%**. Stations exceed the 30% source threshold: **92.9% active / 98.4% offline**.

Proposal: carried income **3,917.1 Scrap/min** and savings **58,035** seed an increasing income-time curve (the first cost includes carried savings). World 2 costs **77,479 / 38,889 / 58,333 / 77,778 / 97,222**; cumulative times **5.1 / 14.3 / 28.1 / 47.3 / 69.2 min**, versus live **0.2 / 1.3 / 4.5 / 13.7 / 30.6**. World 1 is **46.7 min**: proposal **1.48×**, 1.2% below the 1.5× target.

Left open: coordinator approval and cold playtest. Full Field Notes, human search/decision time and companion luck-to-catch uplift remain unmodeled; optional source snapshots are not injected into progression. Suite remains **71 passing tests**; analyze/data lint clean.
