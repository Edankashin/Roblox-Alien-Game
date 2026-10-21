---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceRockB
name: Frost standing rock
world: 2
kind: prop
status: build
height: 4.25
blocks: 9
tris: 108
budget: 320
collision: Hull
footprint: [3.375, 2.75, 4.25]
palette: ["#A9B7C0", "#8796A0", "#F2F6FA", "#BFEBFA", "#BFF3FF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/IceRockB/IceRockB.glb"
---
# Frost standing rock (World 2 Frostbyte)

A taller, narrower rock: a standing block with a top and a foot, two veins of ice running down its faces with a lit glint, snow on its top, a shelf and its foot.

- **Cells**: `stone`, `snow`, `ice` veins, a `glow` glint
- **Footprint**: 3.375 x 2.75 x 4.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 3 x 3 x 4.
- **Budget**: 320 triangles (the estimate before culling is 108); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the rock
  - {name: Rock, slot: Body, size: [2.5, 3, 2.5], at: [0, 1.5, 0], material: stone}
  - {name: Top, slot: Body, size: [1.75, 0.75, 1.5], at: [-0.125, 3.375, 0.25], material: stone}
  - {name: Foot, slot: Body, size: [1.25, 0.75, 1], at: [1.375, 0.375, -0.5], material: stone}
  # ice veins and a glint
  - {name: Vein, slot: Trim, size: [0.375, 2.5, 0.125], at: [0.4375, 1.75, -1.3125], material: ice}
  - {name: Vein2, slot: Trim, size: [0.125, 1.5, 0.375], at: [-1.3125, 1.5, 0.1875], material: ice}
  - {name: Glint, slot: Glow, size: [0.25, 0.25, 0.125], at: [0.5, 2.25, -1.4375]}
  # snow
  - {name: Cap, slot: Accessory, size: [1.5, 0.5, 1.25], at: [-0.125, 4, 0.25], material: snow}
  - {name: Shelf, slot: Accessory, size: [1.25, 0.5, 1], at: [0.375, 3.25, -0.875], material: snow}
  - {name: FootSnow, slot: Accessory, size: [1, 0.25, 0.75], at: [1.375, 0.875, -0.5], material: snow}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
