---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: IceArch
name: Ice cave mouth
world: 2
kind: prop
status: concept
height: 6.5
blocks: 10
tris: 116
palette: ["#BFEBFA", "#1E2A3C", "#F2F6FA"]
roles: [body, second, accent]
render: "[[world2_scene_v1.jpg]]"
glb: ""
---
# Ice cave mouth (World 2 Frostbyte)

The mouth of the Ice Cave as a blocky arch: two ice pillars, a lintel with stepped shoulders (the chamfer of Frostbyte's ice-facet motif, drawn as a step since a block tilts only 10 to 25 degrees), two icicles hanging from the lintel, snow lying on top, and the dark of the cave behind the opening. The opening is 3 studs wide and 4 tall, so an avatar walks in and a Legendary does not. In the diorama it stands at the foot of the packed-snow cliff, turned a little toward the camp, where the layout's `IceCaveMouth` landmark sits (`src/shared/data/Frostbyte.luau`, `Landmarks`). Rules: [[Blocky-Style]] "Environment".

- **Cells**: `ice` on the pillars, lintel, shoulders and icicles (the other diagonal, glossy); `snow` on the two caps (half a stud tall, so the lip covers their sides); the cave's dark is a plain near-black block in the second colour, matte, so the opening reads as a hole from the hero camera.
- **No glow**: the arch stays unlit; the crystals carry the world's light.

## Parts

```yaml
parts:
  # two pillars, a lintel across them, stepped shoulders under the lintel's ends
  - {name: Pillar, slot: Body, size: [1.5, 4.5, 2], at: [2.25, 2.25, 0], mirror: x, material: ice}
  - {name: Lintel, slot: Body, size: [6, 1.25, 2], at: [0, 5.125, 0], material: ice}
  - {name: Shoulder, slot: Body, size: [0.5, 0.5, 2], at: [1.25, 4.25, 0], mirror: x, material: ice}
  # icicles hanging from the lintel, points down
  - {name: Icicle, slot: Body, size: [0.375, 1, 0.375], at: [0.6875, 4, -0.6875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  # snow on the lintel and the cave's dark behind the opening
  - {name: Cap, slot: Accessory, size: [5.5, 0.5, 1.75], at: [0, 6, 0.125], material: snow}
  - {name: Cap2, slot: Accessory, size: [1.75, 0.25, 1.5], at: [-1.75, 6.375, 0.125], material: snow}
  - {name: Dark, slot: BodyDark, size: [3, 4.5, 0.5], at: [0, 2.25, 0.75]}
```

## Renders

In the Frostbyte diorama: ![[world2_scene_v1.jpg]]

## Reviews

- 2026-10-19, World 2 worker. First build: against the cliff the dark opening reads as a cave mouth and the stepped shoulders as a cut arch; the icicles read from the low angle. Status concept.
