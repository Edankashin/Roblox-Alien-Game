---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Capybubble
name: Snorzo
world: 2
tier: Rare
status: review
element: Bubble
height: 3.13
blocks: 23
tris: 458
bevel_width: 0.1
bevel_segments: 2
palette: ["#E0C3A0", "#5C4A2A", "#FFF1D6", "#FF9A2E", "#5FDCFF", "#2B1D12"]
roles: [body, second, accent, trim, glow, ink]
hero: Tangerine
vfx: "a soft light (Rare): snore bubbles rise from its nose, three every 4 s, one pops with a tiny splash (Effects.luau, the Ring emitter at Mouth); steam wisps off its back (the Wisp at Top); the three bubble parts beside its head are lit and bob, one moving group; a soft teal light; it breathes 4 percent, asleep; the ears move"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Capybubble_sheet.svg]]"
render: "[[Capybubble_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.997, 0.996, 0.994]
vfx_render: "[[Capybubble_vfx_cells.jpg]]"
cells_render: "[[Capybubble_tq_cells.jpg]]"
---
# Capybubble (Snorzo), Rare, World 2 Frostbyte

A tan capybara loaf, long and low, dozing in the Geyser Field's warm pools: a square head with a cream muzzle drawn into the face under a flat dark nose, two small ears, a furred torso behind on four stubby umber legs, a glossy tangerine sitting on its head with a stem and a leaf, three lit bubbles rising from its nose up the side of its head, and a bubble-ring glyph stamped on each flank. Concept row in `src/shared/data/Species.luau`: "capybara, tangerine hat, snores bubbles". Element and effect: [[Roster-Redesign]] section 2 (snore bubbles rise from its nose, one pops; a soft teal light). Rules: [[Blocky-Style]].

**What makes a player want it.** A joke, on purpose: the calmest animal in the world, asleep with a tangerine on its head, snoring bubbles that glow. Nothing about it is fierce. The Rare rung exactly: a stamped element glyph (the bubble ring on each flank), one glossy trim slot (the tangerine) and a soft light (the bubbles), at 3.1 studs to Floe's 3.

**Hero block.** The `Tangerine`, a glossy orange orb on its head with a stem and a leaf: unique in Frostbyte.

**Alien anatomy.** The bubbles it snores are part of it, three orbs of light that float beside its head and never pop (the `float` group the game bobs); the tangerine grew there; it has no neck, and its nose is a flat bar proud of the muzzle.

**World motif (Frostbyte).** The ice facet as steps: the muzzle steps down the face and the nose steps out of it; the warm Geyser Field accent (tangerine and cream) against the cold glow of the bubbles.

## Parts

```yaml
parts:
  # four stubby umber legs
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, -0.75], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, 1.25], mirror: x}
  # the square head and the long furred torso
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.25, -1], bevel: true}
  - {name: Torso, slot: Body, size: [2, 1.25, 2.25], at: [0, 1.125, 0.875], bevel: true, material: fur}
  # the flat dark nose, proud of the muzzle
  - {name: Nose, slot: Eye, size: [0.5, 0.125, 0.125], at: [0, 0.8125, -1.8125]}
  # small ears, each one moving part
  - {name: Ear, slot: BodyDark, size: [0.5, 0.375, 0.25], at: [0.75, 2.1875, -1.25], mirror: x, moves: ear, pivot: [0.75, 2, -1.25]}
  # the hero: a glossy tangerine on its head, a stem and a leaf
  - {name: Tangerine, slot: Trim, size: [1, 0.75, 1], at: [0, 2.375, -0.875], shape: ico1}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 2.875, -0.875]}
  - {name: Leaf, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [0.25, 3.0625, -0.875]}
  # the snore bubbles rising from the nose up the right side of the head, lit, one floating group
  - {name: Bubble, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.125, 1.375, -1.625], shape: ico1, moves: float, pivot: [1, 1, -1.75]}
  - {name: Bubble2, slot: Glow, size: [0.5, 0.5, 0.5], at: [1.5, 1.875, -1.5], shape: ico1, moves: float, pivot: [1, 1, -1.75]}
  - {name: Bubble3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.625, 2.5, -1.375], shape: ico1, moves: float, pivot: [1, 1, -1.75]}
  # the stamped element glyph: a bubble ring (a hollow square of eighth-stud bars) in glossy tangerine on each flank
  - {name: Glyph, slot: Trim, size: [0.125, 0.125, 0.75], at: [1.0625, 1.4375, 0.875], mirror: x}
  - {name: Glyph2, slot: Trim, size: [0.125, 0.125, 0.75], at: [1.0625, 0.8125, 0.875], mirror: x}
  - {name: Glyph3, slot: Trim, size: [0.125, 0.5, 0.125], at: [1.0625, 1.125, 0.5625], mirror: x}
  - {name: Glyph4, slot: Trim, size: [0.125, 0.5, 0.125], at: [1.0625, 1.125, 1.1875], mirror: x}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front. A cream muzzle (`c`, the accent) fills the lower rows under the nose bar, with a small sleepy mouth on it; the eye's lit crescent is the bubbles' glow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9C8A"
    "c": accent
  rows:
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.cccc.gg..."
    - "..pp.cc..cc.pp.."
    - "....cckkkkcc...."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Capybubble.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Capybubble.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Capybubble_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Capybubble_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Capybubble_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 25 cells tall. Materials: `fur` on the torso (soft tufts on a lattice; the 2-stud head stays skin so the tufts never crowd the face), the bubbles in glow cells, the tangerine and the glyphs glossy (the trim slot), skin on the head, legs and ears.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a muzzle block hid the crescent rows, so the muzzle is drawn into the face and only the nose bar stands proud. Round 2: the glyph as a lit plus read as a first-aid cross, so it is a hollow square ring of eighth-stud bars in the glossy tangerine. Overlap 0.994 to 0.997, 458 triangles, 23 blocks, 3.12 studs, three moving objects (the ears, the bubble group). Wanted for: a capybara asleep under a tangerine, snoring bubbles. Still cheap: the bubbles rise on one side only; the torso's fur tufts are faint on tan. Status review.
