---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Pengoo
name: Pengoo
world: 2
tier: Uncommon
status: review
element: Snow spray
height: 2.75
blocks: 15
tris: 346
bevel_width: 0.1
bevel_segments: 2
palette: ["#2B3F5C", "#F4F7FA", "#FFA63D", "#141B2B"]
roles: [body, second, accent, ink]
hero: Backpack
vfx: "one touch (Uncommon): a spray of snow behind the runners while it belly-slides (Effects.luau, the Flake emitter at Feet) and a glint across the goggles every 5 s; the flippers, held out and up, flap; two moving parts; no glow, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Pengoo_sheet.svg]]"
render: "[[Pengoo_tq_cells.jpg]]"
glb: ""
overlap: [0.993, 0.994, 0.994, 0.993]
cells_render: "[[Pengoo_tq_cells.jpg]]"
---
# Pengoo (Pengoo), Uncommon, World 2 Frostbyte

A round navy penguin with a cream face and belly, orange goggles pushed up on its forehead, a short orange beak between its eyes, two flippers held out and up, and a tiny orange backpack with a cream flap and two straps down its front. It has no feet: it stands on, and belly-slides on, two orange runners. Concept row in `src/shared/data/Species.luau`: "round penguin, tiny backpack, belly-slides everywhere". Element and effect: [[Roster-Redesign]] section 2 (snow spray while it slides; the goggles glint). Rules: [[Blocky-Style]].

**What makes a player want it.** The Uncommon rung exactly: a two-tone body (navy over cream), one secondary block (the backpack) and a second colour in the touch (the orange spray glint), at 2.75 studs to Mitt's 2.5. It is the one that is always going somewhere, sliding on its runners with its pack on.

**Hero block.** The `Backpack`, a small orange pack on its back with a cream flap and two straps round the front, unique in Frostbyte.

**Alien anatomy.** No feet: two runners of its own ice (the orange `Runner` pair) that it stands and slides on; goggles that are part of its head.

**World motif (Frostbyte).** The ice facet as steps: the goggle lenses and the beak are quarter-stud steps proud of the head; the eye patches are navy cells inside the cream face, like a facet cut into a plate.

## Parts

```yaml
parts:
  # the runners it slides on (no feet), the body with its cream belly, the head over it
  - {name: Runner, slot: Accessory, size: [0.5, 0.375, 1.25], at: [0.5, 0.1875, 0.125], mirror: x}
  - {name: Body, slot: Body, size: [1.75, 1, 1.5], at: [0, 0.875, 0.125], bevel: true}
  - {name: Belly, slot: BodyDark, size: [1.25, 0.75, 0.125], at: [0, 0.875, -0.6875]}
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.875, 0], bevel: true}
  # the beak between the eyes, the goggles pushed up on the forehead with two orange lenses
  - {name: Beak, slot: Accessory, size: [0.5, 0.25, 0.375], at: [0, 1.75, -1.0625]}
  - {name: Goggles, slot: BodyDark, size: [1.75, 0.25, 0.25], at: [0, 2.625, -0.5]}
  - {name: Lens, slot: Accessory, size: [0.5, 0.25, 0.125], at: [0.5, 2.625, -0.6875], mirror: x}
  # flippers hanging out at a tilt, each one moving part
  - {name: Flipper, slot: Body, size: [0.25, 1.25, 0.5], at: [1.5625, 1.6875, 0.125], rot: [0, 0, -70], mirror: x, moves: wing, pivot: [1, 1.5, 0.125]}
  # the hero: a tiny backpack with a cream flap and two straps down the front
  - {name: Backpack, slot: Accessory, size: [1, 1, 0.5], at: [0, 1.375, 1.125]}
  - {name: Flap, slot: BodyDark, size: [1, 0.375, 0.125], at: [0, 1.6875, 1.4375]}
  - {name: Strap, slot: BodyDark, size: [0.25, 0.75, 0.125], at: [0.75, 0.875, -0.8125], mirror: x}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. The face is cream (`c`, the second colour) with the eyes in navy patches, the way a penguin's eye sits in its dark hood; the lit crescent is the accent orange (an Uncommon has no glow).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF8FA3"
    "c": second
  rows:
    - "................"
    - ".cccccccccccccc."
    - ".c.kk.cccc.kk.c."
    - ".ckwkkcccckkwkc."
    - ".ckwkkcccckkwkc."
    - ".ckkkkcccckkkkc."
    - ".ckgwkcccckwgkc."
    - ".c.gg.kcck.gg.c."
    - ".cppccckkcccppc."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Pengoo.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Pengoo.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Pengoo_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Pengoo_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: skin everywhere (the navy carries the jitter and the grout; the cream face cells are drawn exactly, never jittered).

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: with the cream drawn right round the eyes the house eye's corner cells broke the stamp, so each eye sits in a navy patch the exact size of the stamp, which reads as the penguin's dark hood. Round 2: the beak dropped from the forehead to between the eyes so the smile stays under it; a tail was cut to keep 15 blocks. Round 3 (the silhouette test): as a plain block with its flippers close it overlapped Sabrek, Skadra and Fenrir at 0.73 to 0.78 in the boxed 64 px test, so the flippers went out and up (20 degrees off horizontal, a quarter stud longer): a penguin with its arms up, which leaves the box's corners empty and drops every pair under 0.7. Overlap 0.993 to 0.994, 346 triangles, 15 blocks, 2.75 studs, two moving objects (the flippers). Wanted for: a two-tone penguin always sliding somewhere with its pack on. Still cheap: the runners read as feet from the front; the glint is only in the effects. Status review.
