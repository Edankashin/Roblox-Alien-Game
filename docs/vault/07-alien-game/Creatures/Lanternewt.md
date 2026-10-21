---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Lanternewt
name: Lantrin
world: 1
tier: Uncommon
status: review
element: Light
height: 2.75
blocks: 19
tris: 412
bevel_width: 0.1
bevel_segments: 2
palette: ["#F26B3A", "#4A2638", "#FFD24A", "#1E1016"]
roles: [body, second, accent, ink]
hero: Lamp
vfx: "two touches (Uncommon): Effects.luau's held amber glow sprite (FFA94D, PixelHalo) breathing at the Tail lamp, and one warm cream mote (FFE2A8, the second colour) rising off it every 2 s; a Breathe idle of 2 degrees over 2.6 s; no light (that starts at Rare), no glow region. The rig adds the motion: the lamp tail sways, the feathery gills flutter and the body breathes"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Lanternewt_sheet.svg]]"
render: "[[Lanternewt_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.995, 0.995, 0.996]
cells_render: "[[Lanternewt_tq_cells.jpg]]"
idle_render: "[[Lanternewt_idle.png]]"
---
# Lanternewt (Lantrin), Uncommon, World 1 Verdant

An orange newt that carries a lantern on its tail, 2.75 studs: a wide square head low to the ground, a long low body on four stubby legs, two dark feathery gills (two blades each) sweeping back from the head like an axolotl's, three yellow spots on its back, and a tail that curls up behind it to hold a lantern: a dark metal base and cap round a yellow glass with two cage bars across its front. Concept row in `src/shared/data/Species.luau`: "newt, glowing tail". Element and effect: [[Roster-Redesign]] section 2 (Light; the lamp breathes). Rules: [[Blocky-Style]].

**What makes a player want it.** It only comes out at night and it brings its own light: a small orange thing in the dark grass with a lantern held up behind it. B46: its own `moonlet` eyes, a lamp-yellow iris with a big pupil over an amber crescent, as if the lantern were lit in each eye, and gills that flutter as it breathes. An Uncommon has no glow region, so the glass is painted in the accent yellow and the game's held glow does the breathing; above it on the ladder the light becomes real.

**Hero block.** The `Lamp`, a caged lantern on the tip of an upturned tail, unique in Verdant (Glim's bulb trails behind on a stalk; this is a lamp with a base, a cap and cage bars).

**Moving parts (three objects and the blink).** `tail` (the tail and its lamp sway as one), `gillR` and `gillL` (the feathery gills flutter); the plate blinks.

**Alien anatomy.** External gills on a creature that walks the meadow, and a tail that is a lamp post.

**World motif (Verdant).** The moss cell as the quarter-stud spots and the eighth-stud gill feathers and cage bars.

## Parts

```yaml
parts:
  # four stubby legs
  - {name: Leg, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.75, 0.1875, -0.5], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.5, 0.375, 0.5], at: [0.625, 0.1875, 1.25], mirror: x}
  # the head, wide and low, the face on its front; the long low body behind it
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, -0.75], bevel: true}
  - {name: Body, slot: Body, size: [1.5, 1, 2], at: [0, 0.875, 1], bevel: true}
  # alien anatomy: two feathery gills sweeping back and up from the head's sides, 20 degrees, two blades each; they flutter on their roots
  - {name: Gill, slot: BodyDark, size: [0.75, 0.125, 0.125], at: [1.3125, 1.4375, -0.1875], rot: [0, 0, 20], mirror: x, moves: gill, pivot: [1, 1.375, -0.1875]}
  - {name: GillFeather, slot: BodyDark, size: [0.5, 0.125, 0.125], at: [1.25, 1.625, -0.0625], rot: [0, 0, 20], mirror: x, moves: gill, pivot: [1, 1.375, -0.1875]}
  # three yellow spots on the back
  - {name: Spot, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.375, 1.4375, 0.75]}
  - {name: Spot2, slot: Accessory, size: [0.25, 0.125, 0.25], at: [-0.25, 1.4375, 1.5]}
  - {name: Spot3, slot: Accessory, size: [0.25, 0.125, 0.25], at: [0.375, 1.4375, 1.75]}
  # the hero: the tail curls up 25 degrees behind it and holds a lantern: a metal base and cap round a yellow glass with two cage bars
  - {name: Tail, slot: Body, size: [0.5, 0.5, 1.25], at: [0, 1.5, 2.5], rot: [-25, 0, 0], moves: tail, pivot: [0, 1.125, 1.9375]}
  - {name: LampBase, slot: BodyDark, size: [0.5, 0.125, 0.5], at: [0, 1.9375, 3.125], moves: tail, pivot: [0, 1.125, 1.9375], material: metal}
  - {name: Lamp, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0, 2.25, 3.125], moves: tail, pivot: [0, 1.125, 1.9375], material: glow}
  - {name: CageBar, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.1875, 2.25, 2.8125], mirror: x, moves: tail, pivot: [0, 1.125, 1.9375], material: metal}
  - {name: LampCap, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [0, 2.625, 3.125], moves: tail, pivot: [0, 1.125, 1.9375], material: metal}
```

## Face

The head's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `moonlet`, an Uncommon design, a big pupil in a lamp-yellow iris (the accent) over a warm amber crescent, the lantern lit in each eye (a warm crescent, never a pale one: rule 3's tears lesson). At 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, three frames). A wide newt's smile and blush cheeks. In World 1 only Lantrin wears `moonlet`.

```yaml
eyes:
  key: moonlet
  colours: {iris: accent, iris2: "#FF8A1F"}
  mouth: smile
  cheeks: blush
  plate: [1.75, 1]
  at: [0, 0.9375]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the lamp tail sways slowly side to side and lifts, the gills flutter out of step with each other like an axolotl's, the body breathes, the face blinks. Three objects and the blink (an Uncommon needs three); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    tail: [{kind: sway, amp: 6, period: 2.6, axis: y}, {kind: sway, amp: 4, period: 3.9, axis: x, phase: 0.2}]
    gillR: [{kind: flap, amp: 14, period: 1.3, axis: z}]
    gillL: [{kind: flap, amp: 14, period: 1.3, axis: z, phase: 0.5}]
    root: [{kind: squash, amp: 0.03, period: 2.6}]
    face: [{kind: blink, period: 5}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Lanternewt.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Lanternewt.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Lanternewt_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Lanternewt_idle.png]]

The concept sheet, drawn from the parts table above: [[Lanternewt_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Lanternewt_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 22 cells tall; one atlas of 512 x 512 at 8 texels a cell (80 islands). Materials: metal on the lamp's base and cap, glow cells (a lit core, no emission) on the glass, skin elsewhere.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: built as drawn; the lamp on the upturned tail read at once, the gills as fins. Round 2: the body a stud tall so one bevel width fits both masses, the finial dropped to stay under 2.75 and 15 blocks. Wanted for: a small orange thing in the dark grass with its own lantern. Still cheap: the body is long and plain between the spots; the lamp's glass is painted, not lit (an Uncommon has no glow region). Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, one round. In the band already (2.75 studs). A second feather on each gill, a third back spot and two iron cage bars across the lamp's front bring it to 19 blocks (the Uncommon band is 10 to 20). Its own `moonlet` eyes: a big pupil in a lamp-yellow iris over a warm amber crescent, the lantern lit in each eye (warm, never pale: the tears lesson), a wide newt's smile. Three moving objects and the blink: the lamp tail sways and lifts, the gills flutter out of step, the body breathes. Overlap 0.995 to 0.996; worst silhouette pair 0.63 (Voltus). Wanted for: the night's lamp-carrier with the lamp's glow in its eyes. Still weak: from the three-quarter view the dark gill blades read as whiskers more than feathers, and the lamp could swing on its own (it moves only with the tail). Status review.
