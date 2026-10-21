---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Buzzlebee
name: Buzzik
world: 1
tier: Uncommon
status: review
element: Pollen
height: 2.58
blocks: 19
tris: 424
bevel_width: 0.1
bevel_segments: 2
palette: ["#FFC83D", "#4A2F1F", "#FF6B9A", "#1A120C"]
roles: [body, second, accent, ink]
hero: Backpack
vfx: "two touches (Uncommon): Effects.luau's yellow pollen Emitter (FFD84D) at the Back, 3 motes a second drifting down for 1.3 s, and a white Sparkle at BackL every 2.5 s, the second colour; a Flap idle on its wings (25 degrees, 0.14 s); no light, no glow region. The rig adds the motion: the four wings beat, the antennae nod, the stinger wags and the body hovers"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Buzzlebee_sheet.svg]]"
render: "[[Buzzlebee_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.995, 0.998, 0.995]
cells_render: "[[Buzzlebee_tq_cells.jpg]]"
idle_render: "[[Buzzlebee_idle.png]]"
---
# Buzzlebee (Buzzik), Uncommon, World 1 Verdant

A honey-yellow bee, 2.6 studs to its antenna tips, with a wide square head, a striped abdomen, four pink wings (two pairs, the big pair angled up) and a tiny pink backpack with a cocoa flap behind the wing roots, its two cocoa straps running forward over its back. Long antennae end in pink pompoms. It stands on two stubby front legs and lets its striped back end hang in the air. Concept row in `src/shared/data/Species.luau`: "bee, tiny backpack". Element: Pollen (the species' row in `src/shared/data/Effects.luau`); [[Roster-Redesign]] section 2 gives the buzz and the motes. Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first creature on the meadow with a *thing*: the backpack says it is going somewhere, and the four wings say it is not quite a bee. B46: its own `twotone` eyes, a pink iris under a cocoa top with a big pupil and a shine, over a toothy grin, and the most motion of the lower rungs: four wings beating, the pompom antennae nodding and the stinger wagging. It is the Uncommon rung exactly: a two-tone body (the yellow and cocoa stripes), one secondary block (the pack) and one small touch of a second colour (the pink on the pack, the wings, the pompoms and the eyes), so it reads as one step up from Moop and one step short of Vixa's glossy trim and light.

**Hero block.** The `Backpack`: a pink box with a cocoa flap folded over its front and two straps, behind the wing roots, unique in Verdant.

**Moving parts (four objects and the blink).** `wingR` and `wingL` (both pairs beat as one a side), `antenna` (the pair nods), `stinger` (it wags); the plate blinks.

**Alien anatomy.** Two pairs of wings of different sizes, both on one pivot per side, so they flap together like a dragonfly's, and long bare antennae; it walks on two legs and hovers its abdomen.

**World motif (Verdant).** The moss cell, here as the half-stud steps of the stripes and the pack.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, -0.375], bevel: true}
  - {name: Abdomen, slot: Body, size: [1.5, 1, 1.25], at: [0, 1, 1], bevel: true}
  # the two-tone body: two cocoa stripes round the abdomen, proud by an eighth, and a cone stinger behind that wags
  - {name: Band, slot: BodyDark, size: [1.75, 1.25, 0.25], at: [0, 1, 0.75]}
  - {name: Band2, slot: BodyDark, size: [1.75, 1.25, 0.25], at: [0, 1, 1.25]}
  - {name: Stinger, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 0.9375, 1.75], shape: cone6, rot: [90, 0, 0], moves: stinger, pivot: [0, 0.9375, 1.625]}
  - {name: Leg, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.5, 0.1875, -0.5], mirror: x}
  # long antennae with pink pompoms; the pair nods as one
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [0.625, 2, -0.625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0, 1.625, -0.625]}
  - {name: Pompom, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.8125, 2.4375, -0.625], shape: ico1, rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0, 1.625, -0.625]}
  # alien anatomy: four wings, a big pair angled up and a small pair behind, both on one pivot a side so they flap as one
  - {name: Wing, slot: Accessory, size: [1, 0.125, 0.625], at: [0.8125, 1.8125, 0.375], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.375, 1.625, 0.5], material: crystal}
  - {name: HindWing, slot: Accessory, size: [0.75, 0.125, 0.5], at: [0.75, 1.625, 0.875], rot: [0, 0, 15], mirror: x, moves: wing, pivot: [0.375, 1.625, 0.5], material: crystal}
  # the hero: a tiny pink backpack behind the wing roots, its cocoa flap folded over the front, two cocoa straps running forward over the back
  - {name: Backpack, slot: Accessory, size: [0.75, 0.625, 0.5], at: [0, 1.6875, 1.375]}
  - {name: Flap, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [0, 2.0625, 1.25]}
  - {name: Strap, slot: BodyDark, size: [0.125, 0.125, 0.75], at: [0.3125, 1.6875, 0.75], mirror: x}
```

## Face

The head's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `twotone`, an Uncommon design, a round iris dark over light with a big pupil and two shines: the top half cocoa (the second colour), the bottom pink (the accent), the colours of its stripes and its pack. At 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, three frames). A toothy `grin` with a pink tongue and dot cheeks. In World 1 only Buzzik wears `twotone`.

```yaml
eyes:
  key: twotone
  colours: {iris: accent, iris2: second}
  mouth: grin
  cheeks: dots
  plate: [1.75, 1]
  at: [0, 0.9375]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it; Effects.luau's Flap idle buzzes the wings faster on top): the wings beat, the pompom antennae nod, the stinger wags in bursts, the whole bee bobs as it hovers, the face blinks. Four objects and the blink (an Uncommon needs three); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    wing: [{kind: flap, amp: 20, period: 0.4, axis: z}]
    antenna: [{kind: sway, amp: 10, period: 1.6, axis: x}]
    stinger: [{kind: wag, amp: 15, period: 2.2, axis: y}]
    root: [{kind: bob, amp: 0.08, period: 1.2}]
    face: [{kind: blink, period: 3.8}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Buzzlebee.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Buzzlebee.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Buzzlebee_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Buzzlebee_idle.png]]

The concept sheet, drawn from the parts table above: [[Buzzlebee_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Buzzlebee_sheet.png]]. The flat build of loop 2 and its silhouette views: [[Buzzlebee_tq.jpg]], [[Buzzlebee_views.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 21 cells tall; one atlas at 8 texels a cell. Materials: crystal on the four wings (light diagonals, so they read as wing membrane), skin elsewhere.

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: a sky-blue accent: the blue crescent under each eye read as tears, and a dark lid over the pack lay on the wings like a board. Round 2: the accent went to pink (the crescents, the four wings, the pack) and the pack moved behind the wing roots with a small cocoa flap. Round 3: no change after the side-by-side. Overlap 0.993 to 0.998, 370 triangles, 15 blocks, 2.37 studs. Wanted for: four pink wings and a tiny backpack, the first creature that carries something. Still cheap: the pack reads as a pink box (straps do not fit in 15 blocks), and from the side the cocoa stripes darken the whole abdomen. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). At 1 : 2 : 1 jitter the yellow read as a sponge; at 1 : 6 : 1 with the grout it is a clean yellow of little blocks; the wings' diagonals read as shimmer. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, one round. In the band (2.58 studs to its pompoms, from 2.37): pink pompoms on the antenna tips and two cocoa straps from the pack over its back bring it to 19 blocks (the Uncommon band is 10 to 20). Its own `twotone` eyes, cocoa over pink with a big pupil, a toothy grin and dot cheeks; four moving objects and the blink: both wing pairs beat as one a side, the pompom antennae nod, the stinger wags in bursts, the bee bobs as it hovers. Overlap 0.995 to 0.998, 424 triangles; worst silhouette pair 0.668 (Twiglo), from 0.684. Wanted for: the first alien with a thing (the pack), and now the liveliest face of the lower rungs. Still weak: from the three-quarter view the straps read as the arms of a chair over the pack, and the pompoms crowd the big wings. Status review.
