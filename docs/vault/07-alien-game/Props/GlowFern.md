---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: GlowFern
name: Glow fern
world: 1
region: Forest
kind: prop
status: build
height: 1.625
blocks: 19
tris: 228
budget: 320
collision: None
footprint: [3.25, 3.25, 1.625]
palette: ["#2F9A8A", "#1F6670", "#A6E8FF"]
roles: [body, second, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/GlowFern/GlowFern.glb"
---
# Glow fern (World 1 Verdant, Starhollow Forest)

A small fern for the forest floor: four fronds stepping out and up from a moss knot, each ending in a glowing sky-blue tip, and a glowing fiddlehead curling at the centre. Under the moon trees and along the stream, a scatter of light at ankle height.

- **Cells**: plain cells on the fronds (their blocks are too small for a motif), `moss` on the knot; the tips and curl `glow`
- **Collision**: none
- **Footprint**: 3.25 x 3.25 x 1.625 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 320 triangles (the estimate before culling is 228); collision `None` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the knot, the stalk and four stepped fronds
  - {name: Base, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [0, 0.125, 0], material: moss}
  - {name: Stalk, slot: Body, size: [0.25, 0.75, 0.25], at: [0, 0.625, 0]}
  - {name: Frond, slot: Body, size: [0.75, 0.25, 0.25], at: [0.5, 0.75, 0], mirror: x}
  - {name: FrondOut, slot: Body, size: [0.5, 0.25, 0.25], at: [1.125, 1, 0], mirror: x}
  - {name: FrondFront, slot: Body, size: [0.25, 0.25, 0.75], at: [0, 0.875, -0.5]}
  - {name: FrondFrontOut, slot: Body, size: [0.25, 0.25, 0.5], at: [0, 1.125, -1.125]}
  - {name: FrondBack, slot: Body, size: [0.25, 0.25, 0.75], at: [0, 1, 0.5]}
  - {name: FrondBackOut, slot: Body, size: [0.25, 0.25, 0.5], at: [0, 1.25, 1.125]}
  - {name: Leaflet, slot: Body, size: [0.25, 0.125, 0.5], at: [0.5, 0.9375, 0], mirror: x}
  - {name: LeafletFront, slot: Body, size: [0.5, 0.125, 0.25], at: [0, 1.0625, -0.5]}
  # glowing tips and the fiddlehead
  - {name: Tip, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.5, 0.875, 0], mirror: x}
  - {name: TipFront, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 1, -1.5]}
  - {name: TipBack, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 1.125, 1.5]}
  - {name: Curl, slot: Glow, size: [0.25, 0.375, 0.25], at: [0, 1.1875, 0]}
  - {name: CurlTop, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.125, 1.5, 0]}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
