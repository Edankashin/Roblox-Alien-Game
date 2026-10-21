---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: Shrine
name: Shrine of the Warden
world: 1
kind: prop
status: build
height: 8
blocks: 33
tris: 396
budget: 1400
collision: Precise
footprint: [17, 18.5, 8]
palette: ["#9E9E8E", "#C8C0A6", "#5E9E3A", "#C9A15B", "#2ECC71"]
roles: [body, second, accent, trim, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/Shrine/Shrine.glb"
---
# Shrine of the Warden (World 1 Verdant)

World 1's landmark: a round paved plaza ringed by standing stones, entered from the front through a gate of two tall stones and a lintel. Every stone carries a glowing green rune on its inward face, the gate a rune on its lintel, and a square ring of rune light is set into the paving round the empty centre where the Pedestal stands (placed by the world builder, 5 x 5). Moss lies on the stones' tops and creeps over the paving; one stone has fallen.

- **Cells**: `stone` cobbles on the stones and paving (the paving a paler second colour); `moss` on the tops and the creepers; the runes `glow` in the meadow shrine's green (data/Meadow.luau Shrine.glowColor 2ECC71), Neon, so Props.Tint leaves them lit
- **Read**: the gate and the ring of stones from far away; the runes pull you in; the centre is left clear for the Pedestal
- **Footprint**: 17 x 18.5 x 8 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 18.4 x 17.8 x 8.4.
- **Budget**: 1400 triangles (the estimate before culling is 396); collision `Precise` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the plaza: three slabs make an octagon, a step at the gate
  - {name: Plaza, slot: BodyDark, size: [17, 0.25, 11], at: [0, 0.125, 0], material: stone}
  - {name: PlazaCross, slot: BodyDark, size: [11, 0.25, 17], at: [0, 0.125, 0], material: stone}
  - {name: PlazaDiag, slot: BodyDark, size: [15, 0.25, 15], at: [0, 0.125, 0], material: stone}
  - {name: Step, slot: BodyDark, size: [5, 0.25, 1.5], at: [0, 0.125, -9.25], material: stone}
  # the gate, six standing stones and a fallen one
  - {name: GateL, slot: Body, size: [1.5, 6.5, 1.25], at: [-2.25, 3.5, -7], material: stone}
  - {name: GateR, slot: Body, size: [1.5, 6.5, 1.25], at: [2.25, 3.5, -7], material: stone}
  - {name: GateTop, slot: Body, size: [6.5, 1, 1.5], at: [0, 7.25, -7], material: stone}
  - {name: East, slot: Body, size: [1.25, 5, 2], at: [7, 2.75, 0], material: stone}
  - {name: West, slot: Body, size: [1.25, 5.5, 2], at: [-7, 3, 0], material: stone}
  - {name: North, slot: Body, size: [2, 5, 1.25], at: [0, 2.75, 7], material: stone}
  - {name: Diag, slot: Body, size: [1.5, 4.5, 1.5], at: [5, 2.5, -5], material: stone}
  - {name: Diag2, slot: Body, size: [1.5, 4, 1.5], at: [-5, 2.25, -5], material: stone}
  - {name: Diag3, slot: Body, size: [1.5, 4.5, 1.5], at: [5, 2.5, 5], material: stone}
  - {name: Diag4, slot: Body, size: [1.5, 3.5, 1.5], at: [-5, 2, 5], material: stone}
  - {name: Fallen, slot: Body, size: [1.25, 1, 3], at: [-7, 0.75, 4], rot: [0, 18, 0], material: stone}
  # moss on the tops and creeping over the paving
  - {name: Moss, slot: Accessory, size: [1.5, 0.25, 1.25], at: [-2.25, 6.875, -7], material: moss}
  - {name: MossTop, slot: Accessory, size: [4, 0.25, 1.25], at: [-0.5, 7.875, -7], material: moss}
  - {name: MossE, slot: Accessory, size: [1.25, 0.25, 1.75], at: [7, 5.375, 0], material: moss}
  - {name: MossW, slot: Accessory, size: [1.25, 0.25, 2], at: [-7, 5.875, 0], material: moss}
  - {name: MossN, slot: Accessory, size: [2, 0.25, 1.25], at: [0, 5.375, 7], material: moss}
  - {name: MossD, slot: Accessory, size: [1.5, 0.25, 1.5], at: [5, 4.875, 5], material: moss}
  - {name: Creep, slot: Accessory, size: [2, 0.25, 1.5], at: [6.5, 0.375, -3], material: moss}
  - {name: Creep2, slot: Accessory, size: [1.5, 0.25, 2.5], at: [-4.5, 0.375, 6.5], material: moss}
  # runes on the stones and a ring of light round the centre
  - {name: RuneGate, slot: Glow, size: [1.5, 0.5, 0.125], at: [0, 7.25, -7.8125]}
  - {name: RuneL, slot: Glow, size: [0.5, 1.5, 0.125], at: [-2.25, 3.5, -6.3125]}
  - {name: RuneR, slot: Glow, size: [0.5, 1.5, 0.125], at: [2.25, 3.5, -6.3125]}
  - {name: RuneE, slot: Glow, size: [0.125, 1.5, 0.5], at: [6.3125, 3, 0]}
  - {name: RuneW, slot: Glow, size: [0.125, 1.5, 0.5], at: [-6.3125, 3.25, 0]}
  - {name: RuneN, slot: Glow, size: [0.5, 1.5, 0.125], at: [0, 3, 6.3125]}
  - {name: Ring, slot: Glow, size: [6, 0.125, 0.25], at: [0, 0.3125, -3.125]}
  - {name: Ring2, slot: Glow, size: [6, 0.125, 0.25], at: [0, 0.3125, 3.125]}
  - {name: Ring3, slot: Glow, size: [0.25, 0.125, 6], at: [3.125, 0.3125, 0], mirror: x}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
