---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Zapfinch
name: Zirrit
world: 1
tier: Rare
status: review
element: Lightning
height: 3.375
blocks: 30
tris: 538
bevel_width: 0.1
bevel_segments: 2
palette: ["#4FA8E8", "#23386B", "#F3F0E2", "#F2C14E", "#FFEE55", "#101A33"]
roles: [body, second, accent, trim, glow, ink]
hero: Crest
arcs: ["CrestTipR>CrestTipL"]
vfx: "a soft light (Rare), three layers in Effects.luau: a pale blue static beam flickers over the crest (Top to Back, six segments), a soft blue light pulses at the crest, and two pale sparks pop off the crest every 1.2 s; the game's own idle flaps the wings 15 degrees. The flourish (every 7 s) is a jolt: a hop with the wings flared, the zigzag antennae whipping, the tail fanning and a squash on landing"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Zapfinch_sheet.svg]]"
render: "[[Zapfinch_tq_cells.jpg]]"
glb: ""
overlap: [0.991, 0.994, 0.997, 0.991]
vfx_render: "[[Zapfinch_vfx_cells.jpg]]"
cells_render: "[[Zapfinch_tq_cells.jpg]]"
idle_render: "[[Zapfinch_idle.png]]"
---
# Zapfinch (Zirrit), Rare, World 1 Verdant

A round sky-blue finch with a gold beak, 3.375 studs to its crest tips (it was 3.25) (B45: a perky songbird, high in the band by its antennae, not its tier): a big square head on a small body, a stepped gold beak (a broad upper step and a little hook under it), a cream belly carrying a stamped gold lightning bolt, two navy wings held low with sky-blue coverts at their roots, a three-feather navy tail fanned behind with cream tips, two thin legs on wide gold feet, and on its crown the crest that names it: two zigzag antennae in gold collars, each bent like a small bolt, with lit yellow balls on their tips, between which the static jumps. Concept row in `src/shared/data/Species.luau`: "bird, antenna crest". Element and effect: [[Roster-Redesign]] section 2 (Lightning; a spark jumps between the antenna tips). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It is a bird with a spark gap on its head: two lit balls that crackle at each other, so it is seen before it is heard. At the Uncommons' height it carries twice their blocks (30): zigzag antennae in gold collars, two-tone wings, cream tail tips, the stepped beak and the bolt; its own `bubble` eyes (a big glossy gold iris with an amber arc and an arc of shine, a white glint); six moving things; and a flourish every 7 s that reads across the meadow: it jolts into the air with its wings flared and its antennae whipping.

**Hero block.** The `Crest` pair: two zigzag antennae with lit tips, unique in Verdant (Voltus's are lightning rods beside a bolt; this is a spark gap on a songbird).

**Moving parts (five objects and the blink).** `wingR` and `wingL` (each with its covert: they flick), `crestR` and `crestL` (collar, both zig steps and the lit tip: they tilt and quiver), `tail` (the three feathers and their tips: it wags); the face plate blinks and glints.

**Alien anatomy.** A bird with antennae instead of a crest of feathers.

**World motif (Verdant).** The moss cell as the eighth-stud cells of the bolt glyph, the collars and the tail tips, and the quarter-stud steps of the beak.

## Parts

```yaml
parts:
  # two thin legs on wide feet
  - {name: Foot, slot: Trim, size: [0.5, 0.125, 0.625], at: [0.5, 0.0625, -0.1875], mirror: x, material: metal}
  - {name: Leg, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [0.5625, 0.3125, 0.0625], mirror: x}
  # the small body and the big head over it
  - {name: Body, slot: Body, size: [1.5, 1, 1.5], at: [0, 1, 0.25], bevel: true}
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -0.25], bevel: true}
  # a stepped gold beak proud of the face where the mouth would be: a broad upper step and a little hook under its tip
  - {name: Beak, slot: Trim, size: [0.5, 0.25, 0.25], at: [0, 1.5, -1.125], material: metal}
  - {name: BeakTip, slot: Trim, size: [0.25, 0.125, 0.25], at: [0, 1.4375, -1.375], material: metal}
  # the cream belly plate under the head, with the stamped element glyph: a three-row gold bolt
  - {name: Belly, slot: Accessory, size: [1, 0.5, 0.125], at: [0, 0.875, -0.5625]}
  - {name: Bolt, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.1875, 1.0625, -0.6875], material: metal}
  - {name: Bolt2, slot: Trim, size: [0.5, 0.125, 0.125], at: [0, 0.9375, -0.6875], material: metal}
  - {name: Bolt3, slot: Trim, size: [0.375, 0.125, 0.125], at: [-0.1875, 0.8125, -0.6875], material: metal}
  # two wings held low at the sides, 15 degrees down, a sky-blue covert over each root (the pair that flicks)
  - {name: Wing, slot: BodyDark, size: [1, 0.125, 1], at: [1.25, 1.125, 0.25], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25]}
  - {name: Covert, slot: Body, size: [0.5, 0.125, 0.75], at: [1, 1.25, 0.25], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25]}
  # a tail of three feathers fanned behind, the outer pair turned out 20 degrees, cream tips (it wags)
  - {name: TailMid, slot: BodyDark, size: [0.5, 0.125, 0.75], at: [0, 1.1875, 1.375], moves: tail, pivot: [0, 1.1875, 1]}
  - {name: TailMidTip, slot: Accessory, size: [0.5, 0.125, 0.25], at: [0, 1.1875, 1.875], moves: tail, pivot: [0, 1.1875, 1]}
  - {name: TailSide, slot: BodyDark, size: [0.375, 0.125, 0.75], at: [0.4375, 1.1875, 1.3125], rot: [0, 20, 0], mirror: x, moves: tail, pivot: [0, 1.1875, 1]}
  - {name: TailSideTip, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.625, 1.1875, 1.8125], rot: [0, 20, 0], mirror: x, moves: tail, pivot: [0, 1.1875, 1]}
  # the hero: two zigzag antennae in gold collars, each bent like a small bolt, with lit balls on their tips (the pair that tilts)
  - {name: Collar, slot: Trim, size: [0.25, 0.125, 0.375], at: [0.375, 2.5625, -0.5625], mirror: x, moves: crest, pivot: [0.375, 2.5, -0.5625], material: metal}
  - {name: Crest, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [0.375, 2.75, -0.5625], rot: [0, 0, -15], mirror: x, moves: crest, pivot: [0.375, 2.5, -0.5625]}
  - {name: Crest2, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.4375, 3, -0.5625], rot: [0, 0, 15], mirror: x, moves: crest, pivot: [0.375, 2.5, -0.5625]}
  - {name: CrestTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.4375, 3.1875, -0.5625], shape: ico1, mirror: x, moves: crest, pivot: [0.375, 2.5, -0.5625]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes and cheeks are on the face plate, and the gold beak block proud of it carries the mouth.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `bubble`, a Rare design, a big glossy gold iris with an amber arc low in it, an arc of shine and a white glint, at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, five frames). No mouth on the plate (the beak is the mouth), blush cheeks.

```yaml
eyes:
  key: bubble
  colours: {iris: "#FFC83A", iris2: "#E2741F", glint: "#FFFFFF"}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.75]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the wings flick, the antennae tilt and quiver, the tail wags, the bird bobs, the face blinks and glints. Six moving things (five objects and the blink; a Rare needs four). The flourish, every 7 s: a jolt, a hop with the wings flared, the antennae whipping, the tail fanning, a squash on landing.

```yaml
rig:
  clips:
    wing: [{kind: flap, amp: 15, period: 1.2, axis: z}]
    crest: [{kind: sway, amp: 8, period: 2.4, axis: z}, {kind: wag, amp: 6, period: 3, axis: x, phase: 0.4}]
    tail: [{kind: wag, amp: 14, period: 2.6, axis: y}]
    root: [{kind: bob, amp: 0.05, period: 1.1}]
    face: [{kind: blink, period: 3.8}]
  flourish:
    every: 7
    length: 1.8
    moves:
      - {part: root, kind: hop, amp: 0.35, at: 0, for: 0.6}
      - {part: wing, kind: flare, amp: 35, axis: z, at: 0, for: 0.8}
      - {part: crest, kind: swish, amp: 20, axis: z, at: 0.5, for: 0.9}
      - {part: tail, kind: swish, amp: 25, axis: y, at: 0.6, for: 0.9}
      - {part: root, kind: squash, amp: 0.1, axis: y, at: 1.2, for: 0.6}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Zapfinch.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Zapfinch.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Zapfinch_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Zapfinch_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Zapfinch_idle.png]]

The concept sheet, drawn from the parts table above: [[Zapfinch_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 26 cells tall. Materials: metal on the beak, the feet, the collars and the bolt glyph, skin elsewhere; the crest tips are glow cells.

## Reviews

- 2026-10-19, World 1 roster worker, one round. Built as drawn: the gold beak proud of the face, the lit crest tips, the bolt on the cream belly, the wings held low and the fan tail all read; the bolt's rows and the tail's middle feather moved onto the half grid. Wanted for: a bird with a spark gap on its head. Still cheap: from straight ahead the crest is two posts with balls; the Rare preview is a soft light and little else. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, two rounds. Round 1: 31 blocks: the crest as two zig steps in gold collars, sky-blue coverts on the navy wings, cream tips on the three tail feathers, a stepped beak with a hook, a navy forelock; its own `bubble` eyes in gold with an amber arc and a white glint, blush cheeks, the beak as the mouth. The forelock read as a stray dark box beside an antenna and the zigzag was too short to read. Round 2: the forelock gone, the upper zig step raised so the tips stand at 3.375 studs. Five moving objects and the blink (wings flick, antennae tilt and quiver, the tail wags); a flourish every 7 s (a jolt: a hop with the wings flared, the antennae whipping, the tail fanning, a squash on landing). Overlap 0.991 to 0.997, 30 blocks. Wanted for: a songbird with a spark gap on its head and eyes like two little suns. Still weak: the gold iris sits close in hue to the gold beak, so the face is one warm patch at distance; the cube head is still the boxiest bird in any world. Status review.
