---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Crystal
name: Glow crystal
world: 1
kind: prop
status: concept
height: 3.75
blocks: 6
tris: 70
palette: ["#7FE3F0", "#6E6E7A", "#B6F3FF"]
roles: [body, second, glow]
render: "[[world1_scene_v1.jpg]]"
glb: ""
---
# Glow crystal (World 1 Verdant)

A crystal cluster on a stone seat: one tall spire lit from inside under a six-sided point, three shards leaning out of the seat. The one emissive prop of the meadow (glow is used sparingly: [[Blocky-Style]] "Cells"). It marks a key material node or the shrine; the meadow places it on the high ground at the back.

- **Cells**: `crystal` on the spire, point and shards (a light diagonal band every six cells, its edges a step lighter); the spire is on the Glow slot, so its diagonals glow; the seat in `stone`.
- **Light**: the diorama hangs a soft cyan point light at the spire (the in-game twin is a PointLight on the prop, as in Effects).

## Parts

```yaml
parts:
  - {name: Seat, slot: BodyDark, size: [2, 0.5, 2], at: [0, 0.25, 0], material: stone}
  - {name: Spire, slot: Glow, size: [0.75, 2.5, 0.75], at: [0, 1.75, 0], material: crystal}
  - {name: Tip, slot: Glow, size: [0.75, 0.75, 0.75], at: [0, 3.375, 0], shape: cone6, material: crystal}
  - {name: Shard, slot: Body, size: [0.5, 1.5, 0.5], at: [0.6875, 1.1875, -0.25], rot: [0, 0, -20], material: crystal}
  - {name: Shard2, slot: Body, size: [0.5, 1.25, 0.5], at: [-0.5625, 1.0625, 0.375], rot: [15, 0, 20], material: crystal}
  - {name: Shard3, slot: Body, size: [0.375, 0.75, 0.375], at: [-0.375, 0.8125, -0.625], rot: [-15, 0, 10], material: crystal}
```

## Renders

In the World 1 diorama: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build: the lit diagonals read as crystal; the leaning shards keep it from being a post. Status concept.
