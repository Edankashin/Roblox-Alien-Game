---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: CampCrate
name: Camp supply crate
world: 0
kind: prop
status: build
height: 2
blocks: 23
tris: 276
budget: 360
collision: Box
collision_slots: {Accessory: None, Trim: None}
footprint: [2, 2, 2]
palette: ["#C08A55", "#8C5E32", "#FFC83D", "#68C9FE"]
roles: [body, second, accent, trim]
render: "[[placeholder_props_v1.jpg]]"
glb: "assets/models/props/CampCrate/CampCrate.glb"
---
# Camp supply crate (both worlds, the camp)

The crash's salvage, stacked by the ship bay in both worlds: a plank crate exactly 2 studs a side (the layout stacks one on
another with `lift: 2`), a darker frame of corner posts and rims, and the ship's badge (the ShipHull's yellow ring round a
cyan pixel) on its front and its right side, so it reads as the crew's own kit on the meadow and on the snow alike.

- **Cells**: `wood` on the planks and the frame; the badge plain cells
- **Collision**: `Box` on the crate and its frame; the badge none
- **Footprint**: 2 x 2 x 2 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here (the landmark contract).
- **Budget**: 360 triangles; collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the crate and its frame
  - {name: Crate, slot: Body, size: [1.75, 1.75, 1.75], at: [0, 1, 0], material: wood}
  - {name: Post, slot: BodyDark, size: [0.25, 2, 0.25], at: [0.875, 1, -0.875], mirror: x, material: wood}
  - {name: PostBack, slot: BodyDark, size: [0.25, 2, 0.25], at: [0.875, 1, 0.875], mirror: x, material: wood}
  - {name: RimTop, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 1.875, -0.875], material: wood}
  - {name: RimTopBack, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 1.875, 0.875], material: wood}
  - {name: RimTopSide, slot: BodyDark, size: [0.25, 0.25, 1.5], at: [0.875, 1.875, 0], mirror: x, material: wood}
  - {name: RimFoot, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 0.125, -0.875], material: wood}
  - {name: RimFootBack, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0, 0.125, 0.875], material: wood}
  - {name: RimFootSide, slot: BodyDark, size: [0.25, 0.25, 1.5], at: [0.875, 0.125, 0], mirror: x, material: wood}
  # the ship's badge on the front: a yellow ring round a cyan pixel
  - {name: Badge, slot: Accessory, size: [0.75, 0.25, 0.125], at: [0, 1.25, -0.9375]}
  - {name: Badge2, slot: Accessory, size: [0.75, 0.25, 0.125], at: [0, 0.75, -0.9375]}
  - {name: Badge3, slot: Accessory, size: [0.25, 0.25, 0.125], at: [0.25, 1, -0.9375], mirror: x}
  - {name: Dot, slot: Trim, size: [0.25, 0.25, 0.125], at: [0, 1, -0.9375]}
  # and on the right side
  - {name: Side, slot: Accessory, size: [0.125, 0.25, 0.75], at: [-0.9375, 1.25, 0]}
  - {name: Side2, slot: Accessory, size: [0.125, 0.25, 0.75], at: [-0.9375, 0.75, 0]}
  - {name: Side3, slot: Accessory, size: [0.125, 0.25, 0.25], at: [-0.9375, 1, 0.25]}
  - {name: Side4, slot: Accessory, size: [0.125, 0.25, 0.25], at: [-0.9375, 1, -0.25]}
  - {name: SideDot, slot: Trim, size: [0.125, 0.25, 0.25], at: [-0.9375, 1, 0]}
```

## Renders

On the placeholder props sheet: ![[placeholder_props_v1.jpg]]

## Reviews

- 2026-10-22, placeholder props worker. First block-cell build: it replaces the block placeholder of data/WorldKit (Studio 2026-10-22: 22 placeholders in World 1, 10 in World 2). Status build: waiting for Ethan's look at the sheet.
