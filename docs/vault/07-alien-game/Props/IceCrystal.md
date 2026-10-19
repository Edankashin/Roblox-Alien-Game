---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceCrystal
name: Ice crystal
world: 2
kind: prop
status: concept
height: 4.25
blocks: 7
tris: 82
palette: ["#BFEBFA", "#A9B7C0", "#68C9FE"]
roles: [body, second, glow]
render: "[[world2_scene_v1.jpg]]"
glb: ""
---
# Ice crystal (World 2 Frostbyte)

Frostbyte's twin of the meadow's [[Crystal]]: a cluster of ice on a rock seat, one tall spire lit from inside under a six-sided point, four shards leaning out of the seat. The emissive prop of the snowfield (glow stays sparing: two in the diorama, one on the ledge and one by the pond). Its glow is the Shrine of Skaddle's ice-blue (`src/shared/data/Frostbyte.luau`, `Shrine.glowColor` 68C9FE), so the shrine and the crystals agree. Rules: [[Blocky-Style]] "Environment".

- **Cells**: `ice` on the spire, point and shards (light bands on the other diagonal to crystal's, so Frostbyte's ice never reads as Verdant's crystal); the spire is on the Glow slot, so its bands glow; the seat in `stone` with a `snow` dusting on its top.
- **Light**: the diorama hangs a soft ice-blue point light at the spire.

## Parts

```yaml
parts:
  - {name: Seat, slot: BodyDark, size: [2.5, 0.5, 2], at: [0, 0.25, 0], material: stone}
  - {name: SeatSnow, slot: Body, size: [1, 0.25, 0.75], at: [0.625, 0.625, 0.5], material: snow}
  - {name: Spire, slot: Glow, size: [0.75, 2.75, 0.75], at: [0, 1.875, 0], material: ice}
  - {name: Tip, slot: Glow, size: [0.75, 1, 0.75], at: [0, 3.75, 0], shape: cone6, material: ice}
  - {name: Shard, slot: Body, size: [0.5, 1.75, 0.5], at: [0.75, 1.3125, -0.25], rot: [0, 0, -20], material: ice}
  - {name: Shard2, slot: Body, size: [0.5, 1.25, 0.5], at: [-0.625, 1.0625, 0.375], rot: [15, 0, 20], material: ice}
  - {name: Shard3, slot: Body, size: [0.375, 1, 0.375], at: [-0.4375, 0.9375, -0.6875], rot: [-15, 0, 10], material: ice}
```

## Renders

In the Frostbyte diorama: ![[world2_scene_v1.jpg]]

## Reviews

- 2026-10-19, World 2 worker. First build: the lit bands read as ice and the four leaning shards keep it from being a post; the snow dusting ties the seat to the field. Status concept.
