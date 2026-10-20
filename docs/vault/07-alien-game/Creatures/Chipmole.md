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
blocks: 10
tris: 206
bevel_width: 0.1
bevel_segments: 2
palette: ["#5B6B85", "#2F3A4E", "#3FD3F7", "#141B28"]
roles: [body, second, accent, ink]
hero: Pick
vfx: "none (Common): ice chips kick up from the picks every 5 s, three particles (Effects.luau, the FrontL emitter); a claw scratch, a 10 degree tween of the pick parts, at each chip; it bobs 0.1 studs; no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Chipmole_sheet.svg]]"
render: "[[Chipmole_tq_cells.jpg]]"
glb: ""
overlap: [0.999, 0.996, 0.998, 0.999]
cells_render: "[[Chipmole_tq_cells.jpg]]"
---
# Chipmole (Digling), Common, World 2 Frostbyte

A squat slate-blue mole, low to the ground, with a pink snout drawn into its face, a dark rump behind its head, four dark paws, and two ice picks taller than itself held up out of its front paws: a dark wooden handle rising from each paw with a blade of bright ice pointing forward at the top. Concept row in `src/shared/data/Species.luau`: "mole, ice-pick claws, chips the floor". Element and effect: [[Roster-Redesign]] section 2 (ice chips kick up from the claws, a scratch at each chip). Rules: [[Blocky-Style]].

**What makes a player want it.** The first dark thing on Frostbyte, a mole that cannot dig frozen ground and has grown two ice picks to chip at it instead, held up like a miner about to start. Plain on purpose: slate, one darker slate, one cyan, no glow and no light.

**Hero block.** The `Pick` pair, two blades of ice on handles as tall as the mole, raised over its shoulders: unique in Frostbyte.

**Alien anatomy.** The picks are its claws: they grow out of the front paws, handle and all, and regrow after every chip; it walks on the paws' heels while the picks stay up. Two moving objects: the pick pair (the `jaw` parts the game scratches with).

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
  - {name: Handle, slot: BodyDark, size: [0.25, 1.5, 0.25], at: [1, 1.25, -1.125], mirror: x, moves: jaw, pivot: [1, 0.5, -1.125], material: wood}
  - {name: Pick, slot: Accessory, size: [0.5, 1, 0.5], at: [1, 2.125, -1.625], rot: [-90, 0, 0], shape: cone6, mirror: x, moves: jaw, pivot: [1, 0.5, -1.125], material: ice}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. A pink snout (`n`) between the smile's corners; the lit crescent is the accent cyan (a Common has no glow).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9DB8"
    "n": "#FF9EB5"
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg..nn..gg..."
    - "..pp.k.nn.k.pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Chipmole.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Chipmole.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Chipmole_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Chipmole_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 18 cells tall. Materials: `ice` on the pick blades (lit bands, glossy), `wood` on the handles (grain along the length), skin on the slate body.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: the pick blades at a quarter stud read as cyan gems on two posts, so they are half-stud cones a stud long, which raised it to 2.38 studs. Round 2: the pick pair became the `jaw` mover the scratch tween needs. Overlap 0.996 to 0.999, 206 triangles, 10 blocks, 2.38 studs, two moving objects (the picks). Wanted for: the dark one, a mole with two ice picks held up over its shoulders. Still cheap: the handles are dark slate in the second colour and the wood grain hardly reads; the rump is a plain block. Status review.
