---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Puffpuff
name: Dandel
world: 1
tier: Common
status: review
element: Wind
height: 2.5
blocks: 12
tris: 228
bevel_width: 0.1
bevel_segments: 2
palette: ["#F4F1E8", "#4E9E3C", "#F5C542", "#1D2418"]
roles: [body, second, accent, ink]
hero: Parachute
vfx: "none of its own (Common): Effects.luau's one Burst, a single white seed (FFFFFF, the PixelSeed sprite) lifting off the Top every 5 s and floating away for 3.5 s; a Spin idle, one slow turn on the spot in 16 s; no light, no glow region. The rig adds the motion: the loose seed bobs and drifts, the seeds on the puff sway, the two leaves rise and fall"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Puffpuff_sheet.svg]]"
render: "[[Puffpuff_tq_cells.jpg]]"
glb: ""
overlap: [0.993, 0.996, 0.998, 0.994]
cells_render: "[[Puffpuff_tq_cells.jpg]]"
idle_render: "[[Puffpuff_idle.png]]"
---
# Puffpuff (Dandel), Common, World 1 Verdant

A dandelion clock with a face, 2.5 studs: a soft white seed-head (the head, in woolly cells, stepped narrower above and below so it reads as a round puff) on a yellow calyx with two green sepals curling down and out from its front corners past the head's sides and a short green stem, standing on two broad green leaves that rise out from its foot like a rosette. Three seeds still stand on the puff, each an upturned cone with its parachute open, and one more has just let go and floats beside it. Concept row in `src/shared/data/Species.luau`: "dandelion puff, face". Element and effect: [[Roster-Redesign]] section 2 (Wind; a seed lifts off every 5 s). Rules: [[Blocky-Style]].

**What makes a player want it.** Everyone has blown one. It is the softest thing on the meadow (white wool cells, a round face) and it is slowly coming apart in the wind, which is the kind of small sadness a player wants to look after. B46: its own `dot` eyes, small round ink dots with one shine pixel, the simplest eyes on the meadow for the softest face, and a contented cat mouth: a flower in the sun while its seeds sway and one drifts off. The Common rung on purpose: white, green and one yellow, no glow and no light.

**Hero block.** The `Parachute`, a seed that has just let go and floats beside the head (it bobs and drifts), unique in Verdant (Moop's spore is a lime ball; this is a white upturned cone, the stalk at its point and the open canopy at its top).

**Moving parts (four objects and the blink).** `floatR` (the loose seed bobs and drifts), `seeds` (the three on the puff sway as one), `leafR` and `leafL` (they rise and fall together); the plate blinks.

**Alien anatomy.** A flower that stands on its own leaves and sheds pieces of itself on purpose.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the puff and the calyx.

## Parts

```yaml
parts:
  # the seed-head: a soft white cube in woolly cells, the face on its front, a narrower woolly step on top so it reads as a round puff
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.25, 0], bevel: true, material: wool}
  - {name: Puff, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 2, 0], material: wool}
  # the yellow calyx under it (the lower step of the round), two green sepals curling down and out from its front corners past the head's
  # sides (Polish w1: tucked under the head they were hidden from every camera), the short green stem
  - {name: Collar, slot: Accessory, size: [1.5, 0.25, 1.25], at: [0, 0.5, 0]}
  - {name: Sepal, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [1, 0.3125, -0.625], rot: [0, 0, -20], mirror: x}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 0.1875, 0]}
  # two broad leaves rising out from the foot, 25 degrees up; they rise and fall on their roots
  - {name: Leaf, slot: BodyDark, size: [1.5, 0.125, 0.5], at: [0.8125, 0.375, 0], rot: [0, 0, 25], mirror: x, moves: leaf, pivot: [0.125, 0.25, 0]}
  # three seeds still standing on the puff, each an upturned cone: the stalk at the point, the open parachute at the top; they sway as one
  - {name: Seed, slot: Body, size: [0.5, 0.375, 0.5], at: [-0.5, 2.3125, 0.25], shape: cone6, rot: [180, 0, 0], moves: seeds, pivot: [0, 2.125, 0]}
  - {name: Seed2, slot: Body, size: [0.5, 0.375, 0.5], at: [0.375, 2.3125, -0.375], shape: cone6, rot: [180, 0, 0], moves: seeds, pivot: [0, 2.125, 0]}
  - {name: Seed3, slot: Body, size: [0.5, 0.25, 0.5], at: [0.25, 2.25, 0.5], shape: cone6, rot: [180, 0, 0], moves: seeds, pivot: [0, 2.125, 0]}
  # the hero: a seed that has just let go, floating beside the head
  - {name: Parachute, slot: Body, size: [0.75, 0.5, 0.75], at: [1.125, 2.25, -0.5], shape: cone6, rot: [180, 0, 0], moves: float, pivot: [1.125, 2.25, -0.5]}
```

## Face

The seed-head's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows (the wool on top, plain cells below); the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `dot`, a Common design, a round ink dot with one shine pixel, at 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, three frames). A contented `cat` mouth and blush cheeks. Round one wore `sleepy`: its flat lid over a white face read as unimpressed, not dozy. In World 1 only Dandel wears `dot`.

```yaml
eyes:
  key: dot
  mouth: cat
  cheeks: blush
  plate: [1.75, 0.875]
  at: [0, 1.125]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the loose seed bobs and drifts in a slow circle, the three seeds on the puff sway in the wind, the leaves rise and fall together like slow breathing, the puff breathes, the face blinks slowly. Four objects and the blink; no flourish (that starts at Rare).

```yaml
rig:
  clips:
    float: [{kind: bob, amp: 0.15, period: 2.8}, {kind: orbit, amp: 0.08, period: 5.6}]
    seeds: [{kind: sway, amp: 6, period: 2.2, axis: z}]
    leaf: [{kind: flap, amp: 6, period: 3, axis: z}]
    root: [{kind: squash, amp: 0.04, period: 3.2}]
    face: [{kind: blink, period: 5.2}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Puffpuff.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Puffpuff.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Puffpuff_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Puffpuff_idle.png]]

The concept sheet, drawn from the parts table above: [[Puffpuff_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Puffpuff_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (57 islands). Materials: wool on the seed-head and its top step (shag blobs, a yellow fleck in thirty), skin elsewhere; the seeds are plain white cones.

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "still a cube underneath"). The puff is a voxel round now: a woolly step 1.5 x 1.25 on top of the head and the yellow calyx widened to the same under it, so the outline steps in above and below; the seeds are upturned cones (cone6 turned over, 10 triangles each): three standing on the puff at different heights and the floating hero, so a few seeds stand out of the round instead of one stalk. Still 10 blocks and 2.5 studs (the cap of the Common band). Status review.

- 2026-10-19, World 1 roster worker, three rounds. Round 1: the seed stalks and the floating parachute were an eighth of a stud thick and did not read, and the leaves at 20 degrees sat at 0.70 against Twiglo. Round 2: the leaves 1.5 studs long rising 25 degrees from the foot, the stem a quarter taller so there is air under the head. Round 3: the seed stalks a quarter thick and the canopies 0.75 across, so the standing seed and the one floating off read as parachutes. Wanted for: the softest thing on the meadow, slowly coming apart. Still cheap: the wool's yellow flecks read as confetti more than seeds (the lit sprig of the motif is the accent); the puff is a cube. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, two rounds. In the band already (2.5 studs). Round 1: the library's `sleepy` read as unimpressed on the white face (a flat lid over a white field is a frown, not a doze); round 2 `dot`, round ink dots with one shine, and a `cat` mouth: the softest face on the meadow. Two green sepals under the calyx's front corners (12 blocks, the Common cap; the hind pair went to stay in the band), four moving objects and the blink: the loose seed bobs and drifts, the three seeds on the puff sway as one, the two leaves rise and fall, the puff breathes. Overlap 0.993 to 0.998, 224 triangles; worst silhouette pair 0.666 (Syrinx). Wanted for: a dandelion clock coming apart in the wind, with a face you want to keep. Still weak: the sepals hide under the head's overhang from the three-quarter view, and the seed cones read as paper cups up close. Status review.
- 2026-10-21, Polish w1, one round. The two sepals were tucked under the head's front corners where no camera saw them: each is now three quarters of a stud long, curling down and out 20 degrees from the calyx's front corners past the head's sides. 12 blocks (the Common cap). Overlap 0.993 to 0.998. Honest read: visible now, and the calyx has a shape from the front; in the same green as the leaves they read as part of the rosette more than as sepals, and from straight ahead each sepal and the leaf above it open in a sideways V (reflexed bracts, as a dandelion's are). Status review.
