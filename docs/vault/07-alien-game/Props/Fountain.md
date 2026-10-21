---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: Fountain
name: Garden fountain
world: 0
region: Home
kind: prop
status: build
height: 4.875
blocks: 29
tris: 348
budget: 700
collision: Hull
collision_slots: {Trim: None, Glow: None, Accessory: None}
footprint: [7.5, 7.5, 4.875]
palette: ["#CFC8B6", "#948C7A", "#5E9E3A", "#3FA2E6", "#BFF3FF"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/Fountain/Fountain.glb"
---
# Garden fountain (the home planet)

A stone garden fountain for the middle of the plot: a stepped octagonal basin with an overhanging darker rim, a column and a little bowl, water in both, a glowing spout that splashes and drops, two streams falling from the bowl, sparkles on the water and moss on the stones.

- **Cells**: `stone` on the basin, rim, column and bowl; `water` on both pools; `moss` on the tufts; the spout, the streams and the sparkles `glow` (a pale water-white)
- **Collision**: `Hull` on the stone (the basin and the bowl as two hulls: a player can hop up onto the rim); the water, moss and glow none
- **Footprint**: 7.5 x 7.5 x 4.875 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `Fountain`, 2 x 2 cells, 8 studs).
- **Budget**: 700 triangles (the estimate before culling is 348); collision `Hull` with `Trim` None, `Glow` None, `Accessory` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the basin: a stepped octagon of three blocks meeting edge to edge, its rim overhanging a quarter stud
  - {name: Basin, slot: Body, size: [5, 1.25, 7], at: [0, 0.625, 0], material: stone}
  - {name: BasinSide, slot: Body, size: [1, 1.25, 5], at: [3, 0.625, 0], mirror: x, material: stone}
  - {name: RimFront, slot: BodyDark, size: [5.5, 0.25, 1.25], at: [0, 1.375, -3.125], material: stone}
  - {name: RimBack, slot: BodyDark, size: [5.5, 0.25, 1.25], at: [0, 1.375, 3.125], material: stone}
  - {name: RimSide, slot: BodyDark, size: [1.25, 0.25, 5], at: [3.125, 1.375, 0], mirror: x, material: stone}
  - {name: Water, slot: Trim, size: [5, 0.125, 5], at: [0, 1.3125, 0], material: water}
  # the column, the bowl, its lip and its water
  - {name: Column, slot: Body, size: [1, 2, 1], at: [0, 2, 0], material: stone}
  - {name: Bowl, slot: Body, size: [2.5, 0.5, 2.5], at: [0, 3.25, 0], material: stone}
  - {name: LipFront, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 3.625, -1.125], material: stone}
  - {name: LipBack, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 3.625, 1.125], material: stone}
  - {name: LipSide, slot: BodyDark, size: [0.25, 0.25, 2], at: [1.125, 3.625, 0], mirror: x, material: stone}
  - {name: BowlWater, slot: Trim, size: [2, 0.125, 2], at: [0, 3.5625, 0], material: water}
  # the spout, the splash, the drops, the two streams and the sparkles on the water
  - {name: Spout, slot: Glow, size: [0.25, 1, 0.25], at: [0, 4.125, 0]}
  - {name: Splash, slot: Glow, size: [0.75, 0.25, 0.75], at: [0, 4.75, 0]}
  - {name: Drop, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.625, 4.375, 0], mirror: x}
  - {name: DropFront, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 4.375, -0.625]}
  - {name: Stream, slot: Glow, size: [0.125, 1.625, 0.125], at: [1.3125, 2.1875, 0.0625], mirror: x}
  - {name: Sparkle, slot: Glow, size: [0.25, 0.125, 0.25], at: [1.625, 1.4375, -1.5]}
  - {name: SparkleB, slot: Glow, size: [0.25, 0.125, 0.25], at: [-1.75, 1.4375, 1.125]}
  # moss on the rim and at the foot
  - {name: RimMoss, slot: Accessory, size: [0.75, 0.125, 0.5], at: [-1.5, 1.5625, -3.25], material: moss}
  - {name: RimMossB, slot: Accessory, size: [0.5, 0.125, 0.75], at: [3.25, 1.5625, 1.375], material: moss}
  - {name: FootMoss, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-3.5, 0.25, -1.25], material: moss}
  - {name: FootMossB, slot: Accessory, size: [0.75, 0.375, 0.5], at: [1.625, 0.1875, 3.5], material: moss}
  - {name: FootMossC, slot: Accessory, size: [0.5, 0.25, 0.5], at: [3.5, 0.125, 1.75], material: moss}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
