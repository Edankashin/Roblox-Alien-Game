---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Mossbop
name: Moop
world: 1
tier: Common
status: review
element: Bloom
height: 2.48
blocks: 10
tris: 212
bevel_width: 0.1
bevel_segments: 2
palette: ["#6CCB5F", "#2F7A4B", "#D9F36B", "#142019"]
roles: [body, second, accent, ink]
hero: Leaf
vfx: "none (Common): the sprout's two leaves unfurl and fold every 6 s and the spore bobs beside it, procedural moves of the sprout and float parts; no particles, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Mossbop_sheet.svg]]"
render: "[[Mossbop_tq.jpg]]"
glb: ""
overlap: [0.996, 0.995, 0.993, 0.996]
cells_render: "[[Mossbop_tq_cells.jpg]]"
---
# Mossbop (Moop), Common, World 1 Verdant

A ball of moss built in voxel steps: a wide, soft-cornered middle (the head, with the face), a narrower cap step over it and a narrower base step under it, so from the front it reads as a round, not a cube. It stands on three dark root feet, two in front and one behind (a tripod: no pet animal stands like that), a two-leaf sprout grows out of its cap, and a lime spore the sprout has let go of floats beside it. Concept row in `src/shared/data/Species.luau`: "moss ball, eyes". Element and effect: [[Roster-Redesign]] section 2 (Bloom; the sprout unfurls every 6 s). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is the first thing they catch, so it has to be the cutest thing on the meadow: a round moss ball half of which is face, a sprout that moves and a spore that bobs beside it. It stays plain on purpose: two greens, one lime accent, no glow and no light, so everything above it in the ladder reads as more.

**Hero block.** The `Leaf` pair on its dark `Stem`, lime against the moss green, tilted up 25 degrees; together they are the sprout part the game turns to unfurl them.

**Alien anatomy.** The tripod, and the floating `Spore` (a `float` part the game bobs), so it is a plant that walks rather than a cube with a face.

**World motif (Verdant).** The moss cell as the body itself: the cap and base are quarter-stud steps on the half-stud grid that round the ball off. Loop 1's dark side plates are gone (they read as headphones).

## Parts

```yaml
parts:
  # a moss ball in voxel steps: the head is its wide middle, a narrower cap step above and a narrower base step below round it off
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.125, 0], bevel: true, material: moss}
  - {name: Cap, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 1.875, 0], material: moss}
  - {name: Base, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 0.375, 0], material: moss}
  # the tripod: two root feet in front, one behind
  - {name: Foot, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0.5, 0.125, -0.25], mirror: x, material: wood}
  - {name: HindFoot, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0, 0.125, 0.375], material: wood}
  # alien anatomy: a spore the sprout has let go of, floating beside it (its own moving part)
  - {name: Spore, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.75, 2.25, -0.875], shape: ico1, moves: float, pivot: [0.75, 2.25, -0.875]}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 2.125, 0], material: wood}
  - {name: Leaf, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.375, 2.3125, 0], rot: [0, 0, 25], mirror: x, moves: sprout, pivot: [0, 2.25, 0]}
```

## Face

The house face ([[Blocky-Style]] rule 3) on the head's front, 16 cells across the 2-stud head, so one cell is 0.125 studs and the 1.25-stud front is 10 rows.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF8FA3"
  rows:
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
```

## Build

`python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Mossbop.md --out <scratch>` draws the sheet and the view masks; `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Mossbop.md --out <scratch>` builds the GLB into that scratch folder (never `assets/models`; `glb` stays empty until Ethan approves the sheet) and renders the views (commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Mossbop_tq.jpg]]

The concept sheet, drawn from the parts table above: [[Mossbop_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Mossbop_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Mossbop_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (54 islands). Materials: moss on the head, cap and base (the moss cell of Verdant as a texture at last), wood on the stem and the three root feet.

![[Mossbop_tq_cells.jpg]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: the first house eye read as a white eyeball with a pupil, and the leaves lay flat on the head, so the sprout did not read. Round 2: the house eye v2 (shine bar, lit crescent, sparkle) and a stemmed sprout at 25 degrees; the belly dropped to half a stud so the sprout fits under 2.5 studs. Round 3: no change after the side-by-side. Overlap with the sheet 0.998 to 0.999, 312 triangles. Wanted for: the cutest thing on the meadow, a face that is all eyes and a sprout that moves. Still cheap: the belly is a plain dark box, and the side moss cells read as headphones. Next: try the cell as a moss tuft on the belly, and an idle squash of the head. Status review, waiting for Ethan's look at the board.
- 2026-10-17, loop 2 worker, three rounds. Round 1: the dark belly box became a body-green base step and a narrower cap step went on top, so the head is the wide middle of a voxel round. Round 2: five tries at a moss motif in the one free block (a dark cap, a lime cap, a cap with a drip, a moss bib, a side patch): each read as a lid, a cake, a hat or a sticker, never as moss, so the block went to alien anatomy, a lime spore floating beside the sprout. Round 3: the spore moved off the leaf tip (it merged with it) to float over the front corner. Overlap 0.993 to 0.996, 224 triangles, 10 blocks, 2.48 studs. Wanted for: the cutest thing on the meadow, a round moss ball half of which is face, a sprout that moves and a spore that bobs. Still cheap: the moss reads as a soft green ball more than as moss (open in [[Blocky-Style]]: mottling in the texture), and it is still the boxiest shape in the row. Status review, artboard on the canvas.
- 2026-10-17, block-cell worker, three rounds (cells). Round 1: with moss across the whole head the front read as camouflage round the eyes, so below a two-row fringe the face is plain skin cells. Round 2: half-step tufts still read as a soft green ball; full-step tufts in three-cell clumps with a lit, ragged fringe down the sides read as moss (the open item of loop 2). Round 3: with the grout the ball reads as built of little blocks. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
