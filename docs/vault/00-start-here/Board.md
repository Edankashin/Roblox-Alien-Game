---
tags: [start-here, plan, launch]
aliases: [To-do list, Who is doing what]
up: "[[Start-Here]]"
---
# Board: who is doing what

**Ethan: every open decision and every row with your name is laid out in [[Decide-Now]], answered by number.**

The shared to-do list for Ethan, the collaborator and every Claude or Codex session. Background for every row is in [[Handoff]]. Updated by whoever changes a row, in its own small commit, so the other person sees it after a `git pull`.

Launch state on one screen: [[Launch-Dashboard]]. Every folder of the vault has a hub, mapped from [[Start-Here]].

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
| Overnight job 14, the rest: job 8 store shots, job 4 World 2 and Home, job 3's unrun sections (51a, 47, UI fit, deltas, security D1/D4/D6, reduced-motion assembly, real-currency step 2, phone performance, 45, STUDIO-QUEUE World 1 rows), 50b step 7, quiet-moments step 4; plus the retests of 0825880 (Storage Bay with the new Output lines, the first catch on a fresh profile) | Mac | [[Overnight]]; the music load check passed, the Decal-id icon bug is fixed (0c8c2af) |

## Next (in priority order; take from the top)

| Task | Owner | Notes |
|---|---|---|
| Lighting: `src/shared/data/Lighting.luau` carries `LightingStyle` and `PrioritizeLightingQuality` instead of a Technology value; judge every night and weather look a second time with shadows off and Soft forced | | Cloud. [[Decisions]] B31. Start with a Studio probe: the data header says Lighting.Technology cannot be set from a script (TESTING milestone 22 sets Future by hand), so check whether the two new properties can be set from one; then `LightingDirector`, the TESTING step and [[Look-Plan]] (which still says Future) |
| HUD rebuilt from the canvas, one screen per change, once Ethan picks a board | | Cloud. [Catch an Alien UI](https://claude.ai/artifact/GsddVfW4nSoBSRpEpCSvi4), [[Claude-Design-Brief]], the phone rules in [[UI-Playbook]]; `Builder` and `Theme`, Scale only; the Playbook changes in the same commit. Waits on Ethan's pick |
| The reveal's three beats: taps to crack, shards and rays in the rarity colour, the card with "1 in N (x%)" | Cloud worker | Built 2026-10-15 (one WIP commit, see the log); waits on the Mac's Studio check, [[TESTING]] "Reveal beats". `src/client/UI/Reveal.luau`; tap count, growth and durations in a new table under `src/shared/data`; strings keyed; the chance read from the odds table; the day-7 Epic egg first. [[UI-Playbook]] "Phone rules from the design research" |
| Hybrid sculpt prototype on Moop, Sparkfox and Mitt: a fused core plus crisp features, a shaped mouth | | Cloud. [[Sculpt-Pass]], [[Character-Pipeline]] "The bar after the research"; `tools/blender/species_sculpt.py` on a scratch copy; Ethan looks at the sheet before any model is replaced |
| Mac: open `media/blockbench/Sparkfox.bbmodel` in Blockbench, screenshot the 3D view and the outliner, and report what fails (opens without error, coloured, group pivots, `idle` plays, shading); then Mossbop | | Mac. Waits on Ethan installing Blockbench (Waiting on Ethan). The checklist is "What the Mac must verify" in [[Model-Toolchain]] "The writer"; write the result in the daily log and flip the `to_bbmodel.py` row in [[Tools-Status]] to in use |
| Mac: the Blockbench glTF animation probe: a three-group test creature with one `idle`, exported as glb with animations, into Studio (Rig Type Custom); check `Bone`s, `AnimSaves`, the Animation Editor plays it, Publish gives an id; measure a 16-unit cube in studs and note the facing; then the same with a Blender-rigged cube | | Mac. Waits on Ethan installing Blockbench (Waiting on Ethan). Steps and the results table in [[Model-Toolchain]] section 6; flip the three rows in [[Tools-Status]] "Added from the model toolchain decision" |
| Mac: open a baked Sparkfox in Blockbench and paint one stroke: `python3 tools/blender/unwrap_bake.py --species Sparkfox --out /tmp/uvbake`, then `python3 -I tools/blockbench/to_bbmodel.py --species Sparkfox --models /tmp/uvbake --out /tmp/bb`, open `/tmp/bb/Sparkfox.bbmodel`; check the texture is 512 px with separate islands (the UV tab), paint one stroke on the Body, confirm the stroke lands where the UV tab says and nothing else changes, save, and export glTF once to see the texture embedded | | Mac. Waits on Ethan installing Blockbench (Waiting on Ethan). Built and run in the cloud on a scratch copy only; [[Surface-Pass]] "UV unwrap and palette bake". Report in the daily log; if the islands are too fragmented to paint (Sparkfox has 414), try `--angle-limit 80` or `89` and say which
| Mac: after the Obsidian plugin is in, verify the connection (reads only) and set the Tools-Status rows to in use | | Mac. Waits on Ethan's install (Waiting on Ethan); [[Tools-Status]] "Added from the design research" |
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
| Loading screen in ReplicatedFirst (our art and a progress line while a cold server loads the 53 models, up to 20 s today): built (B22), and in block cells since 2026-10-21 (launch polish worker: a pixel alien on a floating grass island, a cell-by-cell bar; [[UI-Playbook]] "The loading screen in block cells"); waits on the Mac's [[Overnight]] job 47 | Launch polish worker | From the 2026-10-14 audit: bounce in the first 60 s is the number the references fear most |
| Co-play: a "catch with a friend" Field Notes step (the measurement half is done, aff40f7) | | ZPLRKjEf2; `Quests.luau` |
| `deadcode.py --write` and `perf_report.py --write` drop the hand-written tails of Dead-Code and Performance (the "C18 reviewed cleanup" and "Fixed (2026-10-07)" sections); make the generators keep a tail below a marker, then regenerate both notes | | Found 2026-10-15 by the generator-frontmatter worker; both notes are stale against the source until then |
| Codex C25: StyLua for the whole repo | Codex | Run last in a batch, alone |
| Install the five Studio plugins: Stravant GapFill & Extrude, ResizeAlign, Redupe; Brushtool 2; Archimedes v3 | Collab | Free ones freely, paid ones on Ethan's yes; update their rows in [[Tools-Status]] |
| Music: listen to the 12 picked rows in the place, swap any, pick Menus (still 0) | Ethan or Collab | [[Music-Plan]] pick tables (overnight job 5); one number per row in `data/Music.luau` |
| Sound picks: acquire one WardenAppear, Mount and Wiggle candidate each from the Toolbox in Studio, fill the three ids | Mac or Collab | Candidates in [[Music-Plan]] (overnight job 13); the other 36 slots are filled, unheard |
| Moonlit Forest (milestone 48): World 1 Forest at night, props, NightDresser, Lighting night row | Collab (art) + Coord (code) | PRE_PRODUCTION 5c item 4, [[Map-Dressing]]. Now the Starhollow Forest ([[Decisions]] B48): its 13 block-cell props and 3 tiles are built (2026-10-21, [[Blocky-Style]] "Starhollow Forest", Mac job 45); the world worker builds the area |
| Map dressing pass per place, by the map rules; camera rig anchors in `Workspace.Dressing.CameraRig` | Collab | [[Map-Dressing]] "Map design rules" and "Camera rig anchors" |
| Models still missing: home props Bench, Flag, Fountain, HabitatFrostbyte, HabitatVerdant, Planter, RoomCabin, RoomDome, RoomTower (Nebulyn, Spookum, Wisplet done overnight). Built 2026-10-21 as block-cell props ([[Blocky-Style]] "The home planet", `media/studio/2026-10-21/home_props_v1.jpg`), the home floor and plot in tiles; waits on the upload (job 40) and the Mac's [[Overnight]] job 47 | Launch polish worker | [[Blender-MCP]], [[Creature-Generation]]; upload through Open Cloud on Ethan's Mac |
| Icons v2 pass: the reference board, then batches of twelve | Collab + Coord | The plan is written: [[Look-Plan]] L5b (2026-10-12) |
| Store page: upload the picked renders, paste the description, set genre and devices | Ethan | Everything drafted in [[STORE-PAGE]]; the 10 s clip after launch |
| Roster redesign 1: the effects data and renderer (`data/Effects.luau`, the Tiers ladder columns, `World/AlienFx.luau`, the Attach calls in the seven renderers, the caps in Config) | | Cloud. [[Roster-Redesign]] sections 6 and 7 step 1; [[Decisions]] B34, B35, B39; `./tools/analyze.sh` clean |
| Roster redesign 2: names v3 applied (the collision screen on the 19 new picks, then `Species.luau` `name` only, `TUT_2` and `TUT_3`, the GAME_DESIGN roster table, `names_check.py` rules) | | Cloud. Waits on Ethan's letters per species ([[Roster-Redesign]] section 5); [[Decisions]] B36; ids never change |
| Roster redesign 3: the Fenrir and dragon prototypes (the `Fenripup` recipe rebuilt to the brief, a new `Suiryn` recipe, hybrid sculpt on a scratch copy, sheets for Ethan) | | Cloud, then the Mac for the Studio look. [[Roster-Redesign]] section 3; nothing under `assets/models/` changes until Ethan says yes |
| Roster redesign 4: the ladder applied to auras and the reveal (`AlienFx` reads Tiers, `UI/Reveal.luau` beats per tier with a `data/Reveal.luau`, `CameraDirector`, per-tier stingers in `Sounds.luau`, plate styles in `Builder`) | | Cloud. [[Roster-Redesign]] section 1; shares the reveal table with the B29 three-beats row above; the Playbook updated in the same change |
| Roster redesign 5: the hero slate, one per week in the order of the note (Raiju, Qilin, Kerbos, Pegasi, Sphinx, Airava after the two prototypes) | | Cloud and Mac. [[Roster-Redesign]] section 3; waits on Ethan's confirmation of the slate and B37 |
| Roster redesign 6: the Studio check on a phone (a TESTING milestone: iPhone SE and iPad, a dozen wild aliens with a Cosmic, `perf_report.py` numbers, Reduced Motion on and off, two reveals filmed) | | Mac. [[Roster-Redesign]] section 7 step 6; numbers into [[Performance]] |
| Design reference follow-ups, the five skills from ZPLSHwXqp ([[Character-Pipeline]] "The design reference (ZPLSHwXqp)"): (1) a cube-cell build route, `species_sculpt.py --method voxel`, a prototype that reports triangles per pitch; (2) pattern rows with an ink edge on the atlas (`unwrap_bake.py`, Blockbench for hero species); (3) an emissive line map (`<Id>_emissive.png`, `install_models.luau`); (4) articulated hero parts and a display pose (a `split` list in `species_sculpt.py`, extends the Suiryn kept segments); (5) the numbered concept loop and arrival key art | | Cloud, one skill per change, on a scratch copy; nothing under `assets/models/` changes until Ethan says yes. Skill 1 is a different house look from the soft skin: Ethan decides whether it ships at all |

## Waiting on Ethan (only he can do these)

| Task | Notes |
|---|---|
| **Obsidian connection** (about 10 minutes, Studio and Blender closed): install the "Local REST API" community plugin in Obsidian, enable the Obsidian CLI (Settings, General), and run the one `claude mcp add` line from Setup-and-Tips on the Mac | [[Setup-and-Tips]] "Obsidian connected to Claude"; the API key goes into that command only, never into a file; first run the `git check-ignore` line there |
| **Approve or amend the hooks proposal** (SessionStart prints Now, PostToolUse lints vault writes, Stop asks for a log line), and say if the path-scoped rules should follow | [[Setup-and-Tips]] "Hooks proposal (not applied)"; no session applies it, it edits `.claude/settings.json` |
| **Look at the Claude Design canvas and pick a board per screen** (HUD, Aliens, Shop, the reveal), plus the species sheet and thumbnail comps | [Catch an Alien UI](https://claude.ai/artifact/GsddVfW4nSoBSRpEpCSvi4); [[Claude-Design-Brief]]; the rebuild rows in Next wait on it |
| **Close the extra Roblox Studio windows on the Mac** (File > Close, Don't Save; keep one). Four windows wedged Studio's plugin lock at 09:40 EDT; every Studio job waits on it | [[2026-10-14]] Mac session; then tell the Mac session "Studio is back" or start a new one with the Overnight prompt |
| Listen to the overnight music and sound picks in the place (nobody has heard them) | [[Music-Plan]] pick tables; swap a row by changing its id |
| Launch morning checklist: join the private game on your phone, store page, Experience Questionnaire, Public, then tell the coordinator "public" | [[STORE-PAGE]] section 5 |
| Roblox: friend the collaborator, both age-checked, Collaborate > add them with Edit | [[Handoff]] 13.1 |
| GitHub: add the collaborator as a collaborator with Write | [[Handoff]] 13.2 |
| ~~`python3 -I tools/create_products.py --apply` for the six launch items~~ | Done 2026-10-14 by the Mac session (overnight job 2) |
| Open Cloud key hygiene (batch 6, ZPLSaURU3): in the Creator Dashboard check the key is scoped to the Assets API (read and write) and `universe-places:write` for this experience only, has an expiry, and lives only in `~/.zshrc`; rotate it if it was ever pasted anywhere | [[2026-10-14]] batch 6 notes; two minutes |
| **Screen Recording permission for Terminal** (System Settings > Privacy & Security > Screen Recording, then restart Terminal) so the Mac session can record the three store clips (job 18); or record them yourself with Cmd+Shift+5, 15 s each: a Rare catch and its Reveal, a module snapping together, the launch | [[2026-10-14]] Mac evening |
| **Quit Roblox Studio before tonight's Blender run** (File > Quit, Don't Save): on this 8 GB Mac one Studio in Play already fills the swap (5.8 GB after an hour), and Blender cannot share it | [[Setup-and-Tips#Memory on the Mac|Setup-and-Tips "Memory on the Mac"]] |
| Join the private game on your phone: world1 v90, world2 v5, home v4 carry everything built on 2026-10-14 except the evening fixes | [[STORE-PAGE]] section 5 |
| **Install Blockbench** (free, no account): the macOS build from `blockbench.net`, or open `web.blockbench.net` in the browser; then tell the Mac session so the glTF animation probe can run | [[Model-Toolchain]]; [[Tools-Status]] "Added from the model toolchain decision" |
| **Decide the Substance 3D Painter licence**: Steam perpetual (about $200, no Assets library), Adobe Collection (about $60 a month), the free student licence (non-commercial, a trial only), or not now; the 8 GB Mac is below its published 16 GB minimum, so the 30-day trial comes first either way | [[Model-Toolchain]] section 4; prices are snippets, check the live pages |
| Mac installs: `bun` (for claude-mem), rtk, ccstatusline (optional) | [[Tools-Status]] |
| Plugin installs in his Claude Code: roblox-dev (ivar-anon), ShiroKSH roblox-studio, superpowers | He types the install lines himself ([[Claude-Plugins]]) |
| The stray place 82258778278086: keep or delete | |
| ~~Publish the three places privately~~ | Done 2026-10-14 by the Mac session (overnight job 6: world1 v89, world2 v4, home v3) |
| Experience Questionnaire, maturity answers, then going public | Identity and legal steps are his |
| **GAP** from [[Asks-Ledger]]: **allow `tiktok.com`, `tiktokcdn.com` and `tiktokcdn-us.com`** in this cloud environment's network settings (the environment menu, Edit, Network access, Allowed domains; leave "Allow package managers" on), so the coordinator fetches the links you send itself | Asked 2026-10-04 ("find any way to watch the TikToks I send you"); suggested 2026-10-07 and 2026-10-14, never applied; today every link waits for the Mac. Optional, two minutes |
| **Names v3**: a letter per species (A, B or C) or your own names, and your call on the seven near-misses and Pegasi | [[Roster-Redesign]] section 5, [[Species-Names]] "Collision screen (2026-10-15)"; you said on 2026-10-15 you would name them yourself if the alternatives were not better |
| **Look at the sheets** and say which direction is right before any model is replaced: the hybrid sculpt pass 2 (all 35), Fenrir v2 and Skydrake, the UV bake; confirm the hero slate and the "creatures, not deities" line | [[Sculpt-Pass]], [[Hero-Aliens]], [[Surface-Pass]], [[Decisions]] B37; copies in `media/studio/2026-10-15/` |
| **Pick the icon and the thumbnail order**, or say "use yours" | [[Thumbnail-Research]]; `media/store/2026-10-15/`; open since 2026-10-14 |
| **The Mac's 2026-10-15 transcript**: say whether it is exported and what to redact | [[Overnight]] job 31; [[Transcripts]] |
| When the launch date is set: **link your Mac to the coordinator** (Devices in the composer) so it fills the Creator Dashboard from the run sheet, checks the Open Cloud key and creates the group Moop Games (100 Robux; say yes to the spend) | `docs/STORE-PAGE.md` 5d, [[Group-Page]], [[Launch-Dashboard]]; you asked for this on 2026-10-14; parked while the launch is off |

## Decided 2026-10-15 (Ethan)

**The weekend launch is off.** Ethan: "I'm not satisfied with launching the game right now given the designs and UI of the game." No new date until the creature designs read as seamless, complete characters and the UI meets the top games' bar. Research under way on how successful Roblox developers design models, worlds and UI, how they use Obsidian with Claude and Blender bridged to both, and how Claude Design fits (report: `reports/Roblox creature UI and Claude workflows.md`, notes in `research_notes/`). The 32 surfaced bodies stay un-uploaded; the private build (v90, v5, v4) stays as it is; the dashboard, group and clips wait.

The plan from the research is in [[Decisions]] B27 to B33 and the hot note [[Now]]: one connected skin per creature by the hybrid fuse, the phone UI rules, Claude Design as the review surface, the lighting change, and the vault hooks and Obsidian connection as proposals for Ethan.

## Decided 2026-10-14 (Ethan)

Name **Catch an Alien** (decision 19). Launch from the repo publish, dress in week one. Make the group now (100 Robux), named **Moop Games** (the species rename gave the Mossbop its name Moop; the emblem banner reads MOOP, `media/group/emblem_v1.png`); the experience stays under Ethan's account for launch (decision 16). Ship the twelve unheard music picks and swap in week one. Max players 8. Open: the icon and thumbnail picks (Ethan is looking at them). The species rename is applied: the second-pass top picks, see [[Species-Names]] and decision B26.

## Needs a decision (Ethan)

| Question | Options and recommendation |
|---|---|
| Rejoin notifications (decision 20) | Opt-in card on session 2+, event text only, three a week at most, behind a Config flag |
| Substance 3D Painter licence (Steam perpetual, Adobe plan, student trial, or not now) | Recommend: the free trial on the Mac first, Painter only for the six or seven hero species, and Blockbench (free) for everyone's textures and animation; buy nothing until the trial shows Painter runs on 8 GB ([[Model-Toolchain]] section 4) |
| Does a catch at the storage cap also pay its normal catch Scrap on top of the release value? | It does now; one line in `Economy.grantAlien` |
| Refuse a Storage Bay purchase past the hard cap? | Cannot happen with Worlds 1 and 2 (max 640 of 1,500) |
| Credits for the generator trial: one species prompt through Tripo P1, Meshy and Rodin, judged on the three ship checks | About 10 to 15 USD. Recommend yes for one species, to see whether a hero creature is worth generating; until then the fused roster is the safer choice ([[Character-Pipeline]], [[Tools-Status]]) |
| **GAP** from [[Asks-Ledger]]: working through the usage limit. The limit stopped the work six times between 2026-10-05 and 2026-10-15, twice on the night you asked for it to run uninterrupted; your 2026-10-05 OmniRoute ask was skipped on terms and the question never came back to you | Options in [[Claude-Plugins]] "Keeping working when the subscription limit is hit": (a) an Anthropic API key in the Mac shell for the overnight runs, billed per use, the same models, or (b) accept the resets and plan the nights around them. Pooled accounts and model routers are out (terms). Recommend (a) for overnight runs only, with a monthly cap you set |

## Done (newest first; the full history is PRE_PRODUCTION 5b and the logs)

| Task | Owner | Date and commit |
|---|---|---|
| The design reference ZPLSHwXqp watched and noted (the **GAP** from [[Asks-Ledger]]): `media/tiktok/NOTES.md` "The design reference ZPLSHwXqp", a 12-frame sheet in `docs/vault/06-art-pipelines/refs/`, and [[Character-Pipeline]] "The design reference (ZPLSHwXqp)". The clip shows finished creatures and no design process; the five skills to add are the Next row above | Worker (reference) | 2026-10-15, WIP commit |
| The X-post half of the 2026-10-15 research (a GAP from [[Asks-Ledger]]): 66 posts found with the search tool's domain filter, four sections in `research_notes/Roblox creature UI and Claude workflows/x_posts.md`, the ten best and five takes in [[X-Posts]]; x.com itself is unreachable from the cloud, so every entry is snippet-only | Worker (X posts) | 2026-10-15, WIP commit |
| The Blender side of the bbmodel writer: `tools/blender/unwrap_bake.py` unwraps a species GLB once (Smart UV Project over the whole creature, islands packed into 0..1, no overlap, slots, triangles, height, pivot and shading checked equal to the input) and bakes a 512 px palette (slot hex times the `COLOR_0` gradient, optional soft AO); `to_bbmodel.py` reads a `<Id>_palette.png` next to the GLB; `preview.py --lit --textured`; run on all 32 recipe species into scratch (islands 226 to 712, texels covered 30 to 68%, overlap 0.00%, none failed), sheet `refs/surface-pass/uv_bake_sheet.jpg`; `--write-assets` is built and not used, `assets/models` untouched; [[Surface-Pass]] "UV unwrap and palette bake" | Worker (uv bake) | 2026-10-15, WIP commit |
| The bbmodel writer, `tools/blockbench/to_bbmodel.py`: a species GLB and `materials.json` become a Blockbench Generic Model project (a mesh and a group per slot, a 128 px palette texture, an example `idle`), `--check`, `tools/tests/test_to_bbmodel.py`, the first files in `media/blockbench/`; [[Model-Toolchain]] "The writer" | Worker (bbmodel) | 2026-10-15, WIP commit; not yet opened in Blockbench |
| Per-species effects and idle motion for all 35 species, a rarity ladder (Common one mote to Secret dark and grandest), caps and the nearest-12 rule: `data/Effects`, `Shared/EffectsMath`, `Client/World/SpeciesFx`, wired into the wild, camp, companion (mount included) and home-display renderers, and a species `sound` played on its beat; [[Species-Effects]] | Worker (effects) | 2026-10-15, WIP commits; Studio check in TESTING "Species effects" |
| Vault pass: a hub per folder ([[Start-Here]]), frontmatter on every note, broken links and orphans fixed, the glossary, [[Tools-Status]] rows, the [[Launch-Dashboard]], and `tools/lint_vault.py` in `tools/lint.sh` | Worker (vault) | 2026-10-15 |
| Silhouette and surface pass, all 32 species: bodies rebuilt with surfaces in the cloud (21b3b9a World 1 with Gaiabloom, Ra-dish, Glim and Rocklobber reworked; 6b2edd8 Frostbyte), previews in `media/studio/2026-10-15/`; the names applied (a4a6cfe); the textures route (dcae573); the thumbnail research (e680b42). Upload waits on Ethan's "upload" and the Mac's two probes | Coord | 2026-10-15 |
| Silhouette pass, World 1: the bible, the recipes, the builder (0c498ca) and the 16 bodies built on the Mac (b95035c to c74d590); previews in `assets/models/<Id>/<Id>.png` and `media/studio/2026-10-14/silhouette_world1_mac_previews.jpg`; upload waits on Ethan (job 24) | Coord + Mac | 2026-10-14 |
| Evening fixes from the Mac's retests: eggs in season, Reveal hush first, Catch an Alien title (f1d2d1b); overlay badges fit, night ground tint (92228c2); names v2 sheets (bbaad9c); memory tool (c8a1ff6); group page (7a40cf7) | Coord | 2026-10-14 |
| Audit of the references, afternoon build: LaunchGold overlay and Sparkfox week (194d5e4), co-play Party event and `friends` on Catch (aff40f7), day-2 Boost Pair gift, LAUNCHWEEK code, notifications off (9c0b7bb), titled thumbnails (805fbef), icon tool Image ids (66910a8), quiet-moments hush (b43322a), first-catch deltas fix (0825880) | Coord | 2026-10-14 |
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
