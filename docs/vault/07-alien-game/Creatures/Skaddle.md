---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Skaddle
name: Skadra
world: 2
tier: Legendary
status: review
element: Blizzard
height: 3.5
blocks: 71
tris: 962
bevel_width: 0.0625
bevel_segments: 2
palette: ["#F4F7FA", "#5C708A", "#8FD3F4", "#4F9ED0", "#9FA8FF", "#161B2E"]
roles: [body, second, accent, trim, glow, ink]
hero: CrestC
vfx: "touches the ground (Legendary, Effects.luau): a snow flurry of six flakes circles its body (the Orbit at Body), frost ski-tracks trail between its skis (the Trail from FrontL to FrontR), flakes drift down off its crest at 3 a second (the Emitter at Top) and a cold periwinkle light hangs over the crest (pulse 3 s); every 10 s the gust (the flourish): a burst of twenty-two flakes off its skis and a ring of frost rolling out on the ground (the RingPulse at Feet); it hovers a little; in the rig the four wings beat, the crest crystals glimmer, the ear tufts flick and the scarf end swings, and the gust lifts it in a hop and a full turn with every wing flared and the scarf streaming"
ride: "Hover; the rider sits on the back between the hind wings, behind the quiver"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Skaddle_sheet.svg]]"
render: "[[Skaddle_tq_cells.jpg]]"
glb: ""
overlap: [0.996, 0.996, 1, 0.996]
vfx_render: "[[Skaddle_vfx_cells.jpg]]"
cells_render: "[[Skaddle_tq_cells.jpg]]"
idle_render: "[[Skaddle_idle.png]]"
---
# Skaddle (Skadra), Legendary, World 2 Frostbyte

A snow owl on two tiny skis, 3.5 studs to the tip of its crest (B45; it was 6.5, a player-sized owl, and is now redesigned at an owlet's size, not scaled): a big square white head with round golden eyes under a slate brow line, an ice-blue beak with a dark tip, a six-point frost glyph of ice cells on the forehead, two flicking ear tufts, and the frosty crest: five ice crystals in a fan, lit from inside, standing on a frost-blue band across the front of the crown. An ice-blue knitted scarf wraps its neck, one end hanging down its chest and swinging. Its chest is feathered in four scalloped rows of ice blue stepping in, with slate shadow lines between; two stepped wings stretch out and down from the shoulders like a gliding owl's, white, slate and ice blue with a lit line down each leading edge, and a second, smaller pair of wings grows from its back. A quiver of three fletched arrows rides on its back (the echo of Skadi, the winter hunter on skis), its tail fans out in three steps, and its feathered feet stand in bindings on the skis, three talons each, the ski tips curled up in two steps. Concept row in `src/shared/data/Species.luau`: "snow owl, tiny skis, frosty crest; echo of Skadi". Element: Blizzard (`Effects.luau`); [[Roster-Redesign]] section 2. Rules: [[Blocky-Style]].

**What makes a player want it (B46).** It is the Warden of Frostbyte, now an owlet you could hold, and it is plainly rarer than anything under it at the same height: 71 blocks of sixteenth-grid detail (the scalloped chest, the brow, the glyph, the crest, the talons, the curled skis, the quiver, the scarf), eyes no lower species has (the Legendary `halo`, golden rings that breathe outward on a 32-pixel-a-stud plate with a sparkle travelling round them, and star cheeks), nine moving things, and the first light in the snow that touches the ground: the flurry circling it, the ski tracks, and every 10 s the gust that lifts it into a hop and a full turn with all four wings flared and a ring of frost rolling out under it. Cute and cooler, never fiercer: round golden eyes, a scarf and skis.

**Hero block.** `CrestC`, the centre crystal of the crest: five lit ice crystals in a fan on the crown, unique in Frostbyte.

**Moving parts (eight objects and the blink).** `wingR`, `wingL` (they beat), `hindwingR`, `hindwingL` (they flutter), `tuftR`, `tuftL` (they flick), `crest` (the crystals glimmer), `scarf` (its end swings); the face plate blinks, glints and its rings breathe.

**Alien anatomy.** Four wings (a second small pair on the back), skis that are its own ice-bone feet, golden eyes that breathe light.

**World motif (Frostbyte).** The six-point frost glyph on the forehead in ice cells; the ice facet in the crest's stepped crystals and the two-step curl of the ski tips.

## Parts

```yaml
parts:
  # the tiny skis, their tips curled up in two steps, bindings and straps; the feathered feet in them on three talons each
  - {name: Ski, slot: Trim, size: [0.375, 0.125, 1.75], at: [0.4375, 0.0625, -0.125], mirror: x, material: ice}
  - {name: SkiTip, slot: Trim, size: [0.375, 0.125, 0.25], at: [0.4375, 0.1875, -1.0625], mirror: x, material: ice}
  - {name: SkiCurl, slot: Trim, size: [0.375, 0.125, 0.125], at: [0.4375, 0.3125, -1.1875], mirror: x, material: ice}
  - {name: Binding, slot: BodyDark, size: [0.5, 0.1875, 0.5], at: [0.4375, 0.21875, 0], mirror: x}
  - {name: BindStrap, slot: Trim, size: [0.625, 0.0625, 0.25], at: [0.4375, 0.34375, 0], mirror: x, material: metal}
  - {name: Leg, slot: Body, size: [0.375, 0.25, 0.375], at: [0.4375, 0.5, 0], mirror: x, material: fur}
  - {name: Talon, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [0.3125, 0.4375, -0.25], mirror: x}
  - {name: Talon2, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [0.4375, 0.4375, -0.25], mirror: x}
  - {name: Talon3, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [0.5625, 0.4375, -0.25], mirror: x}
  # the body and the big head over it (two masses)
  - {name: Body, slot: Body, size: [2, 0.75, 1.75], at: [0, 1, 0.125], bevel: true, material: fur}
  - {name: Head, slot: Body, size: [2, 1.5, 1.75], at: [0, 2.125, -0.125], bevel: true}
  # the feathered chest: four scalloped rows of ice blue stepping in, slate shadow lines between
  - {name: FeatherA, slot: Accessory, size: [1.5, 0.125, 0.0625], at: [0, 1.25, -0.78125]}
  - {name: BarA, slot: BodyDark, size: [1.25, 0.0625, 0.0625], at: [0, 1.15625, -0.78125]}
  - {name: FeatherB, slot: Accessory, size: [1.25, 0.125, 0.0625], at: [0, 1, -0.78125]}
  - {name: BarB, slot: BodyDark, size: [1, 0.0625, 0.0625], at: [0, 0.90625, -0.78125]}
  - {name: FeatherC, slot: Accessory, size: [1, 0.125, 0.0625], at: [0, 0.8125, -0.78125]}
  - {name: FeatherD, slot: Accessory, size: [0.5, 0.125, 0.0625], at: [0, 0.6875, -0.78125]}
  # the knitted scarf round the neck, one end hanging down the chest and swinging
  - {name: Scarf, slot: Accessory, size: [2.125, 0.1875, 1.875], at: [0, 1.40625, -0.0625]}
  - {name: ScarfEnd, slot: Accessory, size: [0.25, 0.5, 0.0625], at: [0.625, 1.0625, -1.03125], moves: scarf, pivot: [0.625, 1.3125, -1.03125]}
  - {name: ScarfStripe, slot: Trim, size: [0.25, 0.0625, 0.0625], at: [0.625, 0.90625, -1.09375], moves: scarf, pivot: [0.625, 1.3125, -1.03125]}
  # the face: an ice-blue beak with a dark tip between the eyes, a slate brow line over the face plate, a frost glyph on the forehead
  - {name: Beak, slot: Trim, size: [0.25, 0.25, 0.1875], at: [0, 1.8125, -1.09375], material: metal}
  - {name: BeakTip, slot: BodyDark, size: [0.125, 0.125, 0.125], at: [0, 1.625, -1.0625]}
  - {name: Brow, slot: BodyDark, size: [1.75, 0.0625, 0.125], at: [0, 2.46875, -1.0625]}
  - {name: Glyph, slot: Accessory, size: [0.125, 0.375, 0.0625], at: [0, 2.6875, -1.03125]}
  - {name: Glyph2, slot: Accessory, size: [0.125, 0.0625, 0.0625], at: [0.1875, 2.78125, -1.03125], mirror: x}
  - {name: Glyph3, slot: Accessory, size: [0.125, 0.0625, 0.0625], at: [0.1875, 2.59375, -1.03125], mirror: x}
  # ear tufts that flick
  - {name: EarTuft, slot: Body, size: [0.25, 0.375, 0.25], at: [0.75, 3.0625, -0.25], rot: [0, 0, -20], mirror: x, moves: tuft, pivot: [0.6875, 2.875, -0.25]}
  # the hero: the frosty crest, five lit ice crystals in a fan standing on a frost-blue band across the front of the crown; they glimmer
  - {name: CrestBand, slot: Trim, size: [1.5, 0.125, 0.375], at: [0, 2.9375, -0.75], material: metal}
  - {name: CrestC, slot: Glow, size: [0.25, 0.5, 0.25], at: [0, 3.25, -0.75], material: ice, moves: crest, pivot: [0, 3, -0.75]}
  - {name: Crest2, slot: Glow, size: [0.25, 0.375, 0.25], at: [0.3125, 3.1875, -0.75], rot: [0, 0, -15], mirror: x, material: ice, moves: crest, pivot: [0, 3, -0.75]}
  - {name: Crest3, slot: Glow, size: [0.1875, 0.25, 0.1875], at: [0.5625, 3.125, -0.75], rot: [0, 0, -25], mirror: x, material: ice, moves: crest, pivot: [0, 3, -0.75]}
  # two stepped wings stretched out and down from the shoulders, white, slate and ice blue, a lit line down each leading edge; each wing one moving part
  - {name: Wing, slot: Body, size: [0.125, 0.75, 1], at: [1.34375, 1.15625, 0.125], rot: [0, 0, -110], mirror: x, moves: wing, pivot: [1, 1.3125, 0.125]}
  - {name: Wing2, slot: BodyDark, size: [0.125, 0.625, 0.875], at: [2, 0.9375, 0.1875], rot: [0, 0, -110], mirror: x, moves: wing, pivot: [1, 1.3125, 0.125]}
  - {name: WingTip, slot: Accessory, size: [0.125, 0.5, 0.625], at: [2.53125, 0.75, 0.25], rot: [0, 0, -110], mirror: x, moves: wing, pivot: [1, 1.3125, 0.125]}
  - {name: WingLine, slot: Glow, size: [0.125, 0.75, 0.125], at: [1.34375, 1.15625, -0.4375], rot: [0, 0, -110], mirror: x, moves: wing, pivot: [1, 1.3125, 0.125]}
  - {name: WingLine2, slot: Glow, size: [0.125, 0.625, 0.125], at: [2, 0.9375, -0.3125], rot: [0, 0, -110], mirror: x, moves: wing, pivot: [1, 1.3125, 0.125]}
  # alien anatomy: a second, smaller pair of wings on the back, rising up and out
  - {name: HindWing, slot: Body, size: [0.125, 0.5, 0.5], at: [1, 1.75, 1], rot: [0, 0, -20], mirror: x, moves: hindwing, pivot: [0.9375, 1.5, 1]}
  - {name: HindTip, slot: BodyDark, size: [0.125, 0.25, 0.375], at: [1.125, 2.09375, 1], rot: [0, 0, -20], mirror: x, moves: hindwing, pivot: [0.9375, 1.5, 1]}
  - {name: HindLine, slot: Glow, size: [0.125, 0.5, 0.0625], at: [1, 1.75, 0.71875], rot: [0, 0, -20], mirror: x, moves: hindwing, pivot: [0.9375, 1.5, 1]}
  # the tail fanning out behind in three steps
  - {name: Tail, slot: Body, size: [1, 0.125, 0.5], at: [0, 0.75, 1.25]}
  - {name: TailTip, slot: BodyDark, size: [0.75, 0.125, 0.25], at: [0, 0.75, 1.625]}
  - {name: TailEnd, slot: Accessory, size: [0.5, 0.125, 0.25], at: [0, 0.75, 1.875]}
  # the echo of Skadi: a quiver of three fletched arrows riding on the back
  - {name: Quiver, slot: BodyDark, size: [0.375, 1, 0.375], at: [-0.5, 1.75, 1.1875], rot: [0, 0, 15]}
  - {name: Arrow, slot: Trim, size: [0.0625, 0.375, 0.0625], at: [-0.6875, 2.40625, 1.1875], rot: [0, 0, 15], material: metal}
  - {name: Arrow2, slot: Trim, size: [0.0625, 0.375, 0.0625], at: [-0.5625, 2.4375, 1.28125], rot: [0, 0, 15], material: metal}
  - {name: Arrow3, slot: Trim, size: [0.0625, 0.375, 0.0625], at: [-0.75, 2.375, 1.09375], rot: [0, 0, 15], material: metal}
  - {name: Fletch, slot: Accessory, size: [0.125, 0.1875, 0.0625], at: [-0.75, 2.65625, 1.1875], rot: [0, 0, 15]}
  - {name: Fletch2, slot: Accessory, size: [0.125, 0.1875, 0.0625], at: [-0.625, 2.6875, 1.28125], rot: [0, 0, 15]}
  - {name: Fletch3, slot: Accessory, size: [0.125, 0.1875, 0.0625], at: [-0.8125, 2.625, 1.09375], rot: [0, 0, 15]}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell), 12 rows for the 1.5-stud front; the eyes and the cheeks are on the face plate under the slate brow, the beak a block between the eyes.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `halo`, a Legendary design, layered glowing rings that breathe outward with a sparkle travelling round the iris, here a snowy owl's gold (amber, gold and pale gold rings), at 32 pixels a stud on a 1.75 x 0.875 stud plate (56 x 28 pixels, eleven frames: open, half, closed, two glints, six ring frames). Star cheeks (Legendary up); the beak is the mouth.

```yaml
eyes:
  key: halo
  colours: {deep: "#C98A12", mid: "#FFC94D", bright: "#FFF1A8", sparkle: "#FFFFFF"}
  mouth: none
  cheeks: stars
  plate: [1.75, 0.875]
  at: [0, 2]
  spread: 0.4375
```

## Rig

The idle and the flourish ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes them into `src/shared/data/Rigs.luau`). The flourish is the gust, on the 10 s beat of the Effects.luau flourish (the flake burst and the frost ring).

```yaml
rig:
  clips:
    wing: [{kind: flap, amp: 12, period: 2.4, axis: z}]
    hindwing: [{kind: flap, amp: 15, period: 1.2, axis: z}]
    tuft: [{kind: wag, amp: 12, period: 3, axis: z}]
    crest: [{kind: pulse, amp: 0.08, period: 2}]
    scarf: [{kind: sway, amp: 10, period: 1.8, axis: x}]
    root: [{kind: bob, amp: 0.08, period: 2.8}]
    face: [{kind: blink, period: 5}]
  flourish:
    every: 10
    length: 3
    moves:
      - {part: root, kind: hop, amp: 0.5, at: 0, for: 1.2}
      - {part: wing, kind: flare, amp: 30, at: 0, for: 1.6}
      - {part: hindwing, kind: flare, amp: 25, at: 0.2, for: 1.4}
      - {part: root, kind: turn, amp: 360, at: 0.4, for: 2}
      - {part: scarf, kind: swish, amp: 25, at: 0.6, for: 1.6}
      - {part: crest, kind: pop, amp: 0.2, at: 1.8, for: 0.8}
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Skaddle.md --out <scratch>`; build, renders and the idle preview: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Skaddle.md --out <scratch> --suffix _cells --idle` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Skaddle_tq_cells.jpg]]

VFX preview (Blender, labelled as one; the in-game effects are the species' row in `src/shared/data/Effects.luau`, whose colours the preview reads):

![[Skaddle_vfx_cells.jpg]]

The idle: eight frames of the clips, four of the flourish, and the face plate's frames:

![[Skaddle_idle.png]]

The concept sheet, drawn from the parts table above: [[Skaddle_sheet.svg]] (flat shapes and text, for the Claude Design canvas). Before and after B45 and B46 with the rest of the batch: `media/studio/2026-10-21/Roster w2_high_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud). Materials: `fur` on the body and the legs (the white owl's down; the 2-stud head stays skin so the tufts never crowd the face), `ice` on the skis and the crest crystals (lit bands), `metal` on the beak, the straps, the crest band and the arrows, skin on the wings and the scarf.

## Reviews

- 2026-10-19, World 2 worker, two rounds. Round 1: at 44 blocks it sat under the Legendary band, so the wings gained their lit lines, the breast its five bars, the feet their talons, the tail two more rows, the beak a dark tip, the cheeks two feather tufts and the back a quiver of three arrows (the Skadi echo the brief asked for). Round 2: the glyph moved from the flank to the forehead, above the facial disc, where the front view shows it; the ear tufts went static so the four wings keep the four moving objects; the crest's crystals, thin in the first build, grew to three quarters of a stud so the crown reads from the hero camera. Round 3 (the silhouette test): with the wings hanging close it was a mushroom beside Fenrir (0.73), so the wings now stretch out and down from the shoulders (25 degrees under horizontal, a gliding owl, 8 studs across), which leaves the box's lower corners empty and drops the pair under 0.7. A white middle wing block vanished against the render's pale backdrop and the wing read as broken, so the wings are barred white, slate and ice blue. Overlap 0.994 to 0.998, 884 triangles, 62 blocks, 6.5 studs, four moving objects (the two wing pairs). Wanted for: the Warden of Frostbyte, a player-sized owl on skis under a lit crest. Still cheap: the hind wings are small and read only from the three-quarter view; the quiver is hidden from the front. Status review.
- 2026-10-20, World 2 roster worker (the ladder review's fix): the head and body were two big white blocks, so the flat breast panel and its five bars became five scalloped feather rows stepping in down the chest (ice blue over white, a slate shadow line under every other row) with a slate mantle across the shoulders; a slate brow ridge an eighth thick stands proud over the facial disc (a quarter would have covered the eyes' top row); the crest moved from the middle of the crown to its front third with the gem over the brow, so the front view and the game's high camera see it. Overlap 0.994 to 0.998, 910 triangles, 66 blocks, 6.5 studs, four moving objects. Status review.
- 2026-10-21, Roster w2_high worker, the B45 and B46 pass, two rounds. Round 1: redesigned at 3.5 studs from 6.5, not scaled: an owlet whose 2-stud head is 43 percent of it, the body under it on feathered legs in ski bindings with three talons each, the skis curled in two steps, the chest in four scalloped ice-blue rows with slate shadow lines, a knitted scarf whose end swings, the crest's five lit crystals on a band at the crown's front, the forehead glyph in ice cells, wings at -110 degrees in three stepped plates with two lit leading lines (5.5 studs across), the hind wings, the tail fan and the quiver in sixteenth-grid cells. Its own Legendary `halo` eyes in snowy-owl gold (amber, gold and pale gold rings that breathe, a sparkle round them) on a 56 x 28 plate, star cheeks, the beak a block. Round 2: a slate frame round the plate made the white head read as a monitor, so the disc went and the brow line stays: 71 blocks. Rig: two wings beat, two hind wings flutter, the ear tufts flick, the crest glimmers, the scarf swings, it hovers and blinks (nine moving things); every 10 s the gust lifts it in a hop and a full turn with every wing flared and the scarf streaming, on the beat of the frost ring. Overlap 0.996 to 1.000, 962 triangles. Wanted for: golden owl eyes that breathe light, a scarf and skis, the first light in the snow that touches the ground. Still cheap: the crest's lit crystals wash out to white in the render and are small from the front; the wings are edge-on (thin lines) from straight ahead. Status review.
