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
| Launch morning: Studio sign-in, the music listen, the store page, the questionnaire, Public | Ethan | [[STORE-PAGE]] section 5; the morning report in [[2026-10-14]] |
| Overnight job 14: the Studio retests once Studio is signed in (rest of job 3, 4, the music load check, Storage Bay, `/dupes` then `/complete` no gap, Quiet moments) | Mac | [[Overnight]]; the Mac session's watcher resumes by itself |

## Next (in priority order; take from the top)

| Task | Owner | Notes |
|---|---|---|
| Collaborator setup: clone, Rokit, Rojo plugin, Claude Code, Studio MCP, Obsidian; analyze clean, tests pass | Collab, Collab-Claude | [[Handoff]] 13.3; Ethan's own setup and the problems he hit in [[Setup-and-Tips]] |
| Add the collaborator's Roblox user id to `src/shared/data/Admin.luau` `DeveloperUserIds` | Collab-Claude | One line; run the checks; commit |
| Cold playtest of World 1 from a fresh profile, notes in `docs/playtests/<date>-<name>.md` | Collab | The most valuable input right now: where you were confused in the first 5 minutes, where you waited, what you wanted to tap |
| Studio queue: milestone 46 re-check (resting, Back to play, menus count as play) | | `docs/STUDIO-QUEUE.md`, TESTING 46 |
| Studio queue: 49 playtime gifts | | TESTING 49 (step 4 on real saves) |
| Studio queue: 50 and 50b storage cap and Storage Bay | | TESTING 50, 50b; check the band at iPhone SE and iPad |
| Studio queue: 47 cinematics (arrival fly-through, Skip, Legendary push-in) | | TESTING 47 |
| Studio queue: 51a music system (silent tracks; the `Music: <state>` line), Legendary rumble | | TESTING 51a |
| Studio queue: UI fit pass at iPhone SE (667x375, "iPhone 7" in Studio's list) and iPad | | TESTING "UI fit pass" |
| Studio queue: alien list deltas, security hardening | | TESTING sections of those names |
| Studio queue: the runtime model loader (connected place, then a fresh baseplate), the assembly effect, the real-currency lines, security D1/D4/D6 | | TESTING sections of those names (built 2026-10-12, nothing run in Studio) |
| Studio queue: the rest (older milestones' multi-client and real-save steps) | | `docs/STUDIO-QUEUE.md` lists all 29 milestones, 102 steps |
| Codex C25: StyLua for the whole repo | Codex | Run last in a batch, alone |
| Install the five Studio plugins: Stravant GapFill & Extrude, ResizeAlign, Redupe; Brushtool 2; Archimedes v3 | Collab | Free ones freely, paid ones on Ethan's yes; update their rows in [[Tools-Status]] |
| Music: listen to the 12 picked rows in the place, swap any, pick Menus (still 0) | Ethan or Collab | [[Music-Plan]] pick tables (overnight job 5); one number per row in `data/Music.luau` |
| Sound picks: acquire one WardenAppear, Mount and Wiggle candidate each from the Toolbox in Studio, fill the three ids | Mac or Collab | Candidates in [[Music-Plan]] (overnight job 13); the other 36 slots are filled, unheard |
| Moonlit Forest (milestone 48): World 1 Forest at night, props, NightDresser, Lighting night row | Collab (art) + Coord (code) | PRE_PRODUCTION 5c item 4, [[Map-Dressing]] |
| Map dressing pass per place, by the map rules; camera rig anchors in `Workspace.Dressing.CameraRig` | Collab | [[Map-Dressing]] "Map design rules" and "Camera rig anchors" |
| Models still missing: home props Bench, Flag, Fountain, HabitatFrostbyte, HabitatVerdant, Planter, RoomCabin, RoomDome, RoomTower (Nebulyn, Spookum, Wisplet done overnight) | Collab or Mac | [[Blender-MCP]], [[Creature-Generation]]; upload through Open Cloud on Ethan's Mac |
| Icons v2 pass: the reference board, then batches of twelve | Collab + Coord | The plan is written: [[Look-Plan]] L5b (2026-10-12) |
| Store page: upload the picked renders, paste the description, set genre and devices | Ethan | Everything drafted in [[STORE-PAGE]]; the 10 s clip after launch |

## Waiting on Ethan (only he can do these)

| Task | Notes |
|---|---|
| **Sign in to Roblox Studio on the Mac** (it opened its login dialog after a forced quit overnight; every Studio job waits on it) | [[2026-10-14]] Mac session; the session resumes by itself once Studio is signed in |
| Listen to the overnight music and sound picks in the place (nobody has heard them) | [[Music-Plan]] pick tables; swap a row by changing its id |
| Launch morning checklist: join the private game on your phone, store page, Experience Questionnaire, Public, then tell the coordinator "public" | [[STORE-PAGE]] section 5 |
| Roblox: friend the collaborator, both age-checked, Collaborate > add them with Edit | [[Handoff]] 13.1 |
| GitHub: add the collaborator as a collaborator with Write | [[Handoff]] 13.2 |
| ~~`python3 -I tools/create_products.py --apply` for the six launch items~~ | Done 2026-10-14 by the Mac session (overnight job 2) |
| Mac installs: `bun` (for claude-mem), rtk, ccstatusline (optional) | [[Tools-Status]] |
| Plugin installs in his Claude Code: roblox-dev (ivar-anon), ShiroKSH roblox-studio, superpowers | He types the install lines himself ([[Claude-Plugins]]) |
| The stray place 82258778278086: keep or delete | |
| ~~Publish the three places privately~~ | Done 2026-10-14 by the Mac session (overnight job 6: world1 v89, world2 v4, home v3) |
| Experience Questionnaire, maturity answers, then going public | Identity and legal steps are his |

## Needs a decision (Ethan)

| Question | Options and recommendation |
|---|---|
| Launch from the repo publish (no hand-placed dressing or camera anchors) or dress in Team Create first and publish from Studio? | Recommended: launch this weekend from the repo publish (World 1 v89, World 2 v4, Home v3) and dress in week one; [[Hands-Off]] |
| The game's name (decision 19) | Candidates: "Crash Planet: Catch Aliens", "Alien Pals: Build a Rocket", "Planet Hoppers: Alien Collector"; check Roblox search for collisions; no reward words in the title |
| A Roblox group co-owned by both (decision 16), and when to transfer the experience | Recommended: start with Collaborate now; transfer before going public, re-uploading the 53 model assets under the group before the runtime loader ships ([[Handoff]] 13.1) |
| Rejoin notifications (decision 20) | Opt-in card on session 2+, event text only, three a week at most, behind a Config flag |
| Does a catch at the storage cap also pay its normal catch Scrap on top of the release value? | It does now; one line in `Economy.grantAlien` |
| Refuse a Storage Bay purchase past the hard cap? | Cannot happen with Worlds 1 and 2 (max 640 of 1,500) |

## Done (newest first; the full history is PRE_PRODUCTION 5b and the logs)

| Task | Owner | Date and commit |
|---|---|---|
| Overnight run: the loader passes in a built place (53 in 5.8 s), six shop ids live, three places published privately (v89, v4, v3), 51 icons approved, music and sound picks, the three Haunted Nebula species modelled and uploaded, store renders v1 and v2, ccusage in use | Mac | 2026-10-14, 1f88c8f, 707f0eb, 1da5f55, 8ae5673, 00d893c, 27fc743 |
| Overnight fixes: fuse pacing, alien-list sequence guard, quiet moments, shop tiles, `owned` grants, key-name fallback, sound-slot callers, store-page draft | Coord | 2026-10-14, 6687ae4, a5c261e, 94d2c09, 7678e14, 8421791, a538c9b, 4153b98 |
| Runtime model loader (`Services/Models`, `Shared/ModelInstall`), decision B18 | Coord | 2026-10-12, 3d47ca2 |
| Security decisions D1, D4, D6 (`server/Flight.luau`, `Capture.suspect`), decision B19 | Coord | 2026-10-12, 5983164 |
| The assembly effect `Vfx.Assemble` | Coord | 2026-10-12, f9f14a7 |
| Real-currency price lines (`Shared/ShopMath`), decision B20 | Coord | 2026-10-12, 8fe0492 |
| Codex C23, C24, C26 accepted; icons v2 plan ([[Look-Plan]] L5b) | Coord | 2026-10-12, 591ed11 |
| Setup-and-Tips note (Ethan's configuration, tips and tricks) | Coord | 2026-10-10 |
| Handoff file and this Board | Coord | 2026-10-10, 7161e5f |
| Codex C26 TESTING wording, C24 model asset table, C23 place publishing (in review) | Codex | 2026-10-08, c49aa61, 53c1930, 8bdecbd |
| Security hardening (visits, lookup budget, Peddler and Wave proximity) | Coord | 2026-10-07, 7430234 |
| Alien list deltas | Coord | 2026-10-07, ae5fae9 |
| Milestone 47 cinematics | Coord | 2026-10-07, 9c4110c |
| Milestones 49, 50, 50b, 51a, UI fit pass | Coord | 2026-10-07 |
| Computer-use jobs 1 and 2 part 1 (build camera, spin tiles, odds table at phone size, two-player visiting) | Ethan's desktop session | 2026-10-07 |
| Milestones 1 to 46 | Coord, Mac | 2026-10-04 to 2026-10-07 |
