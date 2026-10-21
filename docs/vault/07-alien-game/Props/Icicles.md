---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Icicles
name: Icicle fringe
world: 2
kind: prop
status: build
height: 3.5
blocks: 9
tris: 96
budget: 200
collision: None
footprint: [4, 1.375, 3.5]
palette: ["#BFEBFA", "#7F8E99", "#F2F6FA", "#9FE3FF", "#E8FAFF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Icicles/Icicles.glb"
---
# Icicle fringe (World 2 Frostbyte)

A fringe of six icicles hanging from an ice ledge with snow on top, the longest 2.5 studs, and one lit drop about to fall. Meant for the underside of a cliff edge, a cave lip or a roof: the pivot is at the drop's foot, so stand it 3.5 studs under the ledge top it hangs from (its snow then lies flush with that top).

- **Cells**: `ice` cones hanging point down (rule 5's ice facet), a paler ice Trim slot; `snow` on top; the drop `glow`
- **Footprint**: 4 x 1.375 x 3.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 200 triangles (the estimate before culling is 96); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the ledge and its snow
  - {name: Ledge, slot: Body, size: [4, 0.5, 1.25], at: [0, 2.75, 0], material: ice}
  - {name: Snow, slot: Accessory, size: [4, 0.5, 1.25], at: [0, 3.25, 0.125], material: snow}
  # six icicles and a drop
  - {name: Icicle, slot: Trim, size: [0.375, 1, 0.375], at: [-1.5625, 2, -0.3125], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle2, slot: Trim, size: [0.375, 2, 0.375], at: [-1.0625, 1.5, -0.3125], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle3, slot: Trim, size: [0.375, 1.5, 0.375], at: [-0.3125, 1.75, -0.3125], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle4, slot: Trim, size: [0.375, 2.5, 0.375], at: [0.1875, 1.25, -0.3125], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle5, slot: Trim, size: [0.375, 1.75, 0.375], at: [0.9375, 1.625, -0.3125], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle6, slot: Trim, size: [0.375, 1.25, 0.375], at: [1.4375, 1.875, -0.3125], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Drip, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 0.0625, -0.1875]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
