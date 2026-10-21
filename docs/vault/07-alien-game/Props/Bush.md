---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Bush
name: Berry bush
world: 1
kind: prop
status: build
height: 2.5
blocks: 10
tris: 120
budget: 300
collision: Hull
footprint: [5.125, 2.75, 2.5]
palette: ["#57B04A", "#3F8F2E", "#FF5C8A"]
roles: [body, second, accent]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Bush/Bush.glb"
---
# Berry bush (World 1 Verdant)

A round berry bush: a moss-tufted mass with a top and two side lobes, six raspberry-pink berries proud of its front and sides. It fills the gaps between trees and rocks at knee height.

- **Cells**: `moss` tufts in a lighter leaf green (its sprig cell the berry pink); the berries plain cells
- **Footprint**: 5.125 x 2.75 x 2.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 300 triangles (the estimate before culling is 120); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the bush: a mass, a top, two lobes
  - {name: Bush, slot: Body, size: [3, 1.75, 2.5], at: [0, 0.875, 0], material: moss}
  - {name: Top, slot: Body, size: [2, 0.75, 1.75], at: [-0.25, 2.125, 0.125], material: moss}
  - {name: SideR, slot: Body, size: [1, 1.25, 1.5], at: [1.875, 0.625, -0.25], material: moss}
  - {name: SideL, slot: Body, size: [0.75, 1, 1.25], at: [-1.875, 0.5, 0.25], material: moss}
  # berries
  - {name: Berry, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.5, 1.25, -1.375]}
  - {name: Berry2, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-0.75, 0.875, -1.375]}
  - {name: Berry3, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.875, 2.125, -0.875]}
  - {name: Berry4, slot: Accessory, size: [0.25, 0.25, 0.25], at: [2.5, 0.875, -0.75]}
  - {name: Berry5, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.375, 1.875, -0.5]}
  - {name: Berry6, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-2.375, 0.625, -0.375]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
