---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: GlowcapGiantPink
name: Giant glowcap, dusk pink
world: 1
region: Forest
kind: prop
status: build
height: 19.5
blocks: 18
tris: 216
budget: 600
collision: Box
collision_slots: {Body: None, Accessory: None, Glow: None, Trim: None}
footprint: [11, 11, 19.5]
palette: ["#F49AD8", "#E4DAF4", "#B85CA6", "#2C7F72", "#FFB3E6"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/GlowcapGiantPink/GlowcapGiantPink.glb"
---
# Giant glowcap, dusk pink (World 1 Verdant, Starhollow Forest)

The smallest of the three giants (four avatars tall): a pale stem leaning the other way, a rounder, taller cap in dusk pink over plum gills, a ring of pink light under its edge and two drips.

- **Cells**: plain cells (skin jitter) on the stem and the cap, so the stepped edges read cleanly; the gills a darker accent under the cap; `moss` at the foot; the rim and the drips `glow` (Neon: the grove's light)
- **Scale**: three to five times the 5-stud avatar, the gills high over its head, so a player walks among the stems
- **Variety**: each giant leans, steps and stands at its own height, so a grove of the three never reads as one mushroom copied
- **Collision**: only the stem (BodyDark) collides, as a box; the cap, gills, rim, drips and moss never do
- **Footprint**: 11 x 11 x 19.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 600 triangles (the estimate before culling is 216); collision `Box` in `src/shared/data/Props.luau` with `Body` None, `Accessory` None, `Glow` None, `Trim` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the stem in three steps and its foot
  - {name: Foot, slot: BodyDark, size: [3, 1, 3], at: [0, 0.5, 0]}
  - {name: Stem, slot: BodyDark, size: [2, 5, 2], at: [0, 3.5, 0]}
  - {name: Stem2, slot: BodyDark, size: [1.75, 5, 1.75], at: [-0.25, 8.5, 0]}
  - {name: Stem3, slot: BodyDark, size: [1.5, 3, 1.5], at: [-0.625, 12.5, -0.125]}
  # the cap: gills under, then stepped plates
  - {name: Skirt, slot: Accessory, size: [2.5, 0.5, 2.5], at: [-0.25, 9.75, 0]}
  - {name: Gills, slot: Accessory, size: [9, 0.75, 9], at: [-0.5, 14.375, 0]}
  - {name: CapRim, slot: Body, size: [11, 1.5, 11], at: [-0.5, 15.5, 0]}
  - {name: CapMid, slot: Body, size: [9, 1.5, 9], at: [-0.5, 17, 0]}
  - {name: CapTop, slot: Body, size: [6, 1, 6], at: [-0.5, 18.25, 0]}
  - {name: CapCrown, slot: Body, size: [2.5, 0.75, 2.5], at: [-0.25, 19.125, 0.25]}
  # the glowing rim under the cap's edge, and its drips
  - {name: RimFront, slot: Glow, size: [11, 0.5, 0.5], at: [-0.5, 14.5, -5.25]}
  - {name: RimBack, slot: Glow, size: [11, 0.5, 0.5], at: [-0.5, 14.5, 5.25]}
  - {name: RimLeft, slot: Glow, size: [0.5, 0.5, 10], at: [-5.75, 14.5, 0]}
  - {name: RimRight, slot: Glow, size: [0.5, 0.5, 10], at: [4.75, 14.5, 0]}
  - {name: Drip, slot: Glow, size: [0.25, 1.25, 0.25], at: [-2.875, 13.625, -5.125]}
  - {name: Drip2, slot: Glow, size: [0.25, 1.5, 0.25], at: [4.625, 13.5, 1.875]}
  # moss at the foot
  - {name: Moss, slot: Trim, size: [2.5, 0.5, 1.5], at: [0.75, 0.25, -2.5], material: moss}
  - {name: Moss2, slot: Trim, size: [1.5, 0.25, 2], at: [-2.5, 0.125, 0.5], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
