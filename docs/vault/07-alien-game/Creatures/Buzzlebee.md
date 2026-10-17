---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Buzzlebee
name: Buzzik
world: 1
tier: Uncommon
status: review
element: Pollen
height: 2.37
blocks: 15
tris: 370
bevel_width: 0.1
bevel_segments: 2
palette: ["#FFC83D", "#4A2F1F", "#FF6B9A", "#1A120C"]
roles: [body, second, accent, ink]
hero: Backpack
vfx: "one touch (Uncommon): the four wings flicker (a Flap idle, 0.14 s); a pollen mote drops under it at 5 a second (Effects.luau's yellow Emitter); no glow and no light"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Buzzlebee_sheet.svg]]"
render: "[[Buzzlebee_tq.jpg]]"
glb: ""
overlap: [0.995, 0.993, 0.998, 0.995]
---
# Buzzlebee (Buzzik), Uncommon, World 1 Verdant

A honey-yellow bee with a wide square head, a striped abdomen, four pink wings (two pairs, the big pair angled up) and a tiny pink backpack with a cocoa flap behind the wing roots. It stands on two stubby front legs and lets its striped back end hang in the air. Concept row in `src/shared/data/Species.luau`: "bee, tiny backpack". Element: Pollen (the species' row in `src/shared/data/Effects.luau`); [[Roster-Redesign]] section 2 gives the buzz and the motes. Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first creature on the meadow with a *thing*: the backpack says it is going somewhere, and the four wings say it is not quite a bee. It is the Uncommon rung exactly: a two-tone body (the yellow and cocoa stripes), one secondary block (the pack) and one small touch of a second colour (the pink on the pack, the wings and the eye's crescent), so it reads as one step up from Moop and one step short of Vixa's glossy trim and light.

**Hero block.** The `Backpack`: a pink box with a cocoa flap folded over its front, behind the wing roots, unique in Verdant.

**Alien anatomy.** Two pairs of wings of different sizes, both on one pivot per side, so they flap together like a dragonfly's, and long bare antennae; it walks on two legs and hovers its abdomen.

**World motif (Verdant).** The moss cell, here as the half-stud steps of the stripes and the pack.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, -0.375], bevel: true}
  - {name: Abdomen, slot: Body, size: [1.5, 1, 1.25], at: [0, 1, 1], bevel: true}
  # the two-tone body: two cocoa stripes round the abdomen, proud by an eighth, and a cone stinger behind
  - {name: Band, slot: BodyDark, size: [1.75, 1.25, 0.25], at: [0, 1, 0.75]}
  - {name: Band2, slot: BodyDark, size: [1.75, 1.25, 0.25], at: [0, 1, 1.25]}
  - {name: Stinger, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 0.9375, 1.75], shape: cone6, rot: [90, 0, 0]}
  - {name: Leg, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0.5, 0.1875, -0.5], mirror: x}
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [0.625, 2, -0.625], rot: [0, 0, -20], mirror: x}
  # alien anatomy: four wings, a big pair angled up and a small pair behind, both on one pivot a side so they flap as one
  - {name: Wing, slot: Accessory, size: [1, 0.125, 0.625], at: [0.8125, 1.8125, 0.375], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.375, 1.625, 0.5]}
  - {name: HindWing, slot: Accessory, size: [0.75, 0.125, 0.5], at: [0.75, 1.625, 0.875], rot: [0, 0, 15], mirror: x, moves: wing, pivot: [0.375, 1.625, 0.5]}
  # the hero: a tiny pink backpack behind the wing roots, its cocoa flap folded over the front
  - {name: Backpack, slot: Accessory, size: [0.75, 0.625, 0.5], at: [0, 1.6875, 1.375]}
  - {name: Flap, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [0, 2.0625, 1.25]}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. With no glow on an Uncommon, the eye's lit crescent is the accent, the pink (a sky-blue crescent read as tears).

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": accent
    "p": "#FF8A7A"
  rows:
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.k..k.gg..."
    - "..pp...kk...pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Buzzlebee.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Buzzlebee.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Buzzlebee_tq.jpg]]

The concept sheet, drawn from the parts table above: [[Buzzlebee_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Buzzlebee_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Buzzlebee_views.png]]

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: a sky-blue accent: the blue crescent under each eye read as tears, and a dark lid over the pack lay on the wings like a board. Round 2: the accent went to pink (the crescents, the four wings, the pack) and the pack moved behind the wing roots with a small cocoa flap. Round 3: no change after the side-by-side. Overlap 0.993 to 0.998, 370 triangles, 15 blocks, 2.37 studs. Wanted for: four pink wings and a tiny backpack, the first creature that carries something. Still cheap: the pack reads as a pink box (straps do not fit in 15 blocks), and from the side the cocoa stripes darken the whole abdomen. Status review.
