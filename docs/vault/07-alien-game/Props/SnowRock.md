---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SnowRock
name: Snow rock
world: 2
kind: prop
status: concept
height: 2.75
blocks: 6
tris: 72
palette: ["#A9B7C0", "#7E8C99", "#F2F6FA"]
roles: [body, second, accent]
render: "[[world2_scene_v1.jpg]]"
glb: ""
---
# Snow rock (World 2 Frostbyte)

A boulder in two steps with a darker pebble at its foot, a cap of snow on top and a drift banked against its windward side. Grey-blue from Frostbyte's rock colour (`src/shared/data/Frostbyte.luau`, `RockColor` A9B7C0). Rules: [[Blocky-Style]] "Environment".

- **Cells**: `stone` cobbles on the boulder, cap step and pebble; `snow` on the cap and the drift (each half a stud tall, so the snow lip covers its whole side). The snow is what makes it Frostbyte's rock rather than Verdant's: the same stone, under snow instead of moss.

## Parts

```yaml
parts:
  - {name: Boulder, slot: Body, size: [2.5, 1.5, 2], at: [0, 0.75, 0], material: stone}
  - {name: Cap, slot: Body, size: [1.5, 0.75, 1.25], at: [-0.25, 1.875, 0.125], material: stone}
  - {name: Pebble, slot: BodyDark, size: [1, 0.75, 1], at: [1.75, 0.375, -0.5], material: stone}
  - {name: SnowCap, slot: Accessory, size: [1.25, 0.5, 1], at: [-0.25, 2.5, 0.125], material: snow}
  - {name: SnowLedge, slot: Accessory, size: [1, 0.5, 0.75], at: [0.75, 1.75, 0.375], material: snow}
  - {name: Drift, slot: Accessory, size: [1.5, 0.5, 0.75], at: [-0.75, 0.25, -1.375], material: snow}
```

## Renders

In the Frostbyte diorama: ![[world2_scene_v1.jpg]]

## Reviews

- 2026-10-19, World 2 worker. First build: the cobbles read as stone and the cap, ledge and drift read as snow lying on it from the hero camera. Status concept.
