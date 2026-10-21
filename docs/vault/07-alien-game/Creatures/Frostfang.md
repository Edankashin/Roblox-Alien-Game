---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Frostfang
name: Sabrek
world: 2
tier: Epic
status: review
element: Frost
height: 3.4
blocks: 64
tris: 982
bevel_width: 0.1
bevel_segments: 2
palette: ["#4F9BD8", "#22406B", "#F2F7FB", "#C7DCEE", "#2ED3F7", "#12192B"]
roles: [body, second, accent, trim, glow, ink]
hero: Fang
fx_hooks: {Mouth: FangTip, Top: Crown, Tail: TailTip, Crown: Crown2, Back: QuillTip}
vfx: "kept on the body (Epic, Effects.luau): every 12 s it sneezes, a burst of twenty snowflakes thrown forward off its muzzle that spin as they fall (the flourish Burst at Mouth), frost breath puffs forward off the muzzle twice a second (the Emitter at Mouth), a cool blue light on its body, snowflakes drift down off its back (the Emitter at Top) and a fang glints every 3 s (the Sparkle at Mouth); the two icicle fangs and the tail tip are lit ice; it breathes 4 percent; in the rig the ruff of quills bristles, the ears flick, the lit tail sways and the front paws knead, and the sneeze is the flourish: a wind-up squash with the ruff popped, then a hop and a full turn, ears flared and the tail swished"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Frostfang_sheet.svg]]"
render: "[[Frostfang_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.995, 0.997, 0.994]
vfx_render: "[[Frostfang_vfx_cells.jpg]]"
cells_render: "[[Frostfang_tq_cells.jpg]]"
idle_render: "[[Frostfang_idle.png]]"
---
# Frostfang (Sabrek), Epic, World 2 Frostbyte

A sabre-tooth cub in ice blue caught in a play bow, 3.4 studs to the tip of its tail (B45; it was 3.72, and a cub that plays stands low): its chest is down on big cream front paws in frosted silver ankle bands, its rump up on long hind legs, and its tail stands up off-centre over the rump, leaning to its right, ending in a block of lit ice in a silver band. Round its square head stands a ruff of six dark ice quills pointing out like the rays of a frost star (up, out and down on each side), so from the front its outline is a spiked ring no other Frostbyte alien has. A cream muzzle stands out of the lower face with a small dark cat's nose and an ink cat's mouth over a blue chin, and two little icicle fangs hang from under it in front of the chin, lit from inside. Cream cheek tufts, cream inner ears, a cream bib between the front legs, two dark stripes over the rump, a floating snowflake crown of light turning between its ears, lit beads at its quills' tips and a six-point frost flake of silver cells stamped on each flank. Concept row in `src/shared/data/Species.luau`: "sabre-tooth cub, icicle fangs, quill ruff, sneezes snowflakes". Element: Frost (`Effects.luau`); [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It only rolls in a Blizzard, and it is the first Frostbyte creature that plays: a cub in a play bow under a crown of ice quills, with eyes no lower species has, a lit snowflake turning in each one (the `frost` design, new in the library for it). At the same height as the Rares it carries 55 blocks, most of them sixteenth-grid detail (the stamped flakes, the stripes, the ankle bands, the cat's mouth, the fangs), seven moving things and the sneeze: every 12 s a squash, a hop and a full turn with the ruff popped, flung snowflakes and all. Cute and cooler, never fiercer: the fangs are small and lit, the face is a soft cat's smile.

**Hero block.** The `Fang` pair: two icicles hanging from under the muzzle with stepped points, lit from inside. Unique in Frostbyte.

**Moving parts (seven objects and the blink).** `ruff` (the six quills bristle as one, their lit tips with them), `earR`, `earL` (they flick), `tail` (it sways), `pawR`, `pawL` (the front paws knead), `crown` (the snowflake crown turns once every 6 s and bobs); the face plate blinks and glints.

**Alien anatomy.** Fangs that are icicles growing outside the mouth and regrowing after each sneeze; a ruff of ice quills instead of fur; a tail that ends in a block of light.

**World motif (Frostbyte).** Icicles (the fangs, the quills as stepped points) and the six-point frost flake stamped on the flanks in sixteenth-grid silver cells; the flake again as the pupil of its eyes.

## Parts

```yaml
parts:
  # the play bow: the chest low over the front legs, the rump raised on long hind legs (three masses), the square head low in front
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.625, -1], bevel: true}
  - {name: Torso, slot: Body, size: [1.5, 1, 2], at: [0, 1, 0.25], bevel: true}
  - {name: Rump, slot: Body, size: [1.5, 1, 1], at: [0, 1.75, 1.25], bevel: true}
  - {name: Bib, slot: Accessory, size: [1, 0.375, 0.0625], at: [0, 0.6875, -0.78125]}
  # short front legs on big cream paws that knead, a frosted band on each ankle; long hind legs on cream paws, banded too
  - {name: Leg, slot: Body, size: [0.375, 0.25, 0.375], at: [0.5, 0.375, -0.5], mirror: x}
  - {name: Paw, slot: Accessory, size: [0.5, 0.25, 0.625], at: [0.5, 0.125, -0.625], mirror: x, moves: paw, pivot: [0.5, 0.25, -0.3125]}
  - {name: Band, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.28125, -0.5], mirror: x, material: metal}
  - {name: HindLeg, slot: Body, size: [0.375, 1, 0.375], at: [0.5, 0.75, 1.25], mirror: x}
  - {name: HindPaw, slot: Accessory, size: [0.5, 0.25, 0.625], at: [0.5, 0.125, 1.3125], mirror: x}
  - {name: HindBand, slot: Trim, size: [0.5, 0.0625, 0.5], at: [0.5, 0.28125, 1.25], mirror: x, material: metal}
  # the cream muzzle out of the lower face: a small dark nose (a quarter wide), a small ink cat's mouth; cream cheek tufts at the jaw
  - {name: Muzzle, slot: Accessory, size: [1, 0.375, 0.25], at: [0, 1.0625, -1.875]}
  - {name: Nose, slot: Eye, size: [0.25, 0.125, 0.125], at: [0, 1.1875, -2.0625]}
  - {name: MouthCurl, slot: Eye, size: [0.125, 0.0625, 0.0625], at: [0.125, 1.03125, -2.03125], mirror: x}
  - {name: CheekTuft, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.0625, 1, -1.375], mirror: x}
  # a blue chin under the muzzle, so the fangs sit over a jaw instead of hanging from the muzzle's corners like a moustache
  - {name: Chin, slot: Body, size: [0.75, 0.25, 0.375], at: [0, 0.75, -1.6875]}
  # the hero: two little icicle fangs hanging from under the muzzle, lit from inside, stepped points
  - {name: Fang, slot: Glow, size: [0.125, 0.375, 0.125], at: [0.25, 0.6875, -1.9375], mirror: x, material: ice}
  - {name: FangTip, slot: Glow, size: [0.125, 0.1875, 0.125], at: [0.25, 0.40625, -1.9375], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  # ears with cream insides, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.5, 0.25], at: [0.625, 2.625, -1.25], rot: [0, 0, -15], mirror: x, moves: ear, pivot: [0.625, 2.375, -1.25]}
  - {name: InnerEar, slot: Accessory, size: [0.25, 0.25, 0.0625], at: [0.625, 2.625, -1.40625], rot: [0, 0, -15], mirror: x, moves: ear, pivot: [0.625, 2.375, -1.25]}
  # the ruff: six dark ice quills round the back of the head pointing out like the rays of a frost star; they bristle as one
  - {name: RuffUpper, slot: BodyDark, size: [0.375, 1, 0.375], at: [1.0625, 2.625, -0.1875], rot: [0, 0, -20], shape: cone6, mirror: x, material: ice, moves: ruff, pivot: [0, 1.625, -0.1875]}
  - {name: RuffSide, slot: BodyDark, size: [0.375, 1, 0.375], at: [1.375, 1.75, -0.1875], rot: [0, 0, -70], shape: cone6, mirror: x, material: ice, moves: ruff, pivot: [0, 1.625, -0.1875]}
  - {name: RuffLow, slot: BodyDark, size: [0.375, 0.75, 0.375], at: [1.3125, 1.0625, -0.1875], rot: [0, 0, -115], shape: cone6, mirror: x, material: ice, moves: ruff, pivot: [0, 1.625, -0.1875]}
  # lit ice beads at the tips of the upper and side quills (Rare pass w2), so the frost star round its head is lit at its points
  - {name: QuillTip, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.1875, 3, -0.1875], rot: [0, 0, -20], mirror: x, moves: ruff, pivot: [0, 1.625, -0.1875]}
  - {name: QuillTip2, slot: Glow, size: [0.125, 0.125, 0.125], at: [1.75, 1.875, -0.1875], rot: [0, 0, -70], mirror: x, moves: ruff, pivot: [0, 1.625, -0.1875]}
  # the signature (Rare pass w2): a floating snowflake crown over its head, a lit eight-point flake in sixteenth cells standing face on
  # between the ears, turning slowly about its own axis and bobbing; on the sneeze it whirls
  - {name: Crown, slot: Glow, size: [0.125, 0.75, 0.0625], at: [0, 2.875, -1.03125], moves: crown, pivot: [0, 2.875, -1.03125]}
  - {name: Crown2, slot: Glow, size: [0.75, 0.125, 0.0625], at: [0, 2.875, -1.03125], moves: crown, pivot: [0, 2.875, -1.03125]}
  - {name: Crown3, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.1875, 3.0625, -1.03125], mirror: x, moves: crown, pivot: [0, 2.875, -1.03125]}
  - {name: Crown4, slot: Glow, size: [0.125, 0.125, 0.0625], at: [0.1875, 2.6875, -1.03125], mirror: x, moves: crown, pivot: [0, 2.875, -1.03125]}
  # the tail stands up off the rump, leaning to its right, a silver band on it and a block of lit ice at its tip; one moving part
  - {name: Tail, slot: Body, size: [0.375, 0.75, 0.375], at: [0.28125, 2.625, 1.5], rot: [0, 0, -20], moves: tail, pivot: [0.125, 2.25, 1.5]}
  - {name: TailBand, slot: Trim, size: [0.5, 0.125, 0.5], at: [0.375, 2.875, 1.5], rot: [0, 0, -20], material: metal, moves: tail, pivot: [0.125, 2.25, 1.5]}
  - {name: TailTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.46875, 3.15625, 1.5], rot: [0, 0, -20], material: ice, moves: tail, pivot: [0.125, 2.25, 1.5]}
  # two dark stripes over the raised rump
  - {name: Stripe, slot: BodyDark, size: [1.625, 0.0625, 0.125], at: [0, 2.28125, 1]}
  - {name: Stripe2, slot: BodyDark, size: [1.625, 0.0625, 0.125], at: [0, 2.28125, 1.3125]}
  # the stamped element glyph: a six-point frost flake in frosted silver on each flank (a cross of bars and four diagonal cells)
  - {name: Flake, slot: Trim, size: [0.0625, 0.625, 0.125], at: [0.78125, 1, 0.25], mirror: x, material: metal}
  - {name: Flake2, slot: Trim, size: [0.0625, 0.125, 0.625], at: [0.78125, 1, 0.25], mirror: x, material: metal}
  - {name: Flake3, slot: Trim, size: [0.0625, 0.125, 0.125], at: [0.78125, 1.25, 0.5], mirror: x, material: metal}
  - {name: Flake4, slot: Trim, size: [0.0625, 0.125, 0.125], at: [0.78125, 1.25, 0], mirror: x, material: metal}
  - {name: Flake5, slot: Trim, size: [0.0625, 0.125, 0.125], at: [0.78125, 0.75, 0.5], mirror: x, material: metal}
  - {name: Flake6, slot: Trim, size: [0.0625, 0.125, 0.125], at: [0.78125, 0.75, 0], mirror: x, material: metal}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front; the eyes and the cheeks are on the face plate, the nose and the mouth on the muzzle block under it.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes, new in the eye library for it ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`, Roster w2_high): `frost`, an Epic design, a six-point snowflake pupil lit cyan in a two-tone ice iris (deep navy over frost white) inside an ink rim (a sky-blue iris on the blue head melted into it), a white shine and a glint, at 16 pixels a stud on a 1.75 x 0.75 stud plate over the muzzle (28 x 12 pixels, five frames). Blush cheeks; the mouth is on the muzzle.

```yaml
eyes:
  key: frost
  colours: {iris: "#E8F7FF", iris2: second, pupil: glow, rim: ink}
  mouth: none
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.625]
  spread: 0.5
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`). The flourish is the sneeze, on the same 12 s beat as the Effects.luau snowflake burst.

```yaml
rig:
  clips:
    ruff: [{kind: pulse, amp: 0.06, period: 1.8}]
    ear: [{kind: wag, amp: 18, period: 2.6, axis: z}]
    tail: [{kind: sway, amp: 12, period: 2.2, axis: z}]
    paw: [{kind: sway, amp: 10, period: 3, axis: x, phase: 0.5}]
    crown: [{kind: spin, amp: 360, period: 6}, {kind: bob, amp: 0.06, period: 2.2}]
    root: [{kind: squash, amp: 0.04, period: 1.8}]
    face: [{kind: blink, period: 4}]
  flourish:
    every: 12
    length: 2.4
    moves:
      - {part: root, kind: squash, amp: 0.15, at: 0, for: 0.5}
      - {part: ruff, kind: pop, amp: 0.2, at: 0, for: 0.6}
      - {part: root, kind: hop, amp: 0.4, at: 0.5, for: 0.7}
      - {part: root, kind: turn, amp: 360, at: 0.5, for: 1.3}
      - {part: crown, kind: turn, amp: 720, at: 0.4, for: 1.6}
      - {part: crown, kind: pop, amp: 0.35, at: 1.4, for: 0.9}
      - {part: ear, kind: flare, amp: 30, at: 0.4, for: 0.8}
      - {part: paw, kind: flare, amp: 20, at: 0.5, for: 0.7}
      - {part: tail, kind: swish, amp: 25, at: 0.6, for: 1.2}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Frostfang.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Frostfang.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Frostfang_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Frostfang_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Frostfang_idle.png]]

The concept sheet, drawn from the parts table above: [[Frostfang_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/roster_w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud). Materials: skin on the coat (fur tufts crowd a 2-stud head), `ice` on the fangs, the quills and the tail tip (the glow parts carry the ice bands lit), `metal` on the bands and the flakes.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: a flake with its corner cells on the stripe drops put the glyph under the stripes, so the stripes are three slabs on the back only and the flank is the flake's. Round 2: the ruff's lowest pair point sideways (70 degrees) so the ruff reads as a collar from the front and not as a second pair of ears; the pale cyan crescent under the eye read as a tear on the blue (rule 3's don't), so the glow went to a saturated cyan, which reads as lit. Overlap 0.995 to 0.999, 714 triangles, 49 blocks, 3.72 studs, three moving objects (the ears and the tail); three glow extremities (the fangs and the tail tip). Wanted for: the Blizzard's own cat, two lit icicle fangs and a crown of quills. Still cheap: the coat is plain skin cells (the fur tufts crowded a 2-stud head); the flake is thin from the three-quarter view. Status review.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, three rounds. Round 1: redesigned at 3.4 studs from 3.72 as a cub in a play bow (the chest low on short banded front legs, the rump raised on long hind legs, three masses), a cream muzzle block with a dark nose and an ink cat's mouth, two small lit icicle fangs under it, cheek tufts, a cream bib, stripes over the rump, the tail up off-centre in a silver band with its lit ice tip, the flank flakes and ankle bands in sixteenth-grid cells: 55 blocks. Its own eyes, `frost`, added to the library for it: a lit six-point snowflake pupil. Round 2: the sky-blue iris melted into the blue head, so the iris is frost white under a navy top in an ink rim; the quills hid inside the head, so they moved behind its back face and grew (the upper and side pairs a stud long, the low pair at 25 degrees under horizontal), a frost star round the head. Round 3 (the silhouette test): it sat at 0.70 with Fenrir whatever its ruff did; Fenrir's silver crescent behind its mane parted the pair, now 0.66 and Sabrek's worst. Rig: the ruff bristles, the ears flick, the tail sways, the front paws knead, it breathes and blinks (seven moving things), and the sneeze every 12 s is its flourish: a squash with the ruff popped, then a hop and a full turn with the ears flared and the tail swished. Overlap 0.995 to 0.997, 870 triangles. Wanted for: the Blizzard's playful cub, a lit snowflake in each eye under a frost star of quills. Still cheap: the play bow is gentle from the front (the raised rump hides behind the head); the muzzle with its fangs reads a little like a moustache from straight ahead. Status review.
- 2026-10-21, Polish w2 worker: from the front the muzzle and fangs read as a moustache (a dark bar of a nose over two white points hanging free from the muzzle's corners). The nose narrowed from three eighths to a quarter so it and the philtrum make a small cat's T instead of a bar; a blue `Chin` block (0.75 x 0.25 x 0.375) now sits under the muzzle; the fangs moved in a sixteenth to x 0.25 and hang in front of the chin, so they read as teeth over a jaw. 56 blocks, 882 triangles, overlap 0.995 to 0.997; silhouette worst pair with Sabrek 0.67 (Fenrir), unchanged. Honest read: from the front it is now a sabre kitten's muzzle with two fangs, not a moustache; the fangs are still small at the game camera's distance.
- 2026-10-21, Rare pass w2: the signature is a **floating snowflake crown**, a lit eight-point flake in sixteenth cells standing face on between the ears, its own moving part that turns once every 6 s and bobs, whirling twice and swelling in the sneeze; the upper and side quills of the ruff end in lit ice beads, so the frost star round its head is lit at its points. Paid for by the third rump stripe and the philtrum: 64 blocks (the Epic cap), eight moving things (from seven), the sneeze 2.4 s with nine moves (the paws flare). New attach point: `Crown` (Crown2). Honest read: the crown is the first thing the eye finds and reads as a flake, not a cross, by its diagonal cells; at the same height it now reads as royalty of the cubs, never fiercer.
