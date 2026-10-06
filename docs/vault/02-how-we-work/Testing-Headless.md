# Headless shared math tests

Run `./tools/test.sh`. It uses Python 3's standard library to bundle sources and invokes the official **Luau 0.741** interpreter, without Studio or third-party test libraries. The script prints every result, the test count, and interpreter runtime (including module loading; excluding download and bundle generation). Any failed assertion, load error or empty suite exits nonzero.

`tools/ci/install-tools.sh` installs the checksum-pinned release from `luau-lang/luau` into `$HOME/.local/bin/luau-0.741`. Full CI installation remains Linux x86_64. `--luau-only` also supports macOS arm64/x86_64, allowing `tools/test.sh` to bootstrap the interpreter if missing. Existing Rojo and luau-lsp pins remain unchanged. Update both scripts' interpreter versions and the installer's archive hashes together when upgrading. No workflow change is needed: Checks already invokes both scripts. The existing cache key covers Rojo/luau-lsp; Luau's versioned archive filename prevents confusing interpreter releases even if the download is not cached.

## How the loader works

The Luau CLI sandbox cannot read files directly. `tools/test.sh` packs unchanged `src/shared/**/*.luau` and `tests/*.luau` source into ignored `.cache/headless/sources.luau`. `tests/run.luau` builds a path tree with `Name` and `Parent`, then compiles each requested source with `loadstring` and a per-module environment. `script.Parent` sibling lookups therefore resolve to the same files as in Roblox. A module cache preserves require identity; circular dependencies and missing nodes fail. `game:GetService("ReplicatedStorage").Shared` maps to `src/shared`; every other service fails explicitly. No production implementation is copied into a mock or rewritten.

The runner discovers and executes every `tests/*.spec.luau`, offering `describe`, `it`, and `expect(...).toEqual`/`toBeClose`. Assertions are protected individually so failures do not hide subsequent tests. `TZ=UTC` makes calendar fixture construction independent of the Mac's local zone.

## Coverage

| Spec | Tests | Main boundaries |
| --- | ---: | --- |
| Capture | 14 | Triangle wave at zero/quarter/half/full period; negative time/zero speed; both Perfect and Good edges; near misses inside/outside the margin; zero-amplitude/zero-phase drift and both clamps |
| Growth | 6 | Hatchling, one tick before Grown, Grown, Elder; Next and SecondsToNext including final nil |
| LeaderboardMath | 7 | Period start/id/store key before/on/after reset hour and weekday, next week, NextReset |
| OutpostMath | 7 | Eligible material yield, clamped levels and upgrade limit, production before/at collection, one hour, cap and beyond; round-robin conservation |
| Economy | 7 | Common level-one speed, Grown bonus, offline income at negative/zero/below-cap/cap/beyond-cap |

C3 originally grouped OutpostMath with reset tests. Ethan clarified that OutpostMath should cover its existing production/cap API and only LeaderboardMath should cover weekly resets.

Numeric game inputs and expectations come through `require` from live data tables. Fixtures derive neutral values and fractions from the Common baseline and Hatchling threshold; growth boundaries use stage thresholds minus the configured income tick (currently 0, 7199, 7200, 86400). Calendar boundaries use the configured reset weekday/hour and UTC date functions, independently of the production reset formula. No threshold or expected payout is copied into a spec.

## Verified 2026-10-06

41 passed, 0 failed across five specs; interpreter runtime **0.019 seconds** on the Mac. In separate temporary copies, breaking Capture's triangle formula produced exit 1, and deleting all specs also produced exit 1. No game files changed. CI currently stops at C2's ten known data-reference failures before executing the test step; the installer runs earlier and can still be verified there.
