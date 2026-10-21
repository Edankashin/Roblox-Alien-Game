---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: RoomCabin
name: Log cabin room
world: 0
region: Home
kind: prop
status: build
height: 7.75
blocks: 32
tris: 384
budget: 900
collision: Hull
collision_slots: {Glow: None}
footprint: [8, 7.25, 7.75]
palette: ["#B57A45", "#8E3A30", "#A3A096", "#5A3A24", "#FFC86B"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/RoomCabin/RoomCabin.glb"
---
# Log cabin room (the home planet)

A cosy log cabin room for the house grid: warm log walls on a stone footing, dark corner posts, a stepped red roof with a ridge and a stone chimney, a plank door with a lamp over it and a stone step, and two shuttered windows lit warm from inside (and one each side), so it glows at night like home.

- **Cells**: `wood` on the walls, posts, roof, door and shutters; `stone` on the footing, the step and the chimney; the windows and the lamp `glow`
- **Collision**: `Hull` (walls and roof as one hull, the footing as another); the glow none. A room is a prefab to look at and walk round, not to walk into (data/HomeBuild)
- **Footprint**: 8 x 7.25 x 7.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `RoomCabin`, 2 x 2 cells, 8 studs).
- **Budget**: 900 triangles (the estimate before culling is 384); collision `Hull` with `Glow` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the footing, the step and the walls
  - {name: Footing, slot: Accessory, size: [7.5, 0.5, 6.5], at: [0, 0.25, 0], material: stone}
  - {name: Step, slot: Accessory, size: [2, 0.25, 0.5], at: [0, 0.125, -3.5], material: stone}
  - {name: Walls, slot: Body, size: [7, 4, 6], at: [0, 2.5, 0], material: wood}
  - {name: CornerPost, slot: Trim, size: [0.5, 4, 0.5], at: [3.5, 2.5, -3], mirror: x, material: wood}
  - {name: CornerPostBack, slot: Trim, size: [0.5, 4, 0.5], at: [3.5, 2.5, 3], mirror: x, material: wood}
  # the door, its knob and the lamp over it
  - {name: Door, slot: Trim, size: [1.5, 2.5, 0.25], at: [0, 1.75, -3], material: wood}
  - {name: Knob, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.5, 1.75, -3.25], material: metal}
  - {name: Lamp, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 3.375, -3.125]}
  # two front windows lit from inside, each with a mullion, two half bars and two shutters; one window on each side
  - {name: Window, slot: Glow, size: [1.25, 1.25, 0.25], at: [2, 2.75, -3], mirror: x}
  - {name: Mullion, slot: Trim, size: [0.25, 1.25, 0.375], at: [2, 2.75, -3.0625], mirror: x, material: wood}
  - {name: BarOut, slot: Trim, size: [0.5, 0.25, 0.375], at: [2.375, 2.75, -3.0625], mirror: x, material: wood}
  - {name: BarIn, slot: Trim, size: [0.5, 0.25, 0.375], at: [1.625, 2.75, -3.0625], mirror: x, material: wood}
  - {name: ShutterIn, slot: Trim, size: [0.5, 1.25, 0.25], at: [1.125, 2.75, -3.125], mirror: x, material: wood}
  - {name: ShutterOut, slot: Trim, size: [0.5, 1.25, 0.25], at: [2.875, 2.75, -3.125], mirror: x, material: wood}
  - {name: SideWindow, slot: Glow, size: [0.25, 1.25, 1.25], at: [3.5, 2.75, 0], mirror: x}
  # the stepped gable roof, its ridge and the chimney
  - {name: Roof1, slot: BodyDark, size: [8, 0.5, 7], at: [0, 4.75, 0], material: wood}
  - {name: Roof2, slot: BodyDark, size: [8, 0.5, 5.5], at: [0, 5.25, 0], material: wood}
  - {name: Roof3, slot: BodyDark, size: [8, 0.5, 4], at: [0, 5.75, 0], material: wood}
  - {name: Roof4, slot: BodyDark, size: [8, 0.5, 2.5], at: [0, 6.25, 0], material: wood}
  - {name: Roof5, slot: BodyDark, size: [8, 0.5, 1], at: [0, 6.75, 0], material: wood}
  - {name: Ridge, slot: Trim, size: [8, 0.25, 0.5], at: [0, 7.125, 0], material: wood}
  - {name: Chimney, slot: Accessory, size: [1, 2.75, 1], at: [2.25, 6.125, 1.25], material: stone}
  - {name: ChimneyCap, slot: Accessory, size: [1.25, 0.25, 1.25], at: [2.25, 7.625, 1.25], material: stone}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
