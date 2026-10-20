---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Wisplet
name: Wispkin
world: 1
tier: Rare
status: review
element: Shadow
height: 3.25
blocks: 22
tris: 342
bevel_width: 0.1
bevel_segments: 2
palette: ["#8FDCFF", "#2D5C9E", "#7B5CFF", "#6E6A85", "#B48CFF", "#141B33"]
roles: [body, second, accent, trim, glow, ink]
hero: Bail
vfx: "a soft light (Rare): the flame's tip glows lilac and a cold blue light hangs on the body (Effects.luau's 9BE7FF Light, pulsing every 1.4 s); one faint wisp mote rises off it every 1.5 s (the Wisp emitter); the flame wobbles 8 percent and the two wisps float with it; it hovers 0.5 studs on a 2.8 s bob; the bail swings with the hover"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Wisplet_sheet.svg]]"
render: "[[Wisplet_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.996, 0.997, 0.997]
vfx_render: "[[Wisplet_vfx_cells.jpg]]"
cells_render: "[[Wisplet_tq_cells.jpg]]"
---
# Wisplet (Wispkin), Rare, World 1 Verdant, the Haunted Nebula event

A will-o'-the-wisp: a cold blue flame the size of a lantern, floating a little off the grass with a shy face on its belly. The belly is a soft sky-blue block in flame cells (the lit tongues of the `ember` motif rising from its base), the flame narrows above it in three steps that lean to its right and end in a lilac-lit tip, with a second tongue licking up to the left, and tapers below it through two deep-blue steps swept to the left to a wisp of flame that brushes the ground. An iron lantern's bail handle, hinged to pins on the belly's sides, arches over the flame: the flame is the lantern, escaped from the glass. Two small flamelets float beside it at different heights, and a violet flame glyph is stamped on its right flank. Concept row in `src/shared/data/Species.luau`: "will-o'-the-wisp, a floating lantern flame with a shy face". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`: two weeks from 2026-10-16, World 1, nights twice as long, a Spectral overlay). Element and effect: [[Roster-Redesign]] section 2 (Shadow; a cold blue flame that flickers, one faint ember rising every 1.5 s, a soft blue light; `Effects.luau` calls the element Spirit). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the night's own light in the two weeks of the event: a blue flame that drifts over the meadow at dusk, shy when you get near, and the first Rare that is itself a light rather than carrying one. The Rare rung exactly: a stamped element glyph (the violet flame on its flank), one glossy trim slot (the iron bail), a soft light, four flat colours and a lilac glow at the tip.

**Hero block.** The `Bail`, a lantern's iron handle arched over a flame with no lantern, hinged to pins on the belly, unique in Verdant (Lantrin's lamp is a caged ball on a tail; Gaira's nimbus is a closed ring behind its head).

**Alien anatomy.** A flame with a face that carries its own lantern handle and sheds flamelets that float beside it; three moving objects: the bail (`halo`) and the two flamelets (`float`).

**World motif (Verdant).** The moss cell as the quarter-stud steps of the flame above and below the belly.

**Event palette (Haunted Nebula).** Sky blue over deep blue, with the event's violet as the accent and a lilac glow: the cold end of the event's purple-and-orange range (Grin carries the warm end, Cosmoo the deep violet).

## Parts

```yaml
parts:
  # the belly of the flame: a soft sky-blue block in flame cells, the face on its front
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.5, 0], bevel: true, material: ember}
  # the flame narrows above the belly in three steps leaning to its right, the top one lit, and a second tongue licks up to the left
  - {name: Flame, slot: Body, size: [1.5, 0.375, 1], at: [0.125, 2.4375, 0], material: ember}
  - {name: Flame2, slot: Body, size: [1, 0.375, 0.75], at: [0.375, 2.8125, 0], material: ember}
  - {name: Flame3, slot: Glow, size: [0.5, 0.25, 0.5], at: [0.5, 3.125, 0]}
  - {name: FlameL, slot: Body, size: [0.5, 0.625, 0.5], at: [-0.6875, 2.75, 0], rot: [0, 0, 20], material: ember}
  # and tapers below it through two deep-blue steps to a wisp that brushes the grass
  - {name: Base, slot: Body, size: [1.5, 0.375, 1], at: [0, 0.5625, 0], material: ember}
  - {name: Base2, slot: BodyDark, size: [1, 0.25, 0.75], at: [-0.375, 0.25, 0.125], material: ember}
  - {name: Trail, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [-0.75, 0.0625, 0.25], material: ember}
  # the hero: a lantern's iron bail, a quarter stud thick so it reads across the meadow, hinged to a pin on each side of the belly and
  # stepping up behind the flame to a bar over its tip (it swings)
  - {name: BailPin, slot: Trim, size: [0.5, 0.25, 0.25], at: [1.25, 1.5, 0.75], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: Bail, slot: Trim, size: [0.25, 0.75, 0.25], at: [1.375, 2, 0.875], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: Bail2, slot: Trim, size: [0.75, 0.25, 0.25], at: [1, 2.5, 0.875], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: Bail3, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.625, 2.75, 0.875], mirror: x, material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  - {name: BailTop, slot: Trim, size: [1.5, 0.25, 0.25], at: [0, 3, 0.875], material: metal, moves: halo, pivot: [0, 1.5, 0.875]}
  # two flamelets floating beside the belly at different heights, leaning out 15 degrees (each one moving part)
  - {name: Wisp, slot: Body, size: [0.375, 0.5, 0.375], at: [1.4375, 1.9375, 0.4375], rot: [0, 0, -15], material: ember, moves: float, pivot: [1.4375, 1.9375, 0.4375]}
  - {name: WispL, slot: Body, size: [0.375, 0.5, 0.375], at: [-1.4375, 0.9375, 0.4375], rot: [0, 0, 15], material: ember, moves: float, pivot: [-1.4375, 0.9375, 0.4375]}
  # the stamped element glyph: a violet flame of three steps on the right flank, proud by an eighth
  - {name: Glyph, slot: Accessory, size: [0.125, 0.125, 0.5], at: [1.0625, 1.0625, 0.25]}
  - {name: Glyph2, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.0625, 1.25, 0.25]}
  - {name: Glyph3, slot: Accessory, size: [0.125, 0.125, 0.125], at: [1.0625, 1.4375, 0.1875]}
```

## Face

The house face on the belly's front: 16 cells across the 2-stud block (0.125 a cell), 12 rows for the 1.5-stud front. Shy: a small closed mouth of two cells and big blush cheeks three cells wide and two tall. The eye's lit crescent is the lilac glow (a pale blue crescent on a blue face would read as tears: the Frostbyte lesson).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#F7A8C4"
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
    - ".ppp...kk...ppp."
    - ".ppp........ppp."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Wisplet.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Wisplet.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Wisplet_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Wisplet_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Wisplet_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 26 cells tall; one atlas of 512 x 512 at 8 texels a cell (123 islands). Materials: `ember` on the belly, the flame steps, the base steps, the trail and the flamelets (lit tongues rising from each block's bottom edge with a ragged crest, a white spark cell above them now and then), metal on the bail (glossy), skin on the glyph; the tip is glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, two rounds. Round 1: a belly block with a three-step flame leaning right, a thin bail and two flamelets by the base: it built and read as a flame, but the boxed silhouette sat at 0.74 against Moop (a block with a sprout on top and a spore beside it), and an eighth-stud bail vanished at distance. Round 2: a second tongue licking up to the left, the flamelets moved wide of the belly at different heights, the bail a quarter stud thick and widened past its pins, the base steps swept left: 0.64 at worst (Syrinx). Overlap 0.996 to 0.997, 342 triangles, 22 blocks, 3.25 studs (the Rare cap). Wanted for: the night's own light in the event's two weeks. Still cheap: the ember tongues are subtle on the pale body in daylight (the VFX preview's cold light brings them up); the bail is half hidden behind the flame from the three-quarter view. Status review.
