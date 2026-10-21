---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Mushroom
name: Spotted mushroom
world: 1
kind: prop
status: build
height: 2.875
blocks: 14
tris: 168
budget: 320
collision: Hull
footprint: [2.875, 2.375, 2.875]
palette: ["#E8483D", "#F2E6D0", "#FFF8EE", "#5E9E3A"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Mushroom/Mushroom.glb"
---
# Spotted mushroom (World 1 Verdant)

A storybook toadstool: a cream stem with a skirt under a stepped red cap dotted with white spots on its top and sides, a baby toadstool at its foot and a patch of moss. About half the avatar's height.

- **Cells**: plain cells on the cap and stem (skin jitter), so the spots read cleanly; `moss` on the patch
- **Footprint**: 2.875 x 2.375 x 2.875 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 320 triangles (the estimate before culling is 168); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the toadstool: stem, skirt, cap in two steps
  - {name: Stem, slot: BodyDark, size: [0.75, 1.5, 0.75], at: [0, 0.75, 0]}
  - {name: Skirt, slot: BodyDark, size: [1.125, 0.25, 1.125], at: [0.0625, 1.125, 0.0625]}
  - {name: Cap, slot: Body, size: [2.25, 0.75, 2.25], at: [0, 1.875, 0]}
  - {name: CapTop, slot: Body, size: [1.5, 0.5, 1.5], at: [0, 2.5, 0]}
  # white spots on the cap
  - {name: Spot, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.25, 2.8125, -0.25]}
  - {name: Spot2, slot: Accessory, size: [0.375, 0.375, 0.125], at: [-0.5625, 1.9375, -1.1875]}
  - {name: Spot3, slot: Accessory, size: [0.375, 0.375, 0.125], at: [0.4375, 1.9375, -1.1875]}
  - {name: Spot4, slot: Accessory, size: [0.125, 0.375, 0.375], at: [1.1875, 1.9375, 0.4375]}
  - {name: Spot5, slot: Accessory, size: [0.125, 0.375, 0.375], at: [-1.1875, 1.9375, 0.4375]}
  - {name: Spot6, slot: Accessory, size: [0.375, 0.125, 0.375], at: [-0.3125, 2.0625, 0.6875]}
  # a baby toadstool and a moss patch
  - {name: BabyStem, slot: BodyDark, size: [0.375, 0.625, 0.375], at: [1.1875, 0.3125, -0.8125]}
  - {name: BabyCap, slot: Body, size: [0.875, 0.375, 0.875], at: [1.1875, 0.8125, -0.8125]}
  - {name: BabySpot, slot: Accessory, size: [0.25, 0.125, 0.25], at: [1.125, 1.0625, -0.875]}
  - {name: Grass, slot: Trim, size: [1.25, 0.125, 0.75], at: [-0.25, 0.0625, -0.75], material: moss}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
