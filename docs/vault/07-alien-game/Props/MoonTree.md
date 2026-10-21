---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: MoonTree
name: Moon tree
world: 1
region: Forest
kind: prop
status: build
height: 19
blocks: 32
tris: 384
budget: 700
collision: Box
collision_slots: {Glow: None, Trim: None}
footprint: [16, 14, 19]
palette: ["#4752C4", "#3F2878", "#2A8A94", "#CDC3F2", "#A6E8FF"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/MoonTree/MoonTree.glb"
---
# Moon tree (World 1 Verdant, Starhollow Forest)

Starhollow's everyday tree, taller than the meadow oak: a violet bark trunk on root flares and two branches, a broad stepped indigo crown with teal clumps breaking its box on every side, pale lavender shelf fungus on the trunk, and light dripping from the crown's edge: eight sky-blue drips, two ending in a bead. The canopy's underside is at 11 to 12 studs, so the path runs under it.

- **Cells**: the trunk, roots and branches in `wood`; the crown and clumps in `moss` (the teal accent as the sprig cell in the indigo); the drips `glow` (Neon in the game: the light the scene is lit by)
- **The reference**: the tall dark-trunked trees of the forest TikTok (ZPLYSA3uR, 5 to 9 s), with the falling light under the canopy; the drips are the still part of that light, the falling streaks are the world worker's particles
- **Collision**: the trunk (BodyDark) and the crown (Body, Accessory) box apart; the drips and the shelves never collide
- **Footprint**: 16 x 14 x 19 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 700 triangles (the estimate before culling is 384); collision `Box` in `src/shared/data/Props.luau` with `Glow` None, `Trim` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # trunk, roots and branches: violet bark in grain rows
  - {name: Trunk, slot: BodyDark, size: [2, 12.5, 2], at: [0, 6.25, 0], material: wood}
  - {name: TrunkTop, slot: BodyDark, size: [1.5, 2.5, 1.5], at: [0.25, 13.75, 0], material: wood}
  - {name: Root, slot: BodyDark, size: [1, 1, 1], at: [1.5, 0.5, 0], mirror: x, material: wood}
  - {name: RootFront, slot: BodyDark, size: [1, 0.75, 1], at: [0, 0.375, -1.5], material: wood}
  - {name: RootBack, slot: BodyDark, size: [1, 0.5, 0.75], at: [-0.25, 0.25, 1.375], material: wood}
  - {name: Branch, slot: BodyDark, size: [2.5, 0.75, 0.75], at: [2.0625, 10.125, 0], rot: [0, 0, 20], material: wood}
  - {name: BranchL, slot: BodyDark, size: [0.75, 0.75, 2.25], at: [-0.5, 10.5, -1.6875], rot: [-18, 0, 0], material: wood}
  # the crown: four indigo steps
  - {name: Crown, slot: Body, size: [12, 2.5, 11], at: [0, 13.25, 0], material: moss}
  - {name: CrownMid, slot: Body, size: [9, 2, 8.5], at: [0.5, 15.5, 0.25], material: moss}
  - {name: CrownTop, slot: Body, size: [5.5, 1.5, 5], at: [-0.25, 17.25, -0.5], material: moss}
  - {name: CrownCap, slot: Body, size: [2.5, 1, 2.5], at: [0.75, 18.5, 0.25], material: moss}
  # teal clumps breaking the box
  - {name: ClumpR, slot: Accessory, size: [3, 2, 4], at: [6.5, 12.5, -1], material: moss}
  - {name: ClumpL, slot: Accessory, size: [3, 2.5, 3.5], at: [-6.5, 13.75, 1.25], material: moss}
  - {name: ClumpFront, slot: Accessory, size: [4, 2, 2], at: [-1, 12.5, -6], material: moss}
  - {name: ClumpBack, slot: Accessory, size: [3.5, 2, 2], at: [1.75, 14.5, 6], material: moss}
  - {name: ClumpHigh, slot: Accessory, size: [3, 1.5, 3], at: [-3, 16.25, 2], material: moss}
  - {name: ClumpLow, slot: Accessory, size: [3, 1.5, 3], at: [-3.5, 11.75, 4.5], material: moss}
  # light dripping from the crown's edge
  - {name: Drip, slot: Glow, size: [0.25, 1.5, 0.25], at: [6.125, 10.75, -2.125]}
  - {name: Drip2, slot: Glow, size: [0.25, 0.75, 0.25], at: [7.375, 11.125, 0.375]}
  - {name: Drip3, slot: Glow, size: [0.25, 1.25, 0.25], at: [-1.875, 10.875, -6.375]}
  - {name: Drip4, slot: Glow, size: [0.25, 2, 0.25], at: [0.625, 10.5, -6.625]}
  - {name: Drip5, slot: Glow, size: [0.25, 1, 0.25], at: [-5.625, 12, 2.375]}
  - {name: Drip6, slot: Glow, size: [0.25, 1.5, 0.25], at: [-4.375, 10.25, 5.625]}
  - {name: Drip7, slot: Glow, size: [0.25, 1, 0.25], at: [4.875, 11.5, 4.125]}
  - {name: Drip8, slot: Glow, size: [0.25, 1.75, 0.25], at: [-5.125, 11.125, -4.375]}
  - {name: Bead, slot: Glow, size: [0.5, 0.5, 0.5], at: [0.625, 9.25, -6.625]}
  - {name: Bead2, slot: Glow, size: [0.5, 0.5, 0.5], at: [-5.125, 10, -4.375]}
  # shelf fungus on the trunk
  - {name: Shelf, slot: Trim, size: [1.25, 0.25, 0.75], at: [1.625, 4.125, -0.375]}
  - {name: Shelf2, slot: Trim, size: [0.75, 0.25, 1], at: [-1.375, 6.125, -0.5]}
  - {name: Shelf3, slot: Trim, size: [1, 0.25, 0.75], at: [0.25, 3.125, -1.375]}
  - {name: ShelfTop, slot: Trim, size: [0.75, 0.25, 0.5], at: [0.375, 3.375, -1.25]}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
