---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Drippo
name: Dreep
world: 2
tier: Common
status: review
element: Meltwater
height: 2.5
blocks: 8
tris: 182
bevel_width: 0.1
bevel_segments: 2
palette: ["#A9D6F5", "#2F5F9F", "#0FB4E0", "#162B45"]
roles: [body, second, accent, ink]
hero: Tip
vfx: "none (Common): one drop falls from the drip under its chin every 3 s and lands in the puddle with a tiny ring (Effects.luau, the Mouth emitter, dir Down); it bobs 0.06 studs; no particles beyond the drop, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Drippo_sheet.svg]]"
render: "[[Drippo_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.995, 0.997, 0.995]
cells_render: "[[Drippo_tq_cells.jpg]]"
---
# Drippo (Dreep), Common, World 2 Frostbyte

An icicle that is also a drop: an ice-blue block with the face and a six-sided point on top, standing on two stubby blue legs, one arm up in a nervous wave and the other held tight to its side, a bright cyan drip forming at the corner of its mouth, and the puddle it has already made, spreading out to its left. Concept row in `src/shared/data/Species.luau`: "icicle drop, stubby legs, drips when nervous". Element and effect: [[Roster-Redesign]] section 2 (one drop falls every 3 s and lands with a ring). Rules: [[Blocky-Style]].

**What makes a player want it.** The nervous one: a worried little icicle that drips when you look at it, with a wobbly mouth and a drop that never quite falls. Plain on purpose: ice, one blue, one cyan, no glow and no light.

**Hero block.** The `Tip`, the six-sided ice point on its head, the top of the drop: unique in Frostbyte (the icicles of the Rare and the Epic hang; this one stands).

**Alien anatomy.** It is a drop of water that froze on its way down and grew legs; the drip under its chin is part of it (a lit core of meltwater) and the puddle is where it has been standing.

**World motif (Frostbyte).** The ice facet: the point on the block and the `ice` cells over the whole head, with the puddle in `frozen_water`.

## Parts

```yaml
parts:
  # two stubby legs
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, 0], mirror: x}
  # the drop: the head block and the six-sided point on it
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1.125, 0], bevel: true, material: ice}
  - {name: Tip, slot: Body, size: [1.25, 0.75, 1.25], at: [0, 2.125, 0], shape: cone6, material: ice}
  # one arm up (a nervous wave), one held down at its side
  - {name: ArmUp, slot: BodyDark, size: [0.25, 1, 0.25], at: [1.1875, 1.6875, -0.25], rot: [0, 0, -20]}
  - {name: ArmDown, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [-1.125, 0.9375, -0.25]}
  # the drip forming at the corner of its mouth, a lit core of meltwater, and the puddle it has already made, spreading to its left
  - {name: Drip, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-0.375, 0.375, -0.875], rot: [180, 0, 0], shape: cone6, material: glow}
  - {name: Puddle, slot: BodyDark, size: [1.25, 0.125, 0.75], at: [-0.875, 0.0625, -1.125], material: frozen_water}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. A wobbly worried mouth; the lit crescent is the accent cyan (a Common has no glow; a saturated cyan reads as lit where a pale one read as a tear).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9DB8"
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg......gg..."
    - "..pp.k.kk.k.pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Drippo.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Drippo.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Drippo_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Drippo_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 20 cells tall. Materials: `ice` on the head, step and point (light bands on the other diagonal, glossy; the face keeps a two-row fringe of it and plain cells below), `frozen_water` on the puddle (plates and a bubble, no grout), the drip in glow cells (a lit core, no emission on a Common), skin on the legs and arms.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a symmetric box with a point on quarter-stud legs overlapped Floe, Eekle and Soakum at 0.75 to 0.80 in the boxed test, so the legs grew to half a stud, the step went, the point grew to three quarters of a stud, one arm rose in a wave and the drip and the puddle moved to its left. Round 2: the pale ice body (L* 92) lost its point against the backdrop, so the body is the placeholder's ice blue with a deeper blue and a saturated cyan. Overlap 0.995 to 0.997, 182 triangles, 8 blocks, 2.5 studs, no moving parts (it bobs). Wanted for: a worried icicle that drips when looked at. Still cheap: the ice bands barely show on a 2-stud head; the drip is one small cone. Status review.
