---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Emberchin
name: Sizz
world: 2
tier: Uncommon
status: review
element: Ember
height: 2.75
blocks: 18
tris: 292
bevel_width: 0.1
bevel_segments: 2
palette: ["#73365A", "#C8DCE4", "#FF8C2E", "#1C0F1A"]
roles: [body, second, accent, ink]
hero: EmberQuill
vfx: "Uncommon, two layers (Effects.luau): a Burst of one flickering ember sprite (FF7A2E) pops off the Back every 2 s, and a gold Sparkle (FFD25A) twinkles at the Top every 3 s, the second colour; the idle hops, a bob of 0.15 studs every 1 s; no light; the crown quill flickers, the side quills bristle, the pool ripples and a shed cinder bobs in it in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Emberchin_sheet.svg]]"
render: "[[Emberchin_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.992, 0.997, 0.996]
cells_render: "[[Emberchin_tq_cells.jpg]]"
idle_render: "[[Emberchin_idle.png]]"
---
# Emberchin (Sizz), Uncommon, World 2 Frostbyte

A plum sea urchin out of a hot spring: a round dark body (a block with a cap step, the voxel round) bristling with eleven ember-orange quills, six-sided points leaning out from the top, the sides, the back and over the brow, standing on one pale tube foot in the middle of the little steaming pool it has just hopped into. Concept row in `src/shared/data/Species.luau`: "sea urchin, ember quills, hops between pools". Element and effect: [[Roster-Redesign]] section 2 (the quill tips glow orange; an ember pops off a quill every 2 s). Rules: [[Blocky-Style]].

**What makes a player want it.** A ball of embers that hops: the Geyser Field's spark, dark plum with eleven orange points, sitting in a pool of its own steam on the white snow. The Uncommon rung exactly: a two-tone body (plum over pale steam-blue), one secondary block (the pool) and a second colour in the touch (the orange ember), at 2.75 studs.

**Hero block.** `EmberQuill`, the quill straight up from the crown, the tallest of the eleven: unique in Frostbyte (Sabrek's ruff quills are ice and stand round its neck; these are embers all over a ball).

**Alien anatomy.** One foot, a tube in the middle, and no legs; quills that are embers it grows and sheds; a pool it carries (it hops from pool to pool, and the pool under it is the last one, still steaming).

**World motif (Frostbyte).** The ice facet as points: eleven stepped six-sided quills; the warm accent of the Geyser Field (ember orange on `glow` cells with a lit core) against the cold pool in `water` cells.

## Parts

```yaml
parts:
  # the pool it sits in, and the one tube foot
  - {name: Pool, slot: BodyDark, size: [2.5, 0.125, 2.5], at: [0, 0.0625, 0], material: water, moves: pool, pivot: [0, 0, 0]}
  # B46 detail: a shed ember bobbing in the pool at its front right
  - {name: Cinder, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.875, 0.25, -0.875], shape: ico1, material: glow, moves: cinder, pivot: [0.875, 0.125, -0.875]}
  - {name: Foot, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0, 0.3125, 0]}
  # the body is the head: a dark plum round, bevelled, with a cap step
  - {name: Body, slot: Body, size: [2, 1.5, 1.75], at: [0, 1.25, 0], bevel: true}
  - {name: Cap, slot: Body, size: [1.5, 0.25, 1.25], at: [0, 2.125, 0]}
  # the hero and its ten fellows: ember quills, six-sided points leaning out from the crown, the sides, the back and over the brow
  - {name: EmberQuill, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0, 2.5, 0], shape: cone6, material: glow, moves: ember, pivot: [0, 2.25, 0]}
  - {name: QuillUp, slot: Accessory, size: [0.375, 0.75, 0.375], at: [0.5, 2.375, 0], rot: [0, 0, -20], shape: cone6, mirror: x, material: glow}
  - {name: QuillSide, slot: Accessory, size: [0.375, 0.75, 0.375], at: [1.25, 1.75, 0], rot: [0, 0, -70], shape: cone6, mirror: x, material: glow, moves: quill, pivot: [1, 1.75, 0]}
  - {name: QuillLow, slot: Accessory, size: [0.375, 0.75, 0.375], at: [1.25, 1, 0.25], rot: [0, 0, -110], shape: cone6, mirror: x, material: glow}
  - {name: QuillBack, slot: Accessory, size: [0.375, 0.75, 0.375], at: [0.5, 1.75, 1.125], rot: [70, 0, 0], shape: cone6, mirror: x, material: glow}
  - {name: QuillBrow, slot: Accessory, size: [0.375, 0.625, 0.375], at: [0.5, 2.3125, -0.4375], rot: [-20, 0, 0], shape: cone6, mirror: x, material: glow}
  # B46 detail: an ember freckle lit on each flank, in front of the low quills
  - {name: Freckle, slot: Accessory, size: [0.125, 0.25, 0.25], at: [1.0625, 1.125, -0.375], mirror: x, material: glow}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud body (0.125 a cell); the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Body
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `kindle`, an Uncommon design added by this pass for World 2's fourth Uncommon, a dark iris lit from below with two tongues of ember glow rising beside a big pupil (the iris the accent orange, the dark iris an ember red), the look of a face by firelight, at 16 pixels a stud on a 1.75 x 0.875 stud plate (28 x 14 pixels, three frames). An open `grin` with a pink tongue and `dots` cheeks: a happy hiss.

```yaml
eyes:
  key: kindle
  colours: {iris: accent, iris2: "#C2412D"}
  mouth: grin
  cheeks: dots
  plate: [1.75, 0.875]
  at: [0, 1.25]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the crown's `ember` quill flickers (a pulse on the 2 s beat of the ember spark in Effects.luau), the two side quills bristle in bursts, the pool ripples, a shed ember bobs and glows in it, the urchin squashes on each hop and blinks. Six moving things (five objects, the Uncommon cap, and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    ember: [{kind: pulse, amp: 0.15, period: 2}]
    quill: [{kind: wag, amp: 12, period: 3, axis: z}]
    pool: [{kind: pulse, amp: 0.04, period: 2.5}]
    cinder: [{kind: bob, amp: 0.12, period: 1.6}, {kind: pulse, amp: 0.2, period: 1.6, phase: 0.25}]
    root: [{kind: squash, amp: 0.06, period: 1}]
    face: [{kind: blink, period: 3.4}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Emberchin.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Emberchin.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Emberchin_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Emberchin_idle.png]]

The concept sheet, drawn from the parts table above: [[Emberchin_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: `glow` on the quills (a lit core in the accent orange, no emission on an Uncommon), `water` on the pool (ripples, a sparkle, no grout), skin on the plum body and the foot.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a 1.75-stud body gave an Uncommon 25 cells of height and broke C1's ordering, so the body is 2 studs. Round 2: quarter-stud quills read as thorns, so they are three eighths wide and three quarters long, the top one half a stud. Overlap 0.992 to 0.997, 248 triangles, 15 blocks, 2.75 studs, no moving parts (it hops). Wanted for: a ball of embers on one foot in its own pool. Still cheap: eleven quills on a cube still leave the face's sides plain; the foot is hidden by the pool from the hero camera. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), two rounds. Round 1: World 2 has four Uncommons and the rung three designs, so this pass added `kindle` to the library (a dark ember-red iris lit from below, two orange tongues rising beside a big pupil), on a 28 x 14 plate with a pink-tongued `grin` and `dots` cheeks; it had no moving part, so the crown quill became the `ember` that flickers on the spark's 2 s beat, the side quills the `quill` pair that bristles, the pool ripples, and a steam `Bubble` was added in the pool; ember `Freckle`s light both flanks. Round 2: the pale bubble vanished on the pale pool, so it became a shed `Cinder` in the lit orange, bobbing. Six moving things (five objects, the Uncommon cap, and the blink). Height 2.75 (in band, unchanged), 18 blocks, 292 triangles, overlap 0.992 to 0.997. Wanted for: the warm one on the snow, a plum urchin with firelit eyes, a happy hiss and quills that bristle. Still weak: `kindle`'s half frame (the lid over the orange) reads cross for its 0.18 s, and the freckles read as cubes more than lit cells. Status review.
