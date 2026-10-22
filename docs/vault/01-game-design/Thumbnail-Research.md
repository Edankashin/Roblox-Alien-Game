---
tags: [game-design, research, launch]
aliases: [Thumbnail research, Thumbnails]
up: "[[Game-Design]]"
---
# Thumbnail research: what earns the first click, and how we build ours

Researched 2026-10-14 for Ethan's questions (which thumbnails get the most first clicks, describe or mystery, words, reward or moment, composition, icon versus thumbnail, cadence, a brand-new game). Companion to [[Growth-Playbook]] section 2 and [[STORE-PAGE]] section 4; the look rules are in [[Look-Plan]] L5b and L6.

**Evidence tiers** (the [[Growth-Playbook]] words, plus one): **doc** = a Roblox Creator Docs page I opened in full through its GitHub mirror (`raw.githubusercontent.com/Roblox/creator-docs`); **summary** = a search-result summary of a Roblox post I could not open; **3rd** = a blog, wiki, forum or creator post, not Roblox; **recall** = my own memory of how a live game looks, not seen from here; **heuristic** = a design rule from the above with no Roblox test behind it.

**What I could not do.** roblox.com, create.roblox.com and devforum.roblox.com are blocked and WebFetch reached nothing but the GitHub mirror, so I never saw a Home tile or a Creator Hub chart. About 35 searches returned snippets. There is **no public dataset** of play-through rate (PTR) by thumbnail style, and no creator I found published an A/B result with numbers. Everything about "what the top games' thumbnails show" is therefore recall, flagged in section 4 with a 15-minute check to do on a phone.

## 0. The answer in ten lines

1. Nobody outside Roblox can say which thumbnail style wins; Roblox's own number for the feature that picks winners is +8.5% qualified PTR on average, up to +50% for some games (doc), later quoted as +12% over 8,000+ experiences (summary). A better thumbnail is single-digit to low-double-digit percent, not magic. The first 60 seconds and the 28-day return matter more.
2. Roblox's guidance (doc) is: unique imagery that previews what you will find, accurate to the game, text "sparingly" and only as gameplay context, nothing essential in the bottom (the player count overlays it), no ads, promotions or subjective claims.
3. Since June 2026 Roblox says it demotes games that win clicks with "exciting thumbnails" but deliver little (newsroom, summary), and first-play bounce under 60 s and 180 s counts against you (doc). So **tease the real best moment; never hide the game behind a mystery.**
4. The tile already prints our name, "Catch an Alien", under the picture. Thumbnail words should add what the name does not: the moment, the rarity, the hook, the update. "CATCH CUTE ALIENS" repeats the name, and it sits in the bottom band.
5. All sources agree on the picture: one subject, a face with a clear emotion looking at the viewer, saturated colour with contrast, readable at phone size (3rd, heuristic).
6. Our current legendary shot is the best of the set (12/16 on the recipe); the Verdant (5/16) and Frostbyte (4/16) shots are crowds of small aliens on pale ground and break Roblox's bottom-band rule.
7. **All five store renders show the earlier ball-shaped aliens, not the silhouette-pass models now in `assets/models`.** If those go up before launch, the thumbnails stop matching the game (section 7).
8. Ship three active thumbnails that differ by concept, not styling: Moment, Reward, Mystery (section 8). Roblox's tool is a per-user-group bandit, not a clean A/B; read it after a week.
9. Put the Moment first (section 9): it is the only frame that shows the verb, and the first catch lands at 0:30.
10. The icon is the mascot (Moop), no text, on a saturated dark backdrop; the current pale backdrop and 1% outline are the weak part.

## 1. What Roblox itself says (doc unless marked)

| Topic | Fact |
|---|---|
| Image | 16:9, ideally 1920x1080; jpg, gif, png, tga, bmp; stretched to 16:9 if not; personalization uploads under 3 MB. Up to **10** images or videos on the detail page; personalization uses **2 to 5** active ones |
| Where it shows | "The first image thumbnail is used as the promotional image in various sections of the Home page." With 2+ active, each user group is served the winner instead. Home tile pixel sizes and autoplay behaviour are **not in any page I could read**; the video "can also be shown on the Home page" and shows first on the detail page |
| The test | Personalization starts only with 2+ active thumbnails. Each is shown to random users, qualified PTR is measured per user group, the winner gets more impressions for that group, the others keep "minimal traffic". Impressions re-weight within hours (summary). The Home Page tab fills after a few hours with a table: impressions, qualified plays, average playtime, qualified PTR, a "Winning Segment" mark, and two graphs over time (summary of the docs' analytics section) |
| Results | Average +8.5% qualified PTR in testing, some games +50% (doc). "Over 8,000 experiences adopted it, average +12%" (Bloxy News post quoting Roblox, summary). The 2025 "remembers winners" update: +0.19% and 21% fewer impressions to non-winners (summary); start a new test with the current winner included and it keeps most traffic |
| Cadence | "Test multiple new thumbnails with any major game or content update, and then not make changes until the next update." Keep several active; a thumbnail pulled early may be the second-best performer |
| Measurement | Qualified PTR is a rolling 7-day value (summary); removed thumbnails keep colouring the average for days; several bug threads on mismatched counts (summary) |
| Content | "Imagery that is unique and gives players a relevant preview"; "ambiguous imagery can cause confusion"; "make sure all thumbnails accurately reflect your game"; a dinosaur thumbnail for a game with no dinosaurs is the docs' mismatch example (discovery.md) |
| Text | "Overlay text sparingly, and only to describe gameplay context." Not allowed: advertisements, promotions or subjective claims ("50% off", "Free UGC!"). "Avoid placing essential text or elements at the bottom" |
| Reward words | Metadata that "implies any type of monetary reward is not prioritized"; highly mismatched metadata is not recommended and ranks lower in search (discovery.md). No FREE, Robux, codes words |
| Video | 3 uploads a month; must be authentic (no voice-over, no lyric music, no real-life footage); in-game UI text and a logo overlay are allowed; not on console or VR |
| Icon | Square, 512x512 template, shown down to about 150x150; "prominent placement in several sections of the Home page"; express theme, tone and genre; avoid ambiguous art; colour and contrast carry mood (bright high saturation for fantasy and dreamy). The docs do not mention text in icons. **No icon test exists** (a DevForum request is open, nothing found to say it shipped) |
| Events | Each event can carry its own thumbnail; the docs recommend one "different from your experience thumbnails"; the event category "may be shown alongside your event thumbnail"; max 10 live or upcoming events; Home is not mentioned (experience-events.md) |
| Algorithm | PTR is the top-weighted Recommended-for-You signal; first-play bounce is negative; the window moved to 28 days on 2026-06-15 because short windows let "exciting thumbnails but shallow gameplay" displace better games (newsroom, summary). A temporary PTR drop while impressions rise at first discovery is normal (discovery.md) |

## 2. What creators and trade sources say (3rd, all anecdotal)

- **No numbers on style.** Searches for an A/B result with faces, text or colours returned none. One blog claims face-forward thumbnails beat scenic ones "in reported A/B results" and cites nothing. One generic YouTube-sourced claim (+20 to 30% for genuine emotion) is not Roblox data. I discard every "40% CTR lift" figure I saw (unsourced).
- **Grow a Garden:** an artist posted that a thumbnail "was used for A/B thumbnail testing for the game, and it did pretty well" (X, summary). A fan wiki page named "Thumbnails and Icons" is summarised as "all of Grow a Garden's thumbnails and icons contain text" (wiki, snippet).
- **Roblox's tool is a bandit.** A post from 2024 describes it as multi-armed-bandit testing that finds "what sort of image resonates" (X). A creator contest for a Claw Machine Simulator thumbnail let Roblox's tool pick the winner; the brief asked for eye-catching, "not misleading" (X).
- **One DevForum case:** a creator with a weak PTR was told the default-baseplate-and-sword thumbnail was the weakest of his set and to show an intense fight or scenic view that makes people curious about the gameplay. Another creator reported about 3.2% qualified PTR on the best thumbnail, improved after adding two more (summary; units unclear).
- **Tizzy_RBLX:** a transcript summary lists "test several thumbnails to improve click-through" among seven lessons (3rd). The okviky3 slideshow already in `media/tiktok/NOTES.md` says "nice thumbnails which also show and don't tell" and "good PTR thumbnails" (3rd).
- **Blogs (ForgeGUI, Moda, qptr.io, others; opinion):** one subject, one action, one mood; bold saturated colours that stand out against the white and grey Discover page; faces with clear exaggerated emotion; one to two characters, sometimes three; dynamic angle not flat head-on; if you need a word make it huge, remove text that cannot be read at about 150x150; put text on a thin outline or a bar; keep faces and text away from the bottom edge; before-and-after shots are a simulator staple; test at about 320 px wide. A tool, qptr.io, previews thumbnails on mobile, desktop and console Home layouts.
- **Not found:** BIG Games or any big studio saying anything about thumbnails; any YouTube creator's A/B table. The brief's searches for these returned only the sources above.

## 3. The questions, answered

**Describe or mystery?** Describe the moment, tease the payoff. Roblox's docs and staff post ("showcase your gameplay or content update", rewards thumbnails that match what players will play, warns that clickbait causes quick bounces, summary) point one way, and the June 2026 change makes a mismatched click cost you for 28 days. A pure mystery arm has no evidence for it on Roblox. A cute face plus a hook is fine because it is not a lie. *Confidence: medium (doc and newsroom, no test data).*

**Words: how often, how many, how big, what they say?** The only observed fact is that Grow a Garden uses its title on every thumbnail and icon (wiki snippet). Roblox says sparingly. No measured effect of word count exists. For us: zero or at most three words, one line, cap height at least 9% of the frame (about 100 px at 1080p, 10 px on a 192x108 test), which caps one line at about 12 letters, in the top third. What they should say: the moment ("PERFECT!"), the rarity ("LEGENDARY"), the hook ("WHO'S THAT?"), the update ("NEW WORLD"), because the tile already shows "Catch an Alien". A number: no evidence it helps on Roblox; use one only as a deliberate test (section 8). *Confidence: low on numbers, medium on placement (doc).*

**Does the first thumbnail differ from the second and third?** With 2+ active, Roblox picks per user group, so there is no single "first" on Home. The first image is the fallback and the lead of the detail-page gallery (and a video leads it if one is approved). Make the three differ by concept so the bandit has something to learn. Inactive images (up to 10 in all) only show in the detail-page gallery, which is where the ship and the collection belong. *Confidence: medium (doc).*

**Rarest pet or the catching moment? A face looking at the viewer? Several characters or one?** No data. The genre convention in collection games is the rare pet (3rd, recall); the moment is the thing no peer shows. Faces to the lens and one or two characters are the consensus (3rd). Our call: one hero, eyes to the lens, and we test moment against reward against mystery. *Confidence: low.*

**Composition for a small tile.** All heuristic: hero 55 to 75% of the frame height and 30 to 45% of the width, centred; essentials inside y 0.05 to 0.82 (the bottom 18% is the metadata band); saturated backdrop that is neither white nor pale; complementary hero and backdrop; navy outline at least 1.3% of the frame height on the hero; face and eyes large enough to read at 192x108 (each eye at least 5% of the frame width); text on the top third. Roblox adds: express mood through colour, test at 150x150. I measured our own set at 256x144 (section 7).

**Icon versus thumbnail.** The icon is the identity: square, 150 px, a prominent Home placement; it carries the face, no words. The thumbnail is the pitch: 16:9, the verb and the payoff. Which Home row uses which is not documented; "the first thumbnail" is the promotional image in various Home sections.

**Update cadence.** Roblox: change thumbnails with major updates, then hold. Big games swap with each update and event with an update name or a "NEW" or "UPDATE" tag (recall; Pet Simulator 99 numbers its updates, summary). The platform's own sticker is the event category beside an event thumbnail (doc). We hold the launch set a full week, then rotate one arm per update (World 2, Haunted Nebula's end, the first Frostbyte week).

**What should a brand-new game do differently?** See section 5.

## 4. The top games (recall: verify before relying on it)

I could not open one tile; no search returned a description of a thumbnail. These rows are what I remember of each game's art, each marked with how sure I am. "?" means I do not know. Treat the table as a hypothesis list for the phone check in section 11.

| Game | Describes or teases (recall) | Words | Hero | Render or in-game | Sticker | Confidence |
|---|---|---|---|---|---|---|
| Grow a Garden | Describes: a garden, crops, pets, bright | Title on every thumbnail and icon (wiki snippet); event name on event art | crops or a pet; a face? | stylised 3D render | event names | words: snippet; rest low |
| Steal a Brainrot | Teases: loud meme creatures | big title | a creature face | render | ? | low |
| Pet Simulator 99 | Rewards: one big rare pet, a logo, the update name | logo plus update name | a Huge pet, face to the viewer | polished 3D render | update tags | medium |
| Adopt Me | Describes: friendly pets and the new content | update name | pet faces to the viewer, pastel | soft 3D render | "NEW" on updates | medium |
| Fisch | Rewards: a giant fish and the angler | update name | the catch | render | update tags | low |
| Blox Fruits | Rewards: stylised characters and fruit powers | update name and number | an illustrated hero | 2D illustration; a forum snippet praises its thumbnail quality | update number | medium |
| 99 Nights in the Forest | Teases: dark forest, a creature | little text | a creature | render | ? | low |
| Dress to Impress | Describes: avatars in outfits | ? | avatars | render | ? | low |
| Rivals, Blue Lock Rivals | Describes: a duel or key art | title | characters | render or illustration | ? | low |
| Brookhaven | Describes: a house and the town | the name | a house | render | ? | low |
| Steal an Egg | ? (launched July 2026, after my solid recall; one snippet says Roblox removed it in late August, unverified) | ? | ? | ? | ? | none |
| Pet Catchers | Describes: cute pets to catch | logo | pets | render | ? | low |

What I take from it, only as a pattern to check: the top collection games show one big character with its face to the viewer in a polished render, with the logo or the update name as the only text, and an update sticker when there is something new. The icon repeats the same character close up.

## 5. A brand-new game with no players

- **No social proof.** The tile's rating and player count will be thin or empty for weeks, so the picture and the name are the whole sell. The picture has to say the verb and the cute at once. Our name already says "Catch" and "Alien"; the picture adds how (a bar, a timing moment) and why (cute, a rare glow).
- **No brand recognition.** A top game can run a mystery or a logo because players know it. We cannot; the hook must be visible without knowing us.
- **The click has to be honest.** The first-play bounce is a negative signal and counts Home-acquired players only (Growth-Playbook section 1). Our first catch is at 0:30; the Moment thumbnail promises exactly that.
- **Small traffic means few arms.** A bandit needs impressions; with little traffic three arms learn faster than five. Start with three; add the fourth with the first update.
- **A PTR dip at first discovery is normal** (discovery.md); do not react to day-one numbers.
- **Seed the same story elsewhere:** the 10 to 15 second clip that shows the catch moment, the group page, and the first creators ([[STORE-PAGE]] section 5c).

## 6. Our recipe (the first thumbnail set)

1. **One hero, one verb cue, one payoff.** A single alien, face to the lens, plus one thing that says what you do (the timing bar) or what you get (a rarity glow). Never five equal aliens.
2. **Size and place.** Hero 55 to 75% of the frame height, 30 to 45% of the width, horizontally centred (or on a third when text sits opposite). Face centre between y 0.35 and 0.55.
3. **Safe zone.** Every essential (face, bar, words, badge) inside y 0.05 to 0.82 and x 0.05 to 0.95. Feet, a ground ring or a shadow may drop into the bottom 18%.
4. **Eyes.** Both eyes visible, pupils to the lens, each eye at least 5% of the frame width, mouth open or smiling. Override the recipe's sly lids for the render only.
5. **Colour.** Mean saturation at least 0.40 and at most 15% pale pixels (saturation under 0.25 and value over 0.8); a backdrop that is mid to dark and saturated, not white and not pale; a complementary pair between hero and backdrop; a greyscale step of at least 40% in lightness between hero and backdrop; check at 256x144, 192x108 and in greyscale. The `DAY`, `WINTER` and `DUSK` sky tuples in `store_renders.py` are scene-linear values: (0.45, 0.72, 0.98) displays as a pale #B3DEFC, which is why the set looks washed out. Pick values from the hex-to-linear table in section 8.
6. **Outline.** Hero outline navy `1B1F3B`, 14 px at 1080p (1.3% of the height) minimum; the title outline 2.5% of the height (`store_title.py` default).
7. **Words.** Zero to three words, one line of at most about 12 letters, Fredoka One, cap height at least 9% of the frame (the Verdant title is about 8%), top third only, fill from the hero's rarity or role colour, navy outline. The words must add what the name does not. No FREE, Robux, codes, "best", "cute" (a subjective claim), no price.
8. **Real game only.** The capture bar with the Theme hexes and the tier's real zone widths (Rare: Good 0.26, Perfect 0.08 of the bar), the rarity colours, the "!" bubble, the Reveal's rays, models as they are in the game. No avatar with a net: the game has no held tool.
9. **Three concepts, one brand frame.** Moment, Reward, Mystery, all in the same navy outline, the same Fredoka title style and the same lighting direction, so a player who sees two of them knows it is one game. Hold the set seven days.
10. **Icon is the mascot.** Moop face, 75 to 85% of the frame, saturated dark violet backdrop, outline 3% of the width, no text, no ship, checked at 150 px, 64 px and in greyscale.
11. **Rotate with updates.** One arm per update, keep the current winner in the set, keep the rest of the story (ship, collection, world 2, Haunted Nebula) as inactive gallery images and as the video.

## 7. Scoring our current set against the recipe

Scored 0, 1 or 2 per line (icon on six lines). Measures are from the 1920x1080 files and 256x144 greyscale and colour contact sheets (scratch files only).

| Line | Verdant "CATCH CUTE ALIENS" | Legendary "LEGENDARY!" | Frostbyte "NEW WORLD: FROSTBYTE" | Icon Moop v2 |
|---|---|---|---|---|
| One hero | 0 (five equal) | 2 | 0 (five small) | 2 |
| Hero size | 0 (each 11 to 16% wide, 28% tall at most) | 2 (42% wide, 73% tall) | 0 (aliens 12 to 15% wide, 19 to 27% tall; the title block takes 42% of the height) | 2 (63% wide, 74% tall) |
| Eyes to the lens | 2 | 2 | 1 (small, white-on-white) | 2 |
| Colour and contrast | 1 (saturation 0.29, 26% pale; green alien on green ground, sun disc is a white dot) | 2 (saturation 0.43, 1% pale) | 0 (saturation 0.19, 42% near-white, white aliens on white snow) | 1 (saturation 0.20, 59% pale backdrop; alien reads at 64 px but the outline is 1% of the width, 1.5 px at 150 px) |
| Text rules | 0 (title sits in the bottom 16%, about 8% cap height, repeats the name, "cute" is subjective) | 2 | 1 (top, but a colon and two lines cover the spire) | 2 (none) |
| Shows the verb | 1 (word only) | 0 | 0 | n/a |
| Shows payoff or moment | 0 (a roster; the wreck hides behind the yellow alien) | 2 | 1 (a place) | n/a |
| Matches the live game | 1 | 0 (a ball with two antennae; the model is now a long-legged stag with blossoming antlers) | 1 | 1 |
| **Total** | **5 of 16** | **12 of 16** | **4 of 16** | **10 of 12** |

**Finding that needs a decision before the Mac renders anything.** The five store renders were committed in 27fc743 (2026-10-13, 04:06 -0400) from the pre-silhouette models: a ball body with one accessory (a crown, a knob, a pair of antennae). The silhouette pass (commits b95035c to c74d590, 17:44 to 17:49 -0400 the same day) rebuilt all 16 World 1 species: Moop is a mossy mound, Sparkfox a sitting fox with a paintbrush tail, Thunderhog a hedgehog with a lightning mane, Gaiabloom a stag, Puffpuff a dandelion starburst. Nothing is uploaded yet ("upload waits on Ethan", Board, job 24). Roblox needs the thumbnails to "accurately reflect your game". **Render from whichever model set is live on launch day.** If the silhouette models go up, re-render all five (the icon too); if they do not, render from the pre-silhouette GLBs (`git show b95035c^:assets/models/<Id>/<Id>.glb`, one per species, into a scratch folder, and point `--models` at it) or keep the current art.

Other notes from the small-size check: the Legendary frame is the only one whose hero still reads at 64 px; the Verdant title is the largest thing in its frame and the aliens are specks; the Frostbyte title covers the ice spire and the aliens' white bodies vanish into the snow. "NEW WORLD" means nothing to a stranger on day one (nothing was old); hold that frame for the World 2 update and, until then, if it must run, retitle it "FLY TO NEW WORLDS" (the ship arc is our difference) and give the aliens a darker snow shade and a saturated blue sky.

## 8. Three candidates for tomorrow (precise enough for `tools/blender/store_renders.py`)

**Shared.** 1920x1080, Cycles CPU, 96 samples, denoise, view transform Standard (as now). Camera lens 40 mm, sensor 36 mm wide: the frame is 0.9 x distance wide and 0.506 x distance tall, so for a hero of height H filling a fraction f of the frame, `distance = H / (f x 0.506)`. Outline 14 px via `outline(sc, 14)`. Add three functions `moment()`, `reward()`, `mystery()` following the existing `main()` pattern and a `--only` flag; do not change the existing outputs. Raw renders `thumb_moment_raw.png`, `thumb_reward_raw.png`, `thumb_mystery_raw.png`; finished `thumb_moment_v1.png`, `thumb_reward_v1.png`, `thumb_mystery_v1.png` in `media/store/2026-10-15/`. Title with `python3 -I tools/store_title.py RAW "TEXT" OUT --pos top --fill HEX`. The sky tuples are scene-linear; use these (hex then linear): indigo `101B5C` (0.005, 0.011, 0.107); blue `2F66D6` (0.028, 0.133, 0.672); meadow shade `1E4F2A` (0.013, 0.078, 0.023); violet top `2A1170` (0.023, 0.006, 0.162); violet bottom `9A5BE0` (0.323, 0.105, 0.745); night top `0F0B3A` (0.005, 0.003, 0.042); night bottom `4A2A9A` (0.068, 0.023, 0.323); night ground `2B2160` (0.024, 0.015, 0.117); Rare blue `3B82F6` (0.044, 0.223, 0.922); Legendary gold `F59E0B` (0.913, 0.342, 0.003); Codex purple `A855F7` (0.392, 0.091, 0.930); lamp gold `FFD36B` (1.0, 0.651, 0.147). Faces: the render-only variants are built in a scratch copy, never in the repo. Copy `tools/blender` and `assets/models` to a scratch folder, change the `face` dicts named below in the copy of `species_recipes.py`, run the copy's `species_bodies.py --species Sparkfox,Gaiabloom,Glimmo --models <scratch>/models`, add a `--models` argument to `store_renders.py` (it reads the module constant `MODELS`) and point it at the scratch folder. Nothing in `assets/models` changes and the variants are not committed.

### M. The Moment: `thumb_moment_v1.png` ("PERFECT!")

- **Subject:** Sparkfox (Rare), `import_model("Sparkfox", height=4.0, yaw=-8)`, standing at the origin, tail tip included. Frame fraction f = 0.58 (y 0.24 to 0.82, centre 0.53): `distance = 4.0 / (0.58 x 0.506) = 13.6`, pitch 4, yaw 0, target the bounds centre plus 0.2 in z (a higher target puts the hero lower in the frame), lens 40, no roll. No depth of field (everything crisp at tile size).
- **Face:** `lid` 0.0, `eye_tilt` 0, `look` (0, 0), `eye_scale` 1.3, `mouth` "o": wide awake, delighted, pupils to the lens. The recipe's sly half-lid goes.
- **Glow:** the tail's Accessory emission from 2 to 6 (the glowing tip is the "glowing Rare"); an emissive disc, radius 2.6 units, 2 units behind the fox, colour `BFE0FF` core (strength 4) with an emissive torus ring `3B82F6` (radius 2.9, minor 0.07, strength 8) at the same depth: the tier aura, Rare = blue. A Rare-blue area light behind-right (4000 W) for a rim.
- **Backdrop:** the meadow at night-dim: sky gradient indigo to blue (above), ground plane `1E4F2A` (the game dims the world by 60% in the capture screen), no trees, the CrashWreck small and dark at the back left only if it adds no clutter (skip it by default).
- **The bar (composited after the render, PIL, exact Theme hexes):** a pill 1152 x 76 px centred at (960, 800) (the game's bar is 0.6 of the width at y 0.80 and 0.06 tall; here 0.07 tall for legibility and lifted to y 0.74 so it clears the metadata band), fill `1B1F3B`, 8 px navy edge, soft shadow; the Good zone `51DF51` 26% of the bar wide (300 px, x 810 to 1110) and the Perfect zone `FFC83D` 8% (92 px, x 914 to 1006), both full height with 10 px corners; the ticker white, 14 px wide, 114 px tall, centred at x 977, navy outline 6 px, inside the Perfect zone; a 30 px soft gold glow round the Perfect zone (the near-miss flash in the real bar); a tier label "RARE" in `3B82F6` with a 5 px navy outline, 58 px cap height, centred at (960, 715). Rare's real zones are 0.26 and 0.08, so the bar is honest.
- **Text:** "PERFECT!" (the game's own feedback word, `CATCH_PERFECT`), `--fill FFEF4A`, `--width 0.50` (cap height about 12%), top. Nothing else; the verb "catch" is already in the name under the tile.
- **Player's hand:** none. The game has no held tool; a tap is the input. Do not add an avatar.

### R. The Reward: `thumb_reward_v1.png` ("LEGENDARY")

- **Subject:** Gaiabloom (Legendary), `height=6.0, yaw=12`, halo and ground ring included. f = 0.68 (y 0.24 to 0.92, centre 0.58): `distance = 6.0 / (0.68 x 0.506) = 17.4`, pitch 6, lens 40, target the bounds centre plus 0.7 in z. Antler blossoms reach y 0.24, clear of the title; the ground ring sits in the bottom band, which is fine for a non-essential.
- **Face:** `lid` 0.0, `eye_scale` 1.2, `look` (0, 0), `mouth` "smile": serene, wide-eyed, looking at the viewer.
- **Backdrop:** violet gradient `2A1170` top to `9A5BE0` bottom; a rotating-burst of 16 thin emissive triangles (alternating `FFD36B` and `FFF1B0`, strength 1.2) radiating from behind the head, 12 units long, the Reveal screen's rays; about 40 small emissive confetti quads (Rare blue, Epic magenta `C026D3`, green `57F96C`, gold `F59E0B`), each under 1.5% of the frame wide, none over the face. Rim lights: gold `F59E0B` area light behind-left 5000 W; Codex purple `A855F7` behind-right 4000 W.
- **Text:** "LEGENDARY", `--fill F59E0B`, `--width 0.52`, top. **No number in the base version**: no source shows a number helps on Roblox. **Number variant (the optional fourth arm, week 2):** the same render plus a round badge, Legendary gold with a navy outline, at (0.80, 0.30), 9% of the frame high, reading "1 OF 35" (35 aliens is the store description's count). It tells a stranger "a collection", and a collection count is something we can keep true; do not use odds ("1.5%") because they change and could read as a promotion.
- **In the alien's hand:** nothing. The gold halo and ground ring are the model's own.

### Y. The Mystery: `thumb_mystery_v1.png` ("WHO'S THAT?")

- **Subject:** Glim (id Glimmo; Common, a night-forest species with a glowing lamp) peeking from behind a rock, so the face is cute and the creature is the question. Place MeadowRock at (0.6, 2.2, 0), widened to about 5 units and scaled in z until its top edge is 1.5 units high (0.55 of Glim's 2.7), and Glim at (0.5, 3.4, 0), height 2.7, yaw 0, so the rock hides the skirt and both eyes sit above the edge. Camera: the head (the bell without the skirt) fills 45% of the frame width, `distance = bell_width / (0.45 x 0.9)` from `bounds()`, pitch 3, lens 40, target the eyes, shallow depth of field (focus on the eyes, f/1.8) so the wreck and ground melt.
- **Face:** the recipe's own (`eye_scale` 1.35, smile, `look` (0, 0.1)), slightly shy: raise `look` to (0, 0.15) and add `lid` 0.0. Both eyes at least 9% of the frame wide.
- **Light:** almost no sun (energy 0.3, blue `8FB0FF`); the lamp is the key: a point light 600 W `FFD36B` at the lamp, the lamp material emissive strength 8; a faint teal `5CE1E6` rim from behind-left, 1500 W. Night sky `0F0B3A` to `4A2A9A`, ground `2B2160`, about 25 emissive star specks in the top third, the CrashWreck dark at back left with one cyan window light.
- **The "!":** the game's own alert bubble: a gold `FFC83D` circle, 9% of the frame high, navy "!" and navy outline, above and right of the head at (0.70, 0.30). Composite with PIL.
- **Text:** "WHO'S THAT?", `--fill FFF4DC`, `--width 0.56`, top.
- **Why it is honest:** the design has a new species appear as a shadow silhouette with a "Who's that?" chime and the Codex shows uncaught aliens as silhouettes (GAME_DESIGN section 2, the first-sight row; section 16), and the "!" bubble is the real tap target (GAME_DESIGN section 7). Dim, do not black out the face: the cute must still land.

### Bonus: the Haunted Nebula event thumbnail

`docs/STORE-PAGE.md` lists `thumb_legendary_v2_title.png` for the Events row, but Gaiabloom is not an event species and the docs recommend an event thumbnail different from the experience set. Render Cosmoo (id Nebulyn, the Legendary track reward), Wispkin and Grin on a violet and teal sky with the gold star tail as the hero and "HAUNTED NEBULA" (two words, top, `--fill A855F7` or cream); no "NEW". This one serves the Events surface only.

### The icon, v3 (not requested, one paragraph)

Moop (id Mossbop), camera closer so the face fills 80% of the frame, pupils to the lens, backdrop a radial gradient `3B1E9E` to `7A3FD6` (lime on violet is the complementary pair), outline 3.2% of the width (33 px at 1024), one small gold sparkle, no ship, no text; check at 150 px, 64 px and greyscale. Moop is also the group name and emblem, so the mascot is consistent.

The four candidates as rendered on 2026-10-15, at the size of a Home-page tile (192 x 108; this is the phone-size row of section 11): the Moment, the Reward, the Mystery and the Haunted Nebula event. The full-size files are in `media/store/2026-10-15/`.

![[thumbs_192_strip.png]]

## 9. Which single thumbnail goes first

The Moment. A stranger has three seconds and no reviews, and the name tells them only "catch" and "alien"; the Moment is the only frame that shows how (a bar with a gold zone and a ticker) and why (a wide-eyed cute alien glowing in a Rare's blue) in one look. It matches the first minute (the first catch is at 0:30, [[Growth-Playbook]] section 6), so the click is honest and the first-play bounce does not punish it; and no peer shows a timing bar, so it separates us from every pet sim whose big-rare-pet frame we would otherwise copy. The Reward is the safest picture and the best purely at 64 px, and I expect it to win on pure tile reading, which is why it is the second active arm; the Mystery is the surprise arm. If the Moment's bar is unreadable in the 192x108 check (the bar should read as a dark pill with a green zone and a gold sliver), put the Reward first and the Moment second.

## 10. Test plan, and what to read

Cross-check from TikTok ZPLAkEnnf (machv10, 2026-10-21, `media/tiktok/NOTES.md` batch 9): his three CTR rules are this note's recipe in other words. "Keep it simple" is section 6 (one hero, zero to three words); "match the game name" is section 0 item 4 and section 9 (the name says catch and alien, the Moment shows both); "give a reason to click" is the three concept arms; "A/B test more than one thumbnail" is this section. Nothing to change; the block-cell set is the Launch-week row.

- Activate the three at launch (Creator Hub, Home Page tab, 2 to 5 active). The remaining story frames (the ship being built, the codex, Frostbyte) go in as inactive gallery images, in order, behind them; the video goes first on the detail page when the Mac's clip exists.
- Change nothing for seven days; the metric is a rolling 7-day value and the bandit re-weights hourly.
- Read, per thumbnail, qualified PTR **and** average playtime. A thumbnail with a high PTR and a short playtime is a clickbait arm; keep the one with both.
- Rule of thumb (generic A/B practice, not Roblox's): do not act on fewer than about 1,000 impressions per arm or a gap under about 20% relative. Replace only the weakest arm, with one change to the winning concept, and keep the winner in the set so it keeps most traffic.
- The icon has no test; rotate it by hand one change per two weeks and compare PTR across the same weekdays.

## 11. To verify (15 minutes, a phone, Ethan or the Mac)

Open the Home page and screenshot the top 30 tiles. For each, tick: describes or teases; word count and rough size; which row it is in (icon square or 16:9); reward, moment or a face; a character looking at the lens; render or in-game; the main two colours; an update or NEW sticker; how the icon differs from the thumbnail on the detail page; how many thumbnails the detail page rotates through. Then read section 4 against the screenshots and correct it. Also note the tile's pixel size on an iPhone SE (the design test size) and whether a video autoplays on Home.

## 12. Sources

doc (GitHub mirror of create.roblox.com, base `https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/`): `production/publishing/thumbnails.md`, `production/publishing/experience-icons.md`, `discovery.md`, `production/promotion/experience-events.md`. (`production/promotion/promotional-thumbnails.md` and `cloud/reference/features/thumbnail-personalization.md` returned 404 at that path.)

summary (search snippets of Roblox posts): newsroom "Optimizing Discovery" 2026-06 `https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox`; DevForum `.../t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233`, `.../t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665`, `.../t/get-your-thumbnails-ready-for-thumbnail-personalization/3226599`, `.../t/qualified-play-through-rate-best/3751740`, `.../t/other-thumbnails-still-getting-updated-with-stats-despite-being-removed/3897616`, `.../t/icon-ab-testing/3274267`, `.../t/how-to-get-playthrough-rate-up/4772142`; Bloxy News `https://x.com/Bloxy_News/status/1890113378766704674` (+12%, 8,000+ experiences). (All under `https://devforum.roblox.com` where abbreviated.)

3rd: `https://x.com/MouseyCherie/status/1916109631174414526` (Grow a Garden thumbnail A/B); `https://x.com/david_statter/status/1856758222473851350` (bandit); `https://x.com/DJMonopoli/status/1962876872691249333` (contest brief); `https://growagarden.fandom.com/wiki/Thumbnails_and_Icons` and `https://blox-fruits.fandom.com/f/p/4400000000000110597` (snippets only); `https://forgegui.com/blog/how-to-make-roblox-thumbnail-that-gets-clicks-2026`, `https://rowatcher.com/news/the-roblox-thumbnail-is-a-conversion-ad-stop-designing-it-like-art`, `https://qptr.io/thumbnails`, `https://moda.app/resources/sizes/roblox-thumbnail`, `https://sozai.app/transcript/roblox-game-earnings-lessons/` (Tizzy_RBLX summary); `https://massivelyop.com/2026/08/29/roblox-clamps-down-on-gen-ai-brainrot-scrolling-games-after-steal-an-egg-goes-viral/` (Steal an Egg status, unverified). In the repo: `media/tiktok/NOTES.md` (okviky3), `docs/vault/06-art-pipelines/Silhouette-Pass.md`, `tools/blender/store_renders.py`, `tools/store_title.py`, `src/client/UI/CaptureBar.luau`, `src/shared/data/Tiers.luau`.

## 13. Where this disagrees with Growth-Playbook section 2 (and STORE-PAGE section 4); left unedited for the owner

1. **Text that repeats the name.** The playbook's brief A overlays "CATCH ALIENS!"; the name chosen since (decision 19) is "Catch an Alien", printed under every tile. The overlay should add information (the moment, the rarity, the hook, the update). The playbook's "two to four words of huge outlined text" rests on two SEO blogs (S34); Roblox's text is "sparingly" and "only to describe gameplay context".
2. **Briefs B and C fail the one-subject rule at tile size.** The ship swarm (B) and the 4x3 codex grid (C) are many small subjects. They belong in the inactive gallery slots and the video; the Home arms should be one hero (section 8). C's idea survives as the single-silhouette Mystery.
3. **Honesty line.** The playbook says "every frame is an in-engine render of real features". The five renders on disk predate the silhouette pass and show the earlier ball-shaped aliens; the Legendary frame shows a ball with antennae, not the Gaiabloom stag (section 7). It holds only for whichever model set is live at launch.
4. **Icon.** The playbook asks for a "thick navy outline"; the v2 icon's outline is 1% of the width (1.5 px at 150 px), while [[Look-Plan]] L5b calls for about 6% for UI icons. The pale backdrop (59% pale pixels) is also against "colour and contrast for mood" in the icon docs. STORE-PAGE's "the ship in the corner" will not read at 150 px.
5. **Text position.** The titled Verdant frame puts its title in the bottom 16%, which the docs and the playbook's own rule ("text top-left or top-right") say not to do; the file is the first of the three in the dashboard run sheet.
6. **Numbers in the personalization row.** The playbook's "+8.5% (summary)" is now doc tier (it is in `thumbnails.md`, with "some games +50%"); newer figures are +12% over 8,000+ experiences and +0.19% for the winner-memory update (both summary). No contradiction, only a tier change.
7. **"The first one is the one the tile shows"** (STORE-PAGE section 4) and "up to 5": with two or more active, Roblox picks per user group and the first image is only the fallback and the gallery lead; up to 10 images or videos show on the detail page and 2 to 5 take part in personalization.
8. **"A video autoplays on Home"** (STORE-PAGE section 5c; [[Growth-Playbook]] section 1 says only that the Moments tab shows videos): the docs say a video "can also be shown on the Home page" and are silent on autoplay. I found no page that confirms autoplay or states a Home tile size.
9. **The Events row** (STORE-PAGE section 5d) reuses the Gaiabloom frame for Haunted Nebula; the docs recommend an event thumbnail distinct from the experience set (section 8, bonus).
10. **"CATCH CUTE ALIENS" and "LEGENDARY!"** The docs bar "subjective claims"; "cute" is borderline, "Legendary" is an in-game rarity and fine.
11. **The A/B wording.** [[Look-Plan]] L6 says "tested with Roblox's thumbnail A/B feature": it is personalization, a per-user-group bandit with a hourly re-weight, not an equal split; read it per section 10.

## 14. The block-cell launch set (2026-10-22, B49)

The 2026-10-14 and 10-15 sets show the retired ball-shaped aliens, so the launch set was redone in block cells as options for Ethan: icons A to C and thumbnails 1 to 6 in `media/store/2026-10-22/`, labelled in `choices.jpg` ([[STORE-PAGE]] section 4). One command renders it from whatever `assets/models/` holds: `$BPY tools/blender/store_renders.py --set 2026-10-22` (`--only A,3` for some options). How it is built, and what the first passes taught:

- **Render in Blender, finish in Pillow.** `tools/blender/store_blocky.py` places the exported GLBs in the generated worlds (`world_preview.build`) with film transparent, and renders two cheap held-out passes per shot (the hero's alpha, the cast's alpha). `tools/store_blocky_compose.py` paints the sky behind, adds bloom (Cycles has none), a tier-coloured aura behind the hero, the navy outline from the masks (1.4% of the frame height on a thumbnail's hero, about 2% on an icon so it survives 64 px, 5 px on the cast) and the 2D overlays.
- **Skies, bursts and UI are drawn in whole cells**: the sky a stepped band gradient with jittered cells, star cells, block clouds, a pixel moon, aurora curtains of cells; the capture bar and the reveal card follow the UI Playbook's block plate (corner cells cut, navy ink, lit top row, grout). A smooth gradient beside block-cell aliens reads as another game (B44).
- **Glow**: the rare pass made the high tiers mostly glow cells; boosting emission blew Raddis out to a white blob. Keep the GLB's emission, light the face with a soft area light from the camera side, and let the compose bloom only the pixels over 0.8 luminance. An aura must sit behind the hero only (multiply by one minus its mask), or it washes the face.
- **Framing in a generated world**: find the spot on a top view first (`world_preview` with an ortho camera and a 20-stud marker grid), clear the placed props within a few studs of the camera, and keep the hero 6 to 10 studs out; a forest view needs a low camera (1.5 studs above the path) and an 18 mm lens to get the hero and a landmark 45 studs up in one frame.
- **Scenic shots (S1 to S3, Ethan's brief "the most beautiful version of the world")**: a vista needs a near ledge for the aliens. The camera's height over the ground the aliens stand on sets their size (a 3-stud alien with feet above the bottom fifth is about 3 x tan(depression) / (2 x height x tan(half the vertical field)) of the frame), so a camera 8 studs over a plateau rim gives 12 to 15% aliens and still sees the meadow beyond the rim; from 20 studs up they shrink to dots. `place_cast` stands each alien by frame column and distance and prints where it landed and whether terrain hides it.
- **Aerial haze from a depth pass**: one extra 4-sample render with a material override (camera distance over `far`, 16-bit grey, the sky white) lets compose fade each column towards its own sky colour just over the horizon. It is what makes a block-cell vista read as deep instead of flat; 0.3 to 0.4 at the far plane is enough.
- **Two worlds in one frame**: build both generated worlds in one scene, shift the second, clip both along a real seam (World 1's meadow river) in 2-stud strips with the cut face closed, and light each with its own sun through Cycles light linking (a warm day sun on World 1 and its aliens, a cool moon on Frostbyte). The sky blends day into aurora night in whole cell columns where the seam meets the horizon.
- **Sightlines in a dense forest**: the Starhollow's 115 moon trees hide the floating island from any path-level camera; S2 removes the few trees a ray fan to the island hits (printed), and the Mac's check judges whether that keeps it honest.
- **The face frame**: the GLB's face plate maps frame 0 of the face sheet; a store render can show another frame (a glint, an iris-cycle frame) by moving the plate's UVs by the frame's column and row (`notes.md` names the frames and the columns).
