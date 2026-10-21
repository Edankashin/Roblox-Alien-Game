---
tags: [alien-game, prop, blocky, starhollow]
up: "[[Alien-Game]]"
id: ArchBridge
name: Little arched bridge
world: 1
region: Forest
kind: prop
status: build
height: 4.875
blocks: 40
tris: 480
budget: 600
collision: Hull
collision_slots: {BodyDark: None, Accessory: None, Glow: None, Trim: None}
footprint: [14, 4.625, 4.875]
palette: ["#B07A56", "#6A4636", "#3C3564", "#2C7F72", "#FFE7B0"]
roles: [body, second, accent, trim, glow]
render: "[[starhollow_props_v1.jpg]]"
glb: "assets/models/props/ArchBridge/ArchBridge.glb"
---
# Little arched bridge (World 1 Verdant, Starhollow Forest)

The little wooden bridge over the stream, where a player stops to watch the waterfall: seven plank steps rising to a shallow arch on two dark beams, posts and stepped rails both sides, and a warm lantern on each front end post.

- **Cells**: planks and frame in `wood` (grain along each plank), the lantern roofs in `metal`, moss tufts in `moss`; the lantern light `glow` in the warm white of the area's lamps
- **Walkable**: the deck's steps are half a stud at most and its Hull collision is one smooth convex ramp up and over; 4 studs wide
- **Collision**: only the deck (Body) collides, as a hull; the rails, posts and beams (BodyDark) do not (a box or hull of both rails would wall the deck in), so the rails are a look, not a fence
- **The reference**: the little bridge watching the glowing waterfall in ZPLYSA3uR (20 to 24 s)
- **Footprint**: 14 x 4.625 x 4.875 studs (W x D x H), the pivot at the bottom centre; the front faces -Z here and +Z in the game (the landmark contract).
- **Budget**: 600 triangles (the estimate before culling is 480); collision `Hull` in `src/shared/data/Props.luau` with `BodyDark` None, `Accessory` None, `Glow` None, `Trim` None.

Rules: [[Blocky-Style]] "Environment" (props follow the creature rules, at the world cell of 0.25 studs, no face) and its "Starhollow Forest" section (the night palette, B48). Built and exported by `tools/blocky/export_models.py --props`.

## Parts

```yaml
parts:
  # the deck: seven planks rising to the arch
  - {name: Deck, slot: Body, size: [2, 0.5, 4], at: [-6, 0.25, 0], material: wood}
  - {name: Deck2, slot: Body, size: [2, 0.5, 4], at: [-4, 0.75, 0], material: wood}
  - {name: Deck3, slot: Body, size: [2, 0.5, 4], at: [-2, 1.125, 0], material: wood}
  - {name: Deck4, slot: Body, size: [2, 0.5, 4], at: [0, 1.25, 0], material: wood}
  - {name: Deck5, slot: Body, size: [2, 0.5, 4], at: [2, 1.125, 0], material: wood}
  - {name: Deck6, slot: Body, size: [2, 0.5, 4], at: [4, 0.75, 0], material: wood}
  - {name: Deck7, slot: Body, size: [2, 0.5, 4], at: [6, 0.25, 0], material: wood}
  # two beams under the arch
  - {name: Beam1, slot: BodyDark, size: [2, 0.5, 0.5], at: [-4, 0.25, 1.75], material: wood}
  - {name: BeamF1, slot: BodyDark, size: [2, 0.5, 0.5], at: [-4, 0.25, -1.75], material: wood}
  - {name: Beam2, slot: BodyDark, size: [2, 0.5, 0.5], at: [-2, 0.625, 1.75], material: wood}
  - {name: BeamF2, slot: BodyDark, size: [2, 0.5, 0.5], at: [-2, 0.625, -1.75], material: wood}
  - {name: Beam3, slot: BodyDark, size: [2, 0.5, 0.5], at: [0, 0.75, 1.75], material: wood}
  - {name: BeamF3, slot: BodyDark, size: [2, 0.5, 0.5], at: [0, 0.75, -1.75], material: wood}
  - {name: Beam4, slot: BodyDark, size: [2, 0.5, 0.5], at: [2, 0.625, 1.75], material: wood}
  - {name: BeamF4, slot: BodyDark, size: [2, 0.5, 0.5], at: [2, 0.625, -1.75], material: wood}
  - {name: Beam5, slot: BodyDark, size: [2, 0.5, 0.5], at: [4, 0.25, 1.75], material: wood}
  - {name: BeamF5, slot: BodyDark, size: [2, 0.5, 0.5], at: [4, 0.25, -1.75], material: wood}
  # posts and stepped rails both sides
  - {name: PostEnd, slot: BodyDark, size: [0.5, 3.25, 0.5], at: [6.25, 2.125, -1.875], mirror: x, material: wood}
  - {name: PostEndBack, slot: BodyDark, size: [0.5, 2.75, 0.5], at: [6.25, 1.875, 1.875], mirror: x, material: wood}
  - {name: PostMid, slot: BodyDark, size: [0.5, 1.875, 0.5], at: [2.25, 2.3125, -1.875], mirror: x, material: wood}
  - {name: PostMidBack, slot: BodyDark, size: [0.5, 1.875, 0.5], at: [2.25, 2.3125, 1.875], mirror: x, material: wood}
  - {name: RailOuter, slot: BodyDark, size: [4.5, 0.25, 0.25], at: [4.25, 2.875, -1.875], mirror: x, material: wood}
  - {name: RailOuterBack, slot: BodyDark, size: [4.5, 0.25, 0.25], at: [4.25, 2.875, 1.875], mirror: x, material: wood}
  - {name: RailMid, slot: BodyDark, size: [4, 0.25, 0.25], at: [0, 3.125, -1.875], material: wood}
  - {name: RailMidBack, slot: BodyDark, size: [4, 0.25, 0.25], at: [0, 3.125, 1.875], material: wood}
  # a lantern on each front end post
  - {name: LampRoof, slot: Accessory, size: [1, 0.25, 1], at: [6.25, 4.75, -1.875], mirror: x, material: metal}
  - {name: LampBase, slot: Accessory, size: [0.75, 0.125, 0.75], at: [6.25, 3.8125, -1.875], mirror: x, material: metal}
  - {name: LampLight, slot: Glow, size: [0.5, 0.625, 0.5], at: [6.25, 4.3125, -1.875], mirror: x}
  # moss
  - {name: Moss, slot: Trim, size: [1.25, 0.25, 0.75], at: [-6.375, 0.625, 1.375], material: moss}
  - {name: Moss2, slot: Trim, size: [0.75, 0.25, 1], at: [5.875, 0.625, -1.25], material: moss}
  - {name: MossPost, slot: Trim, size: [0.75, 0.25, 0.75], at: [2.25, 1.5, 1.875], material: moss}
```

## Renders

On the Starhollow sheet: ![[starhollow_props_v1.jpg]]

## Reviews

- 2026-10-21, forest props worker. First block-cell build for the Starhollow Forest ([[Decisions]] B48, the forest TikTok ZPLYSA3uR rebuilt in our own models). Status build: waiting for Ethan's look at the Starhollow sheet and vignette.
