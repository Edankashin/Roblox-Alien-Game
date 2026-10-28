---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Zapfinch
name: Zirrit
world: 1
tier: Rare
status: review
element: Lightning
height: 3.46
blocks: 85
tris: 1230
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
overlap: [0.993, 0.994, 0.997, 0.993]
vfx_render: "[[Zapfinch_vfx_cells.jpg]]"
cells_render: "[[Zapfinch_tq_cells.jpg]]"
idle_render: "[[Zapfinch_idle.png]]"
bar_world: Verdant
bar_kit: 4
bar_pieces: [blossom_bud, moss_cells]
bar_stance: "a songbird mid-song: the head cocked to its right, both wings flicked up, the tail cocked high, a ring of lit bolts and sparks round it"
bar_satellites: 6
bar_orbit: bolts
---
# Zapfinch (Zirrit), Rare, World 1 Verdant

A round sky-blue finch with a gold beak, 3.5 studs to its crest tips (it was 3.25) (B45: a perky songbird, high in the band by its antennae, not its tier): a big head on a small body, rounded from blocks by a narrower step on its crown and a fluffed cheek proud of each side, a stepped gold beak (a broad upper step and a little hook under it), a cream belly carrying a stamped gold lightning bolt, two navy wings held low with sky-blue coverts at their roots, a three-feather navy tail fanned behind with cream tips, two thin legs on wide gold feet, and on its crown the crest that names it: two zigzag antennae in gold collars, each bent like a small bolt, with lit yellow balls on their tips, between which the static jumps. Concept row in `src/shared/data/Species.luau`: "bird, antenna crest". Element and effect: [[Roster-Redesign]] section 2 (Lightning; a spark jumps between the antenna tips). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It is a bird with a spark gap on its head: two lit balls that crackle at each other, so it is seen before it is heard. At the Uncommons' height it carries twice their blocks (33): zigzag antennae in gold collars, two-tone wings, cream tail tips, the stepped beak and the bolt, a stepped crown and fluffed cheeks; its own `bubble` eyes (a big glossy navy iris with a periwinkle arc, an arc of shine and a storm-yellow glint); six moving things; and a flourish every 7 s that reads across the meadow: it jolts into the air with its wings flared and its antennae whipping.

**Hero block.** The `Crest` pair: two zigzag antennae with lit tips, unique in Verdant (Voltus's are lightning rods beside a bolt; this is a spark gap on a songbird).

**Moving parts (five objects and the blink).** `wingR` and `wingL` (each with its covert: they flick), `crestR` and `crestL` (collar, both zig steps and the lit tip: they tilt and quiver), `tail` (the three feathers and their tips: it wags); the face plate blinks and glints. Rare pass w1: `arc` (a lit zigzag spark between the antenna tips: it flickers and pops) makes six objects and the blink; the wings carry lit glass tips.

**Alien anatomy.** A bird with antennae instead of a crest of feathers.

**World motif (Verdant).** The moss cell as the eighth-stud cells of the bolt glyph, the collars and the tail tips, and the quarter-stud steps of the beak.

## Character bar (B54)

BAR-W1 (resumed 2026-10-28), [[Decisions]] B54 to B56; the list below was written first and the build follows it. [[Blocky-Style]] section 10 (rule 8: mass clarity and value contrast), [[Character-References]] apply checklist, plan in `tools/blocky/bar_w1.py` (`zapfinch()`), pieces in `tools/blocky/kits.py` and the module.

- **Theme.** A songbird mid-song: a spark of the meadow with a bolt in its throat. Kept: name, anatomy (a bird with two zigzag antennae and a spark gap between them), the gold beak, the cream belly with its bolt, height 3.46.
- **Gains (visible parts).** (1) Six satellites on a wide low ring clear of the wings, all in one lit gold: three stepped lightning bolts and three held sparks (a gold square ring round a lit heart), each three quarters of a stud and more. (2) Verdant kit: cream moss pads with a lit tuft on its back behind the wings' roots, gold blossom buds on the crown's back corners (they turn with the head). (3) The stance below.
- **Stance (rest groups `head`, `wing`, `tail`).** The head cocked 10 degrees as if listening to its own note, both wings flicked up (30 degrees above level instead of 15 below), the tail cocked 35 degrees up: the outline is a V of wings and a cocked crown, not a box on stilts.
- **Face intent.** Its own `bubble` eyes kept: big glossy navy irises with a periwinkle arc and a storm-yellow glint that match the antenna tips, blush cheeks, the beak as the mouth. Curious and delighted, a bird mid-note; the cock of the head does the "listening" and the face is not changed.
- **Three values (rule 8).** Body sky blue; wings, collars and stems navy (a step darker); beak, feet, buds and satellites one lit gold (a step lighter, and not the body's); the cream belly and moss the quiet light. No backdrop (a Rare has none).
- **Must-nots.** No loose boxes in the ring (every satellite is a bolt or a ring of the same gold); nothing over the face; the buds never cross the antennas; no piece under a quarter stud added for its own sake; height stays in 2 to 3.5 studs.

## Parts

```yaml
parts:
  # two thin legs on wide feet
  - {name: Foot, slot: Trim, size: [0.5, 0.125, 0.625], at: [0.5, 0.0625, -0.1875], mirror: x, material: metal}
  - {name: Leg, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [0.5625, 0.3125, 0.0625], mirror: x}
  # the small body and the big head over it
  - {name: Body, slot: Body, size: [1.5, 1, 1.5], at: [0, 1, 0.25], bevel: true}
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -0.25], bevel: true, pose: head}
  # Polish w1: the head's round from blocks, a narrower step on its crown behind the antennae and a fluffed cheek proud of each side
  - {name: HeadTop, slot: Body, size: [1.5, 0.125, 1.25], at: [0, 2.5625, -0.25], pose: head}
  - {name: Cheek, slot: Body, size: [0.125, 0.75, 1], at: [1.0625, 1.5, -0.5], mirror: x, pose: head}
  # a stepped gold beak proud of the face where the mouth would be: a broad upper step and a little hook under its tip
  - {name: Beak, slot: Trim, size: [0.5, 0.25, 0.25], at: [0, 1.5, -1.125], material: metal, pose: head}
  - {name: BeakTip, slot: Trim, size: [0.25, 0.125, 0.25], at: [0, 1.4375, -1.375], material: metal, pose: head}
  # the cream belly plate under the head, with the stamped element glyph: a three-row gold bolt
  - {name: Belly, slot: Accessory, size: [1, 0.5, 0.125], at: [0, 0.875, -0.5625]}
  - {name: Bolt, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.1875, 1.0625, -0.6875], material: metal}
  - {name: Bolt2, slot: Trim, size: [0.5, 0.125, 0.125], at: [0, 0.9375, -0.6875], material: metal}
  - {name: Bolt3, slot: Trim, size: [0.375, 0.125, 0.125], at: [-0.1875, 0.8125, -0.6875], material: metal}
  # two wings held low at the sides, 15 degrees down, a sky-blue covert over each root (the pair that flicks)
  - {name: Wing, slot: BodyDark, size: [1, 0.125, 1], at: [1.25, 1.125, 0.25], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25], pose: wing}
  - {name: Covert, slot: Body, size: [0.5, 0.125, 0.75], at: [1, 1.25, 0.25], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25], pose: wing}
  # a tail of three feathers fanned behind, the outer pair turned out 20 degrees, cream tips (it wags)
  - {name: TailMid, slot: BodyDark, size: [0.5, 0.125, 0.75], at: [0, 1.1875, 1.375], moves: tail, pivot: [0, 1.1875, 1], pose: tail}
  - {name: TailMidTip, slot: Accessory, size: [0.5, 0.125, 0.25], at: [0, 1.1875, 1.875], moves: tail, pivot: [0, 1.1875, 1], pose: tail}
  - {name: TailSide, slot: BodyDark, size: [0.375, 0.125, 0.75], at: [0.4375, 1.1875, 1.3125], rot: [0, 20, 0], mirror: x, moves: tail, pivot: [0, 1.1875, 1], pose: tail}
  - {name: TailSideTip, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.625, 1.1875, 1.8125], rot: [0, 20, 0], mirror: x, moves: tail, pivot: [0, 1.1875, 1], pose: tail}
  # the hero: two zigzag antennae in gold collars, each bent like a small bolt, with lit balls on their tips (the pair that tilts)
  - {name: Collar, slot: Trim, size: [0.25, 0.125, 0.375], at: [0.375, 2.6875, -0.5625], mirror: x, moves: crest, pivot: [0.375, 2.625, -0.5625], material: metal, pose: head}
  - {name: Crest, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [0.375, 2.875, -0.5625], rot: [0, 0, -15], mirror: x, moves: crest, pivot: [0.375, 2.625, -0.5625], pose: head}
  - {name: Crest2, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.4375, 3.125, -0.5625], rot: [0, 0, 15], mirror: x, moves: crest, pivot: [0.375, 2.625, -0.5625], pose: head}
  - {name: CrestTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.4375, 3.3125, -0.5625], shape: ico1, mirror: x, moves: crest, pivot: [0.375, 2.625, -0.5625], pose: head}
  # Rare pass w1, the signature piece: a spark gap, a lit zigzag arc of storm-yellow glass cells crackling between the two antenna tips
  # (it flickers, jumps and pops on the flourish, `arc`)
  - {name: Arc0, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.1875, 3.3125, -0.5625], moves: arc, pivot: [0.418777, 3.375, -0.5625], material: crystal, pose: head}
  - {name: Arc1, slot: Glow, size: [0.125, 0.125, 0.125], at: [-0.0625, 3.4375, -0.5625], moves: arc, pivot: [0.418777, 3.375, -0.5625], material: crystal, pose: head}
  - {name: Arc2, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.0625, 3.3125, -0.5625], moves: arc, pivot: [0.418777, 3.375, -0.5625], material: crystal, pose: head}
  - {name: Arc3, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.1875, 3.4375, -0.5625], moves: arc, pivot: [0.418777, 3.375, -0.5625], material: crystal, pose: head}
  # Rare pass w1: electric wingtips, three lit glass feather cells along each wing's outer edge (they flick with the wing)
  - {name: WingTip0, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.8125, 1, -0.0625], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25], material: crystal, pose: wing}
  - {name: WingTip1, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.8125, 1, 0.25], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25], material: crystal, pose: wing}
  - {name: WingTip2, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.8125, 1, 0.5625], rot: [0, 0, -15], mirror: x, moves: wing, pivot: [0.75, 1.25, 0.25], material: crystal, pose: wing}
  # pilot bar: begin (tools/blocky/bar_w1.py writes this region: the Verdant kit, the satellite set, the trim and the backdrop)
  # the Verdant kit: cream moss pads with a lit tuft on its back behind the wings' roots
  - {name: Mossa, slot: Accessory, size: [0.5, 0.125, 0.5], at: [0.375, 1.5625, 0.75], mirror: x, material: moss}
  - {name: Mossb, slot: Accessory, size: [0.375, 0.125, 0.25], at: [0.4375, 1.6875, 0.75], mirror: x, material: moss}
  - {name: Mossc, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.3125, 1.8125, 0.6875], mirror: x, material: moss}
  # gold blossom buds on the crown's back corners (they turn with the cocked head)
  - {name: Buda, slot: BodyDark, size: [0.125, 0.25, 0.125], at: [0.8125, 2.625, -0.0625], mirror: x, pose: head, material: wood}
  - {name: Budb, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.8125, 2.8125, -0.0625], mirror: x, pose: head}
  - {name: Budc, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.8125, 2.9375, -0.0625], mirror: x, pose: head}
  # the satellite set (`bolts`, one wide ring clear of the wings, the front low): three stepped bolts and three held sparks, all gold with a lit heart
  - {name: Sat0a, slot: Glow, size: [0.375, 0.25, 0.25], at: [1.3125, 1.25, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat0b, slot: Trim, size: [0.375, 0.25, 0.25], at: [1.1875, 1, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat0c, slot: Trim, size: [0.625, 0.125, 0.25], at: [1.3125, 0.8125, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat0d, slot: Trim, size: [0.25, 0.125, 0.25], at: [1.375, 0.6875, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat0e, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.3125, 0.5625, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat1a, slot: Trim, size: [0.625, 0.125, 0.25], at: [2.4375, 2.0625, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat1b, slot: Trim, size: [0.625, 0.125, 0.25], at: [2.4375, 1.4375, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat1c, slot: Trim, size: [0.125, 0.5, 0.25], at: [2.0625, 1.75, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat1d, slot: Trim, size: [0.125, 0.5, 0.25], at: [2.6875, 1.75, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat1e, slot: Glow, size: [0.25, 0.25, 0.25], at: [2.375, 1.75, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat2a, slot: Glow, size: [0.375, 0.25, 0.25], at: [1.1875, 2.75, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat2b, slot: Trim, size: [0.375, 0.25, 0.25], at: [1.3125, 2.5, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat2c, slot: Trim, size: [0.625, 0.125, 0.25], at: [1.1875, 2.3125, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat2d, slot: Trim, size: [0.25, 0.125, 0.25], at: [1.125, 2.1875, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat2e, slot: Glow, size: [0.125, 0.125, 0.25], at: [1.1875, 2.0625, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat3a, slot: Trim, size: [0.625, 0.125, 0.25], at: [-1.3125, 2.5625, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat3b, slot: Trim, size: [0.625, 0.125, 0.25], at: [-1.3125, 1.9375, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat3c, slot: Trim, size: [0.125, 0.5, 0.25], at: [-0.9375, 2.25, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat3d, slot: Trim, size: [0.125, 0.5, 0.25], at: [-1.5625, 2.25, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat3e, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.25, 2.25, 2.375], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat4a, slot: Glow, size: [0.375, 0.25, 0.25], at: [-2.3125, 1.75, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat4b, slot: Trim, size: [0.375, 0.25, 0.25], at: [-2.4375, 1.5, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat4c, slot: Trim, size: [0.625, 0.125, 0.25], at: [-2.3125, 1.3125, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat4d, slot: Trim, size: [0.25, 0.125, 0.25], at: [-2.25, 1.1875, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat4e, slot: Glow, size: [0.125, 0.125, 0.25], at: [-2.3125, 1.0625, 0.25], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  - {name: Sat5a, slot: Trim, size: [0.625, 0.125, 0.25], at: [-1.1875, 1.0625, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat5b, slot: Trim, size: [0.625, 0.125, 0.25], at: [-1.1875, 0.4375, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat5c, slot: Trim, size: [0.125, 0.5, 0.25], at: [-1.5625, 0.75, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat5d, slot: Trim, size: [0.125, 0.5, 0.25], at: [-0.9375, 0.75, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: metal}
  - {name: Sat5e, slot: Glow, size: [0.25, 0.25, 0.25], at: [-1.25, 0.75, -1.875], moves: bolts, pivot: [0, 1.55, 0.25], material: crystal}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.5-stud front is 12 rows; the eyes and cheeks are on the face plate, and the gold beak block proud of it carries the mouth.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `bubble`, a Rare design, a big glossy navy iris (the wing colour) with a periwinkle arc low in it, an arc of shine and a storm-yellow glint (the antenna tips' glow), at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, five frames). No mouth on the plate (the beak is the mouth), blush cheeks. Polish w1: the gold iris of the B46 pass merged with the gold beak under it (one gold blob from the review angle), so the iris went dark; dark glossy eyes over a gold beak read as a songbird's.

```yaml
eyes:
  key: bubble
  colours: {iris: second, iris2: "#4A5FD0", glint: glow}
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
  rest:
    head: {rot: [0, 0, 10], pivot: [0, 1.0, -0.25], move: [0, -0.1, 0]}
    wing: {rot: [0, 0, 45], pivot: [0.75, 1.25, 0.25], mirror: true}
    tail: {rot: [-35, 0, 0], pivot: [0, 1.1875, 1]}
  clips:
    wing: [{kind: flap, amp: 15, period: 1.2, axis: z}]
    crest: [{kind: sway, amp: 8, period: 2.4, axis: z}, {kind: wag, amp: 6, period: 3, axis: x, phase: 0.4}]
    arc: [{kind: pulse, amp: 0.2, period: 0.5}, {kind: bob, amp: 0.04, period: 0.7, phase: 0.3}]
    tail: [{kind: wag, amp: 14, period: 2.6, axis: y}]
    root: [{kind: bob, amp: 0.05, period: 1.1}]
    bolts: [{kind: spin, amp: 360, period: 18, axis: y}, {kind: bob, amp: 0.05, period: 2.4}]
    face: [{kind: blink, period: 3.8}]
  flourish:
    every: 7
    length: 2.2
    moves:
      - {part: root, kind: hop, amp: 0.35, at: 0, for: 0.6}
      - {part: wing, kind: flare, amp: 35, axis: z, at: 0, for: 0.8}
      - {part: arc, kind: pop, amp: 0.5, at: 0.2, for: 0.5}
      - {part: root, kind: turn, amp: 360, axis: y, at: 0.3, for: 1.2}
      - {part: crest, kind: swish, amp: 20, axis: z, at: 0.5, for: 0.9}
      - {part: tail, kind: swish, amp: 25, axis: y, at: 0.6, for: 0.9}
      - {part: arc, kind: hop, amp: 0.15, at: 1.2, for: 0.4}
      - {part: root, kind: squash, amp: 0.1, axis: y, at: 1.6, for: 0.6}
```

## VFX hooks

Rare pass w1. Where `Effects.luau` and `Spectacle.luau` can hang this species' layers: the existing attach regions stay as they are; these are the new attach points the pass proposes (fractions of the alien's bounds as `Effects.luau` measures them: x and z from the centre, -0.5 to 0.5, the face toward -z; y from the feet, 0, to the top, 1), each on a named part of the GLB. Not wired in `Effects.luau` (another worker's file); listed in the day log for it.

| Attach point | Part (moving object) | x, y, z | What it is for | Nearest existing region |
|---|---|---|---|---|
| Arc | `Arc1` (arc) | -0.02, 0.98, -0.23 | the arc beam between the two crest tips, a spark burst on the flourish | Halo |

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
- 2026-10-21, Polish w1, two rounds. The gold `bubble` iris sat right over the gold beak and the two merged into one gold blob from the review angle: the iris is now navy (the wing colour) with a periwinkle arc and a storm-yellow glint, so the eyes are big, dark and glossy over a gold beak. The square head is rounded from blocks: a narrower crown step (the antennae and their collars rise an eighth onto it, 3.5 studs now) and a sky-blue cheek fluff proud of each side; round 1 tried the cheeks in cream and they read as headphones, so they stay body blue. 33 blocks (Rare 18 to 36). Overlap 0.994 to 0.998. Honest read: the head now reads as a rounded songbird's and the face reads at once (dark eyes, gold beak); it is still a big block of a head, which is the house style. Status review.
- 2026-10-21, Rare pass w1, the "1000x cooler" pass. Signature piece: a spark gap, a lit zigzag of four storm-yellow glass cells crackling between the two antenna tips (it flickers at 2 Hz and pops on the flourish), and three lit glass feather cells along each wing's outer edge. The flourish gained a full turn. 43 blocks, seven moving things. Honest read: the songbird now carries its own spark; the arc is small and pale yellow in the lit view and is the night shot's best feature. Status review.
