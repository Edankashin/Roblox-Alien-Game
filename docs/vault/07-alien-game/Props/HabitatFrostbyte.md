---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: HabitatFrostbyte
name: Frostbyte habitat
world: 0
region: Home
kind: prop
status: build
height: 3
blocks: 47
tris: 564
budget: 900
collision: Precise
collision_slots: {Accessory: None, Trim: None, Glow: None}
footprint: [12, 12, 3]
palette: ["#F2F6FA", "#4A3A2E", "#2F6B5E", "#BFEBFA", "#7FE3F0"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/HabitatFrostbyte/HabitatFrostbyte.glb"
---
# Frostbyte habitat (the home planet)

A little piece of World 2 Frostbyte on the home plot, where caught Frostbyte aliens roam on display: a snow pad inside a fence of frozen logs with ice caps, a gate hung with icicles and a crystal lantern, a frozen pond, two little snow pines, a snow den and glowing cyan crystals in the corners. The middle stays open for the aliens.

- **Cells**: `snow` on the pad and the den; `wood` on the logs; `ice` on the caps, the beam's snow and the icicles; `frozen_water` on the pond; `pine` on the trees; the lantern and the crystals `glow`, Frostbyte's cyan crystal hearts
- **Collision**: `Precise` on the pad, the fence and the den (the pen stays open); pines, ice and glow none
- **The aliens on display** stand at 0.25 studs and walk inside 1 stud of the edge, so the pines, the den and the crystals keep to the corners
- **Footprint**: 12 x 12 x 3 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `HabitatFrostbyte`, 3 x 3 cells, 12 studs).
- **Budget**: 900 triangles (the estimate before culling is 564); collision `Precise` with `Accessory` None, `Trim` None, `Glow` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the pad: packed snow a quarter stud thick
  - {name: Pad, slot: Body, size: [12, 0.25, 12], at: [0, 0.125, 0], material: snow}
  # the fence of frozen logs: posts, two rails a side, a gate with a beam
  - {name: CornerPost, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, -5.5], mirror: x, material: wood}
  - {name: CornerPostBack, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, 5.5], mirror: x, material: wood}
  - {name: MidPostBack, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [1.875, 1, 5.5], mirror: x, material: wood}
  - {name: MidPostSide, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, 1.875], mirror: x, material: wood}
  - {name: MidPostSideFront, slot: BodyDark, size: [0.5, 1.5, 0.5], at: [5.5, 1, -1.875], mirror: x, material: wood}
  - {name: GatePost, slot: BodyDark, size: [0.5, 2.25, 0.5], at: [1.875, 1.375, -5.5], mirror: x, material: wood}
  - {name: GateBeam, slot: BodyDark, size: [4.25, 0.25, 0.5], at: [0, 2.625, -5.5], material: wood}
  - {name: RailBack, slot: BodyDark, size: [10.5, 0.25, 0.25], at: [0, 0.875, 5.5], material: wood}
  - {name: RailSide, slot: BodyDark, size: [0.25, 0.25, 10.5], at: [5.5, 0.875, 0], mirror: x, material: wood}
  - {name: RailFront, slot: BodyDark, size: [3.125, 0.25, 0.25], at: [3.6875, 0.875, -5.5], mirror: x, material: wood}
  - {name: RailBackTop, slot: BodyDark, size: [10.5, 0.25, 0.25], at: [0, 1.375, 5.5], material: wood}
  - {name: RailSideTop, slot: BodyDark, size: [0.25, 0.25, 10.5], at: [5.5, 1.375, 0], mirror: x, material: wood}
  - {name: RailFrontTop, slot: BodyDark, size: [3.125, 0.25, 0.25], at: [3.6875, 1.375, -5.5], mirror: x, material: wood}
  # snow caps and ice on the fence: a cap on each corner and gate post, icicles under the gate beam
  - {name: Cap, slot: Trim, size: [0.75, 0.25, 0.75], at: [5.5, 1.875, -5.5], mirror: x, material: ice}
  - {name: CapBack, slot: Trim, size: [0.75, 0.25, 0.75], at: [5.5, 1.875, 5.5], mirror: x, material: ice}
  - {name: BeamSnow, slot: Trim, size: [4.5, 0.25, 0.75], at: [0, 2.875, -5.5], material: ice}
  - {name: Icicle, slot: Trim, size: [0.25, 0.375, 0.25], at: [1.125, 2.3125, -5.5], mirror: x, material: ice}
  - {name: IcicleMid, slot: Trim, size: [0.25, 0.25, 0.25], at: [0.375, 2.375, -5.5], mirror: x, material: ice}
  # light: a crystal lantern hanging from the beam, crystals in the front corners
  - {name: GateLantern, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 2.25, -5.25]}
  - {name: Crystal, slot: Glow, size: [0.375, 0.75, 0.375], at: [-4.4375, 0.625, -4.4375]}
  - {name: CrystalB, slot: Glow, size: [0.25, 0.5, 0.25], at: [-4.125, 0.5, -4.875]}
  - {name: CrystalC, slot: Glow, size: [0.25, 0.375, 0.25], at: [4.625, 0.4375, -4.625]}
  # a frozen pond in the back left, two little snow pines in the back right, a snow den in the front right
  - {name: Pond, slot: Trim, size: [2.5, 0.125, 2], at: [-3.75, 0.3125, 3.5], material: frozen_water}
  - {name: PineTrunk, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [4.625, 0.4375, 4.625], material: wood}
  - {name: PineLow, slot: Accessory, size: [1, 0.375, 1], at: [4.625, 0.8125, 4.625], material: pine}
  - {name: PineMid, slot: Accessory, size: [0.75, 0.375, 0.75], at: [4.625, 1.1875, 4.625], material: pine}
  - {name: PineTop, slot: Accessory, size: [0.25, 0.25, 0.25], at: [4.625, 1.5, 4.625], material: pine}
  - {name: PineBTrunk, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [3.375, 0.375, 4.875], material: wood}
  - {name: PineBLow, slot: Accessory, size: [0.75, 0.375, 0.75], at: [3.375, 0.6875, 4.875], material: pine}
  - {name: PineBTop, slot: Accessory, size: [0.5, 0.25, 0.5], at: [3.375, 1, 4.875], material: pine}
  - {name: Den, slot: Body, size: [1.5, 0.75, 1.25], at: [4.25, 0.625, -3.875], material: snow}
  - {name: DenTop, slot: Body, size: [1, 0.25, 0.75], at: [4.25, 1.125, -3.875], material: snow}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
