---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Heater
name: Camp heater
world: 2
kind: prop
status: concept
height: 3
blocks: 10
tris: 120
palette: ["#6B7580", "#3D4556", "#C9CFD8", "#FFB347"]
roles: [body, second, trim, glow]
render: "[[world2_scene_v1.jpg]]"
glb: ""
---
# Camp heater (World 2 Frostbyte)

The camp's heater, the one warm thing in the world: a squat steel drum on three feet, a lit grate on its front behind two dark bars, a riveted rim, a stack with a flared cap. In the game it is the Heater tool (place it to reveal aliens a Blizzard hides for 60 s, [[Decisions]] "World 2 roster"); in the diorama it stands by the avatar at the camp and carries the scene's warm point light, the orange against all the blue. Rules: [[Blocky-Style]] "Environment".

- **Cells**: `metal` on the drum, feet, stack and cap (panels, seams and rivets); the rim in `metal` on the glossy Trim slot; the grate a `glow` plate (a lit core inside a border) behind two plain dark bars.
- **Light**: the diorama hangs a warm point light at the grate (the in-game twin is the tool's PointLight).

## Parts

```yaml
parts:
  # the drum on three feet, a rim round its top
  - {name: Drum, slot: Body, size: [1.5, 1.5, 1.5], at: [0, 1.125, 0], material: metal}
  - {name: Foot, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.5, 0.1875, -0.5], mirror: x, material: metal}
  - {name: FootBack, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0, 0.1875, 0.5], material: metal}
  - {name: Rim, slot: Trim, size: [1.75, 0.25, 1.75], at: [0, 1.875, 0], material: metal}
  # the grate: a lit plate on the front behind two dark bars
  - {name: Grate, slot: Glow, size: [1, 0.75, 0.125], at: [0, 1, -0.8125]}
  - {name: Bar, slot: BodyDark, size: [0.25, 0.75, 0.125], at: [0.25, 1, -0.9375], mirror: x}
  # the stack and its flared cap
  - {name: Stack, slot: BodyDark, size: [0.5, 1, 0.5], at: [0.25, 2.5, 0.25], material: metal}
  - {name: StackCap, slot: Trim, size: [0.75, 0.125, 0.75], at: [0.25, 2.9375, 0.25], material: metal}
```

## Renders

In the Frostbyte diorama: ![[world2_scene_v1.jpg]]

## Reviews

- 2026-10-19, World 2 worker. First build: the lit grate and its warm light read as the camp's one warm spot from both cameras; the rivet panels read as steel. Status concept.
