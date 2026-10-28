---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Capybubble
name: Snorzo
world: 2
tier: Rare
status: review
element: Bubble
height: 3.25
blocks: 71
tris: 1142
bevel_width: 0.1
bevel_segments: 2
palette: ["#C49A68", "#5C4A2A", "#FFF1D6", "#FF9A2E", "#5FDCFF", "#2B1D12"]
roles: [body, second, accent, trim, glow, ink]
hero: Tangerine
fx_hooks: {Top: TangerineTop, Mouth: Snout, Halo: Leaf, Ring: Sat1a}
vfx: "a soft light (Rare, Effects.luau): three snore bubbles drift out of its nose every 4 s (the Burst at Mouth, pale aqua), a soft teal light breathes on its body (pulse 3.4 s) and a white sparkle winks on its tangerine every 4 s (the Sparkle at Halo); the body breathes 3 percent; in the rig its three lit bubbles bob and circle, its ears twitch and the tangerine's leaf sways, and every 9 s it snorts awake: a hop and a full turn, ears flared, bubbles popping up, the leaf swishing"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Capybubble_sheet.svg]]"
render: "[[Capybubble_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.986, 0.994, 0.995]
vfx_render: "[[Capybubble_vfx_cells.jpg]]"
cells_render: "[[Capybubble_tq_cells.jpg]]"
idle_render: "[[Capybubble_idle.png]]"
bar_world: Frostbyte
bar_kit: 3
bar_pieces: [silver_band, snowflake_stud]
bar_stance: "a doze: the head nodding 10 degrees and rolled 8, the tangerine tipped with it, a stream of six outlined bubbles curling up its right side, over its back and down its left"
bar_satellites: 6
bar_orbit: ring
---
# Capybubble (Snorzo), Rare, World 2 Frostbyte

A tan capybara loaf, long and low, dozing in the Geyser Field's warm pools, 3.3 studs to the tip of its leaf (B45: its height is its own, a low loaf with a tangerine on top): a square head with a blunt cream snout block standing out of its lower front, a dark nose bar over a small stepped ink smile on the snout, two small round ears, a furred torso behind on four stubby umber legs, a folded cream bath towel with a tangerine stripe lying across its back, a glossy tangerine on its head with a stem and a two-step leaf, a silver belt round its barrel with a silver snowflake stud on each flank, and a stream of six outlined aqua bubbles curling up its sides and over its back (the bar's satellites, grown from the snores). Concept row in `src/shared/data/Species.luau`: "capybara, tangerine hat, snores bubbles". Element and effect: [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** A joke, on purpose: the calmest animal in the world, at the spa, a towel on its back and a tangerine on its head, snoring bubbles that glow. Beside the Uncommons at the same height it carries more: 30 blocks (the snout, the towel and its stripes, the stamped ring, a lit bubble chain), its own glossy `bubble` eyes in aqua with a glint, five moving things and a flourish every 9 s when it snorts itself awake with a hop and a full turn. Nothing about it is fierce.

**Hero block.** The `Tangerine`, a glossy orange orb on its head with a stem and a leaf that sways: unique in Frostbyte.

**Moving parts (five objects and the blink).** `earR`, `earL` (they twitch), `leaf` (the tangerine's leaf sways), `ring` (the bubble stream sways 20 degrees about it and bobs); the face plate blinks and glints.

**Alien anatomy.** The bubbles it snores are part of it: a stream of lit soap bubbles that climbs round it and never pops; the tangerine grew there.

**World motif (Frostbyte).** The ice facet as steps: the snout steps out of the face and the nose steps out of the snout; the warm Geyser Field accent (tangerine and cream) against the cold glow of the bubbles.

## Character bar (B54), prompt list

BAR-W2, 2026-10-28 ([[Blocky-Style]] section 10, [[Character-References]]; the plan is `tools/blocky/bar_w2.py` `capybubble()`).

- **Theme.** Bath time in the Geyser Field: the calmest animal in the world at the spa, a tangerine on its head and the bubbles it snores grown up and circling it.
- **Parts gained.** (1) Six soap bubbles in pixel art (a lit aqua rim in a dark umber outline; two half-stud ones low, four three-quarter ones with a hollow middle high) in one stream climbing from low on its right round the back to high on its left, nothing in front of the face (one lit colour, the aqua of its eyes). They replace the old five-bubble planet ring and the three snore bubbles (one bubble set, not two). (2) A silver bathrobe belt (a pale metal in the cream slot) a quarter stud tall and an eighth proud round its barrel. (3) Silver snowflake studs on its flanks above the belt (kit; they replace the bubble-ring stamp).
- **Value and colour (rule 8).** The body is a deeper tan (`#C49A68`, L* 66; was `#E0C3A0`, L* 80, which sat too close to the snow and to the cream towel), so the cream snout, towel and belt and the orange tangerine each step off it and the dark umber legs, ears and bubble outlines step down; the bubbles' dark outline gives the lit aqua an edge on snow.
- **Stance.** A doze: the head (snout, ears, tangerine and leaf) nodding 10 degrees and rolled 8 about its neck (`rig.rest.head`), so the tangerine tips like a hat on a sleeper. The bubble stream sways 20 degrees about it, never a full turn, so none crosses the face.
- **Face intent.** Unchanged: big glossy aqua `bubble` eyes, blush, a cream snout with a stepped smile; the calm of a creature that has nothing to be cross about, and the nod makes it look sleepy-happy.
- **Must-nots.** No bubble in front of the face; no second lit colour (the tangerine is glossy, not lit); no bubble without a dark outline on snow; no pale-on-pale belt (the body is darker than it).

## Parts

```yaml
parts:
  # four stubby umber legs
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, -0.75], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, 1.25], mirror: x}
  # the square head and the long furred torso
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.25, -1], bevel: true, pose: head}
  - {name: Torso, slot: Body, size: [2, 1.25, 2.25], at: [0, 1.125, 0.875], bevel: true, material: fur}
  # the blunt cream snout standing out of the head's lower front: a dark nose bar on top, a small ink smile under it
  - {name: Snout, slot: Accessory, size: [1.25, 0.5, 0.375], at: [0, 0.75, -1.9375], pose: head}
  - {name: Nose, slot: BodyDark, size: [0.75, 0.125, 0.125], at: [0, 0.9375, -2.1875], pose: head}
  - {name: MouthCorner, slot: Eye, size: [0.125, 0.125, 0.125], at: [0.1875, 0.8125, -2.1875], mirror: x, pose: head}
  - {name: Mouth, slot: Eye, size: [0.25, 0.125, 0.125], at: [0, 0.6875, -2.1875], pose: head}
  # small round ears, each one moving part
  - {name: Ear, slot: BodyDark, size: [0.375, 0.25, 0.25], at: [0.8125, 2.125, -1.375], mirror: x, moves: ear, pivot: [0.8125, 2, -1.375], pose: head}
  # the hero: a glossy tangerine on its head, squat (sunk an eighth into the crown) and bevelled with a narrower step on top (a voxel round with a soft highlight; as a faceted
  # icosahedron it read as a gem), a stem and a two-step leaf that sways
  - {name: Tangerine, slot: Trim, size: [1.25, 1, 1.25], at: [0, 2.25, -0.875], bevel: true, pose: head}
  - {name: TangerineTop, slot: Trim, size: [0.75, 0.125, 0.75], at: [0, 2.8125, -0.875], pose: head}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [0, 2.9375, -0.875], pose: head}
  - {name: Leaf, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [0.3125, 3.0625, -0.875], rot: [0, 0, 20], moves: leaf, pivot: [0.125, 3, -0.875], pose: head}
  - {name: LeafTip, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [0.625, 3.1875, -0.875], rot: [0, 0, 20], moves: leaf, pivot: [0.125, 3, -0.875], pose: head}
  # the spa towel folded across its back, a tangerine stripe down its middle
  - {name: Towel, slot: Accessory, size: [1.25, 0.125, 1], at: [0, 1.8125, 1]}
  - {name: Stripe, slot: Trim, size: [1.25, 0.125, 0.25], at: [0, 1.9375, 1]}
  # pilot bar: begin (tools/blocky/bar_w2.py writes this region: the Frostbyte kit and the bubble stream)
  # the Frostbyte kit: a silver snowflake stud (a plus of eighth-stud bars on a lit heart) on each flank, above the belt, where the old bubble-ring stamp was
  - {name: Flakea, slot: Accessory, size: [0.125, 0.125, 0.5], at: [1.0625, 1.4375, 1], mirror: x, material: metal}
  - {name: Flakeb, slot: Accessory, size: [0.125, 0.5, 0.125], at: [1.0625, 1.375, 1.0625], mirror: x, material: metal}
  - {name: Flakec, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.1875, 1.4375, 1.0625], mirror: x, material: crystal}
  # a silver bathrobe belt: a band a quarter stud tall and an eighth proud round the barrel (the head hides its front)
  - {name: BeltR, slot: Accessory, size: [0.125, 0.25, 2.25], at: [1.0625, 0.875, 0.875], material: metal}
  - {name: BeltL, slot: Accessory, size: [0.125, 0.25, 2.25], at: [-1.0625, 0.875, 0.875], material: metal}
  - {name: BeltB, slot: Accessory, size: [2.25, 0.25, 0.125], at: [0, 0.875, 2.0625], material: metal}
  # the satellite set (`ring`, one stream climbing from low on its right round the back to high on its left, nothing in front of the face): two half-stud bubbles and four three-quarter ones, each a lit aqua rim in a dark outline, facing the viewer
  - {name: Sat0a, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [2, 0.9375, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat0b, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [2, 0.5625, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat0c, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.8125, 0.75, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat0d, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [2.1875, 0.75, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat0e, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 0.75, -1.25], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat1a, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [2.625, 1.3125, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat1b, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [2.625, 0.9375, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat1c, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [2.4375, 1.125, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat1d, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [2.8125, 1.125, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat1e, slot: Glow, size: [0.25, 0.25, 0.25], at: [2.625, 1.125, 0.625], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat2a, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [1.625, 1.9375, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat2b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [1.625, 1.3125, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat2c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [1.9375, 1.625, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat2d, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [1.3125, 1.625, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat2e, slot: Glow, size: [0.5, 0.125, 0.25], at: [1.625, 1.8125, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat2f, slot: Glow, size: [0.5, 0.125, 0.25], at: [1.625, 1.4375, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat2g, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.8125, 1.625, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat2h, slot: Glow, size: [0.125, 0.25, 0.25], at: [1.4375, 1.625, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat3a, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-1.625, 2.3125, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat3b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-1.625, 1.6875, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat3c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-1.3125, 2, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat3d, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-1.9375, 2, 2.375], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat3e, slot: Glow, size: [0.5, 0.125, 0.25], at: [-1.625, 2.1875, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat3f, slot: Glow, size: [0.5, 0.125, 0.25], at: [-1.625, 1.8125, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat3g, slot: Glow, size: [0.125, 0.25, 0.25], at: [-1.4375, 2, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat3h, slot: Glow, size: [0.125, 0.25, 0.25], at: [-1.8125, 2, 2.375], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat4a, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-2.625, 2.6875, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat4b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-2.625, 2.0625, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat4c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-2.9375, 2.375, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat4d, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-2.3125, 2.375, 0.625], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat4e, slot: Glow, size: [0.5, 0.125, 0.25], at: [-2.625, 2.5625, 0.625], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat4f, slot: Glow, size: [0.5, 0.125, 0.25], at: [-2.625, 2.1875, 0.625], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat4g, slot: Glow, size: [0.125, 0.25, 0.25], at: [-2.8125, 2.375, 0.625], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat4h, slot: Glow, size: [0.125, 0.25, 0.25], at: [-2.4375, 2.375, 0.625], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat5a, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-2, 3.1875, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat5b, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [-2, 2.5625, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat5c, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-2.3125, 2.875, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat5d, slot: BodyDark, size: [0.125, 0.5, 0.25], at: [-1.6875, 2.875, -1.25], moves: ring, pivot: [0, 1.3, 0.4]}
  - {name: Sat5e, slot: Glow, size: [0.5, 0.125, 0.25], at: [-2, 3.0625, -1.25], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat5f, slot: Glow, size: [0.5, 0.125, 0.25], at: [-2, 2.6875, -1.25], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat5g, slot: Glow, size: [0.125, 0.25, 0.25], at: [-2.1875, 2.875, -1.25], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  - {name: Sat5h, slot: Glow, size: [0.125, 0.25, 0.25], at: [-1.8125, 2.875, -1.25], moves: ring, pivot: [0, 1.3, 0.4], material: glow}
  # pilot bar: end
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front; the eyes and the cheeks are on the face plate, the nose and mouth on the snout block under it.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `bubble`, a Rare design, a big glossy iris with an arc of shine and a glint, here in aqua over a deep teal, at 16 pixels a stud on a 1.75 x 0.75 stud plate above the snout (28 x 12 pixels, five frames: open, half, closed, two glints). Blush cheeks; the mouth is on the snout.

```yaml
eyes:
  key: bubble
  colours: {iris: "#3FB8D9", iris2: "#1C5F7A", glint: glow}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.375]
  spread: 0.5
  eye_top: 2
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`).

```yaml
rig:
  rest:
    head: {rot: [-10, 0, 8], pivot: [0, 0.9, -0.3]}
  clips:
    ear: [{kind: wag, amp: 20, period: 3.6, axis: z}]
    leaf: [{kind: sway, amp: 12, period: 2.8, axis: z}]
    ring: [{kind: wag, amp: 20, period: 6, axis: y}, {kind: bob, amp: 0.08, period: 2.2}]
    root: [{kind: squash, amp: 0.04, period: 3.4}]
    face: [{kind: blink, period: 5.2}]
  flourish:
    every: 9
    length: 2.4
    moves:
      - {part: root, kind: hop, amp: 0.35, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.1, for: 1.4}
      - {part: ear, kind: flare, amp: 25, at: 0.2, for: 0.8}
      - {part: ring, kind: swish, amp: 40, at: 0.1, for: 1.8}
      - {part: ring, kind: pop, amp: 0.3, at: 0.9, for: 1}
      - {part: leaf, kind: swish, amp: 20, at: 0.8, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Capybubble.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Capybubble.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Capybubble_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Capybubble_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Capybubble_idle.png]]

The concept sheet, drawn from the parts table above: [[Capybubble_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/roster_w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud). Materials: `fur` on the torso (the 2-stud head stays skin so the tufts never crowd the face), the bubbles in glow cells, the tangerine, the glyphs and the towel stripes glossy (the trim slot), skin elsewhere.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a muzzle block hid the crescent rows, so the muzzle is drawn into the face and only the nose bar stands proud. Round 2: the glyph as a lit plus read as a first-aid cross, so it is a hollow square ring of eighth-stud bars in the glossy tangerine. Overlap 0.994 to 0.997, 458 triangles, 23 blocks, 3.12 studs, three moving objects (the ears, the bubble group). Wanted for: a capybara asleep under a tangerine, snoring bubbles. Still cheap: the bubbles rise on one side only; the torso's fur tufts are faint on tan. Status review.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, two rounds. Round 1: already in the band at 3.1 studs, so no resize; the face moved to the plate (`bubble` eyes in aqua over deep teal, blush cheeks) above a blunt cream snout block with the nose bar and a stepped ink smile on it, a spa towel with two tangerine stripes across its back, the tangerine's leaf now its own swaying part: 31 blocks. Round 2: the smallest snore bubble floated just under the right eye and read as a tear, so the bubble chain starts beside the snout and rises clear of the face. Rig: the ears twitch, the leaf sways, the bubbles bob and circle, it breathes and blinks (five moving things), and every 9 s it snorts awake with a hop and a full turn, ears flared and bubbles popping up. 3.29 studs, overlap 0.985 to 0.995, 538 triangles. Wanted for: the calmest thing in the snow, at the spa with a tangerine on its head, glossy aqua eyes and a hop that reads across the field. Still cheap: the tangerine is a faceted orb that reads a little like a gem; the towel's cream sits close to the tan body in value. Status review.
- 2026-10-21, Polish w2 worker: the tangerine read as a gem (a glossy faceted icosahedron in the metal trim slot). It is now a third bevelled mass, a squat 1.25 x 1 x 1.25 stud round sunk an eighth into the crown, with a narrower step on top under the stem (a voxel round: the bevel strips give it a soft fruit highlight, the flat faces carry the cells), the leaf as before; one more block (32), 634 triangles, height unchanged at 3.29, overlap 0.987 to 0.994; silhouette worst pair with Snorzo 0.66 (Aurelyx). Honest read: a blocky orange with a stem, plainly fruit, no longer a jewel; it is bigger on the head than the gem was, which suits the joke.
- 2026-10-21, Rare pass w2 (Ethan: "make the rare aliens 1000x cooler"): the signature is a **bubble planet ring**, five lit bubbles (three a quarter stud, two three eighths) circling the tangerine level with its upper half and clear of the ears, one moving part that turns every 7 s and bobs; on the snort it whirls twice and puffs out. Paid for by one towel stripe (the other widened to a quarter): 36 blocks, the Rare cap. Six moving things (from five), the flourish 2.4 s with seven moves. New attach point for effects: `Ring` (Ring2, the bubble at the front). Honest read: from three-quarter the tangerine now wears a ring of light and reads as a little planet on a capybara; the bubbles are still small at the game camera's distance, and a sixth needs the Rare block band raised.
