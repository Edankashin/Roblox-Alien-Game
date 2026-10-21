---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: MeadowTree
name: Meadow oak
world: 1
kind: prop
status: build
height: 12.75
blocks: 20
tris: 240
budget: 600
collision: Box
footprint: [10.5, 9, 12.75]
palette: ["#4CAF46", "#7B4A2D", "#FFD34D"]
roles: [body, second, accent]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/MeadowTree/MeadowTree.glb"
---
# Meadow oak (World 1 Verdant)

The meadow's everyday tree: a stout bark trunk on four root flares and two branches, a broad crown of moss-tufted leaf clumps that breaks its box on every side, and five sun-yellow fruits proud of the leaves. Read from the camp, it is a round green storybook tree; up close the leaves are moss tufts with lime and yellow sprig cells.

- **Cells**: the trunk, roots and branches in `wood` (grain rows, square rings on the cut ends); the crown in `moss` (clumps a full step apart, a lit fringe on every side, the yellow accent as the sprig cell)
- **Scale**: the crown's underside at 7 studs, so the 5-stud avatar walks under it; trunk and crown are separate MeshParts (BodyDark, Body), so the Box collision boxes each
- **Footprint**: 10.5 x 9 x 12.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 8 x 8 x 14.
- **Budget**: 600 triangles (the estimate before culling is 240); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # trunk, roots and branches: bark in grain rows
  - {name: Trunk, slot: BodyDark, size: [1.5, 6.5, 1.5], at: [0, 3.25, 0], material: wood}
  - {name: Root, slot: BodyDark, size: [0.75, 0.75, 0.75], at: [1.125, 0.375, 0], mirror: x, material: wood}
  - {name: RootFront, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [0, 0.25, -1.125], material: wood}
  - {name: RootBack, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [0.25, 0.25, 1.125], material: wood}
  - {name: Branch, slot: BodyDark, size: [1.75, 0.5, 0.5], at: [1.5, 5.25, -0.25], rot: [0, 0, 20], material: wood}
  - {name: BranchL, slot: BodyDark, size: [0.5, 0.5, 1.5], at: [-0.5, 5.75, 1.25], rot: [-18, 0, 0], material: wood}
  # the crown: a broad mass, a top, a cap and five clumps breaking the box
  - {name: Crown, slot: Body, size: [7, 3, 7], at: [0, 8.5, 0], material: moss}
  - {name: CrownTop, slot: Body, size: [5, 1.75, 5], at: [-0.25, 10.875, 0.25], material: moss}
  - {name: CrownCap, slot: Body, size: [2.5, 1, 2.5], at: [0.5, 12.25, -0.5], material: moss}
  - {name: ClumpR, slot: Body, size: [2, 2, 3], at: [3.75, 7.75, -0.5], material: moss}
  - {name: ClumpL, slot: Body, size: [2.25, 1.75, 2.5], at: [-3.875, 8.375, 1], material: moss}
  - {name: ClumpFront, slot: Body, size: [3, 1.75, 1.5], at: [-0.5, 7.625, -3.75], material: moss}
  - {name: ClumpBack, slot: Body, size: [2.5, 2, 1.5], at: [1, 9, 3.75], material: moss}
  - {name: ClumpLow, slot: Body, size: [2, 1, 2], at: [-2.25, 6.5, -1.75], material: moss}
  # fruit proud of the leaves
  - {name: Fruit, slot: Accessory, size: [0.5, 0.5, 0.5], at: [1.5, 7.25, -3.75]}
  - {name: Fruit2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-2.25, 9.125, -2.75]}
  - {name: Fruit3, slot: Accessory, size: [0.5, 0.5, 0.5], at: [4.875, 8.25, 0.5]}
  - {name: Fruit4, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-5.125, 8.75, 0.75]}
  - {name: Fruit5, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.75, 11.875, -2.125]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
