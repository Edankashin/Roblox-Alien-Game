---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: MeadowTreeB
name: Meadow tall tree
world: 1
kind: prop
status: build
height: 15.375
blocks: 17
tris: 204
budget: 600
collision: Box
footprint: [9.125, 6, 15.375]
palette: ["#3F9B3A", "#6B3F26", "#FFF3F7"]
roles: [body, second, accent]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/MeadowTreeB/MeadowTreeB.glb"
---
# Meadow tall tree (World 1 Verdant)

The meadow's tall tree: a slim trunk with one bough and a knot, and a crown of four stacked tiers that narrow to a tip, two side clumps and a low hanging clump, white blossoms tucked into it. It stands taller than the oak so the treeline has a rhythm.

- **Cells**: `wood` on the trunk, bough and knot; `moss` on the tiers, with the white accent as the sprig cell, so the blossoms and the sprigs speak to each other
- **Scale**: the lowest leaves at 6 studs, over the avatar's head
- **Footprint**: 9.125 x 6 x 15.375 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 9.2 x 7 x 16.1.
- **Budget**: 600 triangles (the estimate before culling is 204); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the trunk, a bough and a knot
  - {name: Trunk, slot: BodyDark, size: [1.25, 8, 1.25], at: [0, 4, 0], material: wood}
  - {name: Root, slot: BodyDark, size: [0.75, 0.75, 0.5], at: [0.875, 0.375, 0.25], mirror: x, material: wood}
  - {name: RootFront, slot: BodyDark, size: [0.5, 0.5, 0.75], at: [-0.25, 0.25, -0.875], material: wood}
  - {name: Bough, slot: BodyDark, size: [2, 0.5, 0.5], at: [1.5, 6.75, 0], rot: [0, 0, 22], material: wood}
  - {name: Knot, slot: BodyDark, size: [0.5, 0.5, 0.25], at: [0.25, 3, -0.75], material: wood}
  # the crown: four tiers to a tip, side clumps, a hanging clump
  - {name: TierLow, slot: Body, size: [6.5, 2.5, 5.5], at: [0.25, 8.25, 0], material: moss}
  - {name: TierMid, slot: Body, size: [5, 2.5, 4.5], at: [-0.25, 10.5, 0.25], material: moss}
  - {name: TierHigh, slot: Body, size: [3.5, 2.25, 3.25], at: [0.25, 12.75, -0.25], material: moss}
  - {name: Tip, slot: Body, size: [1.75, 1.5, 1.75], at: [0, 14.625, 0], material: moss}
  - {name: SideR, slot: Body, size: [1.75, 2, 2.5], at: [3.875, 9.5, -0.5], material: moss}
  - {name: SideL, slot: Body, size: [2, 1.75, 2], at: [-3.375, 10.375, 0.75], material: moss}
  - {name: Hang, slot: Body, size: [2.5, 1, 1.25], at: [-1.25, 6.75, -2.625], material: moss}
  # white blossoms
  - {name: Bloom, slot: Accessory, size: [0.5, 0.5, 0.5], at: [2, 9.75, -2.375]}
  - {name: Bloom2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-2.5, 11.5, -2]}
  - {name: Bloom3, slot: Accessory, size: [0.5, 0.5, 0.5], at: [1, 13.5, -1.75]}
  - {name: Bloom4, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-4.125, 9.25, 0.25]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
