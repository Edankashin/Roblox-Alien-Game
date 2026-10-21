---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Snailbyte
name: Snibble
world: 1
tier: Uncommon
status: review
element: Light
height: 2.75
blocks: 20
tris: 350
bevel_width: 0.1
bevel_segments: 2
palette: ["#9FD9A6", "#2F6B4F", "#C9803E", "#14221A"]
roles: [body, second, accent, ink]
hero: Shell
vfx: "two touches (Uncommon): Effects.luau's pale glint Sparkle (D6E6F2) on the shell at the Back every 4 s and a slow copper mote (E8A15A, the second colour) drifting off it at 0.8 a second; a Bob idle of 0.05 studs over 2.8 s; no light, no glow region. The rig adds the motion: the feelers wave out of step, the dish turns, the body creeps"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Snailbyte_sheet.svg]]"
render: "[[Snailbyte_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.998, 0.999, 0.997]
cells_render: "[[Snailbyte_tq_cells.jpg]]"
idle_render: "[[Snailbyte_idle.png]]"
---
# Snailbyte (Snibble), Uncommon, World 1 Verdant

A mint-green snail whose shell is a copper machine, 2.75 studs: a square soft head with the face at the front of a broad, flat, dark foot, two feelers leaning out with round knobs on their tips, and behind the head a riveted copper shell that is a stepped spiral standing edge-on, taller than the head and off to its left, the whole coil turned 20 degrees so its face looks toward the camera: a disc with the whorl drawn in cells on its flat faces and a dark groove winding in from its rim on the camera's side, an outer turn of riveted panels winding round it in four steps that taper from the thick base behind the dark mouth to a thin lip down the front, and a tall aerial with a little dish tipped up toward the front and the right, a dark cup in it and a feed horn standing out of it, on the foot's right shoulder. Concept row in `src/shared/data/Species.luau`: "snail, metal shell". Element and effect: [[Roster-Redesign]] section 2 (Light; a glint sweeps the shell every 4 s). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first thing on the meadow that is partly a machine: a snail that built itself a copper shell with an aerial, which says someone could fix a ship with it. B46: its own `droplet` eyes, copper dewdrops with a light band at their foot (the machine and the dew in one), its dish turning slowly as it listens and its feelers waving out of step. The Uncommon rung exactly: a two-tone body (mint over the dark foot), one secondary block (the shell) and one touch of a second colour (the copper on the shell, the dish and the eyes).

**Hero block.** The `Shell`, a riveted copper coil standing edge-on and off to one side, the whorl on its faces and the outer turn stepping round it, unique in Verdant.

**Moving parts (three objects and the blink).** `feelerR` and `feelerL` (they wave out of step), `dishR` (the dish and its horn turn); the plate blinks.

**Alien anatomy.** It has no legs and slides on a foot; its shell is metal, and it listens through a turning dish.

**World motif (Verdant).** The moss cell as the quarter-stud steps of the shell's outer turn.

## Parts

```yaml
parts:
  # the foot it slides on, broad, flat and dark, a sole under the head
  - {name: Foot, slot: BodyDark, size: [3, 0.25, 2.75], at: [0, 0.125, 0.125]}
  - {name: Sole, slot: BodyDark, size: [1.5, 0.125, 1], at: [0.375, 0.3125, -0.75]}
  # the head: a soft mint cube at the front, the face on it
  - {name: Head, slot: Body, size: [2, 1.25, 1.25], at: [0.375, 1, -0.75], bevel: true}
  # two feelers leaning out 20 degrees, a round mint knob on each tip; each waves on its root
  - {name: Feeler, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [1.25, 1.9375, -0.6875], rot: [0, 0, -20], moves: feeler, pivot: [1.125, 1.625, -0.6875]}
  - {name: Knob, slot: Body, size: [0.25, 0.25, 0.25], at: [1.4375, 2.4375, -0.6875], shape: ico1, rot: [0, 0, -20], moves: feeler, pivot: [1.125, 1.625, -0.6875]}
  - {name: FeelerL, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [-0.5, 1.9375, -0.6875], rot: [0, 0, 20], moves: feeler, pivot: [-0.375, 1.625, -0.6875]}
  - {name: KnobL, slot: Body, size: [0.25, 0.25, 0.25], at: [-0.6875, 2.4375, -0.6875], shape: ico1, rot: [0, 0, 20], moves: feeler, pivot: [-0.375, 1.625, -0.6875]}
  # the hero: a copper shell that is a stepped spiral standing edge-on behind the head and off to its left, the whole coil turned 20
  # degrees so its flat face looks toward the three-quarter camera (every block of it yawed about the core's centre). The core is a disc
  # with the whorl drawn in cells on its two flat faces; the outer turn winds round it as four narrower steps that taper as they go: the
  # thick base turn behind the mouth, up the back, forward over the top (the tallest point) and a thin lip down the front, ending above
  # the dark mouth where the body comes out
  - {name: Shell, slot: Accessory, size: [1.25, 1.5, 1.5], at: [-0.875, 1.625, 0.75], rot: [0, 20, 0], material: whorl}
  - {name: ShellBase, slot: Accessory, size: [0.75, 0.625, 1.625], at: [-0.75, 0.5625, 1.0625], rot: [0, 20, 0], material: metal}
  - {name: ShellBack, slot: Accessory, size: [0.75, 1.75, 0.375], at: [-0.5625, 1.5, 1.625], rot: [0, 20, 0], material: metal}
  - {name: ShellTop, slot: Accessory, size: [0.75, 0.375, 1.5], at: [-0.875, 2.5625, 0.75], rot: [0, 20, 0], material: metal}
  - {name: ShellLip, slot: Accessory, size: [0.75, 0.625, 0.25], at: [-1.1875, 2.0625, -0.0625], rot: [0, 20, 0], material: metal}
  - {name: Mouth, slot: BodyDark, size: [0.75, 0.625, 0.25], at: [-1.0625, 0.5625, 0.1875], rot: [0, 20, 0]}
  # Polish w1: the whorl in the cells was faint from the review angle, so a dark groove winds in from the core's camera-side rim in three
  # eighth-stud bars proud of its face (over the top, down the back, in along the bottom), turned with the coil, with the cell whorl inside
  - {name: Groove, slot: BodyDark, size: [0.125, 0.125, 1], at: [-0.3125, 2.125, 0.5625], rot: [0, 20, 0]}
  - {name: Groove2, slot: BodyDark, size: [0.125, 1.125, 0.125], at: [-0.125, 1.625, 1], rot: [0, 20, 0]}
  - {name: Groove3, slot: BodyDark, size: [0.125, 0.125, 0.75], at: [-0.25, 1.125, 0.625], rot: [0, 20, 0]}
  # an aerial and a little dish with a feed horn on the right shoulder of the foot, where the three-quarter camera sees them beside the head;
  # the dish turns on the aerial. Polish w1: the flat dish on its post read as a table; it now tips 25 degrees up toward the front and the
  # right (rot x and z) on a taller aerial, with a dark cup in its middle and the feed horn standing out of it along the dish's axis
  - {name: Aerial, slot: BodyDark, size: [0.125, 1, 0.125], at: [1.5625, 0.75, 0.4375], material: metal}
  - {name: Dish, slot: Accessory, size: [0.5, 0.125, 0.5], at: [1.5625, 1.3125, 0.4375], rot: [-25, 0, -25], material: metal, moves: dish, pivot: [1.5625, 1.25, 0.4375]}
  - {name: DishCup, slot: BodyDark, size: [0.25, 0.125, 0.25], at: [1.5625, 1.375, 0.4375], rot: [-25, 0, -25], moves: dish, pivot: [1.5625, 1.25, 0.4375]}
  - {name: Horn, slot: BodyDark, size: [0.125, 0.375, 0.125], at: [1.6875, 1.5, 0.3125], rot: [-25, 0, -25], material: metal, moves: dish, pivot: [1.5625, 1.25, 0.4375]}
```

## Face

The head's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `droplet`, an Uncommon design, a dewdrop with a big pupil and a light band at its foot, here in copper (the accent) over a warm light-copper band: the machine and the morning dew in one eye. At 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, three frames). A small smile and blush cheeks. In World 1 only Snibble wears `droplet`.

```yaml
eyes:
  key: droplet
  colours: {iris: accent, iris2: "#F2B878"}
  mouth: smile
  cheeks: blush
  plate: [1.75, 1]
  at: [0.375, 0.9375]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the feelers wave out of step, the dish turns once in 8 s on its aerial as it listens, the body creeps (a slow stretch along its length), the face blinks. Three objects and the blink (an Uncommon needs three); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    feelerR: [{kind: sway, amp: 10, period: 2, axis: z}, {kind: sway, amp: 6, period: 3, axis: x}]
    feelerL: [{kind: sway, amp: 10, period: 2, axis: z, phase: 0.5}, {kind: sway, amp: 6, period: 3, axis: x, phase: 0.3}]
    dishR: [{kind: spin, amp: 360, period: 8, axis: y}]
    root: [{kind: squash, amp: 0.03, period: 2.8, axis: z}]
    face: [{kind: blink, period: 4.6}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Snailbyte.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Snailbyte.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Snailbyte_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Snailbyte_idle.png]]

The concept sheet, drawn from the parts table above: [[Snailbyte_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Snailbyte_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 22 cells tall; one atlas of 512 x 1024 at 8 texels a cell (75 islands; the yawed shell's faces are not culled). Materials: whorl on the shell's core (a square spiral a step and a half down on its two flat faces, one ring further out every third of a lap, a lit ridge inside each turn; metal panels on its narrow faces), metal on the outer turn, the aerial and the dish (panels, seams and rivets), skin on the head, the foot, the mouth and the feelers.

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "tower, not a spiral"). The shell is a stepped spiral: a 1.25 x 1.5 x 1.5 core disc on the new `whorl` cell motif (the coil drawn on its flat faces) with the outer turn wound round it as four narrower metal steps that taper from the base to the lip, a dark mouth under the lip where the body leaves the shell; the whorl-eye plates and the ziggurat top are gone; the dish moved to the foot's right shoulder where the three-quarter camera sees it. Round 2: the coil was there but faint, a one-cell line on a face the camera sees at a glance, so the whorl line is two cells wide and two steps down and the whole shell is yawed 20 degrees about the core's centre (every block of it, so the turn stays wound on the core; a tilted mass takes no bevel) to face the three-quarter view. The yawed coil put the boxed silhouette at 0.70 against Moop; the shell a quarter further left and the foot a flat quarter-stud slab 3 studs wide (its corners now empty the box's bottom row; a sole under the head keeps the mass on it) took it to 0.66. 13 blocks, 2.75 studs. Status review.

- 2026-10-19, World 1 roster worker, four rounds. Round 1: a shell in three centred steps behind the head: a ziggurat, 0.83 against Moop. Round 2: shifted right with a wide foot, 0.73. Round 3: the shell as a tall coil stood edge-on (1 stud wide, 1.75 tall) off to one side, the head offset the other way, the foot wide: 0.68. Round 4: the coil to its left (Pebblet's cairn leans right) and a second step on top. Wanted for: a snail that built itself a copper machine. Still cheap: the coil reads as a riveted tower, not a spiral (a whorl needs cells drawn on the face, a later motif); the dish is hidden from the three-quarter camera. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, one round. In the band already (2.75 studs). Mint knobs on the feeler tips and a feed horn on the dish bring it to 16 blocks (the Uncommon band is 10 to 20). Its own `droplet` eyes, copper dewdrops with a light-copper band at their foot, the machine and the dew in one, with a small smile. Three moving objects and the blink: the feelers wave out of step, the dish turns once in 8 s on its aerial as it listens, the body creeps (a 3 percent stretch along its length). Overlap 0.996 to 0.998, 302 triangles; worst silhouette pair 0.686 (Moop): the closest pair in the batch, still under 0.7. Wanted for: a snail that built itself a copper machine, now with copper eyes and a turning dish. Still weak: the dish on its aerial reads as a little table or a mushroom from the three-quarter view, and the shell's whorl is faint in daylight. Status review.
- 2026-10-21, Polish w1, four rounds. Two weak spots. The flat dish on its post read as a table: it now tips 25 degrees up toward the front and the right on an aerial a quarter taller, with a dark cup in its middle and the feed horn standing out along its axis. Every dish that faces the camera fills the right of the front silhouette: tilted at the old height it hit 0.70 to 0.706 against Moop; raised on the taller aerial it is 0.697, under the line with no margin. The whorl was faint: three dark eighth-stud bars wind in from the core's camera-side rim (over the top, down the back, in along the bottom), turned with the coil, round the cell whorl. 20 blocks (Uncommon 10 to 20, at the cap). Overlap 0.997 to 0.999. Honest read: a satellite dish now, small; the groove makes the coil read as a spiral from the review angle, though three bars are a start of a spiral, not a whole one (the cap allows no more). Status review.
