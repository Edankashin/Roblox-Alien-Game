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
1. Boot adds a Monetization line right after Analytics: "Monetization: 6 products, 4 passes (live ids: 0)" and `server started: PlayerData, Analytics, Monetization, ...`.
2. Shop > Robux: a scrolling page with three sections. Featured: one gold Starter Pack tile with its description, three Rare picker buttons (Rocklobber, Zapfinch, Sparkfox) and a grey "Pick your Rare first" button. Passes: four small tiles (+1 Slot on Every Station R$ 399, Auto-Optimize R$ 299, Longer Offline Shift R$ 299, Explorer Pack R$ 399). Boosts: Speed Burst x5 R$ 49, Steady Hands x3 R$ 79, Scrap Magnet x3 R$ 99, Server Luck x2 R$ 249 and x4 R$ 999 (the last two carry "Everyone on this planet gets it"; they are hidden entirely for an account whose policy restricts paid random items). Every price reads "R$ N".
3. Tap Sparkfox: the button turns green and the tile reads "Your Rare: Sparkfox"; the Starter Pack button turns green with "R$ 199". Tap it: toast "The purchase did not go through" (ids are 0) and a NotLive print; nothing granted.
4. `/buy StarterPack`: the Reveal plays for a Sparkfox (Rare) after the catch banner, Speed Boots show as Owned in Gear, "Banked spins: 5" in Gifts, toasts "Thanks! Starter Pack is yours" and "Thanks! Starter hoverboard skin is yours", the tile reads "Claimed" when the Shop is reopened. A second `/buy StarterPack` prints AlreadyOwned and grants nothing. `/buy SpeedBurstx5`: the power-up bar shows Speed Burst x5. `/buy ScrapMagnetx3`: x3.
5. `/pass ExplorerPack`: Gear shows Speed Boots, Hoverboard and Radar Mk1 as Owned (the radar disc appears) and the Explorer Pack tile reads "Owned". `/pass SlotEveryStation1`: every station gains one slot (Aliens screen or station pads). `/pass LongerOffline`: no visible change now; the offline cap becomes 3 hours (rejoin after a long absence with DataStores on). `/pass AutoOptimize`: catch an alien that would do better at another station than the one auto-assign picked; it is moved at once.
6. `/buy ServerLuck2x`: a gold banner "<you> bought 2x luck for everyone!", the event banner slot reads "2x luck for everyone" over "14m 59s left" with a green "x2.0 LUCK" chip (luck is additive: 1 + 1.0 on a day with no other bonus), the Luck readout for every player on the server rises, and the Nearby panel is unchanged. `/shower` while it runs: the shower banner takes the slot and the luck chip shows both (x4.0). `/shower end`: the server-luck banner returns with its remaining time. `/buy ServerLuck4x` while x2 runs: the banner changes to 4x and the chip to x4.0 (LuckChanged is re-sent); `/buy ServerLuck2x` while x4 runs: the time extends, the bonus stays x4. After 15 minutes it ends and the luck label returns.
7. Receipts: `ProcessReceipt` cannot be driven from Studio without live ids; once ids exist, Studio's test purchases (no charge) exercise it. A repeated receipt id is answered PurchaseGranted without a second grant (profile.shop.receipts remembers 100).
8. Analytics prints `event ShopBuy kind=robux id=<item>` for every grant, pass grants included.

Known gaps in this milestone: the +1 slot pass does not yet stack on top of a module unlock of the same size and `Config.StationMaxSlots` (3) caps it, so the stacking rule is a design decision before that pass goes live; hoverboard skins (no hoverboard yet), the Home tab, direct-buy aliens, paid spins (P1, with the compliance pass), real-currency equivalents under prices (needs Roblox's regional pricing data), offers that appear at a moment ("all slots full", "shower in under 5 minutes").

## Milestone 15b: one place per world (the Frostbyte layout)

Two Rojo projects now describe the same code for two places: `default.project.json` (World 1) and `world2.project.json` (World 2), differing only in the Workspace attribute `WorldId`. Stop `rojo serve`, run `rojo serve world2.project.json`, connect, and press Play.
1. Boot lines name World 2: "Quests: Field Notes for world 2, 5 steps; warden Skaddle", Materials places the Frostbyte nodes (4 kinds), WorldClock rolls Clear/Snow with Blizzard as the special weather. No errors; `Workspace:GetAttribute("WorldId")` reads 2.
2. The world: a snow-white floor, the cream camp pad, white-and-blue pine scatter, a roofed pale-blue Ice Cave at (-130, -120) with pillar walls, an orange-brown Geyser Field at (130, 120) with 14 dark cone geysers, and the shrine at z 155 in ice colours. The biome chip reads "Snowfield", then "Ice Cave" and "Geyser Field" inside the regions.
3. Spawns are World 2 species only (Flufflet, Snowbun, Pengoo and the rest; Nearby lists them), with the blockout meshes if their Models are imported. `/weather Blizzard`: the banner names Frostfang and it spawns in the Snowfield; `/shower` then `/spawn Fenripup` places the Star-born (a conditional species despawns on the next tick unless its condition is running, so without the shower it vanishes at once).
4. Nodes: Ice Plates in the Snowfield ring, Geyser Pearls in the Geyser Field, Frost Cores in the Ice Cave at night, Blizzard Shards in the Snowfield during a Blizzard; the Ship screen shows the five Frostbyte modules (Heat Shield first) and their key parts.
5. Quests: the Field Notes panel shows the W2 chain; `/step 5` and `/horn` at night summon Skaddle at the shrine.
6. Switch back to `rojo serve` (World 1): everything is as before, with the biome chip reading "Meadow" and the Verdant layout. A profile moved with `/world 2` on World 1 keeps its World 1 camp data and shows World 2's modules only in the World 2 place.

Known gaps in this milestone: launching between places (15c), outposts, the Heater rule for blizzards, World 2's tutorial beats (the tutorial is World 1 only), a place id per world in the data for the teleport.

## Milestone 15c: the launch

World 2's place id is 0 until it is published, and Studio never teleports, so the launch is tested up to the fade and back. Play on World 1 (`rojo serve`) as a fresh profile.
1. Boot adds a Launch line after Economy: "Launch: this is world 1 (Verdant Crash Site); next world 2 place not published; Studio: teleports are skipped". The Dev line lists `/world N` and `/complete`.
2. With a module unfinished, walk to the ship: the button reads "Build" (the Ship screen). `/complete`: every module card reads "Done!", the ship bar reads 100%, and the button by the ship reads "Launch".
3. Press Launch: the HUD hides, the ship lifts over 4 s while the camera glides to it, a gold burst plays at the base, then the screen fades to black with "Next stop: Frostbyte". After 2 s a toast "Frostbyte opens when it is published. The ship is ready.", the screen fades back, the ship sits where it was and the HUD returns. CameraType reads Custom afterwards.
4. The profile moved: the Aliens and Ship screens now show World 2's modules (Heat Shield first, 0%), and Launch on World 1 now refuses with "Your ship is on another world" (the ship stays). Analytics prints `event Launch from=1 to=2`.
5. The Glider: Shop > Gear shows the Glider Pack as buyable (R$ price in Scrap, 15,000) now that two worlds are unlocked; before the launch it read "Unlocks with your first launch".
6. Refusals: on a fresh profile with modules unfinished, calling the Launch remote returns (false, "NotComplete") and the toast "Finish every module first"; a profile already on the last world gets "This is the last world for now".
7. World 2 place: `rojo serve world2.project.json`, Play with a profile moved by `/world 2`: the Frostbyte camp with the five modules at 0%, the Launch line names world 2 and next world 3.

Known gaps in this milestone: the real teleport (needs the published World 2 place id in Worlds.luau and a published universe), outposts producing materials, the Launch Pack offer, the Star Chart to fly back.

## Milestone 16: the Heater rule (World 2)

On the World 2 place (`rojo serve world2.project.json`), with a profile moved by `/world 2`.
1. Boot adds a Heaters line after Economy: "Heaters: rule on for this world" (on World 1 it reads "off"). The remote `PlaceHeater` exists on both.
   After `/world 2` on a profile mid-tutorial: the tutorial pill and waypoint go, Output prints one TutorialSkipped analytics event (value = the step left, field world 2) and no Onboarding funnel lines; the Ship screen lists the World 2 modules.
2. `/weather Blizzard`: the weather banner names Frostfang, a blue hint banner "Blizzard! Aliens hide beyond 25m. Place a Heater to reveal them." shows once, and every wild alien farther than 25 studs disappears (parts and meshes fully transparent, nameplates off, radar blips gone, taps ignored); the ones within 25 studs stay. Walk toward a hidden one: it appears at 25 studs. The Nearby column still lists species (by design).
3. With nothing else in reach the action button reads "Place Heater". With under 150 Scrap: toast "A Heater costs 150 Scrap". `/scrap 500` and tap: Scrap drops by 150, a glowing orange disc appears 6 studs ahead under `Workspace.World.Heaters` with attributes OwnerId, ExpiresAt, Radius 40, toast "Heater lit: 60s of clear air around it", and every alien within 40 studs of the disc shows even beyond 25 studs from you. Analytics prints a Sink line with sku Heater.
4. A third Heater while two burn: toast "Two heaters are burning already". After 60 s the disc vanishes and the aliens it revealed hide again if still beyond 25 studs. `/clear`: the blizzard ends, everything shows, the action button no longer offers the Heater, and tapping the remote answers NoBlizzard.
5. World 1 place: `/weather Rain` never hides anything and `PlaceHeater` answers NotThisWorld.

Known gaps in this milestone: the heater's look (a plain disc; particles and a warmth ring later), the disc size, colour and the 0.25 s check interval live as module constants until moved into Config, and the Nearby column does not reflect hidden aliens.

## Milestone 17: environment props (both places)

Nothing changes until a prop is imported: every builder keeps its part placeholder. Step 1 proves that; the rest need the hand import.
1. With no `ReplicatedStorage.Models.Props` folder, both places build exactly as before (trees, rocks, geyser cones, shrine, ship pad, three stations, heater disc) and Output shows nothing red. The scatter is laid out differently from the milestone 16 build (each tree, rock and cone now takes three extra seeded draws: kind, turn, jitter) but it is identical between the two runs of this step and, later, with and without imports, because those draws happen whether or not a prop exists.
2. Import one prop: File -> Import 3D on `assets/models/props/MeadowTree/MeadowTree.glb`, scale 1, one MeshPart per material; name the result exactly `MeadowTree` and parent it under `ReplicatedStorage.Models.Props` (create `Models` and `Props` folders if missing). Play on the World 1 place: about half the open-floor trees (the layout picks `MeadowTree` or `MeadowTreeB` per tree) are now mesh oaks standing on the ground at the placeholder's spot, sizes varying by about 10%, each named `Tree<n>` under `Workspace.World`; the other half are still cylinder-and-ball placeholders. Walking into a mesh tree is blocked (CanCollide stays on).
3. Import `ShrineStone` and `Pedestal`. The shrine ring is now eight mesh stones facing inward, tinted the layout's stone colour (grey on World 1, pale blue on World 2), the pedestal mesh is tinted the pedestal colour, the Neon glow ball still floats above it, and the Field Notes finale still measures distance to the pedestal (horn works at the shrine).
4. Import `ShipHull`, `GatherStation`, `BuildStation`, `SparkStation`. The camp shows the hull mesh under the module ghosts (the pad slab is invisible but still there), the picnic table, workbench and glow flower replace the station blocks, nameplates still float above them and workers still stand in their slot rows. `/complete` then Launch: the hull lifts with the modules and comes back down on a reset.
5. World 2 place, import `HeaterLamp` and `GeyserCone`, `/weather Blizzard`, `/scrap 500`, Place Heater: a brazier with flames stands where the disc was (the disc is invisible, attributes unchanged) and still reveals aliens within 40 studs; it vanishes after 60 s. Geyser cones in the Geyser Field are mesh cones.
6. Regenerate: `python3 tools/blender/props_base.py --all` prints a line per prop with a triangle count of 600 or less and exits 0.

Known gaps in this milestone: ship modules stay part placeholders (their ghost and snap visuals are part-based), props are not recoloured per world except the shrine, and hand-placed dressing (Brushtool, Redupe) lives in the place file, not in Rojo.

## Milestone 18: Outposts and the Star Chart (World 2 place, then World 1)

A fresh profile on the World 2 place, moved with `/world 2` (so World 1 is unlocked and World 2 is current). Outposts produce lazily: nothing ticks, pending = time since the last collect, capped at 24 h.
1. Boot lists Outposts among the started services, before Launch. Ship screen: a "Star Chart" button bottom-left. Tap it: the Ship screen closes and the Star Chart opens as an orbit map: a gold star with a soft glow in the middle of seven thin rings, one numbered planet per world (1 to 7) on its own ring, and a card for the selected world on the right (about 40% of the panel). Opening selects the current world. Frostbyte's planet is green with a gold ring that pulses (the ring holds still with Reduced Motion on) and its card reads "You are here"; Verdant Crash Site's planet is lit blue with no chip (no outpost yet, because `/world` does not launch); Neon Grid's planet has a gold outline and a dim fill; the other four are faint grey. Tap a planet: its ring turns thick (on the green planet the pulse keeps going, from the thicker ring), and the card switches to that world. Verdant Crash Site's card shows a Fly button and nothing else; Neon Grid's reads "Next stop: finish the ship"; the rest read "Locked" on a dimmed card. At iPhone SE size every planet is easy to hit (at least about 5% of the screen height) and the Close button stays top right. Locked and current worlds have no buttons; invoking the remote `FlyTo` with 3 from the command bar answers false, Locked.
2. `/outpost 1 2` (World 1 outpost at level 1, backdated 2 h): World 1's planet gains a "Lv 1" chip and a green dot (production is ready); tap it and its card reads "Outpost Lv 1", "90 Scrap/h, 2 materials/h", "Ready: 180 Scrap, 4 materials", and the Ready line keeps counting while the screen is open (one Scrap about every 40 s). Collect: Scrap rises by 180, the inventory gains 4 World 1 key materials dealt across Wreck Plate, Glowroot, Cave Crystal and Storm Shard (never Warden's Core), toast "Outpost: +180 Scrap, +4 materials", Analytics prints a Source line with sku Outpost, the dot disappears and the card drops to "Ready: 0 Scrap, 0 materials". Collect again at once: "The outpost needs a few more minutes" (300 s rule). `/outpost 1 30`: Ready shows 24 h of production, 2160 Scrap and 48 materials (the cap), not 30 h.
3. Upgrade with under 600 Scrap and nothing pending (collect first, then `/scrap 0`): "Upgrading needs 600 Scrap" (pending production is paid out before the check, so a backdated outpost can pay for its own upgrade). `/scrap 2000`, Upgrade: any pending production is granted first, Scrap drops by 600, toast "Outpost upgraded to Lv 2", the card reads Lv 2 (and the chip "Lv 2") with "180 Scrap/h, 4 materials/h" and a 1500 Scrap upgrade; a Sink line with sku Outpost prints. At Lv 3 the button reads "Max level" and is dimmed; the remote answers Maxed.
4. `/outpost 1 1` then Fly on Verdant Crash Site: the screens close, the banner reads "Flying to Verdant Crash Site...", the view fades to black for about 1.5 s. The place id is 0 so no teleport happens: the view returns, World 1's pending production was collected on arrival (Scrap +90, a toast), the Ship screen now lists the World 1 modules, the profile's current world is 1 and Frostbyte gained an outpost at level 1 with a fresh clock (`/outpost`-free check: its planet shows a "Lv 1" chip and no dot, and its card reads "Ready: 0 Scrap"). Analytics prints an event Fly with from 2, to 1. Fly to Frostbyte again answers ok; Fly to the current world answers SameWorld.
5. Launch from World 1 (`/complete`, walk to the ship, Launch) still works and still goes to World 2, creating no second outpost for World 1 (the existing one and its level are kept).

Known gaps in this milestone: the map's output number is the "Lv" chip and a ready dot, not the Scrap-per-hour figure (that is on the card); the daily world quest and world-exclusive Sets are later milestones; the teleport itself needs published places.

## Milestone 19: social rewards and the notifications ask (World 1 place)

Memory profiles in Studio; the referral bank and the group check need a live place for the real thing, so steps 3 and 5 use the Dev commands.
1. Boot lists Social after Gifts. Profile loads with `social.sessions` 1 (print it from the command bar through the Dev state if needed). Gifts screen: under the hint a line "Tomorrow: Twig Lure" on a fresh profile (the line names the first gift whose day is above the days played, so day 1 points at the day 2 gift); after `/days 7` and claiming all seven it reads "Every Welcome Week gift claimed!".
2. Social row on the Gifts screen with `Social.GroupId = 0` (the default): no group button at all; the Invite button shows with "Each friend who joins: 500 Scrap, 2 free spins for you, 300 Scrap, 2 x Twig Lure for them" (the social column on the right of the Gifts screen, which is now three columns: calendar, wheel, social). Tap Invite in Studio: the toast "Invites are not available right now" (Studio cannot send invites) or the native invite prompt on a live place.
3. Set `Social.GroupId` to any real group id (temporarily, not committed) and rejoin: the group button reads "Join our group"; tap: the native group prompt opens (Studio may refuse; then the button stays). From the command bar, invoke `ClaimGroupReward`: NotMember when not in the group; for a member, Scrap +500, lures +3, spins +2, toast "Group gift: 500 Scrap, 3 x Twig Lure, 2 free spins", Analytics event GroupReward, the button reads "Group gift claimed" and a second claim answers AlreadyClaimed.
4. `/social ask`: the card "Ship part alerts" with "Yes, tell me" and "Not now" (only when Roblox allows the prompt: in Studio `CanPromptOptInAsync` is usually false, so nothing shows; Output must stay clean). On a live place, Yes opens the native notifications prompt and Analytics prints NotifyAsk with answer yes; No prints answer no; a second `/social ask` inside 30 days does nothing (the server only fires NotifyAsk on load after the cooldown; the Dev command forces the event, so the card shows again: that is expected for Dev).
5. `/social credit 2`: two inviter grants, toasts "A friend joined through your link: 500 Scrap, 2 free spins" twice, Scrap +1000, spins +4, Analytics Referral role inviter twice; `/social credit 100` stops at the lifetime cap of 50 rewarded. `/social reset` clears the group gift, the referral state and the ask stamp.
6. Second session: rejoin. `social.sessions` is 2, and after 120 s the NotifyAsk event fires once (the card itself depends on step 4's platform rule). No card during a capture, the reveal or a launch; the card waits and retries.

Known gaps in this milestone: the invitee path (joining through a referral link) and the offline inviter bank can only be tested on a live place with two accounts; no cosmetic in the group gift until cosmetics render; the leave-with-timer nudge is not built (the Ship screen already shows module timers). Seen in the Studio pass: the Scrap and toast icons are placeholder squares until the icon pack (Look pass L5); the Friend Boost chip sits under stacked toasts while they show.

## Milestone 20: the weekly Catches leaderboard (World 1 place)

In Studio with memory profiles the board is this server only (DataStore off); the shared store needs Studio API access and `Config.UseDataStoreInStudio = true`, or a live place.
1. Boot lists Leaderboard before Catching. A "Ranks" button (glyph #) sits in the top row left of Settings. Tap: the screen "Top catchers this week" with "Resets in Nd Nh" counting down to Friday 16:00 UTC, the note "Studio: this server only (DataStore off)" in memory mode, the list empty with "No catches yet this week. Be the first!", and the bottom row "You: 0 catches this week, rank 100+".
2. Catch three aliens (or `/lb 3`): within a minute the list shows your display name with 3 and the bottom row reads "You: 3 catches this week, rank 1". Catches from a Starter Pack or `/spawn` grants without a catch do not count (only a real catch increments). `/lb 50`: the count climbs by at most 30 in any minute (the cap), the rest is dropped with a print.
3. Multi-client test (two players): both appear, sorted by count, ranks 1 and 2; the loser's bottom row shows rank 2. The list refreshes within 60 s of a catch without reopening.
4. With `Config.UseDataStoreInStudio = true` and API access: the key `Catches_<period id>` in the OrderedDataStore "Catches" holds the counts; rejoin and the count persists; a second Studio server sees the same board within a minute. Leaving flushes at once (no catches lost on a quick rejoin).
5. Reduced Motion on: no list stagger. iPhone SE: 10 rows visible, scrolling to 100.

Known gaps in this milestone: no camp-side board part (the screen is the chart), no all-time board, no rewards for ranks (decide with the event quest track), the all-time codex count is the Codex screen's existing count.

## Milestone 21: daily and weekly quests, promo codes (World 1 place)

1. Boot lists DailyQuests before Quests and Codes after Social. Quests screen: two header tabs, "Field Notes" and "Daily & Weekly". The second tab shows "Today" with three quests and "Resets in Nh Nm" (to 00:00 UTC) and "This week" with three quests and "Resets in Nd Nh" (to Friday 16:00 UTC). Rejoin: the same six quests (the deal is seeded by period and player).
2. Progress: catch aliens until a "Catch 5 aliens" style quest fills (or `/dq done` to fill every dealt quest). Claim: the reward lands (Scrap, lures or spins as the row says), toast "Quest done: <quest text>", the row reads "Claimed", Analytics prints DailyQuest with action claim; a second Claim answers AlreadyClaimed. Claiming a daily quest bumps a weekly "Claim 5 daily quests" quest when dealt.
3. Reroll on an unclaimed daily quest: it is replaced by a quest not on the board, progress 0, toast "New quest dealt"; the button then reads "Rerolled" and a second reroll answers NoRerolls ("No rerolls left today"). Reroll on a claimed quest answers AlreadyClaimed.
4. `/dq reset` then any catch: a fresh deal for both periods with the same ids as step 1 (same period, same player).
5. Settings screen: a "Promo code" field with Redeem. "welcome" (any case, spaces around it) redeems: +500 Scrap, +2 Twig Lure, toast "Code redeemed: 500 Scrap, 2 x Twig Lure", Analytics Code id WELCOME; again: "You already used that code"; "NOPE": "That code does not exist"; a 30-character string: refused before lookup (TooLong, no toast needed beyond the unknown one).
6. Objective kinds to spot-check with `/weather Rain` (catchSpecial counts during Rain on World 1), `/night` (catchCondition Night), a perfect-zone catch (perfectCount), a material pickup (collectAny), crafting a Twig Lure (craft). The friend kind needs a multi-client test with two friended accounts, or stays untested.

Known gaps in this milestone: no quest icons, the friend objective is unverifiable without two friended accounts, codes have no expiry in the table yet (the field exists), and claiming does not animate the row.

## Milestone 22: lighting and atmosphere per world (Look pass L1, both places)

By hand first, once per place: select Lighting in the Explorer and set Technology to Future (a script cannot). Everything else is data (`src/shared/data/Lighting.luau`) applied by the client.
1. Play on World 1: Lighting gains LookAtmosphere, LookBloom, LookColorCorrection and LookSunRays (no LookSky while the sky ids are 0). The meadow reads warm: golden haze at the horizon, a touch of bloom on the Neon glow flower and shrine ball, slightly raised saturation. Output clean.
2. `/night`: over about 2.5 s the ambient falls to a blue night, the sun rays go, the glow ball blooms more and the tint cools. `/day` reverses it. With Reduced Motion on in Settings, the change snaps instead of tweening.
3. `/weather Rain`: grey, dense, desaturated haze with the sun rays off; `/weather Fog`: thicker grey haze; `/clear`: back to the warm look. `/shower`: a warm orange glow with strong bloom layered over the night look; `/shower end` returns to night or day.
4. World 2 place: cold blue-white light, hazier, flat saturation, soft sun. `/weather Blizzard`: near white-out haze (Density 0.6, Haze 6) and a strongly desaturated tint; `/weather Snow`: a lighter pale haze; `/clear` returns.
5. Screenshots for the review: each world at day, night and its special weather at iPhone SE size, into `docs/vault/05-ui-design/refs/look-l1/` (not committed until reviewed). Frame rate on the SE emulator stays above 50 with Future lighting; if not, lower ShadowSoftness or Bloom size in the data table, never in code.

A place file's own Atmosphere is removed and its other post-effects are switched off by the client on start (they fought the looks in the first Studio pass); a built place file (`rojo build`) carries Future lighting and the modern chat from the project files.

Known gaps in this milestone: skyboxes (six ids per world) are still 0 so the default sky stays; no per-biome variation inside a world; particles for rain and snow are pass L3.

## Milestone 23: the Friend Boost (World 1 place, multi-client)

Needs Studio's multi-client test with two accounts that are Roblox friends; with one client the chip reads +0%.
1. Boot lists Friends before Buffs. The HUD shows a "Friend Boost +0%" chip beside the luck line, dim at 0. Tap it: the native invite prompt (or the "Invites are not available right now" toast in Studio).
2. A friend joins the server: toast "<name> is here! Friend Boost +5%", the chip reads +5% and brightens, the luck line shows x1.1 (luck 1 + 0.05, rounded to one decimal; with pity it adds), station income per minute rises by 5% on the Ship screen, and a catch pays 5% more Scrap. Analytics prints FriendsInServer with value 1 for both players.
3. A third and fourth friend: +10%, +15%; a fifth friend stays at +15% (the cap of 3). A friend leaving: toast "Friend Boost +10%" and the numbers fall.
4. Non-friends joining change nothing. The friendship lookup failing (offline Studio) prints one warn and retries after 300 s, never spamming.
5. Daily quests: the "with a friend" objectives count catches while the chip is above +0% (the same friend check).

Known gaps in this milestone: no party or private-server bonus beyond friends present, the chip has no icon, and co-play analytics only record the friend count (party size and visits come with the home planet).

## Milestone 24: weather particles (Look pass L3, both places)

1. World 1, `/weather Rain`: within 1.5 s rain streaks fall around the player from a sheet above the camera, slanted slightly, and keep falling while walking (the sheet follows); `/clear` ramps them off over 1.5 s. `/weather Fog`: slow drifting pale wisps at ground level, few and large. Output clean; no sheet part is visible as geometry.
2. World 2: `/weather Snow`: large slow flakes drifting and spinning; `/weather Blizzard`: dense fast sideways flakes; `/clear` ends them. The Heater still reveals aliens as before (the sheet never blocks taps: CanQuery off).
3. The Meteor Shower sky sheet (milestone 11) still works alongside: `/shower` during Rain shows both.
4. Budget: Output prints one line per sheet with its rate x max lifetime (the on-screen count); none above 200. On the iPhone SE emulator frame rate stays above 50 under Blizzard; if not, lower the rate in data/Weather.luau, never in code.
5. Reduced Motion on: particles still run (they are weather, not motion), unchanged.

Known gaps in this milestone: default square particle textures until the icon pack (raindrop, flake, wisp sprites), no ground splash or snow cover, no sound change per weather.

## Milestone 25: size rolls (World 1 place)

1. Wild spawns carry a Size attribute (Tiny, Small, Normal, Big, Huge) and the rendered alien is scaled by the band (Huge reads clearly larger than its neighbours; Tiny clearly smaller); nameplates and tap targets follow the scale. Over about 50 spawns the mix is roughly 3 / 17 / 60 / 17 / 3 percent. `/spawn Mossbop huge` forces a band for testing (Dev: `/spawn <id> [band]`).
2. Catch a Big or Huge one: the Reveal stamps "HUGE Mossbop! x2 Scrap" (or "Big Mossbop! x1.25 Scrap") above the name with a bigger card pop, and the catch Scrap is multiplied (Huge x2, Big x1.25, Tiny x1.5 as a rare treat, Small and Normal x1). Normal and Small show no stamp.
3. The record keeps the band: the Aliens screen row shows a size chip for Tiny, Big and Huge, the worker at its station is drawn at the band's scale, and a rejoin keeps it. Old profiles migrate to Normal (schema v7).
4. Eggs and shop aliens (Peddler, gifts, Starter Pack) roll a size too, with the same odds, and the reveal stamps them the same way.
5. The server-wide catch banner is unchanged (size is not announced); analytics Catch keeps its three fields.

Known gaps in this milestone: no growth over time, no codex "biggest caught" line, no size-based Set or quest yet.

## Milestone 26: catch variants (World 1 place, Dev-forced)

Variants are rules laid over the one timing bar (`src/shared/data/CatchVariants.luau`): the zone centre drifts over the sweep, the scoring input is a tap or the release of a hold, the ticker speed scales, and the encounter can run on a clock. A world sets its own (`Worlds.catchVariant`: Tidepool Reel, Neon Grid Chase) and a species can override it; until those worlds exist, `/variant <id>` forces one for your player.

1. `/variant Reel`, then `/spawn Mossbop` and catch it: the bar opens with "Cast!", the Good zone is sky blue and the ticker yellow, and the zone bobs side to side (about one swing every 2.6 s) while the ticker runs slower than normal. The hint reads "Hold to reel, let go on the fish!"; pressing (mouse, touch, Space or A) swaps it to "Reeling... let go!" and the release is what scores. A release before the sweep starts is ignored, not a miss. The feedback shows the zone frozen where it was at the release, and the Reveal follows a win as usual.
2. `/variant Chase`, `/spawn Mossbop`, catch: "Chase!", the zone darts faster and wider, a chip above the right end of the bar counts down from 12 s and turns red for the last 3 s. Let it run out: "It bolted!", the alien disappears (server-removed as fled; Output shows the Flee analytics line), and the bar closes. Catch one inside the time: the usual catch.
3. `/variant off` (or `Standard`): the next catch is the plain bar, green zone, white ticker, "Tap to stop!", no chip, no drift.
4. Server authority: with Reel forced, a tap that lands outside the drifted zone is a Miss even if it is inside where the zone was at the sweep's start (the server scores against `Capture.driftCenter` at the tap time, and the result's `zoneAt` is where the client freezes the zone). Multi-round (`/spawn Gaiabloom` with Reel): each round rolls a new base centre and each sweep a new drift phase; the Warden shrink still applies.
5. Wild spawns carry a `Variant` attribute (Standard on World 1 and 2). Output stays clean through all of the above.

Known gaps in this milestone: no fish or rooftop presentation (the ticker is still a bar ticker), no double bar for the Cosmic deep-sea fish yet, no world layouts for Tidepool or Neon Grid, and no per-variant sounds.

## Milestone 27: the five-minute script (World 1 place, fresh profile)

Decision 18 as built: the first Welcome Week gift is the payoff of the first finished module, and the server-wide events that would pull a brand-new player off the loop stay quiet on their screen until the tutorial ends (`data/Tutorial.luau`, the `Script` block). The server's Peddler clock and Shower clock run as ever; this is presentation.

1. Play as a fresh profile (Studio memory profiles reset on Play). Crash opener, T1 plates, T2 Mossbop, T3 Hull Frame started, T4 Puffpuff, T5 three catches. Hull Frame assembly is 60 s in data, so the first module completes inside about four minutes of normal play.
2. When the Hull Frame completes (T6 done, T7 shows): the fanfare and camera pan play first, then a toast "First part built! A gift is waiting." and the Gifts screen opens by itself on the Day 1 tile; the tray's "Tomorrow: Twig Lure" line is visible. Claim it (300 Scrap). Close it: the T7 hint (Forest, Glowroot) is on the pill.
3. If a catch, a reveal or a panel is open at that moment, the pop waits up to 8 s for it to clear, then gives up quietly; the menu badge still shows the unclaimed gift.
4. Peddler hold: on a fresh server the Peddler lands 20 s after boot. During T1 to T7 no "Peddler landed" banner shows for this player (the ship still lands and the Trade prompt still works at its ramp). After T7 (or `/tutorial 8`), the next landing shows the banner.
5. Shower hold: `/shower` during the tutorial: the sky streaks and the luck apply, but no shower chip, banner or horn for this player. `/tutorial 8` mid-shower: the banner and chip appear at once without the horn. A second player past the tutorial sees everything as before.
6. A rejoin after the gift was claimed never re-opens the Gifts screen; the pop fires once per session at most.

Known gaps in this milestone: the story beats stay the two crash lines and the hints; `FirstModuleSeconds` lands in analytics but no in-game timer shows; no Catch Rush party beat yet.
