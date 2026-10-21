---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: StarIsland
name: Star island
world: 1
region: Forest
kind: prop
status: build
height: 22.5
blocks: 44
tris: 528
budget: 1400
collision: Hull
collision_slots: {Glow: None, Accessory: None}
footprint: [24, 22, 22.5]
palette: ["#2E7F76", "#4C4894", "#7FD2FF", "#CDC3F2", "#EEF6FF"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/StarIsland/StarIsland.glb"
---
# Star island (World 1 Verdant, Starhollow Forest)

Starhollow's landmark, the floating island seen from everywhere in the forest: a grassy top on a stepped indigo rock that narrows to a point, with chunks breaking its outline; a white halo arch of light on a pale plinth with an orb inside it; light dripping from every ledge of its underside; and a little stream running to a stone spout at its front, where the waterfall leaves it.

- **Cells**: the top in `grass` (its sides show the rock colour under a teal fringe), the bushes in `moss`, the rock in `stone`, the plinth and spout in pale `stone`, the stream in `water`; the arch, orb and drips `glow`
- **Floating**: the note stands it on y = 0 (the drip under its tip); the world worker lifts it into the sky over the forest, about 40 to 60 studs up, and hangs the waterfall (its own part, with particles) from the spout's front at x = -5, z = -12
- **The reference**: the floating island with a glowing halo arch and a waterfall in ZPLYSA3uR (0 to 4 s and 27 to 30 s); ours has its own shape and an orb in the arch
- **Atlas**: 4 texels a cell (a landmark too big to fit 1024 at 8)
- **Collision**: Hull on the rock and the top (nothing reaches it today; a later jump pad would land on the grass); the light and the water never collide
- **Footprint**: 24 x 22 x 22.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 1400 triangles (the estimate before culling is 528); collision `Hull` in `src/shared/data/Props.luau` with `Glow` None, `Accessory` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the rock under the top's grassy edge: stepped layers narrowing to a tip, chunks breaking the outline
  - {name: Layer2, slot: BodyDark, size: [18, 2, 16], at: [0, 10, -0.5], material: stone}
  - {name: Layer3, slot: BodyDark, size: [13, 2, 12], at: [0.5, 8, 0], material: stone}
  - {name: Layer4, slot: BodyDark, size: [8, 2, 7], at: [-0.5, 6, -0.5], material: stone}
  - {name: Layer5, slot: BodyDark, size: [4, 2, 4], at: [0.5, 4, 0], material: stone}
  - {name: Tip, slot: BodyDark, size: [2, 1.5, 2], at: [0, 2.25, 0], material: stone}
  - {name: ChunkR, slot: BodyDark, size: [2, 2.5, 4], at: [10, 9.75, 3], material: stone}
  - {name: ChunkL, slot: BodyDark, size: [2, 2, 4], at: [-10, 10, -4], material: stone}
  - {name: ChunkBack, slot: BodyDark, size: [5, 2, 2], at: [-3.5, 10, 8.5], material: stone}
  - {name: ChunkLow, slot: BodyDark, size: [3, 2, 3], at: [5.5, 7, -4.5], material: stone}
  # the grassy top, a knoll and three bushes
  - {name: Grass, slot: Body, size: [18, 3, 16], at: [0, 12.5, -0.5], material: grass}
  - {name: GrassWest, slot: Body, size: [3, 3, 20], at: [-10.5, 12.5, 0], material: grass}
  - {name: GrassEast, slot: Body, size: [3, 3, 20], at: [10.5, 12.5, 0], material: grass}
  - {name: GrassNorth, slot: Body, size: [18, 3, 1.5], at: [0, 12.5, 8.25], material: grass}
  - {name: GrassSouth, slot: Body, size: [18, 3, 1.5], at: [0, 12.5, -9.25], material: grass}
  - {name: Knoll, slot: Body, size: [7, 1, 6], at: [4.5, 14.5, 4], material: grass}
  - {name: Bush, slot: Body, size: [3, 2, 3], at: [8.5, 15, -5.5], material: moss}
  - {name: Bush2, slot: Body, size: [2.5, 1.5, 2.5], at: [-8.5, 14.75, 6.5], material: moss}
  - {name: Bush3, slot: Body, size: [2, 1.5, 2], at: [6, 15.75, 5.5], material: moss}
  # the pale plinth under the arch, its step, and the spout
  - {name: Plinth, slot: Trim, size: [6, 0.5, 3], at: [-1, 14.25, 4], material: stone}
  - {name: Step, slot: Trim, size: [4, 0.25, 1], at: [-1, 14.125, 2], material: stone}
  - {name: Spout, slot: Trim, size: [3, 1, 1.5], at: [-5, 13, -10.75], material: stone}
  # the halo arch of light and its orb
  - {name: Post, slot: Glow, size: [1, 6, 1], at: [-4.5, 17.5, 4]}
  - {name: PostR, slot: Glow, size: [1, 6, 1], at: [2.5, 17.5, 4]}
  - {name: Shoulder, slot: Glow, size: [1, 1, 1], at: [-3.5, 21, 4]}
  - {name: ShoulderR, slot: Glow, size: [1, 1, 1], at: [1.5, 21, 4]}
  - {name: Crown, slot: Glow, size: [4, 1, 1], at: [-1, 22, 4]}
  - {name: Orb, slot: Glow, size: [1, 1, 1], at: [-1, 15.5, 4]}
  # the stream to the spout, and the start of the fall
  - {name: Stream, slot: Accessory, size: [2, 0.25, 5], at: [-5, 14.125, -7.5], material: water}
  - {name: Lip, slot: Accessory, size: [2, 0.25, 1.5], at: [-5, 13.625, -10.75], material: water}
  - {name: Fall, slot: Accessory, size: [2, 1.5, 0.5], at: [-5, 12.75, -11.75], material: water}
  # light dripping from every ledge
  - {name: Drip, slot: Glow, size: [0.25, 1.5, 0.25], at: [0.125, 0.75, 0.125]}
  - {name: Drip2, slot: Glow, size: [0.25, 2, 0.25], at: [2.125, 2, -1.875]}
  - {name: Drip3, slot: Glow, size: [0.25, 1.5, 0.25], at: [-1.125, 2.25, 1.625]}
  - {name: Drip4, slot: Glow, size: [0.25, 2.5, 0.25], at: [4.875, 5.75, 3.875]}
  - {name: Drip5, slot: Glow, size: [0.25, 2, 0.25], at: [-4.375, 4, -3.875]}
  - {name: Drip6, slot: Glow, size: [0.25, 2.5, 0.25], at: [6.375, 4.75, -5.625]}
  - {name: Drip7, slot: Glow, size: [0.25, 2.5, 0.25], at: [-6.875, 7.75, 6.125]}
  - {name: Drip8, slot: Glow, size: [0.25, 2, 0.25], at: [8.875, 8, 1.875]}
  - {name: Drip9, slot: Glow, size: [0.25, 3.5, 0.25], at: [-8.375, 7.25, -7.875]}
  - {name: Drip10, slot: Glow, size: [0.25, 2.5, 0.25], at: [3.125, 9.75, 8.125]}
  - {name: Drip11, slot: Glow, size: [0.25, 2, 0.25], at: [-2.125, 10, -9.625]}
  - {name: Drip12, slot: Glow, size: [0.25, 2.5, 0.25], at: [10.875, 9.75, -8.625]}
  - {name: Bead, slot: Glow, size: [0.5, 0.5, 0.5], at: [6.375, 3.25, -5.625]}
  - {name: Bead2, slot: Glow, size: [0.5, 0.5, 0.5], at: [-8.375, 5.25, -7.875]}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
