---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Frostfang
name: Sabrek
world: 2
tier: Epic
status: review
element: Frost
height: 3.72
blocks: 49
tris: 714
bevel_width: 0.125
bevel_segments: 2
palette: ["#4F9BD8", "#22406B", "#F2F7FB", "#C7DCEE", "#2ED3F7", "#12192B"]
roles: [body, second, accent, trim, glow, ink]
hero: Fang
vfx: "kept on the body (Epic): the two icicle fangs and the tail tip glow ice-blue; frost breath wisps from the mouth every 3 s and a sneeze every 12 s throws a burst of snowflakes two studs (Effects.luau, the Wisp emitter at Mouth and the Flake emitter at Top); a blue light on the body; the ears and the tail move"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Frostfang_sheet.svg]]"
render: "[[Frostfang_tq_cells.jpg]]"
glb: ""
overlap: [0.999, 0.995, 0.999, 0.999]
vfx_render: "[[Frostfang_vfx_cells.jpg]]"
cells_render: "[[Frostfang_tq_cells.jpg]]"
---
# Frostfang (Sabrek), Epic, World 2 Frostbyte

A sabre-tooth cub in ice blue on big cream paws, each paw in a frosted silver ankle band, with two icicle fangs hanging from its cheeks that glow from inside and a ruff of seven dark ice quills standing round its neck. Three dark stripes cross its back, a frost flake in silver is stamped on each flank, a cream belly runs under it, and its tail ends in a block of lit ice. The muzzle is cream, drawn into the house face under a dark cat's nose. Concept row in `src/shared/data/Species.luau`: "sabre-tooth cub, icicle fangs, quill ruff, sneezes snowflakes". Element: Frost (`Effects.luau`); [[Roster-Redesign]] section 2 gives the frost breath, the sneeze and the blue light. Rules: [[Blocky-Style]].

**What makes a player want it.** It only rolls in a Blizzard, and it is the first creature on Frostbyte with a crown: the ruff of quills and the two lit fangs read as "charged with cold" from across the snowfield, while the face under them stays the soft house face. The banded body (stripes, bands, belly), the stamped flake and the three glow extremities are the Epic rung's detail; the glow stays on the body, as the ladder says an Epic's effects do.

**Hero block.** The `Fang` pair: two icicles hanging from the cheeks past the chin, lit from inside, with stepped points. Unique in Frostbyte.

**Alien anatomy.** Fangs that are icicles growing from the cheeks outside the mouth and regrowing after each sneeze; a ruff of ice quills instead of fur; a tail that ends in a block of light. Three moving objects: the two ears and the tail.

**World motif (Frostbyte).** Icicles (the fangs, the quills as stepped points) and the six-point frost flake stamped on the flanks in quarter-stud cells.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.75, 1.75], at: [0, 2.375, -1.25], bevel: true}
  - {name: Torso, slot: Body, size: [1.75, 1.5, 2.75], at: [0, 1.5, 0.375], bevel: true}
  - {name: Belly, slot: Accessory, size: [2, 0.5, 2.25], at: [0, 0.875, 0.375]}
  # four legs on big cream paws, a frosted band on each ankle
  - {name: Paw, slot: Accessory, size: [0.75, 0.375, 0.875], at: [0.75, 0.1875, -0.8125], mirror: x}
  - {name: Leg, slot: Body, size: [0.625, 0.5, 0.625], at: [0.6875, 0.625, -0.6875], mirror: x}
  - {name: Band, slot: Trim, size: [0.875, 0.125, 0.875], at: [0.6875, 0.4375, -0.6875], mirror: x, material: metal}
  - {name: HindPaw, slot: Accessory, size: [0.75, 0.375, 0.875], at: [0.75, 0.1875, 1.4375], mirror: x}
  - {name: HindLeg, slot: Body, size: [0.625, 0.5, 0.625], at: [0.6875, 0.625, 1.3125], mirror: x}
  - {name: HindBand, slot: Trim, size: [0.875, 0.125, 0.875], at: [0.6875, 0.4375, 1.3125], mirror: x, material: metal}
  # the hero: icicle fangs hanging from the cheeks past the chin, lit from inside, stepped points
  - {name: Fang, slot: Glow, size: [0.25, 0.75, 0.25], at: [0.5, 1.375, -2.125], mirror: x, material: ice}
  - {name: FangTip, slot: Glow, size: [0.25, 0.375, 0.25], at: [0.5, 0.8125, -2.125], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  # ears with cream insides, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.5, 0.25], at: [0.75, 3.375, -1.375], rot: [0, 0, -15], mirror: x, moves: ear, pivot: [0.75, 3.25, -1.375]}
  - {name: InnerEar, slot: Accessory, size: [0.25, 0.25, 0.125], at: [0.75, 3.375, -1.5625], rot: [0, 0, -15], mirror: x, moves: ear, pivot: [0.75, 3.25, -1.375]}
  # the ruff: seven dark ice quills standing round the neck, leaning back and out
  - {name: RuffTop, slot: BodyDark, size: [0.5, 0.875, 0.5], at: [0, 3.3125, -0.4375], rot: [20, 0, 0], shape: cone6, material: ice}
  - {name: RuffUpper, slot: BodyDark, size: [0.5, 0.875, 0.5], at: [0.8125, 3.125, -0.4375], rot: [15, 0, -20], shape: cone6, mirror: x, material: ice}
  - {name: RuffSide, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [1.1875, 2.5, -0.4375], rot: [0, 0, -25], shape: cone6, mirror: x, material: ice}
  - {name: RuffLow, slot: BodyDark, size: [0.5, 0.75, 0.5], at: [1.125, 1.875, -0.375], rot: [0, 0, -70], shape: cone6, mirror: x, material: ice}
  # three dark stripes across the back
  - {name: Stripe, slot: BodyDark, size: [2, 0.125, 0.25], at: [0, 2.3125, 0.25]}
  - {name: Stripe2, slot: BodyDark, size: [2, 0.125, 0.25], at: [0, 2.3125, 0.875]}
  - {name: Stripe3, slot: BodyDark, size: [2, 0.125, 0.25], at: [0, 2.3125, 1.5]}
  # the stamped element glyph: a six-point frost flake in frosted silver on each flank (a plus of quarter-stud cells and four corner cells)
  - {name: Flake, slot: Trim, size: [0.125, 0.75, 0.25], at: [0.9375, 1.5, 0.875], mirror: x, material: metal}
  - {name: Flake2, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.9375, 1.5, 0.5], mirror: x, material: metal}
  - {name: Flake3, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.9375, 1.5, 1.25], mirror: x, material: metal}
  - {name: Flake4, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.9375, 1.875, 0.375], mirror: x, material: metal}
  - {name: Flake5, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.9375, 1.875, 1.375], mirror: x, material: metal}
  - {name: Flake6, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.9375, 1.125, 0.375], mirror: x, material: metal}
  - {name: Flake7, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.9375, 1.125, 1.375], mirror: x, material: metal}
  # the tail, ending in a block of lit ice, one moving part
  - {name: Tail, slot: Body, size: [0.5, 0.5, 1.25], at: [0, 2, 2.375], moves: tail, pivot: [0, 2, 1.75]}
  - {name: TailTip, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 2, 3.25], moves: tail, pivot: [0, 2, 1.75], material: ice}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 14 rows for the 1.75-stud front. A cream muzzle (`c`, the accent) under a two-cell dark nose; the eye's lit crescent is the fangs' ice glow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF8FA3"
    "c": accent
  rows:
    - "................"
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk.kk.kwgk.."
    - "...gg.kcck.gg..."
    - "..pp.cckkcc.pp.."
    - ".....cccccc....."
    - "......cccc......"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Frostfang.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Frostfang.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Frostfang_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Frostfang_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Frostfang_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 30 cells tall. Materials: `fur` would have been the coat, but a 2-stud cub is 14 cells tall on the head and the tufts crowded the face, so the coat stays skin cells; `ice` on the fangs, the quills and the tail tip (the glow parts carry the ice bands lit), `metal` on the bands and the flake.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: a flake with its corner cells on the stripe drops put the glyph under the stripes, so the stripes are three slabs on the back only and the flank is the flake's. Round 2: the ruff's lowest pair point sideways (70 degrees) so the ruff reads as a collar from the front and not as a second pair of ears; the pale cyan crescent under the eye read as a tear on the blue (rule 3's don't), so the glow went to a saturated cyan, which reads as lit. Overlap 0.995 to 0.999, 714 triangles, 49 blocks, 3.72 studs, three moving objects (the ears and the tail); three glow extremities (the fangs and the tail tip). Wanted for: the Blizzard's own cat, two lit icicle fangs and a crown of quills. Still cheap: the coat is plain skin cells (the fur tufts crowded a 2-stud head); the flake is thin from the three-quarter view. Status review.
