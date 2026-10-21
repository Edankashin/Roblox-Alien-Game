---
tags: [alien-game, creature, blocky]
up: "[[Alien-Game]]"
id: Flapsicle
name: Eekle
world: 2
tier: Uncommon
status: review
element: Ice
height: 2.88
blocks: 19
tris: 402
bevel_width: 0.1
bevel_segments: 2
palette: ["#3F4C8C", "#8FC9F0", "#FF9BB0", "#121630"]
roles: [body, second, accent, ink]
hero: IceWing
vfx: "Uncommon, two layers (Effects.luau): an Emitter sheds pixel frost flakes (BFE9FF) falling from BackL at 2 a second, and a lilac Sparkle (C9B8FF) twinkles at BackR every 3.5 s, the second colour; the idle flaps the wings 20 degrees every 0.5 s; no light; the wings beat, the ears twitch, the perch shimmers and it sways in the rig"
artboard: "https://claude.ai/artifact/QkgZkYfF97ua798aJC55AD"
sheet: "[[Flapsicle_sheet.svg]]"
render: "[[Flapsicle_tq_cells.jpg]]"
glb: ""
overlap: [0.99, 0.995, 0.996, 0.99]
cells_render: "[[Flapsicle_tq_cells.jpg]]"
idle_render: "[[Flapsicle_idle.png]]"
---
# Flapsicle (Eekle), Uncommon, World 2 Frostbyte

An indigo bat hanging upside down from nothing: a small block of ice floats in the air with its two feet clamped round it, its round body hangs under that, and its big head hangs lowest with the house face the right way up (it twists its head to look at you), two wide ears splayed out and down with pink insides, a pink belly patch, two wings of clear ice spread out and down from its shoulders five studs across with an icicle hanging under each tip, and an icicle under its chin that rests on the snow. Concept row in `src/shared/data/Species.luau`: "bat, icicle wings, hangs upside down from nothing". Element and effect: [[Roster-Redesign]] section 2 (frost dust off the wings at each flap; it sways). Rules: [[Blocky-Style]].

**What makes a player want it.** It is the Ice Cave's night catch, hanging from a hook that is not there, so low its chin rests on the snow, wings spread wide, looking at you upside down with the same soft face as everything else. The Uncommon rung exactly: a two-tone body (indigo over ice), one secondary block (the perch of nothing) and a second colour in the touch (the frost dust), at 2.75 studs.

**Hero block.** The `IceWing` pair, two plates of clear ice with icicles at their tips, hanging from the shoulders: unique in Frostbyte (Skadra's wings are feathers; these are ice).

**Alien anatomy.** It hangs from a block of frozen air that goes everywhere with it; its wings are ice, not skin, and shed frost when they move; its head twists so the face stays upright while the rest of it hangs.

**World motif (Frostbyte).** Icicles, the ice facet hanging: three stepped points, one under each wingtip and one under the chin; the wings, the icicles and the perch are `ice` cells.

## Parts

```yaml
parts:
  # the perch of nothing: a floating bar of ice wider than the body, the feet gripping it from below and curling over its front (a small block
  # of ice centred on top read as a hat from the front; a long thin bar reads as something it hangs from)
  - {name: Perch, slot: BodyDark, size: [2.5, 0.25, 0.25], at: [0, 2.75, 0], material: ice, moves: perch, pivot: [0, 2.75, 0]}
  - {name: Foot, slot: Body, size: [0.25, 0.375, 0.125], at: [0.375, 2.6875, -0.1875], mirror: x}
  # the body hangs under the perch, the head hangs lowest and carries the face
  - {name: Body, slot: Body, size: [1.5, 1, 1.25], at: [0, 2, 0], bevel: true}
  - {name: Belly, slot: Accessory, size: [1, 0.5, 0.125], at: [0, 2, -0.6875]}
  - {name: Head, slot: Body, size: [2, 1.25, 1.5], at: [0, 1, 0], bevel: true}
  # wide ears splayed out and down from the head's sides, pink inside, each one moving part
  - {name: Ear, slot: Body, size: [0.5, 0.875, 0.25], at: [1.1875, 0.75, -0.125], rot: [0, 0, -110], mirror: x, moves: ear, pivot: [0.75, 0.875, -0.125]}
  - {name: InnerEar, slot: Accessory, size: [0.25, 0.625, 0.125], at: [1.1875, 0.75, -0.3125], rot: [0, 0, -110], mirror: x, moves: ear, pivot: [0.75, 0.875, -0.125]}
  # the hero: wings of ice spread out and down from the shoulders, an icicle hanging under each tip; each wing one moving part
  - {name: IceWing, slot: BodyDark, size: [2, 0.25, 1], at: [1.6875, 1.9375, 0], rot: [0, 0, -20], mirror: x, moves: wing, pivot: [0.75, 2.25, 0], material: ice}
  - {name: WingIcicle, slot: BodyDark, size: [0.25, 0.5, 0.25], at: [2.5, 1.25, 0], rot: [180, 0, 0], shape: cone6, mirror: x, moves: wing, pivot: [0.75, 2.25, 0], material: ice}
  # B46 detail: the arm bone along each wing's leading edge, indigo on the ice
  - {name: Rib, slot: Body, size: [2, 0.125, 0.125], at: [1.75, 2.125, -0.4375], rot: [0, 0, -20], mirror: x, moves: wing, pivot: [0.75, 2.25, 0]}
  # it hangs so low the icicle under its chin rests on the snow
  - {name: ChinIcicle, slot: BodyDark, size: [0.25, 0.375, 0.25], at: [0, 0.1875, -0.5], rot: [180, 0, 0], shape: cone6, material: ice}
  # B46 detail: a pink nose between the eyes (proud of the plate), and a frost tuft on its chest under the belly patch
  - {name: Nose, slot: Accessory, size: [0.25, 0.125, 0.125], at: [0, 1.0625, -0.8125]}
  - {name: Tuft, slot: BodyDark, size: [0.5, 0.25, 0.125], at: [0, 1.625, -0.6875], material: ice}
```

## Face

The head's front is the body cell grid (Blocky-Style C1): 16 columns across the 2-stud head (0.125 a cell); the eyes, the mouth and the cheeks are on the face plate the right way up (the head twists to look at you), the pink `Nose` block proud of it between the eyes.

```yaml
face:
  host: Head
  cols: 16
```

## Eyes

Its own eyes from the eye library ([[Blocky-Style]] rule 3, `tools/blocky/eyes.py`): `moonlet`, an Uncommon design, a pupil over a second-tone crescent, here an ice-blue iris over a pink moon (a warm crescent: a pale one under the eye would read as a tear), the night catch's eyes, at 16 pixels a stud on a 1.75 x 0.75 stud plate (28 x 12 pixels, three frames). A single little fang (`tooth`) and blush cheeks.

```yaml
eyes:
  key: moonlet
  colours: {iris: second, iris2: accent}
  mouth: tooth
  cheeks: blush
  plate: [1.75, 0.75]
  at: [0, 0.9375]
  spread: 0.5
```

## Rig

The idle ([[Blocky-Style]] rule 8; `tools/blocky/rigs.py` writes it into `src/shared/data/Rigs.luau`): the ice wings beat slowly with their ribs and icicles, the splayed ears twitch in bursts, the perch of frozen air shimmers (a slow pulse), the whole bat sways on its chin icicle and the face blinks. Six moving things (five objects, the Uncommon cap, and the blink); no flourish (that starts at Rare).

```yaml
rig:
  clips:
    wing: [{kind: flap, amp: 16, period: 1.8, axis: z}]
    ear: [{kind: wag, amp: 14, period: 3.4, axis: z}]
    perch: [{kind: pulse, amp: 0.08, period: 3}]
    root: [{kind: sway, amp: 4, period: 3.2, axis: z}]
    face: [{kind: blink, period: 5}]
```

## Build

Sheet: `python3 -I tools/blocky/sheet.py docs/vault/07-alien-game/Creatures/Flapsicle.md --out <scratch>`; build and renders: `tools/blender/blocky_build.py --spec docs/vault/07-alien-game/Creatures/Flapsicle.md --out <scratch>` ([[Blocky-Style]] "The pipeline").

## Renders

Lit, three-quarter, in block cells (Blender, Cycles):

![[Flapsicle_tq_cells.jpg]]

The idle: eight frames of the clips, and the face plate's frames:

![[Flapsicle_idle.png]]

The concept sheet, drawn from the parts table above: [[Flapsicle_sheet.svg]] (flat shapes and text, for the Claude Design canvas). The review sheet with all sixteen World 2 species: `media/studio/2026-10-20/world2_roster_v1.jpg`.

## Cells

The block-cell build ([[Blocky-Style]] "Cells" and "World 2: Frostbyte palette"): the cell is the face cell, 0.125 studs (8 a stud), 22 cells tall. Materials: `ice` on the wings, the wingtip icicles and the perch (light bands on the other diagonal, glossy), skin on the indigo body, head and ears.

## Reviews

- 2026-10-20, World 2 roster worker, two rounds. Round 1: wings hanging down beside the body cleared the head by a hair and the boxed test put it with Dreep, Soakum and Floe at 0.74 to 0.82, so the ice wings spread out and down from the shoulders five studs across (20 degrees under horizontal) with an icicle under each tip, and an icicle under the chin took the ground. Round 2: pale ice wings (L* 90) vanished against the backdrop, so the second colour is a mid ice blue. Overlap 0.992 to 0.998, 354 triangles, 15 blocks, 2.75 studs, four moving objects (the wings, the ears). Wanted for: a bat hanging from nothing, so low its chin rests on the snow. Still cheap: upside down with the face upright, the body over the head can read as a hat; the perch is one small block. Status review.
- 2026-10-21, Roster w2_low worker (B45, B46), one round. The house face became the library's `moonlet`, an ice-blue iris over a pink moon crescent (warm, so it reads as lit, not as a tear), on a 28 x 12 plate with one little fang (`tooth`) and blush; the drawn nose became a pink `Nose` block proud of the plate. Detail: an indigo `Rib` along each ice wing's leading edge (the arm bone; it beats with the wing) and an ice `Tuft` on the chest under the belly patch. Rig: the wings beat slowly, the ears twitch in bursts, the perch of frozen air shimmers, the bat sways on its chin icicle and blinks. Six moving things (five objects, the Uncommon cap, and the blink). Height 2.75 (in band, unchanged), 19 blocks, 402 triangles, overlap 0.988 to 0.996. Wanted for: the night catch, an upside-down bat with moonlit eyes, ice wings that beat and a little fang. Still weak: hanging upside down only reads from the side (from the front the perch looks like a hat), and the ribs merge with the wing edge at a distance. Status review.
- 2026-10-21, Polish w2 worker: from the front the perch read as a hat (a half-stud ice block centred on top). It is now a bar of ice 2.5 studs long, a quarter thick, wider than the body, and the feet are taller blocks gripping its front, so the bat plainly hangs from something; height 2.88 (from 2.75), 19 blocks, 402 triangles, overlap 0.990 to 0.996. Honest read: from the front it is a bat on a trapeze of ice, not a hat; the bar is pale like the wings, so it reads by shape, not colour.
