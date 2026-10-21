---
tags: [alien-game, prop, blocky]
up: "[[Alien-Game]]"
id: ShrineStone
name: Shrine stone
world: 0
kind: prop
status: build
height: 5.25
blocks: 6
tris: 72
budget: 160
collision: Box
footprint: [2, 1.375, 5.25]
palette: ["#9E9E8E", "#7C7C6E", "#6CB04A", "#9BE7FF"]
roles: [body, second, accent, glow]
render: "[[props_v1.jpg]]"
glb: "assets/models/props/ShrineStone/ShrineStone.glb"
---
# Shrine stone (every world)

One standing stone of a shrine ring (the ring the world builder lays round the Pedestal where a world has no hero Shrine, as in Frostbyte and on the home planet): a tall cobbled stone on a foot slab with a smaller stone on top, a glowing rune and a dot on its face, a tuft of moss on its crown. Its stone takes the layout's tint; the rune stays lit.

- **Cells**: `stone` cobbles; the rune `glow` in a cool cyan (Neon, so Props.Tint keeps it)
- **Footprint**: 2 x 1.375 x 5.25 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract); the blockout it replaces was 2 x 1.25 x 5.
- **Budget**: 160 triangles (the estimate before culling is 72); collision `Box` in `src/shared/data/Props.luau`.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the stone, its top and its foot
  - {name: Stone, slot: Body, size: [1.75, 4.25, 1.125], at: [0, 2.375, 0.0625], material: stone}
  - {name: Top, slot: Body, size: [1.25, 0.5, 0.875], at: [-0.125, 4.75, 0.0625], material: stone}
  - {name: Foot, slot: BodyDark, size: [2, 0.25, 1.25], at: [0, 0.125, 0], material: stone}
  # a rune and a dot
  - {name: Rune, slot: Glow, size: [0.5, 1.5, 0.125], at: [0, 2.75, -0.6875]}
  - {name: RuneDot, slot: Glow, size: [0.25, 0.25, 0.125], at: [0, 1.625, -0.6875]}
  # moss
  - {name: Moss, slot: Accessory, size: [1, 0.25, 0.75], at: [-0.25, 5.125, 0.125], material: moss}
```

## Renders

On the props sheet: ![[props_v1.jpg]]

## Reviews

- 2026-10-21, props worker. First block-cell build (replaces the smooth blockout where one existed). Status build: waiting for Ethan's look at the props sheet.
