---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Sparkfox
name: Vixa
world: 1
tier: Rare
status: review
element: Ember
height: 3
blocks: 29
tris: 508
bevel_width: 0.1
bevel_segments: 2
palette: ["#FF7A30", "#FFF1DD", "#4A2433", "#FFC940", "#FFA53D", "#24141A"]
roles: [body, second, accent, trim, glow, ink]
hero: Brush
vfx: "a soft light (Rare): the brush tip glows and an amber light hangs at the tail; a short paint-spark trail while it moves (0.4 s) and ember sparks off the brush at 8 a second (Effects.luau); at rest the floating paint drop falls from the brush and reforms every 4 s"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Sparkfox_sheet.svg]]"
render: "[[Sparkfox_tq.jpg]]"
glb: ""
overlap: [0.994, 0.996, 0.997, 0.995]
vfx_render: "[[Sparkfox_vfx.jpg]]"
cells_render: "[[Sparkfox_tq_cells.jpg]]"
---
# Sparkfox (Vixa), Rare, World 1 Verdant

An orange fox with a square head, a cream muzzle drawn into the house face, stepped ears with plum tips and cream insides, plum socks, and a tail that is a paintbrush: a plum handle, a glossy gold ferrule and orange fur bristles tapering to a tip dipped in glowing amber paint, leaning back and out to its right. A paint drop floats beside the brush, and a gold flame is stamped on each flank. Concept row in `src/shared/data/Species.luau`: "fox, glowing paintbrush tail". Element: Ember (`Effects.luau`); [[Roster-Redesign]] section 2 gives the paint-spark trail, the falling drop and the soft orange light. Rules: [[Blocky-Style]].

**What makes a player want it.** It is the first creature on the meadow that gives off light: the brush tip glows and paints sparks behind it, so it is the one you spot at dusk. The Rare rung, exactly: a stamped element glyph (the gold flame), one glossy trim slot (the ferrule and the flame) and a soft light, at 3 studs to Buzzik's 2.4.

**Hero block.** The `Brush`, the orange bristle head of the tail, with its gold ferrule and plum handle under it and its glowing tip over it: unique in Verdant, and the tail part the game swishes every 4 s.

**Alien anatomy.** The tail is a tool, not fur, and the paint drop floats free of it (the `float` part); four moving objects: the tail, the drop and the two ears.

**World motif (Verdant).** The moss cell, here as the half-stud steps of the ears and the brush and the eighth-stud pixels of the flame.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [2, 1.5, 1.5], at: [0, 1.5, -0.75], bevel: true}
  - {name: Body, slot: Body, size: [1.5, 1, 2], at: [0, 1, 0.75], bevel: true}
  - {name: FrontLeg, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, -0.5], mirror: x}
  - {name: HindLeg, slot: Accessory, size: [0.5, 0.5, 0.5], at: [0.5, 0.25, 1.5], mirror: x}
  # stepped fox ears: an orange base, a plum tip and a cream inside, each ear one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.5, 0.25], at: [0.625, 2.5, -0.875], mirror: x, moves: ear, pivot: [0.625, 2.25, -0.875]}
  - {name: EarTip, slot: Accessory, size: [0.25, 0.25, 0.25], at: [0.625, 2.875, -0.875], mirror: x, moves: ear, pivot: [0.625, 2.25, -0.875]}
  - {name: InnerEar, slot: BodyDark, size: [0.25, 0.25, 0.125], at: [0.625, 2.375, -1.0625], mirror: x, moves: ear, pivot: [0.625, 2.25, -0.875]}
  # the hero: the paintbrush tail, leaning back and out to the right: a plum handle, a glossy gold ferrule, a head of orange fur bristles tapering to a point dipped in glowing paint
  - {name: Tail, slot: Accessory, size: [0.375, 0.5, 0.375], at: [0.4375, 1.3125, 1.875], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: Ferrule, slot: Trim, size: [0.625, 0.25, 0.625], at: [0.5625, 1.6875, 2], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75], material: metal}
  - {name: Brush, slot: Body, size: [0.875, 0.5, 0.875], at: [0.6875, 2, 2.1875], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: Brush2, slot: Body, size: [0.75, 0.25, 0.75], at: [0.8125, 2.3125, 2.3125], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: BrushTip, slot: Glow, size: [0.5, 0.25, 0.5], at: [0.875, 2.5, 2.4375], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  - {name: BrushTip2, slot: Glow, size: [0.25, 0.25, 0.25], at: [0.9375, 2.75, 2.5625], rot: [25, 0, -20], moves: tail, pivot: [0.375, 1.125, 1.75]}
  # alien anatomy: a drop of glowing paint floating free beside the brush
  - {name: Drop, slot: Glow, size: [0.25, 0.375, 0.25], at: [1.5, 2.1875, 2.75], shape: ico1, moves: float, pivot: [1.5, 2.1875, 2.75]}
  # the stamped element glyph: a gold pixel flame on each flank (rows of eighth-stud cells, bottom to top)
  - {name: Flame, slot: Trim, size: [0.125, 0.125, 0.375], at: [0.8125, 0.6875, 0.8125], mirror: x}
  - {name: Flame2, slot: Trim, size: [0.125, 0.25, 0.625], at: [0.8125, 0.875, 0.8125], mirror: x}
  - {name: Flame3, slot: Trim, size: [0.125, 0.125, 0.375], at: [0.8125, 1.0625, 0.8125], mirror: x}
  - {name: Flame4, slot: Trim, size: [0.125, 0.125, 0.25], at: [0.8125, 1.1875, 0.75], mirror: x}
  - {name: Flame5, slot: Trim, size: [0.125, 0.125, 0.125], at: [0.8125, 1.3125, 0.8125], mirror: x}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front. A cream muzzle (`c`, the second colour) is drawn round the mouth; the eye's lit crescent is the paint's glow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF6F91"
    "c": second
  rows:
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
    - "......cccc......"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Sparkfox.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Sparkfox.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Sparkfox_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Sparkfox_vfx.jpg]]

The concept sheet, drawn from the parts table above: [[Sparkfox_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Sparkfox_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Sparkfox_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.125 studs (8.0 a stud), 24 cells tall; one atlas of 512 x 1024 at 8 texels a cell (154 islands). Materials: metal on the ferrule, skin elsewhere; the brush tip and the drop are glow cells.

![[Sparkfox_tq_cells.jpg]]

![[Sparkfox_vfx_cells.jpg]]

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: a cream brush on a pale sky read as a floating cloud, not joined to the fox. Round 2: the tail as one tilted stack (handle, ferrule, bristles, tip) that grows out of the rump; still pale, and the cube head of the brush read as a mallet. Round 3: a plum handle and orange bristles tapering in two steps to a lit point, the amber paint drop floating free; the tail lowered an eighth to keep 3 studs. Overlap 0.994 to 0.997, 548 triangles, 29 blocks, 3 studs. Wanted for: the first light on the meadow and a tail that is a paintbrush, with a stamped gold flame. Still cheap: the Rare preview is only a soft light (as the ladder says), so at night it is a lit tail and little else; the drop is small at distance. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The orange keeps its punch; the cream muzzle cells sit in the face grid as before; the gold flame stays flat (detail blocks under three cells take no edge). Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
