---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: ShipHull
name: Landing hull
world: 0
kind: prop
status: build
height: 1.25
blocks: 19
tris: 228
budget: 400
collision: Hull
footprint: [12, 20, 1.25]
palette: ["#7A8494", "#3A4049", "#FFC83D", "#B8C2CF", "#68C9FE"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/ShipHull/ShipHull.glb"
---
# Landing hull (every world)

The ship's landing hull under the camp's ship (Camp.Props.ship): a riveted steel deck 11 by 19 on four skids inside a polished rail, yellow hazard stripes at both ends and a landing cross in the middle, cyan landing lights at the corners and mid-sides. The ship's modules build up on top of it.

- **Cells**: `metal` panels, seams and rivets on the deck, skids and rail (the rail on the glossy Trim slot); the paint plain cells; the lights `glow`
- **Fit**: 12 x 20 studs like the landing slab (Camp.ShipBaseSize) it stands on; 1.25 studs tall
- **Footprint**: 12 x 20 x 1.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 12 x 20 x 1.15.
- **Budget**: 400 triangles (the estimate before culling is 228); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # skids, the deck and its rail
  - {name: Skid, slot: BodyDark, size: [1, 0.375, 4], at: [4, 0.1875, 6.5], mirror: x, material: metal}
  - {name: SkidFront, slot: BodyDark, size: [1, 0.375, 4], at: [4, 0.1875, -6.5], mirror: x, material: metal}
  - {name: Deck, slot: Body, size: [11, 0.5, 19], at: [0, 0.625, 0], material: metal}
  - {name: Rail, slot: Trim, size: [0.5, 0.625, 20], at: [5.75, 0.6875, 0], mirror: x, material: metal}
  - {name: RailFront, slot: Trim, size: [11, 0.625, 0.5], at: [0, 0.6875, -9.75], material: metal}
  - {name: RailBack, slot: Trim, size: [11, 0.625, 0.5], at: [0, 0.6875, 9.75], material: metal}
  # hazard stripes and the landing cross
  - {name: Hazard, slot: Accessory, size: [11, 0.125, 0.5], at: [0, 0.9375, -8.75]}
  - {name: HazardBack, slot: Accessory, size: [11, 0.125, 0.5], at: [0, 0.9375, 8.75]}
  - {name: Mark, slot: Accessory, size: [4, 0.125, 0.5], at: [0, 0.9375, 0]}
  - {name: MarkCross, slot: Accessory, size: [0.5, 0.125, 4], at: [0, 0.9375, 0]}
  # landing lights
  - {name: Light, slot: Glow, size: [0.5, 0.25, 0.5], at: [5.75, 1.125, -9.75], mirror: x}
  - {name: LightBack, slot: Glow, size: [0.5, 0.25, 0.5], at: [5.75, 1.125, 9.75], mirror: x}
  - {name: LightMid, slot: Glow, size: [0.25, 0.125, 1], at: [5.75, 1.0625, 0], mirror: x}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
