---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: PineTree
name: Snow pine
world: 2
kind: prop
status: concept
height: 9.25
blocks: 12
tris: 144
palette: ["#2F6B5E", "#4A3A2E", "#F2F6FA"]
roles: [body, second, accent]
render: "[[world2_scene_v1.jpg]]"
glb: ""
---
# Snow pine (World 2 Frostbyte)

A blocky conifer for the snowfield: a bark trunk with two root flares, three stepped tiers of needles narrowing to a tip, and a snow cap on every tier. 9.25 studs, nearly two avatars: the tallest prop of the world, so the Cosmic still towers over it. Rules: [[Blocky-Style]] "Environment" and the "World 2: Frostbyte palette".

- **Cells**: the trunk and roots in `wood` (a cold brown; the placeholder's grey-blue trunk read as a post); the tiers in `pine` (needle rows two cells tall, broken into ragged fronds, with the accent snow as dust on the needles); the caps in `snow`. A snow cap is half a stud tall, two cells, so the snow lip covers its whole side and no packed snow shows.
- **Scale**: the lowest tier's underside at 2.5 studs, so a Common walks under it and an avatar brushes it.

## Parts

```yaml
parts:
  # trunk and roots: bark in grain rows, two root flares
  - {name: Trunk, slot: BodyDark, size: [0.75, 3, 0.75], at: [0, 1.5, 0], material: wood}
  - {name: Root, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, 0], mirror: x, material: wood}
  - {name: RootBack, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 0.25, 0.625], material: wood}
  # three tiers of needles, each a step narrower, and the tip
  - {name: Tier, slot: Body, size: [3.5, 1.5, 3.5], at: [0, 3.25, 0], material: pine}
  - {name: Tier2, slot: Body, size: [2.5, 1.5, 2.5], at: [0, 5, 0], material: pine}
  - {name: Tier3, slot: Body, size: [1.5, 1.5, 1.5], at: [0, 6.75, 0], material: pine}
  - {name: Tip, slot: Body, size: [0.75, 1.25, 0.75], at: [0, 8.125, 0], material: pine}
  - {name: TipTop, slot: Body, size: [0.25, 0.5, 0.25], at: [0, 9, 0], material: pine}
  # a snow cap on every tier, a little narrower than the tier under it and wider than the tier over it
  - {name: Cap, slot: Accessory, size: [3, 0.5, 3], at: [0, 4.25, 0], material: snow}
  - {name: Cap2, slot: Accessory, size: [2, 0.5, 2], at: [0, 6, 0], material: snow}
  - {name: Cap3, slot: Accessory, size: [1.25, 0.5, 1.25], at: [0, 7.75, 0], material: snow}
```

## Renders

In the Frostbyte diorama: ![[world2_scene_v1.jpg]]

## Reviews

- 2026-10-19, World 2 worker. First build: the three tiers with their caps read as a snow pine from the hero camera, the needle rows as foliage and the snow dust as snow on it; the trunk's grain reads as bark. Status concept.
