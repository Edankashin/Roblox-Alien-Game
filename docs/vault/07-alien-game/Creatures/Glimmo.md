---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Glimmo
name: Glim
world: 1
tier: Common
status: review
element: Light
height: 2.5
blocks: 9
tris: 196
bevel_width: 0.1
bevel_segments: 2
palette: ["#4FCFC0", "#2E7F78", "#FFE566", "#13302C"]
roles: [body, second, accent, ink]
hero: Bulb
vfx: "none (Common): the bulb blinks brighter for 0.5 s every 3 s (Effects.luau's yellow Back emitter, two motes a second); it hovers 0.25 studs on a 2.4 s bob; no glow region on the model, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Glimmo_sheet.svg]]"
render: "[[Glimmo_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.997, 0.997, 0.996]
cells_render: "[[Glimmo_tq_cells.jpg]]"
---
# Glimmo (Glim), Common, World 1 Verdant

A jelly firefly: a soft aqua jelly bell (the head, with the face) hovering with a yellow belly under it, three thin dark tendrils hanging from the bell that brush the grass, a firefly's yellow bulb curling up behind it like a tail in two steps, and two broad dark wing covers, a stud deep, hinged at its crown and lifted like a beetle about to fly. Concept row in `src/shared/data/Species.luau`: "jelly firefly". Element and effect: [[Roster-Redesign]] section 2 (Light; the bulb blinks every 3 s). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the night one: a jelly that floats at head height and blinks, the first thing a player sees move at dusk. A Common has no glow region and no light, so the bulb is painted in the accent yellow and the game's Effects row does the blinking; everything above it on the ladder adds real light.

**Hero block.** The `Bulb`, a firefly's yellow lantern curling up behind the bell in two steps, unique in Verdant (Lantrin's lamp is a caged ball on a tail).

**Alien anatomy.** A jellyfish that is also a firefly: it has no legs, it hangs tendrils, its light curls up behind it, and its wing covers open over wings it does not have (the game flicks them, the `wing` pair).

**World motif (Verdant).** The moss cell as the half-stud steps of the bulb and the tendrils.

## Parts

```yaml
parts:
  # the bell: a soft-cornered jelly cube, the face on its front, a yellow belly plate under it
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1.125, 0], bevel: true}
  - {name: Belly, slot: Accessory, size: [1, 0.125, 0.75], at: [0, 0.4375, 0]}
  # three thin tendrils hang from the bell and brush the ground: two in front, one behind
  - {name: Tendril, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.6875, 0.25, -0.6875], mirror: x}
  - {name: HindTendril, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.0625, 0.25, 0.6875]}
  # the hero: the firefly bulb, a yellow tail curling up behind the bell in two steps
  - {name: Bulb, slot: Accessory, size: [1, 0.75, 1], at: [0, 1.5, 1.25]}
  - {name: Bulb2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0, 1.875, 2]}
  # a firefly's wing covers: two broad dark plates, a stud deep and a quarter thick, hinged at the crown and lifted 25 degrees like a beetle about
  # to fly (the pair the game flicks)
  - {name: Elytron, slot: BodyDark, size: [1.5, 0.25, 1], at: [0.9375, 2.0625, 0.125], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.25, 1.75, 0.125]}
```

## Face

The house face on the bell's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on a Common, the eye's lit crescent is the accent, the firefly yellow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9DB4"
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Glimmo.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Glimmo.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Glimmo_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Glimmo_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (50 islands). Materials: skin everywhere (a jelly has no motif; the cells are what make it read as built).

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "two sticks at a distance"). The wing covers are plates now: a stud deep and a quarter thick instead of half a stud and an eighth, the same 1.5-stud reach and 25-degree lift, hinged a sixteenth lower so the outer tips stay under the Common cap of 2.5 studs; from the three-quarter view they read as lifted covers over a back, not sticks. Still 9 blocks, 2.5 studs. Status review.

- 2026-10-19, World 1 roster worker, four rounds. Round 1: a cube with two crystal wings at the crown read as ears, the three tendrils as legs, and the bulb hung behind where the camera never saw it. Round 2: a bell with a flared rim and a cap step, which put it at 0.71 against Moop. Round 3: no rim, no cap; the bulb curls up behind the bell like a tail where the three-quarter and the game camera see it, a yellow belly under the bell, and wing covers lifted 25 degrees; five wing-cover variants scored on the silhouette alone (steep, flat, low, long, none), the long pair the only one under 0.68. Round 4: the covers half as deep. Wanted for: the night one, a jelly that blinks. Still cheap: the covers read as two sticks from a distance and the jelly reads as an aqua box; the blink is all Effects.luau's. Status review.
