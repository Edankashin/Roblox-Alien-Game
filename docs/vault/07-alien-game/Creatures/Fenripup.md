---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Fenripup
name: Fenrir
world: 2
tier: Cosmic
status: review
element: Moon
height: 14
blocks: 110
tris: 1436
bevel_width: 0.25
bevel_segments: 2
palette: ["#4B3D8F", "#1E1A47", "#B9C6E0", "#D9E2F5", "#AEB8FF", "#0E0B1E"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#AEB8FF", "#E6ECFF", "#7F74E6"]
hero: MoonC
vfx: "to the sky: the forehead moon glows and passes through its phases over 30 s (the glow cycle: periwinkle, full-moon white, deep violet); the mane tips, the flank runes, the leg marks, the tail's core and the chain's broken ends glow with it; moon-dust motes orbit at 1.5 studs; a ground ring of runes turning once in 12 s; a moonlit mist (the cold light) round the body; a moon-dust trail while it runs; the flourish is the howl: the head goes up, the moon flares and a beam of moonlight stands from the orb into the sky (Effects.luau: Light, the Wisp and Star emitters, Orbit, Trail)"
ride: "Sprint; the rider sits on the mane behind the head (the second and third mane layers, 7.5 studs wide, 10 studs up), between the tufts"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Fenripup_sheet.svg]]"
render: "[[Fenripup_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.996, 0.999, 0.997]
vfx_render: "[[Fenripup_vfx_cells.jpg]]"
cells_render: "[[Fenripup_tq_cells.jpg]]"
---
# Fenripup (Fenrir), Cosmic, World 2 Frostbyte

A giant moon wolf, 14 studs tall, nearly three avatars: an indigo wolf with a 6-stud head carrying the house face, a glowing stepped moon on its forehead, a black nose, two ice fangs hanging past its chin, and a mane of layered cell blocks in near-black: four slabs stepping down the neck with a tuft pointing out of each end of the top three, a ruff along each cheek, and five tufts along the ridge, each tipped with a cell of moonlight. A pale underside runs from the muzzle (drawn into the face) down the chest and belly; silver plates sit on the shoulders, silver bands on the shins, and three moon marks glow on each foreleg. A silver collar with three studs holds a chain of three links hanging down the chest, the last link broken, its ends lit (the echo of the bound Fenrir, worn as a trophy). Its tail is held low and stiff and splits at the tip round a core of light; a moon orb floats between its ears. Concept row in `src/shared/data/Species.luau`: "puppy, glowing moon on its forehead; echo of Fenrir". Element: Moon (`Effects.luau`); [[Roster-Redesign]] section 2 and the Fenrir brief in section 3 give the phasing moon, the rune ring, the moon-dust trail and the howl beam. Rules: [[Blocky-Style]].

**What makes a player want it.** Ethan on the old Fenrir: it "looks too cute, and not really something that would appeal to people who worked so hard to find him"; and later: rarer means worth it to find, not simply fiercer. So Fenrir is the most impressive thing in Frostbyte rather than the meanest: 14 studs, a mount, a mane that stands a stud proud of the head, a moon that phases and a beam to the sky when it howls. The face stays the house face; the two options on the sheet (`world2_ladder_v1.jpg`) are A, the house face as-is, and B, the house face under a heavier brow with a moon-lit eye crescent, for Ethan to pick (B is a hero-only exception to rule 3's "no fierce brow").

**Hero block.** The forehead moon (`MoonC`, the widest of its four stepped rows), a disc of moonlight on the brow, unique in Frostbyte.

**Moving parts (four objects).** `earR`, `earL` (they turn), `tail` (held stiff, it lifts at the howl), `float` (the moon orb, it bobs and is the beam's foot).

**Alien anatomy.** Fangs of ice outside the mouth, a mane that is a stack of slabs rather than hair, a chain that is part of its body (the broken ends glow), a moon orb that floats on nothing, and a tail that splits round a core of light.

**World motif (Frostbyte).** Icicles (the fangs) and the ice facet as steps: the moon is a stepped disc, the mane a stepped stack, the tufts stepped points.

## Parts

```yaml
parts:
  # the masses: a deep chest, the long torso, the big head
  - {name: Torso, slot: Body, size: [4.5, 4, 7.5], at: [0, 5.25, 0.75], bevel: true, material: fur}
  - {name: Chest, slot: Body, size: [4, 2.5, 2.5], at: [0, 4, -3], bevel: true, material: fur}
  - {name: Head, slot: Body, size: [6, 6, 5.5], at: [0, 10, -3.5], bevel: true, material: fur}
  - {name: Belly, slot: Accessory, size: [4.75, 1.5, 6], at: [0, 3.5, 0.75]}
  - {name: Haunch, slot: BodyDark, size: [1, 2.5, 2.75], at: [2.5, 5, 3.375], mirror: x, material: fur}
  - {name: ShoulderPlate, slot: Trim, size: [0.5, 1.5, 2], at: [2.5, 4.5, -2.75], mirror: x, material: metal}
  # four legs: an upper leg, a dark shin in a silver band, an oversized paw with three silver claws
  - {name: FrontLeg, slot: Body, size: [1.5, 1.5, 1.5], at: [1.5, 3, -2.75], mirror: x, material: fur}
  - {name: FrontShin, slot: BodyDark, size: [1.25, 1.25, 1.25], at: [1.5, 1.625, -2.75], mirror: x, material: fur}
  - {name: FrontBand, slot: Trim, size: [1.5, 0.25, 1.5], at: [1.5, 1.125, -2.75], mirror: x, material: metal}
  - {name: FrontPaw, slot: BodyDark, size: [1.75, 1, 2], at: [1.5, 0.5, -3], mirror: x, material: fur}
  - {name: Claw, slot: Trim, size: [0.25, 0.25, 0.5], at: [1, 0.125, -4], mirror: x, material: metal}
  - {name: Claw2, slot: Trim, size: [0.25, 0.25, 0.5], at: [1.5, 0.125, -4], mirror: x, material: metal}
  - {name: Claw3, slot: Trim, size: [0.25, 0.25, 0.5], at: [2, 0.125, -4], mirror: x, material: metal}
  - {name: HindLeg, slot: Body, size: [1.5, 1.5, 1.5], at: [1.5, 3, 3.25], mirror: x, material: fur}
  - {name: HindShin, slot: BodyDark, size: [1.25, 1.25, 1.25], at: [1.5, 1.625, 3.25], mirror: x, material: fur}
  - {name: HindBand, slot: Trim, size: [1.5, 0.25, 1.5], at: [1.5, 1.125, 3.25], mirror: x, material: metal}
  - {name: HindPaw, slot: BodyDark, size: [1.75, 1, 2], at: [1.5, 0.5, 3], mirror: x, material: fur}
  - {name: HindClaw, slot: Trim, size: [0.25, 0.25, 0.5], at: [1, 0.125, 2], mirror: x, material: metal}
  - {name: HindClaw2, slot: Trim, size: [0.25, 0.25, 0.5], at: [1.5, 0.125, 2], mirror: x, material: metal}
  - {name: HindClaw3, slot: Trim, size: [0.25, 0.25, 0.5], at: [2, 0.125, 2], mirror: x, material: metal}
  # three moon marks on each foreleg
  - {name: Mark, slot: Glow, size: [0.125, 0.5, 0.25], at: [2.3125, 3, -3.25], mirror: x}
  - {name: Mark2, slot: Glow, size: [0.125, 0.5, 0.25], at: [2.3125, 3, -2.75], mirror: x}
  - {name: Mark3, slot: Glow, size: [0.125, 0.5, 0.25], at: [2.3125, 3, -2.25], mirror: x}
  # the head's front: a black nose, two ice fangs hanging past the chin with stepped points
  - {name: Nose, slot: BodyDark, size: [1, 0.5, 0.375], at: [0, 8.5, -6.4375]}
  - {name: Fang, slot: Trim, size: [0.5, 1.5, 0.5], at: [1.25, 6.75, -6.25], mirror: x, material: ice}
  - {name: FangTip, slot: Trim, size: [0.5, 0.75, 0.5], at: [1.25, 5.625, -6.25], rot: [180, 0, 0], shape: cone6, mirror: x, material: ice}
  # the hero: a stepped moon of light on the forehead
  - {name: MoonA, slot: Glow, size: [1, 0.25, 0.25], at: [0, 12.375, -6.375]}
  - {name: MoonB, slot: Glow, size: [2, 0.5, 0.25], at: [0, 12, -6.375]}
  - {name: MoonC, slot: Glow, size: [2.5, 1, 0.25], at: [0, 11.25, -6.375]}
  - {name: MoonD, slot: Glow, size: [2, 0.5, 0.25], at: [0, 10.5, -6.375]}
  # ears with pale insides, each one moving part
  - {name: Ear, slot: Body, size: [1.5, 1.25, 0.75], at: [2, 13.25, -3.75], rot: [0, 0, -10], mirror: x, moves: ear, pivot: [1.75, 13, -3.75], material: fur}
  - {name: InnerEar, slot: Accessory, size: [1, 0.75, 0.125], at: [2, 13.25, -4.1875], rot: [0, 0, -10], mirror: x, moves: ear, pivot: [1.75, 13, -3.75]}
  # the mane: four slabs stepping down the neck, tufts out of the slab ends, a ruff along each cheek, five tufts along the ridge each tipped with moonlight
  - {name: ManeA, slot: BodyDark, size: [7, 1.5, 1.5], at: [0, 12, -0.25], material: fur}
  - {name: ManeB, slot: BodyDark, size: [7.5, 1.5, 1.5], at: [0, 10.5, 0.25], material: fur}
  - {name: ManeC, slot: BodyDark, size: [8, 1.5, 1.5], at: [0, 9, 0.75], material: fur}
  - {name: ManeD, slot: BodyDark, size: [7.5, 1.5, 1.5], at: [0, 7.5, 1.25], material: fur}
  - {name: ManeSide, slot: BodyDark, size: [1, 5, 1.5], at: [3.5, 10, -2], mirror: x, material: fur}
  - {name: SideTuft, slot: BodyDark, size: [0.75, 1.5, 0.75], at: [4.1875, 12.25, -0.25], rot: [0, 0, -70], shape: cone6, mirror: x, material: fur}
  - {name: SideTuft2, slot: BodyDark, size: [0.75, 1.5, 0.75], at: [4.4375, 10.75, 0.25], rot: [0, 0, -70], shape: cone6, mirror: x, material: fur}
  - {name: SideTuft3, slot: BodyDark, size: [0.75, 1.5, 0.75], at: [4.6875, 9.25, 0.75], rot: [0, 0, -70], shape: cone6, mirror: x, material: fur}
  - {name: Tuft, slot: BodyDark, size: [1, 1.5, 1], at: [0, 13.25, -0.25], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: Tuft2, slot: BodyDark, size: [1, 1.5, 1], at: [0, 11.75, 0.25], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: Tuft3, slot: BodyDark, size: [1, 1.25, 1], at: [0, 10.25, 0.75], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: Tuft4, slot: BodyDark, size: [1, 1.25, 1], at: [0, 8.75, 1.25], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: Tuft5, slot: BodyDark, size: [1, 1, 1], at: [0, 7.6875, 2.75], rot: [20, 0, 0], shape: cone6, material: fur}
  - {name: TuftLight, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 13.875, 0]}
  - {name: TuftLight2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 12.5, 0.5]}
  - {name: TuftLight3, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 10.875, 1]}
  - {name: TuftLight4, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 9.375, 1.5]}
  - {name: TuftLight5, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 8.125, 2.875]}
  # a ruff of three tufts under the chin
  - {name: ChinTuft, slot: BodyDark, size: [0.75, 1.25, 0.75], at: [0, 6.5, -5], rot: [200, 0, 0], shape: cone6, material: fur}
  - {name: ChinTuft2, slot: BodyDark, size: [0.75, 1.25, 0.75], at: [1.25, 6.5, -5], rot: [200, 0, -15], shape: cone6, mirror: x, material: fur}
  # the collar with three studs, and the chain: three links of cells down the chest, the last one broken, its ends lit
  - {name: Collar, slot: Trim, size: [4.5, 0.5, 0.5], at: [0, 5.5, -4.5], material: metal}
  - {name: CollarSide, slot: Trim, size: [0.5, 0.5, 2.5], at: [2.25, 5.5, -3], mirror: x, material: metal}
  - {name: Stud, slot: Trim, size: [0.25, 0.25, 0.25], at: [0, 5.5, -4.875], material: metal}
  - {name: Stud2, slot: Trim, size: [0.25, 0.25, 0.25], at: [1.5, 5.5, -4.875], mirror: x, material: metal}
  - {name: Link1Top, slot: Trim, size: [1, 0.25, 0.25], at: [0, 5.125, -4.875], material: metal}
  - {name: Link1Side, slot: Trim, size: [0.25, 0.5, 0.25], at: [0.375, 4.75, -4.875], mirror: x, material: metal}
  - {name: Link1Bot, slot: Trim, size: [1, 0.25, 0.25], at: [0, 4.375, -4.875], material: metal}
  - {name: Link2Top, slot: Trim, size: [0.25, 0.25, 1], at: [0, 4.125, -4.875], material: metal}
  - {name: Link2Front, slot: Trim, size: [0.25, 0.5, 0.25], at: [0, 3.75, -5.25], material: metal}
  - {name: Link2Back, slot: Trim, size: [0.25, 0.5, 0.25], at: [0, 3.75, -4.5], material: metal}
  - {name: Link2Bot, slot: Trim, size: [0.25, 0.25, 1], at: [0, 3.375, -4.875], material: metal}
  - {name: Link3Top, slot: Trim, size: [1, 0.25, 0.25], at: [0, 3.125, -4.875], material: metal}
  - {name: Link3Side, slot: Trim, size: [0.25, 0.5, 0.25], at: [0.375, 2.75, -4.875], mirror: x, material: metal}
  - {name: LinkEnd, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.375, 2.375, -4.875], mirror: x}
  # a moon rune glowing on each flank
  - {name: Rune, slot: Glow, size: [0.125, 1.5, 0.25], at: [2.3125, 5.5, 1], mirror: x}
  - {name: Rune2, slot: Glow, size: [0.125, 0.375, 0.75], at: [2.3125, 6.4375, 0.75], mirror: x}
  - {name: Rune3, slot: Glow, size: [0.125, 0.375, 0.75], at: [2.3125, 4.5625, 0.75], mirror: x}
  # the tail, held low and stiff, split at the tip round a core of light; one moving part
  - {name: Tail, slot: Body, size: [1.5, 1.25, 3.5], at: [0, 5.5, 6.25], moves: tail, pivot: [0, 5.75, 4.5], material: fur}
  - {name: TailTip, slot: BodyDark, size: [0.75, 1.25, 1.25], at: [0.5, 5.375, 8.625], mirror: x, moves: tail, pivot: [0, 5.75, 4.5], material: fur}
  - {name: TailCore, slot: Glow, size: [0.5, 0.5, 0.75], at: [0, 5.5, 8.375], moves: tail, pivot: [0, 5.75, 4.5]}
  # the floating accessory: a moon orb between the ears, the foot of the howl's beam
  - {name: Orb, slot: Glow, size: [1, 1, 1], at: [0, 13.5, -3.5], shape: ico1, moves: float, pivot: [0, 13.5, -3.5]}
```

## Face

The house face, 16 cells across the 6-stud head (0.375 studs a cell, so 16 rows for the square front). The eyes sit low (rows 8 to 13) under the moon (rows 1 to 6 of the front carry it as a proud glow block); a pale muzzle (`c`, the accent) is drawn round the mouth under the nose block; the eye's lit crescent is the moon's glow. Option B on the review sheet adds two rows of brow cells (`b`, the ink) over each eye and lights the crescent in the full-moon white of the glow cycle.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9DBB"
    "c": accent
  rows:
    - "................"
    - "................"
    - "................"
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
    - "...gg.kcck.gg..."
    - "..pp.cckkcc.pp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Fenripup.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Fenripup.md --out <scratch>` ([[Blocky-Style]] "The pipeline"). Option B is a scratch copy of this note with the brow rows and the moon-lit glow, built the same way for the sheet only.

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Fenripup_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads): the moonlight beam from the orb, the moon-dust orbit, the rune ring, the sparks on the mane tips, the cold light.

![[Fenripup_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Fenripup_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs and the two face options: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.375 studs (2.7 a stud), 37 cells tall. Materials: `fur` on every coat part (the head, torso, chest, legs, mane, tail: tufts on a lattice, lit on the tops), `ice` on the fangs, `metal` on the plates, bands, claws, collar and chain, glow cells on the moon, the marks, the runes, the tuft lights, the chain ends, the tail core and the orb.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: a 5.5-stud head on a 14-stud wolf fell under rule 2's 40 percent, so the head is 6 studs (16 cells of 0.375, Raddis's cell) and the ears and tufts shortened to keep 14; a fifth moon row touched the eyes' top row, so the moon is four rows with a quarter stud of brow between. The chain's interlocking links shared faces where they crossed (they would shimmer), so each link hangs from the one above, touching. Round 2: the first build's mane read as a dark staircase behind the head, so each of the top three slabs got a tuft pointing out of each end (the mane is now 10 studs across and ragged, a ruff rather than a stack) and the ears grew from nubs to a stud and a half, set into the head's top so the height stays 14; the cheek ruffs and the chin tufts close the ring. Overlap 0.996 to 0.999, 1,436 triangles, 110 blocks, 14 studs, four moving objects (the ears, the tail, the orb). Wanted for: the most impressive thing in Frostbyte, a mount with a moon on its brow and a chain it broke. Still cheap: from the side the torso is a long box between the mane and the haunches; the leg marks are thin; 16 face cells over 6 studs are big pixels in a close-up (the Cosmic close-up question open in [[Blocky-Style]]). Status review, two face options on the sheet for Ethan.
