---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Zapfinch
name: Zirrit
world: 1
tier: Rare
status: review
element: Lightning
height: 3.25
blocks: 20
tris: 416
bevel_width: 0.1
bevel_segments: 2
palette: ["#4FA8E8", "#23386B", "#F3F0E2", "#F2C14E", "#FFEE55", "#101A33"]
roles: [body, second, accent, trim, glow, ink]
hero: Crest
arcs: ["CrestTipR>CrestTipL"]
vfx: "a soft light (Rare): the two crest tips glow and a static spark jumps between them every 3 s (Effects.luau's pale blue Beam, 0.2 s flicker); sparkles pop off the crest at 4 a second; a soft blue light; the wings flick 15 degrees every 1.2 s and the head tilts every 4 s"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Zapfinch_sheet.svg]]"
render: "[[Zapfinch_tq_cells.jpg]]"
glb: ""
overlap: [0.992, 0.993, 0.997, 0.992]
vfx_render: "[[Zapfinch_vfx_cells.jpg]]"
cells_render: "[[Zapfinch_tq_cells.jpg]]"
---
# Zapfinch (Zirrit), Rare, World 1 Verdant

A round sky-blue finch with a gold beak: a big square head on a small body, a cream belly carrying a stamped gold lightning bolt, two navy wings held low at its sides, a three-feather navy tail fanned behind, two thin legs on wide feet, and on its crown the crest that names it: two antennae leaning apart with lit yellow balls on their tips, between which the static jumps. Concept row in `src/shared/data/Species.luau`: "bird, antenna crest". Element and effect: [[Roster-Redesign]] section 2 (Lightning; a spark jumps between the antenna tips every 3 s). Rules: [[Blocky-Style]].

**What makes a player want it.** It is a bird with a spark gap on its head: two lit balls that crackle at each other every few seconds, so it is seen before it is heard. The Rare rung exactly: a stamped element glyph (the gold bolt on its belly), one glossy trim slot (the beak and the bolt) and a soft light (the crest tips), at 3.25 studs.

**Hero block.** The `Crest` pair: two antennae with lit tips, unique in Verdant (Voltus's are lightning rods beside a bolt; this is a spark gap on a songbird).

**Alien anatomy.** A bird with antennae instead of a crest of feathers; four moving objects: the two wings and the two crest antennae.

**World motif (Verdant).** The moss cell as the eighth-stud cells of the bolt glyph and the quarter-stud beak.

## Parts

```yaml
parts:
  # two thin legs on wide feet
  - {name: Foot, slot: Trim, size: [0.5, 0.125, 0.625], at: [0.5, 0.0625, -0.1875], mirror: x, material: metal}
  - {name: Leg, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [0.5625, 0.3125, 0.0625], mirror: x}
  # the small body and the big head over it
  - {name: Body, slot: Body, size: [1.5, 1, 1.5], at: [0, 1, 0.25], bevel: true}
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -0.25], bevel: true}
  # a gold beak proud of the face where the mouth would be
  - {name: Beak, slot: Trim, size: [0.5, 0.25, 0.375], at: [0, 1.5, -1.1875], material: metal}
  # the cream belly plate under the head, with the stamped element glyph: a three-row gold bolt
  - {name: Belly, slot: Accessory, size: [1, 0.5, 0.125], at: [0, 0.875, -0.5625]}
  - {name: Bolt, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.1875, 1.0625, -0.6875], material: metal}
  - {name: Bolt2, slot: Trim, size: [0.5, 0.125, 0.125], at: [0, 0.9375, -0.6875], material: metal}
  - {name: Bolt3, slot: Trim, size: [0.375, 0.125, 0.125], at: [-0.1875, 0.8125, -0.6875], material: metal}
  # two wings held low at the sides, 15 degrees down (the pair the game flicks)
  - {name: Wing, slot: BodyDark, size: [1, 0.125, 1], at: [1.25, 1.125, 0.25], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25]}
  # a tail of three feathers fanned behind, the outer pair turned out 20 degrees
  - {name: TailMid, slot: BodyDark, size: [0.5, 0.125, 0.75], at: [0, 1.1875, 1.375]}
  - {name: TailSide, slot: BodyDark, size: [0.375, 0.125, 0.75], at: [0.4375, 1.1875, 1.3125], rot: [0, 20, 0], mirror: x}
  # the hero: two antennae leaning apart 15 degrees with lit balls on their tips (the pair the game tilts)
  - {name: Crest, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.3125, 2.75, -0.5625], rot: [0, 0, -15], mirror: x, moves: crest, pivot: [0.3125, 2.5, -0.5625]}
  - {name: CrestTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.4375, 3.0625, -0.5625], shape: ico1, mirror: x, moves: crest, pivot: [0.3125, 2.5, -0.5625]}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front. The mouth is the gold beak block proud of the face, so the grid carries the eyes and the cheeks only; the eye's lit crescent is the crest's yellow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9FB0"
  rows:
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg......gg..."
    - "..pp........pp.."
    - "................"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Zapfinch.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Zapfinch.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Zapfinch_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Zapfinch_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Zapfinch_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 26 cells tall; one atlas of 512 x 512 at 8 texels a cell (104 islands). Materials: metal on the beak, the feet and the bolt glyph, skin elsewhere; the crest tips are glow cells.

## Reviews

- 2026-10-19, World 1 roster worker, one round. Built as drawn: the gold beak proud of the face, the lit crest tips, the bolt on the cream belly, the wings held low and the fan tail all read; the bolt's rows and the tail's middle feather moved onto the half grid. Wanted for: a bird with a spark gap on its head. Still cheap: from straight ahead the crest is two posts with balls; the Rare preview is a soft light and little else. Status review.
