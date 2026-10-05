# Test scripts per milestone

Run in Studio with `rojo serve` connected. Report Output lines verbatim and a screenshot.

## Milestone 1: bootstrap and saves

Press Play. Output should show `[AlienGame] server started: ...`, the Studio in-memory-profile warning, `profile loaded for <name> (scrap=0, memoryOnly=true)`, and `client: profile loaded. scrap=0 aliens=0 world=1`.

## Milestone 2: meadow, spawns, capture bar, reveal

1. Press Play. Output shows `server started: PlayerData, WorldClock, Meadow, Spawner, Catching`, the memory-profile warning, and the client profile line.
2. You spawn on a gold square on a cream pad at the centre of a green 400x400 meadow with grey rocks and brown trees. Within a second about 14 dark silhouettes labelled "???" with a coloured tier label bob around you, none within 24 studs of the pad.
3. Walk toward one. At about 40 studs it tweens to its real colour and its name pops in. Inside 12 studs a green "Catch!" button appears bottom right and breathes.
4. Press the button, Space, or click the alien. The world dims, name and tier appear, a bar with a green zone and a gold zone shows, and after about half a second a white ticker sweeps.
5. Tap or click anywhere, or press Space, to stop it. Expect "PERFECT!" (gold) or "Good!" (green) for a catch; "Miss" (red, bar shakes) with "So close!" and a zone flash when just outside; "It wiggled free!" on a failed Good roll for Uncommon and above. Three dots count sweeps; three failures give "It got away!" and the alien vanishes, with a replacement nearby after 60 to 90 s.
6. On a catch the reveal card scales in: a coloured square with the shape name, species name, tier in its colour, a NEW! ribbon, "+50 Scrap" floating up for a Common first catch (120 Uncommon, 400 Rare, 1,500 Epic), confetti for Epic and above. Tap anywhere to close. The Scrap pill rolls up. Catching the same species again shows no NEW! and pays nothing.
7. The top-right chip reads "Day · Clear". After 3 minutes it turns blue, "Night · ...", and the sky darkens over 3 s. Buzzlebee (Day only) despawns at night; Thunderhog (Epic) appears only during Rain.
8. Check the HUD, bar and reveal at iPhone SE and iPad sizes in the device emulator.

Known gaps in this milestone: no lure bonus yet, no per-catch Scrap, no camera zoom on capture, placeholder shapes and silent sounds.

## Milestone 3: camp, Scrap income, materials, ship modules

1. Press Play. Output shows `[AlienGame] Materials: 6 nodes placed`, `[AlienGame] Economy: ticking every 1s`, `server started: PlayerData, WorldClock, Meadow, Materials, Spawner, Economy, Catching`, the memory-profile warning, and the client profile line.
2. HUD: a gold "Ship 0%" bar sits top centre between the Scrap pill and the clock chip, with four thin tick marks. No "+N/min" line under the Scrap pill yet (nothing is assigned).
3. Camp, straight ahead of the spawn: a grey landing slab with a ghost ship (five translucent parts; the hull pulses because it is the module being built). Left of the pad a gold Picnic Table, right a brown Treehouse Bench, behind a glowing purple Glow Flower, each with a nameplate. No wild aliens, rocks or trees inside about 32 studs of the pad.
4. Six grey cubes labelled "Wreck Plate" float 40 to 85 studs from the pad. Inside 8 studs the bottom-right button reads "Collect". Press it: a toast "+1 Wreck Plate" slides in top centre, the cube vanishes and returns 30 s later.
5. Catch a Mossbop (Gather) and a Puffpuff (Build). Each appears beside its station as a small bobbing copy with a nameplate; the station plate shows "+60/min"; the HUD rate line shows the total; the Scrap pill ticks up about once a second.
6. Walk to the ship. Inside 14 studs the button reads "Build". Press it, or tap the ship bar: the Ship screen opens (cream panel, "Your Ship", red close top right). Row 1 Hull Frame is active with "Pay 300", "0/3 Wreck Plate" and "Add Wreck Plate"; rows 2 to 5 are dimmed with "Finish the module above first".
7. Press Pay with under 300 Scrap: toast "Not enough Scrap". Collect three plates and press Add: "3/3 Wreck Plate". When Scrap reaches 300 press Pay: it becomes "Paid" and the status reads "Assembling, 0m 59s left" at "Crew speed x1" (x2 with a Puffpuff at the Bench). The bar fills; when it completes the ghost hull turns solid and pops, a toast "Hull Frame complete!" shows, and the ship bar reads "Ship 10%".
8. Row 2 Thrusters becomes active. Its Add button is grey; pressing it toasts "Find Glowroot in the Forest" (the Forest arrives with the biomes milestone).
9. The Optimize button re-sorts the camp; with two aliens nothing visible changes.
10. Offline accrual needs real saves: set `Config.UseDataStoreInStudio = true` with Studio API access on, leave, rejoin after more than 60 s, and expect a "Welcome back!" toast naming the Scrap gained and any module that finished (the client claims the summary after it boots, so a slow load never loses it).
11. Check the ship bar, Ship screen and toasts at iPhone SE and iPad sizes.

Known gaps in this milestone: Forest and Cave biomes and their materials, launch, lures, per-catch Scrap, placeholder art, silent sounds.

## Milestone 4: Forest and Cave, condition-gated materials, biome chip

1. Press Play. Output shows `[AlienGame] Materials: 16 nodes placed` (6 Wreck Plate, 4 Glowroot, 3 Cave Crystal, 3 Storm Shard) and the same service list as milestone 3. A blue chip under the clock chip reads "Meadow".
2. Walk towards the far corner ahead-right (about 130 studs out, +X +Z): a darker green patch with dense trees. The chip flips to "Forest" at the patch edge. Wild aliens here are Glimmo, Twiglet, Zapfinch (and Lanternewt at night); none of the Meadow species. Four green cylinders labelled "Glowroot" float inside; Collect works on them.
3. Walk to the opposite corner (-X -Z): a grey patch under a flat roof with pillars around the rim. The chip reads "Cave". Wild aliens: Pebblet, Snailbyte, Rocklobber (Gloomoth at night). Three blue balls labelled "Cave Crystal" are dim by day with "Only at night" under the name and no Collect button; at night they turn solid and collect normally.
4. Back in the Meadow, three yellow cubes labelled "Storm Shard" are dim with "Only at rain" until the weather chip reads Rain, then they collect.
5. With Hull Frame done, the Ship screen's row 2 (Thrusters) accepts Glowroot: collect 3, press "Add Glowroot", pay 1,500, and the module assembles. Row 3 (Life Pod) then asks for Cave Crystal.
6. Wild aliens never spawn inside the camp clearance or on top of each other; a conditional spawn (Buzzlebee, Thunderhog, Lanternewt, Gloomoth) despawns when its condition ends.
7. Check the biome chip does not collide with the clock chip or toasts at iPhone SE and iPad sizes.

Known gaps in this milestone: the Warden's Core (quest) is not obtainable, so the Engine Core cannot be built yet; no lures, Peddler or tutorial; placeholder art.

## Milestone 5: menu stack, Aliens screen, Codex screen, Nearby panel

1. Press Play. Down the left edge sit four square buttons with labels: Shop (green, "$"), Aliens (gold, "A"), Codex (purple, "?"), Ship (blue, "^"). Shop shows a "Coming soon" toast. The other three open their panels; tapping another menu button while a panel is open switches panels in one tap (the menu sits above the dim); while any panel is open the Catch!/Collect/Build button is hidden and Space does not start a catch. (Automation note: open panels by clicking the buttons with the MCP mouse; `require`-ing Screens from execute_luau gets a separate module instance and does nothing.)
2. Aliens: with nothing caught the panel reads "Catch an alien and it will work here" under three station cards (Picnic Table 0/1, Treehouse Bench 0/1, Glow Flower 0/1, each with one open slot and two locked squares). Catch two aliens: cards appear sorted by speed with a rarity-coloured frame, speed chip "x1" or "x1.6", and "gathering at the Picnic Table" or "Resting". The station card fills and shows "+60/min". Optimize re-sorts.
3. Codex: "Verdant Crash Site: 2/15" with a purple bar; a grid of 15 cells, caught ones in colour, uncaught as dark silhouettes with "?" (Panpipe reads "???"). Tap a cell: the right card shows a rotating 3D placeholder, name, tier in its colour, "Jobs: Gather L1", and either "Found: Meadow, any time" with the caught count or "Appears in the Meadow in the rain" with "First catch pays 1,500 Scrap" for an uncaught Thunderhog.
4. Nearby: a dark column under the biome chip lists what can appear here now: in the Meadow by day Mossbop, Puffpuff, Sparkfox and Buzzlebee; at night Buzzlebee drops out; in Rain Thunderhog joins. Walk into the Forest and the list becomes Glimmo, Twiglet, Zapfinch (Lanternewt at night). Caught species show in colour, uncaught as silhouettes.
5. Check all three panels and the Nearby column at iPhone SE and iPad sizes; nothing overlaps the top row or the action button.

Known gaps in this milestone: Shop, Quests and Settings are not built; no compass direction from the Nearby panel yet; placeholder icons (first letters) until the icon pack is chosen.

## Milestone 6a: catch Scrap, lures, the Scrap shop, Speed Boots

1. Press Play. Output adds a Shop line to the boot and `server started: PlayerData, WorldClock, Meadow, Materials, Spawner, Economy, Shop, Catching`.
2. Catch a Common: the reveal shows "+60 Scrap" (10 catch Scrap plus the 50 first-catch bonus); catch it again: "+10 Scrap". A Perfect hit shows "x2 Scrap!" under the Scrap line and pays double the catch part.
3. Shop button opens the Shop panel (green header). Lures tab: Twig Lure 150 Scrap "+4% catch zones", Glow Lure 900, Star Lure 4,000, each with "Held: 0" and a Craft button (grey when you cannot afford it; tapping it then toasts "Not enough Scrap"). Craft a Twig Lure: toast "Twig Lure crafted", Scrap drops, Held: 1.
4. Start a catch: a blue chip above the bar reads "Twig Lure used", the green zone is visibly wider, and the shop shows Held: 0 afterwards (the lure is spent on the attempt, caught or not).
5. Gear tab: Speed Boots 800 "+25% walk speed, forever", Hoverboard 5,000 "+60%", Glider Pack grey (locked). Buy Speed Boots: toast "Speed Boots bought", the button becomes "Owned", and you walk faster at once and after a reset.
6. Robux tab reads "Robux items come with the launch shop".
7. Economy check: with two Commons working and catching steadily, Scrap climbs noticeably faster than in milestone 3.
8. Catch a Rare (Sparkfox) or better: a wide banner in the tier colour slides in top centre for 4 s reading "<you> caught a Rare Sparkfox!" (with the overlay named when it has one). Commons and Uncommons post no banner. In a multi-client test the banner shows on every client.

9. Studio-only chat commands exist for testing (the Dev service prints a line at boot and does nothing in a live server): type `/scrap 5000` in the chat to add Scrap, `/night`, `/day`, `/rain`, `/clear` to force the clock. Use them to buy Speed Boots and to test the Cave Crystal and Storm Shard nodes without waiting.
10. Finish the Thrusters (module 2): toasts "Thrusters complete!" and "Every station now has 2 slots!"; the Aliens screen's station cards read 0/2 or 1/2 and a second slot square opens. The Nav Array raises them to 3.

Known gaps in this milestone: Peddler, power-ups, luck, Hoverboard tricks and skins, Radar Mk1.

## Milestone 6b: the Peddler, power-ups, luck

1. Press Play. Boot adds Buffs and Peddler lines and `server started: PlayerData, WorldClock, Meadow, Materials, Spawner, Economy, Buffs, Shop, Catching, Peddler, Dev`. About 20 s in, a gold ship descends to the right of the camp with a toast "The Peddler has landed!" and a nameplate "The Peddler / Leaves in 1:30".
2. Within 12 studs the button reads "Trade". Open it: a gold "The Peddler" panel with three offer cards (kind chip, name, description, price or Free, Buy). `/scrap 5000` then buy a Speed Burst: toast, Scrap drops, the card reads "Sold"; buy it again is refused with "Already bought this visit". A Scrap bundle offer is Free and adds 500 Scrap. A Rare or Epic egg hatches through the reveal card with a NEW! ribbon when new, and posts the server banner like a wild catch.
3. After 90 s the ship lifts off, the panel closes if open with "The Peddler has left", and the Trade button disappears. The next visit comes 5 minutes after the last one started.
4. Bottom-left a "Power-ups" row appears once you hold any: a square per power-up with a count badge. Tap Speed Burst: toast "Speed Burst on!", a blue timer under the slot counts down from 1m 0s, and you move faster; tapping it again while active says "Speed Burst is already running". Leave and rejoin: the timer resumes from where it was (it only runs while online).
5. Luck: under the ship bar a "Luck x1.3" readout appears at night (x1.0 is hidden); a Lucky Charm adds +0.5 while it runs; catching Commons in a row raises it slowly (pity), and a Rare resets it. Spawns near a lucky player roll better tiers.
6. Steady Hands: the capture zones are visibly 30% wider for 10 minutes. Scrap Magnet: catch Scrap pays +50%.

7. Special weather: `/rain` (or `/weather Rain`) forces World 1's special weather: a purple banner "Rain! Thunderhog is out!" slides in, the clock chip reads "Day · Rain", Thunderhogs can spawn in the Meadow and the Storm Shard nodes light up. `/clear` ends it. Weather now rolls from the world's list (Clear, Fog, Rain) with Rain at a 34% chance per change.

8. Layout checks from the 6a test: the chat window now sits bottom-left (the menu stack and Scrap pill are clear of it), the power-up bar is bottom centre, the menu stack hides during a capture and a reveal, toasts stack below an open panel's header, and the Glider row reads "Unlocks with your first launch".
9. Rainy night: `/rain` then `/night`: Cave Crystals are Available (night is still night in the rain) and Storm Shards too; the Nearby column lists both the Night and the Rain species.

Known gaps in this milestone: Scanner Pulse (needs the radar), Double Shift (earned only, no source yet), Peddler ship art and landing sound.

## Milestone 7: Field Notes and the Warden

1. Press Play. Boot adds a Quests line and `server started: ..., Shop, Quests, Catching, Peddler, Dev`. A fifth menu button "Quests" ("!") opens the Field Notes panel: "Step 1 of 5", "First Friends" with its legend, "Catch 5 aliens 0/5", reward "Speed Boots", a grey Claim button; steps 2 to 5 dimmed below.
2. Catch five aliens: the objective counts up; at 5/5 a toast "Field Notes: First Friends complete!" and a red dot on the Quests button. Claim: toast "Reward claimed: Speed Boots", the Shop shows Boots Owned, step 2 "Night Walk" becomes current.
3. Step 2: `/night`, catch anything (1/1) and collect a Cave Crystal (1/1); claim pays 500 Scrap and three Twig Lures. Step 3: craft a Glow Lure in the Shop and catch a Rare (Sparkfox); claim banks a spin and a Glow Lure. Step 4: `/rain` and catch a Thunderhog; claim gives the Warden's Horn (inventory item).
4. Walk to the Shrine of Gaiabloom (straight behind the camp, +Z about 155 studs: a stone ring with a glowing pedestal and a nameplate). By day the button reads "Sound the horn" and refuses with "The horn only works at night"; `/night` then press it: a gold banner "Gaiabloom has come to the shrine!" and a Legendary Gaiabloom appears beside the pedestal, visible only to you.
5. Catch it: three rounds; after each won round "Round 2: the zone shrinks!" and the zones are 15% narrower. On a catch: the reveal with the Legendary colour, the server banner, Gaiabloom seated at a station, and "Warden's Core" in the Ship screen's Engine Core row. Three failed sweeps: "Gaiabloom retreats into the flowers" and the horn refuses with "The Warden rests" for 15 minutes. An unanswered Warden retreats after 3 minutes.
6. Step 5 claims as done: the panel reads "The Field Notes are complete. The Warden rides with you."
7. Other players never see your summoned Warden and cannot catch it.

8. Fast path for testing the finale: `/step 5` jumps the Field Notes to the last step and `/horn` grants the Warden's Horn; then `/night`, walk to the shrine and press "Sound the horn". The step reads 0/1 while the Warden is out and 1/1 only once it is caught; claiming is refused with "Finish every objective first" until then, so a fled Warden can always be summoned again after the cooldown.
9. Automation notes: send one chat command per execute_luau call (back-to-back SendAsync calls from one thread are dropped silently). The wild count rises above 14 right after a teleport because spawns around the old spot stay until they are 180 studs away; that is the cull distance, not a leak.

Known gaps in this milestone: daily and weekly quests, the shrine's art, the Warden's three attack patterns (only the shrink is in), riding.

## Milestone 8: the tutorial (first eight minutes)

Play as a fresh profile (Studio memory profiles reset every Play).
1. Press Play. Boot adds a Tutorial line and `server started: ..., Quests, Tutorial, Catching, Peddler, Dev`. A gold pill above the bottom edge reads "Collect 3 wreck plates for the hull." with "0/3", and a bobbing "v" marker with "Wreck Plate 32m" floats over the nearest plate. Collecting hands the marker to the next plate; at 3/3 the pill slides to "A Mossbop wants to help! Walk up and tap Catch!" and the marker points at a Mossbop standing left of the camp (visible only to you; it never despawns, and comes back 20 s after a fled catch).
2. Catch it: the pill reads "Mossbop is gathering for you. Walk to the ship, pay for the Hull Frame and add your 3 wreck plates." with the marker on the ship. Pay 300 Scrap (first-catch bonus plus income gets there in about two minutes; `/scrap 300` to skip) and tap Add Wreck Plate: the module starts and the pill reads "Puffpuff wants to help!..." and a Puffpuff waits at the same spot.
3. Catch the Puffpuff: "Catch 3 more aliens while they work." with "0/3" counting any catch. Then "Your crew is building the Hull Frame. Watch the ship bar." with the marker on the ship until the module completes (about 30 s at crew speed x2).
4. "Thrusters need Glowroot from the Forest. Follow the marker." points at the Forest centre; stepping into the Forest ends the tutorial: the pill reads "You know the loop: catch, build, fly." for a moment and disappears for good (tutorialStep is saved).
5. The hint and the marker hide during a capture, a reveal and any open panel, and come back after.
6. `/step` does not touch the tutorial; `/tutorial N` jumps to step N (8 ends it). A rejoin resumes at the saved step with its trainee alien re-spawned. A step whose module trigger already happened (the Hull Frame finished while you were still catching, or offline) is skipped the moment it begins.

Known gaps in this milestone: the crash-landing cinematic, the camera pan on module completion, the guaranteed Sparkfox in step 5, analytics funnel events.

## Milestone 9: Welcome Week gifts, the spin wheel, the Meteor Shower

Play as a fresh profile.
1. Press Play. Boot adds Events and Gifts lines: `server started: PlayerData, WorldClock, Events, Meadow, ..., Peddler, Gifts, Dev`, with Events printing the seconds to the next shower. A red "Gifts" button joins the left menu with a badge of 1 (day 1 unclaimed).
2. Gifts: a panel titled "Gifts & Spin". Left: "Welcome Week", "Days played: 1", seven tiles in rows of three. Day 1 ("Welcome Pack") has a green Claim button; days 2 to 7 are grey with "Locked"; day 7 ("Epic Egg") is in the Epic colour. Claim day 1: Scrap rises by 300, the tile turns to "Claimed", a toast "Day 1 gift: Welcome Pack", the badge clears.
3. `/days 7` then reopen: six Claim buttons and the badge reads 6. Claim day 2 (two Twig Lures in the Shop's lure count), day 3 (two Speed Bursts on the power-up bar), day 5 ("Banked spins: 2"), day 7: the panel closes and the alien reveal plays for an Epic alien, which then sits in a station or the Aliens list. Claiming a claimed day does nothing; `/days 0` locks every unclaimed tile again (claimed ones stay "Claimed").
4. Spin: the right half shows the wheel with eight labelled wedges, every label carrying its odds, and "Odds: ..." listing all eight summing to 100%. "Free spins: 1" on a fresh day. Tap Spin!: the wheel turns three to four times and stops with the pointer on the won wedge, then "You won <segment>!" and the reward lands (Scrap, a lure, a power-up, or the Companion Token in inventory). Free spins goes to 0 and a second tap toasts "Come back tomorrow for a free spin". `/spins 3` adds three to the bank; each spin consumes one. The button is disabled while the wheel turns.
5. Meteor Shower: `/shower`. A purple banner "Meteor Shower!" plays, the luck label is replaced by a two-line event banner, "Meteor Shower!" over "2m 59s left", with a green "x3.0 LUCK" chip (x3.3 at night) counting down; toasts stack under the banner while it shows, and the Nearby panel lists the Ra-dish Cosmic as a Shower species. Cosmics are rare even now (0.2% of spawns times luck, by design), so use `/spawn Radish` to place a Ra-dish in front of you: it carries the Cosmic colour and a three-round capture, and its catch posts a Cosmic announcement banner. After 180 s (or `/shower end`) a toast "The sky clears", the luck label returns (x1.0 by day, x1.3 at night), and any Ra-dish still wild leaves.
6. Countdown chip: `/shower in 20` schedules a shower 20 s out: the purple "Shower in 19s" chip appears under the biome chip at once (it shows inside the last 5 minutes before a shower), counts down, and the shower starts on time. With the real clock showers start on the two-hour marks (the Events boot line says how long). The chip never overlaps the Nearby panel.
7. Second client: the shower, its banner and the luck chip are the same for everyone; the Gifts panel is per player.

Known gaps in this milestone: the Cosmic Ra-dish uses the placeholder shape; the Companion Token has no use until the companions milestone; no gift calendar artwork.

## Milestone 10: Radar Mk1

Play as a fresh profile.
1. No minimap at boot: the right edge shows the clock, biome and (when due) shower chips, then the Nearby column (0.225 to 0.63 of the ScreenGui, which excludes the top inset), as before. Boot's Dev line lists `/radar`.
2. Shop, Gear tab: a "Radar Mk1" row between the Hoverboard and the Glider reads "Aliens within 120m on a minimap. Tap a blip to mark it." for 1,500 Scrap. With less Scrap the tap toasts "Not enough Scrap". `/scrap 1500` and buy: Scrap drops by 1,500, the row reads "Owned", and a dark round minimap with a navy outline appears at the right edge under the chips in place of the Nearby column, which hides while a radar is owned. Buying again does nothing (AlreadyOwned).
3. The disc: "N" at the top, a faint blue range ring with "60m" at half radius, a gold diamond at the centre that turns with the camera. Every wild alien within 120 studs is a blip: caught species are filled in their rarity colour; uncaught species are dark with a rarity-coloured ring (a Secret has a white ring). Walk toward a blip and it slides to the centre; aliens past 120 studs are not drawn. A cream square marks the camp and sits pinned to the disc edge when the camp is out of range; during a Peddler visit a gold diamond marks the ship the same way.
4. Tap a blip (tutorial finished: `/step` does not end the tutorial, so either play through it or use a profile that has): the floating waypoint marker jumps to that alien with its name (or "???" for an uncaught species) and a toast "Marked: Mossbop". Walk to it: within 8 studs the marker clears. Catch it instead and the marker clears when the alien is gone. A tap during the tutorial toasts "Finish the first steps before marking aliens" and leaves the tutorial's marker alone.
5. The minimap hides during a capture, a reveal and while any panel is open, and comes back after; the Nearby column stays hidden while the radar is owned.
6. `/radar` on a fresh profile grants the Radar Mk1 free (the Field Notes step 2 reward does the same; the Quests panel lists "Radar Mk1" first among its rewards). The radar survives a rejoin (gear.radar is saved).
7. Device check: at iPhone SE the disc is about 93 px wide and its blips still show their colours; the "N" and ring label stay legible. At iPad the disc does not touch the shower chip or the action button.

Known gaps in this milestone: Radar Mk2 and Mk3 answer "unlocks later"; no minimap on the nodes or hidden spots; no compass strip yet.

## Milestone 11: juice (sounds, particles, ambience, camera moments)

Every sound id in `src/shared/data/Sounds.luau` is still `rbxassetid://0`, so nothing is audible yet: this milestone tests that every hook fires without errors and that the camera always comes back. Play as a fresh profile.
1. Crash landing: on a brand-new profile the HUD is hidden and the camera starts about 140 studs above the camp looking down, a red banner "Mayday! We're going down!" plays, the camera drops over 4 s to a spot behind the character, shakes briefly, a gold banner "...Everyone okay? The ship is not." follows, and the HUD, menu and tutorial pill appear. Walking is possible throughout. A rejoin or any profile past step 1 (`/tutorial 2` then rejoin, or a collected plate) skips it. Console: no errors.
2. Catch burst: catch any alien. Where it stood a burst of particles in its tier colour plays for under a second, and a gold "+10" (or the catch's Scrap) flies from the action button to the Scrap pill before the Reveal opens. `Workspace.ClientVfx` holds the emitter parts briefly and empties itself.
3. Module complete: build the Hull Frame (plates, `/scrap 300`, Pay and Add). On completion a green burst plus gold sparkles rise over the ship, the camera glides to look at the ship for about 2.5 s, rests 1.2 s and glides back, and the usual "Hull Frame complete" toast shows. If a capture starts or a panel is open at that moment the pan is skipped (or cancelled). The camera always returns to the character with normal control.
4. Shower: `/shower`. Meteor streaks (purple dots falling at an angle) appear over the camp for the 180 s and stop with "The sky clears". `Workspace.ClientVfx.ShowerSky` exists only while the shower runs.
5. Peddler: at its next visit (or wait for the 300 s clock) the ship lands with a cream dust puff at the landing spot.
6. Ambience: `SoundService.Ambience` (a SoundGroup) exists; with every id empty it holds no Sounds and nothing errors across `/night`, `/day`, `/rain`, `/clear`, `/shower`.
7. Sound hooks fire silently (no errors) on: any toast, a server banner, Add Wreck Plate, a gift claim, the wheel turning and stopping, sounding the horn, the Warden appearing.
8. Reduced motion: with Roblox's Reduced Motion setting on, the pan and the crash drop take half the time and the shake is skipped.

Harness note: Studio's MCP `execute_luau` records the camera type when a call starts and restores it when the call ends, so a call that straddles a camera sequence (the opener, a pan) leaves the camera Scriptable afterwards. Start such calls only while the camera is Custom.

Known gaps in this milestone: real sound assets (the team picks about 40 ids into Sounds.luau), the day/night ambience cross-fade is untestable until ids exist, no particle textures (round default dots), the launch sequence waits for World 2.

## Milestone 12: mesh models in the world

Needs one model imported by hand first: File > Import 3D on `assets/models/Mossbop/Mossbop.fbx` (scale 1), then move the "Mossbop" Model into a folder `ReplicatedStorage.Models` (create it). Everything else keeps its placeholder, which is the point of the test.
1. Press Play. No warning about a missing Models folder (with no folder at all the client warns once, "placeholders in use", and nothing else changes).
2. Wild Mossbops render as the mesh: a green round body with eyes, feet on the ground where the placeholder ball sat, bobbing, each turned a different way, facing -Z of its own frame (the eyes point along the Model's front). The server's Part is invisible but still carries the nameplate, now lifted above the mesh's top. Every other species is still a placeholder shape.
3. Shadow: on a fresh profile a Mossbop beyond 40 studs is a dark silhouette (every MeshPart in the shadow colour, SmoothPlastic); walking within 40 studs restores its exact colours. Catching one keeps it in colour everywhere after.
4. Catch a Mossbop: the Reveal card shows the mesh in a slowly turning viewport instead of the green square; the "NEW!" ribbon, tier and Scrap lines are unchanged. Catch any other species: the placeholder square still shows.
5. Codex: the Mossbop entry shows the mesh on the pedestal, turning; uncaught it is the dark silhouette. A placeholder species shows its shape as before.
6. Camp: a Mossbop seated at a station is the mesh at worker scale, facing its station, bobbing, with its nameplate; a placeholder species beside it is the old shape.
7. Facing check: if the eyes point away from the Model's front (toward +Z), set `Config.ModelFacesPlusZ = true` and confirm the clone turns 180 degrees; the FBX import should not need it.
8. Nearby, Radar, catch distance and the tap-to-catch on the alien all still work on the server Part (the mesh parts are not queryable).

Known gaps in this milestone: models are imported by hand into the place (no Open Cloud upload yet), no idle animation, overlays (Shiny, Gold) still tint only the placeholder.

## Milestone 13: Settings and the analytics funnel

Play as a fresh profile.
1. Boot adds Analytics (right after PlayerData) and Settings (after Gifts) lines: `server started: PlayerData, Analytics, WorldClock, ..., Gifts, Settings, Dev`, with "Analytics: Studio print mode" (Studio never sends; it prints each event) and "Settings: 4 preferences". A round blue "*" button sits left of the clock chip at the top right; it hides with the HUD during the crash opener and comes back.
2. Tap it: a panel "Settings" with four rows: World sounds (Off/Low/Mid/High, Mid active), Button and catch sounds (High active), Reduced motion (Off), Shadow silhouettes for uncaught aliens (On), and the hint line at the bottom. Each control is at least 44 px tall at iPhone SE.
3. Tap "Low" on World sounds: the button turns green at once after the server's push (SettingsChanged), SoundService.Ambience.Volume reads 0.35 x 0.33 (about 0.12). Tap "Off" on Button and catch sounds: SoundService.UI.Volume reads 0. A bad call `SetSetting("Ambience", 9)` from the client returns (false, "BadArgs"); `SetSetting("Nope", 1)` the same.
4. Reduced motion On: a module completion's camera pan takes half as long (about 3 s out and back instead of 6) and the crash opener on a later fresh profile skips the shake; the "+N" Scrap fly is quicker.
5. Shadow silhouettes Off: every uncaught wild alien renders in colour at any distance and the codex pedestal shows uncaught species in colour (the name stays "???"); On again re-shadows them beyond 40 studs.
6. Rejoin (memory profiles reset in Studio; with DataStores on, the saved choices come back): the panel opens with the stored values. A v2 profile (no settings) loads with the defaults and no error.
7. Analytics prints, in order, as you play: `analytics: funnel Onboarding 1 T1` at load, then one per tutorial step reached (2 T2 ... 8 Done); `analytics: event Catch` with tier, species and perfect fields on every catch and `FirstCatchSeconds` once; `CatchMiss` on a missed sweep, `Flee` when an alien flees; `ModuleComplete` and `FirstModuleSeconds` on the Hull Frame; `ShowerAttend` for each player when `/shower` starts; `GiftClaim`, `Spin`, `PeddlerBuy`, `ShopBuy` on those actions; economy lines for catch and codex Scrap (Source), module pay, shop and Peddler (Sink), and one Income source line about every 60 s; `SessionSeconds` when the player leaves (stop Play and read the server log). No event prints twice for the same funnel step in one session.

Known gaps in this milestone: no master volume slider (levels instead); analytics are print-only in Studio until the place is published and `Config.AnalyticsInStudio` is turned on; daily quests and the Robux shop are later milestones.

## Milestone 14: the Robux launch shop

Product and pass ids in `src/shared/data/Shop.luau` are 0 until they exist in the Creator Dashboard, so a Buy tap answers "The purchase did not go through" (NotLive) and nothing is charged. Grants are tested with the Studio commands instead: `/buy <itemId>` runs the same grant path a receipt would, `/pass <itemId>` (or `/pass <itemId> off`) sets pass ownership for this session.
1. Boot adds a Monetization line right after Analytics: "Monetization: 10 products, 4 passes (live ids: 0)" and `server started: PlayerData, Analytics, Monetization, ...`.
2. Shop > Robux: a scrolling page with three sections. Featured: one gold Starter Pack tile with its description, three Rare picker buttons (Rocklobber, Zapfinch, Sparkfox) and a grey "Pick your Rare first" button. Passes: four small tiles (+1 Slot on Every Station R$ 399, Auto-Optimize R$ 299, Longer Offline Shift R$ 299, Explorer Pack R$ 399). Boosts: Speed Burst x5 R$ 49, Steady Hands x3 R$ 79, Scrap Magnet x3 R$ 99, Server Luck x2 R$ 249 and x4 R$ 999 (the last two carry "Everyone on this planet gets it"; they are hidden entirely for an account whose policy restricts paid random items). Every price reads "R$ N".
3. Tap Sparkfox: the button turns green and the tile reads "Your Rare: Sparkfox"; the Starter Pack button turns green with "R$ 199". Tap it: toast "The purchase did not go through" (ids are 0) and a NotLive print; nothing granted.
4. `/buy StarterPack`: the Reveal plays for a Sparkfox (Rare), Speed Boots show as Owned in Gear, "Banked spins: 5" in Gifts, toast "Thanks! Starter Pack is yours", the tile now reads "Claimed". A second `/buy StarterPack` prints AlreadyOwned and grants nothing. `/buy SpeedBurstx5`: the power-up bar shows Speed Burst x5. `/buy ScrapMagnetx3`: x3.
5. `/pass ExplorerPack`: Gear shows Speed Boots, Hoverboard and Radar Mk1 as Owned (the radar disc appears) and the Explorer Pack tile reads "Owned". `/pass SlotEveryStation1`: every station gains one slot (Aliens screen or station pads). `/pass LongerOffline`: no visible change now; the offline cap becomes 3 hours (rejoin after a long absence with DataStores on). `/pass AutoOptimize`: catch an alien that would do better at another station than the one auto-assign picked; it is moved at once.
6. `/buy ServerLuck2x`: a gold banner "<you> bought 2x luck for everyone!", the event banner slot reads "2x luck for everyone" over "14:59 left" with a green "x3.0 LUCK" chip (base 1 + 2 on a day with no other bonus), the Luck readout for every player on the server rises, and the Nearby panel is unchanged. `/shower` while it runs: the shower banner takes the slot and the luck chip shows both (x5.0). `/shower end`: the server-luck banner returns with its remaining time. `/buy ServerLuck4x` while x2 runs: the banner changes to 4x; `/buy ServerLuck2x` while x4 runs: the time extends, the bonus stays x4. After 15 minutes it ends and the luck label returns.
7. Receipts: `ProcessReceipt` cannot be driven from Studio without live ids; once ids exist, Studio's test purchases (no charge) exercise it. A repeated receipt id is answered PurchaseGranted without a second grant (profile.shop.receipts remembers 100).
8. Analytics prints `event ShopBuy kind=robux id=<item>` for every grant, pass grants included.

Known gaps in this milestone: the +1 slot pass does not yet stack on top of a module unlock of the same size and `Config.StationMaxSlots` (3) caps it, so the stacking rule is a design decision before that pass goes live; hoverboard skins (no hoverboard yet), the Home tab, direct-buy aliens, paid spins (P1, with the compliance pass), real-currency equivalents under prices (needs Roblox's regional pricing data), offers that appear at a moment ("all slots full", "shower in under 5 minutes").

## Milestone 15b: one place per world (the Frostbyte layout)

Two Rojo projects now describe the same code for two places: `default.project.json` (World 1) and `world2.project.json` (World 2), differing only in the Workspace attribute `WorldId`. Stop `rojo serve`, run `rojo serve world2.project.json`, connect, and press Play.
1. Boot lines name World 2: "Quests: Field Notes for world 2, 5 steps; warden Skaddle", Materials places the Frostbyte nodes (4 kinds), WorldClock rolls Clear/Snow with Blizzard as the special weather. No errors; `Workspace:GetAttribute("WorldId")` reads 2.
2. The world: a snow-white floor, the cream camp pad, white-and-blue pine scatter, a roofed pale-blue Ice Cave at (-130, -120) with pillar walls, an orange-brown Geyser Field at (130, 120) with 14 dark cone geysers, and the shrine at z 155 in ice colours. The biome chip reads "Snowfield", then "Ice Cave" and "Geyser Field" inside the regions.
3. Spawns are World 2 species only (Flufflet, Snowbun, Pengoo and the rest; Nearby lists them), with the blockout meshes if their Models are imported. `/weather Blizzard`: the banner names Frostfang and it spawns in the Snowfield; `/spawn Fenripup` places the Star-born.
4. Nodes: Ice Plates in the Snowfield ring, Geyser Pearls in the Geyser Field, Frost Cores in the Ice Cave at night, Blizzard Shards in the Snowfield during a Blizzard; the Ship screen shows the five Frostbyte modules (Heat Shield first) and their key parts.
5. Quests: the Field Notes panel shows the W2 chain; `/step 5` and `/horn` at night summon Skaddle at the shrine.
6. Switch back to `rojo serve` (World 1): everything is as before, with the biome chip reading "Meadow" and the Verdant layout. A profile moved with `/world 2` on World 1 keeps its World 1 camp data and shows World 2's modules only in the World 2 place.

Known gaps in this milestone: launching between places (15c), outposts, the Heater rule for blizzards, World 2's tutorial beats (the tutorial is World 1 only), a place id per world in the data for the teleport.
