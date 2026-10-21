---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: SteppingStone
name: Stepping stone
world: 1
region: Forest
kind: prop
status: build
height: 0.75
blocks: 4
tris: 48
budget: 160
collision: Hull
collision_slots: {Accessory: None}
footprint: [2.75, 2, 0.75]
palette: ["#8E88C6", "#6E69AE", "#2E8A78"]
roles: [body, second, accent]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/SteppingStone/SteppingStone.glb"
---
# Stepping stone (World 1 Verdant, Starhollow Forest)

A flat lavender-grey stone in two steps with moss at its edge, for the stream crossings: placed in a line half a stud out of the water, they lead the eye across as the reference's do.

- **Cells**: `stone`, the moss in `moss`
- **Walkable**: 0.75 studs tall, flat on top; Hull collision
- **Footprint**: 2.75 x 2 x 0.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 160 triangles (the estimate before culling is 48); collision `Hull` in `src/shared/data/Props.luau` with `Accessory` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the stone and its moss
  - {name: Slab, slot: Body, size: [2.5, 0.5, 2], at: [0, 0.25, 0], material: stone}
  - {name: SlabTop, slot: Body, size: [2, 0.25, 1.5], at: [0.25, 0.625, -0.25], material: stone}
  - {name: Moss, slot: Accessory, size: [1, 0.125, 0.75], at: [-0.75, 0.5625, 0.625], material: moss}
  - {name: Moss2, slot: Accessory, size: [0.5, 0.125, 0.5], at: [1.25, 0.5625, 0.75], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
