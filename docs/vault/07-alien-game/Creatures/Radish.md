---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Radish
name: Raddis
world: 1
tier: Cosmic
status: review
element: Sun
height: 13.75
blocks: 102
tris: 1424
bevel_width: 0.1875
bevel_segments: 2
palette: ["#D7265C", "#FFF0D9", "#2CC5B2", "#FFB21E", "#FFE36B", "#2A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#FFE36B", "#FF9F45", "#FFF8DC"]
hero: RingT
vfx: "to the sky: the rays, the orb, the forehead gem and the wing tips glow and step through gold, amber and white every 2 s; the halo turns once in 8 s; gold motes orbit at 1.5 studs; a ground ring of light; a sunlight trail while it hovers; the flourish is a flare and a column of light from the orb"
ride: "Hover; the rider sits on the flat front half of the head top (5.5 by 3 studs, 10.5 studs up), in front of the leaves and under the orb"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Radish_sheet.svg]]"
render: "[[Radish_tq.jpg]]"
glb: ""
overlap: [0.996, 0.997, 0.997, 0.996]
vfx_render: "[[Radish_vfx.jpg]]"
---
# Radish (Raddis), Cosmic, World 1 Verdant

A giant radish that hovers: a deep radish-red head 5.5 studs square with the house face low on it, a bulb under it, a root that steps down from red to cream in four steps to a thin tail, and three tall turquoise leaf blades out of its crown. Behind it turns a stepped gold sun disk with six glowing rays and a pair of spread Egyptian wings, the winged sun of Ra; a glowing orb floats over its crown, a sun gem sits on its forehead, a broad collar of gold and turquoise hangs under its chin and the sides of its head carry the striped headdress. Concept row: "radiant radish, sun disk; echo of Ra". Element: Sun (`Effects.luau`; [[Roster-Redesign]] section 2 gives the corona, the turning disk, the orbiting motes, the ring, the trail and the flare). Rules: [[Blocky-Style]].

**What makes a player want it.** It is 13.75 studs tall and 16.5 studs across the wings, nearly three avatars high: it towers over the player, and it is a mount. The awe comes from the size, the turning sun and the light; the face stays the same soft house face as Moop's, which is the point (rare means worth finding, not fierce).

**Hero block.** The sun disk (`RingT` to `RingB` and the rays): one moving part, the `halo`, that the game turns once in 8 s, unique in Verdant.

**Moving parts (four objects).** `halo` (the ring and its rays, pivot on the disk's centre), `wingR` and `wingL` (pivots at the disk's sides, they flap), `float` (the orb, it bobs).

**World motif (Verdant).** The moss cell, here as the half-stud cells of the ring, the collar and the stepped leaves.

## Parts

```yaml
parts:
  # the radish: a head, a bulb, a cream root stepping down to a point
  - {name: Head, slot: Body, size: [5.5, 5.5, 4.75], at: [0, 7.75, 0], bevel: true}
  - {name: Bulb, slot: Body, size: [4.5, 2, 4], at: [0, 4, 0], bevel: true}
  - {name: Root, slot: Body, size: [3, 0.75, 3], at: [0, 2.625, 0]}
  - {name: Root2, slot: BodyDark, size: [1.75, 0.75, 1.75], at: [0, 1.875, 0]}
  - {name: RootTip, slot: BodyDark, size: [0.75, 0.75, 0.75], at: [0, 1.125, 0]}
  - {name: RootTail, slot: BodyDark, size: [0.25, 0.75, 0.25], at: [0, 0.375, 0]}
  - {name: RootHair, slot: BodyDark, size: [0.25, 0.75, 0.25], at: [1, 1.75, 0], rot: [0, 0, 20], mirror: x}
  # the forehead sun gem in its gold frame
  - {name: GemFrame, slot: Trim, size: [1.5, 1.25, 0.125], at: [0, 9.375, -2.4375]}
  - {name: Gem, slot: Glow, size: [1, 0.75, 0.125], at: [0, 9.375, -2.5625]}
  # the broad collar under the chin: three rows of gold and turquoise cells narrowing to a lit pendant
  - {name: CollarA, slot: Trim, size: [0.5, 0.5, 0.125], at: [0, 4.75, -2.0625]}
  - {name: CollarA1, slot: Accessory, size: [0.5, 0.5, 0.125], at: [0.5, 4.75, -2.0625], mirror: x}
  - {name: CollarA2, slot: Trim, size: [0.5, 0.5, 0.125], at: [1, 4.75, -2.0625], mirror: x}
  - {name: CollarA3, slot: Accessory, size: [0.5, 0.5, 0.125], at: [1.5, 4.75, -2.0625], mirror: x}
  - {name: CollarA4, slot: Trim, size: [0.5, 0.5, 0.125], at: [2, 4.75, -2.0625], mirror: x}
  - {name: CollarB, slot: Accessory, size: [0.5, 0.5, 0.125], at: [0, 4.25, -2.0625]}
  - {name: CollarB1, slot: Trim, size: [0.5, 0.5, 0.125], at: [0.5, 4.25, -2.0625], mirror: x}
  - {name: CollarB2, slot: Accessory, size: [0.5, 0.5, 0.125], at: [1, 4.25, -2.0625], mirror: x}
  - {name: CollarB3, slot: Trim, size: [0.5, 0.5, 0.125], at: [1.5, 4.25, -2.0625], mirror: x}
  - {name: CollarC, slot: Trim, size: [0.5, 0.5, 0.125], at: [0, 3.75, -2.0625]}
  - {name: CollarC1, slot: Accessory, size: [0.5, 0.5, 0.125], at: [0.5, 3.75, -2.0625], mirror: x}
  - {name: CollarC2, slot: Trim, size: [0.5, 0.5, 0.125], at: [1, 3.75, -2.0625], mirror: x}
  - {name: Pendant, slot: Glow, size: [0.5, 0.5, 0.125], at: [0, 3.25, -2.0625]}
  # the striped headdress down each side of the head
  - {name: Nemes, slot: Trim, size: [0.125, 0.5, 4], at: [2.8125, 9.75, 0], mirror: x}
  - {name: Nemes2, slot: Accessory, size: [0.125, 0.5, 4], at: [2.8125, 8.75, 0], mirror: x}
  - {name: Nemes3, slot: Trim, size: [0.125, 0.5, 4], at: [2.8125, 7.75, 0], mirror: x}
  - {name: Nemes4, slot: Accessory, size: [0.125, 0.5, 4], at: [2.8125, 6.75, 0], mirror: x}
  - {name: Nemes5, slot: Trim, size: [0.125, 0.5, 4], at: [2.8125, 5.75, 0], mirror: x}
  # radish greens: three tall blades out of the crown's back half, the outer pair leaning out, a short pair between
  - {name: Leaf, slot: Accessory, size: [0.75, 2.5, 0.25], at: [0, 11.75, 1.75]}
  - {name: Leaf2, slot: Accessory, size: [0.75, 2.25, 0.25], at: [1.625, 11.5625, 1.75], rot: [0, 0, -20], mirror: x}
  - {name: Leaf3, slot: Accessory, size: [0.5, 1.5, 0.25], at: [0.8125, 11.25, 2], rot: [0, 0, -12], mirror: x}
  # the floating accessory: a sun orb over the crown
  - {name: Orb, slot: Glow, size: [1, 1, 1], at: [0, 11.5, 1.25], shape: ico1, moves: float, pivot: [0, 11.5, 1.25]}
  # the sun disk: a stepped ring of half-stud cells behind the head, turning on its centre
  - {name: RingT, slot: Trim, size: [3, 0.5, 0.5], at: [0, 12, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingT1, slot: Trim, size: [5, 0.5, 0.5], at: [0, 11.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingT2, slot: Trim, size: [2, 0.5, 0.5], at: [2, 11, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingT3, slot: Trim, size: [1.5, 0.5, 0.5], at: [2.75, 10.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingT4, slot: Trim, size: [1.5, 0.5, 0.5], at: [3.25, 10, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingT5, slot: Trim, size: [1, 0.5, 0.5], at: [3.5, 9.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingSide, slot: Trim, size: [1, 3, 0.5], at: [4, 7.75, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingB5, slot: Trim, size: [1, 0.5, 0.5], at: [3.5, 6, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingB4, slot: Trim, size: [1.5, 0.5, 0.5], at: [3.25, 5.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingB3, slot: Trim, size: [1.5, 0.5, 0.5], at: [2.75, 5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingB2, slot: Trim, size: [2, 0.5, 0.5], at: [2, 4.5, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingB1, slot: Trim, size: [5, 0.5, 0.5], at: [0, 4, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RingB, slot: Trim, size: [3, 0.5, 0.5], at: [0, 3.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  # six rays, stepped and tapering, colour-cycled glow
  - {name: RayN, slot: Glow, size: [1.5, 0.5, 0.5], at: [0, 12.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayN2, slot: Glow, size: [1, 0.5, 0.5], at: [0, 13, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayN3, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 13.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayS, slot: Glow, size: [1.5, 0.5, 0.5], at: [0, 3, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayS2, slot: Glow, size: [1, 0.5, 0.5], at: [0, 2.5, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayS3, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 2, 2.875], moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayNE, slot: Glow, size: [0.75, 0.75, 0.5], at: [3.625, 11.375, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayNE2, slot: Glow, size: [0.5, 0.5, 0.5], at: [4.125, 11.875, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RayNE3, slot: Glow, size: [0.25, 0.25, 0.5], at: [4.375, 12.125, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RaySE, slot: Glow, size: [0.75, 0.75, 0.5], at: [3.625, 4.125, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RaySE2, slot: Glow, size: [0.5, 0.5, 0.5], at: [4.125, 3.625, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  - {name: RaySE3, slot: Glow, size: [0.25, 0.25, 0.5], at: [4.375, 3.375, 2.875], mirror: x, moves: halo, pivot: [0, 7.75, 2.875]}
  # the wings of the winged sun: four feather rows behind the disk, lit tips; each wing turns on its root to flap
  - {name: Wing, slot: Trim, size: [4, 0.5, 0.25], at: [6.25, 10.25, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: Wing2, slot: Accessory, size: [3.75, 0.75, 0.25], at: [6.125, 9.625, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: Wing3, slot: Body, size: [3.25, 0.75, 0.25], at: [5.875, 8.875, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: Wing4, slot: Accessory, size: [2.5, 0.75, 0.25], at: [5.5, 8.125, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: WingTip, slot: Glow, size: [0.25, 0.75, 0.25], at: [8.125, 9.625, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: WingTip2, slot: Glow, size: [0.25, 0.75, 0.25], at: [7.625, 8.875, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
  - {name: WingTip3, slot: Glow, size: [0.25, 0.75, 0.25], at: [6.875, 8.125, 3.375], mirror: x, moves: wing, pivot: [4.25, 9, 3.375]}
```

## Face

The house face, 16 cells across the 5.5-stud head (0.34375 studs a cell, so 16 rows for the square front). The eyes sit low (rows 7 to 11); rows 1 to 5 stay plain for the gem.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9DBB"
  rows:
    - "................"
    - "................"
    - "................"
    - "................"
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.k..k.gg..."
    - "..pp...kk...pp.."
    - "................"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Radish.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Radish.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Radish_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Radish_vfx.jpg]]

The concept sheet, drawn from the parts table above: [[Radish_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Radish_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Radish_views.png]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: it read as a red box with wings (a short root, leaves like little antlers, an opaque white light column). Round 2: a four-step root taper to a thin tail with root hairs, three tall leaf blades, the upper body raised half a stud (13.75 studs, head 40 percent). Round 3: the preview's turning disk lit, a corona light, a wider translucent column. Overlap 0.996 to 0.997, 1,424 triangles, four moving objects. Wanted for: 2.8 avatars tall and 16.5 studs across the wings, a turning winged sun, a mount. Still cheap: the head front is a big flat red plane above the face, the collar hides under the head's overhang from above, and the wing rows read as flags from the side. Next: a stepped brow band or headdress edge across the top of the face, feather tips stepped at the wing ends, and the face at 32 cells for close-ups. Status review.
