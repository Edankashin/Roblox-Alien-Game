---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: GeyserVent
name: Great vent
world: 2
kind: prop
status: build
height: 10.75
blocks: 22
tris: 264
budget: 1200
collision: Hull
footprint: [14.5, 14.25, 10.75]
palette: ["#6B4A36", "#2A1A12", "#F2FBFF", "#D98A4E", "#9FE8FF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/GeyserVent/GeyserVent.glb"
---
# Great vent (World 2 Frostbyte)

The Great Vent at the Geyser Field's heart: a broad mound of warm rock in four steps, a wet amber rim round a pool of lit hot water, a tall column of steam blocks rising and leaning with the wind, cracks venting a smaller puff, and amber mineral terraces on its flanks. The cones of the field scatter round it.

- **Cells**: `stone` cobbles, the rim and terraces `crystal` (wet, glossy), the pool `glow` (a pale lit cyan), the cracks plain dark, the steam plain white
- **Footprint**: 14.5 x 14.25 x 10.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 14.2 x 14 x 10.65 (clearRadius 14).
- **Budget**: 1200 triangles (the estimate before culling is 264); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the mound in four steps
  - {name: Tier1, slot: Body, size: [14, 1.5, 14], at: [0, 0.75, 0], material: stone}
  - {name: Tier2, slot: Body, size: [11, 1.5, 11], at: [0.25, 2.25, -0.25], material: stone}
  - {name: Tier3, slot: Body, size: [8.5, 1.5, 8.5], at: [0, 3.75, 0], material: stone}
  - {name: Tier4, slot: Body, size: [6.5, 1.5, 6.5], at: [-0.25, 5.25, 0.25], material: stone}
  # the rim and the lit pool
  - {name: RimFront, slot: Trim, size: [5.5, 0.75, 0.75], at: [0, 6.375, -2.375], material: crystal}
  - {name: RimBack, slot: Trim, size: [5.5, 0.75, 0.75], at: [0, 6.375, 2.375], material: crystal}
  - {name: RimSide, slot: Trim, size: [0.75, 0.75, 4], at: [2.375, 6.375, 0], mirror: x, material: crystal}
  - {name: Pool, slot: Glow, size: [4, 0.25, 4], at: [0, 6.125, 0]}
  # cracks, terraces and boulders
  - {name: Crack, slot: BodyDark, size: [0.5, 1.5, 0.125], at: [-3, 2.25, -5.5625]}
  - {name: Crack2, slot: BodyDark, size: [0.125, 1.5, 0.5], at: [5.5625, 2.25, 1.5]}
  - {name: Crack3, slot: BodyDark, size: [0.5, 1.5, 0.125], at: [2, 3.75, -4.3125]}
  - {name: Terrace, slot: Trim, size: [3, 0.25, 1.5], at: [-4.5, 1.625, -5.5], material: crystal}
  - {name: Terrace2, slot: Trim, size: [1.5, 0.25, 2.5], at: [5.75, 3.125, -1.5], material: crystal}
  - {name: Boulder, slot: Body, size: [1.5, 1, 1.5], at: [6.5, 0.5, -6.5], material: stone}
  - {name: Boulder2, slot: Body, size: [1, 0.75, 1], at: [-6.75, 0.375, 5.5], material: stone}
  # the steam column and a side puff
  - {name: Steam, slot: Accessory, size: [3, 1.5, 3], at: [0, 7, 0]}
  - {name: Steam2, slot: Accessory, size: [2.5, 1.25, 2.5], at: [0.25, 8.375, 0.25]}
  - {name: Steam3, slot: Accessory, size: [2, 1, 2], at: [0.75, 9.5, 0.5]}
  - {name: Steam4, slot: Accessory, size: [1.25, 0.75, 1.25], at: [1.25, 10.375, 0.75]}
  - {name: Puff, slot: Accessory, size: [0.75, 0.75, 0.75], at: [-3, 3.75, -3.5]}
  - {name: Puff2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-3.25, 4.5, -3.75]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
