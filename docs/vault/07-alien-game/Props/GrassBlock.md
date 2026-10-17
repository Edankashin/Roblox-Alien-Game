---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: GrassBlock
name: Ground blocks
world: 1
kind: prop
status: concept
height: 2
blocks: 6
tris: 72
palette: ["#6FBF4A", "#8A5A3B", "#C9B48A", "#3FA2E6"]
roles: [body, second, accent, trim]
render: "[[world1_scene_v1.jpg]]"
glb: ""
---
# Ground blocks (World 1 Verdant)

The ground of World 1 built from the same block cells as the creatures ([[Blocky-Style]] "Environment"): 2 x 1 x 2 stud blocks at the world cell (4 cells a stud, 8 across a block), so the meadow is a tiled grid of blocks like the voxel-brick reference (`media/tiktok/NOTES.md` ZPL8MtkYu). Four kinds, one column of each in the parts table below; `tools/blender/blocky_scene.py` reads them by name to build the diorama's ground, so a change here changes the whole meadow.

- **Grass**: the top block of a column. `grass` cells: the top is the meadow green (Meadow.luau's floor colour) with faint blobs and a lit blade now and then; the sides are dirt under a grass fringe one to three cells deep, its top row lit.
- **Dirt**: every block under the top one. `dirt` cells: packed earth, faint blobs, a pebble cell in twenty.
- **Path**: a top block of `stone` cells in a sandy colour: cobbles three cells across parted by a one-cell crack.
- **Water**: the pond's surface, three quarters of a stud tall so it sits a quarter stud under the grass. `water` cells: diagonal ripple dashes, a sparkle now and then; glossy in the build.

The four colours take the four surface roles because the ground has no face and no ink: body grass, second dirt, accent path, trim water (the trim slot is the glossy one).

## Parts

```yaml
parts:
  # one column of each kind: grass over dirt, path over dirt, water over the pond bed
  - {name: Dirt, slot: BodyDark, size: [2, 1, 2], at: [0, 0.5, 0], material: dirt}
  - {name: Grass, slot: Body, size: [2, 1, 2], at: [0, 1.5, 0], material: grass}
  - {name: PathDirt, slot: BodyDark, size: [2, 1, 2], at: [2, 0.5, 0], material: dirt}
  - {name: Path, slot: Accessory, size: [2, 1, 2], at: [2, 1.5, 0], material: stone}
  - {name: PondBed, slot: BodyDark, size: [2, 1, 2], at: [4, 0.5, 0], material: dirt}
  - {name: Water, slot: Trim, size: [2, 0.75, 2], at: [4, 1.375, 0], material: water}
```

## Renders

The diorama, every ground block from this table: ![[world1_scene_v1.jpg]]

## Reviews

- 2026-10-17, block-cell worker. First build in the World 1 diorama: 2-stud blocks at the world cell, each top outlined by a half-step darker rim so the meadow reads as tiled blocks; the grass fringe on every exposed side; the path's cobbles and the pond's ripples read at hero-shot distance. Status concept.
