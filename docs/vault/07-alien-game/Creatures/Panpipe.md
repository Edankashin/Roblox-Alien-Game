---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Panpipe
name: Syrinx
world: 1
tier: Secret
status: review
element: Shadow
height: 13
blocks: 108
tris: 1350
bevel_width: 0.25
bevel_segments: 2
palette: ["#4A4166", "#1E1A2E", "#8E6BFF", "#8C86A6", "#B28CFF", "#0B0812"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#B28CFF", "#7A3CFF", "#E2D6FF"]
arcs: ["PipeMouth>PipeMouth4", "PipeMouth2>PipeMouth5"]
hero: Pipe
vfx: "the Cosmic set in shadow: the pipe mouths, the horn rings, the sound bars, the bell's clapper and the floating note glow and step through violet, deep violet and lilac every 2 s (its own palette only); notes drift from the pipes on a trill every 4 s and fall instead of rise; dark smoke falls at its hooves; a violet orbit and a slow violet ring under it; a shadow trail; the flourish is a hop and a vanish-and-return"
ride: "Stride; the rider sits on the saddle blanket (4.75 by 3 studs, 6.75 studs up), between the head and the pipes"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Panpipe_sheet.svg]]"
render: "[[Panpipe_tq.jpg]]"
glb: ""
overlap: [0.997, 0.996, 0.998, 0.997]
vfx_render: "[[Panpipe_vfx.jpg]]"
cells_render: "[[Panpipe_tq_cells.jpg]]"
---
# Panpipe (Syrinx), Secret, World 1 Verdant

A great shadow goat, slate and near-black, the Cosmic rung's detail in a dark palette with one accent, violet. Six dark reed pipes step down across its rump from right to left, their mouths and lips lit and bound in pewter bands; four pewter horns crown its head (a big pair that arches up and back like an ibex's, with a lit violet band, a dark ridge and lit tips, and a small pair leaning forward with lit tips); a dark beard, a pewter bell with a lit clapper, droopy ears with violet tips, shaggy dark wool hanging from its flanks and rump, cloven pewter hooves and a dark saddle blanket with a pewter pommel whose drapes carry lit sound bars. A lit music note floats over its left shoulder. Concept row in `src/shared/data/Species.luau`: "goat, reed pipes". Element: Shadow (`Effects.luau`); [[Roster-Redesign]] section 2 gives the drifting notes, the falling shadow, the turning ring and the vanish-and-return. Rules: [[Blocky-Style]].

**What makes a player want it.** It is the one dark thing in a bright meadow: 13 studs of shadow, 2.6 avatars, that glows only in violet and plays a trill every 4 s, and it is a mount. Its face is the same soft house face as Moop's, so it reads as a gentle giant you were lucky to meet, not a boss.

**Hero block.** The `Pipe` set, a panpipe the size of a church organ on a goat's back, unique in Verdant.

**Alien anatomy.** Four horns, a floating note that follows it (the `float` part) and an instrument grown into its back; four moving objects: the note, the two ears and the tail.

**World motif (Verdant).** The moss cell in shadow: the half-stud steps of the horns, the beard and the hanging wool.

## Parts

```yaml
parts:
  - {name: Head, slot: Body, size: [5.5, 5.5, 4.5], at: [0, 7, -2.5], bevel: true, material: wool}
  - {name: Torso, slot: Body, size: [4.5, 3.75, 7], at: [0, 4.625, 2.5], bevel: true, material: wool}
  # four legs on cloven pewter hooves, a wool fetlock over each
  - {name: FrontLeg, slot: BodyDark, size: [1, 2.25, 1], at: [1.375, 1.625, -0.25], mirror: x}
  - {name: FrontFetlock, slot: Body, size: [1.25, 0.375, 1.25], at: [1.375, 0.6875, -0.25], mirror: x, material: wool}
  - {name: FrontHoof, slot: Trim, size: [0.5, 0.5, 1.25], at: [1.125, 0.25, -0.25], mirror: x}
  - {name: FrontHoof2, slot: Trim, size: [0.5, 0.5, 1.25], at: [1.75, 0.25, -0.25], mirror: x}
  - {name: HindLeg, slot: BodyDark, size: [1, 2.25, 1], at: [1.375, 1.625, 5.25], mirror: x}
  - {name: HindFetlock, slot: Body, size: [1.25, 0.375, 1.25], at: [1.375, 0.6875, 5.25], mirror: x, material: wool}
  - {name: HindHoof, slot: Trim, size: [0.5, 0.5, 1.25], at: [1.125, 0.25, 5.25], mirror: x}
  - {name: HindHoof2, slot: Trim, size: [0.5, 0.5, 1.25], at: [1.75, 0.25, 5.25], mirror: x}
  # a goat's beard under the chin and a pewter bell with a lit clapper under it
  - {name: Beard, slot: BodyDark, size: [1.75, 0.5, 0.75], at: [0, 4, -4.25], material: wool}
  - {name: Beard2, slot: BodyDark, size: [1.25, 0.5, 0.5], at: [0, 3.5, -4.25], material: wool}
  - {name: Beard3, slot: BodyDark, size: [0.5, 0.5, 0.5], at: [0, 3, -4.25], material: wool}
  - {name: Bell, slot: Trim, size: [0.75, 0.75, 0.75], at: [1.25, 3.375, -3.5], material: metal}
  - {name: BellStrap, slot: Accessory, size: [0.25, 0.75, 0.25], at: [1.25, 4.125, -3.5]}
  - {name: Clapper, slot: Glow, size: [0.25, 0.25, 0.25], at: [1.25, 2.875, -3.5]}
  - {name: Forelock, slot: BodyDark, size: [1.5, 0.5, 1.5], at: [0, 10, -2.75], material: wool}
  # a lit rune low on each side of the head, a note on its side
  - {name: Rune, slot: Glow, size: [0.125, 0.75, 0.25], at: [2.8125, 6.125, -1], mirror: x}
  - {name: Rune2, slot: Glow, size: [0.125, 0.25, 0.5], at: [2.8125, 5.875, -1.25], mirror: x}
  # droopy ears with violet tips, each one moving part
  - {name: Ear, slot: Body, size: [1.25, 0.375, 1], at: [3.3125, 8, -2.5], rot: [0, 0, -25], mirror: x, moves: ear, pivot: [2.75, 8.25, -2.5], material: wool}
  - {name: EarTip, slot: Accessory, size: [0.5, 0.375, 1], at: [4.125, 7.625, -2.5], rot: [0, 0, -25], mirror: x, moves: ear, pivot: [2.75, 8.25, -2.5]}
  # alien anatomy: four horns; the big pair arches up and back like an ibex's, a lit violet band and a dark ridge on each, lit tips; a small pair leans forward
  - {name: Horn, slot: Trim, size: [1, 1, 1], at: [1.625, 10, -2.375], rot: [12, 0, -15], mirror: x, material: metal}
  - {name: HornRing, slot: Glow, size: [1.125, 0.25, 1.125], at: [1.8125, 10.5625, -2.25], rot: [22, 0, -15], mirror: x}
  - {name: Horn2, slot: Trim, size: [0.875, 0.875, 0.875], at: [1.9375, 11.0625, -2.0625], rot: [22, 0, -15], mirror: x, material: metal}
  - {name: HornRidge, slot: BodyDark, size: [1, 0.125, 1], at: [2.0625, 11.5, -1.875], rot: [25, 0, -15], mirror: x}
  - {name: Horn3, slot: Trim, size: [0.75, 0.625, 0.75], at: [2.125, 11.8125, -1.6875], rot: [25, 0, -15], mirror: x, material: metal}
  - {name: HornRing2, slot: Glow, size: [0.875, 0.125, 0.875], at: [2.1875, 12.1875, -1.5], rot: [25, 0, -15], mirror: x}
  - {name: Horn4, slot: Trim, size: [0.625, 0.75, 0.625], at: [2.25, 12.375, -1.1875], rot: [65, 0, -15], mirror: x, material: metal}
  - {name: HornTip, slot: Glow, size: [0.5, 0.5, 0.5], at: [2.3125, 12.5625, -0.5625], rot: [75, 0, -15], mirror: x}
  # chain end at [2.344, 12.65, -0.338]
  - {name: SmallHorn, slot: Trim, size: [0.5, 1.25, 0.5], at: [0.875, 10.375, -3.9375], rot: [-15, 0, 0], mirror: x, material: metal}
  - {name: SmallHornTip, slot: Glow, size: [0.375, 0.375, 0.375], at: [0.9375, 11.0625, -4.0625], shape: ico1, mirror: x}
  # the saddle: a dark blanket over the back with violet hems and lit sound bars on its drapes (the rider sits in front of the pipes)
  - {name: Pommel, slot: Trim, size: [1, 0.5, 0.5], at: [0, 7, 0.5], material: metal}
  - {name: Blanket, slot: BodyDark, size: [4.75, 0.25, 3], at: [0, 6.625, 1.75]}
  - {name: Drape, slot: BodyDark, size: [0.125, 1.5, 3], at: [2.3125, 6, 1.75], mirror: x}
  - {name: Hem, slot: Accessory, size: [0.125, 0.25, 3], at: [2.3125, 5.125, 1.75], mirror: x}
  - {name: SoundBar, slot: Glow, size: [0.125, 0.5, 0.25], at: [2.4375, 5.75, 1.125], mirror: x}
  - {name: SoundBar2, slot: Glow, size: [0.125, 0.75, 0.25], at: [2.4375, 5.875, 1.75], mirror: x}
  - {name: SoundBar3, slot: Glow, size: [0.125, 1, 0.25], at: [2.4375, 6, 2.375], mirror: x}
  # shaggy dark wool hanging from the flanks and the rump, in uneven lengths
  - {name: Fringe, slot: BodyDark, size: [0.25, 1, 0.75], at: [2.25, 2.75, -0.5], mirror: x, material: wool}
  - {name: Fringe2, slot: BodyDark, size: [0.25, 0.75, 0.75], at: [2.25, 2.875, 0.75], mirror: x, material: wool}
  - {name: Fringe3, slot: BodyDark, size: [0.25, 1.25, 0.75], at: [2.25, 2.625, 2], mirror: x, material: wool}
  - {name: Fringe4, slot: BodyDark, size: [0.25, 0.75, 0.75], at: [2.25, 2.875, 3.25], mirror: x, material: wool}
  - {name: Fringe5, slot: BodyDark, size: [0.25, 1, 0.75], at: [2.25, 2.75, 4.25], mirror: x, material: wool}
  - {name: RumpFringe, slot: BodyDark, size: [1.5, 1, 0.25], at: [1, 3, 6.125], mirror: x, material: wool}
  - {name: SpineTuft, slot: BodyDark, size: [1, 0.25, 0.75], at: [0, 6.625, 5.125], material: wool}
  - {name: Tail, slot: BodyDark, size: [0.5, 1, 0.5], at: [0, 7, 5.75], moves: tail, pivot: [0, 6.5, 5.75]}
  - {name: TailTip, slot: Glow, size: [0.25, 0.25, 0.25], at: [0, 7.625, 5.75], moves: tail, pivot: [0, 6.5, 5.75]}
  - {name: Mane, slot: BodyDark, size: [2.5, 2, 0.5], at: [0, 8.5, 0], material: wool}
  - {name: Fleece, slot: BodyDark, size: [0.125, 0.75, 1], at: [2.3125, 4.625, 4.5], mirror: x, material: wool}
  # the hero: the reed pipes, six dark reeds stepping down from the right to the left across the rump, mouths lit, bound by two pewter bands
  - {name: Pipe, slot: BodyDark, size: [0.75, 6.5, 0.75], at: [1.875, 9.5, 4.25], material: wood}
  - {name: PipeMouth, slot: Glow, size: [0.75, 0.25, 0.75], at: [1.875, 12.875, 4.25]}
  - {name: PipeLip, slot: Glow, size: [0.5, 0.25, 0.125], at: [1.875, 11.875, 3.8125]}
  - {name: Pipe2, slot: BodyDark, size: [0.75, 5.75, 0.75], at: [1.125, 9.125, 4.25], material: wood}
  - {name: PipeMouth2, slot: Glow, size: [0.75, 0.25, 0.75], at: [1.125, 12.125, 4.25]}
  - {name: PipeLip2, slot: Glow, size: [0.5, 0.25, 0.125], at: [1.125, 11.125, 3.8125]}
  - {name: Pipe3, slot: BodyDark, size: [0.75, 5, 0.75], at: [0.375, 8.75, 4.25], material: wood}
  - {name: PipeMouth3, slot: Glow, size: [0.75, 0.25, 0.75], at: [0.375, 11.375, 4.25]}
  - {name: PipeLip3, slot: Glow, size: [0.5, 0.25, 0.125], at: [0.375, 10.375, 3.8125]}
  - {name: Pipe4, slot: BodyDark, size: [0.75, 4.25, 0.75], at: [-0.375, 8.375, 4.25], material: wood}
  - {name: PipeMouth4, slot: Glow, size: [0.75, 0.25, 0.75], at: [-0.375, 10.625, 4.25]}
  - {name: PipeLip4, slot: Glow, size: [0.5, 0.25, 0.125], at: [-0.375, 9.625, 3.8125]}
  - {name: Pipe5, slot: BodyDark, size: [0.75, 3.5, 0.75], at: [-1.125, 8, 4.25], material: wood}
  - {name: PipeMouth5, slot: Glow, size: [0.75, 0.25, 0.75], at: [-1.125, 9.875, 4.25]}
  - {name: PipeLip5, slot: Glow, size: [0.5, 0.25, 0.125], at: [-1.125, 8.875, 3.8125]}
  - {name: Pipe6, slot: BodyDark, size: [0.75, 2.75, 0.75], at: [-1.875, 7.625, 4.25], material: wood}
  - {name: PipeMouth6, slot: Glow, size: [0.75, 0.25, 0.75], at: [-1.875, 9.125, 4.25]}
  - {name: PipeLip6, slot: Glow, size: [0.5, 0.25, 0.125], at: [-1.875, 8.125, 3.8125]}
  - {name: PipeBand, slot: Trim, size: [4.75, 0.5, 1], at: [0, 7.25, 4.25], material: metal}
  - {name: PipeBand2, slot: Trim, size: [2.5, 0.5, 1], at: [1.125, 9.25, 4.25], material: metal}
  - {name: PipeBand3, slot: Trim, size: [1, 0.25, 1], at: [1.875, 11.125, 4.25], material: metal}
  # the floating accessory: a lit music note over its left shoulder
  - {name: Note, slot: Glow, size: [0.75, 0.5, 0.25], at: [-4, 10.75, -4], moves: float, pivot: [-3.75, 11.375, -4]}
  - {name: NoteStem, slot: Glow, size: [0.25, 1.25, 0.25], at: [-3.75, 11.625, -4], moves: float, pivot: [-3.75, 11.375, -4]}
  - {name: NoteFlag, slot: Glow, size: [0.5, 0.25, 0.25], at: [-3.5, 12.125, -4], moves: float, pivot: [-3.75, 11.375, -4]}
  - {name: NoteFlag2, slot: Glow, size: [0.25, 0.25, 0.25], at: [-3.25, 11.875, -4], moves: float, pivot: [-3.75, 11.375, -4]}
```

## Face

The house face, 16 cells across the 5.5-stud head (0.34375 studs a cell, 16 rows for the square front); the eye's lit crescent is the violet glow, the cheeks a dusk pink.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#D97BD0"
  rows:
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
    - "...gg.k..k.gg..."
    - "..pp...kk...pp.."
    - "................"
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Panpipe.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Panpipe.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter (Blender, Cycles):

![[Panpipe_tq.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Panpipe_vfx.jpg]]

The concept sheet, drawn from the parts table above: [[Panpipe_sheet.svg]] (flat shapes and text, for the Claude Design canvas) and [[Panpipe_sheet.png]]. The build's four orthographic views (left of each pair) beside the sheet's masks (right), the silhouette check:

![[Panpipe_views.png]]

## Cells

The block-cell build ([[Blocky-Style]] "Cells", [[Decisions]] B44): the cell is the face cell, 0.344 studs (2.9 a stud), 38 cells tall; one atlas of 1024 x 1024 at 8 texels a cell (571 islands). Materials: wool on the head, torso, ears, mane, beard, fringes and fleece (shag blobs with a violet fleck in thirty), wood on the six reeds, metal on the horns, bell, bands and pommel.

![[Panpipe_tq_cells.jpg]]

![[Panpipe_vfx_cells.jpg]]

## Reviews
- 2026-10-17, loop 2 worker, three rounds. Round 1: small pewter horns read as stubs and pewter pipes as a grey chimney behind the head. Round 2: bigger horns sweeping up, out and down read as branches. Round 3: ibex horns that arch back (a chain of tilted segments with a lit band, a dark ridge and lit tips), the pipes dark reeds with lit mouths and lit lips in pewter bands, the ears drooped; the preview gives it a violet ring and falling shadow smoke. Overlap 0.996 to 0.998, 1,504 triangles, 108 blocks, 13 studs. Wanted for: the one dark thing in a bright meadow, a gentle giant that plays its own organ and that you can ride. Still cheap: in daylight it is a muted purple box with a face; the beard and bell are small; the shadow wool reads as stripes on the legs from the side. Status review.
- 2026-10-17, block-cell worker, three rounds (cells). The violet flecks and the grout lift the dark coat in daylight (the open item of loop 2, partly: it is still the darkest thing on the meadow, as a Secret should be); the reeds read as reeds. Overlap with the sheet unchanged (the cells are a texture); hidden faces culled. Status review.
