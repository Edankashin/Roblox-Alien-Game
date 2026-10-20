---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Kettlepuff
name: Kettlet
world: 2
tier: Common
status: review
element: Steam
height: 2.5
blocks: 10
tris: 208
bevel_width: 0.1
bevel_segments: 2
palette: ["#F5EDE0", "#C8743A", "#FFB347", "#2B1F1A"]
roles: [body, second, accent, ink]
hero: Spout
vfx: "none (Common): a steam puff from the spout every 4 s (Effects.luau, the Wisp emitter at Top); the puff part bobs over the spout, a procedural float; it wobbles 3 degrees; a whistle when excited; no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Kettlepuff_sheet.svg]]"
render: "[[Kettlepuff_tq_cells.jpg]]"
glb: ""
overlap: [0.998, 0.996, 0.997, 0.998]
cells_render: "[[Kettlepuff_tq_cells.jpg]]"
---
# Kettlepuff (Kettlet), Common, World 2 Frostbyte

A cream enamel kettle with the face on its belly: a copper base ring it stands on, a copper lid with an amber knob, a copper bail handle arching over the top, a copper spout out of its right side that turns up at the tip, and a puff of steam that floats above the spout's mouth. Its mouth is a round whistle. Concept row in `src/shared/data/Species.luau`: "kettle, steam puff ring, whistles when excited". Element and effect: [[Roster-Redesign]] section 2 (a steam puff from the spout every 4 s; a whistle). Rules: [[Blocky-Style]].

**What makes a player want it.** The camp's kettle got up and walked: the one warm thing on the Geyser Field, cream and copper against the snow, whistling when it sees you. Plain on purpose: cream, copper, amber, no glow and no light.

**Hero block.** The `Spout`, copper, out of its right side and turning up at the tip with its steam puff above it: unique in Frostbyte.

**Alien anatomy.** It has no legs (it rocks on its base ring), its handle is a bone it was born with, and the steam puff is part of it: a cloud that floats above the spout and never quite blows away (the `float` part the game bobs).

**World motif (Frostbyte).** The ice facet as steps: the lid, knob and base ring step in from the body like a cut gem; the warm accent (copper in `metal` cells) is the Geyser Field's answer to the ice.

## Parts

```yaml
parts:
  # no legs: a copper base ring it rocks on
  - {name: Base, slot: BodyDark, size: [1.5, 0.25, 1.25], at: [0, 0.125, 0], material: metal}
  # the kettle is the head: cream enamel, bevelled
  - {name: Kettle, slot: Body, size: [2, 1.5, 1.75], at: [0, 1, 0], bevel: true}
  # the copper lid with an amber knob
  - {name: Lid, slot: BodyDark, size: [1.5, 0.25, 1.25], at: [0, 1.875, 0], material: metal}
  - {name: Knob, slot: Accessory, size: [0.5, 0.25, 0.5], at: [0, 2.125, 0]}
  # the bail handle: two copper posts and a bar arching over the lid
  - {name: Post, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [0.875, 2, 0], mirror: x, material: metal}
  - {name: Bar, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 2.375, 0], material: metal}
  # the hero: the copper spout out of the right side, its tip turned up
  - {name: Spout, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.25, 1, -0.25], material: metal}
  - {name: SpoutTip, slot: BodyDark, size: [0.375, 0.75, 0.375], at: [1.5625, 1.5, -0.25], rot: [0, 0, -20], material: metal}
  # the steam puff floating over the spout's mouth, one moving part
  - {name: Puff, slot: Body, size: [0.5, 0.5, 0.5], at: [1.75, 2.25, -0.25], shape: ico1, moves: float, pivot: [1.75, 2.25, -0.25]}
```

## Face

The house face on the kettle's front: 16 cells across the 2-stud body (0.125 a cell), 12 rows for the 1.5-stud front. The mouth is a round whistle (a 2 x 2 block of ink); the lit crescent is the accent amber (a Common has no glow).

```yaml
face:
  host: Kettle
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF9C8A"
  rows:
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg..kk..gg..."
    - "..pp...kk...pp.."
    - "................"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Kettlepuff.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Kettlepuff.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Kettlepuff_tq_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Kettlepuff_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 20 cells tall. Materials: `metal` on every copper part (panels, a seam, a rivet in each panel's corner: base, lid, handle, spout), skin on the cream enamel, the amber knob and the steam puff.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: the handle's posts ran a quarter stud up into the bar and the merged copper mesh's recalculated normals turned both ends inside out, black in the lit view and invisible in the flat orthographic views (0.998), so the posts now end where the bar begins (a lesson in [[Blocky-Style]]). Overlap 0.996 to 0.998, 208 triangles, 10 blocks, 2.5 studs, one moving object (the steam puff). Wanted for: the camp's kettle, cream and copper on the snow, whistling. Still cheap: the puff is one white icosahedron; the spout's turn is a single tilted block. Status review.
