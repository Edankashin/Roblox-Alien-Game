---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceCrystalCluster
name: Ice crystal cluster
world: 2
kind: prop
status: build
height: 4.25
blocks: 13
tris: 146
budget: 420
collision: Hull
footprint: [2.75, 2.403, 4.25]
palette: ["#BFEBFA", "#7F8E99", "#F2F6FA", "#68C9FE"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/IceCrystalCluster/IceCrystalCluster.glb"
---
# Ice crystal cluster (World 2 Frostbyte)

A cluster of five ice crystals fanning out of a snowy rock, each a prism with a six-sided point, and a cyan lit heart inside the tallest. The crystals that dot Frostbyte's snowfield and the Ice Cave, glowing softly at night.

- **Cells**: `ice` on the prisms and points; the heart `glow` in the crystal glow 68C9FE (Frostbyte data's shrine glow); the rock `stone`
- **Tilt**: the outer crystals lean 10 to 22 degrees (rule 1)
- **Footprint**: 2.75 x 2.403 x 4.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 420 triangles (the estimate before culling is 146); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the rock and a snow patch
  - {name: Rock, slot: BodyDark, size: [2.75, 0.75, 2.25], at: [0, 0.375, 0], material: stone}
  - {name: Snow, slot: Accessory, size: [1.5, 0.25, 1.25], at: [-0.5, 0.875, 0.375], material: snow}
  # five crystals and their points
  - {name: Crystal, slot: Body, size: [0.75, 2.75, 0.75], at: [0, 2.125, 0], material: ice}
  - {name: Crystal2, slot: Body, size: [0.5, 1.75, 0.5], at: [0.75, 1.625, -0.25], rot: [-12, 0, -20], material: ice}
  - {name: Crystal3, slot: Body, size: [0.625, 2, 0.625], at: [-0.75, 1.75, -0.125], rot: [10, 0, 18], material: ice}
  - {name: Crystal4, slot: Body, size: [0.5, 1.5, 0.5], at: [0.25, 1.5, 0.75], rot: [-22, 0, 0], material: ice}
  - {name: Crystal5, slot: Body, size: [0.375, 1.25, 0.375], at: [-0.5, 1.375, -0.75], rot: [20, 0, 10], material: ice}
  - {name: Point, slot: Body, size: [0.75, 0.75, 0.75], at: [0, 3.875, 0], shape: cone6, material: ice}
  - {name: Point2, slot: Body, size: [0.5, 0.5, 0.5], at: [1.125, 2.6875, -0.5], rot: [-12, 0, -20], shape: cone6, material: ice}
  - {name: Point3, slot: Body, size: [0.625, 0.625, 0.625], at: [-1.125, 3, 0.125], rot: [10, 0, 18], shape: cone6, material: ice}
  - {name: Point4, slot: Body, size: [0.5, 0.5, 0.5], at: [0.25, 2.4375, 0.375], rot: [-22, 0, 0], shape: cone6, material: ice}
  - {name: Point5, slot: Body, size: [0.375, 0.375, 0.375], at: [-0.625, 2.125, -0.5], rot: [20, 0, 10], shape: cone6, material: ice}
  # a lit heart
  - {name: Heart, slot: Glow, size: [0.375, 1.5, 0.375], at: [-0.0625, 1.75, -0.3125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
