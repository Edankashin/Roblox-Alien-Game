---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: MossStone
name: Moss stone
world: 1
region: Forest
kind: prop
status: build
height: 3
blocks: 11
tris: 132
budget: 320
collision: Hull
collision_slots: {Glow: None}
footprint: [3.75, 3, 3]
palette: ["#5D5BA0", "#4C4894", "#2E8A70", "#D2B0FF"]
roles: [body, second, accent, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/MossStone/MossStone.glb"
---
# Moss stone (World 1 Verdant, Starhollow Forest)

A chunky indigo-grey rock with a moss blanket over its top and down one side, and four violet glow specks on it like resting fireflies. The forest's scatter rock, beside the path and round the pool.

- **Cells**: `stone` and `moss`; the specks `glow`
- **Collision**: Hull (players hop on it); the specks none
- **Footprint**: 3.75 x 3 x 3 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 320 triangles (the estimate before culling is 132); collision `Hull` in `src/shared/data/Props.luau` with `Glow` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the rock, the moss and the specks
  - {name: Rock, slot: Body, size: [2.5, 1.75, 2.25], at: [0, 0.875, 0], material: stone}
  - {name: RockTop, slot: Body, size: [1.75, 0.75, 1.5], at: [0.125, 2.125, 0.125], material: stone}
  - {name: Chunk, slot: Body, size: [1.25, 1, 1.25], at: [1.375, 0.5, -0.875], material: stone}
  - {name: ChunkBack, slot: Body, size: [1, 1.25, 1], at: [-1.25, 0.625, 1], material: stone}
  - {name: Moss, slot: Accessory, size: [2, 0.25, 1.75], at: [-0.25, 1.875, 0.375], material: moss}
  - {name: MossTop, slot: Accessory, size: [1.25, 0.25, 1], at: [0.125, 2.625, 0.375], material: moss}
  - {name: MossFringe, slot: Accessory, size: [0.25, 0.75, 1.25], at: [-1.375, 1.375, 0.375], material: moss}
  - {name: Speck, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.875, 1.125, -1.125]}
  - {name: Speck2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-0.75, 2.125, -0.625]}
  - {name: Speck3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.25, 1.5, 0.75]}
  - {name: Speck4, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.5, 2.875, 0.375]}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
