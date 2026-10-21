---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: BuildStation
name: Workbench
world: 0
kind: prop
status: build
height: 3.5
blocks: 16
tris: 192
budget: 320
collision: None
footprint: [5, 2.5, 3.5]
palette: ["#C99A5B", "#8B5A2B", "#8FD3FF", "#8A93A0", "#FFC86B"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/BuildStation/BuildStation.glb"
---
# Workbench (every world)

The camp's Build station (the Treehouse Bench of data/Camp.luau): a stout wooden workbench with a back board, a shelf of planks underneath, a steel vise and a hammer on top, a gear and a wrench hanging on the back board, a sky-blue blueprint spread out and a little warm bulb over it all.

- **Cells**: `wood` grain on the bench, `metal` on the tools (the Trim slot, glossy), the blueprint plain, the bulb `glow`
- **Fit**: 5 x 2.5 studs on its invisible collision block (CampRenderer.buildStations), so the mesh does not collide (None)
- **Footprint**: 5 x 2.5 x 3.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 5 x 3 x 2.5.
- **Budget**: 320 triangles (the estimate before culling is 192); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the bench, legs, shelf, planks and back board
  - {name: Top, slot: Body, size: [5, 0.5, 2.5], at: [0, 1.75, 0], material: wood}
  - {name: Leg, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [2, 0.75, -0.875], mirror: x, material: wood}
  - {name: LegBack, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [2, 0.75, 0.875], mirror: x, material: wood}
  - {name: Shelf, slot: Body, size: [4.5, 0.25, 2], at: [0, 0.5, 0], material: wood}
  - {name: Planks, slot: Body, size: [3, 0.5, 1], at: [-0.5, 0.875, 0.25], material: wood}
  - {name: Back, slot: BodyDark, size: [5, 1.25, 0.25], at: [0, 2.625, 1.125], material: wood}
  # tools, blueprint and bulb
  - {name: Vise, slot: Trim, size: [0.75, 0.5, 0.75], at: [1.875, 2.25, -0.5], material: metal}
  - {name: ViseJaw, slot: Trim, size: [0.25, 0.375, 0.25], at: [1.875, 2.6875, -0.875], material: metal}
  - {name: Handle, slot: BodyDark, size: [1.25, 0.25, 0.25], at: [-0.5, 2.125, -0.625], material: wood}
  - {name: Head, slot: Trim, size: [0.25, 0.375, 0.625], at: [0.25, 2.1875, -0.6875], material: metal}
  - {name: Gear, slot: Trim, size: [0.75, 0.75, 0.125], at: [-1.5, 2.875, 0.9375], material: metal}
  - {name: Wrench, slot: Trim, size: [0.125, 0.75, 0.125], at: [-0.4375, 2.875, 0.9375], material: metal}
  - {name: Blueprint, slot: Accessory, size: [1.25, 0.125, 1], at: [-1.625, 2.0625, -0.25]}
  - {name: Bulb, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 3.375, 1]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
