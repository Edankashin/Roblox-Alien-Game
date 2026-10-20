---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Snailbyte
name: Snibble
world: 1
tier: Uncommon
status: review
element: Light
height: 2.75
blocks: 13
tris: 246
bevel_width: 0.1
bevel_segments: 2
palette: ["#9FD9A6", "#2F6B4F", "#C9803E", "#14221A"]
roles: [body, second, accent, ink]
hero: Shell
vfx: "one touch (Uncommon): a glint sweeps across the copper shell every 4 s and a sparkle pops off it at 2 a second (Effects.luau's pale Back emitter); it slides 0.3 studs forward and back; no glow region, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Snailbyte_sheet.svg]]"
render: "[[Snailbyte_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.998, 0.996, 0.997]
cells_render: "[[Snailbyte_tq_cells.jpg]]"
---
# Snailbyte (Snibble), Uncommon, World 1 Verdant

A mint-green snail whose shell is a copper machine: a square soft head with the face at the front of a broad, flat, dark foot, two feelers leaning out, and behind the head a riveted copper shell that is a stepped spiral standing edge-on, taller than the head and off to its left, the whole coil turned 20 degrees so its face looks toward the camera: a disc with the whorl drawn in cells on its flat faces, an outer turn of riveted panels winding round it in four steps that taper from the thick base behind the dark mouth to a thin lip down the front, and an aerial with a little dish on the foot's right shoulder. Concept row in `src/shared/data/Species.luau`: "snail, metal shell". Element and effect: [[Roster-Redesign]] section 2 (Light; a glint sweeps the shell every 4 s). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first thing on the meadow that is partly a machine: a snail that built itself a copper shell with hatches and an aerial, which says someone could fix a ship with it. The Uncommon rung exactly: a two-tone body (mint over the dark foot), one secondary block (the shell) and one touch of a second colour (the copper on the shell, the dish and the eye's crescent).

**Hero block.** The `Shell`, a riveted copper coil standing edge-on and off to one side, the whorl on its faces and the outer turn stepping round it, unique in Verdant.

**Alien anatomy.** It has no legs and slides on a foot; its shell is metal with hatches, and it listens through a dish.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the shell's outer turn.

## Parts

```yaml
parts:
  # the foot it slides on, broad, flat and dark, a sole under the head
  - {name: Foot, slot: BodyDark, size: [3, 0.25, 2.75], at: [0, 0.125, 0.125]}
  - {name: Sole, slot: BodyDark, size: [1.5, 0.125, 1], at: [0.375, 0.3125, -0.75]}
  # the head: a soft mint cube at the front, the face on it
  - {name: Head, slot: Body, size: [2, 1.25, 1.25], at: [0.375, 1, -0.75], bevel: true}
  # two feelers leaning out 20 degrees
  - {name: Feeler, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [1.25, 1.9375, -0.6875], rot: [0, 0, -20]}
  - {name: FeelerL, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [-0.5, 1.9375, -0.6875], rot: [0, 0, 20]}
  # the hero: a copper shell that is a stepped spiral standing edge-on behind the head and off to its left, the whole coil turned 20
  # degrees so its flat face looks toward the three-quarter camera (every block of it yawed about the core's centre). The core is a disc
  # with the whorl drawn in cells on its two flat faces; the outer turn winds round it as four narrower steps that taper as they go: the
  # thick base turn behind the mouth, up the back, forward over the top (the tallest point) and a thin lip down the front, ending above
  # the dark mouth where the body comes out
  - {name: Shell, slot: Accessory, size: [1.25, 1.5, 1.5], at: [-0.875, 1.625, 0.75], rot: [0, 20, 0], material: whorl}
  - {name: ShellBase, slot: Accessory, size: [0.75, 0.625, 1.625], at: [-0.75, 0.5625, 1.0625], rot: [0, 20, 0], material: metal}
  - {name: ShellBack, slot: Accessory, size: [0.75, 1.75, 0.375], at: [-0.5625, 1.5, 1.625], rot: [0, 20, 0], material: metal}
  - {name: ShellTop, slot: Accessory, size: [0.75, 0.375, 1.5], at: [-0.875, 2.5625, 0.75], rot: [0, 20, 0], material: metal}
  - {name: ShellLip, slot: Accessory, size: [0.75, 0.625, 0.25], at: [-1.1875, 2.0625, -0.0625], rot: [0, 20, 0], material: metal}
  - {name: Mouth, slot: BodyDark, size: [0.75, 0.625, 0.25], at: [-1.0625, 0.5625, 0.1875], rot: [0, 20, 0]}
  # an aerial and a little dish on the right shoulder of the foot, where the three-quarter camera sees them beside the head
  - {name: Aerial, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [1.4375, 0.75, 0.4375], material: metal}
  - {name: Dish, slot: Accessory, size: [0.5, 0.125, 0.5], at: [1.5, 1.1875, 0.5], material: metal}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on an Uncommon, the eye's lit crescent is the accent, the copper.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#F29AA6"
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Snailbyte.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Snailbyte.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Snailbyte_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Snailbyte_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 22 cells tall; one atlas of 512 x 1024 at 8 texels a cell (75 islands; the yawed shell's faces are not culled). Materials: whorl on the shell's core (a square spiral a step and a half down on its two flat faces, one ring further out every third of a lap, a lit ridge inside each turn; metal panels on its narrow faces), metal on the outer turn, the aerial and the dish (panels, seams and rivets), skin on the head, the foot, the mouth and the feelers.

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "tower, not a spiral"). The shell is a stepped spiral: a 1.25 x 1.5 x 1.5 core disc on the new `whorl` cell motif (the coil drawn on its flat faces) with the outer turn wound round it as four narrower metal steps that taper from the base to the lip, a dark mouth under the lip where the body leaves the shell; the whorl-eye plates and the ziggurat top are gone; the dish moved to the foot's right shoulder where the three-quarter camera sees it. Round 2: the coil was there but faint, a one-cell line on a face the camera sees at a glance, so the whorl line is two cells wide and two steps down and the whole shell is yawed 20 degrees about the core's centre (every block of it, so the turn stays wound on the core; a tilted mass takes no bevel) to face the three-quarter view. The yawed coil put the boxed silhouette at 0.70 against Moop; the shell a quarter further left and the foot a flat quarter-stud slab 3 studs wide (its corners now empty the box's bottom row; a sole under the head keeps the mass on it) took it to 0.66. 13 blocks, 2.75 studs. Status review.

- 2026-10-19, World 1 roster worker, four rounds. Round 1: a shell in three centred steps behind the head: a ziggurat, 0.83 against Moop. Round 2: shifted right with a wide foot, 0.73. Round 3: the shell as a tall coil stood edge-on (1 stud wide, 1.75 tall) off to one side, the head offset the other way, the foot wide: 0.68. Round 4: the coil to its left (Pebblet's cairn leans right) and a second step on top. Wanted for: a snail that built itself a copper machine. Still cheap: the coil reads as a riveted tower, not a spiral (a whorl needs cells drawn on the face, a later motif); the dish is hidden from the three-quarter camera. Status review.
