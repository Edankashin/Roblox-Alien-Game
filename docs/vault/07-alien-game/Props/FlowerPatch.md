---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: FlowerPatch
name: Flower patch
world: 1
kind: prop
status: build
height: 1.25
blocks: 16
tris: 192
budget: 260
collision: None
footprint: [2, 2, 1.25]
palette: ["#FF8FB0", "#3F8F2E", "#FFD34D", "#F7F3EA"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/FlowerPatch/FlowerPatch.glb"
---
# Flower patch (World 1 Verdant)

A clump of six meadow flowers at different heights in the three meadow colours (pink, sun yellow and white) over four flat leaves. The cheapest prop: scattered by the hundred, no collision, so players run through it.

- **Cells**: plain cells: at the world cell a flower head is a block one and a half cells across, a little square of colour
- **Footprint**: 2 x 2 x 1.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 260 triangles (the estimate before culling is 192); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # leaves flat on the ground
  - {name: Leaf, slot: BodyDark, size: [0.75, 0.125, 0.375], at: [-0.5, 0.0625, -0.3125]}
  - {name: Leaf2, slot: BodyDark, size: [0.375, 0.125, 0.75], at: [0.6875, 0.0625, 0.5]}
  - {name: Leaf3, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [0.75, 0.0625, -0.625]}
  - {name: Leaf4, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [-0.75, 0.0625, 0.75]}
  # six flowers, stem and head
  - {name: Stem, slot: BodyDark, size: [0.125, 1, 0.125], at: [-0.4375, 0.5, -0.1875]}
  - {name: Head, slot: Body, size: [0.375, 0.25, 0.375], at: [-0.5625, 1.125, -0.3125]}
  - {name: Stem2, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [0.5625, 0.375, 0.3125]}
  - {name: Head2, slot: Accessory, size: [0.375, 0.25, 0.375], at: [0.4375, 0.875, 0.4375]}
  - {name: Stem3, slot: BodyDark, size: [0.125, 0.625, 0.125], at: [0.8125, 0.3125, -0.6875]}
  - {name: Head3, slot: Body, size: [0.375, 0.25, 0.375], at: [0.6875, 0.75, -0.5625]}
  - {name: Stem4, slot: BodyDark, size: [0.125, 0.875, 0.125], at: [-0.6875, 0.4375, 0.8125]}
  - {name: Head4, slot: Trim, size: [0.375, 0.25, 0.375], at: [-0.8125, 1, 0.6875]}
  - {name: Stem5, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.0625, 0.25, 0.8125]}
  - {name: Head5, slot: Body, size: [0.375, 0.25, 0.375], at: [-0.0625, 0.625, 0.6875]}
  - {name: Stem6, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [-0.1875, 0.25, -0.9375]}
  - {name: Head6, slot: Accessory, size: [0.375, 0.25, 0.375], at: [-0.0625, 0.625, -0.8125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
