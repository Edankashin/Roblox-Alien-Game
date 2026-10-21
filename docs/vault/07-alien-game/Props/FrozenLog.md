---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: FrozenLog
name: Frozen log
world: 2
kind: prop
status: build
height: 1.75
blocks: 8
tris: 92
budget: 300
collision: Hull
footprint: [4.625, 2.25, 1.75]
palette: ["#F2F6FA", "#4A3A2E", "#F2F6FA", "#BFEBFA"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/FrozenLog/FrozenLog.glb"
---
# Frozen log (World 2 Frostbyte)

Frostbyte's fallen log: dark bark in grain rows under a long blanket of snow, its cut end glazed in ice, two icicles hanging off its front and a bank of snow against it.

- **Cells**: `wood` along the log, `snow` on top (two cells tall), `ice` on the glazed end and the icicles
- **Footprint**: 4.625 x 2.25 x 1.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 300 triangles (the estimate before culling is 92); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the log, a stub, the iced end
  - {name: Log, slot: BodyDark, size: [4.5, 1.25, 1.25], at: [0, 0.625, 0], material: wood}
  - {name: Stub, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [-1, 1.5, 0], material: wood}
  - {name: End, slot: Trim, size: [0.125, 1, 1], at: [2.3125, 0.625, 0], material: ice}
  # snow on it and against it
  - {name: Snow, slot: Accessory, size: [3.75, 0.5, 1.25], at: [-0.125, 1.5, 0], material: snow}
  - {name: SnowEnd, slot: Accessory, size: [1.25, 0.25, 1], at: [1.75, 1.375, 0], material: snow}
  - {name: Bank, slot: Accessory, size: [1.5, 0.5, 1], at: [-1.25, 0.25, -1.125], material: snow}
  # icicles
  - {name: Icicle, slot: Trim, size: [0.25, 0.5, 0.25], at: [0.5, 0.375, -0.75], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle2, slot: Trim, size: [0.25, 0.375, 0.25], at: [1.25, 0.4375, -0.75], rot: [180, 0, 0], shape: cone6, material: ice}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
