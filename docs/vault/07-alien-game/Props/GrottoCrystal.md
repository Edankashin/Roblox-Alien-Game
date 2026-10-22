---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: GrottoCrystal
name: Grotto crystal
world: 1
kind: prop
status: build
height: 4
blocks: 15
tris: 172
budget: 420
collision: Hull
footprint: [2.789, 2.112, 4]
palette: ["#A8F0FA", "#6E6A78", "#B49CFF", "#6CB04A", "#7FE3F0"]
roles: [body, second, accent, trim, glow]
render: "[[placeholder_props_v1.jpg]]"
glb: "assets/models/props/GrottoCrystal/GrottoCrystal.glb"
---
# Grotto crystal (World 1 Verdant, the cave)

The crystals of the cave's grotto at its back and scattered over the cave floor: a lit cyan column with a stepped point
standing out of a slate rock, and four leaning shards round it, two pale aqua and two lilac, each with a six-sided point, and
a tuft of cave moss. The cyan column is the grotto's light (its PointLight stays the recipe's, carried onto the mesh).
Distinct from World 2's [[IceCrystalCluster]] by its lit column, its lilac and its slate.

- **Cells**: `crystal` on the shards and points (light diagonals); `stone` on the rock; `moss` on the tuft; the column `glow`
- **Tilt**: the shards lean 10 to 22 degrees (rule 1)
- **Footprint**: 2.789 x 2.112 x 4 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here (the landmark contract).
- **Budget**: 420 triangles; collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the slate rock
  - {name: Rock, slot: BodyDark, size: [2.5, 0.5, 2], at: [0, 0.25, 0], material: stone}
  - {name: Rock2, slot: BodyDark, size: [1.25, 0.25, 1], at: [-0.5, 0.625, 0.375], material: stone}
  # the lit column and its stepped point
  - {name: Column, slot: Glow, size: [0.75, 2.75, 0.75], at: [0, 1.875, 0]}
  - {name: ColumnTip, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 3.5, 0]}
  - {name: ColumnTip2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 3.875, 0]}
  # four leaning shards with six-sided points
  - {name: Shard, slot: Body, size: [0.5, 1.75, 0.5], at: [0.875, 1.375, -0.25], rot: [-12, 0, -20], material: crystal}
  - {name: Point, slot: Body, size: [0.5, 0.5, 0.5], at: [1.25, 2.4375, -0.5], rot: [-12, 0, -20], shape: cone6, material: crystal}
  - {name: Shard2, slot: Accessory, size: [0.625, 2, 0.625], at: [-0.75, 1.5, -0.125], rot: [10, 0, 18], material: crystal}
  - {name: Point2, slot: Accessory, size: [0.625, 0.625, 0.625], at: [-1.125, 2.75, 0.125], rot: [10, 0, 18], shape: cone6, material: crystal}
  - {name: Shard3, slot: Body, size: [0.375, 1.25, 0.375], at: [0.25, 1.125, 0.625], rot: [18, 0, 0], material: crystal}
  - {name: Point3, slot: Body, size: [0.375, 0.375, 0.375], at: [0.25, 1.875, 0.875], rot: [18, 0, 0], shape: cone6, material: crystal}
  - {name: Shard4, slot: Accessory, size: [0.375, 1, 0.375], at: [-0.375, 1, -0.75], rot: [-20, 0, 10], material: crystal}
  - {name: Point4, slot: Accessory, size: [0.375, 0.375, 0.375], at: [-0.5, 1.625, -1], rot: [-20, 0, 10], shape: cone6, material: crystal}
  # cave moss and a chip of lit crystal
  - {name: Moss, slot: Trim, size: [0.75, 0.25, 0.5], at: [0.75, 0.625, 0.5], material: moss}
  - {name: Chip, slot: Glow, size: [0.25, 0.25, 0.25], at: [1, 0.625, -0.625]}
```

## Renders

On the placeholder props sheet: ![[placeholder_props_v1.jpg]]

## Reviews

- 2026-10-22, placeholder props worker. First block-cell build: it replaces the block placeholder of data/WorldKit (Studio 2026-10-22: 22 placeholders in World 1, 10 in World 2). Status build: waiting for Ethan's look at the sheet.
