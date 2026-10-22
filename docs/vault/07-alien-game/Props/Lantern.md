---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Lantern
name: Path lantern
world: 1
kind: prop
status: build
height: 3.25
blocks: 12
tris: 144
budget: 260
collision: Box
footprint: [2.25, 1.25, 3.25]
palette: ["#4A3B2E", "#7B4A2D", "#5E9E3A", "#C9A15B", "#FF9A2E"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Lantern/Lantern.glb"
---
# Path lantern (World 1 Verdant)

A lantern on a wooden post for the meadow's paths and the camp's edge: a crooked arm, a brass hook and a little iron cage with a roof, and inside it a block of warm light. At dusk it is what the eye finds first.

- **Cells**: `wood` on the post and arm; `metal` on the roof and frame; the light a `glow` block (Neon in the game, with a PointLight from the world worker if wanted)
- **Light**: the PointLight is the warm FFC86B, World 1's lamp colour, while the lamp cell is a deeper amber FF9A2E (the cell in FFC86B read pale cream at a distance at night, Mac job 58); Frostbyte's IceLantern uses the same warmth as its one contrast
- **Footprint**: 2.25 x 1.25 x 3.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 260 triangles (the estimate before culling is 144); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the post, its foot, the arm and a hook
  - {name: Post, slot: BodyDark, size: [0.5, 3, 0.5], at: [0, 1.5, 0], material: wood}
  - {name: Foot, slot: BodyDark, size: [1, 0.25, 1], at: [0, 0.125, 0], material: wood}
  - {name: Arm, slot: BodyDark, size: [1.5, 0.25, 0.25], at: [0.5, 3.125, 0], material: wood}
  - {name: Hook, slot: Trim, size: [0.125, 0.25, 0.125], at: [1.0625, 2.875, 0.0625]}
  # the lamp: a roof, a frame, four corner bars and the light
  - {name: Roof, slot: Body, size: [1, 0.25, 1], at: [1, 2.625, 0], material: metal}
  - {name: Frame, slot: Body, size: [0.875, 0.125, 0.875], at: [1.0625, 1.6875, -0.0625], material: metal}
  - {name: Corner, slot: Body, size: [0.125, 0.75, 0.125], at: [1.4375, 2.125, -0.4375]}
  - {name: Corner2, slot: Body, size: [0.125, 0.75, 0.125], at: [0.6875, 2.125, -0.4375]}
  - {name: Corner3, slot: Body, size: [0.125, 0.75, 0.125], at: [1.4375, 2.125, 0.3125]}
  - {name: Corner4, slot: Body, size: [0.125, 0.75, 0.125], at: [0.6875, 2.125, 0.3125]}
  - {name: Light, slot: Glow, size: [0.625, 0.75, 0.625], at: [1.0625, 2.125, 0.0625]}
  # a tuft at the foot
  - {name: Tuft, slot: Accessory, size: [0.75, 0.25, 0.5], at: [-0.375, 0.375, -0.5], material: moss}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
