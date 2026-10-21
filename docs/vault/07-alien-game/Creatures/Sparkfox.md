---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Sparkfox
name: Vixa
world: 1
tier: Rare
status: review
element: Ember
height: 3
blocks: 41
tris: 650
bevel_width: 0.1
bevel_segments: 2
palette: ["#FF7A30", "#FFF1DD", "#4A2433", "#FFC940", "#FFA53D", "#24141A"]
roles: [body, second, accent, trim, glow, ink]
hero: Brush
vfx: "a soft light (Rare), three layers in Effects.luau: ember sparks rise off the brush tip at 6 a second, an amber light pulses at the tail, and every 4 s a gold sparkle where the paint drop falls from the brush and reforms. The flourish (every 8 s) is a painter's twirl: a hop and a full turn with the brush sweeping a stroke, the ears flared and the drop leaping"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Sparkfox_sheet.svg]]"
render: "[[Sparkfox_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.996, 0.997, 0.996]
vfx_render: "[[Sparkfox_vfx_cells.jpg]]"
cells_render: "[[Sparkfox_tq_cells.jpg]]"
idle_render: "[[Sparkfox_idle.png]]"
---
# Sparkfox (Vixa), Rare, World 1 Verdant

An orange fox painter, 3 studs to its ear tips (B45: a small fox, mid-band): a square head with a cream muzzle block and an ink nose under the face plate, cream cheek tufts on both sides, stepped ears with plum tips and cream insides, a plum painter's beret tipped between them with a gold stalk, plum socks, and a tail that is a paintbrush: a plum handle, a glossy gold ferrule and orange fur bristles tapering to a tip dipped in glowing amber paint, leaning back and out to its right. A paint drop floats beside the brush, and a gold flame is stamped on each flank. Concept row in `src/shared/data/Species.luau`: "fox, glowing paintbrush tail". Element: Ember (`Effects.luau`); [[Roster-Redesign]] section 2 gives the paint-spark trail, the falling drop and the soft orange light. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It is the first creature on the meadow that gives off light, and the first with a costume: a painter's beret between its ears and a brush for a tail. At the same height as the Uncommons it carries twice their blocks (the muzzle, nose, cheek tufts, beret and flames are all small cells), its own `glimmer` eyes (a teal iris ringed darker against the orange, two shines and a glint), five moving things and a flourish every 8 s that reads across the meadow: a twirl, the brush sweeping a stroke of sparks.

**Hero block.** The `Brush`, the orange bristle head of the tail, with its gold ferrule and plum handle under it and its glowing tip over it: unique in Verdant.

**Moving parts (four objects and the blink).** `earR` and `earL` (each with its tip and inside: they twitch), `tail` (the whole brush: it sways and sweeps), `float` (the paint drop: it bobs and circles); the face plate blinks and glints.

**Alien anatomy.** The tail is a tool, not fur, and the paint drop floats free of it.

**World motif (Verdant).** The moss cell, here as the half-stud steps of the ears and the brush and the eighth-stud cells of the flame, the beret and the muzzle.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.5, -0.75], bevel: true}
  - {name: Body, slot: Body, size: [1.5, 1, 2], at: [0, 1, 0.75], bevel: true}
  - {name: FrontLeg, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, -0.5], mirror: x}
  - {name: HindLeg, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, 1.5], mirror: x}
  # the fox's face in blocks under the plate: a cream muzzle with an ink nose on its top edge, cream cheek tufts out of the head's sides
  - {name: Muzzle, slot: BodyDark, size: [0.5, 0.375, 0.125], at: [0, 1.0625, -1.5625]}
  - {name: Nose, slot: Eye, size: [0.25, 0.125, 0.125], at: [0, 1.1875, -1.6875]}
  # Polish w1: the tufts sat at the head's bottom corners beside the front legs and read as paws; they now flare out at cheek height
  # beside the eyes, a step out and a smaller step further out and up, so the face widens at the cheeks like a fox's ruff
  - {name: Tuft, slot: BodyDark, size: [0.125, 0.375, 0.5], at: [1.0625, 1.3125, -1.125], mirror: x}
  - {name: TuftTip, slot: BodyDark, size: [0.125, 0.125, 0.375], at: [1.1875, 1.4375, -1.1875], mirror: x}
  # stepped fox ears: an orange base, a plum tip and a cream inside, each ear one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.5, 0.25], at: [0.625, 2.5, -0.875], mirror: x, moves: ear, pivot: [0.625, 2.25, -0.875]}
  - {name: EarTip, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.625, 2.875, -0.875], mirror: x, moves: ear, pivot: [0.625, 2.25, -0.875]}
  - {name: InnerEar, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [0.625, 2.375, -1.0625], mirror: x, moves: ear, pivot: [0.625, 2.25, -0.875]}
  # a painter's beret tipped between the ears, a gold stalk on top
  - {name: Beret, slot: Accessory, size: [0.75, 0.25, 0.875], at: [0, 2.375, -0.6875], rot: [0, 0, 15]}
  - {name: BeretStalk, slot: Trim, size: [0.125, 0.125, 0.125], at: [-0.0625, 2.5625, -0.6875], rot: [0, 0, 15], material: metal}
  # the hero: the paintbrush tail, leaning back and out to the right: a plum handle, a glossy gold ferrule, a head of orange fur bristles tapering to a point dipped in glowing paint
  - {name: Tail, slot: Accessory, size: [0.375, 0.5, 0.375], at: [0.4375, 1.3125, 1.875], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: Ferrule, slot: Trim, size: [0.625, 0.25, 0.625], at: [0.5625, 1.6875, 2], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75], material: metal}
  - {name: Brush, slot: Body, size: [0.875, 0.5, 0.875], at: [0.6875, 2, 2.1875], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: Brush2, slot: Body, size: [0.75, 0.25, 0.75], at: [0.8125, 2.3125, 2.3125], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: BrushTip, slot: Glow, size: [0.5, 0.25, 0.5], at: [0.875, 2.5, 2.4375], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: BrushTip2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.9375, 2.75, 2.5625], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  # alien anatomy: a drop of glowing paint floating free beside the brush
  - {name: Drop, slot: Glow, size: [0.25, 0.375, 0.25], at: [1.5, 2.1875, 2.75], shape: ico1, moves: float, pivot: [1.5, 2.1875, 2.75]}
  # Rare pass w1, the signature piece: a painter's palette floating at its left shoulder, a plum board held up to face the front, tipped back 20 degrees toward the
  # camera with four dabs of paint on it (lit amber, cream, gold, orange) and a gold thumb ring; it bobs and turns, and leaps with the
  # flourish (`palette`)
  - {name: Palette, slot: Accessory, size: [0.75, 0.125, 0.625], at: [-1.5, 2.625, -1.5], rot: [-70, 0, 0], moves: palette, pivot: [-1.5, 2.625, -1.5]}
  - {name: Dab0, slot: Glow, size: [0.125, 0.125, 0.125], at: [-1.6875, 2.5, -1.6875], rot: [-70, 0, 0], moves: palette, pivot: [-1.5, 2.625, -1.5]}
  - {name: Dab1, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [-1.3125, 2.5, -1.6875], rot: [-70, 0, 0], moves: palette, pivot: [-1.5, 2.625, -1.5]}
  - {name: Dab2, slot: Trim, size: [0.125, 0.125, 0.125], at: [-1.3125, 2.875, -1.5625], rot: [-70, 0, 0], moves: palette, pivot: [-1.5, 2.625, -1.5]}
  - {name: Dab3, slot: Body, size: [0.125, 0.125, 0.125], at: [-1.6875, 2.875, -1.5625], rot: [-70, 0, 0], moves: palette, pivot: [-1.5, 2.625, -1.5]}
  - {name: ThumbRing, slot: Trim, size: [0.125, 0.125, 0.25], at: [-1.9375, 2.625, -1.5], rot: [-70, 0, 0], moves: palette, pivot: [-1.5, 2.625, -1.5], material: metal}
  # the stamped element glyph: a gold pixel flame on each flank (rows of eighth-stud cells, bottom to top)
  - {name: Flame, slot: Trim, size: [0.125, 0.125, 0.375], at: [0.8125, 0.6875, 0.8125], mirror: x}
  - {name: Flame2, slot: Trim, size: [0.125, 0.25, 0.625], at: [0.8125, 0.875, 0.8125], mirror: x}
  - {name: Flame3, slot: Trim, size: [0.125, 0.125, 0.375], at: [0.8125, 1.0625, 0.8125], mirror: x}
  - {name: Flame4, slot: Trim, size: [0.125, 0.25, 0.125], at: [0.8125, 1.25, 0.8125], mirror: x}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes and cheeks are on the face plate, the muzzle and nose are blocks under it (a muzzle block may carry the mouth, [[Blocky-Style]] "World 1 roster notes").

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `glimmer`, a Rare design, a teal iris ringed in deep teal with two shines and a glint, at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, five frames). No mouth on the plate (the muzzle and nose are blocks), blush cheeks.

```yaml
eyes:
  key: glimmer
  colours: {iris: "#35C2A8", iris2: "#1E6B60", glint: glow}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.5]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the ears twitch, the brush sways and dips, the paint drop bobs and circles, the fox breathes, the face blinks and glints. Five moving things (four objects and the blink; a Rare needs four). The flourish, every 8 s: a painter's twirl, a hop and a full turn with the brush sweeping, the ears flared and the drop leaping.

```yaml
rig:
  clips:
    ear: [{kind: wag, amp: 14, period: 4, axis: z}, {kind: sway, amp: 5, period: 2.6, axis: x, phase: 0.3}]
    tail: [{kind: sway, amp: 14, period: 2.2, axis: z}, {kind: sway, amp: 6, period: 3.3, axis: x, phase: 0.25}]
    float: [{kind: bob, amp: 0.12, period: 2}, {kind: orbit, amp: 0.08, period: 4}]
    palette: [{kind: bob, amp: 0.1, period: 2.6, phase: 0.4}, {kind: sway, amp: 8, period: 3.4, axis: y}]
    root: [{kind: squash, amp: 0.03, period: 2.4}]
    face: [{kind: blink, period: 4.4}]
  flourish:
    every: 8
    length: 2.2
    moves:
      - {part: root, kind: hop, amp: 0.3, at: 0.1, for: 0.6}
      - {part: root, kind: turn, amp: 360, axis: y, at: 0.1, for: 1.4}
      - {part: tail, kind: swish, amp: 30, axis: z, at: 0.4, for: 1.4}
      - {part: ear, kind: flare, amp: 20, axis: z, at: 0.2, for: 0.8}
      - {part: palette, kind: hop, amp: 0.3, at: 0.3, for: 0.8}
      - {part: palette, kind: turn, amp: 360, axis: y, at: 0.5, for: 1.2}
      - {part: float, kind: hop, amp: 0.4, at: 0.8, for: 0.8}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Sparkfox.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Sparkfox.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Sparkfox_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Sparkfox_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Sparkfox_idle.png]]

The concept sheet, drawn from the parts table above: [[Sparkfox_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Sparkfox_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 24 cells tall. Materials: metal on the ferrule and the beret's stalk, skin elsewhere; the brush tip and the drop are glow cells.

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: a cream brush on a pale sky read as a floating cloud, not joined to the fox. Round 2: the tail as one tilted stack (handle, ferrule, bristles, tip) that grows out of the rump; still pale, and the cube head of the brush read as a mallet. Round 3: a plum handle and orange bristles tapering in two steps to a lit point, the amber paint drop floating free; the tail lowered an eighth to keep 3 studs. Overlap 0.994 to 0.997, 548 triangles, 29 blocks, 3 studs. Wanted for: the first light on the meadow and a tail that is a paintbrush, with a stamped gold flame. Still cheap: the Rare preview is only a soft light (as the ladder says), so at night it is a lit tail and little else; the drop is small at distance. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The orange keeps its punch; the cream muzzle cells sit in the face grid as before; the gold flame stays flat (detail blocks under three cells take no edge). Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, one round. Kept at 3 studs (a small fox, mid-band) and rebuilt to 33 blocks: a cream muzzle block with an ink nose under the plate (the face rows' muzzle, now in blocks), cream cheek tufts, a plum painter's beret tipped 15 degrees between the ears with a gold stalk, the flank flame in four rows. Its own `glimmer` eyes in teal ringed deep teal (a cool eye on the warmest body in Verdant), blush cheeks, no plate mouth; four moving objects and the blink; a flourish every 8 s (a hop and a full turn, the brush sweeping, ears flared, the drop leaping). Overlap 0.997 to 0.998. Wanted for: a painter fox with a lit brush, the first costume on the meadow. Still weak: the cheek tufts sit low and read as white paws from the three-quarter view; the beret is small between the ears at distance. Status review.
- 2026-10-21, Polish w1, two rounds. The cream cheek tufts sat at the head's bottom corners beside the front legs and read as paws: they now flare out at cheek height beside the eyes (a tuft an eighth proud and a smaller tip a step further out and up), so the face widens at the cheeks like a fox's ruff. Round 1 made them a quarter proud with a bigger tip and pushed the front silhouette to 0.705 against Gaira; at an eighth it is 0.683. 35 blocks (Rare 18 to 36). Overlap 0.994 to 0.998. Honest read: the tufts read as cheek fluff now, nothing low reads as a paw but the paws; small at distance. Status review.
