# Handoff: everything about the Alien game, for the collaborator and their Claude

Written 2026-10-10 by Ethan's coordinator session, from the whole build conversation (2026-10-04 to 2026-10-10) and the repo at that date. This is the one file to read first. It says what the game is, what is built and verified, what is in progress, what comes next, every tool and id, how the work runs, and how Ethan and the collaborator stay in sync. Live status lives on [[Board]]; this file is the background and is updated when something lasting changes.

**For the collaborator's Claude:** read this whole file, then `CLAUDE.md` (the rules, loaded automatically in the repo), then [[Setup-and-Tips]] (how Ethan configured his Claude sessions, the Mac, Studio and every tool, plus the tips and tricks learned so far), then [[Board]], then today's note in `docs/vault/08-log/`. The prompt in section 14 does that for you. Everything below is specific on purpose: ids, file paths, numbers and the reason behind each decision, so nothing needs to be re-asked.

---

## 1. The people and the sessions

| Who | Role | How to reach them |
|---|---|---|
| **Ethan** (Roblox `EDankashin`, user id 1492992374) | Owner of the experience, the repo and the money. Makes product decisions, answers approvals on his Mac, does identity and legal steps, plays the game | Directly; on the repo through [[Board]] and the daily log |
| **The collaborator** | Co-developer. Works in Studio (Team Create, Edit access) and in the repo with their own Claude. Strongest fit to start: playtests, the visual pass (map dressing, models, icons, music picks), then systems as agreed | Same |
| **Ethan's coordinator** (a Claude Code cloud session on claude.ai/code) | Plans, designs, writes the contracts, sends build workers, reviews every diff, writes Codex cards, keeps the docs | Ethan relays; it reads the repo (log, Board) |
| **Ethan's Mac session** (Claude Code CLI on Ethan's MacBook) | Studio through the Studio MCP server, Open Cloud scripts with the key in its shell, starts Codex runs. Paused while Ethan uses the laptop for work | Through Ethan |
| **Ethan's computer-use session** (Claude desktop app, Code tab, computer use on) | The Studio clicks MCP cannot make: device emulator, Test > Clients and Servers with 2 players, plugin installs, File > Publish. Prompt in [[Hands-Off]]. Paused with the Mac | Through Ethan |
| **Codex** (OpenAI Codex CLI on Ethan's Mac) | Tooling cards from [[Codex-Queue]]: lints, tests, simulators, generators; reports into [[Codex-Reports]] | Through the queue |
| **The collaborator's Claude** | A new session on the collaborator's own Claude account. Same rules as every session: `CLAUDE.md`, the vault, the log | Through git: [[Board]], the log, commits |

Sessions on different Claude accounts cannot message each other. **Git is the sync channel**: the Board, the daily log and commit messages. Nothing important lives only in a chat.

---

## 2. The game

### 2.1 The pitch

You crash-land on a strange planet with a broken ship. Cute aliens are everywhere. Catch them with a timing-bar minigame, and they work at your camp and build you a ship. Fill the ship bar, launch, and do it again on a frost world, a cyber world, a lava world. Every planet you leave keeps working for you (outposts), and every alien you catch stays in your Codex forever. Working title: "AlienGame" in code; the experience is named "Alien game" on Roblox; the real name is open (decision 19).

Full design: `docs/GAME_DESIGN.md` (830 lines, 19 sections). Plan and status: `docs/PRE_PRODUCTION.md`. Research: `reports/`, `research_notes/`. Reference videos: `media/tiktok/NOTES.md` (five batches of TikToks, each with what we took).

### 2.2 Pillars (never broken)

1. **One bar.** The ship progress bar is the heartbeat; everything moves it and the player always sees it move.
2. **Aliens everywhere, secrets hidden.** 12 to 20 visible nearby; rares sit behind biome, time, weather and skill (the Pokemon GO model).
3. **Playable with one thumb.** No fail state that loses progress, no upkeep, auto-assign, income and assembly continue offline.
4. **Dopamine at every step.** Feedback within 2 s of every action, a reward in the first 10 s of every session, a climax at the end of every world.
5. **Nothing you did is wasted.** Old worlds become outposts, the Codex is forever, Sets reward the whole collection.

### 2.3 The loop

- **Moment (30 s to 2 min):** spot an alien, tap it, the timing bar opens, hit the zone, rarity reveal, the alien walks to its best station slot, Scrap per minute ticks up, a module crosses its cost, Build, the part snaps on, the ship bar jumps.
- **Session (7 to 15 min):** offline chest on join, a gift or quest, check the next module's missing material, explore for it, stay for a Meteor Shower if it is near, leave with a timer running.
- **World arc (days):** five ship modules, each with three gates (Scrap, a key material, assembly time); the Field Notes quest chain leads to the world's Warden (a Legendary with a three-round catch); launch cinematic; the camp becomes an outpost; next world.

### 2.4 Aliens

- Every alien is a **worker** (jobs Gather, Build, Spark at a level; produces Scrap at a station or assembles modules) and a **companion** (up to 3 follow you, each with a small perk by job and tier). No hunger, no upkeep, they never leave.
- **Rarity ladder:** Common (~50% of spawns, 1x work), Uncommon (~27%, 1.6x), Rare (~15%, 3x, one biome), Epic (~6%, 6x, biome plus a condition), Legendary (~1.5%, 12x, +10% all stations, server-announced), Cosmic (Meteor Shower only or a quest, max(25x, 2x your best), +25%), plus Secret. Overlays on any body: Shiny 1.25x, Gold 1.5x, Crystal 2x, Rainbow 5x (event only), Spectral (Aurora week and Haunted Nebula).
- **Size rolls** Tiny to Huge (Scrap multiplier, scaled model), **growth stages** Hatchling, Grown, Elder by time worked, **fusion** (four spare copies give +1 level on the best copy, max level 3), **mounts** (Thunderhog, the Wardens, the Cosmics, Frostfang are rideable; riding uses a companion slot).
- **Built rosters.** World 1 Verdant Crash Site (19): Mossbop, Pebblet, Glimmo, Twiglet, Puffpuff (Common); Snailbyte, Buzzlebee, Lanternewt (Uncommon); Rocklobber, Zapfinch, Sparkfox (Rare); Thunderhog (Epic, Rain signature), Gloomoth (Epic); Gaiabloom (Legendary Warden); Ra-dish (Cosmic, Shower); Panpipe (Secret); and the Haunted Nebula event set Wisplet (Rare), Spookum (Epic), Nebulyn (Legendary, track reward). World 2 Frostbyte (16): see [[Decisions]] "World 2 roster" (Flufflet to Fenripup, Frostfang the Blizzard signature, Skaddle the Warden). Each species has one goofy trait; Wardens and Cosmics echo myth figures (the Pantheon, organised in Codex Sets: Greek, Norse, Egyptian, Myth Beasts).

### 2.5 The capture minigame

Walk within 8 studs, tap. A bar with a ticker sweeping back and forth: grey Miss, green Good, gold Perfect. Perfect is a guaranteed catch with bonus Scrap (doubles it); Good rolls by tier (Common 100%, Uncommon 90, Rare 75, Epic 60, Legendary 50); up to 3 sweeps, then it flees. Zones shrink and the ticker speeds up by tier; Legendary and Warden catches are 3 rounds. Variants are rows over the same bar (`data/CatchVariants.luau`): Reel (Tidepool, the zone bobs, hold and release) and Chase (Neon Grid, the zone darts, a 12 s clock). **The client only reports the tap time; the server scores it.**

### 2.6 Worlds

Each world is its own Roblox place in one universe, with three biomes, 12 to 16 species, one Warden, one special weather with one signature alien, and one new rule.

| # | World | Biomes | Rule and signature | State |
|---|---|---|---|---|
| 0 | Home Planet | the plot | House grid, habitats, hangar, kiosk, mailbox, visiting | built (place 73774874008460) |
| 1 | Verdant Crash Site | Meadow, Forest, Cave | Day/night and Rain (Thunderhog); Warden Gaiabloom; the tutorial world; to become the "Moonlit Forest" reference world (milestone 48) | built (place 93842567264184) |
| 2 | Frostbyte | Snowfield, Ice Cave, Geyser Field | Blizzards hide aliens, place a Heater to reveal for 60 s (Frostfang); Warden Skaddle | built (place 112829778258240) |
| 3 | Neon Grid | Rooftops, Server Farm, Undercity | Rooftop parkour, Power Surge, 4th job Tinker, the Chase bar; Warden Hephaestron | designed, data rows only |
| 4 | Emberfall | Lava Fields, Obsidian Caves, Ash Forest | Heat meter and Cooling Vents; Warden Vulcanine | designed |
| 5 | Tidepool | Reef, Kelp Forest, Trench | Fishing (the Reel bar), tides, a bioluminescent Trench fountain; Warden Poseidolphin | designed |
| 6 | Dreamdrift | Candy Cliffs, Cloud Sea, Music Box Hollow | Gravity flips, parkour obbies, a rhythm floor; Warden Morpheep | designed |
| 7 | The Void Hub | the Gate | Endgame; every Warden needed; Warden Nyxling | designed |

World order decided: Verdant, Frostbyte, Neon Grid. Every world adds one verb, one special area, one super-rare through a harder bar, one secret spot (GAME_DESIGN 8, "World signatures"). Worlds 3 to 7 come after launch traction (100+ DAU sustained).

### 2.7 The home planet

Its own place (World 0), unlocked by the first launch. A plot with a house grid of rooms and furniture bought with Scrap (`data/HomeBuild.luau`), habitats where resting aliens go on display and earn, a hangar with a scaled model of every ship launched, a spin kiosk, a mailbox (letters from events and `/admin mail`) with a Visitor Book. Friends visit through a reserved server keyed by the owner, with a lock (Only me, Friends, Anyone) and a Wave at a displayed alien that pays both (capped per day). Borrow only, no theft (decision 6).

### 2.8 Retention systems (all built)

Offline earnings (50% of the live rate, capped), resting in game (after 2 min idle the crew earns at half rate while the game stays open; replaces the withdrawn Longer Offline pass), Welcome Week (7 days, strong day 7), daily and weekly quests with a reroll, promo codes, playtime gifts (six a day at 5, 10, 20, 30, 45, 60 minutes played), the spin wheel, the Meteor Shower (2-hour server clock), the Catch Rush (90 s shared round every 10 min), the Peddler (travelling shop with eggs and power-ups), Warden sightings (every 20 min), Alien of the Week with a weekly weather and Vaulted limited species, the weekly catch leaderboard, the Friend Boost (+5% per friend in server, cap 3), group-join reward, referral rewards, rejoin nudges with a notification opt-in card, outposts that keep producing, the Star Chart to fly between worlds, seasonal events (Haunted Nebula, 2026-10-16 16:00 UTC to 2026-10-30 16:00 UTC, data in `data/Seasons.luau`). Why each exists: [[Growth-Playbook]]. Every moment and its feedback: [[Moments]].

### 2.9 Monetization rules (hard rules)

- **One currency, Scrap. Never sold for Robux, directly or as a multiplier.** No second premium currency.
- Robux sells certainty, capacity, convenience, cosmetics. Everything that affects the ship bar is earnable.
- Paid random items (spins, server luck) show per-item odds summing to 100%, have no dud outcome, and are hidden where `PolicyService.ArePaidRandomItemsRestricted` is true.
- Prices cluster at 49 to 399 Robux (parents approve them without thinking). Every price should show its real-currency equivalent (open compliance item).
- No permanent luck pass at launch (decision 9). No "2x cash" product.

### 2.10 Owner direction (2026-10-07, standing; PRE_PRODUCTION 5a)

- **Feel, not just function.** Every moment designed for an emotion. Worked example: a Legendary encounter rumbles the screen (camera shake plus phone haptics), the music turns intense, effects say "not ordinary" before the bar opens, and it resolves in the Reveal. Same care for first catch, Rare spawn, Shower, launch, module snap, arriving home, Warden sighting.
- **Music for each moment**, crossfaded by game state, tracks from Roblox's licensed Creator Store library, **picked with the collaborator**.
- **Cinematics at the level of the reference video** (camera moves, letterbox, framing).
- **Replicate the top games' quality with our own designs.** Map design at the level of the "ropilot astra" reference; World 1 built to match the forest reference (the Moonlit Forest).
- **Icons are not good enough yet**; a replacement plan is written when the look pass starts.
- **Pacing:** World 1 must not be beatable in a day without hours of play; progression should feel steady but the goal stays far; not too many freebies; dopamine sources balanced.
- **Storage grows with progression**, like the top games.

### 2.11 Art, UI and audio direction

- Smooth low-poly, the style of the top simulators (Adopt Me, Grow a Garden, Steal an Egg); cute, saturated two-tone, thick dark outlines, soft shadows.
- UI: Fredoka One, outlined text over the world, chunky outlined buttons, standard rarity colours, the "stud" dialect modelled on Steal an Egg, Scale only (never Offset), built in code from `Theme`. No glassmorphism, no web fonts, no silent taps. The rules: [[UI-Playbook]], [[UI-Checklist]], [[UI-Rules]]. Every screen is checked at iPhone SE (667x375; Studio's list calls it iPhone 7) and iPad sizes.
- Models: 32 species and 21 props/heroes modelled in Blender through Blender MCP, uploaded through Open Cloud (53 Model assets) and installed in the Studio places with colours; 48 flat icons and 3 sprites. The visual quality pass is the big next phase (section 10).
- Sound: 39 `Sounds` slots and 13 `Music` rows exist with every asset id 0 (silent until picked). [[Music-Plan]].

---

## 3. Numbers that matter (all live in `src/shared/data`)

- **World 1 modules** (decision B14): Scrap 300 / 2,000 / 45,000 / 180,000 / 600,000; key materials 3 / 4 / 9 / 12 / 1; assembly 1 min / 7 min / 1 h / 2 h / 4 h. Measured: about 4 to 6 hours of play, launching on day 5 to 6 at 30 to 45 minutes a day, day 3 at 2 hours a day. The first module still lands in under 2 minutes.
- **World 2 modules:** Scrap 60k / 150k / 300k / 600k / 1M, keys 5 / 5 / 8 / 8 / 1, assembly 1.5x World 1. About 1.5x World 1's play time.
- **Freebies** (Welcome Week, quests, daily spin, codes, group gift, playtime gifts) are 1 to 6% of a player's Scrap; playtime gifts moved no launch day. Tools: `tools/progression_sim.py`, `tools/econ_sim.py`, `tools/balance.py`; report [[Balance-Report]].
- **Storage ladder** (decision B16): base 60; plus per finished module (World 1: 10 / 20 / 20 / 30 / 40, so 180 at its end; World 2: 20 / 25 / 30 / 40 / 45, so 340); plus 20 per Storage Bay level bought with Scrap (2,500 / 7,500 / 20,000 / 45,000 / 90,000, then 160,000 / 280,000 / 450,000 / 700,000 / 1,000,000 once World 2 opens); plus 100 with the StorageBoost pass (149 Robux); hard cap 1,500 (save size). At the cap a catch still counts and pays its release value (Common 5 to Cosmic 1,500 Scrap). Research basis: Grow a Garden starts pets at 60 with layered upgrades; Bubble Gum Simulator starts at 125 and sells slot passes.
- **Station slots:** the Thrusters module raises every station to 2 slots, the Nav Array to 3; the slot passes add on top (+1 and +2 stack to +3, decision 17).
- **Offline:** 50% of the live rate up to the cap; resting 50% while the game is open.
- **Save:** one DataStore key per player, `UpdateAsync`, session locking, schema version 18 with a migration for every version (v15 seasons, v16 playtime, v17 storage bay, v18 cinematics seen). A purchase answers PurchaseGranted only after `PlayerData.SaveNow`. Budget: [[Save-Budget]].

---

## 4. Ids and accounts

| Thing | Value |
|---|---|
| Experience (universe) | 10769415131, named "Alien game", **private** (not public yet), owned by Ethan's user account |
| Home Planet place | 73774874008460 (`home.project.json`) |
| World 1 place (start place) | 93842567264184 (`default.project.json`) |
| World 2 place | 112829778258240 (`world2.project.json`) |
| Stray place | 82258778278086, in the universe, unused; Ethan decides whether to delete it |
| Developer panel user ids | `src/shared/data/Admin.luau` `DeveloperUserIds = { 1492992374 }` (add the collaborator's id: section 13.1 step 6) |
| Group | none yet; `Social.luau GroupId = 0` hides the group gift. Decision 16 says a group co-owned by Ethan and the collaborator |
| GitHub repo | `Edankashin/Roblox-Alien-Game`, working branch **`claude/alien-system-research`** (all work so far is on it) |

**Robux catalog** (`src/shared/data/Shop.luau`; an id of 0 means it does not exist on the dashboard yet, and Buy refuses safely):

| Item | Kind | Robux | Id |
|---|---|---|---|
| StarterPack | product | 199 | 3717062435 |
| SpeedBurstx5 | product | 49 | 3717062564 |
| SteadyHandsx3 | product | 79 | 3717062704 |
| ScrapMagnetx3 | product | 99 | 3717062935 |
| ServerLuck2x (paid random) | product | 249 | 3717063366 |
| ServerLuck4x (paid random) | product | 999 | 3717063502 |
| SlotEveryStation1 | pass | 399 | 2013608394 |
| AutoOptimize | pass | 299 | 2014838379 |
| ExplorerPack | pass | 399 | 2014814394 |
| **Launch items still at 0:** Spins1 / Spins5 / Spins12 (paid random, 49 / 199 / 399), SlotEveryStation2 (799), CompanionSlot4 (249), StorageBoost (149) | | | 0, created by `tools/create_products.py --apply` on Ethan's Mac |
| Not at launch, 0 by design: DirectRare, DirectEpic, AutoCollect, ModuleRush, RadarMk1Unlock | | | 0 |

**Secrets.** Ethan's Open Cloud API key lives only in his Mac shell (`~/.zshrc`: `ROBLOX_OPEN_CLOUD_KEY` with `ROBLOX_CREATOR_USER_ID` for `upload_assets.py`, `ROBLOX_API_KEY` for `create_products.py` and `publish.py`). Never in a file in the repo, a commit, the vault, a report or a chat. If the collaborator needs Open Cloud, they make their own key (section 13.4). Asset ids, place ids and product ids are fine to commit.

---

## 5. The repo

```
default.project.json   World 1 (Rojo)        world2.project.json   World 2        home.project.json   Home
src/server/            ServerScriptService: Services/ (40 services: Economy, Catching, Spawner, PlayerData, Visiting, ...)
src/client/            StarterPlayerScripts: HUD, screens (UI/), capture bar, radar, camera (CameraDirector), MusicDirector
src/shared/            ReplicatedStorage: data/ (every number), strings/ (every player-facing string), types/, Theme, Net, shared maths
tests/                 headless Luau specs (265 tests) run by tools/test.sh
tools/                 analyze, lints, simulators, Open Cloud scripts, Blender generators, Studio installers
assets/models/         32 species + props (GLB, FBX, notes, thumbnail, materials.json); assets/models/asset_ids.json
assets/icons/, assets/particles/   icons and sprites
docs/                  GAME_DESIGN, PRE_PRODUCTION, TESTING (a Studio script per milestone), STUDIO-QUEUE (generated run sheet),
                       OWNER-GUIDE (Ethan's manual steps), MECHANICS-SIGNOFF, SETUP, vault/
docs/vault/            this Obsidian vault
media/tiktok/          reference videos' notes (never commit audio or frame dumps from media/tiktok/out/)
reports/, research_notes/   the research behind the design
```

Key docs map: rules `CLAUDE.md` (and `AGENTS.md` for non-Claude agents); design `docs/GAME_DESIGN.md`; plan, decisions and the build status table `docs/PRE_PRODUCTION.md` sections 5a, 5b, 5c; Studio test steps `docs/TESTING.md`; the run sheet of pending Studio checks `docs/STUDIO-QUEUE.md`; Ethan's manual steps `docs/OWNER-GUIDE.md`; decisions [[Decisions]]; every request Ethan made [[Requests]]; tools [[Tools-Status]]; glossary [[Glossary]].

---

## 6. The rules (from `CLAUDE.md`; every person and agent follows them)

- Luau in strict mode; shared types in `src/shared/types`.
- **Server authority** for everything touching Scrap, catches, spawns, timers, purchases and saves. The client renders and animates, never decides.
- **Every number** (costs, odds, timers, spawn weights, prices) in a data table under `src/shared/data`, never in logic.
- **Every player-facing string** in `src/shared/strings`, keyed, for translation.
- UI in Scale, never Offset; built in code from the theme module; follow the UI Playbook.
- Aliens are lightweight server records rendered on the client; no server-side Humanoids for creatures.
- Saves: one key per player, `UpdateAsync`, session locking, schema version with migrations.
- One system per change. Name the instance path. Say where each script goes and why.
- **Never edit scripts inside Studio**: Rojo overwrites them. Code lives in the repo; hand-placed dressing lives in the place file (`Workspace.Dressing`).
- Before committing code: `./tools/analyze.sh` prints `analyze: clean`; also run `python3 -I tools/lint_data.py` (`data lint: clean`), `./tools/test.sh` (all pass), `./tools/lint.sh` (all lints and the Studio-queue freshness check; when TESTING or PRE_PRODUCTION change, regenerate with `python3 -I tools/studio_queue.py --write`). CI runs the same on every push.
- When a review corrects the look of something, update the UI Playbook in the same change.
- Every tool mentioned gets a row in [[Tools-Status]] the same day; "adopt" is done only when the row says **in use**, verified.
- Vault logging: every session appends a heading to `docs/vault/08-log/YYYY-MM-DD.md` (done, found, decided, left); lasting facts move to their topic note with a `[[link]]`; never secrets in the vault.

Team-level limits Ethan set:

- Nothing that spends Robux or money without Ethan's yes.
- Identity and legal steps stay Ethan's: the Experience Questionnaire and maturity answers, ID verification, privacy and compliance forms, and **making the game public the first time**.
- Claude sessions do not install plugins into themselves or write permission rules for any session; the human at that machine does.
- No model names in commits, PRs or code.

---

## 7. Tools and software

Full tracker with every tool ever mentioned: [[Tools-Status]]. Summary:

**In use**

| Tool | What for |
|---|---|
| Roblox Studio (0.741 on Ethan's Mac) | The engine; Team Create for collaboration |
| Rojo 7.7.1 (pinned in `rokit.toml`, installed with Rokit) and the Rojo Studio plugin | Syncs `src/` into Studio; `rojo serve <project>.json`, Connect in Studio |
| luau-lsp 1.70.1 | Strict analysis (`tools/analyze.sh`) with Roblox definitions through the Rojo sourcemap |
| Roblox Studio MCP server (built into Studio) | Claude drives Studio live: run Luau, play, read output, screenshots. Registered in the repo's `.mcp.json` ([[Connection]]) |
| Blender 5.2 with Blender MCP (`mcp-for-blender`) | Species, props, heroes, icons, sprites (`tools/blender/`) |
| Roblox Open Cloud | Asset uploads (`tools/upload_assets.py`), shop items (`tools/create_products.py`), place publishing (`tools/publish.py`); key only in Ethan's shell |
| Codex CLI | Tooling cards ([[Codex-Queue]], [[Codex-Prompt]]) |
| Obsidian | This vault (`docs/vault`) |
| GitHub, with CI on every push | The repo and its checks |
| ffmpeg, yt-dlp, Whisper (sherpa-onnx) | Processing reference TikToks (`tools/watch_video.py`) |
| Claude Code (cloud coordinator, Mac CLI, desktop computer use), Sonnet workers | The build itself ([[Token-Economy]]) |
| Claude Code Setup plugin | Installed on Ethan's Mac |

**Decided, not installed yet** (each needs a step on a Mac by its human): claude-mem (needs `bun`), the Roblox Dev plugin (ivar-anon) after a dry run, the ShiroKSH Roblox Studio skill (for World 2 map work), Superpowers (try on one big build), ccusage (`npx -y ccusage daily` weekly), rtk (trial), ccstatusline (optional), StyLua (Codex card C25). Studio plugins for map work, from the "what pro devs use" reference: **Stravant GapFill & Extrude, ResizeAlign, Redupe, Brushtool 2, Archimedes v3** (none installed yet; free ones installed freely, paid ones need Ethan's yes).

**Chosen instead:** our own `PlayerData` instead of ProfileStore (same guarantees, tested; a swap would migrate every save for no gain); Blender MCP instead of Meshy, 3D AI Studio or Tripo for now.

**Later or skip:** Discord server (launch assets), image models for icons v2 (Nano Banana, Gemini; needs an account and Ethan's call), Claude Design for animated models, Lemonade.gg and Ropilot (reference only), "raw alone" (dropped by Ethan).

**What the collaborator installs** (section 13.3 has the steps): Roblox Studio, Rokit (gives Rojo and luau-lsp), the Rojo Studio plugin, git, Claude Code, Obsidian; optionally Blender 5.x with the MCP add-on, Homebrew, ffmpeg, and the five Studio plugins above.

---

## 8. How the work runs

1. **Milestones.** Each feature is a numbered milestone. The coordinator writes a shared contract first (types, data rows, strings), then sends build workers (Sonnet subagents with a complete brief, often in an isolated worktree), reviews the diff, runs every check, commits and pushes. Each milestone gets a Studio test script in `docs/TESTING.md` and a row in PRE_PRODUCTION 5b.
2. **Studio verification.** A Mac session runs the TESTING steps through the Studio MCP server (property reads, captures, dev commands) and writes pass or fail with what it saw; the computer-use session does the clicks MCP cannot (device emulator, two-player tests, publishing). Fixes from those notes go in, then a re-check. `docs/STUDIO-QUEUE.md` is the generated list of everything still waiting on Studio.
3. **Codex** takes self-contained tooling cards, claims each with a commit, reports in [[Codex-Reports]]; the coordinator reviews and accepts.
4. **Docs move with the code**: every decision in [[Decisions]], every request in [[Requests]], every tool in [[Tools-Status]], every UI lesson in [[UI-Playbook]], every engine fact in `04-roblox-engine`.
5. **Token economy**: workers on Sonnet with complete briefs, read files in one or two commands, write whole files, report in under 300 words ([[Token-Economy]]).

**Studio testing basics:**

- `rojo serve default.project.json` (or `world2.project.json`, `home.project.json`), Connect in Studio, Play. Stop Play before switching projects.
- Real saves: Game Settings > Security > Enable Studio Access to API Services, then `Config.UseDataStoreInStudio = true` (already on). Studio tests then write to the real (private) game's DataStores.
- Studio-only chat commands (the Dev service, never live): `/scrap N`, `/spawn <Species>`, `/night`, `/day`, `/rain`, `/weather <id>`, `/variant <id>`, `/grow N`, `/complete`, `/world N`, `/outpost`, `/dupes <Species> N`, `/follow`, `/habitat`, `/visit <name>|off`, `/season <id>|off`, `/week`, `/radar N`, `/sighting`, `/playtime`, `/storage fill|cap|bay`, `/cinematic <id>|reset|list`, `/deltas`, `/buy <item>`, `/pass <item>`; the full list prints in Output on Play. `/admin luck|shower|weather|say|mail` works live for the ids in `Admin.luau`.
- Two players: Test tab > Clients and Servers > 2 players. Studio's test players are not Roblox friends, so set the home lock to Anyone for visiting tests.
- Server output also lands in `~/Library/Logs/Roblox/*_last.log` on a Mac (faster to grep).

---

## 9. What is done (as of 2026-10-10, branch head fff8206)

Every mechanics milestone from 1 to 51a is built and pushed. "Pass" means its TESTING steps passed in Studio; leftovers are noted.

| # | Milestone | Studio |
|---|---|---|
| 1 to 4 | Bootstrap, saves, the Meadow, spawns, capture bar, reveal, camp, Scrap income, key materials, ship modules, Forest and Cave biomes, condition-gated nodes | pass |
| 5 to 8 | Menus, Aliens and Codex screens, Nearby panel, lures, Scrap shop, Speed Boots, Peddler, power-ups, luck and pity, Field Notes, shrine, Warden encounter, the tutorial | pass |
| 9 to 13 | Welcome Week, spin wheel, Meteor Shower, Radar Mk1, sound hooks, particles, camera moments, crash opener, mesh models, Settings and the analytics funnel | pass |
| 14 | Robux launch shop | pass with grants; receipts wait on live ids |
| 15 to 18 | World 2 Frostbyte, one place per world, the launch, the Heater rule, environment props, outposts and the Star Chart | pass (a few World 1 steps wait on a Connect) |
| 19 to 24 | Group and referral rewards, rejoin nudges, notification card, weekly leaderboard, daily and weekly quests, codes, lighting looks per world, the Friend Boost, weather particles | pass (multi-client parts open) |
| 25 to 30 | Size rolls, catch variants, the five-minute script, growth stages, hero landmarks, the compass strip | pass |
| 31 to 33 | Icons wired with fallbacks, icons on every surface, the VFX pass | partial; waits on the image upload and the visual pass |
| 34 to 41 | Catch Rush, fusion, companions, mounts, the weekly drop, Warden sightings, Radar Mk2, the developer panel | pass (multi-client and real-save steps open) |
| 42a to 42d | Home place, house grid, habitats, hangar, kiosk, mailbox | pass |
| 42e | Visiting | single-client pass; the two-player half passed in the computer-use run (with one guide fix: the home lock must be Anyone for test players); the cross-server trip half needs the published home place and real saves |
| 43 | Scanner Pulse | pass |
| 44 | Haunted Nebula seasonal event | pass |
| 45 | Paid spins and two more passes | spin tiles and the odds table pass at phone size; the rest queued; three spin products and two passes still at id 0 |
| 46 | Resting in the game | two bugs found and fixed (Back to play, menu use as idle); re-check queued |
| 47 | Shot-based cinematic camera (arrivals, Legendary push-in) | built; Studio check queued; camera anchors to place by hand |
| 49 | Playtime gifts | built; Studio check queued |
| 50, 50b | Alien storage cap, storage that grows (Storage Bay, StorageBoost pass) | built; Studio check queued |
| 51a | Music and sound system (director, crossfades, Legendary rumble and haptics) | built; every track id is 0; Studio check queued |
| UI fit pass | Phone-size text fits (wheel, shop tiles, HUD buttons, toasts, name plates) | built; Studio check queued |
| Alien list deltas | Incremental alien list sync (`AliensDelta`, 2 KB instead of up to 290 KB) | built; Studio check queued |
| Security hardening | Visit races, lookup budget, Peddler and Wave proximity ([[Exploit-Review]] D2, D3, D7) | built; Studio check queued |

Also done: 32 species and 16 props plus 5 hero set pieces modelled and uploaded (53 Model assets), 48 icons and 3 sprites rendered; Codex cards C1 to C22 (CI, data lint, 265 headless tests, balance reports, string, remote, UI and TESTING lints, save migration tests, dead code, performance and save budgets, the Studio run sheet, the moment inventory, the music plan, the shop-item creator); the hands-off pipeline ([[Hands-Off]]); pacing retune (B14); the storage ladder (B16).

---

## 10. What is in progress and what comes next

The live list with owners is [[Board]]. In order of priority:

**A. Close the Studio queue** (29 milestones, 102 steps in `docs/STUDIO-QUEUE.md`). Needs a Mac with Studio. The collaborator can run any of it from their own Studio once they have Edit access: `rojo serve`, follow the TESTING steps, write pass or fail under their heading in the daily log. Highest value first: 46 re-check, 49, 50, 50b, 47, 51a, the UI fit pass, alien deltas, security hardening, then the phone and iPad emulator pass.

**B. Ethan's owner items** (`docs/OWNER-GUIDE.md`): run `create_products.py --apply` on his Mac for the six launch items at id 0; the stray place; the group (decision 16) and the name (decision 19); the Experience Questionnaire before going public.

**C. Codex cards in review:** C23 (`tools/publish.py`: builds the three places and uploads through Open Cloud; use `--saved` only until the runtime model loader lands), C24 (`src/shared/data/ModelAssets.luau`: 53 model asset ids plus the installer's colours and materials as data; missing models: Nebulyn, Spookum, Wisplet and nine home props), C26 (35 TESTING lines corrected; the generator's stale notice is hard-coded in `tools/studio_queue.py:71`). Open: C25 (StyLua for the whole repo, run last in a batch).

**D. The runtime model loader** (coordinator): the server loads the species and prop meshes at boot with `InsertService:LoadAsset` from C24's table, so a place built from the repo has its models and publishing needs no Studio. Then `publish.py --apply`.

**E. The visual pass** (the collaborator's natural lead, with the coordinator on code):
1. **Moonlit Forest** (milestone 48, PRE_PRODUCTION 5c item 4): World 1's Forest at night with giant glowcaps, fireflies, a moon pool with lily pads and stepping stones, a waterfall seen from a bridge, path lanterns that light at dusk; indigo, violet and teal. Props from Blender, a client `NightDresser` that turns lights and particles on at night, Lighting's night row retuned.
2. **Map dressing** in each place with Brushtool 2, Redupe, GapFill, ResizeAlign, Archimedes, by the rules in [[Map-Dressing]] (one hero landmark per biome, strong height, a hard colour identity per biome, paths that lead the eye, named sights, the island reads as one from the establishing shot). Place the **camera rig anchors** for the cinematics in `Workspace.Dressing.CameraRig` (the fallback flights can clip trees until they exist).
3. **The assembly effect** (`Vfx.Assemble`: pieces rise in a wave and snap on) for modules, house pieces and opened biomes.
4. **Icons v2**, soft sprites, 9-slice plates, species texture passes, the gloss and chrome pass in UI code ([[Look-Plan]], [[Creature-Generation]], [[Blender-MCP]]).
5. **Music and sounds**: pick tracks for the 13 `Music` rows and the 39 `Sounds` slots from the Creator Store audio library (licensed, permission-tested in the place), per [[Music-Plan]] and [[Moments]]; the new-world arrival stinger and banner.
6. Models still to make: Nebulyn, Spookum, Wisplet, and the home props (Bench, Flag, Fountain, two habitats, Planter, three rooms).

**F. Launch readiness:** a cold playtest by three outsiders (finish the tutorial unaided, come back the next day), the device emulator pass, store page (icon, thumbnails, a 10-second clip, description, genre), real-currency equivalents beside Robux prices, the notifications decision, analytics funnel review, Discord, then publishing and going public (Ethan).

**G. After launch traction:** Worlds 3 to 7 one at a time (Neon Grid first), the Hoverboard and skins, party co-op, Sets of secret aliens, trading and guilds later.

---

## 11. Known issues and open decisions

- Phone haptics through `HapticService` are unverified on a real phone.
- Cinematic fallback paths are straight lines and can pass through trees until anchors are placed; a portrait phone cuts the island's sides on the establishing shot.
- The global lookup budget can answer "Crowded" to a visit for a short while when many players look up homes at once.
- The waved book (who waved at whom today) lives in server memory, not the save.
- Arrival by teleport still trusts a 60 s cached read of the home lock.
- The Gear tab's long radar lines and small Robux tiles still trim with an ellipsis on a phone; other centred panels sit partly under the menu column in a very narrow window.
- [[Exploit-Review]] D1, D4, D6 are decided but not built.
- PRE_PRODUCTION 5b has a duplicated row for milestone 50 (harmless; the run sheet generator reads it).
- Open decisions: the game's name (19), rejoin notifications (20), whether a Storage Bay purchase past the hard cap is refused, whether a catch at the cap pays its catch Scrap on top of the release value (it does now), a fourth round HUD top button rule, the group (16) and when to move the experience into it.

---

## 12. Syncing: how Ethan and the collaborator see each other's work

One repo, one branch, one board, one log.

1. **Pull before you start, push when you stop.** `git pull --rebase origin claude/alien-system-research` before work and before every push. Never force-push. Small commits with clear messages.
2. **[[Board]] is the shared to-do list.** Before starting something, put your name in its Owner column and move it to Now, commit and push that line on its own (so the other person sees the claim within minutes). When done, move it to Done with the commit hash. Never work on a row someone else has claimed; add a note on the row instead.
3. **The daily log** `docs/vault/08-log/YYYY-MM-DD.md`: each person (and each of their Claude sessions) appends their own heading, for example `## Collaborator (Claude, Studio and repo)`, with bullets for done, found, decided, left. Append only; never edit someone else's lines.
4. **Decisions** go into [[Decisions]] with a date; product decisions are Ethan's, so a proposal goes on the Board's "Needs a decision" list until he answers.
5. **Areas, to avoid stepping on each other.** Studio place content (dressing, anchors, hand-placed props in `Workspace.Dressing`) is edited live in Team Create, where both people see each other's changes in real time. Scripts are never edited in Studio (they come from Rojo), so Studio's script drafts are not used. Code, data, strings and docs change only through the repo. Two people editing the same file at once is the one thing to avoid: claim the system on the Board first.
6. **Studio sync caution.** Rojo writes the repo's scripts into whichever Studio is connected. In Team Create only **one** person should have Rojo connected to a place at a time (otherwise both push their local copies); say on the Board "Rojo connected to World 1" while you have it.
7. **Obsidian** shows the same vault on both machines because it is a folder in the repo; git carries the changes. Open `docs/vault` as a vault on each machine; the Board and the log update after a `git pull`.

---

## 13. Access setup, step by step

### 13.1 Roblox Studio (Ethan does steps 1 to 5; about 10 minutes)

Roblox's rule today for an experience owned by a user account: anyone can be given Play access, but **Edit access only goes to people who are your Roblox friends (Connections)**. And since early 2026, **both the owner and the collaborator must complete an age check** (ID or facial age estimation) before Studio's collaboration tools work; by default only compatible age groups can collaborate (adults with 16 and over, for example), and Trusted Connections are the way around a mismatch.

1. **Be Roblox friends (Connections).** Ethan sends a friend request to the collaborator's Roblox account (or accepts theirs).
2. **Age check, both accounts.** On roblox.com: Settings > Account Info > Verify My Age (ID or a face scan). Each account does its own once. If their age groups differ, add each other as Trusted Connections. Two-step verification on both accounts is strongly advised.
3. **Open the experience in Studio.** Studio > the experience "Alien game" (any of its places, World 1 is fine) > it opens from the cloud.
4. **Turn on collaboration and add the collaborator.** Click **Collaborate** in Studio's top-right toolbar. If the place is not yet collaborative, Studio offers to turn it on (this publishes the place once and makes it a Team Create place: say yes; the experience stays private). In the Collaborate window, search the collaborator's Roblox username, pick them, set the permission to **Edit**, and **Save**. Experience-level permissions apply to every place in the universe, so World 2 and Home are covered too. (Older guides call this Team Create and put it under View > Team Create or File > Game Settings > Permissions; the Collaborate button replaced that.)
5. **Studio API access for saves** is already needed for testing: Game Settings > Security > Enable Studio Access to API Services (on). Collaborators with Edit then test real (private) saves too.
6. **Developer panel.** Add the collaborator's Roblox user id to `src/shared/data/Admin.luau` `DeveloperUserIds` (their id is in their profile URL, `roblox.com/users/<id>/profile`), so `/admin` commands work for them in live servers. One-line repo change; either of you commits it.
7. **The collaborator** then opens Studio, signs in, and finds "Alien game" under **Shared With Me** (or in the Collaborate list), opens World 1, and checks that they can see the place tree. They do the repo setup in 13.3 before connecting Rojo.

**The group route (decision 16, later).** A Roblox group co-owned by both, owning the experience, gives roles with "Create and edit group experiences", shared Open Cloud keys owned by the group, the group-join reward (`Social.GroupId`) and group payouts to split revenue. Roblox now supports transferring an experience from a user to a group (Creator Dashboard > Creations > the experience > Configure > Settings > Initiate ownership transfer; email verified; the group accepts; the experience goes private and its servers close). **Before choosing it:** the transfer requires the experience's private assets loaded by InsertService to be owned by the group, and our 53 model assets were uploaded under Ethan's account, so they would be re-uploaded under the group (`tools/upload_assets.py` with a group key), ideally before the runtime model loader (section 10 D) ships; and the shop's passes and products must be checked after the transfer. Recommendation: start with Collaborate now; move to a group as one planned step before going public.

### 13.2 GitHub (Ethan, 2 minutes)

1. github.com/Edankashin/Roblox-Alien-Game > **Settings** > **Collaborators** (under Access) > **Add people** > the collaborator's GitHub username > role **Write**. They accept the email invite.
2. Optional, for the collaborator's Claude on the web (claude.ai/code): the Claude GitHub App is installed on Ethan's account for this repo. If the collaborator's Claude on the web cannot see the repo after they connect their own GitHub, Ethan checks the Claude app's installation (github.com > Settings > Applications > Claude > Configure) includes this repository. The local route (Claude Code on their own computer in a clone) always works with plain git.

### 13.3 The collaborator's computer (their Claude can walk them through it; ask before each install)

How Ethan set up his own machine, step by step with the problems he hit, is in [[Setup-and-Tips]] Part 1; the short version for you is its Part 2.


1. `git clone https://github.com/Edankashin/Roblox-Alien-Game && cd Roblox-Alien-Game && git checkout claude/alien-system-research`
2. Install Rokit (github.com/rojo-rbx/rokit), then in the repo `rokit install` (Rojo 7.7.1, luau-lsp 1.70.1). Check: `./tools/analyze.sh` prints `analyze: clean`, `./tools/test.sh` passes all 265 tests.
3. Roblox Studio, signed in; the Rojo plugin (`rojo plugin install`, or Rojo from the Creator Store).
4. Claude Code (`npm install -g @anthropic-ai/claude-code`, or the Claude desktop app's Code tab) on their own Claude subscription, started inside the repo folder so it reads `CLAUDE.md`.
5. Studio MCP: in Studio, open a place, Assistant button > three dots > Settings or Manage MCP Servers > MCP Servers > turn on **Enable Studio as MCP server**. The repo's `.mcp.json` already registers it for Claude Code on a Mac (`/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`; on Windows the server is `%LOCALAPPDATA%\Roblox\mcp.bat` and needs a local `.mcp.json` edit not committed). Start `claude` in the repo, accept the project MCP server, `/mcp` shows it. Do not register it a second time at user scope ([[Connection]]).
6. Obsidian: Open folder as vault > `Roblox-Alien-Game/docs/vault`.
7. Optional: `tools/setup-mac.sh` (Homebrew, Node, Rokit, Rojo plugin, ffmpeg, yt-dlp, uv, Blender and its MCP add-on, the Claude Code Setup plugin). Read it before running; it installs software machine-wide.
8. Optional for the visual pass: Blender 5.x with the MCP add-on ([[Blender-MCP]]); the five Studio plugins (Toolbox > Plugins or the Creator Store page > Install).
9. Then: `rojo serve default.project.json`, in Studio press Connect on the Rojo plugin (one person at a time per place, section 12.6), press Play, try `/scrap 1000`.

### 13.4 Open Cloud for the collaborator (only if needed)

The scripts read the key from the shell only (`ROBLOX_OPEN_CLOUD_KEY` for uploads, which also take `ROBLOX_CREATOR_GROUP_ID` for group-owned assets; `ROBLOX_API_KEY` for shop items and publishing). On a user-owned experience only the owner's keys reach it, so for now Open Cloud jobs (uploads, shop items, publishing) run on Ethan's Mac. After a move to a group, a group member with the API key admin permission can make a group key limited to this experience (Creator Dashboard > the group in the Creator Hub dropdown > Open Cloud > API Keys). Never share or commit a key.

---

## 14. The prompt for the collaborator's Claude

Paste this as the first message in a Claude Code session started inside the repo folder:

```
You are joining the Roblox Alien Game project as the collaborator's Claude. Read, in order:
docs/vault/00-start-here/Handoff.md (all of it), CLAUDE.md, docs/vault/00-start-here/Setup-and-Tips.md,
docs/vault/00-start-here/Board.md,
and the newest note in docs/vault/08-log/. Then git pull --rebase origin claude/alien-system-research.
Set up my computer per Handoff section 13.3, asking me before every install, and confirm
./tools/analyze.sh prints "analyze: clean" and ./tools/test.sh passes. Then show me the Board's
Now and Next rows that are unowned and suggest what I should take first, given that I am
strongest at <what I like doing: playtesting, map dressing, models, music, UI, systems>.
Rules: follow CLAUDE.md exactly (server authority, every number in src/shared/data, every
string in src/shared/strings, Scale-only UI from Theme, strict Luau, one system per change);
never edit scripts inside Studio; claim a Board row in its own commit before working on it;
log every session under your own heading in docs/vault/08-log/YYYY-MM-DD.md; run analyze,
data lint, tests and lint.sh before every code commit; pull --rebase before every push, never
force-push; never commit audio, frame dumps, keys or secrets; product decisions (prices,
pacing, design changes, anything costing Robux) go on the Board's "Needs a decision" list for
Ethan instead of being made.
```

---

## 15. Where to look for anything else

| Question | Note |
|---|---|
| How Ethan configured Claude, the Mac, Studio and the tools; tips and tricks | [[Setup-and-Tips]] |
| A word you do not know | [[Glossary]] |
| Why a decision was made | [[Decisions]], PRE_PRODUCTION sections 2, 5a, 5c |
| What Ethan asked for and what happened to it | [[Requests]] |
| How a screen should look | [[UI-Playbook]], [[UI-Checklist]], [[UI-Rules]] |
| How remotes, saves and boot work | [[Remotes]], [[Save-Budget]], [[Service-Boot]], [[Data-Tables]], [[Performance]] |
| How to make a model or prop | [[Blender-MCP]], [[Creature-Generation]], [[Map-Dressing]], [[Look-Plan]] |
| What each moment should feel and sound like | [[Moments]], [[Music-Plan]] |
| What still waits on Studio | `docs/STUDIO-QUEUE.md`, `docs/TESTING.md` |
| What Ethan does by hand | `docs/OWNER-GUIDE.md`, [[Hands-Off]] |
| How the AI side runs cheaply | [[Token-Economy]], [[Prompting]], [[Codex-Prompt]] |
| What happened on a given day | `docs/vault/08-log/` |
