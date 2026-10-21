---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Reindazzle
name: Blinkar
world: 2
tier: Rare
status: review
element: Frost
height: 3.19
blocks: 36
tris: 564
bevel_width: 0.1
bevel_segments: 2
palette: ["#A8805A", "#4A3222", "#F2E9DC", "#A8E4FF", "#E0202C", "#1E1510"]
roles: [body, second, accent, trim, glow, ink]
hero: Beam
vfx: "a soft light (Rare, Effects.luau): the lantern nose glows red and pulses every 2 s (the Light at Mouth), two frost sparkles wink over the antlers every 4 s (the Sparkle at Top) and fine frost glitter drifts off them at 2.5 a second (the Emitter at Top); it bobs gently; in the rig the icicles under each antler swing like chimes, the ears twitch and the ice-bell tail swings, and every 10 s it prances: a hop and a full turn, the ears up, the bell swished and the icicles rung"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Reindazzle_sheet.svg]]"
render: "[[Reindazzle_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.991, 0.989, 0.996]
vfx_render: "[[Reindazzle_vfx_cells.jpg]]"
cells_render: "[[Reindazzle_tq_cells.jpg]]"
idle_render: "[[Reindazzle_idle.png]]"
---
# Reindazzle (Blinkar), Rare, World 2 Frostbyte

A tan reindeer, 3.2 studs to the antler tips (B45: its height is a deer's, long-legged, never its tier): a square head with a cream muzzle block standing out of its lower front, a lit red lantern nose on top of the muzzle and a small ink smile under it, dark legs, a cream harness bib on its chest with an ice sleigh bell on it, and antlers that are beams of ice: a dark post out of each side of the skull, an ice beam rising out from it, and two icicles hanging from each beam that swing like wind chimes. A six-point frost flake of ice cells is stamped on each flank, and its tail ends in an ice bell. Concept row in `src/shared/data/Species.luau`: "reindeer, icicle antlers, nose blinks". Element: Frost (`Effects.luau`); [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** The first light on the snow: a red lantern nose that pulses in the dark under antlers that chime. Beside the Uncommons at the same height it is dressed: 36 blocks (the muzzle, the harness bib and its bell, the stamped flake in eighth-stud cells, the chimes), its own amber `glimmer` eyes with a warm glint, six moving things and a prance every 10 s (a hop and a full turn, the bell swished and the icicles rung) that reads from across the snowfield.

**Hero block.** The `Beam` pair: antlers of ice with icicles hanging from them, a wide T from the front, unique in Frostbyte.

**Moving parts (five objects and the blink).** `earR`, `earL` (they twitch), `chimeR`, `chimeL` (the icicles under each beam swing), `tail` (the bell swings); the face plate blinks and glints.

**Alien anatomy.** Antlers that are not bone but ice growing from the skull, hung with icicles that ring; a nose that is a lantern; a bell for a tail.

**World motif (Frostbyte).** Icicles, the ice facet hanging, and the six-point frost flake on the flanks in eighth-stud ice cells.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -1], bevel: true}
  - {name: Torso, slot: Body, size: [1.5, 1, 2.25], at: [0, 1.125, 0.375], bevel: true}
  # dark deer legs
  - {name: FrontLeg, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [0.5, 0.3125, -0.5], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [0.5, 0.3125, 1], mirror: x}
  # the cream muzzle standing out of the head's lower front, the lantern nose on it (a deep red glow: the coral one rendered pale pink) and a small ink smile under the nose
  - {name: Muzzle, slot: Accessory, size: [1, 0.375, 0.25], at: [0, 1.1875, -1.875]}
  - {name: Nose, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 1.375, -2.125]}
  - {name: MouthCorner, slot: Eye, size: [0.125, 0.125, 0.125], at: [0.1875, 1.1875, -2.0625], mirror: x}
  - {name: Mouth, slot: Eye, size: [0.25, 0.125, 0.125], at: [0, 1.0625, -2.0625]}
  # ears out at the head's sides, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.375, 0.25], at: [1.125, 2.125, -1.375], rot: [0, 0, -20], mirror: x, moves: ear, pivot: [1, 2, -1.375]}
  # the hero: antlers of ice: a dark post out of the skull, an ice beam rising out of it, two icicles hanging from the beam that swing as chimes
  - {name: Post, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.625, 2.6875, -0.875], mirror: x}
  - {name: Beam, slot: Trim, size: [1.5, 0.25, 0.25], at: [1.3125, 2.875, -0.875], rot: [0, 0, 15], mirror: x, material: ice}
  - {name: Icicle, slot: Trim, size: [0.25, 0.75, 0.25], at: [1.125, 2.375, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice, moves: chime, pivot: [1.5, 2.75, -0.875]}
  - {name: Icicle2, slot: Trim, size: [0.25, 0.5, 0.25], at: [1.75, 2.625, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice, moves: chime, pivot: [1.5, 2.75, -0.875]}
  # the harness: a cream bib on the chest under the chin, an ice sleigh bell on it
  - {name: Bib, slot: Accessory, size: [1, 0.375, 0.125], at: [0, 0.8125, -0.8125]}
  - {name: SleighBell, slot: Trim, size: [0.25, 0.25, 0.125], at: [0, 0.75, -0.9375], material: ice}
  # the tail is an ice bell hung from the rump, one moving part
  - {name: Bell, slot: Trim, size: [0.5, 0.5, 0.5], at: [0, 1.125, 1.75], moves: tail, pivot: [0, 1.375, 1.5], material: ice}
  # the stamped element glyph: a six-point frost flake of ice cells on each flank: a cross of eighth-stud bars and four diagonal cells
  - {name: Flake, slot: Trim, size: [0.125, 0.625, 0.125], at: [0.8125, 1.0625, 0.4375], mirror: x, material: ice}
  - {name: Flake2, slot: Trim, size: [0.125, 0.125, 0.625], at: [0.8125, 1.0625, 0.4375], mirror: x, material: ice}
  - {name: Flake3, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.8125, 1.3125, 0.6875], mirror: x, material: ice}
  - {name: Flake4, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.8125, 1.3125, 0.1875], mirror: x, material: ice}
  - {name: Flake5, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.8125, 0.8125, 0.6875], mirror: x, material: ice}
  - {name: Flake6, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.8125, 0.8125, 0.1875], mirror: x, material: ice}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front; the eyes and the cheeks are on the face plate, the nose and the smile on the muzzle block under it.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `glimmer`, a Rare design, a coloured iris ringed darker with two shines and a glint, here a warm amber ringed in umber with a warm white glint, at 16 pixels a stud on a 1.75 x 0.75 stud plate over the muzzle (28 x 12 pixels, five frames). Blush dots for cheeks; the smile is on the muzzle.

```yaml
eyes:
  key: glimmer
  colours: {iris: "#E0A030", iris2: "#8A4B12", glint: "#FFF4D6"}
  mouth: none
  cheeks: dots
  plate: [1.75, 0.75]
  at: [0, 1.75]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`).

```yaml
rig:
  clips:
    ear: [{kind: wag, amp: 18, period: 3.2, axis: z}]
    chime: [{kind: sway, amp: 8, period: 1.6, axis: x}]
    tail: [{kind: wag, amp: 22, period: 2, axis: y}]
    root: [{kind: bob, amp: 0.06, period: 1.5}]
    face: [{kind: blink, period: 4.4}]
  flourish:
    every: 10
    length: 2
    moves:
      - {part: root, kind: hop, amp: 0.4, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.1, for: 1.3}
      - {part: ear, kind: flare, amp: 25, at: 0.2, for: 0.8}
      - {part: tail, kind: swish, amp: 30, at: 0.5, for: 1}
      - {part: chime, kind: swish, amp: 15, at: 0.6, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Reindazzle.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Reindazzle.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Reindazzle_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Reindazzle_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Reindazzle_idle.png]]

The concept sheet, drawn from the parts table above: [[Reindazzle_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/roster_w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud). Materials: `ice` on the beams, icicles, flakes and bells (light bands on the other diagonal, glossy), the nose in glow cells, skin elsewhere.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: antlers that rose up ran over the Rare height cap at 3.25, so the beams go out, rising 15 degrees, and the icicles hang from under them: the height stays at 3.19 and the silhouette gets its wide T. A six-point flake glyph with four corner cells put the count at 35; the sparkle plus keeps it at 27. Round 2: the ears moved forward on the head so the antler posts have the back of the skull. Overlap 0.995 to 0.996, 470 triangles, 27 blocks, 3.19 studs, three moving objects (the ears and the bell tail). Wanted for: a lantern nose that blinks in the dark under antlers of ice. Still cheap: the glyph is three thin blocks and reads at distance as a mark, not a flake; the bell is small. Status review.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, two rounds. Round 1: already in the band at 3.19 studs, so no resize; the face moved to the plate (`glimmer` eyes, amber ringed in umber, blush dots) over a cream muzzle block carrying the lantern nose and a stepped ink smile; a harness bib with an ice sleigh bell, the flank glyph rebuilt as a six-point flake of eighth-stud ice cells (the old plus read as a mark), the icicles under each antler made chimes that swing, the bell tail hung straight from the rump: 36 blocks, the top of the Rare band. Round 2: the glimmer's glint in ice blue sat under the iris and read as a tear, so it is a warm white. Rig: the chimes swing, the ears twitch, the bell swings, it bobs and blinks (six moving things), and every 10 s it prances, a hop and a full turn with the bell swished and the icicles rung. 3.19 studs, overlap 0.989 to 0.996, 564 triangles. Wanted for: a lantern nose that pulses under antlers that chime, dressed for the sleigh. Still cheap: the lit nose renders pale pink rather than red under the white light; the bib's bell is small from the game camera. Status review.
- 2026-10-21, Polish w2 worker: the lit nose rendered pale pink (a coral glow `#FF6B6B` washes out under emission). The glow is now a deep lantern red `#E0202C`: in the lit view the nose reads red, in the VFX preview it blooms red round a hot core. Nothing else changed: 36 blocks, 564 triangles, overlap 0.989 to 0.996. Honest read: it is a red-nosed reindeer at a glance now; the Effects.luau light at the Mouth keeps its own colour.
