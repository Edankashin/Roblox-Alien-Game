---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Ship
name: Crashed ship
world: 1
kind: prop
status: concept
height: 6.25
blocks: 44
tris: 528
palette: ["#E6EBF2", "#3D4556", "#7FE3F0", "#FF8A3D", "#FFB347", "#7C8594"]
roles: [body, second, accent, trim, glow, ink]
render: "[[world1_scene_v2.jpg]]"
glb: ""
---
# Crashed ship (World 1 Verdant)

The players' ship as a blocky prop, nose down in the meadow where it crash-landed (the game's opening; the aliens rebuild it to fly to the next world, [[Alien-Game]]). Version 2, 2026-10-19: the v1 ship (11 studs, 13 blocks) was small and plain beside the Cosmic and the Secret, so it is now **14.4 studs long, 6.25 tall and 10.5 across the whole wing**, three avatars long, with the detail a hero prop wants: a white hull in riveted panels with a raised spine, a cockpit (a dark frame under a cyan canopy with a cap), two cyan portholes and a hatch on each side, an orange band round the hull, an orange stripe down the spine, a swept tail fin with a tip and two tail planes, one whole wing and one snapped short to two shards, a three-nozzle engine with the middle exhaust lit, two long skids, an antenna, a scorched nose (a dark cone and tip with soot plates on the nose's top and sides) and a little smoke: four grey cells rising and drifting off the nose. Rules: [[Blocky-Style]] "Environment".

- **Cells**: `metal` on the hull, spine, nose, skids, engine, nozzles, hatches and fins (panels four cells square, a seam a step down, a rivet a step and a half up in each panel's corner); `crystal` on the canopy and the portholes; the orange band, stripe and wings plain `skin` cells; the exhausts `glow`; the soot plates and the smoke plain cells of their own greys (the `second` slate and the `ink` slot, which on this prop is smoke grey, not black).
- **The crash**: the diorama pitches the whole prop 12 degrees nose-down and sinks the nose into the ground, with a few dirt blocks thrown up round it (`tools/blender/blocky_scene.py`); the prop itself stays axis-aligned on y = 0, so the game can also place it level (repaired) later. The smoke is part of the prop so it pitches with it; in the game it becomes a Feet emitter on the nose and these blocks are dropped.

## Parts

```yaml
parts:
  # the hull: a white body in rivet panels with a raised spine, on two long skids
  - {name: Hull, slot: Body, size: [3.5, 2.5, 9], at: [0, 1.75, 0], material: metal}
  - {name: Spine, slot: Body, size: [2.5, 0.5, 7], at: [0, 3.25, 0.5], material: metal}
  - {name: Skid, slot: BodyDark, size: [0.5, 0.5, 6], at: [1.25, 0.25, 0.5], mirror: x, material: metal}
  # the nose: a white step, then a scorched dark cone and tip, soot plates on its top and sides
  - {name: Nose, slot: Body, size: [2.5, 2, 2], at: [0, 1.5, -5.5], material: metal}
  - {name: NoseCone, slot: BodyDark, size: [1.5, 1.25, 1], at: [0, 1.375, -7], material: metal}
  - {name: NoseTip, slot: BodyDark, size: [0.75, 0.75, 0.5], at: [0, 1.375, -7.75], material: metal}
  - {name: Soot, slot: BodyDark, size: [1.75, 0.125, 1.5], at: [0, 2.5625, -5.5]}
  - {name: SootSide, slot: BodyDark, size: [0.125, 1, 1.5], at: [1.3125, 1.5, -5.5], mirror: x}
  # the cockpit: a dark frame on the spine under a cyan canopy with a white cap
  - {name: Frame, slot: BodyDark, size: [2.5, 0.75, 3], at: [0, 3.375, -2.25], material: metal}
  - {name: Canopy, slot: Accessory, size: [2, 0.75, 2.5], at: [0, 4.125, -2.25], material: crystal}
  - {name: CanopyCap, slot: Body, size: [1.5, 0.25, 1.75], at: [0, 4.625, -2], material: metal}
  # portholes and a hatch on each side
  - {name: Porthole, slot: Accessory, size: [0.125, 0.5, 0.5], at: [1.8125, 2.5, -3.5], mirror: x, material: crystal}
  - {name: Porthole2, slot: Accessory, size: [0.125, 0.5, 0.5], at: [1.8125, 2.5, -2.5], mirror: x, material: crystal}
  - {name: Hatch, slot: BodyDark, size: [0.125, 1, 1], at: [1.8125, 2.25, -0.25], mirror: x, material: metal}
  # the orange band round the hull and the stripe down the spine
  - {name: Band, slot: Trim, size: [3.75, 2.75, 0.75], at: [0, 1.75, 1.5]}
  - {name: Stripe, slot: Trim, size: [1, 0.125, 4], at: [0, 3.5625, 2]}
  # the tail: a swept fin with a tip, two tail planes, an antenna
  - {name: Fin, slot: Trim, size: [0.25, 2.5, 2], at: [0, 4.25, 3.5]}
  - {name: FinTip, slot: Trim, size: [0.25, 1, 1], at: [0, 5.75, 4]}
  - {name: TailPlane, slot: Trim, size: [2, 0.25, 1.5], at: [2.75, 2.25, 3.5], mirror: x}
  - {name: Antenna, slot: BodyDark, size: [0.125, 1, 0.125], at: [1.0625, 4, 2.5625], material: metal}
  # one whole wing and one snapped short, two shards left on the stub
  - {name: Wing, slot: Trim, size: [3.5, 0.25, 3], at: [3.5, 1.625, 0]}
  - {name: WingStub, slot: Trim, size: [1.25, 0.25, 2.5], at: [-2.375, 1.625, 0.25]}
  - {name: Shard, slot: Trim, size: [0.5, 0.25, 0.75], at: [-3.25, 1.625, -0.5]}
  - {name: Shard2, slot: Trim, size: [0.5, 0.25, 0.5], at: [-3.25, 1.625, 0.75]}
  # the engine: a dark block with three nozzles, the middle exhaust lit
  - {name: Engine, slot: BodyDark, size: [3, 2, 1.5], at: [0, 1.75, 5.25], material: metal}
  - {name: Nozzle, slot: BodyDark, size: [1.25, 1.25, 0.5], at: [0, 1.75, 6.25], material: metal}
  - {name: Nozzle2, slot: BodyDark, size: [0.75, 0.75, 0.5], at: [1, 1.25, 6.25], mirror: x, material: metal}
  - {name: Exhaust, slot: Glow, size: [1, 1, 0.125], at: [0, 1.75, 6.5625]}
  - {name: Exhaust2, slot: Glow, size: [0.5, 0.5, 0.125], at: [1, 1.25, 6.5625]}
  # a little smoke made of cells: four grey blocks rising and drifting to the right off the scorched nose
  - {name: Smoke, slot: Eye, size: [0.5, 0.5, 0.5], at: [0.25, 2.375, -6.75]}
  - {name: Smoke2, slot: Eye, size: [0.75, 0.75, 0.75], at: [0.625, 3.125, -7.125], rot: [0, 15, 0]}
  - {name: Smoke3, slot: Eye, size: [1, 1, 1], at: [1.25, 4.0625, -7.5], rot: [0, -20, 0]}
  - {name: Smoke4, slot: Eye, size: [1.25, 1.25, 1.25], at: [2.125, 5.1875, -7.75], rot: [0, 15, 0]}
```

## Renders

In the World 1 diorama (v2, with all sixteen World 1 aliens): ![[world1_scene_v2.jpg]]

The v1 ship, for the before: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build: the rivet panels make a plain box read as a hull; the snapped wing and the pitch sell the crash. Status concept.
- 2026-10-19, World 1 roster worker. Version 2: 14.4 studs, 44 blocks; the cockpit, portholes, hatch, fin, tail planes, three nozzles, scorched nose and cell smoke added. Status concept.
