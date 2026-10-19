---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Skaddle
name: Skadra
world: 2
tier: Legendary
status: review
element: Blizzard
height: 6.5
blocks: 62
tris: 884
bevel_width: 0.125
bevel_segments: 2
palette: ["#F4F7FA", "#5C708A", "#8FD3F4", "#4F9ED0", "#9FA8FF", "#161B2E"]
roles: [body, second, accent, trim, glow, ink]
hero: CrestC
vfx: "touches the ground (Legendary): the five ice crystals of the crest glow and the leading edge of each wing is a lit line; a snow flurry swirls round it a stud out and frost ski-tracks trail behind the skis (Effects.luau, the Flake emitters at Top and Feet, the Sparkle at Back); a ground ring of frost in the tier gold; a cold light over the crest; the flourish is a gust that lifts it half a stud; four wings move"
ride: "Hover; the rider sits on the back between the hind wings, behind the quiver"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Skaddle_sheet.svg]]"
render: "[[Skaddle_tq_cells.jpg]]"
glb: ""
overlap: [0.995, 0.994, 0.998, 0.995]
vfx_render: "[[Skaddle_vfx_cells.jpg]]"
cells_render: "[[Skaddle_tq_cells.jpg]]"
---
# Skaddle (Skadra), Legendary, World 2 Frostbyte

A snow owl the size of the player, standing on two tiny skis. A big square head carries a slate-rimmed facial disc with the house face inside it, a six-point frost glyph on the forehead, two ear tufts, and the frosty crest: five ice crystals in a fan, lit from inside, standing in a frost band across the crown. The breast is ice blue under five slate bars; two stepped wings stretch out and down from the shoulders, a gliding owl's, barred white, slate and ice blue, with a lit line down each leading edge, and a second, smaller pair of wings grows from the back. A quiver of three fletched arrows hangs on its back (the echo of Skadi, the winter hunter on skis), and its feet, in bindings on the skis, end in three talons each. Concept row in `src/shared/data/Species.luau`: "snow owl, tiny skis, frosty crest; echo of Skadi". Element: Blizzard (`Effects.luau`); [[Roster-Redesign]] section 2 gives the flurry, the ski tracks, the ground ring and the gust. Rules: [[Blocky-Style]].

**What makes a player want it.** It is the Warden of Frostbyte, 6.5 studs to the avatar's 5, and the first creature on the snow whose light reaches the ground: the gold ring under its skis and the flurry circling it say "Legendary" from across the field before the face does. The face stays the soft house face; the awe is the crest, the four wings and the skis.

**Hero block.** `CrestC`, the centre crystal of the crest: five lit ice crystals in a fan on the crown, unique in Frostbyte.

**Alien anatomy.** Four wings (a second small pair on the back), skis that are its own ice-bone feet, and a facial disc that is a ring of slate cells. Four moving objects: the two wings and the two hind wings.

**World motif (Frostbyte).** The six-point frost glyph on the forehead in ice-blue cells; the ice facet in the crest's stepped crystals and the chamfered ski tips.

## Parts

```yaml
parts:
  # the tiny skis, their tips curled up, bindings and straps; the feet in them on three talons each
  - {name: Ski, slot: Trim, size: [0.5, 0.25, 2.5], at: [0.75, 0.125, -0.25], mirror: x, material: ice}
  - {name: SkiTip, slot: Trim, size: [0.5, 0.25, 0.375], at: [0.75, 0.375, -1.5625], mirror: x, material: ice}
  - {name: Binding, slot: BodyDark, size: [0.75, 0.25, 0.75], at: [0.75, 0.375, 0], mirror: x}
  - {name: BindStrap, slot: Trim, size: [1, 0.125, 0.25], at: [0.75, 0.5625, 0], mirror: x, material: metal}
  - {name: Foot, slot: BodyDark, size: [0.75, 0.5, 0.75], at: [0.75, 0.75, 0], mirror: x}
  - {name: Talon, slot: Trim, size: [0.25, 0.25, 0.375], at: [0.375, 0.625, -0.5625], mirror: x, material: metal}
  - {name: Talon2, slot: Trim, size: [0.25, 0.25, 0.375], at: [0.75, 0.625, -0.5625], mirror: x, material: metal}
  - {name: Talon3, slot: Trim, size: [0.25, 0.25, 0.375], at: [1.125, 0.625, -0.5625], mirror: x, material: metal}
  # the body with its barred ice-blue breast, the head over it
  - {name: Body, slot: Body, size: [2.5, 2, 2.25], at: [0, 2, 0.125], bevel: true, material: fur}
  - {name: Breast, slot: Accessory, size: [1.5, 1.25, 0.125], at: [0, 1.875, -1.0625]}
  - {name: Bar, slot: BodyDark, size: [1.25, 0.125, 0.125], at: [0, 1.0625, -1.1875]}
  - {name: Bar2, slot: BodyDark, size: [1.25, 0.125, 0.125], at: [0, 1.4375, -1.1875]}
  - {name: Bar3, slot: BodyDark, size: [1.25, 0.125, 0.125], at: [0, 1.8125, -1.1875]}
  - {name: Bar4, slot: BodyDark, size: [1.25, 0.125, 0.125], at: [0, 2.1875, -1.1875]}
  - {name: Bar5, slot: BodyDark, size: [1.25, 0.125, 0.125], at: [0, 2.5625, -1.1875]}
  - {name: Head, slot: Body, size: [3, 3, 2.5], at: [0, 4, -0.25], bevel: true, material: fur}
  - {name: Beak, slot: Trim, size: [0.75, 0.375, 0.375], at: [0, 3.8125, -1.6875], material: metal}
  - {name: BeakTip, slot: BodyDark, size: [0.5, 0.125, 0.25], at: [0, 3.5625, -1.625]}
  - {name: Cheek, slot: Body, size: [0.25, 0.5, 0.5], at: [1.625, 3.5, -0.75], mirror: x}
  - {name: EarTuft, slot: Body, size: [0.5, 0.75, 0.375], at: [1.25, 5.75, -0.5], rot: [0, 0, -20], mirror: x}
  # the hero: the frosty crest, five lit ice crystals in a fan standing in a frost band across the crown
  - {name: CrestBand, slot: Trim, size: [2.5, 0.25, 0.5], at: [0, 5.625, 0], material: metal}
  - {name: CrestGem, slot: Glow, size: [0.5, 0.5, 0.5], at: [0, 5.75, -0.5], shape: ico1, material: ice}
  - {name: CrestC, slot: Glow, size: [0.75, 1, 0.75], at: [0, 6, 0], material: ice}
  - {name: Crest2, slot: Glow, size: [0.5, 0.875, 0.5], at: [0.75, 5.8125, 0], rot: [0, 0, -15], mirror: x, material: ice}
  - {name: Crest3, slot: Glow, size: [0.5, 0.625, 0.5], at: [1.3125, 5.6875, 0], rot: [0, 0, -25], mirror: x, material: ice}
  # two stepped wings stretched out and down from the shoulders, barred white, slate and ice blue, a lit line down each leading edge; each wing one moving part
  - {name: Wing, slot: Body, size: [0.375, 1.25, 1.75], at: [1.8125, 3, 0.25], rot: [0, 0, -115], mirror: x, moves: wing, pivot: [1.25, 3.25, 0.25]}
  - {name: Wing2, slot: BodyDark, size: [0.375, 1, 1.5], at: [2.8125, 2.5, 0.375], rot: [0, 0, -115], mirror: x, moves: wing, pivot: [1.25, 3.25, 0.25]}
  - {name: WingTip, slot: Accessory, size: [0.375, 0.75, 1.25], at: [3.625, 2.125, 0.5], rot: [0, 0, -115], mirror: x, moves: wing, pivot: [1.25, 3.25, 0.25]}
  - {name: WingLine, slot: Glow, size: [0.125, 1.25, 0.125], at: [1.8125, 3, -0.6875], rot: [0, 0, -115], mirror: x, moves: wing, pivot: [1.25, 3.25, 0.25]}
  # alien anatomy: a second, smaller pair of wings on the back
  - {name: HindWing, slot: Body, size: [0.25, 1, 1], at: [1.4375, 2.75, 1.5], rot: [0, 0, -25], mirror: x, moves: wing, pivot: [1.25, 3, 1.5]}
  - {name: HindTip, slot: BodyDark, size: [0.25, 0.5, 0.75], at: [1.75, 2, 1.625], rot: [0, 0, -25], mirror: x, moves: wing, pivot: [1.25, 3, 1.5]}
  - {name: HindLine, slot: Glow, size: [0.125, 1, 0.125], at: [1.4375, 2.75, 0.9375], rot: [0, 0, -25], mirror: x, moves: wing, pivot: [1.25, 3, 1.5]}
  # tail feathers in two rows
  - {name: Tail, slot: Body, size: [1.5, 0.25, 1], at: [0, 1.125, 1.75]}
  - {name: TailTip, slot: BodyDark, size: [1.25, 0.25, 0.5], at: [0, 1.125, 2.5]}
  - {name: Tail2, slot: Body, size: [1, 0.25, 0.75], at: [0, 0.875, 1.875]}
  - {name: Tail3, slot: BodyDark, size: [0.75, 0.25, 0.5], at: [0, 0.875, 2.5]}
  # the echo of Skadi: a quiver of three fletched arrows on the back
  - {name: Quiver, slot: BodyDark, size: [0.625, 2, 0.625], at: [-0.75, 2.75, 1.5625], rot: [0, 0, 15]}
  - {name: Arrow, slot: Trim, size: [0.125, 1, 0.125], at: [-0.875, 4.125, 1.5], rot: [0, 0, 15], material: metal}
  - {name: Arrow2, slot: Trim, size: [0.125, 1, 0.125], at: [-0.6875, 4.25, 1.6875], rot: [0, 0, 15], material: metal}
  - {name: Arrow3, slot: Trim, size: [0.125, 1, 0.125], at: [-0.5625, 4, 1.4375], rot: [0, 0, 15], material: metal}
  - {name: Fletch, slot: Accessory, size: [0.25, 0.375, 0.125], at: [-1.0625, 4.8125, 1.5], rot: [0, 0, 15]}
  - {name: Fletch2, slot: Accessory, size: [0.25, 0.375, 0.125], at: [-0.875, 4.9375, 1.6875], rot: [0, 0, 15]}
  - {name: Fletch3, slot: Accessory, size: [0.25, 0.375, 0.125], at: [-0.75, 4.6875, 1.4375], rot: [0, 0, 15]}
```

## Face

The house face on the head's front: 16 cells across the 3-stud head (0.1875 a cell), 16 rows for the square front. The facial disc is a ring of slate cells (`d`, the second colour) inside the border; the six-point frost glyph (`f`, the accent) sits on the forehead above it; the eye's lit crescent is the crest's glow.

```yaml
face:
  host: Head
  legend:
    ".": body
    "k": ink
    "w": "#FFFFFF"
    "g": glow
    "p": "#FF8FA3"
    "d": second
    "f": accent
  rows:
    - "................"
    - "......f...f....."
    - ".......f.f......"
    - "......fffff....."
    - ".......f.f......"
    - "......f...f....."
    - ".dddddddddddddd."
    - ".d.kk......kk.d."
    - ".dkwkk....kkwkd."
    - ".dkwkk....kkwkd."
    - ".dkkkk....kkkkd."
    - ".dkgwk....kwgkd."
    - ".d.gg.k..k.gg.d."
    - ".dpp...kk...ppd."
    - ".dddddddddddddd."
    - "................"
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Skaddle.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Skaddle.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Skaddle_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Skaddle_vfx_cells.jpg]]

The concept sheet, drawn from the parts table above: [[Skaddle_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with the six World 2 rungs: `media/studio/2026-10-19/world2_ladder_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.1875 studs (5.3 a stud), 35 cells tall. Materials: `fur` on the head and body (the white owl's down: soft tufts on a lattice), `ice` on the skis and the crest crystals (lit bands), `metal` on the beak, the talons, the straps, the crest band and the arrows, skin on the wings.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: at 44 blocks it sat under the Legendary band, so the wings gained their lit lines, the breast its five bars, the feet their talons, the tail two more rows, the beak a dark tip, the cheeks two feather tufts and the back a quiver of three arrows (the Skadi echo the brief asked for). Round 2: the glyph moved from the flank to the forehead, above the facial disc, where the front view shows it; the ear tufts went static so the four wings keep the four moving objects; the crest's crystals, thin in the first build, grew to three quarters of a stud so the crown reads from the hero camera. Round 3 (the silhouette test): with the wings hanging close it was a mushroom beside Fenrir (0.73), so the wings now stretch out and down from the shoulders (25 degrees under horizontal, a gliding owl, 8 studs across), which leaves the box's lower corners empty and drops the pair under 0.7. A white middle wing block vanished against the render's pale backdrop and the wing read as broken, so the wings are barred white, slate and ice blue. Overlap 0.994 to 0.998, 884 triangles, 62 blocks, 6.5 studs, four moving objects (the two wing pairs). Wanted for: the Warden of Frostbyte, a player-sized owl on skis under a lit crest. Still cheap: the hind wings are small and read only from the three-quarter view; the quiver is hidden from the front. Status review.
