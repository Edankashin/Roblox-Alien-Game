---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Nebulyn
name: Cosmoo
world: 1
tier: Legendary
status: review
element: Star
height: 5.625
blocks: 60
tris: 752
bevel_width: 0.1875
bevel_segments: 2
palette: ["#6B4EC2", "#2E2166", "#E66BD2", "#FFD98A", "#FFF3B0", "#100A26"]
roles: [body, second, accent, trim, glow, ink]
hero: Tail
vfx: "touches the ground (Legendary): star cells on the cloud and along the tail glow cream; small stars orbit the body a stud out and a ground ring of starlight in the tier gold sits under it; a tail of stars streams behind it (Effects.luau's Star emitter and Trail from the tail, wisp motes off the body at 10 a second, sparkles at the eyes, a violet 8F6BFF light pulsing every 3.4 s); it hovers 0.45 studs on a 3.2 s bob, drifting sideways; the flourish is a twinkle burst"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Nebulyn_sheet.svg]]"
render: "[[Nebulyn_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.994, 0.995, 0.997]
vfx_render: "[[Nebulyn_vfx_cells.jpg]]"
cells_render: "[[Nebulyn_tq_cells.jpg]]"
---
# Nebulyn (Cosmoo), Legendary, World 1 Verdant, the Haunted Nebula event

A small nebula with a face: a violet cloud the size of a player, built as a big soft core block with puffs stepping off its top, sides, back and underside (three of them magenta, where the nebula glows pink), star cells lit cream all over it, two bright house eyes with cream crescents, and a tail of cloud curling up and back behind it in five tapering steps with stars along it, ending in a big star; two more stars float free beyond the tip and one has fallen to the grass beneath. Two gold constellations are drawn on its flanks: stars joined by thin gold lines that step across the cloud. Concept row in `src/shared/data/Species.luau`: "a small nebula cloud with two bright eyes and a trailing tail of stars". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`: the event track's last reward, through the quest only). Element and effect: [[Roster-Redesign]] section 2 (Star; a tail of stars trails behind it, small stars orbit at 1 stud, a ground ring of starlight; `Effects.luau` calls the element Nebula). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the event's prize and the one that cannot be caught, only earned: 25 event catches for a piece of the night sky that follows you home, taller than you with its tail up, its stars orbiting and a ring of starlight under it. The Legendary rung: 60 blocks, accessories (the constellations), emissive cells (the stars), the effects touching the ground (the ring, and the star that fell).

**Hero block.** The `Tail`, a tail of cloud curling up behind it in five steps with stars along it and a star at its tip, unique in Verdant (Vixa's tail is a brush, Glim's bulb curls up in two steps).

**Alien anatomy.** A cloud that has eyes and a tail, lit from inside by stars, with constellations on its skin; four moving objects: the tail (its five steps, their stars and the tip star) and three floating stars (`float`: two past the tip and one on the ground).

**World motif (Verdant).** The moss cell as the quarter-stud steps of the puffs and the tail.

**Event palette (Haunted Nebula).** Deep violet over indigo with a magenta accent, pale gold trim and a star-cream glow: the deep end of the event's range (Wispkin the cold blue, Grin the ghost white and pumpkin orange).

## Parts

```yaml
parts:
  # the core of the cloud: one big soft block in nebula cells, the face on its front
  - {name: Core, slot: Body, size: [2.5, 2.5, 2.5], at: [0, 2.5, 0], bevel: true, material: nebula}
  # puffs stepping off the core: the top, the sides, the back, the underside and a chin, three of them magenta
  - {name: PuffTop, slot: Body, size: [1.5, 0.75, 1.5], at: [-0.5, 4.125, 0.25], material: nebula}
  - {name: PuffTop2, slot: Body, size: [1, 0.5, 1], at: [0.75, 4, -0.5], material: nebula}
  - {name: PuffTop3, slot: Body, size: [0.75, 0.5, 0.75], at: [-0.375, 4.75, 0.125], material: nebula}
  - {name: PuffFront, slot: Body, size: [0.75, 0.5, 0.5], at: [-0.875, 4, -1], material: nebula}
  - {name: PuffR, slot: Body, size: [0.75, 1.5, 1.5], at: [1.625, 2.5, 0.25], material: nebula}
  - {name: PuffR2, slot: Body, size: [0.5, 0.5, 0.75], at: [2.25, 3, 0.625], material: nebula}
  - {name: PuffL, slot: Body, size: [0.5, 1.25, 1.25], at: [-1.5, 2.875, -0.125], material: nebula}
  - {name: PuffBack, slot: Body, size: [1.75, 1.5, 0.75], at: [0.125, 2.625, 1.625], material: nebula}
  - {name: PuffUnder, slot: Body, size: [1.75, 0.5, 1.75], at: [-0.125, 1, 0.25], material: nebula}
  - {name: PuffUnder2, slot: Body, size: [1, 0.25, 1], at: [0.25, 0.625, 0.5], material: nebula}
  - {name: Chin, slot: Body, size: [1.5, 0.375, 0.75], at: [0.25, 1.0625, -1], material: nebula}
  - {name: Pink, slot: Accessory, size: [1, 0.75, 1], at: [1, 3.875, 0.75], material: nebula}
  - {name: Pink2, slot: Accessory, size: [0.75, 0.5, 0.75], at: [-1.375, 1.75, 0.625], material: nebula}
  - {name: Pink3, slot: Accessory, size: [0.5, 0.5, 0.5], at: [1.75, 1.5, -0.5], material: nebula}
  # star cells: lit quarter-stud cubes half sunk into the cloud's faces
  - {name: Star, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.25, 3.5, -0.75]}
  - {name: Star2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.25, 3.5, 0.75]}
  - {name: Star3, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 3.75, -0.875]}
  - {name: Star4, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.75, 1.25, -0.75]}
  - {name: Star5, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 2.25, 0.25]}
  - {name: Star6, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 4.5, 0.75]}
  - {name: Star7, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.25, 4.125, -0.25]}
  - {name: Star8, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.25, 4, -0.5]}
  - {name: Star9, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 2.5, 2]}
  - {name: Star10, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.5, 3.25, 2]}
  - {name: Star11, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.5, 0.75, 0]}
  - {name: Star12, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.5, 3.875, 0.75]}
  - {name: Star13, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.75, 1.75, 0.5]}
  - {name: Star14, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 5, 0.25]}
  - {name: Star15, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 0.875, -1.375]}
  - {name: Star16, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 0.5, 0.75]}
  - {name: Star17, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.25, 3.375, 1.625]}
  # the constellations: stars joined by thin gold lines stepping across the right puff and the left puff
  - {name: ConStar, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 2.5, -0.25]}
  - {name: ConStar2, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 2, 0.25]}
  - {name: ConStar3, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 2.5, 0.75]}
  - {name: ConLine, slot: Trim, size: [0.25, 0.5, 0.125], at: [2, 2.25, -0.3125]}
  - {name: ConLine2, slot: Trim, size: [0.25, 0.125, 0.5], at: [2, 2.0625, 0]}
  - {name: ConLine3, slot: Trim, size: [0.25, 0.125, 0.5], at: [2, 2.0625, 0.5]}
  - {name: ConLine4, slot: Trim, size: [0.25, 0.5, 0.125], at: [2, 2.25, 0.6875]}
  - {name: ConStarL, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.75, 3.25, -0.5]}
  - {name: ConStarL2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.75, 2.5, 0]}
  - {name: ConLineL, slot: Trim, size: [0.25, 0.75, 0.125], at: [-1.75, 2.875, -0.5625]}
  - {name: ConLineL2, slot: Trim, size: [0.25, 0.125, 0.5], at: [-1.75, 2.5625, -0.25]}
  # the hero: a tail of cloud curling up and back in five tapering steps, stars along it and a big star at its tip (one moving part)
  - {name: Tail, slot: Body, size: [1.5, 1.25, 1], at: [0.25, 1.875, 2.5], material: nebula, moves: tail, pivot: [0, 2, 1.25]}
  - {name: Tail2, slot: Body, size: [1.25, 1, 1], at: [0.625, 2.5, 3.5], material: nebula, moves: tail, pivot: [0, 2, 1.25]}
  - {name: Tail3, slot: Body, size: [1, 0.75, 0.75], at: [1, 3.125, 4.375], material: nebula, moves: tail, pivot: [0, 2, 1.25]}
  - {name: Tail4, slot: Body, size: [0.75, 0.5, 0.5], at: [1.375, 3.75, 5], material: nebula, moves: tail, pivot: [0, 2, 1.25]}
  - {name: Tail5, slot: Body, size: [0.5, 0.5, 0.5], at: [1.75, 4.25, 5.5], material: nebula, moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar, slot: Glow, size: [0.25, 0.25, 0.25], at: [1, 2.25, 2.5], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 2.5, 2.25], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.25, 2.75, 3.5], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar4, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.25, 3, 3.75], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar5, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.5, 3.25, 4.5], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar6, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.75, 3.5, 4.25], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar7, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.75, 4, 5], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TailStar8, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 4.5, 5.5], moves: tail, pivot: [0, 2, 1.25]}
  - {name: TipStar, slot: Glow, size: [0.5, 0.5, 0.5], at: [2, 4.75, 5.875], shape: ico1, moves: tail, pivot: [0, 2, 1.25]}
  # three stars floating free: two past the tip of the tail, one fallen to the grass beneath it
  - {name: Float, slot: Glow, size: [0.375, 0.375, 0.375], at: [2.3125, 5.3125, 6.3125], shape: ico1, moves: float, pivot: [2.3125, 5.3125, 6.3125]}
  - {name: Float2, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.5, 5.5, 6.75], shape: ico1, moves: float, pivot: [1.5, 5.5, 6.75]}
  - {name: Fallen, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 0.125, 3.5], shape: ico1, moves: float, pivot: [0.5, 0.125, 3.5]}
```

## Face

The house face on the core's front: 16 cells across the 2.5-stud block (0.15625 a cell), 16 rows for the square front. Two bright eyes: the house stamp with the lit crescent in the star cream, which is the brightest crescent in Verdant on the darkest head; the top two rows keep the nebula motif (its billows and a star or two), the rest of the front is plain cells so nothing crowds the eyes.

```yaml
face:
  host: Core
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#F2A0E0"
  rows:
    - "................"
    - "................"
    - "................"
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
    - "................"
    - "................"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Nebulyn.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Nebulyn.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Nebulyn_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Nebulyn_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Nebulyn_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.156 studs (6.4 a stud), 36 cells tall; one atlas of 512 x 1024 at 8 texels a cell (312 islands). Materials: `nebula` on the core, every puff and the tail (billows of light and shade, a dust lane drifting on the diagonal, a star cell in forty in the cream glow with a twinkle round one in three), skin on the gold constellation lines (glossy trim); the stars are glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, one round. Built as drawn: a core with puffs stepping off it on the nebula motif, sixteen star cells, two gold constellations on the side puffs, and the tail of five steps curling up behind with eight stars along it, a big one at its tip, two floating past it and one fallen to the grass. The VFX preview is the Legendary set: the tail's stars lit, ten stars orbiting a stud out, a gold ring of starlight on the ground. Overlap 0.994 to 0.997, 752 triangles, 60 blocks (the floor of the Legendary band), 5.63 studs; the boxed silhouette's worst pair is Buzzik at 0.67. Wanted for: the event's prize, a piece of the night sky with a tail. Still cheap: the core still reads as a cube from the front (the puffs are on its top, sides and underside); the constellations are small gold marks at the review size; the tail's eight studs of depth make the body a third of the frame. Status review.
