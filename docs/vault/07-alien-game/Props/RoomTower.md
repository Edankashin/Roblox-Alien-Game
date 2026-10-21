---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: RoomTower
name: Lookout tower room
world: 0
region: Home
kind: prop
status: build
height: 12
blocks: 26
tris: 312
budget: 700
collision: Box
collision_slots: {Accessory: None, Glow: None}
footprint: [4, 4, 12]
palette: ["#D3C7AC", "#4A5BC4", "#FFC83D", "#7B4A2D", "#FFC86B"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/RoomTower/RoomTower.glb"
---
# Lookout tower room (the home planet)

A tall, narrow lookout tower room for one cell of the house grid: a stepped octagonal stone shaft on a plinth, a wooden band halfway up, a crown under a stepped blue roof, a gold pennant on top, an arched plank door and warm windows up the front and the sides, for looking out over the home planet.

- **Cells**: `stone` on the plinth, the shaft, the crown and the roof (slate); `wood` on the band, the door and the pole; `wool` on the pennant; the windows `glow`
- **Collision**: `Box` on the stone, the roof and the wood (the tower is one tall block to walk round); the pennant and the glow none
- **Footprint**: 4 x 4 x 12 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `RoomTower`, 1 x 1 cell, 4 studs).
- **Budget**: 700 triangles (the estimate before culling is 312); collision `Box` with `Accessory` None, `Glow` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the plinth, the shaft, the band and the crown: stepped octagons
  - {name: Plinth, slot: Body, size: [2.25, 0.5, 3.75], at: [0, 0.25, 0], material: stone}
  - {name: PlinthSide, slot: Body, size: [0.75, 0.5, 2.25], at: [1.5, 0.25, 0], mirror: x, material: stone}
  - {name: Shaft, slot: Body, size: [1.75, 6.5, 3.25], at: [0, 3.75, 0], material: stone}
  - {name: ShaftSide, slot: Body, size: [0.75, 6.5, 1.75], at: [1.25, 3.75, 0], mirror: x, material: stone}
  - {name: Band, slot: Trim, size: [2, 0.25, 3.5], at: [0, 4.125, 0], material: wood}
  - {name: BandSide, slot: Trim, size: [0.75, 0.25, 2], at: [1.375, 4.125, 0], mirror: x, material: wood}
  - {name: Crown, slot: Body, size: [2.25, 0.5, 3.75], at: [0, 7.25, 0], material: stone}
  - {name: CrownSide, slot: Body, size: [0.75, 0.5, 2.25], at: [1.5, 7.25, 0], mirror: x, material: stone}
  # the stepped blue roof, the pole and the pennant
  - {name: Roof1, slot: BodyDark, size: [4, 0.5, 4], at: [0, 7.75, 0], material: stone}
  - {name: Roof2, slot: BodyDark, size: [3.25, 0.75, 3.25], at: [0, 8.375, 0], material: stone}
  - {name: Roof3, slot: BodyDark, size: [2.5, 0.75, 2.5], at: [0, 9.125, 0], material: stone}
  - {name: Roof4, slot: BodyDark, size: [1.75, 0.75, 1.75], at: [0, 9.875, 0], material: stone}
  - {name: Roof5, slot: BodyDark, size: [1, 0.75, 1], at: [0, 10.625, 0], material: stone}
  - {name: Pole, slot: Trim, size: [0.25, 1, 0.25], at: [0, 11.5, 0], material: wood}
  - {name: Pennant, slot: Accessory, size: [1, 0.5, 0.125], at: [0.625, 11.625, 0.0625], material: wool}
  # the arched door and the windows
  - {name: Door, slot: Trim, size: [1, 1.75, 0.25], at: [0, 1.375, -1.625], material: wood}
  - {name: Arch, slot: Trim, size: [0.5, 0.25, 0.25], at: [0, 2.375, -1.625], material: wood}
  - {name: Window, slot: Glow, size: [0.5, 0.75, 0.25], at: [0, 3.125, -1.625]}
  - {name: WindowHigh, slot: Glow, size: [0.5, 0.75, 0.25], at: [0, 5.375, -1.625]}
  - {name: SideWindow, slot: Glow, size: [0.25, 0.75, 0.5], at: [1.625, 5.375, 0], mirror: x}
  - {name: BackWindow, slot: Glow, size: [0.5, 0.75, 0.25], at: [0, 5.375, 1.625]}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
