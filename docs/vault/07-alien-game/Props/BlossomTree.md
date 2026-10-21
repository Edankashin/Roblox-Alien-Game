---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: BlossomTree
name: Blossom tree
world: 1
kind: prop
status: build
height: 11.25
blocks: 20
tris: 240
budget: 600
collision: Box
footprint: [9, 6.625, 11.25]
palette: ["#FF9EC4", "#6B3F2A", "#FFE3EE"]
roles: [body, second, accent]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/BlossomTree/BlossomTree.glb"
---
# Blossom tree (World 1 Verdant)

A cherry-pink storybook tree for the meadow's soft corners: a leaning trunk that forks into two arms, a crown of pink blossom clumps with pale sprig cells, petals lying in little pink patches round its roots and two caught mid-fall. It is the meadow's one big splash of pink, placed sparingly so it stays a treat.

- **Cells**: `wood` on the trunk and arms; `moss` tufts in blossom pink on the crown (the pale accent as the sprig); the fallen petals plain cells one row thin
- **Scale**: the crown's underside at 6 studs; a smaller tree than the oak, so it can stand by the pond and the path
- **Footprint**: 9 x 6.625 x 11.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 600 triangles (the estimate before culling is 240); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the trunk leaning into two arms
  - {name: Trunk, slot: BodyDark, size: [1.25, 4.5, 1.25], at: [0, 2.25, 0], material: wood}
  - {name: Lean, slot: BodyDark, size: [1, 2.5, 1], at: [0.5, 5.25, 0], rot: [0, 0, -15], material: wood}
  - {name: Root, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.875, 0.25, 0], mirror: x, material: wood}
  - {name: Arm, slot: BodyDark, size: [2, 0.5, 0.5], at: [-1.5, 5.25, 0.25], rot: [0, 0, -20], material: wood}
  - {name: ArmR, slot: BodyDark, size: [0.5, 0.5, 1.75], at: [1, 6, -1.25], rot: [20, 0, 0], material: wood}
  # the blossom crown
  - {name: Crown, slot: Body, size: [6, 2.25, 5.5], at: [0.25, 7.625, 0], material: moss}
  - {name: CrownTop, slot: Body, size: [4, 1.5, 4], at: [0.5, 9.5, 0.25], material: moss}
  - {name: Puff, slot: Body, size: [2.5, 1.75, 2.5], at: [-3.25, 6.875, 0.5], material: moss}
  - {name: PuffR, slot: Body, size: [2, 1.5, 2.25], at: [3.5, 7.25, -1], material: moss}
  - {name: PuffFront, slot: Body, size: [2.25, 1.25, 1.25], at: [0, 6.875, -3.25], material: moss}
  - {name: PuffTop, slot: Body, size: [1.75, 1, 1.75], at: [-0.75, 10.75, 0.75], material: moss}
  # petals on the ground and in the air, buds
  - {name: Petals, slot: Accessory, size: [1.5, 0.125, 1], at: [2.25, 0.0625, -1.5], material: skin}
  - {name: Petals2, slot: Accessory, size: [1, 0.125, 1.25], at: [-2, 0.0625, 0.75], material: skin}
  - {name: Petals3, slot: Accessory, size: [0.75, 0.125, 0.75], at: [0.5, 0.0625, 2.25], material: skin}
  - {name: Petals4, slot: Accessory, size: [0.5, 0.125, 0.5], at: [-1, 0.0625, -2.25], material: skin}
  - {name: Falling, slot: Accessory, size: [0.25, 0.25, 0.25], at: [2.75, 4, -2.25]}
  - {name: Falling2, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-3, 3.25, -1]}
  - {name: Bud, slot: Accessory, size: [0.5, 0.5, 0.5], at: [1.5, 8.5, -2.875]}
  - {name: Bud2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-2.25, 9, -1.75]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
