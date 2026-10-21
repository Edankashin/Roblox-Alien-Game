---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: HabitatVerdant
name: Verdant habitat
world: 0
region: Home
kind: prop
status: build
height: 2.75
blocks: 43
tris: 516
budget: 900
collision: Precise
collision_slots: {Accessory: None, Trim: None, Glow: None}
footprint: [12, 12, 2.75]
palette: ["#6FBF4A", "#7B4A2D", "#F49AD8", "#3FA2E6", "#FFC86B"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/HabitatVerdant/HabitatVerdant.glb"
---
# Verdant habitat (the home planet)

A little piece of World 1 Verdant on the home plot, where caught Verdant aliens roam on display: a meadow pad inside a wooden fence with a gate and a warm lantern under its beam, a pond, a feeding trough, two leafy bushes in pink flower, flowers and two glowbuds in the grass. The middle stays open: the aliens wander there (data/Habitats).

- **Cells**: `grass` on the pad; `wood` on the fence and the trough; `moss` on the bushes; `water` on the pond and in the trough; plain cells on the flowers; the lanterns and glowbuds `glow`
- **Collision**: `Precise` on the pad and the fence (a box or a hull of the fence ring would fill the pen; the gate stays open, the pad is walkable); flowers, water and glow none
- **The aliens on display** stand at `placeholder.height` (0.25 studs, the pad's top) and walk inside `WanderInsetStuds` (1 stud) of the footprint's edge, so the props inside the fence keep to the corners and under 1.25 studs tall
- **Footprint**: 12 x 12 x 2.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `HabitatVerdant`, 3 x 3 cells, 12 studs).
- **Budget**: 900 triangles (the estimate before culling is 516); collision `Precise` with `Accessory` None, `Trim` None, `Glow` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the pad: a meadow a quarter stud thick (the aliens on display stand on its top, data/HomeBuild placeholder.height)
  - {name: Pad, slot: Body, size: [12, 0.25, 12], at: [0, 0.125, 0], material: grass}
  # the fence: posts, two rails a side, a gate in the front with a beam
  - {name: CornerPost, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, -5.5], mirror: x, material: wood}
  - {name: CornerPostBack, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, 5.5], mirror: x, material: wood}
  - {name: MidPostBack, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [1.875, 1, 5.5], mirror: x, material: wood}
  - {name: MidPostSide, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, 1.875], mirror: x, material: wood}
  - {name: MidPostSideFront, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, -1.875], mirror: x, material: wood}
  - {name: GatePost, slot: BodyDark, size: [0.5, 2.25, 0.5], at: [1.875, 1.375, -5.5], mirror: x, material: wood}
  - {name: GateBeam, slot: BodyDark, size: [4.25, 0.25, 0.5], at: [0, 2.625, -5.5], material: wood}
  - {name: RailBack, slot: BodyDark, size: [10.5, 0.25, 0.25], at: [0, 0.875, 5.5], material: wood}
  - {name: RailSide, slot: BodyDark, size: [0.25, 0.25, 10.5], at: [5.5, 0.875, 0], mirror: x, material: wood}
  - {name: RailFront, slot: BodyDark, size: [3.125, 0.25, 0.25], at: [3.6875, 0.875, -5.5], mirror: x, material: wood}
  - {name: RailBackTop, slot: BodyDark, size: [10.5, 0.25, 0.25], at: [0, 1.375, 5.5], material: wood}
  - {name: RailSideTop, slot: BodyDark, size: [0.25, 0.25, 10.5], at: [5.5, 1.375, 0], mirror: x, material: wood}
  - {name: RailFrontTop, slot: BodyDark, size: [3.125, 0.25, 0.25], at: [3.6875, 1.375, -5.5], mirror: x, material: wood}
  # light: a lantern under the gate beam and one on each corner post
  - {name: GateLantern, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 2.25, -5.5]}
  - {name: PostLight, slot: Glow, size: [0.25, 0.25, 0.25], at: [5.5, 1.875, -5.5], mirror: x}
  - {name: PostLightBack, slot: Glow, size: [0.25, 0.25, 0.25], at: [5.5, 1.875, 5.5], mirror: x}
  # a pond in the back left corner and a feeding trough by the gate
  - {name: Pond, slot: Trim, size: [2.5, 0.125, 2], at: [-3.75, 0.3125, 3.5], material: water}
  - {name: Trough, slot: BodyDark, size: [1.5, 0.375, 0.75], at: [3.5, 0.4375, -3.75], material: wood}
  - {name: TroughWater, slot: Trim, size: [1.25, 0.125, 0.5], at: [3.5, 0.6875, -3.75], material: water}
  # two leafy bushes in the back corners with pink flowers, and flowers in the grass
  - {name: Bush, slot: Body, size: [1, 0.75, 1], at: [4.5, 0.625, 4.5], material: moss}
  - {name: BushLeft, slot: Body, size: [1.25, 0.5, 0.75], at: [-4.375, 0.5, -4.375], material: moss}
  - {name: BushFlower, slot: Accessory, size: [0.25, 0.25, 0.25], at: [4.375, 1.125, 4.375]}
  - {name: BushFlowerB, slot: Accessory, size: [0.25, 0.25, 0.25], at: [4.75, 1.125, 4.75]}
  - {name: BushLeftFlower, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-4.5, 0.875, -4.375]}
  - {name: Flower, slot: Accessory, size: [0.25, 0.25, 0.25], at: [2.875, 0.375, 2.375]}
  - {name: FlowerB, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.625, 0.375, -2.875]}
  - {name: FlowerC, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-4.375, 0.375, 1.125]}
  - {name: FlowerD, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.125, 0.375, 4.125]}
  - {name: Glowbud, slot: Glow, size: [0.25, 0.25, 0.25], at: [-2.875, 0.375, 1.875]}
  - {name: GlowbudB, slot: Glow, size: [0.25, 0.25, 0.25], at: [3.875, 0.375, 0.625]}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
