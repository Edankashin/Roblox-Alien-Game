---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: GeyserCone
name: Geyser cone
world: 2
kind: prop
status: build
height: 8.625
blocks: 15
tris: 180
budget: 420
collision: Box
footprint: [6, 6, 8.625]
palette: ["#8C5A3C", "#4A2E1E", "#F2F6FA", "#D9A066", "#BFF3FF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/GeyserCone/GeyserCone.glb"
---
# Geyser cone (World 2 Frostbyte)

A small geyser of the Geyser Field: a mound of warm mineral rock in four steps, a wet amber rim round a dark crater with a lit pool at its bottom, mineral streaks running down its sides, and a puff of steam rising from it. The field's warm rock is the one place in Frostbyte that is not blue.

- **Cells**: `stone` cobbles on the mound; the rim and streaks `crystal` (glossy, wet); the steam plain white cells; the pool `glow`
- **Footprint**: 6 x 6 x 8.625 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 6 x 6 x 7.
- **Budget**: 420 triangles (the estimate before culling is 180); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the mound in four steps
  - {name: Tier1, slot: Body, size: [6, 1.5, 6], at: [0, 0.75, 0], material: stone}
  - {name: Tier2, slot: Body, size: [4.75, 1.5, 4.75], at: [0.125, 2.25, -0.125], material: stone}
  - {name: Tier3, slot: Body, size: [3.5, 1.5, 3.5], at: [0, 3.75, 0], material: stone}
  - {name: Tier4, slot: Body, size: [2.5, 1.25, 2.5], at: [0.125, 5.125, 0.125], material: stone}
  # the rim and crater
  - {name: RimFront, slot: Trim, size: [2.5, 0.5, 0.5], at: [0, 6, -1], material: crystal}
  - {name: RimBack, slot: Trim, size: [2.5, 0.5, 0.5], at: [0, 6, 1], material: crystal}
  - {name: RimSide, slot: Trim, size: [0.5, 0.5, 1.5], at: [1, 6, 0], mirror: x, material: crystal}
  - {name: Crater, slot: BodyDark, size: [1.5, 0.125, 1.5], at: [0, 5.8125, 0]}
  # streaks and the lit pool
  - {name: Streak, slot: Trim, size: [0.5, 1.25, 0.125], at: [0.5, 4.125, -1.3125], material: crystal}
  - {name: Streak2, slot: Trim, size: [0.125, 1.5, 0.5], at: [2.4375, 2.25, 0.5], material: crystal}
  - {name: Pool, slot: Glow, size: [0.75, 0.125, 0.75], at: [0, 5.9375, 0]}
  # steam
  - {name: Steam, slot: Accessory, size: [1.25, 0.75, 1.25], at: [0, 7, 0]}
  - {name: Steam2, slot: Accessory, size: [1, 0.75, 1], at: [0.25, 7.75, 0.125]}
  - {name: Steam3, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 8.375, 0.25]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
