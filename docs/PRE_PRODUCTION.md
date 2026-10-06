# Pre-production checklist: what is still missing before the build

This is the gap list between the design in `GAME_DESIGN.md` and a buildable project. It is written so that a build prompt to Claude Code can start from it. Sections are ordered by what blocks what.

---

## 1. What a code-based build can and cannot produce

Be clear about this before the first prompt, because it shapes the division of labor.

**Claude Code can write, inside this repo:**

- All game logic in Luau: server systems (spawning, catching, stations, modules, offline accrual, saves, events, shop, quests, spins, Peddler), client systems (HUD, screens, capture bar, radar, camera, tweens, sounds), shared data tables, and remote event wiring.
- A Rojo project that syncs the repo into Roblox Studio, with the folder structure, module layout, and build configuration.
- The entire UI, constructed in code from a theme module, including every screen in the design doc.
- Placeholder geometry and placeholder aliens built from parts in code, so every system can be tested before any art exists.
- Balance tables (species, spawn rules, module costs, lures, Peddler stock, spin segments, quests, gifts, shop catalog) as data files that can be edited without touching logic.
- A simple economy simulator to sanity-check pacing.

**Claude Code cannot produce:**

- 3D models, meshes, textures, rigs, or animations. Aliens, ship modules, biomes, props, and gear need to be modeled (Blender or Studio) or bought on the Creator Store.
- Sound effects and music. These need to be made, bought, or picked from Roblox's audio library.
- UI icons. One cartoon icon pack from the Creator Store, picked once.
- Testing in Studio. Claude Code cannot open Studio, run the game, or see the screen. The team runs it, reports what happened, and sends screenshots or error output.
- Publishing, the Experience Questionnaire (age rating), thumbnails, icon, and store page.

**The workflow that follows:** the repo holds code and data; Rojo syncs it into a Studio place; the team builds art in Studio or imports it, tests with Studio's multi-client test, and reports back. Every design number lives in a data table so tuning never needs a code change.

---

## 2. Decisions to lock before the first build prompt

From `GAME_DESIGN.md` section 19, plus a few the build needs. Each needs a one-line answer.

| # | Decision | Recommendation | Needed by |
|---|---|---|---|
| 1 | Game name | Undecided; working title AlienGame in code | Day 1 (place name, strings) |
| 2 | Art style | Answered: smooth low-poly | Before any modeling |
| 3 | Number of jobs at launch | Answered: 3 (Gather, Build, Spark) | Day 1 (data tables) |
| 4 | Companions following the player | Answered: yes, 3 slots | Day 1 |
| 5 | Splicing | Answered: none; Secrets come from codex Sets | P1 |
| 6 | Theft or borrow | Answered: borrow only; raid parked | P2 |
| 7 | World order | Answered: Verdant, Frostbyte, Neon Grid | P1 |
| 8 | Event rerun policy | Answered: monthly Vault Rotation plus annual reopening | P1 |
| 9 | Permanent personal luck pass | Answered: not at launch | Launch |
| 10 | Mounts use a companion slot | Answered: yes | P1 |
| 11 | Scrap for Robux | Answered: never | Day 1 (shop data) |
| 12 | UI font | Answered: Fredoka One | Day 1 (theme module) |
| 13 | UI palette (six colors) | Answered: stud dialect, playbook values | Day 1 |
| 14 | Icon pack | Answered: placeholders until chosen | First UI pass |
| 15 | Who owns the Roblox group and the experience | Answered: co-owned by both team members | Day 1 |
| 16 | Free station slot growth | Built as the default on 2026-10-05: slot 2 on every station unlocks with the Thrusters, slot 3 with the Nav Array (`unlocksSlots` in `Modules.luau`); passes would add a 4th and 5th. The simulator (section 3.3) showed one slot per station leaves 100+ aliens idle by module 5 and makes the Nav Array the only Scrap-blocked module. Change the two numbers in the data table if the team prefers another curve | Confirm or change |

Answers so far are logged in `docs/vault/07-alien-game/Decisions.md`.

---

## 3. Design gaps that still need to be written down

These are specified in spirit in the design doc but not as data a build can consume.

### 3.1 The first eight minutes, beat by beat

The tutorial decides D1 and it is not scripted yet. It needs a step list with: trigger, what the player sees, what they must do, what unlocks, the exact text, and the time budget per step. Proposed skeleton:

| Step | Time | Beat | Unlock |
|---|---|---|---|
| 1 | 0:00 | Crash landing cinematic, 8 seconds, skippable after the first time | |
| 2 | 0:10 | "Drag 3 wreck plates to the frame." Player gathers by hand. Ship bar appears at the first plate | Ship bar |
| 3 | 1:00 | Mossbop waddles up, "!" bubble. First capture, zone 40% wide, cannot fail (ticker slows near the zone) | Capture bar, codex |
| 4 | 1:30 | Mossbop auto-walks to the Gather station and takes over gathering. Timer visibly drops | Stations |
| 5 | 2:00 | "Build a panel." Player holds a button. Puffpuff appears, same ritual, takes over building | Second job |
| 6 | 3:00 | Scrap counter appears with "+" text. First module hits 50%. "Catch 3 more aliens while they work" | Scrap |
| 7 | 3:30 to 6:30 | Free catching in the Meadow with the Nearby panel on. A Rare (Sparkfox) is guaranteed to spawn once in this window | Nearby panel |
| 8 | 7:00 | Module 1 completes. Camera pan, part snaps, bass hit. Field Notes step 1 appears with Speed Boots as the reward | Quests, gear |
| 9 | 8:00 | "Thrusters need Glowroot from the Forest." Waypoint set. Peddler lands for the first time. Welcome Week gift 1 pops | Peddler, gifts |

The Growth Playbook (section 6) tightens this to a five-minute script against the tutorial steps T1 to T7: first catch by 0:45, first module by about 4:30, Welcome Week gift 1 at the module payoff instead of minute 8, nothing else (Peddler, Shower, shop, notification card) before minute 5. That needs a tutorial-only assembly time of about 90 s in data (decision 18).

### 3.2 Data tables to author

Each of these is a file the build reads. The design doc has the shape; the full rows need writing.

- `species`: id, name, three-word concept, tier, jobs and levels, biome, condition, voice line id, idle animation id, ride trait, mesh id (placeholder until art exists).
- `spawns`: per biome and condition, the weighted list of species and the density target.
- `modules`: per world, five rows of Scrap cost, key material and count, base assembly seconds, required job.
- `keyMaterials`: id, world, biome, condition, drop count per node, node respawn time.
- `lures`: three tiers, Scrap cost, zone width bonus.
- `gear`: tiers, cost, speed multiplier, unlock source.
- `radar`: tiers, range, features, cost.
- `powerUps`: id, effect, duration, stack rule, sources.
- `peddler`: stock pool with weights and Scrap prices, restock seconds.
- `spins`: segments with exact odds summing to 100%, reward per segment.
- `gifts`: seven Welcome Week rows.
- `quests`: daily and weekly templates, Field Notes steps per world with trigger conditions and rewards.
- `codexRewards`: first-catch Scrap by tier, page milestones.
- `luck`: base tier shares, cap, source bonuses.
- `shop`: every SKU with type, price, product id placeholder, PolicyService flag, earnable alternative text.
- `events`: schema for an event config (start, end, spawn overrides, overlay, weather, banner, quest track).
- `strings`: every player-facing string, keyed, for translation.

### 3.3 Economy sanity check

`tools/econ_sim.py` runs a bot through World 1 on the real data tables (read by `tools/luau_tables.py`) with the server's own rules: tier roll by share, species by biome and condition, auto-assign to the station slots, Scrap per second from work speed, three gates per module, assembly at player speed plus the matching crew. It reports when each module completes and how long the bot was blocked by Scrap, by key material, or by assembly. The target is that the key material is the usual blocker and Scrap almost never is. Re-run after every number change: `python3 tools/econ_sim.py [--slots 3] [--catch-every 60] [--trace]`.

First run (2026-10-04, median of 20 runs, continuous play, one catch attempt every 30 s, one slot per station):

| Module | Done at | Blocked by key | Blocked by Scrap | Assembling | Scrap/s at done | Aliens caught |
|---|---|---|---|---|---|---|
| Hull Frame | 1m | 0m | 0m | 0m | 3.0 | 2 |
| Thrusters | 5m | 3m | 0m | 1m | 6.9 | 5 |
| Life Pod | 16m | 7m | 0m | 3m | 9.0 | 18 |
| Nav Array | 40m | 1m | 10m | 3m | 12.4 | 54 |
| Engine Core | 1h17m | 21m | 4m | 6m | 24.0 | 116 |

What it says:

1. **Key material is the blocker on four of five modules**, as intended: night-only crystals hold the Life Pod about 7 minutes and the Warden holds the Engine Core 20 to 50 minutes depending on pace.
2. **The Nav Array is the one Scrap-blocked module.** With one slot per station, income caps near 12 Scrap/s, and 12,000 Scrap takes about 10 minutes of waiting with nothing to do but catch duplicates. Either the Nav Array's Scrap cost drops (8,000 keeps the curve), or the second station slot arrives before it (see 3).
3. **Slots never grow in the free loop.** `StationStartSlots` is 1 and nothing in the design unlocks slot 2 or 3 except passes. By the Engine Core the bot has caught over a hundred aliens and three of them work; the rest are idle until fusion (P1). Three slots per station move the Nav Array to 25 minutes and remove the Scrap block entirely. Proposed: slot 2 on every station unlocks with the Thrusters, slot 3 with the Nav Array; passes then add a fourth and fifth. Decision 16 in section 2.
4. **World 1 runs about 1h15m to 1h40m of continuous play** against the 2 to 3 hour target. The bot does not walk to hidden spots, craft lures or play the Field Notes steps, so this is a floor. Re-run after the biomes milestone and again after the first cold playtest before touching any cost.
5. Pace barely matters above one catch every 30 seconds; a casual player (one a minute) finishes about 25 minutes later, almost all of it waiting for Rain and Night windows. That is the intended shape: the clock gates, not the grind.

### 3.4 Sound list

A named list of every sound the game plays, about 40 at launch: six UI sounds, one reveal jingle per tier (six), one catch-hit and one miss, a Perfect stinger, a ship-part snap, a module-complete fanfare, a launch sequence, a Meteor Shower horn, a Peddler landing, a toast ding, a Scrap tick, weather ambiences for Rain and Clear, day and night ambiences, three Hoverboard sounds, and one voice line per species (fifteen). Picked or made by the team; referenced by id in a table.

### 3.5 Art list for World 1

The minimum art the vertical slice needs, in priority order: a ship with five visibly separable modules; the Meadow biome; 6 species meshes with one idle animation each; a station prop; a wreck pile; Speed Boots; the Hoverboard; UI icon pack. Everything else can be placeholder parts until the slice is fun.

---

## 4. Technical decisions for the build

Proposed stack, chosen for a two-person team working from a repo:

- **Rojo** to sync the repo into Studio. One `default.project.json` mapping `src/server`, `src/client`, `src/shared` to ServerScriptService, StarterPlayerScripts, and ReplicatedStorage.
- **Luau in strict mode** with a shared types module.
- **No heavy framework.** Plain ModuleScripts with a tiny service loader, and a thin `Net` wrapper around RemoteEvents and RemoteFunctions with rate limiting and type checks on the server.
- **ProfileStore** (or an equivalent session-locked wrapper) for player saves, one key per player, autosave every 3 minutes, schema versioning with migration functions from day one.
- **Server authority** for everything that touches Scrap, catches, spawns, timers, and purchases. The client renders and animates; it never decides outcomes.
- **Aliens as lightweight records** replicated through attributes on tagged parts, rendered on the client with AnimationController, spawned only near players, StreamingEnabled on.
- **Configs** for live-tunable values and **Experiments** for A/B tests on the first eight minutes.
- **MarketplaceService** receipt handling with idempotent purchase processing and a purchase log in the save.
- **PolicyService** checked on join and cached; every random purchase and luck product respects it.
- **Analytics** through Roblox's AnalyticsService custom events plus a funnel for the tutorial steps.

### Save schema v1 (shape, not final)

```
Profile = {
  version = 1,
  scrap = 0,
  aliens = { [uid] = { species, level, overlay, caughtAt, slot } },
  stations = { Gather = { slots = 1, assigned = { uid } }, Build = {...}, Spark = {...} },
  modules = { [worldId] = { [1] = { scrapPaid, keyPaid, progress, completedAt } } },
  world = { current = 1, unlocked = { 1 }, outposts = { [worldId] = { level, lastCollect } } },
  codex = { [speciesId] = { count, bestOverlay, firstCaughtAt } },
  gear = { boots = false, hoverboard = false, glider = false, radar = 0 },
  companions = { uid, uid, uid },
  quests = { daily = {}, weekly = {}, fieldNotes = { [worldId] = step } },
  gifts = { daysPlayed = 0, claimed = {} },
  spins = { free = 1, banked = 0, lastFree = 0 },
  luck = { pity = 0 },
  purchases = { [productId] = count },
  lastSeen = 0,
}
```

### Place structure

- `World1` is the start place, public, MaxPlayers 8, PreferredPlayers 6.
- `World2`, `World3` are non-start places, "Secure within universe only".
- `Home` is a non-start place loaded per visit from the owner's profile.
- `PrivateWorld1` and so on are the same places as the public worlds, reached through reserved servers from the Party flow.

---

## 5. The vertical slice (build this first, two to three weeks)

Prove the loop is fun before building the roster. Scope:

- Meadow biome only, with day and night.
- 6 species: Mossbop, Pebblet, Puffpuff, Buzzlebee, Sparkfox, Thunderhog (Common, Common, Common, Uncommon, Rare, Epic).
- Capture bar with tier difficulty, lures tier 1, hidden kindness.
- Two jobs (Gather, Build), one station each, auto-assign. Spark arrives with module 2.
- Two modules with all three gates, the ship bar, the assembling ship.
- Scrap, offline accrual, offline assembly.
- Codex with first-catch payouts and shadow silhouettes.
- Nearby panel and Radar Mk1.
- Speed Boots and the Hoverboard.
- The Peddler.
- The HUD and four screens: Shop (stubbed), Aliens, Codex, Ship.
- Saves with session locking.
- Tutorial steps 1 to 8.

Exit criteria: three people outside the team play it cold, finish the tutorial without help, and come back the next day on their own. If they do not, fix the first eight minutes before adding anything.

---

## 5b. Build status (2026-10-05)

What the branch `claude/alien-system-research` holds, by milestone, and how far each was verified in Studio through the Mac session. Test scripts per milestone are in `docs/TESTING.md`.

| # | Milestone | Studio test |
|---|---|---|
| 1 to 2 | Bootstrap, saves (memory profiles in Studio), meadow, spawns, capture bar, reveal | pass |
| 3 to 4 | Camp, Scrap income, materials, ship modules, Forest and Cave, condition-gated nodes | pass |
| 5 to 6 | Menu stack, Aliens, Codex, Nearby, catch Scrap, lures, Scrap shop, Speed Boots, Peddler, power-ups, luck | pass |
| 7 to 8 | Field Notes, shrine, reserved Warden; the tutorial | pass |
| 9 | Welcome Week gifts, spin wheel, Meteor Shower | pass |
| 10 | Radar Mk1 minimap, blip waypoints | pass |
| 11 | Sound hooks (placeholder ids), particles, ambience, camera pan, crash opener | pass |
| 12 | Mesh models in the world (placeholder fallback) | pass with the 53 coloured models installed (2026-10-06); meshes stood 0.7 studs high at the bob's low point, fixed and re-checked at 0.0 |
| 13 | Settings, preferences, analytics funnel | pass |
| 14 | Robux launch shop (Starter Pack, four passes, boosts, server luck) | pass with grants; receipts wait on live ids |
| 15 | World 2 Frostbyte data and blockouts, one place per world, the launch | pass (15b, 15c on World 2; 15c step 4 waits on a World 1 Connect) |
| 16 | The Heater rule for blizzards (World 2) | pass |
| 17 | Environment props: generated scenery and camp meshes, builders swap them in, map-dressing workflow | pass on both worlds with the installed meshes (the Heater disc invisible under its lamp mesh) |
| 18 | Outposts (lazy production, collect, upgrade) and the Star Chart (fly back to unlocked worlds) | pass on World 2; step 5 waits on the World 1 place |
| 19 | Group-join reward, referral rewards, rejoin nudges, notification opt-in card (Growth Playbook) | pass (group step needs a group id; session-2 ask needs real saves) |
| 20 | Weekly "Catches this week" leaderboard | pass single-client; multi-client and the shared store wait on Ethan |
| 21 | Daily and weekly quests with a reroll, promo codes | pass |
| 22 | Look pass L1: lighting and atmosphere looks per world and condition, tweened on the client | pass, both places, after three fixes (foreign effects, grey fog, chat in built places) |
| 23 | Friend Boost: +5% Scrap and luck per friend in the server (cap 3), HUD chip, friend analytics | step 1 pass; friends need a multi-client test |
| 24 | Look pass L3 particles: weather sheets per condition following the camera | pass; rain visibility waits on real particle textures (L5) |
| 25 | Size rolls: Tiny to Huge on every spawn and grant, scaled models, Scrap multiplier, reveal stamp | pass (steps 1 to 3); the 50-spawn mix and eggs not sampled |
| 26 | Catch variants: the cast-and-reel bar (Tidepool) and the rooftop chase (Neon Grid) as data rows over the one bar; drifting zone, hold-and-release, encounter clock; `/variant` to force one | pass (steps 1 to 3, 5; step 4 partial: multi-round drift seen on Ra-dish, the drift-miss scoring is a code check) |
| 27 | The five-minute script: Welcome Week gift 1 opens as the first module's payoff, Peddler and Shower banners held on the client until the tutorial ends (`Tutorial.Script`) | pass (steps 2 to 5); the rejoin step waits on real saves |
| 28 | Growth stages: aliens at a station grow Hatchling, Grown, Elder by time worked (offline counted, capped), a speed bump and a size step per stage, stage chip and countdown on the Aliens screen, grew toasts, `/grow H` | pass (steps 1 to 4, 6); the card chips were widened after the run; the away-time line waits on real saves |
| 29 | Look pass L3 hero landmarks: five set pieces from Blender (`tools/blender/heroes_base.py`), placed from each layout's `Landmarks` list with scatter clearance; the hero Shrine replaces World 1's ring | pass on both worlds (2 of 2 placed each, scatter clear; World 1's ring replaced by the hero, World 2's kept) World 2 step 3 pass (GeyserVent, IceCaveMouth, shrine ring; all meshes in the saved place). |
| 30 | The compass strip: cardinals, ticks, heading pill, coloured diamonds for the camp, the waypoint, the radar target, the Peddler, the shrine and the hero landmarks, a "Camp 42m" line; the HUD's centre column moved under it | pass (strip, stacking, camp marker, label order); the World 2 landmark diamonds pass; the shrine and target markers need a hand check; the shower toast overlapped the Friend chip, fixed World 2 pass (camp and shrine diamonds at their distances; the line keeps its fixed priority, so the Peddler names it over a nearer shrine while it visits, by design). |
| 31 | Look pass L5 icons: 48 icons and 3 particle sprites rendered from Blender (`tools/blender/icons.py`), uploaded as Decals (`upload_assets.py --images`), keyed in `data/Icons.luau`; `Builder.icon`, button icon faces, the Scrap pill, the shower banner and the weather sprites use them, letters stay until an id exists | step 1 pass (fallbacks unchanged); the image upload is part of the last visual pass |
| 32 | Icons on the remaining surfaces: power-up squares, shop rows, gift tiles, the Reveal's rarity badge, node nameplates and material toasts, all optional until the ids exist | built; Studio check after the image upload |
| 33 | The VFX pass: soft sprites on every emitter, sunburst rays and sprite confetti on the Reveal, a Perfect flash, tier auras (light and glow) on rare spawns | auras pass; the flash needs a human Perfect; sprites wait on the last visual pass |
| 34 | The Catch Rush: a 90 s shared round every 10 min on the wall clock, wild catches counted, top three paid by rank plus participation, winner announced; chip, banner and result toasts; skipped during a shower | pass (steps 1 to 3, 5, and 6 on a fresh profile); singular toasts fixed; 4 and 7 need multi-client |
| 35 | Fusion: four spare copies of a species fuse into +1 level on the best copy (max Lv 3), Fuse button and hint on the Aliens screen, level chip, `/dupes` | pass (steps 1 to 6 after the fodder fix: a capped Lv 3 was being consumed for a plain copy; only copies at or below the kept copy's level are fodder now, both sides) |
| 36 | Companions: up to three resting aliens follow the player for everyone to see, one perk each by job and tier (catch Scrap, zone, luck), the +1 pass and Companion Tokens add slots; tap a card to follow | pass (steps 1 to 4: follower on the ground 6 studs behind, snaps after a jump and a world change, perks line fits, token and pass slots, the working-card toast, a live /follow redraw, luck +0.1 exactly); 5 needs multi-client, 6 real saves |
| 37 | Mounts: a rideable follower (Thunderhog, the Wardens, the Cosmics, Frostfang) carries the player at its tier's speed with a bigger leap; Ride and Hop off on the card; drawn under the rider for everyone | pass (steps 1 to 4 on 7248c54: 25.6 and 30.72 walk speed, 11.52 jump height, hips lifted by the seat, the mount centred under the rider through walking, turning, jumping and a world change, the arc closes with no gap, fusion keeps the ridden copy); Thunderhog's seat raised 0.4 for its quills; 5 needs multi-client, 6 real saves |
| 38 | The weekly drop: Alien of the Week on the Friday clock (limited species Vaulted outside their week, featured ones boosted), a themed weather all week (Aurora) with a week-only overlay (Spectral), Codex stamps, the HUD banner, `/week` | pass (steps 1 to 6 on ace01f8: Panpipe 4.9% and Spectral 3.3% of 61 spawns, Gloomoth and Shimmerlynx 5.4%, flips counted once each, the hold holds); the banner title clipped the name at phone width, so the name moved to the line under it with its world when the drop is elsewhere; the Codex stamp shortened so it clears the unknown mark; the Aurora reads green-teal rather than violet (a look-pass item) |
| 39 | Warden sightings: every 20 min the world's Warden walks a loop of the map in the open, uncatchable, with a trail, a server-wide banner and a compass marker; `/sighting` | pass (steps 1 to 5 on c3b4db9: 589 studs in 73.8 s, uncatchable, the hold holds, 60 fps with 54 puffs alive); fixed from the notes: the mesh surged on the server's steps (now a constant-speed walk), the puffs washed out to white (deeper hues, a dimmer light), the compass diamond took the target's blue (now the Legendary colour) |
| 40 | Radar Mk2: 250 studs, secrets as a pulsing "???" ping with a quickening heartbeat, absent rares with their condition in the Nearby panel, the Shop row unlocked by World 2, `/radar N` | pass (steps 1 to 4 on c3b4db9: the row and its unlock, the ping at 0.40 to 0.90 s beats by distance, no ping on Mk1, two "not now" rows under the disc); fixed from the notes: the swell covered the range label (1.25 now), "in a Meteor Shower" overflowed the tag ("in a Shower"), `/radar 3` granted a tier with no buy rule (refused now) |
| 41 | The developer panel: `/admin luck|shower|weather|say` for the team's user ids, to every server through MessagingService (local fallback in Studio), a gifted luck window named "the team", a notice banner | pass (steps 1 to 3 on c3b4db9 with Ethan's id, now in the data; Studio published for real, so every command made the round trip); fixed from the notes: the gifted window's toast said "bought" (its own line now) and the luck pill's word did not fit (number only); step 4 needs a published game |
| 42a | The home place: world 0 as its own place (home.project.json, data/Home layout, Worlds row 0), unlocked by the first launch (schema v10), the Star Chart's Home planet to fly to and back, every wild-world service off at home while the camp still pays | pass (steps 1 to 3 at 2caea87: the Home planet and its unlock, the scene, every wild-world service off, Build not Launch, the fly back, seated aliens earning at home); fixed from the notes: no stations stood at home (the unlock world is now the highest the ship has reached), Rain never rolled there (row 0 has it), the Ship screen's empty panel says why; open: the weekly chip clips at home and the Rush countdown chip shows there (client fixes queued), step 4 needs real saves; the locked Home planet's colour is a look-pass note |
| 42b | The house grid: rooms and furniture from `data/HomeBuild` placed on the plot's cells for Scrap through the server, a ghost preview and a build tray on the client, caps per kind, saved on the profile (schema v11) | pass (steps 1 to 4 at 2caea87: Decorate inside 18 studs, the ghost on the tapped cell, Turn, placing and its events, Taken, Not enough Scrap, the room cap, Take away, nothing on World 1); fixed from the notes: the menu column covered the tray's left edge (the tray sits bottom right now), full-cap cards stayed coloured, a Turn carried over to the next pick; the touch tap-versus-drag check needs a device |
| 42c | Habitats: a house-grid kind per world where resting aliens go on display from the Aliens screen, roam inside a fenced pad and pay Scrap per hour by tier, settled on arriving home (schema v12); `/habitat H` | pass (steps 1 to 4 at 86df5a8: the pad and its 12 posts, Display and the pill, the wander at 2 studs/s inside the inset, the full toast, Optimize leaving displays alone, the income maths and the 24 h cap, Bring back, Take away); fixed from the notes: the tray's list showed one row, not two (a ScrollingFrame's CanvasSize scales against its parent); open: a World 2 alien with no habitat of its world shows no Display button and no Display-off event is logged when a habitat is removed (fixes queued) |
| 42d | The hangar, the kiosk and the mailbox: scaled ship hulls per launched world with name plates, Spin at the kiosk opens the wheel, Mail opens the mailbox screen with claimable letters and the Visitor Book; letters from `/admin mail` to every server (schema v13) | pass (steps 1, 2, 4 and the claim at 86df5a8: hulls on the pads by launched world, the kiosk and mailbox actions at 10 studs, Claim and its events, the 21-letter cap and the scroll); fixed from the notes: every /admin command hung on an unpublished place (PublishAsync off the thread with a 5 s timeout), the mailbox showed one letter per window (the same canvas rule); step 3's /admin mail re-check queued |
| 42e | Visiting: a friend's home as a reserved server of the home place keyed by the owner (the code in a MemoryStore map), the owner's save read without a lock when away, the HomeLock preference (only me, friends, anyone), the Visit screen from the Star Chart, Wave at a displayed alien paying both through the gifts' path with daily caps, the HomeInbox for an away owner, `/visit` | contract written; building |
| 43 | The Scanner Pulse reader: while the power-up runs every wild alien in the biome shows on the radar at any range (rim markers beyond it), uncaught species resolve from their silhouettes, the ring pulses purple | queued on the Mac |

Pipeline: `tools/blender/alien_base.py` builds a blockout mesh per species (32 so far, `assets/models/`), the `import-model` skill brings one into Studio, and the renderers use a mesh when `ReplicatedStorage.Models.<SpeciesId>` exists. `tools/blender/props_base.py` does the same for scenery and camp props (`assets/models/props/`, looked up under `ReplicatedStorage.Models.Props.<Name>`); the by-hand dressing pass with the Stravant-era plugins is in `docs/vault/06-art-pipelines/Map-Dressing.md`. The order and tools of the look passes (lighting, ground, dressing, creatures, UI, store page) are in `docs/vault/06-art-pipelines/Look-Plan.md`.

**Waits on the team** (nothing else blocks these):
- Import one model by hand (File > Import 3D, `assets/models/Mossbop/Mossbop.fbx`, into `ReplicatedStorage.Models`) to finish the milestone 12 test, then the rest.
- Blender, `uv` and the MCP add-on on the Mac (`tools/setup-mac.sh`), for the next modelling pass.
- Import the 16 props (`assets/models/props/<Name>/<Name>.glb`) into `ReplicatedStorage.Models.Props` and install Brushtool 2, Redupe, GapFill, ResizeAlign and Archimedes from the Creator Store for the dressing pass (`Map-Dressing.md`).
- Developer products and game passes in the Creator Dashboard; paste the ids into `src/shared/data/Shop.luau` (all 0 now, so Buy refuses safely).
- Studio API access on the place, then `Config.UseDataStoreInStudio = true`, to test real saves and the schema migrations (v4).
- Publish the World 2 place and put its id in `src/shared/data/Worlds.luau` so the launch teleports.
- About 40 sound ids into `src/shared/data/Sounds.luau` and one icon pack (section 3.4 and the UI build notes).
- Decide the slot-pass stacking rule (decision 17 below) before that pass goes live.

**Decision 18 (taken, milestone 27): the five-minute script.** Welcome Week gift 1 opens as the first module's payoff (the Gifts screen with its "Tomorrow" line, right after the fanfare), and the Peddler's landing banner and the Shower chip and banner stay off a new player's screen until the tutorial ends. The Hull Frame's 60 s assembly already lands the first module inside four minutes of normal play, so no tutorial-only assembly time was needed. Set in `data/Tutorial.luau` (`Script`), so the beats can move without code.

**Decision 19 (open): the name.** Candidates from the playbook: "Crash Planet: Catch Aliens", "Alien Pals: Build a Rocket", "Planet Hoppers: Alien Collector". Check Roblox search for collisions before locking; no reward words in the title.

**Decision 20 (open): rejoin notifications.** Experience Notifications are opt-in and 13+ only; the ask comes on session 2 or later with our own card first, event text only (part ready, Alien of the Week, hosted Shower), three a week at most, behind a Config flag so it can be turned off for a market. Sending needs an Open Cloud key on the Mac, never in the repo.

**Decision 21 (proposed yes): world signatures.** Every world adds one verb, one special area, one super-rare through a harder bar, and one secret spot (`docs/GAME_DESIGN.md` section 8, "World signatures"). Tidepool becomes the fishing world with a bioluminescent Trench fountain; Neon Grid the rooftop-parkour cyberpunk world with robotic aliens; Dreamdrift the gravity-flip parkour world. First builds: the cast-and-reel bar and the rooftop chase as catch variants, then the special areas as layout regions with their own spawn tables and buffs. Milestone 26 built the two variants as rows in `data/CatchVariants.luau` (worlds 3 and 5 select them in `Worlds.luau`); the special areas and the double bar come with those worlds' layouts.

**Decision 17 (taken, 2026-10-06): the +1 slot pass.** Bought slots are kept as a `bonus` on each station state: a module unlock sets `max(slots, unlocks + bonus)` and the cap is `Config.StationMaxSlots + bonus`, so the pass always adds its slot on top of whatever the modules grant, now and after every later unlock. The Aliens screen draws the extra square past the cap.

**The home planet, build plan (milestones 42a to 42e; GAME_DESIGN section 10).** The home is its own place in the universe, like a world: `home.project.json` sets `WorldId` 0, `data/Worlds.luau` gains row 0 "Home" (built, no warden, no weather list, no spawn tables) and `data/Layouts.luau` row 0 (`data/Home.luau`: a small floor, the plot grid, the hangar pad, the kiosk and mailbox points, no regions, no scatter, no shrine). Every service that is about a wild world no-ops on world 0 through one shared check (`Place.IsHome()`): Spawner, Materials, Quests' Field Notes, Tutorial, Peddler, Heaters, Outposts, Sightings, the weekly spawn share, Launch's launch (the Star Chart flies home and back instead). The camp's stations still work at home (the player's aliens keep earning). Saves grow a `home` table on the profile (schema v10) with a migration.

- **42a, the home place.** The place, the Star Chart's Home entry (unlocked by the first launch, Fly there and back like a world), the plot square, every wild-world service off at home. The Mac tests the home place from `home.project.json` directly (a third Rojo project, like World 2).
- **42b, the house grid.** Prefab rooms and furniture rows in `data/HomeBuild.luau` priced in Scrap below ship parts, placed on the plot's cells through the server (one remote to place, one to remove; the client previews a ghost on the grid), the caps per kind as the capacity, saved in `profile.home.items` (schema v11); the Decorate action at the plot opens the build tray.
- **42c, habitats.** Themed enclosures per world from data (a frost habitat, a neon habitat), each showing up to N resting aliens the player assigns (never a seated worker), paying a little Scrap passively through the outpost maths (lazy, capped), habitat count as a capacity upgrade. The home renderer draws the displayed aliens roaming inside the enclosure.
- **42d, the hangar, the kiosk and the mailbox.** A scaled model of every ship launched (one per world unlocked) with the Warden silhouette in the cockpit; the spin wheel kiosk opens the Gifts screen's wheel; the mailbox holds gifts from friends and events (a `mail` list on the profile with a cap), claimed through Gifts.GrantRewards; the visitor book lists the last visitors.
- **42e, visiting.** Friends visit when the owner is online or offline: a reserved server of the home place keyed by the owner's user id (`TeleportService:ReserveServer` and a MemoryStore map from owner to access code), the owner's save loaded read-only from the DataStore when they are offline, lock levels (owner only, friends, anyone) in Settings, Wave at a displayed alien for a tiny bonus to both (through the gifts' reward path, capped per day). Needs a published home place and real saves to test; the Mac can verify the UI and the owner-online path in a multi-client run.

Open for Ethan before 42a lands in the plan rows: the home place id (a third place in the universe), and whether the first launch or a Scrap price unlocks the plot's first room (the design says the launch).

**Not built yet (P1 from section 18, after 19 to 21):** the Hoverboard model and skins, the home planet, paid spins. Growth stages were built as milestone 28 and the compass strip as milestone 30.

---

## 6. Compliance and store readiness

- Complete the Experience Questionnaire honestly; expect a rating suitable for all ages or 9+, which rules out the US 18+ DevEx rate.
- Every paid random item shows per-item odds summing to 100%, no dud outcome, live-updating odds under luck, and is hidden where `PolicyService.ArePaidRandomItemsRestricted` returns true, with a deterministic alternative shown.
- Scrap is never sold for Robux (see decision 11).
- No reward for a like, favorite or follow: there is no engine API to verify one and the practice is treated as prohibited (Growth Playbook, section 3). A group-join reward is allowed and verifiable (`Player:IsInGroupAsync`); the official referral system rewards invites.
- Real-currency equivalent beside every Robux price.
- No login streaks; gifts unlock by days played.
- A privacy-respecting analytics setup: no personal data beyond Roblox user ids.
- Voice chat off at launch (age checks and moderation burden) unless the team wants it.

---

## 7. Launch assets and discovery

- Game icon and three thumbnails showing real gameplay with the ship bar and a cute alien in frame. Roblox's 2026 algorithm demotes clickbait thumbnails and autoplays gameplay video on Home, so a 10-second gameplay clip is a launch asset, not a nice-to-have.
- A one-paragraph description that says the loop in the first sentence.
- Genre set correctly in the experience settings so the new genre sorts can place it.
- A short list of mid-size Roblox creators who cover sim and pet games, contacted with a private-server link two weeks before launch.
- Sponsored ads only after D1 is above 20%. Not because paid traffic hurts ranking: Roblox's discovery page says users first acquired from ads, curation, friends, search or social are simply not counted in the ranking stage of Recommended For You, so ads buy players, never rank (`docs/vault/01-game-design/Growth-Playbook.md`, S1). The gate stays because ad spend only returns once the game keeps the players it buys.
- What Home actually scores, per user over 28 days (verified 2026-10-05 in the Growth Playbook): play-through rate from the tile, first-play bounce under 60 s and 61 to 180 s, distinct play days in the Day 1, Day 2 to 7 and Day 8 to 28 windows, playtime capped at 60 min per day, co-play days, spend days. No official page names "the first three games played that day" or a 5-minute threshold; the 5 minutes is Roblox's onboarding advice, not a scoring rule. Design to the bounce windows and to return days, not to session length.
- Thumbnails: ship three and keep all three live; Roblox personalises per user group by qualified play-through rate. Keep text out of the bottom band. Icon tests are by hand, one change per two weeks. Name candidates and thumbnail briefs are in the playbook, section 2.
- A Discord server before launch, linked from every teaser, so the pre-launch audience has somewhere to land. The dinosaur-ranch teaser in `media/tiktok/NOTES.md` batch 3 reached 466K views and 39K likes the day before release with nothing but a Discord link and a release date.
- A release date announced in advance and one creator teaser cut from real gameplay, framed against the current number one ("this might be better than Steal an Egg"). Spectacle beats (a Warden sighting, a Meteor Shower, a ship launch) are what the teaser needs, so they are built before the trailer is cut.

---

## 8. Playtest plan

- Studio multi-client tests for every multiplayer feature before it ships.
- Weekly cold playtests with two or three kids in the target age band (with a parent present) from the vertical slice onward; watch, do not explain.
- A feedback form with three questions: what did you want to do next, what confused you, what would you show a friend.
- Funnel review every Monday: tutorial completion, time to first catch, time to module 1, D1, D7.

---

## 9. Suggested build prompt

When the decisions in section 2 are answered, a prompt like this starts the build:

> Build the vertical slice described in `docs/PRE_PRODUCTION.md` section 5 for the game in `docs/GAME_DESIGN.md`. Use Rojo with the project layout in section 4, Luau strict, ProfileStore for saves, server-authoritative logic, and code-built UI from a theme module following `GAME_DESIGN.md` section 16. Use placeholder part-based aliens and ship modules. Put every number in data tables under `src/shared/data`. Decisions: [name], [art style], [palette hexes], [icon pack asset ids]. Start with the Rojo project, the data tables, and the save system, then the capture bar, then the ship bar and stations, then the HUD.

The build will come back with a repo the team syncs into Studio, tests, and reports on. Expect three or four rounds of "here is what happened, here is a screenshot" before the slice is playable end to end.

---

## 10. Build workflow, learned from the reference videos

Seven creator videos were processed frame by frame and transcribed (`media/tiktok/NOTES.md`). They describe how small teams are actually shipping Roblox games with Claude in 2026, and they change the workflow in sections 1 and 4 in concrete ways.

### 10.1 The workspace

Three connections, all on at once:

| Piece | What it carries | Setup |
|---|---|---|
| **Rojo** | All code and data tables, synced from this repo into Studio | `default.project.json` maps `src/server`, `src/client`, `src/shared` to their services; Rojo plugin in Studio; `rojo serve` in the repo |
| **Claude Code** in the repo | Writes the code, reads the vault and `CLAUDE.md` | Run in a terminal inside the repo folder (local), or this cloud session pushing to the branch |
| **Studio MCP** | Lets Claude read and edit the live place: instances, UI trees, properties, and run installers | In Studio: AI Assistant button, three dots, Settings, MCP servers, turn on "Enable Studio as MCP server," toggle the client under Quick connect. In the Claude desktop app: Settings, Developer, Local MCP servers, toggle Roblox Studio to running. Fully restart both. The Assistant settings should show one client connected |

Rojo is for code. MCP is for the things code is bad at describing: placing a UI tree, inspecting an instance that misbehaves, running a model installer in the command bar.

### 10.2 CLAUDE.md, the one file that changes everything

A `CLAUDE.md` now sits at the repo root. It states what the project is, the rules (strict Luau, server authority, Scale not Offset, one currency, data in tables, strings in a table), the folder layout, how to run and test, and where the vault is. Every session reads it automatically, so the rules never need repeating.

### 10.3 The knowledge vault, inside the repo

The vault is what makes "train Claude on good UI" repeatable. The reference creator keeps it in Obsidian; we keep it as markdown under `docs/vault/` so every session, local or cloud, reads it, and so Claude can write back to it when it learns something. Structure, mirrored from the video:

```
docs/vault/
  00-start-here/   Glossary.md (Promise, FTUE, Funnel, Bounce, Play-through, D1/D7/D30,
                   Cohort, Co-play, LiveOps, Three-goal ladder, Source/sink, Prestige,
                   Paid random item, each linked to the design doc section)
  01-game-design/  one note per system, pointing into GAME_DESIGN.md
  02-how-we-work/  prompt rules, review loop, commit habits
  03-studio-and-mcp/  the MCP connection, Rojo layout, plugin list
  04-roblox-engine/   Scale vs Offset, UIStroke, StreamingEnabled, DataStore limits, remote patterns
  05-ui-design/
      refs/        named screenshots: hud-stack, currency-pill, shop-featured, shop-passes,
                   index-cells, reveal-popup, capture-bar, toast, from Steal an Egg,
                   Pet Simulator 99, Grow a Garden, Adopt Me, plus our own screens
      UI-Playbook.md   the look, to the level of hex codes and proportions
      UI-Checklist.md  what every screen must pass before it ships
      UI-Recipes.md    how to build each component in code from the theme module
      User-UI-Taste.md what the team likes and dislikes, updated after every review
  06-art-pipelines/  creature generation prompts, installer workflow, Blender notes, Open Cloud upload
  07-alien-game/     anything specific to this project that is not design
```

The UI Playbook is the part to write first, and to the level the reference showed: close button is red, square-ish, white X with a black stroke, about 80% of the header height, top right, same place on every panel; at least 2% inner margin; header colours as hex values; section headings as "— FEATURED —" in a named yellow with a black stroke at about 7% of panel height; index cells coloured by rarity with the exact hex per tier; banners with a stated aspect ratio. Rules written that precisely are rules Claude follows.

### 10.4 Prompting discipline

From the three-month build in the videos, and the free guide the creator published:

- **One system per prompt.** One button, one panel, one service. Never "make the game" or "make a UI system."
- **Name the instance path and say where scripts go.** The example that worked: "inside StarterGui.MainGui.Button, make it so when the player clicks the button, it triggers this action. put the client code in the right place, use a remote event if the server needs to handle anything, and explain where each script goes."
- **Paste the error with the action.** "I clicked Build with two aliens assigned and got this error," not "it broke."
- **Plan first for anything multi-file.** Ask for the plan, correct it, then let it build.
- **Ask it to explain** what it changed, so the team can test and debug it.
- **Record corrections in the vault.** When a review says "the close button is in the wrong place," the fix goes into the playbook, not only into the code.
- **Make it ask questions, twice.** (batch 4) End a system brief with "do you have any questions for me?", answer, then ask what else it could ask. The answers become part of the brief before any code.
- **Map first, props by hand.** (batch 4) For a new world, generate the layout and structures first and place trees and bushes by hand; AI placement of scattered props is the weak spot every creator names.

### 10.5 Training the UI

1. Collect screenshots of the three or four most popular games closest to ours into `docs/vault/05-ui-design/refs/`, named by what they show.
2. Write the UI Playbook from them and from `GAME_DESIGN.md` section 16, with hex values and proportions.
3. Build one panel (the Shop) first, review it against the refs, correct it, and write every correction back into the playbook.
4. Then build the rest from the playbook and the theme module.
5. **Scale, never Offset**, for Position and Size on every element. Check every screen in Studio's device emulator at an iPhone SE size and an iPad size before it ships.

### 10.6 Generating the aliens

The model-generation video shows a creature pipeline a two-person team can run: one prompt per species, a generated model with VFX and a set of animations, a `.lua` installer pasted into Studio's command bar (or handed to Claude through MCP) that rigs the model and imports the animations, then a wiring prompt. The creator reports that ten enemies cost about 30% of a usage allowance, and that asking the tool to ask its own questions first improves the result.

Our prompt template per species, built from `GAME_DESIGN.md` sections 4 and 15:

> Generate a Roblox-ready creature called [name]: [three-word concept]. Round compact body, big eyes, tiny mouth, short limbs, one bold [colour], stylized low-poly, drawable by a child. One accessory: [attribute]. Animations: idle (looping, job-tied: [job]), walk, work-at-station ([job] loop), catch-reveal (shake, pop, pose), ride ([traversal] if rideable), flee. Tier [tier]: [overlay notes from the table]. Low particle count, mobile-safe. Import 1:1 with an installer .lua. Ask me every question you need before generating.

Generate commons first in batches, review silhouettes in greyscale at thumbnail size, and keep the one goofy element at every tier. Verify the current name and availability of the generation tool before planning around it; the video calls it Claude Design.

### 10.7 Studio plugins to install before building

GapFill and ResizeAlign (ship module seams, snapping parts), Brushtool 2 (scattering biome props), Redupe (station rows, fence lines, codex pedestals, repeated hull plates), Archimedes v3 (round camp pads, curved hull pieces, arches). The four are the ones "all the devs had." An AI scripting plugin that reads the place is optional once the MCP connection is in.

Claude Code plugins and skills (batch 4, the "optimize Claude for Roblox Studio" video) are a separate list: Roblox Dev (ivar-anon), the ShiroKSH Roblox Studio skill, Superpowers, Graphify, Ponytail, Agent Skills, plus the two MCPs we already run. Decisions and the exact install commands are in `docs/vault/02-how-we-work/Claude-Plugins.md`; nothing is installed by a script.

### 10.8 Co-play, measured and designed

One creator's single biggest regret was not designing for co-play, the share of play that happens with friends, which the discovery algorithm rewards. The design doc now treats it as a first-class metric (section 13). For the build: log friend-in-server, party size, visits, borrows and shared Showers from day one, and show a "Friend Boost" on the HUD so players can see co-play paying off.

### 10.9 Real benchmarks and the metrics Roblox actually shows

Three creators posted their Creator Hub pages (`media/tiktok/NOTES.md`, batch 2). They give real 2026 numbers to aim at, and they name the metrics the Home algorithm reads:

| Metric | What it is | Reference values seen | Our target |
|---|---|---|---|
| Day 1 retention | share of new players back the next day | Party & Casual benchmark band 6.19% to 11.84% (50th to 90th); a 1K-CCU tag game at 14.55% was the 97th percentile | above the 90th percentile of our genre band in Creator Hub; 12% good, 15% great |
| Day 7 retention | back after a week | 50th 0.51%, 90th 2.01%; 1.18% was the 73rd | above 2%, stretch 4% |
| First play bounce rate | left within 60 s, and within 61 to 180 s, of a first visit. Creator Hub warns high rates cut Home recommendation exposure | 10.94% and 16.37% on a healthy party game | under 10% and under 15% |
| New user first session retention | still playing after 5 minutes | 57.84% | above 55% |
| Play-through rate (PTR) | saw the tile, pressed play | not shown; depends on icon, thumbnails and the video trailer | track from launch; change thumbnails when it drops |
| Session time | | 8.7 min on a party game; Roblox median about 7 | above 10 min |
| Client crash rate, client frame rate | | 0.24%, 39 fps | under 0.5%, 30+ fps on phones |

The genre-benchmark bands are what Roblox compares us against, so the `D1 > 20%` target in `GAME_DESIGN.md` section 18 is the top-1% stretch, not the launch bar. Build the Roblox onboarding funnel with `AnalyticsService` funnel events from the first tutorial step so the Creator Hub funnel chart shows where players drop.

### 10.10 Sound, VFX, trailer

Two creators who reached 1K CCU said the same thing: sound design and VFX "help pretty much every stat," and a video trailer with good thumbnails is what drives play-through rate. So the sound list in section 3.4 and the reveal and catch VFX are launch requirements, not polish, and the 10-second gameplay trailer is a launch asset alongside the icon.

### 10.11 Asset tools seen working in 2026

| Tool | Used for | Note |
|---|---|---|
| Claude Design | models with VFX and animation sets plus a Lua installer (batch 1) | paid Claude plans |
| 3D AI Studio | meshes with a target polygon count | the creator preferred it to Meshy for poly control, which matters on phones |
| Meshy | rigged and animated GLB characters and props; large example library | import GLB through Studio's 3D importer |
| Gemini or another image model | icon sets and 3D model reference sheets | solves the icon pack question: generate one consistent set from the UI playbook description |
| Studio MCP `generate_mesh`, `generate_material` | quick placeholders and materials from inside Claude Code | free |

Pick one tool per asset type and record settings in `docs/vault/06-art-pipelines/`.

### 10.12 Mixing in a party beat

A party-game creator's advice runs both ways: party games get players more easily because they are simple and the genre bar is lower, and they monetise better when they borrow a simulator's coin-and-cosmetic loop. Our loop is the simulator side. The cheap party beat to add is a short, shared, timed round that any newcomer understands in five seconds: the Meteor Shower already is one, and a "Catch Rush" (90 seconds, most catches wins a cosmetic, every 10 minutes on the server clock) is a P1 experiment worth trying for bounce rate.

### 10.13 Befriend a Roblox dev

Every creator in both batches credits other developers. Two concrete asks for the first month: join one Roblox developer community (DevForum plus one Discord), and get three developers with a shipped game to play the vertical slice and tell us the first thing that confused them.
