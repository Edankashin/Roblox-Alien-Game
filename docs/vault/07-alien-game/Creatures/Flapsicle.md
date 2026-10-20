---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Flapsicle
name: Eekle
world: 2
tier: Uncommon
status: review
element: Ice
height: 2.75
blocks: 15
tris: 354
bevel_width: 0.1
bevel_segments: 2
palette: ["#3F4C8C", "#8FC9F0", "#FF9BB0", "#121630"]
roles: [body, second, accent, ink]
hero: IceWing
vfx: "one touch (Uncommon): the icicle wings shed frost dust at each flap, 2 a second (Effects.luau, the Flake emitter at BackL, falling); it hangs upside down and sways 5 degrees; the two wings flap 20 degrees; two moving pairs (the wings, the ears); no glow, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Flapsicle_sheet.svg]]"
render: "[[Flapsicle_tq_cells.jpg]]"
glb: ""
overlap: [0.992, 0.993, 0.998, 0.992]
cells_render: "[[Flapsicle_tq_cells.jpg]]"
---
# Flapsicle (Eekle), Uncommon, World 2 Frostbyte

An indigo bat hanging upside down from nothing: a small block of ice floats in the air with its two feet clamped round it, its round body hangs under that, and its big head hangs lowest with the house face the right way up (it twists its head to look at you), two wide ears splayed out and down with pink insides, a pink belly patch, two wings of clear ice spread out and down from its shoulders five studs across with an icicle hanging under each tip, and an icicle under its chin that rests on the snow. Concept row in `src/shared/data/Species.luau`: "bat, icicle wings, hangs upside down from nothing". Element and effect: [[Roster-Redesign]] section 2 (frost dust off the wings at each flap; it sways). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the Ice Cave's night catch, hanging from a hook that is not there, so low its chin rests on the snow, wings spread wide, looking at you upside down with the same soft face as everything else. The Uncommon rung exactly: a two-tone body (indigo over ice), one secondary block (the perch of nothing) and a second colour in the touch (the frost dust), at 2.75 studs.

**Hero block.** The `IceWing` pair, two plates of clear ice with icicles at their tips, hanging from the shoulders: unique in Frostbyte (Skadra's wings are feathers; these are ice).

**Alien anatomy.** It hangs from a block of frozen air that goes everywhere with it; its wings are ice, not skin, and shed frost when they move; its head twists so the face stays upright while the rest of it hangs.

**World motif (Frostbyte).** Icicles, the ice facet hanging: three stepped points, one under each wingtip and one under the chin; the wings, the icicles and the perch are `ice` cells.

## Parts

```yaml
parts:
  # the perch of nothing: a floating block of ice, the feet clamped round it
  - {name: Perch, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0, 2.625, 0], material: ice}
  - {name: Foot, slot: Body, size: [0.25, 0.25, 0.25], at: [0.375, 2.625, 0], mirror: x}
  # the body hangs under the perch, the head hangs lowest and carries the face
  - {name: Body, slot: Body, size: [1.5, 1, 1.25], at: [0, 2, 0], bevel: true}
  - {name: Belly, slot: Accessory, size: [1, 0.5, 0.125], at: [0, 2, -0.6875]}
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, 0], bevel: true}
  # wide ears splayed out and down from the head's sides, pink inside, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.875, 0.25], at: [1.1875, 0.75, -0.125], rot: [0, 0, -110], mirror: x, moves: ear, pivot: [0.75, 0.875, -0.125]}
  - {name: InnerEar, slot: Accessory, size: [0.25, 0.625, 0.125], at: [1.1875, 0.75, -0.3125], rot: [0, 0, -110], mirror: x, moves: ear, pivot: [0.75, 0.875, -0.125]}
  # the hero: wings of ice spread out and down from the shoulders, an icicle hanging under each tip; each wing one moving part
  - {name: IceWing, slot: BodyDark, size: [2, 0.25, 1], at: [1.6875, 1.9375, 0], rot: [0, 0, -20], mirror: x, moves: wing, pivot: [0.75, 2.25, 0], material: ice}
  - {name: WingIcicle, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [2.5, 1.25, 0], rot: [180, 0, 0], shape: cone6, mirror: x, moves: wing, pivot: [0.75, 2.25, 0], material: ice}
  # it hangs so low the icicle under its chin rests on the snow
  - {name: ChinIcicle, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 0.1875, -0.5], rot: [180, 0, 0], shape: cone6, material: ice}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. A pink nose (`n`) between the eyes, two white fang cells beside the smile; the lit crescent is the accent pink (an Uncommon has no glow).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9DB8"
    "n": accent
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk.nn.kwgk.."
    - "...gg.k..k.gg..."
    - "..pp..wkkw..pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Flapsicle.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Flapsicle.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Flapsicle_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Flapsicle_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: `ice` on the wings, the wingtip icicles and the perch (light bands on the other diagonal, glossy), skin on the indigo body, head and ears.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: wings hanging down beside the body cleared the head by a hair and the boxed test put it with Dreep, Soakum and Floe at 0.74 to 0.82, so the ice wings spread out and down from the shoulders five studs across (20 degrees under horizontal) with an icicle under each tip, and an icicle under the chin took the ground. Round 2: pale ice wings (L* 90) vanished against the backdrop, so the second colour is a mid ice blue. Overlap 0.992 to 0.998, 354 triangles, 15 blocks, 2.75 studs, four moving objects (the wings, the ears). Wanted for: a bat hanging from nothing, so low its chin rests on the snow. Still cheap: upside down with the face upright, the body over the head can read as a hat; the perch is one small block. Status review.
