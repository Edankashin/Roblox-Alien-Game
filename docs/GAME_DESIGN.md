# Game Design Document (working title TBD)

**Pitch:** You crash-land on a strange planet. Cute aliens are everywhere. Catch them, and they build you a ship. Fill the ship bar, launch, and do it again on a frost world, a cyber world, a lava world. Every planet you leave keeps working for you, and every alien you catch goes in your codex forever.

**Status:** Vision plan v1, written against the research in `reports/Roblox alien collection game design.md`. All numbers in this document are starting values to tune in playtests, not tested thresholds.

---

## 1. Design pillars

1. **One bar.** The ship progress bar is the heartbeat of the game. Everything the player does moves it, and the player can always see it move.
2. **Aliens everywhere, secrets hidden.** Like Pokémon GO: the world is never empty, commons are a tap away, and rares live behind biome, time, weather, and skill.
3. **Playable with one thumb while eating.** No fail state that loses progress. No upkeep. Auto-assign by default. Idle income and assembly continue offline. Every tap does something.
4. **Dopamine at every step.** Every action has a feedback beat within two seconds, every session has a reward beat in the first ten seconds, and every world ends in a climax.
5. **Nothing you did is wasted.** Old worlds become outposts, every alien stays in the codex forever, Sets reward the whole collection.

The plot stays one sentence: *catch aliens, build the ship, reach the next world.* Depth lives in the aliens, not the story.

---

## 2. The loop at three timescales

### Moment-to-moment (30 seconds to 2 minutes)

1. Spot an alien (always 12 to 20 visible nearby).
2. Tap it. The timing bar appears.
3. Hit the zone. Catch animation and rarity reveal.
4. The alien auto-walks to the best open station slot. The Scrap/min number ticks up. The module sub-bar speeds up.
5. Scrap crosses a module's cost. Tap "Build." Aliens swarm the ship. The part snaps on. The ship bar jumps.
6. Repeat.

### Session (7 to 15 minutes, the Roblox median is about 7)

1. Login. Offline chest pops open: Scrap earned, and any module that finished while away snaps onto the ship with a camera pan.
2. Welcome Week gift or daily quest reminder (one tap).
3. Check the ship bar and the next module's missing ingredient.
4. Explore for 2 to 4 catches, usually toward the key material the next module needs.
5. If the Meteor Shower timer is under 3 minutes, stay for it.
6. Leave with a visible timer running: a module assembling, an offline chest filling, the next Shower countdown.

### World arc (2 to 7 days per world)

1. Five modules, each with three gates (Scrap, key material, assembly time).
2. The Field Notes quest chain leads to the world's Warden, a Legendary with a three-round capture.
3. Launch cinematic. The camp becomes an Outpost. The ship and roster fly to the next world.
4. The home planet grows (house, habitats, trophy ship).
5. Codex pages fill; secrets unlock through quests and completed Sets.

### Dopamine map

| Cadence | Beat | Feedback |
|---|---|---|
| Every 1 to 5 s | Scrap ticks, aliens work | Floating numbers, work-loop animations, soft chime on round numbers |
| Every 30 to 90 s | A catch | Timing-bar hit sound, catch burst, rarity-colored card, codex "NEW" stamp |
| First sight of a new species | A shadow silhouette resolves into color as you approach | "Who's that?" chime, radar blip turns from shadow to icon |
| Every 3 to 10 min | Module sub-bar completes | Aliens swarm, part snaps on, camera pan, ship bar jumps with a bass hit |
| Every session | Return reward | Offline chest, daily gift, daily quest complete, one free spin |
| Every 2 h (server clock) | Meteor Shower | Server banner, sky changes, beacons, Epic+ spawns, Cosmic chance |
| Every 2 to 7 days | Launch | Warden capture, countdown, liftoff cinematic, new world reveal |
| Weekly | Alien of the Week, Weekly Weather, one hosted Shower Storm | New silhouette in the codex with a 7-day timer, event-only overlay, server-wide banner |
| Monthly | Themed seasonal event or a new world | Sky, music, and camp decor change; event quest track; Vaulted alien |

Juice rules: every number that goes up animates going up; every bar that fills pulses when it fills; every tier has a louder sound than the one below it; every near-miss on the timing bar is shown (the ticker stops just outside the zone and the zone flashes) so the player feels they almost had it.

---

## 3. The Ship Bar

The ship bar is pinned to the top of the HUD at all times. It is the weighted sum of five module sub-bars. The ship itself sits in the camp as a 3D model that visibly assembles: each module is a physical part that snaps on when complete, so the bar and the object always agree.

### Three gates per module

Every module has three costs. This is how the two models from the team's earlier debate become one system:

| Gate | What pays it | What it rewards | Who it's for |
|---|---|---|---|
| **Scrap cost** | Aliens at stations generate Scrap passively, offline too | Having more and better aliens | The idle player |
| **Key material** | Found only by exploring a specific biome under a specific condition | Exploration, catching rares along the way | The explorer |
| **Assembly time** | Aliens with the matching job stand in the module's slots; time is divided by their summed work speed | Rarer aliens finish the ship visibly faster | The collector |

Scrap is the one number on the HUD and is meant to feel abundant. Key materials are the real pacing gate. Assembly time is where rare aliens prove their worth: drop an Epic welder into a slot and the timer visibly shrinks.

### World 1 pacing (Verdant Crash Site)

| Module | Scrap | Key material (where, when) | Base assembly time | Target cumulative play |
|---|---|---|---|---|
| 1. Hull Frame | 300 | Wreck Plating x3 (tutorial, by hand then by alien) | 1 min | 8 min |
| 2. Thrusters | 1,500 | Glowroot x3 (Forest, any time) | 5 min | 25 min |
| 3. Life Pod | 5,000 | Cave Crystal x3 (Cave, night only) | 12 min | end of day 1 |
| 4. Nav Array | 12,000 | Storm Shard x2 (Meadow, only during Rain weather) | 25 min | day 2 |
| 5. Engine Core | 30,000 | Warden's Core x1 (catch the Warden after Field Notes) | 45 min | day 2 to 3 |

Base assembly time assumes a summed work speed of 1x. An Epic (6x) cuts the Engine Core from 45 minutes to 7.5. Assembly continues offline, so a player who starts a long module before dinner finds it done after.

Income reference: a Common at level 1 produces about 1 Scrap/s at a station. Two aliens pay for the Hull Frame in under 3 minutes. By module 3 a player with six aliens including one Rare makes about 10 Scrap/s. By module 5, ten aliens make about 25 Scrap/s, so 30,000 Scrap is 20 minutes of accrual. Scrap is never the thing that stops the player. The night-only crystal, the rain-only shard, and the Warden are.

### "A little challenging": the Warden finale

The last module of every world needs that world's Core, and the Core comes from catching the world's Warden. The Warden is a Legendary with a unique three-round timing capture (see section 7). The Field Notes quest chain (section 9) leads to a guaranteed Warden encounter, so the challenge is skill and persistence, never luck. If the player fails the capture, the Warden retreats and returns at the next Meteor Shower or after a 15-minute cooldown; nothing is lost. When caught, the Warden becomes the ship's pilot, visible in the cockpit, and its silhouette appears on the launch cinematic. It is the cute-to-epic payoff of the whole world.

World pacing target: World 1 takes 2 to 3 hours of play across 2 to 3 days. World 2 about 4 to 5 days. World 3 about a week. The offline systems make every return feel like progress even when the player only has five minutes.

---

## 4. The aliens

### Two roles per alien

Every alien is a **worker** and a **companion**.

- **Worker:** has one or two jobs at a level. At a station it produces Scrap; in a module slot it assembles. Three jobs at launch, named to feel like play rather than a factory: Gather (collect materials), Build (assemble), Spark (power things up). Auto-assign puts every new catch in its best open slot. A single "Optimize" button re-sorts the camp. Manual placement exists for players who want it.
- **Companion:** up to three aliens follow the player (Pet Simulator pattern) and each gives one small perk while following: slower timing ticker, wider zone, longer radar range, more Scrap from catches, higher luck. Companions are how aliens matter during exploration, not only at camp.

No hunger, no happiness, no upkeep. Aliens never leave, never die, never need feeding.

### Rarity ladder

| Tier | Share of wild spawns | Work speed | Jobs | Camp passive | Where it appears |
|---|---|---|---|---|---|
| Common | ~50% | 1x | 1 job, L1 | none | every biome, any time |
| Uncommon | ~27% | 1.6x | 1 job, L2 | none | every biome, any time |
| Rare | ~15% | 3x | 1 job L3 or 2 jobs L2 | none | one specific biome |
| Epic | ~6% | 6x | 2 jobs, L3 to L4 | none | biome + condition (night or a weather state) |
| Legendary | ~1.5% | 12x | 2 jobs, L4 to L5 | +10% all stations | biome + condition + Tier 2 lure; server-announced |
| Cosmic | Meteor Shower only (~0.2% per event spawn) or quest | max(25x, 2x your best alien) | all jobs, L5 | +25% all stations | 2-hour event or deterministic quest |

Overlays roll on any body, one per alien, multiplicative: Shiny 1.25x (~5%), Gold 1.5x (~1.5%), Crystal 2x (~0.3%), Rainbow 5x (event only). A Rainbow Common out-works a plain Rare and is a visible flex. This is the cheapest way to keep commons exciting late.

### Why commons never become trash

- **Slots:** each station starts with one slot and grows to three. Three Common builders beat an empty slot. A full slot always beats an empty one.
- **Fusion:** four duplicates of a species fuse into +1 level on one copy (max +2). Surplus always has a destination.
- **Codex payout:** the first catch of any species pays Scrap and a decoration. A late Common is worthless as a unit but valuable as an entry.
- **Gather is commons-only:** one job is held only by Common and Uncommon species, so the camp cannot run without them.
- **Sets need them:** every Set in the codex includes commons, so a Set reward is impossible without them (section 9).
- **Size rolls and growth (P1, from the dinosaur-ranch reference in `media/tiktok/NOTES.md` batch 3):** every catch rolls a size (Tiny to Giant, a bell curve) shown on the nameplate and as a visible scale, with a small work-speed bonus at the top end, so the twentieth Mossbop can still be a "whoa, look at the size of it". Aliens at a station also grow Hatchling to Grown to Elder by time worked, each stage a visible size step and a small speed bump. Growth is a reward with no feeding, no hunger and no decay, so pillar 3 holds.

### How value is shown

Four channels at once: the module timer visibly shrinks when a better alien is dropped in; the Scrap/min readout rises; the alien card shows job badges and level pips; the body shows tier and overlay from across the camp. Cosmic stats display as "????" and Cosmics are rideable.

### World 1 example roster (15 species, placeholders)

Naming rule: each alien is an alien-plus-object or alien-plus-tool hybrid describable in three words, with a rhythmic or reduplicated name, one voice line, and one job-tied idle animation.

| Name | Concept (3 words) | Tier | Job | Where / when |
|---|---|---|---|---|
| Mossbop | moss ball, eyes | Common | Gather | Meadow, any |
| Pebblet | pebble with legs | Common | Gather | Cave mouth, any |
| Glimmo | jelly firefly | Common | Spark | Forest, any |
| Twiglet | stick bug, leaf hat | Common | Gather | Forest, any |
| Puffpuff | dandelion puff, face | Common | Build | Meadow, any |
| Snailbyte | snail, metal shell | Uncommon | Gather | Cave, any |
| Buzzlebee | bee, tiny backpack | Uncommon | Gather | Meadow, day |
| Lanternewt | newt, glowing tail | Uncommon | Spark | Forest, night |
| Rocklobber | crab, boulder claws | Rare | Gather L3 | Cave, any |
| Zapfinch | bird, antenna crest | Rare | Spark L3 | Forest, any |
| Sparkfox | fox, glowing paintbrush tail | Rare | Build L3 | Meadow, any |
| Thunderhog | hedgehog, lightning quills | Epic | Spark/Build | Meadow, Rain only |
| Gloomoth | moth, crystal wings | Epic | Gather/Spark | Cave, night only |
| Gaiabloom (Verdant Warden) | stag, tree antlers, flowers bloom where it steps; echo of Gaia | Legendary | all | Field Notes finale |
| Panpipe (secret) | goat, reed pipes; echo of Pan | Secret | all | Unlocked by completing the Verdant codex page |

### The Pantheon: ancient beings as the epic end of the ladder

The top of every world's roster references a figure from ancient mythology, drawn in the same round, big-eyed body as everything else. A tiny chubby sky god with a lightning quill is both cute and epic in one silhouette, which is exactly the ladder this game needs, and the names are instantly recognizable to kids who know these figures from school, books, and games. The pun names also travel well on TikTok.

Three bands use it:

| Band | Tier | Myth source | Role |
|---|---|---|---|
| **Wardens** | Legendary, one per world | A god or spirit matching the world's theme | The world's finale catch and ship pilot (section 3) |
| **Star-born** | Cosmic, Meteor Shower only | Primordial and cosmic beings: sun, sky, time, world-serpents | The rarest wild finds; "fallen from the old sky" |
| **Chimeras** | Secret, Set rewards only | Mythic hybrids: griffin, pegasus, chimera, hydra, cerberus | The reward for completing a Set in the codex (section 9) |

Proposed Wardens and Star-born (placeholders; the pun is the point):

| World | Warden (Legendary) | Echo of | Attribute kept | Star-born example (Cosmic) | Echo of |
|---|---|---|---|---|---|
| Verdant | Gaiabloom | Gaia, Greek earth | flowers bloom in its footprints | Ra-dish | Ra, Egyptian sun; a radiant radish with a sun disk |
| Frostbyte | Skaddle | Skadi, Norse winter | tiny skis, snow-owl body | Fenripup | Fenrir, Norse wolf; a puppy with a moon on its forehead |
| Neon Grid | Hephaestron | Hephaestus, Greek forge | hammer tail, glowing seams | Thothbyte | Thoth, Egyptian knowledge; an ibis with a data-scroll |
| Emberfall | Vulcanine | Vulcan, Roman fire | lava-dog with an ember mane | Quetzalcoodle | Quetzalcoatl, Aztec feathered serpent; a noodle with feathers |
| Tidepool | Poseidolphin | Poseidon, Greek sea | a tiny trident on its nose | Jormungeel | Jormungandr, Norse sea serpent; an eel eating its own tail |
| Dreamdrift | Morpheep | Morpheus, Greek dreams | a sheep that floats | Kronosnail | Kronos, Greek time; a snail with a clock shell |
| Void Hub | Nyxling | Nyx, Greek night | star-speckled | Sphinxie | the Sphinx; a cat that asks riddles |

Chimeras are Set rewards: complete the Greek Set and a quest leads to Pegasus; the Norse Set to Fenrir's cub; the Egyptian Set to the Sphinx; the Myth Beasts Set to Cerberus. Each Chimera is all-jobs, has a unique silhouette, and is never sold.

Rules for the Pantheon:

- **Public domain only.** Greek, Roman, Norse, Egyptian, Mesopotamian, Aztec and Maya, and Celtic figures are free to use. The designs must be original: no Marvel Thor, no Disney Hercules or Maui, no God of War Kratos, no Percy Jackson art. The name pun and one attribute carry the reference; the body is this game's.
- **Ancient pantheons, not living religions.** Avoid deities and sacred figures from religions with large living communities (Hindu, Buddhist, Shinto, Abrahamic). Roblox's Community Standards prohibit content that mocks religion, and the audience is children. Treat the figures used with affection: they are "echoes" the aliens carry, not the gods themselves.
- **Keep the body cute.** The god attribute is one accessory or one silhouette add. Everything else follows the common-tier recipe (round body, big eyes, short limbs). A pompous god voice line in a squeaky little body is the joke and the charm.
- **Ruins as landmarks.** Each world has one ruined shrine to its Warden, a hidden spot with glyphs that hint at the world's other hidden spots and its Set rewards. The Field Notes finale happens at the shrine. This gives every world a landmark worth filming and a reason to read the codex.

---

## 5. Exploration (the Pokémon GO model)

- **Density:** 12 to 20 wild aliens are visible around the player at all times. Commons respawn 60 to 90 seconds after a catch. The world is never empty.
- **Nearby panel:** a small panel lists the species present in this biome right now as silhouettes. Caught species show in color, uncaught as dark silhouettes, secrets as "???". Tapping one shows a compass direction, not a pin. The chase is the content.
- **Compass strip (P1):** a thin strip along the top edge with cardinal letters, the heading number in a small pill, and coloured diamond markers for the camp, the current Field Notes target, the Peddler and any live event, with a "Camp 42m" label under it. Reads better on a phone than a minimap and is what the dinosaur-ranch reference (batch 3) uses for its waypoints.
- **Node markers:** key-material nodes carry a floating verb marker ("✦ Collect") readable from far away; the material name shows only up close. Verbs over nouns at distance tell the player what to do before they know what it is.
- **Gating ladder:** rarity is gated by *where* (biome), *when* (day/night, weather), and *how* (lure tier, companion perks). Day/night cycle is 3 minutes day and 90 seconds night (a 15-minute session gets three nights). Weather rolls randomly for 2 to 5 minutes from the world's own list, and each world has one special weather with a signature alien (section 8).
- **Hidden places:** rares spawn in nested spots: cave depths, treetops, behind a waterfall, under ice. Finding the spot is a one-time discovery that the codex remembers.
- **Secret cues:** a secret alien in the area plays a unique chirp and shows a glint on the horizon. The Nearby panel shows "???". Nothing else is told.
- **Radar:** a tiered, Scrap-upgradable radar that shows nearby aliens as blips, with uncaught species drawn as shadow silhouettes. Full spec in section 6.
- **Gear:** speed boots, a hoverboard, a glider, and rideable aliens make the map bigger as the player gets stronger. Section 6.
- **Meteor Shower:** every 2 hours on a fixed server clock, a 3-minute window. Server-wide banner, sky turns, beacons mark spawns, Epic+ rates rise, Cosmics can appear. It is the only place Cosmics spawn, which turns the rarest find into a shared appointment rather than a private slot machine.
- **Server announcements:** Legendary and Cosmic spawns announce to the whole server with location, the pattern Steal a Brainrot and Steal an Egg use. Seeing someone else's catch is content. Every catch of Rare and above (the threshold is `Config.AnnounceMinTier`) also posts a server-wide banner in the tier's colour naming the player, the rarity and the species ("Ethan caught a Shiny Epic Thunderhog!"), so rarity is read aloud to the whole server, not just to the catcher.

---

## 6. Gear, mounts, power-ups, radar, and luck

Exploration tools are the second progression track beside the ship. They make the map bigger as the player gets stronger (speed, height, water), they are the most natural things to sell on Roblox (speed coils, hoverboards, and vehicles are platform staples in Pet Simulator 99, Adopt Me, and Bloxburg), and they live exactly where the research says monetization belongs: convenience and cosmetics, never income.

Two rules govern everything in this section. **Everything is earnable with Scrap or quests**; Robux buys skins or an early unlock of something a player would get anyway. **Nothing here is required to catch commons or to finish a module.** Gear opens shortcuts and hidden spots. It never gates the ship bar.

### Movement gear (permanent unlocks)

| Tier | Gear | Effect | How to earn | Robux |
|---|---|---|---|---|
| 0 | Walk | base speed, single jump | | |
| 1 | Speed Boots | +25% speed | Field Notes step 1, or 800 Scrap | skins only |
| 2 | Hoverboard (the skateboard) | +60% speed, trick animations on jumps, dismounts in caves | 5,000 Scrap, or codex 50% on World 1 | skins (neon, flame, pizza, cardboard box) 99 to 299 |
| 3 | Glider Pack | hold jump to glide; reaches treetops and rooftops, which is where several Rares and hidden spots live | 15,000 Scrap, or first launch | skins |
| 4 | Jet Boost | short vertical burst on a cooldown | World 3 Field Notes | skins |
| World gear | Ice Skates (Frostbyte), Swim Fins (Tidepool), Heat Suit (Emberfall), Mag Boots (Neon Grid) | the traversal each world's rule needs | that world's Field Notes step 2 | skins |

The Hoverboard is the one to get right. It is the thing players will film: a cute alien riding behind a kid on a pizza-skinned board doing a kickflip over a crater is a ten-second clip. Give it three trick animations and a landing sound.

An "Explorer Pack" that unlocks tiers 1 to 3 at once for about 399 Robux is acceptable because every piece is also earnable and the paid speed equals the earned speed. Never sell a speed that cannot be earned.

### Mounts (rideable aliens)

Some species carry a **Ride** trait: every Cosmic and every Warden, plus one or two Epic species per world. Riding an alien gives a traversal type and a speed set by its tier:

| Traversal | What it does | Example (placeholder) |
|---|---|---|
| Sprint | fastest ground movement, big leap | Thunderhog (World 1 Epic), Gaiabloom |
| Hover | ignores slow terrain, crosses small gaps and ice | a yeti-slug on Frostbyte |
| Glide | long glide from any height | a drone-cat on Neon Grid |
| Swim | fast swimming and diving | a manta on Tidepool |
| Climb | runs up walls | a gecko-bot on Neon Grid |

Epic mounts match Hoverboard speed. Legendary mounts are 20% faster. Cosmic mounts are 40% faster with a unique trail and the "????" stat card. Riding uses one of the three companion slots, so a mounted alien is a visible, deliberate choice. Mounts are the biggest social flex in the game: everyone on the server sees what you ride, and the Warden you fought for becomes the thing you arrive on. Saddle and harness cosmetics are sold; the mounts themselves are never sold.

### Power-ups (consumables)

| Power-up | Effect | Duration | Sources |
|---|---|---|---|
| Speed Burst | +50% speed | 60 s | Peddler, spins, event tracks |
| Steady Hands | timing zones +30% wider | 10 min | Peddler, quests |
| Scanner Pulse | reveals every hidden spot and every uncaught alien in the biome on the radar | 60 s | quests, spins |
| Lucky Charm | +50% personal luck | 10 min | quests, spins, Welcome Week, events. Earned only |
| Scrap Magnet | catches pay +50% Scrap | 10 min | Peddler, spins |
| Double Shift | stations produce 2x Scrap | 10 min | spins and event tracks only. Never sold |

Rules: one active per type, timers run only while online so a kid never wastes one by closing the app, active buffs show as small rings under the ship bar, and activation has a sound and a brief screen tint. Speed Burst, Steady Hands, and Scrap Magnet may be sold in fixed bundles (no randomness). Lucky Charm and Double Shift stay earned-only: one is a probability modifier and the other is the income multiplier the research warns against selling.

### The Radar

The radar is the shadow idea made into a progression item. Uncaught species always appear as **shadow silhouettes**, both on the radar and in the world, and the silhouettes are the same art the codex uses, so the radar is literally a to-do list for the codex.

| Tier | Radar | Range | What it shows | How to earn | Robux |
|---|---|---|---|---|---|
| 0 | Nearby panel (free) | this biome | species present now: caught in color, uncaught as shadows, secrets as "???"; compass direction only | always | |
| 1 | Radar Mk1 | 120 studs | minimap blips; uncaught species as shadow silhouettes with a rarity-colored outline; tap a blip to set a waypoint | Field Notes step 2, or 1,500 Scrap | early unlock 149; skins |
| 2 | Radar Mk2 | 250 studs | hidden spots once you have passed within 50 studs; for rares that are not here right now, the condition they need ("appears: night, Rain"); a "???" ping and a heartbeat sound that quickens as you approach a secret | 8,000 Scrap, or World 2 | skins |
| 3 | Radar Mk3 | whole biome | Meteor Shower spawn preview 30 seconds early; a glint icon on any spawn carrying an overlay within 60 studs | 25,000 Scrap, or World 3 | skins |

**Shadow reveal in the world:** uncaught species render as dark silhouettes beyond about 40 studs and resolve into full color as the player approaches. Every first sighting becomes a small "Who's that?" moment, and it costs almost nothing to build: a client-side material swap keyed on the player's codex. An accessibility toggle turns it off.

No radar tier is Robux-only. The Mk1 early unlock is deterministic and the same item players earn in the first half hour.

### Luck

Luck is one visible number, "Luck x1.0," under the ship bar. Tapping it shows the exact tier odds with current luck applied, which is both a dopamine readout and the disclosure Roblox requires for any paid modifier.

**What luck affects.** Wild aliens spawn around players, and the server rolls each spawn's tier using the **highest luck among the players nearby**. That makes luck social: standing next to a lucky friend makes your spawns better, which is Steal a Brainrot's shared server luck turned into a reason to explore together. Luck also raises the overlay roll on your own catches and improves Peddler stock quality. It never touches the spin wheel, whose odds stay fixed and published.

**How it scales.** Each tier's share above Common is multiplied by Luck and Common absorbs the difference. At 4x luck, Legendary goes from 1.5% to 6% and Epic from 6% to 24%. Total luck is capped at 8x, the same ceiling Steal a Brainrot's stacked server luck reaches.

| Source | Bonus | Duration | Notes |
|---|---|---|---|
| Companion perks | +10% to +25% each, up to three | while following | the main permanent source |
| Lucky Charm | +50% | 10 min | earned only |
| Night, for night-conditional species | +25% | while night | shows on the readout |
| Weekly Weather and seasonal events | +100% | event window | section 12 |
| Meteor Shower | +200% server-wide | 3 min | section 5 |
| Codex page complete | +5% permanent per world page | forever | the collector's reward |
| Server Luck (purchased) | 2x or 4x, shared by all eight players | 15 min | 249 / 999 Robux, full disclosure, PolicyService gated |
| Soft pity ("scanner charge") | rises each catch without a Rare+, resets on one | until a Rare+ | shown inside the readout |

**Monetization stance.** Sell shared server luck at launch, as the monetization section already does. A permanent personal luck pass (x1.5 for 299 to 399 Robux) is the Roblox norm and converts well, but it is a probability modifier bought by a kids-skewed audience, so it is listed as a later option, not a launch SKU. If it ships, it needs the same disclosure and PolicyService gate as server luck, and the readout must show it.

---

## 7. The capture minigame

The team's instinct is right: a timing bar is the single best fit for one-thumb play and it adds skill expression without stress.

### Spec

1. Walk within 8 studs and tap the alien (or its "!" bubble). The camera zooms, the world dims.
2. A horizontal bar appears with a ticker sweeping left to right and back.
3. Zones: outer grey (Miss), green (Good), gold center (Perfect). Tap, click, or space to stop the ticker.
4. **Perfect:** guaranteed catch, bonus Scrap, "PERFECT" stamp, a slightly louder reveal.
5. **Good:** catch roll by tier (Common 100%, Uncommon 90%, Rare 75%, Epic 60%, Legendary 50%). On a failed roll the alien wiggles free and the ticker sweeps again. Up to 3 sweeps per encounter.
6. **Miss:** costs one sweep. After 3 failed sweeps the alien flees. Commons reappear nearby in 60 seconds. Rares vanish until their condition next returns, but the radar marks the spot.

### Difficulty by tier

| Tier | Ticker speed | Zone width (Good / Perfect) | Rounds |
|---|---|---|---|
| Common | slow | 40% / 12% | 1 |
| Uncommon | slow | 34% / 10% | 1 |
| Rare | medium | 26% / 8% | 1 |
| Epic | medium-fast | 20% / 6% | 1 |
| Legendary | fast, zone drifts | 16% / 5% | 3 |
| Cosmic / Warden | fast, zone drifts and shrinks | 14% / 4% | 3, with a unique pattern per Warden |

Legendary and Warden captures are three rounds: between rounds the alien does a short "attack" animation (the Warden stomps, the screen shakes) and the bar changes pattern. This is the boss fight of a game with no combat.

### Fairness and feel

- **Lures:** crafted from Scrap in three tiers; each tier widens both zones. A player who meets a Legendary with a Tier 1 lure has a reason to come back, not a dead roll.
- **Companions:** perks like slower ticker or wider zone stack with lures.
- **Hidden kindness:** after two misses on the same alien the zone widens 20%. Kids should never rage-quit a catch.
- **Easy Catch toggle:** an accessibility option that widens zones permanently and slows the ticker. Never sold.
- **Near-miss display:** when the ticker stops just outside the zone, the zone flashes and the miss is shown. Near-misses are the strongest "one more try" signal in timing games.
- **Haptics and sound:** a tick per sweep, a rising tone as the ticker approaches the zone, a clean hit sound, a longer sound ladder per tier on the reveal.

### Anti-exploit note

The server owns the encounter: it generates the ticker speed, zone position, and a start timestamp, and sends them to the client. The client reports its tap time. The server computes the ticker position with about a 100 ms latency allowance and rejects impossible inputs. The minigame is cheap to validate and must not trust the client's "I hit Perfect."

---

## 8. Worlds

Each world is a separate Roblox place in one universe, handcrafted, with three biomes, 12 to 15 species, one Warden, one or two secrets, and one new rule. Themes change the constraint, not just the skin.

| # | World (placeholder) | Biomes | New rule | Key materials | Notes |
|---|---|---|---|---|---|
| 1 | Verdant Crash Site | Meadow, Forest, Cave | Day/night, Rain | Glowroot, Cave Crystal, Storm Shard, Warden's Core | Gentle tutorial world. Warden: Gaiabloom |
| 2 | Frostbyte | Snowfield, Ice Cave, Geyser Field | Blizzards hide aliens; place a Heater (Scrap) to reveal them for 60 s | Frost Core, Geyser Pearl | Introduces placing a tool in the world. Warden: Skaddle |
| 3 | Neon Grid | Rooftops, Server Farm, Undercity | Day is dim; night is neon and busy; Power Surges (weather) spawn Epics; new job: Tinker | Data Shard, Surge Cell | Adds a 4th job and a 4th station. Warden: Hephaestron |
| 4 | Emberfall | Lava Fields, Obsidian Caves, Ash Forest | Heat meter: stay near Cooling Vents or return to camp; eruptions are the weather event | Magma Core, Obsidian Lens | First world with a light pressure mechanic. Warden: Vulcanine |
| 5 | Tidepool | Reef, Kelp Forest, Trench | Swimming and diving; tides as the weather cycle | Pearl Core, Abyss Glass | Warden: Poseidolphin |
| 6 | Dreamdrift | Candy Cliffs, Cloud Sea, Music Box Hollow | Gravity flips as the weather event | Dream Core | Warden: Morpheep |
| 7 | The Void Hub | Endgame | All Wardens needed to open the gate | | Long-term goal. Warden: Nyxling |

### World signatures: every world adds one verb (2026-10-05)

A world is not a palette swap. Each one adds a way of playing the other worlds do not have, one special area that changes the rules inside it, one super-rare alien caught through a harder version of the minigame, and one secret spot reached by movement (a short obby, a glide, a dive). The first two worlds keep their built mechanics; the rest are the design intent for their builds.

| World | Signature verb (how you catch and move) | Special area | Super-rare and its harder minigame | Secret spot |
|---|---|---|---|---|
| 1 Verdant Crash Site | The baseline: walk, tap, timing bar | The Shrine of the Warden (built) | Gaiabloom through the Field Notes finale (built) | A treetop hollow reached by a log-hop obby; Glider later |
| 2 Frostbyte | Place Heaters to reveal (built); ice patches slide you | A geyser that lifts you to a ledge on its timer | Fenripup in a Meteor Shower (built); Skaddle finale (built) | An ice cave behind a waterfall of snow, a timed jump across geyser plumes |
| 3 Neon Grid | Rooftop parkour: jumps, zip lines, vents that launch you; robotic and cyberpunk aliens that only power up at night | The Server Farm core room: a Power Surge boosts luck and spawn speed inside while it runs | A chrome Legendary that flees across rooftops: the bar moves while you chase it on a timer | A hidden arcade under the Undercity, entered by a three-part vent obby |
| 4 Emberfall | Heat runs: dash between Cooling Vents before the meter fills | The Obsidian Caves' crystal garden: cool, slow, where Rares nest | A lava Warden whose zone shrinks with the heat meter: a two-stage catch | A magma bridge that only forms during Ashfall |
| 5 Tidepool | Fishing: aliens are fish; cast from the shore or dive, then a cast-and-reel bar (the zone drifts like a bobber; hold to reel, release to let it run) | A bioluminescent fountain in the Trench: everything glows, catches inside give +luck, and the fountain's own glowing fish spawn only there | A Cosmic deep-sea fish caught through a double bar (reel plus a second tension bar) during King Tide | A sunken ship's hold reached by a breath-limited dive through a kelp maze |
| 6 Dreamdrift | A parkour world: gravity flips (built as weather) turn the Candy Cliffs into ceilings; whole routes are obbies | The Music Box Hollow: a rhythm floor where catches land on the beat for a perfect | A Legendary that only appears mid-flip, caught upside down on a timer | A cloud stair that exists only while you keep jumping |
| 7 The Void Hub | Everything learned: a gauntlet that reuses each world's verb | The Gate | The Eclipse alien through the hardest bar, every mechanic at once | None: the world is the secret |

Rules: a signature verb never gates the ship bar (the modules are still built from catches and materials), a special area is visible from far away so it pulls players across the map, the harder minigame is a variant of the one bar (new rules on the same control), and secret spots are logged in the codex as hidden spots with a Scanner Pulse hint. Build order: the fishing bar (Tidepool) and the rooftop chase (Neon Grid) are the two new catch variants and come first; the obbies use the engine's own movement and need level design more than code.

### One special weather per world

Every world has exactly one special weather state that only it rolls, and one signature alien that spawns only while it runs. The clock rolls the special weather at its own chance whenever the weather changes, so it is an appointment players learn to wait for, and its arrival posts a server-wide banner naming the alien ("Blizzard! Frostfang is out!"). This is `Worlds.luau` data, so adding a world's weather is a row, not code. Placeholders until each world is built:

| World | Normal weathers | Special weather | Signature alien |
|---|---|---|---|
| Verdant Crash Site | Clear, Fog | Rain | Thunderhog (Epic) |
| Frostbyte | Clear, Snow | Blizzard | Frostfang |
| Neon Grid | Clear, Smog | Power Surge | Voltwisp |
| Emberfall | Clear, Haze | Ashfall | Cinderling |
| Tidepool | Clear, Mist | King Tide | Pearlback |
| Dreamdrift | Clear, Drift | Gravity Flip | Floatling |
| The Void Hub | Clear | Eclipse | Shadeling |

The special weather also gates one key material per world where that fits (Storm Shards fall only in Rain), so the same window serves the collector and the ship builder.

What carries forward: the ship, the roster, the codex, Scrap, the home planet. What stays behind becomes an Outpost.

### Outposts: every planet stays relevant

When the player launches, the camp converts into an **Outpost**. Outposts:

- keep producing that world's key materials slowly and a trickle of Scrap, offline too;
- can be upgraded with Scrap for higher output;
- are needed because later ships require earlier worlds' materials (World 3's Nav Array needs Frost Cores from World 2 and Glowroot from World 1);
- host a rotating **daily world quest** ("catch a night alien on Frostbyte") that pays Scrap and spins;
- are where world-exclusive aliens live, which later Sets need.

A **Star Chart** on the ship lets the player fly back to any unlocked world instantly. Returning to World 1 as a veteran with Epics and a wide-zone lure should feel like a victory lap, and the codex should still have something there to find.

---

## 9. Codex, quests, and Sets (the Dragon City index without the breeding)

### Codex

One page per world. Each species has an entry with a silhouette until caught, then the model, its voice line, its jobs, where it was found, how many caught, and the best overlay owned. The codex also has **Sets**: themed groups that cut across worlds, such as the Greek Set, the Norse Set, the Egyptian Set, and the Myth Beasts Set (Pegasus, Cerberus, Hydra, Griffin). Each Set is a page of silhouettes with its own completion bar and a reward (a title, a cosmetic, and for the mythology Sets a Cosmic quest), so a kid who recognises Zeus and Thor has a reason to chase the whole family. First catch pays Scrap and a camp decoration. Page completion milestones (50%, 100%) pay cosmetics, spins, and the title for that world. The codex also tracks discovered hidden spots. Completion percent is shown everywhere a bar can fit.

Entry layout, copied from the dinosaur-ranch reference (batch 3, `docs/vault/05-ui-design/refs/dino-codex-entry.jpg`): a 3D viewport of the alien on a round pedestal that the player drags to rotate, an Idle / Move toggle that previews its animation, the rarity tag, its jobs, a "Found: Meadow, Rain" line built from its biome and condition, caught count and best overlay. An uncaught species shows the same card with a black "?" silhouette, the name "???", the backdrop in its rarity colour, and one hint line ("Appears in the Meadow during Rain"), which is the whole Nearby-panel promise in one place.

### Field Notes (per-world quest chain)

Five steps, modeled on Pokémon GO's Special Research: never expires, one step at a time, each step pays something.

Example for World 1:

1. Catch 5 aliens. Reward: Tier 1 lure.
2. Catch a night alien and find the Cave's hidden pool. Reward: 500 Scrap.
3. Craft a Tier 2 lure and catch a Rare. Reward: a spin.
4. Catch an Epic during Rain. Reward: the Warden's call (a horn item).
5. Sound the horn at the Shrine of Gaiabloom at night. Reward: guaranteed Gaiabloom encounter.

Each world's Field Notes is written as a short legend the aliens tell about their Warden ("the earth mother sleeps where the flowers never close"), and the shrine where it ends is that world's landmark.

Later worlds add a twist to step 5 (sound the horn during a Blizzard, during a Power Surge).

### Sets (secret aliens from completing the right group)

No breeding and no lab. The team decided the game stays a simple, low-maintenance collection loop, so Secrets come from the codex itself.

- Every Set is a themed page of silhouettes that cuts across worlds: the Greek Set, the Norse Set, the Egyptian Set, the Myth Beasts Set, plus small flavour Sets (Night Owls, Rain Chasers, Hoverboard Riders).
- Each Set shows its own completion bar and reward. Milestones at 50% pay Scrap and a cosmetic; 100% unlocks a short quest that ends in a guaranteed Secret encounter.
- Sets send players back to earlier worlds, because every Set includes commons from more than one planet.
- Nothing about a Set is random: the player can see exactly which silhouettes are missing and where each one lives.

Secrets are the top of the codex, the long-term goal for collectors, and never sold.

---

## 10. The home planet

Unlocks on the first launch, as the reward for finishing World 1. It is the player's persistent showcase and the place friends visit.

- **House (Bloxburg-lite):** modular prefab rooms and furniture on a grid, paid in Scrap. Plot size and furniture caps are the monetized capacity. No free-form building (data size and scope).
- **Habitats:** themed enclosures per world (a frost habitat, a neon habitat). Displayed aliens roam and produce a little Scrap passively (Dragon City habitats). Habitat count is a capacity upgrade.
- **Trophy Hangar:** a scaled model of every ship the player has launched, with the Warden pilot in each cockpit.
- **Spin Wheel kiosk, Mailbox** (gifts from friends and events), **Visitor Book.**
- **Visiting:** friends can visit when the owner is online or offline (loaded from the owner's save). Lock levels: owner only, friends, anyone. Visitors can "Wave" at displayed aliens for a tiny bonus to both players.

Keep Scrap as the only spendable currency. Home decor is priced below ship parts so building a house never blocks a launch.

---

## 11. Retention systems

- **Offline accrual:** Scrap accrues at 50% rate while away, capped at about 60 minutes of income; module assembly continues at full speed. The return is always a chest and often a snapped-on part.
- **Welcome Week:** seven gifts that unlock by *days played*, not consecutive days. Missing a day loses nothing. Day 7 is an Epic alien egg hatched in the free loop with odds shown. (Login *streaks* are a named target in the EU's September 2026 KIDS Act proposal, so the track is built as "seven gifts" rather than "seven days in a row" from the start.)
- **Daily quests (3) and weekly quests (3):** Scrap, lures, spins.
- **Spin Wheel:** one free spin per day plus spins earned from quests and codex milestones. Every segment has value (Scrap, lures, a temporary Shiny charm, a cosmetic, a rare companion-slot token). No "nothing" segment.
- **Limited-time events** at four cadences, from the 5-minute Peddler to monthly seasonal events. See section 12.

### Paid spins: how to do them within the rules

Roblox's paid random items policy applies to anything random bought with Robux or Robux-derived currency. Paid spins are allowed if, and only if:

- every segment's odds are shown numerically before purchase and sum to 100%;
- every outcome gives real value (no dud segment);
- any active luck boost is disclosed numerically and the displayed odds update live;
- the purchase is hidden for players where `PolicyService.ArePaidRandomItemsRestricted` is true (UK under 18, all of Australia, Brazilian minors today) and a deterministic alternative is offered instead;
- paid spins never contain exclusive aliens. Cosmetics, Scrap, lures, and boosts only. Aliens are earned.

Build the wheel so that the paid path can be switched off per region without touching the free path. If the EU proposal passes, the game keeps working.

---

## 12. Limited-time events

Grow a Garden is the right model. Every record it set was an event: 8.9M concurrent during the "Monster Mash World Record" weekend in June 2025, 22.3M during the Admin War against Steal a Brainrot on August 23, 2025 (the day Roblox itself hit a 47.4M platform record). Steal a Brainrot's 24.1M came during its "Extinct Event." Both games' *average* concurrency at their height was roughly a tenth of their event peaks. Events are the single biggest lever on player count, and they are also what creators stream, which is where new players come from.

The pieces the hits reuse: weekly exclusives that leave after seven days, event-only mutations that exist only during a themed window (Steal a Brainrot's Bloodrot, Candy, Galaxy, and Lava are event-limited; Gold, Diamond, and Rainbow are permanent), weather that mutates things in front of the whole server, a shop that restocks on a five-minute clock so every visit is a lottery ticket, retired content that becomes prestige (Adopt Me's 2019 Shadow and Frost Dragons are its most valuable pets because supply stopped), live developer-hosted windows with drops for everyone logged in, and head-to-head "world record" framing that streamers can rally around.

### Four cadences

| Cadence | Event | What happens | Cost to build |
|---|---|---|---|
| **Every 5 min (always on)** | The Peddler | A small alien merchant ship lands at camp with three rotating offers for Scrap: lures, a Scrap bundle, decor, and a small chance of a Rare or Epic alien egg. Stock is server-wide and shared, so players tell each other what landed. Grow a Garden's seed shop, re-skinned. | Low: one data table, one landing animation |
| **Every 2 h (always on)** | Meteor Shower | Already in section 5. The only Cosmic spawn. | In P0 |
| **Weekly (Friday, fixed time)** | Alien of the Week + Weekly Weather + one hosted Shower Storm | One limited species spawns for seven days, then is Vaulted. One themed weather state exists only that week and applies a week-only overlay. One Meteor Shower that week is hosted live by the developers with server luck gifted to everyone and a guaranteed Cosmic somewhere on every server. | Medium: one species and one overlay per week; the hosted hour is scheduling, not code |
| **Monthly (2 weeks on, 2 off)** | Themed seasonal event | A theme layered over existing worlds, not a new world: sky, music, camp decor, an event quest track with milestone rewards, two to three event aliens, one event overlay, limited cosmetics. Alternates with new-world launches so there is always something on. | High: this is the two-week content drop |
| **Quarterly or at milestones** | Live record attempt | A streamed weekend with a community goal ("catch 10 million aliens together"), celebrity and creator servers, and a one-time Cosmic. This is the Admin War pattern. | Low in code (global counter plus boosted tables), high in coordination |

### Event theme calendar (first year, placeholders)

| Month | Theme | Overlay (event-only) | Event aliens | Hook |
|---|---|---|---|---|
| Launch month | First Landing | Launch Gold (1.5x, retired after) | 1 launch-week alien | Players who were there first keep proof |
| October | Haunted Nebula | Spectral (2x, translucent, trails) | Ghost-themed species on World 1 | Night lasts twice as long all event |
| December | Frostfall | Frosted (2x, ice shell) | Snow species across worlds | Snow falls on every world, including Verdant |
| February | Starlight Bloom | Blossom (2x, petals) | Pollinator species | Weather is always Clear with aurora |
| April | Egg Hunt | Speckled (2x) | Hatchling species found as eggs hidden in biomes | Eggs replace spawns; find-and-tap hunt |
| June | Solar Flare | Solar (2x, heat shimmer) | Sun species | Meteor Showers twice as often |
| Every seasonal event | Vault Rotation | none | Two or three Vaulted aliens return for the event | A rerun every month (see below) |
| Anniversary | Vault Reopening | none | Every Vaulted alien returns for one week | The big rerun |

Each world launch (section 8) is also treated as an event: a "First Landing" week with double key material drops and a launch-week limited alien.

### Event mechanics the whole system reuses

- **Event quest track:** a free milestone track (catch 20 event aliens, catch one with the event overlay, finish three Showers) that pays Scrap, lures, spins, decor, and finally the event's rarest alien. No second currency. Everything is earnable in roughly 2 to 3 hours of total play across the two weeks.
- **Event overlays:** multiplicative like permanent overlays, tier-sized (2x) because they are scarce, and they stop rolling when the event ends. An alien caught with a Spectral overlay in October is permanently proof of October.
- **Vaulting:** when an event or weekly alien leaves, its codex entry gets a "Vaulted" stamp and the silhouette stays visible to everyone. Vaulted aliens never get stronger than current ones; their value is prestige, not power, so missing one does not cost progress.
- **Server-wide luck, gifted:** developers can grant every server a free luck window during hosted events. It is the same mechanic sold in section 14, which makes the hosted hour feel generous.
- **Global counter:** a universe-wide tally (MemoryStore plus a DataStore checkpoint) drives community goals and unlocks a shared reward when the number is hit. Pokémon GO's Global Challenges and Grow a Garden's record attempts both run on this.
- **Event banner:** a persistent HUD banner with the event name, the end date, and the next hosted window, in the same slot the Shower countdown uses. Players always know what is on and when it ends. Anatomy (batch 3 reference, in the UI Playbook): a dark pill top centre with the event icon on the left, the name in bold with the time left beneath it, and a green "1.5x LUCK" chip on the right whenever the event changes luck.
- **Warden sightings (P1):** on a timer, the world's Warden crosses the map in the open (Gaiabloom walks the Meadow at dusk, flowers blooming behind it), uncatchable until the Field Notes finale, with a server-wide toast. The dinosaur-ranch reference opens with a sea giant breaching beside the player's boat; a spectacle that costs nothing and gives everyone online the same thing to film.

### Rules for a young audience

- **Announce the end date on day one** and never run a "last chance" countdown louder than the normal banner. The EU KIDS Act proposal names pressure loops and login streaks; a visible calendar is not a pressure loop, a flashing countdown is.
- **Nothing event-exclusive is ever sold.** Event aliens come from the quest track and spawns. Event cosmetics may be sold. Event overlays roll only on free catches.
- **Prestige over power.** Event aliens and overlays are never required for a module, a Set, or a Warden. Players who skip an event lose nothing on the ship bar.
- **Reruns are regular.** Two or three Vaulted aliens come back with every monthly seasonal event, and all of them return for the anniversary week. Adopt Me's permanent retirement creates trading value, but this game has no trading at launch, so permanent retirement would only create regret.
- **Events boost the free loop first.** Doubled key materials, more Showers, longer nights: the best event rewards are things players would have wanted anyway, arriving faster.

### Tooling for two people

Build events as data, not code, from day one:

- An **event config** (start and end timestamps, spawn table overrides, overlay table, weather override, banner text, quest track) loaded through Configs so an event can be scheduled, extended, or ended without a restart.
- A **developer panel** that triggers server-wide effects (luck window, forced Shower, forced weather, announcement) across all servers through MessagingService. This is what "admin abuse" is mechanically.
- A **content checklist per weekly drop:** one species (mesh family plus overlay variants), one voice line, one idle, one codex entry, one spawn rule. If a weekly alien takes more than two days of work, it is too elaborate.
- **Scheduled, not improvised.** Publish the month's calendar in-game and on socials. Creators plan streams around known windows; a surprise event only reaches players who were already online.

### What events are not

Events spike concurrency about tenfold for a day; they do not set the baseline. 99 Nights in the Forest held its chart position after pausing weekly updates because the loop was deep, and Roblox's 2026 discovery algorithm scores 28 days of return behavior, which weekly and monthly events feed directly. Events are how the game gets seen. The ship bar, the catch, and the codex are why players stay.

---

## 13. Multiplayer

- **World servers:** MaxPlayers 8, PreferredPlayers 6, eight fixed camp slots, one or two social slots reserved for friends. Camps restore from the player's save on join.
- **Co-op:** platform Party (up to 6) plus the Party API and reserved servers for a private world instance. Progress stays per player; only the instance is shared.
- **Home planet visiting:** friends load the owner's home from the save, online or offline.
- **No trading at launch.** Add a gated system later (license quiz, 30-day log, two-step confirm, item caps).
- **Visit and borrow instead of steal:** a friend lends an alien to your module slot for a timed window, keeps ownership, both get a bonus. A raid mode is parked: the team likes it but worries it is too close to other games, so it waits for a later decision. Given the 2025 to 2026 lawsuits around Roblox and kids, theft is not the launch hook.
- **Design for no chat.** Roblox segments chat by age group since January 2026. Waves, emotes, gifts, visible camps, and server announcements carry the social load.
- **Co-play is a first-class metric.** The share of play that happens with friends is something Roblox's discovery system rewards, and a creator who nearly reached number one named its absence as the thing that stopped them. Design it in and show it: a **Friend Boost** readout on the HUD (+5% Scrap and +5% luck per friend on the planet, up to three, the pattern Steal an Egg shows as "Friend Boost +0%"), a daily quest that needs a friend ("catch five aliens on the same planet as a friend"), one Field Notes step per world that is faster with a party, the shared Meteor Shower, borrowing, and home visits. Log friend-in-server, party size, visits and borrows from day one so co-play can be read off the dashboard.

---

## 14. Monetization and the Robux Shop

Rule: keep randomness in the free loop; sell certainty, capacity, convenience, and cosmetics. Everything that affects the ship bar is earnable. Robux buys things faster, prettier, or bigger, never things that are otherwise impossible.

### The shop

A single Shop button on the HUD opens a store with six tabs. The Featured tab rotates weekly with the event calendar. Every price shows its real-currency equivalent beneath it. Regional pricing is on from day one (Roblox reports 4 to 10% more total spend and 43 to 52% more pass purchases in discounted regions).

| Tab | What lives there |
|---|---|
| Featured | Starter Pack, this week's hoverboard skin, the current event's cosmetics, one bundle |
| Aliens | direct-buy Rare and Epic aliens, alien hats, trails, name colors, companion slot |
| Camp & Ship | station slots, auto-collect, auto-optimize, longer offline shift, hull skins, module rush |
| Gear & Style | Explorer Pack, hoverboard and glider skins, trick packs, saddles, radar skins, emotes |
| Boosts | power-up bundles, server luck, module rush |
| Home | plot expansion, habitat slots, furniture cap, house themes, visitor fireworks |
| Spins | spin bundles with full odds shown, hidden where restricted |

### Catalog

Prices use Roblox's standard anchors (49, 99, 149, 199, 299, 399, 799, 999, 1,699). Items under 50 Robux are impulse buys; passes are the recurring earners. The research's developer-education sources report that games with five or more passes earn about 2.3x more than games with fewer, with the caveat that the methodology was not disclosed.

**Aliens**

| Item | Type | R$ | Earnable alternative | Notes |
|---|---|---|---|---|
| Direct-buy Rare alien (choose species) | Dev Product | 99 | wild catch | Deterministic; the player picks the species |
| Direct-buy Epic alien (choose species) | Dev Product | 199 | wild catch | Never Legendary or above; event aliens never |
| Alien hats and accessories | Cosmetic | 49 to 99 | some from codex milestones | Per-alien or account-wide |
| Alien trails and auras | Cosmetic | 99 to 149 | event tracks | Cosmetic only; never confused with overlays (different VFX language) |
| Name color and nameplate | Cosmetic | 49 | | |
| +1 companion slot (3 to 4) | Pass | 249 | | Capacity; a 4th perk, not a stronger one |

**Camp & Ship**

| Item | Type | R$ | Earnable alternative | Notes |
|---|---|---|---|---|
| +1 slot on one station | Pass | 149 | slots grow with worlds | Capacity |
| +1 slot on every station | Pass | 399 | | The best-value pass; expect it to be the top earner |
| +2 slots on every station | Pass | 799 | | |
| Auto-collect | Pass | 199 | tap to collect | Convenience |
| Auto-optimize (always best assignment) | Pass | 299 | Optimize button | Convenience |
| Longer offline shift (cap 60 to 180 min) | Pass | 299 | | Same rate, longer cap. Convenience for kids who play once a day |
| Module rush | Dev Product | 29 / 59 / 99 | wait or add aliens | Priced by remaining time; deterministic |
| Hull skins | Cosmetic | 99 to 299 | one per world from codex 100% | The ship is on screen all the time; this is prime cosmetic space |
| Landing and launch VFX | Cosmetic | 99 to 199 | | Seen by the whole server at launch |
| Camp decor packs | Cosmetic | 49 to 199 | codex decorations | |

**Gear & Style**

| Item | Type | R$ | Earnable alternative | Notes |
|---|---|---|---|---|
| Explorer Pack (gear tiers 1 to 3 now) | Pass | 399 | Scrap and quests | Paid speed equals earned speed |
| Hoverboard skins | Cosmetic | 99 to 299 | one from codex 50% | The cosmetic headline; new skin weekly |
| Trick packs (3 new trick animations) | Cosmetic | 99 | | Clip fuel |
| Glider skins, radar skins | Cosmetic | 99 to 149 | | |
| Mount saddles and harnesses | Cosmetic | 99 to 199 | | Mounts themselves never sold |
| Emotes and dances | Cosmetic | 49 to 99 | some from quests | The no-chat social layer |

**Boosts**

| Item | Type | R$ | Earnable alternative | Notes |
|---|---|---|---|---|
| Speed Burst x5 | Dev Product | 49 | Peddler, spins | Fixed bundle |
| Steady Hands x3 | Dev Product | 79 | Peddler, quests | Fixed bundle |
| Scrap Magnet x3 | Dev Product | 99 | Peddler, spins | Catch bonus, not station income |
| Server luck 2x, 15 min | Dev Product | 249 | Meteor Shower, events | Shared by all 8 players; odds shown live; PolicyService gated |
| Server luck 4x, 15 min | Dev Product | 999 | | Same rules |

**Home**

| Item | Type | R$ | Earnable alternative | Notes |
|---|---|---|---|---|
| Plot expansion (two steps) | Pass | 199 / 399 | | Bloxburg's 30x30 to 50x50 pattern |
| Habitat slot | Pass | 149 each, 499 for four | one per world launched | Dragon City habitats |
| Furniture cap (double) | Pass | 199 | | Adopt Me's 4,000 to 8,000 pattern |
| House themes (frost, neon, candy) | Cosmetic | 99 to 299 | | Matches world themes |
| Visitor fireworks and welcome signs | Cosmetic | 49 to 99 | | Seen by visitors |

**Spins and offers**

| Item | Type | R$ | Notes |
|---|---|---|---|
| 1 spin / 5 spins / 12 spins | Dev Product | 49 / 199 / 399 | Full numeric odds, no dud segment, hidden where restricted, cosmetics and consumables only |
| Starter Pack (one per account) | Dev Product | 199 | A chosen Rare alien, a hoverboard skin, 5 spins, Speed Boots now. Always available; no countdown |
| Launch Pack (unlocks at first launch) | Dev Product | 299 | Home plot expansion step 1, a habitat slot, a house theme. Appears once, at the moment the home planet unlocks |
| Supporter tip (badge) | Dev Product | 25 / 100 / 500 | A cosmetic supporter badge and a thank-you in the credits wall |
| Roblox Premium perks | Built in | | Cosmetic aura, one extra free spin per day, an exclusive hoverboard skin |
| Private world | Subscription | free | Roblox's own guidance: do not price friends out |

**Not sold, and why**

| Item | Why |
|---|---|
| 2x Scrap income passes, Double Shift | Developers report income passes drive players away; income is the ship bar |
| Scrap for Robux | If Scrap can be bought with Robux it becomes Robux-derived currency, and every Scrap-priced random item (Peddler eggs, Welcome Week egg) becomes a paid random item under Roblox policy. Keeping Scrap earn-only keeps the whole free loop out of that regime |
| Lucky Charms | Personal probability modifier; keep earned |
| Any alien above Epic, any event alien, any mount | Aliens are the game; the top of the codex is earned |
| Gear that cannot be earned, speed above earned speed | Pay-to-explore |
| A second premium currency | Currency opacity is the most-cited child harm and a named target of the EU KIDS Act proposal |
| Pay-to-steal | Named backlash target in Grow a Garden |

### When offers appear

Offers show up at the moment they make sense and never more than once per session each. No pop-up on login. No countdown timers on offers, except event cosmetics, which carry the event's announced end date.

| Moment | Offer |
|---|---|
| First shop open | Starter Pack on Featured |
| All station slots full and an alien is waiting | +1 slot on every station |
| A module has more than 10 minutes left and the player is idle at camp | Module rush, once |
| Perfect catch on a Rare or Epic | "Dress up [name]?" hat shelf for that alien |
| First Hoverboard ride | Skin shelf |
| First launch | Launch Pack, as the home planet unlocks |
| Meteor Shower in under 5 minutes | Server luck, with the shared benefit stated: "everyone on this planet gets it" |
| Codex page hits 100% | Hull skin for that world, half earned (free) and half sold (variants) |

### Rules that keep it safe

- Every random purchase shows per-item odds summing to 100%, every outcome has value, active luck is disclosed live, and `PolicyService.ArePaidRandomItemsRestricted` hides the item and offers a deterministic alternative.
- Every price shows its real-currency equivalent. One currency, Scrap, and it is never sold.
- All under-16 accounts sit in Roblox Kids or Select tiers with parent spend limits as of June 2026; price points should be ones a parent approves without a second thought, which is why the catalog clusters at 49 to 399.
- Cosmetics do not change stats. Overlays (earned) and trails (bought) use visibly different VFX so a bought trail is never mistaken for a Rainbow.
- The US 18+ DevEx rate applies only to experiences rated R15, which this game will not be; plan revenue on the standard rate. Creator Rewards start paying after 100 DAU sustained for 60 days.

### What to expect

Roblox's Q2 2026 letter blamed a bookings shortfall on engagement shifting toward games "with lower hourly monetization" than the 2025 viral hits, especially among younger US and Canadian players. This catalog will not match a paid-egg economy's peak revenue per hour, and that is the trade. What it buys is a game that stays sellable in the UK, Australia, and Brazil today, needs no re-architecture if the EU acts, converts steadily rather than in spikes, and ranks better under an algorithm that now scores retention and monetization together.

---

## 15. Art and audio direction

- **Cute baseline:** round compact body, big eyes, tiny mouth, short limbs, one bold saturated color, drawable by a child. Stylized low-poly, clean shading.
- **The camp is cozy, not industrial.** Stations look like a picnic table, a treehouse workbench, and a glowing flower, not a mine and a forge. Colours stay bright and soft so the game reads as welcoming to girls and boys alike.
- **Same body, escalating overlays:** tier and overlay are scale, material, glow, particles, and attachments on the same mesh family. This is the only way two people ship 15 species x 6 tiers x 4 overlays per world.

| Tier | Silhouette | Material / glow | Extras | Sound | Reveal |
|---|---|---|---|---|---|
| Common | base body, 100% | flat color | none | squeak | card slides in |
| Uncommon | one small prop | two-tone | none | two-note squeak | card with tier color |
| Rare | 110% | metallic trim, localized glow | none | three-note jingle | card + burst |
| Epic | 120%, one silhouette add | full material swap, stronger glow | one particle emitter | voice line | flash, jingle, name text |
| Legendary | 125%, two adds | animated texture, rainbow-cycling glow | halo, ground ring | long voice line | server banner, beacon |
| Cosmic | 150%+, rideable | shifting cosmic material | trail, aura, "????" stats | theme stinger | server banner, camera pull |

- **Legibility rules:** every tier must read in greyscale and at thumbnail size; pair every color cue with a shape or animation cue.
- **Keep one goofy thing at every tier** (the Sugimori rule). The Warden has tree antlers and still has big eyes and a silly idle.
- **Design for the clip:** each alien has one voice line and one looping job-tied idle, and every Legendary reveal is filmable in ten seconds. Roblox's Home page autoplays gameplay video now; make the ten seconds worth autoplaying.
- **Sound ladder:** a per-tier reveal jingle that grows by one note per tier, a distinct catch sound for Perfect, and a bass hit when a ship part snaps on.

---

## 16. UI and UX direction (how the hits do it)

The fastest way for a Roblox game to look amateur or machine-made is a clean, flat, grey interface with a modern web font and no outlines, no sound, and no motion. The hits look the opposite: chunky, saturated, outlined, bouncy, and loud. Pet Simulator 99, Grow a Garden, Steal a Brainrot, and Adopt Me share one visual language, and players read it as "a real Roblox game" before they have touched anything. This section copies that language on purpose.

### HUD layout (landscape, mobile first)

| Zone | What sits there | Reference |
|---|---|---|
| Top center | The **ship bar**: wide pill, dark trough, gradient fill, a small ship icon at the left end, "62%" in white outlined text in the middle, five tick marks for modules. Under it, a thin row of active buff rings and the Luck readout "Luck x1.4" | Steal a Brainrot's top-center timers, every sim's XP bar |
| Top left | **Scrap counter** as a gradient pill: Scrap icon, rolling-digit number, a green round "+" that opens the shop. Beneath it, small "+24/min" | Pet Sim 99 and Grow a Garden currency pills |
| Top right | Weather icon and day/night dial; **Meteor Shower countdown chip**; event banner when one is on. Toasts stack beneath | Grow a Garden weather banner and restock timer |
| Left edge | **Vertical icon stack**, 6 square rounded buttons with labels under them: Shop, Aliens, Codex, Quests, Gifts & Spin, Settings. Red notification dots and diagonal "NEW!" ribbons | Pet Sim 99, Adopt Me, Bubble Gum Simulator Infinity |
| Right edge | Circular **radar minimap** on top; **gear quick-slots** under it (hoverboard toggle, two power-up slots) | Fisch and Pet Catchers minimaps |
| Bottom center | **Companion bar**: three slots showing the following aliens, tap to swap | Pet Sim 99 pet equip bar |
| Bottom right | One big **contextual action button** that changes with context: Catch!, Build, Ride, Collect, Launch. It gently "breathes" when there is something to do | Steal a Brainrot's steal prompt, Adopt Me's task button |
| Bottom left | Star Chart button at camp; Roblox chat bubble stays where the platform puts it | |
| Center | Capture bar, reveal popups, module-complete camera pan. Never more than one modal at a time | |

Each alien in the world carries a floating **nameplate**: name in white outlined text, tier label in its rarity color, job icon, and for station aliens a "+1.2/s" line. Steal a Brainrot's over-head income labels are the model; they make every neighbor's camp readable from a distance.

### Component language

- **Font:** Fredoka One for everything, with Builder Sans only for long body text in settings. Fredoka One is the de facto sim-game font and reads as "Roblox" instantly. Sizes: 14 minimum on mobile, 18 body, 24 labels, 36 titles, 48 reveal text. Every piece of text that sits over the world gets a 2 to 3 px dark UIStroke outline.
- **Buttons:** rounded rectangles (UICorner about 12 px), saturated fill with a vertical gradient lighter at the top, 3 px darker outline, and a 4 to 6 px darker "lip" at the bottom so the button looks like a physical block. White outlined text. Press scales to 0.92 and springs back; hover on PC scales to 1.05. Every press plays a click.
- **Color roles:** one palette of six UI colors and stick to it. Green is buy, confirm, positive. Red is close, alert, notification. Blue is select, info. Gold is featured, premium. Purple is codex and rarity. Cream or pale sky is panel background. Dark navy is outline and trough.
- **Rarity colors:** use the platform conventions players already know, each paired with a shape icon for colorblind readers. Common grey, Uncommon green, Rare blue, Epic purple, Legendary orange-gold, Cosmic animated rainbow, Secret black with a rainbow outline. Do not invent a new scheme; recognition is the point.
- **Panels:** solid light panel, thick colored border, rounded corners, a header tab with the title in white outlined text, a red round X top right, and tabs down the left side with the active tab raised and brighter. No transparency, no blur, no glassmorphism.
- **Item cards:** square, rarity-colored gradient background, the item rendered large, the name underneath, small stat chips, a diagonal "NEW!" ribbon, an "x3" count badge bottom right, and uncaught items as dark silhouettes with a small lock.
- **Progress bars:** pill shaped, dark trough, gradient fill, a highlight sweep across the fill every two seconds, white outlined text centered, tick marks at milestones.
- **Toasts:** top center, slide down with a small bounce, icon on the left, bold short text, gone in 2.5 seconds, at most three stacked. Server announcements are a full-width colored banner with their own sound.
- **Reveal popup:** backdrop dims 60%, the alien scales in with a Back ease, a radial burst spins behind it, the tier name appears in its rarity color, confetti for Epic and above, "Tap anywhere" at the bottom. This exact ritual appears in every egg-hatching game and players expect it.
- **Counters:** digits roll rather than snap, and gains appear as "+25" floating text that flies from the source to the counter.

### Motion and sound rules

- Every window opens by scaling from 0.85 to 1 over 0.25 seconds with a Back ease and closes in 0.15 seconds.
- Buttons wobble slightly when a notification lands on them.
- The action button breathes (scale 1.0 to 1.04) when there is something to do and sits still when there is not.
- Every tap makes a sound: click for buttons, pop for cards, a tick per Scrap milestone, a ding per toast, a rising ladder per rarity on reveal, a bass hit when a ship part snaps on.
- Respect the player's reduced-motion setting by shortening tweens, never by removing feedback.

### Screens and the game each one copies

| Screen | Copies | Notes |
|---|---|---|
| Shop | Pet Sim 99 shop with left tabs and a Featured tab | Section 14 |
| Aliens (camp view) | Pet Sim 99 inventory grid with rarity frames; a station strip at the top showing slots and who is in them; an Optimize button | Drag or tap-to-assign |
| Codex | Pokémon GO Pokédex meets Pet Sim 99 Index: a page per world, silhouettes for uncaught, a completion bar per page, milestone chests on the bar | Section 9 |
| Ship | A side view of the ship with five module cards, each showing its three gates as three small bars (Scrap, Key material, Assembly) | Section 3 |
| Capture bar | A single wide bar in the lower third with the ticker and zones; the alien stays visible above it | Fisch and Pet Catchers minigame framing |
| Quests | A vertical list of three daily, three weekly, and the Field Notes step with a big claim button that turns green when ready | Grow a Garden quest board |
| Gifts & Spin | A 7-tile gift calendar on the left, the spin wheel on the right, free spin count in a pill | Standard sim daily rewards layout |
| Star Chart | A simple orbit map, unlocked worlds lit, the current one pulsing, outposts showing a small output number | Astroneer's planet view simplified |
| Home | Build mode with a bottom catalog strip and a grid snap, like Bloxburg's | Section 10 |
| Launch | A full-screen countdown, camera orbit, the Warden in the cockpit, liftoff, and a "World 2" title card | |

### Mobile rules

Design for landscape phones first and let tablets and PC breathe. Minimum touch target 44 px using Scale sizing and a UIScale that steps by viewport width. Keep the thumb zones (bottom corners and edges) for the things players tap most. Keep text at or above 14 px. Respect safe-area insets. Use UIAspectRatioConstraint on cards so grids stay square. Test on an iPhone SE-sized viewport and an iPad viewport in Studio's device emulator before every release, because the median Roblox session is on a phone.

### What to avoid, because it reads as generic or machine-made

- Roblox default grey buttons and Source Sans text.
- Modern web fonts (Inter, Montserrat, Roboto) and thin weights.
- Dark glassy panels with blur and transparency.
- Flat card grids with no outlines, no gradients, and identical spacing everywhere.
- Emoji or mixed-style icons. Use one icon pack with thick cartoon outlines, bought or commissioned, or none.
- Gradient text, heavy drop shadows, and center-stacked layouts where every element is the same size.
- Silence and stillness. If a tap does nothing visible and audible, it feels broken.
- Invented rarity colors or tier names players have to learn.

### Build notes for the UI

Build the UI in code from one theme module (font, palette, corner radius, stroke widths, tween durations), so a change to the look is a one-file change. The theme module is generated from the UI Playbook in `docs/vault/05-ui-design/`, which holds reference screenshots of the hit games and the look written down to hex codes and proportions, so Claude builds every panel from the same written standard and corrections go back into the playbook (see `docs/PRE_PRODUCTION.md` section 10). Keep every player-facing string in a strings table for Roblox's automatic translation. Build each screen as a component that takes data and renders, so the Shop, Codex, and Aliens screens share one card component and one tab component. Icons are the one UI asset that cannot be generated in code; pick one cartoon icon pack on the Creator Store before the first UI pass and stick to it.

---

## 17. Technical notes (for the build)

- **Places:** one universe; one place per world; one home-planet place; the World 1 place is the start place and "Fully open" so friends land together; private co-op planets are non-start places set to "Secure within universe only."
- **Saves:** one DataStore key per player (`User_{UserId}`), written with `UpdateAsync` and session locking, autosave every 3 minutes, under 100 KB (slot-based camps and homes keep it small; the per-key cap is 4 MB).
- **Aliens:** lightweight server records (position, state, target as attributes on tagged parts), rendered and animated on the client with `AnimationController`, spawned only near players, `StreamingEnabled` on. 80 to 240 creatures per server is normal; server-side Humanoids at that count are not viable.
- **Offline math:** compute accrual and assembly on login from timestamps; never run timers for offline players.
- **Timing minigame:** server-owned parameters and timestamps, client reports tap time, server validates with a latency allowance.
- **Live tuning:** put prices, odds, spawn tables, and timers in Configs so balance changes don't need a restart; use Experiments for A/B tests on the first ten minutes.
- **Analytics from day one:** tutorial step completion, time to first catch, time to first module, catch minigame hit rates per tier, D1/D7/D28, session length, Meteor Shower attendance.

---

## 18. Roadmap for two people

| Phase | Scope | Why |
|---|---|---|
| **P0: Launch (weeks 1 to 6)** | World 1 with three biomes; 12 to 15 species across 4 jobs, Common to Legendary; 5 modules with three gates each; ship bar and assembling 3D ship; timing capture minigame with tiers, lures, hidden kindness; trainee tutorial (first Common takes over a task you just did by hand); Nearby panel, Radar Mk1, shadow silhouettes for uncaught species, Speed Boots, the Luck readout, and three power-ups through the Peddler; 3:00 / 1:30 day-night and 2 to 5 min weather; Meteor Shower on a 2-hour clock; Field Notes chain and the Verdant Warden; codex with first-catch payouts; offline accrual and offline assembly; Welcome Week (days-played) and one free daily spin; the Peddler on a 5-minute clock; event config and HUD banner so events are data from day one; 8-player servers with camp restore; client-rendered aliens; the launch shop: Starter Pack, four passes, hoverboard skin shelf, boost bundles, and gated server luck; analytics | Everything D1 and week one depend on. One place, no cross-server systems |
| **P1: Weeks 7 to 12** | Overlays (Shiny, Gold, Crystal); 4-duplicate fusion; size rolls and growth stages; the compass strip; Warden sightings; home planet (house, habitats, trophy hangar, visiting); Hoverboard with tricks and skins, Glider Pack, Radar Mk2, Epic mounts with the Ride trait, the full power-up set; Outposts and the Star Chart; World 2 Frostbyte with the Heater rule; Party co-op reserved servers; daily and weekly quests; paid spins with full compliance; Alien of the Week and Weekly Weather; developer panel for hosted Shower Storms; first themed seasonal event (Haunted Nebula) | D7 to D28 depth, which Roblox's 2026 discovery algorithm scores on a 28-day window |
| **P2: After traction (100+ DAU sustained)** | World 3 Neon Grid with the Tinker job, Jet Boost, Mag Boots, and Radar Mk3; a steer-the-hook catch variant for the Tidepool world (batch 3 reference); world gear for each later world; decision on a permanent luck pass; secret aliens via Set completion quests; visit-and-borrow, then opt-in raids; gated trading; guilds; monthly seasonal calendar and the first live record attempt; Worlds 4 to 6 one at a time | Each adds moderation or economy burden to carry only once there is an audience |

**Launch targets,** in the terms Creator Hub reports: Day 1 retention above the 90th percentile of our genre benchmark band (12% good, 15% great; 20% is the top-1% stretch), Day 7 above 2% with 4% as the stretch, first-play bounce under 10% within 60 seconds and under 15% within 180 seconds, more than 55% of new players still playing at 5 minutes, median session above 10 minutes, tutorial completion above 60%, Meteor Shower attendance above 30% of online players. If Day 1 sits under the 50th percentile after week one, the problem is the first eight minutes, not the roster. Sound, VFX and a gameplay trailer are launch requirements: creators who reached 1,000 concurrent say they move every stat (`docs/PRE_PRODUCTION.md` section 10.9).

---

## 19. Decisions for the team

1. **Name.** Placeholders to react to: *Starhoppers*, *Catch & Launch*, *Alien Odyssey*, *Little Astronauts*, *Blastoff Buddies*.
2. **Art style.** Smooth low-poly (Adopt Me) or chunkier blocky (Pet Simulator)? Smooth low-poly reads better for cute-to-epic overlays.
3. **Jobs count.** Four at launch is the recommendation. Two would be simpler; six adds micromanagement.
4. **Companions.** Three following aliens with perks, or keep aliens camp-only for simplicity? The recommendation is three, because it gives aliens a role during exploration.
5. **Splicing.** Decided: none. Secrets come from Sets.
6. **Theft.** Decided: borrow only. Raid mode parked for a later look.
7. **World order.** Verdant, Frostbyte, Neon Grid is the proposed first three. Candy or ocean could swap into slot 3 if the team prefers a brighter third world.
8. **Event rerun policy.** Decided: a Vault Rotation in every monthly event plus the annual full reopening. Something is always on: weekly alien, biweekly content drop, monthly seasonal event.
9. **Permanent luck pass.** Launch without it and sell shared server luck only; revisit after the first month of revenue data.
10. **Mounts and companion slots.** Riding uses a companion slot is the recommendation, so riding your best alien is a visible choice rather than a free bonus.
11. **Scrap for Robux.** The recommendation is never, because it would pull every Scrap-priced random item under the paid random items policy. If revenue demands it later, the Peddler eggs and the Welcome Week egg must get odds disclosure and regional gating first.
12. **Pantheon scope.** Greek, Roman, Norse, Egyptian, Mesopotamian, Aztec and Maya, Celtic is the recommended set. Confirm the team is comfortable excluding living religions' figures.

---

## Sources

Every claim about other games, Roblox policy, platform stats, and regulation in this document is sourced in `reports/Roblox alien collection game design.md` and the five note files under `research_notes/`.
