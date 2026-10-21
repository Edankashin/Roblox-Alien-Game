---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceRock
name: Frost rock
world: 2
kind: prop
status: build
height: 3.25
blocks: 8
tris: 96
budget: 320
collision: Hull
footprint: [4.919, 3.339, 3.25]
palette: ["#A9B7C0", "#8796A0", "#F2F6FA", "#BFEBFA", "#BFF3FF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/IceRock/IceRock.glb"
---
# Frost rock (World 2 Frostbyte)

Frostbyte's everyday rock: a cool grey cobbled boulder with a top and a side lump, snow lying on top and on a ledge, and two ice shards breaking out of its front-right with one lit glint inside. Scattered about forty times a world.

- **Cells**: `stone` cobbles in the world's rock A9B7C0; `snow` caps two cells tall; the shards `ice` on its own diagonal; the glint `glow`
- **Footprint**: 4.919 x 3.339 x 3.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 4 x 4 x 3.
- **Budget**: 320 triangles (the estimate before culling is 96); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the boulder
  - {name: Rock, slot: Body, size: [3.5, 2, 3], at: [0, 1, 0], material: stone}
  - {name: Top, slot: Body, size: [2.5, 0.75, 2.25], at: [0.25, 2.375, -0.25], material: stone}
  - {name: Side, slot: Body, size: [1, 1.25, 1.5], at: [-2, 0.625, 0.5], material: stone}
  # snow on the top and a ledge
  - {name: Cap, slot: Accessory, size: [2.25, 0.5, 2], at: [0.25, 3, -0.125], material: snow}
  - {name: Ledge, slot: Accessory, size: [1.25, 0.5, 1.25], at: [-1.375, 2.25, 0.5], material: snow}
  # ice shards and a glint
  - {name: Shard, slot: Trim, size: [0.75, 1.75, 0.75], at: [1.5, 1.75, -1.25], rot: [-15, 0, -18], material: ice}
  - {name: Shard2, slot: Trim, size: [0.5, 1, 0.5], at: [2, 1, -0.25], rot: [0, 0, -22], material: ice}
  - {name: Glint, slot: Glow, size: [0.25, 0.25, 0.125], at: [1.5, 1.375, -1.6875]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
