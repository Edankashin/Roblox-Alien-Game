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
