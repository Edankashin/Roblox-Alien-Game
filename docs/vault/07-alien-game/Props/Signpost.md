---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Signpost
name: Signpost
world: 1
kind: prop
status: build
height: 3.75
blocks: 10
tris: 120
budget: 260
collision: Box
footprint: [4.5, 1.25, 3.75]
palette: ["#C08A55", "#7B4A2D", "#FFF4DC", "#9E9E8E"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Signpost/Signpost.glb"
---
# Signpost (World 1 Verdant)

A crossroads signpost: a capped post with two arrow boards pointing opposite ways, each with a painted cream stripe (the words go on it in the game as a SurfaceGui, if ever), wedged in a pile of stones.

- **Cells**: `wood` on post and boards; the arrow tips a stepped block (rule 5's chamfer as a step); `stone` on the pile
- **Footprint**: 4.5 x 1.25 x 3.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 260 triangles (the estimate before culling is 120); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the post and its cap
  - {name: Post, slot: BodyDark, size: [0.5, 3.5, 0.5], at: [0, 1.75, 0], material: wood}
  - {name: Top, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [0, 3.625, 0], material: wood}
  # two arrow boards with painted stripes
  - {name: Board, slot: Body, size: [2.25, 0.625, 0.25], at: [1, 2.8125, -0.375], material: wood}
  - {name: Tip, slot: Body, size: [0.25, 0.375, 0.25], at: [2.25, 2.8125, -0.375], material: wood}
  - {name: Board2, slot: Body, size: [2, 0.625, 0.25], at: [-0.875, 2.0625, -0.375], material: wood}
  - {name: Tip2, slot: Body, size: [0.25, 0.375, 0.25], at: [-2, 1.9375, -0.375], material: wood}
  - {name: Mark, slot: Accessory, size: [1.25, 0.125, 0.125], at: [0.875, 2.8125, -0.5625]}
  - {name: Mark2, slot: Accessory, size: [1, 0.125, 0.125], at: [-0.75, 2.0625, -0.5625]}
  # stones at the foot
  - {name: Stones, slot: Trim, size: [1.25, 0.375, 1], at: [0.125, 0.1875, 0.125], material: stone}
  - {name: Tuft, slot: Trim, size: [0.5, 0.25, 0.5], at: [-0.5, 0.5, -0.25], material: moss}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
