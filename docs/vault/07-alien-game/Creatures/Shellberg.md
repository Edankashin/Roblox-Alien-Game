---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Shellberg
name: Floe
world: 2
tier: Rare
status: review
element: Iceberg
height: 3
blocks: 19
tris: 292
bevel_width: 0.1
bevel_segments: 2
palette: ["#3FBFB0", "#1F6F68", "#D3E6F5", "#8CC8F0", "#2ED3F7", "#0F2A2E"]
roles: [body, second, accent, trim, glow, ink]
hero: Peak
vfx: "a soft light (Rare): a cold mist rolls off the iceberg shell at 3 a second and pools at its feet (Effects.luau, the Wisp emitter at Back, falling); the peak glints every 4 s (the Sparkle at Top); the frost glyphs on the berg's sides are lit cells and a soft blue light hangs over the shell; it breathes 2 percent, very slowly; no moving parts"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Shellberg_sheet.svg]]"
render: "[[Shellberg_tq_cells.jpg]]"
glb: ""
overlap: [0.998, 0.997, 0.999, 0.999]
vfx_render: "[[Shellberg_vfx_cells.jpg]]"
cells_render: "[[Shellberg_tq_cells.jpg]]"
---
# Shellberg (Floe), Rare, World 2 Frostbyte

A teal tortoise whose shell is an iceberg, and the iceberg is nine-tenths hidden: all that shows above its white waterline is a stepped peak of snow off to its right and a smaller one on the shelf to its left (no iceberg is symmetric), while the great blue mass of the berg sits below the line, over the tortoise's back, down to its feet. The patient round head pokes out the front, four dark feet and a stub tail poke out from under, and a frost glyph glows on each side of the berg. Concept row in `src/shared/data/Species.luau`: "tortoise, iceberg shell, nine-tenths hidden". Element and effect: [[Roster-Redesign]] section 2 (a cold mist rolls off the shell and pools at its feet; the shell glints; a soft blue light). Rules: [[Blocky-Style]].

**What makes a player want it.** A joke, on purpose: it wears the whole iceberg, so the famous hidden nine-tenths is right there in plain view, and the little white tip on top is what it thinks you can see. The patient face is the punchline. The Rare rung exactly: a stamped element glyph (the lit frost glyph on each side), one glossy trim slot (the berg's frozen water) and a soft light, at 3 studs to Soakum's 2.75.

**Hero block.** The `Peak`, the stepped snow tip above the waterline, four steps of two cells each leaning to one side: unique in Frostbyte.

**Alien anatomy.** The shell is ice, not bone, and most of it hangs below the waterline it carries round with it; the tortoise is nine-tenths inside its own iceberg, with only the head, the feet and the tail out.

**World motif (Frostbyte).** The ice facet as steps: the berg steps in twice below the line and the peak steps up four times above it; the six-point frost glyph on each side in eighth-stud lit cells; `frozen_water` plates and cracks over the berg.

## Parts

```yaml
parts:
  # four dark feet and a stub tail out from under the berg
  - {name: Foot, slot: BodyDark, size: [0.625, 0.375, 0.75], at: [0.9375, 0.1875, -0.5], mirror: x}
  - {name: HindFoot, slot: BodyDark, size: [0.625, 0.375, 0.75], at: [0.9375, 0.1875, 1.25], mirror: x}
  - {name: Tail, slot: BodyDark, size: [0.25, 0.375, 0.5], at: [0, 0.8125, 2.25]}
  # the head pokes out the front, bevelled
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, -1.5], bevel: true}
  # the berg below the waterline: two steps of frozen water, glossy, the trim slot
  - {name: BergBase, slot: Trim, size: [2.5, 0.75, 2.75], at: [0, 0.75, 0.625], material: frozen_water}
  - {name: BergMid, slot: Trim, size: [2.25, 0.75, 2.5], at: [0, 1.5, 0.75], material: frozen_water}
  # the waterline, a rim of snow proud all round with a shelf out to its left, and the hero: the stepped snow peak above it, off to the right
  # (no iceberg is symmetric), with a smaller second peak on the shelf side
  - {name: Waterline, slot: Accessory, size: [3.25, 0.125, 3], at: [-0.25, 1.9375, 0.625], material: snow}
  - {name: Peak, slot: Accessory, size: [2, 0.25, 2], at: [0.25, 2.125, 0.625], material: snow}
  - {name: Peak2, slot: Accessory, size: [1.5, 0.25, 1.5], at: [0.5, 2.375, 0.625], material: snow}
  - {name: Peak3, slot: Accessory, size: [1, 0.25, 1], at: [0.75, 2.625, 0.625], material: snow}
  - {name: Peak4, slot: Accessory, size: [0.5, 0.25, 0.5], at: [0.875, 2.875, 0.625], material: snow}
  - {name: Peak5, slot: Accessory, size: [0.75, 0.25, 0.75], at: [-1.125, 2.125, 0.375], material: snow}
  - {name: Peak6, slot: Accessory, size: [0.25, 0.25, 0.25], at: [-1.125, 2.375, 0.375], material: snow}
  # the stamped element glyph: a frost glyph of lit cells on each side of the berg (a plus of quarter-stud cells)
  - {name: Glyph, slot: Glow, size: [0.125, 0.75, 0.25], at: [1.3125, 0.75, 0.75], mirror: x}
  - {name: Glyph2, slot: Glow, size: [0.125, 0.25, 0.75], at: [1.3125, 0.75, 0.75], mirror: x}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 10 rows for the 1.25-stud front. A patient closed smile; the eye's lit crescent is the glyphs' cyan glow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF8FA3"
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

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Shellberg.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Shellberg.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Shellberg_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Shellberg_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Shellberg_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 24 cells tall. Materials: `frozen_water` on the berg (plates parted by cracks, a trapped bubble, no grout, glossy), `snow` on the waterline and the peak (each step two cells tall, so its lip covers the whole side), the glyphs in glow cells, skin on the teal head, feet and tail.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: a symmetric berg with a centred peak was the worst shape in the row (0.80 with Dreep, 0.82 with Eekle, 0.79 with Soakum), so the peak leans to its right, the waterline shelves out to its left and a second small peak stands on the shelf. Round 2: a white peak (L* 97) vanished against the backdrop and the iceberg joke with it, so the accent is a tinted snow. Overlap 0.997 to 0.999, 292 triangles, 19 blocks, 3 studs, no moving parts (it breathes, slowly). Wanted for: a tortoise wearing a whole iceberg, the hidden nine-tenths in plain view. Still cheap: the head's back is inside the berg; the feet are four plain blocks. Status review.
