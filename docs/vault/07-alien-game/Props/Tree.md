---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Tree
name: Meadow tree
world: 1
kind: prop
status: concept
height: 7.875
blocks: 14
tris: 168
palette: ["#3F9B3A", "#7B4A2D", "#FF8FB0"]
roles: [body, second, accent]
render: "[[world1_scene_v1.jpg]]"
glb: ""
---
# Meadow tree (World 1 Verdant)

A blocky broadleaf for the meadow: a bark trunk with three root flares and one branch, a crown of leaf clumps that breaks the box on three sides, and four pink blossoms proud of its faces. Colours are the meadow's own (`src/shared/data/Meadow.luau`: trunk 7B4A2D, leaves 3F9B3A). Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell).

- **Cells**: the trunk, roots and branch in `wood` (grain rows along the trunk, square rings on the cut ends); the crown in `moss` tufts with the blossom pink as the sprig cell, so the leaves carry the same cell motif as Moop's head and Gaira's antler clumps.
- **Scale**: 7.9 studs, a head and a half over the 5-stud avatar; the crown's underside at 4 studs, so an avatar walks under it.

## Parts

```yaml
parts:
  # trunk and roots: bark in grain rows; the roots flare a half stud out on three sides
  - {name: Trunk, slot: BodyDark, size: [1, 4.5, 1], at: [0, 2.25, 0], material: wood}
  - {name: Root, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.75, 0.25, 0], mirror: x, material: wood}
  - {name: RootBack, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 0.25, 0.75], material: wood}
  - {name: Branch, slot: BodyDark, size: [1, 0.5, 0.5], at: [1, 3.25, 0], material: wood}
  # the crown: a big clump, a smaller cap and three clumps that break the box
  - {name: Crown, slot: Body, size: [4, 2, 4], at: [0, 5.5, 0], material: moss}
  - {name: CrownTop, slot: Body, size: [3, 1, 3], at: [0, 7, 0], material: moss}
  - {name: Clump, slot: Body, size: [1.5, 1.5, 2], at: [2.25, 4.75, 0.5], material: moss}
  - {name: ClumpBack, slot: Body, size: [2, 1.5, 1.5], at: [-0.5, 5.25, 2.25], material: moss}
  - {name: ClumpLow, slot: Body, size: [1.5, 1, 1.5], at: [-2.25, 4.75, -0.75], material: moss}
  # blossoms proud of the crown's faces, pink against the leaves
  - {name: Blossom, slot: Accessory, size: [0.5, 0.5, 0.5], at: [1, 6, -2.125]}
  - {name: Blossom2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [-1.25, 5, -2.125]}
  - {name: Blossom3, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 7.625, -0.75]}
  - {name: Blossom4, slot: Accessory, size: [0.5, 0.5, 0.5], at: [3.125, 5, -0.25]}
```

## Renders

In the World 1 diorama: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build: the crown reads as leaves at hero-shot distance through the moss tufts and the pink sprig cells; the trunk's grain rows read as bark. Status concept.
