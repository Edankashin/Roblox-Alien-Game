---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SnowPine
name: Snow pine
world: 2
kind: prop
status: build
height: 11.25
blocks: 15
tris: 180
budget: 500
collision: Box
footprint: [7, 7.125, 11.25]
palette: ["#2F6B5E", "#4A3A2E", "#F2F6FA", "#BFEBFA", "#BFF3FF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/SnowPine/SnowPine.glb"
---
# Snow pine (World 2 Frostbyte)

Frostbyte's pine: four tiers of needle rows narrowing to a snowy tip, every tier carrying a snow cap two cells tall, three frost crystals catching the light on its tiers and a small lit ice star at the very top that twinkles across the snowfield. A drift banks against its foot.

- **Cells**: `pine` needle rows (the snow accent as the dusting cell), `snow` caps whose lip covers their sides, `wood` on the trunk, `ice` on the frost crystals, the star `glow`
- **Scale**: the lowest tier at 2.5 studs: the avatar ducks to stand under it; trunk and tiers are separate MeshParts so the Box collision boxes each
- **Footprint**: 7 x 7.125 x 11.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 9 x 9 x 15.
- **Budget**: 500 triangles (the estimate before culling is 180); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the trunk and four tiers, each with its snow cap
  - {name: Trunk, slot: BodyDark, size: [1.25, 2.5, 1.25], at: [0, 1.25, 0], material: wood}
  - {name: Tier1, slot: Body, size: [7, 1.75, 7], at: [0, 3.375, 0], material: pine}
  - {name: Tier2, slot: Body, size: [5.5, 1.75, 5.5], at: [0.25, 5.125, -0.25], material: pine}
  - {name: Tier3, slot: Body, size: [4, 1.75, 4], at: [0, 6.875, 0], material: pine}
  - {name: Tier4, slot: Body, size: [2.5, 1.5, 2.5], at: [-0.25, 8.5, 0.25], material: pine}
  - {name: Tier1Snow, slot: Accessory, size: [6, 0.5, 6], at: [-0.125, 4.5, 0.125], material: snow}
  - {name: Tier2Snow, slot: Accessory, size: [4.5, 0.5, 4.5], at: [0.125, 6.25, -0.125], material: snow}
  - {name: Tier3Snow, slot: Accessory, size: [3, 0.5, 3], at: [-0.125, 8, 0.125], material: snow}
  - {name: Tier4Snow, slot: Accessory, size: [1.5, 0.5, 1.5], at: [-0.375, 9.5, 0.375], material: snow}
  # the tip and its lit star
  - {name: Tip, slot: Accessory, size: [1, 1, 1], at: [-0.375, 10.25, 0.375], material: snow}
  - {name: Star, slot: Glow, size: [0.5, 0.5, 0.5], at: [-0.375, 11, 0.375]}
  # frost crystals and a drift
  - {name: Frost, slot: Trim, size: [0.375, 0.375, 0.125], at: [1.9375, 3.6875, -3.5625], material: ice}
  - {name: Frost2, slot: Trim, size: [0.375, 0.375, 0.125], at: [-1.5625, 5.4375, -2.8125], material: ice}
  - {name: Frost3, slot: Trim, size: [0.125, 0.375, 0.375], at: [2.8125, 7.1875, 0.4375], material: ice}
  - {name: Drift, slot: Accessory, size: [2.5, 0.5, 1.75], at: [0.75, 0.25, -1.75], material: snow}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
