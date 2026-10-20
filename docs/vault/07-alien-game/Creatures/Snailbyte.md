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
blocks: 12
tris: 326
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
overlap: [0.993, 0.995, 0.998, 0.992]
cells_render: "[[Snailbyte_tq_cells.jpg]]"
---
# Snailbyte (Snibble), Uncommon, World 1 Verdant

A mint-green snail whose shell is a copper machine: a square soft head with the face at the front of a broad dark foot, two feelers leaning out, and behind the head a riveted copper shell: a tall coil that stands edge-on, taller than the head and off to its left, with a dark whorl-eye bolted to each face, an aerial and a little dish on the shoulder beside it. Concept row in `src/shared/data/Species.luau`: "snail, metal shell". Element and effect: [[Roster-Redesign]] section 2 (Light; a glint sweeps the shell every 4 s). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first thing on the meadow that is partly a machine: a snail that built itself a copper shell with hatches and an aerial, which says someone could fix a ship with it. The Uncommon rung exactly: a two-tone body (mint over the dark foot), one secondary block (the shell) and one touch of a second colour (the copper on the shell, the dish and the eye's crescent).

**Hero block.** The `Shell`, a riveted copper coil standing edge-on and off to one side, with an aerial, unique in Verdant.

**Alien anatomy.** It has no legs and slides on a foot; its shell is metal with hatches, and it listens through a dish.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the shell and the whorl-eyes.

## Parts

```yaml
parts:
  # the foot it slides on, broad and dark
  - {name: Foot, slot: BodyDark, size: [2.5, 0.375, 2.75], at: [0.25, 0.1875, 0.125]}
  # the head: a soft mint cube at the front, the face on it
  - {name: Head, slot: Body, size: [2, 1.25, 1.25], at: [0.375, 1, -0.75], bevel: true}
  # two feelers leaning out 20 degrees
  - {name: Feeler, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [1.25, 1.9375, -0.6875], rot: [0, 0, -20]}
  - {name: FeelerL, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [-0.5, 1.9375, -0.6875], rot: [0, 0, 20]}
  # the hero: a copper shell, a tall coil that stands edge-on behind the head and off to its left: the whorl, its outer turn behind and
  # lower, a step on top, a dark whorl-eye bolted to its face, an aerial and a dish on its left shoulder
  - {name: Shell, slot: Accessory, size: [1, 1.75, 1.75], at: [-0.625, 1.5, 0.625], bevel: true, material: metal}
  - {name: ShellBack, slot: Accessory, size: [1, 1.25, 0.5], at: [-0.625, 1.125, 1.75], material: metal}
  - {name: ShellTop, slot: Accessory, size: [1, 0.25, 1.25], at: [-0.625, 2.5, 0.625], material: metal}
  - {name: ShellTop2, slot: Accessory, size: [0.75, 0.125, 0.75], at: [-0.625, 2.6875, 0.625], material: metal}
  - {name: Whorl, slot: BodyDark, size: [0.125, 0.75, 0.75], at: [-1.1875, 1.5, 0.625], material: metal}
  - {name: WhorlR, slot: BodyDark, size: [0.125, 0.5, 0.5], at: [-0.0625, 1.5, 0.625], material: metal}
  - {name: Aerial, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.8125, 1.75, 0.4375], material: metal}
  - {name: Dish, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.75, 1.9375, 0.5], material: metal}
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

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 22 cells tall; one atlas of 512 x 1024 at 8 texels a cell (67 islands). Materials: metal on the shell, its outer turn and step, the whorl-eyes, the aerial and the dish (panels, seams and rivets), skin on the head, the foot and the feelers.

## Reviews

- 2026-10-19, World 1 roster worker, four rounds. Round 1: a shell in three centred steps behind the head: a ziggurat, 0.83 against Moop. Round 2: shifted right with a wide foot, 0.73. Round 3: the shell as a tall coil stood edge-on (1 stud wide, 1.75 tall) off to one side, the head offset the other way, the foot wide: 0.68. Round 4: the coil to its left (Pebblet's cairn leans right) and a second step on top. Wanted for: a snail that built itself a copper machine. Still cheap: the coil reads as a riveted tower, not a spiral (a whorl needs cells drawn on the face, a later motif); the dish is hidden from the three-quarter camera. Status review.
