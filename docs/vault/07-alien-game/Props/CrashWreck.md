---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: CrashWreck
name: Crash site
world: 1
kind: prop
status: build
height: 9.5
blocks: 32
tris: 380
budget: 1400
collision: Hull
footprint: [22.954, 17.5, 9.5]
palette: ["#9AA3B0", "#3A3530", "#D8D4CE", "#7FE3F0", "#FF7A1A"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/CrashWreck/CrashWreck.glb"
---
# Crash site (World 1 Verdant)

Where the player's ship came down: the hull broken in two on a scorched disc, the front half nose-down in a furrow it ploughed (clods thrown up round it), its cyan canopy cracked open to the sky, the rear half rolled the other way with its fin bent and its engine still glowing, a wing torn off and plates scattered. A column of block smoke climbs from the break, so the site reads from across the meadow; embers glow in the scorch for whoever walks up.

- **Cells**: `metal` panels and rivets on the hull halves, wing and plates; the canopy `crystal` (glossy); `dirt` on the scorch and clods; the smoke plain cells stepping up and drifting with the wind; embers and the exhaust `glow` (Neon)
- **Read**: from far away: the smoke column and the two tilted halves; up close: the canopy, the stripe, the embers, the scattered plates
- **Footprint**: 22.954 x 17.5 x 9.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 24 x 18.8 x 7.7 (clearRadius 16 in data/Meadow.luau holds: the wreck reaches 11 studs from its centre).
- **Budget**: 1400 triangles (the estimate before culling is 380); collision `Hull` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the scorched disc, the furrow and thrown clods
  - {name: Scorch, slot: BodyDark, size: [21, 0.125, 15], at: [1, 0.0625, 0.5], material: dirt}
  - {name: ScorchIn, slot: BodyDark, size: [15, 0.25, 10], at: [0, 0.125, 0], material: dirt}
  - {name: Furrow, slot: BodyDark, size: [3, 0.5, 6], at: [-6.5, 0.25, -6.5], material: dirt}
  - {name: Clod, slot: BodyDark, size: [1.25, 0.75, 1.25], at: [-9, 0.75, -8.25], rot: [15, 0, 20], material: dirt}
  - {name: Clod2, slot: BodyDark, size: [1, 0.5, 1], at: [-4, 0.5, -8.75], rot: [-18, 0, 12], material: dirt}
  - {name: Clod3, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [-10.5, 0.5, -4.5], rot: [20, 0, -15], material: dirt}
  # the two hull halves, canopy, stripe, fin, engine and wings
  - {name: Hull, slot: Body, size: [6, 3.5, 7.5], at: [-3.5, 3.1875, -2], rot: [14, 0, -12], material: metal}
  - {name: Nose, slot: Body, size: [4, 2.5, 3], at: [-5, 2.0625, -6.75], rot: [20, 0, -10], material: metal}
  - {name: Canopy, slot: Trim, size: [3.25, 1.25, 3], at: [-3.75, 4.375, -3.25], rot: [14, 0, -12], material: crystal}
  - {name: Stripe, slot: Accessory, size: [6.125, 0.5, 1], at: [-3.5, 3, 1.25], rot: [14, 0, -12]}
  - {name: Rear, slot: Body, size: [5.5, 3, 6], at: [5, 2.625, 2.5], rot: [-10, 0, 14], material: metal}
  - {name: Engine, slot: BodyDark, size: [3, 2.5, 1.5], at: [5.75, 1.75, 6], rot: [-10, 0, 14], material: metal}
  - {name: Fin, slot: Body, size: [0.5, 3, 3], at: [5, 4.5, 3.5], rot: [0, 0, 22], shape: wedge, material: metal}
  - {name: Wing, slot: Body, size: [5, 0.5, 3], at: [9.5, 0.8125, 1], rot: [0, 0, -12], material: metal}
  - {name: WingStub, slot: Body, size: [3, 0.5, 2.5], at: [-7.75, 0.75, 0], rot: [0, 0, 18], material: metal}
  # scattered plates and a strut
  - {name: Plate, slot: BodyDark, size: [2, 0.25, 1.5], at: [1.5, 0.4375, -5.5], rot: [0, 0, 15], material: metal}
  - {name: Plate2, slot: Body, size: [1.5, 0.25, 1.25], at: [9, 0.375, -4], rot: [-12, 0, 0], material: metal}
  - {name: Plate3, slot: BodyDark, size: [1.25, 0.25, 2], at: [-1, 0.4375, 6], rot: [15, 0, 0], material: metal}
  - {name: Strut, slot: BodyDark, size: [0.5, 0.5, 3], at: [10, 0.5, 4.5], rot: [0, 0, 20], material: metal}
  # embers and the engine's glow
  - {name: Ember, slot: Glow, size: [0.5, 0.5, 0.5], at: [0.5, 0.5, -1]}
  - {name: Ember2, slot: Glow, size: [0.375, 0.375, 0.375], at: [1.1875, 0.4375, 0.6875]}
  - {name: Ember3, slot: Glow, size: [0.5, 0.25, 0.5], at: [-0.5, 0.375, 1.75]}
  - {name: Ember4, slot: Glow, size: [0.25, 0.25, 0.25], at: [3, 0.375, -2.5]}
  - {name: Exhaust, slot: Glow, size: [1.75, 1.25, 0.25], at: [5.75, 1.75, 6.875], rot: [-10, 0, 14]}
  - {name: Spark, slot: Glow, size: [0.25, 0.25, 0.25], at: [-2, 0.375, -4.25]}
  # the smoke column and the engine's wisp
  - {name: Smoke, slot: Accessory, size: [2, 1.5, 2], at: [0.75, 4.25, 0.5]}
  - {name: Smoke2, slot: Accessory, size: [1.75, 1.25, 1.75], at: [1.25, 5.875, 0.75]}
  - {name: Smoke3, slot: Accessory, size: [1.25, 1, 1.25], at: [2, 7.25, 1.25]}
  - {name: Smoke4, slot: Accessory, size: [1, 0.75, 1], at: [2.75, 8.375, 1.5]}
  - {name: Smoke5, slot: Accessory, size: [0.5, 0.5, 0.5], at: [3.5, 9.25, 2]}
  - {name: Wisp, slot: Accessory, size: [1, 0.75, 1], at: [6.5, 4.5, 6.75]}
  - {name: Wisp2, slot: Accessory, size: [0.75, 0.5, 0.75], at: [7, 5.5, 7.25]}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
