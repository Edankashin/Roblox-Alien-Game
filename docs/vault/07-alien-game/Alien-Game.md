---
tags: [alien-game, hub]
up: "[[Start-Here]]"
---
# Alien game

Notes that belong to this project alone: what was decided and what was asked. Back to [[Start-Here]].

- [[Decisions]]: every product and build decision with its date, so no session re-asks. Read it before changing a rule; rows B21 to B26 are the decisions of 2026-10-14 ([[Launch-Dashboard]] lists them).
- [[Requests]]: Ethan's asks in order and where each landed. Read it to see whether something was already asked for.

## Creatures

One spec note per creature in `Creatures/`, the single source of truth for its concept sheet and its Blender build ([[Blocky-Style]] has the format and the rules). The roster view is the Bases file [[Creatures.base]] (cards by tier, a kanban by status, a budgets table).

- [[Mossbop]]: Moop, Common, World 1: a voxel moss ball on three root feet with a two-leaf sprout and a floating spore. Prototype, in review.
- [[Buzzlebee]]: Buzzik, Uncommon, World 1: a four-winged bee with a striped abdomen and a tiny pink backpack. Prototype, in review.
- [[Sparkfox]]: Vixa, Rare, World 1: a fox whose tail is a paintbrush dipped in glowing paint, a gold flame stamped on each flank. Prototype, in review.
- [[Thunderhog]]: Voltus, Epic, World 1: a six-legged storm hedgehog with lightning-rod antennae under a lit lightning crest. Prototype, in review.
- [[Gaiabloom]]: Gaira, Legendary, World 1: an ivory stag with blossoming tree antlers, a gold nimbus and lit dapples. Prototype, in review.
- [[Radish]]: Raddis, Cosmic, World 1: a hovering giant radish with a pharaoh's brow behind a turning winged sun disk, ridable. Prototype, in review.
- [[Panpipe]]: Syrinx, Secret, World 1: a great shadow goat with four horns and an organ of reed pipes on its back, ridable. Prototype, in review.

World 2 Frostbyte's six, one per rung to Cosmic, built by the same rules in the cold cell materials ([[Blocky-Style]] "World 2: Frostbyte palette"; the review sheet `media/studio/2026-10-19/world2_ladder_v1.jpg`):

- [[Flufflet]]: Mitt, Common, World 2: a snowball in a knitted scarf with mittens for ears, rolling on a smaller snowball. Prototype, in review.
- [[Pengoo]]: Pengoo, Uncommon, World 2: a round penguin with its flippers up, goggles on its forehead and a tiny backpack, sliding on two runners. Prototype, in review.
- [[Reindazzle]]: Blinkar, Rare, World 2: a reindeer with antlers of ice hung with icicles and a nose that is a red lantern. Prototype, in review.
- [[Frostfang]]: Sabrek, Epic, World 2: a sabre-tooth cub with lit icicle fangs, a ruff of ice quills and a frost flake on each flank. Prototype, in review.
- [[Skaddle]]: Skadra, Legendary, World 2: a player-sized snow owl on tiny skis under a crest of lit ice crystals, four wings, a quiver on its back. Prototype, in review.
- [[Fenripup]]: Fenrir, Cosmic, World 2: a 14-stud moon wolf with a glowing moon on its brow, a mane of layered blocks and a broken chain, ridable; two face options on the sheet. Prototype, in review.

## Props

One spec note per prop in `Props/`, the same parts table as a creature (`kind: prop`), built through the same route at the world cell ([[Blocky-Style]] "Environment"). World 1 Verdant's set, all in the meadow diorama:

- [[GrassBlock]]: the ground's four kinds, 2 x 1 x 2 stud blocks: grass over dirt, a cobbled path, the pond's water.
- [[Tree]]: a bark trunk under a crown of moss-cell leaf clumps with pink blossoms.
- [[Rock]]: a two-step boulder in stone cobbles with a moss patch.
- [[Crystal]]: a glowing crystal spire with leaning shards on a stone seat.
- [[Ship]]: the players' crashed ship, riveted metal, a crystal canopy, one wing snapped.
- [[Flower]]: a stud-high flower in three petal colours.

World 2 Frostbyte's set, all in the snowfield diorama (`tools/blender/blocky_scene.py --world 2`):

- [[SnowBlock]]: the ground's kinds, 2 x 1 x 2 stud blocks: snow over packed snow, an ice floor, the frozen pond, the cliff.
- [[PineTree]]: a snow pine, three tiers of needle rows with a snow cap on each.
- [[SnowRock]]: a two-step boulder in stone cobbles under a snow cap and a drift.
- [[IceCrystal]]: a glowing ice spire with leaning shards on a snow-dusted rock seat.
- [[IceArch]]: the Ice Cave's mouth, two ice pillars under a stepped lintel with icicles, the cave's dark behind.
- [[Heater]]: the camp's heater, a steel drum with a lit grate, the world's one warm light.

## Plan documents outside the vault

These live in `docs/`, where Obsidian cannot open them, so each has a short pointer note that keeps the links working:

- [[STORE-PAGE]]: the store page draft, the launch morning checklist and the dashboard run sheet.
- [[TESTING]]: the Studio test script per milestone.
- [[STUDIO-QUEUE]]: the generated run queue of the pending Studio checks.
