---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Reindazzle
name: Blinkar
world: 2
tier: Rare
status: review
element: Frost
height: 3.19
blocks: 27
tris: 470
bevel_width: 0.1
bevel_segments: 2
palette: ["#A8805A", "#4A3222", "#F2E9DC", "#A8E4FF", "#FF6B6B", "#1E1510"]
roles: [body, second, accent, trim, glow, ink]
hero: Beam
vfx: "a soft light (Rare): the nose glows and blinks red every 2 s (Effects.luau, the red Light at Mouth, pulse 1.6 s) and frost sparkles drift off the antlers at 4 a second; the icicles glint every 4 s; the ears and the bell tail move"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Reindazzle_sheet.svg]]"
render: "[[Reindazzle_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.996, 0.995, 0.995]
vfx_render: "[[Reindazzle_vfx_cells.jpg]]"
cells_render: "[[Reindazzle_tq_cells.jpg]]"
---
# Reindazzle (Blinkar), Rare, World 2 Frostbyte

A tan reindeer with a square head and a cream muzzle drawn into the house face, a nose that is a red lantern, dark legs, and antlers that are beams of ice: a dark post out of each side of the skull, an ice beam rising out from it, and three icicles hanging from each beam, longest at the root. A frost glyph in ice is stamped on each flank, and its tail ends in an ice bell. Concept row in `src/shared/data/Species.luau`: "reindeer, icicle antlers, nose blinks". Element: Frost (`Effects.luau`); [[Roster-Redesign]] section 2 gives the nose blink, the antler glint and the soft light. Rules: [[Blocky-Style]].

**What makes a player want it.** The first light on the snow: a red nose that blinks in the dark, under antlers that catch the light. The Rare rung exactly: a stamped element glyph (the ice sparkle on the flank), one glossy trim slot (the ice: beams, icicles, glyph and bell) and a soft light, at 3.2 studs to Pengoo's 2.6.

**Hero block.** The `Beam` pair: antlers of ice with icicles hanging from them, a wide T from the front, unique in Frostbyte.

**Alien anatomy.** Antlers that are not bone but ice growing from the skull, hung with icicles that regrow; a nose that is a lantern; a bell for a tail (the `tail` part the game swings).

**World motif (Frostbyte).** Icicles, the ice facet hanging: stepped points under every beam; the frost sparkle glyph on the flanks in eighth-stud cells.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -1], bevel: true}
  - {name: Torso, slot: Body, size: [1.5, 1, 2.25], at: [0, 1.125, 0.375], bevel: true}
  # dark deer legs
  - {name: FrontLeg, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [0.5, 0.3125, -0.5], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [0.5, 0.3125, 1], mirror: x}
  # the lantern nose, on the muzzle between the eyes and the smile
  - {name: Nose, slot: Glow, size: [0.5, 0.375, 0.25], at: [0, 1.6875, -1.875]}
  # ears forward on the head, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.375, 0.25], at: [1.125, 2.125, -1.375], rot: [0, 0, -20], mirror: x, moves: ear, pivot: [1, 2, -1.375]}
  # the hero: antlers of ice: a dark post out of the skull, an ice beam rising out of it, three icicles hanging from the beam
  - {name: Post, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.625, 2.6875, -0.875], mirror: x}
  - {name: Beam, slot: Trim, size: [1.5, 0.25, 0.25], at: [1.3125, 2.875, -0.875], rot: [0, 0, 15], mirror: x, material: ice}
  - {name: Icicle, slot: Trim, size: [0.25, 0.75, 0.25], at: [1.125, 2.375, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  - {name: Icicle2, slot: Trim, size: [0.25, 0.5, 0.25], at: [1.625, 2.625, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  - {name: Icicle3, slot: Trim, size: [0.25, 0.375, 0.25], at: [2, 2.8125, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  # the tail with an ice bell at its end, one moving part
  - {name: Tail, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 1.5, 1.625], moves: tail, pivot: [0, 1.5, 1.5]}
  - {name: Bell, slot: Trim, size: [0.5, 0.5, 0.5], at: [0, 1.125, 1.75], moves: tail, pivot: [0, 1.5, 1.5], material: ice}
  # the stamped element glyph: a frost sparkle in ice on each flank (a plus of quarter-stud cells)
  - {name: Glyph, slot: Trim, size: [0.125, 0.75, 0.25], at: [0.8125, 1.125, 0.5], mirror: x, material: ice}
  - {name: Glyph2, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.8125, 1.125, 0.25], mirror: x, material: ice}
  - {name: Glyph3, slot: Trim, size: [0.125, 0.25, 0.25], at: [0.8125, 1.125, 0.75], mirror: x, material: ice}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front. A cream muzzle (`c`, the accent) is drawn round the mouth under the lantern nose; the eye's lit crescent is the nose's glow.

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
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.kcck.gg..."
    - "..pp.cckkcc.pp.."
    - "......cccc......"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Reindazzle.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Reindazzle.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Reindazzle_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Reindazzle_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Reindazzle_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 26 cells tall. Materials: `ice` on the beams, icicles, glyph and bell (light bands on the other diagonal, glossy), the nose glow cells, skin elsewhere.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: antlers that rose up ran over the Rare height cap at 3.25, so the beams go out, rising 15 degrees, and the icicles hang from under them: the height stays at 3.19 and the silhouette gets its wide T. A six-point flake glyph with four corner cells put the count at 35; the sparkle plus keeps it at 27. Round 2: the ears moved forward on the head so the antler posts have the back of the skull. Overlap 0.995 to 0.996, 470 triangles, 27 blocks, 3.19 studs, three moving objects (the ears and the bell tail). Wanted for: a lantern nose that blinks in the dark under antlers of ice. Still cheap: the glyph is three thin blocks and reads at distance as a mark, not a flake; the bell is small. Status review.
