---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: PathLantern
name: Starhollow path lantern
world: 1
region: Forest
kind: prop
status: build
height: 5.5
blocks: 14
tris: 168
budget: 260
collision: Box
collision_slots: {Accessory: None}
footprint: [1.75, 1.5, 5.5]
palette: ["#3A3562", "#272340", "#2C7F72", "#A891E6", "#FFB84D"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/PathLantern/PathLantern.glb"
---
# Starhollow path lantern (World 1 Verdant, Starhollow Forest)

The lantern that lines Starhollow's paths, about the avatar's height: a dark post on a stone foot, a box lantern of warm-white light in a dark iron frame with a stepped roof and a violet knob, moss at its foot. Every few studs along the pale path, it is the warm note in the cool forest.

- **Cells**: the post in `wood`, the foot in `stone`, the frame and roof in `metal`; the light `glow`, warm amber FFB84D (it was warm white FFE7B0, which read as an unlit white block under bloom at night, Mac job 53 step 5; the world kit adds a PointLight in the same family, FFC46B)
- **The reference**: the lantern posts beside the glowcaps in ZPLYSA3uR (15 to 19 s)
- **Collision**: Box (post and lantern); the moss none
- **Footprint**: 1.75 x 1.5 x 5.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 260 triangles (the estimate before culling is 168); collision `Box` in `src/shared/data/Props.luau` with `Accessory` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the post, the lantern and the moss
  - {name: Foot, slot: BodyDark, size: [1, 0.5, 1], at: [0, 0.25, 0], material: stone}
  - {name: Post, slot: BodyDark, size: [0.5, 3, 0.5], at: [0, 2, 0], material: wood}
  - {name: Collar, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [0, 3.375, 0], material: wood}
  - {name: Base, slot: Body, size: [1.25, 0.25, 1.25], at: [0, 3.625, 0], material: metal}
  - {name: Corner, slot: Body, size: [0.125, 1, 0.125], at: [0.4375, 4.25, -0.4375], mirror: x}
  - {name: CornerBack, slot: Body, size: [0.125, 1, 0.125], at: [0.4375, 4.25, 0.4375], mirror: x}
  - {name: Roof, slot: Body, size: [1.5, 0.25, 1.5], at: [0, 4.875, 0], material: metal}
  - {name: RoofTop, slot: Body, size: [1, 0.25, 1], at: [0, 5.125, 0], material: metal}
  - {name: Knob, slot: Trim, size: [0.25, 0.25, 0.25], at: [0, 5.375, 0]}
  - {name: Light, slot: Glow, size: [0.75, 1, 0.75], at: [0, 4.25, 0]}
  - {name: Tuft, slot: Accessory, size: [0.75, 0.25, 0.5], at: [-0.625, 0.625, -0.5], material: moss}
  - {name: Tuft2, slot: Accessory, size: [0.5, 0.25, 0.5], at: [0.5, 0.625, 0.5], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
