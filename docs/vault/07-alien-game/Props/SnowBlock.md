---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SnowBlock
name: Snow ground blocks
world: 2
kind: prop
status: concept
height: 2
blocks: 7
tris: 84
palette: ["#F2F6FA", "#B9CADA", "#BFEBFA", "#A9D6F5"]
roles: [body, second, accent, trim]
render: "[[world2_scene_v1.jpg]]"
glb: ""
---
# Snow ground blocks (World 2 Frostbyte)

The ground of Frostbyte, the twin of [[GrassBlock]]: 2 x 1 x 2 stud blocks at the world cell (4 cells a stud, 8 across a block), stacked on a height map by `tools/blender/blocky_scene.py --world 2`, which reads the kinds below by name. The cold materials are the "World 2: Frostbyte palette" of [[Blocky-Style]].

- **Snow**: the top block of a column. `snow` cells: a white top with soft drifts and a sparkle cell now and then; the sides are the snow lip, two to four cells deep over packed snow (the second colour), so every exposed side shows snow drifting over the layers under it.
- **PackedSnow**: every block under the top one, and a trodden trail's top. `packed_snow` cells: strata lines every third row (the fallen layers), an ice grain now and then.
- **Ice**: the floor at the ice cave's mouth. `ice` cells: light bands on the other diagonal to crystal's, glossy.
- **FrozenWater**: the pond, frozen, three quarters of a stud tall so its top sits a quarter stud under the snow. `frozen_water` cells: plates parted by cracks, a trapped bubble now and then, no grout, glossy.
- **PondBed**: packed snow under the ice.
- **Cliff**: a packed-snow block whose sides stand exposed in a wall (the ice cliff behind the cave mouth); the same material, named so the scene can stack it high.

The four colours take the four surface roles because the ground has no face: body snow, second packed snow, accent ice, trim the frozen pond (the trim slot is the glossy one).

## Parts

```yaml
parts:
  # one column of each kind: snow over packed snow, ice over packed snow, frozen water over the pond bed, a cliff block
  - {name: PackedSnow, slot: BodyDark, size: [2, 1, 2], at: [0, 0.5, 0], material: packed_snow}
  - {name: Snow, slot: Body, size: [2, 1, 2], at: [0, 1.5, 0], material: snow}
  - {name: IceUnder, slot: BodyDark, size: [2, 1, 2], at: [2, 0.5, 0], material: packed_snow}
  - {name: Ice, slot: Accessory, size: [2, 1, 2], at: [2, 1.5, 0], material: ice}
  - {name: PondBed, slot: BodyDark, size: [2, 1, 2], at: [4, 0.5, 0], material: packed_snow}
  - {name: FrozenWater, slot: Trim, size: [2, 0.75, 2], at: [4, 1.375, 0], material: frozen_water}
  - {name: Cliff, slot: BodyDark, size: [2, 1, 2], at: [6, 0.5, 0], material: packed_snow}
```

## Renders

The Frostbyte diorama, every ground block from this table: ![[world2_scene_v1.jpg]]

## Reviews

- 2026-10-19, World 2 worker. First build in the Frostbyte diorama: the snow lip over packed strata on every exposed side, the frozen pond's cracks and the cliff's layers read at hero-shot distance; the snow tops stay quiet (a half-step rim per block, the grout at half weight). Status concept.
