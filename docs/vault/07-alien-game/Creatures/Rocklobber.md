---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Rocklobber
name: Boulden
world: 1
tier: Rare
status: review
element: Stone
height: 3.125
blocks: 35
tris: 502
bevel_width: 0.1
bevel_segments: 2
palette: ["#C8553D", "#3A3238", "#A39E94", "#E0B04A", "#FFB347", "#1C1418"]
roles: [body, second, accent, trim, glow, ink]
hero: Claw
vfx: "a soft light (Rare), three layers in Effects.luau: a warm amber light pulsing on its left claw (FrontL) where the gem sits; every 5 s the claws clack and a puff of six grey grit chips falls from that claw; a gold sparkle on the right claw's gem (FrontR) every 3 s. The flourish (every 9 s) raises both boulders overhead, hops and clacks them twice"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Rocklobber_sheet.svg]]"
render: "[[Rocklobber_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.996, 1, 0.996]
vfx_render: "[[Rocklobber_vfx_cells.jpg]]"
cells_render: "[[Rocklobber_tq_cells.jpg]]"
idle_render: "[[Rocklobber_idle.png]]"
---
# Rocklobber (Boulden), Rare, World 1 Verdant

A rust-red crab whose claws are boulders, 3.125 studs to the tip of its antenna (B45: a squat crab, so its shell sits low in the band; it was 3): a wide low shell (the head, with the face plate) under a dark carapace rim and a rust dome step with a gold cairn glyph, six dark legs (a knee juts out of the front and hind pairs), two short arms ending in grey boulders built in two steps, each with a stone thumb over it, a stone nip under it and an amber gem set in a gold bezel on its face. One antenna carries a stepped pebble, and two stone nubs sit on the shell's back corners. Concept row in `src/shared/data/Species.luau`: "crab, boulder claws". Element and effect: [[Roster-Redesign]] section 2 (Stone; the claws clack with a dust puff). Rules: [[Blocky-Style]].

**What makes a player want it (B46).** The claws are absurd: two boulders on a crab the size of a shoe, held up like trophies, and they clack. Next to the Uncommons at the same height it carries more and smaller blocks (35 to Buzzik's 15): the stepped boulders with thumbs and nips, the gems in gold bezels, the jointed legs, the dome and its glyph; its own `crescent` eyes (an ink drop over a gold band and an amber crescent that matches its gems, with a glint) where the Commons wear plain ink; six moving things (both boulders, both front legs, the antenna and the blink); and a flourish every 9 s that reads across the meadow: it hops with both boulders raised overhead and clacks them twice.

**Hero block.** The `Claw` pair, boulders of grey stone with an amber gem in a gold bezel each, unique in Verdant.

**Moving parts (five objects and the blink).** `clawR` and `clawL` (the boulder, its top step, thumb, nip, bezel and gem, turning on the shoulder: they lift and clack), `legR` and `legL` (the front legs scuttle), `antenna` (with its pebble, it sways); the face plate blinks and glints.

**Alien anatomy.** Claws of rock it did not grow, six legs with knees, and a single antenna with a pebble on it.

**World motif (Verdant).** The moss cell as the eighth-stud cells of the cairn glyph and the bezels, and the cobbles of the stone motif on the boulders.

## Parts

```yaml
parts:
  # six jointed legs under the shell: a dark post with a knee jutting out of it
  - {name: Leg, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1, 0.25, -0.625], mirror: x, moves: leg, pivot: [1, 0.5, -0.625]}
  - {name: Knee, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [1.0625, 0.4375, -0.625], mirror: x, moves: leg, pivot: [1, 0.5, -0.625]}
  - {name: MidLeg, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1, 0.25, 0], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1, 0.25, 0.625], mirror: x}
  - {name: HindKnee, slot: BodyDark, size: [0.375, 0.125, 0.25], at: [1.0625, 0.4375, 0.625], mirror: x}
  # the shell: a wide low block with the face plate, a dark carapace rim proud over it, a rust dome step on top
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.125, 0], bevel: true}
  - {name: Carapace, slot: BodyDark, size: [2.25, 0.25, 2], at: [0, 1.875, 0]}
  - {name: Dome, slot: Body, size: [1.5, 0.125, 1.25], at: [0, 2.0625, 0.125]}
  # two stone nubs on the shell's back corners
  - {name: Nub, slot: Accessory, size: [0.25, 0.125, 0.25], at: [1, 2.0625, 0.75], mirror: x, material: stone}
  # the stamped element glyph: a gold cairn of three stepped cells on the dome, where the game camera sees it
  - {name: Glyph, slot: Trim, size: [0.75, 0.125, 0.25], at: [-0.25, 2.1875, 0.5], material: metal}
  - {name: Glyph2, slot: Trim, size: [0.5, 0.125, 0.25], at: [-0.25, 2.1875, 0.25], material: metal}
  - {name: Glyph3, slot: Trim, size: [0.25, 0.125, 0.25], at: [-0.25, 2.1875, 0], material: metal}
  # the hero: two short arms, a boulder in two steps on each with a stone thumb over it, a stone nip under it and an amber gem in a gold bezel (the pair that clacks)
  - {name: Arm, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.25, 1.25, -0.75], mirror: x}
  - {name: Claw, slot: Accessory, size: [1.25, 1, 1.25], at: [1.875, 1.5, -1], mirror: x, moves: claw, pivot: [1.25, 1.25, -0.75], material: stone}
  - {name: ClawTop, slot: Accessory, size: [0.875, 0.25, 0.875], at: [1.9375, 2.125, -0.9375], mirror: x, moves: claw, pivot: [1.25, 1.25, -0.75], material: stone}
  - {name: Thumb, slot: Accessory, size: [0.5, 0.375, 0.625], at: [1.875, 2.4375, -1.3125], mirror: x, moves: claw, pivot: [1.25, 1.25, -0.75], material: stone}
  - {name: Nip, slot: Accessory, size: [0.5, 0.25, 0.25], at: [1.875, 1.125, -1.75], mirror: x, moves: claw, pivot: [1.25, 1.25, -0.75], material: stone}
  - {name: Bezel, slot: Trim, size: [0.5, 0.5, 0.125], at: [1.875, 1.625, -1.6875], mirror: x, moves: claw, pivot: [1.25, 1.25, -0.75], material: metal}
  - {name: Gem, slot: Glow, size: [0.25, 0.25, 0.125], at: [1.875, 1.625, -1.8125], mirror: x, moves: claw, pivot: [1.25, 1.25, -0.75]}
  # one antenna with a stepped pebble on its tip (it sways)
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.625, 0.125], at: [0.4375, 2.4375, 0.1875], moves: antenna, pivot: [0.4375, 2.125, 0.1875]}
  - {name: AntennaPebble, slot: Accessory, size: [0.375, 0.25, 0.375], at: [0.4375, 2.875, 0.1875], moves: antenna, pivot: [0.4375, 2.125, 0.1875], material: stone}
  - {name: PebbleCap, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.375, 3.0625, 0.25], moves: antenna, pivot: [0.4375, 2.125, 0.1875], material: stone}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `crescent`, a Rare design, an ink drop over a band of gold iris and a lit amber crescent that matches the gems in its claws, at 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, five frames: open, half, closed, two glints). A cat mouth and blush cheeks.

```yaml
eyes:
  key: crescent
  colours: {iris: trim, glint: glow}
  mouth: cat
  cheeks: blush
  plate: [1.75, 1]
  at: [0, 1.0625]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8): the boulders lift a little and clack in bursts, the front legs scuttle, the antenna sways, the shell rocks side to side, the face blinks and glints. Six moving things (five objects and the blink; a Rare needs four). The flourish, every 9 s: a hop with both boulders raised overhead, then two clacks and the antenna whipping.

```yaml
rig:
  clips:
    claw: [{kind: flap, amp: 8, period: 2.6, axis: z}, {kind: wag, amp: 10, period: 5, axis: y, phase: 0.2}]
    leg: [{kind: sway, amp: 10, period: 0.9, axis: x}]
    antenna: [{kind: sway, amp: 14, period: 1.8, axis: x}, {kind: sway, amp: 8, period: 2.7, axis: z, phase: 0.3}]
    root: [{kind: sway, amp: 3, period: 2.8, axis: z}]
    face: [{kind: blink, period: 4.8}]
  flourish:
    every: 9
    length: 2.2
    moves:
      - {part: claw, kind: flare, amp: 35, axis: z, at: 0, for: 1.2}
      - {part: root, kind: hop, amp: 0.35, at: 0.2, for: 0.7}
      - {part: claw, kind: swish, amp: 18, axis: y, at: 1.1, for: 1}
      - {part: antenna, kind: swish, amp: 25, axis: x, at: 0.9, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Rocklobber.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Rocklobber.md --out <scratch> --suffix _cells --idle --write` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Rocklobber_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Rocklobber_vfx_cells.jpg]]

The idle: eight frames of the clips and four of the flourish, and the face plate's frames:

![[Rocklobber_idle.png]]

The concept sheet, drawn from the parts table above: [[Rocklobber_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud). Materials: stone on the boulders, the thumbs, the nips, the nubs and the pebble (cobbles and cracks), metal on the gold glyph, studs and bezels, skin elsewhere; the gems are glow cells.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the boulder claws read at once and the amber gems carry the Rare's light, but the gold cairn glyph on the flanks sat behind the claws where no camera saw it, and a bevelled claw could not move. Round 2: the claws plain stone boxes on the `jaw` pair, the glyph moved to the carapace. Wanted for: two boulders on a crab the size of a shoe that clack. Still cheap: the shell between the claws is small and flat; the legs are thin posts. Status review.
- 2026-10-21, Roster w1_high worker, the B45 and B46 pass, one round. Kept at 3.125 studs (a squat crab, in the band already) and rebuilt to 35 blocks with smaller detail: each boulder in two steps with a thumb over it and a nip under it (a pincer at last), the gem in a gold bezel, knees on the front and hind legs, a rust dome step under the glyph, stone nubs on the back corners, a stepped pebble on the antenna. Its own `crescent` eyes in gold over an amber crescent that matches the gems, a cat mouth, blush cheeks; five moving objects and the blink (the boulders lift and clack, the front legs scuttle, the antenna sways); a flourish every 9 s (a hop with both boulders raised overhead, two clacks). Overlap 0.996 to 1, 502 triangles. Wanted for: two boulders held up like trophies, and the flourish reads across the meadow. Still weak: the gold bezel and the lit gem are close in value, so the frame reads only up close; the legs are still posts from the front. Status review.
