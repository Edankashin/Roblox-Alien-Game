---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Snowbun
name: Flurra
world: 2
tier: Common
status: review
element: Snowdust
height: 2.47
blocks: 10
tris: 208
bevel_width: 0.1
bevel_segments: 2
palette: ["#B4A9E6", "#CFE2F3", "#F0407F", "#2A2340"]
roles: [body, second, accent, ink]
hero: Ball
vfx: "none (Common): the snowball tail grows in three steps over 9 s and pops back to small with a puff of snow dust (Effects.luau, the Flake emitter at Tail); it hops, a bob of 0.14 studs; the ears flap, a procedural move of the two ear parts; no particles beyond the dust, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Snowbun_sheet.svg]]"
render: "[[Snowbun_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.998, 0.998, 0.997]
cells_render: "[[Snowbun_tq_cells.jpg]]"
---
# Snowbun (Flurra), Common, World 2 Frostbyte

A lavender snow bunny with a snowball for a tail that is bigger than the bunny: a soft lavender head that is most of the animal, two long ears with deep pink insides, one up and one flopped out to its left (lop-eared), two paws of tinted snow, and behind it a stepped snowball of the same snow (a base step, the ball, a cap) that rolls along on the ground and never stops growing. Concept row in `src/shared/data/Species.luau`: "snow bunny, snowball tail that keeps growing". Element and effect: [[Roster-Redesign]] section 2 (the tail grows in three steps, then pops back with a puff of snow dust). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** The first thing on the snow that is not white: a lavender bunny whose tail is a snowball it cannot stop rolling, so it tows its own weight everywhere it hops. It stays plain on purpose (one lavender, white, one pink, no glow, no light) so every rung above it reads as more.

**Hero block.** The `Ball`, a stepped snowball of pure white snow behind the bunny, as tall as its head: unique in Frostbyte (Mitt is a snowball; Flurra drags one).

**Alien anatomy.** The snowball is part of it: a tail that is a growing drift it tows along the ground; it has no hind legs, only two front paws of snow, and its ears are rooted into the top corners of its head, one standing and one that never learned to.

**World motif (Frostbyte).** The ice facet as steps: the snowball is a stepped round (base, ball, cap); the snow lip of the world's ground runs over the snowball's sides and the paws (the `snow` cells).

## Parts

```yaml
parts:
  # two paws of snow in front (no hind legs: the snowball is behind)
  - {name: Paw, slot: BodyDark, size: [0.75, 0.375, 0.75], at: [0.625, 0.1875, -0.25], mirror: x, material: snow}
  # the head is the bunny: a soft lavender block, bevelled
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, 0], bevel: true}
  # long ears, pink inside, one up and one flopped out to its left (lop-eared), each one moving part
  - {name: EarUp, slot: Body, size: [0.5, 1.25, 0.25], at: [0.6875, 1.8125, -0.125], rot: [0, 0, -10], moves: ear, pivot: [0.5, 1.5, -0.125]}
  - {name: InnerUp, slot: Accessory, size: [0.25, 0.875, 0.125], at: [0.75, 1.875, -0.3125], rot: [0, 0, -10], moves: ear, pivot: [0.5, 1.5, -0.125]}
  - {name: EarDown, slot: Body, size: [0.5, 1.25, 0.25], at: [-1.1875, 1.375, -0.125], rot: [0, 0, 110], moves: ear, pivot: [-0.5, 1.5, -0.125]}
  - {name: InnerDown, slot: Accessory, size: [0.25, 0.875, 0.125], at: [-1.25, 1.375, -0.3125], rot: [0, 0, 110], moves: ear, pivot: [-0.5, 1.5, -0.125]}
  # the hero: the snowball tail, a stepped round of snow that rolls on the ground behind the bunny
  - {name: BallBase, slot: BodyDark, size: [1, 0.25, 1], at: [0, 0.125, 1.5], material: snow}
  - {name: Ball, slot: BodyDark, size: [1.5, 1.5, 1.5], at: [0, 1, 1.5], material: snow}
  - {name: BallCap, slot: BodyDark, size: [1, 0.25, 1], at: [0, 1.875, 1.5], material: snow}
```

## Face

The house face ([[Blocky-Style]] rule 3) on the head's front, 16 cells across the 2-stud head, so one cell is 0.125 studs and the 1.25-stud front is 10 rows. A pink nose (`n`) sits between the smile's corners; the lit crescent is the accent pink (a Common has no glow).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FFA3BF"
    "n": accent
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.knnk.gg..."
    - "..pp...kk...pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Snowbun.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Snowbun.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Snowbun_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Snowbun_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 19 cells tall. Materials: `snow` on the snowball and the paws (a white top with drifts and a sparkle, the lip over white strata on the sides, so the ball reads as rolled snow), plain skin on the lavender head and ears.

## Reviews

- 2026-10-20, World 2 roster worker, three rounds. Round 1: a white snowball and white paws on a lavender bunny vanished against the backdrop (Mitt's scarf lesson), so the snow is a shadowed blue-white in the second slot and the lavender deepened to keep the greyscale gaps. Round 2: the ears leaning out 25 degrees filled the box's top corners and the pair with Mitt rose to 0.75, so one ear stands at 10 degrees and the other flops out to its left (worst pair now 0.68, with Floe). Overlap 0.997 to 0.998, 208 triangles, 10 blocks, 2.47 studs, two moving objects (the ears). Wanted for: a bunny towing a snowball bigger than itself. Still cheap: the ball sits behind the head and only the three-quarter and side views show it. Status review.
