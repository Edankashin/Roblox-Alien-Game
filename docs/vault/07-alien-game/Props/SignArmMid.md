---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: SignArmMid
name: Sights signpost arm: Waterfall
world: 1
kind: prop
status: build
height: 1.25
blocks: 5
tris: 60
budget: 200
collision: None
origin: [-2.125, -3.25, 0]
footprint: [3.75, 0.5, 1.25]
palette: ["#E8D4A8", "#3FA2E6", "#5A5A66", "#3B2A1E"]
roles: [body, accent, trim, ink]
render: "[[placeholder_props_v1.jpg]]"
glb: "assets/models/props/SignArmMid/SignArmMid.glb"
---
# Sights signpost arm: Waterfall (World 1 Verdant, the camp)

One of the three arms of the camp's sights signpost (on [[SightPost]], with [[SignArmHigh]] and [[SignArmLow]]): a cream board with
**WATERFALL** painted on both faces in pixel letters, an iron band where it meets the post, and a stepped arrowhead in the waterfall's
blue, pointing along the note's +X, the local +X the layout yaws at the sight (world_gen: yaw = atan2(-dz, dx)).

- **Cells**: `wood` on the board (the letters drawn over its cells in the ink, a quarter cell a letter pixel: cells.py
  `lettering`, the board's `text`); `metal` on the band; the arrowhead plain cells
- **Origin**: the layout places the post's foot (the note's (0, 0, 0)); the arm floats 3.25 studs up, on the mid place
  of the post (data/Props `origin`); the GLB itself stands on its bottom centre like every prop
- **Collision**: `None` (over the path, a board players walk under or past)
- **Words**: English in the texture (Ethan's ask); a translated build would draw the sight's string (`src/shared/strings`) on the
  board with a SurfaceGui instead
- **Footprint**: 3.75 x 0.5 x 1.25 studs (W x D x H), the pivot at the bottom centre (the layout's point is the origin above); the front faces -Z here (the landmark contract).
- **Budget**: 200 triangles; collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the board, its painted name, the iron band that holds it to the post
  - {name: Board, slot: Body, size: [3, 1, 0.25], at: [1.75, 3.875, 0], material: wood, text: "WATERFALL"}
  - {name: Band, slot: Trim, size: [0.25, 1.25, 0.5], at: [0.375, 3.875, 0], material: metal}
  # the stepped arrowhead in the sight's colour
  - {name: Head, slot: Accessory, size: [0.25, 1.25, 0.25], at: [3.375, 3.875, 0]}
  - {name: Head2, slot: Accessory, size: [0.25, 0.75, 0.25], at: [3.625, 3.875, 0]}
  - {name: Head3, slot: Accessory, size: [0.25, 0.25, 0.25], at: [3.875, 3.875, 0]}
```

## Renders

On the placeholder props sheet: ![[placeholder_props_v1.jpg]]

## Reviews

- 2026-10-22, placeholder props worker. First block-cell build: it replaces the block placeholder of data/WorldKit (Studio 2026-10-22: 22 placeholders in World 1, 10 in World 2). Status build: waiting for Ethan's look at the sheet.
