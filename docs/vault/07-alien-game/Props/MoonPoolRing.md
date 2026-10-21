---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: MoonPoolRing
name: Moon pool ring
world: 1
region: Forest
kind: prop
status: build
height: 2.75
blocks: 34
tris: 408
budget: 900
collision: Precise
collision_slots: {Accessory: None, Trim: None, Glow: None}
footprint: [14.5, 14.75, 2.75]
palette: ["#6E69AE", "#4C4894", "#2E8A78", "#3BA88A", "#FFB3E6"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/MoonPoolRing/MoonPoolRing.glb"
---
# Moon pool ring (World 1 Verdant, Starhollow Forest)

The ring round the glowing moon pool: twelve mossy lavender-grey stones of their own sizes round a circle about 13 studs across, two stacked for height, five lily pads floating inside with pink glowing blooms and flecks, and a glint on two stones.

- **Cells**: the stones in `stone`, their tops in `moss`; plain cells on the pads; the blooms `glow`
- **The water is the world worker's part**: a disc of GlowWater (the tile) or Neon glass about 12.5 studs across whose top is at 0.5 studs over the ring's foot, so the pads (their underside at 0.5) float on it; a light shaft over it is theirs too
- **Collision**: `Precise` on the stones, the one way a ring stays open (a box or a hull of one MeshPart round a pool would cover the pool, as for the Shrine); moss, pads and blooms none
- **The reference**: the glowing moon pool ringed with mossy stones and lily pads in ZPLYSA3uR (10 to 14 s)
- **Footprint**: 14.5 x 14.75 x 2.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 900 triangles (the estimate before culling is 408); collision `Precise` in `src/shared/data/Props.luau` with `Accessory` None, `Trim` None, `Glow` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # twelve stones round the pool, two stacked
  - {name: Stone, slot: Body, size: [2.5, 1.25, 1.5], at: [0, 0.625, -6.5], material: stone}
  - {name: Stone2, slot: Body, size: [2, 1.5, 1.5], at: [3.5, 0.75, -5.75], material: stone}
  - {name: Stone3, slot: Body, size: [1.5, 1, 2], at: [5.75, 0.5, -3.25], material: stone}
  - {name: Stone4, slot: Body, size: [1.5, 1.75, 2.5], at: [6.5, 0.875, 0.25], material: stone}
  - {name: Stone5, slot: Body, size: [2, 1.25, 1.5], at: [5.5, 0.625, 3.75], material: stone}
  - {name: Stone6, slot: Body, size: [2.5, 1.5, 1.5], at: [2.75, 0.75, 6], material: stone}
  - {name: Stone7, slot: Body, size: [2, 1, 1.5], at: [-0.75, 0.5, 6.75], material: stone}
  - {name: Stone8, slot: Body, size: [2, 1.75, 2], at: [-4.25, 0.875, 5.25], material: stone}
  - {name: Stone9, slot: Body, size: [1.5, 1.25, 2.5], at: [-6.25, 0.625, 2], material: stone}
  - {name: Stone10, slot: Body, size: [1.5, 1.5, 2], at: [-6.5, 0.75, -1.75], material: stone}
  - {name: Stone11, slot: Body, size: [2, 1.25, 2], at: [-4.75, 0.625, -4.75], material: stone}
  - {name: Stone12, slot: Body, size: [1.5, 0.75, 1.5], at: [-2.5, 0.375, -6.25], material: stone}
  - {name: Cap, slot: Body, size: [1, 0.75, 1.5], at: [6.5, 2.125, 0.25], material: stone}
  - {name: Cap2, slot: Body, size: [1.25, 0.75, 1], at: [-4.25, 2.125, 5.25], material: stone}
  # moss on two stones in three
  - {name: Moss, slot: Accessory, size: [2, 0.25, 1], at: [0, 1.375, -6.5], material: moss}
  - {name: Moss2, slot: Accessory, size: [1.5, 0.25, 1], at: [3.5, 1.625, -5.75], material: moss}
  - {name: Moss4, slot: Accessory, size: [1, 0.25, 2], at: [6.5, 1.875, 0.25], material: moss}
  - {name: Moss5, slot: Accessory, size: [1.5, 0.25, 1], at: [5.5, 1.375, 3.75], material: moss}
  - {name: Moss7, slot: Accessory, size: [1.5, 0.25, 1], at: [-0.75, 1.125, 6.75], material: moss}
  - {name: Moss8, slot: Accessory, size: [1.5, 0.25, 1.5], at: [-4.25, 1.875, 5.25], material: moss}
  - {name: Moss10, slot: Accessory, size: [1, 0.25, 1.5], at: [-6.5, 1.625, -1.75], material: moss}
  - {name: Moss11, slot: Accessory, size: [1.5, 0.25, 1.5], at: [-4.75, 1.375, -4.75], material: moss}
  # lily pads floating at 0.5 studs, the water's top
  - {name: Pad, slot: Trim, size: [1.5, 0.125, 1.25], at: [-1.75, 0.5625, -2.375]}
  - {name: Pad2, slot: Trim, size: [1.25, 0.125, 1], at: [2.375, 0.5625, 1.5]}
  - {name: Pad3, slot: Trim, size: [1, 0.125, 1.25], at: [-2.5, 0.5625, 2.375]}
  - {name: Pad4, slot: Trim, size: [1.25, 0.125, 1.25], at: [1.375, 0.5625, -3.125]}
  - {name: Pad5, slot: Trim, size: [0.75, 0.125, 0.75], at: [3.875, 0.5625, -1.125]}
  # pink blooms, flecks and glints
  - {name: Bloom, slot: Glow, size: [0.5, 0.25, 0.5], at: [-1.5, 0.75, -2.25]}
  - {name: Bloom2, slot: Glow, size: [0.375, 0.25, 0.375], at: [2.4375, 0.75, 1.4375]}
  - {name: Bloom3, slot: Glow, size: [0.5, 0.375, 0.5], at: [1.375, 0.8125, -3.125]}
  - {name: Fleck, slot: Glow, size: [0.25, 0.125, 0.25], at: [-2.625, 0.6875, 2.125]}
  - {name: Fleck2, slot: Glow, size: [0.25, 0.125, 0.25], at: [3.875, 0.6875, -1.125]}
  - {name: Glint, slot: Glow, size: [0.25, 0.25, 0.25], at: [6.375, 2.625, -0.125]}
  - {name: Glint2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.875, 1.125, 6.625]}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
