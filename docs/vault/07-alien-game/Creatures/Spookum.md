---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Spookum
name: Grin
world: 1
tier: Epic
status: review
element: Shadow
height: 3.44
blocks: 62
tris: 790
bevel_width: 0.125
bevel_segments: 2
palette: ["#E9E6FF", "#5B4A8A", "#FF9F1C", "#B89B5A", "#9D6BFF", "#1B1430"]
roles: [body, second, accent, trim, glow, ink]
hero: Stem
vfx: "kept on the body (Epic): Effects.luau's pumpkin-orange Light (FF9F1C) at the Mouth pulsing every 2.4 s, so the grin glows from inside; a ghost-white mist (E9E2FF) pooling at the Feet at 3 a second; ember flickers (FFB347) rising off the Top at 2.5 a second; its signature Burst, a ring of twelve violet wisps (C77DFF) every 5 s and on the flourish (the boo); a violet Sparkle at the Tail every 3 s; a Hover idle of 0.35 studs over 3 s. On the model the tatter tips, the little lantern's face, the lock's keyhole and the back emblem's eyes are violet glow cells. The rig adds the motion and the flourish: the arms wave, the hem and tatters stir, the stem sways, a little jack-o'-lantern floats and turns at its side, and every 10 s it says boo (a squash, a hop and a full turn, the arms flung wide)"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Spookum_sheet.svg]]"
render: "[[Spookum_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.996, 0.997, 0.995]
vfx_render: "[[Spookum_vfx_cells.jpg]]"
cells_render: "[[Spookum_tq_cells.jpg]]"
idle_render: "[[Spookum_idle.png]]"
---
# Spookum (Grin), Epic, World 1 Verdant, the Haunted Nebula event

A round ghost with a pumpkin's grin, 3.44 studs (B45: it was 3.91): a soft lilac-white block body with a bulge proud of each flank and three narrowing steps on top (a dome, a crown in a thin brass band, a cap), so it reads as a ghost's dome rather than a cube, a brass pumpkin stem with a drooping curl and a dusk-violet leaf on its crown, and its own starry eyes over a wide jack-o'-lantern grin built proud of its front in sixteenth-stud cells, an orange slit lit from inside with two white teeth hanging from its top and one rising from the bottom. Under the body a violet hem flares wider than the body like a sheet's skirt, and a ragged fringe of fifteen narrow points of different lengths hangs from its edge all round to the grass, three of them lit violet at their tips; two stubby arms rise out at its sides in a "boo", and a brass chain of five links hangs from the right hand to a little brass lock with a lit keyhole. A tiny jack-o'-lantern with a lit face floats at its left shoulder. Dusk-violet ribs run up its back and sides like a pumpkin's, and a stepped orange pumpkin emblem with two lit eyes sits between the back ribs. Concept row in `src/shared/data/Species.luau`: "round ghost, pumpkin grin, drifts an inch off the ground". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`). Element and effect: [[Roster-Redesign]] section 2 (Shadow; the grin glows orange from inside, a pool of purple mist spreads under it, it fades and returns every 5 s; `Effects.luau` calls the element Ghost). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the event's face: a ghost whose grin is a jack-o'-lantern's, drifting an inch off the ground at night with its tatters brushing the grass, a chain swinging from one hand and a little lantern friend bobbing at its shoulder. B46: smaller than before and much more detailed, 62 blocks in sixteenth-stud cells; its own `hearty` eyes (violet irises with a pumpkin-orange heart for a pupil, a shine on its lobe and orange lashes) and blush cheeks, the cutest face of the event; six moving things and a boo every 10 s. The Epic rung's detail: trim (the brass stem, band, chain and lock), stripes (the ribs), a stepped emblem (the pumpkin on its back), glow on its extremities (the tatter tips, the lantern's face), the light kept on the body.

**Hero block.** The `Stem`, a brass pumpkin stem with a curl and a leaf on a ghost's crown: the one block that says this ghost is a pumpkin, unique in Verdant (Moop's sprout is a lime leaf).

**Moving parts (five objects and the blink).** `armR` and `armL` (the arms wave; the chain and lock swing with the right one), `hem` (the hem and its tatters stir), `stem` (the stem, its curl and leaf sway), `lanternL` (the little jack-o'-lantern bobs, circles and turns); the plate blinks and glints.

**Alien anatomy.** A ghost that is also a pumpkin: a stem on its crown, ribs on its body, a grin that glows from inside, a hem of tatters it floats on, and a pumpkin of its own that follows it like a pet.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the crown, the hem, the tatters and the emblem.

**Event palette (Haunted Nebula).** Ghost white over dusk violet with the event's pumpkin orange as the accent, old brass trim and a violet glow: the warm end of the event's range (Wispkin is the cold blue end, Cosmoo the deep violet).

## Parts

```yaml
parts:
  # the body: one soft lilac-white block, the face plate and the grin on its front; a sheet's round from blocks (Polish w1): a flank bulge
  # proud of each side and three narrowing steps on top (the dome, the crown in its brass band, the cap), so it reads as a ghost's dome
  - {name: Body, slot: Body, size: [2, 1.5, 2], at: [0, 1.5, 0], bevel: true}
  - {name: Flank, slot: Body, size: [0.125, 1, 1.5], at: [1.0625, 1.5, 0], mirror: x}
  - {name: Dome, slot: Body, size: [1.625, 0.25, 1.625], at: [0, 2.375, 0]}
  - {name: CrownBand, slot: Trim, size: [1.25, 0.0625, 1.25], at: [0, 2.53125, 0], material: metal}
  - {name: Crown, slot: Body, size: [1.125, 0.25, 1.125], at: [0, 2.625, 0]}
  - {name: Cap, slot: Body, size: [0.625, 0.125, 0.625], at: [0, 2.8125, 0]}
  # the hero: a brass pumpkin stem with a drooping curl and a dusk-violet leaf on the crown (they sway)
  - {name: Stem, slot: Trim, size: [0.375, 0.375, 0.375], at: [0.1875, 3.0625, 0], moves: stem, pivot: [0, 2.875, 0]}
  - {name: StemCurl, slot: Trim, size: [0.4375, 0.1875, 0.1875], at: [0.4375, 3.28125, 0], rot: [0, 0, -20], moves: stem, pivot: [0, 2.875, 0]}
  - {name: Leaf, slot: BodyDark, size: [0.375, 0.0625, 0.25], at: [-0.15625, 2.96875, 0.0625], rot: [0, 0, 15], moves: stem, pivot: [0, 2.875, 0]}
  # the jack-o'-lantern grin, built proud of the front under the face plate in sixteenth-stud cells: an orange slit lit from inside with
  # upturned corners, an ink line under it, two white teeth hanging from its top edge and one rising from the bottom
  - {name: Grin, slot: Accessory, size: [1.25, 0.25, 0.0625], at: [0, 0.9375, -1.03125], material: glow}
  - {name: GrinCorner, slot: Accessory, size: [0.125, 0.125, 0.0625], at: [0.6875, 1.125, -1.03125], mirror: x, material: glow}
  - {name: GrinLine, slot: Eye, size: [1.25, 0.0625, 0.0625], at: [0, 0.78125, -1.03125]}
  - {name: Tooth, slot: Body, size: [0.125, 0.125, 0.0625], at: [0.25, 1, -1.09375], mirror: x}
  - {name: Tooth2, slot: Body, size: [0.125, 0.125, 0.0625], at: [0, 0.875, -1.09375]}
  # the violet hem flares wider than the body like a sheet's skirt, and a ragged fringe of fifteen narrow points of different lengths hangs
  # from its edge all round (Polish w1: no gap under it as wide as a leg), three of them lit violet at the tip; they stir together
  - {name: Hem, slot: BodyDark, size: [2.25, 0.375, 2.25], at: [0, 0.5625, 0], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-1, 0.3125, -1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter2, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [-0.5, 0.25, -1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter3, slot: BodyDark, size: [0.25, 0.1875, 0.125], at: [0, 0.28125, -1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter4, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [0.5, 0.25, -1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter5, slot: BodyDark, size: [0.25, 0.1875, 0.125], at: [1, 0.28125, -1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter6, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [-0.875, 0.25, 1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter7, slot: BodyDark, size: [0.25, 0.1875, 0.125], at: [-0.25, 0.28125, 1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter8, slot: BodyDark, size: [0.25, 0.3125, 0.125], at: [0.375, 0.21875, 1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter9, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [0.875, 0.3125, 1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter10, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.0625, 0.25, -0.5], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter11, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.0625, 0.25, 0], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter12, slot: BodyDark, size: [0.125, 0.125, 0.25], at: [1.0625, 0.3125, 0.5], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter13, slot: BodyDark, size: [0.125, 0.3125, 0.25], at: [-1.0625, 0.21875, -0.5], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter14, slot: BodyDark, size: [0.125, 0.1875, 0.25], at: [-1.0625, 0.28125, 0], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter15, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [-1.0625, 0.25, 0.5], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter4Tip, slot: Glow, size: [0.25, 0.125, 0.125], at: [0.5, 0.0625, -1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter6Tip, slot: Glow, size: [0.25, 0.125, 0.125], at: [-0.875, 0.0625, 1.0625], moves: hem, pivot: [0, 0.75, 0]}
  - {name: Tatter11Tip, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.0625, 0.0625, 0], moves: hem, pivot: [0, 0.75, 0]}
  # two stubby arms rising out 20 degrees, a hand on each (they wave); the brass chain of five links hangs from the right hand to a little
  # brass lock with a lit keyhole, and swings with it
  - {name: Arm, slot: Body, size: [0.625, 0.3125, 0.4375], at: [1.28125, 1.84375, -0.25], rot: [0, 0, 20], mirror: x, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Hand, slot: Body, size: [0.3125, 0.3125, 0.4375], at: [1.71875, 2.03125, -0.25], rot: [0, 0, 20], mirror: x, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Chain, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [1.75, 1.71875, -0.28125], material: metal, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Chain2, slot: Trim, size: [0.0625, 0.1875, 0.125], at: [1.78125, 1.53125, -0.25], material: metal, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Chain3, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [1.75, 1.34375, -0.28125], material: metal, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Chain4, slot: Trim, size: [0.0625, 0.1875, 0.125], at: [1.78125, 1.15625, -0.25], material: metal, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Chain5, slot: Trim, size: [0.125, 0.1875, 0.0625], at: [1.75, 0.96875, -0.28125], material: metal, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Lock, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.75, 0.75, -0.25], material: metal, moves: arm, pivot: [1, 1.75, -0.25]}
  - {name: Keyhole, slot: Glow, size: [0.0625, 0.125, 0.0625], at: [1.78125, 0.75, -0.34375], moves: arm, pivot: [1, 1.75, -0.25]}
  # a tiny jack-o'-lantern floating at its left shoulder, its face lit violet (it bobs, circles and turns)
  - {name: Lantern, slot: Accessory, size: [0.375, 0.375, 0.375], at: [-1.375, 2.375, -0.25], moves: lantern, pivot: [-1.375, 2.375, -0.25]}
  - {name: LanternStem, slot: Trim, size: [0.125, 0.125, 0.125], at: [-1.375, 2.625, -0.25], moves: lantern, pivot: [-1.375, 2.375, -0.25]}
  - {name: LanternGrin, slot: Glow, size: [0.25, 0.0625, 0.0625], at: [-1.375, 2.28125, -0.46875], moves: lantern, pivot: [-1.375, 2.375, -0.25]}
  - {name: LanternEye, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [-1.46875, 2.40625, -0.46875], moves: lantern, pivot: [-1.375, 2.375, -0.25]}
  - {name: LanternEye2, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [-1.28125, 2.40625, -0.46875], moves: lantern, pivot: [-1.375, 2.375, -0.25]}
  # pumpkin ribs: dusk-violet strips proud of the back and the sides by an eighth
  - {name: Rib, slot: BodyDark, size: [0.25, 1.25, 0.125], at: [0.625, 1.5, 1.0625], mirror: x}
  - {name: SideRib, slot: BodyDark, size: [0.125, 1.25, 0.25], at: [1.1875, 1.5, 0.375], mirror: x}
  # the stepped emblem: an orange pumpkin of three steps with a violet stem and two lit eyes, between the back ribs
  - {name: Emblem, slot: Accessory, size: [0.5, 0.1875, 0.125], at: [0, 1.28125, 1.0625]}
  - {name: Emblem2, slot: Accessory, size: [0.75, 0.3125, 0.125], at: [0, 1.53125, 1.0625]}
  - {name: Emblem3, slot: Accessory, size: [0.5, 0.1875, 0.125], at: [0, 1.78125, 1.0625]}
  - {name: EmblemStem, slot: BodyDark, size: [0.125, 0.1875, 0.125], at: [0, 1.96875, 1.0625]}
  - {name: EmblemEye, slot: Glow, size: [0.0625, 0.0625, 0.0625], at: [0.15625, 1.59375, 1.15625], mirror: x}
```

## Face

The body's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud block, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes and the cheeks are on the face plate, and the jack-o'-lantern grin is geometry proud of the front under it (the plate's own mouths are too small to carry a pumpkin's grin, and the grin has to be a place `Effects.luau` lights from within).

```yaml
face:
  host: Body
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `hearty`, an Epic design, a two-tone iris (the lit violet over dusk violet) with a heart for a pupil in pumpkin orange, a shine on its lobe and orange lashes at the outer corner, two glint frames. At 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, five frames). No mouth on the plate (the grin is built under it) and blush cheeks. Round one wore `starry`: at 16 pixels a stud its orange star read as a plus, a crosshair in each eye. In World 1 only Grin wears `hearty` in these colours.

```yaml
eyes:
  key: hearty
  colours: {iris: glow, iris2: second, pupil: accent, lash: accent}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.5625]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`, World.RigAnimator plays them and calls `SpeciesFx.Flourish` on each flourish, the moment `Effects.luau`'s ring of violet wisps fires): the arms wave out of step (the chain and lock swing with the right), the hem and tatters stir, the stem sways, the little jack-o'-lantern bobs, circles and turns, the body breathes, the face blinks. Five objects and the blink (an Epic needs five). The flourish, every 10 s, the boo: a squash, a hop and a full turn with the arms flung wide, the hem swishing and the lantern leaping.

```yaml
rig:
  clips:
    arm: [{kind: flap, amp: 15, period: 1.6, axis: z}]
    hem: [{kind: sway, amp: 5, period: 2, axis: x}, {kind: sway, amp: 4, period: 2.6, axis: z, phase: 0.25}]
    stem: [{kind: sway, amp: 8, period: 2.4, axis: z}]
    lanternL: [{kind: bob, amp: 0.15, period: 2}, {kind: orbit, amp: 0.12, period: 6}, {kind: spin, amp: 360, period: 5, axis: y}]
    root: [{kind: squash, amp: 0.04, period: 3}]
    face: [{kind: blink, period: 4}]
  flourish:
    every: 10
    length: 2.2
    moves:
      - {part: root, kind: squash, amp: 0.15, at: 0, for: 0.4}
      - {part: root, kind: hop, amp: 0.6, at: 0.3, for: 0.8}
      - {part: root, kind: turn, amp: 360, at: 0.4, for: 1.6}
      - {part: arm, kind: flare, amp: 30, at: 0.3, for: 1.2}
      - {part: hem, kind: swish, amp: 15, at: 0.5, for: 1}
      - {part: lanternL, kind: hop, amp: 0.3, at: 0.8, for: 0.9}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Spookum.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Spookum.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Spookum_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Spookum_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Spookum_idle.png]]

The concept sheet, drawn from the parts table above: [[Spookum_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Spookum_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 28 cells tall; one atlas of 512 x 1024 at 8 texels a cell. Materials: skin on the body, the crown, the hem, the tatters, the arms, the ribs and the emblem (a sheet has no motif; the cells and the grout are what make it read as built), metal on the chain (glossy); the stem is glossy trim; the tatter tips are glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, one round. Built as drawn: the jack-o'-lantern grin under the house eyes reads at once, the brass stem says pumpkin, the chain swings from the right hand on the camera's side, the three lit tatter tips put the Epic's glow at the hem where the mist pools in the game. Overlap 0.994 to 0.996, 416 triangles, 31 blocks, 3.91 studs; the boxed silhouette's worst pair is Zirrit at 0.65. Wanted for: the event's face, a ghost whose grin is a pumpkin's. Still cheap: the arms are two plain white bars; the back emblem and ribs are behind the three-quarter camera (the game's high camera sees the ribs on the sides). Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, two rounds. Brought to 3.32 studs from 3.91 by a shorter body (1.75 studs, the head 53 percent), not a scale; 49 blocks in sixteenth-stud detail (the Epic band is 32 to 64): a brass band round the crown, a leaf and a drooping curl on the stem, the jack-o'-lantern grin rebuilt as geometry proud of the front under the plate (an orange slit on the glow material, upturned corners, an ink line, three white teeth), a five-link chain to a brass lock with a lit keyhole, a tiny floating jack-o'-lantern with a lit face, two lit eyes on the back emblem. Round 1 wore `starry`: at 16 pixels a stud the orange star read as a plus, a crosshair in each eye; round 2 `hearty`, an orange heart pupil in a violet iris with orange lashes, and blush cheeks. Five moving objects and the blink (the arms wave with the chain, the hem and tatters stir, the stem sways, the lantern bobs, circles and turns) and the boo every 10 s: a squash, a hop and a full turn with the arms flung wide. Overlap 0.994 to 0.995, 638 triangles; worst silhouette pair 0.669 (Dandel). Wanted for: the event's face, a pumpkin ghost with heart eyes and a lantern of its own. Still weak: the body is still a cube, and the three white tatters read as legs from the three-quarter view (as before). Status review.
- 2026-10-21, Polish w1, four rounds. The cube and the leg-like tatters. The body is 1.5 studs tall now with a bulge proud of each flank and three narrowing steps on top (a dome 1.625, the crown 1.125 in its brass band, a cap 0.625), so the front and side outlines step in like a dome; the plate and the grin moved down a sixteenth to stay in the lower half. The hem flares to 2.25 studs and the six tatters (three white ones with lit tips read as two legs and feet) became a ragged fringe of fifteen narrow violet points from an eighth to three eighths long all round, three of them lit and none at a corner (a lit corner point read as a foot). A white hem was tried and read as a table on legs. 62 blocks (Epic 32 to 64), 3.44 studs. Overlap 0.994 to 0.997. Honest read: the hem now reads as a ghost's ragged skirt and nothing reads as legs; from the three-quarter view the white body is still mostly a block with a domed top (white on white hides the steps; the front view shows them clearly). Status review.
