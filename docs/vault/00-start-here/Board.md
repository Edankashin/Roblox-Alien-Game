# Board: who is doing what

The shared to-do list for Ethan, the collaborator and every Claude or Codex session. Background for every row is in [[Handoff]]. Updated by whoever changes a row, in its own small commit, so the other person sees it after a `git pull`.

**How to use it**

1. Pick an unowned row from **Next**, put your name in Owner, move it to **Now**, commit and push that change alone ("Board: claim <row>"). Then start.
2. Never work on a row someone else owns. Add a note in its Notes cell instead, or ask.
3. When done, move it to **Done** with the date and the commit hash. Anything you found goes in the daily log, `docs/vault/08-log/YYYY-MM-DD.md`, under your own heading.
4. Product decisions (prices, pacing, design changes, anything costing Robux, legal or identity steps) are Ethan's: put them under **Needs a decision**.
5. While you have Rojo connected to a Team Create place, say so under **Studio right now** and clear it when you disconnect (one Rojo connection per place at a time).

Owners: **Ethan**, **Collab** (the collaborator), **Coord** (Ethan's coordinator session), **Mac** (Ethan's Mac session), **Codex**, **Collab-Claude** (the collaborator's Claude).

## Studio right now

| Place | Who has Rojo connected | Since |
|---|---|---|
| World 1 | nobody | |
| World 2 | nobody | |
| Home | nobody | |

## Now

| Task | Owner | Notes |
|---|---|---|
| Handoff to the collaborator: this Board, [[Handoff]], Roblox and GitHub access | Ethan | Steps in [[Handoff]] 13.1 and 13.2 |

## Next (in priority order; take from the top)

| Task | Owner | Notes |
|---|---|---|
| Collaborator setup: clone, Rokit, Rojo plugin, Claude Code, Studio MCP, Obsidian; analyze clean, tests pass | Collab, Collab-Claude | [[Handoff]] 13.3 |
| Add the collaborator's Roblox user id to `src/shared/data/Admin.luau` `DeveloperUserIds` | Collab-Claude | One line; run the checks; commit |
| Cold playtest of World 1 from a fresh profile, notes in `docs/playtests/<date>-<name>.md` | Collab | The most valuable input right now: where you were confused in the first 5 minutes, where you waited, what you wanted to tap |
| Studio queue: milestone 46 re-check (resting, Back to play, menus count as play) | | `docs/STUDIO-QUEUE.md`, TESTING 46 |
| Studio queue: 49 playtime gifts | | TESTING 49 (step 4 on real saves) |
| Studio queue: 50 and 50b storage cap and Storage Bay | | TESTING 50, 50b; check the band at iPhone SE and iPad |
| Studio queue: 47 cinematics (arrival fly-through, Skip, Legendary push-in) | | TESTING 47 |
| Studio queue: 51a music system (silent tracks; the `Music: <state>` line), Legendary rumble | | TESTING 51a |
| Studio queue: UI fit pass at iPhone SE (667x375, "iPhone 7" in Studio's list) and iPad | | TESTING "UI fit pass" |
| Studio queue: alien list deltas, security hardening | | TESTING sections of those names |
| Studio queue: the rest (older milestones' multi-client and real-save steps) | | `docs/STUDIO-QUEUE.md` lists all 29 milestones, 102 steps |
| Review Codex C23 (publish.py), C24 (ModelAssets table), C26 (TESTING wording) | Coord | [[Codex-Reports]] |
| Runtime model loader (InsertService:LoadAsset from `data/ModelAssets`) | Coord | After C24 is accepted; then `publish.py --apply` is allowed |
| Codex C25: StyLua for the whole repo | Codex | Run last in a batch, alone |
| Install the five Studio plugins: Stravant GapFill & Extrude, ResizeAlign, Redupe; Brushtool 2; Archimedes v3 | Collab | Free ones freely, paid ones on Ethan's yes; update their rows in [[Tools-Status]] |
| Music picks: a track for each of the 13 `data/Music` rows (Creator Store licensed audio), auditioned in the place | Collab | [[Music-Plan]]; send ids with a note each; Coord wires them |
| Sound picks for the 39 `data/Sounds` slots | Collab | [[Moments]] says what each moment should feel like |
| Moonlit Forest (milestone 48): World 1 Forest at night, props, NightDresser, Lighting night row | Collab (art) + Coord (code) | PRE_PRODUCTION 5c item 4, [[Map-Dressing]] |
| Map dressing pass per place, by the map rules; camera rig anchors in `Workspace.Dressing.CameraRig` | Collab | [[Map-Dressing]] "Map design rules" and "Camera rig anchors" |
| Models still missing: Nebulyn, Spookum, Wisplet; home props Bench, Flag, Fountain, HabitatFrostbyte, HabitatVerdant, Planter, RoomCabin, RoomDome, RoomTower | Collab or Mac | [[Blender-MCP]], [[Creature-Generation]]; upload through Open Cloud on Ethan's Mac |
| Icons v2 plan and pass (top-game style references, render pipeline, sizes, review loop) | Collab + Coord | [[Look-Plan]]; owner direction says the current icons are not good enough |
| The assembly effect `Vfx.Assemble` | Coord | PRE_PRODUCTION 5c item 2 |
| Store page: icon, thumbnails, 10 s clip, description, genre | Collab + Ethan | Uses the cinematic shots; [[Growth-Playbook]] |
| Real-currency equivalents beside Robux prices | Coord | Compliance item, GAME_DESIGN 14 |
| Exploit-Review D1, D4, D6 | Coord | [[Exploit-Review]] |

## Waiting on Ethan (only he can do these)

| Task | Notes |
|---|---|
| Roblox: friend the collaborator, both age-checked, Collaborate > add them with Edit | [[Handoff]] 13.1 |
| GitHub: add the collaborator as a collaborator with Write | [[Handoff]] 13.2 |
| `python3 -I tools/create_products.py --apply` on his Mac for Spins1, Spins5, Spins12, SlotEveryStation2, CompanionSlot4, StorageBoost | Writes the ids into `Shop.luau` and pushes; [[Hands-Off]] |
| Mac installs: `bun` (for claude-mem), rtk, ccstatusline (optional) | [[Tools-Status]] |
| Plugin installs in his Claude Code: roblox-dev (ivar-anon), ShiroKSH roblox-studio, superpowers | He types the install lines himself ([[Claude-Plugins]]) |
| The stray place 82258778278086: keep or delete | |
| Publish the three places privately (desktop computer-use job 4 or `publish.py --saved`) | After the Studio checks pass |
| Experience Questionnaire, maturity answers, then going public | Identity and legal steps are his |

## Needs a decision (Ethan)

| Question | Options and recommendation |
|---|---|
| The game's name (decision 19) | Candidates: "Crash Planet: Catch Aliens", "Alien Pals: Build a Rocket", "Planet Hoppers: Alien Collector"; check Roblox search for collisions; no reward words in the title |
| A Roblox group co-owned by both (decision 16), and when to transfer the experience | Recommended: start with Collaborate now; transfer before going public, re-uploading the 53 model assets under the group before the runtime loader ships ([[Handoff]] 13.1) |
| Rejoin notifications (decision 20) | Opt-in card on session 2+, event text only, three a week at most, behind a Config flag |
| Does a catch at the storage cap also pay its normal catch Scrap on top of the release value? | It does now; one line in `Economy.grantAlien` |
| Refuse a Storage Bay purchase past the hard cap? | Cannot happen with Worlds 1 and 2 (max 640 of 1,500) |

## Done (newest first; the full history is PRE_PRODUCTION 5b and the logs)

| Task | Owner | Date and commit |
|---|---|---|
| Handoff file and this Board | Coord | 2026-10-10 |
| Codex C26 TESTING wording, C24 model asset table, C23 place publishing (in review) | Codex | 2026-10-08, c49aa61, 53c1930, 8bdecbd |
| Security hardening (visits, lookup budget, Peddler and Wave proximity) | Coord | 2026-10-07, 7430234 |
| Alien list deltas | Coord | 2026-10-07, ae5fae9 |
| Milestone 47 cinematics | Coord | 2026-10-07, 9c4110c |
| Milestones 49, 50, 50b, 51a, UI fit pass | Coord | 2026-10-07 |
| Computer-use jobs 1 and 2 part 1 (build camera, spin tiles, odds table at phone size, two-player visiting) | Ethan's desktop session | 2026-10-07 |
| Milestones 1 to 46 | Coord, Mac | 2026-10-04 to 2026-10-07 |
