---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Pedestal
name: Shrine pedestal
world: 0
kind: prop
status: build
height: 1.625
blocks: 12
tris: 144
budget: 260
collision: Hull
footprint: [5, 5, 1.625]
palette: ["#D8D2BC", "#B9B29A", "#FFFFFF", "#9BE7FF"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Pedestal/Pedestal.glb"
---
# Shrine pedestal (every world)

The pedestal at the heart of every shrine: three stepped tiers of pale stone with four corner posts, a glowing rune on each side of the middle tier and a lit seal on its top where the Field Notes finale happens.

- **Cells**: `stone` cobbles (the base and posts a step darker in the second colour); the runes and seal `glow` (Neon)
- **Footprint**: 5 x 5 x 1.625 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 5 x 5 x 1.5.
- **Budget**: 260 triangles (the estimate before culling is 144); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # three tiers and four corner posts
  - {name: Base, slot: BodyDark, size: [5, 0.5, 5], at: [0, 0.25, 0], material: stone}
  - {name: Mid, slot: Body, size: [4, 0.5, 4], at: [0, 0.75, 0], material: stone}
  - {name: Top, slot: Body, size: [3, 0.5, 3], at: [0, 1.25, 0], material: stone}
  - {name: Corner, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [2.25, 0.875, -2.25], mirror: x, material: stone}
  - {name: CornerBack, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [2.25, 0.875, 2.25], mirror: x, material: stone}
  # runes and the seal
  - {name: Rune, slot: Glow, size: [1.5, 0.25, 0.125], at: [0, 0.75, -2.0625]}
  - {name: RuneBack, slot: Glow, size: [1.5, 0.25, 0.125], at: [0, 0.75, 2.0625]}
  - {name: RuneSide, slot: Glow, size: [0.125, 0.25, 1.5], at: [2.0625, 0.75, 0], mirror: x}
  - {name: Seal, slot: Glow, size: [1, 0.125, 1], at: [0, 1.5625, 0]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
