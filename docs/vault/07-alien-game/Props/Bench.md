---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: Bench
name: Garden bench
world: 0
region: Home
kind: prop
status: build
height: 2.5
blocks: 14
tris: 168
budget: 260
collision: Box
collision_slots: {Accessory: None}
footprint: [3.5, 1.25, 2.5]
palette: ["#C08A55", "#7B4A2D", "#8FD9B6", "#9E9E8E"]
roles: [body, second, accent, trim]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/Bench/Bench.glb"
---
# Garden bench (the home planet)

A little wooden garden bench for the home plot: a plank seat on four dark legs, a two-slat back between stout posts with iron bolts, and a mint cushion left on one end, as if someone just got up.

- **Cells**: `wood` on the seat, slats, legs and posts; `metal` on the bolts; `wool` on the cushion
- **Collision**: `Box` on the wood (one box over the seat and back, one over the legs and posts: the player stands on it, which is the point of a bench in a kids' game); the cushion none
- **Footprint**: 3.5 x 1.25 x 2.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `Bench`, 1 x 1 cell, 4 studs).
- **Budget**: 260 triangles (the estimate before culling is 168); collision `Box` with `Accessory` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the seat and its legs
  - {name: Seat, slot: Body, size: [3.5, 0.25, 1.25], at: [0, 1.125, 0], material: wood}
  - {name: LegFront, slot: BodyDark, size: [0.25, 1, 0.25], at: [1.375, 0.5, -0.375], mirror: x, material: wood}
  - {name: LegBack, slot: BodyDark, size: [0.25, 1, 0.25], at: [1.375, 0.5, 0.375], mirror: x, material: wood}
  # the back: two posts and two slats, the slats inside the posts' depth so no face is shared
  - {name: Post, slot: BodyDark, size: [0.25, 1.25, 0.375], at: [1.375, 1.875, 0.4375], mirror: x, material: wood}
  - {name: Slat, slot: Body, size: [3.5, 0.375, 0.125], at: [0, 1.6875, 0.4375], material: wood}
  - {name: SlatTop, slot: Body, size: [3.5, 0.375, 0.125], at: [0, 2.1875, 0.4375], material: wood}
  - {name: Bolt, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.375, 1.625, 0.1875], mirror: x, material: metal}
  - {name: BoltTop, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.375, 2.125, 0.1875], mirror: x, material: metal}
  # the cushion
  - {name: Cushion, slot: Accessory, size: [1, 0.25, 0.75], at: [-0.75, 1.375, -0.125], material: wool}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
