---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Reeds
name: Pond reeds
world: 1
kind: prop
status: build
height: 3.59
blocks: 9
tris: 108
budget: 200
collision: None
footprint: [1.758, 1.417, 3.59]
palette: ["#7DB04A", "#4F7F3A", "#7B4A2D"]
roles: [body, second, accent]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Reeds/Reeds.glb"
---
# Pond reeds (World 1 Verdant)

A clump of reeds for the pond's edge: five green reeds leaning a little out of a mossy tuft, two brown cattails and a flat blade. No collision; players wade through.

- **Cells**: plain cells on the reeds (one cell across), `moss` on the tuft
- **Tilt**: each reed leans 10 to 18 degrees (rule 1), so the clump fans out
- **Footprint**: 1.758 x 1.417 x 3.59 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 200 triangles (the estimate before culling is 108); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the tuft
  - {name: Base, slot: BodyDark, size: [1.25, 0.25, 1], at: [0, 0.125, 0], material: moss}
  # five reeds fanning out
  - {name: Reed, slot: Body, size: [0.25, 2.25, 0.25], at: [-0.375, 1.375, -0.25], rot: [0, 0, 12]}
  - {name: Reed2, slot: Body, size: [0.25, 2.75, 0.25], at: [0.25, 1.625, 0.125], rot: [0, 0, -10]}
  - {name: Reed3, slot: Body, size: [0.25, 1.75, 0.25], at: [0, 1.125, -0.375], rot: [12, 0, 0]}
  - {name: Reed4, slot: Body, size: [0.25, 1.5, 0.25], at: [0.5, 1, -0.25], rot: [0, 0, -18]}
  - {name: Reed5, slot: Body, size: [0.25, 2, 0.25], at: [-0.25, 1.25, 0.375], rot: [-14, 0, 0]}
  # cattails and a blade
  - {name: Cattail, slot: Accessory, size: [0.375, 0.625, 0.375], at: [0.5625, 3.25, 0.125], rot: [0, 0, -10]}
  - {name: Cattail2, slot: Accessory, size: [0.375, 0.5, 0.375], at: [-0.625, 2.6875, -0.25], rot: [0, 0, 12]}
  - {name: Blade, slot: Body, size: [0.125, 1.25, 0.375], at: [0.625, 0.875, 0.25], rot: [0, 0, -20]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
