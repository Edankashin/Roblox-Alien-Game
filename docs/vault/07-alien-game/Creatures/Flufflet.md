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
blocks: 10
tris: 220
bevel_width: 0.1
bevel_segments: 2
palette: ["#F2F6FA", "#9CC3E0", "#F0614A", "#1C2433"]
roles: [body, second, accent, ink]
hero: Scarf
vfx: "none (Common): a snowflake lands on its head every 6 s and melts over 1 s (Effects.luau, the Flake emitter at Top); the mitten ears flap once every 5 s, a procedural move of the two ear parts; no particles beyond the one flake, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Flufflet_sheet.svg]]"
render: "[[Flufflet_tq_cells.jpg]]"
glb: ""
overlap: [0.999, 0.998, 1, 0.999]
cells_render: "[[Flufflet_tq_cells.jpg]]"
---
# Flufflet (Mitt), Common, World 2 Frostbyte

A snowball with a face, wrapped in a knitted scarf, with two mittens for ears, rolling along on a smaller snowball it never gets off. The head is the snowball itself, soft-cornered, with a narrower cap step on top so it reads as a round; the scarf is a thick ice-blue knit wrapped round its base with a knot and a tail hanging down the front right; the mittens are coral, thumbs out, standing on the head like ears; the base ball is a second, smaller snowball in the scarf's blue. Concept row in `src/shared/data/Species.luau`: "snowball, knitted scarf, mitten ears". Element and effect: [[Roster-Redesign]] section 2 (Snowfall: one flake lands and melts). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is the first thing caught on Frostbyte, so it has to be the cosiest thing on the snow: a white ball that is mostly face, dressed for the cold in a scarf and mittens, bobbing on its snowball. It stays plain on purpose: white, one blue, one coral, no glow and no light, so every rung above it reads as more.

**Hero block.** The `Scarf`, a thick knit in the second colour with coral flecks (the wool cells), wrapped round the snowball's base with a knot and a tail: unique in Frostbyte.

**Alien anatomy.** No legs: it rolls on a second snowball (the `Base`) that is part of it, and its ears are mittens it was never given, the two `ear` parts the game flaps.

**World motif (Frostbyte).** The ice facet as steps: the cap step over the round, the mitten thumbs as corner steps; the snow lip of the world's ground is echoed in the scarf's knot hanging over its base.

## Parts

```yaml
parts:
  # the snowball: the head is the ball, a narrower cap step rounds its top; soft fur cells
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 1.25, 0], bevel: true, material: fur}
  - {name: Cap, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 2.125, 0], material: fur}
  # alien anatomy: it rolls on a smaller snowball in the scarf's blue
  - {name: Base, slot: BodyDark, size: [0.75, 0.75, 0.75], at: [0, 0.375, 0], shape: ico1, material: fur}
  # the hero: a knitted scarf round the base of the ball, a knot in front and a tail hanging to the ground
  - {name: Scarf, slot: BodyDark, size: [2.25, 0.375, 2], at: [0, 0.6875, 0], material: wool}
  - {name: Knot, slot: BodyDark, size: [0.5, 0.375, 0.25], at: [0.75, 0.6875, -1.125], material: wool}
  - {name: Tail, slot: BodyDark, size: [0.375, 0.5, 0.25], at: [0.9375, 0.25, -1.125], material: wool}
  # mitten ears, thumbs out, each mitten one moving part
  - {name: Mitten, slot: Accessory, size: [0.5, 0.5, 0.25], at: [0.75, 2.25, 0], mirror: x, moves: ear, pivot: [0.75, 2, 0]}
  - {name: Thumb, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.125, 2.125, 0], mirror: x, moves: ear, pivot: [0.75, 2, 0]}
```

## Face

The house face ([[Blocky-Style]] rule 3) on the snowball's front, 16 cells across the 2-stud head, so one cell is 0.125 studs and the 1.5-stud front is 12 rows. The lit crescent is the accent coral (a Common has no glow).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF8FA3"
  rows:
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.k..k.gg..."
    - "..pp...kk...pp.."
    - "................"
    - "................"
```

## Build

`python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Flufflet.md --out <scratch>` draws the sheet and the view masks; `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Flufflet.md --out <scratch>` builds the GLB into that scratch folder (never `assets/models`; `glb` stays empty until Ethan approves the sheet) and renders the views (commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Flufflet_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Flufflet_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs, the silhouette row and the numbers: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 20 cells tall. Materials: `fur` on the head, cap and base (soft tufts on a lattice, so the white reads as a snowball with a few flecks and never as noise), `wool` on the scarf, knot and tail (shag blobs with coral flecks: the knit), plain skin on the mittens.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: the mittens stood upright on the head and read as ears from the front and as mittens from the side; tilting them out put the thumbs over 2.5 studs, so they stay upright. The scarf in the body white vanished against the snowball; in the second blue with coral flecks it reads as a knit. Round 2: the tail hangs from the knot to the ground, so from the front the scarf has a direction. Overlap 0.998 to 1.000, 220 triangles, 10 blocks, 2.5 studs, two moving objects (the mittens). Wanted for: the cosiest thing on the snow, a snowball that is mostly face, dressed for the cold. Still cheap: at ten blocks the mittens are small; the base ball is only read from the side. Status review.
