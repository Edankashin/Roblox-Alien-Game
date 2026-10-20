---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Shimmerlynx
name: Aurelyx
world: 2
tier: Epic
status: review
element: Aurora
height: 4.25
blocks: 38
tris: 812
bevel_width: 0.1
bevel_segments: 2
palette: ["#C8C2F0", "#4B4470", "#FFF4E6", "#8FA6C4", "#9D7CFF", "#1A1530"]
roles: [body, second, accent, trim, glow, ink]
glow_cycle: ["#9D7CFF", "#7CFFC4", "#FF8FD8"]
hero: AuroraC
vfx: "kept on the body (Epic): the five aurora ribbons of the crest, the ear tips and the tail tip glow and step through violet, mint and pink every 6 s (the glow cycle: it purrs in colours); an aurora trail waves off the crest 2 studs back (Effects.luau, the Trail from Top to Tail) and motes drift up off it at 5 a second (the Glow emitter at Top); a light on the body in the aurora colours; the crest sways, the ears turn, the tail swings; a slow blink every 5 s"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Shimmerlynx_sheet.svg]]"
render: "[[Shimmerlynx_tq_cells.jpg]]"
glb: ""
overlap: [0.994, 0.989, 0.996, 0.994]
vfx_render: "[[Shimmerlynx_vfx_cells.jpg]]"
cells_render: "[[Shimmerlynx_tq_cells.jpg]]"
---
# Shimmerlynx (Aurelyx), Epic, World 2 Frostbyte

A lavender lynx sitting up, the Ice Cave's night Epic: a square head with a cream muzzle drawn into the house face under two dark forehead streaks, two small cream cheek ruffs flaring down from the jaw, tufted ears whose tips glow, and on the crown the aurora crest: five tall thin ribbons of light standing in a row across the head, the centre one tallest, in violet, mint and pink. It sits on two furred haunches with its front legs straight, cream paws in silver ankle bands, a cream chest, dark lynx spots and a stepped aurora emblem in silver on each haunch, and its tail held straight up beside its right haunch, ending in a block of light at shoulder height. Concept row in `src/shared/data/Species.luau`: "lynx, glowing aurora crest, purrs in colours". Element: Aurora (`Effects.luau`); [[Roster-Redesign]] section 2 gives the waving aurora ribbon, the colour cycle and the motes. Rules: [[Blocky-Style]].

**What makes a player want it.** The one you see at night from across the cave: a curtain of aurora standing on a cat's head, changing colour as it purrs, sitting the way a cat sits when it has decided you may approach. The banded body (bands, spots, a chest), the stepped emblem and the three glow extremities (the crest, the ear tips, the tail tip) are the Epic rung's detail; the glow stays on the body, as the ladder says an Epic's effects do; the light is a cycle, the aurora's own.

**Hero block.** `AuroraC`, the centre ribbon of the crest, a stud of light standing on the crown with two shorter ribbons each side: unique in Frostbyte (Skadra's crest is five ice crystals in a band; this is five curtains of light).

**Alien anatomy.** The crest is an aurora it grew, not fur: five flat ribbons of light that sway as one (the `crest` part the game moves); its ear tufts and its tail end in light, and the tail stands straight up like a lantern it carries. Four moving objects: the crest, the two ears and the tail.

**World motif (Frostbyte).** The ice facet as steps: the crest is a stepped skyline of ribbons, the haunch emblem a stepped diagonal, the muzzle and the cheek ruffs steps off the face.

## Parts

```yaml
parts:
  # it sits: two furred haunches on cream hind paws, two straight front legs on cream paws in silver bands
  - {name: HindPaw, slot: Accessory, size: [0.75, 0.5, 0.875], at: [0.875, 0.25, -0.4375], mirror: x}
  - {name: Haunch, slot: Body, size: [1, 1, 1.25], at: [0.875, 1, 0.375], bevel: true, mirror: x, material: fur}
  - {name: Paw, slot: Accessory, size: [0.75, 0.375, 0.875], at: [0.5, 0.1875, -0.9375], mirror: x}
  - {name: Band, slot: Trim, size: [0.75, 0.125, 0.75], at: [0.5, 0.4375, -0.75], mirror: x, material: metal}
  - {name: Leg, slot: Body, size: [0.5, 0.75, 0.5], at: [0.5, 0.875, -0.75], mirror: x}
  # the upright torso with a cream chest, the head on it
  - {name: Torso, slot: Body, size: [1.75, 1, 1.5], at: [0, 1.75, 0], bevel: true, material: fur}
  - {name: Chest, slot: Accessory, size: [1.25, 0.25, 0.125], at: [0, 1.375, -0.8125]}
  - {name: Head, slot: Body, size: [2, 1.75, 1.75], at: [0, 2.375, -0.25], bevel: true}
  # cream cheek ruffs flaring down from the jaw
  - {name: CheekRuff, slot: Accessory, size: [0.25, 0.625, 0.375], at: [1.0625, 1.75, -0.8125], rot: [0, 0, 20], mirror: x}
  # tufted ears with glowing tips, each one moving part
  - {name: Ear, slot: BodyDark, size: [0.5, 0.625, 0.25], at: [0.75, 3.5625, -0.375], mirror: x, moves: ear, pivot: [0.75, 3.25, -0.375]}
  - {name: EarTip, slot: Glow, size: [0.25, 0.125, 0.25], at: [0.75, 3.9375, -0.375], mirror: x, moves: ear, pivot: [0.75, 3.25, -0.375]}
  - {name: InnerEar, slot: Accessory, size: [0.25, 0.25, 0.125], at: [0.75, 3.5, -0.5625], mirror: x, moves: ear, pivot: [0.75, 3.25, -0.375]}
  # the hero: the aurora crest, five tall thin ribbons of light standing across the crown, the centre tallest; they sway as one
  - {name: AuroraC, slot: Glow, size: [0.25, 1, 0.375], at: [0, 3.75, 0.3125], moves: crest, pivot: [0, 3.25, 0.3125]}
  - {name: Aurora2, slot: Glow, size: [0.25, 0.75, 0.375], at: [0.375, 3.625, 0.3125], mirror: x, moves: crest, pivot: [0, 3.25, 0.3125]}
  - {name: Aurora3, slot: Glow, size: [0.25, 0.5, 0.375], at: [0.875, 3.5, 0.3125], mirror: x, moves: crest, pivot: [0, 3.25, 0.3125]}
  # the tail held straight up beside its right haunch, ending in a block of light at shoulder height; one moving part
  - {name: Tail, slot: Body, size: [0.5, 2, 0.5], at: [1.625, 1.25, 0.875], moves: tail, pivot: [1.625, 0.25, 0.875]}
  - {name: TailTip, slot: Glow, size: [0.5, 0.5, 0.5], at: [1.625, 2.5, 0.875], moves: tail, pivot: [1.625, 0.25, 0.875]}
  # lynx spots on each haunch, and the stepped emblem: an aurora wave of three silver steps on each haunch's side
  - {name: Spot, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.4375, 1.25, -0.125], mirror: x}
  - {name: Spot2, slot: BodyDark, size: [0.125, 0.25, 0.25], at: [1.4375, 0.75, 0.375], mirror: x}
  - {name: Emblem, slot: Trim, size: [0.125, 0.25, 0.25], at: [1.4375, 0.75, -0.125], mirror: x, material: metal}
  - {name: Emblem2, slot: Trim, size: [0.125, 0.25, 0.25], at: [1.4375, 1, 0.125], mirror: x, material: metal}
  - {name: Emblem3, slot: Trim, size: [0.125, 0.25, 0.25], at: [1.4375, 1.25, 0.375], mirror: x, material: metal}
```

## Face

The house face on the head's front: 16 cells across the 2-stud head (0.125 a cell), 14 rows for the 1.75-stud front. Two dark forehead streaks (`d`, the second colour) over the eyes, a cream muzzle (`c`, the accent) under an ink nose, a closed flat smile; the eye's lit crescent is the aurora's violet.

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
    "d": second
  rows:
    - "................"
    - ".....d....d....."
    - "....d......d...."
    - "....d......d...."
    - "................"
    - "...kk......kk..."
    - "..kwkk....kkwk.."
    - "..kwkk....kkwk.."
    - "..kkkk....kkkk.."
    - "..kgwk....kwgk.."
    - "...gg.ckkc.gg..."
    - "...cccccccccc..."
    - "..ppcckkkkccpp.."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Shimmerlynx.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Shimmerlynx.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Shimmerlynx_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads; the glow parts take the three colours of the cycle in turn):

![[Shimmerlynx_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Shimmerlynx_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 34 cells tall. Materials: `fur` on the torso (the 2-stud head stays skin so the tufts never crowd the face), `metal` on the silver bands and the emblem, the crest, ear tips and tail tip in glow cells, skin elsewhere.

## Reviews

- 2026-10-20, World 2 roster worker, three rounds. Round 1: standing on four legs it was Sabrek to the boxed test (0.83), so it sits: two bevelled haunches, straight front legs, the head on the chest, four masses, bevel 0.1. Round 2: the lower torso made it a wide box like Soakum (0.71) and the crest's 0.75-stud blocks behind the ears read as a pink crown, so the tail stands straight up beside the right haunch with its lit tip at shoulder height (0.68), the ribbons grew to a stud, a quarter wide and three eighths deep, and the cheek ruffs shrank. Overlap 0.989 to 0.996, 812 triangles, 38 blocks, 4.25 studs, four moving objects (the crest, the ears, the tail); three glow extremities. Wanted for: a curtain of aurora on a sitting cat, changing colour as it purrs. Still cheap: the emblem and spots sit on the haunch's outer face and the front view never sees them; the torso is mostly behind the head. Status review.
