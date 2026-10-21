---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Shellberg
name: Floe
world: 2
tier: Rare
status: review
element: Iceberg
height: 3
blocks: 35
tris: 460
bevel_width: 0.1
bevel_segments: 2
palette: ["#3FBFB0", "#1F6F68", "#D3E6F5", "#8CC8F0", "#2ED3F7", "#0F2A2E"]
roles: [body, second, accent, trim, glow, ink]
hero: Peak
vfx: "a soft light (Rare, Effects.luau): a cold mist rolls off the back of the berg at 3 a second and sinks to pool at its feet (the Emitter at Back), a soft blue light over the shell pulses every 4.5 s (the Light at Top) and a white sparkle glints on the peak every 4 s (the Sparkle at Top); it breathes 2 percent, very slowly; in the rig the lit summit pennant waves, the front flippers paddle and the stub tail wags, and every 12 s it does a slow, proud pirouette: a small hop and a full turn, the pennant swished and the flippers out"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Shellberg_sheet.svg]]"
render: "[[Shellberg_tq_cells.jpg]]"
glb: ""
overlap: [0.998, 0.997, 0.999, 0.998]
vfx_render: "[[Shellberg_vfx_cells.jpg]]"
cells_render: "[[Shellberg_tq_cells.jpg]]"
idle_render: "[[Shellberg_idle.png]]"
---
# Shellberg (Floe), Rare, World 2 Frostbyte

A teal tortoise whose shell is an iceberg, and the iceberg is nine-tenths hidden: all that shows above its white waterline is a stepped peak of snow off to its right and a smaller one on the shelf to its left (no iceberg is symmetric), while the great blue mass of the berg sits below the line, over the tortoise's back, down to its feet. On the small peak a tiny explorer's pennant of light flies from a dark pole, as if it had climbed itself. Icicles hang from the waterline's rim, a six-point frost flake of lit cells glows on each side of the berg, the patient round head pokes out the front with three dark scutes on its crown, and four dark flippers and a stub tail poke out from under. 3 studs to the peak and the pennant's tip (B45: its height is the berg's, never its tier). Concept row in `src/shared/data/Species.luau`: "tortoise, iceberg shell, nine-tenths hidden". Element and effect: [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** A joke, on purpose: it wears the whole iceberg, so the famous hidden nine-tenths is right there in plain view, and it has planted its own flag on top. Beside the Uncommons at the same height it carries more: 35 blocks (the stepped peaks, the hanging icicles, two stamped flakes in eighth-stud lit cells, the scutes, the pennant), its own `crescent` eyes (an ink drop over a lit gold crescent, a teal band of iris), five moving things and a slow pirouette every 12 s that reads from across the snowfield by its waving light.

**Hero block.** The `Peak`, the stepped snow tip above the waterline, four steps of two cells each leaning to one side, with the pennant on top: unique in Frostbyte.

**Moving parts (four objects and the blink).** `flagL` (the pole and its lit pennant wave; the rig calls it `flag`), `footR`, `footL` (the front flippers paddle), `tail` (it wags); the face plate blinks and glints.

**Alien anatomy.** The shell is ice, not bone, and most of it hangs below the waterline it carries round with it; the tortoise is nine-tenths inside its own iceberg, with only the head, the flippers and the tail out.

**World motif (Frostbyte).** The ice facet as steps and points: the berg steps in twice below the line, the peak steps up four times above it, icicles hang from the rim; the six-point frost flake on each side in eighth-stud lit cells; `frozen_water` plates and cracks over the berg.

## Parts

```yaml
parts:
  # four dark flippers and a stub tail out from under the berg; the front pair paddle
  - {name: Foot, slot: BodyDark, size: [0.625, 0.375, 0.75], at: [0.9375, 0.1875, -0.5], mirror: x, moves: foot, pivot: [0.9375, 0.375, -0.5]}
  - {name: HindFoot, slot: BodyDark, size: [0.625, 0.375, 0.75], at: [0.9375, 0.1875, 1.25], mirror: x}
  - {name: Tail, slot: BodyDark, size: [0.25, 0.375, 0.5], at: [0, 0.8125, 2.25], moves: tail, pivot: [0, 0.8125, 2]}
  # the head pokes out the front, bevelled, three dark scutes on its crown
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.125, -1.5], bevel: true}
  - {name: Scute, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [0, 1.9375, -1.5]}
  - {name: Scute2, slot: BodyDark, size: [0.375, 0.125, 0.375], at: [0.5625, 1.9375, -1.6875], mirror: x}
  # the berg below the waterline: two steps of frozen water, glossy, the trim slot
  - {name: BergBase, slot: Trim, size: [2.5, 0.75, 2.75], at: [0, 0.75, 0.625], material: frozen_water}
  - {name: BergMid, slot: Trim, size: [2.25, 0.75, 2.5], at: [0, 1.5, 0.75], material: frozen_water}
  # the waterline, a rim of snow proud all round with a shelf out to its left, icicles hanging from it, and the hero: the stepped snow peak
  # above it, off to the right (no iceberg is symmetric), with a smaller second peak on the shelf side
  - {name: Waterline, slot: Accessory, size: [3.25, 0.125, 3], at: [-0.25, 1.9375, 0.625], material: snow}
  - {name: Icicle, slot: Trim, size: [0.25, 0.375, 0.25], at: [1.25, 1.6875, -0.75], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  - {name: Icicle2, slot: Trim, size: [0.25, 0.5, 0.25], at: [-1.75, 1.625, 0.25], rot: [180, 0, 0], shape: cone6, material: ice}
  - {name: Peak, slot: Accessory, size: [2, 0.25, 2], at: [0.25, 2.125, 0.625], material: snow}
  - {name: Peak2, slot: Accessory, size: [1.5, 0.25, 1.5], at: [0.5, 2.375, 0.625], material: snow}
  - {name: Peak3, slot: Accessory, size: [1, 0.25, 1], at: [0.75, 2.625, 0.625], material: snow}
  - {name: Peak4, slot: Accessory, size: [0.5, 0.25, 0.5], at: [0.875, 2.875, 0.625], material: snow}
  - {name: Peak5, slot: Accessory, size: [0.75, 0.25, 0.75], at: [-1.125, 2.125, 0.375], material: snow}
  - {name: Peak6, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.125, 2.375, 0.375], material: snow}
  # the summit pennant on the small peak: a dark pole and a lit pennant that waves (it planted its own flag)
  - {name: Pole, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [-1.0625, 2.75, 0.4375], moves: flag, pivot: [-1.0625, 2.5, 0.4375]}
  - {name: Pennant, slot: Glow, size: [0.375, 0.25, 0.125], at: [-1.3125, 2.875, 0.4375], moves: flag, pivot: [-1.0625, 2.5, 0.4375]}
  # the stamped element glyph: a six-point frost flake of lit cells on each side of the berg (a cross of eighth-stud bars, four diagonal cells)
  - {name: Glyph, slot: Glow, size: [0.125, 0.625, 0.125], at: [1.3125, 0.8125, 0.6875], mirror: x}
  - {name: Glyph2, slot: Glow, size: [0.125, 0.125, 0.625], at: [1.3125, 0.8125, 0.6875], mirror: x}
  - {name: Glyph3, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 1.0625, 0.9375], mirror: x}
  - {name: Glyph4, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 1.0625, 0.4375], mirror: x}
  - {name: Glyph5, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 0.5625, 0.9375], mirror: x}
  - {name: Glyph6, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.3125, 0.5625, 0.4375], mirror: x}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `crescent`, a Rare design, an ink drop over a lit crescent with a band of iris, here a deep teal band over a lit gold crescent (a cyan one under a dark eye on the teal head read as a tear), at 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, five frames). A small patient smile and blush cheeks.

```yaml
eyes:
  key: crescent
  colours: {iris: second, glint: "#FFC94D"}
  mouth: smile
  cheeks: blush
  plate: [1.75, 0.875]
  at: [0, 1.0625]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`).

```yaml
rig:
  clips:
    flag: [{kind: sway, amp: 10, period: 2.4, axis: z}]
    foot: [{kind: sway, amp: 10, period: 2.8, axis: x}]
    tail: [{kind: wag, amp: 20, period: 2.2, axis: y}]
    root: [{kind: squash, amp: 0.03, period: 4.5}]
    face: [{kind: blink, period: 6}]
  flourish:
    every: 12
    length: 2.4
    moves:
      - {part: root, kind: hop, amp: 0.25, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.2, for: 1.8}
      - {part: flag, kind: swish, amp: 25, at: 0.4, for: 1.4}
      - {part: foot, kind: flare, amp: 20, at: 0.3, for: 1}
      - {part: tail, kind: swish, amp: 25, at: 0.8, for: 1}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Shellberg.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Shellberg.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Shellberg_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Shellberg_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Shellberg_idle.png]]

The concept sheet, drawn from the parts table above: [[Shellberg_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/Roster w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud). Materials: `frozen_water` on the berg (plates parted by cracks, a trapped bubble, no grout, glossy), `snow` on the waterline and the peak (each step two cells tall, so its lip covers the whole side), `ice` on the icicles, the flakes and the pennant in glow cells, skin on the teal head, flippers and tail.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a symmetric berg with a centred peak was the worst shape in the row (0.80 with Dreep, 0.82 with Eekle, 0.79 with Soakum), so the peak leans to its right, the waterline shelves out to its left and a second small peak stands on the shelf. Round 2: a white peak (L* 97) vanished against the backdrop and the iceberg joke with it, so the accent is a tinted snow. Overlap 0.997 to 0.999, 292 triangles, 19 blocks, 3 studs, no moving parts (it breathes, slowly). Wanted for: a tortoise wearing a whole iceberg, the hidden nine-tenths in plain view. Still cheap: the head's back is inside the berg; the feet are four plain blocks. Status review.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, three rounds. Round 1: in the band at 3 studs, so no resize; the head grew to 1.5 studs (at 1.25 it fell to 36 percent under the first pennant) with three dark scutes on its crown, icicles hang from the waterline's rim, the flank glyph became a six-point flake of eighth-stud lit cells, the front flippers and the stub tail move, and an explorer's pennant of light flies over the berg: 35 blocks. Round 2: the pennant on the summit put Floe at 0.72 with Snowbun (two tall things at one corner), so it flies from the small shelf peak on its left and the height stays 3. Round 3: the `crescent` eyes' cyan crescent under the dark drop read as tears on the teal head, so the crescent is gold over a deep teal iris band. Rig: the pennant waves, the flippers paddle, the tail wags, it breathes slowly and blinks (five moving things); every 12 s a slow pirouette, a small hop and a full turn with the pennant swished. Overlap 0.997 to 0.999, 460 triangles. Wanted for: a tortoise wearing a whole iceberg with its own flag planted on it, gold-lit eyes and a patient smile. Still cheap: the flank flakes sit low on the berg and read as lit dots from the three-quarter view; the hind flippers are plain blocks. Status review.
