---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Radish
name: Raddis
world: 1
tier: Cosmic
status: review
element: Sun
height: 3.44
blocks: 155
tris: 1806
bevel_width: 0.03125
bevel_segments: 2
palette: ["#D7265C", "#FFF0D9", "#2CC5B2", "#FFB21E", "#FFE36B", "#2A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#FFE36B", "#FF9F45", "#FFF8DC"]
hero: RingT
vfx: "to the sky: the rays, the orb, the motes, the forehead gem, the pendant and the wing tips glow and step through gold, amber and white every 2 s; the halo turns once in 12 s; gold motes circle the shoulders; a ground ring of light; a sunlight trail while it hovers; the flourish (every 12 s) is a hop and a full turn with the wings flared, the disk popping and the orb leaping, the moment Effects.luau can hang a flare and a column of light on (World.RigAnimator.OnFlourish)"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Radish_sheet.svg]]"
render: "[[Radish_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.993, 0.991, 0.994]
vfx_render: "[[Radish_vfx_cells.jpg]]"
cells_render: "[[Radish_tq_cells.jpg]]"
idle_render: "[[Radish_idle.png]]"
---
# Radish (Raddis), Cosmic, World 1 Verdant

A small radish that hovers, 3.44 studs tall (B45: every alien stands 2 to 3.5 studs; it was 13.96): a deep radish-red head 2 studs wide with the face plate low on it, a crown step over it and a bulb under it ringed by a girdle of gold and turquoise cells with cream lenticel dashes below, then a root that tapers in five steps from red to cream to a curled tip with two root hairs. A centre leaf, a pair of fronds and four drooping blades fan out of the back of the crown. The face wears the pharaoh's brow in eighth-stud cells: a band of gold and turquoise over the eyes with a lit gem in a gold frame, striped lappets down both sides and three gold studs on the crown's front edge; cream lenticel dashes mark the radish skin. A broad collar of gold and turquoise cells stands out under the chin, narrowing to a lit pendant that swings. Behind it turns a ring of gold cells, wide enough to frame the head from the front, with eight lit rays and a pair of feathered wings, the winged sun of Ra; a sun orb floats over its crown and two motes circle its shoulders. Concept row: "radiant radish, sun disk; echo of Ra". Element: Sun (`Effects.luau`; [[Roster-Redesign]] section 2). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** Not its size any more: it stands a little under the avatar's shoulder like everyone else. What sets it apart from Moop is everything else: 155 blocks to Moop's 10, most of them eighth-stud cells of gold, turquoise and light (Moop has none); its own solar eyes, a sun in each eye whose pinwheel rays swirl round a white-hot core over a lit turquoise rim, with star cheeks (Moop has ink beans); twelve moving things to Moop's three (the turning disk, two beating wings, the bobbing orb, two circling motes, a nodding leaf, two swaying fronds, the pulsing gem, the swinging pendant, and the blink); and every 12 seconds a flourish: a hop and a full turn with the wings flared, the disk popping and the orb leaping. Rarer means more exclusive and cuter, never fiercer: the face is a soft smile and starry cheeks under sun eyes.

**Hero block.** The sun disk (`RingT` and the ring cells and rays round it): one moving part, the `halo`, that the game turns once in 12 s, unique in Verdant.

**Moving parts (eleven objects and the blink).** `halo` (the ring and its rays), `wingR` and `wingL` (they beat and sway), `orb` (it bobs and spins), `moteR` and `moteL` (they circle), `leaf` (it nods), `frondR` and `frondL` (they sway), `gem` (it pulses), `pendant` (it swings); the face plate blinks, glints and swirls.

**Alien anatomy.** A root that hovers instead of standing, and a sun that turns behind it on nothing.

**World motif (Verdant).** The moss cell, here as the eighth-stud cells of the brow, the lappets, the collar and the ring.

## Parts

```yaml
parts:
  # the radish: a bevelled head with the face plate, a bulb under it with a girdle of cells, a crown step over it, five root steps from red to cream to a curl
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 2, 0], bevel: true}
  - {name: Bulb, slot: Body, size: [1.5, 0.5, 1.5], at: [0, 1, 0], bevel: true}
  # the bulb's girdle: a ring of gold and turquoise cells round its upper step (the collar covers the front), cream lenticel dashes under it
  - {name: Girdle, slot: Trim, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.125, -0.5], mirror: x, material: metal}
  - {name: Girdle1, slot: Accessory, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.125, -0.25], mirror: x}
  - {name: Girdle2, slot: Trim, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.125, 0], mirror: x, material: metal}
  - {name: Girdle3, slot: Accessory, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.125, 0.25], mirror: x}
  - {name: Girdle4, slot: Trim, size: [0.0625, 0.125, 0.25], at: [0.78125, 1.125, 0.5], mirror: x, material: metal}
  - {name: GirdleBack, slot: Trim, size: [0.25, 0.125, 0.0625], at: [-0.5, 1.125, 0.78125], material: metal}
  - {name: GirdleBack1, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [-0.25, 1.125, 0.78125]}
  - {name: GirdleBack2, slot: Trim, size: [0.25, 0.125, 0.0625], at: [0, 1.125, 0.78125], material: metal}
  - {name: GirdleBack3, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0.25, 1.125, 0.78125]}
  - {name: GirdleBack4, slot: Trim, size: [0.25, 0.125, 0.0625], at: [0.5, 1.125, 0.78125], material: metal}
  - {name: BulbDash, slot: BodyDark, size: [0.0625, 0.0625, 0.25], at: [0.78125, 0.90625, 0.125], mirror: x}
  - {name: BulbDash2, slot: BodyDark, size: [0.0625, 0.0625, 0.25], at: [0.78125, 0.84375, -0.375], mirror: x}
  - {name: Crown, slot: Body, size: [1.5, 0.125, 1.25], at: [0, 2.8125, 0.0625]}
  - {name: Root, slot: Body, size: [0.875, 0.125, 0.875], at: [0, 0.6875, 0]}
  - {name: Root2, slot: BodyDark, size: [0.625, 0.125, 0.625], at: [0, 0.5625, 0]}
  - {name: Root3, slot: BodyDark, size: [0.375, 0.125, 0.375], at: [0, 0.4375, 0], material: wood}
  - {name: RootTip, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [0, 0.3125, 0], material: wood}
  - {name: RootTail, slot: BodyDark, size: [0.125, 0.1875, 0.125], at: [0, 0.15625, 0]}
  - {name: RootCurl, slot: BodyDark, size: [0.1875, 0.0625, 0.125], at: [0.03125, 0.03125, 0]}
  - {name: RootHair, slot: BodyDark, size: [0.0625, 0.25, 0.0625], at: [0.40625, 0.5, 0], rot: [0, 0, 20], mirror: x}
  # radish skin: cream lenticel dashes on the head's sides
  - {name: Dash, slot: BodyDark, size: [0.0625, 0.0625, 0.25], at: [1.03125, 2.46875, -0.25], mirror: x}
  - {name: Dash2, slot: BodyDark, size: [0.0625, 0.0625, 0.375], at: [1.03125, 2.09375, 0.25], mirror: x}
  - {name: Dash3, slot: BodyDark, size: [0.0625, 0.0625, 0.25], at: [1.03125, 1.59375, -0.125], mirror: x}
  # the pharaoh's brow: a band of gold and turquoise cells over the face plate, a lit gem in a gold frame, striped lappets down the sides
  - {name: Band, slot: Trim, size: [0.25, 0.125, 0.0625], at: [0, 2.5625, -0.90625], material: metal}
  - {name: Band1, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0.25, 2.5625, -0.90625], mirror: x}
  - {name: Band2, slot: Trim, size: [0.25, 0.125, 0.0625], at: [0.5, 2.5625, -0.90625], mirror: x}
  - {name: Band3, slot: Accessory, size: [0.25, 0.125, 0.0625], at: [0.75, 2.5625, -0.90625], mirror: x}
  - {name: GemFrame, slot: Trim, size: [0.375, 0.125, 0.0625], at: [0, 2.6875, -0.90625], material: metal}
  - {name: Gem, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0, 2.6875, -0.96875], moves: gem, pivot: [0, 2.6875, -0.96875]}
  - {name: Lappet, slot: Trim, size: [0.125, 0.25, 0.0625], at: [0.9375, 2.375, -0.90625], mirror: x}
  - {name: Lappet2, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.9375, 2.125, -0.90625], mirror: x}
  - {name: Lappet3, slot: Trim, size: [0.125, 0.25, 0.0625], at: [0.9375, 1.875, -0.90625], mirror: x}
  - {name: Lappet4, slot: Accessory, size: [0.125, 0.25, 0.0625], at: [0.9375, 1.625, -0.90625], mirror: x}
  # the crown's gold studs along its front edge
  - {name: Stud, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0, 2.90625, -0.4375], material: metal}
  - {name: Stud2, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.375, 2.90625, -0.4375], mirror: x, material: metal}
  - {name: Stud3, slot: Trim, size: [0.125, 0.0625, 0.125], at: [0.6875, 2.90625, -0.4375], mirror: x, material: metal}
  # the broad collar: three rows of gold and turquoise cells standing out over the bulb under the chin, narrowing to a lit pendant that swings
  - {name: CollarA, slot: Trim, size: [0.25, 0.125, 0.1875], at: [0, 1.1875, -0.78125], material: metal}
  - {name: CollarA1, slot: Accessory, size: [0.25, 0.125, 0.1875], at: [0.25, 1.1875, -0.78125], mirror: x}
  - {name: CollarA2, slot: Trim, size: [0.25, 0.125, 0.1875], at: [0.5, 1.1875, -0.78125], mirror: x}
  - {name: CollarB, slot: Accessory, size: [0.25, 0.125, 0.1875], at: [0, 1.0625, -0.78125]}
  - {name: CollarB1, slot: Trim, size: [0.25, 0.125, 0.1875], at: [0.25, 1.0625, -0.78125], mirror: x}
  - {name: CollarC, slot: Trim, size: [0.25, 0.125, 0.1875], at: [0, 0.9375, -0.78125], material: metal}
  - {name: Pendant, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 0.8125, -0.8125], moves: pendant, pivot: [0, 0.875, -0.8125]}
  # the radish greens: a centre leaf that nods, a pair of fronds that sway, drooping outer leaves and back leaves (all broad turquoise blades)
  - {name: LeafStem, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0, 2.9375, 0.4375], moves: leaf, pivot: [0, 2.875, 0.4375]}
  - {name: Leaf, slot: Accessory, size: [0.375, 0.25, 0.125], at: [0, 3.125, 0.4375], moves: leaf, pivot: [0, 2.875, 0.4375]}
  - {name: Leaf2, slot: Accessory, size: [0.25, 0.125, 0.125], at: [0, 3.3125, 0.4375], moves: leaf, pivot: [0, 2.875, 0.4375]}
  - {name: LeafTip, slot: Accessory, size: [0.125, 0.0625, 0.125], at: [0, 3.40625, 0.4375], moves: leaf, pivot: [0, 2.875, 0.4375]}
  - {name: FrondStem, slot: Accessory, size: [0.125, 0.125, 0.125], at: [0.28125, 2.9375, 0.3125], rot: [0, 0, -20], mirror: x, moves: frond, pivot: [0.25, 2.875, 0.3125]}
  - {name: Frond, slot: Accessory, size: [0.3125, 0.25, 0.125], at: [0.375, 3.125, 0.3125], rot: [0, 0, -20], mirror: x, moves: frond, pivot: [0.25, 2.875, 0.3125]}
  - {name: FrondTip, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [0.4375, 3.3125, 0.3125], rot: [0, 0, -20], mirror: x, moves: frond, pivot: [0.25, 2.875, 0.3125]}
  - {name: OuterLeaf, slot: Accessory, size: [0.375, 0.1875, 0.125], at: [0.65625, 2.90625, 0.1875], rot: [0, 0, -65], mirror: x}
  - {name: OuterLeaf2, slot: Accessory, size: [0.25, 0.1875, 0.125], at: [0.8125, 3.0625, 0.1875], rot: [0, 0, -65], mirror: x}
  - {name: BackLeaf, slot: Accessory, size: [0.3125, 0.25, 0.125], at: [0.21875, 3, 0.5625], rot: [15, 0, -15], mirror: x}
  - {name: BackLeaf2, slot: Accessory, size: [0.1875, 0.125, 0.125], at: [0.28125, 3.1875, 0.59375], rot: [15, 0, -15], mirror: x}
  # the floating accessories: a sun orb over the crown's front, two motes circling at the shoulders
  - {name: Orb, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 3.125, -0.25], shape: ico1, moves: orb, pivot: [0, 3.125, -0.25]}
  - {name: Mote, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 2.6875, -0.375], mirror: x, shape: ico1, moves: mote, pivot: [1.3125, 2.6875, -0.375]}
  # the sun disk: a ring of eighth-stud cells behind the head with eight stepped rays, turning on its centre (the hero, `RingT`)
  - {name: RingB9, slot: Trim, size: [1, 0.125, 0.125], at: [0, 0.6875, 1], moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB8, slot: Trim, size: [1.5, 0.125, 0.125], at: [0, 0.8125, 1], moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB7, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.6875, 0.9375, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB6, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.8125, 1.0625, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB5, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.9375, 1.1875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB4, slot: Trim, size: [0.25, 0.125, 0.125], at: [1, 1.3125, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB3, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 1.4375, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB2, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 1.5625, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB1, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 1.6875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingB0, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 1.8125, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT0, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 1.9375, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT1, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 2.0625, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT2, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 2.1875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT3, slot: Trim, size: [0.25, 0.125, 0.125], at: [1.125, 2.3125, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT4, slot: Trim, size: [0.25, 0.125, 0.125], at: [1, 2.4375, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT5, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.9375, 2.5625, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT6, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.8125, 2.6875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT7, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.6875, 2.8125, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT, slot: Trim, size: [1.5, 0.125, 0.125], at: [0, 2.9375, 1], moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: RingT9, slot: Trim, size: [1, 0.125, 0.125], at: [0, 3.0625, 1], moves: halo, pivot: [0, 1.875, 1], material: metal}
  - {name: Ray0, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 3.25, 1], moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray0b, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 3.375, 1], moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray180, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 0.5, 1], moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray180b, slot: Glow, size: [0.125, 0.125, 0.125], at: [0, 0.375, 1], moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray270, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.375, 1.875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray270b, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.5, 1.875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray315, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.0625, 2.9375, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray315b, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.1875, 3.0625, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray225, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.0625, 0.8125, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1]}
  - {name: Ray225b, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.1875, 0.6875, 1], mirror: x, moves: halo, pivot: [0, 1.875, 1]}
  # the wings of the winged sun: four feather rows behind the disk, lit tips; each wing turns on its root to beat
  - {name: Wing, slot: Trim, size: [1.125, 0.125, 0.0625], at: [1.5625, 2.4375, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
  - {name: Wing2, slot: Accessory, size: [1, 0.125, 0.0625], at: [1.5, 2.3125, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
  - {name: Wing3, slot: Body, size: [0.75, 0.125, 0.0625], at: [1.375, 2.1875, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
  - {name: Wing4, slot: Accessory, size: [0.5, 0.125, 0.0625], at: [1.25, 2.0625, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
  - {name: WingTip, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.1875, 2.4375, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
  - {name: WingTip2, slot: Glow, size: [0.125, 0.125, 0.0625], at: [2.0625, 2.3125, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
  - {name: WingTip3, slot: Glow, size: [0.125, 0.125, 0.0625], at: [1.8125, 2.1875, 1.15625], mirror: x, moves: wing, pivot: [1, 2.25, 1.15625]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 32 columns across the 2-stud head, so the cell is 0.0625 studs (16 a stud) and the 1.5-stud front is 24 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 32
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `solar`, a Cosmic design, a sun in each eye whose pinwheel rays swirl round a white-hot core over a lit turquoise rim, at 32 pixels a stud on a 1.75 x 0.875 stud plate (56 x 28 pixels, 13 frames: open, half, closed, two glints, eight swirl frames). A small smile and star cheeks.

```yaml
eyes:
  key: solar
  colours: {deep: "#C2410C", mid: trim, bright: glow, rim: accent, sparkle: "#FFFFFF"}
  mouth: smile
  cheeks: stars
  plate: [1.75, 0.875]
  at: [0, 1.96875]
  spread: 0.4375
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`, World.RigAnimator plays them). A key names a moving object, or the base name of a mirrored pair (both twins, the left mirrored); `root` is the whole body about its feet, `face` the plate.

```yaml
rig:
  clips:
    halo: [{kind: spin, amp: 360, period: 12, axis: z}]
    wing: [{kind: flap, amp: 14, period: 2.8, axis: z}, {kind: sway, amp: 6, period: 5.6, axis: y, phase: 0.25}]
    orb: [{kind: bob, amp: 0.12, period: 2.4}, {kind: spin, amp: 360, period: 6, axis: y}]
    mote: [{kind: orbit, amp: 0.2, period: 3.6}, {kind: bob, amp: 0.08, period: 1.8, phase: 0.5}]
    leaf: [{kind: sway, amp: 8, period: 3.2, axis: x}]
    frond: [{kind: sway, amp: 10, period: 2.6, axis: z, phase: 0.3}]
    gem: [{kind: pulse, amp: 0.2, period: 2}]
    pendant: [{kind: sway, amp: 12, period: 1.9, axis: x}]
    root: [{kind: bob, amp: 0.08, period: 3}]
    face: [{kind: blink, period: 4.6}]
  flourish:
    every: 12
    length: 3.2
    moves:
      - {part: root, kind: hop, amp: 0.4, at: 0, for: 0.9}
      - {part: root, kind: turn, amp: 360, at: 0.15, for: 1.5}
      - {part: wing, kind: flare, amp: 30, at: 0.3, for: 1.4}
      - {part: halo, kind: pop, amp: 0.18, at: 1.4, for: 1}
      - {part: orb, kind: hop, amp: 0.35, at: 1.8, for: 1}
      - {part: frond, kind: swish, amp: 18, at: 2, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Radish.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Radish.md --out <scratch> --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with cells (Blender, Cycles):

![[Radish_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Radish_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Radish_idle.png]]

The concept sheet, drawn from the parts table above: [[Radish_sheet.svg]] and [[Radish_sheet.png]]. The build's four orthographic views against the sheet's masks score the `overlap` in the frontmatter (the silhouette check). Before and after B45 and B46, beside Moop: `media/studio/2026-10-21/pilots_v1.jpg`.

## Reviews

- 2026-10-17, worker, three rounds. Round 1: it read as a red box with wings (a short root, leaves like little antlers, an opaque white light column). Round 2: a four-step root taper to a thin tail with root hairs, three tall leaf blades, the upper body raised half a stud (13.75 studs, head 40 percent). Round 3: the preview's turning disk lit, a corona light, a wider translucent column. Overlap 0.996 to 0.997, 1,424 triangles, four moving objects. Wanted for: 2.8 avatars tall and 16.5 studs across the wings, a turning winged sun, a mount. Still cheap: the head front is a big flat red plane above the face, the collar hides under the head's overhang from above, and the wing rows read as flags from the side. Next: a stepped brow band or headdress edge across the top of the face, feather tips stepped at the wing ends, and the face at 32 cells for close-ups. Status review.
- 2026-10-17, loop 2 worker, three rounds. Round 1: the brow band, the gem and the striped lappets frame the face and break up the red plane; the collar stands out past the chin so it shows from above; the striped head sides (they read as lantern ribs) are gone. Round 2: the leaves read as celery sticks (a cream midrib split each one), and the box still read as a lantern; the root was shortened so the leaves could grow. Round 3: a 6-stud head between a crown step and a bulb, a five-step root from red to cream to a curled tip, seven broad leaves with the outer pair drooping; the preview drops a spark that sat on its cheek. Overlap 0.995 to 0.997, 1,892 triangles, 141 blocks, 13.96 studs. Wanted for: nearly three avatars of radish behind a turning winged sun, a mount. Still cheap: from the side the head is still a tall box; the cream dashes are faint; 16 face cells over 6 studs are big pixels in a close-up. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). At the face cell (0.375 studs) the 6-stud head is 16 cells across, chunky up close and one surface with the face; the root's grain reads as a radish's fibres. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
- 2026-10-21, eyes and rigs worker, the B45 and B46 pilot, three rounds. Round 1: rebuilt from 13.96 studs to 3.44 by redesign, not by scale: a 2-stud head with a 32-column face (0.0625 body cells, 55 cells tall), the brow, lappets, collar and sun ring in eighth-stud cells, 132 blocks. Round 2: its own `solar` eyes on a 56 x 28 face plate (a sun in each eye whose rays swirl over 8 frames round a white-hot core, a lit turquoise rim, star cheeks), eleven moving objects and the blink, a flourish every 12 s (a hop and a full turn, wings flared, the disk popping, the orb leaping). Round 3: the VFX preview's light column scaled to the new height (1.6 studs wide read as a pillar block on a 3.4-stud alien). Overlap 0.991 to 0.993, 1,616 triangles. Wanted for: next to Moop it is plainly the rarer one at the same size, by its cells, its eyes, its light and its motion. Still cheap: the bulb under the face is a plain red block, and the sun ring hides behind the head from the front (it reads from the side and the back). Status review.
- 2026-10-21, Roster w1_high worker, the two weak spots the pilot left, one round. The bulb under the face was a plain red block: it now carries a girdle of gold and turquoise cells round its sides and back (the collar's pattern carried round, the collar still covers the front) and cream lenticel dashes under it. The sun ring hid behind the head from the front: regenerated at 1.31 studs outer radius (it was 1.06) round a centre an eighth lower, so its sides stand a quarter stud past the head and its top over the crown, with the eight rays outside it and the top ray still under 3.5 studs; its top bar keeps the name `RingT` (the hero), the halo pivot moved with it. Overlap 0.991 to 0.994, 155 blocks, 1,806 triangles; height 3.44 and the motion unchanged. Wanted for: from the front it is now a radish framed by a turning sun. Still weak: the ring overlaps the wing roots from the side; the lower half of the ring reads behind the bulb as a gold U. Status review.
