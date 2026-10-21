---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: GlowcapGiantBlue
name: Giant glowcap, sky blue
world: 1
region: Forest
kind: prop
status: build
height: 20.5
blocks: 18
tris: 216
budget: 600
collision: Box
collision_slots: {Body: None, Accessory: None, Glow: None, Trim: None}
footprint: [13, 13, 20.5]
palette: ["#86C8F5", "#DCD6F2", "#4A78C0", "#2C7F72", "#A6E8FF"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/GlowcapGiantBlue/GlowcapGiantBlue.glb"
---
# Giant glowcap, sky blue (World 1 Verdant, Starhollow Forest)

The flat-topped giant: a straight pale stem and a wide, low cap in sky blue, a thin lip and a tier on top, over deep blue gills, with a ring of sky-blue light under its edge and three drips.

- **Cells**: plain cells (skin jitter) on the stem and the cap, so the stepped edges read cleanly; the gills a darker accent under the cap; `moss` at the foot; the rim and the drips `glow` (Neon: the grove's light)
- **Scale**: three to five times the 5-stud avatar, the gills high over its head, so a player walks among the stems
- **Silhouette**: the flat table cap of the reference's blue glowcaps, against the white's dome and the pink's round top
- **Collision**: only the stem (BodyDark) collides, as a box; the cap, gills, rim, drips and moss never do
- **Footprint**: 13 x 13 x 20.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 600 triangles (the estimate before culling is 216); collision `Box` in `src/shared/data/Props.luau` with `Body` None, `Accessory` None, `Glow` None, `Trim` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the stem in three steps and its foot
  - {name: Foot, slot: BodyDark, size: [3.5, 1, 3.5], at: [0, 0.5, 0]}
  - {name: Stem, slot: BodyDark, size: [2.5, 7, 2.5], at: [0, 4.5, 0]}
  - {name: Stem2, slot: BodyDark, size: [2, 8, 2], at: [0, 12, -0.25]}
  # the cap: gills under, then stepped plates
  - {name: Skirt, slot: Accessory, size: [3, 0.5, 3], at: [0, 10.25, -0.25]}
  - {name: Gills, slot: Accessory, size: [11, 0.75, 11], at: [0, 16.375, -0.25]}
  - {name: CapRim, slot: Body, size: [13, 1, 13], at: [0, 17.25, -0.25]}
  - {name: CapLip, slot: Body, size: [12, 0.5, 12], at: [0, 18, -0.25]}
  - {name: CapTop, slot: Body, size: [9, 1, 9], at: [0, 18.75, -0.25]}
  - {name: CapTier, slot: Body, size: [6, 1.25, 6], at: [0, 19.875, -0.25]}
  # the glowing rim under the cap's edge, and its drips
  - {name: RimFront, slot: Glow, size: [13, 0.5, 0.5], at: [0, 16.5, -6.5]}
  - {name: RimBack, slot: Glow, size: [13, 0.5, 0.5], at: [0, 16.5, 6]}
  - {name: RimLeft, slot: Glow, size: [0.5, 0.5, 12], at: [-6.25, 16.5, -0.25]}
  - {name: RimRight, slot: Glow, size: [0.5, 0.5, 12], at: [6.25, 16.5, -0.25]}
  - {name: Drip, slot: Glow, size: [0.25, 1, 0.25], at: [6.125, 15.75, -2.375]}
  - {name: Drip2, slot: Glow, size: [0.25, 1.5, 0.25], at: [-3.125, 15.5, 5.875]}
  - {name: Drip3, slot: Glow, size: [0.25, 1.25, 0.25], at: [-6.125, 15.625, -4.125]}
  # moss at the foot
  - {name: Moss, slot: Trim, size: [2, 0.5, 1.5], at: [-1.5, 0.25, -2.75], material: moss}
  - {name: Moss2, slot: Trim, size: [1.5, 0.5, 2], at: [2.75, 0.25, 1], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
