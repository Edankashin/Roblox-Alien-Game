---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Reindazzle
name: Blinkar
world: 2
tier: Rare
status: review
element: Frost
height: 3.42
blocks: 59
tris: 886
bevel_width: 0.1
bevel_segments: 2
palette: ["#A8805A", "#4A3222", "#F2E9DC", "#A8E4FF", "#E0202C", "#1E1510"]
roles: [body, second, accent, trim, glow, ink]
hero: Beam
fx_hooks: {Mouth: Nose, Top: Tine, Tail: Bell, Antlers: Beam}
vfx: "a soft light (Rare, Effects.luau): the lantern nose glows red and pulses every 2 s (the Light at Mouth), two frost sparkles wink over the antlers every 4 s (the Sparkle at Top) and fine frost glitter drifts off them at 2.5 a second (the Emitter at Top); it bobs gently; in the rig the icicles under each antler swing like chimes, the ears twitch and the ice-bell tail swings, and every 10 s it prances: a hop and a full turn, the ears up, the bell swished and the icicles rung"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Reindazzle_sheet.svg]]"
render: "[[Reindazzle_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.991, 0.989, 0.994]
vfx_render: "[[Reindazzle_vfx_cells.jpg]]"
cells_render: "[[Reindazzle_tq_cells.jpg]]"
idle_render: "[[Reindazzle_idle.png]]"
bar_world: Frostbyte
bar_kit: 4
bar_pieces: [frost_rim, silver_band, snowflake_stud]
bar_stance: "a prance: the head cocked 10 degrees as if listening to its antlers chime, the right foreleg lifted 50 degrees mid-step, an arc of six red lanterns at its sides and back"
bar_satellites: 6
bar_orbit: lanterns
---
# Reindazzle (Blinkar), Rare, World 2 Frostbyte

A tan reindeer, 3.2 studs to the antler tips (B45: its height is a deer's, long-legged, never its tier): a square head with a cream muzzle block standing out of its lower front, a lit red lantern nose on top of the muzzle and a small ink smile under it, dark legs, a cream harness bib on its chest with an ice sleigh bell on it, and antlers that are beams of ice: a dark post out of each side of the skull, an ice beam rising out from it, and two icicles hanging from each beam that swing like wind chimes. A six-point frost flake of ice cells is stamped on each flank, and its tail ends in an ice bell. Concept row in `src/shared/data/Species.luau`: "reindeer, icicle antlers, nose blinks". Element: Frost (`Effects.luau`); [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** The first light on the snow: a red lantern nose that pulses in the dark under antlers that chime. Beside the Uncommons at the same height it is dressed: 36 blocks (the muzzle, the harness bib and its bell, the stamped flake in eighth-stud cells, the chimes), its own amber `glimmer` eyes with a warm glint, six moving things and a prance every 10 s (a hop and a full turn, the bell swished and the icicles rung) that reads from across the snowfield.

**Hero block.** The `Beam` pair: antlers of ice with icicles hanging from them, a wide T from the front, unique in Frostbyte.

**Moving parts (six objects and the blink).** `earR`, `earL` (they twitch), `chimeR`, `chimeL` (the icicles under each beam swing), `tail` (the bell swings), `nose` (the lantern nose pulses on the light's 2 s beat); the face plate blinks and glints.

**Alien anatomy.** Antlers that are not bone but ice growing from the skull, hung with icicles that ring; a nose that is a lantern; a bell for a tail.

**World motif (Frostbyte).** Icicles, the ice facet hanging, and the six-point frost flake on the flanks in eighth-stud ice cells.

## Character bar (B54), prompt list

BAR-W2, 2026-10-26 ([[Blocky-Style]] section 10, [[Character-References]]; the plan is `tools/blocky/bar_w2.py` `reindazzle()`). Work paused by Ethan after round 2: a first build is in, no sheet yet.

- **Theme.** The lantern keeper: a reindeer whose red lantern nose is the one light in the snow, with sleigh lanterns of its own.
- **Parts gained.** (1) Six red sleigh lanterns (dark brown cap and base, lit red heart, 0.5 by 0.625) on an arc at its sides and back, the back higher, nothing in front of the face (one lit colour, the nose's). (2) A silver harness girth over the back and down both sides. (3) Silver snowflake studs on the shoulders (kit, replace the old flank flake). (4) A little ice tiara between the antler posts.
- **Stance.** The head cocked 10 degrees (a listening tilt, `rig.rest.head`) and the right foreleg lifted 50 degrees mid-step (`rig.rest.fore`).
- **Face intent.** Unchanged: wide amber glimmer eyes and the lit nose are the friendly face; a brow pair was tried and cut (it read as a frown). The head cock makes it curious.
- **Must-nots.** No lantern in front of the face or flanking the muzzle (round 1 put red blocks beside the cheeks); no pale piece on snow without a dark neighbour; no second lit colour.
- **Status.** Spec clean, exported (856 triangles, 59 blocks, 3.42 studs). Not yet judged on the 16-stud strip.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.75, -1], bevel: true, pose: head}
  - {name: Torso, slot: Body, size: [1.5, 1, 2.25], at: [0, 1.125, 0.375], bevel: true}
  # dark deer legs
  - {name: FrontLegR, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [0.5, 0.3125, -0.5], pose: fore}
  - {name: FrontLegL, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [-0.5, 0.3125, -0.5]}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.625, 0.5], at: [0.5, 0.3125, 1], mirror: x}
  # the cream muzzle standing out of the head's lower front, the lantern nose on it (its own moving part: it pulses on the light's 2 s beat) (a deep red glow: the coral one rendered pale pink) and a small ink smile under the nose
  - {name: Muzzle, slot: Accessory, size: [1, 0.375, 0.25], at: [0, 1.1875, -1.875], pose: head}
  - {name: Nose, slot: Glow, size: [0.5, 0.25, 0.25], at: [0, 1.375, -2.125], moves: nose, pivot: [0, 1.375, -2.125], pose: head}
  - {name: MouthCorner, slot: Eye, size: [0.125, 0.125, 0.125], at: [0.1875, 1.1875, -2.0625], mirror: x, pose: head}
  - {name: Mouth, slot: Eye, size: [0.25, 0.125, 0.125], at: [0, 1.0625, -2.0625], pose: head}
  # ears out at the head's sides, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.375, 0.25], at: [1.125, 2.125, -1.375], rot: [0, 0, -20], mirror: x, moves: ear, pivot: [1, 2, -1.375], pose: head}
  # the hero: antlers of ice: a dark post out of the skull, an ice beam rising out of it, two icicles hanging from the beam that swing as chimes
  - {name: Post, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.625, 2.6875, -0.875], mirror: x, pose: head}
  - {name: Beam, slot: Trim, size: [1.5, 0.25, 0.25], at: [1.3125, 2.875, -0.875], rot: [0, 0, 15], mirror: x, material: ice, pose: head}
  # branching (Rare pass w2): two ice tines rising off each beam at right angles to it, the outer one tallest, so the antlers are a
  # crystal chandelier over the head instead of a T
  - {name: Tine, slot: Trim, size: [0.25, 0.375, 0.25], at: [1.625, 3.25, -0.875], rot: [0, 0, 15], shape: cone6, mirror: x, material: ice, pose: head}
  - {name: Tine2, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.0625, 3.0625, -0.875], rot: [0, 0, 15], shape: cone6, mirror: x, material: ice, pose: head}
  - {name: Icicle, slot: Trim, size: [0.25, 0.75, 0.25], at: [1.125, 2.375, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice, moves: chime, pivot: [1.5, 2.75, -0.875], pose: head}
  - {name: Icicle2, slot: Trim, size: [0.25, 0.5, 0.25], at: [1.75, 2.625, -0.875], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice, moves: chime, pivot: [1.5, 2.75, -0.875], pose: head}
  # the harness: a cream bib on the chest under the chin, an ice sleigh bell on it
  - {name: Bib, slot: Accessory, size: [1, 0.375, 0.125], at: [0, 0.8125, -0.8125]}
  - {name: SleighBell, slot: Trim, size: [0.25, 0.25, 0.125], at: [0, 0.75, -0.9375], material: ice}
  # the tail is an ice bell hung from the rump, one moving part
  - {name: Bell, slot: Trim, size: [0.5, 0.5, 0.5], at: [0, 1.125, 1.75], moves: tail, pivot: [0, 1.375, 1.5], material: ice}
  # pilot bar: begin (tools/blocky/bar_w2.py writes this region: the Frostbyte kit, the brows and the lantern ring)
  # the Frostbyte kit: a silver snowflake stud (a plus of eighth-stud bars on a lit heart) on each shoulder, where the old flank flake was
  - {name: Flakea, slot: Trim, size: [0.125, 0.125, 0.5], at: [0.8125, 1.1875, 0.375], mirror: x, material: metal}
  - {name: Flakeb, slot: Trim, size: [0.125, 0.5, 0.125], at: [0.8125, 1.125, 0.4375], mirror: x, material: metal}
  - {name: Flakec, slot: Glow, size: [0.125, 0.125, 0.125], at: [0.9375, 1.1875, 0.4375], mirror: x, material: crystal}
  # the harness girth: a silver strap a quarter stud wide and an eighth proud over its back and down both sides behind the front legs
  - {name: GirthT, slot: Trim, size: [1.75, 0.125, 0.25], at: [0, 1.6875, -0.125], material: metal}
  - {name: GirthS, slot: Trim, size: [0.125, 1, 0.25], at: [0.8125, 1.125, -0.125], mirror: x, material: metal}
  # a little ice tiara between the antler posts (a lip of pale ice with two icicle teeth standing up; it rides the head)
  - {name: Tiaraa, slot: Accessory, size: [1, 0.125, 0.25], at: [0, 2.5625, -1.125], pose: head, material: ice}
  - {name: Tiarab, slot: Accessory, size: [0.125, 0.25, 0.25], at: [-0.3125, 2.75, -1.125], pose: head, material: ice}
  - {name: Tiarac, slot: Accessory, size: [0.125, 0.25, 0.25], at: [0.0625, 2.75, -1.125], pose: head, material: ice}
  - {name: Tiarad, slot: Accessory, size: [0.125, 0.25, 0.25], at: [0.4375, 2.75, -1.125], pose: head, material: ice}
  # the satellite set (`lanterns`, an arc at the sides and behind, the back higher, nothing in front of the face): six little sleigh lanterns, dark caps and a lit red heart, facing the viewer
  - {name: Sat0a, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [2.25, 1.8125, -0.1875], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat0b, slot: Glow, size: [0.5, 0.375, 0.25], at: [2.25, 1.5625, -0.25], moves: lanterns, pivot: [0, 1.3, 0.25], material: glow}
  - {name: Sat0c, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [2.25, 1.3125, -0.1875], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat1a, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [2, 2.0625, 1.3125], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat1b, slot: Glow, size: [0.5, 0.375, 0.25], at: [2, 1.8125, 1.25], moves: lanterns, pivot: [0, 1.3, 0.25], material: glow}
  - {name: Sat1c, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [2, 1.5625, 1.3125], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat2a, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [0.75, 2.1875, 2.4375], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat2b, slot: Glow, size: [0.5, 0.375, 0.25], at: [0.75, 1.9375, 2.5], moves: lanterns, pivot: [0, 1.3, 0.25], material: glow}
  - {name: Sat2c, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [0.75, 1.6875, 2.4375], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat3a, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-0.75, 2.1875, 2.4375], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat3b, slot: Glow, size: [0.5, 0.375, 0.25], at: [-0.75, 1.9375, 2.5], moves: lanterns, pivot: [0, 1.3, 0.25], material: glow}
  - {name: Sat3c, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-0.75, 1.6875, 2.4375], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat4a, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-2, 2.0625, 1.4375], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat4b, slot: Glow, size: [0.5, 0.375, 0.25], at: [-2, 1.8125, 1.5], moves: lanterns, pivot: [0, 1.3, 0.25], material: glow}
  - {name: Sat4c, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-2, 1.5625, 1.4375], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat5a, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-2.25, 1.8125, -0.1875], moves: lanterns, pivot: [0, 1.3, 0.25]}
  - {name: Sat5b, slot: Glow, size: [0.5, 0.375, 0.25], at: [-2.25, 1.5625, -0.25], moves: lanterns, pivot: [0, 1.3, 0.25], material: glow}
  - {name: Sat5c, slot: BodyDark, size: [0.25, 0.125, 0.125], at: [-2.25, 1.3125, -0.1875], moves: lanterns, pivot: [0, 1.3, 0.25]}
  # pilot bar: end
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
  rest:
    head: {rot: [0, 0, 10], pivot: [0, 1.25, -0.5], move: [0, -0.25, 0]}
    fore: {rot: [50, 0, 0], pivot: [0.5, 0.625, -0.5]}
  clips:
    ear: [{kind: wag, amp: 18, period: 3.2, axis: z}]
    chime: [{kind: sway, amp: 8, period: 1.6, axis: x}]
    tail: [{kind: wag, amp: 22, period: 2, axis: y}]
    nose: [{kind: pulse, amp: 0.15, period: 2}]
    lanterns: [{kind: spin, amp: -360, period: 16, axis: y}, {kind: bob, amp: 0.05, period: 2.4}]
    root: [{kind: bob, amp: 0.06, period: 1.5}]
    face: [{kind: blink, period: 4.4}]
  flourish:
    every: 10
    length: 2.4
    moves:
      - {part: root, kind: hop, amp: 0.45, at: 0, for: 0.6}
      - {part: root, kind: turn, amp: 360, at: 0.1, for: 1.3}
      - {part: ear, kind: flare, amp: 25, at: 0.2, for: 0.8}
      - {part: nose, kind: pop, amp: 0.4, at: 0.2, for: 0.6}
      - {part: tail, kind: swish, amp: 30, at: 0.5, for: 1}
      - {part: chime, kind: swish, amp: 20, at: 0.6, for: 1.4}
      - {part: nose, kind: pop, amp: 0.4, at: 1.5, for: 0.6}
      - {part: root, kind: hop, amp: 0.2, at: 1.5, for: 0.5}
      - {part: lanterns, kind: pop, amp: 0.3, at: 0.6, for: 1}
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
- 2026-10-21, Rare pass w2: the signature is **branching crystal antlers**: two ice tines rise off each beam at right angles to it (the outer one tallest, to 3.43 studs), so the antlers are a chandelier of ice over the head with the chimes hanging under it instead of a T; the lantern nose is its own moving part that pulses on the Effects.luau light's 2 s beat and pops twice in the prance. Paid for by the flank flakes, four cells a side instead of six (a cross and two diagonal cells, a sparkle's lean). 36 blocks, seven moving things (from six), the prance 2.4 s with eight moves (a second small hop with the nose flash). New attach point: `Antlers` (Beam). Honest read: the branching antlers change its outline from a T to a crown and read across the snow; they are pale ice on a pale backdrop and want the night shot, where the red nose carries it.
