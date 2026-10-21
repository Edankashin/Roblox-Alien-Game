---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Pebblet
name: Pebblet
world: 1
tier: Common
status: review
element: Stone
height: 2.75
blocks: 12
tris: 234
bevel_width: 0.1
bevel_segments: 2
palette: ["#C4B9A6", "#5A5048", "#D27A16", "#1E1A17"]
roles: [body, second, accent, ink]
hero: Cairn
vfx: "none of its own (Common): Effects.luau's one Burst, a puff of four grit motes (B8AFA0) at the Feet every 4 s, falling; a Bob idle of 0.12 studs every 0.8 s (the hop); no light, no glow region. The rig adds the motion: the cairn wobbles, the front feet shuffle, the stone squashes on each hop"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Pebblet_sheet.svg]]"
render: "[[Pebblet_tq_cells.jpg]]"
glb: ""
overlap: [0.993, 0.994, 0.997, 0.994]
cells_render: "[[Pebblet_tq_cells.jpg]]"
idle_render: "[[Pebblet_idle.png]]"
---
# Pebblet (Pebblet), Common, World 1 Verdant

A grey-tan pebble that grew four stubby slate legs and walks, 2.75 studs to the top of its cairn: a wide, low, soft-cornered stone (the head, half of which is face) with a chipped lower-right flank, on four stone stumps splayed out past its corners, so there is air under it. On its back it balances a cairn: three smaller stones stacked and stepped off to one side, the way a hiker leaves a marker on a trail, the bottom one a wide slab so the top of the pebble steps down on the other side, and a tiny pip of a pebble balanced on the very top. A long crust of orange lichen grows low on its right flank, up from the ground line behind the leg, and a fleck of it on the cairn. Concept row in `src/shared/data/Species.luau`: "pebble with legs". Element and effect: [[Roster-Redesign]] section 2 (Stone; a puff of grit when it hops). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is a rock with a face, which is already funny, and the cairn on its back says it is going somewhere and wants to be found again. B46: its own `pebble` eyes (wide soft ovals with a long shine) and a smile with one tooth showing, the goofiest face on the meadow; the cairn wobbles on every hop and never quite falls. The Common rung on purpose: three flat colours (stone, slate, lichen orange), no glow and no light.

**Hero block.** The `Cairn`: three stacked stones and a pip on its back, leaning off to one side on a wide bottom slab, unique in Verdant; the top two stones and the pip wobble as one (`cairn`).

**Moving parts (three objects and the blink).** `cairn` (the top stones wobble), `legR` and `legL` (the front feet shuffle out of step); the plate blinks.

**Alien anatomy.** A stone that walks on four legs and carries a cairn; nothing a pet animal does.

**World motif (Verdant).** The moss cell as the cobbles of the stone motif on every block, and the lichen in the accent.

## Parts

```yaml
parts:
  # the pebble: one wide low stone, soft-cornered, the face on its front
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1.125, 0], bevel: true, material: stone}
  # a chipped flank: a wedge of the stone proud of the lower right side at the front, its facet sloping up to the back
  - {name: Chip, slot: Body, size: [0.25, 0.5, 0.75], at: [1.125, 0.75, -0.375], shape: wedge, material: stone}
  # four stone stumps at the corners, so the pebble stands with air under it; the front pair shuffles
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.125, 0.25, -0.5], mirror: x, material: stone, moves: leg, pivot: [1.125, 0.5, -0.5]}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.125, 0.25, 0.5], mirror: x, material: stone}
  # the hero: a cairn of three stones balanced on its back, stepped off to the right; the bottom stone is a wide flat slab that steps the
  # top of the pebble down on its left; the top two stones and a pip of a pebble wobble on the slab
  - {name: Cairn, slot: Body, size: [1.25, 0.25, 1], at: [0.375, 1.875, 0.125], material: stone}
  - {name: Cairn2, slot: BodyDark, size: [0.75, 0.25, 0.5], at: [0.5, 2.125, 0.125], material: stone, moves: cairn, pivot: [0.5, 2, 0.125]}
  - {name: Cairn3, slot: Body, size: [0.5, 0.25, 0.375], at: [0.625, 2.375, 0.1875], material: stone, moves: cairn, pivot: [0.5, 2, 0.125]}
  - {name: Pip, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0.5, 2.625, 0.25], material: stone, moves: cairn, pivot: [0.5, 2, 0.125]}
  # a patch of orange lichen low on the right flank, a long flat crust growing up from the ground line behind the leg, proud by an eighth
  # (Polish w1: an upright patch at head height read as an ear), and a fleck of it on the cairn's slab
  - {name: Lichen, slot: Accessory, size: [0.125, 0.25, 0.875], at: [1.0625, 0.625, 0.4375]}
  - {name: Fleck, slot: Accessory, size: [0.25, 0.125, 0.25], at: [-0.125, 2.0625, -0.125]}
```

## Face

The stone's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `pebble`, a Common design, a wide soft oval with a long shine, the eye a pebble itself. At 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, three frames). A smile with one tooth (`tooth`) and dot cheeks: the goofiest face on the meadow. In World 1 only Pebblet wears `pebble`.

```yaml
eyes:
  key: pebble
  mouth: tooth
  cheeks: dots
  plate: [1.75, 0.875]
  at: [0, 1.0625]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the cairn wobbles on its slab, the two front feet shuffle out of step in time with Effects.luau's 0.8 s hop, the stone squashes a little on each hop, the face blinks. Three objects and the blink; no flourish (that starts at Rare).

```yaml
rig:
  clips:
    cairn: [{kind: sway, amp: 6, period: 1.6, axis: z}, {kind: sway, amp: 4, period: 2.4, axis: x, phase: 0.3}]
    legR: [{kind: sway, amp: 12, period: 0.8, axis: x}]
    legL: [{kind: sway, amp: 12, period: 0.8, axis: x, phase: 0.5}]
    root: [{kind: squash, amp: 0.05, period: 0.8}]
    face: [{kind: blink, period: 4.8}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Pebblet.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Pebblet.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Pebblet_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Pebblet_idle.png]]

The concept sheet, drawn from the parts table above: [[Pebblet_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Pebblet_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (56 islands). Materials: stone on the pebble, the chip, the legs and the cairn (cobbles parted by cracks), the lichen patch plain.

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "boxiest of the roster"). The outline is stepped and chipped: the cairn's bottom stone is a wide slab offset to the right, so the pebble's top steps down on the left, and a wedge of stone is proud of the lower right flank at the front with its facet sloping to the back, a chip out of the rock on the side the three-quarter camera sees (round 1 had it on the left, where the camera never saw it); from the front the right edge steps out at the bottom and the top steps in on the left. 10 blocks (the cap of the Common band), 2.5 studs. Status review.

- 2026-10-19, World 1 roster worker, three rounds. Round 1: a stone box on four stumps with the cairn centred read as a box with a hat, and the boxed silhouette sat at 0.70 against Moop. Round 2: the legs splayed out past the body's corners and the cairn leaning off to its right, the body a warmer stone (the pale first grey read as paper), the lichen a step darker so the accent clears the body in greyscale. Round 3: no change after the side-by-side. Wanted for: a rock with a face that carries a cairn. Still cheap: it is the boxiest of the nine (the cairn and the stance are what save it); the stone cobbles read only up close. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, one round. In the band already; a pip of a pebble balanced on the cairn (2.75 studs now, the head 45 percent) and a fleck of lichen on the slab bring it to the Common cap of 12 blocks. Its own `pebble` eyes (wide ovals, a long shine) with a one-tooth smile and dot cheeks, the goofiest face on the meadow; three moving objects and the blink: the top of the cairn wobbles on its slab, the front feet shuffle out of step in time with Effects.luau's 0.8 s hop, the stone squashes on each hop. Overlap 0.992 to 0.996, 232 triangles; worst silhouette pair 0.64 (Twiglo), from 0.68. Wanted for: a rock that grins with one tooth and carries a cairn that never quite falls. Still weak: the lichen patch on the flank reads as an ear from the three-quarter view, and the body is still the squarest block in the row. Status review.
- 2026-10-21, Polish w1, one round. The lichen was an upright orange patch at head height on the flank and read as an ear: it is now a long low crust, a quarter tall and seven eighths long, growing up from the ground line behind the front leg on the right flank. 12 blocks, unchanged (the Common cap). Honest read: nothing reads as an ear; the lichen is quieter now, an orange line by the legs and the fleck on the cairn. Status review.
