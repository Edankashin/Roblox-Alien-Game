---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Ship
name: Crashed ship
world: 1
kind: prop
status: concept
height: 4
blocks: 13
tris: 156
palette: ["#E6EBF2", "#3D4556", "#7FE3F0", "#FF8A3D", "#FFB347"]
roles: [body, second, accent, trim, glow]
render: "[[world1_scene_v1.jpg]]"
glb: ""
---
# Crashed ship (World 1 Verdant)

The players' ship as a blocky prop, nose down in the meadow where it crash-landed (the game's opening; the aliens rebuild it to fly to the next world, [[Alien-Game]]). A long white hull in riveted panels, a dark nose cap, a cyan canopy, an orange band, fin and stripe, one whole wing and one snapped short, an engine with a lit exhaust, two skids. 11 studs long, 4 tall: two avatars long, so it reads as a vehicle for one. Rules: [[Blocky-Style]] "Environment".

- **Cells**: `metal` on the hull, nose, skids and engine (panels four cells square, a seam a step down, a rivet a step and a half up in each panel's corner); `crystal` on the canopy; the orange trim plain `skin` cells; the exhaust `glow`.
- **The crash**: the diorama pitches the whole prop 12 degrees nose-down and sinks the nose into the ground, with a few dirt blocks thrown up round it (`tools/blender/blocky_scene.py`); the prop itself stays axis-aligned on y = 0, so the game can also place it level (repaired) later.

## Parts

```yaml
parts:
  # the hull: a white body in rivet panels, a dark nose cap and engine on skids
  - {name: Hull, slot: Body, size: [3, 2, 7], at: [0, 1.5, 0], material: metal}
  - {name: Nose, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.25, -4.25], material: metal}
  - {name: NoseCap, slot: BodyDark, size: [1, 1, 0.5], at: [0, 1.25, -5.25], material: metal}
  - {name: Skid, slot: BodyDark, size: [0.5, 0.5, 5], at: [1, 0.25, 0], mirror: x, material: metal}
  - {name: Engine, slot: BodyDark, size: [2, 1.5, 1], at: [0, 1.5, 4], material: metal}
  - {name: Exhaust, slot: Glow, size: [1.25, 0.75, 0.125], at: [0, 1.5, 4.5625]}
  # the canopy, an orange band round the hull, a fin, a stripe, a wing whole and a wing snapped short
  - {name: Canopy, slot: Accessory, size: [2, 0.75, 2.5], at: [0, 2.875, -1.75], material: crystal}
  - {name: Band, slot: Trim, size: [3.25, 0.5, 1], at: [0, 1.5, 1.5]}
  - {name: Fin, slot: Trim, size: [0.25, 1.5, 1.5], at: [0, 3.25, 2.75]}
  - {name: Stripe, slot: Trim, size: [1, 0.125, 4], at: [0, 2.5625, 1]}
  - {name: Wing, slot: Trim, size: [2, 0.25, 3], at: [2.5, 1.125, 1.5]}
  - {name: WingStub, slot: Trim, size: [1, 0.25, 2], at: [-2, 1.125, 1.5]}
```

## Renders

In the World 1 diorama: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build: the rivet panels make a plain box read as a hull; the snapped wing and the pitch sell the crash. Status concept.
