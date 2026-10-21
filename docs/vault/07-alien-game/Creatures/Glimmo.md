---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Glimmo
name: Glim
world: 1
tier: Common
status: review
element: Light
height: 2.5
blocks: 10
tris: 214
bevel_width: 0.1
bevel_segments: 2
palette: ["#4FCFC0", "#2E7F78", "#FFE566", "#13302C"]
roles: [body, second, accent, ink]
hero: Bulb
vfx: "none of its own (Common): Effects.luau's one Sparkle, the firefly yellow FFE066 at the Back (the bulb) every 3 s, 0.14 studs for half a second; a Hover idle of 0.25 studs over 2.4 s; no light, no glow region. The rig adds the motion: the covers flick, the bulb swings, the tendrils trail and the bell pulses"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Glimmo_sheet.svg]]"
render: "[[Glimmo_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.997, 0.997, 0.996]
cells_render: "[[Glimmo_tq_cells.jpg]]"
idle_render: "[[Glimmo_idle.png]]"
---
# Glimmo (Glim), Common, World 1 Verdant

A jelly firefly, 2.5 studs: a soft aqua jelly bell (the head, with the face) hovering with a yellow belly under it, three thin dark tendrils hanging from the bell that brush the grass, a firefly's yellow bulb curling up behind it like a tail in two steps with a dark firefly band round it, and two broad dark wing covers, a stud deep, hinged at its crown and lifted like a beetle about to fly. Concept row in `src/shared/data/Species.luau`: "jelly firefly". Element and effect: [[Roster-Redesign]] section 2 (Light; the bulb blinks every 3 s). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the night one: a jelly that floats at head height and blinks, the first thing a player sees move at dusk. B46: its own `button` eyes with a firefly-yellow iris, as if the bulb's light were in its eyes too, and a small smile. A Common has no glow region and no light, so the bulb is painted in the accent yellow and the game's Effects row does the blinking; everything above it on the ladder adds real light.

**Hero block.** The `Bulb`, a firefly's yellow lantern curling up behind the bell in two steps, unique in Verdant (Lantrin's lamp is a caged ball on a tail).

**Moving parts (four objects and the blink).** `wingR` and `wingL` (the covers flick), `bulb` (the lantern swings on its root), `tendril` (the front pair trail as one); the plate blinks.

**Alien anatomy.** A jellyfish that is also a firefly: it has no legs, it hangs tendrils, its light curls up behind it, and its wing covers open over wings it does not have.

**World motif (Verdant).** The moss cell as the half-stud steps of the bulb and the tendrils.

## Parts

```yaml
parts:
  # the bell: a soft-cornered jelly cube, the face on its front, a yellow belly plate under it
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1.125, 0], bevel: true}
  - {name: Belly, slot: Accessory, size: [1, 0.125, 0.75], at: [0, 0.4375, 0]}
  # three thin tendrils hang from the bell and brush the ground: two in front (they trail as one, on a pivot at the middle), one behind
  - {name: Tendril, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.6875, 0.25, -0.6875], mirror: x, moves: tendril, pivot: [0, 0.5, -0.6875]}
  - {name: HindTendril, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.0625, 0.25, 0.6875]}
  # the hero: the firefly bulb, a yellow tail curling up behind the bell in two steps, a dark firefly band round its middle; it swings on its root
  - {name: Bulb, slot: Accessory, size: [1, 0.75, 1], at: [0, 1.5, 1.25], moves: bulb, pivot: [0, 1.5, 0.75]}
  - {name: BulbBand, slot: BodyDark, size: [1.25, 0.125, 1.25], at: [0, 1.5625, 1.25], moves: bulb, pivot: [0, 1.5, 0.75]}
  - {name: Bulb2, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0, 1.875, 2], moves: bulb, pivot: [0, 1.5, 0.75]}
  # a firefly's wing covers: two broad dark plates, a stud deep and a quarter thick, hinged at the crown and lifted 25 degrees like a beetle about
  # to fly (the pair flicks)
  - {name: Elytron, slot: BodyDark, size: [1.5, 0.25, 1], at: [0.9375, 2.0625, 0.125], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.25, 1.75, 0.125]}
```

## Face

The bell's front is the body cell grid ([[Blocky-Style]] C1): 16 columns across the 2-stud head, so the cell is 0.125 studs and the 1.25-stud front is 10 rows; the eyes, the mouth and the cheeks are on the face plate.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `button`, a Common design, a round iris button with two holes and a shine, the iris in the firefly yellow (the accent), so the bulb's light seems to be in its eyes too. At 16 pixels a stud on a 1.75 x 1 stud plate (28 x 16 pixels, three frames). A small smile and blush cheeks (round one tried an "o" mouth for wonder; at 16 pixels a stud it read as a sparkle, not a mouth). In World 1 only Glim wears `button`.

```yaml
eyes:
  key: button
  colours: {iris: accent}
  mouth: smile
  cheeks: blush
  plate: [1.75, 1]
  at: [0, 1]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`, World.RigAnimator plays it): the covers flick out of step with each other, the bulb swings up and down on its root like a tail, the front tendrils trail, the bell pulses like a jelly, the face blinks. Four objects and the blink (a Common needs two); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    wing: [{kind: flap, amp: 10, period: 2.2, axis: z}]
    bulb: [{kind: sway, amp: 8, period: 2.4, axis: x}]
    tendril: [{kind: sway, amp: 10, period: 1.8, axis: x, phase: 0.25}]
    root: [{kind: squash, amp: 0.05, period: 2.4}]
    face: [{kind: blink, period: 3.6}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Glimmo.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Glimmo.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Glimmo_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Glimmo_idle.png]]

The concept sheet, drawn from the parts table above: [[Glimmo_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Glimmo_sheet.png]].

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 20 cells tall; one atlas of 512 x 512 at 8 texels a cell (50 islands). Materials: skin everywhere (a jelly has no motif; the cells are what make it read as built).

## Reviews

- 2026-10-20, World 1 fixes worker (the roster review's "two sticks at a distance"). The wing covers are plates now: a stud deep and a quarter thick instead of half a stud and an eighth, the same 1.5-stud reach and 25-degree lift, hinged a sixteenth lower so the outer tips stay under the Common cap of 2.5 studs; from the three-quarter view they read as lifted covers over a back, not sticks. Still 9 blocks, 2.5 studs. Status review.

- 2026-10-19, World 1 roster worker, four rounds. Round 1: a cube with two crystal wings at the crown read as ears, the three tendrils as legs, and the bulb hung behind where the camera never saw it. Round 2: a bell with a flared rim and a cap step, which put it at 0.71 against Moop. Round 3: no rim, no cap; the bulb curls up behind the bell like a tail where the three-quarter and the game camera see it, a yellow belly under the bell, and wing covers lifted 25 degrees; five wing-cover variants scored on the silhouette alone (steep, flat, low, long, none), the long pair the only one under 0.68. Round 4: the covers half as deep. Wanted for: the night one, a jelly that blinks. Still cheap: the covers read as two sticks from a distance and the jelly reads as an aqua box; the blink is all Effects.luau's. Status review.
- 2026-10-21, roster worker w1_low, the B45 and B46 pass, two rounds. Already in the band (2.5 studs), so no resize: the work is the face and the motion. Round 1: the library's `button` with the iris in the firefly yellow, so the bulb's light seems to be in its eyes, and an "o" mouth for wonder, which at 16 pixels a stud read as a sparkle; round 2 a small smile. A dark firefly band round the bulb (10 blocks of the Common 12), four moving objects (the covers flick out of step, the bulb swings on its root, the front tendrils trail as one) and the blink, the bell pulsing 5 percent. Overlap 0.996 to 0.997, 214 triangles. Wanted for: the night one, now with lantern eyes. Still weak: the button eyes are square and read a little like screens; the bulb band sits behind the bell where the three-quarter camera barely sees it. Status review.
