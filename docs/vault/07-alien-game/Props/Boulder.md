---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Boulder
name: Mossy boulder
world: 1
kind: prop
status: build
height: 5.5
blocks: 14
tris: 168
budget: 500
collision: Hull
footprint: [7.994, 5.5, 5.5]
palette: ["#9E9E8E", "#7C7C6E", "#6CB04A", "#F2E6D0", "#FFB86B"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Boulder/Boulder.glb"
---
# Mossy boulder (World 1 Verdant)

A big climbable boulder for the meadow's edges: three stacked masses, a spur and a leaning slab, moss pouring over its top with two vines down its face, and a pair of little warm-glowing mushrooms tucked on a ledge, the reward for climbing it.

- **Cells**: `stone` cobbles; `moss` on the cushion, the lip and the vines; the mushroom caps `glow` (Neon in the game), their stalks plain
- **Scale**: 5.5 studs, a little over the avatar: a hop onto the base, another onto the top
- **Footprint**: 7.994 x 5.5 x 5.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 500 triangles (the estimate before culling is 168); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the boulder: base, upper, crown, a spur, a leaning slab, a foot stone
  - {name: Base, slot: Body, size: [5.5, 2.5, 4.5], at: [0, 1.25, 0], material: stone}
  - {name: Upper, slot: Body, size: [4, 2, 3.5], at: [-0.5, 3.5, 0.25], material: stone}
  - {name: Crown, slot: Body, size: [2.5, 1, 2.25], at: [-0.25, 5, 0.25], material: stone}
  - {name: Spur, slot: BodyDark, size: [1.5, 1.5, 2], at: [3.25, 0.75, 0.5], material: stone}
  - {name: Lean, slot: BodyDark, size: [1.5, 2.5, 1.5], at: [-3, 1.4375, -1.25], rot: [0, 0, 12], material: stone}
  - {name: Foot, slot: BodyDark, size: [1, 0.5, 1], at: [1.5, 0.25, -2.75], material: stone}
  # moss and vines
  - {name: Moss, slot: Accessory, size: [3, 0.5, 2.5], at: [-0.5, 4.75, 0.75], material: moss}
  - {name: MossLip, slot: Accessory, size: [1.5, 0.25, 1.5], at: [1.5, 2.625, 1.25], material: moss}
  - {name: Vine, slot: Accessory, size: [0.5, 1.5, 0.25], at: [1, 1.75, -2.375], material: moss}
  - {name: Vine2, slot: Accessory, size: [0.5, 1, 0.25], at: [-1.25, 3, -1.625], material: moss}
  # two glowing mushrooms on a ledge
  - {name: Stalk, slot: Trim, size: [0.25, 0.5, 0.25], at: [2.25, 2.75, -1.25]}
  - {name: Cap, slot: Glow, size: [0.75, 0.25, 0.75], at: [2.25, 3.125, -1.25]}
  - {name: Stalk2, slot: Trim, size: [0.25, 0.375, 0.25], at: [2.75, 2.6875, -0.75]}
  - {name: Cap2, slot: Glow, size: [0.5, 0.25, 0.5], at: [2.75, 3, -0.75]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
