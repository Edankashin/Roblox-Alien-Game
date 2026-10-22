---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SightPost
name: Sights signpost post
world: 0
kind: prop
status: build
height: 7
blocks: 9
tris: 108
budget: 300
collision: Box
collision_slots: {Glow: None}
footprint: [1.25, 1.25, 7]
palette: ["#A8794A", "#7B4A2D", "#8E8E86", "#FFE36B"]
roles: [body, second, trim, glow]
render: "[[placeholder_props_v1.jpg]]"
glb: "assets/models/props/SightPost/SightPost.glb"
---
# Sights signpost post (both worlds, the camp)

The post of the camp's sights signpost, east of the north path: a tall wooden post on two stones with a cap and a lit pixel
star on top (the sights are what the star points you to). Its three arms are their own props, placed at the same point and
each yawed at its sight: [[SignArmHigh]], [[SignArmMid]], [[SignArmLow]] in World 1, [[IceSignArmHigh]], [[IceSignArmMid]],
[[IceSignArmLow]] in World 2. The post is 0.5 studs square, so an arm's board starts on its face at any yaw.

- **Cells**: `wood` on the post and the cap; `stone` on the foot; the star `glow`
- **Collision**: `Box` on the post and the stones; the star none
- **Footprint**: 1.25 x 1.25 x 7 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here (the landmark contract).
- **Budget**: 300 triangles; collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # two stones, the post and its cap
  - {name: Stone, slot: Trim, size: [1.25, 0.375, 1.25], at: [0, 0.1875, 0], material: stone}
  - {name: Stone2, slot: Trim, size: [0.75, 0.25, 0.5], at: [-0.25, 0.5, -0.375], material: stone}
  - {name: Post, slot: BodyDark, size: [0.5, 5.625, 0.5], at: [0, 3.1875, 0], material: wood}
  - {name: Cap, slot: Body, size: [0.75, 0.25, 0.75], at: [0, 6.125, 0], material: wood}
  # a lit pixel star on top
  - {name: Star, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 6.625, 0]}
  - {name: Star2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 6.375, 0]}
  - {name: Star3, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 6.875, 0]}
  - {name: Star4, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.25, 6.625, 0], mirror: x}
```

## Renders

On the placeholder props sheet: ![[placeholder_props_v1.jpg]]

## Reviews

- 2026-10-22, placeholder props worker. First block-cell build: it replaces the block placeholder of data/WorldKit (Studio 2026-10-22: 22 placeholders in World 1, 10 in World 2). Status build: waiting for Ethan's look at the sheet.
