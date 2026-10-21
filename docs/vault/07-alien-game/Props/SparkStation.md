---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SparkStation
name: Glow flower
world: 0
kind: prop
status: build
height: 4.5
blocks: 12
tris: 144
budget: 260
collision: None
footprint: [2.275, 1.75, 4.5]
palette: ["#A855F7", "#3F9B3A", "#5DBB3A", "#FFC83D"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/SparkStation/SparkStation.glb"
---
# Glow flower (every world)

The camp's Spark station (the Glow Flower of data/Camp.luau): a tall flower on a mossy mound, two leaves reaching out, a head of four purple petals and a cap round a glowing golden core, two motes of pollen floating over it.

- **Cells**: `moss` on the mound and stem, plain cells on leaves and petals, the core and pollen `glow`
- **Fit**: 2 x 2 studs, 4.5 tall; no collision (its block collides)
- **Footprint**: 2.275 x 1.75 x 4.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 2.12 x 1.95 x 4.
- **Budget**: 260 triangles (the estimate before culling is 144); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the mound, stem and leaves
  - {name: Mound, slot: BodyDark, size: [1.5, 0.375, 1.5], at: [0, 0.1875, 0], material: moss}
  - {name: Stem, slot: BodyDark, size: [0.5, 3, 0.5], at: [0, 1.875, 0], material: moss}
  - {name: Leaf, slot: Accessory, size: [1, 0.25, 0.5], at: [0.625, 1.25, 0], rot: [0, 0, 20]}
  - {name: LeafL, slot: Accessory, size: [1, 0.25, 0.5], at: [-0.625, 2, 0], rot: [0, 0, -20]}
  # the head: four petals, a cap, the core and pollen
  - {name: Petal, slot: Body, size: [0.75, 0.75, 0.5], at: [0, 3.625, -0.625]}
  - {name: PetalBack, slot: Body, size: [0.75, 0.75, 0.5], at: [0, 3.625, 0.625]}
  - {name: PetalSide, slot: Body, size: [0.5, 0.75, 0.75], at: [0.625, 3.625, 0], mirror: x}
  - {name: PetalTop, slot: Body, size: [0.5, 0.375, 0.5], at: [0, 4.1875, 0]}
  - {name: Core, slot: Glow, size: [0.75, 0.75, 0.75], at: [0, 3.625, 0]}
  - {name: Pollen, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.8125, 4.3125, -0.4375]}
  - {name: Pollen2, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.6875, 4.4375, 0.3125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
