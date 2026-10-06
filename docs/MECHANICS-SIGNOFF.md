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
- **29** Look pass L3 hero landmarks
- **35** Fusion
- **38** The weekly drop

## 2. Verified with a part still open

Each line names what is still open; most of these are the multi-client, real-save or device-emulator checks that only Ethan's Studio can run.

- **14** Robux launch shop: pass with grants; receipts wait on live ids
- **15** World 2 Frostbyte data and blockouts, one place per world, the launch: pass (15b, 15c on World 2; 15c step 4 waits on a World 1 Connect)
- **18** Outposts: pass on World 2; step 5 waits on the World 1 place
- **19** Group-join reward, referral rewards, rejoin nudges, notification opt-in card: pass (group step needs a group id; session-2 ask needs real saves)
- **20** Weekly "Catches this week" leaderboard: pass single-client; multi-client and the shared store wait on Ethan
- **23** Friend Boost: step 1 pass; friends need a multi-client test
- **24** Look pass L3 particles: pass; rain visibility waits on real particle textures (L5)
- **25** Size rolls: pass (steps 1 to 3); the 50-spawn mix and eggs not sampled
- **26** Catch variants: pass (steps 1 to 3, 5; step 4 partial: multi-round drift seen on Ra-dish, the drift-miss scoring is a code check)
- **27** The five-minute script: pass (steps 2 to 5); the rejoin step waits on real saves
- **28** Growth stages: pass (steps 1 to 4, 6); the card chips were widened after the run; the away-time line waits on real saves
- **30** The compass strip: pass (strip, stacking, camp marker, label order); the World 2 landmark diamonds pass; the shrine and target markers need a hand check; the shower toast overlapped the Friend chip, fixed World 2 pass (camp and shrine diamonds at their distances; the line keeps its fixed priority, so the Peddler names it over a nearer shrine while it visits, by design).
- **31** Look pass L5 icons: step 1 pass (fallbacks unchanged); the image upload is part of the last visual pass
- **33** The VFX pass: auras pass; the flash needs a human Perfect; sprites wait on the last visual pass
- **34** The Catch Rush: pass (steps 1 to 3, 5, and 6 on a fresh profile); singular toasts fixed; 4 and 7 need multi-client
- **36** Companions: pass (steps 1 to 4: follower on the ground 6 studs behind, snaps after a jump and a world change, perks line fits, token and pass slots, the working-card toast, a live /follow redraw, luck +0.1 exactly); 5 needs multi-client, 6 real saves
- **37** Mounts: pass (steps 1 to 4 on 7248c54: 25.6 and 30.72 walk speed, 11.52 jump height, hips lifted by the seat, the mount centred under the rider through walking, turning, jumping and a world change, the arc closes with no gap, fusion keeps the ridden copy); Thunderhog's seat raised 0.4 for its quills; 5 needs multi-client, 6 real saves

## 3. Built, Studio run queued on the Mac

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
