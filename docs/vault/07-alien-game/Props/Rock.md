---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Rock
name: Meadow rock
world: 1
kind: prop
status: concept
height: 2.375
blocks: 4
tris: 48
palette: ["#9E9E8E", "#727266", "#6CCB5F"]
roles: [body, second, accent]
render: "[[world1_scene_v1.jpg]]"
glb: ""
---
# Meadow rock (World 1 Verdant)

A boulder in two steps with a darker pebble at its foot and a thin patch of moss on its cap. Grey from the meadow's rock colour (`src/shared/data/Meadow.luau` 8E8E8E, a step lighter so the cells read). Rules: [[Blocky-Style]] "Environment".

- **Cells**: `stone` cobbles on the boulder, cap and pebble (cracks a step and a half darker, each cobble a quarter step off its neighbours, the tops a half step up); `moss` on the patch, one cell of Verdant's motif on the world's rocks.

## Parts

```yaml
parts:
  - {name: Boulder, slot: Body, size: [2.5, 1.5, 2], at: [0, 0.75, 0], material: stone}
  - {name: Cap, slot: Body, size: [1.5, 0.75, 1.25], at: [-0.25, 1.875, 0.125], material: stone}
  - {name: Pebble, slot: BodyDark, size: [1, 0.75, 1], at: [1.75, 0.375, -0.5], material: stone}
  - {name: Moss, slot: Accessory, size: [1, 0.125, 0.75], at: [-0.25, 2.3125, 0.25], material: moss}
```

## Renders

In the World 1 diorama: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build: the cobbles read as stone at hero-shot distance and the moss patch ties the rock to the meadow. Status concept.
