---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Twiglet
name: Twiglo
world: 1
tier: Common
status: review
element: Bloom
height: 2.49
blocks: 10
tris: 210
bevel_width: 0.1
bevel_segments: 2
palette: ["#9C6B3F", "#4A2E1A", "#7FC94A", "#1F140B"]
roles: [body, second, accent, ink]
hero: Hat
vfx: "none (Common): one leaf lets go of the hat and drifts down every 8 s (Effects.luau's green Top emitter, falling); it sways 4 degrees side to side; no glow, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Twiglet_sheet.svg]]"
render: "[[Twiglet_tq_cells.jpg]]"
glb: ""
overlap: [0.993, 0.996, 0.999, 0.993]
cells_render: "[[Twiglet_tq_cells.jpg]]"
---
# Twiglet (Twiglo), Common, World 1 Verdant

A stick bug that is a twig: a square bark head with the face, a twig body that rises out of its back like a growing shoot, four thin stick legs (the front pair wide under the head's corners, the hind pair long and close together under the twig), two antennae leaning forward, and one broad green leaf wider than its head worn as a hat on a short stem, tipped down over one side. Concept row in `src/shared/data/Species.luau`: "stick bug, leaf hat". Element and effect: [[Roster-Redesign]] section 2 (Bloom; a leaf lets go of the hat every 8 s). Rules: [[Blocky-Style]].

**What makes a player want it.** The leaf hat is a joke it is in on: a stick wearing a leaf and hoping to pass as a plant. The Common rung on purpose: brown, bark and leaf green, no glow and no light, a sway and a falling leaf.

**Hero block.** The `Hat`, one broad leaf worn tipped on a stem, unique in Verdant (Moop's leaves are a sprout pair, Raddis's are a fan).

**Alien anatomy.** A twig that walks: the body is a stick behind a square head, the legs are sticks, and the stance is an insect's (front legs wide, hind legs together).

**World motif (Verdant).** The moss cell as the eighth-stud sticks and the wood grain on every brown block.

## Parts

```yaml
parts:
  # the head: a square of bark, the face on its front
  - {name: Head, slot: Body, size: [2, 1.25, 1.25], at: [0, 1.125, -0.625], bevel: true, material: wood}
  # the twig body behind it
  - {name: Twig, slot: Body, size: [0.5, 0.5, 1.75], at: [0, 1.3125, 0.8125], rot: [-20, 0, 0], material: wood}
  # four stick legs: the front pair under the head's corners, the hind pair under the twig
  - {name: FrontLeg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, -0.9375], mirror: x, material: wood}
  - {name: HindLeg, slot: BodyDark, size: [0.125, 1.125, 0.125], at: [0.1875, 0.5625, 0.6875], mirror: x, material: wood}
  # two antennae leaning forward 20 degrees
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.625, 0.125], at: [0.375, 2, -1.0625], rot: [-20, 0, 0], mirror: x, material: wood}
  # the hero: a broad leaf hat on a short stem, tipped 20 degrees, down over its left side
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 1.875, -0.625], material: wood}
  - {name: Hat, slot: Accessory, size: [2.5, 0.125, 1.5], at: [0, 2, -0.625], rot: [0, 0, 20]}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on a Common, the eye's lit crescent is the accent, the leaf green (Moop's is lime).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#E58A6A"
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Twiglet.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Twiglet.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Twiglet_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Twiglet_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (57 islands). Materials: wood on the head, the twig, the legs, the antennae and the stem (grain along each stick), the leaf hat plain.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the twig body lay flat behind the head and vanished from the three-quarter view, and the leaf hat at the head's width put it at 0.70 against Pebblet and 0.69 against Moop. Round 2: the twig rises 20 degrees out of the back like a growing shoot with long hind legs under it, and the leaf is 2.5 studs across, wider than the head, tipped 20 degrees down over one side. Wanted for: a stick in a leaf hat hoping to pass as a plant. Still cheap: the bark head is a box; the antennae are two posts. Status review.
