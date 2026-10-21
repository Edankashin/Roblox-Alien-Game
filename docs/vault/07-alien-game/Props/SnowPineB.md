---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SnowPineB
name: Slender snow pine
world: 2
kind: prop
status: build
height: 11.25
blocks: 16
tris: 188
budget: 500
collision: Box
footprint: [5.75, 5, 11.25]
palette: ["#2A5F54", "#4A3A2E", "#F2F6FA", "#BFEBFA"]
roles: [body, second, accent, trim]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/SnowPineB/SnowPineB.glb"
---
# Slender snow pine (World 2 Frostbyte)

A slimmer, taller pine for Frostbyte's treeline: five tiers stacked high, one bough reaching out with its own snow cap, two icicles hanging from the lower tiers and a fallen lump of snow at its foot. A darker green than SnowPine, so a stand of the two reads as a forest, not a pattern.

- **Cells**: `pine`, `snow`, `wood`; the icicles `ice` cones hanging point down (rule 5's ice facet)
- **Footprint**: 5.75 x 5 x 11.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 500 triangles (the estimate before culling is 188); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the trunk and five tiers with snow caps
  - {name: Trunk, slot: BodyDark, size: [0.75, 2, 0.75], at: [0, 1, 0], material: wood}
  - {name: Tier1, slot: Body, size: [5, 2, 5], at: [0, 3, 0], material: pine}
  - {name: Tier2, slot: Body, size: [4, 2, 4], at: [0.25, 5, 0], material: pine}
  - {name: Tier3, slot: Body, size: [3, 2, 3], at: [0, 7, 0.25], material: pine}
  - {name: Tier4, slot: Body, size: [2, 1.5, 2], at: [-0.25, 8.75, 0], material: pine}
  - {name: Tier5, slot: Body, size: [1.25, 1.25, 1.25], at: [0, 10.125, 0], material: pine}
  - {name: Tier1Snow, slot: Accessory, size: [4, 0.5, 4], at: [-0.125, 4.25, 0.125], material: snow}
  - {name: Tier2Snow, slot: Accessory, size: [3, 0.5, 3], at: [0.125, 6.25, 0.125], material: snow}
  - {name: Tier3Snow, slot: Accessory, size: [2, 0.5, 2], at: [-0.125, 8.25, 0.375], material: snow}
  - {name: Tier4Snow, slot: Accessory, size: [1, 0.5, 1], at: [-0.375, 9.75, 0.125], material: snow}
  - {name: Tier5Snow, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-0.125, 11, 0.125], material: snow}
  # a bough, a fallen lump, icicles
  - {name: Bough, slot: Body, size: [1.5, 1, 1.5], at: [2.5, 4.5, -0.5], material: pine}
  - {name: BoughSnow, slot: Accessory, size: [1, 0.5, 1], at: [2.5, 5.25, -0.5], material: snow}
  - {name: Lump, slot: Accessory, size: [1.5, 0.75, 1.25], at: [-1.5, 0.375, -1], material: snow}
  - {name: Icicle, slot: Trim, size: [0.25, 0.75, 0.25], at: [2, 1.625, -2], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle2, slot: Trim, size: [0.25, 0.5, 0.25], at: [-2, 1.75, 1.75], rot: [180, 0, 0], shape: cone6, material: ice}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
