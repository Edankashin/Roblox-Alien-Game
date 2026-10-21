---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Log
name: Mossy log
world: 1
kind: prop
status: build
height: 2
blocks: 10
tris: 120
budget: 300
collision: Hull
footprint: [5.75, 1.625, 2]
palette: ["#6CB04A", "#7B4A2D", "#E8843D", "#F2E6D0"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Log/Log.glb"
---
# Mossy log (World 1 Verdant)

A fallen log lying across the grass: bark in grain rows along its length with rings on its cut end, a broken stub, a moss blanket along its top and two little orange toadstools growing from the moss. A seat for the avatar and a perch for the small aliens.

- **Cells**: `wood` (its grain runs the log's length, the end in square rings); `moss` on the blanket; the toadstools plain cells
- **Footprint**: 5.75 x 1.625 x 2 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 300 triangles (the estimate before culling is 120); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the log, a stub, a broken end, a root
  - {name: Log, slot: BodyDark, size: [4.5, 1.25, 1.25], at: [0, 0.625, 0], material: wood}
  - {name: Stub, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [0.75, 1.625, 0], material: wood}
  - {name: Broken, slot: BodyDark, size: [0.75, 1, 1], at: [2.625, 0.5, 0.125], material: wood}
  - {name: Root, slot: BodyDark, size: [0.5, 0.5, 0.75], at: [-2.5, 0.25, -0.625], material: wood}
  # moss along the top
  - {name: Moss, slot: Body, size: [2, 0.25, 1], at: [-0.75, 1.375, 0.125], material: moss}
  - {name: MossEnd, slot: Body, size: [0.75, 0.25, 0.75], at: [1.875, 1.125, 0], material: moss}
  # two toadstools in the moss
  - {name: Shroom, slot: Accessory, size: [0.5, 0.25, 0.5], at: [-1.5, 1.75, -0.125]}
  - {name: ShroomStem, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.5, 1.5, -0.125]}
  - {name: Shroom2, slot: Accessory, size: [0.375, 0.25, 0.375], at: [-0.8125, 1.625, 0.1875]}
  - {name: ShroomStem2, slot: Trim, size: [0.125, 0.125, 0.125], at: [-0.9375, 1.4375, 0.3125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
