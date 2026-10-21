---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Fence
name: Garden fence
world: 1
kind: prop
status: build
height: 2.25
blocks: 10
tris: 120
budget: 260
collision: Box
footprint: [4.5, 1.25, 2.25]
palette: ["#B98552", "#8A5A35", "#5E9E3A", "#FF8FB0"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Fence/Fence.glb"
---
# Garden fence (World 1 Verdant)

A four-stud section of storybook garden fence: two capped posts, two rails and a middle picket, a sprig of vine with a pink bloom climbing the top rail. Sections stand end to end along paths and round the camp.

- **Cells**: `wood` on posts and rails (grain along each; rings on the post caps); the vine `moss`, the bloom plain
- **Footprint**: 4.5 x 1.25 x 2.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 260 triangles (the estimate before culling is 120); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # posts, caps, rails, a picket
  - {name: Post, slot: BodyDark, size: [0.5, 2, 0.5], at: [1.75, 1, 0], mirror: x, material: wood}
  - {name: Cap, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [1.75, 2.125, 0], mirror: x, material: wood}
  - {name: Rail, slot: Body, size: [4.5, 0.375, 0.25], at: [0, 1.5625, -0.375], material: wood}
  - {name: RailLow, slot: Body, size: [4.5, 0.375, 0.25], at: [0, 0.8125, -0.375], material: wood}
  - {name: Picket, slot: Body, size: [0.375, 1.5, 0.125], at: [-0.0625, 1.25, -0.5625], material: wood}
  # a climbing vine with a bloom
  - {name: Vine, slot: Accessory, size: [0.25, 0.25, 0.375], at: [-0.875, 1.5, -0.6875], material: moss}
  - {name: Vine2, slot: Accessory, size: [0.5, 0.25, 0.375], at: [-0.375, 1.75, -0.6875], material: moss}
  - {name: Bloom, slot: Trim, size: [0.25, 0.25, 0.25], at: [-0.625, 1.875, -0.75]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
