---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Pengoo
name: Pengoo
world: 2
tier: Uncommon
status: review
element: Snow spray
height: 3
blocks: 20
tris: 400
bevel_width: 0.1
bevel_segments: 2
palette: ["#2B3F5C", "#F4F7FA", "#FFA63D", "#141B2B"]
roles: [body, second, accent, ink]
hero: Backpack
vfx: "Uncommon, two layers (Effects.luau): an Emitter sprays pixel snowflakes (EAF6FF) back from the Feet at 3 a second, and a Sparkle in ice blue (9FE3FF) glints at the Eyes every 5 s, the second colour; the idle bobs 0.1 studs every 1.1 s; no light; the flippers flap, the tuft sways, the pack bounces and it waddles in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Pengoo_sheet.svg]]"
render: "[[Pengoo_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.998, 0.995, 0.996]
cells_render: "[[Pengoo_tq_cells.jpg]]"
idle_render: "[[Pengoo_idle.png]]"
---
# Pengoo (Pengoo), Uncommon, World 2 Frostbyte

A round navy penguin with a cream face and belly under a navy hood with a feather tuft, orange goggles on an ink strap pushed up against its crown, a short orange beak between its eyes, two flippers held out and up, and a tiny orange backpack with a cream flap and two straps down its front. It has no feet: it stands on, and belly-slides on, two orange runners. Concept row in `src/shared/data/Species.luau`: "round penguin, tiny backpack, belly-slides everywhere". Element and effect: [[Roster-Redesign]] section 2 (snow spray while it slides; the goggles glint). Rules: [[Blocky-Style]].

**What makes a player want it.** The Uncommon rung exactly: a two-tone body (navy over cream), one secondary block (the backpack) and a second colour in the touch (the orange spray glint), at 2.75 studs to Mitt's 2.5. It is the one that is always going somewhere, sliding on its runners with its pack on.

**Hero block.** The `Backpack`, a small orange pack on its back with a cream flap and two straps round the front, unique in Frostbyte.

**Alien anatomy.** No feet: two runners of its own ice (the orange `Runner` pair) that it stands and slides on; goggles that are part of its head.

**World motif (Frostbyte).** The ice facet as steps: the goggle lenses and the beak are quarter-stud steps proud of the head; the navy hood steps round the cream face (crown step, nape, two sides), like a facet cut round a plate.

## Parts

```yaml
parts:
  # the runners it slides on (no feet), the navy body with its cream belly
  - {name: Runner, slot: Accessory, size: [0.5, 0.375, 1.25], at: [0.5, 0.1875, 0.125], mirror: x}
  - {name: Body, slot: Body, size: [1.75, 1, 1.5], at: [0, 0.875, 0.125], bevel: true}
  - {name: Belly, slot: BodyDark, size: [1.25, 0.75, 0.125], at: [0, 0.875, -0.6875]}
  # the head is the cream face (B46: the face plate sits on cream); a navy crown step, a nape, two hood sides over the back of the cheeks and a feather tuft make the hood
  - {name: Head, slot: BodyDark, size: [2, 1.25, 1.75], at: [0, 1.875, 0], bevel: true}
  - {name: Crown, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 2.625, 0.25]}
  - {name: Nape, slot: Body, size: [2, 0.625, 0.125], at: [0, 2.1875, 0.9375]}
  - {name: Hood, slot: Body, size: [0.125, 1, 1.25], at: [1.0625, 2, 0.25], mirror: x}
  - {name: Tuft, slot: Body, size: [0.25, 0.25, 0.25], at: [0, 2.875, 0.25], moves: tuft, pivot: [0, 2.75, 0.25]}
  # the beak between the eyes (it is the mouth), the goggles pushed up against the crown: an ink strap and two orange lenses
  - {name: Beak, slot: Accessory, size: [0.5, 0.25, 0.375], at: [0, 1.75, -1.0625]}
  - {name: Goggles, slot: Eye, size: [1.75, 0.25, 0.25], at: [0, 2.625, -0.5]}
  - {name: Lens, slot: Accessory, size: [0.5, 0.25, 0.125], at: [0.5, 2.625, -0.6875], mirror: x}
  # flippers held out at a tilt, each one moving part
  - {name: Flipper, slot: Body, size: [0.25, 1.25, 0.5], at: [1.5625, 1.6875, 0.125], rot: [0, 0, -70], mirror: x, moves: wing, pivot: [1, 1.5, 0.125]}
  # the hero: a tiny backpack with a cream flap that bounces, and two straps down the front
  - {name: Backpack, slot: Accessory, size: [1, 1, 0.5], at: [0, 1.375, 1.125], moves: pack, pivot: [0, 0.875, 1.125]}
  - {name: Flap, slot: BodyDark, size: [1, 0.375, 0.125], at: [0, 1.6875, 1.4375], moves: pack, pivot: [0, 0.875, 1.125]}
  - {name: Strap, slot: BodyDark, size: [0.25, 0.75, 0.125], at: [0.75, 0.875, -0.8125], mirror: x}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell). On the B46 format the head itself is the cream face (the old navy patches round the eyes were drawn in the face grid, which the plate retires), and the navy hood is five blocks round it: the crown step, the nape, the two hood sides (over the back three quarters of each side, so the front corners stay cream) and the tuft. The eyes and cheeks are on the face plate; the beak is the mouth.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `twotone`, an Uncommon design, a round iris dark over light with a big pupil and two shines, here navy over an icy blue (a penguin's cold, clear eye), at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, three frames). No drawn mouth (the orange beak between the eyes carries it, as Zirrit's does) and blush cheeks. The only `twotone` in Frostbyte's lower rungs.

```yaml
eyes:
  key: twotone
  colours: {iris2: body, iris: "#4FA3E0"}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.9375]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the flippers flap, the feather tuft on its crown sways, the backpack bounces on its back, the whole penguin waddles side to side on its runners and the face blinks. Five moving things (four objects and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    wing: [{kind: flap, amp: 15, period: 1.6, axis: z}]
    tuft: [{kind: sway, amp: 15, period: 1.8, axis: x}]
    pack: [{kind: bob, amp: 0.05, period: 1.1, phase: 0.5}]
    root: [{kind: sway, amp: 4, period: 2.2, axis: z}]
    face: [{kind: blink, period: 4.4}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Pengoo.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Pengoo.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Pengoo_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Pengoo_idle.png]]

The concept sheet, drawn from the parts table above: [[Pengoo_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: skin everywhere (the navy carries the jitter and the grout; the cream face cells are drawn exactly, never jittered).

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: with the cream drawn right round the eyes the house eye's corner cells broke the stamp, so each eye sits in a navy patch the exact size of the stamp, which reads as the penguin's dark hood. Round 2: the beak dropped from the forehead to between the eyes so the smile stays under it; a tail was cut to keep 15 blocks. Round 3 (the silhouette test): as a plain block with its flippers close it overlapped Sabrek, Skadra and Fenrir at 0.73 to 0.78 in the boxed 64 px test, so the flippers went out and up (20 degrees off horizontal, a quarter stud longer): a penguin with its arms up, which leaves the box's corners empty and drops every pair under 0.7. Overlap 0.993 to 0.994, 346 triangles, 15 blocks, 2.75 studs, two moving objects (the flippers). Wanted for: a two-tone penguin always sliding somewhere with its pack on. Still cheap: the runners read as feet from the front; the glint is only in the effects. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), two rounds. The plate puts its eyes on the head's own cells, and its old cream face was drawn in the grid on a navy head, so the head became the cream face (`BodyDark`) under a navy hood. Round 1: a full-width navy crown read as a flat cap on a white cube. Round 2: the crown narrowed to a step, two hood sides cover the back three quarters of the head's sides (the front corners stay cream, so no headphones) and a nape closes the back: a penguin again. Eyes: `twotone`, navy over icy blue with two shines, on a 28 x 12 plate, blush, no drawn mouth (the beak carries it); the goggles' strap is ink so it reads on the cream. A feather `Tuft` on the crown (height 2.75 to 3, its own character: the tuft) sways, the pack bounces, the flippers flap, it waddles and blinks. Five moving things (four objects and the blink). 20 blocks (the Uncommon cap), 400 triangles, overlap 0.995 to 0.998. Wanted for: the busy one, a hooded penguin chick with goggles and a backpack, always about to slide off somewhere. Still weak: the crown step still reads flat from the high camera, and the backpack hides behind it from the front. Status review.
