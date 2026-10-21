---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceCaveMouth
name: Ice cave mouth
world: 2
kind: prop
status: build
height: 13.5
blocks: 26
tris: 302
budget: 1200
collision: Precise
footprint: [17.5, 8, 13.5]
palette: ["#CFEAF7", "#0E1A26", "#F7FBFF", "#6EC6F0", "#68C9FE"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/IceCaveMouth/IceCaveMouth.glb"
---
# Ice cave mouth (World 2 Frostbyte)

The way into World 2's Ice Cave: the same stepped arch as the meadow's cave cut from packed snow with a lintel of clear ice, five icicles hanging over the opening, two facets of deep-blue ice set in the pillars, snow heaped on every ledge and drifted at its foot, and cyan crystals glowing at the threshold.

- **Cells**: `packed_snow` strata on the pillars and top, `ice` on the lintel, shoulders, facets and icicles (the deep blue on the Trim slot), `snow` caps two cells tall, the crystals `glow`
- **Read**: the icicle fringe and the glow from far away; the strata, the facets and the drift close up
- **Footprint**: 17.5 x 8 x 13.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 15.2 x 7.8 x 12.2 (clearRadius 14).
- **Budget**: 1200 triangles (the estimate before culling is 302); collision `Precise` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the arch: packed-snow pillars, an ice lintel, the dark
  - {name: PillarL, slot: Body, size: [4, 9, 6], at: [-4.5, 4.5, 0], material: packed_snow}
  - {name: OuterL, slot: Body, size: [2.5, 5.5, 5], at: [-7.5, 2.75, 0.5], material: packed_snow}
  - {name: PillarR, slot: Body, size: [4, 8, 6], at: [4.5, 4, 0], material: packed_snow}
  - {name: OuterR, slot: Body, size: [2.5, 4.5, 5], at: [7.5, 2.25, 0.25], material: packed_snow}
  - {name: Lintel, slot: Body, size: [5, 3, 6], at: [0, 8, 0], material: ice}
  - {name: Shoulder, slot: Body, size: [0.75, 0.75, 6], at: [2.125, 6.125, 0], mirror: x, material: ice}
  - {name: Top, slot: Body, size: [11, 2, 5.5], at: [0, 10.5, 0.25], material: packed_snow}
  - {name: Crown, slot: Body, size: [6, 1.5, 4], at: [-0.5, 12.25, 0.5], material: packed_snow}
  - {name: Dark, slot: BodyDark, size: [5, 6.5, 1], at: [0, 3.25, 1]}
  # snow on the ledges and a drift
  - {name: Snow, slot: Accessory, size: [10.5, 0.5, 5], at: [0, 11.75, 0.25], material: snow}
  - {name: SnowCrown, slot: Accessory, size: [5.5, 0.5, 3.5], at: [-0.5, 13.25, 0.5], material: snow}
  - {name: SnowL, slot: Accessory, size: [2.25, 0.5, 4.5], at: [-7.5, 5.75, 0.5], material: snow}
  - {name: SnowR, slot: Accessory, size: [2.25, 0.5, 4.5], at: [7.5, 4.75, 0.25], material: snow}
  - {name: Drift, slot: Accessory, size: [3.5, 0.5, 2], at: [-5.25, 0.25, -4], material: snow}
  # icicles and ice facets
  - {name: Icicle, slot: Trim, size: [0.5, 2, 0.5], at: [-2, 5.5, -2.5], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle2, slot: Trim, size: [0.5, 1.25, 0.5], at: [-1, 5.875, -2.5], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle3, slot: Trim, size: [0.5, 2.5, 0.5], at: [0, 5.25, -2.5], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle4, slot: Trim, size: [0.5, 1.5, 0.5], at: [1, 5.75, -2.5], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Icicle5, slot: Trim, size: [0.5, 1, 0.5], at: [1.875, 6, -2.5], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Facet, slot: Trim, size: [1, 4, 0.5], at: [-4.5, 4, -3.25], material: ice}
  - {name: Facet2, slot: Trim, size: [0.75, 3, 0.5], at: [4.75, 3.5, -3.25], material: ice}
  # glowing crystals at the threshold
  - {name: Crystal, slot: Glow, size: [0.75, 2.25, 0.75], at: [-2, 1.25, -2.5], rot: [0, 0, -15]}
  - {name: Crystal2, slot: Glow, size: [0.5, 1.5, 0.5], at: [-2.75, 0.875, -3.25], rot: [15, 0, 20]}
  - {name: Crystal3, slot: Glow, size: [0.75, 2, 0.75], at: [2.125, 1.125, -2.75], rot: [0, 0, 18]}
  - {name: Crystal4, slot: Glow, size: [0.5, 1.25, 0.5], at: [6, 0.75, -3.5], rot: [-15, 0, -12]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
