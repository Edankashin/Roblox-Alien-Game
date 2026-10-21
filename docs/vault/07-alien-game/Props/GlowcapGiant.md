---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: GlowcapGiant
name: Giant glowcap, moon white
world: 1
region: Forest
kind: prop
status: build
height: 23.75
blocks: 20
tris: 240
budget: 600
collision: Box
collision_slots: {Body: None, Accessory: None, Glow: None, Trim: None}
footprint: [15, 15, 23.75]
palette: ["#ECE6FF", "#D6CCEE", "#9C8FD0", "#2C7F72", "#EEF6FF"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/GlowcapGiant/GlowcapGiant.glb"
---
# Giant glowcap, moon white (World 1 Verdant, Starhollow Forest)

The grove's tallest mushroom, nearly five times the avatar: a pale stem in three steps that lean a little, a skirt, and a broad cap of four stepped plates in moon white over lavender gills, with a ring of white light under its edge and three drips falling from it.

- **Cells**: plain cells (skin jitter) on the stem and the cap, so the stepped edges read cleanly; the gills a darker accent under the cap; `moss` at the foot; the rim and the drips `glow` (Neon: the grove's light)
- **Scale**: three to five times the 5-stud avatar, the gills high over its head, so a player walks among the stems
- **The reference**: the giant glowcaps of ZPLYSA3uR (15 to 19 s), pastel white, pink and blue, rebuilt as stepped block caps
- **Collision**: only the stem (BodyDark) collides, as a box; the cap, gills, rim, drips and moss never do
- **Footprint**: 15 x 15 x 23.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 600 triangles (the estimate before culling is 240); collision `Box` in `src/shared/data/Props.luau` with `Body` None, `Accessory` None, `Glow` None, `Trim` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the stem in three steps and its foot
  - {name: Foot, slot: BodyDark, size: [3.5, 1, 3.5], at: [0, 0.5, 0]}
  - {name: Stem, slot: BodyDark, size: [2.5, 6, 2.5], at: [0, 4, 0]}
  - {name: Stem2, slot: BodyDark, size: [2, 6, 2], at: [0.25, 10, 0.25]}
  - {name: Stem3, slot: BodyDark, size: [1.75, 5.5, 1.75], at: [0.625, 15.75, 0.375]}
  # the cap: gills under, then stepped plates
  - {name: Skirt, slot: Accessory, size: [3, 0.5, 3], at: [0.25, 12.25, 0.25]}
  - {name: Gills, slot: Accessory, size: [13, 0.75, 13], at: [0.5, 18.875, 0]}
  - {name: CapRim, slot: Body, size: [15, 1.5, 15], at: [0.5, 20, 0]}
  - {name: CapMid, slot: Body, size: [12, 1.25, 12], at: [0.5, 21.375, 0]}
  - {name: CapTop, slot: Body, size: [8, 1, 8], at: [0.5, 22.5, 0]}
  - {name: CapCrown, slot: Body, size: [4, 0.75, 4], at: [0.5, 23.375, 0]}
  # the glowing rim under the cap's edge, and its drips
  - {name: RimFront, slot: Glow, size: [15, 0.5, 0.5], at: [0.5, 19, -7.25]}
  - {name: RimBack, slot: Glow, size: [15, 0.5, 0.5], at: [0.5, 19, 7.25]}
  - {name: RimLeft, slot: Glow, size: [0.5, 0.5, 14], at: [-6.75, 19, 0]}
  - {name: RimRight, slot: Glow, size: [0.5, 0.5, 14], at: [7.75, 19, 0]}
  - {name: Drip, slot: Glow, size: [0.25, 1.5, 0.25], at: [-4.375, 18, -7.125]}
  - {name: Drip2, slot: Glow, size: [0.25, 1, 0.25], at: [7.625, 18.25, 3.375]}
  - {name: Drip3, slot: Glow, size: [0.25, 1.25, 0.25], at: [2.125, 18.125, 7.125]}
  # moss at the foot
  - {name: Moss, slot: Trim, size: [3, 0.5, 1.5], at: [-0.5, 0.25, -2.75], material: moss}
  - {name: Moss2, slot: Trim, size: [1.5, 0.5, 2.5], at: [2.75, 0.25, 0.75], material: moss}
  - {name: Moss3, slot: Trim, size: [1.5, 0.25, 1.5], at: [-2.5, 0.125, 1.75], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
