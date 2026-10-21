---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: MeadowRock
name: Mossy rock
world: 1
kind: prop
status: build
height: 3.125
blocks: 7
tris: 84
budget: 300
collision: Hull
footprint: [4.75, 3, 3.125]
palette: ["#9E9E8E", "#7C7C6E", "#6CB04A"]
roles: [body, second, accent]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/MeadowRock/MeadowRock.glb"
---
# Mossy rock (World 1 Verdant)

A hip-high meadow rock: a cobbled boulder with a smaller top, a darker shoulder and a chip at its foot, a moss cushion lying across its top with one sprig standing up. Cheap: scattered about forty times a world.

- **Cells**: `stone` cobbles on the rock (the darker shoulder in the second colour); `moss` on the cushion, its lit fringe hanging over the top's edge
- **Footprint**: 4.75 x 3 x 3.125 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 4 x 4 x 2.8.
- **Budget**: 300 triangles (the estimate before culling is 84); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the boulder, its top, a shoulder and a chip
  - {name: Rock, slot: Body, size: [3.5, 1.75, 3], at: [0, 0.875, 0], material: stone}
  - {name: Top, slot: Body, size: [2.5, 0.75, 2.25], at: [-0.25, 2.125, 0.25], material: stone}
  - {name: Shoulder, slot: BodyDark, size: [1.25, 1, 1.5], at: [1.875, 0.5, -0.5], material: stone}
  - {name: Chip, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [-1.875, 0.25, -1], material: stone}
  # moss on top
  - {name: Moss, slot: Accessory, size: [2, 0.25, 1.5], at: [-0.5, 2.625, 0.5], material: moss}
  - {name: MossSide, slot: Accessory, size: [1.25, 0.25, 1], at: [1, 1.875, 0.75], material: moss}
  - {name: Tuft, slot: Accessory, size: [0.25, 0.5, 0.25], at: [0.25, 2.875, -0.375]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
