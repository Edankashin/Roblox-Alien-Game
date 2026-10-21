---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceLantern
name: Ice lantern
world: 2
kind: prop
status: build
height: 4.75
blocks: 12
tris: 142
budget: 320
collision: Box
footprint: [1.5, 1.5, 4.75]
palette: ["#BFEBFA", "#7F8E99", "#F2F6FA", "#FFB347"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/IceLantern/IceLantern.glb"
---
# Ice lantern (World 2 Frostbyte)

A lantern carved from ice on a stone plinth: an ice post, a cage of four ice bars under a pointed ice roof dusted with snow, and inside it a block of warm orange light, the heater's FFB347. In the blue of Frostbyte it is the one warm note, so the eye goes to it: the paths and the camp are lit with these.

- **Cells**: `ice` on post, cage, bars and roof (its edges lighter, glossy); the flame `glow` in the warm FFB347; `snow` on the roof and plinth
- **Footprint**: 1.5 x 1.5 x 4.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 320 triangles (the estimate before culling is 142); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the plinth, the ice post, the cage and roof
  - {name: Plinth, slot: BodyDark, size: [1.25, 0.5, 1.25], at: [0, 0.25, 0], material: stone}
  - {name: Post, slot: Body, size: [0.75, 2, 0.75], at: [0, 1.5, 0], material: ice}
  - {name: Cage, slot: Body, size: [1.25, 0.25, 1.25], at: [0, 2.625, 0], material: ice}
  - {name: Pillar, slot: Body, size: [0.25, 1, 0.25], at: [0.5, 3.25, -0.5], material: ice}
  - {name: Pillar2, slot: Body, size: [0.25, 1, 0.25], at: [-0.5, 3.25, -0.5], material: ice}
  - {name: Pillar3, slot: Body, size: [0.25, 1, 0.25], at: [0.5, 3.25, 0.5], material: ice}
  - {name: Pillar4, slot: Body, size: [0.25, 1, 0.25], at: [-0.5, 3.25, 0.5], material: ice}
  - {name: Roof, slot: Body, size: [1.5, 0.25, 1.5], at: [0, 3.875, 0], material: ice}
  - {name: Point, slot: Body, size: [0.75, 0.75, 0.75], at: [0, 4.375, 0], shape: cone6, material: ice}
  # the warm light
  - {name: Flame, slot: Glow, size: [0.625, 0.75, 0.625], at: [0.0625, 3.125, 0.0625]}
  # snow
  - {name: RoofSnow, slot: Accessory, size: [1.25, 0.25, 1.25], at: [0.125, 4.125, 0.125], material: snow}
  - {name: PlinthSnow, slot: Accessory, size: [1, 0.25, 0.75], at: [-0.125, 0.625, 0.25], material: snow}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
