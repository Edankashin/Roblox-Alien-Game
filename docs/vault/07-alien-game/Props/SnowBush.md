---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SnowBush
name: Frost bush
world: 2
kind: prop
status: build
height: 2.75
blocks: 10
tris: 120
budget: 280
collision: Hull
footprint: [3.875, 2.5, 2.75]
palette: ["#2F6B5E", "#22524A", "#F2F6FA", "#9FE8FF"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/SnowBush/SnowBush.glb"
---
# Frost bush (World 2 Frostbyte)

A low evergreen bush heaped with snow, its frost-berries lit pale cyan like tiny ice lamps. The cold twin of the meadow's berry bush.

- **Cells**: `pine` needle rows, `snow` heaps, the berries `glow`
- **Footprint**: 3.875 x 2.5 x 2.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 280 triangles (the estimate before culling is 120); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the bush
  - {name: Bush, slot: Body, size: [2.75, 1.5, 2.25], at: [0, 0.75, 0], material: pine}
  - {name: Top, slot: Body, size: [1.75, 0.75, 1.5], at: [0.25, 1.875, 0.125], material: pine}
  - {name: Lobe, slot: Body, size: [1, 1, 1.25], at: [-1.75, 0.5, 0.25], material: pine}
  # snow heaped on it
  - {name: Snow, slot: Accessory, size: [1.25, 0.5, 1], at: [0.25, 2.5, 0.125], material: snow}
  - {name: Snow2, slot: Accessory, size: [1.25, 0.25, 1.25], at: [-0.75, 1.625, 0.375], material: snow}
  - {name: Snow3, slot: Accessory, size: [0.75, 0.25, 0.75], at: [-1.75, 1.125, 0.25], material: snow}
  # lit frost-berries
  - {name: Berry, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.75, 1, -1.25]}
  - {name: Berry2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.5, 0.75, -1.25]}
  - {name: Berry3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.5, 1.25, -0.5]}
  - {name: Berry4, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.25, 1.5, -1]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
