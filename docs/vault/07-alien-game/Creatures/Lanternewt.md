---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Lanternewt
name: Lantrin
world: 1
tier: Uncommon
status: review
element: Light
height: 2.75
blocks: 14
tris: 352
bevel_width: 0.1
bevel_segments: 2
palette: ["#F26B3A", "#4A2638", "#FFD24A", "#1E1016"]
roles: [body, second, accent, ink]
hero: Lamp
vfx: "one touch (Uncommon): the tail lamp's warm light breathes with it (Effects.luau's amber Tail light, 3.2 s pulse) and one warm mote drifts off it every 2 s; the tail sways 6 degrees; no glow region on the model"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Lanternewt_sheet.svg]]"
render: "[[Lanternewt_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.995, 0.995, 0.996]
cells_render: "[[Lanternewt_tq_cells.jpg]]"
---
# Lanternewt (Lantrin), Uncommon, World 1 Verdant

An orange newt that carries a lantern on its tail: a wide square head low to the ground, a long low body on four stubby legs, two dark feathery gills sweeping back from the head like an axolotl's, two yellow spots on its back, and a tail that curls up behind it to hold a lantern: a dark metal base and cap round a yellow glass. Concept row in `src/shared/data/Species.luau`: "newt, glowing tail". Element and effect: [[Roster-Redesign]] section 2 (Light; the lamp breathes). Rules: [[Blocky-Style]].

**What makes a player want it.** It only comes out at night and it brings its own light: a small orange thing in the dark grass with a lantern held up behind it. An Uncommon has no glow region, so the glass is painted in the accent yellow and the game's Light layer does the breathing; above it on the ladder the light becomes real.

**Hero block.** The `Lamp`, a caged lantern on the tip of an upturned tail, unique in Verdant (Glim's bulb trails behind on a stalk; this is a lamp with a base and a cap).

**Alien anatomy.** External gills on a creature that walks the meadow, and a tail that is a lamp post.

**World motif (Verdant).** The moss cell as the quarter-stud spots and the eighth-stud gill feathers.

## Parts

```yaml
parts:
  # four stubby legs
  - {name: Leg, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.75, 0.1875, -0.5], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.625, 0.1875, 1.25], mirror: x}
  # the head, wide and low, the face on its front; the long low body behind it
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, -0.75], bevel: true}
  - {name: Body, slot: Body, size: [1.5, 1, 2], at: [0, 0.875, 1], bevel: true}
  # alien anatomy: two feathery gills sweeping back and up from the head's sides, 20 degrees
  - {name: Gill, slot: BodyDark, size: [0.75, 0.125, 0.125], at: [1.3125, 1.4375, -0.1875], rot: [0, 0, 20], mirror: x}
  # two yellow spots on the back
  - {name: Spot, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.375, 1.4375, 0.75]}
  - {name: Spot2, slot: Accessory, size: [0.25, 0.125, 0.25], at: [-0.25, 1.4375, 1.5]}
  # the hero: the tail curls up 25 degrees behind it and holds a lantern: a metal base and cap round a yellow glass
  - {name: Tail, slot: Body, size: [0.5, 0.5, 1.25], at: [0, 1.5, 2.5], rot: [-25, 0, 0], moves: tail, pivot: [0, 1.125, 1.9375]}
  - {name: LampBase, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [0, 1.9375, 3.125], moves: tail, pivot: [0, 1.125, 1.9375], material: metal}
  - {name: Lamp, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0, 2.25, 3.125], moves: tail, pivot: [0, 1.125, 1.9375], material: glow}
  - {name: LampCap, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [0, 2.625, 3.125], moves: tail, pivot: [0, 1.125, 1.9375], material: metal}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on an Uncommon, the eye's lit crescent is the accent, the lamp yellow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9A8A"
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Lanternewt.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Lanternewt.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Lanternewt_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Lanternewt_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 22 cells tall; one atlas of 512 x 512 at 8 texels a cell (80 islands). Materials: metal on the lamp's base and cap, glow cells (a lit core, no emission) on the glass, skin elsewhere.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: built as drawn; the lamp on the upturned tail read at once, the gills as fins. Round 2: the body a stud tall so one bevel width fits both masses, the finial dropped to stay under 2.75 and 15 blocks. Wanted for: a small orange thing in the dark grass with its own lantern. Still cheap: the body is long and plain between the spots; the lamp's glass is painted, not lit (an Uncommon has no glow region). Status review.
