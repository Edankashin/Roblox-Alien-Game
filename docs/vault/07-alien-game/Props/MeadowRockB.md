---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: MeadowRockB
name: Flat rock
world: 1
kind: prop
status: build
height: 2.125
blocks: 9
tris: 108
budget: 300
collision: Hull
footprint: [5.25, 3.5, 2.125]
palette: ["#9E9E8E", "#7C7C6E", "#5E9E3A", "#F7F3EA"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/MeadowRockB/MeadowRockB.glb"
---
# Flat rock (World 1 Verdant)

A low flat rock to sit on: a wide cobbled slab with a step, two loose pebbles, and a tuft of grass with two white daisies growing from a crack. Low enough to hop onto.

- **Cells**: `stone` cobbles; the tuft in `moss`; the daisies plain cells
- **Footprint**: 5.25 x 3.5 x 2.125 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 5 x 4 x 2.
- **Budget**: 300 triangles (the estimate before culling is 108); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the slab, a step, two pebbles
  - {name: Slab, slot: Body, size: [4.5, 1, 3.5], at: [0, 0.5, 0], material: stone}
  - {name: Step, slot: Body, size: [2.5, 0.75, 2], at: [0.75, 1.375, 0.5], material: stone}
  - {name: Pebble, slot: BodyDark, size: [1, 0.5, 1], at: [-1.75, 1.25, -0.75], material: stone}
  - {name: Pebble2, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [2.625, 0.25, -1.375], material: stone}
  # a grass tuft with two daisies
  - {name: Grass, slot: Accessory, size: [1.25, 0.25, 1], at: [-1.25, 1.125, 0.75], material: moss}
  - {name: Stem, slot: Accessory, size: [0.125, 0.5, 0.125], at: [-1.4375, 1.5, 0.5625]}
  - {name: Daisy, slot: Trim, size: [0.375, 0.375, 0.125], at: [-1.5625, 1.9375, 0.4375]}
  - {name: Stem2, slot: Accessory, size: [0.125, 0.375, 0.125], at: [-0.9375, 1.4375, 0.8125]}
  - {name: Daisy2, slot: Trim, size: [0.375, 0.375, 0.125], at: [-0.8125, 1.6875, 0.8125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
