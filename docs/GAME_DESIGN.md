# Game Design Document (working title TBD)

**Pitch:** You crash-land on a strange planet. Cute aliens are everywhere. Catch them, and they build you a ship. Fill the ship bar, launch, and do it again on a frost world, a cyber world, a lava world. Every planet you leave keeps working for you, and every alien you catch goes in your codex forever.

**Status:** Vision plan v1, written against the research in `reports/Roblox alien collection game design.md`. All numbers in this document are starting values to tune in playtests, not tested thresholds.

---

## 1. Design pillars

1. **One bar.** The ship progress bar is the heartbeat of the game. Everything the player does moves it, and the player can always see it move.
2. **Aliens everywhere, secrets hidden.** Like Pokémon GO: the world is never empty, commons are a tap away, and rares live behind biome, time, weather, and skill.
3. **Playable with one thumb while eating.** No fail state that loses progress. No upkeep. Auto-assign by default. Idle income and assembly continue offline. Every tap does something.
4. **Dopamine at every step.** Every action has a feedback beat within two seconds, every session has a reward beat in the first ten seconds, and every world ends in a climax.
5. **Nothing you did is wasted.** Old worlds become outposts, old aliens become splicing parents, the codex never resets.

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
4. The home planet grows (house, habitats, trophy ship, splicing lab).
5. Codex pages fill; secrets unlock through quests and splicing.

### Dopamine map

| Cadence | Beat | Feedback |
|---|---|---|
| Every 1 to 5 s | Scrap ticks, aliens work | Floating numbers, work-loop animations, soft chime on round numbers |
| Every 30 to 90 s | A catch | Timing-bar hit sound, catch burst, rarity-colored card, codex "NEW" stamp |
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

The last module of every world needs that world's Core, and the Core comes from catching the world's Warden. The Warden is a Legendary with a unique three-round timing capture (see section 6). The Field Notes quest chain (section 8) leads to a guaranteed Warden encounter, so the challenge is skill and persistence, never luck. If the player fails the capture, the Warden retreats and returns at the next Meteor Shower or after a 15-minute cooldown; nothing is lost. When caught, the Warden becomes the ship's pilot, visible in the cockpit, and its silhouette appears on the launch cinematic. It is the cute-to-epic payoff of the whole world.

World pacing target: World 1 takes 2 to 3 hours of play across 2 to 3 days. World 2 about 4 to 5 days. World 3 about a week. The offline systems make every return feel like progress even when the player only has five minutes.

---

## 4. The aliens

### Two roles per alien

Every alien is a **worker** and a **companion**.

- **Worker:** has one or two jobs at a level. At a station it produces Scrap; in a module slot it assembles. Four jobs at launch: Mine, Haul, Weld, Wire. Auto-assign puts every new catch in its best open slot. A single "Optimize" button re-sorts the camp. Manual placement exists for players who want it.
- **Companion:** up to three aliens follow the player (Pet Simulator pattern) and each gives one small perk while following: slower timing ticker, wider zone, longer scanner range, more Scrap from catches, higher Shiny chance. Companions are how aliens matter during exploration, not only at camp.

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

- **Slots:** each station starts with one slot and grows to three. Three Common welders beat an empty slot. A full slot always beats an empty one.
- **Fusion:** four duplicates of a species fuse into +1 level on one copy (max +2). Surplus always has a destination.
- **Codex payout:** the first catch of any species pays Scrap and a decoration. A late Common is worthless as a unit but valuable as an entry.
- **Haul is commons-only:** one job is held only by Common and Uncommon species, so the camp cannot run without them.
- **Splicing parents:** secrets require specific commons from specific worlds (section 8).

### How value is shown

Four channels at once: the module timer visibly shrinks when a better alien is dropped in; the Scrap/min readout rises; the alien card shows job badges and level pips; the body shows tier and overlay from across the camp. Cosmic stats display as "????" and Cosmics are rideable.

### World 1 example roster (15 species, placeholders)

Naming rule: each alien is an alien-plus-object or alien-plus-tool hybrid describable in three words, with a rhythmic or reduplicated name, one voice line, and one job-tied idle animation.

| Name | Concept (3 words) | Tier | Job | Where / when |
|---|---|---|---|---|
| Mossbop | moss ball, eyes | Common | Haul | Meadow, any |
| Pebblet | pebble with legs | Common | Mine | Cave mouth, any |
| Glimmo | jelly firefly | Common | Wire | Forest, any |
| Twiglet | stick bug, leaf hat | Common | Haul | Forest, any |
| Puffpuff | dandelion puff, face | Common | Weld | Meadow, any |
| Snailbyte | snail, metal shell | Uncommon | Mine | Cave, any |
| Buzzlebee | bee, tiny backpack | Uncommon | Haul | Meadow, day |
| Lanternewt | newt, glowing tail | Uncommon | Wire | Forest, night |
| Rocklobber | crab, boulder claws | Rare | Mine L3 | Cave, any |
| Zapfinch | bird, antenna crest | Rare | Wire L3 | Forest, any |
| Sparkfox | fox, welding-torch tail | Rare | Weld L3 | Meadow, any |
| Thunderhog | hedgehog, lightning quills | Epic | Wire/Weld | Meadow, Rain only |
| Gloomoth | moth, crystal wings | Epic | Mine/Wire | Cave, night only |
| Verdant Warden | stag, tree antlers, moss cape | Legendary | all | Field Notes finale |
| ??? (splice secret) | hint: "a child of moss and lightning" | Secret | all | Splicing lab |

---

## 5. Exploration (the Pokémon GO model)

- **Density:** 12 to 20 wild aliens are visible around the player at all times. Commons respawn 60 to 90 seconds after a catch. The world is never empty.
- **Nearby panel:** a small panel lists the species present in this biome right now as silhouettes. Caught species show in color, uncaught as dark silhouettes, secrets as "???". Tapping one shows a compass direction, not a pin. The chase is the content.
- **Gating ladder:** rarity is gated by *where* (biome), *when* (day/night, weather), and *how* (lure tier, companion perks). Day/night cycle is 3 minutes day and 90 seconds night (a 15-minute session gets three nights). Weather rolls randomly for 2 to 5 minutes: Rain, Fog, Clear, and later world-specific states.
- **Hidden places:** rares spawn in nested spots: cave depths, treetops, behind a waterfall, under ice. Finding the spot is a one-time discovery that the codex remembers.
- **Secret cues:** a secret alien in the area plays a unique chirp and shows a glint on the horizon. The Nearby panel shows "???". Nothing else is told.
- **Scanner:** a Scrap-upgradable radar that pings rares within range and shows the next Meteor Shower countdown.
- **Meteor Shower:** every 2 hours on a fixed server clock, a 3-minute window. Server-wide banner, sky turns, beacons mark spawns, Epic+ rates rise, Cosmics can appear. It is the only place Cosmics spawn, which turns the rarest find into a shared appointment rather than a private slot machine.
- **Server announcements:** Legendary and Cosmic spawns announce to the whole server with location, the pattern Steal a Brainrot and Steal an Egg use. Seeing someone else's catch is content.

---

## 6. The capture minigame

The team's instinct is right: a timing bar is the single best fit for one-thumb play and it adds skill expression without stress.

### Spec

1. Walk within 8 studs and tap the alien (or its "!" bubble). The camera zooms, the world dims.
2. A horizontal bar appears with a ticker sweeping left to right and back.
3. Zones: outer grey (Miss), green (Good), gold center (Perfect). Tap, click, or space to stop the ticker.
4. **Perfect:** guaranteed catch, bonus Scrap, "PERFECT" stamp, a slightly louder reveal.
5. **Good:** catch roll by tier (Common 100%, Uncommon 90%, Rare 75%, Epic 60%, Legendary 50%). On a failed roll the alien wiggles free and the ticker sweeps again. Up to 3 sweeps per encounter.
6. **Miss:** costs one sweep. After 3 failed sweeps the alien flees. Commons reappear nearby in 60 seconds. Rares vanish until their condition next returns, but the scanner marks the spot.

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

## 7. Worlds

Each world is a separate Roblox place in one universe, handcrafted, with three biomes, 12 to 15 species, one Warden, one or two secrets, and one new rule. Themes change the constraint, not just the skin.

| # | World (placeholder) | Biomes | New rule | Key materials | Notes |
|---|---|---|---|---|---|
| 1 | Verdant Crash Site | Meadow, Forest, Cave | Day/night, Rain | Glowroot, Cave Crystal, Storm Shard, Warden's Core | Gentle tutorial world |
| 2 | Frostbyte | Snowfield, Ice Cave, Geyser Field | Blizzards hide aliens; place a Heater (Scrap) to reveal them for 60 s | Frost Core, Geyser Pearl | Introduces placing a tool in the world |
| 3 | Neon Grid | Rooftops, Server Farm, Undercity | Day is dim; night is neon and busy; Power Surges (weather) spawn Epics; new job: Code | Data Shard, Surge Cell | Adds the 5th job and a 5th station |
| 4 | Emberfall | Lava Fields, Obsidian Caves, Ash Forest | Heat meter: stay near Cooling Vents or return to camp; eruptions are the weather event | Magma Core, Obsidian Lens | First world with a light pressure mechanic |
| 5 | Tidepool | Reef, Kelp Forest, Trench | Swimming and diving; tides as the weather cycle | Pearl Core, Abyss Glass | |
| 6 | Dreamdrift | Candy Cliffs, Cloud Sea, Music Box Hollow | Gravity flips as the weather event | Dream Core | |
| 7 | The Void Hub | Endgame | All Wardens needed to open the gate | | Long-term goal |

What carries forward: the ship, the roster, the codex, Scrap, the home planet. What stays behind becomes an Outpost.

### Outposts: every planet stays relevant

When the player launches, the camp converts into an **Outpost**. Outposts:

- keep producing that world's key materials slowly and a trickle of Scrap, offline too;
- can be upgraded with Scrap for higher output;
- are needed because later ships require earlier worlds' materials (World 3's Nav Array needs Frost Cores from World 2 and Glowroot from World 1);
- host a rotating **daily world quest** ("catch a night alien on Frostbyte") that pays Scrap and spins;
- are where world-exclusive aliens live, which later splicing recipes need.

A **Star Chart** on the ship lets the player fly back to any unlocked world instantly. Returning to World 1 as a veteran with Epics and a wide-zone lure should feel like a victory lap, and the codex should still have something there to find.

---

## 8. Codex, quests, and splicing (the Dragon City model)

### Codex

One page per world. Each species has an entry with a silhouette until caught, then the model, its voice line, its jobs, where it was found, how many caught, and the best overlay owned. First catch pays Scrap and a camp decoration. Page completion milestones (50%, 100%) pay cosmetics, spins, and the title for that world. The codex also tracks discovered hidden spots and discovered splicing recipes. Completion percent is shown everywhere a bar can fit.

### Field Notes (per-world quest chain)

Five steps, modeled on Pokémon GO's Special Research: never expires, one step at a time, each step pays something.

Example for World 1:

1. Catch 5 aliens. Reward: Tier 1 lure.
2. Catch a night alien and find the Cave's hidden pool. Reward: 500 Scrap.
3. Craft a Tier 2 lure and catch a Rare. Reward: a spin.
4. Catch an Epic during Rain. Reward: the Warden's call (a horn item).
5. Sound the horn at the Great Tree at night. Reward: guaranteed Verdant Warden encounter.

Later worlds add a twist to step 5 (sound the horn during a Blizzard, during a Power Surge).

### Splicing (secret aliens from the right combination)

The Splicing Lab on the home planet takes two parent aliens and a Scrap fee and, after a timer (4 hours, Dragon City's breeding cadence), produces a new alien. Parents are **not consumed**; players should never lose a creature they love.

- Recipes are deterministic (same parents always give the same child), but hidden. The codex drops hints ("a child of frost and circuitry"). Discovery is the puzzle; the overlay roll on the child is the dice.
- Secrets need parents from different worlds (a World 2 Frostbyte alien plus a World 3 Neon Grid alien), which sends players back to old worlds.
- Some secrets need a chain: splice A and B, then splice the result with C.
- Rushing the timer is a deterministic Robux purchase (allowed; no randomness), but the free timer must feel fine on its own.

Secrets are the top of the codex, the long-term goal for collectors, and never sold.

---

## 9. The home planet

Unlocks on the first launch, as the reward for finishing World 1. It is the player's persistent showcase and the place friends visit.

- **House (Bloxburg-lite):** modular prefab rooms and furniture on a grid, paid in Scrap. Plot size and furniture caps are the monetized capacity. No free-form building (data size and scope).
- **Habitats:** themed enclosures per world (a frost habitat, a neon habitat). Displayed aliens roam and produce a little Scrap passively (Dragon City habitats). Habitat count is a capacity upgrade.
- **Trophy Hangar:** a scaled model of every ship the player has launched, with the Warden pilot in each cockpit.
- **Splicing Lab, Spin Wheel kiosk, Mailbox** (gifts from friends and events), **Visitor Book.**
- **Visiting:** friends can visit when the owner is online or offline (loaded from the owner's save). Lock levels: owner only, friends, anyone. Visitors can "Wave" at displayed aliens for a tiny bonus to both players.

Keep Scrap as the only spendable currency. Home decor is priced below ship parts so building a house never blocks a launch.

---

## 10. Retention systems

- **Offline accrual:** Scrap accrues at 50% rate while away, capped at about 60 minutes of income; module assembly continues at full speed. The return is always a chest and often a snapped-on part.
- **Welcome Week:** seven gifts that unlock by *days played*, not consecutive days. Missing a day loses nothing. Day 7 is an Epic alien egg hatched in the free loop with odds shown. (Login *streaks* are a named target in the EU's September 2026 KIDS Act proposal, so the track is built as "seven gifts" rather than "seven days in a row" from the start.)
- **Daily quests (3) and weekly quests (3):** Scrap, lures, spins.
- **Spin Wheel:** one free spin per day plus spins earned from quests and codex milestones. Every segment has value (Scrap, lures, a temporary Shiny charm, a cosmetic, a rare companion-slot token). No "nothing" segment.
- **Limited-time events** at four cadences, from the 5-minute Peddler to monthly seasonal events. See section 11.

### Paid spins: how to do them within the rules

Roblox's paid random items policy applies to anything random bought with Robux or Robux-derived currency. Paid spins are allowed if, and only if:

- every segment's odds are shown numerically before purchase and sum to 100%;
- every outcome gives real value (no dud segment);
- any active luck boost is disclosed numerically and the displayed odds update live;
- the purchase is hidden for players where `PolicyService.ArePaidRandomItemsRestricted` is true (UK under 18, all of Australia, Brazilian minors today) and a deterministic alternative is offered instead;
- paid spins never contain exclusive aliens. Cosmetics, Scrap, lures, and boosts only. Aliens are earned.

Build the wheel so that the paid path can be switched off per region without touching the free path. If the EU proposal passes, the game keeps working.

---

## 11. Limited-time events

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
| Anniversary | Vault Reopening | none | Every Vaulted alien returns for one week | The kindness rerun (see below) |

Each world launch (section 7) is also treated as an event: a "First Landing" week with double key material drops and a launch-week limited alien.

### Event mechanics the whole system reuses

- **Event quest track:** a free milestone track (catch 20 event aliens, catch one with the event overlay, finish three Showers) that pays Scrap, lures, spins, decor, and finally the event's rarest alien. No second currency. Everything is earnable in roughly 2 to 3 hours of total play across the two weeks.
- **Event overlays:** multiplicative like permanent overlays, tier-sized (2x) because they are scarce, and they stop rolling when the event ends. An alien caught with a Spectral overlay in October is permanently proof of October.
- **Vaulting:** when an event or weekly alien leaves, its codex entry gets a "Vaulted" stamp and the silhouette stays visible to everyone. Vaulted aliens never get stronger than current ones; their value is prestige, not power, so missing one does not cost progress.
- **Server-wide luck, gifted:** developers can grant every server a free luck window during hosted events. It is the same mechanic sold in section 13, which makes the hosted hour feel generous.
- **Global counter:** a universe-wide tally (MemoryStore plus a DataStore checkpoint) drives community goals and unlocks a shared reward when the number is hit. Pokémon GO's Global Challenges and Grow a Garden's record attempts both run on this.
- **Event banner:** a persistent HUD banner with the event name, the end date, and the next hosted window, in the same slot the Shower countdown uses. Players always know what is on and when it ends.

### Rules for a young audience

- **Announce the end date on day one** and never run a "last chance" countdown louder than the normal banner. The EU KIDS Act proposal names pressure loops and login streaks; a visible calendar is not a pressure loop, a flashing countdown is.
- **Nothing event-exclusive is ever sold.** Event aliens come from the quest track and spawns. Event cosmetics may be sold. Event overlays roll only on free catches.
- **Prestige over power.** Event aliens and overlays are never required for a module, a splice, or a Warden. Players who skip an event lose nothing on the ship bar.
- **Reruns are kind.** Vaulted aliens return once a year at the anniversary. Adopt Me's permanent retirement creates trading value, but this game has no trading at launch, so permanent retirement would only create regret.
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

## 12. Multiplayer

- **World servers:** MaxPlayers 8, PreferredPlayers 6, eight fixed camp slots, one or two social slots reserved for friends. Camps restore from the player's save on join.
- **Co-op:** platform Party (up to 6) plus the Party API and reserved servers for a private world instance. Progress stays per player; only the instance is shared.
- **Home planet visiting:** friends load the owner's home from the save, online or offline.
- **No trading at launch.** Add a gated system later (license quiz, 30-day log, two-step confirm, item caps).
- **Visit and borrow instead of steal:** a friend lends an alien to your module slot for a timed window, keeps ownership, both get a bonus. An opt-in raid mode can come later behind Steal a Brainrot's guardrails. Given the 2025 to 2026 lawsuits around Roblox and kids, theft is not the launch hook.
- **Design for no chat.** Roblox segments chat by age group since January 2026. Waves, emotes, gifts, visible camps, and server announcements carry the social load.

---

## 13. Monetization

Rule: keep randomness in the free loop; sell certainty, capacity, convenience, and cosmetics.

| SKU | Type | Price (R$) | Notes |
|---|---|---|---|
| Direct-buy Rare or Epic alien | Dev Product | 99 to 199 | Never Legendary or above |
| +1 station slot, slot bundles | Pass | 149 to 799 | Capacity, not power |
| Auto-collect / auto-optimize | Pass | 199 to 299 | Convenience |
| Home plot expansion, habitat slots | Pass | 199 to 499 | Capacity |
| Hull skins, alien hats and trails, decor | Cosmetics | 49 to 299 | |
| Splice rush, module rush | Dev Product | 29 to 99 | Deterministic timer skip |
| Server-wide luck, 15 min | Consumable | 249 / 999 | Probability modifier: full disclosure, PolicyService gated |
| Paid spins | Consumable | 49 to 199 | Section 10 rules |
| Private world | Subscription | free or minimal | Don't price friends out |
| **Not sold** | | | 2x Scrap income, pay-to-steal, Robux-only aliens, exclusive aliens in spins |

Show the real-currency equivalent next to every Robux price, never add a second premium currency, and turn on regional pricing from day one.

---

## 14. Art and audio direction

- **Cute baseline:** round compact body, big eyes, tiny mouth, short limbs, one bold saturated color, drawable by a child. Stylized low-poly, clean shading.
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

## 15. Technical notes (for the build)

- **Places:** one universe; one place per world; one home-planet place; the World 1 place is the start place and "Fully open" so friends land together; private co-op planets are non-start places set to "Secure within universe only."
- **Saves:** one DataStore key per player (`User_{UserId}`), written with `UpdateAsync` and session locking, autosave every 3 minutes, under 100 KB (slot-based camps and homes keep it small; the per-key cap is 4 MB).
- **Aliens:** lightweight server records (position, state, target as attributes on tagged parts), rendered and animated on the client with `AnimationController`, spawned only near players, `StreamingEnabled` on. 80 to 240 creatures per server is normal; server-side Humanoids at that count are not viable.
- **Offline math:** compute accrual and assembly on login from timestamps; never run timers for offline players.
- **Timing minigame:** server-owned parameters and timestamps, client reports tap time, server validates with a latency allowance.
- **Live tuning:** put prices, odds, spawn tables, and timers in Configs so balance changes don't need a restart; use Experiments for A/B tests on the first ten minutes.
- **Analytics from day one:** tutorial step completion, time to first catch, time to first module, catch minigame hit rates per tier, D1/D7/D28, session length, Meteor Shower attendance.

---

## 16. Roadmap for two people

| Phase | Scope | Why |
|---|---|---|
| **P0: Launch (weeks 1 to 6)** | World 1 with three biomes; 12 to 15 species across 4 jobs, Common to Legendary; 5 modules with three gates each; ship bar and assembling 3D ship; timing capture minigame with tiers, lures, hidden kindness; trainee tutorial (first Common takes over a task you just did by hand); Nearby panel and scanner; 3:00 / 1:30 day-night and 2 to 5 min weather; Meteor Shower on a 2-hour clock; Field Notes chain and the Verdant Warden; codex with first-catch payouts; offline accrual and offline assembly; Welcome Week (days-played) and one free daily spin; the Peddler on a 5-minute clock; event config and HUD banner so events are data from day one; 8-player servers with camp restore; client-rendered aliens; 3 to 4 passes plus gated server luck; analytics | Everything D1 and week one depend on. One place, no cross-server systems |
| **P1: Weeks 7 to 12** | Overlays (Shiny, Gold, Crystal); 4-duplicate fusion; home planet (house, habitats, trophy hangar, splicing lab, visiting); Outposts and the Star Chart; World 2 Frostbyte with the Heater rule; Party co-op reserved servers; daily and weekly quests; paid spins with full compliance; Alien of the Week and Weekly Weather; developer panel for hosted Shower Storms; first themed seasonal event (Haunted Nebula) | D7 to D28 depth, which Roblox's 2026 discovery algorithm scores on a 28-day window |
| **P2: After traction (100+ DAU sustained)** | World 3 Neon Grid with the Code job; secret aliens via splicing chains; visit-and-borrow, then opt-in raids; gated trading; guilds; monthly seasonal calendar and the first live record attempt; Worlds 4 to 6 one at a time | Each adds moderation or economy burden to carry only once there is an audience |

**Launch targets:** D1 above 20%, D7 above 8% (the top-1% band on Roblox), median session above 10 minutes, tutorial completion above 60%, Meteor Shower attendance above 30% of online players. If D1 is under 15% after week one, the problem is the first eight minutes, not the roster.

---

## 17. Decisions for the team

1. **Name.** Placeholders to react to: *Starhoppers*, *Catch & Launch*, *Alien Odyssey*, *Little Astronauts*, *Blastoff Buddies*.
2. **Art style.** Smooth low-poly (Adopt Me) or chunkier blocky (Pet Simulator)? Smooth low-poly reads better for cute-to-epic overlays.
3. **Jobs count.** Four at launch is the recommendation. Two would be simpler; six adds micromanagement.
4. **Companions.** Three following aliens with perks, or keep aliens camp-only for simplicity? The recommendation is three, because it gives aliens a role during exploration.
5. **Splicing parents.** Not consumed is the recommendation. Consuming parents is a bigger Scrap sink but risks grief.
6. **Theft.** Borrow-only at launch is the recommendation. Opt-in raids later.
7. **World order.** Verdant, Frostbyte, Neon Grid is the proposed first three. Candy or ocean could swap into slot 3 if the team prefers a brighter third world.
8. **Event rerun policy.** Annual Vault Reopening is the recommendation. Permanent retirement (Adopt Me) only makes sense once trading exists.

---

## Sources

Every claim about other games, Roblox policy, platform stats, and regulation in this document is sourced in `reports/Roblox alien collection game design.md` and the five note files under `research_notes/`.
