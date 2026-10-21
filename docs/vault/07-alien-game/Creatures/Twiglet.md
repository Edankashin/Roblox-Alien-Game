---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Twiglet
name: Twiglo
world: 1
tier: Common
status: review
element: Bloom
height: 2.49
blocks: 12
tris: 236
bevel_width: 0.1
bevel_segments: 2
palette: ["#9C6B3F", "#4A2E1A", "#7FC94A", "#1F140B"]
roles: [body, second, accent, ink]
hero: Hat
vfx: "none of its own (Common): Effects.luau's one Burst, a single leaf (9CB84A, the PixelLeaf sprite, spinning) letting go of the Top every 8 s and drifting down for 3 s; a Bob idle of 0.08 studs every 1.2 s; no light, no glow region. The rig adds the motion: the hat sways, the antennae nod, the twig wags and the whole stick rocks"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Twiglet_sheet.svg]]"
render: "[[Twiglet_tq_cells.jpg]]"
glb: ""
overlap: [0.993, 0.996, 1, 0.993]
cells_render: "[[Twiglet_tq_cells.jpg]]"
idle_render: "[[Twiglet_idle.png]]"
---
# Twiglet (Twiglo), Common, World 1 Verdant

A stick bug that is a twig, 2.5 studs: a square bark head with the face and a dark knot on its cheek, a twig body that rises out of its back like a growing shoot with a green bud standing up at its tip above the hat's back edge, four thin stick legs (the front pair wide under the head's corners, the hind pair long and close together under the twig), two antennae leaning forward, and one broad green leaf wider than its head worn as a hat on a short stem, tipped down over one side. Concept row in `src/shared/data/Species.luau`: "stick bug, leaf hat". Element and effect: [[Roster-Redesign]] section 2 (Bloom; a leaf lets go of the hat every 8 s). Rules: [[Blocky-Style]].

**What makes a player want it.** The leaf hat is a joke it is in on: a stick wearing a leaf and hoping to pass as a plant. B46: its own `happy` eyes, closed in two smiling arcs over an open, laughing mouth: the only Verdant face that is mid-giggle. The hat sways, the antennae nod and the twig wags like a tail. The Common rung on purpose: brown, bark and leaf green, no glow and no light.

**Hero block.** The `Hat`, one broad leaf worn tipped on a stem, unique in Verdant (Moop's leaves are a sprout pair, Raddis's are a fan); it sways on its stem.

**Moving parts (three objects and the blink).** `hat` (the leaf and its stem sway), `antenna` (the pair nods as one), `twig` (the body and its bud wag); the plate blinks.

**Alien anatomy.** A twig that walks: the body is a stick behind a square head, the legs are sticks, and the stance is an insect's (front legs wide, hind legs together); the body is still growing (the bud).

**World motif (Verdant).** The moss cell as the eighth-stud sticks and the wood grain on every brown block.

## Parts

```yaml
parts:
  # the head: a square of bark, the face on its front, a dark knot on its right cheek
  - {name: Head, slot: Body, size: [2, 1.25, 1.25], at: [0, 1.125, -0.625], bevel: true, material: wood}
  - {name: Knot, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.0625, 1.25, -0.75], material: wood}
  # the twig body behind it, with a green bud at its tip; it wags from its root
  - {name: Twig, slot: Body, size: [0.5, 0.5, 1.75], at: [0, 1.3125, 0.8125], rot: [-20, 0, 0], material: wood, moves: twig, pivot: [0, 1, 0]}
  - {name: Bud, slot: Accessory, size: [0.375, 0.5, 0.375], at: [-0.25, 2, 1.75], rot: [-20, 0, 0], moves: twig, pivot: [0, 1, 0]}
  # four stick legs: the front pair under the head's corners, the hind pair under the twig
  - {name: FrontLeg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, -0.9375], mirror: x, material: wood}
  - {name: HindLeg, slot: BodyDark, size: [0.125, 1.125, 0.125], at: [0.1875, 0.5625, 0.6875], mirror: x, material: wood}
  # two antennae leaning forward 20 degrees; they nod as one
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.625, 0.125], at: [0.375, 2, -1.0625], rot: [-20, 0, 0], mirror: x, material: wood, moves: antenna, pivot: [0, 1.75, -1]}
  # the hero: a broad leaf hat on a short stem, tipped 20 degrees, down over its left side; it sways on its stem
  - {name: Stem, slot: BodyDark, size: [0.25, 0.25, 0.25], at: [0, 1.875, -0.625], material: wood, moves: hat, pivot: [0, 1.75, -0.625]}
  - {name: Hat, slot: Accessory, size: [2.5, 0.125, 1.5], at: [0, 2, -0.625], rot: [0, 0, 20], moves: hat, pivot: [0, 1.75, -0.625]}
```

## Face

The bark front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `happy`, a Common design, two soft arcs closed in a smile (its blink flattens them), at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, three frames). An `open` laughing mouth with its tongue, and blush cheeks: mid-giggle at its own disguise. In World 1 only Twiglo wears `happy`.

```yaml
eyes:
  key: happy
  mouth: open
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 1.0625]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the hat sways on its stem, the antennae nod, the twig wags side to side in bursts like a tail, the whole stick rocks a little, the face blinks. Three objects and the blink; no flourish (that starts at Rare).

```yaml
rig:
  clips:
    hat: [{kind: sway, amp: 8, period: 2.6, axis: z}]
    antenna: [{kind: sway, amp: 12, period: 1.4, axis: x}]
    twig: [{kind: wag, amp: 12, period: 3, axis: y}]
    root: [{kind: sway, amp: 3, period: 2.4, axis: z}]
    face: [{kind: blink, period: 4.4}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Twiglet.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Twiglet.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Twiglet_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Twiglet_idle.png]]

The concept sheet, drawn from the parts table above: [[Twiglet_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Twiglet_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (57 islands). Materials: wood on the head, the twig, the legs, the antennae and the stem (grain along each stick), the leaf hat plain.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the twig body lay flat behind the head and vanished from the three-quarter view, and the leaf hat at the head's width put it at 0.70 against Pebblet and 0.69 against Moop. Round 2: the twig rises 20 degrees out of the back like a growing shoot with long hind legs under it, and the leaf is 2.5 studs across, wider than the head, tipped 20 degrees down over one side. Wanted for: a stick in a leaf hat hoping to pass as a plant. Still cheap: the bark head is a box; the antennae are two posts. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, one round. In the band already (2.49 studs): a dark bark knot on its right cheek and a green bud at the twig's tip bring it to the Common cap of 12 blocks. Its own `happy` eyes (two arcs closed in a smile) over an open laughing mouth with a pink tongue: the only face on the meadow caught mid-giggle. Three moving objects and the blink: the hat sways on its stem, the antennae nod as one, the twig wags in bursts like a tail, and the whole stick rocks 3 degrees. Overlap 0.993 to 1.0, 236 triangles; worst silhouette pair 0.675 (Buzzik), from 0.684. Wanted for: a stick in a leaf hat laughing at its own disguise. Still weak: the bud on the twig sits behind the head where the three-quarter camera cannot see it, and a happy-eyed Common never shows the open eye (its blink only flattens the arcs). Status review.
- 2026-10-21, Polish w1, two rounds. The bud at the twig's tip hid under the raised side of the leaf hat. It is now a bigger bud (three eighths by a half) standing up at the twig's tip; round 1 put it on the twig's centre line, where it rose into the hat's raised corner and merged with the lime leaf; round 2 moved it a quarter to the left and an eighth further back, where the hat dips, so it stands clear above the hat's back edge. 12 blocks (the Common cap). Overlap 0.993 to 1.000. Honest read: the growing shoot now reads from the review angle; the bud is the hat's lime, the only green the palette has. Status review.
