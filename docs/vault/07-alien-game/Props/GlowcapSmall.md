---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: GlowcapSmall
name: Glowcap cluster
world: 1
region: Forest
kind: prop
status: build
height: 2.125
blocks: 17
tris: 204
budget: 320
collision: None
footprint: [2.875, 2.25, 2.125]
palette: ["#F5A6DC", "#E6DEF6", "#FFF4FB", "#2C7F72", "#D2B0FF"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/GlowcapSmall/GlowcapSmall.glb"
---
# Glowcap cluster (World 1 Verdant, Starhollow Forest)

A cluster of five small mushrooms on a moss mat for the giants' feet and the path's edge: three with violet glowing caps, two pink with white spots, the tallest under half the avatar's height. Scattered in rings round a giant, they are the grove's low light.

- **Cells**: plain cells on the stems and the pink caps; `moss` on the mat; the violet caps `glow`
- **Collision**: none, players run through it
- **Footprint**: 2.875 x 2.25 x 2.125 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 320 triangles (the estimate before culling is 204); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # five stems
  - {name: Stem, slot: BodyDark, size: [0.5, 1.25, 0.5], at: [0, 0.875, 0]}
  - {name: Stem2, slot: BodyDark, size: [0.375, 0.75, 0.375], at: [0.8125, 0.625, -0.5625]}
  - {name: Stem3, slot: BodyDark, size: [0.375, 1, 0.375], at: [-0.9375, 0.75, 0.3125]}
  - {name: Stem4, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [-0.375, 0.5, -0.875]}
  - {name: Stem5, slot: BodyDark, size: [0.25, 0.625, 0.25], at: [1.125, 0.5625, 0.625]}
  # three glowing caps and two pink
  - {name: Cap, slot: Glow, size: [1.25, 0.375, 1.25], at: [0, 1.6875, 0]}
  - {name: CapTop, slot: Glow, size: [0.75, 0.25, 0.75], at: [0, 2, 0]}
  - {name: Cap3, slot: Glow, size: [1, 0.375, 1], at: [-1, 1.4375, 0.25]}
  - {name: Cap5, slot: Glow, size: [0.625, 0.25, 0.625], at: [1.0625, 1, 0.6875]}
  - {name: Cap2, slot: Body, size: [0.875, 0.375, 0.875], at: [0.8125, 1.1875, -0.5625]}
  - {name: Cap2Top, slot: Body, size: [0.5, 0.125, 0.5], at: [0.75, 1.4375, -0.5]}
  - {name: Cap4, slot: Body, size: [0.625, 0.25, 0.625], at: [-0.3125, 0.875, -0.9375]}
  # white spots on the pink caps
  - {name: Spot, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.625, 1.5625, -0.625]}
  - {name: Spot2, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.3125, 1.25, -0.5]}
  - {name: Spot3, slot: Accessory, size: [0.25, 0.125, 0.25], at: [-0.25, 1.0625, -0.875]}
  # the moss mat
  - {name: Moss, slot: Trim, size: [2.5, 0.25, 2], at: [0, 0.125, 0], material: moss}
  - {name: MossTuft, slot: Trim, size: [0.75, 0.25, 0.75], at: [-0.5, 0.375, 0.5], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
