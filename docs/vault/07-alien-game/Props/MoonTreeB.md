---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: MoonTreeB
name: Moon tree, two-tier
world: 1
region: Forest
kind: prop
status: build
height: 19.75
blocks: 27
tris: 324
budget: 700
collision: Box
collision_slots: {Glow: None, Trim: None}
footprint: [13.5, 11.125, 19.75]
palette: ["#2A8A94", "#4A2F86", "#5560D0", "#D2B0FF", "#9B3FD0"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/MoonTreeB/MoonTreeB.glb"
---
# Moon tree, two-tier (World 1 Verdant, Starhollow Forest)

The second moon tree, so a grove never repeats: a taller, slimmer violet trunk carrying two teal tiers with the trunk showing between them and a tuft on top, indigo clumps on both tiers, violet bracket fungus up the trunk and pink light dripping from both tiers.

- **Cells**: the trunk in `wood`; the tiers and clumps in `moss` (the indigo accent as the sprig cell in the teal); the drips `glow`, deep violet 9B3FD0 (it was pale pink FFB3E6, which bloomed to white at night, Mac job 58)
- **Silhouette**: the gap between the tiers is the shape the reference's stacked trees have; MoonTree is one broad crown, this is two layers
- **Collision**: trunk and tiers box apart; drips and fungus none
- **Footprint**: 13.5 x 11.125 x 19.75 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 700 triangles (the estimate before culling is 324); collision `Box` in `src/shared/data/Props.luau` with `Glow` None, `Trim` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # trunk, roots and a bough
  - {name: Trunk, slot: BodyDark, size: [1.75, 15, 1.75], at: [0, 7.5, 0], material: wood}
  - {name: Root, slot: BodyDark, size: [0.75, 1.25, 0.75], at: [1.25, 0.625, 0.25], mirror: x, material: wood}
  - {name: RootFront, slot: BodyDark, size: [0.75, 0.75, 0.75], at: [-0.25, 0.375, -1.25], material: wood}
  - {name: RootBack, slot: BodyDark, size: [1, 1, 0.75], at: [0.25, 0.5, 1.25], material: wood}
  - {name: Bough, slot: BodyDark, size: [2.25, 0.5, 0.5], at: [-1.75, 12.875, 0.25], rot: [0, 0, -18], material: wood}
  # the low tier
  - {name: Tier, slot: Body, size: [10, 2, 10], at: [0, 11, 0], material: moss}
  - {name: TierStep, slot: Body, size: [7, 1.5, 7], at: [0.5, 12.75, 0.5], material: moss}
  - {name: TierLobe, slot: Body, size: [2.5, 1.5, 4], at: [6.25, 10.75, -0.5], material: moss}
  # the high tier and the tuft
  - {name: Tier2, slot: Body, size: [8, 2, 8], at: [0.5, 15.25, -0.5], material: moss}
  - {name: Tier2Step, slot: Body, size: [5.5, 1.5, 5.5], at: [0.25, 17, -0.25], material: moss}
  - {name: Top, slot: Body, size: [3, 1.25, 3], at: [0, 18.375, 0], material: moss}
  - {name: TopTuft, slot: Body, size: [1.5, 0.75, 1.5], at: [0.5, 19.375, -0.5], material: moss}
  # indigo clumps on both tiers
  - {name: Clump, slot: Accessory, size: [3, 1.75, 3], at: [-4.5, 11.375, -3.625], material: moss}
  - {name: Clump2, slot: Accessory, size: [3.5, 1.5, 2.5], at: [2.75, 11.75, 4.75], material: moss}
  - {name: Clump3, slot: Accessory, size: [2.5, 1.5, 3], at: [-4.25, 15.25, 2.25], material: moss}
  - {name: Clump4, slot: Accessory, size: [3, 1.25, 2.5], at: [3.5, 16.125, -3.375], material: moss}
  # pink light dripping from both tiers
  - {name: Drip, slot: Glow, size: [0.25, 1.5, 0.25], at: [-3.875, 9.25, -4.625]}
  - {name: Drip2, slot: Glow, size: [0.25, 1, 0.25], at: [4.625, 9.5, 2.125]}
  - {name: Drip3, slot: Glow, size: [0.25, 2, 0.25], at: [1.125, 9, -4.875]}
  - {name: Drip4, slot: Glow, size: [0.25, 1.25, 0.25], at: [-4.875, 9.375, 3.375]}
  - {name: Drip5, slot: Glow, size: [0.25, 1.25, 0.25], at: [3.875, 13.625, -4.125]}
  - {name: Drip6, slot: Glow, size: [0.25, 1, 0.25], at: [-3.125, 13.75, 3.125]}
  - {name: Bead, slot: Glow, size: [0.5, 0.5, 0.5], at: [1.125, 7.75, -4.875]}
  # bracket fungus
  - {name: Bracket, slot: Trim, size: [1, 0.25, 0.75], at: [-1.375, 5.125, -0.25]}
  - {name: Bracket2, slot: Trim, size: [0.75, 0.25, 1], at: [0.625, 8.125, -1.375]}
  - {name: Bracket3, slot: Trim, size: [1.25, 0.25, 0.75], at: [1.5, 3.125, 0.375]}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
