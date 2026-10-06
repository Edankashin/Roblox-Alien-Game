# Mechanics sign-off

The checklist that closes the mechanics phase before the visual pass (the pass Ethan and the collaborator run together, `docs/vault/06-art-pipelines/Look-Plan.md`). Rows come from the build-status table in `docs/PRE_PRODUCTION.md` section 5b; the test scripts are in `docs/TESTING.md`. Updated 2026-10-06.

## 1. Verified in Studio, nothing open

- **1 to 2** Bootstrap, saves
- **3 to 4** Camp, Scrap income, materials, ship modules, Forest and Cave, condition-gated nodes
- **5 to 6** Menu stack, Aliens, Codex, Nearby, catch Scrap, lures, Scrap shop, Speed Boots, Peddler, power-ups, luck
- **7 to 8** Field Notes, shrine, reserved Warden; the tutorial
- **9** Welcome Week gifts, spin wheel, Meteor Shower
- **10** Radar Mk1 minimap, blip waypoints
- **11** Sound hooks
- **12** Mesh models in the world
- **13** Settings, preferences, analytics funnel
- **16** The Heater rule for blizzards
- **17** Environment props
- **21** Daily and weekly quests with a reroll, promo codes
- **22** Look pass L1
- **25** Size rolls
- **26** Catch variants
- **29** Look pass L3 hero landmarks
- **30** The compass strip
- **35** Fusion
- **38** The weekly drop

## 2. Verified with a part still open

Each line names what is still open; most of these are the multi-client, real-save or device-emulator checks that only Ethan's Studio can run.

- **1** Game name: Undecided; working title AlienGame in code | Day 1 (place name, strings)
- **2** Art style: Answered: smooth low-poly | Before any modeling
- **3** Number of jobs at launch: Answered: 3 (Gather, Build, Spark) | Day 1 (data tables)
- **4** Companions following the player: Answered: yes, 3 slots | Day 1
- **5** Splicing: Answered: none; Secrets come from codex Sets | P1
- **6** Theft or borrow: Answered: borrow only; raid parked | P2
- **7** World order: Answered: Verdant, Frostbyte, Neon Grid | P1
- **8** Event rerun policy: Answered: monthly Vault Rotation plus annual reopening | P1
- **9** Permanent personal luck pass: Answered: not at launch | Launch
- **10** Mounts use a companion slot: Answered: yes | P1
- **11** Scrap for Robux: Answered: never | Day 1 (shop data)
- **12** UI font: Answered: Fredoka One | Day 1 (theme module)
- **13** UI palette: Answered: stud dialect, playbook values | Day 1
- **14** Icon pack: Answered: placeholders until chosen | First UI pass
- **15** Who owns the Roblox group and the experience: Answered: co-owned by both team members | Day 1
- **1** 0: Crash landing cinematic, 8 seconds, skippable after the first time |
- **2** 0: "Drag 3 wreck plates to the frame." Player gathers by hand. Ship bar appears at the first plate | Ship bar
- **3** 1: Mossbop waddles up, "!" bubble. First capture, zone 40% wide, cannot fail (ticker slows near the zone) | Capture bar, codex
- **4** 1: Mossbop auto-walks to the Gather station and takes over gathering. Timer visibly drops | Stations
- **5** 2: "Build a panel." Player holds a button. Puffpuff appears, same ritual, takes over building | Second job
- **6** 3: Scrap counter appears with "+" text. First module hits 50%. "Catch 3 more aliens while they work" | Scrap
- **7** 3: Free catching in the Meadow with the Nearby panel on. A Rare (Sparkfox) is guaranteed to spawn once in this window | Nearby panel
- **8** 7: Module 1 completes. Camera pan, part snaps, bass hit. Field Notes step 1 appears with Speed Boots as the reward | Quests, gear
- **9** 8: "Thrusters need Glowroot from the Forest." Waypoint set. Peddler lands for the first time. Welcome Week gift 1 pops | Peddler, gifts
- **14** Robux launch shop: pass with grants; receipts wait on live ids
- **15** World 2 Frostbyte data and blockouts, one place per world, the launch: pass (15b, 15c on World 2; 15c step 4 waits on a World 1 Connect)
- **18** Outposts: pass on World 2; step 5 waits on the World 1 place
- **19** Group-join reward, referral rewards, rejoin nudges, notification opt-in card: pass (group step needs a group id; session-2 ask needs real saves)
- **20** Weekly "Catches this week" leaderboard: pass single-client; multi-client and the shared store wait on Ethan
- **23** Friend Boost: step 1 pass; friends need a multi-client test
- **24** Look pass L3 particles: pass; rain visibility waits on real particle textures (L5)
- **27** The five-minute script: pass (steps 2 to 5); the rejoin step waits on real saves
- **28** Growth stages: pass (steps 1 to 4, 6); the card chips were widened after the run; the away-time line waits on real saves
- **31** Look pass L5 icons: step 1 pass (fallbacks unchanged); the image upload is part of the last visual pass
- **33** The VFX pass: auras pass; the flash needs a human Perfect; sprites wait on the last visual pass
- **34** The Catch Rush: pass (steps 1 to 3, 5, and 6 on a fresh profile); singular toasts fixed; 4 and 7 need multi-client
- **36** Companions: pass (steps 1 to 4: follower on the ground 6 studs behind, snaps after a jump and a world change, perks line fits, token and pass slots, the working-card toast, a live /follow redraw, luck +0.1 exactly); 5 needs multi-client, 6 real saves
- **37** Mounts: pass (steps 1 to 4 on 7248c54: 25.6 and 30.72 walk speed, 11.52 jump height, hips lifted by the seat, the mount centred under the rider through walking, turning, jumping and a world change, the arc closes with no gap, fusion keeps the ridden copy); Thunderhog's seat raised 0.4 for its quills; 5 needs multi-client, 6 real saves

## 3. Built, Studio run queued on the Mac

- **16** Free station slot growth: Built as the default on 2026-10-05: slot 2 on every station unlocks with the Thrusters, slot 3 with the Nav Array (`unlocksSlots` in `Modules.luau`); passes would add a 4th and 5th. The simulator (section 3.3) showed one slot per station leaves 100+ aliens idle by module 5 and makes the Nav Array the only Scrap-blocked module. Change the two numbers in the data table if the team prefers another curve | Confirm or change
- **32** Icons on the remaining surfaces: built; Studio check after the image upload
- **39** Warden sightings: queued on the Mac
- **40** Radar Mk2: queued on the Mac
- **41** The developer panel: queued on the Mac

## 4. What only Ethan can close

- Multi-client runs (Test > Clients and Servers): milestones 20, 23, 34 step 4, 36 step 5, 37 step 5, 41 step 4 (published game, two servers).
- The device emulator pass at iPhone SE and iPad on every screen (the Aliens card chips, the perks line, the Ride button, the Codex stamps, the compact "not now" column, the Shop's Gear scroll).
- Real saves: Studio API access on the place, then `Config.UseDataStoreInStudio = true`, to run every rejoin step and the schema migrations (now v9).
- The Creator Dashboard: developer products and passes (ids into `src/shared/data/Shop.luau`), the two place ids (`Worlds.luau`), the group id (`Social.luau`), the game name, the notifications default, and the team's user ids into `src/shared/data/Admin.luau` for the developer panel.
- Saving the World 1 place after the installer (Cmd+S) so the models stay.

## 5. Open design decisions

- The name (decision 19), rejoin notifications (20), world signatures beyond the two catch variants (21).
- Hidden spots (section 5 of the design) are not built in any world; Radar Mk2 ships without them and Mk3 waits on World 3.
- Riding has no animation, saddle cosmetics or Hover terrain yet; Glide, Swim and Climb wait on their worlds.

## 6. Rule for the visual pass

No mechanic changes during the pass: the look pass edits data (`Lighting`, `Weather`, `Icons`, `Theme`), meshes, textures, sprites, 9-slice plates and the place file. A playtest finding that needs code goes on this list first.
