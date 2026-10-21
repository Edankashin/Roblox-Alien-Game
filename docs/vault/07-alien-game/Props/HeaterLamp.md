---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: HeaterLamp
name: Heater lamp
world: 0
kind: prop
status: build
height: 2.5
blocks: 12
tris: 144
budget: 300
collision: Box
footprint: [2.5, 2.625, 2.5]
palette: ["#6B7580", "#3D4556", "#FFFFFF", "#C9CFD8", "#FFB347"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/HeaterLamp/HeaterLamp.glb"
---
# Heater lamp (every world)

The camp's heater lamp (the Heater tool on its disc in Frostbyte, and the Lamp in the home plot): a squat riveted steel brazier on three feet with a lit grate behind two bars at its front and a bed of glowing coals with two embers in its open top, under a polished rim. The warm orange is the only warm light in World 2.

- **Cells**: `metal` panels and rivets on the drum and feet, the rim and band on the glossy Trim slot; the grate and coals `glow` (Neon in the game; the Heaters service adds its PointLight)
- **Footprint**: 2.5 x 2.625 x 2.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 3 x 3 x 2.6.
- **Budget**: 300 triangles (the estimate before culling is 144); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the drum on three feet, a band and a rim
  - {name: Foot, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.875, 0.1875, -0.875], mirror: x, material: metal}
  - {name: FootBack, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0, 0.1875, 0.875], material: metal}
  - {name: Drum, slot: Body, size: [2.25, 1.5, 2.25], at: [0, 1.125, 0], material: metal}
  - {name: Rim, slot: Trim, size: [2.5, 0.25, 2.5], at: [0, 2, 0], material: metal}
  - {name: Band, slot: Trim, size: [2.375, 0.25, 2.375], at: [-0.0625, 0.625, -0.0625], material: metal}
  # the grate, its bars, the coals and embers
  - {name: Grate, slot: Glow, size: [1.25, 0.75, 0.125], at: [0, 1.125, -1.1875]}
  - {name: Bar, slot: BodyDark, size: [0.25, 0.75, 0.125], at: [0.25, 1.125, -1.3125], mirror: x}
  - {name: Coals, slot: Glow, size: [1.75, 0.25, 1.75], at: [0, 2, 0]}
  - {name: Ember, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.1875, 2.3125, -0.3125]}
  - {name: Ember2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.375, 2.375, 0.25]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
