---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Snowbun
name: Flurra
world: 2
tier: Common
status: review
element: Snowdust
height: 2.47
blocks: 11
tris: 226
bevel_width: 0.1
bevel_segments: 2
palette: ["#B4A9E6", "#CFE2F3", "#F0407F", "#2A2340"]
roles: [body, second, accent, ink]
hero: Ball
vfx: "Common, one layer (Effects.luau): a Burst of six pixel snowflakes (DDEBF7) puffs off the Tail every 9 s; the idle hops, a bob of 0.14 studs every 1 s; no light; the ears sway and twitch, the nose twitches and the snowball tail swells in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Snowbun_sheet.svg]]"
render: "[[Snowbun_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.995, 0.995, 0.997]
cells_render: "[[Snowbun_tq_cells.jpg]]"
idle_render: "[[Snowbun_idle.png]]"
---
# Snowbun (Flurra), Common, World 2 Frostbyte

A lavender snow bunny with a snowball for a tail that is bigger than the bunny: a soft lavender head that is most of the animal, two long ears with deep pink insides, one up and one flopped out to its left (lop-eared), two paws of tinted snow, and behind it a stepped snowball of the same snow (a base step, the ball, a cap) that rolls along on the ground and never stops growing. Concept row in `src/shared/data/Species.luau`: "snow bunny, snowball tail that keeps growing". Element and effect: [[Roster-Redesign]] section 2 (the tail grows in three steps, then pops back with a puff of snow dust). The style rules it is checked against: [[Blocky-Style]].

**What makes a player want it.** The first thing on the snow that is not white: a lavender bunny whose tail is a snowball it cannot stop rolling, so it tows its own weight everywhere it hops. It stays plain on purpose (one lavender, white, one pink, no glow, no light) so every rung above it reads as more.

**Hero block.** The `Ball`, a stepped snowball of pure white snow behind the bunny, as tall as its head: unique in Frostbyte (Mitt is a snowball; Flurra drags one).

**Alien anatomy.** The snowball is part of it: a tail that is a growing drift it tows along the ground; it has no hind legs, only two front paws of snow, and its ears are rooted into the top corners of its head, one standing and one that never learned to.

**World motif (Frostbyte).** The ice facet as steps: the snowball is a stepped round (base, ball, cap); the snow lip of the world's ground runs over the snowball's sides and the paws (the `snow` cells).

## Parts

```yaml
parts:
  # two paws of snow in front (no hind legs: the snowball is behind)
  - {name: Paw, slot: BodyDark, size: [0.75, 0.375, 0.75], at: [0.625, 0.1875, -0.25], mirror: x, material: snow}
  # the head is the bunny: a soft lavender block, bevelled
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, 0], bevel: true}
  # long ears, pink inside, one up and one flopped out to its left (lop-eared), each one moving part
  - {name: EarUp, slot: Body, size: [0.5, 1.25, 0.25], at: [0.6875, 1.8125, -0.125], rot: [0, 0, -10], moves: ear, pivot: [0.5, 1.5, -0.125]}
  - {name: InnerUp, slot: Accessory, size: [0.25, 0.875, 0.125], at: [0.75, 1.875, -0.3125], rot: [0, 0, -10], moves: ear, pivot: [0.5, 1.5, -0.125]}
  - {name: EarDown, slot: Body, size: [0.5, 1.25, 0.25], at: [-1.1875, 1.375, -0.125], rot: [0, 0, 110], moves: ear, pivot: [-0.5, 1.5, -0.125]}
  - {name: InnerDown, slot: Accessory, size: [0.25, 0.875, 0.125], at: [-1.25, 1.375, -0.3125], rot: [0, 0, 110], moves: ear, pivot: [-0.5, 1.5, -0.125]}
  # the hero: the snowball tail, a stepped round of snow that rolls on the ground behind the bunny
  - {name: BallBase, slot: BodyDark, size: [1, 0.25, 1], at: [0, 0.125, 1.5], material: snow, moves: tail, pivot: [0, 0, 1.5]}
  - {name: Ball, slot: BodyDark, size: [1.5, 1.5, 1.5], at: [0, 1, 1.5], material: snow, moves: tail, pivot: [0, 0, 1.5]}
  - {name: BallCap, slot: BodyDark, size: [1, 0.25, 1], at: [0, 1.875, 1.5], material: snow, moves: tail, pivot: [0, 0, 1.5]}
  # B46 detail: a pink button nose proud of the face between the eyes, that twitches
  - {name: Nose, slot: Accessory, size: [0.25, 0.125, 0.125], at: [0, 1.0625, -0.8125], moves: nose, pivot: [0, 1.0625, -0.75]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell); the eyes, the mouth and the cheeks are on the face plate, and the pink `Nose` block sits proud of it between the eyes.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `dot`, a Common design, round ink dots with one shine, a bunny's bright round eyes, at 16 pixels a stud on a 1.75 x 0.625 stud plate (28 x 10 pixels, three frames). A small smile under the twitching nose, and blush cheeks. The only `dot` in Frostbyte.

```yaml
eyes:
  key: dot
  mouth: smile
  cheeks: blush
  plate: [1.75, 0.625]
  at: [0, 1]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): both ears sway (the flopped one mirrored) and the standing one twitches in bursts, the nose twitches, the snowball tail swells and settles (the growing drift; Effects.luau pops it with snow dust every 9 s), the bunny squashes on each hop and the face blinks. Five moving things (four objects, the Common cap, and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    ear: [{kind: sway, amp: 10, period: 2.6, axis: z}]
    earR: [{kind: wag, amp: 15, period: 4, axis: x}]
    nose: [{kind: bob, amp: 0.03, period: 0.5}]
    tail: [{kind: pulse, amp: 0.08, period: 4.5}]
    root: [{kind: squash, amp: 0.05, period: 1}]
    face: [{kind: blink, period: 3.6}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Snowbun.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Snowbun.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Snowbun_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Snowbun_idle.png]]

The concept sheet, drawn from the parts table above: [[Snowbun_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 19 cells tall. Materials: `snow` on the snowball and the paws (a white top with drifts and a sparkle, the lip over white strata on the sides, so the ball reads as rolled snow), plain skin on the lavender head and ears.

## Reviews

- 2026-10-20, World 2 roster worker, three rounds. Round 1: a white snowball and white paws on a lavender bunny vanished against the backdrop (Mitt's scarf lesson), so the snow is a shadowed blue-white in the second slot and the lavender deepened to keep the greyscale gaps. Round 2: the ears leaning out 25 degrees filled the box's top corners and the pair with Mitt rose to 0.75, so one ear stands at 10 degrees and the other flops out to its left (worst pair now 0.68, with Floe). Overlap 0.997 to 0.998, 208 triangles, 10 blocks, 2.47 studs, two moving objects (the ears). Wanted for: a bunny towing a snowball bigger than itself. Still cheap: the ball sits behind the head and only the three-quarter and side views show it. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), one round. The house face became the library's `dot` (round ink dots with a shine) on a 28 x 10 plate with a small smile and blush; the drawn nose became a pink `Nose` block proud of the plate that twitches. Rig: both ears sway (the flop mirrored) and the standing one twitches in bursts, the snowball became the `tail` object that swells and settles (the drift that Effects.luau pops every 9 s), it squashes on each hop and blinks. Five moving things (four objects, the Common cap, and the blink). Height 2.47 (in band, unchanged), 11 blocks, 226 triangles, overlap 0.995 to 0.997. Wanted for: the first colour on the snow, a lop-eared lavender bunny with a twitching pink nose towing a snowball bigger than itself. Still weak: the dot eyes are the smallest the library allows (19 percent of the head), and the snowball is plain snow with no mark of its rolling. Status review.
