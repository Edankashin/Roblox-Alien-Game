---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Campfire
name: Campfire
world: 1
kind: prop
status: build
height: 3.125
blocks: 18
tris: 216
budget: 400
collision: Box
collision_slots: {Body: None, Glow: None}
footprint: [3, 3, 3.125]
palette: ["#FF8A2A", "#7B4A2D", "#FFE36B", "#8E8E86", "#FFD34D"]
roles: [body, second, accent, trim, glow]
render: "[[placeholder_props_v1.jpg]]"
glb: "assets/models/props/Campfire/Campfire.glb"
---
# Campfire (World 1 Verdant, the camp)

The camp's fire north-east of the deck, ringed by the three log seats: eight stones round a bed of ash, two crossed logs, and a
flame of lit tongues with a glowing core showing on all four sides and two sparks above it. The first warm thing a player sees at
dusk; the PointLight stays the recipe's (data/WorldKit `Campfire` light), carried onto the mesh by Services/Meadow.

- **Cells**: `stone` on the ring; `dirt` (grey) on the ash; `wood` on the logs (grain along, rings on the cut ends); `ember` on the
  flame (tongues a step up from its foot, sparks in the accent yellow); the core and the sparks `glow`
- **Collision**: `Box` on the stones and the logs; the flame and the glow none
- **Footprint**: 3 x 3 x 3.125 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here (the landmark contract).
- **Budget**: 400 triangles; collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # a ring of eight stones and the ash bed
  - {name: Stone, slot: Trim, size: [0.75, 0.5, 0.5], at: [0, 0.25, -1.25], material: stone}
  - {name: Stone2, slot: Trim, size: [0.75, 0.375, 0.5], at: [0.125, 0.1875, 1.25], material: stone}
  - {name: Stone3, slot: Trim, size: [0.5, 0.5, 0.75], at: [1.25, 0.25, 0], material: stone}
  - {name: Stone4, slot: Trim, size: [0.5, 0.375, 0.625], at: [-1.25, 0.1875, -0.0625], material: stone}
  - {name: Stone5, slot: Trim, size: [0.5, 0.375, 0.5], at: [0.875, 0.1875, -0.875], material: stone}
  - {name: Stone6, slot: Trim, size: [0.5, 0.5, 0.5], at: [-0.875, 0.25, -0.875], material: stone}
  - {name: Stone7, slot: Trim, size: [0.5, 0.375, 0.5], at: [0.875, 0.1875, 0.875], material: stone}
  - {name: Stone8, slot: Trim, size: [0.5, 0.375, 0.5], at: [-0.875, 0.1875, 0.875], material: stone}
  - {name: Ash, slot: Trim, size: [1.5, 0.125, 1.5], at: [0, 0.0625, 0], material: dirt}
  # two crossed logs
  - {name: Log, slot: BodyDark, size: [2, 0.5, 0.5], at: [0, 0.375, 0], material: wood}
  - {name: Log2, slot: BodyDark, size: [0.5, 0.375, 1.75], at: [0, 0.8125, 0], material: wood}
  # the flame: a block of tongues, two licks, a lit core through it and two sparks
  - {name: Flame, slot: Body, size: [1, 1, 1], at: [0, 1.5, 0], material: ember}
  - {name: Flame2, slot: Body, size: [0.5, 0.75, 0.5], at: [0.25, 2.375, 0], material: ember}
  - {name: Flame3, slot: Body, size: [0.5, 0.5, 0.5], at: [-0.375, 2.25, -0.125], material: ember}
  - {name: Core, slot: Glow, size: [0.5, 0.5, 1.25], at: [0, 1.25, 0]}
  - {name: Core2, slot: Glow, size: [1.25, 0.5, 0.5], at: [0, 1.75, 0]}
  - {name: Spark, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.4375, 3.0625, -0.1875]}
  - {name: Spark2, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.3125, 2.8125, 0.3125]}
```

## Renders

On the placeholder props sheet: ![[placeholder_props_v1.jpg]]

## Reviews

- 2026-10-22, placeholder props worker. First block-cell build: it replaces the block placeholder of data/WorldKit (Studio 2026-10-22: 22 placeholders in World 1, 10 in World 2). Status build: waiting for Ethan's look at the sheet.
