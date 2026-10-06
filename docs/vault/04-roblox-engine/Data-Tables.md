# Data tables: shapes that code can walk safely

Rules learned the hard way, for `src/shared/data`.

## Numeric-row tables never gain string keys

`data/Radar.luau` holds tier rows `[0]..[3]`. The client's `Radar.luau` finds the top tier with `for tier in pairs(tiers)` and compares the keys as numbers. Adding a string key (`Mk2 = { ... }`, milestone 40) made that loop compare a number with a string and the whole client failed to boot at the Radar require: every module after it (compass, waypoint, sightings) never loaded. Studio showed it on the first play; CI and the data lint did not, because neither executes client code.

- Put extra settings for a numeric-row table in their own table (`data/RadarMk2.luau`) or under a single documented key that every loop skips, and grep for `pairs(` over that table before adding the key.
- A loop over a mixed table checks the key's type: `if type(key) == "number" and key > best`.
- `ipairs` stops at the first hole and never sees `[0]`, so it is not a fix for a table that starts at zero.

## Fixed-shape tables are not dictionaries

`data/Gear.luau` carries `BaseWalkSpeed` next to its rows and `data/PowerUps.luau` is one row per key; the services pick the rows out by id into a typed map (`GEAR_ROWS`, `DEFS`) rather than casting the whole table. A new row needs a line in that map or it stays invisible to the code (see the comment above `GEAR_ROWS` in `Shop.luau`).

## Lists stay dense

Spawn lists, rotation lists and orders (`Overlays.Order`, `Tiers.Order`, `Weekly.Rotation`) are walked with `ipairs`; `nil` in the middle of one hides everything after it. An optional entry is a field on the row (`weather = nil`), never a hole in the list.

## What catches it

Only a Studio play (or a client in the multi-client test) loads client modules. The headless suite (`tools/test.sh`) runs the shared maths; it can require a data table but not a client module. A boot error shows in Output as `Requested module experienced an error while loading` naming the require in `Client`; the Mac's first-play check is the net, which is why every block starts with "if anything errors at boot, send the first Output line and stop".
