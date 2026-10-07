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

## C8 — 2026-10-06 — review

Implementation: `8767c2c`; claim: `490f762`.

Added the isolated-mode string lint and executable extra-lint runner. **42 dynamic families**, **264 required keys**; the full family and **36 unused-candidate** lists are in Data-Lint.md. Families resolve from their input tables/types/UI call sites, not existing string keys. Unknown families fail; optional COND_SHORT overrides respect the consumer fallback. Direct lowercase strings aliases are counted too.

Added **4 missing keys only**: LANDMARK_CrashSite, LANDMARK_CaveMouth, LANDMARK_GreatVent, LANDMARK_IceCaveMouth. No existing wording changed and no unused strings deleted.

Measured: **2 isolated mutation checks** caught an unknown family and a deleted landmark key. String lint below one second; **0 hard failures**, **36 advisory unused candidates**. Analyze/data lint clean, extra lint clean, **71 tests pass** in **0.034 s**. Left open: coordinator reviews unused candidates before deletion; lexical analysis is not proof of runtime reachability.

## C9 — 2026-10-06 — review

Audit/report: `d7c406f`; claim: `751ca21`. Guard commits, one service each: Catching `0280159`, Habitats `6518f19`, Companions `df0230c`, HomeBuild `97b2295`, Mail `9d027bb`.

The audit resolves **108 remotes / 58 handlers**, including literal initializer arrays, aliases and remote-name wrappers. **0 missing server counterparts**, **0 unused/unheard remotes**. Fixed **3 missing rate limits** (CaptureCancel, ClaimHabitatIncome, GetAllCompanions) and **2 checks after profile reads** (GetHome, GetMail). Existing enum checks in Shop/DailyQuests and Social's explicit yes/else-no normalization are recognized, not changed. Capture timestamp sanitization remains intact.

Measured: **10 isolated handler regression checks** prove allowed-call return/effect parity and blocked-call state protection; **2 audit mutations** detect an absent server remote and removed limiter. Deterministic Remotes.md regeneration. Analysis clean after each service commit; **71 headless tests pass**, data and extra lints clean. Final audit: **0 guard warnings**.

Left open: argument/control-flow inspection is heuristic, not a security proof. Rate rejection uses each endpoint's existing neutral response shape; no Studio operations.

## C10 — 2026-10-06 — blocked, review

Claim: `59c9b28`. No implementation or save behavior changed.

The card requires preserving current behavior while proving a future-version save is left alone. PlayerData.migrate skips version steps for versions above 15, but unconditionally fills missing top-level fields from template afterward. These requirements conflict for a future save with absent current fields.

Reproduction: executed the unchanged helpers/template/migrations/migrate under the pinned Luau interpreter with live Config, Jobs and Settings inputs. `{version = SCHEMA_VERSION + 1, marker = "future"}` retains its identity/version/marker but grows from **2 to 29 fields**, including scrap and home. An assertion that such a save is untouched would fail today; adding an early return would change production behavior beyond the allowed move.

Left open: coordinator either explicitly authorizes a future-version early return (then test it) or revises (e) to pin today's fill-only behavior. No ProfileSchema extraction or partial suite was committed, per the blocker instruction. Existing **71 tests** and all lints remain green; analyze clean. No DataStore or Studio access.

## C11 — 2026-10-06 — blocked, review

Claim: `4994601`. No UI source or partial lint changed.

The stated zero-offset baseline is false: `src/client/UI/AliensScreen.luau:688` uses `UDim2.new(CELL_W, 0, 0, cellPx)` for CellSize; line 689 uses `UDim2.new(CELL_GAP, 0, 0, gapPx)` for CellPadding. Values derive from a nonzero AbsoluteSize. UI-Playbook.md line 102 expressly permits pixel-derived grid heights to prevent ScrollingFrame canvas feedback.

Measured: **2 existing forbidden constructor calls** under the card's literal rule. The card allows baselining colours only, and its file list excludes AliensScreen and the Playbook. A strict offset lint would fail today's tree; exempting these calls without changing the card would weaken its rule. Per the blocker instructions, neither route was taken.

Left open: coordinator authorizes the documented grid exception in C11 or changes the grid first. Then implement offset/font checks, colour baseline and silent-tap audit. No colour/sound audit results are claimed. Existing **71 tests** and all current lints remain green; analyze clean.

## C12 — 2026-10-06 — review

Implementation: `1801d10`; claim: `f960271`.

Added an advisory isolated-mode TESTING.md lint: **36 documented commands**, all registered; **373 quoted UI candidates** after documented code/log exclusions. Generic caller-supplied templates cannot mask arbitrary text. **2 isolated mutations** detect an unknown command and stale text. Runtime under one second; **71 tests pass**, analyze/data/extra lints clean.

Fixed **14 occurrences / 13 replacements**: complete Puffpuff tutorial instruction; Hull Frame completion exclamation; Settings glyph `=`; full fusion refusal (twice); weekly chip Aurora; elsewhere chip Frostbyte; full Spectral catch example; separate Visitors heading/empty line; full no-friends text; full wave-cap text; full World 1 unpublished-flight toast; seasonal chip Spectral; home weekly subtitle uses World 1 instead of its long name. Only TESTING.md wording changed, never strings or behavior.

Left **4 advisory excerpts**: milestone 2 `Night · ...` is a partial clock; milestone 16 `off` is a log fragment; milestone 21 `welcome` is typed code input; milestone 42d `Welcome home` is developer-authored mail. These are not proposed game-string fixes. The checker covers wording, not stale historical milestone behavior or numerical claims; those still need coordinator review.

## C13 — 2026-10-07 — review

Implementation: `78da295`; claim: `96779ed`. Added `tools/deadcode.py` and reproducible Dead-Code.md, with a disposition for every candidate. No game code/data changed.

Measured: **35 public API candidates, 10 catalog routing gaps, 36 strings; 0 icon, sound or remote candidates**. Runtime **3.02 seconds**; repeat output identical. Two isolated probe cases detected an unused export and retained an aliased callback reference. **71 headless tests pass**; analyze/data/extra lints clean.

Left open: lexical references are conservative, not proof of safe deletion. Same-named members can hide candidates, data ids conservatively retain icons, and sound id zero is not considered unused. Internal API callers must remain intact. CompanionSlot4 already has a live pass reader despite lacking a Launch/Grants route.

Priorities: resolve catalog exposure/grant intent; review unnecessary public exports with callback/Studio usage; review unused labels while retaining planned future-world text. All proposed changes remain coordinator decisions.

## C14 — 2026-10-07 — review

Implementation: `5d5b6fb`; claim: `c105e76`. Added `tools/perf_report.py` and Performance.md; no game changes or Studio operations. Runtime **0.35 seconds**; deterministic repeated output. **4 mutation checks** detect an unknown connection and part, particle and loop budget crossings. **71 tests pass**, analyze/data/extra lints clean.

Inventoried **16 client frame connections, 0 server** with cadence, loops, bounds, allocations and suggestions. Eight-player scenario: **112 density-target wild records (not a cap), 40 companion records / 24 drawn, 9 camp workers, 6 habitat displays, 16 material nodes**. Scoped fallback parts: **Home 94, World 1 408, World 2 347**; imported meshes, avatars and transients are explicitly excluded/itemized. World 2 module ids have no Camp.Modules placeholder entries.

Requested Shower+Rain: **196 particles/s, approximately 103 steady alive**; two worst weather sheets plus Shower conservatively model **387.2 alive**. WeatherParticleMax warns; it does not clamp. Forced transitions and burst effects lack a global ceiling.

Top priorities: cache companion raycast exclusions (currently allocated every active frame); bound global spawn/visible-animation work (hidden wild models still move); measure imported scenes before visual polish and pool sighting trail effects (up to roughly **81 puffs/lights** in the catch-up model). Numeric scenarios are below budgets, but actual global parts, spawns and particles cannot be certified from these inputs. Callback annotations are reviewed source notes, not a general call-graph analyzer.

### Coordinator note on the C5 to C14 batch — 2026-10-07

Accepted: C5, C6, C8, C9, C12, C13 and C14. The fusion move kept every test green and C9's five guards were read line by line: each refusal returns before any state is cleared, so a refused call loses nothing.

C7: the proposal is declined in shape, kept in method. Its first module (77,479) cost twice its second (38,889) to soak up the savings, which a player reads as a bug. The coordinator ran `tools/balance.py` at 51 seeds on rising curves and applied 12,000 / 24,000 / 42,000 / 68,000 / 120,000: World 2 now takes 61.3 continuous minutes against World 1's 42.6 (1.44x), the savings snap on the first two modules, each step after rises by 1.6 to 1.8x, and a once-a-day player finishes World 2 in about two days, as for World 1. The report is regenerated from the live data.

C10 and C11 are reopened with decisions under each card: the future-save early return now exists (and the server refuses to own such a save), and the Playbook's grid exception is allowed on marked lines only.

Left for the polish pass: C8's 36 unused string keys and C13's catalog findings. C12's four advisory lines are text a player types (a promo code, a mail line), correct as written.

