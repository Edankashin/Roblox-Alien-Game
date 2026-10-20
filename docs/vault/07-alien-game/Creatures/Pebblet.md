---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Pebblet
name: Pebblet
world: 1
tier: Common
status: review
element: Stone
height: 2.5
blocks: 9
tris: 196
bevel_width: 0.1
bevel_segments: 2
palette: ["#C4B9A6", "#5A5048", "#D27A16", "#1E1A17"]
roles: [body, second, accent, ink]
hero: Cairn
vfx: "none (Common): a puff of grit at its feet every 4 s when it hops (Effects.luau's grey Feet emitter) and a 0.1-stud hop; no particles otherwise, no glow, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Pebblet_sheet.svg]]"
render: "[[Pebblet_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.996, 0.996, 0.995]
cells_render: "[[Pebblet_tq_cells.jpg]]"
---
# Pebblet (Pebblet), Common, World 1 Verdant

A smooth grey-tan pebble that grew four stubby slate legs and walks: a wide, low, soft-cornered stone (the head, half of which is face) on four stone stumps splayed out past its corners, so there is air under it. On its back it balances a cairn: three smaller stones stacked and stepped off to one side, the way a hiker leaves a marker on a trail. A patch of orange lichen grows on its right flank. Concept row in `src/shared/data/Species.luau`: "pebble with legs". Element and effect: [[Roster-Redesign]] section 2 (Stone; a puff of grit when it hops). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is a rock with a face, which is already funny, and the cairn on its back says it is going somewhere and wants to be found again. The Common rung on purpose: three flat colours (stone, slate, lichen orange), no glow and no light, a hop and a puff.

**Hero block.** The `Cairn`: three stacked stones on its back, leaning off to one side, unique in Verdant.

**Alien anatomy.** A stone that walks on four legs and carries a cairn; nothing a pet animal does.

**World motif (Verdant).** The moss cell as the cobbles of the stone motif on every block, and the lichen patch in the accent.

## Parts

```yaml
parts:
  # the pebble: one wide low stone, soft-cornered, the face on its front
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1.125, 0], bevel: true, material: stone}
  # four stone stumps at the corners, so the pebble stands with air under it
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.125, 0.25, -0.5], mirror: x, material: stone}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.125, 0.25, 0.5], mirror: x, material: stone}
  # the hero: a cairn of three stones balanced on its back, stepped off to the right
  - {name: Cairn, slot: Body, size: [1, 0.25, 0.75], at: [0.375, 1.875, 0.125], material: stone}
  - {name: Cairn2, slot: BodyDark, size: [0.75, 0.25, 0.5], at: [0.5, 2.125, 0.125], material: stone}
  - {name: Cairn3, slot: Body, size: [0.5, 0.25, 0.375], at: [0.625, 2.375, 0.1875], material: stone}
  # a patch of orange lichen on the right flank, proud by an eighth
  - {name: Lichen, slot: Accessory, size: [0.125, 0.5, 0.625], at: [1.0625, 1.25, 0.1875]}
```

## Face

The house face ([[Blocky-Style]] rule 3) on the pebble's front, 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on a Common, the eye's lit crescent is the accent, the lichen orange.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#F0968A"
  rows:
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
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Pebblet.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Pebblet.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Pebblet_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Pebblet_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (50 islands). Materials: stone on the pebble, the legs and the cairn (cobbles parted by cracks), the lichen patch plain.

## Reviews

- 2026-10-19, World 1 roster worker, three rounds. Round 1: a stone box on four stumps with the cairn centred read as a box with a hat, and the boxed silhouette sat at 0.70 against Moop. Round 2: the legs splayed out past the body's corners and the cairn leaning off to its right, the body a warmer stone (the pale first grey read as paper), the lichen a step darker so the accent clears the body in greyscale. Round 3: no change after the side-by-side. Wanted for: a rock with a face that carries a cairn. Still cheap: it is the boxiest of the nine (the cairn and the stance are what save it); the stone cobbles read only up close. Status review.
