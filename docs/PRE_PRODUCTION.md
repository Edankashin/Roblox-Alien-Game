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
| 1 | Game name | pick one of the placeholders or a new one | Day 1 (place name, strings) |
| 2 | Art style | smooth low-poly | Before any modeling |
| 3 | Number of jobs at launch | 4 | Day 1 (data tables) |
| 4 | Companions following the player | yes, 3 slots | Day 1 |
| 5 | Splicing consumes parents | no | P1 |
| 6 | Theft or borrow | borrow only | P2 |
| 7 | World order | Verdant, Frostbyte, Neon Grid | P1 |
| 8 | Event rerun policy | annual Vault Reopening | P1 |
| 9 | Permanent personal luck pass | not at launch | Launch |
| 10 | Mounts use a companion slot | yes | P1 |
| 11 | Scrap for Robux | never | Day 1 (shop data) |
| 12 | UI font | Fredoka One | Day 1 (theme module) |
| 13 | UI palette (six colors) | pick hex values, or accept a default set in the theme module | Day 1 |
| 14 | Icon pack | pick one on the Creator Store | First UI pass |
| 15 | Who owns the Roblox group and the experience | one account; the other is a collaborator with edit access | Day 1 |

---

## 3. Design gaps that still need to be written down

These are specified in spirit in the design doc but not as data a build can consume.

### 3.1 The first eight minutes, beat by beat

The tutorial decides D1 and it is not scripted yet. It needs a step list with: trigger, what the player sees, what they must do, what unlocks, the exact text, and the time budget per step. Proposed skeleton:

| Step | Time | Beat | Unlock |
|---|---|---|---|
| 1 | 0:00 | Crash landing cinematic, 8 seconds, skippable after the first time | |
| 2 | 0:10 | "Drag 3 wreck plates to the frame." Player hauls by hand. Ship bar appears at the first plate | Ship bar |
| 3 | 1:00 | Mossbop waddles up, "!" bubble. First capture, zone 40% wide, cannot fail (ticker slows near the zone) | Capture bar, codex |
| 4 | 1:30 | Mossbop auto-walks to the Haul station and takes over hauling. Timer visibly drops | Stations |
| 5 | 2:00 | "Weld a panel." Player holds a button. Puffpuff appears, same ritual, takes over welding | Second job |
| 6 | 3:00 | Scrap counter appears with "+" text. First module hits 50%. "Catch 3 more aliens while they work" | Scrap |
| 7 | 3:30 to 6:30 | Free catching in the Meadow with the Nearby panel on. A Rare (Sparkfox) is guaranteed to spawn once in this window | Nearby panel |
| 8 | 7:00 | Module 1 completes. Camera pan, part snaps, bass hit. Field Notes step 1 appears with Speed Boots as the reward | Quests, gear |
| 9 | 8:00 | "Thrusters need Glowroot from the Forest." Waypoint set. Peddler lands for the first time. Welcome Week gift 1 pops | Peddler, gifts |

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

Before the first playtest, a small simulator should run a bot through World 1 with the proposed numbers and report: time to each module, Scrap balance over time, catches per minute, how often the player is Scrap-blocked versus key-material-blocked versus assembly-blocked. The target is that the key material is the usual blocker and Scrap almost never is. This can be a 200-line script in the repo.

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
  stations = { Mine = { slots = 1, assigned = { uid } }, ... },
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
- Two jobs (Haul, Weld), one station each, auto-assign.
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

## 6. Compliance and store readiness

- Complete the Experience Questionnaire honestly; expect a rating suitable for all ages or 9+, which rules out the US 18+ DevEx rate.
- Every paid random item shows per-item odds summing to 100%, no dud outcome, live-updating odds under luck, and is hidden where `PolicyService.ArePaidRandomItemsRestricted` returns true, with a deterministic alternative shown.
- Scrap is never sold for Robux (see decision 11).
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
- Sponsored ads only after D1 is above 20%, because paid traffic drags down the engagement signals discovery uses.

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

### 10.8 Co-play, measured and designed

One creator's single biggest regret was not designing for co-play, the share of play that happens with friends, which the discovery algorithm rewards. The design doc now treats it as a first-class metric (section 13). For the build: log friend-in-server, party size, visits, borrows and shared Showers from day one, and show a "Friend Boost" on the HUD so players can see co-play paying off.
