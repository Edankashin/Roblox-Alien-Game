# Store page and the launch morning (draft, 2026-10-14; art and description 2026-10-22)

Everything the Creator Dashboard asks for when the game goes public, drafted so Ethan's part is a few clicks. Dashboard: create.roblox.com → Creations → Alien game → Configure.

## 1. Name (decision 19, Ethan's pick)

**Decided 2026-10-14: Catch an Alien** (Ethan's pick). Before entering it: search the name on roblox.com to check nothing popular collides; if it does, "Catch an Alien!" or "Catch an Alien: Crash Planet".

## 2. Description (paste as is; under 1,000 characters)

Refreshed 2026-10-22 for the block-cell game (B44 to B49): 797 characters. Every line is in the build: 35 species in `data/Species` (Common to Secret), the eye library and the effects ladder by tier ([[Blocky-Style]] 3 and 7), the Starhollow Forest (B48), Frostbyte's lake, Ice Cave, Geyser Field and blizzards, offline earnings, showers every 7,200 s (`Config.ShowerIntervalSeconds`), the Peddler, daily quests, gifts, fusion, three companion slots (`Config.CompanionSlots`), the home planet and visiting. "Ride the big ones" is gone: mounts are an open decision (Decide-Now 44, B45).

```
You crash-landed on a strange planet built of little blocks. Cute aliens are everywhere!

Catch them with a quick timing bar, put them to work at your camp, and watch your ship come together piece by piece. Fill the ship bar, launch, and land on World 2, Frostbyte: frozen lakes, ice caves, geysers and blizzards.

- 35 aliens to find, from Common to Cosmic and Secret
- The rarer the alien, the more special its eyes, glow and effects
- Explore the moonlit Starhollow Forest: glowcaps, lanterns and a floating island
- Your camp earns while you are away
- Meteor Showers every two hours, a travelling Peddler, daily quests and gifts
- Fuse spare aliens and bring three along as companions
- Build your own home planet and visit your friends'

One thumb, no stress, nothing you did is ever wasted.
```

## 3. Settings

- Genre: Adventure (subgenre, if offered: Collecting). Playable devices: Computer, Phone, Tablet (Console off until tested).
- Max players per server: 8 (`Config.MaxPlayers`); preferred 6.
- Private servers: off at launch. Chat: on. Experience notifications: off (decision 20 open).
- Paid access: off. The six new shop items are already created (overnight job 2); check Passes and Developer Products are "for sale".
- Age guidelines / Experience Questionnaire: answer honestly: no blood, no realistic violence, no gambling (the spin wheel and server luck are paid random items with odds shown and no real-money payout; answer the "random items" question as the questionnaire words it), mild cartoon creatures. Expected rating: All ages or 9+.

## 4. Icon and thumbnails

**The launch set in block cells, 2026-10-22 (B49): `media/store/2026-10-22/`, options for Ethan to pick from.** The sheet `choices.jpg` shows every option with its big letter or number; answer like "icon B, thumbs 3, 1, 5". Rendered by one command from the exported block-cell models in `assets/models/` and the generated worlds, so it can be re-run after any model pass: `$BPY tools/blender/store_renders.py --set 2026-10-22` (`tools/blender/store_blocky.py` renders, `tools/store_blocky_compose.py` paints the stepped-cell sky, the bloom, the thick navy outline, the block-cell UI overlays and the Fredoka One title; `--only A,2` re-renders some options, the rest are kept). The rules from [[Thumbnail-Research]]: show the real best moment, words only in the top third, one hero facing the lens, nothing essential in the bottom fifth; our own art only.

| Option | File | What it shows |
|---|---|---|
| Icon A | `icon_A.png` (512) | Moop's face close-up on the meadow grass, the crashed ship behind, a blue day sky |
| Icon B | `icon_B.png` | Raddis (Cosmic) glowing at night in the Starhollow: its sunstones, solar eyes, a gold ground ring and motes |
| Icon C | `icon_C.png` | Moop (Common), Aurelyx (Epic) and Vixa (Rare) squeezed together |
| 64 px check | `icons_64_strip.png` | the three icons at 64 px, the smallest size they are seen at |
| Thumb 1 | `thumb_1.png` (1920x1080) | the camp: aliens at work round the half-built ship (built part solid, the rest the blue module ghost), the player, a Rare (Zirrit) popping out of its portal of cells; title |
| Thumb 2 | `thumb_2.png` | the catch: Gaira (Legendary) in its gold ring and light at dusk, the capture bar in block cells (Legendary's real zone widths) |
| Thumb 3 | `thumb_3.png` | the Starhollow Forest at night: the lavender path, lanterns, glowcaps, the floating island and its waterfall, Lantrin on the path; title |
| Thumb 4 | `thumb_4.png` | World 2 Frostbyte: Fenrir with its gibbous moon by the frozen lake, the ice spire, pines, a pixel moon and aurora |
| Thumb 5 | `thumb_5.png` | the rarity ladder: Common to Secret on stepping blocks, each glowing more (pool, light, ring, motes, pillars); title |
| Thumb 6 | `thumb_6.png` | the reveal: the Cosmic card landing in its pixel sky, the cell-ray fan, starburst, gold cell frame and confetti cells |

**Ethan's picks (2026-10-22): icon A, first thumbnail S3 (the two-worlds panorama).** For the thumbnails he asked for scenery: "I want the thumbnail to show the most beautiful version of the world so that it is scenic and shows what the game offers." So slot 1 is **Ethan's pick from S1 to S3** below (answer "S1", "S2" or "S3" on `scenic_choices.jpg`), slots 2 and 3 are suggested from the first set: **thumb 2** (the catch), then **thumb 1** (the camp).

| Option | File | What it shows |
|---|---|---|
| S1 | `thumb_S1.png` (and `thumb_S1_notitle.png`) | the meadow vista from the highland plateau by the lookout at golden hour: the river running to the falls, blossom trees, the camp with the half-built ship and flag, the wreck, paths, Moop, Dandel, Vixa (Rare), Buzzik, Gaira (Legendary, glowing) and Iridia on the rim; the Starhollow's violet canopy and the floating island with its glowing fall on the horizon; title top left |
| S2 | `thumb_S2.png` (and `_notitle`) | the Starhollow at dusk from where the lavender path leaves the meadow: lanterns, glowcaps, light drips, fireflies, the island and its fall through the canopy, Raddis (Cosmic) in its gold sun ring, Lantrin with its lamp and Iridia, the meadow's trees still warm on the right under the sunset; title top left |
| S3 | `thumb_S3.png` (and `_notitle`) | the two worlds in one panorama joined along World 1's meadow river: the sunlit meadow, camp and Moop, Buzzik and Vixa on the left; across the river Frostbyte's snow, frozen lake, ice spires and pines under the aurora and moon, with Fenrir (Cosmic), Pengoo and Mitt; title centred |
| 400 px check | `scenic_400_strip.png` | S1 to S3 at 400 px, the size of a phone's game list |

Rendered by the same route, one command: `$BPY tools/blender/store_renders.py --set 2026-10-22 --only S1,S2,S3` (the generated worlds and the real models; a depth pass for aerial haze, bloom on the glow cells, an aura behind each glowing rare, gentle depth of field; [[Thumbnail-Research]] section 14). Two liberties, both for job 53 to judge: S2 leaves out the few moon trees standing in the sightline to the island, and S3 joins two places that are separate worlds in the game.

The store-art worker's recommendation is in the 2026-10-21 log (Store art worker). The earlier sets stay for the record: `media/store/2026-10-14/` (the interim v2) and `media/store/2026-10-15/` (the pre-blocky candidates); neither matches the block-cell game, so neither goes up.

- A 10-second clip for the store video can wait until after launch (the cinematic shots film it).

## 5. Launch morning checklist (Ethan, about 20 minutes)

1. Read `docs/vault/08-log/2026-10-14.md`, the Mac's closing summary: what passed, what is blocked.
2. Join the private game on your phone once (the published places from overnight job 6): the models load (no grey placeholder shapes), the shop shows "about $" lines, a catch works, music plays (or is silent where a track is still 0).
3. Dashboard: name, description, genre, devices, icon, thumbnails (section 1 to 4).
4. Experience Questionnaire, then Privacy: Public.
5. Creator Hub > Events: list the Haunted Nebula event (2026-10-16 to 2026-10-30) with one line and the frostbyte or legendary thumbnail, so the game shows on the Events surface (Growth Playbook S9).
6. Tell the coordinator "public"; it starts the Day 1 watch below.

## 5b. Day 1 watch (what to read in Creator Hub > Analytics on launch day, and the numbers that mean trouble)

Day 1 retention lags a day, so launch day is about: concurrent players (CCU), average session time, the first-session funnel (the game's own analytics events: joined, first catch, first module, five minutes), crash rate and frame rate, and the Robux sales rows. The targets from the design (section 18): in the terms Creator Hub reports: Day 1 retention above the 90th percentile of our genre benchmark band (12% good, 15% great; 20% is the top-1% stretch), Day 7 above 2% with 4% as the stretch, first-play bounce under 10% within 60 seconds and under 15% within 180 seconds, more than 55% of new players still playing at 5 minutes, median session above 10 minutes, tutorial completion above 60%, Meteor Shower attendance above 30% of online players. If Day 1 sits under the 50th percentile after week one, the problem is the first eight minutes, not the roster. Sound, VFX and a gameplay trailer are launch requirements: creators who reached 1,000 concurrent say they move every stat (`docs/PRE_PRODUCTION.md` section 10.9).

What we change first if a number is off: bounce high at 60 s means the loading wait or the first screen (cold servers wait up to 20 s on the model loader; the five-minute script's first beat); low catch-at-5-minutes means the first wild alien is too far or the tap is unclear; crash or frame rate on phone means the phone performance list in TESTING; a flat Robux row on day one is normal.

## 5c. The week before and the first week (seeding, from PRE_PRODUCTION 7 and the references)

- A 10 to 15 second gameplay video on the store page: play-through rate is the top signal and a video autoplays on Home. The Mac records three clips during Play (Overnight job 18); pick one, upload it with the icon.
- A Discord invite (or the group wall) on the store description's last line once a server exists; the `LAUNCHWEEK` promo code (300 Scrap and a Lucky Charm, 2026-10-16 to 10-31) in the description and in every post.
- A Roblox group (decision 16) unlocks the group-join gift in the game (`Social.GroupId`); without it the gift stays hidden.
- Five creators who cover small cute games, one DM each with the code and the trailer; no paid promotion in week one.
- Launch week in the game: the LaunchGold overlay (about 1 in 25 catches through 2026-10-26) and a World 1 Alien of the Week, so the players who were there have something to show.

## 5d. Dashboard run sheet (for the session that drives Ethan's screen; every field in order, no decisions left in it)

Creator Dashboard: create.roblox.com > Creations > Alien game (universe 10769415131). Values below assume Ethan's answers to the decisions list; replace a line if he chose otherwise.

| Page | Field | Value |
|---|---|---|
| Basic Settings | Name | Catch an Alien (Ethan's pick, 2026-10-14; check Roblox search for a collision first) |
| Basic Settings | Description | section 2 above, pasted as is; append the LAUNCHWEEK line: "Code LAUNCHWEEK: 300 Scrap and a Lucky Charm, until Oct 31." |
| Basic Settings | Genre | Adventure |
| Basic Settings | Playable devices | Computer, Phone, Tablet on; Console and VR off |
| Basic Settings | Icon | `media/store/2026-10-22/icon_A.png` (Ethan's pick, 2026-10-22; section 4) |
| Basic Settings | Thumbnails (in order) | 1: `media/store/2026-10-22/thumb_S3.png` (Ethan's pick, 2026-10-22: the two-worlds panorama); 2: `thumb_2.png`; 3: `thumb_1.png` (section 4; at least two so personalization runs; drop any that job 53 finds the game does not show); video `media/store/2026-10-14/clip_catch.mp4` once the Mac's job 18 delivers it |
| Places > World 1 | Max players | 8; server fill: Roblox optimised |
| Access | Private servers | Off |
| Access | Paid access | Off |
| Communication | Chat | On (text) |
| Monetization > Passes | SlotEveryStation2, CompanionSlot4, StorageBoost, ExplorerPack, SlotEveryStation1 | each "For sale" |
| Monetization > Developer Products | Spins1, Spins5, Spins12, the boosts, Server Luck | each "For sale" |
| Events | New event | Haunted Nebula, 2026-10-16 to 2026-10-30, one line from the season's strings, thumbnail: one of the 2026-10-22 set Ethan did not pick for the store (the docs want an event image that differs from the experience thumbnails; thumb 2 or 6 if free) |
| Experience Questionnaire | Violence | none realistic; cartoon creatures caught with a timing bar, no blood, no weapons |
| Experience Questionnaire | Fear | none (Haunted Nebula is cartoon spooky) |
| Experience Questionnaire | Romance, crude humour, alcohol, gambling | none; paid random items: yes (spins and eggs), odds shown in game, no real-money payout, no Scrap sold for Robux |
| Experience Questionnaire | Free-form chat | yes (Roblox text chat) |
| Privacy | Public | only after Ethan's phone check; he says "public" |
| Credentials > API keys | the Open Cloud key | read only: scopes (Assets read and write, universe-places write for this experience), expiry set; note what it shows in the log; never copy the secret |

## 6. Known gaps shipping with the launch (fix in week one)

Icons are the flat pack where no pixel icon exists yet; music is a first blind pick; camera anchors are not placed; worlds 3 to 7 are designed only; haptics unverified on a real phone. Five shop items (DirectRare, DirectEpic, AutoCollect, ModuleRush, RadarMk1Unlock) are not sold until their features exist (`docs/vault/04-roblox-engine/Prelaunch-Audit.md`).
