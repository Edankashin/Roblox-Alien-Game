---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: LilyPad
name: Lily pad
world: 1
kind: prop
status: build
height: 0.5
blocks: 8
tris: 96
budget: 160
collision: None
footprint: [2.75, 2.125, 0.5]
palette: ["#4FAF4A", "#3F8F2E", "#FFB3CC", "#FFD34D"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/LilyPad/LilyPad.glb"
---
# Lily pad (World 1 Verdant)

A lily pad for the pond: a notched pad (two plates, the notch at its front) and a small second pad, a pink water-lily with a yellow heart on the big one. It floats on the water's top; no collision.

- **Cells**: plain cells; the pad is one cell thin, so it reads as a leaf on the water
- **Footprint**: 2.75 x 2.125 x 0.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 160 triangles (the estimate before culling is 96); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the pads
  - {name: Pad, slot: Body, size: [1.75, 0.125, 1.25], at: [0, 0.0625, 0.25]}
  - {name: PadFront, slot: Body, size: [1, 0.125, 0.5], at: [-0.375, 0.0625, -0.625]}
  - {name: Pad2, slot: BodyDark, size: [0.875, 0.125, 0.875], at: [1.4375, 0.0625, -0.8125]}
  # the water-lily
  - {name: Petal, slot: Accessory, size: [0.375, 0.25, 0.375], at: [0.1875, 0.25, 0.1875]}
  - {name: PetalSide, slot: Accessory, size: [0.25, 0.375, 0.25], at: [0.375, 0.3125, 0.125], mirror: x}
  - {name: PetalBack, slot: Accessory, size: [0.25, 0.375, 0.25], at: [0.125, 0.3125, 0.375]}
  - {name: Heart, slot: Trim, size: [0.25, 0.125, 0.25], at: [0.125, 0.4375, 0.125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
