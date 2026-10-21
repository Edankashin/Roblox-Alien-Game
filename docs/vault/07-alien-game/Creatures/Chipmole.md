---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Chipmole
name: Digling
world: 2
tier: Common
status: review
element: Ice chips
height: 2.38
blocks: 12
tris: 234
bevel_width: 0.1
bevel_segments: 2
palette: ["#5B6B85", "#2F3A4E", "#3FD3F7", "#141B28"]
roles: [body, second, accent, ink]
hero: Pick
vfx: "Common, one layer (Effects.luau): a Burst of three ice-chip grit sprites (C9E6F5) kicks up at FrontL every 5 s; the idle bob is 0.1 studs every 0.9 s; no light; the picks rock and the tail wags in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Chipmole_sheet.svg]]"
render: "[[Chipmole_tq_cells.jpg]]"
glb: ""
overlap: [0.999, 0.996, 0.998, 0.999]
cells_render: "[[Chipmole_tq_cells.jpg]]"
idle_render: "[[Chipmole_idle.png]]"
---
# Chipmole (Digling), Common, World 2 Frostbyte

A squat slate-blue mole, low to the ground, with a frost-nipped ice nose proud of its face, a dark rump, a frost-nipped stub tail standing up off its rump, four dark paws, and two ice picks taller than itself held up out of its front paws: a dark wooden handle rising from each paw with a blade of bright ice pointing forward at the top. Concept row in `src/shared/data/Species.luau`: "mole, ice-pick claws, chips the floor". Element and effect: [[Roster-Redesign]] section 2 (ice chips kick up from the claws, a scratch at each chip). Rules: [[Blocky-Style]].

**What makes a player want it.** The first dark thing on Frostbyte, a mole that cannot dig frozen ground and has grown two ice picks to chip at it instead, held up like a miner about to start. Plain on purpose: slate, one darker slate, one cyan, no glow and no light.

**Hero block.** The `Pick` pair, two blades of ice on handles as tall as the mole, raised over its shoulders: unique in Frostbyte.

**Alien anatomy.** The picks are its claws: they grow out of the front paws, handle and all, and regrow after every chip; it walks on the paws' heels while the picks stay up. Three moving objects: the pick pair (`pickR`, `pickL`, which rock as if chipping) and the stub `tail`.

**World motif (Frostbyte).** The ice facet: the pick blades are six-sided ice points lying forward, in `ice` cells.

## Parts

```yaml
parts:
  # the head is most of the mole, low and long; a dark rump behind it
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 0.875, -0.25], bevel: true}
  - {name: Rump, slot: BodyDark, size: [1.5, 1, 1], at: [0, 0.75, 1.125]}
  # four dark paws: the front pair big, the picks grow out of them
  - {name: Paw, slot: BodyDark, size: [0.5, 0.5, 0.75], at: [1, 0.25, -0.875], mirror: x}
  - {name: HindPaw, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0.75, 0.125, 1], mirror: x}
  # the hero: two ice picks, a wooden handle up from each front paw and a blade of ice pointing forward at the top
  - {name: Handle, slot: BodyDark, size: [0.25, 1.5, 0.25], at: [1, 1.25, -1.125], mirror: x, moves: pick, pivot: [1, 0.5, -1.125], material: wood}
  - {name: Pick, slot: Accessory, size: [0.5, 1, 0.5], at: [1, 2.125, -1.625], rot: [-90, 0, 0], shape: cone6, mirror: x, moves: pick, pivot: [1, 0.5, -1.125], material: ice}
  # B46 detail: a frost-nipped nose proud of the face between the eyes, and a frost-nipped stub tail standing up off the rump's back corner on
  # the camera's side, leaning back, that wags (straight out behind the rump, low and dark, the three-quarter camera never saw it)
  - {name: Nose, slot: Accessory, size: [0.25, 0.125, 0.125], at: [0, 0.9375, -1.1875], material: ice}
  - {name: Tail, slot: Accessory, size: [0.25, 0.5, 0.25], at: [0.375, 1.25, 1.625], rot: [20, 0, 0], material: ice, moves: tail, pivot: [0.375, 1, 1.5625]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell); the eyes, the mouth and the cheeks are on the face plate, and the ice `Nose` block sits proud of the plate between the eyes.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `pebble`, a Common design, a wide soft oval with a long shine, a mole's small wide eyes made big, at 16 pixels a stud on a 1.75 x 0.625 stud plate (28 x 10 pixels, three frames). A buck `tooth` mouth for the digger under the ice nose, and blush cheeks. The only `pebble` in Frostbyte.

```yaml
eyes:
  key: pebble
  mouth: tooth
  cheeks: blush
  plate: [1.75, 0.625]
  at: [0, 0.875]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the two picks rock forward and back as if chipping (`pickR`, `pickL`), the stub tail wags, the whole mole breathes and the face blinks. Four moving things (three objects and the blink; a Common needs two, and four objects is its cap); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    pick: [{kind: sway, amp: 12, period: 2.4, axis: x}]
    tail: [{kind: wag, amp: 20, period: 1.6, axis: z}]
    root: [{kind: squash, amp: 0.04, period: 2.2}]
    face: [{kind: blink, period: 3.8}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Chipmole.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Chipmole.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Chipmole_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Chipmole_idle.png]]

The concept sheet, drawn from the parts table above: [[Chipmole_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 18 cells tall. Materials: `ice` on the pick blades (lit bands, glossy), `wood` on the handles (grain along the length), skin on the slate body.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: the pick blades at a quarter stud read as cyan gems on two posts, so they are half-stud cones a stud long, which raised it to 2.38 studs. Round 2: the pick pair became the `jaw` mover the scratch tween needs. Overlap 0.996 to 0.999, 206 triangles, 10 blocks, 2.38 studs, two moving objects (the picks). Wanted for: the dark one, a mole with two ice picks held up over its shoulders. Still cheap: the handles are dark slate in the second colour and the wood grain hardly reads; the rump is a plain block. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), two rounds. Round 1: `sleepy` eyes read as a bored squint (the flat lid on a dark slate face is a frown), so they went to `pebble`, wide soft ovals with a long shine, on a 28 x 10 plate; the drawn pink snout became an ice `Nose` block proud of the plate with a buck `tooth` under it, and a stub `Tail` joined the rump. Rig: the picks rock 12 degrees as if chipping, the tail wags, the body breathes, a blink every 3.8 s (four moving things, three objects). Height 2.38 (in band, unchanged: it is a low mole), 12 blocks (the Common cap), 234 triangles, overlap 0.991 to 0.999. Wanted for: the dark one, a buck-toothed mole with an icy nose and two picks it rocks like a miner. Still weak: the tail is hidden from the three-quarter view, and the handles still read slate more than wood. Status review.
- 2026-10-21, Polish w2 worker: the tail was unseen from three-quarter (low, dark and straight out behind the rump). It now stands up off the rump's back corner on the camera's side (x 0.375), half a stud tall and leaning back 20 degrees, frost-nipped in the ice accent like the nose, and it wags side to side (axis z) instead of twisting; still 12 blocks (the Common cap), 234 triangles, overlap 0.996 to 0.999. Honest read: the three-quarter and high cameras now see a little ice tail; from the front a sliver of it peeks over the head.
