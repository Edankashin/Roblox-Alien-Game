---
tags: [alien-game, prop, blocky, home]
up: "[[Alien-Game]]"
id: Flag
name: Home flag
world: 0
region: Home
kind: prop
status: build
height: 6.5
blocks: 10
tris: 120
budget: 260
collision: Box
collision_slots: {Body: None, Accessory: None, Glow: None}
footprint: [3.875, 1.5, 6.5]
palette: ["#FF8AD8", "#6E7690", "#6BCB3F", "#9E9E8E", "#FFEF4A"]
roles: [body, second, accent, trim, glow]
render: "[[home_props_v1.jpg]]"
glb: "assets/models/props/Flag/Flag.glb"
---
# Home flag (the home planet)

The player's own flag on their planet: a metal pole on a stepped stone base, a gold finial, and a pink banner caught in the wind (two panels a step apart) with a green alien head on it, antenna and glowing eyes, so it reads as "my alien planet" from across the plot.

- **Cells**: `stone` on the base; `metal` on the pole; `wool` on the banner; plain cells on the alien head; the finial and the eyes `glow`
- **Collision**: `Box` on the pole and the base; the banner, the emblem and the glow none (players run under the banner)
- **Off-centre**: the pole stands left of the bounds' centre, so the banner fits the 4-stud cell; the pivot is the bounds' bottom centre as for every prop
- **Footprint**: 3.875 x 1.5 x 6.5 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract). It stands on its footprint's centre on the plot (World.HomeRenderer, `data/HomeBuild` row `Flag`, 1 x 1 cell, 4 studs).
- **Budget**: 260 triangles (the estimate before culling is 120); collision `Box` with `Body` None, `Accessory` None, `Glow` None in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "The home planet" section. Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the base, the pole and the finial
  - {name: Base, slot: Trim, size: [1.5, 0.5, 1.5], at: [-0.875, 0.25, 0], material: stone}
  - {name: BaseStep, slot: Trim, size: [1, 0.25, 1], at: [-0.875, 0.625, 0], material: stone}
  - {name: Pole, slot: BodyDark, size: [0.25, 5.25, 0.25], at: [-0.875, 3.375, 0], material: metal}
  - {name: Finial, slot: Glow, size: [0.5, 0.5, 0.5], at: [-0.875, 6.25, 0]}
  # the banner in two panels, the far one a step back and lower (the wind)
  - {name: Banner, slot: Body, size: [1.75, 1.75, 0.125], at: [0.125, 4.875, 0.0625], material: wool}
  - {name: BannerTail, slot: Body, size: [1.25, 1.5, 0.125], at: [1.625, 4.75, -0.0625], material: wool}
  # the alien head on the banner, standing proud of it on both sides
  - {name: Emblem, slot: Accessory, size: [1, 0.875, 0.375], at: [0.125, 4.8125, 0.0625]}
  - {name: EmblemAntenna, slot: Accessory, size: [0.125, 0.25, 0.375], at: [0.0625, 5.375, 0.0625]}
  - {name: EmblemEye, slot: Glow, size: [0.25, 0.25, 0.625], at: [0.375, 4.875, 0.0625]}
  - {name: EmblemEyeL, slot: Glow, size: [0.25, 0.25, 0.625], at: [-0.125, 4.875, 0.0625]}
```

## Renders

On the home props sheet: ![[home_props_v1.jpg]]

## Reviews

- 2026-10-21, launch polish worker. First block-cell build: the home's nine props were placeholders until now (Decision B49, Launch week). Status build: waiting for Ethan's look at the home props sheet.
