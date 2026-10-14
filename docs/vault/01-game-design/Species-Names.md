# Species names: the scheme, three candidates each, and the picture sheets

Status: candidates, waiting for Ethan's pick. Nothing in `src` has changed; the rename lands in `Species.luau` after he chooses.

Ethan's ask: the alien names are not cute enough. The common basic aliens of a world should be called Moops or something, and the names should change with the world's theme and the rarity. This note is the scheme, three candidates per species, and the picture sheets to choose from: `media/names/sheet_world1.png` (World 1 plus the three Haunted Nebula event aliens) and `media/names/sheet_world2.png`, made by `tools/names_sheet.py` straight from the tables below, so editing a name here and re-running the tool refreshes the sheet.

## What stays fixed

- Species ids never change. Saves, `assets/models/<Id>/` folders, `ModelAssets` and the spawn tables all key on the id. Only the `name` field of the row changes (the Ra-dish row already shows id `Radish` with name `Ra-dish`).
- Names are data in `src/shared/data/Species.luau`, not strings, so the rename is one data edit per species. Three more places say a name in words: `TUT_2` and `TUT_3` in `src/shared/strings/en.luau` ("A Mossbop wants to help!"), and the docs (`docs/GAME_DESIGN.md` roster table, the Store page and Group page notes). Run `./tools/test.sh`, `./tools/lint.sh` and `./tools/analyze.sh` after.
- Tone: warm and playful, a name an eight-year-old can say and giggle at. No reward words, no puns that sound like money or loot.

## The scheme: each tier is a family with its own sound

| Tier | Family | The sound | Roots and endings |
|---|---|---|---|
| Common | the Moops | baby names, one or two syllables, round vowels (oo, o, u), soft consonants (m, p, b, f) | -oop, -o, -y, -bo: Moop, Pebbo, Chippo |
| Uncommon | the Bibbles | a little more character, doubled consonants, a wiggle in the middle | -ble, -bee, -sy: Snibble, Buzzbee, Newtsy |
| Rare | the Sparks | a glow or spark word plus the animal, two beats | Spark-, Gem-, Gleam-, Glim-, -kit, -claw: Sparkit, Gemclaw |
| Epic | the Zaps | bigger energy, still warm: the glow word gets louder | Zap-, Thunder-, Glow-, Prism-, Aura-: Zaphog, Glowmoth, Auralynx |
| Legendary | the Wardens | grand and warm, one word or a gentle compound, keeps the myth echo | Gaiabloom, Skaddle |
| Cosmic | the Star-born | grand, a little cheeky, the echo is the joke | Ra-dish, Fenripup |
| Secret | the Chimeras | the Set reward: mythic and a touch mischievous | Panpipe |
| Event | spooky-cute | Haunted Nebula only; a soft boo, never scary | Pumpboo, Gleamwisp, Nebuloom |

Each world flavours the roots, so a Moop from Verdant and a Moop from Frostbyte sound like cousins, not twins:

- World 1, Verdant: earthy, mossy, buzzy. Roots from moss, pebble, twig, puff, glow, newt, bee. Soft m, p, b, and the "oo" of moss.
- World 2, Frostbyte: chilly and fluffy. Roots from fluff, drip, chip, mitt, steam, snow, berg. Cold f, ch, dr, with a puffy o.
- Later worlds follow the same two moves: keep the tier's ending, swap the roots for the world (Neon Grid: bleep, zip, wire; Emberfall: cinder, toast, pop).

Length follows rarity too: a Common is short (4 to 7 letters), a Warden may take 9 or 10.

## Rules every candidate passed

- Under 11 characters (10 at most).
- Pronounceable by an eight-year-old, one obvious reading.
- Unique across the roster: all 105 candidates are different from each other and from every other species' current name (checked by script, case-insensitive). A candidate may equal its own species' current name where that name already fits ("Sparkfox can stay").
- No profanity risk as a word, a start, or a join (so no "Poo-", "Toot", "Hang-", "Prick-" forms).
- No trademarked creature name. I checked the obvious ones from memory, not by a trademark search: Pokemon, Adopt Me, Pet Simulator, Grow a Garden pets, Kirby, Pikmin, Mario and Zelda enemies, Sonic, Smurfs, Sanrio, Squishmallows, D&D, Minecraft. Before a name ships on the store page (not before it goes into the game), run a quick Roblox catalog and USPTO check on the final pick.

Dropped on the way, so nobody re-proposes them:

| Name | Why not |
|---|---|
| Puffo | The Italian name for a Smurf |
| Pengu | One letter from Pingu |
| Tux | The Linux penguin |
| Waddle, Scarfy | Kirby enemies |
| Flicky | A Sega bird |
| Tortle | A D&D tortoise race |
| Bumble | Bumblebee and the app |
| Mopsy, Boop, Snoofy | Peter Rabbit, Betty Boop, Snoopy |
| Glowbo | Probably a toy line; Glowby is clear |
| Toot-, Hang-, Prick- forms | Kid-slang risk |

Closest calls that stay in: Twiggy (a nickname of a famous model, not a creature), Lobbit (rhymes with Hobbit but is its own coinage; Clawbub is the safe twin), Sparkit, Moop (also the Burning Man acronym, which no eight-year-old knows). Flag them to the final check.

## The three candidates

A is the cutest literal fit for the scheme. B keeps a hint of the current name (or is the current name where it already fits). C is a wild card. "My pick" is one opinion; Ethan chooses.

Shimmerlynx is 11 characters, over the limit, so it changes whichever way the pick goes.

### World 1 Verdant

#### World 1 Verdant, Common: the Moops

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Mossbop | Mossbop | Moop | Mossy | Mooshy | A Moop |
| Pebblet | Pebblet | Pebbo | Pebbly | Cobbo | A Pebbo |
| Glimmo | Glimmo | Glowby | Glimmy | Jellibo | A Glowby |
| Twiglet | Twiglet | Twiggy | Twigbo | Sprigo | A Twiggy |
| Puffpuff | Puffpuff | Puffbo | Puffy | Wishoo | A Puffbo |

#### World 1 Verdant, Uncommon: the Bibbles

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Snailbyte | Snailbyte | Snibble | Snailby | Cogsy | A Snibble |
| Buzzlebee | Buzzlebee | Buzzbee | Buzzle | Bimble | A Buzzbee |
| Lanternewt | Lanternewt | Newtsy | Lantsy | Glimble | A Newtsy |

#### World 1 Verdant, Rare: the Sparks

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Rocklobber | Rocklobber | Gemclaw | Lobbit | Clawbub | B Lobbit |
| Zapfinch | Zapfinch | Zapchirp | Zapfinch | Beepwing | B Zapfinch |
| Sparkfox | Sparkfox | Sparkit | Sparkfox | Doodlefox | B Sparkfox |

#### World 1 Verdant, Epic: the Zaps

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Thunderhog | Thunderhog | Zaphog | Thunderhog | Quillbolt | B Thunderhog |
| Gloomoth | Gloomoth | Glowmoth | Gloomoth | Prismoth | A Glowmoth |

#### World 1 Verdant, Legendary: the Wardens

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Gaiabloom | Gaiabloom | Gaiabloom | Gaibloo | Verdanta | A Gaiabloom |

#### World 1 Verdant, Cosmic: the Star-born

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Radish | Ra-dish | Ra-dish | Raydish | Sunnip | A Ra-dish |

#### World 1 Verdant, Secret: the Chimeras

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Panpipe | Panpipe | Panpipe | Billypan | Faunlet | A Panpipe |

#### Event, Haunted Nebula: spooky-cute

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Wisplet | Wisplet | Gleamwisp | Wispy | Flickle | C Flickle |
| Spookum | Spookum | Pumpboo | Spookle | Floatkin | A Pumpboo |
| Nebulyn | Nebulyn | Nebuloom | Nebulyn | Cosmoo | A Nebuloom |

### World 2 Frostbyte

#### World 2 Frostbyte, Common: the Moops

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Flufflet | Flufflet | Fluffo | Fluffle | Mitto | A Fluffo |
| Snowbun | Snowbun | Bunbo | Snowbun | Bunnoop | B Snowbun |
| Drippo | Drippo | Drippy | Drippo | Dewbo | B Drippo |
| Chipmole | Chipmole | Chippo | Chipmo | Digbo | A Chippo |
| Kettlepuff | Kettlepuff | Steamo | Kettlo | Fweebo | B Kettlo |

#### World 2 Frostbyte, Uncommon: the Bibbles

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Pengoo | Pengoo | Pengsy | Pengoo | Toboggy | C Toboggy |
| Flapsicle | Flapsicle | Flapsy | Flibble | Eeksy | A Flapsy |
| Toastoad | Toastoad | Toasty | Toadle | Bathsy | A Toasty |
| Emberchin | Emberchin | Embersy | Urchibble | Spikle | B Urchibble |

#### World 2 Frostbyte, Rare: the Sparks

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Reindazzle | Reindazzle | Glimdeer | Reindazzle | Blinkdeer | B Reindazzle |
| Shellberg | Shellberg | Gemshell | Shellberg | Bergo | B Shellberg |
| Capybubble | Capybubble | Bubbara | Capybubble | Tangybara | B Capybubble |

#### World 2 Frostbyte, Epic: the Zaps

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Shimmerlynx | Shimmerlynx | Auralynx | Shimlynx | Purrora | A Auralynx |
| Frostfang | Frostfang | Frostcub | Frostfang | Achoocub | C Achoocub |

#### World 2 Frostbyte, Legendary: the Wardens

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Skaddle | Skaddle | Skaddle | Skadowl | Skiowl | A Skaddle |

#### World 2 Frostbyte, Cosmic: the Star-born

| Id | Now | A | B | C | My pick |
|---|---|---|---|---|---|
| Fenripup | Fenripup | Fenripup | Moonpup | Fenrilune | A Fenripup |

## My top pick per species

Moop, Pebbo, Glowby, Twiggy, Puffbo, Snibble, Buzzbee, Newtsy, Lobbit, Zapfinch, Sparkfox, Thunderhog, Glowmoth, Gaiabloom, Ra-dish, Panpipe; events Flickle, Pumpboo, Nebuloom; Frostbyte Fluffo, Snowbun, Drippo, Chippo, Kettlo, Toboggy, Flapsy, Toasty, Urchibble, Reindazzle, Shellberg, Capybubble, Auralynx, Achoocub, Skaddle, Fenripup.

## The grand ones: is there a cuter form that keeps the grandeur?

- Gaiabloom: no. The echo of Gaia is the whole point, and "Gaiabloom" already says earth and flowers warmly. Gaibloo is cuter and loses the echo; keep the original.
- Ra-dish: keep. The hyphen is the joke, and a kid who knows Ra gets it. Raydish is cuter and drops the hyphen pun; Sunnip is the wild card.
- Panpipe: keep. Billypan adds a goat but trades the instrument for a nickname; Faunlet is the wild card.
- Skaddle and Fenripup: keep. Both are already round and silly, with the echo (Skadi, Fenrir) intact; Skadowl and Moonpup are the safe cute cousins.
- Frostfang is the one Epic whose name is not cute. Achoocub (it sneezes snowflakes) is the pick; Frostcub is the quiet alternative.

## Event species (Haunted Nebula)

Wisplet, Spookum and Nebulyn are close already, so the alternatives stay near them: a boo or a flicker in the name, never a scary word. They hold their tier's rarity colour but use the spooky-cute sound instead of their tier's family.

## Applying the pick

1. Ethan names the letter per species (for example "Mossbop B, Pebblet A, rest as your pick").
2. One edit per row in `src/shared/data/Species.luau`: only `name`. Do not touch `id`.
3. Fix `TUT_2` and `TUT_3` in `src/shared/strings/en.luau` and the roster table in `docs/GAME_DESIGN.md`.
4. Re-run `python3 -I tools/names_sheet.py` if the tables change; log the decision in [[Decisions]].

See also [[Group-Page]] and [[Growth-Playbook]] (the Mossbop mascot is the icon, so Moop is also the face of the store page and the group emblem).
