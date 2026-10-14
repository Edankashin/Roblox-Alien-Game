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

**Rendered overnight on 2026-10-14 (headless Blender, `tools/blender/store_renders.py`), in `media/store/2026-10-14/`.** The coordinator's picks: icon `icon_Mossbop_v2.png` (the navy outline reads like the top games' icons; `icon_Sparkfox_v2` and `icon_Thunderhog_v2` are the alternates); thumbnails in this order: `thumb_verdant_v2.png` (five aliens at the crash wreck under the trees), `thumb_legendary_v2.png` (Gaiabloom alone), `thumb_frostbyte_v2.png` (the frost species with the spire and pines). The `_v1` files are the plain first pass. Upload as they are for the weekend; a title overlay in Fredoka One and the wreck brought closer are the first polish items after launch.


- Icon 512x512: the Mossbop (or Sparkfox) face close-up on the meadow, rendered in Blender from the species model with the icons v2 light (`docs/vault/06-art-pipelines/Look-Plan.md` L5b), thick outline, the ship in the corner. Until that render exists: a Studio capture of a Mossbop catch moment, cropped square.
- Thumbnails 1920x1080 (up to 5; the first one is the one the tile shows): (1) the camp with the half-built ship and aliens at work, (2) the capture bar on a Rare, (3) the Moonlit Forest at night, (4) the home planet with habitats. The Mac's overnight captures land in `media/store/2026-10-14/`; pick the four best, add the game name in Fredoka One with an outline on the first one.
- A 10-second clip for the store video can wait until after launch (the cinematic shots film it).

## 5. Launch morning checklist (Ethan, about 20 minutes)

1. Read `docs/vault/08-log/2026-10-14.md`, the Mac's closing summary: what passed, what is blocked.
2. Join the private game on your phone once (the published places from overnight job 6): the models load (no grey placeholder shapes), the shop shows "about $" lines, a catch works, music plays (or is silent where a track is still 0).
3. Dashboard: name, description, genre, devices, icon, thumbnails (section 1 to 4).
4. Experience Questionnaire, then Privacy: Public.
5. Tell the coordinator "public"; it starts the Day 1 watch (analytics funnel, the first-session bounce, crash reports).

## 6. Known gaps shipping with the launch (fix in week one)

Icons are the flat pack (icons v2 to come); music is a first blind pick; the Moonlit Forest dressing and camera anchors are not placed; worlds 3 to 7 are designed only; haptics unverified on a real phone.
