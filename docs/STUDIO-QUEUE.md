# Studio run queue

Generated from `PRE_PRODUCTION.md` §5b and `TESTING.md`; input fingerprint `6dff976f087ad3e6`.
Regenerate: `python3 -I tools/studio_queue.py --write`. Check: `python3 -I tools/studio_queue.py` (also in `tools/lint.sh`).

**29 pending milestones; 102 numbered steps; each milestone appears once.** Do the place-only blocks first, then multiplayer, persistence and published-server checks. Multi-requirement milestones stay together in the strongest prerequisite block; keep each project open for adjacent entries. Empty groups mean no independent pending check.

Owner/Mac session only: stop Play before changing Rojo project, reconnect, then Play. Two-player means Test → Clients and Servers; friendship/cap checks may need additional real friends. Real saves require Studio API access and the coordinator-approved test save setup (`Config.UseDataStoreInStudio`); do not change production data for this sheet. Published checks use the published universe and actual accounts; Dev-only commands are setup in Studio, not promises of live availability.

Run the selected original step numbers below. Commands are extracted from the milestone as setup references, not a sequence to execute blindly. Known stale source wording (zero place IDs, memory-profile persistence, retired passes and old toasts) is reproduced as evidence, never treated as authority over code. Return the observed behavior for coordinator correction.

For every entry send: commit/build, project and WorldId, player count, original step number, pass/fail, exact first Output error, and a screenshot or short clip for UI failures. Include balances/counts before and after for rewards; record device/viewport for layout checks. No secrets.

## World 1 place

### Milestone 15c: the launch

**Pending status:** pass (15b, 15c on World 2; 15c step 4 waits on a World 1 Connect)

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/complete`, `/world 2`, `/world N`.

**Send back:** standard evidence above; original steps 4.

**TESTING step 4.** The profile moved: the Aliens and Ship screens now show World 2's modules (Heat Shield first, 0%), and Launch on World 1 now refuses with "Your ship is on another world" (the ship stays). Analytics prints `event Launch from=1 to=2`.

### Milestone 18: Outposts and the Star Chart (World 2 place, then World 1)

**Pending status:** pass on World 2; step 5 waits on the World 1 place

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/complete`, `/outpost`, `/outpost 1 1`, `/outpost 1 2`, `/outpost 1 30`, `/scrap 0`, `/scrap 2000`, `/world`, `/world 2`.

**Send back:** standard evidence above; original steps 5.

**TESTING step 5.** Launch from World 1 (`/complete`, walk to the ship, Launch) still works and still goes to World 2, creating no second outpost for World 1 (the existing one and its level are kept).

### Milestone 25: size rolls (World 1 place)

**Pending status:** pass (steps 1 to 3); the 50-spawn mix and eggs not sampled

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/spawn <id> [band]`, `/spawn Mossbop huge`.

**Send back:** standard evidence above; original steps 1, 4.

**TESTING step 1.** Wild spawns carry a Size attribute (Tiny, Small, Normal, Big, Huge) and the rendered alien is scaled by the band (Huge reads clearly larger than its neighbours; Tiny clearly smaller); nameplates and tap targets follow the scale. Over about 50 spawns the mix is roughly 3 / 17 / 60 / 17 / 3 percent. `/spawn Mossbop huge` forces a band for testing (Dev: `/spawn <id> [band]`).

**TESTING step 4.** Eggs and shop aliens (Peddler, gifts, Starter Pack) roll a size too, with the same odds, and the reveal stamps them the same way.

### Milestone 30: the compass strip (World 1 place, then World 2)

**Pending status:** pass (strip, stacking, camp marker, label order); the World 2 landmark diamonds pass; the shrine and target markers need a hand check; the shower toast overlapped the Friend chip, fixed World 2 pass (camp and shrine diamonds at their distances; the line keeps its fixed priority, so the Peddler names it over a nearer shrine while it visits, by design).

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/shower`.

**Send back:** standard evidence above; original steps 2, 3.

**TESTING step 2.** Walk away from the camp: past 30 studs a green diamond for the camp appears at its bearing and the line reads "Camp 42m" (the number falling as you walk back); within 30 studs it hides. The gold Shrine diamond shows from 20 studs out with "Shrine 155m" when it is the nearest or highest-priority marker.

**TESTING step 3.** Tutorial running: the gold waypoint diamond points at the marker's target and the line uses the waypoint's own label ("Wreck Plate 18m"); it beats the camp. Tap a radar blip (Radar Mk1): a sky-blue Target diamond appears and the line reads "Target 61m" until you reach it.

### Milestone 31: the icon pack (World 1 place; before and after the image upload)

**Pending status:** step 1 pass (fallbacks unchanged); the image upload is part of the last visual pass

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/weather Rain`, `/weather Snow`.

**Send back:** standard evidence above; original steps 2, 3, 4, 5.

**TESTING step 2.** `python3 tools/upload_assets.py --images --dry-run` lists 51 PNGs; `--images` uploads them (Decals), writes `assets/icons/asset_ids.json`; `--images --emit-icons-luau` prints the two tables, which replace the ones in `src/shared/data/Icons.luau`; analyze clean; commit both files.

**TESTING step 3.** With the ids in: the six menu buttons show the price tag, alien face, book, rocket, scroll and gift box icons at 70% of the face, the Settings gear and the Ranks podium on the top buttons, the gear-cog coin in the Scrap pill, the meteor on the shower banner's left square; every button still presses, hovers and opens its panel; the letters are gone.

**TESTING step 4.** `/weather Rain` then `/weather Snow` (World 2 for Snow and Blizzard): drops are soft vertical streaks, flakes six-point flakes, fog wisps soft blobs; the counts and speeds are unchanged (the data numbers did not move).

**TESTING step 5.** iPhone SE emulator: the icons stay crisp and centred on the buttons; nothing clips.

### Milestone 32: icons on the remaining surfaces (World 1 place, after the image upload)

**Pending status:** built; Studio check after the image upload

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** none; follow the prerequisites in the step.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6.

**TESTING step 1.** Power-ups row: each square shows its power-up icon (bolt, target, pulse, clover, magnet, clock) instead of a letter; the count badge and the timer ring still work.

**TESTING step 2.** Shop, Lures and Gear pages: each row has its item's icon at the left (the three lures, the boots, the hoverboard, the radars); the Robux rows have none and look as before.

**TESTING step 3.** Gifts: the tiles carry a small reward icon top-right (coin, lure, power-up, the Epic badge on Day 7); claiming re-renders without stacking.

**TESTING step 4.** Catch a Rare: the Reveal shows the blue triangle badge left of "Rare"; a Common shows the grey circle.

**TESTING step 5.** Walk to a Wreck Plate node: its nameplate shows the plate icon left of the name; collect it: the "+1 Wreck Plate" toast carries the same icon; use a Speed Burst: the "Speed Burst on!" toast carries the bolt.

**TESTING step 6.** With every id at 0 (before the upload) none of the above shows and nothing moved: letters, plain rows, plain tiles, plain toasts. Output clean in both states.

### Milestone 33: the VFX pass (World 1 place; sprites optional)

**Pending status:** auras pass; the flash needs a human Perfect; sprites wait on the last visual pass

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/spawn Mossbop`, `/spawn Sparkfox`, `/spawn Thunderhog`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4.

**TESTING step 1.** `/spawn Sparkfox` (Rare): a blue light on it at night and a soft glow that breathes about every 1.6 s; `/spawn Thunderhog` (Epic) brighter and purple; `/spawn Mossbop` nothing. Blizzard-hidden or reserved-for-another spawns carry no glow. 50 spawns on screen stay above 50 fps on the SE emulator.

**TESTING step 2.** Catch with a Perfect: a quick white flash (0.35 s) before the Reveal; a Good hit: none. Reduced Motion on: no flash, no rays, confetti as before.

**TESTING step 3.** With the sprite ids in: the catch burst is sparkles and one expanding ring in the tier colour, the module burst stars and glow, the shower streaks real streaks, the dust soft wisps; the Reveal shows slow sunburst rays behind the card in the tier colour and confetti pieces are the sprite.

**TESTING step 4.** Output clean; no sprite part is visible as geometry.

### Milestone 45: paid spins and two more passes (World 1 place)

**Pending status:** built; Studio check queued; the product ids wait on the owner guide's Part C

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/buy <itemId>`, `/buy Spins5`, `/pass <itemId>`, `/pass CompanionSlot4`, `/pass SlotEveryStation2`.

**Send back:** standard evidence above; original steps 1, 2, 3.

**TESTING step 1.** Shop, Robux tab: the Passes section shows six tiles, including +100 Alien Storage (the Longer Offline pass was withdrawn), the Spins section three red tiles under Boosts. Each spin tile reads its name and "Tap for the odds" in gold where other tiles have a description (the name says what it is); a tap anywhere on the description band opens the Gifts screen on the wheel; the Buy button is its own target. At 767x435 and iPhone SE nothing is cut off. On the Gifts screen, "See every prize's odds" under the wheel opens a table over the wheel: a Prize and Chance header, one row per prize with its odds, most likely first, and a Total row reading 100%, all in navy; every row readable at iPhone SE size. The button then reads "Back to the wheel" and closes it; closing and reopening the screen shows the wheel first.

**TESTING step 2.** `/buy Spins5`: the spin balance on the wheel rises by 5; Output shows the purchase recorded. `/pass SlotEveryStation2`: every station shows two more open slots (three more with `SlotEveryStation1` as well). `/pass CompanionSlot4`: the Aliens screen allows one more follower.

**TESTING step 3.** Where paid random items are restricted, the Spins section and its heading are hidden with the Server Luck tiles. In Studio the server prints its answer when the shop first asks: `Policy for <name>: paid random items restricted = false` (Studio's own answer is usually false; the hidden case is checked by reading the code path or on a restricted test account). Output clean.

### Milestone 46: resting in the game (World 1 place)

**Pending status:** built; Studio check queued

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/afk`, `/afk off`, `/afk rejoin`, `/spins 5`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6.

**TESTING step 1.** With at least one seated alien, stand still for 2 minutes (or `/afk`): the world dims behind a card reading "Resting", "Your crew keeps working at half speed while you rest. Leave the game on as long as you like.", "Resting for 0:12" counting up, and "Earned while resting: N Scrap" rising; the HUD's Scrap per minute halves. Output: `Afk: <name> is resting`.

**TESTING step 2.** Move, tap "Back to play" (mouse click or touch), or press any key or click anywhere: the screen goes and the server wakes at once (fixed 2026-10-07: the screen used to hide on mouse-down before the button could fire, leaving the server resting), the toast "Welcome back! Your crew earned N Scrap while you rested" shows, the per-minute rate returns to full. Output: `analytics: event Rest value=<seconds> earned=<N>`.

**TESTING step 3.** Standing still but using menus (open Aliens, tap a card, open the Shop, scroll a list) for 3 minutes never rests: the client reports presses and scrolls the server cannot see (`AfkWake`, at most every `Afk.ActivityPingSeconds`, 20 s), so using the game counts as playing (fixed 2026-10-07: menus used to count as idle). Standing still with no input still rests after 2 minutes.

**TESTING step 4.** `/afk rejoin`: Output `Afk: would rejoin <name> to this server (Studio skips teleports)`; on the screen the line "Keeping your spot..." shows. In a published game, after 17 minutes without input the player rejoins the same server and rests again two minutes later.

**TESTING step 5.** The Shop's Passes section has six tiles, including +100 Alien Storage (no Longer Offline Shift); a rejoin after 3 hours away still pays at most an hour of half-rate income. Output clean.

**TESTING step 6.** The HUD's Scrap per minute now shows what is paid: use a Double Shift (`/spins 5` and spin until one lands, or a code) and the line doubles at once and returns when it ends; a Roblox friend joining the server raises it by the Friend Boost (multi-client); resting halves it. Before this milestone the line never moved for any of the three.

### Milestone 47: cinematic arrivals and the Legendary push-in (World 1 place)

**Pending status:** built; anchors to place in each place by hand (Map-Dressing); Studio check queued

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/cinematic <momentId>`, `/cinematic Arrival_1`, `/cinematic Legendary`, `/cinematic list`, `/cinematic reset`, `/spawn Gaiabloom`, `/spawn Mossbop`, `/tutorial 8`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6, 7, 8, 9.

**TESTING step 1.** The arrival. Press Play, wait for the crash landing to finish, then `/cinematic Arrival_1`. The HUD hides and black bars slide in at the top and bottom (a tenth of the screen each, in about 0.4 seconds). The camera starts far out over the Forest and rests for under a second, then dives and flies low and fast toward the camp with the foreground blurred and the field of view widening; as it slows and rises the blur clears; it cranes up over the camp, then pulls up and out to an establishing view where the whole 400-stud floor reads as one island with the camp in the middle; then it descends to the seat behind your character, the bars slide out and the HUD comes back, with the camera already where the normal one takes over. About 15 seconds in all; Output has no red lines and no Cinematics warning (a warning names the shot whose view could not be computed).

**TESTING step 2.** Skip. `/cinematic Arrival_1` again and watch for the Skip button: it is not there for the first second, then a blue chunky button "Skip" pops in at the lower right just above the bottom bar (about 130 x 45 px at iPhone SE size, never under the bar). Tap it: the camera cuts to the seat behind the character at once, the bars slide out, the HUD returns, and the button is gone. No blur is left on the screen (Explorer shows no CinematicDepthOfField under the Camera).

**TESTING step 3.** Reduced motion. Turn on Reduced motion in Settings and `/cinematic Arrival_1`: no flight and no bars; the camera cuts straight to the seat behind the character, holds about 0.6 seconds with the HUD hidden, and hands back. No blur. `/cinematic Legendary` does nothing at all. Turn the setting off again.

**TESTING step 4.** A Legendary catch. `/tutorial 8`, then `/spawn Gaiabloom` and press Catch (or Space): no bars and no blur; the camera pushes in slowly toward the alien for 1.2 seconds, ending a few studs from it and looking at it; the screen then rumbles on that view for another 1.2 seconds (Output `Music: CatchIntense` at the tap, the low rumble sound slot is silent until its id lands) and only then does the catch bar open, with the sweep starting from the left edge. The wait from the tap to the bar is about 2.4 seconds plus the server's answer. After the rumble the normal camera takes over behind your character. Finish the catch normally. With Reduced motion on, neither the push-in nor the shake plays and the bar opens at once. A Common alien (`/spawn Mossbop`) shows no push-in.

**TESTING step 5.** A catch cancels a cinematic. `/spawn Mossbop`, walk to within catch range of it, then `/cinematic Arrival_1` and press Space while the camera is flying (the HUD is hidden, so the key is the way): the cinematic stops at once, the bars slide out, the HUD returns and the catch bar opens as usual. Output clean.

**TESTING step 6.** First arrival on World 2 (sync `world2.project.json`, press Play): a brand-new profile on this place plays the Frostbyte arrival (`Arrival_2`: opens over the Geyser Field) once, with no crash landing; the HUD returns at the end. `/cinematic list` prints `watched Arrival_2`. With real saves, stop and press Play again: the arrival does not play; `/cinematic reset` then Stop and Play: it plays again.

**TESTING step 7.** First arrival on World 1. With real saves, a brand-new profile in the World 1 place sees the crash landing (not the arrival); after it ends `/cinematic list` prints `watched Arrival_1`, and a second Play shows neither. In the home place (`home.project.json`) a brand-new profile plays the short `Arrival_0` (8 seconds, no crash landing).

**TESTING step 8.** Anchors. Place a Part named `Arrival_1_Pull` in `Workspace.Dressing.CameraRig` as Map-Dressing describes (Anchored, Transparency 1, CanCollide off, facing the view you want) high over one corner of the floor, then `/cinematic Arrival_1`: the pull-out segment ends at that Part's view instead of the computed one. Delete it and the computed view returns. The Part stays invisible and cannot be walked into.

**TESTING step 9.** Check the bars, the Skip button and the Legendary push-in at iPhone SE (667x375) and iPad sizes in the device emulator, and in portrait on the phone emulator: the bars span the width, the Skip button stays inside the screen and clear of the bottom bar, and the establishing view still shows most of the island (in portrait the narrow field of view cuts its sides: place anchors that frame for portrait if that matters).

### Milestone 49: playtime gifts (World 1 place)

**Pending status:** built; Studio check queued

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/afk`, `/afk off`, `/playtime -5`, `/playtime 10`, `/playtime 12`, `/playtime 5`, `/playtime 60`, `/playtime <minutes>`, `/playtime reset`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6, 7.

**TESTING step 1.** Press Play. Output `Playtime: on; gifts at 5, 10, 20, 30, 45, 60 min, 5s ticks, day resets at 00:00 UTC`. The HUD gains a round green button with a ">" left of the Ranks button, with no badge. Tap it: the "Playtime gifts" panel opens with six cards in one row, the chips reading "5 min", "10 min", "20 min", "30 min", "45 min" and "60 min", the rewards "150 Scrap", "1 x Twig Lure", "1 x Speed Burst", "1 free spin", "1 x Lucky Charm" and "Rare Egg" (the egg card keeps the Rare blue edge), each card holding a dark pill with its time left as m:ss that counts down once a second (the first starts a few seconds under 5:00), and the line "Play to unlock more. Resets each day." under the row. The X and a tap on the dim close it. At iPhone SE (667x375) and iPad sizes in the device emulator nothing is cut off and no name runs past two lines.

**TESTING step 2.** `/playtime 5`: Output `dev: <name> has played 300 s today (0 claimed)` (a few seconds more if you have already played some). Within a moment the badge shows 1 on the button and, with the panel open, the first card turns white with a green "Claim" button while the rest keep counting. Tap it: the click, the toast "Playtime gift: 150 Scrap", Scrap +150, the card reads "Claimed" on a grey card and the badge goes. Output `analytics: event PlaytimeGift value=1` and `analytics: economy Source Scrap amount=150 ... type=TimedReward sku=Playtime`.

**TESTING step 3.** `/playtime 60`: the badge reads 5 and cards 2 to 6 show "Claim". Claim 2: toast "Playtime gift: 1 x Twig Lure" and the lure count rises by one. Claim 3: "Playtime gift: 1 x Speed Burst" and the power-up bar holds a Speed Burst. Claim 4: the toast, and the Gifts screen's "Banked spins" rises by 1. Claim 5: a Lucky Charm joins the power-up bar. Claim 6 (the Rare egg): no toast, the panel closes and the Reveal shows a Rare alien of this world with its Scrap, the alien joins the camp and the badge clears. Reopen the panel: all six read "Claimed". Output six `analytics: event PlaytimeGift value=N` lines (1 to 6) and the egg's `event Catch` with the tier and species.

**TESTING step 4.** Rejoin keeps progress (needs real saves: keep the current `Config.UseDataStoreInStudio = true`, enable Studio API access and confirm `memoryOnly=false`; memory-only profiles are dropped when the player leaves): `/playtime 12`, claim the first gift, stop Play and press Play again. The panel shows the first card "Claimed", the second with its "Claim" button, the third counting down from about 8:00, and the badge reads 1. Leaving and coming back the same day loses nothing and adds nothing for the time away.

**TESTING step 5.** Resting does not count: `/playtime reset`, then `/afk` (the Resting screen), wait 30 seconds, `/afk off`, open the panel. The first card has about the time it had before `/afk` (at most a few seconds less than 5:00), not 30 seconds less; walking around afterwards lowers it by one second per second. Opening the panel while still resting wakes the player (every server call counts as use), so wake first.

**TESTING step 6.** `/playtime reset`: Output `dev: <name>'s playtime today cleared`; every card goes back to its countdown from 5:00 and the badge goes, and gifts claimed earlier can be claimed again. `/playtime -5` after a `/playtime 10` takes five minutes back.

**TESTING step 7.** Set `Enabled = false` in `src/shared/data/Playtime.luau` and press Play: Output `Playtime: off (Shared/data/Playtime Enabled = false)`, the HUD button is gone and the buttons beside it close the gap, and `/playtime 5` prints but shows no badge. Set it back to `true`.

### Milestone 50: alien storage cap (World 1 place)

**Pending status:** built; Studio check queued

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/pass StorageBoost`, `/spawn <speciesId>`, `/storage bay 10`, `/storage cap`, `/storage fill`, `/storage fill 1`, `/storage fill 5`, `/storage fill 53`, `/storage fill [N]`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6, 7, 8.

**TESTING step 1.** Press Play. Open Aliens: the count reads "Aliens: 0 / 60" in white (a few more if you have caught some), and a blue Release button sits at the top left, level with the red X. `/storage cap`: Output `dev: <name> storage 0 / 60 (ok)`.

**TESTING step 2.** The count colours: `/storage fill 53` (or fewer if you hold some: the total should reach 53) and reopen Aliens: white. `/storage fill 1`: the total is 54 (90% of the cap of 60) and the count turns gold; Output ends `(warning)`. `/storage fill`: the total is 60, the count is red and Output ends `(full)`. A further `/storage fill 5` adds nothing (Output `filled with 0 Common record(s)`). For the long grid, `/storage bay 10` and `/pass StorageBoost` raise the cap (milestone 50b) and a second `/storage fill` adds more; the grid scrolls through hundreds of cards without a hitch.

**TESTING step 3.** A catch at the cap: `/spawn <speciesId>` a species you have not caught (or catch any wild alien), then catch it. The Reveal shows its usual card and, above it, a red ribbon "Storage full: turned into 5 Scrap" (12 for an Uncommon, and so on). The "+N Scrap" under the card is the catch pay plus the first-catch payout plus that value, and the Scrap pill rises by the same N. Close the Reveal: a red toast "Release or fuse aliens to keep new catches". Open Aliens: the count still reads "Aliens: 60 / 60" and no card was added. Open the Codex: the species is now caught. Output: `analytics: economy Source Scrap amount=5 ... sku=Overflow` after the Catch and Codex lines. The daily quest and Field Notes counts moved as for any catch.

**TESTING step 4.** Releasing an alien that is in use is refused with its reason. With a seated alien, hold its card for half a second: a panel opens with its name, "Common, Lv 1" in the tier colour, a grey Release button "Release +5 Scrap" that takes no action, and the red line "Working at a station. Only resting aliens can be released." Close it (the X, a tap outside the card, or the Aliens X). Make a resting alien follow (tap its card) and hold it: the line reads "Following you. Stop it following first." (At the home place a displayed alien reads "On display at home. Bring it back first.") A quick tap on a card still follows or unfollows as before and never opens the panel; dragging a finger over the grid scrolls it without opening the panel.

**TESTING step 5.** Releasing a free alien frees a slot. Hold a resting Common: the panel shows a gold button "Release +5 Scrap". Tap it once: the button turns red and reads "Tap again to release"; wait 3 seconds and it goes back to gold. Tap it twice within 3 seconds: a gold toast "Released Mossbop: +5 Scrap" (the species you held), the panel closes, the card is gone, the count reads "Aliens: 59 / 60" in gold and the Scrap pill is up by 5. Output: `analytics: economy Source Scrap amount=5 ... sku=Release`. Catch another alien: it is stored (the count returns to 60) and the Reveal has no ribbon.

**TESTING step 6.** Bulk release: tap the blue Release button. The card "Release aliens" lists "Release all unused Commons" with a line "N aliens, +5N Scrap" and "Release all unused Uncommons" with its own line ("None to release" and a grey button when there are none), and a grey hint "Hold an alien card to release just that one". N counts only resting aliens: seated and following Commons are not in it. Tap the Commons button: "Release N Common aliens for +5N Scrap?" with Cancel and a red Release. Cancel returns to the menu. Release: a gold toast "Released N aliens: +5N Scrap", the card closes, the seated and following Commons are still in the grid, the count falls by N and the Scrap rises by 5N. Output: one `economy Source Scrap amount=5N ... sku=Release`. Reopen the menu: the Commons line reads "None to release".

**TESTING step 7.** Fusion still frees slots at the cap: with the store full of Commons (step 2), tap Fuse. Toasts "<species> fused to Lv 2!" appear, four records leave for each fusion, the count falls and the next catch is stored again. (Fuse asks the server once per fusion, so a full store takes a while; release some Commons first if it feels slow.)

**TESTING step 8.** Check the Aliens screen, the Release card, the confirm view and the Reveal ribbon at iPhone SE (667x375) and iPad sizes in the device emulator: the button, the three lines and both buttons of the card stay inside it, no text is cut off, and the ribbon clears the card and the top of the screen.

### Milestone 50b: storage that grows (World 1 place)

**Pending status:** built; Studio check queued

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/complete`, `/pass StorageBoost`, `/pass StorageBoost [off]`, `/pass StorageBoost off`, `/scrap 200000`, `/scrap 2000000`, `/scrap 300`, `/scrap 5000`, `/storage bay 0`, `/storage bay 10`, `/storage bay 3`, `/storage bay 5`, `/storage bay 9`, `/storage bay <level>`, `/storage cap`, `/storage fill`, `/world 2`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6, 7, 8.

**TESTING step 1.** A fresh profile starts small. Press Play (Studio profiles start fresh). Open Aliens: under the header the band reads "Aliens: N / 60" in white (N is what you have caught so far), "Companions 0/3" under it, and at its right a green button "+20 storage: 2,500 Scrap" (grey while the Scrap pill is under 2,500; the station cards above are a little shorter than before). `/storage cap`: Output `dev: <name> storage N / 60 (ok)` and `storage cap parts: base 60 + modules 0 + bay 0 (level 0 of 10) + pass 0 = 60, hard cap 1500`.

**TESTING step 2.** A finished module raises it. Finish the Hull Frame the normal way (`/scrap 300` and its 3 Wreck Plates, then the 60 seconds): after the green "Hull Frame complete!" toast comes a gold toast "+10 alien storage", and the Aliens count reads "N / 70". `/storage cap` shows `modules 10`. Then `/complete` (the other four World 1 modules): the module fanfare and a gold toast "+110 alien storage", the count reads "N / 180", Output `modules 120`. Reopening Aliens keeps both numbers.

**TESTING step 3.** The Storage Bay is bought with Scrap. `/scrap 5000`: the button is green. Tap it: the click, a green toast "Storage Bay upgraded: +20 alien storage", the Scrap pill falls by exactly 2,500, the count reads "N / 200" (180 + 20), the button now reads "+20 storage: 7,500 Scrap" and, with under 7,500 Scrap left, is grey. Tap the grey button: a grey toast "Not enough Scrap for the Storage Bay" and nothing is spent. Output: `analytics: economy Sink Scrap amount=2500 ... sku=StorageBay`. `/storage cap` shows `bay 20 (level 1 of 10)`.

**TESTING step 4.** The Bay waits for World 2 at level 6. `/storage bay 5`: the count reads "N / 280", the button is grey and reads "+20 storage: reach World 2"; tap it: a grey toast "The next Storage Bay level needs World 2", nothing is spent. `/world 2` (only the profile moves; this place stays World 1), `/scrap 200000`: the button turns green "+20 storage: 160,000 Scrap"; tap it: the count reads "N / 300". `/storage bay 10`: the count reads "N / 380" (60 + 120 modules + 200 bay), the button is grey and reads "Storage Bay maxed out"; tap it: a grey toast "The Storage Bay is fully upgraded". `/storage bay 0` takes the levels away again.

**TESTING step 5.** The pass adds space. `/pass StorageBoost`: the count rises by 100 at once with the Aliens screen open (no toast), `/storage cap` shows `pass 100`. `/pass StorageBoost off`: it falls by 100. Open Shop, Robux page, Passes: a tile "+100 Alien Storage" with "Room for 100 more aliens in your storage, forever. It stacks with the Storage Bay." at 149 Robux sits after "+1 Companion"; its Buy refuses safely (the pass has no id yet, Output `PromptPurchase StorageBoost refused: NotLive`).

**TESTING step 6.** Fullness follows the cap. `/storage fill` fills to the current cap (the colours of milestone 50 now sit at 90% and 100% of it); raise the cap with `/storage bay 3` and the red count falls back to white or gold and a catch is stored again; lower it with `/storage bay 0` while full and the next catch turns into Scrap (the red "Storage full: turned into N Scrap" ribbon) without deleting anything you hold: the count may read over the cap (for example "70 / 60") until you release or fuse.

**TESTING step 7.** The hard cap holds. In Studio set `HardCap = 150` in `src/shared/data/Storage.luau` (Rojo syncs it; put 1,500 back afterwards), then `/complete`, `/storage bay 10` and `/pass StorageBoost`: the count reads "N / 150" (not 380 or 480) and `/storage cap` prints `= 480, hard cap 150`; `/storage fill` stops at 150. The headless spec "CapFor never passes the hard cap" checks the same with the real data.

**TESTING step 8.** Check the Aliens screen at iPhone SE (667x375) and iPad sizes in the device emulator: the count, the companion line and the Storage Bay button stay inside the panel and clear of the station cards above and the perks line below; the button's text is one line for every level (check "+20 storage: 1,000,000 Scrap" with `/storage bay 9` and `/scrap 2000000`) and at the grey states; the count line "Aliens: 1,234 / 1,500" (`/storage fill` with a raised cap) is not cut off; the Release button, the X and the header tab are where they were.

### Milestone 51a: music and sound system (World 1 place)

**Pending status:** built; tracks wait on the Mac's audition; Studio check queued

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/afk`, `/afk off`, `/complete`, `/day`, `/night`, `/rush`, `/rush end`, `/season HauntedNebula`, `/season off`, `/shower`, `/shower end`, `/spawn`, `/spawn Gaiabloom`, `/spawn Mossbop`, `/tutorial 8`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5, 6, 7, 8, 9, 10.

**TESTING step 1.** Day and night. Press Play. The client Output shows one `[AlienGame] Music: VerdantDay` (`VerdantNight` if the clock starts at night) after the profile line, not two. `/night` prints `Music: VerdantNight` and `/day` prints `Music: VerdantDay`, once per flip, not once per clock push. Open Settings: a "Music" row sits between "World sounds" and "Button and catch sounds" with Off, Low, Mid and High, High lit for a fresh profile, and every row stays inside the card at iPhone SE and iPad sizes.

**TESTING step 2.** A plain catch. `/spawn Mossbop`, walk within 12 studs and press Catch: Output `Music: CatchBase` at the tap, no screen shake, the bar opens as before. On a catch, `Music: VerdantDay` prints when the Reveal is about to open and `Music: stinger Reveal.Common (silent)` as it opens; on a flee, `Music: VerdantDay` prints when the bar closes. Spawn and catch a Rare (`/spawn` any Rare): the stinger line reads `Reveal.Rare`, and so on for each tier.

**TESTING step 3.** A Legendary catch. `/spawn Gaiabloom` and press Catch: Output `Music: CatchIntense` at the tap, the screen shakes for about 1.2 seconds (strongest at the start, easing to still) and only then does the catch bar open, with the ticker leaving the left edge as on any other catch (the request waits for the rumble, so the first sweep is untouched). On a phone or controller that supports vibration the Small motor buzzes for about 0.8 seconds with the shake; the buzz is checked on a real device (Studio's emulator does not vibrate). After the catch, `Music: VerdantDay` and `Music: stinger Reveal.Legendary (silent)`. A Cosmic or Secret catch opens the same way.

**TESTING step 4.** Reduced motion. Turn on Reduced motion in Settings and catch another Gaiabloom: `Music: CatchIntense` still prints, but there is no shake, no buzz and no wait before the bar opens. Turn it off again.

**TESTING step 5.** Events. `/shower`: Output `Music: MeteorShower`; a plain catch during it prints no `CatchBase` line (the Shower keeps the music), a Legendary catch prints `CatchIntense` and then `MeteorShower` again; `/shower end` returns the world bed. `/rush` prints `Music: CatchRush` and `/rush end` returns the world bed; with a Shower and a Rush both running, the Shower line wins. `/season HauntedNebula` prints `Music: HauntedNebula` on World 1 (the season's worlds) and `/season off` returns it.

**TESTING step 6.** Resting. `/afk`: Output `Music: Resting`; `/afk off`: the world bed returns. A running Shower still beats resting.

**TESTING step 7.** Panels. Opening and closing a panel (Aliens, Codex, Settings) prints no Music line: a menu is a layer over the bed, not a state. With ids filled (step 10) the bed drops to about two thirds while a panel is open and eases back after it closes.

**TESTING step 8.** The home place (`home.project.json` synced): Output `Music: Home`, and `/night` prints no new line, because Home is one track day and night. Visiting a friend's home also plays Home.

**TESTING step 9.** Launch. Complete the ship (`/complete`), press Launch: Output `Music: Launch` and `Music: stinger Launch (silent)` at the lift-off; Studio skips teleports even with the published place ID, so after the black hold the camp returns and `Music: VerdantDay` prints again. The launch cue is not ducked by its own hit.

**TESTING step 10.** When the Mac session fills ids (needs a real track): paste the plain number into a row's `assetId` in `src/shared/data/Music.luau`, press Play and check, with headphones and the device emulator's speaker, the day and night crossfade (about 3 seconds), the catch bed coming in and out within a third of a second, the intense bed on a Legendary, a Reveal stinger dipping the bed for its length and the bed returning within a second after it, and the Music setting scaling the whole mix. While the row plays, Explorer shows one Sound per voice under SoundService > Music; a row still at 0 shows none, and a silent winner leaves the next row down playing.

## World 2 place

### Milestone 24: weather particles (Look pass L3, both places)

**Pending status:** pass; rain visibility waits on real particle textures (L5)

**Setup projects:** `rojo serve world2.project.json`, `rojo serve default.project.json`.
**Dev/setup references:** `/clear`, `/shower`, `/weather Blizzard`, `/weather Fog`, `/weather Rain`, `/weather Snow`.

**Send back:** standard evidence above; original steps 1, 2, 3, 4, 5.

**TESTING step 1.** World 1, `/weather Rain`: within 1.5 s rain streaks fall around the player from a sheet above the camera, slanted slightly, and keep falling while walking (the sheet follows); `/clear` ramps them off over 1.5 s. `/weather Fog`: slow drifting pale wisps at ground level, few and large. Output clean; no sheet part is visible as geometry.

**TESTING step 2.** World 2: `/weather Snow`: large slow flakes drifting and spinning; `/weather Blizzard`: dense fast sideways flakes; `/clear` ends them. The Heater still reveals aliens as before (the sheet never blocks taps: CanQuery off).

**TESTING step 3.** The Meteor Shower sky sheet (milestone 11) still works alongside: `/shower` during Rain shows both.

**TESTING step 4.** Budget: Output prints one line per sheet with its rate x max lifetime (the on-screen count); none above 200. On the iPhone SE emulator frame rate stays above 50 under Blizzard; if not, lower the rate in data/Weather.luau, never in code.

**TESTING step 5.** Reduced Motion on: particles still run (they are weather, not motion), unchanged.

## Home place

### Milestone 42b: the house grid (home place, `home.project.json`)

**Pending status:** pass (steps 1 to 4 at 2caea87: Decorate inside 18 studs, the ghost on the tapped cell, Turn, placing and its events, Taken, Not enough Scrap, the room cap, Take away, nothing on World 1); fixed from the notes: the menu column covered the tray's left edge (the tray sits bottom right, 0.88 wide), full-cap cards stayed coloured, a Turn carried over to the next pick (re-check at c126343: rows, cap and turn pass); the touch tap-versus-drag check needs a device

**Setup projects:** `rojo serve home.project.json`.
**Dev/setup references:** `/scrap 1000`.

**Send back:** standard evidence above; original steps 5.

**TESTING step 5.** The build camera (added 2026-10-07 after D2's missing ghost: the tray swallows taps on its own area, and a plot low in the view sat behind it). Stand anywhere within reach of the plot and open the tray: the camera glides (about 0.6 s) to look down on the plot from the side it stood on, and the whole sand square shows above the tray and its title tab, at iPhone SE and iPad sizes in the device emulator and in a small multi-client window. Pick Verdant Habitat (or Cabin) and tap a free cell: the ghost appears. Done: the camera glides back behind the character and the mouse steers it again. Open the tray and start walking: the camera stays on the plot until Done. Reduced motion on: both glides take half as long.

## Two-player test

### Milestone 23: the Friend Boost (World 1 place, multi-client)

**Pending status:** step 1 pass; friends need a multi-client test

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** none; follow the prerequisites in the step.

**Send back:** standard evidence above; original steps 2, 3, 4, 5.

**TESTING step 2.** A friend joins the server: toast "<name> is here! Friend Boost +5%", the chip reads +5% and brightens, the luck line shows x1.1 (luck 1 + 0.05, rounded to one decimal; with pity it adds), station income per minute rises by 5% on the Ship screen, and a catch pays 5% more Scrap. Analytics prints FriendsInServer with value 1 for both players.

**TESTING step 3.** A third and fourth friend: +10%, +15%; a fifth friend stays at +15% (the cap of 3). A friend leaving: toast "Friend Boost +10%" and the numbers fall.

**TESTING step 4.** Non-friends joining change nothing. The friendship lookup failing (offline Studio) prints one warn and retries after 300 s, never spamming.

**TESTING step 5.** Daily quests: the "with a friend" objectives count catches while the chip is above +0% (the same friend check).

### Milestone 34: the Catch Rush (World 1 place, multi-client where noted)

**Pending status:** pass (steps 1 to 3, 5, and 6 on a fresh profile); singular toasts fixed; 4 and 7 need multi-client

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/rush`, `/rush end`, `/rush in 40`, `/shower`, `/shower end`, `/tutorial 1`.

**Send back:** standard evidence above; original steps 4, 7.

**TESTING step 4.** Multi-client (Test > Clients and Servers, 2 players): both see the same clock and chip; player A catches 2, player B 3: B's banner says #1 and A's says #2 with 300 Scrap; ties rank the earlier count first.

**TESTING step 7.** Output clean; a late joiner (second client) during a round sees the banner and the right counts at once.

## Real saves

### Milestone 19: social rewards and the notifications ask (World 1 place)

**Pending status:** pass (group step needs a group id; session-2 ask needs real saves)

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/days 7`, `/social ask`, `/social credit 100`, `/social credit 2`, `/social reset`.

**Send back:** standard evidence above; original steps 3, 6.

**TESTING step 3.** Set `Social.GroupId` to any real group id (temporarily, not committed) and rejoin: the group button reads "Join our group"; tap: the native group prompt opens (Studio may refuse; then the button stays). From the command bar, invoke `ClaimGroupReward`: NotMember when not in the group; for a member, Scrap +500, lures +3, spins +2, toast "Group gift: 500 Scrap, 3 x Twig Lure, 2 free spins", Analytics event GroupReward, the button reads "Group gift claimed" and a second claim answers AlreadyClaimed.

**TESTING step 6.** Second session: rejoin. `social.sessions` is 2, and after 120 s the NotifyAsk event fires once (the card itself depends on step 4's platform rule). No card during a capture, the reveal or a launch; the card waits and retries.

### Milestone 20: the weekly Catches leaderboard (World 1 place)

**Pending status:** pass single-client; multi-client and the shared store wait on Ethan

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/lb 3`, `/lb 50`, `/spawn`.

**Send back:** standard evidence above; original steps 3, 4.

**TESTING step 3.** Multi-client test (two players): both appear, sorted by count, ranks 1 and 2; the loser's bottom row shows rank 2. The list refreshes within 60 s of a catch without reopening.

**TESTING step 4.** With `Config.UseDataStoreInStudio = true` and API access: the key `Catches_<period id>` in the OrderedDataStore "Catches" holds the counts; rejoin and the count persists; a second Studio server sees the same board within a minute. Leaving flushes at once (no catches lost on a quick rejoin).

### Milestone 27: the five-minute script (World 1 place, fresh profile)

**Pending status:** pass (steps 2 to 5); the rejoin step waits on real saves

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/shower`, `/tutorial 8`.

**Send back:** standard evidence above; original steps 6.

**TESTING step 6.** A rejoin after the gift was claimed never re-opens the Gifts screen; the pop fires once per session at most.

### Milestone 28: growth stages (World 1 place)

**Pending status:** pass (steps 1 to 4, 6); the card chips were widened after the run; the away-time line waits on real saves

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/grow 1`, `/grow 2`, `/grow 22`.

**Send back:** standard evidence above; original steps 5.

**TESTING step 5.** Rejoin after the server has run for over a minute with aliens seated: the welcome-back toast still reports Scrap; the away-time growth and the "N of your aliens grew while you were away!" line require `memoryOnly=false` and Studio API access (the current `Config.UseDataStoreInStudio` is true); note them as untested if the session falls back to memory.

### Milestone 36: companions (World 1 place; step 5 multi-client)

**Pending status:** pass (steps 1 to 4: follower on the ground 6 studs behind, snaps after a jump and a world change, perks line fits, token and pass slots, the working-card toast, a live /follow redraw, luck +0.1 exactly); 5 needs multi-client, 6 real saves

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/follow Sparkfox`, `/pass CompanionSlot4`, `/token`, `/world`.

**Send back:** standard evidence above; original steps 5, 6.

**TESTING step 5.** Multi-client (Test > Clients and Servers): player B sees A's companions walking behind A with name plates (no tier line); when A leaves, they vanish for B; a late-joining C sees them at once. Beyond 120 studs from the camera the followers of others are not drawn; 50 wild spawns plus companions stay above 50 fps on the SE emulator.

**TESTING step 6.** Rejoin: the companions still follow (real saves in Studio with API access and `memoryOnly=false`; schema v9 adds `companionSlots`). Output clean.

### Milestone 37: mounts (World 1 place; step 5 multi-client)

**Pending status:** pass (steps 1 to 4 on 7248c54: 25.6 and 30.72 walk speed, 11.52 jump height, hips lifted by the seat, the mount centred under the rider through walking, turning, jumping and a world change, the arc closes with no gap, fusion keeps the ridden copy); Thunderhog's seat raised 0.4 for its quills; 5 needs multi-client, 6 real saves

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/dupes`, `/ride <speciesId|off>`, `/ride Gaiabloom`, `/spawn Gaiabloom`, `/spawn Thunderhog`, `/world 2`.

**Send back:** standard evidence above; original steps 5, 6.

**TESTING step 5.** Multi-client: player B sees A sitting on the mount with no name plate on the mount, and A's other followers behind; A hops off: the mount walks back into the arc for B too.

**TESTING step 6.** Rejoin: back on foot (riding is not saved; the mount still follows). Output clean.

### Milestone 42a: the home place (home.project.json; World 1 place for the unlock)

**Pending status:** pass (steps 1 to 3 at 2caea87: the Home planet and its unlock, the scene, every wild-world service off, Build not Launch, the fly back, seated aliens earning at home); fixed from the notes: no stations stood at home (the unlock world is now the highest the ship has reached), Rain never rolled there (row 0 has it), the Ship screen's empty panel says why; fixed too: the weekly chip clipped at home (no world name in it, the subtitle has it), the Rush countdown and a "Catch Rush! 0s left" banner showed there (the home answers no round now); the re-check at c126343 passed the stations, the Aliens screen's station area, Optimize and the Ship screen's line; /rain at home forces the world's special weather (Clear) so only /weather Rain works, fix queued; the week's weather holds at home by design; step 4 needs real saves; the locked Home planet's colour is a look-pass note

**Setup projects:** `rojo serve default.project.json`, `rojo serve home.project.json`.
**Dev/setup references:** `/complete`, `/night`, `/rain`, `/sighting`, `/world 0`, `/world 1`.

**Send back:** standard evidence above; original steps 2, 4.

**TESTING step 2.** Home place (`rojo serve home.project.json`, connect, Play with a profile on world 0 via `/world 0` on World 1 first, or a fresh profile with `/world 0`): the floor is small and pale blue with the camp pad, the ship and the stations; a sand-coloured plot square sits past the pad on +Z (6 by 6 cells of 4 studs); no wild aliens ever spawn, no nodes, no shrine, no Peddler landing, no sightings (`/sighting` prints that this world has none), the weekly banner names the drop's world ("Panpipe on World 1 · 6d 23h left"), the biome chip reads "Home", `/rain` and `/night` still work (lighting only). The ship's action at home reads Build, not Launch (a launch there is refused with NoNextWorld), the Ship screen's "walk to the ship and launch" hint stays off, and the HUD ship bar reads 0% (the home has no modules; a later part hides it); Fly back to World 1 works from the Star Chart.

**TESTING step 4.** A profile below schema v10 (requires an existing pre-v10 test save; new profiles start at the current version, and Studio real saves require API access): one with two unlocked worlds migrates with `home.unlocked = true`. Output clean on both places.

### Milestone 43: the Scanner Pulse (World 1 place)

**Pending status:** pass (steps 1 to 3 at c126343: the SCANNER code route, the purple breathing ring, rim blips at the exact bearing of wilds beyond the range, the biome rule across the Meadow and Forest border, tier 0 unchanged, the 60 s countdown and the ring back to blue); fixed from the notes and re-checked at 67a6832: the farthest wilds (137 to 180 studs) never re-shadowed after the pulse (a biome change re-judges, the end is judged for every wild), the Rush chip read "Rush in 0s"; a Secret gets no blip below Mk2 by design (noted in the script); rejoin mid-pulse needs real saves

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/buy`, `/radar 1`, `/spins`.

**Send back:** standard evidence above; original steps 3.

**TESTING step 3.** The buff ring under the ship bar counts the 60 s down; at the end the rim blips go, the ring returns to blue, the silhouettes return. Rejoin mid-pulse (real saves with Studio API access and `memoryOnly=false`): the timer resumes and the reveal with it. Output clean.

## Published game

### Milestone 14: the Robux launch shop

**Pending status:** pass with grants; receipts wait on live ids

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/buy <itemId>`, `/buy ScrapMagnetx3`, `/buy ServerLuck2x`, `/buy ServerLuck4x`, `/buy SpeedBurstx5`, `/buy StarterPack`, `/pass <itemId>`, `/pass <itemId> off`, `/pass AutoOptimize`, `/pass ExplorerPack`, `/pass LongerOffline`, `/pass SlotEveryStation1`, `/shower`, `/shower end`.

**Send back:** standard evidence above; original steps 7.

**TESTING step 7.** Receipts: `ProcessReceipt` cannot be driven from Studio without live ids; once ids exist, Studio's test purchases (no charge) exercise it. A repeated receipt id is answered PurchaseGranted without a second grant (profile.shop.receipts remembers 100).

### Milestone 41: the developer panel (World 1 place; step 4 multi-server needs a published game)

**Pending status:** pass (steps 1 to 3 on c3b4db9 with Ethan's id, now in the data; Studio published for real, so every command made the round trip); fixed from the notes: the gifted window's toast said "bought" (its own line now) and the luck pill's word did not fit (number only); step 4 needs a published game

**Setup projects:** `rojo serve default.project.json`.
**Dev/setup references:** `/admin`, `/admin luck`, `/admin luck 1 2`, `/admin luck [bonus] [minutes]`, `/admin say`, `/admin say <text>`, `/admin say Hello from the team`, `/admin say x`, `/admin shower`, `/admin weather <state>`, `/admin weather Rain`.

**Send back:** standard evidence above; original steps 4.

**TESTING step 4.** Published game, two servers (Ethan): `/admin say` in one server reaches the other within a few seconds; a luck window shows in both; the message is ignored by a server that receives it more than 30 s late (replay guard). Output clean.

### Milestone 42e: visiting (home place; the teleport half waits on the published home place)

**Pending status:** single-client half pass (steps 1, 2 and 5's guest flight at 67a6832: the HomeLock row, the Visit screen with the server's players and 43 Roblox friends, the refusal without a live place, "Your ship waits here" and the guest Fly); fixed from the notes: deleted accounts listed as friends, friend rows a third of the panel tall (the CanvasSize rule); steps 3, 4 and the visiting half of 5 wait on a two-player Studio test (owner guide, section 8); the trip half (reserved servers, the owner's save read without a lock, the inbox) needs the published home place and real saves

**Setup projects:** `rojo serve home.project.json`.
**Dev/setup references:** `/visit A`, `/visit off`, `/world 0`, `/world 1`, `/world 2`.

**Send back:** standard evidence above; original steps 3, 4, 5, 6.

**TESTING step 3.** Multi-client in the home place, the owner (client A) with a room, a displayed alien and a launched world (`/world 2` then `/world 0`): client B taps Visit on A. B: the screens close, "Welcome to A's home!", the biome chip reads "A's home", A's rooms stand on the plot, A's displayed alien roams its habitat, A's hull stands in the hangar, B's own items are gone from the plot; near the plot the action is no longer Decorate, at the mailbox no longer Mail, Spin at the kiosk still works; B's Aliens screen shows no Display button. A: "B came to see your home" and B's name in the Visitor Book. Output `analytics: event Visit value=1 owner=<A's id> how=here`.

**TESTING step 4.** B walks within 10 studs of A's displayed alien: the action reads "Wave"; tap: "You waved at A's Mossbop (+5 Scrap)", B's Scrap +5; A: "B waved at your Mossbop (+5 Scrap)" and +5. A second tap on the same alien: "You already waved at this one" (and still so after Fly home and Visit again the same day). The daily cap counts waves at different aliens now (an alien pays once per owner per day, and a home shows at most six): to see it without ten aliens set `WavesPerDay` to 1 in `data/Visiting.luau` for the run, wave at one displayed alien, then at another: "No more waves today. Come back tomorrow!". A sets the lock to Only me: B's Visit answers "A's home is closed to visitors"; Anyone lets B in again (Friends does when B is A's Roblox friend). Output `analytics: event Wave value=5 owner=<A's id> species=Mossbop` on B, a Wave economy source on both.

**TESTING step 5.** B's Star Chart while visiting: the Home card reads "Your ship waits here" with Fly; Fly: "Back at your own home", B's own plot and hangar return, the chip reads "Home". `/visit A` and `/visit off` do the same from the chat. In the home place, `/world 1` then the Star Chart: the World 1 card reads "Your ship waits here" with Fly (a guest may fly to the world the ship is on), and Fly answers with the "Verdant Crash Site is not published yet; your ship is logged there" toast in Studio. Output clean.

**TESTING step 6.** The teleport half (needs the published home place, its id in `data/Worlds` row 0, and real saves; not in Studio): Visit on an away friend reserves a server, keeps its code in the HomeServers map and teleports with the owner's id in the teleport data; the home server reads the owner from the join data and shows their home from their save (no lock, re-read every 60 s at most); the visit and the waves go to the HomeInbox; the owner's next load shows the Visitor Book line and the letter "N waves at your aliens while you were away" with the Scrap. The owner's own Fly home lands in that same reserved server, where the friends already there see them arrive. Output clean.
