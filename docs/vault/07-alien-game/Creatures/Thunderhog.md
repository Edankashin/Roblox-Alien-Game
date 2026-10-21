---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Thunderhog
name: Voltus
world: 1
tier: Epic
status: review
element: Lightning
height: 3.375
blocks: 58
tris: 834
bevel_width: 0.125
bevel_segments: 2
palette: ["#8B5CF6", "#2E1F66", "#D4C6FF", "#FFC233", "#FFF27A", "#160F2E"]
roles: [body, second, accent, trim, glow, ink]
hero: Crest
arcs: ["Crest>AntennaTipR", "Crest>AntennaTipL", "Crest>TailTip"]
vfx: "kept on the body (Epic), five layers in Effects.luau: a storm-yellow arc flickers across its back between the quill rows (BackL to BackR, eight segments), sparks leave the back at 5 a second, a violet light, a yellow catchlight sparkles in its star eyes every 4.5 s, and the signature: every 6 s and on the flourish the quills discharge a crackle of twelve sparks. The flourish (every 8 s) is that discharge: a hop, the bolt popping, the lightning rods and the tail whipping, a squash on landing"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Thunderhog_sheet.svg]]"
render: "[[Thunderhog_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.998, 0.998, 0.997]
vfx_render: "[[Thunderhog_vfx_cells.jpg]]"
cells_render: "[[Thunderhog_tq_cells.jpg]]"
idle_render: "[[Thunderhog_idle.png]]"
---
# Thunderhog (Voltus), Epic, World 1 Verdant

A storm hedgehog on six stubby splayed legs (an alien hexapod), 3.375 studs to the tip of its bolt (B45: it was 3.875; a long low hog, its height is all crest): each foot a dark block with two lavender toes, and two lightning-rod antennae leaning wide off the head's corners with lit bulbs, where a hedgehog has ears. One lightning bolt stands on its back, now drawn in ten eighth-stud rows: a zigzag seen from the front with a wide crossbar, a forward lean seen from the side, gold below and lit in its top four rows. Its long body is banded like a hedgehog's: a dark quill coat over the top with dark cone quills either side of the bolt, violet flanks carrying a stepped gold bolt, a lavender belly plate underneath, and a gold collar behind the head with two lavender rivets; a lit bolt for a tail, and a spark that circles the crest. Concept row: "hedgehog, lightning quills". Element and effect: [[Roster-Redesign]] section 2 (Lightning: arcs, sparks off the tips, a violet light). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** At a Rare's height it wears a crown no Rare has: a ten-row bolt lit at its top, two lit lightning rods and a spark that circles them, with arcs jumping between. 57 blocks (the Rares carry 30 to 35); its own `starry` eyes, a lit yellow star in a violet two-tone iris with gold lashes, and an open, excited smile; six moving things; and a flourish every 8 s that reads across the meadow: it hops and discharges, the bolt popping and the rods whipping while the effects crackle. Charged, never fierce: the face under the storm is a delighted one.

**Hero block.** The `Crest`: a ten-row pixel lightning bolt cut flat like a sign, a quarter stud thick, its rows stepping sideways only (a slant down, a wide jog back, a second slant to a point), so it is a zigzag from the front and the three-quarter view, solid gold below and lit in its top two rows. Polish w1: the earlier rows stepped forward as well, and from the three-quarter view their plates stacked into a lit cluster. It is one moving part (it pulses and pops); the arcs start at its top cell, `Crest`.

**Moving parts (five objects and the blink).** `crest` (the whole bolt: it pulses and sways), `antennaR` and `antennaL` (rod and bulb: they tilt), `tail` (the lit tail bolt: it wags), `spark` (a lit mote circling the crest); the face plate blinks and glints.

**Alien anatomy.** Six legs, and antennae that are lightning rods: the arcs run from the crest tip to the two antenna bulbs and the tail tip.

**World motif (Verdant).** The moss cell, here as the eighth-stud steps of the crest and the quarter-stud steps of the flank bolt, and the eighth-stud toes.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.75, 1.75], at: [0, 1.375, -0.75], bevel: true}
  - {name: Torso, slot: Body, size: [1.75, 1.5, 2.5], at: [0, 1.25, 1.125], bevel: true}
  # six legs (the alien hexapod) splayed out under the body's edges, each with two lavender toe cells in front
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.875, 0.25, -0.875], mirror: x}
  - {name: MidLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.875, 0.25, 0.75], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.875, 0.25, 1.875], mirror: x}
  - {name: Toe, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.6875, 0.0625, -1.1875], mirror: x}
  - {name: Toe2, slot: Accessory, size: [0.125, 0.125, 0.125], at: [1.0625, 0.0625, -1.1875], mirror: x}
  - {name: MidToe, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.6875, 0.0625, 0.4375], mirror: x}
  - {name: MidToe2, slot: Accessory, size: [0.125, 0.125, 0.125], at: [1.0625, 0.0625, 0.4375], mirror: x}
  - {name: HindToe, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.6875, 0.0625, 1.5625], mirror: x}
  - {name: HindToe2, slot: Accessory, size: [0.125, 0.125, 0.125], at: [1.0625, 0.0625, 1.5625], mirror: x}
  # the torso in three bands: a dark quill coat over the top, violet flanks with the gold bolt, a lavender belly plate; a gold collar in
  # front with a lavender rivet on each side
  - {name: Collar, slot: Trim, size: [2, 1.75, 0.25], at: [0, 1.25, 0.375], material: metal}
  - {name: Rivet, slot: Accessory, size: [0.0625, 0.125, 0.125], at: [1.03125, 1.5, 0.375], mirror: x}
  - {name: Coat, slot: BodyDark, size: [2, 0.5, 2], at: [0, 1.875, 1.5]}
  - {name: Belly, slot: Accessory, size: [2, 0.5, 2], at: [0, 0.625, 1.5]}
  # the flank emblem: a three-row stepped bolt in gold between the coat and the belly
  - {name: Emblem, slot: Trim, size: [0.125, 0.25, 0.5], at: [0.9375, 1.5, 1.625], mirror: x}
  - {name: Emblem2, slot: Trim, size: [0.125, 0.25, 1], at: [0.9375, 1.25, 1.375], mirror: x}
  - {name: Emblem3, slot: Trim, size: [0.125, 0.25, 0.5], at: [0.9375, 1, 1.125], mirror: x}
  # the hero: one lightning bolt standing on the coat in ten eighth-stud rows, flat like a cut-out (a quarter stud thick, Polish w1) so
  # its zigzag reads from the front and the three-quarter view: a slant down to the left, a wide jog to the right, a second slant down
  # to a point; lit in its top two rows only, solid gold below (it pulses and pops); `Crest` is its top cell, where the arcs start
  - {name: Crest, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.125, 3.3125, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest2, slot: Glow, size: [0.375, 0.125, 0.25], at: [0, 3.1875, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest3, slot: Trim, size: [0.375, 0.125, 0.25], at: [-0.125, 3.0625, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest4, slot: Trim, size: [0.375, 0.125, 0.25], at: [-0.25, 2.9375, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest5, slot: Trim, size: [0.75, 0.125, 0.25], at: [-0.125, 2.8125, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest6, slot: Trim, size: [0.375, 0.125, 0.25], at: [0, 2.6875, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest7, slot: Trim, size: [0.375, 0.125, 0.25], at: [-0.125, 2.5625, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest8, slot: Trim, size: [0.375, 0.125, 0.25], at: [-0.25, 2.4375, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest9, slot: Trim, size: [0.25, 0.125, 0.25], at: [-0.375, 2.3125, 1], moves: crest, pivot: [0, 2.125, 1]}
  - {name: Crest10, slot: Trim, size: [0.125, 0.125, 0.25], at: [-0.4375, 2.1875, 1], moves: crest, pivot: [0, 2.125, 1]}
  # a lit spark circling the bolt
  - {name: Spark, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.625, 2.875, 0.875], shape: ico1, moves: spark, pivot: [0.625, 2.875, 0.875]}
  # hedgehog quills down both sides of the bolt, leaning out 20 degrees, kept short so the bolt stands over them
  - {name: Quill, slot: BodyDark, size: [0.375, 0.5, 0.375], at: [0.6875, 2.3125, 1], shape: cone6, rot: [0, 0, -20], mirror: x}
  - {name: Quill2, slot: BodyDark, size: [0.375, 0.5, 0.375], at: [0.6875, 2.3125, 1.625], shape: cone6, rot: [0, 0, -20], mirror: x}
  - {name: Quill3, slot: BodyDark, size: [0.375, 0.5, 0.375], at: [0.6875, 2.3125, 2.25], shape: cone6, rot: [0, 0, -20], mirror: x}
  # cheek quills: two dark spikes out of each side of the head, the hedgehog's ruff
  - {name: Cheek, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1.125, 1, -1], shape: cone6, rot: [0, 0, -70], mirror: x}
  - {name: Cheek2, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1.125, 1.5, -0.75], shape: cone6, rot: [0, 0, -70], mirror: x}
  # alien anatomy: two lightning-rod antennae instead of ears, lit bulbs on top; the arcs jump between them and the crest tip
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.875, 0.125], at: [1.0625, 2.65625, -0.75], rot: [0, 0, -25], mirror: x, moves: antenna, pivot: [0.875, 2.25, -0.75]}
  - {name: AntennaTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [1.3125, 3.1875, -0.75], shape: ico1, mirror: x, moves: antenna, pivot: [0.875, 2.25, -0.75]}
  - {name: Tail, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 1.625, 2.75], moves: tail, pivot: [0, 1.625, 2.5]}
  - {name: TailTip, slot: Glow, size: [0.25, 0.5, 0.25], at: [0, 2.125, 2.875], moves: tail, pivot: [0, 1.625, 2.5]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.75-stud front is 14 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `starry`, an Epic design, a lit storm-yellow star pupil in a two-tone iris (deep indigo over violet) with gold lashes, at 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, five frames). An open, delighted mouth and blush cheeks.

```yaml
eyes:
  key: starry
  colours: {iris: "#5B33C9", iris2: "#2E1F66", pupil: glow, lash: trim}
  mouth: open
  cheeks: blush
  plate: [1.75, 0.875]
  at: [0, 1.1875]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the bolt pulses and sways, the lightning rods tilt, the tail wags, a spark circles the bolt, the hog breathes, the face blinks and glints. Six moving things (five objects and the blink; an Epic needs five). The flourish, every 8 s: a discharge, a hop with the bolt popping, the rods and the tail whipping, and a squash on landing.

```yaml
rig:
  clips:
    crest: [{kind: pulse, amp: 0.05, period: 1.6}, {kind: sway, amp: 4, period: 3.2, axis: z}]
    antenna: [{kind: sway, amp: 8, period: 2.2, axis: z}, {kind: wag, amp: 6, period: 3.5, axis: x, phase: 0.3}]
    tail: [{kind: wag, amp: 16, period: 2.4, axis: y}]
    spark: [{kind: orbit, amp: 0.3, period: 2.6}, {kind: bob, amp: 0.1, period: 1.3}]
    root: [{kind: bob, amp: 0.04, period: 1.1}]
    face: [{kind: blink, period: 4.5}]
  flourish:
    every: 8
    length: 2
    moves:
      - {part: root, kind: hop, amp: 0.3, at: 0, for: 0.6}
      - {part: crest, kind: pop, amp: 0.15, at: 0.2, for: 0.8}
      - {part: antenna, kind: swish, amp: 18, axis: z, at: 0.3, for: 1}
      - {part: tail, kind: swish, amp: 25, axis: y, at: 0.4, for: 1}
      - {part: root, kind: squash, amp: 0.08, axis: y, at: 1.2, for: 0.8}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Thunderhog.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Thunderhog.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Thunderhog_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Thunderhog_vfx.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Thunderhog_idle.png]]

The concept sheet, drawn from the parts table above: [[Thunderhog_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Thunderhog_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Thunderhog_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 31 cells tall; one atlas of 1024 x 1024 at 8 texels a cell (277 islands). Materials: metal on the gold collar (rivet panels: an armoured collar), crystal on the crest's gold steps, skin elsewhere.

![[Thunderhog_tq_cells.jpg]]

![[Thunderhog_vfx_cells.jpg]]

## Reviews

- 2026-10-17, worker, three rounds. Round 1: three zigzag stacks read as a dark mohawk, and the gold bands merged with the flank emblem into one gold blob. Round 2: one stepped lightning bolt as the crest, lit in its top three rows, dark cone quills either side, the rear band made a dark stripe, two cheek quills a side. Round 3: the VFX preview (jagged arcs from the crest tip to two quill tips, sparks a third of a stud out, the violet light; colours read from Effects.luau). Overlap 0.995 to 0.997, 732 triangles. Wanted for: the first Verdant creature with a lit crown, readable as storm from across the meadow. Still cheap: the long violet torso is flat between the bands, the gold anklets read as sandals, and from straight ahead the crest is a thin post. Next: a lighter belly plate or groove pattern on the torso, toe caps instead of anklets, a second bolt edge so the crest reads from the front. Status review.
- 2026-10-17, loop 2 worker, three rounds. Round 1: the torso in bands (a dark quill coat, violet flanks with the gold bolt, a lavender belly plate, the gold collar), two lavender toe cells on each foot instead of the anklets, lightning-rod antennae with lit bulbs instead of the cone ears, and a crest whose rows step sideways as well as forward, so it is a bolt from the front too. Round 2: the arcs go from the crest tip to the antenna bulbs and the tail tip. Round 3: the preview's sparks are kept off the face. Overlap 0.996 to 0.998, 812 triangles, 52 blocks, 3.88 studs. Wanted for: a lit crown and two lit antennae with lightning between them, readable as storm from across the meadow. Still cheap: the top is busy (the bolt, six quills, two antennae and four cheek spikes compete), and the toes vanish at distance. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The banded torso reads as blocks of cells; the collar's rivets read only up close; the crest's diagonals catch the light in the preview. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, three rounds. Round 1: from 3.875 studs to 3.375 by redrawing the bolt in ten eighth-stud rows (it was seven quarter-stud rows) with a wide crossbar, the whole bolt one moving part, a spark circling it, lavender rivets on the collar; its own `starry` eyes, an open delighted mouth, blush cheeks. The shorter crown made it a box with a bump: 0.705 against Buzzik and 0.698 against Moop in the silhouette test. Round 2: the six legs splayed out under the body's edges and the lightning rods moved to the head's corners and leaned 25 degrees, so the box's top and bottom corners fill differently (0.647 and 0.640). Round 3: the star pupil was faint on a light violet iris (now a deeper violet under indigo), and the bolt hid behind the quills (quills shortened to half a stud, the bolt's rows widened). Five moving objects and the blink; a flourish every 8 s (a discharge: a hop, the bolt popping, the rods and tail whipping, a squash on landing). Overlap 0.996 to 0.998, 58 blocks. Wanted for: lit star eyes under a crown of lightning, a step up from the Rares at the same height. Still weak: from the three-quarter camera the bolt reads as a lit cluster more than a zigzag (the front view and the game's high camera show it); the head is still the plain cube of loop 1. Status review.
- 2026-10-21, Polish w1, two rounds. The bolt read as a lit cluster from the three-quarter view: its ten rows were plates a half stud deep stepping forward as well as sideways, so from that angle they stacked, and four lit rows washed it to a glow. Rebuilt as a flat cut-out a quarter stud thick, every row in one plane, stepping sideways only (a slant down to the left, a wide jog back to the right, a second slant down to a point), lit in its top two rows and solid gold (not the pale crystal) below; moved a quarter stud toward its left so the right lightning rod no longer crosses it. Same ten blocks, 58 in all. Overlap 0.997 to 0.998. Honest read: a gold zigzag bolt reads at once from the front and the three-quarter view; from straight side it is a thin gold post, as any flat sign is (the high game camera rarely sees it so). Status review.
