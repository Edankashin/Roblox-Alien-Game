---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Radish
name: Raddis
world: 1
tier: Cosmic
status: review
element: Sun
height: 13.96
blocks: 141
tris: 1608
bevel_width: 0.125
bevel_segments: 2
palette: ["#D7265C", "#FFF0D9", "#2CC5B2", "#FFB21E", "#FFE36B", "#2A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#FFE36B", "#FF9F45", "#FFF8DC"]
hero: RingT
vfx: "to the sky: the rays, the orb, the forehead gem and the wing tips glow and step through gold, amber and white every 2 s; the halo turns once in 8 s; gold motes orbit at 1.5 studs; a ground ring of light; a sunlight trail while it hovers; the flourish is a flare and a column of light from the orb"
ride: "Hover; the rider sits on the flat front of the head top (6 by 2 studs, 10.75 studs up), in front of the crown step and the leaves"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Radish_sheet.svg]]"
render: "[[Radish_tq.jpg]]"
glb: ""
overlap: [0.997, 0.997, 0.995, 0.997]
vfx_render: "[[Radish_vfx.jpg]]"
cells_render: "[[Radish_tq_cells.jpg]]"
---
# Radish (Raddis), Cosmic, World 1 Verdant

A giant radish that hovers: a deep radish-red head 6 studs square with the house face low on it, a narrower crown step over it and a narrower bulb under it, so the red body reads as a round, then a root that tapers in five steps from red to cream down to a thin tail with a curl at its tip and two root hairs. Seven broad turquoise leaves fan out of the back of the crown, the outer pair drooping over its shoulders. The face wears the pharaoh's brow: a band of gold and turquoise cells across the forehead with the lit sun gem on it, and striped lappets down both sides of the face; cream lenticel dashes mark the radish skin on the sides. A broad collar of gold and turquoise cells stands out under the chin, narrowing to a lit pendant. Behind it turns a stepped gold sun disk with six glowing rays and a pair of spread Egyptian wings, the winged sun of Ra, and a glowing orb floats over its crown. Concept row: "radiant radish, sun disk; echo of Ra". Element: Sun (`Effects.luau`; [[Roster-Redesign]] section 2 gives the corona, the turning disk, the orbiting motes, the ring, the trail and the flare). Rules: [[Blocky-Style]].

**What makes a player want it.** It is 13.96 studs tall and 16.5 studs across the wings, nearly three avatars high: it towers over the player, and it is a mount. The awe comes from the size, the turning sun and the light; the face stays the same soft house face as Moop's, which is the point (rare means worth finding, not fierce). Loop 2 makes it read as a radish first (the leaf fan, the round red body, the white root) and a lantern not at all (loop 1's striped head sides read as lantern ribs; they are gone).

**Hero block.** The sun disk (`RingT` to `RingB` and the rays): one moving part, the `halo`, that the game turns once in 8 s, unique in Verdant.

**Moving parts (four objects).** `halo` (the ring and its rays, pivot on the disk's centre), `wingR` and `wingL` (pivots at the disk's sides, they flap), `float` (the orb, it bobs).

**Alien anatomy.** A root that hovers instead of standing, and a sun that turns behind it on nothing.

**World motif (Verdant).** The moss cell, here as the half-stud cells of the ring, the brow band, the lappets and the collar.

## Parts

```yaml
parts:
  # the radish: a wide head with the face, a crown step over it, a bulb under it, then a root that tapers in steps from red to cream to a curled tip
  - {name: Head, slot: Body, size: [6, 6, 5], at: [0, 7.75, 0], bevel: true}
  - {name: Crown, slot: Body, size: [5, 0.5, 4], at: [0, 11, 0.25]}
  - {name: Bulb, slot: Body, size: [5, 1.5, 4.5], at: [0, 4, 0], bevel: true}
  - {name: Root, slot: Body, size: [3.75, 0.75, 3.5], at: [0, 2.875, 0]}
  - {name: Root2, slot: BodyDark, size: [2.75, 0.75, 2.5], at: [0, 2.125, 0], material: wood}
  - {name: Root3, slot: BodyDark, size: [1.75, 0.5, 1.5], at: [0, 1.5, 0], material: wood}
  - {name: RootTip, slot: BodyDark, size: [1, 0.5, 1], at: [0, 1, 0], material: wood}
  - {name: RootTail, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [0, 0.5, 0]}
  - {name: RootCurl, slot: BodyDark, size: [0.5, 0.25, 0.25], at: [0.125, 0.125, 0]}
  - {name: RootHair, slot: BodyDark, size: [0.25, 0.75, 0.25], at: [1.5625, 1.875, 0], rot: [0, 0, 20], mirror: x}
  # radish skin: short cream lenticel dashes on the head's sides
  - {name: Dash, slot: BodyDark, size: [0.125, 0.125, 0.75], at: [3.0625, 9.6875, -0.75], mirror: x}
  - {name: Dash2, slot: BodyDark, size: [0.125, 0.125, 1], at: [3.0625, 8.1875, 0.75], mirror: x}
  - {name: Dash3, slot: BodyDark, size: [0.125, 0.125, 0.5], at: [3.0625, 6.4375, -0.25], mirror: x}
  # the pharaoh's brow: a band of gold and turquoise cells across the forehead, the lit sun gem on it, striped lappets framing the face
  - {name: Band, slot: Trim, size: [0.5, 0.5, 0.125], at: [0, 9, -2.5625]}
  - {name: Band1, slot: Accessory, size: [0.5, 0.5, 0.125], at: [0.5, 9, -2.5625], mirror: x}
  - {name: Band2, slot: Trim, size: [0.5, 0.5, 0.125], at: [1, 9, -2.5625], mirror: x}
  - {name: Band3, slot: Accessory, size: [0.5, 0.5, 0.125], at: [1.5, 9, -2.5625], mirror: x}
  - {name: Band4, slot: Trim, size: [0.5, 0.5, 0.125], at: [2, 9, -2.5625], mirror: x}
  - {name: GemFrame, slot: Trim, size: [1.25, 0.75, 0.125], at: [0, 9.625, -2.5625], material: metal}
  - {name: Gem, slot: Glow, size: [0.75, 0.5, 0.125], at: [0, 9.625, -2.6875]}
  - {name: Lappet, slot: Trim, size: [0.5, 0.75, 0.125], at: [2.75, 8.875, -2.5625], mirror: x}
  - {name: Lappet2, slot: Accessory, size: [0.5, 0.75, 0.125], at: [2.75, 8.125, -2.5625], mirror: x}
  - {name: Lappet3, slot: Trim, size: [0.5, 0.75, 0.125], at: [2.75, 7.375, -2.5625], mirror: x}
  - {name: Lappet4, slot: Accessory, size: [0.5, 0.75, 0.125], at: [2.75, 6.625, -2.5625], mirror: x}
  - {name: Lappet5, slot: Trim, size: [0.5, 0.75, 0.125], at: [2.75, 5.875, -2.5625], mirror: x}
  - {name: Lappet6, slot: Accessory, size: [0.5, 0.75, 0.125], at: [2.75, 5.125, -2.5625], mirror: x}
  # the broad collar: three rows of gold and turquoise cells standing out past the chin, so it shows from above, narrowing to a lit pendant
  - {name: CollarA, slot: Trim, size: [0.5, 0.5, 1], at: [0, 4.5, -2.625]}
  - {name: CollarA1, slot: Accessory, size: [0.5, 0.5, 1], at: [0.5, 4.5, -2.625], mirror: x}
  - {name: CollarA2, slot: Trim, size: [0.5, 0.5, 1], at: [1, 4.5, -2.625], mirror: x}
  - {name: CollarA3, slot: Accessory, size: [0.5, 0.5, 1], at: [1.5, 4.5, -2.625], mirror: x}
  - {name: CollarA4, slot: Trim, size: [0.5, 0.5, 1], at: [2, 4.5, -2.625], mirror: x}
  - {name: CollarB, slot: Accessory, size: [0.5, 0.5, 0.875], at: [0, 4, -2.5625]}
  - {name: CollarB1, slot: Trim, size: [0.5, 0.5, 0.875], at: [0.5, 4, -2.5625], mirror: x}
  - {name: CollarB2, slot: Accessory, size: [0.5, 0.5, 0.875], at: [1, 4, -2.5625], mirror: x}
  - {name: CollarB3, slot: Trim, size: [0.5, 0.5, 0.875], at: [1.5, 4, -2.5625], mirror: x}
  - {name: CollarC, slot: Trim, size: [0.5, 0.5, 0.75], at: [0, 3.5, -2.5]}
  - {name: CollarC1, slot: Accessory, size: [0.5, 0.5, 0.75], at: [0.5, 3.5, -2.5], mirror: x}
  - {name: CollarC2, slot: Trim, size: [0.5, 0.5, 0.75], at: [1, 3.5, -2.5], mirror: x}
  - {name: Pendant, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 3, -2.125]}
  # the radish greens: seven broad turquoise leaves fanning out of the back of the crown (a stem, a wide blade, a narrower tip), the outer pair drooping
  - {name: Leaf, slot: Accessory, size: [0.375, 0.375, 0.25], at: [0, 11.4375, 1.8125], rot: [15, 0, 0]}
  - {name: Leaf2, slot: Accessory, size: [1.5, 1.25, 0.25], at: [0, 12.1875, 2], rot: [15, 0, 0]}
  - {name: Leaf3, slot: Accessory, size: [1, 0.75, 0.25], at: [0, 13.1875, 2.25], rot: [15, 0, 0]}
  - {name: Leaf4, slot: Accessory, size: [0.5, 0.375, 0.25], at: [0, 13.75, 2.4375], rot: [15, 0, 0]}
  # Leaf top at [0, 13.906, 2.462]
  - {name: SideLeaf, slot: Accessory, size: [0.375, 0.375, 0.25], at: [0.9375, 11.4375, 1.25], rot: [0, 0, -25], mirror: x}
  - {name: SideLeaf2, slot: Accessory, size: [1.375, 1.25, 0.25], at: [1.3125, 12.1875, 1.25], rot: [0, 0, -25], mirror: x}
  - {name: SideLeaf3, slot: Accessory, size: [1, 0.75, 0.25], at: [1.75, 13.0625, 1.25], rot: [0, 0, -25], mirror: x}
  - {name: SideLeaf4, slot: Accessory, size: [0.5, 0.375, 0.25], at: [1.9375, 13.5625, 1.25], rot: [0, 0, -25], mirror: x}
  # SideLeaf top at [2.037, 13.742, 1.25]
  - {name: BackLeaf, slot: Accessory, size: [0.375, 0.375, 0.25], at: [0.6875, 11.4375, 1.8125], rot: [15, 0, -15], mirror: x}
  - {name: BackLeaf2, slot: Accessory, size: [1.125, 1, 0.25], at: [0.875, 12.0625, 2], rot: [15, 0, -15], mirror: x}
  - {name: BackLeaf3, slot: Accessory, size: [0.75, 0.75, 0.25], at: [1.0625, 12.875, 2.1875], rot: [15, 0, -15], mirror: x}
  # BackLeaf top at [1.156, 13.233, 2.3]
  - {name: OuterLeaf, slot: Accessory, size: [0.375, 0.375, 0.25], at: [1.9375, 11.0625, 0.75], rot: [0, 0, -65], mirror: x}
  - {name: OuterLeaf2, slot: Accessory, size: [1, 1, 0.25], at: [2.5625, 11.375, 0.75], rot: [0, 0, -65], mirror: x}
  - {name: OuterLeaf3, slot: Accessory, size: [0.75, 0.75, 0.25], at: [3.3125, 11.75, 0.75], rot: [0, 0, -65], mirror: x}
  # OuterLeaf top at [3.676, 11.898, 0.75]
  # the floating accessory: a sun orb over the crown, in front of the leaves
  - {name: Orb, slot: Glow, size: [1, 1, 1], at: [0, 12.5, 0.25], shape: ico1, moves: float, pivot: [0, 12.5, 0.25]}
  # the sun disk: a stepped ring of half-stud cells behind the head, turning on its centre
  - {name: RingT, slot: Trim, size: [3, 0.5, 0.5], at: [0, 12, 2.875], moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingT1, slot: Trim, size: [5, 0.5, 0.5], at: [0, 11.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingT2, slot: Trim, size: [2, 0.5, 0.5], at: [2, 11, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingT3, slot: Trim, size: [1.5, 0.5, 0.5], at: [2.75, 10.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingT4, slot: Trim, size: [1.5, 0.5, 0.5], at: [3.25, 10, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingT5, slot: Trim, size: [1, 0.5, 0.5], at: [3.5, 9.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingSide, slot: Trim, size: [1, 3, 0.5], at: [4, 7.75, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingB5, slot: Trim, size: [1, 0.5, 0.5], at: [3.5, 6, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingB4, slot: Trim, size: [1.5, 0.5, 0.5], at: [3.25, 5.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingB3, slot: Trim, size: [1.5, 0.5, 0.5], at: [2.75, 5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingB2, slot: Trim, size: [2, 0.5, 0.5], at: [2, 4.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingB1, slot: Trim, size: [5, 0.5, 0.5], at: [0, 4, 2.875], moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  - {name: RingB, slot: Trim, size: [3, 0.5, 0.5], at: [0, 3.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875], material: metal}
  # six rays, stepped and tapering, colour-cycled glow
  - {name: RayN, slot: Glow, size: [1.5, 0.5, 0.5], at: [0, 12.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayN2, slot: Glow, size: [1, 0.5, 0.5], at: [0, 13, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayN3, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 13.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayS, slot: Glow, size: [1.5, 0.5, 0.5], at: [0, 3, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayS2, slot: Glow, size: [1, 0.5, 0.5], at: [0, 2.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayS3, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 2, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayNE, slot: Glow, size: [0.75, 0.75, 0.5], at: [3.625, 11.375, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayNE2, slot: Glow, size: [0.5, 0.5, 0.5], at: [4.125, 11.875, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayNE3, slot: Glow, size: [0.25, 0.25, 0.5], at: [4.375, 12.125, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RaySE, slot: Glow, size: [0.75, 0.75, 0.5], at: [3.625, 4.125, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RaySE2, slot: Glow, size: [0.5, 0.5, 0.5], at: [4.125, 3.625, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RaySE3, slot: Glow, size: [0.25, 0.25, 0.5], at: [4.375, 3.375, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  # the wings of the winged sun: four feather rows behind the disk, lit tips; each wing turns on its root to flap
  - {name: Wing, slot: Trim, size: [4, 0.5, 0.25], at: [6.25, 10.25, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: Wing2, slot: Accessory, size: [3.75, 0.75, 0.25], at: [6.125, 9.625, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: Wing3, slot: Body, size: [3.25, 0.75, 0.25], at: [5.875, 8.875, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: Wing4, slot: Accessory, size: [2.5, 0.75, 0.25], at: [5.5, 8.125, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: WingTip, slot: Glow, size: [0.25, 0.75, 0.25], at: [8.125, 9.625, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: WingTip2, slot: Glow, size: [0.25, 0.75, 0.25], at: [7.625, 8.875, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: WingTip3, slot: Glow, size: [0.25, 0.75, 0.25], at: [6.875, 8.125, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
```

## Face

The house face, 16 cells across the 6-stud head (0.375 studs a cell, so 16 rows for the square front). The eyes sit low (rows 7 to 12); the brow band and the gem cover rows 2 to 5, the lappets the two outer columns.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9DBB"
  rows:
    - "................"
    - "................"
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
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Radish.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Radish.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Radish_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Radish_vfx.jpg]]

The concept sheet, drawn from the parts table above: [[Radish_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Radish_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Radish_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.375 studs (2.7 a stud), 37 cells tall; one atlas of 512 x 1024 at 8 texels a cell (704 islands). Materials: wood on the root steps (fibre rows), metal on the sun disk and the gem frame, skin elsewhere.

![[Radish_tq_cells.jpg]]

![[Radish_vfx_cells.jpg]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: it read as a red box with wings (a short root, leaves like little antlers, an opaque white light column). Round 2: a four-step root taper to a thin tail with root hairs, three tall leaf blades, the upper body raised half a stud (13.75 studs, head 40 percent). Round 3: the preview's turning disk lit, a corona light, a wider translucent column. Overlap 0.996 to 0.997, 1,424 triangles, four moving objects. Wanted for: 2.8 avatars tall and 16.5 studs across the wings, a turning winged sun, a mount. Still cheap: the head front is a big flat red plane above the face, the collar hides under the head's overhang from above, and the wing rows read as flags from the side. Next: a stepped brow band or headdress edge across the top of the face, feather tips stepped at the wing ends, and the face at 32 cells for close-ups. Status review.
- 2026-10-17, loop 2 worker, three rounds. Round 1: the brow band, the gem and the striped lappets frame the face and break up the red plane; the collar stands out past the chin so it shows from above; the striped head sides (they read as lantern ribs) are gone. Round 2: the leaves read as celery sticks (a cream midrib split each one), and the box still read as a lantern; the root was shortened so the leaves could grow. Round 3: a 6-stud head between a crown step and a bulb, a five-step root from red to cream to a curled tip, seven broad leaves with the outer pair drooping; the preview drops a spark that sat on its cheek. Overlap 0.995 to 0.997, 1,892 triangles, 141 blocks, 13.96 studs. Wanted for: nearly three avatars of radish behind a turning winged sun, a mount. Still cheap: from the side the head is still a tall box; the cream dashes are faint; 16 face cells over 6 studs are big pixels in a close-up. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). At the face cell (0.375 studs) the 6-stud head is 16 cells across, chunky up close and one surface with the face; the root's grain reads as a radish's fibres. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
