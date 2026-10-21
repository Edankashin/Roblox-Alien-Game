---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: RoomDome
name: Habitat dome room
world: 0
region: Home
kind: prop
status: build
height: 7
blocks: 35
tris: 420
budget: 900
collision: Hull
collision_slots: {Glow: None, Accessory: None}
footprint: [7.5, 7.75, 7]
palette: ["#EEF0F7", "#6E7690", "#FF9A3D", "#7FD3F0", "#FFC86B"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/RoomDome/RoomDome.glb"
---
# Habitat dome room (the home planet)

A little space-colony dome room: white panels stepped up into a dome on a dark metal ring, a glass skylight on top with an antenna and a blinking gold tip, an orange door with a porthole in a dark frame, warm-lit windows all round, and an orange satellite dish tilted to the sky.

- **Cells**: `metal` on the panels, the ring, the frame and the antenna; `crystal` on the skylight; plain cells on the door and the dish; the windows, the porthole, the tip and the receiver `glow`
- **Collision**: `Hull` on the shell (a stepped dome is nearly convex) and the ring; the door, the dish and the glow none
- **Footprint**: 7.5 x 7.75 x 7 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `RoomDome`, 2 x 2 cells, 8 studs).
- **Budget**: 900 triangles (the estimate before culling is 420); collision `Hull` with `Glow` None, `Accessory` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the ring, the wall and the dome: stepped octagons of three blocks meeting edge to edge, a glass skylight on top
  - {name: Base, slot: BodyDark, size: [4.5, 0.5, 7.5], at: [0, 0.25, 0], material: metal}
  - {name: BaseSide, slot: BodyDark, size: [1.5, 0.5, 4.5], at: [3, 0.25, 0], mirror: x, material: metal}
  - {name: Wall, slot: Body, size: [4, 2, 7], at: [0, 1.5, 0], material: metal}
  - {name: WallSide, slot: Body, size: [1.5, 2, 4], at: [2.75, 1.5, 0], mirror: x, material: metal}
  - {name: Shell, slot: Body, size: [3.5, 0.75, 6.5], at: [0, 2.875, 0], material: metal}
  - {name: ShellSide, slot: Body, size: [1.5, 0.75, 3.5], at: [2.5, 2.875, 0], mirror: x, material: metal}
  - {name: ShellMid, slot: Body, size: [3, 0.75, 5.5], at: [0, 3.625, 0], material: metal}
  - {name: ShellMidSide, slot: Body, size: [1.25, 0.75, 3], at: [2.125, 3.625, 0], mirror: x, material: metal}
  - {name: ShellHigh, slot: Body, size: [2.5, 0.75, 4.5], at: [0, 4.375, 0], material: metal}
  - {name: ShellHighSide, slot: Body, size: [1, 0.75, 2.5], at: [1.75, 4.375, 0], mirror: x, material: metal}
  - {name: ShellTop, slot: Body, size: [1.5, 0.5, 3], at: [0, 5, 0], material: metal}
  - {name: ShellTopSide, slot: Body, size: [0.75, 0.5, 1.5], at: [1.125, 5, 0], mirror: x, material: metal}
  - {name: Skylight, slot: Trim, size: [1, 0.25, 2], at: [0, 5.375, 0], material: crystal}
  - {name: SkylightSide, slot: Trim, size: [0.5, 0.25, 1], at: [0.75, 5.375, 0], mirror: x, material: crystal}
  # the door: a dark frame, an orange door, a porthole, a step
  - {name: DoorFrame, slot: BodyDark, size: [1.75, 2, 0.25], at: [0, 1.5, -3.5], material: metal}
  - {name: Door, slot: Accessory, size: [1.25, 1.625, 0.25], at: [0, 1.4375, -3.625]}
  - {name: Porthole, slot: Glow, size: [0.5, 0.5, 0.125], at: [0, 1.75, -3.8125]}
  - {name: Step, slot: BodyDark, size: [2, 0.25, 0.25], at: [0, 0.125, -3.875], material: metal}
  # warm windows on the slanted faces and the sides
  - {name: Window, slot: Glow, size: [0.75, 0.75, 0.25], at: [2.75, 1.625, -2], mirror: x}
  - {name: SideWindow, slot: Glow, size: [0.25, 0.75, 1], at: [3.5, 1.625, 0], mirror: x}
  - {name: BackWindow, slot: Glow, size: [1, 0.75, 0.25], at: [0, 1.625, 3.5]}
  # the antenna and its tip, the satellite dish tilted to the sky
  - {name: Antenna, slot: BodyDark, size: [0.25, 1, 0.25], at: [0, 6, 0], material: metal}
  - {name: Tip, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 6.75, 0]}
  - {name: DishStalk, slot: BodyDark, size: [0.25, 0.75, 0.25], at: [2.5, 4.375, 0], material: metal}
  - {name: Dish, slot: Accessory, size: [1, 0.25, 1], at: [2.5, 4.875, 0], rot: [0, 0, -20]}
  - {name: Receiver, slot: Glow, size: [0.25, 0.25, 0.25], at: [2.5, 5.125, 0]}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
