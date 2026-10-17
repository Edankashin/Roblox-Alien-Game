# Rarity ladder and VFX in top Roblox pet games: what changes from Common to the rarest pet

Researched 2026-10-17. **Method caveat:** in this session WebFetch failed with a DNS error and curl got a proxy 403 for every page tried: pet-simulator.fandom.com, adoptme.fandom.com, create.roblox.com, devforum.roblox.com, biggames.io, esports.gg, u7buy.com and bloxinformer.com. Every finding below therefore comes from search-engine result summaries of the linked pages, not from reading the pages. Where a summary said "one source" without naming which result it came from, the note says so. Check any number on its page before it goes into a data table. Dates: "current" means the newest dated source found (2026). Older material is marked.

**Baseline (what the project already has, `docs/vault/01-game-design/Roster-Redesign.md` sections 1, 4 and 6):** tier scale 1.0 / 1.0 / 1.1 / 1.2 / 1.25 / 1.5 / 1.3 (Common to Secret), multiplied by a size roll of 0.75 to 1.35 and growth up to 1.16 (maximum 2.35x a Common). Effect layers climb from 0 to "everything": a light, then glow, emitter, orbit, ground ring, trail and beam. Overlays (Shiny, Gold, Crystal, Rainbow) recolour the glow slot and the aura. The plate ladder runs plain, coloured, outlined, shimmer, animated gradient, dark glyph. Reveal beats and the server banner start at Legendary. Faces run cute, then cool, then fierce, then spectacular. Mobile caps: 100 particles a second per emitter, 20 s lifetime, a 3,600 ceiling (the project uses 1,200) and 255 Highlights.

**What this research adds beyond that baseline (summary; details and sources in the sections below):**
1. **The top size steps in the reference games are large jumps, not 10 to 25 percent steps.** PS99 Gargantuan pets (since Update 39, December 2024) are 3x the size of Titanic pets. Titanic is reported as about 2x a Huge by one value site, and as about 3x by unofficial mesh scales (Huge 2, Titanic 6). Titanic and Gargantuan pets are ridable. Normal : Huge : Titanic : Gargantuan works out to about 1 : 2.7 : 8 : 24 on those unofficial scales. The project's ladder tops out at 1.5x by tier.
2. **The very top tier gets a ceremony for the whole server, or for every server.** A PS99 Gargantuan hatch plays a cutscene for everyone in the server: the sky darkens and the egg lifts. PS99's Hatch Wars update says the rarest hatches "blast into chat and every server". BGSI announces its top Secret variants to all servers without the hatcher's name.
3. **Variant finishes have concrete timings and limits.** Adopt Me's Mega Neon cycles its glow parts through the rainbow about every 1 to 3 s, and some species cycle only through their own palette. Steal a Brainrot's Rainbow cycles RGB while Gold and Diamond are flat recolours.
4. **A mark on the body.** Bee Swarm's gifted bees get a per-species new colour scheme, stained wings and a star on the back and sides, plus a glowing gold border on their hive slot.
5. **Traits as stackable VFX layers that are independent of rarity.** Steal a Brainrot's Fireworks trait fires a continuous multicoloured firework emitter, Nyan adds rainbow trails, and Taco puts a taco on the head.
6. **Engine facts to build around.** Particle count is Rate x Lifetime. `:Emit()` bypasses Roblox's automatic quality-level reduction. A burst of about 300 particles near the camera caused spikes of about 18 ms. Constraint-based or BulkMoveTo pet movement is used to keep many followers cheap.

**Composite ladder seen across the games (each row sourced below):**

| Step | Size | Finish / detail | VFX | Presence |
|---|---|---|---|---|
| Normal / Common | base | base colours | none | none |
| Coloured variant (PS99 Golden, SAB Gold/Diamond, GaG Golden) | same mesh | flat recolour (gold; SAB Diamond cyan) | none or a shine | none |
| Glow variant (Adopt Me Neon, BSS Gifted) | same mesh | glow on species-chosen parts in a fixed species colour (Neon); a new colour scheme, stained wings and a star mark (Gifted) | glow regions | gold slot border (BSS) |
| Cycling variant (PS99 Rainbow, Adopt Me Mega Neon, SAB/GaG Rainbow) | same mesh | hue cycle on the glow parts, about every 1 to 3 s (Mega Neon) | colour cycle | none |
| Sparkle variant (PS99 Shiny, BGSI Shiny) | same mesh | "shines" in the world and in the inventory | sparkle (the exact effect is not documented in the sources found) | coloured name (BGSI) |
| Scale class 1 (PS99 Huge; GaG Huge weight) | about 2.7x normal (unofficial mesh scale 2 against 0.75) | — | — | — |
| Scale class 2 (PS99 Titanic) | about 2x Huge (one value site), or 3x (unofficial mesh scale 6) | — | — | ridable |
| Scale class 3 (PS99 Gargantuan) | 3x Titanic (Update 39 guide) | variant shown on the pet | — | ridable; hatch cutscene for the whole server, with the sky darkened |
| Rarest announced tiers (BGSI Mythic/Shiny Mythic Secret, SAB Brainrot God, PS99 rarest hatches) | — | — | — | announced to every server or on spawn; BGSI omits the username |

## 1. Size and height: how much bigger are rare pets?

### Takeaway
In the top games the rarest pets are bigger in large, discrete jumps. PS99 stacks Huge, then Titanic (2 to 3x Huge, ridable), then Gargantuan (3x Titanic, ridable). That is about 24x a normal pet on unofficial mesh scales. Grow a Garden sorts pets into named weight classes and also has size mutations (Mega, Gigantic, Nightmare). Exact stud sizes are not published in any source found, and Bee Swarm's gifted bees do not change size in the sources found.

### Cited Findings
- **PS99 Titanic:** the PS99 wiki describes Titanic pets as "larger than huge pets in both size and power", "3x stronger than the player's best pets, and ridable" — [Titanic Pets (Pet Simulator 99), fandom](https://pet-simulator.fandom.com/wiki/Titanic_Pets_(Pet_Simulator_99)).
- **Older PSX version (about 2022 to 2023):** Titanic pets were "larger than huge pets in both size and power", "5x stronger than the player's best pets", and ridable — [Titanic Pets (Pet Simulator X), fandom](https://pet-simulator.fandom.com/wiki/Titanic_Pets_(Pet_Simulator_X)).
- **Size multiplier, Titanic to Huge:** a PS99 value site says Titanic-class pets are "roughly twice the size of Huge pets" and deal about 2x the damage of a player's strongest standard pet — [ps99wiki.com, Titanic Pixel Monkey](https://ps99wiki.com/pet/titanic-pixel-monkey/) (one of three ps99wiki Titanic pages returned; the summary did not say which one). A buyer's guide gives Titanic damage as 200% of the strongest standard pet — [U7BUY, Gargantuan vs Titanic](https://www.u7buy.com/blog/ps99-gargantuan-vs-titanic-pets/). These conflict with the wiki's "3x stronger".
- **Gargantuan, size multiplier (best source found):** Gargantuan pets were introduced in Update 39 (December 2024) and are "3x the size of Titanic pets". The guide's tier table lists Titanic as "Extra large" and Gargantuan as "3x Titanic" — [Dungeonpath, Huge and Titanic guide](https://dungeonpath.com/posts/pet-simulator-99/huge-titanic-guide/). The sibling note `blocky_visual_language.md` attributes the same "3x" wording to BIG Games' own Update 39 post ([biggames.io, Update 39](https://www.biggames.io/post/pet-simulator-99-update-39); not opened here).
- **Gargantuan is still released in 2026:** Update 85 (Tap Gauntlet, 18 July 2026) added a Gargantuan Samurai Kitsune alongside Titanic and Huge pets — [holdtoreset, PS99 update log](https://holdtoreset.com/pet-simulator-99-updates-details-list) (a secondary patch log).
- **Huge and Titanic mesh scales (unofficial):** a community post cites "0.75 for a normal pet and 2 for a huge pet", and 6 for a Titanic — as cited in the sibling note `blocky_visual_language.md` from [PS wiki, Huge Pets (PS99)](https://pet-simulator.fandom.com/wiki/Huge_Pets_(Pet_Simulator_99)) (not opened here).
- **Gargantuan, an older range:** "a Gargantuan mount is approximately 2 to 3 times larger than a standard Titanic pet". The search summary attributed this to "another source" in a result set that held the [U7BUY buyer's guide](https://www.u7buy.com/blog/ps99-gargantuan-vs-titanic-pets/) and a [Dungeonpath guide](https://dungeonpath.com/tags/gargantuan/). Unverified.
- **Gargantuan, ranking:** "larger than titanic pets in both size and power, and ridable" — [fandom user blog, "Gargantuan Pets Updated Version"](https://pet-simulator.fandom.com/wiki/User_blog:SomeStream994512243/Gargantuan_Pets_Updated_Version) (a user blog, so a weak source). The [Gargantuan Pets (PS99) fandom page](https://pet-simulator.fandom.com/wiki/Gargantuan_Pets_(Pet_Simulator_99)) confirms Gargantuan as its own tier above Titanic.
- **Odds, an example of how rare the scale classes are:** a Titanic SpongeBob SquarePants hatched at "a mere 0.05% chance" — [Sportskeeda](https://www.sportskeeda.com/roblox-news/pet-simulator-99-how-get-titanic-spongebob-squarepants). Titanic pets are a recurring limited release in updates; Update 55 added Titanic Ooze Cat, Titanic Jelly Kitsune and Titanic Nightmare Sludge — [Sportskeeda, Update 55](https://sportskeeda.com/roblox-news/news-pet-simulator-99-slime-tank-update-55-slime-factory-titanic-pets).
- **Grow a Garden weight classes:** "Huge 5–6.9 kg, Titanic 8–8.9 kg, Godly 9–9.9 kg, Colossal 10+ kg". The class "sets starting stats, growth rate, maximum size and the potential strength of its abilities" — [growagardencalculator.ca, Pet Weight Calculator](https://www.growagardencalculator.ca/pet-weight-calculator). Another calculator in the same result set gives Huge as 8 to 9 kg, so the bands conflict — [GAG tools](https://gagtools.net/pet-weight-calculator), [gagcalculatorvalue](https://gagcalculatorvalue.com/pets) (the summary did not say which).
- **Grow a Garden, Huge modifier:** the community wiki says Huge pets get "a ×4 weight modifier" — [Grow a Garden Wiki, Pets](https://growagarden.fandom.com/wiki/Pets). One calculator site says Huge pets have "a noticeable visual size increase". It was not named in the summary; candidates are [GAGdata weight calculator](https://www.gagdata.com/calculators/pet-weight-calculator) and [growagardentradevalues](https://growagardentradevalues.com/calculator/pet-weight/). No official confirmation was found.
- **Grow a Garden, age and size:** a community post says age does not increase pet size — [Grow a Garden fandom forum, "Huge Pet Information"](https://growagarden.fandom.com/f/p/4400000000000090410). Some calculators instead use W = (Wh / 11) x (A + 10), where Wh is the hatch weight and A the age — [GAG tools](https://gagtools.net/pet-weight-calculator). These conflict and neither is official.
- **Grow a Garden size mutations:**
  - **Mega:** about a 6.23% chance; "makes a pet massive in size"; 20% faster hunger; 10 to 40 XP a second — [esports.gg](https://esports.gg/guides/roblox/grow-a-garden-a-complete-pet-mutations-guide/). Another site gives 6.43% and a cost of 1B Sheckles — [growagardencalculator.io, Mega](https://www.growagardencalculator.io/mutations/mega).
  - **Gigantic:** "greatly increases the pet's size"; sources conflict on its odds (0.0001% at Level 50, or 12.5% at Level 500) — [growagardencalculator.io, Gigantic](https://www.growagardencalculator.io/mutations/gigantic).
  - **Nightmare:** "increases the affected pet's size by 125%" — one source in a result set that held [Sportskeeda's tier list](https://www.sportskeeda.com/roblox-news/grow-garden-pet-mutations-tier-list) and [BlueStacks](https://www.bluestacks.com/blog/game-guides/roblox/rl-grow-a-garden-pet-mutations-guide-en.html). Unverified.
  - The Mega shard was "most likely replaced by the Giantbean Shard" in a recent update — [Deltia's Gaming](https://deltiasgaming.com/?p=326429).
- **Bee Swarm gifted bees:** the sources describe a new colour scheme, stained wings and a star mark, not a size change (see section 3) — [Gifted Bee, BSS wiki](https://bee-swarm-simulator.fandom.com/wiki/Gifted_Bee).

### Inferences
- PS99's chain on the unofficial mesh scales (0.75, 2, 6) and the 3x Gargantuan step is normal : Huge : Titanic : Gargantuan of about 1 : 2.7 : 8 : 24. On the value site's "Titanic about 2x Huge" it would be about 1 : 2.7 : 5.3 : 16. Either way each step is 2 to 3x, far steeper than the project's 1.0 to 1.5 tier scale and its 2.35x maximum. **(Inference: arithmetic on partly unofficial numbers)**
- In PS99 and Grow a Garden, size is its own rare roll (a scale class, a weight class or a size mutation) on top of rarity. It is not just the tier. The project already works this way (`Sizes.luau` plus the tier scale). The research suggests the top size roll should be visibly discontinuous. One option is a very rare roll at about 2x, separate from the 0.75 to 1.35 band, ridable where the species has a seat. It would need an original name and must not use "Titanic", "Gargantuan" or "Colossal". **(Inference and option)**
- Ridability is how the top scale class justifies itself. Once a pet is too big to follow beside the player, it becomes a mount. **(Inference from the PSX/PS99 Titanic and Gargantuan "ridable" findings)**

### Gaps
- No official scale factor for a PS99 Huge against a normal pet was found (only the community mesh scales 0.75 and 2), and no stud sizes for any class. The fandom pages that might hold them could not be opened. A side-by-side screenshot or video measurement is the way to get it.
- Whether a Grow a Garden pet's in-world model visibly scales with kg is not officially confirmed, and the sources conflict.
- Whether BGSI "XL" pets are physically bigger is not confirmed. The only XL example found is the XL Chest Mimic, at 1 in 20,000,000 — [Chest Mimic, BGSI wiki](https://bgs-infinity.fandom.com/wiki/Chest_Mimic).

## 2. Detail: what extra modelling do rarer pets get?

### Takeaway
The clearest documented pattern is that a rarer variant keeps the same mesh and gains designated glow parts, a new colour scheme, a stamped mark or an outline texture. Adopt Me (Neon parts), Bee Swarm (gifted colours, stained wings, star) and PS99 (evolved Huge recolours with a shiny outline) all work this way. The top base species lean on big signature features: wings, dragon bodies, angel themes. A Common-against-Legendary model comparison (block or part counts) could not be sourced.

### Cited Findings
- **Adopt Me Neon:** the glow sits on species-chosen parts. A Neon Dog glows on the ears, paws and tail tip; a Neon Unicorn glows pink in the horn, hooves and mane. Dragon descriptions conflict (wings and spine, or wings and belly) — [GG Chest](https://ggchest.com/blog/adopt-me/how-to-make-a-neon-pet-in-adopt-me), [adoptmewiki.com, Neon Pets](https://adoptmewiki.com/wiki/neon-pets/), [GameBoost](https://gameboost.com/blog/how-to-get-neon-pets-in-adopt-me).
- **Adopt Me Neon colour:** fixed per species; "players cannot change the color of the neon on their pet" — same guides ([adoptmewiki.com](https://adoptmewiki.com/wiki/neon-pets/)).
- **Adopt Me Neon growth names:** Reborn, Twinkle, Sparkle, Flare, Sunshine, Luminous — [adoptmewiki.com, Neon Pets](https://adoptmewiki.com/wiki/neon-pets/).
- **Adopt Me, no stat gain:** Neon pets "do not gain extra stats, but they hold significantly higher trade value" — [U7BUY, Neon pets](https://www.u7buy.com/blog/how-to-make-neon-pets-in-adopt-me/) or [RPG Stash](https://www.rpgstash.com/blog/adopt-me-how-to-make-neon-pets) (the summary did not say which).
- **Bee Swarm gifted:** "a new color scheme unique to each type of bee, stained wings, and a star on its back and sides"; the hive icon does not change colour — [Gifted Bee, BSS wiki](https://bee-swarm-simulator.fandom.com/wiki/Gifted_Bee).
- **PS99 evolved Huges:** recolours of Huge pets that "cannot be golden, but rainbow or shiny"; they "share a similar texture to gold pets, having a shiny outline" — [Evolve Machine (PS99), fandom](https://pet-simulator.fandom.com/wiki/Evolve_Machine_(Pet_Simulator_99)).
- **Top Adopt Me pets by value (2026):** Shadow Dragon first, then Bat Dragon, Giraffe and Frost Dragon — [RoWatcher, Adopt Me trading values 2026](https://rowatcher.com/news/adopt-me-trading-values-in-2026-pet-economics-rising-legendaries-scam-prevention). Guides describe the Shadow Dragon's "dark coloration and menacing presence", the Bat Dragon's "bat-like wings" and the Frost Dragon's "stunning icy appearance". These come from SEO-style mirror pages (low quality) — [toky.co mirror, Legendary tier list](https://monitoring.toky.co/?p=12024).
- **PS99 top-tier themes:** many cats among the Titanics. Dragons and angels appear too: Titanic Blazing Dragon, Starfall Dragon, Sea Dragon, Lucki Angelus and Black Hole Angelus — an [eBay listing](https://www.ebay.de/itm/406010894559) (weak; a names-only source). A Gargantuan Dark Dragon was added in one update. Gargantuan Leprechaun Fox came with Update 74 on 21 March 2026, per a summary over a result set that held [Dungeonpath](https://dungeonpath.com/tags/gargantuan/) and [Eldorado](https://www.eldorado.gg/blog/roblox-en/pet-simulator-99-values/). Top marketplace listings: Gargantuan Nyan Cat at $845 and Titanic Nightmare Cat at $300 (a mid-2026 snapshot) — [Eldorado, PS99 values](https://www.eldorado.gg/blog/roblox-en/pet-simulator-99-values/).
- **Steal a Brainrot:** some top-tier "detail" is an accessory added by a trait. Taco puts a taco on the brainrot's head — [Owlzo, traits](https://owlzo.com/steal-a-brainrot-traits), [Sportskeeda, traits](https://www.sportskeeda.com/roblox-news/steal-brainrot-all-traits-multipliers).

### Inferences
- The structural lesson matches the project's own section 4 note ("glow regions planned into the mesh"). The research sharpens it in two ways. Each species chooses which 2 to 3 parts glow: the extremities (ears, paws, tail tip, horn, hooves, mane, wings), never the whole body. And the glow colour is fixed per species in the base variant. **(Inference from the Adopt Me findings)**
- A stamped mark (BSS's star on the back and sides) is a cheap detail step that needs no new geometry: a decal or a small crisp part. It could be one rung of the alien ladder, for example an element glyph that appears from Rare up. **(Inference and option)**
- The top base species in these games are mostly classic "grand" archetypes: dragons, winged animals, angels. Each carries one big silhouette feature (wings, horns, a halo). **(Inference from the Adopt Me and PS99 names; it rests on names, not on model inspection)**

### Gaps
- No source compared a Common and a Legendary or Secret model of the same game by part, block or triangle count, number of accessories or texture detail. The wikis that carry model images could not be opened. Next step: screenshots from a showcase video or the in-game index, recorded in `05-ui-design/refs` per the project rule.
- No source documented whether PS99 or Pets Go top pets carry modelled crowns, armour or layered parts.
- Pets Go was not covered by any result.

## 3. VFX: what effects do rare pets and variants carry, and how do they step up?

### Takeaway
The documented variant ladder is mostly recolour, then glow parts, then hue cycling, then sparkle. Gold is a flat gold recolour. Diamond is cyan. Rainbow cycles hues (Adopt Me's Mega Neon about every 1 to 3 s). Shiny "shines" in the world and in the inventory. Particles, trails and lightning show up mostly as add-on traits or mutations (Steal a Brainrot's Fireworks, Nyan and Lightning; Grow a Garden's Shocked and Radiant) rather than as automatic per-rarity auras. The exact particle make-up of PS99 Shiny or Huge effects is not documented in the sources found.

### Cited Findings
- **Adopt Me Mega Neon:** made from four Luminous Neons of the same species in the Neon Cave. It glows on the same parts as the Neon, but those parts cycle through the rainbow — [Adopt Me Wiki, Aye Aye](https://adoptme.fandom.com/wiki/Aye_Aye), [Adopt Me Wiki, Sugar Glider](https://adoptme.fandom.com/wiki/Sugar_Glider). The glow "changes to a different rainbow color about every 1-3 seconds" — [Sportskeeda, Mega Neon](https://sportskeeda.com/roblox-news/mega-neon-pet-adopt-me) (attributed by the summary; unverified).
- **Mega Neon exceptions:** some pets cycle only through colours matching their palette (Evil Unicorn). Frost Dragon and Shadow Dragon originally cycled only white and blue; the Monkey Fairground update changed both to the full rainbow. There is no tier above Mega Neon — [Adopt Me Wiki, File: Mega Neon Goat](https://adoptme.fandom.com/wiki/File:Mega_Neon_Goat.png), [Adopt Me Wiki, Punk Pony](https://adoptme.fandom.com/wiki/Punk_Pony).
- **PS99 / PSX Shiny (older, the PSX Shiny update of about December 2022):** Shiny is "a new attribute for ANY pet". Shiny pets "shine in-game and in your inventory, making them standout", are stronger (2.5x in that post), and Gold, Rainbow and Dark Matter can each be shiny — [BIG Games, "Shiny Update!"](https://www.biggames.io/post/pet-simulator-x-shiny-update).
- **PS99 Rainbow Machine:** at least 10 identical golden pets make one rainbow pet; it unlocks at area 31; the power gain is about 27% ("not 10x" despite the tooltip) — [Rainbow Machine (PS99), fandom](https://pet-simulator.fandom.com/wiki/Rainbow_Machine_(Pet_Simulator_99)).
- **PS99 Titanic variants:** Golden is "+1.2 times more damage than Normal Titanic Pets"; Rainbow "+3.6 times" — [Titanic Pets (PS99), fandom](https://pet-simulator.fandom.com/wiki/Titanic_Pets_(Pet_Simulator_99)) (as attributed by the summary).
- **PS99 motion:** "Your Golden, Rainbow, and Shiny pets now bounce in full color!" — a BIG Games PS99 update post in a result set that held [Update 61](https://www.biggames.io/post/pet-simulator-99-update-61) and [Update 91](https://www.biggames.io/post/pet-simulator-99-update-91) (the summary did not say which).
- **Steal a Brainrot mutations:** Gold turns the brainrot yellow/gold (1.25x, or 1.2x on another site); Diamond turns it cyan (1.5x); Rainbow "cycle[s] between RGB colours" (10x) — [Bloxodes, mutations](https://bloxodes.com/wiki/steal-a-brainrot/mutations), [rblxguide](https://rblxguide.com/games/steal-a-brainrot/mutations), [bloxinformer](https://bloxinformer.com/wikis/steal-a-brainrot/mutations/). Galaxy is 6x (7x during its event) — [Beebom](https://beebom.com/steal-a-brainrot-mutations-and-traits-list/amp/); no description of its look was found.
- **Steal a Brainrot, current mutation list:** 16 mutations, with Cyber the best at an 11x income multiplier as of 18 April 2026 — [rblxguide, May 2026](https://rblxguide.com/games/steal-a-brainrot/updates/steal-a-brainrot-mutations-guide-may-2026). An October 2026 guide counts 15 mutations besides Normal — [GameOverdrive (PT)](https://gameoverdrive.com.br/steal-a-brainrot-mutacoes/).
- **Steal a Brainrot traits as VFX:**
  - **Fireworks:** "a firework particle effect is applied" (5x) — [Steal a Brainrot Wiki, Traits/AA Exclusive](https://stealabrainrot.fandom.com/wiki/Traits/AA_Exclusive); described as "a multicoloured starburst firework effect firing continuously from the Brainrot" — [sabwiki, traits](https://sabwiki.com/traits/).
  - **Nyan:** cats with rainbow trails, a rainbow trail on hit brainrots (6x, or 5x on the wiki) — [Beebom](https://beebom.com/steal-a-brainrot-mutations-and-traits-list/), [Sportskeeda](https://www.sportskeeda.com/roblox-news/steal-brainrot-all-traits-multipliers).
  - **Lightning:** from admin lightning strikes (6x) — [TechWiser](https://techwiser.com/all-traits-in-steal-a-brainrot-and-how-to-get-them-roblox/).
  - **Taco:** a taco on the head (3x or 4x) — [Owlzo](https://owlzo.com/steal-a-brainrot-traits).
- **Grow a Garden pet mutations:** Golden 6.43%, Rainbow 3.22%, Shocked 3.22% (in a thunderstorm, a 25 to 30% chance to attract lightning), Radiant 3.22%, Inverted 16.08%, Frozen 9.65% (mid-2025 guides) — [TheGamer](https://www.thegamer.com/roblox-grow-a-garden-pet-mutation-effect-list-guide/), [Beebom](https://beebom.com/grow-a-garden-pet-mutation-guide/). There are 47 pet mutations as of May 2026 — [GAGdata, pet mutations](https://www.gagdata.com/pets/mutations).
- **Grow a Garden mutation visuals:**
  - A Rainbow pet "can change colours every few seconds" — [RPG Stash](https://www.rpgstash.com/blog/7-best-pet-mutations-roblox-grow-a-garden).
  - A Shocked pet has "an electric visual" — [MyGAG Calculator](https://mygagcalculator.com/all-mutations-in-grow-a-garden/).
  - On crops: Rainbow is "an iridescent rainbow glow", Shocked "an electric blue glow", Celestial "a golden star particle effect" — [GAGdata, Rainbow](https://www.gagdata.com/mutations/rainbow), [GAGdata, Shocked](https://www.gagdata.com/mutations/shocked), [GAGdata, mutations](https://www.gagdata.com/mutations).
  - Radiant is "a glowing radiant aura on pets" — from one unnamed source in that result set; unverified.
- **Bee Swarm gifted presentation:** "a glowing gold hexagon around its hive slot" — [Gifted Bee](https://bee-swarm-simulator.fandom.com/wiki/Gifted_Bee); "a thin yellow glowing line will trace the hive slot border" — [Hive, BSS wiki](https://bee-swarm-simulator.fandom.com/wiki/Hive) (the two descriptions conflict). Older: "in the earlier days … bee faces on hive slots were bigger and they also used to sparkle depending on what rarity the bee was" — [Hive](https://bee-swarm-simulator.fandom.com/wiki/Hive).
- **BGSI:** variants are Shiny, Mythic, Shiny Mythic, XL, Shiny XL, Mythic XL and Shiny Mythic XL, and each has its own name colour (Shiny Mythic is lime) — [BGSI Wiki, Pets](https://bgs-infinity.fandom.com/wiki/Pets).

### Inferences
- Across the games, a rarity tier and a variant finish are two separate axes. The tier picks the species, and the species' own design carries the spectacle. The variant finish (Gold, Rainbow, Shiny, Neon) is a material or colour treatment on the same mesh. The project's split (species effect in the element colour, tier layer in the tier colour, overlay on the glow slot) already matches this and goes further than the reference games: none of them was found to give every tier an automatic aura ladder. **(Inference)**
- Concrete numbers worth adopting for the project's overlays: a Rainbow hue cycle period of 1 to 3 s per step (Mega Neon), and palette-locked cycling for species whose identity would break under a full rainbow (the Evil Unicorn exception). The latter suits Secret, a dark palette with one accent. **(Inference)**
- Steal a Brainrot's traits are a separate, stackable "event layer" (a firework emitter, a rainbow trail, a hat). A future alien event modifier could reuse the `AlienFx` layer slots this way without touching the tier ladder. **(Inference and option)**

### Gaps
- No source described the particle content of PS99 Shiny (sprite, rate, colour), any Huge-only aura, or Dark Matter's look in PS99. Dark Matter appears only in the older PSX Shiny post.
- No source described orbiting items, ground rings or light beams on any reference game's rare pets. The project's section 4 claim about "orbiting gems on top pets" is not confirmed by this pass.
- Galaxy (Steal a Brainrot) and Ascended (Grow a Garden) visuals: no description found.

## 4. Animation and presence: idle, the hatch reveal, sound, announcements, nameplates

### Takeaway
The documented step-ups are about who sees the moment. PS99 gives its rarest class (Gargantuan) a hatch cutscene that the whole server sees, with the sky darkening and the egg lifting. BIG Games' Hatch Wars update sends the rarest hatches to chat and every server. BGSI announces Mythic and Shiny Mythic Secrets to every server but hides the username. Steal a Brainrot announces a Brainrot God's name when it spawns. Idle-animation differences by rarity were not documented.

### Cited Findings
- **PS99 Gargantuan hatch:** "a hatching cutscene is displayed for everyone in the server". The sequence darkens the sky and lifts the egg, and the pet's golden, rainbow or shiny status is shown on it. Gargantuans are described as "the first type of pets to have a hatching cutscene" — [Gargantuan Pets (PS99), fandom](https://pet-simulator.fandom.com/wiki/Gargantuan_Pets_(Pet_Simulator_99)).
- **PS99 hatch visibility:** "everyone in the server can see your hatches" — [BIG Games, Update 75 "Spring Egg Machine!"](https://www.biggames.io/post/pet-simulator-99-update-75).
- **PS99 cross-server announcements:** "the rarest hatches blast into chat and every server"; players "compete to hatch the biggest pet each hour! Top hatchers get their name displayed across every server" — [BIG Games, Update 96 "Hatch Wars!"](https://www.biggames.io/post/pet-simulator-99-update-96) (the second quote may come from [Update 60 "Grow an Egg!"](https://www.biggames.io/post/pet-simulator-99-update-60), which was in the same result set).
- **BGSI:** "Mythic and Shiny Mythic Secret pets will also be announced globally, but the hatcher's username is not shown" — [BGSI Wiki, Pets](https://bgs-infinity.fandom.com/wiki/Pets).
- **BGSI odds behind that:** Shiny Mythic hatches naturally at 0.025%, or is crafted from 8 Mythic Secret pets. The shiny chance is 2.5%, and Golden Egg Mastery guarantees a Shiny every 75 hatches (about April 2025) — [Deltia's Gaming, BGSI pets guide](https://deltiasgaming.com/complete-guide-to-pets-in-bubble-gum-simulator-infinity-roblox/). Variant stat multipliers: Shiny 1.5x, Mythic 1.75x, Shiny Mythic 2.625x — [Sportskeeda, BGSI pets](https://www.sportskeeda.com/roblox-news/bubble-gum-simulator-infinity-pets-guide). The wiki says Shiny Mythic is 125% better, rising to 160% at level 25 — [BGSI Wiki, Pets](https://bgs-infinity.fandom.com/wiki/Pets). The two sources conflict.
- **Steal a Brainrot:** tiers run Common, Rare, Epic, Legendary, Mythic, Brainrot God, Secret, OG — [games.gg tier list](https://games.gg/steal-a-brainrot/guides/steal-a-brainrot-complete-brainrot-tier-list/), [Lootester](https://lootester.com/steal-a-brainrot-tier-list/). One guide says a Brainrot God's name is announced when it spawns (the summary did not name the guide; candidates are the same two pages).
- **PS99 motion:** golden, rainbow and shiny pets "bounce in full color" — BIG Games update post ([Update 61](https://www.biggames.io/post/pet-simulator-99-update-61) / [Update 91](https://www.biggames.io/post/pet-simulator-99-update-91), unconfirmed which).
- **Bee Swarm, collection state in the bee menu:** no star if the gifted form is undiscovered, a faded star if discovered but not in the hive, a black star if owned — [Gifted Bee, BSS wiki](https://bee-swarm-simulator.fandom.com/wiki/Gifted_Bee).

### Inferences
- The project already has a server banner at Legendary and above. The research adds three further rungs used by the top games:
  1. A whole-server cutscene for the single rarest class, where the sky or lighting changes for everyone.
  2. A cross-server announcement for the rarest outcomes, which would mean `MessagingService` on Roblox. The rate and payload are server-side; check the limits before committing.
  3. An anonymous variant of that announcement, as BGSI does.

  A possible mapping for the alien game: Legendary gets the in-server banner, Cosmic the in-server banner plus a sky moment for everyone nearby, and Secret a cross-server line without the name. **(Inference and option; the project's privacy and safety review would decide on names)**
- A codex mark with three states (none, faded, black star) is a cheap collection cue that BSS uses for variants. The project's codex could show overlay discovery the same way. **(Inference and option)**

### Gaps
- No source documented rarity-scaled idle animations (bob height, flap speed) in any reference game, sound design differences by rarity, or nameplate styling beyond BGSI's per-variant name colour.
- No source documented whether PS99 Huge or Titanic hatches (as opposed to Gargantuan) have a cutscene or a chat line.

## 5. Do rarer pets look fiercer, or more spectacular, ornate and majestic?

### Takeaway
The evidence points to spectacle and status, not scariness, as what makes the top pets desirable. The most valuable Adopt Me pets include one "menacing" design (Shadow Dragon) but also a Giraffe and an icy Frost Dragon. PS99's top classes are dominated by cats, dragons and angels. Steal a Brainrot's top OG tier includes absurd meme characters. Size, glow and rarity carry the "worth it" feeling; the face does not need to be scary.

### Cited Findings
- **Adopt Me, most valuable in 2026:** Shadow Dragon, Bat Dragon, Giraffe, Frost Dragon — [RoWatcher](https://rowatcher.com/news/adopt-me-trading-values-in-2026-pet-economics-rising-legendaries-scam-prevention). Descriptors used by guides: Shadow Dragon "dark coloration and menacing presence"; Frost Dragon "stunning icy appearance"; Bat Dragon "bat-like wings and enchanting appearance", "spooky aesthetic"; guides credit scarcity from limited events plus design — [toky.co mirror guides](https://monitoring.toky.co/?p=12024) (low-quality SEO pages; the descriptors are opinion).
- **Adopt Me, rarest:** the Mega Neon Bat Dragon "currently holds the top spot as the rarest". A free Mega Neon Shadow Dragon was given out in a November 2025 event — [esports.gg, 10 rarest pets](https://esports.gg/news/roblox/10-rarest-pets-adopt-me/).
- **PS99 top classes:** cat variants are very common among Titanics. Dragon and angel themes appear (Titanic Blazing Dragon, Starfall Dragon, Sea Dragon, Lucki Angelus, Black Hole Angelus) — [eBay listing](https://www.ebay.de/itm/406010894559) (names only). The highest-priced listings were Gargantuan Nyan Cat and Titanic Nightmare Cat — [Eldorado](https://www.eldorado.gg/blog/roblox-en/pet-simulator-99-values/).
- **Steal a Brainrot OG:** named units include Spyder Elephant, Meowl, Strawberry Elephant, Skibidi Toilet and Headless Horseman — [Lootester](https://lootester.com/steal-a-brainrot-tier-list/), [Driffle, October 2026 list](https://driffle.com/blog/steal-a-brainrot-all-brainrots-list/).

### Inferences
- The top tier in these games is a mix: about one-third of the named top pets read as dark or menacing (Shadow Dragon, Nightmare Cat, Black Hole Angelus, Headless Horseman). The rest read as majestic (dragons, angels), cute-iconic (Nyan Cat, Giraffe) or absurd (Meowl, Skibidi Toilet). **(Inference from names and guide descriptors, not from a systematic count)**
- This supports the project's B42 "spectacular" temperament for Cosmic and Secret over pure "fierce". It also supports keeping a few top-tier aliens cute-iconic, like Nyan Cat, a Giraffe or Meowl at the top of their games: a cute face on a huge, glowing, rare body still reads as a prize. **(Inference)**
- Recurring top-tier archetypes are dragons, angels or winged forms, and "dark" variants of a popular species. These are archetypes, not designs. Any use must be original per the project's "inspired by, never traced" rule. **(Inference)**

### Gaps
- No systematic count of temperament across a full top tier was possible without the wiki galleries. No player-survey or engagement data links "scary" against "majestic" looks to desirability.

## 6. Mobile performance limits on pet VFX

### Takeaway
Roblox's documented limits are 400 particles a second per emitter (100 on mobile) and a 20 s maximum lifetime, with on-screen count equal to Rate x Lifetime. Undocumented whole-client ceilings of about 3,500 to 3,600 particles on mobile, and 16,000 on desktop, are widely reported. Enabled emitters are reduced automatically at low graphics quality, but `:Emit()` bursts bypass that. Pet games keep many followers cheap with client-side movement through constraints or BulkMoveTo on a fixed tick.

### Cited Findings
- **Per-emitter limits:** maximum output is 400 particles a second, or 100 on mobile — [Roblox Creator Docs, ParticleEmitter.Rate](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter#Rate). Particles have a maximum lifetime of 20 s, and higher values are capped — [Creator Docs, Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) (page metadata about 4.6 years old; check the live page).
- **Counting particles:** the number of particles on screen equals Rate x Lifetime — [ParticleEmitter reference](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter#Rate).
- **Testing quality:** look varies with the device's graphics setting; set Editor Quality Level to lowest and highest in Studio after tuning. To thin out flicker in the distance, shorten Lifetime or lower Rate — [Creator Docs, Particle emitters](https://create.roblox.com/docs/effects/particle-emitters), [Creator Docs, waterfalls VFX tutorial](https://create.roblox.com/docs/tutorials/building/effects/custom-particle-effects).
- **Whole-client ceilings (undocumented):** "16000 particles on computer and XBox devices … 3500 particles on mobile devices"; another thread says 3,600 for mobile and Xbox — [DevForum, "Does the ParticleEmitter Rate have a significant effect on performance?"](https://devforum.roblox.com/t/does-the-particleemitter-rate-have-a-significant-affect-on-performance/3006334), [DevForum, "Particle FPS drop?"](https://devforum.roblox.com/t/2640095) (the summary did not say which thread gave which number).
- **Emit() spikes:** a burst of "around 300" particles caused "around 18ms Id_Transparent spikes", mainly with the camera close to the emitter — [DevForum engine bug](https://devforum.roblox.com/t/particleemitteremit-causes-huge-lag-spikes-when-camera-is-close-to-particleemitter/2543010).
- **Automatic quality scaling:** particles are "automatically optimized (based on graphics level) by Roblox" when the emitter is enabled, but ":Emit() ignores the automatic optimisation". The suggested pattern is to scale Emit counts by the client's quality level — [DevForum, "Custom particles emitting system"](https://devforum.roblox.com/t/custom-particles-emitting-system/968599), [DevForum, "How could I bypass this?"](https://devforum.roblox.com/t/how-could-i-bypass-this/1994624).
- **Emitter count:** one developer found that "it doesn't matter if they're turned on or not, just having a lot of them in the workspace" hurt performance (a single report, unconfirmed) — [DevForum, "How to improve performance on particle effects?"](https://devforum.roblox.com/t/how-to-improve-performance-on-particle-effects/503741).
- **Low-end devices:** "increasing the rates on ParticleEmitters will hit performance quite notably on a lower-end device"; scale emission by graphics quality — [DevForum, performance considerations](https://devforum.roblox.com/t/performance-considerations-improvements-and-optimizations-when-making-a-game/817499). High rates were invisible in cost on a good machine but not on low-end ones — [DevForum, high rates with low lifetimes](https://devforum.roblox.com/t/what-are-the-effects-of-high-particleemitter-rates-with-low-lifetimes/419394).
- **Many followers:**
  - An AlignPosition approach with "1 player = 100 pets" held 160 to 170 FPS while moving — [DevForum, "How to make a very optimized Pet Follower?"](https://devforum.roblox.com/t/how-to-make-a-very-optimized-pet-follower/3235258).
  - `BulkMoveTo` with `Enum.BulkMoveMode.FireCFrameChanged` suppresses the other change events — [DevForum, moving large numbers of parts](https://devforum.roblox.com/t/help-with-optimization-on-movingresizing-large-amount-of-parts/3113374).
  - Run movement on a fixed tick with an accumulator rather than every Heartbeat — [DevForum, entity system](https://devforum.roblox.com/t/how-can-i-optimize-my-entity-system/2084513).
  - Offsets come from `HumanoidRootPart.CFrame:PointToWorldSpace` — [DevForum, pet follow system #17](https://devforum.roblox.com/t/how-do-i-make-pet-follow-system/3308281/17).
  - A client pet-follow script saw script activity above 50% — [DevForum, "Optimize Pet Follow?"](https://devforum.roblox.com/t/optimize-pet-follow/3166935).
- **Other engines (context only):** one team limits to 150 to 200 particles on screen on mobile — [Solar2D forum](https://forums.solar2d.com/t/how-many-particles-is-too-much/352924). Mobile is fill-rate bound, so use a stronger texture and fewer particles — [Godot forum](https://forum.godotengine.org/t/how-to-improve-performance-of-cpuparticles-for-mobiles/22730).

### Inferences
- The project's caps (100 a second per emitter, 20 s, a scene budget of 1,200 against a ceiling of about 3,600) are consistent with these sources. Three additions follow:
  1. Budget by Rate x Lifetime per alien, not by Rate alone. A Cosmic at 60 a second with 2 s lifetimes is 120 live particles; at 5 s it is 300.
  2. Route reveal and flourish bursts through a helper that multiplies `:Emit()` counts by the client's quality level, because `:Emit()` skips Roblox's own reduction.
  3. Destroy or reparent the emitters of culled aliens rather than leaving them disabled, given the anecdotal cost of emitters that exist but are disabled.

  **(Inference)**
- Keep burst sizes under about 300 near the camera, because the reveal and the codex place the camera close to the model. **(Inference from the 18 ms spike report)**
- Large, glowing, low-overdraw effects (glow regions, colour cycling, an outline) are cheaper on phones than dense particles. That is how Adopt Me (Neon and Mega Neon are colour and glow, not particles) and most variant finishes work. This favours making overlays material and colour changes first and particles second. **(Inference)**

### Gaps
- No primary BIG Games or Uplift (Adopt Me) statement on how they budget pet VFX was found.
- No official Roblox figure for Beam, Trail or PointLight cost on mobile was found in this pass. The whole-client particle ceiling is undocumented and its exact number (3,500 or 3,600) is unsettled.
- The Creator Docs particle page could not be opened to confirm whether the 100-a-second mobile cap is still current in October 2026.
