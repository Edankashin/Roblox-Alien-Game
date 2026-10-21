---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: GatherStation
name: Picnic table
world: 0
kind: prop
status: build
height: 2.375
blocks: 18
tris: 216
budget: 320
collision: None
footprint: [6, 4, 2.375]
palette: ["#C99A5B", "#8B5A2B", "#FFC83D", "#E8483D", "#FFD98A"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/GatherStation/GatherStation.glb"
---
# Picnic table (every world)

The camp's Gather station (the Picnic Table of data/Camp.luau): a low wooden table with a bench on each side, a sunny yellow cloth draped over it, a basket of glossy red apples, a crate of berries and a glowing jar of firefly light in the middle.

- **Cells**: `wood` grain on the table, benches, basket and crate; the cloth plain; the fruit `crystal` (glossy); the jar `glow`
- **Fit**: 6 x 3 studs, 1.5 tall at the table top (the jar and fruit stand on it); no collision (its block collides)
- **Footprint**: 6 x 4 x 2.375 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 6 x 3 x 1.5.
- **Budget**: 320 triangles (the estimate before culling is 216); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the table and two benches
  - {name: Top, slot: Body, size: [6, 0.375, 2.5], at: [0, 1.3125, 0], material: wood}
  - {name: Leg, slot: BodyDark, size: [0.5, 1.125, 2], at: [2.25, 0.5625, 0], mirror: x, material: wood}
  - {name: Bench, slot: Body, size: [5, 0.25, 0.5], at: [0, 0.625, -1.75], material: wood}
  - {name: BenchBack, slot: Body, size: [5, 0.25, 0.5], at: [0, 0.625, 1.75], material: wood}
  - {name: BenchLeg, slot: BodyDark, size: [0.25, 0.5, 0.5], at: [2.125, 0.25, -1.75], mirror: x, material: wood}
  - {name: BenchLegBack, slot: BodyDark, size: [0.25, 0.5, 0.5], at: [2.125, 0.25, 1.75], mirror: x, material: wood}
  # the cloth
  - {name: Cloth, slot: Accessory, size: [2.5, 0.125, 2.75], at: [0, 1.5625, 0]}
  - {name: Drape, slot: Accessory, size: [2.5, 0.375, 0.125], at: [0, 1.3125, -1.4375]}
  - {name: DrapeBack, slot: Accessory, size: [2.5, 0.375, 0.125], at: [0, 1.3125, 1.4375]}
  # a basket, a crate and a firefly jar
  - {name: Basket, slot: BodyDark, size: [1, 0.5, 0.75], at: [-1.75, 1.75, 0], material: wood}
  - {name: Apple, slot: Trim, size: [0.375, 0.375, 0.375], at: [-1.8125, 2.1875, -0.0625], material: crystal}
  - {name: Apple2, slot: Trim, size: [0.25, 0.25, 0.25], at: [-1.5, 2.125, 0.125], material: crystal}
  - {name: Crate, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [1.75, 1.75, 0.25], material: wood}
  - {name: Berry, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.625, 2.125, 0.125], material: crystal}
  - {name: Jar, slot: Glow, size: [0.375, 0.5, 0.375], at: [0.1875, 1.875, 0.1875]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
