# Collaborator brief

Written for Ethan's co-developer and for the Claude session he works with. Feed this file to your Claude first ("Read docs/COLLABORATOR-BRIEF.md, then CLAUDE.md and AGENTS.md, then set me up"). The coordinator (Ethan's Claude session) updates this file at every milestone, so it is always current; `docs/PRE_PRODUCTION.md` section 5b holds the build status table it summarises.

## 1. The game in one minute

An original Roblox collection game. You crash-land on a planet with a broken ship. Cute aliens live there; you catch them with a timing-bar minigame (tap when the ticker crosses the zone; a Perfect doubles the Scrap). Caught aliens work at your camp's stations and earn Scrap, the only currency (never sold for Robux). Scrap and key materials gathered in the world build the ship's modules; when the ship is whole you launch to the next themed world and the loop repeats with a new rule, a new roster and a new signature mechanic. Reasons to come back: offline earnings, aliens that grow by time worked, a 7-day welcome week, daily and weekly quests, a weekly catch leaderboard, a Meteor Shower appointment, a travelling Peddler, outposts that keep producing on worlds you left. Design: `docs/GAME_DESIGN.md`. Why each retention piece exists: `docs/vault/01-game-design/Growth-Playbook.md`.

The pillars we never break: one currency, server authority for every outcome, every number in a data table, every string keyed for translation, phone-first UI (Scale only), no dark patterns (no like-for-reward, odds shown on anything paid and random).

## 2. Where everything lives

- `CLAUDE.md`: the rules every agent and person follows. `AGENTS.md`: the same rules for a non-Claude agent.
- `src/server` (services), `src/client` (HUD, screens, renderers), `src/shared` (data tables, strings, types, Theme, shared math). Rojo maps it with `default.project.json` (World 1) and `world2.project.json` (World 2).
- `docs/PRE_PRODUCTION.md`: the plan, the decisions, the build status table (section 5b), the open owner items. `docs/TESTING.md`: one Studio test script per milestone.
- `docs/vault/`: the knowledge vault. Start with `05-ui-design/UI-Playbook.md` (the look rules), `06-art-pipelines/Look-Plan.md` (the visual passes in order), `06-art-pipelines/Blender-MCP.md` and `Creature-Generation.md` (how models are made), `06-art-pipelines/Map-Dressing.md` (props and the Open Cloud upload), `02-how-we-work/Token-Economy.md` (how we keep AI cost down), `02-how-we-work/Codex-Queue.md` (jobs for the second agent), `07-alien-game/Requests.md` (every request Ethan made and what happened to it).
- `assets/models/<Species>/` and `assets/models/props/<Name>/`: every generated model (GLB, FBX, notes, thumbnail, materials.json). `assets/icons/`, `assets/particles/`: the icon set and sprites. `tools/blender/`: the generators that make them. `tools/upload_assets.py`: uploads to Roblox through Open Cloud.
- `media/tiktok/NOTES.md`: lessons from the reference videos.

## 3. Setting up your Mac

1. Clone the repo and check out the working branch: `git clone https://github.com/Edankashin/Roblox-Alien-Game && cd Roblox-Alien-Game && git checkout claude/alien-system-research`.
2. Tools: install Rokit (https://github.com/rojo-rbx/rokit), then in the repo `rokit install` gives rojo 7.7.1 and luau-lsp 1.70.1 (or put them in `~/.local/bin`); `./tools/analyze.sh` must print `analyze: clean`. `tools/setup-mac.sh` has the rest (Blender add-ons, ccusage, the Claude plugins we use).
3. Roblox Studio with the Rojo plugin (Creator Store). In the repo run `rojo serve` and press Connect in Studio, or build a place file: `rojo build default.project.json -o /tmp/alien-world1.rbxl && open /tmp/alien-world1.rbxl`. Press Play. Studio chat commands exist for testing (`/spawn Mossbop`, `/scrap 1000`, `/weather Rain`, `/variant Reel`, `/grow 2`, the full list prints in Output on Play).
4. Team Create: Ethan invites you on the published place with Edit access; hand-placed dressing lives in that place file, the code lives in the repo (never edit scripts in Studio; Rojo overwrites them).
5. Blender 5.x (headless renders work: `blender -b -P tools/blender/alien_base.py -- --help`). The Blender MCP add-on lets a Claude drive Blender live; `tools/setup-mac.sh` installs it.
6. Claude Code in the repo folder reads `CLAUDE.md` automatically. The `import-model` skill (in `.claude/skills`) brings a model into Studio. Studio can also be driven live through the Roblox Studio MCP server (enable it in Studio's AI Assistant settings).
7. Git habits: commit on `claude/alien-system-research`, `git pull --rebase origin claude/alien-system-research` before every push, never force-push, never commit audio or frame dumps from `media/tiktok/out/`. Secrets: the Open Cloud API key lives only in a shell variable on Ethan's Mac, never in a file or a commit; asset ids are fine to commit.

## 4. How the work runs

- Ethan and his Claude session (the coordinator) plan milestone by milestone: a shared contract (types, data, strings) first, then small build workers for the server and client halves, a strict analysis before every commit, a Studio test script per milestone, and a review of every diff.
- A second Claude session on Ethan's Mac runs the Studio tests (property reads and captures), the Blender generators and the Open Cloud uploads, and reports back.
- Codex (a second coding agent) takes self-contained cards from `docs/vault/02-how-we-work/Codex-Queue.md`: continuous integration, data lint, headless unit tests, a balance simulator.
- You: see section 6. Anything that touches game systems, data numbers or strings goes through the coordinator (send Ethan the ask or a note in the repo); visual work on models, props, dressing, textures, icons, sounds and references is yours to drive once the visual pass opens, within the UI Playbook and the Look plan. When a review changes the look of something, the Playbook is updated in the same change.

## 5. Status

Updated 2026-10-06.

**Done and Studio-verified (milestones 1 to 38).** Saves with session locking and schema migrations; the meadow and two biome regions with weather and day/night; wild spawns, the capture bar, the reveal; the camp with three stations, Scrap income, offline earnings; key materials and five ship modules with three gates each; menus and screens (Shop, Aliens, Codex, Ship, Quests, Gifts, Settings, Ranks, Star Chart); lures, a Scrap shop, Speed Boots; the Peddler with eggs and power-ups; luck and pity; the Field Notes chain with a reserved Warden encounter; a seven-step tutorial with a five-minute script (gift 1 lands at the first module's payoff); Welcome Week gifts, the spin wheel, the Meteor Shower; the Radar minimap; sound hooks (placeholder ids), particles, camera moments, the crash opener; the Robux launch shop (ids pending); the launch and World 2 Frostbyte with the Heater rule for blizzards; generated scenery and camp props; outposts and the orbit-map Star Chart; group reward, referral rewards, rejoin nudges and the notification opt-in card; a weekly catch leaderboard; daily and weekly quests with promo codes; per-world lighting and weather looks with particle sheets; the Friend Boost; size rolls (Tiny to Huge); catch variants (the Tidepool cast-and-reel bar and the Neon Grid rooftop chase as rules on the one bar); growth stages (Hatchling, Grown, Elder by time worked); five hero landmarks placed from layout data; the compass strip; the icon pack wired with fallbacks; the VFX pass (sprites on every emitter, reveal rays, a Perfect flash, tier auras); the Catch Rush (a shared 90-second round every ten minutes, paid by rank); fusion (four spare copies of a species become +1 level on the best one); companions (up to three resting aliens follow the player for everyone to see, each with a small perk by job and tier; more slots from a pass and spin-wheel tokens); mounts (a rideable follower carries the player at its tier's speed with a bigger leap, drawn under the rider for everyone); the weekly drop (an Alien of the Week on the Friday clock, limited species Vaulted outside their week, a themed Aurora week with a week-only Spectral overlay, Codex stamps and the HUD banner). Art so far: 32 species and 16 props modelled in Blender and given a look pass, 5 hero set pieces, 48 flat icons and 3 sprites; all 53 models uploaded through Open Cloud and installed with colours.

**Doing now.** Milestones 39 to 42: Warden sightings (the world's Warden walks a loop of the map every 20 minutes, uncatchable, with a trail, a banner and a compass marker), Radar Mk2 (250 studs, secrets as a pulsing "???" ping with a heartbeat, the rares not out right now with their condition), the developer panel (`/admin` commands for the team's user ids reaching every server), and the home planet (its own place, unlocked by the first launch; the house grid of rooms and furniture on the plot; habitats where resting aliens go on display and earn; the trophy hangar, the spin kiosk and the mailbox; visiting, 42e: a friend's home as a reserved server, the owner's save read without a lock, a lock level in Settings, a Wave at a displayed alien that pays both, with the teleport half waiting on the published home place) and the Scanner Pulse reader (43). Then the remaining multi-client and phone/tablet emulator checks; Codex cards C1 to C4 (CI, data lint, headless tests, balance report); the gloss and chrome pass in code.

**Next, in order.** Ethan's owner items (developer products and passes, Studio API access for real saves, the two place ids, the group id, the game name, the notifications default). Then the mechanics polish from playtests (the first five minutes above all). Then the last pass, the one you join for: the visual replication of the top games' quality with our own unique designs (species texture passes, world dressing in Studio, rendered glossy icons, soft sprites, 9-slice UI plates, the store icon and thumbnails), and the sound set. Worlds 3 to 7 are designed in `docs/GAME_DESIGN.md` section 8 and come after launch traction.

**The sign-off list.** `docs/MECHANICS-SIGNOFF.md` is the live checklist that closes the mechanics phase: what is verified, what is still open per milestone, and what only Ethan's Studio can close.

**Pace.** Milestones have landed at roughly four to six a day with Studio verification in step; the visual pass is scheduled right after the mechanics are signed off, which is where your work starts in earnest.

## 6. What you can start on now

1. Play World 1 cold and write playtest notes in `docs/playtests/<date>-<name>.md`: where you were confused in the first five minutes, where you waited, what you wanted to tap. This is the most valuable thing anyone can give the project right now.
2. Read the UI Playbook and the Look plan, then build a reference board for our own style (not copies): three games whose look we admire and what we take from each; put it in `docs/vault/05-ui-design/refs/board/` with a `README.md`. The brief we are working to: rendered, glossy, saturated two-tone, thick dark outline, soft shadow, chunky outlined text; unique silhouettes and palettes per world.
3. Learn the generators: run `blender -b -P tools/blender/alien_base.py -- --only Mossbop` and read `assets/models/Mossbop/notes.md`; try a texture or shape pass on one species on a branch and show a render. Models keep their height, pivot and material slot order so they drop into the game unchanged.
4. Dress a corner of the Meadow in the Team Create place with the installed props (Brushtool 2, Redupe, GapFill, ResizeAlign, Archimedes from the Creator Store); `docs/vault/06-art-pipelines/Map-Dressing.md` has the workflow. Dressing lives in the place file.
5. Sound: about 40 slots are listed in `src/shared/data/Sounds.luau`; pick candidates from the Creator Store audio library and send the ids with a note on each.
6. When the visual pass opens, the cards for it are written in the Codex queue and here; your Claude can take them the same way Codex does, under `AGENTS.md`.

## 7. A prompt for your Claude

```
Read docs/COLLABORATOR-BRIEF.md, then CLAUDE.md and AGENTS.md, in this repo. Set up my Mac per section 3 (ask me before any install), confirm ./tools/analyze.sh prints "analyze: clean", build and open the World 1 place, and then help me with item <N> of section 6. Follow the UI Playbook and the Look plan for anything visual, keep every number in src/shared/data and every string in src/shared/strings, never edit scripts inside Studio, commit on claude/alien-system-research with pull --rebase before push, and never commit audio, frame dumps or any key.
```
