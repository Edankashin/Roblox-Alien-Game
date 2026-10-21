---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SnowDrift
name: Snow drift
world: 2
kind: prop
status: build
height: 1.625
blocks: 6
tris: 72
budget: 160
collision: None
footprint: [4.75, 3, 1.625]
palette: ["#F2F6FA", "#B9CADA", "#FFFFFF"]
roles: [body, second, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/SnowDrift/SnowDrift.glb"
---
# Snow drift (World 2 Frostbyte)

A soft drift of snow: three stepped layers rising to a crest on one side with a lip curling off the other, and two glittering cells. Scattered over the snowfield to break the flat ground; no collision, players walk through it.

- **Cells**: `snow` (each layer half a stud tall, so the drift lip covers its side over the packed snow); the glints `glow` in white
- **Footprint**: 4.75 x 3 x 1.625 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 160 triangles (the estimate before culling is 72); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # three layers, a crest and a lip, two glints
  - {name: Drift, slot: Body, size: [4.5, 0.5, 3], at: [0, 0.25, 0], material: snow}
  - {name: Rise, slot: Body, size: [3.25, 0.5, 2.25], at: [0.5, 0.75, 0.25], material: snow}
  - {name: Crest, slot: Body, size: [1.75, 0.5, 1.25], at: [1, 1.25, 0.5], material: snow}
  - {name: Lip, slot: Body, size: [1.5, 0.25, 1.25], at: [-1.75, 0.625, -0.5], material: snow}
  - {name: Sparkle, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.75, 1.5625, 0.25]}
  - {name: Sparkle2, slot: Glow, size: [0.25, 0.125, 0.25], at: [-1.25, 0.5625, 1]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
