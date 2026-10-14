# Store page and the launch morning (draft, 2026-10-14)

Everything the Creator Dashboard asks for when the game goes public, drafted so Ethan's part is a few clicks. Dashboard: create.roblox.com → Creations → Alien game → Configure.

## 1. Name (decision 19, Ethan's pick)

Recommended: **Crash Planet: Catch Aliens** (clear promise, the verb first, no reward words). Alternatives: Alien Pals: Build a Rocket; Planet Hoppers: Alien Collector. Before locking: search the name on roblox.com to check nothing popular collides.

## 2. Description (paste as is; under 1,000 characters)

```
You crash-landed on a strange planet. Cute aliens are everywhere!

Catch them with a quick timing bar, put them to work at your camp, and watch your ship come together piece by piece. Fill the ship bar, launch, and land on the next world: a frozen one with blizzards, then more.

- 35 aliens to find, from Common to Cosmic, with rare ones hiding at night and in the rain
- Your camp earns while you are away
- Meteor Showers every two hours, a travelling Peddler, daily quests and gifts
- Fuse spare aliens, ride the big ones, bring three along as companions
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

**Rendered overnight on 2026-10-14 (headless Blender, `tools/blender/store_renders.py`), in `media/store/2026-10-14/`.** The coordinator's picks: icon `icon_Mossbop_v2.png` (the navy outline reads like the top games' icons; `icon_Sparkfox_v2` and `icon_Thunderhog_v2` are the alternates); thumbnails in this order, the titled versions (two to four outlined words in Fredoka One, `tools/store_title.py`, 2026-10-14 afternoon): `thumb_verdant_v2_title.png` ("CATCH CUTE ALIENS" over five aliens at the crash wreck), `thumb_legendary_v2_title.png` ("LEGENDARY!" in gold over Gaiabloom), `thumb_frostbyte_v2_title.png` ("NEW WORLD: FROSTBYTE" over the spire and pines). The untitled `_v2` files are the same shots without text; `_v1` is the plain first pass. The wreck brought closer is the first polish item after launch.


- Icon 512x512: the Mossbop (or Sparkfox) face close-up on the meadow, rendered in Blender from the species model with the icons v2 light (`docs/vault/06-art-pipelines/Look-Plan.md` L5b), thick outline, the ship in the corner. Until that render exists: a Studio capture of a Mossbop catch moment, cropped square.
- Thumbnails 1920x1080 (up to 5; the first one is the one the tile shows): (1) the camp with the half-built ship and aliens at work, (2) the capture bar on a Rare, (3) the Moonlit Forest at night, (4) the home planet with habitats. The Mac's overnight captures land in `media/store/2026-10-14/`; pick the four best, add the game name in Fredoka One with an outline on the first one.
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

## 6. Known gaps shipping with the launch (fix in week one)

Icons are the flat pack (icons v2 to come); music is a first blind pick; the Moonlit Forest dressing and camera anchors are not placed; worlds 3 to 7 are designed only; haptics unverified on a real phone.
