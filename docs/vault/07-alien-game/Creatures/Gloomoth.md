---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Gloomoth
name: Iridia
world: 1
tier: Epic
status: review
element: Crystal
height: 3.5
blocks: 36
tris: 626
bevel_width: 0.125
bevel_segments: 2
palette: ["#8C6FB5", "#3B2454", "#F1E9FF", "#E8C45A", "#E08CFF", "#140C21"]
roles: [body, second, accent, trim, glow, ink]
hero: ForeWing
vfx: "kept on the body (Epic): the eyespot on each fore wing and the two antenna tips glow orchid; a glint sweeps the crystal wings every 3 s (Effects.luau's BackL sparkle emitter) and a dust of light falls under them at 5 a second; a lilac light; the wings beat 22 degrees"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Gloomoth_sheet.svg]]"
render: "[[Gloomoth_tq_cells.jpg]]"
glb: ""
overlap: [0.99, 0.993, 0.996, 0.99]
vfx_render: "[[Gloomoth_vfx_cells.jpg]]"
cells_render: "[[Gloomoth_tq_cells.jpg]]"
---
# Gloomoth (Iridia), Epic, World 1 Verdant

A night moth in mauve and moon-cream whose wings are crystal: a big square head in a shaggy cream ruff, two feathered comb antennae leaning apart with lit tips, a fuzzy banded abdomen behind on six thin legs, and four pale crystal wings spread wide off its back, the big fore pair lifted with a gold-ringed orchid eyespot on each and a plum edge, the smaller hind pair low behind. A stepped crystal emblem sits on its crown between the antennae. Concept row in `src/shared/data/Species.luau`: "moth, crystal wings". Element and effect: [[Roster-Redesign]] section 2 (Crystal; a glint sweeps the wings and light dust falls). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first thing in Verdant with wings that catch the light: a 6-stud span of crystal over a soft, fuzzy moth, with lit eyespots looking back at you from the wings and lit antennae over the house face. The Epic rung's detail: the ruff, the bands, the comb antennae, the stepped emblem, glow on three extremities (two tips, two eyespots), the light kept on the body.

**Hero block.** The `ForeWing` pair, two broad crystal wings with eyespots, unique in Verdant (Buzzik's wings are small pink membranes; Raddis's are the sun's).

**Alien anatomy.** Wings of crystal that look back with eyespots, six legs under a moth that stands, and comb antennae that light at the tip; four moving objects: the two fore wings (with their eyespots and edges) and the two antennae.

**World motif (Verdant).** The moss cell as the eighth-stud teeth of the antennae and the quarter-stud steps of the emblem.

## Parts

```yaml
parts:
  # six thin legs
  - {name: Leg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, -0.4375], mirror: x}
  - {name: MidLeg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, 0.1875], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.125, 0.5, 0.125], at: [0.8125, 0.25, 0.8125], mirror: x}
  # the abdomen behind, banded in plum, a dark tuft at its end; the big head in front
  - {name: Abdomen, slot: Body, size: [1.5, 1.25, 2.25], at: [0, 1.125, 1.125], bevel: true}
  - {name: Band, slot: BodyDark, size: [1.75, 1.5, 0.25], at: [0, 1.125, 1]}
  - {name: Band2, slot: BodyDark, size: [1.75, 1.5, 0.25], at: [0, 1.125, 1.75]}
  - {name: Tuft, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 1, 2.5]}
  - {name: Head, slot: Body, size: [2, 1.75, 1.5], at: [0, 1.625, -0.75], bevel: true}
  # a shaggy cream ruff round the neck and a tuft of it on the crown's back
  - {name: Ruff, slot: Accessory, size: [2.25, 0.625, 0.75], at: [0, 1.6875, 0.125], material: wool}
  - {name: Ruff2, slot: Accessory, size: [1.5, 0.25, 0.5], at: [0, 2.625, -0.25], material: wool}
  # the stepped crystal emblem on the crown, between the antennae
  - {name: Emblem, slot: Trim, size: [0.25, 0.125, 0.25], at: [0, 2.5625, -1.25], material: crystal}
  - {name: Emblem2, slot: Trim, size: [0.75, 0.125, 0.25], at: [0, 2.5625, -1], material: crystal}
  - {name: Emblem3, slot: Trim, size: [0.25, 0.125, 0.25], at: [0, 2.5625, -0.75], material: crystal}
  # comb antennae leaning apart 20 degrees: a stalk, three teeth and a lit tip each (the pair the game tilts)
  - {name: Stalk, slot: BodyDark, size: [0.125, 0.875, 0.125], at: [0.5625, 2.9375, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.4375, 2.5, -0.5625]}
  - {name: Tooth, slot: BodyDark, size: [0.375, 0.125, 0.125], at: [0.6875, 2.5625, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.4375, 2.5, -0.5625]}
  - {name: Tooth2, slot: BodyDark, size: [0.375, 0.125, 0.125], at: [0.8125, 2.8125, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.4375, 2.5, -0.5625]}
  - {name: Tooth3, slot: BodyDark, size: [0.375, 0.125, 0.125], at: [0.9375, 3.125, -0.5625], rot: [0, 0, -20], mirror: x, moves: antenna, pivot: [0.4375, 2.5, -0.5625]}
  - {name: AntennaTip, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.75, 3.375, -0.5], shape: ico1, mirror: x, moves: antenna, pivot: [0.4375, 2.5, -0.5625]}
  # the hero: the crystal fore wings spread wide and lifted 25 degrees, a plum edge along the outer rim, a gold-ringed orchid eyespot on each
  - {name: ForeWing, slot: Accessory, size: [2, 0.125, 2], at: [1.6875, 2.1875, 0.5], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.5], material: crystal}
  - {name: WingEdge, slot: BodyDark, size: [0.125, 0.25, 2], at: [2.5, 2.625, 0.5], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.5]}
  - {name: EyeRing, slot: Trim, size: [0.625, 0.125, 0.625], at: [1.75, 2.375, 0.5], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.5], material: metal}
  - {name: Eyespot, slot: Glow, size: [0.375, 0.125, 0.375], at: [1.75, 2.4375, 0.5], rot: [0, 0, 25], mirror: x, moves: wing, pivot: [0.75, 1.75, 0.5]}
  # the smaller hind wings, low behind, 15 degrees up
  - {name: HindWing, slot: Accessory, size: [1.25, 0.125, 1.5], at: [1.375, 1.6875, 1.625], rot: [0, 0, 15], mirror: x, material: crystal}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 14 rows for the 1.75-stud front. The eye's lit crescent is the orchid glow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9FD0"
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
    - "...gg.k..k.gg..."
    - "..pp...kk...pp.."
    - "................"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Gloomoth.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Gloomoth.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Gloomoth_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Gloomoth_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Gloomoth_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 28 cells tall; one atlas of 1024 x 1024 at 8 texels a cell (209 islands). Materials: crystal on the four wings and the emblem (light diagonals), wool on the ruff (shag with cream flecks), metal on the eye rings, skin elsewhere; the eyespots and antenna tips are glow cells.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the fore wings stood up 65 degrees like sails and read as two white boards behind the head, and the eyespots faced sideways where the game's high camera would not see them. Round 2: the fore wings 2 studs square spread wide at 25 degrees (a 6-stud span) with the eyespots and gold rings on their tops, the hind pair low at 15; the silhouette against Syrinx fell from 0.69 to 0.50. Wanted for: the first wings in Verdant that catch the light. Still cheap: the comb antennae are busy (two stalks and six teeth), the ruff reads as a white collar block, the emblem on the crown is small. Status review.
