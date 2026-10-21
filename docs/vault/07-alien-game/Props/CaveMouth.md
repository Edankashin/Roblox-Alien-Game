---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: CaveMouth
name: Cave mouth
world: 1
kind: prop
status: build
height: 13.25
blocks: 26
tris: 312
budget: 1200
collision: Precise
footprint: [17.5, 8.25, 13.25]
palette: ["#7A756E", "#15120F", "#5E9E3A", "#C084FC", "#7FE3FF"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/CaveMouth/CaveMouth.glb"
---
# Cave mouth (World 1 Verdant)

The way into World 1's Cave: a stepped rock arch over a dark opening 5 studs wide and 6.5 tall, moss and grass lying thick on its top and ledges with three vines hanging over the lintel, cyan crystals glowing at the foot of each pillar and a cluster of violet amethyst on the right. The glow at the threshold is the invitation; the dark behind it is the promise.

- **Cells**: `stone` cobbles on the frame and rubble; `moss` on the tops, ledges and vines; the cyan crystals `glow` (Neon), the amethyst `crystal` (glossy); the opening a plain near-black block set 3.5 studs back so it reads as depth
- **Read**: the arch and the glowing threshold from far away; the vines, amethyst and rubble close up
- **Footprint**: 17.5 x 8.25 x 13.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 15.4 x 7.4 x 12.3 (clearRadius 14).
- **Budget**: 1200 triangles (the estimate before culling is 312); collision `Precise` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the arch: two stepped pillars, a lintel with shoulders, a top and a crown, the dark
  - {name: PillarL, slot: Body, size: [4, 9, 6], at: [-4.5, 4.5, 0], material: stone}
  - {name: OuterL, slot: Body, size: [2.5, 5.5, 5], at: [-7.5, 2.75, 0.5], material: stone}
  - {name: PillarR, slot: Body, size: [4, 8, 6], at: [4.5, 4, 0], material: stone}
  - {name: OuterR, slot: Body, size: [2.5, 4.5, 5], at: [7.5, 2.25, 0.25], material: stone}
  - {name: Lintel, slot: Body, size: [5, 3, 6], at: [0, 8, 0], material: stone}
  - {name: Shoulder, slot: Body, size: [0.75, 0.75, 6], at: [2.125, 6.125, 0], mirror: x, material: stone}
  - {name: Top, slot: Body, size: [11, 2, 5.5], at: [0, 10.5, 0.25], material: stone}
  - {name: Crown, slot: Body, size: [6, 1.5, 4], at: [-0.5, 12.25, 0.5], material: stone}
  - {name: Dark, slot: BodyDark, size: [5, 6.5, 1], at: [0, 3.25, 1]}
  # moss, vines and grass
  - {name: Moss, slot: Accessory, size: [9.5, 0.5, 4.5], at: [0.25, 11.75, 0.25], material: moss}
  - {name: MossCrown, slot: Accessory, size: [4.5, 0.25, 3], at: [-0.75, 13.125, 0.5], material: moss}
  - {name: MossL, slot: Accessory, size: [2, 0.5, 4], at: [-7.5, 5.75, 0.5], material: moss}
  - {name: Vine, slot: Accessory, size: [0.5, 2.5, 0.25], at: [-1.75, 7.5, -3.125], material: moss}
  - {name: Vine2, slot: Accessory, size: [0.5, 1.75, 0.25], at: [0.75, 7.875, -3.125], material: moss}
  - {name: Vine3, slot: Accessory, size: [0.5, 3, 0.25], at: [3.5, 6.75, -3.125], material: moss}
  - {name: Grass, slot: Accessory, size: [3, 0.25, 2], at: [6, 0.125, -4], material: moss}
  # glowing crystals and amethyst at the threshold
  - {name: Crystal, slot: Glow, size: [0.75, 2.25, 0.75], at: [-2, 1.25, -2.5], rot: [0, 0, -15]}
  - {name: Crystal2, slot: Glow, size: [0.5, 1.5, 0.5], at: [-2.75, 0.875, -3.25], rot: [15, 0, 20]}
  - {name: Crystal3, slot: Glow, size: [0.75, 2, 0.75], at: [2.125, 1.125, -2.75], rot: [0, 0, 18]}
  - {name: Amethyst, slot: Trim, size: [1, 2.5, 1], at: [5.25, 1.4375, -3.75], rot: [-12, 0, -15], material: crystal}
  - {name: Amethyst2, slot: Trim, size: [0.75, 1.75, 0.75], at: [6.25, 1, -3.25], rot: [0, 0, -22], material: crystal}
  - {name: Amethyst3, slot: Trim, size: [0.5, 1.25, 0.5], at: [4.5, 0.75, -4.25], rot: [18, 0, 10], material: crystal}
  # rubble
  - {name: Rubble, slot: Body, size: [1.5, 1, 1.25], at: [-5.5, 0.5, -4], material: stone}
  - {name: Rubble2, slot: Body, size: [1, 0.75, 1], at: [-3.5, 0.375, -4.75], material: stone}
  - {name: Rubble3, slot: Body, size: [1.25, 0.75, 1], at: [7.75, 0.375, -3.25], material: stone}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
