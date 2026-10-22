---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: CampFlag
name: Camp flag
world: 0
kind: prop
status: build
height: 9
blocks: 8
tris: 96
budget: 300
collision: Box
collision_slots: {Body: None, Accessory: None, Glow: None}
origin: [-1.5, 0, 0]
footprint: [4.25, 1.25, 9]
palette: ["#FFC83D", "#6E7690", "#68C9FE", "#8E8E86", "#FFE36B"]
roles: [body, second, accent, trim, glow]
render: "[[placeholder_props_v1.jpg]]"
glb: "assets/models/props/CampFlag/CampFlag.glb"
---
# Camp flag (both worlds, the camp)

The crew's flag at the ship bay's south-west corner, in the ShipHull's yellow and cyan: a metal pole on a stepped stone foot, a
lit finial (a beacon over the camp at night), and a yellow banner in two panels a step apart (the wind) with a cyan stripe
standing proud of it on both sides.

- **Cells**: `stone` on the foot; `metal` on the pole; `wool` on the banner and the stripe; the finial `glow`
- **Origin**: the layout places the pole's foot (the note's (0, 0, 0)), not the bounds' centre, so the pole stands where the
  placeholder's did and the banner flies to the local +X (data/Props `origin`)
- **Collision**: `Box` on the pole and the foot; the banner, the stripe and the finial none
- **Footprint**: 4.25 x 1.25 x 9 studs (W x D x H), the pivot at the bottom centre (the layout's point is the origin above); the front faces -Z here (the landmark contract).
- **Budget**: 300 triangles; collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the foot, the pole and the finial
  - {name: Base, slot: Trim, size: [1.25, 0.5, 1.25], at: [0, 0.25, 0], material: stone}
  - {name: BaseStep, slot: Trim, size: [0.75, 0.25, 0.75], at: [0, 0.625, 0], material: stone}
  - {name: Pole, slot: BodyDark, size: [0.25, 7.75, 0.25], at: [0, 4.625, 0], material: metal}
  - {name: Finial, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 8.75, 0]}
  # the banner in two panels, the far one a step back and lower (the wind), each with a cyan stripe
  - {name: Banner, slot: Body, size: [2.5, 1.75, 0.125], at: [1.375, 7.375, 0.0625], material: wool}
  - {name: BannerTail, slot: Body, size: [1, 1.5, 0.125], at: [3.125, 7.25, -0.0625], material: wool}
  - {name: Stripe, slot: Accessory, size: [2.5, 0.5, 0.375], at: [1.375, 7.375, 0.0625], material: wool}
  - {name: StripeTail, slot: Accessory, size: [1, 0.5, 0.375], at: [3.125, 7.25, -0.0625], material: wool}
```

## Renders

On the placeholder props sheet: ![[placeholder_props_v1.jpg]]

## Reviews

- 2026-10-22, placeholder props worker. First block-cell build: it replaces the block placeholder of data/WorldKit (Studio 2026-10-22: 22 placeholders in World 1, 10 in World 2). Status build: waiting for Ethan's look at the sheet.
