---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Flower
name: Meadow flower
world: 1
kind: prop
status: concept
height: 1.125
blocks: 4
tris: 48
palette: ["#FF8FB0", "#2F7A4B", "#FFE36B"]
roles: [body, second, accent]
render: "[[world1_scene_v1.jpg]]"
glb: ""
---
# Meadow flower (World 1 Verdant)

A stud-high flower: a stem with one leaf, a square of petals and a yellow heart. At the world cell the petals are three cells across, so each flower is a little block of cells, never a smudge. The diorama scatters it in three petal colours (pink as drawn, sun yellow FFD34D and white F7F3EA), a body-colour swap per instance. Rules: [[Blocky-Style]] "Environment".

## Parts

```yaml
parts:
  - {name: Stem, slot: BodyDark, size: [0.25, 0.75, 0.25], at: [0, 0.375, 0]}
  - {name: Leaf, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [0.25, 0.3125, 0]}
  - {name: Petals, slot: Body, size: [0.75, 0.25, 0.75], at: [0, 0.875, 0]}
  - {name: Heart, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0, 1.0625, 0]}
```

## Renders

In the World 1 diorama: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build: reads as a flower from the hero camera, a dot of colour at the second angle. Status concept.
