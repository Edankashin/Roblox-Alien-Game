---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceSpire
name: Ice spire
world: 2
kind: prop
status: build
height: 11.25
blocks: 12
tris: 142
budget: 600
collision: Box
footprint: [5.58, 4.444, 11.25]
palette: ["#BFEBFA", "#7F8E99", "#F2F6FA", "#7FE6FF"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/IceSpire/IceSpire.glb"
---
# Ice spire (World 2 Frostbyte)

A tall spire of clear ice standing out of a snowy rock: three stacked ice blocks narrowing to a point, three shards leaning out of its foot, and lit cores glowing inside it like trapped light. It is Frostbyte's tree-height landmark of the snowfield, the sparkle you see from the camp.

- **Cells**: `ice` (the other diagonal band, a sparkle in seventy, its edges lighter); the cores `glow` plates set into the faces; the base `stone` under `snow`
- **Footprint**: 5.58 x 4.444 x 11.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 6.7 x 5.4 x 10.
- **Budget**: 600 triangles (the estimate before culling is 142); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # a rock base under snow
  - {name: Base, slot: BodyDark, size: [4.5, 1, 4], at: [0, 0.5, 0], material: stone}
  - {name: BaseSnow, slot: Accessory, size: [3.75, 0.5, 3.25], at: [-0.25, 1.25, 0.25], material: snow}
  # the spire: three blocks, a point and three shards
  - {name: Spire, slot: Body, size: [2.5, 4, 2.25], at: [0, 3, 0], material: ice}
  - {name: Spire2, slot: Body, size: [1.75, 3, 1.5], at: [0.25, 6.5, -0.125], material: ice}
  - {name: Spire3, slot: Body, size: [1, 2, 1], at: [0.375, 9, -0.25], material: ice}
  - {name: Point, slot: Body, size: [0.75, 1.25, 0.75], at: [0.375, 10.625, -0.25], shape: cone6, material: ice}
  - {name: ShardR, slot: Body, size: [1, 3, 1], at: [2, 2.75, 0.25], rot: [0, 0, -20], material: ice}
  - {name: ShardL, slot: Body, size: [0.75, 2.25, 0.75], at: [-1.875, 2.5, -0.5], rot: [15, 0, 18], material: ice}
  - {name: ShardBack, slot: Body, size: [0.75, 2, 0.75], at: [-0.5, 2.5, 1.75], rot: [-20, 0, 0], material: ice}
  # lit cores in the ice
  - {name: Core, slot: Glow, size: [0.75, 1.5, 0.125], at: [0, 3.25, -1.1875]}
  - {name: Core2, slot: Glow, size: [0.5, 1, 0.125], at: [0.25, 6.75, -0.8125]}
  - {name: Core3, slot: Glow, size: [0.125, 0.75, 0.5], at: [1.3125, 3.75, 0.25]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
