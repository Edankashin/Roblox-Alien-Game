---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Spookum
name: Grin
world: 1
tier: Epic
status: review
element: Shadow
height: 3.91
blocks: 31
tris: 416
bevel_width: 0.125
bevel_segments: 2
palette: ["#E9E6FF", "#5B4A8A", "#FF9F1C", "#B89B5A", "#9D6BFF", "#1B1430"]
roles: [body, second, accent, trim, glow, ink]
hero: Stem
vfx: "kept on the body (Epic): the pumpkin grin is lit orange from inside (Effects.luau's FF9F1C Light at the mouth, pulsing every 2.4 s, and ember motes rising off the grin at 4 a second); the three longest tatters glow violet at their tips and a ghost-white mist pools under the hem (the Feet emitter); it hovers 0.35 studs on a 3 s bob, an inch off the ground, and fades to 60 percent and back every 5 s; the arms wave"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Spookum_sheet.svg]]"
render: "[[Spookum_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.996, 0.995, 0.994]
vfx_render: "[[Spookum_vfx_cells.jpg]]"
cells_render: "[[Spookum_tq_cells.jpg]]"
---
# Spookum (Grin), Epic, World 1 Verdant, the Haunted Nebula event

A round ghost with a pumpkin's grin: a soft lilac-white block body stepped narrower on top, a brass pumpkin stem with a curling tip on its crown, and the house eyes over a wide jack-o'-lantern grin cut into its front and lit orange from inside. Under the body a violet hem and six tatters of different lengths hang to the grass, the three longest lit violet at their tips; two stubby arms rise out at its sides in a "boo", and a brass chain hangs from the right hand. Dusk-violet ribs run up its back and sides like a pumpkin's, and a stepped orange pumpkin emblem sits between the back ribs. Concept row in `src/shared/data/Species.luau`: "round ghost, pumpkin grin, drifts an inch off the ground". Event: the Haunted Nebula (`src/shared/data/Seasons.luau`). Element and effect: [[Roster-Redesign]] section 2 (Shadow; the grin glows orange from inside, a pool of purple mist spreads under it, it fades and returns every 5 s; `Effects.luau` calls the element Ghost). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the event's face: a ghost whose grin is a jack-o'-lantern's, drifting an inch off the ground at night with its tatters brushing the grass and a chain swinging from one hand. The Epic rung's detail: trim (the brass stem and chain), stripes (the ribs), a stepped emblem (the pumpkin on its back), glow on three extremities (the tatter tips), the light kept on the body.

**Hero block.** The `Stem`, a brass pumpkin stem with a curling tip on a ghost's crown: the one block that says this ghost is a pumpkin, unique in Verdant (Moop's sprout is a lime leaf).

**Alien anatomy.** A ghost that is also a pumpkin: a stem on its crown, ribs on its body, a grin that glows from inside, a hem of tatters it floats on and arms it waves (the `wing` pair, the right one carrying the chain).

**World motif (Verdant).** The moss cell as the quarter-stud steps of the crown, the hem, the tatters and the emblem.

**Event palette (Haunted Nebula).** Ghost white over dusk violet with the event's pumpkin orange as the accent, old brass trim and a violet glow: the warm end of the event's range (Wispkin is the cold blue end, Cosmoo the deep violet).

## Parts

```yaml
parts:
  # the body: one soft lilac-white block, the face and the grin on its front, a narrower step on its crown
  - {name: Body, slot: Body, size: [2, 2, 2], at: [0, 1.75, 0], bevel: true}
  - {name: Crown, slot: Body, size: [1.5, 0.25, 1.5], at: [0, 2.875, 0]}
  # the hero: a brass pumpkin stem with a curling tip, off centre on the crown
  - {name: Stem, slot: Trim, size: [0.5, 0.625, 0.5], at: [0.25, 3.3125, 0]}
  - {name: StemCurl, slot: Trim, size: [0.625, 0.25, 0.25], at: [0.5625, 3.6875, 0], rot: [0, 0, -20]}
  # the violet hem under the body and six tatters hanging from it to the grass, three white with lit tips, three violet
  - {name: Hem, slot: BodyDark, size: [1.75, 0.25, 1.75], at: [0, 0.625, 0]}
  - {name: Tatter, slot: Body, size: [0.5, 0.375, 0.25], at: [-0.5, 0.3125, -0.75]}
  - {name: Tatter2, slot: BodyDark, size: [0.375, 0.25, 0.25], at: [0.4375, 0.375, -0.75]}
  - {name: Tatter3, slot: Body, size: [0.25, 0.375, 0.5], at: [0.75, 0.3125, 0]}
  - {name: Tatter4, slot: BodyDark, size: [0.25, 0.25, 0.5], at: [-0.75, 0.375, 0.25]}
  - {name: Tatter5, slot: Body, size: [0.5, 0.375, 0.25], at: [0.25, 0.3125, 0.75]}
  - {name: Tatter6, slot: BodyDark, size: [0.375, 0.25, 0.25], at: [-0.5625, 0.375, 0.75]}
  - {name: TatterTip, slot: Glow, size: [0.5, 0.125, 0.25], at: [-0.5, 0.0625, -0.75]}
  - {name: TatterTip3, slot: Glow, size: [0.25, 0.125, 0.5], at: [0.75, 0.0625, 0]}
  - {name: TatterTip5, slot: Glow, size: [0.5, 0.125, 0.25], at: [0.25, 0.0625, 0.75]}
  # two stubby arms rising out 20 degrees, a hand on each (the pair the game waves); the brass chain hangs from the right hand and swings with it
  - {name: Arm, slot: Body, size: [0.75, 0.375, 0.5], at: [1.3125, 2, -0.25], rot: [0, 0, 20], mirror: x, moves: wing, pivot: [1, 1.875, -0.25]}
  - {name: Hand, slot: Body, size: [0.375, 0.375, 0.5], at: [1.8125, 2.1875, -0.25], rot: [0, 0, 20], mirror: x, moves: wing, pivot: [1, 1.875, -0.25]}
  - {name: Chain, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.875, 1.75, -0.3125], material: metal, moves: wing, pivot: [1, 1.875, -0.25]}
  - {name: Chain2, slot: Trim, size: [0.125, 0.25, 0.25], at: [1.9375, 1.5, -0.25], material: metal, moves: wing, pivot: [1, 1.875, -0.25]}
  - {name: Chain3, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.875, 1.25, -0.3125], material: metal, moves: wing, pivot: [1, 1.875, -0.25]}
  - {name: Chain4, slot: Trim, size: [0.125, 0.25, 0.25], at: [1.9375, 1, -0.25], material: metal, moves: wing, pivot: [1, 1.875, -0.25]}
  - {name: Chain5, slot: Trim, size: [0.25, 0.25, 0.125], at: [1.875, 0.75, -0.3125], material: metal, moves: wing, pivot: [1, 1.875, -0.25]}
  # pumpkin ribs: dusk-violet strips proud of the back and the sides by an eighth
  - {name: Rib, slot: BodyDark, size: [0.25, 1.5, 0.125], at: [0.625, 1.75, 1.0625], mirror: x}
  - {name: SideRib, slot: BodyDark, size: [0.125, 1.5, 0.25], at: [1.0625, 1.75, 0.375], mirror: x}
  # the stepped emblem: an orange pumpkin of three steps with a violet stem, between the back ribs
  - {name: Emblem, slot: Accessory, size: [0.5, 0.25, 0.125], at: [0, 1.375, 1.0625]}
  - {name: Emblem2, slot: Accessory, size: [0.75, 0.375, 0.125], at: [0, 1.6875, 1.0625]}
  - {name: Emblem3, slot: Accessory, size: [0.5, 0.25, 0.125], at: [0, 2, 1.0625]}
  - {name: EmblemStem, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [0, 2.25, 1.0625]}
```

## Face

The house face on the body's front: 16 cells across the 2-stud block (0.125 a cell), 16 rows for the square front. The eyes keep the house stamp (rule 3); the mouth is a pumpkin's grin: ten cells wide and three tall, outlined in ink on its sides and bottom, two teeth hanging from its top edge and one rising from the bottom, the inside in the pumpkin orange (`o`, the accent) that `Effects.luau` lights from within. Lilac cheeks beside the grin's corners; the eye's lit crescent is the violet glow.

```yaml
face:
  host: Body
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "o": accent
    "p": "#F2A6D8"
  rows:
    - "................"
    - "................"
    - "................"
    - "................"
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg......gg..."
    - ".ppk........kpp."
    - "...kokoooookok.."
    - "...koookkoook..."
    - "....kkkkkkkk...."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Spookum.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Spookum.md --out <scratch>` (never `assets/models`; `glb` stays empty until Ethan approves the sheet; commands in full: [[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Spookum_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Spookum_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Spookum_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 31 cells tall; one atlas of 512 x 1024 at 8 texels a cell (160 islands). Materials: skin on the body, the crown, the hem, the tatters, the arms, the ribs and the emblem (a sheet has no motif; the cells and the grout are what make it read as built), metal on the chain (glossy); the stem is glossy trim; the tatter tips are glow cells.

## Reviews

- 2026-10-20, World 1 fixes worker, one round. Built as drawn: the jack-o'-lantern grin under the house eyes reads at once, the brass stem says pumpkin, the chain swings from the right hand on the camera's side, the three lit tatter tips put the Epic's glow at the hem where the mist pools in the game. Overlap 0.994 to 0.996, 416 triangles, 31 blocks, 3.91 studs; the boxed silhouette's worst pair is Zirrit at 0.65. Wanted for: the event's face, a ghost whose grin is a pumpkin's. Still cheap: the arms are two plain white bars; the back emblem and ribs are behind the three-quarter camera (the game's high camera sees the ribs on the sides). Status review.
