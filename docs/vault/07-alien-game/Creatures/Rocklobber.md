---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Rocklobber
name: Boulden
world: 1
tier: Rare
status: review
element: Stone
height: 3
blocks: 21
tris: 338
bevel_width: 0.1
bevel_segments: 2
palette: ["#C8553D", "#3A3238", "#A39E94", "#E0B04A", "#FFB347", "#1C1418"]
roles: [body, second, accent, trim, glow, ink]
hero: Claw
vfx: "a soft light (Rare): the amber gem in each boulder claw glows and a warm light hangs over it; the claws clack together every 5 s with a dust puff and two pebble chips (Effects.luau's grey FrontL and Feet emitters); it shuffles sideways 0.2 studs"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Rocklobber_sheet.svg]]"
render: "[[Rocklobber_tq_cells.jpg]]"
glb: ""
overlap: [0.997, 0.994, 1, 0.997]
vfx_render: "[[Rocklobber_vfx_cells.jpg]]"
cells_render: "[[Rocklobber_tq_cells.jpg]]"
---
# Rocklobber (Boulden), Rare, World 1 Verdant

A rust-red crab whose claws are boulders: a wide low shell (the head, with the face) under a dark carapace rim, six thin dark legs, two short arms ending in grey stone boulders each bigger than its head, a stone thumb on each boulder to make the pincer and an amber gem set in each boulder's face that glows. One antenna with a pebble on its tip bobs over the shell, and a gold cairn glyph is stamped on the carapace. Concept row in `src/shared/data/Species.luau`: "crab, boulder claws". Element and effect: [[Roster-Redesign]] section 2 (Stone; the claws clack with a dust puff). Rules: [[Blocky-Style]].

**What makes a player want it.** The claws are absurd: two boulders on a crab the size of a shoe, held up like trophies, and they clack. It is the Rare rung exactly: a stamped element glyph (the gold cairn on the carapace), one glossy trim slot (the glyph) and a soft light (the amber gems), at 3 studs to Snibble's 2.75.

**Hero block.** The `Claw` pair, boulders of grey stone with an amber gem each, unique in Verdant.

**Alien anatomy.** Claws of rock it did not grow, six legs, and a single antenna with a pebble on it; three moving objects: the two claws (the `jaw` pair the game clacks) and the antenna.

**World motif (Verdant).** The moss cell as the eighth-stud cells of the cairn glyph and the cobbles of the stone motif on the boulders.

## Parts

```yaml
parts:
  # six thin legs under the shell
  - {name: Leg, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1, 0.25, -0.625], mirror: x}
  - {name: MidLeg, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1, 0.25, 0], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [1, 0.25, 0.625], mirror: x}
  # the shell: a wide low block with the face, a dark carapace rim proud over it
  - {name: Head, slot: Body, size: [2, 1.25, 1.75], at: [0, 1.125, 0], bevel: true}
  - {name: Carapace, slot: BodyDark, size: [2.25, 0.25, 2], at: [0, 1.875, 0]}
  # the hero: two short arms, a boulder on each with a stone thumb for the pincer and an amber gem set in its face (the pair that clacks)
  - {name: Arm, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [1.25, 1.25, -0.75], mirror: x}
  - {name: Claw, slot: Accessory, size: [1.25, 1.25, 1.25], at: [1.875, 1.625, -1], mirror: x, moves: jaw, pivot: [1.25, 1.25, -0.75], material: stone}
  - {name: Thumb, slot: Accessory, size: [0.5, 0.5, 0.5], at: [1.875, 2.5, -1.25], mirror: x, moves: jaw, pivot: [1.25, 1.25, -0.75], material: stone}
  - {name: Gem, slot: Glow, size: [0.25, 0.25, 0.25], at: [2, 1.75, -1.75], mirror: x, moves: jaw, pivot: [1.25, 1.25, -0.75]}
  # one antenna with a pebble on its tip (the antenna the game bobs)
  - {name: Antenna, slot: BodyDark, size: [0.125, 0.75, 0.125], at: [0.3125, 2.375, 0.0625], moves: antenna, pivot: [0.3125, 2, 0.0625]}
  - {name: AntennaPebble, slot: Accessory, size: [0.375, 0.25, 0.375], at: [0.3125, 2.875, 0.0625], moves: antenna, pivot: [0.3125, 2, 0.0625], material: stone}
  # the stamped element glyph: a gold cairn of three stepped cells on the carapace, where the game camera sees it
  - {name: Glyph, slot: Trim, size: [0.75, 0.125, 0.25], at: [-0.375, 2.0625, 0.75], material: metal}
  - {name: Glyph2, slot: Trim, size: [0.5, 0.125, 0.25], at: [-0.375, 2.0625, 0.5], material: metal}
  - {name: Glyph3, slot: Trim, size: [0.25, 0.125, 0.25], at: [-0.375, 2.0625, 0.25], material: metal}
```

## Face

The house face on the shell's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. The eye's lit crescent is the gem's amber.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF9C8A"
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Rocklobber.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Rocklobber.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, with block cells (Blender, Cycles):

![[Rocklobber_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Rocklobber_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Rocklobber_sheet.svg]] (flat shapes and text, for the Claude Design canvas).

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 24 cells tall; one atlas of 512 x 1024 at 8 texels a cell (121 islands). Materials: stone on the boulders, the thumbs and the antenna pebble (cobbles and cracks), metal on the gold glyph, skin elsewhere; the gems are glow cells.

## Reviews

- 2026-10-19, World 1 roster worker, two rounds. Round 1: the boulder claws read at once and the amber gems carry the Rare's light, but the gold cairn glyph on the flanks sat behind the claws where no camera saw it, and a bevelled claw could not move. Round 2: the claws plain stone boxes on the `jaw` pair, the glyph moved to the carapace. Wanted for: two boulders on a crab the size of a shoe that clack. Still cheap: the shell between the claws is small and flat; the legs are thin posts. Status review.
