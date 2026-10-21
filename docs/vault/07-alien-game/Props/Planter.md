---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: Planter
name: Flower planter
world: 0
region: Home
kind: prop
status: build
height: 2.25
blocks: 17
tris: 204
budget: 320
collision: Box
collision_slots: {Accessory: None, Trim: None, Glow: None}
footprint: [2.5, 2.5, 2.25]
palette: ["#C08A55", "#6B4630", "#3F9B3A", "#FF8AD8", "#FFEF4A"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/Planter/Planter.glb"
---
# Flower planter (the home planet)

A raised wooden planter box with a rim of boards, dark soil, three leafy clumps, two pink flowers and one alien glowbud on a tall stem: a sprout from the worlds the player has been to, glowing gold at night.

- **Cells**: `wood` on the box and rim; `dirt` on the soil; `moss` on the leaves; plain cells on the petals; the glowbud and the flower hearts `glow`
- **Collision**: `Box` on the wooden box (the player hops onto it); the soil, leaves, flowers and glow none
- **Footprint**: 2.5 x 2.5 x 2.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `Planter`, 1 x 1 cell, 4 studs).
- **Budget**: 320 triangles (the estimate before culling is 204); collision `Box` with `Accessory` None, `Trim` None, `Glow` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the box, its rim of boards and the soil
  - {name: Box, slot: Body, size: [2.5, 0.75, 2.5], at: [0, 0.375, 0], material: wood}
  - {name: RimFront, slot: Body, size: [2.5, 0.25, 0.25], at: [0, 0.875, -1.125], material: wood}
  - {name: RimBack, slot: Body, size: [2.5, 0.25, 0.25], at: [0, 0.875, 1.125], material: wood}
  - {name: RimSide, slot: Body, size: [0.25, 0.25, 2], at: [1.125, 0.875, 0], mirror: x, material: wood}
  - {name: Soil, slot: BodyDark, size: [2, 0.125, 2], at: [0, 0.8125, 0], material: dirt}
  # three leafy clumps
  - {name: Clump, slot: Accessory, size: [0.75, 0.5, 0.75], at: [-0.5, 1.125, -0.375], material: moss}
  - {name: ClumpTall, slot: Accessory, size: [0.5, 0.75, 0.5], at: [0.5, 1.25, 0.375], material: moss}
  - {name: ClumpSmall, slot: Accessory, size: [0.5, 0.375, 0.5], at: [0.5, 1.0625, -0.5], material: moss}
  - {name: ClumpBack, slot: Accessory, size: [0.75, 0.375, 0.5], at: [-0.5, 1.0625, 0.5], material: moss}
  # two flowers with glowing hearts
  - {name: Flower, slot: Trim, size: [0.5, 0.25, 0.5], at: [-0.5, 1.5, -0.375]}
  - {name: Heart, slot: Glow, size: [0.25, 0.125, 0.25], at: [-0.5, 1.6875, -0.375]}
  - {name: FlowerTall, slot: Trim, size: [0.75, 0.25, 0.75], at: [0.5, 1.75, 0.375]}
  - {name: HeartTall, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.5, 1.9375, 0.375]}
  # the alien glowbud: a stem, a leaf and a gold bulb
  - {name: Stem, slot: Accessory, size: [0.125, 1, 0.125], at: [0.0625, 1.375, 0.0625], material: moss}
  - {name: Leaf, slot: Accessory, size: [0.375, 0.125, 0.125], at: [0.3125, 1.4375, 0.0625], material: moss}
  - {name: Bud, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.0625, 2.0625, 0.0625]}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
