---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Capybubble
name: Snorzo
world: 2
tier: Rare
status: review
element: Bubble
height: 3.29
blocks: 31
tris: 538
bevel_width: 0.1
bevel_segments: 2
palette: ["#E0C3A0", "#5C4A2A", "#FFF1D6", "#FF9A2E", "#5FDCFF", "#2B1D12"]
roles: [body, second, accent, trim, glow, ink]
hero: Tangerine
vfx: "a soft light (Rare, Effects.luau): three snore bubbles drift out of its nose every 4 s (the Burst at Mouth, pale aqua), a soft teal light breathes on its body (pulse 3.4 s) and a white sparkle winks on its tangerine every 4 s (the Sparkle at Halo); the body breathes 3 percent; in the rig its three lit bubbles bob and circle, its ears twitch and the tangerine's leaf sways, and every 9 s it snorts awake: a hop and a full turn, ears flared, bubbles popping up, the leaf swishing"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Capybubble_sheet.svg]]"
render: "[[Capybubble_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.985, 0.994, 0.995]
vfx_render: "[[Capybubble_vfx_cells.jpg]]"
cells_render: "[[Capybubble_tq_cells.jpg]]"
idle_render: "[[Capybubble_idle.png]]"
---
# Capybubble (Snorzo), Rare, World 2 Frostbyte

A tan capybara loaf, long and low, dozing in the Geyser Field's warm pools, 3.3 studs to the tip of its leaf (B45: its height is its own, a low loaf with a tangerine on top): a square head with a blunt cream snout block standing out of its lower front, a dark nose bar over a small stepped ink smile on the snout, two small round ears, a furred torso behind on four stubby umber legs, a folded cream bath towel with two tangerine stripes lying across its back, a glossy tangerine on its head with a stem and a two-step leaf, three lit bubbles rising from its nose up the right side of its head, and a bubble-ring glyph stamped on each flank. Concept row in `src/shared/data/Species.luau`: "capybara, tangerine hat, snores bubbles". Element and effect: [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** A joke, on purpose: the calmest animal in the world, at the spa, a towel on its back and a tangerine on its head, snoring bubbles that glow. Beside the Uncommons at the same height it carries more: 30 blocks (the snout, the towel and its stripes, the stamped ring, a lit bubble chain), its own glossy `bubble` eyes in aqua with a glint, five moving things and a flourish every 9 s when it snorts itself awake with a hop and a full turn. Nothing about it is fierce.

**Hero block.** The `Tangerine`, a glossy orange orb on its head with a stem and a leaf that sways: unique in Frostbyte.

**Moving parts (four objects and the blink).** `earR`, `earL` (they twitch), `leaf` (the tangerine's leaf sways), `float` (the three snore bubbles bob and circle); the face plate blinks and glints.

**Alien anatomy.** The bubbles it snores are part of it, three orbs of light that float beside its head and never pop (only rise when it snorts); the tangerine grew there.

**World motif (Frostbyte).** The ice facet as steps: the snout steps out of the face and the nose steps out of the snout; the warm Geyser Field accent (tangerine and cream) against the cold glow of the bubbles.

## Parts

```yaml
parts:
  # four stubby umber legs
  - {name: Leg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, -0.75], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0.625, 0.25, 1.25], mirror: x}
  # the square head and the long furred torso
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.25, -1], bevel: true}
  - {name: Torso, slot: Body, size: [2, 1.25, 2.25], at: [0, 1.125, 0.875], bevel: true, material: fur}
  # the blunt cream snout standing out of the head's lower front: a dark nose bar on top, a small ink smile under it
  - {name: Snout, slot: Accessory, size: [1.25, 0.5, 0.375], at: [0, 0.75, -1.9375]}
  - {name: Nose, slot: BodyDark, size: [0.75, 0.125, 0.125], at: [0, 0.9375, -2.1875]}
  - {name: MouthCorner, slot: Eye, size: [0.125, 0.125, 0.125], at: [0.1875, 0.8125, -2.1875], mirror: x}
  - {name: Mouth, slot: Eye, size: [0.25, 0.125, 0.125], at: [0, 0.6875, -2.1875]}
  # small round ears, each one moving part
  - {name: Ear, slot: BodyDark, size: [0.375, 0.25, 0.25], at: [0.8125, 2.125, -1.375], mirror: x, moves: ear, pivot: [0.8125, 2, -1.375]}
  # the hero: a glossy tangerine on its head, a stem and a two-step leaf that sways
  - {name: Tangerine, slot: Trim, size: [1, 0.75, 1], at: [0, 2.375, -0.875], shape: ico1}
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 2.875, -0.875]}
  - {name: Leaf, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [0.3125, 3.0625, -0.875], rot: [0, 0, 20], moves: leaf, pivot: [0.125, 3, -0.875]}
  - {name: LeafTip, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [0.625, 3.1875, -0.875], rot: [0, 0, 20], moves: leaf, pivot: [0.125, 3, -0.875]}
  # the snore bubbles rising from beside the snout up the right side of the head, clear of the face, lit, one floating group
  - {name: Bubble, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.25, 1, -2], shape: ico1, moves: float, pivot: [1.25, 1, -1.75]}
  - {name: Bubble2, slot: Glow, size: [0.5, 0.5, 0.5], at: [1.5, 1.625, -1.75], shape: ico1, moves: float, pivot: [1.25, 1, -1.75]}
  - {name: Bubble3, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.375, 2.25, -1.5], shape: ico1, moves: float, pivot: [1.25, 1, -1.75]}
  # the stamped element glyph: a bubble ring (a hollow square of eighth-stud bars) in glossy tangerine on each flank
  - {name: Glyph, slot: Trim, size: [0.125, 0.125, 0.75], at: [1.0625, 1.4375, 0.875], mirror: x}
  - {name: Glyph2, slot: Trim, size: [0.125, 0.125, 0.75], at: [1.0625, 0.8125, 0.875], mirror: x}
  - {name: Glyph3, slot: Trim, size: [0.125, 0.5, 0.125], at: [1.0625, 1.125, 0.5625], mirror: x}
  - {name: Glyph4, slot: Trim, size: [0.125, 0.5, 0.125], at: [1.0625, 1.125, 1.1875], mirror: x}
  # the spa towel folded across its back, two tangerine stripes on it
  - {name: Towel, slot: Accessory, size: [1.25, 0.125, 1], at: [0, 1.8125, 1]}
  - {name: Stripe, slot: Trim, size: [1.25, 0.125, 0.125], at: [0, 1.9375, 0.6875]}
  - {name: Stripe2, slot: Trim, size: [1.25, 0.125, 0.125], at: [0, 1.9375, 1.3125]}
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
  clips:
    ear: [{kind: wag, amp: 20, period: 3.6, axis: z}]
    leaf: [{kind: sway, amp: 12, period: 2.8, axis: z}]
    float: [{kind: bob, amp: 0.15, period: 2.2}, {kind: orbit, amp: 0.06, period: 4.4}]
    root: [{kind: squash, amp: 0.04, period: 3.4}]
    face: [{kind: blink, period: 5.2}]
  flourish:
    every: 9
    length: 2.2
    moves:
      - {part: root, kind: hop, amp: 0.3, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.1, for: 1.4}
      - {part: ear, kind: flare, amp: 25, at: 0.2, for: 0.8}
      - {part: float, kind: pop, amp: 0.25, at: 0.6, for: 0.8}
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
