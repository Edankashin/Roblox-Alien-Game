---
tags: [game-design, species, research, decision]
aliases: [Species names, Mossbop, Moop]
up: "[[Game-Design]]"
---
# Species names: the study, the rules and the candidates

Status: second pass, **applied on 2026-10-14**. Ethan took the top picks; the collision screen below swapped five of them (Shardwing, Twiddle, Floof, Bunbun, Ember) and `Species.luau` `name` now carries the result. Ids are untouched. The group is named Moop Games. The first pass (the afternoon of 2026-10-14) is kept at the bottom of this note.

Ethan's feedback on the first sheets: the names should not all end in o or y, they should differ from each other in that way too, and the designs and names of the top games with the same hook (Pet Simulator, Steal an Egg) are the place to look. The first pass picked 12 of 35 names ending in o or y (Pebbo, Glowby, Twiggy, Puffbo, Newtsy, Fluffo, Drippo, Chippo, Kettlo, Toboggy, Flapsy, Toasty). This pass studies the games, writes a rule set from what they do, and rebuilds all 35 species under it. The picture sheets are `media/names/sheet_world1_v2.png` (World 1 plus the three Haunted Nebula aliens) and `media/names/sheet_world2_v2.png`, drawn from the tables below by `tools/names_sheet.py`; `python3 -I tools/names_check.py` checks every rule below on the A column, the B column, the C column and the "My pick" mix.

## What the top games do (the study)

How the sample was made: roblox.com is blocked from the sandbox, and so are the wiki pages a fetch could reach, so these lists come from web-search summaries of fan wikis and guide sites (Fandom, Beebom, Eldorado, Pocket Tactics, ProGameGuides, Esports.gg and similar) read on 2026-10-14. Names are spelled as those pages spell them; the pages disagree on rarities, prices and some spellings, which does not matter for naming and was not checked in game.

| Game | Names in the sample |
|---|---|
| Pet Simulator 99 (BIG Games) | Lucky Cat, Keyboard Cat, Rave Crab, Ice Cream Cone, Pixel Corgi, Pixel Griffin, Hippomelon, Axolotl, Cupcake, Quartz Fox, Scribe Squirrel, Empyrean Owl, Leprechaun Kitsune, Dawn Phoenix, Atlantean Orca; the same pets again as Huge, Titanic and Gargantuan forms |
| Adopt Me | Frost Dragon, Bat Dragon, Shadow Dragon, Frost Fury, Evil Unicorn, Diamond Unicorn, Giraffe, Crow, Kangaroo, Flamingo, Albino Monkey, Snow Owl, Arctic Reindeer, Golden Mummy Cat, Golden Lady Bug; each again as Neon and Mega Neon |
| Steal a Brainrot | Noobini Pizzanini, Lirili Larila, Tim Cheese, Fluriflura, Svinina Bombardino, Trippi Troppi, Bandito Bobritto, Cappuccino Assassino, Tung Tung Tung Sahur, Tralalero Tralala, Bombardiro Crocodilo, Brr Brr Patapim, Los Tralaleritos, La Vacca Saturno Saturnita |
| Steal an Egg | Chicken, Duckling, Catfish, Jerboa, Sand Spider, Mammoth, Brr Brr Patapim, Trulimero Trulicina, Tralaledon, Lava Dragon, Cosmic Dragon, Skeletal Sabertooth, Phoenix, Kitsune, Cerberus, Unicorn, Mosasaurus, Dodo |
| Grow a Garden | Raccoon, Red Fox, Dragonfly, Golden Dragonfly, Kitsune, Disco Bee, Queen Bee, Praying Mantis, Echo Frog, Blood Kiwi, Blood Hedgehog, Ice Serpent, Golden Goose, Polar Bear |

What the sample shows:

1. **A real animal is the base of nearly every name, and the games get their sound variety from the animals.** Cat, Fox, Owl, Crow, Orca, Giraffe, Axolotl, Unicorn, Crab end in very different sounds. Outside the brainrot names (62 names) the last letters spread over 15 different letters (n 13, e 9, and t, l, x, y, g 4 each); only 7 of 62 end in o or y. We cannot use a plain animal, so the variety has to be built into invented words, which is why the first pass collapsed into -o and -y.
2. **One flavour word in front of the animal.** 35 of the 62 are two words, a flavour word then a creature: Frost Dragon, Bat Dragon, Shadow Dragon, Evil Unicorn, Lava Dragon, Cosmic Dragon, Sand Spider, Snow Owl, Arctic Reindeer, Red Fox, Queen Bee, Disco Bee, Blood Kiwi, Echo Frog, Ice Serpent, Quartz Fox, Pixel Corgi, Keyboard Cat, Lucky Cat, Rave Crab. The flavour word is a biome or element (Frost, Lava, Sand, Snow, Arctic, Cosmic, Ice), a mood (Shadow, Evil, Blood, Echo), a party or object joke (Rave, Disco, Keyboard, Pixel, Ice Cream) or a luck or royalty word (Lucky, Queen). It is one short word and the animal is always the last word, so the name tells you the world and the joke in two beats.
3. **Rank is a prefix ladder on top of the same name.** Huge, Titanic, Gargantuan (Pet Simulator), Golden, Rainbow, Shiny, Neon, Mega Neon (Pet Simulator and Adopt Me), Golden Dragonfly and Golden Goose (Grow a Garden). The base name never changes, so it never has to carry rarity. We already show rarity with the tier colour and badge, so our names carry no rank word and no tier suffix.
4. **The top rarities reach for one known mythic word.** Dragon, Phoenix, Unicorn, Kitsune, Cerberus, Griffin, Serpent, Mosasaurus: in Steal an Egg the Unicorn and Kitsune are Divine, the Phoenix and Lava Dragon Eternal, Cerberus and Cosmic Dragon Secret. One big word is what the top of the ladder sounds like. We need coinages for that slot, not those words (Gaiabloom, Skaddle).
5. **Brainrot names are rhythm before meaning.** Reduplication and echo (Tung Tung Tung Sahur, Tralalero Tralala, Lirili Larila, Trippi Troppi, Brr Brr Patapim), Italian-sounding endings (-ino, -ini, -ero, -ito: Cappuccino Assassino, Noobini Pizzanini, Svinina Bombardino, Bandito Bobritto), and a mashup of an animal with an object or a food (Bombardiro Crocodilo, Cappuccino Assassino). They run 6 syllables on average and up to 10, and 8 of 14 end in a or o. Take the bounce and the repeat in one short word (Bunbun, Flapflap, Puffpuff), never the length.
6. **Blends and baby suffixes are rarer than you would think.** Hippomelon (hippo and watermelon), Fluriflura, Trulimero Trulicina, Dragonfly, Catfish and Duckling are the nearest to our shapes 3 and 6. The -let, -kin, -ling, -bit family comes from the collecting-game tradition rather than from this sample, so it is ours to keep varied.
7. **Length.** Outside brainrot the average name is about 3 syllables (2.9 to 3.5 per game) and the longest is 5 (the one exception is Steal an Egg's brainrot crossover, Trulimero Trulicina, at 8); the base animal alone is 1 to 4 (Cat, Fox, Hippomelon). Our commons stay 1 or 2 syllables, rares and up 2 to 4, all under 11 characters.

## Our rules

- **An original roster.** No name from the sample above, no real-game name, no real animal on its own. The trademark check is from memory only, as in the first pass; run a Roblox catalog and USPTO check on the final pick before the store page.
- **Tier is a voice, not a suffix.** The first pass gave each tier an ending family (-oop, -ble, -kit, Zap-); that is what made the names collapse into o and y. Now the tier only sets how the name sounds:

| Tier | Voice | Hard consonant | Length |
|---|---|---|---|
| Common | soft: m, p, b, f, l and round vowels; one or two syllables; no x, z, q, no hard c, at most one k | none | 3 to 10 letters |
| Uncommon | a wiggle in the middle, doubled consonants, a funny sound | optional | 4 to 10 |
| Rare | a spark or a clipped hit | one, somewhere | 6 to 10 |
| Epic | bigger energy, still warm | one, louder | 4 to 10 |
| Legendary | grand and warm, with an echo of a myth | yes | 6 to 9 |
| Cosmic | grand and a little cheeky, the echo is the joke | yes | 5 to 9 |
| Secret | mythic and mischievous | yes | 7 to 9 |
| Event | Haunted Nebula only: spooky-cute, a soft boo, never scary | as its tier | |

- **Seven shapes, every one used.** Each species slot has one shape, and its A, B and C are three names in that shape, so any mix of letters keeps the shape rules.

| # | Shape | Reads as | In the A column |
|---|---|---|---|
| 1 | monosyllable or near | a sound you can say with one breath | Moop, Glim, Fluff, Drip, Grin, Ember |
| 2 | reduplication | the brainrot bounce | Puffpuff, Bunbun, Flapflap |
| 3 | diminutive suffix (-let, -kin, -ling, -bit, -et) | small and dear | Pebblet, Buzzbit, Wispkin, Digling, Kettlet, Fenrikin |
| 4 | compound of animal and feature | the Frost Dragon move | Lanternewt, Rocklobber, Thunderhog, Trillgoat, Shellberg, Toastoad, Achoocub |
| 5 | hard-consonant cool ending (-k, -x, -nch, -ng) | the Lynx and Phoenix move | Zapfinch, Sparkfox, Shardwing, Glintelk, Auralynx |
| 6 | nonsense-cute blend | the Hippomelon move | Twiddle, Snibble, Ra-dish, Cosmoo, Pengoo, Capybubble |
| 7 | grand single word, Legendary and up | one big word | Gaiabloom, Skaddle |

- **The quotas, checked by script.** Within a world no ending (last two letters) is on more than 3 species. Across a tier within a world there are at least three different shapes (all different when the tier has fewer than three species). No two species in the same biome share a shape. Commons stay short and soft, rares and up carry a harder consonant, every name is under 11 characters, pronounceable by an eight-year-old, unique among every candidate and every current name, and never a real animal on its own.
- **Two honest exceptions.** The Meadow holds 8 species and there are 7 shapes, so one shape must repeat there: Thunderhog and the Secret goat are both compounds, three tiers apart. The three Haunted Nebula aliens are checked as their own group of three different shapes, because with them the Meadow would hold 9. Panpipe and Fenripup are out: neither has a hard consonant, which the Secret and Cosmic tiers now need, so their echoes return as Trillgoat, Pangoat, Fauntrick and Fenrikin, Fenrilet.
- **Moop stays for the moss ball.** It is a monosyllable with the round "oo" of moss, it is unique, and it is the face of the store page and the group emblem already. The alternatives I tried are weaker: Bop is the creature's voice line (it stays as B), Mush is porridge, Boop is Betty Boop, Mooch means freeloader, Glom is a verb for grabbing.
- **Haunted Nebula stays spooky-cute** (Wispkin, Grin, Cosmoo: a flame, a pumpkin smile, a star-cloud) and **Frostbyte stays chilly** (Fluff, Bunbun, Glintelk, Achoocub, Auralynx, and the geyser pair Kettlet and Ember for the warm pools).

## Second pass: the candidates

A is the best fit for the species and its tier voice, B keeps a hint of the current name (or is the current name where it already fits the rules), C is a wild card. The Shape column is the shape number all three share. "My pick" is one opinion; Ethan chooses. Where a pick is its own current name the species keeps it.

### World 1 Verdant and the Haunted Nebula event

#### World 1 Verdant, Common: soft and short

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Mossbop | Mossbop | Moop | Bop | Mush | A Moop | 1 |
| Pebblet | Pebblet | Pebblet | Pebbling | Rubblet | A Pebblet | 3 |
| Glimmo | Glimmo | Glim | Glow | Glub | A Glim | 1 |
| Twiglet | Twiglet | Twiddle | Twiggle | Sprigle | B Twiggle | 6 |
| Puffpuff | Puffpuff | Puffpuff | Pompom | Wishwish | A Puffpuff | 2 |

#### World 1 Verdant, Uncommon: a wiggle in the middle

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Snailbyte | Snailbyte | Snibble | Snailbert | Snurble | A Snibble | 6 |
| Buzzlebee | Buzzlebee | Buzzbit | Buzzlet | Honeykin | A Buzzbit | 3 |
| Lanternewt | Lanternewt | Lanternewt | Glownewt | Wicknewt | A Lanternewt | 4 |

#### World 1 Verdant, Rare: a spark and a hard edge

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Rocklobber | Rocklobber | Rocklobber | Rockclaw | Cragcrab | A Rocklobber | 4 |
| Zapfinch | Zapfinch | Zapfinch | Boltfinch | Beepwing | A Zapfinch | 5 |
| Sparkfox | Sparkfox | Sparkfox | Glowfox | Foxflick | A Sparkfox | 5 |

#### World 1 Verdant, Epic: bigger energy

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Thunderhog | Thunderhog | Thunderhog | Zaphog | Quillbolt | A Thunderhog | 4 |
| Gloomoth | Gloomoth | Shardwing | Gloomwing | Prismlux | C Prismlux | 5 |

#### World 1 Verdant, Legendary: grand and warm

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Gaiabloom | Gaiabloom | Gaiabloom | Gaibloo | Verdanta | A Gaiabloom | 7 |

#### World 1 Verdant, Cosmic: grand and a little cheeky

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Radish | Ra-dish | Ra-dish | Raydish | Raydiant | A Ra-dish | 6 |

#### World 1 Verdant, Secret: mythic and mischievous

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Panpipe | Panpipe | Trillgoat | Pangoat | Fauntrick | A Trillgoat | 4 |

#### Event, Haunted Nebula: spooky-cute

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Wisplet | Wisplet | Wispkin | Wisplet | Flickling | A Wispkin | 3 |
| Spookum | Spookum | Grin | Gloop | Gourd | A Grin | 1 |
| Nebulyn | Nebulyn | Cosmoo | Nebuzoo | Glimmoon | A Cosmoo | 6 |

### World 2 Frostbyte

#### World 2 Frostbyte, Common: soft and short

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Flufflet | Flufflet | Fluff | Floof | Mitt | C Mitt | 1 |
| Snowbun | Snowbun | Bunbun | Snowsnow | Thumpthump | B Snowsnow | 2 |
| Drippo | Drippo | Drip | Drop | Plip | A Drip | 1 |
| Chipmole | Chipmole | Digling | Chiplet | Digbit | A Digling | 3 |
| Kettlepuff | Kettlepuff | Kettlet | Steamkin | Whistlet | A Kettlet | 3 |

#### World 2 Frostbyte, Uncommon: a wiggle in the middle

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Pengoo | Pengoo | Pengoo | Pengwing | Tuxedoo | A Pengoo | 6 |
| Flapsicle | Flapsicle | Flapflap | Eekeek | Flitflit | A Flapflap | 2 |
| Toastoad | Toastoad | Toastoad | Toastfrog | Prunetoad | A Toastoad | 4 |
| Emberchin | Emberchin | Ember | Sizz | Burr | B Sizz | 1 |

#### World 2 Frostbyte, Rare: a spark and a hard edge

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Reindazzle | Reindazzle | Glintelk | Reinzing | Antlerix | A Glintelk | 5 |
| Shellberg | Shellberg | Shellberg | Bergshell | Slowberg | A Shellberg | 4 |
| Capybubble | Capybubble | Capybubble | Capybobble | Snorgle | A Capybubble | 6 |

#### World 2 Frostbyte, Epic: bigger energy

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Shimmerlynx | Shimmerlynx | Auralynx | Shimlynx | Purrlux | A Auralynx | 5 |
| Frostfang | Frostfang | Achoocub | Frostcub | Tuskpuff | A Achoocub | 4 |

#### World 2 Frostbyte, Legendary: grand and warm

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Skaddle | Skaddle | Skaddle | Skadowl | Skiowl | A Skaddle | 7 |

#### World 2 Frostbyte, Cosmic: grand and a little cheeky

| Id | Now | A | B | C | My pick | Shape |
|---|---|---|---|---|---|---|
| Fenripup | Fenripup | Fenrikin | Fenrilet | Moonling | A Fenrikin | 3 |

## My top pick per species

Ethan's choice, after the collision screen (its table is below); the "My pick" column holds exactly this list and `tools/names_check.py` checks it as a roster.

World 1 Verdant: Moop, Pebblet, Glim, Twiggle, Puffpuff, Snibble, Buzzbit, Lanternewt, Rocklobber, Zapfinch, Sparkfox, Thunderhog, Prismlux, Gaiabloom, Ra-dish, Trillgoat; the Haunted Nebula event: Wispkin, Grin, Cosmoo.

World 2 Frostbyte: Mitt, Snowsnow, Drip, Digling, Kettlet, Pengoo, Flapflap, Toastoad, Sizz, Glintelk, Shellberg, Capybubble, Auralynx, Achoocub, Skaddle, Fenrikin.

Before the screen the list had Twiddle, Shardwing, Floof, Bunbun and Ember in those five places.

## Notes on the picks

- The picks end in 16 different letters (t 6; e 4; p, x, g, n 3 each; m, h, o 2 each; f, r, w, d, z, k, b once) and none ends in y; the only two ending in o are the double o of Cosmoo and Pengoo. The first pass picked 12 names ending in o or y.
- Fourteen picks are their own current names because those names already satisfy the shapes, the endings and the hard-consonant rule: Pebblet, Puffpuff, Lanternewt, Rocklobber, Zapfinch, Sparkfox, Thunderhog, Gaiabloom, Ra-dish, Shellberg, Pengoo, Toastoad, Capybubble, Skaddle. The study says why they work: they are the Frost Dragon move (a flavour word and an animal) or the grand single word. The other 21 change.
- Sparkfox and Zapfinch are both "spark word and a bird or fox" and share shape 5, so they are the pair most likely to sound alike on a row; they sit in different biomes. Foxflick (C) and Boltfinch (B) pull them apart if Ethan wants the Rare row to sound more mixed.
- Trillgoat is the Secret goat: a trill for the reed pipes and a goat, with hard letters. Pangoat (B) keeps Pan; Fauntrick (C) is the mischief.
- Fenripup becomes Fenrikin (A): the Fenrir echo stays, a baby suffix makes it cheeky, and the k gives the Cosmic tier its hard letter. Skaddle keeps its echo of Skadi and is the only Legendary-or-up name that already passed.
- Shimmerlynx was 11 characters; Auralynx (A), Shimlynx (B) and Purrlux (C) fix that and keep the lynx ending.
- Sizz (B) is the urchin: a true monosyllable, the hiss of a hot pool. Ember (A) was the first pick and fell to the screen (Pixar's Elemental lead, a Skylanders character, a Steal an Egg pet). Mitt (C) is the snowball with mitten ears: Floof (B) is a Kirby enemy and a moldable-toy brand, and Fluff (A) is a Donkey Kong Country enemy, so the wild card is the one left. Mitt is the plainest pick on the list and the first to revisit if Ethan wants a cuter snowball.
- Twiggle (B) is the stick bug (Twiddle is a fidget-toy brand), Snowsnow (B) the snow bunny (Bunbun is a Mario enemy), Prismlux (C) the crystal moth (Shardwing is a Steal an Egg Secret pet and Gloomwing a D&D moth). All three kept their shape, so the quotas still hold.
- Event aliens: Wisplet is kept as B (it already passes), Wispkin (A) is the pick so that no two names on a row end in -let. Grin is the pumpkin smile, Cosmoo a cosmos with a boo in it. All three get a different shape.
- If Ethan mixes letters, run `python3 -I tools/names_check.py` after writing the picks into the "My pick" column; it reads that column as a roster of its own.

## Collision screen (2026-10-14)

Ethan's rule: every new name gets three searches, `"<name>" Roblox`, `"<name>" toy` and `"<name>" game character`, and anything that is an existing Roblox game or pet, a Pokemon, or a toy or character brand is swapped for that species' B or C. The searches were web-search summaries (the Roblox site itself is blocked from the sandbox), not a trademark register search, so this finds collisions a child or a reviewer would notice; it does not clear a filing. Swap rule used: swap on an exact match with a Roblox pet or game, a franchise creature or character (Nintendo, Disney, Skylanders, D&D) or a toy line; keep a plain dictionary word, a small indie or defunct item and a near-miss spelling, and flag the near-misses. The 14 unchanged names were not searched again (they passed the first-pass memory check).

Swapped out (the exact name is taken):

| Name | Species | What came up | Result |
|---|---|---|---|
| Shardwing | Gloomoth | A Secret-rarity pet in Steal an Egg (from the Shattered Rift Egg) | Swapped. B Gloomwing is a D&D and Pathfinder moth monster, so also out. C Prismlux is clean. |
| Twiddle | Twiglet | The Twiddle fidget toy (Twiddle Mega and others), Twiddle Turtle in a children's board game, a small Roblox horror game "Twiddle the Killer" | Swapped to B Twiggle |
| Floof | Flufflet | A Kirby enemy (Floof, Big Floof), the Floof moldable-toy brand, a picture book with a Floof plush, a Monster Hunter Stories NPC | Swapped. A Fluff is a Donkey Kong Country: Tropical Freeze enemy, so also out. C Mitt is clean. |
| Bunbun | Snowbun | A Super Mario Land enemy (Bunbun), the Aurora Rolly Pet Bunbun plush, the Bunbun & Bonbon graphic novels | Swapped to B Snowsnow |
| Ember | Emberchin | Ember Lumen (Pixar's Elemental), Ember in Skylanders Imaginators, Ember Dragon (Steal an Egg), Emberlight (Adopt Me), Ember plushies | Swapped to B Sizz |

Kept (nothing exact on Roblox, no Pokemon, no toy line):

| Name | Species | What came up | Result |
|---|---|---|---|
| Moop | Mossbop | Roblox: a group or two. Toy: the Kachooz pencil toppers, each called a Moop (the USPTO filings for KACHOOZ! were abandoned in 2011). Character: Moop in the 2002 point-and-click Moop and Dreadly, a moon spirit in an anime, the Moopies preschool app (monsters from planet Moop) | Kept, flagged: all obscure or defunct, nothing on Roblox, and it is the studio name. Run a USPTO check before the store page. |
| Glim | Glimmo | Glimmies (a different word), Glim Jim (a NICI firefly plush, two words), Glimmer in Xenoblade and Donkey Kong Country 2 | Kept |
| Twiggle | Twiglet | Twiglets (a UK snack), Twigg (a LEGO minifigure) | Kept (swapped in) |
| Snibble | Snailbyte | Nothing; a Scots dictionary word for a wooden knob | Kept |
| Buzzbit | Buzzlebee | Buzzbite, a Donkey Kong Country Returns enemy, one letter off; Buzz Bee Toys | Kept, flagged near-miss |
| Prismlux | Gloomoth | Nothing (Prism Runway Show and PrismAdmin are other words) | Kept (swapped in) |
| Trillgoat | Panpipe | Nothing | Kept |
| Wispkin | Wisplet | Nothing; wisps are items in Verse Piece and Fisch, Sonic's Wisps are another word | Kept |
| Grin | Spookum | No pet. Zuru's Fuggler "Grin Grin", a 2025 middle-grade horror novel and a 2026 horror-film clown named Grin, minor RPG NPCs | Kept, flagged: a plain word, none of it is a pet or a toy brand; the horror link is unrelated to a pumpkin smile |
| Cosmoo | Nebulyn | Nothing exact. Kosmoo, a Flemish children's series about a boy and his dog, sounds the same; Cosmo in Dandy's World and in Guardians of the Galaxy | Kept, flagged near-miss |
| Mitt | Flufflet | Nothing (Mr. Mittens in Pixar's Soul is another word) | Kept (swapped in) |
| Snowsnow | Snowbun | Nothing | Kept (swapped in) |
| Drip | Drippo | Roblox "drip" is avatar-fashion slang, not a pet. Drippy characters, the 2010 Drip Drops preschool toys | Kept (a plain word) |
| Digling | Chipmole | Nothing (Dig is a Roblox game, Diggles a 2001 game) | Kept |
| Kettlet | Kettlepuff | Nothing | Kept |
| Flapflap | Flapsicle | Flipflap, a Donkey Kong bat enemy, one letter off; the Flip Flap solar toy | Kept, flagged near-miss |
| Sizz | Emberchin | Nothing exact; Sizzlipede (Pokemon) and Sizzard (Dragon Quest) are other words, and Sizz is a Dragon Quest spell | Kept (swapped in) |
| Glintelk | Reindazzle | Nothing | Kept |
| Auralynx | Shimmerlynx | Nothing (the Auralyx Studios Roblox group and CrystaLynx toys are other words) | Kept |
| Achoocub | Frostfang | Nothing | Kept |
| Fenrikin | Fenripup | Nothing exact; two letters from the Pokemon Fennekin, built on Fenrir | Kept, flagged near-miss: B Fenrilet is the ready swap |

The four near-misses (Buzzbit, Cosmoo, Flapflap, Fenrikin) and Moop and Grin are the ones to put in front of a trademark search before the store page.

## Applied: id to display name

Ids never change (saves, `assets/models/<Id>/`, `ModelAssets`, spawn tables, dev commands such as `/spawn Mossbop`). The test script in `docs/TESTING.md` and the Studio queue name species by id in commands and by the old display name in some prose; screens now show the names below.

| Id | Name | Id | Name |
|---|---|---|---|
| Mossbop | Moop | Flufflet | Mitt |
| Pebblet | Pebblet | Snowbun | Snowsnow |
| Glimmo | Glim | Drippo | Drip |
| Twiglet | Twiggle | Chipmole | Digling |
| Puffpuff | Puffpuff | Kettlepuff | Kettlet |
| Snailbyte | Snibble | Pengoo | Pengoo |
| Buzzlebee | Buzzbit | Flapsicle | Flapflap |
| Lanternewt | Lanternewt | Toastoad | Toastoad |
| Rocklobber | Rocklobber | Emberchin | Sizz |
| Zapfinch | Zapfinch | Reindazzle | Glintelk |
| Sparkfox | Sparkfox | Shellberg | Shellberg |
| Thunderhog | Thunderhog | Capybubble | Capybubble |
| Gloomoth | Prismlux | Shimmerlynx | Auralynx |
| Gaiabloom | Gaiabloom | Frostfang | Achoocub |
| Radish | Ra-dish | Skaddle | Skaddle |
| Panpipe | Trillgoat | Fenripup | Fenrikin |
| Wisplet | Wispkin | Spookum | Grin |
| Nebulyn | Cosmoo | | |

## First pass (2026-10-14 afternoon)

Kept as it was: the ending-family scheme, 105 candidates and the rules they passed. The tier families here (Moops, Bibbles and the rest) are superseded by the voice table above, and these tables are not read by `tools/names_check.py`; `python3 -I tools/names_sheet.py --section "First pass" --suffix ""` redraws their sheets (`sheet_world1.png`, `sheet_world2.png`).

Status: candidates, waiting for Ethan's pick. Nothing in `src` has changed; the rename lands in `Species.luau` after he chooses.

Ethan's ask: the alien names are not cute enough. The common basic aliens of a world should be called Moops or something, and the names should change with the world's theme and the rarity. This note is the scheme, three candidates per species, and the picture sheets to choose from: `media/names/sheet_world1.png` (World 1 plus the three Haunted Nebula event aliens) and `media/names/sheet_world2.png`, made by `tools/names_sheet.py` straight from the tables below, so editing a name here and re-running the tool refreshes the sheet.

### What stays fixed

- Species ids never change. Saves, `assets/models/<Id>/` folders, `ModelAssets` and the spawn tables all key on the id. Only the `name` field of the row changes (the Ra-dish row already shows id `Radish` with name `Ra-dish`).
- Names are data in `src/shared/data/Species.luau`, not strings, so the rename is one data edit per species. Three more places say a name in words: `TUT_2` and `TUT_3` in `src/shared/strings/en.luau` ("A Mossbop wants to help!"), and the docs (`docs/GAME_DESIGN.md` roster table, the Store page and Group page notes). Run `./tools/test.sh`, `./tools/lint.sh` and `./tools/analyze.sh` after.
- Tone: warm and playful, a name an eight-year-old can say and giggle at. No reward words, no puns that sound like money or loot.

### The scheme: each tier is a family with its own sound

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

### Rules every candidate passed

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

### The three candidates

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

### My top pick per species

Moop, Pebbo, Glowby, Twiggy, Puffbo, Snibble, Buzzbee, Newtsy, Lobbit, Zapfinch, Sparkfox, Thunderhog, Glowmoth, Gaiabloom, Ra-dish, Panpipe; events Flickle, Pumpboo, Nebuloom; Frostbyte Fluffo, Snowbun, Drippo, Chippo, Kettlo, Toboggy, Flapsy, Toasty, Urchibble, Reindazzle, Shellberg, Capybubble, Auralynx, Achoocub, Skaddle, Fenripup.

### The grand ones: is there a cuter form that keeps the grandeur?

- Gaiabloom: no. The echo of Gaia is the whole point, and "Gaiabloom" already says earth and flowers warmly. Gaibloo is cuter and loses the echo; keep the original.
- Ra-dish: keep. The hyphen is the joke, and a kid who knows Ra gets it. Raydish is cuter and drops the hyphen pun; Sunnip is the wild card.
- Panpipe: keep. Billypan adds a goat but trades the instrument for a nickname; Faunlet is the wild card.
- Skaddle and Fenripup: keep. Both are already round and silly, with the echo (Skadi, Fenrir) intact; Skadowl and Moonpup are the safe cute cousins.
- Frostfang is the one Epic whose name is not cute. Achoocub (it sneezes snowflakes) is the pick; Frostcub is the quiet alternative.

### Event species (Haunted Nebula)

Wisplet, Spookum and Nebulyn are close already, so the alternatives stay near them: a boo or a flicker in the name, never a scary word. They hold their tier's rarity colour but use the spooky-cute sound instead of their tier's family.

### Applying the pick

1. Ethan names the letter per species (for example "Mossbop B, Pebblet A, rest as your pick").
2. One edit per row in `src/shared/data/Species.luau`: only `name`. Do not touch `id`.
3. Fix `TUT_2` and `TUT_3` in `src/shared/strings/en.luau` and the roster table in `docs/GAME_DESIGN.md`.
4. Re-run `python3 -I tools/names_sheet.py` if the tables change; log the decision in [[Decisions]].

See also [[Group-Page]] and [[Growth-Playbook]] (the Mossbop mascot is the icon, so Moop is also the face of the store page and the group emblem).
