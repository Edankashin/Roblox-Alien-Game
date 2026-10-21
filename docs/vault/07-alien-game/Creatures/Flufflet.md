---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Flufflet
name: Mitt
world: 2
tier: Common
status: review
element: Snowfall
height: 2.5
blocks: 12
tris: 246
bevel_width: 0.1
bevel_segments: 2
palette: ["#F2F6FA", "#9CC3E0", "#F0614A", "#1C2433"]
roles: [body, second, accent, ink]
hero: Scarf
vfx: "Common, one layer (Effects.luau): a Burst of one pixel snowflake (F2F6FA) drifts down onto its head every 6 s and melts; the idle breathes 2.5 percent every 2.8 s; no light; the mitten ears flick, the scarf tail swings and the ball rocks in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Flufflet_sheet.svg]]"
render: "[[Flufflet_tq_cells.jpg]]"
glb: ""
overlap: [0.999, 0.998, 1, 0.999]
cells_render: "[[Flufflet_tq_cells.jpg]]"
idle_render: "[[Flufflet_idle.png]]"
---
# Flufflet (Mitt), Common, World 2 Frostbyte

A snowball with a face, wrapped in a knitted scarf, with two mittens for ears, rolling along on a smaller snowball it never gets off. The head is the snowball itself, soft-cornered, with two narrower cap steps on top so it reads as a stepped round and never as a cube; the scarf is a thick ice-blue knit wrapped round its base with its knotted tail hanging down the front right nearly to the ground; the mittens are big and coral, thumbs out, standing on the head like ears; the base ball is a second, smaller snowball in the scarf's blue. Concept row in `src/shared/data/Species.luau`: "snowball, knitted scarf, mitten ears". Element and effect: [[Roster-Redesign]] section 2 (Snowfall: one flake lands and melts). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is the first thing caught on Frostbyte, so it has to be the cosiest thing on the snow: a white ball that is mostly face, dressed for the cold in a scarf and mittens, bobbing on its snowball. It stays plain on purpose: white, one blue, one coral, no glow and no light, so every rung above it reads as more.

**Hero block.** The `Scarf`, a thick knit in the second colour with coral flecks (the wool cells), wrapped round the snowball's base with its knotted tail hanging down: unique in Frostbyte.

**Alien anatomy.** No legs: it rolls on a second snowball (the `Base`) that is part of it, and its ears are mittens it was never given, the two `ear` parts the game flaps.

**World motif (Frostbyte).** The ice facet as steps: the two cap steps over the round, the mitten thumbs as corner steps; the snow lip of the world's ground is echoed in the scarf's tail hanging over its base.

## Parts

```yaml
parts:
  # the snowball: the head is the ball, two narrower cap steps round its top (a stepped round, not a cube); soft fur cells
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.125, 0], bevel: true, material: fur}
  - {name: Cap, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 1.875, 0], material: fur}
  - {name: Cap2, slot: Body, size: [1, 0.25, 0.75], at: [0, 2.125, 0], material: fur}
  # alien anatomy: it rolls on a smaller snowball in the scarf's blue
  - {name: Base, slot: BodyDark, size: [0.75, 0.75, 0.75], at: [0, 0.375, 0], shape: ico1, material: fur, moves: ball, pivot: [0, 0.375, 0]}
  # the hero: a knitted scarf round the base of the ball, its knot and tail hanging down the front right nearly to the ground
  - {name: Scarf, slot: BodyDark, size: [2.25, 0.375, 2], at: [0, 0.6875, 0], material: wool}
  - {name: Tail, slot: BodyDark, size: [0.5, 0.75, 0.25], at: [0.75, 0.5, -1.125], material: wool, moves: scarf, pivot: [0.75, 0.875, -1.125]}
  # B46 detail: the knot over the tail and a fringe stripe near its end, coral knit in the accent, swinging with it
  - {name: Knot, slot: Accessory, size: [0.5, 0.25, 0.125], at: [0.75, 0.75, -1.3125], material: wool, moves: scarf, pivot: [0.75, 0.875, -1.125]}
  - {name: Stripe, slot: Accessory, size: [0.5, 0.125, 0.125], at: [0.75, 0.3125, -1.3125], material: wool, moves: scarf, pivot: [0.75, 0.875, -1.125]}
  # big mitten ears, thumbs out, each mitten one moving part
  - {name: Mitten, slot: Accessory, size: [0.75, 0.75, 0.5], at: [0.875, 2.125, 0], mirror: x, moves: ear, pivot: [0.875, 1.75, 0]}
  - {name: Thumb, slot: Accessory, size: [0.25, 0.375, 0.5], at: [1.375, 2.0625, 0], mirror: x, moves: ear, pivot: [0.875, 1.75, 0]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud snowball (0.125 a cell), in soft fur cells; the eyes, the mouth and the cheeks are on the face plate, clear of the scarf's top.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `beam`, a Common design added for it in the Polish w2 pass, two bold two-pixel arcs closed in a big smile (9 x 5; the `happy` arcs at 7 x 4 read small on its snowball), over a `cat` mouth (a little w) and blush cheeks, the cosiest face on the snow (a ^w^), at 16 pixels a stud on a 1.75 x 0.5625 stud plate (28 x 9 pixels, three frames; its blink flattens the arcs). The only `beam` in the library.

```yaml
eyes:
  key: beam
  mouth: cat
  cheeks: blush
  plate: [1.75, 0.5625]
  at: [0, 1.125]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the mitten ears flick out in a burst every 5 s and sway a little between, the scarf's tail swings with its knot and stripe, the whole snowball rocks on the ball it rides, it breathes and the face blinks. Five moving things (four objects, the Common cap, and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    ear: [{kind: wag, amp: 18, period: 5, axis: z}, {kind: sway, amp: 5, period: 3, axis: x, phase: 0.25}]
    scarf: [{kind: sway, amp: 10, period: 2.2, axis: x}]
    ball: [{kind: sway, amp: 12, period: 2.8, axis: x}]
    root: [{kind: squash, amp: 0.04, period: 2.8}]
    face: [{kind: blink, period: 4.6}]
```

## Build

`python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Flufflet.md --out <scratch>` draws the sheet and the view masks; `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Flufflet.md --out <scratch>` builds the GLB into that scratch folder (never `assets/models`; `glb` stays empty until Ethan approves the sheet) and renders the views (commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Flufflet_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Flufflet_idle.png]]

The concept sheet, drawn from the parts table above: [[Flufflet_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs, the silhouette row and the numbers: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 20 cells tall. Materials: `fur` on the head, cap and base (soft tufts on a lattice, so the white reads as a snowball with a few flecks and never as noise), `wool` on the scarf and its knotted tail (shag blobs with coral flecks: the knit), plain skin on the mittens.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: the mittens stood upright on the head and read as ears from the front and as mittens from the side; tilting them out put the thumbs over 2.5 studs, so they stay upright. The scarf in the body white vanished against the snowball; in the second blue with coral flecks it reads as a knit. Round 2: the tail hangs from the knot to the ground, so from the front the scarf has a direction. Overlap 0.998 to 1.000, 220 triangles, 10 blocks, 2.5 studs, two moving objects (the mittens). Wanted for: the cosiest thing on the snow, a snowball that is mostly face, dressed for the cold. Still cheap: at ten blocks the mittens are small; the base ball is only read from the side. Status review.
- 2026-10-20, World 2 roster worker (the ladder review's fix): the head was still a soft cube, so it is 1.25 tall with two cap steps (1.5 then 1 wide), the scarf's knot and tail are one block hanging nearly to the ground, and the mittens grew to three quarters of a stud with bigger thumbs; the face is 10 rows. Overlap 0.998 to 1.000, 220 triangles, 10 blocks, 2.5 studs, two moving objects. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), one round. The house face became the library's `happy` (two soft arcs closed in a smile) over a `cat` mouth and blush cheeks, a ^w^, on a 28 x 9 plate kept clear of the scarf's top; a coral `Knot` and fringe `Stripe` in the accent knit dress the scarf's tail, which now swings as the `scarf` object; the base snowball became the `ball` the body rocks on; the mittens flick out every 5 s. Five moving things (four objects, the Common cap, and the blink). Height 2.5 (in band, unchanged), 12 blocks, 246 triangles, overlap 0.998 to 1. Wanted for: the cosiest face on the snow, a ^w^ in a scarf with mittens for ears. Still weak: the arcs are 7 pixels on a 32-pixel head and could be a pixel bigger, and the ball hardly shows under the scarf, so its rock reads mostly as the whole body tipping. Status review.
- 2026-10-21, Polish w2 worker: the arc eyes were small. A new Common design, `beam` (the Polish w2 block in `tools/blocky/eyes.py`): the same closed smile at 9 x 5 with two-pixel arcs, 28 percent of the head's width (from 22). 12 blocks, 246 triangles, overlap 0.998 to 1.000. Honest read: the ^w^ now carries from across the snow and is the cosiest face in Frostbyte.
