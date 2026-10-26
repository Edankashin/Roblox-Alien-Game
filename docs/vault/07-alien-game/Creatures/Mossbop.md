---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Mossbop
name: Moop
world: 1
tier: Common
status: review
element: Bloom
height: 2.87
blocks: 12
tris: 250
bevel_width: 0.1
bevel_segments: 2
palette: ["#6CCB5F", "#2F7A4B", "#FFD45C", "#142019"]
roles: [body, second, accent, ink]
hero: LeafR
vfx: "none (Common): the sprout's two leaves unfurl and fold every 6 s and the spore bobs beside it, procedural moves of the sprout and float parts; no particles, no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Mossbop_sheet.svg]]"
render: "[[Mossbop_tq.jpg]]"
glb: ""
overlap: [0.996, 0.997, 0.997, 0.996]
cells_render: "[[Mossbop_tq_cells.jpg]]"
idle_render: "[[Mossbop_idle.png]]"
bar_world: Verdant
bar_kit: 1
bar_pieces: [sap_run]
bar_stance: "a clear slump: the whole ball rolled 14 degrees about its feet to its right, the tripod caught mid-step, one leaf standing straight up like an ear and the other drooping"
---
# Mossbop (Moop), Common, World 1 Verdant

A ball of moss built in voxel steps: a wide, soft-cornered middle (the head, with the face), a narrower cap step over it and a narrower base step under it, so from the front it reads as a round, not a cube. It stands on three dark root feet, two in front and one behind (a tripod: no pet animal stands like that), a two-leaf sprout grows out of its cap, and an amber spore of pollen the sprout has let go of floats beside it. Since the character bar pilot (2026-10-26) the whole ball leans (the cap slumps a quarter stud to its right, the base an eighth to its left), the tripod is caught mid-step and amber sap runs down its right side. Concept row in `src/shared/data/Species.luau`: "moss ball, eyes". Element and effect: [[Roster-Redesign]] section 2 (Bloom; the sprout unfurls every 6 s). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** It is the first thing they catch, so it has to be the cutest thing on the meadow: a round moss ball half of which is face, a sprout that moves and a spore that bobs beside it. It stays plain on purpose: two greens, one amber accent, no glow and no light, so everything above it in the ladder reads as more.

**Hero block.** The `LeafR` and `LeafL` pair on its dark `Stem`, amber against the moss green: the right leaf reaches up 25 degrees, the left one droops 15; together they are the sprout part the game turns to unfurl them.

**Alien anatomy.** The tripod, and the floating `Spore` (a `float` part the game bobs), so it is a plant that walks rather than a cube with a face.

**World motif (Verdant).** The moss cell as the body itself: the cap and base are quarter-stud steps on the half-stud grid that round the ball off. Loop 1's dark side plates are gone (they read as headphones).

## The character bar (B54, pilot 2026-10-26; second pass, bolder)

[[Blocky-Style]] section 10 and "Pilot bar notes (v2)"; the plan is `tools/blocky/pilots.py` (`moop()`), the kit `tools/blocky/kits.py`. A Common stays inside its 12 blocks and 2 to 3 flat colours; the first pass shifted its steps a quarter stud and nothing read, so v2 changes the outline instead:

- **Stance (rest pose `lean`).** The whole ball (head, cap, base, stem, leaves, sap) is rolled 14 degrees about its feet (`rig.rest.lean`, [[Blocky-Style]] section 8 "Rest-pose groups"): a clear slump to its right, the tripod caught mid-step under it. The authored boxes stay axis-aligned; the face plate leans with the head.
- **One ear up.** One amber leaf stands almost straight up (65 degrees from flat, most of a stud above the cap, the hero), the other droops; the lean takes them to about 79 and 39 degrees.
- **Kit (one piece).** `sap_run`, amber sap half a stud long (a neck and a fat drop, two blocks, no glow) down the head's right side, leaning with it.
- **No satellites, backdrop or aura**: they start at Rare, Legendary and Cosmic.
- Blocks 10 to 12 (v1 12), triangles 214 to 250 (Blender), moving things 3, height 2.87 (v1 2.48: the standing leaf), 2 to 3.5 held.

## Parts

```yaml
parts:
  # a moss ball in voxel steps, standing in the `lean` rest pose (PILOT-2: the whole ball rolled 14 degrees about its feet, a clear slump to its
  # right, instead of a quarter stud of shear): the head is its wide middle, the cap step over it and the base step under it
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.125, 0], bevel: true, material: moss, pose: lean}
  - {name: Cap, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 1.875, 0], material: moss, pose: lean}
  - {name: Base, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 0.375, 0], material: moss, pose: lean}
  # the tripod, caught mid-step: the right root foot forward and out, the left one back and under, the hind foot behind
  - {name: FootR, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [0.625, 0.125, -0.5], material: wood}
  - {name: FootL, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [-0.5, 0.125, -0.125], material: wood}
  - {name: HindFoot, slot: BodyDark, size: [0.5, 0.25, 0.5], at: [-0.125, 0.125, 0.375], material: wood}
  # alien anatomy: a spore the sprout has let go of, floating beside it (its own moving part), a mote of pollen in the amber accent
  - {name: Spore, slot: Accessory, size: [0.25, 0.25, 0.25], at: [1.375, 2.5, -0.75], shape: ico1, moves: float, pivot: [1.375, 2.5, -0.75]}
  # the sprout grows off the cap: one leaf stands straight up (an ear up, the hero), the other droops (two amber leaves)
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 2.125, 0], material: wood, pose: lean}
  - {name: LeafR, slot: Accessory, size: [0.625, 0.125, 0.5], at: [0.4375, 2.125, 0], rot: [0, 0, -25], moves: sprout, pivot: [0, 2.25, 0], pose: lean}
  - {name: LeafL, slot: Accessory, size: [0.625, 0.125, 0.5], at: [-0.25, 2.5625, 0], rot: [0, 0, -65], moves: sprout, pivot: [0, 2.25, 0], pose: lean}
  # pilot bar: begin (tools/blocky/pilots.py writes this region: the Verdant kit's one piece, a sap drop)
  # the Verdant kit's one piece (a Common wears one): amber sap, half a stud long, running down the head's right side from under the cap
  - {name: Sapa, slot: Accessory, size: [0.125, 0.125, 0.25], at: [1.0625, 1.6875, -0.25], pose: lean, material: metal}
  - {name: Sapb, slot: Accessory, size: [0.125, 0.375, 0.25], at: [1.0625, 1.4375, -0.25], pose: lean, material: metal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows (the moss fringe on the top two); the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `bean`, a Common design, a tall soft ink bean with one square shine, at 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, three frames: open, half, closed). A small smile and blush cheeks: the plainest face on the meadow, and still the cutest.

```yaml
eyes:
  key: bean
  mouth: smile
  cheeks: blush
  plate: [1.75, 1]
  at: [0.125, 1.0625]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the sprout sways, the spore bobs and circles, the whole ball breathes, and the face blinks. Two moving objects and the blink (a Common needs two); no flourish (that starts at Rare).

```yaml
rig:
  rest:
    lean: {rot: [0, 0, -14], pivot: [0, 0.25, 0]}
  clips:
    sprout: [{kind: sway, amp: 10, period: 3.2, axis: z}]
    float: [{kind: bob, amp: 0.12, period: 2.4}, {kind: orbit, amp: 0.06, period: 4.8}]
    root: [{kind: squash, amp: 0.04, period: 2.6}]
    face: [{kind: blink, period: 4.2}]
```

## Build

`python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Mossbop.md --out <scratch>` draws the sheet and the view masks; `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Mossbop.md --out <scratch>` builds the GLB into that scratch folder (never `assets/models`; `glb` stays empty until Ethan approves the sheet) and renders the views (commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Mossbop_tq.jpg]]

The concept sheet, drawn from the parts table above: [[Mossbop_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Mossbop_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Mossbop_views.png]]

The idle: eight frames of the clips, and the face plate's frames:

![[Mossbop_idle.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (54 islands). Materials: moss on the head, cap and base (the moss cell of Verdant as a texture at last), wood on the stem and the three root feet.

![[Mossbop_tq_cells.jpg]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: the first house eye read as a white eyeball with a pupil, and the leaves lay flat on the head, so the sprout did not read. Round 2: the house eye v2 (shine bar, lit crescent, sparkle) and a stemmed sprout at 25 degrees; the belly dropped to half a stud so the sprout fits under 2.5 studs. Round 3: no change after the side-by-side. Overlap with the sheet 0.998 to 0.999, 312 triangles. Wanted for: the cutest thing on the meadow, a face that is all eyes and a sprout that moves. Still cheap: the belly is a plain dark box, and the side moss cells read as headphones. Next: try the cell as a moss tuft on the belly, and an idle squash of the head. Status review, waiting for Ethan's look at the board.
- 2026-10-17, loop 2 worker, three rounds. Round 1: the dark belly box became a body-green base step and a narrower cap step went on top, so the head is the wide middle of a voxel round. Round 2: five tries at a moss motif in the one free block (a dark cap, a lime cap, a cap with a drip, a moss bib, a side patch): each read as a lid, a cake, a hat or a sticker, never as moss, so the block went to alien anatomy, a lime spore floating beside the sprout. Round 3: the spore moved off the leaf tip (it merged with it) to float over the front corner. Overlap 0.993 to 0.996, 224 triangles, 10 blocks, 2.48 studs. Wanted for: the cutest thing on the meadow, a round moss ball half of which is face, a sprout that moves and a spore that bobs. Still cheap: the moss reads as a soft green ball more than as moss (open in [[Blocky-Style]]: mottling in the texture), and it is still the boxiest shape in the row. Status review, artboard on the canvas.
- 2026-10-17, block-cell worker, three rounds (cells). Round 1: with moss across the whole head the front read as camouflage round the eyes, so below a two-row fringe the face is plain skin cells. Round 2: half-step tufts still read as a soft green ball; full-step tufts in three-cell clumps with a lit, ragged fringe down the sides read as moss (the open item of loop 2). Round 3: with the grout the ball reads as built of little blocks. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, eyes and rigs worker, the B46 pilot, two rounds. Round 1: the house eye retired for the library's `bean` (7 x 9 pixels at 16 a stud, one square shine) on a 28 x 16 face plate with a small smile and blush cheeks; the head's front is now plain cells (the moss fringe on top). Round 2: the first beans were 6 pixels wide, 19 percent of the head, and read small; at 7 they are 22 percent. Its rig: the sprout sways, the spore bobs and circles, the ball breathes (a 4 percent squash), the face blinks every 4.2 s: three moving things, no flourish. Height 2.48 (in the B45 band), overlap 0.993 to 0.996, 214 triangles. Wanted for: the plainest face on the meadow and still the cutest. Status review.
- 2026-10-26, character bar pilot worker, two rounds. Round 1: the cap and base shifted a quarter stud and an eighth, the tripod split into a stride, the sprout asymmetric (right leaf up, left drooping), the accent moved from lime to amber so the Verdant metal reads on a Common, and one sap piece hung under the head (it read as a stray block under the chin). Round 2: the sap moved to the head's right side as `sap_run` and the head and its face plate shifted an eighth right so the lean is real. Overlap 0.996 to 0.997, 12 blocks, 234 triangles. Wanted for: the same cutest-thing-on-the-meadow face, now leaning and stepping, the first rung of the bar. Still plain: from 16 studs the lean is a small change of silhouette (the sheet `media/studio/2026-10-26/pilot_bar_v1.jpg`); a Common has no room for more under 12 blocks.
- 2026-10-26, PILOT-2 (the second pass, bolder), one round after the coordinator's verdict that v1 was too timid (nothing new read at 16 studs): the caps lifted (Epic 4,000, Legendary and up 6,000), rest-pose groups so a head, a leg, a tail or a whole body can turn without a mass leaving its axis, and every addition made big (a body-sized backdrop, satellites of 0.5 to 0.9 stud, metal a quarter stud thick, a stance that changes the outline). See "The character bar" above; sheet `media/studio/2026-10-26/pilot_bar_v2.jpg`.
