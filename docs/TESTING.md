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
5. With Hull Frame done, the Ship screen's row 2 (Thrusters) accepts Glowroot: collect 4, press "Add Glowroot", pay 2,000, and the module assembles (the World 1 numbers since the 2026-10-07 pacing retune; `data/Modules.luau` is the truth). Row 3 (Life Pod) then asks for Cave Crystal.
6. Wild aliens never spawn inside the camp clearance or on top of each other; a conditional spawn (Buzzlebee, Thunderhog, Lanternewt, Gloomoth) despawns when its condition ends.
7. Check the biome chip does not collide with the clock chip or toasts at iPhone SE and iPad sizes.

Known gaps in this milestone: the Warden's Core (quest) is not obtainable, so the Engine Core cannot be built yet; no lures, Peddler or tutorial; placeholder art.

## Milestone 5: menu stack, Aliens screen, Codex screen, Nearby panel

1. Press Play. Down the left edge sit four square buttons with labels: Shop (green, "$"), Aliens (gold, "A"), Codex (purple, "?"), Ship (blue, "^"). Shop shows a "Coming soon" toast. The other three open their panels; tapping another menu button while a panel is open switches panels in one tap (the menu sits above the dim); while any panel is open the Catch!/Collect/Build button is hidden and Space does not start a catch. (Automation note: open panels by clicking the buttons with the MCP mouse; `require`-ing Screens from execute_luau gets a separate module instance and does nothing.)
2. Aliens: with nothing caught the panel reads "Catch an alien and it will work here" under three station cards (Picnic Table 0/1, Treehouse Bench 0/1, Glow Flower 0/1, each with one open slot and two locked squares). Catch two aliens: cards appear sorted by speed with a rarity-coloured frame, speed chip "x1" or "x1.6", and "Picnic Table" (where it works) or "Resting". The station card fills and shows "+60/min". Optimize re-sorts.
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
2. Catch it: the pill reads "Mossbop is gathering for you. Walk to the ship, pay for the Hull Frame and add your 3 wreck plates." with the marker on the ship. Pay 300 Scrap (first-catch bonus plus income gets there in about two minutes; `/scrap 300` to skip) and tap Add Wreck Plate: the module starts and the pill reads "Puffpuff wants to help! Catch it and it will build." and a Puffpuff waits at the same spot.
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
3. Module complete: build the Hull Frame (plates, `/scrap 300`, Pay and Add). On completion a green burst plus gold sparkles rise over the ship, the camera glides to look at the ship for about 2.5 s, rests 1.2 s and glides back, and the usual "Hull Frame complete!" toast shows. If a capture starts or a panel is open at that moment the pan is skipped (or cancelled). The camera always returns to the character with normal control.
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
1. Boot adds Analytics (right after PlayerData) and Settings (after Gifts) lines: `server started: PlayerData, Analytics, WorldClock, ..., Gifts, Settings, Dev`, with "Analytics: Studio print mode" (Studio never sends; it prints each event) and "Settings: 4 preferences". A round blue "=" button sits left of the clock chip at the top right; it hides with the HUD during the crash opener and comes back.
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

Decision 17 (2026-10-06): `/pass SlotEveryStation1` then finish the Thrusters: every station reads 3 slots (2 unlocked + 1 bought), the Aliens screen station card shows a fourth square after the Nav Array (3 + 1), and the bought slot survives a rejoin. Known gap: at four slots the slot squares truncate long names ("Mossbo").

Known gaps in this milestone: hoverboard skins (no hoverboard yet), the Home tab, direct-buy aliens, paid spins (P1, with the compliance pass), real-currency equivalents under prices (needs Roblox's regional pricing data), offers that appear at a moment ("all slots full", "shower in under 5 minutes").

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
2. When the Hull Frame completes (T6 done, T7 shows): the fanfare and camera pan play first, then the Gifts screen opens by itself on the Day 1 tile with nothing over it; the tray's "Tomorrow: Twig Lure" line is visible. Claim it (300 Scrap). Close it: the T7 hint (Forest, Glowroot) is on the pill.
3. If a catch, a reveal or a panel is open at that moment, the pop waits up to 8 s for it to clear, then gives up quietly; the menu badge still shows the unclaimed gift.
4. Peddler hold: on a fresh server the Peddler lands 20 s after boot. During T1 to T7 no "Peddler landed" banner shows for this player (the ship still lands and the Trade prompt still works at its ramp). After T7 (or `/tutorial 8`), the next landing shows the banner.
5. Shower hold: `/shower` during the tutorial: the sky streaks and the luck apply, but no shower chip, banner or horn for this player. `/tutorial 8` mid-shower: the banner and chip appear at once without the horn. A second player past the tutorial sees everything as before.
6. A rejoin after the gift was claimed never re-opens the Gifts screen; the pop fires once per session at most.

Known gaps in this milestone: the story beats stay the two crash lines and the hints; `FirstModuleSeconds` lands in analytics but no in-game timer shows; no Catch Rush party beat yet.

## Milestone 28: growth stages (World 1 place)

Aliens at a station grow Hatchling to Grown (2 h worked) to Elder (24 h worked), each a visible size step and a work-speed bump (`data/Growth.luau`). Time counts only while seated; time away counts for the aliens seated at leave, capped like offline Scrap. Profiles migrate to schema v8 (worked time 0).

1. Catch three aliens so two are seated. On the Aliens screen a seated alien's card shows a white "2h" chip mid-right (the work time to its next stage) that counts down as it works ("1h", then "59m" and under); a resting Hatchling shows no chip on the right.
2. `/grow 2`: a toast "Mossbop grew up: Grown!" per seated alien (and Output's dev line names 2 crossings), each worker at the camp pops and stands a little taller, the Aliens screen shows a sky-blue "Grown" chip on the right of those cards and the station rate rose by 10% for each (Ship screen or HUD rate). The resting alien is unchanged.
3. `/grow 22`: "Elder!" toasts, the chip reads "Elder" in sky blue (no stage ahead, so no countdown), workers 16% taller than a Hatchling, the rate bump is 25%.
4. Seat the resting alien and `/grow 1`: no crossing yet (one hour of two); its chip reads "1h" (never "60m").
5. Rejoin after the server has run for over a minute with aliens seated: the welcome-back toast still reports Scrap; with `Config.UseDataStoreInStudio` off nothing persists, so the away-time growth and the "N of your aliens grew while you were away!" line need a real save (Ethan's Studio API access) to verify; note it as untested otherwise.
6. Output stays clean through all of the above; no stage chip or line shows for an alien from before growth until it works (migration sets 0).

Known gaps in this milestone: no growth analytics event, no codex "Elder" mark, the model itself does not change shape between stages (scale only).

## Milestone 29: hero landmarks (both places, after the colour re-upload)

Hero set pieces are placed from each layout's `Landmarks` list (`data/Meadow.luau`, `data/Frostbyte.luau`) when their prop exists under `ReplicatedStorage.Models.Props`; nothing is built for a missing one, so a place without the imports looks as before.

1. World 1 without the hero props imported: the world builds exactly as before (same scatter, same shrine ring); Output prints one line naming the landmarks that were skipped.
2. World 1 with the props installed: the CrashWreck lies beside the camp pad (x 24, z −10) with its scorched disc on the ground and the ember slots glowing; the CaveMouth stands just outside the Cave rim on the camp side (x −82, z −75), arch facing the camp (if it faces away, the yaw in data is off by 180 and that is a data fix); no rock or tree overlaps either (scatter keeps `clearRadius`); the Shrine is the hero model (paving, monoliths, moss, glow) with the old stone ring and glow ball gone, and the Field Notes horn still works at it (the pedestal anchor and its LandmarkId stay).
3. World 2 with the props installed: the GeyserVent sits at the Geyser Field's centre with the cones scattered around it (none inside its clearance), the IceCaveMouth outside the Ice Cave rim facing the camp; the World 2 shrine keeps its pale stone ring (no hero shrine there).
4. Output clean on both; the landmark line reads "placed N of M".

Known gaps in this milestone: no placeholder for a missing hero, no client waypoint to the wreck or the mouths yet (their LandmarkIds are set for that), no terrain blending under the pieces (L2).

## Milestone 30: the compass strip (World 1 place, then World 2)

A thin band at the top centre of the HUD (`data/Compass.luau`): cardinal letters and ticks that slide as you turn, the heading in a small pill, a coloured diamond per marker in front of you, and one line under it naming the marker you are heading for with its distance. The ship bar and everything stacked under it moved down to make room; the Scrap pill and the clock chip did not.

1. On spawn the strip shows N/E/S/W sliding as the camera turns, the heading pill counts 0 to 359 in the same sense as the Radar's north, and the ship bar sits just under the strip with the luck line, the event banner slot and the Friend Boost chip stacked below as before (nothing overlaps; the Scrap pill and the clock chip are where they were).
2. Walk away from the camp: past 30 studs a green diamond for the camp appears at its bearing and the line reads "Camp 42m" (the number falling as you walk back); within 30 studs it hides. The gold Shrine diamond shows from 20 studs out with "Shrine 155m" when it is the nearest or highest-priority marker.
3. Tutorial running: the gold waypoint diamond points at the marker's target and the line uses the waypoint's own label ("Wreck Plate 18m"); it beats the camp. Tap a radar blip (Radar Mk1): a sky-blue Target diamond appears and the line reads "Target 61m" until you reach it.
4. `/shower` or any time the Peddler lands: a gold Peddler diamond from 14 studs out, "Peddler 48m". Turn until a marker leaves the field of view (90° to a side): it fades near the edge and disappears past it.
5. World 2 place: the Great Vent diamond (red) and the Ice Cave diamond (purple) show once the hero props are imported (they read LandmarkIds); without them, no diamond and no error. The crash opener, a capture and a Reveal hide the strip with the rest of the HUD.
6. iPhone SE emulator: the strip, its letters and the heading pill are readable and the line under it does not collide with the ship bar. Output clean.

Known gaps in this milestone: no marker icons (diamonds only), no event marker for a Meteor Shower (it has no position), no tap on a diamond to set a waypoint yet.

## Milestone 31: the icon pack (World 1 place; before and after the image upload)

The 48 icons and 3 particle sprites rendered from Blender (`assets/icons`, `assets/particles`) are keyed in `data/Icons.luau`; `tools/upload_assets.py --images` uploads them as Decals and `--emit-icons-luau` fills the ids in. Every id is 0 until then, and the UI must look exactly as it did.

1. With the ids at 0: the menu stack and the round top buttons show their glyph letters, the Scrap pill its colour square, the shower banner its purple square, rain and snow their default sparkle particles. Output clean.
2. `python3 tools/upload_assets.py --images --dry-run` lists 51 PNGs; `--images` uploads them (Decals), writes `assets/icons/asset_ids.json`; `--images --emit-icons-luau` prints the two tables, which replace the ones in `src/shared/data/Icons.luau`; analyze clean; commit both files.
3. With the ids in: the six menu buttons show the price tag, alien face, book, rocket, scroll and gift box icons at 70% of the face, the Settings gear and the Ranks podium on the top buttons, the gear-cog coin in the Scrap pill, the meteor on the shower banner's left square; every button still presses, hovers and opens its panel; the letters are gone.
4. `/weather Rain` then `/weather Snow` (World 2 for Snow and Blizzard): drops are soft vertical streaks, flakes six-point flakes, fog wisps soft blobs; the counts and speeds are unchanged (the data numbers did not move).
5. iPhone SE emulator: the icons stay crisp and centred on the buttons; nothing clips.

Known gaps in this milestone: the material, gear, rarity, power-up and lure icons are uploaded but not yet placed (toasts, nodes, cards and the shop rows come next); no Glider or JetBoost icon; the server luck banner has no icon.

## Milestone 32: icons on the remaining surfaces (World 1 place, after the image upload)

With the ids in (`data/Icons.luau` filled by `--images --emit-icons-luau`):

1. Power-ups row: each square shows its power-up icon (bolt, target, pulse, clover, magnet, clock) instead of a letter; the count badge and the timer ring still work.
2. Shop, Lures and Gear pages: each row has its item's icon at the left (the three lures, the boots, the hoverboard, the radars); the Robux rows have none and look as before.
3. Gifts: the tiles carry a small reward icon top-right (coin, lure, power-up, the Epic badge on Day 7); claiming re-renders without stacking.
4. Catch a Rare: the Reveal shows the blue triangle badge left of "Rare"; a Common shows the grey circle.
5. Walk to a Wreck Plate node: its nameplate shows the plate icon left of the name; collect it: the "+1 Wreck Plate" toast carries the same icon; use a Speed Burst: the "Speed Burst on!" toast carries the bolt.
6. With every id at 0 (before the upload) none of the above shows and nothing moved: letters, plain rows, plain tiles, plain toasts. Output clean in both states.

Known gaps in this milestone: no icons on the Aliens and Codex cards, the Quests reward lines, the Peddler offers or the Star Chart yet; the clock chip has no weather icon.

## Milestone 33: the VFX pass (World 1 place; sprites optional)

Catch bursts, module bursts, meteor streaks and the Peddler's dust take the soft sprites (`data/Icons.luau` Particles) once uploaded; the Reveal gets rotating sunburst rays behind the card and sprite confetti; a Perfect catch flashes white; a Rare or better wild spawn carries a tier-coloured point light and a breathing glow sprite (`Tiers.aura`). With every sprite id at 0 the emitters keep the default particle, the rays and sprite confetti are skipped (frame confetti stays), and only the light and the flash are new.

1. `/spawn Sparkfox` (Rare): a blue light on it at night and a soft glow that breathes about every 1.6 s; `/spawn Thunderhog` (Epic) brighter and purple; `/spawn Mossbop` nothing. Blizzard-hidden or reserved-for-another spawns carry no glow. 50 spawns on screen stay above 50 fps on the SE emulator.
2. Catch with a Perfect: a quick white flash (0.35 s) before the Reveal; a Good hit: none. Reduced Motion on: no flash, no rays, confetti as before.
3. With the sprite ids in: the catch burst is sparkles and one expanding ring in the tier colour, the module burst stars and glow, the shower streaks real streaks, the dust soft wisps; the Reveal shows slow sunburst rays behind the card in the tier colour and confetti pieces are the sprite.
4. Output clean; no sprite part is visible as geometry.

Known gaps in this milestone: no hoverboard trail, no screen-edge glow for a Legendary, no sound change with the effects.

## Milestone 34: the Catch Rush (World 1 place, multi-client where noted)

A 90-second shared round every 10 minutes on the wall clock (`data/CatchRush.luau`): every wild catch counts, the top three are paid by rank, anyone else with a catch gets a participation payout, the winner is announced to the server. A round that would start during a Meteor Shower is skipped.

1. `/rush in 40`: the countdown chip under the clock reads "Rush in 40s" (the shower's chip wins if both are due) and counts down; at zero a gold banner "Catch Rush!" and the event banner slot reads "Catch Rush!" over "1m 30s left" with a chip "You 0 · Top 0".
2. Catch three aliens during the round: the chip climbs to "You 3 · Top 3" within a second of each catch (one push per second at most). `/rush end`: toast "Catch Rush over!", then "Catch Rush: #1 with 3 catches! 500 Scrap, 1 free spin" (one catch reads "1 catch") and the server-wide banner "<you> won the Catch Rush with 3 catches!"; Scrap and the spin land (Gifts screen); Output shows `analytics: event CatchRush value=3 rank=1`.
3. A round with no catch: at its end the toast reads "Catch Rush over: catch one next time!" and nothing is paid.
4. Multi-client (Test > Clients and Servers, 2 players): both see the same clock and chip; player A catches 2, player B 3: B's banner says #1 and A's says #2 with 300 Scrap; ties rank the earlier count first.
5. `/shower` then `/rush`: the shower keeps the banner slot and the rush still counts underneath (the chip shows the rush after `/shower end`); on the live clock a rush whose start falls inside a shower is skipped (Output prints one line).
6. Tutorial running: no rush banner or chip until it ends (the same hold as the shower); the rush still counts. Use a profile that has not done the tutorial's deeds (a fresh test user in the multi-client test): `/tutorial 1` on a finished profile skips every step it already satisfies and lands past the end, and Output prints the step reached ("asked for tutorial step 1 and is on step 8").
7. Output clean; a late joiner (second client) during a round sees the banner and the right counts at once.

Known gaps in this milestone: no cosmetic prize yet (Scrap and a spin instead), no Rush history or best-score line, no sound for the start; the countdown chip does not know a slot will be skipped for a shower (it counts to a start that then does not happen); a player who leaves mid-round is dropped from the table.

## Milestone 35: fusion (World 1 place)

Four spare copies of a species fuse into +1 level on the best copy, up to Lv 3 (`data/Fusion.luau`); the level multiplies work speed by `Config.LevelSpeedStep` per level. Surplus always has a destination.

1. Catch one Mossbop, then `/dupes Mossbop 4`: the Aliens screen shows five Mossbop cards and a gold "Fuse" button beside Optimize with the hint "4 spare copies of a species fuse into +1 level (up to Lv 3)". Tap Fuse: toast "Mossbop fused to Lv 2!", one Mossbop card remains with a gold "Lv 2" chip and a speed chip of x1.4 (x1.35 per level over the Common's x1), the station rate rose; Output `analytics: event Fuse value=2 species=Mossbop`.
2. `/dupes Mossbop 8`, Fuse: two fusions in a row (toasts Lv 2 then Lv 3, then nothing more) and the kept copy is the best (a Shiny or a Huge is never consumed while a plain Normal is); the Lv 3 and the last plain copy remain. A copy above the kept one is never fodder: with the Lv 3 and four plain copies, Fuse says "Nothing to fuse yet: keep 4 spare copies of one species" and the plain copies stay (a fifth plain copy would fuse a second Lv 2). A seated copy stays seated unless only seated copies remain; the freed slots refill.
3. Tap Fuse with nothing eligible: "Nothing to fuse yet: keep 4 spare copies of one species". `/dupes Puffpuff 3` (four copies total): still nothing (a fusion needs five).
4. A Lv 3 copy with four more spares: Fuse shows "Nothing to fuse yet: keep 4 spare copies of one species" for it (the Lv 3 is not fodder and four plain copies are one short); with five spares it fuses a second Lv 2 and the Lv 3 is untouched.
5. Rejoin: the level and the chip persist (memory profiles in Studio; a real save keeps it the same way, no schema change: `level` existed).
6. Output clean; the Codex count for Mossbop is unchanged by fusing (it counts catches).

Known gaps in this milestone: no fusion animation on the camp, no choice of which copy to keep (the best is kept), no fusion quest or daily objective yet.

## Milestone 36: companions (World 1 place; step 5 multi-client)

Up to three resting aliens follow the player (`data/Companions.luau`), drawn behind the character for everyone, each giving one perk by its first job scaled by tier (Gather: catch Scrap, Build: wider zones, Spark: luck). The +1 companion pass and Companion Tokens from the spin wheel add slots, up to five.

1. Catch four aliens so one rests, open Aliens: the header reads "Companions 0/3" and "Perks: none yet"; the resting card's status reads "Tap to follow". Tap it: toast "Mossbop is following you", the status becomes "Following", the header "Companions 1/3" and "Perks: +10% catch Scrap"; a Mossbop walks behind your character, stays on the ground, turns with you and bobs; after a long jump or `/world` it catches up or snaps. Output `analytics: event Companion value=1 action=follow species=Mossbop`.
2. Tap a working alien's card: "Puffpuff is working; pick a resting alien" and no request. `/follow Sparkfox` (Rare, Build): "Perks: +10% catch Scrap, +15% zone" and the capture bar's zones are visibly wider on the next catch; a Spark companion lifts the HUD luck readout.
3. Fill three slots then tap a fourth resting alien: "All 3 companion slots are taken". `/token`, then the footer shows "Use Token (1)"; tap it: "Companion slot unlocked: 4", a fourth follows. `/pass CompanionSlot4`: the header reads 5 slots (the cap).
4. Tap a following card: "Mossbop stays at camp", it stops following; Optimize never seats a companion (its station stays Resting); fusing consumes a companion only when it is among the worst copies and it then vanishes from the followers.
5. Multi-client (Test > Clients and Servers): player B sees A's companions walking behind A with name plates (no tier line); when A leaves, they vanish for B; a late-joining C sees them at once. Beyond 120 studs from the camera the followers of others are not drawn; 50 wild spawns plus companions stay above 50 fps on the SE emulator.
6. Rejoin: the companions still follow (memory profiles in Studio; schema v9 adds `companionSlots`). Output clean.

Known gaps in this milestone: no mount riding yet (section 6 of the design: rideable Epics), no radar perk reader (Tinker is a World 3 job), no companion animations beyond the bob.

## Milestone 37: mounts (World 1 place; step 5 multi-client)

A species with a `ride` traversal (`data/Species.luau`: Thunderhog, Gaiabloom, Radish, Frostfang, Skaddle, Fenripup) can be ridden once it follows the player (`data/Mounts.luau`): the rider is lifted onto it, moves at the tier's speed (Epic 1.6x like the Hoverboard, Legendary 1.92x, Cosmic 2.24x) and jumps by the traversal (Sprint 1.6x, Hover 1.2x). The mount keeps its companion slot and perk. Dev: `/ride <speciesId|off>` (follows a resting copy first if needed).

1. `/spawn Thunderhog`, catch it, open Aliens: its card reads "Tap to follow" and shows no Ride button; tap it ("Thunderhog is following you") and a Featured "Ride" button appears on the card. Tap Ride: toast "Riding Thunderhog!", the status reads "Riding", the button reads "Hop off"; in the world your character sits on the Thunderhog (feet about 2.2 studs higher), it stays under you as you walk and turn, and the other followers keep their arc behind you. Output: `analytics: event Mount value=1 action=mount species=Thunderhog traversal=Sprint`.
2. Walk and jump: WalkSpeed reads 25.6 (16 x 1.6; `game.Players.LocalPlayer.Character.Humanoid.WalkSpeed` in the command bar) and the jump is visibly higher (JumpPower 80 or JumpHeight 11.52). Hop off: toast "You hop off Thunderhog", speed and jump back to normal, hips back down, the Thunderhog rejoins the arc. Mount again, then tap the card (not the button): you hop off first; a second tap stops it following.
3. Speed Boots owned plus a mount: the mount wins (25.6, not 20); with the Hoverboard owned and an Epic mount both read 25.6; `/ride Gaiabloom` after `/spawn Gaiabloom` and a catch: 30.72. A Speed Burst on top multiplies as before.
4. A non-rideable follower's card (Mossbop) never shows Ride. Fusing away the mount (`/dupes` on its species then Fuse while riding a plain copy) or unfollowing it from the card dismounts you cleanly (speed, jump and hips restored). `/world 2` and back: still riding, still on the mount.
5. Multi-client: player B sees A sitting on the mount with no name plate on the mount, and A's other followers behind; A hops off: the mount walks back into the arc for B too.
6. Rejoin: back on foot (riding is not saved; the mount still follows). Output clean.

Known gaps in this milestone: no riding animation (the rider keeps the walk animation), no saddle cosmetics, Hover has no slow terrain to ignore yet, Glide, Swim and Climb are placeholders for later worlds.

## Milestone 38: the weekly drop (World 1 place; step 6 on World 2)

Every week on the leaderboard's Friday 16:00 UTC clock (`data/Weekly.luau`, `Shared/WeeklyMath`) one species is the Alien of the Week: a limited one (Panpipe, week 1 of the rotation) spawns only in its week and reads "Vaulted" in the Codex otherwise; a featured one (Gloomoth, week 2) is boosted everywhere in its world. A drop may hold a themed weather all week (Aurora) and a week-only overlay (Spectral, x2) then rolls on wild spawns. Dev: `/week <N|next|off>` shifts the rotation by whole weeks for this server.

1. Boot: Output prints the week ("Weekly: week 2026-10-09, drop 1 Panpipe, Aurora") and the HUD event banner slot (when no shower, rush or server luck runs) reads "Alien of the Week" over "Panpipe · 6d 23h left" with a chip "Aurora" (on a world the drop is not on, the chip names that world instead: "Frostbyte"); the sky is tinted green-violet with slow glowing wisps, strongest at night (`/night`), and the clock's weather reads Aurora between rain showers (`/rain` still works and the Aurora returns when the rain ends on its own; `/clear` forces Clear until the next roll, then the Aurora is back). A banner "Alien of the Week: Panpipe! Aurora skies all week" shows once at join.
2. Codex: Panpipe's cell carries a "This week" stamp; its detail reads "Alien of the Week: 6d 23h left". `/week next`: Output prints the flip, the banner names Gloomoth with no chip, the sky returns to the usual weather, Panpipe's cell reads "Vaulted" and its detail "Vaulted: back in a later week"; Gloomoth's cell reads "This week".
3. Spawns: on week 1 (`/week 0`) about 1 wild spawn in 20 is a Panpipe in any Meadow, Forest or Cave spot (count 60 spawns with `/spawn` excluded: walk the biomes and tally); catch one: the reveal, the codex entry and the camp all work as for any Secret (catch chance 100%, three rounds). About 3 in 100 wild spawns carry the Spectral overlay while the Aurora runs (the reveal's overlay badge reads "Spectral", the announcement "<you> caught a Spectral Secret Panpipe!"); none after `/week next`.
4. Featured week (`/week 1`): Gloomoth spawns by day in the Meadow too (about 1 in 20); its codex stamp reads "This week" and no Vaulted stamp exists for it after `/week next` (it is not limited).
5. `/week off`: the real week again; the banner and stamps follow. A shower, rush or server luck still takes the banner slot over the weekly line and gives it back after.
6. World 2 (`/world 2`): the Aurora holds there too in week 1, and week 3 features Shimmerlynx on World 2 only (`/week 2`: Shimmerlynx spawns boosted on World 2, nothing extra on World 1). Output clean.

Known gaps in this milestone: no hosted Shower Storm or developer panel yet (MessagingService, a later card), the weekly species is drawn from the existing roster until new weekly models exist, one themed weather (Aurora) so far.

## Milestone 39: Warden sightings (World 1 place; step 5 on World 2)

Every 20 minutes on the server clock (`data/Sightings.luau`) the world's Warden walks a loop of the map in the open: from the shrine, between the camp and the Forest, past the wreck, by the Cave mouth and back, at 8 studs a second (about 80 s), leaving a trail of glowing puffs (flowers on World 1, frost on World 2). It cannot be caught or marked; a banner opens it and a toast closes it; the compass points at it while it walks if nothing else is marked. Dev: `/sighting [end]`.

1. `/sighting`: a server-wide banner "Gaiabloom is crossing the land! Go and see" with the Warden horn sound; the compass line reads "Warden 150m" (when no radar target or waypoint is set) and a Legendary-coloured diamond tracks it; Output `analytics: event Sighting value=1 species=Gaiabloom`. Walk to it: the Gaiabloom mesh (placeholder if not installed) at 1.3x walks the floor smoothly, turns toward its travel, and leaves pink puffs every 3 studs that glow and fade over 20 s. Its name plate reads "Gaiabloom" with no tier line.
2. Uncatchable: no capture prompt near it, the Nearby panel and the radar ignore it, a tap on it does nothing, and the capture bar never opens. The wild spawns around it carry on.
3. At the end of the loop (about 80 s) the part goes, the toast "Gaiabloom has wandered off" shows, the compass marker clears, the trail fades on its own. `/sighting end` mid-walk does the same at once.
4. The tutorial hold: on a fresh profile under the tutorial, `/sighting` shows no banner and no toast (the Warden still walks). A shower banner keeps its slot; the sighting is a banner and a compass marker only, never the event slot.
5. `/world 2`, `/sighting`: Skaddle walks the same loop over Frostbyte with frost-blue puffs. A sighting that was running when you arrived is drawn from its current point (late join). Output clean.

Known gaps in this milestone: no walk animation (the mesh glides with a bob), no camera pull, the Warden walks through props on its path (the points keep clear of the landmarks and the camp).

## Milestone 40: Radar Mk2 (World 1 place)

Radar Mk2 (`data/Radar.luau`, 8,000 Scrap once World 2 is unlocked, or `/radar 2`): the disc reaches 250 studs; a Secret-tier alien in range shows as a pulsing "???" ping with a heartbeat that quickens as you near it (Mk1 shows nothing for a secret); the Nearby panel lists up to three rares of this biome that are not out right now, dimmed, with the condition they need. Mk3 stays locked.

1. Shop > Gear with only World 1 unlocked: a "Radar Mk2" row reads "Unlocks with World 2", grey; after `/world 2` and back (two worlds unlocked) and with Mk1 owned it is buyable at 8,000 Scrap ("Aliens within 250m, secrets as ???, and who appears when"); without Mk1 the server refuses (Locked) and the toast says so. Buy it: the disc's ring reads 125m, blips appear out to 250 studs, `analytics: event ShopBuy kind=gear id=Radar2`.
2. `/week off` (Panpipe week), find a Panpipe within range (or `/spawn Panpipe`): the disc shows a white "???" ping that swells on each beat; the heartbeat beats every 1.2 s at the edge and every 0.4 s within 20 studs (count the ping's swells; the sound slot plays once its id is set); on Mk1 (`/radar 1` on a fresh profile) the same Panpipe shows no blip at all. Tap the ping: it marks the spot like any blip.
3. On Mk2 the Nearby column comes back under the disc in a compact form titled "not now": no icons, one two-line entry per Rare-plus species of this biome under a condition not active now (the name, then "in the rain" under it in blue), as many as fit (one on an iPhone SE, three on an iPad), at most three; in the Meadow by day that is Thunderhog; `/rain` removes it (it is out now, so the disc shows it); with nothing absent the column hides. On Mk1 the column stays hidden as before.
4. `/radar 3`: refused with a print that Mk3 is not in the game yet (no buy rule). Rejoin: the tier persists (memory profiles in Studio). Output clean.

Known gaps in this milestone: no hidden spots yet (none are built in the worlds), the heartbeat and ping sounds are placeholder ids, Mk3's shower preview and overlay glint wait on World 3.

## Milestone 41: the developer panel (World 1 place; step 4 multi-server needs a published game)

Commands the team's accounts (`data/Admin.luau` DeveloperUserIds) can type in any server, sent to every server through MessagingService: `/admin luck [bonus] [minutes]` (a gifted luck window, like a bought Server Luck, named "the team"), `/admin shower` (a Meteor Shower now), `/admin weather <state>` (this world's weather now), `/admin say <text>` (a banner to everyone, 80 characters). A server that cannot publish (Studio without API access) applies the command to itself. The guard is the user id, not Studio; `/admin` from anyone else does nothing and prints nothing.

1. Studio, your user id in DeveloperUserIds (Ethan's is in the data): `/admin luck`: a banner "3x luck for everyone, from the team!", the event slot reads "3x luck for everyone" over "10m 0s left" with the chip "x3.0", counting down, the HUD luck rises by 2.0, Output `analytics: event Admin value=1 action=luck by=<id>` and a line that the publish failed and the command was applied locally. `/admin luck 1 2`: the running x3 window keeps its bonus and gains two minutes (a smaller bonus extends the window, as for bought luck); on its own it would be x2 for 2 minutes.
2. `/admin shower`: a shower starts now with its banner; `/admin weather Rain`: the clock reads Rain; `/admin say Hello from the team`: a purple banner "Hello from the team" to every client, once (the line goes through Roblox's text filter first; in Studio without API access the filter passes the text through); a 100-character line is cut to 80.
3. Your id removed from DeveloperUserIds (or another test user): `/admin say x` does nothing, no print, no analytics. Seven `/admin say` lines inside a minute: the seventh is dropped (CommandsPerMinute).
4. Published game, two servers (Ethan): `/admin say` in one server reaches the other within a few seconds; a luck window shows in both; the message is ignored by a server that receives it more than 30 s late (replay guard). Output clean.

Known gaps in this milestone: no web dashboard (chat commands only), no scheduled hosted Shower (the team types it at the time), no per-world targeting (every server of every world applies it).

## Milestone 42a: the home place (home.project.json; World 1 place for the unlock)

The home planet is world 0, its own place (`home.project.json`, WorldId 0; `data/Home.luau`, `data/Worlds.luau` row 0): a small floor with the camp pad and the plot square, no spawns, nodes, shrine, Field Notes, Peddler, sightings, weekly share or launches; the ship and the stations work there. It unlocks on the first launch (profile `home.unlocked`, schema v10; a save that had launched already owns it on migration) and the Star Chart gains a Home planet to fly to and back. Dev: `/world 0` sets the current world to home.

1. World 1 place: open the Star Chart before any launch: a "Home" planet sits at the map's centre, grey, with "Launch once to unlock your home". `/complete` then launch: the toast "Your home planet is yours! Find it on the Star Chart" shows after the launch toast; `/world 1` back; the Star Chart's Home now reads "Your own planet. The ship and the stations work here too." with a Fly button; Fly: the "Flying to Home Planet..." toast and, in Studio, the "not published yet; your ship is logged there" line as for a world (no teleport; the place stays World 1, so the biome chip keeps "Meadow"). Output: `analytics: event Fly value=1 from=1 to=0`.
2. Home place (`rojo serve home.project.json`, connect, Play with a profile on world 0 via `/world 0` on World 1 first, or a fresh profile with `/world 0`): the floor is small and pale blue with the camp pad, the ship and the stations; a sand-coloured plot square sits past the pad on +Z (6 by 6 cells of 4 studs); no wild aliens ever spawn, no nodes, no shrine, no Peddler landing, no sightings (`/sighting` prints that this world has none), the weekly banner names the drop's world ("Panpipe on World 1 · 6d 23h left"), the biome chip reads "Home", `/rain` and `/night` still work (lighting only). The ship's action at home reads Build, not Launch (a launch there is refused with NoNextWorld), the Ship screen's "walk to the ship and launch" hint stays off, and the HUD ship bar reads 0% (the home has no modules; a later part hides it); Fly back to World 1 works from the Star Chart.
3. Stations at home: seated aliens keep earning (Scrap/min on the HUD), offline earnings settle on a rejoin as on any world; companions follow and mounts ride as elsewhere.
4. A profile below schema v10 (memory profiles start at the current version; skip unless real saves are on): one with two unlocked worlds migrates with `home.unlocked = true`. Output clean on both places.

Known gaps in this milestone: the house grid comes in 42b, habitats, the hangar, the kiosk, the mailbox and visiting in 42c to 42e; the home has no look pass yet (a plain floor).

## Milestone 42b: the house grid (home place, `home.project.json`)

Rooms and furniture (`data/HomeBuild.luau`) go on the plot's 6 by 6 cells for Scrap: walk to the plot, the action button reads "Decorate" and opens a tray; pick an item, a ghost follows your tap on the plot, Turn rotates it a quarter, a tap places it (the server pays and saves it, schema v11); Take away removes a placed item (no refund). Caps: 4 rooms, 12 things.

1. At the plot with 1,000 Scrap (`/scrap 1000`): "Decorate" within 18 studs of the plot's centre; the tray lists Rooms (Cabin 300, Dome 450, Tower 350) and Things (Bench 60, Lamp 80, Planter 50, Fountain 250, Flag 40) with "Rooms: 0/4" and "Things: 0/12". Pick Cabin: the hint reads "Tap a spot on the plot to place it", a half-transparent 2x2-cell ghost snaps to the cell under your tap (its low corner; a tap on the floor off the plot leaves the ghost where it is); a cell where the item would overhang the edge says "Keep it on the plot" when placed; Turn: the ghost rotates a quarter (a fresh pick starts unturned); tap a free spot: toast "Cabin placed", Scrap 700, "Rooms: 1/4", a cabin (prop or tan block, 6 studs tall) stands on those cells; Output `analytics: event HomePlace value=300 item=RoomCabin`.
2. Overlap: pick Bench and tap a cabin cell: "That spot is taken", nothing paid. Place a Bench beside it (60): "Things: 1/12". Spend down to 20 Scrap and pick Flag (40): the card is grey and a tap on the plot says Not enough Scrap. Place 4 rooms: "Rooms: 4/4" turns red, every room card goes grey, and a tap on one says "No room for more Rooms". The tray sits bottom right, clear of the menu column on the left.
3. Take away: tap a placed bench: "Bench taken away", the cell is free, Scrap unchanged (no refund), "Things: 0/12". Done closes the tray; the action button returns.
4. Rejoin (memory profiles in Studio): everything placed is drawn again from the profile on load. On World 1 the Decorate action never appears (no plot) and the remotes refuse (NotAtHome). Output clean.
5. The build camera (added 2026-10-07 after D2's missing ghost: the tray swallows taps on its own area, and a plot low in the view sat behind it). Stand anywhere within reach of the plot and open the tray: the camera glides (about 0.6 s) to look down on the plot from the side it stood on, and the whole sand square shows above the tray and its title tab, at iPhone SE and iPad sizes in the device emulator and in a small multi-client window. Pick Verdant Habitat (or Cabin) and tap a free cell: the ghost appears. Done: the camera glides back behind the character and the mouse steers it again. Open the tray and start walking: the camera stays on the plot until Done. Reduced motion on: both glides take half as long.

Known gaps in this milestone: no plot upgrade yet (the caps and the 6 by 6 plot are fixed), items have placeholder shapes until their props exist, no doors or interiors (rooms are solid prefabs), visitors do not see a house until 42e.

## Milestone 42c: habitats (home place; the display from the Aliens screen)

A habitat is a house-grid item of its own kind (`data/HomeBuild`: Verdant Habitat 600, Frostbyte Habitat 800, 3 by 3 cells, 3 aliens each, two habitats at once) where resting aliens of that world go on display (`data/Habitats`): they roam inside for everyone to see and pay Scrap per hour by tier, lazily, settled when the player arrives home (capped at a day). A displayed alien is never seated and never follows.

1. At home with a Verdant Habitat placed (the tray's Habitats row; "Habitats: 1/2"): the plot shows a green pad with a low fence ring. Open Aliens: a resting Mossbop's card shows a "Display" button (a World 1 alien at home with a Verdant habitat that has room); tap it: toast "Mossbop is on display", the card's status reads "On display" and the button "Bring back", the Mossbop walks about inside the fence (never through it), stopping now and then, with its name plate; Output `analytics: event Display value=1 action=on species=Mossbop`. Optimize never seats it; its card never offers Follow while displayed.
2. Fill the habitat with three; a fourth resting World 1 alien's card still shows Display but the tap says "Every Verdant Crash Site habitat is full"; a World 2 alien (Pengoo, `/world 2` catch or `/dupes`) with no Frostbyte habitat: "Build a Frostbyte habitat on your plot first". Bring back: "Mossbop comes back to camp", it leaves the pad and is seated again by Optimize.
3. Income: with three displayed (two Common, one Uncommon: 6 + 6 + 10 = 22 Scrap/h), `/grow` does not apply (that is worked time); instead leave home (`/world 1`), set the settle clock back with `/habitat 2` (two hours owed), fly back home: toast "Your habitats made 44 Scrap while you were away", Scrap +44, Output `analytics: economy Source 44 ... Habitat`. A second arrival within a minute pays nothing. A day away caps at 24 hours' worth.
4. Taking the habitat away (Take away in the tray) sends its aliens back to camp (their cards read "Tap to follow" again) and pays nothing. Fusing a displayed copy away clears it from the pad. Rejoin (memory profiles): the display persists. Output clean.

Known gaps in this milestone: habitat placeholder pads until the props exist, no "Wave" for visitors yet (42e), no habitat upgrade (capacity 3 fixed), displayed aliens play no animation beyond the walk and bob.

## Milestone 42d: the hangar, the kiosk and the mailbox (home place)

Three fixed features of the home (`data/Home.luau` points, `data/Mail.luau`): the trophy hangar, a row of scaled ship hulls on -Z of the camp, one per world the player has launched from, each on a pad with the world's name plate; the spin wheel kiosk on -X of the pad, where "Spin" opens the Gifts screen's wheel; the mailbox on +X, where "Mail" opens the mailbox screen: letters with a line and rewards (claimed through the gifts' reward path) and the Visitor Book under them. Letters arrive from the developer panel for now (`/admin mail <text> [scrap N]`, to everyone online on every server); visitors are written by 42e.

1. Home place, a profile that launched from World 1 (`/world 2` then `/world 0`, or a real launch): one hull at 0.35 scale on the first grey pad at (-14, -40) with the plate "Verdant Crash Site"; after a launch from World 2 as well (`/outpost 2`), a second hull on the next pad 14 studs along the row. A profile that never launched shows no hull (the hangar pads stay).
2. The kiosk at (-22, 0): within 10 studs the action reads "Spin" and opens the Gifts screen on its wheel; the mailbox at (22, 0): "Mail" opens the Mailbox screen, "No letters yet", "Visitors" above "Nobody has visited yet".
3. `/admin mail Welcome home scrap 250` (your id is a developer): every player online gets a letter; the toast "A letter is waiting in your mailbox at home" shows once (on any place); at the mailbox the letter reads "From the team", "Welcome home", "250 Scrap", a Claim button; Claim: toast "Claimed: 250 Scrap", Scrap +250, the letter goes, Output `analytics: event MailClaim value=1 from=the team` and a Mail economy source. A 100-character line is cut to 80; `scrap 9000` is capped at 5,000.
4. Twenty-one letters: the oldest is dropped (`/admin mail` 21 times, or `/mail N` in Studio which writes N test letters to yourself); the screen scrolls. Rejoin (memory profiles): letters persist. On World 1 the Mailbox screen opens too (the menu has no entry; the action exists only at home) and Claim works there as well. Output clean.

Known gaps in this milestone: no Warden pilot in the cockpits until the hangar prop exists (a placeholder silhouette ball sits on each hull), no mail between players yet (42e), letters never expire.

## Milestone 42e: visiting (home place; the teleport half waits on the published home place)

Visiting (`data/Visiting.luau`, `Shared/VisitRules.luau`): a friend's home is a reserved server of the home place keyed by the owner's user id (`TeleportService:ReserveServer`, the code kept in a MemoryStore map so the owner and every friend land in the same server), the owner's save read without a lock when they are away (`PlayerData.Peek`), a lock level in Settings ("Who can visit your home": Only me, Friends, Anyone; Friends for a fresh profile), and a Wave at a displayed alien that pays both players 5 Scrap through the gifts' reward path, 10 waves a day per visitor, once per alien per visit, 100 Scrap a day per owner. In a public home server (Studio, or a direct join) everyone is at their own home; Visit on a player in the same server switches the view there with no teleport, which is what Studio can test. What visitors leave for an away owner (the Visitor Book line, the waves' Scrap) waits in a HomeInbox DataStore and comes in at the owner's next load as Visitor Book lines and one letter from "Visitors". A visitor's own ship and stations stay theirs (the Ship screen, Collect and Build still work on their own camp).

1. Settings: the row "Who can visit your home" with Only me, Friends, Anyone; Friends is lit for a fresh profile; a tap saves and a rejoin (memory profiles) keeps it. Output clean.
2. Star Chart, Home card: a Visit button beside Fly opens "Visit a friend": "In this server" lists the other players here (multi-client: the second client's name with a Visit button; alone, "Nobody else is here right now"), "Friends" lists your Roblox friends (up to 50, online ones first, each with Visit) or "No friends yet. Add friends on Roblox and they show up here." when you have none. On World 1, Visit on an absent friend answers "Visiting opens when the home place is published" (the home world's place id is 0).
3. Multi-client in the home place, the owner (client A) with a room, a displayed alien and a launched world (`/world 2` then `/world 0`): client B taps Visit on A. B: the screens close, "Welcome to A's home!", the biome chip reads "A's home", A's rooms stand on the plot, A's displayed alien roams its habitat, A's hull stands in the hangar, B's own items are gone from the plot; near the plot the action is no longer Decorate, at the mailbox no longer Mail, Spin at the kiosk still works; B's Aliens screen shows no Display button. A: "B came to see your home" and B's name in the Visitor Book. Output `analytics: event Visit value=1 owner=<A's id> how=here`.
4. B walks within 10 studs of A's displayed alien: the action reads "Wave"; tap: "You waved at A's Mossbop (+5 Scrap)", B's Scrap +5; A: "B waved at your Mossbop (+5 Scrap)" and +5. A second tap on the same alien: "You already waved at this one". After 10 waves in a day (two displayed aliens, Fly home and Visit again between): "No more waves today. Come back tomorrow!". A sets the lock to Only me: B's Visit answers "A's home is closed to visitors"; Anyone lets B in again (Friends does when B is A's Roblox friend). Output `analytics: event Wave value=5 owner=<A's id> species=Mossbop` on B, a Wave economy source on both.
5. B's Star Chart while visiting: the Home card reads "Your ship waits here" with Fly; Fly: "Back at your own home", B's own plot and hangar return, the chip reads "Home". `/visit A` and `/visit off` do the same from the chat. In the home place, `/world 1` then the Star Chart: the World 1 card reads "Your ship waits here" with Fly (a guest may fly to the world the ship is on), and Fly answers with the "Verdant Crash Site is not published yet; your ship is logged there" toast in Studio. Output clean.
6. The teleport half (needs the published home place, its id in `data/Worlds` row 0, and real saves; not in Studio): Visit on an away friend reserves a server, keeps its code in the HomeServers map and teleports with the owner's id in the teleport data; the home server reads the owner from the join data and shows their home from their save (no lock, re-read every 60 s at most); the visit and the waves go to the HomeInbox; the owner's next load shows the Visitor Book line and the letter "N waves at your aliens while you were away" with the Scrap. The owner's own Fly home lands in that same reserved server, where the friends already there see them arrive. Output clean.

Known gaps in this milestone: a visitor's own ship stands on the owner's camp pad (their stations keep working; the owner's ship there is a look-pass item); no wave animation beyond the toast and a burst; waves to an away owner arrive as one letter a day, not one each; a lock change while a visitor is already inside does not send them away.

## Milestone 50: alien storage cap (World 1 place)

A profile holds at most 1,500 alien records (`data/Storage.luau`, `Shared/StorageMath.luau`, `Economy.GrantAlien`, `Economy.Release`). Why: the save is one DataStore value with a 4 MB limit and each record costs about 193 bytes, so a heavy player would lose saves around day 25 at 3 hours a day (`Save-Budget.md`). At the cap a new alien adds no record: the codex entry and its first-catch Scrap, the catch stats, the quests and the weekly board still count, and the alien turns into Scrap at its tier's release value (5 Common, 12 Uncommon, 40 Rare, 150 Epic, 500 Legendary, 1,500 Cosmic and Secret) on top of the catch pay. Releasing an alien pays the same value; holding an alien card opens its Release panel, and the blue Release button at the top left of the Aliens screen releases every unused Common or Uncommon at once. An alien that works at a station, follows you (a mount included) or is on display is never released. A paid Robux alien is exempt from the cap. Dev: `/storage fill [N]` adds N plain Common records (no number: as many as fit; never past the cap), `/storage cap` prints the count.

1. Press Play. Open Aliens: the count row reads "Aliens: 0 / 1,500" in white (a few more if you have caught some), and a blue Release button sits at the top left, level with the red X. `/storage cap`: Output `dev: <name> storage 0 / 1500 (ok)`.
2. The count colours: `/storage fill 1349` (or fewer if you hold some: the total should reach 1,349) and reopen Aliens: white. `/storage fill 1`: the total is 1,350 (90% of the cap) and the count turns gold; Output ends `(warning)`. `/storage fill`: the total is 1,500, the count is red and Output ends `(full)`. A further `/storage fill 5` adds nothing (Output `filled with 0 Common record(s)`). The grid scrolls through the 1,500 cards without a hitch.
3. A catch at the cap: `/spawn <speciesId>` a species you have not caught (or catch any wild alien), then catch it. The Reveal shows its usual card and, above it, a red ribbon "Storage full: turned into 5 Scrap" (12 for an Uncommon, and so on). The "+N Scrap" under the card is the catch pay plus the first-catch payout plus that value, and the Scrap pill rises by the same N. Close the Reveal: a red toast "Release or fuse aliens to keep new catches". Open Aliens: the count still reads "Aliens: 1,500 / 1,500" and no card was added. Open the Codex: the species is now caught. Output: `analytics: economy Source Scrap amount=5 ... sku=Overflow` after the Catch and Codex lines. The daily quest and Field Notes counts moved as for any catch.
4. Releasing an alien that is in use is refused with its reason. With a seated alien, hold its card for half a second: a panel opens with its name, "Common, Lv 1" in the tier colour, a grey Release button "Release +5 Scrap" that takes no action, and the red line "Working at a station. Only resting aliens can be released." Close it (the X, a tap outside the card, or the Aliens X). Make a resting alien follow (tap its card) and hold it: the line reads "Following you. Stop it following first." (At the home place a displayed alien reads "On display at home. Bring it back first.") A quick tap on a card still follows or unfollows as before and never opens the panel; dragging a finger over the grid scrolls it without opening the panel.
5. Releasing a free alien frees a slot. Hold a resting Common: the panel shows a gold button "Release +5 Scrap". Tap it once: the button turns red and reads "Tap again to release"; wait 3 seconds and it goes back to gold. Tap it twice within 3 seconds: a gold toast "Released Mossbop: +5 Scrap" (the species you held), the panel closes, the card is gone, the count reads "Aliens: 1,499 / 1,500" in gold and the Scrap pill is up by 5. Output: `analytics: economy Source Scrap amount=5 ... sku=Release`. Catch another alien: it is stored (the count returns to 1,500) and the Reveal has no ribbon.
6. Bulk release: tap the blue Release button. The card "Release aliens" lists "Release all unused Commons" with a line "N aliens, +5N Scrap" and "Release all unused Uncommons" with its own line ("None to release" and a grey button when there are none), and a grey hint "Hold an alien card to release just that one". N counts only resting aliens: seated and following Commons are not in it. Tap the Commons button: "Release N Common aliens for +5N Scrap?" with Cancel and a red Release. Cancel returns to the menu. Release: a gold toast "Released N aliens: +5N Scrap", the card closes, the seated and following Commons are still in the grid, the count falls by N and the Scrap rises by 5N. Output: one `economy Source Scrap amount=5N ... sku=Release`. Reopen the menu: the Commons line reads "None to release".
7. Fusion still frees slots at the cap: with the store full of Commons (step 2), tap Fuse. Toasts "<species> fused to Lv 2!" appear, four records leave for each fusion, the count falls and the next catch is stored again. (Fuse asks the server once per fusion, so a full store takes a while; release some Commons first if it feels slow.)
8. Check the Aliens screen, the Release card, the confirm view and the Reveal ribbon at iPhone SE (667x375) and iPad sizes in the device emulator: the button, the three lines and both buttons of the card stay inside it, no text is cut off, and the ribbon clears the card and the top of the screen.

Known gaps in this milestone: Release and the card have no sound ids yet (the Click is a placeholder like the rest); there is no multi-select, so a single Rare or better is released one hold at a time; the Aliens screen still resends all records on every camp push, which at 1,500 records is about 290 KB a push (a performance follow-up, not a rule); `tools/save_budget.py` does not model the cap yet.

## Milestone 49: playtime gifts (World 1 place)

Six gifts unlock by the minutes a player has actively played today (`data/Playtime.luau`, `Shared/PlaytimeMath.luau`, the Playtime service): 5 minutes 150 Scrap, 10 a Twig Lure, 20 a Speed Burst, 30 a free spin, 45 a Lucky Charm, 60 a Rare egg. The server counts every 5 seconds while the player is not resting (the milestone 46 rule), keeps the count and the claims in the save the same day (schema v16, `profile.playtime`), and starts again at 00:00 UTC; leaving the game loses nothing. `Enabled = false` in the data file hides the button and the screen. Dev: `/playtime <minutes>` adds that many minutes of played time today, `/playtime reset` clears today's time and claims. Decision 5c-1 measured these as no change to World 1's launch day.

1. Press Play. Output `Playtime: on; gifts at 5, 10, 20, 30, 45, 60 min, 5s ticks, day resets at 00:00 UTC`. The HUD gains a round green button with a ">" left of the Ranks button, with no badge. Tap it: the "Playtime gifts" panel opens with six cards in one row, the chips reading "5 min", "10 min", "20 min", "30 min", "45 min" and "60 min", the rewards "150 Scrap", "1 x Twig Lure", "1 x Speed Burst", "1 free spin", "1 x Lucky Charm" and "Rare Egg" (the egg card keeps the Rare blue edge), each card holding a dark pill with its time left as m:ss that counts down once a second (the first starts a few seconds under 5:00), and the line "Play to unlock more. Resets each day." under the row. The X and a tap on the dim close it. At iPhone SE (667x375) and iPad sizes in the device emulator nothing is cut off and no name runs past two lines.
2. `/playtime 5`: Output `dev: <name> has played 300 s today (0 claimed)` (a few seconds more if you have already played some). Within a moment the badge shows 1 on the button and, with the panel open, the first card turns white with a green "Claim" button while the rest keep counting. Tap it: the click, the toast "Playtime gift: 150 Scrap", Scrap +150, the card reads "Claimed" on a grey card and the badge goes. Output `analytics: event PlaytimeGift value=1` and `analytics: economy Source Scrap amount=150 ... type=TimedReward sku=Playtime`.
3. `/playtime 60`: the badge reads 5 and cards 2 to 6 show "Claim". Claim 2: toast "Playtime gift: 1 x Twig Lure" and the lure count rises by one. Claim 3: "Playtime gift: 1 x Speed Burst" and the power-up bar holds a Speed Burst. Claim 4: the toast, and the Gifts screen's "Banked spins" rises by 1. Claim 5: a Lucky Charm joins the power-up bar. Claim 6 (the Rare egg): no toast, the panel closes and the Reveal shows a Rare alien of this world with its Scrap, the alien joins the camp and the badge clears. Reopen the panel: all six read "Claimed". Output six `analytics: event PlaytimeGift value=N` lines (1 to 6) and the egg's `event Catch` with the tier and species.
4. Rejoin keeps progress (needs real saves: memory-only profiles are dropped when the player leaves, so set `Config.UseDataStoreInStudio = true` with Studio API access first): `/playtime 12`, claim the first gift, stop Play and press Play again. The panel shows the first card "Claimed", the second with its "Claim" button, the third counting down from about 8:00, and the badge reads 1. Leaving and coming back the same day loses nothing and adds nothing for the time away.
5. Resting does not count: `/playtime reset`, then `/afk` (the Resting screen), wait 30 seconds, `/afk off`, open the panel. The first card has about the time it had before `/afk` (at most a few seconds less than 5:00), not 30 seconds less; walking around afterwards lowers it by one second per second. Opening the panel while still resting wakes the player (every server call counts as use), so wake first.
6. `/playtime reset`: Output `dev: <name>'s playtime today cleared`; every card goes back to its countdown from 5:00 and the badge goes, and gifts claimed earlier can be claimed again. `/playtime -5` after a `/playtime 10` takes five minutes back.
7. Set `Enabled = false` in `src/shared/data/Playtime.luau` and press Play: Output `Playtime: off (Shared/data/Playtime Enabled = false)`, the HUD button is gone and the buttons beside it close the gap, and `/playtime 5` prints but shows no badge. Set it back to `true`.

Known gaps in this milestone: the gift icons and the button's icon wait for the icon pack (the cards show names, the button a ">" glyph) and the claim sound id is 0 like the rest; the countdown on the open panel is the client's estimate from the server's last count and corrects at the next push or the next time the panel opens; a player who stands idle with the panel open rests after two minutes and the estimate runs ahead until they wake; the day resets at 00:00 UTC for everyone.

## Milestone 46: resting in the game (World 1 place)

Resting (`data/Afk.luau`): after 2 minutes with no movement and no use of the game, a player is resting. Their stations pay half the usual rate for as long as the game stays open (being away pays the same half rate but stops after an hour). A calm Resting screen shows the time and the Scrap earned. Before Roblox's 20-minute idle cutoff the game rejoins the player to the same server. The Longer Offline pass is withdrawn. Dev: `/afk` rests now, `/afk off` wakes, `/afk rejoin` runs the rejoin (Studio only prints it).

1. With at least one seated alien, stand still for 2 minutes (or `/afk`): the world dims behind a card reading "Resting", "Your crew keeps working at half speed while you rest. Leave the game on as long as you like.", "Resting for 0:12" counting up, and "Earned while resting: N Scrap" rising; the HUD's Scrap per minute halves. Output: `Afk: <name> is resting`.
2. Move, tap "Back to play" (mouse click or touch), or press any key or click anywhere: the screen goes and the server wakes at once (fixed 2026-10-07: the screen used to hide on mouse-down before the button could fire, leaving the server resting), the toast "Welcome back! Your crew earned N Scrap while you rested" shows, the per-minute rate returns to full. Output: `analytics: event Rest value=<seconds> earned=<N>`.
3. Standing still but using menus (open Aliens, tap a card, open the Shop, scroll a list) for 3 minutes never rests: the client reports presses and scrolls the server cannot see (`AfkWake`, at most every `Afk.ActivityPingSeconds`, 20 s), so using the game counts as playing (fixed 2026-10-07: menus used to count as idle). Standing still with no input still rests after 2 minutes.
4. `/afk rejoin`: Output `Afk: would rejoin <name> to this server (Studio skips teleports)`; on the screen the line "Keeping your spot..." shows. In a published game, after 17 minutes without input the player rejoins the same server and rests again two minutes later.
5. The Shop's Passes section has five tiles (no Longer Offline Shift); a rejoin after 3 hours away still pays at most an hour of half-rate income. Output clean.
6. The HUD's Scrap per minute now shows what is paid: use a Double Shift (`/spins 5` and spin until one lands, or a code) and the line doubles at once and returns when it ends; a Roblox friend joining the server raises it by the Friend Boost (multi-client); resting halves it. Before this milestone the line never moved for any of the three.

## Phone performance fixes (World 1 place; from Codex's report C14)

No visible change is intended; these are re-checks that nothing broke. Companions keep their footing on slopes and never stand inside another player (the raycast list is cached now); a server never holds more than 80 wild aliens (`Config.SpawnMaxWild`; `/spawn` and summoned Wardens are not counted or blocked), and with two clients far apart both get aliens; far-away and blizzard-hidden aliens stop bobbing and resume in step when you come back; a Warden sighting's trail looks as before (its puffs are pooled); the radar's blips and the secret ping behave as before.

1. Walk with a companion over the Forest's slopes and past another player (multi-client if possible): it stays on the ground. Output clean.
2. `/sighting`: the trail of puffs looks and fades as in milestone 39; after two sightings the Explorer's ClientSightings folder does not keep growing.
3. In a Blizzard (World 2, `/weather Blizzard`), hidden aliens reappear in place when a Heater is placed near them; walking 200 studs away and back, nearby aliens bob in step.

## Milestone 45: paid spins and two more passes (World 1 place)

The Robux page gains a Spins section (1, 5 and 12 spins; `data/Shop` rows with `oddsOnWheel`) and two passes (+2 Slots on Every Station, +1 Companion). Product and pass ids are 0 until the owner creates them, so Buy refuses safely; `/pass <itemId>` and `/buy <itemId>` grant them in Studio.

1. Shop, Robux tab: the Passes section shows five tiles (the Longer Offline pass was withdrawn), the Spins section three red tiles under Boosts. Each spin tile reads its name and "Tap for the odds" in gold where other tiles have a description (the name says what it is); a tap anywhere on the description band opens the Gifts screen on the wheel; the Buy button is its own target. At 767x435 and iPhone SE nothing is cut off. On the Gifts screen, "See every prize's odds" under the wheel opens a table over the wheel: a Prize and Chance header, one row per prize with its odds, most likely first, and a Total row reading 100%, all in navy; every row readable at iPhone SE size. The button then reads "Back to the wheel" and closes it; closing and reopening the screen shows the wheel first.
2. `/buy Spins5`: the spin balance on the wheel rises by 5; Output shows the purchase recorded. `/pass SlotEveryStation2`: every station shows two more open slots (three more with `SlotEveryStation1` as well). `/pass CompanionSlot4`: the Aliens screen allows one more follower.
3. Where paid random items are restricted, the Spins section and its heading are hidden with the Server Luck tiles. In Studio the server prints its answer when the shop first asks: `Policy for <name>: paid random items restricted = false` (Studio's own answer is usually false; the hidden case is checked by reading the code path or on a restricted test account). Output clean.

## Milestone 44: the Haunted Nebula seasonal event (World 1 place)

A seasonal event (`data/Seasons.luau`, `Shared/SeasonMath.luau`) is a dated window laid over the existing worlds: two limited event aliens (Wisplet, Rare, Forest, Night; Spookum, Epic, Cave, Night) take a 12% share of World 1's wild spawns in any biome, Spectral rolls on 3% of World 1's wilds whatever the weather, nights last twice as long, Panpipe comes back at 3% (the Vault Rotation), and a free five-row track (catch 5, 12 and 25 event aliens, one with Spectral, be there when three Showers end) pays Scrap, lures, spins and, last, the track-only Legendary Nebulyn. Haunted Nebula's window is 2026-10-16 16:00 UTC to 2026-10-30 16:00 UTC; in Studio `/season HauntedNebula` forces it on (the banner counts the whole window), `/season off` returns to the calendar, `/season done` fills every row of the track.

1. `/season HauntedNebula`: toast "Haunted Nebula has begun! Event aliens roam Verdant Crash Site"; the HUD banner reads "Haunted Nebula", "13d 23h left" (or so) and the chip "Spectral", above the weekly's banner (the weekly returns when the season ends); Output `analytics: event SeasonStart value=1 id=HauntedNebula` and the Seasons service's line naming the event. The Codex: Wisplet and Spookum unknown with the stamp "Event" and the hint "Event alien: 13d left"; Panpipe stamped "Event" with "Back for Haunted Nebula: 13d left"; Nebulyn unknown with no stamp.
2. Spawns: over about 60 wild spawns roughly 12% are Wisplet or Spookum (in any biome, day or night), about 3% carry Spectral in Clear weather, and about 3% are Panpipe; none of the three leaves when the clock's condition changes (`/day` after a night spawn). Catch a Wisplet: the Reveal, the Codex entry fills, the card is a normal Rare.
3. Nights: with the season on, the next night lasts 180 s (the clock chip's countdown), days stay 180 s; `/season off` and the night after is 90 s again.
4. The track: the Quests screen gains an "Event" tab while the season runs (three tabs); it lists the five rows with "n/N" progress, a free-hint line, and Claim buttons that light when a row is done. Five event catches: the first row's Claim; tap: toast "Claimed: 500 Scrap", Scrap +500, the row reads Done, Output `analytics: event SeasonClaim value=1 id=HauntedNebula quest=S_catch5`. A Spectral catch counts the overlay row; `/shower` then `/shower end`, three times, counts the shower row. `/season done` then Claim on the last row: the Reveal shows Nebulyn and it joins the camp (a Legendary, never spawning). A second Claim on a row answers nothing (already claimed). Rejoin (memory profiles): the counts and the claims persist.
5. `/season off`: the banner and the Event tab go, the weekly banner returns, no event alien spawns from then on, the Codex stamps read "Vaulted" for Wisplet, Spookum and Panpipe. Output clean on both sides.

Known gaps in this milestone: the sky, music and camp decor are the look pass's; the window dates are placeholders until the launch date is set; the track's alien reward goes through the catch path, so analytics counts it as a catch; no "last chance" countdown by design (the end is on the banner from day one); the three event species have placeholder shapes until their blockouts are generated.

## Milestone 43: the Scanner Pulse (World 1 place)

The Scanner Pulse power-up (`data/PowerUps`, effect "reveal", 60 s, from quests and spins, never sold) finally has a reader: while it runs, every wild alien in the player's biome shows on the radar whatever the range (beyond the disc's range a blip sits on the rim as a direction marker, like the camp square), every uncaught species in that biome resolves from its shadow silhouette at any distance, and the disc's ring pulses in the Codex purple. A radar of any tier shows it; the free Nearby panel (tier 0) is unchanged.

1. `/radar 1`, then with a Scanner Pulse in the inventory (the spin wheel or quests; in Studio `/buy` has no Scrap row for it, so grant it through a code or a quest, or use `/spins` and spin until one lands) use it from the power-up bar: "Scanner Pulse on!", the ring turns purple and breathes; blips appear for wild aliens 150 and 250 studs away, pinned to the rim with the right bearing (compare the compass heading); a Forest alien does not show while you stand in the Meadow (the biome rule), and it appears when you cross into the Forest.
2. An uncaught species 100 studs away is drawn in colour (no silhouette) while the pulse runs and shadows again when it ends; the Nearby panel on tier 0 lists the same species it always did.
3. The buff ring under the ship bar counts the 60 s down; at the end the rim blips go, the ring returns to blue, the silhouettes return. Rejoin mid-pulse (memory profiles): the timer resumes and the reveal with it. Output clean.

Known gaps in this milestone: "hidden spots" are not built in any world, so the pulse reveals aliens only; no sound on activation beyond the generic power-up cue. By design, a Secret-tier wild gets no blip from the pulse below Radar Mk2: the "???" ping is what Mk2 sells, and the pulse never gives a secret away.










